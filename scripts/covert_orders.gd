extends RefCounted
## COVERT ORDERS SPOKEN AT COURT. "Send spies to Ruvak", "find out what they
## plan", "steal their secret of ironwork", "burn their granary by stealth",
## "poison their chief", and the god's own line: "Send an assassin to Ruvak
## disguised as an envoy. Let them get close enough to stick a dagger into the
## heart of ruvaks leaders, as many of them as he can before being killed."
##
## A covert order never becomes a flat march question. It becomes a real,
## adjudicated operation (covert_ops.gd) with stated odds and a seeded roll,
## or an honest refusal. The right official answers in character: the
## Pathfinder is the eyes abroad; the war leader carries a killing or a
## sabotage; and an envoy cover is the Messenger's envoys, whose sanctity is
## grave to break. They state the odds in plain numbers, may object on the
## facts, and the god can insist ("do it anyway").
##
## read()    the words -> {kind, civ_id, city_id, cover, agent?, target_desc,
##           insist} or {}. Only fires on a covert cue (cue()), so a plain
##           raid ("burn their stores") or scout party ("send scouts north")
##           is never taken for a covert act.
## perform() the official weighs it and launches the operation, objects with
##           the real cost, or says plainly why not. Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

## A covert cue must be present, or these are ordinary words.
const CUE:="(?i)\\b(spy|spies|spying|spied|assassin|assassins|assassinate|assassinated|saboteur|sabotage|sabotaged|infiltrat\\w*|informant|informants|disguis\\w*|secretly|in secret|under cover|poison(ed|s|er)?|dagger|slip (into|in among)|sneak (into|in)|steal (their|the enemy'?s|ruvak'?s|[a-z]+'?s) (secret|secrets|knowledge|craft|way|ways|art)|foul (a|the|their|its) (well|wells|water)|spoil (their|the|its) (harvest|crop|crops)|eyes (in|on|among)|find out what (they|the \\w+) (plan|planning|have|hold|intend|are doing)|learn what (they|the \\w+) (plan|planning|intend))\\b"
## How the agent travels among them.
const COVER_WORDS:={
	"envoy":"(?i)\\b(envoy|envoys|herald|heralds|messenger|ambassador|emissary|a flag of truce|peace envoy)\\b",
	"trader":"(?i)\\b(trader|traders|merchant|merchants|peddler|a trade caravan|trading party|a trader'?s)\\b",
	"pilgrim":"(?i)\\b(pilgrim|pilgrims|holy (man|woman)|a wanderer|a seer)\\b",
	"refugee":"(?i)\\b(refugee|refugees|a fugitive|fleeing our|seeking shelter|one who has fled)\\b",
}
## The verbs of each operation, checked assassinate -> sabotage -> steal ->
## plant -> watch (so "a spy to kill their chief" is a killing, not a watch).
const ASSASSINATE:="(?i)(assassin|assassinate|murder|slay|stab|dagger|poison (their|the|its|ruvak'?s)? ?(chief|chieftain|ruler|king|queen|leader|leaders|elders|headman|lord)|stick (a|the) (dagger|knife|blade)|slit (their|the) throats?|put (their|the) (chief|ruler|leaders?) to (death|the sword)|do away with (their|the) (chief|ruler|leader)|have (their|the) (chief|ruler|leaders?|king) killed|kill (their|the|ruvak'?s|[a-z]+'?s) (chief|chieftain|ruler|king|queen|leader|leaders|elders|headman|lords?))"
const SABOTAGE:="(?i)(sabotage|saboteur|foul (a|the|their|its) (well|wells|water)|poison (a|the|their|its) (well|wells|water|crops?|harvest|grain|food)|spoil (their|the|its) (harvest|crop|crops|grain)|wreck (their|the|its)|burn (their|the|its) (granar\\w+|stores?|wells?|harvest|barns?|carts?))"
const STEAL:="(?i)(steal|take|carry off|make off with) (their|the enemy'?s|ruvak'?s|[a-z]+'?s|its)? ?(secret|secrets|knowledge|craft|crafts|way|ways|art|arts)"
const PLANT:="(?i)(plant|leave|place|keep) (a|an|one|our)? ?(spy|agent|source|informant|watcher|ear|eye)s? (among|in|inside|with|within)|a (standing|lasting|kept) (spy|source|agent|ear)"
const WATCH:="(?i)(spy on|spy out|send (a |our |some )?(spy|spies)|send (someone|a man|a woman|one of ours) to (spy|watch)|watch what|watch (the|their)|keep (an? )?(eye|eyes|watch) on|find out what (they|the \\w+)|learn what (they|the \\w+) (plan|intend)|scout (them|their|the \\w+) (out )?secretly|eyes (in|on|among))"

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func cue(text:String)->bool:
	return _re(CUE).search(text)!=null

# --------------------------------------------------------------------------
# Reading the words
# --------------------------------------------------------------------------

## The peoples and towns a covert order could name.
static func _peoples()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or String((civ as Dictionary).get("id",""))=="player": continue
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<1 and not bool(rel.get("at_war",false)): continue
		out.append({"civ_id":String((civ as Dictionary).get("id","")),"name":String((civ as Dictionary).get("name",""))})
	return out

static func _match_target(text:String)->Dictionary:
	## A town we know (held or not) first, then a people, by name.
	var lower:=text.to_lower()
	for t:Dictionary in WarOrders.held_towns()+WarOrders.known_places():
		var name:=String(t.get("name","")).trim_prefix("Reported home of ")
		if name!="" and _re("\\b"+_escape(name.to_lower())+"\\b").search(lower)!=null:
			return {"kind":"town","civ_id":String(t.get("civ_id","")),"city_id":String(t.get("city_id","")),"name":name}
	for p:Dictionary in _peoples():
		var name2:=String(p.name)
		var bare:=name2.to_lower().trim_prefix("the ")
		if bare!="" and _re("\\b"+_escape(bare)+"\\b").search(lower)!=null:
			return {"kind":"people","civ_id":String(p.civ_id),"city_id":"","name":name2}
	return {}

static func _escape(text:String)->String:
	var out:=""
	for ch in text: out+=("\\"+ch) if ch in ".^$*+?()[]{}|\\-/" else ch
	return out

static func _cover(text:String)->String:
	for cover in ["envoy","trader","pilgrim","refugee"]:
		if _re(String(COVER_WORDS[cover])).search(text)!=null: return cover
	return "none"

static func _kind(text:String)->String:
	if _re(ASSASSINATE).search(text)!=null: return "assassinate"
	if _re(SABOTAGE).search(text)!=null: return "sabotage"
	if _re(STEAL).search(text)!=null: return "steal"
	if _re(PLANT).search(text)!=null: return "plant"
	if _re(WATCH).search(text)!=null: return "watch"
	# A cue with no clear verb, but a target and a covert word: eyes on them.
	if cue(text): return "watch"
	return ""

## A named agent ("send Kael", "have Kael do it"): the given name, or "".
static func _named_agent(text:String)->String:
	var m:=_re("(?i)\\b(send|have|let|use|put|tell|choose|take)\\s+(?<who>(?-i:[A-Z])[\\w'-]+)\\b").search(text)
	if m==null: return ""
	var who:=m.get_string("who")
	# Not a cover word or a people's name.
	if who.to_lower() in ["an","a","our","the","them","him","her","someone","a man","a woman","spies","spy","word","envoys"]: return ""
	for p:Dictionary in _peoples():
		if who.to_lower()==String(p.name).to_lower().trim_prefix("the "): return ""
	return who

static func read(text:String,_civ_hint:String="",_audience_id:String="")->Dictionary:
	## {} unless a covert cue is present and a covert operation can be read.
	var clean:=text.strip_edges()
	if clean=="" or clean.ends_with("?"): return {}
	if not cue(clean): return {}
	var kind:=_kind(clean)
	if kind=="": return {}
	var target:=_match_target(clean)
	var cover:=_cover(clean)
	# An assassin "disguised as an envoy" with no cover word read is still an
	# envoy cover when "disguised" and "envoy" both appear.
	var insist:=WarOrders._has(clean.to_lower(),WarOrders.INSIST_WORDS)
	var out:={"kind":kind,"civ_id":String(target.get("civ_id","")),"city_id":String(target.get("city_id","")),
		"target_name":String(target.get("name","")),"cover":cover,"agent":_named_agent(clean),
		"target_desc":clean.substr(0,120),"insist":insist,"unknown_target":target.is_empty()}
	return out

# --------------------------------------------------------------------------
# Who carries it
# --------------------------------------------------------------------------

## The official who answers for a covert order: the Pathfinder for the eyes
## abroad (watch, plant, steal); the war leader for a killing or a sabotage.
## The one actually spoken to passes it on and the card names the carrier.
static func carrier(kind:String)->Dictionary:
	if kind in ["assassinate","sabotage"]:
		var general:=WarOrders.war_leader()
		if not general.is_empty(): return {"name":String(general.get("name","the war leader")),"office":"Marshal","person_id":int(general.get("person_id",0)),"figure_id":String(general.get("figure_id",""))}
	var pathfinder:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if not pathfinder.is_empty(): return {"name":String(pathfinder.get("name","the Pathfinder")),"office":"ChiefScout","person_id":int(pathfinder.get("person_id",0)),"figure_id":""}
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	if not steward.is_empty(): return {"name":String(steward.get("name","the headman")),"office":"Steward","person_id":int(steward.get("person_id",0)),"figure_id":"","stand_in":true}
	return {"name":"the headman","office":"Steward","person_id":0,"figure_id":"","stand_in":true}

static func _given(name:String)->String:
	return EraNames.given_of(name) if name!="" else "the one who carries it"

# --------------------------------------------------------------------------
# Performing a covert order
# --------------------------------------------------------------------------

## {verdict: "act"|"object"|"impossible", says, outcome, odds, op_id, carrier,
##  kind, cover}. act launches the operation; object states the odds and the
## grave cost and waits for the god to insist; impossible says plainly why not.
static func perform(reading:Dictionary,insist:bool,ctx:Dictionary={})->Dictionary:
	var kind:=String(reading.get("kind",""))
	var civ_id:=String(reading.get("civ_id",""))
	var cover:=String(reading.get("cover","none"))
	var who:=carrier(kind)
	var gname:=String(who.get("name",""))
	var out:={"verdict":"impossible","says":"","outcome":"","kind":kind,"cover":cover,"carrier":gname,"op_id":0}
	# The method must be within what our people know.
	var barred:=Covert.method_barred(kind)
	if barred!="":
		out.says="%s %s" % [barred,_fix_method(kind)]
		out.outcome="Nothing is done: we have no way to do that yet."
		return out
	# A target we can name and reach.
	if civ_id=="":
		var name:=String(reading.get("target_name",""))
		out.says=("We do not know the %s, nor where they live. Our scouts must find them before anyone can go among them." % (name if name!="" else "people you mean")) if name!="" else "Name the people, and I will see who can go among them."
		out.outcome="Nothing is done: we cannot reach them."
		return out
	# The target town, or their chief town for a people.
	var city_id:=String(reading.get("city_id",""))
	var the:=_the(civ_id)
	# Build an agent: the god's named one, or a volunteer the court finds.
	var agent:Dictionary=Covert.resolve_named(String(reading.get("agent",""))) if String(reading.get("agent",""))!="" else {}
	var named_missing:=String(reading.get("agent",""))!="" and agent.is_empty()
	if agent.is_empty(): agent=Covert.volunteer()
	var odds:=Covert.odds(kind,civ_id,city_id,cover,agent)
	# The official states the odds and the cost, and may object on the facts.
	var object:=_objection(kind,civ_id,cover,odds)
	if object!="" and not insist:
		out.verdict="object"
		out.says=_answer(kind,civ_id,city_id,cover,agent,odds,named_missing)+" "+object
		out.outcome="Nothing is done yet: %s waits on your word." % _given(gname)
		out["odds"]=odds
		return out
	# Launch it.
	var op:=Covert.launch(kind,civ_id,city_id,cover,agent,String(reading.get("target_desc","")))
	if op.has("error"):
		out.says=String(op.error)
		out.outcome="Nothing is done: "+String(op.error)
		return out
	out.verdict="act"
	out.op_id=int(op.id)
	out["odds"]=odds
	out.says=_answer(kind,civ_id,city_id,cover,agent,odds,false)+_sets_out(kind,agent,the,int(odds.days))
	out.outcome=_outcome_note(kind,agent,the,int(odds.days))
	return out

static func _fix_method(kind:String)->String:
	match kind:
		"plant": return "A kinsman can be sent to watch and come home, but none can live unseen among them yet."
		"steal": return "Watch them, or take what they have by the spear, instead."
	return ""

static func _objection(kind:String,civ_id:String,cover:String,odds:Dictionary)->String:
	## The grave cost an official names, grounded in the facts. "" when there
	## is nothing to object to.
	if kind=="assassinate":
		var parts:PackedStringArray=PackedStringArray()
		if cover=="envoy":
			parts.append("To send a killer under an envoy's cover breaks the sanctity of envoys: once it is known, no ruler will receive our envoys, and every people will trust them less for a long while.")
		parts.append("If it is traced to us — and a taken agent may talk — it means %s with %s." % [("war" if _formal(civ_id) else "a blood feud"),_the(civ_id)])
		parts.append("The agent will almost surely not come home.")
		parts.append("Say the word and I will send them anyway.")
		return " ".join(parts)
	if kind=="sabotage" and float(odds.get("caught",0.0))>=0.45:
		return "Their guard is up; if our agent is caught it may be traced to us. Shall I send them anyway?"
	return ""

static func _answer(kind:String,civ_id:String,city_id:String,cover:String,agent:Dictionary,odds:Dictionary,named_missing:bool)->String:
	## The official's plain answer with the odds in numbers.
	var the:=_the(civ_id)
	var who:=String(agent.get("given",agent.get("name","the one I would send")))
	var lead:=""
	if named_missing: lead="I know no one of that name to send; I would send %s instead. " % who
	match kind:
		"watch":
			return "%sI can put eyes on %s under a %s's cover: about %s that %s gets word home, in some %d days. If they are caught, their chance is about %s." % [lead,the,_cover_word(cover),Covert.odds_words(float(odds.success)),who,int(odds.days),Covert.odds_words(float(odds.get("caught",0.1)))]
		"plant":
			return "%sI can leave %s as a standing source among them, under a %s's cover: about %s they take root and send word until found." % [lead,who,_cover_word(cover),Covert.odds_words(float(odds.success))]
		"steal":
			return "%s%s can try to carry off a craft of theirs we lack: about %s they succeed, about %s they are caught." % [lead,who.capitalize(),Covert.odds_words(float(odds.success)),Covert.odds_words(float(odds.get("caught",0.1)))]
		"sabotage":
			return "%sI can send %s to burn their stores or foul a well under a %s's cover: about %s it is done, about %s they are caught." % [lead,who,_cover_word(cover),Covert.odds_words(float(odds.success)),Covert.odds_words(float(odds.get("caught",0.1)))]
		"assassinate":
			var reach:=float(odds.get("reach",odds.get("access",0.3)))
			return "%sI can send %s to %s under a %s's cover. About %s they get close enough; if they do, they will likely kill one of their leaders, two or three at most before they are cut down. In all, about %s the blow lands." % [lead,who,"strike at their leaders",_cover_word(cover),Covert.odds_words(reach),Covert.odds_words(float(odds.success))]
	return ""

static func _sets_out(kind:String,agent:Dictionary,the:String,days:int)->String:
	var who:=String(agent.get("given",agent.get("name","our agent")))
	return " %s sets out for %s; about %d days on the road." % [who.capitalize(),the,days]

static func _outcome_note(kind:String,agent:Dictionary,the:String,days:int)->String:
	var who:=String(agent.get("name","our agent"))
	match kind:
		"watch","plant": return "%s goes to watch %s: word should come back in some days." % [who,the]
		"steal": return "%s goes to carry off a secret of %s." % [who,the]
		"sabotage": return "%s goes to strike at %s's stores." % [who,the]
		"assassinate": return "%s goes to strike at the leaders of %s." % [who,the]
	return "%s sets out." % who

static func _cover_word(cover:String)->String:
	return {"envoy":"envoy","trader":"trader","pilgrim":"pilgrim","refugee":"refugee","none":"no"}.get(cover,"no")

static func _the(civ_id:String)->String:
	var name:=Hall._civ_name(civ_id)
	return name if name.to_lower().begins_with("the ") else "the "+name

static func _formal(civ_id:String)->bool:
	return bool((load(WAR_LOOP_PATH) as GDScript).call("formal",civ_id))

# --------------------------------------------------------------------------
# Is this covert business this audience is about? (for the modal's routing)
# --------------------------------------------------------------------------

static func court_business(text:String,civ_id:String="",audience_id:String="")->bool:
	return not read(text,civ_id,audience_id).is_empty()
