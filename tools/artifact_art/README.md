# Artifact artwork production

The user corrected the art scope: the 4,096 exploration finds are PREHISTORIC, very crude, like rough stone bowls and ancient cave pigment traces. They must not look like objects made using later in-game discoveries. The completed decorated-object illustrations are preserved for early CIVILIZATION-MADE art, as explicitly requested. Both use the four supplied paper/gouache aesthetic references.

Active prehistoric queue: `python3 tools/artifact_art/prehistoric.py next --limit 4`.

The helper emits individual prompts; it does not call an image API. Use one built-in `image_gen` call per pending entry, with the supplied images as style references only. Do not resume the obsolete civilization-art production loop. No API/CLI image-generation switch has been authorized. Keep generation batches small enough to stop promptly on user corrections.

Register each original generated PNG with `prehistoric.py register --id ID --source ABSOLUTE_PATH`. Inspect the actual full image before approving with the same command plus `--review 'specific visual findings'`. This copies originals without changing pixels; only Godot import metadata limits in-game texture size to 512. Registration rejects duplicate image bytes assigned to different catalogue IDs and never overwrites a different original. File locking preserves progress across simultaneous results.

`prehistoric.py audit` validates current progress. `prehistoric.py audit --complete` intentionally fails until all 4,096 individual illustrations are approved. Pending prompts are not completed artwork. The runtime index contains approved images only; it must never map missing entries to the wrong existing artwork.

Preserved civilization bank: `catalogue.py audit`; originals live in `assets/ui/artifacts/early-civ-v1/`, with prompts and provenance in `art_source/early-civ-art/manifest.json`. The old river-themed sequence is not associated with a specific civ. Record origin plus actual maker/adoption gates determine use, not a filename or apparent visual sophistication. Do not discard these images.

The two namespaces can both have catalogue ID 0 without sharing images. Ancient records use `artifact_origin=prehistoric`, `art_collection=prehistoric-v1`, and no living source civ. Contemporary records use `artifact_origin=civilization`, `art_collection=early-civ-v1`, a real source ID and the required maker discoveries. Existing unclassified records retain generic icons; they are not retroactively reinterpreted.
