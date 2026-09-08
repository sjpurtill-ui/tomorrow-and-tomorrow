# Automatic crew training recovery

Base: `06798ef484993d9b7c5db7e2d7e972ec23e41c4a`.
Worktree: `/Users/seanpurtill/Documents/Codex/tt-service-training-recovery`.
Branch: `codex/service-training-recovery`. Primary agent is the designated integrator.

Navy and Air crews finish an existing repair spell at 98% condition before resuming instruction or exercises. Initial crews continue essential repairs even when instruction is suspended, wait without partial spending when repair materials are missing, and resume automatically when funded. Qualified crews use the existing operations repair path; training cannot simultaneously charge exercises or grant proficiency while repairs continue.

Repeated processing on the same day preserves attendance and staff status as well as paid progress. Rival crew messages cannot overwrite the player's staff report. Initial instruction reports completion and remaining time rather than claiming that 125% of crews are rotating. The broad roster keeps actual repair shortages and travel visible, with training availability as supporting information.

Owned files: `scripts/military_training_staff.gd`, `scripts/hud/military_roster_screen.gd`, `tests/test_training_strategy.gd` and this handoff. No shared simulation hotspot changes, conflicts, save schema changes or data migrations. Existing optional repair/training fields remain compatible.

Validation: **74 tests passed**, zero errors, failures or orphans, in `/tmp/tt-service-training-worktree.log`. The explicit worktree was tested headlessly using isolated userdata. Suites: training strategy (21), joint operations (5), joint campaign loop (30), main-map services (6), training accounting (10), map dismissal (2). Six added cases cover full repair-to-training transitions for both services and qualification states, suspended repairs and shortages, same-day graduation, rival report isolation, instruction text and actual roster activity. Initial targeted failure was a test asserting an `ok` field on a route receipt whose success is represented by route points; corrected to the established error contract.

No player/editor restart, graphical probe or native interaction. Main integration and its validation are recorded separately; a running game retains its loaded scripts. No remote push or other worktree changes.
