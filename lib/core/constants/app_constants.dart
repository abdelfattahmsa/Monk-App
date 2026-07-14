/// App-wide constants
class AppConstants {
  AppConstants._();

  static const appName = 'Monk';
  static const appVersion = '4.9.0';
  static const appStage = 'Alpha'; // alpha → beta → release

  // Supabase
  static const supabaseUrl = 'https://qjqkmvlqrrkowvisvcmc.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_RP1IetL7Hfe4YKuLXNWkKw_OBDI0cvX';

  // Clerk Auth
  static const clerkPublishableKey = 'pk_live_Y2xlcmsucHJwLWFwcC53ZWJzaXRlJA';

  // Hive box names
  static const hiveBoxSettings = 'settings';
  static const hiveBoxCache = 'cache';
  static const hiveBoxSchedule = 'schedule';

  // Shared prefs keys
  static const prefTheme = 'theme_mode';
  static const prefScheduleMode = 'schedule_mode';
  static const prefAlarmsEnabled = 'alarms_enabled';
  static const prefOnboarded = 'onboarded';
  static const prefDayStartHour = 'day_start_hour';
  static const prefFirstDayOfWeek = 'first_day_of_week';
  static const prefDefaultCurrency = 'default_currency';
  static const prefAlphaVantageApiKey = 'alpha_vantage_api_key';
  static const prefActivePillars = 'active_pillars';
  static const prefCompactMode = 'compact_mode';
  static const prefNotifyFocus = 'notify_focus';
  static const prefNotifyGoals = 'notify_goals';
  static const prefNotifyHabits = 'notify_habits';
  static const prefNotifyFasting = 'notify_fasting';
  static const prefScheduleModes = 'schedule_modes_v2'; // JSON list of ScheduleMode objects

  // Default schedule modes (fallback — user-defined list replaces these)
  static const scheduleModes = ['normal', 'fasting', 'friday', 'cairo'];

  // Category keys
  static const categoryKeys = [
    'deen', 'learn', 'project', 'health',
    'work', 'rest', 'fast', 'com',
  ];

  // Event type keys
  static const eventTypeKeys = [
    'personal', 'milestone', 'islamic', 'work',
    'study', 'family', 'finance',
    'quran', 'travel', 'done', 'health',
  ];

  // Priority levels
  static const priorities = ['high', 'medium', 'low'];

  // Egypt banks
  static const egyptBanks = [
    'National Bank of Egypt (NBE)',
    'Banque Misr',
    'Banque du Caire',
    'Commercial International Bank (CIB)',
    'QNB Al Ahli',
    'HSBC Egypt',
    'Arab African International Bank (AAIB)',
    'Arab Bank',
    'Emirates NBD Egypt',
    'Faisal Islamic Bank of Egypt',
    'Agricultural Bank of Egypt (ABE)',
    'Abu Dhabi Islamic Bank (ADIB)',
    'Al Baraka Bank Egypt',
    'Bank Audi Egypt',
    'Bank of Alexandria',
    'Crédit Agricole Egypt',
    'Egyptian Arab Land Bank',
    'Egyptian Gulf Bank (EGB)',
    'Export Development Bank of Egypt (EBE)',
    'First Abu Dhabi Bank (FAB) Egypt',
    'Housing and Development Bank (HDB)',
    'Industrial Development Bank',
    'Mashreq Bank Egypt',
    'Misr Iran Development Bank',
    'Principal Bank for Development & Agricultural Credit',
    'Société Arabe Internationale de Banque (SAIB)',
    'Suez Canal Bank',
    'United Bank',
    'Ahly United Bank',
    'Alex Bank',
    'Inbank (formerly Enppi Bank)',
    'Nasser Social Bank',
    'Egypt Post (Savings)',
    'Vodafone Cash',
    'Fawry',
    'Other',
  ];

  // Transaction categories
  static const txCategories = [
    'General', 'Food', 'Transport', 'Bills',
    'Shopping', 'Health', 'Personal', 'Business',
    'Education', 'Transfer',
  ];

  // Focus timer defaults (minutes)
  static const defaultFocusDuration = 25;
  static const defaultBreakDuration = 5;
  static const defaultLongBreakDuration = 15;
}

/// Category display info
class CategoryInfo {
  const CategoryInfo({
    required this.key,
    required this.label,
    required this.emoji,
  });
  final String key;
  final String label;
  final String emoji;
}

const categoryInfoMap = {
  'deen':    CategoryInfo(key: 'deen',    label: 'Deen',     emoji: '🕌'),
  'learn':   CategoryInfo(key: 'learn',   label: 'Learning', emoji: '📖'),
  'project': CategoryInfo(key: 'project', label: 'Project',  emoji: '🚀'),
  'health':  CategoryInfo(key: 'health',  label: 'Health',   emoji: '🚶'),
  'work':    CategoryInfo(key: 'work',    label: 'Work',     emoji: '🏗️'),
  'rest':    CategoryInfo(key: 'rest',    label: 'Rest',     emoji: '💤'),
  'fast':    CategoryInfo(key: 'fast',    label: 'Fasting',  emoji: '🌙'),
  'com':     CategoryInfo(key: 'com',     label: 'Commute',  emoji: '🚗'),
};

/// Event type display info
class EventTypeInfo {
  const EventTypeInfo({required this.key, required this.label, required this.emoji});
  final String key;
  final String label;
  final String emoji;
}

const eventTypeInfoMap = {
  'personal':  EventTypeInfo(key: 'personal',  label: 'Personal',  emoji: '👤'),
  'milestone': EventTypeInfo(key: 'milestone', label: 'Milestone', emoji: '🏆'),
  'islamic':   EventTypeInfo(key: 'islamic',   label: 'Islamic',   emoji: '🌙'),
  'work':      EventTypeInfo(key: 'work',      label: 'Work',      emoji: '💼'),
  'study':     EventTypeInfo(key: 'study',     label: 'Study',     emoji: '📚'),
  'family':    EventTypeInfo(key: 'family',    label: 'Family',    emoji: '👨‍👩‍👦'),
  'finance':   EventTypeInfo(key: 'finance',   label: 'Finance',   emoji: '💰'),
  'quran':     EventTypeInfo(key: 'quran',     label: 'Quran',     emoji: '📖'),
  'travel':    EventTypeInfo(key: 'travel',    label: 'Travel',    emoji: '✈️'),
  'done':      EventTypeInfo(key: 'done',      label: 'Done ✓',    emoji: '✅'),
  'health':    EventTypeInfo(key: 'health',    label: 'Health',    emoji: '🏃'),
};
