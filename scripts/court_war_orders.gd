extends RefCounted
## WAR ORDERS SPOKEN AT COURT.
##
## "Send our full forces into battle on Tsaren", "attack Tsaren", "lay siege
## to their town", "raid their fields", "attack their army", "march home",
## "defend the ford": a war order to the war leader (or the court as a whole,
## or any official, who passes it on) never becomes a vague custom directive.
## It becomes a real, validated military objective, or an honest refusal.
##
## read()    the ruler's words -> {kind, target, full, insist, ...} or {}.
## perform() the war leader weighs it against what is really there: known
##           place, a land road (army_land_route.gd), every force he commands
##           (his own band wherever it stands, the trained reserve at home,
##           and the recruits still in drill, with their real drill and
##           weapons), and the last estimate of the enemy garrison. Then:
##           - act: sends his band from where it stands, or forms a host from
##             the home formations, through MilitaryCampaign's field-army
##             machinery (march along the land road, then attack, siege or
##             raid on arrival; war begins on contact);
##           - object: forces exist but are too few, half-drilled, unarmed or
##             outnumbered. He says so with the real numbers and what would
##             fix it; "I insist" / "take them as they are" overrides, and
##             recruits still in drill then march with the drill they have;
##           - impossible: only when nothing can go at all (nobody under arms
##             or in drill, no land road, an unknown place, a fight already on).
##           The war leader's words (says) carry the answer; outcome is one
##           short plain note ("No one marches yet.").
##           No accepting answer is ever given without a created objective:
##           an accepting result always carries objective.army_id.
## daily()   follows ordered marches: the general's unsolicited report comes
##           back as a court matter when the fight is over (or the road ends).
##
## Offline, the same words reach read() through court_commands.hear(); online
## the live reading may name verb "war" with the place in `object`, and the
## same perform() validates it. Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const TownFate:=preload("res://scripts/town_fate.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const BattleGround:=preload("res://scripts/battle_ground.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

const KINDS:=["attack","siege","raid","intercept","recall","defend","drill","fate","held","storm","which_town","no_town","take_first","group_maim","pursue","let_go","abandon","keep","measure","town_word","measure_drop","captives","follow_kill"]
## A strike by stealth: by night, unseen, on them asleep ("sneak attack
## Eldwick under cover of night"). The attack goes in as a night approach
## (battle_tactics.night_approach) at a chance stated when it is ordered.
const NIGHT_WORDS:="\\b(sneak|by night|at night|in the night|night (attack|raid|march|strike)|under (the )?cover of (the )?(night|darkness|dark)|in the dark(ness)?|before (dawn|first light|daybreak)|while they sleep|asleep|unawares|by surprise|surprise (attack|raid|strike)|creep up|steal up|slip up)\\b"
## "With 17 troops": how many the ruler wants sent.
const COUNT_WORDS:="\\b(\\d{1,5})\\s+(of (our|my|the|them) )?(troops|men|fighters|warriors|soldiers|spears|spearmen|archers|riders|bowmen|people|of them|of us|hunters)\\b"
## What becomes of those we took in a fight and what we took from them, or the
## standing word for every fight to come. Never a held town's people
## (occupation_measures.gd).
const CAPTIVE_WORDS:="\\b(captives?|prisoners?|bondservants?|bondsmen|slaves|the (men|ones|people|fighters) we (took|captured|caught))\\b"
const SPOILS_WORDS:="\\b(spoils|plunder|loot|booty|what we took|everything we took|all we took)\\b"
const LEADER_WORDS:="\\b(their|the captured|the enemy'?s?) (leader|chief|war ?leader|general|commander|headman)\\b"
const STANDING_WORDS:="\\b(from now on|from this day|henceforth|in future|in the future|always|every time|whenever|as a rule|each time|after every|after each|after any)\\b"
## What a measure on a town still in their hands would be, said plainly.
const MEASURE_DEEDS:={"bind_men":"round up its men","disarm":"take its weapons","hostages":"take hostages from it","curfew":"keep its people indoors","search":"search its houses",
	"labour":"put its men to work","requisition":"take its food","conscript":"take its young men","execute_ringleaders":"put its ringleaders to death","release":"free anyone there",
	"relief":"feed its people","set_headman":"set one of ours over it","settle":"settle our families there"}
## How long the war leader remembers what he already said in an audience.
const ASKED_DAYS:=4
## Storming a town our band already besieges.
const STORM_WORDS:="(storm|assault|take the walls|scale the walls|over the walls|break (in|through)|attack now|attack (the|their) (walls|gate)|go in now|rush the gate|carry the walls)"
## Fewer trained soldiers than this cannot take or besiege a town at all.
const MIN_FORCE:=5
## Below this share of the enemy's estimated strength, a general objects.
const OBJECT_RATIO:=0.8
## Below this average drill, a general will not lead them at walls unasked.
const UNDRILLED:=0.2
## The home watch a general keeps back unless told to send everything.
const WATCH_SHARE:=0.2
const LEDGER_MAX:=24
## How long an objection stays open to 'take them as they are' (as court_commands).
const PENDING_DAYS:=2
## Share of a force without weapons at which a general objects.
const UNARMED_SHARE:=0.25

const ARMY_WORDS:="(army|armies|forces?|troops|soldiers|warriors|fighters|host|levy|levies|war ?bands?|spearmen|column|everyone who can fight|every fighter|every spear)"
## Words that mean fighters only next to "against"/"on" ("send our men against them").
const LOOSE_ARMY_WORDS:="(men|bands?|spears|companies|people)"
const ATTACK_WORDS:="(attack|assault|storm|strike|fall (up)?on|march (on|against|to war|to battle|into battle)|go (to war|against|to battle)|make war|wage war|war on|battle|into battle|fight|take the (city|town|village|settlement)|capture|conquer|sack|crush|destroy|wipe out|invade|smash|raze|burn [\\w' ]{0,20}?to the ground|put [\\w' ]{0,20}? to the sword)"
const SIEGE_WORDS:="(besiege|lay siege|siege|starve [\\w' ]{0,20}?out|surround (the|their) (city|town|walls|village))"
const RAID_WORDS:="(raid|plunder|pillage|loot|burn their (fields|crops|stores|granar\\w*|barns|harvest|grain)|steal their|drive off their (herds|cattle|flocks))"
const INTERCEPT_WORDS:="(attack|fight|meet|catch|hunt down|destroy|engage|smash|crush|intercept|fall (up)?on|go after|chase|pursue) (their|the enemy'?s?|the) (army|host|war ?band|column|forces?|fighters|raiders|warriors|soldiers|troops|men)"
const RECALL_WORDS:="((march|come|go|bring|call|send|pull|get|fall)\\w* [\\w' ]{0,30}?(home|back)\\b|withdraw|retreat|fall back|pull back|recall|disengage)"
const DEFEND_WORDS:="(defend|hold|guard|protect|garrison|man the walls|stand guard)"
const FULL_WORDS:="(full|whole|all (of )?(our|my|the)|every|everything|everyone|each and every|all we have|all you have|to the last)"
const INSIST_WORDS:="(regardless|whatever the cost|no matter (what|the cost|the odds)|at any cost|at all costs|i don't care|i do not care|now!|at once|i insist|i command it|do it anyway|anyway)"
## "Drill them first", "let them finish their drill": the god takes the war
## leader's advice instead of insisting.
const DRILL_WORDS:="((drill|train) (them|the band|the levy|your band|your men) (first|more|longer)|let them (finish|drill|train)|finish (their|the) (drill|training)|bring (them|the band|your band) home (to|and) (drill|train))"
## "Chase them", "go after the men who ran": after men got away from a town we hold.
const CHASE_WORDS:="(\\b(chase|pursue|go after|run down|hunt down|hunt|track down|catch|ride down|follow)\\b[\\w' ]{0,14}\\b(them|men|ones|fled|ran|runaways|fugitives|survivors|rest|others|escaped|got away)\\b|\\b(after them|chase them|run them down)\\b)"
## "Come back", "everyone come home", "return to Seanstone": our people, not a town's fate.
const RECALL_BACK:="((come|get|head|turn|go|march|walk|fall)\\w* (back|home)\\b|\\breturn (home|to )|call off the (chase|pursuit|hunt)|call (them|everyone|everybody|the \\w+) (back|home))"
const GROUP_RECALL:="(everyone|everybody|all of you|you all|them all|all of them|the garrison|garrisons?|the detachment|the men|our men|the band|every one of)"
## Answers to the war leader's question ("Shall I?", "Leave it unguarded?").
const YES_WORDS:="^\\W*(yes|yeah|yea|yep|aye|do it|go ahead|go on|go|please|sure|all right|alright|ok|okay|very well|so be it|of course|indeed|do so)\\b"
const NO_WORDS:="^\\W*(no|nope|nay|don'?t|do not|let them go|leave them|not now|never mind|forget it|stay|keep (it|them|the garrison))\\b"
const PLACE_WORDS:="(ford|pass|bridge|crossing|river|border|hills?|gate|road|walls?|home|village|town|camp|fields)"

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile("(?i)"+pattern)
	return re

static func _has(text:String,pattern:String)->bool:
	return _re("\\b"+pattern).search(text)!=null

# --------------------------------------------------------------------------
# Reading the words
# --------------------------------------------------------------------------

static func known_places()->Array[Dictionary]:
	## Known foreign towns: {city_id, civ_id, name, civ_name, position}.
	## Towns we hold are not among them (held_towns()).
	var out:Array[Dictionary]=[]
	var world:Variant=WorldSimulation.world
	if world==null or not "city_intelligence" in world or world.city_intelligence==null: return out
	var held:={}
	for town:Dictionary in held_towns(): held[String(town.city_id)]=true
	for city:Dictionary in world.city_intelligence.known_cities("player","",false):
		var controller:=String(city.get("controller",city.get("civ_id","")))
		if controller in ["","player"] or String(city.get("civ_id",""))=="player" or held.has(String(city.city_id)): continue
		out.append({"city_id":String(city.city_id),"civ_id":String(city.get("civ_id","")),"controller":controller,"name":String(city.get("name","")),"civ_name":Hall._civ_name(String(city.get("civ_id",""))),"position":(city.get("position",{}) as Dictionary).duplicate(true)})
	return out

static func held_towns()->Array[Dictionary]:
	## Towns we have taken and still hold, with who holds them:
	## {city_id, civ_id, name, civ_name, garrison, commander, population,
	## position, held:true}.
	## Held is the one reading every system uses (town_ledger.hold): the
	## region is ours and a garrison of ours stands in it.
	var out:Array[Dictionary]=[]
	var mc:Variant=WorldSimulation.military
	var world:Variant=WorldSimulation.world
	if mc==null or world==null: return out
	for f in mc.occupation_forces:
		var force:Dictionary=f
		var civ_id:=String(force.get("civ_id",""))
		var rid:=String(force.get("region_id",""))
		var h:=Ledger.hold(civ_id,rid)
		if not bool(h.held): continue
		var troops:=int(h.garrison)
		var region:Dictionary=world.region_snapshot(civ_id,rid)
		var known:Dictionary=world.city_intelligence.known("player",rid) if "city_intelligence" in world and world.city_intelligence!=null else {}
		var name:=String(region.get("name",force.get("region_name","")))
		if name=="": name=String(known.get("name","")).trim_prefix("Reported home of ")
		var position:Dictionary=(known.get("position",{}) as Dictionary).duplicate(true)
		out.append({"city_id":rid,"civ_id":civ_id,"name":name,"civ_name":Hall._civ_name(civ_id),"garrison":troops,
			"commander":String((force.get("commander",{}) as Dictionary).get("name","")),"population":roundi(float(region.get("population",0.0))),"position":position,"held":true,
			"taken_day":int(force.get("committed_day",0))})
	return out

static func unguarded_towns()->Array[Dictionary]:
	## Towns we took that are ours with no garrison of ours in them
	## (town_ledger.hold state "unguarded"): neither held nor a foreign town
	## to march on. {city_id, civ_id, name, civ_name, position, unguarded:true}.
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	for pair in Ledger.towns():
		var h:=Ledger.hold(String(pair[0]),String(pair[1]))
		if String(h.state)!="unguarded" or String(h.name)=="": continue
		var known:Dictionary=WorldSimulation.world.city_intelligence.known("player",String(pair[1])) if "city_intelligence" in WorldSimulation.world and WorldSimulation.world.city_intelligence!=null else {}
		out.append({"city_id":String(pair[1]),"civ_id":String(pair[0]),"controller":"player","name":String(h.name),"civ_name":Hall._civ_name(String(pair[0])),"position":(known.get("position",{}) as Dictionary).duplicate(true),"unguarded":true})
	return out

static func _name_hit(lower:String,name:String)->bool:
	var n:=name.to_lower().strip_edges()
	if n.length()<3: return false
	if _re("\\b%s\\b" % _escape(n)).search(lower)!=null: return true
	# "Reported home of Tsaren" is found by "Tsaren".
	for word in n.split(" ",false):
		if word.length()>=4 and not word in ["reported","home","city","town","village","camp","settlement","the"] and _re("\\b%s\\b" % _escape(word)).search(lower)!=null: return true
	return false

static func _escape(text:String)->String:
	var out:=""
	for c in text:
		out+=("\\"+c) if c in ".^$*+?()[]{}|\\-" else c
	return out

static func find_target(text:String,context_civ:String="")->Dictionary:
	## The foreign town the words name (by its own name or its people's), or
	## the one "their" means. {city_id,civ_id,name,civ_name,position} | {}.
	## {"ambiguous":[names]} when "their" could be several peoples;
	## {"unknown":"Name"} when a capitalised name matches nothing we know.
	var lower:=text.to_lower()
	# A town we already hold is named as ours, never as a place to attack.
	for town:Dictionary in held_towns():
		if _name_hit(lower,String(town.name)): return town
	# A town we took that is ours with nobody of ours in it (the garrison
	# left): named as what it is (town_ledger.hold), never "no town".
	for town:Dictionary in unguarded_towns():
		if _name_hit(lower,String(town.name)): return town
	var places:=known_places()
	for p:Dictionary in places:
		if _name_hit(lower,String(p.name)):
			# A town we burned and left: a ruin, never a town to march on.
			if not Ledger.our_ruin(String(p.city_id)).is_empty():
				var ruin:=p.duplicate(true); ruin["ruin"]=true
				return ruin
			return p
	var civs:Array=WorldSimulation.world.civilizations if WorldSimulation.world!=null else []
	for c:Dictionary in civs:
		if String(c.get("id",""))=="player": continue
		if _name_hit(lower,String(c.get("name",""))):
			var best:=_primary_place(places,String(c.id))
			if not best.is_empty(): return best
			return {"unknown":String(c.get("name","")),"civ_id":String(c.id)}
	# A proper name after "on/against/at/to" we do not know at all.
	var m:=RegEx.new(); m.compile("\\b(?i:on|against|attack|besiege|raid|storm|siege of)\\s+(?:the\\s+)?([A-Z][\\w'-]{2,})")
	for hit in m.search_all(text):
		var word:=hit.get_string(1)
		if not word in ["The","Our","My","Their","Them","It","Home","Your","War","Battle","Me","You"]: return {"unknown":word}
	if _has(lower,"(their|them|the enemy|the enemy's|those people|these people)\\b"):
		if context_civ!="":
			var own:=_primary_place(places,context_civ)
			if not own.is_empty(): return own
		var hostile:Array[String]=[]
		for c:Dictionary in civs:
			var rel:Dictionary=c.get("player_relation",{}) if c.get("player_relation") is Dictionary else {}
			if bool(rel.get("at_war",false)): hostile.append(String(c.id))
		if hostile.size()==1:
			var at_war:=_primary_place(places,hostile[0])
			if not at_war.is_empty(): return at_war
		var peoples:Dictionary={}
		for p:Dictionary in places: peoples[String(p.civ_id)]=String(p.civ_name)
		if peoples.size()==1: return _primary_place(places,String(peoples.keys()[0]))
		if peoples.size()>1: return {"ambiguous":peoples.values()}
	return {}

static func _primary_place(places:Array[Dictionary],civ_id:String)->Dictionary:
	var best:Dictionary={}
	var best_d:=INF
	var home:Vector2=WorldSimulation.world.player_world_origin
	for p:Dictionary in places:
		if String(p.civ_id)!=civ_id and String(p.controller)!=civ_id: continue
		var d:=home.distance_to(Vector2(float(p.position.get("x",0)),float(p.position.get("z",0))))
		if d<best_d: best_d=d; best=p
	return best

## A town taken this many days before any other we hold is "the town" when
## an order names none.
const RECENT_TAKING_DAYS:=10

static func read(text:String,context_civ:String="",audience_id:String="")->Dictionary:
	## {} when the words are not a war order. Otherwise {kind, target, full,
	## insist, place, army_words}. Questions are discussion, never orders.
	## A fate order that names no town ("kill all the males and bring the
	## females back to Seanstone") is about the town we hold; see _implied_town.
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?"): return {}
	var lower:=clean.to_lower()
	for lead in ["what","why","how","who","whom","where","when","should","could","can","would","shall we","do we","is it","are we"]:
		if lower.begins_with(lead+" "): return {}
	# "The women too" just after an order about a town: that order, for them.
	if audience_id!="":
		var more:=follow_up(clean,audience_id)
		if not more.is_empty(): return more
	var army:=_has(lower,ARMY_WORDS+"\\b")
	var named:=find_target(clean,context_civ)
	var named_town:=named.has("city_id") or named.has("unknown")
	var kind:=""
	# The captives and spoils of a fight, or the standing word for the next
	# ("free the captives", "from now on the spoils go to the warriors").
	if not bool(named.get("held",false)):
		var captive:=captive_reading(clean)
		if not captive.is_empty() and captive_applies(captive): return captive
	# After men got away from a town we hold: "chase them" is a chase.
	if _has(lower,CHASE_WORDS):
		var flight:=Pursuit.latest_flight(String(named.city_id) if bool(named.get("held",false)) else "")
		if not flight.is_empty():
			var n:=_re("\\b(\\d{1,4})\\b").search(lower)
			return {"kind":"pursue","target":_held_town(String(flight.region_id)),"count":int(n.get_string(1)) if n!=null else 0,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
	# What the garrison is to do with a town's people (occupation_measures.gd):
	# "round up the men and tie them up; if any run, threaten their families".
	# A threat on a condition is a stance, never an order in itself, so fate
	# words are read without it.
	var measure:=Measures.read(clean)
	var main:=String(Measures.conditions(lower).main) if not measure.is_empty() else lower
	if not bool(named.get("held",false)):
		if not measure.is_empty():
			var on_town:=_measure_town(clean,lower,main,named,army,audience_id,measure)
			if not on_town.is_empty(): return on_town
		var implied:=_implied_town(clean,main,named,army,audience_id)
		if not implied.is_empty(): return implied
	if bool(named.get("held",false)):
		# A town we hold: what becomes of it and its people is the god's to
		# say (town_fate.gd), and what the garrison does there
		# (occupation_measures.gd). Only an attack on it is answered with the
		# plain truth that it is ours; any other order about it is read as
		# nearly as the words allow, never answered with the same question.
		if not measure.is_empty():
			var measured:=_measure_reading(clean,main,named,measure,army)
			if not measured.is_empty(): return measured
		var fate:=TownFate.fate_words(main)
		if not fate.is_empty(): return {"kind":"fate","target":named,"fate":fate,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}
		# Maiming or flogging a whole town's people: the war leader's plain
		# answer (group_maim), never a persons inquiry nor a hand on anyone here.
		if _has(main,"(maim|mutilat|cripple|blind|geld|castrat|hamstring|brand|flog|whip|scourge)\\w*\\b") and _has(main,TownFate.GROUP_WORDS):
			return {"kind":"group_maim","target":named,"fate":{"group":true},"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300),"harm":"maim","group_harm":true}
		# A chase from the town when nobody has run: the war leader says so.
		if _has(lower,CHASE_WORDS): return {"kind":"pursue","target":named,"count":0,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
		if _attack_on_held(main,army): return {"kind":"held","target":named,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
		if Measures.looks_like_order(clean): return {"kind":"town_word","target":named,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}
		return {}
	var besieged:=_besieged()
	if not besieged.is_empty() and (named.is_empty() or String(named.get("city_id",""))==String(besieged.city_id)) and (_has(lower,STORM_WORDS) or (String(named.get("city_id",""))==String(besieged.city_id) and _has(lower,ATTACK_WORDS))):
		return {"kind":"storm","target":besieged,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}
	if _has(lower,DRILL_WORDS): return {"kind":"drill","target":{},"full":false,"insist":false,"place":"","army_words":true,"text":clean.substr(0,300)}
	if _has(lower,INTERCEPT_WORDS): kind="intercept"
	elif _has(lower,SIEGE_WORDS): kind="siege"
	elif _has(lower,RAID_WORDS): kind="raid"
	elif _has(lower,RECALL_WORDS) and (army or _has(lower,"(march|come) home|withdraw|retreat|fall back|pull back|recall")): kind="recall"
	elif _has(lower,RECALL_BACK) and (army or _has(lower,GROUP_RECALL) or _re("^\\W*(come|get|head|turn|return|go|march|call|all|everyone|everybody)\\b").search(lower)!=null): kind="recall"
	elif _has(lower,ATTACK_WORDS): kind="attack"
	elif _has(lower,DEFEND_WORDS) and (army or _has(lower,"(defend|hold|guard|protect|garrison) (the|our|my) "+PLACE_WORDS)): kind="defend"
	elif army and _has(lower,"(send|march|lead|take|move)") and _has(lower,"(on|against|to|at|toward|towards)\\b"): kind="attack"
	elif _has(lower,LOOSE_ARMY_WORDS) and _has(lower,"(send|march|lead|take)") and _has(lower,"(on|against)\\b") and named_town: kind="attack"
	# "Send everything we have against Tsaren", "throw all we have at them".
	elif named_town and _has(lower,"(send|throw|hurl|commit)\\b") and _has(lower,"(against|on|into|at)\\b") and _has(lower,"(everything|everyone|all (we|you) have|all of us|every one of us|whatever we have|all our)\\b"): kind="attack"
	elif named_town and _has(lower,"(take|seize|win|burn|punish|humble|finish|end|go for|hit)"): kind="attack"
	if kind=="": return _implied_word(clean,lower,audience_id)
	var target:={} if kind=="recall" else named
	# An attack verb with nothing to attack and no army named is not a war
	# order ("strike him", "destroy the old hut").
	if kind in ["attack","siege","raid"] and target.is_empty() and not army and not _has(lower,"(their|the enemy)"): return {}
	if kind=="intercept" and target.is_empty() and not _has(lower,"(their|the enemy)"): return {}
	if kind=="defend" and not army and not _has(lower,"\\b(the|our|my) "+PLACE_WORDS): return {}
	var place:=""
	var pm:=_re("\\b(the|our|my) "+PLACE_WORDS+"\\b").search(lower)
	if pm!=null: place=pm.get_string()
	var reading:={"kind":kind,"target":target,"full":_has(lower,FULL_WORDS),"insist":_has(lower,INSIST_WORDS),"place":place,"army_words":army,"text":clean.substr(0,300)}
	strike_manner(reading,lower)
	if kind=="recall":
		# Home, or back to the town they came from; and whether the garrison is meant.
		var home_name:=String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
		reading["home"]=_has(lower,"(home|withdraw|retreat|recall)") or (home_name!="" and _name_hit(lower,home_name))
		reading["garrison"]=_has(lower,"(garrisons?|every ?one|every ?body|all of (you|them)|them all|you all|every soldier|all our|all the)")
	return reading

## Words that are the war leader's business however they are phrased, never
## a persons inquiry even when they say "who", "bring" or "maim": what becomes
## of a town we hold and its people, the men who fled it, the captives of a
## fight. (The court modal asks this before the persons engine takes words.)
const COURT_BUSINESS:=["measure","town_word","fate","which_town","measure_drop","pursue","let_go","captives","group_maim","follow_kill","abandon","keep"]

static func court_business(text:String,context_civ:String="",audience_id:String="")->bool:
	return String(read(text,context_civ,audience_id).get("kind","")) in COURT_BUSINESS

## How a strike goes in, from the ruler's words: by night (approach) and
## with how many (count). Shared by the live reading (order_reader.gd).
static func strike_manner(reading:Dictionary,lower:String)->void:
	var kind:=String(reading.get("kind",""))
	if kind in ["attack","raid"] and _has(lower,NIGHT_WORDS): reading["approach"]="night"
	var counted:=_re(COUNT_WORDS).search(lower)
	if counted!=null and kind in ["attack","raid","siege"] and int(reading.get("count",0))<=0: reading["count"]=int(counted.get_string(1))


## {} when the words are not about captives or spoils; else {kind:"captives",
## part (prisoners | spoils | general), policy, standing}.
static func captive_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?"): return {}
	var lower:=clean.to_lower()
	var part:=""
	if _has(lower,SPOILS_WORDS): part="spoils"
	elif _has(lower,LEADER_WORDS) and not _has(lower,CAPTIVE_WORDS): part="general"
	elif _has(lower,CAPTIVE_WORDS): part="prisoners"
	if part=="": return {}
	var policy:=_captive_policy(lower,part)
	if policy=="": return {}
	return {"kind":"captives","part":part,"policy":policy,"standing":_has(lower,STANDING_WORDS),"target":{},"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":false,"text":clean.substr(0,300)}


static func _captive_policy(lower:String,part:String)->String:
	if part=="spoils":
		if _has(lower,"\\b(give|hand|send|take) ([\\w']+ ){0,3}back\\b|\\breturn\\b"): return "return property"
		if _has(lower,"\\b(warriors|fighters|troops|soldiers|men|band|bands|those who fought|the ones who fought|hunters)\\b"): return "reward troops"
		if _has(lower,"\\b(treasury|coffers)\\b"): return "state treasury"
		if _has(lower,"\\b(stores?|store ?houses?|granar\\w*|common)\\b"): return "army stores"
		return ""
	if _has(lower,"\\b(kill|execute|put ([\\w']+ ){0,3}to death|slay|behead|hang)\\b"): return "execute"
	# "Sell the captives": back to their own people for goods, the one sale there is.
	if _has(lower,"\\b(ransom|sell|trade ([\\w']+ ){0,3}back)\\b"): return "ransom"
	if part=="prisoners" and _has(lower,"\\b(bondservants?|bondsmen|slaves?|enslave|put ([\\w']+ ){0,3}to work|make ([\\w']+ ){0,3}work|servants)\\b"): return "enslave"
	if _has(lower,"\\b(free|freed|release|let ([\\w']+ ){0,3}go|set ([\\w']+ ){0,3}free|send ([\\w']+ ){0,3}home|spare|unbind|untie)\\b"): return "release"
	if _has(lower,"\\b(keep|hold|guard|lock ([\\w']+ ){0,3}up)\\b"): return "hold"
	return ""


## Whether a captives reading has something to act on: a standing word
## always does; otherwise a fight's settlement still open to change, or
## captives still held under guard (a held town's people are the garrison's).
static func captive_applies(reading:Dictionary)->bool:
	if bool(reading.get("standing",false)): return true
	var mc:Node=WorldSimulation.military if WorldSimulation!=null else null
	if mc==null or not mc.has_method("open_settlement"): return false
	var part:=String(reading.get("part","prisoners"))
	if not (mc.open_settlement(part) as Dictionary).is_empty(): return true
	if part=="prisoners": return int(mc.foreign_prisoners)>0
	if part=="general": return not (mc.held_generals as Array).is_empty()
	return false


## What becomes of them, as a standing word says it.
static func practice_words(part:String,policy:String)->String:
	match part:
		"spoils": return String({"army stores":"the spoils go to the stores","reward troops":"the spoils go to the warriors","state treasury":"the spoils go to the treasury",
			"return property":"what we take is given back","unrestricted plunder":"the warriors keep all they can carry"}.get(policy,"the spoils go to the stores"))
		"general": return String({"hold":"their leader is held","ransom":"their leader is given back for ransom","release":"their leader is let go","execute":"their leader is put to death"}.get(policy,"their leader is held"))
	return String({"hold":"the captives are held under guard","release":"the captives are let go","parole":"the captives are let go on their word","ransom":"the captives are given back for ransom",
		"enslave":"the captives come home as bondservants","execute":"the captives are put to death","exchange":"the captives are traded for our own"}.get(policy,"the captives are held under guard"))


## The ruler's word on captives and spoils: a standing word for every fight
## to come, or a change to what the general did after the last one (only
## what is still in our hands, and only by what is really there).
static func _captives(out:Dictionary,reading:Dictionary)->Dictionary:
	var mc:=_mc()
	var part:=String(reading.get("part","prisoners"))
	var policy:=String(reading.get("policy",""))
	out["part"]=part; out["policy"]=policy
	if bool(reading.get("standing",false)):
		var set:Dictionary=mc.set_aftermath_practice(part,policy)
		if set.has("error"): return _refuse_captives(out,"unknown",String(set.error))
		out.verdict="fate"
		out.says="From now on, after every fight, %s." % practice_words(part,policy)
		out.outcome="A standing word: %s." % practice_words(part,policy)
		return out
	var settled:Dictionary=(mc.open_settlement(part) as Dictionary).duplicate(true)
	var changed:Dictionary=mc.revise_settlement(part,policy)
	if changed.has("error") and part=="prisoners" and int(mc.foreign_prisoners)>0 and policy!="hold":
		# Captives held under guard from any fight: all of them.
		var held:=int(mc.foreign_prisoners)
		var done:Dictionary=mc.resolve_held_prisoners(policy,held)
		if not done.has("error"):
			var did:=_cap(String({"release":"%s set free","parole":"%s let go on their word","ransom":"%s sent back to their people for ransom","enslave":"%s put to work as bondservants",
				"execute":"%s put to death","exchange":"%s traded for our own people"}.get(policy,"%s dealt with")) % _people_words(held))
			out.verdict="fate"; out.says="The %d we were holding under guard: %s." % [held,did.substr(0,1).to_lower()+did.substr(1)]; out.outcome=did+"."
			return out
	if changed.has("error"): return _refuse_captives(out,String(changed.get("reason","cannot")),String(changed.error))
	out.verdict="fate"
	var moved:Variant=changed.get("moved",0)
	var count:=int(moved) if (moved is int or moved is float) else 0
	out.says=(String(changed.done)+" "+_captives_were(settled,part,String(changed.get("from","")),count)).strip_edges()
	out.outcome=String(changed.done)
	return out

## Who the captives were, from the fight's own record: "They were the Esurai
## we took at the ford, at our hearths as bondservants."
static func _captives_were(s:Dictionary,part:String,was:String,moved:int)->String:
	if s.is_empty() or part!="prisoners" or moved<=0: return ""
	var place:=""
	for b in _mc().battle_history:
		if String((b as Dictionary).get("id",""))==String(s.get("battle_id","")) and String(s.get("battle_id",""))!="":
			place=String((b as Dictionary).get("target_region_name",""))
			break
	var people:=String(s.get("people",""))
	var who:=("the %s" % people) if people!="" and not people.begins_with("UNIDENTIFIED") else "the ones"
	var where:=(" at %s" % place) if place!="" else " in the last fight"
	var how:=String({"enslave":", at our hearths as bondservants","hold":", held under guard"}.get(was,""))
	if moved==1: return "That one was one of %s we took%s%s." % [who,where,how]
	return "They were %s we took%s%s." % [who,where,how]


static func _refuse_captives(out:Dictionary,reason:String,says:String)->Dictionary:
	out.verdict="impossible"; out.reason=reason; out.says=says; out.fix=""
	out.outcome="Nothing is changed."
	return out


static func _people_words(n:int)->String:
	return preload("res://scripts/battle_account.gd")._people(n,"captive","captives")


static func _held_town(region_id:String)->Dictionary:
	for town:Dictionary in held_towns():
		if String(town.city_id)==region_id: return town
	return {}

## Words that send fighters against a town (an attack on a town we hold is
## answered with the truth); "the men of Tsaren" are its people, not ours.
const HELD_ATTACK_WORDS:="(attack|assault|storm|strike at|march (on|against|to war|to battle|into battle)|go (to war|against|to battle)|make war|wage war|war on|battle|into battle|take the (city|town|village|settlement)|capture|conquer|invade|besiege|lay siege|siege of)"

static func _attack_on_held(main:String,army:bool)->bool:
	if army or _has(main,HELD_ATTACK_WORDS) or _has(main,SIEGE_WORDS): return true
	return _has(main,LOOSE_ARMY_WORDS) and _has(main,"(send|march|lead)") and _has(main,"(on|against|into)\\b") and not _has(main,"\\b(men|people|women|villagers) of\\b")

## Measures for a town we hold, with any fate the same words decide.
## {} when the measures explain every word and none is left to do.
static func _measure_reading(clean:String,main:String,town:Dictionary,measure:Dictionary,army:bool)->Dictionary:
	var ids:Array=(measure.measures as Array).duplicate()
	var raw:=TownFate.fate_words(main).duplicate()
	var consumes:Array=(measure.consumes as Array).duplicate()
	# "Take their food and leave" is tribute on the way out, not a requisition.
	if (bool(raw.get("leave",false)) or bool(raw.get("raze",false))) and ids.has("requisition"):
		ids.erase("requisition"); consumes.erase("tribute")
	# "Make them build our walls in Seanstone": they walk home to labour.
	var home:=String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
	if ids.has("labour") and home!="" and _name_hit(main,home):
		ids.erase("labour"); raw["move"]="penal"; raw.erase("captives")
	var fate:=_fate_less(raw,consumes)
	if ids.is_empty() and not bool(measure.get("stance_set",false)):
		if fate.is_empty(): return {}
		return {"kind":"fate","target":town,"fate":fate,"full":false,"insist":_has(main,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}
	return {"kind":"measure","target":town,"measures":ids,"measure":measure,"fate":fate,"full":false,"insist":_has(main,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}

## A fate less the flags the measures already explain.
static func _fate_less(fate:Dictionary,consumes:Array)->Dictionary:
	var out:=fate.duplicate()
	for flag in consumes:
		if String(flag)=="policy":
			if String(out.get("policy",""))=="forced_labor": out.erase("policy")
		else: out.erase(String(flag))
	for key in out.keys():
		if not String(key) in ["count","group"]: return out
	return {}

## Measures that are only ever about a people in our hands.
const OCCUPATION_ONLY:=["bind_men","disarm","hostages","conscript","execute_ringleaders","set_headman","settle","release"]

static func _measure_town(clean:String,lower:String,main:String,named:Dictionary,army:bool,audience_id:String,measure:Dictionary)->Dictionary:
	## Measures in words that name no town we hold: the town they must mean,
	## or {} when nothing points at one ("feed the people" at home is civic
	## business). A foreign town named outright must be taken first.
	var ids:Array=measure.measures
	if named.has("city_id") and not bool(named.get("held",false)) and _name_hit(lower,String(named.get("name","")).trim_prefix("Reported home of ")):
		var deed:=String(MEASURE_DEEDS.get(String(ids[0]) if not ids.is_empty() else "","deal with its people"))
		return {"kind":"take_first","target":named,"fate":{},"deed":deed,"harm":"","full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
	var held:=held_towns()
	var civ:=String(named.get("civ_id",""))
	if civ!="":
		var theirs:Array[Dictionary]=[]
		for t:Dictionary in held:
			if String(t.civ_id)==civ: theirs.append(t)
		if not theirs.is_empty(): held=theirs
	var their:=_has(main,"(their|its)\\b")
	if held.is_empty():
		# Measures on a foe's people when we hold none of their towns.
		if not ids.is_empty() and (bool(measure.people) or their) and _has(lower,"(their|theirs|the enemy|enemy|foes?)\\b") and _any_war():
			return {"kind":"no_town","target":{},"fate":{},"measure_words":true,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
		return {}
	var spoken:=_town_in_audience(held,audience_id)
	var strong:=ids.any(func(id:Variant)->bool: return String(id) in OCCUPATION_ONLY)
	var pointed:=_has(lower,TownFate.TOWN_REF) or not spoken.is_empty() or their or (strong and (bool(measure.people) or bool(measure.pronoun))) or (ids.is_empty() and bool(measure.get("stance_set",false)) and bool(measure.people))
	if not pointed: return {}
	var chosen:Dictionary={}
	if held.size()==1: chosen=held[0]
	elif not spoken.is_empty(): chosen=spoken
	else:
		var by_day:=held.duplicate()
		by_day.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.taken_day)>int(b.taken_day))
		if int(by_day[0].taken_day)-int(by_day[1].taken_day)>=RECENT_TAKING_DAYS: chosen=by_day[0]
	if chosen.is_empty():
		var names:Array[String]=[]
		for t:Dictionary in held: names.append(String(t.name))
		return {"kind":"which_town","target":{},"towns":names,"fate":{},"measures":ids,"measure":measure,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300),"implied":true}
	var reading:=_measure_reading(clean,main,chosen,measure,army)
	if not reading.is_empty(): reading["implied"]=true
	return reading

static func conditional_reading(text:String,audience_id:String)->Dictionary:
	## Harm only on a condition ("whoever resists, kill him") while we hold a
	## town (the one spoken of, or the only one): the garrison's standing word.
	var measure:=Measures.read(text)
	if measure.is_empty() or String(measure.get("clause",""))=="": return {}
	var held:=held_towns()
	var town:=_town_in_audience(held,audience_id)
	if town.is_empty() and held.size()==1: town=held[0]
	if town.is_empty(): return {}
	return {"kind":"measure","target":town,"measures":(measure.measures as Array).duplicate(),"measure":measure,"fate":{},"full":false,"insist":false,"place":"","army_words":false,"text":text.strip_edges().substr(0,300),"implied":true}

static func pronoun_harm_reading(text:String,audience_id:String)->Dictionary:
	## "Kill them" at court with nobody named: when we hold a town, the one
	## spoken of (or the only one) and the war leader's one question about it.
	var held:=held_towns()
	var town:=_town_in_audience(held,audience_id)
	if town.is_empty() and held.size()==1: town=held[0]
	if town.is_empty(): return {}
	return {"kind":"town_word","target":town,"full":false,"insist":false,"place":"","army_words":false,"text":text.strip_edges().substr(0,300),"implied":true}

## "The women too", "now the children", "take the women too": the same
## order again for another group of the same town, said just after it
## (audience town_order). A plain verb may lead ("take", "bind", "round up");
## one that names a different deed ("kill the women") or a place to take them
## ("take the women to Seanstone") is its own order.
const FOLLOW_UP_RE:="^(?:(?:and|now|also|then|yes|good|next|right|the same for|same for|do the same (?:to|with|for)|the same (?:to|with|for)|take|get|grab|seize|bind|tie up|tie|round up|do)[,]?\\s+)*(?:all\\s+)?(?:of\\s+)?(?:the\\s+|their\\s+)?(?<who>women|womenfolk|wives|children|boys|girls|old people|old men|old women|old ones|elders|the rest|rest|others|rest of them|everyone else|everybody else|men|males)(?:\\s+of\\s+[a-z'-]+)?(?:\\s+(?:too|as well|also|next|now|up))*\\W*$"

static func follow_up(clean:String,audience_id:String)->Dictionary:
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or not audience.get("town_order") is Dictionary: return {}
	var last:Dictionary=audience.town_order
	if Hall._day()-int(last.get("day",-99))>PENDING_DAYS: return {}
	var lower:=clean.to_lower().strip_edges()
	var m:=_re(FOLLOW_UP_RE).search(lower)
	if m==null: return {}
	var word:=m.get_string("who")
	var town:=_held_town(String(last.get("city_id","")))
	if town.is_empty(): return {}
	var who:=_group_of(word)
	var words:=_group_words(who)
	var name:=String(town.get("name","the town"))
	var base:={"target":town,"full":false,"insist":false,"place":"","army_words":false,"text":clean.substr(0,300),"implied":true,"follow_up":true}
	var ids:Array=last.get("measures",[])
	var fate:Dictionary=last.get("fate",{}) if last.get("fate") is Dictionary else {}
	if bool(fate.get("kill_men",false)):
		# Killing more is grave: one question, with the choices.
		var ask:=base.duplicate(); ask["kind"]="follow_kill"; ask["who"]=who
		return ask
	if ids.has("bind_men"):
		var measure:=Measures.read("Round up the %s of %s and bind them" % [words,name])
		measure["who"]=who
		var bind:=base.duplicate(); bind["kind"]="measure"; bind["measures"]=["bind_men"]; bind["measure"]=measure; bind["fate"]={}
		return bind
	if bool(fate.get("captives",false)):
		var take:=base.duplicate(); take["kind"]="fate"
		take["fate"]={"captives":true,"take":{} if who=="people" else {who:1.0}}
		if who=="people": (take.fate as Dictionary)["take"]={"women":1.0,"children":1.0,"elders":1.0,"men":1.0}
		# "The boys too": which of the children (town_ledger's make-up).
		var kw:=TownFate.kid_words(word)
		if who=="children" and not kw.is_empty():
			(take.fate as Dictionary)["kids"]=kw.bands
			(take.fate as Dictionary)["kids_words"]=String(kw.words)
		return take
	return {}

## The ledger's group for a word: "girls" -> children; "the rest" -> people.
static func _group_of(word:String)->String:
	match word:
		"women","womenfolk","wives": return "women"
		"children","boys","girls": return "children"
		"old people","old men","old women","old ones","elders": return "elders"
		"men","males": return "men"
	return "people"

static func _group_words(who:String)->String:
	return String({"men":"men","women":"women","children":"children","elders":"old people"}.get(who,"people"))

## An order about a town's people remembered for a follow-up ("the women too").
static func _note_town_order(out:Dictionary,town:Dictionary,ids:Array,fate:Dictionary)->void:
	var audience:=Hall.find(String(out.get("audience_id","")))
	if audience.is_empty(): return
	audience["town_order"]={"city_id":String(town.get("city_id","")),"measures":ids.duplicate(),"fate":fate.duplicate(),"day":Hall._day()}

static func _follow_kill(out:Dictionary,reading:Dictionary)->Dictionary:
	## "The women too" after the men were killed: the war leader asks once,
	## his own reading first; an unclear answer is that reading.
	var town:Dictionary=reading.get("target",{})
	var name:=String(town.get("name","the town"))
	var who:=String(reading.get("who","people"))
	var words:=_group_words(who)
	var groups:Array=Ledger.GROUPS.duplicate() if who=="people" else [who]
	var options:=[
		{"kind":"fate","id":"kill_"+who,"fate":{"kill_men":true,"kill_groups":groups},"stance":"firm","words":"put the %s to death as well" % words,"order":"Kill the %s of %s" % [words,name],"keys":["kill","death","sword","yes"]},
		{"kind":"measure","id":"bind_men","who":who,"stance":"firm","words":"bind them and keep them under guard","order":"Round up the %s of %s and bind them" % [words,name],"keys":["bind","tie","guard","round up"]},
		{"kind":"measure","id":"word","tone":"lenient","stance":"lenient","words":"leave them be","order":"Leave the %s of %s be" % [words,name],"keys":["leave","spare","alone","let them be"]}]
	var audience_id:=String(out.get("audience_id",""))
	var key:="follow:%s:%s" % [String(town.get("city_id","")),who]
	var question:="The %s of %s as well? I can %s, %s, or %s." % [words,name,String(options[0].words),String(options[1].words),String(options[2].words)]
	if _asked(audience_id,key)>=1:
		var again:=reading.duplicate()
		again["kind"]="fate"; again["nearest"]=true; again["fate"]=(options[0].fate as Dictionary).duplicate(true)
		var done:=_fate(out,again)
		if String(done.verdict)=="fate": done.says="You said it again, so I take it you mean me to %s. %s" % [String(options[0].words),String(done.says)]
		return done
	_mark_asked(audience_id,key)
	out.verdict="ask"; out.reason="measure_ask"
	out["target"]=town.duplicate(true)
	out.says=question
	out.fix="Say which; if you only say go on, I do the first."
	out.outcome="Nothing is done yet at %s." % name
	out["pending"]={"ask":"measure","confirm":true,"region_id":String(town.get("city_id","")),"options":options,"nearest":options[0],"question":question,"text":String(options[0].order)}
	return out

static func _implied_word(clean:String,lower:String,audience_id:String)->Dictionary:
	## An order that names no measure, about the people of a town this
	## audience is speaking of ("punish them", "deal with the men there"): the
	## war leader's nearest reading of it, never silence.
	if not Measures.looks_like_order(clean): return {}
	if not (_has(lower,"(them|their|they)\\b") or _has(lower,TownFate.GROUP_WORDS) or _has(lower,TownFate.TOWN_REF)): return {}
	var held:=held_towns()
	if held.is_empty(): return {}
	var town:=_town_in_audience(held,audience_id)
	if town.is_empty() and held.size()==1 and _has(lower,TownFate.TOWN_REF): town=held[0]
	if town.is_empty(): return {}
	return {"kind":"town_word","target":town,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":false,"text":clean.substr(0,300),"implied":true}

static func _any_war()->bool:
	if WorldSimulation.world==null: return false
	for c:Dictionary in WorldSimulation.world.civilizations:
		var rel:Dictionary=c.get("player_relation",{}) if c.get("player_relation") is Dictionary else {}
		if bool(rel.get("at_war",false)): return true
	return false

static func pending_answer(audience:Dictionary,clean:String)->Dictionary:
	## The god's answer to the war leader's own question: "Shall I send some
	## after them?" or "Leave Tsaren unguarded?". A reading, or {}.
	var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if pending.is_empty() or Hall._day()-int(pending.get("day",-99))>PENDING_DAYS+2: return {}
	var ask:=String(pending.get("ask",""))
	if ask=="": return {}
	var lower:=clean.to_lower().strip_edges()
	var yes:=_re(YES_WORDS).search(lower)!=null
	var no:=_re(NO_WORDS).search(lower)!=null and not yes
	var town:=_held_town(String(pending.get("region_id","")))
	var base:={"target":town,"full":false,"insist":false,"place":"","army_words":false,"text":clean.substr(0,300),"answer":true}
	# A whole new order about the town's people ("Untie the men of Tsaren and
	# let them go back to their houses") is read on its own, never as the
	# answer "let them go" to "Shall I send some after them?". A plain yes or
	# no, or words about "them" alone, still answer the question.
	if ask in ["chase","abandon"] and not yes and not no and own_order(clean): return {}
	if ask=="chase":
		if no or _has(lower,"(let them (go|run)|leave them|not worth)"): base["kind"]="let_go"; return base
		if yes or _has(lower,CHASE_WORDS):
			var n:=_re("\\b(\\d{1,4})\\b").search(lower)
			base["kind"]="pursue"; base["count"]=int(n.get_string(1)) if n!=null else 0; return base
	elif ask=="abandon":
		if no: base["kind"]="keep"; return base
		if yes or _has(lower,"(abandon|leave it|leave (the town|them)|unguarded|come home|bring them home)"):
			base["kind"]="abandon"; base["towns"]=(pending.get("towns",[]) as Array).duplicate(); return base
	elif ask=="measure":
		# The war leader asked one question with its options. A clear new
		# order about the town is read on its own; an option named or counted
		# ("the second", "bind them") is that option; "no" drops it; anything
		# else is taken as his own nearest reading, never asked again.
		if town.is_empty(): return {}
		var options:Array=pending.get("options",[])
		var pick:=_option_named(lower,options)
		if pick.is_empty() and (not Measures.read(clean).is_empty() or not TownFate.fate_words(lower).is_empty()): return {}
		if pick.is_empty() and no: base["kind"]="measure_drop"; return base
		var chosen:Dictionary=pick if not pick.is_empty() else (pending.get("nearest",{}) as Dictionary)
		if chosen.is_empty(): return {}
		base["kind"]="measure" if String(chosen.get("kind","measure"))=="measure" else "fate"
		base["measures"]=[String(chosen.id)] if base.kind=="measure" else []
		base["fate"]=(chosen.get("fate",{}) as Dictionary).duplicate(true)
		base["measure"]={"stance":String(chosen.get("stance","firm")),"stance_set":String(chosen.get("stance","firm"))!="firm","words":String(pending.get("text","")),"who":String(chosen.get("who","men")),"tone":String(chosen.get("tone",""))}
		# "Bind the children" to "The women as well?": the group the words name.
		var named:=_named_group(lower)
		if named!="" and not pick.is_empty():
			if base.kind=="measure" and (base.measure as Dictionary).has("who"): (base.measure as Dictionary)["who"]=named
			elif bool((base.fate as Dictionary).get("kill_men",false)): (base.fate as Dictionary)["kill_groups"]=Ledger.GROUPS.duplicate() if named=="people" else [named]
		base["taken"]=pick.is_empty() and not yes
		base["taken_words"]=String(chosen.get("words",""))
		return base
	return {}

## A whole order of its own about a town's people: a measure or a fate that
## names the people ("the men of Tsaren", "the women"), not "them" alone.
static func own_order(clean:String)->bool:
	var m:=Measures.read(clean)
	if not m.is_empty() and bool(m.get("people",false)) and not (m.get("measures",[]) as Array).is_empty(): return true
	var lower:=clean.to_lower()
	var fate:=TownFate.fate_words(lower)
	return not fate.is_empty() and _has(lower,TownFate.GROUP_WORDS) and not _re("^\\W*(them|those|these|they)\\b").search(lower)

## The one group of a town's people the words name: "men", "women",
## "children", "elders", "people" (everyone), or "".
static func _named_group(lower:String)->String:
	if _has(lower,"(everyone|everybody|all of them|them all|the rest|everyone else|the people)\\b"): return "people"
	var found:Array[String]=[]
	if _has(lower,"(women|womenfolk|wives)\\b"): found.append("women")
	if _has(lower,"(children|boys|girls)\\b"): found.append("children")
	if _has(lower,"(elders|old people|old men|old women|old ones)\\b"): found.append("elders")
	if _has(lower.replace("old men","old ones"),"(men|males)\\b"): found.append("men")
	return found[0] if found.size()==1 else ""

## "The second", "the last", or the words of one option, in an answer.
static func _option_named(lower:String,options:Array)->Dictionary:
	if options.is_empty(): return {}
	var ordinals:=[["first","1st"],["second","2nd"],["third","3rd"]]
	for i in mini(options.size(),ordinals.size()):
		for word in ordinals[i]:
			if _has(lower,"%s\\b" % String(word)): return options[i]
	if _has(lower,"last( one)?\\b"): return options[options.size()-1]
	# "One", "number two", "option three" on their own.
	var counted:=_re("^\\W*(?:the |number |option |choice )?(one|two|three)\\W*$").search(lower.strip_edges())
	if counted!=null:
		var at:=["one","two","three"].find(counted.get_string(1))
		if at>=0 and at<options.size(): return options[at]
	for option in options:
		for key in (option as Dictionary).get("keys",[]):
			if _has(lower,String(key)): return option
	return {}

static func _implied_town(clean:String,lower:String,named:Dictionary,army:bool,audience_id:String)->Dictionary:
	## A fate order that names no town. With one town held, it is that town;
	## with several, the one spoken of in this audience, else the one taken
	## last if it was clearly the latest; otherwise the war leader asks which
	## ("which_town"). Holding none, violence to a people is answered plainly
	## ("no_town"): there is nobody of theirs in our hands.
	var fate:=TownFate.fate_words(lower)
	if not TownFate.implicit(fate,lower): return {}
	# A town of ours that nobody of ours holds, named: what is true of it
	# (take_first says who holds it and what became of those we held).
	if bool(named.get("unguarded",false)) and _name_hit(lower,String(named.get("name",""))):
		return {"kind":"take_first","target":named,"fate":fate,"harm":"kill" if bool(fate.get("kill_men",false)) else "","full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300),"implied":true}
	# A foreign town named by its own name is not a town we hold.
	if named.has("city_id") and _name_hit(lower,String(named.get("name",""))): return {}
	if named.has("unknown") and _name_hit(lower,String(named.unknown)) and String(named.get("civ_id",""))=="": return {}
	var group:=bool(fate.get("group",false)) and (bool(fate.get("kill_men",false)) or bool(fate.get("captives",false)) or String(fate.get("move",""))!="" or bool(fate.get("free",false)))
	# "Burn their town" with a foreign town in mind stays an attack.
	if not group and not named.is_empty() and not named.has("ambiguous"): return {}
	var held:=held_towns()
	var people:=String(named.get("civ_id",""))
	if people!="":
		var theirs:Array[Dictionary]=[]
		for t:Dictionary in held:
			if String(t.civ_id)==people: theirs.append(t)
		if not theirs.is_empty(): held=theirs
	var base:={"fate":fate,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300),"implied":true}
	if held.is_empty():
		if not group: return {}
		# The town this audience is speaking of, not ours now: said plainly
		# why nobody of it is in our hands, and what it would take.
		var spoken:=_place_in_audience(audience_id)
		if spoken.has("city_id") and (people=="" or String(spoken.get("civ_id",""))==people):
			var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=spoken
			return first
		var none:=base.duplicate(); none["kind"]="no_town"; none["target"]={}
		return none
	var chosen:Dictionary={}
	if held.size()==1: chosen=held[0]
	else:
		chosen=_town_in_audience(held,audience_id)
		if chosen.is_empty():
			var by_day:=held.duplicate()
			by_day.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.taken_day)>int(b.taken_day))
			if int(by_day[0].taken_day)-int(by_day[1].taken_day)>=RECENT_TAKING_DAYS: chosen=by_day[0]
	if chosen.is_empty():
		var ask:=base.duplicate(); ask["kind"]="which_town"; ask["target"]={}
		var names:Array[String]=[]
		for t:Dictionary in held: names.append(String(t.name))
		ask["towns"]=names
		return ask
	var out:=base.duplicate(); out["kind"]="fate"; out["target"]=chosen
	return out

static func group_harm_reading(text:String,verb:String="kill",object:String="",context_civ:String="",audience_id:String="")->Dictionary:
	## An order to kill or maim a people ("kill all the males of Tsaren",
	## "put Tsaren's men to the sword", "kill them all") read as what it is:
	## the fate of a town we hold, or, when the town is still theirs, a town
	## that must be taken first ("take_first": the war leader asks to march).
	## Never {} and never a person: court_commands.gd routes every such order
	## here so it cannot fall on anyone in the hall.
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	var reading:=read(clean,context_civ,audience_id)
	var kind:=String(reading.get("kind",""))
	# "Kill the ringleaders", "if any run, kill them": a measure or a standing
	# word to the garrison, never every man in the town. "Put the captives
	# to death": the captives of our last fight, never a town's people.
	if kind in ["measure","town_word","captives","follow_kill"]: return reading
	if kind in ["fate","which_town"] and bool((reading.get("fate",{}) as Dictionary).get("kill_men",false))==(verb=="kill"): return reading
	var measure:=Measures.read(clean)
	var main:=String(Measures.conditions(lower).main) if not measure.is_empty() else lower
	var fate:=TownFate.fate_words(main).duplicate()
	if String(measure.get("clause",""))!="" and not bool(fate.get("kill_men",false)):
		var held:=held_towns()
		var town:=_town_in_audience(held,audience_id)
		if town.is_empty() and held.size()==1: town=held[0]
		if not town.is_empty():
			return {"kind":"measure","target":town,"measures":(measure.measures as Array).duplicate(),"measure":measure,"fate":{},"full":false,"insist":false,"place":"","army_words":false,"text":clean.substr(0,300)}
	if verb=="kill": fate["kill_men"]=true
	fate["group"]=true
	var base:={"fate":fate,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":false,"text":clean.substr(0,300),"harm":verb,"group_harm":true}
	var target:=find_target(clean+(" "+object if object!="" else ""),context_civ)
	if target.is_empty() or target.has("ambiguous"):
		var spoken:=_place_in_audience(audience_id)
		if not spoken.is_empty(): target=spoken
	if bool(target.get("held",false)):
		var out:=base.duplicate(); out["kind"]="fate" if verb=="kill" else "group_maim"; out["target"]=target
		return out
	if target.has("city_id") or target.has("unknown") or target.has("ambiguous"):
		var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=target
		return first
	# No town named or meant: the one we hold, or ask which, or say we hold none.
	var held:=held_towns()
	if held.size()==1:
		var one:=base.duplicate(); one["kind"]="fate" if verb=="kill" else "group_maim"; one["target"]=held[0]
		return one
	if held.size()>1 and verb=="kill":
		var ask:=base.duplicate(); ask["kind"]="which_town"; ask["target"]={}
		var names:Array[String]=[]
		for t:Dictionary in held: names.append(String(t.name))
		ask["towns"]=names
		return ask
	var none:=base.duplicate(); none["kind"]="no_town"; none["target"]={}
	return none

static func _place_in_audience(audience_id:String)->Dictionary:
	## The town, ours or theirs, last named in this audience: "kill them all"
	## said while speaking of Tsaren means Tsaren's people.
	if audience_id=="": return {}
	var lines:Array=Hall.find(audience_id).get("lines",[])
	var places:Array[Dictionary]=held_towns()
	places.append_array(known_places())
	for i in range(lines.size()-1,maxi(-1,lines.size()-16),-1):
		var said:=String((lines[i] as Dictionary).get("text","")).to_lower()
		var hits:Array[Dictionary]=[]
		for t:Dictionary in places:
			if _name_hit(said,String(t.name)): hits.append(t)
		if hits.size()==1: return hits[0]
	return {}

static func _town_in_audience(held:Array,audience_id:String)->Dictionary:
	## The held town last spoken of in this audience, by anyone.
	if audience_id=="": return {}
	var lines:Array=Hall.find(audience_id).get("lines",[])
	for i in range(lines.size()-1,maxi(-1,lines.size()-16),-1):
		var said:=String((lines[i] as Dictionary).get("text","")).to_lower()
		var hits:Array[Dictionary]=[]
		for t:Dictionary in held:
			if _name_hit(said,String(t.name)): hits.append(t)
		# "Which town, Tsaren or Varo?" points at neither.
		if hits.size()==1: return hits[0]
	return {}

static func read_live(object:String,text:String,context_civ:String="",audience_id:String="")->Dictionary:
	## The live reading named verb "war"; its object carries the kind and
	## place ("attack Tsaren", "siege Tsaren", "march home"). The engine still
	## reads the ruler's own words first.
	var own:=read(text,context_civ,audience_id)
	if not own.is_empty(): return own
	var from_object:=read(object,context_civ,audience_id)
	if not from_object.is_empty():
		from_object["full"]=bool(from_object.full) or _has(text.to_lower(),FULL_WORDS)
		from_object["insist"]=bool(from_object.insist) or _has(text.to_lower(),INSIST_WORDS)
		from_object["text"]=text.substr(0,300)
		return from_object
	# The model says it is a war order but neither text names what: ask.
	return {"kind":"attack","target":find_target(object+" "+text,context_civ),"full":false,"insist":false,"place":"","army_words":true,"text":text.substr(0,300),"vague":true}

static func offline_choices(audience_id:String="")->Array[Dictionary]:
	## Offline the court offers war orders as choices built from real state
	## (known towns, the war leader's own band, armies away, enemies seen);
	## each is the same words the god could type, so both reach perform()
	## through court_commands.hear(). After an objection the god's two answers
	## to it come first: take them as they are, or drill them first.
	var out:Array[Dictionary]=[]
	if WorldSimulation.military==null or WorldSimulation.world==null: return out
	var audience:Dictionary=Hall.find(audience_id) if audience_id!="" else {}
	var general:=war_leader(_speaker_of(audience))
	var band:=_band_of(general)
	var who:=_given(String(general.get("name","")))
	var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if bool(pending.get("which_town",false)) and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS:
		# "Which town?": each town we hold is an answer.
		for town:Dictionary in held_towns():
			out.append({"group":"war","label":String(town.name),"action":"command","params":{"command_text":String(town.name)}})
	elif String(pending.get("ask",""))=="chase" and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS+2:
		# "Shall I send some after them?"
		out.append({"group":"war","label":"Go after them","action":"command","params":{"command_text":"Yes, go after them"}})
		out.append({"group":"war","label":"Let them go","action":"command","params":{"command_text":"No, let them go"}})
	elif String(pending.get("ask",""))=="abandon" and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS+2:
		# "Leave Tsaren unguarded?"
		var towns:=" and ".join(PackedStringArray(pending.get("towns",[])))
		out.append({"group":"war","label":"Leave %s and come home" % towns,"action":"command","params":{"command_text":"Yes, leave %s and come home" % towns}})
		out.append({"group":"war","label":"Keep the garrison there","action":"command","params":{"command_text":"No, keep the garrison there"}})
	elif String(pending.get("ask",""))=="measure" and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS+2:
		# The war leader's one question about a held town: each option, or leave it.
		var asked_town:=_held_town(String(pending.get("region_id","")))
		var tname:=String(asked_town.get("name","the town"))
		for option in pending.get("options",[]):
			var o:Dictionary=option
			var words:=Measures.order_words(String(o.id),tname) if String(o.get("kind",""))=="measure" else ("Burn %s" % tname if String(o.id)=="raze" else "Put the men of %s to the sword" % tname)
			out.append({"group":"war","label":_cap(String(o.get("words",words))),"action":"command","params":{"command_text":words}})
		out.append({"group":"war","label":"Leave them be","action":"command","params":{"command_text":"No, leave them be"}})
	elif not pending.is_empty() and String(pending.get("verb",""))=="war" and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS:
		out.append({"group":"war","label":"Take them as they are","action":"command","params":{"command_text":"Take them as they are"}})
		out.append({"group":"war","label":"Drill them first","action":"command","params":{"command_text":"Drill them first"}})
	# A town we hold: every decision about it is made here (the occupation
	# screen only reports). Each choice is words the god could type.
	for town:Dictionary in held_towns().slice(0,2):
		var n:=String(town.name)
		for row in [["Spare %s and hold it","Spare %s and hold it"],["Take captives and burn %s","Take captives home and burn %s"],
				["Put the men of %s to the sword","Put the men of %s to the sword"],["Take tribute from %s and leave","Take tribute from %s and leave"],
				["Govern %s as ours","Govern %s well as a town of ours"],["Rule %s by the spear","Rule %s by the spear"],["Let %s keep its own elders","Let %s govern themselves"],
				["Make %s's people our own","Make the people of %s our own, equal citizens"],["Enslave the people of %s","Enslave the people of %s"],
				["Bring 20 of %s's people home as our own","Bring 20 people of %s home as our own"],["Rebuild %s","Rebuild %s"],
				["Strengthen the garrison at %s","Strengthen the garrison at %s"],["Give %s back and come home","Give %s back and come home"]]:
			out.append({"group":"war","label":String(row[0]) % n,"action":"command","params":{"command_text":String(row[1]) % n}})
		# What the garrison does with its people, from what is in force there.
		out.append_array(garrison_choices(town))
	# A siege of ours: storm it now, or keep them shut in.
	var siege:Dictionary=WorldSimulation.military.active_siege
	if not siege.is_empty() and String(siege.get("mode",""))=="offensive":
		var walled:=String((siege.get("threat",{}) as Dictionary).get("target_region_name","the town"))
		out.append({"group":"war","label":"Storm the walls of %s" % walled,"action":"command","params":{"command_text":"Storm the walls of %s" % walled}})
	var places:=known_places()
	var home:Vector2=WorldSimulation.world.player_world_origin
	places.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return home.distance_squared_to(Vector2(float(a.position.x),float(a.position.z)))<home.distance_squared_to(Vector2(float(b.position.x),float(b.position.z))))
	for p:Dictionary in places.slice(0,3):
		var name:=String(p.name).trim_prefix("Reported home of ")
		if not band.is_empty():
			out.append({"group":"war","label":"March %s's band on %s" % [who,name],"action":"command","params":{"command_text":"March your band on %s" % name}})
		else:
			out.append({"group":"war","label":"March on %s" % name,"action":"command","params":{"command_text":"March our army on %s" % name}})
		out.append({"group":"war","label":"Lay siege to %s" % name,"action":"command","params":{"command_text":"Lay siege to %s" % name}})
		out.append({"group":"war","label":"Raid the fields of %s" % name,"action":"command","params":{"command_text":"Raid the fields of %s" % name}})
	for formation in WorldSimulation.world.foreign_formations:
		if String((formation as Dictionary).get("kind",""))!="scout" and not WorldSimulation.world.visible_formation_sighting(String(formation.get("id",""))).is_empty():
			out.append({"group":"war","label":"Go after %s's army" % Hall._civ_name(String(formation.get("civ_id",""))),"action":"command","params":{"command_text":"Attack their army, the %s" % Hall._civ_name(String(formation.get("civ_id","")))}})
			break
	if not band.is_empty() and _drill(band.get("formations",[]))<UNDRILLED and pending.is_empty():
		out.append({"group":"war","label":"Drill %s's band" % who,"action":"command","params":{"command_text":"Bring your band home to drill"}})
	if not Pursuit.detachments().is_empty():
		out.append({"group":"war","label":"Call the detachment back","action":"command","params":{"command_text":"Call off the chase and come back"}})
	if not (forces(general).away as Array).filter(func(a:Dictionary)->bool: return not a.get("pursuit") is Dictionary).is_empty():
		out.append({"group":"war","label":"Bring the army home","action":"command","params":{"command_text":"Bring the army home"}})
	out.append({"group":"war","label":"Keep the soldiers home on watch","action":"command","params":{"command_text":"Defend our home with the soldiers"}})
	return out

static func garrison_choices(town:Dictionary)->Array[Dictionary]:
	## Offline, the garrison's measures for a town we hold are offered as the
	## same words the god could type, chosen from what is in force there.
	var out:Array[Dictionary]=[]
	var n:=String(town.get("name",""))
	if n=="": return out
	var running:={}
	for m:Dictionary in Measures.active(String(town.civ_id),String(town.city_id)): running[String(m.id)]=true
	var rows:Array=[]
	if running.has("bind_men"): rows.append(["Free the bound men of %s","Free the men of %s"])
	else: rows.append(["Round up and bind the men of %s","Round up the men of %s and bind them"])
	if not running.has("disarm"): rows.append(["Take the weapons of %s","Take the weapons of %s"])
	if running.has("hostages"): rows.append(["Send the hostages of %s home","Free the hostages of %s"])
	else: rows.append(["Take hostages from %s","Take hostages from %s"])
	if not running.has("curfew"): rows.append(["Keep %s indoors after dark","Keep the people of %s in their houses"])
	rows.append(["Search every house in %s","Search every house in %s"])
	if not running.has("labour"): rows.append(["Make the men of %s build a wall","Make the men of %s build a wall round the town"])
	if not running.has("requisition"): rows.append(["Take the food stores of %s","Take the food stores of %s"])
	if not running.has("conscript"): rows.append(["Take the young men of %s into our bands","Take the young men of %s into our bands"])
	rows.append(["Put the ringleaders of %s to death","Put the ringleaders of %s to death"])
	if not running.has("relief"): rows.append(["Feed and protect the people of %s","Feed the people of %s and protect them"])
	if not running.has("set_headman"): rows.append(["Set one of ours over %s","Set one of ours over %s as headman"])
	if not running.has("settle"): rows.append(["Send our families to settle in %s","Send some of our families to settle in %s"])
	for row in rows:
		out.append({"group":"garrison","label":String(row[0]) % n,"action":"command","params":{"command_text":String(row[1]) % n}})
	return out

# --------------------------------------------------------------------------
# What there is to send
# --------------------------------------------------------------------------

static func _mc()->Node:
	return WorldSimulation.military

static func _strength(formations:Array)->float:
	var total:=0.0
	for f in formations:
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		var gear:=clampf(float(f.get("equipment",0))/maxf(1.0,float(f.get("equipment_required",count))),0.0,1.0)
		total+=count*(0.35+0.65*clampf(float(f.get("training",0.3)),0.0,1.0))*(0.45+0.55*gear)
	return total

static func _drill(formations:Array)->float:
	## Head-weighted drill (training) of a force, 0..1.
	var heads:=0; var drill:=0.0
	for f in formations:
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		heads+=count; drill+=count*clampf(float(f.get("training",0.0)),0.0,1.0)
	return drill/float(heads) if heads>0 else 0.0

static func _unarmed(formations:Array)->int:
	## Heads in a force with no weapon of their own (equipment short of need).
	var out:=0
	for f in formations:
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		var need:=maxi(0,int(f.get("equipment_required",count)))
		if count<=0 or need<=0: continue
		var short:=maxi(0,need-int(f.get("equipment",0)))
		out+=mini(count,ceili(float(short)*float(count)/float(need)))
	return out

## Camp drill (MilitaryCampaign.TRAINING_PROGRAMS.camp_drill): a levy at home
## gains about this much drill over this many days.
const CAMP_DRILL_GAIN:=0.065
const CAMP_DRILL_DAYS:=84.0

static func _drill_days_to_fit(formations:Array)->int:
	## About how many days of camp drill at home before this force is fit to
	## lead at walls (UNDRILLED). 0 when it already is.
	var drill:=_drill(formations)
	if formations.is_empty() or drill>=UNDRILLED: return 0
	return maxi(1,ceili((UNDRILLED-drill)/CAMP_DRILL_GAIN*CAMP_DRILL_DAYS))

static func _trainees()->Dictionary:
	## Recruits still in their first drill at home, as they really stand:
	## {heads, days (to the end of drill), drill (0..1 of the course), unarmed}.
	var mc:=_mc()
	var heads:=0; var days:=0; var share:=0.0; var unarmed:=0
	var stock:Dictionary=(mc.military_inventory as Dictionary).duplicate()
	for t in mc.training_queue:
		var entry:Dictionary=t
		var count:=maxi(0,int(entry.get("count",0)))
		if count<=0: continue
		heads+=count
		var required:=maxf(1.0,float(entry.get("required_days",1)))
		share+=count*clampf(float(entry.get("progress_days",0))/required,0.0,1.0)
		days=maxi(days,ceili(maxf(0.0,required-float(entry.get("progress_days",0)))))
		var need:int=mc._equipment_required_for(String(entry.get("unit","levy")),count)
		var held:=int(entry.get("reserved_equipment",0))
		if not entry.has("deployment_line"):
			var weapon:=String(entry.get("weapon","improvised"))
			var take:=mini(maxi(0,need-held),maxi(0,int(stock.get(weapon,0))))
			stock[weapon]=int(stock.get(weapon,0))-take; held+=take
		if need>0: unarmed+=mini(count,ceili(float(maxi(0,need-held))*float(count)/float(need)))
	return {"heads":heads,"days":days,"drill":share/float(heads) if heads>0 else 0.0,"unarmed":unarmed}

static func _available(army:Dictionary)->bool:
	## A field army the war leader can give a new objective to now.
	var mc:=_mc()
	var id:=int(army.get("army_id",0))
	if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): return false
	if mc.command_hierarchy.battle.engaged(id): return false
	if army.has("court_order") and String(army.get("status",""))=="moving": return false
	if not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==id: return false
	if WorldSimulation.campaign!=null and WorldSimulation.campaign.active and id==int(WorldSimulation.campaign.state.get("army_id",-1)): return false
	return true

static func _at_home(army:Dictionary)->bool:
	return preload("res://scripts/hud/army_marks.gd").at_home(army,WorldSimulation.world.player_world_origin)

static func _band_of(general:Dictionary)->Dictionary:
	## The field army this war leader leads himself (his own band), wherever
	## it stands, when it can take an order. {} when he leads none.
	if general.is_empty() or WorldSimulation.military==null: return {}
	var fid:=String(general.get("figure_id",""))
	var pid:=int(general.get("person_id",0))
	var full_name:=String(general.get("name",""))
	for a in _mc().field_armies:
		var army:Dictionary=a
		if not _available(army): continue
		var c:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		if (fid!="" and String(c.get("figure_id",""))==fid) or (pid>0 and int(c.get("person_id",0))==pid) or (full_name!="" and String(c.get("name",""))==full_name): return army
	return {}

static func _where(army:Dictionary)->String:
	## Where a force stands, in plain words.
	if _at_home(army): return "at home"
	var p:Dictionary=army.get("position",{}) if army.get("position") is Dictionary else {}
	var km:=roundi(WorldSimulation.world.player_world_origin.distance_to(Vector2(float(p.get("x",0)),float(p.get("z",0)))))
	if String(army.get("status",""))=="moving": return "on the march, about %d km from home" % km
	return "camped about %d km from home" % km

static func forces(general:Dictionary={})->Dictionary:
	## Plain numbers the war leader answers from: the trained reserve at
	## home, the recruits in drill, his own band, other armies.
	var mc:=_mc()
	var home:Dictionary=mc.home_army
	var trained:=maxi(0,int(home.get("troops",0)))
	var t:=_trainees()
	var idle:Array[Dictionary]=[]
	var away:Array[Dictionary]=[]
	for a in mc.field_armies:
		var army:Dictionary=a
		if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): continue
		var at_home:=_at_home(army)
		if at_home and not mc.command_hierarchy.battle.engaged(int(army.army_id)) and not army.has("court_order"): idle.append(army)
		elif not at_home: away.append(army)
	# A fight elsewhere does not stop a march: the bands in it are simply not
	# free (engaged above). The captives of a fight never hold anything up:
	# the general settles them himself (MilitaryCampaign._settle_aftermath).
	var busy:=""
	if not mc.active_siege.is_empty(): busy="our soldiers are already besieging %s" % String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","a town"))
	elif not mc.active_threat.is_empty() and String(mc.active_threat.get("campaign_mode",""))=="defensive": busy="an enemy force is already coming at us"
	var garrisons:=held_towns()
	var holding:=0
	for town:Dictionary in garrisons: holding+=int(town.garrison)
	return {"trained":trained,"home_strength":_strength(home.get("formations",[])),"drilling":int(t.heads),"drill_days":int(t.days),"trainees":t,
		"idle":idle,"away":away,"busy":busy,"marching":_marching_on(),"band":_band_of(general),"garrisons":garrisons,"holding":holding}

static func _marching_on()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for a in _mc().field_armies:
		if (a as Dictionary).has("court_order") and String(a.get("status",""))=="moving": out.append(a)
	return out

static func _enemy_estimate(city_id:String)->Dictionary:
	var report:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var field:Dictionary=(report.get("fields",{}) as Dictionary).get("garrison",{})
	if field.is_empty(): return {"known":false,"age":int(report.get("age_days",-1))}
	var low:=float(field.get("low",0)); var high:=float(field.get("high",0))
	return {"known":true,"low":roundi(low),"high":roundi(high),"mid":(low+high)*0.5,"age":int(field.get("age_days",report.get("age_days",0)))}

static func _muster_trainees()->int:
	## "Take them as they are": every recruit still in drill leaves the drill
	## ground with the drill and weapons they have (MilitaryCampaign's own
	## completion, scaled by progress) and joins the trained reserve at home.
	var mc:=_mc()
	var mustered:=0
	var slots:Array=[]
	for index in range(mc.training_queue.size()-1,-1,-1):
		var order:Dictionary=mc.training_queue[index]
		var count:=maxi(0,int(order.get("count",0)))
		if count<=0: continue
		if order.has("deployment_line"): slots.append([int(order.deployment_line),int(order.get("deployment_slot",-1))])
		mc._complete_training(order)
		mc.training_queue.remove_at(index)
		mustered+=count
	# A recruitment line's cohort is spent; the line does not raise it again.
	for pair in slots:
		var line:Dictionary=mc.recruit_deploy.line(int(pair[0]))
		if not line.is_empty() and int(pair[1]) in (line.slots as Array):
			(line.slots as Array).erase(int(pair[1])); line.deployed=int(line.deployed)+1
	return mustered

# --------------------------------------------------------------------------
# Deciding and doing
# --------------------------------------------------------------------------

static func war_leader(speaker:Dictionary={})->Dictionary:
	## The war leader who answers: a summoned war leader of renown answers for
	## himself; otherwise the Marshal (war leader office); else a living war
	## leader of renown (HistoricalFigures General) who leads our bands.
	var figures:Variant=Engine.get_main_loop().root.get_node_or_null("HistoricalFigures") if Engine.get_main_loop() is SceneTree else null
	var fid:=String(speaker.get("figure_id",""))
	if fid!="" and figures!=null:
		var figure:Dictionary=figures.by_id(fid)
		if String(figure.get("role",""))=="General" and String(figure.get("status",""))!="dead":
			return {"name":String(figure.get("name","")),"person_id":0,"figure_id":fid}
	var marshal:=Hall._relevant_official(["Marshal"])
	if not marshal.is_empty(): return marshal
	if figures!=null:
		for figure in figures.people:
			if figure is Dictionary and String(figure.get("role",""))=="General" and String(figure.get("status",""))!="dead":
				return {"name":String(figure.get("name","")),"person_id":0,"figure_id":String(figure.get("id",""))}
	return {}

static func _speaker_of(audience:Dictionary)->Dictionary:
	## {figure_id} of a summoned war leader of renown, from the audience.
	var key:=String(audience.get("holder_key",""))
	if key.begins_with("figure:"): return {"figure_id":key.trim_prefix("figure:")}
	return {}

static func perform(reading:Dictionary,insist:bool=false,context:Dictionary={})->Dictionary:
	## The engine's answer: {verdict:"act"|"object"|"impossible", kind,
	## outcome (one short plain note), says (the war leader's own words, which
	## carry the answer), reason, fix, objective:{army_id,...} when acted}.
	## context.general: the war leader who was spoken to.
	## context.army_id: a band the god chose (the Army command screen); the
	##   same checks, objections and insistence apply, aimed at that band.
	## context.home_only: send from the home reserve (and recruits) only.
	## Pure of any UI.
	var kind:=String(reading.get("kind","attack"))
	insist=insist or bool(reading.get("insist",false))
	var given:Variant=context.get("general",{})
	var general:Dictionary=given if given is Dictionary and not (given as Dictionary).is_empty() else war_leader()
	var gname:=_given(String(general.get("name","The war leader")))
	var out:={"kind":kind,"general":gname,"general_pid":int(general.get("person_id",0)),"general_ref":general.duplicate(),"verdict":"impossible","outcome":"","says":"","reason":"","fix":"","objective":{},
		"chosen":maxi(0,int(context.get("army_id",0))),"home_only":bool(context.get("home_only",false)),"audience_id":String(context.get("audience_id",""))}
	if WorldSimulation.military==null or WorldSimulation.world==null:
		return _no(out,"no_military","We have nothing organised to fight with yet.","Raise and drill a levy first.")
	match kind:
		"measure": return _measure(out,reading)
		"town_word": return _town_word(out,reading)
		"measure_drop": return _measure_drop(out,reading)
		"recall": return _recall(out,reading)
		"defend": return _defend(out,reading)
		"intercept": return _intercept(out,reading,insist)
		"drill": return _drill_first(out)
		"fate": return _fate(out,reading)
		"which_town": return _which_town(out,reading)
		"no_town": return _no_town(out,reading)
		"take_first": return _take_first(out,reading)
		"group_maim": return _group_maim(out,reading)
		"storm": return _storm(out,insist)
		"held": return _held(out,reading.get("target",{}))
		"pursue": return _pursue(out,reading)
		"let_go": return _let_go(out,reading)
		"abandon": return _abandon(out,reading)
		"keep": return _keep(out,reading)
		"captives": return _captives(out,reading)
		"follow_kill": return _follow_kill(out,reading)
	if bool((reading.get("target",{}) as Dictionary).get("held",false)): return _held(out,reading.target)
	if bool((reading.get("target",{}) as Dictionary).get("ruin",false)): return _ruin(out,reading.target)
	if bool((reading.get("target",{}) as Dictionary).get("unguarded",false)): return _unguarded(out,reading.target)
	var struck:=_strike(out,reading,insist)
	# A strike by night: the chance of reaching them unseen, stated plainly.
	if String(struck.get("night_words",""))!="": struck["says"]=(String(struck.says)+" "+String(struck.night_words)).strip_edges()
	return struck

static func _ruin(out:Dictionary,town:Dictionary)->Dictionary:
	## A town we burned and left: nothing there to attack or burn again. Said
	## plainly from our own record, with who lives there now.
	var ruin:=Ledger.our_ruin(String(town.get("city_id","")))
	var rec:Dictionary=ruin.get("ruin",{})
	var c:=Ledger.counts(String(ruin.get("civ_id","")),String(town.get("city_id","")))
	var name:=String(ruin.get("name",town.get("name","the town")))
	out["target"]=town.duplicate(true)
	out.verdict="noted"; out.reason="ruin"
	out.objective={"army_id":0,"kind":"ruin","city_id":String(town.get("city_id",""))}
	var lives:="Nobody lives there now." if int(c.get("here",0))<=0 else "%s live in the ruins." % _cap(_number(int(c.here)))
	out.says="%s is a ruin; we burned it %s and nobody of ours holds it. %s There is nothing there to take or burn again." % [name,_in_season_words(int(rec.get("day",-1))),lives]
	out.outcome="%s is a ruin; nothing is done." % name
	return out

static func _unguarded(out:Dictionary,town:Dictionary)->Dictionary:
	## A town that is ours with nobody of ours in it: nothing to attack there.
	## Said plainly from who holds it (town_ledger.hold) and what became of
	## those we held.
	var h:=Ledger.hold_at(String(town.get("city_id","")))
	var name:=String(town.get("name","the town"))
	out["target"]=town.duplicate(true)
	var c:=Ledger.counts(String(h.get("civ_id","")),String(town.get("city_id","")))
	var went:=String(c.get("went_free_words",""))
	var failed:=_no(out,"unguarded","%s%s There is nothing there to attack; to hold it again, a band must go and stand in it." % [Ledger.hold_words(h),(" "+went) if went!="" else ""],"")
	failed.outcome="Nothing is done: %s is ours, and nobody of ours is there." % name
	return failed

static func _in_season_words(day:int)->String:
	if day<0: return "some time ago"
	var parts:=preload("res://scripts/hud/era_words.gd").when(day).split(" · ")
	return "in the %s of %s" % [parts[1].to_lower(),parts[0]] if parts.size()==2 else "in "+String(parts[0])

static func _held_words(town:Dictionary)->String:
	var who:=_given(String(town.get("commander","")))
	var holder:=("%s's garrison" % who) if String(town.get("commander",""))!="" else "our garrison"
	return "%s is already ours. %s of %s hold%s it." % [String(town.name),_cap(_number(int(town.garrison))),holder,"s" if int(town.garrison)==1 else ""]

static func _held(out:Dictionary,town:Dictionary)->Dictionary:
	## An attack on a town we hold: the war leader says so, with who holds it,
	## and asks what is to become of it; told again, he says it differently
	## and asks nothing he has asked already.
	var band:Dictionary=forces(out.general_ref).band
	var mine:=" I have %s with me." % _number(int(band.troops)) if not band.is_empty() else ""
	out.verdict="held"; out.reason="already_ours"; out["target"]=town.duplicate(true)
	var times:=_asked(String(out.get("audience_id","")),"held:"+String(town.get("city_id","")))
	match times:
		0: out.says="%s%s Tell me what is to become of it and its people: spare it and hold it, take captives and burn it, put the men to death, or take tribute and leave." % [_held_words(town),mine]
		1: out.says="%s%s Nobody needs to march on it. If you want something done there, say what the garrison is to do: bind the men, take their weapons or their food, set one of ours over them, or give it back." % [_held_words(town),mine]
		_: out.says="%s%s Nobody needs to march; the garrison there waits for your word." % [_held_words(town),mine]
	_mark_asked(String(out.get("audience_id","")),"held:"+String(town.get("city_id","")))
	out.fix=""
	out.outcome="%s is already ours." % String(town.name)
	return out

# --------------------------------------------------------------------------
# What the garrison does with the people of a town we hold
# --------------------------------------------------------------------------

## Remembered per audience: what the war leader already said or asked, so the
## same question is never put twice.
static func _asked(audience_id:String,key:String)->int:
	if audience_id=="": return 0
	var said:Dictionary=Hall.find(audience_id).get("war_said",{}) if Hall.find(audience_id).get("war_said") is Dictionary else {}
	var entry:Dictionary=said.get(key,{}) if said.get(key) is Dictionary else {}
	if entry.is_empty() or Hall._day()-int(entry.get("day",-99))>ASKED_DAYS: return 0
	return int(entry.get("count",0))

static func _mark_asked(audience_id:String,key:String)->void:
	if audience_id=="": return
	var audience:=Hall.find(audience_id)
	if audience.is_empty(): return
	var said:Dictionary=audience.get("war_said",{}) if audience.get("war_said") is Dictionary else {}
	var entry:Dictionary=said.get(key,{}) if said.get(key) is Dictionary else {}
	var fresh:=not entry.is_empty() and Hall._day()-int(entry.get("day",-99))<=ASKED_DAYS
	said[key]={"count":(int(entry.get("count",0)) if fresh else 0)+1,"day":Hall._day()}
	while said.size()>16: said.erase(said.keys()[0])
	audience["war_said"]=said

static func _measure_opts(reading:Dictionary)->Dictionary:
	var m:Dictionary=reading.get("measure",{}) if reading.get("measure") is Dictionary else {}
	var opts:={"stance":String(m.get("stance","firm")),"stance_set":bool(m.get("stance_set",false)),"families":bool(m.get("families",false)),"clause":String(m.get("clause","")),
		"who":String(m.get("who","men")),"work":String(m.get("work","")),"work_who":String(m.get("work_who","men")),"count":int(m.get("count",0)),"headman":String(m.get("headman","")),"release":(m.get("release",[]) as Array).duplicate(),"release_who":String(m.get("release_who","people")),
		"destroy":bool(m.get("destroy",false)),"heavy":bool(m.get("heavy",false)),"tone":String(m.get("tone","")),"words":String(m.get("words",reading.get("text","")))}
	return opts

static func _measure(out:Dictionary,reading:Dictionary)->Dictionary:
	## The garrison carries out what the god said about a town we hold
	## (occupation_measures.gd), with any fate the same words decide
	## (town_fate.gd) after it: "round up the men and put them to the sword"
	## binds them first, so none get away.
	var town:Dictionary=reading.get("target",{})
	var civ_id:=String(town.get("civ_id","")); var city_id:=String(town.get("city_id",""))
	var name:=String(town.get("name","the town"))
	out["target"]=town.duplicate(true)
	var ids:Array=reading.get("measures",[])
	var fate:Dictionary=reading.get("fate",{}) if reading.get("fate") is Dictionary else {}
	var opts:=_measure_opts(reading)
	var said:PackedStringArray=PackedStringArray()
	var notes:PackedStringArray=PackedStringArray()
	var done:Dictionary={}
	var failed:=""
	if not ids.is_empty() or fate.is_empty():
		done=Measures.apply(civ_id,city_id,ids,opts,out.general_ref)
		if done.has("error"): failed=String(done.error); done={}
		else: said.append(String(done.text)); notes.append(String(done.outcome))
	var fated:Dictionary={}
	if not fate.is_empty():
		fated=TownFate.apply(civ_id,city_id,fate,out.general_ref)
		if fated.has("error"):
			failed=(failed+" "+String(fated.error)).strip_edges(); fated={}
		else: said.append(String(fated.text)); notes.append(String(fated.outcome))
	if said.is_empty():
		var refused:=_no(out,"measure_failed",failed if failed!="" else "There is nothing the garrison can do about that.","")
		refused.outcome="Nothing is done at %s." % name
		return refused
	if failed!="": said.append("But "+failed.substr(0,1).to_lower()+failed.substr(1))
	var stance:=String(opts.stance)
	var hard:=stance in ["harsh","brutal"] or (done.get("applied",[]) as Array).has("execute_ringleaders") or not fated.is_empty() and (int(fated.get("killed",0))>0 or int(fated.get("captives",0))>0)
	# Nothing new was done (the same order again): nothing to have qualms about.
	if (done.get("applied",[]) as Array).is_empty() and fated.is_empty(): hard=false
	var qualm:=""
	if hard and not bool(reading.get("nearest",false)):
		var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(out.general_pid)) if int(out.general_pid)>0 else {}
		var empathy:=float((person.get("personality",{}) as Dictionary).get("empathy",0.5)) if not person.is_empty() else 0.5
		if empathy>=0.6: qualm="I do not like putting their families in it, but it is done. " if bool(opts.families) else "I would not have chosen it, but it is done. "
		elif empathy>=0.35: qualm="It is done. "
	out.verdict="fate"; out.reason="town_measure"
	out.objective={"army_id":0,"kind":"measure","city_id":city_id,"civ_id":civ_id,"measures":(done.get("applied",[]) as Array).duplicate(),"renewed":(done.get("renewed",[]) as Array).duplicate(),
		"freed":(done.get("freed",[]) as Array).duplicate(),"bound":int(done.get("bound",0)),"fled":int(done.get("fled",0)),"killed":int(done.get("killed",0))+int(fated.get("killed",0)),
		"captives":int(fated.get("captives",0)),"stance":stance,"left":bool(fated.get("left",false)),"burned":bool(fated.get("burned",false))}
	# His own reading of an unanswered question: said so, once.
	var taken:=("You did not choose, so I did as I first read you: %s. " % String(reading.get("taken_words",""))) if bool(reading.get("taken",false)) and String(reading.get("taken_words",""))!="" else ""
	out.says=(taken+qualm+" ".join(said)).strip_edges()
	out.outcome=" ".join(notes)
	out["measure"]=done
	out["fate"]=fated
	_note_town_order(out,town,(done.get("applied",[]) as Array)+(done.get("renewed",[]) as Array),fate)
	# Men got away as the round-up began (or the killing): offer a chase.
	var fled:Dictionary=done.get("fled_record",{}) if done.get("fled_record") is Dictionary and not (done.get("fled_record") as Dictionary).is_empty() else (fated.get("fled",{}) if fated.get("fled") is Dictionary else {})
	if not fled.is_empty() and not bool(fated.get("left",false)):
		# Guards tied to the bound are not free to chase.
		var force:Dictionary=_mc().occupation_force_for_region(civ_id,city_id)
		var garrison:=int(force.get("troops",0))
		var spare:=mini(garrison,Measures.free_hands(force)+maxi(Pursuit.KEEP_AT_LEAST,ceili(float(garrison)*Pursuit.KEEP_SHARE)))
		var offer:=Pursuit.offer_words(fled,spare)
		if offer!="":
			out.says+=" "+offer
			if Pursuit.detachment_size(spare,int(fled.count),0)>0:
				out["pending"]={"ask":"chase","region_id":city_id,"text":"Go after the men who fled %s" % name}
	return out

## The god's words name no measure: the war leader's nearest reading. Done
## when it takes no life; a grave one ("destroy them", "kill them", "punish
## them") is asked about once, with concrete choices, the first being his
## own reading; words that point at nothing exact get a plain standing word.
const RUIN_WORDS:="(destroy|wipe (them|it|the town) out|wipe out|annihilate|exterminate|erase|level|finish (them|it) off|end them)\\b"
const KILL_WORDS:="(kill|slay|slaughter|massacre|butcher|put (them|the men|those) to death|execute|murder)\\b"

static func _grave_options(kind:String,near_id:String,town:Dictionary)->Array:
	## The war leader's choices, his own reading first; the milder ones are
	## what is not already in force there (never "bind the men" when they are).
	var name:=String(town.get("name","the town"))
	var burn:={"kind":"fate","id":"raze","fate":{"raze":true},"stance":"firm","words":"burn it and drive its people out","order":"Burn %s" % name,"keys":["burn","raze","drive (them )?out"]}
	var kill:={"kind":"fate","id":"kill_men","fate":{"kill_men":true},"stance":"firm","words":"put its men to death","order":"Kill the men of %s" % name,"keys":["all the men","every man","its men","the men to death"]}
	var leaders:={"kind":"measure","id":"execute_ringleaders","stance":"firm","words":"put to death only the few who led them","order":Measures.order_words("execute_ringleaders",name),"keys":["ringleaders","leaders","the few","only"]}
	var running:={}
	for m:Dictionary in Measures.active(String(town.get("civ_id","")),String(town.get("city_id",""))): running[String(m.id)]=true
	var milder:Array=[]
	for row in [["bind_men","bind the men and keep them under guard",["bind","tie","chain","guard","round up"]],["hostages","take hostages from their leading families",["hostage","elders","families"]],
			["requisition","take their food",["food","stores","grain"]],["disarm","take their weapons",["weapon","spears","disarm"]],["curfew","keep them in their houses",["houses","indoors","curfew"]]]:
		if running.has(String(row[0])): continue
		milder.append({"kind":"measure","id":String(row[0]),"stance":"firm","words":String(row[1]),"order":Measures.order_words(String(row[0]),name),"keys":row[2]})
	var first:Dictionary=burn if kind=="ruin" else (kill if kind=="kill" else leaders)
	if kind=="measure" and near_id!="execute_ringleaders":
		first={"kind":"measure","id":near_id,"stance":"firm","words":String((Measures.CATALOGUE.get(near_id,{}) as Dictionary).get("short",near_id)),"order":Measures.order_words(near_id,name),"keys":[near_id]}
	var second:Dictionary=kill if kind=="ruin" else (leaders if kind=="kill" else {})
	var options:Array=[first]
	if not second.is_empty(): options.append(second)
	for m:Dictionary in milder:
		if options.size()>=3: break
		options.append(m)
	return options

static func _town_word(out:Dictionary,reading:Dictionary)->Dictionary:
	var town:Dictionary=reading.get("target",{})
	var name:=String(town.get("name","the town"))
	var text:=String(reading.get("text",""))
	var near:=Measures.nearest(text)
	var lower:=text.to_lower()
	var grave_kind:=""
	if _has(lower,RUIN_WORDS): grave_kind="ruin"
	elif _has(lower,KILL_WORDS): grave_kind="kill"
	elif bool(near.grave): grave_kind="measure"
	var audience_id:=String(out.get("audience_id",""))
	if grave_kind!="":
		var options:=_grave_options(grave_kind,String(near.id),town)
		var first:Dictionary=options[0]
		var key:="word:%s:%s:%s" % [String(town.get("city_id","")),grave_kind,String(first.id)]
		if _asked(audience_id,key)>=1:
			# Said again without an answer: his own reading, not the question again.
			var again:=reading.duplicate()
			again["nearest"]=true
			again["kind"]=String(first.kind)
			again["fate"]=(first.get("fate",{}) as Dictionary).duplicate()
			again["measures"]=[String(first.id)] if String(first.kind)=="measure" else []
			again["measure"]={"stance":"firm","stance_set":false,"words":text}
			var done:=_fate(out,again) if String(first.kind)=="fate" else _measure(out,again)
			if String(done.verdict)=="fate": done.says="You said it again, so I take it you mean me to %s. %s" % [String(first.words),String(done.says)]
			return done
		_mark_asked(audience_id,key)
		var words:PackedStringArray=PackedStringArray()
		for o:Dictionary in options: words.append(String(o.words))
		var question:="What shall we do in %s: %s, or %s?" % [name,", ".join(words.slice(0,words.size()-1)),words[words.size()-1]]
		out.verdict="ask"; out.reason="measure_ask"
		out["target"]=town.duplicate(true)
		out.says=question
		out.fix="Say which; if you only say go on, I do the first."
		out.outcome="Nothing is done yet at %s." % name
		out["pending"]={"ask":"measure","confirm":true,"region_id":String(town.get("city_id","")),"options":options,"nearest":first,"question":question,"text":String(first.order)}
		return out
	var r:=reading.duplicate()
	r["kind"]="measure"; r["nearest"]=true
	if String(near.id)!="":
		r["measures"]=[String(near.id)]
		r["measure"]={"stance":String(near.stance),"stance_set":String(near.tone)!="neutral","words":text}
		var done:=_measure(out,r)
		if String(done.verdict)=="fate": done.says="I take it you want me to %s. %s" % [String((Measures.CATALOGUE[String(near.id)] as Dictionary).short),String(done.says)]
		return done
	r["measures"]=[]
	r["measure"]={"tone":String(near.tone),"stance":String(near.stance),"stance_set":false,"words":text}
	return _measure(out,r)

static func _measure_drop(out:Dictionary,reading:Dictionary)->Dictionary:
	var town:Dictionary=reading.get("target",{})
	out["target"]=town.duplicate(true)
	out.verdict="noted"; out.reason="measure_drop"
	out.objective={"army_id":0,"kind":"measure_drop","city_id":String(town.get("city_id",""))}
	out.says="Then nothing more is done to them for now. The garrison keeps order in %s as it has, and I will tell you if that changes." % String(town.get("name","the town"))
	out.outcome="Nothing more is done at %s." % String(town.get("name","the town"))
	return out

static func _fate(out:Dictionary,reading:Dictionary)->Dictionary:
	## The god decides what becomes of a town we hold (town_fate.gd). The war
	## leader may say what he thinks of it; a clear order is carried out.
	var town:Dictionary=reading.get("target",{})
	var fate:Dictionary=reading.get("fate",{})
	out["target"]=town.duplicate(true)
	var result:=TownFate.apply(String(town.civ_id),String(town.city_id),fate,out.general_ref)
	if result.has("error"):
		var failed:=_no(out,"fate_failed",String(result.error),"")
		failed.outcome="Nothing is done at %s." % String(town.get("name","the town"))
		return failed
	var harsh:=bool(fate.get("kill_men",false)) or bool(fate.get("captives",false)) or bool(fate.get("raze",false))
	var qualm:=""
	if harsh:
		var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(out.general_pid)) if int(out.general_pid)>0 else {}
		var empathy:=float((person.get("personality",{}) as Dictionary).get("empathy",0.5)) if not person.is_empty() else 0.5
		qualm="I would not have chosen it, but it is done. " if empathy>=0.6 else ("It is done. " if empathy>=0.35 else "It is done, and they will remember us for it. ")
	out.verdict="fate"; out.reason="town_fate"
	out.objective={"army_id":0,"kind":"fate","city_id":String(town.city_id),"civ_id":String(town.civ_id),"killed":int(result.killed),"captives":int(result.captives),"burned":bool(result.burned),"left":bool(result.left),"spared":bool(result.spared)}
	# His own reading of an unanswered question (occupation measures): said so, once.
	var taken:=("You did not choose, so I did as I first read you: %s. " % String(reading.get("taken_words",""))) if bool(reading.get("taken",false)) and String(reading.get("taken_words",""))!="" else ""
	out.says=(taken+qualm+String(result.text)).strip_edges()
	out.outcome=String(result.outcome)
	out["fate"]=result
	_note_town_order(out,town,[],fate)
	# Men got away and the garrison still holds the town: say so, and offer a chase.
	var fled:Dictionary=result.get("fled",{}) if result.get("fled") is Dictionary else {}
	if not fled.is_empty():
		var garrison:=int(_mc().occupation_force_for_region(String(town.civ_id),String(town.city_id)).get("troops",0))
		var offer:=Pursuit.offer_words(fled,garrison)
		if offer!="":
			out.says+=" "+offer
			if Pursuit.detachment_size(garrison,int(fled.count),0)>0:
				out["pending"]={"ask":"chase","region_id":String(town.city_id),"text":"Go after the men who fled %s" % String(town.name)}
	return out

static func _pursue(out:Dictionary,reading:Dictionary)->Dictionary:
	## After the men who got away from a town we hold: a real detachment, or
	## a plain reason why not (pursuit.gd).
	var town:Dictionary=reading.get("target",{})
	if town.is_empty():
		var flight:=Pursuit.latest_flight()
		if not flight.is_empty(): town=_held_town(String(flight.region_id))
	if town.is_empty(): return _no(out,"nobody_fled","Nobody has run from any town of ours that I know of.","")
	out["target"]=town.duplicate(true)
	var r:=Pursuit.begin(String(town.civ_id),String(town.city_id),int(reading.get("count",0)))
	if r.has("error"):
		var failed:=_no(out,String(r.get("reason","no_pursuit")),String(r.error),"")
		failed.outcome="Nobody goes after them."
		return failed
	out.verdict="act"; out.reason="pursuit"
	out.objective={"army_id":int(r.army_id),"kind":"pursuit","city_id":String(town.city_id),"civ_id":String(town.civ_id),"troops":int(r.troops),"days":int(r.days),"left":int(r.left)}
	out.says=String(r.says)
	out.outcome=String(r.outcome)
	Chronicle.record({"key":"pursuit_out:%s:%d" % [String(town.city_id),int(WorldSimulation.state.elapsed_days)],"title":("After the Men Who Fled %s" % String(town.name)).substr(0,70),
		"text":"%s of the garrison of %s went after the men who had fled it." % [_cap(_number(int(r.troops))),String(town.name)],"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":String(town.civ_id)}}})
	return out

static func _let_go(out:Dictionary,reading:Dictionary)->Dictionary:
	var town:Dictionary=reading.get("target",{})
	var flight:=Pursuit.latest_flight(String(town.get("city_id","")))
	var where:=""
	if not flight.is_empty(): where=", and the men who ran will be %s by tomorrow" % ("in the hills" if bool((flight.fled as Dictionary).get("hills",false)) else "in "+String((flight.fled as Dictionary).get("toward","their other towns")))
	out.verdict="act"; out.reason="let_go"
	out.objective={"army_id":0,"kind":"let_go"}
	out.says="Then nobody goes after them. The garrison stays inside %s%s." % [String(town.get("name","the town")),where]
	out.outcome="Nobody goes after them."
	return out

static func _abandon(out:Dictionary,reading:Dictionary)->Dictionary:
	## The god means the town to be left: the garrison marches home and the
	## town's own people have it back (occupation_resident_order restore_self_rule).
	var names:Array=reading.get("towns",[])
	if names.is_empty() and not (reading.get("target",{}) as Dictionary).is_empty(): names=[String(reading.target.name)]
	var left:Array[String]=[]
	var home:=0
	var refused:Array[String]=[]
	var ruins:Array[String]=[]
	var freed:PackedStringArray=PackedStringArray()
	for town:Dictionary in held_towns():
		if not names.is_empty() and not String(town.name) in names: continue
		# A ruin we burned is left to nobody, never handed back to its old people.
		var ruin:=not Ledger.our_ruin(String(town.city_id)).is_empty()
		var back:Dictionary=_mc().evacuate_occupation(String(town.civ_id),String(town.city_id)) if ruin else WorldSimulation.world.occupation_resident_order(String(town.civ_id),String(town.city_id),"restore_self_rule")
		if back.has("error"): refused.append("%s: %s" % [String(town.name),String(back.error)]); continue
		if ruin: ruins.append(String(town.name))
		left.append("%s (%d)" % [String(town.name),int(town.garrison)]); home+=int(town.garrison)
		# Nobody of ours stays to guard those we held: they go free, said here.
		var went:=Ledger.settle(String(town.civ_id),String(town.city_id),true)
		if not went.is_empty(): freed.append(String(went.words))
	for d:Dictionary in Pursuit.recall(false): home+=int(d.troops)
	if left.is_empty():
		return _no(out,"cannot_leave",("We cannot leave yet. "+"; ".join(PackedStringArray(refused))) if not refused.is_empty() else "We hold no town to leave.","")
	var days:=0
	for a in _mc().field_armies:
		if String((a as Dictionary).get("destination_id",""))=="player_home" and String(a.get("status",""))=="moving": days=maxi(days,int(a.get("arrival_day",0))-int(WorldSimulation.state.elapsed_days))
	out.verdict="act"; out.reason="abandon"
	out.objective={"army_id":-1,"kind":"abandon","left":left,"troops":home,"days":days}
	var whom:=("We leave %s to its own people." % ", ".join(PackedStringArray(left))) if ruins.is_empty() else ("We leave the ruins of %s; nobody holds them now." % ", ".join(PackedStringArray(ruins)) if ruins.size()==left.size() else "We leave %s; the ruins of %s are nobody's now." % [", ".join(PackedStringArray(left)),", ".join(PackedStringArray(ruins))])
	out.says="%s %s of ours are marching home%s." % [whom,_cap(_number(home)),(", about %s on the road" % ("a day" if days<=1 else "%s days" % _number(days))) if days>0 else ""]
	if not freed.is_empty(): out.says+=" "+" ".join(freed)
	out.outcome="%s left; the garrison is coming home." % ", ".join(PackedStringArray(left))
	return out

static func _keep(out:Dictionary,reading:Dictionary)->Dictionary:
	var town:Dictionary=reading.get("target",{})
	out.verdict="act"; out.reason="keep"
	out.objective={"army_id":0,"kind":"keep"}
	var names:=PackedStringArray()
	for t:Dictionary in held_towns(): names.append("%s (%d)" % [String(t.name),int(t.garrison)])
	out.says="The garrison stays: %s." % (", ".join(names) if not names.is_empty() else String(town.get("name","the town")))
	out.outcome="The garrison stays."
	return out

static func _which_town(out:Dictionary,reading:Dictionary)->Dictionary:
	## Several towns held and the words name none: ask, plainly. Nothing is
	## done until the god says which; the answer ("Tsaren") carries the order.
	## Asked once already and given the order again without a name: the town
	## spoken of, else the one taken last, rather than the question again.
	var audience_id:=String(out.get("audience_id",""))
	if _asked(audience_id,"which_town")>=1:
		var held:=held_towns()
		var pick:=_town_in_audience(held,audience_id)
		if pick.is_empty() and not held.is_empty():
			var by_day:=held.duplicate()
			by_day.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.taken_day)>int(b.taken_day))
			pick=by_day[0]
		if not pick.is_empty():
			var again:=reading.duplicate()
			again["target"]=pick
			again["kind"]="measure" if not (reading.get("measures",[]) as Array).is_empty() or reading.get("measure") is Dictionary else "fate"
			var done:=_measure(out,again) if String(again.kind)=="measure" else _fate(out,again)
			if String(done.verdict)=="fate": done.says="You have not named the town, so I take it you mean %s, the last we spoke of or took. %s" % [String(pick.name),String(done.says)]
			return done
	_mark_asked(audience_id,"which_town")
	var names:Array=reading.get("towns",[])
	var list:=""
	for i in names.size():
		list+=("" if i==0 else (" or " if i==names.size()-1 else ", "))+String(names[i])
	out.verdict="ask"; out.reason="which_town"
	out.says="Which town, %s? We hold %s. Name it and I send word to the garrison there." % [list,_number(names.size())]
	out.fix="Name the town."
	out.outcome="Nothing is done until you name the town."
	out["towns"]=names.duplicate()
	return out

static func _no_town(out:Dictionary,reading:Dictionary)->Dictionary:
	## Violence to a people when we hold none of their towns: said plainly.
	var fate:Dictionary=reading.get("fate",{})
	var what:="to kill or carry off" if bool(fate.get("kill_men",false)) and bool(fate.get("captives",false)) else ("to kill" if bool(fate.get("kill_men",false)) else "to carry off")
	# Towns we took and no longer hold: named, so the god hears why.
	var left:PackedStringArray=PackedStringArray()
	for pair in Ledger.towns():
		var h:=Ledger.hold(String(pair[0]),String(pair[1]))
		if not bool(h.held) and String(h.state)=="theirs" and String(h.name)!="": left.append(String(h.name))
	var now:=(" now: our men left %s" % " and ".join(left)) if not left.is_empty() else ""
	var failed:=_no(out,"no_town","We hold no town of theirs%s. There is nobody of theirs in our hands %s." % [now,what],"Name a town and I will tell you what it would take to take it.")
	failed.outcome="Nothing is done: we hold no town."
	return failed

static func _take_first(out:Dictionary,reading:Dictionary)->Dictionary:
	## Harm to the people of a town still in their hands: nobody of theirs is
	## in ours. The war leader says it must be taken first and asks to march;
	## nothing moves until the god says yes (court_commands.gd keeps the
	## march as the pending order). Nothing to march with: said plainly.
	var target:Dictionary=reading.get("target",{})
	if not target.has("city_id"): return _target_problem(out,target,"attack")
	var name:=String(target.get("name","")).trim_prefix("Reported home of ")
	out["target"]=target.duplicate(true)
	var fate:Dictionary=reading.get("fate",{})
	var men:=_has(String(reading.get("text","")).to_lower(),"(males?|men|menfolk|boys|sons|every man)\\b")
	var deed:=("kill its men" if men else "kill its people") if String(reading.get("harm","kill"))=="kill" or bool(fate.get("kill_men",false)) else ("harm its men" if men else "harm its people")
	if bool(fate.get("captives",false)) and not bool(fate.get("kill_men",false)):
		deed="carry off its "+TownFate._take_names(fate.get("take",{"women":1.0,"children":1.0}) as Dictionary,fate.get("kids",{}) as Dictionary if fate.get("kids") is Dictionary else {},String(fate.get("kids_words","")))
	elif String(fate.get("move",""))!="" and not bool(fate.get("kill_men",false)): deed="bring its people home"
	if String(reading.get("deed",""))!="": deed=String(reading.deed)
	# Why nobody of it is in our hands, from who holds it (town_ledger.hold).
	var h:=Ledger.hold_at(String(target.city_id))
	if String(h.get("name",""))=="": h["name"]=name
	if String(h.state) in ["unguarded","ruin"]:
		# Ours, or our ruin, with nobody of ours there: no march; men must go there.
		# Those we held there went free when our men left: said, from the ledger.
		var c:=Ledger.counts(String(h.civ_id),String(target.city_id))
		var went:=String(c.get("went_free_words",""))
		var about_held:=bool(fate.get("bound_only",false)) or deed.begins_with("free") or _has(String(reading.get("text","")).to_lower(),"(bound|tied|captive|prisoners|hostages|held)\\b")
		var why:=("%s Nobody of theirs is under our guard there now. " % went) if went!="" and about_held else ""
		var there:=_no(out,"not_held","%s%s To %s, some of ours must be there first." % [why,Ledger.hold_words(h),deed],"Send a band to hold %s first." % name)
		there.outcome="Nothing is done: nobody of ours is in %s." % name
		return there
	var taken:=bool(h.get("taken",false))
	var lead:=("%s None of its people are in our hands." % Ledger.hold_words(h)) if taken else "%s is still theirs." % name
	var again:="again" if taken else "first"
	var f:=forces(out.general_ref)
	var anyone:=int(f.trained)>0 or int(f.drilling)>0 or not (f.band as Dictionary).is_empty() or not (f.idle as Array).is_empty() or not (f.away as Array).is_empty()
	if not anyone:
		var none:=_no(out,"nobody_under_arms","%s To %s we must take it %s, and we have nobody under arms to take it." % [lead,deed,again],"Raise and drill a levy first.")
		none.outcome="Nothing is done: %s is not ours." % name
		return none
	out.verdict="ask_march"; out.reason="take_first"
	out.says="%s To %s we must take it %s. Shall I march on it?" % [lead,deed,again]
	out.fix="Say yes and we march on %s." % name
	out.outcome="Nothing is done yet: %s is not ours." % name if taken else "Nothing is done yet: %s is still theirs." % name
	out["march_text"]="Attack %s" % name
	return out

static func _group_maim(out:Dictionary,reading:Dictionary)->Dictionary:
	## Maiming a whole town's people is not something a garrison does; the
	## war leader says what it can do instead.
	var town:Dictionary=reading.get("target",{})
	out["target"]=town.duplicate(true)
	var failed:=_no(out,"group_maim","That is not a thing a garrison does to a whole town.","I can put its men to the sword, take captives, rule it by the spear, or burn it. Tell me which.")
	failed.outcome="Nothing is done at %s." % String(town.get("name","the town"))
	return failed

static func _besieged()->Dictionary:
	## The town our band is besieging now: {city_id, civ_id, name, army_id}.
	var mc:Variant=WorldSimulation.military
	if mc==null or mc.active_siege.is_empty() or String(mc.active_siege.get("mode",""))!="offensive": return {}
	var threat:Dictionary=mc.active_siege.get("threat",{})
	return {"city_id":String(threat.get("target_region_id","")),"civ_id":String(mc.active_siege.get("defender_id",threat.get("source_civ_id",""))),
		"name":String(threat.get("target_region_name","the town")),"army_id":int(mc.active_siege.get("army_id",0)),"besieged":true}

static func _storm(out:Dictionary,insist:bool)->Dictionary:
	## Storm a town our band is besieging: the war leader says how the siege
	## stands; before the walls are worn down he objects, and goes if the god
	## insists (military_campaign.siege_order "assault").
	var mc:=_mc()
	var town:=_besieged()
	if town.is_empty(): return _no(out,"no_siege","We are not besieging anyone.","Name a town and I will look to it.")
	out["target"]=town.duplicate(true)
	var siege:Dictionary=mc.active_siege
	var name:=String(town.name)
	var days:=maxi(1,int(siege.get("days",0)))
	var pressure:=float(siege.get("pressure",0.0))
	var army:=_army(int(town.army_id))
	var troops:=int(army.get("troops",0))
	var worn:="their walls are breached and their people hungry" if pressure>=0.72 else ("their stores are running low" if pressure>=0.5 else "their walls are whole and their food is not gone")
	if not insist and pressure<0.5:
		var objected:=_object(out,"walls_whole","Day %d of the siege of %s, and %s. Storming now, my %s would lose many for little." % [days,name,worn,_fighters(troops)],"Give it more days, or say the word and we go over the walls.")
		objected.outcome="Nobody goes at the walls yet."
		return objected
	var r:Dictionary=mc.siege_order(String(siege.id),"assault")
	if r.has("error"): return _no(out,"assault_failed",String(r.error),"")
	out.verdict="act"; out.reason="storm"
	out.objective={"army_id":int(town.army_id),"kind":"storm","city_id":String(town.city_id),"civ_id":String(town.civ_id),"troops":troops,"days":0}
	out.says="Day %d of the siege, and %s. We go over the walls of %s now with %s, from the lines we hold." % [days,worn,name,_fighters(troops)]
	out.outcome="%s's band storms %s." % [String(out.general),name]
	return out

static func _number(n:int)->String:
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _no(out:Dictionary,reason:String,says:String,fix:String)->Dictionary:
	out.verdict="impossible"; out.reason=reason
	out.says=says+(" "+fix if fix!="" else ""); out.fix=fix
	out.outcome="No one marches."
	return out

static func _object(out:Dictionary,reason:String,says:String,fix:String)->Dictionary:
	out.verdict="object"; out.reason=reason
	out.says=says+(" "+fix if fix!="" else ""); out.fix=fix
	out.outcome="No one marches yet."
	return out

static func _target_problem(out:Dictionary,target:Dictionary,kind:String)->Dictionary:
	if target.has("ambiguous"):
		return _no(out,"ambiguous_target","Which people? We know of %s." % " and ".join(PackedStringArray(target.ambiguous)),"Name the town and I will look to it.")
	if target.has("unknown"):
		return _no(out,"unknown_place","No scout has brought back where %s stands. I cannot march on a place nobody has seen." % String(target.unknown),"Send scouts toward it; once they are back, give the order again.")
	return _no(out,"no_target","You have not told me where to %s." % {"attack":"strike","siege":"lay siege","raid":"raid"}.get(kind,"go"),"Name the town.")

static func _drill_words(drill:float)->String:
	if drill<0.08: return "have barely begun their drill"
	if drill<UNDRILLED: return "are not half through their drill"
	return "are drilled"

static func _span(days:int)->String:
	## "45 days", or "7 months" for a long stretch.
	if days<=60: return "%d %s" % [days,"day" if days==1 else "days"]
	return "%d months" % roundi(float(days)/30.4)

static func _fighters(n:int)->String:
	return "%d %s" % [n,"fighter" if n==1 else "fighters"]

static func _home_extras(f:Dictionary,band_used:bool)->String:
	## What else stands at home, when the band is elsewhere.
	var t:Dictionary=f.trainees
	var parts:PackedStringArray=PackedStringArray()
	if band_used and int(f.trained)>0: parts.append("%d more %s trained" % [int(f.trained),"is" if int(f.trained)==1 else "are"])
	if int(t.heads)>0: parts.append("%d %s in their first drill, about %d days from done" % [int(t.heads),"is" if int(t.heads)==1 else "are",int(t.days)])
	if parts.is_empty(): return ""
	return " At home %s." % " and ".join(parts)

static func _strike(out:Dictionary,reading:Dictionary,insist:bool)->Dictionary:
	var kind:=String(out.kind)
	var target:Dictionary=reading.get("target",{})
	if target.is_empty() or not target.has("city_id"): return _target_problem(out,target,kind)
	var name:=String(target.name).trim_prefix("Reported home of ")
	out["target"]=target.duplicate(true)
	var general:Dictionary=out.general_ref
	var f:=forces(general)
	var t:Dictionary=f.trainees
	if String(f.busy)!="":
		return _no(out,"busy","We cannot start another fight while %s." % String(f.busy),"When that is done, give the order again.")
	for marching:Dictionary in f.marching:
		if String((marching.court_order as Dictionary).get("city_id",""))==String(target.city_id):
			var left_days:=maxi(0,int(marching.get("arrival_day",0))-int(WorldSimulation.state.elapsed_days))
			var already:=_no(out,"already_marching","%s is already on the road to %s with %s, %s out." % [String(marching.get("name","Our army")),name,_fighters(int(marching.get("troops",0))),"a day" if left_days<=1 else "%d days" % left_days],"")
			already.outcome="Nothing new is set in motion: %s is already on the road to %s." % [String(marching.get("name","Our army")),name]
			already["target"]=target.duplicate(true)
			return already
	var mc:=_mc()
	var full:=bool(reading.get("full",false))
	var trained:=int(f.trained)
	# Who goes: his own band from where it stands; else an idle army at home;
	# else a host formed from the home reserve (with the recruits still in
	# drill if the god says take them as they are); else any army in the field.
	var band:Dictionary=f.band
	var use_army:Dictionary={}
	var own_band:=false
	var chosen:=int(out.chosen)
	# "With 17 troops": that many go from the home reserve when it has them.
	var asked:=maxi(0,int(reading.get("count",0)))
	var exact:=asked>0 and chosen<=0 and not bool(out.home_only) and trained>=asked
	if chosen>0:
		var picked:=_army(chosen)
		if picked.is_empty(): return _no(out,"no_band","That band is no longer on our rolls.","")
		if not _available(picked): return _no(out,"band_busy","%s cannot take a new order now: %s." % [String(picked.get("name","That band")),_busy_words(picked)],"Call it home first, or wait until it is free.")
		use_army=picked; own_band=not band.is_empty() and int(band.army_id)==chosen
	elif not exact and not bool(out.home_only) and not band.is_empty() and (int(band.troops)>=trained or not _at_home(band)):
		use_army=band; own_band=true
	var keep:=0 if full else (ceili(trained*WATCH_SHARE) if trained>=MIN_FORCE*2 else 0)
	var send:=trained-keep
	if exact: send=asked; keep=trained-asked
	if use_army.is_empty() and not exact and not bool(out.home_only):
		var idle:Array=f.idle
		if not idle.is_empty():
			idle.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.troops)>int(b.troops))
			if int(idle[0].troops)>=send: use_army=idle[0]
	if use_army.is_empty() and not exact and not bool(out.home_only) and send<MIN_FORCE and int(t.heads)==0:
		var largest:Dictionary={}
		for a:Dictionary in f.away:
			if _available(a) and int(a.troops)>send and (largest.is_empty() or int(a.troops)>int(largest.troops)): largest=a
		use_army=largest
	var with_recruits:=use_army.is_empty() and int(t.heads)>0 and (send<MIN_FORCE or full)
	var going:=int(use_army.get("troops",0)) if not use_army.is_empty() else send+(int(t.heads) if with_recruits else 0)
	if going<=0 and int(t.heads)<=0:
		return _no(out,"no_forces","We have nobody under arms and nobody in drill.","Raise a levy and have it drilled; then I can go.")
	var start:Vector2=WorldSimulation.world.player_world_origin
	if not use_army.is_empty():
		var p:Dictionary=use_army.get("position",{}) if use_army.get("position") is Dictionary else {}
		if p.has_all(["x","z"]): start=Vector2(float(p.x),float(p.z))
	var there:=Vector2(float(target.position.get("x",0)),float(target.position.get("z",0)))
	var road:Dictionary=mc.field_route(start,there) if start.distance_to(there)>=0.5 else {"ok":true,"length_km":start.distance_to(there),"direct":true}
	if road.has("error"):
		var why:=String(road.get("reason",""))
		if why=="no_land_route":
			return _no(out,"no_land_route","There is no way to %s on foot: open water lies between us and every shore we know of theirs, and we have no boats that can carry an army." % name,"If our people learn to build boats that carry more than a few, or scouts find a way round by land, we can go.")
		return _no(out,why if why!="" else "no_route",String(road.error),"")
	var who:="My band" if own_band else ("The host" if use_army.is_empty() else String(use_army.get("name","The host")))
	var where:=_where(use_army) if not use_army.is_empty() else "at home"
	# What the force really is: its numbers, drill and weapons.
	var drilled:=0.0
	var unarmed:=0
	var going_strength:=0.0
	if not use_army.is_empty():
		drilled=_drill(use_army.get("formations",[])); unarmed=_unarmed(use_army.get("formations",[])); going_strength=_strength(use_army.get("formations",[]))
	else:
		var home_forms:Array=mc.home_army.get("formations",[])
		var recruits:=int(t.heads) if with_recruits else 0
		var recruit_drill:=float(mc._training_quality("levy"))*float(t.drill)
		drilled=(_drill(home_forms)*send+recruit_drill*recruits)/maxf(1.0,float(send+recruits))
		unarmed=(ceili(float(_unarmed(home_forms))*float(send)/float(trained)) if trained>0 else 0)+(int(t.unarmed) if with_recruits else 0)
		going_strength=float(f.home_strength)*(float(send)/maxf(1.0,float(trained)))+recruits*(0.35+0.65*recruit_drill)*(0.45+0.55*(1.0-float(t.unarmed)/maxf(1.0,float(t.heads))))
	var speed_force:Dictionary=use_army if not use_army.is_empty() else mc.home_army
	var speed:float=mc._field_army_speed(speed_force) if not speed_force.is_empty() else 0.0
	var days:=ceili(float(road.length_km)/maxf(2.0,speed))
	var enemy:=_enemy_estimate(String(target.city_id))
	var ratio:=going_strength/maxf(1.0,float(enemy.get("mid",0.0))*0.9) if bool(enemy.known) else 1.0
	out["estimate"]=enemy
	out["going"]=going
	out["days"]=days
	out["road_km"]=float(road.length_km)
	# By night: the chance of reaching them unseen, from what is really there
	# (battle_tactics.surprise_odds). The attack is rolled at this chance.
	var approach:={}
	if String(reading.get("approach",""))=="night" and kind in ["attack","raid"]:
		var leader:Dictionary=(use_army.get("commander",{}) as Dictionary) if not use_army.is_empty() else (mc.home_army.get("commander",{}) as Dictionary)
		var ground:=BattleGround.classify(BattleGround.sample(there))
		var at_war_now:=_at_war(String(target.civ_id))
		var odds:=Tactics.surprise_odds({"troops":going,"march_days":days,"watchers":float(enemy.get("mid",0.0)) if bool(enemy.known) else -1.0,"alert":1.0 if at_war_now else 0.0,"cover":Tactics.cover_of(ground),"tactics":float(leader.get("tactics",0.5))})
		approach={"kind":"night","chance":float(odds.chance),"ground":ground}
		out["surprise"]=odds
		out["night_words"]=_night_words(odds,going,name,days,ground,at_war_now)
	var take_word:="say the word and I take them as they are."
	if not insist:
		# Forces exist: the war leader objects with the real numbers, never "raise a levy".
		if use_army.is_empty() and send<MIN_FORCE and int(t.heads)>0:
			var armed_words:=", and %d of them have no weapons yet" % int(t.unarmed) if int(t.unarmed)>0 else ""
			var have:="Nobody has finished drill yet" if send<=0 else "Only %d %s finished drill" % [send,"has" if send==1 else "have"]
			return _object(out,"few_trained","%s. %d more are in their first drill, about %d days from done%s. Against %s's walls that is not enough." % [have,int(t.heads),int(t.days),armed_words,name],"Give me those %d days, or say the word and I take all %d as they are." % [int(t.days),send+int(t.heads)])
		if going<MIN_FORCE:
			var held_note:=""
			for town:Dictionary in f.garrisons: held_note+=" %s more hold %s and cannot leave it unguarded." % [_cap(_number(int(town.garrison))),String(town.name)]
			return _object(out,"too_few","%s against a walled town? %s would shut the gate and wait us out.%s" % [_fighters(going),name,held_note],"Give me more soldiers, or say the word and they go anyway.")
		if bool(enemy.known) and ratio<OBJECT_RATIO:
			var their:="about %d" % roundi(float(enemy.mid)) if int(enemy.low)!=int(enemy.high) else "%d" % int(enemy.low)
			var ours:="my band of %d" % going if own_band else "%d" % going
			return _object(out,"outnumbered","%s keeps %s under arms behind its walls; we would bring %s%s. I would lose them for nothing." % [name,their,ours,", most of them half-drilled" if ratio<0.5 else ""],("Let the drill finish first, about %d days, or %s" % [int(t.days),take_word]) if int(t.heads)>0 else "Give me more trained soldiers first, or %s" % take_word)
		var raw:=drilled<UNDRILLED
		var bare:=unarmed>0 and float(unarmed)>=float(going)*UNARMED_SHARE
		if raw or bare:
			var state:PackedStringArray=PackedStringArray()
			if raw: state.append("they %s" % _drill_words(drilled))
			if unarmed>0: state.append("%d still %s weapons" % [unarmed,"lacks" if unarmed==1 else "lack"])
			var head:="%s is %d strong, but %s." % [who,going," and ".join(state)] if not use_army.is_empty() else "%d would go, but %s." % [going," and ".join(state)]
			var away_now:=not use_army.is_empty() and not _at_home(use_army)
			var place:=" They are %s." % where if away_now else ""
			var fix_days:=_drill_days_to_fit(use_army.get("formations",[])) if not use_army.is_empty() else maxi(int(t.days),_drill_days_to_fit(mc.home_army.get("formations",[])))
			var fix:=""
			if raw:
				fix=("Bring them home for about %s of drill, or %s" % [_span(fix_days),take_word]) if away_now else ("Give me about %s of drill, or %s" % [_span(fix_days),take_word])
			else:
				fix="Give me time to arm them, or %s" % take_word
			return _object(out,"undrilled" if raw else "unarmed","%s%s Against %s's walls they would break.%s" % [head,place,name,_home_extras(f,not use_army.is_empty())],fix)
		if kind=="siege" and going<MIN_FORCE*3:
			return _object(out,"siege_too_small","A siege needs enough of us to ring %s and still feed ourselves; %d cannot do it." % [name,going],"Let me storm it instead, give me more soldiers, or say the word and we try.")
	# Act: the force is his band, an idle army, or formed from the home reserve.
	var formed:=false
	var army_id:=int(use_army.get("army_id",0))
	var mustered:=0
	if use_army.is_empty():
		if with_recruits: mustered=_muster_trainees()
		var ready:=maxi(0,int(mc.home_army.get("troops",0)))-keep
		if ready<=0: return _no(out,"cannot_form","Nobody could be gathered to march.","")
		var made:Dictionary=mc.create_field_army(ready,_host_name(kind,name))
		if made.has("error"): return _no(out,"cannot_form",String(made.error),"")
		army_id=int((made.army as Dictionary).army_id); formed=true
		going=ready
	var order:Dictionary=mc.order_city_operation(army_id,String(target.civ_id),String(target.city_id),kind=="siege",kind=="raid",approach)
	if order.has("error"):
		if formed: mc.disband_field_army(army_id)
		return _no(out,"order_failed",String(order.error),"")
	var index:int=mc._field_army_index(army_id)
	if index<0: return _no(out,"order_failed","The army could not be set on the road.","")
	var army:Dictionary=mc.field_armies[index]
	var day:=int(WorldSimulation.state.elapsed_days)
	var at_war:=_at_war(String(target.civ_id))
	army["court_order"]={"kind":kind,"civ_id":String(target.civ_id),"city_id":String(target.city_id),"city_name":name,"day":day,"general":String(out.general),"general_pid":int(out.general_pid),"going":going}
	if not approach.is_empty(): army.court_order["approach"]=approach.duplicate(true)
	if not own_band and not formed and chosen<=0 and not String(army.get("name","")).contains(name): army["name"]=_host_name(kind,name)
	mc.field_armies[index]=army
	mc.army_changed.emit(mc.home_army.duplicate(true))
	days=int(order.get("days",days))
	var km:=roundi(float(order.get("distance_km",road.length_km)))
	var verb:String={"attack":"to attack","siege":"to lay siege to","raid":"to raid the fields and stores of"}.get(kind,"against")
	if not approach.is_empty(): verb={"attack":"to fall by night on","raid":"to raid by night the fields and stores of"}.get(kind,verb)
	var roundabout:="" if bool(road.get("direct",true)) else " going round the water by land"
	var as_they_are:=insist and (drilled<UNDRILLED or (unarmed>0 and float(unarmed)>=float(going)*UNARMED_SHARE) or going<MIN_FORCE)
	out.verdict="act"
	out.objective={"army_id":army_id,"army_name":String(army.get("name","")),"city_id":String(target.city_id),"civ_id":String(target.civ_id),"kind":kind,"days":days,"troops":going,"route_km":km,"own_band":own_band,"mustered":mustered}
	var declared:="" if at_war else " Nobody has declared war; it begins when we reach %s." % name
	if own_band:
		out.says="My band of %d marches %s %s from where it stands, %s. It is %d km%s, about %d days.%s%s" % [going,verb,name,where,km,roundabout,days," They go as they are." if as_they_are else "",declared]
	else:
		var left:="I keep %d at home to watch the approaches." % keep if keep>0 else "Nobody trained stays behind."
		var raw_words:=(" %d of them come straight off the drill ground." % mustered) if mustered>0 else (" They go as they are." if as_they_are else "")
		out.says="%d of us march %s %s. It is %d km%s, about %d days. %s%s%s" % [going,verb,name,km,roundabout,days,left,raw_words,declared]
	var party:="%s's band" % String(out.general) if own_band else String(army.get("name","The host"))
	out.outcome="%s sets out for %s, about %d %s by land." % [party,name,days,"day" if days==1 else "days"]
	out["chronicle"]="%s leaves with %s for %s: %d km%s, about %d days on the road.%s" % [party,_fighters(going),name,km,roundabout,days,"" if at_war else " There was no declaration; the war begins when they reach %s, and %s will hear of it before then." % [name,Hall._civ_name(String(target.civ_id))]]
	_on_departure(out,army,target,at_war)
	return out

## The night approach's chance, with every number it came from.
static func _night_words(odds:Dictionary,going:int,name:String,days:int,ground:String,at_war:bool)->String:
	var theirs:=("about %d of theirs" % int(odds.watchers)) if bool(odds.counted) else "a watch nobody has counted"
	var road:=("%s on the road" % _span(days)) if days>0 else "no march at all"
	var cover:=String({"forest":"with woods to hide in","rough":"over broken ground","pass":"through the hills","marsh":"through wet ground","ford":"across the ford","bridge":"over the bridge"}.get(ground,"over open ground"))
	var wary:=", and they are at war with us and watching" if at_war else ""
	return "By night: %s against %s, %s, %s%s. The chance we reach %s unseen is %s." % [_fighters(going),theirs,road,cover,wary,name,Tactics.chance_words(float(odds.chance))]


static func _drill_first(out:Dictionary)->Dictionary:
	## The god takes the war leader's advice: his band comes home (if away)
	## and camp drill begins, or the recruits keep to their drill.
	var mc:=_mc()
	var general:Dictionary=out.general_ref
	var f:=forces(general)
	var band:Dictionary=f.band
	var t:Dictionary=f.trainees
	if band.is_empty() and int(t.heads)<=0 and int(f.trained)<=0:
		return _no(out,"no_forces","There is nobody under arms or in drill to train.","Raise a levy first.")
	var need:=_drill_days_to_fit(band.get("formations",[]) if not band.is_empty() else mc.home_army.get("formations",[]))
	var started:=""
	if mc.training_program.is_empty():
		var began:Dictionary=mc.start_training_program("camp_drill")
		if not began.has("error"): started="camp_drill"
	out.verdict="act"
	if not band.is_empty() and not _at_home(band):
		var r:Dictionary=mc.return_field_army(int(band.army_id))
		if r.has("error"): return _no(out,"cannot_recall","I cannot bring the band home yet. %s" % String(r.error),"")
		var index:int=mc._field_army_index(int(band.army_id))
		if index>=0: mc.field_armies[index].erase("court_order")
		var home_days:=int(r.get("days",0))
		out.objective={"army_id":int(band.army_id),"kind":"drill","days":home_days,"drill_days":need,"program":started}
		out.says="Then I bring the band home: about %d %s on the road, and after that about %s of camp drill before I would lead them at walls." % [home_days,"day" if home_days==1 else "days",_span(need)]
		out.outcome="%s's band turns for home to drill, about %d %s away." % [String(out.general),home_days,"day" if home_days==1 else "days"]
		return out
	var until:=need if not band.is_empty() else maxi(int(t.days),need)
	out.objective={"army_id":int(band.get("army_id",0)),"kind":"drill","drill_days":until,"program":started}
	if until<=0:
		out.says="They are drilled well enough already. Give me the word when you want them to march."
	else:
		out.says="They keep to their drill at home. In about %s they will be fit to take into a fight, and I will tell you so." % _span(until)
	out.outcome="The drill goes on."
	return out

static func _host_name(kind:String,place:String)->String:
	return ("Raiders for %s" if kind=="raid" else ("Siege host for %s" if kind=="siege" else "Host marching on %s")) % place

static func _at_war(civ_id:String)->bool:
	var index:=Hall._civ_index(civ_id)
	if index<0: return false
	var rel:Variant=WorldSimulation.world.civilizations[index].get("player_relation",{})
	return rel is Dictionary and bool((rel as Dictionary).get("at_war",false))

static func _on_departure(out:Dictionary,army:Dictionary,target:Dictionary,at_war:bool)->void:
	var civ_id:=String(target.civ_id)
	var name:=String(out.objective.get("city_id",""))
	var place:=String(army.court_order.city_name)
	var day:=int(WorldSimulation.state.elapsed_days)
	# The rival's people see an army on the road: opinion falls, the border tightens.
	Hall._shift_relation(civ_id,-0.06 if not at_war else -0.02,0.12)
	Chronicle.record({"key":"court_war:%s:%d:%d" % [name,day,int(out.objective.army_id)],"title":("%s Marches on %s" % [String(out.general),place]).substr(0,70),"text":String(out.get("chronicle",out.outcome)),"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	_ledger_add({"day":day,"army_id":int(out.objective.army_id),"civ_id":civ_id,"city_id":String(target.city_id),"city_name":place,"kind":String(out.kind),"general":String(out.general),"status":"marching","going":int(out.objective.troops)})
	if int(out.general_pid)>0:
		GovernmentPeopleSystem.record_person_memory(int(out.general_pid),"The god sent me against %s with %d." % [place,int(out.objective.troops)],"divine",0.7,{"emotion":"duty","outcome":"marching"})

static func _recall(out:Dictionary,reading:Dictionary={})->Dictionary:
	## Bring our people back: bands in the field march home; a detachment out
	## after fleeing men turns back to its town ("come back") or comes home
	## ("come home"); a garrison is only taken out of a town we hold when the
	## god says to leave it, so the war leader asks once ("Leave Tsaren
	## unguarded?"). The reply says who is coming, how many and how long.
	var mc:=_mc()
	var sent:Array[String]=[]
	var longest:=0
	var blocked:Array[String]=[]
	var chosen:=int(out.get("chosen",0))
	var to_home:=bool(reading.get("home",true))
	for a in mc.field_armies.duplicate():
		var army:Dictionary=a
		if int(army.get("troops",0))<=0 or army.get("pursuit") is Dictionary: continue
		if chosen>0 and int(army.army_id)!=chosen: continue
		if String(army.get("status",""))=="stationed" and String(army.get("location_id",""))=="player_home": continue
		if String(army.get("status",""))=="moving" and String(army.get("destination_id",""))=="player_home": continue
		var r:Dictionary=mc.return_field_army(int(army.army_id))
		if r.has("error"): blocked.append("%s: %s" % [String(army.get("name","An army")),String(r.error)]); continue
		var index:int=mc._field_army_index(int(army.army_id))
		if index>=0: mc.field_armies[index].erase("court_order")
		var c:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		var who:=("%s's band" % _given(String(c.get("name","")))) if String(c.get("name",""))!="" and chosen<=0 else String(army.get("name","An army"))
		sent.append("%s (%d)" % [who,int(army.get("troops",0))] if chosen<=0 else who)
		longest=maxi(longest,int(r.get("days",0)))
	# Detachments out after fleeing men.
	var turned:Array[String]=[]
	if chosen<=0:
		for d:Dictionary in Pursuit.recall(not to_home):
			if String(d.get("error",""))!="": blocked.append("%s: %s" % [String(d.name),String(d.error)]); continue
			var days:=int(d.get("days",0))
			turned.append("%s (%d) %s%s" % [String(d.name),int(d.troops),"is back inside %s" % String(d.to) if days<=0 and String(d.to)!="home" else ("turns back to %s" % String(d.to) if String(d.to)!="home" else "is coming home"),(", %s" % _span(days)) if days>0 else ""])
			longest=maxi(longest,days)
	# Garrisons stay unless the town is to be left.
	var garrisons:Array[Dictionary]=held_towns() if chosen<=0 else ([] as Array[Dictionary])
	var ask_towns:Array[String]=[]
	if not garrisons.is_empty() and not reading.is_empty() and to_home and (bool(reading.get("garrison",false)) or (sent.is_empty() and turned.is_empty() and blocked.is_empty() and to_home)):
		for t:Dictionary in garrisons: ask_towns.append(String(t.name))
	if sent.is_empty() and blocked.is_empty() and turned.is_empty() and ask_towns.is_empty():
		return _no(out,"all_home","Every one of our soldiers is already at home or on the way back.","")
	if sent.is_empty() and turned.is_empty() and ask_towns.is_empty():
		return _no(out,"cannot_recall","I cannot bring them back yet. "+"; ".join(PackedStringArray(blocked)),"")
	var said:=PackedStringArray()
	if not sent.is_empty():
		var names:=", ".join(PackedStringArray(sent))
		var be:="is" if sent.size()==1 else "are"
		if longest<=0: said.append("%s %s called back before %s had gone far; %s home again." % [names,be,"it" if sent.size()==1 else "they","it is" if sent.size()==1 else "they are"])
		else: said.append("I have sent runners: %s %s turning for home, %s." % [names,be,_span(longest)])
	if not turned.is_empty(): said.append(_cap("; ".join(PackedStringArray(turned)))+".")
	var outcome:=PackedStringArray()
	if not sent.is_empty(): outcome.append("%s %s marching home%s." % [", ".join(PackedStringArray(sent)),"is" if sent.size()==1 else "are",", about %d %s away" % [longest,"day" if longest==1 else "days"] if longest>0 else ""])
	if not turned.is_empty(): outcome.append("The detachment is coming back.")
	if not ask_towns.is_empty():
		var holding:=PackedStringArray()
		for t:Dictionary in garrisons: holding.append("%d hold %s" % [int(t.garrison),String(t.name)])
		var list:=" and ".join(PackedStringArray(ask_towns))
		said.append("%s. If they come home too, %s is left to its own people. Leave %s unguarded?" % [_cap(", ".join(holding)),list,list])
		out["pending"]={"ask":"abandon","towns":ask_towns.duplicate(),"region_id":String(garrisons[0].city_id),"text":"Abandon %s and bring the garrison home" % list}
		outcome.append("The garrison at %s stays until you say." % list)
	if not blocked.is_empty(): outcome.append("; ".join(PackedStringArray(blocked)))
	out.verdict="act" if not (sent.is_empty() and turned.is_empty()) else "ask"
	out.reason="recall" if String(out.verdict)=="act" else "abandon_ask"
	out.objective={"army_id":-1,"recalled":sent,"turned":turned,"days":longest,"kind":"recall"} if String(out.verdict)=="act" else {}
	out.says=" ".join(said)
	out.outcome=" ".join(outcome)
	return out

static func _defend(out:Dictionary,reading:Dictionary)->Dictionary:
	var f:=forces()
	var place:=String(reading.get("place",""))
	var home_words:=place=="" or _has(place,"(home|walls?|village|town|camp|fields|gate)")
	var recalled:=_recall(out.duplicate(true))
	var brought:Array=(recalled.objective as Dictionary).get("recalled",[]) if String(recalled.verdict)=="act" else []
	var watchers:=int(f.trained)
	if watchers<=0 and brought.is_empty():
		return _no(out,"no_trained","There is no one trained to put on watch.%s" % (" %d are in their first drill, about %d days from done." % [int(f.drilling),int(f.drill_days)] if int(f.drilling)>0 else ""),"Until then the whole village keeps its own watch.")
	# The real effect: every front with a hostile people is watched for half a year.
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var day:=int(WorldSimulation.state.elapsed_days)
	for c:Dictionary in WorldSimulation.world.civilizations:
		var cid:=String(c.get("id",""))
		if cid=="" or cid=="player": continue
		var front:Dictionary=war_loop.call("front",cid)
		if _at_war(cid) or int(front.get("level",0))>0: front["guard_until"]=day+180
	var here:=String(WorldSimulation.state.settlement_name) if String(WorldSimulation.state.settlement_name)!="" else "home"
	out.verdict="act"
	out.objective={"army_id":0,"kind":"defend","watch":watchers,"recalled":brought,"until_day":day+180}
	var brought_words:=" %s %s coming back to join them." % [", ".join(PackedStringArray(brought)),"is" if brought.size()==1 else "are"] if not brought.is_empty() else ""
	if home_words:
		out.says="%d of us will stand watch on the approaches to %s for half a year.%s" % [watchers,here,brought_words]
	else:
		out.says="%s is not a place on any chart we have, so I cannot post a guard there. I will keep all %d at %s, watching every approach, for half a year.%s" % [place.capitalize(),watchers,here,brought_words]
		out.reason="unknown_place"
	out.outcome="The watch is set for half a year."
	return out

static func _intercept(out:Dictionary,reading:Dictionary,insist:bool)->Dictionary:
	var target:Dictionary=reading.get("target",{})
	var civ_id:=String(target.get("civ_id",""))
	var only:=String(target.get("formation_id",""))
	var mc:=_mc()
	var seen:Array[Dictionary]=[]
	for formation in WorldSimulation.world.foreign_formations:
		var rec:Dictionary=formation
		if String(rec.get("kind",""))=="scout": continue
		if only!="" and String(rec.get("id",""))!=only: continue
		if civ_id!="" and String(rec.get("civ_id",""))!=civ_id: continue
		var sighting:Dictionary=WorldSimulation.world.visible_formation_sighting(String(rec.get("id","")))
		if not sighting.is_empty(): seen.append({"id":String(rec.id),"sighting":sighting})
	if seen.is_empty():
		var whose:=Hall._civ_name(civ_id) if civ_id!="" else "the enemy"
		return _no(out,"no_sighting","Nobody has seen %s's fighters in the open lately, so there is nothing to march at." % whose,"Tell me to march on their town instead, or send scouts to find their army.")
	var f:=forces()
	if String(f.busy)!="": return _no(out,"busy","We cannot start another fight while %s." % String(f.busy),"")
	var going:=int(f.trained)
	var chosen:=int(out.get("chosen",0))
	var picked:=_army(chosen) if chosen>0 else {}
	if chosen>0:
		if picked.is_empty(): return _no(out,"no_band","That band is no longer on our rolls.","")
		if not _available(picked): return _no(out,"band_busy","%s cannot take a new order now: %s." % [String(picked.get("name","That band")),_busy_words(picked)],"Call it home first, or wait until it is free.")
		going=int(picked.troops)
	elif not (f.idle as Array).is_empty(): going=maxi(going,int((f.idle as Array)[0].troops))
	if going<MIN_FORCE and not insist: return _no(out,"too_few","%d trained fighters cannot meet an army in the field." % going,"Let the levy finish its drill first.")
	var army_id:=chosen if chosen>0 else (int((f.idle as Array)[0].army_id) if not (f.idle as Array).is_empty() and int((f.idle as Array)[0].troops)>=int(f.trained) else 0)
	var formed:=false
	if army_id==0:
		var made:Dictionary=mc.create_field_army(int(f.trained),"Host against %s" % Hall._civ_name(civ_id if civ_id!="" else String(seen[0].get("sighting",{}).get("civ_id",""))))
		if made.has("error"): return _no(out,"cannot_form",String(made.error),"")
		army_id=int((made.army as Dictionary).army_id); formed=true
	var result:Dictionary=mc.order_field_army_intercept(army_id,String(seen[0].id))
	if result.has("error"):
		if formed: mc.disband_field_army(army_id)
		return _no(out,"order_failed",String(result.error),"")
	out.verdict="act"
	out.objective={"army_id":army_id,"kind":"intercept","formation_id":String(seen[0].id),"troops":going}
	out.says="We go after them: %d of us, toward where they were last seen." % going
	out.outcome="%d fighters set out to catch %s in the open." % [going,String((seen[0].sighting as Dictionary).get("label","their army"))]
	return out

static func _army(army_id:int)->Dictionary:
	if army_id<=0: return {}
	var index:int=_mc()._field_army_index(army_id)
	return {} if index<0 else _mc().field_armies[index]

static func _busy_words(army:Dictionary)->String:
	var mc:=_mc()
	if mc.command_hierarchy.battle.engaged(int(army.army_id)): return "it is fighting"
	if not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==int(army.army_id): return "it is laying siege"
	if bool(army.get("embarked",false)): return "it is at sea"
	if army.has("court_order"): return "it is marching on %s" % String((army.court_order as Dictionary).get("city_name","a town"))
	return "it is not free"

# --------------------------------------------------------------------------
# Plain readings for other screens (the Army command screen). Public, so
# callers never reach into the private helpers above.
# --------------------------------------------------------------------------

static func strength_of(formations:Array)->float: return _strength(formations)
static func drill_of(formations:Array)->float: return _drill(formations)
static func enemy_estimate(city_id:String)->Dictionary: return _enemy_estimate(city_id)
static func at_war(civ_id:String)->bool: return _at_war(civ_id)
static func given_name(name:String)->String: return _given(name)
static func civ_name(civ_id:String)->String: return Hall._civ_name(civ_id)
static func available(army:Dictionary)->bool: return _available(army)

static func _given(name:String)->String:
	return preload("res://scripts/era_names.gd").given_of(name) if name!="" else "The war leader"

# --------------------------------------------------------------------------
# Following the march: the general's own report comes back
# --------------------------------------------------------------------------

static func _ledger()->Array:
	var s:Dictionary=(load(WAR_LOOP_PATH) as GDScript).call("state")
	if not s.get("court_orders") is Array: s["court_orders"]=[]
	return s.court_orders

static func _ledger_add(entry:Dictionary)->void:
	var list:=_ledger()
	list.push_front(entry)
	while list.size()>LEDGER_MAX: list.pop_back()

static func ledger()->Array:
	return _ledger().duplicate(true)

static func daily(day:int)->Array:
	## Returns the report matters filed today (tests read them).
	var filed:Array=[]
	if WorldSimulation.military==null: return filed
	var mc:=_mc()
	# Every town's people agree with who holds it: nobody is under our guard
	# where no garrison of ours stands, and the war leader says so once.
	filed.append_array(Ledger.settle_all())
	# Detachments out after fleeing men: the chase, its one report, the way back.
	filed.append_array(Pursuit.daily(day))
	# What the garrisons do with the people of towns we hold: food, labour,
	# desertion, the end of each measure and any incident, each told once.
	filed.append_array(Measures.daily(day))
	# Ruins we burned: nobody resists in an empty ruin; its people may come
	# back on their day, told when our people hear of it.
	filed.append_array(TownFate.daily(day))
	for e in _ledger():
		var entry:Dictionary=e
		if String(entry.get("status",""))!="marching": continue
		var index:int=mc._field_army_index(int(entry.army_id))
		var text:=""
		var battle:Dictionary={}
		var told:Array=entry.get("reported_seeds",[])
		for b in mc.battle_history:
			var rec:Dictionary=b
			if int(rec.get("day",-1))<int(entry.day) or told.has(int(rec.get("seed",0))): continue
			var ours:=int(rec.get("home_force_id",-1))==int(entry.army_id) and String(rec.get("home_force_kind",""))=="field_army"
			if ours or String(rec.get("target_region_id",""))==String(entry.city_id): battle=rec; break
		if not battle.is_empty():
			# One battle, one account: the war leader's court matter carries
			# the same account as the report card, in his own voice. The
			# Chronicle's entry is the battle's own (military_campaign).
			told.append(int(battle.get("seed",0))); entry["reported_seeds"]=told.slice(-8)
			if String(battle.get("target_region_id",""))==String(entry.city_id) or index<0: entry["status"]="reported"
			var matter:=_file_battle(entry,battle,day)
			if not matter.is_empty(): filed.append(matter)
			continue
		elif not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==int(entry.army_id) and not bool(entry.get("siege_reported",false)):
			entry["siege_reported"]=true
			text="We are before %s and have ringed it. Nobody goes in or out with food while we hold." % String(entry.city_name)
		elif index<0:
			text="The host that marched on %s is gone from our rolls; nobody has come back to say how." % String(entry.city_name)
			entry["status"]="lost"
		else:
			var army:Dictionary=mc.field_armies[index]
			if String(army.get("status",""))=="stationed" and army.has("movement_block_reason"):
				text="We stopped on the road to %s: %s" % [String(entry.city_name),String(army.movement_block_reason)]
				entry["status"]="halted"
			elif String(army.get("status",""))=="stationed" and String(army.get("location_id",""))=="player_home" and day>int(entry.day)+1:
				entry["status"]="home"
			# Short of food in the field: said once per hungry spell, in plain words.
			var hungry:=preload("res://scripts/field_rations.gd").is_hungry(army) and not _at_home(army)
			if hungry and text=="" and not bool(entry.get("hunger_reported",false)):
				entry["hunger_reported"]=true
				text="We are short of food, %s. Too little of what is sent reaches us, and the country here does not feed us all. Send more out to us or call us home." % _where(army)
			elif not hungry: entry.erase("hunger_reported")
		if text!="":
			var matter:=_file_report(entry,text,day)
			if not matter.is_empty(): filed.append(matter)
	return filed

## The battle's account (battle_account.gd), in the war leader's own voice.
static func _battle_words(_entry:Dictionary,battle:Dictionary)->String:
	var Account:=preload("res://scripts/battle_account.gd")
	var state:=Account.gather(battle)
	state["voice"]="first"
	return Account.text(Account.build(battle,state))

static func _file_battle(entry:Dictionary,battle:Dictionary,day:int)->Dictionary:
	## The court matter for a battle: no Chronicle entry of its own.
	var text:=_battle_words(entry,battle)
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",String(entry.civ_id),"report",text,day,{"battle_seed":int(battle.get("seed",0)),"account":text})
	return matter if matter is Dictionary else {}

static func _file_report(entry:Dictionary,text:String,day:int)->Dictionary:
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",String(entry.civ_id),"report",text,day)
	Chronicle.record({"key":"court_war_report:%s:%d:%d" % [String(entry.city_id),int(entry.army_id),day],"title":("Word From the Road to %s" % String(entry.city_name)).substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":String(entry.civ_id)}}})
	return matter if matter is Dictionary else {}
