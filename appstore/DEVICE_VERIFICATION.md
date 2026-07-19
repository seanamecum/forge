# Forge — On-Device Verification Checklist

Everything in this list **cannot be signed off from the iOS Simulator or unit tests** and needs a real
iPhone (and, where noted, a paired Apple Watch + a signed-in Supabase account). It maps to the
`FORGE_AUDIT.md §7` "requires a real device" items and verifies the behaviour behind the logic that *is*
unit-tested. Check each box on device; note the build (`Forge v1.0`), iOS version, and device.

Device: __________  ·  iOS: __________  ·  Build: __________  ·  Date: __________

---

## 1. HealthKit — authorization state machine
Settings → Privacy & Security → Health → Forge lets you flip these between runs.

- [ ] **Not determined (first run):** demo data shows, "Not connected — demo data active", connect banner visible.
- [ ] **Authorize all:** status → "Connected · live Health data"; recovery hero reads "Estimated from your HRV …";
      demo chips disappear; Forge Score inputs reflect real sleep/HRV.
- [ ] **Authorize partial** (grant workouts, deny HRV/sleep): app stays usable; recovery falls back to a
      labeled estimate/demo (never a fabricated "live" number).
- [ ] **Deny all reads:** app remains fully functional on demo data; "Partial · estimated" / "Demo data"
      labels are honest; a path to Settings is offered.
- [ ] **No Health samples yet** (authorized, empty): "Connected — no Health samples yet, showing demo values."

## 2. HealthKit — freshness / staleness (initiative 5)
Requires a device whose Health store has an **old** HRV sample (e.g., stop wearing the Watch a day, or
add a backdated sample via a testing tool).

- [ ] With a **fresh** HRV sample: recovery hero says "Estimated from your HRV …"; Score basis confidence rises.
- [ ] With an HRV sample **> 24h old**: recovery hero reads "… last HRV ~Nh old, recovery held at estimate";
      Score/Directive "Signals/Missing" list "A fresh HRV reading (last sample ~Nh old)"; recovery is NOT
      derived from the stale value.
- [ ] Sample age displayed roughly matches the real sample's age.

## 3. Accessibility — the sweep the simulator can't sign off
Settings → Accessibility.

- [ ] **Dynamic Type at AX-XXXL** (Accessibility text sizes → largest): no clipped/overlapping text on the
      Dashboard, Recovery, Fuel, Coach, Train logger, Profile. Note any truncation.
- [ ] **VoiceOver reading order** on the Dashboard: greeting → directive → score → today → fuel is logical;
      cards read as single grouped elements; the "Signals Forge used"/"Confidence" disclosures are reachable.
- [ ] **VoiceOver on charts:** every Sparkline/BarTrend speaks a trend summary ("Recovery trend: now 78, up
      from 72 …") — none are silent.
- [ ] **Reduce Motion:** score/recovery rings snap instead of animating; entrance animations are calm.
- [ ] **Increased Contrast** and **Bold Text:** status stays legible; nothing relies on color alone.
- [ ] **Touch targets ≥ 44pt:** the concussion symptom 0–6 dots and any small buttons are comfortably
      tappable (known gap — the symptom dots are 16pt; confirm/az fix).
- [ ] **Differentiate Without Color:** recovery/score bands remain distinguishable (they carry numbers/labels).

## 4. Account & data (App Store 5.1.1(v)) — needs a signed-in Supabase account
- [ ] Sign up → sign in works against live Supabase; session survives relaunch (Keychain).
- [ ] Token refresh: after the access token would expire (~1h), an authed action (e.g. Delete account) still
      works — it refreshes rather than failing with a "check your connection" error.
- [ ] **Delete cloud account only:** account removed server-side; signed out; local data remains.
- [ ] **Delete all data on this phone:** local workouts/nutrition/check-ins/scores/hydration cleared; you stay
      signed in.
- [ ] **Delete account + all data:** both gone; a *failed* server delete leaves local data intact (retryable).
- [ ] **Export my data:** produces a `.json` share sheet; the file opens and contains schema_version, profile,
      workouts (with per-set detail), nutrition, hydration, scores, check-ins, timezone, ISO-8601 timestamps.

## 5. Widget · Live Activity · Watch (needs device; Watch for the last)
- [ ] Home-screen widget shows today's directive + Forge Score and refreshes.
- [ ] Start a workout → Live Activity appears on lock screen + Dynamic Island; ends cleanly.
- [ ] App-Group SwiftData store initialises with no CoreData sandbox errors (the simulator logs these; a real
      device with the entitlement should not).
- [ ] Paired Apple Watch receives the directive over WatchConnectivity after a sync.

## 6. Feedback + nutrition capture (needs device hardware)
- [ ] Feedback submit: success path; airplane-mode shows the "You're offline …" typed error (not a generic one).
- [ ] Barcode scanner (camera): scanning a packaged food looks it up via OpenFoodFacts; an unknown barcode
      shows a useful state; camera-denied is handled.
- [ ] Photo food scan runs on-device (nothing uploaded) and admits when it can't identify a plate.

## 7. Edge / lifecycle
- [ ] Background the app mid-workout, return → timer/state intact; force-quit mid-workout → history is saved.
- [ ] New calendar day while app is open → today's logs reset honestly (empty, not stale).
- [ ] Low Power Mode: animations/GPS behave; no crashes.

---

### Sign-off
When every box above is checked on a real device, update `FORGE_AUDIT.md §7`/§8 and raise the beta/App-Store
readiness scores accordingly. Anything that fails is a P0/P1 to file, not a box to skip.
