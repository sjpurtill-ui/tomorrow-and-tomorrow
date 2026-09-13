extends RefCounted
const Cycle=preload("res://scripts/induction_case_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const INSPECTION={"Steel Tool Bits":.002,"Graded Alumina Abrasive":.01,"Paper":.01}
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("induction_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.induction_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,
			"reserved":spec.materials.duplicate(true),"run":Cycle.start(float(spec.induction_frequency),float(spec.induction_gap)),"last_day":int(state.elapsed_days),"work_credit":0.0,"inspection_work":0.0,"inspection_paid":false}
	var p:Dictionary=job.induction_pending
	if p.site!=state.resource_settlement_id:return
	synchronize_idle(job,work)
	while work>.000001 and int(p.run.tick)<Cycle.TICKS:
		var cost:=Cycle.cost(int(p.run.tick))
		if Ops.service("electricity")<float(cost.electricity) or float(state.resource_stockpiles.get("Freshwater",0))<float(cost.water):return
		var used_work:=minf(work,Cycle.STEP-float(p.get("work_credit",0)))
		p.work_credit=float(p.get("work_credit",0))+used_work;work-=used_work
		job.last_work=float(job.last_work)+used_work
		job.progress_days=float(p.run.tick)*Cycle.STEP+float(p.work_credit)
		if float(p.work_credit)+.000001<Cycle.STEP:return
		p.work_credit=0.0
		Ops.consume_electricity(float(cost.electricity))
		if float(cost.water)>0:
			state.resource_stockpiles.Freshwater-=float(cost.water)
			job.last_consumed.Freshwater=float(job.last_consumed.get("Freshwater",0))+float(cost.water)
			state.resource_stockpiles["Spent Quench Water"]=float(state.resource_stockpiles.get("Spent Quench Water",0))+float(cost.water)
		Cycle.step(p.run)
		job.progress_days=float(p.run.tick)*Cycle.STEP
	if int(p.run.tick)<Cycle.TICKS or work<=.000001:return
	if float(p.run.temperatures.max())>150:return
	if not p.inspection_paid:
		for resource:String in INSPECTION:
			if float(state.resource_stockpiles.get(resource,0))<float(INSPECTION[resource]):return
		for resource:String in INSPECTION:
			state.resource_stockpiles[resource]-=float(INSPECTION[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(INSPECTION[resource])
		p.inspection_paid=true
	var used:=minf(work,minf(.5-float(p.inspection_work),Ops.service("electricity")/.4))
	Ops.consume_electricity(used*.4);p.inspection_work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=Cycle.WORK+float(p.inspection_work)
	if float(p.inspection_work)+.000001<.5:return
	p.observation=Cycle.indentation(p.run);p.accepted=Cycle.accepted(p.observation)
	var output:=String(spec.output if p.accepted else spec.induction_reject)
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
	state.resource_stockpiles["Spent Metallographic Sections"]=float(state.resource_stockpiles.get("Spent Metallographic Sections",0))+.02
	job.induction_last=p.duplicate(true);job.erase("induction_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.accepted else 0)
static func clear(job:Dictionary)->void:
	job.erase("induction_pending");job.erase("induction_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.has("induction_frequency") and not job.has("induction_pending") and float(job.get("progress_days",0))>0:return "Missing induction workpiece."
	for key:String in ["induction_pending","induction_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="induction_last"
		if not spec.has("induction_frequency") or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","run","inspection_work","inspection_paid"]):return "Invalid induction record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid induction source."
		if not p.site is String or p.site.length()>128 or not Cycle.valid(p.run):return "Invalid induction cycle."
		if not p.get("last_day") is int or p.last_day<0:return "Invalid induction day."
		if p.run.frequency!=spec.induction_frequency or p.run.gap!=spec.induction_gap:return "Changed induction settings."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.inspection_work) or p.inspection_work<0 or p.inspection_work>.500001 or not p.inspection_paid is bool:return "Invalid induction inspection."
		var credit:Variant=p.get("work_credit",0.0)
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(credit) or credit<0 or credit>=Cycle.STEP or (p.run.tick==Cycle.TICKS and credit!=0):return "Invalid induction work credit."
		if p.inspection_paid and (p.run.tick!=Cycle.TICKS or float(p.run.temperatures.max())>150):return "Premature induction section."
		if p.inspection_work>0 and (not p.inspection_paid or p.run.tick!=Cycle.TICKS):return "Unpaid induction inspection."
		if finished:
			if p.run.tick!=Cycle.TICKS or absf(float(p.inspection_work)-.5)>.000001 or p.get("observation")!=Cycle.indentation(p.run) or p.get("accepted")!=Cycle.accepted(p.observation):return "Invalid induction outcome."
		elif absf(float(job.progress_days)-float(p.run.tick)*Cycle.STEP-float(p.inspection_work)-float(credit))>.000001:return "Invalid induction progress."
	return ""

static func synchronize_idle(job:Dictionary,work:float)->void:
	if not job.has("induction_pending"):return
	var p:Dictionary=job.induction_pending
	var state=WorldSimulation.state
	var today:=int(state.elapsed_days)
	var delta:=maxi(0,today-int(p.last_day))
	if delta==0:return
	var cost:=Cycle.cost(int(p.run.tick)) if int(p.run.tick)<Cycle.TICKS else {"electricity":.2,"water":0.0}
	var unavailable:bool=work<=0 or bool(job.get("paused",false)) or p.site!=state.resource_settlement_id or Ops.service("electricity")<float(cost.electricity) or float(state.resource_stockpiles.get("Freshwater",0))<float(cost.water)
	var missed:=delta if unavailable else maxi(0,delta-1)
	if missed>0:Cycle.idle(p.run,missed)
	p.last_day=today
