# Border art direction

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
