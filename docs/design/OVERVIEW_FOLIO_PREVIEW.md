# Overview folio — held for visual approval

Status: HELD. The user requested a replacement for the Overview's diagram-like
town and repeated meters, with a rendered example before integration.

Base: `8938da235ed115ab5942704aa773d66a8e616537`.
Branch: `codex/overview-folio`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-walk-facing/TomorrowandTomorrow`.

The Overview uses painted architecture, large serif values, quieter labels and
condition notes, and an optional text comparison with scouted towns. The source
ledger, era vocabulary, row navigation, local leader, work choices, seat-growth
description, water-work controls and history remain authoritative and intact.
Comparisons retain the reported words and age of each sighting; they never read
the foreign town's hidden state. Live refresh updates existing reading nodes.

The new renderer derives from the current overview. Culture, inquiry, history
and foreign-town renderers continue using their existing base. Shared changes
are confined to the overview renderer choice in `dock_blocks.gd` and two
presentation fields in `own_town_model.gd`: architecture tier for illustration
selection, and removal of the outdated reference to a lore bar in its tooltip.
There are no simulation, labor-authority or save-schema changes.

## Art and scope

Built-in imagegen produced `assets/ui/overview/town-portraits-v1.png` (1536 × 1024,
four 768 × 512 plates). Original generated file:
`C:/Users/sjpur/.codex/generated_images/01a10976-5d5e-7d63-9bed-ecfaf28f1fab/exec-b57e41ff-34b6-4f43-801f-0dc28258a6e6.png`.

These are representative paintings of four architectural stages, selected from
the town's existing fabric tier. They are not an exact map, and do not depict
every individual completed work, ruin or defensive wall. Exact conditions remain
in the readings and tooltips. The four plates cover preindustrial architecture;
individual cultural and industrial-era paintings remain a future art expansion.
The original atlas is unchanged; a page shader dissolves its paper background
into both supported themes. Rendered examples use prepared test records.

## Validation and handoff

- `test_own_town_page.gd`: 10/10 passing, report 22. Includes exact owning-ledger
  values, returned scouting estimates, secondary-town scope, era words, controls,
  row navigation, history and contrast. The renderer test now checks the text
  comparison disclosure instead of obsolete meter nodes.
- The old suite was also run against its original base renderer (report 21),
  reproducing its stale New towns switch expectation. The fixture now asserts
  the current seat-growth description and absence of the removed switch, allowing
  the existing leader, work and report actions to run to completion.
- Private GPU previews cover early and developed towns, light and dark themes,
  and a secondary town at 1138px. Top, scrolled readings and expanded comparisons
  are captured; open comparisons are checked across a dock refresh.
- Generated captures, Godot caches, imports and UID files are excluded from Git.
  All probes use acceptance-specific userdata and exit after capture.

Reproduce with `tools/run_isolated_gpu_probe.ps1`, explicit worktree path,
scene `res://tests/overview_folio_preview.tscn`, and user arguments
`--overview-preview --case=late --mode=dark --out=res://artifacts/overview-final-dark`.
For the compact secondary town use `--case=secondary --width=1138`.

Do not integrate without visual approval. Review shared-file changes against
concurrent work. The canonical checkout and player session were not modified
or launched by this task. No save migration is needed.

## Art prompt

Use case: historical-scene. Create ONE production game illustration atlas,
1536x1024 landscape, a precise 2 by 2 grid of FOUR independent equally sized
painted vignettes. No text, no lettering, no UI, no borders, no frames. Each
quadrant has its OWN isolated town scene centered safely within that quadrant,
with broad warm ivory parchment margins all around and softly dissolving
watercolor edges, no marks crossing between quadrants. Premium illustrated
historical atlas style, sophisticated finely detailed gouache and watercolor,
warm ochre, weathered timber, muted sage vegetation, natural cast shadows,
compelling elevated three-quarter perspective, tiny ordinary people carrying
baskets and working. Not icons, not diagrams, not cartoon, not game screenshots.
TOP LEFT: a very small prehistoric encampment with a few hide tents and lean-tos
near a hearth, baskets and drying poles, earth paths, open ground, no walls.
TOP RIGHT: a beautiful established early village of clustered reed-thatched
timber and earth huts, a communal timber hall, woven stores, tiny people working
along curving earthen paths, a few trees; no fortifications, no castles, no
monumental buildings. BOTTOM LEFT: a larger developed preindustrial timber and
earthen town with varied modest houses and workshops, winding lanes, a modest
town square, everyday human life, no fortifications and no castles. BOTTOM RIGHT:
a mature town of mixed masonry, timber and plaster low-rise homes and workshops,
modest streets and courtyards, no fortifications, no castles or churches or
skyscrapers. Beautifully hand painted architectural detail and atmospheric depth
in every vignette. All four towns depicted at same camera perspective, distinct
density and architectural progression. Background parchment exactly pale warm
ivory, RGB approximately 245,236,219. Scene illustrations only, no decorative
compass roses or invented labels. This will be cropped into four individual
paintings for a real game Overview page.
