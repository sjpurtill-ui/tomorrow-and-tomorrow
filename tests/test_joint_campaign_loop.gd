extends GdUnitTestSuite
const C=preload("res://scripts/joint_force_catalog.gd")
const G=preload("res://scripts/joint_geography.gd")
var op:RefCounted
var port:int
var airfield:int
func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(20000)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.player_settlements[0].position=Vector2(0,1)
	GameState.player_settlements.append({"id":"second","name":"Harbor Two","position":Vector2(40,1),"primary":false,"population_share":.2,"founded_day":20})
	for definition:Dictionary in DiscoverySystem.catalog:
		var id:=String(definition.id)
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	for id:String in C.UNITS:
		var gate:=String(C.UNITS[id].gate)
		if gate not in GameState.known_discoveries:GameState.known_discoveries.append(gate)
		GameState.discovery_adoption[gate]=1.0
		MilitaryCampaign.military_inventory[C.UNITS[id].equipment]=100
	for resource:String in ["Timber","Stone","Iron Ore","Fiber Plants","Copper Ore","Graphite","Bitumen"]:GameState.resource_stockpiles[resource]=1000000.0
	GameState.food_stocks={"Preserved food":10000.0}
	GameState.population_allocations["Construction"]=100
	MilitaryCampaign.military_consumables.fuel=1000000
	op=MilitaryCampaign.joint_operations
	op.geography.land_query=func(point:Vector2)->bool:return point.y>=0
	var home:=String(GameState.player_settlements[0].id)
	assert_bool(op.build_base(home,"navy").has("ok")).is_true();port=int(op.state.bases.back().id);op.base(port).construction_work=30.0
	assert_bool(op.build_base(home,"air").has("ok")).is_true();airfield=int(op.state.bases.back().id);op.base(airfield).construction_work=30.0

func _ready_force(type_id:String,count:int=1)->Dictionary:
	var result:Dictionary=op.commission(port if C.UNITS[type_id].domain=="navy" else airfield,type_id,count)
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	var force:Dictionary=op.force(int(result.get("id",0)));force.training=1.0
	return force

func test_water_route_goes_around_island_and_rejects_land_destination()->void:
	var map:=G.new();map.land_query=func(point:Vector2)->bool:return absf(point.x)<10 and absf(point.y)<15
	var route:=map.sea_route(Vector2(-40,0),Vector2(40,0))
	assert_bool(route.has("error")).is_false()
	assert_float(float(route.distance)).is_greater(80)
	for i in range(1,route.points.size()):assert_bool(map.sea_edge(G.unpack(route.points[i-1]),G.unpack(route.points[i]))).is_true()
	assert_bool(map.sea_route(Vector2(-40,0),Vector2.ZERO).has("error")).is_true()

func test_transport_delivers_withdrawn_food_once_then_returns()->void:
	var force:=_ready_force("convoy_transport")
	var before:=FoodSystem.total_stored()
	var destination_before:float=SettlementModel.with_city_resources("second",func():return FoodSystem.total_stored())
	assert_bool(op.logistics.start(int(force.id),"second",100).has("ok")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal_approx(before-100,.001)
	for day in range(1,5):op.advance(day)
	var destination_after:float=SettlementModel.with_city_resources("second",func():return FoodSystem.total_stored())
	assert_float(destination_after-destination_before).is_equal_approx(100,.001)
	assert_str(String(op.state.convoys[0].status)).is_equal("returned")
	op.advance(5)
	assert_float(float(SettlementModel.with_city_resources("second",func():return FoodSystem.total_stored()))).is_equal_approx(destination_after,.001)

func test_no_fuel_halts_transport_without_moving_or_losing_cargo()->void:
	var force:=_ready_force("transport_aircraft")
	assert_bool(op.logistics.start(int(force.id),"second",10).has("ok")).is_true()
	MilitaryCampaign.military_consumables.fuel=0
	var position:Dictionary=force.position.duplicate(true)
	op.advance(1)
	assert_dict(force.position).is_equal(position)
	assert_float(float(op.state.convoys[0].food)).is_equal_approx(10,.0001)
	assert_str(String(force.status)).contains("no fuel")

func test_carrier_capacity_and_airframe_compatibility_are_enforced()->void:
	var carrier:=_ready_force("aircraft_carrier")
	var wing:=_ready_force("fighter",10)
	var bomber:=_ready_force("strategic_bomber")
	assert_bool(op.attach_carrier(int(bomber.id),int(carrier.id)).has("error")).is_true()
	assert_bool(op.attach_carrier(int(wing.id),int(carrier.id)).has("ok")).is_true()
	assert_int(int(wing.get("pending_carrier_id",0))).is_equal(int(carrier.id))
	op.advance(1)
	assert_int(int(wing.carrier_id)).is_equal(int(carrier.id))
	carrier.units.aircraft_carrier=0
	op.advance(2)
	assert_int(int(wing.carrier_id)).is_equal(0)

func test_splitting_merging_and_fleet_grouping_conserve_people_and_hulls()->void:
	var force:=_ready_force("war_canoe",4)
	var people:=MilitaryCampaign._mobilized_count()
	var split:Dictionary=op.split_force(int(force.id))
	assert_bool(split.has("ok")).is_true()
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(people)
	assert_bool(op.group_fleet(int(split.id),int(force.id)).has("ok")).is_true()
	assert_bool(op.merge_forces(int(force.id),int(split.id)).has("ok")).is_true()
	assert_int(op.hardware(force)).is_equal(4)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(people)

func test_construction_diverts_existing_city_workers_without_extra_labor()->void:
	var base:Dictionary=op.base(port);base.construction_work=0.0
	var raw:=GameState.effective_workers("Construction",true)
	assert_float(GameState.effective_workers("Construction")).is_equal_approx(raw*.75,.001)
	op.advance(1)
	assert_float(float(base.construction_work)).is_equal_approx(raw*.25*.1,.001)

func test_airlift_food_is_credited_only_to_receiving_army_and_spent_once()->void:
	MilitaryCampaign.field_armies=[{"army_id":1,"name":"Remote army","troops":10,"formations":[],"position":{"x":20.0,"z":2.0},"status":"stationed","delivered_field_food":5.0},{"army_id":2,"name":"Other army","troops":10,"formations":[],"position":{"x":30.0,"z":2.0},"status":"stationed"}]
	MilitaryCampaign.home_army.troops=0
	var receipt:=MilitaryCampaign.draw_delivered_field_rations(20)
	assert_float(float(receipt.total)).is_equal(5.0)
	MilitaryCampaign.record_daily_provisions(20,0,receipt)
	assert_float(float(MilitaryCampaign.field_armies[0].provisions_delivered_today)).is_equal(5.0)
	assert_float(float(MilitaryCampaign.field_armies[1].provisions_delivered_today)).is_equal(0.0)
	assert_float(float(MilitaryCampaign.draw_delivered_field_rations(20).total)).is_equal(0.0)

func test_operations_screen_instantiates_and_offers_only_researched_production()->void:
	var screen:CanvasLayer=auto_free(preload("res://scripts/hud/naval_command_panel.gd").new())
	add_child(screen)
	assert_int(screen.type_picker.item_count).is_greater(0)
	for i in screen.type_picker.item_count:
		var id:=String(screen.type_picker.get_item_metadata(i))
		assert_bool(MilitaryCampaign._knowledge_gate(String(C.UNITS[id].gate),.1).unlocked).is_true()
	assert_bool(screen.map!=null).is_true()

func test_drawn_regions_follow_boundaries_and_persist()->void:
	var created:Dictionary=op.create_region("air",op.R.rectangle(Vector2(20,0),30),"Northern approaches")
	assert_bool(created.has("ok")).is_true()
	var wing:=_ready_force("fighter")
	assert_bool(op.assign(int(wing.id),created.region,"air_superiority").has("ok")).is_true()
	wing.efficiency=1.0
	assert_float(float(op.effects.control("player",op.region_at(Vector2(20,0),"air")))).is_equal(1.0)
	assert_float(float(op.effects.control("player",op.region_at(Vector2(100,0),"air")))).is_equal(0.0)
	var saved:Dictionary=op.export_state()
	assert_str(op.validate(saved)).is_empty()
	op.reset();op.import_state(saved)
	assert_array(op.known_regions("air")).has_size(1)
	assert_str(String(op.known_regions("air")[0].name)).is_equal("Northern approaches")
	var broken:Dictionary=saved.duplicate(true);broken.regions[0].vertices[0].x=NAN
	assert_str(op.validate(broken)).is_not_empty()
	op.import_state(broken)
	assert_dict(op.export_state()).is_equal(saved)

func test_crossed_boundaries_are_rejected_without_saving_an_area()->void:
	var vertices:=[G.pack(Vector2(0,0)),G.pack(Vector2(20,20)),G.pack(Vector2(0,20)),G.pack(Vector2(20,0))]
	assert_bool(op.create_region("air",vertices).has("error")).is_true()
	assert_array(op.state.regions).is_empty()

func test_polygon_coverage_accounts_for_partial_range_and_overlap()->void:
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2.ZERO,100)).region
	var overlap:Dictionary=op.create_region("air",op.R.rectangle(Vector2(100,0),100)).region
	assert_float(op.R.overlap(region,overlap)).is_equal_approx(.5,.001)
	assert_float(op.R.coverage(region,Vector2.ZERO,50)).is_between(.1,.3)
	assert_float(op.R.coverage(region,Vector2(1000,0),50)).is_equal(0.0)

func test_screening_protects_capitals_and_submarines_are_harder_to_detect()->void:
	var attacker:={"domain":"navy","units":{"submarine":3}}
	var bare:={"domain":"navy","units":{"battleship":1}}
	var escorted:={"domain":"navy","units":{"battleship":1,"destroyer":3}}
	assert_float(op.B.damage_multiplier(attacker,escorted)).is_less(op.B.damage_multiplier(attacker,bare))
	assert_float(op.B.detection_multiplier(escorted,attacker)).is_greater(op.B.detection_multiplier(bare,attacker))

func test_lost_base_blocks_existing_production_without_spending_materials()->void:
	var result:Dictionary=MilitaryCampaign.start_production_line("fighter_equipment",2)
	# The ordinary production policy also needs crafting workers.
	if result.has("error"):
		GameState.population_allocations["Crafting"]=100;GameState.population_allocations["Logistics"]=100
		result=MilitaryCampaign.start_production_line("fighter_equipment",2)
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	op.base(airfield).condition=0.0
	var stocks:Dictionary=GameState.resource_stockpiles.duplicate(true)
	assert_str(preload("res://scripts/persistent_production.gd").state(MilitaryCampaign,job)).is_equal("No operational airfield")
	preload("res://scripts/persistent_production.gd").advance(MilitaryCampaign,job,100)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)

func test_rival_crews_are_reserved_from_land_capacity()->void:
	var force:=_ready_force("galley")
	force.owner="test_rival"
	assert_float(CivilizationSystem.land_military_population({"id":"test_rival","military_population":1000.0})).is_equal(920.0)

func test_transport_save_rejects_invalid_routes_and_preserves_cargo()->void:
	var force:=_ready_force("convoy_transport")
	assert_bool(op.logistics.start(int(force.id),"second",100).has("ok")).is_true()
	var saved:Dictionary=op.export_state()
	assert_str(op.validate(saved)).is_empty()
	var broken:=saved.duplicate(true);broken.convoys[0].route=[{"x":NAN,"z":0}]
	assert_str(op.validate(broken)).is_not_empty()
	op.import_state(broken)
	assert_dict(op.export_state()).is_equal(saved)

func test_split_with_casualties_preserves_authorized_replacement_targets()->void:
	var original:=_ready_force("destroyer",1)
	original.units["light_cruiser"]=1;original.authorized={"destroyer":100,"light_cruiser":100}
	var result:Dictionary=op.split_force(int(original.id))
	assert_bool(result.has("ok")).is_true()
	var other:Dictionary=op.force(int(result.id))
	assert_int(int(original.authorized.destroyer)+int(other.authorized.destroyer)).is_equal(100)
	assert_int(int(original.authorized.light_cruiser)+int(other.authorized.light_cruiser)).is_equal(100)
	assert_int(op.hardware(original)+op.hardware(other)).is_equal(2)
