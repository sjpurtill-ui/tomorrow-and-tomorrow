# Artifact art and origins — production checkpoint

HELD for the full 4,096-image request: production remains incomplete. The origin separation and available artwork are tested; this checkpoint is not a claim of full art coverage or integration.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-artifact-paper-art`

Branch: `codex/artifact-paper-art`

Canonical base: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`. Dependency `94393c3dcc9914c2da7649953d54fa557e31b96e` was applied here as `773b43db2fe3f70b57e60e18808746a15a08141c`. No main merge or player launch.

## User's corrected direction

Exploration artifacts predate living civilizations: very crude stone bowls, chipped stones, simple bone traces, ochre and prehistoric cave-painting fragments. The user explicitly asked to preserve the initially generated, more developed decorated-object images for early civilization art. The supplied images define the paper/gouache aesthetic, not technology level or civilization identity. The earlier river motif group is not tied to a specific civilization.

## Implemented separation

New exploration finds come from `prehistoric_artifacts.gd`: 4,096 combinations of crude form, physical variation and surface preservation, restricted to early observational/research subjects. They do not supply finished ceramics, measuring rods, seals, woven textiles, or polished ornament. Existing holding/appreciation/trade/museum rules remain in the original artifact subsystem.

Living-civilization encounter objects receive an explicit origin. Preserved art is attached only where the depicted material matches an existing paid craft recipe and its real maker knows and has adopted all required discoveries. Conservative gates are in `early_civ_artifacts.gd`. This adds no free workforce, fabricated source civ, automatic craft production or research completion. Other preserved illustrations remain available in the bank for future matching production paths.

The runtime uses separate `prehistoric-v1` and `early-civ-v1` indices, validates record origins and maker requirements, and keys its 48-texture cache by full path to prevent same-ID collisions. Approved artwork displays at collection-card size with a 512-pixel import limit; source PNGs retain full resolution. The UI says PREHISTORIC FIND or CIVILIZATION-MADE. Existing unclassified records retain their existing generic presentation.

## Current artwork and verification

21 earlier civilization-art originals are preserved. Eight have explicit visual approval; thirteen are preserved pending individual review. The prehistoric bank has 88 approved illustrations (IDs 0–87) at this review checkpoint. Letter-like first versions of bones 11 and 43 and tooth 77 are archived under `art_source/prehistoric-art/rejected/`; reviewed replacements remove those glyph-like marks. Future bone/tooth prompts were tightened accordingly. Manifest counts, hashes, dimensions, prompts, visual review notes and paths are authoritative; production may extend this checkpoint. Manifest/index writes are atomic and registration is locked so generation and visual review cannot truncate each other’s records.

95 combined headless cases pass with zero errors, failures, skips or orphans in `/tmp/tt-artifact-origins-tests.log`: artifact visuals/origin gates, artifact economics/exchange and existing society exchange. Coverage includes all 4,096 prehistoric definitions, valid early evidence subjects, prevention of cross-origin artwork leakage, actual-maker discovery/adoption gates, 512-pixel resource import, legacy fallback, and illustrated collection geometry at 340×640 and 960×720. Expanded headless artwork import also exited successfully without errors (`/tmp/tt-artifact-expanded-import.log`). All original artwork claimed approved was visually inspected. These are not native gameplay screenshot or FPS results.

## Continuation and integration

Continue **prehistoric.py**, not the obsolete decorated-object sequence. See `tools/artifact_art/README.md`. Built-in generation only; the user has not opted into a paid API batch. Keep prompts and originals separate from completed/approved counts. `audit --complete` must pass before claiming the full request is complete.

Changes remain in this isolated art worktree. Owned files include artifact origin/catalogue modules, society exchange and collection UI hooks, art loader, tests, both art banks, reference images and production manifests/helpers. No tech-tree art files are changed. The targeted edits in `artifact_collection.gd`, `society_exchange.gd` and `exchange_collection_panel.gd` must be reconciled with any concurrent integration of the prior artifact delivery. Save fields are additive/optional; existing objects are not renamed or reclassified retrospectively. Remove the owned `override.cfg` before packaging; it uses the isolated `TomorrowArtifactPaperArtTests` data directory. No player/editor was stopped or launched.
