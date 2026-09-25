# Years 1800–2400 research lists — brief

## Format
Use the same format as the approved lists in `docs/research/y1200/*_1200_1800.md`. Read `KNOWLEDGE_1200_1800.md` first and match it:
- Scope, Historical anchor, Research time, Id and Today columns.
- Two tables: "Years 1800–2100" and "Years 2100–2400".
- A compact pacing summary and key thresholds.
- A "Government and civic life" section.
- A short table of items that are currently far too early or too late.

## Timeline
From the `scripts/technology_eras.gd` CURVE `[[1500,1000],[2000,1600],[2400,1800]]`:

| Game year | Historical year |
|---|---|
| 1800 | ≈ AD 1360 |
| 1900 | ≈ AD 1480 |
| 2000 | ≈ AD 1600 |
| 2100 | ≈ AD 1650 |
| 2200 | ≈ AD 1700 |
| 2300 | ≈ AD 1750 |
| 2400 | ≈ AD 1800 |

The window runs from the late-medieval crisis through the gunpowder transition, the printing press, oceanic navigation and global exchange, the scientific revolution, the early-modern fiscal-military state and the Enlightenment. It stops at the threshold of industrial steam power. Watt-type engines and factories belong in the last decades only, and mostly later.

## Required placements
- Decisive gunpowder weapons: hand cannon, then matchlock, then flintlock, plus artillery and bastion fortresses.
- Metal movable type and the screw press.
- Ocean navigation: carrack/galleon, latitude sailing, then longitude late in the window.
- Double-entry bookkeeping, joint-stock companies, central banks and public debt.
- Scientific method, telescopes and microscopes, calculus, the pendulum clock and the barometer.
- Variolation, then inoculation late in the window. Quarantine stations.
- New-world crops through contact: maize, potatoes, coffee and sugar are all contact-gated.
- Enclosure, the seed drill, and the four-course rotation late in the window.
- Canal networks and turnpikes.
- Standing professional armies, drill manuals and general staffs late in the window.
- Parliaments, constitutions, bureaucratic cameralism and the census.

Place every catalog id that the 1200–1800 registry marked `belongs_later` (see `docs/research/y1200/registry_1800.json` when it exists, otherwise the lists' belongs-later tables) if it falls in this window. Place every catalog id in `scripts/*_knowledge.gd` and in `technology_eras.gd` HISTORICAL_YEAR whose year falls in the window.

## Rules
- **Alternative history.** Use generic, era-appropriate practice names. No real places, people, empires, religions or events. Real history is calibration only.
- **Continuity.** Continue from all earlier registries: `docs/research/registry.json`, `y600/registry_1200.json` and `y1200/registry_1800.json`. Never duplicate an id. Mark improvements "(continues: id)".
- **Research time and length.** Research runs at 1 day/s. Lists are LONG: about 80–110 per line, one short line each.
- **Tone.** The player is a god-figure. No victory framing.
- **Tag government changes.** Tag rows that change government or civic life, or the court, with `[gov: offices|court|law|seat|towns|culture]` in the Discovery column. For example: parliaments, cabinets, ministries, standing bureaucracy, courts of law, constitutions, the press.
- **Security.** Security discoveries change what generals can do; the player never controls units. See `docs/GENERAL_CAMPAIGN_DESIGN.md` in the canonical repo (read only).
- **De-duplication.** Other agents write the other lines at the same time. Before finishing, read their files in this folder and remove your duplicates. Do not delete an item unless the other line clearly keeps it; name the owning line in your key thresholds. Re-check once at the very end.
- **Scratch files.** Use your own scratchpad subfolder.
