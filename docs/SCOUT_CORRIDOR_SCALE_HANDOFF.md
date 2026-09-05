# Scout corridor scale

Branch `codex/scout-corridor-scale`, base `5cedfb9`.

The actual refresh caller supplied uppercase map bands to a lowercase renderer,
selecting the widest 4.2 km fallback even at close zoom. It now uses warfare bands.
Corridor width, arrow size and ground clearance derive from camera size with hard
bounds. Close corridors remain visible; their large endpoint text retires below
8 km. Arrow ground heights use the same surface sampler as their ribbons.

A logarithmic 8% zoom bucket in the cache signature refreshes within-band geometry
without rebuilding at stationary zoom. Width may vary by up to one bucket between
rebuilds; this is bounded scale stepping, not a continuous shader-width solution.

Validation: headless and hidden graphical warfare runtime probes PASS. Actual
refresh caller tested at 0.035, 0.8, 20, 40 and 320 km: width bounds, correct arrow
counts, endpoint text visibility, changed-zoom rebuilds, unchanged-zoom reuse and
unmodified ordered-route data. Graphical cardinal-direction checks also pass.
Capture `artifacts/route-scout-scale.png` inspected; the QA camera is now assigned
to the real renderer so width uses its actual view. No shader errors observed.

Save/mission/intelligence logic unchanged; corridors still show planned orders,
never current scout positions. Existing shutdown resource warnings remain.

IMPORTANT: base precedes route-layer patch `11d6fd5`. Preserve that integrated
patch's material ordering when applying this commit. Capture here consequently
still shows pre-layer arrow centers; that issue is already fixed separately.
Shared changes: scout refresh cache, profile helper, constructor size/height/text.
