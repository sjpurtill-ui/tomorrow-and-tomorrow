extends GdUnitTestSuite
## A DRY YEAR DRAINS THE WATER (dry_water.gd, resource_system.gd,
## crisis_system.gd, crisis_unattended.gd). The user: "yes make droughts
## actually drain the water". A dry year now dries the near springs by its
## depth, ramping in and out; the store falls day by day; the thirst the
## engine already knows ("Dehydration") kills when it runs out; only a small
## toll of its own ("Drought") is left for the heat, the failed forage and
## foul water. Carrying from the far pools, deep wells, water lines and
## cisterns act through the same ledger.
## - the store falls during a dry year, and the tile's days with it;
## - carrying water raises the store; a deep well keeps most of the loss away;
## - a cistern or a deep well lowers the deaths, by the engine's forecast;
## - the user's own dry year (the Year the Springs Failed, 261 people, their
##   three towns' water works) kills about as many as before;
## - no death is counted twice across Drought and Dehydration;
## - the fast sim's mirror gives the same numbers (tools/sim/dry_water.py).
## Offline; never calls a real API.

const Crisis:=preload("res://scripts/crisis_system.gd")
const DryWater:=preload("res://scripts/dry_water.gd")
const Unattended:=preload("res://scripts/crisis_unattended.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(7510);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.ensure_population_total(100);GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.population_allocations.Logistics=10
	GameState.resource_stockpiles={"Freshwater":0.0}
	GameState.active_modifiers.clear()
	ForeignDiplomacy.ensure()
	ForeignDiplomacy.audiences.erase("crises")
	Crisis.onsets_enabled=false

func after_test()->void:
	Crisis.onsets_enabled=true
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _river()->Dictionary:
	return {"origin":Vector3.ZERO,"surface_water_distance_km":0.5,"surface_water_recognized":true,"environment_profile":{"precipitation":0.6}}

func _well()->Dictionary:
	var context:=_river()
	context["water_conveyance_sources"]=[{"id":"well:1","kind":"Lined well","revealed":true,"position":Vector3.ZERO}]
	return context

## A deep dry year from day 10 to day 130.
func _dry_year(depth:float=0.85)->Dictionary:
	var c:={"id":"cT","type":"drought","kind":"drought","name":"the Dry Year of the test","phase":"open","start":10,"end_day":130,"mid_day":45,
		"depth":depth,"sev":0.4,"draw":0.05,"pop0":100,"m":0.0,"mult":1.0,"deaths":0,"dead":[],"choice":"","mid_choice":""}
	(Crisis.state().active as Dictionary)["cT"]=c
	return c

## Runs the water day from `from` to `to`; returns each day's stored water.
func _days(context:Dictionary,from:int,to:int)->Array:
	var stored:Array=[]
	for day in range(from,to+1):
		GameState.elapsed_days=float(day)
		ResourceSystem._process_water_flow(context)
		stored.append(float(GameState.water_metrics.stored))
	return stored

func _carry(from:int)->void:
	# The court's answer, as crisis_system.gd _policy writes it.
	var coefficients:={}
	for channel in Crisis.CARRY_EFFECTS:coefficients[channel]=float(Crisis.CARRY_EFFECTS[channel])/0.2
	GameState.active_modifiers.append({"id":"crisis_cT_carry","kind":"policy","effects":coefficients,"magnitude":0.2,"started_day":float(from),"until_day":float(from+90),"crisis":"cT"})

func test_a_dry_year_drains_the_store_day_by_day()->void:
	var calm:=_days(_river(),1,9)
	var full:=float(calm.back())
	assert_float(full).is_greater(0.0)
	# In good times the store stands still, full.
	assert_float(float(calm[-2])).is_equal_approx(full,0.01)
	_dry_year()
	var dry:=_days(_river(),10,60)
	assert_float(float(GameState.water_metrics.dry_loss)).is_greater(0.5)
	# It falls as the springs fail, and the tile's days fall with it.
	assert_float(float(dry[20])).is_less(full)
	assert_float(float(dry[25])).is_less(float(dry[15]))
	assert_float(float(dry.back())).is_less(full*0.5)
	assert_float(float(GameState.water_metrics.days)).is_less(float(full)/100.0)
	assert_float(float(GameState.water_metrics.intake_ratio)).is_less(0.98)

func test_carrying_from_the_far_pools_raises_the_store()->void:
	_days(_river(),1,9)
	_dry_year()
	var left:=_days(_river(),10,60)
	var intake_left:=float(GameState.water_metrics.intake_ratio)
	before_test()
	_days(_river(),1,9)
	_dry_year()
	_carry(10)
	var carried:=_days(_river(),10,60)
	assert_float(float(GameState.water_metrics.dry_far)).is_greater(0.0)
	assert_float(float(GameState.water_metrics.intake_ratio)).is_greater(intake_left)
	var sum_left:=0.0;var sum_carried:=0.0
	for i in left.size():sum_left+=float(left[i]);sum_carried+=float(carried[i])
	assert_float(sum_carried).is_greater(sum_left)

func test_a_deep_well_keeps_most_of_the_loss_away()->void:
	_days(_river(),1,9)
	_dry_year()
	_days(_river(),10,60)
	var open_loss:=float(GameState.water_metrics.dry_loss)
	var open_store:=float(GameState.water_metrics.stored)
	before_test()
	_days(_well(),1,9)
	_dry_year()
	_days(_well(),10,60)
	assert_float(float(GameState.water_metrics.dry_loss)).is_equal_approx(open_loss*(1.0-DryWater.DEEP_WELL_HOLD),0.02)
	assert_float(float(GameState.water_metrics.stored)).is_greater(open_store)

func test_the_court_quotes_each_answer_from_the_water_forecast()->void:
	_days(_river(),1,9)
	var c:=_dry_year(0.9)
	c["decide_by"]=34
	var regex:=RegEx.create_from_string("about ([0-9]+) may die.*this way about ([0-9]+)")
	# As things stand the holder carries at the decision day: carrying now is
	# about the same (its 90 days end sooner), praying for rain carries nothing.
	var carry:=regex.search(Crisis.stakes_words(c,"carry","open"))
	var rain:=regex.search(Crisis.stakes_words(c,"rain","open"))
	assert_object(carry).is_not_null()
	assert_object(rain).is_not_null()
	assert_int(absi(int(carry.get_string(2))-int(carry.get_string(1)))).is_less_equal(2)
	assert_int(int(rain.get_string(2))).is_greater(int(rain.get_string(1)))
	assert_str(Crisis.stakes_words(c,"hold","mid")).is_empty()

func test_with_no_dry_year_the_water_day_is_unchanged()->void:
	# collect() with no loss is the old arithmetic exactly.
	var parts:={"need":100.0,"cap":135.0,"near":320.0,"household":118.0,"flow":0.95,"organized":202.0,"line":60.0,"rain":9.6,"cistern":250.0,"accessible":true}
	var got:=DryWater.collect(parts,0.0,0.3,0.5)
	var old:=minf(135.0+250.0,minf(135.0,320.0)*0.95+minf(60.0,135.0-118.0*0.95)+9.6)
	assert_float(float(got.collected)).is_equal_approx(old,0.0001)
	assert_float(float(got.far)).is_equal(0.0)

func test_the_thirst_rate_is_the_engines_own()->void:
	for intake in [1.0,0.9,0.6,0.2]:
		for days in [0.0,2.0,9.0]:
			assert_float(ConsequenceEngine._dehydration_mortality_rate(intake,days)).is_equal(DryWater.thirst_rate(intake,days))

# --------------------------------------------------------------------------
# The user's dry year, by the engine's forecast
# --------------------------------------------------------------------------

## The user's three towns on the day the Year the Springs Failed began, from
## their save (each town's water ledger): full stores, everyone drinking.
static func users_towns(change:Dictionary={})->Array:
	var rows:=[["Ashleyfire",114.84,122.30,144.31,450.97,728.28,12.99],["Seanlyfire",81.14,86.42,101.97,296.66,514.58,9.18],["Wallyfire",58.16,61.95,73.10,224.66,368.87,6.58]]
	var out:Array=[]
	for row in rows:
		var drinking:=float(row[1]);var need:=float(row[2])
		var organized:=float(row[4])*float(change.get("organized",1.0))
		var capacity:=float(row[5])*float(change.get("capacity",1.0))
		var parts:={"need":need,"cap":need*DryWater.DRAW_CAP,"near":float(row[3])+organized,"household":float(row[3]),"flow":1.0,"organized":organized,
			"line":float(change.get("line",0.0))*drinking,"rain":0.0,"cistern":0.0,"held":DryWater.held_by(bool(change.get("deep",false)),float(change.get("wells",0.161))),"accessible":true}
		out.append({"name":row[0],"population":drinking,"shortage_days":0.0,
			"water":{"required_today":drinking,"stored":capacity-need,"capacity":capacity,"collection_workers":float(row[6])*float(change.get("organized",1.0)),"dry_parts":parts}})
	return out

## The Year the Springs Failed (crisis c140): sev 0.334, its draw 0.0602,
## days 21556 to 21682, 261 people.
static func springs_failed()->Dictionary:
	return {"id":"c140","type":"drought","phase":"open","start":21556,"end_day":21682,"sev":0.33415129256561904,"draw":0.06018884114340828,"pop0":261,"mult":1.0,"held_sum":0.0,"held_days":0.0}

## Its toll from the first day, the holder carrying from the far pools at
## day 24 for 90 days as they did.
static func users_toll(change:Dictionary={},carry:bool=true)->Dictionary:
	return DryWater.forecast(springs_failed(),users_towns(change),21556.0,{"far":DryWater.CARRY_REACH,"far_days":90.0,"far_from":24.0} if carry else {"choice":"rain"})

func test_the_users_dry_year_kills_about_as_many_as_before()->void:
	# Before: a toll fixed at its start, 261 x 0.0602 x 0.7 for carrying: 11.
	var today:=users_toll()
	assert_float(float(today.total)).is_between(8.0,15.0)
	assert_float(float(today.thirst)).is_greater(float(today.toll))
	# Poor water works (a quarter of the carriers, three days of vessels, no
	# wells): clearly more.
	var poor:=users_toll({"organized":0.25,"capacity":3.0/6.34,"wells":0.0})
	assert_float(float(poor.total)).is_greater(float(today.total)*1.5)
	# A deep well in every town, or a water line, or a cistern: fewer.
	var deep:=users_toll({"deep":true})
	assert_float(float(deep.total)).is_less(float(today.total)/3.0)
	var line:=users_toll({"line":1.0})
	assert_float(float(line.total)).is_less(float(today.total)/3.0)
	var cistern:=DryWater.forecast(springs_failed(),users_towns(),21556.0,{"far":DryWater.CARRY_REACH,"far_days":90.0,"far_from":24.0,"cistern":true})
	assert_float(float(cistern.total)).is_less(float(today.total))
	# Not carrying at all: many more.
	assert_float(float(users_toll({},false).total)).is_greater(float(today.total)*1.5)
	# Silent, the holder carries from the decision day (24 days in): as things stand.
	var silent:=springs_failed();silent["decide_by"]=21580;silent["choice"]=""
	assert_float(float(DryWater.forecast(silent,users_towns(),21556.0).total)).is_equal_approx(float(today.total),0.01)

func test_the_dry_years_depth_comes_from_its_own_draw()->void:
	var c:=springs_failed()
	assert_float(DryWater.depth_of(c)).is_equal_approx(0.334+DryWater.DEPTH_LUCK*2.556,0.002)
	# The median draw for that dryness: the depth is the dryness alone.
	assert_float(DryWater.depth(0.3,DryWater.DRAW_MEDIAN*(1.0+DryWater.DRAW_SEV*0.3))).is_equal_approx(0.3,0.0001)
	assert_float(DryWater.loss(c,21556.0)).is_equal(0.0)
	assert_float(DryWater.loss(c,21600.0)).is_equal_approx(DryWater.depth_of(c),0.0001)
	assert_float(DryWater.loss(c,21682.0)).is_equal(0.0)

## The fixture tools/sim/dry_water.py writes from the fast sim's mirror
## (python tools/sim/dry_water.py; --write to rewrite it): the engine's
## forecast must give the same dead and the same drinking.
func test_the_fast_sims_mirror_gives_the_same_numbers()->void:
	var file:=FileAccess.open("res://tools/sim/dry_water_parity.json",FileAccess.READ)
	assert_object(file).is_not_null()
	var cases:Array=JSON.parse_string(file.get_as_text())
	for case:Dictionary in cases:
		var c:={"start":float(case.start),"end_day":float(case.end),"sev":float(case.sev),"draw":float(case.draw),"pop0":int(case.people),"mult":1.0,"phase":"open"}
		var parts:Dictionary=case.parts
		var town:={"name":"t","population":float(case.people),"shortage_days":0.0,"water":{"required_today":float(case.people),"stored":float(case.capacity)-float(case.people),"capacity":float(case.capacity),"collection_workers":1.0,"dry_parts":parts}}
		var got:=DryWater.forecast(c,[town],float(case.start),{"far":DryWater.CARRY_REACH,"far_days":90.0,"far_from":float(case.carry_from)-float(case.start)})
		assert_float(float(got.thirst)).override_failure_message("%s: %.4f, the sim's %.4f" % [case.name,float(got.thirst),float(case.thirst)]).is_equal_approx(float(case.thirst),0.01)
		assert_float(float(got.held)).is_equal_approx(float(case.held),0.0005)

# --------------------------------------------------------------------------
# One ledger: no death counted twice
# --------------------------------------------------------------------------

func test_thirst_and_the_dry_years_toll_are_counted_once()->void:
	GameState.ensure_population_total(400)
	GameState.settlement_founded_day=0
	GameState.elapsed_days=10.0
	GameState.death_cause_days.clear()
	var c:=_dry_year()
	c.pop0=400;c.sev=0.5
	var before:=GameState.population_total
	# The water ledger kills 6 of thirst over the first weeks (consequence_engine.gd).
	for day in [20,25,30]:
		GameState.elapsed_days=float(day)
		GameState.register_population_deaths(2,"Dehydration")
		Crisis.dry_day(c)
	assert_int(int(c.thirst)).is_equal(6)
	assert_int(int(c.deaths)).is_equal(6)
	# The turn takes the dry year's own toll, by the share that drank.
	GameState.elapsed_days=45.0
	Crisis._due_deaths(c,0.4,"mid")
	var causes:=GameState.rolling_death_causes(365)
	assert_int(int(causes.get("Dehydration",0))).is_equal(6)
	assert_int(int(causes.get("Drought",0))).is_equal(int(c.toll_dead))
	assert_int(int(c.deaths)).is_equal(int(c.thirst)+int(c.toll_dead))
	# Every one of them once, and the people fewer by exactly that many.
	assert_int(before-GameState.population_total).is_equal(int(c.deaths))
	# Seen again the same day: nothing more.
	Crisis.dry_day(c)
	assert_int(int(c.deaths)).is_equal(int(c.thirst)+int(c.toll_dead))
	# The old-save re-read never moves a death the water ledger counted.
	(Crisis.state().flags as Dictionary).erase("drought_cause_v2")
	Crisis.reconcile_drought_causes(Crisis.state())
	causes=GameState.rolling_death_causes(365)
	assert_int(int(causes.get("Dehydration",0))).is_equal(6)

func test_every_people_meets_a_dry_year_by_the_same_rule()->void:
	# The silent official's answer for another people (crisis_unattended.gd):
	# carrying through the water ledger, not a death factor.
	var c:=_dry_year()
	Unattended._answer(Crisis.state(),c,"carry")
	assert_float(float(c.mult)).is_equal(1.0)
	assert_float(ConsequenceEngine.policy_effect("water_far")).is_equal_approx(DryWater.CARRY_REACH,0.0001)
	# Its planned share is the forecast, and its depth its draw's.
	var opened:={"id":"u1","type":"drought","start":0,"end_day":120,"sev":0.3,"pop0":100,"mult":1.0,"deaths":0,"phase":"open"}
	Crisis.plan_drought(opened,0.01)
	assert_float(float(opened.depth)).is_equal_approx(DryWater.depth(0.3,0.01),0.0001)
	assert_float(float(opened.m)).is_greater(0.0)
