# Working Stockyard art

Generated for the approved Materials screen with the built-in `image_gen` tool on October 16, 2026. Exact atlas prompts and resource order are in [stockyard-art-prompts.json](stockyard-art-prompts.json).

The five new atlases supply 29 dedicated specimens plus one generic stored-goods illustration. The existing `material-atlas.png` supplies Timber, Stone, Clay, Fiber Plants and Copper Ore: 34 distinct catalogue illustrations in total. Each atlas is two columns by three rows, read left to right and top to bottom. The renderer uses full cells with preserved aspect ratio. JPEGs are quality90 encodings of the generated PNGs, with no visual edits.

| Project asset | Generated source | Contents |
|---|---|---|
| stockyard-common.jpg | exec-e638f340-896f-446e-a387-22ea66dd760e.png | Flint, Salt, Medicinal Plants, Peat, Limestone, Fine Sand |
| stockyard-earth.jpg | exec-318ced42-d92f-4a74-b227-d1cef4e582e5.png | Ochre Earth, Bitumen, Refractory Clay, Kaolin, Phosphate Rock, Graphite |
| stockyard-fuel.jpg | exec-cc8ee19f-a5ca-4b8e-8d19-42b24a71842b.png | Sulfur, Nitrates, Coal, Crude Oil, Tin Ore, Lead Ore |
| stockyard-ores.jpg | exec-6cedd020-e3aa-4d5e-8393-33e54751414f.png | Iron Ore, Zinc Ore, Silver Ore, Gold Ore, Nickel Ore, Bauxite |
| stockyard-land.jpg | exec-0dfec00b-7d47-4968-9223-ea75beac78ce.png | Rutile Ore, Uranium Ore, Fertile Soil, Game, Deep Aquifer, __fallback__ |

The `land` sheet represents Fertile Soil as productive land, Game as wildlife, and Deep Aquifer as a geological water source. The ore pictures show raw specimens, not refined products. Runtime labels continue to use the game's discovery gates. Art availability never reveals an undiscovered resource.

Unknown saved stock keys retain their exact names and quantities, with the generic illustration explicitly labeled in the row tooltip. The catalogue is open to manufactured/imported or retained legacy stock; this package does not claim dedicated illustrations for every historical product string.

The inventory presents these specimens as small 30-pixel icons beside readable quantities in compact 44-pixel rows, with at most eight materials per page. Selecting a row keeps a compact source and stock reader beside it. Artwork does not determine discovery, inventory or simulation behavior.

`working-stockyard.jpg` is the representative landscape approved in the concept. Generated source: `exec-39647fd8-5bfb-494b-8541-b20177120cc8.png`. It does not assert the selected town's exact population, buildings or unlocks. Its generation prompt:

> Create one beautiful vibrant historical strategy game landscape illustration, wide 3:2 composition, around 1536x1024. This is scenery artwork for an interactive Materials economy screen; DO NOT draw any UI, labels, words, numbers, frames or text. Elevated oblique view of a small preindustrial community's resource grounds and working stockyard. Rich lived-in detail, warm sunlight, natural saturated greens, ochre earth, sparkling river, painterly realistic game concept art rather than cartoon. Upper left: dense leafy woodland with several men and women chopping and carrying timber using period-appropriate tools. Upper right: pale exposed stone quarry and rocky copper-colored mineral ground with workers sorting stone by hand. Lower left: riverbank with clay gathering and bundled reeds/fiber. Across the middle: a clearly visible winding path with adults carrying wicker baskets, wood bundles and a simple hand-drawn sledge toward the yard. Lower center and lower right: an extremely crowded stockyard overflowing its small open-sided thatched storage sheds, with clearly separated piles of cut logs, dressed and rough stone, clay baskets, reed bundles and mineral baskets. A modest carpentry work shelter and unfinished timber frame at the far right show what materials support, but no furnaces/smelting equipment. People are small, anatomically credible, mixed men and women, natural woven tunics, bare or wrapped feet, early agrarian tools. No modern dress, machinery, glass, steel tools, paved roads, wheels or carts. The village feels alive and useful. Composition must distinctly separate forest left, quarry right, water/clay lower left, crowded storage foreground right so data can be anchored to meaningful imagery. Keep the upper center open enough for a short readable text overlay later. Do not imitate a spreadsheet or infographic. No UI boxes.

The resulting landscape includes a simple wheeled load-carrier despite the prompt restriction. It is accepted only as representative preindustrial scenery, not as a depiction of starting technology. It is cropped to the stockyard for the page banner.
