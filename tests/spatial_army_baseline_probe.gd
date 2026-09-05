extends SceneTree

func _initialize()->void:
	call_deferred("_run")

func _run()->void:
	AudioServer.set_bus_mute(0,true)
	var state:=root.get_node("GameState")
	var military:=root.get_node("MilitaryCampaign")
	state.reset_for_new_world(24681357)
	state.ensure_population_total(1000000)
	military.reset_for_new_world()
	military.set_process(false)
	var rows:Array=[]
	for count in [1,4,12]:
		military.field_armies.clear()
		for id in count:
			var army:Dictionary=military.simulator.create_formation_force("BENCHMARK",[{"id":id+1,"unit":"levy","weapon":"improvised","count":1000,"authorized_count":1000,"equipment":1000,"equipment_required":1000}],0.72,0.68)
			army.merge({"army_id":id+1,"status":"moving","position":{"x":0.0,"z":0.0},"origin_position":{"x":0.0,"z":0.0},"destination_position":{"x":10000.0,"z":0.0},"distance_total_km":10000.0,"distance_remaining_km":10000.0},true)
			military.field_armies.append(army)
		var times:Array[float]=[]
		for sample in 120:
			var started:=Time.get_ticks_usec()
			military._process_field_army_movement_day()
			times.append(float(Time.get_ticks_usec()-started)/1000.0)
		times.sort()
		rows.append({"armies":count,"p50_ms":times[60],"p95_ms":times[114],"p99_ms":times[118],"max_ms":times.back(),"actually_moved":military.field_armies[0].position.x>0.0,"note":"Actual current continuous strategic movement and supply update only; no building obstacles or battle."})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var file:=FileAccess.open("res://artifacts/spatial-army-baseline.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(rows,"\t")); file.close()
	print("SPATIAL_ARMY_BASELINE_DONE ",JSON.stringify(rows))
	quit()
