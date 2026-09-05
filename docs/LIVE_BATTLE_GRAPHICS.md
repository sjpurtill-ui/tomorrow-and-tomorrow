# Live armies and battle graphics

Open Military Command with F6. Armies > Inspect in 3D opens the home army. The field-army dialog has 3D View for the selected force. Use the existing field-army orders to move it; nearby army figures show the chosen models and interpolate route updates. Orders > View Battle opens an active campaign engagement.

The army inspector offers equipment, classical and medieval appearance themes and individual formation models. These choices are cosmetic, stored on formations, and leave combat equipment, cost and counters unchanged. The 26 land models are available across compatible broad combat roles. Armored formations and modern artillery currently use motorized infantry and field artillery placeholders. Triremes remain separate assets pending naval integration.

The battle screen displays actual combat-round personnel, morale, losses, and events. Hold Round, Press Attack, and Retreat issue campaign orders. Drag to orbit, scroll to zoom, click formation banners to inspect, or use Front Line and Director Camera. Pause View and Slow Motion control presentation only; campaign time continues.

Each side uses at most 96 GPU-animated representative figures. A fallen figure represents a share of losses from action, including wounded and scattered personnel. Formation positions illustrate the aggregate round; they do not simulate individual collisions, ranges, or terrain cover. Projectile cues require recorded ammunition use. The round record is a summary, not yet a scrub-enabled replay.

The Battle Lab includes Open Live 3D Battlefield. Its condition tracking now uses counted cohorts instead of the removed individual-citizen API. The standalone scene `res://tools/battle_graphics_demo.tscn` runs an isolated demonstration without changing campaign state.

Validation: battle_graphics_probe checks cosmetic combat invariance, metadata export, two campaign rounds, casualty/reset/retreat/pause handling, and the 192-figure limit even for billion-person armies. battle_lab_probe checks counted-cohort scaling, recovery, ammunition, and 100 combat seeds. warfare_map_runtime_probe covers the map presentation. GPU capture is saved in artifacts/battle_graphics.png.

Future work: distinct historical combat definitions and unlocks, naval battles, terrain-specific battlefields, siege interactions, replay scrubbing, and richer aftermath scenes.
