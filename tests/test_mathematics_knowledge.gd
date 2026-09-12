extends GdUnitTestSuite
const Mathematics=preload("res://scripts/mathematics_knowledge.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91414);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=100000
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_each_mathematical_identity_has_a_valid_downstream_use()->void:
	assert_int(Mathematics.entries().size()).is_equal(26)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Mathematics.entries(),DiscoverySystem.technology_catalog)).is_empty()
	for entry:Dictionary in Mathematics.entries():
		assert_dict(entry.effects).is_empty()
		assert_bool(entry.foundation_for.is_empty()).is_false()
func test_all_existing_empirical_approaches_remain_available()->void:
	for id:String in Mathematics.MODELS:
		var entry:=DiscoverySystem.discovery_definition(id)
		GameState.known_discoveries.assign(entry.requires)
		var route:=P.chosen(entry,100000)
		assert_bool(route.is_empty()).override_failure_message(id+" lost its empirical route").is_false()
		assert_bool(String(route.id).begins_with("mathematical:")).is_false()
func test_mathematics_improves_only_the_relevant_ready_route()->void:
	for id:String in Mathematics.MODELS:
		var entry:=DiscoverySystem.discovery_definition(id)
		GameState.known_discoveries.assign(entry.requires)
		var baseline:=P.multiplier(entry)
		GameState.known_discoveries.append_array(Mathematics.MODELS[id].requires)
		assert_bool(String(P.chosen(entry,100000).id).begins_with("mathematical:")).is_true()
		assert_float(absf(P.multiplier(entry)/baseline-1.2)).is_less(.000001)
		GameState.known_discoveries.erase(entry.requires[0])
		assert_bool(P.ready(entry,100000)).override_failure_message(id+" bypassed a practical foundation").is_false()
func test_sampling_accepts_case_records_or_census_without_requiring_both()->void:
	var entry:=DiscoverySystem.discovery_definition("statistical_sampling")
	for source:String in ["case_records","census_rolls"]:
		GameState.known_discoveries.assign(["probability_theory",source])
		assert_bool(P.ready(entry,100000)).is_true()
	GameState.known_discoveries.assign(["probability_theory"])
	assert_bool(P.ready(entry,100000)).is_false()
func test_removing_all_new_mathematics_preserves_the_old_graphs_reachability()->void:
	var excluded:Array=[]
	for entry:Dictionary in Mathematics.entries():excluded.append(entry.id)
	var known:Array=[];var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if entry.id in known or entry.id in excluded:continue
			for route:Dictionary in P.routes_for(entry,known,{}):
				if route.ready:known.append(entry.id);changed=true;break
	# Later authored mechanics and geoscience may depend on mathematics; the
	# empirical catalog that preceded it must still remain reachable.
	var later:Array=[]
	for entry:Dictionary in preload("res://scripts/mechanics_knowledge.gd").entries():later.append(entry.id)
	for entry:Dictionary in preload("res://scripts/geoscience_knowledge.gd").entries():later.append(entry.id)
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if entry.id not in excluded and entry.id not in later:assert_bool(entry.id in known).override_failure_message(String(entry.id)).is_true()
func test_route_augmentation_is_idempotent_and_preserves_original_requirements()->void:
	var base:={"id":"wind_tunnel_testing","requires":["physical_gate"],"requires_all":["common_gate"],"requires_any":[["route_a","route_b"]],"learning_routes":[{"id":"local","label":"Experiments","requires_all":["apparatus"],"requires_any":[["wood","metal"]]}]}
	var once:=Mathematics.apply(base.duplicate(true))
	assert_dict(Mathematics.apply(once.duplicate(true))).is_equal(once)
	assert_array(once.requires_all).is_equal(base.requires_all)
	assert_array(once.requires_any).is_equal(base.requires_any)
	assert_dict(once.learning_routes[0]).is_equal(base.learning_routes[0])
	assert_array(once.learning_routes[1].requires_any).is_equal([["wood","metal"]])
func test_foreign_model_findings_still_require_physical_foundations()->void:
	var entry:=DiscoverySystem.discovery_definition("wind_tunnel_testing")
	var source:={"id":"foreign:wind_tunnel","kind":"knowledge","source_name":"Partner","research_purchase":true}
	var known:Array=Mathematics.MODELS.wind_tunnel_testing.requires.duplicate()
	for route:Dictionary in P.routes_for(entry,known,{},source):assert_bool(route.ready).is_false()
	known.append_array(entry.requires)
	var ready_model:=false
	for route:Dictionary in P.routes_for(entry,known,{},source):
		if route.get("imported",false) and String(route.id).contains("mathematical:") and route.ready:ready_model=true
	assert_bool(ready_model).is_true()
func test_old_discovery_progress_and_recorded_origin_survive_catalog_expansion()->void:
	GameState.known_discoveries.append("geometric_survey")
	GameState.discovery_progress.wind_tunnel_testing=.42
	GameState.society_exchange.origins.geometric_survey={"route":"local","label":"Recorded empirical survey","requires":["place_value","standard_measures"],"collection_id":"","day":9000}
	var before:Dictionary=GameState.society_exchange.origins.duplicate(true)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	assert_bool("geometric_survey" in GameState.known_discoveries).is_true()
	assert_float(float(GameState.discovery_progress.wind_tunnel_testing)).is_equal(.42)
	assert_dict(GameState.society_exchange.origins).is_equal(before)
