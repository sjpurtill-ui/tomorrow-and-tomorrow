# First-300-year paper artwork

Scope: years 0-299. Illustrations describe practices, not recorded events. Later-era resources remain available. Ancestry never sets gameplay statistics or political behavior.

## Character identity

Thirteen authored human visual families: Kilnfold, Reedwake, Windseam, Stoneweft, Ashplain, Rillmark, Flintmere, Morrowfen, Thornbank, Sunhollow, Greyfold, Ochrestep and Hollowreed. Each supplies four principal action scenes. Stoneweft uses the previously approved five-cell source, with four allocated character slots.

`scripts/character_appearance.gd` distributes families without repetition across the default new world (player plus twelve rivals). Saved government and same-world diplomatic assignments take precedence. Larger worlds repeat families, and additional officials reuse the small cast. Existing saves are not recast. Assignment consumes no simulation RNG.

## Runtime bindings

- `early_civ_art.gd`: government, settlement leadership, known diplomatic leaders and culture practices.
- Buildings: 4x2 atlas; materials: 2x3; workshops and matching early products: 4x3.
- Fourteen civic directions: two atlases, 4x2 and 3x2, for founding choices, cultural history and the Wealth work illustration.
- Twelve undertaking design studies: two 3x2 atlases. Actual construction and operating status remain separate.
- Early scouting header, 44 explicit research subject overrides and nine military unit types use the same paper aesthetic in their respective folders.

Native generated originals are retained without raster editing. Runtime AtlasTexture regions use contained framing. Family atlases use mipmaps and a 1536 import cap; the shared source cache remains bounded at eight textures with lazy loading.

Exact prompts and native source IDs are in `prompts.json` and the named subsequent prompt JSON files. Ochrestep retains both its original and targeted cast-correction prompt. The rejected original is not used. Civic practice imagery responds to lived values independently of ancestry.

## Initial source records

| File | Runtime use | Native generation file |
| --- | --- | --- |
| buildings-v1.png | Construction and settlement building cards; original 4×2 semantic order | exec-872fe1c4-89e1-48a9-8a3a-8f2b842f99b6.png |
| materials-v1.png | Materials; original 2×3 semantic order | exec-40625322-ae60-4e8f-92b9-d29b88b73c5e.png |
| workshops-v1.png | Production art and matching early product icons; original 4×3 order | exec-3d4902cb-5f50-410d-8cdf-4090b2249db5.png |
| kilnfold-scenes-v1.png | Four independent action scenes, visual family 0 | exec-dc1b4fbd-74f8-4e9a-b221-91449def2509.png |
| reedwake-scenes-v1.png | Four independent action scenes, visual family 1 | exec-a339f8d1-7db3-4e71-8f67-38c19d78ad8c.png |
| windseam-scenes-v1.png | Four independent action scenes, visual family 2 | exec-f81d102b-4362-4c38-bdc4-d9b6ec7eb70c.png |
| civic-practices-v1.png | Culture header selected from lived values: command, council, stewardship, exchange | exec-1a3c1a7c-e4c7-44a5-8a38-864ce8133431.png |





