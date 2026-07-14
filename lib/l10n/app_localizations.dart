import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Monk'**
  String get appName;

  /// Main nav tab: Overview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// Main nav tab: Time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get tabTime;

  /// Main nav tab: Finance
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get tabFinance;

  /// Main nav tab: Energy
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get tabEnergy;

  /// Main nav tab: Health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get tabHealth;

  /// Main nav tab: Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Sub-tab label: Overview (shared)
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get subOverview;

  /// Sub-tab: Calendar (Time)
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get subCalendar;

  /// Sub-tab: Schedule (Time)
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get subSchedule;

  /// Sub-tab: Tasks (Time)
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get subTasks;

  /// Sub-tab: Accounts (Finance)
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get subAccounts;

  /// Sub-tab: Cards (Finance)
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get subCards;

  /// Sub-tab: Investments (Finance)
  ///
  /// In en, this message translates to:
  /// **'Invest'**
  String get subInvest;

  /// Sub-tab: Debts/Liabilities (Finance)
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get subDebts;

  /// Sub-tab: Transactions (Finance)
  ///
  /// In en, this message translates to:
  /// **'Txns'**
  String get subTxns;

  /// Sub-tab: Focus (Energy)
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get subFocus;

  /// Sub-tab: Mood (Energy)
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get subMood;

  /// Sub-tab: Goals (Energy)
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get subGoals;

  /// Sub-tab: Ideas (Energy)
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get subIdeas;

  /// Sub-tab: Progress (Health)
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get subProgress;

  /// Sub-tab: Fasting (Health)
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get subFasting;

  /// Sub-tab: Habits (Health)
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get subHabits;

  /// Sub-tab: Body (Health)
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get subBody;

  /// Sub-tab: Nutrition (Health)
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get subNutrition;

  /// Sub-tab: Exercise (Health)
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get subExercise;

  /// Sub-tab: Account settings (Profile)
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get subAccount;

  /// Sub-tab: App settings (Profile)
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get subApp;

  /// Sign out action
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Sign out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// Sign out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get signOutMessage;

  /// Cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Add action
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Snackbar: notifications enabled
  ///
  /// In en, this message translates to:
  /// **'✓ Notifications enabled'**
  String get notificationsEnabled;

  /// Enable notifications button
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableNotifications;

  /// Notification permission banner text
  ///
  /// In en, this message translates to:
  /// **'Enable notifications for focus, fasting & habit reminders'**
  String get notificationsPrompt;

  /// Email verification banner prompt
  ///
  /// In en, this message translates to:
  /// **'Please verify your email'**
  String get emailVerifyPrompt;

  /// Email verification banner tail text
  ///
  /// In en, this message translates to:
  /// **'to unlock all features.'**
  String get emailVerifyUnlock;

  /// Resend verification email button
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Focus session completion notification
  ///
  /// In en, this message translates to:
  /// **'🍅 Focus session complete!'**
  String get focusSessionComplete;

  /// Break over notification
  ///
  /// In en, this message translates to:
  /// **'☕ Break over!'**
  String get breakOver;

  /// Notification body to return to app
  ///
  /// In en, this message translates to:
  /// **'Tap to return to Monk'**
  String get tapToReturn;

  /// Focus timer label
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// Break timer label
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// Support link tooltip
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Terms and privacy link tooltip
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// Collapse sidebar tooltip
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Profile header fallback name
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Health sync: manual entry on unsupported platform
  ///
  /// In en, this message translates to:
  /// **'Manual entry only on this platform'**
  String get manualEntryOnly;

  /// Health sync: syncing in progress
  ///
  /// In en, this message translates to:
  /// **'Syncing from {platform}…'**
  String syncingFrom(String platform);

  /// Health sync: error state
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// Health sync: connect prompt
  ///
  /// In en, this message translates to:
  /// **'Connect to {platform}'**
  String connectTo(String platform);

  /// Health sync: connect description
  ///
  /// In en, this message translates to:
  /// **'Sync weight, heart rate, steps & sleep automatically'**
  String get connectDescription;

  /// Health sync: permission denied state
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// Health sync: tap to grant permission
  ///
  /// In en, this message translates to:
  /// **'Tap to grant access to {platform}'**
  String permissionTap(String platform);

  /// Health sync: success state
  ///
  /// In en, this message translates to:
  /// **'Synced from {platform}'**
  String syncedFrom(String platform);

  /// Health sync: grant access button
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get grantAccess;

  /// Health sync: sync again button
  ///
  /// In en, this message translates to:
  /// **'Sync again'**
  String get syncAgain;

  /// Health sync: connect button
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
