# Classical other discoveries, batch 6

Twenty-one discovery paintings continue the Classical non-priority inventory. Each follows its registered research direction and the handmade medium and palette in `data/research/art_direction_styles.json`. Approved direction paintings were used as style references in built-in generation. Each scene was reviewed at the game's 3.37:1 banner crop.

`selected.json` records generated sources. Each installed PNG has a sidecar with its brief, direction, medium, source, and SHA-256. The two `selected-crops` sheets show the final review. `verify_textures.gd` loads all 21 assets through Godot and checks their dimensions.

Generated sources remain in the Codex generated-images folder; installed copies are under `assets/ui/research/subjects/`. The paintings are keyed in `assets/ui/research/subject-art-manifest.json`.
