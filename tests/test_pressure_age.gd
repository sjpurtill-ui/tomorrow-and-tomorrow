extends GdUnitTestSuite
## THE QUIET AGE AND THE PRESSURE AFTER IT (pressure_age.gd, war_loop.gd):
## for 300 years no people comes against another unprovoked; after that the
## pressure rises over 60 years, and a neighbour who leans on us and can
## reach us comes about once in ten years. The same clock for every people.
## Quick: three simulated peoples next door to ours, no day simulated.

const Pressure:=preload("res://scripts/pressure_age.gd")
const War:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Strategy:=preload("res://scripts/civilization_strategy.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,3))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	ids=[]
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for i in CivilizationSystem.civilizations.size():
		var c:Dictionary=CivilizationSystem.civilizations[i]
		ids.append(String(c.id))
		var at:=Vector2(60.0*float(i+1),0.0)
		c["world_position"]=at
		c["position"]=Vector2(at.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,0.0)
		for region:Dictionary in c.get("strategic_regions",[]):
			if String(region.get("role",""))=="capital": region["position"]=at
		c["alive"]=true; c["population"]=900.0
		var rel:Dictionary=c.player_relation
		rel["contact_level"]=2; rel["home_location_known"]=true; rel["opinion"]=-0.3; rel["treaty"]="none"; rel["at_war"]=false
	ForeignDiplomacy.ensure()

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

func _year(year:float)->void:
	GameState.elapsed_days=year*365.0

func test_the_clock_is_quiet_for_300_years_then_rises_over_60()->void:
	assert_float(Pressure.at_year(0.0)).is_equal(0.0)
	assert_float(Pressure.at_year(300.0)).is_equal(0.0)
	assert_float(Pressure.at_year(330.0)).is_equal_approx(0.5,0.0001)
	assert_float(Pressure.at_year(360.0)).is_equal(1.0)
	assert_float(Pressure.at_year(2000.0)).is_equal(1.0)
	_year(120.0)
	assert_bool(Pressure.quiet()).is_true()
	assert_str(Pressure.words()).contains("before year 300")
	_year(318.0)
	assert_bool(Pressure.quiet()).is_false()
	assert_str(Pressure.words()).contains("3 parts in 10")

func test_in_the_quiet_age_nobody_comes_unless_we_wronged_them()->void:
	var a:=String(ids[0])
	_year(120.0)
	assert_bool(War.provoked(a)).is_false()
	assert_bool(War.may_come(a)).is_false()
	assert_float(War.pressure_chance(a)).is_equal(0.0)
	# A refused demand, envy and a bolder mood send nobody.
	for cause:String in ["refusal","envy","bolder","pressure"]:
		War._schedule(a,int(GameState.elapsed_days)+30,cause,"t")
		assert_dict(War.front(a).pending).override_failure_message(cause).is_empty()
	# Nor does anyone demand tribute at spear-point.
	var rng:=RandomNumberGenerator.new()
	for seed_value in 12:
		rng.seed=seed_value
		assert_dict(Hall._candidate("tribute_demand",a,{"type":"tension_rise","key":"t","civ_id":a,"data":{}},rng,{},int(GameState.elapsed_days))).is_empty()
	# We wrong them: now they may come, in the quiet age too.
	Rivals.grudge(a,"the gift you tore from our bearers",0.6,"seized_gift:test")
	assert_bool(War.provoked(a)).is_true()
	assert_bool(War.may_come(a)).is_true()
	War._schedule(a,int(GameState.elapsed_days)+30,"refusal","t")
	assert_dict(War.front(a).pending).is_not_empty()
	# Vengeance for our own attack was never held back.
	var b:=String(ids[1])
	War._schedule(b,int(GameState.elapsed_days)+30,"vengeance","attack")
	assert_dict(War.front(b).pending).is_not_empty()

func test_after_it_a_neighbour_who_can_reach_us_comes_about_once_in_ten_years()->void:
	var a:=String(ids[0])
	_year(400.0)
	assert_bool(War.may_come(a)).is_true()
	var lean:=War.pressure_lean(a)
	assert_float(lean).is_between(0.2,2.0)
	var monthly:=War.pressure_chance(a)
	assert_float(monthly).is_equal_approx(Pressure.PER_YEAR/12.0*lean*lerpf(0.5,1.0,War.proximity(a)),0.0001)
	assert_float(monthly*12.0).is_between(0.02,0.25)
	# Halfway up the ramp, half as often.
	_year(330.0)
	assert_float(War.pressure_chance(a)).is_equal_approx(monthly*0.5,0.0005)
	_year(400.0)
	# A people that dislikes us leans harder than one that likes us.
	var cold:=War.pressure_lean(a)
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["opinion"]=0.6
	assert_float(War.pressure_lean(a)).is_less(cold)
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["opinion"]=-0.3
	# Bound to peace, they do not come: the god's choices still count.
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["treaty"]="non_aggression"
	assert_float(War.pressure_chance(a)).is_equal(0.0)
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["treaty"]="none"
	# Nor a people far weaker than us: it has nothing to press with.
	if War.ratio(a)>=War.PRESSURE_LEAST_RATIO:
		var people:=float(CivilizationSystem.civilizations[0].population)
		CivilizationSystem.civilizations[0]["population"]=1.0
		GameState.ensure_population_total(60000)
		if War.ratio(a)<War.PRESSURE_LEAST_RATIO: assert_float(War.pressure_chance(a)).is_equal(0.0)
		CivilizationSystem.civilizations[0]["population"]=people
	# Nor a people at war with us already, nor one we have never met.
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["contact_level"]=1
	assert_float(War.pressure_chance(a)).is_equal(0.0)
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["contact_level"]=2

func test_the_pressure_sends_them_at_about_the_stated_rate()->void:
	_year(400.0)
	var start:=int(GameState.elapsed_days)
	var expected:=0.0
	var came:=0
	# Each month for 100 years, with the slate wiped so every month is a fresh roll.
	for month in 1200:
		var day:=start+month*30
		GameState.elapsed_days=float(day)
		for id:String in ids: expected+=War.pressure_chance(id,day)
		var before:=int((War.state().stats as Dictionary).get("pressure_comings",0))
		War._pressure(day)
		came+=int((War.state().stats as Dictionary).get("pressure_comings",0))-before
		for id:String in ids:
			var f:=War.front(id)
			f["pending"]={}; f["level"]=0; f["war"]={}; f["last_harm"]=-99999
			(CivilizationSystem.civilizations[ids.find(id)].player_relation as Dictionary)["at_war"]=false
			(CivilizationSystem.civilizations[ids.find(id)].player_relation as Dictionary)["opinion"]=-0.3
			(CivilizationSystem.civilizations[ids.find(id)].player_relation as Dictionary)["treaty"]="none"
	assert_float(expected).is_greater(8.0)
	assert_float(float(came)).is_between(expected*0.6,expected*1.4)

func test_other_peoples_keep_the_same_clock_among_themselves()->void:
	var first:Dictionary=CivilizationSystem.civilizations[0]
	var second:Dictionary=CivilizationSystem.civilizations[1]
	var relation:={"opinion":-0.4,"border_tension":0.5}
	_year(200.0)
	assert_float(War.rival_war_hazard(first,second,relation)).is_equal(0.0)
	_year(301.0)
	var early:=War.rival_war_hazard(first,second,relation)
	assert_float(early).is_greater(0.0)
	_year(400.0)
	var full:=War.rival_war_hazard(first,second,relation)
	assert_float(full).is_greater(early*3.0)
	assert_float(full).is_less_equal(War.RIVAL_WAR_CAP*War.RIVAL_PRESSURE+0.0001)

func test_rulers_keep_more_under_arms_and_take_offence_sooner_under_pressure()->void:
	var p:={"assertiveness":0.5,"discipline":0.5,"risk_tolerance":0.5,"empathy":0.5,"openness":0.5}
	# The age's own share moves with the years; the pressure is the part on top.
	var Scale:=preload("res://scripts/standing_scale.gd")
	var band:Array=Scale.anchors(Scale.DEFENSE_SHARE,420.0)
	var plain:=clampf(float(band[1]),float(band[0]),float(band[3]))/100.0*Scale.ABLE_SHARE
	var pressed:=clampf(float(band[1])*(1.0+Pressure.WATCH_GAIN),float(band[0]),float(band[3]))/100.0*Scale.ABLE_SHARE
	assert_float(Strategy.watch_share(p,420.0,false)).is_equal_approx(pressed,0.00001)
	assert_float(pressed).is_greater_equal(plain)
	var quiet_band:Array=Scale.anchors(Scale.DEFENSE_SHARE,200.0)
	assert_float(Strategy.watch_share(p,200.0,false)).is_equal_approx(float(quiet_band[1])/100.0*Scale.ABLE_SHARE,0.00001)
