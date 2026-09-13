extends RefCounted
## Calendar interruptions are retained separately from paid processing work.
static func synchronize(p:Dictionary,available:bool,duration:float,today:int)->void:
	var delta:=maxi(0,today-int(p.last_day))
	if delta==0:return
	var missed:=maxi(0,delta-1) if available else delta
	if missed>0:
		var position:=minf(float(p.work),duration)
		if not p.pauses.is_empty() and absf(float(p.pauses.back().work)-position)<.000001:
			p.pauses.back().days+=missed
		else:p.pauses.append({"work":position,"days":missed})
	p.last_day=today
static func valid(p:Dictionary,duration:float)->bool:
	if not p.get("last_day") is int or p.last_day<0 or not p.get("pauses") is Array:return false
	var previous:=-1.0
	for event:Variant in p.pauses:
		if not event is Dictionary or not event.has_all(["work","days"]):return false
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(event.work) or not event.days is int or event.days<=0:return false
		if event.work<0 or event.work<=previous or event.work>minf(float(p.work),duration):return false
		previous=float(event.work)
	return true
