# Court atmosphere and city character

Status: **READY for integrator review; not integrated into the player build.**
Worker branch: `codex/court-atmosphere`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.
Base: `05c9ecce98486738b60236844dc51dc4dcdc1aba`, the completed court evolution
checkpoint, including integrated main `ec537b74fa82253806dc3cb5ee2ce9bd718ba81d`.
This is a follow-up to `docs/COURT_EVOLUTION_POLISH_HANDOFF.md`. Neither worker
branch is a claim that the canonical player build has been updated.

## Runtime changes

- Glass, metal and ceramic receive separate painted finishes. Paper, hide and
  plaster retain their matte response. Authored chapter overrides still win;
  highlights respect each light's specular contribution.
- At most two small daylight meshes project through authored rear apertures to
  the floor. They use no extra lights or CPU animation, follow mirrored room
  renewals, switch off on low quality, and yield to the god's dramatic light.
- Window fills and one broad, diffuse room-return light keep the cast readable,
  dim with the room during divine speech, and restore exactly. The return adds
  no shadow map. Actual camera review prompted its final energy/position tuning.
- Conversation attention travels through the room with a short stagger. Brief
  glances expire, newer speakers supersede older attention, and idle actions
  defer to foreground performances. Overlapping hushes retain their deadline.
- Deterministic modern facade families vary material and bay treatment while
  retaining the original footprint, storeys, roof and building provenance.
- All sixteen rooms have quieter finished joinery and supported, gated records
  and desk details. Original furniture, architecture and movement marks remain.
- Existing city representatives use actual frontages and bounded, cached paths
  around recorded footprints. Smoke comes from rendered chimney caps. Geometry
  refresh reconciles adults and children and updates smoke heights on the same
  day. Overflow remains conservatively blocked; an entirely inaccessible site
  temporarily omits its visual actors without changing the population ledger.

## Validation and integration

Combined headless court regression: **429/429, 38 suites**, zero errors,
failures, skips or orphans. `artifacts/court-atmosphere-full-tests.log`, report66.
After the final room-return energy/position adjustment, **170/170 across ten
focused court-lighting, geometry, city and living-map suites** pass with the
same clean result. `artifacts/court-atmosphere-final-focused-tests.log`, report67.
These suites overlap; their case counts must not be added as unique coverage.

Raw validation passes **16 rooms, 90 seats, 140,712 triangles, 13,599,160 bytes**;
the largest room has 11,856 triangles. Additional checks preserve all marks and
apertures and the exact triangles/winding/material assignments of **931
structural meshes**. **41 work-detail groups** pass support, height, footprint
and capability-gate checks. Logs: `court-atmosphere-raw-rooms.log` and
`court-atmosphere-raw-supports.log` under `artifacts/`.

Private GUI validation, all tracked processes exited0 with no engine/script
errors:

- Full sixteen-chapter acting/atmosphere sweep: PID70932,
  `artifacts/court-atmosphere-full-gpu.log`. Entrances and seated speech included.
- Final lighting on all sixteen chapters, with wrath and low/high-quality
  recovery: PID31908, `artifacts/court-atmosphere-final-rooms-gpu.log`.
- Actual year3000 audience at1920x1080 and1280x720: PID18112,
  `artifacts/court-atmosphere-final-modal-gpu.log`. Room and speaking frames
  inspected; speech bubbles leave the speaker's face clear.
- Final actual LivingMap layer: PID76412,
  `artifacts/court-atmosphere-city-life-gpu-3.log`, forty masonry/modern frames.
  Thirty-one labor representatives and three children; masonry smoke starts at
  chimney caps, modern vents produce none. Positions remain outside footprints.

Images are ignored local review evidence, not new game assets:
`reports/court_atmosphere/room-timeline.png`, `audience-timeline.png`, and
`before-after.png`; full room/action frames in
`reports/court_evolution_reference/quality-auto/`; actual audience frames in
`reports/court_evolution_modal/`; city frames in `artifacts/city-life-character/`.

Source checkpoints incorporated in this branch:

| Worker branch | Final source checkpoint |
| --- | --- |
| `codex/court-attention` | `5c9d0e5bcc6f1677205b12b0c678556205990e4e` (after `7932a525`) |
| `codex/city-character` | `cc19cba486f52a8338d6ba7a53602d072b4e57e9` (after `0de3c678`, `e41d8265`, `56b3331d`) |
| `codex/court-room-character` | `fb25be7ece43ffb772cbe5bfaa53a82d64a549c6` (after `21357221`) |

The first combined attention run exposed an obsolete one-frame assertion in
the fallback gaze test. The correction retains the original gaze, stance and
kneel checks after the new bounded listener ripple; the full court suite above
includes it. No test was removed to mask a behavior failure.

## Limits and shared files

These are prepared knowledge/settlement snapshots and actual renderer checks,
not a complete simulated 3,000-year campaign. Daylight is a small additive
surface effect with depth testing, not volumetric scattering behind furniture.
The map path search is deliberately bounded; an unresolvable route holds a
representative still. The underlying simulation continues normally.

Private renderer startup remains intermittently unstable: two root city probes
exited3221226505 before OpenGL initialization; their separate logs are retained.
The third completed and is the accepted final capture. Earlier worker failures
are recorded in their handoffs. No driver changes or user-process interruption
were used. The existing Compatibility depth-of-field warning remains.

Shared integration files: `court_stage.gd`, `court_director.gd`,
`court_acting.gd`, `court_set_3d.gd`, `living_map.gd`, the architecture kit and
settlement ink shader provider, plus the court chapter generator/manifest/GLBs.
No changes in this pass to project.godot, terrain, GameState, discovery,
military, save systems or GovernmentPeopleSystem. Generated caches/import
churn and captures are excluded from source commits.

Saved campaigns require no migration. This work changes presentation and
bounded visual representatives, not adjudication, population counts,
GovernmentPeopleSystem ownership, discoveries or save schema. Protected
walking, turning, storm-out and the four retained execution choices remain.

The integrator must combine this branch with current origin/main in an
integration worktree, rerun the combined court/clothing/city checks, push and
verify main, then fast-forward the canonical checkout. No canonical launch,
editor interruption or main merge is part of this worker delivery.
