# Early civilization artwork: runtime bindings

Scope: the first 300 game years. These are illustrations, not simulated event records. Existing later-era resources remain available after the early gate. No ancestry changes gameplay statistics or civic behavior.

| File | Runtime use | Native generation file |
| --- | --- | --- |
| buildings-v1.png | Construction and settlement building cards; original 4×2 semantic order | exec-872fe1c4-89e1-48a9-8a3a-8f2b842f99b6.png |
| materials-v1.png | Materials; original 2×3 semantic order | exec-40625322-ae60-4e8f-92b9-d29b88b73c5e.png |
| workshops-v1.png | Production art and matching early product icons; original 4×3 order | exec-3d4902cb-5f50-410d-8cdf-4090b2249db5.png |
| kilnfold-scenes-v1.png | Four independent action scenes, visual family 0 | exec-dc1b4fbd-74f8-4e9a-b221-91449def2509.png |
| reedwake-scenes-v1.png | Four independent action scenes, visual family 1 | exec-a339f8d1-7db3-4e71-8f67-38c19d78ad8c.png |
| windseam-scenes-v1.png | Four independent action scenes, visual family 2 | exec-f81d102b-4362-4c38-bdc4-d9b6ec7eb70c.png |
| civic-practices-v1.png | Culture header selected from lived values: command, council, stewardship, exchange | exec-1a3c1a7c-e4c7-44a5-8a38-864ce8133431.png |

The fourth visual family uses the approved `assets/portraits/paper/stoneweft-actions-v4.png`. Native originals are retained without raster cropping; AtlasTexture crops and contained aspect ratios are used at runtime. Exact available generation prompts are in prompts.json. The civic sheet is the opaque-paper repair of exec-5fc60762-c057-4b77-83f9-bb2b7a84a070.png; that defective original is not used.

Civilization ID and world seed choose a consistent visual family. Person records retain early_art_index across saves and changes of office. Existing cabinets receive separate slots where capacity permits. Four illustrated individuals per family remain a coverage limitation: larger populations and additional offices reuse art. Four families also means different civilizations can share a family. Neither unique art for every official nor exclusive art for every civilization is complete.

Culture pictures interpret current values, not racial temperament, actual diplomatic reputation, or a recorded event. Generic research/category scenes reuse relevant existing paper subjects; specific discovery illustrations are unchanged. Texture loading is lazy and bounded, with no new per-frame image generation or simulation work beyond assigning missing appearance indices.

Direction art: directions-a-v1.png contains the first eight civic directions in 4×2 order; directions-b-v1.png contains the remaining six in 3×2 order. Both are selected by scripts/hud/ambition_art.gd for the direction cards and cultural-history illustrations. Exact prompts and native sources are in direction-prompts.json. The illustrated practices represent choices, not ancestry.

Research update: 28 specific early research subjects now use reviewed paper illustrations through ResearchVisuals; discovery visibility and later-era mappings remain intact. Known foreign-leader records also use stable civilization-owned action art. The four-family coverage limitation above remains.

Character library expansion: ashplain-scenes-v1.png adds a fifth family with four independently composed working scenes. ashplain-prompt.json retains its native source and exact prompt. scripts/character_appearance.gd now owns family names and first-assignment selection for both government and known diplomatic leaders. Existing saved families take precedence; the new family is available to first-time assignments/new worlds, not a retroactive recasting of established people. Five families still cannot give all 12–36 rivals exclusive ancestry artwork.

Rillmark adds a sixth authored family with four distinct inspection/explanation scenes; see rillmark-prompt.json. For newly assigned worlds, the player and first five canonical rival IDs use all six families before repetition. The family choice is deterministic and independent of simulation RNG. Saved appearances retain priority. This improves distribution; it does not claim six families can cover every rival uniquely.

Flintmere and Morrowfen extend the library to eight families, each with four independently composed action scenes and its own prompt/provenance file. The nonrepeating first-assignment span grows to the player plus seven rivals; established saved families are unchanged. Atlases retain 1536 caps and mipmaps, and the shared source cache remains bounded at eight textures.
