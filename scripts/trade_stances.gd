extends RefCounted
## ECONOMIC STANCES: economic power as pressure, and as war.
##
## Each people keeps a stance toward each people it knows, as the god keeps
## one toward each enemy on the War screen. What each does, in the engine's
## numbers (trade_ledger.gd carries them out at every settlement):
##   free     trade as it comes (every people's default).
##   favour   we sell to them FAVOUR_DISCOUNT below our price and trade grows
##            FAVOUR_VOLUME times: it costs us the discount, warms them and
##            leans them on us. With a good named ("flood their markets with
##            goods") we push that good past what they need.
##   toll     TOLL_SHARE of the worth of all trade between us comes to our
##            purse (in goods before money); trade falls to TOLL_VOLUME.
##   embargo  nothing passes either way: they lose what we sent, we lose
##            what they sent.
##   squeeze  one good they lean on: none of it goes from us, and we buy it
##            up from every other people we trade with, paying
##            trade_ledger.SQUEEZE_PREMIUM over the price (silver, coin or our
##            goods), so they cannot get it from them either.
##   tribute  a demand: goods worth TRIBUTE_SHARE of what they make each
##            season, for TRIBUTE_YEARS years.
##   gifts    each season a gift of GIFT_PER_HEAD a head of theirs from our
##            plenty: it costs our stores, warms them and leans them on us.
##            What they take and do not return is owed (the pair's "owed"):
##            an obligation that eases their answers by up to a tenth.
## The coercive stances (toll, embargo, squeeze, tribute) are ANSWERED. Word
## reaches them after the days a messenger takes (message_days); their
## answer is then rolled once, seeded, with the odds stated beforehand
## (odds()): from how much they lean on us, our strength against theirs
## (fighters, and wealth), their ruler's nature (temper and trait), the
## other peoples who could supply them instead, and the gifts they owe us. The answers: yield (pay the
## tribute, accept the toll, or come to terms with a payment), bear it, find
## another supplier, strike back with an embargo of their own, raid our
## traders, or war (war_loop.gd; a feud between small peoples) with the plain
## cause ("the flint embargo"). A stance that stands is answered again each
## year, sooner once a shortage bites them (after_settle).
## Every people uses these stances by its nature (review()), on others and,
## rarely and with real business, on us. Calibration: sanctions answered by
## the target giving way about one time in three when it leans hard on the
## sender (the twentieth century's record), rarely otherwise; tribute paid by
## the weaker neighbour, seldom by an equal; an embargo of a vital good
## sometimes the cause of war (a trade decree before a long war). Static.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Personality:=preload("res://scripts/leader_personality.gd")
const Standing:=preload("res://scripts/standing.gd")
const Prices:=preload("res://scripts/trade_prices.gd")
const WAR_PATH:="res://scripts/war_loop.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const WORDS_PATH:="res://scripts/trade_words.gd"
const LEVERS_PATH:="res://scripts/office_levers.gd"

const IDS:=["free","favour","toll","embargo","squeeze","tribute","gifts"]
const COERCIVE:=["toll","embargo","squeeze","tribute"]
const FAVOUR_DISCOUNT:=0.20
const FAVOUR_VOLUME:=1.4
const TOLL_SHARE:=0.10
const TOLL_VOLUME:=0.75
const TRIBUTE_SHARE:=0.04
const TRIBUTE_YEARS:=5
const GIFT_PER_HEAD:=0.5
## A people that found another supplier trades this much more with the
## others for a year.
const SUPPLIER_BOOST:=1.5
const BOOST_DAYS:=365
const REROLL_DAYS:=365
## A shortage bites when stores of a good they leaned on fall under this
## share of the holding they want.
const BITE_SHARE:=0.3
const BITE_LEANING:=0.2
const BITE_DAYS:=180
## A people's choices at its monthly review, as monthly hazards when their
## conditions hold (review()); toward the god's people they are halved and
## at most one hostile act in PLAYER_GAP days.
const PLAYER_GAP:=730
## Answers, in the order they are rolled.
const ANSWERS:=["yield","supplier","counter","raid","war","bear"]

# --------------------------------------------------------------------------
# Stances
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func skey(actor:String,target:String)->String:
	return "%s>%s" % [actor,target]

## The stance `actor` keeps toward `target`: {id, good, amount, since, ...}.
static func stance(actor:String,target:String)->Dictionary:
	var s:=Ledger.peek()
	if s.is_empty(): return {"id":"free"}
	var st:Variant=(s.get("stances",{}) as Dictionary).get(skey(actor,target))
	return st if st is Dictionary else {"id":"free"}

static func embargo_between(a:String,b:String)->String:
	if String(stance(a,b).get("id",""))=="embargo": return "embargo:"+a
	if String(stance(b,a).get("id",""))=="embargo": return "embargo:"+b
	return ""

## Sets a stance and says what it does. by: "god" (the god's word), "ai" (a
## people's own leaders), "answer" (a counter-embargo). Returns {ok, said,
## odds, answer_day, preview} or {ok:false, said}.
static func set_stance(actor:String,target:String,id:String,good:String="",amount:float=0.0,by:String="god")->Dictionary:
	if not id in IDS: return {"ok":false,"said":"There is no such way of dealing with a people."}
	if actor==target or not Ledger.alive(target): return {"ok":false,"said":"There is no such people to deal with."}
	if id=="squeeze" and good=="":
		var most:=Ledger.most_needed(target,actor)
		good=String(most.get("good",""))
		if good=="": good=_their_short_good(target)
		if good=="": return {"ok":false,"said":"They lean on us for nothing we could squeeze."}
	var s:=Ledger.state()
	var day:=_day()
	var k:=skey(actor,target)
	var before:=stance(actor,target)
	var preview:=preview_for(id,actor,target,good,amount)
	if id=="free":
		s.stances.erase(k)
		if String(before.get("id","free")) in COERCIVE: _lifted(actor,target,before)
		return {"ok":true,"said":String(preview.get("effect","")),"odds":{},"answer_day":-1,"preview":preview}
	# The same word again changes nothing: no second message, no second roll.
	if String(before.get("id","free"))==id and String(before.get("good",""))==good and s.stances.has(k):
		return {"ok":true,"said":String(preview.get("effect","")),"odds":odds(id,actor,target,good,float(before.get("amount",amount))),"answer_day":int(before.get("answer",-1)),"preview":preview,"same":true}
	var st:={"id":id,"good":good,"amount":snappedf(amount,0.01),"since":day,"by":by,"answer":-1}
	if id in COERCIVE:
		st["answer"]=day+message_days(actor,target)
		# What they leaned on us for, when the stance began: a shortage of it bites.
		var leaned:={}
		for row:Dictionary in Ledger.reading(target,actor):
			if float(row.share)>=0.05 and (id!="squeeze" or String(row.good)==good): leaned[String(row.good)]=snappedf(float(row.share),0.01)
		st["leaned"]=leaned
		st["lost"]=snappedf(Ledger.flow_value(target,actor),0.01)
		if id=="tribute" and amount<=0.0: st["amount"]=snappedf(tribute_size(target,actor),0.01)
	if id=="gifts" and amount<=0.0: st["amount"]=snappedf(gift_size(actor,target),0.01)
	s.stances[k]=st
	Ledger._stat("stance_"+id)
	# How it lands with them now: coercion cools them, gifts and favour warm in time.
	var cool:={"embargo":-0.05,"squeeze":-0.04,"toll":-0.03,"tribute":-0.04}
	if cool.has(id) and String(before.get("id",""))!=id: Ledger._warm(target,actor,float(cool[id]))
	if target=="player" and id in COERCIVE: Ledger.news(id,actor,target,good)
	if actor=="player" and target!="player" and id in ["embargo","squeeze","toll","tribute"] and by=="god":
		ForeignDiplomacy.remember(target,String((load(WORDS_PATH) as GDScript).call("remembered",st,actor)))
		# Their ruler trusts our word less (standing.gd reads it as their trust in us).
		Hall._leader_trust(target,-0.03)
	return {"ok":true,"said":String(preview.get("effect","")),"odds":odds(id,actor,target,good,float(st.get("amount",amount))),"answer_day":int(st.get("answer",-1)),"preview":preview}

## The good a people lacks most (for a squeeze with nothing yet flowing).
static func _their_short_good(owner:String)->String:
	var g:Dictionary=Ledger.report(owner).get("g",{})
	var best:=""; var worst:=1.0
	for good:String in Ledger.GOODS:
		var x:Dictionary=g.get(good,{})
		if x.is_empty() or good=="Food" or float(x.get("d",0.0))<=0.0: continue
		var held:=float(x.get("s",0.0))/float(x.d)
		if held<worst: worst=held; best=good
	return best

static func _lifted(actor:String,target:String,before:Dictionary)->void:
	Ledger._warm(target,actor,0.02)
	if actor=="player" or target=="player": Ledger.news("lifted",actor,target,String(before.get("good","")),{"stance":String(before.get("id",""))})

## Days for word to reach them: a messenger's road (intercivilization message days).
static func message_days(a:String,b:String)->int:
	var logistics:=clampf((float(Ledger.report(a).get("log",0.16))+float(Ledger.report(b).get("log",0.16)))*0.5,0.0,1.0)
	return clampi(ceili(Ledger.distance_km(a,b)/(17.0*(0.75+logistics*0.25))),3,90)

## What tribute a people pays a season by default: TRIBUTE_SHARE of what it
## makes in a season (its own output at its own prices).
static func tribute_size(payer:String,_payee:String="")->float:
	return output_season(payer)*TRIBUTE_SHARE

static func output_season(owner:String)->float:
	var g:Dictionary=Ledger.report(owner).get("g",{})
	var total:=0.0
	for good:String in g:
		var x:Dictionary=g[good]
		total+=float(x.get("p",0.0))*float(x.get("v",1.0))
	return total*3.0

## A season's gift: GIFT_PER_HEAD a head of the receiver, no more than a
## fiftieth of what the giver makes in a season.
static func gift_size(giver:String,taker:String)->float:
	return minf(Ledger.population(taker)*GIFT_PER_HEAD,maxf(1.0,output_season(giver)*0.02))

# --------------------------------------------------------------------------
# What stances do to one pair's settlement (trade_ledger._settle)
# --------------------------------------------------------------------------

static func pair_mods(a:String,b:String,day:int)->Dictionary:
	var mods:={"cap":1.0,"deny":{"ab":[],"ba":[]},"flood":{"ab":"","ba":""},"discount":{"ab":0.0,"ba":0.0},"toll":{"a":0.0,"b":0.0},"gift":{"ab":0.0,"ba":0.0},"buy":{"a":[],"b":[]}}
	for side:Array in [[a,b,"ab","a"],[b,a,"ba","b"]]:
		var st:=stance(String(side[0]),String(side[1]))
		var dir:=String(side[2])
		match String(st.get("id","free")):
			"favour":
				mods.cap=float(mods.cap)*FAVOUR_VOLUME
				(mods.discount as Dictionary)[dir]=FAVOUR_DISCOUNT
				if String(st.get("good",""))!="": (mods.flood as Dictionary)[dir]=String(st.good)
			"toll":
				mods.cap=float(mods.cap)*TOLL_VOLUME
				(mods.toll as Dictionary)[String(side[3])]=TOLL_SHARE
			"squeeze":
				((mods.deny as Dictionary)[dir] as Array).append(String(st.get("good","")))
			"gifts":
				(mods.gift as Dictionary)[dir]=float(st.get("amount",gift_size(String(side[0]),String(side[1]))))/3.0
		(mods.buy as Dictionary)[String(side[3])]=_buying(String(side[0]),String(side[1]))
	var p:=Ledger.pair(a,b)
	var boost:Dictionary=p.get("boost",{}) if p.get("boost") is Dictionary else {}
	for owner in boost:
		if int(boost[owner])>day: mods.cap=float(mods.cap)*SUPPLIER_BOOST; break
	return mods

## Goods `owner` is buying up (its squeezes on peoples other than `seller`).
static func _buying(owner:String,seller:String)->Array:
	var out:Array=[]
	var s:=Ledger.peek()
	if s.is_empty(): return out
	var stances:Dictionary=s.get("stances",{})
	for k:String in stances:
		if not k.begins_with(owner+">") or k==skey(owner,seller): continue
		var st:Dictionary=stances[k]
		if String(st.get("id",""))=="squeeze" and String(st.get("good",""))!="" and not out.has(String(st.good)): out.append(String(st.good))
	return out

## After a pair settles: a shortage that bites a people under an embargo or
## squeeze (its stores of a good it leaned on fall under BITE_SHARE of what
## it wants) costs its rulers standing at home, is told once, and brings its
## answer sooner.
static func after_settle(p:Dictionary,day:int)->void:
	for side:Array in [[String(p.a),String(p.b)],[String(p.b),String(p.a)]]:
		var actor:=String(side[0]); var target:=String(side[1])
		var st:=stance(actor,target)
		if not String(st.get("id","")) in ["embargo","squeeze"]: continue
		if day-int(st.get("bit",-99999))<BITE_DAYS: continue
		var g:Dictionary=Ledger.report(target).get("g",{})
		for good:String in (st.get("leaned",{}) as Dictionary):
			if float(st.leaned[good])<BITE_LEANING: continue
			var x:Dictionary=g.get(good,{})
			if x.is_empty() or float(x.get("d",0.0))<=0.0: continue
			if float(x.get("s",0.0))/float(x.d)>=BITE_SHARE: continue
			st["bit"]=day
			_hardship(target,"shortage of %s" % good,-0.02,-0.02,90)
			if actor=="player" or target=="player": Ledger.news("shortage",actor,target,good,{"share":float(st.leaned[good])})
			if int(st.get("answer",-1))>day+30: st["answer"]=day+30
			Ledger._stat("bites")
			break

# --------------------------------------------------------------------------
# Odds: the engine's own reading, stated before the roll
# --------------------------------------------------------------------------

## Everything the answer is weighed on.
static func factors(actor:String,target:String,good:String="")->Dictionary:
	var dep:=Ledger.share(target,actor,good) if good!="" else Ledger.dependence(target,actor)
	var temper:=Personality.of_owner(target)
	var trait_id:=trait_of(target)
	var ratio:=clampf(strength(actor)/maxf(1.0,strength(target)),0.1,10.0)
	var wealth:=clampf(econ(actor)/maxf(1.0,econ(target)),0.1,10.0)
	var fear:=0.0
	if actor=="player" and target!="player": fear=float(preload("res://scripts/divine_regard.gd").civ_dread(target))
	var sway:=0.0
	if actor=="player":
		var levers:=load(LEVERS_PATH) as GDScript
		if levers!=null: sway=float(levers.call("value","Envoy"))
	# Gifts unreturned are an obligation: a people that owes us gives way more readily.
	var obligation:=clampf(owed_to(actor,target)/maxf(1.0,output_season(target)*0.05),0.0,1.0)
	return {"dep":dep,"our_dep":Ledger.dependence(actor,target),"ratio":ratio,"wealth":wealth,"obligation":obligation,"assertive":float(temper.get("assertiveness",0.5)),
		"risk":float(temper.get("risk_tolerance",0.5)),"empathy":float(temper.get("empathy",0.5)),"discipline":float(temper.get("discipline",0.5)),
		"trait":trait_id,"alt":alternatives(target,actor,good),"fear":fear,"sway":sway,"opinion":Ledger.opinion(actor,target),"output":output_season(target)}

## The chance of each answer: {p:{yield, supplier, counter, raid, war, bear}, f}.
static func odds(id:String,actor:String,target:String,good:String="",amount:float=0.0)->Dictionary:
	var p:={"yield":0.0,"supplier":0.0,"counter":0.0,"raid":0.0,"war":0.0,"bear":0.0}
	if not id in COERCIVE or target=="player": return {"p":p,"f":{}}
	var f:=factors(actor,target,good)
	var dep:=float(f.dep); var alt:=float(f.alt); var a:=float(f.assertive); var r:=float(f.risk)
	var stronger:=clampf((float(f.ratio)-1.0)/2.0,-0.5,1.0)
	var richer:=clampf((float(f.wealth)-1.0)/3.0,-0.5,1.0)
	var sway:=float(f.sway)+0.10*float(f.get("obligation",0.0))
	match id:
		"toll":
			p.yield=0.30+0.35*dep+0.15*maxf(0.0,stronger)-0.25*(a-0.5)-0.20*alt+sway
			p.supplier=0.45*alt
			p.counter=0.06+0.15*maxf(0.0,a-0.4)+0.20*float(f.our_dep)
			p.raid=0.02+0.05*r
		"embargo","squeeze":
			p.yield=0.06+0.45*dep+0.20*maxf(0.0,stronger)+0.10*maxf(0.0,richer)-0.25*(a-0.5)-0.25*alt+sway
			p.supplier=0.55*alt
			p.counter=0.08+0.20*maxf(0.0,a-0.3)+0.25*float(f.our_dep)
			p.raid=(0.04+0.12*r+0.08*dep)*(0.4 if stronger>0.5 else 1.0)
			p.war=(0.015+0.10*dep*(1.0 if stronger<0.25 else 0.3)+0.08*maxf(0.0,a-0.5))*(0.3 if stronger>0.5 else 1.0)
		"tribute":
			var burden:=amount/maxf(1.0,float(f.output))
			p.yield=(0.04+0.30*dep+0.40*maxf(0.0,stronger)+0.10*float(f.fear)-0.25*(a-0.5)-0.15*alt+sway)*clampf(1.3-burden*4.0,0.2,1.2)
			p.counter=0.06+0.15*maxf(0.0,a-0.4)
			p.raid=(0.05+0.10*r)*(0.3 if stronger>0.5 else 1.0)
			p.war=0.03+0.12*maxf(0.0,-stronger)+0.06*maxf(0.0,a-0.5)
	match String(f.trait):
		"grudge": p.yield*=0.7; p.war*=1.6; p.counter*=1.3
		"hunter": p.raid*=1.6
		"bluffer": p.counter*=1.5; p.war*=0.6
		"ledger": p.yield*=1.1; p.supplier*=1.2
		"matchmaker": p.yield*=1.15; p.war*=0.5
		"magpie": p.supplier*=1.3
	# A people broken past fighting raids no one and goes to war with no one.
	var war:=load(WAR_PATH) as GDScript
	if target!="player" and war!=null and bool(war.call("broken",target)): p.raid=0.0; p.war=0.0
	var total:=0.0
	for answer in ANSWERS:
		if answer=="bear": continue
		p[answer]=maxf(0.0,float(p[answer])); total+=float(p[answer])
	if total>0.95:
		for answer in ANSWERS:
			if answer!="bear": p[answer]=float(p[answer])*0.95/total
		total=0.95
	p.bear=1.0-total
	return {"p":p,"f":f}

## The worth of gifts `debtor` has taken from `creditor` and not returned
## (the pair's owed balance, from the creditor's side; 0 when none).
static func owed_to(creditor:String,debtor:String)->float:
	var p:=Ledger.pair(creditor,debtor)
	if p.is_empty(): return 0.0
	var owed:=float(p.get("owed",0.0))
	return maxf(0.0,owed if String(p.a)==creditor else -owed)

## Fighting strength on one scale (standing.gd, as war_loop.ratio reads it).
static func strength(owner:String)->float:
	if owner=="player": return float(WorldSimulation.scoped("player",func()->float:return Standing.our_fighting_strength()))
	var c:=Ledger.civ(owner)
	return Standing.their_fighting_strength(c) if not c.is_empty() else 100.0

## Economic weight: a month's own output and a twelfth of what is stored, at the people's own prices.
static func econ(owner:String)->float:
	var g:Dictionary=Ledger.report(owner).get("g",{})
	var total:=0.0
	for good:String in g:
		var x:Dictionary=g[good]
		total+=(float(x.get("p",0.0))+float(x.get("s",0.0))/12.0)*float(x.get("v",1.0))
	return maxf(1.0,total)

## 0..1: how readily another people could supply `owner` with what `from`
## sends it (their surplus of those goods against what `from` sends).
static func alternatives(owner:String,from:String,good:String="")->float:
	var goods:Array=[good] if good!="" else Ledger.flows(from,owner).keys()
	if goods.is_empty(): return 0.0
	var need:=0.0; var could:=0.0
	for g:String in goods:
		var monthly:=Ledger.flow(from,owner,g)*3.0
		if good!="" and monthly<=0.0: monthly=maxf(1.0,float((((Ledger.report(owner).get("g",{}) as Dictionary).get(g,{})) as Dictionary).get("d",1.0))*0.25)
		need+=monthly
		for row:Dictionary in Ledger.partners(owner):
			var other:=String(row.id)
			if other==from or String(stance(other,owner).get("id",""))=="embargo" or String(stance(owner,other).get("id",""))=="embargo": continue
			could+=Ledger.offer_of(Ledger.report(other).get("g",{}),g)
	return clampf(could/maxf(0.01,need),0.0,1.0)

## The ruler's trait, where the god knows the ruler (rival_rulers.gd).
static func trait_of(owner:String)->String:
	if owner=="player" or ForeignDiplomacy.civilization(owner).is_empty(): return ""
	var rivals:=load(RIVALS_PATH) as GDScript
	if rivals==null: return ""
	return String((rivals.call("character",owner) as Dictionary).get("trait",""))

# --------------------------------------------------------------------------
# What a stance would do, in the engine's numbers (the Trade page, the court)
# --------------------------------------------------------------------------

## {effect (plain words), cost, gain, odds} for one stance toward one people.
static func preview_for(id:String,actor:String,target:String,good:String="",amount:float=0.0)->Dictionary:
	var words:=load(WORDS_PATH) as GDScript
	var out:={"id":id,"good":good}
	var p:=Ledger.pair(actor,target)
	var form:=String(p.get("form","gift")) if not p.is_empty() else "gift"
	var out_value:=Ledger.flow_value(actor,target); var in_value:=Ledger.flow_value(target,actor)
	match id:
		"favour":
			out["cost"]=out_value*FAVOUR_VOLUME*FAVOUR_DISCOUNT
			out["gain"]=(out_value+in_value)*(FAVOUR_VOLUME-1.0)
		"toll":
			out["gain"]=(out_value+in_value)*TOLL_VOLUME*TOLL_SHARE
			out["cost"]=(out_value+in_value)*(1.0-TOLL_VOLUME)
		"embargo":
			out["cost"]=in_value
			out["their_loss"]=out_value
		"squeeze":
			out["cost"]=Ledger.flow(actor,target,good)*Prices.value(good,actor)+_buy_up_cost(actor,target,good)
			out["their_loss"]=Ledger.flow(actor,target,good)
		"tribute":
			out["gain"]=amount if amount>0.0 else tribute_size(target,actor)
		"gifts":
			out["cost"]=amount if amount>0.0 else gift_size(actor,target)
	out["form"]=form
	if id in COERCIVE: out["odds"]=odds(id,actor,target,good,float(out.get("gain",amount)) if id=="tribute" else amount)
	out["effect"]=String(words.call("effect_line",out,actor,target)) if words!=null else id
	return out

## What buying a good up from every other partner would cost a month.
static func _buy_up_cost(actor:String,target:String,good:String)->float:
	var total:=0.0
	for row:Dictionary in Ledger.partners(actor):
		var other:=String(row.id)
		if other==target: continue
		total+=Ledger.offer_of(Ledger.report(other).get("g",{}),good)*Prices.value(good,other)*Ledger.SQUEEZE_PREMIUM/3.0
	return total

# --------------------------------------------------------------------------
# The day: answers due, tribute due, raids on traders, every people's review
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	var s:=Ledger.state()
	var stances:Dictionary=s.stances
	for k:String in stances.keys():
		var st:Variant=stances.get(k)
		if not st is Dictionary: continue
		var due:=int((st as Dictionary).get("answer",-1))
		if due>=0 and due<=day: _answer(k,st,day)
	var tributes:Dictionary=s.tributes
	for k:String in tributes.keys():
		var t:Variant=tributes.get(k)
		if t is Dictionary and int((t as Dictionary).get("next",0))<=day: _collect(k,t,day)
	var raids:Dictionary=s.raids
	for k:String in raids.keys():
		var r:Variant=raids.get(k)
		if not r is Dictionary: continue
		if int((r as Dictionary).get("until",0))<day: raids.erase(k); continue
		if int((r as Dictionary).get("next",0))<=day: _raid(k,r,day)
	for owner:String in WorldSimulation.actors.keys():
		if posmod(day+posmod(hash("trade_review:"+owner),30),30)==0: review(owner,day)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:trade:%s" % [int(GameState.world_seed),key])
	return rng

## Their answer, rolled once with the stated odds; the roll is kept.
static func _answer(k:String,st:Dictionary,day:int)->void:
	var actor:=k.get_slice(">",0); var target:=k.get_slice(">",1)
	if not Ledger.alive(actor) or not Ledger.alive(target) or target=="player":
		st["answer"]=-1
		return
	var id:=String(st.get("id",""))
	var o:=odds(id,actor,target,String(st.get("good","")),float(st.get("amount",0.0)))
	var p:Dictionary=o.p
	var roll:=_rng("answer:%s:%d" % [k,day]).randf()
	var kind:="bear"
	var acc:=0.0
	for answer in ANSWERS:
		acc+=float(p.get(answer,0.0))
		if roll<acc: kind=answer; break
	var record:={"day":day,"stance":id,"good":String(st.get("good","")),"kind":kind,"roll":snappedf(roll,0.001),"odds":_rounded(p),"dep":snappedf(float((o.f as Dictionary).get("dep",0.0)),0.01),"rolls":int(st.get("rolls",0))+1}
	(Ledger.state().answers as Dictionary)[k]=record
	st["rolls"]=int(record.rolls)
	st["last"]=kind
	st["answer"]=day+REROLL_DAYS if kind in ["bear","supplier","counter","raid"] else -1
	Ledger._stat("answer_"+kind)
	_apply(actor,target,st,kind,day)
	if actor=="player" or target=="player": Ledger.news(kind,actor,target,String(st.get("good","")),{"stance":id,"roll":record.roll,"chance":snappedf(float(p.get(kind,0.0)),0.01)})

static func _rounded(p:Dictionary)->Dictionary:
	var out:={}
	for k in p: out[k]=snappedf(float(p[k]),0.001)
	return out

static func _apply(actor:String,target:String,st:Dictionary,kind:String,day:int)->void:
	var id:=String(st.get("id",""))
	var cause:=String((load(WORDS_PATH) as GDScript).call("cause",st))
	match kind:
		"yield":
			match id:
				"tribute": _begin_tribute(target,actor,float(st.get("amount",tribute_size(target,actor))),day)
				"embargo","squeeze":
					# They come to terms: two seasons' tribute at once.
					var p:=Ledger.pair(actor,target)
					var paid:=Ledger._levy(target,actor,tribute_size(target,actor)*2.0,String(p.get("form","gift")) if not p.is_empty() else "gift","tribute")
					st["terms_paid"]=snappedf(paid,0.01)
					# A people's own leaders take the terms and open trade again.
					if actor!="player": set_stance(actor,target,"free","",0.0,"ai")
			# Their rulers gave way: it costs them at home, and they resent it.
			_hardship(target,"giving way to %s" % Ledger.name_of(actor),0.0,-0.03,365)
			Ledger._warm(target,actor,-0.05)
			if actor=="player":
				preload("res://scripts/divine_regard.gd").add_civ_dread(target,0.04)
				var rivals:=load(RIVALS_PATH) as GDScript
				if rivals!=null: rivals.call("grudge",target,"how you made us bow over %s" % cause,0.3,"trade_yield:%s:%d" % [target,day])
			_others_watch(actor,target,-0.02)
		"supplier":
			for row:Dictionary in Ledger.partners(target):
				var other:=String(row.id)
				if other==actor: continue
				var p2:=Ledger.pair(target,other)
				if p2.is_empty(): continue
				var boost:Dictionary=p2.get("boost",{}) if p2.get("boost") is Dictionary else {}
				boost[target]=day+BOOST_DAYS
				p2["boost"]=boost
		"counter":
			var answer_id:="toll" if id=="toll" else "embargo"
			set_stance(target,actor,answer_id,"",0.0,"answer")
		"raid":
			(Ledger.state().raids as Dictionary)[skey(target,actor)]={"until":day+365,"next":day+_rng("raid_first:%s:%s:%d" % [target,actor,day]).randi_range(15,60),"cause":cause,"count":0}
		"war":
			_war(target,actor,cause,day)
			_others_watch(actor,target,-0.02)
		"bear":
			pass

## Coercion seen by every other people that knows the one who used it.
static func _others_watch(actor:String,target:String,delta:float)->void:
	if actor!="player": return
	for c:Dictionary in CivilizationSystem.civilizations:
		var id:=String(c.get("id",""))
		if id==target or not bool(c.get("alive",true)) or int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		Hall._shift_relation(id,delta,0.0)

## War (or a feud between small peoples) over the trade, through the war's own engine.
static func _war(attacker:String,defender:String,cause:String,day:int)->void:
	var war:=load(WAR_PATH) as GDScript
	if defender=="player":
		if war!=null: war.call("declare",attacker,day,cause)
		Ledger._stat("trade_wars")
		return
	if attacker=="player": return
	var civs:Array=CivilizationSystem.civilizations
	var i:=-1; var j:=-1
	for index in civs.size():
		var id:=String((civs[index] as Dictionary).get("id",""))
		if id==attacker: i=index
		elif id==defender: j=index
	if i<0 or j<0: return
	var declared:=false
	if preload("res://scripts/conflict_scale.gd").formal_war(attacker,defender) and WorldSimulation.actors.has(attacker):
		var sent:Dictionary=WorldSimulation.submit(attacker,{"kind":"diplomacy","target":defender,"action":"declare_war"})
		declared=bool(sent.get("ok",false))
	if not declared: CivilizationSystem.start_rival_feud(mini(i,j),maxi(i,j),day,cause)
	Ledger._stat("trade_wars")

## A people's rulers lose standing (and its people their cohesion) for a
## while: a bounded policy shock in its own scope, as crisis_unattended uses.
static func _hardship(owner:String,why:String,cohesion:float,legitimacy:float,days:int)->void:
	if not Ledger.simulated(owner) or absf(cohesion)+absf(legitimacy)<=0.0: return
	WorldSimulation.scoped(owner,func()->void:
		var magnitude:=0.2
		var effects:={}
		if cohesion!=0.0: effects["cohesion_target"]=cohesion/magnitude
		if legitimacy!=0.0: effects["legitimacy_target"]=legitimacy/magnitude
		if effects.is_empty(): return
		var day:=float(WorldSimulation.state.elapsed_days)
		WorldSimulation.state.active_modifiers.append({"id":"trade_%s" % why.replace(" ","_").substr(0,40),"kind":"policy","effects":effects,"magnitude":magnitude,
			"started_day":day,"until_day":day+float(days),"description":"Trade: %s" % why}))

# --------------------------------------------------------------------------
# Tribute agreements
# --------------------------------------------------------------------------

static func _begin_tribute(payer:String,payee:String,value:float,day:int)->void:
	(Ledger.state().tributes as Dictionary)[skey(payer,payee)]={"value":snappedf(maxf(1.0,value),0.01),"since":day,"until":day+TRIBUTE_YEARS*365,"next":day+1,"paid":0.0,"missed":0}

## The god's tribute agreements and others': {payer>payee: record}.
static func tribute(payer:String,payee:String)->Dictionary:
	var s:=Ledger.peek()
	if s.is_empty(): return {}
	var t:Variant=(s.get("tributes",{}) as Dictionary).get(skey(payer,payee))
	return t if t is Dictionary else {}

static func _collect(k:String,t:Dictionary,day:int)->void:
	var payer:=k.get_slice(">",0); var payee:=k.get_slice(">",1)
	var tributes:Dictionary=Ledger.state().tributes
	if day>=int(t.get("until",0)) or not Ledger.alive(payer) or not Ledger.alive(payee):
		tributes.erase(k)
		if payer=="player" or payee=="player": Ledger.news("tribute_end",payer,payee,"",{"paid":float(t.get("paid",0.0))})
		return
	t["next"]=day+91
	if Ledger.blocked(payer,payee,day) in ["war","feud"]:
		t["missed"]=int(t.get("missed",0))+1
	else:
		var p:=Ledger.pair(payer,payee)
		var got:=Ledger._levy(payer,payee,float(t.value),String(p.get("form","gift")) if not p.is_empty() else "gift","tribute")
		t["paid"]=float(t.get("paid",0.0))+got
		t["last"]=snappedf(got,0.01)
		if got<float(t.value)*0.5: t["missed"]=int(t.get("missed",0))+1
		else: t["missed"]=0
		Ledger._stat("tribute_value",got)
	if int(t.get("missed",0))>=2:
		tributes.erase(k)
		if payer=="player" or payee=="player": Ledger.news("tribute_stopped",payer,payee,"",{"paid":float(t.get("paid",0.0))})
		# A people's own leaders answer tribute withheld by cutting them off.
		if payee!="player": set_stance(payee,payer,"embargo","",0.0,"ai")

# --------------------------------------------------------------------------
# Raids on traders
# --------------------------------------------------------------------------

## Their raiders fall on the victim's traders on its busiest road: a share of
## a season's goods seized, and a few carriers killed.
static func _raid(k:String,r:Dictionary,day:int)->void:
	var raider:=k.get_slice(">",0); var victim:=k.get_slice(">",1)
	var rng:=_rng("raid:%s:%d" % [k,day])
	r["next"]=day+rng.randi_range(30,90)
	if not Ledger.alive(raider) or not Ledger.alive(victim): return
	var road:={}
	for row:Dictionary in Ledger.partners(victim):
		if float(row.value)>float(road.get("value",0.0)): road=row
	var season:=float(road.get("value",0.0))*3.0
	if season<=0.0: season=Ledger.flow_value(victim,raider)*3.0
	var seized:=Ledger.pay_in_kind(victim,raider,season*rng.randf_range(0.2,0.4),"","seized")
	var dead:=0
	if rng.randf()<0.5:
		var want:=mini(3,maxi(1,roundi(Ledger.population(victim)*0.0015)))
		dead=int(WorldSimulation.scoped(victim,func()->int:return int((WorldSimulation.state.register_population_deaths(want,"Killed on the trading road") as Dictionary).get("count",0)))) if Ledger.simulated(victim) else 0
	r["count"]=int(r.get("count",0))+1
	Ledger._warm(victim,raider,-0.05)
	Ledger._stat("raids")
	if raider=="player" or victim=="player": Ledger.news("raided",raider,victim,"",{"seized":snappedf(seized,0.1),"dead":dead,"road":String(road.get("id",""))})

# --------------------------------------------------------------------------
# Every people's own review: by its nature, rarely, with real business
# --------------------------------------------------------------------------

static func review(owner:String,day:int)->void:
	if not Ledger.alive(owner): return
	var temper:=Personality.of_owner(owner)
	var a:=float(temper.get("assertiveness",0.5)); var e:=float(temper.get("empathy",0.5)); var d:=float(temper.get("discipline",0.5))
	var trait_id:=trait_of(owner)
	var s:=Ledger.state()
	for row:Dictionary in Ledger.partners(owner):
		var other:=String(row.id)
		if not Ledger.alive(other) or Ledger.blocked(owner,other,day) in ["war","feud"]: continue
		var cur:=stance(owner,other)
		var op:=Ledger.opinion(owner,other)
		var rng:=_rng("review:%s:%s:%d" % [owner,other,day])
		if String(cur.get("id","free"))!="free":
			# Stances wear out: after a year, eased as tempers cool.
			if day-int(cur.get("since",day))>365 and (op>-0.1 or String(cur.get("last",""))=="yield") and rng.randf()<1.0/18.0:
				set_stance(owner,other,"free","",0.0,"ai")
			continue
		var to_us:=other=="player"
		if to_us and day-int((s.stats as Dictionary).get("last_on_player:"+owner,-99999))<PLAYER_GAP: continue
		var their_dep:=Ledger.dependence(other,owner)
		var our_dep:=Ledger.dependence(owner,other)
		var ratio:=strength(owner)/maxf(1.0,strength(other))
		var choices:={}
		if op<-0.25 and our_dep<0.15: choices["embargo"]=0.010*(1.0+a)*(1.5 if trait_id=="grudge" else 1.0)
		var most:=Ledger.most_needed(other,owner)
		if not most.is_empty() and float(most.share)>=0.3 and op<0.1 and (a>0.6 or trait_id in ["hunter","magpie"]): choices["squeeze"]=0.008
		if ratio>2.5 and (their_dep>0.2 or ratio>4.0) and a>0.55: choices["tribute"]=0.006
		if (trait_id=="ledger" or d>0.65) and Ledger.flow_value(owner,other)+Ledger.flow_value(other,owner)>Ledger.population(owner)*0.05: choices["toll"]=0.006
		if (e>0.6 or trait_id=="matchmaker") and op>0.1 and op<0.5: choices["gifts"]=0.008
		if op>0.35 and float(row.value)>0.0: choices["favour"]=0.004
		if choices.is_empty(): continue
		var total:=0.0
		for id in choices:
			if to_us: choices[id]=float(choices[id])*0.5
			total+=float(choices[id])
		if rng.randf()>=total: continue
		var pick:=rng.randf()*total
		var chosen:=""
		for id in choices:
			pick-=float(choices[id])
			if pick<=0.0: chosen=String(id); break
		if chosen=="": continue
		if to_us and chosen=="tribute":
			# A demand on the god's people comes by envoy, with real business
			# (audience_hall.gd: an envoy demanding tribute).
			Hall._add_occasion({"key":"trade_tribute:%s:%d" % [owner,day],"type":"ambient","civ_id":owner,"day":day,"expires":day+180,"data":{"text":"their hold on our trade","business":{"tribute_demand":1.0}}})
		else:
			set_stance(owner,other,chosen,String(most.get("good","")) if chosen=="squeeze" else "",0.0,"ai")
		if to_us and chosen in COERCIVE: (s.stats as Dictionary)["last_on_player:"+owner]=day
		Ledger._stat("ai_"+chosen)
