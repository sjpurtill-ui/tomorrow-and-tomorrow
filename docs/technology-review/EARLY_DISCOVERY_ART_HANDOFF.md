# Early discovery artwork handoff

Four new illustrations for existing implemented discoveries: Selective Planting (`seed_selection`), Food Drying (`food_drying`), Basketry (`basketry`) and Material Tallies (`tallies`). Each uses its exact matching `paper/<id>` asset key. No new discovery identity or runtime mechanic is added.

Generated with the built-in image tool using the approved oral-epics painting as a style reference. Each native original is1254×1254 pixels; no crop or raster transformation was applied. Texture imports limit runtime size to768 pixels with mipmaps. Prompts, original source paths and intended bindings are recorded in EARLY_DISCOVERY_ART_MANIFEST.json.

Visual review: selective planting visibly compares seed heads beside a selected-seed tray; drying uses separated food on open racks with no smoking fire; basketry shows an unfinished interlaced rim and gathered reeds; tallies connects notched sticks to counted stores. All four preserve ivory paper, matte pigment, ochre/charcoal silhouettes and open upper space. These are illustrative historical scenes, not archaeological reconstructions or technical instructions.

The shared `scripts/hud/research_visuals.gd` is deliberately not changed because the integrator owns concurrent bindings. Integration must add each of these four exact mappings to DISCOVERY_ART, preserve all existing mappings, run the existing atlas verification and regenerate the queue. Until that happens these paintings are committed assets, not four additional bound cards.

Worktree: /Users/seanpurtill/Documents/Codex/tt-early-discovery-art
Branch: codex/early-discovery-art
Base:6fed85fb93fef79b3cabd134047b010b04437150
Ownership: four new PNGs and their import settings, manifest and this handoff. No existing art overwritten, no shared-file conflict, no save-format changes. No player launch.

Validation: isolated headless editor import exited0 with no ERROR/SCRIPT ERROR/Failed log entries. All four native square dimensions and import settings checked; an isolated headless load probe verified all four imported textures at768×768 and exited0. Existing atlas tests remain an integration check because this delivery does not modify the binding table.
