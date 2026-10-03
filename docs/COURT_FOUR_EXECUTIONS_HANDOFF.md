# Four court executions: scope handoff

Date: 2026-10-03

The user's current selection supersedes the broader 25-act implementation plan: enable only **2 club home run, 3 into the fire, 4 dog dinner, and 10 three-swing beheading**. Preserve all other assets and catalog entries for later.

## Delivery and ownership

- Worker branch: `codex/court-four-executions`.
- Development worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow` (reused after pushing the motion branch).
- Started from integrated main `df2c25260ea96d856c6aa9ef9426f5dd5d2008c3`; merged the published execution work through `f489a49c5505a643bceebb9a08f94aa66d9bc4eb`.
- Minimal scope-change commit: `771da83774966fb0b5008f877ff108b2be9e9b14`. The wiring integrator can cherry-pick this commit onto its latest execution branch.
- Only the wiring integrator should combine this with main, clothing work, and the separately pushed `codex/court-motion` commit `2e99218ff496f25a4634a13351db0f41325d9304`. This worker has not merged into main or launched the player game.
- During validation, main advanced to `f9c6f398b38254f4370b99ac7be0e430bc045d39` with the separate faint/walk fix. The execution branch advanced to `b90c866e07e55dad8c4e3138d85cd3dff3b0d2f3`, a documentation addendum after the tested implementation at `f489a49c`.

## Behavior

- Menus and automatic selection offer only the four selected methods, still subject to existing era/animal requirements.
- A command naming a parked method falls back to an eligible active method, as existing unsupported staging did; captions follow the selected method.
- Direct stage execution, direct execution events, and director scene generation reject parked or unknown methods before allocating an execution or queuing reactions/audio.
- The complete 25-method catalog and existing assets remain available for future development. No walking, turning, acting clips, clothing, or execution choreography was changed by this scope patch.
- No save schema or ledger changes; existing saves remain compatible.

## Validation and remaining integration work

- Godot 4.7.2 headless import succeeded.
- `test_court_executions.gd`, `test_court_exec_stage.gd`, and `test_court_director.gd`: **51/51 passed**, zero suite failures, errors, skipped tests, or orphan nodes, after merging `f489a49c`.
- Tests cover menu/era gating, seeded choices, every parked command, and direct-call rejection without changing stage state.
- Engine shutdown still reports two ObjectDB instances and one retained `court_figure_gore.gd` script resource, plus an allocator diagnostic. The test process exits 0; this warning is not counted as a suite failure. That figure resource is unchanged by the scope patch; its ownership needs follow-up if a clean shutdown is required.
- Fire retains the existing staged char/crumble scene. Its fuller acting work remains unfinished upstream; the upstream handoff also documents incomplete sound synchronization for staged scenes. Club, dogs, and beheading use the existing full acting plans.
- The integrator still needs to resolve shared `court_stage.gd` / `court_director.gd` / acting changes, run the combined court tests and clothing audit, and verify the four scenes visually before claiming the player build includes them.
- Import sidecars, generated UIDs, caches, test reports, and captures stay local and are excluded from this branch's task commits.
