extends GdUnitTestSuite
const R=preload("res://scripts/civilization_resources.gd")
func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.enabled=true
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":{"resource_potentials":{"Clay":.95},"signature":"clay-test"}}
	for id:String in ["survey_a","survey_b"]:
		WorldSimulation.create_actor(id,777)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
func after_test()->void:WorldSimulation.clear();WorldSimulation.context_provider=Callable()
func test_returned_survey_uses_shared_finite_geology_and_other_society_cannot_refill()->void:
	var found:Dictionary={}
	var location:=Vector2.ZERO
	WorldSimulation.scoped("survey_a",func()->void:
		for x in range(10,30):
			var result:=R.survey_occurrence("Clay",Vector2(x*16+8,8))
			if not result.is_empty():found.merge(result,true);break
	)
	assert_dict(found).is_not_empty()
	if found.is_empty():return
	var parts:=String(found.world_key).split(":")
	location=Vector2(int(parts[0])*16+8,int(parts[1])*16+8)
	var original:=float(found.remaining)
	assert_float(original).is_greater(0.0)
	assert_float(R.withdraw(found,original)).is_equal(original)
	WorldSimulation.scoped("survey_b",func()->void:
		var stocks:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_dict(R.survey_occurrence("Clay",location)).is_empty()
		for deposit:Dictionary in WorldSimulation.state.resource_deposits:
			if deposit.get("world_key","")==found.world_key:assert_float(float(deposit.remaining)).is_equal(0.0)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks)
	)
	assert_float(float(WorldSimulation.geography_stock[found.world_key].remaining)).is_equal(0.0)

func test_survey_uses_terrain_geology_not_favorable_report_to_create_stock()->void:
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":{"resource_potentials":{"Clay":0.0}}}
	WorldSimulation.scoped("survey_a",func()->void:
		var result:=WorldSimulation.resources.register_expedition_occurrence("Clay",Vector2(1000,1000),{"resource_potentials":{"Clay":1.0}})
		assert_dict(result).is_empty()
	)


