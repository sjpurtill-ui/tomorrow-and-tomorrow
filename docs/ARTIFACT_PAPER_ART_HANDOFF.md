# Artifact art and origins — production checkpoint

HELD for the full 4,096-image request: production remains incomplete. The origin separation and available artwork are tested; this checkpoint is not a claim of full art coverage or integration.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-artifact-paper-art`

Branch: `codex/artifact-paper-art`

Canonical base: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`. Dependency `94393c3dcc9914c2da7649953d54fa557e31b96e` was applied here as `773b43db2fe3f70b57e60e18808746a15a08141c`. No main merge or player launch.

## User's corrected direction

Exploration artifacts predate living civilizations: very crude stone bowls, chipped stones, simple bone traces, ochre and prehistoric cave-painting fragments. The user explicitly asked to preserve the initially generated, more developed decorated-object images for early civilization art. The supplied images define the paper/gouache aesthetic, not technology level or civilization identity. The earlier river motif group is not tied to a specific civilization.

## Implemented separation

New exploration finds come from `prehistoric_artifacts.gd`: 4,096 stable catalogue IDs restricted to early observational/research subjects. IDs 160–282 now have individually authored prehistoric experiments in `data/artifacts/prehistoric_experiments.json`, including crude fastenings, resin joints, portable light, sound, repairs and transferred shapes. Each carries a bounded optional `insight` description shown in the collection. IDs 283–4095 extend those 123 functional families through 31 further practical experiments (repair, scale, contact, material comparison and other changes). These are authored families with systematic experiment variations, not 4,096 independently invented technologies. Each generated result still needs material-specific visual review; unsuitable versions are preserved and revised with `revise.py`. They do not supply finished ceramics, measuring rods, seals, woven textiles, or polished ornament. Existing holding/appreciation/trade/museum rules remain in the original artifact subsystem.

Living-civilization encounter objects receive an explicit origin. Preserved art is attached only where the depicted material matches an existing paid craft recipe and its real maker knows and has adopted all required discoveries. Conservative gates are in `early_civ_artifacts.gd`. This adds no free workforce, fabricated source civ, automatic craft production or research completion. Other preserved illustrations remain available in the bank for future matching production paths.

The runtime uses separate `prehistoric-v1` and `early-civ-v1` indices, validates record origins and maker requirements, and keys its 48-texture cache by full path to prevent same-ID collisions. Approved artwork displays at collection-card size with a 512-pixel import limit; source PNGs retain full resolution. The UI says PREHISTORIC FIND or CIVILIZATION-MADE. Existing unclassified records retain their existing generic presentation.

## Current artwork and verification

21 earlier civilization-art originals remain preserved and visually reviewed for civilization use. The prehistoric bank has at least 743 approved illustrations at this checkpoint; generation and review continue beyond that count. The manifests are authoritative for live counts. All generated originals from the earlier registration-path parsing failure were recovered and registered without regeneration. Letter-like first versions of bones 11 and 43 and tooth 77 remain archived under `art_source/prehistoric-art/rejected/`. Meaningful prehistoric marks, knots and experiments are allowed; no blanket ban on ingenuity or intentional traces.

96 combined headless cases passed with zero errors, failures, skips or orphans in `/tmp/tt-creative-tests.log`. After adding explicit insight serialization/type/length checks and an insight-bearing collection geometry case, all 34 cases in the affected visual suite passed (`/tmp/tt-creative-insight-tests.log`). After expanding all authored runtime definitions, 71 cases across the visual and artifact-collection suites passed with zero errors, failures, skips or orphans (`/tmp/tt-experiment-catalogue-tests.log`). The previous full artwork import passed; newly arriving images still require a final headless import before handoff. These are isolated headless checks, not player screenshots or FPS results.

Every approved original has been visually inspected. Source PNGs remain byte-for-byte originals. The built-in generation queue now extracts the precise PNG path and registers each result under the manifest lock; long-running registration commands must be awaited through their session IDs before deciding success. Production is active, not complete.

## Continuation and integration

Continue **prehistoric.py**, not the obsolete decorated-object sequence. See `tools/artifact_art/README.md`. Built-in generation only; the user has not opted into a paid API batch. Keep prompts and originals separate from completed/approved counts. `audit --complete` must pass before claiming the full request is complete.

Changes remain in this isolated art worktree. Owned files include artifact origin/catalogue modules, society exchange and collection UI hooks, art loader, tests, both art banks, reference images and production manifests/helpers. No tech-tree art files are changed. The targeted edits in `artifact_collection.gd`, `society_exchange.gd` and `exchange_collection_panel.gd` must be reconciled with any concurrent integration of the prior artifact delivery. Save fields are additive/optional; existing objects are not renamed or reclassified retrospectively. The owned ignored test `override.cfg` currently isolates checks and must be removed before final handoff; tests use the isolated `TomorrowArtifactPaperArtTests` data directory. No player/editor was stopped or launched.
