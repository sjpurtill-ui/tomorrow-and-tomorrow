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

Keep generation in the built-in tool, one image per specimen, with the supplied
paper/gouache reference as medium only. Every result must depict its specified
prehistoric material and mechanism. The bank is incomplete. Only the designated
integrator merges/pushes main; worker checkpoints do not update the player game.
