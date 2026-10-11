# Border art direction

## October 11 correction: the map must read before its numbers

The user rejected the encirclement screenshot as unreadable. The earlier critic
acceptance below is superseded: card separation and passing UI checks did not
establish good art direction. Sixteen troop plates, remote battle scoreboards,
leaders and route lines hid the geography and fighting.

The revised idle map uses small force banners, compact contact signals at the
actual battle, and fine held-border strokes. Only active fighting segments work
and brighten. Routes, fallback intentions and tactic diagrams appear for an
inspected formation. Troop counts and report dates remain in one contextual
readout; they come from the same dated report as the displayed force. Garrison
banners are inspectable too. The army bar opens from a compact disclosure or a
selected army, while the War screen retains its explicit full army controls.

Visual review must include an ordinary asymmetric shared border, the former
crowded case at 1152 × 720, close fighting, a focused readout, distant zoom,
night and paused/reduced motion. Mechanical checks alone do not approve the art.

The first screenshot critique rejected remaining archived scout rays, duplicate
legacy war tokens, and contact glyphs that blended into army banners. The next
pass lowers completed scout journeys to background ink (current scout orders
retain their previous contrast), removes redundant war tokens when deployed
fronts own the map, and uses an ivory roundel with crossed weapons at each battle.
Small clearance around that roundel leaves neighboring army targets selectable.
Grouped army members scroll within their allotted bar width at small windows.

Current targeted validation: 154 tests pass with zero errors, failures or orphan
nodes. These include report fidelity, garrison inspection, route focus, shared
objectives, large-army selection budgets, close-ground contact selection, and
all eight member chips in a bounded viewport. The focused 50-band/20-battle draw
check is 6.0 ms on this machine against its unchanged 60 ms limit; it is not a
whole-game frame-rate measurement.

### Final correction evidence

Three implementation passes addressed the rejected hierarchy: first compact
force/contact marks and selection-only detail, then the first critic's route,
duplicate-token and battle-symbol findings, then the second critic's request
for a useful battle hover. The final hover gives location, report day, current
outcome and an accurate watch action without adding idle labels.

The second screenshot critique accepted the default crowded map. The final
read-only review of production `41e09c85` also accepted the coastal overview,
battle hover, selected army, night and reduced-motion views with no remaining
actionable visual blocker in this scope. The selected-army capture shows seven
members with the last member selected and scrolled fully into its bounded strip;
the separate focused regression proves all eight members remain reachable.
Static screenshot review does not establish animation timing.

Final local evidence:

- `C:/Users/sjpur/tt-organic-place-capture/artifacts/border-defense/quiet-coast-r3/`:
  11 passing audit records and 14 PNGs; private GPU process 63988 exited 0 with
  no engine/script errors. Nine actual force identities remain represented and
  hittable in overview, with one real battle and zero default troop cards.
  `crowded_small.png`, `focused_battle.png` and `selected_army.png` show the
  ordinary coast, inspected contact and bounded member strip.
- The coastal fixture uses copied campaign terrain, three actual fort-ledger
  watch camps, seven council-deployed friendly bands and two adjacent opposing
  bands. It clears unrelated copied scout/order archives and old feud state,
  then runs actual marches, observations, combat and production map collection.
  This is an authored conflict, not a claim that the copied campaign naturally
  reached this state. The source save checksum remains unchanged.
- `C:/Users/sjpur/tt-organic-place-capture/artifacts/border-defense/quiet-stress-r2/`:
  both crowded encirclement captures pass. The copied scout archive is retained
  in this run, independently demonstrating the production route-ink correction.
  Private GPU process 52884 exited 0.
- The final temporal probe measures 825 changed blue-front pixels and 1,355
  red-front pixels with decorative contact pulses disabled only for that
  diagnostic. Both sides measure zero changed pixels while paused or under
  reduced motion. The ordinary screenshots retain production pulse settings.
- Root `artifacts/border-critic-final-visual.log` / `reports/report_24`: 154/154
  targeted tests pass with zero errors, failures or orphans. Root
  `artifacts/quiet-final-interaction.log` / `reports/report_25`: the final hover
  refinement passes its 20/20 focused rerun (overlapping tests, not 20 new cases).

The earlier core mechanics run remains 126/127; its unrelated long-run raid
cadence assertion also fails on unchanged main `16982712`. No core simulation
code changed in this presentation correction. The worker branch remains
unmerged and no player/editor process was restarted.

## Original border-control delivery

October 10, 2026. Base `16982712`, branch `codex/border-art-direction`.

The border controls now read as a field atlas: warm paper, quiet plum ink,
serif place names, engraved fort seals and large, grouped readings. The map
remains the place to build and move forts.

## Audit and changes

The old map key, fort note and placement quote gave almost every sentence the
same weight. Staffing, loss and land gained were difficult to find. Night mode
put pale text over a hard-coded pale stretch-label background. Placement quotes
could stay stale when resources changed without moving the pointer; open fort
notes did not refresh their condition or garrison.

- The map key leads with posted watch, the watch on linked stretches and daily
  transport loss, then explains line strength and offers bounded staffing controls.
- Fort notes separate condition or construction progress from garrison, reach,
  distance and daily loss. Move and dismantle remain the same engine actions.
- Placement and move previews emphasize the actual ground gained or relinquished,
  then materials, time, staffing, supply loss and links. Rejected sites state why.
  Moving explicitly explains the temporary loss of held ground during rebuilding.
- Successful placement and movement open the resulting fort's construction note.
  Selected forts receive a quiet compass marker, and move mode has a cancel button.
- Cards avoid one another where space allows; compact keys retain functional
  controls at 1152 × 720. Long preview titles wrap with measured height.
- The War board has a matching border folio, with distinct empty, building,
  unlinked, weak and well-watched states, plus a prominent action into the map.
- Border strokes have fine paper edges with the same gaps and geometry. Smaller,
  higher-resolution fort marks retain their actual kind and construction state.

FortBorder remains the sole authority for costs, fort state, territory and watch.
No save schema, fort rules, day progression, population or foreign visibility was
changed. Existing close-view 3D fort models are retained. The marker texture cache
is bounded; there are no animated people or decorative simulation entities.

## Evidence and reproduction

The root worktree is `C:/Users/sjpur/tt-organic-place-art`. Captures and logs are
ignored local evidence, not committed assets or player saves.

Initial evidence is `artifacts/border-art/acceptance/`: all 55 UI checks passed
across 12 captures, and all seven terrain checks passed across four captures.
After two critic reviews, `artifacts/border-art/critic-r2/` records 71 passing UI
checks across 14 captures. These add no-watch and limited-watch availability,
truthful zero coverage, and a live map-ink refresh while the pointer is away.
All private GPU processes exited normally. Review: pull request #205.

- `artifacts/border-art/fort-tests-final.log`: all 15 existing border tests passed,
  with zero failures, errors or orphan nodes.
- `tests/border_art_probe.tscn --verify`: actual BorderMap controls and FortBorder
  rules on a labeled flat inspection fixture. Covers empty, earliest watch camp,
  valid placement, rejected home ground, missing materials, linked border,
  standing, building, moving, understaffed, night and 1152 × 720 states.
- The probe checks card click interception, share endpoints, Escape/cancel/close,
  condition and stationary quote freshness, actual placement cost and move identity,
  construction-note feedback, layout and unchanged calendar.
- Add `--terrain --save=res://artifacts/organic-places/current.save` to inspect
  authored palisade posts over a copied campaign's actual terrain. The fixture
  freezes the calendar and verifies the copied save's checksum. It does not claim
  that the staged forts arose naturally in that campaign.
- War board plates cover five states in both palettes at 300 px card width:
  `C:/Users/sjpur/tt-organic-place-plan/artifacts/border-board/light.png` and
  `dark.png`. They have no child overflow and leave the ledger unchanged.

Run GPU probes only through `tools/run_isolated_gpu_probe.ps1` with a QA custom
user directory. They render on a private desktop with Dummy audio and exit after
capture. No player session was restarted. Source review also checked the combined
UI and cartography changes; misleading low-condition advice was corrected to
include both garrison and material upkeep.
