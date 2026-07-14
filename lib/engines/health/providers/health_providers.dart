import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/health_models.dart';
import '../data/repositories/health_repository.dart';
import '../../../services/health_sync_service.dart';

const _uuid = Uuid();

// ── Habits ────────────────────────────────────────────────────────
final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() => HealthRepository.instance.getHabits();

  Future<void> add(Habit habit) async {
    await HealthRepository.instance.upsertHabit(habit);
    state = AsyncData([...state.value!, habit]);
  }

  Future<void> upsert(Habit habit) async {
    await HealthRepository.instance.upsertHabit(habit);
    state = AsyncData(
        state.value!.map((h) => h.id == habit.id ? habit : h).toList());
  }

  Future<void> delete(String id) async {
    await HealthRepository.instance.deleteHabit(id);
    state = AsyncData(state.value!.where((h) => h.id != id).toList());
  }

  Future<void> toggle(String id, String dateKey) async {
    final habits = state.value!;
    final habit = habits.firstWhere((h) => h.id == id);
    final wasDone = habit.history[dateKey] ?? false;

    // Optimistic update
    final newHistory = Map<String, bool>.from(habit.history);
    newHistory[dateKey] = !wasDone;
    final updated = habit.copyWith(history: newHistory);
    final newStreak = updated.calculateStreak();
    final withStreak = updated.copyWith(
      streak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    );
    state = AsyncData(habits.map((h) => h.id == id ? withStreak : h).toList());

    try {
      await HealthRepository.instance.toggleHabitDay(id, dateKey, !wasDone);
    } catch (e) {
      // Roll back to original state if DB write fails
      state = AsyncData(habits);
      rethrow;
    }
  }
}

// Derived: today's completion %
final habitsTodayProvider = Provider((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  if (habits.isEmpty) return (done: 0, total: 0, pct: 0.0);
  final done = habits.where((h) => h.isDoneToday).length;
  return (done: done, total: habits.length, pct: done / habits.length);
});

// ── Body Profile ──────────────────────────────────────────────────
final bodyProfileProvider =
    AsyncNotifierProvider<BodyProfileNotifier, BodyProfile>(BodyProfileNotifier.new);

class BodyProfileNotifier extends AsyncNotifier<BodyProfile> {
  @override
  Future<BodyProfile> build() => HealthRepository.instance.getBodyProfile();

  Future<void> save(BodyProfile profile) async {
    await HealthRepository.instance.upsertBodyProfile(profile);
    state = AsyncData(profile);
  }
}

// ── Weight Entries ────────────────────────────────────────────────
final weightEntriesProvider =
    AsyncNotifierProvider<WeightEntriesNotifier, List<WeightEntry>>(
        WeightEntriesNotifier.new);

class WeightEntriesNotifier extends AsyncNotifier<List<WeightEntry>> {
  @override
  Future<List<WeightEntry>> build() =>
      HealthRepository.instance.getWeightEntries();

  Future<void> add({required double weightKg, String? note}) async {
    final entry = WeightEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      weightKg: weightKg,
      note: note,
    );
    await HealthRepository.instance.addWeightEntry(entry);
    state = AsyncData([entry, ...state.value!]);
  }

  Future<void> addFromSync({required double weightKg}) async {
    final existing = state.value ?? [];
    final todayKey = DateTime.now().toIso8601String().split('T').first;
    // Don't duplicate if already have a synced entry for today
    final alreadyToday = existing.any(
      (e) => e.date.toIso8601String().split('T').first == todayKey &&
          e.note == '🔄 Synced',
    );
    if (alreadyToday) return;
    final entry = WeightEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      weightKg: weightKg,
      note: '🔄 Synced',
    );
    await HealthRepository.instance.addWeightEntry(entry);
    state = AsyncData([entry, ...existing]);
  }

  Future<void> delete(String id) async {
    await HealthRepository.instance.deleteWeightEntry(id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }
}

// ── Calorie Entries ───────────────────────────────────────────────
final calorieEntriesProvider =
    AsyncNotifierProvider<CalorieEntriesNotifier, List<CalorieEntry>>(
        CalorieEntriesNotifier.new);

class CalorieEntriesNotifier extends AsyncNotifier<List<CalorieEntry>> {
  @override
  Future<List<CalorieEntry>> build() =>
      HealthRepository.instance.getCalorieEntries();

  Future<void> add({
    required MealType mealType,
    required String description,
    required int calories,
  }) async {
    final entry = CalorieEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      mealType: mealType,
      description: description,
      calories: calories,
    );
    await HealthRepository.instance.addCalorieEntry(entry);
    state = AsyncData([entry, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await HealthRepository.instance.deleteCalorieEntry(id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }
}

// ── Exercise Entries ──────────────────────────────────────────────
final exerciseEntriesProvider =
    AsyncNotifierProvider<ExerciseEntriesNotifier, List<ExerciseEntry>>(
        ExerciseEntriesNotifier.new);

class ExerciseEntriesNotifier extends AsyncNotifier<List<ExerciseEntry>> {
  @override
  Future<List<ExerciseEntry>> build() =>
      HealthRepository.instance.getExerciseEntries();

  Future<void> add({
    required String name,
    required ExerciseType exerciseType,
    required int durationMins,
    int caloriesBurned = 0,
    String? note,
  }) async {
    final entry = ExerciseEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      name: name,
      exerciseType: exerciseType,
      durationMins: durationMins,
      caloriesBurned: caloriesBurned,
      note: note,
    );
    await HealthRepository.instance.addExerciseEntry(entry);
    state = AsyncData([entry, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await HealthRepository.instance.deleteExerciseEntry(id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }
}

// ── Health Platform Sync ──────────────────────────────────────────
// Holds the last sync result; null means not yet synced this session.
final healthSyncProvider =
    AsyncNotifierProvider<HealthSyncNotifier, HealthSyncResult?>(
        HealthSyncNotifier.new);

class HealthSyncNotifier extends AsyncNotifier<HealthSyncResult?> {
  @override
  Future<HealthSyncResult?> build() async => null; // no auto-sync on startup

  Future<void> sync() async {
    state = const AsyncLoading();
    final result = await HealthSyncService.instance.syncToday();
    state = AsyncData(result);

    // If sync returned a weight, add it to the weight log
    if (result.latestWeightKg != null && result.permissionGranted) {
      final notifier = ref.read(weightEntriesProvider.notifier);
      await notifier.addFromSync(weightKg: result.latestWeightKg!);
    }
  }

  bool get isSupported => HealthSyncService.instance.isSupported;
  String get platformName => HealthSyncService.instance.platformName;
}
