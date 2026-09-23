extends GdUnitTestSuite
const Founding=preload("res://scripts/founding_knowledge.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(8123)
	MilitaryCampaign.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
func after_test()->void:WorldSimulation.clear()
func test_founders_know_practical_skills_but_not_farming_or_industry()->void:
	for id in Founding.PRACTICES:
		assert_dict(DiscoverySystem.discovery_definition(id)).is_not_empty()
		assert_bool(id in GameState.known_discoveries).is_true()
		assert_float(float(GameState.discovery_adoption[id])).is_equal(1.0)
	for id in ["seed_selection","animal_taming","pit_firing","bow_craft","shield_wall","bronze_alloying","internal_combustion"]:
		assert_bool(id in GameState.known_discoveries).is_false()
func test_finite_portable_supplies_are_not_replenished_by_initialize()->void:
	ResourceSystem.initialize()
	assert_float(float(GameState.resource_stockpiles.get("Civilian Goods",0))).is_greater(0)
	GameState.resource_stockpiles["Civilian Goods"]=0.0
	ResourceSystem.initialize()
	assert_float(float(GameState.resource_stockpiles["Civilian Goods"])).is_equal(0.0)
func test_spear_order_is_available_and_consumes_real_materials()->void:
	ResourceSystem.initialize()
	GameState.population_allocations.Crafting=30;GameState.population_allocations.Logistics=30
	GameState.settlement_site_committed=true
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_plots.assign([{"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}}])
	assert_bool(P.recipe(MilitaryCampaign,"spear").has("error")).is_false()
	assert_bool(P.recipe(MilitaryCampaign,"bow").has("error")).is_true()
	var timber:=float(GameState.resource_stockpiles.Timber)
	var stone:=float(GameState.resource_stockpiles.Stone)
	var order:=MilitaryCampaign.start_production_line("spear",2)
	assert_bool(order.has("error")).is_false()
	P.advance(MilitaryCampaign,MilitaryCampaign.equipment_queue.back(),100)
	assert_int(int(MilitaryCampaign.military_inventory.spear)).is_equal(2)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber-1.3,.00001)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal_approx(stone-.2,.00001)

func test_ai_can_reuse_finished_weapon_line_but_not_paused_or_player_lines()->void:
	var actor:=WorldSimulation.create_actor("pacing_supply",234)
	WorldSimulation.scoped("pacing_supply",func()->void:
		var host=WorldSimulation.military
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.state.population_allocations.Crafting=30
		WorldSimulation.state.population_allocations.Logistics=30
		WorldSimulation.state.resource_stockpiles.Timber=100.0
		WorldSimulation.state.resource_stockpiles.Stone=100.0
		var order:Dictionary=host.start_production_line("spear",1)
		assert_bool(order.has("error")).is_false()
		var job:Dictionary=host.equipment_queue.back()
		P.advance(host,job,100)
		var controller=preload("res://scripts/civilization_controller.gd")
		assert_int(controller.finished_ai_line("pacing_supply",host)).is_equal(int(job.id))
		assert_int(controller.finished_ai_line("player",host)).is_equal(-1)
		job.paused=true
		assert_int(controller.finished_ai_line("pacing_supply",host)).is_equal(-1)
		job.paused=false;job["reserved_materials"]={"Timber":.1}
		assert_int(controller.finished_ai_line("pacing_supply",host)).is_equal(-1)
	)
