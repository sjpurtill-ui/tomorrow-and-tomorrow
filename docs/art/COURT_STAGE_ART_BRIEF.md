# Court stage art brief

The Court is the one screen where the player, a god to their people,
receives officials, envoys and petitioners. Its setting changes with the
form of court that the people's discoveries support. The stages, their
triggers, offices and ceremony are in `docs/CIVIC_EVOLUTION.md`.

Each stage below has a prompt for a backdrop painting. Until a painting
exists, the game draws a procedural gouache scene for that stage.

## Where the art goes

- **File.** Save each painting as `assets/ui/court/<stage_id>.png`, using
  the stage ids below. The game picks it up automatically
  (`CourtBackdrop.stage_texture`). No code change is needed; open the editor
  once so Godot imports it.
- **Older tier plates.** `assets/ui/court/court-tier-N.png` still covers the
  stage that its tier used to draw when that stage has no painting of its
  own.
- **Review.** Windowed runs of `tests/court_probe.tscn` through
  `tools/run_isolated_gpu_probe.ps1` capture every stage as
  `reports/court/stage-<id>-<mode>.png` for side-by-side review.

## Delivery specification

- **Size.** 2560 × 1440 PNG, sRGB, full bleed, 16:9.
- **Crop.** The game cover-crops the painting. The court at rest shows a
  wide band of roughly 1280 × 370, the middle 28%–72% of the height. The
  audience view shows the whole frame behind a paper veil. So:
  - Keep the architecture's focal point (seat, apse, platform, doors) in
    that middle band, centred.
  - Keep the lower 30% as open floor. The seated officials' portraits
    overlay an arc there, and the fire, altar or table sits at the centre
    bottom.
  - Keep the top 20% quiet: sky, roof or vault. A dark header lies across
    it.
- **Viewpoint.** Eye level, from where the god's presence would stand,
  looking toward the seat of rule, one-point perspective. The god is never
  shown.
- **People.** Anonymous figures at believable scale, secondary to the
  architecture: attendants, guards, scribes, crowds. No close faces, since
  real portraits are laid over the scene.
- **Style.** Shared by every stage; see below.
- **Exclusions.** No lettering, no legible script, no UI, no borders, no
  real-world landmark, flag, heraldry, religious symbol or polity. No
  modern objects, no fantasy creatures, no gunpowder weapons.
- **Light and dark.** One painting serves both modes, and the game adds a
  firelit night wash in dark mode. Paint a balanced mid-key, not deep
  night.

**Shared style line** (prepend to every prompt): *Sophisticated painterly
gouache on handmade paper, fine engraved ink linework, visible paper tooth,
restrained historical palette, soft atmospheric depth, one-point
perspective at eye level, calm and grand, no text, no borders, no modern
objects, alternative history (no real-world landmark, flag, religious symbol
or heraldry).*

## Stage prompts

### `hearth_council`: the fire circle

**Scene.** An open ring of logs and rolled hides around a central fire on
trodden earth. A stitched-hide windbreak on stakes curves behind. There is a
drying rack with a stretched hide, spears leaning at the left, knapped stone
by the seats and a line of far trees and low hills.

**Light.** Late afternoon sky, warm ochre and pale blue, woodsmoke drifting.

**Materials.** Wood, hide, cord, flint.

**Feel.** Intimate, egalitarian, the whole band close to one fire.

### `elders_circle`: the elders' ring

**Scene.** The same open fire circle, now enclosed by a ring of rough
standing stones leaning slightly, spotted with lichen and taller at the
sides. Two high-backed carved wooden seats for the eldest have zigzag
carving, and a carved speaking staff hung with coloured cords is planted by
the fire. Two grey-haired elders stand with staffs.

**Light.** Dusk: the sky shifts from amber to violet, with firelight on the
stones.

**Materials.** Raw stone, carved wood, hide.

**Feel.** Solemn, deliberate, the weight of custom.

### `chiefs_hall`: the chief's hall

**Scene.** Inside a long timber hall. Two rows of heavy posts recede to a
back wall with a bright doorway, under thatch rafters and a smoke-hole with
a shaft of light. At the far end is a raised platform with the chief's high
seat, tall carved posts topped with gilded knobs, furs thrown over it.
Painted round shields hang on the near posts, and a long plank feast board
with bowls and drinking horns runs down one side. A long hearth burns in
the middle. Two hall warriors with spears stand by the seat, and a guest
kneels with a bundle of gifts.

**Light.** Smoky amber interior.

**Materials.** Oak, wattle, thatch, hide.

### `temple_palace`: the house of the god

**Scene.** A mudbrick and timber hall with a niched, buttressed back wall
and woven hangings in zigzag and lozenge bands. A stepped, lamp-lit niche
sits above a carved seat on a low dais. Before the dais stands an offering
table with clay jars and a heap of grain, with incense smoke rising from two
burners. Scribes sit cross-legged on mats with clay tablets and stacks of
tablets beside them. A keeper of offerings in white linen wears a tall
headdress, and two petitioners kneel at the threshold.

**Light.** Warm lamplight on plaster.

**Materials.** Mudbrick, cedar beams, reed mats, clay.

**Feel.** Sacred, administered, counted.

### `palace_bureaucracy`: the palace hall

**Scene.** A dressed-stone hall of fluted columns with banners hung between
them. A throne sits on a stepped dais under a great dark arch. To either
side, archive walls of pigeonholes are stacked with tablets and scrolls,
and a tall law stele with close-cut lines of text (illegible) stands beside
the dais. A herald with a gilded staff stands mid-hall, spear guards flank
the dais, and scribes sit at low desks. Petitioners lie prostrate on the
flagstones, and braziers burn either side.

**Light.** Cool stone daylight from high openings.

**Materials.** Limestone, bronze, dyed wool.

**Feel.** Ordered, hierarchical, written.

### `citizen_assembly`: the assembly place

**Scene.** An open-air assembly place: semicircular stepped stone tiers
rise around a packed-earth floor and are filled with seated citizens in
plain robes, small in the distance. A square stone speakers' platform with
steps stands at the centre, with a water-clock on a stand and two clay
voting urns. A small altar fire stands at the front. Behind the tiers are a
colonnade, a town of whitewashed houses with tiled roofs climbing a hill,
and a small columned shrine on the height. A herald opens the session, and
a petitioner holds a bough.

**Light.** Bright open daylight, a clear sky.

**Materials.** Limestone, terracotta, wool.

**Feel.** Public, level, argumentative. No throne anywhere.

### `imperial_court`: the throne hall

**Scene.** A vast vaulted throne hall of pale marble columns. A gold-ground
mosaic half-dome apse with radiating light stands over a raised throne, and
heavy purple curtains are drawn back and tied with gold cords. A long
purple carpet runs to the throne, flanked by rows of guards and ranks of
ministers in rich robes with gold stoles. Secretaries hold scrolls, priests
of the rites wear tall hats, and lamps of many lights hang on chains. A
master of ceremonies stands with a staff, and petitioners wait at a
distance, bowed.

**Light.** Incense haze in shafts of window light.

**Materials.** Marble, gold tesserae, silk, bronze.

**Feel.** Overwhelming, silent, remote.

### `senate_house`: the council house

**Scene.** A tall marble council house seen down its length. Tiered stone
benches on both sides are filled with seated councillors in pale robes,
some with coloured borders. Two folding magistrates' chairs with gilded
X-legs stand on a low platform at the far end. Great bronze doors stand
open onto a sunlit square beyond, and a small altar fire burns at the
entrance. The coffered ceiling rises above an inlaid marble floor with a
porphyry disc at the centre. Attendants with rods stand at the doors, and a
petitioner stands at the bar.

**Light.** Clear, even daylight.

**Materials.** White and coloured marble, bronze.

**Feel.** Civic dignity, debate, a republic.

### `late_antique_hall`: the consistory

**Scene.** A dim columned basilica. A deep blue mosaic apse is scattered
with gold stars over an empty throne on a dais. Polycandela lamps of many
small flames hang low on chains. Ushers with rods keep the silence while
officers of the household in stiff brocade, clergy of the god in dark
vestments and sworn retainers stand in ranks. Notaries hold sealed
memorials, and petitioners kneel to kiss a hem.

**Light.** Deep shadow, with pools of lamp and window light.

**Materials.** Porphyry, blue and gold glass tesserae, brocade.

**Feel.** Sacral, hushed, ceremonious; an old empire grown formal.

### `feudal_hall`: the great hall

**Scene.** A stone great hall under dark timber trusses, the tie-beams
receding. A high table with a white cloth runs along the dais, with a
tall-backed chair at its centre. Long trestle tables run down both sides,
and rushes cover the floor around a central long hearth. Painted kite and
heater-shaped shields of sworn households, in plain invented tinctures,
hang on the walls, and ring lamps hang from the beams. Retainers in mail
stand with spears. A herald of the household is present, and vassals kneel
with their hands placed between a lord's hands (the lord is only a figure
at the high table, faceless).

**Light.** Warm smoky firelight.

**Materials.** Rough-dressed stone, oak, wool hangings, iron.

**Feel.** Personal bonds, oaths, a travelling court.

### `chancery_court`: the chamber of the seal

**Scene.** A vaulted stone chamber with tall windows of stone tracery and
leaded panes. A long table covered in green cloth crosses the room, covered
with rolled parchments, bound books, a red wax great seal and candles.
Clerks sit behind it writing, and masters of requests stand in dark gowns.
Iron-bound chests of rolls stand at the sides, with sergeants-at-arms
carrying maces. Suitors bow with writs in hand, and a crier stands at the
door.

**Light.** Cool daylight through tracery, with warm candle points.

**Materials.** Stone, parchment, green baize, oak, iron.

**Feel.** Paperwork as power; quiet, exact.

### `chartered_commune`: the commune's hall

**Scene.** A timber-ceilinged council chamber above a market. A great
mullioned window shows the town square, house fronts with stepped gables
and a tall bell tower. Guild banners hang in plain invented colours with
simple tool emblems (no real guild marks), and a bell rope hangs from the
beams. A horseshoe council table in red cloth holds the town's charter on a
lectern with a wax seal. Consuls and guild masters sit around it in sober
gowns, a town crier and two watchmen stand by, and townsfolk bring their
grievances.

**Light.** Bright northern daylight.

**Materials.** Timber, brick, red cloth, parchment.

**Feel.** Self-governing, mercantile, sworn together.

### `estates_assembly`: the hall of the estates

**Scene.** A great hall with a large rose window of coloured glass
(abstract geometric, no figures) throwing coloured light down the floor. At
the end, a canopy of state in the house colour hangs over a raised seat.
Three banks of benches hold the three estates in distinct dress: dark
vestments on one side, crimson and furs on the other, blue and black town
gowns across the front. Banners of chartered towns in plain invented
colours line the walls, with heralds, clerks, guards and bearers of
grievances.

**Light.** Luminous and coloured.

**Materials.** Stone, glass, velvet, oak.

**Feel.** A realm speaking back to its sovereign.

## Civic buildings and settlement visuals to change

These are prompts for future settlement art. The settlement renderer does
not read them yet; the list is in each stage's `civic_buildings` field. Use
the same shared style line for concept paintings. For map models, follow the
delivery rules in `docs/art/UNDERTAKINGS_IMAGE_BRIEF.md`: physical
footprint, material variants by region, no fantasy scale.

| Stage | Buildings and visuals | Prompt |
|---|---|---|
| Hearth council | Common fire ring, storage pits, drying racks | A small camp's trampled centre: a stone-ringed fire, covered storage pits and hide drying racks, with a few shelters around them. |
| Elders' circle | Meeting stone, boundary markers, watched common store | A flat meeting stone under a large tree, with a low circle of stones. Boundary stones stand at the field edges, and a raised store has a watcher's seat. |
| Chief's hall | Chief's longhouse, tribute store, feast ground, shrine house | A long thatched hall twice the size of other houses on a slight rise, with a fenced tribute store beside it, an open feast ground with fire pits and a small house for the god. |
| Temple-palace | God's storehouse, scribes' house, ration hall, stepped shrine terrace | A buttressed mudbrick temple on a stepped terrace with storerooms, a scribes' house with a tablet-drying yard, and a ration hall where workers queue with bowls. |
| Palace bureaucracy | Governor's residence, district archive, law stele in the square, palace granary, workshops under quota | A courtyard residence with a guarded gate, an archive building with small high windows, a tall law stele in the paved square, a long granary and a row of palace workshops. |
| Citizen assembly | Assembly place, council house, law court, treasury, market wardens' office, public inscriptions | A hillside assembly place with stepped seating, a square council house beside a colonnaded market, a small treasury building with a strong door, and inscribed stone slabs at the market edge. |
| Imperial court | Prefecture, post station, state granary, provincial treasury, academy, examination hall | A walled prefecture compound with a gate tower, a post station with stables on the trunk road, a raised state granary, and an examination hall of many small cells. |
| Council house | Council house, record office, basilica court, public baths, municipal treasury | A tall council house with bronze doors on the forum, a long basilica court with a clerestory, a record office and a domed bath house. |
| Late-antique consistory | Fortified count's hall, god's-house court, charity hospital, walled market, tithe barn | A fortified hall inside patched old walls, a god's house with a court annex, a charity hospital with a cloister, and a great tithe barn. |
| Feudal hall | Castle and bailey, manor court, tithe barn, lord's mill | A timber-then-stone keep on a mound with a bailey, a manor house where the manor court meets, a water mill of the lord and a tithe barn. |
| Chancery court | Chancery house, shire court, toll house, guild hall, record tower | A stone chancery house with barred windows, a shire hall for courts, a toll house at the bridge and a narrow record tower. |
| Chartered commune | Town hall with belfry, guild halls, market cross, town gate and walls, weigh house | A brick town hall with a tall belfry over the market square, gabled guild halls, a market cross, a weigh house and a gated town wall. |
| Estates assembly | Town hall with belfry, guild halls, merchants' exchange, hall of learning, cloth hall | An arcaded merchants' exchange, a long cloth hall, a hall of learning with a quadrangle, and a grander town hall where deputies are chosen. |

Across all stages, the ruler's own seat in the capital settlement should
follow the court scene: the fire ring, then the stone ring, the longhouse,
the god's house, the palace, the assembly place or throne hall, the council
house or basilica, the great hall or castle, and finally the chancery,
commune hall or hall of the estates.
