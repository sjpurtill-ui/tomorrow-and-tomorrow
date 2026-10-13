extends GdUnitTestSuite
## The day rebuilds the people's metrics from nothing (consequence_engine.gd).
## Running readings other systems keep there (KEPT_METRICS) must outlive it:
## rebuilt away, a decree's pull never added up to a person, the share of food
## brought in never rose past one day's step, a struck people's fear was gone
## by morning, and the usual toll of hard times read zero on the Health page.
const DAY=preload("res://scripts/civilization_day.gd")
const Engine_:=preload("res://scripts/consequence_engine.gd")

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.alpha.controller="manual"

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func test_running_readings_outlive_the_days_rebuild()->void:
	assert_bool(WorldSimulation.submit("alpha",{"kind":"found"}).get("ok",false)).is_true()
	var read:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:
		for day in range(1,6):DAY.advance(day,DAY.context(Vector2.ZERO))
		var m:Dictionary=WorldSimulation.state.simulation_metrics
		# What the day itself keeps there is still there after its rebuild.
		var first:={"hardship":m.has("usual_hardship_rate"),"hardship_value":float(m.get("usual_hardship_rate",-1.0))}
		m["war_fear"]=0.4
		m["food_import_share"]=0.25
		m["top_fifth_share"]=0.55
		DAY.advance(6,DAY.context(Vector2.ZERO))
		m=WorldSimulation.state.simulation_metrics
		first["fear"]=float(m.get("war_fear",-1.0))
		first["import"]=m.has("food_import_share")
		first["fifth"]=m.has("top_fifth_share")
		for day in range(7,372):DAY.advance(day,DAY.context(Vector2.ZERO))
		first["fear_year"]=float(WorldSimulation.state.simulation_metrics.get("war_fear",-1.0))
		return first)
	assert_bool(bool(read.hardship)).is_true()
	assert_float(float(read.hardship_value)).is_greater(0.0)
	# Fear is kept, and fades: a day takes a little, a year about half.
	assert_float(float(read.fear)).is_between(0.39,0.4)
	assert_float(float(read.fear_year)).is_between(0.15,0.25)
	assert_bool(bool(read["import"])).is_true()
	assert_bool(bool(read.fifth)).is_true()

func test_every_kept_metric_has_a_named_keeper()->void:
	assert_array(Engine_.KEPT_METRICS).contains(["directive_migration_progress","food_import_share","war_fear","fabric_weather","usual_hardship_rate"])
