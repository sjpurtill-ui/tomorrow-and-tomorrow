extends Node
func _ready()->void:
	call_deferred("run")
func run()->void:
	GameState.reset_for_new_world(9241)
	var count:=36;var duration:=3
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--opponents="):count=int(argument.get_slice("=",1))
		if argument.begins_with("--days="):duration=int(argument.get_slice("=",1))
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
	var total_ms:=0
	for day in range(1,duration+1):
		start=Time.get_ticks_msec()
		WorldSimulation.advance_day(day,preload("res://scripts/civilization_day.gd").context(player_start))
		total_ms+=Time.get_ticks_msec()-start
		if day<=3 or day%30==0:print("ACTUAL DAY ",day," time_ms ",Time.get_ticks_msec()-start)
	var errors:=CivilizationSystem.validate_state()
	print("WORLD ERRORS ",errors)
	print("AVERAGE DAY MS ",float(total_ms)/duration)
	for id in WorldSimulation.actors:
		var state:Node=WorldSimulation.actors[id].systems.GameState
		print("CIV ",id," population ",state.population_total," cities ",state.player_settlements.size()," discoveries ",state.known_discoveries.size())
	WorldSimulation.clear();terrain.free()
	get_tree().quit(0 if errors.is_empty() and waterless==0 else 1)
