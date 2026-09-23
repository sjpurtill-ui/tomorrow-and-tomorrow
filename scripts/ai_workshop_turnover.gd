extends RefCounted
## Managed workshops finish or set aside paid ordinary batches of military items.
const P=preload("res://scripts/persistent_production.gd")

static func authorized(id:String,host:Node,delegated:bool)->bool:
	if delegated:return id=="player" and WorldSimulation.actor_id=="player" and host==WorldSimulation.military and bool(host.workshop.data.enabled)
	return String(WorldSimulation.actors.get(id,{}).get("controller",""))=="ai"

static func ordinary(job:Dictionary)->bool:
	# Former civilian lines are retired on the production day, not retooled.
	if String(job.get("job_type",""))=="civilian" or not job.get("reserved_materials",{}).is_empty():return false
	for key:String in job:
		if key.ends_with("pending") or key.ends_with("trial") or key=="formed_piece":return false
	return true

static func can_suspend(host:Node,job:Dictionary)->bool:
	return ordinary(job) and float(job.get("progress_days",0))>0 and P.state(host,job).begins_with("Missing ") and job.get("suspended_batches",{}).size()<32

static func request(id:String,host:Node,item:String,target:int,delegated:bool=false)->bool:
	if not authorized(id,host,delegated):return false
	for job:Dictionary in host.equipment_queue:
		if job.has("ai_turnover"):return false
	var selected:Dictionary={}
	for job:Dictionary in host.equipment_queue:
		if delegated and not bool(job.get("planner_managed",false)):continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)) or String(job.item)==item:continue
		if int(job.get("completed",0))<1 and not can_suspend(host,job):continue
		if not ordinary(job) or not P.startup_blockers(host,item,P.installed_tooling(job)).is_empty():continue
		if selected.is_empty() or int(job.completed)>int(selected.completed):selected=job
	if selected.is_empty():return false
	selected.ai_turnover={"item":item,"target":clampi(target,1,P.MAX_TARGET)}
	if float(selected.progress_days)<=0.0:selected.paused=true
	return true

static func advance(id:String,host:Node,delegated:bool=false)->void:
	if not authorized(id,host,delegated):return
	for job:Dictionary in host.equipment_queue:
		if delegated and not bool(job.get("planner_managed",false)):continue
		if not job.has("ai_turnover"):continue
		var suspending:=float(job.progress_days)>0
		if suspending and not can_suspend(host,job):continue
		if not suspending and not bool(job.get("paused",false)):continue
		var next:Dictionary=job.ai_turnover.duplicate()
		if not P.startup_blockers(host,String(next.item),P.installed_tooling(job)).is_empty():
			job.erase("ai_turnover");job.paused=false
			continue
		var suspended_item:=""
		if suspending:
			suspended_item=String(job.item)
			if not job.has("suspended_batches"):job.suspended_batches={}
			if job.suspended_batches.has(suspended_item):continue
			job.suspended_batches[suspended_item]={"persistent":true,"item":job.item,"job_type":job.job_type,"materials":job.materials.duplicate(true),"work_per_item":job.work_per_item,"progress_days":job.progress_days,"target_stock":1,"allocation":1.0,"efficiency":.20,"completed":0}
		var result:=WorldSimulation.submit(id,{"kind":"production_retool","job":int(job.id),"item":String(next.item)})
		job.erase("ai_turnover")
		if result.has("error"):
			if not suspended_item.is_empty():job.suspended_batches.erase(suspended_item)
			job.paused=false
			continue
		WorldSimulation.submit(id,{"kind":"production_target","job":int(job.id),"target":int(next.target),"paused":false})
		job.planner_managed=true
