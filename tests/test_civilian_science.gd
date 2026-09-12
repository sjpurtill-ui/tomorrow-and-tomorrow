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

const Science=preload("res://scripts/civilian_science_knowledge.gd")
func test_science_contracts_have_real_downstream_uses()->void:
	assert_int(Science.entries().size()).is_equal(24)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Science.entries(),DiscoverySystem.technology_catalog)).is_empty()
	for entry:Dictionary in Science.entries():
		assert_dict(entry.effects).is_empty()
		assert_bool(entry.foundation_for.is_empty()).is_false()

func test_peaceful_graph_reaches_modern_civilian_capabilities()->void:
	var peaceful:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if entry.dynamic!="security":peaceful.append(entry)
	var known:Array=[]
	var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in peaceful:
			if entry.id in known:continue
			for route:Dictionary in P.routes_for(entry,known,{}):
				if route.ready:known.append(entry.id);changed=true;break
	for id:String in ["atomic_physics","reactor_engineering","internal_combustion","powered_flight","advanced_airframes","jet_propulsion"]:
		assert_bool(id in known).override_failure_message(id+" still needs military research").is_true()

func test_reactor_needs_fuel_physics_control_containment_and_instrumentation()->void:
	var entry:=DiscoverySystem.discovery_definition("reactor_engineering")
	var foundations:Array=entry.requires.duplicate()
	for missing:String in foundations:
		GameState.known_discoveries.assign(foundations)
		GameState.known_discoveries.erase(missing)
		assert_bool(P.ready(entry,100000)).is_false()
	GameState.known_discoveries.assign(foundations)
	assert_bool(P.ready(entry,100000)).is_true()
	assert_bool("naval_fire_control" in P.definition_parents(entry)).is_false()

func test_existing_ids_and_progress_survive_reclassification()->void:
	GameState.discovery_progress.atomic_physics=.4
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	assert_float(float(GameState.discovery_progress.atomic_physics)).is_equal(.4)
	assert_str(DiscoverySystem.discovery_definition("atomic_physics").dynamic).is_equal("knowledge")
	assert_str(DiscoverySystem.discovery_definition("advanced_airframes").dynamic).is_equal("production")

func test_authoring_rejects_fictional_downstream_links()->void:
	var entry:Dictionary=Science.entries()[0].duplicate(true)
	entry.foundation_for=["phantom_capability"]
	assert_bool(preload("res://scripts/technology_catalog_contract.gd").validate([entry],[entry]).is_empty()).is_false()

func test_whole_graph_remains_reachable_after_rewiring()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	assert_array(R.validate(graph)).is_empty()

func test_reclassified_question_cannot_remain_in_two_channels()->void:
	var entry:=DiscoverySystem.discovery_definition("atomic_physics")
	GameState.known_discoveries.assign(entry.requires)
	GameState.research_subcategory_allocations[entry.dynamic][entry.subcategory]=10
	var old_channel:=DiscoverySystem._channel_key("security","Military readiness")
	GameState.active_investigations[old_channel]="atomic_physics"
	GameState.discovery_progress.atomic_physics=.4
	DiscoverySystem._refresh_active_investigations()
	assert_bool(GameState.active_investigations.get(old_channel,"")=="atomic_physics").is_false()
	var count:=0
	for id:Variant in GameState.active_investigations.values():
		if id=="atomic_physics":count+=1
	assert_int(count).is_less_equal(1)
	assert_float(float(GameState.discovery_progress.atomic_physics)).is_equal(.4)
