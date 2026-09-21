extends RefCounted
## Scheduling and receipts only. Existing production owns every material and hour.
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Planner=preload("res://scripts/civilian_production_planner.gd")
const MAX_RECEIPTS:=256
var host:Node
var data:Dictionary={}
func _init(campaign:Node)->void:
	host=campaign
	reset()
func reset()->void:
	data={"enabled":true,"last_day":-1,"status":"Staff review workshop needs each day.","receipts":[],"totals":{},"tracking_day":-1}
func owner()->String:
	for office:String in ["Quartermaster","Steward"]:
		var person:Dictionary=WorldSimulation.government.officeholder(office)
		if not person.is_empty():return "%s · %s" % [String(person.name),office]
	return "No workshop officeholder"
func set_enabled(enabled:bool)->Dictionary:
	data.enabled=enabled
	if not enabled:
		for job:Dictionary in host.equipment_queue:
			if job.has("ai_turnover") and bool(job.get("planner_managed",false)):
				job.erase("ai_turnover");job.paused=false
	data.status="Staff review workshop needs each day." if enabled else "Scheduling is manual. Existing orders continue."
	return {"ok":true,"message":data.status}
func delegate_lines()->Dictionary:
	data.enabled=true
	for job:Dictionary in host.equipment_queue:
		if bool(job.get("persistent",false)) and not bool(job.get("paused",false)):
			job.planner_managed=true
			if int(job.get("target_stock",0))==0:job.target_stock=P.stock(host,job)+1
	return {"ok":true,"message":"Staff now schedule unpaused lines. Work in progress is preserved; manual target or pause changes take a line back under your control."}
func delegate_line(id:int)->Dictionary:
	for job:Dictionary in host.equipment_queue:
		if int(job.get("id",-1))!=id or not bool(job.get("persistent",false)):continue
		data.enabled=true
		job.planner_managed=true
		job.paused=false
		job.erase("staff_idle")
		if int(job.get("target_stock",0))==0:job.target_stock=P.stock(host,job)+1
		return {"ok":true,"message":"Line returned to leader management; unfinished work is preserved."}
	return {"error":"Select an active production line."}
func advance(day:int)->void:
	if WorldSimulation.actor_id!="player" or int(data.last_day)==day:return
	data.last_day=day
	if not bool(data.enabled):return
	if not WorldSimulation.state.settlement_site_committed:return
	if WorldSimulation.government.officeholder("Quartermaster").is_empty() and WorldSimulation.government.officeholder("Steward").is_empty():
		data.status="Appoint a steward or quartermaster to manage the workshops.";return
	preload("res://scripts/ai_workshop_turnover.gd").advance("player",host,true)
	var demands:=army_demands()
	for job:Dictionary in host.equipment_queue:
		if not bool(job.get("planner_managed",false)) or not bool(job.get("persistent",false)) or String(job.get("job_type",""))!="production":continue
		var target:=0
		for demand:Dictionary in demands:
			if String(demand.item)==String(job.item):target=int(demand.target)
		# Stop once the authorized army requirement disappears. Don't accumulate
		# another army's worth of equipment after the last intake or cancellation.
		var finishing:=target==0 and float(job.get("progress_days",0))>0
		job.target_stock=P.stock(host,job)+1 if finishing else maxi(1,target)
		job.paused=target==0 and not finishing
		job["staff_idle"]=bool(job.paused)
	var civilian:=preload("res://scripts/civilian_investment_planner.gd").recommendation()
	if not civilian.is_empty():demands.append(civilian)
	# Alternate first consideration; a standing military order cannot starve
	# civilian supply planning forever, and vice versa.
	if day%2==0 and not civilian.is_empty():demands.push_front(demands.pop_back())
	data.status="No additional feasible supply order. Existing lines continue." if not host.equipment_queue.is_empty() else "Workshop idle: no feasible order for current needs. Household crafts are recorded separately from production lines."
	for demand:Dictionary in demands:
		var result:=schedule(demand)
		data.status=String(result.get("message",result.get("error",data.status)))
		if bool(result.get("changed",false)):return
func army_demands()->Array[Dictionary]:
	var totals:Dictionary={}
	for template:Dictionary in host.army_templates:
		if not bool(template.get("recruitment_requested",false)):continue
		var quote:Dictionary=host.template_training_quote(int(template.template_id))
		for item:String in quote.get("equipment",{}):totals[item]=int(totals.get(item,0))+int(quote.equipment[item])
	# Serving troops need replacement and initial equipment even when no new
	# recruitment template has been requested. Demand is only their missing gear;
	# already issued equipment and stored inventory must not be manufactured twice.
	for force:Dictionary in [host.home_army]+host.field_armies+host.occupation_forces:
		for formation:Dictionary in force.get("formations",[]):
			var item:=String(formation.get("weapon","improvised"))
			var required:=maxi(0,int(formation.get("equipment_required",formation.get("count",0))))
			var missing:=maxi(0,required-int(formation.get("equipment",0)))
			if missing>0:totals[item]=int(totals.get(item,0))+missing
			var ammunition:=String(host._ammunition_type_for(item))
			if not ammunition.is_empty():
				var rounds:=maxi(0,int(formation.get("ammunition_required",host._ammunition_required_for(item,required)))-int(formation.get("ammunition",0)))
				if rounds>0:totals[ammunition]=int(totals.get(ammunition,0))+rounds
	var result:Array[Dictionary]=[]
	for item:String in totals:
		var recipe:=P.recipe(host,item)
		if recipe.has("error"):continue
		if int(totals[item])<=P.stock(host,recipe):continue
		var upstream:Dictionary={}
		for material:String in recipe.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(material,0))<float(recipe.materials[material]):
				upstream=Planner.supply(material,ceili(float(recipe.materials[material])*int(totals[item])),{})
				if not upstream.is_empty():break
		result.append(upstream if not upstream.is_empty() else {"item":item,"target":int(totals[item])})
	return result
func schedule(demand:Dictionary)->Dictionary:
	if String(demand.get("kind",""))=="plant_install":
		var installed:=WorldSimulation.submit("player",demand)
		if installed.has("error"):return installed
		return {"changed":true,"message":"Work commissioned: %s. Materials and labor are paid through construction." % String(demand.get("plant","")).replace("_"," ")}
	var item:=String(demand.get("item",""));var target:=clampi(int(demand.get("target",1)),1,P.MAX_TARGET)
	for job:Dictionary in host.equipment_queue:
		if String(job.item)!=item:continue
		if not bool(job.get("planner_managed",false)) or (bool(job.get("paused",false)) and not bool(job.get("staff_idle",false))):
			return {"message":"%s is under your control; staff have left its order unchanged." % P.product_name(item)}
		if int(job.target_stock)==target and not bool(job.get("staff_idle",false)):return {"message":"Supplying %s · target %d in stores." % [P.product_name(item),target]}
		var updated:Dictionary=host.configure_production_line(int(job.id),target,false)
		if updated.has("error"):return updated
		job.planner_managed=true
		job.erase("staff_idle")
		return {"changed":true,"message":"Adjusted %s to current demand: %d in stores." % [P.product_name(item),target]}
	var result:Dictionary={}
	if host.equipment_queue.size()<host.production_line_capacity():result=host.start_production_line(item,target)
	else:
		for job:Dictionary in host.equipment_queue:
			# Never discard trials, reserved inputs, manual work, or a paused order.
			if not bool(job.get("planner_managed",false)) or not bool(job.get("persistent",false)) or (bool(job.get("paused",false)) and not bool(job.get("staff_idle",false))):continue
			if float(job.get("progress_days",0))>0 or not (job.get("reserved_materials",{}) as Dictionary).is_empty():continue
			var pending:=false
			for key:String in job:
				if key.ends_with("pending") or key.ends_with("trial") or key=="formed_piece":pending=true
			if pending or (P.state(host,job)!="Target met" and not bool(job.get("staff_idle",false))):continue
			result=host.retool_production_line(int(job.id),item)
			if result.has("error"):continue
			result=host.configure_production_line(int(job.id),target,false)
			result["job_id"]=int(job.id);break
		if result.is_empty():
			if preload("res://scripts/ai_workshop_turnover.gd").request("player",host,item,target,true):
				return {"changed":true,"message":"Finishing the current batch, then supplying %s." % P.product_name(item)}
			return {"message":"All lines are occupied. Staff wait for a delegated line to finish; manual orders are protected."}
	if result.has("error"):return result
	for job:Dictionary in host.equipment_queue:
		if int(job.id)==int(result.get("job_id",-1)):job.planner_managed=true
	return {"changed":true,"message":"Scheduled %s · replenish to %d in stores." % [P.product_name(item),target]}
func output_stocks(job:Dictionary)->Dictionary:
	var item:=String(job.item);var kind:=String(job.get("job_type","production"))
	if kind=="civilian":
		var spec:=I.product(item);var stocks:Dictionary={}
		for resource:String in [String(spec.get("output",""))]+spec.get("co_products",{}).keys():
			stocks[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		return stocks
	return {item:float(P.stock(host,job))}
func record(job:Dictionary,before:Dictionary)->void:
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data.tracking_day)<0:data.tracking_day=day
	var city_id:=String(WorldSimulation.state.resource_settlement_id)
	var city_name:=String(WorldSimulation.state.settlement_name)
	if city_id.is_empty():
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if bool(city.get("primary",false)):city_id=String(city.id);city_name=String(city.name);break
	var after:=output_stocks(job)
	for resource:String in after:
		var amount:=float(after[resource])-float(before.get(resource,after[resource]))
		if amount<=.0000001:continue
		var entry:={"day":day,"item":String(job.item),"resource":resource,"kind":String(job.get("job_type","production")),"quantity":amount,"settlement_id":city_id,"settlement_name":city_name}
		_add_total(data.totals,entry)
		var combined:=false
		for receipt:Dictionary in data.receipts:
			if String(receipt.get("settlement_id",""))==city_id and int(receipt.day)==day and String(receipt.item)==String(job.item) and String(receipt.resource)==resource and String(receipt.kind)==String(job.get("job_type","production")):
				receipt.quantity=float(receipt.quantity)+amount;combined=true;break
		if not combined:data.receipts.push_front(entry)
	while data.receipts.size()>MAX_RECEIPTS:data.receipts.pop_back()
func record_household(made:Dictionary)->void:
	if WorldSimulation.actor_id!="player" or made.is_empty():return
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data.tracking_day)<0:data.tracking_day=day
	var city_id:=String(WorldSimulation.state.resource_settlement_id)
	var city_name:=String(WorldSimulation.state.settlement_name)
	if city_id.is_empty():
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if bool(city.get("primary",false)):city_id=String(city.id);city_name=String(city.name);break
	for resource:String in made:
		var amount:=float(made[resource])
		if amount<=0:continue
		_add_total(data.totals,{"day":day,"item":resource,"resource":resource,"kind":"household","quantity":amount,"settlement_id":city_id,"settlement_name":city_name})

func restore(payload:Dictionary)->void:
	reset()
	data.merge(payload.duplicate(true),true)
	if not payload.has("totals"):
		for receipt:Dictionary in data.receipts:_add_total(data.totals,receipt)
static func _add_total(totals:Dictionary,receipt:Dictionary)->void:
	var key:=JSON.stringify([receipt.get("settlement_id",""),receipt.kind,receipt.resource])
	if not totals.has(key):totals[key]=receipt.duplicate(true);totals[key].quantity=0.0
	totals[key].quantity=float(totals[key].quantity)+float(receipt.quantity)
	if int(receipt.day)>=int(totals[key].day):
		totals[key].day=receipt.day
		totals[key]["settlement_name"]=receipt.get("settlement_name","Settlement not recorded")
static func history_totals(receipts:Array,totals:Dictionary={})->Array:
	if not totals.is_empty():return totals.values()
	var reconstructed:Dictionary={}
	for receipt:Dictionary in receipts:_add_total(reconstructed,receipt)
	return reconstructed.values()

static func validate(payload:Variant)->String:
	if not payload is Dictionary:return "Invalid workshop management."
	if not payload.get("enabled",true) is bool:return "Invalid workshop delegation."
	for key:String in ["last_day","tracking_day"]:
		var value:Variant=payload.get(key,-1)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<-1 or float(value)!=floorf(float(value)):return "Invalid workshop date."
	if not payload.get("status","") is String:return "Invalid workshop status."
	if not payload.get("receipts",[]) is Array or payload.get("receipts",[]).size()>MAX_RECEIPTS:return "Invalid workshop receipts."
	if not payload.get("totals",{}) is Dictionary:return "Invalid production totals."
	for receipt:Variant in payload.get("receipts",[])+payload.get("totals",{}).values():
		if not receipt is Dictionary:return "Invalid workshop receipt."
		for key:String in ["item","resource","kind"]:
			if not receipt.get(key,"") is String or String(receipt.get(key,"")).is_empty():return "Invalid workshop product."
		for field:String in ["settlement_id","settlement_name"]:
			if receipt.has(field) and not receipt[field] is String:return "Invalid production settlement."
		for key:String in ["day","quantity"]:
			var value:Variant=receipt.get(key,null)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return "Invalid workshop output."
		if float(receipt.day)!=floorf(float(receipt.day)):return "Invalid workshop receipt date."
	return ""
