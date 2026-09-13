extends RefCounted
const S=preload("res://scripts/residual_slitting.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("slitting_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.slitting_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,
			"reserved":spec.materials.duplicate(true),"work":0.0,"energy":0.0,"readings":[]}
	var p:Dictionary=job.slitting_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(4.0-float(p.work),Ops.service("electricity")))
	if used<=0:return
	Ops.consume_electricity(used);p.energy+=used;p.work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=float(p.work)
	# The first paid work unit forms and unloads the actual reserved coupon.
	if float(p.work)>=1.0 and not p.has("piece"):p.piece=S.prepared(float(spec.slitting_curvature))
	while p.readings.size()<3 and float(p.work)+.000001>=float(p.readings.size()+2):
		p.readings.append(S.reading(p.piece,p.readings.size()+1))
	if p.readings.size()!=3:return
	p.observation=S.measure(p.readings)
	var output:=String(spec.output if p.observation.qualified else "Unresolved Slitting Records")
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
	state.resource_stockpiles["Spent Slitting Coupons"]=float(state.resource_stockpiles.get("Spent Slitting Coupons",0))+.2
	job.slitting_last=p.duplicate(true);job.erase("slitting_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.observation.qualified else 0)
static func clear(job:Dictionary)->void:
	job.erase("slitting_pending");job.erase("slitting_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.has("slitting_curvature") and not job.has("slitting_pending") and float(job.get("progress_days",0))>0:return "Missing slitting specimen."
	for key:String in ["slitting_pending","slitting_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="slitting_last"
		if not spec.has("slitting_curvature") or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","energy","readings"]):return "Invalid slitting record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid slitting source."
		if not p.site is String or p.site.length()>128:return "Invalid slitting store."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.work) or p.work<0 or p.work>4.000001 or p.energy!=p.work:return "Invalid paid slitting work."
		if float(p.work)>=1.0:
			if p.get("piece")!=S.prepared(float(spec.slitting_curvature)):return "Invalid slitting preparation."
		elif p.has("piece"):return "Unpaid slitting preparation."
		if not p.readings is Array or p.readings.size()!=clampi(int(floor(float(p.work)+.000001))-1,0,3):return "Invalid slit depths."
		for index:int in range(p.readings.size()):
			if p.readings[index]!=S.reading(p.piece,index+1):return "Invalid strain release record."
		if finished:
			if p.readings.size()!=3 or p.get("observation")!=S.measure(p.readings):return "Invalid residual stress report."
		elif absf(float(job.progress_days)-float(p.work))>.000001:return "Invalid slitting progress."
	return ""
