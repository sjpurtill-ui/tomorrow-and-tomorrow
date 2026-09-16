extends RefCounted

const KINDS := ["latrine", "wellhead", "cistern", "settling_basin"]
const STATUSES := ["under_construction", "active"]

static func empty()->Dictionary:
	return {"works": [], "next_id": 1, "last_day": -1, "report": {}}

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if not value.get("works",[]) is Array or not value.get("report",{}) is Dictionary:return false
	var next_id:Variant=value.get("next_id",1)
	var last_day:Variant=value.get("last_day",-1)
	if not _whole(next_id,1,1000000) or not _whole(last_day,-1,1e12):return false
	var ids:Dictionary={}
	var kinds:Dictionary={}
	if value.works.size()>KINDS.size():return false
	for variant:Variant in value.works:
		if not variant is Dictionary:return false
		var work:Dictionary=variant
		for key:String in ["id","kind","status","work_done","work_required","condition","started_day","last_maintenance_day"]:
			if not work.has(key):return false
		if not _whole(work.id,1,1000000) or ids.has(int(work.id)):return false
		ids[int(work.id)]=true
		if String(work.kind) not in KINDS or String(work.status) not in STATUSES or kinds.has(String(work.kind)):return false
		kinds[String(work.kind)]=true
		for key:String in ["work_done","work_required","condition"]:
			if not _finite_nonnegative(work[key]):return false
		if float(work.work_required)<=0 or float(work.work_done)>float(work.work_required) or float(work.condition)>1:return false
		if not _whole(work.started_day,-1,1e12) or not _whole(work.last_maintenance_day,-1,1e12):return false
	return value.report.size()<=6

static func valid_state(state:Dictionary)->bool:
	if not valid(state.get("water_waste_works",empty())):return false
	for city_variant:Variant in state.get("player_settlements",[]):
		if not city_variant is Dictionary:return false
		var local:Variant=(city_variant as Dictionary).get("local_resources",{})
		if not local is Dictionary:return false
		if not valid((local as Dictionary).get("water_waste_works",empty())):return false
	return true

static func _whole(value:Variant,minimum:float,maximum:float)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum and float(value)==floorf(float(value))

static func _finite_nonnegative(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0
