# Early roof filtering

Base eba7ec53927a8a98827b01cc6c88136624a94486; branch codex/early-roof-filtering.

The early roof atlas sampler now uses its existing mip chain, matching late roofs. This removes high-frequency photographic speckle in the inspected aerial village image without changing roof geometry, materials, condition, simulation, or saves.

74 texture/settlement architecture tests pass. New regression checks both actual roof sampler declarations and their bound textures' mip chains. Compared artifacts/village-roof-unfiltered.png and village-roof-filtered.png at identical seeded settlement/camera settings. Camera-motion shimmer improvement is expected but not directly measured; do not claim a temporal comparison was performed. Existing capture shutdown resource warnings persist.

Only one sampler declaration in local_terrain.gd and test_map_texture_filtering.gd changed. No player launch.
