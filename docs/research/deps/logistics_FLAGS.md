# Logistics flags

Registry left unchanged. Items whose year conflicts with their prerequisites:

- `reed_bundle_boats` (36): the name says the boats are sealed with bitumen, but `bitumen_sealing` (infrastructure) is at 58. Bitumen is only a precedent here. Either move `reed_bundle_boats` to about 55–60 or drop "sealed with bitumen" from the name.
- `river_craft` (14): dugouts need a ground adze, but `ground_stone_axes` (production) is at 16. The ground adze is only a precedent here. The gap is within the band, so this is minor.
- `vermin_deterrent_placement` (6): this comes before `pest_deterrent_storage_herbs` (nutrition, 13). The herbs are only a precedent here. This is minor.
- `treenail_fastening` (335) and `plank_spiling` (355): tenoned plank hulls historically needed metal chisels, but `copper_carpentry_tools` (production) is at 350. The chisels are only a precedent here. Consider moving `copper_carpentry_tools` to about 320.
- `hired_carriers` (485): this comes before `hired_labor_contracts` (labor, 520). The more general contract should come first. Consider moving `hired_labor_contracts` to about 480 or earlier.
- `pack_animals` (150): the donkey was domesticated in dry lands and was borrowed elsewhere. It is gated by `environment=dry`. If the engine treats this as a hard gate, also let `contact_required` satisfy it.
- `onager_hybrid_teams` (390) → `battle_wagons` (security 390): the years are the same. The hard link is valid (≤).
- Registry overlap: `road_stations` has no later `caravanserais` id in the registry, so there is nothing to merge.
