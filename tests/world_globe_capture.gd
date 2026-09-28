extends Node
## World view captures (hud/world_globe.gd) on one world, in one run:
##   fresh       a new world: the founding ground only
##   scouted     after walkers' trails, a few envoy roads and towns seen
##   transition  the map at the far lands, zooming out into the world, midway
##   later       decades on: a much larger known region, and a closer look
## Windowed only (a headless run has no image): run it through
## tools/run_isolated_gpu_probe.ps1 so no window reaches the desktop.
##   -- --out=<absolute dir>
## Prints WORLD_GLOBE_CAPTURE PASS when every shot was written.
const WorldGlobe:=preload("res://scripts/hud/world_globe.gd")
const Chart:=preload("res://scripts/world_globe_chart.gd")

var terrain:Node
var out_dir:=""
var written:=0
var home:=Vector2.ZERO
var rng:=RandomNumberGenerator.new()


func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	out_dir=ProjectSettings.globalize_path("user://world_globe_capture")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):out_dir=argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	rng.seed=20260927
	GameState.reset_for_new_world(184271)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain.game_speed=0.0
	if not GameState.settlement_site_committed or "Hearth Circle" not in GameState.settlement_completed:
		GameState.settlement_site_committed=true
		GameState.settlement_founded_at=terrain.settler_marker.position
		if "Hearth Circle" not in GameState.settlement_completed:GameState.settlement_completed.append("Hearth Circle")
		SettlementModel.ensure_founded()
	var deadline:=Time.get_ticks_msec()+90000
	while not terrain.macro_render.ready() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	print("WORLD_GLOBE_CAPTURE macro ready: ",terrain.macro_render.ready())
	home=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	CivilizationSystem.record_founding_camp_survey(home)
	await _shot("fresh",{})
	_scout_the_near_world()
	await _shot("scouted",{})
	await _transition()
	_learn_the_wider_world()
	await _shot("later",{"today":40*365})
	await _shot("later-close",{"today":40*365,"distance":WorldGlobe.NEAR_DISTANCE+0.25})
	# The night palette (display preferences): the view as a dark-mode player sees it.
	HudTokens.set_color_mode("dark")
	await _shot("later-night",{"today":40*365})
	HudTokens.set_color_mode("light")
	await _fly_back()
	print("WORLD_GLOBE_CAPTURE shots written: %d" % written)
	if written>=11:print("WORLD_GLOBE_CAPTURE PASS")
	get_tree().quit(0 if written>=11 else 1)


## Clicking known ground: the globe turns to it, closes in, and the map takes
## over there and eases in to the region.
func _fly_back()->void:
	var view:Control=WorldGlobe.open(terrain,terrain.hud,false)
	var started:=Time.get_ticks_msec()
	while view.phase!="open" or view.chart.busy():
		await get_tree().process_frame
		if Time.get_ticks_msec()-started>20000:break
	await _wait(0.4)
	view.leave_to(home+Vector2(420.0,-160.0),2)
	await _wait(0.55)
	await _save("leave-mid")
	await _wait(2.4)
	await _save("leave-end")


## Opens the world view, waits for the chart and its ink, saves one image.
func _shot(label:String,options:Dictionary)->void:
	# Let the map finish its own response to new reveals first, so the timings
	# below belong to the world view alone.
	await _wait(2.5)
	var opening:=Time.get_ticks_usec()
	var view:Control=WorldGlobe.open(terrain,terrain.hud,false)
	var open_ms:=float(Time.get_ticks_usec()-opening)/1000.0
	if options.has("today"):view.today_override=int(options.today)
	var started:=Time.get_ticks_msec()
	var worst:=0.0
	var worst_frame:=-1
	for frame in 40:
		var frame_start:=Time.get_ticks_usec()
		await get_tree().process_frame
		var took:=float(Time.get_ticks_usec()-frame_start)/1000.0
		if took>worst:
			worst=took
			worst_frame=frame
	print("WORLD_GLOBE_CAPTURE %s open took %.1f ms, worst of the next 40 frames %.1f ms (frame %d)" % [label,open_ms,worst,worst_frame])
	while view.chart.busy() or view.shown_revision!=view.chart.revision or view.phase!="open":
		var frame_start:=Time.get_ticks_usec()
		await get_tree().process_frame
		worst=maxf(worst,float(Time.get_ticks_usec()-frame_start)/1000.0)
		if Time.get_ticks_msec()-started>30000:break
	for frame in 10:
		var frame_start:=Time.get_ticks_usec()
		await get_tree().process_frame
		worst=maxf(worst,float(Time.get_ticks_usec()-frame_start)/1000.0)
	print("WORLD_GLOBE_CAPTURE %s worst frame through the chart's arrival %.1f ms" % [label,worst])
	print("WORLD_GLOBE_CAPTURE %s keys held by a screen above: %s" % [label,str(view._covered())])
	print("WORLD_GLOBE_CAPTURE %s chart ready in %d ms (%s heights, %d records, %d texels)" % [label,Time.get_ticks_msec()-started,view.chart.height_mode,int(view.chart.stats.records),int(view.chart.stats.texels)])
	if options.has("distance"):
		view.distance=float(options.distance)
		view.distance_goal=view.distance
	view._update_card()
	await _wait(1.3)
	var rid:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	var frames:=0
	var clock:=Time.get_ticks_usec()
	var gpu:=0.0
	var cpu:=0.0
	while frames<60:
		await get_tree().process_frame
		frames+=1
		gpu+=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu+=RenderingServer.viewport_get_measured_render_time_cpu(rid)
	RenderingServer.viewport_set_measure_render_time(rid,false)
	print("WORLD_GLOBE_CAPTURE %s frame time %.2f ms (render gpu %.2f ms, cpu %.2f ms, process %.2f ms)" % [label,float(Time.get_ticks_usec()-clock)/1000.0/float(frames),gpu/float(frames),cpu/float(frames),Performance.get_monitor(Performance.TIME_PROCESS)*1000.0])
	print("WORLD_GLOBE_CAPTURE %s headline: %s | %s | land %s sea %s" % [label,view.headline.text,view.growth.text,view.land_value.text,view.sea_value.text])
	await _save(label)
	view.close()
	await _wait(0.6)


func _transition()->void:
	terrain.set_camera_distance_level(3)
	await _wait(2.5)
	# Let the far-lands ground stream in before zooming out of it.
	var deadline:=Time.get_ticks_msec()+15000
	while terrain.get("terrain_patch_job")!=null and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	await _wait(1.0)
	await _save("transition-start")
	terrain.distance_input_msec=-100000
	var centre:Vector2=get_viewport().get_visible_rect().size*0.5
	var map_height:float=terrain.camera.size
	var map_yaw:float=terrain.camera_yaw
	terrain._step_camera_distance(centre,1.0)
	var view:Control=terrain.world_globe
	if view:print("WORLD_GLOBE_CAPTURE transition from map height %.0f km yaw %.2f: globe starts at %.3f (rest %.3f), roll %.2f" % [map_height,map_yaw,view.distance,view.rest_distance,view.roll])
	await _wait(0.12)
	if is_instance_valid(view):print("WORLD_GLOBE_CAPTURE transition early: distance %.3f roll %.2f opacity %.2f" % [view.distance,view.roll,view.opacity])
	await _save("transition-early")
	await _wait(0.2)
	await _save("transition-mid")
	await _wait(1.4)
	await _save("transition-end")
	if is_instance_valid(terrain.world_globe):terrain.world_globe.close()
	await _wait(0.6)


func _save(label:String)->void:
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	var path:=out_dir.path_join("globe-%s.png" % label)
	if image.save_png(path)==OK:
		written+=1
		print("WORLD_GLOBE_CAPTURE wrote ",path)


func _wait(seconds:float)->void:
	var until:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<until:
		await get_tree().process_frame


## A wandering walkers' trail from `from`, heading roughly `bearing`.
func _walk(from:Vector2,bearing:float,length_km:float,steps:int)->Array:
	var points:Array=[{"x":from.x,"z":from.y}]
	var at:=from
	var heading:=bearing
	for step in steps:
		heading+=rng.randf_range(-0.35,0.35)
		at+=Vector2.from_angle(heading)*length_km/float(steps)
		points.append({"x":at.x,"z":at.y})
	return points


## The near world: eight walkers' trails, two envoy roads, a few towns seen.
func _scout_the_near_world()->void:
	for index in 8:
		var bearing:=TAU*float(index)/8.0+rng.randf_range(-0.2,0.2)
		CivilizationSystem._add_revealed_trail(_walk(home,bearing,rng.randf_range(260.0,700.0),12),18.0,"returned scout trail",60+index*30)
	var towns:=_nearest_towns(4)
	print("WORLD_GLOBE_CAPTURE near towns: %d of %d sites, %d peoples" % [towns.size(),CivilizationSystem.city_intelligence.sites(false).size(),CivilizationSystem.civilizations.size()])
	for index in towns.size():
		var town:Dictionary=towns[index]
		var at:=Vector2(float(town.position.x),float(town.position.z))
		if index<2:CivilizationSystem._reveal_diplomatic_route(home,at)
		var day:=int(GameState.elapsed_days)
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(town.city_id),0.8,day,"physical reconnaissance","capture"),day)


## Decades on: long journeys in every direction, far envoy roads, more towns.
func _learn_the_wider_world()->void:
	for index in 36:
		var bearing:=rng.randf_range(0.0,TAU)
		var start:=home+Vector2.from_angle(rng.randf_range(0.0,TAU))*rng.randf_range(0.0,900.0)
		CivilizationSystem._add_revealed_trail(_walk(start,bearing,rng.randf_range(900.0,3200.0),24),22.0,"returned scout trail",2000+index*300)
	var towns:=_nearest_towns(12)
	for index in towns.size():
		var town:Dictionary=towns[index]
		var at:=Vector2(float(town.position.x),float(town.position.z))
		if index<7:CivilizationSystem._add_revealed_trail([{"x":home.x,"z":home.y},{"x":at.x,"z":at.y}],24.0,"returned diplomatic route",4000+index*600)
		var day:=int(GameState.elapsed_days)
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(town.city_id),0.8,day,"physical reconnaissance","capture"),day)
	for index in 6:
		var bearing:=rng.randf_range(0.0,TAU)
		CivilizationSystem._add_revealed_trail(_walk(home,bearing,rng.randf_range(1500.0,2600.0),20),30.0,"trade caravan route",9000+index*400)


func _nearest_towns(count:int)->Array:
	# A new world's rivals have not raised their towns yet: for the picture,
	# the nearest peoples' chief towns stand already.
	var peoples:=CivilizationSystem.civilizations.duplicate()
	peoples.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return CivilizationSystem._civilization_world_position(a).distance_to(home)<CivilizationSystem._civilization_world_position(b).distance_to(home))
	for civ:Dictionary in peoples.slice(0,5):
		for region:Dictionary in civ.strategic_regions:
			if String(region.get("role",""))=="capital" or rng.randf()<0.4:region["settlement_founded"]=true
	var towns:Array=[]
	for site:Dictionary in CivilizationSystem.city_intelligence.sites(false):towns.append(site)
	towns.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return Vector2(float(a.position.x),float(a.position.z)).distance_to(home)<Vector2(float(b.position.x),float(b.position.z)).distance_to(home))
	return towns.slice(0,count)
