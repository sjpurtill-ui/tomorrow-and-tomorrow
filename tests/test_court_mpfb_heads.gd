extends GdUnitTestSuite
## Real imported assets: protect the native anatomy and the runtime face contract.
const Figure = preload("res://scripts/hud/court_figure_3d.gd")
const Merge = preload("res://scripts/hud/court_figure_merge.gd")
const Acting = preload("res://scripts/hud/court_acting.gd")
const MASK_PATH := "res://assets/court_figures/mpfb_source/eyebrow001.png"
const TEETH_PATH := "res://assets/court_figures/mpfb_source/teeth.png"
const GAZE := ["eyes_left", "eyes_right", "eyes_up", "eyes_down"]
const EXPRESSIONS := ["smile", "frown", "brows_up", "brows_down", "brows_worried",
	"eyes_wide", "eyes_narrow", "blink", "jaw_open", "lips_pressed", "sneer",
	"cheeks_puff", "v_aa", "v_ee", "v_oo", "v_mm", "v_fv",
	"mood_smile", "mood_tight", "mood_worry", "mood_stern"]

var _merge_enabled := true

func before_test() -> void:
	_merge_enabled = Merge.enabled

func after_test() -> void:
	Merge.enabled = _merge_enabled

func _imported(variant: String) -> Node3D:
	var scene: PackedScene = Figure.scene_for(variant)
	assert_object(scene).override_failure_message("Missing imported court body: " + variant).is_not_null()
	return auto_free(scene.instantiate()) as Node3D if scene != null else null

func _part(root: Node, name: String) -> MeshInstance3D:
	var part := root.find_child(name, true, false) as MeshInstance3D
	assert_object(part).override_failure_message("Missing face part: " + name).is_not_null()
	return part

func _shape_index(mesh: Mesh, name: String) -> int:
	for index in mesh.get_blend_shape_count():
		if String(mesh.get_blend_shape_name(index)) == name:
			return index
	return -1

func _shape_motion(mesh: Mesh, name: String, native_only := false) -> float:
	var index := _shape_index(mesh, name)
	if index < 0:
		return 0.0
	var peak := 0.0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var base: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var shapes := mesh.surface_get_blend_shape_arrays(surface)
		if index >= shapes.size():
			continue
		var moved: PackedVector3Array = shapes[index][Mesh.ARRAY_VERTEX]
		assert_int(moved.size()).is_equal(base.size())
		for vertex in mini(base.size(), moved.size()):
			# The shader reads 1-UV2.y; a value above 1.5 disables fake relief.
			if native_only and (uv2.size() != base.size() or uv2[vertex].y >= -0.5):
				continue
			peak = maxf(peak, base[vertex].distance_to(moved[vertex]))
	return peak

func _uvs(mesh: Mesh) -> PackedVector2Array:
	var result := PackedVector2Array()
	for surface in mesh.get_surface_count():
		result.append_array(mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV])
	return result

func _figure(merged: bool, lit := true, variant := "male_adult") -> Node3D:
	Merge.enabled = merged
	var figure: Node3D = auto_free(Figure.new())
	add_child(figure)
	assert_bool(figure.setup({"variant": variant, "outfit": "tunic", "hair": "cropped",
		"lit": lit, "face": {"jaw": 0.25, "brow": -0.2}})).is_true()
	figure.player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return figure

func _assert_mask(material: ShaderMaterial) -> void:
	assert_object(material).is_not_null()
	if material == null:
		return
	var texture := material.get_shader_parameter("brow_mask") as Texture2D
	assert_object(texture).override_failure_message("Native brows need their transparent hair mask").is_not_null()
	if texture == null:
		return
	assert_str(texture.resource_path).is_equal(MASK_PATH)
	var image := texture.get_image()
	assert_object(image).is_not_null()
	if image == null:
		return
	if image.is_compressed():
		assert_int(image.decompress()).is_equal(OK)
	var low := 1.0
	var high := 0.0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var alpha := image.get_pixel(x, y).a
			low = minf(low, alpha)
			high = maxf(high, alpha)
	assert_float(low).is_less(0.1)
	assert_float(high).is_greater(0.9)

func test_all_seven_imported_heads_keep_native_anatomy_and_live_face_keys() -> void:
	for variant: String in Figure.BODIES:
		var model := _imported(variant)
		if model == null:
			continue
		var body := _part(model, "Body")
		if body == null:
			continue
		var marked := 0
		for surface in body.mesh.get_surface_count():
			var uv2: PackedVector2Array = body.mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV2]
			for point in uv2:
				if point.y < -0.5:
					marked += 1
		assert_int(marked).override_failure_message(variant + " lost the native-head relief marker").is_greater(1000)
		var keys: Array = EXPRESSIONS.duplicate()
		for identity: String in Figure.FACE_SHAPES:
			keys.append("face_" + identity)
		for key: String in keys:
			assert_float(_shape_motion(body.mesh, key, true)).override_failure_message(
				"%s: %s is missing or no longer deforms the native head" % [variant, key]).is_greater(0.00005)

func test_spherical_eyes_keep_gaze_and_leave_lid_deformation_on_the_body() -> void:
	for variant: String in Figure.BODIES:
		var model := _imported(variant)
		if model == null:
			continue
		var body := _part(model, "Body")
		var eyes := _part(model, "Eyes")
		if body == null or eyes == null:
			continue
		for key: String in GAZE:
			assert_float(_shape_motion(eyes.mesh, key)).override_failure_message(
				"%s: eye gaze %s stopped moving" % [variant, key]).is_greater(0.001)
			assert_int(_shape_index(body.mesh, key)).override_failure_message(
				"Body gaze keys steal acting's first matching eye binding").is_equal(-1)
		for key in ["blink", "eyes_narrow", "eyes_wide"]:
			assert_int(_shape_index(eyes.mesh, key)).override_failure_message(
				"%s: %s must move eyelids, not squash the eyeball" % [variant, key]).is_equal(-1)

func test_brow_alpha_uvs_and_teeth_survive_merged_and_fallback_dressing() -> void:
	for mode in [[true, true], [false, true], [false, false]]:
		var figure := _figure(mode[0], mode[1])
		var brow: MeshInstance3D = figure._mesh_named("Brows")
		var teeth: MeshInstance3D = figure._mesh_named("Mouth")
		assert_object(brow).is_not_null()
		assert_object(teeth).is_not_null()
		if brow == null or teeth == null:
			continue
		var native_uv := _uvs(brow.mesh)
		assert_int(native_uv.size()).is_greater(100)
		assert_str(teeth.mesh.surface_get_material(0).resource_name).is_equal("TEETH")
		assert_float(_shape_motion(teeth.mesh, "jaw_open")).is_greater(0.005)
		if mode[0]:
			var body: MeshInstance3D = figure._merged.Body
			var material := body.get_active_material(0) as ShaderMaterial
			_assert_mask(material)
			var teeth_texture := material.get_shader_parameter("teeth_mask") as Texture2D
			assert_object(teeth_texture).is_not_null()
			if teeth_texture != null:
				assert_str(teeth_texture.resource_path).is_equal(TEETH_PATH)
			var arrays := body.mesh.surface_get_arrays(0)
			var slots: PackedFloat32Array = (arrays[Mesh.ARRAY_CUSTOM0] as PackedByteArray).to_float32_array()
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var merged_brow := PackedVector2Array()
			var tooth_vertices := 0
			for vertex in slots.size():
				if roundi(slots[vertex]) == Merge.SLOTS.find("BROW"):
					merged_brow.append(uv[vertex])
				elif roundi(slots[vertex]) == Merge.SLOTS.find("TEETH"):
					tooth_vertices += 1
			assert_bool(merged_brow == native_uv).override_failure_message("Merging replaced the native brow texture coordinates").is_true()
			assert_int(tooth_vertices).is_greater(100)
			var palette: PackedVector3Array = material.get_shader_parameter("slot_albedo")
			assert_float(palette[Merge.SLOTS.find("TEETH")].distance_to(
				palette[Merge.SLOTS.find("MOUTH")])).is_greater(0.5)
		else:
			var brow_material := brow.get_active_material(0) as ShaderMaterial
			_assert_mask(brow_material)
			assert_bool(brow_material.get_shader_parameter("brow")).is_true()
			assert_bool(brow.visible and teeth.visible).is_true()
			var material := teeth.get_active_material(0) as ShaderMaterial
			var teeth_texture := material.get_shader_parameter("teeth_mask") as Texture2D
			assert_object(teeth_texture).is_not_null()
			if teeth_texture != null:
				assert_str(teeth_texture.resource_path).is_equal(TEETH_PATH)
			var albedo: Color = material.get_shader_parameter("albedo")
			assert_float(albedo.v).override_failure_message("Teeth inherited the dark mouth-interior material").is_greater(0.65)
			assert_object(material.next_pass).is_null()

func test_acting_closes_native_lids_without_scaling_eye_bones() -> void:
	for merged in [false, true]:
		for variant in ["male_adult", "female_old", "child"]:
			var figure := _figure(merged, true, variant)
			var actor: Node = Acting.of(figure)
			var body: MeshInstance3D = figure._merged.Body if merged else figure._mesh_named("Body")
			var blink := body.find_blend_shape_by_name("blink")
			assert_int(blink).is_greater_equal(0)
			if blink < 0:
				continue
			figure.skeleton.reset_bone_poses()
			# Drive the hold at the center of an actual acting blink, deterministically.
			actor._blink_wait = 10.0
			actor._blink_t = 0.079
			actor._face_out(0.001)
			assert_float(body.get_blend_shape_value(blink)).override_failure_message(
				"%s: acting blink did not reach the visible native Body" % variant).is_greater(0.9)
			for side in ["L", "R"]:
				var bone: int = figure.skeleton.find_bone("eye." + side)
				assert_int(bone).is_greater_equal(0)
				if bone >= 0:
					var scale: Vector3 = figure.skeleton.get_bone_pose_scale(bone)
					assert_float(scale.distance_to(Vector3.ONE)).is_less(0.00001)
