class_name BattleView
extends RefCounted
## THE BATTLE VIEW for any caller.
##
##   BattleView.list_now()        the battles being fought right now
##   BattleView.open(target)      the battle panel on a battle: an engagement
##                                id, a battle seed, or a record Dictionary
##   BattleView.find(target)      {record, live} for a target, or {}
##
## Every entry point that used to open the stick-figure replay (the report
## card, the court, the Chronicle, war planning, the siege screen and the
## map) opens the battle panel through here. Opening a battle never fights
## it: a live battle is read as it stands and a finished one from its record.

const Record:=preload("res://scripts/battle_record.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const PANEL_PATH:="res://scripts/hud/battle_panel.gd"
const META:="battle_panel_layer"
## The war chart's own two inks (hud/war_front_overlay.gd OURS / THEIRS).
const OURS:=Color("#2f5d6b")
const THEIRS:=Color("#8e3b2e")
## Two neutral inks for a fight between other peoples.
const FIRST:=Color("#6a4f1f")
const SECOND:=Color("#3e506f")


## The battles being fought right now: [{id, x, z, sides:{a:{civ_id, name,
## colour, troops}, b:{...}}, progress, status, day, place_name}]. Side a is
## ours when we fight, else the attacker; progress is side a's (-1..1).
static func list_now()->Array:
	var out:Array=[]
	for engagement in live_engagements():
		out.append(summary(engagement))
	return out


## One live battle as list_now() gives it.
static func summary(engagement:Dictionary)->Dictionary:
	var threat:Dictionary=engagement.get("threat",{})
	var home:=String(engagement.get("home_side",""))
	var player:=home in ["attacker","defender"]
	var a:=home if player else "attacker"
	var b:="defender" if a=="attacker" else "attacker"
	var at:=_position(engagement)
	var sides:={}
	for pair in [["a",a],["b",b]]:
		var role:=String(pair[1])
		var force:Dictionary=engagement.get(role,{})
		var ours:=player and role==home
		sides[pair[0]]={"civ_id":"player" if ours else String(threat.get("source_civ_id",force.get("civ_id",""))),
			"name":String(force.get("name","")),"colour":(OURS if ours else THEIRS) if player else (FIRST if role=="attacker" else SECOND),
			"troops":int(force.get("troops",force.get("remaining_troops",0)))}
	var battle:Dictionary=engagement.get("battle",{})
	return {"id":String(engagement.get("id","")),"x":at.x,"z":at.y,"sides":sides,
		"progress":float(engagement.get("progress",0.0)) if player else float(battle.get("progress",0.0)),
		"status":"drawn up" if int(engagement.get("round",0))<=0 else "fighting",
		"day":int(threat.get("discovered_day",0)),"place_name":_place(engagement)}


## Every battle being fought now, the player's own and those the generals run.
static func live_engagements()->Array:
	var mc:Node=_military()
	if mc==null: return []
	var out:Array=[]
	var seen:={}
	var registry:Variant=mc.get("engagements")
	if registry is Dictionary:
		for id in registry:
			var engagement:Variant=registry[id]
			if engagement is Dictionary and not (engagement as Dictionary).is_empty():
				out.append(engagement); seen[String((engagement as Dictionary).get("id",id))]=true
	var active:Dictionary=mc.active_engagement
	if not active.is_empty() and not seen.has(String(active.get("id","-"))): out.append(active); seen[String(active.get("id","-"))]=true
	var hierarchy:Variant=mc.get("command_hierarchy")
	if hierarchy!=null:
		for engagement in (hierarchy.data.get("battles",[]) as Array):
			if engagement is Dictionary and not seen.has(String((engagement as Dictionary).get("id","-"))): out.append(engagement)
	return out


## A battle to show: {record, live} for an engagement id, a seed, or a record.
static func find(target:Variant)->Dictionary:
	if target is Dictionary:
		var given:Dictionary=target
		if given.is_empty(): return {}
		for engagement in live_engagements():
			if String(engagement.get("id",""))!="" and String(engagement.get("id",""))==String(given.get("id","")): return {"record":engagement,"live":true}
		return {"record":given,"live":false}
	var mc:Node=_military()
	if mc==null: return {}
	var id:=String(target) if target is String or target is StringName else ""
	var seed:=int(target) if target is int else -1
	for engagement in live_engagements():
		if (id!="" and String(engagement.get("id",""))==id) or (seed>=0 and int(engagement.get("seed",-1))==seed): return {"record":engagement,"live":true}
	for past in mc.battle_history:
		if (id!="" and String((past as Dictionary).get("id",""))==id) or (seed>=0 and int((past as Dictionary).get("seed",-2))==seed): return {"record":past,"live":false}
	for past in observed():
		if (id!="" and String((past as Dictionary).get("id",""))==id) or (seed>=0 and int((past as Dictionary).get("seed",-2))==seed): return {"record":past,"live":false}
	return {}


## The war leader's clashes with raiders and rivals (war_loop.gd), kept to
## be watched: newest first.
static func observed()->Array:
	return preload("res://scripts/war_loop.gd").observed_battles()


## The most useful battle when nothing is named: the one being fought for
## this army, else any being fought, else the last one fought.
static func pick(army_id:int=0)->Dictionary:
	var live:=live_engagements()
	for engagement in live:
		if army_id>0 and _involves(engagement,army_id): return {"record":engagement,"live":true}
	for engagement in live:
		if not bool(engagement.get("commander_managed",false)): return {"record":engagement,"live":true}
	if not live.is_empty(): return {"record":live[0],"live":true}
	var mc:Node=_military()
	if mc!=null and not (mc.battle_history as Array).is_empty(): return {"record":mc.battle_history[0],"live":false}
	return {}


## Opens the battle panel. target: engagement id (String), battle seed (int),
## or a record (Dictionary). host: the node to hang the panel on (the map
## when omitted). Returns the panel, or null when there is nothing to show.
static func open(target:Variant,host:Node=null)->Control:
	var found:=find(target) if not (target is int and int(target)<0) else pick()
	if found.is_empty(): return null
	return open_found(found,host)


static func open_found(found:Dictionary,host:Node=null)->Control:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null: return null
	if host==null: host=tree.current_scene if tree.current_scene!=null else tree.root
	close_open(host)
	var record:Dictionary=found.record
	if bool(found.get("live",false)): record.erase("awaiting_player_view")
	var layer:=CanvasLayer.new(); layer.name="BattlePanelLayer"; layer.layer=80
	host.add_child(layer)
	var panel:Control=load(PANEL_PATH).new()
	panel.set("host",host)
	panel.set("record",record)
	panel.set("live",bool(found.get("live",false)))
	layer.add_child(panel)
	host.set_meta(META,layer)
	var ui:Node=tree.root.get_node_or_null("MilitaryCommandUI")
	if ui!=null: ui.set("battle_graphics",panel)
	return panel


static func close_open(host:Node)->void:
	if host!=null and host.has_meta(META):
		var old:Variant=host.get_meta(META)
		if is_instance_valid(old): (old as Node).queue_free()
		host.remove_meta(META)


## The words battle_record.view needs for a record: the two sides' names as
## our people say them, the generals, the place and the era's words.
static func words(record:Dictionary,live:bool)->Dictionary:
	var stage:=EraWords.stage()
	var home:=String(record.get("home_side",""))
	var threat:Dictionary=record.get("threat",{})
	var out:={"stage":stage,"live":live,"today":int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null else 0}
	if home in ["attacker","defender"]:
		var enemy:="defender" if home=="attacker" else "attacker"
		var ours:Dictionary=record.get(home,{})
		var theirs:Dictionary=record.get(enemy,{})
		var general_full:=String((ours.get("commander",{}) as Dictionary).get("name",""))
		var first:=Account._first_name(general_full)
		var troops:=int(ours.get("initial_troops",record.get(home+"_initial",ours.get("troops",0))))
		var noun:=Marks.noun(maxi(1,troops),stage)
		var people:=String(threat.get("source_name",""))
		out["left_name"]=("%s's %s" % [first,noun]) if first!="" else "our "+noun
		out["right_name"]=("the "+people) if people!="" and not people.begins_with("UNIDENTIFIED") else "the strangers"
		out["left_general"]=general_full
		out["left_general_first"]=first
		out["right_general"]=String((theirs.get("commander",{}) as Dictionary).get("name",""))
		if not live and record.has("termination") and not bool(record.get("observed",false)):
			var account:=Account.build(record,Account.gather(record))
			out["where"]=String(account.get("where",""))
			out["headline"]=String(account.get("headline",""))
			out["left_name"]=String(account.get("band",out.left_name))
		else:
			out["where"]=String(record.get("where","")) if String(record.get("where",""))!="" else _where(record)
	else:
		out["left_name"]=String(record.get("attacker_people",(record.get("attacker",{}) as Dictionary).get("name","the attackers")))
		out["right_name"]=String(record.get("defender_people",(record.get("defender",{}) as Dictionary).get("name","the defenders")))
		out["left_general"]=String(((record.get("attacker",{}) as Dictionary).get("commander",{}) as Dictionary).get("name",""))
		out["right_general"]=String(((record.get("defender",{}) as Dictionary).get("commander",{}) as Dictionary).get("name",""))
		out["where"]=String(record.get("where",_where(record)))
		out["headline"]=String(record.get("headline",""))
	out["place"]=_place(record)
	# No town to name it by: say where by its ground (a ford, a pass, the gate).
	var ground:Variant=record.get("ground",(record.get("battle",{}) as Dictionary).get("ground",{}) if record.get("battle") is Dictionary else {})
	var kind:=String((ground as Dictionary).get("kind","open")) if ground is Dictionary else "open"
	if String(out.get("where",""))=="in the open country" and kind!="open":
		out["where"]=Record.ground_place(kind)
		out["headline"]=String(out.get("headline","")).replace("in the open country",Record.ground_place(kind))
	return out


# --- Helpers ---------------------------------------------------------------------------

static func _military()->Node:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null: return null
	return tree.root.get_node_or_null("MilitaryCampaign")


static func _involves(engagement:Dictionary,army_id:int)->bool:
	if int(engagement.get("home_force_id",-1))==army_id: return true
	for member in engagement.get("command_participants",[]):
		if int((member as Dictionary).get("army_id",-1))==army_id: return true
	return false


static func _position(engagement:Dictionary)->Vector2:
	var threat:Dictionary=engagement.get("threat",{})
	var target:Variant=threat.get("target_position",{})
	if target is Dictionary and (target as Dictionary).has_all(["x","z"]): return Vector2(float(target.x),float(target.z))
	var mc:Node=_military()
	var army_id:=int(engagement.get("home_force_id",0))
	if mc!=null and army_id>0:
		var index:int=mc._field_army_index(army_id)
		if index>=0:
			var p:Variant=mc.field_armies[index].get("position",{})
			if p is Dictionary and (p as Dictionary).has_all(["x","z"]): return Vector2(float(p.x),float(p.z))
	if WorldSimulation!=null and WorldSimulation.world!=null:
		var origin:Variant=WorldSimulation.world.get("player_world_origin")
		if origin is Vector2: return origin
	return Vector2.ZERO


static func _place(record:Dictionary)->String:
	var threat:Dictionary=record.get("threat",{})
	var name:=Account._place_name(String(record.get("target_region_name",threat.get("target_region_name",""))))
	if name!="": return name
	if WorldSimulation!=null and WorldSimulation.world!=null: name=Account._nearest_town(threat.get("target_position",{}))
	return name


static func _where(record:Dictionary)->String:
	var threat:Dictionary=record.get("threat",{})
	var town:=Account._place_name(String(record.get("target_region_name",threat.get("target_region_name",""))))
	var home:=String(record.get("home_side",""))
	if town!="" and not bool(threat.get("field_encounter",false)): return ("at " if home=="defender" else "before ")+town
	# Our own settlement, defended at its edge.
	if home=="defender" and town=="" and not bool(threat.get("field_encounter",false)) and String(record.get("home_force_kind","field"))=="field" and WorldSimulation!=null:
		var name:=String(WorldSimulation.state.settlement_name)
		if name!="": return "at "+name
	var near:=_place(record)
	return ("near "+near) if near!="" else "in the open country"
