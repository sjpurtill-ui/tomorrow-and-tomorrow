extends Node
## Opt-in, fixed private fixture. Never writes ordinary save slots.
class Snapshot extends "res://scripts/save_system.gd":
	func slot_path(slot:String)->String:return "res://artifacts/year71_"+slot+".save"
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func _ready()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()!="headless" or "--year71-profile" not in OS.get_cmdline_user_args():get_tree().quit(2);return
	var args:=OS.get_cmdline_user_args()
	var mode:="detail" if "--detail" in args else "stepped" if "--stepped" in args else "after" if "--after" in args else "before"
	var saves:=Snapshot.new();add_child(saves)
	var loaded:=saves.load_game("fixture")
	if loaded.has("error"):print(loaded);get_tree().quit(1);return
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.civic_api_enabled=false
	# Exact comparisons need strictly daily rivals; --span=N opts into day_span.gd.
	WorldSimulation.span_limit=1
	for arg in args:
		if arg.begins_with("--span="):WorldSimulation.span_limit=maxi(1,int(arg.trim_prefix("--span=")))
	for id in WorldSimulation.actors:WorldSimulation.actors[id].systems.GameState.civic_api_enabled=false
	if "--map-profile" in OS.get_cmdline_user_args():
		await map_profile();return
	if "--frame-profile" in OS.get_cmdline_user_args():
		await frame_profile();return
	if "--census" in OS.get_cmdline_user_args():
		census();get_tree().quit(0);return
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	WorldSimulation.context_provider=terrain._civilization_geography
	WorldSimulation.surface_material_provider=terrain._civilization_surface_materials
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=GameState.settlement_founded_at
	var report:Dictionary={"day":GameState.elapsed_days,"population":GameState.population_total,"actors":WorldSimulation.actors.size(),"cities":GameState.player_settlements.size(),"samples":[],"fabric":[]}
	var inventory:Array=[]
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			var state:=WorldSimulation.state;var world:=WorldSimulation.world
			var cities:=state.player_settlements.size();var deposits:=state.resource_deposits.size()
			for city:Dictionary in state.player_settlements:
				if not bool(city.get("primary",false)):deposits+=city.get("local_resources",{}).get("resource_deposits",[]).size()
			inventory.append({"actor":id,"cities":cities,"deposits":deposits,"officials_including_history":WorldSimulation.government.people.size(),"scout_missions":world.scout_missions.size(),"chart_records":world.revealed_areas.size(),"plots_primary":state.settlement_plots.size(),"known_discoveries":state.known_discoveries.size()})
		)
	report["inventory"]=inventory
	for lod in [0,1,2]:
		var parent:=Node3D.new();terrain.add_child(parent)
		var start:=Time.get_ticks_usec()
		terrain._create_plot_fabric(GameState.settlement_founded_at,SettlementModel.plots_for_lod(lod),lod,parent)
		report.fabric.append({"lod":lod,"ms":(Time.get_ticks_usec()-start)/1000.0,"nodes":parent.get_child_count()})
		parent.free()
	preload("res://scripts/performance_trace.gd").enabled=mode=="detail"
	var cpu_start:=cpu_seconds()
	var day:=int(GameState.elapsed_days)
	var days:=8 if mode!="detail" else 2
	for arg in args:
		if arg.begins_with("--days="):days=int(arg.trim_prefix("--days="))
	for i in days:
		# Detail totals exclude the cold first day after load; it fills
		# save-excluded caches and misstates steady-state cost.
		if mode=="detail" and i==1:preload("res://scripts/performance_trace.gd").totals.clear()
		var timings:Dictionary={"enabled":true}
		var start:=Time.get_ticks_usec()
		if mode=="stepped":
			report.samples.append({"day":day+i+1,"steps":stepped_day(day+i+1,terrain._discovery_context(),report)})
			report.samples[-1]["ms"]=(Time.get_ticks_usec()-start)/1000.0
		else:
			WorldSimulation.advance_day(day+i+1,terrain._discovery_context(),Callable(),timings)
			report.samples.append({"day":day+i+1,"ms":(Time.get_ticks_usec()-start)/1000.0,"timings":timings})
		print("PROFILE_DAY ",day+i+1," ",report.samples[-1].ms)
		await get_tree().process_frame
	report["simulation_cpu_seconds"]=cpu_seconds()-cpu_start
	if "--outcomes" in args:report["outcomes"]=outcomes()
	report["detail"]=preload("res://scripts/performance_trace.gd").totals
	if mode=="stepped":summarize_steps(report)
	var saved:=saves.save_game(mode)
	assert(saved.get("ok",false))
	if mode in ["after","stepped"]:
		var before:=saves._read_payload("before");var after:=saves._read_payload(mode)
		before.metadata.erase("saved_unix");after.metadata.erase("saved_unix")
		var comparator=load("res://tools/campaign_performance_probe.gd").new()
		comparator.compare(before,after,"world")
		report["state_mismatches"]=comparator.failures.duplicate();comparator.free()
	var file:=FileAccess.open("res://artifacts/year71_"+mode+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("PROFILE_DONE ",mode," state mismatches ",report.get("state_mismatches",[]))
	terrain.free();WorldSimulation.clear();get_tree().quit(0 if report.get("state_mismatches",[]).is_empty() else 1)

## One world day, one scheduled step per call, as the frame loop would run it.
func stepped_day(target:int,context:Dictionary,report:Dictionary)->int:
	var steps:Array=report.get_or_add("step_records",[])
	WorldSimulation.begin_day(target,context)
	var count:=0
	while WorldSimulation.day_in_progress():
		var job=WorldSimulation._day_job
		WorldSimulation.pump_day(0)
		steps.append(job.last_step.merged({"day":target}));count+=1
	return count

func summarize_steps(report:Dictionary)->void:
	var records:Array=report.step_records
	var first_day:=int(records[0].day)
	var warm:Array=records.filter(func(r:Dictionary)->bool:return int(r.day)>first_day).map(func(r:Dictionary)->int:return int(r.usec))
	warm.sort()
	report["warm_steps"]={"count":warm.size(),"p95_ms":warm[int(warm.size()*.95)]/1000.0,"p99_ms":warm[int(warm.size()*.99)]/1000.0,"max_ms":warm[-1]/1000.0,"over_16ms":warm.filter(func(v:int)->bool:return v>16000).size(),"over_33ms":warm.filter(func(v:int)->bool:return v>33000).size()}
	print("WARM_STEPS ",JSON.stringify(report.warm_steps))
	var durations:Array=[]
	var by_label:Dictionary={}
	for record:Dictionary in records:
		durations.append(int(record.usec))
		var key:=String(record.label)
		var entry:Dictionary=by_label.get_or_add(key,{"count":0,"total_ms":0.0,"max_ms":0.0})
		entry.count+=1;entry.total_ms+=record.usec/1000.0;entry.max_ms=maxf(entry.max_ms,record.usec/1000.0)
	durations.sort()
	var pick:=func(q:float)->float:return durations[mini(durations.size()-1,int(q*durations.size()))]/1000.0
	records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.usec)>int(b.usec))
	var over:={"4ms":0,"8ms":0,"16ms":0,"33ms":0}
	for d:int in durations:
		for limit in [[4000,"4ms"],[8000,"8ms"],[16000,"16ms"],[33000,"33ms"]]:
			if d>limit[0]:over[limit[1]]+=1
	report.erase("step_records")
	report["steps"]={"count":durations.size(),"median_ms":pick.call(.5),"p95_ms":pick.call(.95),"p99_ms":pick.call(.99),"max_ms":durations[-1]/1000.0,"over":over,"slowest":records.slice(0,20),"by_label":by_label}
	print("STEPS ",JSON.stringify(report.steps.duplicate().merged({"slowest":records.slice(0,8),"by_label":null},true)))

## Real terrain frames at the fastest calendar speed. Days run as scheduled
## steps inside the terrain's own _process; this records whole-frame intervals.
func frame_profile()->void:
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for node in get_tree().root.get_children():
		if node!=self and node!=terrain:node.set_process(false);node.set_physics_process(false)
	await get_tree().process_frame
	# --settle waits for the initial terrain refinement after load, as a player
	# watching the map would, before measuring top-speed throughput.
	if "--settle" in OS.get_cmdline_user_args():
		var settle_began:=Time.get_ticks_msec()
		var idle_frames:=0
		while idle_frames<30 and Time.get_ticks_msec()-settle_began<60000:
			await get_tree().process_frame
			idle_frames=idle_frames+1 if terrain.terrain_patch_job==null else 0
		print("SETTLED_MS ",Time.get_ticks_msec()-settle_began)
	if "--scene-detail" in OS.get_cmdline_user_args():
		await scene_detail(terrain);return
	var start_day:=int(GameState.elapsed_days)
	var target_days:=4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--days="):target_days=int(arg.trim_prefix("--days="))
	# Warm throughput starts once the cold first day after load has finished.
	var warm_began:=-1
	terrain.scheduled_world_days_enabled="--synchronous" not in OS.get_cmdline_user_args()
	terrain._set_game_speed(5)
	var trace=preload("res://scripts/performance_trace.gd")
	trace.enabled="--frame-trace" in OS.get_cmdline_user_args();trace.totals.clear()
	var frames:Array=[]
	var navigating_frames:Array=[]
	var last:=Time.get_ticks_usec()
	var began:=last
	while int(GameState.elapsed_days)<start_day+target_days and Time.get_ticks_usec()-began<120000000:
		# Pan the camera for a stretch, as a player would while days compute.
		var panning:=frames.size()>=60 and frames.size()<180 and "--no-pan" not in OS.get_cmdline_user_args()
		if panning:
			terrain.camera_target+=Vector3(.01,0,.004);terrain.camera_input_msec=Time.get_ticks_msec()
		var before_totals:Dictionary={}
		if trace.enabled:
			for key:String in trace.totals:before_totals[key]=int(trace.totals[key].microseconds)
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		if trace.enabled and now-last>100000:
			var spent:Dictionary={}
			for key:String in trace.totals:
				var delta:=int(trace.totals[key].microseconds)-int(before_totals.get(key,0))
				if delta>5000:spent[key]=delta/1000
			print("SLOW_FRAME ",(now-last)/1000," day ",int(GameState.elapsed_days)," ",JSON.stringify(spent))
		if warm_began<0 and int(GameState.elapsed_days)>start_day:warm_began=now
		frames.append((now-last)/1000.0)
		if panning:navigating_frames.append((now-last)/1000.0)
		last=now
	terrain._set_game_speed(0)
	WorldSimulation.flush_day()
	var sorted:=frames.duplicate();sorted.sort()
	var report:={"scheduled":terrain.scheduled_world_days_enabled,"days":int(GameState.elapsed_days)-start_day,"seconds":(last-began)/1000000.0,"frames":frames.size(),"warm_days_per_second":float(int(GameState.elapsed_days)-start_day-1)/maxf(.001,(last-warm_began)/1000000.0),"median_ms":sorted[sorted.size()/2],"p95_ms":sorted[int(sorted.size()*.95)],"max_ms":sorted[-1],"over_33ms":sorted.filter(func(v:float)->bool:return v>33.0).size(),"over_100ms":sorted.filter(func(v:float)->bool:return v>100.0).size(),"navigating_max_ms":navigating_frames.max() if not navigating_frames.is_empty() else 0.0}
	var file:=FileAccess.open("res://artifacts/year71_frames_%s.json" % ("scheduled" if report.scheduled else "synchronous"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report.merged({"frames_ms":frames}),"  "));file.close()
	if trace.enabled:
		var phases:Dictionary={}
		for key:String in trace.totals:
			phases[key]=snappedf(float(trace.totals[key].microseconds)/1000.0,.1)
		print("FRAME_TRACE_MS ",JSON.stringify(phases))
		print("SLOW_STEPS ",JSON.stringify(preload("res://scripts/day_job.gd").slow_steps))
	print("FRAME_PROFILE_DONE ",JSON.stringify(report))
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame;get_tree().quit(0 if report.days>=target_days else 1)

func map_profile()->void:
	var trace=preload("res://scripts/performance_trace.gd")
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	terrain._set_game_speed(0);terrain.set_process(false)
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	await get_tree().process_frame
	trace.totals.clear();trace.enabled=true
	var frames:Array=[]
	for i in 36:
		terrain.camera_target+=Vector3(.025,0,.01)
		terrain.camera.size=1.0+float(i)*.12
		var start:=Time.get_ticks_usec()
		terrain._process(1.0/60.0)
		frames.append((Time.get_ticks_usec()-start)/1000.0)
		await get_tree().process_frame
	var file:=FileAccess.open("res://artifacts/year71_map.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames_ms":frames,"phases":trace.totals},"  "));file.close()
	print("MAP_PROFILE_DONE ",frames)
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame;get_tree().quit()

func cpu_seconds()->float:
	if OS.get_name()!="Windows":return 0.0
	var output:Array=[]
	var command:="(Get-Process -Id %d).TotalProcessorTime.TotalSeconds.ToString([System.Globalization.CultureInfo]::InvariantCulture)" % OS.get_process_id()
	var code:=OS.execute("powershell.exe",PackedStringArray(["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-Command",command]),output)
	return String(output[0]).strip_edges().to_float() if code==0 and not output.is_empty() else 0.0

## Which rivals are calm enough for multi-day steps.
func census()->void:
	var known:Dictionary={}
	for civ:Dictionary in CivilizationSystem.civilizations:known[String(civ.id)]={"contact":civ.get("contact",null),"discovered":civ.get("discovered",null),"known":civ.get("known",null),"relation":String(civ.get("player_relation",{}).get("status","")) if civ.get("player_relation") is Dictionary else str(civ.get("player_relation"))}
	print("CIV_KEYS ",CivilizationSystem.civilizations[0].keys() if not CivilizationSystem.civilizations.is_empty() else [])
	for id:String in WorldSimulation.actors:
		WorldSimulation.scoped(id,func()->void:
			var towns:Array=[]
			for city:Dictionary in WorldSimulation.state.player_settlements:
				if not bool(city.get("primary",false)):towns.append(snappedf(float(city.get("resource_metrics",{}).get("food_days",-1)),0.1))
			var fx:=WorldSimulation.world.player_effects()
			print("CENSUS ",id," wars=",fx.war_count," field=",WorldSimulation.military.field_armies.size()," engaged=",not WorldSimulation.military.active_engagement.is_empty()," travel=",WorldSimulation.state.convoy_traveling," convoy=",bool(WorldSimulation.state.settlement_convoy.get("active",false))," food_days=",snappedf(float(WorldSimulation.state.simulation_metrics.get("food_days",-1)),0.1)," towns=",towns," player_view=",known.get(id,{}))
		)

## Aggregate state per owner, for comparing multi-day rival steps with daily ones.
func outcomes()->Dictionary:
	var result:Dictionary={}
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		result[id]=WorldSimulation.scoped(id,func()->Dictionary:
			var state:=WorldSimulation.state
			var m:Dictionary=state.simulation_metrics
			var stock:=0.0
			for key in state.resource_stockpiles:
				if String(key)!="Freshwater":stock+=maxf(0,float(state.resource_stockpiles[key]))
			var food:=0.0
			for key in state.food_stocks:food+=maxf(0,float(state.food_stocks[key]))
			var town_pop:=0.0
			for city:Dictionary in state.player_settlements:
				if not bool(city.get("primary",false)):town_pop+=float(city.get("local_resources",{}).get("population_exact",0))
			return {"day":int(state.elapsed_days),"population":state.population_exact,"food":food,"stock":stock,"health":state.population_health,"food_security":state.food_security,
				"cohesion":float(m.get("cohesion",0)),"knowledge":float(m.get("knowledge",0)),"material":float(m.get("material_capacity",0)),"legitimacy":float(m.get("legitimacy",0)),
				"discoveries":state.known_discoveries.size(),"cities":state.player_settlements.size(),"housing":state.housing_capacity,"treasury":float(state.public_treasury),
				"troops":int(WorldSimulation.military.home_army.get("troops",0)),"projects":state.settlement_completed.size(),"goods_coverage":load("res://scripts/civilian_goods.gd").coverage() if ResourceLoader.exists("res://scripts/civilian_goods.gd") else -1.0}
		)
	return result

## Synchronous days inside the real game scene, with per-phase timings in the
## same format as --detail, so scene-only costs (geography, local building) show.
func scene_detail(terrain:Node)->void:
	var days:=6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--days="):days=int(arg.trim_prefix("--days="))
	var report:Dictionary={"samples":[]}
	var trace=preload("res://scripts/performance_trace.gd")
	trace.enabled="--frame-trace" in OS.get_cmdline_user_args()
	var day:=int(GameState.elapsed_days)
	for i in days:
		var timings:Dictionary={"enabled":true}
		var start:=Time.get_ticks_usec()
		WorldSimulation.advance_day(day+i+1,terrain._discovery_context(),terrain._process_local_settlement_day,timings)
		GameState.elapsed_days=float(day+i+1);terrain.last_discovery_day=day+i+1
		report.samples.append({"day":day+i+1,"ms":(Time.get_ticks_usec()-start)/1000.0,"timings":timings})
		print("SCENE_DAY ",day+i+1," ",report.samples[-1].ms)
		# Warm totals exclude the cold first day, as --detail does.
		if i==0:trace.totals.clear()
		await get_tree().process_frame
	report["detail"]=trace.totals
	var file:=FileAccess.open("res://artifacts/year71_scene_detail.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame;get_tree().quit(0)
