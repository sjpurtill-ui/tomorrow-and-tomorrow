# Trade barter vignette — prototype asset

Status: HELD for page-level visual approval. This asset is a development preview,
not an integrated player feature. The user requires seeing and approving the
rendered page example before integration into the game.

- Asset: `assets/ui/trade/barter-vignette-v1.png`.
- Generated 2026-10-04 using the built-in imagegen tool with transparent background enabled.
- Dimensions: 2172 × 724; PNG RGBA; 2,188,559 bytes.
- Source: `C:/Users/sjpur/.codex/generated_images/01a109aa-d0f5-7103-80f3-147a07d29a80/exec-4308a71c-4db9-43c3-8f4c-47aea89d484a.png`.
- Reference inspected: `docs/design/approved-wealth-and-navigation.png`.
  It supplies visual quality, medium and presentation, not later-era technologies.
- No reference image was passed into generation; the inspected style was described in the prompt below.
- No post-generation pixel editing, cropping, recoloring or alpha processing.
- Symbolic barter illustration; neither person represents an actual official or recorded exchange.
- Base: `8bd11fddd7bc0f177c2c914fa992527451d7d026`, branch `codex/trade-folio-art`.

## Review and limitations

Visual inspection confirms two adults, gathered grains/nuts, woven basket and
fibers, knapped flint, hide sack and bundled timber. No coins, pottery, metal,
medieval stalls or buildings appear. The intended technology level is the opening
early barter era. Artwork does not encode quantities or assert ledger history.
A theme/parchment composite must still be reviewed in the actual page preview;
this asset alone does not establish visual acceptance of the page.

Read-only Pillow inspection confirms RGBA, alpha range 0–255, 711,185 fully
transparent pixels, 861,153 partially transparent pixels, and 190 opaque pixels.
No executable code, simulation, saves or shared integration files changed.
No Godot process was launched. No save migration is required.

## Generation prompt

```text
Use case: historical-scene.
Asset type: a production-quality painted vignette for a historical strategy game's Trade ledger page; NOT a page mockup.
Primary request: a richly detailed wide horizontal illustration of early barter between two adult traders. The trader at the left kneels beside a shallow woven basket of gathered grains and nuts, extending the basket toward the trader at the right who squats and offers several finely knapped flint blanks. Woven plant fibers, a small hide sack, and a bound bundle of timber branches are arranged across the foreground. Objects are prominent and identifiable. Both traders wear simple natural undyed plant-fiber and hide clothing with bare forearms and uncomplicated wraps. They look at the exchanged goods, hands naturally interacting.
Style/medium: exquisite traditional historical-book watercolor and gouache, fine realistic brushwork with restrained ink detail, tactile woven textures and flint facets, warmly modeled faces and hands. Rich handmade illustration quality suitable for a beautiful museum history book, never cartoon or clipart. The composition should echo the account-object paintings and small working-people scene in a refined parchment ledger.
Composition/framing: wide panoramic arrangement approximately 3:1, two complete seated or crouching figures with all limbs visible, goods spread between them, generous transparent margin at each edge, full-body subjects entirely within frame. Slight three-quarter eye-level view. A little naturally shadowed earth beneath the objects, ending in irregular softly feathered watercolor edges. No horizon, no scenic backdrop, no panel.
Lighting and palette: gentle warm daylight, muted ochre, russet, umber, flax cream, moss green, restrained slate blue accents. Soft natural shadows. Aged fine pigment character but crisp key details; grounded and beautiful.
Transparency: actual transparent alpha background, feather the isolated composition's edge into transparency. No paper background. No checkerboard drawn into the picture.
Constraints: EARLIEST technology era, before pottery and metalworking. Absolutely no coins, metal, pottery, bowls made of clay, wheeled vehicles, horses, medieval stalls, architecture, masonry, furniture, barrels, printed fabric, buttons or modern objects. No text, numbers, letters, labels, logo, frame, border, charts or interface. Exactly two adults, no extra people. This is a symbolic historical illustration, not a named person's portrait.
```

