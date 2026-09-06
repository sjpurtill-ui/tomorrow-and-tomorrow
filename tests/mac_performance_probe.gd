extends Node
func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(184271)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain.game_speed=0
	terrain.set_process(false)
	await get_tree().process_frame
	var report:Dictionary={}
	for method in ["_refresh_contact_encounter_markers","_refresh_foreign_formation_markers","_refresh_player_field_army_markers","_refresh_player_scout_route_markers","_refresh_settlement_network"]:
		var times:Array[float]=[]
		for i in 20:
			var start:=Time.get_ticks_usec()
			terrain.call(method)
			times.append(float(Time.get_ticks_usec()-start)/1000)
		times.sort()
		report[method]={"median_ms":times[10],"max_ms":times[-1]}
	# Warm the terrain jobs, then alternate both schedules in the same process.
	for i in 240:terrain._process(1.0/60)
	var before_day:=GameState.elapsed_days
	var before_population:=GameState.population_total
	var schedules:Dictionary={"every_frame":[],"ten_hz":[]}
	for round_index in 3:
		for schedule in ["every_frame","ten_hz"]:
			terrain.map_snapshot_elapsed=0.0
			var refreshes:int=terrain.map_snapshot_refreshes
			var started:=Time.get_ticks_usec()
			for i in 120:
				if schedule=="every_frame":terrain.map_snapshot_elapsed=0.1
				terrain._process(1.0/60)
			schedules[schedule].append({"cpu_ms":float(Time.get_ticks_usec()-started)/1000,"snapshot_refreshes":terrain.map_snapshot_refreshes-refreshes})
	var failures:=0
	for sample in schedules.ten_hz:
		if sample.snapshot_refreshes<19 or sample.snapshot_refreshes>21:failures+=1
	for sample in schedules.every_frame:
		if sample.snapshot_refreshes!=120:failures+=1
	if GameState.elapsed_days!=before_day or GameState.population_total!=before_population:failures+=1
	report["same_process_schedules"]=schedules
	report["failures"]=failures
	print("MAC_CPU_PROBE: ",JSON.stringify(report))
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
