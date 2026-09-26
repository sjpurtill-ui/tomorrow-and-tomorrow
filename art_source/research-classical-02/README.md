# Classical key thresholds, batch 2

Twenty-two discovery paintings for the Classical 800–1200 block. Each follows its registry research direction and the medium and palette in `data/research/art_direction_styles.json`. Approved direction paintings were used as style references in built-in image generation. Every scene was reviewed at the game's 3.37:1 banner crop. The midwifery scene was redrawn after a direction mismatch was caught in review.

`selected.json` records generated sources. Each installed PNG has a sidecar with its brief, direction, medium, source, and SHA-256. The two `selected-crops` sheets show the final review. `verify_textures.gd` loads all 22 assets through Godot and checks their dimensions.

Generated sources remain in the Codex generated-images folder; installed copies are under `assets/ui/research/subjects/`. The paintings are keyed in `assets/ui/research/subject-art-manifest.json`.
