extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")

func _figure()->Node3D:
	var figure:Node3D=auto_free(Figure.new())
	add_child(figure)
	assert_bool(figure.setup({"variant":"male_adult","outfit":"business","hair":"cropped","beard":"short","lit":true})).is_true()
	return figure

func _uniform_meshes(figure:Node3D,hidden_only:=false)->Array[String]:
	var names:Array[String]=[]
	for node:MeshInstance3D in figure.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or (hidden_only and node.visible):continue
		# Two carried props can be revealed without rebuilding a person's look.
		if hidden_only and String(node.name) in Figure.CARRIED.values():continue
		for surface in node.mesh.get_surface_count():
			var material:=node.get_active_material(surface)
			if material is ShaderMaterial and "instance uniform" in material.shader.code:
				names.append(String(figure.get_path_to(node)));break
	return names

func test_merged_figure_does_not_allocate_instance_uniforms_for_hidden_source_parts()->void:
	var figure:=_figure()
	var hidden:=_uniform_meshes(figure,true)
	print("COURT_RENDER_BUDGET total=",_uniform_meshes(figure).size()," hidden=",hidden)
	assert_array(hidden).override_failure_message("Hidden source parts still reserve shader instance slots").is_empty()
	assert_int(_uniform_meshes(figure).size()).is_less_equal(6)

func test_redressing_and_unmerging_release_inactive_materials_without_replacing_the_rig()->void:
	var figure:=_figure()
	var skeleton:Skeleton3D=figure.skeleton
	var player:AnimationPlayer=figure.player
	var hips:=skeleton.find_bone("hips")
	var rest:=skeleton.get_bone_rest(hips)
	for lit in [false,true,false,true]:
		var look:Dictionary=figure.look.duplicate(true)
		look.lit=lit;look.hair="long" if not lit else "cropped"
		assert_bool(figure.setup(look)).is_true()
		assert_object(figure.skeleton).is_same(skeleton)
		assert_object(figure.player).is_same(player)
		assert_bool(skeleton.get_bone_rest(hips).is_equal_approx(rest)).is_true()
		assert_array(_uniform_meshes(figure,true)).is_empty()
		if lit:
			assert_int(_uniform_meshes(figure).size()).is_less_equal(6)
			assert_int(figure._merged.Body.get_blend_shape_count()).is_greater(0)
			assert_object(figure._merged.Body.get_instance_shader_parameter("face_a")).is_not_null()
		figure.play("walk_in",0.0,0.0)
		assert_str(figure.player.current_animation).is_equal("walk_in")

func test_merged_person_keeps_carried_prop_material_and_lighting()->void:
	var figure:=_figure()
	figure.carry("bundle")
	assert_bool(figure.carrying()).is_true()
	assert_bool(figure._carried.visible).is_true()
	assert_object(figure._carried.get_active_material(0)).is_instanceof(ShaderMaterial)
	figure.set_light(.72)
	assert_float(figure._carried.get_instance_shader_parameter("dim")).is_equal_approx(.72,.00001)
	assert_float(figure._merged.Body.get_instance_shader_parameter("dim")).is_equal_approx(.72,.00001)

func test_removed_merge_group_releases_its_material_and_can_be_redressed()->void:
	var figure:=_figure()
	var look:Dictionary=figure.look.duplicate(true)
	var omitted:Array=[]
	for part:MeshInstance3D in figure._parts:
		if String(part.name).begins_with("business_"):omitted.append(String(part.name))
	look.without=omitted
	assert_bool(figure.setup(look)).is_true()
	assert_bool(figure._merged.Rest.visible).is_false()
	assert_array(_uniform_meshes(figure,true)).is_empty()
	look.without=[]
	assert_bool(figure.setup(look)).is_true()
	assert_bool(figure._merged.Rest.visible).is_true()
	assert_object(figure._merged.Rest.get_active_material(0)).is_instanceof(ShaderMaterial)
	assert_int(_uniform_meshes(figure).size()).is_less_equal(6)
