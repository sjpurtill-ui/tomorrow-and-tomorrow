extends GdUnitTestSuite
## Crises for every people (crisis_unattended.gd): a computer-run people meets
## the same crises as the god's people, from the same hazards, with the same
## death draws and floors and the court official's own answers, paid out of
## its own ledger and never the god's people's.

const Unattended:=preload("res://scripts/crisis_unattended.gd")
const Crises:=preload("res://scripts/crisis_system.gd")
const DAY:=preload("res://scripts/civilization_day.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9191)
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("gamma",4242,Vector2.ZERO)
	WorldSimulation.actors.gamma.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.gamma.controller="manual"
	assert_bool(WorldSimulation.submit("gamma",{"kind":"found"}).get("ok",false)).is_true()

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _in_gamma(operation:Callable)->Variant:
	return WorldSimulation.scoped("gamma",operation)

## Hunger at the door: a long shortage and short rations.
func _starving(day:int)->void:
	_in_gamma(func()->void:
		var people=WorldSimulation.state
		people.elapsed_days=float(day)
		people.settlement_founded_day=0
		people.simulation_metrics["food_shortage_days"]=14.0
		people.simulation_metrics["food_intake_ratio"]=0.8
		people.simulation_metrics["food_days"]=4.0)

func test_a_computer_people_meets_hunger_from_its_own_ledger()->void:
	var player_modifiers:=GameState.active_modifiers.size()
	var player_court:=(ForeignDiplomacy.audiences as Dictionary).duplicate(true)
	var day:=Crises.QUIET_AFTER_FOUNDING+60
	_starving(day)
	_in_gamma(func()->void: Unattended.daily(day))
	var s:Dictionary=_in_gamma(func()->Dictionary: return Crises.state())
	var hunger:=Crises._active_in(s,"hunger")
	assert_bool(hunger.is_empty()).is_false()
	# The court official's silent answer: smaller portions, at once.
	assert_str(String(hunger.choice)).is_equal("ration")
	var rationed:=false
	for modifier in WorldSimulation.actors.gamma.systems.GameState.active_modifiers:
		if String(modifier.get("id","")).ends_with("_ration"): rationed=true
	assert_bool(rationed).is_true()
	# Nothing of it touches the god's people.
	assert_int(GameState.active_modifiers.size()).is_equal(player_modifiers)
	assert_dict(ForeignDiplomacy.audiences as Dictionary).is_equal(player_court)

func test_deaths_follow_the_courts_draws_and_never_pass_the_floor()->void:
	var day:=Crises.QUIET_AFTER_FOUNDING+60
	_starving(day)
	_in_gamma(func()->void: Unattended.daily(day))
	var before:int=_in_gamma(func()->int: return int(WorldSimulation.state.population_total))
	var s:Dictionary=_in_gamma(func()->Dictionary: return Crises.state())
	var hunger:=Crises._active_in(s,"hunger")
	# A grave famine: the worst the court's draw allows.
	hunger.m=0.25
	hunger.mult=1.0
	var end_day:=int(hunger.end_day)
	_in_gamma(func()->void:
		for d in range(day+1,end_day+2):
			WorldSimulation.state.elapsed_days=float(d)
			Unattended.daily(d))
	var after:int=_in_gamma(func()->int: return int(WorldSimulation.state.population_total))
	var floor_count:=maxi(Crises.FLOOR_PEOPLE,roundi(float(hunger.pop0)*Crises.FLOOR_SHARE))
	assert_int(after).is_less(before)
	assert_int(after).is_greater_equal(floor_count)
	assert_int(int(hunger.deaths)).is_equal(before-after)
	# Over, and remembered in its history.
	assert_bool(Crises._active_in(s,"hunger").is_empty()).is_true()
	assert_str(String((s.history as Array)[0].type)).is_equal("hunger")

func test_the_same_hazards_are_read_in_each_peoples_own_scope()->void:
	var day:=Crises.QUIET_AFTER_FOUNDING+60
	_starving(day)
	var theirs:Dictionary=_in_gamma(func()->Dictionary: return Crises.inputs(day))
	var ours:=Crises.inputs(day)
	assert_float(float(theirs.intake)).is_equal_approx(0.8,0.0001)
	assert_float(float(ours.intake)).is_not_equal(0.8)
	assert_float(float(theirs.pop)).is_equal(float(WorldSimulation.actors.gamma.systems.GameState.population_total))

func test_every_people_steps_its_hardship_in_the_daily_pass()->void:
	# The day's steps call it for every people but the god's.
	var source:=FileAccess.get_file_as_string("res://scripts/civilization_day.gd")
	assert_str(source).contains("S.step(\"hardship\"")
	assert_str(source).contains("crisis_unattended.gd")

## The stakes of a crisis answer quote the very factor the answer applies.
func test_crisis_answers_state_their_deaths_from_the_one_table()->void:
	var c:={"id":"t1","type":"hunger","kind":"lean_season","m":0.05,"mult":1.0,"pop0":120}
	var said:=Crises.stakes_words(c,"ration","open")
	assert_str(said).is_equal("As things stand about 6 may die; this way about %d." % roundi(120*0.05*float(Crises.DEATH_FACTOR.ration)))
	# Tending everyone spreads it: the stated number rises.
	var s2:={"id":"t2","type":"sickness","kind":"fever","m":0.05,"mult":1.0,"pop0":120}
	assert_str(Crises.stakes_words(s2,"tend","open")).contains("this way about 8")
	# The flux answers clean water best.
	s2.kind="flux"
	assert_float(Crises.death_factor(s2,"water")).is_equal(Crises.WATER_FLUX_FACTOR)
	# A crisis that takes no lives states none.
	var cold:={"id":"t3","type":"cold","m":0.0,"mult":1.0,"pop0":120}
	assert_str(Crises.stakes_words(cold,"ration","open")).is_equal("")
