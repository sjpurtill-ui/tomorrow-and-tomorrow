# Aerial ruin traces

Branch `codex/neighborhood-ruin-traces`, base `d9485b9`.

Damaged/destroyed neighborhood sectors now retain muted broken foundation and
rubble traces derived from the same procedural roof masks whose structures were
lost. Surviving roofs remain more prominent. Activity bright spots follow structure
survival instead of appearing in cleared sectors. Detail filters out with pixel size.

No added geometry, textures, nodes, simulated structures, menus or save changes.
Only the kind-5 aerial shader and source-level regression assertions changed.
One additional procedural noise evaluation applies inside the destruction branch;
GPU timing has not been benchmarked independently.

Validation: 79 settlement visual architecture tests PASS. Hidden, self-quitting
production-shader condition capture completed without shader errors. Pixel checks
against the previous condition fixture: zero changed pixels in all six GREAT through
POOR interiors; changes confined to DAMAGED/DESTROYED. Surviving structures and
open ground are not repopulated. Traces are aggregate appearance, not individual
saved building ruins or explorable interiors.

Captures (ignored): `artifacts/neighborhood-open-ground-final.png` before and
`artifacts/neighborhood-ruin-traces-final.png` after. The first trial was too faint
and was adjusted after inspection. Final traces remain subordinate to intact roofs.

Shared-file integration hotspot: `scripts/local_terrain.gd`, kind-5 shader after
urban roof coverage and activity spot calculation. Preserve other terrain work.
