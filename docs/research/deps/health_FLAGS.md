# Health dependency flags

These are year concerns found while mapping. The registry was not changed.

1. **`healer_titles` (368) comes before `healer_specialization_customs` (378).** Titles such as "tooth-healer" and "eye-healer" presuppose healers who specialise. Swap the two years, or move specialisation to about 360. Mapped with specialisation as a precedent of titles, because the bands overlap.
2. **The id `household_water_boiling` (13) does not match its name, "Drinking water left to settle".** Boiling would need fire-resistant pots (`pit_firing` 20, `clay_tempering` 22). Mapped as settling in baskets or clay vessels. Rename the id, or move true boiling after 22.
3. **`burial_ground_separation` (272) vs. its culture alias "cemeteries set apart" (140).** The dependency chain supports 272 (after `outbreak_burial_protocols` 222). Separate cemeteries appear historically well before sanitation reasoning, though. Keep 272 for the health effect only if culture keeps its own earlier cemetery practice.
4. **`ash_fat_soap` (345) overlaps the later catalog `soap_manufacture`.** Make sure the later entry requires this one and does not duplicate it.
5. **`copper_razors` (355) looks late.** Copper working is known from 68–105. Suggest about 200–250.
6. **`tooth_drilling` (31) uses beeswax, but `wild_honey_smoking` is at 58.** See nutrition flag 4.
7. **`embalming_anatomy` (400) is gated by `environment: dry`.** Desiccation-based preparation of the dead is typical of arid regions.
