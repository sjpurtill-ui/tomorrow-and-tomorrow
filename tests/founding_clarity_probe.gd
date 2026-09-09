extends Node
func _ready()->void:call_deferred("run")
func run()->void:
	var terrain=load("res://scripts/local_terrain.gd").new()
	var failures:=0;var checked:=0
	for seed_value in [9241,741991,1788457137,1788994953,17,42,92026]:
		GameState.reset_for_new_world(seed_value)
		CivilizationSystem.reset_for_new_world()
		terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
		for seat in 13:
			var start=terrain._civilization_start(preload("res://scripts/civilization_start.gd").candidate(seed_value,seat))
			CivilizationSystem.revealed_areas=[{"x":start.x,"z":start.y,"radius":38.0}]
			var position=Vector3(start.x,terrain._height_at(start.x,start.y),start.y)
			var advice=terrain._founding_site_advice(position,true)
			checked+=1
			if not advice.valid:
				failures+=1
				print("MISMATCH ",seed_value," seat ",seat," pos ",position," dailywater ",terrain._river_distance_at(start.x,start.y)," sources ",terrain._founding_water_sources(position)," advice ",advice)
	print("FOUNDING STARTS checked=",checked," failures=",failures)
	terrain.free();WorldSimulation.clear();get_tree().quit(failures)
