extends RefCounted
## Bounded manufacturing-variation model, not a physical sensor simulation.
## Candidate identity is recorded at manufacture, never seeded by inspection.
const I=preload("res://scripts/civilian_industry.gd")
const LIMIT=256
const MAX=1000000000
static func data()->Dictionary:
	var owner:Dictionary=WorldSimulation.state.technology_operations
	if not owner.has("abrasive_lots"):owner.abrasive_lots={"next_id":1,"records":{}}
	return owner.abrasive_lots
static func capacity()->bool:
	var d:=data()
	for key:Variant in d.records.keys():
		if int(d.records[key].remaining)==0:d.records.erase(key)
	return d.records.size()<LIMIT and int(d.next_id)<MAX
static func record(job:Dictionary,count:int)->void:
	var spec:=I.product(String(job.item))
	if count<=0 or not spec.has("abrasive_candidate"):return
	assert(capacity())
	var d:=data();var id:=int(d.next_id);d.next_id=id+1
	d.records[str(id)]={"id":id,"recipe":String(job.item),"source_job":int(job.id),"first_ordinal":int(job.completed)-count+1,"count":count,"remaining":count,"source_store":WorldSimulation.state.resource_settlement_id}
static func selected(spec:Dictionary)->Dictionary:
	var keys:Array=data().records.keys();keys.sort_custom(func(a:String,b:String)->bool:return int(a)<int(b))
	for key:String in keys:
		var r:Dictionary=data().records[key]
		if int(r.remaining)>0 and r.source_store==WorldSimulation.state.resource_settlement_id and I.product(r.recipe).output==spec.abrasive_inspection:return r
	return {}
static func available(spec:Dictionary)->float:
	var total:=0.0
	for r:Dictionary in data().records.values():
		if r.source_store==WorldSimulation.state.resource_settlement_id and I.product(r.recipe).output==spec.get("abrasive_inspection",""):total+=float(r.remaining)
	return minf(total,float(WorldSimulation.state.resource_stockpiles.get(spec.get("abrasive_inspection",""),0)))
static func readings(source_job:int,ordinal:int)->Dictionary:
	# Selected near-net plain steel forms / wheel / dry-belt qualification only.
	# Fixed original identity prevents cancellation and save/load from rerolling.
	var phase:=(source_job%19*13+ordinal%19*7)%19
	return {"model":"bounded_manufacturing_v1","size_ratio":1.2 if phase==0 else .35+float(phase%4)*.1,"form_ratio":1.25 if phase==1 else .3+float(phase%5)*.1,"surface_ratio":1.3 if phase==2 else .25+float(phase%6)*.1}
static func accepted(report:Dictionary)->bool:
	return float(report.size_ratio)<=1 and float(report.form_ratio)<=1 and float(report.surface_ratio)<=1
static func pending_valid(p:Variant,spec:Dictionary)->bool:
	if not p is Dictionary or not p.has_all(["source_job","ordinal","lot_id","source_store","report"]):return false
	for key:String in ["source_job","ordinal","lot_id"]:
		if not integer(p[key],1,MAX):return false
	return p.source_store is String and p.source_store.length()<=128 and p.report is Dictionary and p.report==readings(int(p.source_job),int(p.ordinal)) and spec.has("abrasive_inspection")
static func advance(job:Dictionary,work:float)->void:
	var spec:=I.product(String(job.item));var state=WorldSimulation.state
	var ops=preload("res://scripts/technology_operations.gd")
	var budget:=work
	for iteration:int in range(64):
		if budget<=0:return
		if not job.has("abrasive_pending"):
			if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
			var lot:=selected(spec)
			if lot.is_empty():return
			for r:String in spec.materials:
				if float(state.resource_stockpiles.get(r,0))<float(spec.materials[r]):return
			# Reserve one actual candidate and its inspection consumables once.
			var ordinal:=int(lot.first_ordinal)+int(lot.count)-int(lot.remaining)
			job.abrasive_pending={"source_job":int(lot.source_job),"ordinal":ordinal,"lot_id":int(lot.id),"source_store":lot.source_store,"report":readings(int(lot.source_job),ordinal)}
			lot.remaining=int(lot.remaining)-1
			for r:String in spec.materials:
				state.resource_stockpiles[r]=float(state.resource_stockpiles.get(r,0))-float(spec.materials[r])
				job.last_consumed[r]=float(job.last_consumed.get(r,0))+float(spec.materials[r])
		if job.abrasive_pending.source_store!=state.resource_settlement_id:return
		var used:=minf(budget,float(spec.days)-float(job.progress_days))
		var power:=float(spec.get("power",0))/float(spec.days)
		if power>0:used=minf(used,ops.service("electricity")/power)
		if used<=0:return
		if power>0:ops.consume_electricity(used*power)
		job.progress_days=float(job.progress_days)+used;job.last_work=float(job.last_work)+used;budget-=used
		if float(job.progress_days)+.000000001<float(spec.days):return
		var pass_check:=accepted(job.abrasive_pending.report)
		var output:String=String(spec.output if pass_check else spec.abrasive_reject)
		state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1
		job.abrasive_last=job.abrasive_pending.duplicate(true)
		job.abrasive_last["accepted"]=pass_check
		job.abrasive_last["inspection_recipe"]=String(job.item)
		job.completed=int(job.completed)+1;job.progress_days=0.0
		job.last_output=int(job.last_output)+(1 if pass_check else 0)
		job["abrasive_rejected"]=int(job.get("abrasive_rejected",0))+(0 if pass_check else 1)
		job.erase("abrasive_pending")
static func clear(job:Dictionary)->void:
	for key:String in ["abrasive_pending","abrasive_last","abrasive_rejected"]:job.erase(key)
static func validate_job(job:Dictionary)->String:
	var spec:=I.product(String(job.get("item","")))
	if not spec.has("abrasive_inspection"):
		for key:String in ["abrasive_pending","abrasive_last","abrasive_rejected"]:
			if job.has(key):return "Unexpected abrasive inspection state."
		return ""
	if job.has("abrasive_pending") and not pending_valid(job.abrasive_pending,spec):return "Invalid abrasive workpiece."
	if float(job.get("progress_days",0))>0 and not job.has("abrasive_pending"):return "Missing reserved abrasive workpiece."
	if not integer(job.get("abrasive_rejected",0),0,int(job.get("completed",0))):return "Invalid abrasive rejection count."
	if job.has("abrasive_last"):
		var last:Variant=job.abrasive_last
		if not pending_valid(last,spec) or last.get("inspection_recipe")!=job.item:return "Invalid abrasive report."
		if not last.get("accepted") is bool or last.accepted!=accepted(last.report):return "Invalid abrasive acceptance."
	return ""
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["next_id","records"]):return false
	if not integer(value.next_id,1,MAX) or not value.records is Dictionary or value.records.size()>LIMIT:return false
	for key:Variant in value.records:
		var r:Variant=value.records[key]
		if not key is String or not r is Dictionary or not r.has_all(["id","recipe","source_job","first_ordinal","count","remaining","source_store"]):return false
		if not integer(r.id,1,int(value.next_id)-1) or key!=str(int(r.id)):return false
		if not r.recipe is String or not I.product(r.recipe).has("abrasive_candidate"):return false
		if not integer(r.source_job,1,MAX) or not integer(r.first_ordinal,1,MAX):return false
		if not integer(r.count,1,MAX-int(r.first_ordinal)+1) or not integer(r.remaining,0,int(r.count)):return false
		if not r.source_store is String or r.source_store.length()>128:return false
	return true
static func integer(v:Variant,low:int,high:int)->bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)==floorf(float(v)) and float(v)>=low and float(v)<=high
