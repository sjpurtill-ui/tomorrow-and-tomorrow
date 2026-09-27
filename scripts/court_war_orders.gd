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
##           place, a land road (army_land_route.gd), trained soldiers at home
##           (keeping a sensible watch unless told "everything"), the drill of
##           the levy, and the last estimate of the enemy garrison. Then:
##           - act: forms the force from the actual home formations and sends
##             it through MilitaryCampaign's field-army machinery (march along
##             the land road, then attack, siege or raid on arrival; war begins
##             on contact, and the rival's people hear of it as the army goes);
##           - object: a general's objection with the real numbers and what
##             would fix it; "I insist" (or "whatever the cost") overrides;
##           - impossible: the real reason and what would change it.
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
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

const KINDS:=["attack","siege","raid","intercept","recall","defend"]
## Fewer trained soldiers than this cannot take or besiege a town at all.
const MIN_FORCE:=5
## Below this share of the enemy's estimated strength, a general objects.
const OBJECT_RATIO:=0.8
## Below this average drill, a general will not lead them at walls unasked.
const UNDRILLED:=0.2
## The home watch a general keeps back unless told to send everything.
const WATCH_SHARE:=0.2
const LEDGER_MAX:=24

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
	var out:Array[Dictionary]=[]
	var world:Variant=WorldSimulation.world
	if world==null or not "city_intelligence" in world or world.city_intelligence==null: return out
	for city:Dictionary in world.city_intelligence.known_cities("player","",false):
		var controller:=String(city.get("controller",city.get("civ_id","")))
		if controller in ["","player"] or String(city.get("civ_id",""))=="player": continue
		out.append({"city_id":String(city.city_id),"civ_id":String(city.get("civ_id","")),"controller":controller,"name":String(city.get("name","")),"civ_name":Hall._civ_name(String(city.get("civ_id",""))),"position":(city.get("position",{}) as Dictionary).duplicate(true)})
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

static func offline_choices()->Array[Dictionary]:
	## Offline the court offers war orders as choices built from real state
	## (known towns, armies away, enemies seen); each is the same words the
	## god could type, so both reach perform() through court_commands.hear().
	var out:Array[Dictionary]=[]
	if WorldSimulation.military==null or WorldSimulation.world==null: return out
	var places:=known_places()
	var home:Vector2=WorldSimulation.world.player_world_origin
	places.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return home.distance_squared_to(Vector2(float(a.position.x),float(a.position.z)))<home.distance_squared_to(Vector2(float(b.position.x),float(b.position.z))))
	for p:Dictionary in places.slice(0,3):
		var name:=String(p.name).trim_prefix("Reported home of ")
		out.append({"group":"war","label":"March on %s" % name,"action":"command","params":{"command_text":"March our army on %s" % name}})
		out.append({"group":"war","label":"Lay siege to %s" % name,"action":"command","params":{"command_text":"Lay siege to %s" % name}})
		out.append({"group":"war","label":"Raid the fields of %s" % name,"action":"command","params":{"command_text":"Raid the fields of %s" % name}})
	for formation in WorldSimulation.world.foreign_formations:
		if String((formation as Dictionary).get("kind",""))!="scout" and not WorldSimulation.world.visible_formation_sighting(String(formation.get("id",""))).is_empty():
			out.append({"group":"war","label":"Go after %s's army" % Hall._civ_name(String(formation.get("civ_id",""))),"action":"command","params":{"command_text":"Attack their army, the %s" % Hall._civ_name(String(formation.get("civ_id","")))}})
			break
	if not (forces().away as Array).is_empty():
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

static func forces()->Dictionary:
	## Plain numbers the war leader answers from.
	var mc:=_mc()
	var home:Dictionary=mc.home_army
	var trained:=maxi(0,int(home.get("troops",0)))
	var drilling:=0
	var drill_days:=0
	for t in mc.training_queue:
		var entry:Dictionary=t
		drilling+=maxi(0,int(entry.get("count",0)))
		drill_days=maxi(drill_days,ceili(maxf(0.0,float(entry.get("required_days",0))-float(entry.get("progress_days",0)))))
	var idle:Array[Dictionary]=[]
	var away:Array[Dictionary]=[]
	for a in mc.field_armies:
		var army:Dictionary=a
		if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): continue
		var at_home:=String(army.get("status",""))=="stationed" and String(army.get("location_id",""))=="player_home"
		if at_home and not mc.command_hierarchy.battle.engaged(int(army.army_id)) and not army.has("court_order"): idle.append(army)
		elif not at_home: away.append(army)
	var busy:=""
	if not mc.active_engagement.is_empty(): busy="a battle is still being fought"
	elif not mc.active_siege.is_empty(): busy="our soldiers are already besieging %s" % String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","a town"))
	elif not mc.pending_aftermath.is_empty(): busy="the last battle's captives and spoils are not yet settled"
	elif not mc.active_threat.is_empty() and String(mc.active_threat.get("campaign_mode",""))=="defensive": busy="an enemy force is already coming at us"
	return {"trained":trained,"home_strength":_strength(home.get("formations",[])),"drilling":drilling,"drill_days":drill_days,"idle":idle,"away":away,"busy":busy,"marching":_marching_on()}

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

# --------------------------------------------------------------------------
# Deciding and doing
# --------------------------------------------------------------------------

static func war_leader()->Dictionary:
	## The Marshal (war leader office); else a living war leader of renown
	## (HistoricalFigures General) who leads our bands.
	var marshal:=Hall._relevant_official(["Marshal"])
	if not marshal.is_empty(): return marshal
	var figures:Variant=Engine.get_main_loop().root.get_node_or_null("HistoricalFigures") if Engine.get_main_loop() is SceneTree else null
	if figures!=null:
		for figure in figures.people:
			if figure is Dictionary and String(figure.get("role",""))=="General" and String(figure.get("status",""))!="dead":
				return {"name":String(figure.get("name","")),"person_id":0,"figure_id":String(figure.get("id",""))}
	return {}

static func perform(reading:Dictionary,insist:bool=false,context:Dictionary={})->Dictionary:
	## The engine's answer: {verdict:"act"|"object"|"impossible", kind,
	## outcome (plain narration), says (the war leader's own words), reason,
	## fix, objective:{army_id,...} when acted}. Pure of any UI.
	var kind:=String(reading.get("kind","attack"))
	insist=insist or bool(reading.get("insist",false))
	var general:=war_leader()
	var gname:=_given(String(general.get("name","The war leader")))
	var out:={"kind":kind,"general":gname,"general_pid":int(general.get("person_id",0)),"verdict":"impossible","outcome":"","says":"","reason":"","fix":"","objective":{}}
	if WorldSimulation.military==null or WorldSimulation.world==null:
		return _no(out,"no_military","We have nothing organised to fight with yet.","Raise and drill a levy first.")
	match kind:
		"recall": return _recall(out)
		"defend": return _defend(out,reading)
		"intercept": return _intercept(out,reading,insist)
	return _strike(out,reading,insist)

static func _no(out:Dictionary,reason:String,says:String,fix:String)->Dictionary:
	out.verdict="impossible"; out.reason=reason; out.says=says; out.fix=fix
	out.outcome="No soldiers march. "+says+(" "+fix if fix!="" else "")
	return out

static func _object(out:Dictionary,reason:String,says:String,fix:String)->Dictionary:
	out.verdict="object"; out.reason=reason; out.says=says; out.fix=fix
	out.outcome="No soldiers march yet: %s objects. %s %s Say it again and %s will go." % [String(out.general),says,fix,String(out.general)]
	return out

static func _target_problem(out:Dictionary,target:Dictionary,kind:String)->Dictionary:
	if target.has("ambiguous"):
		return _no(out,"ambiguous_target","Which people? We know of %s." % " and ".join(PackedStringArray(target.ambiguous)),"Name the town and I will look to it.")
	if target.has("unknown"):
		return _no(out,"unknown_place","No scout has brought back where %s stands. I cannot march on a place nobody has seen." % String(target.unknown),"Send scouts toward it; once they are back, give the order again.")
	return _no(out,"no_target","You have not told me where to %s." % {"attack":"strike","siege":"lay siege","raid":"raid"}.get(kind,"go"),"Name the town.")

static func _strike(out:Dictionary,reading:Dictionary,insist:bool)->Dictionary:
	var kind:=String(out.kind)
	var target:Dictionary=reading.get("target",{})
	if target.is_empty() or not target.has("city_id"): return _target_problem(out,target,kind)
	var name:=String(target.name).trim_prefix("Reported home of ")
	out["target"]=target.duplicate(true)
	var f:=forces()
	if String(f.busy)!="":
		return _no(out,"busy","We cannot start another fight while %s." % String(f.busy),"When that is done, give the order again.")
	for marching:Dictionary in f.marching:
		if String((marching.court_order as Dictionary).get("city_id",""))==String(target.city_id):
			return _no(out,"already_marching","%s is already on the road to %s, %d days out." % [String(marching.get("name","Our army")),name,maxi(0,int(marching.get("arrival_day",0))-int(WorldSimulation.state.elapsed_days))],"")
	var mc:=_mc()
	var home:Vector2=WorldSimulation.world.player_world_origin
	var there:=Vector2(float(target.position.get("x",0)),float(target.position.get("z",0)))
	var road:Dictionary=mc.field_route(home,there)
	if road.has("error"):
		var why:=String(road.get("reason",""))
		if why=="no_land_route":
			return _no(out,"no_land_route","There is no way to %s on foot: open water lies between us and every shore we know of theirs, and we have no boats that can carry an army." % name,"If our people learn to build boats that carry more than a few, or scouts find a way round by land, we can go.")
		return _no(out,why if why!="" else "no_route",String(road.error),"")
	# Who goes: an idle army at home, or a force formed from the home reserve.
	var full:=bool(reading.get("full",false))
	var trained:=int(f.trained)
	var keep:=0 if full else (ceili(trained*WATCH_SHARE) if trained>=MIN_FORCE*2 else 0)
	var send:=trained-keep
	var idle:Array=f.idle
	var use_army:Dictionary={}
	if not idle.is_empty():
		idle.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.troops)>int(b.troops))
		if int(idle[0].troops)>=send: use_army=idle[0]; send=0
	var going:=int(use_army.get("troops",0))+send
	var going_strength:=_strength(use_army.get("formations",[])) if not use_army.is_empty() else float(f.home_strength)*(float(send)/maxf(1.0,float(trained)))
	var drilled:=_drill(use_army.get("formations",[]) if not use_army.is_empty() else _mc().home_army.get("formations",[]))
	var drill_words:=""
	if int(f.drilling)>0: drill_words=" %d more are in their first drill, about %d days from done." % [int(f.drilling),int(f.drill_days)]
	if going<=0:
		return _no(out,"no_trained","We have no trained fighters to send.%s" % drill_words,"Wait for the drill to finish, then give the order." if int(f.drilling)>0 else "Raise a levy and have it drilled first.")
	if going<MIN_FORCE:
		return _no(out,"too_few","%d trained %s cannot take a town. %s would shut the gate and laugh at us.%s" % [going,"fighter" if going==1 else "fighters",name,drill_words],("Give me those %d days of drill and I will take all of them." % int(f.drill_days)) if int(f.drilling)>0 else "Raise and drill a real levy first.")
	var days:=ceili(float(road.length_km)/maxf(0.1,mc._field_army_speed(use_army if not use_army.is_empty() else mc.home_army)))
	var enemy:=_enemy_estimate(String(target.city_id))
	var ratio:=going_strength/maxf(1.0,float(enemy.get("mid",0.0))*0.9) if bool(enemy.known) else 1.0
	out["estimate"]=enemy
	out["going"]=going
	out["days"]=days
	out["road_km"]=float(road.length_km)
	if bool(enemy.known) and ratio<OBJECT_RATIO and not insist:
		var their:="about %d" % roundi(float(enemy.mid)) if int(enemy.low)!=int(enemy.high) else "%d" % int(enemy.low)
		return _object(out,"outnumbered","%s keeps %s under arms behind its walls; we would bring %d%s. I would lose them for nothing." % [name,their,going,", most of them half-drilled" if ratio<0.5 else ""],("Let the drill finish first, about %d days." % int(f.drill_days)) if int(f.drilling)>0 else "Give me more trained soldiers first.")
	if drilled<UNDRILLED and not insist:
		return _object(out,"undrilled","%d who have never drilled together, against %s's walls? They would break at the first charge." % [going,name],("Give me the rest of their drill first, about %d days." % int(f.drill_days)) if int(f.drilling)>0 else "Give me a season to drill them first.")
	if kind=="siege" and going<MIN_FORCE*3 and not insist:
		return _object(out,"siege_too_small","A siege needs enough of us to ring %s and still feed ourselves; %d cannot do it." % [name,going],"Let me storm it instead, or give me more soldiers.")
	# Act: the force is formed from the real formations and set on the road.
	var formed:=false
	var army_id:=int(use_army.get("army_id",0))
	if use_army.is_empty():
		var made:Dictionary=mc.create_field_army(send,_host_name(kind,name))
		if made.has("error"): return _no(out,"cannot_form",String(made.error),"")
		army_id=int((made.army as Dictionary).army_id); formed=true
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
	if not use_army.is_empty() and not String(army.get("name","")).contains(name): army["name"]=_host_name(kind,name)
	mc.field_armies[index]=army
	mc.army_changed.emit(mc.home_army.duplicate(true))
	days=int(order.get("days",days))
	var verb:String={"attack":"to attack","siege":"to lay siege to","raid":"to raid the fields and stores of"}.get(kind,"against")
	var roundabout:="" if bool(road.get("direct",true)) else " going round the water by land"
	out.verdict="act"
	out.objective={"army_id":army_id,"army_name":String(army.get("name","")),"city_id":String(target.city_id),"civ_id":String(target.civ_id),"kind":kind,"days":days,"troops":going,"route_km":float(road.length_km)}
	out.says="%d of us march %s %s. It is %d km%s, about %d days. %s" % [going,verb,name,roundi(float(road.length_km)),roundabout,days,"I keep %d at home to watch the approaches." % keep if keep>0 else "Nobody trained stays behind."]
	out.outcome="%s leaves with %d %s for %s: %d km%s, about %d days on the road.%s" % [String(army.get("name","The army")),going,"fighter" if going==1 else "fighters",name,roundi(float(road.length_km)),roundabout,days,"" if at_war else " There has been no declaration; the war begins when they reach %s, and %s will hear of it before then." % [name,Hall._civ_name(String(target.civ_id))]]
	_on_departure(out,army,target,at_war)
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
	Chronicle.record({"key":"court_war:%s:%d:%d" % [name,day,int(out.objective.army_id)],"title":("%s Marches on %s" % [String(out.general),place]).substr(0,70),"text":String(out.outcome),"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	_ledger_add({"day":day,"army_id":int(out.objective.army_id),"civ_id":civ_id,"city_id":String(target.city_id),"city_name":place,"kind":String(out.kind),"general":String(out.general),"status":"marching","going":int(out.objective.troops)})
	if int(out.general_pid)>0:
		GovernmentPeopleSystem.record_person_memory(int(out.general_pid),"The god sent me against %s with %d." % [place,int(out.objective.troops)],"divine",0.7,{"emotion":"duty","outcome":"marching"})

static func _recall(out:Dictionary)->Dictionary:
	var mc:=_mc()
	var sent:Array[String]=[]
	var longest:=0
	var blocked:Array[String]=[]
	for a in mc.field_armies.duplicate():
		var army:Dictionary=a
		if int(army.get("troops",0))<=0: continue
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
		out.outcome=out.says
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
	out.outcome=out.says
	return out

static func _intercept(out:Dictionary,reading:Dictionary,insist:bool)->Dictionary:
	var target:Dictionary=reading.get("target",{})
	var civ_id:=String(target.get("civ_id",""))
	var mc:=_mc()
	var seen:Array[Dictionary]=[]
	for formation in WorldSimulation.world.foreign_formations:
		var rec:Dictionary=formation
		if String(rec.get("kind",""))=="scout": continue
		if civ_id!="" and String(rec.get("civ_id",""))!=civ_id: continue
		var sighting:Dictionary=WorldSimulation.world.visible_formation_sighting(String(rec.get("id","")))
		if not sighting.is_empty(): seen.append({"id":String(rec.id),"sighting":sighting})
	if seen.is_empty():
		var whose:=Hall._civ_name(civ_id) if civ_id!="" else "the enemy"
		return _no(out,"no_sighting","Nobody has seen %s's fighters in the open lately, so there is nothing to march at." % whose,"Tell me to march on their town instead, or send scouts to find their army.")
	var f:=forces()
	if String(f.busy)!="": return _no(out,"busy","We cannot start another fight while %s." % String(f.busy),"")
	var going:=int(f.trained)
	if not (f.idle as Array).is_empty(): going=maxi(going,int((f.idle as Array)[0].troops))
	if going<MIN_FORCE: return _no(out,"too_few","%d trained fighters cannot meet an army in the field." % going,"Let the levy finish its drill first.")
	var army_id:=int((f.idle as Array)[0].army_id) if not (f.idle as Array).is_empty() and int((f.idle as Array)[0].troops)>=int(f.trained) else 0
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
