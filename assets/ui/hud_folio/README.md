# Engraved folio icon family

The user approved the Elizabethan engraved folio concept on October 4, 2026.
These two transparent atlases were generated with the built-in `image_gen`
tool from that approved reference. They are original game artwork, not store
downloads or historical scans. `provenance.json` records their source hashes.

The PNGs are unchanged tool outputs. `regions.json` selects each emblem without
resampling the source. The two import settings enable mipmaps so fine carving
remains stable at small UI sizes. `hud_folio_art.gd` caches the atlas regions;
`hud_chrome_icon.gd` draws them with their original aspect ratio. Night mode
reverses neutral ink and ivory in a shader while retaining gold and source alpha.

## Production prompt set

Both production generations referenced the approved twelve-icon concept sheet.
The following records the generation brief and constraints for reproducing the
family, including the subjects and ordering used by the runtime atlas.

### Navigation atlas

Create a production game UI sprite atlas from the twelve approved designs.
Use the reference for style and subjects, not its background. Landscape 4-column
by 3-row atlas, truly transparent background, no text, labels, headings, corner
decorations, border or paper. Exactly twelve individual emblems, centered in
equal cells with transparent separation. Shakespearean Elizabethan woodcut and
heraldic folio illustration; simplify fine crosshatching and strengthen outlines
and negative spaces for a small sidebar. Iron-gall dark brown-black ink, ivory
highlights inside objects, aged gold accents, especially the court. No gradients
or shadows. Aim for 68–72% optical cell coverage and 15% transparent padding.

- Court: canopied throne; People: three Tudor profiles; Standing: heraldic lion
  with a banner; Known World: armillary sphere over an unfurled map.
- Military: shield and polearms; Chronicle: quill across a folio; Food: wheat
  sheaf and sickle; Water: decorated pouring ewer and waves.
- Wealth: cornucopia; Trade: cuffed handshake and exchange arrows; Crafts:
  anvil, hammer and Tudor rose; Learning: open book and guiding star.

Book pages use carved lines without readable text. Production illustrations,
not a presentation sheet; clear transparent separation is essential.

### Work and life atlas

Create a matching second UI atlas in the approved Shakespearean Elizabethan
woodcut style. Exactly eight standalone icons in four columns and two rows on
a genuinely transparent background. Equal cells, generous transparent padding,
no touching emblems. No text, labels, letters, headings, border, paper background
or outside ornaments. Strong ink, ivory, muted gold, controlled carved linework,
recognizable small silhouettes and clean negative spaces. No shadows or gradients.

- Materials: stacked logs, stone and a rope coil; Buildings: timber-framed gabled
  house and mason's square; Culture: thoughtful and smiling theatre masks with
  rosemary, tasteful rather than grotesque; Ledgers: clasped leather account
  book with tally and corner fittings.
- Health: vigorous leafy branch and ripe fruit, hands cupping the roots; Goods:
  jug, folded cloth and a hand tool; Labour: working hands with rolled sleeves,
  wooden hoe and harvested stalk; Menu: eight-petal printer's rosette containing
  three horizontal rule marks.

## Runtime identifiers

Twenty distinct emblems serve the rail, menu and status cards. The resource
counter aliases `population → overview`, `economy → food`, and `science → inquiry`
intentionally share their corresponding navigation emblem. All other mappings
are explicit in `regions.json`. New production icons should extend that mapping;
the procedural renderer is only a missing-art fallback.
