extends RefCounted
## Conservative envelope of a newly visible aggregate roof. Detailed placement
## rejection is never bypassed; this guards only plots excluded by its budget.
static func place(at:Vector2,center:Vector2,right:Vector2,forward:Vector2,polygon:PackedVector2Array,routes:Array[Dictionary],land:Callable,height:Callable,occupied:Array[PackedVector2Array])->Dictionary:
	# Aggregate masses may be recentered/compacted within their own recorded lot.
	# Four bounded candidates avoid making a legal small lot disappear solely
	# because the generic warehouse envelope was larger than that lot.
	for candidate in [[at,1.0],[center,1.0],[at.lerp(center,.5),.85],[center,.65]]:
		var point:Vector2=candidate[0];var scale:float=candidate[1]
		var r:=right*scale;var f:=forward*scale
		var footprint:=PackedVector2Array([point-r-f,point+r-f,point+r+f,point-r+f])
		if not fits(footprint,polygon,routes,land,height):continue
		if occupied.any(func(other:PackedVector2Array)->bool:return not Geometry2D.intersect_polygons(footprint,other).is_empty()):continue
		return {"position":point,"scale":scale,"footprint":footprint}
	return {}

static func fits(footprint:PackedVector2Array,polygon:PackedVector2Array,routes:Array[Dictionary],land:Callable,height:Callable)->bool:
	if polygon.size()<3 or not Geometry2D.clip_polygons(footprint,polygon).is_empty():return false
	for route in routes:
		if not bool(route.get("active",true)):continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		for envelope:PackedVector2Array in Geometry2D.offset_polyline(points,preload("res://scripts/organic_town_visual.gd").route_half_width(route)):
			if not Geometry2D.intersect_polygons(footprint,envelope).is_empty():return false
	var midpoint:=Vector2.ZERO
	for point in footprint:midpoint+=point
	midpoint/=float(footprint.size())
	if not bool(land.call(midpoint)):return false
	var middle_height:=float(height.call(midpoint))
	for point in footprint:
		if not bool(land.call(point)):return false
		if absf(float(height.call(point))-middle_height)>midpoint.distance_to(point)*.34:return false
	return true
