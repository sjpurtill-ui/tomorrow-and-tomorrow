extends RefCounted
## Nearby subcommands fight together; losses return to their original formations.
var host:Node
func _init(campaign:Node)->void:host=campaign
func participants(lead:Dictionary,candidates:Array,target:Vector2)->Array:
	var result:Array=[lead]
	var terrain=host.command_hierarchy.land
	for actual:Dictionary in candidates:
		if int(actual.get("army_id",0))==int(lead.get("army_id",0)) or int(actual.get("troops",0))<=0 or bool(actual.get("embarked",false)) or engaged(int(actual.get("army_id",0))):continue
		if terrain.point(actual).distance_to(target)>host.MAP_ENGAGEMENT_RANGE_KM:continue
		if host.field_route_availability(terrain.point(actual),target).has("error"):continue
		result.append(actual)
	return result
func attach(engagement:Dictionary,candidates:Array)->void:
	if candidates.size()<2:return
	var side:String=host._engagement_home_side(engagement)
	var original:Dictionary=engagement[side]
	var forms:Array=[];var records:Array=[];var supply:=0.0;var morale:=0.0;var readiness:=0.0;var total:=0
	for actual:Dictionary in candidates:
		var count:=int(actual.troops)
		var entry:={"army_id":int(actual.army_id),"offset":forms.size(),"length":actual.formations.size(),"initial":count}
		for key:String in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","dead"]:entry[key]=int(actual.get(key,0))
		records.append(entry);forms.append_array(actual.formations)
		supply+=float(actual.get("supply_level",1))*count;morale+=float(actual.get("morale",.7))*count;readiness+=float(actual.get("readiness",.5))*count;total+=count
	var combined:Dictionary=host.simulator.create_formation_force(String(original.name),forms,morale/maxi(1,total),readiness/maxi(1,total))
	combined["commander"]=original.get("commander",{}).duplicate(true);combined["supply_level"]=supply/maxi(1,total)
	for key:String in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","dead"]:
		combined[key]=0
		for entry:Dictionary in records:combined[key]+=int(entry[key])
	engagement[side]=combined;engagement[side+"_initial"]=total;engagement["command_participants"]=records
func engaged(army_id:int)->bool:
	var assigned:int=host._field_army_index(army_id)
	if assigned>=0 and bool(host.field_armies[assigned].get("relief_assignment",false)):return true
	if WorldSimulation.enabled and preload("res://scripts/civilization_combat.gd").reserved({"actor":WorldSimulation.actor_id,"field_id":army_id},false):return true
	var engagements:Array=host.command_hierarchy.data.get("battles",[]).duplicate()
	if not host.active_engagement.is_empty():engagements.append(host.active_engagement)
	for engagement:Dictionary in engagements:
		if int(engagement.get("home_force_id",0))==army_id:return true
		for entry:Dictionary in engagement.get("command_participants",[]):
			if int(entry.army_id)==army_id:return true
	return false
func allocate(total:int,weights:Array)->Array:
	var result:Array=[];var sum:=0
	for weight in weights:sum+=maxi(0,int(weight));result.append(0)
	total=clampi(total,0,sum)
	var left:=total
	for index in weights.size():
		result[index]=floori(float(total)*int(weights[index])/maxi(1,sum));left-=int(result[index])
	for index in weights.size():
		if left<=0:break
		if int(result[index])<int(weights[index]):result[index]+=1;left-=1
	return result
func commit(result:Dictionary)->void:
	var side:String=result.home_side;var final:Dictionary=result[side];var entries:Array=result.command_participants
	var member_rounds:Array=[];var totals:Array=[]
	for entry:Dictionary in entries:
		member_rounds.append([]);totals.append({"killed":0,"wounded":0,"scattered":0,"disabled":0,"severe_disability":0})
	for round_data:Dictionary in result.rounds:
		var weights:Array=[];var cohort:Array=round_data.get(side+"_cohort_losses",[])
		for entry:Dictionary in entries:
			var weight:=0
			for index in range(int(entry.offset),mini(cohort.size(),int(entry.offset)+int(entry.length))):weight+=int(cohort[index])
			weights.append(weight)
		var breakdown:Dictionary=round_data.get(side+"_casualties",{})
		var killed:=allocate(int(breakdown.get("killed",0)),weights)
		for index in weights.size():weights[index]-=killed[index]
		var wounded:=allocate(int(breakdown.get("wounded",0)),weights)
		for index in weights.size():weights[index]-=wounded[index]
		var scattered:=allocate(int(breakdown.get("scattered",0)),weights)
		var disabled:=allocate(int(breakdown.get("disabled",0)),wounded)
		var severe:=allocate(int(breakdown.get("severe_disability",0)),disabled)
		for index in entries.size():
			var entry:Dictionary=entries[index];var local_round:=round_data.duplicate(true)
			var losses:={"killed":killed[index],"wounded":wounded[index],"scattered":scattered[index],"disabled":disabled[index],"severe_disability":severe[index]}
			local_round[side+"_casualties"]=losses
			for key:String in ["_cohort_losses","_cohort_equipment_losses","_cohort_ammunition_used"]:local_round[side+key]=(round_data.get(side+key,[]) as Array).slice(int(entry.offset),int(entry.offset)+int(entry.length))
			member_rounds[index].append(local_round)
			for key:String in losses:totals[index][key]+=int(losses[key])
	for index in entries.size():
		var entry:Dictionary=entries[index];var local:Dictionary=final.duplicate(true)
		local.formations=final.formations.slice(int(entry.offset),int(entry.offset)+int(entry.length));local.remaining_troops=0
		for formation:Dictionary in local.formations:local.remaining_troops+=int(formation.count)
		for pair:Array in [["wounded_pool","wounded"],["disabled_pool","disabled"],["severe_disabled_pool","severe_disability"],["scattered_pool","scattered"],["dead","killed"]]:local[pair[0]]=int(entry[pair[0]])+int(totals[index][pair[1]])
		host._apply_field_army_result(int(entry.army_id),local,member_rounds[index],int(result.seed),side)
		var force_index:int=host._field_army_index(int(entry.army_id))
		if force_index>=0:host.field_armies[force_index]["last_report"]=host._army_report_snapshot(host.field_armies[force_index])
func capture_survivors(result:Dictionary,count:int)->void:
	var forces:Array=[];var weights:Array=[]
	for entry:Dictionary in result.command_participants:
		var index:int=host._field_army_index(int(entry.army_id))
		if index>=0:forces.append(host.field_armies[index]);weights.append(int(host.field_armies[index].troops))
	var shares:=allocate(count,weights)
	for index in forces.size():host._mark_engaged_force_prisoners("field_army",int(forces[index].army_id),"","",int(shares[index]))
func reinforce_occupation(civ_id:String,region_id:String,participants:Array,desired:float=-1)->void:
	var index:int=host._occupation_force_index(civ_id,region_id)
	if index<0:return
	var occupation:Dictionary=host.occupation_forces[index]
	var target:=ceili((float(occupation.required) if desired<0 else desired)/maxf(.05,float(occupation.supply_level)*(.5+.5*float(occupation.readiness))))
	for member:Dictionary in participants:
		var remaining:=maxi(0,target-int(occupation.troops))
		if remaining<=0:break
		var forms:Array=host._detach_field_army_formations(int(member.army_id),remaining)
		occupation.formations.append_array(forms)
		for formation:Dictionary in forms:occupation.troops+=int(formation.count)
func siege_members()->Array:
	var result:Array=[];var siege:Dictionary=host.active_siege
	if siege.is_empty():return result
	for id in siege.get("command_members",[int(siege.get("army_id",0))]):
		var index:int=host._field_army_index(int(id))
		if index<0:continue
		var actual:Dictionary=host.field_armies[index]
		var position:Dictionary=siege.get("threat",{}).get("target_position",{})
		if not position.is_empty() and host.command_hierarchy.land.point(actual).distance_to(host.command_hierarchy.G.unpack(position))>host.MAP_ENGAGEMENT_RANGE_KM:continue
		if bool(actual.get("embarked",false)):continue
		result.append(actual)
	return result
func archive_active()->void:
	if host.active_engagement.is_empty() or not bool(host.active_engagement.get("commander_managed",false)):return
	host.command_hierarchy.data.battles.append(host.active_engagement.duplicate(true))
	host.active_engagement.clear()
func enemy_engaged(id:String)->bool:
	for engagement:Dictionary in host.command_hierarchy.data.get("battles",[]):
		if String(engagement.get("threat",{}).get("formation_id",""))==id:return true
	return false
func city_engaged(id:String)->bool:
	for engagement:Dictionary in host.command_hierarchy.data.get("battles",[]):
		if String(engagement.get("threat",{}).get("target_region_id",""))==id:return true
	return false
func advance_all()->void:
	var legacy:Dictionary=host.active_engagement
	var pending:Array=host.command_hierarchy.data.battles
	host.command_hierarchy.data.battles=[]
	for engagement:Dictionary in pending:
		host.active_engagement=engagement
		host.advance_engagement(host.command_hierarchy.land.battle_order())
		if not host.active_engagement.is_empty():host.command_hierarchy.data.battles.append(host.active_engagement.duplicate(true))
	host.active_engagement=legacy
static func validate(saved:Variant,forces:Array)->String:
	if not saved is Array or saved.size()>32:return "Invalid commander battle list."
	var available:Dictionary={};var committed:Dictionary={}
	for actual in forces:
		if actual is Dictionary:available[int(actual.get("army_id",0))]=actual
	for engagement in saved:
		if not engagement is Dictionary or engagement.get("commander_managed",false)!=true or engagement.get("home_side","") not in ["attacker","defender"] or engagement.get("home_force_kind","")!="field_army":return "Invalid commander battle."
		if not engagement.get("threat",null) is Dictionary or not engagement.get("rounds",null) is Array or engagement.rounds.size()>256:return "Invalid battle history."
		for key:String in ["round","seed","home_force_id","attacker_initial","defender_initial"]:
			if not whole(engagement.get(key,null)):return "Invalid battle counter."
		if int(engagement.round)!=engagement.rounds.size() or not is_finite(float(engagement.get("terrain_defense",NAN))):return "Invalid battle progress."
		for side:String in ["attacker","defender"]:
			var force:Variant=engagement.get(side,null)
			if not force is Dictionary or not force.get("formations",null) is Array or force.formations.size()>1024 or not whole(force.get("troops",null)):return "Invalid combat force."
			var total:=0
			for formation in force.formations:
				if not formation is Dictionary or not whole(formation.get("count",null)):return "Invalid combat formation."
				total+=int(formation.count)
			if total!=int(force.troops):return "Combat strength does not match its formations."
			for key:String in ["morale","readiness","supply_level"]:
				if not is_finite(float(force.get(key,1))):return "Invalid battle condition."
		var members:Variant=engagement.get("command_participants",[])
		if not members is Array or members.size()>256:return "Invalid battle participants."
		var identifiers:Array=[];var offset:=0
		for member in members:
			if not member is Dictionary:return "Invalid battle participant."
			for key:String in ["army_id","offset","length","initial","wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","dead"]:
				if not whole(member.get(key,null)):return "Invalid participant accounting."
			if int(member.offset)!=offset:return "Overlapping battle formations."
			offset+=int(member.length);identifiers.append(int(member.army_id))
		if not members.is_empty() and offset!=engagement[engagement.home_side].formations.size():return "Incomplete participant accounting."
		if members.is_empty():identifiers.append(int(engagement.home_force_id))
		if int(engagement.home_force_id) not in identifiers:return "Missing battle commander."
		for id:int in identifiers:
			if not available.has(id) or committed.has(id):return "A missing or already engaged force appears in battle."
			committed[id]=true
	return ""
static func whole(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and floorf(float(value))==float(value)
