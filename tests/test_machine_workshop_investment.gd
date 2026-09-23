extends GdUnitTestSuite
const F=preload("res://scripts/machine_workshop_investment.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const C=preload("res://scripts/civilization_controller.gd")

func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("workshop",115)

func after_test()->void:WorldSimulation.clear()

func learn(id:String)->void:
	var state=WorldSimulation.state
	if id not in state.known_discoveries:state.known_discoveries.append(id)
	state.discovery_adoption[id]=1.0

func setup(plant:String="powered_workshop")->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=12;state.population_allocations.Logistics=12
	state.resource_stockpiles.clear();state.elapsed_days=100
	# Civilian parts are no longer made on lines; a sustained military line
	# (arrows from raw timber, fibre and stone) is the supplied workshop demand.
	learn("bow_craft")
	state.resource_stockpiles.Freshwater=10000.0
	var spec:Dictionary=Ops.PLANTS[plant]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for resource:String in spec.cost:state.resource_stockpiles[resource]=float(spec.cost[resource])*10.0
	for resource:String in spec.inputs:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+float(spec.inputs[resource])*30.0
	# Flattened plant bills may name the same raw materials; keep the line supplied on top.
	for resource:String in ["Timber","Fiber Plants","Stone"]:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+10000.0
	var started:Dictionary=WorldSimulation.military.start_production_line("arrows",100000)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	Ops.data().plants.solar_array={"installed":2,"building":0,"work":0.0,"enabled":true}

func test_controller_pays_commissions_and_improves_real_work_rate()->void:
	WorldSimulation.scoped("workshop",func()->void:
		setup();var state=WorldSimulation.state
		assert_float(F.supplied_work_days()).is_greater(30.0)
		assert_str(F.recommendation().get("plant","")).is_equal("powered_workshop")
		# Former tool sets and motors are paid as raw materials plus Civilian Goods.
		var goods:=float(Ops.PLANTS.powered_workshop.cost["Civilian Goods"])
		var before:=float(state.resource_stockpiles["Civilian Goods"])
		var baseline:=WorldSimulation.military._base_production_rate()
		C.civilian_orders("workshop",{})
		assert_float(float(state.resource_stockpiles["Civilian Goods"])).is_equal_approx(before-goods,.000001)
		assert_int(int(Ops.data().plants.powered_workshop.building)).is_equal(1)
		assert_dict(F.recommendation()).is_empty()
		for day in range(101,109):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(3.0)
		assert_float(WorldSimulation.military._base_production_rate()).is_greater(baseline)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)

func test_all_workshop_families_follow_local_adoption_and_physical_costs()->void:
	for id:String in F.TYPES:
		WorldSimulation.scoped("workshop",func()->void:
			WorldSimulation.military.equipment_queue.clear();Ops.data().plants.clear()
			WorldSimulation.state.known_discoveries.clear();setup(id)
			assert_str(F.recommendation().get("plant","")).is_equal(id)
			WorldSimulation.state.discovery_adoption[Ops.PLANTS[id].gate]=.1
			assert_dict(F.recommendation()).is_empty()
		)

func test_paused_short_finished_and_unsupplied_jobs_do_not_trigger_investment()->void:
	WorldSimulation.scoped("workshop",func()->void:
		setup();var job:Dictionary=WorldSimulation.military.equipment_queue[0];var state=WorldSimulation.state
		job.paused=true;assert_dict(F.recommendation()).is_empty();job.paused=false
		job.target_stock=1;job.progress_days=float(job.work_per_item)-.001
		assert_dict(F.recommendation()).is_empty();job.target_stock=100000;job.progress_days=0.0
		WorldSimulation.military.military_consumables.arrows=100000;assert_dict(F.recommendation()).is_empty();WorldSimulation.military.military_consumables.arrows=0
		state.resource_stockpiles.Stone=0.0;assert_dict(F.recommendation()).is_empty()
	)

func test_operator_cost_and_saturated_assistance_prevent_overbuilding()->void:
	WorldSimulation.scoped("workshop",func()->void:
		setup();var state=WorldSimulation.state
		state.population_allocations.Crafting=2;assert_dict(F.recommendation()).is_empty();state.population_allocations.Crafting=12
		Ops.data().plants.powered_workshop={"installed":2,"building":0,"work":0.0,"enabled":true}
		assert_dict(F.recommendation()).is_empty()
		Ops.data().plants.powered_workshop.installed=0;Ops.data().plants.powered_workshop.enabled=false
		assert_dict(F.recommendation()).is_empty()
	)

func test_power_is_commissioned_first_and_emergency_orders_are_suppressed()->void:
	WorldSimulation.scoped("workshop",func()->void:
		setup();Ops.data().plants.clear();var state=WorldSimulation.state
		assert_dict(F.recommendation()).is_empty()
		learn("photovoltaic_power");learn("cable_insulation")
		var solar:Dictionary=Ops.PLANTS.solar_array.cost
		for resource:String in solar:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+float(solar[resource])
		assert_str(F.recommendation().get("plant","")).is_equal("solar_array")
		C.civilian_orders("workshop",{"hungry":true});C.civilian_orders("workshop",{"at_war":true})
		assert_dict(Ops.data().plants).is_empty()
		C.civilian_orders("workshop",{})
		assert_int(int(Ops.data().plants.solar_array.building)).is_equal(1)
		assert_bool(Ops.data().plants.has("powered_workshop")).is_false()
		state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty()
	)
