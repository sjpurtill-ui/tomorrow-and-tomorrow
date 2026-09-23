extends GdUnitTestSuite
const K=preload("res://scripts/electronic_components.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("electronics",995)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_nine_distinct_components_have_valid_contracts()->void:
	WorldSimulation.scoped("electronics",func()->void:
		assert_int(K.entries().size()).is_equal(9)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func setup_plant(id:String)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for material:String in spec.cost:WorldSimulation.state.resource_stockpiles[material]=float(spec.cost[material])+10.0
	assert_bool(Ops.install(id).get("error","")=="").is_true()
	for material:String in spec.cost:assert_float(float(WorldSimulation.state.resource_stockpiles[material])).is_equal_approx(10.0,.000001)
func day(value:int)->void:WorldSimulation.state.elapsed_days=value;Ops.advance(value)
func test_controlled_workshop_needs_commissioning_operators_and_actual_power()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
		setup_plant("controlled_workshop")
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(0)
		for n in range(1,10):day(n)
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		setup_plant("solar_array")
		for n in range(10,18):day(n)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(4.5,.000001)
		assert_float(float(Ops.data().workers)).is_equal_approx(1.625,.000001)
		assert_float(Ops.service("electricity")).is_equal_approx(0.0,.000001)
		assert_float(float(P.workforce().powered_factor)).is_greater(1.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()));assert_bool(Ops.valid(saved)).is_true()
		state.technology_operations=saved;state.population_allocations.Crafting=0;day(18)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(1)
		state.population_allocations.Crafting=20;Ops.set_enabled("solar_array",false);day(19)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
	)

func test_all_installation_types_can_save_their_maximum_commissioning_workforce()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
		var maximum:=Ops.PLANTS.size()*2*Ops.LIMIT
		state.ensure_population_total(maximum+6000);state.population_allocations.Crafting=maximum
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		for id:String in Ops.PLANTS:Ops.data().plants[id]={"installed":0,"building":1000,"work":0.0,"enabled":true}
		day(1)
		assert_float(float(Ops.data().workers)).is_equal(float(maximum))
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
		var invalid:Dictionary=Ops.data().duplicate(true);invalid.workers=float(maximum+1)
		assert_bool(Ops.valid(invalid)).is_false()
		invalid=Ops.data().duplicate(true);invalid.services.mechanical_work=21501.0
		assert_bool(Ops.valid(invalid)).is_false()
	)
