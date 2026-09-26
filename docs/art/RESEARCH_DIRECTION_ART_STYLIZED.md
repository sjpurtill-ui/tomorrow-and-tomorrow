# Twelve distinct research art directions

The approved People & Homes proof establishes the level of stylization: serious adult editorial art with visible handmade texture and simplified 2D forms. The [twelve-card review sheet](research_direction_stylized_review.png) applies that level across twelve different media. The [banner-crop sheet](research_direction_stylized_banner_crop.png) shows the paintings at the discovery-card aspect ratio and records the chosen focal points. The prior realistic pilot batch (`codex/research-art-first-batch`) and the childlike chalk retry are rejected; neither is a source for game art.

`data/research/art_direction_styles.json` records the medium, palette, form, and shared rejection criteria. Every discovery uses its direction's medium, but the objects, action, and clothing follow the discovery's own date. A direction's medium is never an anachronistic object in its scene.

The current batch covers twelve discoveries in `data/research/blocks/y2400_3000.json`, one for each direction. Each selected image lives at `assets/ui/research/subjects/<id>-v1.png` and has a matching provenance sidecar. The subject-art manifest makes the discovery card resolve the image. This is a pilot batch, not a claim that the other later-era discoveries have art.

Review at the game's banner crop before expanding production. Reject a result when it looks like a photograph with a filter, a children's cartoon, an unclear discovery, or an anachronistic scene. The failed attempts are omitted from this branch.
