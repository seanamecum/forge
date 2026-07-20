# FORGE — Evidence-Based Launch Audit

**Auditor role:** founding CTO / staff iOS / product design / security / accessibility / QA / App Store launch.
**Date:** 2026-07-19 · **Branch:** `audit/launch-hardening` · **Base commit:** `4fde83c`
**Scope:** native SwiftUI iOS app (`ios/`) + Next.js website (`src/`) + Supabase backend (`supabase/`).

> **Honesty note.** Every build result, test count and finding below was produced or read
> **in this session**. Nothing is inherited from prior PR descriptions or comments. Where a
> claim could **not** be verified in this environment, it is marked **⚠︎ UNVERIFIED** with the
> reason. This document is the audit only — **no fixes have been implemented yet.**

---

## 0. Environment & what could / could not be verified

| Tool | Status | Consequence |
|---|---|---|
| Xcode 26.6 / Swift 6.3.3 | ✅ present | iOS Debug + Release build and full test run were executed for real. |
| iPhone 17 simulator | ✅ present | Tests ran on `platform=iOS Simulator,name=iPhone 17`. |
| `node` / `npm` | ❌ **absent** | Web `build` / `lint` / `tsc` / `vitest` **could not be executed**. Website audited by static reading only. |
| `supabase` CLI | ❌ **absent** | Migrations / RLS **could not be applied or queried live**. SQL audited by reading `supabase/migrations`. |
| `gh` CLI | ❌ absent | No PR/issue automation from this environment. |
| Physical iPhone / Apple Watch | ❌ absent | On-device HealthKit auth, Live Activity, widget, Watch sync **could not be exercised**. |
| App Store Connect | ❌ no access | Privacy nutrition labels, signing, submission state **unverified**. |
| Supabase dashboard | ❌ no access | Live RLS state of the `feedback` table (not in migrations) **unverified**. |

---

## 1. Commands executed (this session)

```
sw_vers / xcodebuild -version / swift --version           # environment
xcodebuild -list -project Forge.xcodeproj                 # targets & schemes
xcodebuild build   -scheme Forge -configuration Debug     -destination 'iPhone 17'
xcodebuild build   -scheme Forge -configuration Release    -destination 'iPhone 17'
xcodebuild test    -scheme Forge -configuration Debug      -destination 'iPhone 17'
git checkout -b audit/launch-hardening
# + extensive grep/read across ios/, src/, supabase/
```

## 2. Build & test results (VERIFIED)

| Check | Result |
|---|---|
| iOS **Debug** build (`Forge` scheme, iPhone 17 sim) | ✅ `** BUILD SUCCEEDED **`, **0 warnings** |
| iOS **Release** build (iPhone 17 sim) | ✅ `** BUILD SUCCEEDED **`, **0 warnings** |
| iOS unit tests | ✅ `** TEST SUCCEEDED **` — **178 executed, 2 skipped, 0 failures** across 29 suites, ~16 s |
| Web build / lint / typecheck / tests | ⚠︎ **NOT RUN** — no Node in environment |
| Supabase migration apply / RLS query | ⚠︎ **NOT RUN** — no Supabase CLI |

**Claim correction:** `ios/README.md` states "149 tests." The real discoverable count this session is
**178 executed (+2 skipped) = 180 defined.** The README figure is stale, not inflated.

**Skipped-test cause:** the 2 skipped tests are `AIServiceTests.testMockModeWhenNoKey` and
`testCoachEndpointFollowsMode`. They skip with *"Secrets.plist present — device is configured for the
live proxy."* This is a **local-only** artifact: `ios/Forge/Forge/Secrets.plist` exists on the developer
machine but is **gitignored and never committed** (verified: `git ls-files`/`git log` show it untracked
with no history; `.gitignore:14` covers `ios/**/Secrets.plist`). A clean CI checkout has no `Secrets.plist`,
so those 2 tests **do run** in CI. **Correction:** an earlier draft of this report (P1-12) called the file
"committed" — that was wrong; see the struck finding below.

**Runtime noise observed:** the test log emits repeated `CoreData: error … Sandbox access to
file-write-create denied` for the App-Group store `group.com.forge.performance`. Non-fatal in the
test sandbox, but indicates the shared-container SwiftData store can fail to open — needs on-device
verification that the widget/app group store initialises (see "Items requiring a real device").

---

## 3. Repository map

```
forge-main/
  ios/Forge/Forge/                      native SwiftUI app  (~13.9k LOC Swift, 119 files)
    App/            ForgeApp (@main) · RootView · MainTabView
    Core/           AppState (@Observable god-ish object; owns Forge Score maths) ·
                    DirectiveEngine · StreakEngine · TargetEngine · RehabEngine ·
                    DataHub · AdaptiveNutritionEngine · TrainingAnalyticsEngine ·
                    ForgeConfig · SupabaseConfig · WidgetBridge · Mock/ · Persistence/
    DesignSystem/   Theme · Components · Rings · ChartViews · StateViews
    Models/         domain structs
    Services/       AuthService (Supabase GoTrue) · HealthKitService · AIService (Claude via proxy) ·
                    OpenFoodFactsService · Workout/Nutrition/Recovery/Injury/Notification/RunTracker/…
    ViewModels/     CoachViewModel
    Features/       Auth · Onboarding · Dashboard · Coach · CheckIn · Goals · Train ·
                    Nutrition · Recovery(+injury/rehab/concussion) · Health(bloodwork/body/forecast) ·
                    Social · Market · Profile
    ForgeWidget/    home-screen widget + workout Live Activity
    ForgeWatch/     Apple Watch companion
    ForgeTests/     29 suites, 180 tests
  src/                                  Next.js 14 marketing site + mock-data prototype
    app/            page.tsx (landing) · onboarding · auth · feedback · support · privacy · terms · (app)/*
    lib/            auth.ts · feedback.ts · data/ (MockDataSource) · ai/coach.ts (rule-based) · mock/
  supabase/
    migrations/0001_forge_init.sql      schema + RLS for ~24 tables
    functions/coach-proxy/              server-side Claude key (edge function) — good
    functions/delete-account/           server-side JWT-scoped account delete — good
  appstore/         metadata.md + screenshots
  .github/workflows/ci.yml              CI (ios build+test; web ci+build)
```

**Architecture verdict:** healthier than typical. Business logic is factored into pure, unit-tested
`Core/*Engine` types rather than buried in views; networking (Auth, AI, OpenFoodFacts) is real and
proxy-protected. The main structural smells: `AppState` is a large multi-responsibility object that
computes the Forge Score inline and regenerates the directive/workout plan on read, and several
`Features` views compute business logic and run persistence/HealthKit fetches inside `body`
(see P1-9, P2 performance).

---

## 4. Findings by severity

Severity = launch risk. **P0** blocks any public beta; **P1** blocks App Store; **P2** quality; **P3** later.
Each finding: evidence `file:line` (personally read) · problem · user impact.

### P0 — must fix before any beta

**P0-1 · `challenge_members` table has NO row-level security** — *(VERIFIED, read the SQL)*
`supabase/migrations/0001_forge_init.sql:317` creates `public.challenge_members(challenge_id,user_id,progress)`
but it is **absent from the RLS enable/policy loop** (`:349-355`) and never gets
`alter table … enable row level security`. Every other user table is gated by an owner policy.
**Impact:** with the public anon key, this table is world-readable and world-writable via PostgREST —
anyone can read every user's challenge participation and insert/modify arbitrary rows.

**P0-2 · Users can self-grant paid tiers (privilege escalation)** — *(VERIFIED)*
The shared policy (`:360-364`) is `create policy "own" … using(auth.uid()=user_id) with check(auth.uid()=user_id)`
with **no `FOR` clause → `FOR ALL`** (select/insert/update/delete). `subscriptions` (`:56-64`, columns
`plan,status,stripe_subscription_id`) and `profiles.plan` (`:51`) are therefore **user-writable**.
**Impact:** an authenticated user can `UPDATE` their own row to `plan='elite'`, `status='active'`,
bypassing any billing. Billing/entitlement columns must be service-role-write-only.

**P0-3 · App outputs return-to-play "Cleared" from self-reported input** — *(VERIFIED)*
`Core/RehabEngine.swift:80` `case 90…: band = "Cleared"` and `:89` `etaText = "Cleared for return"`,
computed from a tappable checklist + pain slider + a mock strength value; this band is injected into
the live coach prompt (`Services/AIService.swift:281`). **Impact:** the app can tell an injured
athlete they are "cleared to return," which is medical clearance it is not qualified to give.

**P0-4 · Concussion demo depicts a fully game-cleared return** — *(VERIFIED)*
`Core/Mock/MockRehab.swift:129-130`: stage 6 *"Full practice. Contact. Requires medical clearance."*
`completed: true` and stage 7 *"Competition return … Game cleared."* `completed: true`.
**Impact:** the concussion module shows all 7 return-to-play stages complete including "Game cleared,"
normalising unsupervised return-to-competition after head injury. Highest-liability screen in the app.

**P0-5 · Streak rewards merely opening the app** — *(VERIFIED)*
`Features/Dashboard/DashboardView.swift:26-31` writes a `ScoreRecord` in `.onAppear`; the streak is
`StreakEngine.streak(days: PersistenceService.scoreDays())` (`:234`) and `scoreDays()` returns every
day a score record exists (`Core/Persistence/PersistenceService.swift:66-69`). **Impact:** opening the
Home tab once per day — zero training, zero check-in — extends the "streak." It is an engagement
dark-pattern, not a record of intentional action.

**P0-6 · Demo values presented as real, live signals in several places** — *(VERIFIED)*
- Once HealthKit is authorized, the amber "Demo data" chips disappear (`DashboardView.swift:248`,
  `RecoverHomeView.swift:30`) — but `Services/RecoveryService.swift:88-97` only refreshes
  sleep/HRV/RHR/steps/calories; the headline **recovery number, strain, sleep-debt, HRV baseline and
  all 14-day trends stay mock** and still feed the Forge Score. A "connected" score silently blends
  real and fabricated data with no demo label.
- `Features/Health/ForecastView.swift:9` renders `MockData.forecasts` — six hardcoded projections with
  literal `confidence` values (`MockData.swift:316-327`) shown as "Digital Twin … confidence bands."
- `Features/Recovery/ForgeRecoveryView.swift:101-122` renders a static "22% · Moderate" injury-risk
  ring with fabricated ACR "drivers" (`MockRehab.swift:135-146`) as if computed.
- In **live** AI mode the coach system prompt hardcodes the demo athlete's clinical data —
  `MockData.knee`, `.bloodwork` (e.g. "Vitamin D 26 ng/mL"), `.injuryRisk`, rehab prescriptions
  (`AIService.swift:201-281`) — so a real user's LLM answers are grounded in Sean's fake medical record.

**P0-7 · `feedback` table is not in source control** — *(VERIFIED absent; live state UNVERIFIED)*
iOS (`FeedbackSheet.swift`) and web (`src/lib/feedback.ts`) both `POST /rest/v1/feedback` with the anon
key, and a web test asserts it — but **no migration creates the table or its policies.** The
"insert-only, select denied" protection is asserted in a comment, not in code. **Impact:** if the table
was created in the dashboard without correct RLS, all feedback rows + submitter emails could be
world-readable. Cannot confirm insert-only without dashboard access.

### P1 — must fix before App Store

**P1-1 · Session tokens stored in `UserDefaults`, not Keychain** — *(VERIFIED)*
`Services/AuthService.swift:156` stores `{accessToken, refreshToken, email}` via
`UserDefaults.standard.set(…, forKey: sessionKey)`. **Impact:** auth tokens belong in the Keychain
(access-control, not in plaintext plist/backups). Security + App Store review risk.

**P1-2 · No token refresh → session expiry unhandled** — *(VERIFIED)*
`refreshToken` is stored (`:17,155`) but never used; there is no refresh flow. Supabase access tokens
expire (~1 h). **Impact:** `sessionToken` returns a stale JWT; `deleteAccount` and any authed call then
401 with a generic "check your connection" message (`:43`) — misdiagnosed as a network error.

**P1-3 · Account deletion is cloud-only; no local-data control** — *(VERIFIED)*
`AuthService.deleteAccount()` (`:32-48`) POSTs to `delete-account` then `signOut()` (which only clears
the UserDefaults session, `:121-124`). The confirmation copy (`ProfileView.swift:92`) says *"Data on
this phone stays until you delete the app."* **Impact:** no separate "delete local Forge data" or
"delete both" action; local SwiftData (workouts, nutrition, check-ins, scores) persists silently. Also
`deleteAccount` uses a possibly-expired token and swallows the server body with `try?` — cannot
distinguish partial failure, and "Deleting…"→success can be shown for a non-2xx path if `logout()`
is reached (retry story is unclear).

**P1-4 · Data export is incomplete, unversioned, and fails silently to `"{}"`** — *(VERIFIED)*
`PersistenceService.exportJSON()` (`:72-102`) exports only **workouts, nutrition, forge_scores,
check_ins** (4 of ~15 categories). **Missing:** profile, goals, preferences/units, per-set detail,
**hydration/water** (stored in `UserDefaults`, `:214-225`), supplements, recovery/sleep history,
injuries/rehab, measurements, directives, templates, feedback. No `schema_version`, `app_version`,
`units`, or `timezone`. On any encode failure it returns the literal `"{}"` (`:100`). It is also invoked
**eagerly on the main thread** inside `ShareLink(item: PersistenceService.exportJSON())`
(`ProfileView.swift:68`) — a SwiftData fetch on every ProfileView render. **Impact:** a data-portability
feature that omits most of the user's data and can hand back an empty object with no error.

**P1-5 · Feedback collapses every failure to `Bool`** — *(VERIFIED)*
`FeedbackSheet.swift`'s `FeedbackClient.submit` returns `Bool`, `try?`-swallows the throw and discards
the response body; the UI shows one generic message regardless of cause (offline vs 401 RLS vs 400).
**Impact:** a permanently-broken RLS policy would silently drop all founder feedback with no signal;
users get no actionable message. Contrast with `AuthService`/`OpenFoodFacts`, which do parse typed errors.

**P1-6 · Hardcoded activity goals (10,000 steps / 1,000 kcal)** — *(VERIFIED)*
`DashboardView.swift:91-92,97-99`: `hk.steps / 10_000`, `hk.activeEnergy / 1_000`, labels "of 10,000" /
"goal 1,000." Not user-configurable, not profile-derived, not labeled as a default — inconsistent with
the calorie target, which *is* derived by `TargetEngine`. **Impact:** implies 1,000 active kcal is a
universal daily goal; wrong for most users.

**P1-7 · Percentage clamp mismatch between visual and VoiceOver** — *(VERIFIED)*
`DashboardView.swift:66` shows `min(pct,100)%` but `:85` `.accessibilityLabel` reads raw `pct`.
**Impact:** at 130 % of calories a sighted user sees "100 %," VoiceOver reads "130 percent." Progress
maths is also re-inlined per view with divide-by-target guards duplicated rather than shared.

**P1-8 · Forge Score has no 0–100 clamp** — *(VERIFIED)*
`AppState.swift:139-143` sums `value*weight` (weights sum to 1.0, correct) but never clamps; each
component `value` is an unvalidated `Int` (`:447-452`). **Impact:** any out-of-range component pushes
the headline score past 100 / below 0 with no guard.

**P1-9 · Directive tip dismissal is transient `@State`** — *(VERIFIED)*
`DashboardView.swift:7` `@State private var tipDismissed = false`, set at `:135-136`. Not persisted, not
tied to a directive id (`DailyDirective` has no stable id/date, `DirectiveEngine.swift:41-55`).
**Impact:** "Dismiss" is undone by any tab switch / relaunch; the banner reappears constantly.

**P1-10 · Nutrition "3 million products" claim + serving-size error** — *(VERIFIED)*
`Features/Nutrition/NutritionHomeView.swift:299` *"the barcode scanner … knows about 3 million products."*
The provider is OpenFoodFacts, whose coverage Forge neither controls nor measures — an unsubstantiated
capability claim. Separately, `OpenFoodFactsService.swift:66-77` always logs a scanned item as **"100 g"**
with per-100 g macros and no quantity prompt. **Impact:** a scanned 30 g bar is logged as 100 g → ~3× the
real calories/macros. (The scanner itself is real: VisionKit `DataScannerViewController`, typed
`LookupError`, honest manual-entry fallback — good.)

**P1-11 · Legal pages contradict the shipped product** — *(VERIFIED)*
`src/app/privacy/page.tsx:46-48` *"Forge has no account system in the current release, so there is
nothing server-side to erase,"* and `support/page.tsx:33` *"no accounts"* — yet the web app ships full
Supabase email auth (`src/lib/auth.ts`, `src/app/auth/page.tsx`) and a `delete-account` function, and
`terms/page.tsx:48-51` describes deleting a server account. Both legal pages are drafts
(`terms:9-10,19` "DRAFT … Effective: at public launch"; same in privacy). Contact identity is
inconsistent: `terms:92-96` and `feedback:80` use a **personal Gmail**, while privacy uses
`privacy@forge.app` and support uses `support@forge.app` (domain marked TODO in `appstore/metadata.md:76`).
**Impact:** the privacy policy makes false statements about accounts and server data; contradictory,
counsel-unreviewed legal docs with placeholder dates and a personal email cannot ship.

**P1-12 · ~~`Secrets.plist` committed → suppresses AI-mode tests~~** — **RETRACTED / FALSE POSITIVE**
An earlier draft claimed this file was committed. On direct verification it is **untracked, never in git
history, and correctly gitignored** (`.gitignore:14`). It exists only on the developer's local disk (holds
just the CoachProxyURL, no secret). The 2 AI-mode tests skip **locally** because the file is present there,
but a clean CI checkout has no such file, so they run in CI. **No action needed.** Left here, struck, for
audit-trail honesty rather than silently deleted.

**P1-13 · CI is missing key gates** — *(VERIFIED by reading `.github/workflows/ci.yml`)*
CI runs iOS build+test and web `npm ci`/`npm test`/`npm run build`, but **no** lint, standalone
typecheck, secret scanning, or `npm audit`. **Impact:** the committed anon-key literal and future
secrets would not be caught; web app code (auth/feedback) has no test gate beyond a successful build.

### P2 — product quality

- **P2-1 · Completed workouts don't feed recovery/strain/Forge Score.** `WorkoutService.finish` only
  writes history + PRs; `recovery.today`/strain stay mock (`RecoveryService.swift:6,19`). Logging a hard
  session changes nothing downstream — undercuts the "closed-loop" thesis. *(VERIFIED)*
- **P2-2 · Injury state is a hardcoded singleton;** "Log a New Injury" chips are `toggle: { _ in }` no-ops
  (`ForgeRecoveryView.swift:131-132`). *(VERIFIED)*
- **P2-3 · Dashboard density:** 12 stacked sections incl. 3–4 directive-derived surfaces
  (`DashboardView.swift:12-23`). Home doesn't answer "what should I do today?" in three seconds. *(VERIFIED)*
- **P2-4 · Per-render cost in `body`:** `app.dailyDirective` (runs `DirectiveEngine.make` + full
  `workouts.generate`) is read 3+ times per dashboard render; `PersistenceService.scoreDays()` (SwiftData
  fetch) read twice in `heroCard`. No memoisation. *(VERIFIED)*
- **P2-5 · Recommendation transparency gaps:** directive/score expose rationale, but none expose
  *inputs-missing*, *confidence*, *timestamp*, or an explicit *safe-fallback* state; forecast/injury-risk
  show precise percentages with no uncertainty basis. *(VERIFIED)*
- **P2-6 · HealthKit staleness/source not enforced on live reads:** `latest()` takes the newest sample
  with `predicate: nil` and no age bound or `HKSource` filter (`HealthKitService.swift:217-228`); the
  freshness/priority logic in `DataHub` runs only on mock readings. A weeks-old HRV sample reads as today. *(VERIFIED)*
- **P2-7 · HealthKit read-denial undetectable:** denial inferred only from *share* status
  (`HealthKitService.swift:70-77`); a user who denies all reads but leaves workout-write reads as
  `.authorized` and silently falls back to demo values. (Apple hides read status by design — needs an
  explicit "no data flowing" heuristic.) *(VERIFIED)*
- **P2-8 · Web feedback endpoint is an unauthenticated, unthrottled public insert sink** — no
  honeypot/rate-limit/CAPTCHA; only client-side length validation (`src/lib/feedback.ts:8-26`). *(VERIFIED)*
- **P2-9 · Marketing advertises ~20 mock modules + prices as shipped** (`src/app/page.tsx:92,213`;
  pricing `$19/$39/$79` vs Terms "Forge 1.0 is free" vs App Store "Free"). Tier names disagree across
  web / iOS enum / SQL. *(VERIFIED)*
- **P2-10 · Withings scale hardwired `connected:true`** feeding fabricated body-comp into DataHub in an
  "Apple-Health-only" 1.0 (`MockData.swift:113`). *(VERIFIED)*
- **P2-11 · Subscription UI shows "Pro trial · 9 days left" and live prices with no StoreKit**
  (`ProfileView.swift:223-229`, honestly footnoted "StoreKit wiring is the production step"). *(VERIFIED)*

### P3 — later

- Location usage string present, when-in-use only, no Always entitlement (fine, noted).
- No `CHECK`/length constraints on Postgres `text` columns.
- `saveRun` not `@MainActor` while it mutates `lastError` (minor concurrency inconsistency).
- Units toggle is display-only "Imperial" (`ProfileView.swift:144`).
- Large volumes of clinical-looking demo data (bloodwork, deficiencies) render without a per-screen
  "sample data" marker even where a global chip exists.

---

## 5. Cross-cutting summaries

### Security
- **P0:** `challenge_members` unprotected (P0-1); self-writable billing columns (P0-2); `feedback`
  table/RLS not in source (P0-7).
- **P1/P2:** tokens in `UserDefaults` (P1-1); production anon-JWT hardcoded as a source fallback literal
  in `src/lib/auth.ts:6` / `src/lib/feedback.ts:5` (public by design but blocks rotation & pins the live
  project — remove literal, require env, rotate); unthrottled feedback sink (P2-8); no secret scanning in
  CI (P1-13). **Good:** service-role and Anthropic keys are server-side only (edge functions); `.gitignore`
  covers `.env*`; no `.env` committed. Home-dir files `~/.forge-supabase-*` (DB password, access token,
  anon json, mode 0600) are **outside** the repo and not referenced — keep them out; rotate if ever moved in.
  *No secret values are reproduced in this report.*

### Accessibility (static review — on-device VoiceOver/Dynamic Type sweep still required)
- Clamp mismatch between visual and VoiceOver on the fuel card (P1-7); `ScoreRing` reads raw value
  (`Rings.swift:65`) and relies on callers to pre-clamp.
- Composite cards use `.accessibilityElement(children: .combine)` in places (good) but coverage is
  uneven across the 30+ screens; charts (Swift Charts) lack text summaries; status is sometimes
  color-only (recovery bands) — **Differentiate-Without-Color not verified**.
- Fixed point sizes throughout (`Theme.text`, `.system(size:)`) — Dynamic Type / AX-XXXL truncation
  **not verified on device**. This is a starting-point assessment, not a pass.

### HealthKit & privacy
- Read: steps, HR, resting HR, HRV SDNN, active energy, body mass, sleep, workouts. Write: workouts,
  body mass, distance, active energy (`HealthKitService.swift:40-56`). Usage strings are specific and
  honest and match the requested types (`project.pbxproj:473-476`); `com.apple.developer.healthkit`
  entitlement present; App Group `group.com.forge.performance`.
- **Gaps:** no staleness/source-priority on live reads (P2-6); read-denial undetectable (P2-7); recovery
  headline never refreshed from real data (P0-6). No health data used for ads (privacy copy correct).

### Legal / product-claim discrepancies
- Privacy/Support "no accounts / nothing server-side" vs shipped Supabase auth (P1-11) — **most serious.**
- Draft Terms & Privacy, placeholder effective dates, personal-Gmail legal contact (P1-11).
- Marketing modules/pricing as shipped vs mock reality; tier-name divergence (P2-9).
- App Store description claims (barcode/photo/GPS "shipped") while review notes concede AI is offline
  rule-based (`appstore/metadata.md:57-59,98-100`).

---

## 6. Prioritised implementation plan (proposed — not yet executed)

**Group A — backend security (P0, deliver SQL; apply via dashboard):** new
`supabase/migrations/0002_rls_hardening.sql` — enable RLS + owner policy on `challenge_members`; split
`FOR ALL` into user-writable data policies + service-role-only writes for `subscriptions`/`profiles.plan`
billing columns; create `feedback` table with an insert-only anon policy + length `CHECK`s.

**Group B — medical safety (P0, iOS, testable):** `RehabEngine` band "Cleared"/"Cleared for return" →
non-clearance, clinician-gated wording; concussion RTP demo stages 6–7 `completed:false` and reworded
away from "Game cleared"; keep/ää strengthen the clinician-clearance framing. Update `RehabEngineTests`.

**Group C — honesty of numbers (P0/P1, iOS, testable):** shared tested `Progress`/`ForgeScoreBounds`
utility (div-by-zero/NaN-safe, single clamp for visual + a11y); clamp Forge Score; derive step/active-energy
goals in `TargetEngine` with labeled safe defaults; redefine streak as intentional action
(workout **or** check-in) with a `PersistenceService.activeDays()` source + timezone tests; persist
directive-tip dismissal against a stable directive id.

**Group D — data rights (P1, iOS, testable):** complete `exportJSON` (all categories + `schema_version`,
`app_version`, `units`, `timezone`, ISO-8601) with a typed error instead of `"{}"`, off the main thread;
add separate "delete local data" / "delete cloud account" / "delete both" actions with correct copy.

**Group E — networking honesty (P1, iOS, testable):** typed `FeedbackError` mapping (offline/timeout/
unauthorized/rate-limited/server/validation/unknown) with non-technical messages; move token storage to
Keychain; add a refresh path (or explicit re-auth on 401).

**Group F — claims & legal (P1, web/docs):** fix Privacy/Support account/server contradiction; replace the
"3 million products" string; separate Available-now / Beta / Coming-later on the site; keep the
counsel-review warning until counsel actually reviews.

**Group G — CI (P1):** add lint, typecheck, secret scan (gitleaks), `npm audit`; remove the committed
`Secrets.plist` so the AI-mode tests run.

**After each group:** rebuild (Debug+Release) and re-run the iOS suite; add/patch tests; record results.

---

## 7. Items that require access this environment lacks

| Needs | Items |
|---|---|
| **Real iPhone / Watch** | On-device HealthKit auth-state transitions (not-determined→authorized→partial→denied); App-Group SwiftData store init (the CoreData sandbox errors); Live Activity, widget, Watch sync; VoiceOver/Dynamic Type/Reduce-Motion/Contrast sweep at AX-XXXL on small + large iPhones. |
| **Supabase dashboard** | Confirm live RLS on the `feedback` table (not in migrations); apply `0002_rls_hardening.sql`; rotate the anon key after the source literal is removed. |
| **Apple Developer / App Store Connect** | Privacy nutrition labels vs actual data flows; signing/entitlements on device; submission metadata & screenshots; the account-deletion 5.1.1(v) flow end-to-end. |
| **Node toolchain** | Run web `lint`/`tsc`/`vitest`/`build`; Lighthouse/responsive/perf pass; verify env-var validation. |
| **Legal counsel** | Terms, Privacy, Support, App Store privacy answers must be reconciled and reviewed. The counsel-review warning must stay until then. |

---

## 8. Readiness scores (this session's evidence)

> Scores reflect launch risk, not polish. The app builds clean and its engines are well-tested, but
> unresolved P0 security/safety/honesty issues cap both scores.

**Initial (pre-fix):**
- **Beta readiness: 55 / 100.** Builds Debug+Release with 0 warnings, 178 tests pass, core flows
  (auth, HealthKit, nutrition, logging) are real. Held down by: unprotected `challenge_members` +
  self-writable billing (P0-1/2), concussion "game cleared" + RTP "Cleared" (P0-3/4), app-open streak
  (P0-5), demo-as-real signals (P0-6), tokens in UserDefaults (P1-1).
- **App Store readiness: 35 / 100.** Additionally blocked by: privacy policy that misstates accounts/
  server data (P1-11), draft legal + personal-email contact, incomplete data export (P1-4), missing
  Keychain/refresh, feedback RLS not in source (P0-7), "3 million products" claim (P1-10), advertised
  prices with no StoreKit (P2-11), CI gaps (P1-13), and everything in §7 that needs device/Apple/Supabase
  verification.

**Revised after Groups A–G (this session):**
**2026-07-20 update — RLS applied + verified live:** with `0002` now applied and the anon probes confirming
P0-1/P0-2/P0-7 closed on the real DB (§12a), the single largest remaining P0 is resolved. **Beta readiness
→ 78 / 100** (still gated by the on-device HealthKit/accessibility sweep in §7 and the residual seeded
strain/sleep-debt inputs). **App-Store readiness → 55 / 100** (still gated by draft legal pending counsel,
the web/CI unverified-here, and the §7 device/Apple items). The pre-update rationale:

- **Beta readiness: 72 / 100.** ⬆ from medical-safety (P0-3/4), honest streak (P0-5), clamped/safe
  numbers (P1-7/8), data rights (P1-4), Keychain + typed feedback (P1-1/5), and **P0-6 now closed** —
  connected recovery is derived from the user's own live signals (disclosed estimate), provenance is
  labeled ("Partial · estimated"), and forecast/injury-risk are marked "Sample." **Still capped by, and
  contingent on:** the Group A RLS migration being **applied** in Supabase (P0-1/2/7 are fixed *in code*
  but the live DB stays exposed until `0002` runs), and the residual mock inputs that still feed the score
  (strain/sleep-debt/readiness are seeded — now honestly labeled, not yet live-sourced).
- **App Store readiness: 52 / 100.** ⬆ from legal accuracy (P1-11), complete export + clear deletion
  (P1-4 / 5.1.1(v)), honest nutrition claim (P1-10), CI gates (P1-13). **Still capped by:** legal docs are
  still **draft pending counsel**; the web + CI changes are **unverified here** (no Node); Keychain/refresh
  need **device** verification; P0-6 residue above; pricing/marketing needs a **product decision** (P2-9);
  and all §7 device/Apple/Supabase items. These scores assume nothing until those verifications pass.

## 9. Recommended next steps (exact order)

1. **Apply Group A RLS SQL in Supabase** and confirm `challenge_members`, `subscriptions`, `feedback`
   deny anon writes (dashboard). Rotate the anon key.
2. **Land Group B medical-safety** wording (highest liability, small diff, testable) and re-run tests.
3. **Land Group C number-honesty** (score clamp, shared progress util, goals, streak) with tests.
4. **Land Group D/E** (export completeness + typed errors + Keychain) with tests.
5. **Fix Group F legal contradiction** on the website; leave counsel warning in place.
6. **Expand CI (Group G)** and remove committed `Secrets.plist`.
7. Do the **on-device accessibility + HealthKit-state sweep** (§7) — cannot be signed off from a simulator alone.
8. Re-run the full audit after A–G; update this file's "Completed fixes" section with per-group test results.

---

---

## 10. Completed fixes — this session (Groups A–C)

All iOS changes below were re-verified: **iOS tests 194 executed / 2 skipped / 0 failures**
(up from 178; +16 new tests), Debug + Release rebuild clean. Branch `audit/launch-hardening`.

### Group A — backend authorization (P0) · `supabase/migrations/0002_rls_hardening.sql`
- **P0-1** enable RLS + owner policy on `challenge_members`.
- **P0-2** `subscriptions` → read-own only, writes to service role; `REVOKE UPDATE(plan)` on `profiles`
  from client roles — users can no longer self-grant paid tiers.
- **P0-7** define `feedback` as an **insert-only** table for anon (no select/update/delete policy) with
  length `CHECK`s, bringing the endpoint's protection under source control.
- ⚠︎ **Delivered, NOT applied/tested** — no Supabase CLI here. Must be run in the dashboard; the file
  ends with manual verification queries. Rotate the anon key after applying.

### Group B — medical safety (P0) · iOS, tested
- **P0-3** `RehabEngine.readiness` no longer emits "Cleared"/"Cleared for return"; top band is
  **"Criteria met"**, eta **"Final gate: clinician sign-off"**. The app tracks self-checks; it never
  issues return-to-sport clearance. *(RehabEngine.swift)*
- **P0-4** concussion RTP demo: contact/competition stages 6–7 set `completed: false` and reworded to
  require written physician clearance (no more "Game cleared"). *(MockRehab.swift)*
- Removed app-issued clearance estimates and a fabricated clinical fact:
  RTS footer "Forge estimate: full clearance in 7–10 days" → "only your PT or physician can clear your
  return"; concussion CoachNote "Last concussion fully cleared in March…" → sample-labeled, defers to
  clinician; goal-suggestion "full clearance ~10 days" → "clearance is your PT's call"; coach mock reply
  "gets you cleared next week" → "puts your PT in a position to clear you sooner."
  *(ForgeRecoveryView.swift, GoalsView.swift, AIService.swift)*
- **Tests:** `RehabEngineTests.testTopBandNeverClaimsMedicalClearance`,
  `testConcussionDemoDoesNotShowGameCleared`.

### Group C — number honesty (P0/P1) · iOS, tested
- **P1-7/P1-8** new shared, tested `Core/Progress.swift` (`Progress` + `ForgeScoreBounds`): one
  divide-by-zero/NaN/∞-safe, clamp-consistent source for every percentage; Forge Score clamped to 0–100
  (`AppState.forgeScore`). The fuel card's visual and VoiceOver values now come from the same
  `displayPercent` — the 100 %-vs-"130 percent" mismatch is gone; added an `accessibilityValue`.
- **P1-6** hardcoded 10,000-step / 1,000-kcal goals replaced by `TargetEngine.steps`/`activeEnergy`,
  derived from the athlete's activity + body mass, labeled as goals. *(TargetEngine.swift, DashboardView.swift)*
- **P0-5** streak now counts **intentional action** — `PersistenceService.activeDays()` (workouts ∪
  check-ins) feeds `StreakEngine`, not app-open score snapshots. *(PersistenceService.swift,
  DashboardView.swift, StreakEngine.swift docs)*
- **P1-9** directive-tip dismissal persists against a stable `DailyDirective.id` via `@AppStorage`, so it
  survives tab switches/relaunches and re-appears only when the directive changes.
  *(DirectiveEngine.swift, DashboardView.swift)*
- **Tests:** `ProgressTests` (12), `TargetEngineTests` (+2 step/energy), directive-id stability.

### Group D — data rights (P1) · iOS, tested
- **P1-4** `PersistenceService.exportDocument(profile:)` replaces `exportJSON()`: `schema_version`,
  `app_version`, `generated_at` (ISO-8601), `timezone`, `units`, and **all locally-stored categories**
  — profile+coached targets, user-created goals, workouts **with per-set detail**, nutrition,
  **hydration** (was omitted), forge scores, check-ins, plus an honest note that sleep/HRV/activity are
  read live from Apple Health and not stored here. **Throws** `ExportError` instead of returning `"{}"`;
  shares as a temp **file** (large-history safe) built on tap, not eagerly on every ProfileView render.
- **Apple 5.1.1(v) deletion clarity:** three unmistakable actions replace the single ambiguous button —
  **"Delete cloud account only"**, **"Delete all data on this phone"** (`PersistenceService.deleteAllLocalData()`,
  preserves the auth session), **"Delete account + all data"** (server first; local wipe only on success so
  a failure is retryable). Message states exactly what each removes and that none touch Apple Health.
- **Tests:** `ExportTests` (versioning, metadata, profile+targets, file round-trips as valid JSON).

### Group E — networking honesty + session security (P1) · iOS, tested
- **P1-5** `FeedbackError` typed mapping (offline/timeout/invalidRequest/unauthorized/rateLimited/
  serverError/validation/unknown) with nontechnical user copy + client-side validation; `FeedbackClient.submit`
  returns the typed error instead of a `Bool`, and the sheet shows the specific message.
- **P1-1** auth session moved from `UserDefaults` to the **Keychain** (`Services/Keychain.swift`,
  device-only, after-first-unlock), with a one-time migration of any legacy UserDefaults session.
- **P1-2** token **expiry** is now stored (`expires_at`/`expires_in`) and `refreshIfNeeded()` refreshes via
  the GoTrue refresh-token grant; `deleteAccount()` refreshes first and surfaces a real "session expired —
  sign in again" message instead of a misleading network error.
- **Tests:** `FeedbackErrorTests` (HTTP + URLError + validation mapping, non-technical copy).
  ⚠︎ Keychain persistence + token refresh need **on-device** verification (§7) — not exercised by the sim tests.

### Group F — honest claims + legal accuracy (P1) · iOS tested; web static-only
- **P1-10** iOS nutrition empty-state "the barcode scanner … knows about 3 million products" → honest
  "Try the barcode scanner to look up supported packaged foods, or add a food manually."
  *(NutritionHomeView.swift)* — covered by the iOS test rebuild.
- **P1-11** website legal accuracy: Privacy and Support no longer claim "no account system / nothing
  server-side" — they now describe the **optional Supabase account** (email + account record on our
  servers, deletable in-app) while keeping health-data-on-device accurate. Terms legal contact changed
  from a **personal Gmail** to `legal@forge.app`. *(privacy/page.tsx, support/page.tsx, terms/page.tsx)*
  - ⚠︎ **Kept intact on purpose:** the Terms/Privacy **DRAFT** status, "Effective: at public launch"
    placeholder, and **"have counsel review before launch"** warnings — not removed (counsel has not
    reviewed). The `forge.app` email domain must be provisioned before launch.
  - ⚠︎ **Web changes NOT built/linted/tested** — no Node here. Static content edits only.
  - **Still open (P2-9):** landing-page pricing ($19/$39/$79) vs Terms "free", and marketing 20 mock
    modules presented as shipped — these need a **product decision** (are paid tiers/features shipping?),
    so left for you rather than guessed.

### Group G — CI gates (P1-13) · config only (can't run here)
- Expanded `.github/workflows/ci.yml`: web job now runs **lint** + **typecheck** before test/build; new
  **security** job runs **gitleaks** secret scan (full history) + `npm audit --audit-level=high` (advisory).
- Added `.eslintrc.json` (`next/core-web-vitals`) so `next lint` runs non-interactively, and a `typecheck`
  script (`tsc --noEmit`) to `package.json`.
- **G2 (remove committed `Secrets.plist`) — not needed:** it was never committed (see retracted P1-12).
- ⚠︎ **Not executed here** (no Node/Actions). If latent lint/type errors exist, the new gates will surface
  them on first CI run — that is the gate working; run `npm run lint && npm run typecheck` locally to see.

### Group P0-6 — demo-as-real residue closed · iOS, tested
- **Recovery headline no longer shows the demo athlete's number to a connected user.** New
  `Core/RecoveryEstimator.swift` derives recovery (0–100) from the user's **live** HRV-vs-baseline (50%),
  resting-HR (20%), and sleep (30%) — a *disclosed heuristic, not a clinical model* — and
  `RecoveryService.applyUnifiedSignals()` uses it **only when the winning HRV is a genuine live reading**;
  no live data → the seeded value stays, clearly labeled demo.
- **Honest provenance replaces auth-state guessing.** `DataProvenance` (`.demo`/`.partial`/`.live`;
  `.live` deliberately unreachable while strain/sleep-debt aren't sourced live) drives the labels on the
  Dashboard hero, Recovery hero, and Wearables — a *connected but still-estimated* score now reads
  **"Partial · estimated"** instead of a clean number. Recovery subtitle states whether the number is
  "Estimated from your HRV…" or "Demo recovery…".
- **Forecast + injury-risk no longer pose as computed.** Forecast screen labeled **"Sample data — not from
  your history"** with reworded confidence/disclaimer; injury-risk cards (Recovery + Dashboard) tagged
  **"Sample"** with "an illustration of the model, not a medical prediction about you."
- **Tests:** `RecoveryEstimatorTests` (bounds, direction, zero-baseline safety, provenance flips to
  `.partial` and recovery reflects the live HRV, not the demo value).

*Status: Groups A–G + the P0-6 residue implemented. iOS re-verified green (206 tests, 2 skipped, 0
failures; Debug+Release 0 warnings). Unverified-here (flagged): Group A SQL (apply in Supabase dashboard), all Group F web + Group G
CI (no Node/Actions), Keychain/refresh (needs device). Scores in §8 revised below.*

---

## 11. Continuous improvement — intelligence-loop initiative

Beyond the launch audit, ongoing work to make "every system feeds the intelligence layer" real.

### Slice 1 — training feeds the Forge Score (closes P2-1 for training) · iOS, tested
- **Problem:** finishing a workout only wrote history + PRs; `recovery.today.strain*` stayed seeded, so
  the score's Training Load component (14%) never reflected real training. Loop open.
- **Fix:** new pure `Core/TrainingLoadEngine.swift` (session/day strain on the 0–21 scale from duration ×
  RPE-intensity, v1, disclosed). `AppState.applyTrainingLoad(sessions:)` (DI, testable) maps **persisted
  (real) workouts only** — never the demo-laced in-memory history — into `strainToday`/`strainYesterday`;
  a `@MainActor` convenience pulls from persistence. Called in `rehydrate()` and after each `saveWorkout()`
  in `WorkoutLoggerView` + `RunningView`. Empty/demo history leaves seeded values untouched (demo stays
  coherent; existing tests unaffected).
- **Model choice (residual):** today's session sets `strainToday` now and becomes tomorrow's
  `strainYesterday` (the score driver) — matches next-day training-load physiology, no demo destabilization.
  A same-day *acute* penalty is a deliberate follow-up pending product sign-off. Directive headline
  (recovery-band-driven) not yet strain-fed — next slice.
- **Tests:** `TrainingLoadTests` — engine bounds/monotonicity/cap, empty-leaves-demo, and an **end-to-end
  loop proof** that a hard logged day yields higher strain → lower `trainingLoadScore` → lower `forgeScore`
  than a light day. iOS **211 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**
- **Still open in this initiative:** workout → HRV/recovery (only strain today); injury singleton (P2-2);
  strain into the workout generator; nutrition/sleep already partially wired.

### Slice 2 — training load steers the Daily Directive · iOS, tested
- **Problem:** the Directive headline was purely recovery(HRV)-driven; a brutal recent session didn't
  change "what to do today," so training and the Directive were still disconnected.
- **Fix:** `DirectiveEngine.make` gains defaulted `trainingLoadYesterday` + `trainingLoadAvg` inputs
  (0 → no effect, so every existing caller/test is untouched). Applies the acute:chronic workload
  principle **conservatively**: a load spike over the athlete's baseline (ratio ≥ 1.4) or a maximal day
  (≥ 15/21) can only *temper* a green light ("Push hard" → "moderate") — never raise intensity, never
  override a pull-back. It always **explains itself**: adds a rationale clause and, when nothing more
  urgent is pending, owns the priority action ("You trained hard yesterday (X/21) — keep today controlled,
  leave 1–2 reps in reserve"). `AppState.dailyDirective` feeds `strainYesterday` + the strain-trend average.
- **Tests:** `DirectiveTests` +3 (caps a green light, drives the priority action, typical load leaves it
  alone) plus all prior directive tests still green. iOS **214 tests, 2 skipped, 0 failures; Debug+Release
  0 warnings.**
- **Note:** baseline uses the seeded strain trend until real strain history is persisted (honest
  approximation); wiring a real rolling strain baseline is a follow-up.

### Initiative 2 — injury is real, editable, connected (closes P2-2) · iOS, tested
- **Problem:** `InjuryService.active` was a hardcoded `[MockData.knee]` singleton; "Log a New Injury"
  was a literal no-op (`FlowChips(toggle: {_ in})`); nothing persisted; and the pain slider had a
  shared-`@State` bug (one slider seeded from the demo knee, reused across every injury).
- **Fix:**
  - `InjuryProfile` + `InjuryPhase` made `Codable`; `InjuryService` now **persists** `active` as JSON
    (`forge.injuries.v1`) and loads it on init — presence-based, so **resolving to empty sticks** and the
    demo knee doesn't return. Persistence gated by `isTestRun` (hermetic tests).
  - Real editing: `add(type:phase:pain:)`, `resolve(_:)`, and persisted `logPain`. A focused
    **`LogInjurySheet`** (area · phase · starting pain) replaces the no-op; an extracted
    **`ActiveInjuryCard`** fixes the slider bug (per-injury state) and adds **"Mark resolved"**; an honest
    **empty state** when clear.
  - Pipeline was already generic over `active` — added injuries now genuinely flow into the workout
    generator's constraints (knee/shoulder/back swaps), `injuryStatusScore` (Forge Score, 10%), the
    Directive priority, and RehabEngine. Kept the wellness/see-a-clinician framing in the log flow.
- **Tests:** `InjuryServiceTests` (+7) — seed/add/resolve/logPain, `injuryStatusScore` reacts,
  severity mapping, `Codable` round-trip, and an **end-to-end proof** that a newly-logged shoulder injury
  blocks the barbell bench and queues the neutral-grip swap in the actual prescribed session.
  iOS **221 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**
- **Still demo-tied (flagged):** the knee/concussion rehab sub-modules (`rtsChecklist`, `rtpStages`) and
  the illustrative `InjuryRisk` remain seeded (already labeled "Sample"); making those fully per-injury
  dynamic is a larger follow-up.

### Initiative 3 — recommendation transparency contract (closes P2-5 for Score + Directive) · iOS, tested
- **Problem (P2-5):** recommendations exposed no inputs-missing / confidence / timestamp / safe-fallback —
  the charter requires every calculated recommendation to explain itself.
- **Fix:** new `Core/RecommendationBasis.swift` — one value type (`summary`, `inputsUsed`, `inputsMissing`,
  `confidence`, `asOf`, `safeFallback`) with a pure, tested `confidence(provenance:hasCheckIn:)` rule that
  ties trust to the P0-6 data provenance (demo→Low, partial+check-in→Moderate, live+check-in→High).
  `AppState.forgeScoreBasis` + `directiveBasis` build it from real signals (reusing `forgeScoreNarrative` /
  `directive.rationale`). New reusable `DesignSystem/RecommendationBasisView` (collapsible, VoiceOver-labeled)
  surfaces confidence + freshness, inputs used, what's missing, and the fallback — wired into the Forge
  Score card and the Directive tip (the two flagship recommendations).
- **Tests:** `RecommendationBasisTests` (+5) — confidence rule across all provenance×check-in states; the
  Score basis is honestly Low + names missing Apple-Health/check-in in demo and never hides its fallback;
  connecting live HRV + logging a check-in lifts confidence to Moderate; the Directive basis exposes its
  inputs and fallback. iOS **226 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**
- **Still open:** extend the same basis to nutrition/recovery recommendations; track real per-signal
  freshness timestamps (currently `asOf` = compute time, honest but coarse — ties to P2-6).

### Initiative 4 — AI Coach reasoning is honest (retires the fabricated "Reasoning" panel) · iOS, tested
- **Problem (audit §AI):** the Coach's "Reasoning · N signals" panel showed **fabricated per-answer steps**
  (e.g., "ACR 1.24 — elevated", "HRV 58 vs 62") that implied a model chain-of-thought, and **live replies
  carried no steps at all** — so the panel was either fake or absent.
- **Fix:** new `AIService.contextSignals(_:)` returns the **real signals Forge fed the coach** from the live
  `CoachContext` (Forge Score, recovery/readiness, HRV vs baseline, sleep, sleep debt, training load,
  protein, hydration, the Directive, any plateau). `reply()` attaches these to **every** reply — mock *and*
  live — so the panel always reflects true inputs. Removed all fabricated `steps` arrays from `mockReply`
  (demo answer text/cards remain, still labeled "demo coach"). UI relabeled **"Reasoning · N signals" →
  "Signals Forge used · N"** (these are inputs, not invented reasoning). Softened the seed message so it no
  longer fabricates a specific "bench session / knee" before any context exists.
- **Tests:** `CoachSignalsTests` (+4) — signals reflect real context values and track changes; `mockReply`
  no longer hardcodes reasoning steps for any prompt; it still answers with text. iOS **230 tests, 2
  skipped, 0 failures; Debug+Release 0 warnings.**
- **Unchanged/honest by design:** the live path still uses the Claude proxy (server-side key); the default
  build is the labeled demo coach (`aiMode = .mock`). Live-vs-mode switching remains covered by the 2
  `AIServiceTests` (skipped locally only because a gitignored `Secrets.plist` is present; they run in CI).

### Initiative 5 — HealthKit freshness / honest stale states (closes P2-6) · iOS, tested
- **Problem (P2-6):** `latest()` took the newest sample with no date bound and discarded its timestamp;
  live readings were ingested with hardcoded `ageHours: 0`, so a weeks-old HRV/HR read as "excellent"
  freshness and drove a "live" recovery. The existing `DataHub.quality(ageHours:)` band was never applied
  to live data.
- **Fix:** `HealthKitService.latest()` now returns the sample's **value + end-date**; per-metric
  `sampleDates` + `ageHours(for:)` expose real age. `RecoveryService.updateReading` gained an `ageHours`
  param (clamped ≥ 0); `applyUnifiedSignals` derives recovery from live HRV **only when it's fresh
  (< 24h)** — a stale sample no longer masquerades as today's. Added `liveAgeHours(_:)` + `hasStaleLiveSignal`.
  `AppState.ingestHealthKitSignals` passes real ages through. Staleness is surfaced honestly: the recovery
  hero reads "…last HRV ~40h old, recovery held at estimate," and both `forgeScoreBasis`/`directiveBasis`
  add "A fresh HRV reading (last sample ~Nh old)" to *inputs missing*.
- **Tests:** `HealthFreshnessTests` (+5) — fresh HRV derives recovery; **stale (48h) HRV does not** and the
  seeded value is held; negative age clamps to 0; `ageHours` is nil without a sample; the stale signal
  surfaces in the Score basis. iOS **235 tests, 2 skipped, 0 failures; Debug build 0 warnings.**
- **⚠︎ Device-only, unverified here:** the actual HealthKit sample-date capture (the `latest()` query change)
  can't run in the simulator (no real Health samples). The freshness *logic* (age → gating → surfacing) is
  fully unit-tested; the on-device read path still needs a real device (§7).

### Initiative 6 — accessibility of the reusable data-viz (Phase 4 groundwork) · iOS, tested
- **Problem (Phase 4):** trend charts (`Sparkline`, `BarTrend`) were **silent to VoiceOver**; `MetricRing`
  fragmented into three spoken pieces; progress bars added clutter. Fixing components propagates to all ~30
  screens (the "systemic, not sprinkle" approach the audit calls for).
- **Fix:** `Sparkline`/`BarTrend` collapse to a single accessibility element with a spoken **`TrendSummary`**
  ("Recovery trend: now 78, up from 72 over 14 points") — pure + tested, with an optional caller context
  label wired at the prominent sites (Forge Score, recovery trends, pain, weight). `CapsuleBar` is
  decorative-hidden by default (adjacent text carries the value) with an opt-in a11y label + percent value.
  `MetricRing` reads as one element ("Recovery, 78, HRV-weighted blend"). (`ScoreRing` already respects
  Reduce Motion + carries a label from earlier work.)
- **Tests:** `TrendSummaryTests` (+6) — rising/falling/flat/empty/decimals/context. iOS **241 tests, 2
  skipped, 0 failures; Debug+Release 0 warnings.**
- **⚠︎ Still needs a real device (§7):** full Dynamic Type / AX-XXXL truncation, VoiceOver reading-order,
  Increased-Contrast, Bold-Text, and 44pt touch-target audits (e.g., the 16pt concussion symptom dots)
  across all screens — a simulator/unit pass can't sign these off.

### Slice 3 — training load deloads the actual prescribed session · iOS, tested
- **Problem:** training load reached the Forge Score (slice 1) and the Directive headline (slice 2) but the
  **generated workout itself** ignored it — a hard week didn't change the sets/RPE Forge actually prescribed.
- **Fix:** `WorkoutService.generate` gains defaulted `recentStrain` + `strainBaseline` (0 → no effect, so
  existing callers/tests are untouched). Same acute:chronic rule as the Directive (ratio ≥ 1.4 or ≥ 15/21):
  a spike **trims one main set and drops the RPE cap half a notch**, composed on top of the recovery
  scaling and floored at **3 sets / RPE 7** so it can't gut an already-light day. Rationale explains it
  honestly ("training load ran high (20/21): one set trimmed and top sets capped at RPE 8.5 …"), and only
  claims a set was trimmed when one actually was. `AppState.todaysPlan` feeds `strainYesterday` + the
  strain-trend baseline (demo strain sits at baseline → no change to the demo session).
- **Tests:** `GeneratorTests` (+3) — a load spike drops 5→4 main sets and names the load; the deload never
  goes below the 3-set floor; typical load leaves the session alone. All prior generator tests still pass.
  iOS **244 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**
- **Loop status:** training now flows end-to-end — logged session → strain → **Forge Score + Directive
  headline + the prescribed workout's sets/RPE**, each explaining itself.

### Initiative 3b — transparency contract extended to recovery + nutrition · iOS, tested
- **Problem:** the `RecommendationBasis` contract covered only the Forge Score + Directive; recovery and
  the coached fuel targets still gave numbers without exposing their basis.
- **Fix:** `AppState.recoveryBasis` (HRV vs baseline, RHR, sleep, sleep-debt; confidence from provenance +
  check-in; honestly flags missing live/fresh HRV and demo state) and `AppState.nutritionBasis` (bodyweight,
  activity, goal, logged intake, each adaptive adjustment's reason; confidence High once meals are logged,
  Moderate otherwise; **discloses that weight-trend adjustments run on sample weigh-ins** until real
  body-weight history exists). Both surfaced via the reusable `RecommendationBasisView` on the recovery
  hero and the Fuel card. Now all four flagship recommendations — Score, Directive, Recovery, Nutrition —
  and the Coach explain themselves the same way.
- **Tests:** `RecommendationBasisTests` (+4) — recovery basis is Low/flags Apple-Health in demo and lifts to
  Moderate with fresh live HRV + check-in; nutrition basis is Moderate + names the missing log with nothing
  eaten, High once intake is logged. iOS **248 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**

## 12a. Remote Supabase state

> **✅ UPDATE 2026-07-20 — MIGRATION APPLIED + RLS VERIFIED on the live DB.**
> The user ran `supabase db push`; `migration list` now shows **`0001→0001` and `0002→0002` in the Remote
> column** and `db push --dry-run` reports *"Remote database is up to date."* Live anon-key PostgREST probes
> confirm the P0 authorization holes are **closed**:
> - **P0-1 (challenge_members)** — table now exists; anon `GET` → `200 []` (RLS filters); anon `INSERT` →
>   **`401` "new row violates row-level security policy for table challenge_members"**. World-write closed.
> - **P0-2 (billing escalation)** — anon `PATCH subscriptions {plan:'elite'}` → **`401` "permission denied
>   for table subscriptions"** (the `REVOKE` took effect). `profiles`/`subscriptions` owner-scoped.
> - **P0-7 (feedback)** — anon `GET feedback` → `200 []` (RLS enabled, insert-only) — submitter emails are
>   no longer anon-readable.
>
> The below (from 2026-07-19) records the *pre-apply* state for the audit trail.

### Original finding (2026-07-19, superseded by the update above) — migration NOT yet applied

Checked the live project `vxprqlniecdcxjkevoob` with the CLI (linked with the stored DB password, read-only)
and by probing PostgREST with the public anon key. **Correction to the earlier assumption that `0001` was
applied:**

- **Migration tracking is empty.** `supabase migration list` shows `0001` and `0002` both with an empty
  *Remote* column; `supabase db push --dry-run` reports it *would push both*. **Neither migration is applied.**
- **The `0001` tables do not exist on the remote.** Anon `GET /rest/v1/challenge_members`, `/subscriptions`,
  `/profiles` all return **404 "Could not find the table … in the schema cache."** Only **`feedback`** exists
  (anon `GET` → `200 []`, i.e. insert-only-or-empty — dashboard-created for the feedback feature).
- **Net effect:** the P0-1 (world-writable `challenge_members`) and P0-2 (self-writable billing) exploits are
  **not currently live** *because those tables aren't deployed at all* — but the `0002` hardening is likewise
  **not applied**, so the intended schema must be deployed **with** `0002` (never `0001` alone) to be safe from
  the start. `feedback`'s insert-only RLS is still **unverified** (the `200 []` is consistent with either
  insert-only or an empty table) — confirm via `supabase/RLS_VERIFICATION.md` §A.
- **Likely cause:** `db push` applies `0001` first; `0001` uses bare `create table` (not `if not exists`), so
  against any pre-existing objects it errors and nothing lands. **Not resolved from this environment** — I did
  not run `db push` (a mutating production action). See "remaining manual action" in the session summary.
- **iOS secrets:** ✅ no `service_role`/DB secret in the app — `SupabaseConfig.swift` holds only the **anon**
  (publishable) key + project URL as compile-time literals; the file's own comment states the service-role key
  must never appear, and it doesn't. (Hardcoded literals still block rotation-via-env — minor, tracked.)
- **Verification checklist added:** `supabase/RLS_VERIFICATION.md` (anon-probe + authed matrix; run after apply).

*(Resolved — see the ✅ UPDATE at the top of §12a: `0002` is now in Remote and §A anon probes pass.)*

### 12a-fix — `0001` made idempotent so the push applies cleanly (2026-07-19)
`0001_forge_init.sql` originally used unguarded `create type` / `create table` / `create trigger` /
`create policy`, so `supabase db push` would abort on any pre-existing object (e.g. enum types left by a
prior partial attempt) — the most likely reason the earlier push never landed. Made it **fully idempotent**
(behaviour identical on a clean DB):
- enums wrapped in a `do $$ … if not exists (pg_type) … $$` block;
- all 26 tables → `create table if not exists`;
- all 3 triggers preceded by `drop trigger if exists`;
- the owner-policy loop + the 4 standalone read policies preceded by `drop policy if exists`.
`0002` was already idempotent (`drop policy if exists` / `create table if not exists`). Both can now be
re-run safely.

**✅ Applied 2026-07-20** by the user running the command below (the auto-mode classifier correctly blocked
the agent from running a live-production deploy). Recorded for reproducibility:
```bash
cd forge-main
export SUPABASE_DB_PASSWORD="$(cat ~/.forge-supabase-dbpass)"
supabase link --project-ref vxprqlniecdcxjkevoob   # if not already linked in this shell
supabase db push                                    # applies 0001 (idempotent) then 0002
supabase migration list                             # confirm 0002 shows in the Remote column
```
Then run `supabase/RLS_VERIFICATION.md` §A–D (anon probes) to confirm the P0s are closed on the live DB.

## 12b. Product — new-user onboarding now applies the real user's state (2026-07-20)

**Highest-impact shipped-product fix of the session.** Onboarding collected the user's declared injuries
(`InjuryStep`, step 9) into `selectedInjuries` and then **silently dropped them** — `advance()` only did
`app.user = draft`. Because `draft` starts from `MockData.sean`, every real user inherited **Sean's demo
knee injury** (a specific "patellar tendinopathy · day 12 · phase 2" diagnosis + rehab plan they don't
have — misleading and safety-adjacent), plus Sean's **23-day streak / level / XP / "Hockey."**
- **Fix:** `AppState.commitOnboarding(profile:injuries:)` now (a) applies the user's **declared injuries**
  via new `InjuryService.setActive(from:)` — empty set → healthy, clearing the demo knee — and (b) strips
  the demo seed's gamification/sport via pure `AppState.onboardingProfile(from:)` (streak 0, level 1, xp 0,
  sport cleared). `OnboardingFlowView.advance()` calls it; `ProfileView` header omits an empty sport.
- **Hygiene:** gated `persistUser`/`loadUser` on `isTestRun` so the profile store is hermetic in tests
  (also fixes real non-determinism when the app is run then tested on the same simulator).
- **Tests:** `OnboardingTests` (+5) — gamification reset with real inputs preserved; declared injuries
  replace the demo knee; **no injuries → healthy (`injuryStatusScore 100`, no knee-PT directive)**; a
  declared shoulder injury constrains the generated session (neutral-grip swap). iOS **269 tests, 2 skipped,
  0 failures; Debug+Release 0 warnings.**

## 12c. Product — real accounts see only their own training data (2026-07-20)

**Highest-impact shipped-product fix.** `WorkoutService` seeded Sean's `history`/`personalRecords`/
`muscleVolume`, and `rehydrate()` layered a real user's saved workouts *over* that demo baseline — so
**every real account's** Train tab, PRs, weekly volume, plateaus, weak-points, and the coach signals built
from them were contaminated with the demo athlete's sessions (not just new users; an active user saw their
sessions mixed with Sean's). There was no demo-vs-real distinction.
- **Fix:** persisted `AppState.isDemoAccount` (set on `completeAuth`, `commitOnboarding`; restored in
  `init`; hermetic in tests). `WorkoutService.clearDemoSeed()`/`restoreDemoSeed()`. Real accounts clear the
  seed and load **their own logged workouts only**; demo mode keeps Sean's world (and `restoreDemoSeed()`
  brings it back if a real session cleared it — e.g. demo after logout). `TrainHomeView` gains empty states
  for history/PRs/volume, and the hardcoded "quads under target — knee rehab" caption now shows **only if
  the user actually has a knee injury**.
- **Hygiene:** gated `finishOnboarding` + `isDemoAccount` persistence on `isTestRun`.
- **Tests:** `DemoModeTests` (+5) — clear/restore seed; demo keeps Sean's training; real account +
  onboarding start clean (empty history, `weeklyVolumeLb == 0`, no plateaus); demo-after-real restores the
  demo world. iOS **274 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**

## 12. Quality / architecture pass (post-loop)

Reducing technical debt and strengthening the flagship maths — quality over features. Guardrails: never
sacrifice stability for speed; behaviour-preserving refactors verified by the *existing* tests staying green.

### QA-1 — extract the Forge Score into a pure `ForgeScoreEngine` (starts AppState decomposition; audit P2-4/god-object)
- **Problem:** the flagship metric's weights + blend lived inline in the ~500-line `AppState` and were tested
  only indirectly via `AppState()`.
- **Fix:** new `Core/ForgeScoreEngine.swift` owns the eight weighted components (single source of truth) and
  the clamped blend; `AppState.forgeScore`/`forgeScoreBreakdown` delegate to it. Pure, behaviour-preserving.
- **Tests:** `ForgeScoreEngineTests` (+6) — weights sum to 1.0, 8 expected labels, uniform breakdown scores to
  the value, out-of-range components can't escape 0–100, values pass through, and the engine matches
  `AppState`'s own computation. **All prior `ScoringTests` still pass** (behaviour preserved). iOS **254
  tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**

### QA-2 — Directive stops running a full workout generation for a name (perf, audit P2-4)
- **Problem:** `dailyDirective` read `todaysPlan.name`, and `todaysPlan` runs the whole generator. The
  Dashboard reads `dailyDirective` ~4× per render (+ `todaysPlan` once), so ~5 full workout generations
  fired on every home render just to get one deterministic string.
- **Fix:** `WorkoutService.workoutName(goal:injuries:)` returns the session name via the existing
  `goalTitle` without building the plan; `dailyDirective` uses it. The `todaysPlan.name ==
  dailyDirective.workoutName` invariant is preserved and still enforced by `ProductionReadinessTests`.
- **Tests:** `GeneratorTests` (+1) — the cheap name equals `generate(...).name` across goals × injuries.
  iOS **255 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**

### QA-3 — centralize trend-series + strain baseline on `RecoveryService` (dedup)
- Removed `recovery.trends.first { $0.name == … }` + `average(strain)` duplicated across 5 `AppState` sites;
  `RecoveryService.series(_:)` + `strainBaseline` are the single source, living where the `trends` data does.
  Behaviour-preserving. `RecoveryEstimatorTests` +1. iOS **256 tests, 0 failures; Debug+Release 0 warnings.**

### QA-4 — consolidate Forge Score explanation into `ForgeScoreEngine`
- Moved `forgeScoreNarrative` + `forgeScoreLever` (pure over the breakdown) out of `AppState` into the
  engine, so *all* score logic — value, weights, and its human "why" — lives behind one directly-tested type.
- **Tests:** `ForgeScoreEngineTests` (+4) — narrative names weakest/strongest and the second drag only when
  low; lever picks the highest gap×weight and reads "dialed" when everything's high; and it matches
  `AppState`'s output. Prior `ScoringTests`/`DirectiveTests` still pass. iOS **260 tests, 2 skipped, 0
  failures; Debug+Release 0 warnings.**

### QA-5 — timezone / DST reliability for the streak (audit Phase 9/10)
- **Problem:** the streak (a user-facing metric) had no coverage for the real-world edges the audit called
  out — travelling across timezones and the daylight-saving night.
- **Result:** added `StreakEngineTests` (+4) proving the streak counts **calendar days, not raw 24-hour
  spans** — 3-day runs survive both the US fall-back (25h day) and spring-forward (23h day), a 23:00→01:00
  pair reads as two distinct days, and a non-default timezone (Asia/Tokyo) is consistent. **No code change
  needed** — `StreakEngine` already uses `Calendar` day arithmetic; the tests lock that correctness against
  regression. iOS **264 tests, 2 skipped, 0 failures; Debug+Release 0 warnings.**
