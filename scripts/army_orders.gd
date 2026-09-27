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
## Static helpers; preload.

const WO:=preload("res://scripts/court_war_orders.gd")
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
	return String(record.get("status",""))=="stationed" and String(record.get("location_id",""))=="player_home"

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func general_name(record:Dictionary)->String:
	## A band's own leader's given name, or "" for a nameless staff.
	var name:=String((record.get("commander",{}) as Dictionary).get("name","")).strip_edges()
	if name=="" or name==name.to_upper() or "staff" in name.to_lower() or name.to_lower() in Marks.UNNAMED: return ""
	return WO._given(name)

static func war_leader_name()->String:
	var leader:=WO.war_leader()
	return WO._given(String(leader.get("name",""))) if not leader.is_empty() else ""

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
	var drilled:=WO._drill(mc.home_army.get("formations",[]))
	var home_detail:=PackedStringArray()
	if int(f.trained)>0: home_detail.append(drill_words(drilled))
	if int(f.drilling)>0: home_detail.append("%d more in their first drill, about %d %s to go" % [int(f.drilling),int(f.drill_days),"day" if int(f.drill_days)==1 else "days"])
	if int(f.trained)<=0 and int(f.drilling)<=0: home_detail.append("nobody trained yet")
	var home_title:=("%s's %s at home, %d" % [leader,"levy" if noun=="band" else noun,int(f.trained)]) if leader!="" else ("The levy at home, %d" % int(f.trained))
	out.append({"id":HOME,"title":home_title,"detail":Marks._sentence(" · ".join(home_detail)),"troops":int(f.trained),"at_home":true,"position":_home(),"drilling":int(f.drilling)})
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
			"location_name":String(record.get("location_name","")),"command_status":String(record.get("command_status","")),"at_home":home,
			"besieging":String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","")) if not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==int(record.army_id) else "",
			"fighting":mc.command_hierarchy.battle.engaged(int(record.army_id)),"days_left":maxi(0,int(record.get("arrival_day",0))-_today())})
		parts.append(doing)
		parts.append(drill_words(WO._drill(record.get("formations",[]))))
		if not home and pos.is_finite() and pos.distance_to(_home())>=1.0: parts.append(distance_words(pos))
		out.append({"id":int(record.army_id),"title":title,"detail":Marks._sentence(" · ".join(parts)),"troops":troops,"at_home":home,"position":pos,"name":name})
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
		out.append({"formation_id":String(rec.id),"civ_id":civ,"label":"The %s host" % WO.Hall._civ_name(civ),"position":(seen.get("position",{}) as Dictionary).duplicate(true)})
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
		if int(f.trained)<=0 and verb_id!="defend":
			return "Nobody at home is trained yet." if int(f.drilling)<=0 else "Nobody at home has finished drilling yet."
		return ""
	var record:=army(force_id)
	if record.is_empty(): return "That band is no longer on the rolls."
	if verb_id=="recall" and (at_home(record) or String(record.get("destination_id",""))=="player_home"): return "Already home or on the way."
	return ""

static func preview(force_id:int,verb_id:String,target:Dictionary)->Dictionary:
	## Plain lines about what the order would do, and whether the war leader
	## is likely to object. {lines:[...], likely:"act"|"object"|"impossible",
	## ready:bool (enough chosen to give the order), road:[Vector2], days, km}
	var out:={"lines":[],"likely":"act","ready":false,"road":[],"days":0,"km":0.0}
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
		var idle:Array=f.idle
		if not idle.is_empty() and verb_id in ["attack","siege","raid"]:
			idle.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.troops)>int(b.troops))
			if int(idle[0].troops)>=going:
				going=int(idle[0].troops); keep=0; formations=idle[0].get("formations",[]); speed_force=idle[0]
				out.lines.append("%s goes: they are the band already standing ready at home." % String(idle[0].get("name","The band at home")))
	match verb_id:
		"defend":
			var away:=(f.away as Array).size()
			out.lines.append("The %d trained at home watch every approach for half a year." % int(f.trained))
			if away>0: out.lines.append("%s away %s called home to join them." % [EraWords.count_word(away).capitalize()+(" band" if away==1 else " bands"),"is" if away==1 else "are"])
			return out
		"recall":
			if force_id==HOME:
				out.lines.append("Every band away turns for home by the land road.")
				return out
			var road:Dictionary=mc.field_route(from,_home()) if from.distance_to(_home())>=0.5 else {"length_km":0.0,"points":[_home()]}
			if road.has("error"): out.lines.append(String(road.error)); out.likely="impossible"; return out
			_road_lines(out,road,mc._field_army_speed(record),"home")
			return out
	var there:=Vector2.INF
	match String(target.get("type","")):
		"place": there=_v2((target.get("place",{}) as Dictionary).get("position",{}))
		"host": there=_v2(target.get("position",{}))
		"spot": there=Vector2(float(target.get("x",0)),float(target.get("z",0)))
	if not there.is_finite():
		out.ready=false; out.lines.append("That place is not on our charts."); return out
	var road:Dictionary=mc.field_route(from,there) if from.distance_to(there)>=0.5 else {"length_km":0.0,"points":[there],"direct":true}
	if road.has("error"):
		out.lines.append(String(road.error)); out.likely="impossible"; return out
	var speed:float=mc._field_army_speed(speed_force) if not (speed_force.get("formations",[]) as Array).is_empty() else 12.0
	_road_lines(out,road,speed,target_title(target))
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
		var enemy:=WO._enemy_estimate(String(p.city_id))
		if bool(enemy.known):
			var age:=Marks.age_words(int(enemy.age),"counted")
			out.lines.append("%s keeps %s under arms%s." % [name,Marks.about_range(int(enemy.low),int(enemy.high)),(", "+age) if age!="" else ""])
		else:
			out.lines.append("Nobody has counted the fighters in %s." % name)
		var strength:=WO._strength(formations)*(float(going)/maxf(1.0,float(_heads(formations))))
		var ratio:=strength/maxf(1.0,float(enemy.get("mid",0.0))*0.9) if bool(enemy.known) else 1.0
		var drill:=WO._drill(formations)
		var who_objects:=leader if leader!="" else "The war leader"
		if going<WO.MIN_FORCE:
			out.likely="impossible"; out.lines.append("%d cannot take a town; %s will refuse." % [going,who_objects])
		elif bool(enemy.known) and ratio<WO.OBJECT_RATIO:
			out.likely="object"; out.lines.append("%s will probably object: we would be the weaker side." % who_objects)
		elif drill<WO.UNDRILLED:
			out.likely="object"; out.lines.append("%s will probably object: they have hardly drilled." % who_objects)
		elif verb_id=="siege" and going<WO.MIN_FORCE*3:
			out.likely="object"; out.lines.append("%s will probably object: too few to ring the town." % who_objects)
		if not WO._at_war(String(p.civ_id)):
			out.lines.append("We are not at war with %s. The war starts when they arrive, and %s will hear of the march before then." % [WO.Hall._civ_name(String(p.civ_id)),name])
	elif verb_id=="guard":
		out.lines.append("They hold about %s km around it and fight anyone hostile who comes into it." % EraWords.grouped(roundi(guard_radius(going))))
	return out

static func _heads(formations:Array)->int:
	var n:=0
	for f in formations: n+=maxi(0,int((f as Dictionary).get("count",0)))
	return n

static func _road_lines(out:Dictionary,road:Dictionary,speed:float,where:String)->void:
	var km:=float(road.get("length_km",0.0))
	var days:=ceili(km/maxf(0.1,speed)) if km>0.0 else 0
	out.km=km; out.days=days
	var points:Array=[]
	for p in road.get("points",[]): points.append(p)
	out.road=points
	if km<0.5: out.lines.append("They are already there."); return
	var round_water:="" if bool(road.get("direct",true)) else " by land round the water"
	out.lines.append("The road to %s is %s km%s, about %d %s." % [where,EraWords.grouped(roundi(km)),round_water,days,"day" if days==1 else "days"])

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
		"recall":
			if force_id==HOME: return WO.perform({"kind":"recall","target":{},"full":false,"insist":insist},insist)
			return _recall_one(force_id)
		"guard": return _guard(force_id,target)
		"goto": return _go_to(force_id,target)
	var kind:=verb_id
	if String(target.get("type",""))=="host":
		kind="intercept"
	elif String(target.get("type",""))!="place":
		return _answer("impossible",verb_id,"no_target","You have not shown me where.","Click a town on the map, or pick one from the list.")
	if force_id==HOME:
		if kind=="intercept":
			return WO.perform({"kind":"intercept","target":{"civ_id":String(target.get("civ_id",""))},"full":false,"insist":insist},insist)
		return WO.perform({"kind":kind,"target":(target.place as Dictionary).duplicate(true),"full":false,"insist":insist,"place":""},insist)
	_release_from_zone(force_id)
	if kind=="intercept": return _intercept_with(force_id,target)
	return _strike_with(force_id,kind,target.place,insist)

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

static func _strike_with(army_id:int,kind:String,target:Dictionary,insist:bool)->Dictionary:
	## WO._strike() for one chosen band: same checks, same objections, same
	## MilitaryCampaign calls, same court_order tag, ledger and Chronicle.
	var mc:=_mc()
	var leader:=WO.war_leader()
	var out:={"kind":kind,"general":WO._given(String(leader.get("name","The war leader"))),"general_pid":int(leader.get("person_id",0)),"verdict":"impossible","outcome":"","says":"","reason":"","fix":"","objective":{}}
	var record:=army(army_id)
	if record.is_empty(): return WO._no(out,"cannot_form","That band is no longer on the rolls.","")
	var name:=place_name(target)
	out["target"]=target.duplicate(true)
	var f:=WO.forces()
	if String(f.busy)!="": return WO._no(out,"busy","We cannot start another fight while %s." % String(f.busy),"When that is done, give the order again.")
	var ordered:Dictionary=record.get("court_order",{})
	if String(ordered.get("city_id",""))==String(target.city_id) and String(ordered.get("kind",""))==kind and String(record.get("status",""))=="moving":
		return WO._no(out,"already_marching","%s is already on the road to %s." % [String(record.get("name","That band")),name],"")
	var quote:Dictionary=mc.city_operation_quote(army_id,String(target.civ_id),String(target.city_id))
	if quote.has("error"):
		var why:=String(quote.get("reason",""))
		if why=="no_land_route":
			return WO._no(out,"no_land_route","There is no way to %s on foot: open water lies between us, and we have no boats that can carry an army." % name,"If our people learn to build boats that carry more than a few, or scouts find a way round by land, we can go.")
		return WO._no(out,why if why!="" else "order_failed",String(quote.error),"")
	var going:=int(record.get("troops",0))
	var formations:Array=record.get("formations",[])
	if going<WO.MIN_FORCE:
		return WO._no(out,"too_few","%d %s cannot take a town. %s would shut the gate and laugh at us." % [going,"fighter" if going==1 else "fighters",name],"Send a bigger band, or let the levy finish its drill.")
	var enemy:=WO._enemy_estimate(String(target.city_id))
	var ratio:=WO._strength(formations)/maxf(1.0,float(enemy.get("mid",0.0))*0.9) if bool(enemy.known) else 1.0
	var drilled:=WO._drill(formations)
	out["estimate"]=enemy
	out["going"]=going
	out["days"]=int(quote.days)
	out["road_km"]=float(quote.distance_km)
	if bool(enemy.known) and ratio<WO.OBJECT_RATIO and not insist:
		var their:="about %d" % roundi(float(enemy.mid)) if int(enemy.low)!=int(enemy.high) else "%d" % int(enemy.low)
		return WO._object(out,"outnumbered","%s keeps %s under arms behind its walls; we would bring %d%s. I would lose them for nothing." % [name,their,going,", most of them half-drilled" if ratio<0.5 else ""],"Give me more trained soldiers first.")
	if drilled<WO.UNDRILLED and not insist:
		return WO._object(out,"undrilled","%d who have never drilled together, against %s's walls? They would break at the first charge." % [going,name],"Give me a season to drill them first.")
	if kind=="siege" and going<WO.MIN_FORCE*3 and not insist:
		return WO._object(out,"siege_too_small","A siege needs enough of us to ring %s and still feed ourselves; %d cannot do it." % [name,going],"Let me storm it instead, or give me more soldiers.")
	var order:Dictionary=mc.order_city_operation(army_id,String(target.civ_id),String(target.city_id),kind=="siege",kind=="raid")
	if order.has("error"): return WO._no(out,"order_failed",String(order.error),"")
	var index:int=mc._field_army_index(army_id)
	if index<0: return WO._no(out,"order_failed","The band could not be set on the road.","")
	var marching:Dictionary=mc.field_armies[index]
	var at_war:=WO._at_war(String(target.civ_id))
	marching["court_order"]={"kind":kind,"civ_id":String(target.civ_id),"city_id":String(target.city_id),"city_name":name,"day":_today(),"general":String(out.general),"general_pid":int(out.general_pid),"going":going}
	mc.field_armies[index]=marching
	mc.army_changed.emit(mc.home_army.duplicate(true))
	var days:=int(order.get("days",quote.days))
	var km:=float(order.get("distance_km",quote.distance_km))
	var verb_words:String={"attack":"to attack","siege":"to lay siege to","raid":"to raid the fields and stores of"}.get(kind,"against")
	var roundabout:="" if bool(quote.get("direct",true)) else " going round the water by land"
	out.verdict="act"
	out.objective={"army_id":army_id,"army_name":String(marching.get("name","")),"city_id":String(target.city_id),"civ_id":String(target.civ_id),"kind":kind,"days":days,"troops":going,"route_km":km}
	out.says=("%d of us march %s %s. It is %d km%s, about %d days." % [going,verb_words,name,roundi(km),roundabout,days]) if km>0.5 else ("We are at %s already; we go in now." % name)
	out.outcome="%s leaves with %d %s for %s: %d km%s, about %d days on the road.%s" % [String(marching.get("name","The band")),going,"fighter" if going==1 else "fighters",name,roundi(km),roundabout,days,"" if at_war else " There has been no declaration; the war begins when they reach %s, and %s will hear of it before then." % [name,WO.Hall._civ_name(String(target.civ_id))]]
	WO._on_departure(out,marching,target,at_war)
	return out

static func _intercept_with(army_id:int,target:Dictionary)->Dictionary:
	var mc:=_mc()
	var out:=_answer("impossible","intercept","","","")
	var result:Dictionary=mc.order_field_army_intercept(army_id,String(target.get("formation_id","")))
	if result.has("error"):
		out.reason="order_failed"; out.says=String(result.error); out.outcome="No soldiers march. "+out.says
		return out
	var record:=army(army_id)
	out.verdict="act"
	out.objective={"army_id":army_id,"kind":"intercept","formation_id":String(target.get("formation_id","")),"troops":int(record.get("troops",0))}
	out.says="We go after %s, toward where they were last seen." % String(target.get("label","their host")).to_lower()
	out.outcome="%s sets out to catch %s in the open." % [String(record.get("name","The band")),String(target.get("label","their host")).to_lower()]
	return out

static func _recall_one(army_id:int)->Dictionary:
	## WO._recall() for one band: the same MilitaryCampaign call.
	var mc:=_mc()
	var record:=army(army_id)
	var name:=String(record.get("name","The band"))
	var r:Dictionary=mc.return_field_army(army_id)
	if r.has("error"): return _answer("impossible","recall","cannot_recall","I cannot bring them back yet. "+String(r.error),"")
	var index:int=mc._field_army_index(army_id)
	if index>=0: mc.field_armies[index].erase("court_order")
	var days:=int(r.get("days",0))
	var out:=_answer("act","recall","","","")
	out.objective={"army_id":-1,"recalled":[name],"days":days,"kind":"recall"}
	if days<=0:
		out.says="%s is home again." % name
	else:
		out.says="I have sent runners: %s is turning for home, about %d %s out." % [name,days,"day" if days==1 else "days"]
	out.outcome=out.says if days<=0 else "%s is marching home, about %d %s away." % [name,days,"day" if days==1 else "days"]
	return out

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
	var made:Dictionary=command.create_region("army",vertices,Marks._sentence(where.trim_prefix("the ")))
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
