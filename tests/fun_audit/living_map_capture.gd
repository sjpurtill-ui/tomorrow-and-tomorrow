extends Node
## Living map GPU capture and frame-time probe (isolated userdata, never saves).
## Runs the real map through founding, day 30, a year-2 summer and winter, and a
## scout party's return. At each stop it saves a PNG, measures frame times with
## vsync off, and (when the build has scripts/living_map.gd) records how many
## people are shown doing which work against the real labour allocation.
## Runs unchanged on a build without the living map, for the "before" set.
##   tools/run_isolated_gpu_probe.ps1 -Scene res://tests/fun_audit/living_map_capture.tscn
##     -UserArguments "--out_dir=<dir> --seed=424242"
const LIVING:="res://scripts/living_map.gd"
const OPENING_FEET:=656.17
var terrain:Node
var out_dir:=""
var results:Dictionary={"shots":{}}
var scout_back:=-1
var scout_report:Dictionary={}

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	out_dir=_arg("out_dir","user://living_map")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var size:=Vector2i(1600,900)
	get_window().size=size;get_window().content_scale_size=size
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var seed_value:=int(_arg("seed","424242"))
	results["seed"]=seed_value
	results["living_map"]=ResourceLoader.exists(LIVING)
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose(_arg("ambition","makers"))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	CivilizationSystem.scout_report_returned.connect(func(r:Dictionary)->void:scout_back=int(GameState.elapsed_days);scout_report=r)
	await _frames(90)
	# 1. The opening frame as this build presents it, then the same 200 m view.
	await _shot("01-founding-opening")
	terrain._inspect_aerial_altitude(OPENING_FEET)
	await _frames(90)
	await _shot("02-founding-200m")
	# The people on the march (shown in place: no journey is ordered here).
	terrain.travel_active=true
	await _frames(30)
	await _shot("02b-founding-march-200m")
	terrain.travel_active=false
	# 2. Found the settlement and live a month.
	terrain._start_settlement_here()
	await _frames(4)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	await _advance_to(30)
	await _look_at_hearth(OPENING_FEET)
	await _shot("03-day30-hearth-200m")
	# A scout party goes out now so that it is home in the second year.
	var sent:Dictionary=CivilizationSystem.dispatch_scouts(90)
	results["scouts_sent"]=str(sent).left(300)
	# 3. Year 2: high summer, then deep winter at this latitude.
	var center:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var summer:=_extreme_day(365,730,center,true)
	var winter:=_extreme_day(summer,summer+365,center,false)
	results["summer_day"]=summer;results["winter_day"]=winter
	results["hemisphere_z"]=center.y
	# What the seasonal shader sees here: mean warmth, rain and the swing.
	var climate:Dictionary=terrain._climate_at(center.x,center.y,GameState.settlement_founded_at.y)
	var amplitude:=PlanetEnvironment.seasonality_at(center)
	var mean:=lerpf(-6.0,28.0,float(climate.temperature))
	results["shader_climate"]={"rain":snappedf(float(climate.precipitation),0.01),"mean_c":snappedf(mean,0.1),"amplitude_c":snappedf(amplitude,0.1),"summer_c":snappedf(mean+amplitude*PlanetEnvironment.season_wave({"position":center},float(summer)),0.1),"winter_c":snappedf(mean+amplitude*PlanetEnvironment.season_wave({"position":center},float(winter)),0.1)}
	await _advance_to(summer)
	await _look_at_hearth(OPENING_FEET)
	await _shot("04-year2-summer-hearth-200m")
	await _look_at_hearth(10000.0)
	await _shot("05-year2-summer-10000ft")
	await _advance_to(winter)
	await _look_at_hearth(OPENING_FEET)
	await _shot("06-year2-winter-hearth-200m")
	await _look_at_hearth(10000.0)
	await _shot("07-year2-winter-10000ft")
	# 4. A scout return: send a short party and wait for it.
	scout_back=-1
	var again:Dictionary=CivilizationSystem.dispatch_scouts(30)
	results["scouts_resent"]=str(again).left(300)
	var limit:=int(GameState.elapsed_days)+120
	while scout_back<0 and GameState.elapsed_days<limit:
		await _advance_to(int(GameState.elapsed_days)+1)
	results["scout_return_day"]=scout_back
	if scout_back>=0:
		await _look_at_party()
		await _shot("08-scout-return")
	var file:=FileAccess.open(out_dir.path_join("living_map_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	file.close()
	print("LIVING_MAP_CAPTURE DONE ",JSON.stringify(results))
	get_tree().quit(0)

func _extreme_day(from:int,to:int,center:Vector2,warmest:bool)->int:
	var best:=from
	var best_value:=INF if not warmest else -INF
	for day in range(from,to):
		var value:=PlanetEnvironment.season_wave({"position":center},float(day))
		if (warmest and value>best_value) or (not warmest and value<best_value):
			best=day;best_value=value
	return best

func _advance_to(day:int)->void:
	terrain._set_game_speed(5)
	while GameState.elapsed_days<day:
		_release_pauses()
		if terrain.game_speed<=0.0:terrain._set_game_speed(5)
		terrain.advance_world_time(1.0)
		await get_tree().process_frame
		_close_court()
	# Watch at one day per second.
	terrain._set_game_speed(4)

func _release_pauses()->void:
	var pause:=preload("res://scripts/hud/simulation_pause.gd")
	pause.owners.clear()
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	var dlg=terrain.military_attention_dialog
	if dlg and is_instance_valid(dlg):dlg.queue_free()
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if PeopleDirection.needs_century_choice():PeopleDirection.choose(_arg("ambition","makers"))

func _close_court()->void:
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.get("modal")):(dir.modal as Node).queue_free()

func _look_at_hearth(feet:float)->void:
	var at:=GameState.settlement_founded_at
	terrain._set_camera_target(Vector3(at.x,terrain._height_at(at.x,at.z),at.z))
	terrain._inspect_aerial_altitude(feet)
	await _frames(150)

func _look_at_party()->void:
	## Frame the scout party where it is now, on its way home.
	var layer:Node=terrain.get_node_or_null("LivingMap")
	terrain._inspect_aerial_altitude(OPENING_FEET)
	for attempt in 3:
		await _frames(30)
		var target:=GameState.settlement_founded_at
		if layer:
			var walkers:Array=layer.get("events")
			for i in walkers.size():
				if String((walkers[i] as Dictionary).kind)!="party":continue
				var local:Vector3=(layer.get("event_mm") as MultiMeshInstance3D).multimesh.get_instance_transform(i).origin
				# Keep the hearth in the frame too: look a little toward home.
				target=(layer as Node3D).position+local*0.7
				break
		terrain._set_camera_target(Vector3(target.x,terrain._height_at(target.x,target.z),target.z))
		terrain._update_camera()
	await _frames(20)

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

func _shot(label:String)->void:
	# Frame times with vsync and the frame cap off, then the capture. With the
	# living map present, blocks alternate layer on / layer off at the same view
	# so its own cost is separated from the day's simulation work.
	Engine.max_fps=0
	var map_only:=not label.begins_with("01")
	if map_only and terrain.hud:
		terrain.hud.close_detail();terrain.hud.close_dock()
		terrain.hud.visible=false
	var layer:Node3D=terrain.get_node_or_null("LivingMap")
	var on:Array[float]=[]
	var off:Array[float]=[]
	for block in 4:
		var enabled:=layer==null or block%2==0
		if layer:
			layer.visible=enabled
			layer.process_mode=Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		await _frames(10)
		var last:=Time.get_ticks_usec()
		for i in 120:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			(on if enabled else off).append(float(now-last)/1000.0);last=now
	if layer:
		layer.visible=true;layer.process_mode=Node.PROCESS_MODE_INHERIT
		await _frames(10)
	await RenderingServer.frame_post_draw
	var path:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(path)
	var shot:={"day":int(GameState.elapsed_days),"population":GameState.population_total,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"altitude_ft":roundi(terrain.aerial_altitude_feet()),"camera_size_km":snappedf(terrain.camera.size,0.001)}
	shot.merge(_stats(on,""))
	if not off.is_empty():shot.merge(_stats(off,"layer_off_"))
	if layer and layer.has_method("activity_report"):shot["living_map"]=layer.activity_report()
	shot["allocations"]=GameState.population_allocations.duplicate()
	results.shots[label]=shot
	if terrain.hud:terrain.hud.visible=true
	print("CAPTURE ",path," ",JSON.stringify(shot))

func _stats(times:Array[float],prefix:String)->Dictionary:
	times.sort()
	var total:=0.0
	for t in times:total+=t
	return {prefix+"fps_avg":snappedf(1000.0*times.size()/total,0.1),prefix+"frame_ms_p50":snappedf(times[times.size()/2],0.01),prefix+"frame_ms_p95":snappedf(times[int(times.size()*0.95)],0.01)}
