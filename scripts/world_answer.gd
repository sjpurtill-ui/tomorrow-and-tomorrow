extends RefCounted
## WHAT A PEOPLE DOES ABOUT US: the feud's endings.
##
## A feud alone only loops: raids, a parley, three quiet years, raids again.
## Peoples in the record do not loop forever with a neighbour who terrifies
## them. They bend the knee and pay, or they gather every spear they have and
## come to settle it. Once a month every people we know weighs both, from
## what it remembers of us (deeds.gd: Fear and Resentment), the strength of
## its spears against ours (standing.gd: their league's together, if they are
## bound against us), how worn its feud has left it, and its ruler's nerve.
## The odds are stated (odds()) and shown on the Standing page; the roll is
## seeded.
##
## - BOW. Afraid and outmatched, they send an envoy to submit: tribute in
##   Food every harvest out of their own stores, a hostage of their ruler's
##   house, and no more raids. Taken, they are TRIBUTARIES: the feud is over,
##   their raiders stay home (war_loop.keeps_peace), their envoys bring no
##   demands, and each year the tribute moves between the two real ledgers
##   (civilization_exchange). Asking for more is a gamble at stated odds.
##   They pay while they still fear us and our spears still outmatch theirs;
##   when either fails they WITHHOLD it, and the bond is broken.
## - EVERYTHING THEY HAVE. Resentful and not outmatched (above all once bound
##   in a league against us), they arm for a season: their own ruler raises
##   more spears (their plan reads as war: civilization_strategy), which the
##   Chronicle warns of. Then every free fighter of theirs marches on our
##   nearest town as one band (war_council: the same raid, all of them), and
##   every league member that knows the way sends its own the same month.
##
## State lives in ForeignDiplomacy.audiences["answers"] (saved with the court;
## older saves start without it). Static helpers; preload. Read in any scope:
## a rival's own planner asks arming() about itself.

const VERSION:=1
## One great answer per people every this many days.
const ANSWER_GAP:=2*365
## A refused submission is not offered again for this long.
const REFUSED_GAP:=3*365
const ARMING_MIN:=60
const ARMING_MAX:=120
## A tributary's yearly tribute: this share of a year of its own people's
## eating (the record's tributaries gave a tenth or less of their harvest).
const TRIBUTE_SHARE:=0.05
const TRIBUTE_MIN:=15.0
## Of their stores, at most this much goes in one payment.
const STOCK_SHARE:=0.35
## Below these they stop paying.
const PAY_FEAR:=0.25
const PAY_RATIO:=1.0
## Monthly chances are capped here.
const BOW_MAX:=0.08
const ALL_IN_MAX:=0.06
const LOG_MAX:=40

const TYPES:={"submission":{"headline":"comes to bow before the god","family":"peace"}}

const Hall:=preload("res://scripts/audience_hall.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const WAR_PATH:="res://scripts/war_loop.gd"
const COUNCIL_PATH:="res://scripts/war_council.gd"
const STANDING_PATH:="res://scripts/standing.gd"
const DEEDS_PATH:="res://scripts/deeds.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"

static func _day()->int:
	return int(GameState.elapsed_days)

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	if not s.get("answers") is Dictionary or int((s.answers as Dictionary).get("version",0))!=VERSION:
		s["answers"]={"version":VERSION,"peoples":{},"tributaries":{},"arming":{},"log":[]}
	var a:Dictionary=s.answers
	for key in ["peoples","tributaries","arming"]:
		if not a.get(key) is Dictionary: a[key]={}
	if not a.get("log") is Array: a["log"]=[]
	return a

## Read without making the block (a rival's planner asks this every month).
static func _peek()->Dictionary:
	var holder:Variant=ForeignDiplomacy.get("audiences")
	var a:Variant=(holder as Dictionary).get("answers") if holder is Dictionary else null
	return a if a is Dictionary and int((a as Dictionary).get("version",0))==VERSION else {}

static func _num(v:Variant)->bool:
	return (v is int or v is float) and is_finite(float(v))

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	for key in ["peoples","tributaries","arming"]:
		if data.has(key):
			if not data[key] is Dictionary or (data[key] as Dictionary).size()>256: return false
			for k in data[key]:
				if not k is String or not data[key][k] is Dictionary or JSON.stringify(data[key][k]).length()>800: return false
	for k in (data.get("tributaries",{}) as Dictionary):
		var t:Dictionary=data.tributaries[k]
		for f in ["since","amount","due"]:
			if not _num(t.get(f)): return false
	for k in (data.get("arming",{}) as Dictionary):
		var a:Dictionary=data.arming[k]
		for f in ["since","march"]:
			if not _num(a.get(f)): return false
	if data.has("log") and (not data.log is Array or (data.log as Array).size()>LOG_MAX): return false
	return true

static func _log(civ_id:String,kind:String,text:String)->void:
	var list:Array=state().log
	list.push_front({"day":_day(),"civ":civ_id,"kind":kind,"text":text.substr(0,300)})
	while list.size()>LOG_MAX: list.pop_back()

static func _name(civ_id:String)->String:
	return Hall._civ_name(civ_id)

static func _chronicle(key:String,title:String,text:String,tier:String,civ_id:String)->void:
	var chronicle:=load(CHRONICLE_PATH) as GDScript
	if chronicle!=null: chronicle.call("record",{"key":key,"title":title.substr(0,70),"text":text,"tier":tier,"kind":"war","domain":"diplomacy","action":{"kind":"court","focus":{"civ_id":civ_id}}})

# --------------------------------------------------------------------------
# Status
# --------------------------------------------------------------------------

static func tributary(civ_id:String)->Dictionary:
	var a:=_peek()
	var t:Variant=(a.get("tributaries",{}) as Dictionary).get(civ_id) if not a.is_empty() else null
	return t if t is Dictionary else {}

static func is_tributary(civ_id:String)->bool:
	return not tributary(civ_id).is_empty()

## Arming to come at us with everything: {} or {since, march, league, cause}.
## Asked in a rival's own scope by its planner (civilization_strategy), with
## its own id.
static func arming(civ_id:String)->Dictionary:
	var a:=_peek()
	var v:Variant=(a.get("arming",{}) as Dictionary).get(civ_id) if not a.is_empty() else null
	return v if v is Dictionary else {}

static func tributaries()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var a:=_peek()
	if a.is_empty(): return out
	for civ_id in (a.tributaries as Dictionary):
		var t:Dictionary=(a.tributaries[civ_id] as Dictionary).duplicate()
		t["civ_id"]=String(civ_id); t["name"]=_name(String(civ_id))
		out.append(t)
	return out

# --------------------------------------------------------------------------
# What they weigh
# --------------------------------------------------------------------------

## {fear, resentment, ratio (our spears over theirs, a league's together),
## bold, worn, lost (towns of theirs we hold or burned), trait, league,
## knows_way, small}.
static func reading(civ_id:String)->Dictionary:
	var standing:=load(STANDING_PATH) as GDScript
	var v:Dictionary=standing.call("view_of",civ_id) if standing!=null else {}
	var p:=Hall._personality(civ_id)
	var war:=load(WAR_PATH) as GDScript
	var front:Dictionary=war.call("_peek",civ_id) if war!=null else {}
	var rivals:=load(RIVALS_PATH) as GDScript
	var character:Dictionary=rivals.call("rival_character",civ_id) if rivals!=null else {}
	var st:Dictionary=(load("res://scripts/envoy_aftermath.gd") as GDScript).call("standing",civ_id)
	var league:=load("res://scripts/fear_league.gd") as GDScript
	return {"known":bool(v.get("known",false)),"fear":float(v.get("fear",0.0)),"resentment":float(v.get("resentment",0.0)),"ratio":float(v.get("strength_ratio",1.0)),
		"bold":(float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5,"worn":float(front.get("their_exh",0.0)),
		"lost":(st.get("held",[]) as Array).size()+(st.get("burned",[]) as Array).size(),"trait":String(character.get("trait","")),
		"league":league!=null and bool(league.call("is_member",civ_id)),"knows_way":_knows_our_towns(civ_id)}

## Monthly chances: {bow, all_in, why_bow, why_all_in}. The same rule for
## every people; only their fear, grievance, strength and nerve differ.
static func odds(civ_id:String,r:Dictionary={})->Dictionary:
	if r.is_empty(): r=reading(civ_id)
	var out:={"bow":0.0,"all_in":0.0,"why_bow":"","why_all_in":""}
	if not bool(r.get("known",false)): return out
	var fear:=float(r.fear); var res:=float(r.resentment); var ratio:=float(r.ratio); var bold:=float(r.bold)
	if fear>=0.4 and ratio>=1.3:
		var outmatched:=clampf((ratio-1.3)/1.2+0.3,0.0,1.0)
		var bow:=(fear-0.4)*0.3*outmatched*clampf(1.3-bold,0.2,1.0)*(1.3 if int(r.lost)>0 else 1.0)*(0.5 if String(r.trait)=="grudge" else 1.0)
		out.bow=clampf(bow,0.0,BOW_MAX)
		out.why_bow="they fear us (%d in 100) and our spears %s theirs" % [roundi(fear*100.0),_ratio_words(ratio)]
	if res>=0.45 and ratio<=1.5 and float(r.worn)<0.4 and bool(r.get("knows_way",true)):
		var all_in:=(res-0.45)*0.25*clampf(1.6-ratio,0.0,1.0)*(0.6+bold)*(1.3 if String(r.trait) in ["grudge","hunter"] else 1.0)*(1.5 if bool(r.league) else 1.0)
		out.all_in=clampf(all_in,0.0,ALL_IN_MAX)
		out.why_all_in="they resent us (%d in 100) and our spears %s theirs%s" % [roundi(res*100.0),_ratio_words(ratio)," with their league's" if bool(r.league) else ""]
	return out

static func _ratio_words(ratio:float)->String:
	var standing:=load(STANDING_PATH) as GDScript
	return String(standing.call("_ratio_words",ratio)) if standing!=null else "match"

static func _knows_our_towns(civ_id:String)->bool:
	if not WorldSimulation.enabled or not WorldSimulation.actors.has(civ_id): return true
	return bool(WorldSimulation.scoped(civ_id,func()->bool:
		return not ((load(COUNCIL_PATH) as GDScript).call("known_towns","human") as Array).is_empty()))

# --------------------------------------------------------------------------
# Monthly
# --------------------------------------------------------------------------

## Once a month (war_loop.daily, after the league is read): tribute falls due,
## armed peoples march, and every other people we know weighs its answer.
static func monthly(day:int)->void:
	if String(WorldSimulation.actor_id)!="player" or WorldSimulation.world==null: return
	var a:=state()
	for civ_id in (a.tributaries as Dictionary).keys():
		if day>=int((a.tributaries[civ_id] as Dictionary).get("due",day+1)): _tribute_due(String(civ_id),day)
	for civ_id in (a.arming as Dictionary).keys():
		if day>=int((a.arming[civ_id] as Dictionary).get("march",day+1)): _march(String(civ_id),day)
	var war:=load(WAR_PATH) as GDScript
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or not bool((civ as Dictionary).get("alive",true)): continue
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player" or bool((civ as Dictionary).get("general_campaign_owned",false)): continue
		var relation:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(relation.get("contact_level",0))<2: continue
		if (a.tributaries as Dictionary).has(id) or (a.arming as Dictionary).has(id): continue
		if bool(war.call("broken",id)): continue
		# A war between peoples organised for it is fought out by its own rules.
		if bool(relation.get("at_war",false)) and bool(war.call("formal",id)): continue
		var mine:Dictionary=(a.peoples as Dictionary).get(id,{})
		if day-int(mine.get("day",-99999))<ANSWER_GAP: continue
		# Kin by marriage do not come against kin.
		var kin:=not (war.call("_married",id) as Dictionary).is_empty()
		var o:=odds(id)
		var roll:=_rng("answer:%s:%d" % [id,day]).randf()
		if roll<float(o.bow) and day-int(mine.get("refused",-99999))>=REFUSED_GAP:
			_offer_submission(id,day,o)
		elif not kin and roll<float(o.bow)+float(o.all_in):
			_begin_arming(id,day,o)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s" % [int(GameState.world_seed),key])
	return rng

static func _mark(civ_id:String,kind:String,day:int)->void:
	var peoples:Dictionary=state().peoples
	var mine:Dictionary=peoples.get(civ_id,{})
	mine["kind"]=kind; mine["day"]=day
	peoples[civ_id]=mine

# --------------------------------------------------------------------------
# Bowing
# --------------------------------------------------------------------------

static func _offer_submission(civ_id:String,day:int,o:Dictionary)->void:
	_mark(civ_id,"bow",day)
	Hall._add_occasion({"key":"submission:%s:%d" % [civ_id,day],"type":"submission","civ_id":civ_id,"day":day,"not_before":day,"expires":day+120,"crisis":true,
		"data":{"text":"they come to bow before the god","why":String(o.get("why_bow",""))}})
	_log(civ_id,"bow_offered","%s sends an envoy to submit: %s." % [_name(civ_id),String(o.get("why_bow",""))])

## What they offer: a yearly tribute out of their own stores and a hostage
## of their ruler's house. {resource, amount, now, hostage}.
static func terms(civ_id:String)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=float(civ.get("population",100.0))
	var stock:=Hall.foreign_stock(civ_id,"Food")
	var amount:=maxf(TRIBUTE_MIN,pop*_eats_per_head()*365.0*TRIBUTE_SHARE)
	if stock>=0.0: amount=minf(amount,maxf(TRIBUTE_MIN,stock*STOCK_SHARE))
	amount=Hall._nice(amount)
	var now:=Hall._nice(minf(amount,stock)) if stock>=0.0 else amount
	return {"resource":"Food","amount":amount,"now":maxf(0.0,now),"hostage":_hostage(civ_id)}

## Food one person eats in a day, read from our own people's eating (the
## same diet scale for every people in this age).
static func _eats_per_head()->float:
	var m:Dictionary=GameState.simulation_metrics
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var eaten:=float(m.get("food_consumption",0.0))
	return clampf(eaten/people,0.05,0.6) if eaten>0.0 else 0.17

static func _hostage(civ_id:String)->String:
	var rivals:=load(RIVALS_PATH) as GDScript
	var ruler:=String(rivals.call("given",civ_id)) if rivals!=null else ""
	var son:=EraNames.given_for(int(GameState.world_seed),"hostage:%s" % civ_id,false,civ_id,{ruler:true,"given:"+ruler:true})
	return "%s, son of %s" % [son,ruler] if ruler!="" else son

static func handles(situation_type:String)->bool:
	return TYPES.has(situation_type)

static func family(situation_type:String)->String:
	return String((TYPES.get(situation_type,{}) as Dictionary).get("family",""))

static func candidate(situation_type:String,civ_id:String,occasion:Dictionary,_rng_in:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	if situation_type!="submission" or is_tributary(civ_id): return {}
	var t:=terms(civ_id)
	var name:=_name(civ_id)
	var rivals:=load(RIVALS_PATH) as GDScript
	var ruler:=String(rivals.call("given",civ_id)) if rivals!=null else "their ruler"
	var why:=String((occasion.get("data",{}) as Dictionary).get("why","")) if occasion.get("data") is Dictionary else ""
	var s:={"type":"submission","headline":"comes to bow before the god","ask":"submission:%d" % floori(float(day)/365.0)}
	if used.has(String(s.ask)): return {}
	s["req"]={"resource":String(t.resource),"amount":float(t.amount),"now":float(t.now),"hostage":String(t.hostage),"why":why}
	s.summary="%s bows. %s will send %d %s every harvest%s, give %s into your keeping, and send no more raiders against us." % [name,ruler,roundi(float(t.amount)),String(t.resource),(" (%d now)" % roundi(float(t.now))) if float(t.now)>0.0 else "",String(t.hostage)]
	return {"kind":"request","situation":s}

## Asking for twice as much: the odds they bear it.
static func more_odds(civ_id:String)->float:
	var r:=reading(civ_id)
	return clampf(float(r.fear)*1.1-float(r.bold)*0.4+clampf(float(r.ratio)-1.5,0.0,1.0)*0.25,0.1,0.9)

## The envoy's own words, from the terms (offline voice; the live voice is
## given the same facts).
static func open_lines(audience:Dictionary)->Array:
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var rivals:=load(RIVALS_PATH) as GDScript
	var ruler:=String(rivals.call("given",civ_id)) if rivals!=null else "Our ruler"
	var amount:=roundi(float(p.get("amount",0.0)))
	var out:Array=[]
	out.append("%s will fight you no more. Every harvest we will bring you %d Food, and %s stays with you as our pledge." % [ruler,amount,String(p.get("hostage","a son of our house"))])
	out.append("We have buried enough of ours. Take our tribute and let our people live.")
	return out

static func _req(audience:Dictionary)->Dictionary:
	var s:=Hall._situation(audience)
	return s.get("req",{}) if s.get("req") is Dictionary else {}

static func options(audience:Dictionary)->Array[Dictionary]:
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var name:=String(audience.get("civ_name",_name(civ_id)))
	var o:Array[Dictionary]=[]
	o.append(Hall._option("accept","Take their tribute and their hostage","%s pays %d %s every harvest and %s lives among us. Their raiders stay home." % [name,roundi(float(p.get("amount",0.0))),String(p.get("resource","Food")),String(p.get("hostage","a hostage"))],"neutral"))
	var chance:=more_odds(civ_id)
	o.append(Hall._option("more","Demand twice as much","%d in 100 they bear it and pay %d a year. Otherwise they go home shamed, and remember it." % [roundi(chance*100.0),roundi(float(p.get("amount",0.0))*2.0)],"hostile"))
	o.append(Hall._option("refuse","Turn them away","The feud goes on. They will not bow again for years.","hostile"))
	for option in o: option["cost"]=("Risk: " if String(option.id)!="accept" else "Cost: ")+String(option.sub)
	return o

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var name:=String(audience.get("civ_name",_name(civ_id)))
	var day:=_day()
	var amount:=float(p.get("amount",TRIBUTE_MIN))
	match option_id:
		"accept":
			var text:=_bind(civ_id,day,amount,String(p.get("hostage","")),float(p.get("now",0.0)),"")
			return {"outcome":text,"reaction":"neutral"}
		"more":
			var chance:=more_odds(civ_id)
			var roll:=_rng("more:%s:%d" % [civ_id,day]).randf()
			if roll<chance:
				var text2:=_bind(civ_id,day,amount*2.0,String(p.get("hostage","")),float(p.get("now",0.0)),"They bore your demand (%d in 100): " % roundi(chance*100.0))
				return {"outcome":text2,"reaction":"offended"}
			_refused(civ_id,day,"the god's scorn for their submission")
			var r:=load(RIVALS_PATH) as GDScript
			if r!=null: r.call("grudge",civ_id,"how you shamed our submission",0.5,"submission_shamed:%d" % day)
			var lost:="%s would not bear twice the tribute (the odds were %d in 100). Their envoy went home shamed; the feud goes on." % [name,roundi(chance*100.0)]
			_log(civ_id,"bow_shamed",lost)
			return {"outcome":lost,"reaction":"offended"}
		"refuse":
			_refused(civ_id,day,"the god turning away their submission")
			var told:="You turned %s's submission away. The feud goes on, and they will not bow again for years." % name
			_log(civ_id,"bow_refused",told)
			return {"outcome":told,"reaction":"offended"}
	return {"error":"That answer is not open to you here."}

static func _refused(civ_id:String,day:int,words:String)->void:
	var peoples:Dictionary=state().peoples
	var mine:Dictionary=peoples.get(civ_id,{})
	mine["refused"]=day; mine["kind"]="bow_refused"; mine["day"]=day
	peoples[civ_id]=mine
	ForeignDiplomacy.remember(civ_id,"The god would not take our submission.")
	(load(DEEDS_PATH) as GDScript).call("record",civ_id,"shame_envoy",1,words)

## They become tributaries: the feud ends, the first tribute comes with the
## envoy, and their raiders stay home while they pay.
static func _bind(civ_id:String,day:int,amount:float,hostage:String,now:float,lead:String)->String:
	var name:=_name(civ_id)
	var paid:=0.0
	if now>0.0:
		paid=Hall.EXCHANGE.take(civ_id,"Food",minf(now,amount))
		if paid>0.0: Hall.EXCHANGE.receive("player","Food",paid)
	state().tributaries[civ_id]={"since":day,"resource":"Food","amount":Hall._nice(amount),"hostage":hostage.substr(0,80),"due":day+365,"paid":1 if paid>0.0 else 0,"missed":0}
	var war:=load(WAR_PATH) as GDScript
	if war!=null and bool(war.call("feuding",civ_id,day)): war.call("_end_feud",civ_id,day,"submission","%s bowed to the god." % name)
	var index:=Hall._civ_index(civ_id)
	if index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[index].player_relation
		relation["stance"]="tributary"
	ForeignDiplomacy.remember(civ_id,"We bowed to the god and pay its people tribute.")
	_mark(civ_id,"bow",day)
	var text:="%s%s bows to the god. %s pays %d Food every harvest%s, and %s lives among us as their pledge. Their raiders stay home while they pay." % [lead,name,name,roundi(amount),(" (%d came with the envoy)" % roundi(paid)) if paid>0.0 else "",hostage if hostage!="" else "a hostage"]
	_chronicle("bow:%s:%d" % [civ_id,day],"%s Bows to the God" % name,text,"moment",civ_id)
	_log(civ_id,"bow",text)
	return text

## A harvest's tribute falls due: they pay while they still fear us and our
## spears still outmatch theirs; otherwise they withhold it and the bond breaks.
static func _tribute_due(civ_id:String,day:int)->void:
	var a:=state()
	var t:Dictionary=a.tributaries[civ_id]
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var name:=_name(civ_id)
	if civ.is_empty() or not bool(civ.get("alive",true)):
		(a.tributaries as Dictionary).erase(civ_id)
		return
	var r:=reading(civ_id)
	var amount:=float(t.get("amount",TRIBUTE_MIN))
	var stock:=Hall.foreign_stock(civ_id,"Food")
	if float(r.fear)>=PAY_FEAR and float(r.ratio)>=PAY_RATIO and (stock<0.0 or stock>=amount*0.5):
		var paid:=Hall.EXCHANGE.take(civ_id,"Food",minf(amount,stock*STOCK_SHARE*2.0) if stock>=0.0 else amount)
		if paid>0.0: Hall.EXCHANGE.receive("player","Food",paid)
		t["paid"]=int(t.get("paid",0))+1
		t["due"]=int(t.due)+365
		t["last_paid"]=roundi(paid)
		var first:=int(t.paid)<=2
		_chronicle("tribute:%s:%d" % [civ_id,day],"%s Brings Its Tribute" % name,"%s brought %d Food, as it does every harvest since it bowed (the %s time)." % [name,roundi(paid),_nth(int(t.paid))],"moment" if first else "notice",civ_id)
		_log(civ_id,"tribute_paid","%d Food" % roundi(paid))
		return
	var why:="they no longer fear us enough" if float(r.fear)<PAY_FEAR else ("their spears now match ours" if float(r.ratio)<PAY_RATIO else "their stores are too thin")
	(a.tributaries as Dictionary).erase(civ_id)
	var index:=Hall._civ_index(civ_id)
	if index>=0: WorldSimulation.world.civilizations[index].player_relation["stance"]="hostile"
	_mark(civ_id,"withheld",day)
	var text:="%s did not bring its tribute this harvest: %s. The bond is broken. %s is still in our hands." % [name,why,String(t.get("hostage","Their hostage"))]
	_chronicle("withheld:%s:%d" % [civ_id,day],"%s Withholds Its Tribute" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"We no longer pay the god's people tribute.")
	_log(civ_id,"withheld",text)

const ORDINALS:=["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth"]
static func _nth(n:int)->String:
	return String(ORDINALS[n-1]) if n>=1 and n<=ORDINALS.size() else "%dth" % n

# --------------------------------------------------------------------------
# Everything they have
# --------------------------------------------------------------------------

static func _begin_arming(civ_id:String,day:int,o:Dictionary)->void:
	var league:=load("res://scripts/fear_league.gd") as GDScript
	var with:Array=[]
	if league!=null and bool(league.call("is_member",civ_id)):
		for other in league.call("members"):
			if String(other)!=civ_id: with.append(String(other))
	var march:=day+_rng("arm:%s:%d" % [civ_id,day]).randi_range(ARMING_MIN,ARMING_MAX)
	state().arming[civ_id]={"since":day,"march":march,"league":with,"cause":String(o.get("why_all_in","")).substr(0,160)}
	_mark(civ_id,"all_in",day)
	var name:=_name(civ_id)
	var allies:=""
	if not with.is_empty():
		var names:PackedStringArray=[]
		for other in with: names.append(_name(String(other)))
		allies=" %s will come with them." % " and ".join(names)
	var text:="%s is calling every spear it has. Their ruler means to settle it with us before the season is out.%s Our watch should be ready." % [name,allies]
	_chronicle("arming:%s:%d" % [civ_id,day],"%s Sharpens Every Spear" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"We gather every spear to settle it with the god's people.")
	_log(civ_id,"arming",text)

## The march: every free fighter of theirs, and of each league member that
## knows the way, goes as one band on our nearest town (war_council: the
## same raid as any other, sent whole).
static func _march(civ_id:String,day:int)->void:
	var a:=state()
	var arm:Dictionary=a.arming[civ_id]
	(a.arming as Dictionary).erase(civ_id)
	var war:=load(WAR_PATH) as GDScript
	if war!=null and bool(war.call("keeps_peace",civ_id,day)):
		_log(civ_id,"stood_down","%s laid its spears down again: the peace holds." % _name(civ_id))
		return
	var went:Array=[]
	for id in [civ_id]+(arm.get("league",[]) as Array):
		if _send_all(String(id),day): went.append(String(id))
	var name:=_name(civ_id)
	if went.is_empty():
		_log(civ_id,"no_march","%s gathered its spears but never found the road to us." % name)
		return
	var names:PackedStringArray=[]
	for id in went: names.append(_name(String(id)))
	var text:="%s %s on the road to us with every fighter %s. Their bands march on our nearest town." % [" and ".join(names),"are" if went.size()>1 else "is","they have" if went.size()>1 else "it has"]
	_chronicle("all_in:%s:%d" % [civ_id,day],"%s Comes With Everything" % name if went.size()==1 else "They Come With Everything",text,"moment",civ_id)
	_log(civ_id,"march",text)

static func _send_all(civ_id:String,day:int)->bool:
	var war:=load(WAR_PATH) as GDScript
	if WorldSimulation.enabled and WorldSimulation.actors.has(civ_id):
		return bool(WorldSimulation.scoped(civ_id,func()->bool:
			var council:=load(COUNCIL_PATH) as GDScript
			var towns:Array=council.call("known_towns","human")
			if towns.is_empty(): return false
			var done:Dictionary=council.call("_launch","human",towns[0],"punish",true,{"all":true})
			return String(done.get("verdict",""))=="act" or bool(done.get("live",false))))
	# A people the world does not simulate in full sends its counted fighters.
	if war==null: return false
	var result:Dictionary=war.call("_raid",civ_id,day,"everything",true,false)
	return not result.is_empty()
