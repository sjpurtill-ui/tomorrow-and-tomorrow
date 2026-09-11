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

const Ops=preload("res://scripts/technology_operations.gd")
func prepare()->void:
	GameState.elapsed_days=0
	GameState.settlement_site_committed=true
	GameState.convoy_traveling=false
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.population_allocations.Crafting=10
	for spec:Dictionary in Ops.PLANTS.values():
		for gate:String in [spec.gate]+spec.requires:
			if gate not in GameState.known_discoveries:GameState.known_discoveries.append(gate)
			GameState.discovery_adoption[gate]=1.0
		for item:String in spec.cost:GameState.resource_stockpiles[item]=100.0
		for item:String in spec.inputs:GameState.resource_stockpiles[item]=100.0

func tick(day:int)->void:
	GameState.elapsed_days=day;Ops.advance(day)

func running_cold_store()->void:
	prepare()
	assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
	assert_bool(Ops.install("cold_store").get("ok",false)).is_true()
	for day in range(1,12):tick(day)

func test_knowledge_and_stored_machines_do_not_provide_free_power()->void:
	prepare()
	assert_float(Ops.service("cold_storage")).is_equal(0.0)
	var before:float=GameState.resource_stockpiles["Electrical Generators"]
	assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
	assert_float(float(GameState.resource_stockpiles["Electrical Generators"])).is_equal(before-1)
	assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(0)
	tick(1)
	assert_float(Ops.service("electricity")).is_equal(0.0)
	assert_float(GameState.effective_workers("Crafting")).is_equal(8.0)

func test_fuel_power_and_staff_are_conserved_and_daily_delivery_is_idempotent()->void:
	running_cold_store()
	assert_float(Ops.service("cold_storage")).is_equal(200.0)
	assert_float(absf(float(Ops.data().inputs.Coal)-.15)).is_less(.000001)
	assert_float(absf(float(Ops.data().workers)-1.6)).is_less(.000001)
	assert_float(absf(GameState.effective_workers("Crafting")-8.4)).is_less(.000001)
	assert_float(Ops.service("electricity")).is_equal(0.0)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	Ops.advance(11)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)

func test_fuel_interruption_stops_refrigeration_without_forgetting_knowledge()->void:
	running_cold_store();GameState.resource_stockpiles.Coal=0.0
	tick(12)
	assert_float(Ops.service("cold_storage")).is_equal(0.0)
	assert_str(Ops.status("steam_generator")).contains("Coal")
	assert_float(GameState.effective_workers("Crafting")).is_equal(10.0)
	assert_bool("mechanical_refrigeration" in GameState.known_discoveries).is_true()
	GameState.resource_stockpiles.Coal=1.0;tick(13)
	assert_float(Ops.service("cold_storage")).is_equal(200.0)

func test_cooling_changes_actual_spoilage_with_finite_capacity()->void:
	running_cold_store()
	GameState.food_stocks={"Fresh meat":400.0}
	var losses:=FoodSystem._spoil(false)
	assert_float(absf(float(losses["Fresh meat"])-400*.045*.6)).is_less(.000001)
	assert_float(Ops.refrigeration_multiplier(200,{"Dry staples":400.0})).is_equal(1.0)

func test_idle_generator_does_not_burn_fuel_without_consumers()->void:
	prepare();Ops.install("steam_generator")
	var coal:float=GameState.resource_stockpiles.Coal
	for day in range(1,15):tick(day)
	assert_float(float(GameState.resource_stockpiles.Coal)).is_equal(coal)
	assert_float(Ops.service("electricity")).is_equal(0.0)

func test_operator_shortage_scales_service_and_never_overbooks_workers()->void:
	running_cold_store();GameState.population_allocations.Crafting=1
	tick(12)
	assert_float(Ops.service("cold_storage")).is_less(200.0)
	assert_float(float(Ops.data().workers)).is_less_equal(1.0)
	assert_float(GameState.effective_workers("Crafting")).is_greater_equal(0.0)

func test_saved_installations_resume_and_malformed_counts_are_rejected()->void:
	running_cold_store()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()))
	assert_bool(Ops.valid(saved)).is_true()
	GameState.technology_operations=saved
	tick(12)
	assert_float(Ops.service("cold_storage")).is_equal(200.0)
	saved.plants.cold_store.installed=-1
	assert_bool(Ops.valid(saved)).is_false()

func test_forecast_does_not_promise_cooling_beyond_stored_fuel()->void:
	running_cold_store();GameState.resource_stockpiles.Coal=.16
	assert_float(Ops.forecast_service("cold_storage",1)).is_equal(200.0)
	assert_float(Ops.forecast_service("cold_storage",2)).is_equal(0.0)

func test_travel_stops_settlement_services_and_releases_staff()->void:
	running_cold_store();GameState.convoy_traveling=true;tick(12)
	assert_float(Ops.service("cold_storage")).is_equal(0.0)
	assert_float(GameState.effective_workers("Crafting")).is_equal(10.0)

func test_research_inspector_install_action_reserves_real_equipment()->void:
	prepare()
	var panel:VBoxContainer=auto_free(preload("res://scripts/hud/technology_operations_panel.gd").new())
	panel.subject="mechanical_refrigeration";add_child(panel)
	panel.rows.cold_store.build.pressed.emit()
	assert_int(int(Ops.data().plants.cold_store.building)).is_equal(1)
	assert_float(float(GameState.resource_stockpiles["Electric Motors"])).is_equal(99.0)

func test_powered_workshop_improves_actual_production_without_creating_workers()->void:
	prepare()
	var baseline:=MilitaryCampaign._base_production_rate()
	Ops.install("steam_generator");Ops.install("powered_workshop")
	for day in range(1,12):tick(day)
	assert_float(MilitaryCampaign._base_production_rate()).is_greater(baseline)
	assert_float(GameState.effective_workers("Crafting")).is_less(10.0)
	GameState.resource_stockpiles.Coal=0.0;tick(12)
	assert_float(absf(MilitaryCampaign._base_production_rate()-baseline)).is_less(.000001)

func test_new_construction_does_not_displace_operating_cold_store()->void:
	running_cold_store()
	Ops.install("powered_workshop",5);tick(12)
	assert_float(Ops.service("cold_storage")).is_equal(200.0)
	assert_float(float(Ops.data().workers)).is_less_equal(10.0)

func test_rival_installation_ledger_is_independent()->void:
	running_cold_store()
	WorldSimulation.create_actor("plant_neighbor",777,Vector2(30,0))
	var capacity:float=WorldSimulation.scoped("plant_neighbor",func()->float:return Ops.service("cold_storage"))
	assert_float(capacity).is_equal(0.0)
	assert_float(Ops.service("cold_storage")).is_equal(200.0)

func test_invalid_operating_service_rejected_before_loading()->void:
	var bad:=Ops.empty_state();bad.services={"infinite_food":100.0}
	assert_bool(Ops.valid(bad)).is_false()
	var result:=SaveSystem._validate_human_payload({"reflected_GameState":{"technology_operations":bad}},777)
	assert_bool(result.has("error")).is_true()
