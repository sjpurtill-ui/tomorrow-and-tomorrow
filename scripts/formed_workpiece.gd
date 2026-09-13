extends RefCounted
## One traceable formed bar retained by its existing production job.
const S=preload("res://scripts/residual_slitting.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const MATERIAL="Traceable Formed Steel Bars"
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0 or not job.get("tooling_paid",false):return
	if job.has("formed_piece") and not job.formed_piece.consumed:return
	var state=WorldSimulation.state
	if int(job.target_stock)>0 and float(state.resource_stockpiles.get(MATERIAL,0))>=int(job.target_stock):return
	if not job.has("forming_pending"):
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
		job.forming_pending={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"work":0.0}
	var p:Dictionary=job.forming_pending
	if p.site!=state.resource_settlement_id:return
	var used:=minf(work,minf(2.0-float(p.work),Ops.service("electricity")))
	Ops.consume_electricity(used);p.work+=used;job.progress_days=p.work;job.last_work=float(job.last_work)+used
	if float(p.work)+.000001<2:return
	p.work=2.0
	p.piece=S.prepared(float(spec.formed_source_curvature));p.consumed=false
	job.formed_piece=p.duplicate(true);job.erase("forming_pending")
	state.resource_stockpiles[MATERIAL]=float(state.resource_stockpiles.get(MATERIAL,0))+1.0
	job.completed+=1;job.progress_days=0.0;job.last_output=1
static func available()->Dictionary:
	if float(WorldSimulation.state.resource_stockpiles.get(MATERIAL,0))<1:return {}
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		var p:Dictionary=job.get("formed_piece",{})
		if not p.is_empty() and not bool(p.consumed) and p.site==WorldSimulation.state.resource_settlement_id:return p
	return {}
static func take()->Dictionary:
	var p:=available()
	if p.is_empty():return {}
	p.consumed=true
	return p.duplicate(true)
static func valid_source(p:Variant)->bool:
	if not p is Dictionary or not p.has_all(["recipe","source_job","ordinal","site","reserved","work","piece","consumed"]):return false
	var spec:Dictionary=load("res://scripts/civilian_industry.gd").product(String(p.recipe))
	return spec.has("formed_source_curvature") and p.source_job is int and p.source_job>0 and p.ordinal is int and p.ordinal>0 and p.site is String and p.site.length()<=128 and p.reserved==spec.materials and p.work==2.0 and p.piece==S.prepared(float(spec.formed_source_curvature)) and p.consumed is bool
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if job.has("formed_piece"):
		if not valid_source(job.formed_piece) or job.formed_piece.source_job!=job.id or job.formed_piece.recipe!=job.item or job.formed_piece.ordinal!=job.completed:return "Invalid formed workpiece."
	if job.has("forming_pending"):
		var p:Variant=job.forming_pending
		if not spec.has("formed_source_curvature") or not p is Dictionary or p.get("source_job")!=job.id or p.get("recipe")!=job.item or p.get("ordinal")!=int(job.completed)+1 or p.get("reserved")!=spec.materials:return "Invalid forming source."
		if not p.get("site") is String or p.site.length()>128:return "Invalid forming store."
		if job.has("formed_piece") and not job.formed_piece.consumed:return "Uncollected formed piece overlaps unfinished forming."
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(p.get("work")) or p.work<0 or p.work>=2 or p.work!=job.progress_days:return "Invalid forming work."
	elif spec.has("formed_source_curvature") and float(job.progress_days)>0:return "Missing forming workpiece."
	return ""
static func can_clear(job:Dictionary)->bool:
	if not job.has("formed_piece") or bool(job.formed_piece.consumed):return true
	var source:String=job.formed_piece.site
	if source==WorldSimulation.state.resource_settlement_id:return true
	var record:Dictionary=WorldSimulation.settlements.settlement_record(source)
	# Primary stores cannot be accessed through a currently active secondary
	# resource scope. Keep ownership intact until cleanup runs at that store.
	return not record.is_empty() and not bool(record.get("primary",false))
static func clear(job:Dictionary)->bool:
	if not can_clear(job):return false
	if job.has("formed_piece") and not bool(job.formed_piece.consumed):
		var source:String=job.formed_piece.site
		var downgrade:=func()->void:
			var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
			var quantity:=minf(1.0,maxf(0,float(stocks.get(MATERIAL,0))))
			stocks[MATERIAL]=float(stocks.get(MATERIAL,0))-quantity
			stocks["Unqualified Formed Steel"]=float(stocks.get("Unqualified Formed Steel",0))+quantity
		if source==WorldSimulation.state.resource_settlement_id:downgrade.call()
		else:WorldSimulation.settlements.with_city_resources(source,downgrade)
	job.erase("formed_piece");job.erase("forming_pending")
	return true

static func source_key(p:Dictionary)->String:
	return var_to_str([p.site,p.source_job,p.ordinal])
static func validate_links(jobs:Array)->String:
	var owners:Dictionary={};var claims:Dictionary={}
	for job:Dictionary in jobs:
		if job.has("formed_piece"):
			if not bool(job.get("persistent",false)) or not valid_source(job.formed_piece):return "Invalid formed source owner."
			var key:=source_key(job.formed_piece)
			if owners.has(key):return "Duplicate formed source owner."
			owners[key]=job.formed_piece
	for job:Dictionary in jobs:
		for field:String in ["slitting_pending","slitting_last","fracture_pending","fracture_last"]:
			var trial:Variant=job.get(field,{})
			if not trial is Dictionary:return "Invalid material trial."
			if not trial.has("external_source"):continue
			var source:Variant=trial.external_source
			if not bool(job.get("persistent",false)) or not valid_source(source) or not source.consumed:return "Invalid consumed material source."
			var key:=source_key(source)
			if claims.has(key):return "A formed workpiece was consumed by multiple trials."
			claims[key]=true
			if owners.has(key) and owners[key]!=source:return "Source owner and consuming trial disagree."
	return ""
