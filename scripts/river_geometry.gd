extends RefCounted
## Refine rendered reaches without moving their surveyed horizontal course.
static func drape_course(points:Array[Vector3],height_at:Callable,maximum_step:float=0.25)->Array[Vector3]:
	var result:Array[Vector3]=[]
	if points.is_empty(): return result
	var step:=maxf(maximum_step,0.01)
	for index in points.size()-1:
		var a:=points[index]
		var b:=points[index+1]
		var distance:=Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
		if distance<0.000001: continue
		var pieces:=maxi(1,ceili(distance/step))
		for piece in pieces:
			var point:=a.lerp(b,float(piece)/float(pieces))
			point.y=height_at.call(point.x,point.z)
			result.append(point)
	var last:Vector3=points.back()
	last.y=height_at.call(last.x,last.z)
	result.append(last)
	return result

## Width grows over a fixed distance, independent of rendering tessellation.
static func headwater_factors(points:Array[Vector3],transition_km:float=5.0)->PackedFloat32Array:
	var factors:=PackedFloat32Array()
	var distance:=0.0
	for index in points.size():
		if index>0:
			distance+=Vector2(points[index].x,points[index].z).distance_to(Vector2(points[index-1].x,points[index-1].z))
		factors.append(lerpf(0.12,1.0,smoothstep(0.0,maxf(0.01,transition_km),distance)))
	return factors
