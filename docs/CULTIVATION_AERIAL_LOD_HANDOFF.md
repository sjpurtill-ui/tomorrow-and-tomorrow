# Cultivation aerial LOD

Base: 918bedd. Scope: settlement field materials and visual regression.

Crop micro-beds now fade continuously when their world-space pixel footprint grows
from 0.35 to 1.5 metres. The underlying crop-colored field becomes modestly stronger
over the same interval. A rows-only material uniform separates this behavior from
the broad field; no camera-dependent opacity is baked into its mesh. Active field
base alpha is 0.10 (formerly 0.035/0.09 across the mesh LOD boundary), with a maximum
shader multiplier of 3. Existing feathered parcel edges and vegetation breakup stay.

Captures: artifacts/cultivation-lod-before.png and cultivation-lod-cover.png at
0.7 km show reduced dotted row scratches; cultivation-lod-close.png at 0.25 km
retains the fine beds. These are static comparisons, not a measured temporal
shimmer benchmark. Remaining outlines/hedges and tree speckling are separate.

Tests cover separate actual row/base materials, identical ground colors across
mesh LOD 0/1, and derivative-driven shader transition. No extra geometry, textures,
simulation changes, save changes, UI layout changes or launch. Shared integration
surface: _commit_settlement_surface, _settlement_fabric_material and field base
alpha in _create_plot_fabric, scripts/local_terrain.gd.
