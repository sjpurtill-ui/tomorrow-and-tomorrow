extends GdUnitTestSuite
const M=preload("res://scripts/mechanics_knowledge.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91418);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func closure(excluded:Array)->Array:
	var known:Array=[];var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if entry.id in known or entry.id in excluded:continue
			for route:Dictionary in P.routes_for(entry,known,{}):
				if route.ready:known.append(entry.id);changed=true;break
	return known
func test_individual_capabilities_have_valid_downstream_uses()->void:
	assert_int(M.entries().size()).is_equal(24)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(M.entries(),DiscoverySystem.technology_catalog)).is_empty()
func test_earlier_catalog_remains_reachable_without_mechanics_branch()->void:
	var excluded:Array=[]
	for entry:Dictionary in M.entries():excluded.append(entry.id)
	var later:Array=[]
	for entry:Dictionary in preload("res://scripts/geoscience_knowledge.gd").entries():later.append(entry.id)
	var reachable:=closure(excluded)
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if entry.id not in excluded and entry.id not in later:assert_bool(entry.id in reachable).override_failure_message(String(entry.id)).is_true()
func test_each_model_can_be_learned_before_its_target()->void:
	for subject:String in M.MODELS:
		var known:=closure([subject])
		for parent:String in M.MODELS[subject].requires:
			assert_bool(parent in known).override_failure_message(subject+" model is circular through "+parent).is_true()
func test_relevant_mechanics_improves_research_without_removing_practical_route()->void:
	for subject:String in M.MODELS:
		var entry:=DiscoverySystem.discovery_definition(subject)
		GameState.known_discoveries.assign(entry.requires)
		assert_bool(P.ready(entry,0)).override_failure_message(subject).is_true()
		var before:=P.multiplier(entry)
		GameState.known_discoveries.append_array(M.MODELS[subject].requires)
		assert_float(absf(P.multiplier(entry)/before-1.15)).is_less(.000001)
		assert_bool(String(P.chosen(entry,0).id).begins_with("mechanical:")).is_true()
		GameState.known_discoveries.erase(entry.requires[0])
		assert_bool(P.ready(entry,0)).is_false()
func test_overlay_is_idempotent_and_keeps_existing_route_requirements()->void:
	var entry:=DiscoverySystem.discovery_definition("aerodynamics").duplicate(true)
	assert_dict(M.apply(entry.duplicate(true))).is_equal(entry)
	var ids:Array=[]
	for route:Dictionary in entry.learning_routes:
		assert_bool(route.id in ids).is_false();ids.append(route.id)
func test_mathematical_and_mechanical_routes_can_combine_without_repeated_bonuses()->void:
	var entry:=DiscoverySystem.discovery_definition("aerodynamics")
	GameState.known_discoveries.assign(entry.requires)
	var baseline:=P.multiplier(entry)
	GameState.known_discoveries.append_array(M.MODELS.aerodynamics.requires)
	GameState.known_discoveries.append_array(preload("res://scripts/mathematics_knowledge.gd").MODELS.aerodynamics.requires)
	assert_float(absf(P.multiplier(entry)/baseline-1.2*1.15)).is_less(.000001)
	assert_bool(String(P.chosen(entry,0).id).begins_with("mechanical:mathematical:")).is_true()

func test_woven_hull_alternative_remains_available_without_joinery()->void:
	var entry:=DiscoverySystem.discovery_definition("coastal_watercraft")
	var ready:=false
	for route:Dictionary in P.routes_for(entry,["river_craft","basketry"],{"fiber":2.0,"travel":2.0}):
		if route.id=="experimental" and route.ready:ready=true
	assert_bool(ready).is_true()
	for route:Dictionary in P.routes_for(entry,["river_craft","basketry","displacement_buoyancy"],{}):
		if String(route.id).contains("experimental"):assert_bool(route.ready).is_false()
