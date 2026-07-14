# Stage 1 — Codebase Audit

> App under audit: Monk (formerly "PRP System"), package `monk_app` (pubspec.yaml renamed), version 4.1.0+1.
> Audited: 2026-07-14. All file paths are absolute from `/home/user/PRP-APP/`.

---

## 1. Architecture Map vs Intended 6-Layer Hierarchy

### Intended hierarchy (per `ARCHITECTURE.md`)

| Layer | Role | Target |
|-------|------|--------|
| 1 | Infrastructure | `SupabaseService` singleton |
| 2 | Repositories | Per-engine, one per domain |
| 3 | Engine data providers | `AsyncNotifierProvider` per entity |
| 4 | Computed providers | Derived state (summaries, today-pct) |
| 5 | Cross-engine providers | `resourceScoresProvider` |
| 6 | UI providers | Ephemeral (timer, clock) |

### Actual state

**What is properly implemented:**
- Layers 1–6 structurally exist in the codebase.
- Each engine (`money`, `time`, `energy`, `health`, `goals`, `checkin`, `categories`, `ideas`, `religion`) has `data/models`, `data/repositories`, and `providers` folders.
- `resourceScoresProvider` (`lib/core/providers/resource_scores_provider.dart`) correctly watches all engines without circular dependencies.
- `financeSummaryProvider` is a proper computed Layer 4 provider.

**Drift / deviations:**

| Issue | Evidence | Severity |
|-------|----------|----------|
| Religion engine fully present in Monk codebase | `lib/engines/religion/`, `lib/features/religion/`, `lib/core/router/app_router.dart` lines 46–51, 355–372 | High — contradicts stated strategy |
| `SupabaseService` is a 700+ line god class | `lib/services/supabase_service.dart` — all tables in one file; repository layer is just a thin delegation wrapper with no real abstraction | Medium |
| `ScheduleActions` uses static singleton + raw `dynamic ref` | `lib/engines/time/providers/time_providers.dart` lines 51–74 — bypasses Riverpod type system | Medium |
| `scheduleProvider` is `FutureProvider.family`, not `AsyncNotifier` | `lib/engines/time/providers/time_providers.dart` line 46 — inconsistent with all other engine providers | Low |
| `all_providers.dart` barrel re-export still widely imported | `lib/shared/models/all_providers.dart` — most screens import this instead of engine-specific files | Low |
| Onboarding still brands app as "PRP" | `lib/features/onboarding/screens/onboarding_screen.dart` line 172 "Open PRP 🚀" | Low — branding debt |

**Rating: 3/5** — Architecture intent is solid; implementation has meaningful drift in the religion engine (full tab, routes, screens, models, data layer all present) and a god-service problem.

---

## 2. Code Quality

### 2a. State Management Consistency

Two patterns coexist — not a bug, but creates ambiguity:

| Pattern | Where used | Notes |
|---------|-----------|-------|
| Optimistic update (modify `state` directly) | `debtsProvider`, `investmentsProvider`, `habitsProvider` | Faster UI, but can desync on DB error |
| `ref.invalidateSelf()` / `ref.invalidate()` | `bankAccountsProvider.upsert()`, `ScheduleActions` | Correct, re-fetches from DB |
| `AsyncValue.guard()` | `AuthNotifier` methods | Correct error handling |

The habit toggle in `lib/engines/health/providers/health_providers.dart` line 33 is NOT wrapped in `AsyncValue.guard()`. If `HealthRepository.instance.toggleHabitDay()` throws, the local state is updated but the DB write failed — silent data corruption.

### 2b. Error / Loading / Empty State Handling

| State | Quality | Evidence |
|-------|---------|----------|
| Loading | Consistent — `CircularProgressIndicator(strokeWidth: 2)` in most screens | `lib/features/overview/screens/overview_screen.dart` lines 1283–1286 |
| Error | Minimal — usually renders error string inline, no retry UI | `lib/features/overview/screens/overview_screen.dart` line 1288 |
| Empty | Basic — text message ("No habits yet") with no CTA to create first item | `lib/features/overview/screens/overview_screen.dart` lines 1289–1292 |

One dead screen found: `lib/features/health/screens/health_screen.dart` says "Health tracking coming soon" (line 40) but multiple sub-screens (habits, fasting, nutrition, exercise, body) are implemented and routed. This file is unreachable in normal navigation but wastes compilation.

### 2c. Offline Behavior

**Zero offline support.** Every read goes directly to Supabase; no local cache, no queue. `ARCHITECTURE.md` Phase 2 lists this as planned. On a slow connection all screens show loading spinners with no timeout or fallback. On Windows (.exe) this is tolerable; on web it will frustrate any user with latency.

### 2d. Test Coverage

**1 test file, 1 placeholder test.**

```
/home/user/PRP-APP/test/widget_test.dart — line 4: expect(1 + 1, equals(2));
```

Zero functional coverage. Zero widget tests. Zero integration tests. No mocks of Supabase. This is an alpha-level risk: any refactor can silently break behavior.

**Rating: 2/5** for code quality.

### 2e. i18n Completeness (AR vs EN parity)

| Metric | EN | AR |
|--------|----|----|
| ARB file lines | 237 | 90 |
| Keys count | ~49 | ~49 (same keys) |
| Coverage | Navigation labels, action words, health sync strings | Same — 100% key parity |

**Critical finding:** The ARB files cover navigation labels and a handful of common actions. The vast majority of UI strings — finance form labels, schedule block names, error messages, goal descriptions, habit suggestions, onboarding body text — are **hardcoded English strings** in the Dart files. Examples:

- `lib/features/onboarding/screens/onboarding_screen.dart` line 229: `'Welcome to PRP'` (hardcoded)
- `lib/engines/money/data/models/money_models.dart` lines 6–9: all provider names in English constants
- `lib/features/overview/screens/overview_screen.dart` — all card labels hardcoded in English

An Arabic-speaking user switching the locale will get Arabic navigation tabs but English everywhere else. **Arabic support is cosmetic, not functional.**

**Rating: 2/5** for i18n.

### 2f. Accessibility

- No `Semantics` wrappers found in any screen or widget.
- No `excludeSemantics` markers.
- `MergeSemantics` absent.
- Icon buttons (close, retry) have no `tooltip` or `semanticLabel`.

Minimum accessibility bar (screen reader) is not met.

**Rating: 1/5** for accessibility.

---

## 3. Data Layer

### 3a. Schema Review

**Critical finding: `schema.sql` is incomplete/outdated.**

`/home/user/PRP-APP/supabase/schema.sql` defines 10 tables. The app actively queries at least 20 tables. Missing from schema.sql:

| Table | Referenced in code | Has RLS? (unknown) |
|-------|-------------------|---------------------|
| `credit_cards` | `lib/services/supabase_service.dart` line 338 | Unknown — migration not in repo |
| `installment_plans` | `lib/services/supabase_service.dart` line 360 | Unknown |
| `mood_entries` | `lib/services/supabase_service.dart` line 479 | Unknown |
| `body_profiles` | `lib/services/supabase_service.dart` line 500 | Unknown |
| `weight_entries` | `lib/services/supabase_service.dart` line 513 | Unknown |
| `calorie_entries` | `lib/services/supabase_service.dart` line 535 | Unknown |
| `exercise_entries` | `lib/services/supabase_service.dart` line 557 | Unknown |
| `user_categories` | `lib/services/supabase_service.dart` line 648 | Unknown |
| `fasting_records` | `lib/services/supabase_service.dart` line 681 | Unknown |
| `ideas` | `lib/engines/ideas/data/repositories/ideas_repository.dart` | Unknown |
| `user_tasks` | `lib/engines/time/data/repositories/time_repository.dart` | Unknown |
| `daily_checkins` | `lib/engines/checkin/data/repositories/checkin_repository.dart` | Unknown |

The `cash_on_hand` column referenced in `lib/services/supabase_service.dart` line 640 reads from `profiles.cash_on_hand`, but this column is absent from the profiles table definition in `schema.sql`.

**Action required:** Export actual Supabase schema via `supabase db dump --schema public` to verify RLS coverage on all tables. Until then, unknown RLS on 12+ tables is a security risk.

### 3b. RLS Coverage (on known tables)

All 10 tables in `schema.sql` have RLS enabled with `auth.uid() = user_id` policies. This is correct.

The `schedule_blocks_own` policy on line 43-44 of schema.sql uses both `USING` and `WITH CHECK` in a single `CREATE POLICY` statement — this applies the `user_id` filter for all operations (SELECT + INSERT + UPDATE + DELETE) correctly.

### 3c. N+1 / Query Patterns

| Pattern | Location | Risk |
|---------|----------|------|
| Habit toggle: fetch row → update | `lib/services/supabase_service.dart` lines 406–422 | N+1 per toggle: 2 round-trips instead of 1. At scale, slow. |
| `_ensureProfile()` called on every write | `lib/services/supabase_service.dart` line 23 — called in `upsertDebt`, `upsertInvestment`, `addTransaction`, `upsertHabit`, etc. | Extra Supabase round-trip on every write. Should be called once at app start. |
| `getTransactions()` fetches all records | `lib/services/supabase_service.dart` lines 319–327 — no pagination | Full table scan for every load. A user with 1000 transactions fetches all. |
| `getFocusSessions()` fetches last 100 | `lib/services/supabase_service.dart` line 448 — `.limit(100)` | Reasonable. |

### 3d. Multi-Currency Correctness

- Currency is stored per-account (`currency` field on `BankAccount`, `CreditCard`, `Transaction`).
- FX rates fetched from `https://api.exchangerate-api.com/v4/latest/USD` at session start (`lib/services/fx_rates_service.dart` line 10).
- Fallback rates hardcoded: EGP = 50.0 — as of July 2026 the actual rate is ~50+ EGP/USD but volatile.
- `financeSummaryProvider` sums accounts in their native currencies **without conversion**. A user with USD savings + EGP debt will see the net worth calculated by raw addition (e.g., USD 1,000 + EGP -50,000 = EGP -49,000 displayed as "net worth"), which is nonsensical.
- `convertCurrency()` function exists in `lib/services/fx_rates_service.dart` but is **not used** in `financeSummaryProvider`.

**Rating: 2/5** for data layer — schema gap is serious.

---

## 4. Release Engineering

### 4a. Build Reproducibility

| Factor | Status |
|--------|--------|
| Flutter version pinned | `>=3.19.0` in pubspec.yaml — minimum, not pinned. Builds may differ across machines. |
| Dart version | `>=3.3.0 <4.0.0` — range, not pinned |
| pubspec.lock | Present — dependencies locked ✓ |
| Supabase credentials | Hardcoded in `lib/core/constants/app_constants.dart` — in source control, not env vars |

### 4b. CI/CD Risk

**No CI/CD in place.** Web deploy is manual: `flutter build web --release` → `vercel --prod`. Windows .exe is manual. A forgotten step → stale production. `DEPLOYMENT.md` provides a GitHub Actions example but it is not wired up.

### 4c. Web Bundle

`vercel.json` has correct caching headers:
- `index.html`, `flutter_service_worker.js`: `no-cache` ✓
- Assets: `public, max-age=31536000, immutable` ✓

No analysis of actual bundle size (Flutter web wasm vs canvaskit not confirmed). `health: ^12.2.0` includes mobile-specific code; on web it falls back gracefully (service check in `lib/services/health_sync_service.dart`).

### 4d. Cold-Start Time

No measurement. Flutter web cold start (first load) for a feature-complete app is typically 3–6 seconds on average internet. The app uses Google Fonts (`google_fonts: ^8.1.0`) which makes an HTTP request on first render if fonts aren't cached — adds ~200–500ms.

**Rating: 2/5** for release engineering.

---

## 5. Summary Ratings

| Area | Rating | Key Issue |
|------|--------|-----------|
| Architecture adherence | 3/5 | Religion engine in wrong app; god service; schedule inconsistency |
| State management | 3/5 | Two patterns coexist; habit toggle unguarded |
| Error/loading/empty states | 2/5 | Loading consistent, error minimal, empty state no CTA |
| Offline behavior | 1/5 | None |
| Test coverage | 1/5 | 1 placeholder test |
| i18n | 2/5 | Navigation labels only; all content hardcoded English |
| Accessibility | 1/5 | No semantics |
| Schema / RLS | 2/5 | schema.sql missing 12+ tables; multi-currency not applied to totals |
| Query patterns | 3/5 | N+1 on toggle; no pagination on transactions |
| Release engineering | 2/5 | No CI/CD; hardcoded secrets |

---

## 6. What to Export Before Proceeding

To complete the data-layer audit:
1. Run `supabase db dump --schema public > full_schema.sql` — get the actual production schema.
2. Confirm RLS on all 20+ tables.
3. Confirm `cash_on_hand`, `minimum_payment`, `wallet_provider`, `account_type` columns exist in `bank_accounts`.
4. Check whether `credit_cards`, `installment_plans`, `mood_entries`, etc. have proper `created_at` indexes.
