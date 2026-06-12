# ◆ FORGE — iOS

The native SwiftUI implementation of Forge, the AI human performance operating system.
Sibling of the Next.js web prototype at the repo root — same brand, same product thesis,
rebuilt as a real iOS app.

## Run it

1. **Requirements:** macOS with **Xcode 16+** (the project uses filesystem-synchronized
   groups, `objectVersion 77`). iOS 17.0 deployment target.
2. Open `ios/Forge/Forge.xcodeproj`.
3. Select any iPhone simulator → **Run**. No signing team needed for Simulator.
4. On the welcome screen, tap **"Explore the demo →"** to drop straight into Sean's
   fully-populated world, or walk the 14-step onboarding.

To run on device: select your team under Signing & Capabilities (HealthKit entitlement
is already configured and works with free personal teams).

## Architecture

```
Forge/
  App/            ForgeApp (@main, SwiftData container) · RootView · MainTabView
  Core/           AppState (@Observable: user, phase, services, Forge Score engine)
    Mock/         MockData (Sean's world) · MockExercises · MockRehab
    Persistence/  SwiftData @Model records (User, Goal, Workout, NutritionEntry,
                  Recovery, Sleep, ScoreRecord) + PersistenceService helpers
  DesignSystem/   Theme tokens · Components (Card, Chip, StatTile, buttons, bars,
                  ScreenScaffold) · Rings · ChartViews (Swift Charts) ·
                  StateViews (LoadingStateView, EmptyStateView, ErrorBanner)
  Models/         Domain structs: UserProfile, Exercise, Workout, Food, RecoveryData,
                  InjuryProfile, BloodworkMarker, SocialPost, CoachMessage, …
  Services/       Auth · HealthKit (8 read types + workout/body-mass writes, denial
                  handling, mock fallback) · AI (coach brain) · Workout (generator) ·
                  Nutrition · Recovery · Injury · Social · Marketplace · Notification
  ViewModels/     CoachViewModel (chat orchestration)
  Features/       Auth · Onboarding (14 steps) · Dashboard · Coach · Goals (SwiftData
                  CRUD) · Train (logger → SwiftData + HealthKit write, exercise DB,
                  AI generator, Running, form analysis) · Nutrition · Recovery
                  (sleep, wearables, FORGE RECOVERY injury/PT) · Health (bloodwork,
                  body, digital twin) · Social · Market · Profile (Free/Pro/Elite)
  Utilities/      Shared extensions (clamped, date labels)
ForgeTests/       ScoringTests · GeneratorTests · WorkoutMathTests ·
                  HealthKitServiceTests — run with ⌘U
```

**Navigation:** 5 primary tabs per Apple HIG — Home, Train, Coach (center), Fuel,
Recover. Health, Body, Forecast, Social, Compete, Achievements, Marketplace, Teams,
Wearables, and Form Analysis are first-class screens reached from the Home modules
grid; Profile and Notifications from the Home header. Nothing in the spec was cut —
it's organized the way a shipping iOS app would be.

## The demo story (Sean)

Sean Calloway, 21 — hockey athlete, 6'3" / 200 lb, intermediate, lean-bulking.
Bench 180 · Squat 230 · Deadlift 280. Recovery 78, sleep 7.2 h, 23-day streak,
**left patellar tendinopathy, day 12, rehab phase 2 of 4**.

Every module reflects that one state: the generator swaps squats for hip thrusts and
tempo leg press; the coach explains the bench plateau via RPE 9+ streaks and short
sleep; deficiency detection flags Mg/D/Omega-3, which bloodwork corroborates (D at
26 ng/mL) and the supplement tracker shows unlogged; the digital twin projects
bench 225 by Nov 6 and injury risk falling 22% → 9% if volume holds flat.

## HealthKit

`HealthKitService` requests read access to steps, heart rate, active energy, body
mass, and sleep, then live-reads the first four via `HKStatisticsQuery`/`HKSampleQuery`
wrapped in async/await. Everything is mock-seeded so the app behaves identically when
Health data is unavailable or denied. Entitlement + Info.plist usage strings are
configured in the target build settings.

## Backend integration path

- **Auth:** `AuthService` async signatures are Supabase/Firebase-shaped — replace bodies.
- **Data sync:** every `@Observable` service owns its domain; introduce a repository
  beneath each and the views never change.
- **AI:** `AIService.reply(to:)` is the single seam — swap the rule engine for a Claude
  API call with the same `CoachMessage` (text + reasoning steps + cards) contract.
- **Push:** `NotificationService` already requests UNUserNotificationCenter permission.
- **Subscriptions / analytics / crash reporting:** placeholder card in Profile;
  add StoreKit 2 + your SDK of choice at the AppState layer.

## Disclaimers

Medical disclaimers ship in: onboarding injury step, Forge Recovery (every tab),
concussion module (emergency-signs card), bloodwork, deficiencies, form analysis,
forecast, and Profile → Medical Disclaimer. Educational guidance wording throughout.
