extends GdUnitTestSuite
## MAKING AND GOODS: THE FIRST CURRENCY (docs/PEOPLE_FIRST.md D;
## civilian_goods.gd, economy_system.gd, weapons_stock.gd, trade_ledger.gd
## goods_deal, enterprise.gd rung 1). Barter from year one with prices kept;
## makers' goods follow how many make and how well people work; goods buy
## resources, arms and people from another people at stated terms through
## the one ledger; arms are dear, kept in one stock with a small API for the
## military; stalls and workshops stand under barter once goods change hands.
## Quick: the world is three simulated peoples and ours at day 0, with stores
## set by hand; no day of any people is simulated.

const Goods:=preload("res://scripts/civilian_goods.gd")
const Arms:=preload("res://scripts/weapons_stock.gd")
const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Prices:=preload("res://scripts/trade_prices.gd")
const Business:=preload("res://scripts/enterprise.gd")
const War:=preload("res://scripts/war_loop.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,3))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	ids=[]
	for c:Dictionary in CivilizationSystem.civilizations: ids.append(String(c.id))
	GameState.settlement_site_committed=true; GameState.convoy_traveling=false; GameState.settlement_completed=["Hearth Circle"]
	GameState.water_metrics["intake_ratio"]=1.0
	FoodSystem.reset_for_new_world(); FoodSystem.initialize()
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for i in ids.size():
		var c:Dictionary=CivilizationSystem.civilizations[i]
		c["world_position"]=Vector2(150.0*float(i+1),0.0)
		c["alive"]=true
		(c.player_relation as Dictionary)["contact_level"]=2
		(c.player_relation as Dictionary)["opinion"]=0.1
		for other:String in (c.get("relations",{}) as Dictionary): ((c.relations as Dictionary)[other] as Dictionary)["opinion"]=0.1
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for v:Dictionary in WorldSimulation.world.civilizations: (v.player_relation as Dictionary)["contact_level"]=2)
	GameState.ensure_population_total(200)
	GameState.simulation_metrics["labor_efficiency"]=0.8
	# No arms in any old armoury unless a test puts them there.
	_clear_armoury("player")
	# Flint and stone in store: spears and bows are within the makers' reach.
	GameState.resource_stockpiles.merge({"Flint":20.0,"Stone":20.0},true)
	for id:String in ids: _clear_armoury(id)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

## Sets a people's stores (and makes each good known to its economy).
func _stores(owner:String,goods:Dictionary)->void:
	WorldSimulation.scoped(owner,func()->void:
		for good:String in goods:
			if good=="Food":
				var have:=WorldSimulation.food.total_stored()
				if float(goods[good])>have: WorldSimulation.food.receive_external_food(float(goods[good])-have)
				else: WorldSimulation.food.issue_for_obligation(have-float(goods[good]),"test","test")
			else: WorldSimulation.state.resource_stockpiles[good]=float(goods[good])
			WorldSimulation.state.economy_known_goods[good]=true)

func _stock(owner:String,good:String)->float:
	return float(WorldSimulation.scoped(owner,func()->float:
		return WorldSimulation.food.total_stored() if good=="Food" else float(WorldSimulation.state.resource_stockpiles.get(good,0.0))))

func _clear_armoury(owner:String)->void:
	WorldSimulation.scoped(owner,func()->void:
		var inventory:Dictionary=WorldSimulation.military.military_inventory
		for item in inventory.keys(): inventory[item]=0)

func _pop(owner:String)->int:
	return int(WorldSimulation.scoped(owner,func()->int:return int(WorldSimulation.state.population_total)))

func _work(owner:String,role:String,count:int)->void:
	WorldSimulation.scoped(owner,func()->void:WorldSimulation.state.population_allocations[role]=count)

## A pair that has found its meeting place: barter each season.
func _barter_pair(a:String,b:String)->Dictionary:
	Ledger._discover_pairs(int(GameState.elapsed_days))
	var p:=Ledger.pair(a,b)
	p["meet"]=0
	return p

func _materials(owner:String,amount:float)->void:
	_stores(owner,{"Timber":amount,"Fiber Plants":amount,"Clay":amount,"Stone":amount,"Flint":amount})


# --- 1. Barter from year one, with prices kept -----------------------------------

func test_barter_starts_in_year_one_with_prices_kept()->void:
	# A founding people: no tallies, no shared measures, no metal.
	assert_bool("tallies" in GameState.known_discoveries).is_false()
	assert_str(GameState.economy_stage).is_equal(EconomySystem.STAGE_SUBSISTENCE)
	assert_str(String(EconomySystem.STAGE_NAMES[GameState.economy_stage])).is_equal("Barter")
	_work("player","Defense",0)
	_work("player","Crafting",12)
	_work("player","Logistics",10)
	_materials("player",400.0)
	GameState.elapsed_days=20
	var made:=float(Goods.advance().made)
	assert_float(made).is_greater(0.0)
	EconomySystem.process_day({})
	var m:Dictionary=GameState.economy_metrics
	# Goods changed hands at the hearth, and the day's prices were kept.
	assert_float(float(m.goods_made)).is_equal_approx(made,0.0001)
	assert_float(float(m.goods_changed)).is_greater(0.0)
	assert_float(float(m.goods_changed)).is_equal_approx(made*float(m.market_access),0.0001)
	assert_int(int(m.goods_traded_days)).is_equal(1)
	assert_int(int(m.price_observations)).is_equal(1)
	assert_float(float(m.price_index)).is_greater(0.0)
	assert_bool(GameState.market_prices.has("Food")).is_true()
	assert_bool(GameState.market_prices.has(Goods.GOODS)).is_true()
	# Barter is most of how goods move before money, and it is said so.
	assert_float(float((m.exchange_mix as Dictionary).barter)).is_greater(0.26)
	assert_str(EconomySystem.settlement_medium()).contains("barter of goods")
	# Values are compared with strangers only with tallies and measures (or
	# money): a first meeting with another people still begins with gifts.
	assert_bool(EconomySystem.values_comparable_abroad()).is_false()
	# A second day keeps counting.
	GameState.elapsed_days=21
	Goods.advance()
	EconomySystem.process_day({})
	assert_int(int(GameState.economy_metrics.goods_traded_days)).is_equal(2)
	assert_int(int(GameState.economy_metrics.price_observations)).is_equal(2)


func test_market_access_grows_with_makers_and_carriers()->void:
	_work("player","Crafting",0)
	_work("player","Logistics",0)
	var bare:=EconomySystem._market_access({})
	_work("player","Crafting",10)
	var with_makers:=EconomySystem._market_access({})
	assert_float(with_makers-bare).is_equal_approx(EconomySystem.MAKERS_REACH,0.0001)
	_work("player","Logistics",10)
	var with_carriers:=EconomySystem._market_access({})
	assert_float(with_carriers-with_makers).is_equal_approx(EconomySystem.CARRIERS_REACH,0.0001)
	assert_float(EconomySystem.barter_reach()).is_equal_approx(EconomySystem.MAKERS_REACH+EconomySystem.CARRIERS_REACH,0.0001)


# --- 2. Makers' goods follow how many make and how well they work --------------------

func test_goods_scale_with_makers_and_how_well_people_work()->void:
	_work("player","Defense",0)
	_materials("player",400.0)
	_work("player","Crafting",10)
	GameState.elapsed_days=30
	var ten:=float(Goods.advance().made)
	# Ten makers at the usual pace: 10 x 0.18 x 5 x 0.8 = 7.2 a day with no
	# crafts known, times what the founders' crafts add (5 in 100 each).
	assert_float(ten).is_equal_approx(10.0*Goods.CRAFT_SHARE*Goods.BASE_RATE*0.8*Goods.technique_output(),0.0001)
	assert_float(ten/Goods.technique_output()).is_equal_approx(7.2,0.0001)
	# One maker in twenty: no more each than alone.
	assert_float(Goods.specialization()).is_equal(1.0)
	_materials("player",400.0)
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	_work("player","Crafting",20)
	GameState.elapsed_days=31
	# Twice the makers, a little more each (one in ten make: +5 in 100).
	assert_float(Goods.specialization()).is_equal_approx(1.05,0.0001)
	assert_float(float(Goods.advance().made)).is_equal_approx(ten*2.0*1.05,0.0001)
	# Half as well as people work: half the goods.
	_materials("player",400.0)
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	GameState.simulation_metrics["labor_efficiency"]=0.4
	GameState.elapsed_days=32
	assert_float(float(Goods.advance().made)).is_equal_approx(ten*1.05,0.0001)
	GameState.simulation_metrics["labor_efficiency"]=0.8
	_work("player","Crafting",10)
	# What making does now and with ten more makers, for the People view.
	var effect:=Goods.role_effect("Crafting")
	var n:Dictionary=effect.numbers
	assert_float(float(n.per_maker)).is_equal_approx(0.72*Goods.technique_output(),0.0001)
	assert_float(float(n.goods_day_ten_more)-float(n.goods_day)).is_equal_approx(7.2*Goods.technique_output(),0.0001)
	assert_str(String(effect.plus_ten)).starts_with("Ten more")
	# The People view's lines: twelve words or fewer.
	for line:String in [String(effect.now),String(effect.plus_ten)]:assert_int(line.split(" ",false).size()).override_failure_message(line).is_less_equal(12)


func test_a_people_all_in_on_making_gets_a_little_extra()->void:
	_work("player","Defense",0)
	_materials("player",3000.0)
	# One in four make: each makes 15 in 100 more, and the market holds half
	# again as many goods a head. No more than that however many make.
	_work("player","Crafting",50)
	assert_float(Goods.specialization()).is_equal_approx(1.0+Goods.SPECIALIZATION,0.0001)
	var held:=Goods.ceiling()
	_work("player","Crafting",100)
	assert_float(Goods.specialization()).is_equal_approx(1.0+Goods.SPECIALIZATION,0.0001)
	assert_float(Goods.ceiling()).is_equal_approx(held,0.0001)
	_work("player","Crafting",10)
	assert_float(held-Goods.ceiling()).is_equal_approx(GameState.population_exact*Goods.SURPLUS_PER_HEAD*Goods.HOLD_MORE,0.001)
	# Arms are as dear for a making people: the set's maker-days do not fall.
	_work("player","Crafting",50)
	assert_float(float(Arms.cost_per_fighter().maker_days)).is_equal(10.0)


func test_barter_goods_leave_the_builders_share_of_materials()->void:
	_work("player","Defense",0)
	_work("player","Crafting",40)
	# Timber only, and less than the stores want: homes are stocked from it,
	# but nothing is made for barter from the builders' share.
	GameState.resource_stockpiles={"Timber":100.0}
	GameState.elapsed_days=40
	var report:=Goods.advance()
	var homes:=Goods.target()*1.2
	assert_float(float(report.made)).is_equal_approx(homes,0.0001)
	assert_float(float(report.for_barter)).is_equal(0.0)
	# Plenty of timber: the rest of the makers' day goes to barter.
	GameState.resource_stockpiles["Timber"]=2000.0
	GameState.elapsed_days=41
	report=Goods.advance()
	assert_float(float(report.for_barter)).is_greater(0.0)
	var floor_:=float(EconomySystem._desired_stock("Timber",GameState.population_exact))*Goods.BARTER_MATERIAL_FLOOR
	assert_float(float(GameState.resource_stockpiles.Timber)).is_greater_equal(floor_-0.0001)


# --- 3. Goods buy resources, arms and people from another people ----------------------

func test_goods_buy_resources_at_stated_terms_through_the_ledger()->void:
	var a:=String(ids[0])
	_stores("player",{Goods.GOODS:300.0,"Timber":0.0})
	_stores(a,{Goods.GOODS:0.0,"Timber":900.0})
	_barter_pair("player",a)
	var t:=Ledger.deal_terms("player",a,"Timber",50.0)
	assert_bool(bool(t.ok)).override_failure_message(String(t.why)).is_true()
	# Their price, a fifth over, in goods at their price for goods.
	var each:=Prices.value("Timber",a)*Ledger.DEAL_PREMIUM/Prices.value(Goods.GOODS,a)
	assert_float(float(t.each)).is_equal_approx(each,0.0001)
	assert_float(float(t.count)).is_equal_approx(50.0,0.0001)
	assert_float(float(t.goods)).is_equal_approx(50.0*each,0.0001)
	# A reading never writes.
	assert_float(_stock("player",Goods.GOODS)).is_equal(300.0)
	var goods_before:=_stock("player",Goods.GOODS)+_stock(a,Goods.GOODS)
	var timber_before:=_stock("player","Timber")+_stock(a,"Timber")
	var done:=Ledger.goods_deal("player",a,"Timber",50.0)
	assert_bool(bool(done.ok)).is_true()
	# Real goods both ways, and nothing made or lost.
	assert_float(300.0-_stock("player",Goods.GOODS)).is_equal_approx(float(t.goods),0.0001)
	assert_float(_stock(a,Goods.GOODS)).is_equal_approx(float(t.goods),0.0001)
	assert_float(_stock("player","Timber")).is_equal_approx(50.0,0.0001)
	assert_float(_stock("player",Goods.GOODS)+_stock(a,Goods.GOODS)).is_equal_approx(goods_before,0.0001)
	assert_float(_stock("player","Timber")+_stock(a,"Timber")).is_equal_approx(timber_before,0.0001)
	# Booked in the one ledger: the pair's flows, its kinds and its deals.
	var p:=Ledger.pair("player",a)
	var dir:="ab" if String(p.a)=="player" else "ba"
	var back:="ba" if dir=="ab" else "ab"
	assert_float(float(((p.acc as Dictionary)[dir] as Dictionary).get(Goods.GOODS,0.0))).is_equal_approx(float(t.goods),0.0001)
	assert_float(float(((p.acc as Dictionary)[back] as Dictionary).get("Timber",0.0))).is_equal_approx(50.0,0.0001)
	assert_bool((p.kinds as Dictionary).has(dir+":deal")).is_true()
	assert_str(String(((p.deals as Array)[0] as Dictionary).what)).is_equal("Timber")
	assert_str(String(done.said)).contains("50 timber")
	# Goods do not buy goods (no market of goods for goods).
	assert_bool(bool(Ledger.deal_terms("player",a,Goods.GOODS,5.0).ok)).is_false()


func test_goods_buy_only_where_the_peoples_barter()->void:
	var a:=String(ids[0])
	_stores("player",{Goods.GOODS:300.0})
	_stores(a,{"Timber":900.0})
	Ledger._discover_pairs(0)
	# Strangers still in their seasons of gifts: no deal, and it says why.
	var t:=Ledger.deal_terms("player",a,"Timber",10.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("gifts")
	_barter_pair("player",a)
	assert_bool(bool(Ledger.deal_terms("player",a,"Timber",10.0).ok)).is_true()
	# At war, no trader crosses.
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["at_war"]=true
	t=Ledger.deal_terms("player",a,"Timber",10.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("war")
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["at_war"]=false
	# Too few goods: the terms say how many a load costs.
	_stores("player",{Goods.GOODS:Goods.target()})
	t=Ledger.deal_terms("player",a,"Timber",10.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("too few goods")


func test_goods_buy_arms_from_a_people_with_arms_to_spare()->void:
	var a:=String(ids[0])
	_work(a,"Defense",4)
	_stores(a,{Arms.GOOD:20.0,Goods.GOODS:0.0})
	_stores("player",{Goods.GOODS:400.0})
	_barter_pair("player",a)
	# They keep arms for their own watch (with a tenth over): 20 - 4 x 1.1.
	var t:=Ledger.deal_terms("player",a,Arms.GOOD,30.0)
	assert_bool(bool(t.ok)).override_failure_message(String(t.why)).is_true()
	assert_float(float(t.most)).is_equal(15.0)
	assert_float(float(t.count)).is_equal(15.0)
	assert_float(float(t.each)).is_equal_approx(Prices.value(Arms.GOOD,a)*Ledger.DEAL_PREMIUM/Prices.value(Goods.GOODS,a),0.0001)
	# Arms are dear: a set costs more goods than a load of anything else.
	assert_float(float(t.each)).is_greater(float(Ledger.deal_terms("player",a,"Timber",1.0).each)*10.0)
	var held_before:=Arms.weapons_held()
	var done:=Ledger.goods_deal("player",a,Arms.GOOD,30.0)
	assert_bool(bool(done.ok)).is_true()
	assert_int(Arms.weapons_held()-held_before).is_equal(15)
	assert_float(_stock(a,Arms.GOOD)).is_equal_approx(5.0,0.0001)
	assert_float(400.0-_stock("player",Goods.GOODS)).is_equal_approx(15.0*float(t.each),0.0001)
	assert_str(String(done.said)).contains("Arms for 15 fighters")


## Their people eat this share of what they need.
func _eats(owner:String,share:float)->void:
	WorldSimulation.scoped(owner,func()->void:WorldSimulation.state.simulation_metrics["food_intake_ratio"]=share)

func test_families_come_only_from_a_people_that_cannot_feed_them()->void:
	var a:=String(ids[0])
	WorldSimulation.scoped(a,func()->void:WorldSimulation.state.ensure_population_total(500))
	_stores("player",{Goods.GOODS:3000.0})
	_barter_pair("player",a)
	# A well-fed people lets no one go, whatever we offer, all year.
	_eats(a,1.0)
	var t:=Ledger.deal_terms("player",a,"families",50.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("feed their own")
	var theirs:=_pop(a)
	for season in 4:
		GameState.elapsed_days=10+season*Ledger.FAMILY_DAYS
		assert_bool(bool(Ledger.goods_deal("player",a,"families",50.0).ok)).is_false()
	assert_int(_pop(a)).is_equal(theirs)
	# Hungry (eating 80 in 100 of their need): only as many as their food
	# cannot feed, at most 2 in 100 of them a deal, at a person's year of work.
	_eats(a,0.8)
	GameState.elapsed_days=400
	t=Ledger.deal_terms("player",a,"families",50.0)
	assert_bool(bool(t.ok)).override_failure_message(String(t.why)).is_true()
	assert_float(float(t.most)).is_equal(floorf(minf(500.0*(Ledger.FAMILY_HUNGRY-0.8),500.0*Ledger.FAMILY_SHARE)))
	assert_float(float(t.most)).is_equal(10.0)
	assert_float(float(t.each)).is_equal_approx(Ledger.person_worth(a)/Prices.value(Goods.GOODS,a),0.0001)
	assert_float(float(t.each)).is_greater_equal(Ledger.FAMILY_YEAR_DAYS*Prices.value("Food",a)/Prices.value(Goods.GOODS,a)-0.0001)
	assert_str(String(t.words)).contains("children with them")
	var ours:=_pop("player")
	theirs=_pop(a)
	var opinion:=Ledger.opinion(a,"player")
	var done:=Ledger.goods_deal("player",a,"families",50.0)
	assert_bool(bool(done.ok)).is_true()
	# The same people leave them and arrive among us: counts add up.
	assert_int(int(done.count)).is_equal(10)
	assert_int(_pop("player")-ours).is_equal(10)
	assert_int(theirs-_pop(a)).is_equal(10)
	assert_float(3000.0-_stock("player",Goods.GOODS)).is_equal_approx(10.0*float(t.each),0.0001)
	# Families moving warm no one: a repeat is no easier.
	assert_float(Ledger.opinion(a,"player")).is_equal_approx(opinion,0.000001)
	# One families deal a pair a season.
	t=Ledger.deal_terms("player",a,"families",50.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("this season")
	# A year from the first deal, from a people that stays hungry: four deals
	# at most, each at most 2 in 100 of them.
	var came:=10
	var deals:=1
	for day in range(401,765):
		GameState.elapsed_days=day
		var more:=Ledger.goods_deal("player",a,"families",50.0)
		if bool(more.ok):
			came+=int(more.count)
			deals+=1
	assert_int(deals).is_equal(4)
	assert_int(came).is_less_equal(40)
	assert_int(_pop(a)).is_greater_equal(Ledger.FAMILY_KEEP)
	# A people that thinks ill of us keeps its families.
	GameState.elapsed_days=2000
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["opinion"]=-0.2
	assert_bool(bool(Ledger.deal_terms("player",a,"families",1.0).ok)).is_false()


func test_goods_ransom_our_people_taken_captive_from_the_record()->void:
	var a:=String(ids[0])
	_stores("player",{Goods.GOODS:400.0})
	_barter_pair("player",a)
	assert_bool(bool(Ledger.deal_terms("player",a,"captives",1.0).ok)).is_false()
	# An older save: the war's log tells of three taken, but no count was kept.
	(War.state().log as Array).push_front({"day":0,"civ":a,"kind":"raid","text":"","captives":3})
	var old:=Ledger.deal_terms("player",a,"captives",3.0)
	assert_bool(bool(old.ok)).is_false()
	assert_str(String(old.why)).contains("before any count was kept")
	# Their raid takes three of ours now: kept with them, ages as taken.
	var ours:=_pop("player")
	var theirs:=_pop(a)
	var taken:=War._our_captives_lost(3,a)
	assert_int(taken).is_equal(3)
	assert_int(ours-_pop("player")).is_equal(3)
	assert_int(Ledger.captives_held(a,"player")).is_equal(3)
	var ages:Dictionary=Ledger.captive_pool(a,"player").c
	var counted:=0.0
	for key in ages: counted+=float(ages[key])
	assert_float(counted).is_equal_approx(3.0,0.0001)
	var t:=Ledger.deal_terms("player",a,"captives",3.0)
	assert_bool(bool(t.ok)).override_failure_message(String(t.why)).is_true()
	assert_float(float(t.each)).is_equal_approx(Ledger.RANSOM_RATIONS*Prices.value("Food",a)/Prices.value(Goods.GOODS,a),0.0001)
	var done:=Ledger.goods_deal("player",a,"captives",3.0)
	assert_bool(bool(done.ok)).is_true()
	# Home again; none of their own people left them.
	assert_int(_pop("player")).is_equal(ours)
	assert_int(_pop(a)).is_equal(theirs)
	assert_int(Ledger.captives_held(a,"player")).is_equal(0)
	assert_str(String(done.said)).contains("3 of ours ransomed home")


# --- 4. Arms: always dear, one stock, a small API --------------------------------------

func test_arms_cost_per_fighter_is_high_and_rises_with_the_age()->void:
	var cost:=Arms.cost_per_fighter()
	assert_str(String(cost.kind)).is_equal("a spear and a bow")
	assert_float(float(cost.maker_days)).is_equal(10.0)
	assert_float(float((cost.materials as Dictionary).Timber)).is_equal(1.4)
	# Ten days of a maker's goods and the materials: worth some eight goods,
	# near fifty rations (a month and a half of a person's food).
	# What the engine forgoes: the goods ten maker-days make at full pace (a
	# slower people takes more days and makes fewer goods a day: it cancels).
	assert_float(float(cost.goods_forgone)).is_equal_approx(10.0*Goods.goods_per_maker_day_at_full_pace(),0.0001)
	GameState.simulation_metrics["labor_efficiency"]=0.4
	assert_float(float(Arms.cost_per_fighter().goods_forgone)).is_equal_approx(float(cost.goods_forgone),0.0001)
	GameState.simulation_metrics["labor_efficiency"]=0.8
	assert_float(float(cost.worth_goods)).is_greater(8.0)
	assert_float(float(cost.worth_rations)).is_between(40.0,80.0)
	assert_float(Arms.weapons_quality()).is_equal(1.0)
	# Bronze learned, with copper and tin in store.
	GameState.resource_stockpiles.merge({"Copper Ore":50.0,"Tin Ore":10.0,"Timber":50.0,"Fiber Plants":50.0},true)
	GameState.known_discoveries.append("bronze_weaponry"); GameState.discovery_adoption["bronze_weaponry"]=0.5
	var bronze:=Arms.cost_per_fighter()
	assert_float(float(bronze.maker_days)).is_equal(16.0)
	assert_bool((bronze.materials as Dictionary).has("Copper Ore")).is_true()
	assert_float(Arms.weapons_quality()).is_greater(1.0)


func test_the_weapons_stock_api_for_the_military()->void:
	_work("player","Defense",30)
	_stores("player",{Arms.GOOD:12.0})
	# The old armoury's spears and bows count as held: nothing moved.
	MilitaryCampaign.military_inventory["spear"]=5
	MilitaryCampaign.military_inventory["bow"]=2
	MilitaryCampaign.military_inventory["improvised"]=40
	assert_int(Arms.weapons_held()).is_equal(19)
	# Held for the watch's own kit: the made sets and the armoury's of it.
	var kit:=Arms.kit_item()
	assert_int(Arms.weapons_held(kit)).is_equal(12+int(MilitaryCampaign.military_inventory.get(kit,0)))
	assert_int(Arms.arms_wanted()).is_equal(30-Arms.weapons_held(kit))
	# The watch carries what its formations carry: none yet.
	assert_int(Arms.weapons_issued()).is_equal(0)
	# Taken with no kit named: made sets first, then the old armoury, the cheapest kit first.
	var cheaper:="spear" if Arms._kit_worth("spear")<Arms._kit_worth("bow") else "bow"
	var dearer:="bow" if cheaper=="spear" else "spear"
	var dearer_count:=int(MilitaryCampaign.military_inventory[dearer])
	var first:=12+int(MilitaryCampaign.military_inventory[cheaper])
	assert_int(Arms.take_weapons(first)).is_equal(first)
	assert_float(_stock("player",Arms.GOOD)).is_equal(0.0)
	assert_int(int(MilitaryCampaign.military_inventory[cheaper])).is_equal(0)
	assert_int(int(MilitaryCampaign.military_inventory[dearer])).is_equal(dearer_count)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(40)
	assert_int(Arms.weapons_held()).is_equal(dearer_count)
	# Never more than is held; the arms record counts what passed.
	assert_int(Arms.take_weapons(50)).is_equal(dearer_count)
	assert_int(Arms.weapons_held()).is_equal(0)
	assert_float(float(Arms.record().issued)).is_equal(19.0)
	# Made sets back into store (never more than the record took), or lost with the fallen.
	assert_int(Arms.return_weapons(5)).is_equal(5)
	assert_int(Arms.weapons_held()).is_equal(5)
	assert_int(Arms.lose_weapons(4)).is_equal(4)
	assert_float(float(Arms.record().issued)).is_equal(10.0)
	assert_float(float(Arms.record().lost)).is_equal(4.0)
	assert_int(Arms.return_weapons(100)).is_equal(10)
	assert_float(float(Arms.record().issued)).is_equal(0.0)
	# A kit named goes back to the armoury, as that kit (never traded).
	assert_int(Arms.return_weapons(3,"bow")).is_equal(3)
	assert_int(int(MilitaryCampaign.military_inventory.bow)).is_equal(3)


func test_taking_arms_is_exact_with_part_sets()->void:
	_work("player","Defense",30)
	_stores("player",{Arms.GOOD:2.6})
	MilitaryCampaign.military_inventory["spear"]=3
	var before:=Arms.held_exact()
	assert_float(before).is_equal_approx(5.6,0.0001)
	assert_int(Arms.take_weapons(3)).is_equal(3)
	# 2.6 made sets and one spear: the 0.6 left of the spear stays in store.
	assert_float(Arms.held_exact()).is_equal_approx(before-3.0,0.0001)
	assert_int(int(MilitaryCampaign.military_inventory.spear)).is_equal(2)
	assert_float(Arms.stock()).is_equal_approx(0.6,0.0001)


func test_makers_arm_the_watch_at_a_high_cost_in_goods()->void:
	_work("player","Defense",10)
	_work("player","Crafting",20)
	_materials("player",500.0)
	GameState.elapsed_days=50
	var plan:=Arms.plan_day()
	assert_int(int(plan.wanted)).is_equal(10)
	assert_float(float(plan.share)).is_equal(Arms.ARMS_SHARE)
	var report:=Goods.advance()
	# A fifth of the makers on arms at the usual pace: 20 x 0.2 x 0.8 / 10 = 0.32 sets a day.
	assert_float(float(report.arms_made)).is_equal_approx(20.0*Arms.ARMS_SHARE*0.8/10.0,0.0001)
	assert_float(float(report.arms_hands)).is_equal_approx(20.0*Arms.ARMS_SHARE,0.0001)
	assert_float(Arms.stock()).is_equal_approx(float(report.arms_made),0.0001)
	# Those hands made no goods today, and are out of every other making work
	# while they make arms (the workshops, tools and materials).
	assert_float(float(report.made)).is_equal_approx((20.0-20.0*Arms.ARMS_SHARE)*Goods.CRAFT_SHARE*Goods.BASE_RATE*0.8*Goods.technique_output()*Goods.specialization(),0.0001)
	assert_float(GameState.effective_workers("Crafting")).is_equal_approx(20.0-20.0*Arms.ARMS_SHARE,0.0001)
	assert_float(Goods.makers()).is_equal_approx(20.0,0.0001)
	# At war, twice the makers; and the war is read the same from their side.
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["at_war"]=true
	GameState.elapsed_days=51
	assert_float(float(Arms.plan_day().share)).is_equal(Arms.WAR_SHARE)
	assert_bool(bool(WorldSimulation.scoped(String(ids[0]),func()->bool:return Arms.at_war()))).is_true()
	assert_bool(bool(WorldSimulation.scoped(String(ids[1]),func()->bool:return Arms.at_war()))).is_false()
	(CivilizationSystem.civilizations[0].player_relation as Dictionary)["at_war"]=false
	# The watch armed: no more arms are made.
	_stores("player",{Arms.GOOD:10.0})
	GameState.elapsed_days=52
	assert_float(float(Arms.plan_day().share)).is_equal(0.0)
	assert_float(float(Goods.advance().arms_made)).is_equal(0.0)


func test_arms_makers_are_counted_with_every_bonus_in()->void:
	# A hundred makers with a genius of making (each counts for 1.4), a fifth on arms.
	GameState.ensure_population_total(1000)
	_work("player","Crafting",100)
	_work("player","Defense",400)
	_materials("player",5000.0)
	WorldSimulation.figures.genius_bonus={"Crafting":0.4}
	var all_makers:=GameState.effective_workers("Crafting")
	assert_float(all_makers).is_equal_approx(140.0,0.0001)
	GameState.elapsed_days=70
	Arms.plan_day()
	var report:=Goods.advance()
	assert_float(float(report.arms_hands)).is_equal_approx(28.0,0.0001)
	# The rest of the making work counts the other 112, and all the makers are still 140.
	assert_float(GameState.effective_workers("Crafting")).is_equal_approx(112.0,0.0001)
	assert_float(Goods.makers()).is_equal_approx(140.0,0.0001)
	# The tools-and-materials count leaves out the same share (a fifth).
	assert_float(Goods.arms_fraction(GameState)).is_equal_approx(0.2,0.0001)
	WorldSimulation.figures.genius_bonus={}


func test_goods_to_trade_leave_what_makers_must_make_again()->void:
	GameState.resource_stockpiles[Goods.GOODS]=Goods.target()+50.0
	# Beyond the homes' need, less the goods kept for the first plant and the learners.
	assert_float(Goods.spare()).is_equal_approx(maxf(0.0,50.0-Goods.capital_reserve()-float(preload("res://scripts/research_600_catalog.gd").learners_goods().wanted)),0.0001)
	assert_float(Goods.spare()).is_less_equal(50.0)


func test_arms_trade_as_a_good_between_peoples()->void:
	var a:=String(ids[0])
	assert_bool(Ledger.ARMS in Ledger.GOODS).is_true()
	_work(a,"Defense",2)
	_stores(a,{Arms.GOOD:30.0})
	_work("player","Defense",20)
	_stores("player",{Arms.GOOD:0.0})
	Ledger._refresh_report(a,0)
	Ledger._refresh_report("player",0)
	# They offer what they hold over their watch's need; we want what ours lacks.
	assert_float(Ledger.offer_of(Ledger.report(a).g,Arms.GOOD)).is_greater(0.0)
	assert_float(Ledger.want_of(Ledger.report("player").g,Arms.GOOD)).is_equal_approx(20.0,0.0001)
	# The old armoury arms the watch and is never traded, paid or given away.
	WorldSimulation.scoped(a,func()->void:WorldSimulation.military.military_inventory["spear"]=500)
	_stores(a,{Arms.GOOD:0.0})
	assert_float(Ledger.spare_of(a,Arms.GOOD)).is_equal(0.0)
	_barter_pair("player",a)
	_stores("player",{Goods.GOODS:900.0})
	assert_bool(bool(Ledger.deal_terms("player",a,Arms.GOOD,5.0).ok)).is_false()
	# Paying in kind (tolls, tribute, terms) never takes arms unless chosen.
	_stores(a,{Arms.GOOD:30.0,Goods.GOODS:0.0,"Timber":0.0,"Stone":0.0,"Flint":0.0,"Clay":0.0,"Fiber Plants":0.0,"Salt":0.0})
	Ledger._refresh_report(a,1)
	Ledger.pay_in_kind(a,"player",50.0,"","tribute")
	assert_float(_stock(a,Arms.GOOD)).is_equal(30.0)
	assert_int(int(WorldSimulation.scoped(a,func()->int:return int(WorldSimulation.military.military_inventory.spear)))).is_equal(500)


# --- 5. Stalls and workshops under barter ---------------------------------------------

func test_stalls_and_workshops_stand_under_barter_once_goods_change_hands()->void:
	GameState.enterprise={}
	assert_str(GameState.economy_stage).is_equal("subsistence")
	assert_int(Business.rung()).is_equal(0)
	assert_str(Business.next_needs()).contains("goods changing hands")
	_work("player","Defense",0)
	_work("player","Crafting",12)
	_materials("player",400.0)
	GameState.elapsed_days=5
	Goods.advance()
	EconomySystem.process_day({})
	assert_bool(Business.goods_change_hands()).is_true()
	assert_bool(Business.prices_kept()).is_true()
	assert_int(Business.rung()).is_equal(1)
	assert_str(Business.rung_name(Business.rung())).is_equal("Stalls and hired workshops")
	# Merchant houses still wait on weighed metal or coin.
	GameState.known_discoveries.append("craft_guilds"); GameState.discovery_adoption["craft_guilds"]=1.0
	assert_int(Business.rung()).is_equal(1)
	assert_str(Business.next_needs()).contains("weighed metal or coin")


# --- 6. Every people by the same rules; older saves -----------------------------------

func test_a_computer_people_buys_arms_with_goods_by_the_same_rules()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	_work(a,"Defense",20)
	_stores(a,{Arms.GOOD:0.0,Goods.GOODS:600.0})
	_work(b,"Defense",1)
	_stores(b,{Arms.GOOD:25.0,Goods.GOODS:0.0})
	Ledger._discover_pairs(0)
	var p:=Ledger.pair(a,b)
	p["meet"]=0
	# Partners: a pair with goods moving between them.
	(p.val as Dictionary)["ab"]=5.0
	var made:=Stances.goods_buys(a,30)
	assert_int(made.size()).is_greater_equal(1)
	assert_str(String((made[0] as Dictionary).what)).is_equal(Arms.GOOD)
	assert_float(_stock(a,Arms.GOOD)).is_equal(float(Stances.ARMS_BUY_MAX))
	assert_float(_stock(b,Goods.GOODS)).is_greater(0.0)


func test_a_fed_people_takes_in_families_from_a_hungry_one_for_goods()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	_work(a,"Defense",0)
	_stores(a,{Goods.GOODS:3000.0})
	WorldSimulation.scoped(b,func()->void:WorldSimulation.state.ensure_population_total(400))
	for id:String in ids+["player"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.simulation_metrics["food_days"]=30.0
			WorldSimulation.state.simulation_metrics["food_intake_ratio"]=1.0)
	Ledger._discover_pairs(0)
	Ledger.pair(a,b)["meet"]=0
	# Both fed: nobody leaves.
	assert_int(Stances.goods_buys(a,30).size()).is_equal(0)
	# Their people go hungry: as many as the god's people could take, on the same terms.
	_eats(b,0.7)
	var theirs:=_pop(b)
	var ours:=_pop(a)
	var terms:=Ledger.deal_terms(a,b,"families",1000.0)
	var made:=Stances.goods_buys(a,60)
	assert_int(made.size()).is_equal(1)
	assert_str(String((made[0] as Dictionary).what)).is_equal("families")
	var came:=int((made[0] as Dictionary).count)
	assert_int(came).is_equal(int(terms.count))
	assert_int(came).is_equal(8)
	assert_int(theirs-_pop(b)).is_equal(came)
	assert_int(_pop(a)-ours).is_equal(came)
	# Not again this season.
	assert_int(Stances.goods_buys(a,61).size()).is_equal(0)


func test_older_saves_keep_their_goods_and_arms_without_a_jump()->void:
	# An older record: no arms, a seven-line report.
	GameState.civilian_goods={"initialized":true,"last_day":3,"migrated":true,"report":{"workers":1.0,"made":1.0,"worn":0.1,"inputs":{},"coverage":1.0,"target":4.0,"reason":"Stock target met"}}
	assert_bool(Goods.valid(GameState.civilian_goods)).is_true()
	GameState.resource_stockpiles[Goods.GOODS]=7.5
	MilitaryCampaign.military_inventory["bow"]=6
	assert_int(Arms.weapons_held()).is_equal(6)
	assert_int(Arms.weapons_issued()).is_equal(0)
	assert_float(Goods.stock()).is_equal(7.5)
	# A new day's record still passes the save's check.
	_work("player","Crafting",5)
	_materials("player",100.0)
	GameState.elapsed_days=4
	Goods.advance()
	assert_bool(Goods.valid(GameState.civilian_goods)).is_true()
	assert_int(int(MilitaryCampaign.military_inventory.bow)).is_equal(6)
