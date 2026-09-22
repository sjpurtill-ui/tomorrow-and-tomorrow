extends RefCounted
## Routine maintenance is staff work, independent of manual production orders.
const P=preload("res://scripts/persistent_production.gd")
const Knowledge=preload("res://scripts/field_repair.gd")
static func prepare(host:Node)->void:
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling or host.recovery.home_unavailable():return
	# One batch at a time; never reserve the same damaged items twice.
	for job:Dictionary in host.equipment_queue:
		if String(job.get("job_type",""))=="repair" or job.has("repair_pending"):return
	for item:String in host.damaged_equipment:
		if int(host.damaged_equipment[item])<=0 or not Knowledge.understood(host,item):continue
		# An active managed weapon line already pays for repairs before manufacture.
		var handled:=false
		for job:Dictionary in host.equipment_queue:
			if String(job.get("item",""))==item and bool(job.get("planner_managed",false)) and bool(host.workshop.data.enabled) and P.eligible(host,job):handled=true
		if handled:continue
		var affordable:=true
		var recipe:Dictionary=host._equipment_recipe(item)
		for resource:String in recipe.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(resource,0))<float(recipe.materials[resource])*.18:affordable=false
		if not affordable:continue
		if host.equipment_queue.size()>=host.production_line_capacity():
			for job:Dictionary in host.equipment_queue:
				if not bool(job.get("planner_managed",false)) or not bool(job.get("persistent",false)):continue
				if not bool(job.get("staff_idle",false)) and P.state(host,job)!="Target met":continue
				if float(job.get("progress_days",0))>0 or not (job.get("reserved_materials",{}) as Dictionary).is_empty():continue
				var pending:=false
				for key:String in job:
					if key.ends_with("pending") or key.ends_with("trial") or key=="formed_piece":pending=true
				if pending:continue
				host.cancel_equipment_job(int(job.id));break
		for count:int in range(mini(10,int(host.damaged_equipment[item])),0,-1):
			if host.equipment_repair_quote(item,count).has("error"):continue
			host.queue_equipment_repair(item,count);return
static func status(host:Node,item:String)->String:
	for job:Dictionary in host.equipment_queue:
		if String(job.get("item",""))==item and (String(job.get("job_type",""))=="repair" or job.has("repair_pending")):return "Staff repairs underway"
	if not Knowledge.understood(host,item):return "Staff waiting for repair knowledge"
	if host.equipment_queue.size()>=host.production_line_capacity():return "Staff waiting for workshop capacity; repairs remain on the upkeep list"
	var quote:Dictionary=host.equipment_repair_quote(item,1)
	if quote.has("error"):return "Staff waiting · "+String(quote.error)
	return "Staff will schedule repairs automatically"

static func pending(host:Node,item:String)->int:
	var count:=0
	for job:Dictionary in host.equipment_queue:
		if String(job.get("item",""))!=item:continue
		if String(job.get("job_type",""))=="repair":count+=maxi(0,int(job.get("count",0))-int(job.get("completed",0)))
		if job.has("repair_pending"):count+=maxi(0,int(job.repair_pending.count)-int(job.repair_pending.completed))
	return count
