extends GdUnitTestSuite
const Materials=preload("res://scripts/construction_materials.gd")
const Construction=preload("res://scripts/settlement_construction.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
func before_test()->void:
	GameState.reset_for_new_world(42);SettlementModel.reset_for_new_world()
	GameState.resource_stockpiles={"Clay":100.0,"Fiber Plants":100.0,"Timber":0.0,"Stone":0.0}
	GameState.known_discoveries=["clay_shaping"]

func test_every_starter_work_can_use_delivered_clay_and_fiber_without_timber()->void:
	for project:Dictionary in Construction._settlement_definitions():
		var cost:=Construction._settlement_project_material_plan(project)
		assert_bool(cost.is_empty()).is_false()
		assert_float(float(cost.get("Timber",0))).is_equal(0.0)

func test_builders_conserve_scarce_timber_when_clay_is_abundant()->void:
	GameState.resource_stockpiles["Timber"]=2.0
	var recipe:=SettlementModel._available_household_recipe()
	assert_str(recipe.family).is_equal("earth")
	assert_bool(recipe.mix.has("Timber")).is_false()
	assert_dict(GameState.resource_stockpiles).contains_key_value("Timber",2.0)
	GameState.resource_stockpiles={"Timber":100.0,"Fiber Plants":100.0,"Clay":3.2}
	assert_str(SettlementModel._available_household_recipe().family).is_equal("organic")

func test_earthen_building_knowledge_and_delivered_materials_are_required()->void:
	GameState.known_discoveries=[]
	assert_bool(SettlementModel._available_household_recipe().is_empty()).is_true()
	GameState.known_discoveries=["clay_shaping"]
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	assert_bool(SettlementModel._available_household_recipe().is_empty()).is_true()

func test_courts_workshops_and_stores_have_feasible_earthen_variants()->void:
	for use:String in ["workshop","storage","market","hospitality","civic"]:
		var recipe:=SettlementModel._available_functional_recipe(use)
		assert_bool(recipe.is_empty()).is_false()
		assert_str(recipe.family).is_equal("earth")
		assert_bool(recipe.cost.has("Timber")).is_false()
	# Processing still requires real fuel; clay cannot be burned in its place.
	assert_bool(SettlementModel._available_functional_recipe("dirty_industry").is_empty()).is_true()

func test_completed_clay_shelters_pay_once_and_keep_earthen_visuals()->void:
	GameState.resource_stockpiles["Fiber Plants"]=20.0
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.population_allocations={"Construction":8,"Logistics":5,"Crafting":4}
	GameState.settlement_projects={"Lean-to Shelters":1000.0}
	GameState.population_total=110;GameState.population_exact=110
	GameState.simulation_metrics={"labor_efficiency":1.0}
	GameState.settlement_plots=[{"id":1,"seed":1,"land_use":"residential_compound","form":"portable_shelter_cluster","material_family":"organic","storeys":1,"roof_coverage":.1}]
	var before:=GameState.resource_stockpiles.duplicate(true)
	var events:=Construction.process_day()
	assert_int(events.size()).is_equal(1)
	assert_str(events[0].kind).is_equal("Lean-to Shelters")
	assert_str(events[0].material_family).is_equal("earth")
	assert_float(GameState.resource_stockpiles.Clay).is_equal(float(before.Clay)-float(events[0].materials.Clay))
	var paid:=GameState.resource_stockpiles.duplicate(true)
	SettlementModel._synchronize_early_works(20,[])
	assert_dict(GameState.resource_stockpiles).is_equal(paid)
	assert_str(Early.kind(GameState.settlement_plots[0])).is_equal("earthen_household")
	SettlementModel._synchronize_early_works(21,[])
	assert_dict(GameState.resource_stockpiles).is_equal(paid)

func test_stone_policy_cannot_select_an_unaffordable_recipe()->void:
	var recipes:Array[Dictionary]=[{"family":"earth","cost":{"Clay":4}}, {"family":"stone","cost":{"Stone":4}}]
	var choice:=Materials.choose(recipes,{"Clay":10,"Stone":0},[],100)
	assert_str(choice.family).is_equal("earth")

func test_city_supply_context_selects_its_own_materials()->void:
	GameState.initialize_population_model();GameState.ensure_population_total(1000)
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"other","name":"Claybank","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":20})
	var city:=SettlementModel.settlement_record("other")
	SettlementModel._ensure_city_resources(city)
	city.local_resources.resource_stockpiles={"Timber":100.0,"Fiber Plants":100.0,"Clay":0.0}
	SettlementModel.with_city_resources("other",func()->void:assert_str(SettlementModel._available_household_recipe().family).is_equal("organic"))
	assert_str(SettlementModel._available_household_recipe().family).is_equal("earth")
