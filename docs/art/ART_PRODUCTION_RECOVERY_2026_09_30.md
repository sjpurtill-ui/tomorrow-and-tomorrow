# Art production recovery — September 30, 2026

READY for integration review; not yet in the player build.

Recovered source chat: **Choose an art aesthetic**, archived Codex chat
`01a0d94b-564f-7a23-a03d-78831c465b59`. Its last completed generation was an
unregistered Watch Rotation painting. That original contained a basket and was
revised rather than silently installed.

Worktree: `C:/Users/sjpur/tt-research-art-opening-chronology-02`.
Branch: `codex/research-art-opening-chronology-02`.
Verified fetched base: `24751719d7bce474911193ccd3014142da49c0b8`.
The canonical checkout and running player/editor were not changed.

## Research paintings

Three opening subjects, all proposed game year 2:

| ID | Medium | Correction | Focus |
|---|---|---|---|
| watch_rotation | Layered hand-cut woodblock | Portable hide camp and stone spear handoff; no palisade or basket | .50, .40 |
| wound_cleaning | Transparent watercolor and restrained ink | Cupped hands rinse a minor scrape at a spring; no ceramic basin | .50, .30 |
| edible_resource_recognition | Opaque botanical tempera | Bare hands compare wild leaves and lifted root; no basket or cultivated field | .50, .55 |

The founding knowledge list includes watch rotation and edible-resource
recognition, with flaking, cordage and hafting. It does not confer basketry,
pottery, weaving or metallurgy (`scripts/founding_knowledge.gd`). The three
catalog rows have no prerequisite discoveries. Illustrations therefore need to
remain credible before those later crafts, irrespective of the proposed year.

Original PNGs and older bindings remain preserved. Three sibling `-v2.png`
paintings have provenance sidecars, exact prompts and hashes in
`art_source/research-opening-02/selected.json`. The first-300 bindings and subject
manifest resolve them both early and later; the three focus overrides read the
same manifest coordinates. A first botanical result was rejected for drifting
toward realistic rendering. The accepted botanical image uses the approved
`gene_edited_crops-v1.png` solely as a medium reference; no greenhouse, farming or
later clothing was imported into its subject.

## Prehistoric artifacts

Approved originals 1313 and 1314 depict respectively a hollow branch containing
tinder with one crude brace, and a twig assembly with a root binding and one
small splint. Both use the supplied ivory-paper/gouache reference solely for
medium. The production manifest retains catalogue prompts, exact generation
prompts, source paths, SHA256 hashes, dimensions and specific visual reviews.
The runtime index includes both approved images. Original square PNGs remain
unchanged; Godot imports them at a 512-pixel limit. No artifact definitions,
maker gates, origin rules or save fields were changed.

Artifact audit: **1,313 approved, 15 generated awaiting review, 2,768 pending**
of 4,096, with no errors. This is a production checkpoint, not full coverage.

## Validation

- Full images and actual 3.37:1 crops visually reviewed.
- Final headless editor imports exited 0 with no engine/script errors. The
  initial fresh-cache import logged font-loader errors; these did not recur
  after the import completed.
- Existing research probe with `--opening-chronology-02`: PASS, 3 subjects,
  live catalog IDs, year-dependent resolver precedence, texture paths,
  distinct hashes/provenance, hidden-subject gating and crop bounds.
- Private-desktop GPU probe: exit 0, same PASS count 3, no logged errors; actual
  captured cards inspected. Capture remains local at
  `artifacts/earliest-opening-02-research-in-game-crops.png`.
- Artifact runtime probe: PASS, 2 exact image sources, distinct loaded textures,
  512-pixel limits and rejection of a living-maker source for an ancient find.
- Artifact bank audit: no missing files, changed hashes or duplicate bytes.
- Task diff whitespace check passed.

No save compatibility changes. Shared edits are limited to the research
manifest, first-300 bindings, three focus cases in research_visuals, the existing
research art probe, and the artifact manifest/index. Reconcile those entries
deliberately if another art branch changes them. Other generated import/cache
changes are excluded from delivery.

## Resume

Continue earliest effective opening-art chronology review before expanding to
later research batches. Batch 43 and later held art are not included here.
For artifacts, next pending ID is 1315; also review the 15 existing unapproved
originals individually rather than counting them as completed. Use
`python tools/artifact_art/prehistoric.py next --limit 2` and `audit`. Built-in
image generation remains the production method. Preserve twelve research media
from `data/research/art_direction_styles.json` and the separate artifact
paper/gouache references. Full-image, card-crop, provenance and runtime approval
remain separate checks.

Only the designated integrator merges and pushes main. A pushed worker branch
does not make these paintings part of the current player game.
