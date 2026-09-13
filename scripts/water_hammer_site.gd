extends RefCounted
## A bounded river-drive abstraction, not a measurement of discharge or head.
## A settlement has one pinned hammer site; stacking installations shares its cap.
const RANGE_KM:=0.75
static func point(value:Variant)->bool:
	return value is Vector3 and is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
static func valid(site:Variant)->bool:
	if not site is Dictionary or not site.has_all(["source_id","source","home"]):return false
	if not site.source_id is String or site.source_id.is_empty() or site.source_id.length()>256:return false
	for field:String in ["source","home"]:
		if not site[field] is Array or site[field].size()!=3:return false
		for n:Variant in site[field]:
			if not (n is float or n is int) or not is_finite(float(n)):return false
	return true
static func pack(p:Vector3)->Array:return [p.x,p.y,p.z]
static func unpack(p:Array)->Vector3:return Vector3(float(p[0]),float(p[1]),float(p[2]))
static func select(context:Dictionary)->Dictionary:
	var home:Variant=context.get("settlement_origin",context.get("origin"))
	if not point(home):return {}
	var chosen:Dictionary={};var distance:=RANGE_KM
	for source:Dictionary in context.get("water_conveyance_sources",[]):
		if not bool(source.get("revealed",false)) or String(source.get("kind","")) not in ["River","Tributary"]:continue
		var p:Variant=source.get("position")
		if not point(p) or String(source.get("id","")).is_empty():continue
		var d:float=Vector2(home.x,home.z).distance_to(Vector2(p.x,p.z))
		if d<=distance:
			distance=d;chosen={"source_id":String(source.id),"source":pack(p),"home":pack(home)}
	return chosen
static func assessment(site:Dictionary,context:Dictionary,day:int)->Dictionary:
	if not valid(site):return {"capacity":0.0,"reason":"No confirmed river installation site"}
	var home:Variant=context.get("settlement_origin",context.get("origin"))
	if not point(home) or home.distance_to(unpack(site.home))>.01:return {"capacity":0.0,"reason":"Settlement has moved away from its hammer site"}
	var confirmed:=false
	for source:Dictionary in context.get("water_conveyance_sources",[]):
		var p:Variant=source.get("position")
		if String(source.get("id",""))==site.source_id and bool(source.get("revealed",false)) and String(source.get("kind","")) in ["River","Tributary"] and point(p) and p.distance_to(unpack(site.source))<=.01:
			confirmed=Vector2(home.x,home.z).distance_to(Vector2(p.x,p.z))<=RANGE_KM
	if not confirmed:return {"capacity":0.0,"reason":"River source is no longer confirmed at this site"}
	var profile:Dictionary=context.get("environment_profile",{})
	if profile.is_empty():return {"capacity":0.0,"reason":"Waiting for local climate observations"}
	if PlanetEnvironment.ambient_temperature_c(profile,day)<=0:return {"capacity":0.0,"reason":"River drive is frozen"}
	var wetness:=clampf(float(profile.get("precipitation",0.0)),0,1)
	if wetness<=.1:return {"capacity":0.0,"reason":"River drive is too dry"}
	var seasonal:=clampf(1.0-.3*PlanetEnvironment.season_wave(profile,day),.7,1.3)
	return {"capacity":minf(2.0,2.0*(wetness-.1)/.5*seasonal),"reason":"Shared seasonal river-drive capacity"}
