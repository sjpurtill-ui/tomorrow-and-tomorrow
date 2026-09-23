extends RefCounted
## Persistent workshop lines share the existing Crafting pool with household work.
## This adapter owns no citizens, stockpiles, clock, or separate save authority.
## Only military equipment, consumables, carts and ships/aircraft are made on
## lines; civilian manufactures are Civilian Goods made by Crafting households.
const Industry=preload("res://scripts/civilian_industry.gd")
const Bills=preload("res://scripts/goods_bills.gd")
const MAX_TARGET := 1000000000
const CIVILIAN_ERROR:="Made as Civilian Goods by Crafting households; workshops no longer make it on a line."

static func recipe(host: Node, item: String) -> Dictionary:
	var gate: Dictionary
	var definition: Dictionary
	var kind := "production"
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty():
		gate=host._knowledge_gate(String(joint.gate),.10);definition={"materials":Bills.flatten(joint.materials),"days":float(joint.work_days),"tooling":Bills.flatten(joint.get("tooling",{}))}
	elif item=="transport_cart":
		gate=host._knowledge_gate("joinery",.10);definition=host._transport_recipe();kind="transport"
	elif host.CONSUMABLE_KNOWLEDGE.has(item):
		gate=host.consumable_knowledge_availability(item);definition=host._consumable_recipe(item);kind="consumable"
	elif host.simulator.WEAPONS.has(item):
		gate=host._knowledge_gate(String(host.EQUIPMENT_KNOWLEDGE.get(item,"")),.08);definition=host._equipment_recipe(item)
	elif not Industry.product(item).is_empty():return {"error":CIVILIAN_ERROR}
	else: return {"error":"Unknown production item: %s" % item}
	if not bool(gate.get("unlocked",false)): return {"error":String(gate.get("reason","Adopt the required production practice first."))}
	return {"item":item,"job_type":kind,"materials":definition.materials.duplicate(true),"work_per_item":float(definition.days),"tooling":definition.get("tooling",{}).duplicate(true)}

static func product_name(item:String)->String:
	# Old receipts may still name a former civilian product.
	if not Industry.product(item).is_empty():return String(Industry.product(item).name)
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty():return String(joint.label)
	return {"improvised":"Simple levy weapons","spear":"Spears","bow":"Bows","sword_shield":"Sword & shield sets","siege_kit":"Siege engineer kits"}.get(item,item.replace("_"," ").capitalize())

static func product_description(item:String)->String:
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty():return "%s equipment. %d crew per hull or aircraft; commission through %s operations." % [String(joint.purpose),int(joint.crew),String(joint.domain)]
	if item=="improvised":return "Basic wooden clubs and makeshift hand weapons for levies. One set equips one levy; this produces equipment, not a trained unit."
	if not Industry.product(item).is_empty():return CIVILIAN_ERROR
	var users:Array[String]=[]
	for unit:Dictionary in preload("res://scripts/military_unit_catalog.gd").ARCHETYPES.values():
		if item in unit.equipment:users.append(String(unit.label))
	return "Equipment for "+", ".join(users)+". Train and deploy those units through Prepare an Army." if not users.is_empty() else "Ammunition or transport supply used by your forces."

static func available_products(host:Node)->Array[String]:
	var result:Array[String]=[]
	for item:String in host.EQUIPMENT_KNOWLEDGE.keys()+host.CONSUMABLE_KNOWLEDGE.keys()+["transport_cart"]:
		if not recipe(host,item).has("error"):result.append(item)
	return result

static func installed_tooling(job:Dictionary)->Dictionary:
	if job.has("installed_tooling"):return (job.installed_tooling as Dictionary).duplicate(true)
	# Older lines can prove only their current paid setup, not past discarded tools.
	return (job.get("tooling",{}) as Dictionary).duplicate(true) if bool(job.get("tooling_paid",false)) else {}

static func missing_tooling(required:Dictionary,installed:Dictionary)->Dictionary:
	var result:Dictionary={}
	for resource:String in required:
		var missing:=maxf(0,float(required[resource])-float(installed.get(resource,0)))
		if missing>0:result[resource]=missing
	return result

static func startup_blockers(host:Node,item:String,installed:Dictionary={})->Array[String]:
	var result:Array[String]=[]
	var definition:=recipe(host,item)
	if definition.has("error"):return [String(definition.error)]
	var tooling:=missing_tooling(definition.tooling,installed)
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty() and not host.joint_operations.available_base(String(joint.domain)):result.append("Build an operational naval base or airfield for this production branch first.")
	var staff:=workforce()
	if host.production_labor_share<=0:result.append("No crafting labor assigned to workshop production. Increase the workshop crafting share.")
	if float(staff.workers)<=0:result.append("No available craftspeople. Assign crafting work in your cities.")
	elif float(staff.condition_factor)<=0:result.append("Workforce or workplaces cannot operate. Restore health and usable workshops.")
	for resource:String in definition.materials:
		var needed:=float(definition.materials[resource])+float(tooling.get(resource,0));var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		if stored<needed:result.append("%s: %.2f in stores; %.2f needed for one item." % [WorldSimulation.resources.display_name(resource),stored,needed])
	for resource:String in tooling:
		if definition.materials.has(resource):continue
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))<float(tooling[resource]):result.append("Line setup needs %.1f %s." % [float(tooling[resource]),resource])
	return result

static func start(host: Node, item: String, target: int) -> Dictionary:
	if target<0 or target>MAX_TARGET: return {"error":"Choose a stockpile target from 0 to 1 billion; 0 means continuous production."}
	var gate: Dictionary=host._production_line_gate()
	if gate.has("error"): return gate
	var definition:=recipe(host,item)
	if definition.has("error"): return definition
	var blockers:=startup_blockers(host,item)
	if not blockers.is_empty():return {"error":"Cannot start production: "+" ".join(blockers)}
	for resource:String in definition.get("tooling",{}):WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(definition.tooling[resource])
	var id: int=host.next_equipment_job_id;host.next_equipment_job_id+=1
	var job:=definition.duplicate(true)
	job.merge({"id":id,"persistent":true,"target_stock":target,"paused":false,"allocation":1.0,"efficiency":.20,"progress_days":0.0,"completed":0,"count":1,"required_days":float(definition.work_per_item),"reserved_materials":{},"last_output":0,"last_consumed":{},"last_work":0.0,"tooling_paid":true,"installed_tooling":definition.tooling.duplicate(true)})
	host.equipment_queue.append(job)
	return {"ok":true,"job_id":id,"message":product_name(item)+(" — continuous production: no limit; runs until paused or supplies run out." if target==0 else " — maintain %d in stores; pauses at target and replenishes after issue." % target)}

static func configure(host: Node, id: int, target: int, paused: bool) -> Dictionary:
	if target<0 or target>MAX_TARGET: return {"error":"Invalid stockpile target."}
	for job in host.equipment_queue:
		if int(job.id)==id and bool(job.get("persistent",false)):
			job.target_stock=target;job.paused=paused
			job.erase("planner_managed")
			job.erase("staff_idle")
			job.erase("ai_turnover")
			return {"ok":true,"message":"Production line updated."}
	return {"error":"Select a persistent production line."}

static func retool(host: Node, id: int, item: String) -> Dictionary:
	var definition:=recipe(host,item)
	if definition.has("error"): return definition
	for job in host.equipment_queue:
		if int(job.id)!=id or not bool(job.get("persistent",false)): continue
		if String(job.item)==item: return {"ok":true,"message":"This line already makes that item."}
		var installed:=installed_tooling(job)
		var additions:=missing_tooling(definition.tooling,installed)
		if not definition.tooling.is_empty():
			var blockers:=startup_blockers(host,item,installed)
			if not blockers.is_empty():return {"error":"Cannot retool: "+" ".join(blockers)}
			for resource:String in additions:
				WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(additions[resource])
				installed[resource]=float(installed.get(resource,0))+float(additions[resource])
		job["installed_tooling"]=installed
		var retention:=.65 if String(job.job_type)==String(definition.job_type) else .35
		job.efficiency=maxf(.10,float(job.efficiency)*retention)
		preload("res://scripts/managed_weapon_repair.gd").clear(host,job)
		job.merge(definition,true);job.progress_days=0.0;job.completed=0;job.last_output=0;job.last_work=0.0;job.last_consumed={}
		var suspended:Dictionary=job.get("suspended_batches",{})
		if suspended.has(item):
			var batch:Dictionary=suspended[item]
			# Previously paid work belongs to this exact recipe and is restored once.
			if batch.materials==definition.materials and float(batch.work_per_item)==float(definition.work_per_item):
				job.progress_days=float(batch.progress_days)
				suspended.erase(item)
		job.required_days=job.work_per_item
		job.erase("planner_managed")
		job.erase("staff_idle")
		job.erase("ai_turnover")
		return {"ok":true,"message":"Line retooled. Existing setup tools remain assigned; missing tools are added. Some efficiency is retained; unfinished work is discarded without refunding consumed materials."}
	return {"error":"Select a persistent production line."}

static func stock(host: Node, job: Dictionary) -> int:
	if String(job.job_type)=="consumable": return int(host.military_consumables.get(String(job.item),0))
	if String(job.job_type)=="transport": return int(WorldSimulation.state.resource_stockpiles.get("Transport Carts",0))
	return int(host.military_inventory.get(String(job.item),0))

static func state(host: Node, job: Dictionary) -> String:
	if bool(job.get("paused",false)): return "Paused"
	if not bool(job.get("persistent",false)): return "Batch"
	var gate:=recipe(host,String(job.item))
	if gate.has("error"):return "Research unavailable: "+String(gate.error)
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(String(job.item))
	if not joint.is_empty() and not host.joint_operations.available_base(String(joint.domain)):return "No operational "+("naval base" if joint.domain=="navy" else "airfield")
	if int(job.target_stock)>0 and stock(host,job)>=int(job.target_stock): return "Target met"
	if preload("res://scripts/managed_weapon_repair.gd").available(host,job):return "Repairing equipment"
	for resource in job.materials:
		if float(job.materials[resource])>0 and float(WorldSimulation.state.resource_stockpiles.get(resource,0))<=.000000001: return "Missing "+WorldSimulation.resources.display_name(String(resource))
	return "Working"

static func eligible(host: Node, job: Dictionary) -> bool:
	return state(host,job) in ["Working","Batch","Repairing equipment"]

static func workforce() -> Dictionary:
	var workers:=WorldSimulation.state.effective_workers("Crafting")
	var health:=clampf(WorldSimulation.state.population_health,0.0,1.0)
	var labor:=clampf(float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72)),0.0,1.45)
	var carrying:=WorldSimulation.state.effective_workers("Logistics")
	var logistics:=clampf(.35+carrying/maxf(1.0,workers*.3)*.65,.35,1.0)
	# Mobile crafts are possible with carried tools; founded workplace damage
	# reduces the city's built workplace capacity rather than a decorative score.
	var facilities:=float(WorldSimulation.settlements.city_capacities().get("workplace_condition",.5))
	var powered_factor:=1.0+minf(.5,preload("res://scripts/technology_operations.gd").service("mechanical_work")/maxf(1.0,workers))
	return {"powered_factor":powered_factor,"workers":workers,"health":health,"labor_efficiency":labor,"logistics":logistics,"workplace_condition":facilities,"condition_factor":health*labor*logistics*facilities*powered_factor}

static func advance(host: Node, job: Dictionary, work: float) -> void:
	job.last_output=0;job.last_work=0.0;job.last_consumed={}
	if not eligible(host,job) or work<=0:return
	if preload("res://scripts/research_licenses.gd").uses_license(String(job.item)):work*=.65
	var per_item:=float(job.work_per_item)
	var units:=work/per_item
	if job.has("ai_turnover"):units=minf(units,maxf(0,1.0-float(job.progress_days)/per_item))
	if int(job.target_stock)>0:
		units=minf(units,maxf(0.0,int(job.target_stock)-stock(host,job)-float(job.progress_days)/per_item))
	var possible:=units
	for resource in job.materials:
		var cost:=float(job.materials[resource])
		if cost>0: possible=minf(possible,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0)))/cost)
	possible=maxf(0,possible)
	for resource in job.materials:
		var consumed:=float(job.materials[resource])*possible
		WorldSimulation.state.resource_stockpiles[resource]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0))-consumed)
		job.last_consumed[resource]=consumed
	var progress:=float(job.progress_days)+possible*per_item
	var produced:=maxi(0,floori(progress/per_item+.000000001))
	job.progress_days=maxf(0,progress-produced*per_item)
	job.completed=int(job.completed)+produced;job.last_output=produced;job.last_work=possible*per_item
	if String(job.job_type)=="consumable": host.military_consumables[String(job.item)]=stock(host,job)+produced
	elif String(job.job_type)=="transport": WorldSimulation.state.resource_stockpiles["Transport Carts"]=stock(host,job)+produced
	else: host.military_inventory[String(job.item)]=stock(host,job)+produced
	if produced>0 and job.has("ai_turnover"):
		job.progress_days=0.0
		job.paused=true
	if possible>0: job.efficiency=move_toward(float(job.efficiency),1.0,.0025*(.65+host._adoption("workshop_standards"))*minf(1,possible/maxf(.000001,units)))

static func snapshot(host: Node, job: Dictionary, rate: float, share: float) -> Dictionary:
	var result:=job.duplicate(true)
	result["state"]=state(host,job);result["stock"]=stock(host,job);result["share"]=share
	result["licensed"]=preload("res://scripts/research_licenses.gd").uses_license(String(job.item))
	result["daily_work"]=rate*share*float(job.efficiency)*(.65 if result.licensed else 1.0)
	var repairing:bool=result.state=="Repairing equipment"
	if repairing:
		result.work_per_item=float(job.work_per_item)*preload("res://scripts/managed_weapon_repair.gd").WORK_FACTOR
		result.required_days=result.work_per_item
		var pending:Dictionary=job.get("repair_pending",{})
		result.progress_days=maxf(0,float(pending.get("progress",0))-int(pending.get("completed",0))*float(result.work_per_item))
	if result.state in ["Working","Repairing equipment"] and float(result.daily_work)<=0:
		var staff:=workforce()
		if host.production_labor_share<=0:result.state="No workshop crafting share"
		elif float(staff.workers)<=0:result.state="No available craftspeople"
		elif float(staff.workplace_condition)<=0:result.state="No usable workplaces"
		else:result.state="Workforce unable to work"
	result["output_per_day"]=float(result.daily_work)/float(result.work_per_item)
	result["inputs_per_day"]={}
	for resource in job.materials: result.inputs_per_day[resource]=float(job.materials[resource])*float(result.output_per_day)*(preload("res://scripts/managed_weapon_repair.gd").MATERIAL_FACTOR if repairing else 1.0)
	result["forecast_output_per_day"]=float(result.output_per_day) if result.state in ["Working","Repairing equipment"] else 0.0
	result["materials_status"]=[]
	for resource:String in job.materials:
		var cost:=float(job.materials[resource]);var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		if cost>0:result.forecast_output_per_day=minf(float(result.forecast_output_per_day),stored/cost)
		result.materials_status.append({"resource":resource,"name":WorldSimulation.resources.display_name(resource),"stored":stored,"per_item":cost,"per_day":float(result.inputs_per_day[resource])})
	if int(job.target_stock)>0:result.forecast_output_per_day=minf(float(result.forecast_output_per_day),maxf(0,int(job.target_stock)-int(result.stock)-float(job.progress_days)/float(job.work_per_item)))
	result["electricity_per_item"]=0.0
	return result

static var _allowed_tools:Dictionary={}
## Tool names a saved line may hold: former recipe tools and their flattened
## raw materials and Civilian Goods.
static func _allowed_tool(resource:String)->bool:
	if _allowed_tools.is_empty():
		var bills:Array=[]
		for product:Dictionary in Industry.PRODUCTS.values():bills.append(product.get("tooling",{}))
		for unit:Dictionary in preload("res://scripts/joint_force_catalog.gd").UNITS.values():bills.append(unit.get("tooling",{}))
		for bill:Dictionary in bills:
			for tool:String in bill:_allowed_tools[tool]=true
			for tool:String in Bills.flatten(bill):_allowed_tools[tool]=true
	return _allowed_tools.has(resource)

static func validate_saved(payload: Dictionary) -> String:
	var share: Variant=payload.get("production_labor_share",.35)
	if not (share is float or share is int) or not is_finite(float(share)) or float(share)<0 or float(share)>1: return "Invalid production labor share."
	if not payload.get("equipment_queue",[]) is Array:return "Invalid production queue."
	for job in payload.get("equipment_queue",[]):
		if not job is Dictionary: return "Invalid production line."
		if not bool(job.get("persistent",false)): continue
		# Former civilian lines are retired on the first production day
		# (retire_civilian); their specialised trial records need no checks.
		if String(job.get("job_type",""))=="civilian":continue
		if job.has("planner_managed") and not job.planner_managed is bool:return "Invalid production management flag."
		if job.has("suspended_batches"):
			if not job.suspended_batches is Dictionary or job.suspended_batches.size()>32:return "Invalid suspended workshop batches."
			for item:Variant in job.suspended_batches:
				var batch:Variant=job.suspended_batches[item]
				if not item is String or not batch is Dictionary or batch.has("suspended_batches") or not bool(batch.get("persistent",false)) or batch.get("item")!=item:return "Invalid suspended workshop batch."
				var batch_error:=validate_saved({"equipment_queue":[batch]})
				if not batch_error.is_empty():return batch_error
				if float(batch.progress_days)<=0 or float(batch.progress_days)>=float(batch.work_per_item):return "Invalid suspended workshop progress."
		if job.has("ai_turnover"):
			var next:Variant=job.ai_turnover
			if not next is Dictionary or not next.get("item") is String or String(next.item).is_empty() or String(next.item).length()>100 or not next.get("target") is int or int(next.target)<1 or int(next.target)>MAX_TARGET:return "Invalid planned production change."

		for key in ["target_stock","progress_days","work_per_item","allocation","efficiency","completed"]:
			var value: Variant=job.get(key,null)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return "Invalid persistent production value: "+key
		if float(job.target_stock)>MAX_TARGET or float(job.target_stock)!=floorf(float(job.target_stock)) or float(job.completed)!=floorf(float(job.completed)): return "Invalid production counts."
		if float(job.work_per_item)<=0 or float(job.progress_days)>=float(job.work_per_item)+.000001: return "Invalid production work in progress."
		if float(job.allocation)<.05 or float(job.allocation)>4 or float(job.efficiency)<.10 or float(job.efficiency)>1: return "Invalid production priority or efficiency."
		if String(job.get("job_type","")) not in ["production","consumable","transport"] or String(job.get("item","")).is_empty(): return "Invalid production recipe."
		if not job.get("materials",null) is Dictionary or not job.get("reserved_materials",{}) is Dictionary or not job.get("reserved_materials",{}).is_empty(): return "Invalid production materials."
		if job.has("installed_tooling"):
			if not job.installed_tooling is Dictionary:return "Invalid installed tooling."
			for resource:Variant in job.installed_tooling:
				if not resource is String or not _allowed_tool(resource):return "Unknown installed tool."
				var value:Variant=job.installed_tooling[resource]
				if not (value is int or value is float) or not is_finite(float(value)) or float(value)<=0 or float(value)>MAX_TARGET:return "Invalid installed tooling quantity."
		for value in job.materials.values():
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return "Invalid material cost."
	return ""

## Bills on a saved line or batch as they are now: civilian parts named by
## older recipes become raw materials and Civilian Goods. Touches no stores.
static func flatten_saved(job:Dictionary)->void:
	for key:String in ["materials","reserved_materials"]:
		if job.get(key) is Dictionary and not (job[key] as Dictionary).is_empty():job[key]=Bills.flatten(job[key]).duplicate()
	var suspended:Variant=job.get("suspended_batches")
	if suspended is Dictionary:
		for item:String in (suspended as Dictionary).keys():
			var batch:Dictionary=suspended[item]
			if String(batch.get("job_type",""))=="civilian":suspended.erase(item);continue
			if batch.get("materials") is Dictionary:batch.materials=Bills.flatten(batch.materials).duplicate()

## Drop former civilian lines from `host`'s queue. Inputs already reserved for
## a batch or trial, and those consumed by unfinished ordinary work, return to
## the current stores as raw materials and Civilian Goods. Runs on the
## production day, where the owning actor's stores are the active ones.
static func retire_civilian(host:Node)->void:
	for index in range(host.equipment_queue.size()-1,-1,-1):
		var job:Dictionary=host.equipment_queue[index]
		if String(job.get("job_type",""))!="civilian":continue
		var refund:Dictionary=(job.get("reserved_materials",{}) as Dictionary).duplicate()
		for key:String in job:
			var record:Variant=job[key]
			if (key.ends_with("pending") or key.ends_with("trial")) and record is Dictionary and (record as Dictionary).get("reserved") is Dictionary:
				for resource:String in record.reserved:refund[resource]=float(refund.get(resource,0))+float(record.reserved[resource])
		var per_item:=float(job.get("work_per_item",0))
		if per_item>0 and job.get("materials") is Dictionary:
			var fraction:=clampf(float(job.get("progress_days",0))/per_item,0,1)
			for resource:String in job.materials:refund[resource]=float(refund.get(resource,0))+float(job.materials[resource])*fraction
		var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
		var raw:=Bills.flatten(refund)
		for resource:String in raw:
			if float(raw[resource])>0:stocks[resource]=float(stocks.get(resource,0))+float(raw[resource])
		host.equipment_queue.remove_at(index)

static func close(job:Dictionary)->bool:
	preload("res://scripts/managed_weapon_repair.gd").clear(WorldSimulation.military,job)
	return true
