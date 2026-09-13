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
