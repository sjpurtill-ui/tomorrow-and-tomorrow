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
	var mode:="detail" if "--detail" in OS.get_cmdline_user_args() else "after" if "--after" in OS.get_cmdline_user_args() else "before"
	var saves:=Snapshot.new();add_child(saves)
	var loaded:=saves.load_game("fixture")
	if loaded.has("error"):print(loaded);get_tree().quit(1);return
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.civic_api_enabled=false
	for id in WorldSimulation.actors:WorldSimulation.actors[id].systems.GameState.civic_api_enabled=false
	if "--map-profile" in OS.get_cmdline_user_args():
		await map_profile();return
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
	for i in (2 if mode=="detail" else 8):
		var timings:Dictionary={"enabled":true}
		var start:=Time.get_ticks_usec()
		WorldSimulation.advance_day(day+i+1,terrain._discovery_context(),Callable(),timings)
		report.samples.append({"day":day+i+1,"ms":(Time.get_ticks_usec()-start)/1000.0,"timings":timings})
		print("PROFILE_DAY ",day+i+1," ",report.samples[-1].ms)
		await get_tree().process_frame
	report["simulation_cpu_seconds"]=cpu_seconds()-cpu_start
	report["detail"]=preload("res://scripts/performance_trace.gd").totals
	var saved:=saves.save_game(mode)
	assert(saved.get("ok",false))
	if mode=="after":
		var before:=saves._read_payload("before");var after:=saves._read_payload("after")
		before.metadata.erase("saved_unix");after.metadata.erase("saved_unix")
		var comparator=load("res://tools/campaign_performance_probe.gd").new()
		comparator.compare(before,after,"world")
		report["state_mismatches"]=comparator.failures.duplicate();comparator.free()
	var file:=FileAccess.open("res://artifacts/year71_"+mode+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("PROFILE_DONE ",mode," state mismatches ",report.get("state_mismatches",[]))
	terrain.free();WorldSimulation.clear();get_tree().quit(0 if report.get("state_mismatches",[]).is_empty() else 1)

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
