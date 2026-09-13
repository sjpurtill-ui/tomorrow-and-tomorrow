extends RefCounted
const F=preload("res://scripts/foam_pattern_measurement.gd")
const Pause=preload("res://scripts/thermal_pause.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("pattern_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.pattern_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"work":0.0,"energy":0.0,"wear":float(job.get("pattern_wear",0)),"last_day":int(state.elapsed_days),"pauses":[],"evidence":F.evidence(0,float(job.get("pattern_wear",0)))}
	var p:Dictionary=job.pattern_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(4.0-float(p.work),Ops.service("electricity")/.5))
	if used<=0:return
	Ops.consume_electricity(used*.5);p.energy+=used*.5;p.work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=float(p.work);p.evidence=F.evidence(float(p.work),float(p.wear),p.pauses)
	if float(p.work)+.000001<4.0:return
	p.witness=F.witness(p.evidence);p.report=F.inspect(p.witness)
	var output:=String(spec.output if p.report.qualified else "Rejected EPS Patterns")
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
	state.resource_stockpiles["Pattern Expansion Exhaust"]=float(state.resource_stockpiles.get("Pattern Expansion Exhaust",0))+.002
	state.resource_stockpiles["Spent Pattern Water"]=float(state.resource_stockpiles.get("Spent Pattern Water",0))+.2
	job.pattern_wear=minf(2,float(p.wear)+.02)
	job.pattern_last=p.duplicate(true);job.erase("pattern_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.report.qualified else 0)
static func clear(job:Dictionary)->void:
	job.erase("pattern_pending");job.erase("pattern_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if job.has("pattern_wear") and (not preload("res://scripts/metallurgy_thermal_cycle.gd").number(job.pattern_wear) or job.pattern_wear<0 or job.pattern_wear>2):return "Invalid retained pattern wear."
	if spec.get("pattern_trial",false) and not job.has("pattern_pending") and float(job.get("progress_days",0))>0:return "Missing pattern specimen."
	for key:String in ["pattern_pending","pattern_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="pattern_last"
		if not spec.get("pattern_trial",false) or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","energy","evidence"]):return "Invalid pattern record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid pattern source."
		if not p.site is String or p.site.length()>128:return "Invalid pattern store."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.work) or p.work<0 or p.work>4.000001 or not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.energy) or absf(float(p.energy)-float(p.work)*.5)>.000001:return "Invalid paid pattern work."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.get("wear")) or p.wear<0 or p.wear>2:return "Invalid pattern mold wear."
		if not Pause.valid(p,4.0):return "Invalid pattern interruptions."
		if p.evidence!=F.evidence(float(p.work),float(p.wear),p.pauses):return "Invalid pattern specimen evidence."
		if finished:
			if absf(float(p.work)-4.0)>.000001 or p.get("witness")!=F.witness(p.evidence) or p.get("report")!=F.inspect(p.witness):return "Invalid pattern report."
		elif absf(float(job.progress_days)-float(p.work))>.000001:return "Invalid pattern progress."
	return ""
static func synchronize_idle(job:Dictionary,work:float)->void:
	if not job.has("pattern_pending"):return
	var p:Dictionary=job.pattern_pending
	var state=WorldSimulation.state
	var available:bool=work>0 and not bool(job.get("paused",false)) and p.site==state.resource_settlement_id and Ops.service("electricity")>0
	Pause.synchronize(p,available,4.0,int(state.elapsed_days))
	p.evidence=F.evidence(float(p.work),float(p.wear),p.pauses)
