# Food and water paper artwork

Built-in image_gen, September 22, 2026. Three selected native PNGs, preserved unchanged. Approved style reference: assets/ui/research/paper/oral_epics.png. One style correction per new image removes excessive realism. Representative early food practices, not literal city inventories or unlock evidence.

Bindings replace the former food-atlas in food reserves, store rows, water access and the settlement food card. Preserved food and water reuse food_drying.png and clean_water.png with non-destructive UI framing. Runtime imports cap new textures at 768px with mipmaps; five-entry lazy cache, no map or simulation work.

## fresh-plants-v1.png

Initial prompt:
Create ONE landscape 3:2 production game illustration, no text or border. The approved aesthetic is spare matte gouache on warm ivory fibrous paper, visible dry pigment, broad flat charcoal silhouettes, restrained ochre, umber and sage, simplified faces, quiet human dignity. No photography, 3D, glossy objects, cinematic lighting, fantasy, labels or UI. Scene occupies lower two thirds with broken dry brush edges fading naturally into ivory on every side, upper third quiet blank paper. Prehistoric settled community, simple woven garments, handmade equipment, no modern items. Readable at small card size. Two gatherers sorting freshly gathered edible leafy greens, roots and small wild berries into a shallow reed basket beside a patch of low vegetation. Plants and human action clearly legible. No corn, tomatoes, potatoes or overflowing luxury fruit display.

## meat-fish-v1.png

Initial prompt:
Create ONE landscape 3:2 production game illustration, no text or border. The approved aesthetic is spare matte gouache on warm ivory fibrous paper, visible dry pigment, broad flat charcoal silhouettes, restrained ochre, umber and sage, simplified faces, quiet human dignity. No photography, 3D, glossy objects, cinematic lighting, fantasy, labels or UI. Scene occupies lower two thirds with broken dry brush edges fading naturally into ivory on every side, upper third quiet blank paper. Prehistoric settled community, simple woven garments, handmade equipment, no modern items. Readable at small card size. Two riverside fishers laying several whole small fish from a woven fish trap onto a reed mat. One person crouches with the trap and another holds the mat edge. Subtle river reed silhouettes. Modest daily catch, not a feast, no boats with modern fittings.

## dry-staples-v1.png

Initial prompt:
Create ONE landscape 3:2 production game illustration, no text or border. The approved aesthetic is spare matte gouache on warm ivory fibrous paper, visible dry pigment, broad flat charcoal silhouettes, restrained ochre, umber and sage, simplified faces, quiet human dignity. No photography, 3D, glossy objects, cinematic lighting, fantasy, labels or UI. Scene occupies lower two thirds with broken dry brush edges fading naturally into ivory on every side, upper third quiet blank paper. Prehistoric settled community, simple woven garments, handmade equipment, no modern items. Readable at small card size. A seated person pouring dry cereal grains from a small basket into a large coarse woven storage basket, a second person tying a filled grain sack. A few cereal stalks beside them. Grain and storage are the clear subject, no milling machinery, no labels.

## Shared final edit prompt

Restyle FIRST image to closely match the SECOND reference's very flat charcoal silhouettes and spare abstract gouache. Keep the first image's specific food activity readable, landscape 3:2. REMOVE detailed faces and anatomical modeling: heads and hands are flat dark ink silhouettes. Remove almost all background buildings and scenery; just two or three loose terrain brush shapes. Restrict pigment to charcoal black, ochre, dull sage, gray. Figures wear simple solid ochre or umber woven garments, not detailed ragged caveman clothing. Large irregular dry pigment shapes and paper grain; NOT realistic painted illustration. Upper third blank warm ivory paper. Match the reference's graphic simplicity and quiet dignity, human activity grouped across lower two thirds, fading paper edges. No text, border, captions or UI.

## Remaining migration

## Validation and provenance

Godot 4.7.2 headless import completed without script/import errors. Runtime probe loaded all five bindings, checked nonempty in-bounds framing, 768px size limits and texture cache reuse: FOOD_PAPER_ALL_PASS. Native selected images were visually inspected; full player-screen review remains with the user. No game restart, save-schema or gameplay changes.

Selected native sources under C:/Users/sjpur/.codex/generated_images/01a0c20c-f896-7520-a475-0c05aa067a1a/:
- fresh-plants-v1.png: exec-713b98f6-4ec0-422c-8a0c-2eed54415911.png
- meat-fish-v1.png: exec-1e3be028-4c47-4556-ac1d-cb2597b555fe.png
- dry-staples-v1.png: exec-4fc6efcc-beec-4832-935f-0edb07a3818b.png

## Remaining migration scope

This batch replaces Food & Water only. Older building and workshop atlases, leader portraits, culture/opening art, scouting banners, military and world screens still need individual subject and style review. Keep the paper direction throughout those replacements; asset creation is not runtime integration. No map art or simulation change in this batch.
