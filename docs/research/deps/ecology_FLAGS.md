# Ecology flags

Registry left unchanged. Items whose year conflicts with their prerequisites:

- `copper_outcrop_signs` (140) comes after `ore_assaying` (production 85), `copper_smelting` (90) and `native_copper_working` (68). Prospecting signs should come before smelting. Suggest a year of about 60–75, and then make it a requires_all of `ore_assaying`.
- `herd_size_limits` (8) and `browse_line_monitoring` (12) come before `animal_taming` (nutrition, 16). Managed herds imply taming. Either move `herd_size_limits` to about 18–20 or read it as wild herds. Taming is only a precedent here.
- `hive_sparing_honey_harvest` (50) comes before `wild_honey_smoking` (nutrition, 58). The registry marks it as the follow-on to smoking. Swap the years or move `wild_honey_smoking` to about 40. Smoking is only a precedent here.
- `seasonal_hunting_closures` (108) and `communal_catch_limits` (150) both need `customary_law` (35). The years are fine. They are noted because both ecology rules depend on institutions.
- `pit_pond_reclamation` (350) could later require `stocked_fish_ponds` (nutrition 405). That would need the years swapped, so it is left as is.
