extends RefCounted
## Finite daily instrument assistance; ordinary Knowledge work is still required.
const Ops=preload("res://scripts/technology_operations.gd")
static func use(item:Dictionary,progress:float,remaining:float)->float:
	if String(item.get("kind",""))!="specimen" or progress<=0:return 0.0
	var extra:=minf(maxf(0,remaining-progress),minf(progress*.25,Ops.service("specimen_observation")))
	if extra>0:Ops.data().services.specimen_observation-=extra
	return extra
