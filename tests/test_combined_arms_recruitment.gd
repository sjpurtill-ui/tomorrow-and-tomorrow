extends GdUnitTestSuite
const R=preload("res://scripts/combined_arms_recruitment.gd")
const C=preload("res://scripts/civilization_controller.gd")
const Strategy=preload("res://scripts/civilization_strategy.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("recruitment",118)
func after_test()->void:WorldSimulation.clear()
func setup()->Dictionary:
	var state=WorldSimulation.state;var host=WorldSimulation.military
	state.settlement_site_committed=true;state.convoy_traveling=false;state.population_allocations.Crafting=10
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Defense=100
	for id:String in ["bow_craft","skirmisher_infantry_screens"]:
		state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
	host.home_army=host.simulator.create_formation_force("Home",[{"unit":"spearman","weapon":"spear","count":60,"equipment":60,"training":1.0}])
	host.aggregate_recruits=100;host.military_inventory.bow=100
	return Strategy.preferences({}, {"food_days":120,"food_intake_ratio":1.0,"at_war":false})
func recommend(plan:Dictionary)->Dictionary:
	return R.recommendation("spearman",plan,func(item:String)->bool:return C.can_supply_equipment(WorldSimulation.military,item))
func test_controller_orders_only_missing_support_and_does_not_grant_troops()->void:
	WorldSimulation.scoped("recruitment",func()->void:
		var plan:=setup();var host=WorldSimulation.military
		var before:=host._mobilized_count();var equipment:Dictionary=host.military_inventory.duplicate(true)
		var suggestion:=recommend(plan)
		assert_str(suggestion.unit).is_equal("skirmisher");assert_int(int(suggestion.count)).is_equal(30)
		C.land_training_orders("recruitment","spearman","spear",100,plan)
		assert_int(host.training_queue.size()).is_equal(1)
		assert_str(host.training_queue[0].unit).is_equal("skirmisher");assert_int(int(host.training_queue[0].count)).is_equal(30)
		assert_int(host.aggregate_recruits).is_equal(70);assert_int(host._mobilized_count()).is_equal(before)
		assert_dict(host.military_inventory).is_equal(equipment)
		assert_dict(recommend(plan)).is_empty()
	)
func test_existing_and_pending_support_bound_further_orders()->void:
	WorldSimulation.scoped("recruitment",func()->void:
		var plan:=setup();var host=WorldSimulation.military
		host.home_army.formations.append({"unit":"skirmisher","count":10,"equipment":0,"training":0.0})
		host.training_queue.append({"unit":"skirmisher","count":15})
		assert_int(int(recommend(plan).count)).is_equal(5)
		host.aggregate_recruits=2;assert_int(int(recommend(plan).count)).is_equal(2)
		host.training_queue[0].count=20;assert_dict(recommend(plan)).is_empty()
	)
func test_research_adoption_supply_and_training_guards()->void:
	WorldSimulation.scoped("recruitment",func()->void:
		var plan:=setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		state.known_discoveries.erase("skirmisher_infantry_screens");state.discovery_adoption.erase("skirmisher_infantry_screens")
		assert_str(String(recommend(plan).unit)).is_equal("skirmisher")
		assert_dict(preload("res://scripts/combined_arms_doctrine.gd").levels()).is_empty()
		state.discovery_adoption.skirmisher_infantry_screens=1.0;state.discovery_adoption.bow_craft=.01;assert_dict(recommend(plan)).is_empty()
		state.discovery_adoption.bow_craft=1.0;host.military_inventory.bow=0;state.resource_stockpiles.clear();assert_dict(recommend(plan)).is_empty()
		host.military_inventory.bow=100;plan.hungry=true;assert_dict(recommend(plan)).is_empty()
		plan.hungry=false;plan.training="suspended";assert_dict(recommend(plan)).is_empty()
	)
func test_no_support_for_unrelated_primary_or_empty_home_force()->void:
	WorldSimulation.scoped("recruitment",func()->void:
		var plan:=setup()
		assert_dict(R.recommendation("levy",plan,func(_item:String)->bool:return true)).is_empty()
		WorldSimulation.military.home_army.formations.clear()
		assert_dict(recommend(plan)).is_empty()
	)
