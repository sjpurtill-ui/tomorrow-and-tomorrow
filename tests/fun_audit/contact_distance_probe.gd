extends Node
## Measures the distance from the player's seeded start to every rival home.
func _ready()->void:
	var CS:=preload("res://scripts/civilization_start.gd")
	for seed_value in [424242,77013,112358,91420,5,8080,31337,2024]:
		GameState.reset_for_new_world(seed_value)
		CivilizationSystem.reset_for_new_world()
		var p:Vector2=CS.candidate(seed_value,0)
		var ds:Array=[]
		for civ:Dictionary in CivilizationSystem.civilizations:ds.append(roundi(p.distance_to(CivilizationSystem._civilization_world_position(civ))))
		ds.sort()
		print("seed ",seed_value," player ",p," nearest ",ds.slice(0,4))
	get_tree().quit(0)
