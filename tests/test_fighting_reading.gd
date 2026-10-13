extends GdUnitTestSuite
## ONE READING OF A PEOPLE'S FIGHTING STRENGTH (MilitaryCampaign.fighting_reading):
## ours and every other people's by the same rule. Ours used to leave out the
## bands in the field; a rival's commander was a number drawn once at the
## world's making; the age of their arms and their kit were never written.
const DAY=preload("res://scripts/civilization_day.gd")
const Standing:=preload("res://scripts/standing.gd")

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	GameState.reset_for_new_world(9241)
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,2))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.start_world()

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	MilitaryCampaign.reset_for_new_world()

func _army(mc:Node,home:int,out:int,home_ready:float,out_ready:float)->void:
	mc.home_army=mc.simulator.create_formation_force("Home",[{"id":1,"unit":"levy","weapon":"improvised","count":home,"equipment":home,"training":0.6}],home_ready,0.8)
	mc.home_army["readiness"]=home_ready
	mc.home_army["commander"]={"command":0.9,"tactics":0.7,"logistics":0.5,"resolve":0.7}
	mc.field_armies.clear()
	if out>0:
		var band:Dictionary=mc.simulator.create_formation_force("Band",[{"id":2,"unit":"levy","weapon":"improvised","count":out,"equipment":out,"training":0.6}],out_ready,0.8)
		band["readiness"]=out_ready;band["army_id"]=7
		mc.field_armies.append(band)

func test_ours_counts_the_bands_in_the_field_like_theirs()->void:
	_army(MilitaryCampaign,100,300,0.8,0.4)
	var ours:Dictionary=MilitaryCampaign.fighting_reading()
	assert_float(float(ours.warriors)).is_equal(400.0)
	# Readiness weighed by where the men stand: (100 x 0.8 + 300 x 0.4) / 400.
	assert_float(float(ours.readiness)).is_equal_approx(0.5,0.0001)
	assert_float(float(ours.command)).is_equal_approx(0.7,0.0001)
	assert_float(Standing._warriors()).is_equal(400.0)
	assert_float(Standing._readiness()).is_equal_approx(0.5,0.0001)

func test_a_rivals_summary_carries_the_same_reading_as_it_stands_now()->void:
	var id:=String(CivilizationSystem.civilizations[0].id)
	var drawn:=float(CivilizationSystem.civilizations[0].get("command_readiness",-1.0))
	WorldSimulation.scoped(id,func()->void:_army(WorldSimulation.military,100,300,0.8,0.4))
	var theirs:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:return WorldSimulation.military.fighting_reading())
	# Their summary, read afresh (a people that has not moved a day keeps its last reading).
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	WorldSimulation.scoped(id,func()->void:WorldSimulation.project(civ))
	var people:=float(civ.population)
	assert_float(float(civ.fighting_men)).is_equal_approx(minf(float(theirs.warriors),people),0.001)
	assert_float(float(civ.military_readiness)).is_equal_approx(float(theirs.readiness),0.0001)
	# Their commander as he is, not the number drawn at the world's making.
	assert_float(float(civ.command_readiness)).is_equal_approx(0.7,0.0001)
	assert_float(float(civ.command_readiness)).is_not_equal(drawn)
	assert_bool(civ.has("military_era_tier")).is_true()
	assert_bool(civ.has("military_replacement_coverage")).is_true()
	# The same men, the same rule: a rival with our army reads as our equal in warriors.
	_army(MilitaryCampaign,100,300,0.8,0.4)
	assert_float(minf(float(MilitaryCampaign.fighting_reading().warriors),people)).is_equal_approx(float(civ.fighting_men),0.001)
