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
	GameState.known_discoveries.assign(["experimental_controls","public_schools"])
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]

func trip()->Dictionary:
	return {"civ_id":"neighbor","depart_day":100000,"arrival_day":100003,"return_day":100006,"personnel":2,"target_position":{"x":30.0,"z":0.0},"purpose":"goodwill","research_subject":"clay_shaping","gift_resource":"Stone","gift_amount":44.0}


const Joint=preload("res://scripts/research_partnerships.gd")
func joint_prepare()->void:
	prepare();WorldSimulation.enabled=true
	var peer:=E.owner_state("neighbor")
	peer.known_discoveries.assign(["public_schools","experimental_controls"])
	peer.elapsed_days=GameState.elapsed_days

func complete_trip()->Dictionary:
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	CivilizationSystem._process_diplomatic_mission(int(mission.arrival_day))
	var completed:=mission.duplicate(true)
	CivilizationSystem._process_diplomatic_mission(int(completed.return_day))
	GameState.elapsed_days=int(completed.return_day)
	return completed

func begin_project()->void:
	joint_prepare()
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:=complete_trip()
	assert_bool(mission.research_refused).is_false()

func study(days:int,both:bool=true)->void:
	for n in days:
		GameState.elapsed_days+=1;E.advance(GameState.elapsed_days)
		if both:
			var day:=GameState.elapsed_days
			WorldSimulation.scoped("neighbor",func()->void:WorldSimulation.state.elapsed_days=day;E.advance(day))

func test_joint_research_requires_two_studies_physical_exchange_and_validation()->void:
	begin_project()
	var local_key:=Joint.key("neighbor","clay_shaping")
	var peer_key:=Joint.key("player","clay_shaping")
	assert_bool(E.data().collections.has(local_key)).is_true()
	assert_bool(E.owner_state("neighbor").society_exchange.collections.has(peer_key)).is_true()
	assert_bool(Joint.quote("neighbor","clay_shaping","Stone").has("error")).is_true()
	study(100)
	assert_float(float(E.data().collections[local_key].study)).is_equal(1.0)
	assert_bool(E.data().evidence.has("clay_shaping")).is_false()
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_str(Joint.quote("neighbor","clay_shaping","Stone").get("partnership_phase","")).is_equal("exchange")
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	CivilizationSystem._process_diplomatic_mission(int(mission.arrival_day))
	assert_bool(E.data().collections.has(Joint.key("neighbor","clay_shaping",true))).is_false()
	var return_day:=int(mission.return_day)
	CivilizationSystem._process_diplomatic_mission(return_day)
	GameState.elapsed_days=return_day
	assert_bool(E.data().evidence.has("clay_shaping")).is_false()
	study(40)
	var evidence:=P.evidence("clay_shaping")
	assert_bool(evidence.get("research_partnership",false)).is_true()
	assert_float(float(P.chosen(DiscoverySystem.discovery_definition("clay_shaping"),GameState.elapsed_days).progress_multiplier)).is_equal(1.6)
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_bool(Joint.quote("neighbor","clay_shaping","Stone").has("error")).is_true()

func test_quote_does_not_reveal_partner_readiness_and_refusal_refunds_once()->void:
	joint_prepare()
	var terms:=Joint.quote("neighbor","clay_shaping","Stone")
	E.owner_state("neighbor").known_discoveries.clear()
	assert_dict(Joint.quote("neighbor","clay_shaping","Stone")).is_equal(terms)
	var stock:float=GameState.resource_stockpiles.Stone
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:=complete_trip()
	assert_bool(mission.research_refused).is_true()
	CivilizationSystem._process_diplomatic_mission(GameState.elapsed_days+1)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(stock)
	assert_bool(E.data().collections.has(Joint.key("neighbor","clay_shaping"))).is_false()

func test_unfinished_partner_delays_exchange_without_erasing_local_work()->void:
	begin_project();study(100,false)
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:=complete_trip()
	assert_bool(mission.research_refused).is_true()
	assert_float(float(E.data().collections[Joint.key("neighbor","clay_shaping")].study)).is_equal(1.0)
	assert_bool(E.data().collections.has(Joint.key("neighbor","clay_shaping",true))).is_false()

func test_protocol_uses_existing_study_budget_and_no_staff_means_no_progress()->void:
	begin_project();GameState.population_allocations.Knowledge=0
	study(2,false)
	var protocol:Dictionary=E.data().collections[Joint.key("neighbor","clay_shaping")]
	assert_float(float(protocol.study)).is_equal(0.0)
	GameState.population_allocations.Knowledge=10
	study(1,false)
	assert_float(absf(float(protocol.study)-1.5/180.0)).is_less(.000001)
	assert_bool(E.studying()).is_true()

func test_protocol_save_round_trip_preserves_work_and_cannot_claim_evidence()->void:
	begin_project();study(3)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	assert_bool(E.valid(saved)).is_true()
	GameState.society_exchange=saved
	var protocol:Dictionary=saved.collections[Joint.key("neighbor","clay_shaping")]
	var prior:float=protocol.study;study(1,false)
	assert_float(float(protocol.study)).is_greater(prior)
	protocol.study=1.0;saved.evidence.clay_shaping=protocol.id
	assert_bool(E.valid(saved)).is_false()

func test_actual_panel_dispatches_partnership_and_phase_metadata_is_validated()->void:
	joint_prepare()
	var panel:VBoxContainer=auto_free(preload("res://scripts/hud/research_purchase_panel.gd").new())
	panel.subject="clay_shaping";add_child(panel)
	for n in panel.modes.item_count:
		if panel.modes.get_item_metadata(n)=="partnership":panel.modes.select(n)
	panel.resources.select(4);panel.refresh();panel.send.pressed.emit()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	assert_str(mission.get("research_mode","")).is_equal("partnership")
	assert_bool(E.valid_mission(mission)).is_true()
	mission.partnership_phase="free_research"
	assert_bool(E.valid_mission(mission)).is_false()

func test_war_blocks_findings_exchange_but_keeps_completed_local_work()->void:
	begin_project();study(100)
	CivilizationSystem.civilizations[0].player_relation.at_war=true
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").has("error")).is_true()
	assert_float(float(E.data().collections[Joint.key("neighbor","clay_shaping")].study)).is_equal(1.0)

func test_protocol_cannot_be_studied_before_its_actual_arrival_day()->void:
	begin_project()
	var protocol:Dictionary=E.data().collections[Joint.key("neighbor","clay_shaping")]
	var arrival:=int(protocol.returned_day)
	GameState.elapsed_days=arrival-10;E.data().last_day=-1
	study(2,false)
	assert_float(float(protocol.study)).is_equal(0.0)

func test_joint_findings_do_not_replace_a_stronger_existing_study()->void:
	joint_prepare()
	var old:=Joint.item("neighbor","Neighbor","clay_shaping",{"x":30.0,"z":0.0},GameState.elapsed_days,true)
	old.id="purchase:neighbor:clay_shaping";old.research_partnership=false;old.research_purchase=true;old.study=1.0;old.work=120.0
	E.data().collections[old.id]=old;E.data().evidence.clay_shaping=old.id
	var report:=Joint.item("neighbor","Neighbor","clay_shaping",{"x":30.0,"z":0.0},GameState.elapsed_days,true)
	E.data().collections[report.id]=report
	study(30,false)
	assert_float(float(report.study)).is_equal(1.0)
	assert_str(String(E.data().evidence.clay_shaping)).is_equal(String(old.id))

func test_independent_discovery_does_not_prevent_honoring_an_agreed_exchange()->void:
	begin_project();study(100)
	GameState.known_discoveries.append("clay_shaping")
	assert_bool(Joint.pending("clay_shaping")).is_true()
	assert_str(Joint.quote("neighbor","clay_shaping","Stone").get("partnership_phase","")).is_equal("exchange")
	assert_bool(Joint.dispatch("neighbor","clay_shaping","Stone").get("ok",false)).is_true()
	var mission:=complete_trip()
	assert_bool(mission.research_refused).is_false()
	assert_bool(Joint.pending("clay_shaping")).is_false()
