extends GdUnitTestSuite
## FAIR ENVOY DEALS (envoy_deals.gd, deal_value.gd, lent_hands.gd).
##
## The user (2026-10-03): "I have a ton of food, and my neighbors will come by
## and ask for a favor and give me food in return. If I decline them, it ruins
## our relationship, but if I accept it, I'm giving them way too much for
## something that has zero impact on me at all."
##
## A food-rich people values a food payment low; neighbours pay in what we
## lack, about evenly for both sides; turning a request down costs in
## proportion to how fair and needed it was; counters resolve at their stated
## odds; every people is weighed alike; hands lent abroad are away from work;
## older saves still load and answer. Quick: three simulated peoples and ours
## at day 400, stores set by hand, no day simulated.

const Hall:=preload("res://scripts/audience_hall.gd")
const ER:=preload("res://scripts/envoy_requests.gd")
const Deals:=preload("res://scripts/envoy_deals.gd")
const DV:=preload("res://scripts/deal_value.gd")
const RequestAI:=preload("res://scripts/envoy_request_ai.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const LentHands:=preload("res://scripts/lent_hands.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	ER.enabled=true
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
		# Neighbours close enough for every kind of request (envoy_requests.gd plausible).
		c["world_position"]=Vector2(30.0*float(i+1),0.0)
		c["alive"]=true
		(c.player_relation as Dictionary)["contact_level"]=2
		(c.player_relation as Dictionary)["opinion"]=0.35
	GameState.ensure_population_total(200)
	GameState.elapsed_days=400
	GovernmentPeopleSystem.reset_for_new_world(); GovernmentPeopleSystem.initialize()
	# Ours: a great deal of food (150 days, 30 wanted), short of stone and timber.
	_stores("player",{"Food":30000.0,"Timber":60.0,"Stone":40.0,"Clay":90.0,"Fiber Plants":90.0})
	GameState.simulation_metrics["food_days"]=150.0
	for id:String in ids: _stores(id,{"Food":DV.wanted(id,"Food")*40.0/30.0,"Stone":300.0,"Timber":200.0,"Salt":80.0,"Flint":30.0,"Clay":50.0,"Fiber Plants":60.0})
	for id:String in ids: _plain_ruler(id)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

func _stores(owner:String,goods:Dictionary)->void:
	WorldSimulation.scoped(owner,func()->void:
		for good:String in goods:
			if good=="Food":
				var have:=WorldSimulation.food.total_stored()
				if float(goods[good])>have: WorldSimulation.food.receive_external_food(float(goods[good])-have)
				else: WorldSimulation.food.issue_for_obligation(have-float(goods[good]),"test","test")
			else: WorldSimulation.state.resource_stockpiles[good]=float(goods[good])
			WorldSimulation.state.economy_known_goods[good]=true)

func _plain_ruler(id:String)->void:
	## No trust built up yet. (A ruler's nature is the world's own: drawn from
	## the seed, never set by hand.)
	ForeignDiplomacy.leader(id)["trust"]=0.0

func _civ(i:int=0)->Dictionary:
	return ForeignDiplomacy.civilization(ids[i])

func _back(type:String,i:int=0,food_days:float=40.0)->Dictionary:
	var civ:=_civ(i)
	var other:=_civ(1 if i!=1 else 0)
	civ.player_relation.opinion=0.35
	civ.food_days=food_days; civ.health=0.8
	(Rivals.character(ids[i]).bonds as Array).clear()
	match type:
		"healer_plea": civ.health=0.4
		"rite_keeper","blessing_rite": civ.player_relation.opinion=0.8
		"war_supplies": civ.relations[String(other.id)]={"border_tension":0.9,"at_war":true}
		"craft_teaching":
			for d in ["sealed_vessels","kiln_control","clay_tempering","pit_firing"]:
				if not d in GameState.known_discoveries: GameState.known_discoveries.append(d)
		"safe_passage": civ.relations[String(other.id)]={"border_tension":0.1,"at_war":false}
	# The world keeps a people's food days and its stores as one reading.
	_stores(ids[i],{"Food":DV.wanted(ids[i],"Food")*food_days/30.0})
	return civ

func _raise(type:String,i:int=0,food_days:float=40.0)->Dictionary:
	_back(type,i,food_days)
	return Hall.debug_situation(type,ids[i],{})

func _req(a:Dictionary)->Dictionary:
	return (a.situation as Dictionary).get("req",{})

func _option(a:Dictionary,id:String)->Dictionary:
	for o in Hall.options(String(a.id)):
		if String(o.id)==id: return o
	return {}

# --- 1. value to the receiver -------------------------------------------------

func test_a_food_rich_people_values_a_food_payment_low()->void:
	# 150 days in store against 30 wanted: a unit of food is worth a fifth of its price.
	assert_float(DV.depth("player","Food")).is_equal_approx(5.0,0.01)
	assert_float(DV.worth_in("player","Food",100.0)).is_less(25.0)
	# Stone we lack: worth twice its price to us.
	assert_float(DV.worth_in("player","Stone",30.0)).is_greater(30.0*1.8*1.9)
	# The same 100 Food is worth about its price to a people holding what it wants.
	_stores(ids[0],{"Food":DV.wanted(ids[0],"Food")})
	assert_float(DV.worth_in(ids[0],"Food",100.0)).is_between(80.0,100.0)
	# So a neighbour with stone to spare pays in stone, not in food.
	for type in ["craft_teaching","rite_keeper","safe_passage","war_supplies","healer_plea","blessing_rite"]:
		var a:=_raise(type)
		assert_dict(a).override_failure_message("%s not raised" % type).is_not_empty()
		var p:=_req(a)
		for field in ["pay_res","gift_res","toll_res","offer_res"]:
			if p.has(field): assert_str(String(p[field])).override_failure_message("%s paid in %s" % [type,String(p[field])]).is_not_equal("Food")
	# Our share of a hunt comes in what we lack while meat is worth little to us.
	var hunt:=_raise("joint_hunt")
	assert_str(String(_req(hunt).get("share_res",""))).is_not_empty()
	assert_str(String(_req(hunt).share_res)).is_not_equal("Food")

func test_a_people_with_only_food_to_give_offers_a_poor_deal_that_costs_little_to_decline()->void:
	_stores(ids[0],{"Stone":0.0,"Timber":0.0,"Salt":0.0,"Flint":0.0,"Clay":0.0,"Fiber Plants":0.0})
	var a:=_raise("rite_keeper")
	assert_dict(a).is_not_empty()
	var p:=_req(a)
	assert_str(String(p.get("gift_res",""))).is_equal("Food")
	var d:Dictionary=p.deal
	# One of ours gone for good, for food we are drowning in: they pay no more
	# than a keeper is worth to them, and that food is worth little to us.
	assert_float(float(d.us_get)).is_less(float(d.us_give)*0.5)
	assert_float(float(d.them_give)).is_less_equal(float(d.them_get)*Deals.temper(ids[0],float(d.need))+5.0)
	var st:=Hall.stakes(String(a.id))
	assert_str(String(st.short)).starts_with("Poor for us")
	# Declining it courteously costs next to nothing, and no grudge.
	var grudges:=(Rivals.character(ids[0]).grudges as Array).size()
	var before:=float(_civ().player_relation.opinion)
	var result:=Hall.resolve(String(a.id),"decline")
	assert_bool(bool(result.ok)).is_true()
	assert_float(before-float(_civ().player_relation.opinion)).is_less(0.012)
	assert_int((Rivals.character(ids[0]).grudges as Array).size()).is_equal(grudges)
	# And such a deal is seldom brought: its appeal is low.
	var c:=ER.candidate("rite_keeper",ids[0],{"type":"ambient","data":{}},Hall._rng("t",2),{},int(GameState.elapsed_days)+800)
	if not c.is_empty(): assert_float(float(c.get("appeal",1.0))).is_less(0.6)

# --- 2. a fair price -------------------------------------------------------------

func test_offers_leave_both_sides_about_equally_better_off()->void:
	# The offer rule: worth to us plus cost to them is about what the thing
	# costs us plus what it is worth to them (an even split), before temper.
	for pair in [[60.0,120.0],[365.0,548.0],[0.0,384.0],[117.0,226.0]]:
		var cost:=float(pair[0]); var gain:=float(pair[1])
		var o:=Deals.offer(ids[0],"player",cost,gain,1.0)
		assert_dict(o).is_not_empty()
		if bool(o.capped): continue
		var ours:=float(o.worth)-cost
		var theirs:=gain-float(o.cost)
		assert_float(absf(ours-theirs)).override_failure_message("cost %d gain %d: ours %.1f theirs %.1f (%s)" % [cost,gain,ours,theirs,str(o)]).is_less_equal(0.15*(cost+gain)+12.0)
	# And on the requests themselves, priced by what each costs us in the
	# ledger: with stone to spare they pay in what we lack, never leaving us
	# with less than half of what we give, and both sides come out ahead or
	# near it (a payment capped by their stores leaves them the better part).
	for type in ["craft_teaching","rite_keeper","healer_plea","war_supplies","safe_passage"]:
		var a:=_raise(type)
		var d:Dictionary=_req(a).deal
		assert_float(float(d.us_get)).override_failure_message("%s: %s" % [type,str(d)]).is_greater_equal(0.5*float(d.us_give))
		assert_float(float(d.them_get)-float(d.them_give)).override_failure_message("%s: %s" % [type,str(d)]).is_greater_equal(-5.0)
	# A desperate people pays more than one at ease for the same thing; a hard,
	# unkindly ruler pays less than a kindly one.
	assert_float(Deals.temper(ids[0],1.0)).is_greater(Deals.temper(ids[0],0.0))
	var hard:=ids.duplicate()
	hard.sort_custom(func(x:String,y:String)->bool:
		var px:=Hall._personality(x); var py:=Hall._personality(y)
		return float(px.assertiveness)-0.5*float(px.empathy)>float(py.assertiveness)-0.5*float(py.empathy))
	var proud:=func(id:String)->bool:return String(ForeignDiplomacy.leader(id).get("temperament",""))=="Proud guardian"
	if not bool(proud.call(hard[0])) and not bool(proud.call(hard[-1])): assert_float(Deals.temper(String(hard[0]),0.0)).is_less_equal(Deals.temper(String(hard[-1]),0.0))

func test_the_card_states_both_sides_values_with_the_engines_numbers()->void:
	var a:=_raise("craft_teaching")
	var d:Dictionary=_req(a).deal
	var st:=Hall.stakes(String(a.id))
	var keys:=[]
	for row in st.rows: keys.append(String(row.key))
	assert_array(keys).contains(["The balance","We give","We get","Their side"])
	var balance:=String((st.rows as Array)[0].text)
	assert_str(balance).contains("We give about %d and get about %d" % [roundi(float(d.us_give)),roundi(float(d.us_get))])
	assert_str(String(st.refusal)).contains("regard")
	var accept:=_option(a,"accept")
	assert_str(String(accept.sub)).contains("We give about %d, get about %d" % [roundi(float(d.us_give)),roundi(float(d.us_get))])
	var decline:=_option(a,"decline")
	assert_str(String(decline.label)).is_equal("Decline courteously")
	assert_str(String(decline.cost)).contains("regard")
	# The voice is told the same numbers.
	var context:=Hall.voice_context(String(a.id))
	assert_dict(context.get("stakes",{})).is_not_empty()

# --- 3. proportionate refusals -------------------------------------------------------

func test_refusal_costs_scale_with_fairness_and_need()->void:
	# The same request, fair to us and lopsided against us.
	var fair:=_raise("rite_keeper")
	var fair_cost:=-float(Deals.refusal(fair,false).o)
	_stores(ids[1],{"Stone":0.0,"Timber":0.0,"Salt":0.0,"Flint":0.0,"Clay":0.0,"Fiber Plants":0.0})
	_plain_ruler(ids[1])
	var lopsided:=_raise("rite_keeper",1)
	assert_str(String(_req(lopsided).gift_res)).is_equal("Food")
	var lopsided_cost:=-float(Deals.refusal(lopsided,false).o)
	assert_float(lopsided_cost).is_less(fair_cost)
	# A courteous decline costs less than a blunt refusal.
	assert_float(-float(Deals.refusal(fair,true).o)).is_less(fair_cost)
	# A starving neighbour's loan, refused, costs more than a merely short one's.
	var starving:=_raise("food_loan",0,3.0)
	var short:=_raise("food_loan",2,19.0)
	assert_dict(starving).is_not_empty(); assert_dict(short).is_not_empty()
	var hard:=Deals.refusal(starving,false)
	var soft:=Deals.refusal(short,false)
	assert_float(-float(hard.o)).is_greater(-float(soft.o))
	assert_float(float(hard.g)).is_greater(float(soft.g))
	# Refusing the starving costs more than the old fixed price (0.04).
	assert_float(-float(hard.o)).is_greater(0.04)
	# Carried out: the blunt refusal of a starving people's fair plea leaves a
	# grudge; a courteous decline of the lopsided deal leaves none and brings
	# them back cooler, never with a demand.
	var grudges:=(Rivals.character(ids[0]).grudges as Array).size()
	assert_bool(bool(Hall.resolve(String(starving.id),"refuse").ok)).is_true()
	assert_int((Rivals.character(ids[0]).grudges as Array).size()).is_greater(grudges)
	assert_bool(bool(Hall.resolve(String(lopsided.id),"refuse").ok)).is_true()
	assert_bool(ER.soft_refusal(lopsided)).is_true()
	for o in Hall.occasions():
		if String(o.get("type",""))=="sequel" and String(o.get("civ_id",""))==ids[1]:
			assert_str(String(((o.data as Dictionary).previous as Dictionary).option)).is_equal("decline")

# --- 4. counters ---------------------------------------------------------------------

func test_counters_resolve_with_their_stated_odds()->void:
	var a:=_raise("healer_plea")
	var c:=_option(a,"counter_more")
	assert_dict(c).is_not_empty()
	var chance:=float(c.odds)
	assert_str(String(c.sub)).contains("in 10 that they agree")
	assert_str(String(c.sub)).contains("if not")
	var counters:Array=_req(a).counters
	var asked:Dictionary=counters.filter(func(x:Dictionary)->bool:return String(x.id)=="counter_more")[0]
	var res:=String(asked.res)
	var before:=Hall.player_stock(res)
	var agrees:=Deals.agrees(a,"counter_more",Deals.odds(a,float(asked.over)))
	var result:=Hall.resolve(String(a.id),"counter_more")
	assert_bool(bool(result.ok)).is_true()
	if agrees:
		assert_float(Hall.player_stock(res)-before).is_equal_approx(float(asked.amt),0.6)
		assert_str(String(result.outcome)).contains("agreed to your terms")
	else:
		assert_float(Hall.player_stock(res)).is_equal_approx(before,0.01)
		assert_str(String(result.outcome)).contains("without a deal")
	# The seeded roll lands at the stated odds across many envoys.
	for p in [0.2,0.5,0.8]:
		var yes:=0
		for n in 400:
			if Deals.agrees({"id":"aud_%d" % n},"counter_more",p): yes+=1
		assert_float(float(yes)/400.0).is_between(p-0.07,p+0.07)
	# Viewing a record never rolls again: the same envoy, the same answer.
	assert_bool(Deals.agrees(a,"counter_more",chance)).is_equal(Deals.agrees(a,"counter_more",chance))

func test_typed_and_live_counters_go_through_the_same_rules()->void:
	# Our people know salt (it is worth something to us), and hold none.
	_stores("player",{"Salt":0.0})
	var a:=_raise("craft_teaching")
	# Ask for a good other than the one they offered.
	var offered:=String(_req(a).pay_res)
	var good:="Salt" if offered!="Salt" else "Timber"
	var read:=ER.typed_choice(a,"Ask for 20 %s instead" % good.to_lower())
	assert_str(String(read.get("option",""))).is_equal("counter_good")
	assert_str(String(read.get("ask_res",""))).is_equal(good)
	assert_float(float(read.get("ask_amt",0))).is_equal(20.0)
	# The live reading's answer maps to the same terms.
	var live:=RequestAI.read_answer({"answer":"counter_good","share":1,"repay":good,"amount":20,"confidence":0.9},a)
	assert_str(String(live.option)).is_equal("counter_good")
	assert_str(String(live.ask_res)).is_equal(good)
	# Validated by the counters' own rule: a good of no use to us, or more
	# than they can spare, is no counter.
	var t:=Deals.counter_terms(a,"counter_good",good,20.0)
	assert_dict(t).is_not_empty()
	assert_dict(Deals.counter_terms(a,"counter_good","Copper Ore",20.0)).is_empty()
	assert_dict(Deals.counter_terms(a,"counter_good",good,500.0)).is_empty()
	ER.apply_typed(Hall.find(String(a.id)),read)
	# The words put their own counter on the card, at its own odds.
	var card:=_option(a,"counter_good")
	assert_str(String(card.sub)).contains("20 %s" % good)
	var mine:=Hall.player_stock(good)
	var them:=Hall.foreign_stock(ids[0],good)
	var agrees:=Deals.agrees(a,"counter_good",Deals.odds(a,float(t.get("over",0.0))))
	var result:=Hall.resolve(String(a.id),"counter_good")
	assert_bool(bool(result.ok)).is_true()
	if agrees:
		assert_float(Hall.player_stock(good)-mine).is_equal_approx(20.0,0.5)
		assert_float(them-Hall.foreign_stock(ids[0],good)).is_equal_approx(20.0,0.5)
	else: assert_float(Hall.player_stock(good)).is_equal_approx(mine,0.01)
	# "Decline" words are the courteous decline where it is open.
	var b:=_raise("war_supplies")
	assert_str(String(ER.typed_choice(b,"Decline politely").get("option",""))).is_equal("decline")
	assert_str(String(ER.typed_choice(b,"Stay out of it").get("option",""))).is_equal("refuse")

# --- 5. every people alike -----------------------------------------------------------------

func test_parity_between_computer_rulers()->void:
	# Two computer peoples with the very stores and people of ours are weighed
	# exactly as we are (and know the same goods).
	_stores("player",{"Salt":0.0,"Flint":0.0})
	for id in [ids[1],ids[2]]:
		WorldSimulation.scoped(id,func()->void:WorldSimulation.state.ensure_population_total(200))
		_stores(id,{"Food":30000.0,"Timber":60.0,"Stone":40.0,"Clay":90.0,"Fiber Plants":90.0,"Salt":0.0,"Flint":0.0})
	for good in ["Food","Stone","Timber"]:
		var mine:=DV.worth_in("player",good,50.0)
		assert_float(DV.worth_in(ids[1],good,50.0)).is_equal_approx(mine,0.001)
		assert_float(DV.worth_in(ids[2],good,50.0)).is_equal_approx(mine,0.001)
		assert_float(DV.worth_out(ids[1],good,50.0)).is_equal_approx(DV.worth_out("player",good,50.0),0.001)
	# A computer ruler paying a computer ruler offers as it would offer us.
	var to_us:=Deals.offer(ids[0],"player",60.0,120.0,1.0)
	var to_them:=Deals.offer(ids[0],ids[1],60.0,120.0,1.0)
	assert_str(String(to_them.res)).is_equal(String(to_us.res))
	assert_float(float(to_them.amt)).is_equal(float(to_us.amt))
	assert_float(float(to_them.worth)).is_equal_approx(float(to_us.worth),0.001)

# --- 6. hands lent abroad -------------------------------------------------------------------

func test_hands_sent_abroad_are_away_from_work_until_they_come_home()->void:
	var a:=_raise("joint_hunt")
	var hunters:=int(_req(a).hunters)
	var day:=int(GameState.elapsed_days)
	var civilian:=0.0
	for role in GameState.population_allocations:
		if role!="Defense": civilian+=float(GameState.population_allocations[role])
	if civilian<=0.0: GameState.population_allocations["Food"]=150
	var before:=GameState.civilian_workforce_fraction()
	assert_bool(bool(Hall.resolve(String(a.id),"accept").ok)).is_true()
	assert_float(LentHands.away(day)).is_equal(float(hunters))
	assert_float(GameState.civilian_workforce_fraction()).is_less(before)
	# Home after the drive: the record clears on the next ten-day reckoning.
	GameState.elapsed_days=day+40
	ER.daily(int(GameState.elapsed_days)-int(GameState.elapsed_days)%10)
	assert_float(LentHands.away(int(GameState.elapsed_days))).is_equal(0.0)
	assert_int((ER.store().lent as Array).size()).is_equal(0)

# --- 7. saves ------------------------------------------------------------------------------

func test_save_compatibility()->void:
	# New state round-trips: deals and counters on requests, hands lent, a
	# pledge in a good beyond the hall's five.
	var a:=_raise("craft_teaching")
	Hall.resolve(String(a.id),"accept")
	var hunt:=_raise("joint_hunt")
	Hall.resolve(String(hunt.id),"accept")
	_raise("healer_plea")
	ER.store().pledges.append({"civ":ids[0],"res":"Salt","amt":10.0,"due":900,"day":400,"text":"a test","tries":0})
	var s:=Hall.state()
	assert_bool(Hall.validate_state(s)).is_true()
	assert_bool(Hall.validate_state(JSON.parse_string(JSON.stringify(s)))).is_true()
	var bad:=s.duplicate(true); bad.envoy_requests["lent"]=[{"n":"many"}]
	assert_bool(Hall.validate_state(bad)).is_false()
	# An older save: a waiting request with no deal or counters on it, and no
	# record of lent hands. Its card is weighed when first read, and it answers.
	var old:=_raise("war_supplies")
	var req:=_req(old)
	req.erase("deal"); req.erase("counters")
	ER.store().erase("lent")
	var ids_seen:=[]
	for o in Hall.options(String(old.id)): ids_seen.append(String(o.id))
	assert_array(ids_seen).contains(["accept","decline","refuse"])
	assert_dict(Hall.stakes(String(old.id))).is_not_empty()
	assert_bool(bool(Hall.resolve(String(old.id),"decline").ok)).is_true()
	assert_bool(Hall.validate_state(JSON.parse_string(JSON.stringify(Hall.state())))).is_true()
	# A state written before this change validates as it was.
	var older:=Hall.state().duplicate(true)
	(older.envoy_requests as Dictionary).erase("lent")
	assert_bool(Hall.validate_state(older)).is_true()

# --- review of PR #134 -----------------------------------------------------------------------

func _raise_until(type:String,agree:bool,option_id:String,i:int=0)->Dictionary:
	## An envoy of this kind whose seeded roll on the counter comes out as asked.
	for n in 40:
		var a:=_raise(type,i)
		if a.is_empty(): return {}
		var c:={}
		for x in _req(a).get("counters",[]):
			if String(x.id)==option_id: c=x
		if c.is_empty(): return {}
		if Deals.agrees(a,option_id,Deals.odds(a,float(c.over)))==agree: return a
		Hall.resolve(String(a.id),"decline")
	return {}

func test_review_1_a_typed_work_counter_cannot_gather_more_than_the_workers_can()->void:
	var a:=_raise("work_for_food",0,10.0)
	assert_dict(a).is_not_empty()
	var p:=_req(a)
	# Another good from our land than the one they offered to gather.
	var other:="Timber" if String(p.res)!="Timber" else "Stone"
	var cap:=Deals.gather_cap(p,other,false)
	# "Gather 50000" is no counter: the workers cannot gather it, in another
	# good or as more of the same.
	assert_dict(Deals.counter_terms(a,"counter_good",other,50000.0)).is_empty()
	assert_dict(Deals.counter_terms(a,"counter_good",other,Hall._nice(cap)*2.0)).is_empty()
	assert_dict(Deals.counter_terms(a,"counter_more","",50000.0)).is_empty()
	# Within what they can gather, it stands.
	assert_dict(Deals.counter_terms(a,"counter_good",other,floorf(cap*0.5))).is_not_empty()
	# Through the typed path: refused, and nothing appears, now or when the work is done.
	var read:=ER.typed_choice(a,"Have them gather 50000 %s instead" % other.to_lower())
	assert_str(String(read.get("option",""))).is_equal("counter_good")
	assert_str(String(read.get("ask_res",""))).is_equal(other)
	ER.apply_typed(Hall.find(String(a.id)),read)
	var held:=Hall.player_stock(other)
	var result:=Hall.resolve(String(a.id),"counter_good")
	assert_bool(bool(result.ok)).is_false()
	var day:=int(GameState.elapsed_days)+int(p.days)*2
	GameState.elapsed_days=day+(10-day%10)%10
	ER.daily(int(GameState.elapsed_days))
	assert_float(Hall.player_stock(other)).is_less_equal(held+0.01)

func test_review_2_a_rejected_typed_counter_leaves_the_cards_counters_alone()->void:
	var a:=_raise("healer_plea")
	var card:Dictionary=(_req(a).counters as Array).filter(func(x:Dictionary)->bool:return String(x.id)=="counter_more")[0]
	# The god named a counter they cannot meet: 9000 of their payment.
	ER.apply_typed(Hall.find(String(a.id)),{"option":"counter_more","ask_amt":9000.0})
	assert_bool(bool(Hall.resolve(String(a.id),"counter_more").ok)).is_false()
	# The words are cleared with the error: the card's own counter is the card's.
	assert_bool(Hall._situation(Hall.find(String(a.id))).has("typed")).is_false()
	assert_dict(ER._counter(Hall.find(String(a.id)),_req(a),"counter_more",{})).is_equal(card)
	# Words naming one counter never bend another.
	var named:={"counter":"counter_good","ask_res":"Salt","ask_amt":20.0}
	assert_dict(ER._counter(a,_req(a),"counter_more",named)).is_equal(card)
	var res:=String(card.res)
	var mine:=Hall.player_stock(res)
	var agrees:=Deals.agrees(a,"counter_more",Deals.odds(a,float(card.over)))
	assert_bool(bool(Hall.resolve(String(a.id),"counter_more").ok)).is_true()
	if agrees: assert_float(Hall.player_stock(res)-mine).is_equal_approx(float(card.amt),0.6)

func test_review_3_only_answers_that_roll_state_odds()->void:
	var barter:=_raise("barter",0,10.0)
	if not barter.is_empty(): assert_str(String(_option(barter,"bargain").sub)).contains("in 10 that they agree")
	_back("fugitive_return"); _civ().player_relation.recruitment_visits=1
	var fugitive:=Hall.debug_situation("fugitive_return",ids[0],{})
	assert_dict(fugitive).is_not_empty()
	assert_str(String(_option(fugitive,"bargain").sub)).not_contains("in 10")
	var rites:=_raise("rite_keeper")
	assert_str(String(_option(rites,"bargain").sub)).not_contains("in 10")
	assert_str(String(_option(rites,"counter_more").sub)).contains("in 10 that they agree")
	# Demanding our captured scouts back rolls, so it says its odds.
	CivilizationSystem.captured_player_scouts[ids[0]]={"count":3,"captured_day":380}
	var held:=Hall.debug_situation("captive_scouts",ids[0],{})
	assert_str(String(_option(held,"refuse").sub)).contains("in 10 that they agree")

func test_review_4_a_refused_counter_costs_exactly_what_the_card_says()->void:
	var a:=_raise_until("healer_plea",false,"counter_more")
	assert_dict(a).is_not_empty()
	assert_str(String(_option(a,"counter_more").sub)).contains("their regard falls about %d point" % roundi(Deals.COUNTER_LOST*100.0))
	var civ:=_civ()
	var opinion:=float(civ.player_relation.opinion)
	var trust:=float(ForeignDiplomacy.leader(ids[0]).trust)
	var tension:=float(civ.player_relation.border_tension)
	var result:=Hall.resolve(String(a.id),"counter_more")
	assert_bool(bool(result.ok)).is_true()
	assert_str(String(result.outcome)).contains("without a deal")
	assert_float(opinion-float(civ.player_relation.opinion)).is_equal_approx(Deals.COUNTER_LOST,0.0001)
	assert_float(float(ForeignDiplomacy.leader(ids[0]).trust)).is_equal_approx(trust,0.0001)
	assert_float(float(civ.player_relation.border_tension)).is_equal_approx(tension,0.0001)

func test_review_5_a_loans_repayment_is_read_from_their_stores_not_a_made_up_chance()->void:
	var a:=_raise("food_loan",0,10.0)
	var p:=_req(a)
	var d:Dictionary=p.deal
	assert_str(String(d.get)).not_contains("in 10")
	assert_str(String(d.get)).contains("they hold %d %s now" % [roundi(DV.held(ids[0],String(p.repay_res))),String(p.repay_res)])
	# By the repayment rule: enough held, the whole loan is counted; too little, none of it.
	var full:=Deals.repayable(ids[0],String(p.repay_res),float(p.repay_amt))
	assert_float(float(full.share)).is_equal(1.0)
	_stores(ids[0],{String(p.repay_res):float(p.repay_amt)*0.3})
	var short:=Deals.repayable(ids[0],String(p.repay_res),float(p.repay_amt))
	assert_float(float(short.share)).is_equal(0.0)
	assert_str(String(short.words)).contains("too little")

func test_review_6_hands_lent_abroad_do_not_rise_to_defend()->void:
	var combat:=preload("res://scripts/civilization_combat.gd")
	var before:=int(combat._away(WorldSimulation.state))
	var a:=_raise("joint_hunt")
	assert_bool(bool(Hall.resolve(String(a.id),"accept").ok)).is_true()
	assert_int(int(combat._away(WorldSimulation.state))-before).is_equal(int(_req(a).hunters))

func test_review_7_an_agreed_counter_on_help_brings_the_grateful_return()->void:
	var a:=_raise_until("healer_plea",true,"counter_more")
	assert_dict(a).is_not_empty()
	assert_bool(bool(Hall.resolve(String(a.id),"counter_more").ok)).is_true()
	var found:=false
	for o in Hall.occasions():
		if String(o.get("type",""))=="sequel" and String(o.get("civ_id",""))==ids[0]:
			found=true
			assert_str(String(((o.data as Dictionary).previous as Dictionary).option)).is_equal("accept")
			assert_dict(ER.extra_mix("sequel",o)).is_equal(ER.SEQUEL_WARM)
	assert_bool(found).is_true()
	# A refused counter is a courteous no: they come back cooler, never with a demand.
	var b:=_raise_until("healer_plea",false,"counter_more",1)
	assert_dict(b).is_not_empty()
	Hall.resolve(String(b.id),"counter_more")
	for o in Hall.occasions():
		if String(o.get("type",""))=="sequel" and String(o.get("civ_id",""))==ids[1]:
			assert_str(String(((o.data as Dictionary).previous as Dictionary).option)).is_equal("decline")

func test_review_8_the_border_grows_tenser_in_plain_words()->void:
	var a:=_raise("forage_leave",0,10.0)
	assert_str(String(_option(a,"refuse").sub)).contains("the border grows")
	assert_str(Deals.refusal_words({"o":-0.02,"x":0.06,"g":0.0})).contains("the border grows 6 points tenser")
