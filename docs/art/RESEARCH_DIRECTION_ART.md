# Research discovery art: twelve aesthetics

The twelve research directions each have a distinct rendering language. The
direction determines medium, palette, and composition; the discovery and its
date determine every object, action, garment, building, and piece of equipment.
The player approved this direction after reviewing the [twelve-field concept
sheet](research_direction_aesthetics.png) on September 25, 2026.
The [later-era pilot sheet](research_direction_modern_pilot.png) tests the same
languages on one key-threshold discovery per direction. Both sheets are visual
references, not installed discovery paintings.

| Research direction | Rendering language | Dominant color |
|---|---|---|
| People & homes | Chalk pastel, intimate domestic scenes | Terracotta |
| Food & farming | Botanical egg tempera, practical abundance | Olive and wheat |
| Health & care | Watercolor and fine ink, close care gestures | Sage |
| Work & tools | Charcoal and ochre wash, hands and applied force | Ochre |
| Learning & records | Blue-black ink wash, measured quiet space | Lapis |
| Craft & industry | Impasto oil, tactile material transformation | Copper and ember |
| Water & building | Architectural gouache, clear structural planes | Mineral blue |
| Transport & supply | Panoramic travel watercolor, routes and motion | Sand and indigo |
| Land & nature | Naturalist field painting, living relationships | Moss |
| Government | Civic fresco, balanced group decisions | Plum and limestone |
| Defense | Layered woodblock print, graphic defensive action | Vermilion |
| Culture & memory | Tapestry-inspired painting, communal expression | Rose and indigo |

`data/research/art_direction_styles.json` is the authoritative wording for each
direction. Keep the twelve existing research UI accent colors in that file; the
painting palette complements each accent rather than replacing game UI colors.

## Rules shared by every image

- Make a finished 3:2 landscape illustration. The discovery's particular action
  or mechanism must remain legible in the game's central banner crop.
- Match the discovery's historical date. The medium is a rendering choice, not
  permission to place anachronistic materials or art-making technology in the
  scene. Avoid recognizable real-world states, monuments, people, flags, and
  emblems in this alternative-history setting.
- Vary setting, distance, viewpoint, and people across a batch. Repeated
  standing artisans against interchangeable backdrops weaken the whole set.
- Keep all writing, signs, records, and screens illegible. No title, caption,
  border, watermark, UI, logo, or montage inside the image.
- Review at full size and at the game's card crop. Reject unclear mechanisms,
  incorrect era details, accidental symbols, distorted tools, and illegible
  silhouettes. The concept sheet established aesthetic direction only: some of
  its imagined architecture is too specific or too late for the sample date.
  The later-era pilot confirms the media remain distinct across time, while
  also exposing normal single-generation faults: pseudo-writing on records or
  containers, overly allegorical civic scenes, and objects that need closer
  historical checking. Review each final image individually before installation.

## Preparing production prompts

The discovery inventory on `codex/research-cleanup` lists 4,284 discoveries
without their own image, including 738 key thresholds. Those numbers belong to
that branch's September 25 snapshot; refresh the inventory against the current
integrated game before installing a large batch. The later block data is not
yet on `main` at the base of this art-direction branch.

`tools/build_research_art_queue.py` reads that inventory and its effects files,
finds each discovery's research direction, and writes JSONL records containing
the final prompt and metadata. It only prepares prompts: generation, visual
review, resizing, provenance, and installation remain separate steps.

Example from a checkout that has the later research data and inventory:

```powershell
python tools/build_research_art_queue.py `
  --source-root C:\Users\sjpur\tt-research-cleanup `
  --out C:\Users\sjpur\art-queue\key-thresholds.jsonl `
  --priority-only
```

Start production with a two-era pilot for each direction, including at least
one industrial or modern subject. Then generate key thresholds in small
reviewable batches, followed by the remaining discoveries. Preserve each
approved image's exact prompt, source, discovery ID, and version. Use the game's
existing `store_subject_art.py` and art manifests when the related research
blocks are integrated. A queued prompt or a copied PNG alone does not make the
game display the image.
