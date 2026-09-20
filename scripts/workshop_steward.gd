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
	data={"enabled":true,"last_day":-1,"status":"Staff review workshop needs each day.","receipts":[],"tracking_day":-1}
func owner()->String:
	for office:String in ["Quartermaster","Steward"]:
		var person:Dictionary=WorldSimulation.government.officeholder(office)
		if not person.is_empty():return "%s · %s" % [String(person.name),office]
	return "No workshop officeholder"
func set_enabled(enabled:bool)->Dictionary:
	data.enabled=enabled
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
	var civilian:=Planner.recommendation()
	if not civilian.is_empty():demands.append(civilian)
	# Alternate first consideration; a standing military order cannot starve
	# civilian supply planning forever, and vice versa.
	if day%2==0 and not civilian.is_empty():demands.push_front(demands.pop_back())
	data.status="No additional feasible supply order. Existing lines continue."
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
	var result:Array[Dictionary]=[]
	for item:String in totals:
		if int(totals[item])<=int(host.military_inventory.get(item,0)):continue
		var recipe:=P.recipe(host,item)
		if recipe.has("error"):continue
		var upstream:Dictionary={}
		for material:String in recipe.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(material,0))<float(recipe.materials[material]):
				upstream=Planner.supply(material,ceili(float(recipe.materials[material])*int(totals[item])),{})
				if not upstream.is_empty():break
		result.append(upstream if not upstream.is_empty() else {"item":item,"target":int(totals[item])})
	return result
func schedule(demand:Dictionary)->Dictionary:
	var item:=String(demand.get("item",""));var target:=clampi(int(demand.get("target",1)),1,P.MAX_TARGET)
	for job:Dictionary in host.equipment_queue:
		if String(job.item)!=item:continue
		if not bool(job.get("planner_managed",false)) or bool(job.get("paused",false)):
			return {"message":"%s is under your control; staff have left its order unchanged." % P.product_name(item)}
		if int(job.target_stock)==target:return {"message":"Supplying %s · target %d in stores." % [P.product_name(item),target]}
		var updated:Dictionary=host.configure_production_line(int(job.id),target,false)
		if updated.has("error"):return updated
		job.planner_managed=true
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
		if result.is_empty():return {"message":"All lines are occupied. Staff wait for a delegated line to finish; manual orders are protected."}
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
	var after:=output_stocks(job)
	for resource:String in after:
		var amount:=float(after[resource])-float(before.get(resource,after[resource]))
		if amount<=.0000001:continue
		var combined:=false
		for receipt:Dictionary in data.receipts:
			if int(receipt.day)==day and String(receipt.item)==String(job.item) and String(receipt.resource)==resource and String(receipt.kind)==String(job.get("job_type","production")):
				receipt.quantity=float(receipt.quantity)+amount;combined=true;break
		if not combined:data.receipts.push_front({"day":day,"item":String(job.item),"resource":resource,"kind":String(job.get("job_type","production")),"quantity":amount})
	while data.receipts.size()>MAX_RECEIPTS:data.receipts.pop_back()
func restore(payload:Dictionary)->void:
	reset()
	data.merge(payload.duplicate(true),true)
static func validate(payload:Variant)->String:
	if not payload is Dictionary:return "Invalid workshop management."
	if not payload.get("enabled",true) is bool:return "Invalid workshop delegation."
	for key:String in ["last_day","tracking_day"]:
		var value:Variant=payload.get(key,-1)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<-1 or float(value)!=floorf(float(value)):return "Invalid workshop date."
	if not payload.get("status","") is String:return "Invalid workshop status."
	if not payload.get("receipts",[]) is Array or payload.get("receipts",[]).size()>MAX_RECEIPTS:return "Invalid workshop receipts."
	for receipt:Variant in payload.get("receipts",[]):
		if not receipt is Dictionary:return "Invalid workshop receipt."
		for key:String in ["item","resource","kind"]:
			if not receipt.get(key,"") is String or String(receipt.get(key,"")).is_empty():return "Invalid workshop product."
		for key:String in ["day","quantity"]:
			var value:Variant=receipt.get(key,null)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return "Invalid workshop output."
		if float(receipt.day)!=floorf(float(receipt.day)):return "Invalid workshop receipt date."
	return ""
