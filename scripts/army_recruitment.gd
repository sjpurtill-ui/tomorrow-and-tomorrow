extends RefCounted
## One standing order fills missing personnel in supplied, capacity-limited groups.
## Home soldiers keep their experience, equipment and availability.
var host:Node
func _init(campaign:Node)->void:host=campaign
func quote(template_id:int)->Dictionary:
	var index:int=host._template_index(template_id)
	if index<0:return {"error":"Army design not found."}
	var required:=0;var missing:=0;var active:=0;var home_total:=0;var start_now:=0
	var shortfalls:Array[Dictionary]=[];var batches:Array[Dictionary]=[];var blockers:Array[String]=[]
	var equipment:Dictionary={};var equipment_rows:Array[Dictionary]=[]
	var stock:Dictionary=host.military_inventory.duplicate(true)
	var places:int=maxi(0,host.training_capacity()-host._queued_trainees())
	var people:int=host.aggregate_recruits+maxi(0,host.recruitment_capacity()-host._mobilized_count())
	var space_left:=places;var people_left:=people
	var food_left:float=host.training_staff.spendable_food();var food:=0.0
	var policy:Dictionary=host.training_staff.policy("army")
	var global_block:=""
	if not host.active_engagement.is_empty() or not host.pending_aftermath.is_empty():global_block="Finish the battle or aftermath before enrolling recruits."
	elif host.recovery.home_unavailable():global_block="Home is occupied; recruitment cannot operate here."
	elif float(policy.intake)<=0:global_block="Army training is suspended. Choose a training policy to resume."
	for entry:Dictionary in host.army_templates[index].get("entries",[]):
		var unit:=String(entry.unit);var weapon:=String(entry.weapon);var count:=int(entry.count)
		var home:int=mini(count,host._matching_home_count(unit,weapon))
		var training:int=mini(count-home,host._matching_training_count(unit,weapon))
		var need:=maxi(0,count-home-training)
		required+=count;home_total+=home;active+=training;missing+=need
		var needed_gear:int=host._equipment_required_for(unit,need)
		equipment[weapon]=int(equipment.get(weapon,0))+needed_gear

		if need<=0:continue
		shortfalls.append({"unit":unit,"weapon":weapon,"missing":need})
		var gate:Dictionary=host._training_gate(unit,weapon)
		if gate.has("error"):blockers.append(String(gate.error));continue
		var candidate:=mini(need,mini(space_left,people_left))
		if bool(gate.get("prototype",false)):
			if need>host.PROTOTYPE_COHORT_LIMIT:blockers.append("Experimental units are limited to %d people until the practice is established." % host.PROTOTYPE_COHORT_LIMIT);continue
			candidate=mini(candidate,host.PROTOTYPE_COHORT_LIMIT)
		var days:float=host.UnitCatalog.training_days(unit)*(host.PROTOTYPE_TRAINING_MULTIPLIER if bool(gate.get("prototype",false)) else 1.0)
		var per_person:=maxf(.18,days*.18)
		candidate=mini(candidate,maxi(0,floori(food_left/per_person)))
		# Binary search handles shared artillery/vehicle sets without assuming one
		# weapon per person. Deduct the same stock budget across all entries.
		var low:=0;var high:=candidate
		while low<high:
			var middle:=(low+high+1)/2
			if host._equipment_required_for(unit,middle)<=int(stock.get(weapon,0)):low=middle
			else:high=middle-1
		candidate=low if global_block.is_empty() else 0
		if candidate>0:
			var gear:int=host._equipment_required_for(unit,candidate)
			batches.append({"unit":unit,"weapon":weapon,"count":candidate,"equipment":gear})
			start_now+=candidate;space_left-=candidate;people_left-=candidate
			stock[weapon]=int(stock.get(weapon,0))-gear;food_left-=candidate*per_person;food+=candidate*per_person
		if candidate<need:
			var name:String=host.PersistentProduction.product_name(weapon)
			if needed_gear>int(host.military_inventory.get(weapon,0)):blockers.append("%s: %d in stores; %d needed for all missing recruits." % [name,int(host.military_inventory.get(weapon,0)),needed_gear])
	# Stores are shared by equipment type, not a separate supply for each unit.
	# Present the actual stock once, before any proposed intake reservations.
	for weapon:String in equipment:
		var held:=0;var reserved:=0
		for formation:Dictionary in host.home_army.get("formations",[]):
			if formation.get("weapon","")==weapon:held+=int(formation.get("equipment",0))
		for order:Dictionary in host.training_queue:
			if order.get("weapon","")==weapon:reserved+=int(order.get("reserved_equipment",0))
		equipment_rows.append({"weapon":weapon,"needed":int(equipment[weapon]),"stored":int(host.military_inventory.get(weapon,0)),"issued":held,"reserved":reserved})
	if not global_block.is_empty():blockers.push_front(global_block)
	elif missing>start_now:
		if places<=start_now:blockers.append("Training space: %d free now. The next group follows when a place opens." % places)
		if people<=start_now:blockers.append("Recruitable people: %d now; %d still needed. Review military commitments to free more people." % [people,missing])
		if food_left<.18:blockers.append("Food reserve protected. Recruitment resumes when extra training rations are available.")
		elif start_now==0 and blockers.is_empty():blockers.append("Not enough extra training rations above the seven-day civilian reserve.")
	var summary:="%d can start now · %d follow automatically" % [start_now,maxi(0,missing-start_now)] if start_now>0 else ("%d already training · staff fill remaining places automatically" % active if active>0 else "Waiting for supplies or people")
	if missing<=0:summary="All %d soldiers are at home" % home_total if active==0 else "%d at home · %d in training" % [home_total,active]
	return {"can_start":start_now>0,"start_now":start_now,"missing":missing,"required":required,"home":home_total,"shortfalls":shortfalls,"blockers":blockers,"food":food,"people_room":people,"training_places":places,"equipment":equipment,"equipment_rows":equipment_rows,"active_training":active,"batches":batches,"summary":summary}
func enroll(template_id:int,retain_order:bool)->Dictionary:
	var index:int=host._template_index(template_id)
	if index<0:return {"error":"Army design not found."}
	if retain_order:host.army_templates[index].recruitment_requested=true
	var view:=quote(template_id)
	if int(view.missing)<=0:return {"ok":true,"queued":0,"message":String(view.summary)+". Staff will replace later shortfalls while recruitment is on."}
	if not bool(view.can_start):return {"ok":true,"queued":0,"waiting":true,"message":"Recruitment is on. "+String(view.blockers[0] if not view.blockers.is_empty() else view.summary)}
	var queued:=0
	for batch:Dictionary in view.batches:
		var count:=int(batch.count)
		if host.aggregate_recruits<count:host.raise_recruits(count-host.aggregate_recruits)
		var result:Dictionary=host.start_training(batch.unit,batch.weapon,count)
		if result.has("error"):continue
		var order:Dictionary=host.training_queue[-1]
		order.recruitment_template=template_id
		var gear:int=host._equipment_required_for(batch.unit,int(result.accepted))
		order.reserved_equipment=gear
		host.military_inventory[batch.weapon]=int(host.military_inventory.get(batch.weapon,0))-gear
		queued+=int(result.accepted)
	return {"ok":true,"queued":queued,"message":"%d recruits started training. %d soldiers remain at home. %d still to recruit; staff handle the next group automatically." % [queued,int(view.home),maxi(0,int(view.missing)-queued)]}
