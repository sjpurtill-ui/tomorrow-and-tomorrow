extends RefCounted
## TRADE BETWEEN PEOPLES: what moves, the dependence it makes, and the one
## ledger every trade system reads and writes.
##
## How exchange grows with what each people knows (the FORM of a pair):
##   gift    from first meeting: each season each side gives from what it has
##           in plenty toward what the other lacks. Every gift is remembered
##           (the pair's owed balance: who owes whom a return) and warms the
##           one who receives it.
##   barter  goods for goods each season, at a meeting place the two found
##           after MEETING_SEASONS seasons of gifts going both ways, or once
##           both can compare values (tallies and measures: economy_system's
##           own test, _comparison_values_observable). Barter balances to
##           within BARTER_SLACK; the rest is owed.
##   silver  once both have money (weighed metal): monthly; the side that
##           buys more pays the difference from its purse.
##   coin    once both mint coin: the same, in coin.
## What moves: each people's surplus (stock over OFFER_OVER times its wanted
## holding, economy_system._desired_stock) toward the other's shortfall,
## good by good, the most needed first, at the seller's own price
## (trade_prices.gd, the one table), within what carriers can bring
## (capacity: the smaller people's size, the form's INTENSITY, the distance
## against roads and boats, the trade discoveries both know). Bulky goods
## (grain, timber, stone) use more of it than goods that carry well (salt,
## flint, made goods): CARRY.
## Settled on a schedule per pair (a season for gifts and barter, a month for
## priced trade), each pair on its own day, so a few pairs settle a day.
## Goods move between the real stores of both peoples' capitals
## (civilization_exchange take and receive). A people the world does not
## simulate (an old save, a test world) trades food only, from its counted
## food days. Every people trades by these rules, rival with rival.
##
## THE DEPENDENCE LEDGER: per people and good, a monthly reading of stock,
## own output (deposits delivered, food grown), use (output + imports -
## exports - what the stores grew) and imports; per pair the smoothed monthly
## flow each way. From it: the share of a people's supply of a good that comes
## from another (share), and how long its stores last without it
## (days_without).
##
## Other systems fold what they move into the same ledger (note_flow): trade
## pacts, gifts carried by envoys, tribute from towns we hold, food taken in
## raids. Stances (trade_stances.gd) shape every settlement; the purse
## (purse) is the one door for money.
##
## State: ForeignDiplomacy.audiences["trade"] (the god's own diplomacy record,
## saved with the audience hall; an older save starts an empty ledger).
## Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const Prices:=preload("res://scripts/trade_prices.gd")
const STANCES_PATH:="res://scripts/trade_stances.gd"
const WORDS_PATH:="res://scripts/trade_words.gd"
const WAR_PATH:="res://scripts/war_loop.gd"

const VERSION:=1
## The goods that pass between peoples (as between our own towns:
## settlement_model.gd CITY_TRADE_GOODS).
const GOODS:=["Food","Salt","Flint","Stone","Timber","Clay","Fiber Plants","Medicinal Plants","Copper Ore","Tin Ore","Iron Ore","Coal","Civilian Goods"]
## Goods any people wants once it lacks them, before it has seen them traded.
## The rest (salt, herbs, ores, coal) are wanted once the people knows them.
const BASIC:=["Food","Flint","Stone","Timber","Clay","Fiber Plants","Civilian Goods"]
## How well a good carries over distance: worth much for its weight and keeps
## (salt, herbs, flint, made goods) above 1; bulk (grain, timber, stone) below.
## A load of it uses value/CARRY of a pair's capacity.
const CARRY:={"Food":0.5,"Salt":1.6,"Flint":1.2,"Stone":0.4,"Timber":0.4,"Clay":0.5,"Fiber Plants":0.8,"Medicinal Plants":1.6,"Copper Ore":0.9,"Tin Ore":1.0,"Iron Ore":0.8,"Coal":0.5,"Civilian Goods":1.4}
const FORMS:=["gift","barter","silver","coin"]
## Days between settlements of a pair, by form.
const PERIOD:={"gift":91,"barter":91,"silver":30,"coin":30}
## Value carried a month per person of the smaller people, at the distance
## where reach is one half. Calibrated so stone-age exchange between peoples
## hundreds of km apart is a few loads a season (down-the-line flint and
## shell trade), bronze-age silver trade a few hundredths of output, and coin
## trade with roads and boats a tenth or so (classical grain and wine trade).
const INTENSITY:={"gift":0.06,"barter":0.25,"silver":0.7,"coin":1.4}
## Distance (km) at which reach falls to one half, before roads; roads double
## it at full logistics; boats on both sides carry BOAT_REACH times as far.
const REACH_KM:=120.0
const BOAT_REACH:=1.6
const BOATS:=["river_craft","reed_bundle_boats","hide_covered_boats","coastal_watercraft"]
const MEETING_SEASONS:=4
## A people parts with what it holds over OFFER_OVER times its wanted
## holding, and with no more than OFFER_SHARE of that excess at one time.
const OFFER_OVER:=1.1
const OFFER_SHARE:=0.5
const BARTER_SLACK:=0.25
## Reports are read again after this many days.
const REPORT_DAYS:=30
## How much a month's reading moves the smoothed one.
const MONTH_WEIGHT:=0.35
## A gift worth this much a head of the receiver warms them by GOODWILL_MAX.
const GOODWILL_VALUE:=1.0
const GOODWILL_MAX:=0.03
## Trading warms both a little each settlement, up to this opinion.
const WARMTH:=0.004
const WARMTH_CEILING:=0.4
## Below this opinion a people will not meet the other's traders.
const HOSTILE_OPINION:=-0.45
const NEWS_MAX:=40
## An alert stays under the clock this many days.
const NEWS_DAYS:=20
## A pair below this much value a month counts as not trading.
const PARTNER_FLOOR:=0.5
## What a people pays over the price to buy a good up from others, so that a
## people it squeezes cannot get it (trade_stances.gd "squeeze").
const SQUEEZE_PREMIUM:=1.25

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get("trade")
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed):
		s=empty_state()
		holder["trade"]=s
	var d:Dictionary=s
	for key in ["pairs","stances","answers","tributes","reports","stats","fold","raids"]:
		if not d.get(key) is Dictionary: d[key]={}
	if not d.get("news") is Array: d["news"]=[]
	return d

static func empty_state()->Dictionary:
	return {"version":VERSION,"world_seed":int(GameState.world_seed),"day":-1,"serial":0,"pairs":{},"stances":{},"answers":{},"tributes":{},"reports":{},"news":[],"fold":{},"raids":{},"stats":{}}

## The ledger as it would be read, without creating it (a reading never writes).
static func peek()->Dictionary:
	var holder:Variant=ForeignDiplomacy.get("audiences")
	var s:Variant=(holder as Dictionary).get("trade") if holder is Dictionary else null
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION: return {}
	return s

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	for key in ["pairs","stances","answers","tributes","reports"]:
		if d.has(key) and not d[key] is Dictionary: return false
	if d.has("news") and (not d.news is Array or (d.news as Array).size()>NEWS_MAX*2): return false
	if (d.get("pairs",{}) as Dictionary).size()>400 or (d.get("stances",{}) as Dictionary).size()>800: return false
	for p in (d.get("pairs",{}) as Dictionary).values():
		if not p is Dictionary or not (p as Dictionary).get("a") is String or not (p as Dictionary).get("b") is String: return false
		if not Hall._num((p as Dictionary).get("next",0)): return false
	for st in (d.get("stances",{}) as Dictionary).values():
		if not st is Dictionary or not String((st as Dictionary).get("id","")) in ["free","favour","toll","embargo","squeeze","tribute","gifts"]: return false
	return JSON.stringify(d).length()<=600000

static func _stat(key:String,amount:float=1.0)->void:
	var stats:Dictionary=state().stats
	stats[key]=float(stats.get(key,0.0))+amount

# --------------------------------------------------------------------------
# Peoples
# --------------------------------------------------------------------------

## "player" for the god's people (the world calls it "human" in other
## peoples' views).
static func owner_of(id:String)->String:
	return "player" if id=="human" or id=="" else id

static func simulated(owner:String)->bool:
	return owner=="player" or WorldSimulation.actors.has(owner)

static func civ(owner:String)->Dictionary:
	if owner=="player": return {}
	for c:Dictionary in CivilizationSystem.civilizations:
		if String(c.get("id",""))==owner: return c
	return {}

static func name_of(owner:String)->String:
	if owner=="player": return String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "our people"
	var c:=civ(owner)
	return String(c.get("name",owner)) if not c.is_empty() else owner

static func alive(owner:String)->bool:
	if owner=="player": return GameState.population_total>0
	var c:=civ(owner)
	return not c.is_empty() and bool(c.get("alive",true))

static func population(owner:String)->float:
	if owner=="player": return maxf(1.0,float(GameState.population_exact))
	if WorldSimulation.actors.has(owner): return maxf(1.0,float(WorldSimulation.actors[owner].systems.GameState.population_exact))
	return maxf(1.0,float(civ(owner).get("population",100.0)))

## Every people the world knows, the god's first.
static func owners()->Array:
	var out:Array=["player"]
	for c:Dictionary in CivilizationSystem.civilizations:
		var id:=String(c.get("id",""))
		if id!="" and id!="player" and bool(c.get("alive",true)): out.append(id)
	return out

static func key(a:String,b:String)->String:
	return "%s|%s" % [a,b] if a<b else "%s|%s" % [b,a]

static func pair(a:String,b:String)->Dictionary:
	return (state().pairs as Dictionary).get(key(a,b),{})

## Positions on the world (km): the god's home, another people's.
static func position(owner:String)->Vector2:
	if owner=="player": return CivilizationSystem.player_world_origin
	var c:=civ(owner)
	if c.is_empty(): return Vector2.ZERO
	var at:Variant=c.get("world_position")
	if at is Vector2: return at
	return CivilizationSystem._civilization_world_position(c)

static func distance_km(a:String,b:String)->float:
	return position(a).distance_to(position(b))

## The relation one people keeps with another, read in the god's scope: the
## god's own (player_relation) for a pair with us, the pair relation of two
## other peoples otherwise.
static func relation(a:String,b:String)->Dictionary:
	if a=="player" or b=="player":
		var other:=b if a=="player" else a
		return civ(other).get("player_relation",{})
	var first:=civ(a)
	return ((first.get("relations",{}) as Dictionary).get(b,{}) as Dictionary) if not first.is_empty() else {}

static func opinion(a:String,b:String)->float:
	return float(relation(a,b).get("opinion",0.0))

## Why two peoples cannot trade now ("" when they can).
static func blocked(a:String,b:String,day:int=-1)->String:
	if day<0: day=_day()
	var rel:=relation(a,b)
	if bool(rel.get("at_war",false)): return "war"
	if a=="player" or b=="player":
		var other:=b if a=="player" else a
		var war:=load(WAR_PATH) as GDScript
		if war!=null and bool(war.call("hot",other,day)): return "feud"
	elif CivilizationSystem.has_method("rival_feud_hot") and bool(CivilizationSystem.rival_feud_hot(rel,day)): return "feud"
	if float(rel.get("opinion",0.0))<HOSTILE_OPINION: return "hostile"
	var stances:=load(STANCES_PATH) as GDScript
	if stances!=null:
		var why:=String(stances.call("embargo_between",a,b))
		if why!="": return why
	return ""

# --------------------------------------------------------------------------
# The day: pairs found, settled on their days, stances answered
# --------------------------------------------------------------------------

## Called once a world day, in the god's scope (world_simulation.gd's
## exchange step). Returns at once on days with nothing due.
static func advance(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	var s:=state()
	if int(s.get("day",-1))>=day: return
	var first:=int(s.get("day",-1))<0
	s["day"]=day
	if first or posmod(day,30)==7: _discover_pairs(day)
	# Each people's market is read on its own day of the month.
	for owner:String in owners():
		if posmod(day+posmod(hash("trade_report:"+owner),REPORT_DAYS),REPORT_DAYS)==0: _refresh_report(owner,day)
	for k:String in (s.pairs as Dictionary).keys():
		var p:Dictionary=s.pairs[k]
		if int(p.get("next",0))<=day: _settle(p,day)
	(load(STANCES_PATH) as GDScript).call("daily",day)
	if posmod(day,30)==11: _fold(day)
	_prune_news(day)

## Pairs of peoples that know each other: the god's with each people it has
## met; two other simulated peoples once either has met the other.
static func _discover_pairs(day:int)->void:
	var s:=state()
	var pairs:Dictionary=s.pairs
	var met:={}
	for c:Dictionary in CivilizationSystem.civilizations:
		var id:=String(c.get("id",""))
		if id=="" or not bool(c.get("alive",true)): continue
		if int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: met[key("player",id)]=["player",id]
	var actors:Array=WorldSimulation.actors.keys()
	actors.sort()
	for a:String in actors:
		var seen:Array=WorldSimulation.scoped(a,func()->Array:
			var out:Array=[]
			for c:Dictionary in WorldSimulation.world.civilizations:
				var other:=owner_of(String(c.get("id","")))
				if other!="player" and int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: out.append(other)
			return out)
		for b:String in seen:
			if WorldSimulation.actors.has(b) and alive(a) and alive(b): met[key(a,b)]=[a,b] if a<b else [b,a]
	for k:String in met:
		if pairs.has(k):
			(pairs[k] as Dictionary)["known"]=true
			continue
		var ids:Array=met[k]
		var a:=String(ids[0]) if String(ids[0])<String(ids[1]) else String(ids[1])
		var b:=String(ids[1]) if a==String(ids[0]) else String(ids[0])
		pairs[k]={"a":a,"b":b,"known":true,"since":-1,"met":day,"next":day+1+posmod(hash(k),30),"form":"gift","meet":-1,"gift_seasons":0,"owed":0.0,
			"ema":{"ab":{},"ba":{}},"val":{"ab":0.0,"ba":0.0},"acc":{"ab":{},"ba":{}},"kinds":{},"last":{},"total":{"ab":0.0,"ba":0.0},"last_day":day}

static func _settle(p:Dictionary,day:int)->void:
	var a:=String(p.a); var b:=String(p.b)
	if not alive(a) or not alive(b):
		p["next"]=day+365
		return
	var ra:=engine_report(a,day); var rb:=engine_report(b,day)
	_fresh(a,ra); _fresh(b,rb)
	var form:=form_of(p,ra,rb)
	var period:=int(PERIOD[form])
	var elapsed:=clampi(day-int(p.get("last_day",day-period)),1,400)
	p["form"]=form
	p["next"]=day+period
	var stances:=load(STANCES_PATH) as GDScript
	var mods:Dictionary=stances.call("pair_mods",a,b,day)
	var moved:={"ab":{},"ba":{}}
	var value:={"ab":0.0,"ba":0.0}
	var paid:=0.0
	var tolls:={"a":0.0,"b":0.0}
	var gifts:={"ab":0.0,"ba":0.0}
	# What was traded (and given) between them this time, apart from tolls,
	# tribute, spoils and pacts: the reciprocity and the warmth read only this.
	var traded_ab:=0.0; var traded_ba:=0.0
	var why:=blocked(a,b,day) if bool(p.get("known",false)) else "unmet"
	if why=="":
		var cap:=capacity(a,b,form,period,ra,rb)*float(mods.get("cap",1.0))
		var ab:=_fill(ra,rb,a,cap*0.5,(mods.deny as Dictionary).get("ab",[]),String((mods.flood as Dictionary).get("ab","")),float((mods.discount as Dictionary).get("ab",0.0)),(mods.buy as Dictionary).get("b",[]),form)
		var ba:=_fill(rb,ra,b,cap*0.5,(mods.deny as Dictionary).get("ba",[]),String((mods.flood as Dictionary).get("ba","")),float((mods.discount as Dictionary).get("ba",0.0)),(mods.buy as Dictionary).get("a",[]),form)
		var vab:=float(ab.value); var vba:=float(ba.value)
		match form:
			"barter":
				# Goods for goods: each side's load is cut to what the other
				# brings, within BARTER_SLACK; the rest is remembered as owed.
				var even:=minf(vab,vba)*(1.0+BARTER_SLACK)
				if vab>even: ab=_scaled(ab,even/vab); vab=even
				if vba>even: ba=_scaled(ba,even/vba); vba=even
			"silver","coin":
				# The side that buys more pays the difference from its purse.
				var net:=vab-vba
				if absf(net)>0.01:
					var payer:=b if net>0.0 else a
					var payee:=a if net>0.0 else b
					var got:=-purse(payer,-absf(net),"trade with %s" % name_of(payee))
					if got>0.0: purse(payee,got,"trade with %s" % name_of(payer))
					paid=got*(1.0 if net>0.0 else -1.0)
					if got<absf(net)-0.01:
						# What could not be paid for does not go.
						if net>0.0:
							ab=_scaled(ab,(vba+got)/maxf(0.01,vab)); vab=vba+got
						else:
							ba=_scaled(ba,(vab+got)/maxf(0.01,vba)); vba=vab+got
		moved.ab=_carry(a,b,ab.goods)
		moved.ba=_carry(b,a,ba.goods)
		value.ab=_worth(moved.ab,a)
		value.ba=_worth(moved.ba,b)
		traded_ab=float(value.ab); traded_ba=float(value.ba)
		# Tolls: a tenth of the trade's worth to the side that levies them.
		for side in ["a","b"]:
			var share:=float((mods.toll as Dictionary).get(side,0.0))
			if share<=0.0: continue
			var levier:=a if side=="a" else b
			var payer2:=b if side=="a" else a
			tolls[side]=_levy(payer2,levier,share*(float(value.ab)+float(value.ba)),form)
		# Gifts beyond trade, from a stance (trade_stances.gd "gifts").
		for dir in ["ab","ba"]:
			var size:=float((mods.gift as Dictionary).get(dir,0.0))*float(period)/30.0
			if size<=0.0: continue
			var giver:=a if dir=="ab" else b
			var taker:=b if dir=="ab" else a
			var given:=_gift(giver,taker,size,ra if dir=="ab" else rb,rb if dir=="ab" else ra)
			gifts[dir]=given
	# What other systems moved between them since (pacts, tribute, spoils, envoys' gifts).
	var acc:Dictionary=p.get("acc",{"ab":{},"ba":{}})
	for dir in ["ab","ba"]:
		var noted:Dictionary=acc.get(dir,{})
		for good:String in noted:
			(moved[dir] as Dictionary)[good]=float((moved[dir] as Dictionary).get(good,0.0))+float(noted[good])
			value[dir]=float(value[dir])+float(noted[good])*Prices.value(good,a if dir=="ab" else b)
	p["acc"]={"ab":{},"ba":{}}
	_smooth(p,moved,value,elapsed)
	var given_ab:=traded_ab+float(gifts.ab); var given_ba:=traded_ba+float(gifts.ba)
	var traded:=given_ab+given_ba
	if form in ["gift","barter"] or float(gifts.ab)+float(gifts.ba)>0.0:
		p["owed"]=clampf(float(p.get("owed",0.0))+given_ab-given_ba,-1e12,1e12)
	p["last"]={"day":day,"form":form,"ab":_rounded(moved.ab),"ba":_rounded(moved.ba),"vab":snappedf(float(value.ab),0.01),"vba":snappedf(float(value.ba),0.01),"trade_ab":snappedf(traded_ab,0.01),"trade_ba":snappedf(traded_ba,0.01),"paid":snappedf(paid,0.01),
		"toll_a":snappedf(float(tolls.a),0.01),"toll_b":snappedf(float(tolls.b),0.01),"gift_ab":snappedf(float(gifts.ab),0.01),"gift_ba":snappedf(float(gifts.ba),0.01),"why":why}
	p["last_day"]=day
	var totals:Dictionary=p.get("total",{"ab":0.0,"ba":0.0})
	totals["ab"]=float(totals.get("ab",0.0))+float(value.ab); totals["ba"]=float(totals.get("ba",0.0))+float(value.ba)
	p["total"]=totals
	_stat("settlements")
	if traded>0.01:
		_stat("value",traded)
		if int(p.get("since",-1))<0:
			p["since"]=day
			if a=="player" or b=="player": _news("partner",a,b,"",day)
		# Gifts warm the one who receives them; trade warms both a little.
		var gift_ab:=(traded_ab-traded_ba) if form=="gift" else 0.0
		if gift_ab>0.0 or float(gifts.ab)>0.0: _warm(b,a,_goodwill(maxf(gift_ab,0.0)+float(gifts.ab),b))
		if gift_ab<0.0 or float(gifts.ba)>0.0: _warm(a,b,_goodwill(maxf(-gift_ab,0.0)+float(gifts.ba),a))
		if opinion(a,b)<WARMTH_CEILING: _warm(a,b,WARMTH)
		if form=="gift" and traded_ab>0.01 and traded_ba>0.01:
			p["gift_seasons"]=int(p.get("gift_seasons",0))+1
			if int(p.get("meet",-1))<0 and int(p.gift_seasons)>=MEETING_SEASONS and opinion(a,b)>=-0.1:
				p["meet"]=day
				if a=="player" or b=="player": _news("meeting",a,b,"",day)
	stances.call("after_settle",p,day)

## The exchange form two peoples can use now.
static func form_of(p:Dictionary,ra:Dictionary,rb:Dictionary)->String:
	var sa:=String(ra.get("stage","subsistence")); var sb:=String(rb.get("stage","subsistence"))
	if sa=="currency" and sb=="currency": return "coin"
	if sa!="subsistence" and sb!="subsistence": return "silver"
	if int(p.get("meet",-1))>=0 or (bool(ra.get("cmp",false)) and bool(rb.get("cmp",false))): return "barter"
	return "gift"

## Value two peoples' carriers can bring in one settlement (the seller's
## prices; a load of a good uses value/CARRY of it).
static func capacity(a:String,b:String,form:String,period:int,ra:Dictionary={},rb:Dictionary={})->float:
	if ra.is_empty(): ra=report(a)
	if rb.is_empty(): rb=report(b)
	var people:=minf(float(ra.get("pop",1.0)),float(rb.get("pop",1.0)))
	# A great work that draws strangers' traders (great_works_rivalry.trade_routing) brings more to its holder's market.
	var drawn:=maxf(float(ra.get("gw",0.0)),float(rb.get("gw",0.0)))
	return people*float(INTENSITY.get(form,0.06))*float(period)/30.0*reach(a,b,ra,rb)*(1.0+clampf((float(ra.get("tc",0.0))+float(rb.get("tc",0.0)))*0.5,0.0,2.0))*(1.0+drawn)

## 0..1: how much of the form's intensity reaches across the distance.
static func reach(a:String,b:String,ra:Dictionary,rb:Dictionary)->float:
	var logistics:=clampf((float(ra.get("log",0.16))+float(rb.get("log",0.16)))*0.5,0.0,1.0)
	var km:=REACH_KM*(1.0+logistics)
	if bool(ra.get("boats",false)) and bool(rb.get("boats",false)): km*=BOAT_REACH*clampf(minf(float(ra.get("sea",1.0)),float(rb.get("sea",1.0))),0.2,1.0)
	return 1.0/(1.0+distance_km(a,b)/maxf(1.0,km))

static func by_water(ra:Dictionary,rb:Dictionary)->bool:
	return bool(ra.get("boats",false)) and bool(rb.get("boats",false))

## What `seller` would send `buyer` within `budget` (value): the goods the
## buyer lacks most first. deny: goods the seller will not send; flood: a
## good the seller pushes past the buyer's need; discount: the share of its
## price the seller gives up (favour); buying: goods the buyer is buying up
## (a squeeze elsewhere), all the seller offers of them at SQUEEZE premium.
static func _fill(seller_rep:Dictionary,buyer_rep:Dictionary,seller:String,budget:float,deny:Array,flood:String,discount:float,buying:Array,form:String)->Dictionary:
	var out:={"goods":{},"value":0.0}
	if budget<=0.0: return out
	var picks:Array=[]
	var sg:Dictionary=seller_rep.get("g",{}); var bg:Dictionary=buyer_rep.get("g",{})
	for good:String in GOODS:
		if good in deny: continue
		var offer:=offer_of(sg,good)
		if offer<=0.001: continue
		var want:=want_of(bg,good)
		var bought:=good in buying and form!="gift"
		if bought: want=maxf(want,offer)
		if good==flood: want=maxf(want,float((bg.get(good,{}) as Dictionary).get("d",0.0))*0.5)
		if want<=0.001: continue
		var price:=float((sg.get(good,{}) as Dictionary).get("v",Prices.base(good)))*(1.0-clampf(discount,0.0,0.9))
		if bought: price*=SQUEEZE_PREMIUM
		var need:=want/maxf(1.0,float((bg.get(good,{}) as Dictionary).get("d",1.0)))
		picks.append({"good":good,"q":minf(offer,want),"v":maxf(0.01,price),"w":need*float(CARRY.get(good,1.0))+(10.0 if bought or good==flood else 0.0)})
	picks.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.w)>float(y.w) or (float(x.w)==float(y.w) and String(x.good)<String(y.good)))
	var left:=budget
	for pick:Dictionary in picks:
		if left<=0.0001: break
		var per:=float(pick.v)/float(CARRY.get(String(pick.good),1.0))
		var q:=minf(float(pick.q),left/maxf(0.0001,per))
		if q<=0.0001: continue
		(out.goods as Dictionary)[String(pick.good)]=q
		out["value"]=float(out.value)+q*float(pick.v)
		left-=q*per
	return out

static func _scaled(load_:Dictionary,share:float)->Dictionary:
	var out:={"goods":{},"value":float(load_.get("value",0.0))*clampf(share,0.0,1.0)}
	for good:String in (load_.goods as Dictionary): (out.goods as Dictionary)[good]=float(load_.goods[good])*clampf(share,0.0,1.0)
	return out

## Units of a good a people parts with in one settlement.
static func offer_of(g:Dictionary,good:String)->float:
	var x:Dictionary=g.get(good,{})
	if x.is_empty() or not bool(x.get("k",false)): return 0.0
	return maxf(0.0,float(x.get("s",0.0))-float(x.get("d",0.0))*OFFER_OVER)*OFFER_SHARE

## Units of a good a people lacks against its wanted holding.
static func want_of(g:Dictionary,good:String)->float:
	var x:Dictionary=g.get(good,{})
	if x.is_empty(): return 0.0
	if not bool(x.get("k",false)) and not good in BASIC: return 0.0
	return maxf(0.0,float(x.get("d",0.0))-float(x.get("s",0.0)))

## Moves the goods from one people's stores to the other's; what arrived.
static func _carry(from:String,to:String,goods:Dictionary)->Dictionary:
	var out:={}
	for good:String in goods:
		var got:=move(from,to,good,float(goods[good]))
		if got>0.0001: out[good]=got
	return out

static func _worth(goods:Dictionary,seller:String)->float:
	var total:=0.0
	for good:String in goods: total+=float(goods[good])*Prices.value(good,seller)
	return total

static func _rounded(goods:Dictionary)->Dictionary:
	var out:={}
	for good:String in goods: out[good]=snappedf(float(goods[good]),0.01)
	return out

## One good from one people's stores to another's: what arrived. The god's
## people and every simulated people trade from their capital's stores; a
## people the world does not simulate gives and takes food from its counted
## food days only.
static func move(from:String,to:String,good:String,qty:float)->float:
	if qty<=0.0 or from==to: return 0.0
	var taken:=_take(from,good,qty)
	if taken<=0.0: return 0.0
	var got:=_give(to,good,taken)
	_note_report(from,good,-taken)
	_note_report(to,good,got)
	return got

static func _take(owner:String,good:String,qty:float)->float:
	if simulated(owner): return EXCHANGE.take(owner,good,qty)
	if good!="Food": return 0.0
	var c:=civ(owner)
	if c.is_empty(): return 0.0
	var pop:=maxf(1.0,float(c.get("population",1.0)))
	var have:=maxf(0.0,float(c.get("food_days",0.0)))*pop
	var sent:=minf(qty,have)
	c["food_days"]=maxf(0.0,float(c.get("food_days",0.0))-sent/pop)
	return sent

static func _give(owner:String,good:String,qty:float)->float:
	if simulated(owner): return EXCHANGE.receive(owner,good,qty)
	var c:=civ(owner)
	if c.is_empty(): return 0.0
	c["gift_value_received"]=maxf(0.0,float(c.get("gift_value_received",0.0)))+qty*Prices.base(good)
	if good!="Food": return qty
	c["food_days"]=clampf(float(c.get("food_days",0.0))+qty/maxf(1.0,float(c.get("population",1.0))),0.0,180.0)
	return qty

## A toll or tribute paid in money where the form allows, else in kind from
## the payer's plenty. Returns the value that reached the receiver.
static func _levy(payer:String,receiver:String,amount:float,form:String,kind:String="toll")->float:
	if amount<=0.0: return 0.0
	if form in ["silver","coin"]:
		var got:=-purse(payer,-amount,"%s to %s" % [kind,name_of(receiver)])
		if got>0.0:
			purse(receiver,got,"%s from %s" % [kind,name_of(payer)])
			note_kind(payer,receiver,kind,got)
		if got>=amount-0.01: return got
		return got+pay_in_kind(payer,receiver,amount-got,"",kind)
	return pay_in_kind(payer,receiver,amount,"",kind)

## Goods worth `amount` from what the payer holds most of (over its wanted
## holding first, then anything but its last food), to the receiver.
static func pay_in_kind(payer:String,receiver:String,amount:float,preferred:String="",kind:String="levy")->float:
	if amount<=0.0: return 0.0
	var rep:=engine_report(payer,_day())
	_fresh(payer,rep)
	var g:Dictionary=rep.get("g",{})
	var order:Array=[]
	for good:String in GOODS:
		var x:Dictionary=g.get(good,{})
		if x.is_empty() or not bool(x.get("k",false)): continue
		var spare:=maxf(0.0,float(x.get("s",0.0))-float(x.get("d",0.0))*0.5)
		if spare<=0.0: continue
		order.append({"good":good,"spare":spare,"v":maxf(0.01,float(x.get("v",Prices.base(good)))),"first":good==preferred})
	order.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return bool(x.first) and not bool(y.first) or (bool(x.first)==bool(y.first) and float(x.spare)*float(x.v)>float(y.spare)*float(y.v)))
	var left:=amount
	var paid:=0.0
	for o:Dictionary in order:
		if left<=0.01: break
		var q:=minf(float(o.spare),left/float(o.v))
		var got:=move(payer,receiver,String(o.good),q)
		var worth:=got*float(o.v)
		paid+=worth; left-=worth
		_book_pair(payer,receiver,String(o.good),got)
		note_kind(payer,receiver,kind,worth)
	return paid

## A gift of `value` from the giver's plenty toward what the taker lacks or
## knows; what reached them.
static func _gift(giver:String,taker:String,size:float,giver_rep:Dictionary,taker_rep:Dictionary)->float:
	var load_:=_fill(giver_rep,taker_rep,giver,size,[],"",0.0,[],"gift")
	if float(load_.value)<size*0.5:
		# Nothing they lack: what we have most of that they know.
		return pay_in_kind(giver,taker,size,"","gift")
	var moved:=_carry(giver,taker,load_.goods)
	for good:String in moved: _book_pair(giver,taker,good,float(moved[good]))
	var worth:=_worth(moved,giver)
	note_kind(giver,taker,"gift",worth)
	return worth

## A gift's warmth, by its worth a head of the receiver.
static func _goodwill(value:float,receiver:String)->float:
	return clampf(value/maxf(1.0,population(receiver)*GOODWILL_VALUE)*GOODWILL_MAX,0.0,GOODWILL_MAX)

## `who`'s regard for `toward` changes by delta (and the border eases).
static func _warm(who:String,toward:String,delta:float)->void:
	if absf(delta)<0.00001: return
	if who=="player" or toward=="player":
		var other:=toward if who=="player" else who
		Hall._shift_relation(other,delta,-maxf(0.0,delta)*0.5)
		return
	shift_pair(who,toward,delta,-maxf(0.0,delta)*0.5)

## Two other peoples' regard for each other: their pair relation (the god's
## record of them) and the receiving people's own view.
static func shift_pair(who:String,toward:String,opinion_delta:float,tension_delta:float)->void:
	var civs:Array=CivilizationSystem.civilizations
	var i:=-1; var j:=-1
	for index in civs.size():
		var id:=String((civs[index] as Dictionary).get("id",""))
		if id==who: i=index
		elif id==toward: j=index
	if i<0 or j<0: return
	var rel:Dictionary=(((civs[i] as Dictionary).get("relations",{}) as Dictionary).get(toward,{}) as Dictionary).duplicate(true)
	if rel.is_empty(): return
	rel["opinion"]=clampf(float(rel.get("opinion",0.0))+opinion_delta,-1.0,1.0)
	rel["border_tension"]=clampf(float(rel.get("border_tension",0.0))+tension_delta,0.0,1.0)
	CivilizationSystem._set_pair_relation(mini(i,j),maxi(i,j),rel)
	if WorldSimulation.actors.has(who):
		WorldSimulation.scoped(who,func()->void:
			for c in WorldSimulation.world.civilizations:
				if String((c as Dictionary).get("id",""))!=toward: continue
				var view:Dictionary=(c as Dictionary).get("player_relation",{})
				view["opinion"]=clampf(float(view.get("opinion",0.0))+opinion_delta,-1.0,1.0)
				(c as Dictionary)["player_relation"]=view
				return)

# --------------------------------------------------------------------------
# What other systems move (pacts, tribute, spoils, envoys' gifts)
# --------------------------------------------------------------------------

## Goods another system moved between two peoples (already moved: this only
## books them). kind: "pact", "tribute", "spoils", "gift", "levy".
static func note_flow(from:String,to:String,good:String,qty:float,kind:String="")->void:
	from=owner_of(from); to=owner_of(to)
	if qty<=0.0 or from==to or not good in GOODS: return
	var p:=ensure_pair(from,to)
	var dir:="ab" if String(p.a)==from else "ba"
	var acc:Dictionary=p.get("acc",{})
	if not acc.get(dir) is Dictionary: acc[dir]={}
	(acc[dir] as Dictionary)[good]=float((acc[dir] as Dictionary).get(good,0.0))+qty
	p["acc"]=acc
	_note_report(from,good,-qty)
	_note_report(to,good,qty)
	if kind!="": note_kind(from,to,kind,qty*Prices.base(good))

## The pair's record, made when two peoples first pass goods.
static func ensure_pair(from:String,to:String)->Dictionary:
	var s:=state()
	var k:=key(from,to)
	var p:Dictionary=(s.pairs as Dictionary).get(k,{})
	if not p.is_empty(): return p
	var a:=from if from<to else to
	var b:=to if a==from else from
	p={"a":a,"b":b,"since":-1,"met":_day(),"next":_day()+1+posmod(hash(k),30),"form":"gift","meet":-1,"gift_seasons":0,"owed":0.0,
		"ema":{"ab":{},"ba":{}},"val":{"ab":0.0,"ba":0.0},"acc":{"ab":{},"ba":{}},"kinds":{},"last":{},"total":{"ab":0.0,"ba":0.0},"last_day":_day()}
	s.pairs[k]=p
	revision+=1
	return p

## Goods `move` already carried, booked to the pair's flows (folded into its
## smoothed flows at its next settlement): what leaned one people on another.
static func _book_pair(from:String,to:String,good:String,qty:float)->void:
	if qty<=0.0 or from==to: return
	var p:=pair(from,to)
	if p.is_empty(): return
	var dir:="ab" if String(p.a)==from else "ba"
	var acc:Dictionary=p.get("acc",{})
	if not acc.get(dir) is Dictionary: acc[dir]={}
	(acc[dir] as Dictionary)[good]=float((acc[dir] as Dictionary).get(good,0.0))+qty
	p["acc"]=acc

## The worth of what passed between two peoples by kind (tribute, spoils...),
## kept per direction for the Trade page.
static func note_kind(from:String,to:String,kind:String,value:float)->void:
	if value<=0.0 or kind=="": return
	var p:=pair(from,to)
	if p.is_empty(): return
	var dir:="ab" if String(p.a)==from else "ba"
	var kinds:Dictionary=p.get("kinds",{})
	var row:Dictionary=kinds.get(dir+":"+kind,{"value":0.0,"day":-1})
	row["value"]=float(row.get("value",0.0))+value
	row["day"]=_day()
	kinds[dir+":"+kind]=row
	p["kinds"]=kinds

static func _note_report(owner:String,good:String,qty:float)->void:
	var reps:Dictionary=state().reports
	var r:Dictionary=reps.get(owner,{})
	if r.is_empty(): return
	var field:="acc_in" if qty>0.0 else "acc_out"
	if not r.get(field) is Dictionary: r[field]={}
	(r[field] as Dictionary)[good]=float((r[field] as Dictionary).get(good,0.0))+absf(qty)
	var g:Dictionary=r.get("g",{})
	if g.has(good): (g[good] as Dictionary)["s"]=maxf(0.0,float((g[good] as Dictionary).get("s",0.0))+qty)

## Monthly: food taken in raids either way, from the war's own records
## (war_loop's log for their raids on us; our bands' battles for ours).
static func _fold(day:int)->void:
	var s:=state()
	var fold:Dictionary=s.fold
	var since:=int(fold.get("raids",-1))
	var war:=load(WAR_PATH) as GDScript
	if war!=null:
		var entries:Array=(war.call("state") as Dictionary).get("log",[])
		for entry in entries:
			if not entry is Dictionary: continue
			var d:=int((entry as Dictionary).get("day",-1))
			if d<=since: continue
			if String((entry as Dictionary).get("kind","")) in ["raid","skirmish","ambush"] and int((entry as Dictionary).get("taken",0))>0:
				note_flow("player",String((entry as Dictionary).get("civ","")),"Food",float((entry as Dictionary).taken),"spoils")
	var mc:Variant=WorldSimulation.military
	if mc!=null:
		for record in mc.battle_history:
			if not record is Dictionary: continue
			var d2:=int((record as Dictionary).get("day",-1))
			if d2<=since: continue
			var outcome:Dictionary=(record as Dictionary).get("strategic_outcome",{}) if (record as Dictionary).get("strategic_outcome") is Dictionary else {}
			var spoils:Dictionary=outcome.get("raid_spoils",{}) if outcome.get("raid_spoils") is Dictionary else {}
			var food:=float(spoils.get("Food",0.0))
			var enemy:=String((record as Dictionary).get("opponent_id",(record as Dictionary).get("enemy_id","")))
			if food>0.0 and enemy!="" and String((record as Dictionary).get("home_side",""))=="attacker": note_flow(enemy,"player","Food",food,"spoils")
	fold["raids"]=day

# --------------------------------------------------------------------------
# Reports: what each people holds, makes, uses and brings in
# --------------------------------------------------------------------------

## A people's market reading as the ledger last took it. A reading never
## writes: a people not yet read is read for the asking, and not kept.
static func report(owner:String,_day_unused:int=-1)->Dictionary:
	var s:=peek()
	var r:Variant=(s.get("reports",{}) as Dictionary).get(owner) if not s.is_empty() else null
	if r is Dictionary and not (r as Dictionary).is_empty(): return r
	return _read(owner,_day(),{})

## The engine's reading: taken anew on each people's own monthly day
## (advance), and the first time a people trades; kept in the ledger.
static func engine_report(owner:String,day:int)->Dictionary:
	var reps:Dictionary=state().reports
	var r:Dictionary=reps.get(owner,{})
	if not r.is_empty(): return r
	r=_read(owner,day,{})
	reps[owner]=r
	return r

static func _refresh_report(owner:String,day:int)->void:
	var reps:Dictionary=state().reports
	var r:Dictionary=reps.get(owner,{})
	if not r.is_empty() and day-int(r.get("day",-99999))<REPORT_DAYS-5: return
	reps[owner]=_read(owner,day,r)

## The stocks and prices of a cached report brought up to today (cheap: no
## deposits are read).
static func _fresh(owner:String,r:Dictionary)->void:
	if r.is_empty() or int(r.get("fresh",-1))==_day(): return
	r["fresh"]=_day()
	var g:Dictionary=r.get("g",{})
	if not simulated(owner):
		var c:=civ(owner)
		if g.has("Food"): (g.Food as Dictionary)["s"]=maxf(0.0,float(c.get("food_days",0.0)))*maxf(1.0,float(c.get("population",1.0)))
		return
	WorldSimulation.scoped(owner,func()->void:
		for good:String in g:
			var x:Dictionary=g[good]
			x["s"]=WorldSimulation.food.total_stored() if good=="Food" else maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(good,0.0)))
			x["v"]=Prices.in_scope(good)
	)

static func _read(owner:String,day:int,prev:Dictionary)->Dictionary:
	if not simulated(owner): return _read_unsimulated(owner,day,prev)
	return WorldSimulation.scoped(owner,func()->Dictionary:
		var st=WorldSimulation.state
		var eco=WorldSimulation.economy
		var pop:=maxf(1.0,float(st.population_exact))
		var last_day:=int(prev.get("day",day-REPORT_DAYS))
		var elapsed:=float(clampi(day-last_day,1,400))
		var weight:=1.0-pow(1.0-MONTH_WEIGHT,elapsed/30.0)
		var cum:={}
		for dep in st.resource_deposits:
			if dep is Dictionary: cum[String(dep.get("resource",""))]=float(cum.get(String(dep.get("resource","")),0.0))+float(dep.get("lifetime_delivered",0.0))
		var food_made:=0.0
		var gap_from:=last_day
		for entry in st.food_history:
			if not entry is Dictionary: continue
			var d:=int(entry.get("day",-1))
			if d<=gap_from: continue
			food_made+=float(entry.get("produced",0.0))*float(mini(d-gap_from,30)); gap_from=d
		var food_use:=float(st.simulation_metrics.get("food_consumption",pop))*elapsed
		var acc_in:Dictionary=prev.get("acc_in",{}); var acc_out:Dictionary=prev.get("acc_out",{})
		var old_g:Dictionary=prev.get("g",{})
		var goods:={}
		for good:String in GOODS:
			var stock:=WorldSimulation.food.total_stored() if good=="Food" else maxf(0.0,float(st.resource_stockpiles.get(good,0.0)))
			var known:=good=="Food" or bool(eco._resource_is_economically_known(good,stock))
			var old:Dictionary=old_g.get(good,{})
			var made:=food_made if good=="Food" else maxf(0.0,float(cum.get(good,0.0))-float(old.get("c",cum.get(good,0.0))))
			var came:=float(acc_in.get(good,0.0)); var went:=float(acc_out.get(good,0.0))
			var used:=food_use if good=="Food" else maxf(0.0,made+came-went-(stock-float(old.get("s0",stock))))
			var month:=30.0/elapsed
			goods[good]={"s":stock,"s0":stock,"d":float(eco._desired_stock(good,pop)),"k":known,"v":Prices.in_scope(good),"c":float(cum.get(good,0.0)),
				"p":_ema(old,"p",made*month,weight),"u":_ema(old,"u",used*month,weight),"m":_ema(old,"m",came*month,weight),"x":_ema(old,"x",went*month,weight)}
		var boats:=false
		for id in BOATS:
			if st.known_discoveries.has(id): boats=true; break
		return {"day":day,"fresh":day,"pop":pop,"stage":String(st.economy_stage),"cmp":bool(eco._comparison_values_observable()),"log":float(st.simulation_metrics.get("logistics",0.16)),
			"tc":float(WorldSimulation.discovery.effect("trade_capacity")),"gw":float((load("res://scripts/great_works_rivalry.gd") as GDScript).call("trade_routing",owner)),"boats":boats,"sea":float(WorldSimulation.military.joint_operations.sea_trade_factor()) if WorldSimulation.military!=null and WorldSimulation.military.get("joint_operations")!=null else 1.0,
			"sim":true,"g":goods,"acc_in":{},"acc_out":{}})

static func _read_unsimulated(owner:String,day:int,prev:Dictionary)->Dictionary:
	var c:=civ(owner)
	var pop:=maxf(1.0,float(c.get("population",100.0)))
	var old:Dictionary=(prev.get("g",{}) as Dictionary).get("Food",{})
	var last_day:=int(prev.get("day",day-REPORT_DAYS))
	var elapsed:=float(clampi(day-last_day,1,400))
	var weight:=1.0-pow(1.0-MONTH_WEIGHT,elapsed/30.0)
	var came:=float((prev.get("acc_in",{}) as Dictionary).get("Food",0.0)); var went:=float((prev.get("acc_out",{}) as Dictionary).get("Food",0.0))
	var food:={"s":maxf(0.0,float(c.get("food_days",30.0)))*pop,"d":pop*30.0,"k":true,"v":Prices.base("Food"),"c":0.0,
		"p":_ema(old,"p",maxf(0.0,float(c.get("food_capacity",pop)))*30.0,weight),"u":_ema(old,"u",pop*30.0,weight),"m":_ema(old,"m",came*30.0/elapsed,weight),"x":_ema(old,"x",went*30.0/elapsed,weight)}
	return {"day":day,"fresh":day,"pop":pop,"stage":"subsistence","cmp":false,"log":clampf(float(c.get("logistics",0.16)),0.0,1.0),"tc":0.0,"boats":false,"sea":1.0,"sim":false,"g":{"Food":food},"acc_in":{},"acc_out":{}}

static func _ema(old:Dictionary,field:String,now:float,weight:float)->float:
	if not old.has(field): return now
	return lerpf(float(old[field]),now,clampf(weight,0.0,1.0))

## Each settlement's goods, turned to monthly rates, move the pair's
## smoothed flows (MONTH_WEIGHT a month).
static func _smooth(p:Dictionary,moved:Dictionary,value:Dictionary,elapsed:int)->void:
	revision+=1
	var weight:=1.0-pow(1.0-MONTH_WEIGHT,float(elapsed)/30.0)
	var month:=30.0/float(maxi(1,elapsed))
	var ema:Dictionary=p.get("ema",{"ab":{},"ba":{}})
	var val:Dictionary=p.get("val",{"ab":0.0,"ba":0.0})
	for dir in ["ab","ba"]:
		var flows:Dictionary=ema.get(dir,{})
		var now:Dictionary=moved.get(dir,{})
		var names:={}
		for good in flows: names[good]=true
		for good in now: names[good]=true
		for good:String in names:
			var next:=lerpf(float(flows.get(good,0.0)),float(now.get(good,0.0))*month,weight)
			if next<0.001: flows.erase(good)
			else: flows[good]=next
		ema[dir]=flows
		val[dir]=lerpf(float(val.get(dir,0.0)),float(value.get(dir,0.0))*month,weight)
	p["ema"]=ema
	p["val"]=val

# --------------------------------------------------------------------------
# The dependence ledger
# --------------------------------------------------------------------------

## Monthly units of `good` that flow from `from` to `to` (smoothed).
static func flow(from:String,to:String,good:String)->float:
	var p:=pair(from,to)
	if p.is_empty(): return 0.0
	var dir:="ab" if String(p.a)==from else "ba"
	return float(((p.get("ema",{}) as Dictionary).get(dir,{}) as Dictionary).get(good,0.0))

## Every good that flows from `from` to `to`: {good: monthly units}.
static func flows(from:String,to:String)->Dictionary:
	var p:=pair(from,to)
	if p.is_empty(): return {}
	var dir:="ab" if String(p.a)==from else "ba"
	return ((p.get("ema",{}) as Dictionary).get(dir,{}) as Dictionary).duplicate()

## Monthly value of everything that flows from `from` to `to`.
static func flow_value(from:String,to:String)->float:
	var p:=pair(from,to)
	if p.is_empty(): return 0.0
	return float((p.get("val",{}) as Dictionary).get("ab" if String(p.a)==from else "ba",0.0))

## The share (0..1) of `owner`'s monthly supply of `good` (own output and all
## that comes in) that comes from `from`.
static func share(owner:String,from:String,good:String)->float:
	var r:=report(owner)
	var x:Dictionary=(r.get("g",{}) as Dictionary).get(good,{})
	var supply:=float(x.get("p",0.0))+float(x.get("m",0.0))
	var theirs:=flow(from,owner,good)
	if theirs<=0.0001: return 0.0
	return clampf(theirs/maxf(theirs,supply),0.0,1.0)

## Days `owner`'s stores of `good` last without what `from` sends: -1 when
## they would not run short (they make or get enough elsewhere).
static func days_without(owner:String,from:String,good:String)->float:
	var r:=report(owner)
	var x:Dictionary=(r.get("g",{}) as Dictionary).get(good,{})
	if x.is_empty(): return -1.0
	var stock:=float(x.get("s",0.0))
	var drain:=(float(x.get("u",0.0))-float(x.get("p",0.0))-maxf(0.0,float(x.get("m",0.0))-flow(from,owner,good)))/30.0
	if drain<=maxf(0.0001,stock*0.0005): return -1.0
	return stock/drain

## How much `owner` leans on `from`, 0..1: the shares of its supply weighted
## by what each good is worth to it.
static func dependence(owner:String,from:String)->float:
	var r:=report(owner)
	var g:Dictionary=r.get("g",{})
	var total:=0.0; var leaning:=0.0
	for good:String in flows(from,owner):
		var x:Dictionary=g.get(good,{})
		var worth:=(float(x.get("p",0.0))+float(x.get("m",0.0)))*float(x.get("v",Prices.base(good)))
		if worth<=0.0: continue
		total+=worth; leaning+=worth*share(owner,from,good)
	if total<=0.0: return 0.0
	# Weighed against everything the people supplies itself with.
	var all:=0.0
	for good:String in g:
		var y:Dictionary=g[good]
		all+=(float(y.get("p",0.0))+float(y.get("m",0.0)))*float(y.get("v",Prices.base(good)))
	return clampf(leaning/maxf(total,all*0.25),0.0,1.0)

## The good `owner` leans on `from` for most: {good, share, days} or {}.
static func most_needed(owner:String,from:String)->Dictionary:
	var best:={}
	for good:String in flows(from,owner):
		var s:=share(owner,from,good)
		if s<0.05: continue
		if best.is_empty() or s>float(best.share): best={"good":good,"share":s,"days":days_without(owner,from,good)}
	return best

## Every reading for one direction: what flows, and the leaning it makes.
static func reading(owner:String,from:String)->Array:
	var out:Array=[]
	for good:String in flows(from,owner):
		var monthly:=flow(from,owner,good)
		if monthly<0.01: continue
		out.append({"good":good,"monthly":monthly,"share":share(owner,from,good),"days":days_without(owner,from,good)})
	out.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.share)>float(y.share) or (float(x.share)==float(y.share) and String(x.good)<String(y.good)))
	return out

# --------------------------------------------------------------------------
# The purse: the one door for money
# --------------------------------------------------------------------------

## Every money move of trade (tolls and tribute in, gifts and purchases out,
## priced trade both ways) goes through here, so one change can send it to
## the realm's treasury when that lands (realm_purse.gd: balance, deposit,
## spend, unit_word). Today it writes the capital's own accounts: coin in
## the public treasury (with the bullion behind it, so the money supply stays
## whole) once a people mints coin; weighed metal ("Coin" in its stores)
## before; nothing before money. amount>0 deposits, <0 spends; returns the
## signed amount that moved.
static func purse(owner:String,amount:float,why:String)->float:
	if absf(amount)<0.0001 or not simulated(owner): return 0.0
	return float(WorldSimulation.scoped(owner,func()->float:
		var st=WorldSimulation.state
		var economy=WorldSimulation.economy
		match String(st.economy_stage):
			"currency":
				if amount>0.0:
					st.monetary_reserve_metals["Foreign Coin"]=float(st.monetary_reserve_metals.get("Foreign Coin",0.0))+amount
					st.currency_supply+=amount
					st.public_treasury+=amount
					economy._ledger("trade_in",amount,"foreign","public",why)
					return amount
				var out:=minf(-amount,maxf(0.0,float(st.public_treasury)))
				if out<=0.0: return 0.0
				st.public_treasury-=out
				st.currency_supply=maxf(0.0,float(st.currency_supply)-out)
				economy._ledger("trade_out",out,"public","foreign",why)
				return -out
			"weighed_metal":
				var held:=maxf(0.0,float(st.resource_stockpiles.get("Coin",0.0)))
				if amount>0.0:
					st.resource_stockpiles["Coin"]=held+amount
					economy._ledger("trade_in",amount,"foreign","material_stores",why)
					return amount
				var spent:=minf(-amount,held)
				if spent<=0.0: return 0.0
				st.resource_stockpiles["Coin"]=held-spent
				economy._ledger("trade_out",spent,"material_stores","foreign",why)
				return -spent
		return 0.0))

static func purse_balance(owner:String)->float:
	if not simulated(owner): return 0.0
	return float(WorldSimulation.scoped(owner,func()->float:
		match String(WorldSimulation.state.economy_stage):
			"currency": return maxf(0.0,float(WorldSimulation.state.public_treasury))
			"weighed_metal": return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get("Coin",0.0)))
		return 0.0))

## The people's word for its money: "" before money, "silver", "coin".
static func purse_unit(owner:String)->String:
	var stage:=String(report(owner).get("stage","subsistence"))
	return "coin" if stage=="currency" else ("silver" if stage=="weighed_metal" else "")

# --------------------------------------------------------------------------
# What trade gives each people (economy_system, civilization_system)
# --------------------------------------------------------------------------

## Smoothed flows change only at a settlement: readings the economy takes
## every day for every people are kept until then (never saved).
static var revision:=0
static var _cache:={}
static var _cache_key:=-1

static func _cached(kind:String,owner:String,make:Callable)->Dictionary:
	var s:=peek()
	var stats:Dictionary=s.get("stats",{}) if not s.is_empty() else {}
	var key:=hash([revision,int(GameState.elapsed_days),(s.get("pairs",{}) as Dictionary).size() if not s.is_empty() else -1,float(stats.get("settlements",0.0)),float(stats.get("value",0.0))])
	if key!=_cache_key: _cache.clear(); _cache_key=key
	var k:=kind+":"+owner
	if not _cache.has(k): _cache[k]=make.call()
	return _cache[k]

## Real trade for the economy's market access (civilization_system
## player_effects): partners with goods actually moving, and the monthly value.
static func access(owner:String)->Dictionary:
	return _cached("access",owner,func()->Dictionary:return _access(owner))

static func _access(owner:String)->Dictionary:
	var s:=peek()
	if s.is_empty(): return {"partners":0,"value":0.0}
	var partners:=0; var value:=0.0
	# A partner is one whose trade is worth something to us: a hundredth of a
	# ration's worth a head a month or more.
	var least:=maxf(PARTNER_FLOOR,population(owner)*0.01)
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		if String(p.get("a",""))!=owner and String(p.get("b",""))!=owner: continue
		var v:=float((p.get("val",{}) as Dictionary).get("ab",0.0))+float((p.get("val",{}) as Dictionary).get("ba",0.0))
		if v>=least: partners+=1
		value+=v
	return {"partners":partners,"value":value}

## The economy's external trade for one people (civilization_exchange.quote):
## the last month's flows in and out, by value and goods.
static func summary(owner:String)->Dictionary:
	return _cached("summary",owner,func()->Dictionary:return _summary(owner)).duplicate(true)

static func _summary(owner:String)->Dictionary:
	var out:={"exports":0.0,"imports":0.0,"exported_goods":{},"imported_goods":{},"partners":0,"available":false}
	var s:=peek()
	if s.is_empty(): return out
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		var mine:=""
		if String(p.get("a",""))==owner: mine="ab"
		elif String(p.get("b",""))==owner: mine="ba"
		else: continue
		var theirs:="ba" if mine=="ab" else "ab"
		var val:Dictionary=p.get("val",{})
		out.exports=float(out.exports)+float(val.get(mine,0.0))
		out.imports=float(out.imports)+float(val.get(theirs,0.0))
		for good:String in ((p.get("ema",{}) as Dictionary).get(mine,{}) as Dictionary): (out.exported_goods as Dictionary)[good]=float((out.exported_goods as Dictionary).get(good,0.0))+float(p.ema[mine][good])
		for good:String in ((p.get("ema",{}) as Dictionary).get(theirs,{}) as Dictionary): (out.imported_goods as Dictionary)[good]=float((out.imported_goods as Dictionary).get(good,0.0))+float(p.ema[theirs][good])
		if float(val.get(mine,0.0))+float(val.get(theirs,0.0))>=PARTNER_FLOOR: out.partners=int(out.partners)+1
	out.available=int(out.partners)>0
	return out

## Every people `owner` trades with (pairs with goods moving), largest first.
static func partners(owner:String)->Array:
	var out:Array=[]
	var s:=peek()
	if s.is_empty(): return out
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		var other:=""
		if String(p.get("a",""))==owner: other=String(p.b)
		elif String(p.get("b",""))==owner: other=String(p.a)
		else: continue
		var v:=float((p.get("val",{}) as Dictionary).get("ab",0.0))+float((p.get("val",{}) as Dictionary).get("ba",0.0))
		out.append({"id":other,"value":v,"form":String(p.get("form","gift"))})
	out.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.value)>float(y.value) or (float(x.value)==float(y.value) and String(x.id)<String(y.id)))
	return out

# --------------------------------------------------------------------------
# News: told once (the alerts under the clock and the chronicle)
# --------------------------------------------------------------------------

## A piece of trade news for the god (only news that touches our people is
## kept). kind: partner, meeting, embargo, squeeze, toll, tribute_demand,
## yield, refuse, counter, supplier, raid, war, shortage, lifted, tribute.
static func _news(kind:String,a:String,b:String,good:String,day:int,extra:Dictionary={})->Dictionary:
	var s:=state()
	s.serial=int(s.get("serial",0))+1
	var item:={"id":int(s.serial),"day":day,"kind":kind,"a":a,"b":b,"good":good}
	item.merge(extra,true)
	var words:=load(WORDS_PATH) as GDScript
	item["text"]=String(words.call("news_line",item)) if words!=null else kind
	(s.news as Array).push_front(item)
	while (s.news as Array).size()>NEWS_MAX: (s.news as Array).pop_back()
	if words!=null: words.call("chronicle",item)
	return item

static func news(kind:String,a:String,b:String,good:String="",extra:Dictionary={})->Dictionary:
	return _news(kind,a,b,good,_day(),extra)

## News of the last NEWS_DAYS days, newest first.
static func recent_news(days:int=NEWS_DAYS)->Array:
	var s:=peek()
	if s.is_empty(): return []
	var today:=_day()
	var out:Array=[]
	for item in s.get("news",[]):
		if item is Dictionary and today-int((item as Dictionary).get("day",-99999))<=days: out.append(item)
	return out

static func _prune_news(day:int)->void:
	var list:Array=state().news
	while not list.is_empty() and day-int((list.back() as Dictionary).get("day",day))>365*3: list.pop_back()
