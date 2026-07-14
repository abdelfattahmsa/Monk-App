import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/schedule_modes_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loaded = false;
  String _scheduleMode = 'normal';
  bool _alarmsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _scheduleMode = prefs.getString(AppConstants.prefScheduleMode) ?? 'normal';
      _alarmsEnabled = prefs.getBool(AppConstants.prefAlarmsEnabled) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setScheduleMode(String mode) async {
    setState(() => _scheduleMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefScheduleMode, mode);
  }

  Future<void> _setAlarmsEnabled(bool enabled) async {
    setState(() => _alarmsEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefAlarmsEnabled, enabled);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final scheduleMode = _scheduleMode;
    final alarmsEnabled = _alarmsEnabled;
    final modes = ref.watch(scheduleModesProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: Spacing.pagePadding(context),
                children: [
                  // Header
                  Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
                  const Gap(Spacing.xs),
                  Text(
                    'Preferences & account',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Gap(Spacing.xl),

                  // ── Profile card ────────────────────────────
                  _SectionLabel(label: 'ACCOUNT'),
                  const Gap(10),
                  _ProfileCard(user: user),
                  const Gap(24),

                  // ── Schedule preferences ────────────────────
                  _SectionLabel(label: 'SCHEDULE'),
                  const Gap(10),
                  _SettingsTile(
                    icon: Icons.calendar_view_day_outlined,
                    label: 'Schedule Mode',
                    trailing: DropdownButton<String>(
                      value: scheduleMode,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                      items: modes
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text('${m.emoji} ${m.label}'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _setScheduleMode(v);
                      },
                    ),
                  ),
                  const Gap(8),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Block Alarms',
                    trailing: Switch(
                      value: alarmsEnabled,
                      onChanged: _setAlarmsEnabled,
                    ),
                  ),
                  const Gap(24),

                  // ── Appearance ──────────────────────────────
                  _SectionLabel(label: 'APPEARANCE'),
                  const Gap(10),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Theme',
                    trailing: Text(
                      'Dark',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const Gap(24),

                  // ── Account actions ─────────────────────────
                  _SectionLabel(label: 'ACTIONS'),
                  const Gap(10),
                  _ActionTile(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    color: AppColors.error,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(authNotifierProvider.notifier).signOut();
                              },
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Gap(32),

                  // ── App info ────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, AppColors.goldDim],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Monk',
                              style: TextStyle(
                                color: AppColors.bg,
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const Gap(10),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontFamily: 'PlayfairDisplay',
                              ),
                        ),
                        const Gap(2),
                        Text(
                          'v${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Gap(4),
                        Text(
                          'Built for Abdelfattah',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.goldDim,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(40),
                ],
              ),
      ),
    );
  }

}

// ── Helper widgets ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.goldDim,
            letterSpacing: 2,
          ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Loading...';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty && name != 'Loading...' ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.goldDim,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.gold,
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (email.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const Gap(12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Gap(12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}