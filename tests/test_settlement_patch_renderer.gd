extends GdUnitTestSuite
const Patches=preload("res://scripts/settlement_patch_renderer.gd")
const Keys=preload("res://scripts/settlement_visual_keys.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 1.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 1.0
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _rebuild_close_vegetation(_center:Vector3)->void:pass
	func _paint_settlement_grounds(_center:Vector3)->void:pass
	func _build_settlement_stage_patch(parent:Node3D,_center:Vector3,_profile:Dictionary,_plots:Array[Dictionary],_lod:int,_defense:Dictionary)->void:
		var mesh:=MeshInstance3D.new();mesh.mesh=BoxMesh.new();parent.add_child(mesh)
	func _build_settlement_prop_patch(parent:Node3D,_center:Vector3,_plan:Dictionary,_plots:Array[Dictionary],_routes:Array[Dictionary])->void:
		parent.add_child(Node3D.new())
class GuardedTerrain extends Terrain:
	var refresh_calls:=0
	func _refresh_settlement_footprint(_force:=false)->void:refresh_calls+=1

func built(parent:Node3D,identity:String)->void:
	var node:=MeshInstance3D.new();node.name=identity;node.mesh=BoxMesh.new();parent.add_child(node)

func record(key:String,revision:int)->Dictionary:
	return {"key":key,"signature":revision,"build":built.bind("Visible"+str(revision))}

func test_local_change_keeps_other_mesh_roots_and_old_until_replacement_ready()->void:
	var root:Node3D=auto_free(Node3D.new())
	var patches:=Patches.new(root)
	patches.request([record("west",1),record("east",1)])
	patches.process(100000,8)
	var west:int=patches.stats().keys.west.node_id
	var east:int=patches.stats().keys.east.node_id
	patches.request([record("west",1),record("east",2)])
	assert_int(patches.stats().pending).is_equal(1)
	assert_int(patches.stats().keys.east.node_id).is_equal(east)
	patches.process(100000,8)
	assert_int(patches.stats().keys.west.node_id).is_equal(west)
	assert_int(patches.stats().keys.east.node_id).is_not_equal(east)
	assert_int(root.get_child_count()).is_equal(2)

func test_superseded_jobs_coalesce_and_no_longer_visible_work_is_cancelled()->void:
	var root:Node3D=auto_free(Node3D.new())
	var patches:=Patches.new(root)
	patches.request([record("a",1),record("b",1),record("c",1)])
	patches.request([record("a",2),record("b",1)])
	assert_int(patches.stats().pending).is_equal(2)
	patches.process(100000,1)
	assert_int(patches.stats().last_jobs).is_equal(1)
	assert_int(patches.stats().pending).is_equal(1)
	patches.process(100000,1)
	assert_int(patches.stats().keys.a.signature).is_equal(2)
	assert_bool(patches.stats().keys.has("c")).is_false()
	patches.request([record("a",2),record("b",1)])
	patches.process()
	assert_int(patches.stats().builds).is_equal(2)

func test_placement_ignores_economics_and_weather_but_tracks_footprints()->void:
	var plots:Array[Dictionary]=[{"id":1,"form":"timber_household","roof_plan":"timber_ridge","material_family":"timber","land_use":"residential_compound","centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2.ZERO,Vector2(.01,0),Vector2(0,.01)])}]
	var routes:Array[Dictionary]=[{"id":1,"points":PackedVector2Array([Vector2.ZERO,Vector2.ONE])}]
	var before:=Keys.placement(plots,routes)
	plots[0]["condition"]=.4;plots[0]["resident_count"]=400;plots[0]["prosperity"]=.1;plots[0]["history"]=["repair"]
	routes[0]["traffic"]=100;routes[0]["condition"]=.2
	assert_int(Keys.placement(plots,routes)).is_equal(before)
	plots[0].polygon[0]=Vector2(-.01,0)
	assert_int(Keys.placement(plots,routes)).is_not_equal(before)

func test_camera_revisit_reuses_hidden_mesh_and_cache_is_bounded()->void:
	var root:Node3D=auto_free(Node3D.new())
	var patches:=Patches.new(root)
	patches.request([record("a",1)]);patches.process()
	var original:int=patches.stats().keys.a.node_id
	patches.request([record("b",1)]);patches.process()
	assert_bool(patches.stats().keys.a.visible).is_false()
	patches.request([record("a",1)]);patches.process()
	assert_int(patches.stats().keys.a.node_id).is_equal(original)
	assert_int(patches.stats().builds).is_equal(2)
	for i in 70:
		patches.request([record(str(i),1)]);patches.process()
	assert_int(patches.stats().cached).is_less_equal(Patches.MAX_HIDDEN_PATCHES)
	assert_int(root.get_child_count()).is_less_equal(Patches.MAX_HIDDEN_PATCHES+1)

func test_cached_layout_reads_current_damage_without_moving_saved_sites()->void:
	GameState.reset_for_new_world(9121)
	var plots:Array[Dictionary]=[{"id":1,"seed":31,"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]),"frontage_route_id":1,"area_ha":.16,"roof_coverage":.3,"material_family":"organic","land_use":"residential_compound","form":"portable_shelter_cluster","roof_plan":"ridge_light_shelter","status":"active","condition":1.0}]
	GameState.settlement_plots=plots
	GameState.settlement_routes=[{"id":1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(-.025,0),Vector2(.025,0)])}]
	var terrain:Terrain=auto_free(Terrain.new())
	var first:Dictionary=terrain._organic_town_plan(Vector3.ZERO,func(_p:Vector2)->bool:return true)
	assert_int(first.buildings.size()).is_greater(0)
	var position:Vector2=first.buildings[0].position
	GameState.settlement_plots[0].condition=.1
	GameState.settlement_plots[0]["damage"]={"fire":.8}
	var next:Dictionary=terrain._organic_town_plan(Vector3.ZERO,func(_p:Vector2)->bool:return true)
	assert_int(terrain.settlement_layout_builds).is_equal(1)
	assert_vector(next.buildings[0].position).is_equal(position)
	assert_float(next.buildings[0].plot.condition).is_equal(.1)
	assert_float(next.buildings[0].plot.damage.fire).is_equal(.8)

func test_cell_identity_is_world_fixed_and_does_not_depend_on_population()->void:
	var plot:={"id":1,"centroid":Vector2(.30,.02),"resident_count":2}
	var key:=Keys.patch_key(plot,Vector3.ZERO)
	plot.resident_count=1000000
	assert_str(Keys.patch_key(plot,Vector3.ZERO)).is_equal(key)
	assert_str(Keys.patch_key({"id":2,"centroid":Vector2(.31,.02)},Vector3.ZERO)).is_equal(key)
	assert_str(Keys.patch_key({"id":3,"centroid":Vector2(.60,.02)},Vector3.ZERO)).is_not_equal(key)

func test_pending_geometry_waits_for_new_authoritative_state_request()->void:
	GameState.reset_for_new_world(9140)
	var terrain:GuardedTerrain=auto_free(GuardedTerrain.new())
	terrain.settlement_land_use_root=Node3D.new();terrain.add_child(terrain.settlement_land_use_root)
	terrain.settlement_patches=Patches.new(terrain.settlement_land_use_root)
	var requested:Array[Dictionary]=[record("home",1)]
	terrain.settlement_patches.request(requested)
	terrain.settlement_patch_source_token=terrain._settlement_patch_state_token()
	GameState.morphology_revision+=1
	terrain._process_settlement_visual_jobs()
	assert_int(terrain.refresh_calls).is_equal(1)
	assert_int(terrain.settlement_patch_stats().builds).is_equal(0)
	assert_int(terrain.settlement_patch_stats().pending).is_equal(1)

func test_recorded_kit_and_fields_do_not_rebuild_for_another_calendar_year()->void:
	assert_int(Keys.age({"created_day":0,"land_use":"residential_compound"},365*3000,true)).is_equal(0)
	assert_int(Keys.age({"created_day":0,"land_use":"field"},365*3000,false)).is_equal(0)
	assert_int(Keys.age({"created_day":0,"land_use":"residential_compound"},365*3000,false)).is_equal(90)

func test_ground_shader_preserves_valid_founding_paint_before_frontier_tiles()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/settlement_ground.gdshaderinc").replace("\r\n","\n")
	var selection:=source.substr(source.find("int settlement_ground_slot("))
	selection=selection.substr(0,selection.find("\n}\n")+3)
	# Keep the 140 m founding texture ahead of overlapping 512 m frontier cells.
	assert_str(selection).contains("int s = index == 0 ? 0 : (index < 5 ? index+3 : index-4);")
	assert_str(selection).contains("if (sg_frames[s].y <= 0.0) { continue; }")
	assert_str(selection).contains("m.x >= pad_m && m.y >= pad_m && m.x < size_m-pad_m && m.y < size_m-pad_m")
	var shader:=Shader.new()
	shader.code="shader_type spatial;\nuniform vec4 sg_frames[8];\nuniform vec4 sg_origins[8];\n"+selection+"\nvoid fragment() { vec2 local_m; int slot = settlement_ground_slot(vec2(0.0), vec2(0.0), local_m); ALBEDO = vec3(float(slot)); }"
	assert_int(shader.get_shader_uniform_list().size()).is_equal(2)

func field(id:int,x:float)->Dictionary:
	return {"id":id,"seed":id,"centroid":Vector2(x,0),"polygon":PackedVector2Array([Vector2(x-.01,-.01),Vector2(x+.01,-.01),Vector2(x+.01,.01),Vector2(x-.01,.01)]),"area_ha":.04,"land_use":"field","status":"active","cultivation_phase":"growing","form":"worked_field","condition":.8,"created_day":0}

func test_live_plot_builder_retains_west_field_when_east_changes_crop_phase()->void:
	GameState.reset_for_new_world(9142)
	GameState.settlement_plots=[field(129,.10),field(130,.40)]
	GameState.settlement_routes=[]
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=auto_free(Camera3D.new());terrain.camera.size=.5
	terrain.settlement_land_use_root=Node3D.new();terrain.add_child(terrain.settlement_land_use_root)
	terrain.settlement_patches=Patches.new(terrain.settlement_land_use_root)
	var profile:Dictionary=terrain._settlement_expansion_visual_profile({"classification":"village","population":120})
	terrain._request_settlement_visual_patches(Vector3.ZERO,GameState.settlement_plots,GameState.settlement_routes,1,profile,{})
	while terrain.settlement_patch_stats().pending>0:terrain._process_settlement_visual_jobs()
	var west:=Keys.patch_key(GameState.settlement_plots[0],Vector3.ZERO)
	var east:=Keys.patch_key(GameState.settlement_plots[1],Vector3.ZERO)
	var before:Dictionary=terrain.settlement_patch_stats().keys
	var western_root:Node=instance_from_id(before[west].node_id)
	assert_int(western_root.get_child_count()).is_greater(0)
	GameState.settlement_plots[1].cultivation_phase="harvested"
	terrain._request_settlement_visual_patches(Vector3.ZERO,GameState.settlement_plots,GameState.settlement_routes,1,profile,{})
	assert_int(terrain.settlement_patch_stats().pending).is_equal(1)
	terrain._process_settlement_visual_jobs()
	var after:Dictionary=terrain.settlement_patch_stats().keys
	assert_int(after[west].node_id).is_equal(before[west].node_id)
	assert_int(after[east].node_id).is_not_equal(before[east].node_id)
