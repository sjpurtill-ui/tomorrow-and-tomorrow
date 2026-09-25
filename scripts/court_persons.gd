extends RefCounted
## Court-known persons: anyone the god asks about or calls before them.
##
## The engine counts people in aggregate. When the god asks the court about
## someone ("who is responsible for this?", "tell me of the potters") an
## official answers with a person, and that person is resolved here: an
## official, a war leader or master builder, a remembered commoner, or a new
## commoner created on the spot from the actual population, settlement, era and
## event. Created people are kept as a small bounded registry (saved with the
## audience-hall payload), so asking again or summoning again returns the same
## person. They stay drawn from the aggregate: killing one removes one person
## from the population; raising one to office admits them through
## GovernmentPeopleSystem's appointment rules.
##
## Blame is attributed with a hidden truth record: who really was responsible,
## who was named, and whether the answering official lied (their own guilt or
## a kinsman's, their honesty, love and dread of the god, their stakes). A lie
## names a real or newly created scapegoat and leaves one or two tells that are
## grounded in state (the office's charge, the scapegoat's absence, the tally
## of the stores, an honest person's unease). The player can question the
## summoned, confront the liar, and judge; every outcome is decided here first
## and applied through the real systems. The voice (offline banks, learned
## templates or the live model) only describes what was decided.
##
## One resolution core serves both modes: offline, the Court shows choices from
## choices(); online, the live model maps typed words onto the same action
## vocabulary (menu()) and perform() applies it. Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DV:=preload("res://scripts/divine_voice.gd")
const Notables:=preload("res://scripts/village_notables.gd")
const Lines:=preload("res://scripts/court_persons_lines.gd")

const KEY:="court_persons"
const VERSION:=1
const MAX_PEOPLE:=48
const MAX_TRUTH:=40
const MAX_MEMORIES:=8
const MAX_GROUP:=40
const MAX_GROUP_DEATHS:=12
const WAITING_CAP:=10

## The shared action vocabulary. Offline choices and the live model's
## canonical_action both name one of these (or "novel:<slug>").
const ASK:=["ask_blame","ask_about","seek"]
const QUESTION:=["q_where","q_did","q_swear","q_who_else","q_mercy","q_threaten"]
const CONFRONT:=["accuse_lie","accuse_record","bring_ledger"]
const JUDGE:=["exalt","reward","pardon","exile","execute","maim","curse","make_priest","make_official","marry_off","make_example"]
const OTHER:=["summon","talk"]
const LABELS:={"ask_blame":"Who is responsible for this?","ask_about":"Tell me of…","seek":"Have them sought out","summon":"Summon them",
	"q_where":"Where were you?","q_did":"Did you do this?","q_swear":"Swear it before me","q_who_else":"Who else knows?","q_mercy":"Show mercy","q_threaten":"Threaten",
	"accuse_lie":"You are lying","accuse_record":"The records say otherwise","bring_ledger":"Bring the ledger",
	"exalt":"Exalt","reward":"Reward","pardon":"Pardon","exile":"Exile","execute":"Execute","maim":"Maim","curse":"Curse",
	"make_priest":"Make priest","make_official":"Make official","marry_off":"Marry off","make_example":"Make an example","talk":"Speak with them"}

## Trades, gated by what the people know (character_voice era gates).
const TRADES:={
	"gatherer":{"label":"gatherer","plural":"gatherers","gate":""},
	"hunter":{"label":"hunter","plural":"hunters","gate":""},
	"fisher":{"label":"fisher","plural":"fishers","gate":""},
	"flint-knapper":{"label":"flint-knapper","plural":"flint-knappers","gate":""},
	"hide-scraper":{"label":"hide-scraper","plural":"hide-scrapers","gate":""},
	"fire-keeper":{"label":"fire-keeper","plural":"fire-keepers","gate":""},
	"storekeeper":{"label":"store-keeper","plural":"store-keepers","gate":""},
	"builder":{"label":"builder","plural":"builders","gate":""},
	"tracker":{"label":"tracker","plural":"trackers","gate":""},
	"scout":{"label":"scout","plural":"scouts","gate":""},
	"warrior":{"label":"spear-carrier","plural":"spear-carriers","gate":""},
	"watchman":{"label":"night watcher","plural":"night watchers","gate":""},
	"healer":{"label":"herb-finder","plural":"herb-finders","gate":""},
	"water-carrier":{"label":"water-carrier","plural":"water-carriers","gate":""},
	"reed-weaver":{"label":"reed-weaver","plural":"reed-weavers","gate":""},
	"potter":{"label":"potter","plural":"potters","gate":"pottery"},
	"farmer":{"label":"farmer","plural":"farmers","gate":"farming"},
	"herder":{"label":"herder","plural":"herders","gate":"dairy"},
	"weaver":{"label":"weaver","plural":"weavers","gate":"weaving"},
	"mason":{"label":"mason","plural":"masons","gate":"masonry"},
	"smith":{"label":"smith","plural":"smiths","gate":"metal"},
	"boatman":{"label":"boatman","plural":"boatmen","gate":"boats"},
}
const KIN_RELATIONS:={"male":["son","nephew","brother","cousin"],"female":["daughter","niece","sister","cousin"]}
const TEMPERS:=["quiet and watchful","hot-tempered","sly","cheerful","stubborn","proud","timid","earnest","sullen","talkative"]
const DETAILS:=["is missing two fingers of the left hand","has a laugh you hear across the whole camp","walks with a limp from an old fall","wears a string of fish-bone beads","has burn scars along both forearms","hums while working","has one grey eye and one brown","is never seen without a bone awl at the belt",
	"keeps a tame crow","has hands stained dark to the wrist","is the first awake at every fire","tells long stories about the old winters"]
const ALIBI_PLACES:=["gathering reeds in the far marsh","hunting in the eastern hills","out at the salt flats","tending a sick mother across the river","cutting timber in the high woods","netting fish at the lower falls"]
const EVENT_KINDS:=[
	{"id":"discovery","words":["discover","learned","invent","new way","knowledge","found how"],"offices":["Scholar","Steward"],"trades":["gatherer","flint-knapper","potter","farmer","healer"],"kind":"credit"},
	{"id":"victory","words":["victory","won ","triumph","completed","finished","dedicated","raised the"],"offices":["Marshal","Steward"],"trades":["warrior","builder"],"kind":"credit"},
	{"id":"stores","words":["granary","store","spoil","famine","hunger","starv","food","harvest","rot","larder","ration"],"offices":["Quartermaster","Steward"],"trades":["storekeeper","gatherer","farmer"],"kind":"misfortune"},
	{"id":"war","words":["battle","raid","defeat","attack","war","siege","slain","ambush"],"offices":["Marshal"],"trades":["warrior","watchman"],"kind":"misfortune"},
	{"id":"scouts","words":["scout","expedition","caravan","lost","missing","party","envoy"],"offices":["ChiefScout","Envoy"],"trades":["scout","tracker"],"kind":"misfortune"},
	{"id":"sickness","words":["sick","fever","plague","illness","disease","health","died"],"offices":["Steward","Scholar"],"trades":["healer","water-carrier"],"kind":"misfortune"},
	{"id":"works","words":["collapse","fire","flood","burn","wall","roof","fell","broke","shelter"],"offices":["Steward","Quartermaster"],"trades":["builder","fire-keeper","mason"],"kind":"misfortune"},
]
const OFFICE_CHARGE:={"Quartermaster":"the stores","Steward":"the hearths and the stores","Marshal":"the watch and the spears","ChiefScout":"the scouting parties","Scholar":"the lore","Envoy":"the messengers"}

## Tests may pin the hidden draw: {"culprit":"holder"|"kin"|"commoner", "lie":bool}.
static var force:Dictionary={}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var audiences:Dictionary=ForeignDiplomacy.audiences
	if not audiences.get(KEY) is Dictionary: audiences[KEY]={}
	var s:Dictionary=audiences[KEY]
	if not s.get("people") is Array: s["people"]=[]
	if not s.get("truth") is Array: s["truth"]=[]
	if not s.get("focus") is Dictionary: s["focus"]={}
	if not (s.get("serial") is int or s.get("serial") is float): s["serial"]=0
	s["version"]=VERSION
	return s

static func people()->Array:
	return state().people

static func truth_records()->Array:
	return state().truth

static func by_id(id:String)->Dictionary:
	for p in people():
		if p is Dictionary and String((p as Dictionary).get("id",""))==id: return p
	return {}

static func record(id:String)->Dictionary:
	for r in truth_records():
		if r is Dictionary and String((r as Dictionary).get("id",""))==id: return r
	return {}

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if not d.get("people",[]) is Array or (d.get("people",[]) as Array).size()>MAX_PEOPLE*2: return false
	if not d.get("truth",[]) is Array or (d.get("truth",[]) as Array).size()>MAX_TRUTH*2: return false
	for p in d.get("people",[]):
		if not p is Dictionary or not (p as Dictionary).get("id","") is String or not (p as Dictionary).get("name","") is String: return false
		if JSON.stringify(p).length()>8000: return false
	for r in d.get("truth",[]):
		if not r is Dictionary or not (r as Dictionary).get("id","") is String or JSON.stringify(r).length()>8000: return false
	return true

static func _day()->int:
	return int(GameState.elapsed_days)

static func _roll(key:String)->float:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|court_persons|%s" % [int(GameState.world_seed),key])
	return rng.randf()

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|court_persons|%s" % [int(GameState.world_seed),key])
	return rng

static func tags()->Array:
	return CV.era_tags("player")

static func era_tier()->int:
	return CV.era_tier(tags())

static func trade_ok(trade:String)->bool:
	var spec:Dictionary=TRADES.get(trade,{})
	if spec.is_empty(): return false
	var gate:=String(spec.get("gate",""))
	return gate=="" or tags().has(gate)

static func trade_label(trade:String,plural:bool=false)->String:
	var spec:Dictionary=TRADES.get(trade,{})
	if spec.is_empty(): return trade
	return String(spec.get("plural" if plural else "label",trade))

static func _fit_trade(wanted:Array)->String:
	for t in wanted:
		if trade_ok(String(t)): return String(t)
	return "gatherer"

# --------------------------------------------------------------------------
# References: {"kind":"known","id"} | {"kind":"official","pid"} | {"kind":"figure","id"}
# --------------------------------------------------------------------------

static func ref_of(p:Dictionary)->Dictionary:
	return {"kind":"known","id":String(p.get("id",""))}

static func ref_key(ref:Dictionary)->String:
	match String(ref.get("kind","")):
		"known": return "known:"+String(ref.get("id",""))
		"official": return "person:%d" % int(ref.get("pid",0))
		"figure": return "figure:"+String(ref.get("id",""))
	return ""

static func ref_name(ref:Dictionary)->String:
	match String(ref.get("kind","")):
		"known": return String(by_id(String(ref.get("id",""))).get("name",""))
		"official": return String(GovernmentPeopleSystem.person_snapshot(int(ref.get("pid",0))).get("name",""))
		"figure": return String(HistoricalFigures.by_id(String(ref.get("id",""))).get("name",""))
	return ""

static func ref_alive(ref:Dictionary)->bool:
	match String(ref.get("kind","")):
		"known": return String(by_id(String(ref.get("id",""))).get("status",""))=="living"
		"official": return String(GovernmentPeopleSystem.person_snapshot(int(ref.get("pid",0))).get("status",""))=="active"
		"figure": return String(HistoricalFigures.by_id(String(ref.get("id",""))).get("status","dead")) in ["living","wounded"]
	return false

static func same_ref(a:Dictionary,b:Dictionary)->bool:
	return not a.is_empty() and ref_key(a)==ref_key(b)

# --------------------------------------------------------------------------
# Identity: created from the real population, settlement, era and event
# --------------------------------------------------------------------------

static func _settlement(sid:String)->Dictionary:
	for s in GameState.player_settlements:
		if s is Dictionary and String((s as Dictionary).get("id",""))==sid: return s
	return (GameState.player_settlements[0] as Dictionary) if not GameState.player_settlements.is_empty() else {}

static func _settlement_name(sid:String)->String:
	var s:=_settlement(sid)
	var n:=String(s.get("name",""))
	if n=="": n=String(GameState.settlement_name)
	return n if n!="" else "the home camp"

static func _used_names()->Dictionary:
	var used:Dictionary={}
	for p in people(): used[String((p as Dictionary).get("name",""))]=true
	for p in GovernmentPeopleSystem.people: used[String((p as Dictionary).get("name",""))]=true
	return used

static func _name_for(sex:String,rng:RandomNumberGenerator,family:String="")->Dictionary:
	var pool:Array=Notables.MEN if sex=="male" else Notables.WOMEN
	var families:Array=[]
	for f in GovernmentPeopleSystem.FAMILY_NAMES:
		if CV.permits(String(f),tags()) and String(f).length()<=9: families.append(String(f))
	var used:=_used_names()
	for attempt in 60:
		var given:=String(pool[rng.randi_range(0,pool.size()-1)])
		var fam:=family if family!="" else String(families[rng.randi_range(0,families.size()-1)])
		var full:="%s %s" % [given,fam]
		if not used.has(full): return {"given":given,"family":fam,"name":full}
	var given2:=String(pool[rng.randi_range(0,pool.size()-1)])
	return {"given":given2,"family":"of %s" % _settlement_name(""),"name":"%s of %s" % [given2,_settlement_name("")]}

static func desc_key(desc:Dictionary)->String:
	return "%s|%s|%s|%s|%s|%s|%s" % [String(desc.get("trade","")),String(desc.get("sex","")),String(desc.get("age","")),String(desc.get("settlement_id","")),
		String(desc.get("quality","")),String(desc.get("deed","")).to_lower().substr(0,40),"g" if int(desc.get("count",1))>1 else "1"]

static func find_or_create(desc:Dictionary)->Dictionary:
	## The person a description names: the remembered one (alive) whose keys
	## match, else a new one. Re-asking returns the same person.
	var key:=desc_key(desc)
	for p in people():
		var rec:Dictionary=p
		if (rec.get("keys",[]) as Array).has(key) and String(rec.get("status",""))=="living": return rec
	return create(desc,key)

static func create(desc:Dictionary,key:String="")->Dictionary:
	var s:=state()
	s.serial=int(s.serial)+1
	var serial:=int(s.serial)
	if key=="": key=desc_key(desc)
	var rng:=_rng("create|%s|%d" % [key,serial])
	var sex:=String(desc.get("sex",""))
	if not sex in ["male","female"]: sex="male" if rng.randf()<0.5 else "female"
	var trade:=String(desc.get("trade",""))
	if not trade_ok(trade): trade=_fit_trade(["gatherer","hunter","fisher"]) if trade=="" else _fit_trade([trade,"gatherer"])
	var age_band:=String(desc.get("age",""))
	var age:=rng.randi_range(22,46)
	match age_band:
		"child": age=rng.randi_range(7,12)
		"young": age=rng.randi_range(15,21)
		"old": age=rng.randi_range(55,64)
		"oldest": age=rng.randi_range(66,74)
	var sid:=String(desc.get("settlement_id",""))
	if sid=="" or _settlement(sid).is_empty(): sid=String(_settlement("").get("id",""))
	var kin_of:Dictionary=desc.get("kin_of",{}) if desc.get("kin_of") is Dictionary else {}
	var family:=""
	if not kin_of.is_empty(): family=String(GovernmentPeopleSystem.person_snapshot(int(kin_of.get("pid",0))).get("name","")).get_slice(" ",1)
	var n:=_name_for(sex,rng,family)
	var children:=0
	if age>=20: children=clampi(roundi((float(age)-19.0)*0.18*rng.randf_range(0.5,1.3)),0,7)
	var spouse:={}
	if age>=18 and rng.randf()<0.7:
		var sp:=_name_for("female" if sex=="male" else "male",rng,String(n.family))
		spouse={"name":String(sp.given),"alive":not bool(desc.get("widow",false))}
	if bool(desc.get("widow",false)) and spouse.is_empty(): spouse={"name":String(_name_for("male" if sex=="female" else "female",rng,String(n.family)).given),"alive":false}
	var p:={
		"id":"cp_%d" % serial,"name":String(n.name),"given":String(n.given),"family":String(n.family),"sex":sex,
		"born_day":_day()-age*365-rng.randi_range(0,300),"trade":trade,"settlement_id":sid,"village":_settlement_name(sid),
		"temper":String(TEMPERS[rng.randi_range(0,TEMPERS.size()-1)]),"detail":String(DETAILS[rng.randi_range(0,DETAILS.size()-1)]),
		"courage":snappedf(rng.randf_range(0.2,0.85),0.01),"honesty":snappedf(rng.randf_range(0.3,0.95),0.01),"pride":snappedf(rng.randf_range(0.15,0.85),0.01),
		"love":snappedf(clampf(_people_love()+rng.randf_range(-0.15,0.15),0.05,0.95),0.01),"dread":snappedf(clampf(_people_dread()+rng.randf_range(-0.1,0.15),0.02,0.9),0.01),
		"household":{"spouse":spouse,"children":children},"status":"living","role":"","keys":[key],"memories":[],"records":[],
		"importance":1.0,"created_day":_day(),"last_seen_day":_day(),"count":1,"voice_model":"",
	}
	if age_band=="child": p.household={"spouse":{},"children":0,"parents":String(_name_for("female",rng,String(n.family)).given)}
	if not kin_of.is_empty(): p["kin_of"]=kin_of.duplicate()
	var count:=int(desc.get("count",1))
	if count>1:
		p["count"]=clampi(count,2,mini(MAX_GROUP,maxi(2,roundi(float(GameState.population_total)*0.06))))
		p["group"]=trade_label(trade,true)
	if String(desc.get("quality",""))!="": p["excels"]=String(desc.quality)
	if String(desc.get("deed",""))!="": _remember(p,"I %s." % String(desc.deed).substr(0,120))
	if String(desc.get("note",""))!="": _remember(p,String(desc.note))
	# A memory consistent with the settlement's real condition.
	var food:=float(GameState.simulation_metrics.get("food_days",30.0))
	_remember(p,"The stores have been lean at our hearth this season." if food<16.0 else "We have eaten well enough this year at %s." % String(p.village))
	p["voice_model"]=String(persona(p).get("model",""))
	(s.people as Array).append(p)
	_evict()
	return p

static func _people_love()->float:
	return float(DIVINE.people_regard(Hall._officials()).get("love",0.5))

static func _people_dread()->float:
	return float(DIVINE.people_regard(Hall._officials()).get("dread",0.2))

static func age_of(p:Dictionary)->int:
	return maxi(0,floori(float(_day()-int(p.get("born_day",_day())))/365.0))

static func _remember(p:Dictionary,text:String)->void:
	var mem:Array=p.get("memories",[]) if p.get("memories") is Array else []
	mem.append({"day":_day(),"text":text.substr(0,200)})
	while mem.size()>MAX_MEMORIES: mem.pop_front()
	p["memories"]=mem

static func _importance(p:Dictionary,add:float)->void:
	p["importance"]=float(p.get("importance",1.0))+add
	p["last_seen_day"]=_day()

static func _evict()->void:
	## Bounded: the dead and the unimportant go first; never someone a live
	## truth record or a waiting audience still needs.
	var list:Array=people()
	var guard:=0
	while list.size()>MAX_PEOPLE and guard<MAX_PEOPLE:
		guard+=1
		var needed:Dictionary={}
		for r in truth_records():
			for k in ["true_party","named","scapegoat"]:
				var ref:Dictionary=(r as Dictionary).get(k,{}) if (r as Dictionary).get(k) is Dictionary else {}
				if String(ref.get("kind",""))=="known": needed[String(ref.get("id",""))]=true
		for a in Hall.waiting():
			var kid:=String(((a as Dictionary).get("speaker",{}) as Dictionary).get("known_id",""))
			if kid!="": needed[kid]=true
		var worst:=-1
		var worst_score:=INF
		for i in list.size():
			var p:Dictionary=list[i]
			if needed.has(String(p.get("id",""))): continue
			var score:=float(p.get("importance",1.0))+float(p.get("last_seen_day",0))/3650.0
			if String(p.get("status",""))!="living": score-=5.0
			if score<worst_score: worst_score=score; worst=i
		if worst<0: break
		list.remove_at(worst)

# --------------------------------------------------------------------------
# Persona: one voice model for life
# --------------------------------------------------------------------------

static func persona(p:Dictionary)->Dictionary:
	var who:="known:"+String(p.get("id",""))
	var registry:Dictionary=CV.registry
	var models:Dictionary=registry.get("models",{}) if registry.get("models") is Dictionary else {}
	if String(p.get("voice_model",""))!="": models[who]=String(p.voice_model)
	registry["models"]=models
	CV.registry=registry
	var person:={"person_id":0,"name":String(p.get("name","")),"traits":[],"courage":float(p.get("courage",0.5)),"honesty":float(p.get("honesty",0.5)),"pride":float(p.get("pride",0.5)),
		"personality":{"assertiveness":clampf(float(p.get("pride",0.5))+0.1,0.0,1.0),"empathy":clampf(float(p.get("honesty",0.5)),0.0,1.0),"openness":0.5,"discipline":0.5,"risk_tolerance":float(p.get("courage",0.5))},
		"office_title":title_of(p)}
	var persona_out:=CV.for_person(person)
	var reg:Dictionary=CV.registry
	for k in ["models","addresses"]:
		if reg.get(k) is Dictionary: (reg[k] as Dictionary).erase("person:0")
	# for_person keys by person id; re-key the manner to this person for life.
	var stance:=String(persona_out.get("stance","pragmatic"))
	persona_out["model_rank"]=CV.rank_models(CV._features_from(person),stance,who)
	CV._lifelong(persona_out,who)
	persona_out["key"]="envoy"
	persona_out["name"]=String(p.get("name",""))
	persona_out["title"]=title_of(p)
	persona_out["known_id"]=String(p.get("id",""))
	return persona_out

static func title_of(p:Dictionary)->String:
	if int(p.get("count",1))>1: return "for the %d %s" % [int(p.count),String(p.get("group",trade_label(String(p.get("trade","")),true)))]
	var role:=String(p.get("role",""))
	if role!="": return role
	var age:=age_of(p)
	if age<13: return "a child of %s" % String(p.get("village",""))
	return "%s of %s" % [trade_label(String(p.get("trade",""))),String(p.get("village",""))]

static func view(p:Dictionary)->Dictionary:
	## What may be said of them aloud (never the hidden truth).
	var hh:Dictionary=p.get("household",{}) if p.get("household") is Dictionary else {}
	var sp:Dictionary=hh.get("spouse",{}) if hh.get("spouse") is Dictionary else {}
	var mems:Array=[]
	for m in p.get("memories",[]): mems.append(String((m as Dictionary).get("text","")))
	return {"name":String(p.get("name","")),"sex":String(p.get("sex","")),"age":age_of(p),"trade":trade_label(String(p.get("trade",""))),"village":String(p.get("village","")),
		"temper":String(p.get("temper","")),"detail":String(p.get("detail","")),"spouse":String(sp.get("name","")),"spouse_alive":bool(sp.get("alive",true)),
		"children":int(hh.get("children",0)),"status":String(p.get("status","")),"role":String(p.get("role","")),"count":int(p.get("count",1)),"memories":mems}

# --------------------------------------------------------------------------
# Events ("this") and categories ("tell me of…")
# --------------------------------------------------------------------------

static func _classify_event(text:String)->Dictionary:
	var low:=text.to_lower()
	for k in EVENT_KINDS:
		for w in (k as Dictionary).words:
			if String(w) in low: return k
	return EVENT_KINDS[4]

static func recent_events(limit:int=5,audience_id:String="")->Array[Dictionary]:
	## Significant events the ruler may ask about, newest first: the matter at
	## hand in this audience, then the realm's recent notices and discoveries.
	var out:Array[Dictionary]=[]
	var seen:Dictionary={}
	var day:=_day()
	if audience_id!="":
		var a:=Hall.find(audience_id)
		var topic:=String((a.get("petition",{}) as Dictionary).get("topic",""))
		if topic in ["food","health","housing","security","war"]:
			var words:=String({"food":"the stores ran low","health":"the sickness spread at the hearths","housing":"the people went without shelter","security":"the watch failed","war":"the war came on us"}.get(topic,""))
			var e:=_event_entry("aud:%s:%d" % [topic,floori(float(int(a.get("arrived_day",day)))/30.0)],words,int(a.get("arrived_day",day)),String((a.get("petition",{}) as Dictionary).get("summary",words)))
			out.append(e); seen[e.key]=true
	for ev in GameState.simulation_events:
		if not ev is Dictionary: continue
		var d:Dictionary=ev
		if day-int(d.get("day",day))>365: continue
		if String(d.get("severity",""))=="minor": continue
		var title:=String(d.get("title",""))
		if title=="" or title in ["Officeholder Dismissed","Leader Dismissed","Official Appointed"]: continue
		var e2:=_event_entry("sim:%d:%d" % [int(d.get("day",0)),absi(hash(title))%100000],title.to_lower(),int(d.get("day",day)),String(d.get("description",title)))
		if seen.has(e2.key): continue
		out.append(e2); seen[e2.key]=true
		if out.size()>=limit: return out
	for ev in GameState.discovery_log:
		if not ev is Dictionary: continue
		var dd:Dictionary=ev
		if day-int(dd.get("day",day))>730: continue
		var e3:=_event_entry("disc:%s" % String(dd.get("id","")),"the discovery of %s" % String(dd.get("name","a new way")).to_lower(),int(dd.get("day",day)),"The people learned %s." % String(dd.get("name","")).to_lower())
		e3["kind"]="credit"; e3["type"]="discovery"; e3["discovery"]=String(dd.get("name",""))
		if seen.has(e3.key): continue
		out.append(e3); seen[e3.key]=true
		break
	while out.size()>limit: out.pop_back()
	return out

static func _event_entry(key:String,title:String,day:int,text:String)->Dictionary:
	var k:=_classify_event(title+" "+text)
	# "Food Stores Spoiled" is spoken as "the food stores spoiled".
	var clause:=title.strip_edges().to_lower()
	if not clause.begins_with("the ") and not clause.begins_with("a "): clause="the "+clause
	return {"key":key,"title":clause.substr(0,80),"day":day,"text":text.substr(0,200),"type":String(k.id),"kind":String(k.kind),"offices":(k.offices as Array).duplicate(),"trades":(k.trades as Array).duplicate()}

static func event_by_key(key:String,audience_id:String="")->Dictionary:
	for e in recent_events(12,audience_id):
		if String(e.key)==key: return e
	for r in truth_records():
		var ev:Dictionary=(r as Dictionary).get("event",{})
		if String(ev.get("key",""))==key: return ev
	return {}

static func categories()->Array[Dictionary]:
	## "Tell me of…": people the court could name, from what exists.
	var out:Array[Dictionary]=[]
	var sid:=String(_settlement("").get("id",""))
	for trade in ["potter","farmer","hunter","fisher","mason","weaver","smith","herder","builder"]:
		if trade_ok(trade) and out.size()<4: out.append({"label":"the %s" % trade_label(trade,true),"desc":{"trade":trade,"count":6,"settlement_id":sid}})
	out.append({"label":"the oldest woman alive","desc":{"sex":"female","age":"oldest","quality":"age","settlement_id":sid}})
	out.append({"label":"a widow of %s" % _settlement_name(sid),"desc":{"sex":"female","widow":true,"trade":_fit_trade(["farmer","gatherer"]),"settlement_id":sid}})
	out.append({"label":"a child of %s" % _settlement_name(sid),"desc":{"age":"child","settlement_id":sid}})
	out.append({"label":"the strongest man in the camp","desc":{"sex":"male","quality":"strength","trade":_fit_trade(["builder","hunter"]),"settlement_id":sid}})
	var chief:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if not chief.is_empty(): out.append({"label":"my best scout","desc":{"official":int(chief.person_id)}})
	for f in HistoricalFigures.people:
		if f is Dictionary and String((f as Dictionary).get("role",""))=="General" and String((f as Dictionary).get("status",""))!="dead":
			out.append({"label":"the war leader %s" % String((f as Dictionary).get("name","")),"desc":{"figure":String((f as Dictionary).get("id",""))}}); break
	if not GameState.discovery_log.is_empty():
		var d:Dictionary=GameState.discovery_log[0]
		out.append({"label":"whoever made the last discovery","desc":{"discovery":String(d.get("id","")),"deed":"found %s" % String(d.get("name","a new way")).to_lower(),"trade":_fit_trade(["gatherer","flint-knapper","potter","healer"]),"settlement_id":sid}})
	out.append({"label":"a stranger from beyond the hills","desc":{"far":true,"trade":_fit_trade(["trader","tracker","hunter"]),"settlement_id":sid}})
	return out

# --------------------------------------------------------------------------
# Resolution (structured): existing people first, then the created
# --------------------------------------------------------------------------

static func resolve(desc:Dictionary)->Dictionary:
	## {ref, unknown:bool}. desc may name an official ("official":pid), a
	## figure ("figure":id), a known person ("known":id or "name"), or describe
	## someone (trade, sex, age, settlement_id, quality, deed, count, widow, far).
	if int(desc.get("official",0))>0 and not GovernmentPeopleSystem.person_snapshot(int(desc.official)).is_empty(): return {"ref":{"kind":"official","pid":int(desc.official)}}
	if String(desc.get("figure",""))!="" and not HistoricalFigures.by_id(String(desc.figure)).is_empty(): return {"ref":{"kind":"figure","id":String(desc.figure)}}
	if String(desc.get("known",""))!="" and not by_id(String(desc.known)).is_empty(): return {"ref":{"kind":"known","id":String(desc.known)}}
	var named:=String(desc.get("name","")).strip_edges().to_lower()
	if named!="":
		for p:Dictionary in Hall._officials():
			if named in String(p.get("name","")).to_lower(): return {"ref":{"kind":"official","pid":int(p.person_id)}}
		for f in HistoricalFigures.people:
			if f is Dictionary and named in String((f as Dictionary).get("name","")).to_lower(): return {"ref":{"kind":"figure","id":String((f as Dictionary).get("id",""))}}
		for p2 in people():
			if named in String((p2 as Dictionary).get("name","")).to_lower() or named==String((p2 as Dictionary).get("given","")).to_lower(): return {"ref":ref_of(p2)}
	if String(desc.get("discovery",""))!="":
		# A real record first: the supported figure credited with it.
		for f2 in HistoricalFigures.people:
			if not f2 is Dictionary: continue
			for e in (f2 as Dictionary).get("events",[]):
				if String((e as Dictionary).get("text","")).to_lower().contains(String(desc.get("deed","")).trim_prefix("found ").substr(0,24)): return {"ref":{"kind":"figure","id":String((f2 as Dictionary).get("id",""))}}
	if bool(desc.get("far",false)): return {"unknown":true,"desc":desc.duplicate()}
	return {"ref":ref_of(find_or_create(desc))}

# --------------------------------------------------------------------------
# Blame: the hidden truth record
# --------------------------------------------------------------------------

static func _record_for_event(key:String)->Dictionary:
	for r in truth_records():
		if String(((r as Dictionary).get("event",{}) as Dictionary).get("key",""))==key: return r
	return {}

static func _holder_for(event:Dictionary)->Dictionary:
	for office in event.get("offices",[]):
		if GovernmentPeopleSystem.office_is_active(String(office)):
			var holder:=GovernmentPeopleSystem.officeholder(String(office))
			if not holder.is_empty():
				holder["office_key"]=String(office)
				return holder
	return {}

static func answerer_for(event:Dictionary,audience_id:String="")->Dictionary:
	## Who answers for it: the official before you, else the office's holder,
	## else the first official at court.
	var a:=Hall.find(audience_id)
	var pid:=int((a.get("speaker",{}) as Dictionary).get("person_id",0)) if not a.is_empty() else 0
	if pid>0 and not Hall._official(pid).is_empty(): return Hall._official(pid)
	var holder:=_holder_for(event)
	if not holder.is_empty(): return Hall._official(int(holder.person_id)) if not Hall._official(int(holder.person_id)).is_empty() else holder
	var all:=Hall._officials()
	return all[0] if not all.is_empty() else {}

static func answerer_for_desc(desc:Dictionary)->Dictionary:
	## Who knows people like this: the Chief Scout for distant folk, the war
	## leader's office for soldiers, the steward for everyone at home.
	var offices:Array=["Steward","Quartermaster"]
	if bool(desc.get("far",false)): offices=["ChiefScout","Envoy","Steward"]
	elif String(desc.get("trade","")) in ["warrior","watchman"]: offices=["Marshal","Steward"]
	elif int(desc.get("official",0))>0 and String(GovernmentPeopleSystem.person_snapshot(int(desc.official)).get("office_key",""))=="ChiefScout": offices=["Steward"]
	for office in offices:
		if GovernmentPeopleSystem.office_is_active(String(office)):
			var holder:=GovernmentPeopleSystem.officeholder(String(office))
			if not holder.is_empty(): return holder
	var all:=Hall._officials()
	return all[0] if not all.is_empty() else {}

static func attribute(event:Dictionary,answerer:Dictionary)->Dictionary:
	## Returns the truth record for this event (created once; asking again
	## returns the same answer).
	var existing:=_record_for_event(String(event.get("key","")))
	if not existing.is_empty(): return existing
	var s:=state()
	s.serial=int(s.serial)+1
	var key:=String(event.get("key",""))
	var holder:=_holder_for(event)
	var answerer_pid:=int(answerer.get("person_id",0))
	var sid:=String(_settlement("").get("id",""))
	var trade:=_fit_trade(event.get("trades",["gatherer"]))
	var rec:={"id":"tr_%d" % int(s.serial),"event":event.duplicate(true),"day":_day(),"answerer":{"pid":answerer_pid,"name":String(answerer.get("name",""))},
		"office_key":String(holder.get("office_key","")),"holder_pid":int(holder.get("person_id",0)),"lie":false,"relation":"other","tells":[],"revealed":[],
		"alibi_heard":false,"exposed":false,"confessed":[],"false_confessions":[],"false_accusations":[],"judged":[],"kind":String(event.get("kind","misfortune"))}
	if String(event.get("kind",""))=="credit":
		var credited:Dictionary={}
		for f in HistoricalFigures.people:
			if not f is Dictionary: continue
			for e in (f as Dictionary).get("events",[]):
				var words:=String(event.get("discovery",event.get("title",""))).to_lower().substr(0,24)
				if words!="" and String((e as Dictionary).get("text","")).to_lower().contains(words): credited={"kind":"figure","id":String((f as Dictionary).get("id",""))}
		if credited.is_empty():
			var p:=create({"trade":trade,"settlement_id":sid,"deed":"worked out %s" % String(event.get("discovery",event.get("title","it"))).to_lower()})
			credited=ref_of(p)
		rec["true_party"]=credited; rec["named"]=credited.duplicate(); rec["relation"]="credit"
	else:
		var culprit:=String(force.get("culprit",""))
		if culprit=="":
			var r:=_roll("culprit|"+key)
			culprit="holder" if r<0.4 else ("kin" if r<0.58 else "commoner")
		if holder.is_empty() and culprit in ["holder","kin"]: culprit="commoner"
		# A war leader who commanded that day is on the record by name.
		if String(event.get("type",""))=="war":
			for f in HistoricalFigures.people:
				if f is Dictionary and String((f as Dictionary).get("role",""))=="General":
					for e in (f as Dictionary).get("events",[]):
						if int((e as Dictionary).get("day",-1))==int(event.get("day",-2)): culprit="figure:"+String((f as Dictionary).get("id",""))
		var truth_ref:Dictionary
		if culprit.begins_with("figure:"): truth_ref={"kind":"figure","id":culprit.trim_prefix("figure:")}; rec.relation="commander"
		elif culprit=="holder": truth_ref={"kind":"official","pid":int(holder.person_id)}; rec.relation="self"
		elif culprit=="kin":
			var rng:=_rng("kin|"+key)
			var sex:="male" if rng.randf()<0.5 else "female"
			var rels:Array=KIN_RELATIONS[sex]
			var kin:=create({"trade":trade,"settlement_id":sid,"sex":sex,"kin_of":{"pid":int(holder.person_id),"relation":String(rels[rng.randi_range(0,rels.size()-1)])},"note":"I was minding %s the day %s." % [String(OFFICE_CHARGE.get(String(holder.get("office_key","")),"the work")),String(event.get("title","it happened"))]})
			truth_ref=ref_of(kin); rec.relation="kin"
		else:
			var c:=create({"trade":trade,"settlement_id":sid,"note":"I was at the work the day %s." % String(event.get("title","it happened"))})
			truth_ref=ref_of(c); rec.relation="other"
		rec["true_party"]=truth_ref
		# Does the one who answers lie? Only to shield themselves or their kin.
		var stake:bool=answerer_pid>0 and answerer_pid==int(holder.get("person_id",0)) and rec.relation in ["self","kin"]
		var lie:=false
		if stake:
			if force.has("lie"): lie=bool(force.lie)
			else:
				var person:=GovernmentPeopleSystem.person_snapshot(answerer_pid)
				var p_lie:=clampf(0.25+(1.0-float(person.get("honesty",0.6)))*0.55+DIVINE.dread_of(person)*0.45-DIVINE.love_of(person)*0.4+float(person.get("pride",0.5))*0.15+(0.1 if rec.relation=="kin" else 0.0),0.05,0.92)
				lie=_roll("lie|"+key)<p_lie
		rec.lie=lie
		if lie:
			var scape:=create({"trade":trade,"settlement_id":sid,"note":"I had nothing to do with it when %s." % String(event.get("title","it happened"))})
			var rng2:=_rng("alibi|"+key)
			var chief:=GovernmentPeopleSystem.officeholder("ChiefScout")
			var place:=String(ALIBI_PLACES[rng2.randi_range(0,ALIBI_PLACES.size()-1)])
			if not chief.is_empty() and rng2.randf()<0.5: place="out with the scouting party %s led" % String(chief.get("name","the pathfinder")).get_slice(" ",0)
			var companion:=_name_for("male" if rng2.randf()<0.5 else "female",rng2)
			var evday:=int(event.get("day",_day()))
			scape["alibi"]={"place":place,"from":evday-rng2.randi_range(6,12),"to":evday+rng2.randi_range(2,5),"witness":String(companion.name)}
			_remember(scape,"I was %s the day %s; %s was with me." % [place,String(event.get("title","it happened")),String(companion.given)])
			rec["named"]=ref_of(scape); rec["scapegoat"]=ref_of(scape)
			var tells:Array=["alibi"]
			if float(GovernmentPeopleSystem.person_snapshot(answerer_pid).get("honesty",0.5))>=0.55: tells.append("demeanor")
			else: tells.append("charge")
			rec.tells=tells
		else:
			rec["named"]=truth_ref.duplicate()
	for k in ["true_party","named","scapegoat"]:
		var ref:Dictionary=rec.get(k,{}) if rec.get(k) is Dictionary else {}
		if String(ref.get("kind",""))=="known":
			var p2:=by_id(String(ref.id))
			if not (p2.get("records",[]) as Array).has(rec.id): (p2.records as Array).append(rec.id)
			_importance(p2,3.0)
	(s.truth as Array).append(rec)
	while (s.truth as Array).size()>MAX_TRUTH: (s.truth as Array).pop_front()
	return rec

static func stance_in(rec:Dictionary,ref:Dictionary)->String:
	## "g" guilty (the true party), "i" named but innocent, "n" not involved.
	if rec.is_empty() or ref.is_empty(): return "n"
	if same_ref(rec.get("true_party",{}),ref): return "g"
	if same_ref(rec.get("named",{}),ref) or same_ref(rec.get("scapegoat",{}),ref): return "i"
	return "n"

static func active_record(audience_id:String)->Dictionary:
	var a:=Hall.find(audience_id)
	var rid:=String(a.get("record_id","")) if not a.is_empty() else ""
	if rid=="": rid=String(state().focus.get("record_id",""))
	return record(rid)

# --------------------------------------------------------------------------
# Who is before the god
# --------------------------------------------------------------------------

static func speaker_ref(audience_id:String)->Dictionary:
	var a:=Hall.find(audience_id)
	if a.is_empty(): return {}
	var sp:Dictionary=a.get("speaker",{}) if a.get("speaker") is Dictionary else {}
	if String(sp.get("known_id",""))!="": return {"kind":"known","id":String(sp.known_id)}
	if int(sp.get("person_id",0))>0: return {"kind":"official","pid":int(sp.person_id)}
	var hk:=String(a.get("holder_key",""))
	if hk.begins_with("figure:"): return {"kind":"figure","id":hk.trim_prefix("figure:")}
	return {}

static func speaker_known(audience_id:String)->Dictionary:
	var ref:=speaker_ref(audience_id)
	return by_id(String(ref.get("id",""))) if String(ref.get("kind",""))=="known" else {}

static func _official_person(pid:int)->Dictionary:
	var p:=Hall._official(pid)
	return p if not p.is_empty() else GovernmentPeopleSystem.person_snapshot(pid)

static func bench(audience_id:String)->Array[Dictionary]:
	return Hall.court(audience_id)

static func _witnesses(audience_id:String,exclude_pid:int=0)->Array:
	var out:Array=[]
	var a:=Hall.find(audience_id)
	var spid:=int((a.get("speaker",{}) as Dictionary).get("person_id",0)) if not a.is_empty() else 0
	if spid>0 and spid!=exclude_pid and not Hall._official(spid).is_empty(): out.append(Hall._official(spid))
	for p in bench(audience_id):
		if int(p.person_id)!=exclude_pid: out.append(p)
	return out

# --------------------------------------------------------------------------
# Choices (offline) and the menu (online)
# --------------------------------------------------------------------------

static func _choice(action:String,label:String,group:String,params:Dictionary={},extra:Dictionary={})->Dictionary:
	var c:={"action":action,"label":label,"group":group,"params":params}
	c.merge(extra,true)
	return c

static func choices(audience_id:String)->Array[Dictionary]:
	## Every step's choices, generated from real state: a tell-based challenge
	## appears only when that tell really exists and has shown itself.
	var out:Array[Dictionary]=[]
	var a:=Hall.find(audience_id)
	var waiting:=not a.is_empty() and String(a.get("status",""))=="waiting"
	var sref:=speaker_ref(audience_id)
	var known:=speaker_known(audience_id)
	var rec:=active_record(audience_id)
	var focus:Dictionary=state().focus
	var official_before:=String(sref.get("kind",""))=="official"
	if a.is_empty() or official_before:
		for e in recent_events(5,audience_id):
			out.append(_choice("ask_blame","Who is responsible for this? (%s)" % String(e.title).trim_prefix("the ").capitalize(),"ask",{"event":String(e.key)}))
		for c in categories():
			out.append(_choice("ask_about","Tell me of %s" % String(c.label),"ask",{"desc":c.desc}))
	if not focus.get("seek",{}).is_empty() and (a.is_empty() or official_before):
		out.append(_choice("seek","Have them sought out","ask",{"desc":focus.seek}))
	var fref:Dictionary=focus.get("person",{}) if focus.get("person") is Dictionary else {}
	if not fref.is_empty() and ref_alive(fref) and not same_ref(fref,sref):
		out.append(_choice("summon","Summon %s" % ref_name(fref),"summon",{"ref":fref}))
	var wit:=String(focus.get("witness",""))
	if wit!="" and not by_id(wit).is_empty() and not same_ref({"kind":"known","id":wit},sref) and not same_ref({"kind":"known","id":wit},fref):
		out.append(_choice("summon","Summon %s" % String(by_id(wit).name),"summon",{"ref":{"kind":"known","id":wit}}))
	if not known.is_empty() and waiting and String(known.get("status",""))=="living":
		for q in QUESTION: out.append(_choice(q,String(LABELS[q]),"question"))
		for j in JUDGE:
			if j=="make_official":
				for office:Dictionary in GovernmentPeopleSystem.active_offices():
					var title:=String(GovernmentPeopleSystem.office_definition(String(office.key)).get("title",String(office.key)))
					out.append(_choice(j,"Make %s the %s" % [String(known.given),title],"judge",{"office":String(office.key)}))
			elif j=="make_priest" and not _priest_ok(): continue
			else: out.append(_choice(j,"%s %s" % [String(LABELS[j]),String(known.given)] if j!="make_example" else "Make an example of %s" % String(known.given),"judge"))
		for n in Lines.novel_choices(signature(audience_id,"judge",{})):
			out.append(_choice(String(n.action),String(n.label),"judge",{"novel":n}))
	if not rec.is_empty() and waiting and not bool(rec.get("exposed",false)) and String(rec.get("kind",""))=="misfortune":
		var liar:=_official_person(int((rec.get("answerer",{}) as Dictionary).get("pid",0)))
		if not liar.is_empty() and _present(audience_id,int(liar.get("person_id",0))):
			var who:=String(liar.get("name","")).get_slice(" ",0)
			out.append(_choice("accuse_lie","%s, you are lying" % who,"confront",{"target":{"kind":"official","pid":int(liar.person_id)}}))
			for t in rec.get("revealed",[]):
				var label:=_tell_label(rec,String(t))
				if label!="": out.append(_choice("accuse_record",label,"confront",{"tell":String(t),"target":{"kind":"official","pid":int(liar.person_id)}}))
			out.append(_choice("bring_ledger","Bring the %s" % ledger_word(),"confront"))
	if not known.is_empty() and waiting:
		out.append(_choice("accuse_lie","%s, you are lying" % String(known.given),"confront",{"target":sref}))
	# Judgment of an official caught lying goes through the court's command engine.
	if not rec.is_empty() and bool(rec.get("exposed",false)) and waiting:
		var liar2:=_official_person(int((rec.get("answerer",{}) as Dictionary).get("pid",0)))
		if not liar2.is_empty() and String(liar2.get("status",""))=="active":
			for pair in [["Execute","execute"],["Exile","exile"],["Strip of office","demote"],["Pardon","pardon_official"]]:
				out.append(_choice("command",("%s %s" % [String(pair[0]),String(liar2.get("name",""))]),"judge",{"command_text":"%s %s" % [{"execute":"Execute","exile":"Exile","demote":"Demote","pardon_official":"Bless"}.get(String(pair[1]),"Bless"),String(liar2.get("name",""))]}))
	return out

static func _present(audience_id:String,pid:int)->bool:
	if pid<=0: return false
	for p in _witnesses(audience_id):
		if int((p as Dictionary).get("person_id",0))==pid: return true
	return false

static func _priest_ok()->bool:
	return true

static func priest_word()->String:
	return "priest" if CV.permits("priest",tags()) else "keeper of the god's fire"

static func ledger_word()->String:
	return "ledger" if CV.permits("ledger",tags()) else "tally-sticks"

static func _tell_label(rec:Dictionary,tell:String)->String:
	var scape:=by_id(String((rec.get("scapegoat",{}) as Dictionary).get("id","")))
	match tell:
		"alibi":
			if scape.is_empty(): return ""
			return "%s was %s that moon" % [String(scape.given),String((scape.get("alibi",{}) as Dictionary).get("place","away"))]
		"charge":
			return "%s were your charge, not a %s's" % [String(OFFICE_CHARGE.get(String(rec.get("office_key","")),"the stores")).capitalize(),trade_label(String(scape.get("trade","gatherer")))]
		"ledger":
			return "The %s show your own marks" % ledger_word()
		"demeanor":
			return ""
	return ""

static func menu(audience_id:String,prepare:bool=false)->Array[Dictionary]:
	## For the live model: the same actions, each with what the engine would
	## decide (never shown to the player; the model writes to it). prepare:
	## settle who is responsible for each listed event first, so the model
	## names the same person the engine will.
	var out:Array[Dictionary]=[]
	var seen:Dictionary={}
	if prepare:
		for e in recent_events(5,audience_id): attribute(e,answerer_for(e,audience_id))
	for c in choices(audience_id):
		var k:=String(c.action)+JSON.stringify(c.params)
		if seen.has(k): continue
		seen[k]=true
		var d:=decide(audience_id,String(c.action),c.params)
		out.append({"action":String(c.action),"label":String(c.label),"params":c.params,"decided":String(d.get("words",""))})
		if out.size()>=24: break
	return out

# --------------------------------------------------------------------------
# Signature (stored with learned templates; no names, no secrets)
# --------------------------------------------------------------------------

static func hidden_words(audience_id:String)->String:
	## The truth the live model must play but never volunteer.
	var parts:PackedStringArray=PackedStringArray()
	var rec:=active_record(audience_id)
	if not rec.is_empty():
		var ev:Dictionary=rec.get("event",{})
		var how_named:=", truthfully"
		if bool(rec.get("lie",false)): how_named=", which is a LIE to shield %s" % ("themselves" if String(rec.get("relation",""))=="self" else "their kin")
		parts.append("Matter: %s. Truly responsible: %s (%s). The one who answered was %s; they named %s%s." % [String(ev.get("title","")),ref_name(rec.get("true_party",{})),String(rec.get("relation","")),
			String((rec.get("answerer",{}) as Dictionary).get("name","")),ref_name(rec.get("named",{})),how_named])
		var scape:=by_id(String((rec.get("scapegoat",{}) as Dictionary).get("id","")))
		if not scape.is_empty():
			var alibi:Dictionary=scape.get("alibi",{}) if scape.get("alibi") is Dictionary else {}
			parts.append("%s was %s from day %d to %d with %s." % [String(scape.name),String(alibi.get("place","")),int(alibi.get("from",0)),int(alibi.get("to",0)),String(alibi.get("witness",""))])
		var shown:PackedStringArray=PackedStringArray()
		for t in rec.get("revealed",[]): shown.append(String(t))
		parts.append("Exposed already: %s. Tells shown: %s." % ["yes" if bool(rec.get("exposed",false)) else "no",", ".join(shown)])
	var known:=speaker_known(audience_id)
	if not known.is_empty():
		var st:=stance_in(rec,ref_of(known))
		var words:=String({"g":"GUILTY","i":"INNOCENT","n":"not involved"}.get(st,"not involved"))
		if st=="i" and bool(rec.get("lie",false)): words="INNOCENT, named falsely"
		parts.append("%s (before the god) is %s. Their life: %s" % [String(known.name),words,JSON.stringify(view(known)).substr(0,600)])
	return " ".join(parts) if not parts.is_empty() else "none"

static func descriptor_from(raw:Dictionary)->Dictionary:
	## A live model's description of someone, reduced to what the engine can ground.
	var d:Dictionary={}
	var trade:=String(raw.get("trade","")).to_lower().strip_edges()
	for t in TRADES:
		if trade!="" and (trade==String(t) or trade==trade_label(String(t)) or trade==trade_label(String(t),true) or String(t).begins_with(trade.trim_suffix("s"))):
			d["trade"]=String(t); break
	var sex:=String(raw.get("sex","")).to_lower()
	if sex in ["male","man","m"]: d["sex"]="male"
	elif sex in ["female","woman","f"]: d["sex"]="female"
	var age:=String(raw.get("age","")).to_lower()
	if age in ["child","young","old","oldest"]: d["age"]=age
	var deed:=String(raw.get("deed","")).strip_edges().substr(0,80)
	if deed!="": d["deed"]=deed
	var count:Variant=raw.get("count",1)
	if (count is int or count is float) and int(count)>1: d["count"]=int(count)
	if raw.get("far") is bool and bool(raw.far): d["far"]=true
	d["settlement_id"]=String(_settlement("").get("id",""))
	return d

static func signature(audience_id:String,action:String,params:Dictionary)->Dictionary:
	var sref:=speaker_ref(audience_id)
	var rec:=active_record(audience_id)
	var target:Dictionary=params.get("target",{}) if params.get("target") is Dictionary else {}
	if target.is_empty(): target=sref
	var role:="official" if String(sref.get("kind",""))=="official" else ("group" if int(by_id(String(sref.get("id",""))).get("count",1))>1 else ("commoner" if String(sref.get("kind",""))=="known" else "court"))
	var love:=0.5; var dread:=0.2
	if String(target.get("kind",""))=="known":
		var p:=by_id(String(target.id)); love=float(p.get("love",0.5)); dread=float(p.get("dread",0.2))
	elif String(target.get("kind",""))=="official":
		var o:=_official_person(int(target.pid)); love=DIVINE.love_of(o); dread=DIVINE.dread_of(o)
	var band:="dread" if dread>=0.55 else ("love" if love>=0.6 else "wary")
	var lie:="n"
	if not rec.is_empty() and String(rec.get("kind",""))=="misfortune": lie="l" if bool(rec.get("lie",false)) and not bool(rec.get("exposed",false)) else "t"
	return {"action":action,"role":role,"g":stance_in(rec,target),"l":lie,"band":band,"era":era_tier(),"ev":String((rec.get("event",{}) as Dictionary).get("type",""))}

static func signature_text(sig:Dictionary)->String:
	return "r=%s;g=%s;l=%s;b=%s;e=%d;v=%s" % [String(sig.get("role","")),String(sig.get("g","n")),String(sig.get("l","n")),String(sig.get("band","")),int(sig.get("era",0)),String(sig.get("ev",""))]

# --------------------------------------------------------------------------
# Deciding (pure) and performing (applies)
# --------------------------------------------------------------------------

static func _pressure(audience_id:String,kid:String)->Dictionary:
	var a:=Hall.find(audience_id)
	if a.is_empty(): return {}
	if not a.get("interrogation") is Dictionary: a["interrogation"]={}
	var all:Dictionary=a.interrogation
	if not all.get(kid) is Dictionary: all[kid]={"rounds":0,"threat":0,"mercy":0,"oath":0}
	return all[kid]

static func decide(audience_id:String,action:String,params:Dictionary={})->Dictionary:
	## What the engine would do, without doing it. Deterministic: perform()
	## decides the same way. {ok, outcome_id, words, ...}.
	var rec:=active_record(audience_id)
	var sref:=speaker_ref(audience_id)
	var known:=speaker_known(audience_id)
	match action:
		"ask_blame":
			var ev:=event_by_key(String(params.get("event","")),audience_id)
			if ev.is_empty(): return {"ok":false,"words":"no such event"}
			var existing:=_record_for_event(String(ev.key))
			if existing.is_empty(): return {"ok":true,"outcome_id":"name","words":"The one who answers names who was responsible for %s (decided when asked; name them exactly as the engine does)." % String(ev.title)}
			return {"ok":true,"outcome_id":"name","words":"%s names %s for %s%s." % [String((existing.answerer as Dictionary).get("name","")),ref_name(existing.named),String(ev.title)," (A LIE, hidden: the truth is %s; they shield it)" % ref_name(existing.true_party) if bool(existing.lie) else ""]}
		"ask_about":
			var desc:Dictionary=params.get("desc",{}) if params.get("desc") is Dictionary else {}
			return {"ok":true,"outcome_id":"unknown" if bool(desc.get("far",false)) else "describe","words":"No one at court knows such a person; they offer to have them sought." if bool(desc.get("far",false)) else "An official describes the person asked about (created or remembered)."}
		"seek": return {"ok":true,"outcome_id":"found","words":"Runners are sent; the person is found and named."}
		"summon":
			var ref:Dictionary=params.get("ref",{}) if params.get("ref") is Dictionary else {}
			if ref.is_empty() and params.get("desc") is Dictionary: return {"ok":true,"outcome_id":"summoned","words":"The person described is found (or created) and brought before the god."}
			if ref.is_empty(): ref=state().focus.get("person",{})
			return {"ok":not ref.is_empty(),"outcome_id":"summoned","words":"%s is brought before the god." % ref_name(ref)}
	if action in QUESTION:
		if known.is_empty(): return {"ok":false,"words":"no summoned person to question"}
		return _decide_question(audience_id,action,known,rec,params)
	if action=="accuse_lie":
		var target:Dictionary=params.get("target",{}) if params.get("target") is Dictionary and not (params.get("target") as Dictionary).is_empty() else sref
		if String(target.get("kind",""))=="known":
			if known.is_empty(): return {"ok":false,"words":"nobody to accuse"}
			var d:=_decide_question(audience_id,"q_did",known,rec,{"evidence":1})
			d["accused"]=true
			return d
		return _decide_accuse(audience_id,rec,int(target.get("pid",0)),"",false)
	if action=="accuse_record":
		var target2:Dictionary=params.get("target",{}) if params.get("target") is Dictionary else {}
		var pid:=int(target2.get("pid",(rec.get("answerer",{}) as Dictionary).get("pid",0)))
		return _decide_accuse(audience_id,rec,pid,String(params.get("tell","")),false)
	if action=="bring_ledger":
		if rec.is_empty(): return {"ok":true,"outcome_id":"nothing","words":"The %s show nothing to the point." % ledger_word()}
		var keeper:=String(GovernmentPeopleSystem.office_definition(String(rec.get("office_key","Steward"))).get("title","keeper"))
		if bool(rec.get("lie",false)) and not bool(rec.get("exposed",false)): return {"ok":true,"outcome_id":"ledger_contradicts","words":"The %s show the %s's own marks on the matter, not the one who was named: a tell against the one who answered." % [ledger_word(),keeper]}
		return {"ok":true,"outcome_id":"ledger_confirms","words":"The %s bear out what was said." % ledger_word()}
	if action in JUDGE or action.begins_with("novel:"):
		var target3:Dictionary=params.get("target",{}) if params.get("target") is Dictionary and not (params.get("target") as Dictionary).is_empty() else sref
		if String(target3.get("kind",""))!="known": return {"ok":false,"words":"judgment here needs a summoned person"}
		return {"ok":true,"outcome_id":action,"words":"%s: carried out on %s at once." % [String(LABELS.get(action,action)),ref_name(target3)]}
	if action=="talk": return {"ok":true,"outcome_id":"talk","words":"They answer from what they know."}
	return {"ok":false,"words":"unknown action"}

static func _decide_question(audience_id:String,action:String,p:Dictionary,rec:Dictionary,params:Dictionary)->Dictionary:
	var ref:=ref_of(p)
	var stance:=stance_in(rec,ref)
	var pr:=_pressure(audience_id,String(p.id))
	var rounds:=int(pr.get("rounds",0))
	var threat:=int(pr.get("threat",0))+(1 if action=="q_threaten" else 0)
	var mercy:=int(pr.get("mercy",0))+(1 if action=="q_mercy" else 0)
	var oath:=action=="q_swear"
	var dread:=clampf(float(p.get("dread",0.2))+(0.25 if action=="q_threaten" else 0.0),0.0,1.0)
	var love:=clampf(float(p.get("love",0.5))+(0.1 if action=="q_mercy" else 0.0),0.0,1.0)
	var courage:=float(p.get("courage",0.5))
	var honesty:=float(p.get("honesty",0.5))
	var evidence:=int(params.get("evidence",0))+(rec.get("revealed",[]) as Array).size() if not rec.is_empty() else int(params.get("evidence",0))
	var kids:=int((p.get("household",{}) as Dictionary).get("children",0))
	var out:={"ok":true,"stance":stance,"dread_after":dread,"love_after":love,"threat":threat,"mercy":mercy}
	if stance=="n":
		out["outcome_id"]={"q_where":"where_plain","q_did":"did_what","q_swear":"swear_true","q_who_else":"no_one","q_mercy":"thanks","q_threaten":"cower"}.get(action,"talk")
		out["words"]="%s is not involved in any matter before the court and answers plainly from their own life." % String(p.name)
		return out
	if stance=="i":
		# An innocent: alibi with specifics, and they point at who named them.
		if action in ["q_threaten","q_did"] and dread>=0.75 and courage<0.45 and threat>=1:
			out["outcome_id"]="false_confession"
			out["words"]="%s is innocent but, terrified, falsely confesses (record it as FALSE)." % String(p.name)
			return out
		out["outcome_id"]={"q_where":"alibi","q_did":"protest","q_swear":"swear_true","q_who_else":"witness","q_mercy":"thanks_alibi","q_threaten":"protest"}.get(action,"protest")
		out["words"]="%s is innocent: they give their alibi (%s, with %s) and say who named them." % [String(p.name),String((p.get("alibi",{}) as Dictionary).get("place","elsewhere")),String((p.get("alibi",{}) as Dictionary).get("witness","a neighbour"))]
		return out
	# Guilty: deny, deflect, beg, or crack.
	var p_crack:=clampf(0.08+dread*0.35+float(threat)*0.12+float(evidence)*0.14+(honesty*0.35 if oath else 0.0)+float(mercy)*love*0.22-courage*0.25+float(rounds)*0.1,0.02,0.95)
	if action=="q_where":
		out["outcome_id"]="vague"
		out["words"]="%s is guilty and gives a vague account of where they were." % String(p.name)
		return out
	if action=="q_who_else":
		out["outcome_id"]="shift_blame" if float(p.get("pride",0.5))>0.5 else "no_one_guilty"
		out["words"]="%s is guilty and tries to shift eyes elsewhere." % String(p.name)
		return out
	var roll:=_roll("crack|%s|%s|%d|%s" % [String(rec.get("id","")),String(p.id),rounds,action])
	if roll<p_crack:
		out["outcome_id"]="confess"
		out["words"]="%s is guilty and CRACKS: they confess." % String(p.name)
	elif oath:
		out["outcome_id"]="swear_false"
		out["words"]="%s is guilty and swears falsely." % String(p.name)
	elif courage<0.4 or (kids>0 and dread>0.5):
		out["outcome_id"]="beg"
		out["words"]="%s is guilty and begs, without admitting it." % String(p.name)
	else:
		out["outcome_id"]="deny"
		out["words"]="%s is guilty and denies it." % String(p.name)
	out["p_crack"]=p_crack
	return out

static func _decide_accuse(audience_id:String,rec:Dictionary,pid:int,tell:String,_apply:bool)->Dictionary:
	var person:=_official_person(pid)
	if person.is_empty(): return {"ok":false,"words":"nobody to accuse"}
	var lying:=not rec.is_empty() and bool(rec.get("lie",false)) and int((rec.get("answerer",{}) as Dictionary).get("pid",0))==pid and not bool(rec.get("exposed",false))
	if not lying:
		return {"ok":true,"outcome_id":"false_accusation","honest":true,"words":"%s told the truth; the accusation is false. They protest; love and trust fall." % String(person.get("name",""))}
	var revealed:Array=rec.get("revealed",[])
	var evidence:=float(revealed.size())+(1.0 if bool(rec.get("alibi_heard",false)) else 0.0)
	var right_tell:=tell!="" and (rec.get("tells",[]) as Array).has(tell) or tell=="ledger" and revealed.has("ledger")
	var dread:=DIVINE.dread_of(person)
	var love:=DIVINE.love_of(person)
	var p:=clampf(0.12+evidence*0.18+(0.3 if right_tell else 0.0)+dread*0.3+love*0.2-float(person.get("pride",0.5))*0.25-float(person.get("courage",0.5))*0.1+float(rec.get("pressed",0))*0.12,0.05,0.97)
	var roll:=_roll("accuse|%s|%d|%s" % [String(rec.get("id","")),int(rec.get("pressed",0)),tell])
	if roll<p: return {"ok":true,"outcome_id":"liar_cracks","words":"%s LIED and now CRACKS: they confess %s." % [String(person.get("name","")),"their kinsman's fault" if String(rec.get("relation",""))=="kin" else "their own fault"],"p":p}
	return {"ok":true,"outcome_id":"liar_doubles_down","words":"%s LIED and doubles down; their unease shows." % String(person.get("name","")),"p":p}

static func perform(audience_id:String,action:String,params:Dictionary={},how:Dictionary={})->Dictionary:
	## Decide and apply. how: {"lines":[{who,text,aside}] from the live model
	## (spoken instead of the offline lines), "echo":ruler words to add,
	## "deltas":[...] for a novel action}. Returns {ok, action, outcome_id,
	## outcome, lines, summon_audience_id?, signature}.
	var result:={"ok":false,"action":action,"params":params.duplicate(true),"outcome":"","lines":[],"signature":signature(audience_id,action,params)}
	var echo:=String(how.get("echo",""))
	if echo!="" and not Hall.find(audience_id).is_empty(): Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"text":echo,"day":_day()})
	var d:=decide(audience_id,action,params)
	result.merge(d,true)
	if not bool(d.get("ok",false)):
		result.outcome="That cannot be done here."
		return result
	var beats:Array=[]
	match action:
		"ask_blame": beats=_do_ask_blame(audience_id,params,result)
		"ask_about": beats=_do_ask_about(audience_id,params,result)
		"seek": beats=_do_seek(audience_id,params,result)
		"summon": beats=_do_summon(audience_id,params,result)
		"accuse_lie","accuse_record": beats=_do_accuse(audience_id,action,params,result,d)
		"bring_ledger": beats=_do_ledger(audience_id,result,d)
		"talk": beats=[]
	if action in QUESTION or (action=="accuse_lie" and bool(d.get("accused",false))): beats=_do_question(audience_id,"q_did" if action=="accuse_lie" else action,params,result,d)
	if action in JUDGE or action.begins_with("novel:"): beats=_do_judge(audience_id,action,params,result,how)
	result.ok=true
	# Speak: the live model's lines if given, else offline (learned or banked).
	# Where the engine chose a person, the live principal line must name them,
	# or the engine's own line stands in for it (asides and staging stay).
	var spoken:Array=how.get("lines",[]) if how.get("lines") is Array else []
	var target_id:=String(result.get("speak_in",audience_id))
	var offline_lines:=Lines.render(beats,result.signature,_rng("lines|%s|%s|%d" % [audience_id,action,(Hall.find(target_id).get("lines",[]) as Array).size()]))
	result["spoke_live"]=false
	if not spoken.is_empty():
		var named:Dictionary=result.get("named",{}) if result.get("named") is Dictionary else {}
		var must:=ref_name(named).get_slice(" ",0) if bool(how.get("require_name",false)) and not named.is_empty() and action!="summon" else ""
		var principal_ok:=true
		var principal_index:=-1
		for i in spoken.size():
			var sl:Dictionary=spoken[i]
			if String(sl.get("role",""))!="narrator" and not bool(sl.get("aside",false)):
				principal_index=i; break
		if must!="" and (principal_index<0 or not String((spoken[principal_index] as Dictionary).get("text","")).contains(must)): principal_ok=false
		if not principal_ok:
			var engine_principal:Dictionary={}
			for l in offline_lines:
				if String((l as Dictionary).get("role",""))!="narrator" and not bool((l as Dictionary).get("aside",false)):
					engine_principal=l; break
			if principal_index>=0: spoken[principal_index]=engine_principal
			else: spoken.push_front(engine_principal)
		# The exchange happened where the god spoke; an arrival is already
		# staged in the summoned person's own audience.
		_speak_lines(audience_id,spoken)
		result["spoke_live"]=principal_ok
	else: _speak_lines(target_id,offline_lines)
	if String(result.outcome)!="" and not bool(how.get("quiet_outcome",false)) and not action in ASK:
		Hall.append_line(target_id if spoken.is_empty() else audience_id,{"speaker":"","role":"narrator","person_id":0,"text":String(result.outcome),"day":_day()})
	result.lines=beats
	result["spoken"]=offline_lines if spoken.is_empty() else spoken
	# The dead and the driven-out do not stay to talk.
	if bool(result.get("conclude",false)): Hall.conclude(audience_id,String(result.outcome),action)
	return result

static func _speak_lines(audience_id:String,lines:Array)->void:
	for l in lines:
		if not l is Dictionary: continue
		var line:Dictionary=l
		if String(line.get("text","")).strip_edges()=="": continue
		Hall.append_line(audience_id,{"speaker":String(line.get("speaker","")),"role":String(line.get("role","official")),"person_id":int(line.get("person_id",0)),"text":String(line.text),"day":_day(),"aside":bool(line.get("aside",false))})

# ---- beats: {who:"speaker"|"official"|"narrator"|"known", person:{...}, beat, slots}

static func _beat_official(person:Dictionary,beat:String,slots:Dictionary,aside:bool=false)->Dictionary:
	return {"speaker":String(person.get("name","")),"role":"official","person_id":int(person.get("person_id",0)),"beat":beat,"slots":slots,"aside":aside,"persona_of":{"official":int(person.get("person_id",0))}}

static func _beat_known(p:Dictionary,beat:String,slots:Dictionary)->Dictionary:
	return {"speaker":String(p.get("name","")),"role":"official","person_id":0,"beat":beat,"slots":slots,"aside":false,"persona_of":{"known":String(p.get("id",""))},"principal":true}

static func _beat_narrator(beat:String,slots:Dictionary)->Dictionary:
	return {"speaker":"","role":"narrator","person_id":0,"beat":beat,"slots":slots}

static func slots_for(ref:Dictionary)->Dictionary:
	## Values for {name} {given} {trade} {village} {age} {household} {detail}.
	var out:={"name":ref_name(ref),"given":ref_name(ref).get_slice(" ",0),"god_address":"Great One"}
	match String(ref.get("kind","")):
		"known":
			var p:=by_id(String(ref.id))
			var v:=view(p)
			out.merge({"trade":String(v.trade) if int(p.get("count",1))<=1 else trade_label(String(p.get("trade","")),true),"village":String(v.village),"age":str(int(v.age)),"detail":String(v.detail),"temper":String(v.temper),"role":title_of(p),"place":String(v.village),
				"household":_household_words(p),"count":str(int(p.get("count",1))),"he":"she" if String(p.get("sex",""))=="female" else "he","his":"her" if String(p.get("sex",""))=="female" else "his"},true)
			var kin:Dictionary=p.get("kin_of",{}) if p.get("kin_of") is Dictionary else {}
			if not kin.is_empty(): out["kin"]="%s's %s" % [String(GovernmentPeopleSystem.person_snapshot(int(kin.pid)).get("name","")).get_slice(" ",0),String(kin.get("relation","kin"))]
		"official":
			var o:=_official_person(int(ref.pid))
			out.merge({"role":String(o.get("office_title",o.get("title","official"))),"trade":String(o.get("office_title","official")),"village":_settlement_name(String(o.get("home_settlement_id",""))),"age":str(int(o.get("age",40))),"detail":"holds the office of %s" % String(o.get("office_title","")),"household":"","he":"they","his":"their"},true)
		"figure":
			var f:=HistoricalFigures.by_id(String(ref.id))
			out.merge({"role":"war leader" if String(f.get("role",""))=="General" else String(f.get("role","")).to_lower(),"trade":String(f.get("role","")).to_lower(),"village":String(f.get("origin","")),"detail":String(f.get("temperament","")),"household":"","he":"she" if String(f.get("gender",""))=="woman" else "he","his":"her" if String(f.get("gender",""))=="woman" else "his"},true)
	return out

static func _household_words(p:Dictionary)->String:
	var hh:Dictionary=p.get("household",{}) if p.get("household") is Dictionary else {}
	var sp:Dictionary=hh.get("spouse",{}) if hh.get("spouse") is Dictionary else {}
	var kids:=int(hh.get("children",0))
	var parts:PackedStringArray=PackedStringArray()
	if String(hh.get("parents",""))!="": parts.append("the child of %s" % String(hh.parents))
	if not sp.is_empty(): parts.append(("widowed of %s" if not bool(sp.get("alive",true)) else "married to %s") % String(sp.get("name","")))
	if kids>0: parts.append("%s %s" % [Notables._number_word(kids),"child" if kids==1 else "children"])
	return ", ".join(parts) if not parts.is_empty() else "no household of their own"

static func _set_focus(ref:Dictionary,rec_id:String="")->void:
	var f:Dictionary=state().focus
	f["person"]=ref.duplicate()
	f["day"]=_day()
	if rec_id!="": f["record_id"]=rec_id
	f.erase("seek")

static func _do_ask_blame(audience_id:String,params:Dictionary,result:Dictionary)->Array:
	var ev:=event_by_key(String(params.get("event","")),audience_id)
	var answerer:=answerer_for(ev,audience_id)
	var asked_before:=not _record_for_event(String(ev.get("key",""))).is_empty() and bool(_record_for_event(String(ev.get("key",""))).get("asked",false))
	var rec:=attribute(ev,answerer)
	rec["asked"]=true
	# The one who first answered answers for it; asking again gets the same name.
	var first_pid:=int((rec.get("answerer",{}) as Dictionary).get("pid",0))
	if first_pid>0 and first_pid!=int(answerer.get("person_id",0)) and _present(audience_id,first_pid): answerer=_official_person(first_pid)
	var a:=Hall.find(audience_id)
	if not a.is_empty(): a["record_id"]=String(rec.id)
	_set_focus(rec.named,String(rec.id))
	result["record_id"]=String(rec.id)
	result["named"]=(rec.named as Dictionary).duplicate()
	var slots:=slots_for(rec.named)
	slots["event"]=String(ev.get("title","this"))
	var beats:Array=[]
	var is_credit:=String(rec.get("kind",""))=="credit"
	beats.append(_beat_official(answerer,"blame_again" if asked_before else ("credit" if is_credit else ("blame_lie" if bool(rec.lie) else "blame")),slots))
	if asked_before:
		result.signature=signature(audience_id,"ask_blame",{"target":{"kind":"official","pid":int(answerer.get("person_id",0))}})
		result.outcome=""
		return beats
	result.signature=signature(audience_id,"ask_blame",{"target":{"kind":"official","pid":int(answerer.get("person_id",0))}})
	if bool(rec.lie):
		# The tell that is not the scapegoat's own story shows at once.
		for t in rec.tells:
			if String(t)=="demeanor":
				beats.append(_beat_narrator("tell_demeanor",{"liar":String(answerer.get("name","")).get_slice(" ",0)}))
				_reveal(rec,"demeanor")
			elif String(t)=="charge":
				var rival:={}
				for w in _witnesses(audience_id,int(answerer.get("person_id",0))): rival=w; break
				if not rival.is_empty():
					var rs:={"liar":String(answerer.get("name","")).get_slice(" ",0),"charge":String(OFFICE_CHARGE.get(String(rec.get("office_key","")),"the stores")),"trade":String(slots.get("trade",""))}
					beats.append(_beat_official(rival,"tell_charge",rs,true))
					_reveal(rec,"charge")
				else:
					beats.append(_beat_narrator("tell_demeanor",{"liar":String(answerer.get("name","")).get_slice(" ",0)}))
					_reveal(rec,"demeanor")
	result.outcome="%s named %s%s." % [String(answerer.get("name","")),ref_name(rec.named)," as the one responsible when "+String(ev.get("title","it happened")) if not is_credit else " as the one behind "+String(ev.get("title","it"))]
	return beats

static func _reveal(rec:Dictionary,tell:String)->void:
	var revealed:Array=rec.get("revealed",[])
	if not revealed.has(tell): revealed.append(tell)
	rec["revealed"]=revealed

static func _do_ask_about(audience_id:String,params:Dictionary,result:Dictionary)->Array:
	var desc:Dictionary=params.get("desc",{}) if params.get("desc") is Dictionary else {}
	var a:=Hall.find(audience_id)
	var answerer:Dictionary={}
	var sp:=int((a.get("speaker",{}) as Dictionary).get("person_id",0)) if not a.is_empty() else 0
	if sp>0: answerer=_official_person(sp)
	elif not bench(audience_id).is_empty(): answerer=bench(audience_id)[0]
	var r:=resolve(desc)
	if bool(r.get("unknown",false)):
		state().focus["seek"]=desc.duplicate()
		result["unknown"]=true
		result.outcome="Nobody at court knows such a person."
		return [_beat_official(answerer,"unknown",{"trade":trade_label(String(desc.get("trade","hunter")),true)})]
	var ref:Dictionary=r.ref
	_set_focus(ref)
	result["named"]=ref.duplicate()
	if String(ref.get("kind",""))=="known": _importance(by_id(String(ref.id)),1.0)
	result.outcome=""
	return [_beat_official(answerer,"describe" if int(by_id(String(ref.get("id",""))).get("count",1))<=1 else "describe_group",slots_for(ref))]

static func _do_seek(audience_id:String,params:Dictionary,result:Dictionary)->Array:
	var desc:Dictionary=(params.get("desc",{}) as Dictionary).duplicate() if params.get("desc") is Dictionary else {}
	desc.erase("far")
	desc["note"]="Runners came for me from the court and I walked three days to answer."
	var p:=create(desc)
	_set_focus(ref_of(p))
	result["named"]=ref_of(p)
	var a:=Hall.find(audience_id)
	var answerer:Dictionary={}
	var sp:=int((a.get("speaker",{}) as Dictionary).get("person_id",0)) if not a.is_empty() else 0
	if sp>0: answerer=_official_person(sp)
	return [_beat_official(answerer,"found",slots_for(ref_of(p)))]

static func _do_summon(audience_id:String,params:Dictionary,result:Dictionary)->Array:
	var ref:Dictionary=params.get("ref",{}) if params.get("ref") is Dictionary and not (params.get("ref") as Dictionary).is_empty() else state().focus.get("person",{})
	if params.get("desc") is Dictionary and not (params.get("desc") as Dictionary).is_empty():
		var r:=resolve(params.desc)
		if not r.has("ref"):
			result.ok=false
			result.outcome="Nobody at court knows where to find such a person; have them sought out first."
			return []
		ref=r.ref
	result["named"]=ref.duplicate()
	var made:=summon_ref(ref,audience_id)
	if made.is_empty():
		result.ok=false
		result.outcome="They cannot be brought before you now."
		return []
	result["summon_audience_id"]=String(made.id)
	result["speak_in"]=String(made.id)
	result.outcome=""
	return []

static func summon_ref(ref:Dictionary,from_audience_id:String="")->Dictionary:
	## Bring someone before the god: officials and figures through the hall's
	## own summons; a court-known person as a summons audience of their own.
	match String(ref.get("kind","")):
		"official": return Hall.summon({"person_id":int(ref.pid)})
		"figure": return Hall.summon({"figure_id":String(ref.id)})
	var p:=by_id(String(ref.get("id","")))
	if p.is_empty() or String(p.get("status",""))!="living": return {}
	for a in Hall.waiting():
		if String(((a as Dictionary).get("speaker",{}) as Dictionary).get("known_id",""))==String(p.id): return a
	_trim_waiting()
	var from:=Hall.find(from_audience_id)
	var day:=_day()
	var audience:=Hall._new_audience("court","summons",day)
	var title:=title_of(p)
	audience.speaker={"name":String(p.name).substr(0,100),"title":title.substr(0,100),"person_id":0,"role":"official","known_id":String(p.id)}
	audience.petition={"topic":"summons","summary":"%s is brought before you at your word." % String(p.name),"suggested_decree":""}
	audience.situation={"type":"summons","ask":"summons:known:%s:%d" % [String(p.id),day],"headline":"is brought before you","summary":"%s, %s, is brought before you." % [String(p.name),title],"occasion":{"type":"summons","text":"the ruler sent for them","day":day,"crisis":false}}
	audience["summoned"]=true
	audience["holder_key"]="known:"+String(p.id)
	var rec_id:=String(from.get("record_id","")) if not from.is_empty() else ""
	if rec_id=="": rec_id=String(state().focus.get("record_id",""))
	if rec_id!="" and (p.get("records",[]) as Array).has(rec_id): audience["record_id"]=rec_id
	elif not (p.get("records",[]) as Array).is_empty(): audience["record_id"]=String((p.records as Array).back())
	# Those who were in the room come with the god's attention: the one who
	# named them sits on the bench.
	var pids:Array=[]
	var rec:=record(String(audience.get("record_id","")))
	if not rec.is_empty() and int((rec.answerer as Dictionary).get("pid",0))>0: pids.append(int((rec.answerer as Dictionary).pid))
	var fsp:=int((from.get("speaker",{}) as Dictionary).get("person_id",0)) if not from.is_empty() else 0
	if fsp>0 and not pids.has(fsp): pids.append(fsp)
	audience["court_pids"]=pids
	if not Hall._valid_audience(audience): return {}
	Hall._enqueue(audience,day)
	_importance(p,2.0)
	_set_focus(ref_of(p),String(audience.get("record_id","")))
	# They arrive: a stage direction and their own first words.
	var slots:=slots_for(ref_of(p))
	var stance:=stance_in(rec,ref_of(p))
	var beats:Array=[_beat_narrator("arrive_stage" if int(p.get("count",1))<=1 else "arrive_group",slots),_beat_known(p,{"g":"arrive_guilty","i":"arrive_named","n":"arrive"}.get(stance,"arrive"),slots)]
	var sig:=signature(String(audience.id),"summon",{})
	_speak_lines(String(audience.id),Lines.render(beats,sig,_rng("arrive|%s" % String(audience.id))))
	return audience

static func _trim_waiting()->void:
	## Summoning many people never piles up an unbounded waiting room: the
	## oldest summoned commoners go home first.
	var known_waiting:Array=[]
	for a in Hall.waiting():
		if String(((a as Dictionary).get("speaker",{}) as Dictionary).get("known_id",""))!="": known_waiting.append(a)
	var guard:=0
	while Hall.waiting().size()>=WAITING_CAP and not known_waiting.is_empty() and guard<20:
		guard+=1
		var old:Dictionary=known_waiting.pop_front()
		Hall.conclude(String(old.id),"%s went home." % String((old.speaker as Dictionary).get("name","They")),"dismiss_summons")

static func _do_question(audience_id:String,action:String,_params:Dictionary,result:Dictionary,d:Dictionary)->Array:
	var p:=speaker_known(audience_id)
	var rec:=active_record(audience_id)
	var pr:=_pressure(audience_id,String(p.id))
	pr["rounds"]=int(pr.get("rounds",0))+1
	pr["threat"]=int(d.get("threat",0)); pr["mercy"]=int(d.get("mercy",0))
	if action=="q_swear": pr["oath"]=int(pr.get("oath",0))+1
	p["dread"]=snappedf(float(d.get("dread_after",p.get("dread",0.2))),0.01)
	p["love"]=snappedf(float(d.get("love_after",p.get("love",0.5))),0.01)
	_importance(p,0.5)
	var slots:=slots_for(ref_of(p))
	var alibi:Dictionary=p.get("alibi",{}) if p.get("alibi") is Dictionary else {}
	slots["place"]=String(alibi.get("place",p.get("village","")))
	slots["witness"]=String(alibi.get("witness",""))
	slots["event"]=String((rec.get("event",{}) as Dictionary).get("title","this"))
	var answerer_pid:=int((rec.get("answerer",{}) as Dictionary).get("pid",0))
	var liar:=_official_person(answerer_pid)
	slots["liar"]=String(liar.get("name","")).get_slice(" ",0)
	slots["liar_title"]=String(liar.get("office_title","the official"))
	slots["charge"]=String(OFFICE_CHARGE.get(String(rec.get("office_key","")),"the stores"))
	var truth:Dictionary=rec.get("true_party",{}) if rec.get("true_party") is Dictionary else {}
	slots["culprit"]=ref_name(truth)
	var outcome_id:=String(d.get("outcome_id","talk"))
	result["outcome_id"]=outcome_id
	var beats:Array=[]
	if action=="q_threaten": beats.append(_beat_narrator("threatened",slots))
	var known_beat:=outcome_id
	# An innocent named by a lie knows who named them; a kinsman's victim may know more.
	if outcome_id in ["alibi","protest","thanks_alibi","swear_true"] and String(d.get("stance",""))=="i":
		rec["alibi_heard"]=true
		_reveal(rec,"alibi")
		if bool(rec.get("lie",false)) and String(rec.get("relation",""))=="kin" and outcome_id=="alibi": known_beat="alibi_kin"
		elif bool(rec.get("lie",false)): known_beat=outcome_id+"_named"
		var wname:=String(alibi.get("witness",""))
		if wname!="":
			var w:=find_or_create({"trade":String(p.get("trade","")),"settlement_id":String(p.get("settlement_id","")),"deed":"was with %s %s" % [String(p.given),String(alibi.get("place",""))]})
			if String(w.get("name",""))!=wname: w["name"]=wname; w["given"]=wname.get_slice(" ",0)
			_remember(w,"I was %s with %s the day %s." % [String(alibi.get("place","")),String(p.given),slots.event])
			state().focus["witness"]=String(w.id)
	if outcome_id=="confess":
		(rec.get("confessed",[]) as Array).append({"ref":ref_of(p),"day":_day(),"true":true})
		rec["exposed"]=true
		_remember(p,"Before the god I confessed my part in it, the day %s." % slots.event)
	elif outcome_id=="false_confession":
		(rec.get("false_confessions",[]) as Array).append({"ref":ref_of(p),"day":_day(),"under":"terror"})
		_remember(p,"I said I did it. I did not. I was afraid for my life.")
	elif outcome_id=="swear_false":
		_remember(p,"I swore a false oath before the god.")
		rec["false_oaths"]=int(rec.get("false_oaths",0))+1
	elif outcome_id=="swear_true":
		_remember(p,"I swore before the god that I had no part in it, the day %s." % slots.event)
	beats.append(_beat_known(p,known_beat,slots))
	# Witnesses: the liar shifts in their seat when the alibi lands.
	if known_beat.ends_with("_named") or known_beat=="alibi_kin":
		if _present(audience_id,answerer_pid): beats.append(_beat_narrator("liar_uneasy",slots))
	if outcome_id=="false_confession":
		for w in _witnesses(audience_id,answerer_pid):
			beats.append(_beat_official(w,"witness_doubt",slots,true)); break
	if outcome_id=="confess": result.outcome="%s confessed before the court." % String(p.name)
	elif outcome_id=="false_confession": result.outcome="%s confessed, shaking." % String(p.name)
	else: result.outcome=""
	return beats

static func _do_accuse(audience_id:String,action:String,params:Dictionary,result:Dictionary,d:Dictionary)->Array:
	var rec:=active_record(audience_id)
	var target:Dictionary=params.get("target",{}) if params.get("target") is Dictionary and not (params.get("target") as Dictionary).is_empty() else {"kind":"official","pid":int((rec.get("answerer",{}) as Dictionary).get("pid",0))}
	var pid:=int(target.get("pid",0))
	var person:=_official_person(pid)
	var slots:=slots_for({"kind":"official","pid":pid})
	slots["event"]=String((rec.get("event",{}) as Dictionary).get("title","this"))
	slots["named"]=ref_name(rec.get("named",{}))
	slots["culprit"]=ref_name(rec.get("true_party",{}))
	slots["charge"]=String(OFFICE_CHARGE.get(String(rec.get("office_key","")),"the stores"))
	var beats:Array=[]
	var outcome_id:=String(d.get("outcome_id",""))
	result["outcome_id"]=outcome_id
	var witnesses:=_witnesses(audience_id,pid)
	match outcome_id:
		"false_accusation":
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":-0.07,"resentment":0.06,"trust":-0.05})
			GovernmentPeopleSystem.record_person_memory(pid,"The god called me a liar before the court, and I had told the truth.","divine",0.75,{"emotion":"hurt","outcome":"falsely_accused"})
			for w in witnesses: GovernmentPeopleSystem.adjust_person_bonds(int((w as Dictionary).person_id),{"trust":-0.03,"fear":0.02})
			if not rec.is_empty(): (rec.get("false_accusations",[]) as Array).append({"pid":pid,"day":_day()})
			beats.append(_beat_official(person,"protest_honest",slots))
			if not witnesses.is_empty(): beats.append(_beat_official(witnesses[0],"witness_wary",slots,true))
			result.outcome="%s had told the truth. Love and trust at court fall." % String(person.get("name",""))
		"liar_cracks":
			rec["exposed"]=true
			(rec.get("confessed",[]) as Array).append({"ref":{"kind":"official","pid":pid},"day":_day(),"true":true})
			if action=="accuse_record": _reveal(rec,String(params.get("tell","")))
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.08,"respect":-0.05,"trust":-0.04,"hold_days":40})
			GovernmentPeopleSystem.record_person_memory(pid,"I lied to the god about how %s, and was caught before the court." % slots.event,"divine",0.9,{"emotion":"shame","outcome":"lie_exposed"})
			for w in witnesses: GovernmentPeopleSystem.record_person_memory(int((w as Dictionary).person_id),"%s was caught lying to the god about how %s." % [String(person.get("name","")),slots.event],"divine",0.6,{"emotion":"dread","outcome":"witnessed_exposure"})
			var scape:=by_id(String((rec.get("scapegoat",{}) as Dictionary).get("id","")))
			if not scape.is_empty(): _remember(scape,"The god learned that %s had named me falsely." % String(person.get("name","")).get_slice(" ",0))
			beats.append(_beat_official(person,"confess_kin" if String(rec.get("relation",""))=="kin" else "confess_self",slots))
			if not witnesses.is_empty(): beats.append(_beat_official(witnesses[0],"witness_exposed",slots,true))
			_set_focus(rec.get("true_party",{}),String(rec.id))
			result.outcome="%s confessed the lie: %s was responsible when %s, not %s." % [String(person.get("name","")),ref_name(rec.get("true_party",{})),slots.event,slots.named]
		"liar_doubles_down":
			rec["pressed"]=int(rec.get("pressed",0))+1
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.04})
			beats.append(_beat_official(person,"double_down",slots))
			beats.append(_beat_narrator("tell_voice",{"liar":String(person.get("name","")).get_slice(" ",0)}))
			result.outcome=""
	return beats

static func _do_ledger(audience_id:String,result:Dictionary,d:Dictionary)->Array:
	var rec:=active_record(audience_id)
	var slots:={"ledger":ledger_word(),"title":String(GovernmentPeopleSystem.office_definition(String(rec.get("office_key","Steward"))).get("title","keeper")),"named":ref_name(rec.get("named",{})),"event":String((rec.get("event",{}) as Dictionary).get("title","this"))}
	if String(d.get("outcome_id",""))=="ledger_contradicts": _reveal(rec,"ledger")
	result.outcome=String(d.get("words",""))
	return [_beat_narrator(String(d.get("outcome_id","ledger_confirms")),slots)]

# --------------------------------------------------------------------------
# Judgment: every act has bounded, real consequences
# --------------------------------------------------------------------------

static func _metric(key:String,delta:float)->void:
	var m:Dictionary=GameState.simulation_metrics
	m[key]=clampf(float(m.get(key,0.5))+clampf(delta,-0.03,0.03),0.01,0.99)

static func _log(title:String,text:String,severity:String="notice")->void:
	var events:Array=GameState.simulation_events
	events.push_front({"day":_day(),"title":title,"description":text.substr(0,300),"domain":"institutions","severity":severity})
	while events.size()>80: events.pop_back()

static func _do_judge(audience_id:String,action:String,params:Dictionary,result:Dictionary,how:Dictionary)->Array:
	var sref:=speaker_ref(audience_id)
	var target:Dictionary=params.get("target",{}) if params.get("target") is Dictionary and not (params.get("target") as Dictionary).is_empty() else sref
	var p:=by_id(String(target.get("id","")))
	var rec:=active_record(audience_id)
	var name:=String(p.get("name",""))
	var count:=int(p.get("count",1))
	var watchers:=_witnesses(audience_id)
	var slots:=slots_for(ref_of(p))
	var beats:Array=[]
	var stance:=stance_in(rec,ref_of(p))
	var hand:=""
	var effects:Dictionary={}
	match action:
		"execute":
			var n:=mini(count,MAX_GROUP_DEATHS)
			var gone:=GameState.register_population_deaths(n,"Executed at the god's word")
			p["status"]="dead"; p["died_day"]=_day()
			effects=DIVINE.apply_to_court("strike_down",{"person_id":0,"name":name},watchers)
			_metric("legitimacy",-0.01 if stance!="i" else -0.02); _metric("cohesion",-0.005*float(n))
			if stance=="i": rec["executed_innocent"]=true
			_family_grief(p,"was put to death at the god's word")
			result["deaths"]=int(gone.get("count",n))
			result["conclude"]=same_ref(ref_of(p),sref)
			hand="execute"
			result.outcome="%s %s put to death at your word. The court's dread of you deepens." % [name,"were" if count>1 else "was"]
			_log("Put to Death","%s was put to death in the court at the god's word." % name,"major")
		"exile":
			var gone2:=GameState.register_population_departures(mini(count,MAX_GROUP_DEATHS),"Exiled by the god")
			p["status"]="exiled"
			effects=DIVINE.apply_to_court("cast_out",{"person_id":0,"name":name},watchers)
			_metric("cohesion",-0.004)
			_family_grief(p,"was driven out of the realm")
			result["departures"]=int(gone2.get("count",1))
			result["conclude"]=same_ref(ref_of(p),sref)
			hand="exile"
			result.outcome="%s %s driven out of the realm." % [name,"were" if count>1 else "was"]
			_log("Cast Out","%s was driven out of the realm at the god's word." % name)
		"maim":
			p["status"]="living"; p["maimed"]=true
			p["dread"]=clampf(float(p.get("dread",0.2))+0.35,0.0,1.0); p["love"]=clampf(float(p.get("love",0.5))-0.15,0.0,1.0)
			effects=DIVINE.apply_to_court("terrify",{"person_id":0,"name":name},watchers)
			_metric("cohesion",-0.004)
			_remember(p,"At the god's word I was maimed before the court.")
			hand="maim"
			result.outcome="%s was maimed before the court and carried out." % name
		"curse":
			p["cursed"]=true
			p["dread"]=clampf(float(p.get("dread",0.2))+0.25,0.0,1.0); p["love"]=clampf(float(p.get("love",0.5))-0.2,0.0,1.0)
			effects=DIVINE.apply_to_court("terrify",{"person_id":0,"name":name},watchers)
			_metric("cohesion",-0.003)
			_remember(p,"The god cursed me before the court; no hearth will share its fire with me now.")
			hand="curse"
			result.outcome="You cursed %s. Their neighbours will shun their fire." % name
		"make_example":
			p["status"]="living"; p["bound"]=true
			p["dread"]=clampf(float(p.get("dread",0.2))+0.3,0.0,1.0)
			effects=DIVINE.apply_to_court("terrify",{"person_id":0,"name":name},watchers)
			_metric("legitimacy",-0.005)
			_remember(p,"I was bound and shown to the whole camp as the god's example.")
			hand="example"
			result.outcome="%s was bound and shown to the whole camp as a warning." % name
		"exalt":
			p["love"]=clampf(float(p.get("love",0.5))+0.2,0.0,1.0); p["exalted"]=true
			effects=DIVINE.apply_to_court("raise_up",{"person_id":0,"name":name},watchers)
			_importance(p,3.0)
			_remember(p,"The god raised me up before the whole court.")
			hand="exalt"
			result.outcome="%s was raised up and set in a place of honour." % name
		"reward":
			var paid:=Hall._debit_player("Food",minf(12.0*float(mini(count,6)),floorf(Hall.player_stock("Food"))))
			p["love"]=clampf(float(p.get("love",0.5))+0.12,0.0,1.0)
			effects=DIVINE.apply_to_court("boon",{"person_id":0,"name":name},watchers)
			_remember(p,"The god rewarded me from the stores.")
			result["paid"]=paid
			hand="reward"
			result.outcome=("%s was given %d food from the stores." % [name,roundi(paid)]) if paid>0.0 else "%s was praised; the stores had nothing to spare." % name
		"pardon":
			p["love"]=clampf(float(p.get("love",0.5))+0.15,0.0,1.0); p["dread"]=clampf(float(p.get("dread",0.2))-0.1,0.0,1.0)
			p.erase("bound")
			effects=DIVINE.apply_to_court("bless",{"person_id":0,"name":name},watchers)
			if stance=="g": _metric("legitimacy",0.004)
			_remember(p,"The god pardoned me before the court.")
			hand="pardon"
			result.outcome="%s was pardoned and sent home." % name
		"make_priest":
			p["role"]=priest_word(); p["love"]=clampf(float(p.get("love",0.5))+0.2,0.0,1.0)
			effects=DIVINE.apply_to_court("raise_up",{"person_id":0,"name":name},watchers)
			_metric("cohesion",0.004)
			_importance(p,4.0)
			_remember(p,"The god made me %s." % priest_word())
			hand="priest"
			result.outcome="%s now keeps the god's fire as %s." % [name,priest_word()]
		"make_official":
			return _make_official(audience_id,p,String(params.get("office","")),result,watchers)
		"marry_off":
			var rng:=_rng("marry|%s" % String(p.id))
			var sp:=create({"sex":"female" if String(p.get("sex",""))=="male" else "male","trade":_fit_trade([String(p.get("trade","")),"gatherer"]),"settlement_id":String(p.get("settlement_id","")),"note":"The god gave me in marriage to %s." % name})
			var hh:Dictionary=p.get("household",{}) if p.get("household") is Dictionary else {}
			hh["spouse"]={"name":String(sp.given),"alive":true,"known":String(sp.id)}
			p["household"]=hh
			(sp.household as Dictionary)["spouse"]={"name":String(p.given),"alive":true,"known":String(p.id)}
			p["love"]=clampf(float(p.get("love",0.5))+0.05+rng.randf()*0.03,0.0,1.0)
			_metric("cohesion",0.003)
			_remember(p,"The god gave me in marriage to %s." % String(sp.name))
			slots["spouse"]=String(sp.name)
			hand="marry"
			result.outcome="%s is married to %s at your word." % [name,String(sp.name)]
		_:
			if action.begins_with("novel:"):
				return _novel(audience_id,action,p,params,how,result,watchers)
	result["effects"]=effects
	result["witness_ids"]=watchers.map(func(w:Variant)->int: return int((w as Dictionary).get("person_id",0)))
	beats.append(_beat_narrator("judge_"+hand,slots))
	if not action in ["execute","exile"]: beats.append(_beat_known(p,"react_"+hand,slots))
	for w in watchers:
		beats.append(_beat_official(w,"witness_"+hand,slots,true)); break
	if not rec.is_empty(): (rec.get("judged",[]) as Array).append({"ref":ref_of(p),"act":action,"day":_day(),"stance_hidden":stance})
	return beats

static func _family_grief(p:Dictionary,what:String)->void:
	var hh:Dictionary=p.get("household",{}) if p.get("household") is Dictionary else {}
	var sp:Dictionary=hh.get("spouse",{}) if hh.get("spouse") is Dictionary else {}
	if String(sp.get("known",""))!="":
		var other:=by_id(String(sp.known))
		if not other.is_empty(): _remember(other,"My %s %s." % ["husband" if String(p.get("sex",""))=="male" else "wife",what])
	_remember(p,"I %s." % what)

static func _make_official(audience_id:String,p:Dictionary,office:String,result:Dictionary,watchers:Array)->Array:
	## Through GovernmentPeopleSystem: admitted to its people, then appointed
	## by its own rules. An office not yet established becomes honour instead.
	var slots:=slots_for(ref_of(p))
	var beats:Array=[]
	if office=="" or not GovernmentPeopleSystem.office_is_active(office):
		p["exalted"]=true
		result.outcome="No such office stands yet; %s is honoured instead." % String(p.name)
		return [_beat_narrator("judge_exalt",slots),_beat_known(p,"react_exalt",slots)]
	var admitted:=GovernmentPeopleSystem.admit_person({"name":String(p.name),"born_day":int(p.get("born_day",_day()-30*365)),"home_settlement_id":String(p.get("settlement_id","")),
		"courage":float(p.get("courage",0.5)),"honesty":float(p.get("honesty",0.5)),"pride":float(p.get("pride",0.5)),"background":"Raised from the %s by the god's word" % trade_label(String(p.get("trade","")),true)})
	if admitted.is_empty():
		result.outcome="The roll of public people is full; %s is honoured instead." % String(p.name)
		return [_beat_narrator("judge_exalt",slots),_beat_known(p,"react_exalt",slots)]
	var pid:=int(admitted.person_id)
	var former:=GovernmentPeopleSystem.officeholder(office)
	var appointed:=GovernmentPeopleSystem.mark_central_appointment(pid,office)
	if appointed.is_empty():
		p["gps_person_id"]=pid
		result.outcome="%s joins the public people, but cannot hold that office yet." % String(p.name)
		return [_beat_narrator("judge_exalt",slots),_beat_known(p,"react_exalt",slots)]
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":0.1,"obligation":0.1,"respect":0.05})
	GovernmentPeopleSystem.record_person_memory(pid,"I was a %s until the god made me %s before the court." % [trade_label(String(p.get("trade",""))),String(appointed.get("office_title",office))],"divine",0.9,{"emotion":"awe","outcome":"appointed"})
	if not former.is_empty() and int(former.person_id)!=pid:
		GovernmentPeopleSystem.adjust_person_bonds(int(former.person_id),{"resentment":0.1,"respect":-0.04})
		GovernmentPeopleSystem.record_person_memory(int(former.person_id),"The god gave my office to %s, a %s." % [String(p.name),trade_label(String(p.get("trade","")))],"divine",0.7,{"emotion":"shame","outcome":"replaced"})
	p["gps_person_id"]=pid
	p["role"]=String(appointed.get("office_title",office))
	_importance(p,6.0)
	DIVINE.apply_to_court("raise_up",{"person_id":0,"name":String(p.name)},watchers)
	slots["office"]=String(appointed.get("office_title",office))
	result["appointed_pid"]=pid
	result.outcome="%s is now %s by your word.%s" % [String(p.name),String(appointed.get("office_title",office))," %s no longer holds it." % String(former.get("name","")) if not former.is_empty() and int(former.person_id)!=pid else ""]
	_log("Raised to Office","%s, a %s, was made %s by the god's word." % [String(p.name),trade_label(String(p.get("trade",""))),String(appointed.get("office_title",office))])
	beats.append(_beat_narrator("judge_office",slots))
	beats.append(_beat_known(p,"react_exalt",slots))
	for w in watchers:
		beats.append(_beat_official(w,"witness_exalt",slots,true)); break
	return beats

const NOVEL_METRICS:=["legitimacy","cohesion","love","dread"]

static func _novel(_audience_id:String,action:String,p:Dictionary,params:Dictionary,how:Dictionary,result:Dictionary,watchers:Array)->Array:
	## An act the vocabulary has no word for: the model (or a learned choice)
	## proposes bounded deltas; the engine clamps and applies them.
	var deltas:Array=how.get("deltas",[]) if how.get("deltas") is Array else []
	if deltas.is_empty():
		var n:Dictionary=params.get("novel",{}) if params.get("novel") is Dictionary else {}
		deltas=n.get("deltas",[]) if n.get("deltas") is Array else []
	var applied:Array=[]
	for dv in clamp_deltas(deltas):
		var d:Dictionary=dv
		match String(d.metric):
			"legitimacy","cohesion": _metric(String(d.metric),float(d.delta))
			"love": p["love"]=clampf(float(p.get("love",0.5))+float(d.delta)*3.0,0.0,1.0)
			"dread":
				p["dread"]=clampf(float(p.get("dread",0.2))+float(d.delta)*3.0,0.0,1.0)
				if float(d.delta)>0.0: DIVINE.apply_to_court("terrify",{"person_id":0,"name":String(p.name)},watchers)
		applied.append(d)
	var label:=String(params.get("label",(params.get("novel",{}) as Dictionary).get("label",action.trim_prefix("novel:").replace("_"," ")) if params.get("novel") is Dictionary else action.trim_prefix("novel:").replace("_"," ")))
	_remember(p,"At the god's word: %s." % label.substr(0,100))
	result["effects"]={"deltas":applied}
	result.outcome="Done at your word: %s." % label
	return [_beat_narrator("judge_novel",slots_for(ref_of(p)).merged({"act":label}))]

static func clamp_deltas(raw:Array)->Array:
	var out:Array=[]
	for v in raw:
		if out.size()>=4: break
		if not v is Dictionary: continue
		var metric:=String((v as Dictionary).get("metric",""))
		var delta:Variant=(v as Dictionary).get("delta",0.0)
		if not metric in NOVEL_METRICS or not (delta is float or delta is int) or not is_finite(float(delta)): continue
		out.append({"metric":metric,"delta":clampf(float(delta),-0.03,0.03)})
	return out
