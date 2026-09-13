extends RefCounted
## Adapter for retained machine work inside the existing persistent workshop job.
## The pending workpiece remains in its job; it is never fungible accepted stock.
const Program=preload("res://scripts/machine_coordinate_program.gd")
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	var state=WorldSimulation.state
	var ops=preload("res://scripts/technology_operations.gd")
	if work<=0 or not spec.has("machine_program") or not Program.valid_program(spec.machine_program):return
	if not job.has("machine_pending"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		if ops.service("electricity")<=0:return
		job.machine_pending={"recipe":String(job.item),"source_job":int(job.id),"ordinal":int(job.completed)+1,"site":String(state.resource_settlement_id),"reserved":spec.materials.duplicate(true),"run":Program.start(spec.machine_program),"phase":"machining"}
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
	var pending:Dictionary=job.machine_pending
	if pending.site!=state.resource_settlement_id or pending.phase!="machining":return
	var rate:=float(spec.power)/float(spec.days)
	var receipt:=Program.advance(pending.run,work,ops.service("electricity"),rate)
	ops.consume_electricity(float(receipt.energy))
	job.last_work=float(job.last_work)+float(receipt.work)
	# Inspection belongs to the same reserved workpiece and will consume the
	# remaining recipe work. No accepted output is minted at path completion.
	job.progress_days=float(pending.run.work)
	if Program.complete(pending.run):pending.phase="inspection"
static func clear(job:Dictionary)->void:
	# Changing production abandons the reserved workpiece; no free refund.
	job.erase("machine_pending")
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if not spec.has("machine_program"):
		return "Unexpected machine workpiece." if job.has("machine_pending") else ""
	if not job.has("machine_pending"):
		return "Missing machine workpiece." if float(job.get("progress_days",0))>0 else ""
	var pending:Variant=job.machine_pending
	if not pending is Dictionary or not pending.has_all(["recipe","source_job","ordinal","site","reserved","run","phase"]):return "Invalid machine workpiece."
	if pending.recipe!=job.item or pending.source_job!=job.id or pending.ordinal!=int(job.completed)+1 or pending.reserved!=spec.materials:return "Mismatched machine material provenance."
	if not pending.site is String or pending.site.length()>128 or pending.phase not in ["machining","inspection"]:return "Invalid machine stage."
	if not Program.valid(pending.run) or pending.run.program!=spec.machine_program:return "Invalid retained machine program."
	if Program.complete(pending.run)!=(pending.phase=="inspection") or absf(float(job.progress_days)-float(pending.run.work))>.000001:return "Inconsistent machine progress."
	return ""
