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

func test_patrol_and_raiders_keep_searching_after_their_first_arrival()->void:
	MilitaryCampaign.training_staff.set_policy("navy","suspended")
	var region:Dictionary=op.create_region("navy",op.R.rectangle(Vector2(0,-50),30),"Coastal search").region
	var patrol:=_ready_force("war_canoe");var raider:=_ready_force("torpedo_boat")
	assert_bool(op.assign(int(patrol.id),region,"patrol").has("ok")).is_true()
	assert_bool(op.assign(int(raider.id),region,"convoy_raiding").has("ok")).is_true()
	op.advance(1)
	var visited:Dictionary={}
	for day in range(2,8):
		var before:Array=[op.force_position(patrol),op.force_position(raider)]
		op.advance(day)
		for i in 2:
			var ship:Dictionary=[patrol,raider][i];var position:Vector2=op.force_position(ship)
			assert_float(position.distance_to(before[i])).is_greater(.1)
			assert_float(position.distance_to(before[i])).is_less_equal(op.speed(ship))
			assert_bool(op.R.contains(region,position)).is_true()
			assert_bool(op.geography.sea_edge(before[i],position)).is_true()
			assert_float(float(ship.efficiency)).is_greater(0.0)
			visited[str(i)+str(position)]=true
	assert_int(visited.size()).is_greater_equal(8)
	assert_str(String(patrol.status)).contains("Patrolling")
	assert_str(String(raider.status)).contains("Searching for convoys")

func test_search_legs_respect_islands_concave_boundaries_range_and_daily_speed()->void:
	var map:=G.new()
	map.land_query=func(point:Vector2)->bool:return point.distance_to(Vector2(-65,-80))<12
	var vertices:Array=[]
	for point:Vector2 in [Vector2(-100,-20),Vector2(-20,-20),Vector2(-20,-100),Vector2(100,-100),Vector2(100,-200),Vector2(-100,-200)]:vertices.append(G.pack(point))
	var region:Dictionary=op.create_region("navy",vertices,"Island approaches").region
	var home:=Vector2(-100,-100);var position:=Vector2(-80,-50);var visited:Dictionary={}
	for day in 30:
		var route:=map.patrol_route(region,position,home,140,35,day*1237)
		assert_bool(route.is_empty()).is_false()
		if route.is_empty():return
		var target:=G.unpack(route.points.back())
		assert_float(position.distance_to(target)).is_between(.1,35)
		for sample in 41:
			var location:=position.lerp(target,sample/40.0)
			assert_bool(op.R.contains(region,location)).is_true()
			assert_bool(map.is_land(location)).is_false()
			assert_float(location.distance_to(home)).is_less_equal(140)
		visited[str(target)]=true;position=target
	assert_int(visited.size()).is_greater(8)
	# An isolated pocket cannot invent a route through land to another cell.
	map.land_query=func(point:Vector2)->bool:return point.distance_to(position)>.01
	assert_dict(map.patrol_route(region,position,home,140,35,1)).is_empty()
	assert_dict(map.patrol_route(region,Vector2(1000,1000),home,140,35,1)).is_empty()

func test_patrol_fuel_shortage_and_saved_orders_resume_without_reissuing()->void:
	MilitaryCampaign.training_staff.set_policy("navy","suspended")
	var ship:=_ready_force("torpedo_boat")
	var region:Dictionary=op.create_region("navy",op.R.rectangle(Vector2(0,-50),30),"Fuel patrol").region
	assert_bool(op.assign(int(ship.id),region,"patrol").has("ok")).is_true()
	op.advance(1)
	var stopped:Vector2=op.force_position(ship)
	MilitaryCampaign.military_consumables.fuel=0
	op.advance(2)
	assert_vector(op.force_position(ship)).is_equal(stopped)
	assert_int(int(ship.fuel_used)).is_equal(0)
	assert_float(float(ship.efficiency)).is_equal(0.0)
	assert_str(String(ship.status)).contains("No fuel")
	assert_array(ship.route).is_not_empty()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(op.export_state()))
	assert_str(op.validate(saved)).is_empty()
	MilitaryCampaign.military_consumables.fuel=6
	op.advance(3);op.advance(4)
	var expected:Vector2=op.force_position(ship)
	assert_float(expected.distance_to(stopped)).is_greater(.1)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(2)
	var id:=int(ship.id)
	op.import_state(saved);ship=op.force(id)
	MilitaryCampaign.military_consumables.fuel=6
	op.advance(3);op.advance(4)
	assert_vector(op.force_position(ship)).is_equal(expected)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(2)
	assert_str(String(ship.mission)).is_equal("patrol")
	assert_str(String(ship.region.id)).is_equal(String(region.id))
	op.advance(4)
	assert_vector(op.force_position(ship)).is_equal(expected)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(2)

func test_contacts_interrupt_search_then_patrol_resumes_and_strike_force_returns()->void:
	MilitaryCampaign.training_staff.set_policy("navy","suspended")
	var patrol:=_ready_force("torpedo_boat");var strike:=_ready_force("torpedo_boat")
	var region:Dictionary=op.create_region("navy",op.R.rectangle(Vector2(0,-100),80),"Contact search").region
	assert_bool(op.assign(int(patrol.id),region,"patrol").has("ok")).is_true()
	assert_bool(op.assign(int(strike.id),region,"strike_force").has("ok")).is_true()
	op.advance(1)
	var home:Vector2=op.point(op.base(port))
	assert_vector(op.force_position(strike)).is_equal(home)
	assert_int(int(strike.fuel_used)).is_equal(0)
	assert_str(String(strike.status)).contains("waiting for a patrol contact")
	var rival:Dictionary={"id":"patrol_test_enemy","player_relation":{"at_war":true},"strategic_regions":[]}
	CivilizationSystem.civilizations.append(rival)
	var reported:=Vector2(50,-130)
	op.state.contacts["player:999"]={"observer":"player","target":999,"region":region.id,"day":1,"name":"Reported hostile","position":G.pack(reported),"owner":rival.id,"domain":"navy"}
	for day in [2,3]:
		op.advance(day)
		assert_vector(op.force_position(patrol)).is_equal(reported)
		assert_vector(op.force_position(strike)).is_equal(reported)
	op.advance(4)
	assert_float(op.force_position(patrol).distance_to(reported)).is_greater(.1)
	assert_vector(op.force_position(strike)).is_equal(home)
	op.advance(5)
	assert_vector(op.force_position(strike)).is_equal(home)
	assert_int(int(strike.fuel_used)).is_equal(0)
	CivilizationSystem.civilizations.erase(rival)

func test_patrol_repair_and_stand_down_override_search_movement()->void:
	MilitaryCampaign.training_staff.set_policy("navy","suspended")
	var ship:=_ready_force("torpedo_boat")
	var region:Dictionary=op.create_region("navy",op.R.rectangle(Vector2(0,-50),30),"Repair patrol").region
	assert_bool(op.assign(int(ship.id),region,"patrol").has("ok")).is_true()
	op.advance(1)
	ship.condition=.5;ship.repairing=true
	op.advance(2)
	var home:Vector2=op.point(op.base(port))
	assert_vector(op.force_position(ship)).is_equal(home)
	assert_str(String(ship.status)).contains("Returning for repairs")
	op.advance(3)
	assert_vector(op.force_position(ship)).is_equal(home)
	assert_int(int(ship.fuel_used)).is_equal(0)
	ship.condition=1.0;ship.repairing=false
	assert_bool(op.assign(int(ship.id),{},"hold").has("ok")).is_true()
	op.advance(4)
	assert_vector(op.force_position(ship)).is_equal(home)
	for day in [5,6]:
		op.advance(day)
		assert_vector(op.force_position(ship)).is_equal(home)
		assert_int(int(ship.fuel_used)).is_equal(0)

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

func test_carrier_leaving_air_range_grounds_wing_without_sortie_fuel_and_return_resumes_order()->void:
	MilitaryCampaign.training_staff.set_policy("navy","suspended")
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var carrier:=_ready_force("aircraft_carrier");carrier.position=G.pack(Vector2(600,-10))
	var wing:=_ready_force("fighter",4)
	assert_bool(op.attach_carrier(int(wing.id),int(carrier.id)).has("ok")).is_true()
	var fuel:=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(1)
	assert_int(int(wing.carrier_id)).is_equal(int(carrier.id))
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-op.fuel_cost(wing))
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2.ZERO,20),"Coastal cover").region
	assert_bool(op.assign(int(wing.id),region,"air_superiority").has("ok")).is_true()
	assert_bool(op.set_route(carrier,Vector2(1600,-10)).has("error")).is_false()
	fuel=int(MilitaryCampaign.military_consumables.fuel)
	var experience:=float(wing.experience)
	op.advance(2)
	assert_float(op.force_position(carrier).x).is_greater(1000)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-op.fuel_cost(carrier))
	assert_int(int(wing.fuel_used)).is_equal(0)
	assert_float(float(wing.efficiency)).is_equal(0.0)
	assert_float(float(wing.experience)).is_equal(experience)
	assert_float(float(op.effects.control("player",region))).is_equal(0.0)
	assert_str(String(wing.status)).is_equal("Grounded · operating area out of range")
	assert_str(String(wing.mission)).is_equal("air_superiority")
	assert_dict(wing.region).is_equal(region)
	var panel:CanvasLayer=auto_free(preload("res://scripts/hud/air_command_panel.gd").new());add_child(panel)
	panel.selected_id=int(wing.id);panel._select_force(true)
	assert_str(panel.status.text).contains("Grounded · operating area out of range").contains("Flight fuel: 0 used today")
	assert_str(panel.readiness_label.text).contains("beyond operating range")
	# A grounded standing order survives a save; returning the carrier resumes it.
	var saved:Dictionary=op.export_state();assert_str(op.validate(saved)).is_empty()
	var carrier_id:=int(carrier.id);var wing_id:=int(wing.id)
	op.reset();op.import_state(saved);carrier=op.force(carrier_id);wing=op.force(wing_id)
	assert_bool(op.set_route(carrier,Vector2(600,-10)).has("error")).is_false()
	fuel=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(3)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-op.fuel_cost(carrier)-op.fuel_cost(wing))
	assert_int(int(wing.fuel_used)).is_equal(op.fuel_cost(wing))
	assert_float(float(wing.efficiency)).is_greater(0.0)
	assert_float(float(wing.experience)).is_greater(experience)
	assert_float(float(op.effects.control("player",region))).is_equal(1.0)
	assert_str(String(wing.status)).contains("On mission")
	assert_dict(wing.region).is_equal(region)
	panel._refresh_status()
	assert_str(panel.status.text).contains("On mission").contains("Flight fuel: 4 used today")
	fuel=int(MilitaryCampaign.military_consumables.fuel);op.advance(3)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel)

func test_partial_air_coverage_flies_only_after_fuel_arrives()->void:
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var wing:=_ready_force("fighter",4)
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2(650,1),150),"Distant cover").region
	assert_bool(op.assign(int(wing.id),region,"air_superiority").has("ok")).is_true()
	var factors:Dictionary=op.mission_factors(wing,region,1)
	assert_float(float(factors.coverage)).is_between(.1,.9)
	MilitaryCampaign.military_consumables.fuel=op.fuel_cost(wing)-1
	op.advance(1)
	assert_str(String(wing.status)).contains("No fuel")
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(op.fuel_cost(wing)-1)
	assert_int(int(wing.fuel_used)).is_equal(0)
	assert_float(float(wing.efficiency)).is_equal(0.0)
	assert_float(float(op.effects.control("player",region))).is_equal(0.0)
	MilitaryCampaign.military_consumables.fuel=op.fuel_cost(wing)
	op.advance(2)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(0)
	assert_int(int(wing.fuel_used)).is_equal(op.fuel_cost(wing))
	factors=op.mission_factors(wing,region,2)
	assert_float(float(wing.efficiency)).is_equal_approx(float(factors.efficiency),.0001)
	assert_float(float(wing.efficiency)).is_greater(0.0)
	assert_str(String(wing.status)).contains("On mission")

func test_air_rebase_and_repair_return_still_consume_movement_fuel()->void:
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var wing:=_ready_force("fighter",4)
	SettlementModel.with_city_resources("second",func():
		for material:String in ["Timber","Stone","Iron Ore","Copper Ore","Fiber Plants","Graphite"]:GameState.resource_stockpiles[material]=1000.0)
	assert_bool(op.build_base("second","air").has("ok")).is_true()
	var destination:Dictionary=op.state.bases.back();destination.construction_work=30.0
	assert_bool(op.rebase(int(wing.id),int(destination.id)).has("ok")).is_true()
	var fuel:=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(1)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-op.fuel_cost(wing))
	assert_float(op.force_position(wing).distance_to(op.point(destination))).is_less(.001)
	assert_str(String(wing.status)).is_equal("Arrived at base")
	# A damaged wing returning from a distant position still pays for its flight.
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2(600,1),20)).region
	assert_bool(op.assign(int(wing.id),region,"air_superiority").has("ok")).is_true()
	wing.condition=.5;wing.position=G.pack(Vector2(1200,1))
	fuel=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(2)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-op.fuel_cost(wing))
	assert_float(op.force_position(wing).x).is_equal_approx(400,.001)
	assert_float(float(wing.efficiency)).is_equal(0.0)
	op.advance(3)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel-2*op.fuel_cost(wing))
	assert_float(op.force_position(wing).distance_to(op.point(destination))).is_less(.001)
	fuel=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(4)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel)
	assert_float(float(wing.condition)).is_greater(.5)

func test_air_order_without_an_operating_area_does_not_consume_sortie_fuel()->void:
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var wing:=_ready_force("fighter",4);wing.mission="interception"
	var fuel:=int(MilitaryCampaign.military_consumables.fuel)
	op.advance(1)
	assert_int(int(MilitaryCampaign.military_consumables.fuel)).is_equal(fuel)
	assert_int(int(wing.fuel_used)).is_equal(0)
	assert_float(float(wing.efficiency)).is_equal(0.0)
	assert_str(String(wing.status)).is_equal("Grounded · choose an operating region")

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

func test_wooden_hulls_repair_from_wood_and_fiber_without_iron()->void:
	var boat:=_ready_force("war_canoe",2)
	boat.condition=.5;boat.repairing=true
	GameState.resource_stockpiles["Iron Ore"]=0.0
	var before:=float(GameState.resource_stockpiles.Timber)
	var costs:Dictionary=op.repair_costs(boat)
	assert_bool(costs.has("Iron Ore")).is_false()
	var receipt:Dictionary=op.repair_at_base(boat,op.base(port))
	assert_bool(receipt.has("ok")).is_true()
	assert_float(float(boat.condition)).is_equal_approx(.54,.0001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(before-float(costs.Timber),.0001)

func test_repair_shortage_does_not_partially_pay_or_heal()->void:
	var boat:=_ready_force("war_canoe",2);boat.condition=.5;boat.repairing=true
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	var before:Dictionary=GameState.resource_stockpiles.duplicate(true)
	var receipt:Dictionary=op.repair_at_base(boat,op.base(port))
	assert_bool(receipt.has("error")).is_true()
	assert_str(String(receipt.error)).contains("Repairs waiting for")
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_float(float(boat.condition)).is_equal(.5)

func test_airbase_crowding_reduces_sorties_but_not_ships_at_sea()->void:
	var ships:=_ready_force("war_canoe",30)
	var wing:=_ready_force("fighter",30)
	op.base(port).capacity=10;op.base(airfield).capacity=10
	var air_region:Dictionary=op.create_region("air",op.R.rectangle(Vector2(0,0),20),"Flight area").region
	var sea_region:Dictionary=op.create_region("navy",op.R.rectangle(Vector2(0,-20),20),"Sea area").region
	var air:Dictionary=op.mission_factors(wing,air_region,1)
	var sea:Dictionary=op.mission_factors(ships,sea_region,1)
	assert_float(float(air.crowding)).is_equal_approx(1.0/3,.0001)
	assert_float(float(sea.crowding)).is_equal(1.0)

func test_readiness_explains_training_fuel_and_range_without_mutation()->void:
	var wing:=_ready_force("fighter");wing.training=.5
	MilitaryCampaign.military_consumables.fuel=0
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2(9000,0),20),"Distant area").region
	var before:Dictionary=op.export_state()
	var ready:Dictionary=op.readiness(int(wing.id),region)
	var reasons:=str(ready.blockers)
	assert_str(reasons).contains("Training:").contains("beyond operating range").contains("Insufficient fuel")
	assert_dict(op.export_state()).is_equal(before)

func test_air_superiority_does_not_attack_grounded_wings_and_interception_targets_raids()->void:
	var fighter:=_ready_force("fighter");fighter.mission="air_superiority"
	var bomber:=_ready_force("tactical_bomber");bomber.mission="hold";bomber.efficiency=0.0
	assert_bool(op.can_attack(fighter,bomber)).is_false()
	bomber.mission="strategic_bombing";bomber.efficiency=1.0
	assert_bool(op.can_attack(fighter,bomber)).is_true()
	fighter.mission="interception"
	assert_bool(op.can_attack(fighter,bomber)).is_true()
	bomber.mission="air_superiority"
	assert_bool(op.can_attack(fighter,bomber)).is_false()

func test_port_strikes_and_naval_strikes_use_physical_port_location()->void:
	var bomber:=_ready_force("naval_bomber");bomber.mission="port_strike"
	var ship:=_ready_force("war_canoe");ship.mission="strike_force"
	assert_bool(op.can_attack(bomber,ship)).is_true()
	ship.position={"x":100.0,"z":-100.0}
	assert_bool(op.can_attack(bomber,ship)).is_false()
	bomber.mission="naval_strike"
	assert_bool(op.can_attack(bomber,ship)).is_true()

func test_surface_ships_cannot_fire_across_an_entire_player_drawn_region()->void:
	var first:=_ready_force("war_canoe");first.mission="patrol";first.position={"x":0.0,"z":-20.0}
	var second:=_ready_force("war_canoe");second.mission="patrol";second.position={"x":100.0,"z":-20.0}
	assert_bool(op.can_attack(first,second)).is_false()
	second.position.x=1.0
	assert_bool(op.can_attack(first,second)).is_true()
	first.repairing=true
	assert_bool(op.can_attack(first,second)).is_false()

func test_commission_quote_is_read_only_and_matches_actual_equipment_blocker()->void:
	MilitaryCampaign.military_inventory.fighter_equipment=1
	var before:Dictionary=op.export_state()
	var people:=MilitaryCampaign._mobilized_count()
	var quote:Dictionary=op.commission_quote(airfield,"fighter",2)
	assert_str(String(quote.error)).contains("only 1 in reserve")
	assert_dict(op.commission(airfield,"fighter",2)).is_equal(quote)
	assert_dict(op.export_state()).is_equal(before)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(people)
	var possible:Dictionary=op.commission_quote(airfield,"fighter",1)
	assert_bool(possible.has("ok")).is_true()
	assert_int(int(possible.crew)).is_equal(int(C.UNITS.fighter.crew))

func test_rebase_cancels_pending_carrier_ferry_and_reaches_selected_airbase()->void:
	var carrier:=_ready_force("aircraft_carrier");carrier.position={"x":100.0,"z":-10.0}
	var wing:=_ready_force("fighter")
	assert_bool(op.attach_carrier(int(wing.id),int(carrier.id)).has("ok")).is_true()
	assert_bool(op.rebase(int(wing.id),airfield).has("ok")).is_true()
	assert_int(int(wing.pending_carrier_id)).is_equal(0)
	op.advance(1)
	assert_int(int(wing.carrier_id)).is_equal(0)
	assert_float(op.force_position(wing).distance_to(op.point(op.base(airfield)))).is_less(.001)

func test_carrier_wing_stand_down_stays_on_deck_and_preserves_equipment()->void:
	var carrier:=_ready_force("aircraft_carrier");carrier.position={"x":100.0,"z":-10.0}
	var wing:=_ready_force("fighter",2)
	wing.carrier_id=carrier.id;wing.mission="air_superiority"
	var people:=MilitaryCampaign._mobilized_count()
	assert_bool(op.assign(int(wing.id),{},"hold").has("ok")).is_true()
	assert_int(int(wing.carrier_id)).is_equal(int(carrier.id))
	assert_array(wing.route).is_empty()
	op.advance(1)
	assert_str(String(wing.status)).is_equal("Standing by on carrier deck")
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(people)
	assert_int(op.hardware(wing)).is_equal(2)

func test_disband_cannot_teleport_distant_hulls_to_reserve_or_orphan_deck_wings()->void:
	var carrier:=_ready_force("aircraft_carrier")
	var wing:=_ready_force("fighter");wing.carrier_id=carrier.id
	var before:Dictionary=op.export_state()
	assert_bool(op.disband(int(carrier.id)).has("error")).is_true()
	assert_bool(op.disband(int(wing.id)).has("error")).is_true()
	assert_dict(op.export_state()).is_equal(before)
	wing.carrier_id=0
	carrier.position={"x":100.0,"z":-10.0}
	assert_bool(op.disband(int(carrier.id)).has("error")).is_true()

func test_merging_carriers_redirects_incoming_wings_and_keeps_save_valid()->void:
	var first:=_ready_force("aircraft_carrier")
	var second:=_ready_force("aircraft_carrier")
	var wing:=_ready_force("fighter")
	assert_bool(op.attach_carrier(int(wing.id),int(second.id)).has("ok")).is_true()
	assert_bool(op.merge_forces(int(first.id),int(second.id)).has("ok")).is_true()
	assert_int(int(wing.pending_carrier_id)).is_equal(int(first.id))
	assert_str(op.validate(op.export_state())).is_empty()
	op.advance(1)
	assert_int(int(wing.carrier_id)).is_equal(int(first.id))

func test_command_refresh_preserves_pending_region_and_mission_until_assignment()->void:
	var wing:=_ready_force("fighter")
	var old:Dictionary=op.create_region("air",op.R.rectangle(Vector2(10,0),20),"Old sector").region
	var next:Dictionary=op.create_region("air",op.R.rectangle(Vector2(40,0),20),"New sector").region
	assert_bool(op.assign(int(wing.id),old,"air_superiority").has("ok")).is_true()
	var panel:CanvasLayer=auto_free(preload("res://scripts/hud/air_command_panel.gd").new());add_child(panel)
	panel._region(next)
	for i in panel.mission_picker.item_count:
		if panel.mission_picker.get_item_metadata(i)=="interception":panel.mission_picker.select(i)
	panel._refresh_choices()
	assert_str(String(panel.map.selected.id)).is_equal(String(next.id))
	assert_str(String(panel._selected(panel.mission_picker))).is_equal("interception")
	panel._report({"error":"Example blocked order"})
	assert_str(String(panel.map.selected.id)).is_equal(String(next.id))
	assert_str(String(panel._selected(panel.mission_picker))).is_equal("interception")
	panel._assign()
	assert_str(String(wing.region.id)).is_equal(String(next.id))
	assert_str(String(wing.mission)).is_equal("interception")
	assert_str(panel.status.text).contains("Current order:")

func test_explicit_force_selection_shows_that_forces_existing_order()->void:
	var first:=_ready_force("fighter")
	var second:=_ready_force("fighter")
	var region:Dictionary=op.create_region("air",op.R.rectangle(Vector2(10,0),20),"Assigned sector").region
	assert_bool(op.assign(int(second.id),region,"interception").has("ok")).is_true()
	var panel:CanvasLayer=auto_free(preload("res://scripts/hud/air_command_panel.gd").new());add_child(panel)
	panel.selected_id=int(second.id);panel._select_force(true)
	assert_str(String(panel.map.selected.id)).is_equal(String(region.id))
	assert_str(String(panel._selected(panel.mission_picker))).is_equal("interception")
	panel.selected_id=int(first.id);panel._select_force(true)
	assert_dict(panel.map.selected).is_empty()
	assert_str(String(panel._selected(panel.mission_picker))).is_equal("hold")
