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
The renderer uses `settlement-timber-variants-v2.png`. Its corrected spacing
keeps lower-row roofs out of the top-row cells; v1 is retained as superseded
source artwork and is not used by the renderer.

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
The corrective v2 edit preserved the six subjects and required every complete
house to fit inside its own 512px cell with transparent separation. A read-only
alpha audit confirmed no visible pixels on the row or column boundaries.

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
- Timber variants, corrected v2: `exec-4076ee61-3153-41bf-bb20-be10339d2472.png`
- Workshop: `exec-f2ea6e25-3755-4bb0-ad69-ae415d5a1570.png`

Original outputs remain in the conversation's generated-image directory. These
workspace copies are the runtime assets; no dependency on that directory exists.

## October 15 motion revision

`settle-people-walk-v1.png` and `settle-people-carry-v1.png` are transparent
1254×1254 RGBA atlases with four columns and four clothing rows. The columns
show contact, passing, opposite contact and opposite passing. All figures face
right; the renderer mirrors the complete figure to match actual travel.
The carry version holds a small wood bundle in both arms throughout the stride.
These are bounded visual representatives, not a new stock or transport system.

The motion sheets replace the two static, extended-leg poses previously used as
a walk cycle. Complete bodies are used without splicing limbs. Fractional cell
boundaries are rounded and sampled at texel centers, and measured head/ground
registration keeps successive frames aligned. Gait follows distance traveled;
pickup and delivery pauses hold it still. Existing knowledge, adoption and
household supply rules continue to select the clothing row.

Generation used the built-in image tool with transparent backgrounds. The walk
prompt specified a four-by-four production atlas, explicit alternating contact
and bent-knee passing poses, a stable torso facing right, bare forearms/calves,
rough hide through simple woven garments, and the existing warm painterly style.
It excluded modern garments, weapons, tools, labels and scenery. The carry edit
preserved the complete walking figures and added a small bundle of wood held
steadily with both arms. Runtime registration accommodates the returned size.

- Walk source: `exec-862b96b0-7c45-455e-93b9-b724703b2d5b.png`
- Carry source: `exec-5691c9be-6b3b-4922-939d-6e07b8d1c81e.png`

The earlier eight-column candidate was rejected because its poses still twisted
the body instead of providing a clear passing step; it is not a runtime asset.

## Mixed workforce representatives

Three additional assets were created with the built-in image-generation tool:

- `settle-people-roles-v1.png`: eighteen complete figures, one woman and one man
  for each of Food, Survey, Extraction, Construction, Crafting, Logistics,
  Knowledge, Administration (keeping and caring), and Defense. Six columns by
  three rows; paired roles follow that order. Only one adult appears in each
  cell. Tools touch a small local work object; care prepares leaves and dressings
  without adding a patient. Watchkeepers carry simple upright stone-tipped spears.
- `settle-people-male-walk-v1.png`: the male counterpart of the approved four-phase
  contact/passing walk, with the same four garment-material stages.
- `settle-people-male-carry-v1.png`: complete matching bodies holding a wood bundle
  through all four phases, including a stable planted contact during a pause.

The role sheet is 1774×887 RGBA. The male motion sheets are 1254×1254 RGBA with
slightly uneven transparent gutters; inspected texture-region boundaries preserve
complete feet and heads. PNGs are not trimmed or repainted by runtime code.
The shader registers ground and head positions, and preserves naturally shorter
crouching poses. The cast's conservative hide clothing stays consistent between
travel and work. These are percentage representatives, not individual clothing
or equipment inventory; legacy knowledge/adoption/issued-clothing gates remain.

Prompt set: use the existing warm painterly ancient clothing as style reference;
create alternating female/male work pairs, with bare forearms/calves, natural
hide wraps, one complete adult per cell and visible hand/tool contact. Explicitly
exclude modern garments, armor, paper, metal tools, extra people and scenery slabs.
The care revision replaces counters with leaf preparation and a rolled dressing;
the male garments use a consistent shoulder wrap. A packing revision adds large
transparent gutters. The male walk prompt specifies stable right-facing torsos
and alternating planted-contact/bent-knee-passing poses. The carry edit changes
only arms and the held load, preserving whole-body gait and clothing.

Final built-in source outputs, directory `01a13b4f-8ab2-7a81-a3b3-186e772b4a77`:

- Roles: `exec-14ca8681-7a34-4bce-b388-3f6f35a954e6.png`
- Male walk: `exec-5beaf2bb-b9ec-4236-b647-835442d000b1.png`
- Male carry: `exec-9592906d-14ee-4f12-9eb0-5fbff7296aed.png`

Earlier closely packed candidates were excluded because their figures crossed
the nominal cell boundaries. The runtime assets above live in this repository;
the generated-image directory is provenance only.
