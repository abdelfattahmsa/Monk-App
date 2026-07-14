# Stage 2 — Product Teardown

> Walk as a first-time user on the live Web version (prp-app.website).
> App identity at time of audit: branded "PRP" internally, being renamed to "Monk" (pubspec.yaml name: `monk_app`). Onboarding still says "PRP."

---

## 1. First-Time User Flow: Onboarding → First Value

### Flow map

```
Hit URL → Login screen → Sign up → Onboarding (5 pages) → Overview screen
                                    ↓
                         [Page 0] Welcome — four resources
                         [Page 1] Tour — swipeable pillar cards
                         [Page 2] Currency selection (EGP default)
                         [Page 3] Add first habit (with suggestions)
                         [Page 4] "All set" + getting-started checklist
```

### Time-to-first-aha estimate

| Milestone | Minutes |
|-----------|---------|
| Signup (email + password + name) | 1 |
| Through 5 onboarding pages | 2–3 |
| See Overview screen with seeded data | 4 |
| Understand what the app does | 8–12 |
| Log first real transaction | 15+ |
| Derive first insight from data | Days |

**First "aha" is not today.** The app requires users to input their own data before it returns value. A new user sees a pre-seeded schedule (14 default blocks for "normal" mode) and 4 generic goals ("Build emergency fund", "Complete certification", "Exercise 3x/week", "Read 12 books") and 6 generic habits. This is the right call — blank walls kill onboarding — but the seeded data is generic and creates false engagement: users may check off habits they didn't set and feel the numbers are meaningless.

### Where a normal user would quit

1. **Finance screen (bank accounts)** — First time a user sees the Finance section and finds no real data, no CSV import, no bank API, just "Add account" — most users will not manually type their balances. This is the primary abandon point.
2. **Habit list** — Six pre-seeded generic habits with emoji. A non-systems-thinking user will not understand why these matter or how to customize them for their life.
3. **Ideas section** — Captures ideas but has no processing: no tags, no linking to goals, no export. Why not just use Notes or Notion? No clear answer.

---

## 2. Empty-State Experience

| Screen | Empty state quality | Evidence |
|--------|---------------------|----------|
| Overview | Getting-Started checklist visible, KPI grid shows real values (0m focus, 0/6 habits) | `lib/features/overview/screens/overview_screen.dart` lines 213–217 |
| Finance overview | Shows 0 net worth, 0 spending — numerically correct but offers no "add your first account" prompt | `lib/features/finance/screens/finance_overview_screen.dart` |
| Habits | "No habits yet" text, no CTA | `lib/features/overview/screens/overview_screen.dart` line 1291 |
| Goals | "No active goals" text, no CTA | Line 1350 |
| Ideas | Not visited in flow — inferred minimal | `lib/features/ideas/screens/ideas_screen.dart` |
| Focus timer | Functional — shows timer UI immediately | `lib/features/focus/screens/focus_screen.dart` |

**The Getting-Started checklist is the app's best onboarding mechanic.** It surfaces in Overview after onboarding and drives users to complete profile → add bank → create schedule → set goal → track habit → complete focus session. This is the right architecture. However it can be dismissed and never brought back.

**Seed data verdict:** Default habits and goals are plausible but impersonal. They tell the user nothing about what the app uniquely offers. Better: seed one Egyptian-specific habit (e.g., "Read 30 min after Fajr") and one finance goal specific to EGP debt ("Pay Valu installment").

---

## 3. Friction Inventory

| Data type | Current friction | Automation available? |
|-----------|----------------|----------------------|
| Bank balances | Manual entry per account, per update | Bank CSV import possible but unimplemented; open banking API (Egypt: no standard yet) |
| Credit card balance | Manual entry | Same |
| Transactions | One-by-one manual entry | CSV import unimplemented; bank SMS parsing (Egypt: feasible, unimplemented) |
| Habits | Manual toggle per day | None needed — it's a toggle |
| Weight / body metrics | Manual entry | Apple Health/Google Health Connect available — implemented but **only on iOS/Android** |
| Steps / heart rate | Manual entry on web/Windows | Platform limitation — web cannot sync health |
| Fasting timer | One-tap start/stop | Good — minimal friction |
| Schedule | Manual block creation | Calendar import (ICS) unimplemented |
| Goals progress | Manual % slider | Could auto-compute from linked calendar events (feature exists as `linked_event_ids` field in schema) |
| Check-in | Manual 5-score + text fields | No automation possible — intentional friction |
| FX rates | Auto-fetched from exchangerate-api.com | Working — no friction |
| Stock prices | Requires user-supplied Alpha Vantage API key | Significant friction; free tier Alpha Vantage is slow |

**The single biggest friction point: all financial data is 100% manual.** In a world where YNAB, Copilot, and even Notion templates sync directly to bank accounts, Monk's Finance engine starts from zero every session unless the user manually updates balances. For the Egyptian market, bank API access doesn't exist at this level — but CSV import from CIB, Banque Misr, and ADCB would cover the major banks.

---

## 4. Feature Depth vs Breadth

### Finance Engine — Genuine differentiation: 4/5

What is distinctly valuable:
- **Egyptian installment providers hardcoded** (`lib/engines/money/data/models/money_models.dart` lines 12–15): Valu, Tru (TruValue), Contact Finance, Sympl, Aman, Bank Takseet. No Western app models these.
- **Digital wallets specific to Egypt/MENA** (lines 6–9): Vodafone Cash, FawryPay, InstaPay, OPay — correct local providers.
- **Credit card with APR, statement day, due day, min payment %** — more sophisticated than most personal finance apps in Arabic.
- **Net worth across: savings + current − (CC balances + installments + external debts)** — correct formula, correctly computed in `financeSummaryProvider`.

What is missing:
- No bank statement import (CSV).
- Multi-currency net worth is numerically wrong (raw sum without conversion).
- No recurring transactions (salary, rent, subscriptions).
- No budget categories / spending limits.

### Time Engine — Moderate: 3/5

**Schedule modes (normal/fasting/friday/cairo)** are the standout feature. This maps directly to Egyptian Muslim professional life. No competitor does this.

Shallow:
- Calendar is basic event logging with no external calendar sync (Google Calendar field `gcal_event_id` exists in schema but sync is unimplemented).
- Tasks have no priority matrix, no tags, no recurring tasks.
- Time overview screen shows no analytics.

### Energy Engine — Moderate: 3/5

- Focus timer (Pomodoro) is functional. Session logging works. 7-day chart on Overview is genuinely useful for tracking.
- Goals have progress % (manual), milestones (text array), priority (high/medium/low). Adequate but not deep — Notion goals templates offer more linking.
- Ideas is a notes capture screen with no structure. An idea with no processing path is a liability. Users will abandon it quickly.
- Mood logging (morning + evening) is genuinely useful. Combined with the check-in flow it creates a journal-like data set.

### Health Engine — Shallow: 2/5

- Habits: functional, streak calculated correctly, history stored as JSONB (grows unbounded).
- Fasting timer: correct — start/stop/history.
- Body metrics, nutrition logging, exercise logging: all implemented, all manual-entry only.
- Health sync: works on iOS/Android via `health: ^12.2.0`; has no function on the live web deployment.
- `lib/features/health/screens/health_screen.dart` — dead file saying "Health tracking coming soon" — contradicts the multiple working sub-screens. Should be deleted.

### Ideas Engine — Shallow: 1/5

Quick capture is fine. But there is no processing:
- No tagging
- No linking to goals
- No status (inbox / processed / archived)
- No export
- No search (inferred — not verified)

Superior alternatives exist at zero cost: Apple Notes, Google Keep, Notion free tier. Monk needs to justify why you'd capture ideas here instead of those.

### Religion/Deen Engine — Still fully present: 0/5 for Monk

The Deen tab (Salah, Quran, Zakat) is fully routed, implemented, and shipped to the web at `/deen/*`. Per stated strategy it should be in Mizan, not Monk. Its presence in Monk:
1. Dilutes the positioning ("not a religion app").
2. Creates confusion for non-Muslim users or users who want secular positioning.
3. Adds 4 screens of code/maintenance burden to Monk.

This is not a small leftover — it is a full tab in the shell navigation.

---

## 5. Navigation UX

The shell (`lib/shared/screens/shell_screen.dart`) implements:
- Desktop (≥800px): sidebar rail with full labels + sub-tab expansion.
- Mobile: bottom navigation bar.
- Sub-tabs: horizontal scrollable tab bar per pillar.

**Count of tabs:** 7 (Overview, Time, Finance, Energy, Health, Deen, Profile).

**Problem:** 7 top-level tabs plus 4–6 sub-tabs each is 30+ routes. For a first-time user this is overwhelming. The Getting-Started checklist partially mitigates this, but discovery of features like Fasting, Mood, or Installments requires deliberate exploration.

**Quick-capture FAB:** Present (`lib/shared/widgets/quick_capture_fab.dart`). Captures ideas. Does not capture transactions or habits — two higher-priority quick-capture targets.

---

## 6. Verdict on First-Time User Experience

**The app rewards second-week users, not first-hour users.**

A user who commits to entering their actual financial data, setting real habits, and returning daily gets a genuinely differentiated dashboard. The problem is the cost of reaching that state is high (hours of manual data entry) with no intermediate value. The one exception is the Focus Timer — it delivers value immediately with zero setup.

The brand positioning ("treat your life like a business") self-selects for a very specific user: systems-thinking, high-conscientiousness, willing to invest time in a tool. The onboarding doesn't acknowledge this contract with the user. It says "Welcome to PRP" and shows generic habits. It should say "This app requires 20 minutes to set up and daily discipline to use. Here's what you'll get in return."
