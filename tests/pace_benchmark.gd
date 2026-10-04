extends Node
## PACE BENCHMARK: what a world day costs, by owner and by step, from a copied
## save. Headless and opt-in; never reads or writes the player's save slots.
##   <godot> --headless --path <worktree> res://tests/pace_benchmark.tscn -- --pace-benchmark
##       --save=<path to a COPY of a .save> [--days=30] [--warm=2] [--trace]
## Days run as the frame loop runs them: begin_day, then one scheduled step at
## a time, so the longest single steps (which set the worst frames) show too.
## Reports ms a day by owner (player, each rival), by step label and by system
## timing, the steps each owner took, and the slowest steps.
##   --save-out=NAME   write the world afterwards to res://artifacts/pace_NAME.save
##                     and report its size
##   --compare=NAME    compare the world afterwards with an earlier --save-out
##                     (the same world must come out of the same days);
##                     --ignore-keys=a,b and --ignore-paths=a,b set aside fields a
##                     change deliberately adds or reshapes; floats within
##                     --tolerance (relative, 1e-9) are counted as rounding
##   --compare-only=A,B  compare two earlier --save-out worlds and stop
##   --span=N, --unmet-span=N  rival step limits (world_simulation.gd)
##   --census          why each rival steps as often as it does
##   --outcomes        each owner's state in aggregate at the end
##   --explain-over=MS list the heavy steps of any day over MS
##   --slowest=N       how many of the slowest steps to keep
## --frames runs the game's own scene and frame loop instead, at --speed=5 for
## --seconds=60 after the map settles, with --render-cost=14 ms standing in for
## drawing; it prints the player's PERF line and lists long frames by traced
## phase. --quiet=name, --quiet-children, --quiet-range=A,B, --list-children
## and --list-under=N stop or list scene children to find what makes frames long.
class Snapshot extends "res://scripts/save_system.gd":
	var fixture:=""
	func slot_path(slot:String)->String:
		return fixture if slot=="fixture" else "res://artifacts/pace_"+slot+".save"
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

func _ready()->void:call_deferred("run")

func _arg(name:String,fallback:String)->String:
	for a:String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):return a.substr(name.length()+3)
	return fallback

func run()->void:
	var args:=OS.get_cmdline_user_args()
	_ignored_paths=_arg("ignore-paths","").split(",",false)
	if DisplayServer.get_name()!="headless" or "--pace-benchmark" not in args:get_tree().quit(2);return
	var saves:=Snapshot.new();saves.fixture=_arg("save","res://artifacts/pace_fixture.save");add_child(saves)
	if _arg("compare-only","")!="":
		# --compare-only=A,B compares two earlier --save-out worlds and stops.
		var names:=_arg("compare-only","").split(",")
		var first:=saves._read_payload(names[0]);var second:=saves._read_payload(names[1])
		first.metadata.erase("saved_unix");second.metadata.erase("saved_unix")
		var diff:={"mismatches":[],"mismatch_count":0,"rounding":[],"rounding_count":0}
		_compare(first,second,"world",diff,_arg("ignore-keys","").split(",",false),float(_arg("tolerance","1e-9")))
		print("PACE_COMPARE ",JSON.stringify(diff))
		get_tree().quit(0);return
	var load_began:=Time.get_ticks_usec()
	var loaded:=saves.load_game("fixture")
	var load_ms:=(Time.get_ticks_usec()-load_began)/1000.0
	if loaded.has("error"):print("PACE_LOAD_FAILED ",loaded);get_tree().quit(1);return
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.civic_api_enabled=false
	for id in WorldSimulation.actors:WorldSimulation.actors[id].systems.GameState.civic_api_enabled=false
	if _arg("span","")!="":WorldSimulation.span_limit=maxi(1,int(_arg("span","3")))
	if _arg("unmet-span","")!="":WorldSimulation.set("uncontacted_span_limit",maxi(1,int(_arg("unmet-span","10"))))
	if "--frames" in args:
		await _frames(load_ms)
		return
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	terrain._prepare_river_course()
	# The same geography the game's terrain hands the simulation (local_terrain.gd _ready).
	CivilizationSystem.set_scout_geography_authority(Callable(terrain,"_scout_land_at"))
	CivilizationSystem.set_ground_survey_authority(Callable(terrain,"_survey_ground_at"))
	MilitaryCampaign.recovery.surface_assessor=Callable(terrain,"_settlement_surface_assessment")
	WorldSimulation.water_provider=Callable(terrain,"_surface_water_site_near")
	WorldSimulation.context_provider=terrain._civilization_geography
	WorldSimulation.surface_material_provider=terrain._civilization_surface_materials
	WorldSimulation.bind_geography()
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=GameState.settlement_founded_at
	if "--census" in args:_census()
	var days:=int(_arg("days","30"))
	var warm:=int(_arg("warm","2"))
	var trace=preload("res://scripts/performance_trace.gd")
	trace.enabled="--trace" in args;trace.totals.clear()
	var start_day:=int(GameState.elapsed_days)
	var report:Dictionary={"save":saves.fixture,"load_ms":load_ms,"start_day":start_day,"year":start_day/365.0,"population":GameState.population_total,"rivals":WorldSimulation.actors.size(),"span_limit":WorldSimulation.span_limit,"days":days,"warm":warm}
	var totals:Dictionary={}
	var owners:Dictionary={}
	var labels:Dictionary={}
	var warm_steps:PackedInt32Array=PackedInt32Array()
	var slowest:Array=[]
	var advanced:Dictionary={}
	var day_ms:Array=[]
	for i in days:
		var day:=start_day+i+1
		if i==warm:trace.totals.clear()
		var timings:Dictionary={"enabled":true}
		var began:=Time.get_ticks_usec()
		WorldSimulation.begin_day(day,terrain._discovery_context(),Callable(),Callable(),timings)
		var records:Array=[]
		while WorldSimulation.day_in_progress():
			var job=WorldSimulation._day_job
			WorldSimulation.pump_day(0)
			records.append(job.last_step)
		var ms:=(Time.get_ticks_usec()-began)/1000.0
		day_ms.append(ms)
		print("PACE_DAY ",day," ",snappedf(ms,.1))
		if i<warm:continue
		if ms>=float(_arg("explain-over","400")):
			var by_step:Dictionary={}
			for record:Dictionary in records:
				var key:="%s:%s" % [String(record.owner),String(record.label)]
				by_step[key]=snappedf(float(by_step.get(key,0.0))+int(record.usec)/1000.0,.1)
			var heavy:Dictionary={}
			for key:String in by_step:
				if float(by_step[key])>=10.0:heavy[key]=by_step[key]
			print("PACE_HEAVY_DAY ",day," ",snappedf(ms,.1)," ",JSON.stringify(_sorted_desc(heavy)))
		for record:Dictionary in records:
			var owner:=String(record.owner)
			var usec:=int(record.usec)
			owners[owner]=int(owners.get(owner,0))+usec
			if String(record.label)=="arrivals":advanced[owner]=int(advanced.get(owner,0))+1
			if String(record.label)=="secondary_settlements":advanced[owner+":towns"]=int(advanced.get(owner+":towns",0))+1
			var kind:="player" if owner=="player" else "rival"
			var key:="%s:%s" % [kind,String(record.label)]
			labels[key]=int(labels.get(key,0))+usec
			warm_steps.append(usec)
			if usec>=15000:slowest.append({"day":day,"owner":owner,"label":String(record.label),"ms":usec/1000.0})
		_accumulate(totals,timings)
	var warm_days:=maxi(1,days-warm)
	var warm_ms:Array=day_ms.slice(warm)
	var total_ms:=0.0
	for v:float in warm_ms:total_ms+=v
	report["mean_ms_per_day"]=total_ms/warm_days
	var sorted:=warm_ms.duplicate();sorted.sort()
	report["median_ms_per_day"]=sorted[sorted.size()/2] if not sorted.is_empty() else 0.0
	report["max_ms_per_day"]=sorted[-1] if not sorted.is_empty() else 0.0
	report["day_ms"]=day_ms
	var rival_total:=0
	for owner:String in owners:if owner!="player":rival_total+=int(owners[owner])
	report["player_ms_per_day"]=float(owners.get("player",0))/1000.0/warm_days
	report["rivals_ms_per_day"]=float(rival_total)/1000.0/warm_days
	var by_owner:Dictionary={}
	for owner:String in owners:by_owner[owner]=snappedf(float(owners[owner])/1000.0/warm_days,.01)
	report["owner_ms_per_day"]=by_owner
	# Steps each owner took (a rival covers several days in one when calm).
	report["owner_steps"]=advanced
	report["label_ms_per_day"]=_per_day(labels,warm_days)
	report["timings_ms_per_day"]=_timing_table(totals,warm_days)
	warm_steps.sort()
	if not warm_steps.is_empty():
		report["steps"]={"count_per_day":float(warm_steps.size())/warm_days,"p50_ms":warm_steps[warm_steps.size()/2]/1000.0,"p95_ms":warm_steps[int(warm_steps.size()*.95)]/1000.0,"p99_ms":warm_steps[int(warm_steps.size()*.99)]/1000.0,"max_ms":warm_steps[-1]/1000.0,"over_16ms":_count_over(warm_steps,16000),"over_33ms":_count_over(warm_steps,33000)}
	slowest.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.ms)>float(b.ms))
	report["slowest_steps"]=slowest.slice(0,int(_arg("slowest","25")))
	if trace.enabled:
		var traced:Dictionary={}
		for key:String in trace.totals:traced[key]=snappedf(float(trace.totals[key].microseconds)/1000.0/warm_days,.01)
		report["trace_ms_per_day"]=_sorted_desc(traced)
		var calls:Dictionary={}
		for key:String in trace.totals:calls[key]=snappedf(float(trace.totals[key].calls)/warm_days,.1)
		report["trace_calls_per_day"]=calls
	var out_name:=_arg("save-out","")
	if out_name!="":
		var saved:=saves.save_game(out_name)
		report["saved"]=saved.get("ok",false)
		var file:=FileAccess.open(saves.slot_path(out_name),FileAccess.READ)
		report["saved_bytes"]=file.get_length() if file else -1
		if file:file.close()
	var compare_name:=_arg("compare","")
	if compare_name!="" and out_name!="":
		var before:=saves._read_payload(compare_name);var after:=saves._read_payload(out_name)
		before.metadata.erase("saved_unix");after.metadata.erase("saved_unix")
		var diff:={"mismatches":[],"mismatch_count":0,"rounding":[],"rounding_count":0}
		var ignored:=_arg("ignore-keys","").split(",",false)
		_compare(before,after,"world",diff,ignored,float(_arg("tolerance","1e-9")))
		report["state_mismatches"]=diff.mismatches
		report["state_mismatch_count"]=diff.mismatch_count
		report["float_rounding_diffs"]=diff.rounding
		report["float_rounding_count"]=diff.rounding_count
	if "--outcomes" in args:
		report["outcomes"]=_outcomes()
		print("PACE_OUTCOMES ",JSON.stringify(report.outcomes))
	print("PACE_SUMMARY ",JSON.stringify({"year":snappedf(report.year,.1),"mean_ms_per_day":snappedf(report.mean_ms_per_day,.1),"player_ms_per_day":snappedf(report.player_ms_per_day,.1),"rivals_ms_per_day":snappedf(report.rivals_ms_per_day,.1),"steps":report.get("steps",{}),"saved_bytes":report.get("saved_bytes",-1),"state_mismatch_count":report.get("state_mismatch_count",null),"float_rounding_count":report.get("float_rounding_count",null),"state_mismatches":report.get("state_mismatches",null)}))
	var json_path:=_arg("json","res://artifacts/pace_benchmark.json")
	var out:=FileAccess.open(json_path,FileAccess.WRITE)
	if out:out.store_string(JSON.stringify(report,"  "));out.close()
	print("PACE_DONE ",json_path)
	terrain.free();WorldSimulation.clear();get_tree().quit(0)

## --frames: the game's own terrain scene at a chosen speed (default 5), its
## frame loop scheduling the days, for [--seconds=60] after the map settles.
## --render-cost=MS stands in for drawing (headless draws nothing). Prints
## the same PERF line the player's log carries, plus the frame phases.
func _frames(load_ms:float)->void:
	var began:=Time.get_ticks_usec()
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for node in get_tree().root.get_children():
		if node!=self and node!=terrain:node.set_process(false);node.set_physics_process(false)
	await get_tree().process_frame
	var settle_began:=Time.get_ticks_msec()
	var idle:=0
	while idle<30 and Time.get_ticks_msec()-settle_began<60000:
		await get_tree().process_frame
		idle=idle+1 if terrain.terrain_patch_job==null else 0
	print("PACE_SCENE_READY_MS ",(Time.get_ticks_usec()-began)/1000," load_ms ",roundi(load_ms))
	# --quiet=a,b: diagnostics only; stops those children of the scene from
	# processing (e.g. hud) to find what makes a frame long.
	if "--quiet-children" in OS.get_cmdline_user_args():
		for child:Node in terrain.get_children():child.process_mode=Node.PROCESS_MODE_DISABLED
	var quiet_from:=int(_arg("quiet-range","-1,-1").split(",")[0]);var quiet_to:=int(_arg("quiet-range","-1,-1").split(",")[1])
	var listed:=0
	for child:Node in terrain.get_children():
		var script:Script=child.get_script()
		var path:String=script.resource_path if script else ""
		var processing:=child.is_processing() or child.is_physics_processing()
		if listed>=quiet_from and listed<=quiet_to:child.process_mode=Node.PROCESS_MODE_DISABLED
		if "--list-children" in OS.get_cmdline_user_args():
			print("PACE_CHILD ",listed," ",child.name," ",child.get_class()," ",path," processing=",processing," descendants=",_count_processing(child))
			if _arg("list-under","")==str(listed):_list_processing(child,"  ")
		listed+=1
	for name:String in _arg("quiet","").split(",",false):
		var node:Node=terrain.get(name) if name in terrain else terrain.get_node_or_null(name)
		if node!=null:node.process_mode=Node.PROCESS_MODE_DISABLED;print("PACE_QUIET ",name)
	var render_usec:=int(float(_arg("render-cost","14"))*1000.0)
	var seconds:=float(_arg("seconds","60"))
	var trace=preload("res://scripts/performance_trace.gd")
	trace.enabled=true;trace.totals.clear()
	var meter=preload("res://scripts/perf_meter.gd")
	terrain._set_game_speed(float(_arg("speed","5")))
	await get_tree().process_frame
	await get_tree().process_frame
	var start_day:=float(GameState.elapsed_days)
	var start:=Time.get_ticks_usec()
	var frames:=PackedFloat32Array()
	var last:=start
	var long_frames:Array=[]
	var before:Dictionary={}
	var jobs:=preload("res://scripts/day_job.gd")
	while Time.get_ticks_usec()-start<int(seconds*1000000.0):
		for key:String in trace.totals:before[key]=int(trace.totals[key].microseconds)
		var steps_before:=jobs.slow_steps.size()
		await get_tree().process_frame
		if render_usec>0:OS.delay_usec(render_usec)
		var now:=Time.get_ticks_usec()
		frames.append((now-last)/1000.0)
		if now-last>100000 and long_frames.size()<40:
			# What a long frame spent its time on (traced phases over 5 ms).
			var spent:Dictionary={}
			for key:String in trace.totals:
				var delta:=int(trace.totals[key].microseconds)-int(before.get(key,0))
				if delta>5000:spent[key]=delta/1000
			long_frames.append({"ms":(now-last)/1000,"day":int(GameState.elapsed_days),"spent":spent,"slow_steps":jobs.slow_steps.slice(steps_before),
				"process_ms":snappedf(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,.1),"physics_ms":snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,.1),
				"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT)})
		last=now
	var elapsed:=(last-start)/1000000.0
	print("PACE_PERF ",meter.line(last))
	var sorted:=frames.duplicate();sorted.sort()
	var phases:Dictionary={}
	for key:String in trace.totals:phases[key]=snappedf(float(trace.totals[key].microseconds)/1000.0/maxf(.001,elapsed),.1)
	var report:={"seconds":elapsed,"days":float(GameState.elapsed_days)-start_day,"days_per_s":(float(GameState.elapsed_days)-start_day)/maxf(.001,elapsed),"fps":frames.size()/maxf(.001,elapsed),"p50_ms":sorted[sorted.size()/2],"p95_ms":sorted[int(sorted.size()*.95)],"max_ms":sorted[-1],"over_50ms":Array(sorted).filter(func(v:float)->bool:return v>50.0).size(),"render_cost_ms":render_usec/1000.0,"phase_ms_per_s":_sorted_desc(phases)}
	var slow:Array=preload("res://scripts/day_job.gd").slow_steps.duplicate()
	slow.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.usec)>int(b.usec))
	report["slow_steps"]=slow.slice(0,30)
	report["long_frames"]=long_frames
	report["slow_step_count"]=slow.size()
	print("PACE_FRAMES ",JSON.stringify(report))
	var out:=FileAccess.open(_arg("json","res://artifacts/pace_frames.json"),FileAccess.WRITE)
	if out:out.store_string(JSON.stringify(report.merged({"frames_ms":frames}),"  "));out.close()
	terrain._set_game_speed(0)
	WorldSimulation.flush_day()
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame;get_tree().quit(0)

## Each owner's state in aggregate, for comparing step lengths (day_span.gd).
func _outcomes()->Dictionary:
	var result:Dictionary={}
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		result[id]=WorldSimulation.scoped(id,func()->Dictionary:
			var state=WorldSimulation.state
			var m:Dictionary=state.simulation_metrics
			var stock:=0.0
			for key in state.resource_stockpiles:
				if String(key)!="Freshwater" and String(key)!="Food":stock+=maxf(0,float(state.resource_stockpiles[key]))
			var food:=0.0
			for key in state.food_stocks:food+=maxf(0,float(state.food_stocks[key]))
			return {"day":int(state.elapsed_days),"population":snappedf(state.population_exact,.01),"food":snappedf(food,.1),"stock":snappedf(stock,.1),"health":snappedf(state.population_health,.001),
				"cohesion":snappedf(float(m.get("cohesion",0)),.001),"knowledge":snappedf(float(m.get("knowledge",0)),.001),"discoveries":state.known_discoveries.size(),"cities":state.player_settlements.size(),
				"housing":state.housing_capacity,"troops":int(WorldSimulation.military.home_army.get("troops",0)),"projects":state.settlement_completed.size()}
		)
	return result

func _list_processing(node:Node,indent:String)->void:
	for child:Node in node.get_children():
		if _count_processing(child)>0:
			var script:Script=child.get_script()
			print("PACE_UNDER ",indent,child.name," ",script.resource_path if script else child.get_class()," processing=",child.is_processing())
			_list_processing(child,indent+"  ")

func _count_processing(node:Node)->int:
	var n:=1 if node.is_processing() else 0
	for child:Node in node.get_children():n+=_count_processing(child)
	return n

## Why each rival steps as often as it does (world_simulation.gd _span_waits).
func _census()->void:
	var contact:Dictionary={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		contact[String(civ.id)]=int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))
	for id:String in WorldSimulation.actors:
		var actor:Dictionary=WorldSimulation.actors[id]
		WorldSimulation.scoped(id,func()->void:
			var state=WorldSimulation.state
			var military=WorldSimulation.military
			var moving:=0
			for army:Dictionary in military.field_armies:
				if String(army.get("status","stationed"))!="stationed":moving+=1
			var towns_dry:=[]
			for city:Dictionary in state.player_settlements:
				if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
				var m:Dictionary=city.get("resource_metrics",{})
				towns_dry.append("%s/f%d/p%d" % [snappedf(float(m.get("water_intake_ratio",0.0)),.01),int(m.get("food_days",0.0)),int(city.get("population",0))])
			print("PACE_CENSUS ",id," pop=",int(state.population_exact)," contact=",contact.get(id,-1)," calm=",preload("res://scripts/day_span.gd").calm()," food_span=",preload("res://scripts/day_span.gd").food_span()," limit=",WorldSimulation._span_limit_for(id)," last_gap=",actor.get("last_gap",1)," wars=",WorldSimulation.world.player_effects().get("war_count",0)," moving_armies=",moving," engaged=",not military.active_engagement.is_empty()," threat=",not military.active_threat.is_empty()," siege=",not military.active_siege.is_empty()," water=",snappedf(float(state.simulation_metrics.get("water_intake_ratio",0.0)),.01)," towns_water=",towns_dry," convoy=",state.convoy_traveling or bool(state.settlement_convoy.get("active",false))," recovery=",military.recovery.home_unavailable())
		)

## Compares two saved worlds. A key in `ignored` may be added or dropped (a
## field an optimization keeps); floats within `tolerance` (relative) differ
## only by the order of their additions and are counted apart.
func _compare(before:Variant,after:Variant,path:String,diff:Dictionary,ignored:PackedStringArray,tolerance:float)->void:
	if before==after:return
	for part:String in _ignored_paths:
		if part in path:return
	if before is Dictionary and after is Dictionary:
		for key:Variant in before:
			if not after.has(key):
				if String(key) not in ignored:_mismatch(diff,path+"."+str(key)+" missing")
			else:_compare(before[key],after[key],path+"."+str(key),diff,ignored,tolerance)
		for key:Variant in after:
			if not before.has(key) and String(key) not in ignored:_mismatch(diff,path+"."+str(key)+" added")
	elif before is Array and after is Array and before.size()==after.size():
		for index in before.size():_compare(before[index],after[index],path+"["+str(index)+"]",diff,ignored,tolerance)
	elif (before is float or before is int) and (after is float or after is int):
		var a:=float(before);var b:=float(after)
		if absf(a-b)<=tolerance*maxf(1.0,maxf(absf(a),absf(b))):
			diff.rounding_count+=1
			if diff.rounding.size()<20:diff.rounding.append("%s %s -> %s" % [path,str(a),str(b)])
		else:_mismatch(diff,"%s %s -> %s" % [path,str(before),str(after)])
	else:_mismatch(diff,path+(" size %d -> %d" % [before.size(),after.size()] if before is Array and after is Array else ""))

## --ignore-paths=a,b: parts of the world a change deliberately reshapes
## (e.g. economy_history after its old entries are slimmed).
var _ignored_paths:PackedStringArray=PackedStringArray()

func _mismatch(diff:Dictionary,text:String)->void:
	diff.mismatch_count+=1
	if diff.mismatches.size()<40:diff.mismatches.append(text)

## Folds one day's nested timings (see world_simulation.gd begin_day) into
## totals keyed "owner/label" or "owner/group/label" (rivals folded together).
func _accumulate(totals:Dictionary,timings:Dictionary)->void:
	for key:String in timings:
		var value:Variant=timings[key]
		if not value is Dictionary:continue
		if (value as Dictionary).has("microseconds"):
			totals["world/"+key]=int(totals.get("world/"+key,0))+int(value.microseconds)
			continue
		var owner:="player" if key=="player_phases" else "player/secondary" if key=="player_secondary" else "rival"
		_fold(totals,owner,value)

func _fold(totals:Dictionary,prefix:String,table:Dictionary)->void:
	for key:String in table:
		var value:Variant=table[key]
		if not value is Dictionary:continue
		if (value as Dictionary).has("microseconds"):
			var name:="%s/%s" % [prefix,key]
			totals[name]=int(totals.get(name,0))+int(value.microseconds)
		else:_fold(totals,"%s/%s" % [prefix,key],value)

func _timing_table(totals:Dictionary,days:int)->Dictionary:
	var result:Dictionary={}
	for key:String in totals:result[key]=snappedf(float(totals[key])/1000.0/days,.01)
	return _sorted_desc(result)

func _per_day(table:Dictionary,days:int)->Dictionary:
	var result:Dictionary={}
	for key:String in table:result[key]=snappedf(float(table[key])/1000.0/days,.01)
	return _sorted_desc(result)

func _sorted_desc(table:Dictionary)->Dictionary:
	var keys:=table.keys()
	keys.sort_custom(func(a,b)->bool:return float(table[a])>float(table[b]))
	var result:Dictionary={}
	for key in keys:result[key]=table[key]
	return result

func _count_over(values:PackedInt32Array,limit:int)->int:
	var n:=0
	for v in values:if v>limit:n+=1
	return n
