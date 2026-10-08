extends GdUnitTestSuite
## Named places remain copied facts of one owner and one ledger.
const Plan:=preload("res://scripts/settlement_country_plan.gd")
const Places:=preload("res://scripts/settlement_places.gd")
const Growth:=preload("res://scripts/settlement_country_growth.gd")
const Layer:=preload("res://scripts/settlement_country_layer.gd")
const HOME:=Vector2(14,-9)
var _processing:Dictionary={}

class FakeTerrain extends Node3D:
	var camera:Camera3D
	var river_terrain_grid:=Vector4(14,-9,160,64)
	var detail_surface_center:=HOME
	var detail_terrain_patch:Node3D
	func _harvest_ground_height_at(_point:Vector2)->float:return 0.1
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _world_position_is_revealed(_point:Vector3)->bool:return true
	func _camera_in_motion()->bool:return false

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:
		_processing[node]=node.is_processing();node.set_process(false)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(91733)
	CivilizationSystem.reset_for_new_world()
	_seed_state(GameState,HOME)

func after_test()->void:
	WorldSimulation.clear()

func after()->void:
	GameState.reset_for_new_world(91733)
	CivilizationSystem.reset_for_new_world()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func _place(id:String="shore",kind:String="coast",people:int=12)->Dictionary:
	return {"id":id,"name":"Keth Shore","position":HOME+Vector2(24.15,3.7),"kind":kind,"status":"living",
		"people":people,"share":0.03,"trend":1,"age_days":0,"founded_day":30,"left_day":-1,"flooded":false,
		"shoreline":0.9,"open_water":0.8,"facing":Vector2.RIGHT if kind!="inland" else Vector2.ZERO}

func _snapshot(places:Array,people:float=1000.0)->Dictionary:
	return {"owner":"player","origin":HOME,"population":people,"core_km":2.0,"worked_km":8.0,"realm_km":100.0,
		"seed":91733,"founded":true,"knowledge":[],"built_fabric":{},"road_tier":1,"deposits":[],
		"root_fabric":{"claims":[],"templates":[{"form":"roundhouse","roof_plan":"conical","material_family":"organic","storeys":1}]},
		"places_view":{"owner":"player","seat_position":HOME,"seat_people":970,"revision":1,"places":places}}

func _named(plan:Dictionary)->Array:
	return (plan.homesteads as Array).filter(func(record:Dictionary)->bool:return record.has("place"))

func _seed_state(state:Object,origin:Vector2)->void:
	state.world_seed=91733;state.population_exact=1000.0;state.population_total=1000
	state.elapsed_days=30.0;state.settlement_site_committed=true
	state.settlement_founded_at=Vector3(origin.x,0,origin.y)
	state.player_settlements.assign([{"id":"home","primary":true,"position":origin,"places":[]}])
	state.settlement_plots.clear();state.resource_deposits.clear();state.known_discoveries.clear()

func _record(id:String="shore",kind:String="coast")->Dictionary:
	var place:=_place(id,kind)
	place.erase("people");place.erase("trend");place.erase("age_days");place.erase("flooded")
	place["target"]=0.05;place["setback_until"]=70
	return place

func test_all_place_kinds_anchor_exactly_outside_the_worked_radius()->void:
	var source:Array=[]
	for index in 4:
		var place:=_place(str(index),["coast","lake","river","inland"][index])
		place.position+=Vector2(0,index*8);source.append(place)
	var data:=_snapshot(source)
	var named:=_named(Plan.build(data))
	assert_int(named.size()).is_equal(4)
	for index in 4:
		var record:Dictionary=named[index]
		assert_str(record.id).is_equal("place:"+String(source[index].id))
		assert_str(record.kind).is_equal("cluster")
		assert_str(record.group).is_equal("homesteads")
		assert_vector(record.position).is_equal(source[index].position)
		assert_vector(record.track_from).is_equal(HOME)
		assert_vector(record.settlement_growth.facing).is_equal(source[index].facing)
		assert_int(record.road_tier).is_equal(1)
		assert_str(record.place.kind).is_equal(source[index].kind)
	# A report's country centre never substitutes for the scoped actual seat
	# at the start of a named place's track.
	data.origin=HOME+Vector2(1,0)
	assert_vector(_named(Plan.build(data))[0].track_from).is_equal(HOME)

func test_founders_and_mature_places_use_bounded_completed_root_parcels()->void:
	var source:=_place()
	var data:=_snapshot([source])
	var early:Dictionary=_named(Plan.build(data))[0]
	assert_int(early.settlement_growth.parcels).is_between(2,6)
	assert_array(early.settlement_growth.templates).is_equal(data.root_fabric.templates)
	source.people=2000000000
	var mature:Dictionary=_named(Plan.build(data))[0]
	assert_int(mature.settlement_growth.parcels).is_equal(Growth.MAX_PARCELS)
	assert_int(mature.settlement_growth.seed).is_equal(early.settlement_growth.seed)
	assert_vector(mature.position).is_equal(early.position)

func test_named_living_and_ruin_caps_share_one_seed_budget_with_fringe()->void:
	var source:Array=[]
	for index in 30:
		var place:=_place(str(index))
		place.position+=Vector2(0,index*6)
		if index>=18:place.status="ruin";place.people=0;place.left_day=40
		source.append(place)
	var plan:=Plan.build(_snapshot(source,1000000.0))
	var named:=_named(plan)
	assert_int(named.size()).is_equal(Places.MAX_PLACES+Places.MAX_RUINS)
	assert_int(named.filter(func(record:Dictionary)->bool:return record.place.status=="living").size()).is_equal(12)
	assert_int(named.filter(func(record:Dictionary)->bool:return record.place.status=="ruin").size()).is_equal(4)
	var seeds:=(plan.homesteads as Array).filter(func(record:Dictionary)->bool:return record.has("settlement_growth"))
	assert_int(seeds.size()).is_equal(Growth.MAX_SEEDS)
	assert_bool(plan.homesteads[0].has("place")).is_true()

func test_a_ruin_remains_when_realm_population_falls_below_admission()->void:
	var place:=_place();place.status="ruin";place.people=0;place.left_day=700;place.age_days=800
	var data:=_snapshot([place],0.0)
	var named:=_named(Plan.build(data))
	assert_int(named.size()).is_equal(1)
	assert_int(named[0].settlement_growth.parcels).is_equal(6)
	assert_int(named[0].place.day).is_equal(830)
	data.places_view.places=[];data.places_view.revision=2
	assert_int(_named(Plan.build(data)).size()).is_equal(0)

func test_plan_copies_place_metadata_and_completed_templates_without_writes()->void:
	var place:=_place();place.trend=-1;place.flooded=true
	var data:=_snapshot([place]);var before:=data.duplicate(true)
	var plan:=Plan.build(data);var record:Dictionary=_named(plan)[0]
	assert_dict(data).is_equal(before)
	assert_int(record.place.trend).is_equal(-1)
	assert_bool(record.place.flooded).is_true()
	record.place.name="edited drawing";record.place.people=999
	record.settlement_growth.templates[0].form="invented"
	assert_dict(data).is_equal(before)

func test_signature_changes_only_at_relevant_place_buckets_and_state()->void:
	var place:=_place("shore","coast",1000);place.age_days=20
	var data:=_snapshot([place]);var initial:=Plan.signature(data)
	place.people=1001;place.age_days+=1;place.share+=0.0001
	assert_int(Plan.signature(data)).is_equal(initial)
	place.people=1300
	assert_int(Plan.signature(data)).is_not_equal(initial)
	place.people=1000;place.flooded=true
	assert_int(Plan.signature(data)).is_not_equal(initial)
	place.flooded=false;place.trend=-1
	assert_int(Plan.signature(data)).is_not_equal(initial)
	place.trend=1;data.places_view.revision=2
	assert_int(Plan.quick_signature(data)).is_not_equal(Plan.quick_signature(_snapshot([place])))

func test_ruin_fade_uses_year_buckets_and_living_age_does_not_rebuild()->void:
	var place:=_place();place.status="ruin";place.left_day=10;place.founded_day=0;place.age_days=10
	var data:=_snapshot([place]);var initial:=Plan.signature(data)
	place.age_days=374
	assert_int(Plan.signature(data)).is_equal(initial)
	place.age_days=375
	assert_int(Plan.signature(data)).is_not_equal(initial)
	place.status="living";initial=Plan.signature(data);place.age_days+=36500
	assert_int(Plan.signature(data)).is_equal(initial)

func test_capture_reads_the_scoped_one_ledger_without_mutating_it()->void:
	GameState.player_settlements[0].places=[_record()]
	var before:=GameState.player_settlements.duplicate(true)
	var snapshot:=Plan.capture_current({"center":HOME,"reach":80.0})
	assert_str(snapshot.places_view.owner).is_equal("player")
	assert_int(snapshot.places_view.places[0].people).is_equal(30)
	assert_bool(snapshot.places_view.places[0].flooded).is_true()
	snapshot.places_view.places[0].name="copied only"
	assert_array(GameState.player_settlements).is_equal(before)
	assert_int(GameState.player_settlements.size()).is_equal(1)
	assert_float(GameState.population_exact).is_equal(1000.0)

func test_rival_capture_uses_its_owner_places_and_restores_player_scope()->void:
	GameState.player_settlements[0].places=[_record("ours")]
	var rival:Object=GameState.get_script().new();_seed_state(rival,HOME+Vector2(80,0))
	var record:=_record("theirs","lake");record.position+=Vector2(80,0)
	rival.player_settlements[0].places=[record]
	WorldSimulation.actors["rival"]={"systems":{"GameState":rival},"origin":HOME+Vector2(80,0),"last_day":30}
	var snapshot:Dictionary=WorldSimulation.scoped("rival",func()->Dictionary:return Plan.capture_current({"center":HOME+Vector2(80,0),"reach":80.0}))
	assert_str(snapshot.places_view.owner).is_equal("rival")
	assert_str(snapshot.places_view.places[0].id).is_equal("theirs")
	assert_vector(_named(Plan.build(snapshot))[0].position).is_equal(record.position)
	assert_str(WorldSimulation.actor_id).is_equal("player")
	assert_str(GameState.player_settlements[0].places[0].id).is_equal("ours")
	snapshot.places_view.owner="player"
	assert_int(_named(Plan.build(snapshot)).size()).is_equal(0)

func test_country_layer_refreshes_paused_founding_and_defers_fractional_day_changes()->void:
	var terrain:FakeTerrain=auto_free(FakeTerrain.new());add_child(terrain)
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.position=Vector3(HOME.x,60,HOME.y);terrain.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;terrain.camera.size=160
	var layer:=Layer.new();terrain.add_child(layer);layer.refresh(terrain)
	var captures:=layer.captures
	GameState.player_settlements[0].places=[_record()];GameState.settlement_network_revision+=1
	layer.refresh(terrain)
	assert_int(layer.captures).is_equal(captures+1)
	assert_int(_named(layer.layers.player.node.plan).size()).is_equal(1)
	captures=layer.captures
	GameState.elapsed_days+=0.25
	for index in 20:layer.refresh(terrain)
	assert_int(layer.captures).is_equal(captures)
	GameState.elapsed_days+=1.0;GameState.player_settlements[0].places[0].share=0.05
	layer.refresh(terrain)
	assert_int(layer.captures).is_equal(captures+1)
	assert_int(layer.layers.player.snapshot.places_view.places[0].people).is_equal(50)
