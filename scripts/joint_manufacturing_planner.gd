extends RefCounted
## Build known ship/aircraft inputs through ordinary, finite workshop orders.
## This planner neither acquires unknown methods nor commissions free equipment.
const P=preload("res://scripts/persistent_production.gd")
const J=preload("res://scripts/joint_force_catalog.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func plan(host:Node,item:String)->Dictionary:
	var unit:=J.by_equipment(item)
	if unit.is_empty():return {}
	if int(host.military_inventory.get(item,0))>0:return {"ready":true}
	var definition:=P.recipe(host,item)
	if definition.has("error") or not host.joint_operations.available_base(String(unit.domain)):return {}
	var staff:=P.workforce()
	if host.production_labor_share<=0 or float(staff.workers)<=0 or float(staff.condition_factor)<=0:return {}
	var existing:Dictionary={}
	for job:Dictionary in host.equipment_queue:
		if String(job.get("item",""))!=item:continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):return {}
		existing=job;break
	# Retained lines preserve their paid historical recipe and fractional work.
	var fraction:=1.0 if existing.is_empty() else maxf(0,1.0-float(existing.progress_days)/float(existing.work_per_item))
	var materials:Dictionary=definition.materials if existing.is_empty() else existing.materials
	var needed:Dictionary={}
	for resource:String in materials:needed[resource]=float(materials[resource])*fraction
	if existing.is_empty():
		for resource:String in definition.tooling:needed[resource]=float(needed.get(resource,0))+float(definition.tooling[resource])
	var first:Dictionary={}
	for resource:String in needed:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))+.000001>=float(needed[resource]):continue
		var upstream:=Supply.supply(resource,ceili(float(needed[resource])),{})
		# A missing raw supply, unknown process or paused upstream line blocks
		# this candidate; do not spend on a knowingly unusable partial chain.
		if upstream.is_empty():return {}
		if first.is_empty():first=upstream
	return {"ready":true} if first.is_empty() else {"ready":false,"upstream":first}
