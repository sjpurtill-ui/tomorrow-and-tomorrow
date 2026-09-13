extends RefCounted
const Source=preload("res://scripts/formed_workpiece.gd")
const F=preload("res://scripts/fracture_trial.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func evidence(work:float,source:Dictionary={})->Dictionary:
	var resistance:=2.0
	if not source.is_empty():
		var plastic_work:=0.0
		for y:float in Source.S.Y:plastic_work+=maxf(0,absf(float(source.piece.curvature)*y)-1.0/Source.S.E)
		resistance=2.0/(1.0+plastic_work*100.0)
	var r:={"geometry":F.geometry()}
	if work<1:return r
	var cycles:=mini(1000,int(floor(maxf(0,work-1.0)*500.0+.000001)))
	r.precrack=F.precrack(cycles)
	if work<3:return r
	r.initial_front=r.precrack.front.duplicate();r.trace=[]
	var count:=mini(15,int(floor((work-3.0)*15.0+.000001)))
	for index:int in range(count):
		var point:=F.sample(index,float(r.initial_front[1]),r.geometry,resistance)
		r.trace.append({"force":point.force,"opening":point.opening})
	if work+0.000001>=4.5:
		var extension:=float(F.sample(14,float(r.initial_front[1]),r.geometry,resistance).crack_extension)
		r.final_front=[]
		for initial:float in r.initial_front:r.final_front.append(snappedf(initial+extension,.0001))
	return r
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	var state=WorldSimulation.state
	for apparatus:String in spec.tooling:
		if float(job.get("tooling",{}).get(apparatus,0))<float(spec.tooling[apparatus]):return
	if not job.has("fracture_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		var source:Dictionary={}
		if spec.get("fracture_external",false):
			source=Source.take()
			if source.is_empty():return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.fracture_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"work":0.0,"energy":0.0,"evidence":evidence(0)}
		if not source.is_empty():
			job.fracture_pending.external_source=source
			job.fracture_pending.evidence=evidence(0,source)
	var p:Dictionary=job.fracture_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(4.5-float(p.work),Ops.service("electricity")/2.0))
	if used<=0:return
	Ops.consume_electricity(used*2);p.energy+=used*2;p.work+=used
	job.last_work=float(job.last_work)+used;job.progress_days=float(p.work);p.evidence=evidence(float(p.work),p.get("external_source",{}))
	if float(p.work)+.000001<4.5:return
	p.report=F.measure(p.evidence)
	p.accepted=bool(p.report.qualified) and (not spec.get("fracture_external",false) or float(p.report.get("provisional_k",0))>=1.5)
	var output:=String(spec.output if p.accepted else ("Toughness-Rejected Steel Blanks" if spec.get("fracture_external",false) else "Comparison Fracture Records"))
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+(.8 if spec.get("fracture_external",false) else 1.0)
	state.resource_stockpiles["Broken Fracture Specimens"]=float(state.resource_stockpiles.get("Broken Fracture Specimens",0))+.2
	job.fracture_last=p.duplicate(true);job.erase("fracture_pending")
	job.completed+=1;job.progress_days=0.0;job.last_output=int(job.get("last_output",0))+(1 if p.accepted else 0)
static func clear(job:Dictionary)->void:
	job.erase("fracture_pending");job.erase("fracture_last")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.get("fracture_trial",false) and not job.has("fracture_pending") and float(job.get("progress_days",0))>0:return "Missing fracture specimen."
	for key:String in ["fracture_pending","fracture_last"]:
		if not job.has(key):continue
		var p:Variant=job[key];var finished:=key=="fracture_last"
		if not spec.get("fracture_trial",false) or not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","energy","evidence"]):return "Invalid fracture record."
		if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return "Invalid fracture source."
		if not p.site is String or p.site.length()>128:return "Invalid fracture store."
		if not F.N.number(p.work) or p.work<0 or p.work>4.500001 or not F.N.number(p.energy) or absf(float(p.energy)-float(p.work)*2)>.000001:return "Invalid paid fracture work."
		if spec.get("fracture_external",false) and (not Source.valid_source(p.get("external_source")) or not p.external_source.consumed or p.external_source.site!=p.site):return "Invalid external fracture workpiece."
		if p.evidence!=evidence(float(p.work),p.get("external_source",{})):return "Invalid fracture specimen evidence."
		if finished:
			if absf(float(p.work)-4.5)>.000001 or p.get("report")!=F.measure(p.evidence):return "Invalid fracture report."
			var passed:bool=bool(p.report.qualified) and (not spec.get("fracture_external",false) or float(p.report.get("provisional_k",0))>=1.5)
			if p.get("accepted")!=passed:return "Invalid fracture disposition."
		elif absf(float(job.progress_days)-float(p.work))>.000001:return "Invalid fracture progress."
	return ""
