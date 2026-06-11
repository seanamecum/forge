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
  App/            ForgeApp (@main) · AppState (@Observable god-object: user, phase,
                  tab, services, Forge Score engine) · RootView (welcome→onboarding→main)
                  · MainTabView (custom 5-tab bar, gold Coach center)
  Theme/          Theme (obsidian/gold/cream tokens, serif display font) ·
                  Components (Card, Chip, StatTile, buttons, bars, ScreenScaffold) ·
                  Rings (animated ScoreRing) · ChartViews (Swift Charts sparklines,
                  bar trends, sleep-stage bar)
  Models/         UserProfile, Exercise, Workout/WorkoutSet/LoggedExercise, Food/
                  FoodEntry/Supplement/DeficiencyAlert, RecoveryData/SleepData/
                  WearableDevice, InjuryProfile/PTExercise/RehabProtocol/RTPStage,
                  BloodworkMarker/BodySnapshot/Forecast, SocialPost/Challenge/Badge/
                  Mission/Team, CoachMessage, ForgeNotification
  Mock/           MockData (Sean's world) · MockExercises (19 exercises + history/PRs)
                  · MockRehab (PT library, 4 protocols, concussion, RTS, risk model)
  Services/       Auth · HealthKit (real reads w/ mock fallback) · AI (coach brain) ·
                  Workout (incl. generator logic) · Nutrition · Recovery · Injury ·
                  Social · Marketplace · Notification — all @Observable, all owned by
                  AppState, all swappable for networked implementations
  Features/       Auth · Onboarding (14 steps) · Dashboard · Coach · Train (logger w/
                  rest timer, exercise DB, AI generator, form analysis) · Nutrition
                  (food log, barcode/photo sims, micros, deficiencies, supplements) ·
                  Recovery (sleep stages, trends, wearables, FORGE RECOVERY injury/PT)
                  · Health (bloodwork, body, digital twin) · Social (feed, groups,
                  compete, achievements) · Market (marketplace, teams) · Profile
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
