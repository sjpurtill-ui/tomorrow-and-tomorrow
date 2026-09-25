extends GdUnitTestSuite
const Ops=preload("res://scripts/technology_operations.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Bills=preload("res://scripts/goods_bills.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("polymers",4986)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func prepare()->void:
	var s=WorldSimulation.state
	s.settlement_site_committed=true;s.convoy_traveling=false;s.elapsed_days=0
	s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	for gate:String in ["radical_chain_polymerization","polymer_reaction_heat_management","pressure_vessels","precision_thermometry","electric_motors"]:
		s.known_discoveries.append(gate);s.discovery_adoption[gate]=1.0
	for item:String in ["Polymer-Grade Ethene","Oxygen","Freshwater","Laboratory Glassware"]:s.resource_stockpiles[item]=100.0
func learn(gate:String)->void:
	if gate not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(gate)
	WorldSimulation.state.discovery_adoption[gate]=1.0
func supply(bill:Dictionary,scale:float=1.0)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in bill:stocks[item]=float(stocks.get(item,0))+float(bill[item])*scale
## Pays for `id` from a stock of its bill plus `spare`, and checks that exactly the bill was paid.
func install(id:String,spare:float=100.0)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	supply(spec.cost)
	for item:String in spec.cost:WorldSimulation.state.resource_stockpiles[item]=float(WorldSimulation.state.resource_stockpiles[item])+spare
	var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate()
	assert_bool(Ops.install(id).get("ok",false)).is_true()
	for item:String in spec.cost:assert_float(float(WorldSimulation.state.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(spec.cost[item]),.000001)
func provision_plants()->void:
	for id:String in ["polymer_pressure_reactor","polymer_cooling_circuit","steam_generator"]:
		install(id)
		for item:String in Ops.PLANTS[id].inputs:WorldSimulation.state.resource_stockpiles[item]=1000.0
## A raw material (not goods, water or fuel) in the cooling circuit's fitting maintenance.
func fitting_raw()->String:
	for item:String in Bills.flatten({"Pressure Pipe Fittings":1.0}):
		if item not in ["Civilian Goods","Freshwater","Coal"] and Ops.PLANTS.polymer_cooling_circuit.inputs.has(item):return item
	return ""
func test_paid_commissioning_and_daily_cooling_supply()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();provision_plants()
		assert_bool(Ops.PLANTS.polymer_pressure_reactor.cost.has("Polymer Pressure Reactors")).is_false()
		assert_float(Ops.service("polymer_reactor_work")).is_equal(0.0)
		for day:int in range(1,45):
			WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.polymer_pressure_reactor.installed)).is_equal(1)
		assert_float(Ops.service("polymer_reactor_work")).is_greater(0.0)
		assert_float(Ops.service("polymer_heat_removal")).is_greater(0.0)
		assert_float(float(Ops.data().inputs.get("Freshwater",0))).is_greater_equal(4.0)
		assert_float(float(Ops.data().workers)).is_less_equal(20.0))
func test_actual_daily_owner_stops_cooling_when_maintenance_is_missing()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();provision_plants()
		for id:String in Ops.data().plants:
			Ops.data().plants[id].installed=1;Ops.data().plants[id].building=0
		var fitting:=fitting_raw();assert_str(fitting).is_not_empty()
		WorldSimulation.state.resource_stockpiles[fitting]=0.0
		preload("res://scripts/civilization_day.gd").advance(1,{"settlement_origin":Vector3.ZERO})
		assert_float(Ops.service("polymer_heat_removal")).is_equal(0.0)
		assert_float(float(Ops.data().plants.polymer_cooling_circuit.running_units)).is_equal(0.0)
		assert_float(float(Ops.data().inputs.get(fitting,0))).is_equal(0.0))

func test_missing_definition_has_no_depth_and_remains_a_graph_error()->void:
	WorldSimulation.scoped("polymers",func()->void:
		WorldSimulation.discovery.initialize()
		assert_int(WorldSimulation.discovery.technology_depth("missing_polymer_parent")).is_equal(0)
		assert_bool(WorldSimulation.discovery.catalog_by_id.has("missing_polymer_parent")).is_false()
		var errors:=preload("res://scripts/technology_requirements.gd").validate([{"id":"dependent","requires_all":["missing_polymer_parent"]}])
		assert_bool(errors.is_empty()).is_false())
func test_silver_needs_assaying_and_finite_worked_deposit()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		var s=WorldSimulation.state
		var resource=WorldSimulation.resources
		var deposit:Dictionary=resource._deposit("Silver Ore",Vector3(1,0,1),.8,1000,0)
		deposit.clues=1.0;s.resource_deposits.assign([deposit])
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(deposit.stage)).is_equal("unknown")
		s.known_discoveries.append("ore_assaying");s.discovery_adoption.ore_assaying=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(deposit.stage)).is_equal("recognized")
		assert_float(float(s.resource_stockpiles.get("Silver Ore",0))).is_equal(0.0)
		deposit.stage="surveyed";deposit.route=1.0
		s.population_allocations.Extraction=8;s.population_allocations.Logistics=8;s.population_allocations.Knowledge=5;s.population_allocations.Construction=10
		resource.process_day({"origin":Vector3.ZERO,"settled":false,"tools":1.0})
		assert_float(float(deposit.remaining)).is_less(1000.0)
		assert_float(float(deposit.lifetime_extracted)).is_greater(0.0)
		assert_float(float(deposit.remaining)+float(deposit.lifetime_extracted)).is_equal_approx(1000.0,.00001))
func test_silver_has_geographic_potential_and_old_ore_keys_keep_order()->void:
	var profile:Dictionary=PlanetEnvironment.profile_at(Vector2(100,200))
	assert_bool(profile.resource_potentials.has("Silver Ore")).is_true()
	assert_float(float(profile.resource_potentials["Silver Ore"])).is_between(0.0,1.0)
	assert_array(ResourceSystem.catalog.keys().slice(-7)).is_equal(["Silver Ore","Nickel Ore","Bauxite","Rutile Ore","Ochre Earth","Zinc Ore","Kaolin"])
	assert_bool(bool(ResourceSystem.catalog["Silver Ore"].renewable)).is_false()
func test_appended_silver_does_not_change_existing_generated_deposits()->void:
	WorldSimulation.scoped("polymers",func()->void:
		var resource=WorldSimulation.resources
		var silver:Dictionary=resource.catalog["Silver Ore"].duplicate(true)
		var nickel:Dictionary=resource.catalog["Nickel Ore"].duplicate(true)
		var bauxite:Dictionary=resource.catalog["Bauxite"].duplicate(true)
		var rutile:Dictionary=resource.catalog["Rutile Ore"].duplicate(true)
		var ochre:Dictionary=resource.catalog["Ochre Earth"].duplicate(true)
		var zinc:Dictionary=resource.catalog["Zinc Ore"].duplicate(true)
		var kaolin:Dictionary=resource.catalog["Kaolin"].duplicate(true)
		var potentials:Dictionary={}
		for key:String in resource.catalog:potentials[key]=.8
		var profile:={"resource_potentials":potentials,"signature":"silver-regression"}
		var seen_silver:=false
		for seed_value:int in range(10,18):
			WorldSimulation.state.world_seed=seed_value
			resource.catalog.erase("Silver Ore");resource.catalog.erase("Nickel Ore");resource.catalog.erase("Bauxite");resource.catalog.erase("Rutile Ore");resource.catalog.erase("Ochre Earth");resource.catalog.erase("Zinc Ore");resource.catalog.erase("Kaolin")
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var old: Array=WorldSimulation.state.resource_deposits.duplicate(true)
			resource.catalog["Silver Ore"]=silver;resource.catalog["Nickel Ore"]=nickel;resource.catalog["Bauxite"]=bauxite;resource.catalog["Rutile Ore"]=rutile;resource.catalog["Ochre Earth"]=ochre;resource.catalog["Zinc Ore"]=zinc;resource.catalog["Kaolin"]=kaolin
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var unchanged:Array=[]
			for deposit:Dictionary in WorldSimulation.state.resource_deposits:
				if deposit.resource=="Silver Ore":seen_silver=true
				elif deposit.resource in ["Nickel Ore","Bauxite","Rutile Ore","Ochre Earth","Zinc Ore","Kaolin"]:pass
				else:unchanged.append(deposit)
			assert_array(unchanged).is_equal(old)
		assert_bool(seen_silver).is_true())
func test_silver_deposit_and_stock_survive_full_save_load()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		var deposit:Dictionary=WorldSimulation.resources._deposit("Silver Ore",Vector3(1,0,1),.8,500,0)
		deposit.stage="recognized"
		WorldSimulation.state.resource_deposits.assign([deposit])
		WorldSimulation.state.resource_stockpiles["Nickel Ore"]=5.5
		WorldSimulation.state.resource_stockpiles["Silver Ore"]=3.5
		WorldSimulation.state.resource_stockpiles["Bating Protease"]=2.0)
	var slot:="polymer_silver_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("polymers",func()->void:
		assert_float(float(WorldSimulation.state.resource_stockpiles["Nickel Ore"])).is_equal(5.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Silver Ore"])).is_equal(3.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Bating Protease"])).is_equal(2.0)
		var deposit:Dictionary=WorldSimulation.state.resource_deposits[0]
		assert_str(String(deposit.resource)).is_equal("Silver Ore")
		assert_str(String(deposit.stage)).is_equal("recognized")
		assert_float(float(deposit.remaining)).is_equal(500.0))
func test_actual_hunting_supplies_enzyme_tissue_once_and_stored_meat_does_not()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.ensure_population_total(400);s.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
		s.known_discoveries.append("enzyme_catalysis");s.discovery_adoption.enzyme_catalysis=1.0
		WorldSimulation.food.initialize();s.food_stocks["Fresh meat"]=10000.0
		s.population_allocations.Food=0;s.population_allocations.Logistics=0
		WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(float(s.resource_stockpiles.get("Pancreatic Tissue",0))).is_equal(0.0)
		s.elapsed_days=1;s.population_allocations.Food=20
		var report:Dictionary=WorldSimulation.food.process_day({"traveling":false},1,1)
		var tissue:=float(s.resource_stockpiles.get("Pancreatic Tissue",0))
		assert_float(tissue).is_greater(0.0)
		assert_float(tissue).is_equal_approx(minf(s.population_exact*.001,float(report.food_harvest["Fresh meat"])*.0002),.000001)
		preload("res://scripts/household_clothing.gd").advance(0,400,false,100000)
		assert_float(float(s.resource_stockpiles["Pancreatic Tissue"])).is_equal(tissue)
		s.elapsed_days=2;preload("res://scripts/household_clothing.gd").advance(0,400,false,0)
		assert_float(float(s.resource_stockpiles["Pancreatic Tissue"])).is_equal_approx(tissue*.25,.000001))
func test_enzyme_activity_declines_without_new_hunting_and_repeated_calls_do_not_double_decay()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		WorldSimulation.state.resource_stockpiles["Pancreatic Enzyme Fraction"]=2.0
		WorldSimulation.state.resource_stockpiles["Bating Protease"]=2.0
		preload("res://scripts/household_clothing.gd").advance(0,400,false,0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pancreatic Enzyme Fraction"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Bating Protease"])).is_equal(1.96)
		preload("res://scripts/household_clothing.gd").advance(0,400,false,0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Bating Protease"])).is_equal(1.96))
func test_tissue_cap_and_activity_loss_stay_local_to_secondary_city()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.ensure_population_total(400);s.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
		s.known_discoveries.append("enzyme_catalysis");s.discovery_adoption.enzyme_catalysis=1.0
		s.player_settlements.append({"id":"enzyme_city","name":"Enzyme City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		s.resource_stockpiles["Bating Protease"]=10.0
		WorldSimulation.settlements.with_city_resources("enzyme_city",func()->void:
			s.resource_stockpiles["Bating Protease"]=2.0
			preload("res://scripts/household_clothing.gd").advance(0,100,false,100000)
			assert_float(float(s.resource_stockpiles["Pancreatic Tissue"])).is_equal(.1)
			assert_float(float(s.resource_stockpiles["Bating Protease"])).is_equal(1.96))
		assert_float(float(s.resource_stockpiles.get("Pancreatic Tissue",0))).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Bating Protease"])).is_equal(10.0))
func test_paid_passive_cooling_bath_supplies_heat_removal_without_radical_mastery()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.erase("radical_chain_polymerization");s.discovery_adoption.erase("radical_chain_polymerization")
		install("polymer_passive_cooling")
		for day:int in range(1,14):s.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(.2)
		assert_bool("radical_chain_polymerization" in s.known_discoveries).is_false())
func test_belt_workshop_draws_supplied_belt_maintenance()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		provision_plants()
		var spec:Dictionary=Ops.PLANTS.belt_workshop
		assert_bool(spec.inputs.has("Drive Belts")).is_false()
		install("belt_workshop");supply(spec.inputs,100.0)
		var before:Dictionary=s.resource_stockpiles.duplicate()
		for day:int in range(1,22):s.elapsed_days=day;Ops.advance(day)
		for item:String in spec.inputs:
			if item not in ["Freshwater","Coal"]:assert_float(float(s.resource_stockpiles[item])).is_less(float(before[item]))
		assert_float(float(Ops.data().plants.belt_workshop.running_units)).is_greater(0.0))
func test_natural_nickel_occurrence_can_be_recognized_and_worked()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state;var resource=WorldSimulation.resources
		var found:Dictionary={}
		for x:int in range(-19000,19001,1000):
			for y:int in range(-9000,9001,1000):
				var profile:Dictionary=PlanetEnvironment.profile_at(Vector2(x,y))
				if float(profile.resource_potentials["Nickel Ore"])<.14:continue
				s.resource_deposits.clear();resource.reset_for_new_world()
				resource.register_local_occurrences([],"Hills",profile)
				for deposit:Dictionary in s.resource_deposits:
					if deposit.resource=="Nickel Ore":found=deposit;break
				if not found.is_empty():break
			if not found.is_empty():break
		assert_bool(found.is_empty()).override_failure_message("Natural terrain must supply reachable nickel; no synthetic potential override").is_false()
		if found.is_empty():return
		s.resource_deposits.assign([found]);found.clues=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("unknown")
		for gate:String in ["ore_assaying","nickel_metal_recovery"]:
			s.known_discoveries.append(gate);s.discovery_adoption[gate]=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("recognized")
		assert_float(float(s.resource_stockpiles.get("Nickel Ore",0))).is_equal(0.0)
		found.stage="surveyed";found.route=1.0
		var initial:float=float(found.remaining)
		s.population_allocations.Extraction=8;s.population_allocations.Logistics=8;s.population_allocations.Knowledge=5;s.population_allocations.Construction=10
		resource.process_day({"origin":Vector3.ZERO,"settled":false,"tools":1.0})
		assert_float(float(found.lifetime_extracted)).is_greater(0.0)
		assert_float(float(found.remaining)+float(found.lifetime_extracted)).is_equal_approx(initial,.00001))
func test_paid_foam_cold_store_supplies_cold_storage_and_stops_without_power()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		provision_plants()
		var spec:Dictionary=Ops.PLANTS.foam_insulated_cold_store
		assert_bool(spec.cost.has("Foam Cold-Store Panels") or spec.inputs.has("Foam Cold-Store Panels")).is_false()
		install("foam_insulated_cold_store");supply(spec.inputs,100.0)
		var before:Dictionary=s.resource_stockpiles.duplicate()
		assert_float(Ops.service("cold_storage")).is_equal(0.0)
		for day:int in range(1,36):s.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("cold_storage")).is_equal(200.0)
		for item:String in spec.inputs:
			if item not in ["Freshwater","Coal"]:assert_float(float(s.resource_stockpiles[item])).is_less(float(before[item]))
		s.resource_stockpiles["Coal"]=0.0;s.elapsed_days=36;Ops.advance(36)
		assert_float(Ops.service("cold_storage")).is_equal(0.0))
func test_exposure_save_validation_rejects_impossible_days()->void:
	var helper=preload("res://scripts/exposure_production.gd")
	var spec:=I.product("exposed_panel_sealant")
	assert_str(helper.validate({"exposure_started_day":0,"exposure_last_day":1,"exposure_day_work":1,"progress_days":20},spec)).is_not_empty()
	assert_str(helper.validate({"exposure_started_day":0},spec)).is_not_empty()

func test_natural_bauxite_occurrence_can_be_recognized_and_worked()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state;var resource=WorldSimulation.resources
		var found:Dictionary={}
		for x:int in range(-19000,19001,1000):
			for y:int in range(-9000,9001,1000):
				var profile:Dictionary=PlanetEnvironment.profile_at(Vector2(x,y))
				if float(profile.resource_potentials["Bauxite"])<.14:continue
				s.resource_deposits.clear();resource.reset_for_new_world()
				resource.register_local_occurrences([],"Hills",profile)
				for deposit:Dictionary in s.resource_deposits:
					if deposit.resource=="Bauxite":found=deposit;break
				if not found.is_empty():break
			if not found.is_empty():break
		assert_bool(found.is_empty()).override_failure_message("Natural terrain must supply reachable bauxite; no synthetic potential override").is_false()
		if found.is_empty():return
		s.resource_deposits.assign([found]);found.clues=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("unknown")
		for gate:String in ["ore_assaying","alumina_refining"]:
			s.known_discoveries.append(gate);s.discovery_adoption[gate]=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("recognized")
		assert_float(float(s.resource_stockpiles.get("Bauxite",0))).is_equal(0.0)
		found.stage="surveyed";found.route=1.0
		var initial:float=float(found.remaining)
		s.population_allocations.Extraction=8;s.population_allocations.Logistics=8;s.population_allocations.Knowledge=5;s.population_allocations.Construction=10
		resource.process_day({"origin":Vector3.ZERO,"settled":false,"tools":1.0})
		assert_float(float(found.lifetime_extracted)).is_greater(0.0)
		assert_float(float(found.remaining)+float(found.lifetime_extracted)).is_equal_approx(initial,.00001))
func test_natural_rutile_occurrence_can_be_recognized_and_worked()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state;var resource=WorldSimulation.resources
		var found:Dictionary={}
		for x:int in range(-19000,19001,1000):
			for y:int in range(-9000,9001,1000):
				var profile:Dictionary=PlanetEnvironment.profile_at(Vector2(x,y))
				if float(profile.resource_potentials["Rutile Ore"])<.14:continue
				s.resource_deposits.clear();resource.reset_for_new_world()
				resource.register_local_occurrences([],"Hills",profile)
				for deposit:Dictionary in s.resource_deposits:
					if deposit.resource=="Rutile Ore":found=deposit;break
				if not found.is_empty():break
			if not found.is_empty():break
		assert_bool(found.is_empty()).override_failure_message("Natural terrain must supply reachable rutile; no synthetic potential override").is_false()
		if found.is_empty():return
		s.resource_deposits.assign([found]);found.clues=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("unknown")
		for gate:String in ["ore_assaying","industrial_catalyst_design"]:
			s.known_discoveries.append(gate);s.discovery_adoption[gate]=1.0
		resource.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(found.stage)).is_equal("recognized")
		assert_float(float(s.resource_stockpiles.get("Rutile Ore",0))).is_equal(0.0)
		found.stage="surveyed";found.route=1.0
		var initial:float=float(found.remaining)
		s.population_allocations.Extraction=8;s.population_allocations.Logistics=8;s.population_allocations.Knowledge=5;s.population_allocations.Construction=10
		resource.process_day({"origin":Vector3.ZERO,"settled":false,"tools":1.0})
		assert_float(float(found.lifetime_extracted)).is_greater(0.0)
		assert_float(float(found.remaining)+float(found.lifetime_extracted)).is_equal_approx(initial,.00001))
func test_operating_polymer_plants_survive_full_save_with_services_and_maintenance()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var expected:Dictionary={}
	WorldSimulation.scoped("polymers",func()->void:
		prepare();provision_plants()
		for day:int in range(1,46):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("polymer_heat_removal")).is_greater(0.0)
		assert_float(float(Ops.data().inputs.get(fitting_raw(),0))).is_greater(0.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
		expected.merge(Ops.data().duplicate(true)))
	var slot:="polymer_operating_plants_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("polymers",func()->void:
		assert_bool(Ops.data()==expected).is_true()
		var fitting:=fitting_raw()
		var before:=float(WorldSimulation.state.resource_stockpiles[fitting])
		Ops.advance(45)
		assert_float(float(WorldSimulation.state.resource_stockpiles[fitting])).is_equal(before)
		WorldSimulation.state.elapsed_days=46;Ops.advance(46)
		assert_float(float(WorldSimulation.state.resource_stockpiles[fitting])).is_less(before))

func test_polymer_service_save_limits_reject_unknown_or_excess_capacity()->void:
	var ledger:=Ops.empty_state()
	ledger.services={"polymer_reactor_work":1000.0,"polymer_heat_removal":2200.0,"polymer_stirred_work":1000.0,"cold_storage":400000.0}
	ledger.inputs={"Brazed Steel Fittings":1.0,"Pressure Pipe Fittings":1.0,"Foam Cold-Store Panels":1.0}
	assert_bool(Ops.valid(ledger)).is_true()
	for key:String in ledger.services:
		var bad:=ledger.duplicate(true);bad.services[key]+=1.0
		assert_bool(Ops.valid(bad)).is_false()
	ledger.inputs["Invented Catalyst"]=1.0
	assert_bool(Ops.valid(ledger)).is_false()

func test_paid_nmr_bench_commissions_unqualified_time_and_stops_without_maintenance()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		var spec:Dictionary=Ops.PLANTS.nmr_analytical_bench
		assert_bool(spec.cost.has("Unqualified NMR Benches")).is_false()
		install("nmr_analytical_bench",0.0);supply(spec.inputs,1000.0)
		assert_float(Ops.service("nmr_unqualified_time")).is_equal(0.0)
		provision_plants()
		for day:int in range(1,65):s.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.nmr_analytical_bench.installed)).is_equal(1)
		assert_float(Ops.service("nmr_unqualified_time")).is_greater(0.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
		assert_bool(Ops.data().get("polymer_samples",{}).get("records",{}).is_empty()).is_true()
		assert_float(float(s.resource_stockpiles.get("Sequence-Qualified Copolymer",0))).is_equal(0.0)
		# Cable maintenance (now raw materials and goods) runs out.
		for item:String in Bills.flatten({"Insulated Cable":1.0}):
			if item not in ["Freshwater","Coal"] and spec.inputs.has(item):s.resource_stockpiles[item]=0.0
		s.elapsed_days=65;Ops.advance(65)
		assert_float(Ops.service("nmr_unqualified_time")).is_equal(0.0))
func test_nmr_keeps_all_authored_parents_and_does_not_reuse_mri()->void:
	var entries=preload("res://scripts/polymer_knowledge.gd").entries()
	var found:=false
	for entry:Dictionary in entries:
		if entry.id!="nuclear_magnetic_resonance_spectroscopy":continue
		found=true
		assert_bool(entry.requires_all==["atomic_physics","spectroscopy","resonant_tuned_circuits","precision_thermometry"]).is_true()
		assert_bool(entry.requires_any.is_empty()).is_true()
		assert_bool(entry.effects.is_empty()).is_true()
	assert_bool(found).is_true()
