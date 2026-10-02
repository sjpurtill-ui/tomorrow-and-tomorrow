extends GdUnitTestSuite
## Searching the land (resource_system.gd land_survey): the searched land
## rises with searchers and sags without them, cutters and diggers yield
## × (0.75 + 0.5 × cover), finds roll monthly at the stated odds from a seed
## and are told once, an older save blends into the new yield over a year,
## and a computer people follows the same rules.
const Chronicle:=preload("res://scripts/chronicle.gd")
const SEED:=60417

func before_test()->void:
	WorldSimulation.clear()
	_fresh(GameState)
	ResourceSystem.reset_for_new_world()
	ResourceSystem.forced_land_roll=-1.0

func after_test()->void:
	ResourceSystem.forced_land_roll=-1.0
	WorldSimulation.clear()

## A settled people of 120 with `searchers` at the search (the same set-up for
## any people's state).
func _fresh(state:Object,searchers:int=2)->void:
	state.reset_for_new_world(SEED)
	state.initialize_population_model()
	state.settlement_site_committed=true
	state.settlement_founded_day=0
	state.settlement_founded_at=Vector3.ZERO
	state.settlement_name="Stonebrook"
	state.elapsed_days=0
	state.population_exact=120.0
	state.population_total=120
	state.population_allocations={"Food":40,"Survey":searchers,"Extraction":10,"Construction":6,"Crafting":4,"Logistics":6,"Knowledge":2,"Administration":2,"Defense":2}
	state.simulation_metrics={"labor_efficiency":1.0}
	(state.resource_deposits as Array).clear()
	state.land_survey={}

func _context()->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO,"tools":0.25,"environment_profile":{"resource_potentials":{}}}

func _deposit(resource:String,at:Vector3,stage:String,index:int,quality:float=1.0)->Dictionary:
	var deposit:=ResourceSystem._deposit(resource,at,quality,5000.0,index)
	deposit.stage=stage
	if stage!="unknown":deposit.clues=1.0
	if stage in ["surveyed","accessible","developed"]:deposit.survey=1.0
	if stage in ["accessible","developed"]:deposit.access=1.0
	return deposit

## Steps the land day by day from `from` to `to` (inclusive).
func _days(from:int,to:int,context:Dictionary=_context())->void:
	for day in range(from,to+1):
		GameState.elapsed_days=day
		ResourceSystem._advance_land(context)


# --- Cover ---------------------------------------------------------------------------------

func test_one_searcher_for_sixty_people_holds_the_land_near_six_tenths()->void:
	assert_float(ResourceSystem.land_target(2.0,120.0)).is_equal_approx(0.6,0.0001)
	assert_float(ResourceSystem.land_target(0.0,120.0)).is_equal(0.0)
	# Over a few years it nears 0.6, and holds there.
	assert_float(ResourceSystem.land_step(0.0,2.0,120.0,365.0*3.0)).is_between(0.48,0.6)
	assert_float(ResourceSystem.land_step(0.0,2.0,120.0,365.0*5.0)).is_between(0.55,0.6)
	assert_float(ResourceSystem.land_step(0.6,2.0,120.0,365.0*20.0)).is_equal_approx(0.6,0.0001)
	# More searchers search more of it, never past all of it.
	assert_float(ResourceSystem.land_target(12.0,120.0)).is_greater(ResourceSystem.land_target(2.0,120.0))
	assert_float(ResourceSystem.land_step(0.0,120.0,120.0,365.0*50.0)).is_less_equal(1.0)

func test_cover_rises_with_searchers_day_by_day_and_sags_without_them()->void:
	_days(0,0)
	assert_float(float(GameState.land_survey.cover)).is_equal(0.0)
	var searchers:=GameState.effective_workers("Survey")
	assert_float(searchers).is_greater(0.0)
	_days(1,365*3)
	var cover:=float(GameState.land_survey.cover)
	# Day by day it follows the one rule (the closed form over the same days).
	assert_float(cover).is_equal_approx(ResourceSystem.land_step(0.0,searchers,120.0,365.0*3.0),0.0005)
	assert_float(cover).is_greater(0.3)
	# Nobody searching: it sags 5 in 100 a year.
	GameState.population_allocations.Survey=0
	_days(365*3+1,365*4)
	assert_float(float(GameState.land_survey.cover)).is_equal_approx(cover*0.95,0.0005)
	_days(365*4+1,365*5)
	assert_float(float(GameState.land_survey.cover)).is_equal_approx(cover*0.95*0.95,0.0005)

func test_a_people_on_the_road_searches_no_land()->void:
	GameState.settlement_site_committed=false
	GameState.elapsed_days=40
	ResourceSystem._advance_land({"settled":false})
	assert_bool(GameState.land_survey.has("cover")).is_false()
	assert_float(ResourceSystem.land_yield_factor()).is_equal(1.0)


# --- Cutting and digging ---------------------------------------------------------------------

func test_extraction_yield_follows_the_searched_land()->void:
	assert_float(ResourceSystem.land_yield(0.0)).is_equal(0.75)
	assert_float(ResourceSystem.land_yield(0.6)).is_equal_approx(1.05,0.000001)
	assert_float(ResourceSystem.land_yield(1.0)).is_equal(1.25)
	var clay:=_deposit("Clay",Vector3(2,0,0),"accessible",0)
	GameState.resource_deposits=[clay]
	GameState.resource_stockpiles={"Clay":0.0}
	var yields:Dictionary={}
	for cover:float in [0.0,0.6,1.0]:
		GameState.resource_practice={}
		GameState.land_survey={"cover":cover,"day":0,"find_month":0,"blend_from":-1,"finds":[],"last_roll":{}}
		ResourceSystem._process_material_flow(_context())
		yields[cover]=float(clay.daily_yield)
		assert_float(float(GameState.material_metrics.land_factor)).is_equal_approx(ResourceSystem.land_yield(cover),0.000001)
		# What one cutter brings in a day (the People view's "ten more").
		var cutters:=GameState.effective_workers("Extraction")
		assert_float(float(GameState.material_metrics.per_cutter)*cutters).is_equal_approx(float(clay.daily_yield),0.0001)
	assert_float(float(yields[0.0])).is_greater(0.0)
	assert_float(float(yields[0.6])/float(yields[0.0])).is_equal_approx(1.05/0.75,0.0001)
	assert_float(float(yields[1.0])/float(yields[0.0])).is_equal_approx(1.25/0.75,0.0001)


# --- Finds ---------------------------------------------------------------------------------

func test_find_odds_are_stated_and_the_roll_is_seeded()->void:
	assert_float(ResourceSystem.land_find_odds(10.0)).is_equal_approx(1.0-exp(-0.16),0.000001)
	assert_float(ResourceSystem.land_find_odds(0.0)).is_equal(0.0)
	assert_str(ResourceSystem.odds_words(ResourceSystem.land_find_odds(10.0))).is_equal("about 1 chance in 7")
	GameState.population_allocations.Survey=6
	_days(0,0)
	_days(30,30)
	var roll:Dictionary=GameState.land_survey.last_roll
	assert_float(float(roll.p)).is_equal_approx(ResourceSystem.land_find_odds(),0.000001)
	assert_float(float(roll.roll)).is_equal(ResourceSystem._land_rng(1).randf())
	# The same land and month roll the same, whoever reads it and however often.
	var again:Dictionary=roll.duplicate(true)
	_fresh(GameState,6)
	_days(0,0)
	_days(30,30)
	assert_dict(GameState.land_survey.last_roll).is_equal(again)
	# Over many months the seeded rolls come up as often as the stated odds say.
	var p:=ResourceSystem.land_find_odds(10.0)
	var hits:=0
	for month in range(1,3001):
		if ResourceSystem._land_rng(month).randf()<p:hits+=1
	assert_float(float(hits)/3000.0).is_equal_approx(p,0.02)

func test_a_find_measures_a_deposit_of_the_land_and_is_told_once()->void:
	var clay:=_deposit("Clay",Vector3(3,0,4),"unknown",0)
	GameState.resource_deposits=[clay]
	_days(0,0)
	ResourceSystem.forced_land_roll=0.0
	_days(1,45)
	assert_str(String(clay.stage)).is_equal("surveyed")
	var finds:Array=GameState.land_survey.finds
	assert_int(finds.size()).is_equal(1)
	assert_str(String(finds[0].kind)).is_equal("new")
	assert_str(String(finds[0].deposit_id)).is_equal(String(clay.id))
	assert_float(float(finds[0].km)).is_equal_approx(5.0,0.01)
	assert_bool(bool(finds[0].told)).is_true()
	var key:="land_find::30:%s" % String(clay.id)
	assert_bool((Chronicle.data().keys as Dictionary).has(key)).is_true()
	var told:=0
	for entry:Dictionary in Chronicle.data().entries:
		if String(entry.get("key",""))==key:
			told+=1
			assert_str(String(entry.text)).contains("Searchers found clay about 5 km")
	assert_int(told).is_equal(1)
	# The same month never rolls again.
	_days(46,59)
	assert_int((GameState.land_survey.finds as Array).size()).is_equal(1)

func test_with_nothing_hidden_a_find_is_a_richer_part_of_a_worked_deposit_at_most_twice()->void:
	var stone:=_deposit("Clay",Vector3(1,0,0),"accessible",0,1.0)
	GameState.resource_deposits=[stone]
	_days(0,0)
	ResourceSystem.forced_land_roll=0.0
	_days(1,30)
	assert_float(float(stone.quality)).is_equal_approx(1.1,0.000001)
	assert_str(String(GameState.land_survey.finds[0].kind)).is_equal("richer")
	_days(31,60)
	assert_float(float(stone.quality)).is_equal_approx(1.21,0.000001)
	_days(61,90)
	assert_float(float(stone.quality)).is_equal_approx(1.21,0.000001)
	assert_str(String(GameState.land_survey.last_roll.found)).is_equal("nothing new")
	assert_int((GameState.land_survey.finds as Array).size()).is_equal(2)

func test_new_ground_uses_the_expedition_registration()->void:
	GameState.resource_deposits=[]
	_days(0,0)
	ResourceSystem.forced_land_roll=0.0
	var context:=_context()
	context.environment_profile={"resource_potentials":{"Clay":0.9}}
	_days(1,30,context)
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	var found:Dictionary=GameState.resource_deposits[0]
	assert_str(String(found.resource)).is_equal("Clay")
	assert_str(String(found.stage)).is_equal("surveyed")
	assert_str(String(found.get("found_by",""))).is_equal("searchers")
	assert_float(ResourceSystem._land_km(found,Vector3.ZERO)).is_between(4.0,20.0)


# --- Older saves -------------------------------------------------------------------------------

func test_an_older_save_starts_from_its_survey_history_and_blends_over_a_year()->void:
	var deposits:Array[Dictionary]=[]
	for index in 4:deposits.append(_deposit("Clay" if index%2==0 else "Flint",Vector3(index+1,0,0),"surveyed",index))
	deposits.append(_deposit("Clay",Vector3(9,0,0),"unknown",4))
	GameState.resource_deposits=deposits
	GameState.elapsed_days=400
	# No jump on load: the old rule's yield on the first day.
	assert_float(ResourceSystem.land_yield_factor()).is_equal(1.0)
	var land:Dictionary=GameState.land_survey
	assert_float(float(land.cover)).is_equal_approx(0.8,0.000001)
	assert_int(int(land.blend_from)).is_equal(400)
	GameState.elapsed_days=400+73
	assert_float(ResourceSystem.land_yield_factor()).is_equal_approx(1.0+0.15*73.0/365.0,0.000001)
	GameState.elapsed_days=765
	assert_float(ResourceSystem.land_yield_factor()).is_equal_approx(1.15,0.000001)
	ResourceSystem._advance_land(_context())
	assert_int(int(GameState.land_survey.blend_from)).is_equal(-1)

func test_a_new_people_starts_from_what_its_founders_saw_at_once()->void:
	GameState.resource_deposits=[_deposit("Clay",Vector3(1,0,0),"recognized",0),_deposit("Flint",Vector3(2,0,0),"unknown",1)]
	GameState.elapsed_days=5
	assert_float(ResourceSystem.land_yield_factor()).is_equal_approx(ResourceSystem.land_yield(0.25),0.000001)
	assert_int(int(GameState.land_survey.blend_from)).is_equal(-1)


# --- Every people, every town ---------------------------------------------------------------------

func test_a_computer_people_follows_the_same_rules()->void:
	var setup:=func()->void:
		_fresh(WorldSimulation.state,30)
		(WorldSimulation.state.resource_deposits as Array).assign([_deposit("Clay",Vector3(3,0,0),"unknown",0),_deposit("Flint",Vector3(0,0,6),"unknown",1),_deposit("Clay",Vector3(1,0,0),"accessible",2)])
	var run:=func()->void:
		for day in range(0,400):
			WorldSimulation.state.elapsed_days=day
			WorldSimulation.resources._advance_land(_context())
	# The god's people first: a fresh start of theirs clears the world's peoples.
	setup.call()
	run.call()
	WorldSimulation.create_actor("alpha",SEED,Vector2.ZERO)
	WorldSimulation.scoped("alpha",func()->void:
		setup.call()
		run.call()
	)
	var ours:Dictionary=GameState.land_survey.duplicate(true)
	var theirs:Dictionary=WorldSimulation.actors.alpha.systems.GameState.land_survey.duplicate(true)
	assert_int((ours.finds as Array).size()).is_greater(0)
	# Only the god's own people are told; the rest is the same, roll for roll.
	for land:Dictionary in [ours,theirs]:
		for find:Dictionary in land.finds:find.erase("told")
	assert_dict(theirs).is_equal(ours)
	var stages:=func(deposits:Array)->Array:return deposits.map(func(d:Dictionary)->Array:return [String(d.stage),float(d.quality)])
	assert_array(stages.call(WorldSimulation.actors.alpha.systems.GameState.resource_deposits)).is_equal(stages.call(GameState.resource_deposits))
	for find:Dictionary in WorldSimulation.actors.alpha.systems.GameState.land_survey.finds:
		assert_bool(bool(find.told)).is_false()

func test_each_town_keeps_its_own_searched_land()->void:
	SettlementModel.reset_for_new_world()
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	_days(0,0)
	GameState.land_survey.cover=0.5
	SettlementModel.with_city_resources("dawngate",func()->void:
		GameState.elapsed_days=0
		ResourceSystem._advance_land(_context())
		assert_float(float(GameState.land_survey.cover)).is_equal(0.0)
		GameState.land_survey.cover=0.2
	)
	assert_float(float(GameState.land_survey.cover)).is_equal(0.5)
	SettlementModel.with_city_resources("dawngate",func()->void:
		assert_float(float(GameState.land_survey.cover)).is_equal(0.2)
	)


# --- What the screens and the People view read ----------------------------------------------------

func test_role_effects_say_what_the_work_does_now_and_ten_more()->void:
	_days(0,0)
	var survey:=ResourceSystem.role_effect("Survey")
	assert_str(String(survey.now)).contains("searching")
	assert_str(String(survey.plus_ten)).starts_with("Ten more searching")
	var numbers:Dictionary=survey.numbers
	assert_float(float(numbers.plus_ten.target)).is_greater(float(numbers.target))
	assert_float(float(numbers.plus_ten.find_month)).is_greater(float(numbers.find_month))
	var clay:=_deposit("Clay",Vector3(2,0,0),"accessible",0)
	GameState.resource_deposits=[clay]
	ResourceSystem._process_material_flow(_context())
	var cutting:=ResourceSystem.role_effect("Extraction")
	assert_float(float(cutting.numbers.plus_ten_loads)).is_equal_approx(float(GameState.material_metrics.per_cutter)*10.0,0.000001)
	assert_str(String(cutting.plus_ten)).starts_with("Ten more would bring in about")
	assert_dict(ResourceSystem.role_effect("Food")).is_empty()
	assert_str(ResourceSystem.land_words()).contains("Searched land 0 in 100")

func test_the_materials_page_shows_the_searched_land()->void:
	_days(0,0)
	var words:=ResourceSystem.land_words()
	assert_str(words).contains("Cutting and digging ×0.75").contains("A find this month: %s." % ResourceSystem.odds_words(ResourceSystem.land_find_odds()))
	var page:VBoxContainer=auto_free(preload("res://scripts/hud/materials_ledger.gd").new())
	page.setup({"city":"Stonebrook","leader":{},"managed":true,"can_direct":false,"focus":"","storage":10.0,"capacity":100.0,"hauling":0.9,"land":words,
		"rows":[],"incoming":[],"day":0,"selected":"","on_select":func(_k:String):pass,"on_map":func():pass,"on_focus":func(_f:String):pass,"on_trade":func():pass})
	var label:Label=page.find_child("SearchedLand",true,false)
	assert_object(label).is_not_null()
	assert_str(label.text).is_equal(words)
