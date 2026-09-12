extends RefCounted
## Home-workshop repair support; forward recovery and spare-parts cargo are not modeled here.
const ID := "field_armorer_teams"
static func entries()->Array[Dictionary]:
	return [{"id":ID,"name":"Field Armorer Teams","direction":"Warfare","day":0,"chance":.002,"requires":["joinery","workshop_standards"],"requires_all":["joinery","workshop_standards"],"requires_any":[],"learning_routes":[{"id":"local","label":"Organized equipment repair","requires_all":[]}],"signals":["materials","logistics","warfare"],"observation":"Trained crews inspect damaged equipment and organize tools and repair work before returning serviceable items to stores.","effects":{},"repair_method":ID,"production_contract":"Enables repair kits and trained field repair companies. Supplied companies stationed at home contribute repair work to damaged equipment whose manufacture is locally understood. Repairs reserve real materials and workshop space; no new equipment or battlefield salvage appears for free."}]
static func understood(host:Node,item:String)->bool:
	return host.EQUIPMENT_KNOWLEDGE.has(item) and bool(host._knowledge_gate(String(host.EQUIPMENT_KNOWLEDGE[item]),.1).get("unlocked",false))
static func capacity(host:Node)->float:
	if WorldSimulation.state.convoy_traveling or host.recovery.home_unavailable() or not host.active_engagement.is_empty():return 0.0
	if not host.training_program.is_empty() and String(host.training_program.get("scope","army"))=="army":return 0.0
	if ID not in WorldSimulation.state.known_discoveries:return 0.0
	var staff:=0.0
	for force:Dictionary in host._exercise_forces():
		var supplied:=clampf(float(force.get("supply_level",0)),0,1)*clampf(float(WorldSimulation.state.simulation_metrics.get("food_intake_ratio",1)),0,1)
		for formation:Dictionary in force.get("formations",[]):
			if String(formation.get("unit",""))!="field_repair_company" or String(formation.get("weapon",""))!="repair_kit":continue
			staff+=minf(maxf(0,float(formation.get("count",0))),maxf(0,float(formation.get("equipment",0))))*clampf(float(formation.get("training",0)),0,1)*clampf(float(formation.get("personnel_condition",1)),0,1)*supplied
	return staff*.1*WorldSimulation.discovery.adoption(ID)
static func prepare(host:Node)->float:
	var work:=capacity(host)
	if work<=0:return 0.0
	for job:Dictionary in host.equipment_queue:
		if String(job.get("job_type",""))=="repair" and not bool(job.get("paused",false)) and understood(host,String(job.item)):return work
	# One affordable batch per day; use the same reservations and capacity as manual repair.
	var items:Array=host.damaged_equipment.keys();items.sort()
	for item:String in items:
		if not understood(host,item):continue
		for count in range(mini(10,int(host.damaged_equipment[item])),0,-1):
			if not host.equipment_repair_quote(item,count).has("error"):
				host.queue_equipment_repair(item,count)
				return work
	return work
