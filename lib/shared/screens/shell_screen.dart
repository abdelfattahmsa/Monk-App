import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/providers/pillar_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/models/all_providers.dart';
import '../../services/notification_service.dart';
import '../../services/web_notif.dart';
import '../../shared/widgets/quick_capture_fab.dart';
import '../../l10n/app_localizations.dart';

const _shellUuid = Uuid();

// ══════════════════════════════════════════════════════════════
// NAVIGATION MODEL
// ══════════════════════════════════════════════════════════════

class AppSubTab {
  const AppSubTab({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}

class AppTab {
  const AppTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.subTabs = const [],
  });
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  /// The route navigated to when this tab is tapped.
  /// For tabs with sub-tabs this points to the first sub-tab.
  final String route;
  final List<AppSubTab> subTabs;
  bool get hasSubTabs => subTabs.isNotEmpty;
}

// ── 6 MAIN TABS ──────────────────────────────────────────────
const kAppTabs = <AppTab>[
  AppTab(
    id: 'overview',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: Routes.overview,
  ),
  AppTab(
    id: 'time',
    label: 'Time',
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule_rounded,
    route: Routes.timeOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.timeOverview),
      AppSubTab(
          label: 'Calendar',
          icon: Icons.event_outlined,
          route: Routes.timeCalendar),
      AppSubTab(
          label: 'Schedule',
          icon: Icons.view_timeline_outlined,
          route: Routes.timeSchedule),
      AppSubTab(
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          route: Routes.timeTasks),
    ],
  ),
  AppTab(
    id: 'finance',
    label: 'Finance',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    route: Routes.financeOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.financeOverview),
      AppSubTab(
          label: 'Accounts',
          icon: Icons.account_balance_outlined,
          route: Routes.financeAccounts),
      AppSubTab(
          label: 'Cards',
          icon: Icons.credit_card_outlined,
          route: Routes.financeCards),
      AppSubTab(
          label: 'Invest',
          icon: Icons.trending_up_outlined,
          route: Routes.financeInvestments),
      AppSubTab(
          label: 'Debts',
          icon: Icons.trending_down_outlined,
          route: Routes.financeLiabilities),
      AppSubTab(
          label: 'Txns',
          icon: Icons.receipt_long_outlined,
          route: Routes.financeTransactions),
    ],
  ),
  AppTab(
    id: 'energy',
    label: 'Energy',
    icon: Icons.bolt_outlined,
    activeIcon: Icons.bolt_rounded,
    route: Routes.energyOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.energyOverview),
      AppSubTab(
          label: 'Focus',
          icon: Icons.timer_outlined,
          route: Routes.energyFocus),
      AppSubTab(
          label: 'Mood',
          icon: Icons.sentiment_satisfied_alt_outlined,
          route: Routes.energyMood),
      AppSubTab(
          label: 'Goals',
          icon: Icons.flag_outlined,
          route: Routes.energyGoals),
      AppSubTab(
          label: 'Ideas',
          icon: Icons.lightbulb_outline,
          route: Routes.energyIdeas),
    ],
  ),
  AppTab(
    id: 'health',
    label: 'Health',
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite_rounded,
    route: Routes.healthOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.healthOverview),
      AppSubTab(
          label: 'Progress',
          icon: Icons.trending_up_outlined,
          route: Routes.healthDailyProgress),
      AppSubTab(
          label: 'Fasting',
          icon: Icons.hourglass_empty,
          route: Routes.healthFasting),
      AppSubTab(
          label: 'Habits',
          icon: Icons.check_circle_outline,
          route: Routes.healthHabits),
      AppSubTab(
          label: 'Body',
          icon: Icons.monitor_weight_outlined,
          route: Routes.healthBody),
      AppSubTab(
          label: 'Nutrition',
          icon: Icons.restaurant_outlined,
          route: Routes.healthNutrition),
      AppSubTab(
          label: 'Exercise',
          icon: Icons.fitness_center_outlined,
          route: Routes.healthExercise),
    ],
  ),
  AppTab(
    id: 'profile',
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
    route: Routes.profileSettings,
    subTabs: [
      AppSubTab(
          label: 'Profile',
          icon: Icons.person_outline,
          route: Routes.profileSettings),
      AppSubTab(
          label: 'Account',
          icon: Icons.manage_accounts_outlined,
          route: Routes.profileAccount),
      AppSubTab(
          label: 'App',
          icon: Icons.tune_outlined,
          route: Routes.profileApp),
    ],
  ),
];

// ══════════════════════════════════════════════════════════════
// LOCALIZATION HELPERS
// ══════════════════════════════════════════════════════════════

extension AppTabL10n on AppTab {
  String localizedLabel(AppLocalizations l) {
    switch (id) {
      case 'overview': return l.tabOverview;
      case 'time':     return l.tabTime;
      case 'finance':  return l.tabFinance;
      case 'energy':   return l.tabEnergy;
      case 'health':   return l.tabHealth;
      case 'profile':  return l.tabProfile;
      default:         return label;
    }
  }
}

extension AppSubTabL10n on AppSubTab {
  String localizedLabel(AppLocalizations l) {
    switch (route) {
      // shared "Overview"
      case Routes.timeOverview:
      case Routes.financeOverview:
      case Routes.energyOverview:
      case Routes.healthOverview:
        return l.subOverview;
      // Time
      case Routes.timeCalendar:   return l.subCalendar;
      case Routes.timeSchedule:   return l.subSchedule;
      case Routes.timeTasks:      return l.subTasks;
      // Finance
      case Routes.financeAccounts:     return l.subAccounts;
      case Routes.financeCards:        return l.subCards;
      case Routes.financeInvestments:  return l.subInvest;
      case Routes.financeLiabilities:  return l.subDebts;
      case Routes.financeTransactions: return l.subTxns;
      // Energy
      case Routes.energyFocus: return l.subFocus;
      case Routes.energyMood:  return l.subMood;
      case Routes.energyGoals: return l.subGoals;
      case Routes.energyIdeas: return l.subIdeas;
      // Health
      case Routes.healthDailyProgress: return l.subProgress;
      case Routes.healthFasting:        return l.subFasting;
      case Routes.healthHabits:         return l.subHabits;
      case Routes.healthBody:           return l.subBody;
      case Routes.healthNutrition:      return l.subNutrition;
      case Routes.healthExercise:       return l.subExercise;
      // Profile
      case Routes.profileSettings: return l.tabProfile;
      case Routes.profileAccount:  return l.subAccount;
      case Routes.profileApp:      return l.subApp;
      default: return label;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// SHELL SCREEN
// ══════════════════════════════════════════════════════════════

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  bool _showNotifBanner = false;
  bool _emailBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkNotifBanner();
  }

  Future<void> _checkNotifBanner() async {
    if (!kIsWeb) return;
    if (webNotifsGranted) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('notif_banner_dismissed') ?? false;
    if (!dismissed && mounted) setState(() => _showNotifBanner = true);
  }

  Future<void> _enableNotifications() async {
    final granted = await requestWebNotifPermission();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_banner_dismissed', true);
    if (!mounted) return;
    setState(() => _showNotifBanner = false);
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Notifications enabled')),
      );
    }
  }

  Future<void> _dismissNotifBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_banner_dismissed', true);
    if (mounted) setState(() => _showNotifBanner = false);
  }

  /// Unified notify — web browser notification on web, flutter_local_notifications on desktop/mobile.
  void _notify(String title, {String? body}) {
    if (kIsWeb) {
      showWebNotif(title, body: body);
    } else {
      NotificationService.instance.showInstant(title: title, body: body ?? '');
    }
  }

  int _activeTabIndex(List<AppTab> tabs) {
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      for (final sub in tab.subTabs) {
        if (widget.location.startsWith(sub.route)) return i;
      }
      if (!tab.hasSubTabs && widget.location.startsWith(tab.route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // ── Focus timer completion ─────────────────────────────────
    ref.listen<FocusTimerState>(focusTimerProvider, (prev, next) {
      if (next.completedAt != null && prev?.completedAt == null) {
        _onFocusComplete(next);
      }
    });

    // ── Fasting events ─────────────────────────────────────────
    ref.listen<FastingState>(fastingProvider, (prev, next) {
      if (!mounted) return;
      // Fast just started
      if (prev?.isFasting == false && next.isFasting == true) {
        _notify('⏱ Fast started',
            body: 'Your ${next.active!.goalHours}h fast has begun. Stay strong!');
      }
      // Goal just reached
      if (prev?.active?.goalReached == false && next.active?.goalReached == true) {
        _notify('🌟 Fasting goal reached!',
            body: "You've hit your ${next.active!.goalHours}h goal. Keep going!");
      }
      // Fast just ended
      if (prev?.isFasting == true && next.isFasting == false) {
        final last = next.history.isNotEmpty ? next.history.last : null;
        if (last != null) {
          final h = last.duration.inHours;
          final m = last.duration.inMinutes % 60;
          _notify('✅ Fast complete!',
              body: 'You fasted for ${h}h ${m}m. Great work!');
        }
      }
    });

    // ── All habits done today ──────────────────────────────────
    ref.listen<({int done, int total, double pct})>(
        habitsTodayProvider, (prev, next) {
      if (!mounted) return;
      if ((prev?.pct ?? 0) < 1.0 && next.pct >= 1.0 && next.total > 0) {
        _notify('🎉 All habits done!',
            body: 'You completed all ${next.total} habits for today!');
      }
    });

    // ── Email verification banner ──────────────────────────────
    final isEmailVerified = ref.watch(isEmailVerifiedProvider);
    final isLoggedIn      = ref.watch(authStateProvider);
    final currentUser     = ref.watch(currentUserProvider);
    final showEmailBanner =
        isLoggedIn && !isEmailVerified && !_emailBannerDismissed;

    // ── Visible tabs (pillar-filtered) ─────────────────────────
    final visibleTabs = ref.watch(visibleTabsProvider);
    final tabIndex = _activeTabIndex(visibleTabs);
    final activeTab = visibleTabs[tabIndex];

    Widget shell;
    if (Breakpoints.isWide(context)) {
      shell = _DesktopShell(
        tabs: visibleTabs,
        location: widget.location,
        tabIndex: tabIndex,
        child: widget.child,
      );
    } else {
      shell = _MobileShell(
        tabs: visibleTabs,
        location: widget.location,
        activeTab: activeTab,
        tabIndex: tabIndex,
        child: widget.child,
      );
    }

    final hasBanners = _showNotifBanner || showEmailBanner;
    if (!hasBanners) return shell;

    return Column(
      children: [
        if (showEmailBanner)
          _EmailVerificationBanner(
            email: currentUser?.email ?? '',
            onResend: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(authNotifierProvider.notifier)
                  .resendVerification(currentUser?.email ?? '');
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('✉️ Verification email resent!')),
                );
              }
            },
            onDismiss: () => setState(() => _emailBannerDismissed = true),
          ),
        if (_showNotifBanner)
          _NotifPermissionBanner(
            onEnable: _enableNotifications,
            onDismiss: _dismissNotifBanner,
          ),
        Expanded(child: shell),
      ],
    );
  }

  void _onFocusComplete(FocusTimerState state) {
    final elapsed = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inSeconds
        : state.totalSeconds;
    final session = FocusSession(
      id: _shellUuid.v4(),
      date: DateTime.now(),
      blockLabel: state.selectedBlockLabel.isEmpty
          ? 'Free session'
          : state.selectedBlockLabel,
      blockCategoryKey: state.selectedBlockCategory,
      plannedSeconds: state.totalSeconds,
      actualSeconds: elapsed,
      completed: true,
      note: state.note.isNotEmpty ? state.note : null,
      startedAt: state.startedAt,
    );
    ref.read(focusSessionsProvider.notifier).add(session);
    final msg = state.mode == 'focus'
        ? '🍅 Focus session complete!'
        : '☕ Break over!';
    _notify(msg, body: 'Tap to return to Monk');
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    // Auto-reset after 3 seconds
    Timer(const Duration(seconds: 3), () {
      ref.read(focusTimerProvider.notifier).reset();
    });
  }
}

// ── Sign-out confirmation ────────────────────────────────────────
Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.signOutTitle),
      content: Text(l.signOutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            l.signOut,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref.read(authNotifierProvider.notifier).signOut();
  }
}

// ══════════════════════════════════════════════════════════════
// DESKTOP SHELL
// ══════════════════════════════════════════════════════════════

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell({
    required this.tabs,
    required this.location,
    required this.tabIndex,
    required this.child,
  });
  final List<AppTab> tabs;
  final String location;
  final int tabIndex;
  final Widget child;

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expanded = Breakpoints.isDesktop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final railWidth = _expanded ? 200.0 : 64.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const QuickCaptureFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Row(
        children: [
          // ── Sidebar ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: railWidth,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                  right: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Column(
              children: [
                _SidebarProfileHeader(
                  expanded: _expanded,
                  onToggle: () =>
                      setState(() => _expanded = !_expanded),
                ),
                // ── Profile sub-tabs (visible when on any /profile route) ──
                Builder(builder: (ctx) {
                  final isProfileActive =
                      widget.tabIndex == widget.tabs.length - 1;
                  final profileTab = widget.tabs.last;
                  if (!isProfileActive || !profileTab.hasSubTabs) {
                    return Divider(height: 1, color: borderColor);
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      if (_expanded)
                        for (final sub in profileTab.subTabs)
                          _SidebarSubTabItem(
                            sub: sub,
                            active: widget.location.startsWith(sub.route),
                            onTap: () => context.go(sub.route),
                          )
                      else
                        for (final sub in profileTab.subTabs)
                          _SidebarSubTabItemCollapsed(
                            sub: sub,
                            active: widget.location.startsWith(sub.route),
                            onTap: () => context.go(sub.route),
                          ),
                      const SizedBox(height: 4),
                      Divider(height: 1, color: borderColor),
                    ],
                  );
                }),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.sm),
                    children: [
                      // Show all tabs except Profile (last) — Profile card lives at top
                      for (var i = 0; i < widget.tabs.length - 1; i++) ...[
                        _SidebarTabItem(
                          tab: widget.tabs[i],
                          active: i == widget.tabIndex,
                          expanded: _expanded,
                          onTap: () => context.go(widget.tabs[i].route),
                        ),
                        // Sub-tabs shown when this tab is active
                        if (i == widget.tabIndex &&
                            widget.tabs[i].hasSubTabs &&
                            _expanded)
                          for (final sub in widget.tabs[i].subTabs)
                            _SidebarSubTabItem(
                              sub: sub,
                              active: widget.location.startsWith(sub.route),
                              onTap: () => context.go(sub.route),
                            ),
                        // Collapsed: show active sub-tab indicator dot
                        if (i == widget.tabIndex &&
                            widget.tabs[i].hasSubTabs &&
                            !_expanded)
                          for (final sub in widget.tabs[i].subTabs)
                            _SidebarSubTabItemCollapsed(
                              sub: sub,
                              active: widget.location.startsWith(sub.route),
                              onTap: () => context.go(sub.route),
                            ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                _SidebarFooter(expanded: _expanded),
              ],
            ),
          ),
          // ── Content ──
          Expanded(child: ClipRect(child: widget.child)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MOBILE SHELL
// ══════════════════════════════════════════════════════════════

class _MobileShell extends ConsumerWidget {
  const _MobileShell({
    required this.tabs,
    required this.location,
    required this.activeTab,
    required this.tabIndex,
    required this.child,
  });
  final List<AppTab> tabs;
  final String location;
  final AppTab activeTab;
  final int tabIndex;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final isProfileTab = activeTab.id == 'profile';
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const _FocusTimerBanner(),
          // Sub-tab bar sits at top of body when tab has sub-tabs
          if (activeTab.hasSubTabs)
            _MobileSubTabBar(
              subTabs: activeTab.subTabs,
              location: location,
              trailing: isProfileTab
                  ? _MobileSignOutButton(ref: ref)
                  : null,
            ),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: const QuickCaptureFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) => context.go(tabs[i].route),
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.localizedLabel(l),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MOBILE SUB-TAB BAR
// ══════════════════════════════════════════════════════════════

class _MobileSubTabBar extends StatelessWidget {
  const _MobileSubTabBar({
    required this.subTabs,
    required this.location,
    this.trailing,
  });
  final List<AppSubTab> subTabs;
  final String location;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Horizontally scrollable so Finance (6 sub-tabs) fits on small screens
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final sub in subTabs)
                    _MobileSubTabItem(
                      sub: sub,
                      active: location.startsWith(sub.route),
                      textSecondary: textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            VerticalDivider(width: 1, color: borderColor),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Sign-out icon for the mobile profile sub-tab bar
class _MobileSignOutButton extends StatelessWidget {
  const _MobileSignOutButton({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 44,
      height: 40,
      child: IconButton(
        icon: Icon(Icons.logout_rounded, size: 17, color: textSecondary),
        tooltip: l.signOut,
        onPressed: () => _confirmSignOut(context, ref),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _MobileSubTabItem extends StatelessWidget {
  const _MobileSubTabItem({
    required this.sub,
    required this.active,
    required this.textSecondary,
  });
  final AppSubTab sub;
  final bool active;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.go(sub.route),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Minimum width per tab; enough for icon + short label
        width: 80,
        height: 40,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sub.icon,
                    size: 14,
                    color: active ? accent : textSecondary,
                  ),
                  const Gap(4),
                  Text(
                    sub.localizedLabel(l),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? accent : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SIDEBAR COMPONENTS
// ══════════════════════════════════════════════════════════════

class _SidebarProfileHeader extends ConsumerWidget {
  const _SidebarProfileHeader({
    required this.expanded,
    required this.onToggle,
  });
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    final initial = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : (user != null && user.email.isNotEmpty ? user.email[0].toUpperCase() : '?');

    Widget avatar({double radius = 18}) => CircleAvatar(
          radius: radius,
          backgroundImage: user?.avatarUrl != null
              ? NetworkImage(user!.avatarUrl!)
              : null,
          backgroundColor: accent.withValues(alpha: 0.15),
          child: user?.avatarUrl == null
              ? Text(
                  initial,
                  style: TextStyle(
                    color: accent,
                    fontSize: radius * 0.67,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                )
              : null,
        );

    if (!expanded) {
      return InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Center(child: avatar(radius: 16)),
        ),
      );
    }

    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(kAppTabs.last.route),
            child: avatar(radius: 18),
          ),
          const Gap(10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(kAppTabs.last.route),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.fullName?.isNotEmpty == true
                        ? user!.fullName!
                        : l.myProfile,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: textMuted,
                      fontFamily: 'Roboto',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 15),
            color: textMuted,
            tooltip: l.signOut,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: onToggle,
            icon: const Icon(Icons.chevron_left_rounded, size: 16),
            color: textMuted,
            tooltip: l.collapse,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SidebarTabItem extends StatelessWidget {
  const _SidebarTabItem({
    required this.tab,
    required this.active,
    required this.expanded,
    required this.onTap,
  });
  final AppTab tab;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final color = active ? accent : textSecondary;
    final l = AppLocalizations.of(context)!;
    final tabLabel = tab.localizedLabel(l);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 8.0 : 6.0,
        vertical: 1,
      ),
      child: Material(
        color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: accent.withValues(alpha: 0.06),
          child: Tooltip(
            message: expanded ? '' : tabLabel,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12.0 : 0,
                vertical: expanded ? 9.0 : 12.0,
              ),
              child: expanded
                  ? Row(
                      children: [
                        Icon(active ? tab.activeIcon : tab.icon,
                            color: color, size: 18),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            tabLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        if (active && !tab.hasSubTabs)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                        if (tab.hasSubTabs)
                          Icon(
                            active
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 14,
                            color: textSecondary,
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(active ? tab.activeIcon : tab.icon,
                          color: color, size: 20),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSubTabItem extends StatelessWidget {
  const _SidebarSubTabItem({
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final AppSubTab sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final color = active ? accent : textSecondary;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 1, bottom: 1),
      child: Material(
        color: active ? accent.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // Connector line
                Container(
                  width: 1,
                  height: 14,
                  color: active
                      ? accent.withValues(alpha: 0.5)
                      : (isDark
                          ? AppColors.border
                          : AppColors.lightBorder),
                  margin: const EdgeInsets.only(right: 10),
                ),
                Icon(sub.icon, color: color, size: 14),
                const Gap(8),
                Text(
                  sub.localizedLabel(l),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSubTabItemCollapsed extends StatelessWidget {
  const _SidebarSubTabItemCollapsed({
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final AppSubTab sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Tooltip(
        message: sub.localizedLabel(l),
        child: Material(
          color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 36,
              child: Center(
                child: Icon(
                  sub.icon,
                  size: 15,
                  color: active ? accent : textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    Widget iconBtn(IconData icon, String tooltip, VoidCallback onTap) =>
        Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              hoverColor: textMuted.withValues(alpha: 0.1),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(icon, size: 15, color: textMuted),
                ),
              ),
            ),
          ),
        );

    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          iconBtn(
            Icons.chat_bubble_outline_rounded,
            l.support,
            () => launchUrl(Uri.parse('mailto:support@prp-app.website')),
          ),
          const Gap(2),
          iconBtn(
            Icons.description_outlined,
            l.termsPrivacy,
            () => context.go(Routes.terms),
          ),
          if (expanded) ...[
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse('https://kyberia.tech')),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✳',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Kyberia',
                    style: TextStyle(
                      fontSize: 9,
                      color: textMuted,
                      fontFamily: 'Roboto',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
          ] else ...[
            const Gap(2),
            Tooltip(
              message: 'Kyberia',
              child: GestureDetector(
                onTap: () =>
                    launchUrl(Uri.parse('https://kyberia.tech')),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Text(
                      '✳',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EMAIL VERIFICATION BANNER
// ══════════════════════════════════════════════════════════════

class _EmailVerificationBanner extends StatelessWidget {
  const _EmailVerificationBanner({
    required this.email,
    required this.onResend,
    required this.onDismiss,
  });
  final String email;
  final VoidCallback onResend;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const bannerColor = Color(0xFFF59E0B); // amber
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = bannerColor.withValues(alpha: isDark ? 0.10 : 0.08);
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              size: 15, color: bannerColor),
          const Gap(10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: textColor),
                children: [
                  const TextSpan(text: 'Please verify your email '),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(text: ' to unlock all features.'),
                ],
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: onResend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Resend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// NOTIFICATION PERMISSION BANNER
// ══════════════════════════════════════════════════════════════

class _NotifPermissionBanner extends StatelessWidget {
  const _NotifPermissionBanner({
    required this.onEnable,
    required this.onDismiss,
  });
  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = accent.withValues(alpha: isDark ? 0.09 : 0.07);
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined, size: 15, color: accent),
          const Gap(10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.notificationsPrompt,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
          const Gap(10),
          GestureDetector(
            onTap: onEnable,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppLocalizations.of(context)!.enableNotifications,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }
}

// ── Persistent focus timer banner ─────────────────────────────

class _FocusTimerBanner extends ConsumerWidget {
  const _FocusTimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    if (!timer.isRunning) return const SizedBox.shrink();

    final mins = (timer.secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (timer.secondsLeft % 60).toString().padLeft(2, '0');
    final l = AppLocalizations.of(context)!;
    final label = timer.mode == 'focus' ? l.focus : l.breakLabel;
    final color = timer.mode == 'focus' ? AppColors.accent : AppColors.warning;

    return Material(
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => GoRouter.of(context).go(Routes.energyFocus),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.timer_rounded, size: 16, color: color),
              const Gap(8),
              Text(
                '$label — $mins:$secs',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 3,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const Gap(8),
              Icon(Icons.chevron_right_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}