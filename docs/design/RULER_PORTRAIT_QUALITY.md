# Ruler portrait quality

October 6, 2026. The reported foreign ruler card enlarged a 112 x 128 roster
thumbnail to a 224-pixel-wide panel. Its incompatible aspect ratio also cropped
the crown, especially in the compact layout. Linear filtering and MSAA were
already enabled; neither could recover the missing source detail.

The shared portrait entry point now selects a separate 444 x 392 or 444 x 300
still for large cards. Small roster portraits retain their existing 112 x 128
budget. The bounded studio cache and one-at-a-time render queue are unchanged.
Large stills use matching mipmaps, a slight three-quarter turn, a portrait-safe
pose and framing relative to the actual head position. Seated or crouching
stage poses can no longer put the face outside the large portrait crop. The
same figure, face seed, people palette, clothing system and original art remain.
This change does not alter the live court's models, lighting or animation.

Foreign portrait subjects now read sex, birth year and portrait index from the
existing ruler record, and carry the ruler's rank into clothing selection.
Reading the portrait does not create or mutate a simulation character. The
appearance registry includes these factual presentation inputs so an older
cached appearance cannot replace them; identity seeds remain stable.

Validation uses a copied quicksave containing the exact reported ruler,
Zerudajin Chujobat of Zatkumad. Private GPU captures compare both 1600 x 900 and
1280 x 720 layouts at actual card size. The rendering comparison deliberately
uses the same corrected identity on both sides. Additional labelled specimens
cover an elderly male whose stage stance is seated and a young female.
The probe is `tests/ruler_portrait_preview.tscn`; it requires isolated QA
userdata and the private-desktop runner, and writes only ignored artifacts.
The copied save and captures are excluded from source delivery.

The 13 focused identity, figure-appearance and wardrobe tests pass with no
errors, skips or orphans (report 55). Final GPU runs pass with no engine or
script errors: large/compact textures are 444 x 392 and 444 x 300, the actual
cards are 224 x 196 and 224 x 150, and no studio jobs remain pending. Both
screen sizes retain the complete crown and face above the regard strip; both
age/stance specimens do too. The private probe processes have exited.
GPU evidence and the review are recorded
under `artifacts/ruler-portrait/`. No saved fields or simulation rules change.
The current player is preserved and loads the fix on its normal restart.
