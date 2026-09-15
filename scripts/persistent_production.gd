extends RefCounted
## Persistent workshop lines share the existing Crafting pool with civilian work.
## This adapter owns no citizens, stockpiles, clock, or separate save authority.
const Industry=preload("res://scripts/civilian_industry.gd")
const Machine=preload("res://scripts/machine_workshop.gd")
const Formed=preload("res://scripts/formed_workpiece.gd")
const Vacuum=preload("res://scripts/vacuum_workshop.gd")
const Pattern=preload("res://scripts/pattern_workshop.gd")
const Weld=preload("res://scripts/weld_workshop.gd")
const Fracture=preload("res://scripts/fracture_workshop.gd")
const Slitting=preload("res://scripts/slitting_workshop.gd")
const Induction=preload("res://scripts/induction_workshop.gd")
const Metallurgy=preload("res://scripts/metallurgy_workshop.gd")
const AlloyTrials=preload("res://scripts/alloy_phase_trials.gd")
const Casting=preload("res://scripts/casting_workshop.gd")
const Abrasive=preload("res://scripts/abrasive_inspection.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const Exposure=preload("res://scripts/exposure_production.gd")
const MAX_TARGET := 1000000000

static func recipe(host: Node, item: String) -> Dictionary:
	var gate: Dictionary
	var definition: Dictionary
	var kind := "production"
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not Industry.product(item).is_empty():
		definition=Industry.product(item);gate=host._knowledge_gate(String(definition.gate),.10);kind="civilian"
		if not gate.get("unlocked",false) and preload("res://scripts/research_licenses.gd").active(String(definition.gate)):gate={"unlocked":true}
	elif not joint.is_empty():
		gate=host._knowledge_gate(String(joint.gate),.10);definition={"materials":joint.materials,"days":float(joint.work_days),"tooling":joint.get("tooling",{})}
	elif item=="transport_cart":
		gate=host._knowledge_gate("joinery",.10);definition=host._transport_recipe();kind="transport"
	elif host.CONSUMABLE_KNOWLEDGE.has(item):
		gate=host.consumable_knowledge_availability(item);definition=host._consumable_recipe(item);kind="consumable"
	elif host.simulator.WEAPONS.has(item):
		gate=host._knowledge_gate(String(host.EQUIPMENT_KNOWLEDGE.get(item,"")),.08);definition=host._equipment_recipe(item)
	else: return {"error":"Unknown production item: %s" % item}
	if not bool(gate.get("unlocked",false)): return {"error":String(gate.get("reason","Adopt the required production practice first."))}
	return {"item":item,"job_type":kind,"materials":definition.materials.duplicate(true),"work_per_item":float(definition.days),"tooling":definition.get("tooling",{}).duplicate(true)}

static func services_per_item(job:Dictionary)->Dictionary:
	return Industry.product(String(job.get("item",""))).get("services",{}) if String(job.get("job_type",""))=="civilian" else {}

static func power_per_item(job:Dictionary)->float:
	return float(Industry.product(String(job.get("item",""))).get("power",0)) if String(job.get("job_type",""))=="civilian" else 0.0

static func product_name(item:String)->String:
	if not Industry.product(item).is_empty():return String(Industry.product(item).name)
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty():return String(joint.label)
	return {"improvised":"Simple levy weapons","spear":"Spears","bow":"Bows","sword_shield":"Sword & shield sets","siege_kit":"Siege engineer kits"}.get(item,item.replace("_"," ").capitalize())

static func product_description(item:String)->String:
	if not Industry.product(item).is_empty():
		var definition:=Industry.product(item);var parts:Array[String]=[]
		for resource:String in definition.tooling:parts.append("%.1f %s" % [float(definition.tooling[resource]),resource])
		var power_note:=" Each batch also consumes %.1f electricity from the shared daily supply." % float(definition.power) if float(definition.get("power",0))>0 else ""
		for name:String in definition.get("services",{}):power_note+=" Each batch consumes %.1f %s from the shared daily supply." % [float(definition.services[name]),name.replace("_"," ")]
		var joint_outputs:Array[String]=[]
		for resource:String in definition.get("co_products",{}):joint_outputs.append("%.2f %s" % [float(definition.co_products[resource]),resource])
		var co_note:=" Each completed batch also yields "+", ".join(joint_outputs)+"; the stock target tracks "+String(definition.output)+"." if not joint_outputs.is_empty() else ""
		if definition.has("exposure_days"):power_note+=" Reserves one full specimen batch; requires %.0f observed exposure days with operators and power. Extra same-day labor cannot shorten exposure." % float(definition.exposure_days)
		return ("Produces %s in the settlement stock ledger. Line setup consumes %s; batch inputs and workshop time are consumed during production. Machinery must be deployed separately to provide a service." % [definition.output,", ".join(parts)])+power_note+co_note
	var joint:=preload("res://scripts/joint_force_catalog.gd").by_equipment(item)
	if not joint.is_empty():return "%s equipment. %d crew per hull or aircraft; commission through %s operations." % [String(joint.purpose),int(joint.crew),String(joint.domain)]
	if item=="improvised":return "Basic wooden clubs and makeshift hand weapons for levies. One set equips one levy; this produces equipment, not a trained unit."
	var users:Array[String]=[]
	for unit:Dictionary in preload("res://scripts/military_unit_catalog.gd").ARCHETYPES.values():
		if item in unit.equipment:users.append(String(unit.label))
	return "Equipment for "+", ".join(users)+". Train and deploy those units through Prepare an Army." if not users.is_empty() else "Ammunition or transport supply used by your forces."

static func available_products(host:Node)->Array[String]:
	var result:Array[String]=[]
	for item:String in host.EQUIPMENT_KNOWLEDGE.keys()+host.CONSUMABLE_KNOWLEDGE.keys()+["transport_cart"]+Industry.PRODUCTS.keys():
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
	var spec:=Industry.product(item)
	if spec.has("abrasive_candidate") and not Abrasive.capacity():result.append("Abrasive lot register full.")
	if spec.has("abrasive_inspection") and Abrasive.selected(spec).is_empty():result.append("No traceable abrasive candidates at this store.")
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
			return {"ok":true,"message":"Production line updated."}
	return {"error":"Select a persistent production line."}

static func retool(host: Node, id: int, item: String) -> Dictionary:
	var definition:=recipe(host,item)
	if definition.has("error"): return definition
	for job in host.equipment_queue:
		if int(job.id)!=id or not bool(job.get("persistent",false)): continue
		if not Formed.can_clear(job):return {"error":"Return to the formed workpiece store before retooling this line."}
		if String(job.item)==item: return {"ok":true,"message":"This line already makes that item."}
		var installed:=installed_tooling(job)
		var additions:=missing_tooling(definition.tooling,installed)
		if not Industry.product(item).is_empty() or not definition.tooling.is_empty():
			var blockers:=startup_blockers(host,item,installed)
			if not blockers.is_empty():return {"error":"Cannot retool: "+" ".join(blockers)}
			for resource:String in additions:
				WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(additions[resource])
				installed[resource]=float(installed.get(resource,0))+float(additions[resource])
		job["installed_tooling"]=installed
		var retention:=.65 if String(job.job_type)==String(definition.job_type) else .35
		job.efficiency=maxf(.10,float(job.efficiency)*retention)
		Exposure.clear(job)
		Abrasive.clear(job)
		Machine.clear(job)
		Formed.clear(job)
		Vacuum.clear(job)
		Pattern.clear(job)
		Weld.clear(job)
		Fracture.clear(job)
		Slitting.clear(job)
		Induction.clear(job)
		Metallurgy.clear(job)
		AlloyTrials.clear(job)
		Casting.clear(job)
		job.merge(definition,true);job.progress_days=0.0;job.completed=0;job.last_output=0;job.last_work=0.0;job.last_consumed={}
		job.required_days=job.work_per_item
		job.erase("planner_managed")
		job.erase("staff_idle")
		return {"ok":true,"message":"Line retooled. Existing setup tools remain assigned; missing tools are added. Some efficiency is retained; unfinished work is discarded without refunding consumed materials."}
	return {"error":"Select a persistent production line."}

static func stock(host: Node, job: Dictionary) -> int:
	if String(job.job_type)=="civilian":return int(WorldSimulation.state.resource_stockpiles.get(String(Industry.product(String(job.item)).get("output","")),0))
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
	if Industry.product(String(job.item)).has("abrasive_candidate") and not Abrasive.capacity():return "Abrasive lot register full"
	if Industry.product(String(job.item)).has("specimen_source") and not Samples.has_capacity():return "Sample register full"
	var inspection:Dictionary=Industry.product(String(job.item))
	if inspection.has("formed_source_curvature"):
		if job.has("formed_piece") and not job.formed_piece.consumed:return "Waiting for workpiece collection"
		if job.has("forming_pending"):
			return "Working" if job.forming_pending.site==WorldSimulation.state.resource_settlement_id else "Workpiece belongs to another store"
	if inspection.get("vacuum_trial",false) and job.has("vacuum_pending"):
		if job.vacuum_pending.site!=WorldSimulation.state.resource_settlement_id:return "Melt belongs to another store"
		return "Working"
	if inspection.get("pattern_trial",false) and job.has("pattern_pending"):
		return "Working" if job.pattern_pending.site==WorldSimulation.state.resource_settlement_id else "Pattern belongs to another store"
	if inspection.get("weld_trial",false) and job.has("weld_pending"):
		if job.weld_pending.site!=WorldSimulation.state.resource_settlement_id:return "Joint belongs to another store"
		return "Working"
	if inspection.get("fracture_trial",false) and job.has("fracture_pending"):
		if job.fracture_pending.site!=WorldSimulation.state.resource_settlement_id:return "Specimen belongs to another store"
		return "Working"
	if inspection.has("slitting_curvature") and job.has("slitting_pending"):
		if job.slitting_pending.site!=WorldSimulation.state.resource_settlement_id:return "Specimen belongs to another store"
		return "Working"
	if inspection.has("induction_frequency") and job.has("induction_pending"):
		if job.induction_pending.site!=WorldSimulation.state.resource_settlement_id:return "Workpiece belongs to another store"
		return "Working"
	if inspection.has("casting_stages") and job.has("casting_pending"):
		if job.casting_pending.site!=WorldSimulation.state.resource_settlement_id:return "Casting belongs to another store"
		return "Working"
	if inspection.get("alloy_phase_trial",false) and job.has("alloy_trial"):
		if job.alloy_trial.site!=WorldSimulation.state.resource_settlement_id:return "Trial belongs to another store"
		return "Working" if preload("res://scripts/technology_operations.gd").service("electricity")>0 else "Waiting for electricity"
	if inspection.has("thermal_program") and job.has("metallurgy_pending"):
		if job.metallurgy_pending.site!=WorldSimulation.state.resource_settlement_id:return "Workpiece belongs to another store"
		var pending:Dictionary=job.metallurgy_pending
		if pending.phase=="inspection" and not preload("res://scripts/metallurgy_sections.gd").available(inspection):return "Waiting for adopted grain-size measurement"
		var cooling:bool=pending.phase=="thermal" and float(pending.run.program[int(pending.run.stage)].power)==0
		return "Working" if cooling or preload("res://scripts/technology_operations.gd").service("electricity")>0 else "Waiting for electricity"
	if inspection.has("machine_program") and job.has("machine_pending"):
		if job.machine_pending.site!=WorldSimulation.state.resource_settlement_id:return "Workpiece belongs to another store"
		return "Working" if preload("res://scripts/technology_operations.gd").service("electricity")>0 else "Waiting for electricity"
	if inspection.has("abrasive_inspection") and not job.has("abrasive_pending") and Abrasive.selected(inspection).is_empty():return "No traceable abrasive candidates"
	if job.has("abrasive_pending") and job.abrasive_pending.source_store!=WorldSimulation.state.resource_settlement_id:return "Inspection belongs to another store"
	var needs_specimen:=Industry.product(String(job.item)).has("exposure_days") and not job.has("exposure_started_day")
	for resource in job.materials:
		if job.has("exposure_started_day") or job.has("abrasive_pending"):continue
		var available:=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		if needs_specimen and available<float(job.materials[resource]):return "Missing "+WorldSimulation.resources.display_name(String(resource))+" for full specimen"
		if float(job.materials[resource])>0 and available<=.000000001: return "Missing "+WorldSimulation.resources.display_name(String(resource))
	if power_per_item(job)>0 and preload("res://scripts/technology_operations.gd").service("electricity")<=.000000001:return "Waiting for electricity"
	for name:String in services_per_item(job):
		if preload("res://scripts/technology_operations.gd").service(name)<=.000000001:return "Waiting for "+name.replace("_"," ")
	return "Working"

static func eligible(host: Node, job: Dictionary) -> bool:
	return state(host,job) in ["Working","Batch"]

static func workforce() -> Dictionary:
	var workers:=WorldSimulation.state.effective_workers("Crafting")
	var health:=clampf(WorldSimulation.state.population_health,0.0,1.0)
	var labor:=clampf(float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72)),0.0,1.45)
	var carrying:=WorldSimulation.state.effective_workers("Logistics")
	var logistics:=clampf(.35+carrying/maxf(1.0,workers*.3)*.65,.35,1.0)
	var weight:=0.0;var usable:=0.0
	for plot in WorldSimulation.state.settlement_plots:
		if String(plot.get("land_use","")) not in ["workshop","mixed_household"]: continue
		var size:=maxf(1.0,float(plot.get("worker_capacity",1)))
		weight+=size
		if String(plot.get("status","active")) in ["ruin","vacant","reclaimed","under_construction"]: continue
		var damage: Dictionary=plot.get("damage",{})
		usable+=size*clampf(float(plot.get("condition",1)),0,1)*(1-clampf(float(damage.get("structural",0)),0,1))
	# Mobile crafts are possible with carried tools; founded workplace damage
	# reduces the real recorded productive fabric rather than a decorative score.
	var facilities:=usable/weight if weight>0 else .5
	var powered_factor:=1.0+minf(.5,preload("res://scripts/technology_operations.gd").service("mechanical_work")/maxf(1.0,workers))
	return {"powered_factor":powered_factor,"workers":workers,"health":health,"labor_efficiency":labor,"logistics":logistics,"workplace_condition":facilities,"condition_factor":health*labor*logistics*facilities*powered_factor}

static func advance(host: Node, job: Dictionary, work: float) -> void:
	job.last_output=0;job.last_work=0.0;job.last_consumed={}
	var can_run:=eligible(host,job)
	if job.has("casting_pending"):Casting.synchronize_idle(job,Industry.product(String(job.item)),work if can_run else 0.0)
	AlloyTrials.synchronize_idle(job,work if can_run else 0.0)
	Metallurgy.synchronize_idle(job,work if can_run else 0.0)
	Induction.synchronize_idle(job,work if can_run else 0.0)
	Pattern.synchronize_idle(job,work if can_run else 0.0)
	Weld.synchronize_idle(job,work if can_run else 0.0)
	Vacuum.synchronize_idle(job,work if can_run else 0.0)
	if not can_run or work<=0:
		return
	if preload("res://scripts/research_licenses.gd").uses_license(String(job.item)):work*=.65
	var exposure_spec:=Industry.product(String(job.item))
	if exposure_spec.has("formed_source_curvature"):
		Formed.advance(job,exposure_spec,work)
		return
	if exposure_spec.get("vacuum_trial",false):
		Vacuum.advance(job,exposure_spec,work)
		return
	if exposure_spec.get("pattern_trial",false):
		Pattern.advance(job,exposure_spec,work)
		return
	if exposure_spec.get("weld_trial",false):
		Weld.advance(job,exposure_spec,work)
		return
	if exposure_spec.get("fracture_trial",false):
		Fracture.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("slitting_curvature"):
		Slitting.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("induction_frequency"):
		Induction.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("casting_stages"):
		Casting.advance(job,exposure_spec,work)
		return
	if exposure_spec.get("alloy_phase_trial",false):
		AlloyTrials.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("thermal_program"):
		Metallurgy.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("machine_program"):
		Machine.advance(job,exposure_spec,work)
		return
	if exposure_spec.has("abrasive_inspection"):
		Abrasive.advance(job,work)
		return
	if exposure_spec.has("exposure_days"):
		Exposure.advance(job,exposure_spec,work)
		return
	var per_item:=float(job.work_per_item)
	var units:=work/per_item
	if int(job.target_stock)>0:
		units=minf(units,maxf(0.0,int(job.target_stock)-stock(host,job)-float(job.progress_days)/per_item))
	var possible:=units
	if exposure_spec.has("specimen_source"):possible=minf(possible,1000000000.0)
	for resource in job.materials:
		var cost:=float(job.materials[resource])
		if cost>0: possible=minf(possible,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0)))/cost)
	var power:=power_per_item(job)
	if power>0:possible=minf(possible,preload("res://scripts/technology_operations.gd").service("electricity")/power)
	var services:=services_per_item(job)
	for name:String in services:
		possible=minf(possible,preload("res://scripts/technology_operations.gd").service(name)/float(services[name]))
	possible=maxf(0,possible)
	if power>0:preload("res://scripts/technology_operations.gd").consume_electricity(possible*power)
	for name:String in services:preload("res://scripts/technology_operations.gd").consume_service(name,possible*float(services[name]))
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
	elif String(job.job_type)=="civilian":
		# Yield belongs to the authored recipe, never mutable saved job metadata.
		var definition:=Industry.product(String(job.item))
		Samples.completed(String(job.item),produced)
		Abrasive.record(job,produced)
		var yields:Dictionary=definition.get("co_products",{}).duplicate()
		yields[String(definition.output)]=1.0
		for resource:String in yields:
			WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))+produced*float(yields[resource])
	else: host.military_inventory[String(job.item)]=stock(host,job)+produced
	if possible>0: job.efficiency=move_toward(float(job.efficiency),1.0,.0025*(.65+host._adoption("workshop_standards"))*minf(1,possible/maxf(.000001,units)))

static func snapshot(host: Node, job: Dictionary, rate: float, share: float) -> Dictionary:
	var result:=job.duplicate(true)
	result["state"]=state(host,job);result["stock"]=stock(host,job);result["share"]=share
	result["licensed"]=preload("res://scripts/research_licenses.gd").uses_license(String(job.item))
	result["daily_work"]=rate*share*float(job.efficiency)*(.65 if result.licensed else 1.0)
	if result.state=="Working" and float(result.daily_work)<=0:
		var staff:=workforce()
		if host.production_labor_share<=0:result.state="No workshop crafting share"
		elif float(staff.workers)<=0:result.state="No available craftspeople"
		elif float(staff.workplace_condition)<=0:result.state="No usable workplaces"
		else:result.state="Workforce unable to work"
	if String(job.job_type)=="civilian":result["co_products"]=Industry.product(String(job.item)).get("co_products",{}).duplicate()
	var exposure_spec:=Industry.product(String(job.item))
	if exposure_spec.has("exposure_days"):result.daily_work=minf(float(result.daily_work),1.0)
	result["output_per_day"]=float(result.daily_work)/float(job.work_per_item)
	result["inputs_per_day"]={}
	for resource in job.materials: result.inputs_per_day[resource]=float(job.materials[resource])*float(result.output_per_day)
	result["forecast_output_per_day"]=float(result.output_per_day) if result.state=="Working" else 0.0
	if exposure_spec.has("exposure_days"):
		for resource:String in result.inputs_per_day:result.inputs_per_day[resource]=0.0
		result["exposure_days_completed"]=float(job.progress_days)
		result["exposure_days_required"]=float(exposure_spec.exposure_days)
		result.forecast_output_per_day=0.0
	result["materials_status"]=[]
	for resource:String in job.materials:
		var cost:=float(job.materials[resource]);var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		if cost>0:result.forecast_output_per_day=minf(float(result.forecast_output_per_day),stored/cost)
		result.materials_status.append({"resource":resource,"name":WorldSimulation.resources.display_name(resource),"stored":stored,"per_item":cost,"per_day":float(result.inputs_per_day[resource])})
	if int(job.target_stock)>0:result.forecast_output_per_day=minf(float(result.forecast_output_per_day),maxf(0,int(job.target_stock)-int(result.stock)-float(job.progress_days)/float(job.work_per_item)))
	var power:=power_per_item(job)
	result["electricity_per_item"]=power
	if power>0:result.forecast_output_per_day=minf(float(result.forecast_output_per_day),preload("res://scripts/technology_operations.gd").service("electricity")/power)
	if exposure_spec.has("abrasive_inspection"):
		result["forecast_inspections_per_day"]=result.forecast_output_per_day
		result["accepted_total"]=int(job.completed)-int(job.get("abrasive_rejected",0))
		result["rejected_total"]=int(job.get("abrasive_rejected",0))
		result.forecast_output_per_day=0.0
	return result

static func validate_saved(payload: Dictionary) -> String:
	var share: Variant=payload.get("production_labor_share",.35)
	if not (share is float or share is int) or not is_finite(float(share)) or float(share)<0 or float(share)>1: return "Invalid production labor share."
	if not payload.get("equipment_queue",[]) is Array:return "Invalid production queue."
	for job in payload.get("equipment_queue",[]):
		if not job is Dictionary: return "Invalid production line."
		if not bool(job.get("persistent",false)): continue
		if job.has("planner_managed") and not job.planner_managed is bool:return "Invalid production management flag."
		for key in ["target_stock","progress_days","work_per_item","allocation","efficiency","completed"]:
			var value: Variant=job.get(key,null)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return "Invalid persistent production value: "+key
		if float(job.target_stock)>MAX_TARGET or float(job.target_stock)!=floorf(float(job.target_stock)) or float(job.completed)!=floorf(float(job.completed)): return "Invalid production counts."
		if float(job.work_per_item)<=0 or float(job.progress_days)>=float(job.work_per_item)+.000001: return "Invalid production work in progress."
		if float(job.allocation)<.05 or float(job.allocation)>4 or float(job.efficiency)<.10 or float(job.efficiency)>1: return "Invalid production priority or efficiency."
		if String(job.get("job_type","")) not in ["production","consumable","transport","civilian"] or String(job.get("item","")).is_empty(): return "Invalid production recipe."
		if not job.get("materials",null) is Dictionary or not job.get("reserved_materials",{}) is Dictionary or not job.get("reserved_materials",{}).is_empty(): return "Invalid production materials."
		if String(job.job_type)=="civilian":
			var definition:=Industry.product(String(job.item))
			if definition.is_empty() or job.materials!=definition.materials or float(job.work_per_item)!=float(definition.days):return "Invalid civilian production recipe."
		var machine_error:=Machine.validate_job(job,Industry.product(String(job.item)))
		if not machine_error.is_empty():return machine_error
		var formed_error:=Formed.validate_job(job,Industry.product(String(job.item)))
		if not formed_error.is_empty():return formed_error
		var vacuum_error:=Vacuum.validate_job(job,Industry.product(String(job.item)))
		if not vacuum_error.is_empty():return vacuum_error
		var pattern_error:=Pattern.validate_job(job,Industry.product(String(job.item)))
		if not pattern_error.is_empty():return pattern_error
		var weld_error:=Weld.validate_job(job,Industry.product(String(job.item)))
		if not weld_error.is_empty():return weld_error
		var fracture_error:=Fracture.validate_job(job,Industry.product(String(job.item)))
		if not fracture_error.is_empty():return fracture_error
		var slitting_error:=Slitting.validate_job(job,Industry.product(String(job.item)))
		if not slitting_error.is_empty():return slitting_error
		var induction_error:=Induction.validate_job(job,Industry.product(String(job.item)))
		if not induction_error.is_empty():return induction_error
		var metallurgy_error:=Metallurgy.validate_job(job,Industry.product(String(job.item)))
		if not metallurgy_error.is_empty():return metallurgy_error
		var alloy_error:=AlloyTrials.validate_job(job,Industry.product(String(job.item)))
		if not alloy_error.is_empty():return alloy_error
		var casting_error:=Casting.validate_job(job,Industry.product(String(job.item)))
		if not casting_error.is_empty():return casting_error
		var abrasive_error:=Abrasive.validate_job(job)
		if not abrasive_error.is_empty():return abrasive_error
		var exposure_error:=Exposure.validate(job,Industry.product(String(job.item)))
		if not exposure_error.is_empty():return exposure_error
		if job.has("installed_tooling"):
			if not job.installed_tooling is Dictionary:return "Invalid installed tooling."
			var allowed:Dictionary={}
			for product:Dictionary in Industry.PRODUCTS.values():
				for resource:String in product.get("tooling",{}):allowed[resource]=true
			for unit:Dictionary in preload("res://scripts/joint_force_catalog.gd").UNITS.values():
				for resource:String in unit.get("tooling",{}):allowed[resource]=true
			for resource:Variant in job.installed_tooling:
				if not resource is String or not allowed.has(resource):return "Unknown installed tool."
				var value:Variant=job.installed_tooling[resource]
				if not (value is int or value is float) or not is_finite(float(value)) or float(value)<=0 or float(value)>MAX_TARGET:return "Invalid installed tooling quantity."
		for value in job.materials.values():
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return "Invalid material cost."
	return Formed.validate_links(payload.get("equipment_queue",[]))

static func close(job:Dictionary)->bool:
	return Formed.clear(job)
