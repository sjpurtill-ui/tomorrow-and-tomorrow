# Command panel layout

READY for integration. Worktree `/Users/seanpurtill/Documents/Codex/tt-command-panel-layout`, branch `codex/command-panel-layout`, base `241e5327a408ac3a8341f88e2f34efa8688c1ba5`.

The Army, Fleet and Air Force hierarchy panels keep Give objective and Cancel orders outside the scrolling form. The hierarchy receives more vertical room; the objective selector comes first, while optional zone names and briefing notes start collapsed. Finish and Cancel drawing appear only during a draft. Personnel/craft headers receive font-measured width. Long feedback is bounded to two lines with its complete text in a tooltip. Single-line headings and scrollable staff status prevent the Air Force panel from extending below the minimum logical canvas.

All 37 worktree checks pass, zero errors/failures/orphans: `tests/test_command_hierarchy.gd`, `tests/test_main_map_services.gd`, `tests/test_map_panel_dismissal.gd`. Log: `/tmp/tt-command-panel-layout-verified.log`. Layout checks explicitly set logical canvas sizes of 1280×720 and 1024×640 and exercise all three services with expanded optional details, drawing controls, long feedback and scrolled content. Existing native mouse expansion, conservation, command execution and map dismissal regressions also pass. Guards cover previously opened panels lacking newly introduced drawing controls during editor script reload.

Changed files: `scripts/hud/command_hierarchy_panel.gd`, `scripts/hud/command_tree.gd`, `tests/test_command_hierarchy.gd` and this handoff. No simulation, save schema or shared integration hotspot changes; existing saves remain compatible. No integration conflict is expected from the stated base. Isolated test user data was used and its temporary project override removed before commit.

Native visual inspection of this layout is pending. The canonical running player has not been restarted; its existing panel does not acquire the new structure until it is recreated after script reload or a normal launch. Integration records must distinguish tested source delivery from receipt by the running game.
