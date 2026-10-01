extends RefCounted
## COMMANDS: a leader and the bands under them, the unit the ruler works in.
## The player assigns bands to a leader's command; the leader sees to the
## rest (routes, camps, pacing, supply, the fight), as the general-led design
## has it (docs/GENERAL_CAMPAIGN_DESIGN.md). The engine already reads a
## band's leader through its commander record: command, tactics and resolve
## in battle (battle_tactics.gd, battle_record.gd), logistics for how fast a
## band recovers heart in camp, and the war leader at home's logistics for
## how well the carriers move (carriers.gd).
##
## A command is keyed by its leader:
##   a named general (HistoricalFigures, role "General"): their figure id;
##   WAR_LEADER: the war leader at home (the Marshal, else the acting field
##     staff), who leads every band without a named general.
## A band's leader is its commander record's figure_id (HistoricalFigures
## keeps the slot "army_<id>" -> figure in its assignments), so a command is
## read from the bands themselves and needs nothing saved of its own.
## Static helpers; preload.

const Logistics:=preload("res://scripts/equipment_logistics.gd")
const Counter:=preload("res://scripts/hud/army_counter.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const WAR_LEADER:="war_leader"
## Each command's colour on the map and the army bar. The war leader's is our
## own blue; each general's comes from PALETTE by the order the generals came
## forward, so a general keeps their colour for life. No red: red is theirs.
const WAR_LEADER_COLOR:=Color("#4f9bb8")
const PALETTE:=[Color("#2f7f6f"),Color("#6b5b95"),Color("#8a6a2f"),Color("#3f5f8f"),Color("#7a4f6d"),Color("#4f7a3a"),Color("#5f6f7f"),Color("#3a4a8a")]


## The colour of a command (a leader key: a figure id or WAR_LEADER).
static func color(leader_id:String)->Color:
	if leader_id=="" or leader_id==WAR_LEADER:return WAR_LEADER_COLOR
	var parts:=leader_id.split("_")
	var serial:=int(parts[parts.size()-1]) if parts.size()>1 and String(parts[parts.size()-1]).is_valid_int() else absi(leader_id.hash())
	return PALETTE[posmod(serial,PALETTE.size())]


## The leader key of an army bar card: its general, its command's key, or
## WAR_LEADER.
static func leader_of_card(card:Dictionary,mc:Variant=null)->String:
	var id:=String(card.get("id",""))
	if id.begins_with("general:"):
		var key:=id.trim_prefix("general:")
		return WAR_LEADER if key=="war_leader" or key==war_leader_figure(mc) else key
	var figure:=String((card.get("general",{}) as Dictionary).get("figure_id","")) if card.get("general") is Dictionary else ""
	return WAR_LEADER if figure=="" or figure==war_leader_figure(mc) else figure


static func _mc(mc:Variant)->Node:
	return mc if mc!=null else MilitaryCampaign


static func _figures()->Node:
	return WorldSimulation.figures if WorldSimulation!=null else null


## The figure the war leader at home is, when a named general holds that
## place (no Marshal in office: HistoricalFigures' "home" slot); "" else.
static func war_leader_figure(mc:Variant=null)->String:
	var host:=_mc(mc)
	var home:Dictionary=host.home_army.get("commander",{}) if host.home_army is Dictionary and host.home_army.get("commander") is Dictionary else {}
	return String(home.get("figure_id",""))


## The leader key of a band: its general's figure id, or WAR_LEADER (no named
## general, or the war leader at home's own figure).
static func leader_of(army:Dictionary,mc:Variant=null)->String:
	var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
	var figure_id:=String(commander.get("figure_id",""))
	if figure_id=="" or figure_id==war_leader_figure(mc):return WAR_LEADER
	var figures:=_figures()
	if figures!=null:
		var person:Dictionary=figures.by_id(figure_id)
		if person.is_empty() or String(person.get("status",""))=="dead":return WAR_LEADER
	return figure_id


## Every leader who commands bands or could: {id, name, title, figure_id,
## person (the figure), commander (skills), status}. The war leader first,
## then the generals by name.
static func leaders(mc:Variant=null)->Array[Dictionary]:
	var host:=_mc(mc)
	sync_commanders(host)
	var out:Array[Dictionary]=[]
	var home:Dictionary=host.home_army.get("commander",{}) if host.home_army is Dictionary else {}
	var figures:=_figures()
	var home_figure:=String(home.get("figure_id",""))
	var home_person:Dictionary=figures.by_id(home_figure) if figures!=null and home_figure!="" else {}
	out.append({"id":WAR_LEADER,"name":String(home.get("name","The war leader")),"title":"War leader at home","figure_id":home_figure,"person":home_person,"commander":home.duplicate(true),"status":"living"})
	if figures==null:return out
	figures.ensure()
	var generals:Array[Dictionary]=[]
	for person:Dictionary in figures.people:
		if String(person.get("role",""))!="General" or String(person.get("status",""))=="dead":continue
		if String(person.id)==home_figure:continue
		generals.append({"id":String(person.id),"name":String(person.name),"title":"General","figure_id":String(person.id),"person":person,"commander":_commander_of(host,String(person.id)),"status":String(person.get("status","living"))})
	generals.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.name).naturalnocasecmp_to(String(b.name))<0)
	out.append_array(generals)
	return out


## Each band (and garrison, and the band at home when a named general holds
## it) keeps its general's commander record, drawn when the general took it.
## When the general's own skills have changed since (they grew in battle or
## in the field, or the save is older than generals' own skills), the record
## is drawn again from them, so the engine, the leaders' screen and the War
## screen read the same numbers. Idempotent; returns how many were redrawn.
static func sync_commanders(host:Node)->int:
	var figures:=_figures()
	if figures==null or host==null: return 0
	var base:Dictionary={}
	var changed:=0
	for force in host.field_armies:
		if figures.sync_force(host,force as Dictionary,base): changed+=1
	for force in host.occupation_forces:
		if figures.sync_force(host,force as Dictionary,base): changed+=1
	if host.home_army is Dictionary and not (host.home_army as Dictionary).is_empty() and figures.sync_force(host,host.home_army,base): changed+=1
	return changed

## A general's skills as the engine gives them to the bands they lead: the
## commander record of any band they lead, else as one would be made.
static func _commander_of(host:Node,figure_id:String)->Dictionary:
	for army_variant in host.field_armies:
		var army:Dictionary=army_variant
		var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		if String(commander.get("figure_id",""))==figure_id:return commander.duplicate(true)
	var figures:=_figures()
	var person:Dictionary=figures.by_id(figure_id) if figures!=null else {}
	if person.is_empty():return {}
	# The same record HistoricalFigures.commander puts on a band they lead:
	# the general's own skills, with what the realm's army lends them.
	return figures.commander_record(person,host._acting_field_commander(false))


## The commands as they stand: one per leader with bands (the war leader's
## always, even with none), then the leaders without a command.
## {id, leader (as leaders()), bands:[army ids], men, full, issued, required,
##  will (by men), supply (by men), hungry, breaking, marching, foraging,
##  places:{name: bands}}.
static func commands(mc:Variant=null)->Array[Dictionary]:
	var host:=_mc(mc)
	var by:={}
	for leader:Dictionary in leaders(host):
		by[String(leader.id)]={"id":String(leader.id),"leader":leader,"bands":[],"men":0,"full":0,"issued":0,"required":0,"will":0.0,"supply":0.0,"hungry":0,"breaking":0,"marching":0,"foraging":0,"places":{}}
	for army_variant in host.field_armies:
		var army:Dictionary=army_variant
		var men:=int(army.get("troops",0))
		if men<=0:continue
		var key:=leader_of(army,host)
		if not by.has(key):key=WAR_LEADER
		var command:Dictionary=by[key]
		(command.bands as Array).append(int(army.get("army_id",0)))
		command.men=int(command.men)+men
		command.full=int(command.full)+maxi(men,ArmyMarks.full_strength(army))
		for formation_variant in army.get("formations",[]):
			var formation:Dictionary=formation_variant
			command.issued=int(command.issued)+mini(int(formation.get("equipment",0)),int(formation.get("equipment_required",formation.get("count",0))))
			command.required=int(command.required)+int(formation.get("equipment_required",formation.get("count",0)))
		var will:=clampf(float(army.get("morale",0.6)),0.0,1.0)
		command.will=float(command.will)+will*men
		command.supply=float(command.supply)+clampf(float(army.get("provision_ratio",army.get("supply_level",1.0))),0.0,1.0)*men
		if Rations.is_hungry(army):command.hungry=int(command.hungry)+1
		if will<0.3:command.breaking=int(command.breaking)+1
		if String(army.get("status",""))=="moving":
			command.marching=int(command.marching)+1
			if bool(army.get("living_off_land",false)):command.foraging=int(command.foraging)+1
		var place:=String(army.get("destination_name" if String(army.get("status",""))=="moving" else "location_name","")).strip_edges()
		if place=="":place="the field"
		command.places[place]=int((command.places as Dictionary).get(place,0))+1
	var out:Array[Dictionary]=[]
	for key in by:
		var command:Dictionary=by[key]
		var men:=maxi(1,int(command.men))
		command.will=float(command.will)/men if int(command.men)>0 else 0.0
		command.supply=float(command.supply)/men if int(command.men)>0 else 0.0
		if String(key)==WAR_LEADER or not (command.bands as Array).is_empty():out.append(command)
	# The free generals last.
	for key in by:
		var command:Dictionary=by[key]
		if String(key)!=WAR_LEADER and (command.bands as Array).is_empty():out.append(command)
	return out


## Puts a band under a leader's command: a named general (their figure id) or
## WAR_LEADER. The band fights, camps and recovers with that leader's skills
## from now on. Not while it is in battle.
## {ok, message} or {error}.
static func assign(mc:Variant,army_id:int,leader_id:String)->Dictionary:
	var host:=_mc(mc)
	var index:int=host._field_army_index(army_id)
	if index<0:return {"error":"There is no such band."}
	var army:Dictionary=host.field_armies[index]
	if host.command_hierarchy.battle.engaged(army_id) or host._army_in_battle(army_id):return {"error":"That band is fighting; it changes leaders when the fight is done."}
	var figures:=_figures()
	var slot:="army_%d" % army_id
	var before:=Logistics.force_name(army)
	var leader_name:=""
	if leader_id==WAR_LEADER:
		if figures!=null:figures.assignments.erase(slot)
		army["commander"]=host._marshal_commander()
		leader_name=String((army.commander as Dictionary).get("name","the war leader"))
	else:
		if figures==null:return {"error":"No leaders are known yet."}
		var person:Dictionary=figures.by_id(leader_id)
		if person.is_empty() or String(person.get("role",""))!="General":return {"error":"There is no such general."}
		if String(person.get("status",""))!="living":return {"error":"%s cannot lead a band now (%s)." % [String(person.name),String(person.get("status",""))]}
		figures.assignments[slot]=leader_id
		army["commander"]=figures.commander(host._acting_field_commander(false),slot)
		leader_name=String(person.name)
	# A march the court ordered is led by the new leader from now on.
	if army.get("court_order") is Dictionary:(army.court_order as Dictionary)["general"]=leader_name.get_slice(" ",0)
	host.field_armies[index]=army
	return {"ok":true,"message":"%s now serves under %s." % [before,leader_name],"leader":leader_name}


## A leader's record from the figure: battles fought, won and lost, our men
## lost under them and theirs, their pace on the march, the days their bands
## went hungry, the men who deserted them, the days in the field and the
## years in public life (HistoricalFigures RECORD_KEYS). {} for the war
## leader at home.
static func record(leader:Dictionary)->Dictionary:
	var person:Dictionary=leader.get("person",{})
	if person.is_empty():return {}
	var today:=int(WorldSimulation.state.elapsed_days)
	var kept:Dictionary=person.get("record",{}) if person.get("record") is Dictionary else {}
	var march_days:=float(kept.get("march_days",0.0))
	return {"battles":(person.get("battle_keys",[]) as Array).size(),"won":int(person.get("battles_won",0)),"lost":int(person.get("battles_lost",0)),
		"years":maxi(0,(today-int(person.get("emerged",today)))/365),"age":maxi(0,(today-int(person.get("born",today)))/365),"renown":int(person.get("renown",0)),
		"men_lost":roundi(float(kept.get("men_lost",0.0))),"enemy_lost":roundi(float(kept.get("enemy_lost",0.0))),
		"km_day":float(kept.get("march_km",0.0))/march_days if march_days>=1.0 else 0.0,"march_days":roundi(march_days),
		"hungry_days":roundi(float(kept.get("hungry_days",0.0))),"deserted":roundi(float(kept.get("deserted",0.0))),"field_days":roundi(float(kept.get("field_days",0.0)))}
