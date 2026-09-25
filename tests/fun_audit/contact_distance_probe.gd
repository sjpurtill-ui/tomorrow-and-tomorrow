extends Node
## Measures the distance from the player's seeded start to every rival home,
## and how close each rival's standing expedition route passes the player.
func _ready()->void:
	var CS:=preload("res://scripts/civilization_start.gd")
	var nearest_all:Array=[]
	for seed_value in [424242,77013,112358,91420,5,8080,31337,2024,6,99,1234,555]:
		GameState.reset_for_new_world(seed_value)
		CivilizationSystem.reset_for_new_world()
		var p:Vector2=CS.candidate(seed_value,0)
		var ds:Array=[]
		for civ:Dictionary in CivilizationSystem.civilizations:ds.append(roundi(p.distance_to(CivilizationSystem._civilization_world_position(civ))))
		ds.sort()
		nearest_all.append(ds[0])
		var pass_km:=INF
		for f:Dictionary in CivilizationSystem.foreign_formations:
			if String(f.get("kind",""))!="expedition":continue
			var a:=Vector2(f.point_a);var b:=Vector2(f.point_b)
			pass_km=minf(pass_km,p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)))
		print("CONTACT_DISTANCE seed ",seed_value," nearest ",ds.slice(0,4)," closest_expedition_pass_km ",roundi(pass_km))
	nearest_all.sort()
	print("CONTACT_DISTANCE nearest-neighbour km sorted ",nearest_all)
	get_tree().quit(0)
