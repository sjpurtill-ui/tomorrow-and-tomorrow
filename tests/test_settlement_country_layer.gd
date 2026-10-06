extends GdUnitTestSuite
const Layer=preload("res://scripts/settlement_country_layer.gd")
const Plan=preload("res://scripts/settlement_country_plan.gd")
const Woodland=preload("res://scripts/landscape_resource_visuals.gd")
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
	assert_vector(node.view_center).is_equal(Vector2(20,20))
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
		{"id":"far","position":Vector2(9,0),"field_radius_km":0.12},
		{"id":"near","position":Vector2(1,0),"field_radius_km":0.14},
		{"id":"middle","position":Vector2(5,0),"field_radius_km":0.16}],
		"herders":[{"id":"grazer","kind":"herder","position":Vector2(0.1,0),"field_radius_km":0.07,"rotation":0.0}],
		"sites":[{"position":Vector2.ZERO,"field_radius_km":0.7}]}
	second.plan={"homesteads":[
		{"id":"rival_near","position":Vector2(3,0),"field_radius_km":0.12},
		{"id":"rival_far","position":Vector2(7,0),"field_radius_km":0.14}],"herders":[],"sites":[]}
	f.layer.layers={"player":{"node":first},"known":{"node":second}}
	var first_before:=first.plan.duplicate(true)
	var second_before:=second.plan.duplicate(true)
	var deposits_before:=GameState.resource_deposits.duplicate(true)
	var people_before:=GameState.population_exact
	var all_clearings:PackedVector4Array=f.layer.canopy_clearings(Vector2.ZERO,128)
	# Each farm has a yard and three clearing cells for each of four plots;
	# the herder has a yard and three cells for its one plot.
	# The real site remains the responsibility of the real woodland ledger.
	assert_int(all_clearings.size()).is_equal(69)
	assert_int(f.layer.canopy_clearings(Vector2.ZERO).size()).is_equal(16)
	var previous_distance:=-1.0
	for clearing:Vector4 in all_clearings:
		var point:=Vector2(clearing.x,clearing.y)
		assert_bool(point!=Vector2.ZERO).is_true()
		assert_float(point.length_squared()).is_greater_equal(previous_distance)
		previous_distance=point.length_squared()
		assert_float(clearing.z).is_less(0.065)
		var matching_footprint:=false
		for source:Dictionary in [first.plan,second.plan]:
			for group:String in ["homesteads","herders"]:
				for home:Dictionary in source.get(group,[]):
					var layout:=Plan.homestead_layout(home)
					if point==layout.yard_center:
						matching_footprint=true
						assert_float(clearing.z).is_equal_approx(float(layout.yard_radius_km),0.000001)
						assert_float(clearing.w).is_equal_approx(0.01,0.000001)
					for field:Dictionary in layout.fields:
						var along:=Vector2.from_angle(float(field.angle))
						for cell in 3:
							var expected:Vector2=field.center+along*float(field.half_length_km)/3.0*float((cell-1)*2)
							if point.is_equal_approx(expected):
								matching_footprint=true
								assert_float(clearing.w).is_equal(0.0)
		assert_bool(matching_footprint).is_true()
	var clearings:PackedVector4Array=f.layer.canopy_clearings(Vector2.ZERO,3)
	assert_int(clearings.size()).is_equal(3)
	for index in 3:assert_vector(clearings[index]).is_equal(all_clearings[index])
	# The grazer's plot is second, after its yard. Rejecting this one field
	# must leave the valid yard, then fill the budget with the next candidates.
	f.terrain.rejected_land.append(Vector2(all_clearings[1].x,all_clearings[1].y))
	clearings=f.layer.canopy_clearings(Vector2.ZERO,3)
	assert_int(clearings.size()).is_equal(3)
	assert_vector(clearings[0]).is_equal(all_clearings[0])
	assert_vector(clearings[1]).is_equal(all_clearings[2])
	assert_vector(clearings[2]).is_equal(all_clearings[3])
	# A whole rejected household must not leave orphan clearings around it.
	f.terrain.rejected_land.append(Vector2(0.1,0))
	clearings=f.layer.canopy_clearings(Vector2.ZERO,3)
	assert_int(clearings.size()).is_equal(3)
	for clearing:Vector4 in clearings:assert_float(Vector2(clearing.x,clearing.y).length()).is_greater(0.8)
	f.terrain.revealed=false
	assert_int(f.layer.canopy_clearings(Vector2.ZERO,3).size()).is_equal(0)
	assert_int(f.layer.canopy_clearings(Vector2.ZERO,0).size()).is_equal(0)
	assert_dict(first.plan).is_equal(first_before)
	assert_dict(second.plan).is_equal(second_before)
	assert_array(GameState.resource_deposits).is_equal(deposits_before)
	assert_float(GameState.population_exact).is_equal(people_before)

func test_cached_clearings_follow_plan_revisions_and_owner_removal()->void:
	var f:=_fixture();f.layer.terrain=f.terrain
	var visual:=preload("res://scripts/settlement_country_visual.gd").new();f.layer.add_child(visual)
	visual.plan={"homesteads":[{"id":"home","position":Vector2(1,0),"field_radius_km":0.12}],"herders":[],"sites":[]}
	f.layer.layers={"player":{"node":visual}}
	var first:PackedVector4Array=f.layer.canopy_clearings(Vector2.ZERO)
	assert_int(first.size()).is_equal(13)
	assert_bool(first==f.layer.canopy_clearings(Vector2.ZERO)).is_true()
	visual.plan.homesteads[0].position=Vector2(3,0);f.layer.clearing_revision+=1
	var changed:PackedVector4Array=f.layer.canopy_clearings(Vector2.ZERO)
	assert_bool(changed!=first).is_true()
	for clearing:Vector4 in changed:assert_float(clearing.x).is_greater(2.8)
	f.layer.layers.clear();f.layer.clearing_revision+=1
	assert_int(f.layer.canopy_clearings(Vector2.ZERO).size()).is_equal(0)

func test_all_rotated_plot_ends_and_corners_fit_inside_clear_canopy()->void:
	var f:=_fixture();f.layer.terrain=f.terrain
	var visual:=preload("res://scripts/settlement_country_visual.gd").new();f.layer.add_child(visual)
	f.layer.layers={"player":{"node":visual}}
	for index in 40:
		var home:={"id":"covered_%d" % index,"position":Vector2(14034,-2892),"field_radius_km":lerpf(0.10,0.18,float(index)/39.0)}
		visual.plan={"homesteads":[home],"herders":[],"sites":[]};f.layer.clearing_revision+=1
		var masks:PackedVector4Array=f.layer.canopy_clearings(home.position)
		assert_int(masks.size()).is_equal(13)
		for field:Dictionary in Plan.homestead_layout(home).fields:
			var along:=Vector2.from_angle(float(field.angle));var across:=along.orthogonal()
			for x in range(-5,6):
				for y in range(-3,4):
					var point:Vector2=field.center+along*float(field.half_length_km)*float(x)/5.0+across*float(field.half_width_km)*float(y)/3.0
					assert_float(Woodland.retained_at(point,masks)).is_less_equal(0.001)
