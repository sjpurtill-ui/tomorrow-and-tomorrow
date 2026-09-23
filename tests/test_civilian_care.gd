extends GdUnitTestSuite
const Care=preload("res://scripts/civilian_care.gd")
const F=preload("res://scripts/civilian_care_fabric.gd")
const S=preload("res://scripts/civilian_care_state.gd")
const BillStock=preload("res://scripts/bill_stock.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(772241);ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	for id:String in Care.IDS.values():GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	GameState.population_allocations.Knowledge=12
	GameState.resource_stockpiles=supplies(100.0,100.0,100.0);GameState.resource_stockpiles.Food=10000.0
## Record clay, water and the raw materials and Civilian Goods of `cloth` woven cloth.
func supplies(clay:float,water:float,cloth:float)->Dictionary:
	return BillStock.add_scaled({"Clay":clay,"Freshwater":water},F.CLOTH_UNIT,cloth/F.CARE_CLOTH)
func test_care_reserves_knowledge_before_and_after_service()->void:
	assert_float(Care.staff()).is_equal(3.0)
	var before:=GameState.effective_workers("Knowledge")
	assert_float(before).is_equal(9.0)
	Care.process_day(.8)
	assert_float(GameState.effective_workers("Knowledge")).is_equal(before)
	assert_float(float(Care.data().report.staff_used)).is_less_equal(3.0)
	Care.data().staff_share=0
	assert_float(GameState.effective_workers("Knowledge")).is_equal(12.0)
func test_absent_scholars_are_removed_before_care_share()->void:
	GameState.society_exchange.scholar_visits={"away":{"source":"player","depart_day":0,"home_day":10}}
	assert_float(GameState.effective_workers("Knowledge",false,true)).is_equal(11.0)
	assert_float(Care.staff()).is_equal(2.75)
	assert_float(GameState.effective_workers("Knowledge")).is_equal(8.25)
	Care.process_day(.8)
	assert_float(GameState.effective_workers("Knowledge")).is_equal(8.25)
func test_paid_observation_and_care_are_once_daily()->void:
	var stock:=GameState.resource_stockpiles.duplicate()
	var report:=Care.process_day(.8).duplicate(true)
	assert_float(float(report.observed)).is_greater(0)
	assert_float(float(report.supported)).is_greater(0)
	assert_float(float(GameState.resource_stockpiles.Clay)).is_equal_approx(float(stock.Clay)-float(report.record_clay_used),.000001)
	assert_float(float(report.water_used)).is_equal_approx(float(report.supported)*F.CARE_WATER,.000001)
	# Each supported case pays water plus the flattened cloth (which itself may name water).
	for item:String in F.CARE_UNIT:
		assert_float(float(GameState.resource_stockpiles[item])).is_equal_approx(float(stock[item])-float(report.supported)*float(F.CARE_UNIT[item]),.000001)
	var after:=GameState.resource_stockpiles.duplicate()
	assert_dict(Care.process_day(.8)).is_equal(report)
	assert_dict(GameState.resource_stockpiles).is_equal(after)
func test_observation_alone_does_not_grant_recovery()->void:
	GameState.known_discoveries.erase("nursing_care_organization")
	var report:=Care.process_day(.8)
	assert_float(float(report.observed)).is_greater(0)
	assert_float(float(report.additional_recovery)).is_equal(0.0)
	assert_float(float(report.health_relief)).is_equal(0.0)
func test_shortage_prevents_care_and_preserves_unspent_supplies()->void:
	GameState.resource_stockpiles.Clay=0.0
	var before:=GameState.resource_stockpiles.duplicate()
	var report:=Care.process_day(.8)
	assert_float(float(report.supported)).is_equal(0.0)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	GameState.elapsed_days=1;GameState.resource_stockpiles.Clay=100;GameState.resource_stockpiles.Freshwater=0
	report=Care.process_day(.8)
	assert_float(float(report.observed)).is_greater(0)
	assert_float(float(report.supported)).is_equal(0.0)
	assert_float(float(report.health_relief)).is_equal(0.0)
func test_population_bound_and_record_count()->void:
	for day in 40:
		F.admit(Care.data(),400,20,.5,day)
		Care.data().last_day=day
	assert_int(Care.data().episodes.size()).is_less_equal(F.MAX_EPISODES)
	assert_float(F.outstanding(Care.data())).is_less_equal(400.0)
	F.fit_population(Care.data(),20)
	assert_float(F.outstanding(Care.data())).is_equal_approx(20,.0001)
	assert_bool(S.valid(Care.data(),20)).is_true()
func test_malformed_and_legacy_state()->void:
	assert_bool(S.valid_state({})).is_true()
	Care.process_day(.8)
	assert_bool(S.valid(Care.data())).override_failure_message(str(Care.data())).is_true()
	var bad:=Care.data().duplicate(true);bad.staff_share=INF
	assert_bool(S.valid(bad)).is_false()
	bad=Care.data().duplicate(true);bad.episodes[0].observation_day=100
	assert_bool(S.valid(bad)).is_false()
func test_secondary_city_cannot_borrow_primary_supplies()->void:
	GameState.player_settlements.append({"id":"care_city","name":"Care City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	var before:=GameState.resource_stockpiles.duplicate()
	SettlementModel.with_city_resources("care_city",func()->void:
		SettlementModel.with_local_population(func()->void:
			var report:=Care.process_day(.8)
			assert_float(float(report.supported)).is_equal(0.0)
			assert_float(F.outstanding(Care.data())).is_greater(0.0)))
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_bool(Care.data().episodes.is_empty()).is_true()
func test_research_capacity_conserves_absence_and_care_in_both_orders()->void:
	DiscoverySystem.initialize()
	GameState.research_subcategory_allocations={"health":{"General health":1}}
	GameState.society_exchange.scholar_visits={"away":{"source":"player","depart_day":0,"home_day":10}}
	Care.data().staff_share=0
	var baseline:=DiscoverySystem.research_capacity_for("health","General health")
	assert_float(float(baseline.researchers)).is_equal(11.0)
	Care.data().staff_share=.25
	var first:=DiscoverySystem.research_capacity_for("health","General health")
	assert_float(float(first.researchers)).is_equal(8.25)
	Care.process_day(.8)
	var second:=DiscoverySystem.research_capacity_for("health","General health")
	assert_float(float(second.researchers)).is_equal(float(first.researchers))
	GameState.elapsed_days=1;Care.process_day(.8)
	assert_float(float(DiscoverySystem.research_capacity_for("health","General health").researchers)).is_equal(8.25)
func test_nursing_continuity_needs_real_followup_and_breaks_on_shortage()->void:
	F.admit(Care.data(),400,1,.8,0)
	var methods:=Care.methods(GameState)
	var first:=F.serve(Care.data(),GameState.resource_stockpiles,12,methods,0)
	assert_float(float(first.additional_recovery)).is_equal_approx(.03,.000001)
	var second:=F.serve(Care.data(),GameState.resource_stockpiles,12,methods,1)
	assert_float(float(second.additional_recovery)/float(second.supported)).is_greater(.03)
	GameState.resource_stockpiles.Freshwater=0
	F.serve(Care.data(),GameState.resource_stockpiles,12,methods,2)
	assert_float(float(Care.data().episodes[0].continuity)).is_equal(0.0)

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_travel_and_occupation_release_staff_without_service()->void:
	GameState.convoy_traveling=true
	var stock:=GameState.resource_stockpiles.duplicate()
	assert_float(Care.staff()).is_equal(0.0)
	assert_float(GameState.effective_workers("Knowledge")).is_equal(12.0)
	assert_float(float(Care.process_day(.8).supported)).is_equal(0.0)
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
	GameState.elapsed_days=1;GameState.convoy_traveling=false
	GameState.player_settlements[0].occupied_by="occupier"
	assert_float(Care.staff()).is_equal(0.0)
	assert_float(float(Care.process_day(.8).supported)).is_equal(0.0)
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
func test_report_rejects_unpaid_work_and_unbounded_health_bonus()->void:
	Care.process_day(.8)
	var bad:=Care.data().duplicate(true);bad.report.health_relief=1
	assert_bool(S.valid(bad)).is_false()
	bad=Care.data().duplicate(true);bad.report.water_used=0
	assert_bool(S.valid(bad)).is_false()
	bad=Care.data().duplicate(true);bad.report.day=1
	assert_bool(S.valid(bad)).is_false()
func test_full_save_restores_human_and_actor_care_without_double_payment()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	Care.process_day(.8)
	GameState.elapsed_days=1;Care.process_day(.8)
	var human:=Care.data().duplicate(true)
	var stock:=GameState.resource_stockpiles.duplicate(true)
	WorldSimulation.create_actor("care_owner",9393)
	WorldSimulation.scoped("care_owner",func()->void:
		var state=WorldSimulation.state
		state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
		state.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
		state.population_allocations.Knowledge=8
		for id:String in Care.IDS.values():state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
		state.resource_stockpiles=supplies(10.0,10.0,10.0)
		var report:=Care.process_day(.8)
		assert_float(float(report.supported)).is_greater(0)
		assert_float(float(report.staff_available)).is_equal(2.0))
	assert_dict(Care.data()).is_equal(human)
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
	var slot:="civilian_care_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.civilian_care=F.empty_state();WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_dict(Care.data()).is_equal(human)
	Care.process_day(.8)
	assert_dict(GameState.resource_stockpiles).is_equal(stock)
	WorldSimulation.scoped("care_owner",func()->void:
		assert_float(float(Care.data().report.staff_available)).is_equal(2.0)
		var actor_stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		Care.process_day(.8)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(actor_stock))

func test_pulse_assessment_changes_next_round_priority()->void:
	var plain:=F.empty_state();var pulse:=F.empty_state()
	for data:Dictionary in [plain,pulse]:
		F.admit(data,400,1,.51,0);F.admit(data,400,1,.99,0)
		F.serve(data,{"Clay":100.0},10,{"rounds":true,"pulse":is_same(data,pulse)},0)
	# Both severities occupy the same coarse category without pulse assessment.
	assert_float(float(plain.episodes[0].assessed_severity)).is_equal(.5)
	assert_float(float(plain.episodes[1].assessed_severity)).is_equal(.5)
	F.serve(pulse,supplies(100.0,100.0,100.0),1.25,{"rounds":true,"pulse":true,"nursing":true},1)
	assert_float(float(pulse.episodes[0].severity)).is_equal(.99)
	assert_float(float(pulse.episodes[0].cared)).is_greater(float(pulse.episodes[1].cared))
func test_daily_consequence_applies_only_paid_health_relief()->void:
	var outcomes:Array=[]
	for enabled:bool in [false,true]:
		WorldSimulation.clear();WorldSimulation.create_actor("care_comparison",5591)
		WorldSimulation.scoped("care_comparison",func()->void:
			var state=WorldSimulation.state
			state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
			state.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
			state.population_health=.5;state.population_allocations.Knowledge=12
			state.resource_stockpiles=supplies(100.0,100.0,100.0);state.resource_stockpiles.Food=10000.0
			state.water_metrics={"intake_ratio":1.0,"days":10.0}
			for id:String in Care.IDS.values():state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
			Care.data().enabled=enabled
			WorldSimulation.consequences.process_day({"traveling":false})
			outcomes.append({"health":state.population_health,"relief":Care.data().report.health_relief,"supported":Care.data().report.supported}))
	assert_float(float(outcomes[0].relief)).is_equal(0.0)
	assert_float(float(outcomes[1].supported)).is_greater(0.0)
	assert_float(float(outcomes[1].health)).is_greater(float(outcomes[0].health))
	assert_float(float(outcomes[1].health)-float(outcomes[0].health)).is_equal_approx(float(outcomes[1].relief)*.022,.00000001)
func test_care_supplies_travel_to_secondary_city_before_use()->void:
	GameState.player_settlements.append({"id":"care_city","name":"Care City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	CivilizationSystem.register_player_origin(Vector2.ZERO);CivilizationSystem.record_player_travel(Vector2(10,0))
	GameState.society_capacities.logistics=.8;GameState.society_capacities.institutions=.8
	GameState.population_allocations.Logistics=100
	SettlementModel.with_city_resources("care_city",func()->void:GameState.resource_stockpiles.Food=10000.0)
	# Care cloth travels as its raw materials and Civilian Goods.
	var before:=GameState.resource_stockpiles.duplicate()
	SettlementModel.process_city_trade()
	var shipped:Dictionary={};var total:=0.0
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.destination_id)=="care_city" and F.CLOTH_UNIT.has(String(shipment.resource)):
			shipped[shipment.resource]=float(shipped.get(shipment.resource,0.0))+float(shipment.quantity);total+=float(shipment.quantity)
	assert_float(total).is_greater(0)
	for item:String in shipped:
		assert_float(float(GameState.resource_stockpiles[item])+float(shipped[item])).is_equal_approx(float(before[item]),.000001)
		assert_float(float(SettlementModel.city_resource_snapshot("care_city").stores.get(item,0))).is_equal(0.0)
	GameState.society_capacities.logistics=0;GameState.elapsed_days=20
	SettlementModel.process_city_trade()
	for item:String in shipped:
		assert_float(float(SettlementModel.city_resource_snapshot("care_city").stores.get(item,0))).is_equal_approx(float(shipped[item]),.000001)
func test_selected_city_care_signature_and_duty_are_local()->void:
	GameState.player_settlements.append({"id":"care_city","name":"Care City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	GameState.selected_player_settlement_id="care_city"
	var panel=preload("res://scripts/hud/content/dock_detail_health.gd").new(null,null)
	var first:Array=panel.signature()
	SettlementModel.with_city_resources("care_city",func()->void:Care.set_share(.5))
	var second:Array=panel.signature()
	assert_bool(first==second).is_false()
	assert_float(float(Care.data().staff_share)).is_equal(.25)
	assert_str(String(second[0])).is_equal("care_city")
