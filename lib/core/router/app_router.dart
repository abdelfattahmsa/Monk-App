import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart'; // includes SignupScreen + ForgotPasswordScreen
import '../../features/checkin/screens/daily_checkin_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../shared/screens/shell_screen.dart';

// ── Tab 1: Overview ──
import '../../features/overview/screens/overview_screen.dart';

// ── Tab 2: Time ──
import '../../features/time/screens/time_overview_screen.dart';
import '../../features/time/screens/time_tasks_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';

// ── Tab 3: Finance ──
import '../../features/finance/screens/finance_overview_screen.dart';
import '../../features/finance/screens/finance_accounts_screen.dart';
import '../../features/finance/screens/finance_cards_screen.dart';
import '../../features/finance/screens/finance_investments_screen.dart';
import '../../features/finance/screens/finance_liabilities_screen.dart';
import '../../features/finance/screens/finance_transactions_screen.dart';

// ── Tab 4: Energy ──
import '../../features/energy/screens/energy_overview_screen.dart';
import '../../features/energy/screens/energy_mood_screen.dart';
import '../../features/focus/screens/focus_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/ideas/screens/ideas_screen.dart';

// ── Tab 5: Health ──
import '../../features/health/screens/health_overview_screen.dart';
import '../../features/health/screens/health_daily_progress_screen.dart';
import '../../features/health/screens/health_fasting_screen.dart';
import '../../features/health/screens/health_habits_screen.dart';
import '../../features/health/screens/health_body_screen.dart';
import '../../features/health/screens/health_nutrition_screen.dart';
import '../../features/health/screens/health_exercise_screen.dart';

// ── Tab 7: Profile ──
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/profile/screens/profile_account_screen.dart';
import '../../features/profile/screens/profile_app_settings_screen.dart';

// ── Legal ──
import '../../features/legal/terms_screen.dart';
import '../../features/legal/privacy_screen.dart';

// ══════════════════════════════════════════════════════════════
// ROUTE CONSTANTS
// ══════════════════════════════════════════════════════════════
class Routes {
  // ── Auth ──
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  // ── Tab 1: Overview ──
  static const overview = '/overview';

  // ── Tab 2: Time ──
  static const timeOverview = '/time/overview';
  static const timeSchedule = '/time/schedule';
  static const timeCalendar = '/time/calendar';
  static const timeTasks = '/time/tasks';

  // ── Tab 3: Finance ──
  static const financeOverview = '/finance/overview';
  static const financeAccounts = '/finance/accounts';
  static const financeCards = '/finance/cards';
  static const financeInvestments = '/finance/investments';
  static const financeLiabilities = '/finance/liabilities';
  static const financeTransactions = '/finance/transactions';

  // ── Tab 4: Energy ──
  static const energyOverview = '/energy/overview';
  static const energyFocus = '/energy/focus';
  static const energyMood = '/energy/mood';
  static const energyGoals = '/energy/goals';
  static const energyIdeas = '/energy/ideas';

  // ── Tab 5: Health ──
  static const healthOverview = '/health/overview';
  static const healthDailyProgress = '/health/daily-progress';
  static const healthFasting = '/health/fasting';
  static const healthHabits = '/health/habits';
  static const healthBody = '/health/body';
  static const healthNutrition = '/health/nutrition';
  static const healthExercise = '/health/exercise';

  // ── Tab 7: Profile ──
  static const profileSettings = '/profile/settings';
  static const profileAccount = '/profile/account';
  static const profileApp = '/profile/app';

  // ── Onboarding ──
  static const onboarding = '/onboarding';

  // ── Daily Check-in ──
  static const checkin = '/checkin';

  // ── Legal ──
  static const terms = '/terms';
  static const privacy = '/privacy';

  // ── Legacy aliases (redirect targets exist) ──
  static const schedule = timeSchedule;
  static const calendar = timeCalendar;
  static const focus = energyFocus;
  static const goals = energyGoals;
  static const settings = profileApp;
  static const habits = healthHabits;
}

// ══════════════════════════════════════════════════════════════
// ONBOARDING STATE PROVIDER
// AsyncNotifier so markOnboarded() updates state immediately —
// the router sees hasOnboarded == true on the same frame as
// context.go(overview), preventing a redirect loop back to /onboarding.
// ══════════════════════════════════════════════════════════════
class OnboardedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefOnboarded) ?? false;
  }

  Future<void> markOnboarded() async {
    state = const AsyncData(true); // instant update → router sees true immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboarded, true);
  }
}

final onboardedProvider =
    AsyncNotifierProvider<OnboardedNotifier, bool>(OnboardedNotifier.new);

// ══════════════════════════════════════════════════════════════
// ROUTER PROVIDER
// ══════════════════════════════════════════════════════════════
final routerProvider = Provider<GoRouter>((ref) {
  // authStateProvider is now a plain Provider<bool> (Clerk isSignedIn)
  final isLoggedIn = ref.watch(authStateProvider);
  // Onboarding — may still be loading (null = unknown, true/false = resolved)
  final onboardedAsync = ref.watch(onboardedProvider);
  final hasOnboarded = onboardedAsync.asData?.value;

  return GoRouter(
    initialLocation: Routes.overview,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/signup') ||
          loc.startsWith('/forgot');
      final isOnboardingRoute = loc.startsWith('/onboarding');

      // Not logged in — send to login
      if (!isLoggedIn && !isAuthRoute) return Routes.login;
      // Logged in, on auth page — decide where to go
      if (isLoggedIn && isAuthRoute) {
        // Wait until we know onboarding state
        if (hasOnboarded == null) return null;
        return hasOnboarded ? Routes.overview : Routes.onboarding;
      }
      // Logged in, not yet onboarded, and not already on onboarding
      if (isLoggedIn && hasOnboarded == false && !isOnboardingRoute) {
        return Routes.onboarding;
      }
      // Logged in, already onboarded, on onboarding route → skip to overview
      if (isLoggedIn && hasOnboarded == true && isOnboardingRoute) {
        return Routes.overview;
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      // ── Onboarding ─────────────────────────────────────────
      GoRoute(
          path: Routes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      // ── Daily Check-in ────────────────────────────────────
      GoRoute(
          path: Routes.checkin,
          builder: (_, state) => DailyCheckinScreen(
              mode: state.uri.queryParameters['mode'] ?? 'morning')),
      // ── Legal ─────────────────────────────────────────────
      GoRoute(path: Routes.terms,   builder: (_, __) => const TermsScreen()),
      GoRoute(path: Routes.privacy, builder: (_, __) => const PrivacyScreen()),

      // ── Shell (authenticated) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.matchedLocation, child: child),
        routes: [
          // ── Tab 1: Overview ──────────────────────────────
          GoRoute(
            path: Routes.overview,
            builder: (_, __) => const OverviewScreen(),
          ),

          // ── Tab 2: Time ──────────────────────────────────
          GoRoute(path: '/time', redirect: (_, __) => Routes.timeOverview),
          GoRoute(
            path: Routes.timeOverview,
            builder: (_, __) => const TimeOverviewScreen(),
          ),
          GoRoute(
            path: Routes.timeSchedule,
            builder: (_, __) => const ScheduleScreen(),
            routes: [
              GoRoute(
                path: 'edit-block',
                builder: (_, state) => EditBlockScreen(
                  blockId: state.uri.queryParameters['id'],
                  scheduleMode:
                      state.uri.queryParameters['mode'] ?? 'normal',
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.timeCalendar,
            builder: (_, __) => const CalendarScreen(),
            routes: [
              GoRoute(
                path: 'event',
                builder: (_, state) => EventDetailScreen(
                  eventId: state.uri.queryParameters['id'],
                  initialDate: state.uri.queryParameters['date'] != null
                      ? DateTime.tryParse(
                          state.uri.queryParameters['date']!)
                      : null,
                ),
              ),
            ],
          ),

          GoRoute(
            path: Routes.timeTasks,
            builder: (_, __) => const TimeTasksScreen(),
          ),

          // ── Tab 3: Finance ────────────────────────────────
          GoRoute(
              path: '/finance',
              redirect: (_, __) => Routes.financeOverview),
          GoRoute(
            path: Routes.financeOverview,
            builder: (_, __) => const FinanceOverviewScreen(),
          ),
          GoRoute(
            path: Routes.financeAccounts,
            builder: (_, __) => const FinanceAccountsScreen(),
          ),
          GoRoute(
            path: Routes.financeCards,
            builder: (_, __) => const FinanceCardsScreen(),
          ),
          GoRoute(
            path: Routes.financeInvestments,
            builder: (_, __) => const FinanceInvestmentsScreen(),
          ),
          GoRoute(
            path: Routes.financeLiabilities,
            builder: (_, __) => const FinanceLiabilitiesScreen(),
          ),
          GoRoute(
            path: Routes.financeTransactions,
            builder: (_, __) => const FinanceTransactionsScreen(),
          ),

          // ── Tab 4: Energy ─────────────────────────────────
          GoRoute(
              path: '/energy', redirect: (_, __) => Routes.energyOverview),
          GoRoute(
            path: Routes.energyOverview,
            builder: (_, __) => const EnergyOverviewScreen(),
          ),
          GoRoute(
            path: Routes.energyFocus,
            builder: (_, __) => const FocusScreen(),
          ),
          GoRoute(
            path: Routes.energyMood,
            builder: (_, __) => const EnergyMoodScreen(),
          ),
          GoRoute(
            path: Routes.energyGoals,
            builder: (_, __) => const GoalsScreen(),
          ),
          GoRoute(
            path: Routes.energyIdeas,
            builder: (_, __) => const IdeasScreen(),
          ),
          // Legacy redirect: habits moved to Health
          GoRoute(
              path: '/energy/habits',
              redirect: (_, __) => Routes.healthHabits),

          // ── Tab 5: Health ─────────────────────────────────
          GoRoute(
              path: '/health', redirect: (_, __) => Routes.healthOverview),
          GoRoute(
            path: Routes.healthOverview,
            builder: (_, __) => const HealthOverviewScreen(),
          ),
          GoRoute(
            path: Routes.healthDailyProgress,
            builder: (_, __) => const HealthDailyProgressScreen(),
          ),
          GoRoute(
            path: Routes.healthFasting,
            builder: (_, __) => const HealthFastingScreen(),
          ),
          GoRoute(
            path: Routes.healthHabits,
            builder: (_, __) => const HealthHabitsScreen(),
          ),
          GoRoute(
            path: Routes.healthBody,
            builder: (_, __) => const HealthBodyScreen(),
          ),
          GoRoute(
            path: Routes.healthNutrition,
            builder: (_, __) => const HealthNutritionScreen(),
          ),
          GoRoute(
            path: Routes.healthExercise,
            builder: (_, __) => const HealthExerciseScreen(),
          ),

          // ── Tab 7: Profile ────────────────────────────────
          GoRoute(
              path: '/profile',
              redirect: (_, __) => Routes.profileSettings),
          GoRoute(
            path: Routes.profileSettings,
            builder: (_, __) => const ProfileSettingsScreen(),
          ),
          GoRoute(
            path: Routes.profileAccount,
            builder: (_, __) => const ProfileAccountScreen(),
          ),
          GoRoute(
            path: Routes.profileApp,
            builder: (_, __) => const ProfileAppSettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF08070C),
      body: Center(
        child: Text(
          'Not found: ${state.error}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    ),
  );
});
