extends GdUnitTestSuite
## THE REALM'S PURSE (scripts/realm_purse.gd): one account the god commands,
## the levy and what it buys, the wealth shares that can fall again, the
## soldiers counted against the whole realm, and the court's purse orders.
## Offline; never calls a real API. The world is the court evaluation's base
## (Seanstone, 900 people, the Headman Kishan), built through the real engine.

const Purse:=preload("res://scripts/realm_purse.gd")
const PurseOrders:=preload("res://scripts/court_purse_orders.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Board:=preload("res://scripts/hud/purse_board.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const DAY:=preload("res://scripts/civilization_day.gd")

var fx:Fixtures


func before_test()->void:
	fx=Fixtures.new(self)
	fx.base(false)
	GameState.realm_purse={}


func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()


## The capital's day's work as the economy reads it (real_economy).
func _output(value:float)->void:
	var metrics:Dictionary=GameState.economy_metrics
	metrics["real_economy"]={"daily_output_value":value}
	GameState.economy_metrics=metrics


func _soldiers(count:int)->void:
	fx.train(count)


# --- 1. Inequality can fall again, within the age's bounds -------------------------

func test_inequality_falls_back_within_the_ages_bounds()->void:
	GameState.economy_stage="subsistence"
	GameState.simulation_metrics["food_days"]=30.0
	# An older save at the old cap: three-quarters held by the richest fifth.
	GameState.wealth_shares.assign([0.01,0.03,0.07,0.14,0.75])
	EconomySystem._update_wealth_distribution(0.0,0.0,0.0,0.0,{"labor_return_index":1.0})
	var first:=float(GameState.wealth_shares[4])
	assert_float(first).override_failure_message("before money the richest fifth cannot hold more than 55 in 100").is_less_equal(0.55)
	for day in 720: EconomySystem._update_wealth_distribution(0.0,0.0,0.0,0.0,{"labor_return_index":1.0})
	var settled:=float(GameState.wealth_shares[4])
	assert_float(settled).override_failure_message("sharing out pulls it back down").is_less(first-0.05)
	assert_float(settled).is_greater_equal(0.28)
	var total:=0.0
	for share in GameState.wealth_shares: total+=float(share)
	assert_float(total).is_equal_approx(1.0,0.0001)
	# Feasts when the stores are full share it out faster.
	GameState.wealth_shares.assign([0.05,0.10,0.18,0.22,0.45])
	for day in 180: EconomySystem._update_wealth_distribution(0.0,0.0,0.0,0.0,{"labor_return_index":1.0})
	var lean:=float(GameState.wealth_shares[4])
	GameState.wealth_shares.assign([0.05,0.10,0.18,0.22,0.45])
	GameState.simulation_metrics["food_days"]=90.0
	for day in 180: EconomySystem._update_wealth_distribution(0.0,0.0,0.0,0.0,{"labor_return_index":1.0})
	assert_float(float(GameState.wealth_shares[4])).is_less(lean)


func test_the_purses_pay_and_taxing_the_rich_spread_the_wealth()->void:
	GameState.economy_stage="currency"
	var start:=[0.04,0.09,0.15,0.22,0.50]
	GameState.wealth_shares.assign(start)
	for day in 365: EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	var alone:=float(GameState.wealth_shares[4])
	# The chief's redistribution: the purse put a twentieth of the output back in common hands.
	GameState.wealth_shares.assign(start)
	var purse:=Purse.state()
	purse.redistribution=0.05
	for day in 365: EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	var shared:=float(GameState.wealth_shares[4])
	assert_float(shared).is_less(alone)
	purse.redistribution=0.0
	# "Tax the rich" (wealth_levy) names the wealth shares and moves them.
	GameState.wealth_shares.assign(start)
	GameState.active_modifiers.append({"kind":"policy","id":"wealth_levy","magnitude":0.16,"started_day":float(GameState.elapsed_days),"until_day":float(GameState.elapsed_days)+400.0})
	assert_float(float(ConsequenceEngine.policy_effect("wealth_concentration"))).is_less(0.0)
	for day in 365: EconomySystem._update_wealth_distribution(0.3,0.0,0.0,0.0,{"labor_return_index":1.0})
	assert_float(float(GameState.wealth_shares[4])).is_less(alone)
	# ... and the richest fifth pay into the purse while it holds.
	assert_float(Purse.rich_levy(100.0)).is_greater(0.0)
	assert_float(float(GameState.wealth_shares[4])).is_greater_equal(0.35)


func test_freeing_the_markets_widens_them_and_concentrates_wealth()->void:
	var before:=float(ConsequenceEngine.policy_effect("market_access"))
	GameState.active_modifiers.append({"kind":"policy","id":"market_deregulation","magnitude":0.14,"started_day":float(GameState.elapsed_days),"until_day":float(GameState.elapsed_days)+180.0})
	assert_float(float(ConsequenceEngine.policy_effect("market_access"))).is_greater(before)
	assert_float(float(ConsequenceEngine.policy_effect("wealth_concentration"))).is_greater(0.0)
	assert_float(EconomySystem._market_policy()).is_greater(0.0)
	var words:=GovernmentPolicyCatalog.formatted_effects(GovernmentPolicyCatalog.definition("market_deregulation").effects,0.14)
	assert_str(words).contains("market reach")
	assert_str(words).contains("richest fifth")
	# The channels these policies name are known and observed.
	var ours:=GovernmentPolicyCatalog.validation_errors().filter(func(e:String)->bool:return "wealth_concentration" in e or "market_access" in e)
	assert_array(ours).is_empty()


# --- 2. Soldiers are counted against the whole realm's workers ----------------------

func test_soldiers_are_counted_against_the_whole_realms_workers()->void:
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.75,"founded_day":0})
	var burden:={"mobilized_population":40.0}
	var whole:=EconomySystem._real_economy_accounts(0.0,0.0,burden)
	assert_float(float(whole.mobilized_labor)).is_equal_approx(40.0,0.001)
	# The capital holds a quarter of the people: it carries a quarter of the soldiers.
	var local:Dictionary=SettlementModel.with_local_population(func()->Dictionary:return EconomySystem._real_economy_accounts(0.0,0.0,burden))
	assert_float(float(local.mobilized_labor)).is_equal_approx(40.0*0.25,0.5)
	assert_float(float(local.collective_labor_share)).is_less_equal(float(whole.collective_labor_share)+0.0001)


# --- 3. One realm account, merged once from every town's money ----------------------

func test_town_treasuries_merge_once_into_one_realm_account()->void:
	GameState.economy_stage="currency"
	GameState.currency_supply=500.0;GameState.public_treasury=120.0;GameState.private_currency=380.0;GameState.currency_hoards=0.0;GameState.mutual_aid_reserve=0.0
	GameState.monetary_reserve_metals={"Copper Ore":250.0};GameState.public_debt=20.0;GameState.military_arrears=5.0;GameState.civil_arrears=3.0
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	SettlementModel._ensure_city_resources(GameState.player_settlements[-1])
	var town:Dictionary=(GameState.player_settlements[-1] as Dictionary).local_resources
	town.economy_stage="currency";town.currency_supply=100.0;town.public_treasury=30.0;town.private_currency=70.0;town.monetary_reserve_metals={"Tin Ore":50.0}
	GameState.realm_purse={}
	var purse:=Purse.state()
	# The capital's treasury first repaid its own households' 20; then both merged.
	assert_float(float(purse.balance)).is_equal_approx(100.0+30.0,0.001)
	assert_float(float(purse.coin)).is_equal_approx(130.0,0.001)
	assert_float(float(purse.debt)).is_equal_approx(5.0,0.001)
	assert_float(GameState.public_treasury).is_equal(0.0)
	assert_float(GameState.public_debt).is_equal(0.0)
	assert_float(GameState.civil_arrears).is_equal(0.0)
	assert_float(float(town.public_treasury)).is_equal(0.0)
	# Every coin is still counted: each town's circulation adds up, and the
	# metal that backed the merged coin moved with it.
	assert_float(GameState.currency_supply).is_equal_approx(GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve,0.001)
	assert_float(float(town.currency_supply)).is_equal_approx(float(town.private_currency),0.001)
	var backing:=0.0
	for v in (purse.backing as Dictionary).values(): backing+=float(v)
	assert_float(backing).is_equal_approx(130.0*Purse.BACKING_RATIO,0.001)
	assert_bool(bool(EconomySystem.accounting_audit().ok)).is_true()
	# Once: a second reading merges nothing more.
	GameState.public_treasury=0.0
	Purse.state()
	assert_float(float(Purse.state().balance)).is_equal_approx(130.0,0.001)
	# After coinage the share on goods sold for money is paid in coin: it
	# leaves the households' circulation with its backing, every coin counted.
	var private_before:=GameState.private_currency
	var coin_before:=float(Purse.state().coin)
	var paid:=Purse.accrue({"daily_output_value":200.0,"observed_trade":50.0},0.5)
	assert_float(float(paid.coin)).is_greater(0.0)
	assert_float(float(paid.coin)).is_less(float(paid.levy))
	assert_float(GameState.private_currency).is_equal_approx(private_before-float(paid.coin),0.0001)
	assert_float(float(Purse.state().coin)).is_equal_approx(coin_before+float(paid.coin),0.0001)
	assert_float(GameState.currency_supply).is_equal_approx(GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve,0.001)
	assert_bool(bool(EconomySystem.accounting_audit().ok)).is_true()
	# One account: the capital's and the town's levies both fill it.
	var before:=Purse.balance()
	Purse.accrue({"daily_output_value":200.0},0.0)
	SettlementModel.with_city_resources("dawngate",func()->void:Purse.accrue({"daily_output_value":100.0},0.0))
	assert_float(Purse.balance()).is_greater(before)
	assert_float(float((Purse.state().month as Dictionary).output)).is_equal_approx(200.0+300.0,0.001)


# --- 4. Words by age --------------------------------------------------------------------

func test_the_purse_is_named_by_what_the_people_know()->void:
	GameState.economy_stage="subsistence"
	Purse.state().balance=340.0
	assert_str(Purse.account_name()).is_equal("the common store")
	assert_str(Purse.amount_text(340.0)).is_equal("340 rations' worth")
	assert_str(Purse.pay_word()).is_equal("food and gifts")
	GameState.economy_stage="weighed_metal"
	GameState.known_discoveries.append("copper_smelting")
	assert_str(Purse.account_name()).is_equal("the silver store")
	assert_str(Purse.amount_text(340.0)).is_equal("340 silver")
	GameState.economy_stage="currency"
	# Coin is said only once the people keep registers or public credit.
	assert_str(Purse.unit_word()).is_equal("silver")
	GameState.known_discoveries.append("property_registers")
	assert_str(Purse.account_name()).is_equal("the treasury")
	assert_str(Purse.amount_text(340.0)).is_equal("340 coin")
	# One account: the words changed, the balance did not.
	assert_float(Purse.balance()).is_equal(340.0)


# --- 5. The levy: its levels, yield and costs --------------------------------------------

func test_levy_levels_take_the_ages_share_with_their_yield_and_costs()->void:
	GameState.economy_stage="subsistence"
	_output(150.0)
	var light:=Purse.quote("light");var usual:=Purse.quote("usual");var heavy:=Purse.quote("heavy")
	# A chief's tribute: a tenth of the harvest at most.
	assert_float(float(light.rate)).is_equal_approx(1.0/40.0,0.0001)
	assert_float(float(usual.rate)).is_equal_approx(1.0/20.0,0.0001)
	assert_float(float(heavy.rate)).is_equal_approx(1.0/10.0,0.0001)
	assert_str(String(usual.words)).is_equal("one part in twenty")
	assert_float(float(usual.per_season)).is_greater(float(light.per_season))
	assert_float(float(heavy.per_season)).is_greater(float(usual.per_season))
	assert_float(float(heavy.evasion)).is_greater(float(light.evasion))
	assert_float(float(heavy.trust)).is_greater(float(usual.trust))
	assert_float(float(light.trust)).is_less(1.0)
	assert_float(float(heavy.trust)).is_less_equal(Purse.LEVY_TRUST*100.0)
	# Early states take a fifth at most.
	GameState.economy_stage="weighed_metal"
	assert_float(float(Purse.quote("heavy").rate)).is_equal_approx(0.2,0.0001)
	# The yield is the engine's: output x rate x reach x (1 - hidden).
	GameState.economy_stage="subsistence"
	Purse.set_levy("heavy")
	var q:=Purse.quote("heavy")
	var before:=Purse.balance()
	var day:=Purse.accrue({"daily_output_value":150.0},0.0)
	assert_float(Purse.balance()-before).is_equal_approx(150.0*float(q.rate)*float(q.reach)*(1.0-float(q.evasion)),0.01)
	assert_float(float(day.evaded)).is_greater(0.0)
	# Its cost reaches the people: trust and holding together, in the economy's pressure.
	assert_float(Purse.levy_pressure()).is_equal_approx(0.8*Purse.LEVY_TRUST,0.0001)
	Purse.set_levy("light")
	assert_float(Purse.levy_pressure()).is_less(0.005)
	# Stepping past the heaviest stays there, and says so.
	Purse.set_levy("heavy")
	assert_bool(bool(Purse.step_levy(1).get("at_end",false))).is_true()


# --- 6. An unpaid army loses will and some desert, bounded --------------------------------

func test_an_unpaid_army_loses_will_and_some_desert_within_bounds()->void:
	_soldiers(60)
	_output(1200.0)
	var troops:=int(MilitaryCampaign.home_army.get("troops",0))
	assert_int(troops).is_greater_equal(50)
	var will:=float(MilitaryCampaign.home_army.get("morale",1.0))
	var purse:=Purse.state()
	purse.balance=0.0;purse.coin=0.0
	purse.last_settle_day=int(GameState.elapsed_days)-1
	var day:=int(GameState.elapsed_days)
	var month:=30-posmod(day,30)
	var report:=Purse.settle(day+month)
	assert_float(float((report.army as Dictionary).get("unpaid",0.0))).is_equal_approx(1.0,0.001)
	var lost:=will-float(MilitaryCampaign.home_army.get("morale",1.0))
	assert_float(lost).is_greater(0.0)
	assert_float(lost).is_less_equal(MilitaryCampaign.UNPAID_WILL+0.0001)
	# Months running: desertion stays bounded (at most 1 in 25 a month).
	var left:=troops
	for m in range(1,5):
		var at:=int(MilitaryCampaign.home_army.get("troops",0))
		Purse.settle(day+month+30*m)
		var gone:=at-int(MilitaryCampaign.home_army.get("troops",0))
		assert_int(gone).is_less_equal(ceili(float(at)*0.04))
		left=int(MilitaryCampaign.home_army.get("troops",0))
	assert_int(left).is_less(troops)
	assert_int(int(Purse.state().unpaid_months)).is_equal(5)
	assert_float(float(MilitaryCampaign.home_army.get("pay_readiness",1.0))).is_equal_approx(1.0-MilitaryCampaign.UNPAID_READINESS,0.0001)
	# The alert row says so, under the clock.
	var alert:=preload("res://scripts/hud/army_alerts.gd").unpaid_alert()
	assert_int(int(alert.count)).is_equal(5)
	# Paid again, they take heart: readiness comes back, no one else leaves.
	Purse.state().balance=1000000.0
	var before_pay:=int(MilitaryCampaign.home_army.get("troops",0))
	Purse.settle(day+month+30*5)
	assert_int(int(Purse.state().unpaid_months)).is_equal(0)
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(before_pay)
	assert_float(float(MilitaryCampaign.home_army.get("pay_readiness",1.0))).is_greater(1.0-MilitaryCampaign.UNPAID_READINESS)


# --- 7. Scholars and crews give bounded effects ---------------------------------------------

func test_scholars_and_crews_give_bounded_effects()->void:
	assert_float(Purse.scholars_factor()).is_equal(1.0)
	assert_float(Purse.crews_bonus()).is_equal(0.0)
	var before_research:=float(DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge").progress_multiplier)
	var before_building:=preload("res://scripts/settlement_construction.gd").daily_work()
	Purse.set_line("scholars",true);Purse.set_line("crews",true)
	assert_float(Purse.scholars_factor()).is_equal_approx(1.0+Purse.SCHOLARS_MAX,0.0001)
	assert_float(Purse.crews_bonus()).is_equal_approx(Purse.CREWS_MAX,0.0001)
	if before_research>0.0: assert_float(float(DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge").progress_multiplier)).is_equal_approx(before_research*(1.0+Purse.SCHOLARS_MAX),0.0001)
	assert_float(preload("res://scripts/settlement_construction.gd").daily_work()).is_greater_equal(before_building)
	# Paid half, they give half; never more than the full line.
	(Purse.state().funded as Dictionary).scholars=0.5
	assert_float(Purse.scholars_factor()).is_equal_approx(1.0+Purse.SCHOLARS_MAX*0.5,0.0001)
	(Purse.state().funded as Dictionary).crews=3.0
	assert_float(Purse.crews_bonus()).is_equal_approx(Purse.CREWS_MAX,0.0001)
	# The reckoning pays them from the purse at the stated keep.
	_output(1200.0)
	var purse:=Purse.state()
	purse.balance=100000.0
	var day:=int(GameState.elapsed_days)
	purse.last_settle_day=day
	(purse.line_days as Dictionary).scholars=day;(purse.line_days as Dictionary).crews=day
	var next:=day+30-posmod(day,30)
	var report:=Purse.settle(next)
	var oph:=Purse.output_per_head()
	assert_float(float((report.paid as Dictionary).get("scholars",0.0))).is_equal_approx(Purse.line_cost_per_day("scholars",oph)*float(next-day),0.5)
	assert_float(float((Purse.state().funded as Dictionary).scholars)).is_equal_approx(1.0,0.0001)
	# Switched off, the effect stops at once.
	Purse.set_line("scholars",false)
	assert_float(Purse.scholars_factor()).is_equal(1.0)


# --- 8. Relief buys food at the market price -------------------------------------------------

func test_relief_buys_food_for_a_hungry_town_at_the_market_price()->void:
	GameState.food_stocks={"Fresh food":0.0,"Stored food":6000.0}
	GameState.resource_stockpiles["Food"]=6000.0
	GameState.economy_metrics["price_observations"]=12
	GameState.market_prices["Food"]=1.25
	GameState.simulation_metrics["food_days"]=120.0
	GameState.simulation_metrics["food_consumption"]=600.0
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	var record:Dictionary=GameState.player_settlements[-1]
	SettlementModel._ensure_city_resources(record)
	record["resource_metrics"]={"food_days":4.0,"food_consumption":200.0}
	Purse.state().balance=2000.0
	var capital_food:=float(GameState.resource_stockpiles.get("Food",0.0))
	var bought:=Purse.buy_relief(500.0)
	assert_float(float(bought.spent)).is_greater(0.0)
	assert_float(float(bought.spent)).is_less_equal(500.0+0.001)
	# At the seller's market price, every ration paid for.
	assert_float(float(bought.spent)).is_equal_approx(float(bought.rations)*1.25,0.01)
	assert_float(capital_food-float(GameState.resource_stockpiles.get("Food",0.0))).is_equal_approx(float(bought.rations),0.01)
	assert_float(Purse.balance()).is_equal_approx(2000.0-float(bought.spent),0.01)
	# The food is on the road to the hungry town, as a delivery between towns.
	var on_road:=0.0
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.destination_id)=="dawngate": on_road+=float(shipment.quantity)
	assert_float(on_road).is_equal_approx(float(bought.rations),0.01)
	# No market, no purchase: said plainly.
	GameState.economy_metrics["price_observations"]=0
	var none:=Purse.buy_relief(500.0)
	assert_float(float(none.spent)).is_equal(0.0)
	assert_str(String(none.reason)).contains("no market")


# --- 9. The Wealth screen ---------------------------------------------------------------------

func test_the_wealth_screen_builds_with_short_plain_labels()->void:
	_output(900.0)
	_soldiers(10)
	Purse.state().balance=640.0
	Purse.set_line("scholars",true)
	var board:=Board.new()
	add_child(board)
	board.setup({})
	for part in ["Balance","ComingIn","GoingOut","Budget","Levels","LevyNow","LevyCost","Line_army","Line_scholars","Line_crews","Line_relief","Fifths","Shares","Pressure"]:
		assert_object(board.find_child(part,true,false)).override_failure_message("the purse board has no %s" % part).is_not_null()
	var long:=PackedStringArray()
	for node in board.find_children("*","",true,false):
		var text:=""
		if node is Label: text=(node as Label).text
		elif node is Button: text=(node as Button).text
		else: continue
		var words:=0
		for token in text.replace("\n"," ").split(" ",false):
			if token in ["·","−","+",":"]: continue
			words+=1
		if words>12: long.append(text)
	assert_array(Array(long)).override_failure_message("labels over twelve words: %s" % str(long)).is_empty()
	# A level chosen on the screen is the engine's levy.
	(board.find_child("Level_heavy",true,false) as Button).emit_signal("pressed")
	assert_str(String(Purse.state().levy)).is_equal("heavy")
	# The sections drawn again are freed with the frame; then the board.
	await await_idle_frame()
	remove_child(board)
	board.free()
	# The economy's Wealth tab mounts the board first.
	var tab:Dictionary=preload("res://scripts/hud/content/dock_content_economy.gd").new(null,null)._wealth_tab()
	assert_str(String((tab.blocks[0] as Dictionary).type)).is_equal("purse_board")


# --- 10. The court ------------------------------------------------------------------------------

func _headman()->String:
	var person:=GovernmentPeopleSystem.officeholder("Steward")
	return String(Hall.summon({"person_id":int(person.person_id)}).get("id",""))

func test_the_court_carries_the_purse_orders_with_numbers()->void:
	_output(900.0)
	_soldiers(10)
	var id:=_headman()
	assert_str(id).is_not_empty()
	var raised:=CC.hear(id,"Raise the levy",{})
	assert_bool(bool(raised.get("handled",false))).is_true()
	assert_str(String(raised.get("route",""))).is_equal("purse")
	assert_str(String(Purse.state().levy)).is_equal("heavy")
	assert_str(String(raised.get("actor_says",""))).contains("one part in ten")
	assert_bool(bool(raised.executed)).is_true()
	var lowered:=CC.hear(id,"lower the levy",{})
	assert_str(String(Purse.state().levy)).is_equal("usual")
	assert_bool(bool(lowered.executed)).is_true()
	CC.hear(id,"Stop paying the soldiers",{})
	assert_bool(Purse.line_on("army")).is_false()
	CC.hear(id,"Pay the soldiers",{})
	assert_bool(Purse.line_on("army")).is_true()
	CC.hear(id,"Fund the scholars",{})
	assert_bool(Purse.line_on("scholars")).is_true()
	CC.hear(id,"Hire crews",{})
	assert_bool(Purse.line_on("crews")).is_true()
	# Relief with no second town to buy from: said plainly, nothing pretended.
	var relief:=CC.hear(id,"Spend 100 on food for the hungry",{})
	assert_str(String(relief.get("route",""))).is_equal("purse")
	assert_bool(bool(relief.executed)).is_false()
	assert_str(String(relief.stage)).is_equal("none")
	# Questions are answered from the purse's fact sheet, with its numbers.
	Purse.state().balance=340.0
	var asked:=Facts.answer_for(id,"How much is in the treasury?")
	assert_str(asked).contains("340")
	assert_str(asked).contains("common store")
	var levy:=Facts.answer_for(id,"What does the levy bring in?")
	assert_str(levy).contains("one part in twenty")
	assert_str(levy).contains(EraWords_grouped(roundi(float(PurseOrders.facts().levy_season))))
	# The live voice is given the same facts.
	var which:=Facts.offices({},{"person_id":int(GovernmentPeopleSystem.officeholder("Steward").person_id)})
	assert_bool(which.has("purse")).is_true()
	assert_str(Facts.text(Facts.sheet(which))).contains("The realm's account is the common store")
	# The headman's office buttons carry the purse (no Treasurer is named).
	var menus:=preload("res://scripts/court_office_orders.gd").menus(id)
	var names:=PackedStringArray()
	for m:Dictionary in menus: names.append(String(m.get("name","")))
	assert_bool(names.has("Levy")).is_true()
	assert_bool(names.has("PayArmy")).is_true()

func EraWords_grouped(value:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(value)

func test_look_alikes_are_not_purse_orders()->void:
	for said in ["Raise a levy of 10 men","stand the levy down","Recruit 3 levies, train them and arm them","tax the rich","How much is in the treasury?","Store more food for the winter","Ration the food","Build more homes"]:
		assert_dict(PurseOrders.read(said)).override_failure_message("'%s' was read as a purse order" % said).is_empty()
	assert_dict(PurseOrders.read("RAISE THE LEVY")).is_equal({"kind":"levy","step":1})
	assert_dict(PurseOrders.read("make the levy heavy")).is_equal({"kind":"levy","level":"heavy"})
	assert_dict(PurseOrders.read("Set the levy to light")).is_equal({"kind":"levy","level":"light"})
	assert_dict(PurseOrders.read("cut taxes")).is_equal({"kind":"levy","step":-1})
	assert_dict(PurseOrders.read("stop paying the soldiers")).is_equal({"kind":"line","line":"army","on":false})
	assert_dict(PurseOrders.read("let the crews go")).is_equal({"kind":"line","line":"crews","on":false})
	assert_dict(PurseOrders.read("spend 250 on food for the hungry")).is_equal({"kind":"relief","amount":250.0})


# --- 11. Rivals use the same levers ------------------------------------------------------------

func test_rivals_set_the_purse_by_their_nature_and_desert_unpaid()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["hawk","dove"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].controller="ai"
	var hawk:={"personality":{"assertiveness":0.9,"discipline":0.8,"empathy":0.1,"openness":0.3,"risk_tolerance":0.6},"at_war":true}
	var dove:={"personality":{"assertiveness":0.1,"discipline":0.3,"empathy":0.9,"openness":0.8,"risk_tolerance":0.3},"at_war":false}
	WorldSimulation.scoped("hawk",func()->void:Controller.purse_orders("hawk",hawk))
	WorldSimulation.scoped("dove",func()->void:Controller.purse_orders("dove",dove))
	var hawk_levy:=String(WorldSimulation.scoped("hawk",func()->String:return String(Purse.state().levy)))
	var dove_levy:=String(WorldSimulation.scoped("dove",func()->String:return String(Purse.state().levy)))
	assert_str(hawk_levy).is_equal("heavy")
	assert_str(dove_levy).is_equal("light")
	assert_bool(bool(WorldSimulation.scoped("dove",func()->bool:return Purse.line_on("relief")))).is_true()
	# A rival that cannot pay its army sees desertion too: the same reckoning.
	var gone:int=WorldSimulation.scoped("hawk",func()->int:
		var mc=WorldSimulation.military
		mc.military_inventory["improvised"]=20
		mc.raise_recruits(20)
		mc.start_training("levy","improvised",20)
		mc._complete_training(mc.training_queue[0].duplicate(true))
		mc.training_queue.clear()
		var at:=int(mc.home_army.get("troops",0))
		var purse:=Purse.state()
		purse.balance=0.0
		purse.last_settle_day=0
		WorldSimulation.state.economy_metrics["real_economy"]={"daily_output_value":400.0}
		for month in range(1,6):Purse.settle(30*month)
		return at-int(mc.home_army.get("troops",0)))
	assert_int(gone).is_greater(0)
	# The player's own state was not touched by either.
	assert_int(int(Purse.state().get("unpaid_months",0))).is_equal(0)


# --- 12. Saves ---------------------------------------------------------------------------------

func test_the_purse_survives_a_save_round_trip()->void:
	_soldiers(10)
	var purse:=Purse.state()
	purse.balance=777.0
	Purse.set_levy("heavy");Purse.set_line("scholars",true)
	purse.unpaid_months=2
	MilitaryCampaign.pay_shortfall(1.0,2,0.0)
	var readiness:=float(MilitaryCampaign.home_army.get("pay_readiness",1.0))
	assert_str(fx._round_trip()).is_empty()
	var loaded:=Purse.state()
	assert_float(float(loaded.balance)).is_equal_approx(777.0,0.001)
	assert_str(String(loaded.levy)).is_equal("heavy")
	assert_bool(Purse.line_on("scholars")).is_true()
	assert_int(int(loaded.unpaid_months)).is_equal(2)
	assert_float(float(MilitaryCampaign.home_army.get("pay_readiness",1.0))).is_equal_approx(readiness,0.0001)
	# An older save without a purse loads with a whole one.
	GameState.realm_purse={}
	assert_str(String(Purse.state().levy)).is_not_empty()
	assert_bool(Purse.state().has("lines")).is_true()


# --- 13. Speed: no per-day loops ----------------------------------------------------------------

func test_the_purse_settles_monthly_and_costs_no_more_a_day()->void:
	_output(900.0)
	var purse:=Purse.state()
	purse.last_settle_day=0
	var settled:=0
	for day in range(1,366):
		if not Purse.settle(day).is_empty(): settled+=1
	assert_int(settled).is_equal(12)
	# The daily levy replaces the old per-town treasury day (tax capacity,
	# upkeep, debt and a thirty-day fiscal forecast): it must cost no more.
	var accounts:={"daily_output_value":900.0}
	var started:=Time.get_ticks_usec()
	for day in 365:
		EconomySystem._tax_capacity_for(GameState.tax_rate,90.0,0.3,GameState.private_currency)
		EconomySystem._public_upkeep({})
		EconomySystem._fiscal_outlook_for(30.0,90.0,0.3,{},GameState.public_treasury,GameState.private_currency,GameState.tax_rate)
	var old_cost:=Time.get_ticks_usec()-started
	started=Time.get_ticks_usec()
	for day in 365:
		Purse.accrue(accounts,0.3)
		EconomySystem._purse_outlook()
	var new_cost:=Time.get_ticks_usec()-started
	print("purse per-day cost: old finance %d us/yr, purse %d us/yr" % [old_cost,new_cost])
	assert_int(new_cost).is_less_equal(maxi(old_cost*2,2000))
