extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const CollectionPanel=preload("res://scripts/hud/exchange_collection_panel.gd")

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
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func mission(kind:String="explore")->Dictionary:
	return {"mission_id":9,"personnel":6,"target_kind":kind,"start_day":0,"return_day":40,"actual_return_day":40,"carried_collections":[],"encountered_societies":["neighbor"]}

func item(id:String="oral_epics",kind:String="culture")->Dictionary:
	return {"id":"neighbor:"+id,"kind":kind,"name":"A recorded practice","source_id":"neighbor","source_name":"Neighbor","position":{"x":30.0,"z":0.0},"observed_day":4,"returned_day":40,"discovery_id":id,"study":0.0,"work":10.0,"signals":["culture","research"]}

func test_return_is_required_and_repeated_reading_never_repeats_rewards()->void:
	var trip:=mission();var stock:float=E.owner_state("neighbor").resource_stockpiles.Clay
	E.encounter(trip,"neighbor","Neighbor",{"x":30.0,"z":0.0},10)
	assert_int(trip.carried_collections.size()).is_equal(1)
	assert_str(trip.carried_collections[0].kind).is_equal("artifact")
	assert_float(float(E.owner_state("neighbor").resource_stockpiles.Clay)).is_equal(stock-1)
	assert_dict(E.data().collections).is_empty();assert_dict(P.evidence("clay_shaping")).is_empty()
	assert_int(E.returned(trip,40).size()).is_equal(1)
	assert_array(E.returned(trip,41)).is_empty()
	assert_dict(P.evidence("clay_shaping")).is_empty()
	for day in range(41,100):E.advance(day)
	assert_dict(P.evidence("clay_shaping")).is_not_empty()
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_bool(E.valid(E.data())).is_true()

func test_source_must_know_and_adopt_the_practice_and_guarding_prevents_gifts()->void:
	E.owner_state("neighbor").discovery_adoption.clay_shaping=.1
	var trip:=mission();E.encounter(trip,"neighbor","Neighbor",{"x":30.0,"z":0.0},10)
	assert_array(trip.carried_collections).is_empty()
	E.owner_state("neighbor").discovery_adoption.clay_shaping=1
	E.owner_state("neighbor").society_exchange.sharing_policy="guarded"
	trip=mission();E.encounter(trip,"neighbor","Neighbor",{"x":30.0,"z":0.0},10)
	assert_array(trip.carried_collections).is_empty()

func test_households_transfer_once_and_preserve_world_population_and_mortality()->void:
	var trip:=mission("recruit_people_visit")
	var before:float=GameState.population_exact+E.owner_state("neighbor").population_exact
	var deaths:Dictionary=E.owner_state("neighbor").mortality_by_age_cohort.duplicate()
	E.invite_households(trip,"neighbor","Neighbor",10)
	assert_bool(trip.has("migrant_reservation")).is_true()
	assert_float(GameState.population_exact+E.owner_state("neighbor").population_exact).is_equal(before)
	var count:=E.arrive(trip,40)
	assert_int(count).is_greater(0);assert_int(E.arrive(trip,40)).is_equal(0)
	assert_float(GameState.population_exact+E.owner_state("neighbor").population_exact).is_equal_approx(before,.00001)
	assert_dict(E.owner_state("neighbor").mortality_by_age_cohort).is_equal(deaths)
	assert_float(float(E.pressure().unsettled)).is_equal(float(count))
	assert_int(int(E.known_relation("neighbor").arrivals)).is_equal(count)

func test_repeated_recruitment_without_an_encounter_never_creates_people()->void:
	var before:=GameState.population_exact
	for day in 400:
		assert_int(CivilizationSystem._resolve_scout_recruitment(mission("recruit_people"),day)).is_equal(0)
	assert_float(GameState.population_exact).is_equal(before)

func test_invitation_requires_spare_homes_water_food_and_a_better_offer()->void:
	GameState.housing_capacity=190
	var trip:=mission("recruit_people_visit");E.invite_households(trip,"neighbor","Neighbor",10)
	assert_bool(trip.has("migrant_reservation")).is_false()
	GameState.housing_capacity=280;GameState.water_metrics.intake_ratio=.7
	trip=mission("recruit_people_visit");E.invite_households(trip,"neighbor","Neighbor",10)
	assert_bool(trip.has("migrant_reservation")).is_false()
	GameState.water_metrics.intake_ratio=1;E.policy("consolidate","open")
	assert_int(E.reception_capacity()).is_equal(0)

func test_integration_uses_existing_administrators_and_releases_pressure_over_time()->void:
	E.data().integration.append({"origin":"neighbor","count":30.0,"remaining":30.0})
	var before:=float(E.pressure().cohesion_cost)
	GameState.population_allocations.Administration=0
	E.advance(1);assert_float(float(E.pressure().unsettled)).is_equal(30.0)
	GameState.population_allocations.Administration=12
	for day in range(2,90):E.advance(day)
	assert_float(float(E.pressure().unsettled)).is_less(30.0)
	assert_float(float(E.pressure().cohesion_cost)).is_less(before)

func test_objects_need_staff_and_generic_research_is_not_instantly_completed()->void:
	var record:=item();E.data().collections[record.id]=record
	GameState.population_allocations.Knowledge=0
	for day in 30:E.advance(day)
	assert_float(float(record.study)).is_equal(0.0)
	GameState.population_allocations.Knowledge=30
	for day in range(30,60):E.advance(day)
	assert_float(float(record.study)).is_equal(1.0)
	assert_bool("oral_epics" in GameState.known_discoveries).is_false()
	assert_float(float(E.known_relation("neighbor").respect)).is_greater(0.0)

func test_culture_can_travel_outward_without_population_or_military_strength()->void:
	GameState.known_discoveries.assign(["oral_epics"]);GameState.discovery_adoption.oral_epics=1
	E.policy("balanced","selective")
	var trip:=mission();E.share_practice(trip,"neighbor",{"x":30.0,"z":0.0},10)
	var foreign:Dictionary=E.owner_state("neighbor").society_exchange
	assert_bool(foreign.collections.has("player:oral_epics")).is_true()
	assert_dict(E.data().connections).is_empty()
	E.returned(trip,40);assert_bool("oral_epics" in E.known_relation("neighbor").shared).is_true()
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.state.population_allocations.Knowledge=40
		for day in range(11,130):E.advance(day))
	assert_float(E.counterpart_value("neighbor",{"openness":.8,"assertiveness":.2})).is_greater(0)

func test_alternative_foundations_are_functional_and_reconnect_on_one_discovery()->void:
	var definition:=DiscoverySystem.discovery_definition("pit_firing")
	GameState.known_discoveries.assign(["clay_shaping","food_drying"])
	DiscoverySystem.latest_context={"fire":1.0,"clay":1.0}
	assert_bool(P.ready(definition,100)).is_true()
	assert_str(P.chosen(definition).id).is_equal("experimental")
	P.remember(definition,100)
	assert_str(E.data().origins.pit_firing.route).is_equal("experimental")
	GameState.known_discoveries.append("pit_firing")
	assert_bool(DiscoverySystem._discovery_is_eligible(definition,100)).is_false()

func test_imported_evidence_changes_timing_without_skipping_foundations()->void:
	var record:=item("civic_games");record.study=1
	E.data().collections[record.id]=record;E.data().evidence.civic_games=record.id
	var definition:=DiscoverySystem.discovery_definition("civic_games")
	assert_bool(P.ready(definition,1)).is_false()
	GameState.known_discoveries.assign(["festival_calendar","standard_measures"])
	assert_bool(P.ready(definition,1)).is_true()
	assert_str(P.chosen(definition).id).is_equal("exchange")
	assert_float(P.multiplier(definition)).is_greater(1.0)

func test_roundtrip_keeps_origins_collections_and_pending_migration_separate_for_each_owner()->void:
	E.data().collections["neighbor:oral_epics"]=item()
	var trip:=mission("recruit_people_visit");E.invite_households(trip,"neighbor","Neighbor",10)
	var snapshot:=SaveSystem._capture_reflected(GameState,[])
	var actor:=WorldSimulation.capture_actor("neighbor")
	assert_bool(E.valid(JSON.parse_string(JSON.stringify(snapshot.society_exchange)))).is_true()
	assert_dict(actor.GameState.society_exchange.collections).is_empty()
	assert_int(actor.GameState.society_exchange.outbound.size()).is_equal(1)
	var invalid:Dictionary=snapshot.society_exchange.duplicate(true);invalid.collections["neighbor:oral_epics"].study=-1
	assert_bool(E.valid(invalid)).is_false()

func test_collection_layout_fits_small_and_large_windows()->void:
	for size:Vector2i in [Vector2i(340,640),Vector2i(960,720)]:
		var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=size;add_child(viewport)
		var view:=CollectionPanel.new();viewport.add_child(view)
		await get_tree().process_frame;await get_tree().process_frame
		assert_float(view.panel.position.x).is_greater_equal(0)
		assert_float(view.panel.size.x).is_less_equal(size.x)
		assert_float(view.panel.size.y).is_less_equal(size.y)

func test_multiple_inviting_parties_reserve_homes_and_source_labor_once()->void:
	GameState.housing_capacity=206
	var first:=mission("recruit_people_visit");CivilizationSystem.scout_missions.append(first)
	E.invite_households(first,"neighbor","Neighbor",10)
	var promised:=int(first.migrant_reservation.count)
	var second:=mission("recruit_people_visit");second.mission_id=10;CivilizationSystem.scout_missions.append(second)
	E.invite_households(second,"neighbor","Neighbor",10)
	var total:=promised+int(second.get("migrant_reservation",{}).get("count",0))
	assert_int(total).is_less_equal(6)
	assert_int(E.reception_capacity()).is_equal(6-total)
	WorldSimulation.scoped("neighbor",func()->void:
		assert_int(WorldSimulation.world.mission_absent_personnel()).is_equal(total)
		assert_int(WorldSimulation.world.player_population_commitments().total_absent).is_equal(total))

func test_failed_return_releases_source_reservation_without_spawning_or_killing_households()->void:
	var trip:=mission("recruit_people_visit");E.invite_households(trip,"neighbor","Neighbor",10)
	var population:float=E.owner_state("neighbor").population_exact
	WorldSimulation.scoped("neighbor",func()->void:E.advance(42))
	assert_int(E.arrive(trip,43)).is_equal(0)
	assert_float(E.owner_state("neighbor").population_exact).is_equal(population)

func test_every_authored_research_route_has_real_foundations()->void:
	for id:String in P.ALTERNATIVES:
		assert_dict(DiscoverySystem.discovery_definition(id)).override_failure_message("Missing alternate target "+id).is_not_empty()
		for requirement:String in P.ALTERNATIVES[id].requires:
			assert_dict(DiscoverySystem.discovery_definition(requirement)).override_failure_message("Missing foundation "+requirement).is_not_empty()

func test_opponents_can_receive_and_send_households_to_the_human_using_the_same_rules()->void:
	WorldSimulation.scoped("neighbor",func()->void:
		assert_object(E.owner_state("human")).is_same(GameState)
		WorldSimulation.state.housing_capacity=300;WorldSimulation.state.food_security=1;WorldSimulation.state.population_health=1
		WorldSimulation.state.water_metrics={"intake_ratio":1};WorldSimulation.state.population_allocations.Administration=12
		WorldSimulation.state.simulation_metrics={"food_days":60,"food_intake_ratio":1,"security":1,"cohesion":1}
		GameState.food_security=.3;GameState.population_health=.5
		var before:float=GameState.population_exact+WorldSimulation.state.population_exact
		var trip:=mission("recruit_people_visit");E.invite_households(trip,"human","Human community",10)
		assert_bool(trip.has("migrant_reservation")).is_true()
		assert_int(E.arrive(trip,40)).is_greater(0)
		assert_float(GameState.population_exact+WorldSimulation.state.population_exact).is_equal_approx(before,.00001)
		assert_int(int(E.known_relation("human").arrivals)).is_greater(0))

func test_physical_envoy_contact_brings_practices_home_only_on_return()->void:
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor"}]
	var trip:={"civ_id":"neighbor","depart_day":1,"arrival_day":10,"return_day":20,"personnel":2,"target_position":{"x":30.0,"z":0.0},"purpose":"leader_parley"}
	E.envoy_arrived(CivilizationSystem,trip,10)
	assert_int(trip.carried_collections.size()).is_equal(1)
	assert_dict(E.data().collections).is_empty()
	assert_int(E.returned(trip,20).size()).is_equal(1)
	assert_array(E.returned(trip,21)).is_empty()
	assert_bool(E.valid_mission(trip)).is_true()

func test_bilateral_understanding_has_actual_reciprocal_benefit_and_recruitment_terms()->void:
	E.accept_accord("neighbor","restraint","culture",.12,730)
	var trip:=mission("recruit_people_visit");E.invite_households(trip,"neighbor","Neighbor",10)
	assert_bool(trip.has("migrant_reservation")).is_false()
	assert_str(trip.recruitment_reason).contains("border understanding")
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.world.civilizations.append({"id":"human","player_relation":{"at_war":false}})
		assert_float(E.received_accord_bonus("culture")).is_equal(.12)
		assert_int(E.known_relation("human").recruitment_truce_until).is_equal(730)
		WorldSimulation.world.civilizations[0].player_relation.at_war=true
		assert_float(E.received_accord_bonus("culture")).is_equal(0.0))

func test_knowledge_sharing_and_arrivals_change_leader_goals_and_diplomatic_choice()->void:
	var personality:={"openness":.8,"discipline":.5,"empathy":.6,"assertiveness":.3,"risk_tolerance":.4}
	var strategy=preload("res://scripts/civilization_strategy.gd")
	var base:=strategy.preferences(personality,{"food_days":60})
	var strained:=strategy.preferences(personality,{"food_days":60,"integration_pressure":.3})
	assert_str(strained.goals[0].title).contains("settle")
	assert_float(strained.research_weights.institutions).is_greater(base.research_weights.institutions)
	var relationship:={"at_war":false,"opinion":-.15,"treaty":"none"}
	assert_str(strategy.diplomatic_action(relationship,base,60)).is_equal("")
	E.connection("neighbor").respect=.3;relationship.opinion+=E.diplomatic_value("neighbor",personality)
	assert_str(strategy.diplomatic_action(relationship,base,60)).is_equal("open_trade")

func test_malformed_evidence_and_carried_records_are_rejected()->void:
	E.data().evidence["clay_shaping"]="missing"
	assert_bool(E.valid(E.data())).is_false()
	var trip:=mission();trip.carried_collections.append(item());trip.carried_collections[0].work=0
	assert_bool(E.valid_mission(trip)).is_false()

func test_ground_samples_require_actual_unexplored_ground_and_do_not_reward_retracing()->void:
	CivilizationSystem.ground_survey_authority=func(_point:Vector2)->Dictionary:return {"biome":"grassland","label":"Exposed clay bank","resource_potentials":{"Clay":.8}}
	var trip:=mission();var point:=Vector2(7000,7000)
	E.sample_ground(CivilizationSystem,trip,point,10)
	assert_int(trip.carried_collections.size()).is_equal(1)
	assert_dict(P.evidence("clay_shaping")).is_empty()
	E.returned(trip,40)
	var repeated:=mission();E.sample_ground(CivilizationSystem,repeated,point+Vector2(80,0),50)
	assert_array(repeated.carried_collections).is_empty()
	CivilizationSystem._add_revealed_area(point,200,"visited")
	var known:=mission();E.sample_ground(CivilizationSystem,known,point,60)
	assert_array(known.carried_collections).is_empty()

func test_larger_delegation_increases_invitation_capacity_but_cannot_exceed_real_households()->void:
	var small:=mission("recruit_people_visit");small.personnel=2
	E.invite_households(small,"neighbor","Neighbor",10)
	var fewer:=int(small.migrant_reservation.count)
	var large:=mission("recruit_people_visit");large.personnel=12;large.mission_id=10
	E.invite_households(large,"neighbor","Neighbor",10)
	assert_int(int(large.migrant_reservation.count)).is_greater(fewer)
	assert_int(int(large.migrant_reservation.count)).is_less_equal(E.reception_capacity())

func test_selective_sharing_has_the_same_limits_for_visitors_and_hosts()->void:
	var source:=E.owner_state("neighbor")
	source.known_discoveries.assign(["civic_games"]);source.discovery_adoption.civic_games=1
	source.society_exchange.sharing_policy="selective"
	var trip:=mission();E.encounter(trip,"neighbor","Neighbor",{"x":30.0,"z":0.0},10)
	assert_int(trip.carried_collections.size()).is_equal(1)
	source.known_discoveries.assign(["copper_smelting"]);source.discovery_adoption.copper_smelting=1
	trip=mission();E.encounter(trip,"neighbor","Neighbor",{"x":30.0,"z":0.0},10)
	assert_array(trip.carried_collections).is_empty()
	GameState.known_discoveries.assign(["copper_smelting"]);GameState.discovery_adoption.copper_smelting=1
	E.policy("balanced","selective");E.share_practice(mission(),"neighbor",{"x":30.0,"z":0.0},10)
	assert_bool(source.society_exchange.collections.has("player:copper_smelting")).is_false()

func test_received_cooperation_does_not_resume_after_war_ends()->void:
	E.connection("neighbor")["received_cooperation"]={"domain":"knowledge","kind":"exchange","bonus":.12,"until":730}
	assert_float(E.received_accord_bonus("knowledge")).is_equal(.12)
	CivilizationSystem.civilizations[0].player_relation.at_war=true;E.advance(1)
	CivilizationSystem.civilizations[0].player_relation.at_war=false
	assert_float(E.received_accord_bonus("knowledge")).is_equal(0.0)

func test_reception_readiness_names_individual_shortages_and_reserved_places()->void:
	GameState.housing_capacity=201;GameState.water_metrics.intake_ratio=.5
	GameState.simulation_metrics.food_days=8;GameState.population_allocations.Administration=0
	var readiness:=E.reception_snapshot()
	assert_int(readiness.capacity).is_equal(0)
	assert_str(readiness.message).contains("Housing: 1")
	assert_str(readiness.message).contains("Food: 8.0")
	assert_str(readiness.message).contains("Water: 50%")
	assert_str(readiness.message).contains("Reception staff")
	GameState.housing_capacity=205;GameState.water_metrics.intake_ratio=1
	GameState.simulation_metrics.food_days=60;GameState.population_allocations.Administration=12
	CivilizationSystem.scout_missions.append({"migrant_reservation":{"count":4}})
	assert_int(E.reception_capacity()).is_equal(0)
	CivilizationSystem.scout_missions.clear()
	assert_int(E.reception_capacity()).is_equal(5)

func test_dispatched_influence_party_physically_brings_knowledge_home_without_inviting_when_full()->void:
	GameState.housing_capacity=190
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions.append({"id":"neighbor_city","name":"Neighbor Town","role":"capital","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor"})
	CivilizationSystem.city_intelligence.records.player={"neighbor_city":{"city_id":"neighbor_city","name":"Neighbor Town","civ_id":"neighbor","controller":"neighbor","position":{"x":30.0,"z":0.0},"observed_day":0,"reported_day":0,"source":"physical visit","reference":"test","fields":{}}}
	CivilizationSystem.scouting_staff.set_policy(.05,"recruitment")
	CivilizationSystem.scouting_staff.advance(0)
	assert_int(CivilizationSystem.scout_missions.size()).is_equal(1)
	var trip:Dictionary=CivilizationSystem.scout_missions[0]
	assert_str(trip.target_kind).is_equal("recruit_people_visit")
	assert_dict(E.data().collections).is_empty()
	var end:=int(trip.actual_return_day)
	for day in range(1,end):
		GameState.elapsed_days=day;E.sample_missions(CivilizationSystem,day)
	assert_bool("neighbor" in trip.encountered_societies).is_true()
	assert_bool(trip.has("migrant_reservation")).is_false()
	assert_str(trip.recruitment_reason).contains("Housing:")
	assert_dict(E.data().collections).is_empty()
	assert_int(E.returned(trip,end).size()).is_greater(0)
	assert_int(E.arrive(trip,end)).is_equal(0)
	assert_float(GameState.population_exact).is_equal(200.0)

func _archive_item(index:int)->Dictionary:
	return {"id":"archive-%d" % index,"kind":"knowledge","name":"Returned account %d" % index,"source_id":"","source_name":"Collection fixture","position":{"x":0.0,"z":0.0},"observed_day":index,"returned_day":index,"discovery_id":"tallies","study":1.0,"work":120.0,"signals":[]}
func test_large_collection_roundtrip_preserves_records_beyond_old_limit()->void:
	for index in range(5001):E.data().collections["archive-%d" % index]=_archive_item(index)
	E.data().evidence.tallies="archive-5000"
	var restored:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	assert_bool(E.valid(restored)).is_true()
	assert_int(restored.collections.size()).is_equal(5001)
	assert_str(restored.evidence.tallies).is_equal("archive-5000")
	assert_int(E.COLLECTION_LIMIT).is_greater_equal(30000)
func test_collection_pagination_reaches_oldest_records_and_resets_filter()->void:
	for index in range(45):E.data().collections["archive-%d" % index]=_archive_item(index)
	var view:=CollectionPanel.new();add_child(view)
	assert_str(view.page_label.text).is_equal("Page 1 of 2 · 45 finds")
	assert_bool(view.previous_page.disabled).is_true()
	view.next_page.pressed.emit()
	assert_str(view.page_label.text).is_equal("Page 2 of 2 · 45 finds")
	assert_bool(view.next_page.disabled).is_true()
	assert_int(view.cards.get_child_count()).is_equal(5)
	view.filter.select(1);view.filter.item_selected.emit(1)
	assert_int(view.page).is_equal(0)
	assert_str(view.page_label.text).is_equal("Page 1 of 1 · 0 finds")
	await get_tree().process_frame
	view.free()
