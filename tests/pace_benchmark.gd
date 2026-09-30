extends Node
## PACE BENCHMARK: what a world day costs, by owner and by step, from a copied
## save. Headless and opt-in; never reads or writes the player's save slots.
##   <godot> --headless --path <worktree> res://tests/pace_benchmark.tscn -- --pace-benchmark
##       --save=<absolute path to a COPY of a .save> [--days=30] [--warm=2]
##       [--span=N] [--trace] [--save-out=NAME] [--compare=NAME] [--json=PATH]
##       [--ignore-keys=a,b] [--tolerance=1e-9]
## Days run as the frame loop runs them: begin_day, then one scheduled step at
## a time, so the longest single steps (which set the worst frames) show too.
## --save-out writes the world after the run to res://artifacts/pace_NAME.save
## and reports its size; --compare=NAME compares the world after the run with
## an earlier --save-out (the same world must come out of the same days).
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
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	WorldSimulation.context_provider=terrain._civilization_geography
	WorldSimulation.surface_material_provider=terrain._civilization_surface_materials
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=GameState.settlement_founded_at
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
		for record:Dictionary in records:
			var owner:=String(record.owner)
			var usec:=int(record.usec)
			owners[owner]=int(owners.get(owner,0))+usec
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
	report["label_ms_per_day"]=_per_day(labels,warm_days)
	report["timings_ms_per_day"]=_timing_table(totals,warm_days)
	warm_steps.sort()
	if not warm_steps.is_empty():
		report["steps"]={"count_per_day":float(warm_steps.size())/warm_days,"p50_ms":warm_steps[warm_steps.size()/2]/1000.0,"p95_ms":warm_steps[int(warm_steps.size()*.95)]/1000.0,"p99_ms":warm_steps[int(warm_steps.size()*.99)]/1000.0,"max_ms":warm_steps[-1]/1000.0,"over_16ms":_count_over(warm_steps,16000),"over_33ms":_count_over(warm_steps,33000)}
	slowest.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.ms)>float(b.ms))
	report["slowest_steps"]=slowest.slice(0,25)
	if trace.enabled:
		var traced:Dictionary={}
		for key:String in trace.totals:traced[key]=snappedf(float(trace.totals[key].microseconds)/1000.0/warm_days,.01)
		report["trace_ms_per_day"]=_sorted_desc(traced)
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
	print("PACE_SUMMARY ",JSON.stringify({"year":snappedf(report.year,.1),"mean_ms_per_day":snappedf(report.mean_ms_per_day,.1),"player_ms_per_day":snappedf(report.player_ms_per_day,.1),"rivals_ms_per_day":snappedf(report.rivals_ms_per_day,.1),"steps":report.get("steps",{}),"saved_bytes":report.get("saved_bytes",-1),"state_mismatch_count":report.get("state_mismatch_count",null),"float_rounding_count":report.get("float_rounding_count",null),"state_mismatches":report.get("state_mismatches",null)}))
	var json_path:=_arg("json","res://artifacts/pace_benchmark.json")
	var out:=FileAccess.open(json_path,FileAccess.WRITE)
	if out:out.store_string(JSON.stringify(report,"  "));out.close()
	print("PACE_DONE ",json_path)
	terrain.free();WorldSimulation.clear();get_tree().quit(0)

## Compares two saved worlds. A key in `ignored` may be added or dropped (a
## field an optimization keeps); floats within `tolerance` (relative) differ
## only by the order of their additions and are counted apart.
func _compare(before:Variant,after:Variant,path:String,diff:Dictionary,ignored:PackedStringArray,tolerance:float)->void:
	if before==after:return
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
		var owner:="player" if key=="player_phases" else "rival"
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
