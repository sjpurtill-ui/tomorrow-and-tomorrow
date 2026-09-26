extends RefCounted
## Territory edge geometry drawn like a hand-inked chart: closed bands between
## two matching outlines, mitred at every vertex. The old per-segment quads
## overlapped at each corner, so a translucent wash or ink line showed a darker
## bead at every one of the outline's 32 vertices; a mitred band never doubles up.
##
## Heights come from `ground` outlines whose points do not move with zoom (the
## authoritative boundary itself), so a long-lived sample cache answers them on
## every later rebuild instead of re-evaluating the planet height field.

## The outline moved along its vertex normals: positive `distance` outward,
## negative inward. Inward moves are held to half of each vertex's distance to
## the centre, so a territory only a few pixels wide cannot fold over itself.
static func offset(boundary:PackedVector2Array,distance:float)->PackedVector2Array:
	var count:=boundary.size()
	if count<3 or is_zero_approx(distance): return boundary
	var area:=0.0
	var center:=Vector2.ZERO
	for index in count:
		var a:=boundary[index];var b:=boundary[(index+1)%count]
		area+=a.x*b.y-b.x*a.y
		center+=a
	center/=float(count)
	# Right-hand edge normals point outward on a counter-clockwise outline
	# (positive shoelace area) and inward on a clockwise one.
	var outward_sign:=1.0 if area>0.0 else -1.0
	var out:=PackedVector2Array()
	out.resize(count)
	for index in count:
		var previous:=boundary[(index-1+count)%count]
		var point:=boundary[index]
		var next:=boundary[(index+1)%count]
		var d1:=(point-previous).normalized()
		var d2:=(next-point).normalized()
		var n1:=Vector2(d1.y,-d1.x)*outward_sign
		var n2:=Vector2(d2.y,-d2.x)*outward_sign
		var miter:=(n1+n2)
		if miter.length_squared()<0.000001: miter=n2
		miter=miter.normalized()
		var reach:=distance/maxf(0.5,miter.dot(n2))
		if distance<0.0:
			reach=-minf(-reach,point.distance_to(center)*0.5)
		out[index]=point+miter*reach
	return out

## Appends the band between `outer` and `inner` (same point count). Each edge is
## split into `subdivisions` pieces so the band drapes over relief; the colour
## runs from `outer_color` to `inner_color` across the band for a painted fade.
static func append(surface:SurfaceTool,outer:PackedVector2Array,inner:PackedVector2Array,outer_ground:PackedVector2Array,inner_ground:PackedVector2Array,outer_color:Color,inner_color:Color,lift:float,samples:RefCounted,subdivisions:int)->int:
	var count:=outer.size()
	if count<3 or inner.size()!=count or outer_ground.size()!=count or inner_ground.size()!=count: return 0
	subdivisions=maxi(1,subdivisions)
	for index in count:
		var next:=(index+1)%count
		for step in subdivisions:
			var t0:=float(step)/float(subdivisions)
			var t1:=float(step+1)/float(subdivisions)
			var o0:=_vertex(outer[index].lerp(outer[next],t0),outer_ground[index].lerp(outer_ground[next],t0),lift,samples)
			var o1:=_vertex(outer[index].lerp(outer[next],t1),outer_ground[index].lerp(outer_ground[next],t1),lift,samples)
			var i0:=_vertex(inner[index].lerp(inner[next],t0),inner_ground[index].lerp(inner_ground[next],t0),lift,samples)
			var i1:=_vertex(inner[index].lerp(inner[next],t1),inner_ground[index].lerp(inner_ground[next],t1),lift,samples)
			surface.set_color(outer_color);surface.add_vertex(o0)
			surface.set_color(outer_color);surface.add_vertex(o1)
			surface.set_color(inner_color);surface.add_vertex(i1)
			surface.set_color(outer_color);surface.add_vertex(o0)
			surface.set_color(inner_color);surface.add_vertex(i1)
			surface.set_color(inner_color);surface.add_vertex(i0)
	return count

static func _vertex(point:Vector2,ground:Vector2,lift:float,samples:RefCounted)->Vector3:
	return Vector3(point.x,samples.height_at(ground.x,ground.y)+lift,point.y)
