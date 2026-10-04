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
## - BOW. Afraid and outmatched, they send an envoy to submit: tribute every
##   season, a hostage of their ruler's house, and no more raids. Taken, they
##   are TRIBUTARIES: the feud is over, their raiders stay home
##   (war_loop.keeps_peace) and their envoys bring no demands. The tribute is
##   the economy's own (trade_stances: an agreement in the trade ledger, sized
##   by tribute_size and collected each season in their goods, the same
##   ledger every people's tribute runs through). Asking for twice as much is
##   a gamble at stated odds. Each year they weigh it again: they keep paying
##   while they still fear us and our spears still outmatch theirs; when
##   either fails, or their goods run out, they WITHHOLD it and the bond is
##   broken.
## - EVERYTHING THEY HAVE. Resentful and not outmatched (above all once bound
##   in a league against us), they arm for a season: their own ruler raises
##   more spears (their plan reads as war: civilization_strategy), which the
##   Chronicle warns of. Then every free fighter of theirs marches on our
##   nearest town as one band (war_council: the same raid, all of them), and
##   every league member that knows the way sends its own the same month. A
##   people organised for war (conflict_scale.gd) declares war instead.
##
## State lives in ForeignDiplomacy.audiences["answers"] (saved with the court;
## older saves start without it). Static helpers; preload. Read in any scope:
## a rival's own planner asks arming() about itself.

const VERSION:=1
## One great answer per people every this many days; after coming at us with
## everything, a people needs longer to gather itself again (and the dead it
## left at our hearths are told as fear, leaning it toward bowing next).
const ANSWER_GAP:=2*365
const ALL_IN_GAP:=5*365
## A refused submission is not offered again for this long.
const REFUSED_GAP:=3*365
const ARMING_MIN:=60
const ARMING_MAX:=120
## A tribute agreement in the trade ledger is kept this far ahead while the
## bond holds, and renewed at each yearly reckoning.
const BOND_AHEAD:=2*365
## Without a trade report for them: a season's tribute worth this share of
## a season of their people's eating, at the price of Food.
const FALLBACK_SHARE:=0.05
## Below these they stop paying.
const PAY_FEAR:=0.25
const PAY_RATIO:=1.0
## Monthly chances are capped here.
const BOW_MAX:=0.08
const ALL_IN_MAX:=0.06
const LOG_MAX:=40

const TYPES:={"submission":{"headline":"comes to bow before the god","family":"peace"}}

const Hall:=preload("res://scripts/audience_hall.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const TradeLedger:=preload("res://scripts/trade_ledger.gd")
const Prices:=preload("res://scripts/trade_prices.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const WAR_PATH:="res://scripts/war_loop.gd"
const COUNCIL_PATH:="res://scripts/war_council.gd"
const STANDING_PATH:="res://scripts/standing.gd"
const DEEDS_PATH:="res://scripts/deeds.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"
const PERSONS_PATH:="res://scripts/court_persons.gd"

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
		for f in ["since","value","due"]:
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

## Late word of an arming our watchers missed: it reaches us in the last month
## before they march (standing.gd LATE_WORD_DAYS), told then.
static func _late_word(civ_id:String,day:int)->void:
	var arm:Dictionary=(state().arming as Dictionary).get(civ_id,{})
	if arm.is_empty() or bool(arm.get("heard",true)): return
	var left:=int(arm.get("march",day))-day
	var standing:=load(STANDING_PATH) as GDScript
	var late:=int(standing.get_script_constant_map().get("LATE_WORD_DAYS",30)) if standing!=null else 30
	if left>late: return
	arm["heard"]=true
	var name:=_name(civ_id)
	var text:="Late word: %s is calling every spear it has, and marches on us within %s. Our watchers did not see it begin (we hear of it at once %d times in 100, by our cunning). Our watch should be ready." % [name,_days_words(maxi(1,left)),roundi(float(arm.get("heard_odds",0.5))*100.0)]
	_chronicle("arming_late:%s:%d" % [civ_id,int(arm.get("since",day))],"Late Word: %s Sharpens Every Spear" % name,text,"moment",civ_id)
	_log(civ_id,"arming",text)

## Arming against us as far as we have heard of it ({} while our watchers
## have missed it): what the Standing page and the court can say.
static func heard_of_arming(civ_id:String)->Dictionary:
	var arm:=arming(civ_id)
	return arm if bool(arm.get("heard",true)) else {}

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
## bold, worn, lost (towns of theirs we hold or burned), trait, league}.
## odds() asks whether they know the road to us only when it matters.
static func reading(civ_id:String,view:Dictionary={})->Dictionary:
	var standing:=load(STANDING_PATH) as GDScript
	var v:Dictionary=view if not view.is_empty() else (standing.call("view_of",civ_id) if standing!=null else {})
	var p:=Hall._personality(civ_id)
	var war:=load(WAR_PATH) as GDScript
	var front:Dictionary=war.call("_peek",civ_id) if war!=null else {}
	var rivals:=load(RIVALS_PATH) as GDScript
	var character:Dictionary=rivals.call("rival_character",civ_id) if rivals!=null else {}
	var st:Dictionary=(load("res://scripts/envoy_aftermath.gd") as GDScript).call("standing",civ_id)
	var league:=load("res://scripts/fear_league.gd") as GDScript
	var bound:=war!=null and (bool(war.call("keeps_peace",civ_id,_day())) or not (war.call("_married",civ_id) as Dictionary).is_empty())
	return {"known":bool(v.get("known",false)),"vow":_vow(civ_id),"sworn_vengeance":bool((load("res://scripts/envoy_aftermath.gd") as GDScript).call("sworn",civ_id)),"at_peace":bound,"fear":float(v.get("fear",0.0)),"resentment":float(v.get("resentment",0.0)),"ratio":float(v.get("strength_ratio",1.0)),
		"bold":(float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5,"worn":float(front.get("their_exh",0.0)),
		"lost":(st.get("held",[]) as Array).size()+(st.get("burned",[]) as Array).size(),"trait":String(character.get("trait","")),
		"league":league!=null and bool(league.call("is_member",civ_id))}

## Monthly chances: {bow, all_in, why_bow, why_all_in}. The same rule for
## every people; only their fear, grievance, strength and nerve differ.
static func odds(civ_id:String,r:Dictionary={})->Dictionary:
	if r.is_empty(): r=reading(civ_id)
	var out:={"bow":0.0,"all_in":0.0,"why_bow":"","why_all_in":""}
	if not bool(r.get("known",false)): return out
	var fear:=float(r.fear); var res:=float(r.resentment); var ratio:=float(r.ratio); var bold:=float(r.bold)
	if fear>=0.4 and ratio>=1.3:
		var outmatched:=clampf((ratio-1.3)/1.2+0.3,0.0,1.0)
		var bow:=(fear-0.4)*0.3*outmatched*clampf(1.3-bold,0.2,1.0)*(1.3 if int(r.lost)>0 else 1.0)*(0.5 if String(r.trait)=="grudge" else 1.0)*float(VOW_BOW.get(String(r.get("vow","")),1.0))
		out.bow=clampf(bow,0.0,BOW_MAX)
		out.why_bow="they fear us (%d in 100) and our spears %s theirs" % [roundi(fear*100.0),_ratio_words(ratio)]
	# Whether they know the road to a town of ours is asked last, and only of a
	# people otherwise ready to come (it is read in their own world). A people
	# bound to peace with us (a truce, a pact, a settled feud, kin, tribute)
	# does not come.
	if res>=0.45 and ratio<=1.5 and float(r.worn)<0.4 and not bool(r.get("at_peace",false)) and (bool(r.knows_way) if r.has("knows_way") else _knows_our_towns(civ_id)):
		var all_in:=(res-0.45)*0.25*clampf(1.6-ratio,0.0,1.0)*(0.6+bold)*(1.3 if String(r.trait) in ["grudge","hunter"] else 1.0)*(1.5 if bool(r.league) else 1.0)*float(VOW_ALL_IN.get(String(r.get("vow","")),1.0))*(VENGEANCE_ALL_IN if bool(r.get("sworn_vengeance",false)) else 1.0)
		out.all_in=clampf(all_in,0.0,ALL_IN_MAX)
		out.why_all_in="they resent us (%d in 100) and our spears %s theirs%s" % [roundi(res*100.0),_ratio_words(ratio)," with their league's" if bool(r.league) else ""]
	return out

## What their ruler has sworn about us (legacy_aims.gd rival vows) leans
## the answer: sworn to make us yield, they come sooner and bow later; sworn
## to bind us in friendship, they seldom come at all.
const VOW_BOW:={"humble":0.6,"bond":1.2}
const VOW_ALL_IN:={"humble":1.3,"bond":0.4}
## A ruler who has sworn vengeance to our face (envoy_aftermath.gd) comes
## sooner: the vow is the warning, the arming its keeping.
const VENGEANCE_ALL_IN:=1.4
const AIMS_PATH:="res://scripts/legacy_aims.gd"

## The template of their ruler's vow still sworn ("humble", "bond", ...), or "".
static func _vow(civ_id:String)->String:
	var aims:=load(AIMS_PATH) as GDScript
	if aims==null: return ""
	var s:Dictionary=aims.call("state")
	var r:Variant=(s.get("rivals",{}) as Dictionary).get(civ_id)
	if not r is Dictionary or String((r as Dictionary).get("status",""))!="active": return ""
	return String((r as Dictionary).get("template",""))

## They bowed: a vow to make us yield came to nothing, told as such.
static func _vow_undone(civ_id:String,day:int)->void:
	if _vow(civ_id)!="humble": return
	var aims:=load(AIMS_PATH) as GDScript
	var r:Dictionary=(aims.call("state").rivals as Dictionary)[civ_id]
	aims.call("_rival_close",r,"failed",day)

static func _ratio_words(ratio:float)->String:
	var standing:=load(STANDING_PATH) as GDScript
	return String(standing.call("_ratio_words",ratio)) if standing!=null else "match"

## Free to come against us: not a tributary, not kin by marriage, not bound
## by a truce, a pact or a settled feud (war_loop.keeps_peace), and not
## broken. A people organised for war comes only when formal_ok (as a
## league member it declares war instead of raiding).
static func free_to_come(civ_id:String,day:int=-1,formal_ok:bool=false)->bool:
	if day<0: day=_day()
	if is_tributary(civ_id): return false
	var war:=load(WAR_PATH) as GDScript
	if war==null: return true
	if bool(war.call("keeps_peace",civ_id,day)) or bool(war.call("broken",civ_id)) or (bool(war.call("formal",civ_id)) and not formal_ok): return false
	return (war.call("_married",civ_id) as Dictionary).is_empty()

static func _knows_our_towns(civ_id:String)->bool:
	if not WorldSimulation.enabled or not WorldSimulation.actors.has(civ_id): return true
	return bool(WorldSimulation.scoped(civ_id,func()->bool:
		return not ((load(COUNCIL_PATH) as GDScript).call("known_towns","human") as Array).is_empty()))

## What this people's answer to us is, as the Standing page says it:
## [{id, tone, words, detail}] (consequences rows), worst first.
static func standing_rows(civ_id:String,view:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var t:=tributary(civ_id)
	if not t.is_empty():
		var hostage:=String(t.get("hostage",""))
		out.append({"id":"tributary","tone":"good","words":"Bowed to us: tribute worth %s every season%s" % [_qty(float(t.get("value",0.0))),("; %s is our hostage" % hostage) if hostage!="" else ""],
			"detail":"Worth %s paid in all since they bowed. They pay while they fear us (they stop below %d in 100) and our spears outmatch theirs." % [_qty(paid_so_far(civ_id)),roundi(PAY_FEAR*100.0)]})
		return out
	var arm:=heard_of_arming(civ_id)
	if not arm.is_empty():
		var left:=maxi(0,int(arm.get("march",_day()))-_day())
		out.append({"id":"arming","tone":"danger","words":"Gathering every spear against us: they march in about %s" % _days_words(left),
			"detail":String(arm.get("cause",""))})
		return out
	var standing:=load(STANDING_PATH) as GDScript
	var o:=odds(civ_id,reading(civ_id,view))
	if float(o.all_in)>0.0:
		out.append({"id":"all_in","tone":"danger","words":"May come at us with every spear they have: %s" % String(standing.call("monthly_odds_words",float(o.all_in))),"detail":"Because %s. One great answer every two years at most." % String(o.why_all_in)})
	if float(o.bow)>0.0:
		out.append({"id":"bow","tone":"good","words":"May come to bow and pay us tribute: %s" % String(standing.call("monthly_odds_words",float(o.bow))),"detail":"Because %s." % String(o.why_bow)})
	return out

static func _days_words(days:int)->String:
	if days<=7: return "a few days"
	if days<45: return "%d days" % (roundi(float(days)/5.0)*5)
	return "%d months" % maxi(1,roundi(float(days)/30.0))

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
		else: _late_word(String(civ_id),day)
	var war:=load(WAR_PATH) as GDScript
	# One reading of our strengths and our people's dread serves every people
	# weighed this month (standing.gd's shared reading).
	var standing:=load(STANDING_PATH) as GDScript
	standing.call("_begin_reading")
	var our:Dictionary=standing.call("strengths")
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
		if day-int(mine.get("day",-99999))<(ALL_IN_GAP if String(mine.get("kind",""))=="all_in" else ANSWER_GAP): continue
		# Having come at us with everything once, they come again only for a
		# new wrong done to them since (deeds.gd): old grudges alone do not
		# send a people to throw all its spears at us twice.
		var came:=int(mine.get("came",-1))
		# Kin by marriage do not come against kin.
		var kin:=not (war.call("_married",id) as Dictionary).is_empty()
		var o:=odds(id,reading(id,standing.call("view_of",id,our)))
		var roll:=_rng("answer:%s:%d" % [id,day]).randf()
		# One roll, two stated chances: under the first they bow (unless their
		# last bow was turned away too lately), under both together they come.
		if roll<float(o.bow):
			if day-int(mine.get("refused",-99999))>=REFUSED_GAP: _offer_submission(id,day,o)
		elif not kin and float(o.all_in)>0.0 and roll<float(o.bow)+float(o.all_in) and (came<0 or int((load(DEEDS_PATH) as GDScript).call("last_wrong",id))>came):
			_begin_arming(id,day,o)
	standing.call("_end_reading")

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

## What they offer: tribute every season, of the size every people's
## tribute is (trade_stances.tribute_size: a share of what they make), and a
## hostage of their ruler's house. {value, hostage}.
static func terms(civ_id:String)->Dictionary:
	var value:=Stances.tribute_size(civ_id)
	if value<=0.0:
		var civ:=ForeignDiplomacy.civilization(civ_id)
		value=float(civ.get("population",100.0))*_eats_per_head()*91.0*FALLBACK_SHARE*Prices.base("Food")
	return {"value":snappedf(maxf(1.0,value),0.1),"hostage":_hostage(civ_id)}

## How a worth is said (the trade pages' own words).
static func _qty(value:float)->String:
	var words:=load("res://scripts/trade_words.gd") as GDScript
	return String(words.call("qty",value)) if words!=null else "%d" % roundi(value)

## Worth paid in all through the trade ledger since they bowed.
static func paid_so_far(civ_id:String)->float:
	return float(Stances.tribute(civ_id,"player").get("paid",0.0))

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
	# A son of this day's ruler: never the name of one given before.
	var taken:={ruler:true,"given:"+ruler:true}
	var persons:=load(PERSONS_PATH) as GDScript
	if persons!=null:
		for p in persons.call("people"): taken[String((p as Dictionary).get("given",""))]=true
	var son:=EraNames.given_for(int(GameState.world_seed),"hostage:%s:%d" % [civ_id,_day()],false,civ_id,taken)
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
	s["req"]={"value":float(t.value),"hostage":String(t.hostage),"why":why}
	s.summary="%s bows. %s will send tribute worth %s every season, give %s into your keeping, and send no more raiders against us." % [name,ruler,_qty(float(t.value)),String(t.hostage)]
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
	var out:Array=[]
	out.append("%s will fight you no more. Every season we will bring you goods worth %s, and %s stays with you as our pledge." % [ruler,_qty(float(p.get("value",0.0))),String(p.get("hostage","a son of our house"))])
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
	o.append(Hall._option("accept","Take their tribute and their hostage","%s pays tribute worth %s every season and %s lives among us. Their raiders stay home." % [name,_qty(float(p.get("value",0.0))),String(p.get("hostage","a hostage"))],"neutral"))
	var chance:=more_odds(civ_id)
	o.append(Hall._option("more","Demand twice as much","%d in 100 they bear it and pay %s a season. Otherwise they go home shamed, and remember it." % [roundi(chance*100.0),_qty(float(p.get("value",0.0))*2.0)],"hostile"))
	o.append(Hall._option("refuse","Turn them away","The feud goes on. They will not bow again for years.","hostile"))
	for option in o: option["cost"]=("Risk: " if String(option.id)!="accept" else "Cost: ")+String(option.sub)
	return o

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var name:=String(audience.get("civ_name",_name(civ_id)))
	var day:=_day()
	var value:=float(p.get("value",1.0))
	# Bound since this envoy came (a demand of ours met first): nothing more.
	if is_tributary(civ_id) and option_id in ["accept","more"]: return {"outcome":"%s already bows to you." % name,"reaction":"neutral"}
	match option_id:
		"accept":
			var text:=_bind(civ_id,day,value,String(p.get("hostage","")),"")
			return {"outcome":text,"reaction":"neutral"}
		"more":
			var chance:=more_odds(civ_id)
			var roll:=_rng("more:%s:%d" % [civ_id,day]).randf()
			if roll<chance:
				var text2:=_bind(civ_id,day,value*2.0,String(p.get("hostage","")),"They bore your demand (%d in 100): " % roundi(chance*100.0))
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

## They become tributaries: the tribute agreement goes into the trade ledger
## (collected each season in their goods, like every people's tribute), the
## feud ends, and their raiders stay home while they pay.
static func _bind(civ_id:String,day:int,value:float,hostage:String,lead:String)->String:
	var name:=_name(civ_id)
	if is_tributary(civ_id): return "%s already bows to you." % name
	# Bowed, they lay down whatever spears they were gathering against us.
	(state().arming as Dictionary).erase(civ_id)
	Stances._begin_tribute(civ_id,"player",value,day)
	var agreement:=Stances.tribute(civ_id,"player")
	if not agreement.is_empty(): agreement["until"]=day+BOND_AHEAD
	state().tributaries[civ_id]={"since":day,"value":snappedf(value,0.1),"hostage":hostage.substr(0,80),"due":day+365,"years":0,"seen_paid":0.0,"hostage_id":_make_hostage(civ_id,hostage)}
	# Bowed, they are ours to protect (rival_rulers bonds): when their
	# neighbours raid them they call on us as kin do (kin_call), and a refusal
	# is remembered at the next reckoning.
	var rivals:=load(RIVALS_PATH) as GDScript
	if rivals!=null: rivals.call("bond",civ_id,"tributary","we bow to the god and pay its people tribute",day+BOND_AHEAD)
	var war:=load(WAR_PATH) as GDScript
	if war!=null and bool(war.call("feuding",civ_id,day)): war.call("_end_feud",civ_id,day,"submission","%s bowed to the god." % name)
	var index:=Hall._civ_index(civ_id)
	if index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[index].player_relation
		relation["stance"]="tributary"
	ForeignDiplomacy.remember(civ_id,"We bowed to the god and pay its people tribute.")
	_vow_undone(civ_id,day)
	_mark(civ_id,"bow",day)
	var text:="%s%s bows to the god. %s pays tribute worth %s every season, and %s lives among us as their pledge. Their raiders stay home while they pay." % [lead,name,name,_qty(value),hostage if hostage!="" else "a hostage"]
	_chronicle("bow:%s:%d" % [civ_id,day],"%s Bows to the God" % name,text,"moment",civ_id)
	_log(civ_id,"bow",text)
	return text

## The hostage lives among us as a person the court knows (court_persons.gd):
## the god can summon him by name, keep him, send him home or put him to
## death, and each is answered (hostage_judged). The id ("" if none).
static func _make_hostage(civ_id:String,words:String)->String:
	if words=="": return ""
	var persons:=load(PERSONS_PATH) as GDScript
	if persons==null: return ""
	var given:=words.get_slice(",",0).strip_edges()
	var p:Dictionary=persons.call("create",{"sex":"male","age":"young"})
	if p.is_empty(): return ""
	# Never the answer to "a young man": only his name or his people bring him.
	p["keys"]=["hostage:%s:%d" % [civ_id,_day()]]
	p["name"]=words.substr(0,80); p["given"]=given; p["family"]=""
	p["trade"]=""; p["role"]="hostage of the %s" % _name(civ_id); p["hostage_of"]=civ_id
	p["importance"]=8.0
	p["household"]={"spouse":{},"children":0}
	p["memories"]=[]
	p["memories"].append({"day":_day(),"text":"I am %s of the %s, given to the god's people as the pledge that my people will pay." % [words,_name(civ_id)]})
	return String(p.get("id",""))

## The god's word on a hostage before the court (court_persons._do_judge):
## put to death, the bond is broken and his people will have blood; sent home,
## a mercy they remember; harmed, a wrong they remember. The outcome, or ""
## when the act is the court's ordinary business (they keep him).
static func hostage_judged(p:Dictionary,action:String)->String:
	var civ_id:=String(p.get("hostage_of",""))
	if civ_id=="": return ""
	var name:=String(p.get("name","the hostage"))
	var given:=String(p.get("given",name))
	var people:=_name(civ_id)
	var day:=_day()
	var deeds:=load(DEEDS_PATH) as GDScript
	var t:=tributary(civ_id)
	# The court's own record of the act (divine_regard) is this same deed.
	deeds.call("told_as_foreign",String(p.get("name","")),day)
	match action:
		"execute":
			p["status"]="dead"; p["died_day"]=day
			deeds.call("record",civ_id,"slay_hostage",1,"the killing of %s, given to the god as a pledge" % given)
			deeds.call("record","home","strike_down",1,"%s, a hostage, put to death" % given)
			var broke:=""
			if not t.is_empty():
				_break_bond(civ_id,"the god put %s to death" % given)
				broke=" They will pay nothing more."
			var war:=load(WAR_PATH) as GDScript
			if war!=null and not bool(war.call("formal",civ_id)): war.call("blood_feud",civ_id,day,"the killing of their hostage %s" % given,"","hostage")
			var text:="%s was put to death before the court. %s gave him as a pledge; now they will have blood for him.%s" % [name,people,broke]
			_chronicle("hostage_killed:%s:%d" % [civ_id,day],"%s's Hostage Put to Death" % people,text,"moment",civ_id)
			_log(civ_id,"hostage_killed",text)
			ForeignDiplomacy.remember(civ_id,"The god killed %s, whom we gave as our pledge." % given)
			return text
		"exile","free","pardon":
			p["status"]="sent_home"
			deeds.call("amends",civ_id,"%s sent home by the god" % given)
			if not t.is_empty():
				t["hostage"]=""; t["hostage_id"]=""
			var text2:="%s was sent home to the %s. They will remember the mercy; %s" % [name,people,"the tribute stands while they still fear us." if not t.is_empty() else "nothing binds them to us now."]
			_chronicle("hostage_home:%s:%d" % [civ_id,day],"%s Goes Home" % given,text2,"notice",civ_id)
			_log(civ_id,"hostage_home",text2)
			ForeignDiplomacy.remember(civ_id,"The god sent %s home to us." % given)
			return text2
		"maim","curse","make_example","bind","terrify":
			deeds.call("record",civ_id,"harm_hostage",1,"what the god did to %s, their hostage" % given)
	return ""

## A tributary called on us against its enemy (rival_rulers kin_call; the
## hall's war_support): standing with it is the protection it pays for; staying
## out, or counselling peace, is remembered, and at the next reckoning it
## withholds its tribute (_tribute_due).
static func protection_answered(civ_id:String,enemy:String,option_id:String)->void:
	var t:=tributary(civ_id)
	if t.is_empty(): return
	if option_id=="stand":
		t.erase("refused_day"); t.erase("refused_against")
		_log(civ_id,"protected","We stood with %s against %s." % [_name(civ_id),_name(enemy)])
		return
	t["refused_day"]=_day()
	t["refused_against"]=_name(enemy).substr(0,60)
	_log(civ_id,"abandoned","We would not stand with %s against %s." % [_name(civ_id),_name(enemy)])

## The bond ends: the tribute agreement in the trade ledger is set down and
## they are tributaries no more.
static func _break_bond(civ_id:String,why:String)->void:
	var a:=state()
	var rivals:=load(RIVALS_PATH) as GDScript
	if rivals!=null: rivals.call("break_bond",civ_id,["tributary"])
	if (TradeLedger.state().tributes as Dictionary).has(Stances.skey(civ_id,"player")): (TradeLedger.state().tributes as Dictionary).erase(Stances.skey(civ_id,"player"))
	(a.tributaries as Dictionary).erase(civ_id)
	var index:=Hall._civ_index(civ_id)
	if index>=0: WorldSimulation.world.civilizations[index].player_relation["stance"]="hostile"
	_mark(civ_id,"broken",_day())
	_log(civ_id,"bond_broken",why)

## A year since they bowed or last weighed it: they keep paying while they
## still fear us and our spears still outmatch theirs, and their goods last
## (the trade ledger drops an agreement missed twice); otherwise they
## withhold it, the agreement ends and the bond is broken.
static func _tribute_due(civ_id:String,day:int)->void:
	var a:=state()
	var t:Dictionary=a.tributaries[civ_id]
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var name:=_name(civ_id)
	if civ.is_empty() or not bool(civ.get("alive",true)):
		(a.tributaries as Dictionary).erase(civ_id)
		return
	var r:=reading(civ_id)
	var agreement:=Stances.tribute(civ_id,"player")
	var abandoned:=day-int(t.get("refused_day",-99999))<=365
	if not agreement.is_empty() and float(r.fear)>=PAY_FEAR and float(r.ratio)>=PAY_RATIO and not abandoned:
		agreement["until"]=day+BOND_AHEAD
		var rivals:=load(RIVALS_PATH) as GDScript
		if rivals!=null:
			rivals.call("break_bond",civ_id,["tributary"])
			rivals.call("bond",civ_id,"tributary","we bow to the god and pay its people tribute",day+BOND_AHEAD)
		var paid:=float(agreement.get("paid",0.0))
		var this_year:=maxf(0.0,paid-float(t.get("seen_paid",0.0)))
		t["seen_paid"]=paid
		t["years"]=int(t.get("years",0))+1
		t["due"]=int(t.due)+365
		var first:=int(t.years)<=1
		_chronicle("tribute:%s:%d" % [civ_id,day],"%s Keeps Faith" % name,"%s still bows: tribute worth %s came this year, the %s year since it bowed." % [name,_qty(this_year),_nth(int(t.years))],"moment" if first else "notice",civ_id)
		return
	var why:="their goods ran out" if agreement.is_empty() else ("you would not protect them against %s" % String(t.get("refused_against","their enemies")) if abandoned else ("they no longer fear us enough" if float(r.fear)<PAY_FEAR else "their spears now match ours"))
	_break_bond(civ_id,why)
	_mark(civ_id,"withheld",day)
	var kept:=String(t.get("hostage",""))
	var text:="%s did not bring its tribute this year: %s. The bond is broken.%s" % [name,why,(" %s is still in our hands." % kept) if kept!="" else ""]
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
			if String(other)!=civ_id and free_to_come(String(other),day,true): with.append(String(other))
	var march:=day+_rng("arm:%s:%d" % [civ_id,day]).randi_range(ARMING_MIN,ARMING_MAX)
	# Whether our watchers hear of it now (standing.gd forewarn_odds, by our
	# cunning), or only in the last month before they march (_late_word).
	var standing:=load(STANDING_PATH) as GDScript
	var odds:=float(standing.call("forewarn_odds",float(standing.call("art_of","player","cunning")))) if standing!=null else 1.0
	var heard:=_rng("arm_heard:%s:%d" % [civ_id,day]).randf()<odds
	state().arming[civ_id]={"since":day,"march":march,"league":with,"cause":String(o.get("why_all_in","")).substr(0,160),"heard":heard,"heard_odds":snappedf(odds,0.01)}
	_mark(civ_id,"all_in",day)
	var name:=_name(civ_id)
	if not heard:
		_log(civ_id,"arming_unseen","%s began to gather every spear against us; our watchers did not see it." % name)
		return
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
	var name:=_name(civ_id)
	# A people organised for war (conflict_scale.gd) does not raid with
	# everything: it declares war, and its host and its generals take the field.
	if war!=null and bool(war.call("formal",civ_id)):
		if bool(war.call("declare",civ_id,day,"what they remember of us")):
			_log(civ_id,"war","%s went to war with everything it has." % name)
			_mark(civ_id,"all_in",day)
			(state().peoples[civ_id] as Dictionary)["came"]=day
		return
	var went:Array=[]
	for id in [civ_id]+(arm.get("league",[]) as Array):
		# Each is weighed again on the day: a member that has since bowed, made
		# peace or married into us stays home.
		if String(id)!=civ_id and not free_to_come(String(id),day,true): continue
		# A member organised for war declares war on us beside them.
		if String(id)!=civ_id and war!=null and bool(war.call("formal",String(id))):
			if bool(war.call("declare",String(id),day,"standing with %s against us" % name)): went.append(String(id))
			continue
		if _send_all(String(id),day): went.append(String(id))
	# Those who came are marked so: none comes with everything again for
	# ALL_IN_GAP, nor without a new wrong of ours since (monthly).
	for id in went:
		_mark(String(id),"all_in",day)
		(state().peoples[String(id)] as Dictionary)["came"]=day
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
			# Our town nearest them that they know (the council's own pick).
			var town:Dictionary=council.call("_punish_target","human",{})
			if town.is_empty():
				var towns:Array=council.call("known_towns","human")
				if towns.is_empty(): return false
				town=towns[0]
			var done:Dictionary=council.call("_launch","human",town,"punish",true,{"all":true})
			return String(done.get("verdict",""))=="act" or bool(done.get("live",false))))
	# A people the world does not simulate in full sends its counted fighters.
	if war==null: return false
	var result:Dictionary=war.call("_raid",civ_id,day,"everything",true,false)
	return not result.is_empty()
