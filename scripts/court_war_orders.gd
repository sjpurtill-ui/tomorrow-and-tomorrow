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
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

const KINDS:=["attack","siege","raid","intercept","recall","defend","drill","fate","held"]
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
	var out:Array[Dictionary]=[]
	var mc:Variant=WorldSimulation.military
	var world:Variant=WorldSimulation.world
	if mc==null or world==null: return out
	for f in mc.occupation_forces:
		var force:Dictionary=f
		var troops:=int(force.get("troops",0))
		if troops<=0: continue
		var civ_id:=String(force.get("civ_id",""))
		var rid:=String(force.get("region_id",""))
		var region:Dictionary=world.region_snapshot(civ_id,rid)
		if not region.is_empty() and String(region.get("controller",""))!="player": continue
		var known:Dictionary=world.city_intelligence.known("player",rid) if "city_intelligence" in world and world.city_intelligence!=null else {}
		var name:=String(region.get("name",force.get("region_name","")))
		if name=="": name=String(known.get("name","")).trim_prefix("Reported home of ")
		var position:Dictionary=(known.get("position",{}) as Dictionary).duplicate(true)
		out.append({"city_id":rid,"civ_id":civ_id,"name":name,"civ_name":Hall._civ_name(civ_id),"garrison":troops,
			"commander":String((force.get("commander",{}) as Dictionary).get("name","")),"population":roundi(float(region.get("population",0.0))),"position":position,"held":true})
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
	var places:=known_places()
	for p:Dictionary in places:
		if _name_hit(lower,String(p.name)): return p
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

static func read(text:String,context_civ:String="")->Dictionary:
	## {} when the words are not a war order. Otherwise {kind, target, full,
	## insist, place, army_words}. Questions are discussion, never orders.
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?"): return {}
	var lower:=clean.to_lower()
	for lead in ["what","why","how","who","whom","where","when","should","could","can","would","shall we","do we","is it","are we"]:
		if lower.begins_with(lead+" "): return {}
	var army:=_has(lower,ARMY_WORDS+"\\b")
	var named:=find_target(clean,context_civ)
	var named_town:=named.has("city_id") or named.has("unknown")
	var kind:=""
	if bool(named.get("held",false)):
		# A town we hold: what becomes of it and its people is the god's to
		# say (town_fate.gd); an attack on it is answered with the truth.
		var fate:=TownFate.fate_words(lower)
		if not fate.is_empty(): return {"kind":"fate","target":named,"fate":fate,"full":false,"insist":_has(lower,INSIST_WORDS),"place":"","army_words":army,"text":clean.substr(0,300)}
		if not (_has(lower,SIEGE_WORDS) or _has(lower,RAID_WORDS) or _has(lower,ATTACK_WORDS) or army or _has(lower,LOOSE_ARMY_WORDS)): return {}
		return {"kind":"held","target":named,"full":false,"insist":false,"place":"","army_words":army,"text":clean.substr(0,300)}
	if _has(lower,DRILL_WORDS): return {"kind":"drill","target":{},"full":false,"insist":false,"place":"","army_words":true,"text":clean.substr(0,300)}
	if _has(lower,INTERCEPT_WORDS): kind="intercept"
	elif _has(lower,SIEGE_WORDS): kind="siege"
	elif _has(lower,RAID_WORDS): kind="raid"
	elif _has(lower,RECALL_WORDS) and (army or _has(lower,"(march|come) home|withdraw|retreat|fall back|pull back|recall")): kind="recall"
	elif _has(lower,ATTACK_WORDS): kind="attack"
	elif _has(lower,DEFEND_WORDS) and (army or _has(lower,"(defend|hold|guard|protect|garrison) (the|our|my) "+PLACE_WORDS)): kind="defend"
	elif army and _has(lower,"(send|march|lead|take|move)") and _has(lower,"(on|against|to|at|toward|towards)\\b"): kind="attack"
	elif _has(lower,LOOSE_ARMY_WORDS) and _has(lower,"(send|march|lead|take)") and _has(lower,"(on|against)\\b") and named_town: kind="attack"
	elif named_town and _has(lower,"(take|seize|win|burn|punish|humble|finish|end|go for|hit)"): kind="attack"
	if kind=="": return {}
	var target:={} if kind=="recall" else named
	# An attack verb with nothing to attack and no army named is not a war
	# order ("strike him", "destroy the old hut").
	if kind in ["attack","siege","raid"] and target.is_empty() and not army and not _has(lower,"(their|the enemy)"): return {}
	if kind=="intercept" and target.is_empty() and not _has(lower,"(their|the enemy)"): return {}
	if kind=="defend" and not army and not _has(lower,"\\b(the|our|my) "+PLACE_WORDS): return {}
	var place:=""
	var pm:=_re("\\b(the|our|my) "+PLACE_WORDS+"\\b").search(lower)
	if pm!=null: place=pm.get_string()
	return {"kind":kind,"target":target,"full":_has(lower,FULL_WORDS),"insist":_has(lower,INSIST_WORDS),"place":place,"army_words":army,"text":clean.substr(0,300)}

static func read_live(object:String,text:String,context_civ:String="")->Dictionary:
	## The live reading named verb "war"; its object carries the kind and
	## place ("attack Tsaren", "siege Tsaren", "march home"). The engine still
	## reads the ruler's own words first.
	var own:=read(text,context_civ)
	if not own.is_empty(): return own
	var from_object:=read(object,context_civ)
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
	if not pending.is_empty() and String(pending.get("verb",""))=="war" and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS:
		out.append({"group":"war","label":"Take them as they are","action":"command","params":{"command_text":"Take them as they are"}})
		out.append({"group":"war","label":"Drill them first","action":"command","params":{"command_text":"Drill them first"}})
	for town:Dictionary in held_towns().slice(0,2):
		var held_name:=String(town.name)
		out.append({"group":"war","label":"Spare %s and hold it" % held_name,"action":"command","params":{"command_text":"Spare %s and hold it" % held_name}})
		out.append({"group":"war","label":"Take captives and burn %s" % held_name,"action":"command","params":{"command_text":"Take captives home and burn %s" % held_name}})
		out.append({"group":"war","label":"Put the men of %s to the sword" % held_name,"action":"command","params":{"command_text":"Put the men of %s to the sword" % held_name}})
		out.append({"group":"war","label":"Take tribute from %s and leave" % held_name,"action":"command","params":{"command_text":"Take tribute from %s and leave" % held_name}})
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
	if not (forces(general).away as Array).is_empty():
		out.append({"group":"war","label":"Bring the army home","action":"command","params":{"command_text":"Bring the army home"}})
	out.append({"group":"war","label":"Keep the soldiers home on watch","action":"command","params":{"command_text":"Defend our home with the soldiers"}})
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
	var busy:=""
	if not mc.active_engagement.is_empty(): busy="a battle is still being fought"
	elif not mc.active_siege.is_empty(): busy="our soldiers are already besieging %s" % String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","a town"))
	elif not mc.pending_aftermath.is_empty(): busy="the last battle's captives and spoils are not yet settled"
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
		"chosen":maxi(0,int(context.get("army_id",0))),"home_only":bool(context.get("home_only",false))}
	if WorldSimulation.military==null or WorldSimulation.world==null:
		return _no(out,"no_military","We have nothing organised to fight with yet.","Raise and drill a levy first.")
	match kind:
		"recall": return _recall(out)
		"defend": return _defend(out,reading)
		"intercept": return _intercept(out,reading,insist)
		"drill": return _drill_first(out)
		"fate": return _fate(out,reading)
		"held": return _held(out,reading.get("target",{}))
	if bool((reading.get("target",{}) as Dictionary).get("held",false)): return _held(out,reading.target)
	return _strike(out,reading,insist)

static func _held_words(town:Dictionary)->String:
	var who:=_given(String(town.get("commander","")))
	var holder:=("%s's garrison" % who) if String(town.get("commander",""))!="" else "our garrison"
	return "%s is already ours. %s of %s hold%s it." % [String(town.name),_cap(_number(int(town.garrison))),holder,"s" if int(town.garrison)==1 else ""]

static func _held(out:Dictionary,town:Dictionary)->Dictionary:
	## An attack on a town we hold: the war leader says so, with who holds it,
	## and asks what is to become of it.
	var band:Dictionary=forces(out.general_ref).band
	var mine:=" I have %s with me." % _number(int(band.troops)) if not band.is_empty() else ""
	out.verdict="held"; out.reason="already_ours"; out["target"]=town.duplicate(true)
	out.says="%s%s Tell me what is to become of it and its people: spare it and hold it, take captives and burn it, put the men to the sword, or take tribute and leave." % [_held_words(town),mine]
	out.fix=""
	out.outcome="%s is already ours." % String(town.name)
	return out

static func _fate(out:Dictionary,reading:Dictionary)->Dictionary:
	## The god decides what becomes of a town we hold (town_fate.gd). The war
	## leader may say what he thinks of it; a clear order is carried out.
	var town:Dictionary=reading.get("target",{})
	var fate:Dictionary=reading.get("fate",{})
	out["target"]=town.duplicate(true)
	var result:=TownFate.apply(String(town.civ_id),String(town.city_id),fate,out.general_ref)
	if result.has("error"): return _no(out,"fate_failed",String(result.error),"")
	var harsh:=bool(fate.get("kill_men",false)) or bool(fate.get("captives",false)) or bool(fate.get("raze",false))
	var qualm:=""
	if harsh:
		var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(out.general_pid)) if int(out.general_pid)>0 else {}
		var empathy:=float((person.get("personality",{}) as Dictionary).get("empathy",0.5)) if not person.is_empty() else 0.5
		qualm="I would not have chosen it, but it is done. " if empathy>=0.6 else ("It is done. " if empathy>=0.35 else "It is done, and they will remember us for it. ")
	out.verdict="fate"; out.reason="town_fate"
	out.objective={"army_id":0,"kind":"fate","city_id":String(town.city_id),"civ_id":String(town.civ_id),"killed":int(result.killed),"captives":int(result.captives),"burned":bool(result.burned),"left":bool(result.left),"spared":bool(result.spared)}
	out.says=(qualm+String(result.text)).strip_edges()
	out.outcome=String(result.outcome)
	out["fate"]=result
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
			return _no(out,"already_marching","%s is already on the road to %s, %d days out." % [String(marching.get("name","Our army")),name,maxi(0,int(marching.get("arrival_day",0))-int(WorldSimulation.state.elapsed_days))],"")
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
	if chosen>0:
		var picked:=_army(chosen)
		if picked.is_empty(): return _no(out,"no_band","That band is no longer on our rolls.","")
		if not _available(picked): return _no(out,"band_busy","%s cannot take a new order now: %s." % [String(picked.get("name","That band")),_busy_words(picked)],"Call it home first, or wait until it is free.")
		use_army=picked; own_band=not band.is_empty() and int(band.army_id)==chosen
	elif not bool(out.home_only) and not band.is_empty() and (int(band.troops)>=trained or not _at_home(band)):
		use_army=band; own_band=true
	var keep:=0 if full else (ceili(trained*WATCH_SHARE) if trained>=MIN_FORCE*2 else 0)
	var send:=trained-keep
	if use_army.is_empty() and not bool(out.home_only):
		var idle:Array=f.idle
		if not idle.is_empty():
			idle.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.troops)>int(b.troops))
			if int(idle[0].troops)>=send: use_army=idle[0]
	if use_army.is_empty() and not bool(out.home_only) and send<MIN_FORCE and int(t.heads)==0:
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
	var order:Dictionary=mc.order_city_operation(army_id,String(target.civ_id),String(target.city_id),kind=="siege",kind=="raid")
	if order.has("error"):
		if formed: mc.disband_field_army(army_id)
		return _no(out,"order_failed",String(order.error),"")
	var index:int=mc._field_army_index(army_id)
	if index<0: return _no(out,"order_failed","The army could not be set on the road.","")
	var army:Dictionary=mc.field_armies[index]
	var day:=int(WorldSimulation.state.elapsed_days)
	var at_war:=_at_war(String(target.civ_id))
	army["court_order"]={"kind":kind,"civ_id":String(target.civ_id),"city_id":String(target.city_id),"city_name":name,"day":day,"general":String(out.general),"general_pid":int(out.general_pid),"going":going}
	if not own_band and not formed and chosen<=0 and not String(army.get("name","")).contains(name): army["name"]=_host_name(kind,name)
	mc.field_armies[index]=army
	mc.army_changed.emit(mc.home_army.duplicate(true))
	days=int(order.get("days",days))
	var km:=roundi(float(order.get("distance_km",road.length_km)))
	var verb:String={"attack":"to attack","siege":"to lay siege to","raid":"to raid the fields and stores of"}.get(kind,"against")
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

static func _recall(out:Dictionary)->Dictionary:
	var mc:=_mc()
	var sent:Array[String]=[]
	var longest:=0
	var blocked:Array[String]=[]
	var chosen:=int(out.get("chosen",0))
	for a in mc.field_armies.duplicate():
		var army:Dictionary=a
		if int(army.get("troops",0))<=0: continue
		if chosen>0 and int(army.army_id)!=chosen: continue
		if String(army.get("status",""))=="stationed" and String(army.get("location_id",""))=="player_home": continue
		if String(army.get("status",""))=="moving" and String(army.get("destination_id",""))=="player_home": continue
		var r:Dictionary=mc.return_field_army(int(army.army_id))
		if r.has("error"): blocked.append("%s: %s" % [String(army.get("name","An army")),String(r.error)]); continue
		var index:int=mc._field_army_index(int(army.army_id))
		if index>=0: mc.field_armies[index].erase("court_order")
		sent.append(String(army.get("name","An army")))
		longest=maxi(longest,int(r.get("days",0)))
	if sent.is_empty() and blocked.is_empty():
		return _no(out,"all_home","Every one of our soldiers is already at home or on the way back.","")
	if sent.is_empty():
		return _no(out,"cannot_recall","I cannot bring them back yet. "+"; ".join(PackedStringArray(blocked)),"")
	out.verdict="act"
	out.objective={"army_id":-1,"recalled":sent,"days":longest,"kind":"recall"}
	var names:=", ".join(PackedStringArray(sent))
	var be:="is" if sent.size()==1 else "are"
	if longest<=0:
		out.says="%s %s called back before %s had gone far; %s home again." % [names,be,"it" if sent.size()==1 else "they","it is" if sent.size()==1 else "they are"]
		out.outcome="%s home again." % ("It is" if sent.size()==1 else "They are")
	else:
		out.says="I have sent runners: %s %s turning for home, about %d %s out." % [names,be,longest,"day" if longest==1 else "days"]
		out.outcome="%s %s marching home, about %d %s away." % [names,be,longest,"day" if longest==1 else "days"]
	if not blocked.is_empty(): out.outcome+=" "+"; ".join(PackedStringArray(blocked))
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
	for e in _ledger():
		var entry:Dictionary=e
		if String(entry.get("status",""))!="marching": continue
		var index:int=mc._field_army_index(int(entry.army_id))
		var text:=""
		var battle:Dictionary={}
		for b in mc.battle_history:
			var rec:Dictionary=b
			if int(rec.get("day",-1))>=int(entry.day) and String(rec.get("target_region_id",""))==String(entry.city_id): battle=rec; break
		if not battle.is_empty():
			text=_battle_words(entry,battle)
			entry["status"]="reported"
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
		if text!="":
			var matter:=_file_report(entry,text,day)
			if not matter.is_empty(): filed.append(matter)
	return filed

static func _battle_words(entry:Dictionary,battle:Dictionary)->String:
	var side:=String(battle.get("home_side","attacker"))
	var ours:Dictionary=battle.get(side,{})
	var lost:=maxi(0,int(ours.get("initial_troops",ours.get("troops",0)))-int(ours.get("remaining_troops",0)))
	var outcome:=String(battle.get("outcome",""))
	var won:=outcome.begins_with(side) or String((battle.get("strategic_outcome",{}) as Dictionary).get("player_won",""))=="true"
	var took:=bool((battle.get("strategic_outcome",{}) as Dictionary).get("region_captured",false))
	var words:="We fought at %s. " % String(entry.city_name)
	if took: words+="The town is ours; some of us stay to hold it. "
	elif outcome.ends_with("retreat") and outcome.begins_with(side): words+="We could not break them and pulled back. "
	elif won: words+="We had the better of it. "
	else: words+="They held. "
	words+="%d of the %d who went are dead, hurt or scattered; %d are still with me." % [lost,int(entry.get("going",lost)),int(ours.get("remaining_troops",0))]
	return words

static func _file_report(entry:Dictionary,text:String,day:int)->Dictionary:
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",String(entry.civ_id),"report",text,day)
	Chronicle.record({"key":"court_war_report:%s:%d:%d" % [String(entry.city_id),int(entry.army_id),day],"title":("Word From the Road to %s" % String(entry.city_name)).substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":String(entry.civ_id)}}})
	return matter if matter is Dictionary else {}
