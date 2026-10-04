extends RefCounted
## Read-only walking geometry for the bounded map representatives. Saved visual
## sites are the renderer's placements, not a second building/population ledger.
## Distances are kilometres. No process, simulation writes or per-frame rebuild.
const Kit=preload("res://scripts/settlement_architecture_kit.gd")
const MAX_OBSTACLES:=512
const MAX_GRAPH_OBSTACLES:=32
const MAX_LANE_POINTS:=64
const MAX_CACHED_PATHS:=128
const MAX_GRAPH_POINTS:=2+MAX_LANE_POINTS+MAX_GRAPH_OBSTACLES*8
const CLEARANCE:=0.00075
var obstacles:Array[Dictionary]=[]
var entries:Array[Dictionary]=[]
var lanes:Array[PackedVector2Array]=[]
var hearths:Array[Vector2]=[]
var paths:Dictionary={}
var overflow_bounds:=Rect2()
var has_overflow:=false
var last_road_points:=0
var last_graph_points:=0

func configure(plots:Array,routes:Array)->void:
	obstacles.clear();entries.clear();lanes.clear();hearths.clear();paths.clear()
	has_overflow=false;overflow_bounds=Rect2()
	last_road_points=0;last_graph_points=0
	var route_by_id:Dictionary={}
	for route:Dictionary in routes:
		if not bool(route.get("active",true)):continue
		var points:=points_of(route.get("points",[]))
		if points.size()<2:continue
		route_by_id[int(route.get("id",-1))]=points
		lanes.append(points)
	for plot:Dictionary in plots:
		if String(plot.get("status","active")) in ["ruin","reclaimed","vacant"]:continue
		var form:=String(plot.get("form",""))
		if form in ["open_hearth_yard","maintained_gathering_ground"]:
			hearths.append(point_of(plot.get("centroid",Vector2.ZERO)))
		var sites:Array=plot.get("visual_building_sites",[]) if plot.get("visual_building_sites",[]) is Array else []
		var rendered_kind:=String(plot.get("visual_sites_form",""))
		if rendered_kind!="" and Kit.kind(plot)!="" and rendered_kind!=Kit.kind(plot):sites=[]
		if sites.is_empty() and String(plot.get("land_use","")) in ["residential_compound","mixed_household","workshop","storage","dirty_industry","hospitality","civic","communal","sacred"] and form not in ["open_hearth_yard","maintained_gathering_ground","open_work_yard","carried_water_point"]:
			# Aggregate/fallback roofs have no published individual footprint.
			# Reserve their parcel rather than invent a building-sized hole in it.
			var parcel:=points_of(plot.get("polygon",[]))
			if parcel.size()>=3 and _reserve(parcel):
				var lane:PackedVector2Array=route_by_id.get(int(plot.get("frontage_route_id",-1)),PackedVector2Array())
				var at:=point_of(plot.get("centroid",Vector2.ZERO))
				var frontage:=nearest_on(lane,at)
				entries.append({"at":at,"door":frontage,"frontage":frontage,"angle":0.0,"plot":plot,"site":{},"rendered":false})
		for site:Dictionary in sites:
			var polygon:=points_of(site.get("footprint",[]))
			if polygon.size()<3:continue
			if not _reserve(polygon):continue
			var at:=point_of(site.get("position",plot.get("centroid",Vector2.ZERO)))
			var angle:=float(site.get("angle",0.0))
			var forward:=Vector2(sin(angle),cos(angle))
			var front:=0.0
			for vertex in polygon:front=maxf(front,(vertex-at).dot(forward))
			var door:=at+forward*(front+CLEARANCE+.00015)
			var lane:PackedVector2Array=route_by_id.get(int(plot.get("frontage_route_id",-1)),PackedVector2Array())
			var frontage:=nearest_on(lane,door)
			entries.append({"at":at,"door":door,"frontage":frontage,"angle":angle,"plot":plot,"site":site,"rendered":true})
	# Check against every final footprint, including the next plot's building.
	for entry in entries:
		if not open_at(entry.door):
			entry.door=entry.frontage if open_at(entry.frontage) else Vector2.INF

## Beyond the detailed budget, retain one conservative occupied envelope. An
## overflow must never turn a real building into apparently walkable ground.
func _reserve(polygon:PackedVector2Array)->bool:
	var area:=bounds(polygon).grow(CLEARANCE)
	if obstacles.size()>=MAX_OBSTACLES:
		overflow_bounds=overflow_bounds.merge(area) if has_overflow else area
		has_overflow=true
		return false
	var expanded:=Geometry2D.offset_polygon(polygon,CLEARANCE,Geometry2D.JOIN_MITER)
	var occupied:PackedVector2Array=expanded[0] if not expanded.is_empty() else _rectangle(area)
	obstacles.append({"polygon":occupied,"bounds":bounds(occupied)})
	return true

static func _rectangle(rect:Rect2)->PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func open_at(at:Vector2)->bool:
	if not at.is_finite():return false
	if has_overflow and overflow_bounds.has_point(at):return false
	for obstacle in obstacles:
		if (obstacle.bounds as Rect2).has_point(at) and Geometry2D.is_point_in_polygon(at,obstacle.polygon):return false
	return true

func clear_segment(a:Vector2,b:Vector2)->bool:
	if not open_at(a) or not open_at(b):return false
	var area:=Rect2(a,Vector2.ZERO).expand(b).grow(.000001)
	if has_overflow and area.intersects(overflow_bounds,true):
		var corners:=_rectangle(overflow_bounds)
		for i in 4:
			if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])!=null:return false
	for obstacle in obstacles:
		if not area.intersects(obstacle.bounds,true):continue
		var polygon:PackedVector2Array=obstacle.polygon
		for i in polygon.size():
			if Geometry2D.segment_intersects_segment(a,b,polygon[i],polygon[(i+1)%polygon.size()])!=null:return false
	return true

## Finite visibility graph around the nearest blocking buildings, with real
## street bends and frontage projections as preferred waypoints. If a crowded
## case exceeds the bounded search, hold still; never cut through a building.
func route(from:Vector2,to:Vector2,land:Callable=Callable())->PackedVector2Array:
	if not open_at(from) or not open_at(to):return PackedVector2Array()
	var key:=str(from)+">"+str(to)
	if paths.has(key):return (paths[key] as PackedVector2Array).duplicate()
	var answer:=PackedVector2Array()
	var points:=PackedVector2Array([from,to])
	var road_nodes:Dictionary={}
	# Road projections are exact points on the recorded active route. A short
	# route is preferred to a bare-yard diagonal when both endpoints reach it.
	for lane in lanes:
		if road_nodes.size()>=MAX_LANE_POINTS:break
		for endpoint in [from,to]:
			var p:=nearest_on(lane,endpoint)
			if p.distance_to(endpoint)<=.04 and open_at(p):_add_point(points,p,road_nodes)
		for p in lane:
			if road_nodes.size()>=MAX_LANE_POINTS:break
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,from,to))<.035 and open_at(p):_add_point(points,p,road_nodes)
	last_road_points=road_nodes.size()
	last_graph_points=points.size()
	# Open camp ground needs no graph. In town we keep the road candidates so
	# crossing the lawn is not always the shortest-looking animation.
	if points.size()==2 and clear_segment(from,to) and _land_segment(from,to,land):answer=PackedVector2Array([from,to])
	else:
		var nearby:Array[Dictionary]=obstacles.duplicate()
		nearby.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _distance(a,from,to)<_distance(b,from,to))
		for obstacle in nearby.slice(0,MAX_GRAPH_OBSTACLES):
			var polygon:PackedVector2Array=obstacle.polygon
			var center:Vector2=(obstacle.bounds as Rect2).get_center()
			for vertex in polygon:
				if points.size()>=MAX_GRAPH_POINTS:break
				var p:=vertex+(vertex-center).normalized()*.00003
				if open_at(p):points.append(p)
		last_graph_points=points.size()
		answer=_search(points,road_nodes,land)
	if paths.size()>=MAX_CACHED_PATHS:paths.erase(paths.keys()[0])
	paths[key]=answer.duplicate()
	return answer

func _search(points:PackedVector2Array,road_nodes:Dictionary,land:Callable)->PackedVector2Array:
	var cost:Dictionary={0:0.0};var previous:Dictionary={};var open:Array[int]=[0];var closed:Dictionary={}
	while not open.is_empty():
		var best:=0
		for i in range(1,open.size()):
			if float(cost[open[i]])+points[open[i]].distance_to(points[1])*.78<float(cost[open[best]])+points[open[best]].distance_to(points[1])*.78:best=i
		var current:int=open[best];open.remove_at(best)
		if current==1:
			var result:=PackedVector2Array([points[1]])
			while previous.has(current):current=int(previous[current]);result.insert(0,points[current])
			return result
		closed[current]=true
		var candidates:Array[int]=[]
		for next in points.size():
			if next!=current and not closed.has(next):candidates.append(next)
		candidates.sort_custom(func(a:int,b:int)->bool:return points[current].distance_squared_to(points[a])<points[current].distance_squared_to(points[b]))
		# A small neighbour budget keeps dense megacity representatives cheap.
		candidates=candidates.slice(0,20)
		if not closed.has(1) and 1 not in candidates:candidates.append(1)
		for next in candidates:
			var distance:=points[current].distance_to(points[next])
			var weight:=.78 if road_nodes.has(current) and road_nodes.has(next) and _on_lane(points[current],points[next]) else 1.0
			var proposed:=float(cost[current])+distance*weight
			if proposed>=float(cost.get(next,INF)):continue
			if not clear_segment(points[current],points[next]) or not _land_segment(points[current],points[next],land):continue
			cost[next]=proposed;previous[next]=current
			if next not in open:open.append(next)
	return PackedVector2Array()

func _on_lane(a:Vector2,b:Vector2)->bool:
	for lane in lanes:
		for i in range(1,lane.size()):
			if Geometry2D.get_closest_point_to_segment(a,lane[i-1],lane[i]).distance_to(a)<.0001 and Geometry2D.get_closest_point_to_segment(b,lane[i-1],lane[i]).distance_to(b)<.0001:return true
	return false

static func _land_segment(a:Vector2,b:Vector2,land:Callable)->bool:
	if not land.is_valid():return true
	var steps:=maxi(1,ceili(a.distance_to(b)/.003))
	for i in steps+1:
		if not bool(land.call(a.lerp(b,float(i)/steps))):return false
	return true

static func _distance(obstacle:Dictionary,a:Vector2,b:Vector2)->float:
	var center:Vector2=(obstacle.bounds as Rect2).get_center()
	return center.distance_squared_to(Geometry2D.get_closest_point_to_segment(center,a,b))

static func _add_point(points:PackedVector2Array,p:Vector2,road_nodes:Dictionary)->void:
	if road_nodes.size()>=MAX_LANE_POINTS:return
	for i in points.size():
		if points[i].distance_squared_to(p)<.0000000001:road_nodes[i]=true;return
	road_nodes[points.size()]=true;points.append(p)

static func nearest_on(points:PackedVector2Array,at:Vector2)->Vector2:
	var closest:=at;var distance:=INF
	for i in range(1,points.size()):
		var point:=Geometry2D.get_closest_point_to_segment(at,points[i-1],points[i])
		if point.distance_squared_to(at)<distance:closest=point;distance=point.distance_squared_to(at)
	return closest

static func bounds(points:PackedVector2Array)->Rect2:
	var result:=Rect2(points[0],Vector2.ZERO)
	for p in points:result=result.expand(p)
	return result

static func points_of(value:Variant)->PackedVector2Array:
	var result:=PackedVector2Array()
	if value is Array or value is PackedVector2Array:
		for p in value:result.append(point_of(p))
	return result

static func point_of(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Vector3:return Vector2(value.x,value.z)
	if value is Dictionary:return Vector2(float(value.get("x",0.0)),float(value.get("z",value.get("y",0.0))))
	return Vector2.ZERO

## Read the actual dark chimney-cap quads in the cached authored mesh. This
## automatically tracks roof height/type and never adds smoke to modern vents,
## a merely populated home, or a legacy record with no rendered chimney.
static func chimney_outlets(plot:Dictionary)->PackedVector3Array:
	var result:=PackedVector3Array()
	var kind:=Kit.kind(plot)
	if kind.is_empty() or kind.begins_with("modern_"):return result
	var mesh:=Kit.mesh_for_plot(plot)
	var arrays:=mesh.surface_get_arrays(0)
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var cap:=PackedVector3Array()
	for i in vertices.size()+1:
		var matches:=i<vertices.size() and absf(colors[i].r-.10)<.004 and absf(colors[i].g-.08)<.004 and absf(colors[i].b-.06)<.004
		if matches:cap.append(vertices[i]);continue
		if cap.is_empty():continue
		var box:=AABB(cap[0],Vector3.ZERO)
		for vertex in cap:box=box.expand(vertex)
		result.append(Vector3(box.get_center().x,box.end.y,box.get_center().z)*.001)
		cap.clear()
	return result
