extends RefCounted
const F=preload("res://scripts/civilian_care_fabric.gd")
static func number(value:Variant,low:float,high:float,integer:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=low and float(value)<=high and (not integer or floorf(float(value))==float(value))
static func report_valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	var required:=["day","staff_available","staff_used","observed","pulse_assessed","supported","additional_recovery","water_used","cloth_used","record_clay_used","unmet"]
	for key:String in required:
		if not value.has(key):return false
	for key:Variant in value:
		if not (key is String or key is StringName):return false
		if String(key) not in required and String(key) not in ["waiting","health_relief","blocker"]:return false
		if key=="blocker":
			if not value[key] is String or value[key].length()>500:return false
		elif not number(value[key],0,1e15):return false
	if not number(value.day,0,1e9,true) or not number(value.get("health_relief",0),0,.025):return false
	if float(value.staff_used)>float(value.staff_available)+.000001:return false
	if float(value.pulse_assessed)>float(value.observed)+.000001 or float(value.supported)>float(value.observed)+.000001:return false
	if float(value.additional_recovery)>float(value.supported)*.06+.000001:return false
	var paid_work:=float(value.observed)*F.OBSERVATION_WORK+float(value.pulse_assessed)*F.PULSE_WORK+float(value.supported)*F.CARE_WORK
	if not is_equal_approx(float(value.staff_used),paid_work):return false
	for pair:Array in [["water_used",float(value.supported)*F.CARE_WATER],["cloth_used",float(value.supported)*F.CARE_CLOTH],["record_clay_used",float(value.observed)*F.RECORD_CLAY]]:
		if not is_equal_approx(float(value[pair[0]]),float(pair[1])):return false
	return true
static func valid(value:Variant,population:float=1e15)->bool:
	if not value is Dictionary or not value.get("enabled") is bool or not number(value.get("staff_share"),0,.75):return false
	if not number(value.get("next_id"),1,1e12,true) or not number(value.get("last_day"),-1,1e9,true):return false
	if not value.get("episodes") is Array or value.episodes.size()>F.MAX_EPISODES:return false
	if not value.get("history") is Array or value.history.size()>F.MAX_HISTORY or not report_valid(value.get("report")):return false
	if not value.report.is_empty() and int(value.report.day)!=int(value.last_day):return false
	var ids:Dictionary={};var total:=0.0
	for e:Variant in value.episodes:
		if not e is Dictionary or not number(e.get("id"),1,float(value.next_id)-1,true) or ids.has(e.id):return false
		ids[e.id]=true
		if not number(e.get("remaining"),0,1e15) or not number(e.get("severity"),0,1) or not number(e.get("assessed_severity"),0,1) or not number(e.get("continuity"),0,1):return false
		for field:String in ["observed","cared"]:
			if not number(e.get(field),0,float(e.remaining)+.000001):return false
		for field:String in ["onset_day","observation_day","prior_observation_day","care_day"]:
			if not number(e.get(field),0 if field=="onset_day" else -1,maxf(0,float(value.last_day)),true):return false
		if int(e.prior_observation_day)>=0 and int(e.prior_observation_day)>=int(e.observation_day):return false
		if int(e.observation_day)>=0 and int(e.observation_day)<int(e.onset_day):return false
		if int(e.care_day)>=0 and int(e.care_day)<int(e.onset_day):return false
		total+=float(e.remaining)
	if total>population+.00001:return false
	var previous:=-1
	for r:Variant in value.history:
		if not report_valid(r) or not number(r.get("day"),0,float(value.last_day),true) or int(r.day)<=previous:return false
		previous=int(r.day)
	return true
static func valid_state(state:Dictionary)->bool:
	# Local population can change between care and save; the owner caps episodes
	# before its next service. Validate finite bounded state without inferring deaths.
	if not valid(state.get("civilian_care",F.empty_state())):return false
	if not state.get("player_settlements",[]) is Array:return false
	for city:Variant in state.get("player_settlements",[]):
		if not city is Dictionary:return false
		var local:Variant=city.get("local_resources",{})
		if not local is Dictionary or not valid(local.get("civilian_care",F.empty_state())):return false
	return true
