# Yard material variety

Branch `codex/yard-material-variety`, base `1c424bd`.

Specialized yards had three available ground materials but selected them using a
stride of three, repeatedly choosing the same cell. Storage, civic, sacred and
industrial yards now cycle through their actual three-cell palette. Existing
four-cell yard palettes retain their old ordering. No randomness, patch geometry,
count, color, asset, gameplay or save format changed.

Actual emitted mesh UV regression across four uses and two fabric generations:
eight failures before the fix; full 81-test architecture suite PASS afterward.
This restores existing material variety; no new artwork or broad visual redesign
is claimed. Shared local_terrain.gd edit is one material-index stride calculation.
