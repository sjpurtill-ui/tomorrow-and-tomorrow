# Battle-front layering

Base:737e523. Extract the existing army counter alpha-pass/priority setup into an
idempotent helper and apply it to battle-front markers too. Labels stay priority32,
geometry17–26, selected ring26. Relative priorities stored on each material prevent
repeated calls from incrementing the layer band. Army behavior remains unchanged.

26 presentationtests and warfare runtimeprobe PASS. Runtime checks frontmaterials,
relative plate/core order and repeated setup after a real front snapshot update.
Existing shutdown RID warnings remain.

New self-quitting tools/warfare_front_layer_probe.gd draws the production front
over the production roof material, deliberately testing transparent overdraw.
front-layer-before.png vs front-layer-after.png confirms the missing plate/core
now remain visible. This is an isolated layer fixture, not the player build.

No save/simulation/geometry changes. Shared terrain scope: counter-layer helper and
end of _create_warfare_front_marker. No canonical edits/player launch.
