extends RefCounted
## ORDERS FROM THE ARMY SCREEN, THROUGH THE COURT'S WAR CORE.
##
## The Army command screen asks three plain things: who goes, what they do,
## and where. This file turns those answers into the same objective the
## court would give (court_war_orders.gd): the war leader weighs it, objects
## honestly or refuses with the reason, and "insist" overrides an objection.
## Marches use the general's land road (army_land_route.gd through
## MilitaryCampaign.field_route), the war chart shows the mark, and the
## Chronicle and the court's report ledger record it exactly as for a spoken
## order.
##
## Who goes:
##   0         the levy at home. Orders go straight to WO.perform(), the
##             court's own entry point, so the result is identical.
##   army_id   a band already formed (at home or away). The same checks and
##             the same MilitaryCampaign calls, aimed at that band.
## What:  attack · siege · raid (a known town, or attack a sighted host)
##        defend (home watch, as the court does) · recall (come home)
##        guard (hold ground around a clicked spot; a drawn-zone defend order
##               with a radius set for the band's size) · goto (march there)
##        depot (march there and build a supply depot, field_depots.gd)
## Static helpers; preload.

const WO:=preload("res://scripts/court_war_orders.gd")
const Odds:=preload("res://scripts/war_odds.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const R:=preload("res://scripts/joint_regions.gd")
const G:=preload("res://scripts/joint_geography.gd")

const HOME:=0
## What the player can ask, in the order the screen shows them.
const VERBS:=[
	{"id":"attack","label":"Attack","needs":"place","hint":"Storm a town, or go after a host that was seen."},
	{"id":"siege","label":"Besiege","needs":"place","hint":"Ring a town and starve it out."},
	{"id":"raid","label":"Raid","needs":"place","hint":"Burn their fields and carry off their stores, then come back."},
	{"id":"defend","label":"Defend home","needs":"","hint":"Bring every band home and keep watch on the approaches for half a year."},
	{"id":"guard","label":"Guard a place","needs":"spot","hint":"March to the ground you click and hold it against anyone who comes."},
	{"id":"goto","label":"Go to…","needs":"spot","hint":"March to the ground you click and wait there."},
	{"id":"depot","label":"Lay a depot","needs":"spot","hint":"March to the ground you click and build a supply depot there. Bands beyond it are fed as if the road behind it were half as long."},
	{"id":"recall","label":"Come home","needs":"","hint":"Turn for home by the land road."},
]

static func verb(id:String)->Dictionary:
	for v:Dictionary in VERBS:
		if String(v.id)==id: return v
	return {}

static func _mc()->Node: return WorldSimulation.military

static func _today()->int: return int(WorldSimulation.state.elapsed_days)

static func _home()->Vector2: return WorldSimulation.world.player_world_origin

static func _v2(p:Variant)->Vector2:
	if p is Dictionary and (p as Dictionary).has_all(["x","z"]): return Vector2(float(p.x),float(p.z))
	return Vector2.INF

static func army(army_id:int)->Dictionary:
	if army_id<=0 or _mc()==null: return {}
	var index:int=_mc()._field_army_index(army_id)
	return {} if index<0 else _mc().field_armies[index]

static func at_home(record:Dictionary)->bool:
	return Marks.at_home(record,_home())

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func general_name(record:Dictionary)->String:
	## A band's own leader's given name, or "" for a nameless staff.
	var name:=String((record.get("commander",{}) as Dictionary).get("name","")).strip_edges()
	if name=="" or name==name.to_upper() or "staff" in name.to_lower() or name.to_lower() in Marks.UNNAMED: return ""
	return WO.given_name(name)

static func war_leader_name()->String:
	var leader:=WO.war_leader()
	return WO.given_name(String(leader.get("name",""))) if not leader.is_empty() else ""

static func drill_words(training:float)->String:
	if training<0.2: return "barely drilled"
	if training<0.45: return "half drilled"
	if training<0.75: return "drilled"
	return "well drilled"

static func distance_words(from:Vector2)->String:
	var d:=from.distance_to(_home())
	if d<1.0: return "at home"
	var way:=Marks.compass(from-_home())
	return "%s km %s" % [EraWords.grouped(roundi(d)),way] if way!="" else "%s km out" % EraWords.grouped(roundi(d))

static func place_name(p:Dictionary)->String:
	return Marks.place(String(p.get("name","")).trim_prefix("Reported home of "))

# --------------------------------------------------------------------------
# Who can go
# --------------------------------------------------------------------------

static func forces()->Array[Dictionary]:
	## Cards for the screen: the levy at home first, then every band.
	## {id, title, detail, troops, at_home, busy, position}
	var out:Array[Dictionary]=[]
	var mc:=_mc()
	if mc==null or WorldSimulation.world==null: return out
	var f:=WO.forces()
	var leader:=war_leader_name()
	var noun:=Marks.noun(maxi(1,int(f.trained)),EraWords.stage())
	var drilled:=WO.drill_of(mc.home_army.get("formations",[]))
	var home_detail:=PackedStringArray()
	if int(f.trained)>0: home_detail.append(drill_words(drilled))
	if int(f.drilling)>0: home_detail.append("%d more in their first drill, about %d %s to go" % [int(f.drilling),int(f.drill_days),"day" if int(f.drill_days)==1 else "days"])
	if int(f.trained)<=0 and int(f.drilling)<=0: home_detail.append("nobody trained yet")
	var home_title:=("%s's %s at home, %d" % [leader,"levy" if noun=="band" else noun,int(f.trained)]) if leader!="" else ("The levy at home, %d" % int(f.trained))
	out.append({"id":HOME,"title":home_title,"detail":_sentence(" · ".join(home_detail)),"troops":int(f.trained),"at_home":true,"position":_home(),"drilling":int(f.drilling)})
	for a in mc.field_armies:
		var record:Dictionary=a
		var troops:=int(record.get("troops",0))
		if troops<=0 or bool(record.get("embarked",false)): continue
		var home:=at_home(record)
		var shown:Dictionary=record if home or mc._live_army_reporting() else record.get("last_report",record)
		var pos:=_v2(shown.get("position",record.get("position",{})))
		var general:=general_name(record)
		var word:=Marks.noun(troops,EraWords.stage())
		var name:=String(record.get("name","")).strip_edges()
		var title:=("%s's %s, %d" % [general,word,troops]) if general!="" else ("%s, %d" % [name if name!="" else "Our "+word,troops])
		var parts:=PackedStringArray()
		var destination:=String(record.get("destination_name",""))
		var ordered:Dictionary=record.get("court_order",{})
		if destination=="" and not ordered.is_empty(): destination=String(ordered.get("city_name",""))
		var doing:=Marks.doing({"status":String(record.get("status","")),"destination_name":destination,"destination_id":String(record.get("destination_id","")),
			"location_name":String(record.get("location_name","")),"command_status":String(record.get("command_status","")),"at_home":home,"home_km":Marks.home_km(shown,_home()),
			"besieging":String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","")) if not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==int(record.army_id) else "",
			"fighting":mc.command_hierarchy.battle.engaged(int(record.army_id)),"days_left":maxi(0,int(record.get("arrival_day",0))-_today())})
		parts.append(doing)
		parts.append(drill_words(WO.drill_of(record.get("formations",[]))))
		if not home and pos.is_finite() and pos.distance_to(_home())>=1.0: parts.append(distance_words(pos))
		if preload("res://scripts/field_rations.gd").is_hungry(record): parts.append("going hungry" if float(record.get("provision_ratio",1.0))<0.45 else "short of food")
		out.append({"id":int(record.army_id),"title":title,"detail":_sentence(" · ".join(parts)),"troops":troops,"at_home":home,"position":pos,"name":name})
	return out

# --------------------------------------------------------------------------
# Where
# --------------------------------------------------------------------------

static func places()->Array[Dictionary]:
	## Known foreign towns, nearest first: the court's own list.
	var list:=WO.known_places()
	var home:=_home()
	list.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return home.distance_squared_to(_v2(a.position))<home.distance_squared_to(_v2(b.position)))
	return list

static func place(city_id:String)->Dictionary:
	for p:Dictionary in WO.known_places():
		if String(p.city_id)==city_id: return p
	return {}

static func hosts()->Array[Dictionary]:
	## Their fighting hosts in sight now: {formation_id, civ_id, label, position}.
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	for formation in WorldSimulation.world.foreign_formations:
		var rec:Dictionary=formation
		if String(rec.get("kind",""))=="scout": continue
		var seen:Dictionary=WorldSimulation.world.visible_formation_sighting(String(rec.get("id","")))
		if seen.is_empty(): continue
		var civ:=String(rec.get("civ_id",seen.get("civ_id","")))
		out.append({"formation_id":String(rec.id),"civ_id":civ,"label":"The %s host" % WO.civ_name(civ),"position":(seen.get("position",{}) as Dictionary).duplicate(true)})
	return out

static func target_title(target:Dictionary)->String:
	match String(target.get("type","")):
		"place": return place_name(target.get("place",{}))
		"host": return String(target.get("label","their host"))
		"spot": return spot_words(Vector2(float(target.x),float(target.z)))
	return ""

static func spot_words(at:Vector2)->String:
	## "the marked ground, 12 km north-west of home" or "near Tsaren".
	var best:={}
	var best_d:=INF
	for p:Dictionary in WO.known_places():
		var d:=at.distance_to(_v2(p.position))
		if d<best_d: best_d=d; best=p
	if not best.is_empty() and best_d<6.0: return "the ground near %s" % place_name(best)
	var d_home:=at.distance_to(_home())
	if d_home<1.0: return "the ground at home"
	var way:=Marks.compass(at-_home())
	return "the marked ground, %s km %s of home" % [EraWords.grouped(roundi(d_home)),way]

# --------------------------------------------------------------------------
# What it would cost (before the order)
# --------------------------------------------------------------------------

static func needs(verb_id:String)->String:
	return String(verb(verb_id).get("needs",""))

static func unavailable(force_id:int,verb_id:String)->String:
	## Why this verb cannot be chosen for this force, or "".
	var mc:=_mc()
	if mc==null: return "We have nothing organised to fight with yet."
	if force_id==HOME:
		var f:=WO.forces()
		if verb_id=="recall":
			return "" if not (f.away as Array).is_empty() else "Everyone is already at home."
		if int(f.trained)<=0 and int(f.drilling)<=0 and verb_id!="defend": return "Nobody at home is trained or in drill yet."
		if int(f.trained)<=0 and verb_id in ["guard","goto","depot"]: return "Nobody at home has finished drilling yet."
		if verb_id=="depot":
			var trained:=int(f.trained)
			return mc.depots.blocked(trained-(ceili(trained*WO.WATCH_SHARE) if trained>=WO.MIN_FORCE*2 else 0))
		return ""
	var record:=army(force_id)
	if record.is_empty(): return "That band is no longer on the rolls."
	if verb_id=="recall" and (at_home(record) or String(record.get("destination_id",""))=="player_home"): return "Already home or on the way."
	if verb_id in ["attack","siege","raid"] and not WO.available(record): return "Not free for a new order now. Call it home first, or wait."
	if verb_id=="depot": return mc.depots.blocked(int(record.get("troops",0)))
	return ""

static func preview(force_id:int,verb_id:String,target:Dictionary)->Dictionary:
	## Plain lines about what the order would do, and whether the war leader
	## is likely to object. {lines:[...], likely:"act"|"object"|"impossible",
	## ready:bool (enough chosen to give the order), road:[Vector2], days, km}
	var out:={"lines":[],"likely":"act","ready":false,"road":[],"days":0,"km":0.0,"men":0,"arrive_day":-1}
	var mc:=_mc()
	if mc==null or WorldSimulation.world==null or verb_id=="": return out
	var blocked:=unavailable(force_id,verb_id)
	if blocked!="":
		out.lines.append(blocked); out.likely="impossible"; return out
	var kind:=needs(verb_id)
	if kind=="place" and not String(target.get("type","")) in ["place","host"]:
		out.lines.append("Click a town or one of their hosts on the map, or pick a town below.")
		return out
	if kind=="spot" and String(target.get("type",""))!="spot":
		out.lines.append("Click the ground on the map where they should go.")
		return out
	out.ready=true
	var leader:=war_leader_name()
	var f:=WO.forces()
	var record:=army(force_id)
	var from:=_home() if force_id==HOME else _v2(record.get("position",{}))
	var going:=int(record.get("troops",0))
	var keep:=0
	var formations:Array=record.get("formations",[])
	var speed_force:Dictionary=record
	if force_id==HOME:
		var trained:=int(f.trained)
		keep=ceili(trained*WO.WATCH_SHARE) if trained>=WO.MIN_FORCE*2 and verb_id!="guard" else 0
		going=trained-keep
		formations=mc.home_army.get("formations",[])
		speed_force=mc.home_army
	out.men=going
	match verb_id:
		"defend":
			out.men=int(f.trained)
			var away:=(f.away as Array).size()
			out.lines.append("The %d trained at home watch every approach for half a year." % int(f.trained))
			if away>0: out.lines.append("%s away %s called home to join them." % [EraWords.count_word(away).capitalize()+(" band" if away==1 else " bands"),"is" if away==1 else "are"])
			return out
		"recall":
			if force_id==HOME:
				out.lines.append("Every band away turns for home by the land road.")
				return out
			var road:Dictionary=mc.field_route(from,_home(),record) if from.distance_to(_home())>=0.5 else {"length_km":0.0,"points":[_home()]}
			if road.has("error"): out.lines.append(String(road.error)); out.likely="impossible"; return out
			_road_lines(out,road,record,"home")
			return out
	var there:=Vector2.INF
	match String(target.get("type","")):
		"place": there=_v2((target.get("place",{}) as Dictionary).get("position",{}))
		"host": there=_v2(target.get("position",{}))
		"spot": there=Vector2(float(target.get("x",0)),float(target.get("z",0)))
	if not there.is_finite():
		out.ready=false; out.lines.append("That place is not on our charts."); return out
	var road:Dictionary=mc.field_route(from,there,speed_force) if from.distance_to(there)>=0.5 else {"length_km":0.0,"points":[there],"direct":true}
	if road.has("error"):
		out.lines.append(String(road.error)); out.likely="impossible"; return out
	_road_lines(out,road,speed_force,target_title(target))
	if going<=0 and force_id==HOME and int(f.drilling)>0 and verb_id in ["attack","siege","raid"]:
		var leads:=leader if leader!="" else "The war leader"
		out.lines.append("Nobody has finished drill. %s will want to wait, about %d days, unless you insist and he takes the %d recruits as they are." % [leads,int(f.drill_days),int(f.drilling)])
		out.likely="object"; return out
	if going<=0:
		out.lines.append("Nobody trained is free to go."); out.likely="impossible"; return out
	if keep>0: out.lines.append("%d go; %d stay home to keep watch." % [going,keep])
	elif force_id!=HOME:
		var leads:=general_name(record)
		out.lines.append("All %d of %s go." % [going,("%s's %s" % [leads,Marks.noun(going,EraWords.stage())]) if leads!="" else String(record.get("name","the band"))])
	else: out.lines.append("All %d trained at home go; nobody trained stays behind." % going)
	if verb_id in ["attack","siege","raid"] and String(target.get("type",""))=="place":
		var p:Dictionary=target.place
		var name:=place_name(p)
		var enemy:=WO.enemy_estimate(String(p.city_id))
		if bool(enemy.known):
			var age:=Marks.age_words(int(enemy.age),"counted")
			out.lines.append("%s keeps %s under arms%s." % [name,Marks.about_range(int(enemy.low),int(enemy.high)),(", "+age) if age!="" else ""])
		else:
			out.lines.append("Nobody has counted the fighters in %s." % name)
		var strength:=WO.strength_of(formations)*(float(going)/maxf(1.0,float(_heads(formations))))
		var ratio:=strength/maxf(1.0,float(enemy.get("mid",0.0))*0.9) if bool(enemy.known) else 1.0
		var drill:=WO.drill_of(formations)
		var who_objects:=leader if leader!="" else "The war leader"
		# The war leader's stated odds (war_odds.gd), reckoned before he
		# objects so that he objects by them.
		var arms:=[]
		var odds:={}
		if bool(enemy.known) and going>0:
			arms=_their_arms(String(p.civ_id),int(enemy.age))
			if not arms.is_empty(): out.lines.append("They carry %s." % arms_words(arms))
			odds=stated_odds(speed_force,formations,going,float(enemy.get("mid",0.0)),float(enemy.get("fortification",0.25)),arms,String(p.civ_id))
			if not odds.is_empty():
				out["odds"]=odds
				out.lines.append("Odds%s: %s%s." % [" with the arms our scouts saw" if not arms.is_empty() else ", if they carry arms like ours",odds_words(float(odds.odds),bool(odds.ours)),(", their walls counting for them" if float(odds.walls)>1.08 else "")])
		var weaker:=Odds.weaker(odds) if not odds.is_empty() else ratio<WO.OBJECT_RATIO
		if going<WO.MIN_FORCE:
			out.likely="impossible"; out.lines.append("%d cannot take a town; %s will refuse." % [going,who_objects])
		elif bool(enemy.known) and weaker:
			out.likely="object"; out.lines.append("%s will probably object: we would be the weaker side." % who_objects)
		elif drill<WO.UNDRILLED:
			out.likely="object"; out.lines.append("%s will probably object: they have hardly drilled." % who_objects)
		elif verb_id=="siege" and going<WO.MIN_FORCE*3:
			out.likely="object"; out.lines.append("%s will probably object: too few to ring the town." % who_objects)
		if not WO.at_war(String(p.civ_id)):
			out.lines.append("We are not at war with %s. The war starts when they arrive, and %s will hear of the march before then." % [WO.civ_name(String(p.civ_id)),name])
	elif verb_id=="guard":
		out.lines.append("They hold about %s km around it and fight anyone hostile who comes into it." % EraWords.grouped(roundi(guard_radius(going))))
	elif verb_id=="depot":
		var Depots:=preload("res://scripts/field_depots.gd")
		out.lines.append("There they build a depot: sheds, ovens and a fence, about %d days for %d hands." % [Depots.days_for(going),going])
		# What it does here, by today's line (field_depots.impact_at).
		var gain:=Depots.impact_at(there)
		if gain.is_empty(): pass
		elif float(gain.with)-float(gain.now)<0.03:
			out.lines.append("A depot here would save little: the carriers eat little on the way already.")
		else:
			out.lines.append("Carriers walk %s to get here. Eating at the depot, %d%% of each load would arrive instead of %d%%, here and beyond." % [Supply.days_words(float(gain.days)),roundi(float(gain.with)*100.0),roundi(float(gain.now)*100.0)])
		var given_up:Dictionary=mc.depots.replaces()
		if not given_up.is_empty(): out.lines.append("We keep %d depots; the one %s is given up when this one stands." % [int(mc.depots.limit()),String(given_up.name).trim_prefix("Depot ")])
		out.lines.append("A host at war with us passing within %d km burns it, unless our bands there are at least half its strength." % roundi(Depots.RAID_KM))
	return out

## The stated odds and the scouts' word on their arms live in war_odds.gd,
## which the court's spoken orders read too.
static func stated_odds(force:Dictionary,formations:Array,going:int,their_men:float,fortification:float,their_arms:Array=[],civ_id:String="")->Dictionary:
	return Odds.of(force,formations,going,their_men,fortification,their_arms,civ_id)

static func _their_arms(civ_id:String,age:int)->Array: return Odds.their_arms(civ_id,age)
static func arms_words(arms:Array)->String: return Odds.arms_words(arms)
static func odds_words(odds:float,ours:bool)->String: return Odds.words(odds,ours)
static func odds_short(odds:float,ours:bool)->String: return Odds.short(odds,ours)

static func _sentence(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _heads(formations:Array)->int:
	var n:=0
	for f in formations: n+=maxi(0,int((f as Dictionary).get("count",0)))
	return n

static func _road_lines(out:Dictionary,road:Dictionary,force:Dictionary,where:String)->void:
	var km:=float(road.get("length_km",0.0))
	# The one march estimate (march_terrain.gd through MilitaryCampaign).
	var days:=int(_mc().march_days(force,road)) if km>0.0 and not (force.get("formations",[]) as Array).is_empty() else (ceili(km/12.0) if km>0.0 else 0)
	out.km=km; out.days=days
	out["arrive_day"]=_today()+days
	var points:Array=[]
	for p in road.get("points",[]): points.append(p)
	out.road=points
	if km<0.5: out.lines.append("They are already there."); return
	var round_water:="" if bool(road.get("direct",true)) else " by land round the water"
	var ground:=String(road.get("ground_words",""))
	out.lines.append("The road to %s is %s km%s%s, about %d %s." % [where,EraWords.grouped(roundi(km)),round_water," "+ground if ground!="" else "",days,"day" if days==1 else "days"])

static func guard_radius(troops:int)->float:
	return clampf(sqrt(maxf(1.0,float(troops)))*0.6,2.0,15.0)

# --------------------------------------------------------------------------
# Giving the order
# --------------------------------------------------------------------------

static func give(force_id:int,verb_id:String,target:Dictionary,insist:bool=false)->Dictionary:
	## The war leader's answer, the same shape as WO.perform():
	## {verdict:"act"|"object"|"impossible", kind, general, says, outcome,
	##  reason, fix, objective}.
	var mc:=_mc()
	if mc==null or WorldSimulation.world==null:
		return WO.perform({"kind":"attack"},insist)
	var blocked:=unavailable(force_id,verb_id)
	if blocked!="":
		return _answer("impossible",verb_id,"unavailable",blocked,"")
	match verb_id:
		"defend": return WO.perform({"kind":"defend","place":"","target":{},"full":false,"insist":insist},insist)
		"recall": return WO.perform({"kind":"recall","target":{},"full":false,"insist":insist},insist,{} if force_id==HOME else {"army_id":force_id})
		"guard": return _guard(force_id,target)
		"goto": return _go_to(force_id,target)
		"depot": return _lay_depot(force_id,target)
	var kind:=verb_id
	var reading:={"kind":kind,"target":{},"full":false,"insist":insist,"place":""}
	match String(target.get("type","")):
		"host":
			reading.kind="intercept"
			reading.target={"civ_id":String(target.get("civ_id","")),"formation_id":String(target.get("formation_id",""))}
		"place": reading.target=(target.place as Dictionary).duplicate(true)
		_: return _answer("impossible",verb_id,"no_target","You have not shown me where.","Click a town on the map, or pick one from the list.")
	if force_id==HOME: return WO.perform(reading,insist,{"home_only":true})
	_release_from_zone(force_id)
	return WO.perform(reading,insist,{"army_id":force_id})

static func _answer(verdict:String,kind:String,reason:String,says:String,fix:String)->Dictionary:
	var leader:=war_leader_name()
	var out:={"kind":kind,"general":leader if leader!="" else "The war leader","general_pid":0,"verdict":verdict,"reason":reason,"says":says,"fix":fix,"objective":{},"outcome":""}
	if verdict=="impossible": out.outcome="No soldiers march. "+says+(" "+fix if fix!="" else "")
	elif verdict=="object": out.outcome="No soldiers march yet: %s objects. %s %s" % [String(out.general),says,fix]
	else: out.outcome=says
	return out

static func _release_from_zone(army_id:int)->void:
	## A band under a drawn-zone order leaves it before a new objective, so
	## the zone staff do not pull it back.
	var command:RefCounted=_mc().command_hierarchy
	if not command.controls_army(army_id): return
	for entry:Dictionary in command.data.nodes.values():
		if entry.service=="army" and int(entry.force_id)==army_id:
			command.cancel(String(entry.id),[])
			return

static func _form_from_home(label:String)->Dictionary:
	## The levy at home becomes a band for a march: {army_id} or {error}.
	var mc:=_mc()
	var f:=WO.forces()
	var trained:=int(f.trained)
	var keep:=ceili(trained*WO.WATCH_SHARE) if trained>=WO.MIN_FORCE*2 else 0
	var send:=trained-keep
	if send<=0: return {"error":"Nobody at home is trained yet."}
	var made:Dictionary=mc.create_field_army(send,label)
	if made.has("error"): return made
	return {"army_id":int((made.army as Dictionary).army_id),"formed":true,"keep":keep}

static func _go_to(force_id:int,target:Dictionary)->Dictionary:
	var mc:=_mc()
	if String(target.get("type",""))!="spot": return _answer("impossible","goto","no_target","You have not shown me where.","Click the ground on the map.")
	var where:=spot_words(Vector2(float(target.x),float(target.z)))
	var army_id:=force_id
	var formed:=false
	var keep:=0
	if force_id==HOME:
		var made:=_form_from_home("Band sent to %s" % where.trim_prefix("the "))
		if made.has("error"): return _answer("impossible","goto","no_trained",String(made.error),"Raise a levy and have it drilled first.")
		army_id=int(made.army_id); formed=true; keep=int(made.keep)
	else:
		_release_from_zone(army_id)
	var r:Dictionary=mc.move_field_army_to_position(army_id,float(target.x),float(target.z),"the marked ground")
	if r.has("error"):
		if formed: mc.disband_field_army(army_id)
		return _answer("impossible","goto","order_failed",String(r.error),"")
	var record:=army(army_id)
	var days:=maxi(0,int(record.get("arrival_day",_today()))-_today())
	var out:=_answer("act","goto","","","")
	out.objective={"army_id":army_id,"kind":"goto","days":days,"troops":int(record.get("troops",0)),"route_km":float(record.get("distance_total_km",0.0))}
	out.says=("%d of us march to %s: %d km, about %d %s." % [int(record.get("troops",0)),where,roundi(float(record.get("distance_total_km",0.0))),days,"day" if days==1 else "days"]) if days>0 else "We are there already."
	if keep>0: out.says+=" I keep %d at home to watch the approaches." % keep
	out.outcome=out.says
	return out

## March to the spot and build a depot there (field_depots.gd).
static func _lay_depot(force_id:int,target:Dictionary)->Dictionary:
	var out:=_go_to(force_id,target)
	if String(out.get("verdict",""))!="act": out.kind="depot"; return out
	var army_id:=int((out.get("objective",{}) as Dictionary).get("army_id",-1))
	var mc:=_mc()
	mc.depots.assign(army_id,Vector2(float(target.x),float(target.z)))
	var men:=int(army(army_id).get("troops",0))
	out.kind="depot"
	out.objective.kind="depot"
	out.says+=" There we build the depot, about %d days' work." % preload("res://scripts/field_depots.gd").days_for(men)
	out.outcome=out.says
	return out

static func _guard(force_id:int,target:Dictionary)->Dictionary:
	## A defend order on a drawn zone the staff lay out round the clicked
	## ground, sized for the band. The zone staff march, patrol and fight.
	var mc:=_mc()
	if String(target.get("type",""))!="spot": return _answer("impossible","guard","no_target","You have not shown me where.","Click the ground on the map.")
	var at:=Vector2(float(target.x),float(target.z))
	var command:RefCounted=mc.command_hierarchy
	command.sync()
	var node_id:=""
	var troops:=0
	for entry:Dictionary in command.data.nodes.values():
		if entry.service=="army" and int(entry.force_id)==force_id:
			node_id=String(entry.id); troops=command.amount(entry); break
	if node_id=="" or troops<=0: return _answer("impossible","guard","no_trained","Nobody trained is free to go.","Raise a levy and have it drilled first.")
	var radius:=guard_radius(troops)
	var vertices:Array=[]
	for i in 8:
		var p:=at+Vector2.from_angle(TAU*float(i)/8.0)*radius
		vertices.append({"x":p.x,"z":p.y})
	var where:=spot_words(at)
	var made:Dictionary=command.create_region("army",vertices,_sentence(where.trim_prefix("the ")))
	if made.has("error"): return _answer("impossible","guard","no_zone",String(made.error),"")
	var region:Dictionary=made.region
	var result:Dictionary=command.assign(node_id,[],region,"defend","","")
	if result.has("error"):
		command.remove_region(String(region.id))
		return _answer("impossible","guard","order_failed",String(result.error),"")
	var out:=_answer("act","guard","","","")
	var node:Dictionary=command.node(String(result.id))
	out.objective={"army_id":int(node.get("force_id",-1)),"kind":"guard","zone_id":String(region.id),"troops":troops}
	out.says="%d of us go to hold %s, about %s km round, and fight anyone hostile who comes into it." % [troops,where,EraWords.grouped(roundi(radius))]
	out.outcome=out.says
	return out

# --------------------------------------------------------------------------
# One line for the screen, and drawn plans (the HOI4 battle plan)
# --------------------------------------------------------------------------

const Dates:=preload("res://scripts/hud/deployment_model.gd")
## An arrow ending this close to a town or a host they saw aims at it.
const ARROW_SNAP_KM:=4.0
## A drawn front line shorter than this is a point, not a line.
const MIN_FRONT_KM:=0.7

## The one "What happens" line from a preview (or a plan preview):
## "24 men · 3 days · arrive 12 Spring", with the war leader's likely
## answer when it is not a plain yes. The preview's full lines stay for the
## tooltip.
static func summary(plan:Dictionary)->String:
	if plan.is_empty(): return ""
	var lines:Array=plan.get("lines",[])
	if String(plan.get("likely",""))=="impossible" or not bool(plan.get("ready",false)):
		return String(lines[0]).get_slice(". ",0).trim_suffix(".") if not lines.is_empty() else ""
	var parts:=PackedStringArray()
	if int(plan.get("men",0))>0: parts.append("%s men" % EraWords.grouped(int(plan.men)))
	if float(plan.get("front_km",0.0))>0.0: parts.append("%s km line" % EraWords.grouped(maxi(1,roundi(float(plan.front_km)))))
	var km:=float(plan.get("km",0.0))
	var days:=int(plan.get("days",0))
	if km>=0.5:
		parts.append("%d %s" % [days,"day" if days==1 else "days"])
		if int(plan.get("arrive_day",-1))>=0: parts.append("arrive "+Dates.day_words(int(plan.arrive_day)))
	elif not (plan.get("road",[]) as Array).is_empty(): parts.append("already there")
	if plan.has("odds"): parts.append("odds "+odds_short(float(plan.odds.odds),bool(plan.odds.ours)))
	if String(plan.get("likely",""))=="object":
		var leader:=war_leader_name()
		parts.append("%s will object" % (leader if leader!="" else "the war leader"))
	return " · ".join(parts)


static func _points(raw:Array)->Array[Vector2]:
	var out:Array[Vector2]=[]
	for p in raw:
		var at:Vector2=p if p is Vector2 else _v2(p)
		if at.is_finite() and (out.is_empty() or out[-1].distance_to(at)>=0.1): out.append(at)
	return out


static func line_km(points:Array)->float:
	var line:=_points(points)
	var km:=0.0
	for i in range(1,line.size()): km+=line[i-1].distance_to(line[i])
	return km


## A drawn front line as ground to hold: a strip along the line, as wide
## as a band of this size can watch (guard_radius). [] when the line
## cannot make a simple outline even held straight from end to end.
static func front_zone(points:Array,troops:int)->Array:
	var line:=_points(points)
	if line.size()<2 or line_km(line)<MIN_FRONT_KM: return []
	var half:=clampf(guard_radius(troops)*0.4,0.8,6.0)
	# Few enough corners for a zone (joint_regions: at most 64).
	while line.size()>14:
		var thinned:Array[Vector2]=[]
		for i in line.size():
			if i%2==0 or i==line.size()-1: thinned.append(line[i])
		line=thinned
	for attempt in 2:
		var left:Array[Vector2]=[]
		var right:Array[Vector2]=[]
		for i in line.size():
			var ahead:=(line[mini(i+1,line.size()-1)]-line[maxi(i-1,0)]).normalized()
			var normal:=Vector2(-ahead.y,ahead.x)
			var at:=line[i]
			if i==0: at-=ahead*half*0.6
			elif i==line.size()-1: at+=ahead*half*0.6
			left.append(at+normal*half)
			right.push_front(at-normal*half)
		var vertices:Array=[]
		for p:Vector2 in left+right: vertices.append(G.pack(p))
		if R.validate(vertices)=="": return vertices
		# A sharp bend folds the strip: hold the straight line from end to end.
		var ends:Array[Vector2]=[line[0],line[-1]]
		line=ends
	return []


## Where an arrow ending at `to` aims: a known town or a host they saw close
## by (attack), else the ground itself (advance there). {verb, target}.
static func arrow_target(to:Vector2)->Dictionary:
	var best:={}
	var best_d:=ARROW_SNAP_KM
	for p:Dictionary in WO.known_places():
		var d:=to.distance_to(_v2(p.position))
		if d<best_d:
			best_d=d
			best=p
	if not best.is_empty(): return {"verb":"attack","target":{"type":"place","place":best}}
	for host:Dictionary in hosts():
		var d:=to.distance_to(_v2(host.position))
		if d<best_d:
			best_d=d
			best=host
	if not best.is_empty(): return {"verb":"attack","target":{"type":"host","formation_id":String(best.formation_id),"civ_id":String(best.civ_id),"label":String(best.label),"position":best.position}}
	return {"verb":"goto","target":{"type":"spot","x":to.x,"z":to.y}}


## What a drawn plan would do, in the shape of preview(): an arrow is the
## order it resolves to; a front line is the march to it and the ground held.
static func plan_preview(force_id:int,plan:Dictionary)->Dictionary:
	match String(plan.get("kind","")):
		"arrow":
			var aim:Dictionary=plan if plan.has("verb") else arrow_target(_v2(plan.get("to",{})))
			var out:=preview(force_id,String(aim.verb),aim.target)
			out["verb"]=String(aim.verb)
			return out
		"front":
			var line:=_points(plan.get("points",[]))
			var km:=line_km(line)
			if line.size()<2 or km<MIN_FRONT_KM:
				return {"lines":["Click two or more points on the map for the line."],"likely":"act","ready":false,"road":[],"days":0,"km":0.0,"men":0,"arrive_day":-1,"front_km":0.0}
			var middle:Vector2=line[line.size()/2] if line.size()>2 else line[0].lerp(line[1],0.5)
			var out:=preview(force_id,"guard",{"type":"spot","x":middle.x,"z":middle.y})
			out["front_km"]=km
			if bool(out.ready):
				var kept:Array=[]
				for text in out.lines:
					if not String(text).begins_with("They hold about"): kept.append(text)
				kept.append("They hold a line of %s km and fight anyone hostile who crosses it." % EraWords.grouped(maxi(1,roundi(km))))
				out.lines=kept
			return out
	return {"lines":["Draw the line or the arrow on the map first."],"likely":"act","ready":false,"road":[],"days":0,"km":0.0,"men":0,"arrive_day":-1}


## Carry out a drawn plan through the same objectives as every other order:
## an arrow attacks the town or host it points at, or advances to the
## ground (give()); a front line is held as a defended zone along it (the
## zone staff march, patrol and fight, as for Guard).
static func give_plan(force_id:int,plan:Dictionary,insist:bool=false)->Dictionary:
	match String(plan.get("kind","")):
		"arrow":
			var aim:Dictionary=plan if plan.has("verb") else arrow_target(_v2(plan.get("to",{})))
			return give(force_id,String(aim.verb),aim.target,insist)
		"front": return _hold_front(force_id,plan.get("points",[]))
	return _answer("impossible","plan","no_plan","Draw the line or the arrow on the map first.","")


static func _hold_front(force_id:int,points:Array)->Dictionary:
	var mc:=_mc()
	if mc==null: return _answer("impossible","front","no_force","We have nothing organised to fight with yet.","")
	var blocked:=unavailable(force_id,"guard")
	if blocked!="": return _answer("impossible","front","unavailable",blocked,"")
	var line:=_points(points)
	if line.size()<2 or line_km(line)<MIN_FRONT_KM: return _answer("impossible","front","no_target","That line is too short to hold.","Click two or more points on the map.")
	var command:RefCounted=mc.command_hierarchy
	command.sync()
	var node_id:=""
	var troops:=0
	for entry:Dictionary in command.data.nodes.values():
		if entry.service=="army" and int(entry.force_id)==force_id:
			node_id=String(entry.id)
			troops=command.amount(entry)
			break
	if node_id=="" or troops<=0: return _answer("impossible","front","no_trained","Nobody trained is free to go.","Raise a levy and have it drilled first.")
	var vertices:=front_zone(line,troops)
	if vertices.is_empty(): return _answer("impossible","front","no_zone","That line folds over itself.","Draw it again with gentler bends.")
	var middle:Vector2=line[line.size()/2] if line.size()>2 else line[0].lerp(line[1],0.5)
	var where:=spot_words(middle)
	var made:Dictionary=command.create_region("army",vertices,_sentence("line "+where.trim_prefix("the ")))
	if made.has("error"): return _answer("impossible","front","no_zone",String(made.error),"")
	var region:Dictionary=made.region
	var packed:Array=[]
	for p:Vector2 in line: packed.append(G.pack(p))
	region["plan"]="front"
	region["line"]=packed
	_release_from_zone(force_id)
	var result:Dictionary=command.assign(node_id,[],region,"defend","","")
	if result.has("error"):
		command.remove_region(String(region.id))
		return _answer("impossible","front","order_failed",String(result.error),"")
	var out:=_answer("act","front","","","")
	var node:Dictionary=command.node(String(result.id))
	var km:=line_km(line)
	out.objective={"army_id":int(node.get("force_id",-1)),"kind":"front","zone_id":String(region.id),"troops":troops,"km":km}
	out.says="%d of us hold the line %s, %s km of it, and fight anyone hostile who crosses." % [troops,where,EraWords.grouped(maxi(1,roundi(km)))]
	out.outcome=out.says
	return out
