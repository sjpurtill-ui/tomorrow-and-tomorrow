extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
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
	GameState.known_discoveries.assign(["experimental_controls","public_schools"])
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]

func trip()->Dictionary:
	return {"civ_id":"neighbor","depart_day":100000,"arrival_day":100003,"return_day":100006,"personnel":2,"target_position":{"x":30.0,"z":0.0},"purpose":"goodwill","research_subject":"clay_shaping","gift_resource":"Stone","gift_amount":44.0}

func test_quote_requires_assessment_capability_but_does_not_reveal_supplier_knowledge()->void:
	prepare()
	var before:=GameState.resource_stockpiles.duplicate(true)
	var offer:=Purchase.quote("neighbor","clay_shaping","Stone")
	assert_bool(offer.get("ok",false)).is_true()
	E.owner_state("neighbor").known_discoveries.clear()
	assert_dict(Purchase.quote("neighbor","clay_shaping","Stone")).is_equal(offer)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(float(before.Stone))
	assert_float(float(GameState.resource_stockpiles.Food)).is_equal(float(before.Food))
	GameState.known_discoveries.erase("experimental_controls")
	assert_bool(Purchase.quote("neighbor","clay_shaping","Stone").has("error")).is_true()

func test_dispatch_reserves_real_payment_and_study_waits_for_return_and_examination()->void:
	prepare()
	var before:float=GameState.resource_stockpiles.Stone
	assert_bool(Purchase.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before-float(mission.gift_amount))
	assert_dict(P.evidence("clay_shaping")).is_empty()
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	assert_bool(mission.research_refused).is_false()
	assert_dict(E.data().collections).is_empty()
	Purchase.prepare_return(mission)
	E.returned(mission,int(mission.return_day))
	assert_dict(P.evidence("clay_shaping")).is_empty()
	GameState.population_allocations.Knowledge=60
	for day in range(100007,100100):E.advance(day)
	assert_bool(P.evidence("clay_shaping").get("research_purchase",false)).is_true()
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_float(P.multiplier(DiscoverySystem.discovery_definition("clay_shaping"))).is_equal(2.5)

func test_refusal_refunds_once_and_never_awards_a_study()->void:
	prepare()
	var mission:=trip();E.owner_state("neighbor").known_discoveries.clear()
	var before:float=GameState.resource_stockpiles.Stone
	GameState.resource_stockpiles.Stone-=float(mission.gift_amount)
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	assert_bool(mission.research_refused).is_true()
	Purchase.prepare_return(mission)
	E.returned(mission,int(mission.return_day));E.returned(mission,int(mission.return_day)+1)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before)
	assert_bool(E.data().collections.has(Purchase.key("neighbor","clay_shaping"))).is_false()

func test_unadopted_or_unstaffed_or_guarded_supplier_cannot_sell_a_study()->void:
	prepare()
	var provider:=E.owner_state("neighbor")
	provider.discovery_adoption.clay_shaping=.1
	var mission:=trip();E.envoy_arrived(CivilizationSystem,mission,100003)
	assert_bool(mission.research_refused).is_true()
	provider.discovery_adoption.clay_shaping=1;provider.population_allocations.Knowledge=0
	mission=trip();E.envoy_arrived(CivilizationSystem,mission,100003)
	assert_bool(mission.research_refused).is_true()
	provider.population_allocations.Knowledge=20;provider.society_exchange.sharing_policy="guarded"
	mission=trip();E.envoy_arrived(CivilizationSystem,mission,100003)
	assert_bool(mission.research_refused).is_true()

func test_missing_or_hostile_destination_never_creates_a_purchased_report()->void:
	prepare()
	var mission:=trip();mission.target_position={"x":9000.0,"z":0.0}
	E.envoy_arrived(CivilizationSystem,mission,100003);Purchase.prepare_return(mission)
	assert_bool(mission.research_refused).is_true()
	mission=trip();CivilizationSystem.civilizations[0].player_relation.at_war=true
	E.envoy_arrived(CivilizationSystem,mission,100003);Purchase.prepare_return(mission)
	assert_bool(mission.research_refused).is_true()

func test_purchase_metadata_roundtrips_and_rejects_invalid_types()->void:
	prepare()
	var mission:=trip();E.envoy_arrived(CivilizationSystem,mission,100003)
	assert_bool(E.valid_mission(JSON.parse_string(JSON.stringify(mission)))).is_true()
	mission.research_refused="no"
	assert_bool(E.valid_mission(mission)).is_false()

func test_no_duplicate_purchase_when_the_report_is_already_in_the_collection()->void:
	prepare()
	var mission:=trip();E.envoy_arrived(CivilizationSystem,mission,100003);E.returned(mission,100006)
	assert_bool(Purchase.quote("neighbor","clay_shaping","Stone").has("error")).is_true()

func test_ordinary_embassy_return_settles_both_resource_ledgers_once()->void:
	prepare();WorldSimulation.enabled=true
	var provider:=E.owner_state("neighbor")
	var source_before:=float(provider.resource_stockpiles.get("Stone",0))
	var buyer_before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(Purchase.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	var paid:=float(mission.gift_amount);var arrival:=int(mission.arrival_day);var returned:=int(mission.return_day)
	CivilizationSystem._process_diplomatic_mission(arrival)
	assert_dict(E.data().collections).is_empty()
	CivilizationSystem._process_diplomatic_mission(returned)
	assert_dict(CivilizationSystem.diplomatic_mission).is_empty()
	assert_float(float(provider.resource_stockpiles.get("Stone",0))).is_equal(source_before+paid)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(buyer_before-paid)
	assert_bool(E.data().collections.has(Purchase.key("neighbor","clay_shaping"))).is_true()
	CivilizationSystem._process_diplomatic_mission(returned+1)
	assert_float(float(provider.resource_stockpiles.get("Stone",0))).is_equal(source_before+paid)

func test_ordinary_refused_embassy_returns_payment_without_paying_supplier()->void:
	prepare();WorldSimulation.enabled=true
	var provider:=E.owner_state("neighbor");provider.society_exchange.sharing_policy="guarded"
	var source_before:=float(provider.resource_stockpiles.get("Stone",0));var buyer_before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(Purchase.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var arrival:=int(CivilizationSystem.diplomatic_mission.arrival_day);var returned:=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(arrival);CivilizationSystem._process_diplomatic_mission(returned)
	assert_float(float(provider.resource_stockpiles.get("Stone",0))).is_equal(source_before)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(buyer_before)
	assert_bool(CivilizationSystem.diplomatic_history[0].accepted).is_false()

func test_research_panel_dispatches_the_reviewed_offer_through_the_live_action()->void:
	prepare()
	var panel:VBoxContainer=auto_free(preload("res://scripts/hud/research_purchase_panel.gd").new())
	panel.subject="clay_shaping";panel.size=Vector2(280,500);get_tree().root.add_child(panel)
	assert_bool(panel.send.disabled).is_false()
	assert_str(panel.summary.text).contains("supplier may refuse")
	panel.resources.select(4);panel.refresh()
	panel.send.pressed.emit()
	assert_str(CivilizationSystem.diplomatic_mission.research_subject).is_equal("clay_shaping")
	assert_str(CivilizationSystem.diplomatic_mission.gift_resource).is_equal("Stone")
	assert_bool(panel.send.disabled).is_true()

const Planner=preload("res://scripts/research_acquisition_planner.gd")
func examined_report()->void:
	E.data().collections["returned"]={"id":"returned","kind":"knowledge","source_id":"neighbor","discovery_id":"clay_shaping","study":1.0,"returned_day":100000,"work":90.0}
func test_ai_requests_stronger_study_from_examined_evidence_without_supplier_omniscience()->void:
	prepare();examined_report()
	var expected:=Planner.recommendation()
	assert_str(expected.subject).is_equal("clay_shaping")
	assert_str(expected.resource).is_equal("Stone")
	E.owner_state("neighbor").known_discoveries.clear()
	assert_dict(Planner.recommendation()).is_equal(expected)
	E.data().collections.returned.study=.5
	assert_dict(Planner.recommendation()).is_empty()
	E.data().collections.returned.study=1.0;E.data().collections.returned.returned_day=100001
	assert_dict(Planner.recommendation()).is_empty()
func test_ai_purchase_order_reserves_payment_and_does_not_unlock_discovery()->void:
	prepare();examined_report()
	var before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(preload("res://scripts/civilization_controller.gd").research_purchase_orders("player",{})).is_true()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(before)
	assert_str(String(CivilizationSystem.diplomatic_mission.research_subject)).is_equal("clay_shaping")
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_dict(Planner.recommendation()).is_empty()
func test_ai_retains_scarce_materials_and_does_not_commission_during_emergencies()->void:
	prepare();examined_report()
	assert_dict(Planner.recommendation({"hungry":true})).is_empty()
	assert_dict(Planner.recommendation({"at_war":true})).is_empty()
	for resource:String in ["Timber","Fiber Plants","Clay","Stone"]:GameState.resource_stockpiles[resource]=100.0
	assert_dict(Planner.recommendation()).is_empty()
func test_ai_waits_after_previous_research_trip_and_ignores_already_strong_study()->void:
	prepare();examined_report()
	CivilizationSystem.diplomatic_history.append({"civ_id":"neighbor","research_subject":"clay_shaping","returned_day":99900})
	assert_dict(Planner.recommendation()).is_empty()
	GameState.elapsed_days=100266
	assert_bool(Planner.recommendation().is_empty()).is_false()
	E.data().collections["weaker"]=E.data().collections.returned.duplicate(true)
	E.data().collections.returned.research_purchase=true
	assert_dict(Planner.recommendation()).is_empty()
