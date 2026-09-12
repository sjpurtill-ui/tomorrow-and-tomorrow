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

func test_new_catalog_contract_and_graph_are_valid()->void:
	var additions:=preload("res://scripts/food_water_knowledge.gd").entries()
	assert_int(additions.size()).is_equal(12)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(additions,DiscoverySystem.technology_catalog)).is_empty()
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	assert_array(R.validate(graph)).is_empty()

func test_cisterns_have_three_lining_routes_without_an_aqueduct_gate()->void:
	var entry:=DiscoverySystem.discovery_definition("rainwater_cisterns")
	for lining:String in ["sealed_vessels","lime_mortar","bitumen_sealing"]:
		GameState.known_discoveries.assign(["drainage",lining])
		assert_bool(P.ready(entry,100000)).is_true()
	GameState.known_discoveries.assign(["lime_mortar"])
	assert_bool(P.ready(entry,100000)).is_false()

func test_water_inspections_accept_well_or_cistern_and_keep_record_foundations()->void:
	var entry:=DiscoverySystem.discovery_definition("water_service_inspections")
	for supply:String in ["protected_wellheads","rainwater_cisterns"]:
		GameState.known_discoveries.assign(["case_records","standard_measures",supply])
		assert_bool(P.ready(entry,100000)).is_true()
	GameState.known_discoveries.assign(["protected_wellheads"])
	assert_bool(P.ready(entry,100000)).is_false()

func storage_setup()->void:
	GameState.settlement_site_committed=true
	GameState.population_allocations.Logistics=10
	GameState.population_allocations.Crafting=0
	GameState.known_discoveries.assign(["root_cellars"])
	GameState.discovery_adoption.root_cellars=1.0

func test_cellars_affect_plants_but_not_meat_or_travel()->void:
	storage_setup()
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",false)).is_equal(.84)
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh meat",false)).is_equal(1.0)
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",true)).is_equal(1.0)
	GameState.settlement_site_committed=false
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",false)).is_equal(1.0)

func test_adoption_scales_benefit_and_staff_absence_preserves_knowledge()->void:
	storage_setup()
	GameState.discovery_adoption.root_cellars=.5
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",false)).is_equal(.92)
	GameState.population_allocations.Logistics=0
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",false)).is_equal(1.0)
	assert_bool("root_cellars" in GameState.known_discoveries).is_true()

func test_real_food_losses_change_only_for_the_supported_category()->void:
	storage_setup()
	GameState.known_discoveries.clear()
	GameState.food_stocks={"Fresh plants":100.0,"Fresh meat":100.0}
	var baseline:=FoodSystem._spoil(false)
	GameState.known_discoveries.assign(["root_cellars"])
	GameState.food_stocks={"Fresh plants":100.0,"Fresh meat":100.0}
	var protected:=FoodSystem._spoil(false)
	assert_float(absf(float(protected["Fresh plants"])-float(baseline["Fresh plants"])*.84)).is_less(.000001)
	assert_float(float(protected["Fresh meat"])).is_equal(float(baseline["Fresh meat"]))

func test_contract_rejects_unknown_effect_and_invalid_food_type()->void:
	var entry:Dictionary=preload("res://scripts/food_water_knowledge.gd").entries()[0].duplicate(true)
	entry.effects={"magic_food":.1}
	entry.preservation_profile={"Unmodeled food":.2}
	var errors:=preload("res://scripts/technology_catalog_contract.gd").validate([entry],[entry])
	assert_int(errors.size()).is_equal(2)

func test_inspector_explains_storage_limits()->void:
	var summary:=DiscoverySystem._discovery_effect_summary(DiscoverySystem.discovery_definition("root_cellars"))
	assert_str(summary).contains("Fresh plants 16%")
	assert_str(summary).contains("unavailable during travel")

func test_food_forecast_uses_the_same_preservation_profile()->void:
	storage_setup()
	GameState.food_stocks={"Fresh plants":100.0}
	var baseline:=FoodSystem._forecast(1,{}, {},true)
	var improved:=FoodSystem._forecast(1,{}, {},false)
	assert_float(float(improved.spoilage)).is_less(float(baseline.spoilage))
	assert_float(absf(float(improved.spoilage)-100.0*.022*.84)).is_less(.000001)
	assert_float(float(GameState.food_stocks["Fresh plants"])).is_equal(100.0)

func test_rival_storage_uses_its_own_knowledge_and_adoption()->void:
	storage_setup()
	WorldSimulation.create_actor("storage_neighbor",314159,Vector2(30,0))
	var rival_result:float=WorldSimulation.scoped("storage_neighbor",func()->float:
		WorldSimulation.discovery.initialize()
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.state.population_allocations.Logistics=10
		WorldSimulation.state.known_discoveries.clear()
		return WorldSimulation.discovery.food_storage_multiplier("Fresh plants",false))
	assert_float(rival_result).is_equal(1.0)
	rival_result=WorldSimulation.scoped("storage_neighbor",func()->float:
		WorldSimulation.state.known_discoveries.assign(["root_cellars"])
		WorldSimulation.state.discovery_adoption.root_cellars=.5
		return WorldSimulation.discovery.food_storage_multiplier("Fresh plants",false))
	assert_float(rival_result).is_equal(.92)
	assert_float(DiscoverySystem.food_storage_multiplier("Fresh plants",false)).is_equal(.84)
