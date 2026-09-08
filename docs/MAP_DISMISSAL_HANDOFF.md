# Click the map to close panels

Base 889199f; worktree /Users/seanpurtill/Documents/Codex/tt-main-map-services, branch codex/main-map-services. Primary agent owns local_terrain.gd dismissal/help behavior, service_world_overlay.gd empty-map handling and test_map_panel_dismissal.gd; integrator is the same agent.

READY: bare-map clicks dismiss ordinary docks/detail docks and map help together, consuming the click before world actions. Clicks outside the actual body of supported reports, the pause menu and scout/diplomat dispatch panels dismiss them even when a full-screen dimmer captures GUI events. Military drawing/force/region/base selection remains functional; otherwise bare map closes command mode. Explicit decision dialogs retain their confirm/cancel controls. Map help now describes actual pan/zoom/inspection/dismissal controls and has a clearer Close button; stale fast-zoom tooltip corrected.

11 isolated tests pass: dismissal, report-body hit testing, main-map service input/projection and four-distance camera behavior. Zero errors/failures/orphans, /tmp/tt-map-dismiss-final.log. Dismissal input test verifies no settler movement. No save changes. Shared hotspot local_terrain.gd; no concurrent conflicts. Native pointer behavior requires live verification separately from headless tests.
