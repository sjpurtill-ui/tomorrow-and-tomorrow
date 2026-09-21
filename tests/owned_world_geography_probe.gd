extends Node
func _ready()->void:
	call_deferred("run")
func run()->void:
	GameState.reset_for_new_world(9241)
	var count:=36;var duration:=3;var output:="";var verify_restore:=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--opponents="):count=int(argument.get_slice("=",1))
		if argument.begins_with("--days="):duration=int(argument.get_slice("=",1))
		if argument.begins_with("--out="):output=argument.trim_prefix("--out=")
		if argument=="--verify-restore":verify_restore=true
	GameState.opponent_count=count
	CivilizationSystem.reset_for_new_world()
	var terrain=load("res://scripts/local_terrain.gd").new()
	terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
	CivilizationSystem.set_scout_geography_authority(func(point:Vector2)->bool:return terrain._height_at(point.x,point.y)>.012)
	CivilizationSystem.ground_survey_authority=Callable(terrain,"_survey_ground_at")
	WorldSimulation.water_provider=Callable(terrain,"_surface_water_site_near")
	WorldSimulation.context_provider=Callable(terrain,"_civilization_geography")
	WorldSimulation.start_provider=Callable(terrain,"_civilization_start")
	WorldSimulation.route_provider=Callable(terrain,"_analyze_convoy_route")
	var player_start:Vector2=terrain._civilization_start(preload("res://scripts/civilization_start.gd").candidate(GameState.world_seed,0))
	CivilizationSystem.register_player_origin(player_start)
	GameState.settlement_founded_at=Vector3(player_start.x,0,player_start.y)
	var start=Time.get_ticks_msec()
	WorldSimulation.start_world()
	print("REAL WORLD START ",Time.get_ticks_msec()-start," ms, actors ",WorldSimulation.actors.size())
	var waterless=0
	for actor in WorldSimulation.actors.values():
		var context:Dictionary=terrain._civilization_geography(actor.origin)
		if float(context.surface_water_distance_km)>6:waterless+=1
	print("WATERLESS STARTS ",waterless)
	WorldSimulation.submit("player",{"kind":"ambition","id":"makers"})
	WorldSimulation.submit("player",{"kind":"found"})
	var total_ms:=0;var completed:=0;var errors:Array=[]
	for day in range(1,duration+1):
		start=Time.get_ticks_msec()
		WorldSimulation.advance_day(day,preload("res://scripts/civilization_day.gd").context(player_start))
		total_ms+=Time.get_ticks_msec()-start
		completed=day
		if day<=3 or day%365==0:print("ACTUAL DAY ",day," time_ms ",Time.get_ticks_msec()-start)
		if day%365==0:
			errors=CivilizationSystem.validate_state()
			if not errors.is_empty():break
		if day%30==0:await get_tree().process_frame
	errors=CivilizationSystem.validate_state()
	var save_check:Dictionary=WorldSimulation.check_payload(bytes_to_var(var_to_bytes(WorldSimulation.export_state())))
	if save_check.has("error"):errors.append(save_check.error)
	var human_payload:Dictionary={}
	for name:String in SaveSystem.REFLECTED_SYSTEMS:
		human_payload["reflected_"+name]=SaveSystem._capture_reflected(get_node("/root/"+name),SaveSystem.REFLECT_SKIP.get(name,[]))
	human_payload.reflected_society_model=SaveSystem._capture_reflected(DiscoverySystem.society_model,SaveSystem.SOCIETY_REFLECT_SKIP)
	for name:String in SaveSystem.CURATED_SYSTEMS:
		human_payload["curated_"+name]=get_node("/root/"+name).export_state()
	var human_save_check:Dictionary=SaveSystem._validate_human_payload(bytes_to_var(var_to_bytes(human_payload)),GameState.world_seed)
	if human_save_check.has("error"):errors.append(human_save_check.error)

	var continuation:Dictionary={}
	if verify_restore:
		continuation=preload("res://tools/verify_campaign_save.gd").verify(player_start,func()->void:
			CivilizationSystem.set_scout_geography_authority(func(point:Vector2)->bool:return terrain._height_at(point.x,point.y)>.012)
			CivilizationSystem.ground_survey_authority=Callable(terrain,"_survey_ground_at"))
		if continuation.has("error"):errors.append(continuation.error)
		print("SAVE CONTINUATION ",JSON.stringify(continuation))
	print("WORLD ERRORS ",errors)
	print("AVERAGE DAY MS ",float(total_ms)/maxi(1,completed))
	var settlements:Array=[]
	for id:String in ["player"]+WorldSimulation.actors.keys():
		var summary:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:
			var state:Node=WorldSimulation.state
			return {"id":id,"population":state.population_total,"cities":state.player_settlements.size(),"discoveries":state.known_discoveries.size(),"food_days":state.simulation_metrics.get("food_days",0),"production":preload("res://tools/pacing_production_evidence.gd").capture()})
		settlements.append(summary)
		print("CIV ",JSON.stringify(summary))
	if not output.is_empty():
		var report:={"target_days":duration,"completed_days":completed,"target_reached":completed==duration,"waterless":waterless,"save_check":save_check,"human_save_check":human_save_check,"continuation":continuation,"errors":errors,"actors":settlements,"average_day_ms":float(total_ms)/maxi(1,completed),"limitations":["Headless actual world; no visual verification","No forced contact or wars","Binary payload validation covers player and opponents; rendered load journey is separate"]}
		var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report));file.close()
	WorldSimulation.clear();terrain.free()
	get_tree().quit(0 if errors.is_empty() and waterless==0 and completed==duration else 1)
