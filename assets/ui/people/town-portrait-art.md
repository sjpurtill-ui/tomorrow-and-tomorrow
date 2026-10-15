# Population portraits — October 15, 2026

The People screen uses one continuous, clickable painting at a time. The user
requested the earlier photo approach and then explicitly requested vibrant
population stages, correcting the first small-village image as too developed
for the starting court. The final starting image is a sparse encampment.

All five assets were made with the built-in imagegen tool. No external photo
library or image-generation CLI was used. Original generated images remain in
`C:/Users/sjpur/.codex/generated_images/01a13b4e-53d9-7361-8d69-93b20c9c91ec/`.
The versioned copies here are the files shipped with the game.

| Asset | Population | Original output |
| --- | --- | --- |
| town-portrait-camp-v2.png | below 150 | exec-f7c09a24-89f0-4831-b43d-8eb6e4f44d41.png |
| town-portrait-hearth-v1.png | 150–399 | exec-97531d5c-233e-4ea6-8b08-e2ba582250c3.png |
| town-portrait-village-v1.png | 400–1,499 | exec-cef586d8-8301-40fb-8021-f3dce8eada53.png |
| town-portrait-town-v1.png | 1,500–5,999 | exec-4bbef71d-58ab-42aa-ab14-a6bfce3ca350.png |
| town-portrait-large-town-v1.png | 6,000 and above | exec-a693650e-f47f-4c6d-bc5d-f75a271dd207.png |

These are presentation thresholds based on total population, not assigned
workers. They do not grant a technology, building, military strength or civic
rank. Natural-material architecture remains intentionally conservative.
People in the image are illustrative, not an exact workforce census. Live
counts, allocation percentages and consequences come from existing game data.
The historical 100-sprite renderer is retained in source but is not the active
People presentation. The pictures do not simulate day-to-day construction.

## Prompt set

The village edit used the original approved composition
`exec-a522c89b-b2ad-41f3-91ec-12967044f402.png` as its edit target:

> Edit this village concept into a production BACKGROUND IMAGE for the People
> screen of a civilization strategy game. Preserve its rich, lived-in,
> continuous bird's-eye town composition, warm afternoon lighting, beautiful
> realistic painted/photo-like materials, coherent paths, river, foliage, and
> abundance of meaningful everyday activity. Landscape 3:2 at the highest
> useful resolution. Remove ALL interface completely: the top and bottom dark
> strips, every label, every number, every button, every icon, every glowing
> outline, arrow, line, marker, watermark. Fill those areas naturally with
> scenery. No text whatsoever. This must be one continuous convincing village
> picture, never separate tiles or an atlas.
>
> The village should use early natural materials: small thatched
> wattle/earth/timber homes, woven baskets, cord, stone and wooden tools, simple
> tunics/wraps/hides on BOTH men and women; no modern clothes, machinery, metal
> workshop tools, waterwheel, massive stone tower, castle battlements or
> medieval dress. Replace the top watermill with a modest waterside store and
> reeds. Replace right stone tower with people assembling a timber/thatch
> building frame.
>
> Make these nine work areas visually clear and integrated along the real
> paths, with diverse people visibly engaged in their relevant tasks: crop
> fields and harvesting at upper right around x78%,y17%; land surveyors using
> cord and poles at upper left forest edge x15%,y14%; woodcutting and
> stone-working ground at lower left x16%,y80%; building frame and builders at
> right edge x87%,y40%; open-sided workshops with baskets, weaving and
> tool-making x65%,y45%; water drawing and loaded carriers at lower river
> bridge x62%,y79%; elders teaching using stones and marks in earth at central
> fire/courtyard x47%,y54%; families caring for children and tending sick near
> homes x26%,y45%; two watch guards with spears and hide clothing by a modest
> gate x91%,y72%. These are approximate composition guidance for interactive
> hotspots, not nine rectangular compartments. Keep roofs from obscuring the
> workers. No generic figures standing idly in evenly spaced grids, no cutout
> sprite look, no giant empty lawn. The image itself should be beautiful enough
> to view full screen; live numbers and controls will be drawn separately.

The Hearth, Town and Large town edits used the clean village as reference with
this shared direction:

> Make a matching 3:2 landscape town portrait in the SAME vivid, warm, richly
> textured painted/photo-like style as the reference. One beautiful coherent
> inhabited place, no compartments. No text, numbers, interface, icons, glowing
> outlines or watermarks. Natural early materials only: thatch, timber, earth,
> cord, hide, stone tools; no machinery, wheels, modern clothes, metalwork,
> castles or watermills. Diverse men AND women visibly performing relevant
> jobs. Keep the SAME nine work-neighborhood positions so clickable areas can
> remain intuitive. The river runs uppercenter across rightmiddle and toward
> bottomcenter. Activity clusters should connect naturally through paths,
> never nine isolated islands. Keep the main task figures and tools visible
> rather than hiding them behind roofs. Beautiful foliage, warm smoke and
> flowers, lively work and human warmth at every scale. Preserve these broad
> positions, but all building density and settlement extent must match the
> requested population stage. The image is representative artwork, not an
> exact map.

Stage additions requested a tiny community with only five or six huts for
Hearth, many dozens of modest homes in connected neighborhoods for Town, and
hundreds of modest rooftops stretching through the valley for Large town.
Larger images were explicitly to gain density and scale, not castles,
machinery or technology jumps. The first Hearth was rejected for the start
and retained only as the second population stage.

The final Camp used that Hearth as its edit target, with this prompt:

> Radically simplify this image into the VERY FIRST SPARE ENCAMPMENT of the
> game. This reference is far too developed. Keep only the warm vibrant
> realistic painted/photo-like style, woodland river setting and 3:2 bird's-eye
> composition. Replace the entire settlement with just TWO SMALL MAKESHIFT
> HIDE-AND-BRANCH WINDBREAKS at left-middle, ONE communal fire at center, and
> about EIGHT visible adults total in rough hides/wraps. Mostly untouched green
> woodland, golden grasses, wildflowers, sunlit rocks and a shallow lively
> stream. Rich natural colour and convincing life, but very sparse human
> construction. No thatched houses, wooden buildings, farmland, crop rows,
> fences, gates, formal paths, workshops, benches, stackedcutmasonry, planked
> bridge or elaborate tools. No text or UI. No wealthy or established
> settlement in background.
>
> Arrange a few HUMBLE beginnings of activities with lots of space between:
> upper-left a lone scout on a natural ridge; upper-right wild edible bushes
> with a gatherer; lower-left a fallen branch and small pile of gathered
> stones; far right a few poles being tied into another small windbreak, not
> a house frame; center-right one person knapping a stone tool on the ground;
> center one person showing another a few stones beside the fire; left-middle
> one caregiver by the two hide windbreaks; lower-middle/right one person
> collecting water from the stream beside natural stepping stones;
> lower-right a simple stone-point spear leaned against a tree at the lookout.
> These are informal shared places, not nine separate staffed work teams.
> Preserve beautiful environmental detail without adding settlement detail.
> Human scale should feel as spare as a new court with just a few people. Make
> it warm, hopeful and vibrant, not bleak or abandoned.

The last Camp edit corrected the cropped lookout while preserving the rest:

> Make ONE precise correction to this exact sparse encampment image. Keep the
> entire scene, camera, warm vibrant style, river, two hide windbreaks, fire,
> all existing activity and every other person's placement unchanged. At the
> FAR-RIGHT LOWER EDGE, the lookout is currently a barely visible cropped
> sliver hidden behind the foreground tree. Move that SAME lookout into clear
> view, fully INSIDE the image around normalized x91%, y68%, standing on a
> small existing natural patch beside the tree. Show one complete modestly
> sized adult in simple hide clothing holding a plain wooden spear with a
> stone point, watching outward. The complete person and spear must fit
> within x84%–97%, y55%–80%, with enough space from the image edge for a
> clickable hotspot. Move only this obscured figure; do not add buildings,
> fences, paths, new people elsewhere, UI, text, labels or any other
> development. The camp must remain very spare and mostly untouched nature.
> Preserve all other pixels/composition as closely as possible.
