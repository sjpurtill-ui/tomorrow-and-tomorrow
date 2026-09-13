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

const Land=preload("res://scripts/military_unit_catalog.gd")
const Education=preload("res://scripts/military_education_knowledge.gd")

func test_military_contracts_have_reachable_graph_and_supported_roles()->void:
	assert_int(Education.entries().size()).is_equal(8)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Education.entries(),DiscoverySystem.technology_catalog)).is_empty()
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	var audit=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=audit.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(R.validate(graph,audit.pending(graph))).is_empty()

func test_training_research_is_role_specific_and_scales_with_adoption()->void:
	var base:=Land.training_days("skirmisher")
	var cavalry:=Land.training_days("cavalry")
	GameState.known_discoveries.assign(["skirmish_pair_drill"])
	GameState.discovery_adoption.skirmish_pair_drill=.5
	assert_float(absf(Land.training_days("skirmisher")-base*.925)).is_less(.000001)
	assert_float(Land.training_days("cavalry")).is_equal(cavalry)
	GameState.discovery_adoption.skirmish_pair_drill=1.0
	assert_float(absf(Land.training_days("skirmisher")-base*.85)).is_less(.000001)

func test_alternative_teaching_foundations_keep_weapons_foundation()->void:
	var entry:=DiscoverySystem.discovery_definition("skirmish_pair_drill")
	for teaching:String in ["formation_drill","oral_epics"]:
		GameState.known_discoveries.assign(["bow_craft",teaching])
		assert_bool(P.ready(entry,100000)).is_true()
	GameState.known_discoveries.assign(["oral_epics"])
	assert_bool(P.ready(entry,100000)).is_false()

func test_new_order_uses_teaching_but_existing_order_keeps_schedule()->void:
	MilitaryCampaign.reset_for_new_world()
	GameState.known_discoveries.assign(["bow_craft"])
	GameState.discovery_adoption.bow_craft=1.0
	MilitaryCampaign.aggregate_recruits=20
	var first:=MilitaryCampaign.start_training("skirmisher","bow",5)
	assert_bool(first.has("error")).is_false()
	var original:float=MilitaryCampaign.training_queue[0].required_days
	GameState.known_discoveries.append("skirmish_pair_drill")
	GameState.discovery_adoption.skirmish_pair_drill=1.0
	var second:=MilitaryCampaign.start_training("skirmisher","bow",5)
	assert_bool(second.has("error")).is_false()
	assert_float(float(MilitaryCampaign.training_queue[0].required_days)).is_equal(original)
	assert_float(absf(float(second.required_days)-original*.85)).is_less(.000001)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(10)
	assert_float(float(MilitaryCampaign.training_queue[1].progress_days)).is_equal(0.0)

func test_instruction_does_not_bypass_unit_knowledge_or_recruits()->void:
	MilitaryCampaign.reset_for_new_world()
	GameState.known_discoveries.assign(["skirmish_pair_drill"])
	GameState.discovery_adoption.skirmish_pair_drill=1.0
	MilitaryCampaign.aggregate_recruits=10
	assert_bool(MilitaryCampaign.start_training("skirmisher","bow",5).has("error")).is_true()
	GameState.known_discoveries.append("bow_craft");GameState.discovery_adoption.bow_craft=1.0
	MilitaryCampaign.aggregate_recruits=0
	assert_bool(MilitaryCampaign.start_training("skirmisher","bow",5).has("error")).is_true()

func test_rival_instruction_uses_its_own_adoption()->void:
	GameState.known_discoveries.assign(["skirmish_pair_drill"])
	GameState.discovery_adoption.skirmish_pair_drill=1.0
	WorldSimulation.create_actor("school_neighbor",777,Vector2(30,0))
	var baseline:float=WorldSimulation.scoped("school_neighbor",func()->float:
		WorldSimulation.discovery.initialize();WorldSimulation.state.known_discoveries.clear()
		return Land.training_days("skirmisher"))
	assert_float(absf(Land.training_days("skirmisher")-baseline*.85)).is_less(.000001)

func test_education_description_explains_new_order_limit()->void:
	var summary:=DiscoverySystem._discovery_effect_summary(DiscoverySystem.discovery_definition("skirmish_pair_drill"))
	assert_str(summary).contains("Existing orders retain their schedule")
	assert_str(summary).contains("skirmisher 15%")
