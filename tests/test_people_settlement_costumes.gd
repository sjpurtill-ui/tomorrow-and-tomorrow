extends GdUnitTestSuite
const Costumes = preload("res://scripts/hud/people_settlement_costumes.gd")
const Ink = preload("res://scripts/map_life_ink.gd")
const Clothing = preload("res://scripts/clothing_knowledge.gd")
const Textile = preload("res://scripts/textile_knowledge.gd")

func test_unknown_or_unrelated_technology_keeps_early_wraps() -> void:
	var early := Costumes.appearance([])
	var later := Costumes.appearance(["electric_motors", "standard_measures", "warp_weighted_looms"], {"year": 5000})
	assert_str(early.style).is_equal("hide and fiber wraps")
	assert_int(early.key).is_equal(later.key)
	assert_float(early.uniforms.garment_stage).is_equal(0.0)
	assert_array(early.palette).is_equal(Costumes.HIDE_PALETTE)
	assert_float(Costumes.appearance(["plain_weaving"]).uniforms.garment_supply).is_equal(0.0)

func test_real_methods_gate_sewn_woven_and_cut_attire() -> void:
	assert_bool(Clothing.METHODS.has("bone_needle_sewing")).is_true()
	assert_bool(Clothing.METHODS.has("garment_pattern_cutting")).is_true()
	assert_bool(Textile.entries().any(func(d: Dictionary) -> bool: return d.id == "plain_weaving")).is_true()
	assert_float(Costumes.appearance(["bone_needle_sewing"]).uniforms.garment_stage).is_equal(1.0)
	assert_float(Costumes.appearance(["plain_weaving"]).uniforms.garment_stage).is_equal(2.0)
	assert_bool(Costumes.appearance(["plain_weaving"]).uniforms.garment_sewn).is_false()
	assert_float(Costumes.appearance(["garment_pattern_cutting"]).uniforms.garment_stage).is_equal(0.0)
	assert_float(Costumes.appearance(["garment_pattern_cutting", "bone_needle_sewing"]).uniforms.garment_stage).is_equal(1.0)
	assert_float(Costumes.appearance(["plain_weaving", "bone_needle_sewing", "garment_pattern_cutting"]).uniforms.garment_stage).is_equal(3.0)

func test_adoption_and_actual_supply_are_optional_read_only_limits() -> void:
	var known := ["plain_weaving", "bone_needle_sewing", "garment_pattern_cutting", "cordage"]
	var context := {"adoption": {"plain_weaving": 0.08, "bone_needle_sewing": 0.7, "cordage": 1.0}, "coverage": 0.23}
	var original := context.duplicate(true)
	var look := Costumes.appearance(known, context)
	assert_float(look.uniforms.garment_stage).is_equal(1.0)
	assert_float(look.uniforms.garment_supply).is_equal(0.23)
	assert_bool(look.uniforms.garment_tied).is_true()
	assert_dict(context).is_equal(original)
	assert_int(known.size()).is_equal(4)
	assert_float(Costumes.appearance(known, {"coverage": -1.0}).uniforms.garment_supply).is_equal(0.0)
	assert_float(Costumes.appearance(known, {"coverage": 5.0}).uniforms.garment_supply).is_equal(1.0)

func test_signature_tracks_relevant_methods_without_calendar_or_unrelated_churn() -> void:
	var first := Costumes.appearance(["cordage", "plain_weaving"])
	var reordered := Costumes.appearance(["electric_motors", "plain_weaving", "cordage"], {"year": 4000})
	assert_int(first.key).is_equal(reordered.key)
	assert_int(first.key).is_not_equal(Costumes.appearance(["cordage"]).key)
	assert_int(first.key).is_not_equal(Costumes.appearance(["cordage", "plain_weaving"], {"coverage": 0.2}).key)
	first.palette[0] = Color.MAGENTA
	assert_array(Costumes.appearance(["plain_weaving"]).palette).is_equal(Costumes.WOVEN_PALETTE)

func test_private_shader_preserves_all_original_pose_and_tool_code() -> void:
	var code := Costumes.shader_code()
	var start := Ink.PERSON.find("\tvec3 skin =")
	var end := Ink.PERSON.find("\tif (tool_len > 0.0) {")
	assert_bool(code.contains(Ink.PERSON.substr(0, start))).is_true()
	assert_bool(code.ends_with(Ink.PERSON.substr(end))).is_true()
	assert_bool(code.begins_with(Ink.HEAD)).is_true()
	assert_bool(code.contains("vec3 legs =")).is_false()
	assert_bool(code.contains("min(v_color*1.28")).is_false()
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = code
	material.shader = shader
	for name: String in Costumes.appearance([]).uniforms: material.set_shader_parameter(name, Costumes.appearance([]).uniforms[name])
	assert_bool(material.shader != Ink.material("person").shader).is_true()
