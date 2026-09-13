extends RefCounted
const Route=preload("res://scripts/water_conveyance_route.gd")
const APPLIED=["joinery","gravity_conduit_grade_control","clay_pipe_socket_jointing","lime_mortar","ceramic_pipe_fit_gauges","rigid_pipe_bedding","buried_pipe_load_assessment"]
static func empty()->Dictionary:return {"lines":[],"next_id":1,"last_day":-1,"report":{}}
static func number(value:Variant,low:float,high:float,integer:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=low and float(value)<=high and (not integer or floorf(float(value))==float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.get("lines") is Array or value.lines.size()>8:return false
	if not number(value.get("next_id"),1,1000000,true) or not number(value.get("last_day"),-1,100000000,true):return false
	if not value.get("report",{}) is Dictionary:return false
	var ids:Dictionary={}
	for line:Variant in value.lines:
		if not line is Dictionary or not number(line.get("id"),1,999999,true):return false
		if ids.has(int(line.id)) or int(line.id)>=int(value.next_id):return false
		ids[int(line.id)]=true
		if line.get("material","") not in ["ceramic","timber"] or line.get("status","") not in ["active","under_construction"]:return false
		if not line.get("route") is Dictionary:return false
		var route:Dictionary=line.route
		if not route.get("source_id") is String or route.source_id.is_empty() or route.source_id.length()>160:return false
		if not Route.gravity_blocker(route).is_empty():return false
		if not number(line.get("work_required"),.001,10000) or not number(line.get("work_done"),0,float(line.work_required)):return false
		if line.status=="active" and float(line.work_done)<float(line.work_required):return false
		for key:String in ["condition","obstruction","leakage"]:
			if not number(line.get(key),0,1):return false
		if not number(line.get("decay"),0,.1):return false
		for key:String in ["started_day","last_work_day","last_service_day"]:
			if not number(line.get(key),-1,100000000,true):return false
		for key:String in ["last_maintenance_day","inspected_day"]:
			if line.has(key) and not number(line[key],0,100000000,true):return false
		if line.has("observed_leakage") and not number(line.observed_leakage,0,1):return false
		if not line.get("supply_provenance") is Dictionary or line.supply_provenance.size()>16:return false
		for key:Variant in line.supply_provenance:
			if not key is String or key.length()>100 or not number(line.supply_provenance[key],0,100000):return false
		if not line.get("applied") is Array or line.applied.size()>APPLIED.size():return false
		for method:Variant in line.applied:
			if method not in APPLIED:return false
		if not number(line.get("delivered_today",0),0,100000):return false
	return true

static func valid_state(state:Dictionary)->bool:
	if not valid(state.get("water_conveyance",empty())):return false
	var cities:Variant=state.get("player_settlements",[])
	if not cities is Array:return false
	for city:Variant in cities:
		if not city is Dictionary or not city.get("local_resources",{}) is Dictionary:return false
		if not valid(city.get("local_resources",{}).get("water_conveyance",empty())):return false
	return true
