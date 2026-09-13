# Naval dock integration with sewn garments

Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/naval-sewing-integration`, base `7a44c117393f674466043b508dc1e08b6a2f97b9`. Reviewed frozen naval delivery `bcda00ef6be020221de7bfc76e1a65e7d383ee35` from `cd6accf0cd2dc24b51842bfc3280530ec8c2b52f`, including all four source commits. The additive settlement merge preserves sewing bone state and water shipment demand. See `NAVAL_DOCK_RUNTIME_PLAN.md` for behavior and source acceptance.

All 86 combined cases pass: naval dock14, joint operations5, household clothing21, civilian planner14, owned simulation19 and city resources13. Evidence: `/tmp/tt-naval-sewing-results.json`. The combined graph is clean at 673 discoveries, 455 explicit learning routes, 309 recipes and 17 facilities (`/tmp/tt-673-graph.log`). No terrain changes, player launch or package rebuild.

The dock uses paid local materials, shared construction work, finite repair access and dated surveys. Optional dock/survey records preserve legacy saves and full owner continuation. Supported access covers war canoes and ram galleys only; handling and repair coefficients are game abstractions. Natural coastal placement and historical pacing remain outside these isolated acceptance fixtures. Unfinished laundry work remains separate at `b107bca` and is excluded from this merge.

Canonical runtime `b363f6c6aceaf42515e020281934cef26cb217fd` passes all 48 dock, clothing and city cases (`/tmp/tt-naval-sewing-canonical-results.json`). Ordinary headless startup is clean. Both existing naval IDs are promoted from the exact 673-entry canonical snapshot, retaining the dock prerequisite reconciliation; all 15 ledger checks pass.

Both naval illustrations from `01abed5` were visually reviewed and integrated as `d18a6b0`; import is clean and all 12 research-atlas cases pass (`/tmp/tt-673-atlas.log`). Inventory: 110 verified images /673 live, 563 queued.
