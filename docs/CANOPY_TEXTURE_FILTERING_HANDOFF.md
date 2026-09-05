# Canopy texture filtering

Base: 493cffc. No production shader changes; preserves procedural filtering88a3304.

The canopy shader requested filter_linear_mipmap, but its generated/untracked import
had mipmaps/generate=false. Track the explicit import (with .gitignore exception)
and generate its mip chain. Disable automatic compression conversion as for the
other explicitly managed aerial textures. Original image and alpha border retained.

Regression: loaded image mip-chain check failed before change; after headless import,
all four map-texture tests pass, including actual canopy shader binding. Before/after
captures artifacts/canopy-unfiltered.png vs canopy-filtered.png at0.25km clearly
reduce leaf speckling and retain crown shapes. Static captures only; no measured
camera-motion benchmark. Mipmap memory overhead is the normal approximately one-third
for this texture; no new images, meshes, draw calls, simulation or save changes.

Files: .gitignore, assets/textures/vegetation_canopy_atlas.png.import,
tests/test_map_texture_filtering.gd. No shared terrain shader edits, canonical edits
or player launch. Integrator must reimport the tracked texture before validation.
