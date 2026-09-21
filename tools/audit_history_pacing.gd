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
var real_geography:=false
var terrain:Node
var origin_hint:=Vector2.ZERO
var checkpoint_path:=""
var restore_path:=""
var restored:Dictionary={}
var wood_density:=-1.0
var ambition_id:=""
var profile_enabled:=false
var timings:Dictionary={}
var secondary_timings:Dictionary={}
var previous_secondary_timings:Dictionary={}
var timing_intervals:Array=[]
var previous_timings:Dictionary={}
var previous_timing_day:=0
var previous_timing_usec:=0
var snapshots:Array=[]
var discoveries:Array=[]
func _initialize()->void:call_deferred("run")
func snapshot(day:int)->Dictionary:
	var state:Node=simulation.state
	var result:={"day":day,"year":float(day)/365.0,"population":state.population_total,"known":state.known_discoveries.size(),"knowledge_workers":state.population_allocations.get("Knowledge",0),"active_inquiries":state.active_investigations.size(),"food_security":state.food_security,"food_intake_ratio":state.simulation_metrics.get("food_intake_ratio",1),"food_eaten":state.simulation_metrics.get("food_eaten",0),"food_demand_breakdown":state.simulation_metrics.get("food_demand_breakdown",{}).duplicate(true),"army_provisions_required":state.simulation_metrics.get("army_provisions_required",0),"army_provisions_delivered":state.simulation_metrics.get("army_provisions_delivered",0),"army_provision_delivery_ratio":state.simulation_metrics.get("army_provision_delivery_ratio",1),"food_consumption":state.simulation_metrics.get("food_consumption",0),"food_days":state.simulation_metrics.get("food_days",0),"settled":state.settlement_site_committed,"completed_buildings":state.settlement_completed.size(),"settlement_count":state.player_settlements.size(),"settlement_plots":state.settlement_plots.size(),"plot_history_records":state.settlement_plot_history.size(),"resource_deposits":state.resource_deposits.size(),"material_stocks":{"Timber":state.resource_stockpiles.get("Timber",0),"Stone":state.resource_stockpiles.get("Stone",0),"Clay":state.resource_stockpiles.get("Clay",0),"Fiber Plants":state.resource_stockpiles.get("Fiber Plants",0)}}
	result["production"]=load("res://tools/pacing_production_evidence.gd").capture()
	return result
func timing_interval(day:int)->Dictionary:
	if not profile_enabled or day<=previous_timing_day:return {}
	var now:=Time.get_ticks_usec()
	var stages:Dictionary={}
	for phase:String in timings:
		if not timings[phase] is Dictionary:continue
		var prior:Dictionary=previous_timings.get(phase,{"calls":0,"microseconds":0})
		stages[phase]={"calls":int(timings[phase].calls)-int(prior.calls),"microseconds":int(timings[phase].microseconds)-int(prior.microseconds)}
	var secondary_stages:Dictionary={}
	for phase:String in secondary_timings:
		if not secondary_timings[phase] is Dictionary:continue
		var prior:Dictionary=previous_secondary_timings.get(phase,{"calls":0,"microseconds":0})
		secondary_stages[phase]={"calls":int(secondary_timings[phase].calls)-int(prior.calls),"microseconds":int(secondary_timings[phase].microseconds)-int(prior.microseconds)}
	previous_secondary_timings=secondary_timings.duplicate(true)
	var interval:={"secondary_stages":secondary_stages,"from_day":previous_timing_day,"to_day":day,"wall_microseconds":now-previous_timing_usec,"stages":stages}
	timing_intervals.append(interval)
	previous_timings=timings.duplicate(true);previous_timing_day=day;previous_timing_usec=now
	return interval

func bottlenecks()->Dictionary:
	var cities:Array=[]
	for city:Dictionary in simulation.state.player_settlements:
		var primary:=bool(city.get("primary",false))
		var local:Dictionary=city.get("local_resources",{})
		cities.append({"id":city.id,"primary":primary,"population":simulation.settlements._settlement_population(city),"plots":simulation.state.settlement_plots.size() if primary else local.get("settlement_plots",[]).size(),"last_resource_day":city.get("last_resource_day",-1),"occupied":not String(city.get("occupied_by","")).is_empty()})
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
	var result:={"settlements":cities,"causally_ready_questions":questions,"material_states":material_states,"allocations":simulation.state.population_allocations.duplicate(),"research_allocations":simulation.state.research_allocations.duplicate(),"research_subcategory_allocations":simulation.state.research_subcategory_allocations.duplicate(true),"active_investigations":simulation.state.active_investigations.duplicate(),"controller_plan":controller.current_plan("pacing_reference"),"known_ids":simulation.state.known_discoveries.duplicate()}
	result["production"]=load("res://tools/pacing_production_evidence.gd").capture(true)
	return result
func checkpoint(day:int)->void:
	if checkpoint_path.is_empty():return
	var payload:={"day":day,"seed":seed_value,"real_geography":real_geography,"origin_hint":origin_hint,"wood_density":wood_density,"ambition":ambition_id,"world":simulation.export_state(),"snapshots":snapshots,"discoveries":discoveries}
	var file:=FileAccess.open(checkpoint_path,FileAccess.WRITE)
	if file==null:push_error("Cannot write diagnostic checkpoint: "+checkpoint_path);return
	file.store_buffer(var_to_bytes(payload));file.close()

func run()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument=="--real-geography":real_geography=true
		elif argument.begins_with("--origin-x="):origin_hint.x=argument.trim_prefix("--origin-x=").to_float()
		elif argument.begins_with("--origin-y="):origin_hint.y=argument.trim_prefix("--origin-y=").to_float()
		elif argument.begins_with("--checkpoint="):checkpoint_path=argument.trim_prefix("--checkpoint=")
		elif argument.begins_with("--resume="):restore_path=argument.trim_prefix("--resume=")
		elif argument=="--profile":profile_enabled=true;timings={"enabled":true};secondary_timings={"enabled":true}
		elif argument.begins_with("--days="):target_days=clampi(argument.trim_prefix("--days=").to_int(),1,3650000)
		elif argument.begins_with("--wall-seconds="):wall_seconds=clampf(argument.trim_prefix("--wall-seconds=").to_float(),1,14400)
		elif argument.begins_with("--seed="):seed_value=argument.trim_prefix("--seed=").to_int()
		elif argument.begins_with("--out="):output_path=argument.trim_prefix("--out=")
		elif argument.begins_with("--wood-density="):wood_density=clampf(argument.trim_prefix("--wood-density=").to_float(),0.0,1.0)
		elif argument.begins_with("--ambition="):ambition_id=argument.trim_prefix("--ambition=")
	if not restore_path.is_empty():
		var incoming:Variant=bytes_to_var(FileAccess.get_file_as_bytes(restore_path))
		if not incoming is Dictionary or not incoming.get("world") is Dictionary:push_error("Invalid diagnostic checkpoint.");quit(1);return
		restored=incoming
		seed_value=int(restored.seed);real_geography=bool(restored.real_geography);origin_hint=restored.origin_hint;wood_density=float(restored.wood_density);ambition_id=String(restored.ambition)
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	simulation=root.get_node("WorldSimulation");simulation.clear()
	daily=load("res://scripts/civilization_day.gd");controller=load("res://scripts/civilization_controller.gd")
	var planet:Node=root.get_node("PlanetEnvironment")
	simulation.context_provider=func(point:Vector2)->Dictionary:
		var profile:Dictionary=planet.profile_at(point)
		var fields:Dictionary={}
		for resource:String in ["Timber","Stone","Fiber Plants"]:
			fields[resource]={"density":clampf(float(profile.get("resource_potentials",{}).get(resource,0)),0,1),"area_km2":9.0,"position":Vector3(point.x,0,point.y)}
		if wood_density>=0.0:fields.Timber.density=wood_density
		return {"environment_profile":profile,"surface_water_distance_km":.1,"surface_water_recognized":true,"surface_material_catchments":fields,"woodland_catchment":fields.Timber}
	simulation.water_provider=func(point:Vector3)->Vector3:return point+Vector3(.1,0,0)
	var start_point:=origin_hint
	if real_geography:
		root.get_node("GameState").reset_for_new_world(seed_value)
		terrain=load("res://scripts/local_terrain.gd").new()
		terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
		simulation.water_provider=Callable(terrain,"_surface_water_site_near")
		simulation.context_provider=Callable(terrain,"_civilization_geography")
		simulation.route_provider=Callable(terrain,"_analyze_convoy_route")
		start_point=terrain._civilization_start(origin_hint)
	var actor:Dictionary={}
	if restored.is_empty():actor=simulation.create_actor("pacing_reference",seed_value,start_point)
	else:
		var result:Dictionary=simulation.import_state(restored.world)
		if result.has("error"):push_error(str(result));quit(1);return
		actor=simulation.actors["pacing_reference"];snapshots=restored.snapshots;discoveries=restored.discoveries
	if restored.is_empty() and not ambition_id.is_empty():
		var accepted:Dictionary=simulation.submit("pacing_reference",{"kind":"ambition","id":ambition_id})
		if accepted.has("error"):push_error(str(accepted));simulation.clear();quit(1);return
	simulation.enabled=true # Normal resource days initialize owned world geology.
	if real_geography:
		actor.systems.CivilizationSystem.scout_land_authority=func(point:Vector2)->bool:return terrain._height_at(point.x,point.y)>.012
		actor.systems.CivilizationSystem.ground_survey_authority=Callable(terrain,"_survey_ground_at")
	else:actor.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	previous_timing_usec=Time.get_ticks_usec() if profile_enabled else 0
	var start:=Time.get_ticks_msec()
	var day:=int(restored.get("day",0));var start_day:=day;var reason:="target reached";var catalog_count:=0
	if snapshots.is_empty():simulation.scoped("pacing_reference",func()->void:snapshots.append(snapshot(day)))
	while day<target_days:
		if Time.get_ticks_msec()-start>=wall_seconds*1000:reason="wall-time budget reached";break
		day+=1
		var extinct:bool=simulation.scoped("pacing_reference",func()->bool:
			simulation.state.elapsed_days=day
			var stamp:=Time.get_ticks_usec() if profile_enabled else 0
			if not ambition_id.is_empty() and simulation.direction.needs_century_choice():
				simulation.submit("pacing_reference",{"kind":"ambition","id":ambition_id})
			controller.choose_orders("pacing_reference")
			stamp=daily.record_timing(timings,"controller",stamp)
			var origin:Vector2=simulation.world.player_world_origin
			if simulation.state.settlement_site_committed:origin=Vector2(simulation.state.settlement_founded_at.x,simulation.state.settlement_founded_at.z)
			var context:Dictionary=daily.context(origin,simulation.state.convoy_traveling)
			stamp=daily.record_timing(timings,"context",stamp)
			var result:Dictionary=daily.advance(day,context,Callable(),timings,secondary_timings)
			for event:Dictionary in result.discoveries:discoveries.append({"id":event.id,"day":day,"year":float(day)/365.0})
			if day==1 or day%365==0:snapshots.append(snapshot(day))
			return simulation.state.population_total<=1
		)
		if day%365==0:
			var progress:={"progress":day,"year":float(day)/365.0,"snapshot":snapshots.back()}
			if profile_enabled:progress["timing_interval"]=timing_interval(day)
			print(JSON.stringify(progress))
		if day%9125==0:checkpoint(day)
		if extinct:reason="population collapse";break
		if day%30==0:await process_frame
	if profile_enabled:timing_interval(day)
	var final:Dictionary=simulation.scoped("pacing_reference",func()->Dictionary:return snapshot(day))
	catalog_count=actor.systems.DiscoverySystem.technology_catalog.size()
	var elapsed:=float(Time.get_ticks_msec()-start)/1000.0
	var diagnostic:Dictionary=simulation.scoped("pacing_reference",func()->Dictionary:return bottlenecks())
	checkpoint(day)
	var save_check:Dictionary=simulation.check_payload(bytes_to_var(var_to_bytes(simulation.export_state())))
	var scenario:="isolated AI seat; rendered-terrain geography services; naturally sampled water/materials; no foreign exchange" if real_geography else "isolated AI seat; seeded planet at origin; synthetic recognized river 0.1 km away; macro-profile surface catchments; world geology and matching hydrology record enabled; no foreign exchange"
	var report:={"schema":13,"checkpoint":checkpoint_path,"resumed_from_day":start_day,"save_check":save_check,"real_geography":real_geography,"origin_hint":{"x":origin_hint.x,"y":origin_hint.y},"controlled_choices":{"wood_density_override":wood_density,"century_ambition":ambition_id},"secondary_timings":secondary_timings,"timing_intervals":timing_intervals,"timings":timings,"profiling_enabled":profile_enabled,"bottlenecks":diagnostic,"scenario":scenario,"seed":seed_value,"target_days":target_days,"simulated_days":day,"stop_reason":reason,"wall_seconds":elapsed,"days_per_second":float(day-start_day)/maxf(.001,elapsed),"live_catalog":catalog_count,"target_reached":day==target_days,"full_campaign_verified":false,"initial":snapshots[0],"final":final,"annual_snapshots":snapshots,"discoveries":discoveries,"limitations":["One isolated seat, not a full world or a player campaign","Terrain mode uses real sampling without rendering; reference mode uses synthetic local water/land authority and macro material densities","No foreign acquisition, war or dependency-recovery scenario","Controller and daily economic/demographic/research rules are live; no unlocks, refill or population rescue","Wood override changes local timber catchments only, not an entire biome; ambition uses ordinary century choices, not direct technology grants","Short or collapsed runs do not validate millennial pacing"]}
	var file:=FileAccess.open(output_path,FileAccess.WRITE)
	if file==null:push_error("Cannot write pacing diagnostic: "+output_path);quit(1);return
	file.store_string(JSON.stringify(report,"  "));file.close()
	print(JSON.stringify({"report":output_path,"final":final,"stop_reason":reason,"days_per_second":report.days_per_second,"full_campaign_verified":false}))
	simulation.clear()
	if terrain!=null:terrain.free()
	quit(1 if save_check.has("error") else 0)
