extends RefCounted
const F=preload("res://scripts/vacuum_melt.gd")
const Pause=preload("res://scripts/thermal_pause.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("vacuum_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.vacuum_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"work":0.0,"energy":0.0,"last_day":int(state.elapsed_days),"pauses":[],"evidence":F.evidence(0,float(spec.vacuum_leak))}
	var p:Dictionary=job.vacuum_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(6.5-float(p.work),Ops.service("electricity")/2.0))
	if used<=0:return
	Ops.consume_electricity(used*2);p.energy+=used*2;p.work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=float(p.work);p.evidence=F.evidence(float(p.work),float(spec.vacuum_leak),p.pauses)
	if float(p.work)+.000001<6.5:return
	p.witness=F.witness(p.evidence);p.report=F.inspect(p.witness)
	var output:=String(spec.output if p.report.qualified else "Rejected Vacuum Copper")
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+float(p.evidence.metal_mass)+float(p.evidence.dissolved_gas)-.03
	state.resource_stockpiles["Spent Vacuum Witness Sections"]=float(state.resource_stockpiles.get("Spent Vacuum Witness Sections",0))+.02
	state.resource_stockpiles["Copper Casting Sprues"]=float(state.resource_stockpiles.get("Copper Casting Sprues",0))+.01
	state.resource_stockpiles["Vacuum Metal Condensate"]=float(state.resource_stockpiles.get("Vacuum Metal Condensate",0))+float(p.evidence.vapor_loss)
	state.resource_stockpiles["Extracted Melt Gas"]=float(state.resource_stockpiles.get("Extracted Melt Gas",0))+float(p.evidence.exhausted_gas)+float(p.evidence.headspace_gas)
	job.vacuum_last=p.duplicate(true);job.erase("vacuum_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.report.qualified else 0)
static func clear(job:Dictionary)->void:
	job.erase("vacuum_pending");job.erase("vacuum_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.get("vacuum_trial",false) and not job.has("vacuum_pending") and float(job.get("progress_days",0))>0:return "Missing vacuum specimen."
	for key:String in ["vacuum_pending","vacuum_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="vacuum_last"
		if not spec.get("vacuum_trial",false) or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","energy","evidence"]):return "Invalid vacuum record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid vacuum source."
		if not p.site is String or p.site.length()>128:return "Invalid vacuum store."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.work) or p.work<0 or p.work>6.500001 or not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.energy) or absf(float(p.energy)-float(p.work)*2)>.000001:return "Invalid paid vacuum work."
		if not Pause.valid(p,6.0):return "Invalid vacuum interruptions."
		if p.evidence!=F.evidence(float(p.work),float(spec.vacuum_leak),p.pauses):return "Invalid vacuum specimen evidence."
		if finished:
			if absf(float(p.work)-6.5)>.000001 or p.get("witness")!=F.witness(p.evidence) or p.get("report")!=F.inspect(p.witness):return "Invalid vacuum report."
		elif absf(float(job.progress_days)-float(p.work))>.000001:return "Invalid vacuum progress."
	return ""
static func synchronize_idle(job:Dictionary,work:float)->void:
	if not job.has("vacuum_pending"):return
	var p:Dictionary=job.vacuum_pending
	var state=WorldSimulation.state
	var available:bool=work>0 and not bool(job.get("paused",false)) and p.site==state.resource_settlement_id and Ops.service("electricity")>0
	Pause.synchronize(p,available,6.0,int(state.elapsed_days))
	var spec:=preload("res://scripts/civilian_industry.gd").product(String(job.item))
	p.evidence=F.evidence(float(p.work),float(spec.vacuum_leak),p.pauses)
