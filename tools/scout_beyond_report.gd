extends RefCounted
## Diagnostic ("--capture-scout-beyond"): what the scouts' search beyond the
## charts (scout_frontier.gd beyond) finds from home on the real terrain, round
## the compass, and how near each route's end comes to each people's home.

static func lines()->PackedStringArray:
	var out:PackedStringArray=[]
	var world:Node=CivilizationSystem
	var home:Vector2=world._scout_origin("").position
	var reach:float=world.scout_one_way_range(365)
	out.append("one-way range for a year %d km; staff status: %s" % [roundi(reach),String(world.scouting_staff.data.get("status","")).substr(0,90)])
	var staff_quote:Dictionary=world.scout_mission_quote(365,"open_world","",40,true)
	var plan:Dictionary=staff_quote.get("route_plan",{})
	out.append("staff quote for a year: can_dispatch=%s blocker=%s beyond=%s km=%d fresh=%d novelty=%.2f" % [str(staff_quote.get("can_dispatch",false)),String(staff_quote.get("blocker","")).substr(0,80),str(plan.get("beyond",false)),roundi(float(plan.get("distance_km",0.0))),roundi(float(plan.get("fresh_km",0.0))),float(plan.get("novelty",0.0))])
	for turn in range(0,16,3):
		var began:=Time.get_ticks_msec()
		var walker:RefCounted=preload("res://scripts/scout_frontier.gd").new(world,reach,0.0,home)
		var found:Dictionary=walker.beyond(reach,turn)
		var took:=Time.get_ticks_msec()-began
		if not bool(found.get("ok",false)):out.append("turn %d: nothing (%d ms)" % [turn,took]);continue
		var route:Array=found.route
		var end:=Vector2(float(route[-1].x),float(route[-1].z))
		var near:=""
		for civ:Dictionary in world.civilizations:
			var off:=float(world._closest_route_encounter(route,world._civilization_world_position(civ)).distance)
			if off<400.0:near+=" %s %d km" % [String(civ.name),roundi(off)]
		out.append("turn %d: %d km out %s, %d km of it new, %d points, ends %d km from home (%d ms); passes:%s" % [turn,roundi(float(found.distance_km)),String(found.planned_heading),roundi(walker.fresh_km(found)),route.size(),roundi(end.distance_to(home)),took,near if near!="" else " nobody within 400 km"])
	return out
