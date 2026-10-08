# Settlement position stability

Advancing time must not resample an established neighborhood. Population changes
may add construction; existing physical sites remain where they were built.

## Confirmed faults and changes

- Country cluster admission rises from nine to ten near 11,211 people. Previously,
  falling below that threshold hid the tenth installed cluster and discarded its
  growth/layout history. Returning could rebuild it against different templates.
  The renderer now retains installed seeds and their history within the existing
  24-seed limit. Queued, unbuilt candidates are not retained. Identity changes and
  unfounded settlements clear that history. New root claims can still absorb
  overlapping roofs without moving the remaining neighborhood.
- Root detail and density sampling used a stride derived from total plot count.
  Crossing a budget boundary changed membership across the map. Each settlement
  and view now retains eligible plot IDs, fills only available slots and uses the
  original budgets. The cache is capped at 64 views and clears on world changes.
- Aggregate fallback roofs used occupancy, route condition and current cultural
  values to determine counts and placement. Recorded fabric now controls counts;
  each slot has its own deterministic position and random stream. Recorded infill
  appends slots without recentering earlier ones. A physical frontage setback
  keeps small roadside parcels usable while preserving all existing ground,
  polygon, route, slope and overlap checks.
- Early building-form upgrades could discard saved physical sites. Supported
  early replacements now retain those sites and fit their meshes and installed
  details inside the inherited footprints. Construction uses the same transform.

There are no walking people, population-sized node counts, new simulation
authorities or save-format changes. Retention dictionaries are renderer state;
this does not introduce persistent seed history across separate game sessions.
Actual demolition, changed land claims and new construction can still alter the
map. Existing saves load normally; legacy fallback layouts may change once on
loading the corrected renderer.

## Evidence and limits

Source checkpoint: `0c00ce11`, branch `codex/settlement-position-stability`, based
on `a83a0a7f`. Combined with main `5fcd9a97` at `93d2f55d` without conflicts.
The subsequent spy-report update `ce7be622` was combined at `b78a3e5c`, also
without conflicts; all ten new regressions passed again (report 102).

The new regressions failed against the previous implementation (report 97).
Across reports 98–100, all 120 distinct relevant cases subsequently passed:
country retention 4, display stability 6, country visuals 31, early visuals 18,
retained patches 12, construction 11, country plan 28 and organic town 10.
The ten new regressions passed again on combined main (report 101), and the
combined saved-map replay passed all 16 visibility, history, geometry and ledger
checks with exit 0 and no runtime errors.
Two failures during development were corrected: a roadside fallback placement
regression and Dummy-renderer transform readback in the new test. The latter now
checks the exact recorded transforms submitted to the batch, as existing tests
do; footprint containment assertions remain in place.

A copied Wallyfire save contained 10,565.7456 people, day 109510, 240 plots and
375 saved building sites. It predates the reported 11,500-person view. A controlled
presentation replay used its actual root geometry, crafts and terrain at
10,565.7456 → 11,500 → 10,565.7456 → 11,500. Baseline code hid the tenth cluster's
27 roofs and deleted its history on the dip. Corrected code kept all 27 visible
with exactly unchanged positions, angles and footprints. With frozen templates,
the baseline returned to the same coordinates: this replay proves disappearing,
not the user's complete observed relocation. Separate regressions exercise
history loss with changed templates, early upgrades and fallback slot movement.
The 240-plot checkpoint does not reach the root display-budget threshold.

The replay changes only presentation snapshots, not simulated days or population
ledgers. It is not a GPU/frame-performance benchmark. Saved replay output,
metadata, logs and baseline scripts remain in ignored
`artifacts/settlement-position-stability/`; no campaign save is committed.

## Reproduction

Run the eight named GdUnit suites headlessly with Dummy audio and the explicit
worker path. The saved-map probe is
`tests/settlement_position_stability_probe.tscn`, passed `--position-stability`.
It requires private `TomorrowPeopleGrownLandQA` userdata and a copied save at
`artifacts/settlement-position-stability/current.save` (or `--save=<copy>`).
Export `settlement_country_plan.gd` and `settlement_country_visual.gd` from
`a83a0a7f` into the ignored `baseline` subdirectory; rewrite the baseline visual's
PLAN preload to that baseline plan. `--after-only` explicitly skips comparison.
The probe records checks and exits nonzero for missing setup, lost visibility or
history, changed physical records, unfinished target work or changed ledgers.

No live player was restarted or used as a test process. Save and restart through
the canonical launcher to load the integrated scripts.
