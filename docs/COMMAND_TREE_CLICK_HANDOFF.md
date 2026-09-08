# Native command-tree expansion fix

INTEGRATED as `388ae88`; all 35 canonical checks pass. Live mouse expansion and squad selection also pass in the restored Seanston campaign. Worktree `/Users/seanpurtill/Documents/Codex/tt-command-tree-fix`, branch `codex/command-tree-fix`, base `17eb2407b0aa6ddf0096925b097be7c711bdbeca`.

Live inspection of the integrated Army Command exposed a mouse-event failure that the earlier direct-method tests missed: expanding the squad attempted to create TreeItems while Godot held the native tree selection lock, then dereferenced the failed creation. Expansion now queues the row's instance ID and populates it after the input callback. A row deleted by a rebuild is safely ignored when the deferred call arrives.

All 35 focused tests pass with zero errors/failures/orphans (`/tmp/tt-command-tree-fixed.log`): command hierarchy, main-map services and map-panel dismissal. The new regression sends a native viewport mouse event at the squad disclosure, verifies its four real-size virtual teams, confirms no force was detached, and rebuilds while a deferred expansion is pending.

Only `scripts/hud/command_tree.gd`, `tests/test_command_hierarchy.gd` and this handoff change. No simulation or save changes. No shared hotspot conflict. The integration record supplies the delivered hash, canonical verification and subsequent live inspection.
