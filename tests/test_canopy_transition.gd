extends GdUnitTestSuite
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

func after_test()->void:WorldSimulation.clear()

func fixture()->Terrain:
	WorldSimulation.clear();GameState.reset_for_new_world(873421)
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);canvas.own_world_3d=true;add_child(canvas)
	var terrain:=Terrain.new();canvas.add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	terrain.camera=Camera3D.new();canvas.add_child(terrain.camera)
	terrain.camera_target=Vector3(12000,terrain._height_at(12000,-3800),-3800)
	terrain._rebuild_close_vegetation(terrain.camera_target)
	return terrain

func materials(terrain:Terrain)->Array[ShaderMaterial]:
	var result:Array[ShaderMaterial]=[]
	for child:Node in terrain.close_vegetation_root.get_children():
		if child is GeometryInstance3D:result.append(child.material_override)
	return result

func geometry(terrain:Terrain)->Array:
	var result:Array=[]
	for child:Node in terrain.close_vegetation_root.get_children():
		if child is MultiMeshInstance3D:
			var plants:Array=[]
			for i in child.multimesh.instance_count:plants.append([child.multimesh.get_instance_transform(i),child.multimesh.get_instance_color(i),child.multimesh.get_instance_custom_data(i)])
			result.append([child.name,child.multimesh.get_rid(),plants])
		elif child is MeshInstance3D:result.append([child.name,child.mesh.get_rid()])
	return result

func test_all_actual_distances_handoff_the_same_patch_at_different_aspects()->void:
	var terrain:=fixture();var before:=geometry(terrain)
	for size:Vector2i in [Vector2i(960,720),Vector2i(1280,720),Vector2i(2560,1080),Vector2i(720,1280)]:
		(terrain.get_viewport() as SubViewport).size=size
		for level in 4:
			terrain.set_camera_distance_level(level);terrain.camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1
			terrain._update_camera();terrain._update_scale_lod()
			assert_bool(terrain.close_vegetation_root.visible).is_false()
			for material in materials(terrain):assert_float(material.get_shader_parameter("lod_fade")).is_equal(0.0)
			if level==0:assert_float(terrain.camera.position.y-terrain.camera_target.y).is_equal_approx(3.048,.001)
	assert_array(geometry(terrain)).is_equal(before)

func test_crowns_scrub_and_understory_fade_together_without_rebuilding()->void:
	var terrain:=fixture();var before:=geometry(terrain)
	var resources:=GameState.resource_deposits.duplicate(true);var population:=GameState.population_exact
	var kinds:Dictionary={}
	for material in materials(terrain):kinds[material.get_shader_parameter("vegetation_kind")]=true
	assert_int(kinds.size()).is_equal(3)
	var previous:=1.0
	for step in 120:
		terrain.camera.size=.2+float(step)*.01;terrain._update_scale_lod()
		var values:=materials(terrain);var fade:=float(values[0].get_shader_parameter("lod_fade"))
		assert_float(fade).is_between(0.0,previous)
		assert_float(previous-fade).is_less(.03)
		for material in values:assert_float(material.get_shader_parameter("lod_fade")).is_equal(fade)
		previous=fade
	assert_float(previous).is_equal(0.0)
	assert_array(geometry(terrain)).is_equal(before)
	assert_array(GameState.resource_deposits).is_equal(resources)
	assert_float(GameState.population_exact).is_equal(population)

func test_rebuilt_patch_receives_current_blend_and_its_own_boundary()->void:
	var terrain:=fixture();terrain.camera.size=.7;terrain._update_scale_lod()
	var fade:=float(materials(terrain)[0].get_shader_parameter("lod_fade"))
	assert_float(fade).is_between(.01,.99)
	var destination:=terrain.camera_target+Vector3(.04,0,.02)
	terrain._rebuild_close_vegetation(destination);terrain._update_scale_lod()
	for material in materials(terrain):
		assert_float(material.get_shader_parameter("lod_fade")).is_equal(fade)
		var edge:Vector4=material.get_shader_parameter("close_patch")
		assert_float(edge.x).is_equal(destination.x);assert_float(edge.y).is_equal(destination.z)
		assert_float(edge.z).is_between(.1,.2);assert_float(edge.w).is_between(.2,.235001)
