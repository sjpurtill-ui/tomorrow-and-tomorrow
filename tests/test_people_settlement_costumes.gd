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

func test_painterly_frames_keep_transparent_gutters_and_complete_pose_cells() -> void:
	var texture := Costumes.atlas_texture()
	assert_object(texture).is_not_null()
	if texture == null: return
	var source := texture.get_image()
	var frames := Costumes.atlas_layout()
	assert_int(frames.size()).is_equal(24)
	var cell := Vector2i(source.get_width()/6, source.get_height()/4)
	for index in frames.size():
		var origin := Vector2i(index%6, index/6)*cell
		var sample := source.get_region(Rect2i(origin,cell))
		assert_bool(sample.get_used_rect().has_area()).override_failure_message("Missing painted pose %d"%index).is_true()
		assert_float(sample.get_pixel(0,0).a).is_less(0.03)
		assert_float(sample.get_pixel(cell.x-1,0).a).is_less(0.03)
		var frame:Vector4=frames[index]
		assert_bool(frame.x>=0 and frame.y>=0 and frame.x+frame.z<=1 and frame.y+frame.w<=1).is_true()

func test_painterly_material_preserves_private_visibility_and_supply_contract() -> void:
	var original := Ink.material("person").shader
	var shader := Shader.new();shader.code=Costumes.painterly_shader_code()
	var material := ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("people_atlas",Costumes.atlas_texture())
	material.set_shader_parameter("people_frames",Costumes.atlas_layout())
	var look := Costumes.appearance(["plain_weaving"],{"adoption":{"plain_weaving":1.0},"coverage":0.25})
	for parameter:String in look.uniforms:material.set_shader_parameter(parameter,look.uniforms[parameter])
	assert_float(material.get_shader_parameter("garment_stage")).is_equal(2.0)
	assert_float(material.get_shader_parameter("garment_supply")).is_equal(0.25)
	assert_bool(material.get_shader_parameter("map_people_visible")==true).is_false()
	assert_object(Ink.material("person").shader).is_same(original)

func test_motion_uses_complete_walking_and_carried_body_frames() -> void:
	var motion := Costumes.motion_uniforms()
	for prefix:String in ["walk", "carry", "male_walk", "male_carry"]:
		assert_bool(motion[prefix+"_atlas_ready"]).is_true()
		var texture:Texture2D=motion[prefix+"_atlas"]
		assert_object(texture).is_not_null()
		if texture==null:continue
		var frames:PackedVector4Array=motion[prefix+"_frames"]
		assert_int(frames.size()).is_equal(16)
		var source:=texture.get_image()
		for index in frames.size():
			var region:=frames[index]
			assert_bool(region.x>=0 and region.y>=0 and region.x+region.z<=1 and region.y+region.w<=1).is_true()
			var start:=Vector2i(roundi(region.x*source.get_width()-.5),roundi(region.y*source.get_height()-.5))
			var end:=start+Vector2i(roundi(region.z*source.get_width()+1),roundi(region.w*source.get_height()+1))
			assert_bool(source.get_region(Rect2i(start,end-start)).get_used_rect().has_area()).override_failure_message("Missing %s phase %d"%[prefix,index]).is_true()
			if prefix.begins_with("male"):
				for x in range(start.x,end.x):
					assert_float(source.get_pixel(x,start.y).a).is_less(.03)
					assert_float(source.get_pixel(x,end.y-1).a).is_less(.03)
				for y in range(start.y,end.y):
					assert_float(source.get_pixel(start.x,y).a).is_less(.03)
					assert_float(source.get_pixel(end.x-1,y).a).is_less(.03)

func test_motion_registration_keeps_feet_on_ground_and_head_stable() -> void:
	var motion:=Costumes.motion_uniforms()
	for prefix:String in ["walk", "carry", "male_walk", "male_carry"]:
		var texture:Texture2D=motion[prefix+"_atlas"]
		if texture==null:continue
		var source:=texture.get_image()
		var registrations:PackedVector4Array=motion[prefix+"_registration"]
		var frames:PackedVector4Array=motion[prefix+"_frames"]
		assert_int(registrations.size()).is_equal(16)
		for index in registrations.size():
			var region:=frames[index]
			var start:=Vector2i(roundi(region.x*source.get_width()-.5),roundi(region.y*source.get_height()-.5))
			var end:=start+Vector2i(roundi(region.z*source.get_width()+1),roundi(region.w*source.get_height()+1))
			var size:=end-start;var top:=size.y;var feet:=0;var head:=0.0;var samples:=0
			for y in size.y:
				for x in size.x:
					if source.get_pixel(start.x+x,start.y+y).a<.5:continue
					top=mini(top,y);feet=maxi(feet,y)
					if y<size.y*.25:head+=x;samples+=1
			if prefix.begins_with("male"):
				head=0;samples=0
				for y in range(top,mini(feet+1,ceili(top+(feet-top)*.25))):
					for x in size.x:
						if source.get_pixel(start.x+x,start.y+y).a<.5:continue
						head+=x;samples+=1
			var registration:=registrations[index]
			var shown_feet:=.985+(float(feet)/size.y-registration.y)*registration.z
			var shown_head:=.60+(head/maxi(1,samples)/size.x-registration.x)*registration.z
			var shown_height:=float(feet-top)/size.y*registration.z
			assert_float(shown_feet).is_equal_approx(.985,.001)
			assert_float(shown_head).is_equal_approx(.60,.001)
			assert_float(shown_height).is_equal_approx(.94,.001)

func test_representative_encoding_keeps_roles_sexes_and_load_independent() -> void:
	assert_array(Costumes.ROLES).is_equal(preload("res://scripts/manual_work.gd").ROLES)
	var sexes:=[0,0]
	for identity in 100:
		var sex:=identity%2;sexes[sex]+=1
		for carrying in [false,true]:
			var code:=Costumes.instance_code(identity%9,sex,carrying)
			var fields:=Costumes.instance_fields(code)
			assert_bool(fields.encoded).is_true()
			assert_int(fields.role).is_equal(identity%9)
			assert_int(fields.sex).is_equal(sex)
			assert_bool(fields.carrying).is_equal(carrying)
	assert_array(sexes).is_equal([50,50])
	assert_bool(Costumes.instance_fields(0).encoded).is_false()
	assert_bool(Costumes.instance_fields(1).carrying).is_true()
	assert_bool(Costumes.instance_fields(2).encoded).is_false()

func test_role_art_has_eighteen_separate_complete_cells_and_grounded_proportions() -> void:
	var art:=Costumes.cast_uniforms()
	assert_bool(art.role_atlas_ready).is_true()
	var source:Image=art.role_atlas.get_image()
	assert_int(art.role_frames.size()).is_equal(18)
	assert_int(art.role_registration.size()).is_equal(18)
	for index in 18:
		var start:=Vector2i(roundi(float(index%6)*source.get_width()/6),roundi(float(index/6)*source.get_height()/3))
		var end:=Vector2i(roundi(float(index%6+1)*source.get_width()/6),roundi(float(index/6+1)*source.get_height()/3))
		var region:=source.get_region(Rect2i(start,end-start))
		assert_bool(region.get_used_rect().has_area()).is_true()
		for x in region.get_width():
			assert_float(region.get_pixel(x,0).a).is_less(.03)
			assert_float(region.get_pixel(x,region.get_height()-1).a).is_less(.03)
		for y in region.get_height():
			assert_float(region.get_pixel(0,y).a).is_less(.03)
			assert_float(region.get_pixel(region.get_width()-1,y).a).is_less(.03)
		var registration:Vector4=art.role_registration[index]
		assert_bool(is_finite(registration.z) and registration.z>0).is_true()
		assert_float(float(Costumes.ROLE_HEIGHTS[index])).is_between(.5,1.1)
