# Court interiors and 200-year renewal

Status: READY for integration; this worker branch is not the player build.

Worker: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`, branch
`codex/government-interiors`. Base `3b620e3296ff851c74d72d8a7265781fc473975f`
combines integrated main `3c8ddbe3` with the completed dress/etiquette dependency
`c58b478f`. Only the designated integrator should merge into main.

## Behavior

The room design advances at each 200 elapsed campaign years, from year 0 through
3000 inclusive. This uses `GameState.elapsed_days / 365`, not accelerated research
scholarship. The sixteen authored rooms are:

| Elapsed year | Interior |
| --- | --- |
| 0 | Common hearth, windbreak and log seats |
| 200 | Timber community hall |
| 400 | Plastered courtyard and records alcove |
| 600 | Masonry audience hall |
| 800 | Colonnaded council room |
| 1000 | Vaulted administrative room |
| 1200 | Late-antique chamber of records |
| 1400 | Early-medieval timber great hall |
| 1600 | High-medieval stone great hall |
| 1800 | Late-medieval chancery or civic chamber |
| 2000 | Early-modern secretariat |
| 2200 | Cabinet council room |
| 2400 | Ministerial working office |
| 2600 | Industrial department office |
| 2800 | Mid-century executive conference room |
| 3000 | Contemporary government conference room |

This chronology follows the game's existing `TechnologyEras.CURVE`; elapsed game
years are not AD dates. Construction knowledge or an established civic room limits
the building family. A society behind the calendar renovates its supported floor
plan by alternating entrance/service sides and modest room proportions. It does
not receive new technologies. Sixteen distinct primary designs serve the normal
progression; limited societies reuse their supported family with these variations.

Glazing, paper, bound records, lamps, radiators, phones, typewriters, computers,
ventilation and displays are gated by actual known discoveries. Monarchy and
assembly remain the existing civic system's decision. Neither the calendar nor
room selection changes offices, knowledge, population or institutions.

Early glazing uses small panes, with leaded diamonds in the medieval rooms.
Later government interiors use maintained plaster, restrained upholstery, finished
wood and regular modern tiles. These finishes are reproducible manifest metadata;
the shared shader retains the earlier halls' weathering and woven borders.

The working desks have nearby chairs. Conference chairs face a shared table and
use explicit side approaches. Navigation includes the actual furniture, geometry
transforms and chair access, including departures during acted scenes. No walking
or turning kinematics have been replaced. Authored chairs suppress portable stools.

Rooms explicitly declare hearth, enclosure and floor. Offices have no phantom
hearth light, invisible fire obstruction or ambient crackling. Enclosed rooms have
no falling snow, breath clouds or flies; the authored medieval hearths have flames
without indoor smoke columns. Footsteps distinguish earth, timber and stone.
The lightweight court overview follows the same chapters and civic lean.

The four retained executions stay enabled; no additional method is re-enabled.
An explicit fire act can create a temporary effect, removed on completion or skip.
Working offices do not reconstruct a camp's skull-stake avenue from lifetime death
counts. The ledger, narration facts, acted effects and explicit statues remain
unchanged.

Merged figure draw materials now remain owned until all their mesh children have
been destroyed. This fixes a pre-existing material teardown error without changing
animation or clothing. Legacy camp tests explicitly request their fixture room;
the casting test disposes its modal before clearing the shared acting service.

## Scope and compatibility

Additive room GLBs and manifest, reproducible Blender builder, court presentation,
navigation, chair staging, sound and diagnostic tests. No changes to terrain,
`project.godot`, save schemas, consequence rules or official ownership. Existing
saves derive their room from elapsed time and known discoveries on opening court.
Existing base figure GLBs and wardrobe bundles are unchanged.

Shared-file conflicts for integration: `audience_modal.gd`, `court_backdrop.gd`,
`court_set_3d.gd`, `court_stage.gd`, `court_paths.gd`, `court_exec_stage.gd`,
`court_sound.gd`, `court_foley.gd`. Preserve newer canonical work and the earlier
motion/execution fixes. Also review `court_figure_3d.gd` and
`assets/court_sets/shaders/court_set_toon.gdshader`. Import new GLBs in the
integration worktree before testing.

## Validation and delivery

Implementation checkpoint: `96fd21ff` on `codex/government-interiors`. The final
handoff commit adds this document and the new scripts' Godot UID metadata. The branch includes the preceding complete
court dress/etiquette dependency; review it as a combined branch against main.

- Combined GdUnit run: **354/354**, 25 suites, zero errors, failures, skips or
  orphans; exit 0. `artifacts/court-chapters-verified-tests.log`, report 36.
  Covers chapters, civic stages, attire, etiquette, acting, motion, chair paths,
  executions, gore, room geometry, directing and sound.
- Raw room validator: **16/16**, 90 authored chairs, 117,940 triangles across all
  16 models, 11,242,872 bytes. The final chapter-13 typewriters face their clerks;
  the validator checks key orientation. All navigation bounds/marks are unchanged.
- Actual imported-mesh circulation: **192/192** seat arrivals/departures at asset
  checkpoint `8c1c4be1`; the final typewriter-only correction preserves those bounds.
  Evidence: `C:/Users/sjpur/tt-court-interior-seating/artifacts/interior-routes-partition-final.log`.
- Original figure/wardrobe raw invariants: **7/7**. Rig/face and static coverage
  remain valid; `artifacts/court-chapters-wardrobe-invariants.log`.
- GPU capture of all 16 chapters: **36 images**, chapter selection and enclosure
  assertions pass. `artifacts/court-chapters-delivery-gpu.log`,
  `reports/court_chapters/`. Actual Godot images were reviewed for architecture,
  desk reach, chair direction, finishes and medieval/modern transitions.
  The private-desktop probe exited successfully; the player's desktop stayed
  unchanged. The Compatibility renderer's expected depth-of-field warning remains.

- After the final chapter-13 correction, editor import passed, the imported-room
  suite passed **8/8** again (`artifacts/court-chapters-final-assets-tests.log`,
  report 37), and all 16 chapters were captured again. The corrected typewriters
  were visually checked; the private GPU process exited with code 0 and was
  confirmed absent afterward.

Captures, generated imports, caches and reports remain local evidence, excluded
from source commits. Existing unrelated generated import churn is preserved.
No player game or editor has been launched or interrupted. No canonical main
merge has been performed; pushing the worker branch does not deliver the player
build. The designated integrator must reconcile, test, push and verify main.

The preceding wardrobe pass's documented pose-stretch flags remain a limitation;
this room pass does not claim to eliminate them. See
`docs/COURT_ERA_PRESENTATION_HANDOFF.md` and `docs/COURT_ERA_WARDROBE_HANDOFF.md`.
The rooms are stylized reusable families, not exact reconstructions of every
culture. Optional office equipment is presentation; no new office-work simulation
is introduced. City graphics are outside this interior pass.

## Design references

These are functional references, not exact replicas or measured reconstructions.
Medieval public hall/private-room separation: [English Heritage, Old Soar Manor](https://www.english-heritage.org.uk/visit/places/old-soar-manor/history/)
and [Goodrich household](https://www.english-heritage.org.uk/medievalhousehold).
Working administration and ornate diplomatic rooms have different purposes:
[FCDO building history](https://www.gov.uk/government/history/king-charles-street).
Conference table sightlines: [Downing Street cabinet history](https://history.blog.gov.uk/2016/12/16/harold-macmillan-and-the-geography-of-power-at-no-10/).
Institutional seating, clerks and witnesses: [Parliament committee-room guide](https://committees.parliament.uk/publications/51114/documents/283391/default/).
