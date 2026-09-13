extends RefCounted
## Retained thermal work under an existing workshop job, awaiting inspection.
const Thermal=preload("res://scripts/metallurgy_thermal_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Sections=preload("res://scripts/metallurgy_sections.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not spec.has("thermal_program") or not Thermal.valid_program(spec.thermal_program):return
	var state=WorldSimulation.state
	if not bool(job.get("tooling_paid",false)):return
	for resource:String in spec.tooling:
		if float(job.get("tooling",{}).get(resource,0))<float(spec.tooling[resource]):return
	if not job.has("metallurgy_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		if Ops.service("electricity")<=0:return
		job.metallurgy_pending={"recipe":String(job.item),"source_job":int(job.id),
			"ordinal":int(job.completed)+1,"site":String(state.resource_settlement_id),
			"reserved":spec.materials.duplicate(true),"phase":"thermal",
			"run":Thermal.start(spec.thermal_program,float(spec.thermal_capacity))}
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
	var pending:Dictionary=job.metallurgy_pending
	if pending.site!=state.resource_settlement_id:return
	if pending.phase=="inspection":
		Sections.advance(job,spec,work)
		if pending.get("section",{}).get("disposition")=="observed":finish(job,spec)
		return
	var energy_scale:=float(spec.get("thermal_energy_scale",1.0))
	var receipt:=Thermal.advance(pending.run,work,Ops.service("electricity")/energy_scale,float(state.resource_stockpiles.get("Freshwater",0)))
	Ops.consume_electricity(float(receipt.energy)*energy_scale)
	if float(receipt.coolant)>0:
		state.resource_stockpiles["Freshwater"]-=float(receipt.coolant)
		job.last_consumed["Freshwater"]=float(job.last_consumed.get("Freshwater",0))+float(receipt.coolant)
		state.resource_stockpiles["Spent Quench Water"]=float(state.resource_stockpiles.get("Spent Quench Water",0))+float(receipt.coolant)
	job.last_work=float(job.last_work)+float(receipt.work)
	job.progress_days=float(pending.run.work)
	if Thermal.complete(pending.run):pending.phase="inspection"
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if job.has("metallurgy_last"):
		var last_error:=validate_piece(job,spec,job.metallurgy_last,true)
		if not last_error.is_empty():return last_error
	if not job.has("metallurgy_pending"):
		return "Missing metallurgy workpiece." if spec.has("thermal_program") and float(job.get("progress_days",0))>0 else ""
	var error:=validate_piece(job,spec,job.metallurgy_pending,false)
	if not error.is_empty():return error
	var pending:Dictionary=job.metallurgy_pending
	if absf(float(job.progress_days)-float(pending.run.work)-float(pending.get("section",{}).get("work",0)))>Thermal.EPS:return "Inconsistent metallurgy work."
	return ""
static func validate_piece(job:Dictionary,spec:Dictionary,pending:Variant,finished:bool)->String:
	if not spec.has("thermal_program") or not pending is Dictionary:return "Unexpected metallurgy workpiece."
	if not pending.has_all(["recipe","source_job","ordinal","site","reserved","phase","run"]):return "Incomplete metallurgy workpiece."
	if pending.recipe!=job.item or pending.source_job!=job.id or pending.ordinal!=int(job.completed)+(0 if finished else 1) or pending.reserved!=spec.materials:return "Wrong metallurgy source."
	if not pending.site is String or pending.site.length()>128:return "Invalid metallurgy site."
	if not Thermal.valid(pending.run) or pending.run.program!=spec.thermal_program or pending.run.capacity!=spec.thermal_capacity:return "Invalid metallurgy thermal history."
	if pending.phase!=("inspection" if Thermal.complete(pending.run) else "thermal"):return "Inconsistent metallurgy stage."
	if not Sections.valid(pending,spec):return "Invalid metallurgy section."
	if finished:
		if pending.get("section",{}).get("disposition")!="observed" or not pending.get("accepted") is bool or pending.accepted!=accepted(pending):return "Invalid metallurgy acceptance."
	return ""
static func accepted(p:Dictionary)->bool:
	var observation:Dictionary=p.get("section",{}).get("observation",{})
	return bool(observation.get("qualified",false)) and float(p.run.hot_work)>=1.0 and float(p.run.peak)>=800 and float(p.run.peak)<=950 and float(p.run.temperature)<=150 and float(observation.get("mean_intercept_um",1000))+float(observation.get("uncertainty_um",1000))<=12.0
static func finish(job:Dictionary,spec:Dictionary)->void:
	var p:Dictionary=job.metallurgy_pending
	if not Sections.valid(p,spec):return
	var passed:=accepted(p)
	var output:=String(spec.output if passed else spec.thermal_reject)
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	stocks[output]=float(stocks.get(output,0))+1.0
	job.metallurgy_last=p.duplicate(true);job.metallurgy_last.accepted=passed
	job.completed+=1;job.progress_days=0.0
	job.last_output=int(job.get("last_output",0))+(1 if passed else 0)
	job.erase("metallurgy_pending")
static func clear(job:Dictionary)->void:
	# Retooling discards the retained piece; reserved material is not refunded.
	job.erase("metallurgy_pending")
	job.erase("metallurgy_last")
