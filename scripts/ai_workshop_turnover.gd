extends RefCounted
## An AI or explicitly delegated player workshop may yield after a paid ordinary batch, never during a trial.
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ORDINARY_FIELDS=["name","output","gate","materials","days","tooling","co_products","power","daily_power","services"]

static func authorized(id:String,host:Node,delegated:bool)->bool:
	if delegated:return id=="player" and WorldSimulation.actor_id=="player" and host==WorldSimulation.military and bool(host.workshop.data.enabled)
	return String(WorldSimulation.actors.get(id,{}).get("controller",""))=="ai"

static func request(id:String,host:Node,item:String,target:int,delegated:bool=false)->bool:
	if not authorized(id,host,delegated):return false
	for job:Dictionary in host.equipment_queue:
		if job.has("ai_turnover"):return false
	var selected:Dictionary={}
	for job:Dictionary in host.equipment_queue:
		if delegated and not bool(job.get("planner_managed",false)):continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)) or String(job.item)==item:continue
		if int(job.get("completed",0))<1 or not job.get("reserved_materials",{}).is_empty():continue
		var special:=false
		for key:String in job:
			if key.ends_with("pending") or key.ends_with("trial") or key=="formed_piece":special=true
		for key:String in I.product(String(job.item)):
			if key not in ORDINARY_FIELDS:special=true
		if special or not P.startup_blockers(host,item,P.installed_tooling(job)).is_empty():continue
		if selected.is_empty() or int(job.completed)>int(selected.completed):selected=job
	if selected.is_empty():return false
	selected.ai_turnover={"item":item,"target":clampi(target,1,P.MAX_TARGET)}
	if float(selected.progress_days)<=0.0:selected.paused=true
	return true

static func advance(id:String,host:Node,delegated:bool=false)->void:
	if not authorized(id,host,delegated):return
	for job:Dictionary in host.equipment_queue:
		if delegated and not bool(job.get("planner_managed",false)):continue
		if not job.has("ai_turnover") or not bool(job.get("paused",false)) or float(job.progress_days)>0:continue
		var next:Dictionary=job.ai_turnover.duplicate()
		if not P.startup_blockers(host,String(next.item),P.installed_tooling(job)).is_empty():
			job.erase("ai_turnover");job.paused=false
			continue
		var result:=WorldSimulation.submit(id,{"kind":"production_retool","job":int(job.id),"item":String(next.item)})
		job.erase("ai_turnover")
		if result.has("error"):
			job.paused=false
			continue
		WorldSimulation.submit(id,{"kind":"production_target","job":int(job.id),"target":int(next.target),"paused":false})
		job.planner_managed=true
