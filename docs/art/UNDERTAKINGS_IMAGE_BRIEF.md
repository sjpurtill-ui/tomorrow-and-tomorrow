# Great undertakings — first 300 years

## First playable slice
Twelve candidates, offered through Buildings → Undertakings. Each world/site has a stable subset, further gated by local population, environment and known discoveries. Existing saved games have no undertakings until one is authorized. No guaranteed wonder award and no instant-completion button.

An active site diverts 20% of its city's effective building labor; pressing ahead diverts 50%. Costs are consumed as work occurs. Careful policy stops during provision shortages; pressing ahead records days of hardship. Local leadership skill, craft capacity, labor efficiency and social cohesion determine accumulated workmanship. Inadequate workmanship can yield a completed failure. Five consecutive years without progress leave an abandoned site. Functioning sites reserve maintenance labor and consume materials; neglected sites decay and can become ruins. Ten years of maintained operation can establish an enduring reputation. Human cost remains attached to the legacy.

Practical rewards now include real storage capacity, preservation, crafting/research effectiveness, household attraction and traveler-carried diplomatic reputation. Exact effects and the Enduring Civilization victory requirements are in [UNDERTAKING_REWARDS.md](../UNDERTAKING_REWARDS.md). Leadership skill and existing labor decisions affect execution; autonomous leader proposals, named sponsorship, succession disputes and competing political interpretations remain later work. Ruined/abandoned sites are retained but restoration is not yet playable. This is not a calibrated 300-year campaign balance claim.

## Image delivery specification

For each candidate, deliver one 1536 × 1024 landscape scene, plus aligned foundation, active construction, functioning and abandoned/ruined variants. Same camera, terrain and structural footprint across states. Keep focal structure in the central 65%; safe crop for 3:2 and 16:9 cards. PNG, sRGB. No lettering, borders, UI, modern machinery or embedded progress indicators. Show people at believable scale, ordinary tools, storage and access routes. Success must not automatically become gilded or pristine. Ruins should reveal the original plan.

Map assets: low-poly physical geometry with 3 LODs, metric scale in source assets; renderer converts meters to kilometers. One 2048² base-color atlas, normal and roughness atlas per family. Avoid baked directional shadows. Supply material variants appropriate to the region rather than universal pale marble. Footprint should fit 50–120 m for this opening set. Construction state is structural missingness, not transparency. Ruins retain foundations and broken geometry. Do not enlarge the building to a city-sized fantasy landmark.

Recognition emblems (next art pass): transparent PNG at 256² and 64², plus vector source, with a simple unique silhouette. Two ink colors maximum; usable at 24–32 screen pixels. At 10,000 ft use the physical site plus a restrained emblem anchored to it; hover expands name, condition and legacy. No solid yellow dots, glow columns or permanent text paragraphs. The initial code uses physical blockout geometry and a short depth-tested name/state label; production emblems and final LOD tuning are not delivered in this slice.

## Candidate briefs

| Candidate | Scene / silhouette | Material and setting | Failed or embarrassing state |
|---|---|---|---|
| Ancestors' Ring | Twelve uneven uprights surrounding an open center | Locally quarried stone, restrained paths, offerings | Half-raised circle, fallen uprights and abandoned hauling frames |
| Hall of Many Hearths | Long pitched roof and three parallel entrances | Forest timber, fiber roofing, smoky hearths | Roof absent or sagging, exposed posts and unused assembly floor |
| Court of Collected Rain | Sunken square basin, inward steps, broad rim | Dry country, lined clay, rough stone, feeder channels | Cracked dry basin, silted channels, a conspicuous water line never reached |
| Gardens Above the Flood | Three stepped green bands following terrain | Wet country, low retaining walls, channels and crop strips | Breached wall, scoured soil, two empty terraces |
| Steps of the Watching Sky | Low stepped platform and asymmetric sighting stones | Open horizon, dark local stone, no fantasy telescope | Subsidence, crooked alignments, abandoned observing posts |
| Court of a Hundred Fires | Repeated kiln domes around a working yard | Clay, ash, wood stacks, uneven firing colors | Collapsed kilns and heaps of spoiled vessels |
| House of the Long Song | Modest broad hall and shaded listening court | Timber and woven screens, visible acoustic enclosure | Unroofed hall reused for storage; memory surviving outside the original ambition |
| Granary of the Covenant | Three raised stores surrounding a counting court | Timber piers, clay plaster, ventilated rooflines | Leaning piers, weather damage and emptied storage bays |
| Sanctuary of Safe Passage | Incomplete oval enclosure with two wide gates | Regional stone/wood mix, shelters along the interior | Blocked gateway, stripped shelters, boundary stones still recognizable |
| Orchard of Generations | Broad planted horseshoe with winding paths | Mature trees, varied ages, simple water works | Dead planting rows, surviving old trees and broken irrigation |
| Crown of the Ridge | Low monumental stepped earth-and-stone mound | Earth core, locally dressed facing, long approach | Slumped flank, missing facing and an approach to nowhere |
| House of Common Measures | Compact paired halls around a rectangular court | Timber frames, measuring bench, weights and reference rods | Uneven foundation, deserted inspection court and discarded standards |

## How the map should read at 10,000 ft

1. Physical form: recognizable footprint, correct ground contact, sunlit mass and cast shadow.
2. State: foundation-only / incomplete silhouette / intact mass / broken remains.
3. Recognition aid: eventual 24–32 px emblem, anchored without hiding the footprint; name and story on hover.
4. Zooming closer reveals construction activity and material identity. Zooming farther retains the emblem and suppresses small details.

The supplied map study is a design diagram, not an in-game screenshot. In-game forms now include pitched roofs, raised granaries, kiln domes, planted orchards, sighting stones, stepped terraces and a dry lined basin. Components are combined into one mesh per wonder with a shared material; appearance is cached independently of population and ordinary map rebuilds. New sites use a bounded deterministic search checking ground, slope, existing plots and other landmarks; the chosen position is saved. Earlier saves retain their original offsets. Individual components sample local ground height. Player-directed placement, final illustrated scenes, recognition emblems and authored art remain outstanding.

The Undertakings panel shows live construction/workmanship bars, an estimate at the latest work rate, years of maintained operation, recorded hardship and a bounded history of authorization, completion, abandonment or loss. No workmanship claim is made before work begins.

