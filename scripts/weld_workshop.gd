extends RefCounted
const F=preload("res://scripts/weld_metallurgy.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("weld_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.weld_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"work":0.0,"energy":0.0,"evidence":F.evidence(0,float(spec.weld_cooling))}
	var p:Dictionary=job.weld_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(5.5-float(p.work),Ops.service("electricity")/2.0))
	if used<=0:return
	Ops.consume_electricity(used*2);p.energy+=used*2;p.work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=float(p.work);p.evidence=F.evidence(float(p.work),float(spec.weld_cooling))
	if float(p.work)+.000001<5.5:return
	p.witness=F.witness(p.evidence);p.report=F.inspect(p.witness)
	var output:=String(spec.output if p.report.qualified else "Rejected Welded Straps")
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
	state.resource_stockpiles["Spent Weld Witness Sections"]=float(state.resource_stockpiles.get("Spent Weld Witness Sections",0))+.02
	job.weld_last=p.duplicate(true);job.erase("weld_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.report.qualified else 0)
static func clear(job:Dictionary)->void:
	job.erase("weld_pending");job.erase("weld_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.get("weld_trial",false) and not job.has("weld_pending") and float(job.get("progress_days",0))>0:return "Missing weld specimen."
	for key:String in ["weld_pending","weld_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="weld_last"
		if not spec.get("weld_trial",false) or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","energy","evidence"]):return "Invalid weld record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid weld source."
		if not p.site is String or p.site.length()>128:return "Invalid weld store."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.work) or p.work<0 or p.work>5.500001 or not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.energy) or absf(float(p.energy)-float(p.work)*2)>.000001:return "Invalid paid weld work."
		if p.evidence!=F.evidence(float(p.work),float(spec.weld_cooling)):return "Invalid weld specimen evidence."
		if finished:
			if absf(float(p.work)-5.5)>.000001 or p.get("witness")!=F.witness(p.evidence) or p.get("report")!=F.inspect(p.witness):return "Invalid weld report."
		elif absf(float(job.progress_days)-float(p.work))>.000001:return "Invalid weld progress."
	return ""
