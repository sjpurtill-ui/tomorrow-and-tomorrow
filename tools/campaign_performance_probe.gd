extends Node
## Full-state, headless replay of an explicitly copied mature campaign.
## Never reads or writes ordinary player userdata. See docs/performance/CAMPAIGN_COST.md.
const DAYS := 24
var failures: Array[String] = []

func _ready() -> void:
	if DisplayServer.get_name() != "headless" or not OS.get_user_data_dir().ends_with("TomorrowCampaignPerformanceTests"):
		push_error("Daily cost replay requires headless mode and private TomorrowCampaignPerformanceTests userdata.")
		get_tree().quit(2); return
	var mode := "optimized" if "--compare-baseline" in OS.get_cmdline_user_args() else "baseline"
	var loaded := SaveSystem.load_game("performance_snapshot")
	if not bool(loaded.get("ok",false)):
		push_error("Private performance_snapshot fixture could not be loaded."); get_tree().quit(2); return
	if not WorldSimulation.enabled:
		push_error("This replay requires a shared-rule campaign.");get_tree().quit(2);return
	GameState.civic_api_enabled=false
	var terrain = load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain._set_game_speed(0); terrain.set_process(false)
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	await get_tree().process_frame
	var start_day := int(GameState.elapsed_days)
	var elapsed: Array[float] = []
	for index in DAYS:
		var day := start_day+index+1
		var start := Time.get_ticks_usec()
		WorldSimulation.advance_day(day,terrain._discovery_context(),terrain._process_local_settlement_day)
		elapsed.append((Time.get_ticks_usec()-start)/1000.0)
		for id: String in WorldSimulation.actors:
			if int(WorldSimulation.actors[id].last_day)!=day:failures.append("Missing opponent day "+id)
		await get_tree().process_frame
	var saved := SaveSystem.save_game("daily_cost_"+mode)
	if not bool(saved.get("ok",false)):failures.append("Could not save replay outcome")
	if mode=="optimized":
		var before := SaveSystem._read_payload("daily_cost_baseline")
		var after := SaveSystem._read_payload("daily_cost_optimized")
		if before.is_empty() or after.is_empty():failures.append("Missing comparison payload")
		else:
			# Wall-clock save timestamps do not describe simulation state.
			before.metadata.erase("saved_unix");after.metadata.erase("saved_unix")
			compare(before,after,"world")
	var total := 0.0
	for value: float in elapsed:total+=value
	var sorted := elapsed.duplicate();sorted.sort()
	print("DAILY_COST ",JSON.stringify({"mode":mode,"start_day":start_day,"days":DAYS,"opponents":WorldSimulation.actors.size(),"mean_ms":total/DAYS,"median_ms":sorted[DAYS/2],"p95_ms":sorted[ceili(DAYS*.95)-1],"max_ms":sorted[-1],"samples_ms":elapsed,"simulation_state_matches":mode=="optimized" and failures.is_empty(),"failures":failures}))
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func compare(before: Variant, after: Variant, path: String) -> void:
	if "--allow-observer-summary" in OS.get_cmdline_user_args() and path.ends_with(".local_metrics") and ".strategic_regions[" in path and before is Dictionary and after is Dictionary:
		if after.size()!=3:failures.append(path+" unexpected observer fields")
		for key in ["material_capacity","logistics","food_days"]:
			if after.get(key)!=float(before.get(key,0)):failures.append(path+"."+key+" changed")
		return
	if before==after or failures.size()>=12:return
	if before is Dictionary and after is Dictionary:
		for key: Variant in before:
			if not after.has(key):failures.append(path+"."+str(key)+" missing")
			else:compare(before[key],after[key],path+"."+str(key))
		for key: Variant in after:
			if not before.has(key):failures.append(path+"."+str(key)+" added")
	elif before is Array and after is Array and before.size()==after.size():
		for index in before.size():compare(before[index],after[index],path+"["+str(index)+"]")
	else:failures.append(path)
