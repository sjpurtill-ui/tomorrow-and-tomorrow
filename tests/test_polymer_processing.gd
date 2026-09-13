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
	assert_str(String(ResourceSystem.catalog.keys().back())).is_equal("Silver Ore")
	assert_bool(bool(ResourceSystem.catalog["Silver Ore"].renewable)).is_false()
func test_appended_silver_does_not_change_existing_generated_deposits()->void:
	WorldSimulation.scoped("polymers",func()->void:
		var resource=WorldSimulation.resources
		var silver:Dictionary=resource.catalog["Silver Ore"].duplicate(true)
		var potentials:Dictionary={}
		for key:String in resource.catalog:potentials[key]=.8
		var profile:={"resource_potentials":potentials,"signature":"silver-regression"}
		var seen_silver:=false
		for seed_value:int in range(10,18):
			WorldSimulation.state.world_seed=seed_value
			resource.catalog.erase("Silver Ore")
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var old: Array=WorldSimulation.state.resource_deposits.duplicate(true)
			resource.catalog["Silver Ore"]=silver
			WorldSimulation.state.resource_deposits.clear();resource.reset_for_new_world()
			resource.register_local_occurrences([],"Hills",profile)
			var unchanged:Array=[]
			for deposit:Dictionary in WorldSimulation.state.resource_deposits:
				if deposit.resource=="Silver Ore":seen_silver=true
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
		WorldSimulation.state.resource_stockpiles["Silver Ore"]=3.5)
	var slot:="polymer_silver_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("polymers",func()->void:
		assert_float(float(WorldSimulation.state.resource_stockpiles["Silver Ore"])).is_equal(3.5)
		var deposit:Dictionary=WorldSimulation.state.resource_deposits[0]
		assert_str(String(deposit.resource)).is_equal("Silver Ore")
		assert_str(String(deposit.stage)).is_equal("recognized")
		assert_float(float(deposit.remaining)).is_equal(500.0))
