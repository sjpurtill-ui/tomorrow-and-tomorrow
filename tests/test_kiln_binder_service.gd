extends GdUnitTestSuite

const Ops=preload("res://scripts/technology_operations.gd")
const Industry=preload("res://scripts/civilian_industry.gd")
const Craft=preload("res://scripts/opening_craft_practice.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(7520);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id="";GameState.ensure_population_total(100)
	GameState.population_allocations.Crafting=10;GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.resource_stockpiles={"Stone":20.0,"Clay":10.0,"Joined Timber Components":3.0,"Timber":4.0,"Limestone":10.0,"Unfired Clay Conduits":4.0}

func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(ids:Array[String])->void:
	for id:String in ids:GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0

func install_kiln()->void:
	know(["kiln_control"]);assert_bool(Ops.install("controlled_kiln").get("ok",false)).is_true()
	for day:int in range(1,14):GameState.elapsed_days=day;Ops.advance(day)

func test_kiln_knowledge_has_no_effect_without_paid_operating_capital()->void:
	know(["kiln_control"]);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("craft_output")).is_equal(0.0)
	assert_bool(Ops.quote("controlled_kiln").get("ok",false)).is_true()

func test_kiln_consumes_capital_work_fuel_and_provides_bounded_heat()->void:
	install_kiln()
	assert_int(int(Ops.data().plants.controlled_kiln.installed)).is_equal(1)
	assert_int(int(Ops.data().plants.controlled_kiln.building)).is_equal(0)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(8.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(3.5)
	assert_float(Ops.service("kiln_heat")).is_equal(4.0)
	DiscoverySystem.refresh_operating_effects();assert_float(DiscoverySystem.effect("craft_output")).is_equal_approx(.09,.00001)
	GameState.resource_stockpiles.Timber=0.0;GameState.elapsed_days=14;Ops.advance(14);DiscoverySystem.refresh_operating_effects()
	assert_float(Ops.service("kiln_heat")).is_equal(0.0);assert_float(DiscoverySystem.effect("craft_output")).is_equal(0.0)

func test_fired_pipe_and_quicklime_recipes_require_shared_kiln_heat()->void:
	assert_float(float(Industry.product("fired_clay_conduits").services.kiln_heat)).is_equal(1.0)
	assert_float(float(Industry.product("quicklime").services.kiln_heat)).is_equal(1.5)
	assert_bool(Industry.product("quicklime").materials.has("Timber")).is_false()

func test_lime_effects_follow_physical_stock_and_installed_masonry()->void:
	know(["lime_burning","lime_mortar"]);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("construction_rate")).is_equal(0.0)
	GameState.resource_stockpiles["Quicklime"]=2.0;DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("lime_burning")).is_equal(1.0)
	assert_float(DiscoverySystem.effect("construction_rate")).is_equal_approx(.08,.00001)
	GameState.settlement_plots=[{"form":"lime_masonry_household","status":"active","condition":.5}];DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("lime_mortar")).is_equal(.5)
	assert_float(DiscoverySystem.effect("housing_output")).is_equal_approx(.06,.00001)
