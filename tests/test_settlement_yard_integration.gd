extends GdUnitTestSuite
## Exercise the actual terrain adapter without generating terrain or rendering.
## The sink observes its inputs; placement/mesh behavior has separate tests.

class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

class YardSink extends Node3D:
	var requests:=0
	var processes:=0
	var sources:Array[Dictionary]=[]
	var center:=Vector2.ZERO
	var span:=0.0
	func set_view(at:Vector2,size:float)->void:
		center=at;span=size;visible=size<=.30
	func request(records:Array[Dictionary],_revision:int)->void:
		requests+=1;sources=records.duplicate(true)
	func process_jobs(_budget_usec:int,_max_houses:int)->void:processes+=1

class PatchState extends RefCounted:
	var request_serial:=1
	var builds:=1
	var retired:=0
	var installed:Dictionary={}
	var desired:Dictionary={}

class CountryState extends Node3D:
	var clearing_revision:=1
	var layers:Dictionary={}

class SeedState extends Node3D:
	var seed_ground_revision:=4
	var retained:Dictionary={"builds":1}
	var records:Array[Dictionary]=[]
	func seed_ground_records()->Array[Dictionary]:return records.duplicate(true)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(910182)
	GameState.resource_settlement_id="yard_root"
	GameState.known_discoveries.clear();GameState.discovery_log.clear()

func after_test()->void:WorldSimulation.clear()

func _fixture()->Terrain:
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;terrain.camera.size=.10
	terrain.camera_target=Vector3(14034,0,-9260)
	terrain.settlement_request_ground_center=terrain.camera_target
	terrain.settlement_yards=YardSink.new();terrain.add_child(terrain.settlement_yards)
	return terrain

func _building(id:String)->Dictionary:
	return {"id":id,"plot_id":1,"position":Vector2(.01,.02),"angle":.3,
		"plot":{"id":1,"status":"active","land_use":"residential_compound","resident_count":5}}

func _patch(terrain:Terrain,id:String)->Node3D:
	var node:=Node3D.new();terrain.add_child(node)
	node.set_meta("yard_plan",{"buildings":[_building(id)]})
	return node

func test_root_sources_use_only_installed_desired_plans_and_idle_reuses_request()->void:
	var terrain:=_fixture();var sink:YardSink=terrain.settlement_yards
	var patches:=PatchState.new();terrain.settlement_patches=patches
	patches.installed={"live":{"node":_patch(terrain,"live_home")},"cached":{"node":_patch(terrain,"hidden_home")}}
	patches.desired={"live":{},"not_built_yet":{}}
	GameState.settlement_plots.assign([{"id":1,"status":"active","resident_count":5}])
	var ledger_before:=var_to_bytes(GameState.settlement_plots)
	terrain._process_settlement_yards()
	assert_int(sink.requests).is_equal(1)
	assert_int(sink.sources.size()).is_equal(1)
	assert_str(String(sink.sources[0].id)).is_equal("root:yard_root")
	assert_vector(sink.sources[0].origin).is_equal(Vector2(14034,-9260))
	assert_int(sink.sources[0].plan.buildings.size()).is_equal(1)
	assert_str(String(sink.sources[0].plan.buildings[0].id)).is_equal("live_home")
	for frame in 120:terrain._process_settlement_yards()
	assert_int(sink.requests).is_equal(1)
	assert_int(sink.processes).is_equal(121)
	assert_array(var_to_bytes(GameState.settlement_plots)).is_equal(ledger_before)

func test_secondary_sources_refresh_shared_knowledge_without_rebuilding_or_mutating_fabric()->void:
	var terrain:=_fixture();var sink:YardSink=terrain.settlement_yards
	terrain.settlement_network_fabric_root=Node3D.new();terrain.add_child(terrain.settlement_network_fabric_root)
	var fabric:=Node3D.new();terrain.settlement_network_fabric_root.add_child(fabric)
	var stored:={"id":"city:second","origin":Vector2(14034.125,-9260),"plan":{"buildings":[_building("second_home")]},"plots":[],"routes":[],"knowledge":[]}
	fabric.set_meta("yard_source",stored)
	var before:=var_to_bytes(stored)
	GameState.known_discoveries.assign(["clay_shaping"])
	GameState.discovery_log.assign([{"id":"food_drying"}])
	terrain._process_settlement_yards()
	assert_array(sink.sources[0].knowledge).contains(["clay_shaping","food_drying"])
	GameState.known_discoveries.append("fish_weirs_and_traps")
	terrain._process_settlement_yards()
	assert_int(sink.requests).is_equal(2)
	assert_array(sink.sources[0].knowledge).contains(["clay_shaping","food_drying","fish_weirs_and_traps"])
	assert_int(terrain.settlement_yard_fabric_revision).is_zero()
	assert_array(var_to_bytes(fabric.get_meta("yard_source"))).is_equal(before)

func test_country_replacement_refreshes_sources_even_when_geometry_revision_is_unchanged()->void:
	var terrain:=_fixture();var sink:YardSink=terrain.settlement_yards
	var country:=CountryState.new();terrain.add_child(country);terrain.country_land=country
	var seed:=SeedState.new();country.add_child(seed)
	seed.records=[{"id":"seed:1","origin":Vector2(14034,-9260),"plots":[],"routes":[],"plan":{"buildings":[_building("first")]}}]
	country.layers={"rival":{"node":seed,"snapshot":{"knowledge":["food_drying"]}}}
	terrain._process_settlement_yards()
	assert_int(sink.requests).is_equal(1)
	assert_str(String(sink.sources[0].id)).is_equal("country:rival:seed:1")
	assert_bool(bool(sink.sources[0].representative_occupied)).is_true()
	assert_array(sink.sources[0].knowledge).is_equal(["food_drying"])
	# A fog-clipped replacement can install more roofs at identical parcel geometry.
	seed.records[0].plan.buildings.append(_building("newly_revealed"))
	seed.retained.builds=2
	terrain._process_settlement_yards()
	assert_int(seed.seed_ground_revision).is_equal(4)
	assert_int(sink.requests).is_equal(2)
	assert_int(sink.sources[0].plan.buildings.size()).is_equal(2)
	assert_str(String(seed.records[0].id)).is_equal("seed:1")
	assert_bool(seed.records[0].has("representative_occupied")).is_false()

func test_distant_view_hides_existing_yards_without_request_or_processing()->void:
	var terrain:=_fixture();var sink:YardSink=terrain.settlement_yards
	terrain.camera.size=.301
	terrain._process_settlement_yards()
	assert_bool(sink.visible).is_false()
	assert_int(sink.requests).is_zero();assert_int(sink.processes).is_zero()
	terrain.camera.size=.10
	terrain._process_settlement_yards()
	assert_bool(sink.visible).is_true();assert_int(sink.requests).is_equal(1)
	var process_count:=sink.processes
	terrain.camera.size=20.0
	GameState.known_discoveries.append("food_drying")
	for frame in 30:terrain._process_settlement_yards()
	assert_bool(sink.visible).is_false()
	assert_int(sink.requests).is_equal(1);assert_int(sink.processes).is_equal(process_count)
