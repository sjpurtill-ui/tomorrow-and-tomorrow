# Physical naval dock and hull survey services — INTEGRATED

Worktree `/Users/seanpurtill/Documents/Codex/tt-naval-dock`, branch `codex/naval-dock`, base `cd6accf0cd2dc24b51842bfc3280530ec8c2b52f`. Integrated as `b363f6c6aceaf42515e020281934cef26cb217fd`, including the complete source range. See `NAVAL_SEWING_INTEGRATION.md` for combined and canonical acceptance.

## Behavior

The existing `dry_dock_services` and `hull_condition_surveys` drafts now have physical operating consumers. This adds two live discoveries and no new authored identities. Paid Launch Cradles, Rigging Blocks, Rope Coils, Timber and Stone create an unfinished dock project at an owned completed naval port. Construction shares the existing reserved quarter of local construction labor with other port projects. There is no second labor authority.

The first installation supports War Canoes and Ram Galleys. Completed dock access is finite per day and shared across formations. Onboard repair crew time bounds service. The owner checks and pays the entire ordinary repair bill plus dock upkeep before consuming access or changing condition. Insufficient combined supplies fall back to ordinary paid afloat repair; insufficient ordinary supplies leave inventory, access and condition unchanged.

Qualified hull inspections consume access and crew work, recording date, pre-repair condition and port. Fresh observations improve the effectiveness of allocated dock repair work; observation itself grants no free condition or durability. Same-day repeat calls cannot repeat the dock benefit. The naval panel exposes installation, construction progress, remaining access and dated survey records.

Owned-civilization investment uses the same installation action. It requests actual manufacturing inputs through the existing production planner. Secondary ports wait for the existing debited, delayed intercity shipments rather than drawing remotely from primary inventory. Imported finished cradles remain usable without manufacturing knowledge.

## Branching and integration

Dry Dock Services requires Structural Load Testing AND (Mine Drainage OR Compound Pulleys). Its former draft required drainage and load testing together; retain that predicate change in the promotion reconciliation. The lift-access alternative does not require mine drainage. Hull Condition Surveys retains Hull Seam Caulking AND Measurement Uncertainty.

At this base the graph reports 669 live discoveries, 451 explicit routes, 309 recipes and 17 facilities; no graph errors or blocked production dependencies. Canonical main has since promoted four sewing methods. The integrator must regenerate the combined snapshot and promote these two existing drafts, preserving all newer canonical ledger changes.

Shared files: `civilization_controller.gd` (one authorized investment dispatch), `discovery_system.gd` (registration and description), `settlement_model.gd` (local dock shipment demand), `technology_catalog_contract.gd` (two operating consumers), `joint_operations.gd` (construction, repair and optional save fields), and `hud/naval_command_panel.gd`. Preserve newer clothing and planner changes; this branch includes the cd6 upstream-production resumption base.

## Acceptance evidence

All 51 cases across four suites passed, with zero errors, failures, skips or orphans: `test_naval_dock_service.gd` (14), `test_joint_operations.gd` (5), `test_city_resources.gd` (13), and `test_civilization_owned_simulation.gd` (19). Command: Godot 4.7.2 `--headless --path /Users/seanpurtill/Documents/Codex/tt-naval-dock -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode`, with each suite supplied using `-a`. Terminal log `/tmp/tt-naval-dock-final-tests.log`, exit 0, 33.046 seconds.

The dock cases exercise paid shortage transactionality, reserved work and day limits, finite access, supported and unsupported hulls, survey/material consequences, malformed and legacy records, secondary inventory and occupation, partial work and spent access restoration, actual panel summary and install-button callback, actual cradle production, full human save restoration, full owned-actor save continuation, and delayed secondary-port cradle delivery. Naval-port fixtures convert a constructed base for isolation; they do not establish natural coastal placement or long-campaign progression.

Normal main-scene headless startup with `--quit-after 3` exited 0 and reached `DIRECTION_SCREEN_READY` without errors: `/tmp/tt-naval-dock-boot.log`. Graph/dependency evidence: `/tmp/tt-naval-dock-graph.log`. `git diff --check` passed. Earlier standalone UI check-only output had an unresolved autoload and was rejected; the accepted evidence is the regular in-project panel tests and startup above.

## Compatibility and limits

Optional dock and survey fields round-trip through JointOperations and full SaveSystem for human and owned actors. Legacy saves without them remain valid; malformed numeric fields are rejected. No arbitrary saves were removed and no player or editor was stopped or launched.

Handling quantities are game tuning, not naval engineering ratings. Heavy galleys, sailing ships, armored ships, submarines and mixed unsupported formations need later qualified facilities. Foreign observer-side aggregate repair remains unchanged. This delivery does not finish later shipyard types, all naval research, millennial balance, artwork, or the full 5,000-discovery goal.
