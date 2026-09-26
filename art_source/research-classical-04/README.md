# Classical key thresholds, batch 4

Twenty-one discovery paintings complete the Classical priority threshold list. Each follows its registry research direction and the medium and palette in `data/research/art_direction_styles.json`. Approved direction paintings were used as style references in built-in generation. Every scene was reviewed at the game's 3.37:1 banner crop. The medical scene was rephrased after image-tool rejection; the squinch dome was regenerated and given a top-focused crop so its defining structure remains visible.

`selected.json` records generated sources. Each installed PNG has a sidecar with its brief, direction, medium, source, and SHA-256. The two `selected-crops` sheets show the final review. `verify_textures.gd` loads all 21 assets through Godot and checks their dimensions.

Generated sources remain in the Codex generated-images folder; installed copies are under `assets/ui/research/subjects/`. The paintings are keyed in `assets/ui/research/subject-art-manifest.json`.
