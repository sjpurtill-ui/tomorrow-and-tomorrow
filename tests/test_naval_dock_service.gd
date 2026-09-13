extends GdUnitTestSuite
const Dock=preload("res://scripts/naval_dock_service.gd")
var op:RefCounted
var port:Dictionary
func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	op=MilitaryCampaign.joint_operations
	for id:String in ["river_craft","aerostat_observation","dry_dock_services"]:
		GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	for item:String in ["Timber","Stone","Iron Ore","Fiber Plants"]:GameState.resource_stockpiles[item]=1000.0
	assert_bool(op.build_base(String(GameState.player_settlements[0].id),"air").has("ok")).is_true()
	port=op.state.bases[0];port.domain="navy";port.construction_work=30.0
	for item:String in Dock.BILL:GameState.resource_stockpiles[item]=1000.0
	MilitaryCampaign.military_inventory["war_canoe_equipment"]=2
func ship()->Dictionary:
	var result:Dictionary=op.commission(int(port.id),"war_canoe",1)
	assert_bool(result.has("ok")).is_true()
	var force:Dictionary=op.force(int(result.id));force.condition=.5;force.repairing=true;force.training=1.0
	return force
func completed_dock()->void:
	assert_bool(op.build_dock(int(port.id)).has("ok")).is_true()
	assert_float(Dock.construct(port,240,0)).is_equal(240.0)

func test_paid_project_does_not_install_from_partial_inventory()->void:
	GameState.resource_stockpiles["Rigging Blocks"]=0.0
	var before:=GameState.resource_stockpiles.duplicate()
	assert_bool(op.build_dock(int(port.id)).has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_bool(port.has("dock_service")).is_false()
	GameState.resource_stockpiles["Rigging Blocks"]=8.0
	assert_bool(op.build_dock(int(port.id)).has("ok")).is_true()
	assert_float(float(GameState.resource_stockpiles["Rigging Blocks"])).is_equal(0.0)
	assert_bool(Dock.building(port)).is_true()
	assert_float(Dock.remaining_access(port,0)).is_equal(0.0)
	assert_bool(op.build_dock(int(port.id)).has("error")).is_true()

func test_partial_construction_uses_reserved_work_once_per_day()->void:
	assert_bool(op.build_dock(int(port.id)).has("ok")).is_true()
	GameState.population_allocations.Construction=40
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	var expected:=GameState.effective_workers("Construction",true)*.25*.1
	assert_float(op.construction_share()).is_equal(.25)
	op.advance(1)
	assert_float(float(port.dock_service.work_done)).is_equal_approx(expected,.000001)
	op.advance(1)
	assert_float(float(port.dock_service.work_done)).is_equal_approx(expected,.000001)
	assert_bool(Dock.building(port)).is_true()

func test_paid_inspection_and_repair_commit_together()->void:
	completed_dock();var force:=ship()
	GameState.known_discoveries.append("hull_condition_surveys");GameState.discovery_adoption.hull_condition_surveys=1.0
	var before:=float(GameState.resource_stockpiles.Timber)
	var repaired:Dictionary=op.repair_at_base(force,port)
	assert_bool(repaired.has("ok")).override_failure_message(str(repaired)).is_true()
	assert_float(float(force.condition)).is_greater(.54)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(before)
	assert_float(float(force.hull_survey.condition)).is_equal(.5)
	assert_int(int(force.hull_survey.day)).is_equal(0)
	assert_float(float(port.dock_service.access_used)).is_greater(0)
	var used:=float(port.dock_service.access_used)
	op.repair_at_base(force,port)
	assert_float(float(port.dock_service.access_used)).is_equal(used)

func test_missing_repair_materials_spend_no_dock_access_or_survey()->void:
	completed_dock();var force:=ship()
	GameState.known_discoveries.append("hull_condition_surveys");GameState.discovery_adoption.hull_condition_surveys=1.0
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	var before:=GameState.resource_stockpiles.duplicate()
	assert_bool(op.repair_at_base(force,port).has("error")).is_true()
	assert_float(float(force.condition)).is_equal(.5)
	assert_float(float(port.dock_service.access_used)).is_equal(0.0)
	assert_bool(force.has("hull_survey")).is_false()
	assert_dict(GameState.resource_stockpiles).is_equal(before)

func test_access_exhaustion_and_unsupported_hulls_do_not_gain_dock_work()->void:
	completed_dock();var force:=ship()
	assert_bool(Dock.pay_access(port,force,GameState.resource_stockpiles,0,20).has("ok")).is_true()
	assert_bool(Dock.pay_access(port,force,GameState.resource_stockpiles,0,1).has("error")).is_true()
	assert_float(Dock.remaining_access(port,-1)).is_equal(0.0)
	assert_float(Dock.remaining_access(port,1)).is_equal(20.0)
	force.units={"heavy_galley":1}
	assert_bool(Dock.repair_plan(port,force,1,100,.04,true).is_empty()).is_true()

func test_saved_dock_and_observation_validate_and_reject_corruption()->void:
	completed_dock();var force:=ship()
	GameState.known_discoveries.append("hull_condition_surveys");GameState.discovery_adoption.hull_condition_surveys=1.0
	op.repair_at_base(force,port)
	var saved:Dictionary=op.export_state()
	assert_str(op.validate(saved)).is_empty()
	var broken:=saved.duplicate(true);broken.bases[0].dock_service.access_used=INF
	assert_str(op.validate(broken)).is_not_empty()
	broken=saved.duplicate(true);broken.forces[0].hull_survey.condition=-.1
	assert_str(op.validate(broken)).is_not_empty()
	saved.bases[0].erase("dock_service");saved.forces[0].erase("hull_survey");saved.forces[0].erase("dock_service_day")
	assert_str(op.validate(saved)).is_empty()

func test_secondary_port_cannot_spend_primary_dock_supplies()->void:
	GameState.player_settlements.append({"id":"docktown","name":"Docktown","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	port.city_id="docktown"
	var primary:=GameState.resource_stockpiles.duplicate()
	assert_bool(op.build_dock(int(port.id)).has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(primary)
	SettlementModel.with_city_resources("docktown",func()->void:
		for item:String in Dock.BILL:GameState.resource_stockpiles[item]=float(Dock.BILL[item]))
	assert_bool(op.build_dock(int(port.id)).has("ok")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(primary)
	var city:Dictionary=SettlementModel.settlement_record("docktown")
	assert_float(float(city.local_resources.resource_stockpiles["Launch Cradles"])).is_equal(0.0)
	city.occupied_by="other"
	var force:={"owner":"player","base_id":port.id,"domain":"navy","units":{"war_canoe":1},"condition":.5,"position":port.position}
	assert_bool(op.repair_at_base(force,port).has("error")).is_true()

func test_export_import_preserves_unfinished_dock_work_and_access_usage()->void:
	assert_bool(op.build_dock(int(port.id)).has("ok")).is_true()
	Dock.construct(port,40,0)
	var payload:Dictionary=op.export_state();var id:=int(port.id)
	op.reset();op.import_state(payload);port=op.base(id)
	assert_float(float(port.dock_service.work_done)).is_equal(40.0)
	assert_float(Dock.construct(port,999,1)).is_equal(200.0)
	var force:=ship()
	Dock.pay_access(port,force,GameState.resource_stockpiles,1,12)
	payload=op.export_state();op.reset();op.import_state(payload);port=op.base(id)
	assert_float(Dock.remaining_access(port,1)).is_equal(8.0)

func test_naval_summary_reports_dated_inspection_without_changing_condition()->void:
	completed_dock();var force:=ship()
	GameState.known_discoveries.append("hull_condition_surveys");GameState.discovery_adoption.hull_condition_surveys=1.0
	op.repair_at_base(force,port)
	var panel=load("res://scripts/hud/naval_command_panel.gd").new();auto_free(panel)
	panel.op=op
	var condition:=float(force.condition)
	assert_str(panel._force_summary(force)).contains("Hull survey: day 0")
	assert_float(float(force.condition)).is_equal(condition)

func test_automatic_port_investment_installs_only_after_paid_cradle_production()->void:
	ship()
	GameState.population_allocations.Construction=40
	GameState.population_allocations.Crafting=40
	GameState.resource_stockpiles["Launch Cradles"]=0.0
	var industry=preload("res://scripts/civilian_industry.gd")
	var cradle_id:=""
	for id:String in industry.PRODUCTS:
		if industry.PRODUCTS[id].output=="Launch Cradles":cradle_id=id;break
	assert_str(cradle_id).is_not_empty()
	var spec:Dictionary=industry.PRODUCTS[cradle_id]
	GameState.known_discoveries.append(spec.gate);GameState.discovery_adoption[spec.gate]=1.0
	for material:String in spec.materials:GameState.resource_stockpiles[material]=1000.0
	for material:String in spec.tooling:GameState.resource_stockpiles[material]=1000.0
	var planner=preload("res://scripts/naval_dock_investment.gd")
	var order:Dictionary=planner.recommendation()
	assert_str(String(order.get("item",""))).is_equal(cradle_id)
	assert_bool(port.has("dock_service")).is_false()
	preload("res://scripts/civilization_controller.gd").production_order("player",order)
	assert_array(MilitaryCampaign.equipment_queue).is_not_empty()
	if MilitaryCampaign.equipment_queue.is_empty():return
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	preload("res://scripts/persistent_production.gd").advance(MilitaryCampaign,job,float(spec.days)*4)
	assert_int(int(job.completed)).is_equal(4)
	planner.recommendation()
	assert_bool(port.has("dock_service")).is_true()
	assert_float(float(GameState.resource_stockpiles["Launch Cradles"])).is_equal(0.0)
	assert_bool(Dock.building(port)).is_true()

func test_actual_install_button_pays_for_selected_port()->void:
	var panel=load("res://scripts/hud/naval_command_panel.gd").new();auto_free(panel)
	get_tree().root.add_child(panel)
	var used:=false
	for child:Node in panel.find_children("*","Button",true,false):
		if child.text=="Build timber-vessel dock access":child.pressed.emit();used=true;break
	assert_bool(used).is_true()
	assert_bool(port.has("dock_service")).is_true()
	assert_float(float(GameState.resource_stockpiles["Launch Cradles"])).is_equal(996.0)

func test_full_save_restores_paid_dock_access_and_survey()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	completed_dock();var force:=ship()
	GameState.known_discoveries.append("hull_condition_surveys");GameState.discovery_adoption.hull_condition_surveys=1.0
	op.repair_at_base(force,port)
	var base_id:=int(port.id);var force_id:=int(force.id)
	var used:=float(port.dock_service.access_used);var stock:=GameState.resource_stockpiles.duplicate()
	var slot:="naval_dock_%d" % OS.get_process_id()
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.get("ok",false)).override_failure_message(str(saved)).is_true()
	op.reset()
	var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	op=MilitaryCampaign.joint_operations;port=op.base(base_id);force=op.force(force_id)
	assert_float(float(port.dock_service.access_used)).is_equal(used)
	assert_int(int(force.hull_survey.day)).is_equal(0)
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_owned_actor_installs_imported_dock_and_full_save_retains_partial_work()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("dock_owner",9393)
	var ids:Array[int]=[]
	var human_stock:=GameState.resource_stockpiles.duplicate()
	WorldSimulation.scoped("dock_owner",func()->void:
		var state=WorldSimulation.state;var model=WorldSimulation.settlements;var campaign=WorldSimulation.military
		state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
		state.settlement_completed.assign(["Hearth Circle"]);model.ensure_founded()
		state.population_allocations.Construction=40
		for id:String in ["aerostat_observation","river_craft","dry_dock_services"]:
			state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
		for item:String in Dock.BILL:state.resource_stockpiles[item]=1000.0
		state.resource_stockpiles["Iron Ore"]=1000.0
		var owned=campaign.joint_operations
		assert_bool(owned.build_base(String(state.player_settlements[0].id),"air").has("ok")).is_true()
		var local_port:Dictionary=owned.state.bases[0];local_port.domain="navy";local_port.construction_work=30.0
		campaign.military_inventory["war_canoe_equipment"]=1
		assert_bool(owned.commission(int(local_port.id),"war_canoe",1).has("ok")).is_true()
		preload("res://scripts/naval_dock_investment.gd").recommendation()
		assert_bool(local_port.has("dock_service")).is_true()
		assert_bool("launching_cradles" in state.known_discoveries).is_false()
		assert_float(float(state.resource_stockpiles["Launch Cradles"])).is_equal(996.0)
		Dock.construct(local_port,40,0);ids.append(int(local_port.id)))
	assert_dict(GameState.resource_stockpiles).is_equal(human_stock)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var slot:="naval_actor_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	WorldSimulation.scoped("dock_owner",func()->void:
		var local_port:Dictionary=WorldSimulation.military.joint_operations.base(ids[0])
		assert_float(float(local_port.dock_service.work_done)).is_equal(40.0)
		assert_float(Dock.construct(local_port,999,1)).is_equal(200.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Launch Cradles"])).is_equal(996.0))
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_secondary_dock_waits_for_real_cradle_delivery()->void:
	ship()
	GameState.player_settlements.append({"id":"docktown","name":"Docktown","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	port.city_id="docktown"
	GameState.population_allocations.Construction=100;GameState.population_allocations.Logistics=100
	GameState.society_capacities.logistics=.8;GameState.society_capacities.institutions=.8
	CivilizationSystem.register_player_origin(Vector2.ZERO);CivilizationSystem.record_player_travel(Vector2(10,0))
	GameState.resource_stockpiles["Launch Cradles"]=4.0
	SettlementModel.with_city_resources("docktown",func()->void:
		for item:String in Dock.BILL:GameState.resource_stockpiles[item]=float(Dock.BILL[item])
		GameState.resource_stockpiles["Launch Cradles"]=0.0)
	var planner=preload("res://scripts/naval_dock_investment.gd")
	planner.recommendation();assert_bool(port.has("dock_service")).is_false()
	SettlementModel.process_city_trade()
	var shipped:=0.0
	for shipment:Dictionary in GameState.city_trade_shipments:
		if shipment.resource=="Launch Cradles":shipped+=float(shipment.quantity)
	assert_float(shipped).is_equal(4.0)
	assert_float(float(GameState.resource_stockpiles["Launch Cradles"])).is_equal(0.0)
	planner.recommendation();assert_bool(port.has("dock_service")).is_false()
	GameState.elapsed_days=20;GameState.society_capacities.logistics=0.0
	SettlementModel.process_city_trade();planner.recommendation()
	assert_bool(port.has("dock_service")).is_true()
	var city:Dictionary=SettlementModel.settlement_record("docktown")
	assert_float(float(city.local_resources.resource_stockpiles["Launch Cradles"])).is_equal(0.0)
