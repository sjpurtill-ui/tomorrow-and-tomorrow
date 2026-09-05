extends Node
const Index=preload("res://tests/spatial_experiment_index.gd")
const Urban=preload("res://tests/spatial_experiment_urban.gd")
var results:Dictionary={"index":[],"urban":[],"world":{}}
var failures:Array[String]=[]

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	await get_tree().process_frame
	await _index_workloads()
	await _urban_workloads()
	await _offscreen_projection()
	await _actual_world()
	results["failures"]=failures
	results["coordinate_precision"]={"one_meter_delta_at_origin_km":Vector2(0.001,0).x,"one_meter_delta_at_20000km_km":(Vector2(20000,0)+Vector2(0.001,0)).x-Vector2(20000,0).x,"note":"Godot Vector2 float32; tactical windows need local coordinates at distant world positions."}
	var file:=FileAccess.open("res://artifacts/spatial-cpu.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(results,"\t")); file.close()
	print("SPATIAL_CPU_DONE ",JSON.stringify(results))
	get_tree().quit(0 if failures.is_empty() else 1)

func _stats(samples:Array[float])->Dictionary:
	samples.sort()
	return {"p50_ms":samples[samples.size()/2],"p95_ms":samples[mini(samples.size()-1,int(samples.size()*0.95))],"p99_ms":samples[mini(samples.size()-1,int(samples.size()*0.99))],"max_ms":samples.back(),"samples":samples.size()}

func _index_workloads()->void:
	for total in [1000,10000,100000]:
		var points:=PackedVector2Array()
		var rng:=RandomNumberGenerator.new(); rng.seed=5137
		for id in total:
			# First384 are local tactical aggregates; other points are distant world
			# entities, not citizens. No population-to-object expansion implied.
			points.append(Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1)) if id<384 else Vector2(rng.randf_range(10,20000),rng.randf_range(10,20000)))
		for size in [0.1,0.25,1.0]:
			var index:=Index.new()
			var memory:=OS.get_static_memory_usage()
			var started:=Time.get_ticks_usec()
			index.build(points,size)
			var build_ms:=float(Time.get_ticks_usec()-started)/1000.0
			var memory_delta:=OS.get_static_memory_usage()-memory
			var linear:Array[float]=[]; var indexed:Array[float]=[]; var moves:Array[float]=[]
			for sample in 120:
				var query:=Vector2(sin(sample*0.1),cos(sample*0.1))*0.6
				started=Time.get_ticks_usec()
				var expected:=PackedInt32Array()
				for id in points.size():
					if points[id].distance_squared_to(query)<=0.0625: expected.append(id)
				linear.append(float(Time.get_ticks_usec()-started)/1000.0)
				started=Time.get_ticks_usec()
				var actual:=index.nearby(query,0.25)
				indexed.append(float(Time.get_ticks_usec()-started)/1000.0)
				actual.sort(); expected.sort()
				if actual!=expected: failures.append("Index differs from exact continuous-distance query")
				started=Time.get_ticks_usec()
				for id in 384:
					points[id]+=Vector2(0.0005,0.0003)
					index.move(id,points[id])
				moves.append(float(Time.get_ticks_usec()-started)/1000.0)
			results.index.append({"world_entities":total,"bucket_m":size*1000,"occupied_buckets":index.buckets.size(),"build_ms":build_ms,"tracked_memory_bytes":memory_delta,"linear":_stats(linear),"indexed":_stats(indexed),"move384":_stats(moves),"raw_position_bytes":points.to_byte_array().size()})
			var occupancy_times:Array[float]=[]
			var local_ids:=PackedInt32Array()
			for id in 384: local_ids.append(id)
			for sample in 120:
				started=Time.get_ticks_usec()
				var occupancy:=index.control_occupancy(local_ids,0.25)
				occupancy_times.append(float(Time.get_ticks_usec()-started)/1000.0)
				var accounted:=0
				for counts in occupancy.values(): accounted+=counts.x+counts.y
				if accounted!=38400: failures.append("Control occupancy lost or duplicated personnel")
			results.index[-1]["control384"]=_stats(occupancy_times)
			print("INDEX_DONE ",total," ",size)
			await get_tree().process_frame

func _urban_workloads()->void:
	for cell in [0.01,0.025,0.05,0.1,0.25]:
		for count in [1,4,12]:
			var fronts:Array=[]
			var memory:=OS.get_static_memory_usage()
			var started:=Time.get_ticks_usec()
			for id in count:
				var front:=Urban.new(); front.build(cell,id); fronts.append(front)
			var build_ms:=float(Time.get_ticks_usec()-started)/1000.0
			var memory_delta:=OS.get_static_memory_usage()-memory
			var paths:Array[float]=[]; var ticks:Array[float]=[]; var controls:Array[float]=[]
			var failed:=0; var max_points:=0; var max_compressed:=0; var obstacle_crossings:=0
			var saved_paths:Array=[]
			for sample in 120:
				started=Time.get_ticks_usec()
				for front in fronts: front.changed_control(sample)
				controls.append(float(Time.get_ticks_usec()-started)/1000.0)
				var tick_ms:=0.0
				for front in fronts:
					started=Time.get_ticks_usec()
					var path:PackedVector2Array=front.path(sample)
					var path_ms:=float(Time.get_ticks_usec()-started)/1000.0
					paths.append(path_ms); tick_ms+=path_ms
					if path.is_empty(): failed+=1
					max_points=maxi(max_points,path.size())
					var short:PackedVector2Array=front.compressed(path)
					max_compressed=maxi(max_compressed,short.size())
					# Check physical geometry at5m intervals, including what coarse
					# grids failed to sample. Cell-only success is not route correctness.
					if sample==0:
						for segment in range(1,path.size()):
							var steps:=maxi(1,ceili(path[segment-1].distance_to(path[segment])/0.005))
							for part in range(steps+1):
								if Urban.building_at(path[segment-1].lerp(path[segment],float(part)/steps),front.identity): obstacle_crossings+=1
						var saved:Array=[]
						for point in short: saved.append([point.x,point.y])
						saved_paths.append(saved)
				ticks.append(tick_ms)
			var unreachable:Array[float]=[]
			for sample in 16:
				started=Time.get_ticks_usec()
				for front in fronts:
					if not front.impossible_path().is_empty(): failures.append("Enclosed destination incorrectly reachable")
				unreachable.append(float(Time.get_ticks_usec()-started)/1000.0)
			started=Time.get_ticks_usec()
			var serialized:=JSON.stringify(saved_paths)
			var save_ms:=float(Time.get_ticks_usec()-started)/1000.0
			results.urban.append({"cell_m":cell*1000,"fronts":count,"cells":fronts[0].cells*fronts[0].cells*count,"build_ms":build_ms,"tracked_memory_bytes":memory_delta,"path":_stats(paths),"all_fronts_replan":_stats(ticks),"unreachable_all_fronts":_stats(unreachable),"control25_per_front":_stats(controls),"failed_paths":failed,"geometry_crossings":obstacle_crossings,"max_path_points":max_points,"max_compressed_points":max_compressed,"saved_routes_bytes":serialized.to_utf8_buffer().size(),"save_ms":save_ms})
			print("URBAN_DONE ",cell," ",count)
			await get_tree().process_frame
	var adaptive_memory:=OS.get_static_memory_usage()
	var adaptive_start:=Time.get_ticks_usec()
	var adaptive:Array=[]
	for id in 12:
		var neighborhood:=Urban.new(); neighborhood.build(0.025,id); adaptive.append(neighborhood)
		var contact:=Urban.new(); contact.build(0.01,id,0.4); adaptive.append(contact)
	results["adaptive"]={"fronts":12,"coarse_window_km":2,"coarse_m":25,"contact_window_km":0.4,"contact_m":10,"build_ms":float(Time.get_ticks_usec()-adaptive_start)/1000.0,"tracked_memory_bytes":OS.get_static_memory_usage()-adaptive_memory,"cells":12*(81*81+41*41),"note":"Allocation only; cross-level portal routing is not implemented."}

func _actual_world()->void:
	GameState.reset_for_new_world(24681357)
	GameState.ensure_population_total(1000000000)
	CivilizationSystem.reset_for_new_world()
	var before:=JSON.stringify(CivilizationSystem.export_state())
	var ticks:Array[float]=[]
	for day in range(30,901,30):
		var started:=Time.get_ticks_usec()
		CivilizationSystem.advance_to_day(day)
		ticks.append(float(Time.get_ticks_usec()-started)/1000.0)
		await get_tree().process_frame
	var started:=Time.get_ticks_usec()
	var after:=JSON.stringify(CivilizationSystem.export_state())
	results.world={"rivals":CivilizationSystem.civilizations.size(),"player_population":GameState.population_total,"days":900,"monthly_advance":_stats(ticks),"export_ms":float(Time.get_ticks_usec()-started)/1000.0,"save_bytes":after.to_utf8_buffer().size(),"hidden_world_changed":before!=after,"public_contacts":CivilizationSystem.contact_encounters_snapshot().size()}
	if before==after: failures.append("Unseen world stopped evolving")

func _offscreen_projection()->void:
	var rows:Array=[]
	for count in [1000,10000,100000]:
		var positions:=PackedVector2Array(); var initial:=PackedVector2Array(); var velocities:=PackedVector2Array()
		var food:=PackedFloat64Array()
		for id in count:
			initial.append(Vector2(id%1000,id/1000)); velocities.append(Vector2(0.012,0.008)); food.append(100.0)
		positions=initial.duplicate()
		var started:=Time.get_ticks_usec()
		for day in 30:
			for id in count:
				positions[id]+=velocities[id]
				food[id]=maxf(0.0,food[id]-1.0)
		var stepped_ms:=float(Time.get_ticks_usec()-started)/1000.0
		started=Time.get_ticks_usec()
		var max_error:=0.0
		# Only384 enter an active front at day30. Their unseen journey and stores
		# are projected at promotion, not frozen when outside the camera.
		for id in mini(384,count):
			var projected:=initial[id]+velocities[id]*30.0
			max_error=maxf(max_error,projected.distance_to(positions[id]))
			if not is_equal_approx(food[id],maxf(0.0,100.0-30.0)): failures.append("Projected supplies disagree")
		var promote_ms:=float(Time.get_ticks_usec()-started)/1000.0
		rows.append({"entities":count,"thirty_daily_steps_ms":stepped_ms,"promote384_ms":promote_ms,"max_position_difference_km":max_error,"note":"Exact constant-rate stores; float32 repeated-motion drift measured. Collisions, encounters and changed orders require scheduled events and rebasing, not implemented."})
		await get_tree().process_frame
	results["offscreen_projection"]=rows
