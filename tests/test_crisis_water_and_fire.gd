extends GdUnitTestSuite
## Clean water and sanitation beyond plenty keep lowering endemic sickness,
## within a bound (crisis_system water_term); huts rebuilt apart after a fire
## make every later fire rarer (the "spaced" flag), for the god's people and,
## by the same silent rule, every other people.

const Crisis:=preload("res://scripts/crisis_system.gd")
const Unattended:=preload("res://scripts/crisis_unattended.gd")
const SEED:=515253

var _saved_people:Array=[]
var _saved_effects:Dictionary={}

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(110)
	GameState.settlement_founded_day=0
	GameState.elapsed_days=400
	GameState.chronicle={}
	Crisis.onsets_enabled=false
	_saved_people=GovernmentPeopleSystem.people.duplicate(true)
	_saved_effects=DiscoverySystem.society_model.effect_totals.duplicate(true)

func after_test()->void:
	GovernmentPeopleSystem.people=_saved_people
	DiscoverySystem.society_model.effect_totals=_saved_effects
	Crisis.onsets_enabled=true
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	GameState.set_process(true); CivilizationSystem.set_process(true); MilitaryCampaign.set_process(true)

func _x()->Dictionary:
	var x:=Crisis.inputs(int(GameState.elapsed_days))
	x["pop"]=float(GameState.population_total)
	return x

func test_water_term_rewards_clean_water_beyond_plenty_within_a_bound()->void:
	assert_float(Crisis.water_term(1.0)).is_equal_approx(0.0,.000001)
	# Short of water: as before, 1.5 a unit short.
	assert_float(Crisis.water_term(0.8)).is_equal_approx(0.3,.000001)
	assert_float(Crisis.water_term(1.1)).is_equal_approx(-0.15,.000001)
	assert_float(Crisis.water_term(1.2)).is_equal_approx(-0.3,.000001)
	assert_float(Crisis.water_term(3.0)).is_equal_approx(-0.3,.000001)

func test_water_works_and_sanitation_lower_sickness_while_water_is_plentiful()->void:
	var day:=int(GameState.elapsed_days)
	GameState.simulation_metrics["water_intake_ratio"]=1.0
	var effects:Dictionary=DiscoverySystem.society_model.effect_totals
	for key in ["sanitation","water_safety","disease_exposure","health_protection"]:effects[key]=0.0
	var plain:=_x()
	assert_float(float(plain.water_q)).is_equal_approx(1.0,.0001)
	var before:=float(Crisis.hazards(day,plain).sickness)
	# Latrines, protected wells and settling basins act through these channels.
	effects["sanitation"]=0.3;effects["water_safety"]=0.3
	var clean:=_x()
	assert_float(float(clean.water_q)).is_equal_approx(1.12,.0001)
	var after:=float(Crisis.hazards(day,clean).sickness)
	print("SICKNESS HAZARD: plain %.3f/yr, with sanitation and safe water %.3f/yr" % [before,after])
	assert_float(after).is_less(before)
	# The water term alone, all else equal: e^(-1.5 x 0.12).
	var same:=plain.duplicate();same["water_q"]=1.12
	assert_float(float(Crisis.hazards(day,same).sickness)/before).is_equal_approx(exp(-1.5*0.12),.0001)
	# Bounded: the best water and sanitation make a people fall sick about a quarter less often.
	same["water_q"]=5.0
	assert_float(float(Crisis.hazards(day,same).sickness)/before).is_equal_approx(exp(-0.3),.0001)
	# Short of water, nothing changes from before.
	same["water_q"]=0.8
	assert_float(float(Crisis.hazards(day,same).sickness)/before).is_equal_approx(exp(0.3),.0001)

func test_rebuilding_apart_after_a_fire_makes_every_later_fire_rarer()->void:
	var day:=int(GameState.elapsed_days)
	GameState.housing_capacity=180
	GameState.resource_stockpiles["Timber"]=500.0
	var x:=_x()
	var before:=float(Crisis.hazards(day,x).fire)
	Crisis._open_fire(day,x)
	var c:=Crisis._active_of("fire")
	assert_bool(c.is_empty()).is_false()
	var mult:=float(c.mult)
	var timber:=float(GameState.resource_stockpiles.Timber)
	var housing:=int(GameState.housing_capacity)
	var said:=Crisis._apply(c,"apart","open",false)
	print("REBUILT APART: ",said.outcome)
	assert_str(String(said.outcome)).contains("apart")
	assert_str(String(said.outcome).to_lower()).not_contains("sick")
	# This fire's toll is what it was; the timber goes as for rebuilding.
	assert_float(float(c.mult)).is_equal(mult)
	assert_float(Crisis.death_factor(c,"apart")).is_equal(1.0)
	assert_float(timber-float(GameState.resource_stockpiles.Timber)).is_equal_approx(minf(timber,float(c.house_lost)*0.8),.0001)
	assert_bool(bool((Crisis.state().flags as Dictionary).get("spaced",false))).is_true()
	assert_bool(bool((Crisis.state().flags as Dictionary).get("apart_custom",false))).is_false()
	var slowed:=false
	for modifier in GameState.active_modifiers:
		if String(modifier.get("id",""))=="crisis_%s_apart" % String(c.id):slowed=true
	assert_bool(slowed).is_true()
	# Every later fire is SPACED_FIRE_FACTOR as likely.
	assert_float(float(Crisis.hazards(day,x).fire)).is_equal_approx(before*Crisis.SPACED_FIRE_FACTOR,.000001)
	# The huts stand again when its course ends.
	for d in range(day+1,int(c.end_day)+2):
		GameState.elapsed_days=d
		if (Crisis.state().active as Dictionary).has(String(c.id)):Crisis._advance(c,d,_x())
	assert_int(int(GameState.housing_capacity)).is_equal(housing+int(c.house_lost))

func test_the_fire_answers_say_their_sizes()->void:
	var c:={"id":"f1","type":"fire","m":0.01,"mult":1.0,"pop0":120,"choice":"","mid_choice":"","phase":"open"}
	(Crisis.state().active as Dictionary)["f1"]=c
	var found:={}
	for option:Dictionary in Crisis.options({"situation":{"crisis":{"id":"f1","phase":"open"}}}):found[String(option.get("id",""))]=option
	assert_bool(found.has("apart")).override_failure_message(str(found.keys())).is_true()
	assert_str(String(found.apart.sub)).contains("fires come %d%% less often" % roundi((1.0-Crisis.SPACED_FIRE_FACTOR)*100.0))
	assert_str(String(found.apart.sub)).contains("%d days" % Crisis.REBUILD_APART_DAYS)
	# Rebuilding apart changes later fires, not this one's toll.
	assert_str(Crisis.stakes_words(c,"apart","open")).contains("about the same")

func test_a_people_that_has_burned_before_rebuilds_apart_when_left_to_itself()->void:
	var c:={"id":"x","type":"fire"}
	(Crisis.state().stats as Dictionary)["fire"]={"onsets":1.0}
	assert_str(Crisis._default_choice(c,"open")).is_equal("rebuild")
	(Crisis.state().stats as Dictionary)["fire"]={"onsets":2.0}
	assert_str(Crisis._default_choice(c,"open")).is_equal("apart")

func test_a_computer_people_rebuilds_apart_by_the_same_rule()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("gamma",4242,Vector2.ZERO)
	WorldSimulation.actors.gamma.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.gamma.controller="manual"
	assert_bool(WorldSimulation.submit("gamma",{"kind":"found"}).get("ok",false)).is_true()
	var result:Dictionary=WorldSimulation.scoped("gamma",func()->Dictionary:
		var people=WorldSimulation.state
		var s:=Crisis.state()
		var day:=Crisis.QUIET_AFTER_FOUNDING+60
		people.elapsed_days=float(day)
		people.settlement_founded_day=0
		people.resource_stockpiles["Timber"]=500.0
		var x:=Crisis.inputs(day)
		var first:=float(Crisis.hazards(day,x,s).fire)
		# Its first fire: rebuilt as it was.
		Unattended._open_fire(s,day,x)
		var one:=Crisis._active_in(s,"fire")
		var first_choice:=String(one.choice)
		(s.active as Dictionary).clear()
		# Its second: rebuilt apart, paid from its own timber, and later fires are rarer.
		var housing:=int(people.housing_capacity)
		var timber:=float(people.resource_stockpiles.Timber)
		Unattended._open_fire(s,day+300,x)
		var two:=Crisis._active_in(s,"fire")
		var spent:=timber-float(people.resource_stockpiles.Timber)
		for d in range(day+301,int(two.end_day)+2):
			if not (s.active as Dictionary).has(String(two.id)):break
			people.elapsed_days=float(d)
			Unattended._advance(s,two,d,x)
		return {"first_choice":first_choice,"second_choice":String(two.choice),"spaced":bool((s.flags as Dictionary).get("spaced",false)),"first":first,"after":float(Crisis.hazards(day,x,s).fire),"housing_back":int(people.housing_capacity)-(housing-int(two.house_lost)),"house_lost":int(two.house_lost),"timber_spent":spent})
	assert_str(String(result.first_choice)).is_equal("rebuild")
	assert_str(String(result.second_choice)).is_equal("apart")
	assert_bool(bool(result.spaced)).is_true()
	assert_float(float(result.after)).is_equal_approx(float(result.first)*Crisis.SPACED_FIRE_FACTOR,.000001)
	assert_int(int(result.housing_back)).is_equal(int(result.house_lost))
	assert_float(float(result.timber_spent)).is_greater(0.0)
	# The god's people's court is untouched by it.
	assert_bool(bool((Crisis.state().flags as Dictionary).get("spaced",false))).is_false()
