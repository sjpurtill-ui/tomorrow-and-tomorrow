# Discovery-specific artwork — Stone Selection

Task worktree `/Users/seanpurtill/Documents/Codex/tt-discovery-art`, branch `codex/discovery-art`, based on canonical Mac `4928607e19e202ab3c978b64c7ce20aff0962980`. Sole integrator owns the discovery artwork resolver, popup, research cards/tree, new stone illustration, focused verification and this handoff. No other worker edits imported.

Cause: all discoveries selected artwork by broad domain. The production field illustration depicts pottery, so Stone Selection incorrectly displayed pottery. The catalog's Stone Selection name, description, +3% survey speed and +4% tool quality were correct.

Change: `stone_sorting` has an explicit topic-to-asset mapping to a new illustration of inspecting and testing rocks. Popup, cards, inspector and tree all use that resolver. Unexposed questions keep representative field imagery so the art does not reveal the hidden topic. Other discoveries still use generic category art with a visible FIELD ILLUSTRATION badge; this delivery does not claim every discovery has its own painting. A tree badge has a dark backing; control badges measure their text width to avoid collapsing in TextureRect parents.

Art provenance: built-in image_gen, new-image mode. Original 1536 × 1024 raster and final prompt are retained at `assets/ui/research/stone-selection-v1.png` and `assets/ui/research/PROMPTS.md`. The tracked import limits the game texture to 768px and generates mipmaps. No API key or external credential was used.

Validation:

- 29 source tests across discovery popup, research visual atlas, atlas data and discovery projects pass; zero errors/failures/skips/orphans (`/tmp/tt-discovery-art-tests-final.log`). Includes actual catalog effects, specific asset binding in popup/card/inspector, fallback badge size, hidden topic protection, pause ownership and small-window dismissal controls.
- Native Compatibility capture-only probe passes and exits (`/tmp/tt-discovery-art-native-final.log`). Stone Selection and Clay Vessels were rendered at 1200 × 900 and 800 × 600; research cards and tree also captured. Inspected actual artwork, visible fallback badges, correct effects and reachable dismissal buttons. Captures stay under `artifacts/discovery-art/`. The isolated fixture grants knowledge directly and does not claim campaign progression.
- Early validation caught a native-class name collision in the new probe and a collapsed badge width; both corrected before the final successful runs. Only the owned failed probe was terminated. Player PID 74445 was left running on its existing packaged release.
- Source diff whitespace check passes. Test userdata isolated under TomorrowDiscoveryArtTests; owned override removed before delivery.

Save compatibility: no schema or mechanics changes, no population/resource/research grants, and no change to player/opponent parity. Existing games receive the artwork when loaded by the updated release. Shared-file conflicts: none; UI files listed above exclusively owned for this task. Final source hash and canonical verification belong in INTEGRATION_STATUS.md after integration.
