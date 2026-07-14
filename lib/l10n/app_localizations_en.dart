// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Monk';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabTime => 'Time';

  @override
  String get tabFinance => 'Finance';

  @override
  String get tabEnergy => 'Energy';

  @override
  String get tabHealth => 'Health';

  @override
  String get tabProfile => 'Profile';

  @override
  String get subOverview => 'Overview';

  @override
  String get subCalendar => 'Calendar';

  @override
  String get subSchedule => 'Schedule';

  @override
  String get subTasks => 'Tasks';

  @override
  String get subAccounts => 'Accounts';

  @override
  String get subCards => 'Cards';

  @override
  String get subInvest => 'Invest';

  @override
  String get subDebts => 'Debts';

  @override
  String get subTxns => 'Txns';

  @override
  String get subFocus => 'Focus';

  @override
  String get subMood => 'Mood';

  @override
  String get subGoals => 'Goals';

  @override
  String get subIdeas => 'Ideas';

  @override
  String get subProgress => 'Progress';

  @override
  String get subFasting => 'Fasting';

  @override
  String get subHabits => 'Habits';

  @override
  String get subBody => 'Body';

  @override
  String get subNutrition => 'Nutrition';

  @override
  String get subExercise => 'Exercise';

  @override
  String get subAccount => 'Account';

  @override
  String get subApp => 'App';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutMessage => 'You will be returned to the login screen.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get loading => 'Loading…';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notificationsEnabled => '✓ Notifications enabled';

  @override
  String get enableNotifications => 'Enable';

  @override
  String get notificationsPrompt =>
      'Enable notifications for focus, fasting & habit reminders';

  @override
  String get emailVerifyPrompt => 'Please verify your email';

  @override
  String get emailVerifyUnlock => 'to unlock all features.';

  @override
  String get resend => 'Resend';

  @override
  String get focusSessionComplete => '🍅 Focus session complete!';

  @override
  String get breakOver => '☕ Break over!';

  @override
  String get tapToReturn => 'Tap to return to Monk';

  @override
  String get focus => 'Focus';

  @override
  String get breakLabel => 'Break';

  @override
  String get support => 'Support';

  @override
  String get termsPrivacy => 'Terms & Privacy';

  @override
  String get collapse => 'Collapse';

  @override
  String get myProfile => 'My Profile';

  @override
  String get manualEntryOnly => 'Manual entry only on this platform';

  @override
  String syncingFrom(String platform) {
    return 'Syncing from $platform…';
  }

  @override
  String get syncFailed => 'Sync failed';

  @override
  String connectTo(String platform) {
    return 'Connect to $platform';
  }

  @override
  String get connectDescription =>
      'Sync weight, heart rate, steps & sleep automatically';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String permissionTap(String platform) {
    return 'Tap to grant access to $platform';
  }

  @override
  String syncedFrom(String platform) {
    return 'Synced from $platform';
  }

  @override
  String get grantAccess => 'Grant access';

  @override
  String get syncAgain => 'Sync again';

  @override
  String get connect => 'Connect';
}
