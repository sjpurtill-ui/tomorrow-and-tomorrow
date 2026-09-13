extends RefCounted
## Adapter for retained machine work inside the existing persistent workshop job.
## The pending workpiece remains in its job; it is never fungible accepted stock.
const Skiving=preload("res://scripts/skiving_motion.gd")
const Support=preload("res://scripts/machine_support.gd")
const Measurement=preload("res://scripts/machine_process_measurement.gd")
const Program=preload("res://scripts/machine_coordinate_program.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	var state=WorldSimulation.state
	var ops=preload("res://scripts/technology_operations.gd")
	if work<=0 or not spec.has("machine_program") or not Program.valid_program(spec.machine_program):return
	if spec.has("machine_kind") and not job.has("machine_wear"):
		job.machine_wear=float(job.get("machine_wear_history",{}).get(spec.machine_kind,0))
	if not job.has("machine_pending") and spec.has("machine_kind"):
		work=Support.prepare(job,spec,work)
		if work<=0:return
	if not job.has("machine_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		if ops.service("electricity")<=0:return
		job.machine_pending={"recipe":String(job.item),"source_job":int(job.id),"ordinal":int(job.completed)+1,"site":String(state.resource_settlement_id),"reserved":spec.materials.duplicate(true),"run":Program.start(spec.machine_program),"phase":"machining","tool_wear":float(job.get("machine_wear",0))}
		if spec.get("machine_kind","")=="skiving":job.machine_pending.synchronization=Skiving.start()
		if spec.has("machine_witness"):
			job.machine_pending.witness=spec.machine_witness.duplicate(true)
			job.machine_pending.witness.merge({"source_job":int(job.id),"ordinal":int(job.completed)+1,"site":String(state.resource_settlement_id),"disposition":"reserved"})
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
	var pending:Dictionary=job.machine_pending
	if pending.site!=state.resource_settlement_id:return
	if pending.phase=="inspection":
		inspect(job,spec,work)
		return
	work=Support.service_filter(job,work)
	if work<=0:return
	var rate:=float(spec.power)/float(spec.days)
	var receipt:=Program.advance(pending.run,Support.limit_work(job,work,spec),ops.service("electricity"),rate)
	if spec.get("machine_kind","")=="skiving":Skiving.advance(pending.synchronization,float(receipt.work),float(pending.run.position.z),float(pending.tool_wear))
	Support.consume(job,float(receipt.work))
	var installed:Dictionary=job.get("machine_support",{}).get("installed",{})
	pending.film_work=float(pending.get("film_work",0))+(float(receipt.work) if installed.has("fluid_film_bearings") else 0.0)
	pending.filtered_work=float(pending.get("filtered_work",0))+(float(receipt.work) if installed.has("cutting_fluid_management") else 0.0)
	ops.consume_electricity(float(receipt.energy))
	job.last_work=float(job.last_work)+float(receipt.work)
	# Inspection belongs to the same reserved workpiece and will consume the
	# remaining recipe work. No accepted output is minted at path completion.
	job.progress_days=float(pending.run.work)
	if Program.complete(pending.run):
		pending.phase="inspection"
		if spec.has("machine_kind"):
			pending.physical=physical(spec,pending)
			pending.inspection_work=0.0
static func clear(job:Dictionary)->void:
	# Retained installed heads keep wear across retooling. A partly used head
	# also retains its spent machining share; abandoning a part cannot renew it.
	var spec:Dictionary=load("res://scripts/civilian_industry.gd").product(String(job.get("item","")))
	if spec.has("machine_kind"):
		if not job.has("machine_wear_history"):job.machine_wear_history={}
		var wear:=float(job.get("machine_wear",job.machine_wear_history.get(spec.machine_kind,0)))
		if job.has("machine_pending"):wear+=.08*minf(1,float(job.machine_pending.run.work)/3.0)
		job.machine_wear_history[spec.machine_kind]=minf(2,wear)
	# Changing production abandons the reserved workpiece; no free refund.
	job.erase("machine_pending")
	job.erase("machine_last")
	job.erase("machine_wear")
	job.erase("machine_support")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	var history:Variant=job.get("machine_wear_history",{})
	if not history is Dictionary or history.size()>10:return "Invalid retained machine heads."
	for kind:Variant in history:
		if kind not in ["skiving","wire_edm","sinker_edm","ecm","waterjet","ultrasonic","forming","joining","honing","superfinishing"] or not Program.finite(history[kind],2) or history[kind]<0:return "Invalid retained head wear."
	if not spec.has("machine_program"):
		for key:String in ["machine_pending","machine_last","machine_wear","machine_support"]:
			if job.has(key):return "Unexpected machine state."
		return ""
	if job.has("machine_support") and not Support.valid(job.machine_support,int(job.completed)):return "Invalid machine support records."
	if not Program.finite(job.get("machine_wear",0),2) or float(job.get("machine_wear",0))<0:return "Invalid machine wear."
	if job.has("machine_last") and not valid_piece(job.machine_last,job,spec,true):return "Invalid machine inspection report."
	if not job.has("machine_pending"):
		return "Missing machine workpiece." if float(job.get("progress_days",0))>0 else ""
	if not valid_piece(job.machine_pending,job,spec,false):return "Invalid machine workpiece."
	var pending:Dictionary=job.machine_pending
	if absf(float(job.progress_days)-float(pending.run.work)-float(pending.get("inspection_work",0)))>.000001:return "Inconsistent machine progress."
	return ""
static func valid_piece(p:Variant,job:Dictionary,spec:Dictionary,finished:bool)->bool:
	if not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","run","phase","tool_wear"]):return false
	if p.recipe!=job.item or p.source_job!=job.id or p.ordinal!=int(job.completed)+(0 if finished else 1) or p.reserved!=spec.materials:return false
	if not p.site is String or p.site.length()>128 or p.phase not in ["machining","inspection"]:return false
	if not Program.valid(p.run) or p.run.program!=spec.machine_program or not Program.finite(p.tool_wear,2) or p.tool_wear<0:return false
	# The coordinate runner is recipe-independent; this adapter owns the paid
	# energy rate and must verify it for both the retained total and each frame.
	var energy_rate:=float(spec.power)/float(spec.days)
	if absf(float(p.run.energy)-float(p.run.work)*energy_rate)>.000001:return false
	for frame:Dictionary in p.run.trace:
		if absf(float(frame.energy)-float(frame.work)*energy_rate)>.000001:return false
	if Program.complete(p.run)!=(p.phase=="inspection"):return false
	for field:String in ["film_work","filtered_work"]:
		if not Program.finite(p.get(field,0)) or float(p.get(field,0))<0 or float(p.get(field,0))>float(p.run.work)+.000001:return false
	var checked:Variant=p.get("inspection_work",0)
	if not Program.finite(checked) or checked<0 or float(checked)+float(p.run.work)>float(spec.days)+.000001:return false
	if p.has("inspection_paid") and p.inspection_paid!=spec.get("machine_inspection",{}):return false
	if float(checked)>0 and not p.has("inspection_paid"):return false
	if spec.get("machine_kind","")=="skiving" and not Skiving.valid(p.get("synchronization"),p.run,float(p.tool_wear)):return false
	if p.phase=="inspection" and spec.has("machine_kind"):
		if p.get("physical")!=physical(spec,p):return false
	if spec.has("machine_witness") and not valid_witness(p,job,spec,finished):return false
	if finished:
		if not p.has_all(["observation","accepted","inspection_paid"]) or not p.accepted is bool:return false
		if absf(float(checked)+float(p.run.work)-float(spec.days))>.000001:return false
		if p.observation!=Measurement.observed(p.physical,spec) or p.accepted!=Measurement.accepted(p.observation,spec.machine_limits):return false
	return true

static func inspect(job:Dictionary,spec:Dictionary,work:float)->void:
	if not spec.has("machine_limits"):return
	var state=WorldSimulation.state
	var pending:Dictionary=job.machine_pending
	if spec.get("machine_kind","")=="skiving" and not Skiving.valid(pending.get("synchronization"),pending.run,float(pending.tool_wear)):return
	if spec.has("machine_witness") and not valid_witness(pending,job,spec,false):return
	for apparatus:String in spec.machine_inspection_tools:
		if not bool(job.get("tooling_paid",false)) or float(job.get("tooling",{}).get(apparatus,0))<float(spec.machine_inspection_tools[apparatus]):return
	if not pending.has("inspection_paid"):
		for resource:String in spec.machine_inspection:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.machine_inspection[resource]):return
		for resource:String in spec.machine_inspection:
			state.resource_stockpiles[resource]-=float(spec.machine_inspection[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.machine_inspection[resource])
		pending.inspection_paid=spec.machine_inspection.duplicate(true)
		if pending.has("witness"):pending.witness.disposition="prepared"
	var ops=preload("res://scripts/technology_operations.gd")
	var remaining:=float(spec.days)-float(pending.run.work)-float(pending.inspection_work)
	var rate:=float(spec.power)/float(spec.days)
	var used:=minf(work,minf(remaining,ops.service("electricity")/rate))
	if used<=0:return
	ops.consume_electricity(used*rate)
	pending.inspection_work+=used;job.last_work+=used
	job.progress_days=float(pending.run.work)+float(pending.inspection_work)
	if used+.000000001<remaining:return
	if pending.has("witness"):pending.witness.disposition="destroyed"
	pending.observation=Measurement.observed(pending.physical,spec)
	var passed:=Measurement.accepted(pending.observation,spec.machine_limits)
	var output:=String(spec.output if passed else spec.machine_reject)
	state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
	job.machine_last=pending.duplicate(true);job.machine_last.accepted=passed
	var total_work:=maxf(.000001,float(pending.run.work))
	var film_fraction:=clampf(float(pending.get("film_work",0))/total_work,0,1)
	var filtered_fraction:=clampf(float(pending.get("filtered_work",0))/total_work,0,1)
	job.machine_wear=minf(2,float(job.get("machine_wear",0))+.08*(1-.4*film_fraction-.2*filtered_fraction))
	job.completed+=1;job.progress_days=0.0
	job.last_output=int(job.get("last_output",0))+(1 if passed else 0)
	job.erase("machine_pending")

static func valid_witness(p:Dictionary,job:Dictionary,spec:Dictionary,finished:bool)->bool:
	var witness:Variant=p.get("witness")
	if not witness is Dictionary or witness.get("material")!=spec.machine_witness.material or witness.get("amount")!=spec.machine_witness.amount:return false
	if float(witness.amount)>float(p.reserved.get(witness.material,0)):return false
	if witness.get("source_job")!=job.id or witness.get("ordinal")!=p.ordinal or witness.get("site")!=p.site:return false
	if finished:return witness.get("disposition")=="destroyed"
	return witness.get("disposition")==("prepared" if p.has("inspection_paid") else "reserved")

static func physical(spec:Dictionary,pending:Dictionary)->Dictionary:
	var result:=Measurement.produced(String(spec.machine_kind),pending.run,float(pending.tool_wear))
	if spec.machine_kind=="skiving":result.pitch_error+=Skiving.phase_error(pending.synchronization)*10.0
	return result
