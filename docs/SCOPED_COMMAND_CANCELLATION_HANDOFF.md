# Cancel orders for the selected command

INTEGRATED as `49ef49c`; all 97 canonical tests pass (`/tmp/tt-scoped-cancel-canonical.log`). Worktree `/Users/seanpurtill/Documents/Codex/tt-command-order-state`, branch `codex/scoped-command-cancellation`, base `63e62ab0148bade874b7c70ec5f75ce9ae87c5bb`.

The command panel previously passed only a force ID to Cancel orders, discarding the selected subdivision. Cancelling a virtual squad or team therefore cancelled its entire parent force. Naval and air cancellation also ignored service refusals, so a headquarters could report cancellation while some subordinates kept their missions, or stop earlier subordinates before a later refusal.

Cancel orders now acts on the exact selected hierarchy path. An available land subdivision detaches through the existing conserved personnel/equipment mechanism, receives its own cancellation, and remains selected. Siblings retain their objectives and continue executing them. A changed-strength or busy subdivision is refused without changing the parent. A subdivision with no active objective remains a read-only selection; cancelling it does not create extra detachments.

Whole naval/air commands validate every subordinate's stand-down before committing any directive or mission changes. Convoy and return-route refusals are shown to the player. Feedback distinguishes land commanders holding ground, naval forces holding/returning to ports, and aircraft stopping sorties/returning to base or remaining on their carrier. Cancelling a land objective preserves an already committed battle or siege; the current engagement continues resolving.

Owned files: `scripts/command_hierarchy.gd`, `scripts/hud/command_hierarchy_panel.gd`, `tests/test_command_hierarchy.gd`, and this handoff. No shared integration hotspot changes or expected conflicts. No save schema change; existing cancellation directives and nested detachments continue using the current save format.

All **97 worktree tests pass**, with zero errors, failures, skips or orphans. Tests run headless with Godot 4.7.2 and the explicit worktree path, using `GdUnitCmdTool.gd --ignoreHeadlessMode`:

- `/tmp/tt-scoped-cancel-tests-fixed.log`: 47 cases across command hierarchy, main-map services and map-panel dismissal. Seven new cases cover exact cancellation through the actual button signal, independent sibling execution, asset conservation and serialized overrides, changed-strength/moving rejection, read-only unassigned cancellation, naval/air subdivision refusal, atomic service cancellation with a late convoy blocker, and continued resolution of a real battle.
- `/tmp/tt-scoped-cancel-services.log`: 50 cases across joint operations, joint campaign loop and command city operations (including inherited siege progression cases). Covers existing sea routes, carriers, transports, separate service missions and autonomous city outcomes.

The owned test-userdata override is removed before commit. Preexisting generated UID files are excluded. No player/editor UI action, restart or native visual verification was performed. Editor PID 2812 and player PID 6076 still identify the canonical Mac checkout; that running process is not evidence of receipt of these later scripts.

Limits: a virtual subdivision still must be able to assemble before receiving an independent order; cancellation does not add detachment during marches, battles, at sea or on missions. The complete existing command can still be selected for cancellation, subject to the service's operational constraints. This is a command-scope and truthful-feedback correction, not additional HOI4 combat-system parity.
