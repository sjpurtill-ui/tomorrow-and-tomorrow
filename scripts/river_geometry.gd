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

## Distance along a course from its first point, as a fraction of its length:
## 0 at a tributary's spring, 1 where it joins.
static func course_fractions(points:Array[Vector3])->PackedFloat32Array:
	var fractions:=PackedFloat32Array()
	var distance:=0.0
	for index in points.size():
		if index>0:
			distance+=Vector2(points[index].x,points[index].z).distance_to(Vector2(points[index-1].x,points[index-1].z))
		fractions.append(distance)
	var total:=maxf(distance,0.000001)
	for index in fractions.size(): fractions[index]/=total
	return fractions

## How far downstream each point of a trunk river lies, 0 at its source and 1 at
## its mouth. The river runs toward its lower end; the mouth is where it first
## meets the sea on the way, and any reach beyond it stays at 1.
static func downstream_fractions(points:Array[Vector3],sea_level:float=0.0)->PackedFloat32Array:
	var count:=points.size()
	var fractions:=PackedFloat32Array()
	fractions.resize(count)
	if count<2: return fractions
	var ends:=mini(count/4,200)
	var first_height:=0.0
	var last_height:=0.0
	for index in maxi(ends,1):
		first_height+=points[index].y
		last_height+=points[count-1-index].y
	var forward:=last_height<=first_height
	var along:=PackedFloat32Array()
	along.resize(count)
	var distance:=0.0
	var mouth:=-1.0
	for step in count:
		var index:=step if forward else count-1-step
		if step>0:
			var previous:=index-1 if forward else index+1
			distance+=Vector2(points[index].x,points[index].z).distance_to(Vector2(points[previous].x,points[previous].z))
		along[index]=distance
		if mouth<0.0 and step>0 and points[index].y<sea_level: mouth=distance
	if mouth<=0.0: mouth=distance
	for index in count: fractions[index]=clampf(along[index]/maxf(mouth,0.000001),0.0,1.0)
	return fractions

## A course with its sample-to-sample kinks relaxed away (a few passes of
## neighbour averaging), keeping its two ends where they are. For drawing only:
## the surveyed course stays the one the world measures water distance from.
static func smoothed_course(points:Array[Vector3],passes:int=8)->Array[Vector3]:
	var result:Array[Vector3]=points.duplicate()
	if result.size()<3: return result
	for pass_index in passes:
		var relaxed:Array[Vector3]=result.duplicate()
		for index in range(1,result.size()-1):
			relaxed[index]=result[index-1]*0.25+result[index]*0.5+result[index+1]*0.25
		result=relaxed
	return result
