extends GdUnitTestSuite
class FogTerrain extends "res://scripts/local_terrain.gd":
	var discs:=0
	var segments:=0
	func _paint_discovery_disc(_image:Image,_center:Vector2,_radius:float,_width:int,_height:int)->void:discs+=1
	func _paint_discovery_segment(_image:Image,_a:Vector2,_b:Vector2,_radius:float,_width:int,_height:int)->void:segments+=1
class CountedSettlement extends "res://scripts/settlement_model.gd":
	var queries:=0
	func _completed_work_materials(work_name:String)->Dictionary:
		queries+=1
		return super._completed_work_materials(work_name)
var previous_processing:=false
func before_test()->void:
	previous_processing=CivilizationSystem.is_processing()
	CivilizationSystem.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(765)
	CivilizationSystem.revealed_areas.clear()
	CivilizationSystem.fog_revision=10
func after_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(765)
	CivilizationSystem.initialize()
	CivilizationSystem.set_process(previous_processing)
func test_unchanged_fog_skips_history_but_updates_origin_and_prunes_dead_materials()->void:
	var terrain:FogTerrain=auto_free(FogTerrain.new())
	var shader:=Shader.new()
	shader.code="shader_type spatial; uniform vec2 fog_current_origin; uniform sampler2D discovery_mask;"
	var material:=ShaderMaterial.new();material.shader=shader
	terrain.terrain_fog_materials.append(material)
	terrain.vegetation_fog_materials.append(weakref(material))
	var expired:=RefCounted.new();terrain.vegetation_fog_materials.append(weakref(expired));expired=null
	terrain.rendered_fog_revision=10
	CivilizationSystem.player_world_origin=Vector2(3,7)
	# If unchanged history is touched this valid-shaped trail would be painted.
	CivilizationSystem.revealed_areas.append({"kind":"circle","x":1.0,"z":1.0,"radius":3.0})
	terrain._refresh_discovery_mask()
	assert_int(terrain.discs).is_equal(0)
	assert_int(terrain.vegetation_fog_materials.size()).is_equal(1)
	assert_vector(material.get_shader_parameter("fog_current_origin")).is_equal(Vector2(3,7))
	CivilizationSystem.player_world_origin=Vector2(5,9)
	terrain._refresh_discovery_mask()
	assert_vector(material.get_shader_parameter("fog_current_origin")).is_equal(Vector2(5,9))
func test_revision_and_force_still_repaint_circles_and_returned_trails()->void:
	var terrain:FogTerrain=auto_free(FogTerrain.new())
	CivilizationSystem.revealed_areas.assign([
		{"kind":"circle","x":1.0,"z":2.0,"radius":3.0},
		{"kind":"trail","radius":2.0,"points":[{"x":1.0,"z":2.0},{"x":2.0,"z":3.0},{"x":4.0,"z":6.0}]}
	])
	terrain._refresh_discovery_mask()
	assert_int(terrain.discs).is_equal(1);assert_int(terrain.segments).is_equal(2)
	assert_int(terrain.rendered_fog_revision).is_equal(10)
	terrain._refresh_discovery_mask()
	assert_int(terrain.discs).is_equal(1)
	CivilizationSystem.fog_revision+=1
	terrain._refresh_discovery_mask()
	assert_int(terrain.discs).is_equal(2);assert_int(terrain.segments).is_equal(4)
	terrain._refresh_discovery_mask(true)
	assert_int(terrain.discs).is_equal(3);assert_int(terrain.segments).is_equal(6)
func test_completed_conversions_do_not_read_permanent_building_history()->void:
	var model:CountedSettlement=auto_free(CountedSettlement.new())
	GameState.settlement_completed=["Lean-to Shelters","Framed Hall"]
	GameState.settlement_plots=[{"id":1,"land_use":"residential_compound","form":"lean_to_household_cluster"},{"id":2,"land_use":"communal","form":"timber_frame_hall"}]
	GameState.building_ledger=[{"kind":"historic monument","counts_materials":true}]
	var events:Array[Dictionary]=[]
	model._synchronize_early_works(1000,events)
	assert_int(model.queries).is_equal(0)
	assert_int(GameState.building_ledger.size()).is_equal(1)
	assert_array(events).is_empty()
func test_needed_conversions_keep_original_materials_and_read_once_per_work()->void:
	var model:CountedSettlement=auto_free(CountedSettlement.new())
	GameState.settlement_completed=["Lean-to Shelters","Framed Hall"]
	GameState.resource_settlement_id="home"
	GameState.building_ledger=[{"kind":"Lean-to Shelters","counts_materials":true,"settlement_id":"other","materials":{"Clay":2.0}},{"kind":"Lean-to Shelters","counts_materials":true,"settlement_id":"home","materials":{"Timber":8.0}},{"kind":"Framed Hall","counts_materials":true,"settlement_id":"home","materials":{"Timber":10.0}}]
	GameState.settlement_plots=[{"id":1,"land_use":"residential_compound","form":"portable_shelter_cluster"},{"id":2,"land_use":"residential_compound","form":"light_shelter_cluster"},{"id":3,"land_use":"communal","form":"open_hearth_yard"}]
	var events:Array[Dictionary]=[]
	model._synchronize_early_works(1000,events)
	assert_int(model.queries).is_equal(2)
	assert_array(events).has_size(3)
	assert_str(GameState.settlement_plots[0].form).is_equal("lean_to_household_cluster")
	assert_str(GameState.settlement_plots[1].form).is_equal("lean_to_household_cluster")
	assert_str(GameState.settlement_plots[2].form).is_equal("timber_frame_hall")
	assert_dict(GameState.settlement_plots[0].material_mix).is_equal(preload("res://scripts/construction_materials.gd").mix_for({"Timber":8.0}))
	model._synchronize_early_works(1001,events)
	assert_int(model.queries).is_equal(2)
