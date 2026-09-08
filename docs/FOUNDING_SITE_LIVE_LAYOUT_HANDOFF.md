# Founding overlay live-layout correction

READY. Base 465390d; worktree /Users/seanpurtill/Documents/Codex/tt-founding-water-guidance; branch codex/founding-site-live-layout; integrator root. Source commit contains this handoff.

The main game wraps full-viewport interface children in a modal fitting host. The marker overlay also has a full-viewport root and was mistakenly wrapped, leaving a collapsed empty card despite correct standalone layout. FoundingSiteGuide now explicitly uses its own layout contract, matching the existing opt-out convention. The regression invokes the actual shared modal contract and checks visible controls and absence of the fit host.

Only scripts/hud/founding_site_guide.gd and tests/test_founding_water_guidance.gd change. Sixteen focused founding and map-dismissal tests pass with zero errors/failures/orphans (/tmp/tt-founding-live-layout.log). No simulation, save or additional diplomacy changes. No shared-file conflicts. Test override removed. Requires reopening the review after live script sync or a normal later restart; existing malformed controls are not repaired in place.
