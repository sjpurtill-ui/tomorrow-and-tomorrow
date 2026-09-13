extends GdUnitTestSuite
const Rail=preload("res://scripts/rail_freight.gd")
const F=preload("res://scripts/rail_freight_fabric.gd")
const R=preload("res://scripts/rail_route_survey.gd")
const S=preload("res://scripts/rail_freight_state.gd")
var source_id:String
var old_provider:Callable
func before_test()->void:
	GameState.reset_for_new_world(772241);ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	source_id=String(GameState.player_settlements[0].id)
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	CivilizationSystem.register_player_origin(Vector2.ZERO);CivilizationSystem.record_player_travel(Vector2(10,0))
	for id:String in Rail.REQUIRED+["aggregate_road_foundations"]:GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	for item:String in ["Track Ballast","Timber Rail Panels","Rail Gauge Templates","900 mm Rail Wagons","1435 mm Rail Wagons","Rail Brake Sets","Timber","Wrought Iron","Stone"]:GameState.resource_stockpiles[item]=10000.0
	GameState.population_allocations.Construction=40
	old_provider=WorldSimulation.context_provider
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(origin),"terrain_height_at":func(_x:float,_z:float)->float:return .1,"buildable_land_at":func(_x:float,_z:float)->bool:return true,"river_distance_at":func(_x:float,_z:float)->float:return 10.0}
func after_test()->void:
	WorldSimulation.context_provider=old_provider
func installed(complete:bool=true)->Dictionary:
	var result:=Rail.install(source_id,"dawngate")
	assert_bool(bool(result.get("ok",false))).is_true()
	if not result.has("line_id"):return {}
	var line:=Rail.line_for(int(result.line_id))
	if complete:F.construct(line,99999,0)
	return line
func supplies_for_trade()->void:
	GameState.society_capacities.logistics=.8;GameState.society_capacities.institutions=.8
	GameState.population_allocations.Logistics=8
	for item:String in SettlementModel.CITY_TRADE_GOODS:GameState.resource_stockpiles[item]=10000.0
	GameState.food_stocks.clear();FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(20000)
	SettlementModel.with_city_resources("dawngate",func()->void:
		for item:String in SettlementModel.CITY_TRADE_GOODS:GameState.resource_stockpiles[item]=10000.0
		GameState.resource_stockpiles.Food=0.0;GameState.food_stocks.clear();FoodSystem.reset_for_new_world();FoodSystem.initialize())
func test_route_rejects_missing_evidence_steep_grade_and_between_sample_river()->void:
	var terrain:=Rail.terrain_for(source_id)
	assert_bool(R.survey([Vector3.ZERO,Vector3(10,0,0)],{}).has("error")).is_true()
	terrain.river_distance_at=func(_x:float,_z:float)->float:return INF
	assert_bool(bool(R.survey([Vector3.ZERO,Vector3(10,0,0)],terrain).get("ok",false))).is_true()
	terrain.height_at=func(x:float,_z:float)->float:return x*.03
	assert_bool(R.survey([Vector3.ZERO,Vector3(10,0,0)],terrain).has("error")).is_true()
	terrain.height_at=func(_x:float,_z:float)->float:return .1
	terrain.river_distance_at=func(x:float,_z:float)->float:return absf(x-.125)
	assert_bool(R.survey([Vector3.ZERO,Vector3(1,0,0)],terrain).has("error")).is_true()
	terrain=Rail.terrain_for(source_id);terrain.known_at=func(_x:float,_z:float)->bool:return false
	assert_bool(R.survey([Vector3.ZERO,Vector3(1,0,0)],terrain).has("error")).is_true()
func test_installation_is_paid_atomic_and_gauge_specific()->void:
	GameState.resource_stockpiles["900 mm Rail Wagons"]=0.0
	var before:=GameState.resource_stockpiles.duplicate()
	assert_bool(Rail.install(source_id,"dawngate").has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_bool(Rail.data().lines.is_empty()).is_true()
	GameState.resource_stockpiles["900 mm Rail Wagons"]=2.0
	var line:=installed(false)
	assert_float(float(GameState.resource_stockpiles["900 mm Rail Wagons"])).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles["1435 mm Rail Wagons"])).is_equal(10000.0)
	assert_bool(F.trip_quote(line,100,20,0).is_empty()).is_true()
	assert_bool(Rail.install(source_id,"dawngate").has("error")).is_true()
func test_shared_monthly_construction_does_not_duplicate_builders()->void:
	var line:=installed(false)
	var active:=0
	for plot:Dictionary in GameState.settlement_plots:
		if plot.status=="under_construction":active+=1
	var expected:=GameState.effective_workers("Construction")/float(active+1)*float(GameState.simulation_metrics.get("labor_efficiency",.72))*.1
	GameState.last_morphology_day=-1
	SettlementModel.process_month()
	assert_float(float(line.work_done)).is_equal_approx(expected,.0001)
	SettlementModel.process_month()
	assert_float(float(line.work_done)).is_equal_approx(expected,.0001)
func test_real_cargo_arrives_but_wagons_wait_for_return()->void:
	var line:=installed();supplies_for_trade()
	var before:=float(GameState.resource_stockpiles.Food)
	SettlementModel.process_city_trade()
	var shipments:Array=GameState.city_trade_shipments.filter(func(s:Dictionary)->bool:return s.get("transport_mode","")=="rail")
	assert_int(shipments.size()).is_equal(1)
	if shipments.is_empty():return
	var shipment:Dictionary=shipments[0]
	assert_float(float(GameState.resource_stockpiles.Food)).is_equal_approx(before-float(shipment.quantity),.0001)
	assert_bool(line.trip.is_empty()).is_false()
	GameState.population_allocations.Logistics=0;GameState.elapsed_days=1;SettlementModel.process_city_trade()
	assert_bool(line.trip.is_empty()).is_false()
	assert_float(Rail.reserved_workers(source_id)).is_greater(0.0)
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.Food)).is_equal_approx(float(shipment.quantity)*exp(-.00035),.0001)
	GameState.elapsed_days=2;SettlementModel.process_city_trade()
	assert_bool(line.trip.is_empty()).is_true()
func test_trip_reserves_upkeep_from_the_same_cargo_stock()->void:
	var line:=installed()
	GameState.resource_stockpiles.Timber=5.0
	var receipt:=Rail.issue_dispatch(source_id,"dawngate","Timber",100,20,1)
	assert_float(float(receipt.get("quantity",0))).is_equal_approx(4.0,.0001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(0,.0001)
	assert_bool(Rail.issue_dispatch("dawngate",source_id,"Timber",10,20,2).is_empty()).is_true()
	assert_float(float(line.trip.quantity)).is_equal_approx(4,.0001)
func test_upkeep_shortage_does_not_remove_cargo_or_reserve_assets()->void:
	var line:=installed();GameState.resource_stockpiles["Wrought Iron"]=0.0
	var stock:=GameState.resource_stockpiles.duplicate();var condition:=float(line.condition)
	assert_bool(Rail.issue_dispatch(source_id,"dawngate","Timber",100,20,1).is_empty()).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
	assert_float(float(line.condition)).is_equal(condition)
	assert_bool(line.trip.is_empty()).is_true()
func test_secondary_installation_uses_only_secondary_stores()->void:
	assert_bool(Rail.install("dawngate",source_id).has("error")).is_true()
	var before:=GameState.resource_stockpiles.duplicate()
	SettlementModel.with_city_resources("dawngate",func()->void:
		for item:String in before:GameState.resource_stockpiles[item]=before[item])
	assert_bool(bool(Rail.install("dawngate",source_id).get("ok",false))).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	Rail.city("dawngate").occupied_by="invader"
	assert_bool(Rail.accessible(Rail.data().lines[0])).is_false()
func test_maintenance_closes_line_and_requires_replacements()->void:
	var line:=installed();line.condition=.5;line.wagon_condition=.5
	var stock:=GameState.resource_stockpiles
	stock["Rail Brake Sets"]=0.0
	assert_float(F.maintain(line,stock,30,0)).is_equal(0.0)
	stock["Rail Brake Sets"]=10.0
	assert_float(F.maintain(line,stock,30,0)).is_equal_approx(30,.0001)
	assert_bool(F.trip_quote(line,100,20,0).is_empty()).is_true()
	assert_bool(F.trip_quote(line,100,20,1).is_empty()).is_false()
func test_legacy_and_malformed_saved_state()->void:
	var line:=installed()
	assert_bool(S.valid_state({})).is_true()
	assert_bool(S.valid(Rail.data())).is_true()
	var bad:=Rail.data().duplicate(true);bad.lines[0].work_done=INF
	assert_bool(S.valid(bad)).is_false()
	bad=Rail.data().duplicate(true);bad.lines[0].gauge_mm=1435
	assert_bool(S.valid(bad)).is_false()
	bad=Rail.data().duplicate(true);bad.lines[0].route.waypoints[1].z=2
	assert_bool(S.valid(bad)).is_false()
	assert_bool(Rail.issue_dispatch(source_id,"dawngate","Timber",100,20,1).is_empty()).is_false()
	assert_bool(S.valid(Rail.data())).is_true()
	bad=Rail.data().duplicate(true);bad.lines[0].trip.crew_workers=0
	assert_bool(S.valid(bad)).is_false()
func test_actual_install_button_uses_paid_action()->void:
	var panel=preload("res://scripts/hud/rail_freight_controls.gd").new()
	get_tree().root.add_child(panel)
	assert_bool(panel.build.disabled).is_false()
	panel.build.pressed.emit()
	assert_int(Rail.data().lines.size()).is_equal(1)
	assert_float(float(GameState.resource_stockpiles["900 mm Rail Wagons"])).is_equal(9998.0)
	panel.free()

func test_occupation_holds_cargo_and_return_then_reverse_service_resumes()->void:
	var line:=installed();supplies_for_trade();SettlementModel.process_city_trade()
	var original:Dictionary=GameState.city_trade_shipments.filter(func(s:Dictionary)->bool:return s.get("transport_mode","")=="rail")[0]
	var quantity:=float(original.quantity)
	Rail.city("dawngate").occupied_by="invader"
	GameState.population_allocations.Logistics=0;GameState.elapsed_days=3;SettlementModel.process_city_trade()
	assert_bool(line.trip.is_empty()).is_false()
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.Food)).is_equal(0.0)
	Rail.city("dawngate").erase("occupied_by")
	GameState.elapsed_days=4;SettlementModel.process_city_trade()
	assert_bool(line.trip.is_empty()).is_true()
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.Food)).is_equal_approx(quantity*exp(-.00035),.0001)
	SettlementModel.with_city_resources("dawngate",func()->void:GameState.resource_stockpiles["Wrought Iron"]=100.0)
	assert_bool(Rail.issue_dispatch("dawngate",source_id,"Timber",30,20,999).is_empty()).is_false()
	assert_str(String(line.trip.source_id)).is_equal("dawngate")

func test_saved_cargo_dates_and_duplicate_consignment_are_rejected()->void:
	installed();supplies_for_trade();SettlementModel.process_city_trade()
	var state:={"rail_freight":Rail.data(),"city_trade_shipments":GameState.city_trade_shipments}
	assert_bool(S.valid_state(state)).is_true()
	var bad:=state.duplicate(true)
	bad.city_trade_shipments[0].arrival_day=0
	assert_bool(S.valid_state(bad)).is_false()
	bad=state.duplicate(true);bad.city_trade_shipments.append(bad.city_trade_shipments[0].duplicate(true))
	assert_bool(S.valid_state(bad)).is_false()

func test_full_save_restores_in_transit_cargo_and_paid_rolling_stock()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	installed();supplies_for_trade();SettlementModel.process_city_trade()
	var saved_rail:=Rail.data().duplicate(true)
	var saved_cargo:=GameState.city_trade_shipments.duplicate(true)
	var saved_stock:=GameState.resource_stockpiles.duplicate(true)
	var slot:="rail_freight_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.rail_freight=F.empty_state();GameState.city_trade_shipments.clear()
	var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_dict(Rail.data()).is_equal(saved_rail)
	assert_array(GameState.city_trade_shipments).is_equal(saved_cargo)
	assert_dict(GameState.resource_stockpiles).is_equal(saved_stock)
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_supplied_investment_installs_only_once_without_inventing_materials()->void:
	var planner=preload("res://scripts/rail_freight_investment.gd")
	GameState.city_trade_history.append({"source_id":source_id,"destination_id":"dawngate"})
	var stock:=GameState.resource_stockpiles.duplicate()
	planner.recommendation()
	assert_int(Rail.data().lines.size()).is_equal(1)
	assert_float(float(GameState.resource_stockpiles["900 mm Rail Wagons"])).is_equal(float(stock["900 mm Rail Wagons"])-2)
	var remaining:=GameState.resource_stockpiles.duplicate()
	planner.recommendation()
	assert_int(Rail.data().lines.size()).is_equal(1)
	assert_dict(GameState.resource_stockpiles).is_equal(remaining)

func test_autonomous_wagon_manufacture_precedes_installation()->void:
	GameState.population_allocations.Crafting=40
	GameState.city_trade_history.append({"source_id":source_id,"destination_id":"dawngate"})
	GameState.resource_stockpiles["900 mm Rail Wagons"]=0.0
	var industry=preload("res://scripts/civilian_industry.gd")
	var spec:Dictionary=industry.PRODUCTS.rail_wagons_900
	for material:String in spec.materials:GameState.resource_stockpiles[material]=1000.0
	for material:String in spec.tooling:GameState.resource_stockpiles[material]=1000.0
	var planner=preload("res://scripts/rail_freight_investment.gd")
	var order:Dictionary=planner.recommendation()
	assert_str(String(order.get("item",""))).is_equal("rail_wagons_900")
	assert_int(Rail.data().lines.size()).is_equal(0)
	preload("res://scripts/civilization_controller.gd").production_order("player",order)
	assert_array(MilitaryCampaign.equipment_queue).is_not_empty()
	if MilitaryCampaign.equipment_queue.is_empty():return
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	preload("res://scripts/persistent_production.gd").advance(MilitaryCampaign,job,float(spec.days)*4)
	assert_float(float(GameState.resource_stockpiles["900 mm Rail Wagons"])).is_greater_equal(2.0)
	planner.recommendation()
	assert_int(Rail.data().lines.size()).is_equal(1)

func test_owned_actor_paid_partial_construction_survives_full_save()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("rail_owner",9393)
	var human_stock:=GameState.resource_stockpiles.duplicate()
	WorldSimulation.scoped("rail_owner",func()->void:
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
		state.settlement_completed.assign(["Hearth Circle"]);model.ensure_founded()
		var primary:=String(state.player_settlements[0].id)
		state.player_settlements.append({"id":"rail_end","name":"Rail End","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.system("CivilizationSystem").register_player_origin(Vector2.ZERO)
		WorldSimulation.system("CivilizationSystem").record_player_travel(Vector2(10,0))
		for id:String in Rail.REQUIRED:state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
		for item:String in human_stock:state.resource_stockpiles[item]=human_stock[item]
		var result:=Rail.install(primary,"rail_end")
		assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
		if not result.has("line_id"):return
		F.construct(Rail.line_for(int(result.line_id)),20,0))
	assert_dict(GameState.resource_stockpiles).is_equal(human_stock)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var slot:="rail_actor_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	WorldSimulation.scoped("rail_owner",func()->void:
		assert_int(Rail.data().lines.size()).is_equal(1)
		if Rail.data().lines.is_empty():return
		assert_float(float(Rail.data().lines[0].work_done)).is_equal(20.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["900 mm Rail Wagons"])).is_equal(9998.0))
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
