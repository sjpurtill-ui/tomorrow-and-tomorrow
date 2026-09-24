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
	# Evaluated once the library's era has come (research_600 era gate).
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,maxi(100000,int(ceil(DiscoverySystem.research_600_earliest_year(entry)*365.0))))).is_true()
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

func test_imported_alternate_records_actual_route_without_calendar_gate()->void:
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
	# Viewed once the library's era has come (research_600 era gate).
	GameState.elapsed_days=ceil(DiscoverySystem.research_600_earliest_year(DiscoverySystem.discovery_definition("public_libraries"))*365.0)
	for row:Dictionary in DiscoverySystem.technology_tree():
		if row.id=="public_libraries":assert_bool(row.ready).is_true();assert_array(row.missing).is_empty()

func test_existing_craft_can_support_apprenticeship_without_hafted_tools()->void:
	# 600-year design: contracts formalize keep-for-work apprenticeship and
	# sealed tablet contracts; hafted tools are still not required.
	GameState.known_discoveries.assign(["apprentice_for_keep","sealed_tablet_contracts"])
	assert_bool(P.ready(DiscoverySystem.discovery_definition("apprentice_contracts"),100000)).is_true()
	GameState.known_discoveries.erase("sealed_tablet_contracts")
	assert_bool(P.ready(DiscoverySystem.discovery_definition("apprentice_contracts"),100000)).is_false()

func test_graph_reports_unknown_foundations_and_unrecoverable_cycles()->void:
	assert_array(R.validate([{"id":"a","requires":["missing"]}])).is_not_empty()
	assert_array(R.validate([{"id":"a","requires":["b"]},{"id":"b","requires":["a"]}])).is_not_empty()
	assert_array(R.validate([{"id":"root"},{"id":"a","requires_any":[["root","b"]]},{"id":"b","requires":["a"]}])).is_empty()
	assert_array(R.validate([{"id":"a","requires_any":[[]]}])).is_not_empty()

func test_live_catalog_has_reachable_causal_foundations()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	var dormant=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(R.validate(graph,dormant.pending(graph))).is_empty()

func test_legacy_opponent_candidates_use_the_same_alternative_foundations()->void:
	var civ:={"production":1.0,"logistics":1.0,"environment_profile":{"resource_potentials":{}},"discovery_profile":{"seed":42,"technologies":["formal_archives","public_schools"]}}
	GameState.elapsed_days=ceil(DiscoverySystem.research_600_earliest_year(DiscoverySystem.discovery_definition("public_libraries"))*365.0)
	var found:=false
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"culture"):
		if entry.id=="public_libraries":found=true
	assert_bool(found).is_true()

## research_600: ready foundations still wait for the entry's era (its earliest
## year); the legacy ordering day is never the gate, and routes are unaffected.
func test_ready_foundations_wait_only_for_the_era_gate()->void:
	GameState.elapsed_days=1
	GameState.known_discoveries.assign(["public_schools","formal_archives"])
	var entry:=DiscoverySystem.discovery_definition("public_libraries")
	var opens:=int(ceil(DiscoverySystem.research_600_earliest_year(entry)*365.0))
	assert_bool(int(entry.day)>1 and int(entry.day)<opens).is_true()
	assert_bool(P.ready(entry,1)).is_true()
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,1)).is_false()
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,opens-365)).is_false()
	assert_array(DiscoverySystem.research_600_missing(entry)).is_not_empty()
	GameState.elapsed_days=opens
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,opens)).is_true()
	assert_array(DiscoverySystem.research_600_missing(entry)).is_empty()
	assert_array(P.missing(entry,1)).is_empty()
	assert_str(String(P.chosen(entry,1).id)).is_equal("manuscript")
	assert_bool("public_libraries" in GameState.known_discoveries).is_false()
	GameState.known_discoveries.erase("formal_archives")
	assert_bool(P.ready(entry,2000000)).is_false()

## research_600: rivals share the player's foundations and era gate.
func test_rivals_use_the_same_foundations_and_era_gate()->void:
	GameState.elapsed_days=1
	var civ:={"discovery_profile":{"technologies":["public_schools","formal_archives"]},"environment_profile":{},"production":1.0,"logistics":1.0}
	var candidates:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"culture"):candidates.append(entry.id)
	assert_bool("public_libraries" in candidates).is_false()
	GameState.elapsed_days=ceil(DiscoverySystem.research_600_earliest_year(DiscoverySystem.discovery_definition("public_libraries"))*365.0)
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"culture"):candidates.append(entry.id)
	assert_bool("public_libraries" in candidates).is_true()
	civ.discovery_profile.technologies.erase("formal_archives")
	candidates.clear()
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"culture"):candidates.append(entry.id)
	assert_bool("public_libraries" in candidates).is_false()

func test_legacy_ordering_day_cannot_change_route_readiness_or_rate()->void:
	GameState.known_discoveries.assign(["public_schools","formal_archives"])
	var entry:=DiscoverySystem.discovery_definition("public_libraries").duplicate(true)
	var baseline:=P.chosen(entry,1)
	entry.day=2000000000
	assert_dict(P.chosen(entry,1)).is_equal(baseline)
	assert_array(P.missing(entry,1)).is_empty()

func test_indexed_routes_match_arrays_and_do_not_retain_old_knowledge()->void:
	var entry:=DiscoverySystem.discovery_definition("public_libraries")
	var known:Array=["formal_archives","public_schools"]
	assert_array(P.routes_for(entry,R.index_known(known),{})).is_equal(P.routes_for(entry,known,{}))
	GameState.known_discoveries.assign(known)
	var day:=int(ceil(DiscoverySystem.research_600_earliest_year(entry)*365.0)) # once its era has come
	var channel:=DiscoverySystem._channel_key(String(entry.dynamic),String(entry.subcategory))
	var original:Array=DiscoverySystem.catalog_by_channel[channel]
	DiscoverySystem.catalog_by_channel[channel]=[entry]
	assert_bool(DiscoverySystem._channel_has_candidate(channel,day)).is_true()
	assert_str(DiscoverySystem._best_candidate_for_channel(channel,day).id).is_equal("public_libraries")
	GameState.known_discoveries.erase("public_schools")
	assert_bool(DiscoverySystem._channel_has_candidate(channel,day)).is_false()
	assert_dict(DiscoverySystem._best_candidate_for_channel(channel,day)).is_empty()
	GameState.known_discoveries.append("public_schools")
	GameState.known_discoveries.append("public_libraries")
	assert_bool(DiscoverySystem._channel_has_candidate(channel,day)).is_false()
	DiscoverySystem.catalog_by_channel[channel]=original

func test_large_reverse_graph_preserves_and_or_and_route_foundations()->void:
	var graph:Array=[{"id":"root"}]
	for i in range(1,5000):
		var previous:="root" if i==1 else "node%d"%(i-1)
		graph.append({"id":"node%d"%i,"requires_all":["root"],"learning_routes":[
			{"id":"cycle","requires":["node4999"]},
			{"id":"causal","requires_any":[[previous,"node4999"]]}]})
	graph.reverse()
	assert_array(R.validate(graph)).is_empty()
	graph.back().requires=["node4999"]
	assert_int(R.validate(graph).size()).is_equal(5000)

func test_dependency_queue_matches_fixed_point_on_mixed_graphs()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=41237
	for trial in 20:
		var graph:Array=[]
		for i in 40:
			var entry:Dictionary={"id":"n%d"%i}
			if i>2:
				entry.requires_all=["n%d"%rng.randi_range(0,39)]
				entry.learning_routes=[{"id":"a","requires_any":[["n%d"%rng.randi_range(0,39),"n%d"%rng.randi_range(0,39)]]},{"id":"b","requires":["n%d"%rng.randi_range(0,39)]}]
			graph.append(entry)
		if trial%2==0:graph.reverse()
		var reachable:Array=[]
		var changed:=true
		while changed:
			changed=false
			for entry:Dictionary in graph:
				if entry.id in reachable or not R.evaluate(entry,reachable).ready:continue
				var possible:bool=entry.get("learning_routes",[]).is_empty()
				for route:Dictionary in entry.get("learning_routes",[]):
					if R.evaluate(route,reachable).ready:possible=true
				if possible:reachable.append(entry.id);changed=true
		var expected:Array[String]=[]
		for entry:Dictionary in graph:
			if entry.id not in reachable:expected.append(String(entry.id)+": no reachable causal route (cycle or missing foundation)")
		assert_array(R.validate(graph)).is_equal(expected)
