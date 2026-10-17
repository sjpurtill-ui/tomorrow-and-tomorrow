extends RefCounted
## Map-only battle bodies. Geometry reads reported strength, progress and tactic
## phases; it never resolves combat or moves an army. Both sides use one scale.
const SAMPLES:=33
const BLOB_MEN:=180
const MIN_FRONT_PX:=48.0
const MAX_FRONT_PX:=300.0

static func span_km(battle:Dictionary)->float:
	var sides:Dictionary=battle.get("sides",{})
	var largest:=1.0
	for key in ["a","b"]:
		var side:Dictionary=sides.get(key,{})
		largest=maxf(largest,float(side.get("initial",side.get("troops",0))))
	return clampf(sqrt(largest)*0.07,0.15,4.0)

## A fluid centreline or round blob for each side. Area diminishes with
## remaining strength; progress bends and displaces the contact toward the
## losing side. Animation only adds small ripples, never invented casualties.
static func geometry(battle:Dictionary,at:Vector2,axis:Vector2,span_px:float,clock:float,still:bool=false)->Dictionary:
	if axis.length_squared()<0.0001:axis=Vector2.RIGHT
	axis=axis.normalized()
	var across:=axis.orthogonal()
	var sides:Dictionary=battle.get("sides",{})
	var largest:=1.0
	for key in ["a","b"]:
		var side:Dictionary=sides.get(key,{})
		largest=maxf(largest,float(side.get("initial",side.get("troops",0))))
	var blob:=largest<BLOB_MEN or span_px<MIN_FRONT_PX
	var span:=clampf(span_px,MIN_FRONT_PX,MAX_FRONT_PX)
	var progress:=clampf(float(battle.get("progress",0.0)),-1.0,1.0)
	var live:=int(battle.get("age_days",0))==0 and String(battle.get("status","fighting"))=="fighting"
	var time:=clock if live and not still else 0.0
	var phase:=float(absi(hash(String(battle.get("id",""))))%1000)/173.0
	var bodies:Array=[]
	var bounds:=Rect2(at,Vector2.ZERO)
	for index in 2:
		var key:="a" if index==0 else "b"
		var side:Dictionary=sides.get(key,{})
		var men:=maxf(0.0,float(side.get("troops",0)))
		if men<=0.01:continue
		var relative:=sqrt(clampf(men/largest,0.0,1.0))
		var initial:=maxf(1.0,float(side.get("initial",men)))
		var remaining:=clampf(men/initial,0.0,1.0)
		var sign_side:=1.0 if index==0 else -1.0
		var losing:=maxf(0.0,-progress*sign_side)
		var colour:Color=side.get("colour",Color("#4f9bb8") if index==0 else Color("#b5503c"))
		var radius:=(clampf(4.0+sqrt(largest)*0.12,5.0,12.0) if blob else clampf(span*0.044,3.8,10.0))*relative
		var points:=PackedVector2Array()
		var polygon:=PackedVector2Array()
		if blob:
			var base:=clampf(4.0+sqrt(largest)*0.12,5.0,12.0)
			var centre:=at+axis*(progress*base*1.5-sign_side*(radius+0.8+losing*base*0.7))
			for k in 32:
				var angle:=TAU*float(k)/32.0
				var ripple:=1.0+(0.055*sin(angle*3.0-time*2.5+phase)+0.025*sin(angle*5.0+time*1.7))*float(live)
				polygon.append(centre+Vector2(cos(angle),sin(angle))*radius*ripple)
			points.append(centre)
		else:
			var shape:Dictionary=battle.get("shape_"+key,{})
			var wing:=float(shape.get("wing",0.0)) if bool(battle.get("flank_allowed",true)) else 0.0
			var wings:=float(shape.get("wings",0.0)) if bool(battle.get("flank_allowed",true)) else 0.0
			var closure:=float(shape.get("closure",0.0)) if wings>0.0 else 0.0
			var bulge:=float(shape.get("bulge",0.0))
			var half:=span*0.5*relative
			for k in SAMPLES:
				var u:=float(k)/float(SAMPLES-1)*2.0-1.0
				var edge:=pow(absf(u),3.0)
				var hook:=maxf(wings,wing if u>0.0 else 0.0)*edge
				var bow:=progress*span*0.24*(1.0-0.48*u*u)
				var retreat:=-sign_side*losing*span*0.16
				var tactic:=sign_side*(bulge*span*0.12*(1.0-u*u)+hook*span*0.36)
				var ripple:=sin(u*8.0-time*2.6+phase)*minf(2.2,radius*0.24)*float(live)
				var forward:=-sign_side*(radius+1.1)+bow+retreat+tactic+ripple
				points.append(at+axis*forward+across*(u*half*(1.0-closure*0.45*edge)))
		var body:={"side":key,"points":points,"polygon":polygon,"radius":radius,"colour":colour,"remaining":remaining,"blob":blob}
		bodies.append(body)
		for point in (polygon if blob else points):bounds=bounds.expand(point)
		bounds=bounds.merge(Rect2(points[0]-Vector2.ONE*(radius+3.0),Vector2.ONE*(radius+3.0)*2.0))
		bounds=bounds.merge(Rect2(points[-1]-Vector2.ONE*(radius+3.0),Vector2.ONE*(radius+3.0)*2.0))
	return {"bodies":bodies,"blob":blob,"bounds":bounds.grow(13.0 if not blob else 3.0),"at":at}

static func draw(canvas:CanvasItem,shape:Dictionary,alpha:float=1.0)->void:
	for body:Dictionary in shape.bodies:
		var points:PackedVector2Array=body.points
		var radius:=float(body.radius)
		var colour:Color=body.colour
		if bool(body.blob):
			var polygon:PackedVector2Array=body.polygon
			canvas.draw_circle(points[0]+Vector2(0,1.5),radius+1.8,Color("#14252a",alpha*0.7))
			canvas.draw_colored_polygon(polygon,Color(colour,alpha))
			canvas.draw_arc(points[0],radius*0.7,PI*1.05,PI*1.7,10,Color(colour.lightened(0.55),alpha*0.65),1.2,true)
		else:
			# Rounded tubes; no teeth, weapon counters or tactical arrow decals.
			for pass_index in 3:
				var width:=radius*2.0+(3.0 if pass_index==0 else 0.0)
				var ink:=Color("#17282b",alpha*0.8) if pass_index==0 else Color(colour,alpha)
				if pass_index==2:width=maxf(0.6,radius*0.45);ink=Color(colour.lightened(0.5),alpha*0.42)
				canvas.draw_polyline(points,ink,width,true)
				canvas.draw_circle(points[0],width*0.5,ink)
				canvas.draw_circle(points[-1],width*0.5,ink)

## At continent scale a cluster is one pair of blobs, using summed observed
## strengths. It conveys no invented collective maneuver or exact location.
static func aggregate(battles:Array)->Dictionary:
	var out:={"id":"cluster","status":"fighting","age_days":0,"progress":0.0,"sides":{"a":{"troops":0.0,"initial":0.0},"b":{"troops":0.0,"initial":0.0}}}
	var weight:=0.0
	var all_stale:=true
	for battle:Dictionary in battles:
		var size:=0.0
		for key in ["a","b"]:
			var side:Dictionary=battle.get("sides",{}).get(key,{})
			var men:=float(side.get("troops",0))
			out.sides[key].troops+=men
			out.sides[key].initial+=float(side.get("initial",men))
			size+=men
		out.progress+=float(battle.get("progress",0))*size;weight+=size
		if int(battle.get("age_days",0))==0:all_stale=false
	out.progress/=maxf(1.0,weight)
	if all_stale:out.age_days=1
	return out

## A marching body's head is the reported army position. Its tail follows
## the already travelled route, back through bends; never cut across a bay.
static func column(at:Vector2,trail:PackedVector2Array,heading:Vector2,men:float,pixels_per_km:float,clock:float,still:bool=false,colour:Color=Color("#4f9bb8"))->Dictionary:
	var length:=clampf(sqrt(maxf(1.0,men))*0.035*pixels_per_km,22.0,180.0)
	var radius:=clampf(1.6+log(1.0+maxf(0.0,men))*0.25,2.0,4.8)
	var path:=trail
	if path.size()<2:
		var direction:=heading.normalized() if heading.length_squared()>0.001 else Vector2.RIGHT
		path=PackedVector2Array([at,at-direction*length])
	var available:=0.0
	for k in range(1,path.size()):available+=path[k-1].distance_to(path[k])
	length=minf(length,available)
	var points:=PackedVector2Array()
	var bounds:=Rect2(at,Vector2.ZERO)
	for k in SAMPLES:
		var distance:=length*float(k)/float(SAMPLES-1)
		var point:=path[-1]
		var direction:=Vector2.RIGHT
		for j in range(1,path.size()):
			var segment:=path[j-1].distance_to(path[j])
			if distance<=segment:
				direction=(path[j]-path[j-1]).normalized()
				point=path[j-1].lerp(path[j],distance/maxf(0.0001,segment));break
			distance-=segment
		if not still:point+=direction.orthogonal()*sin(float(k)*0.45-clock*3.0)*radius*0.12*sin(PI*float(k)/float(SAMPLES-1))
		points.append(point);bounds=bounds.expand(point)
	return {"bodies":[{"side":"a","points":points,"polygon":PackedVector2Array(),"radius":radius,"colour":colour,"remaining":1.0,"blob":false}],"bounds":bounds.grow(radius+3.0),"blob":false,"at":at}

## Unfold the same column into its front. Source points are projected from
## the last reported route, so the initial body has no icon-to-line jump.
static func deploy(shape:Dictionary,columns:Dictionary,amount:float)->Dictionary:
	var mix:=smoothstep(0.0,1.0,clampf(amount,0.0,1.0))
	if mix>=1.0 or columns.is_empty():return shape
	var result:=shape.duplicate(true)
	for body:Dictionary in result.bodies:
		var column_shape:Dictionary=columns.get(String(body.side),{})
		if column_shape.is_empty():continue
		var start:PackedVector2Array=column_shape.bodies[0].points
		var end:PackedVector2Array=body.points
		var points:=PackedVector2Array()
		for k in SAMPLES:
			var target:Vector2=end[0] if bool(body.blob) else end[mini(k,end.size()-1)]
			points.append(start[mini(k,start.size()-1)].lerp(target,mix))
		body.points=points;body.blob=false;body.polygon=PackedVector2Array()
		body.radius=lerpf(float(column_shape.bodies[0].radius),float(body.radius),mix)
		for point in points:result.bounds=(result.bounds as Rect2).expand(point)
	result.bounds=(result.bounds as Rect2).grow(5.0)
	return result

## Interpolate a reported move along the travelled polyline, not the chord
## between its endpoints. The returned head and tail stay on the same road.
static func trail_at_progress(trail:PackedVector2Array,old:Vector2,progress:float)->PackedVector2Array:
	if trail.size()<2:return trail
	var nearest:=INF;var back_distance:=0.0;var cumulative:=0.0
	for k in range(1,trail.size()):
		var point:=Geometry2D.get_closest_point_to_segment(old,trail[k-1],trail[k])
		var distance:=old.distance_squared_to(point)
		if distance<nearest:nearest=distance;back_distance=cumulative+trail[k-1].distance_to(point)
		cumulative+=trail[k-1].distance_to(trail[k])
	var remaining:=back_distance*(1.0-clampf(progress,0.0,1.0))
	for k in range(1,trail.size()):
		var length:=trail[k-1].distance_to(trail[k])
		if remaining<=length:
			var out:=PackedVector2Array([trail[k-1].lerp(trail[k],remaining/maxf(0.00001,length))])
			out.append_array(trail.slice(k))
			return out
		remaining-=length
	return PackedVector2Array([trail[-1]])
