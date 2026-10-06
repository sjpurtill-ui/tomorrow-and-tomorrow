extends GdUnitTestSuite
const Layer=preload("res://scripts/settlement_country_layer.gd")
var _civilization_was_processing:=false

class FakeTerrain extends Node3D:
	var camera:Camera3D
	var river_terrain_grid:=Vector4(20,20,160,64)
	var detail_surface_center:=Vector2(20,20)
	var detail_terrain_patch:Node3D
	var moving:=false
	var revealed:=true
	var rejected_land:Array[Vector2]=[]
	func _harvest_ground_height_at(_point:Vector2)->float:return 0.1
	func _settlement_stage_land_at(point:Vector2)->bool:return point not in rejected_land
	func _world_position_is_revealed(_point:Vector3)->bool:return revealed
	func _camera_in_motion()->bool:return moving

func before()->void:
	_civilization_was_processing=CivilizationSystem.is_processing()
	CivilizationSystem.set_process(false)

func after()->void:
	GameState.reset_for_new_world(91733)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.set_process(_civilization_was_processing)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(91733)
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.city_intelligence.records.clear()
	_seed_state(GameState,Vector2(20,20))

func after_test()->void:
	WorldSimulation.clear()

func _seed_state(state:Object,at:Vector2)->void:
	state.population_exact=1000.0;state.population_total=1000
	state.settlement_site_committed=true;state.settlement_founded_at=Vector3(at.x,0,at.y)
	state.player_settlements.assign([{"id":"home","primary":true,"position":at}])
	state.known_discoveries.assign(["joinery"])
	state.resource_deposits.assign([{"id":"wood","resource":"Timber","landscape_source":"woodland_catchment","position":Vector3(at.x+3,0,at.y),"stage":"accessible","remaining":50.0,"initial_amount":100.0,"workers":2,"lifetime_extracted":50.0}])
	state.built_fabric={"v":1,"homes":[0.0,1.0,0.0,0.0,0.0],"effects":{"roads":0.1}}
	state.fabric_realm={}

func _fixture()->Dictionary:
	var terrain:FakeTerrain=auto_free(FakeTerrain.new());add_child(terrain)
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.position=Vector3(20,60,20);terrain.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;terrain.camera.size=160.0
	var layer:=Layer.new();terrain.add_child(layer)
	return {"terrain":terrain,"layer":layer}

func _rival(id:String,at:Vector2,reported:bool=true,demographics:bool=true,ledger:bool=true)->void:
	var city_id:=id+"_capital"
	CivilizationSystem.civilizations.append({"id":id,"population":1000.0,"world_reach":0.0,"strategic_regions":[{"id":city_id,"role":"capital","position":at,"controller":id,"settlement_founded":true}]})
	if ledger:
		var state:Object=GameState.get_script().new()
		state.world_seed=91733;_seed_state(state,at)
		# A minimal independent state is sufficient for pure ring/land readers;
		# none of the daily simulation systems are invoked by this test.
		WorldSimulation.actors[id]={"systems":{"GameState":state},"origin":at,"last_day":0}
	if reported:
		if not CivilizationSystem.city_intelligence.records.has("player"):CivilizationSystem.city_intelligence.records["player"]={}
		CivilizationSystem.city_intelligence.records.player[city_id]={"city_id":city_id,"civ_id":id,"controller":id,"name":id,"position":{"x":at.x,"z":at.y},"observed_day":3,"fields":{"population":{"low":900,"high":1100}} if demographics else {}}

func _builds(layer:Node3D)->int:
	var total:=0
	for entry:Dictionary in layer.layers.values():total+=int(entry.node.retained.builds)
	return total

func test_unchanged_refresh_reuses_owner_and_never_changes_engine_state()->void:
	var f:=_fixture()
	var before:Dictionary={"people":GameState.population_exact,"deposits":GameState.resource_deposits.duplicate(true),"fabric":GameState.built_fabric.duplicate(true),"realm":GameState.fabric_realm.duplicate(true),"towns":GameState.player_settlements.duplicate(true)}
	f.layer.refresh(f.terrain)
	assert_int(f.layer.layers.size()).is_equal(1)
	var node:Node3D=f.layer.layers.player.node
	var captures:=int(f.layer.captures)
	# The main clock advances fractionally every frame; only its completed
	# integer day should trigger a new factual deposit scan.
	GameState.elapsed_days+=0.25
	for i in 40:f.layer.refresh(f.terrain)
	assert_int(f.layer.captures).is_equal(captures)
	assert_bool(f.layer.layers.player.node==node).is_true()
	assert_float(GameState.population_exact).is_equal(float(before.people))
	assert_array(GameState.resource_deposits).is_equal(before.deposits)
	assert_dict(GameState.built_fabric).is_equal(before.fabric)
	assert_dict(GameState.fabric_realm).is_equal(before.realm)
	assert_array(GameState.player_settlements).is_equal(before.towns)

func test_camera_motion_defers_new_drape_and_fog_keeps_unchanged_patch_signatures()->void:
	var f:=_fixture();f.layer.refresh(f.terrain)
	var node:Node3D=f.layer.layers.player.node
	var before:Dictionary=node.retained.desired.duplicate()
	var captures:=int(f.layer.captures)
	CivilizationSystem.fog_revision+=1;f.layer.refresh(f.terrain)
	assert_int(f.layer.captures).is_equal(captures)
	for key:String in before:
		assert_int(node.retained.desired[key].signature).is_equal(int(before[key].signature))
	f.terrain.moving=true;f.terrain.river_terrain_grid=Vector4(30,30,180,64)
	var refreshes:=int(f.layer.refreshes)
	f.layer.refresh(f.terrain)
	assert_int(f.layer.refreshes).is_equal(refreshes)
	f.terrain.moving=false;f.layer.refresh(f.terrain)
	assert_int(f.layer.refreshes).is_equal(refreshes+1)
	assert_int(f.layer.captures).is_equal(captures)
	assert_bool(node.retained.desired.values()[0].signature!=before.values()[0].signature).is_true()

func test_only_known_identified_people_with_estimate_and_real_ledger_are_admitted()->void:
	_rival("unreported",Vector2(25,20),false)
	_rival("location_only",Vector2(30,20),true,false)
	_rival("legacy",Vector2(35,20),true,true,false)
	_rival("known",Vector2(40,20))
	var f:=_fixture();f.layer.refresh(f.terrain)
	assert_int(f.layer.layers.size()).is_equal(2)
	assert_bool(f.layer.layers.has("known")).is_true()
	assert_float(float(f.layer.layers.known.snapshot.population)).is_equal(1000.0)
	assert_float(float(f.layer.layers.known.snapshot.worked_km)).is_equal(float(f.layer.layers.known.snapshot.core_km))
	assert_array(f.layer.woodland_ledgers()).has_size(1)
	assert_array(f.layer.woodland_ledgers()[0]).is_equal(WorldSimulation.actors.known.systems.GameState.resource_deposits)
	assert_str(WorldSimulation.actor_id).is_equal("player")
	assert_bool(WorldSimulation.state==GameState).is_true()

func test_owner_count_and_frame_build_budget_remain_bounded()->void:
	for i in 12:_rival("people_%02d" % i,Vector2(24+i*3,20))
	var f:=_fixture();f.layer.refresh(f.terrain)
	assert_int(f.layer.layers.size()).is_equal(Layer.MAX_PEOPLES)
	var previous:=_builds(f.layer)
	f.layer.process_jobs(1000000,2)
	assert_int(_builds(f.layer)-previous).is_less_equal(2)
	assert_bool(f.layer.layers.has("people_11")).is_false()
	# No population-sized node count, and a following identical view keeps
	# every retained owner instead of recapturing all of its deposit records.
	var captures:=int(f.layer.captures);f.layer.refresh(f.terrain)
	assert_int(f.layer.captures).is_equal(captures)

func test_canopy_clearings_are_nearest_bounded_fields_without_ledger_edits()->void:
	var f:=_fixture()
	f.layer.terrain=f.terrain
	var first:=preload("res://scripts/settlement_country_visual.gd").new()
	var second:=preload("res://scripts/settlement_country_visual.gd").new()
	f.layer.add_child(first);f.layer.add_child(second)
	first.plan={"homesteads":[
		{"position":Vector2(9,0),"field_radius_km":0.2},
		{"position":Vector2(1,0),"field_radius_km":0.3},
		{"position":Vector2(5,0),"field_radius_km":0.4}],
		"herders":[{"position":Vector2(0.1,0),"field_radius_km":0.2}],
		"sites":[{"position":Vector2.ZERO,"field_radius_km":0.7}]}
	second.plan={"homesteads":[
		{"position":Vector2(3,0),"field_radius_km":0.2},
		{"position":Vector2(7,0),"field_radius_km":0.3}],"herders":[],"sites":[]}
	f.layer.layers={"player":{"node":first},"known":{"node":second}}
	var first_before:=first.plan.duplicate(true)
	var second_before:=second.plan.duplicate(true)
	var deposits_before:=GameState.resource_deposits.duplicate(true)
	var people_before:=GameState.population_exact
	var clearings:PackedVector4Array=f.layer.canopy_clearings(Vector2.ZERO,3)
	assert_int(clearings.size()).is_equal(3)
	assert_float(clearings[0].x).is_equal(1.0)
	assert_float(clearings[1].x).is_equal(3.0)
	assert_float(clearings[2].x).is_equal(5.0)
	assert_float(clearings[0].z).is_equal_approx(0.36,0.00001)
	# A rejected nearer candidate must not consume an admission slot or cut
	# canopy where its representative home cannot actually stand.
	f.terrain.rejected_land.append(Vector2(1,0))
	clearings=f.layer.canopy_clearings(Vector2.ZERO,3)
	assert_int(clearings.size()).is_equal(3)
	assert_float(clearings[0].x).is_equal(3.0)
	assert_float(clearings[1].x).is_equal(5.0)
	assert_float(clearings[2].x).is_equal(7.0)
	f.terrain.revealed=false
	assert_int(f.layer.canopy_clearings(Vector2.ZERO,3).size()).is_equal(0)
	assert_int(f.layer.canopy_clearings(Vector2.ZERO,0).size()).is_equal(0)
	assert_dict(first.plan).is_equal(first_before)
	assert_dict(second.plan).is_equal(second_before)
	assert_array(GameState.resource_deposits).is_equal(deposits_before)
	assert_float(GameState.population_exact).is_equal(people_before)
