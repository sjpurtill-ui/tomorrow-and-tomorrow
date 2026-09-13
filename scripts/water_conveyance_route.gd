extends RefCounted
## Read-only route evidence. No water, terrain, visibility or stock authority.
## Horizontal coordinates use the existing map kilometre convention. Heights
## stay in terrain units; this is a feasibility bound, not a pressure rating.
const MAX_LENGTH_KM:=6.0
const SAMPLE_SPACING_KM:=0.125
const MAX_SAMPLES:=64

static func finite_point(value:Variant)->bool:
	return value is Vector3 and is_finite(value.x) and is_finite(value.y) and is_finite(value.z)

static func survey(source:Dictionary,destination:Vector3,height_at:Callable)->Dictionary:
	if not bool(source.get("revealed",false)) or String(source.get("id","")).is_empty():
		return {"ok":false,"reason":"A revealed, identified water source is required."}
	if not finite_point(source.get("position")) or not finite_point(destination) or not height_at.is_valid():
		return {"ok":false,"reason":"Source and route elevation evidence is missing."}
	var intake:Vector3=source.position
	var distance:=Vector2(intake.x,intake.z).distance_to(Vector2(destination.x,destination.z))
	if distance<0.001 or distance>MAX_LENGTH_KM:
		return {"ok":false,"reason":"The source lies outside the supported local conveyance range."}
	var intervals:=maxi(1,ceili(distance/SAMPLE_SPACING_KM))
	var samples:Array[Vector3]=[]
	for index in intervals+1:
		var point:=intake.lerp(destination,float(index)/intervals)
		var elevation:Variant=height_at.call(point.x,point.z)
		if (not elevation is float and not elevation is int) or not is_finite(float(elevation)):
			return {"ok":false,"reason":"The complete route has not been surveyed."}
		point.y=float(elevation)
		samples.append(point)
	var result:={"source_id":String(source.id),"source_position":intake,"destination":samples.back(),"length_km":distance,"samples":samples}
	var failure:=gravity_blocker(result)
	result.ok=failure.is_empty()
	result.reason=failure
	return result

static func gravity_blocker(route:Dictionary)->String:
	if not finite_point(route.get("source_position")) or not finite_point(route.get("destination")):
		return "Source and destination elevations are unavailable."
	var source:Vector3=route.source_position
	var destination:Vector3=route.destination
	if source.y<=destination.y:
		return "The destination is not below the intake; gravity delivery is unavailable."
	var points:Variant=route.get("samples",[])
	if not points is Array or points.size()<2 or points.size()>MAX_SAMPLES:
		return "The route lacks bounded survey evidence."
	var previous:=source
	var length:=0.0
	for index in points.size():
		var point:Variant=points[index]
		if not finite_point(point):return "The route contains an invalid elevation observation."
		var step:=Vector2(previous.x,previous.z).distance_to(Vector2(point.x,point.z))
		if step>SAMPLE_SPACING_KM+0.00001:return "The route has an unsurveyed gap."
		if index==0 and step>0.00001:return "The surveyed route does not begin at its intake."
		if point.y>source.y+0.000001:return "An intervening rise exceeds the intake head; reroute or provide a qualified pump."
		length+=step;previous=point
	if previous.distance_to(destination)>0.00001:return "The surveyed route does not reach its destination."
	if length<0.001 or length>MAX_LENGTH_KM+0.00001:return "The route lies outside the supported local range."
	return ""
