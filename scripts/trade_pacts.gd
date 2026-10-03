extends RefCounted
## Standing exchanges: goods traded between your people and another in
## portions on a schedule ("ten Timber for a hundred Food each year, for ten
## years"). This is what a trade conversation can conclude into.
##
## Terms, always from your side of the table:
##   {give_res, give_amt, get_res, get_amt, cadence ("season"|"year"),
##    portions (deliveries in all), when_ready (each payment waits for the
##    matching delivery), carry_debt (shortfalls are owed later)}
##
## The foreign ruler's side decides with appraise(): what their people have
## to spare, what they lack, their ruler's temper, trust and grudges. Their
## answer is accept, counter (with numbers), refuse (with a reason) or, once,
## consult their council. A sealed exchange is carried out by traders every
## portion through the real ledgers (civilization_exchange.gd), with honest
## outcomes: delivered, partly delivered, skipped for lack of stock, suspended
## by war, lapsed for repeated failure, cancelled or completed. Each is a
## Chronicle line (never an extra envoy) and moves relations and trust.
##
## Volumes are bounded by era (PORTION_CAP) and by what the giver really
## holds: a village-to-village exchange in the stone age moves a few porters'
## loads a season, not a granary. Settlement runs every TICK days like the
## loans in envoy_requests.gd.
##
## State: AudienceHall.state().trade_pacts = {serial:int, pacts:[...]}.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const CHRONICLE_PATH:="res://scripts/chronicle.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"

const RESOURCES:=["Food","Timber","Stone","Clay","Fiber Plants"]
## What goods are worth: the one price table (trade_prices.gd: the economy's
## own prices), read for whichever people weighs them.
const PRICES:=preload("res://scripts/trade_prices.gd")
const LEDGER_PATH:="res://scripts/trade_ledger.gd"

static func worth(res:String,owner:String="player")->float:
	return PRICES.value(res,owner)
const CADENCES:={"season":91,"year":365}
const STANCES:=["propose","accept","counter","refuse","consult"]
const MAX_YEARS:=10
const TICK:=10
## Most a single portion may carry, by era tier (stone age first). A portion
## of 240 Food is 240 person-days of rations: a few porters' loads.
const PORTION_CAP:={"Food":[240,400,700,1200],"Timber":[40,70,120,200],"Stone":[25,45,80,140],"Clay":[40,70,120,200],"Fiber Plants":[40,70,120,200]}
## A ruler will not promise more than this share of what they hold per portion.
const SHARE_OF_STOCK:=0.35
## What each side may draw on when a portion falls due (the rest is reserve).
const PLAYER_DRAW:=0.8
const THEIR_DRAW:=0.6
const PER_CIV_MAX:=3
const ACTIVE_MAX:=8
const ENDED_MAX:=8
const LOG_MAX:=10
const MISSES_TO_LAPSE:=3
const GOODWILL_CAP:=0.12

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func store()->Dictionary:
	var s:=Hall.state()
	if not s.get("trade_pacts") is Dictionary: s["trade_pacts"]={}
	var t:Dictionary=s.trade_pacts
	if not t.get("pacts") is Array: t["pacts"]=[]
	if not Hall._num(t.get("serial")): t["serial"]=0
	return t

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.has("serial") and not Hall._num(d.serial): return false
	if not d.get("pacts",[]) is Array or (d.get("pacts",[]) as Array).size()>ACTIVE_MAX+ENDED_MAX: return false
	for p in d.get("pacts",[]):
		if not p is Dictionary or JSON.stringify(p).length()>6000: return false
		if not p.get("id") is String or not p.get("civ") is String: return false
		if not valid_terms(p.get("terms",{})): return false
		if not String(p.get("status","")) in ["active","completed","cancelled","lapsed"]: return false
		for key in ["sealed","due","done","owe_p","owe_t","back","miss_p","miss_t","gw"]:
			if p.has(key) and not Hall._num(p[key]): return false
		if not p.get("log",[]) is Array or (p.get("log",[]) as Array).size()>LOG_MAX: return false
		for entry in p.get("log",[]):
			if not entry is Dictionary or not Hall._num(entry.get("d")) or not entry.get("o","") is String or not entry.get("n","") is String: return false
	return true

static func pacts(civ_id:String="",active_only:bool=true)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for p in store().pacts:
		if not p is Dictionary: continue
		if civ_id!="" and String(p.civ)!=civ_id: continue
		if active_only and String(p.status)!="active": continue
		out.append(p)
	return out

static func find(pact_id:String)->Dictionary:
	for p in store().pacts:
		if p is Dictionary and String(p.id)==pact_id: return p
	return {}

static func _day()->int:
	return int(GameState.elapsed_days)

# --------------------------------------------------------------------------
# Terms
# --------------------------------------------------------------------------

static func valid_terms(value:Variant)->bool:
	if not value is Dictionary: return false
	var t:Dictionary=value
	if not t.has_all(["give_res","give_amt","get_res","get_amt","cadence","portions","when_ready","carry_debt"]): return false
	if not String(t.give_res) in RESOURCES or not String(t.get_res) in RESOURCES or String(t.give_res)==String(t.get_res): return false
	for key in ["give_amt","get_amt","portions"]:
		if not Hall._num(t[key]) or float(t[key])<1.0 or float(t[key])>100000.0: return false
	if not String(t.cadence) in CADENCES or not t.when_ready is bool or not t.carry_debt is bool: return false
	return int(t.portions)<=max_portions(String(t.cadence))

static func max_portions(cadence:String)->int:
	return MAX_YEARS*(4 if cadence=="season" else 1)

static func from_model(raw:Variant)->Dictionary:
	## The live model's shape (foreign/player named explicitly) to terms.
	## Returns {} when malformed; amounts are whole numbers.
	if not raw is Dictionary or (raw as Dictionary).is_empty(): return {}
	var r:Dictionary=raw
	if not r.has_all(["player_gives","player_amount","foreign_gives","foreign_amount","cadence","portions","when_ready","carry_debt"]): return {}
	for key in ["player_amount","foreign_amount","portions"]:
		if not Hall._num(r[key]): return {}
	var terms:={"give_res":String(r.player_gives),"give_amt":roundi(float(r.player_amount)),"get_res":String(r.foreign_gives),"get_amt":roundi(float(r.foreign_amount)),
		"cadence":String(r.cadence),"portions":roundi(float(r.portions)),"when_ready":r.when_ready,"carry_debt":r.carry_debt}
	if not terms.when_ready is bool or not terms.carry_debt is bool: return {}
	if String(terms.cadence) in CADENCES: terms.portions=clampi(int(terms.portions),1,max_portions(String(terms.cadence)))
	return terms if valid_terms(terms) else {}

static func to_model(terms:Dictionary,stance:String="")->Dictionary:
	var out:={"player_gives":String(terms.give_res),"player_amount":int(terms.give_amt),"foreign_gives":String(terms.get_res),"foreign_amount":int(terms.get_amt),
		"cadence":String(terms.cadence),"portions":int(terms.portions),"when_ready":bool(terms.when_ready),"carry_debt":bool(terms.carry_debt)}
	if stance!="": out["stance"]=stance
	return out

static func same_terms(a:Dictionary,b:Dictionary)->bool:
	if not valid_terms(a) or not valid_terms(b): return false
	for key in ["give_res","get_res","cadence","when_ready","carry_debt"]:
		if str(a[key])!=str(b[key]): return false
	for key in ["give_amt","get_amt","portions"]:
		if int(a[key])!=int(b[key]): return false
	return true

static func signature(terms:Dictionary)->String:
	if not valid_terms(terms): return ""
	return "%s:%d>%s:%d/%s*%d%s%s" % [terms.give_res,int(terms.give_amt),terms.get_res,int(terms.get_amt),terms.cadence,int(terms.portions),"w" if terms.when_ready else "","d" if terms.carry_debt else ""]

static func cap(resource:String)->int:
	var row:Array=PORTION_CAP.get(resource,[40])
	return int(row[clampi(Hall.era_tier(),0,row.size()-1)])

static func period(terms:Dictionary)->int:
	return int(CADENCES.get(String(terms.get("cadence","year")),365))

static func window(terms:Dictionary)->int:
	## How long a portion may wait for its goods when payment waits on delivery.
	return mini(60,period(terms)/2) if bool(terms.get("when_ready",false)) else 0

# --------------------------------------------------------------------------
# Stores on each side
# --------------------------------------------------------------------------

static func player_stock(resource:String)->float:
	return Hall.player_stock(resource)

static func their_stock(civ_id:String,resource:String)->float:
	## Their real ledger when they have one; otherwise a village's working store
	## estimated from their people and food reserve (goods are never conjured:
	## deliveries without a ledger draw that food reserve down).
	var ledger:=Hall.foreign_stock(civ_id,resource)
	if ledger>=0.0: return ledger
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty(): return 0.0
	var pop:=maxf(20.0,float(civ.get("population",100)))
	if resource=="Food": return maxf(0.0,float(civ.get("food_days",30.0)))*pop
	return pop*1.5

static func _their_take(civ_id:String,resource:String,amount:float)->float:
	if amount<=0.0: return 0.0
	if Hall.foreign_stock(civ_id,resource)>=0.0: return EXCHANGE.take(civ_id,resource,amount)
	if resource=="Food":
		var index:=Hall._civ_index(civ_id)
		if index<0: return 0.0
		var civ:Dictionary=WorldSimulation.world.civilizations[index]
		var pop:=maxf(1.0,float(civ.get("population",1.0)))
		var have:=maxf(0.0,float(civ.get("food_days",0.0)))*pop
		var sent:=minf(amount,have)
		civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-sent/pop)
		return sent
	return minf(amount,their_stock(civ_id,resource))

static func _need_mult(civ_id:String,resource:String)->float:
	## How much they want a good: short of it, it is worth more to them.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=maxf(20.0,float(civ.get("population",100)))
	if resource=="Food":
		var days:=their_stock(civ_id,"Food")/pop
		return 1.4 if days<30.0 else (0.8 if days>120.0 else 1.0)
	var per:=their_stock(civ_id,resource)/pop
	return 1.35 if per<0.4 else (0.8 if per>3.0 else 1.0)

static func _surplus_mult(civ_id:String,resource:String)->float:
	## How dear a good is to give up: plenty of it makes it cheap to them.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=maxf(20.0,float(civ.get("population",100)))
	if resource=="Food":
		var days:=their_stock(civ_id,"Food")/pop
		return 1.35 if days<30.0 else (0.8 if days>120.0 else 1.0)
	var per:=their_stock(civ_id,resource)/pop
	return 1.3 if per<0.4 else (0.8 if per>3.0 else 1.0)

static func their_limit(civ_id:String,resource:String)->int:
	## The most they would promise per portion of one good.
	return maxi(0,mini(cap(resource),floori(their_stock(civ_id,resource)*SHARE_OF_STOCK)))

# --------------------------------------------------------------------------
# Validation against the talk and the stores
# --------------------------------------------------------------------------

const _SMALL:={"zero":0,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19,
	"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"seventy":70,"eighty":80,"ninety":90,"score":20}

static func numbers_in(text:String)->Array[int]:
	## Every whole number said in the text, in digits or in words ("one hundred
	## and twenty", "a dozen", "1,000").
	var out:Array[int]=[]
	var clean:=text.to_lower()
	var commas:=RegEx.new(); commas.compile("(\\d),(\\d{3})")
	while commas.search(clean)!=null: clean=commas.sub(clean,"$1$2",true)
	var splitter:=RegEx.new(); splitter.compile("[a-z]+|\\d+")
	var tokens:Array[String]=[]
	for m:RegExMatch in splitter.search_all(clean): tokens.append(m.get_string())
	var current:=0; var total:=0; var have:=false
	for i in tokens.size():
		var tok:=tokens[i]
		var next:=tokens[i+1] if i+1<tokens.size() else ""
		if tok.is_valid_int():
			if have: out.append(total+current); current=0; total=0; have=false
			out.append(int(tok)); continue
		if _SMALL.has(tok): current+=int(_SMALL[tok]); have=true; continue
		if tok=="hundred": current=maxi(current,1)*100; have=true; continue
		if tok=="thousand": total+=maxi(current,1)*1000; current=0; have=true; continue
		if tok=="dozen": current=maxi(current,1)*12; have=true; continue
		if tok=="a" and next in ["hundred","thousand","dozen","score"]: continue
		if tok=="and" and have and (_SMALL.has(next)): continue
		if have: out.append(total+current); current=0; total=0; have=false
	if have: out.append(total+current)
	return out

static func grounded(terms:Dictionary,talk:String)->bool:
	## Both amounts must have been said by someone; invented numbers are not terms.
	var said:=numbers_in(talk)
	return int(terms.give_amt) in said and int(terms.get_amt) in said

static func fit(civ_id:String,terms:Dictionary)->Dictionary:
	## Terms clamped to the era's porters and what they really hold.
	## Returns {terms, notes:Array[String]}; notes say what had to change.
	var t:=terms.duplicate()
	var notes:Array[String]=[]
	t.portions=clampi(int(t.portions),1,max_portions(String(t.cadence)))
	var give_cap:=cap(String(t.give_res))
	if int(t.give_amt)>give_cap:
		t.give_amt=give_cap; notes.append("No more than %d %s can be carried a portion." % [give_cap,t.give_res])
	var limit:=their_limit(civ_id,String(t.get_res))
	if int(t.get_amt)>limit:
		t.get_amt=maxi(0,limit)
		notes.append("They can spare no more than %d %s a portion." % [limit,t.get_res] if limit>0 else "They have no %s to spare." % t.get_res)
	return {"terms":t,"notes":notes}

# --------------------------------------------------------------------------
# The ruler's side decides
# --------------------------------------------------------------------------

static func _threshold(civ_id:String)->float:
	var p:=Hall._personality(civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var opinion:=float((civ.get("player_relation",{}) as Dictionary).get("opinion",0.0))
	var trust:=float(ForeignDiplomacy.leader(civ_id).get("trust",0.0))
	var grudge:=0.0
	var r:=load(RIVALS_PATH) as GDScript
	if r!=null: grudge=float(r.call("grudge_weight",civ_id))
	# How they see us (standing.gd): drawn to us or respecting us, they take
	# thinner terms; holding us in contempt, they drive a harder bargain.
	var standing:=0.0
	var view:Dictionary=preload("res://scripts/standing.gd").view_of(civ_id)
	if bool(view.get("known",false)): standing=-float(view.allure)*0.15-float(view.respect)*0.1+float(view.contempt)*0.15
	return clampf(0.95+(float(p.get("assertiveness",0.5))-0.5)*0.4-opinion*0.25-trust*0.15+minf(0.3,grudge*0.15)+standing,0.6,1.45)

static func ratio(civ_id:String,terms:Dictionary)->float:
	## What they receive over what they give, as they value it.
	var value_in:=float(terms.give_amt)*worth(String(terms.give_res),civ_id)*_need_mult(civ_id,String(terms.give_res))
	var value_out:=float(terms.get_amt)*worth(String(terms.get_res),civ_id)*_surplus_mult(civ_id,String(terms.get_res))
	return value_in/maxf(0.01,value_out)

static func appraise(civ_id:String,terms:Dictionary,final:bool=false,allow_consult:bool=false)->Dictionary:
	## {decision: accept|counter|refuse|consult, terms, reason}. Deterministic.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or not valid_terms(terms): return {"decision":"refuse","terms":terms,"reason":"there is nothing to weigh"}
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)):
		return {"decision":"refuse","terms":terms,"reason":"we are at war with your people"}
	var t:Dictionary=terms.duplicate()
	var limit:=their_limit(civ_id,String(t.get_res))
	if limit<1: return {"decision":"refuse","terms":t,"reason":"we have no %s to spare" % String(t.get_res)}
	var reason:=""
	if int(t.get_amt)>limit:
		t.get_amt=limit
		reason="we cannot spare more than %d %s a portion" % [limit,t.get_res]
	var threshold:=_threshold(civ_id)
	var r:=ratio(civ_id,t)
	if reason=="" and r>=threshold: return {"decision":"accept","terms":t,"reason":"the trade is fair to us"}
	if final:
		if reason=="" and r>=threshold*0.85: return {"decision":"accept","terms":t,"reason":"it is close enough to fair"}
		if reason!="" and r>=threshold: return {"decision":"counter","terms":t,"reason":reason,"final":true}
		return {"decision":"refuse","terms":terms,"reason":reason if reason!="" else "you ask too much %s for too little %s" % [String(t.get_res),String(t.give_res)]}
	if r<threshold*0.3:
		return {"decision":"refuse","terms":terms,"reason":"you ask too much %s for too little %s" % [String(t.get_res),String(t.give_res)]}
	if r<threshold:
		# Ask more of you if you can carry it; otherwise offer less of theirs.
		var unit_in:=worth(String(t.give_res),civ_id)*_need_mult(civ_id,String(t.give_res))
		var value_out:=float(t.get_amt)*worth(String(t.get_res),civ_id)*_surplus_mult(civ_id,String(t.get_res))
		var wanted:=_round_up(value_out*threshold/maxf(0.01,unit_in))
		if wanted<=cap(String(t.give_res)) and float(wanted)<=player_stock(String(t.give_res))*0.5:
			t.give_amt=wanted
		else:
			var unit_out:=worth(String(t.get_res),civ_id)*_surplus_mult(civ_id,String(t.get_res))
			var fair_out:=floori(float(t.give_amt)*unit_in/threshold/maxf(0.01,unit_out))
			if fair_out<1: return {"decision":"refuse","terms":terms,"reason":"what you offer is worth too little to us"}
			t.get_amt=fair_out
		if reason=="": reason="what you offer is not enough for what you ask"
	if allow_consult and r>=threshold*0.8 and float(Hall._personality(civ_id).get("discipline",0.5))>0.6:
		return {"decision":"consult","terms":terms,"reason":"the council must weigh it"}
	return {"decision":"counter","terms":t,"reason":reason}

static func _round_up(value:float)->int:
	var v:=ceili(value)
	if v>=60: return ceili(v/10.0)*10
	if v>=20: return ceili(v/5.0)*5
	return maxi(1,v)

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func _each(terms:Dictionary)->String:
	return "each season" if String(terms.cadence)=="season" else "each year"

static func span_words(terms:Dictionary)->String:
	var n:=int(terms.portions)
	if String(terms.cadence)=="season":
		return "%d season%s" % [n,"" if n==1 else "s"] if n%4!=0 else "%d year%s" % [n/4,"" if n==4 else "s"]
	return "%d year%s" % [n,"" if n==1 else "s"]

static func describe(terms:Dictionary)->String:
	## One plain sentence of the whole agreement, from your side.
	if not valid_terms(terms): return ""
	var text:="You give %d %s and they give %d %s %s, for %s (%d portion%s)." % [int(terms.give_amt),terms.give_res,int(terms.get_amt),terms.get_res,_each(terms),span_words(terms),int(terms.portions),"" if int(terms.portions)==1 else "s"]
	text+=" Each payment waits until its matching delivery is ready." if bool(terms.when_ready) else " Both loads are due on the same day."
	text+=" What cannot be sent is owed later." if bool(terms.carry_debt) else " Nothing unsent is carried forward as debt."
	return text

static func short_words(terms:Dictionary)->String:
	return "%d %s for %d %s %s" % [int(terms.give_amt),terms.give_res,int(terms.get_amt),terms.get_res,"a season" if String(terms.cadence)=="season" else "a year"]

static func ruler_words(civ_id:String,decision:Dictionary)->String:
	## The ruler's plain answer when no live voice speaks for them (offline, or
	## when a forced decision overrules a reply that would not decide).
	var t:Dictionary=decision.get("terms",{})
	if not valid_terms(t): return "There is nothing here I can agree to."
	var theirs:="%d %s" % [int(t.get_amt),t.get_res]
	var yours:="%d %s" % [int(t.give_amt),t.give_res]
	var span:=span_words(t)
	match String(decision.get("decision","")):
		"accept":
			return "%s from us and %s from you, %s, for %s. %s I agree to that. When your ruler seals it, our carriers will come." % [theirs,yours,_each(t),span,"Each load paid when the other arrives, and nothing owed carried over." if bool(t.when_ready) and not bool(t.carry_debt) else ("What cannot be sent is owed." if bool(t.carry_debt) else "Both loads on the same day.")]
		"counter":
			var why:=String(decision.get("reason",""))
			return "Not on those terms: %s. %s for %s, %s, for %s. That I will do%s." % [why,_first_up(yours),theirs,_each(t),span," and I will not bargain further" if bool(decision.get("final",false)) else ""]
		"consult":
			return "%s for %s %s is no small promise. My council will weigh it, and your next envoy will carry home their answer." % [_first_up(yours),theirs,_each(t)]
	return "No. %s." % _first_up(String(decision.get("reason","it does not suit us")))

static func _first_up(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func stance_word(stance:String)->String:
	match stance:
		"accept": return "agrees"
		"counter": return "counters"
		"propose": return "offers"
		"refuse": return "refuses"
		"consult": return "is weighing it with their council"
	return ""

# --------------------------------------------------------------------------
# Offline: predetermined proposals from real surplus and need
# --------------------------------------------------------------------------

static func offline_choices(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return out
	if pacts(civ_id).size()>=PER_CIV_MAX: return out
	# What you hold most of (by worth) and what they hold most of.
	var ours:=""; var ours_worth:=0.0
	for res:String in RESOURCES:
		var held_worth:=player_stock(res)*worth(res)
		# Food is offered only from full stores (food_care.gd RESERVE_DAYS).
		if res=="Food" and float(GameState.simulation_metrics.get("food_days",60.0))<preload("res://scripts/food_care.gd").RESERVE_DAYS: continue
		if held_worth>ours_worth: ours_worth=held_worth; ours=res
	var theirs:=""; var best:=0.0
	for res:String in RESOURCES:
		if res==ours: continue
		var wanted:=float(their_limit(civ_id,res))*worth(res,civ_id)/maxf(0.2,player_stock(res)/maxf(1.0,float(GameState.population_exact)))
		if their_limit(civ_id,res)>=3 and wanted>best: best=wanted; theirs=res
	if ours=="" or theirs=="": return out
	var get_amt:=clampi(their_limit(civ_id,theirs)/2,1,cap(theirs))
	for preset in [["fair","season",8,1.0],["lean","year",5,0.75]]:
		var unit_in:=worth(ours,civ_id)*_need_mult(civ_id,ours)
		var unit_out:=worth(theirs,civ_id)*_surplus_mult(civ_id,theirs)
		var amount:=get_amt if String(preset[1])=="season" else mini(cap(theirs),get_amt*2)
		var give:=_round_up(float(amount)*unit_out*_threshold(civ_id)*float(preset[3])/maxf(0.01,unit_in))
		give=mini(give,cap(ours))
		if give<1 or float(give)>player_stock(ours)*0.5: continue
		var terms:={"give_res":ours,"give_amt":give,"get_res":theirs,"get_amt":amount,"cadence":String(preset[1]),"portions":int(preset[2]),"when_ready":true,"carry_debt":false}
		if not valid_terms(terms): continue
		out.append({"id":"trade:"+String(preset[0]),"label":"Offer %s, for %s" % [short_words(terms),span_words(terms)],"terms":terms,"reaction":"conciliate"})
	return out

# --------------------------------------------------------------------------
# Sealing and cancelling
# --------------------------------------------------------------------------

static func seal_blocker(civ_id:String,terms:Dictionary)->String:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or not bool(civ.get("alive",true)): return "You have no way to reach that people."
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return "No exchange holds while you are at war with them."
	if not valid_terms(terms): return "These terms are incomplete."
	if pacts(civ_id).size()>=PER_CIV_MAX: return "You already keep %d exchanges with them." % PER_CIV_MAX
	if pacts().size()>=ACTIVE_MAX: return "Your traders already carry %d exchanges." % ACTIVE_MAX
	var fitted:=fit(civ_id,terms)
	if not same_terms(fitted.terms,terms): return String((fitted.notes as Array)[0]) if not (fitted.notes as Array).is_empty() else "These terms cannot be carried."
	return ""

static func seal(civ_id:String,terms:Dictionary,travel_days:int=20)->Dictionary:
	var blocker:=seal_blocker(civ_id,terms)
	if blocker!="": return {"error":blocker}
	var s:=store()
	s.serial=int(s.serial)+1
	var day:=_day()
	var pact:={"id":"tp_%d" % int(s.serial),"civ":civ_id,"terms":terms.duplicate(),"sealed":day,"due":day+clampi(travel_days,5,120),"done":0,"status":"active",
		"owe_p":0.0,"owe_t":0.0,"back":0.0,"miss_p":0,"miss_t":0,"gw":0.0,"log":[]}
	(s.pacts as Array).append(pact)
	_trim()
	var name:=Hall._civ_name(civ_id)
	_log(pact,"sealed","Sealed: "+short_words(terms)+" for "+span_words(terms)+".")
	_record("An Exchange With %s" % name.substr(0,40),"You sealed a standing exchange with %s. %s The first portion is due about %s." % [name,describe(terms),_when(int(pact.due))],civ_id,"seal:"+String(pact.id),"notice")
	ForeignDiplomacy.remember(civ_id,"We agreed a standing exchange with the ruler: %s." % short_words(terms))
	Hall._shift_relation(civ_id,0.02,-0.01)
	return {"ok":true,"pact":pact}

static func cancel(pact_id:String,by:String="player")->Dictionary:
	var p:=find(pact_id)
	if p.is_empty() or String(p.status)!="active": return {"error":"There is no such exchange in force."}
	var civ_id:=String(p.civ)
	var name:=Hall._civ_name(civ_id)
	p.status="cancelled"; p["ended"]=_day()
	if by=="player":
		# Ending it after their own failures costs you nothing; otherwise it is a broken word.
		if int(p.get("miss_t",0))>0:
			_log(p,"cancelled","You ended it after their failed portions.")
			_record("You End the Exchange With %s" % name.substr(0,32),"You ended the standing exchange with %s (%s) after they failed to deliver. They do not dispute it." % [name,short_words(p.terms)],civ_id,"end:"+pact_id,"notice")
		else:
			Hall._shift_relation(civ_id,-0.04,0.02)
			Hall._leader_trust(civ_id,-0.06)
			_grudge(civ_id,"how you broke off the exchange of %s" % short_words(p.terms),0.25,"pact_end:"+pact_id)
			_log(p,"cancelled","You ended it; they had kept their side.")
			_record("You End the Exchange With %s" % name.substr(0,32),"You ended the standing exchange with %s (%s) with %d of %d portions still to come. They had kept their side, and they will remember it." % [name,short_words(p.terms),int(p.terms.portions)-int(p.done),int(p.terms.portions)],civ_id,"end:"+pact_id,"notice")
			ForeignDiplomacy.remember(civ_id,"The ruler broke off our exchange while we were keeping it.")
	return {"ok":true,"pact":p}

static func _trim()->void:
	var list:Array=store().pacts
	var ended:Array=list.filter(func(p:Variant)->bool:return p is Dictionary and String(p.status)!="active")
	while ended.size()>ENDED_MAX:
		list.erase(ended.pop_front())

# --------------------------------------------------------------------------
# Settlement: traders carry each portion
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if day%TICK!=0 or WorldSimulation.actor_id!="player": return
	for p in store().pacts.duplicate():
		if p is Dictionary and String(p.status)=="active" and day>=int(p.due): settle(p,day)
	_trim()

static func settle(p:Dictionary,day:int)->void:
	var civ_id:=String(p.civ)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var name:=Hall._civ_name(civ_id)
	var t:Dictionary=p.terms
	if civ.is_empty() or not bool(civ.get("alive",true)):
		p.status="lapsed"; p["ended"]=day
		_log(p,"lapsed","Their people are gone.")
		_record("An Exchange Ends","The standing exchange with %s is over: there is no one left to trade with." % name,civ_id,"gone:"+String(p.id),"notice")
		return
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)):
		if not bool(p.get("suspended",false)):
			p["suspended"]=true
			_log(p,"suspended","Suspended by war.")
			_record("War Stops the Traders","No traders cross to or from %s while you are at war. The exchange of %s waits." % [name,short_words(t)],civ_id,"war:%s:%d" % [p.id,day],"notice")
		p.due=day+30
		if day>int(p.sealed)+(int(t.portions)+1)*period(t)+365:
			p.status="cancelled"; p["ended"]=day
			_log(p,"cancelled","Ended by a long war.")
			_record("The Exchange With %s Ends" % name.substr(0,32),"The war with %s outlasted the exchange of %s. It is over." % [name,short_words(t)],civ_id,"warend:"+String(p.id),"notice")
		return
	p.erase("suspended")
	var give_res:=String(t.give_res); var get_res:=String(t.get_res)
	var linked:=bool(t.when_ready)
	var debt:=bool(t.carry_debt)
	var backlog:=clampf(float(p.get("back",0.0)),0.0,2.0) if linked and debt else 0.0
	var need_p:=float(t.give_amt)*(1.0+backlog)+(float(p.get("owe_p",0.0)) if debt and not linked else 0.0)
	var need_t:=float(t.get_amt)*(1.0+backlog)+(float(p.get("owe_t",0.0)) if debt and not linked else 0.0)
	var fp:=clampf(player_stock(give_res)*PLAYER_DRAW/maxf(0.01,need_p),0.0,1.0)
	var ft:=clampf(their_stock(civ_id,get_res)*THEIR_DRAW/maxf(0.01,need_t),0.0,1.0)
	if linked and minf(fp,ft)<0.999 and day<int(p.due)+window(t):
		p["waiting"]=true
		return
	p.erase("waiting")
	var send_p:=0.0; var send_t:=0.0
	if linked:
		var f:=minf(fp,ft)
		send_p=need_p*f; send_t=need_t*f
		if debt: p.back=clampf((1.0+backlog)*(1.0-f),0.0,2.0)
	else:
		send_p=need_p*fp; send_t=need_t*ft
		if debt:
			p.owe_p=minf(float(t.give_amt)*2.0,need_p-send_p)
			p.owe_t=minf(float(t.get_amt)*2.0,need_t-send_t)
	var gave:=EXCHANGE.take("player",give_res,send_p) if send_p>0.0 else 0.0
	if gave>0.0: Hall._credit_civ(civ_id,give_res,gave)
	var got:=_their_take(civ_id,get_res,send_t) if send_t>0.0 else 0.0
	if got>0.0: got=EXCHANGE.receive("player",get_res,got)
	# Both loads go on the one trade ledger (trade_ledger.gd): what we lean on them for.
	var ledger:=load(LEDGER_PATH) as GDScript
	if ledger!=null:
		if gave>0.0: ledger.call("note_flow","player",civ_id,give_res,gave,"pact")
		if got>0.0: ledger.call("note_flow",civ_id,"player",get_res,got,"pact")
	p.done=int(p.done)+1
	p.due=int(p.due)+period(t)
	var mine_ok:=fp>=0.999
	var theirs_ok:=ft>=0.999
	var portion:="the %s of %d portions" % [_ordinal(int(p.done)),int(t.portions)]
	var outcome:="delivered"; var text:=""; var tier:="whisper"
	if mine_ok and theirs_ok:
		text="Traders from %s brought %d %s and carried home %d %s, %s." % [name,roundi(got),get_res,roundi(gave),give_res,portion]
		if int(p.done)==1: tier="notice"
		var gain:=minf(0.01,GOODWILL_CAP-float(p.get("gw",0.0)))
		if gain>0.0:
			Hall._shift_relation(civ_id,gain,0.0); Hall._leader_trust(civ_id,gain); p.gw=float(p.get("gw",0.0))+gain
	elif gave<=0.5 and got<=0.5:
		outcome="skipped"; tier="notice"
		text="No goods changed hands with %s for %s: %s." % [name,portion,_short_reason(mine_ok,theirs_ok,give_res,get_res,name)]
	else:
		outcome="partial"; tier="notice"
		text="Only part of %s went through with %s: they brought %d of %d %s and you sent %d of %d %s. %s." % [portion,name,roundi(got),roundi(need_t),get_res,roundi(gave),roundi(need_p),give_res,_first_up(_short_reason(mine_ok,theirs_ok,give_res,get_res,name))]
	if debt and outcome!="delivered":
		var owed:=float(p.get("back",0.0))
		if linked and owed>0.0: text+=" The shortfall is owed with the next portion."
		elif not linked and (float(p.get("owe_p",0.0))>0.5 or float(p.get("owe_t",0.0))>0.5): text+=" What was not sent is owed with the next portion."
	# Keeping or breaking it moves them.
	if not mine_ok:
		p.miss_p=int(p.get("miss_p",0))+1 if fp<0.5 else int(p.get("miss_p",0))
		Hall._shift_relation(civ_id,-0.02 if fp<0.5 else -0.01,0.01)
		Hall._leader_trust(civ_id,-0.03 if fp<0.5 else -0.01)
	else: p.miss_p=0
	if not theirs_ok:
		p.miss_t=int(p.get("miss_t",0))+1 if ft<0.5 else int(p.get("miss_t",0))
		ForeignDiplomacy.remember(civ_id,"We could not send all the %s we promised the ruler." % get_res)
	else: p.miss_t=0
	_log(p,outcome,text)
	_record(("Traders From %s" % name.substr(0,36)) if outcome=="delivered" else ("A Short Portion From %s" % name.substr(0,30) if outcome=="partial" else "No Exchange With %s" % name.substr(0,32)),text,civ_id,"tp:%s:%d" % [p.id,int(p.done)],tier)
	if int(p.miss_p)>=MISSES_TO_LAPSE:
		p.status="cancelled"; p["ended"]=day
		Hall._shift_relation(civ_id,-0.05,0.03); Hall._leader_trust(civ_id,-0.08)
		_grudge(civ_id,"how you stopped sending the %s you promised" % give_res,0.35,"pact_broken:"+String(p.id))
		_log(p,"cancelled","They ended it: you failed %d portions running." % MISSES_TO_LAPSE)
		_record("%s Ends the Exchange" % name.substr(0,40),"%s has ended the exchange of %s: your people failed %d portions running. They will remember it." % [name,short_words(t),MISSES_TO_LAPSE],civ_id,"broken:"+String(p.id),"notice")
		ForeignDiplomacy.remember(civ_id,"The ruler stopped keeping our exchange, so we ended it.")
		return
	if int(p.miss_t)>=MISSES_TO_LAPSE:
		p.status="lapsed"; p["ended"]=day
		_log(p,"lapsed","It lapsed: they failed %d portions running." % MISSES_TO_LAPSE)
		_record("The Exchange With %s Lapses" % name.substr(0,32),"%s failed %d portions running, and the exchange of %s has lapsed. No blame falls on your people." % [name,MISSES_TO_LAPSE,short_words(t)],civ_id,"lapsed:"+String(p.id),"notice")
		return
	if int(p.done)>=int(t.portions):
		p.status="completed"; p["ended"]=day
		var kept:=true
		for entry in p.log: kept=kept and String((entry as Dictionary).get("o",""))!="skipped"
		if kept: Hall._shift_relation(civ_id,0.03,-0.02); Hall._leader_trust(civ_id,0.04)
		_log(p,"completed","Completed: all %d portions." % int(t.portions))
		_record("The Exchange With %s Is Complete" % name.substr(0,28),"The last portion of the exchange of %s with %s has been carried. %s" % [short_words(t),name,"Both sides kept it." if kept else "Not every portion went through."],civ_id,"done:"+String(p.id),"notice")
		ForeignDiplomacy.remember(civ_id,"Our exchange with the ruler ran its full course." if kept else "Our exchange with the ruler ran its course, with gaps.")

static func _short_reason(mine_ok:bool,theirs_ok:bool,give_res:String,get_res:String,name:String)->String:
	if not mine_ok and not theirs_ok: return "neither side had the goods to spare"
	if not mine_ok: return "your stores could not spare the %s" % give_res
	return "%s had no %s to spare" % [name,get_res]

static func _ordinal(n:int)->String:
	var suffix:="th"
	if n%100<11 or n%100>13:
		match n%10:
			1: suffix="st"
			2: suffix="nd"
			3: suffix="rd"
	return "%d%s" % [n,suffix]

static func _log(p:Dictionary,outcome:String,note:String)->void:
	var log:Array=p.get("log",[])
	log.push_front({"d":_day(),"o":outcome,"n":note.substr(0,240)})
	while log.size()>LOG_MAX: log.pop_back()
	p["log"]=log

static func _grudge(civ_id:String,clause:String,weight:float,key:String)->void:
	var r:=load(RIVALS_PATH) as GDScript
	if r!=null: r.call("grudge",civ_id,clause,weight,key)

static func _when(day:int)->String:
	var chronicle:=load(CHRONICLE_PATH) as GDScript
	return String(chronicle.call("date_label",maxi(0,day))) if chronicle!=null else "day %d" % day

static func _record(title:String,text:String,civ_id:String,key:String,tier:String)->void:
	var chronicle:=load(CHRONICLE_PATH) as GDScript
	if chronicle!=null: chronicle.call("record",{"title":title,"text":text,"tier":tier,"kind":"contact","key":"tp:%s:%s" % [civ_id,key]})

# --------------------------------------------------------------------------
# What the other ruler knows of it (for the live model), and what you see
# --------------------------------------------------------------------------

static func context(civ_id:String)->Dictionary:
	## The foreign ruler's own reading: their people's stores in words, what
	## they would part with per portion, how they value goods, and any
	## exchanges already in force. Exact ledgers stay private.
	var plenty:Array=[]; var short:Array=[]; var limits:={}
	for res:String in RESOURCES:
		var need:=_need_mult(civ_id,res)
		if need>1.1: short.append(res)
		elif _surplus_mult(civ_id,res)<0.9: plenty.append(res)
		limits[res]=their_limit(civ_id,res)
	var active:Array=[]
	for p in pacts(civ_id): active.append({"terms":short_words(p.terms),"portions_done":int(p.done),"portions":int(p.terms.portions)})
	return {"your_people_have_plenty_of":plenty,"your_people_are_short_of":short,"most_you_would_give_per_portion":limits,
		"relative_worth":PRICES.table(RESOURCES,civ_id),"least_value_you_accept_per_value_given":snappedf(_threshold(civ_id),0.05),"exchanges_in_force":active,"era_portion_ceiling":{"Food":cap("Food"),"Timber":cap("Timber"),"Stone":cap("Stone"),"Clay":cap("Clay"),"Fiber Plants":cap("Fiber Plants")}}

static func next_words(p:Dictionary)->String:
	if String(p.status)!="active": return String(p.status).capitalize()
	if bool(p.get("suspended",false)): return "Suspended while you are at war"
	if bool(p.get("waiting",false)): return "Portion %d waiting for goods (until %s)" % [int(p.done)+1,_when(int(p.due)+window(p.terms))]
	return "Portion %d of %d due %s" % [int(p.done)+1,int(p.terms.portions),_when(int(p.due))]
