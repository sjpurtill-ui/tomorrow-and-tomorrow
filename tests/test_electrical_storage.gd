extends GdUnitTestSuite
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize();MilitaryCampaign.reset_for_new_world()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0;GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.population_allocations.Crafting=10
	GameState.resource_stockpiles.Bitumen=10.0
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func ready(id:String,energy:float=0)->void:
	Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
	if Ops.PLANTS[id].has("storage"):Ops.data().plants[id].stored_energy=energy
func tick(day:int)->void:
	GameState.elapsed_days=day;Ops.advance(day)
func near(actual:float,expected:float)->void:
	assert_float(absf(actual-expected)).is_less(.000001)
func test_charging_consumes_generation_and_respects_capacity()->void:
	ready("solar_array");ready("battery_store");tick(1)
	near(Ops.data().plants.battery_store.charge_input,3)
	near(Ops.data().plants.battery_store.stored_energy,2.4)
	near(Ops.data().plants.solar_array.running_units,.75)
	near(Ops.service("electricity"),0)
	for day in range(2,20):tick(day)
	near(Ops.data().plants.battery_store.stored_energy,12)
	assert_bool(Ops.valid(Ops.data())).is_true()
func test_consumers_take_priority_over_charging()->void:
	ready("solar_array");ready("cold_store");ready("battery_store");tick(1)
	near(Ops.service("cold_storage"),200)
	near(Ops.data().plants.battery_store.stored_energy,.8)
	near(Ops.data().plants.solar_array.running_units,1)
	GameState.population_health=.5;tick(2)
	near(Ops.service("cold_storage"),100)
	near(Ops.data().plants.solar_array.running_units,.5)
func test_interruption_draws_down_energy_and_forecast_expires()->void:
	ready("cold_store");ready("battery_store",12);tick(1)
	near(Ops.service("cold_storage"),200)
	near(Ops.data().plants.battery_store.stored_energy,8.238)
	near(Ops.forecast_service("cold_storage",1),200)
	near(Ops.forecast_service("cold_storage",3),0)
	for day in range(2,7):tick(day)
	near(Ops.service("cold_storage"),0)
	near(Ops.data().plants.battery_store.stored_energy,0)
func test_short_staff_preserves_consumer_operators()->void:
	ready("cold_store");ready("battery_store",12)
	GameState.population_allocations.Crafting=1;tick(1)
	near(Ops.service("cold_storage"),100)
	assert_float(float(Ops.data().workers)).is_less_equal(1.0)
	near(Ops.data().plants.battery_store.discharge_output,1.5)
func test_missing_consumables_does_not_drain_battery()->void:
	ready("cold_store");ready("battery_store",12)
	GameState.resource_stockpiles.Bitumen=0.0;tick(1)
	near(Ops.data().plants.battery_store.discharge_output,0)
	near(Ops.data().plants.battery_store.stored_energy,11.988)
func test_idle_travel_and_save_preserve_finite_energy()->void:
	ready("cold_store");ready("battery_store",12)
	GameState.convoy_traveling=true;tick(1)
	near(Ops.service("cold_storage"),0)
	near(Ops.data().plants.battery_store.stored_energy,11.988)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()))
	assert_bool(Ops.valid(saved)).is_true()
	GameState.technology_operations=saved;GameState.convoy_traveling=false;tick(2)
	near(Ops.service("cold_storage"),200)
	saved.plants.battery_store.stored_energy=13.0
	assert_bool(Ops.valid(saved)).is_false()
	saved.plants.battery_store.stored_energy=NAN
	assert_bool(Ops.valid(saved)).is_false()
func test_no_same_day_bank_to_bank_recharging()->void:
	ready("cold_store");ready("battery_store",12);ready("regulated_battery_store");tick(1)
	near(Ops.service("cold_storage"),200)
	near(Ops.data().plants.regulated_battery_store.charge_input,0)
	near(Ops.data().plants.regulated_battery_store.stored_energy,0)
func learn(id:String)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=1.0
func test_manufactured_bank_commissions_empty_then_charges()->void:
	var industry=preload("res://scripts/civilian_industry.gd")
	var production=preload("res://scripts/persistent_production.gd")
	var knowledge=preload("res://scripts/electrical_storage_knowledge.gd")
	assert_int(knowledge.entries().size()).is_equal(7)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(knowledge.entries(),DiscoverySystem.technology_catalog)).is_empty()
	var plan:={"refined_lead":4,"lead_electrode_sheets":2,"lead_oxide":2,"battery_separators":2,"lead_acid_cell":2,"battery_bank":1}
	var outputs:Array=[]
	for item:String in plan:outputs.append(industry.product(item).output)
	for item:String in plan:
		var recipe:Dictionary=industry.product(item);learn(recipe.gate)
		for material:String in recipe.materials:
			if material not in outputs:GameState.resource_stockpiles[material]=50.0
		for material:String in recipe.tooling:
			if material not in outputs:GameState.resource_stockpiles[material]=50.0
	for output:String in outputs:GameState.resource_stockpiles[output]=0.0
	ready("solar_array");var day:=0
	for item:String in plan:
		var recipe:Dictionary=industry.product(item)
		assert_bool(MilitaryCampaign.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
		var job:Dictionary=MilitaryCampaign.equipment_queue.back()
		for attempt in 40:
			day+=1;tick(day);production.advance(MilitaryCampaign,job,1.0)
			if int(job.completed)>=int(plan[item]):break
		assert_int(int(job.completed)).is_equal(int(plan[item]))
		assert_bool(MilitaryCampaign.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
	near(GameState.resource_stockpiles["Battery Banks"],1)
	learn("cable_insulation")
	assert_bool(Ops.install("battery_store").get("ok",false)).is_true()
	near(GameState.resource_stockpiles["Battery Banks"],0)
	while int(Ops.data().plants.battery_store.installed)==0:
		day+=1;tick(day)
	near(Ops.data().plants.battery_store.get("stored_energy",0),0)
	day+=1;tick(day)
	near(Ops.data().plants.battery_store.stored_energy,2.4)
func test_pending_workshop_keeps_power_and_labor_while_charging()->void:
	var industry=preload("res://scripts/civilian_industry.gd")
	var production=preload("res://scripts/persistent_production.gd")
	var recipe:Dictionary=industry.product("electrolytic_hydrogen");learn(recipe.gate)
	for item:String in recipe.materials:GameState.resource_stockpiles[item]=10.0
	for item:String in recipe.tooling:GameState.resource_stockpiles[item]=10.0
	MilitaryCampaign.production_labor_share=.5
	assert_bool(MilitaryCampaign.start_production_line("electrolytic_hydrogen",1).get("ok",false)).is_true()
	ready("solar_array");ready("battery_store");tick(1)
	near(Ops.service("electricity"),2)
	near(Ops.data().plants.battery_store.charge_input,2)
	assert_float(GameState.effective_workers("Crafting")).is_greater(0.0)
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	production.advance(MilitaryCampaign,job,1.0)
	assert_float(Ops.service("electricity")).is_less(2.0)

func test_battery_powered_workshop_keeps_workers_for_production()->void:
	var industry=preload("res://scripts/civilian_industry.gd")
	var recipe:Dictionary=industry.product("electrolytic_hydrogen");learn(recipe.gate)
	for item:String in recipe.materials:GameState.resource_stockpiles[item]=10.0
	for item:String in recipe.tooling:GameState.resource_stockpiles[item]=10.0
	MilitaryCampaign.production_labor_share=.5;GameState.population_allocations.Crafting=1
	assert_bool(MilitaryCampaign.start_production_line("electrolytic_hydrogen",1).get("ok",false)).is_true()
	ready("battery_store",12);tick(1)
	near(Ops.service("electricity"),1.5)
	near(GameState.effective_workers("Crafting"),.5)
	preload("res://scripts/persistent_production.gd").advance(MilitaryCampaign,MilitaryCampaign.equipment_queue.back(),.25)
	assert_float(Ops.service("electricity")).is_less(1.5)
func test_owned_bank_energy_round_trips_without_changing_player()->void:
	WorldSimulation.create_actor("battery_owner",314)
	WorldSimulation.scoped("battery_owner",func()->void:
		WorldSimulation.state.technology_operations.plants.battery_store={"installed":1,"building":0,"work":0.0,"enabled":true,"stored_energy":7.0}
	)
	var saved:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(saved)).is_empty()
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	WorldSimulation.scoped("battery_owner",func()->void:
		near(Ops.data().plants.battery_store.stored_energy,7)
	)
	assert_dict(GameState.technology_operations.plants).is_empty()
	saved.actors.battery_owner.state.GameState.technology_operations.plants.battery_store.installed=0
	assert_bool(WorldSimulation.validate_payload(saved).is_empty()).is_false()
