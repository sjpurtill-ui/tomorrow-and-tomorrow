extends GdUnitTestSuite
const R=preload("res://scripts/technology_requirements.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const E=preload("res://scripts/society_exchange.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=100000

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_multiple_or_groups_keep_every_common_foundation()->void:
	var spec:={"requires_all":["power"],"requires_any":[["wheels","tracks"],["radio","signals"]]}
	assert_bool(R.evaluate(spec,["power","tracks","signals"]).ready).is_true()
	assert_bool(R.evaluate(spec,["tracks","signals"]).ready).is_false()
	assert_bool(R.evaluate(spec,["power","wheels"]).ready).is_false()
	assert_array(R.evaluate(spec,["power","wheels"]).missing_any).is_equal([["radio","signals"]])

func test_library_has_a_slower_route_without_printing()->void:
	var entry:=DiscoverySystem.discovery_definition("public_libraries")
	GameState.known_discoveries.assign(["public_schools","formal_archives"])
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,100000)).is_true()
	assert_str(P.chosen(entry).id).is_equal("manuscript")
	assert_float(P.multiplier(entry)).is_less(1.0)
	GameState.known_discoveries.erase("public_schools")
	assert_bool(P.ready(entry,100000)).is_false()
	GameState.known_discoveries.append("printing_process")
	assert_bool(P.ready(entry,100000)).is_false()

func test_import_can_support_the_alternative_and_never_skip_common_foundations()->void:
	var entry:=DiscoverySystem.discovery_definition("public_libraries")
	var item:={"id":"neighbor:public_libraries","kind":"knowledge","source_name":"Neighbor","source_id":"neighbor","discovery_id":"public_libraries"}
	var routes:=P.routes_for(entry,["formal_archives","public_schools"],{},item)
	var imported_ready:=false
	for route:Dictionary in routes:
		if route.id=="exchange:manuscript":
			assert_bool(route.ready).is_true();imported_ready=true
	assert_bool(imported_ready).is_true()
	for route:Dictionary in P.routes_for(entry,["formal_archives"],{},item):assert_bool(route.ready).is_false()

func test_imported_alternate_before_local_date_records_actual_route()->void:
	GameState.elapsed_days=1
	GameState.known_discoveries.assign(["public_schools","formal_archives"])
	var record:={"id":"neighbor:public_libraries","kind":"knowledge","name":"Copied library methods","source_id":"neighbor","source_name":"Neighbor","position":{"x":30.0,"z":0.0},"observed_day":0,"returned_day":1,"discovery_id":"public_libraries","study":1.0,"work":90.0,"signals":["research"]}
	E.data().collections[record.id]=record;E.data().evidence.public_libraries=record.id
	var entry:=DiscoverySystem.discovery_definition("public_libraries")
	assert_bool(P.ready(entry,1)).is_true()
	P.remember(entry,1)
	assert_str(E.data().origins.public_libraries.route).is_equal("exchange:manuscript")
	assert_bool(E.valid(JSON.parse_string(JSON.stringify(E.data())))).is_true()
	GameState.known_discoveries.append("public_libraries")
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,1)).is_false()

func test_interface_missing_requirements_describe_available_route()->void:
	GameState.known_discoveries.assign(["formal_archives"])
	var reasons:=P.missing(DiscoverySystem.discovery_definition("public_libraries"),100000)
	assert_int(reasons.size()).is_equal(1)
	assert_str(reasons[0]).is_equal(DiscoverySystem.discovery_definition("public_schools").name)
	GameState.known_discoveries.append("public_schools")
	for row:Dictionary in DiscoverySystem.technology_tree():
		if row.id=="public_libraries":assert_bool(row.ready).is_true();assert_array(row.missing).is_empty()

func test_existing_craft_can_support_apprenticeship_without_hafted_tools()->void:
	GameState.known_discoveries.assign(["customary_law","pit_firing"])
	assert_bool(P.ready(DiscoverySystem.discovery_definition("apprentice_contracts"),100000)).is_true()
	GameState.known_discoveries.erase("customary_law")
	assert_bool(P.ready(DiscoverySystem.discovery_definition("apprentice_contracts"),100000)).is_false()

func test_graph_reports_unknown_foundations_and_unrecoverable_cycles()->void:
	assert_array(R.validate([{"id":"a","requires":["missing"]}])).is_not_empty()
	assert_array(R.validate([{"id":"a","requires":["b"]},{"id":"b","requires":["a"]}])).is_not_empty()
	assert_array(R.validate([{"id":"root"},{"id":"a","requires_any":[["root","b"]]},{"id":"b","requires":["a"]}])).is_empty()
	assert_array(R.validate([{"id":"a","requires_any":[[]]}])).is_not_empty()

func test_live_catalog_has_reachable_causal_foundations()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	assert_array(R.validate(graph)).is_empty()

func test_legacy_opponent_candidates_use_the_same_alternative_foundations()->void:
	var civ:={"production":1.0,"logistics":1.0,"environment_profile":{"resource_potentials":{}},"discovery_profile":{"seed":42,"technologies":["formal_archives","public_schools"]}}
	var found:=false
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"culture"):
		if entry.id=="public_libraries":found=true
	assert_bool(found).is_true()
