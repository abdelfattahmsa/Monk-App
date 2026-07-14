import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../shared/screens/shell_screen.dart';

// ── Pillars that can be toggled on/off ───────────────────────────
// 'overview' and 'profile' are always visible.
const kToggleablePillars = ['time', 'finance', 'energy', 'health'];
const kDefaultActivePillars = {'time', 'finance', 'energy', 'health'};

// ── State + Notifier ─────────────────────────────────────────────

class PillarNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefActivePillars);
    if (stored == null) return Set.from(kDefaultActivePillars);
    // Always ensure at least one pillar is active
    final result = stored.toSet().intersection(Set.from(kToggleablePillars));
    return result.isEmpty ? Set.from(kDefaultActivePillars) : result;
  }

  Future<void> toggle(String pillarId) async {
    final current = await future;
    final updated = Set<String>.from(current);
    if (updated.contains(pillarId)) {
      // Prevent turning off the last active pillar
      if (updated.length <= 1) return;
      updated.remove(pillarId);
    } else {
      updated.add(pillarId);
    }
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefActivePillars, updated.toList());
  }

  bool isActive(String pillarId) {
    return state.asData?.value.contains(pillarId) ?? true;
  }
}

final pillarProvider =
    AsyncNotifierProvider<PillarNotifier, Set<String>>(PillarNotifier.new);

/// Filtered tab list — always includes overview + profile, filtered by active pillars.
final visibleTabsProvider = Provider<List<AppTab>>((ref) {
  final pillarsAsync = ref.watch(pillarProvider);
  final active = pillarsAsync.asData?.value ?? kDefaultActivePillars;
  return kAppTabs.where((tab) {
    if (tab.id == 'overview' || tab.id == 'profile') return true;
    return active.contains(tab.id);
  }).toList();
});
