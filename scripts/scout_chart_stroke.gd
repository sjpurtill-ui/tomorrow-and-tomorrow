extends RefCounted
## Explorer's-chart strokes for scout routes: a centripetal Catmull-Rom curve
## through the waypoints, resampled at even arc length and draped on terrain,
## then drawn as a thin tapering ink line (solid or dotted), a soft feathered
## halo, and a few small open direction ticks. Pure geometry; the caller owns
## materials, zoom and rebuild policy.

const MAX_POINTS:=420

## An ink stroke's triangles as packed arrays. Each vertex is its anchor on
## the route plus an offset kept in UV2 as a fraction of the view height it was
## built for, so scout_chart_ink.gdshader holds the stroke's on-screen width at
## any zoom: the map no longer rebuilds every route on each small zoom step.
## UV carries the distance along the route and across it, both as fractions
## of that view height, so the shader can set round dots along a returned chart.
class Ink:
	var vertices:=PackedVector3Array()
	var colors:=PackedColorArray()
	var offsets:=PackedVector2Array()
	var marks:=PackedVector2Array()
	var view_size:=1.0
	func _init(built_for_view:float)->void:
		view_size=maxf(built_for_view,0.000001)
	func add(anchor:Vector3,offset:Vector2,color:Color,along:float=0.0)->void:
		vertices.append(anchor);offsets.append(offset/view_size);colors.append(color)
		marks.append(Vector2(along,offset.length())/view_size)
	func commit()->ArrayMesh:
		var mesh:=ArrayMesh.new()
		if vertices.is_empty():return mesh
		var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_TEX_UV2]=offsets;arrays[Mesh.ARRAY_TEX_UV]=marks
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		# Offsets reach past the anchors; keep the stroke from being culled early.
		mesh.custom_aabb=mesh.get_aabb().grow(view_size*0.05)
		return mesh

## Smooth `points` and resample them every `step` world units (the step grows
## when a long route would exceed MAX_POINTS). `tolerance` is the simplification
## distance in world units (a few screen pixels at the current zoom): jittery
## daily positions, zero-length hops and back-and-forth doubling are removed
## before the curve is fitted, so the spline only ever sees a clean polyline.
static func smooth(points:PackedVector2Array,step:float,tolerance:float=0.0)->PackedVector2Array:
	if points.is_empty(): return PackedVector2Array()
	# Work relative to the first point: world coordinates are hundreds of km and
	# single-precision spline weights would otherwise cancel into sawtooth noise.
	var origin:=points[0]
	var local:=PackedVector2Array()
	for p in points: local.append(p-origin)
	var clean:=simplify(local,maxf(tolerance,step*0.5))
	if clean.size()<2:
		var single:=PackedVector2Array()
		for p in clean: single.append(p+origin)
		return single
	var dense:=PackedVector2Array([clean[0]])
	var last:=clean.size()-1
	for i in last:
		var p1:=clean[i]; var p2:=clean[i+1]
		# Phantom end points continue the end segments straight on, instead of
		# repeating a point (a zero-length knot interval blows the weights up).
		var p0:=clean[i-1] if i>0 else p1*2.0-p2
		var p3:=clean[i+2] if i+2<=last else p2*2.0-p1
		var samples:=clampi(ceili(p1.distance_to(p2)/maxf(step*0.5,0.000001)),2,64)
		for s in range(1,samples+1): dense.append(_centripetal(p0,p1,p2,p3,float(s)/float(samples)))
	var total:=0.0
	for i in range(1,dense.size()): total+=dense[i-1].distance_to(dense[i])
	var even_step:=maxf(step,total/float(MAX_POINTS))
	var out:=PackedVector2Array([dense[0]+origin])
	var carried:=0.0
	for i in range(1,dense.size()):
		var a:=dense[i-1]; var b:=dense[i]; var length:=a.distance_to(b)
		var along:=even_step-carried
		while along<=length:
			out.append(a.lerp(b,along/maxf(length,0.0000001))+origin)
			along+=even_step
		carried=length-(along-even_step)
	var tail:=dense[dense.size()-1]+origin
	if out[out.size()-1].distance_to(tail)>even_step*0.25: out.append(tail)
	return out


## Clean a raw waypoint list: drop hops shorter than `tolerance`, cut
## back-tracking spurs (a point that doubles back sharply onto the previous
## leg), then Ramer-Douglas-Peucker at `tolerance`.
static func simplify(points:PackedVector2Array,tolerance:float)->PackedVector2Array:
	var clean:=PackedVector2Array()
	for p in points:
		if clean.is_empty() or clean[clean.size()-1].distance_to(p)>tolerance: clean.append(p)
	if points.size()>1 and clean.size()>1 and clean[clean.size()-1]!=points[points.size()-1]:
		clean[clean.size()-1]=points[points.size()-1]
	elif points.size()>1 and clean.size()==1 and points[0].distance_to(points[points.size()-1])>0.0: clean.append(points[points.size()-1])
	var changed:=true
	while changed and clean.size()>2:
		changed=false
		var kept:=PackedVector2Array([clean[0]])
		var i:=1
		while i<clean.size()-1:
			var a:=kept[kept.size()-1]; var b:=clean[i]; var c:=clean[i+1]
			var ab:=b-a; var bc:=c-b
			# A short hop that turns back more than ~150 degrees is a scribble
			# (jittered daily positions), not a route; a long hairpin stays.
			if ab.length()>0.0 and bc.length()>0.0 and minf(ab.length(),bc.length())<tolerance*6.0 and ab.normalized().dot(bc.normalized())<-0.86:
				changed=true
			else:
				kept.append(b)
			i+=1
		kept.append(clean[clean.size()-1])
		clean=kept
	if clean.size()<3: return clean
	var keep:=PackedByteArray(); keep.resize(clean.size()); keep.fill(0)
	keep[0]=1; keep[clean.size()-1]=1
	var stack:=[[0,clean.size()-1]]
	while not stack.is_empty():
		var span:Array=stack.pop_back()
		var first:int=span[0]; var final:int=span[1]
		var worst:=-1; var worst_distance:=tolerance
		for k in range(first+1,final):
			var d:=Geometry2D.get_closest_point_to_segment(clean[k],clean[first],clean[final]).distance_to(clean[k])
			if d>worst_distance: worst_distance=d; worst=k
		if worst>=0:
			keep[worst]=1
			stack.append([first,worst]); stack.append([worst,final])
	var out:=PackedVector2Array()
	for k in clean.size():
		if keep[k]==1: out.append(clean[k])
	return out


static func _centripetal(p0:Vector2,p1:Vector2,p2:Vector2,p3:Vector2,u:float)->Vector2:
	var t0:=0.0
	var t1:=t0+maxf(0.0001,sqrt(p0.distance_to(p1)))
	var t2:=t1+maxf(0.0001,sqrt(p1.distance_to(p2)))
	var t3:=t2+maxf(0.0001,sqrt(p2.distance_to(p3)))
	var t:=lerpf(t1,t2,u)
	var a1:=p0*((t1-t)/(t1-t0))+p1*((t-t0)/(t1-t0))
	var a2:=p1*((t2-t)/(t2-t1))+p2*((t-t1)/(t2-t1))
	var a3:=p2*((t3-t)/(t3-t2))+p3*((t-t2)/(t3-t2))
	var b1:=a1*((t2-t)/(t2-t0))+a2*((t-t0)/(t2-t0))
	var b2:=a2*((t3-t)/(t3-t1))+a3*((t-t1)/(t3-t1))
	return b1*((t2-t)/(t2-t1))+b2*((t-t1)/(t2-t1))


## Cumulative arc length at each point.
static func arc_lengths(points:PackedVector2Array)->PackedFloat32Array:
	var out:=PackedFloat32Array([0.0])
	for i in range(1,points.size()): out.append(out[i-1]+points[i-1].distance_to(points[i]))
	return out


static func _normal(points:PackedVector2Array,i:int)->Vector2:
	var a:=points[maxi(0,i-1)]; var b:=points[mini(points.size()-1,i+1)]
	var d:=(b-a).normalized()
	return Vector2(-d.y,d.x)


## One ribbon: three columns (edge, centre, edge) so the halo feathers to
## nothing and the ink keeps a soft antialiased rim. Width and opacity taper
## over `taper` world units at both ends. `dash_on`/`dash_period` count
## samples: 0 draws a solid line.
static func ribbon(ink:Ink,points:PackedVector2Array,heights:PackedFloat32Array,half_width:float,color:Color,edge_alpha:float,taper:float,dash_on:int=0,dash_period:int=0)->void:
	if points.size()<2: return
	var arcs:=arc_lengths(points)
	var total:=arcs[arcs.size()-1]
	var taper_length:=minf(taper,total*0.35)
	var centre:=PackedVector3Array(); var sides:=PackedVector2Array(); var weights:=PackedFloat32Array()
	for i in points.size():
		var s:=arcs[i]
		var t:=1.0 if taper_length<=0.0 else smoothstep(0.0,taper_length,s)*smoothstep(0.0,taper_length,total-s)
		var w:=lerpf(0.18,1.0,t)
		sides.append(_normal(points,i)*half_width*w)
		centre.append(Vector3(points[i].x,heights[i],points[i].y))
		weights.append(lerpf(0.30,1.0,t))
	for i in points.size()-1:
		if dash_period>0 and (i%dash_period)>=dash_on: continue
		var core_a:=Color(color,color.a*weights[i]); var core_b:=Color(color,color.a*weights[i+1])
		var rim_a:=Color(color,core_a.a*edge_alpha); var rim_b:=Color(color,core_b.a*edge_alpha)
		for side in [1.0,-1.0]:
			var a_side:Vector2=sides[i]*side; var b_side:Vector2=sides[i+1]*side
			ink.add(centre[i],Vector2.ZERO,core_a,arcs[i]); ink.add(centre[i+1],Vector2.ZERO,core_b,arcs[i+1]); ink.add(centre[i+1],b_side,rim_b,arcs[i+1])
			ink.add(centre[i],Vector2.ZERO,core_a,arcs[i]); ink.add(centre[i+1],b_side,rim_b,arcs[i+1]); ink.add(centre[i],a_side,rim_a,arcs[i])


static func _quad(ink:Ink,a:Vector3,a_offset:Vector2,b:Vector3,b_offset:Vector2,c:Vector3,c_offset:Vector2,d:Vector3,d_offset:Vector2,ca:Color,cb:Color,cc:Color,cd:Color)->void:
	ink.add(a,a_offset,ca); ink.add(b,b_offset,cb); ink.add(c,c_offset,cc)
	ink.add(a,a_offset,ca); ink.add(c,c_offset,cc); ink.add(d,d_offset,cd)


## Small open chevrons pointing along the route at the given arc fractions.
static func ticks(ink:Ink,points:PackedVector2Array,heights:PackedFloat32Array,fractions:Array,length:float,half_width:float,color:Color)->int:
	if points.size()<3: return 0
	var arcs:=arc_lengths(points)
	var total:=arcs[arcs.size()-1]
	var count:=0
	for fraction in fractions:
		var target:=total*float(fraction)
		var i:=1
		while i<points.size()-1 and arcs[i]<target: i+=1
		var d:=(points[i]-points[i-1]).normalized()
		if d==Vector2.ZERO: continue
		var n:=Vector2(-d.y,d.x)
		var tip:=Vector3(points[i].x,heights[i],points[i].y)
		# Every corner hangs off the tip, so the whole chevron scales with the view.
		for wing in [-d*length+n*length*0.62,-d*length-n*length*0.62]:
			var along:=(wing as Vector2).normalized()
			var side:=Vector2(-along.y,along.x)*half_width
			_quad(ink,tip,side,tip,wing+side,tip,wing-side,tip,-side,color,color,color,color)
		count+=1
	return count


## World position at an arc fraction (0..1) along the resampled route.
static func point_at(points:PackedVector2Array,fraction:float)->Vector2:
	if points.is_empty(): return Vector2.ZERO
	var arcs:=arc_lengths(points)
	var target:=arcs[arcs.size()-1]*clampf(fraction,0.0,1.0)
	for i in range(1,points.size()):
		if arcs[i]>=target:
			var span:=maxf(arcs[i]-arcs[i-1],0.0000001)
			return points[i-1].lerp(points[i],(target-arcs[i-1])/span)
	return points[points.size()-1]
