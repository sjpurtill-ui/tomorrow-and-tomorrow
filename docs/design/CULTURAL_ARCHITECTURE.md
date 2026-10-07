# Cultural building finishes

Buildings carry a small recorded cultural finish: roof register, compatible
plaster, doorway pattern and decoration. The finish uses the owner's existing
lived values, known crafts and actual emblem identity. It does not add another
culture simulation, unlock materials, charge goods or change population.
The actual ten founding crests span all four muted roof palettes; matching
uses hue and chroma so dark emblem ink cannot collapse them all into grey.

New founding buildings, household and district growth, overflow camps and
genuine building renewal receive a finish. Existing saves receive today's
finish once for eligible unstamped buildings. This is present cosmetic adoption,
not an invented historical building event. Existing records then retain their
finish when current culture or knowledge drifts; later construction and renewal
can leave a different layer of buildings. Saved JSON-safe integer codes remain
stable across load, and malformed/future records render neutrally. Fields and
ruins do not acquire fictitious plaster. Timber and temporary cover keep their
actual materials; advanced decoration uses recorded pigment/marking knowledge.

Root and clustered country buildings use the same existing meshes, transforms,
shared shaders and material resources. Four per-instance codes choose bounded
shared colour tables and metre-scale doorway/frieze patterns on authored faces.
Glass and roof material tags are preserved. Patterns fade when smaller than a
pixel. Foundation/frame construction and access scaffolds stay unpainted; walls
and roofs inherit the finish. Aggregate fallback roofs/walls reuse the same
palette in their existing vertex colours. Sparse far-country single-home
symbols retain their existing simplified palette and do not add fine patterns.
No walking map figures, geometry, new textures or per-culture materials are added.

Finish keys are separate from placement and vegetation. Small daily culture
changes cannot rebuild or repaint old houses. Root-derived country templates
copy finishes after geometry deduplication, preserving the original template
count and deterministic form selection. Previously retained display parcels
adopt a missing finish only from a matching form/material/roof template; existing
finishes, paths and footprints remain unchanged. The culture shader uses the
existing draw batches, rather than adding a batch or node for each style.

Source checkpoint `c6a56d54`, branch `codex/cultural-architecture`, based on
`57e108aa`. Combined with the subsequent culture-screen update `9a859c08` at
`2aeb0b91`, without architecture conflicts.

Headless validation covers culture/craft gates, actual crest diversity and
brightness invariance, save records, owner and secondary-settlement scoping,
actual growth and renewal, one-time legacy/retained-country adoption, unchanged
geometry/materials/batches, construction stages, appearance caching and no
vegetation/layout work on a finish refresh. All 63 distinct feature cases pass
across reports 89–91. The existing construction idempotence case caught and
verified the fix for a missing overflow-camp creation stamp.

GPU validation uses labelled prepared specimens over genuine copied saved
terrain. Root neutral/ordered/open profiles and country neutral/open profiles
are compared within their respective rendering paths, with identical building
geometry and placement. Root and country do not have to emit identical auxiliary
shadow transforms. Each timing window follows 120 warm-up frames and contains
120 samples; image encoding occurs afterward. This compares the active finish
cost against neutral within the current shared shader, not against a historical
shader binary. The actual saved-map context is measured separately.

Final private GPU review of combined source `2aeb0b91` passed with exit 0,
no shader/runtime errors and no map-human instances. All six images were
reviewed. Roof registers, lime/rose plaster and horizontal/patterned doorway
trim are visibly distinct while recorded materials and footprints remain.
Within each rendering path, neutral and styled specimens had exact matching
mesh/transform fingerprints: eight batches, fourteen instances and 13,975
submitted vertices. Draw calls stayed at 66 for root and 67 for country.

Mean render CPU was 1.49/1.48/1.50 ms for neutral/ordered/open root finishes,
and 1.50/1.52 ms for neutral/open country finishes. Wall frames stayed near
the existing 20 ms cap in all controlled cases. GPU means varied from 5.71
to 6.71 ms; variation is not a speedup claim. These measurements support a
small cost in this scene, not zero shader cost on every machine or map.
The separate live saved-map sample averaged 20.00 ms wall / 2.00 ms render
CPU / 3.35 ms GPU, with dynamic draw counts and occasional longer frames.

The merged culture-screen and renderer checks also passed together: eleven
checks, report 92. There are 68 distinct passing checks across feature and
integration validation. Local ignored evidence is in
`artifacts/cultural-architecture/`: `capture-audit.json`, six final PNGs,
`preview-final.log`, its isolated runner record and the source commit record.
Prepared specimens and copied saves remain outside source commits. The player
session was not restarted; save and restart through the canonical launcher
to load the delivered code. Existing save data remains compatible.
