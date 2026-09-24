# Research registry notes

`registry.json` and `registry.csv` hold one canonical entry for each discovery in the twelve `*_600_YEARS.md` lists. Use these ids for dependency mapping.

- **Status.** `catalog` means the id is in main. `era` means the id is in `early_practice_knowledge.gd` on `codex/era-research-pacing`. `new` means the slug was assigned here.
- **Id column in the lists.** A NEW row now shows `NEW · slug`. A NEW row merged into another entry shows `NEW · canonical_id (dup)`. Catalog and era cells are unchanged.
- **shared_with.** This field combines `(shared: X)` notes, `(culture)` markers and the lines of any merged aliases.
- **key_threshold.** This is true when the row is bold in its source table.

## Counts

| Line | Rows listed | Canonical | catalog | era | new | Merged into another line |
|---|---|---|---|---|---|---|
| knowledge | 87 | 87 | 16 | 33 | 38 | 0 |
| institutions | 104 | 102 | 8 | 40 | 54 | 2 |
| culture | 98 | 95 | 2 | 22 | 71 | 3 |
| labor | 80 | 72 | 3 | 32 | 37 | 8 |
| production | 108 | 108 | 47 | 26 | 35 | 0 |
| infrastructure | 96 | 94 | 27 | 25 | 42 | 2 |
| nutrition | 107 | 106 | 41 | 26 | 39 | 1 |
| health | 89 | 89 | 12 | 32 | 45 | 0 |
| demography | 89 | 76 | 3 | 32 | 41 | 13 |
| logistics | 104 | 103 | 25 | 32 | 46 | 1 |
| ecology | 89 | 87 | 4 | 32 | 51 | 2 |
| security | 83 | 82 | 12 | 26 | 44 | 1 |
| **Total** | **1134** | **1101** | **200** | **358** | **543** | **33** |

Every catalog and era id in the lists was checked against the scripts. Catalog ids were checked in main, and era ids on `codex/era-research-pacing`. All of them resolve.

## Duplicates merged (33 rows into 31 entries)

**Rule for merges.** When the same existing id appeared in two lines, the entry stays in the line of the catalog's `direction`/`dynamic`. The one exception is `labor_rotations`, which both lists assign to labor. A NEW row that repeated another row's practice was merged into the line where its main effect falls. The canonical row keeps its own year and band. Alias years are kept in `aliases`, so mappers can see any disagreement.

| Canonical id | Kept in | Merged rows |
|---|---|---|
| `labor_rotations` | labor 1 | institutions 1 |
| `census_rolls` | institutions 295 | demography 330 |
| `public_levies` | institutions 300 | labor 330 |
| `cross_settlement_registries` | institutions 355 | demography 362 |
| `communal_work_songs` | culture 2 | labor 20 |
| `genealogical_recitation` | culture 4 | demography 8 |
| `cooperative_harvest_gatherings` | culture 75 | labor 45 |
| `household_lineage_tokens` | culture 80 | demography 76 |
| `mutual_aid_customs` | culture 100 | labor 72 |
| `naming_day_rites` | culture 225 | demography 290 |
| `intermarriage_visiting_customs` | culture 265 | demography 276 |
| `public_baths` | health 410 | infrastructure 415 |
| `guest_host_reciprocity` (era) | logistics 5 | culture 22 (guest-right) |
| `burial_ground_separation` (era) | health 272 | culture 140 (cemeteries) |
| `raised_granaries` (catalog) | nutrition 85 | infrastructure 65 (raised storehouse floors) |
| `seasonal_crisis_leader` | institutions 24 | security 170 (war leader for a season) |
| `worker_ration_lists` | institutions 280 | labor 290, demography 310 |
| `sealed_family_contracts` | institutions 510 | demography 500 (marriage contracts), demography 510 (adoption contracts) |
| `price_wage_schedules` | institutions 540 | labor 530 (hire rates by trade) |
| `coming_of_age_rites` | culture 65 | demography 46 |
| `children_light_tasks` | labor 16 | demography 32 |
| `fixed_worker_rations` | labor 215 | nutrition 224 (standard ration bowls) |
| `palace_weaving_houses` | production 460 | labor 460 |
| `standard_ingots` | production 500 | logistics 570 (oxhide ingots) |
| `shrine_terraces` | infrastructure 150 | culture 170 (raised platform for the god's house) |
| `work_gang_bakeries` | nutrition 400 | labor 410 |
| `stocked_fish_ponds` | nutrition 405 | ecology 395 |
| `hive_beekeeping` | nutrition 415 | ecology 420 |
| `bride_wealth_gifts` | demography 65 | institutions 50 |
| `trade_colonies` | logistics 235 | demography 235 (bold there) |
| `merchant_quarters_abroad` | logistics 525 | demography 520 |

**Large year gaps between merged rows:** `seasonal_crisis_leader` (24 vs 170), `burial_ground_separation` (272 vs 140) and `children_light_tasks` (16 vs 32). The dependency pass should confirm the canonical year for each of these.

## Related but kept separate

These rows overlap but have different effects. Each pair is a likely prerequisite link, not a duplicate.

- **Distinct existing ids that overlap:**
  - `alarm_relay_signals` / `alarm_relay_customs` / `warning_call_relay`
  - `watch_rotation` / `watch_duty_rotation`
  - `refuge_point_marking` / `refuge_point_designation`
  - `labor_rotations` / `shared_work_crew_rotation`
  - `novice_task_shadowing` / `mentored_task_learning`
  - `rest_break_timing` / `midday_heat_rest`
- **NEW rows kept separate:**
  - `sacred_places` → `sacred_grove_protection`
  - `customary_inheritance_shares` (60) / `partible_inheritance` (472)
  - `service_land_grants` / `frontier_settler_grants`
  - `wild_honey_smoking` → `hive_sparing_honey_harvest`
  - `onager_hybrid_teams` → `battle_wagons`
  - `courtyard_storerooms` / `central_storehouses`
  - `clay_lined_storage_pits` / `hermetic_grain_storage`
  - `rollers_and_runners` / `wedges_and_levers`
  - `copper_outcrop_signs` (140) / `ore_assaying` (85): the years are in reverse order.
- **Possible overlaps with later catalog entries.** Check these when mapping:
  - `ash_fat_soap` vs `soap_manufacture`
  - `corbelled_vaults` / `pitched_brick_vaults` vs `vaulted_masonry_roofs`
  - `road_stations` vs `caravanserais`

## Naming

- NEW slugs are short snake_case names for the practice, such as `counting_words`, `token_envelopes` and `blood_price`.
- No slug begins with a digit. For example, "365-day civil year" became `star_rising_civil_year`.
- **Collisions.** None. All 543 new slugs were checked against every quoted snake_case string in main `scripts/` and in `scripts/` on `codex/era-research-pacing`. The only match was `raised_granaries`, which is a deliberate merge into the existing catalog id. No two new slugs are the same.
