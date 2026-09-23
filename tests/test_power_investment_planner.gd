extends GdUnitTestSuite
const F=preload("res://scripts/power_investment_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const C=preload("res://scripts/civilization_controller.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("power_ruler",998)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	WorldSimulation.state.known_discoveries.append(id);WorldSimulation.state.discovery_adoption[id]=1.0
func stock(id:String)->void:
	for resource:String in Ops.PLANTS[id].cost:WorldSimulation.state.resource_stockpiles[resource]=maxf(float(WorldSimulation.state.resource_stockpiles.get(resource,0)),float(Ops.PLANTS[id].cost[resource])+10.0)
## Bills name raw materials and Civilian Goods; each listed amount is taken once.
func assert_paid(before:Dictionary,id:String)->void:
	var cost:Dictionary=Ops.PLANTS[id].cost
	assert_bool(cost.has("Civilian Goods")).is_true()
	for item:String in cost:
		assert_float(float(WorldSimulation.state.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(cost[item]),.000001)
## Civilian workshop lines no longer draw power; an installed cold store is the
## real electrical consumer (3 power) unless `consumer` is false.
func prepare(consumer:bool=true)->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	for gate:String in ["electrical_generators","steam_propulsion"]:learn(gate)
	stock("steam_generator")
	state.resource_stockpiles.Coal=float(state.resource_stockpiles.Coal)+100.0;state.resource_stockpiles.Freshwater=float(state.resource_stockpiles.Freshwater)+100.0
	state.resource_stockpiles.Bitumen=100.0
	if consumer:Ops.data().plants["cold_store"]={"installed":1,"building":0,"work":0.0,"enabled":true}
func test_ai_pays_commissions_and_supplies_real_power_to_existing_consumer()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		var before:Dictionary=state.resource_stockpiles.duplicate()
		C.civilian_orders("power_ruler",{})
		assert_paid(before,"steam_generator")
		assert_int(int(Ops.data().plants.steam_generator.building)).is_equal(1)
		assert_float(Ops.service("electricity")).is_equal(0.0)
		assert_dict(F.recommendation()).is_empty()
		for day in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(1)
		var coal:float=state.resource_stockpiles.Coal
		state.elapsed_days=12;Ops.advance(12)
		assert_float(Ops.service("cold_storage")).is_equal(200.0)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(coal)
		assert_dict(F.recommendation()).is_empty()
	)
func test_no_investment_for_paused_or_absent_machinery()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var record:Dictionary=Ops.data().plants.cold_store
		record.enabled=false;assert_dict(F.recommendation()).is_empty();record.enabled=true
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		Ops.data().plants.erase("cold_store");assert_dict(F.recommendation()).is_empty()
		C.civilian_orders("power_ruler",{})
		assert_bool(Ops.data().plants.has("steam_generator")).is_false()
	)
func test_generator_respects_fuel_staff_adoption_and_controller_emergencies()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state;var coal:float=state.resource_stockpiles.Coal
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		C.civilian_orders("power_ruler",{"hungry":true});C.civilian_orders("power_ruler",{"at_war":true})
		assert_bool(Ops.data().plants.has("steam_generator")).is_false()
		state.resource_stockpiles.Coal=0.0;assert_dict(F.recommendation()).is_empty();state.resource_stockpiles.Coal=coal
		state.population_allocations.Crafting=2;assert_dict(F.recommendation()).is_empty();state.population_allocations.Crafting=20
		state.discovery_adoption.electrical_generators=.1;assert_dict(F.recommendation()).is_empty();state.discovery_adoption.electrical_generators=1.0
		state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty()
	)
func test_missing_generator_bill_is_not_granted()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state
		state.resource_stockpiles["Civilian Goods"]=0.0
		assert_dict(F.recommendation()).is_empty()
		C.civilian_orders("power_ruler",{})
		assert_bool(Ops.data().plants.has("steam_generator")).is_false()
		assert_float(float(state.resource_stockpiles["Civilian Goods"])).is_equal(0.0)
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
	)
func test_affordable_solar_preference_respects_disabled_and_adequate_capacity()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();learn("photovoltaic_power");learn("cable_insulation")
		var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
		for resource:String in Ops.PLANTS.solar_array.cost:stocks[resource]=float(stocks.get(resource,0))+float(Ops.PLANTS.solar_array.cost[resource])+10.0
		assert_str(F.recommendation().plant).is_equal("solar_array")
		Ops.data().plants["solar_array"]={"installed":1,"building":0,"work":0.0,"enabled":false}
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		assert_bool(Ops.data().plants.solar_array.enabled).is_false()
		Ops.data().plants.solar_array.enabled=true
		assert_dict(F.recommendation()).is_empty()
	)
func test_uncommissioned_unfueled_and_unstaffed_generation_does_not_authorize_new_demand()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare(false)
		Ops.data().plants.steam_generator={"installed":0,"building":1,"work":0.0,"enabled":true}
		assert_bool(F.can_supply(1.0)).is_false()
		Ops.data().plants.steam_generator.installed=1;Ops.data().plants.steam_generator.building=0
		assert_bool(F.can_supply(1.0)).is_true()
		WorldSimulation.state.resource_stockpiles.Coal=0.0;assert_bool(F.can_supply(1.0)).is_false()
		WorldSimulation.state.resource_stockpiles.Coal=100.0;WorldSimulation.state.population_allocations.Crafting=1
		assert_bool(F.can_supply(1.0)).is_false()
	)
func storage_setup()->void:
	prepare();learn("battery_bank_wiring");learn("cable_insulation")
	Ops.data().plants.steam_generator={"installed":1,"building":0,"work":0.0,"enabled":true}
	stock("battery_store")
func test_ai_commissions_empty_reserve_then_charges_and_survives_fuel_loss()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		storage_setup();var state=WorldSimulation.state
		assert_str(F.recommendation().plant).is_equal("battery_store")
		var before:Dictionary=state.resource_stockpiles.duplicate()
		C.civilian_orders("power_ruler",{})
		assert_paid(before,"battery_store")
		assert_dict(F.recommendation()).is_empty()
		for day in range(1,16):state.elapsed_days=day;Ops.advance(day)
		assert_float(float(Ops.data().plants.battery_store.stored_energy)).is_greater(0.0)
		assert_dict(F.recommendation()).is_empty()
		state.resource_stockpiles.Coal=0.0;state.elapsed_days=16;Ops.advance(16)
		assert_float(float(Ops.data().plants.battery_store.discharge_output)).is_greater(0.0)
		assert_float(Ops.service("cold_storage")).is_greater(0.0)
	)
func test_storage_investment_requires_surplus_fuel_and_respects_pause()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		storage_setup();var state=WorldSimulation.state
		assert_str(F.recommendation().plant).is_equal("battery_store")
		state.resource_stockpiles.Coal=0.0;assert_dict(F.recommendation()).is_empty();state.resource_stockpiles.Coal=100.0
		assert_dict(F.storage_recommendation(10,10,2,1)).is_empty()
		assert_dict(F.storage_recommendation(0,10,2,1)).is_empty()
		Ops.data().plants.battery_store={"installed":0,"building":0,"work":0.0,"enabled":false}
		assert_dict(F.recommendation()).is_empty()
		Ops.data().plants.erase("battery_store");state.population_allocations.Crafting=3
		assert_dict(F.recommendation()).is_empty()
	)
func test_new_demand_can_use_only_real_staffed_stored_energy()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare(false)
		Ops.data().plants.battery_store={"installed":1,"building":0,"work":0.0,"enabled":true,"stored_energy":3.0}
		assert_bool(F.can_supply(1)).is_true()
		var snapshot:=Ops.data().duplicate(true);F.can_supply(1);assert_dict(Ops.data()).is_equal(snapshot)
		Ops.data().plants.battery_store.stored_energy=0.0;assert_bool(F.can_supply(1)).is_false()
		Ops.data().plants.battery_store.stored_energy=3.0;Ops.data().plants.battery_store.enabled=false;assert_bool(F.can_supply(1)).is_false()
		Ops.data().plants.battery_store.enabled=true;WorldSimulation.state.population_allocations.Crafting=1;assert_bool(F.can_supply(1)).is_false()
	)
func test_missing_bank_bill_is_not_granted_and_regulation_is_preferred()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		storage_setup();var state=WorldSimulation.state
		state.resource_stockpiles["Lead Ore"]=0.0
		assert_dict(F.recommendation()).is_empty()
		assert_float(float(state.resource_stockpiles["Lead Ore"])).is_equal(0.0)
		learn("charge_regulation");stock("battery_store");stock("regulated_battery_store")
		assert_str(F.recommendation().plant).is_equal("regulated_battery_store")
		state.discovery_adoption.charge_regulation=.1
		assert_str(F.recommendation().plant).is_equal("battery_store")
	)
