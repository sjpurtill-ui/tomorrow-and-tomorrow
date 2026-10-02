extends RefCounted
## WHAT IS REMEMBERED: one ledger of the god's deeds, and who remembers them.
##
## Short memories already exist: a people's fresh dread of the god
## (divine_regard.civ_dread, halving in months) and the talk at our own
## hearths of the god's latest wrath (people_regard's echo, gone in a year).
## At the game's pace those are seconds of play. This is the long memory under
## them: what the god did, to whom, and how much of it is still told a
## generation on. A killed envoy, a town taken or burned, the dead of a feud,
## captives driven off; at home, officials put to death, curses and terrors,
## blessings. Each deed weighs on a view (foreign Fear and Resentment; our own
## people's Dread and Love) and fades with a half-life of a generation
## (GENERATION_DAYS), longer for a people that writes or prints
## (standing.memory_span). Word travels: every people we know fears us a little
## for what we did to others (WORD_SHARE), though only the wronged resent it.
##
## Weights add as chances do, not as sums (1-(1-a)(1-b)...), so many small
## deeds build to a reputation and none alone fills it. Amends (a blood price
## paid, a feud settled) carry negative resentment and are subtracted.
##
## Read by: court_lives.rival_dread (Fear), standing.view_of (Resentment),
## divine_regard.people_regard (our own people's Dread and Love), the Standing
## page ("What they remember of us"), world_answer.gd (what a people does about
## us). Written by: divine_regard._record_event (every act of the god in the
## hall), war_loop._tally/_exhaust (the dead of feuds and wars), town_fate
## (a held town's people put to the sword, its women violated), and the
## monthly look at towns taken or burned and captives driven off (monthly()).
##
## State lives in ForeignDiplomacy.audiences["deeds"] (saved with the court;
## older saves start with no memory). Static helpers; preload.

const VERSION:=1
## A generation: the half-life of a deed in an unlettered people's memory.
const GENERATION_DAYS:=25*365
## Share of a deed against another people that every people we know hears of
## and fears us for.
const WORD_SHARE:=0.3
## Below this a deed is no longer told.
const FORGOTTEN:=0.02
const MAX_DEEDS:=160
## Deeds of the same kind against the same people within this many days are
## told as one ("41 of theirs killed by our spears in the year of ...").
const MERGE_DAYS:=365

## Foreign deeds: [fear, resentment] each, per act (or per head for the
## counted kinds, see PER_HEAD). Home deeds: [dread, love].
const FOREIGN:={
	"slay_envoy":[0.10,0.15],"maim_envoy":[0.07,0.10],"shame_envoy":[0.03,0.05],"terrify_envoy":[0.03,0.02],
	"town_taken":[0.12,0.18],"town_burned":[0.16,0.22],
	"blood":[0.006,0.009],"blood_defending":[0.005,0.004],"captives":[0.003,0.006],
	"amends":[0.0,-0.12],
	"slay_hostage":[0.15,0.4],"harm_hostage":[0.04,0.12],
	# A held town's people put to the sword, or its women violated, at the
	# god's word (town_fate.gd): per head, the weightiest deeds of all.
	"massacre":[0.01,0.012],"violation":[0.004,0.012],
}
## Per-head kinds and the most one counted deed can weigh.
const PER_HEAD:={"blood":[0.25,0.35],"blood_defending":[0.2,0.15],"captives":[0.15,0.25],"massacre":[0.45,0.55],"violation":[0.2,0.45]}
const HOME:={
	"strike_down":[0.05,-0.02],"cast_out":[0.03,-0.01],"terrify":[0.015,0.0],"penance":[0.01,0.0],"flight":[0.02,0.0],
	"slay_envoy":[0.03,0.0],"maim_envoy":[0.02,0.0],"shame_envoy":[0.008,0.0],
	"bless":[0.0,0.01],"boon":[0.0,0.012],"raise_up":[0.0,0.01],
}
## The god's acts on the whole people (divine_regard.PEOPLE_ACTS) are kept at
## this share of their fresh weight.
const PEOPLE_ACT_SHARE:=0.8

static func _day()->int:
	return int(GameState.elapsed_days)

## Readings are asked many times a day (every view, every envoy weighed): each
## one is worked out once a day and kept until a deed is told or the day turns.
static var _cache:Dictionary={}
static var _cache_day:=-1
static var _cache_list:Variant=null
static func _cached(key:String)->Variant:
	var list:Variant=(ForeignDiplomacy.audiences.get("deeds",{}) as Dictionary).get("list") if ForeignDiplomacy.audiences.get("deeds") is Dictionary else null
	if _cache_day!=_day() or not is_same(_cache_list,list):
		_cache.clear(); _cache_day=_day(); _cache_list=list
	return _cache.get(key)
static func _keep(key:String,value:Variant)->Variant:
	_cache[key]=value
	return value
static func _told_changed()->void:
	_cache.clear()

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	var fresh:=not s.get("deeds") is Dictionary or int((s.deeds as Dictionary).get("version",0))!=VERSION
	if fresh: s["deeds"]={"version":VERSION,"list":[],"seen":{}}
	var d:Dictionary=s.deeds
	# An older save: the god's latest acts the court still talks of
	# (divine_regard's recent events) are the first deeds told.
	if fresh: _seed_from_recent()
	if not d.get("list") is Array: d["list"]=[]
	if not d.get("seen") is Dictionary: d["seen"]={}
	return d

static func _num(v:Variant)->bool:
	return (v is int or v is float) and is_finite(float(v))

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	if data.has("list"):
		if not data.list is Array or (data.list as Array).size()>MAX_DEEDS: return false
		for e in data.list:
			if not e is Dictionary or not _num(e.get("day")) or not e.get("kind") is String or not e.get("civ") is String: return false
			for k in ["a","b","n"]:
				if not _num(e.get(k,0)): return false
			if JSON.stringify(e).length()>600: return false
	if data.has("seen"):
		if not data.seen is Dictionary or (data.seen as Dictionary).size()>2000: return false
		for k in data.seen:
			if not k is String or not _num(data.seen[k]): return false
	return true

# --------------------------------------------------------------------------
# Writing
# --------------------------------------------------------------------------

## One deed. civ: the people it was done to ("home" for our own). kind: a key
## of FOREIGN or HOME (or a people act). n: heads, for the counted kinds.
## words: how it is told ("the killing of their envoy Solv").
static func record(civ:String,kind:String,n:int=1,words:String="",day:int=-1)->void:
	# The god's own ledger: a rival people's scope keeps no memory here.
	if civ=="" or n<=0 or String(WorldSimulation.actor_id)!="player": return
	if day<0: day=_day()
	var w:=_weights(civ,kind,n)
	if w.is_empty(): return
	var list:Array=state().list
	if PER_HEAD.has(kind):
		for e in list:
			if e is Dictionary and String(e.civ)==civ and String(e.kind)==kind and day-int(e.day)<=MERGE_DAYS:
				var total:=int(e.get("n",1))+n
				var merged:=_weights(civ,kind,total)
				e["n"]=total; e["a"]=merged[0]; e["b"]=merged[1]
				e["words"]=_counted_words(kind,total,civ)
				_told_changed()
				return
	if words=="" and PER_HEAD.has(kind): words=_counted_words(kind,n,civ)
	list.push_front({"day":day,"kind":kind.substr(0,32),"civ":civ.substr(0,64),"n":n,"a":w[0],"b":w[1],"words":words.substr(0,160)})
	_trim(list)
	_told_changed()

static func _weights(civ:String,kind:String,n:int)->Array:
	if civ=="home":
		if HOME.has(kind): return [float(HOME[kind][0]),float(HOME[kind][1])]
		var acts:Dictionary=(load("res://scripts/divine_regard.gd") as GDScript).get_script_constant_map().get("PEOPLE_ACTS",{})
		if acts.has(kind): return [float(acts[kind][0])*PEOPLE_ACT_SHARE,float(acts[kind][1])*PEOPLE_ACT_SHARE]
		return []
	if not FOREIGN.has(kind): return []
	var a:=float(FOREIGN[kind][0]); var b:=float(FOREIGN[kind][1])
	if PER_HEAD.has(kind):
		var cap:Array=PER_HEAD[kind]
		return [minf(float(cap[0]),a*float(n)),minf(float(cap[1]),b*float(n))]
	return [a,b]

static func _counted_words(kind:String,n:int,_civ:String)->String:
	var count:=preload("res://scripts/hud/era_words.gd").count_word(n)
	match kind:
		"blood": return "%s of theirs killed by our spears" % count
		"blood_defending": return "%s of their raiders killed at our hearths" % count
		"captives": return "%s of their people driven off as captives" % count
		"massacre": return "%s of their people put to the sword in towns we held" % count
		"violation": return "%s of their women violated by our garrisons" % count
	return ""

## The weakest of the forgotten go first, then the faintest.
static func _trim(list:Array)->void:
	var day:=_day()
	for e in list.duplicate():
		if e is Dictionary and _strength(e,day)<FORGOTTEN*0.5: list.erase(e)
	while list.size()>MAX_DEEDS:
		var weakest:Variant=null; var low:=INF
		for e in list:
			var s:=_strength(e,day)
			if s<low: low=s; weakest=e
		list.erase(weakest)

static func _seed_from_recent()->void:
	var holder:Variant=ForeignDiplomacy.audiences.get("divine")
	var events:Variant=(holder as Dictionary).get("events") if holder is Dictionary else null
	if not events is Array: return
	var list:Array=(events as Array).duplicate()
	list.reverse()
	for e in list:
		if e is Dictionary: from_divine(e)

## The god's acts in the hall (divine_regard._record_event): an official
## struck down or blessed, an envoy killed, the whole people cursed.
## The last envoy or hostage harmed: the court's own record of the same act
## (a strike_down or cast_out with no person of ours) is not told again.
static var _foreign_name:=""
static var _foreign_day:=-1
static func told_as_foreign(name:String,day:int)->void:
	_foreign_name=name; _foreign_day=day

static func from_divine(entry:Dictionary)->void:
	var action:=String(entry.get("action",""))
	var civ_id:=String(entry.get("civ_id",""))
	var name:=String(entry.get("name",""))
	var when:=int(entry.get("day",-1)) if _num(entry.get("day")) else -1
	if civ_id!="" and FOREIGN.has(action): told_as_foreign(name,when if when>=0 else _day())
	var given:=name.get_slice(" ",0)
	if civ_id!="" and FOREIGN.has(action):
		var noun:=String({"slay_envoy":"the killing","maim_envoy":"the maiming","shame_envoy":"the shaming","terrify_envoy":"the terrifying"}.get(action,"what was done to"))
		record(civ_id,action,1,"%s of their envoy %s" % [noun,given] if given!="" else "%s of their envoy" % noun,when)
	# The god's act on an envoy or a hostage is told once, as that deed; the
	# court's own record of it (no person of ours) is not told again. Anyone
	# else put to death or cast out before the court is told at home.
	if action in ["strike_down","cast_out","terrify"] and int(entry.get("person_id",0))<=0 and name==_foreign_name and (when if when>=0 else _day())==_foreign_day: return
	var home_words:=""
	match action:
		"strike_down": home_words="%s put to death before the court" % given
		"cast_out": home_words="%s cast out" % given
		"terrify": home_words="the god's fury at %s" % given
		"penance": home_words="the penance laid on %s" % given
		"flight": home_words="%s fled the god's reach" % given
		"slay_envoy": home_words="a guest killed in the god's hall"
		"maim_envoy": home_words="a guest maimed in the god's hall"
		"shame_envoy": home_words="a guest shamed in the god's hall"
		"bless": home_words="the god's blessing on %s" % given
		"boon": home_words="the god's gift to %s" % given
		"raise_up": home_words="%s raised above the others" % given
		"terrify_people": home_words="the day the god terrified the people"
		"curse_people": home_words="the god's curse on the people"
		"harsh_law": home_words="a hard law of the god's"
		"bless_people": home_words="the god's blessing on the people"
		"bless_fields": home_words="the god's blessing on the fields"
	if home_words=="" and (load("res://scripts/divine_regard.gd") as GDScript).get_script_constant_map().get("PEOPLE_ACTS",{}).has(action): home_words=action.replace("_"," ")
	if home_words!="": record("home",action,1,home_words,when)

## The dead of a feud or a war, by our hand: our raiders' and our watch's.
static func blood(civ_id:String,their_dead:int,defending:bool)->void:
	if civ_id=="" or civ_id=="player" or their_dead<=0: return
	record(civ_id,"blood_defending" if defending else "blood",their_dead)

## A blood price paid or a feud set down: amends that ease their resentment.
static func amends(civ_id:String,words:String)->void:
	if civ_id=="" or civ_id=="player": return
	record(civ_id,"amends",1,words)

## Once a month: towns of theirs we took or burned, and captives driven off,
## counted once each (seen keys).
static func monthly(day:int)->void:
	if String(WorldSimulation.actor_id)!="player" or WorldSimulation.world==null: return
	var aftermath:=load("res://scripts/envoy_aftermath.gd") as GDScript
	if aftermath==null: return
	var seen:Dictionary=state().seen
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary: continue
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player": continue
		var relation:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(relation.get("contact_level",0))<=0: continue
		var st:Dictionary=aftermath.call("standing",id)
		for town:Dictionary in st.get("held",[]):
			var key:="town:%s:%s" % [id,String(town.get("id",""))]
			if seen.has(key): continue
			seen[key]=day
			record(id,"town_taken",1,"the taking of %s" % String(town.get("name","their town")),_changed_hands(civ,String(town.get("id","")),day))
		for town_name in st.get("burned",[]):
			var key2:="burn:%s:%s" % [id,String(town_name)]
			if seen.has(key2): continue
			seen[key2]=day
			record(id,"town_burned",1,"the burning of %s" % String(town_name),_changed_hands(civ,"",day,String(town_name)))
		# Each party of captives driven off is told once, by its own record
		# (occupation_transfers), never read again from our own head count.
		var mc:Variant=WorldSimulation.military
		if mc!=null and "occupation_transfers" in mc and mc.occupation_transfers!=null:
			for t:Dictionary in mc.occupation_transfers.data.transfers:
				if String(t.get("source",""))!=id or String(t.get("status",""))=="citizen": continue
				var tkey:="captives:%s:%d" % [id,int(t.get("id",-1))]
				if seen.has(tkey): continue
				seen[tkey]=day
				record(id,"captives",int(t.get("people",0)),"",int(t.get("depart_day",day)))
	while seen.size()>1800: seen.erase(seen.keys()[0])
	_trim(state().list)
	_told_changed()

## The day a town of theirs changed hands (its region's record), else today.
static func _changed_hands(civ:Dictionary,region_id:String,day:int,name:String="")->int:
	for r in civ.get("strategic_regions",[]):
		if not r is Dictionary: continue
		if (region_id!="" and String((r as Dictionary).get("id",""))==region_id) or (name!="" and String((r as Dictionary).get("name",""))==name):
			var changed:=int((r as Dictionary).get("last_control_change_day",0))
			return changed if changed>0 and changed<=day else day
	return day

# --------------------------------------------------------------------------
# Reading
# --------------------------------------------------------------------------

static func half_life(civ:String)->float:
	var span:=1.0
	var standing:=load("res://scripts/standing.gd") as GDScript
	if standing!=null: span=float(standing.call("memory_span","player" if civ=="home" else civ))
	return float(GENERATION_DAYS)*maxf(1.0,span)

static func _strength(e:Dictionary,day:int,life:float=float(GENERATION_DAYS))->float:
	return maxf(absf(float(e.get("a",0.0))),absf(float(e.get("b",0.0))))*pow(0.5,maxf(0.0,float(day-int(e.get("day",day))))/life)

## {a, b} for one people: a = Fear (Dread at home), b = Resentment (Love at
## home), each 0..1, from every deed still told.
static func _sum(civ:String,word:bool)->Dictionary:
	var day:=_day()
	var life:=half_life(civ)
	var keep_a:=1.0; var keep_b:=1.0; var minus_b:=0.0
	var heard:=1.0
	for e in state().list:
		if not e is Dictionary: continue
		var fade:=pow(0.5,maxf(0.0,float(day-int(e.day)))/life)
		var a:=float(e.get("a",0.0))*fade; var b:=float(e.get("b",0.0))*fade
		if String(e.civ)==civ:
			keep_a*=1.0-clampf(a,0.0,0.95)
			if b>=0.0: keep_b*=1.0-clampf(b,0.0,0.95)
			else: minus_b+=-b
		elif word and civ!="home" and String(e.civ)!="home":
			heard*=1.0-clampf(a*WORD_SHARE,0.0,0.95)
	var a_total:=1.0-keep_a*heard
	return {"a":clampf(a_total,0.0,1.0),"b":clampf(1.0-keep_b-minus_b,0.0,1.0)}

## How much this people fears us for what it remembers we did (to them, and
## a share for what we did to others).
static func fear(civ_id:String)->float:
	if civ_id=="" or civ_id=="player" or civ_id=="home": return 0.0
	var got:Variant=_cached("fear:"+civ_id)
	if got!=null: return float(got)
	return float(_keep("fear:"+civ_id,float(_sum(civ_id,true).a)))

## How much this people resents us for what we did to it.
static func resentment(civ_id:String)->float:
	if civ_id=="" or civ_id=="player" or civ_id=="home": return 0.0
	var got:Variant=_cached("res:"+civ_id)
	if got!=null: return float(got)
	return float(_keep("res:"+civ_id,float(_sum(civ_id,false).b)))

## Our own people's long memory of the god: {dread, love}.
static func home()->Dictionary:
	var got:Variant=_cached("home")
	if got is Dictionary: return (got as Dictionary).duplicate()
	return (_keep("home",_home()) as Dictionary).duplicate()

static func _home()->Dictionary:
	var s:=_sum("home",false)
	# Love is told the same way as dread: every remembered kindness adds, and
	# a cruelty (a curse, a killing) takes some away.
	var day:=_day(); var life:=half_life("home"); var keep:=1.0; var minus:=0.0
	for e in state().list:
		if not e is Dictionary or String(e.civ)!="home": continue
		var b:=float(e.get("b",0.0))*pow(0.5,maxf(0.0,float(day-int(e.day)))/life)
		if b>=0.0: keep*=1.0-clampf(b,0.0,0.95)
		else: minus+=-b
	var love:=clampf(1.0-keep,0.0,1.0)-minus
	return {"dread":float(s.a),"love":clampf(love,-1.0,1.0)}

## What one people still tells of us, the weightiest first:
## [{words, day, year, now, years_left, tone ("dread"|"amends"|"love")}].
static func remembered(civ:String,limit:int=4)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var day:=_day()
	var life:=half_life(civ)
	for e in state().list:
		if not e is Dictionary or String(e.civ)!=civ: continue
		var now:=_strength(e,day,life)
		if now<FORGOTTEN: continue
		var years_left:=maxi(1,roundi(life*log(now/FORGOTTEN)/log(2.0)/365.0))
		var tone:="dread"
		if float(e.get("b",0.0))<0.0: tone="amends"
		elif civ=="home" and float(e.get("b",0.0))>float(e.get("a",0.0)): tone="love"
		out.append({"words":String(e.get("words","")),"day":int(e.day),"year":floori(float(e.day)/365.0),"now":now,"years_left":years_left,"tone":tone,"kind":String(e.kind)})
	out.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.now)>float(y.now))
	return out.slice(0,limit)

## "remembered for about 30 more years"
static func years_words(years:int)->String:
	if years<=1: return "fading this year"
	if years<5: return "told a few more years"
	return "told for about %d more years" % (roundi(float(years)/5.0)*5)
