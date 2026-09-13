extends RefCounted
## Authoritative terrain coordinates are kilometres on every axis. The sampling
## bound is game route resolution, not a civil-engineering construction survey.
const MAX_LENGTH_KM:=120.0
const SAMPLE_SPACING_KM:=0.25
const MAX_SAMPLES:=1024
const MAX_GRADE:=0.02
const RIVER_CLEARANCE_KM:=0.05

static func finite_point(value:Variant)->bool:
	return value is Vector3 and is_finite(value.x) and is_finite(value.y) and is_finite(value.z)

static func survey(waypoints:Array,terrain:Dictionary)->Dictionary:
	if waypoints.size()<2 or waypoints.size()>8:return {"error":"A rail survey needs two to eight route points."}
	for point:Variant in waypoints:
		if not finite_point(point):return {"error":"Rail survey coordinates must be finite."}
	for key:String in ["height_at","land_at","known_at","river_distance_at"]:
		if not terrain.get(key) is Callable or not terrain[key].is_valid():return {"error":"Complete terrain and returned-chart evidence is required for rail construction."}
	var points:Array[Vector3]=[]
	var length:=0.0
	var steepest:=0.0
	for segment in range(1,waypoints.size()):
		var start:Vector3=waypoints[segment-1]
		var finish:Vector3=waypoints[segment]
		var distance:=Vector2(start.x,start.z).distance_to(Vector2(finish.x,finish.z))
		if distance<0.001:return {"error":"Rail route points must be distinct."}
		length+=distance
		if length>MAX_LENGTH_KM:return {"error":"The route exceeds the supported rail construction range."}
		var steps:=maxi(1,ceili(distance/SAMPLE_SPACING_KM))
		for index in range(0 if segment==1 else 1,steps+1):
			if points.size()>=MAX_SAMPLES:return {"error":"The route exceeds the survey sample bound."}
			var point:=start.lerp(finish,float(index)/steps)
			# Check returned knowledge before reading or displaying terrain evidence.
			if not bool(terrain.known_at.call(point.x,point.z)):return {"error":"Return a chart covering the complete proposed rail route."}
			if not bool(terrain.land_at.call(point.x,point.z)):return {"error":"This route needs an unsupported water crossing or ground structure."}
			var river:Variant=terrain.river_distance_at.call(point.x,point.z)
			if not number(river) or float(river)<RIVER_CLEARANCE_KM:return {"error":"A river crossing needs a separately qualified rail bridge."}
			var height:Variant=terrain.height_at.call(point.x,point.z)
			if not number(height):return {"error":"Rail elevation evidence is incomplete."}
			point.y=float(height)
			if not points.is_empty():
				var before:Vector3=points.back()
				var horizontal:=Vector2(before.x,before.z).distance_to(Vector2(point.x,point.z))
				var grade:=absf(point.y-before.y)/maxf(.000001,horizontal)
				steepest=maxf(steepest,grade)
				if grade>MAX_GRADE:return {"error":"The surveyed grade exceeds supported wagon haulage; select a different alignment."}
			points.append(point)
	return {"ok":true,"samples":points,"length_km":length,"max_grade":steepest,"origin":points.front(),"destination":points.back()}

static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid(route:Variant)->bool:
	if not route is Dictionary or not finite_point(route.get("origin")) or not finite_point(route.get("destination")):return false
	if not number(route.get("length_km")) or float(route.length_km)<.001 or float(route.length_km)>MAX_LENGTH_KM:return false
	if not number(route.get("max_grade")) or float(route.max_grade)<0 or float(route.max_grade)>MAX_GRADE:return false
	var points:Variant=route.get("samples")
	if not points is Array or points.size()<2 or points.size()>MAX_SAMPLES:return false
	var length:=0.0
	var steepest:=0.0
	for index in points.size():
		if not finite_point(points[index]):return false
		if index==0:continue
		var before:Vector3=points[index-1]
		var point:Vector3=points[index]
		var step:=Vector2(point.x,point.z).distance_to(Vector2(before.x,before.z))
		if step<=0 or step>SAMPLE_SPACING_KM+.00001:return false
		length+=step
		steepest=maxf(steepest,absf(point.y-before.y)/step)
	return points.front().distance_to(route.origin)<.00001 and points.back().distance_to(route.destination)<.00001 and absf(length-float(route.length_km))<.0001 and absf(steepest-float(route.max_grade))<.00001 and steepest<=MAX_GRADE
