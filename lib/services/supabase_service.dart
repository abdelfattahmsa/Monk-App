import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../shared/models/models.dart';
import '../engines/ideas/data/models/idea_models.dart';
import '../engines/time/data/models/task_model.dart';
import '../engines/health/providers/fasting_provider.dart';
import '../engines/categories/data/models/user_category_model.dart';

const _uuidGen = Uuid();

/// Central service for all Supabase operations.
/// Each feature gets its own method group.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  // Guard: only upsert the profile row once per app session.
  // The DB trigger handle_new_user() creates it on signup; this is a
  // belt-and-suspenders FK guard that becomes a no-op after the first call.
  bool _profileEnsured = false;

  Future<void> _ensureProfile() async {
    if (_profileEnsured) return;
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db.from('profiles').upsert(
      {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? '',
      },
      onConflict: 'id',
      ignoreDuplicates: true,
    );
    _profileEnsured = true;
  }

  // ── AUTH ──────────────────────────────────────────────────────
  Stream<AuthState> get authStateStream => _db.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phone,
  }) async {
    final metadata = <String, dynamic>{'full_name': fullName};
    if (username != null && username.isNotEmpty) metadata['username'] = username;
    if (phone != null && phone.isNotEmpty) metadata['phone'] = phone;

    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    // Only run DB writes when a session exists (i.e. email confirmation is
    // disabled or auto-confirmed). When email confirmation is required,
    // res.session is null and auth.uid() would be null → RLS violation.
    // The DB trigger handle_new_user() creates the profile row automatically.
    if (res.user != null && res.session != null) {
      final profileData = <String, dynamic>{
        'id': res.user!.id,
        'email': email,
        'full_name': fullName,
      };
      if (username != null && username.isNotEmpty) profileData['username'] = username;
      if (phone != null && phone.isNotEmpty) profileData['phone'] = phone;
      try {
        await _db.from('profiles').upsert(profileData);
      } catch (_) {
        // username/phone columns may not exist yet — fall back to basic upsert
        await _db.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
        });
      }
      await _seedDefaultData(res.user!.id);
    }
    return res;
  }

  /// Look up the email associated with a given username.
  /// Returns null if not found or if the column doesn't exist yet.
  Future<String?> getEmailByUsername(String username) async {
    try {
      final res = await _db
          .from('profiles')
          .select('email')
          .eq('username', username.trim())
          .maybeSingle();
      return res?['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Look up the email associated with a given phone number.
  /// Returns null if not found or if the column doesn't exist yet.
  Future<String?> getEmailByPhone(String phone) async {
    try {
      final res = await _db
          .from('profiles')
          .select('email')
          .eq('phone', phone.trim())
          .maybeSingle();
      return res?['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Resend the signup confirmation/verification email.
  Future<void> resendVerificationEmail(String email) async {
    await _db.auth.resend(type: OtpType.signup, email: email);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res =
        await _db.auth.signInWithPassword(email: email, password: password);
    if (res.user != null) {
      // Ensure profile row exists (handles users created before profile seeding)
      await _db.from('profiles').upsert(
        {
          'id': res.user!.id,
          'email': res.user!.email ?? email,
          'full_name': res.user!.userMetadata?['full_name'] ?? '',
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
      // For email-confirmed sign-ups, _seedDefaultData() was skipped at
      // signup time (no session). Detect first login by checking for habits.
      final habits = await _db
          .from('habits')
          .select('id')
          .eq('user_id', res.user!.id)
          .limit(1);
      if (habits.isEmpty) {
        await _seedDefaultData(res.user!.id);
      }
    }
    return res;
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<void> resetPassword(String email) =>
      _db.auth.resetPasswordForEmail(email);

  Future<AppUser?> getProfile() async {
    final res =
        await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    return res != null ? AppUser.fromJson(res) : null;
  }

  Future<void> updateProfile(AppUser user) =>
      _db.from('profiles').update(user.toJson()).eq('id', _uid);

  Future<void> updateUserName(String fullName) async {
    // Update Supabase Auth metadata (drives currentUserProvider reactively)
    await _db.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
    // Also persist to profiles table
    await _db
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', _uid);
  }

  Future<String> uploadAvatar(List<int> bytes, String ext) async {
    final path = '$_uid/avatar.$ext';
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'gif'  => 'image/gif',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };
    await _db.storage.from('avatars').uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    await _db.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
    await _db.from('profiles').update({'avatar_url': url}).eq('id', _uid);
    return url;
  }

  // ── SCHEDULE ──────────────────────────────────────────────────
  Future<List<ScheduleBlock>> getScheduleBlocks(String mode) async {
    final res = await _db
        .from('schedule_blocks')
        .select()
        .eq('user_id', _uid)
        .eq('schedule_mode', mode)
        .order('order');
    return res.map((j) => ScheduleBlock.fromJson(j)).toList();
  }

  Future<void> upsertBlock(ScheduleBlock block) => _db
      .from('schedule_blocks')
      .upsert({...block.toJson(), 'user_id': _uid});

  Future<void> deleteBlock(String id) =>
      _db.from('schedule_blocks').delete().eq('id', id).eq('user_id', _uid);

  Future<void> reorderBlocks(List<ScheduleBlock> blocks) async {
    final updates = blocks
        .asMap()
        .entries
        .map((e) => {'id': e.value.id, 'order': e.key, 'user_id': _uid})
        .toList();
    await _db.from('schedule_blocks').upsert(updates);
  }

  // ── CALENDAR ──────────────────────────────────────────────────
  Future<List<CalendarEvent>> getCalendarEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _db
        .from('calendar_events')
        .select()
        .eq('user_id', _uid);
    if (from != null) {
      query = query.gte('date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String().split('T').first);
    }
    final res = await query.order('date');
    return res.map((j) => CalendarEvent.fromJson(j)).toList();
  }

  Future<CalendarEvent> upsertEvent(CalendarEvent event) async {
    final res = await _db
        .from('calendar_events')
        .upsert({...event.toJson(), 'user_id': _uid})
        .select()
        .single();
    return CalendarEvent.fromJson(res);
  }

  Future<void> deleteEvent(String id) => _db
      .from('calendar_events')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  Future<void> markEventDone(String id, bool done) => _db
      .from('calendar_events')
      .update({'is_done': done})
      .eq('id', id)
      .eq('user_id', _uid);

  // ── FINANCE ───────────────────────────────────────────────────
  Future<List<BankAccount>> getBankAccounts() async {
    final res = await _db
        .from('bank_accounts')
        .select()
        .eq('user_id', _uid)
        .order('order');
    return res.map((j) => BankAccount.fromJson(j)).toList();
  }

  Future<void> upsertBankAccount(BankAccount account) async {
    try {
      await _db.from('bank_accounts')
          .upsert({...account.toJson(), 'user_id': _uid});
    } catch (_) {
      // Fallback: save without the new extended columns
      // (needed if migration SQL hasn't been run yet)
      await _db.from('bank_accounts').upsert({
        'id': account.id,
        'name': account.name,
        'cc_balance': account.creditCardBalance,
        'cc_limit': account.creditCardLimit,
        'savings_balance': account.savingsBalance,
        'current_balance': account.currentBalance,
        'order': account.order,
        'user_id': _uid,
      });
    }
  }

  Future<void> deleteBankAccount(String id) =>
      _db.from('bank_accounts').delete().eq('id', id).eq('user_id', _uid);

  Future<List<ExternalDebt>> getDebts() async {
    final res =
        await _db.from('debts').select().eq('user_id', _uid).order('amount', ascending: false);
    return res.map((j) => ExternalDebt.fromJson(j)).toList();
  }

  Future<void> upsertDebt(ExternalDebt debt) async {
    await _ensureProfile();
    await _db.from('debts').upsert({...debt.toJson(), 'user_id': _uid});
  }

  Future<void> deleteDebt(String id) =>
      _db.from('debts').delete().eq('id', id).eq('user_id', _uid);

  Future<List<Investment>> getInvestments() async {
    final res = await _db.from('investments').select().eq('user_id', _uid);
    return res.map((j) => Investment.fromJson(j)).toList();
  }

  Future<void> upsertInvestment(Investment inv) async {
    await _ensureProfile();
    await _db.from('investments').upsert({...inv.toJson(), 'user_id': _uid});
  }

  Future<void> deleteInvestment(String id) =>
      _db.from('investments').delete().eq('id', id).eq('user_id', _uid);

  Future<List<Transaction>> getTransactions({String? category}) async {
    var query =
        _db.from('transactions').select().eq('user_id', _uid);
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    final res = await query.order('date', ascending: false);
    return res.map((j) => Transaction.fromJson(j)).toList();
  }

  Future<void> addTransaction(Transaction tx) async {
    await _ensureProfile();
    await _db.from('transactions').insert({...tx.toJson(), 'user_id': _uid});
  }

  Future<void> deleteTransaction(String id) =>
      _db.from('transactions').delete().eq('id', id).eq('user_id', _uid);

  // ── CREDIT CARDS ──────────────────────────────────────────────
  Future<List<CreditCard>> getCreditCards() async {
    try {
      final res = await _db
          .from('credit_cards')
          .select()
          .eq('user_id', _uid)
          .order('order');
      return res.map((j) => CreditCard.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertCreditCard(CreditCard card) async {
    await _ensureProfile();
    await _db.from('credit_cards').upsert({...card.toJson(), 'user_id': _uid});
  }

  Future<void> deleteCreditCard(String id) =>
      _db.from('credit_cards').delete().eq('id', id).eq('user_id', _uid);

  // ── INSTALLMENT PLANS ─────────────────────────────────────────
  Future<List<InstallmentPlan>> getInstallmentPlans() async {
    try {
      final res = await _db
          .from('installment_plans')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return res.map((j) => InstallmentPlan.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertInstallmentPlan(InstallmentPlan plan) async {
    await _ensureProfile();
    await _db.from('installment_plans').upsert({...plan.toJson(), 'user_id': _uid});
  }

  Future<void> deleteInstallmentPlan(String id) =>
      _db.from('installment_plans').delete().eq('id', id).eq('user_id', _uid);

  Future<void> markInstallmentPaid(String id, int paidMonths) =>
      _db.from('installment_plans')
          .update({'paid_months': paidMonths})
          .eq('id', id)
          .eq('user_id', _uid);

  // ── HABITS ────────────────────────────────────────────────────
  Future<List<Habit>> getHabits() async {
    final res = await _db
        .from('habits')
        .select()
        .eq('user_id', _uid)
        .eq('is_archived', false)
        .order('order');
    return res.map((j) => Habit.fromJson(j)).toList();
  }

  Future<void> upsertHabit(Habit habit) async {
    await _ensureProfile();
    await _db.from('habits').upsert({...habit.toJson(), 'user_id': _uid});
  }

  Future<void> deleteHabit(String id) =>
      _db.from('habits').delete().eq('id', id).eq('user_id', _uid);

  Future<void> toggleHabitDay(String habitId, String dateKey, bool done) async {
    // Fetch current habit, update history, upsert
    final res = await _db
        .from('habits')
        .select()
        .eq('id', habitId)
        .eq('user_id', _uid)
        .single();
    final habit = Habit.fromJson(res);
    final newHistory = Map<String, bool>.from(habit.history);
    newHistory[dateKey] = done;
    final newStreak = habit.copyWith(history: newHistory).calculateStreak();
    await _db.from('habits').update({
      'history': newHistory,
      'streak': newStreak,
      'longest_streak': newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    }).eq('id', habitId).eq('user_id', _uid);
  }

  // ── GOALS ─────────────────────────────────────────────────────
  Future<List<Goal>> getGoals() async {
    final res = await _db
        .from('goals')
        .select()
        .eq('user_id', _uid)
        .order('target_date');
    return res.map((j) => Goal.fromJson(j)).toList();
  }

  Future<Goal> upsertGoal(Goal goal) async {
    final res = await _db
        .from('goals')
        .upsert({...goal.toJson(), 'user_id': _uid})
        .select()
        .single();
    return Goal.fromJson(res);
  }

  Future<void> deleteGoal(String id) =>
      _db.from('goals').delete().eq('id', id).eq('user_id', _uid);

  // ── FOCUS SESSIONS ────────────────────────────────────────────
  Future<List<FocusSession>> getFocusSessions({int limit = 100}) async {
    final res = await _db
        .from('focus_sessions')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .limit(limit);
    return res.map((j) => FocusSession.fromJson(j)).toList();
  }

  Future<void> addFocusSession(FocusSession session) => _db
      .from('focus_sessions')
      .insert({...session.toJson(), 'user_id': _uid});

  Future<void> deleteFocusSession(String id) => _db
      .from('focus_sessions')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  Future<void> updateFocusSession(FocusSession session) => _db
      .from('focus_sessions')
      .update({
        'block_label': session.blockLabel,
        'block_category_key': session.blockCategoryKey,
        'note': session.note,
      })
      .eq('id', session.id)
      .eq('user_id', _uid);

  // ── MOOD ENTRIES ──────────────────────────────────────────────
  Future<List<MoodEntry>> getMoodEntries({int limit = 60}) async {
    final res = await _db
        .from('mood_entries')
        .select()
        .eq('user_id', _uid)
        .order('timestamp', ascending: false)
        .limit(limit);
    return res.map((j) => MoodEntry.fromJson(j)).toList();
  }

  Future<void> upsertMoodEntry(MoodEntry entry) => _db
      .from('mood_entries')
      .upsert({...entry.toJson(), 'user_id': _uid});

  Future<void> deleteMoodEntry(String id) => _db
      .from('mood_entries')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  // ── BODY PROFILE ──────────────────────────────────────────────
  Future<BodyProfile> getBodyProfile() async {
    final res = await _db
        .from('body_profiles')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return res != null ? BodyProfile.fromJson(res) : const BodyProfile();
  }

  Future<void> upsertBodyProfile(BodyProfile profile) => _db
      .from('body_profiles')
      .upsert({...profile.toJson(), 'user_id': _uid}, onConflict: 'user_id');

  // ── WEIGHT ENTRIES ────────────────────────────────────────────
  Future<List<WeightEntry>> getWeightEntries({int limit = 90}) async {
    final res = await _db
        .from('weight_entries')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .limit(limit);
    return res.map((j) => WeightEntry.fromJson(j)).toList();
  }

  Future<void> addWeightEntry(WeightEntry entry) => _db
      .from('weight_entries')
      .insert({...entry.toJson(), 'user_id': _uid});

  Future<void> deleteWeightEntry(String id) => _db
      .from('weight_entries')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  // ── CALORIE ENTRIES ───────────────────────────────────────────
  Future<List<CalorieEntry>> getCalorieEntries({int limit = 200}) async {
    final res = await _db
        .from('calorie_entries')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return res.map((j) => CalorieEntry.fromJson(j)).toList();
  }

  Future<void> addCalorieEntry(CalorieEntry entry) => _db
      .from('calorie_entries')
      .insert({...entry.toJson(), 'user_id': _uid});

  Future<void> deleteCalorieEntry(String id) => _db
      .from('calorie_entries')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  // ── EXERCISE ENTRIES ──────────────────────────────────────────
  Future<List<ExerciseEntry>> getExerciseEntries({int limit = 200}) async {
    final res = await _db
        .from('exercise_entries')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return res.map((j) => ExerciseEntry.fromJson(j)).toList();
  }

  Future<void> addExerciseEntry(ExerciseEntry entry) => _db
      .from('exercise_entries')
      .insert({...entry.toJson(), 'user_id': _uid});

  Future<void> deleteExerciseEntry(String id) => _db
      .from('exercise_entries')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  // ── SEED DEFAULT DATA ─────────────────────────────────────────
  /// Called on first sign-up to populate default schedule blocks,
  /// habits, and goals. All data is generic and user-agnostic.
  Future<void> _seedDefaultData(String uid) async {
    final now = DateTime.now();
    final endOfYear   = DateTime(now.year, 12, 31).toIso8601String().split('T').first;
    final sixMonths   = DateTime(now.year, now.month + 6, now.day).toIso8601String().split('T').first;
    final ninetyDays  = now.add(const Duration(days: 90)).toIso8601String().split('T').first;

    // Generic starter habits
    final defaultHabits = [
      {'id': _uuid(), 'user_id': uid, 'name': 'Morning routine',           'icon': '🌅', 'order': 0, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Exercise 30 min',           'icon': '🏃', 'order': 1, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Read / Learn 30 min',       'icon': '📖', 'order': 2, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Drink 2L water',            'icon': '💧', 'order': 3, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Daily journaling',          'icon': '✍️', 'order': 4, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'No screens 1hr before bed', 'icon': '🌙', 'order': 5, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
    ];
    await _db.from('habits').insert(defaultHabits);

    // Generic starter goals
    final defaultGoals = [
      {'id': _uuid(), 'user_id': uid, 'title': 'Build 3-month emergency fund',         'target_date': sixMonths,   'priority': 'high',   'status': 'active', 'progress': 0, 'description': 'Save consistently until you have 3 months of living expenses covered.',     'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Complete a professional certification', 'target_date': endOfYear,   'priority': 'high',   'status': 'active', 'progress': 0, 'description': 'Pick a certification relevant to your career and get it done this year.',    'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Exercise 3× per week for 90 days',     'target_date': ninetyDays,  'priority': 'medium', 'status': 'active', 'progress': 0, 'description': 'Build a sustainable exercise habit — consistency beats intensity.',         'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Read 12 books this year',               'target_date': endOfYear,   'priority': 'medium', 'status': 'active', 'progress': 0, 'description': 'One book per month — fiction, non-fiction, whatever feeds your mind.',      'milestones': [], 'linked_event_ids': []},
    ];
    await _db.from('goals').insert(defaultGoals);

    // Seed default schedule blocks (normal mode)
    await _seedScheduleBlocks(uid);

    // Seed default user categories
    await _seedDefaultCategories(uid);
  }

  Future<void> _seedScheduleBlocks(String uid) async {
    final normalBlocks = [
      {'schedule_mode': 'normal', 'time': '06:00', 'label': 'Morning routine',        'category_key': 'rest',    'duration': '30m',   'note': 'Hydrate, stretch, set your intentions for the day.', 'order': 0},
      {'schedule_mode': 'normal', 'time': '06:30', 'label': 'Exercise',               'category_key': 'health',  'duration': '45m',   'note': null, 'order': 1},
      {'schedule_mode': 'normal', 'time': '07:15', 'label': 'Breakfast & planning',   'category_key': 'rest',    'duration': '30m',   'note': 'Review your goals and tasks for the day.', 'order': 2},
      {'schedule_mode': 'normal', 'time': '08:00', 'label': 'Deep work — block 1',    'category_key': 'work',    'duration': '3hrs',  'note': 'Your most important work. No distractions.', 'order': 3},
      {'schedule_mode': 'normal', 'time': '11:00', 'label': 'Break',                  'category_key': 'rest',    'duration': '15m',   'note': null, 'order': 4},
      {'schedule_mode': 'normal', 'time': '11:15', 'label': 'Deep work — block 2',    'category_key': 'work',    'duration': '1hr 45m','note': null, 'order': 5},
      {'schedule_mode': 'normal', 'time': '13:00', 'label': 'Lunch break',            'category_key': 'rest',    'duration': '1hr',   'note': null, 'order': 6},
      {'schedule_mode': 'normal', 'time': '14:00', 'label': 'Learning / skill time',  'category_key': 'learn',   'duration': '1hr',   'note': 'Course, book, or deliberate skill practice.', 'order': 7},
      {'schedule_mode': 'normal', 'time': '15:00', 'label': 'Work — afternoon',       'category_key': 'work',    'duration': '2hrs',  'note': null, 'order': 8},
      {'schedule_mode': 'normal', 'time': '17:00', 'label': 'Side project / creative','category_key': 'project', 'duration': '1hr',   'note': 'Build something of your own.', 'order': 9},
      {'schedule_mode': 'normal', 'time': '18:00', 'label': 'Walk / workout',         'category_key': 'health',  'duration': '30m',   'note': null, 'order': 10},
      {'schedule_mode': 'normal', 'time': '18:30', 'label': 'Personal time',          'category_key': 'rest',    'duration': '2hrs',  'note': 'Family, hobbies, social.', 'order': 11},
      {'schedule_mode': 'normal', 'time': '20:30', 'label': 'Wind down',              'category_key': 'rest',    'duration': '1hr',   'note': 'No screens. Reflect, read, or relax.', 'order': 12},
      {'schedule_mode': 'normal', 'time': '22:00', 'label': 'Sleep',                  'category_key': 'rest',    'duration': null,    'note': 'Aim for 7–8 hours.', 'order': 13},
    ];

    final rows = normalBlocks.map((b) => {...b, 'id': _uuid(), 'user_id': uid, 'notify_on_start': true, 'notify_on_end': false}).toList();
    await _db.from('schedule_blocks').insert(rows);
  }

  String _uuid() => _uuidGen.v4();

  // ── CASH ON HAND ───────────────────────────────────────────
  Future<double> getCashOnHand() async {
    final row = await _db.from('profiles').select('cash_on_hand').eq('id', _uid).maybeSingle();
    return (row?['cash_on_hand'] as num?)?.toDouble() ?? 0;
  }

  Future<void> setCashOnHand(double amount) async {
    await _db.from('profiles').update({'cash_on_hand': amount}).eq('id', _uid);
  }

  // ── USER CATEGORIES ────────────────────────────────────────────
  Future<List<UserCategory>> getUserCategories() async {
    final res = await _db
        .from('user_categories')
        .select()
        .eq('user_id', _uid)
        .order('order');
    final cats = res.map((j) => UserCategory.fromJson(j)).toList();
    if (cats.isEmpty) {
      await _seedDefaultCategories(_uid);
      final seeded = await _db
          .from('user_categories')
          .select()
          .eq('user_id', _uid)
          .order('order');
      return seeded.map((j) => UserCategory.fromJson(j)).toList();
    }
    return cats;
  }

  Future<UserCategory> upsertUserCategory(UserCategory cat) async {
    final row = await _db
        .from('user_categories')
        .upsert({...cat.toJson(), 'user_id': _uid})
        .select()
        .single();
    return UserCategory.fromJson(row);
  }

  Future<void> deleteUserCategory(String id) =>
      _db.from('user_categories').delete().eq('id', id).eq('user_id', _uid);

  // ── FASTING ────────────────────────────────────────────────────
  Future<List<FastRecord>> getFastingRecords() async {
    final res = await _db
        .from('fasting_records')
        .select()
        .eq('user_id', _uid)
        .order('start_time', ascending: false);
    return res.map((j) => FastRecord.fromJson(j)).toList();
  }

  Future<FastRecord> startFastRecord({
    required DateTime startTime,
    required int goalHours,
  }) async {
    final row = await _db.from('fasting_records').insert({
      'user_id': _uid,
      'start_time': startTime.toIso8601String(),
      'goal_hours': goalHours,
    }).select().single();
    return FastRecord.fromJson(row);
  }

  Future<void> updateFastRecord(
    String id, {
    DateTime? endTime,
    int? goalHours,
  }) async {
    final data = <String, dynamic>{};
    if (endTime != null) data['end_time'] = endTime.toIso8601String();
    if (goalHours != null) data['goal_hours'] = goalHours;
    if (data.isEmpty) return;
    await _db
        .from('fasting_records')
        .update(data)
        .eq('id', id)
        .eq('user_id', _uid);
  }

  Future<void> _seedDefaultCategories(String uid) async {
    final rows = [
      ...kDefaultScheduleCategories,
      ...kDefaultTxCategories,
    ].map((c) => {
          'id': _uuid(),
          'user_id': uid,
          'name': c.name,
          'emoji': c.emoji,
          'engine': c.engine,
          'key': c.key,
          'order': c.order,
        }).toList();
    await _db.from('user_categories').insert(rows);
  }

  // ── USER TASKS ────────────────────────────────────────────────
  Future<List<UserTask>> getTasks() async {
    try {
      final res = await _db
          .from('tasks')
          .select()
          .eq('user_id', _uid)
          .order('order')
          .order('created_at', ascending: false);
      return res.map((j) => UserTask.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<UserTask> upsertTask(UserTask task) async {
    final row = await _db
        .from('tasks')
        .upsert({...task.toJson(), 'user_id': _uid})
        .select()
        .single();
    return UserTask.fromJson(row);
  }

  Future<void> deleteTask(String id) =>
      _db.from('tasks').delete().eq('id', id).eq('user_id', _uid);

  Future<void> reorderTasks(List<UserTask> tasks) async {
    final updates = tasks
        .asMap()
        .entries
        .map((e) => {'id': e.value.id, 'order': e.key, 'user_id': _uid})
        .toList();
    await _db.from('tasks').upsert(updates);
  }

  // ── IDEAS ──────────────────────────────────────────────────────
  Future<List<Idea>> getIdeas() async {
    final res = await _db
        .from('ideas')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return res.map((j) => Idea.fromJson(j)).toList();
  }

  Future<Idea> upsertIdea(Idea idea) async {
    final row = await _db
        .from('ideas')
        .upsert({...idea.toJson(), 'user_id': _uid})
        .select()
        .single();
    return Idea.fromJson(row);
  }

  Future<void> deleteIdea(String id) =>
      _db.from('ideas').delete().eq('id', id).eq('user_id', _uid);
}
