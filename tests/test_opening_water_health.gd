extends GdUnitTestSuite

const Craft=preload("res://scripts/civilian_goods.gd")

## research_600 balance: magnitudes come from the rebalanced catalog entries,
## weighted by their operating factor and held under the era ceiling.
func expected_effect(key:String,ids:Array[String],factor:float=-1.0)->float:
	var total:=0.0
	for id:String in ids:total+=float((DiscoverySystem.discovery_definition(id).get("effects",{}) as Dictionary).get(key,0.0))*(Craft.factor(id) if factor<0.0 else factor)
	return minf(total,DiscoverySystem.society_model.era_ceiling(key).y)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(6413);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.ensure_population_total(100)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.resource_stockpiles["Freshwater"]=0.0
	GameState.population_allocations.Logistics=0;GameState.population_allocations.Food=0

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(ids:Array[String])->void:
	for id:String in ids:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func nearby_water()->Dictionary:
	return {"origin":Vector3.ZERO,"surface_water_distance_km":0.2,"surface_water_kind":"river","surface_water_id":"test_river"}

func test_knowledge_without_water_provides_no_health_effect()->void:
	know(["wound_cleaning","clean_water"])
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("health_protection")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)
	WorldSimulation.resources._process_water_flow({})
	assert_float(float(GameState.water_metrics.wound_cleaning_coverage)).is_equal(0.0)
	assert_float(float(GameState.water_metrics.clean_water_coverage)).is_equal(0.0)
	assert_float(DiscoverySystem.effect("health_protection")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)

func test_local_water_is_spent_and_enables_bounded_practice_coverage()->void:
	know(["wound_cleaning","clean_water"])
	WorldSimulation.resources._process_water_flow(nearby_water())
	var metrics:Dictionary=GameState.water_metrics
	assert_float(float(metrics.required_today)).is_equal(100.0)
	assert_float(float(metrics.practice_required_today)).is_equal_approx(6.5,.000001)
	assert_float(float(metrics.total_required_today)).is_equal_approx(106.5,.000001)
	assert_float(float(metrics.drinking_consumed_today)).is_equal(100.0)
	assert_float(float(metrics.wound_cleaning_water_used)).is_equal_approx(1.5,.000001)
	assert_float(float(metrics.clean_water_water_used)).is_equal_approx(5.0,.000001)
	assert_float(float(metrics.wound_cleaning_coverage)).is_equal(1.0)
	assert_float(float(metrics.clean_water_coverage)).is_equal(1.0)
	assert_float(float(metrics.collected_today)).is_equal_approx(float(metrics.consumed_today)+float(metrics.stored),.000001)
	assert_float(DiscoverySystem.effect("health_protection")).is_equal_approx(expected_effect("health_protection",["wound_cleaning","clean_water"]),.000001)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal_approx(expected_effect("water_safety",["wound_cleaning","clean_water"]),.000001)
	assert_float(DiscoverySystem.effect("water_safety")).is_greater(0.0)

func test_drinking_is_served_before_health_practices_during_shortage()->void:
	know(["wound_cleaning","clean_water"])
	WorldSimulation.resources._process_water_flow({"origin":Vector3.ZERO,"surface_water_distance_km":6.0})
	var metrics:Dictionary=GameState.water_metrics
	assert_float(float(metrics.drinking_consumed_today)).is_equal(float(metrics.consumed_today))
	assert_float(float(metrics.intake_ratio)).is_less(1.0)
	assert_float(float(metrics.wound_cleaning_water_used)).is_equal(0.0)
	assert_float(float(metrics.clean_water_water_used)).is_equal(0.0)
	assert_float(DiscoverySystem.effect("health_protection")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)

func test_baseline_water_demand_is_unchanged_without_the_practices()->void:
	WorldSimulation.resources._process_water_flow(nearby_water())
	var metrics:Dictionary=GameState.water_metrics
	assert_float(float(metrics.required_today)).is_equal(100.0)
	assert_float(float(metrics.practice_required_today)).is_equal(0.0)
	assert_float(float(metrics.total_required_today)).is_equal(100.0)
	assert_float(float(metrics.consumed_today)).is_equal(100.0)
	assert_float(Craft.factor("wound_cleaning")).is_equal(0.0)
	assert_float(Craft.factor("clean_water")).is_equal(0.0)
