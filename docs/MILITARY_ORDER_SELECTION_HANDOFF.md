# Military order selection

Base 48d860b; worktree /Users/seanpurtill/Documents/Codex/tt-main-map-services, branch codex/main-map-services. Primary agent owns military_service_panel.gd and the campaign regression tests and acts as integrator.

READY: background/feedback refreshes retain the player's proposed mission and selected region rather than restoring the existing assignment. Explicitly selecting a force loads its own order and region. Current order is labelled separately from the proposed mission. Region control text refreshes with status. No simulation or save fields changed.

36 isolated tests pass across joint campaign and main-map service suites, zero errors/failures/orphans. Two new behavioral cases cover preservation through refresh/failure and successful assignment, plus explicit selection of assigned and unassigned forces. Log /tmp/tt-order-selection.log. No conflicts. Running game is not restarted; next normal launch receives this UI correction after integration.
