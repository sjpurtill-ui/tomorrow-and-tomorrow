extends GdUnitTestSuite
## THE BUSINESS SECTOR (scripts/enterprise.gd, docs/BUSINESS_ARC.md stage 1):
## the ladder from household crafts to corporations, its size, what it does
## to work, goods, trade and wealth, the god's stance, booms and busts at
## stated odds, the court's words, computer rulers and saves. Offline; never
## calls a real API. The world is the court evaluation's base (Seanstone, 900
## people, the Headman Kishan), built through the real engine.

const Business:=preload("res://scripts/enterprise.gd")
const BusinessOrders:=preload("res://scripts/court_business_orders.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Board:=preload("res://scripts/hud/purse_board.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

var fx:Fixtures


func before_test()->void:
	fx=Fixtures.new(self)
	fx.base(false)
	GameState.realm_purse={}
	GameState.enterprise={}
	# The month's roll never comes up a bust unless a test asks for one.
	Business.forced_roll=1.0


func after_test()->void:
	Business.forced_roll=-1.0
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()


## Knowledge held at an adoption.
func _know(id:String,adoption:float=1.0)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption

func _forget(id:String)->void:
	GameState.known_discoveries.erase(id)
	GameState.discovery_adoption.erase(id)

## Money and markets: the stage, prices kept, market access, credit.
func _money(stage:String,market:float=0.6,credit_limit:float=0.0,used:float=0.0)->void:
	GameState.economy_stage=stage
	var m:Dictionary=GameState.economy_metrics
	m["price_observations"]=12
	m["market_access"]=market
	m["credit_limit"]=credit_limit
	m["credit_utilization"]=used
	GameState.economy_metrics=m

## The sector at a rung (knowledge and money to match).
func _at_rung(r:int)->void:
	_money("currency" if r>=3 else "weighed_metal")
	if r>=2:_know("craft_guilds")
	if r>=3:_know("bills_of_exchange")
	if r>=4:_know("joint_stock_company")
	if r>=5:_know("limited_liability_registration")

## Sets the record's share (and stance) and refreshes the cached factor.
func _size(share:float,stance:String="")->Dictionary:
	var e:=Business.state()
	e.share=share
	if stance!="":
		e.stance=stance
		e.chosen=true
	Business._refresh(e)
	return e

func _stock_food(days:float,need:float=900.0)->void:
	GameState.simulation_metrics["food_consumption"]=need
	GameState.food_stocks={"Fresh food":0.0,"Stored food":need*days}
	GameState.resource_stockpiles["Food"]=need*days

func _form(variant:String)->void:
	var values:Dictionary=GameState.societal_values
	if not values.get("institutions") is Dictionary:values["institutions"]={}
	(values.institutions as Dictionary)["craft_guilds"]={"variant":variant,"adoption":0.5,"discovered_day":0,"last_reformed_day":0,"source_discovery":"craft_guilds"}


# --- 1. The ladder ------------------------------------------------------------------

func test_rungs_need_knowledge_and_money()->void:
	GameState.economy_stage="subsistence"
	assert_int(Business.rung()).override_failure_message("no business before weighed metal or coin").is_equal(0)
	_money("weighed_metal")
	GameState.economy_metrics["price_observations"]=0
	assert_int(Business.rung()).override_failure_message("prices must be kept").is_equal(0)
	GameState.economy_metrics["price_observations"]=3
	assert_int(Business.rung()).is_equal(1)
	assert_str(Business.rung_name(1)).is_equal("Stalls and hired workshops")
	# Knowledge counts at a quarter adopted, as elsewhere.
	_know("licensed_guilds",0.2)
	assert_int(Business.rung()).is_equal(1)
	_know("licensed_guilds",0.3)
	assert_int(Business.rung()).is_equal(2)
	# Banking knowledge waits on coin.
	_know("voyage_partnerships")
	assert_int(Business.rung()).override_failure_message("banking houses need coin").is_equal(2)
	assert_str(Business.next_needs()).contains("coin")
	GameState.economy_stage="currency"
	assert_int(Business.rung()).is_equal(3)
	_know("joint_stock_company")
	assert_int(Business.rung()).is_equal(4)
	_know("limited_liability_registration")
	assert_int(Business.rung()).is_equal(5)
	assert_str(Business.next_needs()).is_empty()
	# Knowledge is never lost to the ladder; coin lost suspends the coin rungs.
	Business.step(0);Business.step(30)
	_forget("limited_liability_registration");_forget("joint_stock_company")
	assert_int(Business.rung()).override_failure_message("a lost discovery keeps the rung").is_equal(5)
	GameState.economy_stage="weighed_metal"
	assert_int(Business.rung()).override_failure_message("without coin the coin rungs wait").is_equal(2)
	GameState.economy_stage="currency"
	assert_int(Business.rung()).is_equal(5)


func test_the_default_stance_is_guarded_then_chartered()->void:
	_at_rung(1)
	assert_str(Business.stance()).is_equal("guarded")
	_at_rung(2)
	assert_str(Business.stance()).is_equal("chartered")
	# A chosen stance stands whatever the rung.
	Business.set_stance("open")
	_at_rung(3)
	assert_str(Business.stance()).is_equal("open")


# --- 2. Size ------------------------------------------------------------------------

func test_the_share_moves_toward_its_target_at_the_stated_pace()->void:
	_at_rung(2)
	_money("weighed_metal",0.6)
	_size(0.0)
	var goal:=Business.target()
	# rung cap x stance reach x market x credit (no credit yet: 0.85).
	assert_float(goal).is_equal_approx(0.10*0.9*0.6*0.85,0.0001)
	# Credit: 0.7 + 0.3 x the share still free.
	_money("weighed_metal",0.6,500.0,0.25)
	assert_float(Business.credit_term()).is_equal_approx(0.7+0.3*0.75,0.0001)
	assert_float(Business.target()).is_equal_approx(0.10*0.9*0.6*(0.7+0.3*0.75),0.0001)
	_money("weighed_metal",0.6)
	# A twelfth of the gap a year while growing.
	Business.step(0)
	for month in range(1,13):Business.step(30*month)
	var grown:=Business.share()
	assert_float(grown).is_equal_approx(goal*(1.0-pow(11.0/12.0,360.0/365.0)),0.0002)
	# A quarter of the gap a year while shrinking.
	var e:=_size(goal*2.0)
	var high:=goal*2.0
	Business.step(400)
	assert_float(Business.share()).is_equal_approx(high-(high-goal)*(1.0-pow(0.75,40.0/365.0)),0.0002)
	assert_float(float(e.target)).is_equal_approx(goal,0.0001)
	# Market access is held between 0.3 and 1 in the target.
	_money("weighed_metal",0.05)
	assert_float(Business.market_term()).is_equal(0.3)


# --- 3. What it does -------------------------------------------------------------------

func test_productivity_is_share_times_gain_times_form_times_stance()->void:
	_at_rung(5)
	assert_float(Business.productivity(0.55,"open",5)).is_equal_approx(1.0+0.55*0.55*1.15,0.0001)
	assert_float(Business.productivity(0.55,"open",5)).is_between(1.34,1.36)
	assert_float(Business.productivity(0.04,"chartered",1)).is_equal_approx(1.006,0.0001)
	_form("open_professions")
	assert_float(Business.productivity(0.2,"chartered",5)).is_equal_approx(1.0+0.2*0.55*1.08*1.0,0.0001)
	_form("mutual_associations")
	assert_float(Business.productivity(0.2,"guarded",5)).is_equal_approx(1.0+0.2*0.55*0.95*0.95,0.0001)
	# The factor the day reads is cached on the record.
	_size(0.2,"open")
	assert_float(Business.factor()).is_equal_approx(1.0+0.2*0.55*0.95*1.15,0.0001)


func test_the_factor_reaches_the_working_efficiency_and_lifts_its_ceiling()->void:
	_at_rung(5)
	GameState.water_metrics["intake_ratio"]=1.0
	# A first day settles what the engine sets once; then the same day twice.
	_size(0.0)
	ConsequenceEngine.process_day({"traveling":false})
	var before:=GameState.simulation_metrics.duplicate(true)
	var capacities:=GameState.society_capacities.duplicate(true)
	var health:=float(GameState.population_health)
	_size(0.0)
	ConsequenceEngine.process_day({"traveling":false})
	var plain:=float(GameState.simulation_metrics.get("labor_efficiency",0.0))
	var made_plain:=float(GameState.simulation_metrics.get("material_capacity",0.0))
	assert_float(plain).is_between(0.26,1.10)
	# The same day again, the sector large enough to push past the old ceiling.
	GameState.simulation_metrics=before.duplicate(true)
	GameState.society_capacities=capacities.duplicate(true)
	GameState.population_health=health
	var e:=_size(0.0)
	var lift:=1.12/plain*1.1
	e.factor=lift
	ConsequenceEngine.process_day({"traveling":false})
	var worked:=float(GameState.simulation_metrics.get("labor_efficiency",0.0))
	assert_float(worked).override_failure_message("efficiency x factor").is_equal_approx(plain*lift,0.002)
	assert_float(worked).override_failure_message("the 1.12 ceiling rises with the factor").is_greater(1.12)
	# The making capacity settles toward a target the same factor raises.
	var prior:=float(before.get("material_capacity",0.12))
	var rate:=0.012
	var target_plain:=prior+(made_plain-prior)/rate
	var target_lifted:=prior+(float(GameState.simulation_metrics.get("material_capacity",0.0))-prior)/rate
	assert_float(target_lifted).is_equal_approx(target_plain*lift,0.01)


func test_civilian_goods_scale_with_the_factor()->void:
	GameState.population_allocations["Crafting"]=2
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	for item in Goods.BASKET:GameState.resource_stockpiles[item]=500.0
	GameState.civilian_goods=Goods.empty_state()
	var plain:=float(Goods.advance().made)
	assert_float(plain).is_greater(0.0)
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	GameState.civilian_goods=Goods.empty_state()
	_size(0.0).factor=1.3
	var lifted:=float(Goods.advance().made)
	assert_float(lifted).is_equal_approx(plain*1.3,0.0005)


func test_business_carries_trade_further()->void:
	GameState.water_metrics["intake_ratio"]=1.0
	_size(0.0)
	var plain:=EconomySystem._market_access({})
	_size(0.2)
	assert_float(Business.market_bonus()).is_equal_approx(0.06,0.00001)
	assert_float(EconomySystem._market_access({})).is_equal_approx(minf(1.0,plain+0.06),0.00001)


func test_business_gathers_wealth_within_the_ages_bounds()->void:
	_at_rung(4)
	var start:=[0.04,0.09,0.15,0.22,0.50]
	GameState.wealth_shares.assign(start)
	_size(0.0)
	for day in 1500:EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	var plain:=float(GameState.wealth_shares[4])
	# Corporations' share under Open: the room to the ceiling, x share x 1.5.
	_size(0.28,"open")
	var bounds:Array=preload("res://scripts/economy_system.gd").WEALTH_BOUNDS.currency
	assert_float(Business.wealth_lift(bounds)).is_equal_approx((0.75-0.50)*0.28*1.5,0.0001)
	GameState.wealth_shares.assign(start)
	for day in 1500:EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	var gathered:=float(GameState.wealth_shares[4])
	assert_float(gathered).is_greater(plain+0.05)
	assert_float(gathered).is_less_equal(0.75)
	# Even a sector of everyone stays under the age's ceiling.
	_size(1.0,"open")
	assert_float(Business.wealth_lift(bounds)).is_equal_approx(0.25,0.0001)
	GameState.wealth_shares.assign(start)
	for day in 1500:EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	assert_float(float(GameState.wealth_shares[4])).is_less_equal(0.75)
	var total:=0.0
	for share in GameState.wealth_shares:total+=float(share)
	assert_float(total).is_equal_approx(1.0,0.0001)


# --- 4. The stance ------------------------------------------------------------------------

func test_each_stance_has_its_numbers()->void:
	_at_rung(3)
	_money("currency",1.0)
	_size(0.0)
	var cap:=0.16
	var expect:={"guarded":[0.75,0.95,0.5,0.5,0.0],"chartered":[0.9,1.0,1.3,1.0,1.0/20.0],"open":[1.0,1.15,1.5,1.6,0.0]}
	for id in expect:
		var n:Array=expect[id]
		var q:=Business.quote(id)
		assert_float(float(q.target)).override_failure_message("%s reach" % id).is_equal_approx(cap*float(n[0])*1.0*0.85,0.0001)
		assert_float(float(q.work)).override_failure_message("%s gain" % id).is_equal_approx(float(q.target)*0.32*float(n[1]),0.0001)
		assert_float(float(q.rich)).override_failure_message("%s wealth" % id).is_equal_approx((0.75-0.50)*float(q.target)*float(n[2]),0.0001)
		assert_float(Business.bust_month(id,0)).override_failure_message("%s bust odds" % id).is_equal_approx(0.003*float(n[3]),0.000001)
		assert_float(float(q.purse)).override_failure_message("%s purse" % id).is_equal_approx(float(n[4]),0.000001)
	# Open grows fastest and gives most to the rich; Guarded is steadiest.
	assert_float(float(Business.quote("open").work)).is_greater(float(Business.quote("chartered").work))
	assert_float(float(Business.quote("guarded").bust_year)).is_less(float(Business.quote("open").bust_year))
	# The form changes the reach: licensed guilds hold it back.
	_form("licensed_guilds")
	assert_float(Business.target("open")).is_equal_approx(cap*1.0*0.85*1.0*0.85,0.0001)


func test_state_works_need_their_knowledge()->void:
	_at_rung(5)
	assert_bool(Business.choices().has("state")).is_false()
	var refused:=Business.set_stance("state")
	assert_bool(bool(refused.ok)).is_false()
	assert_str(Business.stance()).is_equal("chartered")
	_know("nationalized_core_industries")
	assert_bool(Business.choices().has("state")).is_true()
	assert_bool(bool(Business.set_stance("state").ok)).is_true()
	_size(0.2)
	assert_float(Business.purse_rate()).is_equal_approx(0.1,0.000001)
	assert_float(Business.factor()).is_equal_approx(1.0+0.2*0.55*0.85,0.0001)


func test_a_change_of_stance_costs_trust_once()->void:
	_at_rung(2)
	var trust:=float(GameState.simulation_metrics.get("legitimacy",0.62))
	GameState.simulation_metrics["legitimacy"]=trust
	var changed:=Business.set_stance("open")
	assert_bool(bool(changed.changed)).is_true()
	assert_float(float(changed.trust)).is_equal_approx(0.02,0.0001)
	assert_float(float(GameState.simulation_metrics.legitimacy)).is_equal_approx(trust-0.02,0.0001)
	var again:=Business.set_stance("open")
	assert_bool(bool(again.changed)).is_false()
	assert_float(float(GameState.simulation_metrics.legitimacy)).is_equal_approx(trust-0.02,0.0001)
	var notes:=Purse.history().filter(func(n:Dictionary)->bool:return String(n.kind)=="business")
	assert_int(notes.size()).override_failure_message("told once").is_equal(1)


# --- 5. The purse -------------------------------------------------------------------------

func test_charter_fees_come_out_of_real_stores()->void:
	_at_rung(2)
	_stock_food(200.0)
	GameState.economy_metrics["real_economy"]={"daily_output_value":1000.0}
	_size(0.08,"chartered")
	var purse:=Purse.state()
	var food:=float(GameState.resource_stockpiles.Food)
	var held:=float(purse.balance)
	var day:=Purse.accrue({"daily_output_value":1000.0},0.0)
	var output:=1000.0/Purse.food_price()
	assert_float(float(day.charter)).is_equal_approx(output*0.08*(1.0/20.0)*float(day.reach),0.001)
	# What came in is what left the town's stores: nothing is created.
	var taken:=food-float(GameState.resource_stockpiles.Food)
	assert_float(float(purse.balance)-held).is_equal_approx(float(day.levy)+float(day.charter),0.001)
	assert_float(taken).is_equal_approx(float(day.levy)+float(day.charter),0.001)
	assert_float(float((purse.month as Dictionary).charter)).is_equal_approx(float(day.charter),0.0001)
	assert_float(float(Purse.sources().charter)).is_greater(0.0)
	assert_float(float(Purse.forecast().charter)).is_greater(0.0)
	# A town with nothing to spare gives nothing: no fee is made up.
	_stock_food(30.0)
	var bare:=Purse.accrue({"daily_output_value":1000.0},0.0)
	assert_float(float(bare.charter)).is_equal(0.0)
	# Guarded takes nothing beyond the levy.
	_stock_food(200.0)
	_size(0.08,"guarded")
	assert_float(float(Purse.accrue({"daily_output_value":1000.0},0.0).charter)).is_equal(0.0)


# --- 6. Booms and busts ----------------------------------------------------------------------

func test_bust_odds_follow_the_stated_formula()->void:
	_at_rung(3)
	_size(0.1,"chartered")
	assert_float(Business.bust_month()).is_equal_approx(0.003,0.000001)
	assert_float(Business.bust_month("chartered",12)).is_equal_approx(0.003*1.5,0.000001)
	_know("double_entry_ledgers",0.5)
	assert_float(Business.banking()).is_equal_approx(0.2,0.00001)
	assert_float(Business.bust_month()).is_equal_approx(0.003*0.8,0.000001)
	_form("open_professions")
	assert_float(Business.bust_month("open",0)).is_equal_approx(0.003*1.6*1.15*0.8,0.000001)
	var year:=Business.bust_year()
	assert_float(year).is_equal_approx(1.0-pow(1.0-Business.bust_month(),12.0),0.000001)
	assert_str(Business.odds_words(1.0/40.0)).is_equal("About 1 in 40 years")
	assert_str(Business.odds_words(0.0)).is_equal("No busts")
	# Open commercial economies bust every few decades; guarded ones rarely.
	_forget("double_entry_ledgers");_form("licensed_guilds")
	assert_float(1.0/Business.bust_year("open",0)).is_between(15.0,45.0)
	assert_float(1.0/Business.bust_year("guarded",0)).is_greater(50.0)
	# A boom: growing while more than half the credit is used; work +2%.
	_money("currency",1.0,1000.0,0.7)
	_size(0.01,"open")
	Business.step(0);Business.step(30)
	assert_bool(Business.booming()).is_true()
	assert_float(Business.factor()).is_equal_approx(Business.productivity(Business.share(),"open")*1.02,0.0001)


func test_a_forced_bust_applies_its_effects_once_and_is_told_once()->void:
	_at_rung(3)
	_size(0.12,"open")
	GameState.credit_outstanding=1000.0
	GameState.credit_defaulted=0.0
	GameState.wealth_shares.assign([0.04,0.09,0.15,0.22,0.50])
	GameState.simulation_metrics["cohesion"]=0.6
	var factor_before:=Business.factor()
	var day:=int(GameState.elapsed_days)
	var told_before:=_busts_told()
	var b:=Business.bust_now(day)
	assert_float(Business.share()).is_equal_approx(0.08,0.00001)
	var fraction:=minf(0.9,0.12*2.0)/3.0
	assert_float(float(b.defaulted)).is_equal_approx(1000.0*fraction,0.01)
	assert_float(float(GameState.credit_outstanding)).is_equal_approx(1000.0*(1.0-fraction),0.01)
	assert_float(float(GameState.credit_defaulted)).is_equal_approx(1000.0*fraction,0.01)
	var ledger:=GameState.economic_ledger.filter(func(x:Dictionary)->bool:return String(x.kind)=="credit_default" and String(x.memo)=="Business failures")
	assert_int(ledger.size()).is_equal(1)
	assert_float(float(GameState.wealth_shares[4])).is_equal_approx(0.48,0.00001)
	var total:=0.0
	for share in GameState.wealth_shares:total+=float(share)
	assert_float(total).is_equal_approx(1.0,0.00001)
	assert_float(float(GameState.simulation_metrics.cohesion)).is_equal_approx(0.56,0.00001)
	assert_int(int(b.months)).is_between(6,12)
	assert_float(Business.factor()).is_equal_approx(Business.productivity(0.08,"open")*0.96,0.0001)
	assert_float(Business.factor()).is_less(factor_before)
	assert_int(_busts_told()-told_before).is_equal(1)
	# The months after: the cut eases and nothing is applied again.
	Business.step(day)
	var months:=int(b.months)
	for m in range(1,months+1):
		Business.step(day+30*m)
		var roll:Dictionary=Business.state().last_roll
		assert_float(float(roll.roll)).override_failure_message("this seed's rolls stay above the odds").is_greater_equal(float(roll.p))
	assert_int(Business.bust_left()).is_equal(0)
	assert_float(float(GameState.wealth_shares[4])).is_greater(0.47)
	assert_float(float(GameState.credit_outstanding)).is_equal_approx(1000.0*(1.0-fraction),0.01)
	assert_int(_busts_told()-told_before).is_equal(1)
	assert_float(Business.factor()).is_equal_approx(Business.productivity(Business.share(),"open"),0.0001)

func _busts_told()->int:
	var n:=0
	for entry in (Chronicle.data().entries as Array):
		if String((entry as Dictionary).get("key","")).begins_with("business_bust_"):n+=1
	return n


func test_a_roll_under_the_odds_is_a_bust_through_the_month()->void:
	_at_rung(3)
	_size(0.1,"open")
	Business.step(0)
	Business.forced_roll=0.0
	var month:=Business.step(30)
	assert_bool(month.has("bust")).is_true()
	assert_float(float(month.p)).is_equal_approx(Business.bust_month("open",0),0.000001)
	assert_float(Business.share()).is_less(0.1)
	assert_int(Business.bust_left()).is_greater(0)
	assert_int(int(Business.state().busts)).is_equal(1)


func test_the_monthly_roll_is_seeded_and_repeatable()->void:
	_at_rung(5)
	_size(0.3,"open")
	var a:=Business._rng(3000).randf()
	var b:=Business._rng(3000).randf()
	var c:=Business._rng(3030).randf()
	assert_float(a).is_equal(b)
	assert_float(a).is_not_equal(c)
	# Steps only once a month; a day costs a dictionary read.
	Business.step(0)
	var stepped:=0
	for day in range(1,366):
		if not Business.step(day).is_empty():stepped+=1
	assert_int(stepped).is_equal(12)
	var started:=Time.get_ticks_usec()
	var sum:=0.0
	for i in 20000:sum+=Business.factor()+Business.market_bonus()
	assert_int(Time.get_ticks_usec()-started).is_less(500000)
	assert_float(sum).is_greater(0.0)


# --- 7. Computer rulers ---------------------------------------------------------------------

func test_computer_rulers_choose_by_temperament_and_never_open_at_war()->void:
	var bold:={"assertiveness":0.9,"discipline":0.8,"empathy":0.1,"openness":0.3}
	var free:={"assertiveness":0.3,"discipline":0.3,"empathy":0.2,"openness":0.9}
	var kind:={"assertiveness":0.2,"discipline":0.3,"empathy":0.9,"openness":0.4}
	assert_str(Business.ruler_stance(bold,false)).is_equal("chartered")
	assert_str(Business.ruler_stance(free,false)).is_equal("open")
	assert_str(Business.ruler_stance(kind,false)).is_equal("guarded")
	for p in [bold,free,kind,{"openness":1.0,"assertiveness":0.0,"discipline":0.0,"empathy":0.0}]:
		assert_str(Business.ruler_stance(p,true)).is_not_equal("open")
	# A rival sets its own record in its own scope, by order.
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("trader",778,Vector2.ZERO)
	WorldSimulation.actors.trader.controller="ai"
	var chosen:String=WorldSimulation.scoped("trader",func()->String:
		WorldSimulation.state.economy_stage="weighed_metal"
		WorldSimulation.state.economy_metrics["price_observations"]=4
		Controller.business_orders("trader",{"personality":free,"at_war":false})
		return Business.stance())
	assert_str(chosen).is_equal("open")
	var at_war:String=WorldSimulation.scoped("trader",func()->String:
		Controller.business_orders("trader",{"personality":free,"at_war":true})
		return Business.stance())
	assert_str(at_war).is_not_equal("open")
	# The god's own record was not touched.
	assert_bool(bool(Business.state().chosen)).is_false()


# --- 8. The court ---------------------------------------------------------------------------

func _headman()->String:
	var person:=GovernmentPeopleSystem.officeholder("Steward")
	return String(Hall.summon({"person_id":int(person.person_id)}).get("id",""))

func test_the_court_reads_the_business_orders()->void:
	assert_dict(BusinessOrders.read("Open the markets to all")).is_equal({"kind":"business","stance":"open"})
	assert_dict(BusinessOrders.read("open trade to everyone")).is_equal({"kind":"business","stance":"open"})
	assert_dict(BusinessOrders.read("Grant charters")).is_equal({"kind":"business","stance":"chartered"})
	assert_dict(BusinessOrders.read("grant charters to the trades for a fee")).is_equal({"kind":"business","stance":"chartered"})
	assert_dict(BusinessOrders.read("Guard the trades")).is_equal({"kind":"business","stance":"guarded"})
	assert_dict(BusinessOrders.read("guard the trades with guilds and rules")).is_equal({"kind":"business","stance":"guarded"})
	assert_dict(BusinessOrders.read("Let the state run the great works")).is_equal({"kind":"business","stance":"state"})
	assert_dict(BusinessOrders.read("let the state run the works")).is_equal({"kind":"business","stance":"state"})
	for said in ["free the markets","Trade with the Esurai","guard the gate","Open the gates","open the stores to the hungry","Should we open the markets to all?",
			"don't grant charters","never open the markets","Build a great work","Raise the levy","How is business?","Guard the walls","The state is strong","if we grant charters the rich will grow"]:
		assert_dict(BusinessOrders.read(said)).override_failure_message("'%s' was read as a business order" % said).is_empty()
	# Each office button's words are read as its own stance.
	_at_rung(5)
	_know("nationalized_core_industries")
	for item:Dictionary in (BusinessOrders.menus()[0] as Dictionary).items:
		var reading:=BusinessOrders.read(String(item.text))
		assert_dict(reading).override_failure_message("button '%s' is not read" % String(item.text)).is_not_empty()


func test_the_court_carries_a_stance_with_numbers()->void:
	_at_rung(1)
	_size(0.02)
	GameState.simulation_metrics["legitimacy"]=0.6
	var id:=_headman()
	assert_str(id).is_not_empty()
	var opened:=CC.hear(id,"Open the markets to all",{})
	assert_bool(bool(opened.get("handled",true))).is_true()
	assert_str(String(opened.get("route",""))).is_equal("business")
	assert_bool(bool(opened.executed)).is_true()
	assert_str(Business.stance()).is_equal("open")
	var says:=String(opened.get("actor_says",""))
	assert_str(says).contains("Trust in you falls 2 points")
	assert_str(says).contains("Busts: about 1 in")
	assert_float(float(GameState.simulation_metrics.legitimacy)).is_equal_approx(0.58,0.0001)
	var again:=CC.hear(id,"open the markets to all",{})
	assert_bool(bool(again.executed)).is_false()
	assert_str(String(again.stage)).is_equal("none")
	# State works without its knowledge: said plainly, nothing changed.
	var refused:=CC.hear(id,"Let the state run the great works",{})
	assert_bool(bool(refused.executed)).is_false()
	assert_str(Business.stance()).is_equal("open")
	# Questions are answered from the business fact sheet.
	var asked:=Facts.answer_for(id,"How is business?")
	assert_str(asked).contains("Stalls and hired workshops")
	assert_str(asked).contains("open stance")
	var odds:=Facts.answer_for(id,"How often do the trades bust?")
	assert_str(odds).contains("about 1 in")
	var which:=Facts.offices({},{"person_id":int(GovernmentPeopleSystem.officeholder("Steward").person_id)})
	assert_str(Facts.text(Facts.sheet(which))).contains("Business: stalls and hired workshops")
	# The Headman's buttons carry one Business family.
	var names:=PackedStringArray()
	for m:Dictionary in preload("res://scripts/court_office_orders.gd").menus(id):names.append(String(m.get("name","")))
	assert_bool(names.has("Business")).is_true()


# --- 9. The Wealth tab -------------------------------------------------------------------------

func test_the_wealth_tab_shows_business_with_short_plain_labels()->void:
	_at_rung(1)
	_size(0.015)
	var board:=Board.new()
	add_child(board)
	board.setup({})
	for part in ["Ladder","Rung_0","Rung_5","RungNow","NextRung","Share","ShareWords","BusinessEffect","Stances","Stance_guarded","Stance_chartered","Stance_open","BustOdds"]:
		assert_object(board.find_child(part,true,false)).override_failure_message("the business section has no %s" % part).is_not_null()
	assert_object(board.find_child("Stance_state",true,false)).is_null()
	var texts:=PackedStringArray()
	var long:=PackedStringArray()
	for node in (board.find_child("Business",true,false) as Node).find_children("*","",true,false):
		var text:=""
		if node is Label:text=(node as Label).text
		elif node is Button:text=(node as Button).text
		else:continue
		texts.append(text)
		var words:=0
		for token in text.replace("\n"," ").split(" ",false):
			if token in ["·","−","+",":"]:continue
			words+=1
		if words>12:long.append(text)
	assert_array(Array(long)).override_failure_message("labels over twelve words: %s" % str(long)).is_empty()
	var all:=" | ".join(texts)
	assert_str(all).contains("to all work")
	assert_str(all).contains("Stalls and hired workshops.")
	# The section sits between where the purse's coming-in comes from and the levy.
	var order:=[]
	for child in board.get_children():
		if child is Label:order.append((child as Label).text)
	assert_int(order.find("BUSINESS")).is_greater(order.find("WHERE IT COMES FROM"))
	assert_int(order.find("BUSINESS")).is_less(order.find("THE LEVY"))
	# A stance chosen on the screen is the engine's stance.
	(board.find_child("Stance_open",true,false) as Button).emit_signal("pressed")
	assert_str(Business.stance()).is_equal("open")
	await await_idle_frame()
	remove_child(board)
	board.free()


# --- 10. Saves ----------------------------------------------------------------------------------

func test_the_business_record_survives_a_save_and_older_saves_start_partway()->void:
	_at_rung(2)
	var e:=_size(0.037,"open")
	e.boom_months=3
	e.bust={"day":10,"months":8,"left":5,"rung":2}
	Business._refresh(e)
	var factor:=Business.factor()
	assert_str(fx._round_trip()).is_empty()
	var loaded:=Business.state()
	assert_float(float(loaded.share)).is_equal_approx(0.037,0.000001)
	assert_str(Business.stance()).is_equal("open")
	assert_int(int(loaded.boom_months)).is_equal(3)
	assert_int(Business.bust_left()).is_equal(5)
	assert_float(Business.factor()).is_equal_approx(factor,0.000001)
	# An older save with no record starts at the rung its knowledge allows,
	# with a share at 40 in 100 of that rung's target.
	GameState.enterprise={}
	_at_rung(2)
	var started:=Business.state()
	var goal:=Business.target()
	assert_float(goal).is_greater(0.0)
	assert_float(float(started.share)).is_equal_approx(goal*0.4,0.00001)
	assert_int(int(started.reached)).is_equal(2)
	assert_str(Business.stance()).is_equal("chartered")
	# And a new world starts with no business at all.
	GameState.enterprise={}
	GameState.economy_stage="subsistence"
	assert_float(float(Business.state().share)).is_equal(0.0)

