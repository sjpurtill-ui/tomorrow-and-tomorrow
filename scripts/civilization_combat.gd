extends RefCounted
## Contact views resolve back to the actual owner. Both sides commit the same
## battle result through MilitaryCampaign, including injuries, gear and captives.
static func owner(id:String)->String:return "player" if id=="human" else id

static func force_for(incident:Dictionary)->Dictionary:
	var id:=owner(String(incident.get("source_civ_id","")))
	if id!="player" and not WorldSimulation.actors.has(id):return {}
	var field_id:=int(incident.get("owned_force_id",0))
	var formation_id:=String(incident.get("formation_id",""))
	if formation_id.contains(":army:"):field_id=int(formation_id.get_slice(":army:",1))
	var city_id:=String(incident.get("target_region_id",""))
	var local_id:=""
	if city_id!="":
		var place:=WorldSimulation.world.region_snapshot(String(incident.source_civ_id),city_id)
		local_id=String(place.get("local_city_id",""))
	return WorldSimulation.scoped(id,func()->Dictionary:
		var force:Dictionary={}
		if field_id>0:
			var index:=WorldSimulation.military._field_army_index(field_id)
			if index>=0:force=WorldSimulation.military.field_armies[index].duplicate(true)
		elif local_id.is_empty() or bool(WorldSimulation.settlements.settlement_record(local_id).get("primary",false)):
			force=WorldSimulation.military._home_defense_force(false)
		if force.is_empty():force=WorldSimulation.military.simulator.create_formation_force(WorldSimulation.state.settlement_name+" defenders",[],.5,.1)
		force["owned_target"]={"actor":id,"field_id":field_id,"city_id":local_id}
		return force
	)

static func commit_enemy(result:Dictionary)->void:
	var target:Dictionary=result.get("threat",{}).get("owned_target",{})
	if target.is_empty():return
	var id:=String(target.actor)
	var mirrored:=result.duplicate(true)
	mirrored.home_side="defender" if String(result.get("home_side","attacker"))=="attacker" else "attacker"
	mirrored.home_force_id=int(target.field_id)
	mirrored.home_force_kind="field_army" if int(target.field_id)>0 else "field"
	mirrored.command_participants=[]
	mirrored.commander_managed=id!="player"
	WorldSimulation.scoped(id,func()->void:WorldSimulation.military._commit_campaign_battle(mirrored))

static func troop_catalog()->Dictionary:
	var catalog:Dictionary={}
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	for id:String in ids:
		var result:Array[Dictionary]=[]
		var visible_id:="human" if id=="player" else id
		WorldSimulation.scoped(id,func()->void:
			var day:=int(WorldSimulation.state.elapsed_days)
			for mission:Dictionary in WorldSimulation.world.scout_missions:
				var start:=int(mission.get("start_day",day));var finish:=int(mission.get("actual_return_day",mission.get("return_day",day+1)))
				var point:Vector2=WorldSimulation.world.city_intelligence.mission_position(mission,day)
				var scouting:Dictionary={"id":"%s:scout:%d" % [visible_id,int(mission.mission_id)],"civ_id":visible_id,"kind":"scout","point_a":WorldSimulation.world.player_world_origin,"point_b":point,"command_position":{"x":point.x,"z":point.y},"depart_day":start,"leg_days":maxf(1,float(finish-start)*.5),"strength_share":float(mission.personnel)/maxf(1,WorldSimulation.state.population_exact),"readiness":.5,"actual_troops":int(mission.personnel),"owned_mission":int(mission.mission_id),"route":mission.get("route",[]).duplicate(true),"concealment":.7,"evasion":.8,"last_report_cycle":0,"disabled_until_day":0,"evaded_until_day":int(mission.get("evaded_until_day",0)),"last_interception_day":int(mission.get("last_interception_day",-9999)),"search_sequence":0}
				result.append(scouting)
			for force in WorldSimulation.military.field_armies:
				if int(force.get("troops",0))<=0:continue
				var point:Vector2=WorldSimulation.military.command_hierarchy.land.point(force)
				result.append({"id":"%s:army:%d" % [visible_id,int(force.army_id)],"civ_id":visible_id,"kind":"expedition","point_a":point,"point_b":point,"command_position":{"x":point.x,"z":point.y},"depart_day":0,"leg_days":1.0,"strength_share":float(force.troops)/maxf(1,WorldSimulation.military._mobilized_count()),"readiness":float(force.get("readiness",0)),"actual_troops":int(force.troops),"owned_force_id":int(force.army_id)})
		)
		catalog[id]=result
	return catalog

static func troop_views(observer:String,catalog:Dictionary={})->Array[Dictionary]:
	var current:=troop_catalog() if catalog.is_empty() else catalog
	var result:Array[Dictionary]=[]
	for id:String in current:
		if id==observer:continue
		for entry:Dictionary in current[id]:result.append(entry.duplicate(true))
	return result

static func civilian_deaths(civ:Dictionary,region_id:String,requested:int)->Dictionary:
	var id:=owner(String(civ.id));var local_id:=""
	for region:Dictionary in civ.strategic_regions:
		if String(region.id)==region_id:local_id=String(region.get("local_city_id",""));break
	if local_id.is_empty():return {"civilization":civ,"dead":0}
	var count:int=WorldSimulation.scoped(id,func()->int:
		return WorldSimulation.settlements.with_city_resources(local_id,func()->int:
			return WorldSimulation.settlements.with_local_population(func()->int:return int(WorldSimulation.state.register_population_deaths(requested,"Civilian deaths in war").get("count",0)),true)
		)
	)
	return {"civilization":civ,"dead":count}

static func local_city(civ_id:String,region_id:String)->String:
	var region:=WorldSimulation.world.region_snapshot(civ_id,region_id)
	return String(region.get("local_city_id",region_id))
static func capture(civ:Dictionary,region_id:String,force:Dictionary)->Dictionary:
	var attacker:=WorldSimulation.actor_id
	var target:=owner(String(civ.id))
	var city_id:=local_city(String(civ.id),region_id)
	var occupying_id:="human" if attacker=="player" else attacker
	var result:Dictionary=WorldSimulation.scoped(target,func()->Dictionary:
		return WorldSimulation.military.recovery.capture_city(city_id,occupying_id,force)
	)
	var region:=WorldSimulation.world.region_snapshot(String(civ.id),region_id).duplicate(true)
	if result.has("error"):return {"civilization":civ,"outcome":{"region_captured":false,"message":result.error}}
	region.controller="player"
	return {"civilization":civ,"outcome":{"region_captured":true,"occupation_required":float(result.get("occupation_required",0)),"region":region,"territory_transferred":0.0,"message":result.get("message","The city is occupied.")}}
static func restore(civ:Dictionary,region_id:String)->Dictionary:
	var city_id:=local_city(String(civ.id),region_id)
	WorldSimulation.scoped(owner(String(civ.id)),func()->void:
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		city.occupied_by=""
		for entry:Dictionary in WorldSimulation.military.recovery.data.occupied:
			if String(entry.city_id)==city_id:entry.liberated=true
	)
	var region:=WorldSimulation.world.region_snapshot(String(civ.id),region_id).duplicate(true);region.controller=civ.id
	return {"civilization":civ,"outcome":{"region_recaptured":true,"region":region,"territory_transferred":0.0,"message":"The city is free of occupation."}}
static func same_force(a:Dictionary,b:Dictionary)->bool:
	if a.is_empty() or b.is_empty():return false
	if String(a.get("actor",""))!=String(b.get("actor","")) or int(a.get("field_id",0))!=int(b.get("field_id",0)):return false
	return int(a.get("field_id",0))>0 or String(a.get("city_id","")).is_empty() or String(b.get("city_id","")).is_empty() or a.city_id==b.city_id
static func reserved(target:Dictionary,include_sieges:bool=true)->bool:
	if target.is_empty():return false
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		var occupied:bool=WorldSimulation.scoped(id,func()->bool:
			var operations:Array=WorldSimulation.military.command_hierarchy.data.get("battles",[]).duplicate()
			if not WorldSimulation.military.active_engagement.is_empty():operations.append(WorldSimulation.military.active_engagement)
			if include_sieges and not WorldSimulation.military.active_siege.is_empty():operations.append(WorldSimulation.military.active_siege)
			for operation:Dictionary in operations:
				if same_force(operation.get("threat",{}).get("owned_target",{}),target):return true
				if same_force({"actor":id,"field_id":int(operation.get("home_force_id",operation.get("army_id",0)))},target):return true
				for member:Dictionary in operation.get("command_participants",[]):
					if same_force({"actor":id,"field_id":int(member.army_id)},target):return true
			return false
		)
		if occupied:return true
	return false
static func damage_city(civ_id:String,region_id:String,amount:float)->void:
	var target:=WorldSimulation.actor_id if civ_id=="player" else owner(civ_id)
	var city_id:=region_id if civ_id=="player" else local_city(civ_id,region_id)
	WorldSimulation.scoped(target,func()->void:
		WorldSimulation.settlements.with_city_resources(city_id,func()->void:
			for plot:Dictionary in WorldSimulation.state.settlement_plots:
				if String(plot.get("land_use","")) in ["workshop","mixed_household","storehouse"]:plot.condition=maxf(.05,float(plot.get("condition",1))-amount)
			WorldSimulation.state.morphology_revision+=1
		)
		for base:Dictionary in WorldSimulation.military.joint_operations.state.bases:
			if String(base.city_id)==city_id:base.condition=maxf(0,float(base.condition)-amount)
	)

static func intercept_scout(formation:Dictionary,action:String,success:bool,day:int)->void:
	var captor:=WorldSimulation.actor_id
	WorldSimulation.scoped(owner(String(formation.civ_id)),func()->void:
		for mission:Dictionary in WorldSimulation.world.scout_missions:
			if int(mission.mission_id)!=int(formation.owned_mission):continue
			mission.last_interception_day=day
			if not success:mission.evaded_until_day=day+7;return
			WorldSimulation.world._fail_player_scout_mission(mission,{"civ_id":"human" if captor=="player" else captor,"fate":"captured" if action=="capture" else "destroyed"},day)
			return
	)
static func governance(civ_id:String,region_id:String,region:Dictionary)->void:
	var city_id:=local_city(civ_id,region_id)
	WorldSimulation.scoped(owner(civ_id),func()->void:
		for entry:Dictionary in WorldSimulation.military.recovery.data.occupied:
			if String(entry.city_id)==city_id:
				for key in ["governance","damage","resistance","integration"]:
					if region.has(key):entry.region[key]=region[key]
	)

static func displace(civ_id:String,city_id:String,requested:int)->int:
	var owner_id:=WorldSimulation.actor_id if civ_id=="player" else owner(civ_id)
	return WorldSimulation.scoped(owner_id,func()->int:
		var source:=WorldSimulation.settlements.settlement_record(city_id)
		if source.is_empty():return 0
		var destinations:Array=[]
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if String(city.id)!=city_id and String(city.get("occupied_by","")).is_empty():destinations.append(city)
		if destinations.is_empty():return 0
		var amount:=mini(maxi(0,requested),floori(WorldSimulation.settlements._settlement_population(source)*.35))
		var share:=float(amount)/maxf(1,WorldSimulation.state.population_exact)
		if not bool(source.get("primary",false)):source.population_share=maxf(0,float(source.population_share)-share)
		for city:Dictionary in destinations:
			if not bool(city.get("primary",false)):city.population_share=float(city.population_share)+share/destinations.size()
		WorldSimulation.state.simulation_metrics["displaced_population"]=float(WorldSimulation.state.simulation_metrics.get("displaced_population",0))+amount
		WorldSimulation.state.settlement_network_revision+=1
		return amount
	)

static func occupation_presence(occupier:String,city_id:String)->Dictionary:
	var resident:=WorldSimulation.actor_id
	return WorldSimulation.scoped(owner(occupier),func()->Dictionary:
		for force:Dictionary in WorldSimulation.military.occupation_forces:
			if owner(String(force.get("civ_id","")))!=resident:continue
			var region:=WorldSimulation.world.region_snapshot(String(force.civ_id),String(force.region_id))
			if String(region.get("local_city_id",""))!=city_id:continue
			var supply:=float(force.get("supply_level",0))
			var effective:=float(force.get("troops",0))*supply*(.5+.5*float(force.get("readiness",0)))
			return {"control":clampf(effective/maxf(1,float(force.get("required",1))),0,1),"logistics":supply}
		return {"control":0.0,"logistics":0.0}
	)
