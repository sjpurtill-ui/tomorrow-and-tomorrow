# Water technology artwork

Generated with the built-in image_gen tool. Approved style reference: assets/ui/research/paper/apprentice_contracts.png. Native final outputs were visually inspected for sparse ivory composition, gouache texture, legible hollow pipe sections and the forming/jointing operations. The first overly detailed forming variant was rejected; the revised version is used.

## Clay Pipe Forming

Saved asset: assets/ui/research/paper/clay_pipe_forming.png

Initial prompt:

Use case: historical-scene. Create one square technology discovery illustration for Tomorrow and Tomorrow, subject Clay Pipe Forming. Match the approved paper-and-gouache aesthetic: warm ivory paper with ample untouched negative space across the upper half, flat dry-brushed pigment masses, coarse paper grain, broken brush edges, muted ochre and clay terracotta, charcoal silhouettes, sparse olive-gray landscape. Quiet human-scale invention. In the lower half, two ancient craftspeople in plain undyed linen shape a short hollow clay pipe section around a simple removable wooden cylindrical former on a low wooden bench. Clearly visible open circular bore on one finished unfired section resting beside them; three drying sections stand nearby. Simple clay lumps and wooden smoothing paddle, no modern machinery. Distant low hills barely suggested. Figures have simplified faces, natural restrained gestures. The practical act of forming a hollow conduit is the focal point, with generous breathing room. Matte gouache and handmade print texture, restrained detail, no glossy lighting, no photorealism, no outlines, no text, no lettering, no frame, no watermark. One coherent image, not a collage.

Final revision prompt (image 1 initial output; image 2 apprentice style reference):

Edit Image 1 (clay pipe forming) to match the visual abstraction and composition of Image 2 (approved apprentice card). Keep the hollow pipe forming subject and physically coherent hands/tools. Make the people smaller and place the entire activity in the bottom third. Leave the upper 60 percent as near-white warm ivory paper, not yellow parchment. Remove the distant village, river detail, leafy foreground and most scenery. Keep only one faint ochre hill and a muted olive-gray distant brushstroke. Faces should be nearly featureless dark silhouettes, clothes flat undyed linen masses, no anatomical shading. Use sparse matte gouache silhouettes with broken drybrush edges and paper grain exactly like Image 2. One bench with two workers and four clear clay pipe sections is sufficient. No text, no border, no watermark. Preserve square format.

Source: /Users/seanpurtill/.codex/generated_images/01a08e7d-a646-7131-a24e-5276075de165/exec-efbbd015-2b09-4095-bd47-10c386cd783e.png

## Clay Pipe Socket Jointing

Saved asset: assets/ui/research/paper/clay_pipe_socket_jointing.png

Prompt (reference is revised forming card):

Use case: style-transfer. Transform the reference card into a distinct square discovery illustration for Clay Pipe Socket Jointing, preserving its exact sparse ivory-paper-and-gouache aesthetic, matte drybrush grain, muted terracotta/ochre/olive palette and large untouched upper 60 percent. Replace the potters and bench with two small ancient workers kneeling beside a shallow horizontal trench in the lower third. They carefully align the narrow end of one terracotta water pipe into the wider socket of the next; one presses clay sealant into the circular seam. Show four short connected cylindrical sections with plausible straight alignment, one spare open-bore section and a small bowl of clay. The conduit rests on the trench floor, not floating; no water gushes from the joints. Plain linen clothes, dark nearly featureless faces, simple calm gestures. A faint ochre hill and muted low olive brushstroke only. No modern machinery, dramatic scenery, technical diagrams, arrows, text, labels, border or watermark.

Source: /Users/seanpurtill/.codex/generated_images/01a08e7d-a646-7131-a24e-5276075de165/exec-eb937dac-2120-4904-85b7-459ab8b96f84.png


## Integration handoff

READY artwork-only branch `codex/water-art`, base `7a5e91ff9cc2005c1560bdb348fc8ff67e796044`, worktree `/Users/seanpurtill/Documents/Codex/tt-water-art`. Two new subject bindings in `scripts/hud/research_visuals.gd`; preserve other concurrent bindings when integrating. No runtime behavior or save-format change. Water discovery registration is delivered separately.

Godot 4.7.2 recovery-mode headless import exited 0. The two loaded textures are each 768×768 with mipmaps enabled; `/tmp/tt-water-art-texture-check.log`, exit 0. Native generated PNGs remain intact and project imports perform runtime sizing. No player or editor session was stopped, and no player launch is claimed. The full imagery replacement remains unfinished.
