extends RefCounted
## Operating areas belong to a commander, not a baked world grid.
const G=preload("res://scripts/joint_geography.gd")
const MAX_VERTICES:=64
const MAX_REGIONS:=128

static func polygon(region:Dictionary)->PackedVector2Array:
	var result:=PackedVector2Array()
	for vertex:Dictionary in region.get("vertices",[]):result.append(G.unpack(vertex))
	return result
static func area(points:PackedVector2Array)->float:
	var value:=0.0
	for i in points.size():value+=points[i].cross(points[(i+1)%points.size()])
	return absf(value)*.5
static func validate(vertices:Variant)->String:
	if not vertices is Array or vertices.size()<3 or vertices.size()>MAX_VERTICES:return "Draw a boundary with 3–64 points."
	var points:=PackedVector2Array()
	for vertex in vertices:
		if not vertex is Dictionary:return "Invalid boundary point."
		for key in ["x","z"]:
			var value:Variant=vertex.get(key,null)
			if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value))>100000:return "Boundary coordinates must be finite positions on the map."
		points.append(G.unpack(vertex))
	for i in points.size():
		var next:=(i+1)%points.size()
		if points[i].distance_to(points[next])<.1:return "Boundary points are too close together."
		for j in range(i+1,points.size()):
			var following:=(j+1)%points.size()
			if j==next or following==i:continue
			if Geometry2D.segment_intersects_segment(points[i],points[next],points[j],points[following])!=null:return "The boundary crosses itself. Draw a simple outline."
	if area(points)<1:return "The operating region must cover at least one square kilometre."
	return ""
static func bounds(region:Dictionary)->Rect2:
	var points:=polygon(region)
	if points.is_empty():return Rect2(G.unpack(region.get("position",{}))-Vector2.ONE*250,Vector2.ONE*500)
	var result:=Rect2(points[0],Vector2.ZERO)
	for point:Vector2 in points:result=result.expand(point)
	return result
static func contains(region:Dictionary,point:Vector2)->bool:
	if region.is_empty():return false
	var points:=polygon(region)
	return Geometry2D.is_point_in_polygon(point,points) if points.size()>=3 else bounds(region).has_point(point)
static func overlap(first:Dictionary,second:Dictionary)->float:
	if first.is_empty() or second.is_empty() or first.get("domain","")!=second.get("domain",""):return 0
	if bool(first.get("point_query",false)):return 1.0 if contains(second,G.unpack(first.position)) else 0.0
	if bool(second.get("point_query",false)):return 1.0 if contains(first,G.unpack(second.position)) else 0.0
	var a:=polygon(first);var b:=polygon(second)
	if a.size()<3 or b.size()<3:
		var intersection:=bounds(first).intersection(bounds(second))
		return clampf(intersection.get_area()/maxf(1,bounds(first).get_area()),0,1)
	var total:=0.0
	for intersection in Geometry2D.intersect_polygons(a,b):total+=area(intersection)
	return clampf(total/maxf(1,area(a)),0,1)
static func coverage(region:Dictionary,origin:Vector2,reach:float)->float:
	var box:=bounds(region);var sampled:=0;var covered:=0
	for x in 12:
		for y in 12:
			var point:=box.position+Vector2((x+.5)/12.0,(y+.5)/12.0)*box.size
			if not contains(region,point):continue
			sampled+=1
			if point.distance_to(origin)<=reach:covered+=1
	return float(covered)/sampled if sampled>0 else (1.0 if G.unpack(region.get("position",{})).distance_to(origin)<=reach else 0.0)
static func rectangle(center:Vector2,half_size:float)->Array:
	return [G.pack(center+Vector2(-half_size,-half_size)),G.pack(center+Vector2(half_size,-half_size)),G.pack(center+Vector2(half_size,half_size)),G.pack(center+Vector2(-half_size,half_size))]
