import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../shared/models/all_providers.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════
// ONBOARDING SCREEN  — 5-page guided tour
// Page 0: Welcome + four resources
// Page 1: App tour (swipeable pillar cards)
// Page 2: Default currency setup
// Page 3: Add first habit
// Page 4: All set + Getting Started checklist preview
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _animating = false; // guard against double-tap during page transition

  // Step 3 — first habit
  final _habitCtrl = TextEditingController();
  String _habitIcon = '⭐';
  bool _habitSaved = false;

  static const _habitSuggestions = [
    ('⭐', 'Morning routine'),
    ('📖', 'Read 20 minutes'),
    ('🏃', 'Exercise'),
    ('💧', 'Drink 2L water'),
    ('😴', 'Sleep before midnight'),
    ('🧘', 'Meditate 10 minutes'),
  ];

  static const _totalPages = 5;

  @override
  void dispose() {
    _controller.dispose();
    _habitCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_animating) return;
    if (_currentPage < _totalPages - 1) {
      setState(() => _animating = true);
      await _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      if (mounted) setState(() => _animating = false);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    // Instant state update → router sees true immediately, no redirect loop
    await ref.read(onboardedProvider.notifier).markOnboarded();
    if (mounted) context.go(Routes.overview);
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        ref.watch(currencyNotifierProvider).asData?.value ?? 'EGP';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress + Skip ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: const Text('Skip',
                          style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),

            const Gap(8),

            // ── Page content ────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const _WelcomePage(),
                  const _TourPage(),
                  _CurrencyPage(
                    selected: currency,
                    onSelect: (v) =>
                        ref.read(currencyNotifierProvider.notifier).set(v),
                  ),
                  _FirstHabitPage(
                    ctrl: _habitCtrl,
                    icon: _habitIcon,
                    saved: _habitSaved,
                    suggestions: _habitSuggestions,
                    onIconSelect: (ic) => setState(() => _habitIcon = ic),
                    onSave: _saveHabit,
                  ),
                  const _AllSetPage(),
                ],
              ),
            ),

            // ── Bottom button ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Open Monk 🚀'
                        : _currentPage == 3
                            ? 'Almost done →'
                            : 'Next →',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHabit() async {
    final name = _habitCtrl.text.trim();
    if (name.isEmpty) return;
    final habit = Habit(id: _uuid.v4(), name: name, icon: _habitIcon);
    await ref.read(habitsProvider.notifier).add(habit);
    if (mounted) setState(() => _habitSaved = true);
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 0 — Welcome
// ══════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accentFaint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.accentDim, width: 1.5),
            ),
            child: const Center(
              child: Text('🧭', style: TextStyle(fontSize: 48)),
            ),
          ),
          const Gap(32),
          Text(
            'Welcome to Monk',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            'Your Personal Resource Planner.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'Monk helps you manage the four resources that determine the quality of your life:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: const [
              _ResourceChip(emoji: '💰', label: 'Money'),
              _ResourceChip(emoji: '⏰', label: 'Time'),
              _ResourceChip(emoji: '⚡', label: 'Energy'),
              _ResourceChip(emoji: '❤️', label: 'Health'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 1 — App Tour
// ══════════════════════════════════════════════════════════════

class _TourPage extends StatefulWidget {
  const _TourPage();

  @override
  State<_TourPage> createState() => _TourPageState();
}

class _TourPageState extends State<_TourPage> {
  final _innerCtrl = PageController();
  int _activePillar = 0;

  static const _pillars = [
    _PillarData(
      emoji: '💰',
      label: 'Finance',
      desc: 'Manage your money & build wealth',
      colorSeed: Color(0xFF22C55E), // green
      screens: [
        _ScreenData('📊', 'Finance Overview',
            'Net worth, spending summary & wealth snapshot'),
        _ScreenData('🏦', 'Accounts', 'Track banks, savings & cash balances'),
        _ScreenData('💳', 'Transactions',
            'Log income, expenses & view spending by category'),
        _ScreenData('📈', 'Investments',
            'Live prices for stocks, crypto & gold'),
        _ScreenData('📉', 'Liabilities',
            'Track loans, credit cards & debt'),
      ],
    ),
    _PillarData(
      emoji: '⏰',
      label: 'Time',
      desc: 'Plan your day & stay on schedule',
      colorSeed: Color(0xFFF59E0B), // amber
      screens: [
        _ScreenData('🗓️', 'Time Overview', 'Your day at a glance'),
        _ScreenData('📅', 'Schedule',
            'Build daily routines with time blocks'),
        _ScreenData('📆', 'Calendar', 'Events, appointments & reminders'),
        _ScreenData('✅', 'Tasks', 'To-do lists & prioritized actions'),
      ],
    ),
    _PillarData(
      emoji: '⚡',
      label: 'Energy',
      desc: 'Boost productivity & track progress',
      colorSeed: Color(0xFFF97316), // orange
      screens: [
        _ScreenData('⚡', 'Energy Overview', 'Productivity dashboard'),
        _ScreenData('⏱️', 'Focus Timer',
            'Pomodoro sessions & deep work tracking'),
        _ScreenData('🎯', 'Goals', 'Set, track & celebrate achievements'),
        _ScreenData('💡', 'Ideas', 'Capture thoughts & inspirations fast'),
      ],
    ),
    _PillarData(
      emoji: '❤️',
      label: 'Health',
      desc: 'Build habits & track your wellness',
      colorSeed: Color(0xFFEC4899), // pink
      screens: [
        _ScreenData('❤️', 'Health Overview', 'Wellness dashboard at a glance'),
        _ScreenData('✅', 'Habits',
            'Daily habit streaks & consistency tracking'),
        _ScreenData('🕐', 'Fasting',
            'Intermittent fasting timer & history'),
        _ScreenData('📊', 'Daily Progress',
            'Body metrics, sleep & health log'),
      ],
    ),
  ];

  @override
  void dispose() {
    _innerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A quick tour',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Gap(6),
              Text(
                'Swipe to explore each pillar and what it can do.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),

        const Gap(16),

        // ── Pillar tab selector ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(_pillars.length, (i) {
              final p = _pillars[i];
              final isActive = i == _activePillar;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activePillar = i);
                    _innerCtrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.colorSeed.withValues(alpha: 0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? p.colorSeed.withValues(alpha: 0.5)
                            : AppColors.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(p.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const Gap(2),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? p.colorSeed
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const Gap(16),

        // ── Inner page content ──────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _innerCtrl,
            onPageChanged: (i) => setState(() => _activePillar = i),
            itemCount: _pillars.length,
            itemBuilder: (_, i) => _PillarTourCard(pillar: _pillars[i]),
          ),
        ),
      ],
    );
  }
}

class _PillarData {
  const _PillarData({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.colorSeed,
    required this.screens,
  });
  final String emoji;
  final String label;
  final String desc;
  final Color colorSeed;
  final List<_ScreenData> screens;
}

class _ScreenData {
  const _ScreenData(this.emoji, this.title, this.subtitle);
  final String emoji;
  final String title;
  final String subtitle;
}

class _PillarTourCard extends StatelessWidget {
  const _PillarTourCard({required this.pillar});
  final _PillarData pillar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pillar.colorSeed.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pillar.colorSeed.withValues(alpha: 0.15),
                    pillar.colorSeed.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Text(pillar.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pillar.label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: pillar.colorSeed,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          pillar.desc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Screen list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                itemCount: pillar.screens.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                itemBuilder: (_, i) {
                  final s = pillar.screens[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: pillar.colorSeed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(s.emoji,
                                style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                s.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 2 — Currency
// ══════════════════════════════════════════════════════════════
class _CurrencyPage extends StatelessWidget {
  const _CurrencyPage({required this.selected, required this.onSelect});

  final String selected;
  final void Function(String) onSelect;

  static const _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];
  static const _flags = ['🇪🇬', '🇺🇸', '🇪🇺', '🇬🇧', '🇸🇦', '🇦🇪'];
  static const _labels = [
    'Egyptian Pound',
    'US Dollar',
    'Euro',
    'British Pound',
    'Saudi Riyal',
    'UAE Dirham',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(
            'Default currency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const Gap(8),
          Text(
            'Used across Finance screens. Change anytime in Settings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const Gap(24),
          Expanded(
            child: ListView.separated(
              itemCount: _currencies.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (ctx, i) {
                final isSelected = _currencies[i] == selected;
                return GestureDetector(
                  onTap: () => onSelect(_currencies[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.accentFaint : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentDim
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_flags[i],
                            style: const TextStyle(fontSize: 24)),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currencies[i],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _labels[i],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 3 — First Habit
// ══════════════════════════════════════════════════════════════
class _FirstHabitPage extends StatelessWidget {
  const _FirstHabitPage({
    required this.ctrl,
    required this.icon,
    required this.saved,
    required this.suggestions,
    required this.onIconSelect,
    required this.onSave,
  });

  final TextEditingController ctrl;
  final String icon;
  final bool saved;
  final List<(String, String)> suggestions;
  final void Function(String) onIconSelect;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(
            'Add your first habit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const Gap(8),
          Text(
            'Small, consistent actions compound. Start with one that matters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const Gap(20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  ctrl.text = s.$2;
                  onIconSelect(s.$1);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${s.$1} ${s.$2}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickEmoji(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: false,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Habit name...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ),
              const Gap(10),
              ElevatedButton(
                onPressed: saved ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  saved ? '✓' : 'Add',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Gap(16),
          AnimatedOpacity(
            opacity: saved ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentDim),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 18),
                  Gap(10),
                  Expanded(
                    child: Text(
                      'Habit saved! Add more in Health → Habits.',
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          const Text(
            'You can skip this step and add habits later.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext context) async {
    const emojis = [
      '⭐', '📖', '🏃', '💧', '😴', '🧘', '🏋️', '🍎', '✍️',
      '🎯', '🧠', '💊', '🚶', '🚴', '🎵', '🌅', '🥗', '🏊', '☕',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, e),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 24))),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) onIconSelect(picked);
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 4 — All Set + Getting Started checklist
// ══════════════════════════════════════════════════════════════
class _AllSetPage extends StatelessWidget {
  const _AllSetPage();

  static const _checklistItems = [
    ('👤', 'Complete your profile', 'Name & avatar'),
    ('🏦', 'Add a bank account', 'Finance → Accounts'),
    ('📅', 'Create your first schedule', 'Time → Schedule'),
    ('🎯', 'Set an active goal', 'Energy → Goals'),
    ('✅', 'Track a habit', 'Health → Habits'),
    ('⏱️', 'Complete a focus session', 'Energy → Focus'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Gap(24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.accentFaint,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accentDim, width: 1.5),
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 44)),
            ),
          ),
          const Gap(24),
          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            'Your Monk is ready. Here\'s your Getting Started checklist — it will appear in your Overview until you complete everything.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),

          // Checklist preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        color: AppColors.accent, size: 18),
                    const Gap(8),
                    Text(
                      'Getting Started',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentFaint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '0 / ${_checklistItems.length}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                ...List.generate(_checklistItems.length, (i) {
                  final item = _checklistItems[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentFaint.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(item.$1,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                item.$3,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Gap(16),
          _TipCard(
            emoji: '📌',
            title: 'Daily habit',
            body:
                'Open Monk each morning — check your score, log sleep, review your schedule.',
          ),
          const Gap(32),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(
      {required this.emoji, required this.title, required this.body});
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
