# Infrastructure year flags

Registry years left unchanged.

- `timber_post_beam_connections` (180): the description says "copper chisels", but `copper_carpentry_tools` is at 350. It is mapped on `copper_casting` (105). See production flags.
- `dressed_stone_masonry` (350) shares a year with `copper_carpentry_tools` (350), which it requires. This is legal, but the item will unlock the moment the tools do. Moving the tools earlier (see above) resolves it.
- `wooden_log_conduits` (500): hollowed logs need only axes and channels (about 105). The year looks late. Suggest about 150–250, unless it is meant as pressurized log mains.
- `corbelled_vaults` (275) / `pitched_brick_vaults` (455): these may overlap with the later catalog `vaulted_masonry_roofs`, as `REGISTRY_NOTES` records. Both are mapped as distinct techniques. Corbelling requires `megalith_raising`.
- `ventilated_granaries` (450) requires `raised_granaries` (nutrition 85). The infrastructure alias "raised storehouse floors" (65) was merged there, so there is no conflict.
- `rigid_pipe_bedding` (425): `water_trough_leveling` (knowledge 460) is a precedent only. Levelling comes in through `runoff_grade_reading`, which uses `rod_and_cord_leveling` (240).
- `mine_shoring` (570): galleries have been mined since `fire_setting_mining` (115), with no shoring for about 450 years. This is plausible for shallow workings. No change.
- `rammed_earth_construction` (360): it could come earlier (about 250), since it needs only board forms and levelling. Low priority.
- `shared_work_crew_rotation` (270) is kept separate from `labor_rotations` (1), as `REGISTRY_NOTES` records. It is mapped as the infrastructure-upkeep form of rotation.
