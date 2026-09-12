extends GdUnitTestSuite
const G=preload("res://scripts/geoscience_knowledge.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const C=preload("res://scripts/technology_catalog_contract.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91424);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize();ResourceSystem.reset_for_new_world();ResourceSystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0;GameState.resource_deposits.clear();GameState.resource_stockpiles.clear();GameState.known_discoveries.clear();GameState.discovery_adoption.clear()
	GameState.population_allocations.Survey=12
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String,adoption:float=1.0)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption
func test_each_distinct_method_has_a_valid_implemented_profile()->void:
	assert_int(G.entries().size()).is_equal(16)
	assert_array(C.validate(G.entries(),DiscoverySystem.technology_catalog)).is_empty()
	for entry:Dictionary in G.entries():
		assert_dict(entry.effects).is_empty()
		learn(entry.id)
		var relevant:=false
		for resource:String in entry.prospecting_profile.resources:
			relevant=relevant or G.factor(resource,"recognition")>1.0 or G.factor(resource,"survey")>1.0
		assert_bool(relevant).override_failure_message(entry.id).is_true()
		GameState.known_discoveries.clear()
func test_known_but_unadopted_methods_and_absent_staff_give_no_improvement()->void:
	learn("systematic_channel_sampling",0)
	assert_float(G.factor("Copper Ore","survey")).is_equal(1.0)
	GameState.discovery_adoption.systematic_channel_sampling=.5
	assert_float(absf(G.factor("Copper Ore","survey")-1.1)).is_less(.000001)
	GameState.population_allocations.Survey=0
	assert_float(G.factor("Copper Ore","survey")).is_equal(1.0)
func test_methods_target_relevant_materials_and_only_strongest_in_family_counts()->void:
	learn("mineral_streak_tests")
	assert_float(G.factor("Timber","recognition")).is_equal(1.0)
	assert_float(G.factor("Copper Ore","recognition")).is_equal(1.12)
	learn("mineral_specific_gravity")
	assert_float(G.factor("Copper Ore","recognition")).is_equal(1.15)
	learn("geochemical_anomaly_mapping")
	assert_float(absf(G.factor("Copper Ore","recognition")-1.35)).is_less(.000001)
func test_all_methods_remain_bounded_and_invalid_phase_has_no_effect()->void:
	for entry:Dictionary in G.entries():learn(entry.id)
	for resource:String in ResourceSystem.catalog:
		for phase:String in ["recognition","survey"]:
			assert_float(G.factor(resource,phase)).is_less_equal(1.75)
	assert_float(G.factor("Copper Ore","extract")).is_equal(1.0)
func test_actual_survey_day_improves_work_without_making_stock_or_access()->void:
	var deposit:=ResourceSystem._deposit("Copper Ore",Vector3(1,0,1),1.0,1000,0);deposit.stage="recognized"
	GameState.resource_deposits.append(deposit)
	ResourceSystem.rng.seed=91424;ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	var baseline:=float(deposit.survey);deposit.survey=0.0
	learn("systematic_channel_sampling")
	ResourceSystem.rng.seed=91424;ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_float(absf(float(deposit.survey)/baseline-1.2)).is_less(.000001)
	assert_str(String(deposit.stage)).is_equal("recognized")
	assert_float(float(deposit.remaining)).is_equal(1000.0)
	assert_float(float(GameState.resource_stockpiles.get("Copper Ore",0))).is_equal(0.0)
func test_prospecting_cannot_bypass_special_recognition_or_invent_occurrences()->void:
	for entry:Dictionary in G.entries():learn(entry.id)
	var uranium:=ResourceSystem._deposit("Uranium Ore",Vector3(1,0,1),1.0,1000,0);uranium.clues=1.0
	GameState.resource_deposits.append(uranium)
	ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_str(String(uranium.stage)).is_equal("unknown")
	assert_int(GameState.resource_deposits.size()).is_equal(1)
func test_earlier_catalog_remains_reachable_without_geoscience_methods()->void:
	var excluded:Array=[]
	for entry:Dictionary in G.entries():excluded.append(entry.id)
	var known:Array=[];var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if entry.id in known or entry.id in excluded:continue
			for route:Dictionary in P.routes_for(entry,known,{}):
				if route.ready:known.append(entry.id);changed=true;break
	assert_int(known.size()).is_equal(DiscoverySystem.technology_catalog.size()-16)
func test_invalid_profiles_are_rejected_and_inspector_explains_limits()->void:
	var entry:Dictionary=G.entries()[0].duplicate(true)
	entry.prospecting_profile.resources=["Unobtainium"]
	assert_bool(C.validate([entry],DiscoverySystem.technology_catalog).is_empty()).is_false()
	entry=G.entries()[0].duplicate(true);entry.prospecting_profile.survey=4.0
	assert_bool(C.validate([entry],DiscoverySystem.technology_catalog).is_empty()).is_false()
	var description:=DiscoverySystem._discovery_effect_summary(G.entries()[0])
	assert_str(description).contains("Survey workers")
	assert_str(description).contains("No deposits")
func test_methods_never_amplify_unstaffed_passive_clues()->void:
	GameState.population_allocations.Survey=0
	var deposit:=ResourceSystem._deposit("Copper Ore",Vector3(1,0,1),1.0,1000,0)
	GameState.resource_deposits.append(deposit)
	ResourceSystem.rng.seed=91424;ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	var baseline:=float(deposit.clues);deposit.clues=0.0
	for entry:Dictionary in G.entries():learn(entry.id)
	ResourceSystem.rng.seed=91424;ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_float(float(deposit.clues)).is_equal(baseline)
func test_method_adoption_is_owned_by_the_active_civilization()->void:
	WorldSimulation.create_actor("geo_alpha",91424,Vector2.ZERO)
	WorldSimulation.create_actor("geo_beta",91424,Vector2.ZERO)
	WorldSimulation.scoped("geo_alpha",func()->void:
		WorldSimulation.state.population_allocations.Survey=12
		WorldSimulation.state.known_discoveries.append("systematic_channel_sampling")
		WorldSimulation.state.discovery_adoption.systematic_channel_sampling=1.0
		assert_float(G.factor("Copper Ore","survey")).is_equal(1.2)
	)
	WorldSimulation.scoped("geo_beta",func()->void:
		WorldSimulation.state.population_allocations.Survey=12
		assert_float(G.factor("Copper Ore","survey")).is_equal(1.0)
	)
	assert_float(G.factor("Copper Ore","survey")).is_equal(1.0)
func test_inspector_does_not_name_undiscovered_target_materials()->void:
	var entry:=DiscoverySystem.discovery_definition("mineral_specific_gravity")
	assert_str(DiscoverySystem._discovery_effect_summary(entry)).not_contains("Uranium Ore")
	var copper:=ResourceSystem._deposit("Copper Ore",Vector3(1,0,1),1.0,1000,0);copper.stage="recognized"
	GameState.resource_deposits.append(copper)
	var text:=DiscoverySystem._discovery_effect_summary(entry)
	assert_str(text).contains("Copper Ore")
	assert_str(text).not_contains("Uranium Ore")
func test_empty_effect_profiles_cannot_count_as_implemented_capabilities()->void:
	var entry:Dictionary=G.entries()[0].duplicate(true)
	entry.prospecting_profile.recognition=0.0;entry.prospecting_profile.survey=0.0
	assert_bool(C.validate([entry],DiscoverySystem.technology_catalog).is_empty()).is_false()
