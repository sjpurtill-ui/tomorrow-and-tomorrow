extends RefCounted
## COVERT OPERATIONS: spies and assassins, as a statistically consequential
## part of the one world (docs/ADJUDICATION.md). Every people runs the same
## rules in its own scope; only tendencies differ.
##
## An operation is given to an agent who is a real person of ours (a volunteer
## the court finds, or one the god names: "send Kael"). It travels under a
## cover (envoy, trader, pilgrim, refugee, or none), reports or strikes after
## real days on the road, and is adjudicated by stated odds and a seeded roll.
## Nothing is invented: the odds come from access, their guard, our knowledge,
## the agent's skills, distance and the era; the voice only narrates the facts.
##
## OPERATIONS
##   watch        Eyes on a people or a town. Reports arrive after travel and
##                runner days and SHARPEN what we know (city_intelligence.gd):
##                their army and stores, their leaders, their stance, their
##                towns' defences. The War screen's odds and the city dossiers
##                get better estimates, from the same ledger.
##   plant        A standing source left in their town; it sends word until
##                it is caught. (A settled people only: era-gated.)
##   steal        Knowledge theft: a discovery they hold and we lack moves
##                forward for us, bounded and era-appropriate.
##   sabotage     Burn their stores, foul a well, spoil a harvest: a real,
##                bounded hit to their ledger (civilization_exchange.gd).
##   assassinate  Their ruler, a named leader, or "as many of their leaders as
##                he can". A strike kills 1..STRIKE_KILL_CAP, as history bears
##                out; the agent's fate (killed, taken, escaped) is a separate
##                roll, and whether it is traced to us a third.
##
## CONSEQUENCES, bounded and on the same ledgers:
##   - their ruler dead: succession and a leaderless time (rival_rulers._succeed);
##   - traced: a blood feud or war through war_loop.gd, cause in plain words;
##   - envoy sanctity broken (an assassin under an envoy's cover): every
##     people trusts our envoys less, and our envoys are refused for a time
##     (envoys_barred, read by the court's envoy dispatch);
##   - our own people's love and dread of the god shift (divine_regard.gd);
##   - their suspicion and counter-guard rise;
##   - the outcome is credited to the chronicle once, never twice.
##
## COUNTER-INTELLIGENCE, the same rules: rival peoples send spies and assassins
## against us, rarely and only on real business, at rates set by their nature
## and stance. Our watch catches some, at odds from our security, the
## Pathfinder's hand (office_levers.gd) and the watch's size; a caught spy is
## told under the clock and in the chronicle, never as a pop-up, and the god
## decides their fate at court through the ordinary person acts.
##
## State lives in ForeignDiplomacy.audiences["covert"], saved with the court;
## older saves start with an empty ledger. Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const OfficeLevers:=preload("res://scripts/office_levers.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const SCALE_PATH:="res://scripts/conflict_scale.gd"

const KEY:="covert"
const VERSION:=1
const KINDS:=["watch","plant","steal","sabotage","assassinate"]
const COVERS:=["envoy","trader","pilgrim","refugee","none"]
## Newest-first bounds on the saved ledger.
const OPS_MAX:=24
const LEARNED_MAX:=40
const CAUGHT_MAX:=16
const AGENTS_MAX:=48
const INCOMING_MAX:=8
## A strike kills at most this many of their leaders, as history bears out.
const STRIKE_KILL_CAP:=3
## How long envoy sanctity stays broken after an assassin wore an envoy's
## cover, or a traced strike: our envoys are refused and every people trusts
## them less (a season or two).
const SANCTITY_DAYS:=540
## How often the rivals' covert acts are weighed (days): rare, no per-day loop.
const RIVAL_TICK:=20
## A standing source (plant) sends word about this often (days).
const PLANT_REPORT_DAYS:=90
## Runner days a watch report takes to come back once the agent is in place,
## on top of the travel there.
const RUNNER_DAYS_MIN:=6
const RUNNER_DAYS_MAX:=14
## Days a watcher stays before coming home (a short watch; a plant stays on).
const WATCH_STAY_MIN:=20
const WATCH_STAY_MAX:=45

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:covert:%s" % [int(GameState.world_seed),key])
	return rng

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get(KEY)
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed):
		s={"version":VERSION,"world_seed":int(GameState.world_seed),"serial":0,"ops":[],"learned":[],"agents":{},"caught":[],"incoming":[],"next_rival":_day()+RIVAL_TICK,"sanctity_until":-1,"stats":{}}
		holder[KEY]=s
	var d:Dictionary=s
	for key in ["ops","learned","caught","incoming"]:
		if not d.get(key) is Array: d[key]=[]
	for key in ["agents","stats"]:
		if not d.get(key) is Dictionary: d[key]={}
	return d

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	for key in ["ops","learned","caught","incoming"]:
		if not d.get(key,[]) is Array: return false
	if not d.get("agents",{}) is Dictionary or not d.get("stats",{}) is Dictionary: return false
	if (d.get("ops",[]) as Array).size()>OPS_MAX*2 or (d.get("learned",[]) as Array).size()>LEARNED_MAX*2: return false
	if (d.get("caught",[]) as Array).size()>CAUGHT_MAX*2 or (d.get("agents",{}) as Dictionary).size()>AGENTS_MAX*2: return false
	if (d.get("incoming",[]) as Array).size()>INCOMING_MAX*2: return false
	return JSON.stringify(d).length()<=200000

static func _stat(key:String,amount:int=1)->void:
	var stats:Dictionary=state().stats
	stats[key]=int(stats.get(key,0))+amount

static func summary()->Dictionary:
	## Plain numbers for tests and the playtest harness.
	var s:=state()
	var abroad:=0; var struck:=0
	for op in s.ops:
		if String((op as Dictionary).get("stage","")) in ["travelling","in_place"]: abroad+=1
		if String((op as Dictionary).get("stage",""))=="struck": struck+=1
	return {"stats":(s.stats as Dictionary).duplicate(),"ops":(s.ops as Array).size(),"abroad":abroad,"struck":struck,"learned":(s.learned as Array).size(),"caught":(s.caught as Array).size(),"incoming":(s.incoming as Array).size()}

static func forget()->void:
	## For tests: clear the ledger without touching the rest of the save.
	var s:=state()
	s.ops=[]; s.learned=[]; s.caught=[]; s.incoming=[]; s.agents={}; s.stats={}; s.sanctity_until=-1; s.next_rival=_day()+RIVAL_TICK

# --------------------------------------------------------------------------
# Peoples and towns we may act against
# --------------------------------------------------------------------------

static func _war()->GDScript: return load(WAR_LOOP_PATH) as GDScript
static func _rivals()->GDScript: return load(RIVALS_PATH) as GDScript
static func _scale()->GDScript: return load(SCALE_PATH) as GDScript

static func _civ(civ_id:String)->Dictionary:
	var index:=Hall._civ_index(civ_id)
	return WorldSimulation.world.civilizations[index] if index>=0 and WorldSimulation.world!=null else {}

static func _relation(civ_id:String)->Dictionary:
	var civ:=_civ(civ_id)
	return civ.get("player_relation",{}) if not civ.is_empty() else {}

static func _name(civ_id:String)->String:
	return Hall._civ_name(civ_id)

static func _the(civ_id:String)->String:
	var name:=_name(civ_id)
	return name if name.to_lower().begins_with("the ") else "the "+name

## A chart (city_intelligence.gd) for reading and sharpening what we know.
static func _chart()->Variant:
	var world:Variant=WorldSimulation.world
	if world==null or not "city_intelligence" in world: return null
	return world.city_intelligence

# --------------------------------------------------------------------------
# Era gating: what methods the people knows
# --------------------------------------------------------------------------

static func methods(owner:String="player")->Dictionary:
	## What our people can do by stealth, by what they know. Early peoples have
	## no professional spies: a trusted kinsman sent to watch, a knife, poison
	## from known plants. A settled people can leave a standing source; writing
	## brings codes and networks that steal secrets and reach rulers better.
	var tier:=int(CV.era_tier(CV.era_tags(owner)))
	return {
		"watch":true,                 # a trusted kinsman can always be sent to watch
		"plant":tier>=1,              # a standing source needs their town to be settled
		"steal":tier>=1,              # a secret worth stealing needs a craft to steal it from
		"sabotage":true,              # fire and a fouled well need nothing
		"assassinate":true,           # a knife and known poison need nothing
		"tier":tier,
		"networks":tier>=2,           # trained spies, codes, kept sources
	}

static func method_barred(kind:String,owner:String="player")->String:
	var m:=methods(owner)
	if not bool(m.get(kind,false)):
		match kind:
			"plant": return "Our people have no one who could live unseen among a settled people yet."
			"steal": return "There is no craft of theirs we know how to carry off by stealth yet."
	return ""

# --------------------------------------------------------------------------
# Agents: real people of ours, with skills that matter
# --------------------------------------------------------------------------

## An agent's covert skills (0..1), drawn from the real person's skills and
## nature. stealth/cover (reading country, blending), nerve (holding under
## fear), blade (a hand with a weapon), poison (a hand with plants), tongue
## (lies and the carriage of a cover). A kept agent keeps a record and a fate.
static func _skill01(person:Dictionary,key:String,fallback:float=0.47)->float:
	var skills:Dictionary=person.get("skills",{}) if person.get("skills") is Dictionary else {}
	if skills.has(key): return clampf(float(skills[key])/100.0,0.0,1.0)
	return fallback

static func agent_from_person(person:Dictionary,key:String="")->Dictionary:
	## From a government person (skills 0..100, courage/pride 0..1).
	var k:=key if key!="" else ("person:%d" % int(person.get("person_id",0)))
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	return {"key":k,"name":String(person.get("name","")),"given":EraNames.given_of(String(person.get("name",""))),
		"stealth":clampf(_skill01(person,"Logistics")*0.55+_skill01(person,"Knowledge")*0.45,0.05,0.95),
		"nerve":clampf(courage*0.6+_skill01(person,"Defense")*0.4,0.05,0.95),
		"blade":clampf(_skill01(person,"Defense")*0.7+courage*0.3,0.05,0.95),
		"poison":clampf(_skill01(person,"Knowledge")*0.7+_skill01(person,"Provisioning")*0.3,0.05,0.95),
		"tongue":clampf(_skill01(person,"Diplomacy")*0.8+_skill01(person,"Administration")*0.2,0.05,0.95),
		"source":"person","person_id":int(person.get("person_id",0)),"figure_id":"","known_id":""}

static func agent_from_figure(figure:Dictionary)->Dictionary:
	## From a figure of renown (a general's commander skills 0..1, courage).
	var commander:Dictionary=figure.get("commander",{}) if figure.get("commander") is Dictionary else {}
	var resolve:=clampf(float(commander.get("resolve",0.55)),0.0,1.0)
	var tactics:=clampf(float(commander.get("tactics",0.55)),0.0,1.0)
	var logistics:=clampf(float(commander.get("logistics",0.55)),0.0,1.0)
	return {"key":"figure:"+String(figure.get("id","")),"name":String(figure.get("name","")),"given":EraNames.given_of(String(figure.get("name",""))),
		"stealth":clampf(logistics*0.6+tactics*0.4,0.1,0.9),"nerve":clampf(resolve,0.1,0.95),
		"blade":clampf(tactics*0.6+resolve*0.4,0.15,0.95),"poison":clampf(tactics*0.4+logistics*0.2+0.2,0.1,0.8),
		"tongue":clampf(float(commander.get("command",0.5))*0.5+0.25,0.1,0.85),
		"source":"figure","person_id":0,"figure_id":String(figure.get("id","")),"known_id":""}

static func agent_from_known(p:Dictionary)->Dictionary:
	## From a court-known commoner (court_persons.gd: courage/honesty 0..1).
	var courage:=clampf(float(p.get("courage",0.5)),0.0,1.0)
	var honesty:=clampf(float(p.get("honesty",0.5)),0.0,1.0)
	var rng:=_rng("known:%s" % String(p.get("id","")))
	return {"key":String(p.get("id","")),"name":String(p.get("name","")),"given":String(p.get("given","")),
		"stealth":clampf(0.3+courage*0.3+rng.randf()*0.3,0.1,0.9),"nerve":clampf(courage,0.1,0.95),
		"blade":clampf(0.25+courage*0.4+rng.randf()*0.25,0.1,0.9),"poison":clampf(0.2+rng.randf()*0.4,0.05,0.75),
		"tongue":clampf(0.3+(1.0-honesty)*0.4+rng.randf()*0.2,0.1,0.9),
		"source":"known","person_id":0,"figure_id":"","known_id":String(p.get("id",""))}

static func _generate_agent()->Dictionary:
	## A volunteer the court finds when the god names no one: a person drawn
	## from the people, with a stealthy bent. Kept in the ledger for life.
	var s:=state()
	s.serial=int(s.serial)+1
	var serial:=int(s.serial)
	var rng:=_rng("volunteer:%d" % serial)
	var woman:=rng.randf()<0.45
	var owner:=String(WorldSimulation.actor_id) if String(WorldSimulation.actor_id)!="" else "player"
	var identity:Dictionary=EraNames.make(int(GameState.world_seed),40000+serial,woman,owner,_used_names())
	var name:=String(identity.get("name",""))
	if name=="": name=("Quiet one %d" % serial)
	return {"key":"covert:%d" % serial,"name":name,"given":String(identity.get("given",name.get_slice(" ",0))),
		"stealth":clampf(0.5+rng.randf_range(-0.2,0.35),0.15,0.95),"nerve":clampf(0.45+rng.randf_range(-0.2,0.35),0.15,0.95),
		"blade":clampf(0.4+rng.randf_range(-0.25,0.35),0.1,0.9),"poison":clampf(0.35+rng.randf_range(-0.2,0.35),0.05,0.85),
		"tongue":clampf(0.45+rng.randf_range(-0.25,0.35),0.1,0.95),
		"source":"volunteer","person_id":0,"figure_id":"","known_id":""}

static func _used_names()->Dictionary:
	var used:={}
	for key in state().agents:
		used[String((state().agents[key] as Dictionary).get("name",""))]=true
	return used

## The agent the god named ("send Kael"), or {} when nobody of that name is
## known. A name already an agent of ours is reused.
static func resolve_named(given:String)->Dictionary:
	var want:=given.strip_edges().to_lower()
	if want=="": return {}
	for key in state().agents:
		var a:Dictionary=state().agents[key]
		if String(a.get("given","")).to_lower()==want or String(a.get("name","")).to_lower().get_slice(" ",0)==want: return stored_agent(key)
	# An official or settlement leader of ours.
	for person in Hall._officials():
		if String(person.get("name","")).to_lower().get_slice(" ",0)==want: return agent_from_person(person)
	# Anyone on the people's roster.
	for person in GovernmentPeopleSystem.people:
		if person is Dictionary and String((person as Dictionary).get("status",""))=="active" and String((person as Dictionary).get("name","")).to_lower().get_slice(" ",0)==want:
			return agent_from_person(person)
	# A general of renown.
	for f in HistoricalFigures.people:
		if f is Dictionary and String((f as Dictionary).get("status",""))!="dead" and String((f as Dictionary).get("name","")).to_lower().get_slice(" ",0)==want:
			return agent_from_figure(f)
	# A commoner the court already knows (court_persons.gd).
	var persons:=load("res://scripts/court_persons.gd") as GDScript
	if persons!=null:
		for p in persons.call("people"):
			if p is Dictionary and String((p as Dictionary).get("status",""))=="living" and String((p as Dictionary).get("given","")).to_lower()==want:
				return agent_from_known(p)
	return {}

static func volunteer()->Dictionary:
	## The court finds a willing one: the ablest free of office, else a new
	## volunteer from the people. A free hand with the right bent.
	var best:Dictionary={}
	var best_score:=-1.0
	for person in GovernmentPeopleSystem.people:
		if not person is Dictionary or String((person as Dictionary).get("status",""))!="active": continue
		if String((person as Dictionary).get("office_key",""))!="" or String((person as Dictionary).get("local_leader_of",""))!="": continue
		var a:=agent_from_person(person)
		var score:=float(a.stealth)*0.4+float(a.nerve)*0.3+float(a.blade)*0.15+float(a.tongue)*0.15
		if score>best_score: best_score=score; best=a
	if best.is_empty() or best_score<0.5: best=_generate_agent()
	return best

static func stored_agent(key:String)->Dictionary:
	## The kept agent record (fate and deeds), refreshed from the live person
	## when they are one of ours on the roster.
	var kept:Dictionary=state().agents.get(key,{}) if state().agents.get(key) is Dictionary else {}
	if not kept.is_empty(): return kept
	if key.begins_with("person:"):
		var pid:=int(key.trim_prefix("person:"))
		var person:=GovernmentPeopleSystem.person_snapshot(pid)
		if not person.is_empty(): return agent_from_person(person,key)
	return kept

static func record_agent(agent:Dictionary,op_kind:String,civ_id:String,fate:String="")->Dictionary:
	## Keep (or update) an agent in the ledger with their record and fate.
	var s:=state()
	var key:=String(agent.get("key",""))
	if key=="": return {}
	var kept:Dictionary=s.agents.get(key,{}) if s.agents.get(key) is Dictionary else {}
	if kept.is_empty():
		kept=agent.duplicate(true)
		kept["record"]=[]
		kept["fate"]=""
	kept["last_day"]=_day()
	if fate!="": kept["fate"]=fate
	s.agents[key]=kept
	_trim_agents()
	return kept

static func _agent_deed(key:String,text:String)->void:
	var kept:Dictionary=state().agents.get(key,{}) if state().agents.get(key) is Dictionary else {}
	if kept.is_empty(): return
	var record:Array=kept.get("record",[]) if kept.get("record") is Array else []
	record.push_front({"day":_day(),"text":text.substr(0,160)})
	while record.size()>6: record.pop_back()
	kept["record"]=record

static func _trim_agents()->void:
	var s:=state()
	while (s.agents as Dictionary).size()>AGENTS_MAX:
		# Drop a settled fate with the oldest last word first.
		var worst:=""; var worst_day:=1<<62
		for key in s.agents:
			var a:Dictionary=s.agents[key]
			if String(a.get("fate",""))=="" and not _agent_on_op(key): continue
			if _agent_on_op(key): continue
			if int(a.get("last_day",0))<worst_day: worst_day=int(a.get("last_day",0)); worst=key
		if worst=="":
			for key in s.agents: worst=key; break
		if worst=="": break
		(s.agents as Dictionary).erase(worst)

static func _agent_on_op(key:String)->bool:
	for op in state().ops:
		if String((op as Dictionary).get("agent",""))==key and String((op as Dictionary).get("stage","")) in ["travelling","in_place","struck"]: return true
	return false

# --------------------------------------------------------------------------
# Distance and days
# --------------------------------------------------------------------------

static func _home()->Vector2:
	var world:Variant=WorldSimulation.world
	return world.player_world_origin if world!=null else Vector2.ZERO

static func _target_position(civ_id:String,city_id:String)->Vector2:
	var chart:Variant=_chart()
	if chart!=null and city_id!="":
		var known:Dictionary=chart.known("player",city_id)
		if not known.is_empty(): return chart.vector(known.get("position",{}))
	var relation:=_relation(civ_id)
	if relation.has("home_position"): return Vector2(float((relation.home_position as Dictionary).get("x",0.0)),float((relation.home_position as Dictionary).get("z",0.0)))
	var world:Variant=WorldSimulation.world
	return world._civilization_world_position(_civ(civ_id)) if world!=null and not _civ(civ_id).is_empty() else _home()

static func travel_days(civ_id:String,city_id:String)->int:
	## Days on foot to their town: distance at a walking pace, with a floor so
	## even a near neighbour is some days off (sparse-contact rule).
	var at:=_target_position(civ_id,city_id)
	var km:=_home().distance_to(at)
	return clampi(roundi(km/18.0)+4,6,120)

# --------------------------------------------------------------------------
# Odds: stated, from access, guard, knowledge, skills, distance, era
# --------------------------------------------------------------------------

## How wary they are of strangers now: a feud or a war raises their guard, as
## does fresh suspicion from a caught agent of ours.
static func _wariness(civ_id:String)->float:
	var w:=0.15
	var relation:=_relation(civ_id)
	if bool(relation.get("at_war",false)): w+=0.45
	elif bool(_war().call("feuding",civ_id)): w+=0.35
	w+=clampf(float(relation.get("border_tension",0.0)),0.0,1.0)*0.2
	w+=clampf(float(_civ(civ_id).get("_covert_suspicion",0.0)),0.0,1.0)*0.3
	return clampf(w,0.0,0.95)

## How well our scouts and spies already know them (city_intelligence quality,
## freshened by any eyes we have there): better knowledge, better odds.
static func _knowledge(civ_id:String,city_id:String)->float:
	var chart:Variant=_chart()
	if chart==null: return 0.2
	var best:=0.0
	for city in chart.known_cities("player",civ_id,false):
		if city_id!="" and String((city as Dictionary).get("city_id",""))!=city_id: continue
		best=maxf(best,clampf(float((city as Dictionary).get("quality",0.0)),0.0,1.0))
	var eyes:=eyes_on(civ_id)
	if int(eyes.count)>0: best=maxf(best,0.55)
	return clampf(best,0.1,0.9)

## Whether an envoy of ours would be received by them at all: an audience
## only if they would hear our envoys (not refused by war, a hot feud, or a
## broken envoy-sanctity gate of their own). Used for the envoy cover.
static func _would_receive_envoy(civ_id:String)->bool:
	var relation:=_relation(civ_id)
	if int(relation.get("contact_level",0))<1: return false
	if bool(relation.get("at_war",false)): return false
	if bool(_war().call("feuding",civ_id)): return false
	return true

## The access a cover buys: how close it gets the agent (0..1). An envoy is
## received in their hall, so an envoy cover reaches a ruler best — but only
## where envoys are received, and breaking that trust is grave. A trader
## reaches their market; a pilgrim and a refugee pass unremarked but reach no
## inner hall; "none" must slip past the guard unaided.
static func cover_access(cover:String,kind:String,civ_id:String,agent:Dictionary)->float:
	var tongue:=clampf(float(agent.get("tongue",0.5)),0.0,1.0)
	var stealth:=clampf(float(agent.get("stealth",0.5)),0.0,1.0)
	match cover:
		"envoy":
			if not _would_receive_envoy(civ_id): return 0.08+stealth*0.12   # refused: only a sneak-in is left
			return clampf(0.55+tongue*0.35,0.2,0.95)
		"trader":
			return clampf(0.35+tongue*0.3+stealth*0.15,0.15,0.85)
		"pilgrim":
			return clampf(0.3+stealth*0.35,0.15,0.8)
		"refugee":
			return clampf(0.28+stealth*0.4,0.12,0.8)
		_:
			return clampf(0.12+stealth*0.5,0.05,0.75)

## The odds of an operation, stated before it goes. All chances 0..1.
## {access, success, trace, caught, escape, kills_max, days, report_days}.
static func odds(kind:String,civ_id:String,city_id:String,cover:String,agent:Dictionary)->Dictionary:
	var m:=methods()
	var tier:=int(m.tier)
	var wary:=_wariness(civ_id)
	var know:=_knowledge(civ_id,city_id)
	var access:=cover_access(cover,kind,civ_id,agent)
	var stealth:=clampf(float(agent.get("stealth",0.5)),0.0,1.0)
	var nerve:=clampf(float(agent.get("nerve",0.5)),0.0,1.0)
	var blade:=clampf(float(agent.get("blade",0.5)),0.0,1.0)
	var poison:=clampf(float(agent.get("poison",0.5)),0.0,1.0)
	# The Pathfinder's hand runs the eyes abroad; the war leader sharpens a
	# killer's reach (office_levers.gd intrigue edge).
	var edge:=OfficeLevers.intrigue_edge("ChiefScout")
	var kill_edge:=OfficeLevers.intrigue_edge("Marshal")
	var days:=travel_days(civ_id,city_id)
	var report_days:=days+_rng("rep:%s:%s" % [civ_id,city_id]).randi_range(RUNNER_DAYS_MIN,RUNNER_DAYS_MAX)
	var out:={"access":access,"days":days,"report_days":report_days,"kills_max":0,"wary":wary,"know":know,"tier":tier}
	match kind:
		"watch":
			# Getting eyes on them and getting word home: cover and stealth
			# against their guard; the networks of a later people help.
			out["success"]=clampf(access*0.5+stealth*0.3+edge*0.4+float(tier)*0.04-wary*0.35,0.2,0.95)
			out["caught"]=clampf((wary*0.4+(1.0-stealth)*0.25)*(1.0-edge*2.0),0.02,0.5)
		"plant":
			out["success"]=clampf(access*0.4+stealth*0.35+edge*0.4+float(tier)*0.05-wary*0.4,0.15,0.9)
			# A standing source is found in time; wary people find it sooner.
			out["caught"]=clampf(0.08+wary*0.25+(1.0-stealth)*0.15-edge,0.03,0.6)
		"steal":
			out["success"]=clampf(access*0.35+stealth*0.3+know*0.2+edge*0.3+float(tier)*0.05-wary*0.3,0.12,0.85)
			out["caught"]=clampf(0.12+wary*0.3+(1.0-stealth)*0.2-edge,0.04,0.65)
		"sabotage":
			# Reaching the stores or the well and getting away: stealth and
			# nerve against their guard.
			out["success"]=clampf(access*0.35+stealth*0.35+nerve*0.2+edge*0.2-wary*0.3,0.15,0.9)
			out["caught"]=clampf(0.15+wary*0.35+(1.0-stealth)*0.2-edge*0.5,0.05,0.7)
		"assassinate":
			# Getting close enough to strike, then the strike itself. A people
			# wary of us guards its leaders; our knowledge of their hall helps.
			var reach:=clampf(access*0.55+stealth*0.2+know*0.15+kill_edge*0.3-wary*0.4,0.05,0.9)
			var strike:=clampf(0.35+blade*0.3+poison*0.15+nerve*0.2+kill_edge*0.2-wary*0.15,0.2,0.9)
			out["reach"]=reach
			out["success"]=clampf(reach*strike,0.03,0.82)
			out["kills_max"]=STRIKE_KILL_CAP
			# Whether it is traced to us: a struck hall knows an envoy came
			# from us; a quiet poisoning less so. A caught agent may talk.
			out["trace"]=clampf((0.35 if cover=="envoy" else 0.18)+wary*0.3-stealth*0.2,0.05,0.9)
			# The assassin's own fate: an envoy-cover strike in the open hall
			# almost never comes home; a quiet strike has a slim chance.
			out["escape"]=clampf(stealth*0.3+nerve*0.15+(0.0 if cover=="envoy" else 0.15)-reach*0.0,0.02,0.45)
			out["caught"]=clampf(out.success*0.0+0.0,0.0,0.0)  # fate is rolled on the strike, not a separate catch
	return out

# --------------------------------------------------------------------------
# A plain reckoning of the odds, for the official's answer
# --------------------------------------------------------------------------

static func odds_words(chance:float)->String:
	if chance<=0.0: return "no chance"
	if chance>=0.85: return "almost certain"
	if chance>=0.66: return "likely, about 2 in 3"
	if chance>=0.5: return "about even"
	if chance>=0.38: return "about 2 in 5"
	if chance>=0.28: return "about 1 in 3"
	if chance>=0.18: return "about 1 in 5"
	if chance>=0.1: return "about 1 in 8"
	return "a long chance, less than 1 in 10"

# --------------------------------------------------------------------------
# Launching an operation
# --------------------------------------------------------------------------

static func launch(kind:String,civ_id:String,city_id:String,cover:String,agent:Dictionary,target_desc:String="")->Dictionary:
	## Set an operation in motion. Returns the op (with its stated odds), or
	## {"error":...} when it cannot go. Nothing is rolled here; the roll comes
	## when it arrives or strikes, seeded from the op (viewing never re-rolls).
	if not kind in KINDS: return {"error":"unknown operation"}
	if not cover in COVERS: cover="none"
	var barred:=method_barred(kind)
	if barred!="": return {"error":barred}
	if agent.is_empty(): agent=volunteer()
	var s:=state()
	s.serial=int(s.serial)+1
	var serial:=int(s.serial)
	var o:={
		"id":serial,"kind":kind,"civ_id":civ_id,"civ_name":_name(civ_id),"city_id":city_id,"cover":cover,
		"agent":String(agent.get("key","")),"agent_name":String(agent.get("name","")),"agent_given":String(agent.get("given","")),
		"stage":"travelling","start_day":_day(),"arrive_day":_day()+travel_days(civ_id,city_id),
		"target_desc":target_desc.substr(0,80),"seed":"op:%d:%s" % [serial,civ_id],"traced":false,"credited":false,
		"odds":odds(kind,civ_id,city_id,cover,agent),"outcome":{},
	}
	o["report_day"]=int(o.start_day)+int((o.odds as Dictionary).report_days)
	(s.ops as Array).push_front(o)
	while (s.ops as Array).size()>OPS_MAX: (s.ops as Array).pop_back()
	record_agent(agent,kind,civ_id)
	_agent_deed(String(agent.key),"Set out for %s under a %s's cover." % [_the(civ_id),_cover_word(cover)])
	_stat("launched_"+kind)
	return o

static func _cover_word(cover:String)->String:
	return {"envoy":"envoy","trader":"trader","pilgrim":"pilgrim","refugee":"refugee","none":"no"}.get(cover,"no")

# --------------------------------------------------------------------------
# Daily: advance our operations, the rivals', and our watch
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	var s:=state()
	for op in (s.ops as Array).duplicate():
		_advance(op as Dictionary,day)
	_catch_incoming(day)
	if day>=int(s.get("next_rival",day)):
		s["next_rival"]=day+RIVAL_TICK
		_rivals_scheme(day)

static func _advance(op:Dictionary,day:int)->void:
	match String(op.get("stage","")):
		"travelling":
			if day>=int(op.arrive_day): _arrive(op,day)
		"in_place":
			if String(op.kind)=="watch" and day>=int(op.report_day): _watch_report(op,day)
			elif String(op.kind)=="plant" and day>=int(op.get("next_report",op.report_day)): _plant_report(op,day)

static func _arrive(op:Dictionary,day:int)->void:
	## The agent reached them. A strike happens on arrival; eyes settle in.
	var kind:=String(op.kind)
	if kind in ["assassinate","sabotage","steal"]:
		op["stage"]="struck"
		_resolve(op,day)
	else:
		op["stage"]="in_place"
		if kind=="watch": op["report_day"]=day+int((op.odds as Dictionary).get("report_days",10))-int(op.odds.days)
		elif kind=="plant": op["next_report"]=day+PLANT_REPORT_DAYS
		_agent_deed(String(op.agent),"In place among %s." % _the(String(op.civ_id)))

# --------------------------------------------------------------------------
# Watch and plant: reports that sharpen what we know
# --------------------------------------------------------------------------

static func _watch_report(op:Dictionary,day:int)->void:
	var rng:=_rng(String(op.seed)+":watch:%d" % day)
	var odds:Dictionary=op.odds
	var caught:=rng.randf()<float(odds.get("caught",0.1))
	if caught:
		_agent_caught_ours(op,day,"watching")
		return
	_sharpen(String(op.civ_id),String(op.city_id),0.82,day,"our watcher")
	var fact:=_watch_fact(String(op.civ_id),String(op.city_id))
	if fact!="": _learn(String(op.civ_id),fact,day,String(op.agent_name))
	# The watcher comes home after a short stay.
	op["stage"]="done"
	op["outcome"]={"kind":"watched","traced":false}
	record_agent(_op_agent(op),"watch",String(op.civ_id),"home")
	_agent_deed(String(op.agent),"Came home from %s with word." % _the(String(op.civ_id)))
	_stat("watched")

static func _plant_report(op:Dictionary,day:int)->void:
	var rng:=_rng(String(op.seed)+":plant:%d" % day)
	var odds:Dictionary=op.odds
	if rng.randf()<float(odds.get("caught",0.1)):
		_agent_caught_ours(op,day,"a source in their town")
		return
	_sharpen(String(op.civ_id),String(op.city_id),0.86,day,"our source")
	var fact:=_watch_fact(String(op.civ_id),String(op.city_id))
	if fact!="": _learn(String(op.civ_id),fact,day,String(op.agent_name))
	op["next_report"]=day+PLANT_REPORT_DAYS
	_stat("plant_reports")

static func _sharpen(civ_id:String,city_id:String,quality:float,day:int,source:String)->void:
	## Our knowledge of them gets better estimates, through the same chart the
	## War screen and the city dossiers read (city_intelligence.gd).
	var chart:Variant=_chart()
	if chart==null: return
	var ids:Array=[]
	if city_id!="": ids.append(city_id)
	else:
		for city in chart.known_cities("player",civ_id,false): ids.append(String((city as Dictionary).get("city_id","")))
		if ids.is_empty():
			var primary:=String(chart.primary_id(civ_id))
			if primary!="": ids.append(primary)
	for id in ids:
		var observation:Dictionary=chart.capture("player",String(id),quality,day,source,"covert:"+String(id),3)
		if not observation.is_empty(): chart.publish("player",observation,day)

static func _watch_fact(civ_id:String,city_id:String)->String:
	## A concrete fact the report brings, read from the chart we just sharpened.
	var chart:Variant=_chart()
	if chart==null: return ""
	var id:=city_id if city_id!="" else String(chart.primary_id(civ_id))
	if id=="": return ""
	var known:Dictionary=chart.known("player",id)
	if known.is_empty(): return ""
	var name:=String(known.get("name","their town")).trim_prefix("Reported home of ")
	var fields:Dictionary=known.get("fields",{}) if known.get("fields") is Dictionary else {}
	var garrison:Dictionary=fields.get("garrison",{}) if fields.get("garrison") is Dictionary else {}
	var population:Dictionary=fields.get("population",{}) if fields.get("population") is Dictionary else {}
	if not garrison.is_empty():
		return "%s is held by about %d fighters." % [name,roundi((float(garrison.low)+float(garrison.high))*0.5)]
	if not population.is_empty():
		return "About %d people live in %s." % [roundi((float(population.low)+float(population.high))*0.5),name]
	return "We have eyes in %s now." % name

static func _learn(civ_id:String,fact:String,day:int,who:String)->void:
	var s:=state()
	(s.learned as Array).push_front({"day":day,"civ_id":civ_id,"civ_name":_name(civ_id),"fact":fact.substr(0,160),"who":who})
	while (s.learned as Array).size()>LEARNED_MAX: (s.learned as Array).pop_back()

# --------------------------------------------------------------------------
# The adjudicated strike: steal, sabotage, assassinate
# --------------------------------------------------------------------------

static func _resolve(op:Dictionary,day:int)->void:
	var kind:=String(op.kind)
	var rng:=_rng(String(op.seed)+":strike")
	var odds:Dictionary=op.odds
	var success:=rng.randf()<float(odds.get("success",0.3))
	match kind:
		"steal": _resolve_steal(op,day,success,rng)
		"sabotage": _resolve_sabotage(op,day,success,rng)
		"assassinate": _resolve_assassination(op,day,success,rng)

static func _resolve_steal(op:Dictionary,day:int,success:bool,rng:RandomNumberGenerator)->void:
	var civ_id:=String(op.civ_id)
	var caught:=rng.randf()<float((op.odds as Dictionary).get("caught",0.1))
	if success:
		var got:=_steal_secret(civ_id,rng)
		if got!="":
			_learn(civ_id,"Our agent carried off %s's way of %s." % [_name(civ_id),got],day,String(op.agent_name))
			op["outcome"]={"kind":"stole","secret":got,"traced":caught}
			_credit(op,"A Secret Taken from %s" % _name(civ_id),"Our agent slipped %s's way of %s out of their hands; our thinkers take it up." % [_the(civ_id),got],"notice")
			_stat("stole")
		else:
			op["outcome"]={"kind":"nothing","traced":caught}
			_credit(op,"Nothing Worth Taking","Our agent found nothing of %s's that we do not already know." % _the(civ_id),"whisper")
	else:
		op["outcome"]={"kind":"failed","traced":caught}
		_stat("steal_failed")
	_end_strike(op,day,caught,false)

static func _resolve_sabotage(op:Dictionary,day:int,success:bool,rng:RandomNumberGenerator)->void:
	var civ_id:=String(op.civ_id)
	var caught:=rng.randf()<float((op.odds as Dictionary).get("caught",0.1))
	if success:
		var hit:=_apply_sabotage(civ_id,rng)
		op["outcome"]={"kind":"sabotaged","what":hit.what,"amount":hit.amount,"traced":caught}
		_credit(op,"%s's %s" % [_name(civ_id),hit.title],"%s %s" % [_the(civ_id).capitalize(),hit.words],"notice")
		_stat("sabotaged")
	else:
		op["outcome"]={"kind":"failed","traced":caught}
		_stat("sabotage_failed")
	_end_strike(op,day,caught,false)

static func _resolve_assassination(op:Dictionary,day:int,success:bool,rng:RandomNumberGenerator)->void:
	var civ_id:=String(op.civ_id)
	var odds:Dictionary=op.odds
	var killed:=0
	var ruler_dead:=false
	if success:
		# A strike kills 1..STRIKE_KILL_CAP. "As many as he can" reaches the cap
		# more often; a single named target is one.
		var many:="as many" in String(op.target_desc).to_lower() or "leaders" in String(op.target_desc).to_lower()
		var cap:=STRIKE_KILL_CAP if many else 1
		killed=rng.randi_range(1,maxi(1,cap))
		ruler_dead=rng.randf()<(0.8 if many else 0.6)
	# The assassin's fate: killed, taken, or (rarely) escaped. An envoy-cover
	# strike in the open hall almost never comes home.
	var escape:=rng.randf()<float(odds.get("escape",0.1))
	var fate:="escaped" if escape else ("killed" if rng.randf()<0.6 else "taken")
	# Whether it is traced to us (a separate roll); a taken agent may talk,
	# which raises it.
	var trace_chance:=float(odds.get("trace",0.3))
	if fate=="taken": trace_chance=clampf(trace_chance+0.35,0.0,0.97)
	var traced:=rng.randf()<trace_chance
	if String(op.cover)=="envoy": traced=true   # an envoy who turned killer is known for ours
	op["outcome"]={"kind":"struck" if success else "failed","killed":killed,"ruler_dead":ruler_dead,"fate":fate,"traced":traced,"cover":String(op.cover)}
	if success:
		_kill_leaders(civ_id,killed,ruler_dead,op,day)
		_stat("assassinated")
	else:
		_stat("assassination_failed")
	_end_strike(op,day,traced,true)

## A secret we lack that they hold, moved forward for us (bounded).
static func _steal_secret(civ_id:String,rng:RandomNumberGenerator)->String:
	var owner:Variant=load("res://scripts/society_exchange.gd")
	var owner_id:String=String(owner.call("owner_id",civ_id)) if owner!=null else civ_id
	var theirs:Array=[]
	if WorldSimulation.actors.has(owner_id):
		theirs=WorldSimulation.scoped(owner_id,func()->Array: return (WorldSimulation.state.known_discoveries as Array).duplicate())
	if theirs.is_empty():
		# No full actor in scope (a projected rival): read what their people are
		# known to practise (civilization_system discovery_profile.technologies).
		var profile:Dictionary=_civ(civ_id).get("discovery_profile",{}) if _civ(civ_id).get("discovery_profile") is Dictionary else {}
		var technologies:Variant=profile.get("technologies",[])
		if technologies is Array: theirs=(technologies as Array).duplicate()
	var ours:={}
	for id in GameState.known_discoveries: ours[String(id)]=true
	var candidates:Array=[]
	for id in theirs:
		if ours.has(String(id)): continue
		var definition:Dictionary=DiscoverySystem.discovery_definition(String(id))
		if definition.is_empty(): continue
		candidates.append({"id":String(id),"name":String(definition.get("name",String(id).replace("_"," ")))})
	if candidates.is_empty(): return ""
	var pick:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)]
	# Bounded: the secret moves forward, it is not simply ours overnight.
	var id:=String(pick.id)
	var before:=float(GameState.discovery_progress.get(id,0.0))
	GameState.discovery_progress[id]=clampf(maxf(before,0.0)+rng.randf_range(0.45,0.72),0.0,0.98)
	if not id in GameState.research_targets.values():
		DiscoverySystem.select_research_target(id)
	return String(pick.name)

## A real, bounded hit to their ledger. {what, amount, title, words}.
static func _apply_sabotage(civ_id:String,rng:RandomNumberGenerator)->Dictionary:
	var roll:=rng.randf()
	if roll<0.5:
		# Burn their stores.
		var have:=Hall.foreign_stock(civ_id,"Food")
		if have>0.0:
			var burned:=EXCHANGE.take(civ_id,"Food",maxf(10.0,have*rng.randf_range(0.12,0.3)))
			if burned>0.0: return {"what":"stores","amount":roundi(burned),"title":"Stores Burned","words":"lost about %d in food when our agent fired their stores by night." % roundi(burned)}
		_reduce_food_days(civ_id,rng.randf_range(6.0,14.0))
		return {"what":"stores","amount":0,"title":"Stores Burned","words":"found their stores fired in the night; their winter will be the leaner for it."}
	elif roll<0.8:
		# Foul a well: sickness and thirst, and some food spoiled with it.
		var have:=Hall.foreign_stock(civ_id,"Food")
		if have>0.0: EXCHANGE.take(civ_id,"Food",maxf(6.0,have*rng.randf_range(0.06,0.15)))
		_reduce_food_days(civ_id,rng.randf_range(4.0,9.0))
		return {"what":"well","amount":0,"title":"A Well Fouled","words":"found a well fouled; sickness and thirst follow until they dig another."}
	else:
		# Spoil a harvest.
		var have:=Hall.foreign_stock(civ_id,"Food")
		var spoiled:=EXCHANGE.take(civ_id,"Food",maxf(8.0,have*rng.randf_range(0.08,0.2))) if have>0.0 else 0.0
		_reduce_food_days(civ_id,rng.randf_range(5.0,12.0))
		return {"what":"harvest","amount":roundi(spoiled),"title":"A Harvest Spoiled","words":"saw its standing crop spoiled before the reaping; hunger will press them this year."}

static func _reduce_food_days(civ_id:String,days:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	civ["food_days"]=clampf(float(civ.get("food_days",30.0))-days,0.0,180.0)

## Their leaders dead: the ruler's death brings succession and a leaderless
## time; a named leader or others are counted. Bounded to the strike.
static func _kill_leaders(civ_id:String,killed:int,ruler_dead:bool,op:Dictionary,day:int)->void:
	var name:=_name(civ_id)
	var ruler:String=String(_rivals().call("ruler_name",civ_id))
	var title:=""
	var text:=""
	if ruler_dead:
		# Their ruler falls; the heir takes up a shaken people. Their ruler's
		# character is made first (it may never have been needed before), so
		# the succession has a line to pass to (rival_rulers.gd).
		_rivals().call("character",civ_id)
		_rivals().call("_succeed",civ_id,day)
		DIVINE.add_civ_dread(civ_id,0.3)
		title="%s's Chief Is Dead" % name
		text="Our agent struck down %s of %s. %s" % [ruler,name,("Three of their leaders fell before the agent was cut down." if killed>=3 else ("Two of their leaders fell." if killed==2 else "Their people are leaderless for a time."))]
	else:
		DIVINE.add_civ_dread(civ_id,0.2)
		title="A Leader of %s Slain" % name
		text="Our agent killed %s of %s's leaders before being cut down." % [_count_word(killed),name]
	# Their suspicion and counter-guard rise, whatever is traced.
	_raise_suspicion(civ_id,0.4)
	op["outcome"]["title"]=title
	op["outcome"]["text"]=text

static func _count_word(n:int)->String:
	return ["none","one","two","three"][clampi(n,0,3)]

static func _raise_suspicion(civ_id:String,amount:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	civ["_covert_suspicion"]=clampf(float(civ.get("_covert_suspicion",0.0))+amount,0.0,1.0)

# --------------------------------------------------------------------------
# After a strike: fate, trace, consequences, credit once
# --------------------------------------------------------------------------

static func _end_strike(op:Dictionary,day:int,traced:bool,is_kill:bool)->void:
	op["stage"]="done"
	op["traced"]=traced
	var civ_id:=String(op.civ_id)
	var fate:=String((op.outcome as Dictionary).get("fate","escaped")) if is_kill else ("home" if not traced else "traced")
	record_agent(_op_agent(op),String(op.kind),civ_id,fate if is_kill else ("home" if not traced else "caught"))
	# The deed on the agent's record.
	if is_kill:
		var o:Dictionary=op.outcome
		if String(o.kind)=="struck":
			_agent_deed(String(op.agent),"Struck down %s of %s's leaders; %s." % [_count_word(int(o.killed)),_name(civ_id),{"killed":"cut down in the hall","taken":"taken alive","escaped":"slipped away home"}.get(String(o.fate),"gone")])
		else:
			_agent_deed(String(op.agent),"Could not reach %s's leaders; %s." % [_name(civ_id),{"killed":"cut down","taken":"taken alive","escaped":"came home"}.get(String(o.fate),"gone")])
	# Envoy sanctity broken: an assassin under an envoy's cover, or any traced
	# killing of leaders. Every people trusts our envoys less for a time, and
	# our envoys are refused.
	if is_kill and (String(op.cover)=="envoy" or traced):
		_break_envoy_sanctity(day,String(op.cover)=="envoy")
	# Traced to us: a blood feud or war, with the cause in plain words.
	if traced and (is_kill or String((op.outcome as Dictionary).get("kind",""))=="sabotaged"):
		_feud_or_war(op,day,is_kill)
	# Our own people's love and dread shift: a killing by stealth is a dread
	# act of the god; a traced one that brings war more so.
	if is_kill and String((op.outcome as Dictionary).get("kind",""))=="struck":
		DIVINE.record_people_act("terrify_people" if String(op.cover)=="envoy" or traced else "harsh_law")
	# Credit the outcome once.
	if is_kill:
		var o2:Dictionary=op.outcome
		if String(o2.kind)=="struck":
			_credit(op,String(o2.get("title","A Strike Abroad")),String(o2.get("text",""))+_fate_tail(op),"moment")
		else:
			_credit(op,"A Strike That Failed","Our agent could not reach %s's leaders, and %s." % [_the(civ_id),{"killed":"was cut down","taken":"was taken alive","escaped":"came home empty-handed"}.get(String(o2.get("fate","")),"is gone")],"notice")

static func _fate_tail(op:Dictionary)->String:
	var fate:=String((op.outcome as Dictionary).get("fate",""))
	var traced:=bool(op.traced)
	var who:=String(op.agent_given) if String(op.agent_given)!="" else "the agent"
	match fate:
		"killed": return " %s was cut down in the hall." % who.capitalize()
		"taken": return " %s was taken alive%s." % [who,"; under their hands, the deed is laid at our door" if traced else ""]
		"escaped": return " %s slipped away and is coming home." % who
	return ""

static func _break_envoy_sanctity(day:int,by_envoy:bool)->void:
	var s:=state()
	s["sanctity_until"]=maxi(int(s.get("sanctity_until",-1)),day+SANCTITY_DAYS)
	# Every people we know trusts our envoys less and watches us warily.
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or String((civ as Dictionary).get("id",""))=="player": continue
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<1: continue
		rel["opinion"]=clampf(float(rel.get("opinion",0.0))-0.1,-1.0,1.0)
		rel["border_tension"]=clampf(float(rel.get("border_tension",0.0))+0.15,0.0,1.0)
		DIVINE.add_civ_dread(String((civ as Dictionary).get("id","")),0.08)
	_stat("envoy_sanctity_broken")
	if by_envoy:
		_credit_plain("The Sanctity of Envoys Broken","Word runs among every people we know: an envoy of ours carried a knife. No ruler will receive our envoys now, and none will trust them for a long while.","moment",day)

## Whether our envoys are refused now (the court's envoy dispatch reads this).
static func envoys_barred()->bool:
	return _day()<int(state().get("sanctity_until",-1))

static func sanctity_days_left()->int:
	return maxi(0,int(state().get("sanctity_until",-1))-_day())

static func _feud_or_war(op:Dictionary,day:int,is_kill:bool)->void:
	var civ_id:=String(op.civ_id)
	var cause:=_cause_words(op,is_kill)
	# A people organised for war answers with war; a smaller one with a blood
	# feud (war_loop.gd keeps the distinction). The war leader carries it.
	if _scale().call("formal",civ_id):
		_war().call("declare",civ_id,day,cause)
	else:
		_war().call("blood_feud",civ_id,day,cause,"","covert")
	_raise_suspicion(civ_id,0.3)

static func _cause_words(op:Dictionary,is_kill:bool)->String:
	var civ_id:=String(op.civ_id)
	if is_kill:
		var o:Dictionary=op.outcome
		if bool(o.get("ruler_dead",false)):
			return "the murder of their chief by our %s" % _cover_word(String(op.cover))
		return "the murder of their leaders by our %s" % _cover_word(String(op.cover))
	return "our agent's hand in the ruin of their stores"

# --------------------------------------------------------------------------
# A caught agent of ours
# --------------------------------------------------------------------------

static func _agent_caught_ours(op:Dictionary,day:int,doing:String)->void:
	var rng:=_rng(String(op.seed)+":caught:%d" % day)
	var talks:=rng.randf()<clampf(0.4-float(_op_agent(op).get("nerve",0.5))*0.3,0.05,0.5)
	op["stage"]="done"
	op["traced"]=talks
	op["outcome"]={"kind":"caught","talks":talks,"doing":doing,"traced":talks}
	record_agent(_op_agent(op),String(op.kind),String(op.civ_id),"caught")
	_agent_deed(String(op.agent),"Caught %s among %s%s." % [doing,_the(String(op.civ_id)),"; broke and named us" if talks else "; gave nothing up"])
	_raise_suspicion(String(op.civ_id),0.3)
	if talks: _feud_or_war(op,day,false)
	_credit(op,"%s Caught%s" % [String(op.agent_name),(" — and Talked" if talks else "")],
		"%s was caught %s among %s%s." % [String(op.agent_name),doing,_the(String(op.civ_id)),"; under their hands they named us, and the blood is on our road now" if talks else "; they gave nothing away"],"notice")
	_stat("ours_caught")

static func _op_agent(op:Dictionary)->Dictionary:
	var kept:=stored_agent(String(op.agent))
	if not kept.is_empty(): return kept
	return {"key":String(op.agent),"name":String(op.agent_name),"given":String(op.agent_given),"nerve":0.5}

# --------------------------------------------------------------------------
# Crediting the chronicle once
# --------------------------------------------------------------------------

static func _credit(op:Dictionary,title:String,text:String,tier:String)->void:
	if bool(op.get("credited",false)): return
	op["credited"]=true
	_credit_plain(title,text,tier,_day())

static func _credit_plain(title:String,text:String,tier:String,day:int)->void:
	Chronicle.record({"key":"covert:%d:%s" % [day,title.substr(0,24)],"title":title.substr(0,70),"text":text,"tier":tier,"kind":"court","domain":"security","action":{"kind":"section","section":"military"}})

# --------------------------------------------------------------------------
# Rivals run the same rules against us; our watch catches some
# --------------------------------------------------------------------------

static func _rivals_scheme(day:int)->void:
	## Rare, and only on real business: a people wary of us, in a feud or war,
	## or with a grudge, may send a spy or (rarer) an assassin. Tendencies
	## only; most peoples send nobody.
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or String((civ as Dictionary).get("id",""))=="player": continue
		var civ_id:=String((civ as Dictionary).get("id",""))
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<2: continue
		var chance:=_rival_scheme_chance(civ_id,rel)
		if chance<=0.0: continue
		var rng:=_rng("rival:%s:%d" % [civ_id,day])
		if rng.randf()>=chance: continue
		var kind:="assassinate" if (bool(rel.get("at_war",false)) or bool(_war().call("feuding",civ_id))) and rng.randf()<0.2 else "watch"
		var arrive:=day+travel_days(civ_id,"")
		var s:=state()
		(s.incoming as Array).push_front({"civ_id":civ_id,"civ_name":_name(civ_id),"kind":kind,"start_day":day,"arrive_day":arrive,"seed":"rival:%s:%d" % [civ_id,day]})
		while (s.incoming as Array).size()>INCOMING_MAX: (s.incoming as Array).pop_back()
		_stat("rival_sent")

static func _rival_scheme_chance(civ_id:String,rel:Dictionary)->float:
	## The rate a people schemes against us, per RIVAL_TICK: rare, raised by a
	## grudge, a feud or a war, and by their ruler's cunning.
	var base:=0.0
	if bool(rel.get("at_war",false)): base+=0.35
	elif bool(_war().call("feuding",civ_id)): base+=0.22
	var character:Dictionary=_rivals().call("rival_character",civ_id)
	base+=clampf(float(character.get("grudge_weight",0.0)),0.0,1.5)*0.12
	if String(character.get("trait",""))=="grudge": base+=0.06
	base+=clampf(float(rel.get("border_tension",0.0)),0.0,1.0)*0.08
	return clampf(base,0.0,0.6)

static func _catch_incoming(day:int)->void:
	var s:=state()
	for spy in (s.incoming as Array).duplicate():
		var sp:Dictionary=spy
		if day<int(sp.arrive_day): continue
		(s.incoming as Array).erase(spy)
		var rng:=_rng(String(sp.seed)+":catch")
		# Our watch catches some, by our security, the Pathfinder's hand and
		# the share we keep on the watch.
		if rng.randf()<_catch_chance():
			(s.caught as Array).push_front({"day":day,"civ_id":String(sp.civ_id),"civ_name":String(sp.civ_name),"kind":String(sp.kind),"fate":""})
			while (s.caught as Array).size()>CAUGHT_MAX: (s.caught as Array).pop_back()
			_stat("caught_theirs")
			_credit_plain("A Spy of %s Caught" % String(sp.civ_name),
				"Our watch took %s of %s's%s in our town." % [("an assassin" if String(sp.kind)=="assassinate" else "a spy"),_the(String(sp.civ_id)),""],"notice",day)
		elif String(sp.kind)=="assassinate":
			# An assassin our watch missed: a bounded attempt on us, mostly foiled.
			_stat("theirs_struck")
			_credit_plain("An Assassin Slipped In","An assassin of %s reached our court before being cut down; the god was unharmed." % _the(String(sp.civ_id)),"notice",day)
		else:
			_stat("theirs_watched")

static func _catch_chance()->float:
	## Our security against a slipped-in agent: the Pathfinder's hand, the
	## share of our people on the watch, and our cohesion.
	var edge:=OfficeLevers.intrigue_edge("ChiefScout")
	var watch:=clampf(float(GameState.population_allocations.get("Defense",0))/maxf(1.0,float(GameState.population_exact)*0.08),0.0,1.0)
	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.5)),0.0,1.0)
	return clampf(0.25+edge*2.0+watch*0.3+cohesion*0.2,0.1,0.9)

static func set_caught_fate(index:int,fate:String)->void:
	var caught:Array=state().caught
	if index>=0 and index<caught.size(): (caught[index] as Dictionary)["fate"]=fate

# --------------------------------------------------------------------------
# Reads for the court and the dashboard
# --------------------------------------------------------------------------

static func agents_abroad()->Array:
	## Our agents out now: name, cover, where, mission, days out, last word,
	## risk now.
	var out:Array=[]
	var day:=_day()
	for op in state().ops:
		var o:Dictionary=op
		if not String(o.get("stage","")) in ["travelling","in_place","struck"]: continue
		var odds:Dictionary=o.get("odds",{})
		out.append({"name":String(o.agent_name),"cover":String(o.cover),"kind":String(o.kind),"civ_id":String(o.civ_id),"civ_name":String(o.civ_name),
			"where":String(o.civ_name),"days_out":maxi(0,day-int(o.start_day)),"stage":String(o.stage),
			"last_word":_op_last_word(o,day),"risk":clampf(float(odds.get("caught",odds.get("trace",0.2))),0.0,1.0),"target":String(o.target_desc)})
	return out

static func _op_last_word(op:Dictionary,day:int)->String:
	match String(op.get("stage","")):
		"travelling": return "on the road, %d days to %s" % [maxi(0,int(op.arrive_day)-day),_the(String(op.civ_id))]
		"in_place":
			if String(op.kind)=="watch": return "watching; word back in %d days" % maxi(0,int(op.report_day)-day)
			if String(op.kind)=="plant": return "a source in their town; word every %d days" % PLANT_REPORT_DAYS
			return "in place"
		"struck": return "the blow is struck"
	return ""

static func learned(limit:int=8)->Array:
	## What our spies learned, as concrete facts with their age.
	var out:Array=[]
	var day:=_day()
	for f in state().learned:
		out.append({"fact":String((f as Dictionary).fact),"civ_name":String((f as Dictionary).civ_name),"age_days":maxi(0,day-int((f as Dictionary).day)),"who":String((f as Dictionary).get("who",""))})
		if out.size()>=limit: break
	return out

static func outcomes(limit:int=8)->Array:
	## Operations' outcomes, newest first, for the board.
	var out:Array=[]
	var day:=_day()
	for op in state().ops:
		var o:Dictionary=op
		if String(o.get("stage",""))!="done": continue
		var outcome:Dictionary=o.get("outcome",{})
		out.append({"kind":String(o.kind),"civ_name":String(o.civ_name),"agent":String(o.agent_name),"age_days":maxi(0,day-int(o.get("report_day",o.start_day))),
			"result":String(outcome.get("kind","")),"line":_outcome_line(o),"traced":bool(o.get("traced",false))})
		if out.size()>=limit: break
	return out

static func _outcome_line(op:Dictionary)->String:
	var o:Dictionary=op.outcome
	var civ:=String(op.civ_name)
	match String(o.get("kind","")):
		"struck":
			var fate:String=String({"killed":"cut down","taken":"taken alive","escaped":"came home"}.get(String(o.get("fate","")),"gone"))
			return "%s struck %s of %s's leaders%s · %s%s" % [String(op.agent_name),_count_word(int(o.get("killed",0))),civ,"; their chief is dead" if bool(o.get("ruler_dead",false)) else "",fate,"; traced to us" if bool(o.traced) else ""]
		"stole": return "%s carried off %s's %s" % [String(op.agent_name),civ,String(o.get("secret",""))]
		"sabotaged": return "%s struck %s's %s" % [String(op.agent_name),civ,String(o.get("what",""))]
		"watched": return "%s brought word from %s" % [String(op.agent_name),civ]
		"caught": return "%s caught among %s%s" % [String(op.agent_name),civ,"; talked" if bool(o.get("talks",false)) else ""]
		"failed": return "%s could not do it among %s" % [String(op.agent_name),civ]
		"nothing": return "%s found nothing worth taking from %s" % [String(op.agent_name),civ]
	return "%s · %s" % [String(op.agent_name),civ]

static func caught_spies(limit:int=8)->Array:
	## Their spies our watch caught, newest first.
	var out:Array=[]
	var day:=_day()
	for c in state().caught:
		out.append({"civ_name":String((c as Dictionary).civ_name),"civ_id":String((c as Dictionary).civ_id),"kind":String((c as Dictionary).kind),"age_days":maxi(0,day-int((c as Dictionary).day)),"fate":String((c as Dictionary).get("fate",""))})
		if out.size()>=limit: break
	return out

static func op_by_id(id:int)->Dictionary:
	for op in state().ops:
		if int((op as Dictionary).get("id",0))==id: return op
	return {}

## The order card's reading of an operation (order_probes.gd): how it stands,
## in plain words, from the op itself.
static func op_card(id:int)->Dictionary:
	var op:=op_by_id(id)
	if op.is_empty(): return {"state":"stalled","line":"The venture is no more","progress":0.0,"moved":true}
	var day:=_day()
	match String(op.get("stage","")):
		"travelling":
			var left:=maxi(0,int(op.arrive_day)-day)
			return {"state":"under_way","line":"%s on the road to %s · %d days" % [String(op.agent_name),_the(String(op.civ_id)),left],"value":maxi(0,day-int(op.start_day)),"total":maxi(1,int(op.arrive_day)-int(op.start_day)),"progress":float(day-int(op.start_day)),"moved":true}
		"in_place":
			if String(op.kind)=="plant": return {"state":"under_way","line":"%s is a source in %s · word every %d days" % [String(op.agent_name),_the(String(op.civ_id)),PLANT_REPORT_DAYS],"progress":1.0,"moved":true,"standing":true}
			return {"state":"under_way","line":"%s watching %s · word back in %d days" % [String(op.agent_name),_the(String(op.civ_id)),maxi(0,int(op.get("report_day",day))-day)],"progress":1.0,"moved":true}
		"struck":
			return {"state":"under_way","line":"%s has struck; word is awaited" % String(op.agent_name),"progress":1.5,"moved":true}
		"done":
			return {"state":"done","line":_outcome_line(op),"progress":2.0,"moved":true}
	return {"state":"accepted","line":"%s sets out" % String(op.agent_name),"progress":0.0}

static func eyes_on(civ_id:String)->Dictionary:
	## Our agents abroad in this people's lands, and how fresh their word is,
	## for the War screen's enemy row.
	var count:=0
	var last:=1<<30
	var day:=_day()
	for op in state().ops:
		var o:Dictionary=op
		if String(o.civ_id)!=civ_id or not String(o.get("stage","")) in ["in_place","travelling"]: continue
		if String(o.kind) in ["watch","plant"]:
			count+=1
			var word:=int(o.get("next_report",o.get("report_day",o.start_day)))
			last=mini(last,maxi(0,day-int(o.start_day)))
	# How long since any fact came from them.
	var last_word:=-1
	for f in state().learned:
		if String((f as Dictionary).civ_id)==civ_id: last_word=maxi(0,day-int((f as Dictionary).day)); break
	return {"count":count,"last_word_days":last_word}

# --------------------------------------------------------------------------
# Court questions: "what have our spies learned?", caught spies
# --------------------------------------------------------------------------

## Recent covert news for the alert row under the clock (hud/army_alerts.gd):
## an agent caught or killed, a strike done, their spy caught. Shaped for the
## alert marks; they go under the clock and the chronicle, never a pop-up.
const ALERT_DAYS:=12
static func alerts(day:int=-1)->Array:
	if day<0: day=_day()
	var out:Array=[]
	var theirs:PackedStringArray=PackedStringArray()
	for c in state().caught:
		if day-int((c as Dictionary).day)<=ALERT_DAYS: theirs.append("%s of %s taken in our town" % [("an assassin" if String((c as Dictionary).kind)=="assassinate" else "a spy"),_the(String((c as Dictionary).civ_id))])
	if not theirs.is_empty(): out.append({"id":"covert_caught","war":"feud","tone":"amber","count":theirs.size(),"title":"Spies of theirs caught","lines":theirs,"page":"wars"})
	var ours:PackedStringArray=PackedStringArray()
	var red:=false
	for op in state().ops:
		var o:Dictionary=op
		if String(o.get("stage",""))!="done" or day-int(o.get("report_day",o.start_day))>ALERT_DAYS: continue
		var outcome:Dictionary=o.get("outcome",{})
		match String(outcome.get("kind","")):
			"struck": ours.append("%s struck %s's leaders" % [String(o.agent_name),_name(String(o.civ_id))]); red=true
			"caught": ours.append("%s caught among %s" % [String(o.agent_name),_the(String(o.civ_id))]); red=true
			"sabotaged": ours.append("%s struck %s's %s" % [String(o.agent_name),_name(String(o.civ_id)),String(outcome.get("what",""))])
			"stole": ours.append("%s carried off a secret of %s" % [String(o.agent_name),_name(String(o.civ_id))])
	if not ours.is_empty(): out.append({"id":"covert_done","war":"band","tone":"red" if red else "amber","count":ours.size(),"title":"Our agents abroad","lines":ours,"page":"wars"})
	return out

static func is_covert_question(text:String)->bool:
	var re:=RegEx.create_from_string("(?i)\\b(spy|spies|agent|agents|assassin|assassins|our eyes|spying|informant|informants|saboteur)\\b")
	return re.search(text)!=null

static func answer(text:String)->String:
	## A plain answer from the covert ledger, "" when the words ask nothing it
	## holds. (court_facts hands factual covert questions here.)
	var lower:=text.to_lower()
	if not is_covert_question(text): return ""
	# Caught spies of theirs.
	if RegEx.create_from_string("(?i)\\b(caught|catch|taken|found|took)\\b").search(lower)!=null and RegEx.create_from_string("(?i)\\b(spy|spies|agent|assassin|their|them|theirs)\\b").search(lower)!=null:
		var caught:=caught_spies(6)
		if caught.is_empty(): return "We have caught no spies of theirs in our towns."
		var bits:PackedStringArray=PackedStringArray()
		for c:Dictionary in caught: bits.append("%s of %s%s, %s" % [("an assassin" if String(c.kind)=="assassinate" else "a spy"),c.civ_name,(" (%s)" % c.fate) if String(c.fate)!="" else "",_since(int(c.age_days))])
		return "Our watch has taken %s." % _join(bits)
	# Our agents abroad and what they learned.
	var abroad:=agents_abroad()
	var facts:=learned(5)
	if abroad.is_empty() and facts.is_empty():
		return "No one of ours is abroad in secret, and our spies have brought back nothing yet."
	var parts:PackedStringArray=PackedStringArray()
	if not abroad.is_empty():
		var who:PackedStringArray=PackedStringArray()
		for a:Dictionary in abroad: who.append("%s among %s (%s)" % [String(a.name),String(a.civ_name),String(a.last_word)])
		parts.append("Abroad for us: %s." % _join(who))
	if not facts.is_empty():
		var said:PackedStringArray=PackedStringArray()
		for f:Dictionary in facts: said.append("%s (%s)" % [String(f.fact),_since(int(f.age_days))])
		parts.append("What they have sent back: %s" % " ".join(said))
	return " ".join(parts)

static func _join(bits:PackedStringArray)->String:
	if bits.is_empty(): return "nothing"
	if bits.size()==1: return bits[0]
	return ", ".join(bits.slice(0,bits.size()-1))+" and "+bits[-1]

static func _since(age_days:int)->String:
	if age_days<=0: return "today"
	if age_days==1: return "yesterday"
	if age_days<14: return "%d days ago" % age_days
	if age_days<60: return "%d weeks ago" % maxi(1,roundi(age_days/7.0))
	return "%d months ago" % maxi(1,roundi(age_days/30.0))
