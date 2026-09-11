extends SceneTree
## Isolated AI-seat diagnostic using the actual ordered daily simulation.
## Synthetic river access is explicit; this is not a full-world campaign proof.
var simulation:Node
var daily:Script
var controller:Script
var target_days:=1095000
var wall_seconds:=25.0
var seed_value:=91420
var output_path:="/tmp/tt-history-pacing.json"
var profile_enabled:=false
var timings:Dictionary={}
var snapshots:Array=[]
var discoveries:Array=[]
func _initialize()->void:call_deferred("run")
func snapshot(day:int)->Dictionary:
	var state:Node=simulation.state
	return {"day":day,"year":float(day)/365.0,"population":state.population_total,"known":state.known_discoveries.size(),"knowledge_workers":state.population_allocations.get("Knowledge",0),"active_inquiries":state.active_investigations.size(),"food_security":state.food_security,"food_intake_ratio":state.simulation_metrics.get("food_intake_ratio",1),"food_eaten":state.simulation_metrics.get("food_eaten",0),"food_demand_breakdown":state.simulation_metrics.get("food_demand_breakdown",{}).duplicate(true),"army_provisions_required":state.simulation_metrics.get("army_provisions_required",0),"army_provisions_delivered":state.simulation_metrics.get("army_provisions_delivered",0),"army_provision_delivery_ratio":state.simulation_metrics.get("army_provision_delivery_ratio",1),"food_consumption":state.simulation_metrics.get("food_consumption",0),"food_days":state.simulation_metrics.get("food_days",0),"settled":state.settlement_site_committed,"completed_buildings":state.settlement_completed.size(),"resource_deposits":state.resource_deposits.size(),"material_stocks":{"Timber":state.resource_stockpiles.get("Timber",0),"Stone":state.resource_stockpiles.get("Stone",0),"Clay":state.resource_stockpiles.get("Clay",0),"Fiber Plants":state.resource_stockpiles.get("Fiber Plants",0)}}
func bottlenecks()->Dictionary:
	var material_states:Dictionary={}
	for deposit:Dictionary in simulation.state.resource_deposits:
		var name:=String(deposit.resource)
		if not material_states.has(name):material_states[name]=[]
		material_states[name].append({"stage":deposit.stage,"access":deposit.get("access",0),"route":deposit.get("route",0),"survey":deposit.get("survey",0),"blockers":deposit.get("blockers",[])})
	var questions:Array=[]
	var pathways:Script=load("res://scripts/knowledge_pathways.gd")
	for entry:Dictionary in simulation.discovery.technology_catalog:
		if entry.id in simulation.state.known_discoveries:continue
		if not pathways.ready(entry,int(simulation.state.elapsed_days)):continue
		var missing_materials:Array=[]
		for requirement:Dictionary in entry.get("resource_requirements",[]):
			if not simulation.discovery._resource_requirements_met([requirement]):missing_materials.append(requirement)
		questions.append({"id":entry.id,"domain":entry.dynamic,"subcategory":entry.subcategory,"score":simulation.discovery._candidate_score(entry),"progress":simulation.state.discovery_progress.get(entry.id,0),"eligible":simulation.discovery._discovery_is_eligible(entry,int(simulation.state.elapsed_days)),"missing_materials":missing_materials})
	return {"causally_ready_questions":questions,"material_states":material_states,"allocations":simulation.state.population_allocations.duplicate(),"research_allocations":simulation.state.research_allocations.duplicate(),"research_subcategory_allocations":simulation.state.research_subcategory_allocations.duplicate(true),"active_investigations":simulation.state.active_investigations.duplicate(),"controller_plan":controller.current_plan("pacing_reference"),"known_ids":simulation.state.known_discoveries.duplicate()}
func run()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument=="--profile":profile_enabled=true;timings={"enabled":true}
		elif argument.begins_with("--days="):target_days=clampi(argument.trim_prefix("--days=").to_int(),1,3650000)
		elif argument.begins_with("--wall-seconds="):wall_seconds=clampf(argument.trim_prefix("--wall-seconds=").to_float(),1,3600)
		elif argument.begins_with("--seed="):seed_value=argument.trim_prefix("--seed=").to_int()
		elif argument.begins_with("--out="):output_path=argument.trim_prefix("--out=")
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	simulation=root.get_node("WorldSimulation");simulation.clear()
	daily=load("res://scripts/civilization_day.gd");controller=load("res://scripts/civilization_controller.gd")
	var planet:Node=root.get_node("PlanetEnvironment")
	simulation.context_provider=func(point:Vector2)->Dictionary:
		var profile:Dictionary=planet.profile_at(point)
		var fields:Dictionary={}
		for resource:String in ["Timber","Stone","Fiber Plants"]:
			fields[resource]={"density":clampf(float(profile.get("resource_potentials",{}).get(resource,0)),0,1),"area_km2":9.0,"position":Vector3(point.x,0,point.y)}
		return {"environment_profile":profile,"surface_water_distance_km":.1,"surface_water_recognized":true,"surface_material_catchments":fields,"woodland_catchment":fields.Timber}
	simulation.water_provider=func(point:Vector3)->Vector3:return point+Vector3(.1,0,0)
	var actor:Dictionary=simulation.create_actor("pacing_reference",seed_value,Vector2.ZERO)
	simulation.enabled=true # Normal resource days initialize owned world geology.
	actor.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	var start:=Time.get_ticks_msec()
	var day:=0;var reason:="target reached";var catalog_count:=0
	simulation.scoped("pacing_reference",func()->void:snapshots.append(snapshot(0)))
	while day<target_days:
		if Time.get_ticks_msec()-start>=wall_seconds*1000:reason="wall-time budget reached";break
		day+=1
		var extinct:bool=simulation.scoped("pacing_reference",func()->bool:
			simulation.state.elapsed_days=day
			var stamp:=Time.get_ticks_usec() if profile_enabled else 0
			controller.choose_orders("pacing_reference")
			stamp=daily.record_timing(timings,"controller",stamp)
			var origin:Vector2=simulation.world.player_world_origin
			if simulation.state.settlement_site_committed:origin=Vector2(simulation.state.settlement_founded_at.x,simulation.state.settlement_founded_at.z)
			var context:Dictionary=daily.context(origin,simulation.state.convoy_traveling)
			stamp=daily.record_timing(timings,"context",stamp)
			var result:Dictionary=daily.advance(day,context,Callable(),timings)
			for event:Dictionary in result.discoveries:discoveries.append({"id":event.id,"day":day,"year":float(day)/365.0})
			if day==1 or day%365==0:snapshots.append(snapshot(day))
			return simulation.state.population_total<=1
		)
		if day%365==0:print(JSON.stringify({"progress":day,"year":float(day)/365.0,"snapshot":snapshots.back()}))
		if extinct:reason="population collapse";break
		if day%30==0:await process_frame
	var final:Dictionary=simulation.scoped("pacing_reference",func()->Dictionary:return snapshot(day))
	catalog_count=actor.systems.DiscoverySystem.technology_catalog.size()
	var elapsed:=float(Time.get_ticks_msec()-start)/1000.0
	var diagnostic:Dictionary=simulation.scoped("pacing_reference",func()->Dictionary:return bottlenecks())
	var report:={"schema":6,"timings":timings,"profiling_enabled":profile_enabled,"bottlenecks":diagnostic,"scenario":"isolated AI seat; seeded planet at origin; synthetic recognized river 0.1 km away; macro-profile surface catchments; world geology and matching hydrology record enabled; no foreign exchange","seed":seed_value,"target_days":target_days,"simulated_days":day,"stop_reason":reason,"wall_seconds":elapsed,"days_per_second":float(day)/maxf(.001,elapsed),"live_catalog":catalog_count,"target_reached":day==target_days,"full_campaign_verified":false,"initial":snapshots[0],"final":final,"annual_snapshots":snapshots,"discoveries":discoveries,"limitations":["One isolated seat, not a full world or a player campaign","Synthetic local water and land authority; surface densities come from macro resource potentials, not rendered catchment sampling","No foreign acquisition, war or dependency-recovery scenario","Controller and daily economic/demographic/research rules are live; no unlocks, refill or population rescue","Short or collapsed runs do not validate millennial pacing"]}
	var file:=FileAccess.open(output_path,FileAccess.WRITE)
	if file==null:push_error("Cannot write pacing diagnostic: "+output_path);quit(1);return
	file.store_string(JSON.stringify(report,"  "));file.close()
	print(JSON.stringify({"report":output_path,"final":final,"stop_reason":reason,"days_per_second":report.days_per_second,"full_campaign_verified":false}))
	simulation.clear();quit()
