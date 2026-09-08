# Main-map naval and air commands

Base: 23c5e81. Worker/integrator: primary agent. Worktree: /Users/seanpurtill/Documents/Codex/tt-main-map-services, branch codex/main-map-services.

READY: independent Naval Command (task forces, ports, convoys) and Air Command (wings, airbases, airlift), using a transparent overlay over the actual main terrain camera. No secondary map is opened. Shift+F5 opens Navy; Shift+F6 opens Air. Main camera pan, zoom and four distances remain active. Area vertices are world coordinates; Escape cancels a draft before closing the panel. Service clicks cannot accidentally order settlers or land troops. Region selection/right-click assignment, bases, own forces, routes, air range and player-observed contacts render on the main map. Existing city labels remain the main map's responsibility.

Validation: clean isolated import and 28 tests across main-map services, joint campaign loop, joint operations and camera distances; zero errors/failures/orphans. /tmp/tt-services-final-tests.log. No save schema changes; existing areas and forces retained. Shared changes: local_terrain.gd input routing, joint_operations.gd UI adapter, command rail and military content. No concurrent worker conflicts.

Limits: combat remains the current aggregate daily simulation; this delivery fixes command architecture and map interaction, not full HOI4 numerical parity. Live layout and canonical launch verification follow integration.
