# Research lists for years 2400–3000: brief

## Format
Use the same format as the approved `docs/research/y1200/*_1200_1800.md` lists. Read `KNOWLEDGE_1200_1800.md` first and match it:
- Scope, Historical anchor, Research time, Id and Today columns.
- Two tables: "Years 2400–2700" and "Years 2700–3000".
- A compact pacing summary and key thresholds.
- A "Government and civic life" section.
- A short table of items that are currently far too early or too late.

## Timeline
From the `scripts/technology_eras.gd` CURVE `[[2400,1800],[2800,1950],[3000,2030]]`:

| Game year | ≈ AD |
|---|---|
| 2400 | 1800 |
| 2500 | 1838 |
| 2600 | 1875 |
| 2700 | 1912 |
| 2800 | 1950 |
| 2900 | 1990 |
| 3000 | 2030 (the end of the game) |

The window covers the industrial revolution, steam, railways, the telegraph, industrial chemistry, electricity and the internal combustion engine. It continues through mass politics, world-scale industrial war analogs, antibiotics and vaccines, the green revolution, computing, nuclear power, spaceflight, networks and the information age, and ends in the near future of 2030.

## Existing catalog
The existing game catalog is heavily modern. Most catalog ids in `scripts/*_knowledge.gd` and `technology_eras.gd` HISTORICAL_YEAR belong in this window, so place them all by catalog id. The time pressure is extreme: about 250 historical years, but only 600 game years. Keep lists dense, about 100–130 per line, and pace them.

## Placement
- Place every earlier `belongs_later` item.
- End-of-game items, near the 2030 frontier, may be speculative-plausible but must not be science fiction.

## Rules
- **Alternative history.** Use generic names only. No real people, companies, nations, wars or events. Real history is calibration only.
- **No duplicates.** Continue from all earlier registries: `docs/research/registry.json`, `y600/registry_1200.json` and `y1200/registry_1800.json`. Also check the `y1800/` lists and registry for 1800–2400, which are being written in parallel; read them before finishing. Never duplicate an id. Use "(continues: id)" for items that extend an earlier one.
- **Research time.** 1 day per second.
- **Tone.** The player is a god-figure. No victory framing.
- **Government tags.** Tag rows that change government, civic life or the court with `[gov: …]`. Examples: universal suffrage, the welfare state, the civil service exam, mass media, central planning, constitutional courts, the surveillance state.
- **Security.** Security discoveries change what generals can do; the player never controls units. Weapons of mass destruction may exist as research, framed soberly.
- **Cross-line de-duplication.** Other agents are writing other lines at the same time. Before finishing, read their files in this folder and remove your duplicates. Never delete an item unless the other line clearly keeps it. Re-check once at the very end.
- **Scratch files.** Use your own scratchpad subfolder.
