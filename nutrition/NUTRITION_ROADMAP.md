# Forge Nutrition — Adaptive Coach Roadmap & Architecture Audit

**Status:** approved — Phase 1 in progress. Branch `feat/nutrition-adaptive-coach`
off `audit/launch-hardening`.
**Goal:** make Forge Nutrition a **flagship** feature — a complete **adaptive
nutrition coach** that **exceeds MacroFactor in usability** while remaining
completely original (no copied branding, wording, layouts, implementation, or
visual identity — only studied product principles). Long-term: the **best
nutrition platform available, not just a macro tracker.**

### North-star capabilities (build the architecture to scale to all of these)
- **Near-universal food coverage** via a federated data platform (USDA + self-hosted
  Open Food Facts + Nutritionix/FatSecret restaurants within licensing + Forge-native
  foods/meals/recipes/community).
- **Google-fast unified search** across branded · restaurant · international · barcode
  · USDA · community · custom · recipes · meals — with recents, favorites, frequently
  eaten, **typo tolerance**, **natural-language search**, **AI search**, smart ranking,
  and **offline caching**.
- **Flexible servings everywhere** (1 egg / 5 eggs / 200 g / 7 oz / cups / tbsp / tsp /
  slices / scoops / packages / custom), grams-canonical internally, the chosen unit
  preserved, instant recalculation of cal + macros + micros, **never fabricated
  conversions** (estimated conversions clearly flagged).
- **Explainable adaptive coaching** (trend weight, expenditure estimation, goal modes,
  weekly check-ins, program modes, algorithm status, versioned/auditable outputs).
- **Forge-native intelligence** (training load, recovery, steps, sleep, planned
  workouts) surfaced as plain-language coaching in the Coach + Daily Directive.

---

## 1. Current-state feature inventory (verified against source)

### Data models (`Models/NutritionModels.swift`)
| Type | Shape | Notes |
|---|---|---|
| `Food` | id, name, brand?, `serving: String` (free text e.g. "100 g"), calories:Int, protein/carbs/fat/fiber/sugar:Double | Per-serving values. **No canonical grams, no unit system, no micros beyond fiber/sugar, no source/attribution/verification.** |
| `FoodEntry` | meal, food, `servings: Double` (scalar multiplier), `time: String` ("Now") | Calories = food.calories × servings. **No unit choice, no gram weight, no real timestamp (time is a display string).** |
| `SavedMeal` | name, cal, macros, itemCount | **Display-only mock; not a real, composable entity.** |
| `NutrientStatus`/`NutrientGroup` | name, % of target | Fed by demo data, **not computed from logged foods.** |
| `DeficiencyAlert`, `Supplement` | — | Supplements/bloodwork now real & synced (prior milestones). |

### Services / engines
- **`NutritionService`** (109 LOC): in-memory `entries`, `foods = MockData.foods`, water, totals (cal/protein/carbs/fat), `search(query)` = case-insensitive filter over the mock foods, `add/remove/addWater`, `toggleSupplement`. Demo-gated (`isDemo`) so demo never persists (fixed this session).
- **Food database = `MockData.foods` → 18 hardcoded foods.** That is the entire searchable catalog today.
- **`OpenFoodFactsService`** (100 LOC): real barcode → nutrition via Open Food Facts v2 (no key, per-100 g, macros + fiber/sugar). Pure decoder is unit-tested; degrades offline. **Only micros are fiber/sugar.**
- **`TargetEngine`** (97 LOC): base targets from body × activity × goal (calories, protein, fat, carbs, water, steps, active-energy). Pure, calibrated so demo Sean = 3,200 kcal / 200 g.
- **`AdaptiveNutritionEngine`** (130 LOC): rule-based coached *deltas* (heavy training week +150; weight-trend plateau/stall ±100; injury +15 g protein; low recovery +16 oz; endurance-tomorrow +200), each with a reason. Produces a `FuelPlan`. **This is rules, not a TDEE/expenditure estimator.**

### Persistence & sync
- **`NutritionEntryRecord`** (SwiftData): entryID, `date: Date` (real), meal, name, calories, protein, carbs, fat, servings. Syncs via the generic doc store. **No unit, no gram weight, no food id/source, no per-100 g basis, no micros.**
- `loadTodayEntries()` filters `date >= startOfToday` — **today only; no past/future diary.**
- Water persists per-day in `UserDefaults`.
- **Supabase 0001** has normalized `foods`, `food_logs`, `hydration_days`, `supplements`, `supplement_logs` tables — **but the iOS client uses the generic `sync_records` doc store, so `food_logs`/`foods` are currently unused by mobile.**

### UI (`Features/Nutrition/`)
- `NutritionHomeView`: coached-targets card, macro ring, water, quick-log row, meals card, nav links (Supplements/Deficiencies/Micronutrients). `FoodSearchSheet` = a `List(search(query))` over 18 foods.
- `BarcodeScanSheet` (real, OFF), `PhotoFoodScanSheet` (AI photo — present), `SupplementsView`, `DeficienciesView`, `MicronutrientsView`.

---

## 2. Gaps vs. the product requirements

### 2.1 Fast food logging — mostly missing
| Requirement | Today | Gap |
|---|---|---|
| High-quality food DB search | 18 mock foods | **No real DB.** Needs federated providers + cache. |
| Barcode | ✅ OFF (global) | Keep; broaden + cache; label source. |
| Recent foods | ❌ | Derive from log history. |
| Favorites | ❌ | New entity. |
| Custom foods | ❌ | New entity + create-in-30 s flow. |
| Custom recipes/meals | ❌ (SavedMeal is a mock) | Real composable entities. |
| Multi-add | ❌ | New flow. |
| Quick-add cal/macros | ❌ | New flow. |
| Copy meal / whole day | ❌ | New flow. |
| Log to past/future dates | ❌ (today only) | Diary needs a date cursor. |
| Adjustable serving units + gram weights | ❌ (scalar `servings` only) | **Core: grams-canonical + unit/portion model + conversion engine.** |
| Hourly meal timeline | Partial (meal buckets) | Real timestamps + timeline. |
| Fast edit/delete/duplicate from diary | ❌ (no inline edit) | Diary CRUD. |
| Honest partial/missing-log handling | Partial | Explicit "incomplete day" states. |
| Photo/AI logging | Present (later) | Defer to a late phase. |

### 2.2 Daily experience — partial
Consumed/remaining and macros exist; **fiber/priority-micros from logs, meal-by-meal detail, consumed-vs-remaining toggle, weekly averages, nutrient detail with top food sources, and rich charts are missing.** Micronutrients are demo-fed, not computed.

### 2.3 Adaptive coaching — rules only, no expenditure model
Missing: **trend-weight smoothing**, **expenditure (TDEE) estimated from logged intake + trend-weight change**, **goal modes (lose/maintain/gain) with user target rate**, **weekly explainable check-ins**, **coached/collaborative/manual program modes**, **anti-overreaction to a single weigh-in/day**, **algorithm status (learning/updating/holding/high-confidence)**, and **versioned/auditable outputs.** Current engine is same-day rule deltas.

### 2.4 Forge intelligence — foundation exists, not fully wired
Training-load/recovery/injury deltas exist. Missing: steps/sleep/planned-workout-aware fueling, explicit protein/recovery protection in a deficit surfaced in Coach + Directive as explanations.

### 2.5 Data & architecture — needs a real model
No gram-canonical model, no unit/portion entity, no food source/attribution/verification/timestamps, no recipes/meals/favorites/recents entities, no expenditure/program/adjustment audit records. Sync + RLS + offline-first + demo isolation infrastructure **already exists and is proven** (prior milestones) — the new entities plug into it.

---

## 3. Federated food-data platform

**Principle:** near-universal coverage, no single provider, one unified Forge search. Merge → dedupe → rank → label → attribute → cache (per each provider's rules).

### 3.1 Provider comparison
| Provider | Coverage | Barcode | Restaurant | International | Micros | Speed | License | Cost @ scale | Cache/redistribute |
|---|---|---|---|---|---|---|---|---|---|
| **USDA FoodData Central** | ~2 M (Foundation, SR Legacy, ~1.2 M Branded via GS1) | UPC via `gtinUpc` field | Limited | US-centric | **Excellent** (Foundation/SR) | Good (free key) | **Public domain** | **Free** | **✅ freely cache/redistribute** |
| **Open Food Facts** | ~3 M+ global packaged | **Excellent global EAN/UPC** | Weak | **Excellent** | Variable/incomplete | Good; **full bulk dump** | **ODbL** (attribution + share-alike on the DB) | **Free** | ✅ self-host the dump; ⚠️ ODbL obligations on the derived DB |
| **Nutritionix** | ~1 M grocery | US-focused | **Best US chains/fast-food** + NLP parsing | US-centric | Good | Fast | Proprietary | $$ tiered | ⚠️ **no permanent caching** (TTL limits) |
| **FatSecret Platform** | Large, region-localized | ✅ (premier) | Good, international | **Strong (locales)** | Moderate | Fast | Proprietary, region-licensed | $$ tiered | ⚠️ caching restricted |
| **Edamam** | Generic + branded | ✅ | Some | Moderate | Good (analysis) | Fast | Proprietary | $ free dev → $$ | ⚠️ caching restricted |
| **GS1 / Syndigo / 1WorldSync** | Manufacturer-authoritative UPC | ✅ authoritative | — | Global | Label-complete | — | Enterprise | $$$ | Enterprise terms |
| **Forge user/community** | Your users' foods | user-entered | user-entered | user-entered | as entered | Instant (local) | Forge-owned | Free | ✅ fully owned |

### 3.2 Recommended combination
- **Tier 1 — authoritative & free & cacheable:** **USDA FDC** for US generic + branded and the micronutrient backbone. Public domain → import into Forge's own store, cache freely, rank as "Verified/Authoritative."
- **Tier 2 — global barcode, self-hosted:** **Open Food Facts bulk import** into Forge's Supabase/Postgres food cache → fast, offline-cacheable global barcode coverage with no per-call limits. *Legal note: ODbL requires attribution and share-alike on the derived database — tag OFF-sourced rows, keep them separable, and plan to honor ODbL (publish the OFF-derived subset or isolate it). User data stays separate and private.*
- **Tier 3 — restaurant/fast-food + NLP:** **Nutritionix** (US chains, natural-language) and/or **FatSecret** (international restaurants) as **live, on-demand** lookups — surfaced only when the user searches restaurants; **not permanently cached** (respect TTL/attribution). One provider behind an interface so we can swap/region-route.
- **Tier 4 — Forge-native:** user-created foods, custom recipes/meals, and **moderated community submissions** in RLS-isolated Supabase tables — always owned, cacheable, correctable with audit history.

### 3.3 Search/merge/rank
One `FoodSearchService` fans out: **local cache first** (USDA + OFF import + user/community; fast + offline), then **live providers** for gaps. Merge + **dedupe by UPC, else normalized (name+brand)**; **rank** by source reliability → data completeness → popularity → locale match → exact-match. **Label** each result (Verified · Branded · Restaurant · Community · Yours). Store **attribution + `fetched_at`**; cache live results only within allowed TTL. Flag incomplete/suspicious entries; corrections preserve audit history.

### 3.4 Unified search experience (must feel like Google, and beat MacroFactor)
The search box is the front door — it must be instant and forgiving:
- **Instant local-first:** results stream from the on-device cache before any network
  call; typing never blocks. Debounced live provider calls fill gaps.
- **Personal shortcuts:** **Recents**, **Favorites**, and **Frequently eaten**
  (ranked by the user's own log frequency × recency) appear before a query is typed
  and boost matching results.
- **Typo tolerance / fuzzy match:** trigram/edit-distance matching + common-misspelling
  and singular/plural normalization ("chikken", "brocoli", "egg"↔"eggs").
- **Natural-language logging:** parse "2 eggs and a slice of toast" → structured
  multi-item log with quantities (Tier-3 NLP provider or a Forge parser; falls back to
  plain search offline).
- **AI search:** semantic/embedding match for descriptive queries ("high-protein
  vegan breakfast", "something like chipotle bowl") — an optional layer over the
  ranked results, never fabricating nutrition values.
- **Smart ranking:** blends relevance, personal history, source reliability, data
  completeness, popularity, and locale; learns from what the user actually picks.
- **Barcode** inline in the same surface; **create-food-in-30 s** always one tap away.
- **Offline caching:** recents/favorites/frequently-eaten and the USDA+OFF cache are
  fully available offline; live-only providers degrade gracefully with a clear state.

**Architecture implication (build now):** a `FoodSearchProvider` protocol + a
ranking/merge pipeline + a cache layer, so USDA/OFF/restaurant/AI/NLP are pluggable
sources behind one API. Ranking signals and the cache schema are designed in Phase 2
to accommodate typo/NLP/AI/embedding layers added in Phase 7 without rework.

---

## 4. Serving-size & quantity architecture (core requirement)

**Canonical internal unit = grams.** Nutrients stored **per 100 g** whenever a gram basis exists; provider "servings" become **named portions with gram weights**.

### 4.1 Model
- `FoodPortion { label, unitKind (mass|volume|household|serving), gramWeight, source (manufacturer|usda|off|estimated|user) }` — e.g. "1 medium egg = 50 g", "1 cup = 240 g (if density known)", "1 homemade scoop = 38 g (user)".
- **Log entry stores:** `foodId`, `enteredAmount: Decimal`, `unit/portion`, **`grams` (resolved)**, `gramSource`, and a **`nutrientSnapshotPer100g`** (so a historical log stays stable even if the food is later corrected — auditability).
- Nutrient scaling: `nutrient = per100g × grams / 100` for **every** macro *and* micro.

### 4.2 Conversion rules (never fabricate)
- **Mass** (g ↔ oz ↔ lb): always exact.
- **Volume** (ml/cup/tbsp/tsp) → grams: **only when density/serving-weight is known**; otherwise the unit is unavailable or clearly flagged **"estimated."**
- **Household** (piece/slice/scoop/package): needs a **gram weight per portion** (provider or user-defined). No weight → don't offer it or flag estimated.
- **Edible-portion vs packaged weight** supported where data distinguishes them.

### 4.3 UX (must beat MacroFactor's editor, native to Forge)
Numeric pad + **unit chips**; **+1 / −1 / ×2 / ÷2 / repeat-last**; decimals *and* fractions; **remembers last amount+unit per food**; instant recalculation of cal/macros/micros on every keystroke; inline edit **from the diary** (no delete-and-re-add); clear "estimated conversion" warnings. The flexible example (log eggs as 1 egg / 5 eggs / 200 g / 7 oz / 1 cup / 0.5 serving / custom) is the acceptance bar.

### 4.4 Tests (required)
Unit switching; rounding; fractions/decimals; very large quantities; missing-conversion handling; **micronutrient scaling parity**; density-known vs unknown; edible vs packaged.

---

## 5. Data-model & architecture proposal

New/updated entities (SwiftData `@Model` + `Syncable` doc-store kinds; Supabase mirrors via existing sync + RLS):

- **`FoodItem`** (canonical): id, source, sourceId, upc?, name, brand?, verified, `per100g` nutrients (macros + fiber + priority micros), `defaultPortionId`, portions[], completenessScore, attribution, updatedAt.
- **`FoodPortion`** (§4.1).
- **`DiaryEntry`** (replaces `NutritionEntryRecord`): userId, `day` (calendar), `loggedAt` (timestamp), meal, foodId?, `nutrientSnapshotPer100g`, enteredAmount, unit, grams, gramSource, source. *(Snapshot keeps history stable + offline.)*
- **`Recipe` / `MealTemplate`**: userId, name, yield servings, ingredients[{foodId, grams}], computed nutrients; "copy day/meal" clones DiaryEntries.
- **`FavoriteFood`**, recents derived from `DiaryEntry` history.
- **`WeightSample`** (exists) + **`TrendWeight`** (smoothed; versioned).
- **`ExpenditureEstimate`**: userId, date, tdee, confidence, **algoVersion**, inputsHash — auditable.
- **`NutritionProgram`**: goalMode (lose/maintain/gain), targetRate, mode (coached/collaborative/manual), currentTargets, algoVersion.
- **`AdjustmentEvent`**: weekly check-in output, reason, before/after targets, algoVersion — audit trail.

**Reuse (already proven this launch cycle):** offline-first sync engine, per-user RLS, LWW conflict handling, demo/real isolation, SwiftData lightweight migration with defaulted fields. New record kinds register in `SyncRegistry`; a server-side **shared food cache** (USDA/OFF import) is a separate world-readable table (not user-scoped).

**Versioning/auditability:** every adaptive output carries `algoVersion` + inputs so a recommendation is reproducible and explainable.

---

## 6. Screens & user flows (Forge-native)

1. **Diary (home):** date cursor (‹ Today ›), calories consumed/remaining ring, macro bars (P/C/F) + fiber, **meal-by-meal timeline with real times**, per-entry swipe → edit/duplicate/delete, "+ Add" per meal, incomplete-day banner. Consumed⇄Remaining toggle.
2. **Add food (unified search):** one search box over federated sources; result rows show source label + completeness; tabs/filters: All · Recents · Favorites · Yours · Barcode · Quick-add. Barcode + "Create food (30 s)" always reachable.
3. **Quantity editor** (§4.3): the fast unit/amount sheet; the "eggs" acceptance bar.
4. **Create food / Create recipe:** minimal required fields; recipe = ingredients + yield → computed per-serving.
5. **Multi-add & copy:** select several foods → add together; copy a meal or a whole day to another date.
6. **Nutrient detail:** a nutrient → 7-day avg vs target + **top food sources** from the user's own log.
7. **Weekly report:** calorie/macro averages, adherence, and the **explainable check-in** ("Expenditure trending ~2,780 kcal; trend weight −0.4 lb/wk; recommend +80 kcal — here's why") with accept/adjust (program mode).
8. **Program setup:** goal mode, target rate, coached/collaborative/manual; **algorithm status chip** (learning/holding/updating/high-confidence).

Every screen has explicit **empty / incomplete / offline** states and never shows demo data to a real user.

---

## 7. Phased implementation roadmap

- **Phase 0 — this audit.** ✅
- **Phase 1 — Serving-size & quantity engine + real diary log model.** *(recommended first)* Grams-canonical `FoodItem`/`FoodPortion`, pure **conversion + scaling engine**, `DiaryEntry` (unit/grams/snapshot), quantity editor UX, diary CRUD (edit/duplicate/delete inline), **log to any date**. Migrate `NutritionEntryRecord`. Fully unit-testable; de-risks the data model before external providers.
- **Phase 2 — Federated food data + unified search core.** `FoodSearchProvider`
  protocol + ranking/merge/cache pipeline; USDA FDC import, OFF bulk cache,
  dedup/labeling/attribution, **recents/favorites/frequently-eaten**, custom foods,
  create-in-30 s, global barcode + offline caching. (Ranking + cache schema designed
  to accept typo/NLP/AI layers without rework.)
- **Phase 3 — Daily experience.** Consumed/remaining, fiber + priority micros from logs, meal timeline, weekly averages, nutrient detail + top sources, charts, states.
- **Phase 4 — Recipes, meals, multi-add, copy day/meal, quick-add.**
- **Phase 5 — Adaptive coaching v2.** Trend-weight smoothing, expenditure estimation, goal modes + target rate, weekly explainable check-ins, program modes, algorithm status + versioning/audit, anti-overreaction + missing-day safety.
- **Phase 6 — Forge intelligence integration.** Training-load/recovery/steps/sleep/planned-workout-aware fueling; protein/recovery protection in a deficit; explanations in Coach + Directive.
- **Phase 7 — Search intelligence.** **Typo tolerance / fuzzy match**, **natural-language logging**, **AI/semantic search**, learned smart ranking — layered onto the Phase 2 pipeline.
- **Phase 8 — Restaurant coverage (live Nutritionix/FatSecret), photo/AI food logging, community submissions + moderation.**

---

## 8. Testing strategy
- **Pure engines** (conversion, nutrient scaling, trend weight, expenditure, ranking/dedup) — hermetic unit tests (existing engine-test pattern).
- **Provider decoders** — fixture-based tests (like `OpenFoodFactsTests`); never hit the network in tests.
- **Persistence/migration** — in-memory `ModelContainer` round-trips; legacy `NutritionEntryRecord` → `DiaryEntry` migration.
- **Sync/offline/conflict** — fake-transport integration tests (existing pattern); LWW + demo/real isolation.
- **Serving math** — the required matrix (units, rounding, fractions, large qty, missing conversion, micro scaling).
- **Adaptive** — golden tests: no overreaction to one weigh-in; missing/partial days; algorithm-status transitions; every recommendation carries a reason + `algoVersion`.
- Full suite + Debug + Release each milestone (current: 348 tests, 0 failures).

## 9. Migration risks
- **`NutritionEntryRecord` → `DiaryEntry`:** treat legacy `servings` as a multiplier of the stored per-serving snapshot; backfill `grams` = unknown (`gramSource = legacy`); keep old entries valid and rendering. SwiftData lightweight migration with defaulted fields (proven this cycle).
- **Demo coherence:** Sean's 3,200 kcal / 200 g targets must stay; demo foods stay demo-only.
- **Sync:** new record kinds are additive; pre-launch single client → low risk; register kinds before shipping.
- **Supabase:** add a **shared food cache** table + RLS for the OFF/USDA import (world-readable, service-role-written); user diary stays owner-scoped. New migration `0005_nutrition`.
- **Licensing:** ODbL (OFF) share-alike + provider no-cache terms must be honored — **legal review before Phase 2 ships** with cached third-party data.

## 10. Recommendation — first highest-impact milestone

**Phase 1: the serving-size & quantity engine + real diary log model.**

Why first:
1. **Foundational** — every other feature (search, daily experience, recipes, adaptive coaching) reads/writes the diary + serving model; getting grams-canonical + conversions right first prevents rework.
2. **Fully testable now** — pure conversion/scaling engine + persistence/migration, no external provider or legal dependency, so it ships clean and fast.
3. **Immediately visible value + fixes real gaps** — flexible quantity entry (the eggs example), inline diary editing, and logging to any date replace today's scalar-servings / today-only / 18-food limitations.
4. **De-risks the data model** before we invest in the federated provider platform (Phase 2), which carries the licensing/legal work.

Scope for Phase 1 (proposed): `FoodItem`/`FoodPortion` (grams-canonical) · pure `ServingConversion` + `NutrientScaling` engines · `DiaryEntry` model + migration from `NutritionEntryRecord` · quantity-editor UI (unit chips, ±/×/÷/repeat, fractions, remembered last amount, live recalc, estimated-conversion warnings) · diary CRUD (inline edit/duplicate/delete) · date cursor (past/future) · full tests + Debug/Release + commit/push on a dedicated branch.

---

## Decisions (approved 2026-07-29)
1. ✅ Roadmap + **Phase 1** approved as the first milestone.
2. ✅ Branch **`feat/nutrition-adaptive-coach`** created off `audit/launch-hardening`.
3. ✅ Provider strategy approved: USDA + self-hosted OFF for the cache (ODbL honored;
   legal pass before Phase 2 ships cached third-party data), Nutritionix/FatSecret
   live-only for restaurants, Forge-native foods/meals/recipes/community.
4. ✅ Expanded flagship vision + Google-like search folded in (§0 north-star, §3.4,
   Phases 7–8).
