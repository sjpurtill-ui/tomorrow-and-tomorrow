extends GdUnitTestSuite
const Kit=preload("res://scripts/settlement_architecture_kit.gd")
const Ink=preload("res://scripts/settlement_ink.gd")

func test_modern_facades_are_deterministic_without_changing_the_envelope_or_roofs()->void:
	for type:String in Kit.TYPES:
		for floors in [1,3,8,18]:
			var bounds:=Kit.mesh_for("modern_"+type,floors).get_aabb()
			var roofs:=_roof_vertices(Kit.mesh_for("modern_"+type,floors))
			var fingerprints:Dictionary={}
			for facade in 3:
				var mesh:=Kit.mesh_for("modern_"+type,floors,0,"stone",facade)
				assert_object(Kit.mesh_for("modern_"+type,floors,0,"stone",facade)).is_same(mesh)
				assert_vector(mesh.get_aabb().position).is_equal(bounds.position)
				assert_vector(mesh.get_aabb().size).is_equal(bounds.size)
				assert_bool(_roof_vertices(mesh)==roofs).is_true()
				fingerprints[hash(var_to_bytes(mesh.surface_get_arrays(0)))]=true
			assert_int(fingerprints.size()).is_equal(3)

func test_facade_choice_does_not_modify_records_or_follow_the_clock()->void:
	var plot:={"id":7,"seed":24,"land_use":"mixed_household","fabric_generation":12,"storeys":8,"roof_plan":"rubble_slab"}
	var before:=var_to_bytes(plot)
	var mesh:=Kit.mesh_for_plot(plot)
	var old_day:float=GameState.elapsed_days
	GameState.elapsed_days=0
	assert_object(Kit.mesh_for_plot(plot)).is_same(mesh)
	GameState.elapsed_days=3000*365
	assert_object(Kit.mesh_for_plot(plot)).is_same(mesh)
	GameState.elapsed_days=old_day
	assert_bool(var_to_bytes(plot)==before).is_true()
	var families:Dictionary={}
	for seed in [0,4,8]:
		plot.seed=seed
		assert_str(Kit.kind(plot)).is_equal("modern_terrace")
		families[Kit.facade_for(plot)]=true
	assert_int(families.size()).is_equal(3)

func test_preindustrial_meshes_ignore_the_new_facade_option()->void:
	for family in ["masonry","industrial","timber"]:
		for type in Kit.TYPES:
			var mesh:=Kit.mesh_for(family+"_"+type,3,0,"brick|tile_chimney")
			for facade in [1,2]:
				assert_object(Kit.mesh_for(family+"_"+type,3,0,"brick|tile_chimney",facade)).is_same(mesh)

func test_only_marked_modern_glass_uses_the_architecture_finish()->void:
	assert_bool(Ink.material().get_shader_parameter("architecture_surfaces")==true).is_false()
	assert_bool(Ink.architecture_material().get_shader_parameter("architecture_surfaces")).is_true()
	assert_object(Ink.architecture_material().shader).is_not_same(Ink.material().shader)
	assert_bool(Ink.outline_material().get_shader_parameter("glass_edges")==true).is_false()
	assert_bool(Ink.architecture_material().next_pass.get_shader_parameter("glass_edges")).is_true()
	var colors:PackedColorArray=Kit.mesh_for("modern_terrace",8).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var marked:=0
	for c in colors:
		if c.a>.84 and c.a<.88:marked+=1
	assert_int(marked).is_greater(0)
	colors=Kit.mesh_for("masonry_terrace",3).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for c in colors:assert_bool(c.a>.84 and c.a<.88).is_false()

func _roof_vertices(mesh:Mesh)->PackedVector3Array:
	var arrays:=mesh.surface_get_arrays(0)
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var result:=PackedVector3Array()
	for i in vertices.size():
		if colors[i].a>.9 and colors[i].a<.985:result.append(vertices[i])
	return result
