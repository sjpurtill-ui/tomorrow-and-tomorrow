# Nutrition dependency flags

These are year concerns found while mapping. The registry was not changed.

1. **`resin_sealed_wine` (65) comes before `fermentation_control` (116).** Wine in sealed jars is a controlled ferment. Either move `fermentation_control` to about 60, or move wine after 116. Mapped for now with wine needing only pottery and fruit, and `fermentation_control` listing wine as a precedent.
2. **`ox_drawn_ard` (145) comes before `paired_ox_yoke` (185, logistics).** A yoked ox team needs a yoke. Move the yoke to 145 or earlier, or move the ard later. Mapped with `ox_drawn_sledges` (135) as a precedent only.
3. **`weaning_food_customs` (365) nearly duplicates `weaning_food_softening` (demography 118).** Both describe soft weaning foods. Merge them, or rename 365 to a distinct practice. Mapped as a follow-on to 118.
4. **`wild_honey_smoking` (58) looks late.** Honey hunting with smoke is Palaeolithic. Health `tooth_drilling` (31) uses beeswax fillings. Suggest about 20–30.
5. **`sesame_oil` (425) and `fruit_tree_grafting` (585) are regional.** Both are marked `contact_required`. In a region without the crop or the skill, they should come from a contacted people.
6. **`salting_fish_meat` (155) is gated by `resources_known: ["Salt"]`.** Inland settlements without salt should get it through `salt_shell_routes` (90).
