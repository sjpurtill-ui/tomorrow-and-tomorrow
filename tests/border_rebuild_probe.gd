extends Node
## Border and map-overlay rebuild probe.
## Default: asserts that territory borders, scout route ribbons, the fog mask and
## the war-map overlay do no rebuild/redraw while their inputs are unchanged, and
## that each does rebuild when territory, a route or the camera LOD changes.
## `-- --measure --days=N` also runs N game days at 1 day/s (20 frames a day)
## and prints rebuild counts and milliseconds per day and per frame.
const FRAMES_PER_DAY:=20
const DT:=1.0/FRAMES_PER_DAY
var failures:Array[String]=[]
var terrain:Node
var stats:Dictionary={}

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(184271)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain.game_speed=0
	terrain.set_process(false)
	await get_tree().process_frame
	if not GameState.settlement_site_committed or "Hearth Circle" not in GameState.settlement_completed:
		GameState.settlement_site_committed=true
		if "Hearth Circle" not in GameState.settlement_completed:GameState.settlement_completed.append("Hearth Circle")
		SettlementModel.ensure_founded()
	terrain._ensure_war_map_overlay()
	terrain.war_map_overlay.set_process(false)
	# A regional view over the home settlement, so its claim is in view.
	terrain.camera_target=GameState.settlement_founded_at
	terrain.camera.size=40.0
	for i in 10:_frame()
	var args:=OS.get_cmdline_user_args()
	if "--measure" in args:
		var days:=365
		for arg in args:
			if arg.begins_with("--days="):days=int(arg.trim_prefix("--days="))
		_measure(days)
	# Both throttled overlays must compile (they only run inside their screens).
	for path in ["res://scripts/hud/service_world_overlay.gd","res://scripts/general_campaign_map.gd"]:
		var script:=load(path) as Script
		check(script!=null and script.can_instantiate(),"%s does not compile" % path)
	_assert_steady_and_changes()
	if failures.is_empty(): print("BORDER_REBUILD PASS")
	else:
		for failure in failures: print("FAIL: ",failure)
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _scout_overlays()->Array:
	var out:=[]
	for marker in terrain.player_scout_route_markers.values():
		if is_instance_valid(marker):
			var hover:Node=marker.find_child("ScoutRouteOverlay",true,false)
			if hover:out.append(hover)
	return out

func _time(key:String,call:Callable)->void:
	var start:=Time.get_ticks_usec()
	call.call()
	var entry:Dictionary=stats.get_or_add(key,{"calls":0,"us":0,"rebuilds":0,"rebuild_us":0})
	entry.calls+=1;entry.us+=Time.get_ticks_usec()-start

func _rebuilt(key:String,us:int)->void:
	var entry:Dictionary=stats.get_or_add(key,{"calls":0,"us":0,"rebuilds":0,"rebuild_us":0})
	entry.rebuilds+=1;entry.rebuild_us+=us

## One rendered frame of the border/overlay work, at the terrain's own cadence.
func _frame()->void:
	var t:=terrain
	# Per-frame work.
	var fog_before:int=t.rendered_fog_revision
	var start:=Time.get_ticks_usec()
	_time("fog_mask",t._refresh_discovery_mask)
	if t.rendered_fog_revision!=fog_before:_rebuilt("fog_mask",Time.get_ticks_usec()-start)
	var war:Control=t.war_map_overlay
	var war_collects:int=int(war.get("collects")) if war.get("collects")!=null else -1
	var war_redraws:int=int(war.get("redraw_requests")) if war.get("redraw_requests")!=null else -1
	start=Time.get_ticks_usec()
	_time("war_overlay",war._process.bind(DT))
	var after_collects:int=int(war.get("collects")) if war.get("collects")!=null else -1
	if war_collects<0:
		# Pre-change overlay: collected every 0.25 s, redrew every frame.
		if float(war.collect_elapsed)==0.0:_rebuilt("war_overlay_collect",Time.get_ticks_usec()-start)
		_rebuilt("war_overlay_redraw",0)
	else:
		if after_collects!=war_collects:_rebuilt("war_overlay_collect",Time.get_ticks_usec()-start)
		if int(war.get("redraw_requests"))!=war_redraws:_rebuilt("war_overlay_redraw",0)
	for hover in _scout_overlays():
		var before=hover.get("redraw_requests")
		_time("scout_hover_overlay",hover._process.bind(DT))
		if before==null or int(hover.get("redraw_requests"))!=int(before):_rebuilt("scout_hover_overlay",0)
	# 10 Hz snapshot work (two frames in twenty at 1 day/s = 10 per second).
	t.map_snapshot_elapsed+=DT
	if t.map_snapshot_elapsed>=0.1:
		t.map_snapshot_elapsed=fmod(t.map_snapshot_elapsed,0.1)
		var ids:={}
		for id in t.player_scout_route_markers:ids[id]=(t.player_scout_route_markers[id] as Object).get_instance_id() if is_instance_valid(t.player_scout_route_markers[id]) else 0
		start=Time.get_ticks_usec()
		_time("scout_routes",t._refresh_player_scout_route_markers)
		var changed:bool=ids.size()!=t.player_scout_route_markers.size()
		for id in t.player_scout_route_markers:
			if not ids.has(id) or ids[id]!=(t.player_scout_route_markers[id] as Object).get_instance_id():changed=true
		if changed:_rebuilt("scout_routes",Time.get_ticks_usec()-start)
		var sig:String=t.rendered_settlement_network_signature
		var rebuilds_before=t.get("settlement_border_rebuilds")
		var undertaking:String=t.undertaking_visual_signature
		start=Time.get_ticks_usec()
		_time("territory_borders",t._refresh_settlement_network)
		# Before the geometry key existed, every signature change rebuilt the meshes.
		if (t.rendered_settlement_network_signature!=sig) if rebuilds_before==null else (int(t.get("settlement_border_rebuilds"))!=int(rebuilds_before)):
			_rebuilt("territory_borders",Time.get_ticks_usec()-start)
			if "--why" in OS.get_cmdline_user_args():print("SIG ",sig," -> ",t.rendered_settlement_network_signature)
		if t.undertaking_visual_signature!=undertaking:_rebuilt("undertaking_visuals",0)

func _day()->void:
	for i in FRAMES_PER_DAY:_frame()
	terrain.game_speed=1.0
	var start:=Time.get_ticks_usec()
	terrain.advance_world_time(1.0)
	var entry:Dictionary=stats.get_or_add("simulation_day",{"calls":0,"us":0,"rebuilds":0,"rebuild_us":0})
	entry.calls+=1;entry.us+=Time.get_ticks_usec()-start
	terrain.game_speed=0.0

func _measure(days:int)->void:
	stats.clear()
	var trace=preload("res://scripts/performance_trace.gd")
	trace.enabled="--trace" in OS.get_cmdline_user_args()
	for d in days:_day()
	var frames:=days*FRAMES_PER_DAY
	var report:={"days":days,"frames":frames,"frames_per_day":FRAMES_PER_DAY,"systems":{}}
	for key in stats:
		var e:Dictionary=stats[key]
		report.systems[key]={"calls":e.calls,"rebuilds":e.rebuilds,"ms_total":snappedf(e.us/1000.0,0.01),"ms_per_day":snappedf(e.us/1000.0/days,0.001),"ms_per_frame":snappedf(e.us/1000.0/frames,0.0001),"rebuilds_per_day":snappedf(float(e.rebuilds)/days,0.001),"rebuild_ms_total":snappedf(e.rebuild_us/1000.0,0.01)}
	report["population"]=GameState.population_total
	report["settlements"]=GameState.player_settlements.size()
	report["scout_missions"]=CivilizationSystem.scout_missions.size()
	print("BORDER_PERF: ",JSON.stringify(report))
	if trace.enabled:
		var network:={}
		for key in trace.totals: if String(key).begins_with("network"): network[key]=trace.totals[key]
		print("BORDER_TRACE: ",JSON.stringify(network))
		trace.enabled=false

func _count(key:String)->int:
	return int((stats.get(key,{}) as Dictionary).get("rebuilds",0))

func _assert_steady_and_changes()->void:
	var t:=terrain
	for i in 10:_frame()
	# Steady: nothing changes for two simulated seconds at the same camera.
	stats.clear()
	for i in 40:_frame()
	for key in ["territory_borders","scout_routes","fog_mask","war_overlay_collect","war_overlay_redraw","scout_hover_overlay","undertaking_visuals"]:
		check(_count(key)==0,"%s rebuilt %d times with unchanged inputs" % [key,_count(key)])
	# A simulated day where nothing visible changes must not rebuild borders.
	stats.clear()
	var sig_before:String=t.rendered_settlement_network_signature
	GameState.elapsed_days+=1.0
	for i in 20:_frame()
	check(_count("territory_borders")==0,"borders rebuilt on a day with no territory change (%s -> %s)" % [sig_before,t.rendered_settlement_network_signature])
	check(_count("war_overlay_redraw")==0,"war overlay redrew on a quiet day")
	# A revision bump that changes nothing drawn (daily labour allocations) must not rebuild.
	stats.clear()
	WorldSimulation.state.settlement_network_revision+=1
	for i in 2:_frame()
	check(_count("territory_borders")==0,"borders rebuilt for a revision that changed nothing drawn (%d)" % _count("territory_borders"))
	# Territory change: the claim moves with its settlement.
	stats.clear()
	var people:=WorldSimulation.state.population_exact
	WorldSimulation.state.population_exact=people*6.0
	WorldSimulation.state.population_total=roundi(people*6.0)
	for i in 2:_frame()
	WorldSimulation.state.population_exact=people
	WorldSimulation.state.population_total=roundi(people)
	check(_count("territory_borders")==1,"borders did not rebuild once after a claim change (%d)" % _count("territory_borders"))
	# Camera LOD change.
	stats.clear()
	t.camera.size=300.0
	for i in 2:_frame()
	check(_count("territory_borders")==1,"borders did not rebuild after an LOD change (%d)" % _count("territory_borders"))
	stats.clear()
	for i in 20:_frame()
	check(_count("territory_borders")==0,"borders rebuilt again at the new LOD (%d)" % _count("territory_borders"))
	# A civ met / new charted ground: fog mask rebuilds once.
	stats.clear()
	CivilizationSystem.fog_revision+=1
	for i in 3:_frame()
	check(_count("fog_mask")==1,"fog mask did not rebuild once after new charted ground (%d)" % _count("fog_mask"))
	# War overlay: a moved camera redraws projected marks; a still one does not.
	var war:Control=t.war_map_overlay
	war.marks.assign([{"id":"border:test","kind":"border","points":[Vector3(0,0,0),Vector3(5,0,5)],"tip":"","color":Color.RED,"alpha":1.0}])
	war.set("marks_signature",12345)
	war.set("collect_key",war._collect_key()) # The ledger has not moved; keep the injected marks.
	stats.clear()
	for i in 3:_frame()
	check(_count("war_overlay_redraw")>=1,"war overlay did not redraw new marks")
	stats.clear()
	for i in 20:_frame()
	check(_count("war_overlay_redraw")==0,"war overlay redrew with unchanged marks and camera (%d)" % _count("war_overlay_redraw"))
	stats.clear()
	t.camera.global_position+=Vector3(1,0,0)
	for i in 2:_frame()
	check(_count("war_overlay_redraw")>=1,"war overlay did not redraw after the camera moved")
