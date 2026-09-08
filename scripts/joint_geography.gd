extends RefCounted
## Routes are sampled from the same land authority as scouts and armies.
## Computed when orders change; never a per-frame planet scan.
var land_query:Callable
var route_cache:Dictionary={}

func is_land(location:Vector2)->bool:
	if land_query.is_valid():return bool(land_query.call(location))
	if CivilizationSystem.scout_land_authority.is_valid():return CivilizationSystem._scout_land_at(location)
	return PlanetEnvironment.is_land(location)

func sea_edge(a:Vector2,b:Vector2)->bool:
	var samples:=maxi(1,ceili(a.distance_to(b)/2.0))
	for i in samples+1:
		if is_land(a.lerp(b,float(i)/samples)):return false
	return true

func sea_route(start:Vector2,finish:Vector2)->Dictionary:
	if is_land(start) or is_land(finish):return {"error":"A naval route must start and finish on water."}
	if start.distance_to(finish)<.001:return {"points":[pack(start)],"distance":0.0}
	var cache_key:="%d:%s:%s" % [GameState.world_seed,str(start),str(finish)]
	if route_cache.has(cache_key):return route_cache[cache_key].duplicate(true)
	if sea_edge(start,finish):return _result([start,finish],cache_key)
	var spacing:=maxf(5.0,start.distance_to(finish)/45.0)
	var first:=Vector2i(floori(minf(start.x,finish.x)/spacing)-10,floori(minf(start.y,finish.y)/spacing)-10)
	var last:=Vector2i(ceili(maxf(start.x,finish.x)/spacing)+10,ceili(maxf(start.y,finish.y)/spacing)+10)
	var graph:=AStar2D.new()
	graph.add_point(1,start);graph.add_point(2,finish)
	var nodes:Dictionary={};var serial:=3
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			var cell:=Vector2i(x,y);var position:=Vector2(cell)*spacing
			if is_land(position):continue
			nodes[cell]=serial;graph.add_point(serial,position);serial+=1
	for cell:Vector2i in nodes:
		var id:=int(nodes[cell]);var a:=graph.get_point_position(id)
		for offset:Vector2i in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i(1,1),Vector2i(-1,1)]:
			if nodes.has(cell+offset):
				var other:=int(nodes[cell+offset])
				if sea_edge(a,graph.get_point_position(other)):graph.connect_points(id,other)
		for endpoint in [1,2]:
			var b:=graph.get_point_position(endpoint)
			if a.distance_to(b)<=spacing*2.5 and sea_edge(a,b):graph.connect_points(id,endpoint)
	var path:=graph.get_point_path(1,2)
	if path.is_empty():return {"error":"No connected sea route was found. Rebase to a port on the same coast or choose a nearer region."}
	return _result(Array(path),cache_key)

func _result(points:Array,key:String)->Dictionary:
	var packed:Array=[];var distance:=0.0
	for i in points.size():
		packed.append(pack(points[i]))
		if i>0:distance+=Vector2(points[i-1]).distance_to(Vector2(points[i]))
	var result:={"points":packed,"distance":distance}
	if route_cache.size()>=128:route_cache.clear()
	route_cache[key]=result.duplicate(true)
	return result

func sea_point(region:Dictionary,from:Vector2)->Dictionary:
	# Keep geography independent of the region helper to avoid preload cycles.
	var points:=PackedVector2Array()
	for vertex:Dictionary in region.get("vertices",[]):points.append(unpack(vertex))
	var center:=unpack(region.position)
	var box:=Rect2(center-Vector2.ONE*250,Vector2.ONE*500)
	if points.size()>=3:
		box=Rect2(points[0],Vector2.ZERO)
		for vertex:Vector2 in points:box=box.expand(vertex)
	var best:Dictionary={};var distance:=INF
	for x in 16:
		for y in 16:
			var candidate:=box.position+Vector2((x+.5)/16.0,(y+.5)/16.0)*box.size
			if points.size()>=3 and not Geometry2D.is_point_in_polygon(candidate,points):continue
			if not is_land(candidate) and candidate.distance_to(from)<distance:
				best=pack(candidate);distance=candidate.distance_to(from)
	return best

static func pack(value:Vector2)->Dictionary:return {"x":value.x,"z":value.y}
static func unpack(value:Dictionary)->Vector2:return Vector2(float(value.get("x",0)),float(value.get("z",0)))

static func travel(record:Dictionary,distance:float)->bool:
	var route:Array=record.get("route",[])
	var position:=unpack(record.position)
	while not route.is_empty() and distance>0:
		var target:=unpack(route[0]);var leg:=position.distance_to(target)
		if leg<=distance:
			position=target;distance-=leg;route.pop_front()
		else:position=position.move_toward(target,distance);distance=0
	record.position=pack(position);record.route=route
	return route.is_empty()
