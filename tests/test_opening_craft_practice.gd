extends GdUnitTestSuite

const Craft=preload("res://scripts/opening_craft_practice.gd")
const Paths=preload("res://scripts/knowledge_pathways.gd")
const Requirements=preload("res://scripts/technology_requirements.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(5001)
	# Causal prerequisite tests construct their own knowledge, independent of the founding preset.
	GameState.known_discoveries=[];GameState.discovery_adoption={}
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.settlement_site_committed=true
	GameState.opening_craft_practice=Craft.empty_state();GameState.opening_craft_practice.initialized=true
	DiscoverySystem.latest_context={"food":1.0,"fiber":1.0,"clay":1.0,"timber":1.0,"crafting":1.0,"stone":1.0}

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(ids:Array[String])->void:
	for id:String in ids:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func test_opening_materials_follow_causal_foundations()->void:
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("food_drying"),0)).is_false()
	know(["edible_resource_recognition"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("food_drying"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("cordage"),0)).is_false()
	know(["fiber_grading"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("cordage"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("clay_shaping"),0)).is_false()
	know(["clay_testing"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("clay_shaping"),0)).is_true()
	know(["clay_shaping"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("clay_tempering"),0)).is_false()
	know(["cordage"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("basketry"),0)).is_true()
	know(["pit_firing"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("clay_tempering"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("joinery"),0)).is_false()
	know(["hafted_tools","timber_grading"]);assert_bool(Paths.ready(DiscoverySystem.discovery_definition("joinery"),0)).is_true()

func test_practical_effects_require_and_track_physical_stock()->void:
	know(["fiber_grading","cordage"])
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("haul_capacity")).is_equal(0.0)
	GameState.resource_stockpiles[Craft.PRODUCTS.cordage]=Craft.target("cordage")
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("haul_capacity")).is_equal_approx(.08,.000001)
	for item:Dictionary in preload("res://scripts/hud/atlas_data.gd").inquiry("","Twisted Cordage"):
		assert_str(String(item.operating_summary)).contains("Cordage Bundles").contains("100%")
	GameState.resource_stockpiles[Craft.PRODUCTS.cordage]=Craft.target("cordage")*.5
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("haul_capacity")).is_equal_approx(.04,.000001)

func test_real_inputs_build_the_connected_chain()->void:
	know(["controlled_flaking","fiber_grading","cordage","food_drying","smoking","hafted_tools","basketry","clay_testing","clay_shaping","pit_firing","clay_tempering","sealed_vessels","timber_grading","joinery","ember_tending"])
	GameState.population_allocations.Crafting=100
	GameState.resource_stockpiles={"Flint":20.0,"Stone":20.0,"Fiber Plants":30.0,"Timber":30.0,"Clay":20.0,"Freshwater":20.0}
	GameState.fire_practice={"initialized":true,"embers":.7,"last_day":-1,"source":"test","last_event":"test","fuel_today":0.0,"ignitions":0,"extinctions":0}
	var before:=GameState.resource_stockpiles.duplicate(true)
	var report:=Craft.advance()
	for product:String in Craft.PRODUCTS.values():assert_float(float(GameState.resource_stockpiles.get(product,0.0))).override_failure_message(product).is_greater(0.0)
	assert_float(float(GameState.resource_stockpiles.Flint)).is_less(float(before.Flint))
	assert_float(float(GameState.resource_stockpiles["Fiber Plants"])).is_less(float(before["Fiber Plants"]))
	assert_float(float(GameState.resource_stockpiles.Clay)).is_less(float(before.Clay))
	assert_float(float(report.workers)).is_greater(0.0)
	assert_bool(Craft.valid(Craft.data())).is_true()

func test_pit_firing_cannot_operate_without_a_live_fire()->void:
	know(["clay_testing","clay_shaping","pit_firing"])
	GameState.population_allocations.Crafting=100
	GameState.resource_stockpiles={"Unfired Clay Vessels":5.0,"Timber":5.0}
	Craft.advance()
	assert_float(Craft.stock("Fired Clay Vessels")).is_equal(0.0)
	GameState.elapsed_days=1;GameState.fire_practice={"initialized":true,"embers":.7,"last_day":0,"source":"test","last_event":"test","fuel_today":0.0,"ignitions":0,"extinctions":0}
	Craft.advance()
	assert_float(Craft.stock("Fired Clay Vessels")).is_greater(0.0)

func test_opening_practice_is_actor_and_secondary_city_local()->void:
	know(["fiber_grading","cordage"]);GameState.resource_stockpiles["Fiber Plants"]=10.0;GameState.population_allocations.Crafting=20
	Craft.advance();var home:=Craft.stock("Cordage Bundles");assert_float(home).is_greater(0.0)
	GameState.player_settlements.append({"id":"second","name":"Second","position":Vector2(10,0),"population_share":.25,"founded_day":0})
	WorldSimulation.settlements.with_city_resources("second",func()->void:
		assert_float(Craft.stock("Cordage Bundles")).is_equal(0.0)
		assert_bool(Craft.valid(Craft.data())).is_true()
	)
	assert_float(Craft.stock("Cordage Bundles")).is_equal(home)
	WorldSimulation.create_actor("other",5002)
	WorldSimulation.scoped("other",func()->void:
		var inherited:Dictionary=preload("res://scripts/founding_knowledge.gd").portable_supplies(WorldSimulation.state.population_exact)
		assert_float(Craft.stock("Cordage Bundles")).is_equal(float(inherited["Cordage Bundles"]))
	)

func test_repaired_live_graph_remains_reachable()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(Paths.graph_entry(entry))
	var dormant=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(Requirements.validate(graph,dormant.pending(graph))).is_empty()
