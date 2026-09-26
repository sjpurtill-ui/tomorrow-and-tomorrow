# Classical key thresholds, batch 1

Twenty-two discovery paintings for the Classical 800–1200 block. Each follows its research direction's medium and palette in `data/research/art_direction_styles.json`. The first text-only renders were rejected for realistic style drift. The selected images were redrawn with approved direction paintings as style references and reviewed at the game's 3.37:1 card crop.

`selected.json` records the generated source files. Each installed PNG has a sidecar with its brief, direction, medium, source, and SHA-256. `selected-crops-1.png` and `selected-crops-2.png` show the reviewed card crops. `verify_textures.gd` loads all 22 assets through Godot and checks their dimensions.

Generated sources remain in the Codex generated-images folder; installed copies are under `assets/ui/research/subjects/`. The paintings are keyed in `assets/ui/research/subject-art-manifest.json`.
