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
var snapshots:Array=[]
var discoveries:Array=[]
func _initialize()->void:call_deferred("run")
func snapshot(day:int)->Dictionary:
	var state:Node=simulation.state
	return {"day":day,"year":float(day)/365.0,"population":state.population_total,"known":state.known_discoveries.size(),"knowledge_workers":state.population_allocations.get("Knowledge",0),"active_inquiries":state.active_investigations.size(),"food_security":state.food_security,"food_days":state.simulation_metrics.get("food_days",0),"settled":state.settlement_site_committed,"completed_buildings":state.settlement_completed.size()}
func run()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--days="):target_days=clampi(argument.trim_prefix("--days=").to_int(),1,3650000)
		elif argument.begins_with("--wall-seconds="):wall_seconds=clampf(argument.trim_prefix("--wall-seconds=").to_float(),1,300)
		elif argument.begins_with("--seed="):seed_value=argument.trim_prefix("--seed=").to_int()
		elif argument.begins_with("--out="):output_path=argument.trim_prefix("--out=")
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	simulation=root.get_node("WorldSimulation");simulation.clear()
	daily=load("res://scripts/civilization_day.gd");controller=load("res://scripts/civilization_controller.gd")
	var planet:Node=root.get_node("PlanetEnvironment")
	simulation.context_provider=func(point:Vector2)->Dictionary:return {"environment_profile":planet.profile_at(point),"surface_water_distance_km":.1,"surface_water_recognized":true}
	var actor:Dictionary=simulation.create_actor("pacing_reference",seed_value,Vector2.ZERO)
	actor.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	var start:=Time.get_ticks_msec()
	var day:=0;var reason:="target reached";var catalog_count:=0
	simulation.scoped("pacing_reference",func()->void:snapshots.append(snapshot(0)))
	while day<target_days:
		if Time.get_ticks_msec()-start>=wall_seconds*1000:reason="wall-time budget reached";break
		day+=1
		var extinct:bool=simulation.scoped("pacing_reference",func()->bool:
			simulation.state.elapsed_days=day
			controller.choose_orders("pacing_reference")
			var origin:Vector2=simulation.world.player_world_origin
			if simulation.state.settlement_site_committed:origin=Vector2(simulation.state.settlement_founded_at.x,simulation.state.settlement_founded_at.z)
			var context:Dictionary=daily.context(origin,simulation.state.convoy_traveling)
			var result:Dictionary=daily.advance(day,context)
			for event:Dictionary in result.discoveries:discoveries.append({"id":event.id,"day":day,"year":float(day)/365.0})
			if day==1 or day%365==0:snapshots.append(snapshot(day))
			return simulation.state.population_total<=1
		)
		if extinct:reason="population collapse";break
		if day%30==0:await process_frame
	var final:Dictionary=simulation.scoped("pacing_reference",func()->Dictionary:return snapshot(day))
	catalog_count=actor.systems.DiscoverySystem.technology_catalog.size()
	var elapsed:=float(Time.get_ticks_msec()-start)/1000.0
	var report:={"schema":1,"scenario":"isolated AI seat; seeded planet at origin; synthetic recognized river 0.1 km away; no foreign exchange","seed":seed_value,"target_days":target_days,"simulated_days":day,"stop_reason":reason,"wall_seconds":elapsed,"days_per_second":float(day)/maxf(.001,elapsed),"live_catalog":catalog_count,"target_reached":day==target_days,"full_campaign_verified":false,"initial":snapshots[0],"final":final,"annual_snapshots":snapshots,"discoveries":discoveries,"limitations":["One isolated seat, not a full world or a player campaign","Synthetic local water and land authority; no rendered geography","No foreign acquisition, war or dependency-recovery scenario","Controller and daily economic/demographic/research rules are live; no unlocks, refill or population rescue","Short or collapsed runs do not validate millennial pacing"]}
	var file:=FileAccess.open(output_path,FileAccess.WRITE)
	if file==null:push_error("Cannot write pacing diagnostic: "+output_path);quit(1);return
	file.store_string(JSON.stringify(report,"  "));file.close()
	print(JSON.stringify({"report":output_path,"final":final,"stop_reason":reason,"days_per_second":report.days_per_second,"full_campaign_verified":false}))
	simulation.clear();quit()
