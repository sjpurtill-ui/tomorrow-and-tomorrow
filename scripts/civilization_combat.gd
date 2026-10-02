extends RefCounted
## Contact views resolve back to the actual owner. Both sides commit the same
## battle result through MilitaryCampaign, including injuries, gear and captives.
## Every town has its guards: home its levy and watch, a band its men, and any
## other town its own watch (town_watch), whose losses are that town's own.
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
		else:
			force=town_watch(local_id)
		if force.is_empty():force=WorldSimulation.military.simulator.create_formation_force(WorldSimulation.state.settlement_name+" defenders",[],.5,.1)
		force["owned_target"]={"actor":id,"field_id":field_id,"city_id":local_id}
		return force
	)

## A town's own watch: its share of the watch (watch_ledger), with whatever
## comes to hand. {} when the town keeps none. Run in the town's owner's scope.
static func town_watch(city_id:String)->Dictionary:
	var mc:Variant=WorldSimulation.military
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	var watch:=watch_count(city_id)
	if watch<=0: return {}
	var formation:={"id":-1,"unit":"levy","weapon":"improvised","count":watch,"authorized_count":watch,"equipment":0,"equipment_required":watch,"ammunition":0,"ammunition_required":0,
		"training":0.20,"experience":0.0,"personnel_condition":float(mc._trainee_condition()),"emergency_militia":true}
	var force:Dictionary=mc.simulator.create_formation_force("%s watch" % String(city.get("name","the town")),[formation],float(mc._campaign_morale()),0.18)
	force["commander"]=mc.simulator.create_commander("TOWN WATCH",0.35,0.35,0.35,0.45)
	force["supply_level"]=1.0
	force["town_watch"]=city_id
	return force

## THE WATCH LEDGER, one for every people. Those set to Defense work (D,
## MilitaryCampaign._home_garrison_target) who are not already the trained
## levy at home (T, home_army.troops, as _home_defense_force has always
## netted them) keep the watch: W = max(0, D - T). Each of them keeps it in
## the town they live in: W is shared out by people among the towns that
## keep a watch (lived in, and not held by another people), home included,
## in whole people that add up to W exactly (largest remainder). So home is
## defended by T and its share, every other town by its share, and all the
## towns together by max(T, D): no one stands in two places. Before any town
## is founded the whole watch is at home. {city_id: watch} for every town of
## the owner (0 where none). One pass over the towns; run in the owner's
## scope, outside any one town's. `mc` is the owner's MilitaryCampaign.
static func watch_ledger(mc:Variant=null)->Dictionary:
	if mc==null:mc=WorldSimulation.military
	var out:={}
	if mc==null:return out
	var watch:=maxi(0,int(mc._home_garrison_target())-maxi(0,int(mc.home_army.get("troops",0))))
	var people:={}
	var total:=0.0
	for city:Dictionary in WorldSimulation.state.player_settlements:
		var id:=String(city.get("id",""))
		out[id]=0
		if not keeps_watch(city):continue
		var here:=maxf(0.0,float(WorldSimulation.settlements._settlement_population(city)))
		if here<=0.0:continue
		people[id]=here;total+=here
	if watch<=0 or total<=0.0:return out
	var given:=0
	var rest:Array=[]
	for id:String in people:
		var exact:=float(watch)*float(people[id])/total
		var whole:=mini(floori(exact),floori(float(people[id])))
		out[id]=whole;given+=whole
		rest.append([exact-float(whole),id])
	rest.sort_custom(func(a:Array,b:Array)->bool:return float(a[0])>float(b[0]) if float(a[0])!=float(b[0]) else String(a[1])<String(b[1]))
	var left:=watch-given
	for pair:Array in rest:
		if left<=0:break
		var id:=String(pair[1])
		if int(out[id])+1>floori(float(people[id])):continue
		out[id]=int(out[id])+1;left-=1
	return out

## Whether a town keeps a watch of ours: lived in (dry_towns.gd) and not held
## by another people (siege_recovery capture, a town taken).
static func keeps_watch(city:Dictionary)->bool:
	return not city.is_empty() and String(city.get("occupied_by","")).is_empty() and not WorldSimulation.settlements.abandoned(city)

## Home's own share of the watch (watch_ledger): the untrained neighbours
## who stand with the levy when home is attacked (_home_defense_force).
static func home_watch(mc:Variant=null)->int:
	if mc==null:mc=WorldSimulation.military
	if mc==null:return 0
	var home:=_home_record()
	if home.is_empty():return maxi(0,int(mc._home_garrison_target())-maxi(0,int(mc.home_army.get("troops",0))))
	return int(watch_ledger(mc).get(String(home.get("id","")),0))

static func _home_record()->Dictionary:
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)):return city
	return {}

## How many stand in a town's own watch (town_watch): its share of the watch
## (watch_ledger). The one count of a town's guard: its battles, its page,
## its map badge and what a scout sees all read it. Home stands with its
## trained levy as well (defenders). 0 for no town. Run in the town's
## owner's scope, outside any one town's.
static func watch_count(city_id:String)->int:
	return int(watch_ledger().get(city_id,0))

## watch_count for a town's record already in hand.
static func watch_of(city:Dictionary)->int:
	return 0 if city.is_empty() else watch_count(String(city.get("id","")))

## Who stands at home when it is attacked, as _home_defense_force musters
## them: the trained levy, and home's share of the watch. {trained, watch}.
## Run in the owner's scope.
static func home_defenders()->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null:return {"trained":0,"watch":0}
	return {"trained":maxi(0,int(mc.home_army.get("troops",0))),"watch":home_watch(mc)}

## How many of the owner's people defend one of its towns if it is attacked
## now, as force_for musters them: at home the levy and its share of the
## watch, anywhere else the town's share. 0 for a town another people holds
## (home included: siege_recovery capture) and for a place that is not the
## owner's. The count a town's page, badge and drawing show, and a scout's.
static func defenders(city_id:String)->int:
	return defenders_of(WorldSimulation.settlements.settlement_record(city_id))

## defenders for a town's record already in hand.
static func defenders_of(city:Dictionary)->int:
	if city.is_empty():return 0
	return int(defenders_by_town().get(String(city.get("id","")),0))

## defenders for every town of the owner, by id, from one reading of the
## watch ledger.
static func defenders_by_town()->Dictionary:
	var mc:Variant=WorldSimulation.military
	var out:=watch_ledger(mc)
	if mc==null:return out
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if not bool(city.get("primary",false)):continue
		var id:=String(city.get("id",""))
		if String(city.get("occupied_by","")).is_empty():out[id]=int(out.get(id,0))+maxi(0,int(mc.home_army.get("troops",0)))
		else:out[id]=0
	return out

static func commit_enemy(result:Dictionary)->void:
	var target:Dictionary=result.get("threat",{}).get("owned_target",{})
	if target.is_empty():return
	var id:=String(target.actor)
	var mirrored:=result.duplicate(true)
	mirrored.home_side="defender" if String(result.get("home_side","attacker"))=="attacker" else "attacker"
	mirrored.home_force_id=int(target.field_id)
	mirrored.home_force_kind="field_army" if int(target.field_id)>0 else "field"
	# A town's own watch fought: its losses are that town's (not home's levy).
	var town_id:=String(target.get("city_id",""))
	if int(target.field_id)<=0 and town_id!="" and bool(WorldSimulation.scoped(id,func()->bool:return not WorldSimulation.settlements.settlement_record(town_id).is_empty() and not bool(WorldSimulation.settlements.settlement_record(town_id).get("primary",false)))):
		mirrored.home_force_kind="town"
		mirrored["home_force_city_id"]=town_id
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
		# Our home is lost only if our ruler yields it, never by a fight
		# (MilitaryCampaign._home_after_defeat); another people's ruler yields
		# theirs when the victors could hold it (capture_city).
		if target=="player" and bool(WorldSimulation.settlements.settlement_record(city_id).get("primary",false)):
			return {"error":"They broke through, but our home is still ours: it is lost only if its ruler yields it.","surrender_only":true}
		return WorldSimulation.military.recovery.capture_city(city_id,occupying_id,force)
	)
	var region:=WorldSimulation.world.region_snapshot(String(civ.id),region_id).duplicate(true)
	if result.has("error"):return {"civilization":civ,"outcome":{"region_captured":false,"message":result.error}}
	region.controller="player"
	_set_controller(civ,region_id,"player")
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
	_set_controller(civ,region_id,String(civ.id))
	return {"civilization":civ,"outcome":{"region_recaptured":true,"region":region,"territory_transferred":0.0,"message":"The city is free of occupation."}}
## The world's own record of who holds the town changes the moment it falls,
## as the projection will say at the next day's sync: the field report that
## follows the battle, the map and the court must not see the old holder.
static func _set_controller(civ:Dictionary,region_id:String,controller:String)->void:
	for region:Dictionary in civ.get("strategic_regions",[]):
		if String(region.get("id",""))!=region_id:continue
		region["controller"]=controller
		region["last_control_change_day"]=int(WorldSimulation.state.elapsed_days)
		return
static func same_force(a:Dictionary,b:Dictionary)->bool:
	if a.is_empty() or b.is_empty():return false
	if String(a.get("actor",""))!=String(b.get("actor","")) or int(a.get("field_id",0))!=int(b.get("field_id",0)):return false
	return int(a.get("field_id",0))>0 or String(a.get("city_id","")).is_empty() or String(b.get("city_id","")).is_empty() or a.city_id==b.city_id
static func reserved(target:Dictionary,include_sieges:bool=true)->bool:
	if target.is_empty():return false
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		# Read each owner's campaign directly; entering its scope only to select
		# this instance cost two full scope rebinds per owner per query.
		var military:Node=MilitaryCampaign if id=="player" else WorldSimulation.actors[id].systems.MilitaryCampaign
		var operations:Array=military.engagements.values()
		if include_sieges and not military.active_siege.is_empty():operations.append(military.active_siege)
		for operation:Dictionary in operations:
			if same_force(operation.get("threat",{}).get("owned_target",{}),target):return true
			if same_force({"actor":id,"field_id":int(operation.get("home_force_id",operation.get("army_id",0)))},target):return true
			for member:Dictionary in operation.get("command_participants",[]):
				if same_force({"actor":id,"field_id":int(member.army_id)},target):return true
	return false
static func damage_city(civ_id:String,region_id:String,amount:float)->void:
	var target:=WorldSimulation.actor_id if civ_id=="player" else owner(civ_id)
	var city_id:=region_id if civ_id=="player" else local_city(civ_id,region_id)
	WorldSimulation.scoped(target,func()->void:
		WorldSimulation.settlements.with_city_resources(city_id,func()->void:
			for plot:Dictionary in WorldSimulation.state.settlement_plots:
				if String(plot.get("land_use","")) in ["workshop","mixed_household","storehouse"]:plot.condition=maxf(.05,float(plot.get("condition",1))-amount)
			WorldSimulation.state.morphology_revision+=1
			WorldSimulation.settlements.damage_city_form(amount)
			WorldSimulation.settlements.rebuild_summary()
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
			# Never into a place its people left (settlement_model.abandoned).
			if String(city.id)!=city_id and String(city.get("occupied_by","")).is_empty() and String(city.get("status",""))!="abandoned":destinations.append(city)
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
			# The one rule for holding a town (town_hold.gd).
			var Hold:=preload("res://scripts/town_hold.gd")
			var effective:=Hold.force_strength(force)
			return {"control":clampf(effective/maxf(1,float(force.get("required",1))),0,1),"logistics":Hold.fed(force)}
		return {"control":0.0,"logistics":0.0}
	)
