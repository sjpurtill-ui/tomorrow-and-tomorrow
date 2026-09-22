extends RefCounted
## Ordinary managed weapon lines share their paid workshop time with repairs.
const MATERIAL_FACTOR=0.18
const WORK_FACTOR=0.38
static func available(host:Node,job:Dictionary)->bool:
	if job.has("repair_pending"):return true
	if String(job.get("job_type",""))!="production" or not host.EQUIPMENT_KNOWLEDGE.has(String(job.item)):return false
	var ai:=String(WorldSimulation.actors.get(WorldSimulation.actor_id,{}).get("controller",""))=="ai"
	if not ai and not (bool(job.get("planner_managed",false)) and bool(host.workshop.data.enabled)):return false
	if not preload("res://scripts/field_repair.gd").understood(host,String(job.item)):return false
	if int(host.damaged_equipment.get(String(job.item),0))<=0:return false
	for resource:String in job.materials:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))+.000000001<float(job.materials[resource])*MATERIAL_FACTOR:return false
	return true
static func advance(host:Node,job:Dictionary,work:float)->float:
	if work<=0 or bool(job.get("paused",false)) or not available(host,job):return work
	var item:=String(job.item)
	var per_item:=float(job.work_per_item)*WORK_FACTOR
	if not job.has("repair_pending"):
		var count:=mini(int(host.damaged_equipment.get(item,0)),maxi(1,ceili(work/per_item)))
		if int(job.target_stock)>0:count=mini(count,maxi(0,int(job.target_stock)-int(host.military_inventory.get(item,0))))
		for resource:String in job.materials:
			var cost:=float(job.materials[resource])*MATERIAL_FACTOR
			if cost>0:count=mini(count,floori((float(WorldSimulation.state.resource_stockpiles.get(resource,0))+.000000001)/cost))
		if count<=0:return work
		for resource:String in job.materials:
			WorldSimulation.state.resource_stockpiles[resource]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(job.materials[resource])*MATERIAL_FACTOR*count)
		host.damaged_equipment[item]-=count
		job.repair_pending={"count":count,"completed":0,"progress":0.0}
	var pending:Dictionary=job.repair_pending
	var used:=minf(work,float(pending.count)*per_item-float(pending.progress))
	pending.progress=float(pending.progress)+used
	var completed:=mini(int(pending.count),floori((float(pending.progress)+.000000001)/per_item))
	var repaired:=completed-int(pending.completed)
	var before:Dictionary=host.workshop.output_stocks(job)
	host.military_inventory[item]=int(host.military_inventory.get(item,0))+repaired
	pending.completed=completed
	var receipt:=job.duplicate();receipt.job_type="repair"
	host.workshop.record(receipt,before)
	job.repaired=int(job.get("repaired",0))+repaired
	if completed==int(pending.count):job.erase("repair_pending")
	return maxf(0,work-used)
static func clear(host:Node,job:Dictionary)->void:
	if not job.has("repair_pending"):return
	var pending:Dictionary=job.repair_pending
	var item:=String(job.item)
	host.damaged_equipment[item]=int(host.damaged_equipment.get(item,0))+int(pending.count)-int(pending.completed)
	job.erase("repair_pending")

