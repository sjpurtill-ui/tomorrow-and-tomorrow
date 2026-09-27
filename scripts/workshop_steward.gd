extends RefCounted
## Scheduling and receipts only. Existing production owns every material and hour.
## Lines make military equipment only; civilian investment orders install plants.
const P=preload("res://scripts/persistent_production.gd")
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
func review_arrivals()->void:
	if WorldSimulation.actor_id!="player" or not bool(data.enabled) or not WorldSimulation.state.settlement_site_committed:return
	if WorldSimulation.government.officeholder("Quartermaster").is_empty() and WorldSimulation.government.officeholder("Steward").is_empty():return
	var food:=preload("res://scripts/leader_personality.gd").food_constraints(WorldSimulation.state.simulation_metrics)
	if preload("res://scripts/civilization_controller.gd").production_food_blocked(food):return
	var civilian:=preload("res://scripts/civilian_investment_planner.gd").recommendation()
	if civilian.is_empty():return
	var result:=schedule(civilian)
	if bool(result.get("changed",false)):data.status=String(result.get("message","Civilian work scheduled from delivered supplies."))

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
		if bool(result.get("changed",false)):break
	for job:Dictionary in host.equipment_queue:
		if bool(job.get("planner_managed",false)) and bool(job.get("persistent",false)) and String(job.get("job_type",""))=="production":_set_muster_priority(job)
	var request:=extraction_request()
	if not request.is_empty():data.status+=" "+_shortage_note(request)
func army_demands()->Array[Dictionary]:
	var totals:Dictionary={}
	# Supply initial instruction before staff take more people out of civilian work.
	var explicit_recruitment:=false
	for template:Dictionary in host.army_templates:
		if not bool(template.get("recruitment_requested",false)):continue
		explicit_recruitment=true
		var quote:Dictionary=host.template_training_quote(int(template.template_id))
		for item:String in quote.get("equipment",{}):totals[item]=int(totals.get(item,0))+int(quote.equipment[item])
	for order:Dictionary in host.training_queue:
		# Template batches are covered by their quote above. Recruitment lines hold
		# only reserved sets, so their missing weapons are ordered here like any
		# other cohort; otherwise a line short of weapons could wait in drill indefinitely.
		if order.has("build_batch"):continue
		var item:=String(order.get("weapon","improvised"))
		var needed:=maxi(0,host._equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))-int(order.get("reserved_equipment",0)))
		totals[item]=int(totals.get(item,0))+needed
	if not explicit_recruitment:
		var watch_gap:=maxi(0,host._home_garrison_target()-int(host.home_army.get("troops",0))-host._automatic_basic_trainees())
		totals.improvised=int(totals.get("improvised",0))+mini(watch_gap,maxi(0,host.training_capacity()-host._queued_trainees()))
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
		result.append(upstream if not upstream.is_empty() else {"item":item,"target":int(totals[item]),"gear":true})
	# Gear for soldiers who already exist comes before stock for future intake.
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _waiting_total(String(a.get("item","")))>_waiting_total(String(b.get("item",""))))
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
			if bool(demand.get("gear",false)):return _top_up_player_line(job,target)
			return {"message":"%s is under your control; staff have left its order unchanged." % P.product_name(item)}
		if job.has("ai_turnover"):return {"message":"Finishing the current batch before the scheduled product change."}
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
## Arming soldiers. Soldiers who lack simple gear help make it: shaping a club
## or hardening a stave point is a few hours' work for anyone, so a waiting
## soldier gives a quarter day to his own weapon. Stores still pay every input;
## skilled gear (bows, metal, carts) stays with the craftspeople.
const MUSTER_WORK_PER_SOLDIER:=0.25
const MUSTER_SIMPLE_WORK:=0.6
const MUSTER_PRIORITY:=2.0
## Most extra weight the workshop officer may ask settlement leaders to put on
## gathering (the base Extraction weight is 11 of about 100).
const EXTRACTION_REQUEST_MAX:=6.0

## Gear still missing for `item`: recruits in training, soldiers at home, and
## soldiers away in the field.
func waiting_for(item:String)->Dictionary:
	var result:={"recruits":0,"serving":0,"away":0}
	for order:Dictionary in host.training_queue:
		if String(order.get("weapon","improvised"))!=item:continue
		result.recruits+=maxi(0,host._equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))-int(order.get("reserved_equipment",0)))
	for formation:Dictionary in host.home_army.get("formations",[]):
		if String(formation.get("weapon","improvised"))==item:result.serving+=_formation_missing(formation)
	for force:Dictionary in host.field_armies+host.occupation_forces:
		# An army standing at home draws gear from the same stores and hands.
		var key:="serving" if host.field_armies.has(force) and host._army_is_home(force) else "away"
		for formation:Dictionary in force.get("formations",[]):
			if String(formation.get("weapon","improvised"))==item:result[key]+=_formation_missing(formation)
	return result
static func _formation_missing(formation:Dictionary)->int:
	return maxi(0,maxi(0,int(formation.get("equipment_required",formation.get("count",0))))-int(formation.get("equipment",0)))
func _waiting_total(item:String)->int:
	if item.is_empty():return 0
	var waiting:=waiting_for(item)
	return int(waiting.recruits)+int(waiting.serving)+int(waiting.away)

## Daily work the soldiers at home add to a line making their own simple gear.
func muster_hands_work(job:Dictionary)->float:
	if not bool(job.get("persistent",false)) or String(job.get("job_type",""))!="production" or bool(job.get("paused",false)):return 0.0
	if float(job.get("work_per_item",1.0))>MUSTER_SIMPLE_WORK or WorldSimulation.state.convoy_traveling:return 0.0
	var waiting:=waiting_for(String(job.get("item","")))
	var still:=int(waiting.recruits)+int(waiting.serving)-P.stock(host,job)
	if still<=0:return 0.0
	return still*MUSTER_WORK_PER_SOLDIER*clampf(float(WorldSimulation.state.population_health),.2,1.0)

## Staff lines making gear for waiting soldiers get high priority, and return
## to normal priority once everyone is armed.
func _set_muster_priority(job:Dictionary)->void:
	if _waiting_total(String(job.get("item","")))>0:
		if float(job.get("allocation",1.0))<MUSTER_PRIORITY:
			job.allocation=MUSTER_PRIORITY;job["muster_priority"]=true
	elif bool(job.get("muster_priority",false)):
		job.allocation=1.0;job.erase("muster_priority")

## A line the player runs keeps its owner, priority and pause. When soldiers are
## missing gear the officer only raises a too-low stock target, says so, and
## leaves pausing the line as the player's way to stop him.
func _top_up_player_line(job:Dictionary,target:int)->Dictionary:
	var name:=P.product_name(String(job.item))
	var waiting:=_waiting_total(String(job.item))
	if bool(job.get("paused",false)):
		return {"message":"%s is paused on your order while %d soldiers wait for them. Resume the line or hand it to the %s." % [name,waiting,_office()]}
	var current:=int(job.target_stock)
	if current==0 or current>=target:return {"message":"%s: your order already covers the soldiers' missing gear." % name}
	if not job.has("quartermaster_top_up"):job["quartermaster_top_up"]={"from":current}
	job.quartermaster_top_up["to"]=target
	job.target_stock=target
	return {"changed":true,"message":"The %s raised your %s order from %d to %d so %d waiting soldiers are armed. Pause the line to stop this." % [_office(),name.to_lower(),current,target,waiting]}

func _office()->String:
	return "Quartermaster" if not WorldSimulation.government.officeholder("Quartermaster").is_empty() else "Steward"
func _has_officer()->bool:
	return not (WorldSimulation.government.officeholder("Quartermaster").is_empty() and WorldSimulation.government.officeholder("Steward").is_empty())

## Materials that stores cannot cover for the gear soldiers still lack:
## {resource:{"needed","stored","missing"}}.
func material_shortfalls()->Dictionary:
	var needed:Dictionary={}
	var items:Dictionary={}
	for order:Dictionary in host.training_queue:items[String(order.get("weapon","improvised"))]=true
	for force:Dictionary in [host.home_army]+host.field_armies+host.occupation_forces:
		for formation:Dictionary in force.get("formations",[]):items[String(formation.get("weapon","improvised"))]=true
	for item:String in items:
		var recipe:=P.recipe(host,item)
		if recipe.has("error"):continue
		var to_make:=_waiting_total(item)-P.stock(host,recipe)
		if to_make<=0:continue
		for resource:String in recipe.materials:needed[resource]=float(needed.get(resource,0))+float(recipe.materials[resource])*to_make
	var result:Dictionary={}
	for resource:String in needed:
		var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
		if stored+.0001<float(needed[resource]):result[resource]={"needed":float(needed[resource]),"stored":stored,"missing":float(needed[resource])-stored}
	return result

## Extra Extraction weight the workshop officer asks settlement leaders for
## while soldiers' gear is short of materials. GovernmentPeopleSystem reads it
## and still owns the labor split, the food floor and the survival guards.
func extraction_request()->Dictionary:
	if WorldSimulation.actor_id!="player" or not bool(data.enabled) or not WorldSimulation.state.settlement_site_committed or not _has_officer():return {}
	var short:=material_shortfalls()
	if short.is_empty():return {}
	var worst:=0.0
	for resource:String in short:worst=maxf(worst,float(short[resource].missing)/maxf(.001,float(short[resource].needed)))
	return {"weight":EXTRACTION_REQUEST_MAX*clampf(.4+worst,.4,1.0),"materials":short.keys(),"shortfalls":short}

func _shortage_note(request:Dictionary)->String:
	var parts:Array[String]=[]
	for resource:String in request.shortfalls:
		var short:Dictionary=request.shortfalls[resource]
		parts.append("%s (%d needed, %d in store)" % [WorldSimulation.resources.display_name(resource).to_lower(),ceili(float(short.needed)),floori(float(short.stored))])
	return "Short of %s for soldiers' gear; the %s has asked the settlement leaders for more hands to gather it." % [", ".join(parts),_office()]

static func _gather_phrase(resource:String)->String:
	match resource:
		"Timber":return "cut timber"
		"Stone":return "quarry stone"
		"Fiber Plants":return "gather fibre"
	return "gather "+WorldSimulation.resources.display_name(resource).to_lower()

static func _plan_reason(waiting:Dictionary)->String:
	var parts:Array[String]=[]
	if int(waiting.recruits)>0:parts.append("the new recruits")
	if int(waiting.serving)>0:parts.append("soldiers at home")
	if int(waiting.away)>0:parts.append("the army in the field")
	if parts.size()==3:return "for the new recruits, soldiers at home and the army in the field"
	return "for "+" and ".join(parts)

## Line `id`'s job while it makes gear someone is waiting for, else {}.
func _gear_job(id:int)->Dictionary:
	for job:Dictionary in host.equipment_queue:
		if int(job.get("id",-1))!=id:continue
		if String(job.get("job_type",""))!="production" or not bool(job.get("persistent",false)) or bool(job.get("paused",false)):return {}
		return job
	return {}

## Production-screen hook: what the workshop officer is making on line `id`,
## for whom, and what he has done about materials. {} when no soldier waits.
## {"count":items still to make,"reason":String,"waiting":soldiers,
##  "soldiers_helping":bool,"short":[resources],"raised_from":int (player lines)}
func line_plan(id:int)->Dictionary:
	var job:=_gear_job(id)
	if job.is_empty() or not _has_officer():return {}
	var waiting:=waiting_for(String(job.item))
	var total:=int(waiting.recruits)+int(waiting.serving)+int(waiting.away)
	var count:=total-P.stock(host,job)
	if count<=0:return {}
	var managed:=bool(job.get("planner_managed",false))
	var plan:={"count":count,"reason":_plan_reason(waiting),"waiting":total,"soldiers_helping":muster_hands_work(job)>0,"short":[]}
	if not managed:
		# The player runs this line; the officer at most raised its target.
		plan["officer"]="Your workshop"
		var raised:Dictionary=job.get("quartermaster_top_up",{})
		if not raised.is_empty():
			plan["raised_from"]=int(raised.get("from",0))
			plan.reason+=", after the %s raised your order from %d" % [_office(),int(raised.get("from",0))]
	var request:=extraction_request()
	for resource:String in job.get("materials",{}):
		if (request.get("materials",[]) as Array).has(resource):
			plan.short.append(resource)
			plan.reason+=(" and has asked for more hands to " if managed else "; the %s has asked for more hands to " % _office())+_gather_phrase(resource)
	return plan

## Forces-screen hook: who covers the soldiers' missing `item` and how long it
## takes until all of them are armed. {} when nothing covers the gap.
## {"covered":true,"days":float (absent before a line exists),"maker":String}
func gear_plan(item:String)->Dictionary:
	var waiting:=_waiting_total(item)
	if waiting<=0:return {}
	var recipe:=P.recipe(host,item)
	if recipe.has("error"):return {}
	var to_make:=waiting-P.stock(host,recipe)
	if to_make<=0:return {}
	for line:Dictionary in host.production_lines_snapshot().lines:
		if String(line.get("item",""))!=item or not bool(line.get("persistent",false)) or bool(line.get("paused",false)):continue
		var rate:=float(line.get("forecast_output_per_day",0.0))
		if rate<=0.0:return {}
		var maker:=("the "+_office()) if bool(line.get("planner_managed",false)) and _has_officer() else "your workshop line"
		return {"covered":true,"days":to_make/rate,"maker":maker}
	# No line yet: the officer opens one at the next daily review when he can.
	if bool(data.enabled) and _has_officer() and host.equipment_queue.size()<host.production_line_capacity() and P.startup_blockers(host,item).is_empty():
		return {"covered":true,"maker":"the "+_office()}
	return {}

func output_stocks(job:Dictionary)->Dictionary:
	return {String(job.item):float(P.stock(host,job))}
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
