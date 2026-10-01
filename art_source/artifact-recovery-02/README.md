# Continuing prehistoric artwork

Active worker branch: `codex/artifact-production-recovery-02`.
Worktree: `C:/Users/sjpur/tt-artifact-production-recovery-02`.
Base: verified `origin/main` at `24751719d7bce474911193ccd3014142da49c0b8`.
Production continues until the user asks to stop. Checkpoints are backups, not
completion or a claim of integration.

First checkpoint: three new individually reviewed built-in images (1315–1317)
and two recovered originals reviewed and approved (1019 and 1098). Their exact
original bytes and hashes are preserved. The recovered invocation prompts are
unknown; provenance does not pretend the catalogue prompt is the exact original
generation request. New generation prompts are recorded verbatim.

`reviewed.json` records each accepted source and specific full-image findings.
`register_reviewed.py` copies PNGs through the existing catalogue helper, checks
identity and duplicate hashes, records reviews, and adds known generation
prompts while preserving untouched manifest entries. `verify_batch.gd` checks
the actual runtime loader, approved namespaces, unique hashes, texture limits
and living-source rejection against every reviewed entry.

First runtime checkpoint: PASS count=5. Artifact audit: 1,316 approved,
13 generated awaiting review, 2,767 pending, no errors. Those counts exclude
the two pending artifacts in PR #11 because that PR is not in this branch's
base. IDs 1313 and 1314 are reserved to that PR and must not be regenerated.

The third fresh-cache headless import passed cleanly. The initial import exited
1 with font-loader errors; the retry completed asset import, and the subsequent
clean import and runtime passed. No player or editor was launched or stopped.
No simulation, save, origin rules, research files or maker gates changed.

Two inspected older images remain unapproved: 1012 lacks clear evidence of its
shared-attempt trace, and 1091 does not clearly show the hide-burnishing surface.
Preserve them for specific revisions rather than approving a plausible generic
object. Other old pending images still need individual review.

Second checkpoint adds 1318 (a crude bent-branch tension experiment) and 1319
(a leaf impression interrupted by a clay ridge). Headless runtime and actual
private GPU texture review both PASS count=7. The first GPU startup failed with
native exit 3221226505 before renderer initialization; a separate retry exited
0 with no logged errors and the resulting capture was inspected. Capture stays
local at `artifacts/artifact-recovery02-in-game.png`.

Additional old-image holds: 1129 reads as a pointed hafted implement, with no
clear reversed scraper edge or travel wrapping; 1131 shows a drilled-looking
stone hole instead of the required loose root cradle. Neither was approved.

Keep generation in the built-in tool, one image per specimen, with the supplied
paper/gouache reference as medium only. Every result must depict its specified
prehistoric material and mechanism. The bank is incomplete. Only the designated
integrator merges/pushes main; worker checkpoints do not update the player game.

Third checkpoint adds 1320 (hide cushioning a battered stone), 1321 (wild seed
held in a split twig) and 1322 (hide gathered around a cobble anchor), plus
individually reviewed recovered originals 1182, 1185 and 1186. The first 1320
generation had a protruding twig resembling a handle; a targeted built-in edit
shortened it before approval. Both exact requests and source paths are retained
in reviewed.json. Recovered originals retain their hashes and prior sources;
their invocation prompts remain explicitly unknown.

Clean incremental import, headless runtime and private GPU review PASS count=13.
The GPU startup again failed before initialization with native exit 3221226505;
the separate retry exited 0 and its capture was visually inspected. The probe
validates all reviewed records but displays only the newest twelve at once to
keep its capture legible as this continuous batch grows. Audit: 1,324 approved,
10 generated awaiting review, 2,762 pending, no errors. Production continues.
