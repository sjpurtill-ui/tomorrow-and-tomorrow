# Living settlement illustration assets

Original raster assets generated with the built-in `image_gen` tool on 2026-10-14.
The approved town illustration supplied style, lighting and material direction.
These are independently placed transparent sprites, not a fixed village backdrop.
The renderer must select them from recorded building fabric, footprint, condition
and construction, and must not create a building, crop, inventory or technology.

## Atlas contract

Both early buildings and details have four columns and three rows. Mature
buildings have four columns and two rows. Use the actual PNG dimensions rather
than the requested generation size. Compute opaque bounds inside each cell for
ground contact; the generated objects do not share an exact pixel baseline.
Keep alpha gutters out of neighboring cells and use a small alpha cutoff to
discard negligible transparent-edge color. Files are never fetched at runtime.

Early row-major cells: hide ridge shelter; hide dome; reed lean-to; timber/wattle
roundhouse; earth household; rough-stone household; open craft canopy; raised
timber store; open communal shelter; construction frame; damaged roof shell;
ruin footprint.

Details: spreading oak; small broadleaf; tall slender broadleaf; flowering shrub;
wildflowers/grass; reeds; logs; baskets/jars; fence; hearth; raw stone/wood; crop
rows. Baskets/jars, fences and crops require matching established practices or
recorded objects. The crops do not assert yields. Decorative supplies are not
inventory quantities. Tree positions remain the seeded terrain's positions.

Mature: two-storey timber; two-storey earth; two-storey rough stone; three-storey
masonry; broad workshop; broad storage barn; modest meeting hall; two-storey
scaffold. These require compatible recorded form/material/storeys. Cells with
chimneys or tile roofs additionally require corresponding installed fabric;
unsupported buildings retain truthful geometry instead of being reskinned.

Roof-specific atlas: three columns and two rows, 512px square cells. Row one:
single-storey earth/flat-earth roof, rough stone/slab roof, timber/plank roof.
Row two: the same materials at two storeys. No chimneys or tiles. The stored RGB
in fully transparent pixels is brown; alpha is zero there and must be respected.
`meadow-ground-v1.png` is a repeating painterly meadow/earth material, not a
landscape backdrop or a new terrain resource.

People: six columns and four rows, 256px square cells. Rows are basic hide/fiber
wrap, joined sewn hide, coarse woven drape, and simple woven tunic. Columns are
idle, left/right walking phases, carrying, working and crouching. The existing
knowledge/adoption/supply gates select clothing. They remain bounded visual
representatives moving on existing routes, not a new individual-population model.

States: three columns and two rows, 512px square cells. Row one: bare timber
construction without masonry footing; partly built earth walls; partly built
rough-stone walls. Row two: fire-damaged timber/plank, earth/flat-roof and
stone/slab-roof houses. These require the corresponding recorded construction
or damage and matching material, floor count and roof; they are not generic
ruin overlays. Timber variants use the same three-by-two layout: three modest
single-storey plank-roof houses, then three two-storey versions. Stable recorded
building identity chooses variation without changing installed fabric.

Workshop: one 1254px square transparent image of an open-front timber workshop
with a plank roof, for that recorded material and form. No chimney, glass, metal
fittings or machinery. Its decorative supplies do not assert stored quantities.

## Generation prompts

Buildings: production transparent 4×3 sprite atlas; style-only reference to the
approved rich, warm, painterly strategy village; exact twelve early subjects above;
consistent elevated three-quarter camera about 35 degrees down, upper-left sun,
bottom-center contact, transparent gutters; intricate straw, weathered timber,
earthy ochres and soft organic silhouettes. No UI, labels, people, ground slabs,
modern elements, glass, electricity, mills, factories or fantasy. Distinguish
primitive shelters from developed homes.

Details: production transparent 4×3 sprite atlas of the twelve environmental
subjects above, the same camera and warm light, textured irregular foliage,
natural greens and ochres. No buildings, people, horizon, geometric low-poly
trees, modernware or ground slabs. A corrective edit retained subjects/style
and shrank each object inside a single equal square cell with transparent gutters.

Mature: production transparent 4×2 sprite atlas of the eight developed subjects
above; same warm painterly reference, detailed historic thatch/timber/masonry,
consistent three-quarter view and independent silhouettes. No castles, mills,
electricity, factories, invented emblems, people or opaque ground squares. These
are visual assets, not game unlocks.

Roofs: transparent six-cell sprite sheet, three columns and two rows; exact
single/two-storey earth flat-roof, stone slab-roof and timber plank-roof subjects;
same detailed warm painterly three-quarter architecture. No chimneys, thatch,
tiles, glass, people, balconies or modern technology. A background-extraction
edit preserved all houses and removed the surrounding brown gradient to alpha.

Ground: seamless square top-down painted meadow/earth texture, subtle muted
olive, sage and ochre mosaic with tiny stones and dry blades; low contrast,
natural daylight. No buildings, roads, rivers, people, trees or other objects.

People: transparent 6×4 sheet, the four clothing stages and six poses above,
consistent proportions, facing right in three-quarter view, natural warm skin
and undyed materials, soft detailed painterly light, clear at 24–60px. No modern
shirts, trousers, buttons, collars, armor, metal tools, pottery, weapons, ground,
UI or text. Frame bounds are measured for consistent ground contact.

States: transparent six-cell sheet, three columns and two rows; exact unfinished
and damaged subjects above, consistent warm painterly three-quarter camera.
Timber frame rests directly on ground without a masonry foundation. Damaged
houses retain their matching roof material and single-storey form. No people,
labels, modern equipment, complete buildings in the construction row or solid
background. Transparent gutters separate each independent object.

Timber variants: transparent six-cell sheet, three columns and two rows, three
single-storey and three two-storey timber plank-roof houses; varied modest
weathered wood, roof pitch and handmade detailing, consistent camera and light.
No thatch, tiles, chimneys, glass, people or new technology. Clear alpha gutters.

Workshop: a single transparent, warmly painted ancient open-front timber
workshop, one storey, steep wooden plank roof, handmade bench with wood/stone
tools and logs. Detailed weathered timber, elevated three-quarter view matching
the village assets. No thatch, chimney, pottery, metal, people, UI or ground slab.

## Source output identities

- Early: `exec-4ae5268d-c5fd-41c1-ae0d-5e588248d00f.png`
- Details, corrected: `exec-0a4ac206-a6be-47f9-9298-5370cb721d0b.png`
- Mature: `exec-b4eca32c-88c8-4192-9b24-984e512e5941.png`
- Roofs: `exec-455b57e1-5c46-4114-90e8-4d22edb343ca.png`
- Ground: `exec-c92c7cb2-ed28-420b-a783-a79a6376b7b5.png`
- People: `exec-14eff4ef-116b-4e05-bb7a-6aa7d81e23c0.png`
- States: `exec-00bbc6ed-d6f1-401a-9723-ded77ef349e3.png`
- Timber variants: `exec-fbfd323b-5fd5-47ae-b308-c5b23a365a4f.png`
- Workshop: `exec-f2ea6e25-3755-4bb0-ad69-ae415d5a1570.png`

Original outputs remain in the conversation's generated-image directory. These
workspace copies are the runtime assets; no dependency on that directory exists.
