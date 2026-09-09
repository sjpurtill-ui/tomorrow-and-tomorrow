extends RefCounted
## The dispatch schedule is public. It is not live tracking of people abroad.
static func describe(mission:Dictionary,day:int)->Dictionary:
	if mission.is_empty():return {}
	var departure:=int(mission.get("depart_day",day))
	var arrival:=int(mission.get("arrival_day",departure))
	var returning:=int(mission.get("return_day",arrival))
	return {
		"depart_day":departure,"arrival_day":arrival,"return_day":returning,
		"progress":clampf(float(day-departure)/maxf(1,returning-departure),0,1),
		"distance_km":float(mission.get("distance_km",0)),
		"target_position":(mission.get("target_position",{}) as Dictionary).duplicate(true),
		"origin_position":(mission.get("origin_position",{}) as Dictionary).duplicate(true),
		"destination":String(mission.get("destination",mission.get("civilization","Reported foreign home"))),
		"phase":"Home" if day>=returning else ("Returning" if day>=arrival else "Outbound")
	}
