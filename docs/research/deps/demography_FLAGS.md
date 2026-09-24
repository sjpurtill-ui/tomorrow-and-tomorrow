# Demography dependency flags

These are year concerns found while mapping. The registry was not changed.

1. **`census_rolls` (institutions 295) vs. its merged demography alias (330).** Demography chains (`people_herd_counts` 345, `household_vital_lists` 440) require it. Either year works; 295 is kept.
2. **`weaning_food_softening` (118) duplicates nutrition `weaning_food_customs` (365).** See nutrition flag 3.
3. **`rural_urban_migration` (262) comes before any explicit town discovery.** Examples are `town_enclosure_walls` (300) and `town_identity` (culture 330). It is mapped on `satellite_hamlets` plus `tributary_villages` (215). Consider moving it to about 300, or adding a town threshold.
4. **`three_year_nursing` (568) vs. `lactational_spacing_awareness` (2).** Prolonged nursing is ancient. Only the fixed three-year custom, seen in wet-nurse contracts, fits 568. Keep 568 only if the item means the codified term.
5. **`children_light_tasks` (labor 16 vs. demography alias 32).** This is not mapped here. It is noted because none of the demography items required it.
6. **`min_settlements` conditions** are used on alliances, refugee hosting, satellite hamlets and urban migration (2–3). No `min_population` values were set, because the engine's population scale was not checked.
