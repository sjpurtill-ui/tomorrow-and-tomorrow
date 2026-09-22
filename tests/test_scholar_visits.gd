extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Scholars=preload("res://scripts/scholar_visits.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(777);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=280
	GameState.population_allocations.Knowledge=30;GameState.population_allocations.Administration=12
	GameState.food_security=1;GameState.population_health=.95;GameState.water_metrics={"intake_ratio":1.0}
	GameState.simulation_metrics={"food_days":60,"food_intake_ratio":1.0,"security":.9,"cohesion":.9}
	GameState.resource_stockpiles.Food=20000;GameState.food_stocks={"Preserved food":20000.0}
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.create_actor("neighbor",777,Vector2(30,0));WorldSimulation.actors.neighbor.controller="manual"
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.state.ensure_population_total(200);WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.housing_capacity=140
		WorldSimulation.state.food_security=.6;WorldSimulation.state.population_health=.7
		WorldSimulation.state.simulation_metrics={"food_days":30,"food_intake_ratio":1.0,"security":.3,"cohesion":.3}
		WorldSimulation.state.population_allocations.Crafting=8
		WorldSimulation.state.resource_stockpiles.Clay=20.0;WorldSimulation.state.resource_stockpiles.Food=20000
		WorldSimulation.state.food_stocks={"Preserved food":20000.0}
		WorldSimulation.state.known_discoveries.assign(["clay_shaping"]);WorldSimulation.state.discovery_adoption.clay_shaping=1.0
		E.policy("balanced","open"))
	CivilizationSystem.civilizations.clear();CivilizationSystem.civilizations.append({"id":"neighbor","name":"Neighbor","world_position":Vector2(30,0),"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false}})
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func prepare()->void:
	GameState.elapsed_days=100000
	GameState.known_discoveries.assign(["experimental_controls","public_schools","clay_testing"])
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]

func trip()->Dictionary:
	return {"civ_id":"neighbor","depart_day":100000,"arrival_day":100003,"return_day":100006,"personnel":2,"target_position":{"x":30.0,"z":0.0},"purpose":"goodwill","research_subject":"clay_shaping","gift_resource":"Stone","gift_amount":44.0}

func test_visit_reserves_source_staff_and_teaches_only_after_delivery()->void:
	prepare()
	var provider:=E.owner_state("neighbor")
	provider.elapsed_days=100000
	var original:float=provider.effective_workers("Knowledge")
	var dispatched:=Scholars.dispatch("neighbor","clay_shaping","Stone")
	assert_bool(dispatched.get("ok",false)).override_failure_message(str(dispatched)).is_true()
	if not dispatched.get("ok",false):return
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	assert_bool(mission.research_refused).is_false()
	provider.elapsed_days=mission.arrival_day
	assert_float(provider.effective_workers("Knowledge")).is_equal(original-1)
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.0)
	Purchase.prepare_return(mission)
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.5)
	assert_float(Scholars.bonus("cordage",int(mission.return_day))).is_equal(1.0)
	assert_float(Scholars.bonus("clay_shaping",int(mission.scholar_contract.leave_day))).is_equal(1.0)
	provider.elapsed_days=mission.scholar_contract.home_day
	assert_float(provider.effective_workers("Knowledge")).is_equal(original)
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()

func test_refused_visit_refunds_payment_and_board_once()->void:
	prepare()
	var original_stone:float=GameState.resource_stockpiles.Stone
	var original_food:float=GameState.resource_stockpiles.Food
	var dispatched:=Scholars.dispatch("neighbor","clay_shaping","Stone")
	assert_bool(dispatched.get("ok",false)).override_failure_message(str(dispatched)).is_true()
	if not dispatched.get("ok",false):return
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.owner_state("neighbor").population_allocations.Knowledge=1
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	Purchase.prepare_return(mission)
	E.returned(mission,int(mission.return_day));E.returned(mission,int(mission.return_day))
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(original_stone)
	assert_float(absf(float(GameState.resource_stockpiles.Food)-(original_food-float(mission.provisions)))).is_less(.000001)
	assert_dict(E.owner_state("neighbor").society_exchange.get("scholar_visits",{})).is_empty()

func test_visit_survives_serialization_and_rejects_bad_chronology()->void:
	prepare()
	var dispatched:=Scholars.dispatch("neighbor","clay_shaping","Stone")
	assert_bool(dispatched.get("ok",false)).override_failure_message(str(dispatched)).is_true()
	if not dispatched.get("ok",false):return
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day));Purchase.prepare_return(mission)
	var state:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	assert_bool(E.valid(state)).is_true()
	assert_bool(E.valid_mission(JSON.parse_string(JSON.stringify(mission)))).is_true()
	GameState.society_exchange=state
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.5)
	state.scholar_visits.values()[0].home_day=0
	assert_bool(E.valid(state)).is_false()

func test_teaching_requires_host_staff_and_peace()->void:
	prepare()
	var dispatched:=Scholars.dispatch("neighbor","clay_shaping","Stone")
	assert_bool(dispatched.get("ok",false)).override_failure_message(str(dispatched)).is_true()
	if not dispatched.get("ok",false):return
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day));Purchase.prepare_return(mission)
	CivilizationSystem.civilizations[0].player_relation.at_war=true
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.0)
	CivilizationSystem.civilizations[0].player_relation.at_war=false
	GameState.population_allocations.Knowledge=0
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.0)

func test_early_gate_and_quote_do_not_read_hidden_supplier_knowledge()->void:
	prepare()
	GameState.known_discoveries.assign(["apprentice_contracts","clay_testing"])
	var terms:=Scholars.quote("neighbor","clay_shaping","Stone")
	assert_bool(terms.has("error")).is_false()
	E.owner_state("neighbor").known_discoveries.clear()
	assert_dict(Scholars.quote("neighbor","clay_shaping","Stone")).is_equal(terms)
	assert_bool(Purchase.available()).is_false()

func test_actual_panel_dispatches_scholar_invitation()->void:
	prepare()
	GameState.known_discoveries.assign(["apprentice_contracts","clay_testing"])
	var panel:VBoxContainer=auto_free(preload("res://scripts/hud/research_purchase_panel.gd").new())
	panel.subject="clay_shaping";add_child(panel)
	panel.resources.select(4);panel.refresh();panel.send.pressed.emit()
	assert_str(CivilizationSystem.diplomatic_mission.get("research_mode","")).is_equal("scholar")

func test_real_embassy_settles_payment_once_and_reserves_no_new_population()->void:
	prepare();WorldSimulation.enabled=true
	var provider:=E.owner_state("neighbor")
	var population:float=provider.population_exact
	var stock:float=provider.resource_stockpiles.get("Stone",0)
	var dispatched:=Scholars.dispatch("neighbor","clay_shaping","Stone")
	assert_bool(dispatched.get("ok",false)).override_failure_message(str(dispatched)).is_true()
	if not dispatched.get("ok",false):return
	var mission:=CivilizationSystem.diplomatic_mission.duplicate(true)
	CivilizationSystem._process_diplomatic_mission(int(mission.arrival_day))
	CivilizationSystem._process_diplomatic_mission(int(mission.return_day))
	CivilizationSystem._process_diplomatic_mission(int(mission.return_day)+1)
	assert_float(float(provider.resource_stockpiles.Stone)).is_equal(stock+float(mission.gift_amount))
	assert_float(provider.population_exact).is_equal(population)
	assert_float(Scholars.bonus("clay_shaping",int(mission.return_day))).is_equal(1.5)
	assert_bool(Scholars.quote("neighbor","clay_shaping","Stone").has("error")).is_true()

func test_absence_prevents_overbooking_and_expired_register_is_pruned()->void:
	prepare()
	var provider:=E.owner_state("neighbor")
	provider.population_allocations.Knowledge=2
	var mission:=trip();mission.research_mode="scholar"
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	provider.elapsed_days=mission.arrival_day
	var other:=trip();other.depart_day+=1
	other.research_mode="scholar"
	E.envoy_arrived(CivilizationSystem,other,int(other.arrival_day))
	assert_bool(other.research_refused).is_true()
	Purchase.prepare_return(mission)
	Scholars.advance(int(mission.scholar_contract.home_day))
	assert_dict(E.data().scholar_visits).is_empty()

func test_malformed_scholar_mission_metadata_is_rejected()->void:
	assert_bool(E.valid_mission({"research_mode":"scholar"})).is_false()
	assert_bool(E.valid_mission({"research_subject":"clay_shaping","scholar_provisions":"food"})).is_false()
	assert_bool(E.valid_mission({"research_subject":"clay_shaping","scholar_contract":[]})).is_false()
