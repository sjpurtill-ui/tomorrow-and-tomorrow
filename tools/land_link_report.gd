extends RefCounted
## Diagnostic ("--capture-land-links"): on the real terrain, whether each
## people's home can be reached from ours by land: the scouts' planner, the
## armies' planner, and a plain flood over dry ground at a few cell sizes.

static func lines()->PackedStringArray:
	var out:PackedStringArray=[]
	var world:Node=CivilizationSystem
	var home:Vector2=world.player_world_origin
	for civ:Dictionary in world.civilizations:
		var at:Vector2=world._civilization_world_position(civ)
		if at.distance_to(home)>4000.0:continue
		var scout:Dictionary=world._plan_scout_land_route(home,at)
		var army:Dictionary=preload("res://scripts/army_land_route.gd").find(home,at,Callable(world,"_scout_land_at"),false,{})
		var floods:=""
		for cell:float in [20.0,8.0,3.0]:
			floods+=" flood@%dkm=%s" % [int(cell),str(_flood(world,home,at,cell))]
		out.append("%s %d km: home dry=%s theirs dry=%s | scouts' planner ok=%s km=%s (%s) | armies' planner %s |%s" % [String(civ.get("name","")),roundi(at.distance_to(home)),str(world._scout_land_at(home)),str(world._scout_land_at(at)),str(scout.get("ok",false)),str(roundi(float(scout.get("distance_km",0.0)))),String(scout.get("reason","")).substr(0,60),("ok %d km" % roundi(float(army.get("length_km",0.0)))) if not army.has("error") else String(army.get("reason","")),floods])
	return out

## Whether dry ground connects a to b on a grid of `cell` km (8 neighbours), within a bounded box.
static func _flood(world:Node,a:Vector2,b:Vector2,cell:float)->bool:
	var box:=Rect2(a,Vector2.ZERO).expand(b).grow(1200.0)
	var start:=_snap_dry(world,a,cell);var goal:=_snap_dry(world,b,cell)
	if not start.is_finite() or not goal.is_finite():return false
	var gk:=Vector2i(roundi(goal.x/cell),roundi(goal.y/cell))
	var seen:={}
	var queue:Array[Vector2i]=[Vector2i(roundi(start.x/cell),roundi(start.y/cell))]
	seen[queue[0]]=true
	var head:=0
	while head<queue.size() and seen.size()<900000:
		var k:=queue[head];head+=1
		if k==gk:return true
		for d:Vector2i in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
			var n:=k+d
			if seen.has(n):continue
			var p:=Vector2(n)*cell
			if not box.has_point(p) or not bool(world._scout_land_at(p)):continue
			seen[n]=true;queue.append(n)
	return false

static func _snap_dry(world:Node,p:Vector2,cell:float)->Vector2:
	var base:=Vector2(roundf(p.x/cell),roundf(p.y/cell))
	for r in 6:
		for dx in range(-r,r+1):
			for dy in range(-r,r+1):
				var q:=(base+Vector2(dx,dy))*cell
				if bool(world._scout_land_at(q)):return q
	return Vector2.INF
