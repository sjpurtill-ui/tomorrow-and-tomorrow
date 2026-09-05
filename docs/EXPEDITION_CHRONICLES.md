# Expedition chronicles

Long journeys produce structured discovery records linked to their real deposits. Terrain and the resource system's recognition chronology govern flint, salt and medicinal-plant discoveries. Common materials remain useful to a nearby outpost; they are no longer the headline prize of annual exploration. Distant deposits require normal extraction and transport. Route evidence feeds the existing investigation system. Open water cannot generate land deposits. The illustrated landmark system has been retired, including its navigation bonus; original Midjourney art is preserved under `archive/retired-landmarks/`.

The report separates Discoveries from Journey & Accounts. The former uses a painted cover, typographic discovery cards, and practical implications. The latter contains a chart of the actual recorded route, contacts, recruitment outcomes and supplies. Days away uses departure-to-return time for new records. Old reports retain their actual outcomes and are never retroactively granted finds. Retired landmark cards and related journal lines are removed when older saves load.

## Cover art

Asset: `assets/textures/expeditions/chronicle-dawn.png`. Generated using the built-in image generation tool, then copied into the project. The image is a symbolic journal cover, not a map or depiction of a particular discovery.

Generation prompt:

Use case: stylized-concept / historical-scene. Create one beautiful panoramic editorial illustration for a historical civilization game's expedition chronicle. Asset type: decorative header painting, landscape aspect 3:1, no text, no UI. Depict a small anonymous party of ancient foot travelers with simple cloaks, walking staffs and packs on a dark foreground ridge, gazing into layers of vast distant country at dawn. Sense of wonder, difficult distance, the unknown horizon. Sophisticated painterly gouache and engraved field-journal linework, not cartoon, not photorealistic. Rich deep petrol teal shadows (#102528), muted sage, warm parchment and luminous antique gold dawn, restrained copper accents. Strong silhouette and beautiful atmospheric depth; fine handmade texture. Travelers tiny relative to the world, lower left third. No castles, no invented ruins, no treasure, no weapons in focus, no fantasy creatures, no modern equipment, no lettering. This is a symbolic expedition cover, not a depiction of a specific discovered landmark. Full-bleed elegant composition that reads at 740 by 245 pixels.

## Validation

After retiring landmarks, all seven expedition cases pass, including migration from an old save containing landmark rewards. Save/load, the command rail, and expedition rendering probes pass. All four new covers render in the real report dock. See `EXPEDITION_ART_PROMPTS.md` for the built-in generation prompts and asset names.

All six cases in `tests/test_expedition_findings.gd` pass: real deposit linkage, no teleportation of distant supplies, recognition/terrain gates and later metal variety, no land discoveries on water, old-report compatibility, and return/save/load persistence. The existing 69 civilization tests, four civic implementation tests and scout runtime probe also pass. `tests/expedition_report_visual_probe.tscn` renders the real report components and saves both tabs under `artifacts/` when run with a graphics display; both tabs were visually inspected.
