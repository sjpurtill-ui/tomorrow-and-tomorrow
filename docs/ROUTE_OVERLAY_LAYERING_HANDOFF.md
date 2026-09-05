# Route overlay layering

Branch `codex/route-overlay-layering`, base `cd82d79`.

Route arrows now draw completely above their own ribbons instead of being sliced
through the center. All route geometry uses the transparent pass above terrain
drapes and below unit counters: route band 10–15, counter band 17–26. Objective
pointers draw above their rings. Existing helper has an optional base priority;
the default remains 20, preserving front/counter order and idempotence.

Warfare runtime probe PASS headless and hidden graphical runs. Tests check alpha
pass, route bounds, arrow-over-line and pointer-over-ring ordering, plus existing
counter/front priorities and cardinal arrow directions in the graphical run.
Capture `artifacts/route-directions-layered.png` inspected against
`artifacts/route-directions.png`: complete arrowheads are now visible.

An initial test assertion treated Label3D as a material-bearing mesh (it inherits
GeometryInstance3D); fixed by excluding labels. That failed test was stopped only
after verifying its parent command matched this task's dedicated log name.

No route positions, widths, mission rules, saves or menus changed. Existing
shutdown resource warnings remain. Shared hotspot local_terrain.gd: overlay helper
and army/scout route material order; do not replace surrounding systems wholesale.
