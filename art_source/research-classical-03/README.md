# Classical key thresholds, batch 3

Twenty-two discovery paintings for the Classical 800–1200 block. Each follows its registry research direction and the medium and palette in `data/research/art_direction_styles.json`. Approved direction paintings were used as style references in built-in generation. Every scene was reviewed at the game's 3.37:1 banner crop. The long-service and animal-experiment scenes were regenerated after review found fake writing and a weak depiction of the discovery.

`selected.json` records generated sources. Each installed PNG has a sidecar with its brief, direction, medium, source, and SHA-256. The two `selected-crops` sheets show the final review. `verify_textures.gd` loads all 22 assets through Godot and checks their dimensions.

Generated sources remain in the Codex generated-images folder; installed copies are under `assets/ui/research/subjects/`. The paintings are keyed in `assets/ui/research/subject-art-manifest.json`.
