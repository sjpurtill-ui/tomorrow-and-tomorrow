extends RefCounted
## Bounded connected-ground search. Only returned charts and our own outgoing
## routes affect novelty; choosing a route never reveals its contents.
const NODE_LIMIT:=420
var world:Node
var budget:float
var bearing:float
var surveyed:Dictionary={}
var chart:RefCounted
var active_chart:RefCounted
var origin:Vector2

func _init(owner:Node,distance:float,angle:float,start:Vector2=Vector2.INF)->void:
	world=owner;budget=distance;bearing=angle
	origin=world.player_world_origin if not is_finite(start.x) or not is_finite(start.y) else start
	chart=preload("res://scripts/scout_chart_index.gd").new(world.revealed_areas)
	var active:Array=[]
	for party:Dictionary in world.scout_missions:active.append({"kind":"trail","points":party.get("route",[]),"radius":24.0})
	active_chart=preload("res://scripts/scout_chart_index.gd").new(active)

func novelty(point:Vector2)->float:
	var key:=Vector2i(roundi(point.x),roundi(point.y))
	if surveyed.has(key):return float(surveyed[key])
	var value:=0.15 if chart.contains(point) else 1.0
	if active_chart.contains(point):value=0.0
	surveyed[key]=value
	return value

func score(plan:Dictionary)->float:
	if not bool(plan.get("ok",false)):return -1.0
	var route:Array=plan.route
	var length:float=world._scout_route_distance(route)
	var fresh:=0.0
	for i in range(1,17):fresh+=novelty(world.city_intelligence.route_position(route,float(i)/16.0))
	return fresh/16.0*.8+minf(1,length/maxf(1,budget))*.2

func refine(fallback:Dictionary)->Dictionary:
	var best:=fallback
	var best_score:=score(best)
	if best_score>.92:return best
	var coarse:=clampf(budget/48.0,4.0,64.0)
	for step:float in [coarse,maxf(4.0,coarse*.25)]:
		var plan:=search(step)
		var value:=score(plan)
		# Avoid replacing useful long journeys with trivial glimpses of fog.
		if value>best_score+.01:best=plan;best_score=value
		if best_score>.9:break
	return best

func search(step:float,node_limit:int=NODE_LIMIT)->Dictionary:
	var nodes:Array[Dictionary]=[{"point":origin,"distance":0.0,"fresh":0.0,"parent":-1,"score":0.0}]
	var visited:Dictionary={Vector2i.ZERO:true}
	var pending:Array[int]=[0]
	var best_index:=0
	var directions:Array[Vector2i]=[]
	var turn:=posmod(roundi(bearing/(PI*.25)),8)
	for i in 8:
		var a:=float((i+turn)%8)*PI*.25
		directions.append(Vector2i(roundi(cos(a)),roundi(sin(a))))
	while not pending.is_empty() and nodes.size()<node_limit:
		var selected:=0
		for i in range(1,pending.size()):
			if float(nodes[pending[i]].score)>float(nodes[pending[selected]].score):selected=i
		var index:=pending[selected];pending.remove_at(selected)
		var current:Dictionary=nodes[index]
		for direction:Vector2i in directions:
			var point:Vector2=current.point+Vector2(direction)*step
			var key:=Vector2i(roundi((point.x-origin.x)/step),roundi((point.y-origin.y)/step))
			if visited.has(key):continue
			var length:=Vector2(direction).length()*step
			var distance:=float(current.distance)+length
			if distance>budget+.001:continue
			if not world._scout_land_at(point):visited[key]=true;continue
			if not world._scout_segment_is_land(current.point,point):continue
			visited[key]=true
			var fresh:=float(current.fresh)+length*(novelty(point)+novelty((Vector2(current.point)+point)*.5))*.5
			var value:=(fresh+distance*.12+origin.distance_to(point)*.12)/maxf(1,budget)
			nodes.append({"point":point,"distance":distance,"fresh":fresh,"parent":index,"score":value})
			var next:=nodes.size()-1;pending.append(next)
			if value>float(nodes[best_index].score):best_index=next
			if nodes.size()>=node_limit or (distance>=budget*.94 and fresh>=budget*.6):pending.clear();break
	var points:Array[Vector2]=[]
	var index:=best_index
	while index>=0:points.push_front(nodes[index].point);index=int(nodes[index].parent)
	if points.size()<2:return {"ok":false}
	var compressed:Array[Vector2]=world._compress_scout_land_path(points)
	if compressed.size()<2:return {"ok":false}
	var route:Array[Dictionary]=world._scout_route_dictionaries(compressed)
	return {"ok":true,"route":route,"distance_km":world._scout_route_distance(route),"travel_mode":"land","target_reachable":true,"ordered_heading":"","planned_heading":world._compass_phrase(origin,points[-1])}

func wander(plan:Dictionary,seed_value:int)->Dictionary:
	# Side investigations are part of the physical route, not decorative bends.
	# Preserve every checked waypoint; do not compress away the visited ground.
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var points:Array[Vector2]=[world.city_intelligence.vector(plan.route[0])]
	for i in range(1,plan.route.size()):
		var a:Vector2=world.city_intelligence.vector(plan.route[i-1])
		var b:Vector2=world.city_intelligence.vector(plan.route[i])
		var delta:=b-a;var perpendicular:=Vector2(-delta.y,delta.x).normalized()
		var count:=clampi(ceili(delta.length()/65.0),1,4)
		for j in range(1,count+1):
			if points.size()>=world.SCOUT_ROUTE_POINT_LIMIT/2-plan.route.size()+i-1:break
			var along:=float(j)/float(count+1)
			var center:=a.lerp(b,along)
			var width:=minf(30.0,delta.length()*.10)*rng.randf_range(.55,1.0)
			var best:=center;var score:=-INF
			for sign_value:float in [-1.0,1.0]:
				var candidate:=center+perpendicular*width*sign_value
				if not world._scout_land_at(candidate) or not world._scout_segment_is_land(points[-1],candidate) or not world._scout_segment_is_land(candidate,b):continue
				var value:=novelty(candidate)+rng.randf_range(0,.08)
				if value>score:best=candidate;score=value
			if score>-INF:points.append(best)
		points.append(b)
	var route:Array[Dictionary]=world._scout_route_dictionaries(points)
	if world._scout_route_distance(route)>budget or not world._scout_route_is_land(route):return plan
	# Return over a different checked approach when ground permits. Every point
	# is part of one continuous journey, including the final arrival at home.
	var outward:=points.duplicate()
	for i in range(outward.size()-2,-1,-1):
		var target:Vector2=outward[i]
		if i>0:
			var before:Vector2=points[-1];var after:Vector2=outward[i-1]
			var delta:=after-before;var side:=Vector2(-delta.y,delta.x).normalized()
			var best:=target;var value:=-1.0
			for sign_value:float in [-1.0,1.0]:
				var candidate:=target+side*minf(24.0,delta.length()*.18)*sign_value
				if not world._scout_land_at(candidate) or not world._scout_segment_is_land(before,candidate) or not world._scout_segment_is_land(candidate,after):continue
				var score:=novelty(candidate)+minf(1.0,world._route_distance_to_point(route,candidate)/24.0)
				if score>value:best=candidate;value=score
			target=best
		points.append(target)
	var circuit:Array[Dictionary]=world._scout_route_dictionaries(points)
	var length:float=world._scout_route_distance(circuit)
	if points.size()>world.SCOUT_ROUTE_POINT_LIMIT or length>budget*2.0 or not world._scout_route_is_land(circuit):
		# A narrow coast can force a retrace. Keep the checked physical expedition.
		return plan
	var result:=plan.duplicate(true);result.route=circuit;result.distance_km=length*.5;result.circuit=true
	return result
