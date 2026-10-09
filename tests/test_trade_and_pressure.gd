extends GdUnitTestSuite
## TRADE AND ECONOMIC PRESSURE BETWEEN PEOPLES (trade_ledger.gd,
## trade_stances.gd, trade_words.gd, court_trade.gd, hud/trade_board.gd):
## goods really move between stores, before money and after it, by one price
## table; volumes scale with the people; the dependence ledger reads true;
## every stance has its stated effects and costs on both ledgers; answers are
## rolled once with stated odds; rivals use the same stances; the page, the
## War screen line and the court say it in few words; it all survives a save;
## settlement keeps its schedule over years without spam or a rising cost.
## Quick: the world is three simulated peoples and ours, at day 0, with their
## stores set by hand; no day of any people is simulated.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Words:=preload("res://scripts/trade_words.gd")
const Prices:=preload("res://scripts/trade_prices.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(31337)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,3))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	ids=[]
	for c:Dictionary in CivilizationSystem.civilizations: ids.append(String(c.id))
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	FoodSystem.reset_for_new_world(); FoodSystem.initialize()
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for i in ids.size():
		var c:Dictionary=CivilizationSystem.civilizations[i]
		c["world_position"]=Vector2(150.0*float(i+1),0.0)
		c["alive"]=true
		(c.player_relation as Dictionary)["contact_level"]=2; (c.player_relation as Dictionary)["home_location_known"]=true
		(c.player_relation as Dictionary)["opinion"]=0.1
		for other:String in (c.get("relations",{}) as Dictionary): ((c.relations as Dictionary)[other] as Dictionary)["opinion"]=0.1
	# Every simulated people knows the others and us.
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for v:Dictionary in WorldSimulation.world.civilizations: (v.player_relation as Dictionary)["contact_level"]=2)
	_stores("player",{"Food":6000.0,"Flint":100.0,"Timber":40.0,"Stone":10.0,"Salt":0.0})
	for id:String in ids: _stores(id,{"Food":5000.0,"Flint":0.0,"Timber":40.0,"Salt":60.0})

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

func _people(owner:String,count:int)->void:
	WorldSimulation.scoped(owner,func()->void: WorldSimulation.state.ensure_population_total(count))

## One settlement of a pair now (its due day brought to today).
func _settle(a:String,b:String,day:int=10)->Dictionary:
	GameState.elapsed_days=day
	for id:String in ids: WorldSimulation.actors[id].systems.GameState.elapsed_days=day
	Ledger._discover_pairs(day)
	var p:=Ledger.pair(a,b)
	Ledger._refresh_report(a,day); Ledger._refresh_report(b,day)
	Ledger._settle(p,day)
	return p

# --------------------------------------------------------------------------

func test_gift_and_barter_move_real_goods_before_money()->void:
	var a:=String(ids[0])
	var our_flint:=_stock("player","Flint")
	var their_flint:=_stock(a,"Flint")
	var p:=_settle("player",a)
	assert_str(String(p.form)).is_equal("gift")
	var sent:=our_flint-_stock("player","Flint")
	var got:=_stock(a,"Flint")-their_flint
	# Real goods left our stores and reached theirs, the same amount.
	assert_float(sent).is_greater(0.0)
	assert_float(got).is_equal_approx(sent,0.0001)
	assert_float(float(p.last.ab.get("Flint",p.last.ba.get("Flint",0.0)))).is_equal_approx(sent,0.01)
	# A gift is remembered as owed, and warms them.
	assert_float(absf(float(p.owed))).is_greater(0.0)
	# Their salt came the other way (we lack it and know it).
	assert_float(_stock("player","Salt")).is_greater(0.0)
	# After seasons of gifts both ways, a meeting place: barter.
	p["gift_seasons"]=Ledger.MEETING_SEASONS-1
	_stores("player",{"Flint":100.0,"Salt":0.0})
	_stores(a,{"Flint":0.0,"Salt":60.0})
	p["next"]=0
	Ledger._settle(p,101)
	assert_int(int(p.meet)).is_equal(101)
	_stores("player",{"Flint":100.0,"Salt":0.0})
	_stores(a,{"Flint":0.0,"Salt":60.0})
	Ledger._settle(p,192)
	assert_str(String(p.form)).is_equal("barter")
	# Goods for goods: each side's load within a quarter of the other's.
	var vab:=float(p.last.trade_ab); var vba:=float(p.last.trade_ba)
	assert_float(minf(vab,vba)).is_greater(0.0)
	assert_float(maxf(vab,vba)/minf(vab,vba)).is_less_equal(1.0+Ledger.BARTER_SLACK+0.01)



## Met but not found: a people whose home is not on our map gets no goods
## from us and sends none, until its home is found.
func test_no_trade_with_a_people_whose_home_we_have_not_found()->void:
	var a:=String(ids[0])
	(Ledger.civ(a).player_relation as Dictionary)["home_location_known"]=false
	assert_str(Ledger.blocked("player",a)).is_equal("unlocated")
	var our_flint:=_stock("player","Flint")
	var their_salt:=_stock(a,"Salt")
	var p:=_settle("player",a)
	assert_float(_stock("player","Flint")).is_equal_approx(our_flint,0.0001)
	assert_float(_stock(a,"Salt")).is_equal_approx(their_salt,0.0001)
	assert_float(float(p.total.ab)+float(p.total.ba)).is_equal(0.0)
	# Found: the road opens.
	(Ledger.civ(a).player_relation as Dictionary)["home_location_known"]=true
	assert_str(Ledger.blocked("player",a)).is_equal("")

## The pair's direction from `from` to `to` ("ab" or "ba").
func _dir(p:Dictionary,from:String)->String:
	return "ab" if String(p.a)==from else "ba"

func _set_stage(owner:String,stage:String)->void:
	WorldSimulation.scoped(owner,func()->void: WorldSimulation.state.economy_stage=stage)

func test_priced_trade_after_money_by_one_price_table()->void:
	var a:=String(ids[0])
	_set_stage("player","weighed_metal"); _set_stage(a,"weighed_metal")
	_stores("player",{"Flint":100.0,"Salt":0.0,"Coin":0.0})
	_stores(a,{"Flint":0.0,"Salt":0.0,"Coin":500.0})
	var p:=_settle("player",a)
	assert_str(String(p.form)).is_equal("silver")
	var flint:=float((p.last[_dir(p,"player")] as Dictionary).get("Flint",0.0))
	assert_float(flint).is_greater(0.0)
	# They paid in weighed silver from their purse into ours: real on both ledgers.
	var paid:=_stock("player","Coin")
	assert_float(paid).is_greater(0.0)
	assert_float(500.0-_stock(a,"Coin")).is_equal_approx(paid,0.001)
	# At our own price for flint: one table, the seller's (economy_system's, or
	# the good it stands on: two loads of stone).
	assert_float(paid).is_equal_approx(flint*Prices.value("Flint","player"),0.01)
	assert_float(Prices.value("Flint","player")).is_equal_approx(2.0*float(EconomySystem.BASE_VALUES.Stone),0.001)
	# Coin, once both mint it: the one door for money (pay) moves it from
	# purse to purse, never more than the payer holds, and none is lost.
	_set_stage("player","currency"); _set_stage(a,"currency")
	WorldSimulation.scoped(a,func()->void: WorldSimulation.state.public_treasury=40.0)
	var ours:=Ledger.purse_balance("player")
	assert_float(Ledger.pay(a,"player",100.0,"test")).is_equal_approx(40.0,0.001)
	assert_float(Ledger.purse_balance("player")-ours).is_equal_approx(40.0,0.001)
	assert_float(Ledger.purse_balance(a)).is_equal_approx(0.0,0.001)
	assert_float(Ledger.pay(a,"player",10.0,"test")).is_equal(0.0)
	# No second table: pacts and envoys read the same one.
	assert_bool((load("res://scripts/trade_pacts.gd") as GDScript).get_script_constant_map().has("VALUES")).is_false()
	assert_bool((load("res://scripts/envoy_requests.gd") as GDScript).get_script_constant_map().has("VALUES")).is_false()
	assert_float(preload("res://scripts/trade_pacts.gd").worth("Timber")).is_equal_approx(Prices.value("Timber","player"),0.0001)

func test_volumes_scale_with_population()->void:
	var a:=String(ids[0])
	var small:=_settle("player",a)
	var q1:=float((small.last[_dir(small,"player")] as Dictionary).get("Flint",0.0))
	assert_float(q1).is_greater(0.0)
	_people("player",1200); _people(a,1200)
	_stores("player",{"Flint":1000.0,"Salt":0.0,"Food":60000.0,"Timber":400.0,"Stone":100.0})
	_stores(a,{"Flint":0.0,"Salt":600.0,"Food":50000.0,"Timber":400.0})
	var big:=Ledger.pair("player",a)
	Ledger._refresh_report("player",101); Ledger._refresh_report(a,101)
	Ledger._settle(big,101)
	var q2:=float((big.last[_dir(big,"player")] as Dictionary).get("Flint",0.0))
	# Ten times the people, about ten times the goods (capacity, surplus and need all scale).
	assert_float(q2/q1).is_between(8.0,12.0)
	# And the carriers' capacity scales from 120 to a billion alike.
	var ra:={"pop":120.0,"log":0.3,"tc":0.0}; var rb:={"pop":150.0,"log":0.3,"tc":0.0}
	var huge_a:={"pop":1.2e9,"log":0.3,"tc":0.0}; var huge_b:={"pop":1.5e9,"log":0.3,"tc":0.0}
	var ratio:=Ledger.capacity("player",a,"coin",30,huge_a,huge_b)/Ledger.capacity("player",a,"coin",30,ra,rb)
	assert_float(ratio).is_equal_approx(1.0e7,1.0)

func test_dependence_ledger_reads_share_and_days()->void:
	var a:=String(ids[0])
	var p:=_settle("player",a)
	for season in 3:
		_stores("player",{"Flint":100.0,"Salt":0.0})
		_stores(a,{"Flint":float(_stock(a,"Flint")),"Salt":60.0})
		Ledger._refresh_report("player",101+91*season); Ledger._refresh_report(a,101+91*season)
		Ledger._settle(p,101+91*season)
	# They make no flint: all the flint they get is ours.
	assert_float(Ledger.share(a,"player","Flint")).is_greater(0.95)
	assert_float(Ledger.dependence(a,"player")).is_greater(0.0)
	# How long their stores last without us: their stock over what they use
	# beyond what they make and get elsewhere.
	var r:=Ledger.report(a)
	var x:Dictionary=(r.g as Dictionary).Flint
	x["u"]=30.0; x["p"]=0.0; x["m"]=Ledger.flow("player",a,"Flint")
	assert_float(Ledger.days_without(a,"player","Flint")).is_equal_approx(float(x.s),0.5)
	var line:=Words.leaning_line(a,"player")
	assert_str(line).contains("of its flint from us")
	assert_str(line).contains("stores last")
	# What we lean on them for, the other way.
	assert_str(Words.leaning_line("player",a)).contains("salt")
	# A good nobody sends: no share.
	assert_float(Ledger.share(a,"player","Copper Ore")).is_equal(0.0)

func test_each_stance_has_its_effects_and_costs_on_both_ledgers()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	var p:=_settle("player",a)
	var salt_before:=float((p.last[_dir(p,a)] as Dictionary).get("Salt",0.0))
	assert_float(salt_before).is_greater(0.0)
	# Embargo: nothing either way; we lose what came from them.
	var preview:=Stances.preview_for("embargo","player",a)
	assert_float(float(preview.cost)).is_greater(0.0)
	assert_bool(Stances.set_stance("player",a,"embargo").ok).is_true()
	_stores("player",{"Flint":100.0,"Salt":0.0}); _stores(a,{"Flint":0.0,"Salt":60.0})
	var flint:=_stock("player","Flint"); var salt:=_stock(a,"Salt")
	Ledger._refresh_report("player",101); Ledger._refresh_report(a,101)
	Ledger._settle(p,101)
	assert_str(String(p.last.why)).is_equal("embargo:player")
	assert_float(_stock("player","Flint")).is_equal(flint)
	assert_float(_stock(a,"Salt")).is_equal(salt)
	# Toll: a tenth of the trade's worth comes to us; trade falls a quarter.
	Stances.set_stance("player",a,"toll")
	var mods:=Stances.pair_mods("player",a,192)
	assert_float(float(mods.cap)).is_equal_approx(Stances.TOLL_VOLUME,0.0001)
	Ledger._settle(p,192)
	var toll:=float(p.last.get("toll_b" if String(p.b)=="player" else "toll_a",0.0))
	# Taken in full only where our border facing them is watched; smugglers
	# carry the rest round an open line (fort_border.gd facing: half there).
	var collected:=0.5+0.5*preload("res://scripts/fort_border.gd").facing("player",a,0.0)
	assert_float(toll).is_equal_approx(Stances.TOLL_SHARE*collected*(float(p.last.trade_ab)+float(p.last.trade_ba)),0.05)
	assert_float(toll).is_greater(0.0)
	# Favour: we sell a fifth below our price, and more of it.
	Stances.set_stance("player",a,"favour")
	_set_stage("player","weighed_metal"); _set_stage(a,"weighed_metal")
	_stores("player",{"Flint":100.0,"Salt":0.0,"Coin":0.0}); _stores(a,{"Flint":0.0,"Salt":0.0,"Coin":500.0})
	Ledger._refresh_report("player",283); Ledger._refresh_report(a,283)
	Ledger._settle(p,283)
	var sold:=float((p.last[_dir(p,"player")] as Dictionary).get("Flint",0.0))
	assert_float(_stock("player","Coin")).is_equal_approx(sold*Prices.value("Flint","player")*(1.0-Stances.FAVOUR_DISCOUNT),0.01)
	# Squeeze their flint: none goes to them, and we buy it up from others at a premium.
	Stances.set_stance("player",a,"squeeze","Flint")
	_set_stage(b,"weighed_metal")
	_stores("player",{"Flint":100.0,"Coin":1000.0}); _stores(a,{"Flint":0.0,"Coin":500.0}); _stores(b,{"Flint":200.0,"Coin":0.0})
	var q:=Ledger.pair("player",b)
	Ledger._refresh_report("player",374); Ledger._refresh_report(a,374); Ledger._refresh_report(b,374)
	Ledger._settle(p,374)
	assert_float(float((p.last[_dir(p,"player")] as Dictionary).get("Flint",0.0))).is_equal(0.0)
	Ledger._settle(q,374)
	var bought:=float((q.last[_dir(q,b)] as Dictionary).get("Flint",0.0))
	assert_float(bought).is_greater(0.0)
	assert_float(_stock(b,"Coin")).is_greater_equal(bought*Prices.value("Flint",b)*Ledger.SQUEEZE_PREMIUM-0.01)
	# Gifts: they cost our stores and warm them.
	Stances.set_stance("player",a,"gifts")
	_set_stage("player","subsistence"); _set_stage(a,"subsistence")
	var opinion:=Ledger.opinion("player",a)
	var held:=_stock("player","Food")+_stock("player","Flint")
	Ledger._refresh_report("player",465); Ledger._refresh_report(a,465)
	Ledger._settle(p,465)
	assert_float(float(p.last.get("gift_ab" if String(p.a)=="player" else "gift_ba",0.0))).is_greater(0.0)
	assert_float(float(((p.kinds as Dictionary).get(_dir(p,"player")+":gift",{}) as Dictionary).get("value",0.0))).is_greater(0.0)
	assert_float(_stock("player","Food")+_stock("player","Flint")).is_less(held)
	assert_float(Ledger.opinion("player",a)).is_greater(opinion)
	# What they took unreturned is owed, and what is owed eases their answer.
	p["owed"]=0.0
	assert_float(float(Stances.factors("player",a).obligation)).is_equal(0.0)
	var unobliged:=float((Stances.odds("toll","player",a).p as Dictionary).yield)
	p["owed"]=1e9 if String(p.a)=="player" else -1e9
	assert_float(Stances.owed_to("player",a)).is_greater(0.0)
	assert_float(float(Stances.factors("player",a).obligation)).is_equal(1.0)
	assert_float(float((Stances.odds("toll","player",a).p as Dictionary).yield)).is_greater_equal(unobliged)
	assert_str(Words.owed_label(a)).contains("They owe us")
	assert_int(Words.owed_label(a).split(" ",false).size()).is_less_equal(12)

func test_tribute_demand_yields_and_refuses_with_stated_odds_seeded()->void:
	var a:=String(ids[0])
	_settle("player",a)
	# We are far stronger than they are: a fair chance they pay.
	var c:=Ledger.civ(a)
	c["population"]=60.0; c["military_population"]=0.0; c["military_readiness"]=0.3
	var k:=Stances.skey("player",a)
	var seen:={}
	for day in range(200,2200,10):
		GameState.elapsed_days=day
		Ledger.state().tributes.clear()
		var said:=Stances.set_stance("player",a,"tribute")
		assert_bool(bool(said.ok)).is_true()
		# The odds are stated before the roll, and the roll follows them.
		var p:Dictionary=(said.odds as Dictionary).p
		var st:Dictionary=Ledger.state().stances[k]
		Stances._answer(k,st,day)
		var answer:Dictionary=Ledger.state().answers[k]
		var roll:=float(answer.roll)
		assert_float(roll).is_equal_approx(Stances._rng("answer:%s:%d" % [k,day]).randf(),0.001)
		var acc:=0.0
		var expected:="bear"
		for kind in Stances.ANSWERS:
			acc+=float(p.get(kind,0.0))
			if roll<acc:
				expected=kind
				break
		assert_str(String(answer.kind)).is_equal(expected)
		seen[String(answer.kind)]=true
		if String(answer.kind)=="yield":
			# Yielding binds them to tribute each season, on both ledgers.
			var t:=Stances.tribute(a,"player")
			assert_dict(t).is_not_empty()
			var held:=_stock("player","Food")+_stock("player","Flint")+_stock("player","Salt")+_stock("player","Timber")
			Stances._collect(Stances.skey(a,"player"),t,day+1)
			assert_float(float(t.get("paid",0.0))).is_greater(0.0)
			assert_float(_stock("player","Food")+_stock("player","Flint")+_stock("player","Salt")+_stock("player","Timber")).is_greater(held)
		if seen.has("yield") and seen.size()>=2: break
		Stances.set_stance("player",a,"free")
	assert_bool(seen.has("yield")).override_failure_message("no yield in %s" % str(seen)).is_true()
	assert_int(seen.size()).is_greater_equal(2)
	# An equal people seldom pays: the stated chance falls.
	var strong:=float(Stances.odds("tribute","player",a).p.yield)
	c["population"]=5000.0; c["military_population"]=500.0; c["military_readiness"]=0.8
	assert_float(float(Stances.odds("tribute","player",a).p.yield)).is_less(strong)

func test_embargo_leads_to_counter_supplier_raid_or_war()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	_settle("player",a); _settle(a,b,11)
	var st:={"id":"embargo","good":"","amount":0.0,"since":10,"by":"god","answer":-1}
	Ledger.state().stances[Stances.skey("player",a)]=st
	# Their answer can be any of these; each lands on the real ledgers.
	Stances._apply("player",a,st,"counter",50)
	assert_str(String(Stances.stance(a,"player").id)).is_equal("embargo")
	Stances._apply("player",a,st,"supplier",50)
	assert_int(int((Ledger.pair(a,b).get("boost",{}) as Dictionary).get(a,0))).is_greater(50)
	Stances._apply("player",a,st,"raid",50)
	var raid:Dictionary=Ledger.state().raids[Stances.skey(a,"player")]
	var held:=_stock("player","Food")+_stock("player","Flint")
	GameState.elapsed_days=int(raid.next)
	Stances._raid(Stances.skey(a,"player"),raid,int(raid.next))
	assert_float(_stock("player","Food")+_stock("player","Flint")).is_less(held)
	assert_bool(Ledger.recent_news(400).any(func(n:Dictionary)->bool:return String(n.kind)=="raided")).is_true()
	# War over it, through the war's own engine, with the plain cause.
	Stances._apply("player",a,st,"war",60)
	var WarLoop:=load("res://scripts/war_loop.gd") as GDScript
	assert_bool(bool(WarLoop.call("feuding",a,60)) or bool(Ledger.relation("player",a).get("at_war",false))).is_true()
	assert_str(String((WarLoop.call("front",a) as Dictionary).get("cause",""))).contains("embargo")
	# Between two other peoples it is their feud (small peoples) or their war.
	Stances._apply(a,b,{"id":"squeeze","good":"Salt"},"war",70)
	var rel:=Ledger.relation(a,b)
	assert_bool(int(rel.get("feud_since",-1))>=0 or bool(rel.get("at_war",false)) or String(rel.get("pending_message",""))=="war").is_true()

func test_rivals_use_stances_on_each_other_and_rarely_on_us()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	_settle("player",a); _settle(a,b,11)
	# A holds a grudge against B and against us, and leans on neither.
	Ledger.shift_pair(a,b,-0.8,0.0)
	Ledger._warm("player",a,-0.7)
	var on_b:=0; var on_us:=0; var last_on_us:=-99999
	var gaps:Array=[]
	for month in range(1,240):
		var day:=month*30
		GameState.elapsed_days=day
		var before_b:=String(Stances.stance(a,b).get("id","free"))
		var before_us:=String(Stances.stance(a,"player").get("id","free"))
		Stances.review(a,day)
		if String(Stances.stance(a,b).get("id","free"))!=before_b and String(Stances.stance(a,b).get("id",""))=="embargo": on_b+=1
		var now_us:=String(Stances.stance(a,"player").get("id","free"))
		if now_us!=before_us and now_us in Stances.COERCIVE:
			on_us+=1
			if last_on_us>0: gaps.append(day-last_on_us)
			last_on_us=day
	assert_int(on_b).is_greater(0)
	# On us: rarely, never twice within PLAYER_GAP days.
	assert_int(on_us).is_less_equal(240*30/Stances.PLAYER_GAP+1)
	for gap in gaps: assert_int(int(gap)).is_greater_equal(Stances.PLAYER_GAP)

func _word_count(text:String)->int:
	return text.split(" ",false).size()

func test_trade_page_and_war_line_say_it_in_few_words()->void:
	var a:=String(ids[0])
	_settle("player",a)
	Stances.set_stance("player",a,"embargo")
	var board:VBoxContainer=preload("res://scripts/hud/trade_board.gd").new()
	add_child(board)
	board.setup({})
	assert_object(board.find_child("People_%s" % a,true,false)).is_not_null()
	var labels:=0
	for node in board.find_children("*","",true,false):
		var text:=""
		if node is Label: text=(node as Label).text
		elif node is Button: text=(node as Button).text
		else: continue
		if text=="": continue
		labels+=1
		assert_int(_word_count(text)).override_failure_message("'%s' has more than 12 words" % text).is_less_equal(12)
	assert_int(labels).is_greater(10)
	# The War screen's line for them: the stance and what they lack.
	var line:=Words.war_line(a)
	assert_str(line).starts_with("Trade:")
	assert_str(line).contains("embargo")
	assert_int(_word_count(line)).is_less_equal(12)
	# Every alert line and stance label is short too.
	for item in Ledger.recent_news(400): assert_int(_word_count(String(item.text))).is_less_equal(12)
	for id in Words.LABELS: assert_int(_word_count(String(Words.LABELS[id]))).is_less_equal(12)
	board.queue_free()
	# The trade map: an embargo is a broken line; open trade an inked line each way.
	var c:=Ledger.civ(a)
	(c.player_relation as Dictionary)["home_location_known"]=true
	(c.player_relation as Dictionary)["home_position"]={"x":150.0,"z":0.0}
	var TradeMap:=preload("res://scripts/hud/trade_map.gd")
	assert_bool(TradeMap.collect().any(func(l:Dictionary)->bool:return String(l.kind)=="embargo")).is_true()
	Stances.set_stance("player",a,"free")
	var kinds:=TradeMap.collect().map(func(l:Dictionary)->String:return String(l.kind))
	assert_bool(kinds.has("out") and kinds.has("in")).is_true()
	# A people that turns on our trade is told under the clock, once, in few words.
	Stances.set_stance(a,"player","embargo","",0.0,"ai")
	var alerts:=preload("res://scripts/hud/trade_alerts.gd").alerts()
	assert_bool(alerts.any(func(m:Dictionary)->bool:return String(m.tone)=="red" and String((m.lines as PackedStringArray)[0]).contains(Ledger.name_of(a)))).is_true()
	for m:Dictionary in alerts:
		for l in m.lines: assert_int(_word_count(String(l))).is_less_equal(12)

func test_court_lines_read_and_carry_out_with_odds()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	var ildor:=Ledger.name_of(a); var kezari:=Ledger.name_of(b)
	var Court:=preload("res://scripts/court_trade.gd")
	_settle("player",a); _settle("player",b,11)
	assert_str(String(Court.read("trade with %s" % ildor).act)).is_equal("free")
	assert_str(String(Court.read("stop all trade with %s" % ildor).act)).is_equal("embargo")
	assert_str(String(Court.read("demand tribute from %s" % kezari).act)).is_equal("tribute")
	var squeeze:=Court.read("buy up the flint of %s" % ildor)
	assert_str(String(squeeze.act)).is_equal("squeeze")
	assert_str(String(squeeze.good)).is_equal("Flint")
	var gift:=Court.read("send %s 200 grain" % ildor)
	assert_str(String(gift.act)).is_equal("gift")
	assert_int(int(gift.amount)).is_equal(200)
	assert_str(String(gift.good)).is_equal("Food")
	var flood:=Court.read("flood %s's markets with cloth" % ildor)
	assert_str(String(flood.act)).is_equal("favour")
	assert_str(String(flood.good)).is_equal("Civilian Goods")
	assert_dict(Court.read("what do we trade with %s?" % kezari)).is_empty()
	# Their, them: the people last named in this audience.
	var audience:={"origin":"court","lines":[{"text":"How are the %s?" % ildor}]}
	assert_str(String(Court.read("buy up their flint",audience).civ_id)).is_equal(a)
	assert_str(String(Court.read("send them 200 grain",audience).civ_id)).is_equal(a)
	# Words that are not trade stay with the court.
	assert_dict(Court.read("Give Suri a gift of bronze")).is_empty()
	assert_dict(Court.read("Send scouts to the north")).is_empty()
	assert_dict(Court.read("Send an envoy with gifts to the %s" % ildor)).is_empty()
	# Carried out: the stance is set, and the answer gives the engine's odds.
	var done:=Court.perform(Court.read("stop all trade with %s" % ildor))
	assert_bool(bool(done.ok)).is_true()
	assert_str(String(Stances.stance("player",a).id)).is_equal("embargo")
	assert_str(String(done.says)).contains("Their answer:")
	var tribute:=Court.perform(Court.read("demand tribute from %s" % kezari))
	assert_str(String(tribute.says)).contains("in 10")
	var food:=_stock("player","Food"); var theirs:=_stock(a,"Food")
	var sent:=Court.perform(Court.read("send %s 200 grain" % ildor))
	assert_bool(bool(sent.ok)).is_true()
	assert_float(food-_stock("player","Food")).is_equal_approx(200.0,0.01)
	assert_float(_stock(a,"Food")-theirs).is_equal_approx(200.0,0.01)
	# The question is answered from the keeper's facts.
	var sheet:=preload("res://scripts/court_facts.gd").sheet(["common","tribute"])
	var answer:=String((load("res://scripts/court_answers.gd") as GDScript).call("answer",sheet,"what do we trade with %s?" % kezari))
	assert_str(answer.to_lower()).contains(kezari.to_lower())
	# The office's buttons: one blank each, every one a trade order or a question.
	for menu:Dictionary in Court.menus():
		for item:Dictionary in menu.items:
			var text:=String(item.text)
			assert_bool(text.ends_with("?") or not Court.read(text).is_empty()).override_failure_message("'%s' reaches nothing" % text).is_true()
			assert_int(_word_count(String(item.label))).is_less_equal(12)

func test_the_ledger_survives_a_save()->void:
	var a:=String(ids[0])
	_settle("player",a)
	Stances.set_stance("player",a,"squeeze","Flint")
	Ledger.state().tributes[Stances.skey(a,"player")]={"value":12.0,"since":10,"until":2000,"next":101,"paid":0.0,"missed":0}
	var before:=JSON.stringify(Ledger.state())
	var saved:=ForeignDiplomacy.export_state()
	assert_bool(Ledger.valid_state(saved.audiences.trade)).is_true()
	ForeignDiplomacy.reset_for_new_world()
	assert_bool(ForeignDiplomacy.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	assert_str(JSON.stringify(Ledger.state())).is_equal(before)
	assert_str(String(Stances.stance("player",a).good)).is_equal("Flint")
	# An older save has no trade ledger: it starts empty, every stance free.
	var old:=saved.duplicate(true)
	(old.audiences as Dictionary).erase("trade")
	ForeignDiplomacy.reset_for_new_world()
	assert_bool(ForeignDiplomacy.import_state(old).get("ok",false)).is_true()
	assert_str(String(Stances.stance("player",a).id)).is_equal("free")
	assert_dict(Ledger.state().pairs).is_empty()
	# A broken ledger is refused, not loaded.
	var bad:=saved.duplicate(true)
	bad.audiences.trade.stances["x>y"]={"id":"plunder"}
	assert_bool(ForeignDiplomacy.import_state(bad).has("error")).is_true()

func test_settles_on_schedule_over_years_without_spam_or_rising_cost()->void:
	var first_year:=0; var third_year:=0
	for day in range(1,365*3+1):
		GameState.elapsed_days=day
		for id:String in ids: WorldSimulation.actors[id].systems.GameState.elapsed_days=day
		if day%30==0:
			_stores("player",{"Flint":100.0,"Salt":0.0})
			for id:String in ids: _stores(id,{"Flint":0.0,"Salt":60.0})
		var t0:=Time.get_ticks_usec()
		Ledger.advance(day)
		var spent:=Time.get_ticks_usec()-t0
		if day<=365: first_year+=spent
		elif day>730: third_year+=spent
	var s:=Ledger.state()
	# Six pairs (us and three peoples), each settled every season.
	assert_int((s.pairs as Dictionary).size()).is_equal(6)
	for p:Dictionary in (s.pairs as Dictionary).values():
		assert_int(int(p.get("last_day",0))).is_greater(365*3-120)
	assert_float(float(s.stats.get("settlements",0.0))).is_between(6.0*10.0,6.0*14.0)
	# Told once: one new-partner note a people, and no line twice in the chronicle.
	var partners:=Ledger.recent_news(5000).filter(func(n:Dictionary)->bool:return String(n.kind)=="partner")
	assert_int(partners.size()).is_less_equal(3)
	var keys:={}
	for entry in (GameState.chronicle.get("entries",[]) as Array):
		var key:=String((entry as Dictionary).get("key",""))
		if not key.begins_with("trade:"): continue
		assert_bool(keys.has(key)).is_false()
		keys[key]=true
	# The day's cost stays small and does not grow with the years.
	var per_day_first:=float(first_year)/365.0
	var per_day_third:=float(third_year)/365.0
	print("trade per-day cost: first year %.0f us, third year %.0f us" % [per_day_first,per_day_third])
	assert_float(per_day_third).is_less(1500.0)
	assert_float(per_day_third).is_less_equal(per_day_first*2.0+200.0)
