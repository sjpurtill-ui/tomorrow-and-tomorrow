extends RefCounted
## Bounded physical wall geometry in local kilometres. The caller supplies the
## real occupied outline and the defense ledger's active construction/damage edges.
const MAX_OUTLINE_POINTS:=128
const MAX_GATES:=6
const EPSILON:=0.00000001

static func dimensions(stage:int,integrity:float=1.0)->Dictionary:
	var condition:=lerpf(0.78,1.0,clampf(integrity,0.0,1.0))
	var tier:=clampi(stage,0,5)
	return {"half_width":[0.0,0.0,0.0,0.00019,0.0007,0.0011][tier],
		"height":[0.0,0.0,0.0,0.0032,0.006,0.008][tier]*condition,
		"tower_half_width":[0.0,0.0022,0.0022,0.0015,0.0022,0.003][tier],
		"tower_height":[0.0,0.010,0.011,0.005,0.008,0.010][tier]*condition,
		"gate_clear_width":[0.0,0.0,0.004,0.0035,0.0045,0.006][tier],"base_lift":0.00008}

static func _distances(points:PackedVector2Array)->PackedFloat64Array:
	var distances:=PackedFloat64Array([0.0])
	if points.size()<3 or points.size()>MAX_OUTLINE_POINTS:return distances
	for index in points.size():
		distances.append(distances[-1]+points[index].distance_to(points[(index+1)%points.size()]))
	return distances

static func point_at(points:PackedVector2Array,distance:float)->Vector2:
	var distances:=_distances(points)
	if distances.size()<2 or distances[-1]<=EPSILON:return Vector2.ZERO
	var at:=fposmod(distance,distances[-1])
	for index in points.size():
		if at<=distances[index+1]+EPSILON:
			var length:=distances[index+1]-distances[index]
			return points[index].lerp(points[(index+1)%points.size()],clampf((at-distances[index])/maxf(EPSILON,length),0.0,1.0))
	return points[0]

static func tangent_at(points:PackedVector2Array,distance:float)->Vector2:
	var distances:=_distances(points)
	if distances.size()<2 or distances[-1]<=EPSILON:return Vector2.RIGHT
	var at:=fposmod(distance,distances[-1])
	for index in points.size():
		if at<distances[index+1]-EPSILON:
			return (points[(index+1)%points.size()]-points[index]).normalized()
	return (points[1]-points[0]).normalized()

## Adjacent wall faces share the same mitred cross-section at every corner.
## Gate cuts inside an edge instead use its ordinary perpendicular offset.
static func side_at(points:PackedVector2Array,distance:float,half_width:float)->Vector2:
	var distances:=_distances(points)
	if distances.size()<2 or distances[-1]<=EPSILON:return Vector2.ZERO
	var at:=fposmod(distance,distances[-1])
	for index in points.size():
		if absf(at-distances[index])<=EPSILON:
			var before_edge:=(points[index]-points[(index-1+points.size())%points.size()]).normalized()
			var after_edge:=(points[(index+1)%points.size()]-points[index]).normalized()
			var before:=Vector2(-before_edge.y,before_edge.x)
			var after:=Vector2(-after_edge.y,after_edge.x)
			var bisector:=(before+after).normalized()
			return bisector*minf(half_width*2.0,half_width/maxf(0.5,absf(bisector.dot(after))))
	var along:=tangent_at(points,distance)
	return Vector2(-along.y,along.x)*half_width

## Gates remove a physical interval along the wall, not a whole coarse panel.
## Intervals crossing the closing corner are split and merged before clipping.
static func outline_layout(points:PackedVector2Array,gate_bearings:Array[float],gate_width_km:float,active_edges:PackedByteArray=PackedByteArray(),gate_origin:Vector2=Vector2.ZERO)->Dictionary:
	var out:={"outline":points.duplicate(),"segments":[],"gates":[],"length":0.0}
	var distances:=_distances(points)
	if distances.size()<2 or distances[-1]<=EPSILON:return out
	var length:float=distances[-1]
	out.length=length
	var maximum:=0.0
	for point in points:maximum=maxf(maximum,point.distance_to(gate_origin))
	var cuts:Array[Vector2]=[]
	var width:=clampf(gate_width_km,0.0,length*0.08)
	for bearing:float in gate_bearings.slice(0,MAX_GATES):
		if width<=EPSILON:break
		var direction:=Vector2.from_angle(bearing)
		var nearest:=INF
		var centre_distance:=-1.0
		for index in points.size():
			var crossing:Variant=Geometry2D.segment_intersects_segment(gate_origin,gate_origin+direction*(maximum*2.0+0.01),points[index],points[(index+1)%points.size()])
			if crossing is Vector2 and (crossing as Vector2).distance_squared_to(gate_origin)<nearest:
				nearest=(crossing as Vector2).distance_squared_to(gate_origin)
				centre_distance=distances[index]+points[index].distance_to(crossing)
		if centre_distance<0.0:continue
		var duplicate:=false
		for gate:Dictionary in out.gates:
			var separation:=absf(float(gate.distance)-centre_distance)
			if minf(separation,length-separation)<width*1.05:duplicate=true;break
		if duplicate:continue
		var first:=centre_distance-width*0.5
		var last:=centre_distance+width*0.5
		out.gates.append({"a":point_at(points,first),"b":point_at(points,last),"center":point_at(points,centre_distance),"start":first,"end":last,"distance":centre_distance,"width":width})
		if first<0.0:
			cuts.append(Vector2(0.0,last));cuts.append(Vector2(length+first,length))
		elif last>length:
			cuts.append(Vector2(first,length));cuts.append(Vector2(0.0,last-length))
		else:cuts.append(Vector2(first,last))
	cuts.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x)
	var merged:Array[Vector2]=[]
	for cut:Vector2 in cuts:
		if not merged.is_empty() and cut.x<=merged[-1].y+EPSILON:merged[-1].y=maxf(merged[-1].y,cut.y)
		else:merged.append(cut)
	for index in points.size():
		if not active_edges.is_empty() and (index>=active_edges.size() or active_edges[index]==0):continue
		var cursor:float=distances[index]
		var finish:float=distances[index+1]
		for cut:Vector2 in merged:
			if cut.y<=cursor or cut.x>=finish:continue
			if cut.x>cursor+EPSILON:_append_segment(out,points,index,cursor,minf(cut.x,finish))
			cursor=maxf(cursor,float(cut.y))
			if cursor>=finish:break
		if cursor<finish-EPSILON:_append_segment(out,points,index,cursor,finish)
	return out

static func _append_segment(out:Dictionary,points:PackedVector2Array,edge:int,start:float,finish:float)->void:
	out.segments.append({"a":point_at(points,start),"b":point_at(points,finish),"edge":edge,"start":start,"end":finish})

static func solid_at(layout:Dictionary,distance:float)->bool:
	var length:=float(layout.get("length",0.0))
	if length<=EPSILON:return false
	var at:=fposmod(distance,length)
	for segment:Dictionary in layout.get("segments",[]):
		if at>=float(segment.start)-EPSILON and at<=float(segment.end)+EPSILON:return true
	return false
