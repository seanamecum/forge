# Forge — End-to-End Real-Device Verification

**Status: NOT VERIFIED.** Nothing in this document may be marked ✅ until it is
completed on real hardware and the observed result matches "Expected." Simulators
do **not** carry real HRV/sleep history and cannot prove HealthKit or cross-device
sync — every check here requires physical devices.

## What you need
- **Device A** — a real iPhone (iOS 18+) signed into an Apple ID with **Apple
  Watch history** (real HRV + sleep — ideally ≥14 days of HRV so the personal
  baseline engages; see §1).
- **Device B** — a second real iPhone (or the same phone after a wipe/reinstall)
  for the sync + reinstall checks (§5–§7).
- Xcode 26.x, the `Forge` scheme, run **Release** config on device where noted
  (`Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Build Configuration = Release`).
- Bundle id `com.seanmecum.forge`; HealthKit entitlement is already in
  `Forge/Forge.entitlements`. A real-device run needs a valid signing team.
- A **test account** (real email) for sync, plus the **Demo** path for isolation
  checks. Migration `0003` is live (verified), so cloud sync is active.

Record each result inline: `✅ pass` / `❌ fail (what you saw)` / `⏭ n/a`, plus the
device, iOS version, and date in the sign-off block at the end.

---

## 1. HealthKit permissions & live reads

Navigation: **Recover tab → "Apple Health / Wearables" row → WearablesView**, or
**Home (Dashboard) → Apple Health tile**.

| # | Step | Expected |
|---|---|---|
|1.1| Fresh install, sign into a **real account** (not Demo). Open Wearables. | Status reads *"Not connected — demo data active."* Button **"Connect Apple Health"** is visible. |
|1.2| Tap **Connect Apple Health**. | The iOS HealthKit permission sheet appears listing the categories from the usage string (steps, heart rate, resting HR, HRV, sleep, workouts, energy, weight). |
|1.3| Enable **all** categories, tap Allow. | Returns to Forge; status becomes *"Connected · live Health data"* (or *"Connected — no Health samples yet…"* if the account has no samples). |
|1.4| Confirm the usage strings shown by iOS. | Read string = the `NSHealthShareUsageDescription`; write string = `NSHealthUpdateUsageDescription`. No generic/placeholder text. |
|1.5| With a watch-wearing account, tap **Refresh** and inspect the recovery/HRV/sleep values on the Recover screen. | HRV (ms), resting HR, sleep hours, steps reflect **your real Health data**, not 58 ms / 3.1 h / Sean's numbers. Cross-check one value against the Apple Health app. |
|1.6| **Baseline engagement** (needs ≥14 days real HRV history): open Recover after a refresh. | Recovery is computed against **your own** HRV baseline (median of ~30 days), not the demo 62 ms. Sanity check: if your true resting HRV ≫ 62, recovery should read higher than it did in demo for the same night; if ≪ 62, lower. |
|1.7| **Sparse-history account** (<14 days HRV): refresh. | App does **not** fabricate a baseline — it keeps the clearly-labeled demo/estimated value and the basis card still says values are estimated. No crash, no absurd recovery. |
|1.8| Freshness: put the phone in airplane mode for a day (or use an account whose last HRV is >24 h old), refresh. | The Directive/Recovery basis notes *"A fresh HRV reading (last sample ~Nh old)"* — a stale sample is not presented as today's. |

## 2. Forge Score & Daily Directive update from live data

| # | Step | Expected |
|---|---|---|
|2.1| After 1.5, go **Home**. Note the Forge Score and the Daily Directive headline/actions. | Both reflect the live recovery — a low-recovery morning yields a recovery-day directive (amber/ruby tone, capped intensity); a high-recovery morning yields a green "train hard" directive. |
|2.2| Tap the Forge Score / Directive **"Why"** (RecommendationBasis) surface. | Inputs list shows the live signals actually used (recovery, HRV, sleep debt, training load…). Provenance reads **"Partial · estimated"** when connected (not "Live" — strain/readiness are still derived) and not "Demo data." |
|2.3| Log a **morning check-in** (Home → check-in). Re-open the Directive "Why". | Check-in appears in inputs; "Morning check-in" is no longer listed as missing; confidence rises. |
|2.4| Background the app, wait, reopen (foreground refresh). | On return the app refreshes Health, re-ingests, and the score/directive stay consistent with the latest reading (no flicker back to demo numbers). |

## 3. Workout & health write-back

| # | Step | Expected |
|---|---|---|
|3.1| Train tab → start & complete a **strength workout** (log a couple of sets). | Workout is saved; it appears in history; Forge Score's training-load input moves. |
|3.2| Open Apple Health → Browse → Workouts. | A **Traditional Strength Training** workout from Forge appears with the right time window (and active energy if provided). |
|3.3| Train → **GPS run**, complete it. | Health shows a **Running** workout with distance. |
|3.4| Wearables → **Save weight to Health** (or log a weigh-in on Body). | Health → Body Measurements → Weight shows the value written by Forge. |
|3.5| Body/weigh-in you logged locally. | Round-trips: value persists across relaunch and (per §5) restores after reinstall. |

## 4. Denied permissions, missing data, offline, errors

| # | Step | Expected |
|---|---|---|
|4.1| Fresh account; at the HealthKit sheet (1.2) tap **Don't Allow** (or deny all). | Status: *"Health access denied. Enable Forge in Settings → Privacy & Security → Health."* App stays fully usable on demo/estimated values — **no crash, no blank screens.** |
|4.2| Wearables shows the recovery path. | A **"Open Settings to enable Health access"** button is present and deep-links to iOS Settings. |
|4.3| Grant read but **no data exists** (new Apple ID, no watch). | Status: *"Connected — no Health samples yet, showing demo values."* Honest, not fabricated. |
|4.4| **Offline mode:** airplane mode ON. Use the app — log a workout, a weigh-in, a supplement. | Everything works locally and persists. No hangs, no error dialogs for local actions. |
|4.5| Profile → **Cloud Sync** card while offline (after an edit). | Reads *"Offline — changes saved, will sync when you're back online."* icon = `icloud.slash`. |
|4.6| Turn airplane mode **OFF**, wait or tap **Sync now**. | Card flips to *"Syncing…"* then *"Backed up · <time>."* The offline edits are now on the server (confirm on Device B in §5). |
|4.7| **Token-expiry / re-auth:** sign out, then trigger a sync-requiring action on a stale session (or wait out the token). | Card shows *"Sign in again to keep syncing."* — never silent data loss; local dirty data is retained and flushes after re-sign-in. |

## 5. Two-device sync

Both devices signed into the **same real account**.

| # | Step | Expected |
|---|---|---|
|5.1| Device A: log a **weigh-in** (e.g. 182 lb). Wait for *"Backed up."* | — |
|5.2| Device B: foreground the app (or Profile → **Sync now**). | The 182 lb weigh-in appears on B within one sync. |
|5.3| Device A: add a **supplement** + a **bloodwork** marker + a **goal**. Sync. | All three appear on Device B after its next sync. |
|5.4| Device A: edit the **profile** (name, or notification time in settings). Sync both. | Device B reflects the profile/settings change (profile syncs as one converging document). |
|5.5| Device B: complete a **workout**. Sync both. | Device A shows B's workout — sync is bidirectional. |
|5.6| Rough latency check. | A foreground/"Sync now" reconciles within a few seconds on a normal connection. |

## 6. Reinstall / restore

| # | Step | Expected |
|---|---|---|
|6.1| On Device A (real account with logged history), **delete the app**. | — |
|6.2| Reinstall, sign into the **same account**, let it sync (or Profile → Sync now). | **Full history restores**: weigh-ins, supplements, bloodwork, goals, workouts, profile, and settings all return — the app is not empty. |
|6.3| Confirm the counts/values match what was there before deletion. | Nothing missing, nothing duplicated. |
|6.4| Health-derived recovery/sleep after reinstall. | Recovery/sleep for recent days restore from the cloud snapshot; a fresh HealthKit refresh then updates today. |

## 7. Conflict handling (last-write-wins)

| # | Step | Expected |
|---|---|---|
|7.1| **Both online.** Devices A & B both showing the same weigh-in row. On A, edit it to 205; on B, edit the same row to 190 a few seconds **earlier** than A's edit. | — |
|7.2| Sync A, then B, then A again (foreground each). | Both devices converge to **205** (the later edit wins) — never a mix, never 190 sticking on one device. |
|7.3| **Offline conflict:** Device B airplane-mode, edit the row to 190. Meanwhile A (online) edits to 205 (later timestamp). Bring B online, sync. | Converges to 205 on both; B's older offline edit loses cleanly (no error, no duplicate row). |
|7.4| **Delete vs edit:** A deletes a supplement; B (had it) syncs. | The supplement disappears on B (tombstone propagates). If B made a *newer* edit to it than A's delete, the item survives (edit-after-delete resurrection) — verify whichever you set up. |

## 8. Sync-status UI (Profile → Cloud Sync card)

| # | State to reproduce | Expected card |
|---|---|---|
|8.1| Signed-in, just synced | `checkmark.icloud.fill` (green) · *"Backed up · <time>"* · **Sync now** button |
|8.2| Mid-sync (large first sync or slow net) | spinner · *"Syncing…"* |
|8.3| Offline after an edit | `icloud.slash` (amber) · *"Offline — changes saved, will sync when you're back online"* |
|8.4| Re-auth needed | `exclamationmark.icloud` · *"Sign in again to keep syncing."* |
|8.5| **Demo account** (Profile) | The Cloud Sync card is **absent** — demo never leaves the phone. Confirm no rows for a demo user reach the server. |

## 9. Isolation & privacy sanity (must hold on device)

| # | Step | Expected |
|---|---|---|
|9.1| Use **Demo** mode; log supplements/weight/workouts. | Nothing syncs; on a second device the demo data is **not** present. Demo is self-contained. |
|9.2| Real account after HealthKit connect: check the Coach's "signals" panel and any clinical text. | Only **your** data — never Sean's knee / Vitamin D / bench forecast. |
|9.3| Confirm the app only reads Health (never writes) except the explicit workout/weight write-backs in §3. | No unexpected Health writes appear. |

---

## Sign-off

| Section | Device / iOS | Date | Result | Notes |
|---|---|---|---|---|
| 1. HealthKit permissions & reads | | | | |
| 2. Forge Score & Directive | | | | |
| 3. Workout & health write-back | | | | |
| 4. Denied / missing / offline / errors | | | | |
| 5. Two-device sync | | | | |
| 6. Reinstall / restore | | | | |
| 7. Conflict handling | | | | |
| 8. Sync-status UI | | | | |
| 9. Isolation & privacy | | | | |

All sections `✅` on real hardware ⇒ record the date + devices in `FORGE_AUDIT.md`
(§12a for sync/DB, §12i for HealthKit) and flip "real-device verification" from a
blocker to done. **Until then it stays a blocker.**
