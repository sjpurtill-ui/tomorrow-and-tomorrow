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
