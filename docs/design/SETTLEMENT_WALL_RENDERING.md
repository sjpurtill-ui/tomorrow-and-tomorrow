# Settlement wall rendering

October 7, 2026. The reported Ashfire screenshot showed completed, undamaged
stage-4 defenses as oversized disconnected slabs. The copied current save has
3,670 people, day 93,035, defense integrity 1.0 and no active defense project.

The renderer used three separate ten-sided district loops, removed entire
edges for gates, and placed towers around a different population-derived
circle. Walls were 14 m high and lifted 2.8 m off the sampled ground; towers
were 22 m high. The defense mass material also bypassed depth testing.

Premodern masonry now uses one occupied-plot enclosure. Real polygon corners
constrain its outline, and road approaches supply the gate bearings. Gates cut
short physical intervals along that outline, including across corners. Shared
mitres join wall faces; towers sit on the same solid wall and clear its gates.
Stage-4 walls are 6 m high and 1.4 m thick, with 8 m towers and 4.5 m passages.
Short bounded bays follow the terrain with an 8 cm lift; defense mass obeys
normal depth testing. The stone palette is warm and subordinate to the town.

Ditches and palisades retain their forms and gain physical gate cuts. Premodern
stage-5 walls use the same enclosure with 8 m walls and 10 m towers; the modern
defense network remains separate. Active construction fronts and real breach
sectors still come from the existing defense state. Nothing changes defense
strength, costs, population, saves, or the no-human-figures map policy.

Validation: 11 new geometry/render regressions plus the 7 existing defense
checks passed (18/18, report 65), without engine errors or warnings. They cover
connected geometry, gate width and corner wrapping, tower attachment and gate
clearance, polygon coverage, construction and breaches, grounding, depth
testing, physical dimensions and untwisted wall joins.

The private GPU probe uses one copied current save and identical 0.75 km and
0.25 km camera spans before and after. It keeps the actual defenses enabled.
Local evidence stays in ignored `artifacts/wall-scale/`; saves, generated
images and import caches are excluded from source delivery.

Final before/after GPU review passed at both spans: the disconnected interior
slabs are gone, one joined enclosure follows the occupied town, and attached
towers and narrow gate openings are visible. Save SHA, population, day, defense
ledger and camera targets match exactly across both runs. All six visible
settlement seeds were ready, human map batches remained zero, and both private
processes exited 0 without script or engine errors. Screenshots are
`before_overview.png`, `before_close.png`, `after_overview.png` and
`after_close.png`; captures and defense metadata are recorded in their JSON
reports. A normal player restart is required to load the integrated renderer.
