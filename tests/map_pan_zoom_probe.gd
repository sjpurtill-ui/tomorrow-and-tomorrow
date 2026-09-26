extends Node
## Map responsiveness probe: CPU cost of the terrain frame while the player pans
## and zooms, at three view scales. Runs the terrain's own _process with the
## performance trace on and prints per-phase frame times and the costliest trace
## sections. Headless, so GPU cost is excluded; this measures script hitches.
## `-- --assert` fails when a moving frame's median exceeds its budget.
const DT:=1.0/60.0
var terrain:Node
var trace:=preload("res://scripts/performance_trace.gd")

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
	terrain.camera_target=GameState.settlement_founded_at
	# Warm the terrain jobs so streaming is not counted as a pan hitch.
	terrain.camera.size=40.0
	for i in 240:terrain._process(DT)
	var report:Dictionary={"nodes":_count_nodes(terrain),"label3d":terrain.find_children("*","Label3D",true,false).size()}
	var lod_times:Array[float]=[]
	for i in 30:
		var s:=Time.get_ticks_usec();terrain._update_scale_lod();lod_times.append(float(Time.get_ticks_usec()-s)/1000.0)
	lod_times.sort()
	report["update_scale_lod_median_ms"]=lod_times[15]
	# The per-moving-frame parts of the scale LOD, one by one.
	var parts:={}
	for method in ["_normalize_aerial_labels","_update_secondary_settlement_blips","_update_scale_bar","_update_resource_overlay_lod","_update_settlement_claim_opacity"]:
		var part_times:Array[float]=[]
		for i in 21:
			var s:=Time.get_ticks_usec();terrain.call(method);part_times.append(float(Time.get_ticks_usec()-s)/1000.0)
		part_times.sort()
		parts[method]=part_times[10]
	var profile_times:Array[float]=[]
	for i in 21:
		var s:=Time.get_ticks_usec()
		terrain._settlement_expansion_visual_profile({"classification":terrain._settlement_model().classification(),"population":roundi(terrain._settlement_model().primary_population_exact())})
		profile_times.append(float(Time.get_ticks_usec()-s)/1000.0)
	profile_times.sort()
	parts["_settlement_expansion_visual_profile"]=profile_times[10]
	report["scale_lod_parts_median_ms"]=parts
	# The 10 Hz map snapshot refreshes and what they read.
	var snaps:={}
	var calls:={"field_armies":func():terrain._refresh_player_field_army_markers(),
		"field_armies_snapshot":func():MilitaryCampaign.field_armies_snapshot(),
		"military_fronts_snapshot":func():CivilizationSystem.military_fronts_snapshot(),
		"engagement_snapshot":func():MilitaryCampaign.engagement_snapshot(),
		"close_army_figures":func():terrain._refresh_close_army_figures([],-1),
		"formations":func():terrain._refresh_foreign_formation_markers(),
		"contacts":func():terrain._refresh_contact_encounter_markers(),
		"scout_routes":func():terrain._refresh_player_scout_route_markers()}
	for key in calls:
		var t:Array[float]=[]
		for i in 21:
			var s:=Time.get_ticks_usec();(calls[key] as Callable).call();t.append(float(Time.get_ticks_usec()-s)/1000.0)
		t.sort();snaps[key]=t[10]
	report["snapshot_parts_median_ms"]=snaps
	var failures:=0
	for size in [4.0,40.0,400.0]:
		terrain.camera.size=size
		terrain.zoom_target_size=-1.0
		terrain.camera_target=GameState.settlement_founded_at
		terrain._update_camera()
		for i in 120:terrain._process(DT)
		report["idle_%d" % int(size)]=_phase("idle",size,90)
		report["pan_%d" % int(size)]=_phase("pan",size,120)
		report["zoom_%d" % int(size)]=_phase("zoom",size,120)
		if float(report["pan_%d" % int(size)].p50_ms)>12.0:failures+=1
	# A forced border rebuild at a close view: first cold, then with cached heights.
	terrain.camera.size=4.0;terrain.zoom_target_size=-1.0;terrain.camera_target=GameState.settlement_founded_at;terrain._update_camera()
	terrain.territory_height_cache=null
	for pass_name in ["border_rebuild_cold_ms","border_rebuild_warm_ms"]:
		var s:=Time.get_ticks_usec();terrain._refresh_settlement_network(true)
		report[pass_name]=snappedf(float(Time.get_ticks_usec()-s)/1000.0,0.01)
	report["border_height_samples"]=int(terrain.territory_height_cache.misses) if terrain.territory_height_cache else -1
	report["failures"]=failures
	print("MAP_PAN_ZOOM: ",JSON.stringify(report))
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures and "--assert" in OS.get_cmdline_user_args() else 0)

func _count_nodes(node:Node)->int:
	var n:=1
	for child in node.get_children():n+=_count_nodes(child)
	return n

func _phase(kind:String,size:float,frames:int)->Dictionary:
	trace.totals.clear();trace.enabled=true
	var times:Array[float]=[]
	var worst_ms:=0.0;var worst:Array=[]
	var origin:Vector3=terrain.camera_target
	for i in frames:
		match kind:
			"pan":
				terrain.camera_input_msec=Time.get_ticks_msec()
				terrain._set_camera_target(origin+Vector3(size*0.006*i,0,size*0.003*i))
				terrain._update_camera()
			"zoom":
				if i%30==0:terrain._queue_camera_zoom(Vector2(640,360),1.0 if (i/30)%2==0 else -1.0)
		var before:=_trace_snapshot()
		var s:=Time.get_ticks_usec()
		terrain._process(DT)
		var ms:=float(Time.get_ticks_usec()-s)/1000.0
		times.append(ms)
		if ms>worst_ms:
			worst_ms=ms;worst=_trace_delta(before)
	trace.enabled=false
	times.sort()
	var total:=0.0
	for t in times:total+=t
	var sections:Array=[]
	for key in trace.totals:
		var rec:Dictionary=trace.totals[key]
		sections.append([key,snappedf(float(rec.microseconds)/1000.0/frames,0.001)])
	sections.sort_custom(func(a,b):return a[1]>b[1])
	return {"avg_ms":snappedf(total/frames,0.01),"p50_ms":snappedf(times[frames/2],0.01),"p95_ms":snappedf(times[int(frames*0.95)],0.01),"max_ms":snappedf(times[-1],0.01),"top":sections.slice(0,6),"worst_frame":worst}

func _trace_snapshot()->Dictionary:
	var out:={}
	for key in trace.totals:out[key]=int(trace.totals[key].microseconds)
	return out

func _trace_delta(before:Dictionary)->Array:
	var out:=[]
	for key in trace.totals:
		var us:=int(trace.totals[key].microseconds)-int(before.get(key,0))
		if us>100:out.append([key,snappedf(us/1000.0,0.01)])
	out.sort_custom(func(a,b):return a[1]>b[1])
	return out
