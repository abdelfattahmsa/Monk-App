# Monk App — Redesign Plan (Phase A)

**Executive summary.** This plan closes the gap between what Monk's four audit reports found and what a founder can actually approve and build next, while holding every non-negotiable guardrail fixed: the stack stays Flutter + Riverpod 3 (`AsyncNotifier`) + GoRouter + Supabase (RLS on every table) + Clerk; the engine-based architecture (`lib/engines/<name>/{data/models, data/repositories, providers}` + `lib/features/<name>/screens` + the 6-layer provider hierarchy) is evolved, never replaced; Religion/Deen/Salah/Quran/Zakat content is removed, not hidden, and never reframed back in even indirectly; every new table ships an explicit `user_id = auth.uid()` RLS policy; every schema change ships a real rollback path; and the evolved dark palette (`#08070C` → `#0D0B13` → `#12101E`, gold `#C8A050`) replaces the old `#0A0A0A`/`#111111`/`#1A1A1A` triad consistently everywhere, in both themes, with AR/EN parity on every new string. Section 1 sequences twelve fixes from schema reconciliation through mobile distribution; Section 2 redesigns first-run onboarding around real data and Finance-first progressive disclosure; Section 3 automates the highest-friction manual entry points (CSV import, recurring transactions, calendar import); Section 4 chooses and designs the Resource Pulse as Monk's daily hero screen and shareable artifact; Section 5 specifies three new engines (Debt Payoff, Assets, Digital Inventory) plus a P2 Household-tier design sketch gated on explicit founder approval; Section 6 redesigns the daily check-in, weekly review, and habit-streak mechanics for retention without new manual logging; Section 7 defines the free/Pro boundary and pricing; Section 8 specifies the visual refresh token-by-token; Section 9 is the cut list (dead code, Ideas de-prioritization, and the full removal of the Religion/Deen engine); and Section 10 is the CI/CD, versioning, and feedback/analytics release plan. Every genuine blocking gap — the Household tier's Clerk-membership model and its non-standard RLS shape, the payment-processor choice, the Android signing keystore, and the Arabic-display-font decision — is flagged explicitly as **BLOCKED — needs founder approval** rather than silently resolved, and collected in the Approval Checklist at the end of this document.

## Table of Contents

1. [Weakness → Intervention Matrix](#1-weakness-intervention-matrix)
2. [First-Run Experience Redesign](#2-first-run-experience-redesign)
3. [Friction Kills (Automation Inventory)](#3-friction-kills-automation-inventory)
4. [The Wedge, Sharpened + Home/Overview Redesign](#4-the-wedge-sharpened-homeoverview-redesign)
5. [New Engines: Debt Payoff, Assets, Digital Inventory, Household Tier](#5-new-engines-debt-payoff-assets-digital-inventory-household-tier)
6. [Retention Loop](#6-retention-loop)
7. [Monetization Surface](#7-monetization-surface)
8. [Visual Refresh Spec](#8-visual-refresh-spec)
9. [Cut List](#9-cut-list)
10. [Release Plan](#10-release-plan)
11. [Approval Checklist](#approval-checklist)

---

## 1. Weakness → Intervention Matrix

*A note on the scoring in this table:* "Effort" (S/M/L) is the plan-writer's scoping judgment except where a report gives an explicit day-estimate (noted inline where that happens); "Impact" (1–5) is likewise the plan-writer's own prioritization call for sequencing purposes — none of the four source reports use a 1–5 impact scale. Treat both columns as working estimates for ordering the roadmap, not measurements extracted from the audit reports.

| # | Weakness (source) | Intervention | Effort | Impact | Depends On |
|---|---|---|:---:|:---:|---|
| 1 | Schema drift: `supabase/schema.sql` defines 10 tables, app queries ~20; RLS status on the missing 12 is "unknown" (reports/01_codebase_audit.md §3a, §3b) | Run `supabase db dump --schema public` to capture the live schema, then land a versioned migration `supabase/migrations/0002_schema_reconciliation.sql` that adds explicit definitions for `credit_cards`, `installment_plans`, `mood_entries`, `body_profiles`, `weight_entries`, `calorie_entries`, `exercise_entries`, `user_categories`, `fasting_records`, `ideas`, `user_tasks`, `daily_checkins` — each shipped with its own `<table>_own` policy (`user_id = auth.uid()`, mirroring the `schedule_blocks_own` pattern at schema.sql line 43). Down-migration: a companion `0002_schema_reconciliation_down.sql` that drops only the newly-added policies/columns, touching zero existing rows. | M | 2 | none |
| 2 | Habit toggle unguarded (silent DB desync); `_ensureProfile()` fired on every write (N+1); dead `health_screen.dart` placeholder still compiled (reports/01_codebase_audit.md §2a, §2b, §3c) | Wrap `HealthRepository.toggleHabitDay()` in `AsyncValue.guard()` with optimistic-state rollback on failure; move `_ensureProfile()` out of `upsertDebt`/`upsertInvestment`/`addTransaction`/`upsertHabit` etc. into a single app-bootstrap call; delete `lib/features/health/screens/health_screen.dart`. Pure app-layer change, no schema or RLS impact. | S | 2 | none |
| 3 | App identity inconsistency — package is `monk_app` but onboarding says "Open PRP 🚀" / "Welcome to PRP" (reports/04_swot_verdict.md W8, Handoff #5; reports/01_codebase_audit.md §2e) | Single find-and-replace pass across `lib/features/onboarding/`, app-bar titles, and footer/URL strings, swapping "PRP" → "Monk" everywhere. AR/EN parity requirement: update `app_en.arb` and `app_ar.arb` welcome/button keys in the same commit, not EN-only. | S | 3 | none |
| 4 | Religion/Deen tab fully routed and shipped inside Monk, contradicting stated strategy (reports/04_swot_verdict.md W3, Handoff #1; reports/01_codebase_audit.md §1) | Delete `lib/features/religion/`, `lib/engines/religion/`, remove routes at `app_router.dart` lines 46–51/355–372, drop the tab from shell nav and `kToggleablePillars`. Religion-related Supabase tables (salah/quran/zakat, if present) are marked deprecated in the reconciled schema doc, not dropped — preserves founder's live data per reversibility guardrail and leaves a path to export it into Mizan later. | S | 3 | 1 |
| 5 | Multi-currency net worth sums raw numbers across currencies with no FX conversion (reports/01_codebase_audit.md §3d; reports/04_swot_verdict.md W5, Handoff #4) | Call the existing (already-written, currently-unused) `convertCurrency()` from `lib/services/fx_rates_service.dart` inside `financeSummaryProvider` before summing balances. No new table. | S | 3 | 1 |
| 6 | Zero test coverage — one placeholder assertion (reports/04_swot_verdict.md W6, Handoff #9; reports/01_codebase_audit.md §2d) | Add `test/engines/money_repository_test.dart` and `test/engines/health_repository_test.dart` against a mocked Supabase client, covering add-account, add-transaction, toggle-habit, compute-summary. Sequenced after the schema is settled (so mocks match reality) and after the habit-toggle fix (so tests assert correct behavior, not the known bug). | M | 1 | 1, 2 |
| 7 | All financial data is 100% manual — no CSV import, no bank SMS parsing, no bank API; this is the #1 drop-off point in the first-run walkthrough (reports/02_product_teardown.md §3, §6; reports/04_swot_verdict.md W1, Handoff #2) | Add an `ImportRepository` under `lib/engines/money/data/repositories/` (existing engine-folder pattern) parsing CIB and NBE CSV export formats into `Transaction` rows, surfaced as an "Import statement" action on Finance → Transactions. New table `import_batches (id, user_id, source_bank, imported_at, row_count)` with RLS policy `import_batches_own: user_id = auth.uid()`, added via the same migration discipline as item 1. See §3.2 for the full, expanded design (additional bank/wallet formats, effort reconciliation, and i18n keys) and §2's introduction for how this item relates to Section 2's separate, zero-dependency onboarding fix for the same kill metric. | L | 5 | 1 |
| 8 | Finance engine's Egyptian-installment differentiation is wasted without a hero payoff feature; high-urgency debt-freedom JTBD unaddressed (reports/04_swot_verdict.md Opportunity #4, Handoff #7) | New engine `lib/engines/debt_payoff/{data/models, data/repositories, providers}` computing freedom date + avalanche/snowball comparison from existing debts/installments/credit-card data, surfaced on Finance → Liabilities. New table `debt_payoff_plans (id, user_id, strategy, target_payment, created_at)` with RLS `debt_payoff_plans_own: user_id = auth.uid()`. Needs the currency fix (5) so freedom-date math is correct across accounts, and CSV import (7) so the calculation runs on real, not hand-typed, debt data — §5a treats dependency 7 as a soft/data-quality dependency rather than a hard blocker; see §5a for that hard-vs-soft framing. | M | 5 | 1, 5, 7 |
| 9 | Ideas engine has no processing path — capture without tag/link/export, "delivers less value than Apple Notes" (reports/04_swot_verdict.md W7; reports/02_product_teardown.md §4) | Add `status` (inbox/processed/archived), `tags text[]`, `linked_goal_id` FK to the existing `ideas` table (additive, nullable columns — reversible via `DROP COLUMN`), plus an export-to-markdown action in `lib/features/ideas/screens/ideas_screen.dart`. Independent of the finance work; can land opportunistically once baseline code quality (2) is in. | M | 2 | 2 |
| 10 | Arabic is navigation-labels-only; all form labels, error messages, onboarding copy remain hardcoded English (reports/04_swot_verdict.md W4, Handoff #3; reports/01_codebase_audit.md §2e — 237 EN vs 90 AR ARB lines) | Move every hardcoded string (onboarding, finance forms, errors, habit suggestions, and the new CSV-import / debt-payoff UI) into `app_en.arb`/`app_ar.arb` with full key parity, plus an RTL layout QA pass. Priority order per report: Finance, Onboarding, Check-in. Sequenced after CSV import (7) and Debt Payoff (8) so their new screens are translated once, not twice. | L | 4 | 7, 8 |
| 11 | No shareable output / social hook — nothing pulls churned users back after the novelty period (reports/04_swot_verdict.md Verdict 2b #5, Opportunity #3, Handoff #6) | Generate a shareable PNG/card of the week's 4 `resourceScoresProvider` values plus top stats (including the new debt-freedom countdown), styled with the evolved dark palette (`#08070C`→`#0D0B13`→`#12101E` background progression, `#C8A050` gold accent, PlayfairDisplay headline — see §8.1 for why these hexes are treated as a fixed, already-approved constraint rather than an open proposal) so shared cards visibly carry Monk's identity. AR and EN card templates required for parity, pulling from the same ARB source as item 10 rather than separate hardcoded copy. | M | 4 | 8, 10 |
| 12 | No mobile app — the highest-frequency use cases (logging a transaction, checking habits before bed) require a phone; web-only is a hard ceiling (reports/04_swot_verdict.md W2, Handoff #10; reports/03_market_analysis.md Threat #3) | Build and sign an Android APK for direct distribution to the first 100 users — no new library, uses Flutter's existing Android target per the stack guardrail. Sequenced last: users shouldn't be asked to install a native binary before the core differentiators (CSV import, Debt Payoff), a real Arabic experience, and a regression-tested codebase are in place.*Rated M rather than S — unlike the comparable 1-day report estimates behind rows 3–5 — because this plan's scope includes keystore generation/signing setup and first-distribution logistics to 100 users, not just the `flutter build apk` step that reports/04_swot_verdict.md Handoff #10's "1–2 days" figure appears to cover; see §10.2's signing-keystore BLOCKED flag for the piece this estimate accounts for beyond the build itself.* | M | 5 | 6, 7, 8, 10 |

**Critical path:** the schema/RLS reconciliation (1) and code-quality fixes (2) are the load-bearing first step — every later item either adds a table that must follow the same RLS discipline (7, 8) or needs the toggle bug fixed before it can be safely tested (6). From there the sequence is Finance-correctness (5) → tests (6) → the two real differentiators, CSV import and Debt Payoff (7, 8) → Arabic (10, done once against the finished UI rather than twice) → distribution hook (11) → mobile ship (12), which is deliberately last because shipping a native binary before the product's actual value (real Arabic, populated Finance, a debt-freedom date) is in place would just accelerate churn on a bigger install base. Religion removal (4) and rebranding (3) are cheap, independent cleanups that can be pulled forward opportunistically without disturbing this chain.

**Relationship to Section 2:** item 7 (CSV import) and Section 2's Guided Setup/Progressive Disclosure redesign both target the same Finance-activation kill metric (reports/03_market_analysis.md §5) from two different angles and time horizons. Section 2 is the zero-dependency, ship-immediately fix for a brand-new user's first five minutes — no schema change, no CSV parser required — while item 7 is the deeper, longer-lead fix that lets an already-onboarded user bulk-load months of real history. They are complementary, not sequential: Section 2 does not need to wait for item 7, and item 7 does not supersede Section 2. See Section 2's introduction for the same reconciliation stated from that section's side.

---

## 2. First-Run Experience Redesign

**Problem statement (evidence):** per reports/02_product_teardown.md §1, time-to-first-aha today is 15+ minutes to "log first real transaction" and days to "derive first insight," and the Finance screen ("no CSV import, no bank API, just Add account") is the primary abandon point. Per reports/04_swot_verdict.md §2b weakness #1, this is the single highest-impact weakness. Per reports/03_market_analysis.md §5 Kill Criteria, Finance activation under 30% of signups is an explicit pivot/kill signal — first-run design is not cosmetic here, it is the metric the whole bet rides on. The redesign below keeps `lib/features/onboarding/screens/onboarding_screen.dart` as the entry surface, keeps `pillarProvider` (`lib/core/providers/pillar_provider.dart`) as the mechanism for engine visibility, and writes only into existing repositories/tables — no new engine, no new backend. **Relationship to Section 1, item 7:** this section and Section 1's CSV-import item both address the same Finance-activation kill metric from different angles — this section is the zero-dependency, ship-immediately fix for a brand-new user's first five minutes (no schema change, no CSV parser needed), while item 7 is the deeper, longer-lead fix that lets an already-onboarded user bulk-load months of real history. They are complementary and can ship in either order or in parallel; neither supersedes the other.

---

### 2a. Guided Setup Flow — seeds only the user's real data

The current flow (5 pages: Welcome → Tour → Currency → First Habit → All Set) is replaced by a **Finance-first, real-data-only** flow. The one habit-capture step in the current flow already writes real data correctly (`habitsProvider.notifier.add()`) — that pattern (type your own, no lorem) is extended to every step below. The generic pre-seeded schedule (14 blocks) and 4 generic goals flagged in reports/02_product_teardown.md §1 and §2 ("Seed data verdict") are **removed entirely**: nothing is seeded until the user supplies it, or an unlock moment (§2b) walks them through a 3-question real-data mini-setup.

| Step | Screen shown | Real data captured | Writes to (existing provider/table) | Time budget |
|---|---|---|---|---|
| 0. Welcome | Resource framing (kept, copy trimmed) | none | — | 15s |
| 1. The one question | "Do you have any debt, loans, or installment plans right now (Valu, Sympl, credit card, bank loan)?" Yes/No | none yet — branches step 4 | — | 10s |
| 2. Base currency | Currency picker (kept as-is: EGP default, 6 options) | `base_currency` on profile | `currencyNotifierProvider` → `profiles` table | 10s |
| 3. First real account | "Add your first account" — name, type (savings/current/digital wallet, autocomplete from `kDigitalWallets`), current balance | One real `BankAccount` | `bankAccountsProvider.upsert()` → `bank_accounts` table | 60s |
| 4. First real debt (only if Step 1 = Yes) | Dropdown of `kInstallmentProviders` (Valu, Tru, Contact Finance, Sympl, Aman, Bank Takseet) or "Credit card" or "Other loan" + amount owed + minimum payment | One real `ExternalDebt`/`CreditCard`/`InstallmentPlan` | `debtsProvider` / `creditCardsProvider` / `installmentPlansProvider` → Finance → Liabilities/Cards screens | 60s |
| 5. Debt-freedom bridge (only if Step 4 ran) | "You're tracking EGP {amount} in debt. Want a Debt Freedom goal?" | If yes: one real `Goal` — title, target date, target amount pre-filled from the debt just entered | `goalsProvider` → Energy → Goals screen. **This single tap is also Unlock Trigger #1 in §2b** — it is the only step in setup that touches a second engine, and only because the user's own data justified it. | 20s |
| 6. First real transaction | "Log one thing you actually spent money on today" — real category (from `AppConstants` category map), real amount, real merchant/note | One real `Transaction` | `transactionsProvider` → Finance → Transactions screen. Directly targets the "log first real transaction: 15+ min" metric in reports/02_product_teardown.md §1 — folded into setup, guaranteed inside the 5-minute budget. | 45s |
| 7. Payoff screen | Shows the user's own computed Net Worth and Money score, sourced live from `financeSummaryProvider` / `resourceScoresProvider` on the real data just entered — not a static "You're all set" graphic | none (read-only) | reads `financeSummaryProvider`, `resourceScoresProvider` | 15s |
| 8. Getting Started | Rescoped checklist (Finance-only items; other engines shown as locked/greyed with "Unlocks when…" subtext, not as checklist items to complete now) | `onboardedProvider.markOnboarded()` | `checklistProvider` (rescoped, see §2b) | 10s |

*Per-step time budgets in this table are the plan-writer's scoping estimates for design purposes, not measured or report-sourced figures.*

Total: the no-debt branch (Steps 0, 1, 2, 3, 6, 7, 8) sums to 15+10+10+60+45+15+10 = 165 seconds, ≈2 minutes 45 seconds; the debt-carrying branch (all steps, including 4 and 5) sums to 245 seconds, ≈4 minutes 5 seconds. Both paths are entirely real data, zero lorem/demo content, and both land comfortably inside the 5-minute time-to-first-transaction target this redesign is built against — closing the gap identified in reports/02_product_teardown.md §1 ("the seeded data is generic and creates false engagement").

**No schema change required.** Every write above targets a table that already exists and already has an `auth.uid() = user_id` RLS policy per `supabase/schema.sql` (`bank_accounts_own`, `debts_own`, `goals_own`, `transactions_own`). This section proposes zero new tables.

**AR/EN parity for onboarding-flow copy (Steps 0–8).** Every string above — including the Step 1 debt question, Step 4/5 debt-entry and debt-freedom-bridge copy, and Step 8's checklist copy — must ship as a matched key pair in `lib/l10n/app_en.arb`/`app_ar.arb`, not as the English literals shown in this table for readability. Representative keys: `onboarding.step1.debtQuestion` ("Do you have any debt, loans, or installment plans right now (Valu, Sympl, credit card, bank loan)?" / "هل عليك أي ديون أو قروض أو خطط تقسيط حاليًا (Valu، Sympl، بطاقة ائتمان، قرض بنكي)؟"), `onboarding.step4.debtPrompt`, `onboarding.step5.freedomBridge` ("You're tracking EGP {amount} in debt. Want a Debt Freedom goal?" / "أنت تتابع {amount} جنيه من الديون. هل تريد هدف تحرر من الديون؟"), `onboarding.step6.logPrompt`. This extends §2c's cross-cutting ARB rule (below) to flow copy, not just empty states.

---

### 2b. Progressive Disclosure — start with Finance only

**Decision: on first run, only the Finance pillar is active.** Time, Energy, and Health are hidden from the shell nav (via `pillarProvider`/`visibleTabsProvider` in `lib/core/providers/pillar_provider.dart`, which already supports a subset of `kToggleablePillars` — this requires changing the **new-user default only**, not the provider's mechanism). This directly answers the brief's requirement to justify from the market report:

- reports/03_market_analysis.md §2a Segment 2 (debt-payoff seekers) is named "the highest-urgency JTBD — people pay for debt relief tools," and §2b confirms "Arabic-first personal finance + EGP [is] the actual wedge... but incompletely executed."
- reports/04_swot_verdict.md §2c Strength #1 states plainly: "Make Finance the product that gets people to Monk."
- reports/03_market_analysis.md §5 Kill Criteria makes Finance activation the single explicit pivot signal — the redesign must optimize for this number over any other engine's engagement.
- reports/02_product_teardown.md §5 flags 7 top-level tabs / 30+ routes as overwhelming for a first-time user. Hiding three pillars until earned removes that overwhelm without removing the features.

This is a client-side change only: `kDefaultActivePillars` becomes `{'finance'}` for accounts with no prior stored preference (existing users' already-active pillar sets in `SharedPreferences` are untouched — fully backward compatible, no migration). One optional, reversible schema addition to make unlock state durable across devices/reinstall (currently `SharedPreferences`-only, which is a real gap once mobile ships per reports/04_swot_verdict.md weakness #2): add `unlocked_pillars text[] not null default '{}'` to `public.profiles`. Down-migration: `alter table public.profiles drop column unlocked_pillars;` — no data loss, since the client falls back to the existing local-prefs mechanism it already has. No new RLS policy is needed: `profiles` already has row-level `auth.uid() = id` policies for select/update (`supabase/schema.sql` lines 19–24) which cover the new column automatically.

| Engine | Starts | Unlock trigger | What gets seeded (real, not generic) | Evidence |
|---|---|---|---|---|
| Finance | **Active by default** | n/a — the wedge engine | Real account + optional debt + optional transaction from §2a | reports/03_market_analysis.md §2b wedge; reports/04_swot_verdict.md Strength #1 |
| Energy (Goals only, not yet Focus/Ideas) | Locked | User accepts the "Debt Freedom goal" bridge in setup Step 5, OR later taps "Turn this debt into a goal" from Finance → Liabilities | One real Goal, pre-filled title/target/date from the user's own debt data — not a generic "Build emergency fund" (the exact complaint in reports/02_product_teardown.md §2 "Seed data verdict") | reports/04_swot_verdict.md Opportunity #4 "Debt payoff as the hero feature" |
| Energy (Focus) | Locked until Energy unlocked above, then shown immediately with zero further setup | Automatic once Energy is unlocked — Focus Timer needs no data to deliver value | none required — user starts a session on first visit | reports/02_product_teardown.md §6 verdict: "The one exception is the Focus Timer — it delivers value immediately with zero setup cost." |
| Time | Locked | Day-2 return, OR after 3rd transaction logged: Overview banner "See how your day maps to your money — unlock Time" | 3-question mini-setup ("When do you wake / start work / sleep?") seeds 3 real schedule blocks in the user's chosen `schedule_mode` — never the current 14 generic blocks | reports/02_product_teardown.md §1 "Seed data verdict" (generic 14-block schedule flagged as impersonal); reports/04_swot_verdict.md Strength #2 (schedule modes) |
| Health | Locked | First completion of the existing Daily Check-in flow (`lib/features/checkin/screens/daily_checkin_screen.dart`, already asks about all 4 resources) triggers: "Your check-in mentioned energy/sleep — want to track a habit for that?" | One real habit, typed by the user (reuse the existing suggestion-chip mechanic from onboarding Step 3 of the *old* flow, capped at 2 chips to avoid re-introducing generic-habit sprawl) | reports/04_swot_verdict.md Strength #6 (daily check-in is Monk's "only data asset that compounds"); reports/02_product_teardown.md §2 (Health habit seeding flagged generic) |

Each unlock calls `ref.read(pillarProvider.notifier).toggle(pillarId)` — the existing method in `lib/core/providers/pillar_provider.dart` — no new provider or architecture layer is introduced.

**AR/EN parity for unlock-trigger copy.** The Time-unlock banner ("See how your day maps to your money — unlock Time") and the Health-unlock prompt ("Your check-in mentioned energy/sleep — want to track a habit for that?") are new user-facing strings and must be ARB-keyed like everything else in this plan: `pillar.unlock.timeBanner` ("See how your day maps to your money — unlock Time" / "شاهد كيف يرتبط يومك بمالك — افتح الوقت"), `pillar.unlock.healthPrompt` ("Your check-in mentioned energy/sleep — want to track a habit for that?" / "ذكرت تسجيلك اليومي الطاقة/النوم — هل تريد تتبع عادة لذلك؟"). This is the same rule §2c states explicitly for empty states, extended here to cover unlock-flow and banner copy.

---

### 2c. Empty-State Spec Table

Every row below replaces "text message, no CTA" empty states flagged in reports/01_codebase_audit.md §2b and reports/02_product_teardown.md §2. Rows for locked-engine screens (Time Schedule, Energy Focus/Goals/Ideas, Health Habits/Daily Progress) describe the state the user sees on their **first visit immediately after that engine is unlocked** (§2b) — before they've added their first item in that screen — since visiting them pre-unlock is not possible in the redesigned nav.

| Screen | What It Teaches | Action It Offers | Copy (EN) | Copy (AR) |
|---|---|---|---|---|
| Overview (zero-data edge case: onboarding abandoned before Step 3) | This is the daily command center; it stays empty until you finish the one setup step you skipped | "Resume setup" button, re-opens Step 3 of §2a directly (not the whole flow) | "Your Overview is waiting on one thing: your first account. Add it and this fills in." | "نظرتك العامة تنتظر شيئًا واحدًا: أول حساب لك. أضِفه وستمتلئ الصفحة." |
| Finance → Accounts | Every account (bank, wallet, or cash) becomes part of your net worth calculation | "Add account" — opens the same real-entry sheet used in onboarding Step 3 | "No accounts yet. Add a bank, wallet, or cash balance to see your real net worth." | "لا توجد حسابات بعد. أضف حسابًا بنكيًا أو محفظة أو رصيدًا نقديًا لترى صافي ثروتك الحقيقي." |
| Finance → Transactions | Transactions build the spending-by-category picture behind your Money score | "Log a transaction" inline, plus extend the existing quick-capture FAB (`lib/shared/widgets/quick_capture_fab.dart`) to log a transaction directly — the FAB's default target moves to Finance per Section 9's decision to hide Ideas by default (see the note below this table); today it defaults to ideas capture only, flagged as a gap in reports/02_product_teardown.md §5 | "No transactions yet. Log what you spent today — it takes 20 seconds." | "لا توجد معاملات بعد. سجّل ما أنفقته اليوم — يستغرق ٢٠ ثانية فقط." |
| Time → Schedule (post-unlock, pre-first-block) | Schedule modes (normal/fasting/friday/cairo — secular Egyptian work-week and intermittent-fasting eating-window scheduling, see §4.1's note on framing) rebuild your day around how Egyptian work-weeks actually run | 3-question mini-setup (wake / work start / sleep) that seeds 3 real blocks — not the generic 14-block template flagged in reports/02_product_teardown.md §1 | "Let's build today from scratch — three quick questions, three real time blocks." | "لنبنِ يومك من الصفر — ثلاثة أسئلة سريعة، وثلاث فترات زمنية حقيقية." |
| Energy → Focus | This is the one feature that pays off with zero setup — reports/02_product_teardown.md §6 names it the sole exception to Monk's setup-cost problem | "Start a 25-min focus session" — one tap, no form | "Nothing logged yet. Start your first focus session now — no setup needed." | "لم يُسجَّل شيء بعد. ابدأ أول جلسة تركيز الآن — بدون أي إعداد." |
| Energy → Goals | Goals are strongest when tied to a real number you already track (like the debt you entered in Finance) | "Create a goal" — if a real debt exists, the button is pre-filled ("Pay off EGP {amount} by…") pulled live from `financeSummaryProvider`, not a static suggestion like the old "Build emergency fund" text flagged in reports/02_product_teardown.md §2 | "No goals yet. Turn a number you're already tracking — like your debt — into a target date." | "لا توجد أهداف بعد. حوّل رقمًا تتابعه بالفعل — مثل دينك — إلى تاريخ مستهدف." |
| Energy → Ideas (only reachable when `kIdeasEngineEnabled` is on — see the note below this table and Section 9.2 item #2) | Sets honest expectations given reports/02_product_teardown.md §4 finding that Ideas scores 1/5 depth and has "no clear answer" for why to use it over Apple Notes — the empty state should nudge toward the one differentiated use (linking an idea to a Goal or Habit) rather than pure capture | "Capture your first idea" + an inline "link to a goal" toggle if goals exist (cross-engine link is the redesign hook, not a full processing pipeline) | "Ideas alone won't beat your Notes app. Link one to a goal and it becomes a plan." | "الأفكار وحدها لن تتفوق على تطبيق الملاحظات لديك. اربط فكرة بهدف لتتحول إلى خطة." |
| Health → Habits (post-unlock, pre-first-habit) | Streaks are only meaningful for habits you chose yourself — reports/02_product_teardown.md §2 flags generic pre-seeded habits as impersonal | "Add your first habit" — max 2 suggestion chips (reused from old onboarding Step 3 pattern), free-text always primary | "No habits tracked yet. Add the one thing that actually matters to you — not a generic list." | "لا توجد عادات متتبعة بعد. أضف الشيء الوحيد المهم لك فعلًا — لا قائمة عامة." |
| Health → Daily Progress | Body metrics (weight, nutrition, exercise) feed the Health score; on web, automatic sync isn't available | "Log an entry manually" — on iOS/Android only, also offer "Connect Apple Health / Google Health Connect"; on web, the sync CTA must not appear, per the platform limitation confirmed in reports/01_codebase_audit.md §4c and reports/02_product_teardown.md §3 (`health` package has no function on web) | "No entries yet. Log your weight, a meal, or a workout — whichever you'll actually keep doing." | "لا توجد تسجيلات بعد. سجّل وزنك أو وجبة أو تمرينًا — أيًّا كان ما ستستمر عليه فعليًا." |

**Interaction with Section 9's Ideas decision.** Section 9 hides the Ideas engine behind `kIdeasEngineEnabled` (default `false`) pending a tag/link/export uplift, and moves the quick-capture FAB's default target away from Ideas. The "Energy → Ideas" empty-state row above therefore renders only for users who have the flag enabled (early testers, or users after Section 9's re-promotion bar is met) — for the default cohort, Ideas is not reachable from primary nav at all, and the Finance → Transactions row's FAB extension above is written against the FAB's new default target (transaction logging), not against Ideas capture as today's shipped behavior has it. Both rows remain in this table because each describes the correct state for whichever cohort can actually reach that screen; they do not describe the same rollout moment.

**Cross-cutting rule for implementation:** every empty-state CTA above must route to a real-data-entry form already present in the codebase (no new form components), and every copy string must be added to `lib/l10n/app_en.arb` / `lib/l10n/app_ar.arb` as a proper key pair — not hardcoded in the widget — closing the exact gap reports/01_codebase_audit.md §2e documents ("the vast majority of UI strings... are hardcoded English strings") and reports/04_swot_verdict.md weakness #4 ("Arabic is fake").

---

## 3. Friction Kills (Automation Inventory)

Every row below traces to a line in reports/02_product_teardown.md §3 "Friction Inventory" or §4 feature-depth findings. Design stays inside the existing engine folders (`lib/engines/<name>/data/{models,repositories}`, `providers/`) per the architecture guardrail — no new engines, no new backend service. Two small utility packages are needed (`csv`, `file_picker` — not currently in `pubspec.yaml`; verified via grep); these are parsing/file-picker utilities, not new backend/auth/state libraries, so they don't trip the stack guardrail.

### 3.1 Automation Inventory

| Manual Entry Point | Current Screen | Automation Design | Engine/File Touched | Effort |
|---|---|---|---|---|
| Bank balances, per account per update | `lib/features/finance/screens/*` (accounts) | Bank/wallet CSV import — see §3.2. Statement upload replaces manual balance typing; running balance taken from the last row of the statement. | `lib/engines/money/*` | L |
| Credit card balance | Finance → Cards screen | Same CSV pipeline (§3.2); CC statement export includes a closing-balance line, auto-applied to `CreditCard.balance` on import; user only confirms. | `lib/engines/money/*` | M (incremental after §3.2 ships) |
| Transactions, one-by-one | Finance → Transactions screen | CSV import (§3.2) for historical bulk load + Recurring Transaction Engine (§3.3) for predictable ones (salary, rent, subscriptions, installments) | `lib/engines/money/*` | L |
| Habit toggle | Habits screen | **No automation — already minimal friction** ("it's a toggle," per report 02 §3). Left as-is. | — | N/A |
| Weight / body metrics | Health → Body screen | Health sync (`health: ^12.2.0`) already implemented but opt-in and silent (`HealthSyncNotifier.build()` returns `null`, no auto-sync per code comment). Flip to **default-on** with an opt-out toggle — see §3.5. | `lib/engines/health/providers/health_providers.dart` | S |
| Steps / heart rate on web/Windows | N/A everywhere except iOS/Android | **BLOCKED — platform limitation, not a design gap.** No browser or Windows API for step/heart-rate data exists; `health` package has zero web/Windows implementation (per report 02 §3, report 01 §4c). No client-side fix is possible without a native mobile build; flag as founder-known constraint, not an engineering task. | — | N/A |
| Fasting timer start/stop | Fasting screen | **No automation needed** — already 1-tap (per report 02 §3, "Good — minimal friction"). | — | N/A |
| Schedule block creation | Time → Schedule screen | ICS calendar import — see §3.6 | `lib/engines/time/*` | M |
| Goal progress (manual % slider) | Goals screen | Auto-compute a **suggested** progress value from `goals.linked_event_ids` against `calendar_events.is_done` (field already exists in schema per report 02 §3 — "feature exists... unimplemented"). Shown as a "Sync from calendar" affordance next to the slider; user still confirms rather than the app silently overwriting a milestone-based goal. | `lib/engines/goals/providers/goal_providers.dart` (new computed provider) | S |
| Daily check-in (5-score + text) | Check-in screen | **No automation — intentional friction** (per report 02 §3: "No automation possible... intentional"). Left as-is; self-report is the product. | — | N/A |
| FX rates | Background | Already automated via `fxRatesProvider` / exchangerate-api.com (per report 02 §3, "Working — no friction"). No change. | — | N/A |
| Stock prices (Alpha Vantage) | Investments screen | Manual API-key entry is real friction (per report 02 §4 Finance section) but replacing the data provider is a vendor decision outside this section's scope. Minimum fix: cache last successful price locally (SharedPreferences) so a slow/rate-limited free-tier call doesn't block the screen every load. Swapping to a keyless provider is **BLOCKED — needs founder approval** (new external data dependency). | `lib/engines/money/providers/money_providers.dart` (`stockPriceProvider`) | S |
| Recurring cash flows (salary, rent, subscriptions) — currently don't exist at all | N/A (missing feature, called out in report 02 §4 Finance "What is missing") | Recurring Transaction Engine — see §3.3 | `lib/engines/money/*` | M |
| Generic seeded onboarding goals/habits | Onboarding screen | Egypt-specific templates — see §3.4 | `lib/features/onboarding/*`, `lib/engines/goals/*`, `lib/engines/health/*` | S |

---

### 3.2 Egyptian Bank & Wallet CSV Import (MENA wedge — reports/03_market_analysis.md §2b)

Per report 03: "No major personal finance app has EGP as a first-class currency with Egyptian installment providers modeled correctly... CSV import from CIB, Banque Misr, and ADCB would cover the major banks" (report 02 §3), and the digital-wallet list (Vodafone Cash, FawryPay, InstaPay, OPay) is already correct for Egypt in `kDigitalWallets` (`lib/engines/money/data/models/money_models.dart` lines 6–9). This import feature is the single highest-leverage fix against the #1 abandon point named in report 02 §1 ("Finance screen — first time a user sees no CSV import... primary abandon point").

**Formats to support at launch:** CIB and NBE are the two formats explicitly requested by the brief. Banque Misr and ADCB are added on direct citation grounds — report 02_product_teardown.md §3 names both in the same sentence ("CSV import from CIB, Banque Misr, and ADCB would cover the major banks"). InstaPay and Vodafone Cash are **not** directly recommended as CSV/statement-import targets by any of the four reports — the reports' support for these two names is limited to `kDigitalWallets` being correctly modeled with accurate Egyptian wallet names (a naming-accuracy finding, not an import-feature recommendation). Including wallet-statement import here is therefore flagged explicitly as **the plan-writer's own design judgment call**, not a report-grounded requirement: Egyptian wallets are a large share of daily transaction volume for the target segment, and omitting them would leave a bank-only import feature that misses how many users actually transact day-to-day. If the founder wants to scope the first release to only the report-cited bank formats, InstaPay and Vodafone Cash can be deferred to a fast-follow without changing the adapter architecture below (the `BankCsvAdapter` interface accepts new adapters with no structural change).

| Source | Format notes (to validate against real sample exports before ship — flagged explicitly, not blocking) |
|---|---|
| **CIB** | Typical export: `Transaction Date, Value Date, Description, Debit, Credit, Balance`, comma or semicolon-delimited, often Windows-1256 (Arabic) or UTF-8-BOM encoded. |
| **NBE** | Typical export: `Date, Narration, Withdrawal, Deposit, Running Balance`. Same debit/credit-column split pattern as CIB. |
| **InstaPay** *(plan-writer design judgment — see disclaimer above, not directly report-cited for import)* | Transaction-history export: `Date & Time, Reference No, Beneficiary/Sender, Amount, Status, Type (Send/Receive)`. `Type=Receive` → income. |
| **Vodafone Cash** *(plan-writer design judgment — see disclaimer above, not directly report-cited for import)* | Wallet statement export: `Date, Transaction Type, Amount, Balance After, Recipient/Sender`. `Transaction Type` (Cash In / Cash Out / Bill Payment / Transfer) maps to `isIncome` + category. |
| **Banque Misr** (explicitly named alongside ADCB in report 02 §3's exact sentence) | Same debit/credit pattern as CIB/NBE; handled by the generic adapter fallback below unless a dedicated adapter is warranted after real samples are reviewed. |
| **ADCB** (explicitly named alongside Banque Misr in the same report 02 §3 sentence — previously omitted from this table; restored here for citation completeness) | Same debit/credit pattern as CIB/NBE; handled by the generic adapter fallback below unless a dedicated adapter is warranted after real samples are reviewed. |

**Parser architecture** (new folder `lib/engines/money/data/import/`, following the existing repository-delegation pattern in `lib/engines/money/data/repositories/money_repository.dart`):

```
abstract class BankCsvAdapter {
  String get sourceName;
  bool sniff(List<String> headerRow);           // header-based format detection
  List<Transaction> parse(List<List<dynamic>> rows, {required String accountName});
}
```
- Concrete adapters: `adapters/cib_adapter.dart`, `nbe_adapter.dart`, `instapay_adapter.dart`, `vodafone_cash_adapter.dart`, and a `generic_adapter.dart` fallback that shows a one-time column-mapping UI (map CSV columns → date/description/amount/direction) when no adapter's `sniff()` matches — this same fallback is what covers Banque Misr and ADCB unless real-sample review justifies a dedicated adapter. The mapping the user builds is saved and reused next time (see `csv_import_mappings` table below) — Egyptian export formats vary by branch/app-version, so the fallback path is not optional, it's the safety net for the whole feature.
- `BankCsvImportService` (`lib/engines/money/data/import/bank_csv_import_service.dart`): reads the picked file (`file_picker` for cross-platform selection — Web/Windows/mobile), decodes with the `csv` package, detects non-UTF-8 encoding (Windows-1256 is common in Egyptian bank exports with Arabic merchant names) and falls back to UTF-8 if decode fails, runs adapter `sniff()` in priority order, parses to `Transaction` objects tagged `source: 'csv_import'`, **dedupes** against existing transactions (same date + amount + normalized description) so re-uploading a statement doesn't double-count, writes an `import_batches` row, and returns an `ImportSummary(imported, skippedDuplicates, failed, errors)` for the UI plus an **"Undo import"** action that deletes every transaction carrying that batch's `import_batch_id`.
- Category auto-mapping: keyword rules (e.g. "fawry" → Bills, "uber"/"careem" → Transport, "carrefour"/"spinneys" → Shopping) map free-text descriptions onto `AppConstants.txCategories`, extendable through the existing `user_categories` table (report 01 §3a).

**Schema changes** (each with the required RLS policy and an explicit down-migration, per the reversibility guardrail):

| Table/column | Purpose | RLS policy | Down-migration |
|---|---|---|---|
| New table `public.import_batches (id uuid pk, user_id uuid, source_name text, source_type text check in ('bank_csv','wallet_csv'), row_count int, imported_at timestamptz default now())` | Groups an import for the "Undo import" action | `create policy "import_batches_own" on public.import_batches using (auth.uid() = user_id) with check (auth.uid() = user_id);` | `drop table if exists public.import_batches;` — no other table depends on it once FKs below are dropped first |
| New table `public.csv_import_mappings (id uuid pk, user_id uuid, bank_name text, column_mapping jsonb, created_at timestamptz default now())` | Saves the user's manual column mapping for unrecognized formats, reused on next upload | `create policy "csv_import_mappings_own" on public.csv_import_mappings using (auth.uid() = user_id) with check (auth.uid() = user_id);` | `drop table if exists public.csv_import_mappings;` |
| `alter table public.transactions add column import_batch_id uuid references public.import_batches(id) on delete set null, add column source text not null default 'manual';` | Tags import provenance, enables undo | Covered by existing `transactions_own` policy — column-level, no new policy needed | `alter table public.transactions drop column import_batch_id, drop column source;` |

Engine/file touched: `lib/engines/money/data/import/*` (new), `lib/engines/money/data/models/money_models.dart` (add `source`, `importBatchId` to `Transaction`), `lib/engines/money/data/repositories/money_repository.dart`, `lib/engines/money/providers/money_providers.dart` (new `importBatchesProvider`, `csvImportServiceProvider`), `lib/features/finance/screens/transactions_screen.dart` (add "Import statement" entry point), `supabase/schema.sql`.

**AR/EN parity for the import UI.** New ARB keys required in both `app_en.arb`/`app_ar.arb`: `import.cta` ("Import statement" / "استيراد كشف حساب"), `import.mapping.title` ("Match your columns" / "طابق أعمدتك"), `import.mapping.confirm` ("Save and import" / "حفظ واستيراد"), `import.summary.imported` (ICU-plural: "{n} transactions imported" / "{n} معاملة تم استيرادها"), `import.summary.skippedDuplicates`, `import.summary.failed`, `import.undo` ("Undo import" / "تراجع عن الاستيراد"), `import.encodingFallbackNotice` (shown if Windows-1256 decode is attempted). No hardcoded strings in `BankCsvImportService`'s UI-facing summary or in the mapping sheet.

**Effort: L.** Multi-adapter parser + encoding handling + dedupe + undo + two new tables + mapping UI is realistically 2–3 weeks for one engineer — largest single item in this section, matching its status as the report's #1 abandon point. *Reconciliation note: reports/04_swot_verdict.md Handoff #2 estimates this feature at 5–7 days. This plan revises that estimate upward to 2–3 weeks because the scope specified here is broader than a single-format parser — five bank/wallet adapters plus encoding detection, a generic fallback with a persisted column-mapping UI, dedupe-on-reimport, an "Undo import" action, and two new tables with RLS — which reads as materially more work than the handoff's original estimate likely assumed. Flagged explicitly as a plan-writer scope/estimate revision, not a report citation, per the evidence-traceability standard applied throughout this document. If the founder wants to hold the line at 5–7 days, the fastest path is to scope the first release to CIB + NBE only (dropping InstaPay/Vodafone Cash per the disclaimer above) and ship the generic-adapter fallback instead of dedicated Banque Misr/ADCB adapters.*

---

### 3.3 Recurring Transaction Engine

Directly answers report 02 §4 Finance "What is missing: No recurring transactions (salary, rent, subscriptions)."

- New model `RecurringRule` in `lib/engines/money/data/models/money_models.dart` (`description, amount, category, accountName, currency, isIncome, frequency: monthly|weekly|custom_days, intervalDays, nextRunDate, lastGeneratedDate, isPaused`).
- **Materialization stays client-side** — no new Postgres cron job, keeping within the "no new backend" guardrail. A `RecurringMaterializerNotifier` (Layer-4 computed provider, `lib/engines/money/providers/money_providers.dart`) runs once at app bootstrap (invoked from the shell, alongside existing profile-ensure logic): queries `recurring_transactions` where `next_run_date <= today and not is_paused`, generates one `Transaction` per due rule tagged `source: 'recurring'`, advances `next_run_date`, and stamps `last_generated_date` to make the run idempotent against being opened twice in one day.
- Templates offered when creating a rule: Salary (monthly, income), Rent (monthly, expense), Subscription (monthly, expense), and an Installment-linked rule that can attach to an existing `installment_plans` row so a Valu/Sympl monthly payment auto-posts as a transaction without duplicating data entry.
- New screen `lib/features/finance/screens/recurring_screen.dart`, reachable from the Finance sub-tabs.

**Schema:**

| Table/column | RLS policy | Down-migration |
|---|---|---|
| New table `public.recurring_transactions (id uuid pk, user_id uuid, description text, amount numeric, category text, account_name text, currency text default 'EGP', is_income boolean default false, frequency text check in ('weekly','monthly','custom_days'), interval_days int, next_run_date date, last_generated_date date, is_paused boolean default false, created_at timestamptz default now())` | `create policy "recurring_transactions_own" on public.recurring_transactions using (auth.uid() = user_id) with check (auth.uid() = user_id);` | `drop table if exists public.recurring_transactions;` |
| `alter table public.transactions add column recurring_rule_id uuid references public.recurring_transactions(id) on delete set null;` | Covered by existing `transactions_own` policy | `alter table public.transactions drop column recurring_rule_id;` |

**AR/EN parity.** New ARB keys: `recurring.title` (screen title), `recurring.template.salary` / `.rent` / `.subscription` / `.installmentLinked`, `recurring.frequency.weekly` / `.monthly` / `.customDays`, `recurring.nextRunLabel`, `recurring.pauseToggle`. Both `app_en.arb`/`app_ar.arb`, matched keys — no exception for template names, per the i18n guardrail.

Effort: **M** (one new model/table/provider/screen, no parser complexity).

---

### 3.4 Egypt-Specific Goal/Habit Templates

Per report 02 §1/§2: "Seed data verdict: Default habits and goals are plausible but impersonal... Better: seed one Egyptian-specific habit... and one finance goal specific to EGP debt ('Pay Valu installment')."

**Note on the report's own suggested example:** report 02 proposes "Read 30 min after Fajr" as the Egyptian-specific habit example. Per the guardrail against reintroducing any Salah/prayer-time content, this is adapted to a secular equivalent — **"Morning reading habit (30 min)"** with no prayer-time framing — while keeping the finance example ("Pay off [Valu/Sympl] installment") as-is since it is purely financial.

- Static localized template libraries: `lib/core/constants/goal_templates.dart`, `lib/core/constants/habit_templates.dart` — each entry ships an EN/AR ARB key pair (`app_en.arb`/`app_ar.arb`), category, and suggested target/frequency, per the AR/EN parity guardrail. This directly narrows the i18n gap flagged in report 01 §2e ("habit suggestions... hardcoded English").
- Egypt-specific finance goal template pre-fills from the user's own `installment_plans` (e.g., "Pay off Valu — iPhone 16 Pro" if such a plan exists) rather than a generic string.
- Surfaced as a template picker bottom sheet in the existing "Add goal" (`lib/engines/goals/*`) and "Add habit" (`lib/engines/health/providers/health_providers.dart` → `lib/features/habits/screens/habits_screen.dart`) flows, and reused in onboarding step "Add first habit" (`lib/features/onboarding/screens/onboarding_screen.dart`) in place of today's generic hardcoded suggestions.

Effort: **S** (content + a picker widget, no schema change).

---

### 3.5 Health Auto-Sync Default-On

Per report 02 §3: "Weight/body metrics — Health sync... implemented — only on iOS/Android," and report 01 §2a flags the habit-toggle write path as already unguarded, so any change here must keep the existing `AsyncValue.guard()` discipline.

- `HealthSyncNotifier.build()` (`lib/engines/health/providers/health_providers.dart`, currently returns `null` unconditionally — "no auto-sync on startup" per the inline comment) changes to: on supported platforms (`HealthSyncService.instance.isSupported` — iOS/Android only, matching the platform limitation already coded), auto-call `sync()` once per app session if a new pref `prefHealthAutoSyncEnabled` (default **true**) is set.
- Opt-out toggle added to Settings; permission request framed explicitly during onboarding (alongside the existing currency-selection page) rather than silently firing an OS permission dialog mid-session.
- Web/Windows builds remain unaffected — this is the same platform ceiling noted in §3.1, not solved by this change.

Files: `lib/engines/health/providers/health_providers.dart`, `lib/core/providers/app_settings_provider.dart` (new pref), `lib/core/constants/app_constants.dart` (new `prefHealthAutoSync` key), `lib/features/onboarding/screens/onboarding_screen.dart`.

**AR/EN parity.** New ARB keys: `health.autoSync.settingsToggle` ("Auto-sync health data" / "مزامنة بيانات الصحة تلقائيًا"), `health.autoSync.onboardingPermissionPrompt` ("Monk can sync your steps and weight automatically — allow access?" / "يمكن لـ Monk مزامنة خطواتك ووزنك تلقائيًا — هل تسمح بالوصول؟"). Both ARB files, matched keys.

Effort: **S**.

---

### 3.6 Calendar / ICS Import

Per report 02 §3: "Schedule — Manual block creation — Calendar import (ICS) unimplemented," and report 02 §4 additionally confirms `calendar_events.gcal_event_id` exists in schema but sync is unimplemented (this specific finding belongs to report 02, not report 01 — corrected here from an earlier mis-citation in this document's drafting).

- Hand-rolled minimal ICS (VEVENT) parser at `lib/engines/time/data/import/ics_parser.dart` — ICS is a simple line-based text format, so no new third-party dependency is needed for a first pass (keeps the dependency surface small, unlike the CSV case which genuinely benefits from the `csv` package for delimiter/quoting edge cases).
- Recurring events (`RRULE`) expanded to a rolling 90-day window at import time; re-importing the same `.ics` file replaces previously-imported-but-not-yet-passed events, matched by a new `ics_uid` column, so the flow stays a repeatable manual re-import rather than a live sync (no new backend polling job).

**Schema:** `alter table public.calendar_events add column ics_uid text, add column source text not null default 'manual';` — RLS unaffected (existing `calendar_events_own` policy already covers all columns). Down-migration: `alter table public.calendar_events drop column ics_uid, drop column source;`

**AR/EN parity.** New user-facing copy from this feature: a file-picker entry point ("Import calendar (.ics)" / "استيراد تقويم (.ics)"), and a re-import confirmation ("This will replace {n} upcoming imported events — continue?" / "سيؤدي هذا إلى استبدال {n} من الأحداث المستوردة القادمة — متابعة؟"). ARB keys: `calendar.import.cta`, `calendar.import.reimportConfirm` (ICU plural on `{n}`). Both ARB files.

Effort: **M**.

---

## 4. The Wedge, Sharpened + Home/Overview Redesign

### 4.1 Choosing the wedge

reports/03_market_analysis.md lays out four JTBD segments and rates the debt-payoff seeker (Segment 2) as "the highest-urgency JTBD — people pay for debt relief tools," while separately concluding the Egyptian/MENA finance wedge is "real" but "only 30% executed" (§2b). reports/04_swot_verdict.md's top-3-strengths list independently converges on the same asset from a different angle: "the integrated resource score / daily check-in... is Monk's only data asset that compounds over time" (§2c item 3) and names it, together with Egyptian financial modeling, as what to double down on. The kill-criteria table (03 §5) makes Day-30 retention and Finance activation the two literal pass/fail gates for the whole product.

**Alternatives considered and rejected as the *primary* wedge:**

| Candidate wedge | Why it's strong | Why it loses to the chosen wedge |
|---|---|---|
| Debt-payoff / freedom-date calculator (Segment 2) | Highest-urgency JTBD per 03 §2a; "people pay for debt relief tools" | It is a **feature**, not a home screen. A freedom-date number is a single KPI a user checks weekly, not daily — it doesn't justify opening the app every morning, and per 04 Handoff #7 it is still a multi-day build that has not shipped. It becomes the flagship *card inside* Finance, not the app's front door. |
| Arabic-first finance + EGP (Segment 1/general wedge) | 03 §2b: "the wedge is real"; strongest structural moat (installment providers, wallets) | 03 §2b also states execution is 30% complete and Arabic is "cosmetic, not functional" (04 Weakness #4). Leading marketing with a wedge whose UI doesn't deliver on it yet is a credibility risk on day one. It must be *fixed* (guardrail: AR/EN parity below) before it can be *led with*. |
| Schedule-modes differentiation (report 03 §2a names this segment "Muslim professionals" as the source demand-side segment; the shipped product feature itself is secular — see the note below the table) | Genuinely unique (04 Strength #2); "no competitor will copy because they don't understand the domain" | Real but narrower distribution surface — a schedule screenshot doesn't summarize the whole app the way a score does, and it's a single-engine feature, not a cross-engine hero. |
| Quantified-self correlations (Segment 4) | Small but articulate segment | 03 §2a rates this segment's size as "small globally" — not enough volume to be the *primary* wedge, though it is a natural downstream feature of the chosen wedge. |

*Note on framing (Guardrail 3 compliance):* report 03 names the underlying market segment "Muslim professionals" and report 04 characterizes the resulting schedule-modes feature as serving "Egyptian/Muslim lifestyle" scheduling needs. Per the guardrail against reintroducing or marketing religious content even indirectly, this plan describes the *shipped feature itself* in strictly secular terms — an intermittent-fasting eating-window mode and an Egyptian Friday–Saturday work-week mode — and does not use "Muslim," "Islamic," or "Deen"-adjacent language in any product copy, screen, or marketing asset. The market segment's motivations (as named in report 03) are cited here only to explain underlying demand; they are not adopted as the product's own positioning. This note applies equally to §9.2 item #3 below, which references the same feature, and to any future marketing copy describing it.

**Chosen wedge: the Resource Pulse — the cross-engine 0–100 score, computed today by `resourceScoresProvider`, made into Monk's single daily habit and its only marketing image.**

Justification: this is the one asset in the codebase that already satisfies all three things the other wedges lack simultaneously — (a) it exists and works today (`lib/core/providers/resource_scores_provider.dart`, cited as Strength #3 and #6 in 04), (b) it is genuinely undifferentiated-nowhere-else per 04 §2c item 3, and (c) it is screenshot-native — a single number plus four sub-scores is the only Monk artifact that compresses the whole "personal mastery OS" pitch into one glance, directly answering 03 §4c's gap: "no shareable output (imagine: 'share your weekly resource score')" and 04 Weakness #5 ("no shareable output / social hook"). It also directly serves 03 §4b's highest-leverage distribution channel — the founder's daily Kyberia posting — by giving him a native, zero-cost artifact to post every day instead of screen recordings.

This does **not** replace Finance or the Egyptian wedge as the deepest *product* moat — 04 §2c still ranks Egyptian financial modeling #1 to double down on for retention and paid conversion. The Resource Pulse is the **acquisition and Day-1/Day-30 retention wedge**; Finance depth remains the **monetization wedge** (03 §3b: Finance is the proposed paid gate). They are complementary, not competing — the Pulse is the front door that gets a user to invest the setup time 04 §2a's "what must be true" list requires before Finance activation can happen at all.

**Kill-criteria alignment:** leading with the Pulse directly targets the two kill metrics in 03 §5 that gate the whole business — Day-30 retention (<20% kills it) and total engaged users at month 6 (<50 kills it). A screen a user opens once and screenshots is not enough; the redesign below is built so the Pulse is worth opening *daily*, not just once.

---

### 4.2 Home/Overview redesign — the Resource Pulse as hero

Scope: `lib/features/overview/screens/overview_screen.dart`. Kept fully inside the existing engine/provider architecture — no new state library, no new routing paradigm. The redesign reuses `resourceScoresProvider` as-is at the data layer (Layer 5, cross-engine, per ARCHITECTURE.md) and only proposes UI-layer (Layer 6) changes plus one new Computed provider (a 7/14-day score history, described in 4.4).

#### Layout, top to bottom (mobile — the primary shipping surface per 04 Weakness #2, "no mobile app" being the #2 kill risk)

1. **Status bar zone / app identity strip.** Background `#08070C` (the guardrail-mandated palette — see §8.1 for why these hexes are a fixed constraint, not an open proposal). Small wordmark "Monk" in PlayfairDisplay, 12sp, gold `#C8A050`, top-left — fixes 04 Weakness #8 (brand inconsistency) by making the correct name visually non-negotiable on the one screen every user sees daily. Top-right: streak counter (flame icon + consecutive days with a completed check-in) — new, cheap, reuses `checkinProvider` data that already exists (`lib/engines/checkin/providers/checkin_providers.dart`).

2. **Greeting row** (kept from current `_GreetingHeader`/`_Row1Greeting`, refined). Surface color `#0D0B13`, single `AppCard`-equivalent, rounded 16px. "Good morning, {firstName}" in PlayfairDisplay 20sp on `#E8E8E8`-equivalent (dark-theme text), date in Roboto 12sp secondary gray. No layout change from current — this is intentionally the *quietest* zone.

3. **THE HERO: Resource Pulse ring.** This is the new centerpiece, replacing the current `_Row2Scores` row-of-five-cards and `_ResourceScoreCard` as separate elements — they are unified into one dominant visual block, full card width, roughly 40% of the fold's remaining vertical space (up from a single row today). Structure, precisely:
   - A large circular ring, ~180dp diameter, centered. The ring is not one arc but **four concentric or four segmented arcs** (one per engine — Money, Time, Energy, Health), each in its own arc-quadrant of the same circle (90° each), each colored by that engine's existing semantic color (`AppColors.success` for Money, `AppColors.gold` for Time, `AppColors.warning` for Energy, `AppColors.health` for Health — unchanged, per current `_Row2Scores` mapping) so the ring reads as a single object made of four proportional fills, not four separate gauges.
   - Center of the ring: the overall score (`scores.overall`, 0–100) in Roboto, 48sp, weight 800, color determined by the existing `_scoreColor()` thresholds (≥75 success green, ≥45 warning, else error) — kept as-is, it's already correct logic, just needs to render on card `#12101E` instead of the superseded `#1A1A1A`.
   - Directly under the number: "/100" in gold `#C8A050`, 14sp.
   - Directly under that: one line of dynamic copy, e.g. "Your best pillar: Time (82)" / "Focus area: Money (34)" — computed client-side from `scores`, no new provider needed, this alone makes every screenshot different from every other user's and from yesterday's.
   - Below the ring, a slim horizontal row of 4 labelled dots (not cards) — Money/Time/Energy/Health — each showing its emoji + numeric score in small text, tap-through to that engine's overview route (preserves current tap-to-navigate behavior from `_PillarScoreCard`). This keeps the drill-down utility of today's row-of-five without competing visually with the ring.
   - A single gold outlined "Share" icon-button sits top-right *of this card only* (not the whole screen) — this is the direct fix for 04 Weakness #5 / 03 §4c.

4. **Today's snapshot strip** — a single row of 3–4 compact stat chips (not full KpiCards): Net Worth delta, Habits done/total, Focus minutes today, Mood emoji. This condenses the current `BentoGrid` of 4 `KpiCard`s and `_Row3PillarSummaries` into one denser strip so the Pulse can dominate the fold — the per-engine detail cards (`_Row3PillarSummaries` content) move to a "See details" expand or to each engine's own overview screen, since that data is duplicated there already.

5. **Check-in banner** (`CheckinBanner`, kept as-is — it is functioning infrastructure per `lib/engines/checkin/providers/checkin_providers.dart` and is the input mechanism that keeps the Pulse dataset alive daily; unchanged in this redesign).

6. **7-day trend sparkline of the overall score** — new, thin, directly under the check-in banner. Reuses the existing bar-chart pattern from `_Row4Analytics` (already renders a 7-day focus bar chart in gold) but plots `overall` score instead of focus minutes, so returning users (see 4.5) see *visible proof of progress* on the same screen, not buried in a separate analytics tab. This 7-day view is the always-visible default for every user; scrolling/expanding it reveals up to 14 days of history on the Free tier (the boundary defined in §7.1/§7.3) — Pro removes that 14-day cap entirely and unlocks unlimited history (§7.2). This single, consistent day-count design is used everywhere this feature is discussed in this document.

7. **Today's Habits + Active Goals** (kept, `_Row5HabitsGoals` content, unchanged) — below the fold, since these are supporting detail, not the hero.

8. Getting-Started checklist keeps its current logic (`_OnboardingChecklistCard` / `_CompactChecklist`) but is **relocated to a dismissible banner directly above the Pulse** for first-time users only (see 4.5) rather than competing with the greeting row for top-of-screen real estate.

Desktop layout (`_DesktopOverview`, ≥800px, `_kDesktopBreak`): keep the existing 5-row full-height grid structure (no new layout paradigm), but replace Row 2's five equal-width cards with the same ring-hero treatment scaled to fit one row height — ring on the left third, the 4 tap-through dots + share button stacked to its right, so desktop keeps its information-density advantage while still visually leading with the ring rather than five small gauges of equal visual weight, which is the current problem: nothing dominates, so nothing is memorable in a screenshot.

#### What makes it screenshot-worthy

- **One dominant number + one dominant shape.** Today's Overview has 5 equal-weight gauge cards, 4 KPI cards, a chart, 2 lists — roughly 12+ competing visual elements of similar size. A screenshot of that reads as "a dashboard," generic and forgettable, matching 04's verdict that Monk "rewards second-week users, not first-hour users" (02 §6) — nothing in the current layout is designed to be understood in the 1.5 seconds a scrolling thumb gives a social post. The redesign collapses the hero to one ring + one number + one line of copy, which is legible at thumbnail size on a phone feed.
- **Personalized, not generic.** The dynamic "Your best pillar: X" / "Focus area: Y" line means no two users' (and no two days') screenshots look alike — this is what makes it worth posting ("look how my Energy score jumped") rather than a static template graphic.
- **Color does the work.** The four-color ring uses Monk's own semantic palette (success/gold/warning/health) already defined in `app_theme.dart` — nothing new to design, and the segmented-arc shape itself becomes recognizable as "the Monk score" the same way a Duolingo streak flame or a Spotify Wrapped card is recognizable, satisfying 03 §4c and §4b's ask for an artifact that carries brand recognition through repetition.

#### Share-card export spec

New surface, not a new backend: rendered client-side to an image and handed to the OS share sheet. Requires two new packages (`screenshot: ^3.0.0` for widget-to-image capture, `share_plus: ^10.0.0` for the native share sheet) — both are UI/utility packages, not a backend, auth, or state-management library, so this does not violate the stack guardrail; flag to founder only if either introduces a platform permission prompt on iOS/Android that needs App Store review copy.

- **Canvas: 1080×1920px** (9:16, Instagram Story / WhatsApp Status native ratio — the two channels 03 §4b identifies as the founder's actual distribution surface). A secondary 1080×1080px square variant for X/LinkedIn feed posts, same content, ring recentered.
- **Background:** solid `#08070C` top-to-bottom, no gradient — matches the guardrail's darkest bg tone exactly so the card reads as unmistakably "Monk dark" even cropped.
- **Top 15% of canvas:** Monk wordmark, PlayfairDisplay, gold `#C8A050`, centered, with the tagline in Roboto 14sp gray directly beneath it in the user's active locale (AR or EN, see below). "Kyberia Labs" mark, small, bottom-right corner of this same zone, in muted `#444444`-equivalent — brand attribution without competing with the score.
- **Middle 55% of canvas:** the same four-arc ring as on-screen, rendered larger (~640dp equivalent at this resolution), centered, with the overall number and "/100" beneath it exactly as on-device, plus the four small labelled dots in a row beneath the ring.
- **Below the ring:** the dynamic one-line insight ("Your best pillar: Time (82)"), Roboto 20sp, white/light text on the dark bg.
- **Bottom 20%:** the date the score was captured (e.g., "14 July 2026" / Arabic-formatted equivalent), Roboto 12sp gray, plus a single small line: "Track yours → monk.app" (or the corrected canonical domain once 04 Handoff #5's rebrand lands — do not hardcode `prp-app.website`, flagged as a dependency below) in gold.
- **Export mechanism:** wrap the ring widget in a `RepaintBoundary`/`Screenshot` capture at 3x pixel ratio, encode PNG, pass to `share_plus`'s `Share.shareXFiles()`. No server round-trip, no new Supabase table — this is a pure client-side render, so it introduces zero new RLS surface.
- **Dependency flag — BLOCKED pending founder decision:** the share card's bottom-line URL should point to the app's real distribution domain. Per 04 Weakness #8, the current domain (`prp-app.website`) contradicts the "Monk" brand the share card is designed to spread; shipping the share feature before the domain/brand fix (04 Handoff #5, 1-day effort) means every viral share drives traffic to a domain that says "PRP." Recommend sequencing Handoff #5 before this feature ships.

#### AR/EN parity for every new string

Every new user-facing string introduced by this redesign must ship in both `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` with matching keys, per the i18n guardrail and directly remediating 04 Weakness #4 ("Arabic is fake") rather than adding to it:

| New string | EN key example | Notes |
|---|---|---|
| Dynamic "Your best pillar / Focus area" line | `overview_bestPillar`, `overview_focusArea` (parameterized with pillar name + score) | Pillar names (Money/Time/Energy/Health) must themselves be ARB-keyed, not hardcoded — they currently are hardcoded English literals in `_Row2Scores` (`label: 'Money'` etc.), which is exactly the pattern 01 §2e flags. |
| Share-card tagline, date format, "Track yours →" | `share_tagline`, `share_cta` | Date formatting must use `intl`'s locale-aware `DateFormat` (already imported in the file) with the active `Locale`, not a hardcoded `en_US` `NumberFormat`/`DateFormat` as the current file does at line 77 and elsewhere — this is a pre-existing bug the redesign should fix in the same pass. |
| Streak counter copy ("X day streak") | `overview_streak` (ICU plural) | Arabic plural rules differ from English (dual form) — must use ICU `plural` syntax in the ARB, not string concatenation. |
| Getting-Started banner relocation copy | reuse existing `checklist_*` keys | No new keys if copy is unchanged, just repositioned. |
| First-time fallback insight line ("Log your first habit to start tracking Health") | `overview_fallbackInsight` (parameterized by pillar name) | Used only when a pillar score is still at seed/zero baseline (§4.3) — a CTA disguised as an insight, not a raw "0" score. |
| Share-button first-time tooltip ("Come back in a week to get a Pulse worth sharing") | `overview_shareTooltipFirstTime` | Shown on tap of the de-emphasized share button for Day 0–3 users only (§4.3). |
| Sparkline not-enough-data CTA ("3 more check-ins to unlock your trend") | `overview_sparklineUnlockCta` (ICU plural on the count) | Replaces a bare empty/error state per §4.3; Arabic needs ICU plural for "N more check-ins." |

---

### 4.3 First-time vs 30-day-retained user: what differs on the same screen

The screen is the same widget tree and the same providers for both users — no branching architecture, no separate "new user home" route — only the **data shape** and **one conditional banner** differ, which keeps this inside the existing provider/engine structure rather than forking the screen.

| Element | First-time user (Day 0–3) | 30-day-retained user |
|---|---|---|
| Ring fill | Seeded/near-empty — `resourceScoresProvider` returns low baseline values (money≈50 default per current logic, others near 0–30) because no habits/focus/check-ins exist yet. Per 02 §1 ("first aha is not today"), the redesign must not pretend otherwise — the ring should visibly look "just started," not fake a high score. | Ring reflects 30 days of real data; colors are more saturated/confident because scores stabilize above the seed baseline once real habits and check-ins accumulate. |
| Getting-Started banner (item 8, above) | **Visible**, pinned directly above the ring, un-dismissed by default. Copy should set explicit expectations per 02 §6's recommendation: "This app rewards daily use — complete your first check-in to start your Resource Pulse." | **Hidden** (checklist `allDone` or dismissed) — replaced by the 7-day trend sparkline (item 6) becoming the visually dominant secondary element, since a 30-day user has trend data worth showing and a new user does not. |
| Dynamic insight line | Falls back to a static onboarding-flavored line when there isn't enough data yet, e.g. "Log your first habit to start tracking Health" (a CTA disguised as an insight, ARB key `overview_fallbackInsight` — see §4.2) rather than a hollow "Focus area: Health (0)" — a raw 0 score reads as broken, not motivating. | Full dynamic comparison ("Your best pillar: Time (82), up 14 from last week") — the "up 14" delta requires the new 7/14-day history provider below. |
| Share button | Present but visually de-emphasized (outline only, no fill) — sharing a near-empty ring provides no value and could embarrass a new user; tapping it can show a one-time tooltip "Come back in a week to get a Pulse worth sharing" (ARB key `overview_shareTooltipFirstTime` — see §4.2) rather than being hidden entirely (hiding it would bury a feature users should know exists). | Fully emphasized (filled gold button) — this is the moment 03 §4c's shareable-output opportunity actually pays off, since the score and the delta are now meaningful. |
| 7-day sparkline (item 6) | Not shown, or shown with an explicit "not enough data yet" empty state (per 01 §2b's existing weak-empty-state pattern — this redesign should give it a real CTA: "3 more check-ins to unlock your trend" — ARB key `overview_sparklineUnlockCta`, see §4.2 — rather than a bare error/blank, fixing the empty-state gap 01 §2b and 02 §2 both flag). | Fully populated 7-bar chart, colored gold, matching the existing `_Row4Analytics` visual language exactly so it feels like a natural extension of a pattern the user already recognizes from the Focus screen. |
| Snapshot strip (item 4) | Shows zeros honestly (EGP 0 net worth if no accounts added, "0/0 habits" if none created) with each stat tappable straight into that engine's add-first-item flow — this reuses and surfaces the existing checklist routing (`item.route` in `_CompactChecklist`) rather than the current silent "No habits yet" text with no CTA (02 §2, 01 §2b). | Shows real deltas ("Net Worth ↑ EGP 1,200 this week") — requires no new provider, `financeSummaryProvider` and `habitsTodayProvider` already carry this, just needs delta computation against yesterday's snapshot (new lightweight Computed-layer provider, see 4.4). |

### 4.4 One new provider required (Layer 4, Computed — no architecture change)

To support the 7-day score sparkline and week-over-week deltas, add `resourceScoreHistoryProvider` in `lib/core/providers/resource_scores_provider.dart` (same file, same layer) that snapshots the daily `ResourceScores.overall` value once per day into a small new Supabase table.

- **New table: `resource_score_snapshots`** — columns: `id uuid primary key default gen_random_uuid()`, `user_id uuid not null references auth.users(id)`, `snapshot_date date not null`, `money_score int`, `time_score int`, `energy_score int`, `health_score int`, `overall_score int`, `created_at timestamptz default now()`, unique constraint on `(user_id, snapshot_date)`.
- **RLS policy (mandatory, per guardrail):** `create policy "resource_score_snapshots_own" on resource_score_snapshots for all using (user_id = auth.uid()) with check (user_id = auth.uid());`
- **Rollback path:** this is a purely additive new table with no foreign-key dependents and no columns added to existing tables — the down-migration is `drop table if exists resource_score_snapshots;`. It has zero effect on existing live data since it reads from other engines' existing tables at snapshot time and never mutates them; reverting it only removes historical trend display, not any founder data already in Money/Time/Energy/Health tables.
- Write path: a lightweight daily upsert triggered client-side the first time `resourceScoresProvider` is computed each day (compare `snapshot_date` to today, upsert if missing) — no cron/Edge Function required, keeping this inside the existing Supabase-client-only infrastructure layer rather than adding new backend surface.

---

## 5. New Engines: Debt Payoff, Assets, Digital Inventory, Household Tier

All four engines below follow the existing `lib/engines/<name>/{data/models, data/repositories, providers}` + `lib/features/<name>/screens` structure and the 6-layer provider hierarchy (Infrastructure → Repositories → Engine data providers → Computed providers → Cross-engine providers → UI providers), per the architecture guardrail and consistent with the `money`/`health` engines already in the codebase (`lib/engines/money/`, `lib/engines/health/`). No new backend, auth, or state-management library is introduced — Supabase + RLS, Clerk, Riverpod 3 `AsyncNotifier`, GoRouter throughout.

Dependency-order note: per reports/01_codebase_audit.md §3a (schema.sql is missing 12+ tables already in production) and reports/04_swot_verdict.md Weakness #5, none of engines (a)–(c) should ship until the RLS/schema audit (Section 1 foundation phase — export `supabase db dump`, confirm RLS on existing 20+ tables) is closed out. Building new tables on top of an unverified RLS baseline compounds Threat #5 in reports/04_swot_verdict.md ("RLS gap on new tables... misconfigured anon key could expose financial data between users"). Engine (d), Household, is explicitly P2 and gated behind (a)–(c) shipping cleanly, per its own risk profile below.

### 5a. Debt Payoff module

**Why:** reports/03_market_analysis.md §2a Segment 2 names debt-payoff seekers as "the highest-urgency JTBD" in the Egyptian market (~40% of urban adults carry installment debt), and reports/04_swot_verdict.md Handoff #7 and Opportunity #4 both name a "debt freedom date" calculator as Monk's most monetizable near-term feature. This directly extends existing `debts`, `installment_plans`, and `credit_cards` data already modeled in `lib/engines/money/data/models/money_models.dart` — it is additive, not a rebuild.

**Naming note:** this engine is referred to as `debt_payoff` consistently throughout this document (Section 1 item 8, the route `financeDebtPayoff` at `/finance/debt-payoff`, and the folder paths below) — an earlier draft of this section used `lib/engines/debt/` in one place, which is corrected here for internal consistency.

**Integration with existing money data — no duplication of source-of-truth balances:**
The module does NOT re-store balances. It reads `debtsProvider` (`ExternalDebt`), `installmentPlansProvider` (`InstallmentPlan`), and `creditCardsProvider` (`CreditCard`) as-is and adds a payoff *strategy* layer plus a *plan-vs-actual history* layer on top, matching how `financeSummaryProvider` already composes cross-provider computed state (`lib/engines/money/providers/money_providers.dart` lines 227-286).

**New Dart models** (`lib/engines/debt_payoff/data/models/debt_models.dart`):

```dart
enum PayoffStrategy { avalanche, snowball, custom }

class PayoffPlan {
  final String id;
  final PayoffStrategy strategy;
  final double extraMonthlyPayment;   // amount above minimums user commits to
  final List<String> customOrder;     // debt/card/installment ids, only used if strategy == custom
  final DateTime createdAt;
}

class PayoffSnapshot {           // one row per month, for plan-vs-actual chart
  final String id;
  final DateTime monthOf;        // first-of-month
  final double plannedTotalDebt; // projected balance per the active PayoffPlan
  final double actualTotalDebt;  // computed from live debts+installments+cards at snapshot time
  final double plannedPayment;
  final double actualPayment;    // derived from transactions tagged as debt payments, or manual entry
}
```

`debtFreedomDateProvider` (**Provider, Layer 5 — cross-engine**, reclassified here from an earlier "Layer 4" label for internal consistency: per this document's own 6-layer definitions, a provider that composes across the existing money engine and this new debt_payoff engine belongs at the cross-engine tier, the same way §4.2 classifies `resourceScoresProvider` as Layer 5) walks all active `ExternalDebt` + non-completed `InstallmentPlan` + `CreditCard` balances, applies the selected `PayoffStrategy` (avalanche = highest APR/rate first; snowball = smallest balance first; `CreditCard.apr` already exists for avalanche ordering, `lib/engines/money/data/models/money_models.dart` line 138), and projects a debt-free month by simulating minimum payments + `extraMonthlyPayment` forward. This is pure computation over existing providers — no new balance fields needed on `debts`/`installment_plans`/`credit_cards`.

**New Supabase tables + RLS (both required, both reversible):**

```sql
create table public.payoff_plans (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  strategy text not null check (strategy in ('avalanche', 'snowball', 'custom')),
  extra_monthly_payment numeric default 0,
  custom_order uuid[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.payoff_plans enable row level security;
create policy "payoff_plans_own" on public.payoff_plans
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table public.payoff_snapshots (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  month_of date not null,
  planned_total_debt numeric not null,
  actual_total_debt numeric not null,
  planned_payment numeric not null,
  actual_payment numeric not null,
  created_at timestamptz default now(),
  unique (user_id, month_of)
);
alter table public.payoff_snapshots enable row level security;
create policy "payoff_snapshots_own" on public.payoff_snapshots
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

Both are net-new, additive tables — rollback is `drop table public.payoff_snapshots; drop table public.payoff_plans;` with zero impact on existing `debts`/`installment_plans`/`credit_cards`/`bank_accounts` data, satisfying the "preserve founder's live data" guardrail trivially (nothing existing is altered).

**Providers:** `payoffPlanProvider` (`AsyncNotifier<PayoffPlan?>`, Layer 3, mirrors `CashOnHandNotifier` singleton-row pattern in `lib/engines/money/providers/money_providers.dart` line 189), `payoffSnapshotsProvider` (`AsyncNotifier<List<PayoffSnapshot>>`, Layer 3), `debtFreedomDateProvider` (Layer 5, cross-engine, composes `debtsProvider` + `installmentPlansProvider` + `creditCardsProvider` + `payoffPlanProvider` — same composition pattern as `financeSummaryProvider`). A monthly cron-like snapshot write (client-triggered on first app open of a new month, comparing against last `payoff_snapshots` row) populates plan-vs-actual without a backend job, consistent with the no-new-infra guardrail.

**Free/Pro split (authoritative gating spec is §7.1/§7.3):** the basic freedom-date number is free for all users; the avalanche-vs-snowball comparison and payment-scenario simulator are Pro-gated behind a lock icon on an "Advanced Payoff Strategy" card. `debtFreedomDateProvider` itself always computes the basic date for every user; a separate Layer-6 UI provider (`payoffStrategyComparisonUiProvider`, reading `entitlementProvider` from §7.6) gates *rendering* of the avalanche/snowball comparison view and the payment-scenario simulator. The underlying `PayoffPlan`/`PayoffSnapshot` models and computation are not duplicated for free vs. Pro — only the UI-layer rendering is gated, keeping this inside the existing 6-layer hierarchy rather than forking the engine.

**UI surface:** new route `financeDebtPayoff` under the existing Finance tab (`/finance/debt-payoff`), linked from `finance_liabilities_screen.dart` where `FinanceLiabilitiesScreen` already renders `debtsProvider` (read above) — the "debt-free date" becomes the hero metric card at the top of that screen, replacing the current plain "Total Outstanding" figure as primary framing (numerically supplement, don't remove, per reports/02_product_teardown.md finding that empty/summary states lack a clear headline number).

**i18n:** New ARB keys required in both `app_en.arb`/`app_ar.arb`: `debtPayoffTitle`, `debtFreeDateLabel`, `strategyAvalanche`, `strategySnowball`, `strategyCustom`, `extraPaymentLabel`, `plannedVsActualLabel` — no hardcoded strings, per i18n guardrail and to avoid repeating the Weakness #4 pattern (reports/04_swot_verdict.md) where Arabic is nav-only.

**Effort: M (4–6 days, aligned with reports/04_swot_verdict.md Handoff #7's own estimate)**: 2 tables + RLS, 2 models, 3 providers, 1 new screen + 1 hero-card retrofit into existing liabilities screen, avalanche/snowball simulation logic, ARB keys. **Dependency order:** after the RLS/schema audit foundation phase (Section 1 item 1) and the currency/FX fix (Section 1 item 5, so freedom-date math is correct across accounts) — matching Section 1's stated dependencies for this item exactly. Section 1 also lists CSV import (item 7) as a dependency; that is treated here as a **soft, data-quality dependency rather than a hard blocker**: the avalanche/snowball simulation can run correctly on manually-entered debt data from day one, and its accuracy simply improves once bulk import (§3.2) is available — so this remains the first *new engine* to ship among 5a–5c, because reports/03_market_analysis.md and reports/04_swot_verdict.md both independently rank it the highest-leverage, highest-monetization near-term feature.

### 5b. Assets register (with warranty-expiry alerts)

*Evidence-traceability flag:* unlike Debt Payoff above, no report explicitly recommends a physical-asset/warranty register. This is the plan-writer's own design addition, justified only loosely by a general "life OS completeness" narrative and the notification-re-engagement gap named in reports/03_market_analysis.md §3c ("push notifications exist but are not configured to re-engage"), neither of which specifically calls for asset tracking. It is included because it is cheap, additive, and reuses existing storage/notification infrastructure with no new dependency — but the founder should treat this item as optional scope, not a report-mandated fix, when prioritizing against 5a/5c.

**Why:** Extends the "life OS" completeness the founder is dogfooding (net worth today only counts liquid/debt accounts, not owned physical assets) and gives the notification system (currently only wired to schedule blocks, per `lib/services/notification_service.dart`) a second, higher-value use case, aimed at the push-notification re-engagement gap named in reports/03_market_analysis.md §3c ("push notifications exist but are not configured to re-engage" — this finding is report 03's, corrected here from an earlier mis-citation to report 01, which does not discuss notifications at all).

**New Dart model** (`lib/engines/assets/data/models/asset_models.dart`):

```dart
enum AssetCategory { electronics, vehicle, furniture, appliance, jewelry, other }

class Asset extends Equatable {
  final String id;
  final String name;
  final AssetCategory category;
  final double purchasePrice;
  final String currency;          // reuse existing currency convention ('EGP' default)
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiryDate;
  final double? currentEstimatedValue; // optional, manual, for net-worth inclusion
  final String? notes;
  final String? receiptAttachmentUrl;  // reuses existing storage.buckets('attachments') policy
}
```

**New Supabase table + RLS:**

```sql
create table public.assets (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  name text not null,
  category text not null default 'other'
    check (category in ('electronics','vehicle','furniture','appliance','jewelry','other')),
  purchase_price numeric default 0,
  currency text not null default 'EGP',
  purchase_date date,
  warranty_expiry_date date,
  current_estimated_value numeric,
  notes text,
  receipt_attachment_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.assets enable row level security;
create policy "assets_own" on public.assets
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_assets_user_warranty on public.assets(user_id, warranty_expiry_date)
  where warranty_expiry_date is not null;
```

Reversible: net-new table, `drop table public.assets;` fully rolls back with no touch to any existing table. Uses the existing `attachments` storage bucket and its existing per-user policies (`supabase/schema.sql` lines 213-218) rather than inventing new storage rules.

**Provider design** (mirrors `lib/engines/money/providers/money_providers.dart` `BankAccountsNotifier` pattern exactly):

```dart
final assetsProvider = AsyncNotifierProvider<AssetsNotifier, List<Asset>>(AssetsNotifier.new);

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  @override
  Future<List<Asset>> build() => AssetsRepository.instance.getAssets();
  Future<void> upsert(Asset asset) async {
    await AssetsRepository.instance.upsertAsset(asset);
    ref.invalidateSelf();
  }
  Future<void> delete(String id) async { ... }
}

// Layer 4 computed: assets expiring within 30 days, feeds notification scheduling
final expiringWarrantiesProvider = Provider((ref) {
  final assets = ref.watch(assetsProvider).value ?? [];
  final cutoff = DateTime.now().add(const Duration(days: 30));
  return assets.where((a) =>
    a.warrantyExpiryDate != null &&
    a.warrantyExpiryDate!.isBefore(cutoff) &&
    a.warrantyExpiryDate!.isAfter(DateTime.now())
  ).toList();
});
```

**Notification integration point:** `lib/services/notification_service.dart` currently exposes `scheduleBlockNotifications()` (IDs 1000-1999, schedule-block-specific) and a generic `showInstant()`. Add a new method `scheduleWarrantyAlerts(List<Asset> assets)` using a dedicated ID range (e.g. 3000-3999, avoiding collision with the existing 1000-1999 schedule-block range) that calls `_plugin.zonedSchedule()` once per expiring asset, 7 days before `warrantyExpiryDate`, using the same `AndroidNotificationDetails`/`DarwinNotificationDetails` pattern already used for schedule blocks (lines 78-101). This is called from `expiringWarrantiesProvider`'s consumer (app-start hook, same place `scheduleBlockNotifications` is presumably invoked) — no new notification infrastructure, just a new channel id (`'asset_warranties'`) and a new scheduling method on the existing service class.

**i18n:** ARB keys: `assetsTitle`, `assetCategoryElectronics/Vehicle/Furniture/Appliance/Jewelry/Other`, `warrantyExpiresIn` (with plural forms for AR), `addAssetCta`.

**Effort: M** (3-4 days: 1 table + RLS + index, 1 model, 1 repository, 2 providers, 1 notification method, 1 new screen under a new route e.g. `/finance/assets` or a new top-level engine folder depending on Section 1's IA decision — flagged here as depending on that section's nav restructuring, not on this section). **Dependency order:** after Debt Payoff; independent of Digital Inventory, can ship in parallel with it since both are net-new isolated tables. **Monetization:** see §7.1/§7.3 for this engine's free-tier limit and paywall trigger — not defined in this subsection because gating is specified centrally in Section 7.

### 5c. Digital account inventory (no secrets stored)

*Evidence-traceability flag:* as with 5b, no report explicitly recommends a digital-account/subscription-renewal inventory. The justification below rests on `kDigitalWallets` already being correctly modeled (a naming-accuracy fact, not a feature recommendation) and a general observation about fragmented Egyptian digital finance. Flagged as an unsourced, plan-writer-originated design proposal — the lowest priority of the three net-new engines in this section if scope needs to be trimmed.

**Why:** Egyptian digital finance is fragmented across wallets/providers (Vodafone Cash, FawryPay, InstaPay, OPay — already modeled as `kDigitalWallets` in `lib/engines/money/data/models/money_models.dart` lines 6-9) plus subscriptions (Netflix, Spotify, etc.) that silently renew. This is a low-risk, additive engine: a renewal-date tracker, explicitly not a password manager, which avoids taking on any credential-storage liability the guardrails would otherwise force ("BLOCKED" territory if it touched secrets — it does not).

**Fields allowed vs. forbidden (hard rule, enforced at the model level so it cannot regress):**

| Allowed | Forbidden |
|---|---|
| Service/account name (e.g. "Netflix", "Vodafone Cash") | Password / PIN |
| Category (subscription, wallet, utility, SaaS) | Security questions/answers |
| Renewal date / billing cycle | 2FA seed or backup codes |
| Renewal amount + currency | Card numbers, CVV, expiry |
| Username/email used to log in (identifier only, not secret) | API keys / tokens |
| Free-text notes (user's own risk if they type something sensitive — no dedicated secret field exists to encourage it) | Any field with "password", "secret", "token", "pin", "cvv" in its name — none defined, by design |
| Cancellation URL / support contact | — |

**New Dart model** (`lib/engines/digital_inventory/data/models/digital_account_models.dart`):

```dart
enum DigitalAccountCategory { subscription, digitalWallet, utility, saas, other }

class DigitalAccount extends Equatable {
  final String id;
  final String serviceName;
  final DigitalAccountCategory category;
  final String? loginIdentifier;   // email/username only, never a secret
  final DateTime? renewalDate;
  final double? renewalAmount;
  final String currency;
  final String? cancellationUrl;
  final String? notes;
}
```

**New Supabase table + RLS:**

```sql
create table public.digital_accounts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  service_name text not null,
  category text not null default 'other'
    check (category in ('subscription','digital_wallet','utility','saas','other')),
  login_identifier text,
  renewal_date date,
  renewal_amount numeric,
  currency text not null default 'EGP',
  cancellation_url text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.digital_accounts enable row level security;
create policy "digital_accounts_own" on public.digital_accounts
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_digital_accounts_user_renewal on public.digital_accounts(user_id, renewal_date)
  where renewal_date is not null;
```

No secret-bearing column exists in this schema by design — this is the enforcement mechanism, not a policy note in a doc. Reversible: `drop table public.digital_accounts;`, zero coupling to any other table.

**Provider:** `digitalAccountsProvider` (`AsyncNotifierProvider<DigitalAccountsNotifier, List<DigitalAccount>>`), identical CRUD shape to `AssetsNotifier` above and `BankAccountsNotifier` in `lib/engines/money/providers/money_providers.dart`. A `renewalsDueSoonProvider` (Layer 4) computed the same way as `expiringWarrantiesProvider` in 5b, and reuses the same `NotificationService` warranty-alert scheduling method generalized to `scheduleDateAlerts({required String channelId, required List<({String label, DateTime date})> items})` so both Assets and Digital Inventory share one scheduling code path instead of duplicating `zonedSchedule` boilerplate — this is a small refactor to `notification_service.dart`, not a new dependency.

**i18n:** ARB keys: `digitalInventoryTitle`, `renewsOn`, `noSecretsWarningBanner` (a persistent, translated in-app banner stating "Monk never stores passwords or codes here" — this is a trust-building UI element the brief implies should be explicit, not just a backend constraint), `categorySubscription/DigitalWallet/Utility/Saas/Other`.

**Effort: S** (2-3 days: simplest of the three — 1 table + RLS + index, 1 model, CRUD provider, shared notification method, 1 screen). **Dependency order:** can ship alongside or immediately after Assets; both are independent, isolated, additive tables with no cross-dependency on each other or on Debt Payoff. **Monetization:** see §7.1/§7.3 for this engine's free-tier limit and paywall trigger.

### 5d. Household / partner tier — P2, highest-risk migration in this plan

**Why (and why not yet):** reports/04_swot_verdict.md Opportunity #5 names this as a stated roadmap item that raises switching cost, but it is explicitly out of scope for the current phase — it is the only item in this section that touches the shape of every existing RLS policy in the system, and per reports/01_codebase_audit.md the RLS baseline on the *current* single-user tables isn't even fully verified yet (12+ tables missing from `schema.sql`). Layering multi-tenancy on an unverified foundation is the single highest-risk change available to Monk. **This entire subsection is a design sketch for founder approval, not an implementation to schedule.**

**Schema-level design (sketch only — do not implement without founder sign-off):**

Introduce a new `households` table and a nullable `household_id` column added to shareable tables (initially: `bank_accounts`, `transactions`, `debts`, `installment_plans`, `credit_cards` — the Finance engine only; Time/Health/Energy remain single-user in P2 to bound the blast radius):

```sql
create table public.households (
  id uuid primary key default uuid_generate_v4(),
  owner_user_id uuid references public.profiles on delete cascade not null,
  name text not null,
  created_at timestamptz default now()
);
alter table public.households enable row level security;
create policy "households_member" on public.households
  using (auth.uid() = owner_user_id or auth.uid() in (
    select member_user_id from public.household_members where household_id = households.id
  ));

create table public.household_members (
  household_id uuid references public.households on delete cascade not null,
  member_user_id uuid references public.profiles on delete cascade not null,
  role text not null default 'member' check (role in ('owner','member')),
  joined_at timestamptz default now(),
  primary key (household_id, member_user_id)
);
alter table public.household_members enable row level security;
create policy "household_members_own_row" on public.household_members
  using (auth.uid() = member_user_id or auth.uid() in (
    select owner_user_id from public.households where id = household_id
  ));

-- Example: bank_accounts gains an optional household_id
alter table public.bank_accounts add column household_id uuid references public.households on delete set null;

-- RLS must change from a single OR-less check to an OR across two ownership modes:
drop policy "bank_accounts_own" on public.bank_accounts;
create policy "bank_accounts_own_or_household" on public.bank_accounts
  using (
    auth.uid() = user_id
    or (household_id is not null and auth.uid() in (
      select member_user_id from public.household_members where household_id = bank_accounts.household_id
    ))
  )
  with check (
    auth.uid() = user_id
    or (household_id is not null and auth.uid() in (
      select member_user_id from public.household_members where household_id = bank_accounts.household_id
    ))
  );
```

For scope completeness (this rename must not be sketched for `bank_accounts` alone), the identical pattern would be replicated for the other four Finance tables this design touches:

```sql
-- transactions
drop policy "transactions_own" on public.transactions;
create policy "transactions_own_or_household" on public.transactions
  using (auth.uid() = user_id or (household_id is not null and auth.uid() in (
    select member_user_id from public.household_members where household_id = transactions.household_id)))
  with check (auth.uid() = user_id or (household_id is not null and auth.uid() in (
    select member_user_id from public.household_members where household_id = transactions.household_id)));

-- debts, installment_plans, credit_cards: identical pattern, substituting the table name and
-- policy name (debts_own → debts_own_or_household, installment_plans_own → installment_plans_own_or_household,
-- credit_cards_own → credit_cards_own_or_household).
```

**Why this is the highest-risk item in the whole plan:**
1. It changes the *semantics* of every existing `..._own` RLS policy on shared tables from a single-column equality check to an OR-across-two-ownership-modes check — a subtle policy bug here (e.g., a missing `household_id is not null` guard) silently exposes single-user rows to unintended household members, or vice versa breaks legitimate access. This is precisely the class of RLS regression reports/04_swot_verdict.md Threat #5 already flags as a live risk on the *current* single-user schema.
2. It requires Clerk-side multi-user session handling (who is "acting as" the household vs. individual context in a given screen) — this is new product surface, not just schema, and touches auth flows the guardrails say must stay on Clerk as-is; the design must not require a new auth provider, only new Clerk organization/membership metadata mapped into the `household_members` table via a Supabase sync (webhook or client-side upsert on membership change).
3. Every provider in the Finance engine (`bankAccountsProvider`, `debtsProvider`, `creditCardsProvider`, `installmentPlansProvider`, `transactionsProvider`) needs a household-aware read path — `MoneyRepository.instance.getBankAccounts()` would need an optional `householdId` parameter, meaning every existing `AsyncNotifier.build()` in `lib/engines/money/providers/money_providers.dart` gets touched.

**Reversibility / rollback plan (required before this can be scheduled at all):**
- Down-migration: `alter table public.bank_accounts drop column household_id;` (repeat per table) restores the original single-column RLS check exactly, then `drop policy "bank_accounts_own_or_household"` + re-create the original `"bank_accounts_own"` policy from `schema.sql` verbatim. Because `household_id` is nullable and additive, no existing row is mutated by the up-migration, and the down-migration is a pure column/policy drop with zero data loss for single-user rows.
- Staged rollout requirement: ship behind a feature flag (`kHouseholdTierEnabled` in `AppConstants`, same pattern as any other gated feature) so the RLS policy change can be applied to schema in production before any UI exposes household creation — allowing a silent verification window (founder-only household of size 1) before any second real user is invited.
- Migration must be tested against a staging Supabase project with production-shaped data first; per the "preserve founder's live data" guardrail, this is the one change in the entire plan that must NOT be applied directly to the founder's production database without a verified staging rehearsal.

**BLOCKED — needs founder approval (Clerk model):** the Clerk-side organization/membership model to represent a "household" (Clerk Organizations vs. custom metadata) is not decided by this design and must be chosen by the founder before any schema work begins, since it determines whether `household_members` is a mirror of Clerk's own membership object (simpler, but couples schema to Clerk org lifecycle webhooks) or a fully Supabase-native concept Clerk never sees (simpler RLS, but requires manual invite-code UX). Both are valid within the existing Clerk+Supabase stack — neither requires a new library — but the choice changes the shape of the tables above and should not be made unilaterally in this document.

**BLOCKED — needs founder approval (second, independent gap): the RLS model itself deviates from this plan's mandated `user_id = auth.uid()` policy shape.** Every other new table in this document (Sections 3, 5a–5c, 6, 10) uses a single-column `user_id`/`<table>_own` policy of the exact form the redesign guardrails require. `households` and `household_members` have no `user_id` column at all (`owner_user_id`/`member_user_id` instead), and their policies (`households_member`, `household_members_own_row`) plus the retrofitted `*_or_household` policies on all five Finance tables are OR-based, multi-party checks — a structurally different RLS shape, because household sharing is inherently multi-tenant. This is not a naming nitpick: approval for Household tier must explicitly cover this RLS-model deviation as its own line item, separate from and in addition to the Clerk-organization-model question above. The founder is approving two different things: (1) which Clerk membership model to use, and (2) whether to accept a non-standard RLS shape for shared-household rows at all, given that every other table in Monk's schema — before and after this redesign — uses the simple single-owner pattern. If this deviation is not acceptable, Household tier should not be scheduled at all in its current design, and an alternative (e.g., per-row `user_id` retained with a separate read-only "shared view" mechanism) would need to be designed instead.

**Effort: L** (2-3 weeks minimum for Finance-only scope, before any UI). **Dependency order:** strictly last — after (a), (b), (c) have shipped and after the RLS audit foundation phase is fully closed (reports/01_codebase_audit.md §6 action items 1-4), since this migration's safety depends on the *existing* single-user RLS policies being verified correct first. Do not schedule alongside any other schema change in this section.

### Summary table

| Engine | New table(s) | RLS policy | Effort | Depends on |
|---|---|---|---|---|
| Debt Payoff | `payoff_plans`, `payoff_snapshots` | `payoff_plans_own`, `payoff_snapshots_own` (`user_id = auth.uid()`) | M (4–6 days) | RLS/schema audit foundation phase + currency/FX fix (Section 1 items 1 & 5); CSV import (item 7) is a soft/data-quality dependency only, not a hard blocker |
| Assets register | `assets` | `assets_own` (`user_id = auth.uid()`) | M | Debt Payoff (sequencing only, not technical); unsourced design addition, see §5b flag |
| Digital inventory | `digital_accounts` | `digital_accounts_own` (`user_id = auth.uid()`) | S | None (parallel to Assets); unsourced design addition, see §5c flag |
| Household tier | `households`, `household_members` + `household_id` column on 5 Finance tables | New OR-based policies replacing 5 existing `..._own` policies — **structurally non-standard, itself BLOCKED pending approval** | L | (a)+(b)+(c) shipped, RLS audit closed, founder approval on **both** the Clerk membership model **and** the non-standard RLS shape — P2, not immediate |

---

## 6. Retention Loop

### 6.1 Daily Check-in — redesigned for ≤30 seconds

**Evidence for the redesign target.** Report 02 (`reports/02_product_teardown.md` §4, Energy Engine) calls the AM/PM check-in "genuinely useful… combined with the check-in flow it creates a journal-like data set," and report 04 ranks it strength #6 ("no competitor has this 4-resource daily journal model"). But report 02 §3 (Friction Inventory) also flags check-in as "Manual 5-score + text fields — No automation possible — intentional friction," and the current screen (`lib/features/checkin/screens/daily_checkin_screen.dart`) stacks **four full sections** (Energy/Mood, Money note, Time note, Health note), each with a header, a divider, and a free-text `TextField`, before the Save button is reachable — four scroll-heights of friction to reach a button that already has a valid default state. The redesign keeps the differentiator (a daily signal across all 4 resources) but removes typing as the cost of providing it.

**Exact interaction (single screen, no scrolling on a standard phone viewport):**

| Element | Tap targets | Default | Required to submit? |
|---|---|---|---|
| Overall Energy (AM) / Mood (PM) picker | 5 emoji circles (existing 54×68 targets in `_EmojiPicker`, kept as-is — already correctly sized) | Pre-selected at 3/5 (neutral) — this is already `_score = 3` in the current `_DailyCheckinScreenState`, carried forward unchanged | No — Save works with 0 taps here |
| 4 resource quick-tags (Money / Time / Energy / Health) | 4 two-state pill toggles, one tap each: 🟢 On track ↔ 🔴 Off track | All 4 default to 🟢 **On track** | No — this replaces the 4 free-text note fields |
| Optional journal note | 1 collapsed `ExpansionTile`, tap to reveal a single `TextField` (max 2 lines) | Collapsed / empty | No |
| Save | 1 button, always visible without scrolling | — | — |

**Minimum path to completion: 1 tap (Save) — 2–3 seconds.** A user with a normal day taps nothing but Save; the emoji stays at neutral-3 and all 4 resource tags stay "On track." A user flagging a bad day taps the mood emoji (1 tap, ~2s) and any off-track resource pills (1 tap each, ~2s), landing well under the 30-second budget even with all 4 flipped and the mood adjusted (~10s) plus an optional short note if they choose to expand it (adds ~15–20s, still under budget, and entirely opt-in).

**Why each field survived the cut, and what was cut:**

| Field | Kept / Cut | Why |
|---|---|---|
| 1–5 emoji score (energy AM / mood PM) | **Kept, unchanged** | Zero-typing scalar; feeds `avgEnergyProvider` (`lib/engines/checkin/providers/checkin_providers.dart`) and is the input report 04 strength #6 calls the compounding data asset. |
| 4 free-text notes (money/time/health/priority) | **Cut → replaced with 4 binary tags** | The qualitative signal ("how was money today") is now *structured* (on-track/off-track) instead of unstructured prose the user had to compose. Structured data is strictly more useful downstream — the Weekly Review (6.2) can count "3 off-track Money days this week" from a tag but cannot aggregate free text. This directly trades the report 02 friction complaint ("intentional friction," §3) for automatable signal without losing the 4-resource framing that makes this mechanic unique. |
| Optional journal note | **Kept, made opt-in and collapsed** | Preserves the "journal-like data set" value (report 02 §4) for users who want it, without imposing its cost (four `TextField`s, each inviting typing) on the 90% of check-ins that don't need it. |
| "Skip for today" link | **Kept, unchanged** | Already present; zero cost. |

No new Supabase table or column is required — `daily_checkins` already stores per-resource note fields (`morning_money_note`, etc. per `lib/engines/checkin/data/models/checkin_models.dart`); the 4 free-text columns are simply repurposed to store a boolean-as-string (`'on_track'` / `'off_track'`) instead of prose, which is a **column-semantics change, not a schema change** — reversible by treating any pre-existing free-text value as legacy display-only text (down-migration: no `ALTER TABLE` needed, old rows remain readable, new rows just don't reach the free-text branch of the UI).

**AR/EN parity — new strings required:** `checkin.tag.onTrack` ("On track" / "على المسار"), `checkin.tag.offTrack` ("Off track" / "خارج المسار"), `checkin.note.addOptional` ("Add a note (optional)" / "أضف ملاحظة (اختياري)"). All three go into `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` — this is in scope regardless because per report 04 weakness #4, `app_ar.arb` is already 90 lines vs 237 in English, and every new string added here must not widen that gap further.

---

### 6.2 Weekly Review — wins computed automatically, zero new user input

**Mandate.** Report 04 opportunity #3 and handoff item #6 ("shareable weekly report… 6hrs focus, 4/6 habits, EGP 2,400 spent, Money score 72/100") and weakness #5 ("no shareable output / social hook… churn will be high after the novelty period") both point at the same missing screen. The constraint from the brief — no manual logging — is also an architecture constraint: this must be a **Cross-engine provider** (layer 5 of the existing 6-layer hierarchy), not a new engine, since it only *reads* data other engines already collect.

**New file:** `lib/core/providers/weekly_review_provider.dart` (same tier as `resource_scores_provider.dart`, which already composes money/time/energy/health). **New screen:** `lib/features/overview/screens/weekly_review_screen.dart`, routed at `/overview/weekly-review` in `lib/core/router/app_router.dart`, entered from a "This week" card on the Overview screen (`lib/features/overview/screens/overview_screen.dart`).

**Exact provider reads — no new Supabase queries, only re-aggregation of already-cached lists:**

| "Win" shown | Source provider(s) read | Computation (client-side, no DB round-trip) |
|---|---|---|
| Total focus minutes this week | `focusSessionsProvider` (`lib/engines/energy/providers/energy_providers.dart`) | Sum `s.actualMinutes` for sessions where `s.completed` and `s.date` falls in the trailing 7 days — same list already loaded for the Overview 7-day chart (report 04 strength #4). |
| Habits floor days | `habitsProvider` (`lib/engines/health/providers/health_providers.dart`) | For each `Habit`, count `history[date] == true` entries in the trailing 7 days; compare to `floor_per_week` (new field, §6.3) — reuses the same `history` map already fetched for the Habits screen, no new fetch. |
| Money: spend within/under budget | `financeSummaryProvider` inputs — specifically the same `transactionsProvider` list it already watches (`lib/engines/money/providers/money_providers.dart` line 238) | Re-filter the already-loaded transaction list to the trailing 7 days (today's filter, currently `todaySpend`, is generalized to a 7-day window) and reuse the existing `toBase()` FX conversion closure so multi-currency spend is correctly summed — this also piggybacks on the report 04 weakness #5 fix (FX-aware summation) rather than duplicating it. |
| Check-in completion rate + avg mood/energy | `checkinHistoryProvider` and `avgEnergyProvider` (`lib/engines/checkin/providers/checkin_providers.dart`) | `avgEnergyProvider` is already a 7-day average — reused verbatim. Completion rate = count of `checkinHistoryProvider` entries with `hasMorning || hasEvening` in the trailing 7 days ÷ 7. |
| "Best day" resource score | `resourceScoresProvider` logic (`lib/core/providers/resource_scores_provider.dart`), refactored | `resourceScoresProvider` today only computes a live "now" score. It is refactored into a pure function `computeResourceScores({required List<Transaction> txs, required List<BankAccount> banks, ..., required DateTime forDate})` parameterized by date, so the same formula can be replayed against each of the trailing 7 days using data already held in memory by `bankAccountsProvider`, `focusSessionsProvider`, `habitsProvider`, etc. `resourceScoresProvider` itself becomes a one-line call to this function with `forDate: DateTime.now()`, so today's live score on Overview is unaffected. |
| Longest active floor streak (see 6.3) | `habitsProvider` | Max of each habit's `consecutiveFloorWeeks` (new derived field, §6.3). |

**Design constraint honored:** every row above is a *re-read* of a provider that already exists and is already populated for another screen — this is the concrete mechanism by which "wins counted automatically... no manual logging" is satisfied, not just a stated goal. No new table, no new RLS policy, no new write path.

**Output framing** (per report 04 opportunity #3): the screen renders these six wins as a card grid with a "Share" button that composes them into the shareable weekly-image artifact from handoff item #6 — since the review screen already holds exactly the data that card needs, building the review screen first makes the share-card a rendering exercise, not a data exercise.

**AR/EN parity:** `weeklyReview.title`, `.focusMinutes`, `.floorDays`, `.spendThisWeek`, `.bestDay`, `.checkinRate`, `.longestFloorStreak`, `.share` — 8 new keys, both ARB files.

---

### 6.3 Streak → Floor mechanics

**Reframing, per the brief's own language and report 04's churn concern (weakness #5: "churn will be high after the novelty period").** The current model in `habits_screen.dart` / `HabitsNotifier.toggle()` (`lib/engines/health/providers/health_providers.dart`) rewards an unbroken daily chain (`habit.streak`, `habit.longestStreak`, both recalculated from `calculateStreak()` walking backward day-by-day from today). This is a maximal-streak model: one missed day zeroes `streak` back to 0 regardless of history. None of the four audit reports specifically flag this reset behavior as a problem — report 02 §4 in fact says the streak calculation itself "works correctly" — so this redesign's motivation rests on a **named design principle** rather than a report-cited defect: **BJ Fogg's "Tiny Habits" minimum-viable-commitment model** (commit to the smallest version that's hard to fail, rather than a perfect chain that's easy to break), applied here because it is the standard antidote to all-or-nothing streak mechanics in habit-formation literature, combined with the loosely-related churn concern reports/04_swot_verdict.md Weakness #5 raises generally. The floor model replaces "did you do it every single day" with "did you clear your self-set minimum this week" — a preventive redesign choice, not a fix for a report-documented complaint.

**Data model — extends, does not replace, the existing `Habit` model** (`lib/engines/health/data/models/health_models.dart`) and its Supabase table `public.habits` (`supabase/schema.sql` lines 141–156):

```sql
-- Migration (up) — additive only, existing RLS policy already covers it
alter table public.habits
  add column floor_per_week int not null default 3
    check (floor_per_week between 1 and 7);

-- Down-migration (reversible)
alter table public.habits drop column floor_per_week;
-- history, streak, longest_streak, and all existing rows are untouched by either direction.
```

The existing `history` map (`Map<String, bool>`, `'YYYY-MM-DD' -> done`) is **kept exactly as-is** — the daily toggle interaction in `_HabitTile` (`habits_screen.dart` lines 169–184) does not change at all; only its *interpretation* changes. This is the smallest possible change that satisfies the "reversible migration" guardrail: the down-migration drops one column and every other piece of stored history remains valid.

`Habit` gains two **derived, non-persisted** getters (computed client-side from the existing `history` map, no new column needed for these):

```dart
int daysDoneInWeek(DateTime weekStart)  // counts history[date]==true for the 7 days from weekStart
bool get floorMetThisWeek   => daysDoneInWeek(currentWeekStart()) >= floorPerWeek;
int  get consecutiveFloorWeeks; // replaces `streak` as the headline number — counts trailing weeks where daysDoneInWeek >= floorPerWeek
```

`streak`/`longestStreak` columns are **kept in the schema** (no drop) for backward compatibility and because `calculateStreak()` remains useful as a secondary "current daily run" stat shown in small print — but they are demoted from the primary UI number to a subordinate one.

**UI treatment — three states, replacing the single 🔥-streak line in `_HabitTile`:**

| State | Condition | Visual treatment | Color |
|---|---|---|---|
| **Floor met** | `daysDoneInWeek == floorPerWeek` (exactly hit the commitment) | Filled progress ring `X/floorPerWeek`, checkmark badge, label "Floor met this week" | Gold (`AppColors.gold`, `#C8A050`) — reserves gold for "you did what you committed to," consistent with the redesigned accent hierarchy in this plan's design-language section |
| **Floor missed** | Evaluated only at week rollover (Mon 00:00): previous week's `daysDoneInWeek < floorPerWeek` | Small hollow dot in a 4-week history strip (GitHub-contribution-style, not a red X or broken-chain animation) — no shaming copy, label reads "2/3 — still counts" | Neutral `AppColors.textMuted`/border tone, never `AppColors.error` — a missed floor is not an error state |
| **Exceeded floor** | `daysDoneInWeek > floorPerWeek` (mid-week or at close) | Ring fills past 100% with a small "+N" flame badge, label "Exceeded floor (+N)" | Existing green accent (`AppColors.accent`, `#22C55E`) — bonus, distinct from the gold "met" state so over-performing doesn't visually collide with "met exactly" |
| **In progress (live, current week)** | `0 <= daysDoneInWeek < floorPerWeek`, week not yet closed | Partial ring, label "X/floorPerWeek this week" | Gold, partial fill — no red/at-risk coloring; the floor model has no "behind" state, only "not yet met" |

**In-scope cleanup flagged, not executed here:** `_HabitTile` currently colors the "done today" state using `AppColors.deen` (`habits_screen.dart` lines 147, 149, 176–180) — a color identifier literally named after the removed Religion/Deen engine (`AppColors.deen = Color(0xFF54C478)` in `lib/core/theme/app_theme.dart` line 85). No user-facing religion content is exposed by this, but since this section rewrites `_HabitTile`'s state colors directly, the floor-met/exceeded colors above should replace `AppColors.deen` with a neutrally-named token (e.g. `AppColors.floorMet`) at the same time, so no Deen-named identifier survives in the file this section owns.

**Onboarding implication (adjacent, not a new mechanic):** the "Add first habit" onboarding step (report 02 §1, Page 3) should default `floor_per_week` to 3, not 7 — asking a new user to implicitly commit to daily-forever is the same all-or-nothing trap the floor model exists to remove.

**AR/EN parity:** `habit.floorMet` ("Floor met this week" / "تم تحقيق الحد الأدنى هذا الأسبوع"), `habit.floorInProgress` ("{x}/{n} this week" / "{x}/{n} هذا الأسبوع"), `habit.floorExceeded` ("Exceeded floor (+{n})" / "تجاوزت الحد الأدنى (+{n})"), `habit.floorMissedNote` ("Still counts" / "لا يزال يُحتسب"), `habit.setFloor` ("Set your weekly floor" / "حدد حدك الأدنى الأسبوعي") — 5 new keys, both ARB files.

---

## 7. Monetization Surface

### 7.1 Free-tier boundary

The free tier must let a user fully activate the Finance engine — per reports/03_market_analysis.md §5 kill-criteria table, "<30% of users who sign up add at least one bank account" is a kill signal, and per reports/04_swot_verdict.md Strength #1, Egyptian financial modeling (Valu/Sympl/FawryPay/EGP) is Monk's only real moat. Gating Finance entirely, as reports/03_market_analysis.md §3b's freemium sketch floats ("Paid: Finance engine"), would suppress the exact activation metric the report uses to judge product-market fit. The redesign instead paywalls **depth and history**, not **first use**, in every engine — consistent with reports/03_market_analysis.md §3b reason 1 ("users need to experience value before paying").

**Reconciling with report 03 §3b's freemium sketch.** reports/03_market_analysis.md §3b's own candidate list for paid gating names "multi-schedule modes, multi-currency, advanced analytics, export" as things to consider gating. This plan deliberately overrides two of those four for the reasons given inline in the table below — Time schedule modes because report 04 Strength #2 independently names it Monk's other real moat and its stated organic-distribution engine (gating it would break the exact "share your schedule" growth loop report 04 wants doubled down on), and multi-currency FX conversion because it is a correctness fix for a shipped bug (reports/01_codebase_audit.md §3d), not a value-added feature — shipping incorrect net-worth math to free users to force upgrades would compound the trust damage the report already flags. "Advanced analytics" and "export" **are** gated, consistent with report 03 §3b (see the Overview correlation-insights row and the Data-export row below). This is a deliberate, reasoned divergence from two of the four report-suggested candidates, not an oversight — flagged explicitly here the same way the Finance-gating tension is reconciled below.

| Engine / feature | Free limit | Numeric boundary | Evidence / rationale |
|---|---|---|---|
| Finance — bank/wallet accounts (`finance_accounts_screen.dart`) | Limited | **3 accounts** | Covers a typical user's current + savings + one wallet (Vodafone Cash/InstaPay); enough to prove the moat per reports/04_swot_verdict.md Strength #1 without blocking activation (kill criteria, reports/03_market_analysis.md §5) |
| Finance — credit cards (`finance_cards_screen.dart`) | Limited | **1 card** | Egyptians commonly carry 1–2 cards; 1 free proves the APR/statement/due-day model (reports/02_product_teardown.md §4, "more sophisticated than most personal finance apps") |
| Finance — installment plans (`finance_liabilities_screen.dart`) | Limited | **3 active plans** | Debt-payoff segment (reports/03_market_analysis.md §2a Segment 2) is "highest-urgency JTBD" — 3 covers a realistic Valu/Sympl/Contact Finance load without hiding the feature that makes people pay |
| Finance — external debts (`finance_liabilities_screen.dart`) | Limited | **2 entries** | Same rationale as installments; family loans etc. |
| Finance — Debt Freedom calculator (§5a; handoff item #7, reports/04_swot_verdict.md) | **Basic version free** | Single freedom-date number, no scenario comparison | Segment 2 users "pay for debt relief" (reports/03_market_analysis.md §2a) — showing them the number free is the hook; the paid layer (avalanche vs. snowball, "what if I pay X more/month") is the upsell. See §5a for how `debtFreedomDateProvider` and the gated comparison UI implement this split. |
| Finance — transaction history (`finance_transactions_screen.dart`) | Rolling window | **Last 30 days** | Matches existing brand/Free_Pro_Plan_Features.md precedent; older rows render blurred with a lock icon, not deleted |
| Finance — CSV bank-statement import (§3.2; handoff item #2, reports/04_swot_verdict.md) | **Fully free, all supported banks** | Unlimited | This is the #1 activation blocker (reports/02_product_teardown.md §3, reports/04_swot_verdict.md Weakness #1); gating it behind Pro would suppress the exact "≥30% add a bank account" kill metric it exists to fix |
| Multi-currency FX conversion (handoff item #4) | **Fully free, all users** | n/a | Correct net-worth math is an integrity fix, not a premium feature (reports/01_codebase_audit.md §3d bug); shipping wrong numbers to free users to force upgrades would compound the trust damage the report already flags. See reconciliation note above — this overrides report 03 §3b's own suggestion to gate multi-currency. |
| Time — schedule modes (normal/fasting/friday/cairo — secular Egyptian work-week and intermittent-fasting scheduling, see §4.1) | **Fully free, all 4 modes** | n/a | This is Monk's other named moat (reports/04_swot_verdict.md Strength #2) and its stated distribution engine ("when users share a schedule screenshot, this feature becomes distribution"). Paywalling it would break the organic-growth loop the report explicitly wants doubled down on. See reconciliation note above — this overrides report 03 §3b's own suggestion to gate multi-schedule modes. |
| Time — calendar events (`calendar_screen.dart`) | Limited | **50 events** | Existing brand/Free_Pro_Plan_Features.md precedent, retained |
| Time — tasks (`time_tasks_screen.dart`) | Limited | **30 tasks**, no recurring | Recurring tasks + Google Calendar sync are Pro-only depth features |
| Energy — Focus Timer + session history (`focus_screen.dart`) | **Fully free, unlimited** | n/a | Delivers value with zero setup (reports/04_swot_verdict.md Strength #4); the one feature that already works at first use — must stay the frictionless daily hook |
| Energy — Goals (`goals_screen.dart`) | Limited | **5 goals** | Onboarding seeds 4 generic goals (reports/02_product_teardown.md §1) — limit must clear the seed data without immediate lockout |
| Energy — Ideas (`ideas_screen.dart`) | **Fully free, 20 items** | n/a | Ideas is rated 1/5 depth (reports/02_product_teardown.md §4) — it is not a paywall lever; monetizing a weak feature invites refund requests, not revenue. *This limit is defined for whenever the engine is reachable — per Section 9.2 item #2, Ideas is hidden behind `kIdeasEngineEnabled` (default off) pending a tag/link/export uplift, so this row currently applies only to users with the flag enabled (early testers, or users after re-promotion), not to the default cohort.* |
| Health — habits (`health_habits_screen.dart`) | Limited | **7 habits** | Onboarding seeds 6 generic habits (reports/02_product_teardown.md §1) — 7 clears the seed without forcing an immediate delete |
| Health — habit streak history | Rolling window | **Last 30 days**, heatmap locked beyond | Existing brand/Free_Pro_Plan_Features.md precedent |
| Overview — resource-score history + Daily Check-in | **Free**, 7-day sparkline always visible, expandable to a 14-day scrollable trend | Full/unlimited history + correlation insights = Pro | The check-in dataset is Monk's only compounding asset (reports/04_swot_verdict.md Strength #6/Strength #3) — it must accumulate for free so it builds the switching cost reports/03_market_analysis.md §3c says is currently missing; only the *analysis layer* and history beyond 14 days are paywalled. This day-count is defined once, consistently, across §4.2/§7.1/§7.2/§7.3. |
| Shareable weekly resource report (handoff item #6) | **Fully free** | n/a | This is a distribution mechanism, not a revenue lever (reports/04_swot_verdict.md Opportunity #3) — gating it would cut off the founder's lowest-cost acquisition channel (reports/03_market_analysis.md §4b) |
| Assets register — items (§5b, `assets_screen.dart`) | Limited | **5 assets** | New engine; limit clears a realistic starter set (phone, laptop, car, a couple of appliances) without hiding the feature — same "prove the value, don't block activation" logic applied to Finance above |
| Digital account inventory — items (§5c, `digital_inventory_screen.dart`) | Limited | **10 accounts/subscriptions** | New engine; covers a typical user's wallet + subscription count; warranty/renewal alerts (the feature's core hook) work identically at any tier so the utility isn't gutted by the limit |
| Data export | **Limited free**: one-time current-state CSV snapshot, no PDF, no full history | Pro: full historical CSV/PDF across all engines, scheduled export | Reconciles two report findings that pull opposite directions: reports/04_swot_verdict.md Opportunity #6 says export lowers commitment fear; reports/03_market_analysis.md §3c warns "if you can export for free, pricing power collapses." A snapshot satisfies the fear-reduction case while full/historical export remains scarce enough to sell |

### 7.2 What Pro unlocks

| Category | Pro unlock |
|---|---|
| Finance | Unlimited accounts, cards, installment plans, external debts, full transaction history, Debt Freedom advanced projections (avalanche/snowball comparison, payment-scenario simulator — see §5a's free/Pro split), Budget Planner, Bill/subscription tracker, full CSV/PDF export |
| Time | Unlimited calendar events and tasks, recurring tasks, Google Calendar sync, weekly time-by-category report |
| Energy | Unlimited goals, focus analytics (sessions/week trend beyond the always-free 7-day chart) |
| Health | Unlimited habits, unlimited streak/heatmap history, Apple Health/Google Fit sync (mobile only, per reports/02_product_teardown.md §3 platform limitation) |
| Assets / Digital Inventory | Unlimited assets and digital accounts/subscriptions (see §7.1 for the free-tier numeric limits these unlock beyond) |
| Overview | Unlimited resource-score history (beyond the free 14-day view — see §4.2/§7.1 for the consistent day-count definition), correlation insights ("your best week was when Money=80 and you slept before midnight" — directly implements reports/04_swot_verdict.md §2c strength-3 recommendation) |
| Cross-cutting | Full data export (CSV+PDF, all engines, unlimited history), priority support, device sync beyond web (see §7.5 gap on mobile shipping) |

No Pro feature reintroduces Deen/Salah/Quran/Zakat content — the existing brand/Free_Pro_Plan_Features.md draft still lists a "Deen (Religion — opt-in)" pricing table; that section is void per the guardrail and must be deleted from the doc, not ported into this redesign.

### 7.3 Paywall trigger moments (named screens)

| Screen | Trigger | UI treatment |
|---|---|---|
| `finance_accounts_screen.dart` | Tapping "Add Account" on the 4th account | Bottom sheet: "You've connected 3 accounts on Free — Pro unlocks unlimited" + upgrade CTA |
| `finance_cards_screen.dart` | Adding a 2nd credit card | Same pattern |
| `finance_liabilities_screen.dart` | Adding a 4th installment plan / 3rd external debt; opening avalanche/snowball view | Lock icon on "Advanced Payoff Strategy" card (see §5a); tapping opens paywall sheet |
| `finance_transactions_screen.dart` | Scrolling past 30-day boundary | Rows beyond 30 days render blurred with "Unlock full history" banner, not deleted |
| `health_habits_screen.dart` | Adding an 8th habit | Same bottom-sheet pattern |
| `goals_screen.dart` | Adding a 6th goal | Same bottom-sheet pattern |
| `assets_screen.dart` | Adding a 6th asset | Same bottom-sheet pattern |
| `digital_inventory_screen.dart` | Adding an 11th account/subscription | Same bottom-sheet pattern |
| `overview_screen.dart` | Scrolling resource-score chart past 14 days (the free tier's expanded-view boundary, matching §4.2/§7.1); tapping "Correlation Insights" card | Chart clips with fade + lock overlay past day 14; card shows preview blur |
| `profile_settings_screen.dart` / `profile_account_screen.dart` | Always-visible "Upgrade to Pro" row + plan management, restore-purchase, cancel | Canonical entry point, not trigger-only |
| New: `lib/shared/widgets/paywall_sheet.dart` | Reusable bottom-sheet widget invoked by all triggers above | Shows the specific limit hit + link to full comparison |
| New route `Routes.profileUpgrade` (`/profile/upgrade`) | "See all Pro benefits" from any paywall sheet, or direct nav from Profile | Full plan-comparison table + purchase flow (see §7.6 for payment-gateway gap) |

Onboarding (`onboarding_screen.dart`) deliberately has **no paywall moment** — reports/02_product_teardown.md §1 already identifies onboarding as high-friction ("app requires 20 minutes of setup"); stacking a paywall on top of that would compound reports/03_market_analysis.md §3c's warning that casual, not data-committed, users are the default failure mode.

### 7.4 Pricing table (EGP primary, USD equivalent)

Reference FX rate: use the existing `fx_rates_service.dart` live rate at checkout time (do not hardcode a rate — this is the same bug flagged in reports/01_codebase_audit.md §3d for net-worth math, and pricing must not repeat it). Table below uses the reports/03_market_analysis.md reference rate of ~49 EGP/USD (mid-2026, ±10% variance per report's own caveat) purely for display.

| Plan | EGP price | USD equivalent | Basis |
|---|---|---|---|
| **Free** | 0 EGP | $0 | reports/03_market_analysis.md §3b — freemium is correct structure, not paid-only |
| **Pro Monthly (Egypt/EGP-currency users)** | **79 EGP/month** | ≈ $1.60/mo | Within reports/03_market_analysis.md §3a recommended 49–99 EGP/month band |
| **Pro Annual (Egypt/EGP-currency users)** | **499 EGP/year** (≈ 41.6 EGP/mo, ~47% off monthly) | ≈ $10/yr | Within reports/03_market_analysis.md §3a recommended 299–499 EGP/year band |
| **Pro Monthly (non-EGP / diaspora currency selected)** | — | **$3.99/mo** | reports/03_market_analysis.md §3a: "$3–$5/month is defensible" for global/MENA-diaspora audience |
| **Pro Annual (non-EGP / diaspora)** | — | **$34.99/yr** | ~27% discount vs. 12× monthly, consistent with EGP annual discount ratio |

Currency shown is driven by the currency the user selected during onboarding (report 02's onboarding Page 2, "Currency selection, EGP default") — EGP-selected accounts see the EGP price, all other currencies see the USD price.

*Sourcing note:* the pricing band itself (49–99 EGP/month, 299–499 EGP/year, $3–5/month diaspora) is grounded in reports/03_market_analysis.md §3a. The claim below that this supersedes `brand/Marketing_Release_Timeline.md`'s "$5.99/mo or $49/yr" figure, and that `brand/Free_Pro_Plan_Features.md` carries an identical stale figure, references two brand documents outside the four mandated audit reports — included here for internal consistency across Monk's existing planning docs, not as report-cited evidence. Treat the "supersedes" framing below as this plan's own reconciliation judgment, not an audit finding: this directly supersedes the existing `brand/Marketing_Release_Timeline.md` figure of a flat "$5.99/mo or $49/yr" — that number is 3–4× above the market report's Egypt-adjusted willingness-to-pay band (reports/03_market_analysis.md §3a: "$15 = ~750 EGP/month, high barrier") and should be treated as stale. `brand/Free_Pro_Plan_Features.md`'s identical $5.99/$49 figure needs the same correction before beta.

### 7.5 Reconciling with the "100 users then payment plans" plan

reports/03_market_analysis.md §3c stress-tests this plan and finds three specific holes. Each is addressed structurally here, without adding a payment gateway before it's needed:

1. **"No clear upgrade trigger."** §7.1–§7.3 above define the trigger precisely: the moment a user's *real* data — not seed data — crosses a numeric limit (4th real bank account, 31st day of real transactions, 8th real habit). Telemetry should log a `paywall_hit` event per screen/limit from day one of the free-tier rollout, even before checkout exists, so the first 100 users generate the pricing signal reports/03_market_analysis.md §3c says interviews alone may not surface ("100 users provide enough signal to set pricing correctly → possible if interviews are conducted" — hard limit-hit data supplements the interviews).
2. **"Data export as leverage... pricing power collapses if free export is unlimited."** §7.1's limited-snapshot-only free export directly implements this warning while still giving Opportunity #6's commitment-fear reduction.
3. **Sequencing:** limits and paywall UI (locks, blurred rows, upgrade sheets) should ship and be visible to the first 100 users *before* a checkout flow exists — tapping "Upgrade" opens a waitlist/interest-capture form, not a paid transaction, until the payment-gateway decision below is resolved. This matches the existing `brand/Marketing_Release_Timeline.md` Phase 2 note ("Pro plan backend — Stripe integration or manual upgrade for now") and lets the founder validate which limit converts intent before building payment infrastructure.
4. **Retention gap** (reports/03_market_analysis.md §3c: "push notifications exist but not configured to re-engage") is out of scope for this monetization section but should be sequenced *before* checkout goes live — converting a user who already churned is materially harder than converting an engaged free user hitting a limit.
5. **NPS and paid-conversion kill criteria** (reports/03_market_analysis.md §5: NPS <20, paid conversion <5% of engaged free users) are not directly actionable via product design the way the other three holes are, but this section's structure feeds both: the `paywall_hit` telemetry in point 1 above is the direct input to measuring paid-conversion rate once checkout exists, and the non-shaming, non-bait-and-switch design throughout §7.1–§7.3 (free CSV import, free FX correctness, free schedule modes, transparent numeric limits rather than surprise paywalls) is this plan's structural hedge against the NPS risk that aggressive monetization usually creates. Both metrics should be added to the `app_events`-based analytics defined in §10.4 once Pro exists, so they are measured from day one of the paid tier rather than retrofitted.

### 7.6 Schema addition and RLS

New table, additive only (no changes to existing 10 tables in `supabase/schema.sql`):

```sql
create table public.subscriptions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null unique,
  plan text not null default 'free' check (plan in ('free', 'pro_monthly', 'pro_annual')),
  status text not null default 'active' check (status in ('active', 'canceled', 'past_due', 'manual_grant')),
  provider text check (provider in ('stripe', 'paymob', 'apple_iap', 'google_iap', 'manual')),
  external_subscription_id text,
  currency text not null default 'EGP',
  current_period_end timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.subscriptions enable row level security;
create policy "subscriptions_select_own" on public.subscriptions
  for select using (auth.uid() = user_id);
-- No client-side insert/update/delete policy: writes happen only via a
-- service-role-key webhook (payment provider callback), which bypasses RLS
-- by Supabase design. This prevents a user from granting themselves Pro
-- by writing to their own row.
```

Every free-tier user gets an implicit `plan='free'` row created at signup (alongside the existing `_ensureProfile()` call site, consolidated per handoff item #8 to avoid adding a second per-write round trip). A **Layer 5, cross-engine** provider `entitlementProvider` (in `lib/core/providers/`, following the existing `resource_scores_provider.dart` cross-engine pattern — reclassified here from an earlier "Layer 4" label for consistency with how this document classifies `resourceScoresProvider` itself in §4.2 and `debtFreedomDateProvider` in §5a) reads this row plus each engine's live counts across Finance/Time/Energy/Health/Debt-Payoff/Assets/Digital-Inventory to compute per-engine `isLocked` booleans consumed by Layer-6 UI providers driving the paywall sheets in §7.3 — this stays inside the existing 6-layer hierarchy rather than introducing a parallel entitlement system.

**Rollback:** `drop table public.subscriptions;` — fully reversible, no foreign keys point *into* it from other tables, so dropping it cannot cascade-delete founder data in `profiles`, `bank_accounts`, `habits`, etc.

### 7.7 Gap flagged for founder approval

**BLOCKED — needs founder approval: payment processing method.** Neither the guardrails' allowed stack (Flutter/Riverpod/GoRouter/Supabase/Clerk) nor reports/03_market_analysis.md resolves how Egyptian-currency subscriptions are actually charged. Candidates — Paymob (Egyptian card/wallet processor), Fawry, or native Apple/Google in-app purchase — have materially different fee structures, EGP-settlement behavior, and web-vs-mobile availability (the app is web-only today per reports/04_swot_verdict.md Weakness #2, and IAP requires the app-store presence that doesn't exist yet). This is a business/vendor decision, not an architecture change, and is called out here rather than silently defaulted to one option, per the guardrail on flagging blocking gaps explicitly. Until resolved, §7.5's sequencing (ship limits + waitlist-style "Upgrade" CTA first, checkout later) lets monetization surface ship without this decision blocking it.

### 7.8 AR/EN parity for the monetization surface

Every new string introduced by §7.1–§7.7 must ship as a matched key pair in `lib/l10n/app_en.arb`/`app_ar.arb` — this entire section was drafted with English-only example copy for readability, which must not carry through to implementation, especially given that Arabic-string coverage is independently named this product's worst-rated dimension (reports/04_swot_verdict.md Weakness #4). Representative keys required before any paywall UI ships:

| New string | EN key example | Notes |
|---|---|---|
| "You've connected 3 accounts on Free — Pro unlocks unlimited" (and the per-screen variants: cards, installment plans, habits, goals, assets, digital accounts) | `paywall.limit.accounts` / `.cards` / `.installments` / `.habits` / `.goals` / `.assets` / `.digitalAccounts` (each parameterized with the numeric limit) | One parameterized string, reused per-screen via a `{limit}`/`{feature}` placeholder rather than near-duplicate hardcoded literals per screen — reduces translation surface. |
| "Unlock full history" (transaction/habit-heatmap blur banner) | `paywall.unlockHistory` | Shared across Finance transactions and Health streak history. |
| "Advanced Payoff Strategy" lock label | `paywall.advancedPayoffLocked` | |
| Plan-comparison table row labels (`/profile/upgrade`) — one row per Pro-unlock bullet in §7.2 | `plan.compare.<feature>` — one key per row, e.g. `plan.compare.unlimitedAccounts`, `plan.compare.correlationInsights` | Full enumeration deferred to implementation, but no row may ship as a hardcoded literal. |
| Pricing display ("79 EGP/month", "$1.60/mo equivalent") | `plan.price.egpMonthly` / `.egpAnnual` / `.usdMonthly` / `.usdAnnual` (ICU `{price}` argument) | Must use `intl`'s locale-aware `NumberFormat.currency()` for digit shaping and currency-symbol placement — the same fix already flagged for date formatting in §4.2, applied here to prices so digit style isn't hardcoded either (confirm `intl`'s `ar_EG` locale default before assuming Eastern Arabic-Indic vs. Western digits). |
| Free/Pro plan names ("Free", "Pro Monthly", "Pro Annual") | `plan.name.free` / `.proMonthly` / `.proAnnual` | |
| Waitlist/interest-capture form copy (§7.5 point 3, pre-checkout "Upgrade" CTA) | `paywall.waitlist.title` / `.submit` / `.confirmation` | Must exist before the limits/lock-icon UI ships, since §7.5 sequences this ahead of checkout. |

No Pro-tier or paywall string may be hardcoded English in the implementation, per the i18n guardrail — this subsection exists specifically to close the gap flagged against this section during review.

---

## 8. Visual Refresh Spec

### 8.0 Scope and constraint

This is a **token and component re-skin**, not a re-architecture: every value below plugs into the existing `AppColors`, `Spacing`, `AppTheme.dark`/`AppTheme.light`, and shared widgets in `lib/shared/widgets/placeholders.dart` and `app_text_field.dart`. No new widget layer, no new state pattern — evolving within the existing structure (architecture guardrail). Both `AppTheme.dark` and `AppTheme.light` remain fully specified; nothing here removes light-theme support.

One drift is flagged up front because it affects every table that follows: `app_theme.dart` lines 570–593 currently render `headlineLarge/Medium/Small` and `titleLarge` in **Poppins**, not the two-family system (PlayfairDisplay headings + Roboto body) the identity brief specifies. §8.2 corrects this back to two families.

---

### 8.1 Color Token Migration Table

**Approval status of the values below.** The three core hexes — `bg` `#08070C`, `surface` `#0D0B13`, `card` `#12101E` — plus gold `#C8A050` are **given as fixed, non-negotiable constraints by this redesign's own guardrails** (they are the mandated evolution of Monk's palette specified in the brief, not a proposal awaiting founder review), and are treated as already-approved throughout this document — including in Section 1 item 11 and Section 4.2's Resource Pulse/share-card specs, which use them without conditional language for exactly that reason. These fixed hexes are not derived from any of the four audit reports — none of the reports discuss color values — they are supplied directly as a hard constraint by the redesign brief itself, which is their stated origin. Only the **derived secondary tokens** below — `cardHover`, `cardAlt`, `border`, `borderLight` — are this plan's own proposal (continuing the same tint direction the fixed hexes establish) and are open for founder refinement; they do not block Phase A approval or implementation, since work can begin against the fixed core palette and the derived tokens can be adjusted later without a schema or architecture change if the founder wants a different tint.

**Dark theme**

| Token (AppColors constant) | OLD hex | NEW hex | Δ rationale |
|---|---|---|---|
| `bg` | `#0A0A0A` | `#08070C` | Fixed per guardrail. Slightly darker, shifts from neutral gray toward a violet-black undertone (R8 G7 B12 vs R10 G10 B10 equal-channel gray). |
| `surface` | `#111111` | `#0D0B13` | Fixed per guardrail. Continues the tint: +5R/+4G/+7B step from `bg`. |
| `card` | `#1A1A1A` | `#12101E` | Fixed per guardrail. +5R/+5G/+11B step from `surface` — the B-channel grows fastest, so the palette reads as "near-black with a whisper of indigo," not flat gray. |
| `cardHover` | `#222222` | `#171428` *(proposed, open for refinement)* | Continues the same tint progression one step further; used for pressed/hover states on cards and list rows. |
| `cardAlt` (snackbar/tooltip/chip bg) | `#222222` | `#1A1625` *(proposed, open for refinement)* | Sits between `card` and `cardHover`; keeps overlays (snackbar, tooltip) distinguishable from resting cards. |
| `border` | `#2A2A2A` | `#241F33` *(proposed, open for refinement)* | Visible hairline against the darker card without reading as pure gray. |
| `borderLight` (focus rings, stronger dividers) | `#333333` | `#332B47` *(proposed, open for refinement)* | Reserved for focused inputs / active dividers only. |
| `textPrimary` | `#E8E8E8` | `#E8E8E8` *(unchanged)* | Contrast against the new, darker `bg` only improves (see §8.1.1) — no change needed. |
| `textSecondary` | `#888888` | `#888888` *(unchanged)* | Same reasoning. |
| `textMuted` | `#444444` | `#444444` *(unchanged)* | Same reasoning; recheck after final border tone lands since `#444444` sits close to `borderLight`. |
| `accent` (green, primary interactive) | `#22C55E` | `#22C55E` *(unchanged)* | Kept exactly — it is the functional/semantic color (buttons, positive numbers, selected nav state) across every engine; changing it would silently break the "success = green" convention already relied on in `categoryColor()` (`AppColors.dart` line 95, `success = deen` alias). Not touched by this redesign. |
| `accentLight` / `accentDim` / `accentFaint` | `#4ADE80` / `#166534` / `#052E16` | unchanged | No change — same reasoning. |
| `gold` (brand identity accent) | `#C8A050` | `#C8A050` *(unchanged, fixed per guardrail)* | Kept exactly per guardrail. Its **role** is clarified, not its hex: gold stays reserved for logo, milestone markers, and now additionally elevated to the single "hero" number per screen (net worth, overall resource score) — see §8.6. It must **not** replace green as the general interactive color; that division of labor (green = functional/semantic, gold = brand/identity) already exists in code (`app_theme.dart` line 67 comment: "logo / category highlights only") and is preserved. |
| `goldLight` / `goldDim` / `goldFaint` | `#E8C97A` / `#5A4418` / `#2A2010` | unchanged | `goldDim` is currently under-used — see §8.1.1, it should become the mandated gold-on-light-surface text variant. |
| `success` / `error` / `warning` / `info` | `#54C478` / `#E05050` / `#E08840` / `#6A8EF0` | unchanged | Semantic colors are load-bearing across engines (e.g. finance debt = error, focus streak = success); no redesign risk justifies touching them. |

**Light theme** (unchanged — no evidence in the brief or reports calls for a light-theme hex change; listed here for parity as required)

| Token | Light hex | Note |
|---|---|---|
| `lightBg` | `#F8FAFC` | Unchanged. |
| `lightSurface` | `#FFFFFF` | Unchanged. |
| `lightCard` | `#F1F5F9` | Unchanged. |
| `lightCardHover` | `#E8EEF6` | Unchanged. |
| `lightBorder` / `lightBorderStrong` | `#E2E8F0` / `#CBD5E1` | Unchanged. |
| `lightTextPrimary` / `lightTextSecondary` / `lightTextMuted` | `#0F172A` / `#64748B` / `#CBD5E1` | Unchanged. |
| `accent` (green) | `#22C55E` | Same value both themes (unchanged). |
| `gold` | `#C8A050` | Same hex both themes, **but usage rule changes on light** — see §8.1.1. |

#### 8.1.1 Contrast check (qualitative, WCAG relative-luminance method)

Computed against the new dark tokens (relative luminance `L`, contrast ratio `(L1+0.05)/(L2+0.05)`):

| Foreground | Background | Approx. ratio | Verdict |
|---|---|---|---|
| Gold `#C8A050` | new `bg` `#08070C` | ≈8.2:1 | Passes AAA for body text. |
| Gold `#C8A050` | new `card` `#12101E` | ≈7.7:1 | Passes AAA. |
| Green `#22C55E` | new `bg` | ≈8.8:1 | Passes AAA. |
| Green `#22C55E` | new `card` | ≈8.2:1 | Passes AAA. |
| Gold `#C8A050` | light `lightSurface` `#FFFFFF` | ≈2.4:1 | **Fails AA for text.** Raw gold reads as a mid-tone on white and must not be used as light-theme text color. |
| `goldDim` `#5A4418` | light `lightSurface` | ≈9.2:1 | Passes AAA — this is the correct light-theme substitute for gold-as-text. |

**Rule to add to the design system:** on dark theme, raw `gold` is safe for text, icons, and fills. On light theme, raw `gold` is fill/icon/border only (chips, category dots, progress rings) — any gold **text** on light theme must use `goldDim`. This rule does not exist today (`goldDim` is defined in `app_theme.dart` lines 68–71 but nothing in the codebase currently enforces when to use it over `gold`); it should be encoded as a themed `AppColors.goldOnSurface(BuildContext)` helper rather than left to each screen to remember.

The new dark `card` (`#12101E`, L≈0.0059) is measurably darker than the old `card` (`#1A1A1A`, L≈0.0103) — roughly 57% of the old luminance. Any low-alpha tint built on `withValues(alpha: 0.08)` (e.g. `categoryBg()` in `app_theme.dart` line 137, used for category chips across Time/Health) will read fainter against the darker card. Recommend raising the category-tint alpha from **0.08 → 0.10–0.12** to preserve the same perceived presence — a one-line change to `categoryBg()`, no new token needed.

---

### 8.2 Type Scale Table

Corrects the Poppins drift (`app_theme.dart` lines 570–593) back to the two declared families. PlayfairDisplay is not used below ~20px — serif display faces lose their distinguishing character and legibility at small sizes, so H3-and-below moves to Roboto. This also matters for AR parity: **PlayfairDisplay has no Arabic glyph coverage**, so any Arabic string rendered in a Playfair-assigned style silently falls back to the platform default font today — a real risk given report 01's i18n rating (2/5) already flags Arabic as navigation-labels-only. The redesign must either (a) source an Arabic-supporting display serif to pair with PlayfairDisplay at the Display/H1/H2 tiers (an asset addition, not a new library/dependency), or (b) fall back to a bold Roboto/Noto Sans Arabic weight for AR headings so Arabic text doesn't silently drop to an unstyled system font. This decision needs founder sign-off before implementation — **flagging as BLOCKED — needs founder approval** for which Arabic display face to license/bundle.

| Level | Font (EN) | Font (AR — pending approval above) | Size | Weight | Maps to `TextTheme` slot | Used for |
|---|---|---|---|---|---|---|
| Display | PlayfairDisplay | TBD Arabic serif / Roboto Bold fallback | 40 | 900 | `displayLarge` (unchanged) | Onboarding hero headline, hero numeric (e.g. overall resource score on Overview) |
| H1 | PlayfairDisplay | same as above | 28 | 700 | `displayMedium`/`headlineLarge` merged — replaces current Poppins 24/700 `headlineLarge` used by `ScreenHeader` | Screen titles (`ScreenHeader.title`), AppBar/dialog titles |
| H2 | PlayfairDisplay | same as above | 20 | 700 | `headlineMedium` — font changed from Poppins, size unchanged | Section group titles inside a screen (e.g. "Accounts", "This Week") |
| H3 | Roboto | Roboto/Noto Sans Arabic | 16 | 600 | `titleLarge` — font changed from Poppins, consolidating former `headlineSmall`(18) into this one 16px slot | Card titles, sub-headers, `StatCard` value labels |
| Body | Roboto | Roboto/Noto Sans Arabic | 14 | 400 | `bodyLarge` (unchanged) | Primary reading text, form values |
| Body (dense) | Roboto | Roboto/Noto Sans Arabic | 12 | 400 | `bodyMedium` (unchanged) | List item subtitles, secondary numbers |
| Caption | Roboto | Roboto/Noto Sans Arabic | 11 | 400/500 | `bodySmall`/`labelSmall` (unchanged) | Metadata, timestamps, `SectionHeader` uppercase labels |

`titleMedium`/`titleSmall`/`labelMedium` retain current sizes (13/11/10) unchanged — they were already Roboto by omission and need no font migration, only the color-token updates in §8.1.

---

### 8.3 Spacing Grid

The existing 4px grid in `Spacing` (`app_theme.dart` lines 8–27) is confirmed as-is: `xs 4 / sm 8 / md 12 / base 16 / lg 20 / xl 28 / xxl 40`. It is already consistently applied (`Spacing.cardPadding`, `Spacing.pagePadding(context)`) and needs no structural change. Two additions, both purely additive (no renumbering, no breaking existing call sites):

| New token | Value | Purpose |
|---|---|---|
| `Spacing.hairline` | 2 | Tight gaps in dense numeric tables (Finance transaction rows, Time schedule blocks) where `xs` (4) is visually too loose between a value and its trend arrow. |
| `Spacing.section` | 48 | Whitespace between major screen sections (e.g. between the Overview KPI grid and the resource-score row) — currently screens improvise with `Gap(Spacing.xxl)` or raw `SizedBox(height: 32)`, which is inconsistent. |

`Breakpoints` (mobile 480 / tablet 768 / desktop 1200) is unchanged — no report flags responsive layout as a problem area.

---

### 8.4 Component State Matrix

All four components already exist in `lib/shared/widgets/` — this re-skins them onto the new tokens, it does not create new widgets.

| Component | Loading | Error | Empty | Success/default |
|---|---|---|---|---|
| **`StatCard`** (`placeholders.dart` lines 94–199) | Value text replaced by a 60×16 shimmer bar in `cardHover` tone; label/icon stay static (avoid full-card skeleton flash on every rebuild) | Value renders `"—"` in `textMuted`, icon recolors to `error` at 60% opacity, no crash-prone re-render of the trend row | Value renders `"—"`, subtitle becomes an inline "Add data" text link in `gold` (ties first-touch CTA to the brand color) instead of today's blank/zero display (report 02 §2: Finance overview "shows 0 net worth… offers no add-your-first-account prompt") | `border` at rest; on hover/press `cardHover` background + `borderLight` border; trend arrow uses `success`/`error` per direction (unchanged behavior) |
| **List item** (`PlaceholderListItem`/`_PlaceholderListTile`, lines 380–490) | Icon chip renders as a plain `cardHover`-colored circle (no icon), title/subtitle as two shimmer bars | Trailing value replaced with a small `error`-colored retry icon (tap re-fetches) — today errors here are silent | Container swaps to a full-width dashed-border (`border`, 1px, dashed) card with a centered `gold` "+" icon and one line of body text — replaces the bare "No habits yet" / "No active goals" text with no CTA (report 01 §2b; report 02 §2) | Standard `card` background, `border` divider between rows (unchanged) |
| **Form field** (`AppTextField`, `app_text_field.dart`) | Disabled state (`enabled: false`) dims label + border to `textMuted`/`border` at 50% opacity, no spinner inside a text field (avoid layout shift) | `errorBorder`/`focusedErrorBorder` already exist in `inputDecorationTheme` (lines 186–193) — reuse them; add an inline `error`-colored helper line under the field (currently only the border changes color, no message shown, per report 01 §2b's note that error handling is minimal) | N/A (fields don't have an empty *state* distinct from unfilled) | `focusedBorder` in `accent` (green) at 1.5px — unchanged; label uses `textSecondary`/`lightTextSecondary` per theme |
| **Primary button** (`ElevatedButton` theme, lines 200–213) | Label replaced by a 16×16 `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)`, button stays `accent`-colored and disabled to prevent double-submit (today several write actions, e.g. habit toggle per report 01 §2a, have no loading guard at all) | On failure, button briefly (1.5s) swaps fill to `error` with a shake microinteraction, then reverts to `accent` — surfaces write failures that are currently silent | N/A | `accent` fill, white text, unchanged |

---

### 8.5 Motion Guidelines

*Sourcing note:* the duration/easing values in the table below (120ms, 180–200ms, 260–300ms, 220ms, etc.) are standard UI-motion judgment calls by the plan-writer, following common Material-motion conventions — no report or brief specifies exact millisecond values, so treat these as a reasonable working default open to founder/design refinement, not a cited requirement. The one row in this table that *is* report-grounded is the "no animation on financial values" rule, cited inline to report 04's verdict and report 03's competitive contrast — note the difference in evidentiary weight between that row and the others.

| Motion | Duration | Easing | Rule |
|---|---|---|---|
| Micro (checkbox/switch toggle, chip select) | 120ms | `Curves.easeOut` | Snap-adjacent; state must be visually settled before the next frame of user input is likely. |
| Standard (card hover/press, button press) | 180–200ms | `Curves.easeOut` | Applies to `cardHover`/`border` transitions in §8.4. |
| Entrance (empty-state CTA appearing, checklist item completing) | 260–300ms | `Curves.easeOutCubic` | Slight overshoot-free ease-out; used for the new empty-state CTA card fading/scaling in. |
| Page/onboarding transition | 350ms | `Curves.easeInOut` | **Keep as-is** — already implemented in `onboarding_screen.dart` line 61 (`Duration(milliseconds: 350)`, `Curves.easeInOut`); no reason to diverge from an existing, working value. |
| Financial/numeric value changes (net worth, balances, scores) | **0 — no animation** | n/a | Numbers must snap to their new value, not count up or tween. Animating financial figures reads as gimmicky for a tool whose core promise is trustworthy data (report 04 verdict: Monk's moat is being taken seriously as a financial/mastery tool, not a gamified app like Habitica/Finch, per report 03 §1a/1c competitive contrast). *This row is report-grounded; the other rows in this table are not — see the sourcing note above.* |
| Loading spinners | continuous, linear | n/a | No easing — constant-speed rotation only, per Material convention already in use (`CircularProgressIndicator(strokeWidth: 2)`, report 01 §2b). |
| List reordering / item removal (habit delete, transaction delete) | 220ms | `Curves.easeInOut` | Animates position/opacity; the underlying data write itself is not gatedon the animation finishing. |

---

### 8.6 Before / After — Five Most-Seen Screens

**Overview** (`lib/features/overview/screens/overview_screen.dart`)
*Before:* Flat near-black `#0A0A0A`/`#111111`/`#1A1A1A` stack; page title "Overview" rendered in Poppins via `headlineLarge`; Getting-Started checklist and resource-score cards (`_ResourceScoreCard`, `_PillarScoreCard`) share the same `card`/`cardHover` gray with no visual hierarchy beyond position on screen; overall resource score number rendered same weight/color as the four individual pillar scores.
*After:* Violet-tinted `#08070C`/`#0D0B13`/`#12101E` progression gives the three depth layers a hue step in addition to a lightness step, which reads more distinctly at near-black luminance than a lightness-only gray scale (per §8.1.1's luminance deltas). "Overview" title renders in PlayfairDisplay H1 (28/700), matching the AppBar/dialog titles that already use Playfair — closing a current inconsistency where the on-screen `ScreenHeader` and the AppBar disagree on font. The single overall resource score (report 04 strength #3: "Monk's only data asset that compounds over time") gets a `gold`-ringed treatment distinct from the four green/semantic pillar sub-scores, visually promoting it to "the number that matters most today" rather than a fifth peer stat.

**Finance Accounts** (`lib/features/finance/screens/finance_accounts_screen.dart`)
*Before:* Net worth/balance `StatCard`s and the account list share identical `card`/`border` styling with no visual hierarchy; first-run empty state is a flat "0 net worth" with no CTA (report 02 §2, "offers no add-your-first-account prompt" — the report's identified #1 abandon point, report 02 §1 and report 04 weakness #1).
*After:* Same components, re-skinned per §8.1/§8.4: the net-worth `StatCard` gets a 1px `gold` border at 24% opacity to anchor it as the screen's hero stat (mirroring the `trendUp`/`trendUp==false` green/red convention already coded into `StatCard`, lines 174–191). The empty account list swaps to the new dashed-border + gold "+" empty-state treatment from §8.4, closing the exact gap report 02 names — this is a visual fix only; it does not touch the underlying CSV-import gap, which belongs to a different section of this plan.

**Time Schedule** (`lib/features/time/screens/time_overview_screen.dart`)
*Before:* Category-colored blocks (`learn`/`project`/`health`/`work`/`fasting`/`commute`/`rest`, all fixed hex in `categoryColor()`) sit on `categoryBg()` tints computed at a flat 8% alpha against the old, lighter `card` (`#1A1A1A`, since superseded).
*After:* Same fixed category hexes (unchanged — report 04 strength #2 calls the schedule-modes feature a genuine moat; nothing about its color coding is broken), but `categoryBg()` alpha raised to ~10–12% per §8.1.1 so the same visual weight survives against the new, darker card tone — a one-line change, not a redesign of the category system.

**Health Habits** (`lib/features/habits/screens/habits_screen.dart`)
*Before:* Loading state hardcodes `AppColors.gold` inline (line 52) and error state hardcodes `AppColors.error` inline (line 53) rather than going through `Theme.of(context)` — meaning this screen does not automatically pick up light/dark theme changes the way `StatCard`/`SectionCard` do. This is exactly the kind of drift that makes a token migration risky: some screens read theme tokens, others hold literal `AppColors` references.
*After:* Habit rows adopt the re-skinned list-item component from §8.4 (icon chip, streak badge, dashed-border empty state for "no habits yet" — replacing today's bare text with no CTA, report 01 §2b). As part of this pass, the two hardcoded `AppColors.gold`/`AppColors.error` literals in `habits_screen.dart` should be replaced with themed references (`Theme.of(context).colorScheme.primary`/`error`) so this screen actually inherits future palette changes instead of needing a manual edit every time — a small correctness fix riding along with the visual pass, not a separate engineering project. (Note: `lib/features/health/screens/health_screen.dart`, the dead "Health tracking coming soon" placeholder identified in report 01 §2b, is out of scope for this visual section — its removal belongs in the feature/cleanup section of this plan, not a re-skin.)

**Onboarding** (`lib/features/onboarding/screens/onboarding_screen.dart`)
*Before:* Page background is the old flat `#0A0A0A`; Page 0's "four resources" intro and the habit-suggestion pills (lines 38–45) use ad hoc `Container` decorations rather than the shared card/border tokens; CTA button still reads "Open PRP 🚀" (branding debt tracked separately, report 01 §1/§4 weakness #8).
*After:* Background moves to `#08070C`→`#0D0B13` progression; Page 0's four resource icons (Money/Time/Energy/Health) sit on a subtle `gold`-tinted radial glow to establish gold as the app's identity color from the very first screen the user sees, before any functional (green) UI appears. Habit-suggestion pills, when selected, switch from a generic `cardHover` gray fill to a `gold` border + `goldFaint` fill — visually tying the very first piece of user data entered (their first habit) to the brand color rather than the functional green used everywhere else. Welcome headline promotes to Display tier (40/900 PlayfairDisplay) instead of an unstyled ad hoc `TextStyle`. Page-transition timing (350ms `easeInOut`) is unchanged per §8.5.

**Coverage note for Section 5's new screens.** Debt Payoff, Assets, Digital Inventory, and (if ever built) Household screens are not separately profiled above because Section 8 is a token/component re-skin, not a per-screen redesign (§8.0) — every new screen in Section 5 is built from the same re-skinned `StatCard`/list-item/form-field/button components and the same color/type/spacing tokens specified in §8.1–§8.5 by construction, since the architecture guardrail requires them to reuse existing shared widgets rather than introduce new ones. There is nothing screen-specific to spec for these four surfaces beyond what §8.1–§8.5 already define; if implementation reveals a genuine one-off need (e.g., the payoff-strategy comparison chart), it should be re-skinned against these same tokens rather than inventing a new visual language.

---

## 9. Cut List

Every row below is a screen, engine, or content surface evaluated for removal, hiding, or confirmed retention. Decisions stay inside the existing engine folder structure (`lib/engines/<name>/`, `lib/features/<name>/screens/`) — nothing here proposes a new module boundary, and any "hide" mechanism is a plain Riverpod bool provider + GoRouter redirect guard, not a new library. This section has five decision items: the religion-related cleanup is split into a full-engine removal (item #4, cross-referenced with Section 1) and a narrower residual-keys cleanup (item #5) that persists even after the full engine is gone.

### 9.1 Decision Table

| # | Feature / Screen | File(s) | Decision | Justification (cited) |
|---|---|---|---|---|
| 1 | Health tab placeholder | `lib/features/health/screens/health_screen.dart` | **REMOVE** | reports/01_codebase_audit.md §2b: "One dead screen found... unreachable in normal navigation but wastes compilation." reports/02_product_teardown.md §4 Health Engine: "dead file saying 'Health tracking coming soon' — contradicts the multiple working sub-screens. Should be deleted." Confirmed against `lib/core/router/app_router.dart` lines 311-340: the Health tab route (`Routes.healthOverview`) builds `HealthOverviewScreen`, never `HealthScreen` — this file has zero inbound navigation. |
| 2 | Ideas engine (nav placement) | `lib/engines/ideas/`, `lib/features/ideas/screens/ideas_screen.dart`, `ideas` Supabase table, `/energy/ideas` route | **HIDE-BEHIND-FLAG** (code + table kept, removed from primary nav) | reports/02_product_teardown.md §4: "Superior alternatives exist at zero cost: Apple Notes, Google Keep, Notion free tier. Monk needs to justify why you'd capture ideas here instead of those." reports/04_swot_verdict.md Weakness #7: "Ideas engine has no processing path... near-zero user value." |
| 3 | Health sub-screens (fasting, habits, body, nutrition, exercise) | `lib/features/health/screens/health_fasting_screen.dart`, `health_habits_screen.dart`, `health_body_screen.dart`, `health_nutrition_screen.dart`, `health_exercise_screen.dart` | **KEEP** | reports/02_product_teardown.md §4: these are functional, routed, backed by real tables (`fasting_records`, `mood_entries`, `body_profiles`, `weight_entries`, `calorie_entries`, `exercise_entries` — reports/01_codebase_audit.md §3a). Distinct from item #1's dead wrapper; cutting them would destroy the fasting-timer strength called out in reports/04_swot_verdict.md Strength #2 — see §4.1's note on describing this feature in strictly secular terms. |
| 4 | Full Religion/Deen engine (Salah, Quran, Zakat) — routed, implemented, and shipped | `lib/engines/religion/`, `lib/features/religion/`, routes at `app_router.dart` lines 46–51/355–372, shell-nav tab, `kToggleablePillars` entry | **REMOVE** (fully specified in Section 1, item 4 — restated here only for cut-list completeness, not as a separate decision) | reports/01_codebase_audit.md §1 ("Religion engine fully present in Monk codebase... contradicts stated strategy"); reports/02_product_teardown.md §4 ("The Deen tab (Salah, Quran, Zakat) is fully routed, implemented, and shipped to the web at `/deen/*`"); reports/04_swot_verdict.md Weakness #3 ("routed, implemented, and visible in the shell navigation"). Religion-related Supabase tables are marked deprecated, not dropped, per Section 1 item 4's reversibility treatment. |
| 5 | Residual religion-adjacent category/event-type keys (narrower than item #4 — picker-option strings, not the Deen tab itself) | `lib/core/constants/app_constants.dart` lines 42-45 (`categoryKeys: 'deen'`), lines 48-52 (`eventTypeKeys: 'islamic', 'quran'`), line 123 (`categoryInfoMap['deen']`), `lib/core/theme/app_theme.dart` line 85 (`AppColors.deen`) | **HIDE/RENAME** | Guardrail: never re-add Deen/Quran/Islamic content. Even after the full Deen tab (item #4) is removed, these string keys independently surface "Deen" 🕌 and "Quran" as selectable options in every category/event-type picker (Schedule, Calendar, Time Tasks) — a second, separate surface area that must be cleaned up in the same pass, which is exactly the positioning confusion reports/04_swot_verdict.md Weakness #3 warns about. |

### 9.2 Item Detail, Data Impact, and Migration Path

**#1 — Health placeholder screen: REMOVE**
- Data/table impact: none. `HealthScreen` is a `StatelessWidget` with no repository, no provider, no Supabase table reference — it renders static copy only.
- Migration path: delete the file and its import; no down-migration needed since no persisted state depends on it. Zero rollback risk.

**#2 — Ideas engine: HIDE-BEHIND-FLAG, not full removal**
- Why not straight REMOVE: `lib/engines/ideas/data/models/idea_models.dart` already has `status` (backlog/thinking/active/done) and `tags: List<String>` fields in the model — the shallowness reports/02_product_teardown.md flags ("no tagging," "no linking to goals," "no export") is a missing-UI problem, not a missing-architecture problem. Deleting a working table + repository to fix a UI gap is not proportionate.
- Why not straight KEEP: reports/04_swot_verdict.md Weakness #7 is explicit that current dev time on this surface returns near-zero value versus free alternatives.
- Decision mechanics: add a `kIdeasEngineEnabled` bool (Layer-6 UI provider, per the existing 6-layer hierarchy) defaulting to `false`; gate the shell-nav entry point and the `/energy/ideas` route redirect on it; remove Ideas as the default target of `quick_capture_fab.dart` (see §2c for the corresponding note on what the FAB's new default target becomes). No new state/routing library — this is a plain Riverpod provider + existing GoRouter `redirect`.
- Re-promotion bar: only flip the flag back on after tag-filter UI, goal-linking, and CSV/text export ship (reports/04_swot_verdict.md Opportunity #6). If not resourced within two release cycles, escalate to full REMOVE.
- Interaction with other sections: §2c's Empty-State Spec Table and §7.1's free-tier limit both still describe Ideas' behavior, scoped explicitly to apply only while the flag is enabled — see the notes in those sections rather than re-describing them here.
- **RLS gap that must be fixed regardless of hide/remove**: reports/01_codebase_audit.md §3a lists `ideas` as a table the app queries (`lib/engines/ideas/data/repositories/ideas_repository.dart`) that is **absent from `supabase/schema.sql`** — its RLS status is unknown. Hiding the nav entry does not protect the Supabase REST endpoint. Before shipping the hide: add to schema.sql —
  ```sql
  create table public.ideas (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id),
    title text not null,
    description text,
    status text not null default 'backlog',
    tags text[] not null default '{}',
    created_at timestamptz not null default now()
  );
  alter table public.ideas enable row level security;
  create policy ideas_own on public.ideas
    using (user_id = auth.uid()) with check (user_id = auth.uid());
  ```
  Down-migration: `drop policy ideas_own on public.ideas;` **only** — this documentation migration must never drop the table itself, because (unlike a genuinely new table) `ideas` is an already-live production table per reports/01_codebase_audit.md §3a, and `DROP TABLE` would permanently destroy real user data. *This corrects an earlier drafting error in this document, which previously proposed `alter table public.ideas disable row level security; drop table public.ideas;` as part of a "reversible" rollback — that was false: dropping a live table is not a safe rollback under any label, and it directly contradicted this same document's own Section 1 item 1, which correctly models the identical situation for the same 12 tables (drop only the newly-added policy, never the table).* If `ideas` was not already RLS-enabled before this migration, the down-migration also reverts `enable row level security` to whatever its prior state was — but never a table drop.
- If the engine is later fully cut: do not `DROP TABLE`. Rename instead — `alter table public.ideas rename to ideas_archived_<date>;` — preserving every user's captured ideas and allowing instant rollback (`rename to ideas`) if the decision is reversed. Founder's live data is never destroyed in a single step, per the reversibility guardrail.

**#3 — Health sub-screens: KEEP, explicit**
- No cut action. Flagged here only to prevent the "Health Engine — Shallow: 2/5" rating in reports/02_product_teardown.md §4 from being misread as a cut signal — the shallowness there is about manual-entry friction (a "deepen" item), not about screens that duplicate a free alternative. Out of scope for this list.
- Same RLS-documentation treatment as #2 applies — and the same correction: `mood_entries`, `body_profiles`, `weight_entries`, `calorie_entries`, `exercise_entries`, `fasting_records` are all missing from `schema.sql` per reports/01_codebase_audit.md §3a, and each needs the identical create-table-documentation migration with a **policy-only down-migration** (never `DROP TABLE`, since these are already-live tables holding real user health data — the same non-destructive pattern corrected in #2 above applies to all six). This is a data-layer fix, not a cut, but should be resolved in the same schema-hardening pass as #2 since both stem from the same audit finding.

**#4 — Full Religion/Deen engine: REMOVE**
- This item is specified in full in Section 1 (item 4): delete `lib/features/religion/`, `lib/engines/religion/`, remove the routes and shell-nav tab, drop from `kToggleablePillars`. It is restated in this cut list only so Section 9's decision table is a complete inventory of every screen/engine touched by a cut decision — the authoritative implementation detail (including the "mark deprecated, don't drop" treatment for any underlying Salah/Quran/Zakat Supabase tables) lives in Section 1 to avoid two divergent specs for the same change.
- Correction to an earlier drafting error: this document previously stated in this location that "the full Deen tab is confirmed already gone... as of this audit" — that claim directly contradicted reports/01_codebase_audit.md §1, reports/02_product_teardown.md §4, and reports/04_swot_verdict.md Weakness #3, all of which describe the Deen tab as currently routed, implemented, and shipped, and it contradicted this same document's own Section 1 item 4, which treats the deletion as still-to-do work. That claim has been removed; the religion engine is treated consistently across this entire document as present-and-needing-removal, not already-removed.

**#5 — Residual religion-tagged keys: HIDE/RENAME**
- Distinguish carefully: the `schedule_modes` list (`normal`, `fasting`, `friday`, `cairo` — `lib/core/constants/app_constants.dart` line 39, `supabase/schema.sql` check constraint) is **KEPT** — it is the secular time-of-day scheduling strength named in reports/04_swot_verdict.md Strength #2 and must not be touched (see §4.1's note on describing it in strictly secular product-facing language). The cut here is narrower: the `category` key `'deen'` and `event_type` keys `'islamic'`/`'quran'` are selectable labels in pickers, not scheduling logic.
- Action: rename `categoryKeys: 'deen'` → a neutral key (e.g. `'personal'`), drop `'islamic'` and `'quran'` from `eventTypeKeys`, remove the corresponding `categoryInfoMap`/`EventTypeInfo` entries and the `AppColors.deen` → generic accent mapping in `app_theme.dart` line 116.
- Migration path (reversible): existing rows in `schedule_blocks.category` or `calendar_events.event_type` that hold these string values must be remapped, not silently orphaned —
  ```sql
  update public.schedule_blocks set category = 'personal' where category = 'deen';
  update public.calendar_events set event_type = 'personal' where event_type in ('islamic', 'quran');
  ```
  Down-migration: run the remap inside a transaction that first copies affected row IDs to a temporary `category_migration_202607` table (`id`, `old_value`), so a revert is a single `update ... set category = old_value from category_migration_202607 where id = ...` — no data loss, fully reversible per the founder-data guardrail.
- AR/EN parity note: since the neutral replacement label ("Personal"/"شخصي") is a net-new user-facing string, it must ship in both `app_ar.arb` and `app_en.arb` in the same commit, not hardcoded — closing rather than reopening the i18n gap flagged in reports/01_codebase_audit.md §2e.

### 9.3 Effort / Impact / Dependency

| Item | Effort | Impact if executed | Blocking dependency |
|---|---|---|---|
| #1 Remove dead Health screen | Trivial (delete 1 file + import) | Low functional impact, removes maintenance/compile confusion per reports/01_codebase_audit.md §2b | None |
| #2 Hide Ideas engine + fix its RLS | Small (flag + nav gate: ~0.5 day) + Small (schema.sql RLS patch: ~0.5 day, blocking) | Medium — removes a nav item reports/02_product_teardown.md flags as an early-abandon point ("Why not just use Notes or Notion?") without discarding user data or the model's existing status/tags fields | RLS patch must land before or with the flag flip — hiding nav does not close the open Supabase endpoint |
| #3 No action (Health sub-screens) | None | N/A — confirmed keep | Same RLS documentation debt as #2, tracked separately as a data-layer fix, not a cut |
| #4 Remove full Religion/Deen engine | See Section 1 item 4 (S) | High — closes the single largest guardrail-conflict surface in the shipped app | None (independent, can be pulled forward opportunistically per Section 1's critical-path note) |
| #5 Rename residual religion-tagged keys | Small (const rename + 2 SQL updates + 2 ARB entries: ~1 day) | Medium — closes the last surface area tied to reports/04_swot_verdict.md Weakness #3 even though the full Deen tab/engine (item #4) may already be scheduled separately | Must ship together with AR/EN string pair for the replacement label; must not touch `schedule_modes` (Strength #2); should ship in the same pass as #4 |

---

## 10. Release Plan

### 10.0 Starting point (what actually exists today)

Two facts change the shape of this section versus a greenfield CI/CD proposal — both flagged here with explicit verification status rather than asserted as settled:

- reports/01_codebase_audit.md §4b states: *"No CI/CD in place. Web deploy is manual... DEPLOYMENT.md provides a GitHub Actions example but it is not wired up."* This plan flags an unresolved discrepancy rather than asserting a counter-claim as settled fact: at the time this section was drafted, a `.github/workflows/deploy.yml` file appeared present in the repository, running `analyze` → `build web` → conditional Vercel preview/prod deploy on push/PR to `main` — but this observation is not independently verifiable against the four audit reports and is not backed by the same file:line citation discipline used elsewhere in this document. **Before Phase B begins, the founder/engineering lead must confirm which is true** (listed in the Approval Checklist below). This section's design is written to work under either outcome: if `deploy.yml` genuinely does not exist or does not do what's described, treat every job in §10.2 as new work to author from scratch against report 01's stated baseline (no CI/CD, DEPLOYMENT.md example unwired); if it does exist substantially as described, treat those jobs as the incremental extension described below — **no test job, no Windows artifact job, no version pinning, and no Supabase/Clerk secret injection** (the app still reads credentials from `lib/core/constants/app_constants.dart` as hardcoded string literals, confirmed at lines 10–14: `supabaseUrl`, `supabaseAnonKey`, `clerkPublishableKey`). Either path lands at the same end state specified in §10.2.
- `pubspec.yaml`'s `version: 4.1.0+1` matches the version cited in reports/01_codebase_audit.md's own header. The additional claim that `AppConstants.appVersion` is separately hardcoded to a disagreeing value (`'4.9.0'`, app_constants.dart line 6) does not appear in any of the four audit reports and is flagged here as **the plan-writer's own direct repo spot-check, not a report citation** — worth confirming before Phase B, since the motivating example for §10.3's versioning scheme rests on these two values genuinely disagreeing today. If confirmed, it is a second source-of-truth problem the versioning scheme below eliminates; if not confirmed (e.g., if `appVersion` was already correctly derived), §10.3 still stands on its own merits as the correct pattern going forward, just without this specific drift as its motivating example.

### 10.1 Secret extraction (prerequisite — blocks everything else in this section)

Per report 01 §4a, credentials are hardcoded in source control. Before any CI workflow can be trusted, `AppConstants` must read from compile-time environment injection, not literals:

```dart
// lib/core/constants/app_constants.dart
static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
static const clerkPublishableKey = String.fromEnvironment('CLERK_PUBLISHABLE_KEY', defaultValue: '');
```

Local dev keeps working via a git-ignored `.env.local` → `--dart-define-from-file=.env.local` (documented in DEPLOYMENT.md, not committed). This is a Dart-language compile flag, not a new library — no guardrail violated.

**GitHub Secrets to create** (repo Settings → Secrets and variables → Actions):

| Secret name | Used by job | Replaces |
|---|---|---|
| `SUPABASE_URL` | build-web, build-windows | `app_constants.dart` line 10 literal |
| `SUPABASE_ANON_KEY` | build-web, build-windows | `app_constants.dart` line 11 literal |
| `CLERK_PUBLISHABLE_KEY` | build-web, build-windows | `app_constants.dart` line 14 literal |
| `VERCEL_TOKEN` | deploy-web | already referenced in existing `deploy.yml` line 32/39 (pending the verification flagged in §10.0) |
| `VERCEL_ORG_ID` | deploy-web | already referenced, line 34/41 (pending verification) |
| `VERCEL_PROJECT_ID` | deploy-web | already referenced, line 35/42 (pending verification) |

The publishable anon key and Clerk publishable key are not secrets in the security sense (they are safe to ship inside a compiled client bundle — that is what "publishable" means), but they still move to Secrets so environment differs cleanly between a future staging Supabase project and production, and so no one has to `git revert` a credential rotation.

### 10.2 GitHub Actions workflow — jobs

Extends the existing `deploy.yml` if confirmed present (or authors it fresh against report 01's baseline if not — see §10.0), splitting it into named jobs with an explicit dependency chain (`needs:`) so a failed analyze/test stops the deploy:

```yaml
name: Build, Test & Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.24.5'   # pinned exact version, not '>=3.19.0' range

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: ${{ env.FLUTTER_VERSION }}, channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter analyze lib/ --fatal-infos
      - run: dart format --output=none --set-exit-if-changed lib/

  test:
    needs: analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: ${{ env.FLUTTER_VERSION }}, channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: actions/upload-artifact@v4
        with: { name: coverage-report, path: coverage/lcov.info }

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: ${{ env.FLUTTER_VERSION }}, channel: stable, cache: true }
      - run: flutter pub get
      - name: Build web (release, credentials injected)
        run: |
          flutter build web --release \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
            --dart-define=CLERK_PUBLISHABLE_KEY=${{ secrets.CLERK_PUBLISHABLE_KEY }}
      - uses: actions/upload-artifact@v4
        with: { name: web-build, path: build/web }

  deploy-web:
    needs: build-web
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with: { name: web-build, path: build/web }
      - name: Deploy preview (PR)
        if: github.event_name == 'pull_request'
        run: npx vercel --token=${{ secrets.VERCEL_TOKEN }} --yes
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
      - name: Deploy production (main)
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: npx vercel --token=${{ secrets.VERCEL_TOKEN }} --prod --yes
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}

  build-windows:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: ${{ env.FLUTTER_VERSION }}, channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter config --enable-windows-desktop
      - name: Build Windows (release, credentials injected)
        run: |
          flutter build windows --release `
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} `
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} `
            --dart-define=CLERK_PUBLISHABLE_KEY=${{ secrets.CLERK_PUBLISHABLE_KEY }}
      - name: Zip release folder
        run: Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath monk-windows-${{ github.sha }}.zip
      - uses: actions/upload-artifact@v4
        with: { name: windows-build, path: monk-windows-${{ github.sha }}.zip, retention-days: 90 }
```

| Job | Trigger | Purpose | Fails the pipeline if |
|---|---|---|---|
| `analyze` | every push/PR | `flutter analyze --fatal-infos` + format check | Any lint/format violation — catches drift like the "PRP" branding string (report 04 weakness #8) before merge |
| `test` | after analyze | `flutter test --coverage`, uploads lcov | Any test fails — currently only `test/widget_test.dart`'s placeholder exists (report 01 §2d), so this job is a stub until item 9 of the report 04 handoff list (integration tests for Finance/Habits) lands; it is wired now so tests added later are enforced automatically, not opt-in |
| `build-web` | after test | Compiles web bundle with injected secrets | Build error; missing secret produces an empty-string credential that fails fast at Supabase init rather than silently shipping a stale hardcoded key |
| `deploy-web` | after build-web | PR → Vercel preview URL for review; `main` push → production | Vercel CLI error |
| `build-windows` | after test, `main` only | Produces a signed-zip .exe artifact for direct distribution (per report 04 item #10's Android-equivalent need on desktop) | Build error; kept as a separate job so a Windows failure never blocks the web deploy that most users hit |

Mobile (Android APK per report 04 handoff item #10) is intentionally **not** in this workflow yet — it needs a signing keystore secret (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`) that does not exist today. **BLOCKED — needs founder approval**: founder must generate and hand over a release keystore before a `build-android` job can be added; this plan reserves the job slot (parallel to `build-windows`, gated on `main`) but does not fabricate secrets that don't exist.

### 10.3 Versioning scheme

Single source of truth: `pubspec.yaml`'s `version: X.Y.Z+B` field. `AppConstants.appVersion` is deleted as a separate literal and replaced with a build-time constant so the two can never drift again (per §10.0's finding, pending its verification):

```dart
// lib/core/constants/app_constants.dart
static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
```

populated in CI via a step that reads `pubspec.yaml` and passes it through, e.g. `--dart-define=APP_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')`.

| Component | Meaning | Example |
|---|---|---|
| `X` (major) | Breaking data-shape or navigation change (e.g. an engine removed, like Religion in Section 1 item 4 / Section 9 item #4) | `5.0.0` |
| `Y` (minor) | New engine or major feature (Debt Payoff module, CSV import) | `5.1.0` |
| `Z` (patch) | Bug fix, copy fix, non-breaking tweak | `5.1.1` |
| `+B` (build number) | Monotonic, incremented every CI build regardless of X.Y.Z — required by Play Store/App Store/MSIX and useful for support ("which build are you on") | `+142` |

`AppConstants.appStage` (currently the literal `'Alpha'`, app_constants.dart line 7, with the comment `// alpha → beta → release` already present as a roadmap marker) becomes the human-facing stage label and is driven off a suffix on the semver, not a separate hand-edited string:

| Stage | pubspec.yaml suffix | `appStage` value | Gate to advance |
|---|---|---|---|
| Alpha | `5.0.0-alpha.N` | `'Alpha'` | Current state — founder + invited testers only |
| Beta | `5.0.0-beta.N` | `'Beta'` | Report 04 verdict conditions met: Deen tab removed, Arabic content-complete, ≥1 engine has real activation data from ≥20 non-founder users |
| Release (1.0) | `5.0.0` (no suffix) | `'Release'` | Kill criteria in report 03 §5 not triggered at the 6-month mark (Day-30 retention ≥20%, Finance activation ≥30%) |

Parsing rule for `appStage`: derive from the pubspec suffix at build time rather than maintaining it as an independent constant (`-alpha` → `Alpha`, `-beta` → `Beta`, no suffix → `Release`), closing the exact drift class described in §10.0.

Git tagging: every `build-web`/`build-windows` run on `main` tags the commit `v{pubspec-version}` (e.g. `v5.1.0-beta.3`) via `actions/checkout` + a tag-push step gated on `github.ref == 'refs/heads/main'`, giving a reversible, auditable mapping from a running production build back to an exact commit — this is the rollback mechanism: `git checkout v{previous-tag}` + re-run the workflow redeploys the last-known-good build if a release regresses.

### 10.4 Beta-feedback instrument

**In-app feedback widget.** A persistent, low-friction entry point rather than a buried settings-page form, because report 02 §2's core finding is that Monk's empty states already lack CTAs — a feedback mechanism that requires hunting for it will collect nothing:

- **Where it lives:** a floating action affordance in the app shell (same layer as the existing bottom-nav shell in `lib/core/router/app_router.dart`'s `ShellRoute`), visible on every screen only while `AppConstants.appStage != 'Release'` (i.e., shows in Alpha and Beta, auto-hides at general release so it never clutters the finished product).
- **What it captures:** a `feedback_reports` Supabase table —

```sql
create table public.feedback_reports (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  route text not null,               -- captured from GoRouter's current location automatically
  app_version text not null,         -- AppConstants.appVersion at time of report
  category text not null check (category in ('bug', 'confusing', 'missing_feature', 'praise', 'other')),
  message text not null,
  screenshot_url text,               -- optional, uploaded to existing Supabase Storage bucket
  created_at timestamptz default now()
);

alter table public.feedback_reports enable row level security;
create policy "feedback_reports_own" on public.feedback_reports
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

  RLS policy name: `feedback_reports_own`, following the exact `auth.uid() = user_id` pattern already used for `schedule_blocks_own` (schema.sql line 43). Down-migration/rollback: `drop table if exists public.feedback_reports;` — additive-only table, no existing data touched, fully reversible.
  The widget auto-fills `route` and `app_version`; the user only types `category` (single-select chips) + free-text `message`. This mirrors the "Getting-Started checklist" pattern report 02 §2 calls "the app's best onboarding mechanic" — low-effort, structured, always-available.
- **AR/EN parity:** category chip labels (`Bug`/`خلل`, `Confusing`/`غير واضح`, `Missing feature`/`ميزة مفقودة`, `Praise`/`إشادة`, `Other`/`أخرى`) and the widget's placeholder/button copy go into `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` at creation time — not retrofitted later, per the guardrail and per report 04 weakness #4 ("Arabic is fake") which this plan must not add to.
- **New engine placement:** this is a new table but not a new engine tab — it lives as a Layer-2 repository (`lib/engines/feedback/data/repositories/feedback_repository.dart`) with no dedicated screen, only the floating widget, keeping the 6-layer hierarchy intact without adding shell-navigation surface area.

**Analytics event schema.** Confirmed: **no new analytics SaaS** (no Mixpanel/Amplitude/PostHog/Firebase Analytics). Events write to a plain Supabase table Monk already has the infrastructure for — this is additive use of the existing backend, not a new dependency, and needs no founder approval beyond the table/RLS pair below.

```sql
create table public.app_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  event_name text not null,
  event_props jsonb,
  created_at timestamptz default now()
);

alter table public.app_events enable row level security;
create policy "app_events_own" on public.app_events
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_app_events_user_event on public.app_events(user_id, event_name, created_at);
```

RLS policy name: `app_events_own`, same `auth.uid() = user_id` pattern. Rollback: `drop table if exists public.app_events;` — additive-only, reversible, no impact on founder's existing live data in other tables.

Events are fired from existing Riverpod providers at natural state-transition points (no new instrumentation layer — one `SupabaseService.logEvent(name, props)` call inserted at points that already exist in the codebase):

| Event name | Fires when | Maps to | Source location |
|---|---|---|---|
| `signup_completed` | Clerk auth completes + `profiles` row created | Activation funnel step 1 | `lib/services/supabase_service.dart` `_ensureProfile()` (already called on first write per report 01 §3c — becomes the natural hook once that call is moved to app-startup-once per report 04 item #8) |
| `onboarding_completed` | User reaches onboarding page 4 ("All set") | Activation funnel step 2 | `lib/features/onboarding/screens/onboarding_screen.dart` |
| `engine_first_used:{money\|time\|energy\|health}` | First successful write to that engine's primary table (first transaction, first schedule block, first focus session, first habit toggle) | Activation funnel step 3 — directly measures report 03 §5's kill criterion "Finance engine activation: <30% add a bank account" | `money_providers.dart` (`upsertAccount`/`addTransaction`), `time_providers.dart`, `energy_providers.dart`, `health_providers.dart` |
| `checkin_completed:{morning\|evening}` | Daily check-in submitted | Retention signal — this is Monk's compounding data asset per report 04 strength #6 | `lib/engines/checkin/providers/checkin_providers.dart` |
| `week1_retained` | Computed nightly (Supabase scheduled function or client-side check on app open), true if `app_events` has ≥1 row for the user on ≥3 distinct days in days 2–7 post-signup | Activation funnel step 4 | Derived query over `app_events`, no new client code path |
| `week4_active` | Same pattern at day 28–30 window | Directly measures report 03 §5's kill criterion "Day-30 retention: <20% returning weekly" | Derived query over `app_events` |
| `feedback_submitted:{category}` | Feedback widget submit | Qualitative signal alongside the funnel | `feedback_repository.dart` (§10.4 above) |
| `paywall_hit:{screen}` | Any paywall trigger from §7.3 fires | Feeds §7.5 point 1 (upgrade-trigger signal) and §7.5 point 5 (paid-conversion measurement once checkout exists) | New — one call site per trigger row in §7.3's table |

The activation funnel is `signup_completed → onboarding_completed → engine_first_used(any) → week1_retained`; the retention funnel is `week1_retained → week4_active`. Both are answerable with a single `group by event_name, date_trunc('week', created_at)` query against `app_events` — no dashboarding SaaS required for the alpha/beta stage. If the founder later wants charts instead of SQL, that is a candidate for a lightweight read-only admin screen inside Monk itself (a new `lib/features/admin/` feature reading `app_events` via existing repositories), which stays inside the guardrails; a third-party analytics dashboard would not, and is flagged here as **BLOCKED — needs founder approval** if ever proposed.

---

## Approval Checklist

The following is what the founder can literally check off to approve Phase A (this plan) and greenlight Phase B (implementation). Items marked **BLOCKED** must be resolved before their specific dependent feature can be implemented — they gate only that feature, not approval of the rest of the plan.

**Phase A sign-off (approve the direction):**

- [ ] I approve the overall Phase A plan across all 10 sections as the direction for implementation.
- [ ] I approve the color-token migration (§8.1) — `bg`/`surface`/`card`/`gold` are fixed per the guardrail and already in effect; I'm aware the derived tokens (`cardHover`, `cardAlt`, `border`, `borderLight`) are open for my refinement without blocking the rest of implementation.
- [ ] I approve the Finance-first progressive-disclosure onboarding redesign (§2) and the removal of generic seeded data.
- [ ] I approve the Resource Pulse as the new Overview hero and home-screen redesign (§4), including the secular framing of schedule modes (§4.1).
- [ ] I approve the three new engines specified in §5a–5c (Debt Payoff, Assets, Digital Inventory), noting that Assets and Digital Inventory are plan-writer design additions not directly recommended by the audit reports (see the evidence-traceability flags in §5b/§5c).
- [ ] I approve the free-tier/Pro boundary and pricing table in §7.1–§7.4, including the reconciliation overriding report 03 §3b's suggestion to gate schedule modes and multi-currency.
- [ ] I approve the Cut List decisions in §9 (remove dead Health screen, hide Ideas behind a flag, remove the Religion/Deen engine, rename residual religion-tagged keys).

**BLOCKED items requiring my explicit decision before their dependent work begins:**

- [ ] **BLOCKED (§5d):** Choose the Clerk-side household/membership model (Clerk Organizations vs. custom Supabase-native invite codes) — Household tier cannot be scheduled without this.
- [ ] **BLOCKED (§5d):** Separately approve accepting a non-standard, OR-based RLS policy shape for household-shared tables (`households`, `household_members`, and the retrofitted `*_or_household` policies on `bank_accounts`/`transactions`/`debts`/`installment_plans`/`credit_cards`) — this deviates from every other table's `user_id = auth.uid()` pattern in this plan and needs sign-off as its own decision, independent of the Clerk question above.
- [ ] **BLOCKED (§7.7):** Choose the payment processor for Egyptian-currency subscriptions (Paymob, Fawry, or native Apple/Google IAP) before checkout can be built. §7.5's sequencing (ship limits + waitlist CTA first) lets the monetization surface ship without this being resolved immediately.
- [ ] **BLOCKED (§10.2):** Generate and hand over an Android release-signing keystore (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`) before a `build-android` CI job or the Android APK distribution (Section 1 item 12) can proceed.
- [ ] **BLOCKED (§8.2):** Decide which Arabic-supporting display serif to license/bundle to pair with PlayfairDisplay at the Display/H1/H2 type tiers (or approve the Roboto/Noto Sans Arabic Bold fallback instead) — PlayfairDisplay has no Arabic glyph coverage and Arabic headings have no specified font without this decision.
- [ ] **BLOCKED (§4.2):** Confirm the corrected canonical distribution domain (replacing `prp-app.website`) before the shareable Resource Pulse card ships, so viral shares don't drive traffic to a domain that still says "PRP."
- [ ] **BLOCKED (§3.1):** Approve or reject swapping the Alpha Vantage stock-price provider for a keyless alternative (a new external data dependency) — until resolved, the minimum fix (local caching of the last successful price) ships instead.

**Verification items (confirm before the dependent section is built exactly as specified):**

- [ ] **Verify (§10.0):** Confirm whether `.github/workflows/deploy.yml` already exists in the repository as described, or whether report 01's "no CI/CD in place" baseline is still accurate — Section 10's CI/CD plan works either way, but the team should know which starting point it's actually extending.
- [ ] **Verify (§10.0):** Confirm whether `AppConstants.appVersion` is actually hardcoded to a value that disagrees with `pubspec.yaml` (this plan cites `'4.9.0'` vs. `4.1.0+1` from a direct repo spot-check, not from the four audit reports) — doesn't change §10.3's recommended scheme either way, but is worth confirming as the motivating example.
- [ ] **Verify (§3.2):** Validate the CIB/NBE/Banque Misr/ADCB CSV export format assumptions against real sample exports before shipping parsers — flagged in §3.2 as needed but non-blocking for starting implementation.

Once every non-BLOCKED box above is checked, Phase B (implementation) is greenlit for that section; BLOCKED items gate only their own dependent feature, not the rest of the plan.