extends RefCounted
## Selected small copper bracket process; retained stages own no global ledger.
const T=preload("res://scripts/metallurgy_thermal_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func run_for(stage:Dictionary)->Dictionary:
	return T.start([{"duration":float(stage.work),"target":float(stage.get("temperature",20)),
		"power":float(stage.get("heat_power",0)),"loss":.05,"coolant":0.0}])
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0:return
	var state=WorldSimulation.state
	if not job.has("casting_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		if not bool(job.get("tooling_paid",false)):return
		job.casting_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,
			"site":state.resource_settlement_id,"stage":0,"trace":[],"paid":{},"run":run_for(spec.casting_stages[0]),
			"pattern_mass":0.0,"moisture":0.0,"evaporated_water":0.0,"shell_layers":0,"wear":float(job.get("casting_wear",0))}
	var p:Dictionary=job.casting_pending
	if p.site!=state.resource_settlement_id:return
	while work>.000001 and int(p.stage)<spec.casting_stages.size():
		var stage:Dictionary=spec.casting_stages[int(p.stage)]
		if p.paid.is_empty():
			for resource:String in stage.materials:
				if float(state.resource_stockpiles.get(resource,0))<float(stage.materials[resource]):return
			for resource:String in stage.materials:
				state.resource_stockpiles[resource]-=float(stage.materials[resource])
				job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(stage.materials[resource])
			p.paid=stage.materials.duplicate(true)
			p.paid["stage_charged"]=true
			p.pattern_mass+=float(stage.materials.get("EPS Casting Patterns",0))
			p.moisture+=float(stage.materials.get("Freshwater",0))
		var electric:=Ops.service("electricity")
		var auxiliary:=float(stage.get("auxiliary_power",0))
		var used_work:=minf(work,float(stage.work)-float(p.run.work))
		if auxiliary>0:used_work=minf(used_work,electric/auxiliary)
		var receipt:=T.advance(p.run,used_work,maxf(0,electric-used_work*auxiliary)/.01,0)
		if float(receipt.work)<=0:return
		Ops.consume_electricity(float(receipt.energy)*.01+float(receipt.work)*auxiliary)
		job.last_work=float(job.last_work)+float(receipt.work);work-=float(receipt.work)
		if stage.kind=="dry":
			var evaporated:=minf(float(p.moisture),float(receipt.work)*.2)
			p.moisture-=evaporated;p.evaporated_water+=evaporated
		job.progress_days=completed_work(spec,int(p.stage))+float(p.run.work)
		if not T.complete(p.run):return
		if stage.kind=="coat":p.shell_layers+=1
		if stage.kind=="burnout":
			p.pattern_mass*=1.0-clampf((float(p.run.peak)-700.0)/150.0,0,1)
		if stage.kind=="pour":
			p.pour_pattern_mass=float(p.pattern_mass)
			p.pour_moisture=float(p.moisture)
			p.pour_temperature=float(p.run.temperature)
			if spec.casting_kind=="lost_foam":p.pattern_mass=0.0
		p.trace.append({"kind":stage.kind,"paid":p.paid.duplicate(true),"thermal":p.run.duplicate(true),
			"pattern_remaining":p.pattern_mass,"moisture":p.moisture})
		p.stage+=1;p.paid={}
		if int(p.stage)<spec.casting_stages.size():p.run=run_for(spec.casting_stages[int(p.stage)])
	if int(p.stage)==spec.casting_stages.size():finish(job,spec)
static func completed_work(spec:Dictionary,count:int)->float:
	var total:=0.0
	for index:int in range(count):total+=float(spec.casting_stages[index].work)
	return total
static func readings(p:Dictionary,spec:Dictionary)->Dictionary:
	var residual:=float(p.get("pour_pattern_mass",0)) if spec.casting_kind=="investment" else 0.0
	return {"profile_error":snappedf(.1+.35*float(p.wear),.025),
		"section_void_fraction":snappedf(.03+.25*float(p.wear)+float(p.get("pour_moisture",0))+residual,.025),
		"fill_shortfall":snappedf(clampf((1100.0-float(p.get("pour_temperature",20)))/100.0,0,1),.025)}
static func accepted(report:Dictionary)->bool:
	return float(report.profile_error)+.05<=.5 and float(report.section_void_fraction)+.05<=.5 and float(report.fill_shortfall)+.05<=.1
static func finish(job:Dictionary,spec:Dictionary)->void:
	var p:Dictionary=job.casting_pending
	p.observation={"method":"template_fit_and_polished_witness_section","readings":readings(p,spec),"resolution":.025,"uncertainty":.05}
	p.accepted=accepted(p.observation.readings)
	if spec.casting_kind=="investment":p.accepted=p.accepted and float(p.pour_pattern_mass)<.000001 and int(p.shell_layers)>=3
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var output:=String(spec.output if p.accepted else spec.casting_reject)
	stocks[output]=float(stocks.get(output,0))+1.0
	stocks["Spent Casting Molds"]=float(stocks.get("Spent Casting Molds",0))+1.0
	job.casting_last=p.duplicate(true);job.casting_wear=minf(2,float(p.wear)+.08)
	job.completed+=1;job.last_output=int(job.get("last_output",0))+(1 if p.accepted else 0);job.progress_days=0.0
	job.erase("casting_pending")
static func clear(job:Dictionary)->void:
	job.erase("casting_pending");job.erase("casting_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.has("casting_stages") and not job.has("casting_pending") and float(job.get("progress_days",0))>0:return "Missing casting workpiece."
	for key:String in ["casting_pending","casting_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="casting_last"
		if not spec.has("casting_stages") or not p is Dictionary:return "Unexpected casting state."
		if not p.has_all(["recipe","source_job","ordinal","site","stage","trace","paid","run","pattern_mass","moisture","evaporated_water","shell_layers","wear"]):return "Incomplete casting state."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1):return "Invalid casting source."
		if not p.site is String or p.site.length()>128 or not p.stage is int or p.stage<0 or p.stage>spec.casting_stages.size():return "Invalid casting stage."
		if not p.trace is Array or p.trace.size()!=p.stage or not p.paid is Dictionary:return "Invalid casting record."
		for field:String in ["pattern_mass","moisture","evaporated_water","wear"]:
			if not T.number(p[field]) or p[field]<0:return "Invalid casting quantity."
		if p.wear>2 or not p.shell_layers is int or p.shell_layers<0 or p.shell_layers>3:return "Invalid casting condition."
		for index:int in range(p.trace.size()):
			var frame:Variant=p.trace[index];var stage:Dictionary=spec.casting_stages[index]
			var paid:Dictionary=stage.materials.duplicate(true);paid.stage_charged=true
			if not frame is Dictionary or frame.get("kind")!=stage.kind or frame.get("paid")!=paid or not frame.get("thermal") is Dictionary:return "Invalid casting stage history."
			if not T.complete(frame.thermal) or frame.thermal.program!=run_for(stage).program:return "Invalid casting thermal history."
		if finished:
			if p.stage!=spec.casting_stages.size() or not p.has_all(["observation","accepted","pour_temperature","pour_pattern_mass","pour_moisture"]):return "Incomplete casting inspection."
			if not p.observation is Dictionary or p.observation.get("readings")!=readings(p,spec):return "Invalid casting readings."
			var passed:=accepted(p.observation.readings)
			if spec.casting_kind=="investment":passed=passed and float(p.pour_pattern_mass)<.000001 and int(p.shell_layers)>=3
			if not p.accepted is bool or p.accepted!=passed:return "Invalid casting acceptance."
		else:
			if p.stage>=spec.casting_stages.size() or not T.valid(p.run) or p.run.program!=run_for(spec.casting_stages[p.stage]).program:return "Invalid partial casting stage."
			var paid:Dictionary=spec.casting_stages[p.stage].materials.duplicate(true);paid.stage_charged=true
			if not p.paid.is_empty() and p.paid!=paid:return "Invalid casting charge."
			if float(p.run.work)>0 and p.paid.is_empty():return "Missing casting charge."
			if absf(float(job.progress_days)-completed_work(spec,p.stage)-float(p.run.work))>.000001:return "Invalid casting progress."
	return ""
