extends GdUnitTestSuite

const Paths=preload("res://scripts/knowledge_pathways.gd")
const Requirements=preload("res://scripts/technology_requirements.gd")
const FIRE_IDS=["ember_tending","friction_fire_ignition","percussion_fire_ignition","hearth_heat_retention","fuel_air_drying"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4021)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	DiscoverySystem.latest_context={"fire":1.0,"food":1.0,"clay":1.0,"timber":1.0,"crafting":1.0}

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_authored_fire_practices_are_live_unique_discoveries()->void:
	for id:String in FIRE_IDS:
		var entry:=DiscoverySystem.discovery_definition(id)
		assert_bool(entry.is_empty()).override_failure_message(id).is_false()
		assert_str(String(entry.get("production_contract",""))).is_not_empty()
		assert_bool(entry.get("effects",{}).is_empty()).is_true()
	var live_ids:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:live_ids.append(String(entry.id))
	for id:String in FIRE_IDS:assert_int(live_ids.count(id)).is_equal(1)

func test_fire_is_first_preserved_then_deliberately_recreated()->void:
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("ember_tending"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("friction_fire_ignition"),0)).is_false()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("percussion_fire_ignition"),0)).is_false()
	GameState.known_discoveries.append("ember_tending")
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("friction_fire_ignition"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("percussion_fire_ignition"),0)).is_false()
	GameState.known_discoveries.append("stone_sorting")
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("percussion_fire_ignition"),0)).is_true()

func test_cooking_and_charcoal_cannot_precede_a_controlled_hearth()->void:
	GameState.known_discoveries.assign(["ember_tending","food_drying"])
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("hearth_roasting_control"),0)).is_false()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("charcoal"),0)).is_false()
	GameState.known_discoveries.append("hearth_heat_retention")
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("hearth_roasting_control"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("charcoal"),0)).is_true()

func test_preservation_and_ceramics_keep_branches_without_bypassing_fire()->void:
	var smoking:=DiscoverySystem.discovery_definition("smoking")
	var firing:=DiscoverySystem.discovery_definition("pit_firing")
	GameState.known_discoveries.assign(["food_drying","clay_shaping"])
	assert_bool(Paths.ready(smoking,0)).is_false()
	assert_bool(Paths.ready(firing,0)).is_false()
	GameState.known_discoveries.append("hearth_heat_retention")
	assert_bool(Paths.ready(smoking,0)).is_true()
	assert_bool(Paths.ready(firing,0)).is_true()
	assert_str(String(Paths.chosen(smoking,0).id)).is_equal("local")
	assert_str(String(Paths.chosen(firing,0).id)).is_equal("experimental")
	GameState.known_discoveries.erase("food_drying")
	GameState.known_discoveries.append("charcoal")
	assert_bool(Paths.ready(smoking,0)).is_true()
	assert_bool(Paths.ready(firing,0)).is_true()
	assert_str(String(Paths.chosen(smoking,0).id)).is_equal("charcoal")
	assert_str(String(Paths.chosen(firing,0).id)).is_equal("local")

func test_opening_fire_repairs_leave_the_live_graph_reachable()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(Paths.graph_entry(entry))
	var dormant=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(Requirements.validate(graph,dormant.pending(graph))).is_empty()
