extends GdUnitTestSuite
const Intake=preload("res://scripts/military_intake_supply.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("intake",118)
func after_test()->void:WorldSimulation.clear()
func setup()->Node:
	var host=WorldSimulation.military
	WorldSimulation.state.population_exact=500
	WorldSimulation.state.population_total=500
	WorldSimulation.state.population_allocations.Defense=16
	host.home_army=host.simulator.create_formation_force("Home",[])
	host.training_queue.clear();host.field_armies.clear();host.occupation_forces.clear()
	host.military_inventory=host._empty_equipment_inventory()
	return host
func test_replacements_and_pending_training_have_first_claim_on_inventory()->void:
	WorldSimulation.scoped("intake",func()->void:
		var host:=setup()
		host.home_army=host.simulator.create_formation_force("Home",[{"unit":"levy","weapon":"improvised","count":10,"equipment":4}])
		host.military_inventory.improvised=12
		host.training_queue.append({"unit":"levy","weapon":"improvised","count":4,"reserved_equipment":1})
		assert_int(Intake.places(host,"levy","improvised")).is_equal(3)
		host.military_inventory.improvised=5
		assert_int(Intake.places(host,"levy","improvised")).is_equal(0)
	)
func test_watch_waits_for_gear_and_uses_existing_recruits_once()->void:
	WorldSimulation.scoped("intake",func()->void:
		var host:=setup();host.aggregate_recruits=10
		host._ensure_automatic_basic_training()
		assert_array(host.training_queue).is_empty()
		var demands:Array=host.workshop.army_demands()
		assert_bool(demands.any(func(d:Dictionary)->bool:return d.item=="improvised" and int(d.target)>0)).is_true()
		host.military_inventory.improvised=6
		var before:int=host._mobilized_count()
		host._ensure_automatic_basic_training()
		assert_int(host._automatic_basic_trainees()).is_equal(6)
		assert_int(host.aggregate_recruits).is_equal(4)
		assert_int(host._mobilized_count()).is_equal(before)
		host._ensure_automatic_basic_training()
		assert_int(host._automatic_basic_trainees()).is_equal(6)
	)
func test_controller_returns_unserviceable_waiting_recruits_without_disbanding_troops()->void:
	WorldSimulation.scoped("intake",func()->void:
		var host:=setup();host.aggregate_recruits=100
		host.home_army=host.simulator.create_formation_force("Home",[{"unit":"levy","weapon":"improvised","count":3,"equipment":0}])
		WorldSimulation.state.resource_stockpiles.clear()
		var plan:=Controller.current_plan("intake")
		Controller.military_orders("intake",plan)
		assert_int(host.aggregate_recruits).is_equal(0)
		assert_int(int(host.home_army.troops)).is_equal(3)
		assert_array(host.training_queue).is_empty()
		assert_float(WorldSimulation.state.population_exact).is_equal(500.0)
	)
