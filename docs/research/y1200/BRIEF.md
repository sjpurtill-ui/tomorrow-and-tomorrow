# Research lists for years 1200–1800: brief

## Format
Use the same format as the approved 600–1200 lists (`docs/research/y600/*_600_1200.md`). Read `docs/research/y600/KNOWLEDGE_600_1200.md` first and match it:
- Scope, Historical anchor, Research time, Id and Today columns.
- Two tables, **Years 1200–1500** and **Years 1500–1800**, with the columns Year (band) | Discovery | Research | Real time | Id | Today.
- A compact pacing summary and key thresholds (bold rows).
- A short table of catalog items that are "currently far too early / too late".

## Timeline
From `scripts/technology_eras.gd` CURVE `[[800,-500],[1500,1000],[2000,1600]]`:
- game 1200 ≈ AD 360
- game 1300 ≈ AD 570
- game 1400 ≈ AD 790
- game 1500 ≈ AD 1000
- game 1600 ≈ AD 1120
- game 1700 ≈ AD 1240
- game 1800 ≈ AD 1360

That span runs from late antiquity analogs through the early medieval world and the high-medieval expansion, ending just before gunpowder weapons become decisive. Examples of what belongs here:
- **Agriculture:** heavy mouldboard ploughs, three-field rotation, horse collars and horseshoes.
- **Power:** water and wind mills everywhere.
- **Ships:** stern rudders, the magnetic compass, lateen and cog ships.
- **Crafts:** the spinning wheel, treadle looms, blast furnaces late in the window.
- **Writing and learning:** paper spreading, block printing, positional numerals with zero, algebra, universities and scholastic method.
- **Commerce:** double-entry-like accounting, bills of exchange, banking houses, merchant law.
- **Society:** guilds, chartered towns, manorialism and feudal tenure.
- **Warfare:** castles, the counterweight trebuchet, stirrup shock cavalry, crossbow ubiquity, plate appearing late.
- **Health and ecology:** hospitals and plague responses, quarantine late in the window, forest law and common-land management.

## Rules
- **Alternative history.** Discovery names are generic, era-appropriate practices. Do not use real places, people, empires, religions or events in names or ids. Real history is calibration only.
- **Continue from earlier registries.** Continue from the 0–600 registry (`docs/research/registry.json`) and the 600–1200 registry (`docs/research/y600/registry_1200.json`). Never duplicate an existing id. Improvements of earlier items can be new discoveries with distinct names, noted "(continues: id)".
- **Place existing catalog ids.** Existing catalog ids beyond game 1200 (in scripts/*_knowledge.gd and technology_eras.gd HISTORICAL_YEAR) must be placed in this window if they belong here, using their catalog id, or listed as "belongs later".
  - Also place every item that the 600–1200 registry marked `belongs_later` and that falls in this window: craft_guilds, counterweight_engines, spinning_wheels, pike_drill, canal_locks, printing_process, relief_block_cutting, movable type, chemical_distillation, optical_lenses, carvel/clinker construction, steel_refining, and others. Check `belongs_later` in registry_1200.json.
- **Research time and length.** Research runs at 1 day/s, so 1 game year ≈ 6 real minutes. Lists are LONG: about 70–100 per line, one short line each.
- **Tone.** The player is a god-figure. No victory framing. Keep it era-grounded.
- **Cross-line overlap.** Other agents are writing other lines at the same time. Before finishing, read their files in `docs/research/y1200/` and remove your duplicates. Name the owning line in your key thresholds text.
- **Government and civic life.** Note in the key thresholds which discoveries should visibly change government and civic life: new offices, court composition, law, the seat of rule's architecture. A civic-evolution pass will use them.
