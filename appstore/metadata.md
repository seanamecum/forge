# Forge — App Store Connect Metadata

Ready-to-paste listing content. Placeholders that need real URLs/accounts are
marked `TODO`.

---

## App Information

| Field | Value |
|---|---|
| Name | **Forge: Performance OS** |
| Subtitle (30 chars) | `Your AI performance coach` |
| Bundle ID | `com.forge.performance` |
| Primary category | Health & Fitness |
| Secondary category | Sports |
| Age rating | 4+ (no objectionable content; health guidance is educational with medical disclaimers) |
| Price | Free (subscription tiers post-launch) |

## Promotional Text (170 chars, updatable without review)

> Forge turns your wearable data into one daily plan: what to train, what to eat, how to recover — with the reasoning behind every call. One brain, every device.

## Description

**Forge is the operating system for human performance.**

Stop juggling a recovery app, a workout tracker, a nutrition log, and a rehab
plan. Forge connects the tools you already use — Apple Watch, Apple Health,
WHOOP, Garmin, Oura, Fitbit, Polar, and smart scales — and turns their data
into one clear answer every morning: **what should I do today to improve?**

**TODAY'S DIRECTIVE**
One card with your whole day: training intensity, calories and protein,
mobility or PT work, the supplement you're missing, and tonight's sleep
target — with the reasoning stitched from your live signals, never generic
advice.

**FORGE SCORE**
A single 0–100 readout built from sleep, HRV recovery, nutrition, hydration,
training load, activity, stress, and injury status. See exactly what's
raising it, what's dragging it, and the single highest-leverage fix.

**AI COACH**
Ask anything — "Should I deload?", "Why is my recovery low?", "How do I hit
225 on bench?" — and get answers grounded in your actual numbers: your HRV
trend, your protein pace, your rehab phase, your forecast.

**ONE ECOSYSTEM, EVERY DEVICE**
Forge unifies your stack instead of replacing it. When two devices disagree,
you choose the preferred source; when one stops syncing, Forge falls back
automatically. Your WHOOP recovery, Garmin training load, and Apple Watch
sleep finally work together.

**EVERYTHING ELSE YOU'D NEED FIVE APPS FOR**
• Workout logging with PR detection, and an AI generator that trains around
  your injuries
• Nutrition, macro, micronutrient, supplement, and hydration tracking
• Recovery and sleep analysis with trend charts
• Injury rehab with phased PT plans and return-to-sport readiness
• Bloodwork insights explained in performance terms
• Forecasting: see where your lifts, weight, and recovery are heading
• Teams, challenges, and a curated coach & program marketplace

Forge provides educational guidance, not medical advice.

## Keywords (100 chars)

`recovery,HRV,whoop,garmin,oura,workout,AI coach,nutrition,sleep,readiness,rehab,performance`

## URLs

| Field | Value |
|---|---|
| Support URL | TODO — e.g. `https://forge.app/support` |
| Marketing URL | TODO — e.g. `https://forge.app` |
| Privacy Policy URL | TODO — required before submission |

## App Privacy (nutrition label answers)

Matches `ios/Forge/Forge/PrivacyInfo.xcprivacy`.

- **Data collected:** Health & Fitness (App Functionality), Other User Content
  — chat messages (App Functionality). Only transmitted when live AI coaching
  is enabled; requests go to Forge's backend proxy.
- **Linked to identity:** No (no accounts in this build).
- **Used for tracking:** No. No tracking domains, no third-party ads or analytics.
- HealthKit data is read on-device with permission and is never sold or shared
  beyond the AI request described above.

## App Review Notes

> Forge runs fully offline with a built-in demo athlete — no account needed.
> Tap **"Enter demo"** on the welcome screen to explore every feature.
> HealthKit: read permissions personalize the recovery/score pipeline; the app
> functions identically if permission is denied (demo data, clearly labeled).
> Notifications are optional and configured in-app. AI coaching runs in an
> offline rule-based mode in this build; live AI routes through our backend —
> no API keys ship in the binary.

## Version 1.0 "What's New"

> Meet Forge: your Daily Directive, Forge Score, AI coach, and every wearable
> unified into one plan. Open it tomorrow morning — it'll tell you exactly
> what to do.

## Screenshot plan (6.9" required set — see appstore/screenshots/)

1. **Dashboard** — "One answer every morning." (directive card hero)
2. **Coach** — "A coach who's read your data."
3. **Ecosystem hub** — "Every wearable. One brain."
4. **Recover** — "Know when to push."
5. **Fuel** — "Targets, not spreadsheets."
6. **Train** — "Workouts that respect your injuries."

## Pre-submission checklist (remaining)

- [ ] Apple Developer Program enrollment + signing (currently unsigned dev build)
- [ ] Privacy policy + support pages live at real URLs
- [ ] Deploy `supabase/functions/coach-proxy` and set `CoachProxyURL` for the release build
- [ ] TestFlight round on physical devices (HealthKit, haptics, performance)
- [ ] Screenshot captions/framing pass (raw captures provided)
