extends GdUnitTestSuite
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

func after_test()->void:WorldSimulation.clear()

func fixture(build:bool=true)->Terrain:
	WorldSimulation.clear();GameState.reset_for_new_world(873421)
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);canvas.own_world_3d=true;add_child(canvas)
	var terrain:=Terrain.new();canvas.add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	terrain.camera=Camera3D.new();canvas.add_child(terrain.camera)
	terrain.camera.size=.3;terrain.zoom_target_size=-1;terrain.camera_input_msec=-1000
	terrain.camera_target=Vector3(12000,terrain._height_at(12000,-3800),-3800)
	if build:terrain._rebuild_close_vegetation(terrain.camera_target)
	return terrain

func materials(terrain:Terrain)->Array[ShaderMaterial]:
	var result:Array[ShaderMaterial]=[]
	for child:Node in terrain.close_vegetation_root.get_children():
		if child is GeometryInstance3D:result.append(child.material_override)
	return result

func geometry(terrain:Terrain)->Array:
	var result:Array=[]
	if terrain.close_vegetation_root==null:return result
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

func test_first_construction_waits_until_foliage_is_visible_then_zoom_keeps_it()->void:
	var terrain:=fixture(false)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=terrain.camera_target
	# The close ground layer is independent of the vegetation construction gate.
	terrain.detail_terrain_patch=MeshInstance3D.new();terrain.add_child(terrain.detail_terrain_patch)
	for size:Vector2i in [Vector2i(960,720),Vector2i(1280,720),Vector2i(2560,1080),Vector2i(720,1280)]:
		(terrain.get_viewport() as SubViewport).size=size
		terrain.set_camera_distance_level(0);terrain.camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1
		terrain.camera_input_msec=-1000
		terrain._rebuild_close_vegetation(terrain.camera_target);terrain._update_scale_lod()
		assert_object(terrain.close_vegetation_root).is_null()
	(terrain.get_viewport() as SubViewport).size=Vector2i(1280,720)
	terrain.camera.size=.7;terrain.camera_input_msec=Time.get_ticks_msec();terrain._update_scale_lod()
	assert_object(terrain.close_vegetation_root).is_null()
	terrain.camera_input_msec=-1000;terrain._update_scale_lod()
	assert_object(terrain.close_vegetation_root).is_not_null()
	assert_bool(terrain.close_vegetation_root.visible).is_true()
	var original:=geometry(terrain);var root_id:=terrain.close_vegetation_root.get_instance_id()
	assert_int(original.size()).is_greater(0)
	for span:float in [1.5,.3,50.0,.7]:
		terrain.camera.size=span;terrain._update_scale_lod()
		assert_int(terrain.close_vegetation_root.get_instance_id()).is_equal(root_id)
		assert_array(geometry(terrain)).is_equal(original)

func test_hidden_physical_changes_wait_but_upkeep_retains_the_constructed_patch()->void:
	var terrain:=fixture();var root_id:=terrain.close_vegetation_root.get_instance_id()
	var original:=geometry(terrain)
	GameState.morphology_revision+=1
	terrain._rebuild_close_vegetation(terrain.camera_target)
	assert_int(terrain.close_vegetation_root.get_instance_id()).is_equal(root_id)
	assert_array(geometry(terrain)).is_equal(original)
	# This span passes the old 1.8 km ground-detail gate, but on a wide screen
	# foliage has already disappeared. Actual surface changes still defer.
	terrain.camera.size=1.5
	GameState.settlement_routes.append({"points":PackedVector2Array([Vector2(-.1,0),Vector2(.1,0)]),"width_m":4.0})
	GameState.morphology_revision+=1
	terrain._rebuild_close_vegetation(terrain.camera_target)
	assert_int(terrain.close_vegetation_root.get_instance_id()).is_equal(root_id)
	assert_array(geometry(terrain)).is_equal(original)
	terrain.camera.size=.3;terrain._rebuild_close_vegetation(terrain.camera_target);terrain._update_scale_lod()
	assert_int(terrain.close_vegetation_root.get_instance_id()).is_not_equal(root_id)
	assert_int(terrain.close_vegetation_revision).is_equal(GameState.morphology_revision)
	assert_bool(terrain.close_vegetation_root.visible).is_true()

func test_portrait_visible_foliage_is_built_above_the_old_ground_cutoff()->void:
	var terrain:=fixture(false)
	(terrain.get_viewport() as SubViewport).size=Vector2i(720,1280)
	terrain.camera.size=2.0
	assert_float(terrain._close_vegetation_lod_strength()).is_greater(.001)
	terrain._rebuild_close_vegetation(terrain.camera_target);terrain._update_scale_lod()
	assert_object(terrain.close_vegetation_root).is_not_null()
	assert_bool(terrain.close_vegetation_root.visible).is_true()
