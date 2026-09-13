extends GdUnitTestSuite
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const I=preload("res://scripts/civilian_industry.gd")
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
func test_reactor_without_cooling_cannot_debit_feedstock()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		assert_bool(WorldSimulation.military.start_production_line("radical_ldpe_resin",2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_reactor_work":2.0}
		var before:=float(WorldSimulation.state.resource_stockpiles["Polymer-Grade Ethene"])
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.last_work)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Polymer-Grade Ethene"])).is_equal(before)
		assert_float(Ops.service("polymer_reactor_work")).is_equal(2.0))
func test_cooling_bounds_fractional_work_and_is_consumed_once()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		assert_bool(WorldSimulation.military.start_production_line("radical_ldpe_resin",2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_reactor_work":2.0,"polymer_heat_removal":1.0}
		var before:=float(WorldSimulation.state.resource_stockpiles["Polymer-Grade Ethene"])
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.progress_days)).is_equal(3.0)
		assert_float(before-float(WorldSimulation.state.resource_stockpiles["Polymer-Grade Ethene"])).is_equal_approx(.53,.000001)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(0.0)
		assert_float(Ops.service("polymer_reactor_work")).is_equal(1.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("LDPE Resin",0))).is_equal(0.0)
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.progress_days)).is_equal(3.0)
		Ops.data().services.polymer_heat_removal=1.0
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["LDPE Resin"])).is_equal(1.0))
func test_raw_propene_cannot_substitute_for_purified_ethene()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		assert_bool(WorldSimulation.military.start_production_line("radical_ldpe_resin",2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		WorldSimulation.state.resource_stockpiles["Polymer-Grade Ethene"]=0.0
		WorldSimulation.state.resource_stockpiles["Crude Propene"]=1000.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_reactor_work":2.0,"polymer_heat_removal":4.0}
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.last_work)).is_equal(0.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(4.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Crude Propene"])).is_equal(1000.0))
func provision_plants()->void:
	for id:String in ["polymer_pressure_reactor","polymer_cooling_circuit","steam_generator"]:
		var spec:Dictionary=Ops.PLANTS[id]
		for gate:String in [spec.gate]+spec.requires:
			if gate not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(gate)
			WorldSimulation.state.discovery_adoption[gate]=1.0
		for item:String in spec.cost:WorldSimulation.state.resource_stockpiles[item]=100.0
		for item:String in spec.inputs:WorldSimulation.state.resource_stockpiles[item]=1000.0
		assert_bool(Ops.install(id).get("ok",false)).is_true()
func test_paid_commissioning_and_daily_cooling_supply()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();provision_plants()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Polymer Pressure Reactors"])).is_equal(99.0)
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
		WorldSimulation.state.resource_stockpiles["Pressure Pipe Fittings"]=0.0
		preload("res://scripts/civilization_day.gd").advance(1,{"settlement_origin":Vector3.ZERO})
		assert_float(Ops.service("polymer_heat_removal")).is_equal(0.0)
		assert_float(float(Ops.data().plants.polymer_cooling_circuit.running_units)).is_equal(0.0)
		assert_float(float(Ops.data().inputs.get("Pressure Pipe Fittings",0))).is_equal(0.0))

func test_missing_definition_has_no_depth_and_remains_a_graph_error()->void:
	WorldSimulation.scoped("polymers",func()->void:
		WorldSimulation.discovery.initialize()
		assert_int(WorldSimulation.discovery.technology_depth("missing_polymer_parent")).is_equal(0)
		assert_bool(WorldSimulation.discovery.catalog_by_id.has("missing_polymer_parent")).is_false()
		var errors:=preload("res://scripts/technology_requirements.gd").validate([{"id":"dependent","requires_all":["missing_polymer_parent"]}])
		assert_bool(errors.is_empty()).is_false())
func run_batch(item:String,target:int)->Dictionary:
	var spec:=I.product(item)
	if String(spec.gate) not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(spec.gate)
	WorldSimulation.state.discovery_adoption[spec.gate]=1.0
	for resource:String in spec.tooling:WorldSimulation.state.resource_stockpiles[resource]=1000.0
	var started:Dictionary=WorldSimulation.military.start_production_line(item,target)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	if not started.get("ok",false):return {}
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	P.advance(WorldSimulation.military,job,10000)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
	return job
func test_complete_typed_chain_consumes_feed_and_produces_existing_cable()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		# Existing nonpolymer supply is the boundary fixture. Intermediates start empty.
		WorldSimulation.state.resource_stockpiles={}
		for resource:String in ["Bitumen","Timber","Freshwater","Quicklime","Oxygen","Copper Wire","Laboratory Glassware"]:WorldSimulation.state.resource_stockpiles[resource]=10000.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10000.0,"polymer_reactor_work":100.0,"polymer_heat_removal":200.0}
		var items:Array[String]=["refinery_naphtha_cut","steam_cracked_ethene","purified_ethene_feed","radical_ldpe_resin","characterized_ldpe","ldpe_pelletizing","ldpe_film_grade","ldpe_film_extrusion","polyethylene_wrapped_cable"]
		var targets:Array[int]=[128,24,16,12,10,8,6,4,2]
		for n:int in items.size():
			var job:=run_batch(items[n],targets[n])
			assert_int(int(job.get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(WorldSimulation.state.resource_stockpiles["Insulated Cable"])).is_equal(2.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Bitumen"])).is_equal(9360.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["LDPE Film"])).is_equal_approx(3.2,.00001)
		assert_float(Ops.service("polymer_reactor_work")).is_equal(88.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(176.0))
func test_imported_characterized_resin_enables_adopted_forming_without_synthesis_mastery()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		WorldSimulation.state.known_discoveries.erase("radical_chain_polymerization")
		WorldSimulation.state.discovery_adoption.erase("radical_chain_polymerization")
		WorldSimulation.state.resource_stockpiles["Characterized LDPE"]=2.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0}
		var job:=run_batch("ldpe_pelletizing",1)
		assert_int(int(job.get("completed",0))).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Characterized LDPE"])).is_equal_approx(.96,.00001)
		assert_bool("radical_chain_polymerization" in WorldSimulation.state.known_discoveries).is_false()
		assert_bool(P.recipe(WorldSimulation.military,"radical_ldpe_resin").has("error")).is_true())
func test_injection_grade_and_formed_sheet_reach_real_telephone_assembly()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		WorldSimulation.state.resource_stockpiles["Molding-Grade LDPE"]=2.0
		WorldSimulation.state.resource_stockpiles["LDPE Forming Sheet"]=2.0
		WorldSimulation.state.resource_stockpiles["Compressed Air"]=2.0
		assert_int(int(run_batch("injected_telephone_covers",1).get("completed",0))).is_equal(1)
		assert_int(int(run_batch("formed_telephone_covers",2).get("completed",0))).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Molding-Grade LDPE"])).is_equal_approx(1.4,.00001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["LDPE Forming Sheet"])).is_equal_approx(1.2,.00001)
		for resource:String in ["Carbon Microphones","Telephone Earpieces","Insulated Cable","Timber"]:WorldSimulation.state.resource_stockpiles[resource]=10.0
		assert_int(int(run_batch("polymer_cased_telephones",2).get("completed",0))).is_equal(2)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Polyethylene Telephone Covers"])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Telephone Sets"])).is_equal(2.0))
func test_condensation_supply_chain_reaches_an_indoor_switchboard()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();WorldSimulation.state.resource_stockpiles={}
		# Boundary inputs are existing supply and a separately identified silver ore.
		for resource:String in ["Timber","Freshwater","Quicklime","Silver Ore","Lead Sheets","Charcoal","Limestone","Clay","Oxygen","Ammonia","Sulfuric Acid","Telephone Sets","Insulated Cable","Refined Copper"]:WorldSimulation.state.resource_stockpiles[resource]=1000.0
		Ops.data().last_day=0;Ops.data().services={"electricity":1000.0,"polymer_heat_removal":100.0}
		var items:Array[String]=["wood_chemical_condensate","wood_methanol_fraction","silver_bearing_bullion","cupelled_silver","silver_oxidation_catalyst","formaldehyde_solution","captured_calcination_carbon_dioxide","separated_urea","urea_formaldehyde_resin","qualified_uf_wood_adhesive","graded_interior_wood","laminated_interior_panels","panel_switchboards"]
		var targets:Array[int]=[8,4,4,2,1,3,2,2,2,1,6,2,2]
		for n:int in items.size():
			var job:=run_batch(items[n],targets[n])
			assert_int(int(job.get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Telephone Switchboards",0))).is_equal(2.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Interior Bonded Wood Panels",0))).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Silver Ore"])).is_equal(984.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(98.0))
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
	assert_str(String(ResourceSystem.catalog.keys().back())).is_equal("Rutile Ore")
	assert_bool(bool(ResourceSystem.catalog["Silver Ore"].renewable)).is_false()
func test_appended_silver_does_not_change_existing_generated_deposits()->void:
	WorldSimulation.scoped("polymers",func()->void:
		var resource=WorldSimulation.resources
		var silver:Dictionary=resource.catalog["Silver Ore"].duplicate(true)
		var nickel:Dictionary=resource.catalog["Nickel Ore"].duplicate(true)
		var bauxite:Dictionary=resource.catalog["Bauxite"].duplicate(true)
		var rutile:Dictionary=resource.catalog["Rutile Ore"].duplicate(true)
		var potentials:Dictionary={}
		for key:String in resource.catalog:potentials[key]=.8
		var profile:={"resource_potentials":potentials,"signature":"silver-regression"}
		var seen_silver:=false
		for seed_value:int in range(10,18):
			WorldSimulation.state.world_seed=seed_value
			resource.catalog.erase("Silver Ore");resource.catalog.erase("Nickel Ore");resource.catalog.erase("Bauxite");resource.catalog.erase("Rutile Ore")
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var old: Array=WorldSimulation.state.resource_deposits.duplicate(true)
			resource.catalog["Silver Ore"]=silver;resource.catalog["Nickel Ore"]=nickel;resource.catalog["Bauxite"]=bauxite;resource.catalog["Rutile Ore"]=rutile
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var unchanged:Array=[]
			for deposit:Dictionary in WorldSimulation.state.resource_deposits:
				if deposit.resource=="Silver Ore":seen_silver=true
				elif deposit.resource in ["Nickel Ore","Bauxite","Rutile Ore"]:pass
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
func test_specific_enzyme_fraction_and_bated_hides_reach_flexible_leather()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare()
		for resource:String in ["Salt","Freshwater","Plant Tannin Extract","Rendered Animal Fat"]:WorldSimulation.state.resource_stockpiles[resource]=100.0
		WorldSimulation.state.resource_stockpiles["Pancreatic Tissue"]=.1
		WorldSimulation.state.resource_stockpiles["Prepared Tanning Hides"]=3.0
		WorldSimulation.state.resource_stockpiles["Ammonia"]=1.0
		var items:Array[String]=["pancreatic_enzyme_fraction","qualified_bating_protease","enzyme_bated_hides","bated_vegetable_leather","finished_flexible_leather"]
		var targets:Array[int]=[4,2,2,2,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pancreatic Tissue"])).is_equal_approx(.02,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Flexible Leather"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Bated Hides"])).is_equal(0.0))
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
func test_ring_opening_uses_typed_oxide_and_paid_cooling_without_radical_mastery()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.erase("radical_chain_polymerization");s.discovery_adoption.erase("radical_chain_polymerization")
		s.known_discoveries.append("calorimetry");s.discovery_adoption.calorimetry=1.0
		for item:String in Ops.PLANTS.polymer_passive_cooling.cost:s.resource_stockpiles[item]=100.0
		assert_bool(Ops.install("polymer_passive_cooling").get("ok",false)).is_true()
		for day:int in range(1,14):s.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(.2)
		Ops.data().services.polymer_stirred_work=1.0;Ops.data().services.electricity=10.0
		for item:String in ["Ethylene Oxide","Ethylene Glycol","Caustic Soda","Sulfuric Acid"]:s.resource_stockpiles[item]=10.0
		var job:=run_batch("ring_opened_peg_diol",1)
		assert_float(float(job.progress_days)).is_equal(1.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(0.0)
		assert_float(Ops.service("polymer_stirred_work")).is_equal(.8)
		assert_float(float(s.resource_stockpiles["Ethylene Oxide"])).is_equal_approx(9.77,.000001)
		assert_float(float(s.resource_stockpiles.get("PEG Diol",0))).is_equal(0.0)
		assert_bool("radical_chain_polymerization" in s.known_discoveries).is_false())
func test_isocyanate_chain_and_addition_cured_web_supply_operating_belt_maintenance()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state;s.resource_stockpiles={}
		for resource:String in ["Coal","Timber","Freshwater","Nickel Ore","Sulfuric Acid","Caustic Soda","Charcoal","Hydrogen","Alumina Catalyst Supports","Nitrates","Oxygen","Carbon Dioxide","Chlorine","PEG Diol","Ethylene Glycol","Woven Cloth","Spun Yarn"]:s.resource_stockpiles[resource]=1000.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10000.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		var items:Array[String]=["coal_light_oil","separated_toluene","balanced_nickel_feed","prepared_nickel_oxide","reduced_nickel","qualified_nickel_hydrogenation_catalyst","controlled_aromatic_nitration","aromatic_amine_feed","biomass_producer_gas","assayed_producer_gas","separated_carbon_monoxide","qualified_isocyanate_feed","addition_cured_belt_web","polyurethane_drive_belts"]
		var targets:Array[int]=[8,4,7,2,1,1,3,2,6,5,2,1,1,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles.get("Drive Belts",0))).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Nickel Ore"])).is_equal_approx(992.65,.00001)
		assert_float(float(s.resource_stockpiles["PU-Coated Belt Web"])).is_equal(0.0)
		provision_plants()
		for gate:String in ["belt_power_transmission","electric_motors"]:
			if gate not in s.known_discoveries:s.known_discoveries.append(gate)
			s.discovery_adoption[gate]=1.0
		for item:String in Ops.PLANTS.belt_workshop.cost:s.resource_stockpiles[item]=100.0
		assert_bool(Ops.install("belt_workshop").get("ok",false)).is_true()
		for day:int in range(1,22):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(s.resource_stockpiles["Drive Belts"])).is_less(1.0)
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
func test_blow_molding_needs_air_and_completed_bottles_equip_real_assay()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		s.resource_stockpiles["LDPE Pellets"]=5.0
		assert_int(int(run_batch("ldpe_blow_grade",1).completed)).is_equal(1)
		assert_int(int(run_batch("ldpe_molding_grade",1).completed)).is_equal(1)
		s.known_discoveries.append("polymer_blow_molding");s.discovery_adoption.polymer_blow_molding=1.0
		for resource:String in I.product("blown_wash_bottle_bodies").tooling:s.resource_stockpiles[resource]=1000.0
		var stopped:Dictionary=WorldSimulation.military.start_production_line("blown_wash_bottle_bodies",1)
		assert_bool(stopped.get("ok",false)).is_false()
		assert_str(String(stopped.get("error",""))).contains("Compressed Air")
		assert_float(float(s.resource_stockpiles["Blow-Grade LDPE"])).is_equal(1.0)
		s.resource_stockpiles["Compressed Air"]=.4
		assert_int(int(run_batch("blown_wash_bottle_bodies",1).completed)).is_equal(1)
		assert_float(float(s.resource_stockpiles["Compressed Air"])).is_equal(0.0)
		assert_int(int(run_batch("injected_wash_bottle_closures",1).completed)).is_equal(1)
		assert_int(int(run_batch("assembled_water_wash_bottles",1).completed)).is_equal(1)
		assert_float(float(s.resource_stockpiles["LDPE Wash Bottle Bodies"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["LDPE Wash Bottle Closures"])).is_equal(0.0)
		s.known_discoveries.append("enzyme_catalysis");s.discovery_adoption.enzyme_catalysis=1.0
		s.resource_stockpiles["Pancreatic Enzyme Fraction"]=1.1;s.resource_stockpiles["Prepared Tanning Hides"]=.02
		s.resource_stockpiles["Salt"]=.05;s.resource_stockpiles["Clay"]=2;s.resource_stockpiles["Laboratory Glassware"]=1
		# Do not use run_batch here: its tooling fixture would invent wash bottles.
		assert_bool(WorldSimulation.military.start_production_line("wash_bottle_bating_assay",1).get("ok",false)).is_true()
		assert_float(float(s.resource_stockpiles["Water Wash Bottles"])).is_equal(0.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(1)
		assert_float(float(s.resource_stockpiles["Bating Protease"])).is_equal(1.0))
func test_solution_binder_recovery_has_finite_water_yield_and_operating_catalyst_output()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		for resource:String in ["PEG Diol","Alumina Catalyst Supports","Refined Silver","Polymer-Grade Ethene","Oxygen","Timber"]:s.resource_stockpiles[resource]=100.0
		var items:Array[String]=["qualified_peg_binder","aqueous_peg_binder","dried_peg_alumina_granules","formed_alumina_supports","formed_ethene_catalyst","separated_ethylene_oxide"]
		var targets:Array[int]=[1,2,2,2,1,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Ethylene Oxide"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Ethene Oxidation Catalyst"])).is_equal_approx(.98,.000001)
		assert_float(float(s.resource_stockpiles["PEG Dryer Condensate"])).is_equal(1.6)
		var water_before:float=float(s.resource_stockpiles["Freshwater"])
		assert_int(int(run_batch("recovered_peg_process_water",1).get("completed",0))).is_equal(1)
		assert_float(float(s.resource_stockpiles["PEG Dryer Condensate"])).is_equal_approx(.35,.000001)
		assert_float(float(s.resource_stockpiles["Recovered PEG Process Water"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Freshwater"])).is_equal(water_before)
		assert_int(int(run_batch("recovered_water_peg_binder",1).get("completed",0))).is_equal(1)
		assert_float(float(s.resource_stockpiles["Recovered PEG Process Water"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Freshwater"])).is_equal(water_before)
		assert_float(float(s.resource_stockpiles["Binder-Grade PEG"])).is_equal_approx(.7,.000001))
func test_recovery_does_not_accept_fresh_water_as_process_condensate()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.append("polymer_solvent_recovery");s.discovery_adoption.polymer_solvent_recovery=1.0
		for resource:String in I.product("recovered_peg_process_water").tooling:s.resource_stockpiles[resource]=100.0
		s.resource_stockpiles["Timber"]=100.0
		var started:Dictionary=WorldSimulation.military.start_production_line("recovered_peg_process_water",1)
		assert_bool(started.get("ok",false)).is_false()
		assert_str(String(started.get("error",""))).contains("PEG Dryer Condensate"))
func test_controlled_peg_requires_measured_starter_and_reaches_binder()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		for resource:String in ["Ethylene Glycol","Ethylene Oxide","Caustic Soda","Sulfuric Acid","PEG Diol","Alumina Catalyst Supports"]:s.resource_stockpiles[resource]=100.0
		s.known_discoveries.append("ring_opening_polymerization");s.discovery_adoption.ring_opening_polymerization=1.0
		for resource:String in I.product("controlled_chain_peg").tooling:s.resource_stockpiles[resource]=1000.0
		var denied:Dictionary=WorldSimulation.military.start_production_line("controlled_chain_peg",1)
		assert_bool(denied.get("ok",false)).is_false()
		assert_str(String(denied.get("error",""))).contains("Metered PEG Starter")
		var items:Array[String]=["metered_peg_starter","controlled_chain_peg","characterized_controlled_peg","size_qualified_peg_binder","aqueous_peg_binder"]
		var targets:Array[int]=[1,3,2,1,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Metered PEG Starter"])).is_equal_approx(.88,.000001)
		assert_float(float(s.resource_stockpiles["Controlled-Chain PEG"])).is_equal_approx(.92,.000001)
		assert_float(float(s.resource_stockpiles["Size-Qualified PEG"])).is_equal_approx(.98,.000001)
		assert_float(float(s.resource_stockpiles["Aqueous PEG Binder"])).is_equal(1.0)
		assert_float(Ops.service("polymer_stirred_work")).is_equal_approx(6.4,.000001)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(7.0))
func test_formulated_foam_panels_supply_paid_cold_storage_and_stop_without_power()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		for resource:String in ["Limestone","LDPE Pellets","Carbon Dioxide","Steel Sheets","Bitumen"]:s.resource_stockpiles[resource]=100.0
		var items:Array[String]=["polymer_carbonate_filler","formulated_foam_ldpe","expanded_ldpe_foam","qualified_ldpe_foam","foam_cold_store_panels"]
		var targets:Array[int]=[1,6,5,4,3]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Carbon Dioxide"])).is_equal_approx(99.25,.000001)
		assert_float(float(s.resource_stockpiles["Unqualified LDPE Foam"])).is_equal_approx(.68,.000001)
		provision_plants()
		for gate:String in ["mechanical_refrigeration","electric_motors"]:
			if gate not in s.known_discoveries:s.known_discoveries.append(gate)
			s.discovery_adoption[gate]=1.0
		for item:String in ["Electric Motors","Pressure Vessels","Glass"]:s.resource_stockpiles[item]=100.0
		assert_bool(Ops.install("foam_insulated_cold_store").get("ok",false)).is_true()
		assert_float(float(s.resource_stockpiles["Foam Cold-Store Panels"])).is_equal(1.0)
		assert_float(Ops.service("cold_storage")).is_equal(0.0)
		for day:int in range(1,36):s.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("cold_storage")).is_equal(200.0)
		assert_float(float(s.resource_stockpiles["Foam Cold-Store Panels"])).is_less(1.0)
		s.resource_stockpiles["Coal"]=0.0;s.elapsed_days=36;Ops.advance(36)
		assert_float(Ops.service("cold_storage")).is_equal(0.0))
func test_selective_glycolysis_uses_completed_virgin_offcuts_and_restricted_blend()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.append("belt_power_transmission");s.discovery_adoption.belt_power_transmission=1.0
		for resource:String in ["Steel","Timber","Spun Yarn"]:s.resource_stockpiles[resource]=100.0
		s.resource_stockpiles["PU-Coated Belt Web"]=20.0
		assert_bool(WorldSimulation.military.start_production_line("polyurethane_drive_belts",20).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,1)
		assert_float(float(s.resource_stockpiles.get("Clean PU Belt Offcuts",0))).is_equal(0.0)
		P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(20)
		assert_float(float(s.resource_stockpiles["Clean PU Belt Offcuts"])).is_equal_approx(1.6,.000001)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		for resource:String in ["Ethylene Glycol","Caustic Soda","PEG Diol","Aromatic Diisocyanate Feed","Woven Cloth"]:s.resource_stockpiles[resource]=100.0
		var items:Array[String]=["pu_offcut_glycolysis","qualified_recovered_pu_blend","recovered_blend_belt_web","recovered_blend_drive_belts"]
		var targets:Array[int]=[1,1,1,21]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(1)
		assert_float(float(s.resource_stockpiles["Drive Belts"])).is_equal(21.0)
		assert_float(float(s.resource_stockpiles["Clean PU Belt Offcuts"])).is_equal_approx(.2,.000001)
		assert_float(float(s.resource_stockpiles["Recovered PU Glycolysate"])).is_equal_approx(.9,.000001)
		assert_float(float(s.resource_stockpiles["PEG Diol"])).is_equal_approx(99.06,.000001)
		assert_float(float(s.resource_stockpiles["Recovered-Blend PU Belt Web"])).is_equal(0.0))
func test_cationic_c4_route_supplies_panel_sealant_with_finite_catalyst_and_cooling()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":1000.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		for resource:String in ["Refinery Naphtha","Quicklime","Alumina Catalyst Supports","Charcoal","Chlorine","Hydrogen Chloride","Caustic Soda","Bitumen","Polymer Carbonate Filler","Steel Sheets","Insulation-Grade LDPE Foam"]:s.resource_stockpiles[resource]=100.0
		s.resource_stockpiles["Freshwater"]=1000.0
		var items:Array[String]=["steam_cracked_ethene","qualified_cationic_c4_feed","anhydrous_aluminum_chloride","cationic_polybutene","polybutene_panel_sealant","polybutene_sealed_cold_panels"]
		var targets:Array[int]=[12,3,1,1,1,2]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Mixed Cracker C4"])).is_equal_approx(0.0,.000001)
		assert_float(float(s.resource_stockpiles["Qualified Cationic C4 Feed"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Anhydrous Aluminum Chloride"])).is_equal_approx(.98,.000001)
		assert_float(float(s.resource_stockpiles["Polybutene Panel Sealant"])).is_equal_approx(.94,.000001)
		assert_float(float(s.resource_stockpiles["Foam Cold-Store Panels"])).is_equal(2.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(8.0))
func start_exposure()->Dictionary:
	prepare();var s=WorldSimulation.state
	s.known_discoveries.append("polymer_weathering_trials");s.discovery_adoption.polymer_weathering_trials=1.0
	var spec:=I.product("exposed_panel_sealant")
	for resource:String in spec.tooling:s.resource_stockpiles[resource]=100.0
	for resource:String in spec.materials:s.resource_stockpiles[resource]=spec.materials[resource]
	Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
	assert_bool(WorldSimulation.military.start_production_line("exposed_panel_sealant",1).get("ok",false)).is_true()
	var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,10000)
	return job
func test_exposure_reserves_batch_and_cannot_accelerate_or_skip_unpowered_days()->void:
	WorldSimulation.scoped("polymers",func()->void:
		var job:=start_exposure();var s=WorldSimulation.state
		assert_float(float(s.resource_stockpiles["Polybutene Panel Sealant"])).is_equal(0.0)
		P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(0.0)
		s.elapsed_days=1;Ops.data().last_day=1;P.advance(WorldSimulation.military,job,.5);P.advance(WorldSimulation.military,job,10000);P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(1.0)
		s.elapsed_days=2;Ops.data().last_day=2;Ops.data().services.electricity=0.0;P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(1.0)
		s.elapsed_days=3;Ops.data().last_day=3;Ops.data().services.electricity=100.0;job.paused=true;P.advance(WorldSimulation.military,job,10000)
		job.paused=false;s.elapsed_days=20;Ops.data().last_day=20;P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(2.0)
		for day:int in range(21,49):s.elapsed_days=day;Ops.data().last_day=day;P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(1)
		assert_float(float(s.resource_stockpiles["Exposure-Tested Panel Sealant"])).is_equal(1.0)
		assert_bool("ionic_chain_polymerization" in s.known_discoveries).is_false()
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		s.resource_stockpiles["Insulation-Grade LDPE Foam"]=2;s.resource_stockpiles["Steel Sheets"]=1
		assert_int(int(run_batch("exposure_tested_cold_panels",1).get("completed",0))).is_equal(1))
func test_exposure_survives_full_save_without_repaying_or_replaying_days()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("polymers",func()->void:
		var job:=start_exposure()
		for day:int in range(1,6):WorldSimulation.state.elapsed_days=day;Ops.data().last_day=day;P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(5.0))
	var slot:="polymer_exposure_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("polymers",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		Ops.data().last_day=5;Ops.data().services={"electricity":100.0}
		P.advance(WorldSimulation.military,job,10000)
		assert_float(float(job.progress_days)).is_equal(5.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Polybutene Panel Sealant"])).is_equal(0.0)
		for day:int in range(6,31):WorldSimulation.state.elapsed_days=day;Ops.data().last_day=day;P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(1))
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
func test_bauxite_refining_supplies_operating_oxidation_catalyst()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		for resource:String in ["Caustic Soda","Timber","Refined Silver","Polymer-Grade Ethene","Oxygen"]:s.resource_stockpiles[resource]=100.0
		s.resource_stockpiles["Bauxite"]=5.0
		var items:Array[String]=["bauxite_alumina_refining","refined_alumina_supports","ethene_oxidation_catalyst","separated_ethylene_oxide"]
		var targets:Array[int]=[2,1,1,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Bauxite"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Refined Alumina"])).is_equal_approx(.92,.000001)
		assert_float(float(s.resource_stockpiles["Ethene Oxidation Catalyst"])).is_equal_approx(.98,.000001)
		assert_float(float(s.resource_stockpiles["Ethylene Oxide"])).is_equal(1.0))
func test_chloride_aluminum_requires_paid_mixed_bath_and_power_before_metal_or_chlorine()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		for resource:String in ["Timber","Freshwater","Hydrogen Chloride","Refined Alumina","Charcoal","Chlorine"]:s.resource_stockpiles[resource]=1000.0
		var items:Array[String]=["wood_ash_potassium_extract","purified_potassium_chloride","electrolysis_grade_aluminum_chloride"]
		var targets:Array[int]=[7,5,6]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		s.known_discoveries.append("aluminum_electrolysis");s.discovery_adoption.aluminum_electrolysis=1.0
		for resource:String in ["Salt","Graphite","Refractory Bricks","Steel"]:s.resource_stockpiles[resource]=100.0
		assert_bool(WorldSimulation.military.start_production_line("chloride_aluminum_electrolysis",1).get("ok",false)).is_true()
		assert_float(float(s.resource_stockpiles["Purified Potassium Chloride"])).is_equal(1.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		var chlorine_before:float=float(s.resource_stockpiles["Chlorine"])
		Ops.data().services.electricity=10.0;P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(0)
		assert_float(float(s.resource_stockpiles.get("Refined Aluminum",0))).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Chlorine"])).is_equal(chlorine_before)
		Ops.data().services.electricity=10.0;P.advance(WorldSimulation.military,job,10000)
		assert_int(int(job.completed)).is_equal(1)
		assert_float(float(s.resource_stockpiles["Chlorine"])).is_equal_approx(chlorine_before+3.4,.000001)
		assert_float(float(s.resource_stockpiles["Purified Potassium Chloride"])).is_equal_approx(.97,.000001)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		s.resource_stockpiles["Insulation-Grade LDPE Foam"]=2;s.resource_stockpiles["Bitumen"]=1;Ops.data().services.electricity=10.0
		assert_int(int(run_batch("aluminum_faced_cold_panels",1).get("completed",0))).is_equal(1)
		assert_float(float(s.resource_stockpiles["Refined Aluminum"])).is_equal_approx(.6,.000001))

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
func test_coordination_and_tacticity_route_produces_usable_wash_bottle_closures()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		Ops.data().last_day=0;Ops.data().services={"electricity":1000.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		for resource:String in ["Polymer-Grade Ethene","Hydrogen Chloride","Anhydrous Aluminum Chloride","Refined Aluminum","Rutile Ore","Charcoal","Chlorine","Crude Propene","Quicklime","Toluene","Methanol","Caustic Soda","LDPE Wash Bottle Bodies"]:s.resource_stockpiles[resource]=100.0
		var items:Array[String]=["catalyst_ethyl_chloride","ethylaluminum_cocatalyst","purified_titanium_chloride","reduced_titanium_catalyst","purified_propene_feed","coordination_polypropylene","spectrally_qualified_polypropylene","polypropylene_molding_grade","injected_pp_wash_closures","pp_closure_wash_bottles"]
		var targets:Array[int]=[2,1,2,1,5,4,3,2,1,1]
		for n:int in items.size():assert_int(int(run_batch(items[n],targets[n]).get("completed",0))).override_failure_message(items[n]).is_equal(targets[n])
		assert_float(float(s.resource_stockpiles["Water Wash Bottles"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["PP Wash Bottle Closures"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Titanium Trichloride Catalyst"])).is_equal_approx(.92,.000001)
		assert_float(float(s.resource_stockpiles["Ethylaluminum Cocatalyst"])).is_equal_approx(.96,.000001)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(2.0))
func test_copolymer_feed_requires_both_monomers_and_remains_unqualified_after_synthesis()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.append("copolymer_sequence_control");s.discovery_adoption.copolymer_sequence_control=1.0
		for resource:String in I.product("metered_propene_ethene_feed").tooling:s.resource_stockpiles[resource]=100.0
		s.resource_stockpiles["Polymer-Grade Propene"]=3.0;s.resource_stockpiles["Polymer-Grade Ethene"]=0.0
		var denied:Dictionary=WorldSimulation.military.start_production_line("metered_propene_ethene_feed",1)
		assert_bool(denied.get("ok",false)).is_false()
		assert_str(String(denied.get("error",""))).contains("Polymer-Grade Ethene")
		s.resource_stockpiles["Polymer-Grade Ethene"]=.12
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		for resource:String in ["Titanium Trichloride Catalyst","Ethylaluminum Cocatalyst","Toluene","Methanol","Caustic Soda"]:s.resource_stockpiles[resource]=100.0
		assert_int(int(run_batch("metered_propene_ethene_feed",2).get("completed",0))).is_equal(2)
		assert_int(int(run_batch("controlled_propene_ethene_copolymer",1).get("completed",0))).is_equal(1)
		assert_float(float(s.resource_stockpiles["Polymer-Grade Ethene"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Raw Propene-Ethene Copolymer"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.get("Molding-Grade Polypropylene",0))).is_equal(0.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(8.0))

func test_exposure_waits_for_full_specimen_before_first_and_subsequent_cycles()->void:
	WorldSimulation.scoped("polymers",func()->void:
		prepare();var s=WorldSimulation.state
		s.known_discoveries.append("polymer_weathering_trials");s.discovery_adoption.polymer_weathering_trials=1.0
		var spec:=I.product("exposed_panel_sealant")
		for resource:String in spec.tooling:s.resource_stockpiles[resource]=100.0
		for resource:String in spec.materials:s.resource_stockpiles[resource]=spec.materials[resource]
		Ops.data().last_day=0;Ops.data().services={"electricity":100.0}
		assert_bool(WorldSimulation.military.start_production_line("exposed_panel_sealant",0).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		for cycle:int in range(2):
			for resource:String in spec.materials:s.resource_stockpiles[resource]=spec.materials[resource]
			s.resource_stockpiles["Polybutene Panel Sealant"]=.5
			assert_str(P.state(WorldSimulation.military,job)).contains("for full specimen")
			assert_bool(P.eligible(WorldSimulation.military,job)).is_false()
			var before:Dictionary=s.resource_stockpiles.duplicate()
			P.advance(WorldSimulation.military,job,10000)
			assert_bool(job.has("exposure_started_day")).is_false()
			assert_bool(s.resource_stockpiles==before).is_true()
			s.resource_stockpiles["Polybutene Panel Sealant"]=spec.materials["Polybutene Panel Sealant"]
			assert_str(P.state(WorldSimulation.military,job)).is_equal("Working")
			P.advance(WorldSimulation.military,job,10000)
			assert_bool(job.has("exposure_started_day")).is_true()
			for day:int in range(30):
				s.elapsed_days+=1;Ops.data().last_day=int(s.elapsed_days)
				P.advance(WorldSimulation.military,job,10000)
			assert_int(int(job.completed)).is_equal(cycle+1))
