extends GdUnitTestSuite
## Fresh food, small stores, keepers and carers (docs/PEOPLE_FIRST.md B,
## scripts/food_care.gd): food security counts a lean buffer of twenty days;
## deaths and sickness read what is eaten, never the size of the store; the
## fresh share of what is eaten leans health; carriers cut fresh spoilage and
## widen the daily harvest; keepers cut stored spoilage; carers tend newborns,
## the sick and mothers within the pre-modern benchmarks.

const FoodCare:=preload("res://scripts/food_care.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const GAME_STATE_SCRIPT:=preload("res://scripts/game_state.gd")

class FakeDiscovery extends Node:
	var effects:Dictionary={}
	func adoption(_id:String)->float:return 1.0
	func effect(id:String)->float:return float(effects.get(id,0.0))
	func discovery_definition(id:String)->Dictionary:return {"id":id,"name":id.capitalize()}

var _processing:Dictionary={}

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(5151);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	# No soldiers called up from an earlier suite: every hand works its task.
	FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(100);GameState.housing_capacity=120
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.elapsed_days=400
	# A world begun under today's rules (an older save blends in: see below).
	GameState.early_care_blend=1.0
	FoodSystem._lever_cache.clear()
	FoodSystem.initialize()
	# Room for any store these tests keep.
	GameState.founding_manifest["food_storage_rations"]=100000.0

func after_test()->void:
	FoodSystem._lever_cache.clear()
	FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(5151)
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

## Everyone drinks enough: these tests are about food.
func _water()->void:
	GameState.water_metrics={"intake_ratio":1.0,"days":3.0,"required_today":100.0,"collected_today":100.0,"source_distance_km":0.2}

## The share of those who can work on `role`, in 100 (allocations follow it).
func _work(role:String,share:float)->void:
	GameState.population_allocation_percentages[role]=share
	GameState.synchronize_population_allocations()

func _need()->float:
	return float(FoodSystem._calculate_demand(false).total)

## Stores of `days` of need, all of it put by (stored food).
func _store(days:float)->void:
	GameState.food_stocks={FoodSystem.FRESH:float(GameState.food_stocks.get(FoodSystem.FRESH,0.0)),FoodSystem.STORED:_need()*days}
	FoodSystem._sync_total()

## The food security target before this change (45 days of store counted).
static func _old_security(food_days:float,production_ratio:float,intake:float,diet:float,reserve:float,malnutrition:float)->float:
	return clampf(0.05+minf(1.0,food_days/45.0)*0.30+minf(1.15,production_ratio)*0.25+intake*0.18+diet*0.12+reserve*0.10-malnutrition*0.24,0.02,0.98)


# --- Small stores ------------------------------------------------------------------------

func test_food_security_counts_a_lean_buffer_of_twenty_days()->void:
	var at:={}
	for days:float in [5.0,10.0,20.0,45.0,200.0]:
		at[days]=FoodCare.security_targets(days,1.0,1.0,0.62,0.9,0.0)
		print("food security target at %d days: before %.3f, now %.3f (what is eaten %.3f)" % [days,_old_security(days,1.0,1.0,0.62,0.9,0.0),float(at[days].security),float(at[days].fed)])
	# Twenty days carry the people through a lean spell; more adds nothing.
	assert_float(float(at[20.0].lean)).is_equal(1.0)
	assert_float(float(at[20.0].security)).is_equal_approx(float(at[45.0].security),0.000001)
	assert_float(float(at[20.0].security)).is_equal_approx(float(at[200.0].security),0.000001)
	assert_float(float(at[20.0].security)).is_greater(0.9)
	# A thin store is a thin buffer, half at ten days...
	assert_float(float(at[10.0].lean)).is_equal_approx(0.5,0.000001)
	assert_float(float(at[10.0].security)).is_equal_approx(float(at[20.0].security)-FoodCare.LEAN_WEIGHT*0.5,0.000001)
	# ...but what is eaten, which deaths and sickness read, never counts the store.
	for days:float in [5.0,10.0,45.0,200.0]:
		assert_float(float(at[days].fed)).is_equal_approx(float(at[20.0].fed),0.000001)

func test_the_levy_leaves_every_town_its_lean_buffer()->void:
	assert_float(Purse.LEVY_KEEP_DAYS).is_equal(FoodCare.LEAN_DAYS)
	assert_float(FoodCare.LEAN_DAYS).is_equal(20.0)
	# Relief never lifts a town past what the levy leaves it, so the levy
	# never takes relief back, and no seller is left hungry.
	assert_float(Purse.HUNGRY_DAYS).is_less(Purse.RELIEF_TARGET)
	assert_float(Purse.RELIEF_TARGET).is_less_equal(Purse.LEVY_KEEP_DAYS)
	assert_float(Purse.LEVY_KEEP_DAYS).is_less(Purse.SELLER_KEEP)
	assert_float(Purse.SELLER_KEEP).is_less(Purse.SELLER_DAYS)
	# The planners aim a little past the buffer, for the season.
	assert_float(GovernmentPeopleSystem.RESERVE_TARGET_DAYS).is_equal_approx(FoodCare.LEAN_DAYS*1.5,0.0001)

## Every reading of "days in store" counts the lean stores: the rulers' gates,
## standing, feasts and the court's words ask store_gate of the old days, so
## envy raids, feasts and great works still come to a people with normal stores.
func test_store_readings_count_the_lean_stores()->void:
	var Standing:=preload("res://scripts/standing.gd")
	assert_float(Standing.WEALTH_FOOD_DAYS).is_equal_approx(FoodCare.store_gate(90.0),0.0001)
	assert_float(Standing.ENDURANCE_FOOD_DAYS).is_equal_approx(FoodCare.store_gate(120.0),0.0001)
	assert_float(preload("res://scripts/economy_system.gd").FEAST_FOOD_DAYS).is_equal_approx(FoodCare.store_gate(60.0),0.0001)
	assert_float(preload("res://scripts/civilization_strategy.gd").GOODWILL_FOOD_DAYS).is_equal_approx(FoodCare.store_gate(90.0),0.0001)
	assert_float(preload("res://scripts/civilization_controller.gd").DEFENSE_FOOD_DAYS).is_equal_approx(FoodCare.store_gate(30.0),0.0001)
	# The planners' usual stores read as ample, not lean; under the buffer, lean.
	var Context:=preload("res://scripts/interaction_context.gd")
	assert_str(Context.food_band(GovernmentPeopleSystem.RESERVE_TARGET_DAYS)).is_equal("ample")
	assert_str(Context.food_band(FoodCare.LEAN_DAYS-1.0)).is_equal("lean")
	assert_str(Context.food_band(3.0)).is_equal("scarce")
	# The Food page's words match the plan: 1.02 - 0.15 x how far past the reserve.
	GameState.simulation_metrics={"food_consumption":100.0,"food_days":GovernmentPeopleSystem.RESERVE_TARGET_DAYS*1.5}
	var plan:=GovernmentPeopleSystem.reserve_plan()
	var over:=float(plan.over)
	assert_float(float(plan.draw)).is_equal_approx(maxf(0.0,GovernmentPeopleSystem.RESERVE_MARGIN*over-0.02),0.000001)
	assert_float(1.0-float(plan.draw)).is_equal_approx(1.02-GovernmentPeopleSystem.RESERVE_MARGIN*over,0.000001)

## A village of 100 with twenty days in store and fresh food coming in each
## day thrives: full food security, and no more deaths than with 45 or 200.
func test_a_village_of_100_with_twenty_days_and_fresh_food_thrives()->void:
	var runs:={}
	for days:float in [20.0,45.0,200.0]:
		before_test()
		# Fresh food coming in: enough getters that the day's harvest covers the
		# need (about 6 in 10 at the founding yields, the age's usual share).
		_work("Food",60.0)
		var deaths:=0.0
		for day in 60:
			GameState.elapsed_days=400+day
			_store(days)
			_water()
			ConsequenceEngine.process_day({"traveling":false})
			deaths+=float(GameState.simulation_metrics.get("annual_death_rate",0.0))
		var m:Dictionary=GameState.simulation_metrics
		runs[days]={"security":GameState.food_security,"fed":float(m.food_fed_security),"health":GameState.population_health,"deaths":deaths/60.0,
			"fresh":float(m.get("food_fresh_share",0.0)),"intake":float(m.get("food_intake_ratio",0.0)),"lean":float(m.food_lean_buffer),
			"days":float(m.get("food_days",0.0)),"capacity":FoodSystem._food_storage_capacity(),"people":GameState.population_exact}
		print("village of 100 with %d days in store: %s" % [days,str(runs[days])])
	var lean:Dictionary=runs[20.0]
	assert_float(float(lean.intake)).is_equal(1.0)
	assert_float(float(lean.fresh)).is_greater(0.5)
	assert_float(float(lean.lean)).is_equal(1.0)
	assert_float(float(lean.security)).is_greater(0.85)
	for days:float in [45.0,200.0]:
		var big:Dictionary=runs[days]
		assert_float(float(lean.security)).is_equal_approx(float(big.security),0.002)
		assert_float(float(lean.health)).is_equal_approx(float(big.health),0.002)
		assert_float(float(lean.deaths)).is_equal_approx(float(big.deaths),0.0005)


# --- Fresh against stored ---------------------------------------------------------------

func test_fresh_share_leans_health()->void:
	assert_float(FoodCare.fresh_health(0.5)).is_equal(0.0)
	assert_float(FoodCare.fresh_health(1.0)).is_equal_approx(0.06,0.000001)
	# A town living on its grain loses a little, never much.
	assert_float(FoodCare.fresh_health(0.0)).is_equal_approx(-0.02,0.000001)
	print("health from the fresh share: 0.0 -> %+.3f, 0.3 -> %+.3f, 0.7 -> %+.3f, 1.0 -> %+.3f" % [FoodCare.fresh_health(0.0),FoodCare.fresh_health(0.3),FoodCare.fresh_health(0.7),FoodCare.fresh_health(1.0)])
	assert_float(FoodCare.fresh_health(0.7)).is_greater(FoodCare.fresh_health(0.3))
	# In the engine: the same people, one living on fresh food, one on stores.
	var health:={}
	for fresh:bool in [true,false]:
		before_test()
		_work("Food",0.0)
		_water()
		var need:=_need()
		GameState.food_stocks={FoodSystem.FRESH:need*1.2 if fresh else 0.0,FoodSystem.STORED:need*(20.0 if fresh else 21.2)}
		FoodSystem._sync_total()
		GameState.population_health=0.7
		ConsequenceEngine.process_day({"traveling":false})
		var m:Dictionary=GameState.simulation_metrics
		assert_float(float(m.fresh_health)).is_equal_approx(FoodCare.fresh_health(float(m.food_fresh_share)),0.000001)
		health[fresh]=GameState.population_health
	assert_float(float(health[true])).is_greater(float(health[false]))


# --- Carriers ------------------------------------------------------------------------------

func test_carriers_cut_fresh_spoilage_and_widen_the_daily_harvest()->void:
	GameState.population_allocations.Logistics=0
	var bare:=FoodSystem._spoilage_rates(false)
	var bare_ground:=float((FoodSystem.wild_food_capacity()["Wild gathering"] as Dictionary).rations)
	# Three in 100 of the people carrying: full cover.
	GameState.population_allocations.Logistics=3
	var cover:=FoodCare.carry_cover_of(GameState)
	assert_float(cover).is_greater(0.9)
	var carried:=FoodSystem._spoilage_rates(false)
	assert_float(float(carried[0])).is_equal_approx(float(bare[0])*FoodCare.fresh_spoilage_factor(cover),0.0000001)
	assert_float(float(carried[0])).is_less(float(bare[0])*0.56)
	# Carriers do not keep the stored grain.
	assert_float(float(carried[1])).is_equal_approx(float(bare[1]),0.0000001)
	var ground:=float((FoodSystem.wild_food_capacity()["Wild gathering"] as Dictionary).rations)
	assert_float(ground).is_equal_approx(bare_ground*FoodCare.reach_factor(cover),0.0001)
	assert_float(ground).is_greater(bare_ground*1.2)
	# The day's spoilage of a fresh pool falls with it.
	GameState.food_stocks={FoodSystem.FRESH:1000.0,FoodSystem.STORED:0.0}
	var with_carriers:=float(FoodSystem._spoil(false)[FoodSystem.FRESH])
	GameState.population_allocations.Logistics=0
	GameState.food_stocks={FoodSystem.FRESH:1000.0,FoodSystem.STORED:0.0}
	var without:=float(FoodSystem._spoil(false)[FoodSystem.FRESH])
	assert_float(with_carriers).is_less(without*0.56)


# --- Keepers and carers -------------------------------------------------------------------

func test_keepers_cut_stored_spoilage()->void:
	GameState.population_allocations.Administration=0
	var bare:=FoodSystem._spoilage_rates(false)
	GameState.population_allocations.Administration=2
	var cover:=FoodCare.keep_cover_of(GameState)
	assert_float(cover).is_greater(0.9)
	var kept:=FoodSystem._spoilage_rates(false)
	assert_float(float(kept[1])).is_equal_approx(float(bare[1])*FoodCare.stored_spoilage_factor(cover),0.0000001)
	assert_float(float(kept[1])).is_less(float(bare[1])*0.65)
	assert_float(float(kept[0])).is_equal_approx(float(bare[0]),0.0000001)
	# On the road there is no store to keep.
	assert_float(float(FoodSystem._spoilage_rates(true)[1])).is_greater(float(kept[1]))

## Infant deaths in 1,000 with carers' cover `cover` on `state`.
func _infants(state:Node,discovery:Node,cover:float)->float:
	state.early_care=EarlyCare.profile(state,discovery,{"carer_cover":cover})
	return Indicators.infant_mortality_per_1000(state,discovery)

func test_carers_lower_infant_deaths_a_little_extra_at_full_commitment()->void:
	# The founders as a new world begins them, and a people with every early
	# practice in full use, well fed and well; carers on 0, 2, 4 and 8 in 100
	# of the people (8 is full cover).
	var founders:Node=auto_free(GAME_STATE_SCRIPT.new())
	founders.reset_for_new_world(5150)
	founders.initialize_population_model()
	founders.population_health=0.85;founders.food_security=0.9;founders.housing_capacity=150;founders.early_care_blend=1.0
	for day in 120:founders.food_history.append({"day":day,"diet_quality":0.66})
	var plain:FakeDiscovery=auto_free(FakeDiscovery.new())
	var careful:Node=auto_free(GAME_STATE_SCRIPT.new())
	careful.reset_for_new_world(5150)
	careful.initialize_population_model()
	careful.population_health=0.97;careful.food_security=0.98;careful.housing_capacity=150;careful.early_care_blend=1.0
	for day in 120:careful.food_history.append({"day":day,"diet_quality":0.85})
	for category:Dictionary in EarlyCare.CATEGORIES:
		for id:String in category.practices:
			if id not in careful.known_discoveries:careful.known_discoveries.append(id)
	var shares:=[0.0,0.02,0.04,0.08]
	for people:Node in [founders,careful]:
		var imr:Array[float]=[]
		for share:float in shares:
			imr.append(_infants(people,plain,FoodCare.care_cover(share*100.0,100.0)))
		print("%s: infant deaths in 1,000 with carers on 0/2/4/8 in 100: %.0f / %.0f / %.0f / %.0f" % ["no early practices" if people==founders else "every early practice, well fed",imr[0],imr[1],imr[2],imr[3]])
		# More carers, fewer babies lost, and the usual 4 in 100 give about half.
		for index in range(1,imr.size()):assert_float(imr[index]).is_less(imr[index-1])
		assert_float(FoodCare.care_cover(4.0,100.0)).is_equal_approx(0.5,0.000001)
		# Even full care without modern medicine loses well over 100 in 1,000:
		# a little ahead of the best documented pre-modern figures, never wild.
		assert_float(imr[3]).is_greater(110.0)
	assert_float(_infants(founders,plain,1.0)).is_less(_infants(founders,plain,0.0)-40.0)

func test_care_is_learned_over_months_and_new_worlds_begin_with_it()->void:
	var plain:FakeDiscovery=auto_free(FakeDiscovery.new())
	var people:Node=auto_free(GAME_STATE_SCRIPT.new())
	people.reset_for_new_world(5150)
	people.initialize_population_model()
	people.early_care_blend=1.0
	people.elapsed_days=4000.0
	people.early_care={}
	# An older save: no carers kept yet; it starts from none, not at once.
	var care:=EarlyCare.refresh(people,plain,{"carer_cover":1.0})
	assert_float(float(care.carer_cover)).is_less(0.05)
	assert_float(float(care.carer_cover_target)).is_equal(1.0)
	for day in 59:care=EarlyCare.refresh(people,plain,{"carer_cover":1.0})
	assert_float(float(care.carer_cover)).is_between(0.55,0.70)
	# A world in its first month begins with its carers at work.
	var fresh:Node=auto_free(GAME_STATE_SCRIPT.new())
	fresh.reset_for_new_world(5150)
	fresh.initialize_population_model()
	fresh.elapsed_days=2.0
	fresh.early_care={}
	assert_float(float(EarlyCare.refresh(fresh,plain,{"carer_cover":0.8}).carer_cover)).is_equal_approx(0.8,0.000001)

func test_carers_cover_only_their_categories()->void:
	var plain:FakeDiscovery=auto_free(FakeDiscovery.new())
	var people:Node=auto_free(GAME_STATE_SCRIPT.new())
	people.reset_for_new_world(5150)
	people.initialize_population_model()
	people.early_care_blend=1.0
	var care:=EarlyCare.profile(people,plain,{"carer_cover":1.0})
	for category:Dictionary in care.categories:
		var expected:=float(EarlyCare.CARER_COVER.get(String(category.id),0.0))
		assert_float(float(category.carers)).is_equal_approx(expected,0.000001)
	var none:=EarlyCare.profile(people,plain,{"carer_cover":0.0})
	assert_float(float(care.under5)).is_less(float(none.under5))
	assert_float(float(care.maternal)).is_less(float(none.maternal))
	assert_float(float(care.neonatal)).is_less(float(none.neonatal))


# --- Older saves --------------------------------------------------------------------------

func test_an_older_save_loads_without_a_jump()->void:
	_work("Food",50.0)
	_store(30.0)
	_water()
	# What an older save holds: no fed security, no carers yet, lower security.
	GameState.simulation_metrics.erase("food_fed_security")
	GameState.early_care={}
	GameState.early_care_blend=1.0
	GameState.food_security=0.6;GameState.population_health=0.7
	ConsequenceEngine.process_day({"traveling":false})
	var m:Dictionary=GameState.simulation_metrics
	assert_float(float(m.food_fed_security)).is_less(0.65)
	assert_float(GameState.food_security).is_less(0.65)
	assert_float(float(GameState.early_care.carer_cover)).is_less(0.05)


# --- What each role does (the People view) ---------------------------------------------

func test_role_effects_say_what_ten_more_would_do()->void:
	_work("Food",50.0);_work("Logistics",1.0);_work("Administration",1.0)
	_store(20.0)
	for day in 3:
		GameState.elapsed_days=400+day
		_water()
		ConsequenceEngine.process_day({"traveling":false})
	for role:String in ["Food","Logistics","Administration"]:
		var effect:=FoodCare.role_effect(role)
		assert_str(String(effect.role)).is_equal(role)
		assert_bool((effect.lines as Array).is_empty()).is_false()
		for line:Dictionary in effect.lines:
			for key:String in ["label","value","words","tone"]:assert_bool(line.has(key)).is_true()
			assert_str(String(line.words)).not_contains("%")
			print("%s | %s | %s | %s" % [role,String(line.label),String(line.value),String(line.words)])
	assert_dict(FoodCare.role_effect("Defense")).is_empty()
	var carrying:=FoodCare.role_effect("Logistics")
	assert_float(float(carrying.more.carry_cover)).is_greater(float(carrying.now.carry_cover))
	var keeping:=FoodCare.role_effect("Administration")
	assert_float(float(keeping.more.keep_cover)).is_greater_equal(float(keeping.now.keep_cover))
	assert_float(float(keeping.more.infant_deaths_per_1000)).is_less(float(keeping.now.infant_deaths_per_1000))
	var getting:=FoodCare.role_effect("Food")
	assert_float(float(getting.more.fresh_rations)).is_greater(float(getting.now.fresh_rations))
