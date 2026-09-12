extends RefCounted
## Co-located reorganization only; no travel, recruits or equipment are created.
const D=preload("res://scripts/combined_arms_doctrine.gd")
static func available(host:Node,army_id:int)->Dictionary:
	if not host.active_engagement.is_empty() or not host.pending_aftermath.is_empty() or host.command_hierarchy.battle.engaged(0):return {"error":"Finish battle commitments before reorganizing troops."}
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed or host.recovery.home_unavailable():return {"error":"Reinforcements need an available settled home."}
	var index:=int(host._field_army_index(army_id))
	if index<0:return {"error":"Select an existing field army."}
	var army:Dictionary=host.field_armies[index]
	if host.command_hierarchy.battle.engaged(army_id) or bool(army.get("embarked",false)) or String(army.get("status",""))!="stationed" or String(army.get("location_id",""))!="player_home":return {"error":"The army must be stationed at home and free of battle or transport commitments."}
	return {"index":index}
static func transfer(host:Node,army_id:int,unit:String,count:int)->Dictionary:
	var access:=available(host,army_id)
	if access.has("error"):return access
	if count<=0 or not host.UnitCatalog.ARCHETYPES.has(unit):return {"error":"Choose a valid unit and positive reinforcement count."}
	var present:=0
	for formation:Dictionary in host.home_army.get("formations",[]):
		if String(formation.get("unit",""))==unit:present+=maxi(0,int(formation.get("count",0)))
	if count>present:return {"error":"Not enough trained personnel of that unit are at home."}
	var detached:Array=host._detach_occupation_formations(count,unit)
	var army:Dictionary=host.field_armies[int(access.index)]
	var next_id:=int(host.next_formation_id)
	for formation:Dictionary in army.formations:next_id=maxi(next_id,int(formation.get("id",0))+1)
	for formation:Dictionary in detached:
		formation.id=next_id;next_id+=1;army.formations.append(formation)
	host.next_formation_id=next_id
	var rebuilt:Dictionary=host.simulator.create_formation_force(String(army.name),army.formations,float(army.get("morale",1)),float(army.get("readiness",1)))
	for key:String in ["troops","attack","defense","armor","penetration","formations"]:army[key]=rebuilt[key]
	host._rebuild_home_army_with([])
	army["last_report"]=host._army_report_snapshot(army)
	host.army_changed.emit(host.home_army.duplicate(true))
	return {"ok":true,"transferred":count,"army_id":army_id,"unit":unit,"message":"Trained personnel and their issued equipment joined the army at home."}
static func recommendation(host:Node)->Dictionary:
	var levels:=D.levels()
	for army:Dictionary in host.field_armies:
		if available(host,int(army.army_id)).has("error"):continue
		for id:String in levels:
			if float(levels[id])<.25:continue
			var rule:Dictionary=D.RULES[id];var targets:=0;var support:=0
			for formation:Dictionary in army.formations:
				if formation.get("unit","") in rule.targets:targets+=maxi(0,int(formation.count))
				if formation.get("unit","") in rule.support:support+=maxi(0,int(formation.count))
			var gap:=ceili(targets*D.SUPPORT_PER_TARGET)-support
			if gap<=0:continue
			for formation:Dictionary in host.home_army.get("formations",[]):
				if formation.get("unit","") not in rule.support or D.capacity(formation)<=0:continue
				return {"kind":"army_reinforce_home","army":int(army.army_id),"unit":String(formation.unit),"count":mini(gap,int(formation.count))}
	return {}
