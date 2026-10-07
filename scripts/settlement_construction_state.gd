extends RefCounted
## Read only the owner's recorded work. No date, animation clock or stock lookup
## can manufacture progress; instantaneous completed conversions stay complete.
const Fabric:=preload("res://scripts/settlement_fabric_operations.gd")

static func state(plot:Dictionary)->Dictionary:
	var status:=String(plot.get("status","active"))
	if status=="under_construction":
		var progress:=float(plot.get("construction_progress",0.0))
		if not is_finite(progress):progress=0.0
		return {"mode":"new","stage":clampi(floori(clampf(progress,0.0,1.0)*4.0),0,3),"method":""}
	if status in ["active","stressed","damaged"]:
		var job:Variant=plot.get("fabric_job",{})
		if job is Dictionary and not job.is_empty() and Fabric.valid_job(job):
			# The same bounded access scaffold stays up through assembly and
			# inspection. Fractions cannot rebuild identical overlay geometry.
			return {"mode":"retrofit","stage":0,"method":String(job.method)}
	return {"mode":"","stage":4,"method":""}

static func signature(plot:Dictionary)->Array:
	var recorded:=state(plot)
	return [recorded.mode,recorded.stage,recorded.method]
