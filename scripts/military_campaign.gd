extends Node

signal army_changed(army: Dictionary)
signal battle_resolved(result: Dictionary)
signal aftermath_required(aftermath: Dictionary)
signal threat_changed(threat: Dictionary)

const COMBAT_SIMULATOR_SCRIPT:=preload("res://scripts/combat_simulator.gd")
const SAVE_VERSION:=2
const UNIT_KNOWLEDGE:Dictionary={"levy":"","line_infantry":"shield_wall","skirmisher":"bow_craft","cavalry":"__mount_population__","siege_engineer":"siege_engineering","field_artillery":"powder_artillery"}
const EQUIPMENT_KNOWLEDGE:Dictionary={"improvised":"","spear":"hafted_weapons","bow":"bow_craft","sword_shield":"bronze_weaponry","lance":"__mount_population__","siege_kit":"siege_engineering","field_gun":"powder_artillery"}
const UNIT_EQUIPMENT:Dictionary={"levy":["improvised","spear"],"line_infantry":["spear","sword_shield"],"skirmisher":["bow"],"cavalry":["lance","sword_shield"],"siege_engineer":["siege_kit"],"field_artillery":["field_gun"]}

var simulator:RefCounted
var home_army:Dictionary={}
var battle_history:Array[Dictionary]=[]
var pending_aftermath:Dictionary={}
var military_inventory:Dictionary={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
var military_consumables:Dictionary={"arrows":0,"artillery_rounds":0}
var damaged_equipment:Dictionary={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
var recruit_pool:Array[int]=[]
var training_queue:Array[Dictionary]=[]
var training_injuries:Array[Dictionary]=[]
var equipment_queue:Array[Dictionary]=[]
var foreign_prisoners:=0
var held_generals:Array[Dictionary]=[]
var last_world_seed:=-2147483648
var last_processed_day:=-1
var next_training_order_id:=1
var next_formation_id:=1
var next_equipment_job_id:=1
var prisoner_custody_days:=0
var prisoner_escape_accumulator:=0.0
var escaped_prisoners_total:=0
var active_threat:Dictionary={}
var threats_resolved:=0
var active_engagement:Dictionary={}
var war_reputation:Dictionary={"mercy":0.0,"fear":0.0,"grievance":0.0}


func _ready()->void:
	simulator=COMBAT_SIMULATOR_SCRIPT.new()
	set_process(true)


func _process(_delta:float)->void:
	if GameState.world_seed!=last_world_seed:
		reset_for_new_world()
	var current_day:=int(GameState.elapsed_days)
	if last_processed_day<0: last_processed_day=current_day
	while last_processed_day<current_day:
		last_processed_day+=1
		_process_military_day()


func reset_for_new_world()->void:
	last_world_seed=GameState.world_seed
	last_processed_day=int(GameState.elapsed_days)
	home_army={}
	battle_history.clear()
	pending_aftermath.clear()
	military_inventory={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
	military_consumables={"arrows":0,"artillery_rounds":0}
	damaged_equipment={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
	recruit_pool.clear()
	training_queue.clear()
	training_injuries.clear()
	equipment_queue.clear()
	foreign_prisoners=0
	held_generals.clear()
	next_training_order_id=1
	next_formation_id=1
	next_equipment_job_id=1
	prisoner_custody_days=0
	prisoner_escape_accumulator=0.0
	escaped_prisoners_total=0
	active_threat.clear()
	threats_resolved=0
	active_engagement.clear()
	war_reputation={"mercy":0.0,"fear":0.0,"grievance":0.0}


func muster_home_army(requested_strength:=-1)->Dictionary:
	# Compatibility entry point: raise the requested citizens, but do not conjure
	# trained or equipped formations. Call start_training() to field them.
	if home_army.is_empty(): home_army=_empty_home_army()
	var desired:=int(GameState.population_allocations.get("Defense",0)) if requested_strength<0 else maxi(0,int(requested_strength))
	raise_recruits(maxi(0,desired-recruit_pool.size()-_queued_trainees()))
	return campaign_army_snapshot()


func raise_recruits(count:int)->Dictionary:
	GameState.initialize_citizen_registry()
	var candidates:Array[Dictionary]=[]
	var office_holders:Dictionary={}
	for office in GameState.leadership_positions:
		office_holders[int((GameState.leadership_positions[office] as Dictionary).get("citizen_id",-1))]=true
	for citizen in GameState.living_citizens():
		if String(citizen.get("army_status","civilian")) not in ["civilian",""]: continue
		var age:=GameState.citizen_age_years(citizen)
		if age<16 or age>=60: continue
		if office_holders.has(int(citizen.get("id",-1))): continue
		candidates.append(citizen)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_defense:=1 if String(a.get("role",""))=="Defense" else 0
		var b_defense:=1 if String(b.get("role",""))=="Defense" else 0
		if a_defense!=b_defense: return a_defense>b_defense
		var a_score:=GameState.citizen_physical_capacity(a)+float(a.get("military_experience",0.0))*0.18
		var b_score:=GameState.citizen_physical_capacity(b)+float(b.get("military_experience",0.0))*0.18
		return a_score>b_score)
	var capacity:=recruitment_capacity()
	var available_capacity:=maxi(0,capacity-_mobilized_count())
	var raised:=0
	for index in mini(mini(maxi(0,count),candidates.size()),available_capacity):
		var citizen:Dictionary=candidates[index]
		citizen["pre_army_role"]=String(citizen.get("role","Unassigned"))
		citizen["army_status"]="recruit"
		citizen["role"]="Defense"
		recruit_pool.append(int(citizen.id))
		raised+=1
	if home_army.is_empty(): home_army=_empty_home_army()
	if raised>0: GameState.synchronize_population_allocations()
	army_changed.emit(home_army.duplicate(true))
	return {"requested":count,"raised":raised,"recruit_pool":recruit_pool.size(),"capacity":capacity}


func stand_down(count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before standing formations down."}
	var requested:=maxi(0,count)
	if requested<=0: return {"error":"Stand-down count must be positive."}
	var remaining:=requested
	var released_ids:Array[int]=[]
	var returned_equipment:Dictionary={}
	var commander_id:=int((home_army.get("commander",{}) as Dictionary).get("citizen_id",-1))
	var formations:Array=home_army.get("formations",[])
	for formation_index in range(formations.size()-1,-1,-1):
		if remaining<=0: break
		var formation:Dictionary=formations[formation_index]
		var member_ids:Array=(formation.get("soldier_ids",[]) as Array).duplicate()
		var removed_here:=0
		for member_index in range(member_ids.size()-1,-1,-1):
			if remaining<=0: break
			var citizen_id:=int(member_ids[member_index])
			if citizen_id==commander_id: continue
			member_ids.remove_at(member_index)
			released_ids.append(citizen_id)
			removed_here+=1; remaining-=1
		if removed_here<=0: continue
		var weapon:=String(formation.get("weapon","improvised"))
		var old_equipment:=int(formation.get("equipment",0))
		formation["count"]=maxi(0,int(formation.get("count",0))-removed_here)
		formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",formation.count))-removed_here)
		var new_equipment_required:=_equipment_required_for(String(formation.get("unit","levy")),int(formation.authorized_count))
		var gear_returned:=maxi(0,old_equipment-mini(old_equipment,new_equipment_required))
		formation["equipment"]=old_equipment-gear_returned
		formation["equipment_required"]=new_equipment_required
		var ammunition_type:=_ammunition_type_for(weapon)
		if ammunition_type!="":
			var new_ammunition_required:=_ammunition_required_for(weapon,new_equipment_required)
			var ammunition_returned:=maxi(0,int(formation.get("ammunition",0))-new_ammunition_required)
			formation["ammunition"]=int(formation.get("ammunition",0))-ammunition_returned
			formation["ammunition_required"]=new_ammunition_required
			military_consumables[ammunition_type]=int(military_consumables.get(ammunition_type,0))+ammunition_returned
		formation["soldier_ids"]=member_ids
		formations[formation_index]=formation
		military_inventory[weapon]=int(military_inventory.get(weapon,0))+gear_returned
		returned_equipment[weapon]=int(returned_equipment.get(weapon,0))+gear_returned
	var active_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	for citizen_id in released_ids:
		active_ids.erase(citizen_id)
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if citizen.is_empty(): continue
		citizen["army_status"]="civilian"
		citizen["role"]=String(citizen.get("pre_army_role",citizen.get("role","Unassigned")))
		citizen.erase("pre_army_role")
	home_army["formations"]=formations
	home_army["soldier_ids"]=active_ids
	home_army["troops"]=active_ids.size()
	if not released_ids.is_empty(): GameState.synchronize_population_allocations()
	_refresh_formation_experience()
	_refresh_readiness()
	army_changed.emit(home_army.duplicate(true))
	return {"requested":requested,"released":released_ids.size(),"citizen_ids":released_ids,"returned_equipment":returned_equipment}


func demobilize(count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before demobilizing personnel."}
	var requested:=maxi(0,count)
	if requested<=0: return {"error":"Demobilization count must be positive."}
	var released_recruits:Array[int]=[]
	while released_recruits.size()<requested and not recruit_pool.is_empty():
		var citizen_id:int=int(recruit_pool.pop_back())
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if citizen.is_empty() or not bool(citizen.get("alive",true)): continue
		citizen["army_status"]="civilian"
		citizen["role"]=String(citizen.get("pre_army_role",citizen.get("role","Unassigned")))
		citizen.erase("pre_army_role")
		released_recruits.append(citizen_id)
	var active_result:Dictionary={"released":0,"citizen_ids":[],"returned_equipment":{}}
	var remaining:=requested-released_recruits.size()
	if remaining>0 and int(home_army.get("troops",0))>0: active_result=stand_down(remaining)
	var released_ids:Array=released_recruits.duplicate()
	released_ids.append_array(active_result.get("citizen_ids",[]))
	if not released_recruits.is_empty(): GameState.synchronize_population_allocations()
	army_changed.emit(home_army.duplicate(true))
	return {
		"requested":requested,
		"released":released_ids.size(),
		"released_recruits":released_recruits.size(),
		"released_field_soldiers":int(active_result.get("released",0)),
		"citizen_ids":released_ids,
		"returned_equipment":active_result.get("returned_equipment",{})
	}


func start_training(unit:String,weapon:String,count:int)->Dictionary:
	var gate:=_training_gate(unit,weapon)
	if gate.has("error"): return gate
	var accepted:=mini(maxi(0,count),recruit_pool.size())
	if accepted<=0: return {"error":"No recruits are available for training."}
	var ids:Array[int]=[]
	for index in accepted: ids.append(recruit_pool.pop_front())
	var base_training_days:=float({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45,"siege_engineer":48,"field_artillery":60}.get(unit,21))
	var training_days:=maxf(3.0,base_training_days*(1.0-_citizen_training(ids)*0.35))
	var order_id:=next_training_order_id; next_training_order_id+=1
	training_queue.append({"id":order_id,"unit":unit,"weapon":weapon,"count":accepted,"soldier_ids":ids,"progress_days":0.0,"required_days":training_days,"injury_accumulator":0.0})
	return {"id":order_id,"accepted":accepted,"unit":unit,"weapon":weapon,"required_days":training_days}


func reinforce_formation(formation_id:int,count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before assigning reinforcements."}
	var formation_index:=_formation_index(formation_id)
	if formation_index<0: return {"error":"Formation %d was not found." % formation_id}
	var formation:Dictionary=home_army.formations[formation_index]
	var gate:=_training_gate(String(formation.unit),String(formation.weapon))
	if gate.has("error"): return gate
	var vacancies:=maxi(0,int(formation.get("authorized_count",formation.count))-int(formation.count))
	var accepted:=mini(mini(maxi(0,count),recruit_pool.size()),vacancies)
	if accepted<=0: return {"error":"The formation has no open authorized positions or no recruits are available."}
	var ids:Array[int]=[]
	for index in accepted: ids.append(recruit_pool.pop_front())
	var base_days:=float({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45,"siege_engineer":48,"field_artillery":60}.get(String(formation.unit),21))
	var order_id:=next_training_order_id; next_training_order_id+=1
	var required_days:=maxf(3.0,base_days*0.58)
	training_queue.append({"id":order_id,"mode":"reinforce","target_formation_id":formation_id,"unit":String(formation.unit),"weapon":String(formation.weapon),"count":accepted,"soldier_ids":ids,"progress_days":0.0,"required_days":required_days,"injury_accumulator":0.0})
	return {"id":order_id,"accepted":accepted,"target_formation_id":formation_id,"required_days":required_days}


func retrain_formation(formation_id:int,unit:String,weapon:String)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before retraining a formation."}
	var formation_index:=_formation_index(formation_id)
	if formation_index<0: return {"error":"Formation %d was not found." % formation_id}
	var gate:=_training_gate(unit,weapon)
	if gate.has("error"): return gate
	var formation:Dictionary=home_army.formations[formation_index]
	var commander_id:=int((home_army.get("commander",{}) as Dictionary).get("citizen_id",-1))
	if commander_id in (formation.get("soldier_ids",[]) as Array): return {"error":"Transfer field command before retraining the commander's formation."}
	var member_ids:Array=(formation.get("soldier_ids",[]) as Array).duplicate()
	if member_ids.is_empty(): return {"error":"The formation has no active members to retrain."}
	var old_weapon:=String(formation.get("weapon","improvised"))
	var returned_gear:=int(formation.get("equipment",0))
	military_inventory[old_weapon]=int(military_inventory.get(old_weapon,0))+returned_gear
	var ammunition_type:=_ammunition_type_for(old_weapon)
	var returned_ammunition:=int(formation.get("ammunition",0)) if ammunition_type!="" else 0
	if returned_ammunition>0: military_consumables[ammunition_type]=int(military_consumables.get(ammunition_type,0))+returned_ammunition
	(home_army.formations as Array).remove_at(formation_index)
	for citizen_id in member_ids:
		(home_army.soldier_ids as Array).erase(citizen_id)
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not citizen.is_empty(): citizen["army_status"]="training"
	home_army["troops"]=(home_army.soldier_ids as Array).size()
	var base_days:=float({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45,"siege_engineer":48,"field_artillery":60}.get(unit,21))
	var required_days:=maxf(3.0,base_days*(0.72-_citizen_experience(member_ids)*0.24))
	var order_id:=next_training_order_id; next_training_order_id+=1
	training_queue.append({"id":order_id,"mode":"retrain","unit":unit,"weapon":weapon,"count":member_ids.size(),"soldier_ids":member_ids,"progress_days":0.0,"required_days":required_days,"injury_accumulator":0.0})
	_refresh_readiness()
	return {"id":order_id,"accepted":member_ids.size(),"returned_equipment":returned_gear,"returned_ammunition":returned_ammunition,"required_days":required_days}


func cancel_training(order_id:int)->Dictionary:
	for index in training_queue.size():
		var order:Dictionary=training_queue[index]
		if int(order.get("id",-1))!=order_id: continue
		var returned:Array=order.get("soldier_ids",[]).duplicate()
		for citizen_id in returned:
			if int(citizen_id) not in recruit_pool: recruit_pool.append(int(citizen_id))
			var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if not citizen.is_empty(): citizen["army_status"]="recruit"
		training_queue.remove_at(index)
		return {"cancelled":true,"order_id":order_id,"returned":returned.size(),"progress_retained":float(order.get("progress_days",0.0))}
	return {"error":"Training order %d was not found." % order_id}


func queue_equipment_production(item:String,count:int)->Dictionary:
	if not simulator.WEAPONS.has(item): return {"error":"Unknown equipment type: %s" % item}
	var gate:=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE.get(item,"")),0.08)
	if not bool(gate.unlocked): return {"error":gate.reason,"required_discovery":gate.discovery}
	var amount:=maxi(0,count)
	if amount<=0: return {"error":"Production amount must be positive."}
	var recipe:Dictionary=_equipment_recipe(item)
	for material in recipe.materials:
		var required:=float(recipe.materials[material])*amount
		if float(GameState.resource_stockpiles.get(material,0.0))<required:
			return {"error":"Insufficient %s: need %.1f." % [material,required]}
	for material in recipe.materials:
		GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))-float(recipe.materials[material])*amount
	var job_id:=next_equipment_job_id; next_equipment_job_id+=1
	var reserved:Dictionary={}
	for material in recipe.materials: reserved[material]=float(recipe.materials[material])*amount
	equipment_queue.append({"id":job_id,"job_type":"production","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved})
	return {"id":job_id,"queued":amount,"item":item,"work_days":float(recipe.days)*amount}


func queue_consumable_production(item:String,count:int)->Dictionary:
	var discovery:=String({"arrows":"bow_craft","artillery_rounds":"powder_artillery"}.get(item,""))
	if discovery=="": return {"error":"Unknown military consumable: %s" % item}
	var gate:=_knowledge_gate(discovery,0.08)
	if not bool(gate.unlocked): return {"error":gate.reason,"required_discovery":gate.discovery}
	var amount:=maxi(0,count)
	if amount<=0: return {"error":"Production amount must be positive."}
	var recipe:=_consumable_recipe(item)
	for material in recipe.materials:
		var required:=float(recipe.materials[material])*amount
		if float(GameState.resource_stockpiles.get(material,0.0))<required: return {"error":"Insufficient %s: need %.1f." % [material,required]}
	for material in recipe.materials: GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))-float(recipe.materials[material])*amount
	var job_id:=next_equipment_job_id; next_equipment_job_id+=1
	var reserved:Dictionary={}
	for material in recipe.materials: reserved[material]=float(recipe.materials[material])*amount
	equipment_queue.append({"id":job_id,"job_type":"consumable","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved})
	return {"id":job_id,"queued":amount,"item":item,"work_days":float(recipe.days)*amount}


func queue_transport_cart_production(count:int)->Dictionary:
	var gate:=_knowledge_gate("joinery",0.10)
	if not bool(gate.unlocked): return {"error":gate.reason,"required_discovery":gate.discovery}
	var amount:=maxi(0,count)
	if amount<=0: return {"error":"Production amount must be positive."}
	var recipe:Dictionary=_transport_recipe()
	for material in recipe.materials:
		var required:=float(recipe.materials[material])*amount
		if float(GameState.resource_stockpiles.get(material,0.0))<required: return {"error":"Insufficient %s: need %.1f." % [material,required]}
	for material in recipe.materials: GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))-float(recipe.materials[material])*amount
	var job_id:=next_equipment_job_id; next_equipment_job_id+=1
	var reserved:Dictionary={}
	for material in recipe.materials: reserved[material]=float(recipe.materials[material])*amount
	equipment_queue.append({"id":job_id,"job_type":"transport","item":"transport_cart","count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved})
	return {"id":job_id,"queued":amount,"item":"transport_cart","work_days":float(recipe.days)*amount}


func queue_equipment_repair(item:String,count:int)->Dictionary:
	if not simulator.WEAPONS.has(item): return {"error":"Unknown equipment type: %s" % item}
	var amount:=mini(maxi(0,count),int(damaged_equipment.get(item,0)))
	if amount<=0: return {"error":"No damaged %s is available to repair." % item.replace("_"," ")}
	var recipe:Dictionary=_equipment_recipe(item)
	for material in recipe.materials:
		var required:=float(recipe.materials[material])*amount*0.18
		if float(GameState.resource_stockpiles.get(material,0.0))<required: return {"error":"Insufficient %s for repairs: need %.1f." % [material,required]}
	for material in recipe.materials: GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))-float(recipe.materials[material])*amount*0.18
	damaged_equipment[item]=int(damaged_equipment.get(item,0))-amount
	var work_per_item:=float(recipe.days)*0.38
	var job_id:=next_equipment_job_id; next_equipment_job_id+=1
	var reserved:Dictionary={}
	for material in recipe.materials: reserved[material]=float(recipe.materials[material])*amount*0.18
	equipment_queue.append({"id":job_id,"job_type":"repair","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":work_per_item,"required_days":work_per_item*amount,"reserved_materials":reserved,"reserved_damaged":amount})
	return {"id":job_id,"queued":amount,"item":item,"repair_work_days":work_per_item*amount}


func cancel_equipment_job(job_id:int)->Dictionary:
	for index in equipment_queue.size():
		var job:Dictionary=equipment_queue[index]
		if int(job.get("id",-1))!=job_id: continue
		var count:=int(job.get("count",0))
		var completed:=clampi(int(job.get("completed",0)),0,count)
		var remaining:=maxi(0,count-completed)
		var work_per_item:=maxf(0.01,float(job.get("work_per_item",1.0)))
		var fractional:=clampf(float(job.get("progress_days",0.0))/work_per_item-float(completed),0.0,1.0) if remaining>0 else 0.0
		var refundable_units:=maxf(0.0,float(remaining)-fractional*0.35)
		var refunded:Dictionary={}
		for material in (job.get("reserved_materials",{}) as Dictionary):
			var per_item:=float(job.reserved_materials[material])/maxf(1.0,float(count))
			var amount:=per_item*refundable_units
			GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))+amount
			refunded[material]=amount
		if String(job.get("job_type","production"))=="repair" and remaining>0:
			var item:=String(job.get("item","improvised"))
			damaged_equipment[item]=int(damaged_equipment.get(item,0))+remaining
		equipment_queue.remove_at(index)
		return {"cancelled":true,"job_id":job_id,"completed":completed,"unfinished":remaining,"materials_refunded":refunded,"damaged_items_returned":remaining if String(job.get("job_type","production"))=="repair" else 0}
	return {"error":"Equipment job %d was not found." % job_id}


func recruitment_capacity()->int:
	var population:=GameState.living_citizen_count()
	var share:=0.04
	if _adoption("watch_rotation")>=0.10: share=0.08
	if _adoption("public_levies")>=0.15: share=0.18
	if _adoption("professional_corps")>=0.20: share=0.30
	return maxi(1,roundi(float(population)*share))


func _mobilized_count()->int:
	return recruit_pool.size()+_queued_trainees()+training_injuries.size()+int(home_army.get("troops",0))+int(home_army.get("wounded_pool",0))+int(home_army.get("scattered_pool",0))+(home_army.get("captured_ids",[]) as Array).size()


func military_capabilities()->Dictionary:
	var units:Dictionary={}
	for unit in UNIT_KNOWLEDGE: units[unit]=_knowledge_gate(String(UNIT_KNOWLEDGE[unit]),0.10)
	var equipment:Dictionary={}
	for item in EQUIPMENT_KNOWLEDGE: equipment[item]=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE[item]),0.08)
	var queued_trainees:=_queued_trainees()
	return {"units":units,"equipment":equipment,"unit_equipment":UNIT_EQUIPMENT.duplicate(true),"transport_carts":_knowledge_gate("joinery",0.10),"progression_errors":validate_military_progression(),"recruitment_capacity":recruitment_capacity(),"training_rate":_effective_training_rate(queued_trainees),"base_training_rate":_training_rate(),"training_capacity":training_capacity(),"training_load":queued_trainees,"training_bottleneck":maxi(0,queued_trainees-training_capacity()),"production_rate":_production_rate(),"base_production_rate":_base_production_rate(),"workshop_utilization":workshop_utilization(),"civilian_crafting_fraction":civilian_crafting_fraction(),"equipment_backlog_work":_equipment_backlog_work(),"medical_recovery":_adoption("battlefield_medicine"),"logistics_practice":_adoption("supply_groups"),"staff_planning":_adoption("military_staffs"),"veteran_experience":_army_experience(),"doctrine_transfer":_army_experience()*_adoption("professional_corps")}


func validate_military_progression()->Array[String]:
	var errors:Array[String]=[]
	for gate_map in [UNIT_KNOWLEDGE,EQUIPMENT_KNOWLEDGE]:
		for gate_name in gate_map:
			var discovery:=String(gate_map[gate_name])
			if discovery in ["","__mount_population__"]: continue
			if DiscoverySystem.discovery_definition(discovery).is_empty(): errors.append("%s references missing discovery %s." % [String(gate_name),discovery])
	for unit in UNIT_EQUIPMENT:
		if not UNIT_KNOWLEDGE.has(unit): errors.append("Equipment doctrine references unknown unit %s." % String(unit))
		for item in UNIT_EQUIPMENT[unit]:
			if not EQUIPMENT_KNOWLEDGE.has(item): errors.append("%s references unknown equipment %s." % [String(unit),String(item)])
	return errors


func military_inquiry_context()->Dictionary:
	var fielded:=int(home_army.get("troops",0))
	var queued_trainees:=_queued_trainees()
	var active_military:=_mobilized_count()
	var has_threat:=not active_threat.is_empty()
	var engaged:=not active_engagement.is_empty()
	var threat_strength:=maxi(0,int(active_threat.get("estimated_strength",0)))
	if engaged:
		var enemy_force:Dictionary=active_engagement.get("defender",active_engagement.get("enemy_force",{}))
		threat_strength=maxi(threat_strength,int(enemy_force.get("troops",0)))
	var recent_combat_days:=maxi(0,int(home_army.get("recent_combat_days",0)))
	var wounded:=maxi(0,int(home_army.get("wounded_pool",0)))+training_injuries.size()
	var equipment_shortfall:=0
	var ammunition_shortfall:=0
	for formation_variant in home_army.get("formations",[]):
		var formation:Dictionary=formation_variant
		equipment_shortfall+=maxi(0,int(formation.get("equipment_required",_equipment_required_for(String(formation.get("unit","levy")),int(formation.get("authorized_count",formation.get("count",0))))))-int(formation.get("equipment",0)))
		ammunition_shortfall+=maxi(0,int(formation.get("ammunition_required",0))-int(formation.get("ammunition",0)))
	var damaged_total:=0
	for damaged_count in damaged_equipment.values(): damaged_total+=maxi(0,int(damaged_count))
	var production_backlog:=_equipment_backlog_work()
	var supply_shortfall:=0.0
	var readiness_shortfall:=0.0
	if fielded>0:
		supply_shortfall=1.0-clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
		readiness_shortfall=1.0-clampf(float(home_army.get("readiness",0.0)),0.0,1.0)
	var military_pressure:=active_military>0 or has_threat or engaged or recent_combat_days>0 or not pending_aftermath.is_empty() or production_backlog>0.0 or equipment_shortfall>0 or ammunition_shortfall>0 or damaged_total>0
	if not military_pressure: return {}
	var threat_pressure:=clampf((0.40 if has_threat else 0.0)+float(threat_strength)*0.025+(0.55 if engaged else 0.0),0.0,2.0)
	var service_pressure:=minf(1.5,float(active_military)*0.025)
	var equipment_pressure:=minf(2.0,float(equipment_shortfall)*0.045+float(ammunition_shortfall)*0.008+float(damaged_total)*0.065+production_backlog*0.012)
	var combat_pressure:=minf(1.0,float(recent_combat_days)*0.08+(0.35 if not pending_aftermath.is_empty() else 0.0))
	var injury_pressure:=minf(2.0,float(wounded)*0.10+float(recent_combat_days)*0.045)
	var threat_gap:=maxi(0,threat_strength-fielded)
	var logistics_practice:=minf(0.50,float(GameState.population_allocations.get("Logistics",0))*0.04)
	return {
		"defense":minf(3.0,0.12+service_pressure*0.45+threat_pressure*0.80+readiness_shortfall*0.55+combat_pressure*0.35),
		"danger":minf(3.0,threat_pressure+combat_pressure*0.75),
		"training":minf(2.5,float(queued_trainees)*0.08+float(threat_gap)*0.025+threat_pressure*0.25+readiness_shortfall*0.60),
		"warfare":minf(2.5,float(fielded)*0.035+threat_pressure*0.20+combat_pressure*0.70),
		"crafting":minf(2.5,float(equipment_queue.size())*0.20+equipment_pressure*0.85),
		"materials":minf(2.5,float(equipment_queue.size())*0.18+equipment_pressure*0.75),
		"logistics":minf(2.5,logistics_practice+float(fielded)*0.008+threat_pressure*0.15+supply_shortfall*1.25+(0.35 if engaged else 0.0)),
		"injury":injury_pressure
	}


func resolve_campaign_battle(enemy_force:Dictionary,options:Dictionary={})->Dictionary:
	if not active_engagement.is_empty(): return {"error":"Finish the active campaign engagement first."}
	if home_army.is_empty(): muster_home_army()
	if int(home_army.get("troops",0))<=0: return {"error":"No deployable home army."}
	_refresh_readiness()
	var battle_options:=options.duplicate(true)
	battle_options["seed"]=int(battle_options.get("seed",GameState.world_seed^int(GameState.elapsed_days+1.0)*7919))
	battle_options["terrain_defense"]=float(battle_options.get("terrain_defense",_terrain_defense()))
	var result:Dictionary=simulator.simulate(home_army,enemy_force,battle_options)
	return _commit_campaign_battle(result)


func _commit_campaign_battle(result:Dictionary)->Dictionary:
	_apply_home_result(result.attacker,result.rounds,int(result.seed))
	home_army["recent_combat_days"]=7
	home_army["supply_level"]=clampf(float(home_army.get("supply_level",1.0))-0.06,0.0,1.0)
	_apply_home_commander_fate(result.termination)
	var record:=result.duplicate(true)
	record["day"]=int(GameState.elapsed_days)
	battle_history.push_front(record)
	if battle_history.size()>40: battle_history.resize(40)
	pending_aftermath=result.get("termination",{}).duplicate(true)
	if String(pending_aftermath.get("type","continued"))=="continued": pending_aftermath.clear()
	_record_council_battle(result)
	battle_resolved.emit(result.duplicate(true))
	if not pending_aftermath.is_empty():
		aftermath_required.emit(pending_aftermath.duplicate(true))
	army_changed.emit(home_army.duplicate(true))
	return result


func resolve_aftermath(prisoner_policy:String,spoils_policy:String,general_policy:="hold")->Dictionary:
	if pending_aftermath.is_empty(): return {"error":"No campaign aftermath is awaiting a decision."}
	if prisoner_policy.to_lower() not in ["hold","release","exchange","parole","ransom","execute","enslave"]: return {"error":"Unknown prisoner policy: %s" % prisoner_policy}
	if spoils_policy.to_lower() not in ["army stores","reward troops","state treasury","return property","unrestricted plunder"]: return {"error":"Unknown spoils policy: %s" % spoils_policy}
	if general_policy.to_lower() not in ["hold","release","ransom","execute"]: return {"error":"Unknown general policy: %s" % general_policy}
	var outcome:Dictionary={"prisoner_policy":prisoner_policy,"spoils_policy":spoils_policy,"general_policy":general_policy}
	var home_won:=String(pending_aftermath.get("captor",""))==String(home_army.get("name",""))
	var prisoners:=int(pending_aftermath.get("prisoners",0))
	if home_won:
		_apply_campaign_prisoner_policy(prisoner_policy,prisoners,outcome)
		_apply_campaign_spoils_policy(spoils_policy,pending_aftermath.get("spoils",{}),outcome)
		if bool(pending_aftermath.get("captured_general",false)):
			_apply_campaign_general_policy(general_policy,pending_aftermath,outcome)
	else:
		_mark_home_prisoners(prisoners)
	outcome["day"]=int(GameState.elapsed_days)
	outcome["aftermath"]=pending_aftermath.duplicate(true)
	pending_aftermath.clear()
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Battle aftermath resolved","description":_aftermath_description(outcome),"domain":"security","severity":"notice"})
	army_changed.emit(home_army.duplicate(true))
	return outcome


func campaign_army_snapshot()->Dictionary:
	if home_army.is_empty(): home_army=_empty_home_army()
	var snapshot:=home_army.duplicate(true)
	snapshot["foreign_prisoners"]=foreign_prisoners
	snapshot["held_generals"]=held_generals.duplicate(true)
	snapshot["military_inventory"]=military_inventory.duplicate(true)
	snapshot["military_consumables"]=military_consumables.duplicate(true)
	snapshot["damaged_equipment"]=damaged_equipment.duplicate(true)
	snapshot["recruits"]=recruit_pool.size()
	snapshot["training_queue"]=training_queue.duplicate(true)
	snapshot["training_injuries"]=training_injuries.duplicate(true)
	snapshot["equipment_queue"]=equipment_queue.duplicate(true)
	snapshot["mobilization_cost"]=_mobilization_cost()
	snapshot["prisoner_custody"]=prisoner_custody_snapshot()
	snapshot["economic_burden"]=economic_burden_snapshot()
	return snapshot


func economic_burden_snapshot()->Dictionary:
	var mobilized:=_mobilized_count(); var field_soldiers:=int(home_army.get("troops",0)); var queued:=_queued_trainees(); var recruits:=recruit_pool.size()
	var provisions:=float(home_army.get("provisions_required_today",0.0))
	if int(home_army.get("provision_day",-1))<int(GameState.elapsed_days)-1: provisions=float(field_soldiers)*0.90
	var issued_equipment:=0
	for formation in home_army.get("formations",[]): issued_equipment+=int(formation.get("equipment",0))
	var stored_equipment:=0; var damaged:=0
	for item in military_inventory: stored_equipment+=int(military_inventory[item])
	for item in damaged_equipment: damaged+=int(damaged_equipment[item])
	var currency_upkeep_units:=float(field_soldiers)*0.025+float(maxi(0,mobilized-field_soldiers))*0.012+float(issued_equipment+stored_equipment)*0.001+float(foreign_prisoners)*0.006
	return {"mobilized_citizens":mobilized,"field_soldiers":field_soldiers,"recruits":recruits,"trainees":queued,"citizens_withheld_by_role":_mobilization_cost().former_roles,"daily_field_provisions":provisions,"workshop_diversion":1.0-civilian_crafting_fraction(),"equipment_backlog_work":_equipment_backlog_work(),"issued_equipment":issued_equipment,"stored_equipment":stored_equipment,"damaged_equipment":damaged,"foreign_prisoners":foreign_prisoners,"currency_upkeep_units":currency_upkeep_units}


func combat_summary(force:Dictionary={},opponent:Dictionary={},terrain_modifier:float=1.0)->Dictionary:
	var subject:=force if not force.is_empty() else ((active_engagement.get("attacker",{}) as Dictionary) if not active_engagement.is_empty() else home_army)
	var opposing:=opponent if not opponent.is_empty() else ((active_engagement.get("defender",{}) as Dictionary) if not active_engagement.is_empty() else {"formations":[]})
	var cohorts:Array[Dictionary]=simulator.evaluate_force(subject,opposing,terrain_modifier)
	var attack_strength:=0.0; var defense_strength:=0.0; var base_effective_strength:=0.0
	for cohort in cohorts:
		var count:=float(cohort.get("count",0)); attack_strength+=count*float(cohort.get("attack",0.0)); defense_strength+=count*float(cohort.get("defense",0.0)); base_effective_strength+=count*sqrt(maxf(0.0,float(cohort.get("attack",0.0))*float(cohort.get("defense",0.0))))
	var readiness_components:Dictionary=simulator.force_readiness(subject,_force_personnel_condition(subject))
	var supply:=clampf(float(subject.get("supply_level",home_army.get("supply_level",1.0))),0.0,1.0); var discipline:=clampf(float(subject.get("discipline",home_army.get("discipline",0.5))),0.0,1.0)
	readiness_components["supply"]=supply; readiness_components["discipline"]=discipline
	var calculated_readiness:=float(readiness_components.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)
	var readiness:=clampf(float(subject.get("readiness",calculated_readiness)),0.0,1.5)
	var morale:=clampf(float(subject.get("morale",1.0)),0.0,1.5)
	var commander:Dictionary=subject.get("commander",{})
	var command_factor:=0.90+clampf(float(commander.get("command",0.5)),0.0,1.0)*0.20
	var effective_strength:=base_effective_strength*maxf(CombatSimulator.MIN_EFFECTIVE_STRENGTH,morale)*readiness*command_factor
	return {"troops":int(subject.get("troops",0)),"attack_strength":attack_strength,"defense_strength":defense_strength,"base_effective_strength":base_effective_strength,"effective_strength":effective_strength,"average_attack":attack_strength/maxf(1.0,float(subject.get("troops",0))),"average_defense":defense_strength/maxf(1.0,float(subject.get("troops",0))),"readiness":readiness,"calculated_readiness":calculated_readiness,"readiness_components":readiness_components,"morale":morale,"command_factor":command_factor,"commander":commander.duplicate(true)}


func _force_personnel_condition(force:Dictionary)->float:
	var total_condition:=0.0
	var total_people:=0
	for formation in force.get("formations",[]):
		var people:=maxi(0,int(formation.get("count",0)))
		total_condition+=float(people)*clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0)
		total_people+=people
	return total_condition/maxf(1.0,float(total_people)) if total_people>0 else 1.0


func formation_combat_summaries(force:Dictionary={},opponent:Dictionary={},terrain_modifier:float=1.0)->Array[Dictionary]:
	var subject:=force if not force.is_empty() else home_army
	var opposing:=opponent if not opponent.is_empty() else {"formations":[]}
	var evaluated:Array[Dictionary]=simulator.evaluate_force(subject,opposing,terrain_modifier)
	var formations:Array=subject.get("formations",[])
	var summaries:Array[Dictionary]=[]
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var stats:Dictionary=evaluated[index] if index<evaluated.size() else {}
		var formation_readiness:=clampf(float(formation.get("readiness",subject.get("readiness",1.0))),0.0,1.5)
		var count:=int(formation.get("count",0))
		summaries.append({"id":int(formation.get("id",-1)),"attack_strength":float(stats.get("attack",0.0))*float(count)*formation_readiness,"defense_strength":float(stats.get("defense",0.0))*float(count)*formation_readiness,"readiness":formation_readiness,"condition":float(formation.get("personnel_condition",stats.get("personnel_condition",1.0))),"matchup":float(stats.get("matchup",1.0))})
	return summaries


func threat_snapshot()->Dictionary:
	return active_threat.duplicate(true)


func war_reputation_snapshot()->Dictionary:
	return war_reputation.duplicate(true)


func engagement_snapshot()->Dictionary:
	return active_engagement.duplicate(true)


func begin_threat_engagement()->Dictionary:
	if not active_engagement.is_empty(): return engagement_snapshot()
	if active_threat.is_empty(): return {"error":"No military threat is awaiting a response."}
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	if int(home_army.get("troops",0))<=0: return {"error":"No trained field formation can defend the settlement."}
	_refresh_readiness()
	var threat:=active_threat.duplicate(true)
	active_engagement={"threat":threat,"attacker":home_army.duplicate(true),"defender":threat.enemy_force.duplicate(true),"attacker_initial":int(home_army.troops),"defender_initial":int(threat.enemy_force.troops),"round":0,"rounds":[],"seed":int(threat.seed),"terrain_defense":_terrain_defense(),"status":"active","last_order":"hold"}
	active_threat.clear(); threat_changed.emit({}); army_changed.emit(home_army.duplicate(true))
	return engagement_snapshot()


func advance_engagement(order:String="hold")->Dictionary:
	if active_engagement.is_empty(): return {"error":"No campaign battle is active."}
	var command:=order.to_lower()
	if command not in ["hold","push","retreat"]: return {"error":"Unknown battle order: %s" % order}
	if command=="retreat": return _finish_active_engagement(true,{})
	var attacker:Dictionary=(active_engagement.attacker as Dictionary).duplicate(true)
	var defender:Dictionary=(active_engagement.defender as Dictionary).duplicate(true)
	var round_options:Dictionary={"seed":int(active_engagement.seed)+(int(active_engagement.round)+1)*7919,"terrain_defense":float(active_engagement.terrain_defense),"max_rounds":1}
	if command=="push":
		attacker["attack_modifier"]=float(attacker.get("attack_modifier",1.0))*1.25
		round_options["casualty_intensity"]=1.30
		round_options["attacker_exposure_modifier"]=1.12
	var next_round:=int(active_engagement.round)+1
	var result:Dictionary=simulator.simulate(attacker,defender,round_options)
	if (result.get("rounds",[]) as Array).is_empty(): return _finish_active_engagement(false,result)
	var record:Dictionary=(result.rounds[0] as Dictionary).duplicate(true); record["round"]=next_round; record["order"]=command
	(active_engagement.rounds as Array).append(record)
	active_engagement["round"]=next_round; active_engagement["attacker"]=_force_from_round_result(active_engagement.attacker,result.attacker); active_engagement["defender"]=_force_from_round_result(active_engagement.defender,result.defender); active_engagement["last_order"]=command; active_engagement["last_result"]=result.duplicate(true)
	if String(result.get("outcome","continued"))!="continued" or next_round>=CombatSimulator.MAX_ROUNDS:
		return _finish_active_engagement(false,result)
	army_changed.emit(home_army.duplicate(true))
	return {"active":true,"engagement":engagement_snapshot(),"round":record}


func _force_from_round_result(previous:Dictionary,side:Dictionary)->Dictionary:
	var updated:=previous.duplicate(true)
	for key in ["remaining_troops","morale","formations","reserve_manpower","wounded_pool","scattered_pool","dead"]:
		if not side.has(key): continue
		if key=="remaining_troops": updated["troops"]=int(side[key])
		else: updated[key]=side[key].duplicate(true) if side[key] is Array or side[key] is Dictionary else side[key]
	# Carry the army's supply/organization context forward, but let current
	# manpower, equipment, ammunition, condition, and morale change readiness.
	var prior_components:Dictionary=simulator.force_readiness(previous,_force_personnel_condition(previous))
	var current_components:Dictionary=simulator.force_readiness(updated,_force_personnel_condition(updated))
	var context_factor:=clampf(float(previous.get("readiness",prior_components.aggregate))/maxf(0.01,float(prior_components.aggregate)),0.0,1.5)
	updated["readiness"]=clampf(float(current_components.aggregate)*context_factor,0.0,1.5)
	updated["readiness_components"]=current_components
	return updated


func _finish_active_engagement(retreated:bool,last_result:Dictionary)->Dictionary:
	var engagement:=active_engagement.duplicate(true)
	var attacker:Dictionary=engagement.attacker; var defender:Dictionary=engagement.defender
	var attacker_result:Dictionary=simulator._force_result(attacker,int(engagement.attacker_initial),int(attacker.troops),float(attacker.morale))
	var defender_result:Dictionary=simulator._force_result(defender,int(engagement.defender_initial),int(defender.troops),float(defender.morale))
	var outcome:=String(last_result.get("outcome","continued")); var termination:Dictionary=(last_result.get("termination",{}) as Dictionary).duplicate(true)
	if retreated:
		outcome="attacker_retreat"
		termination={"type":"withdrawal","summary":"%s withdrew from the field before collapse." % String(attacker.name),"defeated":String(attacker.name),"captor":String(defender.name),"prisoners":0,"spoils":{},"captured_general":false,"commander_fate":"escaped"}
	elif outcome=="continued": termination={"type":"continued","summary":"Both forces remain capable of further action."}
	var final_result:Dictionary={"seed":int(engagement.seed),"outcome":outcome,"winner":String(defender.name) if retreated else String(last_result.get("winner","")),"round_count":int(engagement.round),"rounds":engagement.rounds.duplicate(true),"attacker":attacker_result,"defender":defender_result,"terrain_defense":float(engagement.terrain_defense),"effective_terrain_defense":float(last_result.get("effective_terrain_defense",engagement.terrain_defense)),"termination":termination,"orders":{"retreated":retreated}}
	active_engagement.clear(); threats_resolved+=1
	return _commit_campaign_battle(final_result)


func respond_to_threat(response:String)->Dictionary:
	if active_threat.is_empty(): return {"error":"No military threat is awaiting a response."}
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	var choice:=response.to_lower()
	var threat:=active_threat.duplicate(true)
	if choice=="defend":
		return begin_threat_engagement()
	if choice=="tribute":
		var demanded:=float(threat.get("tribute_food",0.0)); var available:=float(GameState.resource_stockpiles.get("Food",0.0))
		if available<demanded: return {"error":"The demanded tribute requires %.1f Food; only %.1f is stored." % [demanded,available]}
		GameState.resource_stockpiles["Food"]=available-demanded
		GameState.simulation_metrics["security"]=clampf(float(GameState.simulation_metrics.get("security",0.38))-0.035,0.0,1.0)
		_resolve_threat_without_battle("Tribute paid","The settlement surrendered %.1f Food to avoid battle." % demanded)
		return {"resolved":true,"response":choice,"food_paid":demanded}
	if choice=="withdraw":
		var losses:Dictionary={}
		for resource_name in ["Food","Timber","Stone","Fiber Plants"]:
			var amount:=float(GameState.resource_stockpiles.get(resource_name,0.0))*float(threat.get("plunder_fraction",0.12))
			GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-amount); losses[resource_name]=amount
		_resolve_threat_without_battle("Settlement yields ground","The population avoided battle, but the hostile force stripped exposed stores.")
		return {"resolved":true,"response":choice,"resources_lost":losses}
	return {"error":"Unknown threat response: %s" % response}


func _resolve_threat_without_battle(title:String,description:String)->void:
	active_threat.clear(); threats_resolved+=1; threat_changed.emit({})
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":title,"description":description,"domain":"security","severity":"warning"})


func _process_threat_day()->void:
	if not active_engagement.is_empty():
		advance_engagement("hold")
		return
	if not active_threat.is_empty():
		if int(GameState.elapsed_days)>int(active_threat.get("deadline_day",GameState.elapsed_days)) and pending_aftermath.is_empty():
			respond_to_threat("defend" if int(home_army.get("troops",0))>0 else "withdraw")
			while not active_engagement.is_empty(): advance_engagement("hold")
		return
	if not GameState.settlement_site_committed or int(GameState.elapsed_days)<90 or not pending_aftermath.is_empty(): return
	var population:=maxi(1,GameState.living_citizen_count()); var security:=clampf(float(GameState.simulation_metrics.get("security",0.38)),0.0,1.0)
	var stored_value:=float(GameState.resource_stockpiles.get("Food",0.0))+float(GameState.resource_stockpiles.get("Timber",0.0))*0.5+float(GameState.resource_stockpiles.get("Copper Ore",0.0))*3.0
	var daily_risk:=clampf(0.00010+(1.0-security)*0.00045+minf(0.00035,stored_value/maxf(1.0,float(population))*0.000004)+float(war_reputation.get("grievance",0.0))*0.00020-float(war_reputation.get("mercy",0.0))*0.00005,0.00005,0.0012)
	var rng:=RandomNumberGenerator.new(); rng.seed=GameState.world_seed^int(GameState.elapsed_days)*104729^threats_resolved*7919
	if rng.randf()>=daily_risk: return
	var strength:=clampi(roundi(float(population)*rng.randf_range(0.045,0.11)),3,maxi(3,roundi(float(population)*0.16)))
	var enemy_formations:Array[Dictionary]=[]
	if int(GameState.elapsed_days)>=2400:
		var archers:=roundi(float(strength)*0.28); var line:=roundi(float(strength)*0.38); var levy:=strength-archers-line
		enemy_formations=[{"unit":"levy","weapon":"improvised","count":levy,"equipment":levy},{"unit":"line_infantry","weapon":"spear","count":line,"equipment":line},{"unit":"skirmisher","weapon":"bow","count":archers,"equipment":archers,"ammunition":archers*6}]
	elif int(GameState.elapsed_days)>=700:
		var line:=roundi(float(strength)*0.42); enemy_formations=[{"unit":"levy","weapon":"improvised","count":strength-line,"equipment":strength-line},{"unit":"line_infantry","weapon":"spear","count":line,"equipment":line}]
	else: enemy_formations=[{"unit":"levy","weapon":"improvised","count":strength,"equipment":strength}]
	var enemy_morale:=clampf(0.48+security*0.18+float(war_reputation.get("grievance",0.0))*0.12-float(war_reputation.get("fear",0.0))*0.10,0.32,0.88)
	var enemy:Dictionary=simulator.create_formation_force("Border Raiders",enemy_formations,enemy_morale,clampf(0.52+float(GameState.elapsed_days)/30000.0,0.50,0.78))
	enemy["commander"]=simulator.create_commander("Raid captain",rng.randf_range(0.32,0.62),rng.randf_range(0.34,0.66),rng.randf_range(0.24,0.55),rng.randf_range(0.38,0.68))
	active_threat={"id":"threat_%d_%d" % [int(GameState.elapsed_days),threats_resolved],"title":"Hostile force approaching","discovered_day":int(GameState.elapsed_days),"deadline_day":int(GameState.elapsed_days)+7,"enemy_force":enemy,"estimated_strength":strength,"tribute_food":maxf(5.0,float(strength)*2.5),"plunder_fraction":rng.randf_range(0.08,0.18),"seed":rng.randi()}
	GameState.council_inbox.push_front({"id":String(active_threat.id),"advisor":"Marshal","office":"Marshal","topic":"security","act":{"type":"report"},"text":"Scouts report roughly %d hostile fighters approaching. A response is required within seven days." % strength,"urgency":0.96,"day":int(GameState.elapsed_days),"status":"unread"})
	threat_changed.emit(active_threat.duplicate(true))


func prisoner_food_demand()->float:
	return float(foreign_prisoners)*0.65+float(held_generals.size())


func field_provision_delivery_ratio()->float:
	var troops:=int(home_army.get("troops",0))
	if troops<=0: return 1.0
	var workers:=float(GameState.population_allocations.get("Logistics",0))
	var labor_coverage:=clampf(workers/maxf(1.0,float(troops)*0.09),0.0,1.0)
	var commander_logistics:=clampf(float((home_army.get("commander",{}) as Dictionary).get("logistics",0.4)),0.0,1.0)
	var carts:=float(GameState.resource_stockpiles.get("Transport Carts",0.0))
	var cart_coverage:=clampf(carts/maxf(1.0,float(troops)/24.0),0.0,1.0)
	return clampf(0.08+labor_coverage*0.42+commander_logistics*0.20+_adoption("supply_groups")*0.20+cart_coverage*0.10,0.0,1.0)


func record_daily_provisions(required:float,delivered:float)->void:
	if home_army.is_empty(): return
	var need:=maxf(0.0,required)
	var received:=clampf(delivered,0.0,need)
	home_army["provisions_required_today"]=need
	home_army["provisions_delivered_today"]=received
	home_army["provision_ratio"]=received/maxf(0.01,need) if need>0.0 else 1.0
	home_army["provision_day"]=int(GameState.elapsed_days)
	var shortfall:=maxf(0.0,need-received)
	home_army["provision_shortfall_total"]=float(home_army.get("provision_shortfall_total",0.0))+shortfall
	home_army["provision_shortfall_days"]=int(home_army.get("provision_shortfall_days",0))+1 if shortfall>0.01 else 0
	var ratio:=float(home_army.provision_ratio)
	for citizen_id in home_army.get("soldier_ids",[]):
		var soldier:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if soldier.is_empty() or not bool(soldier.get("alive",true)): continue
		var current_nutrition:=clampf(float(soldier.get("nutrition_condition",GameState.food_security)),0.0,1.0)
		var nutrition_step:=0.040 if ratio<current_nutrition else 0.014
		soldier["nutrition_condition"]=move_toward(current_nutrition,ratio,nutrition_step)
		if int(home_army.provision_shortfall_days)>=5 and float(soldier.nutrition_condition)<0.38:
			soldier["health_condition"]=clampf(float(soldier.get("health_condition",GameState.population_health))-0.004*(1.0-ratio),0.05,1.0)


func prisoner_custody_snapshot()->Dictionary:
	var guards:=float(GameState.population_allocations.get("Defense",0))*0.18
	var coverage:=clampf(guards/maxf(1.0,float(foreign_prisoners)+float(held_generals.size())*2.0),0.0,1.0)
	return {"prisoners":foreign_prisoners,"held_generals":held_generals.size(),"custody_days":prisoner_custody_days,"guard_coverage":coverage,"food_demand":prisoner_food_demand(),"escape_risk":maxf(0.0,1.0-coverage),"escaped_total":escaped_prisoners_total}


func exchange_prisoners(count:int)->Dictionary:
	var exchanges:=mini(maxi(0,count),mini(foreign_prisoners,(home_army.get("captured_ids",[]) as Array).size()))
	if exchanges<=0: return {"error":"No matched prisoners are available for exchange."}
	foreign_prisoners-=exchanges
	var returned_ids:=_return_home_captives(exchanges)
	return {"exchanged":returned_ids.size(),"returned_citizen_ids":returned_ids,"foreign_prisoners":foreign_prisoners}


func resolve_held_prisoners(policy:String,count:int)->Dictionary:
	var normalized:=policy.to_lower()
	if normalized not in ["release","exchange","parole","ransom","execute","enslave"]: return {"error":"Unknown held-prisoner policy: %s" % policy}
	var amount:=mini(maxi(0,count),foreign_prisoners)
	if amount<=0: return {"error":"No held prisoners are available for disposition."}
	if normalized=="exchange": return exchange_prisoners(amount)
	foreign_prisoners-=amount
	var outcome:Dictionary={"prisoner_policy":normalized,"disposed":amount}
	_apply_campaign_prisoner_policy(normalized,amount,outcome)
	outcome["foreign_prisoners"]=foreign_prisoners
	return outcome


func resolve_held_general(index:int,policy:String)->Dictionary:
	var normalized:=policy.to_lower()
	if normalized not in ["release","ransom","execute"]: return {"error":"Unknown held-general policy: %s" % policy}
	if index<0 or index>=held_generals.size(): return {"error":"Held general %d was not found." % index}
	var general:Dictionary=held_generals.pop_at(index)
	var outcome:Dictionary={"general":general.duplicate(true),"general_policy":normalized}
	if normalized=="ransom":
		outcome["war_wealth_receipt"]=_receive_war_wealth(50.0,"state treasury","Ransom for held commander")
		outcome["ransom_income"]=50
	elif normalized=="release":
		GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.01,0.0,1.0)
	else:
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.025,0.0,1.0)
		outcome["executed"]=true
	return outcome


func resolve_held_captives(prisoner_policy:String,general_policy:String)->Dictionary:
	var normalized_prisoners:=prisoner_policy.to_lower()
	var normalized_generals:=general_policy.to_lower()
	if normalized_prisoners not in ["hold","release","exchange","parole","ransom","execute","enslave"]: return {"error":"Unknown held-prisoner policy: %s" % prisoner_policy}
	if normalized_generals not in ["hold","release","ransom","execute"]: return {"error":"Unknown held-general policy: %s" % general_policy}
	var prisoners_before:=foreign_prisoners
	var generals_before:=held_generals.size()
	if prisoners_before<=0 and generals_before<=0: return {"error":"No foreign captives are being held."}
	if normalized_prisoners=="exchange" and prisoners_before>0 and (home_army.get("captured_ids",[]) as Array).is_empty(): return {"error":"No home captives are available for a prisoner exchange."}
	var prisoner_result:Dictionary={}
	if normalized_prisoners!="hold" and prisoners_before>0:
		prisoner_result=resolve_held_prisoners(normalized_prisoners,prisoners_before)
		if prisoner_result.has("error"): return prisoner_result
	var general_results:Array[Dictionary]=[]
	if normalized_generals!="hold":
		while not held_generals.is_empty(): general_results.append(resolve_held_general(0,normalized_generals))
	var prisoners_resolved:=prisoners_before-foreign_prisoners
	var generals_resolved:=generals_before-held_generals.size()
	var message:="Captives remain in custody."
	if prisoners_resolved>0 or generals_resolved>0:
		message="Resolved %d prisoner%s and %d commander%s." % [prisoners_resolved,"" if prisoners_resolved==1 else "s",generals_resolved,"" if generals_resolved==1 else "s"]
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Captive policy enacted","description":message,"domain":"security","severity":"notice"})
	return {"message":message,"prisoner_policy":normalized_prisoners,"general_policy":normalized_generals,"prisoners_resolved":prisoners_resolved,"generals_resolved":generals_resolved,"prisoner_result":prisoner_result,"general_results":general_results,"foreign_prisoners":foreign_prisoners,"held_generals":held_generals.size()}


func _mobilization_cost()->Dictionary:
	var by_role:Dictionary={}
	var total:=0
	for citizen in GameState.living_citizens():
		var status:=String(citizen.get("army_status","civilian"))
		if status in ["civilian","","deserter"]: continue
		var former_role:=String(citizen.get("pre_army_role","Unassigned"))
		by_role[former_role]=int(by_role.get(former_role,0))+1
		total+=1
	return {"citizens_withheld":total,"former_roles":by_role,"defense_allocation":int(GameState.population_allocations.get("Defense",0))}


func export_state()->Dictionary:
	return {
		"version":SAVE_VERSION,
		"world_seed":GameState.world_seed,
		"last_processed_day":last_processed_day,
		"home_army":home_army.duplicate(true),
		"battle_history":battle_history.duplicate(true),
		"pending_aftermath":pending_aftermath.duplicate(true),
		"military_inventory":military_inventory.duplicate(true),
		"military_consumables":military_consumables.duplicate(true),
		"damaged_equipment":damaged_equipment.duplicate(true),
		"recruit_pool":recruit_pool.duplicate(),
		"training_queue":training_queue.duplicate(true),
		"training_injuries":training_injuries.duplicate(true),
		"equipment_queue":equipment_queue.duplicate(true),
		"foreign_prisoners":foreign_prisoners,
		"held_generals":held_generals.duplicate(true),
		"next_training_order_id":next_training_order_id,
		"next_formation_id":next_formation_id,
		"next_equipment_job_id":next_equipment_job_id,
		"prisoner_custody_days":prisoner_custody_days,
		"prisoner_escape_accumulator":prisoner_escape_accumulator,
		"escaped_prisoners_total":escaped_prisoners_total,
		"active_threat":active_threat.duplicate(true),
		"threats_resolved":threats_resolved,
		"active_engagement":active_engagement.duplicate(true),
		"war_reputation":war_reputation.duplicate(true)
	}


func import_state(payload:Dictionary)->Dictionary:
	var incoming:=payload.duplicate(true)
	var incoming_version:=int(incoming.get("version",-1))
	if incoming_version==1: incoming=_migrate_v1_state(incoming)
	elif incoming_version!=SAVE_VERSION: return {"error":"Unsupported military save version."}
	if int(incoming.get("world_seed",GameState.world_seed))!=GameState.world_seed: return {"error":"Military save belongs to a different world."}
	var previous:=export_state()
	_apply_imported_state(incoming)
	var errors:=validate_state()
	if not errors.is_empty():
		_apply_imported_state(previous)
		return {"error":"Invalid military save state.","details":errors}
	last_world_seed=GameState.world_seed
	return {"ok":true,"version":SAVE_VERSION}


func _migrate_v1_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	var army:Dictionary=migrated.get("home_army",{})
	var formation_id:=1
	for formation in army.get("formations",[]):
		formation["id"]=formation_id; formation_id+=1
		formation["experience"]=_citizen_experience(formation.get("soldier_ids",[]))
	army["supply_level"]=float(army.get("supply_level",1.0))
	army["supply_components"]=army.get("supply_components",{"nutrition":1.0,"delivery":1.0,"target":1.0})
	migrated["home_army"]=army
	var order_id:=1
	for order in migrated.get("training_queue",[]):
		order["id"]=int(order.get("id",order_id)); order_id=maxi(order_id+1,int(order.id)+1)
		order["injury_accumulator"]=float(order.get("injury_accumulator",0.0))
	migrated["training_injuries"]=migrated.get("training_injuries",[])
	migrated["damaged_equipment"]=migrated.get("damaged_equipment",{})
	migrated["next_training_order_id"]=order_id
	migrated["next_formation_id"]=formation_id
	migrated["version"]=SAVE_VERSION
	return migrated


func validate_state()->Array[String]:
	var errors:Array[String]=[]
	var active_ids:Array=home_army.get("soldier_ids",[])
	var formations:Array=home_army.get("formations",[])
	var formation_total:=0
	var formation_ids:Dictionary={}
	var formation_roster:Dictionary={}
	for formation in formations:
		var count:=int(formation.get("count",0)); formation_total+=count
		if count<0 or int(formation.get("equipment",0))<0: errors.append("Formation has a negative personnel or equipment count.")
		var ammunition:=int(formation.get("ammunition",0)); var ammunition_required:=int(formation.get("ammunition_required",0))
		if ammunition<0 or ammunition_required<0 or ammunition>ammunition_required: errors.append("Formation ammunition is outside its authorized capacity.")
		var formation_members:Array=formation.get("soldier_ids",[])
		if formation_members.size()!=count: errors.append("Formation headcount does not equal its citizen IDs.")
		for citizen_id in formation_members:
			if formation_roster.has(int(citizen_id)): errors.append("Citizen %d appears in more than one formation." % int(citizen_id))
			formation_roster[int(citizen_id)]=true
		if absf(float(formation.get("experience",0.0))-_citizen_experience(formation.get("soldier_ids",[])))>0.001: errors.append("Formation experience does not match its citizen roster.")
		var formation_id:=int(formation.get("id",-1))
		if formation_id<=0 or formation_ids.has(formation_id): errors.append("Formation IDs must be positive and unique.")
		formation_ids[formation_id]=true
	if formation_total!=int(home_army.get("troops",0)): errors.append("Formation manpower does not equal army troop total.")
	if active_ids.size()!=int(home_army.get("troops",0)): errors.append("Active citizen IDs do not equal army troop total.")
	if formation_roster.size()!=active_ids.size(): errors.append("Formation roster does not equal the active army roster.")
	for citizen_id in active_ids:
		if not formation_roster.has(int(citizen_id)): errors.append("Active citizen %d is not assigned to a formation." % int(citizen_id))
	if (home_army.get("wounded_ids",[]) as Array).size()!=int(home_army.get("wounded_pool",0)): errors.append("Wounded citizen IDs do not equal wounded pool.")
	if (home_army.get("scattered_ids",[]) as Array).size()!=int(home_army.get("scattered_pool",0)): errors.append("Scattered citizen IDs do not equal scattered pool.")
	var seen:Dictionary={}
	for pool in [active_ids,home_army.get("wounded_ids",[]),home_army.get("scattered_ids",[]),home_army.get("captured_ids",[]),recruit_pool]:
		for citizen_id in pool:
			if seen.has(int(citizen_id)): errors.append("Citizen %d appears in more than one military pool." % int(citizen_id))
			seen[int(citizen_id)]=true
			var pooled_citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if pooled_citizen.is_empty(): errors.append("Military pool references missing citizen %d." % int(citizen_id))
			elif not bool(pooled_citizen.get("alive",true)): errors.append("Military pool references deceased citizen %d." % int(citizen_id))
	for training in training_queue:
		var trainee_ids:Array=training.get("soldier_ids",[])
		if trainee_ids.size()!=int(training.get("count",0)): errors.append("Training order headcount does not equal its citizen IDs.")
		for citizen_id in trainee_ids:
			if seen.has(int(citizen_id)): errors.append("Citizen %d appears in more than one military pool." % int(citizen_id))
			seen[int(citizen_id)]=true
			var trainee:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if trainee.is_empty(): errors.append("Training order references missing citizen %d." % int(citizen_id))
			elif not bool(trainee.get("alive",true)): errors.append("Training order references deceased citizen %d." % int(citizen_id))
	for injury in training_injuries:
		var citizen_id:=int(injury.get("citizen_id",-1))
		if seen.has(citizen_id): errors.append("Citizen %d appears in more than one military pool." % citizen_id)
		seen[citizen_id]=true
		var injured_citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if injured_citizen.is_empty(): errors.append("Training injury references missing citizen %d." % citizen_id)
		elif not bool(injured_citizen.get("alive",true)): errors.append("Training injury references deceased citizen %d." % citizen_id)
	for item in military_inventory:
		if int(military_inventory[item])<0: errors.append("Military inventory for %s is negative." % item)
	for item in military_consumables:
		if int(military_consumables[item])<0: errors.append("Military consumables for %s are negative." % item)
	for item in damaged_equipment:
		if int(damaged_equipment[item])<0: errors.append("Damaged-equipment inventory for %s is negative." % item)
	if foreign_prisoners<0 or prisoner_custody_days<0 or escaped_prisoners_total<0: errors.append("Prisoner custody counters cannot be negative.")
	if not active_threat.is_empty() and not active_engagement.is_empty(): errors.append("A pending threat and active engagement cannot coexist.")
	if not active_engagement.is_empty():
		if int(active_engagement.get("round",-1))<0 or int(active_engagement.get("round",0))>CombatSimulator.MAX_ROUNDS: errors.append("Active engagement round is outside battle limits.")
		if (active_engagement.get("attacker",{}) as Dictionary).is_empty() or (active_engagement.get("defender",{}) as Dictionary).is_empty(): errors.append("Active engagement is missing a force.")
	var equipment_job_ids:Dictionary={}
	for job in equipment_queue:
		var job_id:=int(job.get("id",-1))
		if job_id<=0 or equipment_job_ids.has(job_id): errors.append("Equipment job IDs must be positive and unique.")
		equipment_job_ids[job_id]=true
		if int(job.get("completed",0))<0 or int(job.get("completed",0))>int(job.get("count",0)): errors.append("Equipment job completion is outside its order size.")
	return errors


func _apply_imported_state(payload:Dictionary)->void:
	last_processed_day=int(payload.get("last_processed_day",int(GameState.elapsed_days)))
	home_army=(payload.get("home_army",{}) as Dictionary).duplicate(true)
	_normalize_formation_ammunition()
	battle_history.assign(payload.get("battle_history",[]))
	pending_aftermath=(payload.get("pending_aftermath",{}) as Dictionary).duplicate(true)
	military_inventory={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
	for item in (payload.get("military_inventory",{}) as Dictionary): military_inventory[item]=int(payload.military_inventory[item])
	military_consumables={"arrows":0,"artillery_rounds":0}
	for item in (payload.get("military_consumables",{}) as Dictionary): military_consumables[item]=int(payload.military_consumables[item])
	damaged_equipment={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0,"siege_kit":0,"field_gun":0}
	for item in (payload.get("damaged_equipment",{}) as Dictionary): damaged_equipment[item]=int(payload.damaged_equipment[item])
	recruit_pool.assign(payload.get("recruit_pool",[]))
	training_queue.assign(payload.get("training_queue",[]))
	training_injuries.assign(payload.get("training_injuries",[]))
	equipment_queue.assign(payload.get("equipment_queue",[]))
	_normalize_equipment_jobs()
	foreign_prisoners=maxi(0,int(payload.get("foreign_prisoners",0)))
	held_generals.assign(payload.get("held_generals",[]))
	next_training_order_id=int(payload.get("next_training_order_id",_next_available_training_order_id()))
	next_formation_id=int(payload.get("next_formation_id",_next_available_formation_id()))
	next_equipment_job_id=int(payload.get("next_equipment_job_id",_next_available_equipment_job_id()))
	next_equipment_job_id=maxi(next_equipment_job_id,_next_available_equipment_job_id())
	prisoner_custody_days=maxi(0,int(payload.get("prisoner_custody_days",0)))
	prisoner_escape_accumulator=maxf(0.0,float(payload.get("prisoner_escape_accumulator",0.0)))
	escaped_prisoners_total=maxi(0,int(payload.get("escaped_prisoners_total",0)))
	active_threat=(payload.get("active_threat",{}) as Dictionary).duplicate(true)
	threats_resolved=maxi(0,int(payload.get("threats_resolved",0)))
	active_engagement=(payload.get("active_engagement",{}) as Dictionary).duplicate(true)
	war_reputation={"mercy":0.0,"fear":0.0,"grievance":0.0}
	for key in (payload.get("war_reputation",{}) as Dictionary): war_reputation[key]=clampf(float(payload.war_reputation[key]),0.0,1.0)


func _empty_home_army()->Dictionary:
	var force:Dictionary=simulator.create_formation_force(_home_army_name(),[],_campaign_morale(),0.0)
	force["commander"]=_marshal_commander()
	force["soldier_ids"]=[]
	force["wounded_ids"]=[]
	force["scattered_ids"]=[]
	force["captured_ids"]=[]
	force["reserve_manpower"]=0
	force["supply_level"]=1.0
	force["supply_components"]={"nutrition":1.0,"delivery":1.0,"target":1.0}
	force["provisions_required_today"]=0.0
	force["provisions_delivered_today"]=0.0
	force["provision_ratio"]=1.0
	force["provision_day"]=-1
	force["provision_shortfall_total"]=0.0
	force["provision_shortfall_days"]=0
	force["recent_combat_days"]=0
	force["service_days"]=0
	force["service_strain"]=0.0
	force["discipline"]=0.5
	force["desertion_pressure"]=0.0
	force["desertion_accumulator"]=0.0
	force["desertions_total"]=0
	force["campaign_day"]=int(GameState.elapsed_days)
	return force


func _queued_trainees()->int:
	var total:=0
	for entry in training_queue: total+=int(entry.get("count",0))
	return total


func _next_available_training_order_id()->int:
	var highest:=0
	for order in training_queue: highest=maxi(highest,int(order.get("id",0)))
	return highest+1


func _next_available_formation_id()->int:
	var highest:=0
	for formation in home_army.get("formations",[]): highest=maxi(highest,int(formation.get("id",0)))
	return highest+1


func _next_available_equipment_job_id()->int:
	var highest:=0
	for job in equipment_queue: highest=maxi(highest,int(job.get("id",0)))
	return highest+1


func _normalize_equipment_jobs()->void:
	var fallback_id:=1
	for index in equipment_queue.size():
		var job:Dictionary=equipment_queue[index]
		if int(job.get("id",0))<=0: job["id"]=fallback_id
		fallback_id=maxi(fallback_id+1,int(job.id)+1)
		if not job.has("job_type"): job["job_type"]="production"
		if not job.has("reserved_materials"):
			var job_type:=String(job.get("job_type","production"))
			var recipe:Dictionary
			if job_type=="consumable": recipe=_consumable_recipe(String(job.get("item","arrows")))
			elif job_type=="transport": recipe=_transport_recipe()
			else: recipe=_equipment_recipe(String(job.get("item","improvised")))
			var factor:=0.18 if String(job.job_type)=="repair" else 1.0
			var reserved:Dictionary={}
			for material in recipe.materials: reserved[material]=float(recipe.materials[material])*int(job.get("count",0))*factor
			job["reserved_materials"]=reserved
		equipment_queue[index]=job


func _normalize_formation_ammunition()->void:
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var weapon:=String(formation.get("weapon","improvised"))
		if _ammunition_type_for(weapon)!="":
			var default_equipment_required:=_equipment_required_for(String(formation.get("unit","levy")),int(formation.get("authorized_count",formation.get("count",0))))
			var equipment_required:=maxi(0,int(formation.get("equipment_required",default_equipment_required)))
			formation["equipment_required"]=equipment_required
			var required:=maxi(0,int(formation.get("ammunition_required",_ammunition_required_for(weapon,equipment_required))))
			formation["ammunition_required"]=required
			formation["ammunition"]=clampi(int(formation.get("ammunition",required)),0,required)
		else:
			formation["ammunition_required"]=0
			formation["ammunition"]=0
		formations[index]=formation
	home_army["formations"]=formations


func _formation_index(formation_id:int)->int:
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		if int(formations[index].get("id",-1))==formation_id: return index
	return -1


func _training_gate(unit:String,weapon:String)->Dictionary:
	if not simulator.UNIT_TYPES.has(unit): return {"error":"Unknown unit type: %s" % unit}
	if not simulator.WEAPONS.has(weapon): return {"error":"Unknown weapon type: %s" % weapon}
	var unit_gate:=_knowledge_gate(String(UNIT_KNOWLEDGE.get(unit,"")),0.10)
	if not bool(unit_gate.unlocked): return {"error":unit_gate.reason,"required_discovery":unit_gate.discovery}
	var weapon_gate:=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE.get(weapon,"")),0.10)
	if not bool(weapon_gate.unlocked): return {"error":weapon_gate.reason,"required_discovery":weapon_gate.discovery}
	if weapon not in (UNIT_EQUIPMENT.get(unit,[]) as Array): return {"error":"%s cannot be trained with %s." % [unit.replace("_"," ").capitalize(),weapon.replace("_"," ").capitalize()],"compatible_equipment":UNIT_EQUIPMENT.get(unit,[])}
	return {}


func _formations_for_strength(total:int)->Array[Dictionary]:
	var line_unlocked:=bool(_knowledge_gate("shield_wall",0.10).unlocked) and bool(_knowledge_gate("hafted_weapons",0.08).unlocked)
	var skirmish_unlocked:=bool(_knowledge_gate("bow_craft",0.10).unlocked)
	var line_share:=0.42 if line_unlocked else 0.0
	var skirmish_share:=0.24 if skirmish_unlocked else 0.0
	var line:=roundi(float(total)*line_share)
	var skirmish:=roundi(float(total)*skirmish_share)
	var levy:=maxi(0,total-line-skirmish)
	var line_weapon:="spear" if line_unlocked else "improvised"
	var bow_weapon:="bow" if skirmish_unlocked else "improvised"
	return [
		{"unit":"levy","weapon":"improvised","count":levy,"authorized_count":levy,"equipment":levy,"equipment_required":levy},
		{"unit":"line_infantry","weapon":line_weapon,"count":line,"authorized_count":line,"equipment":line,"equipment_required":line},
		{"unit":"skirmisher","weapon":bow_weapon,"count":skirmish,"authorized_count":skirmish,"equipment":skirmish,"equipment_required":skirmish}
	]


func _marshal_commander()->Dictionary:
	var marshal:Dictionary=GameState.leadership_positions.get("Marshal",{})
	var security:=float(GameState.society_capacities.get("security",0.38))
	var logistics:=float(GameState.society_capacities.get("logistics",0.16))
	if marshal.is_empty(): return _acting_field_commander(false)
	var skills:Dictionary=marshal.get("skills",{})
	var personality_command:=clampf(0.34+float(marshal.get("courage",0.5))*0.34+security*0.24,0.0,1.0)
	var personality_tactics:=clampf(0.30+float(marshal.get("suspicion",0.5))*0.24+security*0.30,0.0,1.0)
	var personality_logistics:=clampf(0.25+float(marshal.get("honesty",0.5))*0.18+logistics*0.48,0.0,1.0)
	var personality_resolve:=clampf(0.30+float(marshal.get("courage",0.5))*0.42+float(marshal.get("pride",0.5))*0.12,0.0,1.0)
	var command:=personality_command
	var tactics:=personality_tactics
	var supply_command:=personality_logistics
	var resolve:=personality_resolve
	if skills.has("Command") or skills.has("Strategy"):
		command=lerpf(personality_command,clampf(float(skills.get("Command",skills.get("Strategy",50)))/100.0,0.0,1.0),0.68)
	if skills.has("Tactics"):
		tactics=lerpf(personality_tactics,clampf(float(skills.Tactics)/100.0,0.0,1.0),0.72)
	if skills.has("Logistics"):
		supply_command=lerpf(personality_logistics,clampf(float(skills.Logistics)/100.0,0.0,1.0),0.72)
	if skills.has("Resolve"):
		resolve=lerpf(personality_resolve,clampf(float(skills.Resolve)/100.0,0.0,1.0),0.68)
	var commander:Dictionary=simulator.create_commander(
		String(marshal.get("name","Marshal")),
		command,
		tactics,
		supply_command,
		resolve
	)
	commander["citizen_id"]=int(marshal.get("citizen_id",-1))
	commander["office"]="Marshal"
	return commander


func _apply_home_commander_fate(termination:Dictionary)->void:
	if String(termination.get("defeated",""))!=String(home_army.get("name","")): return
	var fate:=String(termination.get("commander_fate","escaped"))
	if fate not in ["killed","captured"]: return
	var former:Dictionary=home_army.get("commander",{})
	var citizen_id:=int(former.get("citizen_id",-1))
	var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
	var was_active:=_remove_active_citizen(citizen_id)
	if not citizen.is_empty():
		if fate=="killed":
			var commander_name:=GameState.register_specific_death(citizen_id,"Killed while commanding in battle")
			if commander_name!="": _record_military_deaths([commander_name],"Killed while commanding in battle")
		else:
			citizen["pre_capture_role"]=String(citizen.get("role","Unassigned"))
			citizen["military_capture_kind"]="commander"
			citizen["capture_was_active_soldier"]=was_active
			citizen["army_status"]="captured"
			var captured_ids:Array=home_army.get("captured_ids",[]).duplicate()
			if citizen_id not in captured_ids: captured_ids.append(citizen_id)
			home_army["captured_ids"]=captured_ids
			GameState.synchronize_population_allocations()
	var marshal:Dictionary=GameState.leadership_positions.get("Marshal",{})
	if int(marshal.get("citizen_id",-2))==citizen_id: GameState.leadership_positions.erase("Marshal")
	var successor:=_acting_field_commander(true)
	home_army["commander"]=successor
	GameState.council_inbox.push_front({"id":"succession_%d_%d" % [int(GameState.elapsed_days),citizen_id],"advisor":String(successor.get("name","Field command")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":"%s is %s. %s assumes field command with reduced experience." % [String(former.get("name","The commander")),fate,String(successor.get("name","An acting captain"))],"urgency":0.98,"day":int(GameState.elapsed_days),"status":"unread"})


func _record_military_deaths(names:Array[String],cause:String)->void:
	if names.is_empty(): return
	GameState.lifetime_deaths+=names.size()
	var location:=GameState.settlement_name if GameState.settlement_name!="" else "the campaign"
	var record:Dictionary={"id":"military_deaths_%d_%d" % [int(GameState.elapsed_days),GameState.demographic_ledger.size()],"day":int(GameState.elapsed_days),"start_day":int(GameState.elapsed_days),"end_day":int(GameState.elapsed_days),"title":"%d military death%s near %s" % [names.size(),"" if names.size()==1 else "s",location],"description":"Named citizens killed during military service: %s." % ", ".join(names),"domain":"population","severity":"demographic","kind":"death","count":names.size(),"cause":cause,"location":location,"population_after":GameState.population_total,"people":names.duplicate()}
	GameState.demographic_ledger.push_front(record)
	if GameState.demographic_ledger.size()>120: GameState.demographic_ledger.resize(120)
	GameState.simulation_events.push_front(record)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)


func _acting_field_commander(assign_office:bool)->Dictionary:
	var excluded:Dictionary={}
	for office in GameState.leadership_positions:
		excluded[int((GameState.leadership_positions[office] as Dictionary).get("citizen_id",-1))]=true
	var best:Dictionary={}; var best_score:=-1.0
	for citizen in GameState.living_citizens():
		var citizen_id:=int(citizen.get("id",-1))
		if excluded.has(citizen_id) or GameState.citizen_age_years(citizen)<18: continue
		# The commander is resolved separately from formation casualties and captivity.
		# Keep field command outside every enlisted pool so one citizen cannot receive
		# two contradictory battlefield fates in the same engagement.
		if String(citizen.get("army_status","civilian")) not in ["civilian",""]: continue
		var aptitude:=float(posmod(int(citizen.get("aptitude_seed",citizen_id*7919)),1000))/1000.0
		var score:=GameState.citizen_physical_capacity(citizen)*0.42+aptitude*0.48+(0.10 if String(citizen.get("role",""))=="Defense" else 0.0)
		if score>best_score: best_score=score; best=citizen
	if best.is_empty(): return simulator.create_commander("Acting field captain",0.38,0.36,0.30,0.42)
	var competence:=clampf(0.28+best_score*0.38,0.30,0.68)
	var advisor:={"citizen_id":int(best.id),"name":String(best.get("name","Acting field captain")),"background":"Field-promoted officer","traits":["Resolute","Pragmatic"],"skills":{"Strategy":roundi(competence*100.0),"Tactics":roundi(competence*92.0),"Logistics":roundi(competence*78.0)},"relationships":{"sovereign":{"trust":0.46,"respect":0.52,"fear":0.18,"resentment":0.0,"obligation":0.62}},"honesty":0.52,"courage":clampf(competence+0.10,0.0,1.0),"pride":0.42,"suspicion":0.48,"support":roundi(competence*75.0),"acting":true}
	if assign_office: GameState.leadership_positions["Marshal"]=advisor
	var commander:Dictionary=simulator.create_commander(String(advisor.name),competence,competence*0.92,competence*0.78,clampf(competence+0.08,0.0,1.0))
	commander["citizen_id"]=int(best.id); commander["office"]="Marshal"; commander["acting"]=true
	return commander


func _remove_active_citizen(citizen_id:int)->bool:
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	var position:=soldier_ids.find(citizen_id)
	if position<0: return false
	soldier_ids.remove_at(position)
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var member_ids:Array=(formation.get("soldier_ids",[]) as Array).duplicate()
		var member_position:=member_ids.find(citizen_id)
		if member_position<0: continue
		member_ids.remove_at(member_position)
		formation["count"]=int(formation.get("count",0))-1
		formation["soldier_ids"]=member_ids
		formations[index]=formation
		break
	home_army["soldier_ids"]=soldier_ids
	home_army["formations"]=formations
	home_army["troops"]=maxi(0,int(home_army.get("troops",0))-1)
	_refresh_formation_experience()
	return true


func _condition_average(soldiers:Array[Dictionary])->float:
	if soldiers.is_empty(): return 0.0
	return float(GameState.citizen_condition_profile(soldiers).average_capacity)


func _campaign_morale()->float:
	return clampf(float(GameState.simulation_metrics.get("cohesion",0.58))*0.55+float(GameState.simulation_metrics.get("security",0.38))*0.45,0.15,1.0)


func _terrain_defense()->float:
	return float({"Mountains":1.35,"Hills":1.20,"Forest":1.15,"Marsh":1.12,"Plains":1.0}.get(GameState.province_terrain,1.0))


func _home_army_name()->String:
	return "%s Host" % (GameState.settlement_name if GameState.settlement_name!="" else "Founding")


func _apply_home_result(side:Dictionary,rounds:Array,battle_seed:int)->void:
	var totals:={"killed":0,"wounded":0,"scattered":0}
	var equipment_loss_by_formation:Array[int]=[]
	for round_data in rounds:
		var breakdown:Dictionary=round_data.get("attacker_casualties",{})
		for key in totals: totals[key]=int(totals[key])+int(breakdown.get(key,0))
		var round_equipment:Array=round_data.get("attacker_cohort_equipment_losses",[])
		while equipment_loss_by_formation.size()<round_equipment.size(): equipment_loss_by_formation.append(0)
		for index in round_equipment.size(): equipment_loss_by_formation[index]+=int(round_equipment[index])
	var old_formations:Array=home_army.get("formations",[])
	var result_formations:Array=side.get("formations",[]).duplicate(true)
	var unassigned:Array=home_army.get("soldier_ids",[]).duplicate()
	var soldier_ids:Array=[]
	var casualty_ids:Array=[]
	var rng:=RandomNumberGenerator.new(); rng.seed=battle_seed^0x5bd1e995
	for formation_index in result_formations.size():
		var old_formation:Dictionary=old_formations[formation_index] if formation_index<old_formations.size() else {}
		var members:Array=(old_formation.get("soldier_ids",[]) as Array).duplicate()
		if members.is_empty():
			for index in mini(int(old_formation.get("count",0)),unassigned.size()): members.append(unassigned.pop_front())
		else:
			for citizen_id in members: unassigned.erase(citizen_id)
		for index in range(members.size()-1,0,-1):
			var swap_index:=rng.randi_range(0,index); var held=members[index]; members[index]=members[swap_index]; members[swap_index]=held
		var survivor_count:=mini(int(result_formations[formation_index].get("count",0)),members.size())
		var survivors:=members.slice(0,survivor_count)
		casualty_ids.append_array(members.slice(survivor_count))
		result_formations[formation_index]["soldier_ids"]=survivors
		soldier_ids.append_array(survivors)
	casualty_ids.append_array(unassigned)
	var wounded_ids:Array=home_army.get("wounded_ids",[]).duplicate()
	var scattered_ids:Array=home_army.get("scattered_ids",[]).duplicate()
	var killed_names:Array[String]=[]
	var status_queue:Array[String]=[]
	for index in int(totals.killed): status_queue.append("killed")
	for index in int(totals.wounded): status_queue.append("wounded")
	for index in int(totals.scattered): status_queue.append("scattered")
	for index in mini(status_queue.size(),casualty_ids.size()):
		var citizen:Dictionary=GameState.citizen_by_id(int(casualty_ids[index]))
		if citizen.is_empty(): continue
		citizen["army_status"]=status_queue[index]
		if status_queue[index]=="killed":
			var killed_name:=GameState.register_specific_death(int(citizen.id),"Killed in battle")
			if killed_name!="": killed_names.append(killed_name)
		elif status_queue[index]=="wounded": wounded_ids.append(int(citizen.id))
		elif status_queue[index]=="scattered": scattered_ids.append(int(citizen.id))
	_record_military_deaths(killed_names,"Killed in battle")
	var experience_gain:=clampf(float(rounds.size())*0.014,0.008,0.12)
	for index in mini(status_queue.size(),casualty_ids.size()):
		if status_queue[index]=="killed": continue
		var casualty_survivor:Dictionary=GameState.citizen_by_id(int(casualty_ids[index]))
		if not casualty_survivor.is_empty(): _award_combat_experience(casualty_survivor,experience_gain*0.70)
	for citizen_id in soldier_ids:
		var survivor:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if survivor.is_empty(): continue
		_award_combat_experience(survivor,experience_gain)
	for formation_index in result_formations.size(): result_formations[formation_index]["experience"]=_citizen_experience(result_formations[formation_index].get("soldier_ids",[]))
	var persisted:=home_army.duplicate(true)
	var salvage_accumulators:Dictionary=persisted.get("battlefield_salvage_accumulators",{}).duplicate()
	for formation_index in equipment_loss_by_formation.size():
		if int(equipment_loss_by_formation[formation_index])<=0 or formation_index>=old_formations.size(): continue
		var weapon:=String(old_formations[formation_index].get("weapon","improvised"))
		var salvage_progress:=float(salvage_accumulators.get(weapon,0.0))+float(equipment_loss_by_formation[formation_index])*0.35
		var salvaged:=floori(salvage_progress)
		salvage_accumulators[weapon]=salvage_progress-float(salvaged)
		if salvaged>0: damaged_equipment[weapon]=int(damaged_equipment.get(weapon,0))+salvaged
	persisted["battlefield_salvage_accumulators"]=salvage_accumulators
	persisted["formations"]=result_formations
	persisted["troops"]=int(side.get("remaining_troops",0))
	persisted["morale"]=float(side.get("morale",persisted.get("morale",1.0)))
	persisted["attack"]=float(side.get("attack",persisted.get("attack",1.0)))
	persisted["defense"]=float(side.get("defense",persisted.get("defense",1.0)))
	persisted["armor"]=float(side.get("armor",persisted.get("armor",0.0)))
	persisted["penetration"]=float(side.get("penetration",persisted.get("penetration",0.0)))
	persisted["wounded_pool"]=int(side.get("wounded_pool",0))
	persisted["scattered_pool"]=int(side.get("scattered_pool",0))
	persisted["dead"]=int(side.get("dead",persisted.get("dead",0)))
	home_army=persisted
	home_army["soldier_ids"]=soldier_ids
	home_army["wounded_ids"]=wounded_ids
	home_army["scattered_ids"]=scattered_ids
	home_army["campaign_day"]=int(GameState.elapsed_days)
	_reconcile_dead_military_citizens()


func _reconcile_dead_military_citizens()->Dictionary:
	var removed:Array[int]=[]
	var living_recruits:Array[int]=[]
	for citizen_id in recruit_pool:
		var recruit:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not recruit.is_empty() and bool(recruit.get("alive",true)): living_recruits.append(int(citizen_id))
		else: removed.append(int(citizen_id))
	recruit_pool=living_recruits
	for index in range(training_queue.size()-1,-1,-1):
		var training:Dictionary=training_queue[index]
		var living_trainees:Array[int]=[]
		for citizen_id in training.get("soldier_ids",[]):
			var trainee:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if not trainee.is_empty() and bool(trainee.get("alive",true)): living_trainees.append(int(citizen_id))
			else: removed.append(int(citizen_id))
		training["soldier_ids"]=living_trainees
		training["count"]=living_trainees.size()
		if living_trainees.is_empty(): training_queue.remove_at(index)
		else: training_queue[index]=training
	for index in range(training_injuries.size()-1,-1,-1):
		var injured_id:=int(training_injuries[index].get("citizen_id",-1))
		var injured:Dictionary=GameState.citizen_by_id(injured_id)
		if injured.is_empty() or not bool(injured.get("alive",true)):
			removed.append(injured_id)
			training_injuries.remove_at(index)
	if not home_army.is_empty():
		var formations:Array=home_army.get("formations",[])
		var living_active:Array[int]=[]
		for formation_index in formations.size():
			var formation:Dictionary=formations[formation_index]
			var living_members:Array[int]=[]
			for citizen_id in formation.get("soldier_ids",[]):
				var soldier:Dictionary=GameState.citizen_by_id(int(citizen_id))
				if not soldier.is_empty() and bool(soldier.get("alive",true)):
					living_members.append(int(citizen_id)); living_active.append(int(citizen_id))
				else: removed.append(int(citizen_id))
			formation["soldier_ids"]=living_members
			formation["count"]=living_members.size()
			formation["experience"]=_citizen_experience(living_members)
			formations[formation_index]=formation
		home_army["formations"]=formations
		home_army["soldier_ids"]=living_active
		home_army["troops"]=living_active.size()
		for pool_name in ["wounded_ids","scattered_ids","captured_ids"]:
			var living_pool:Array[int]=[]
			for citizen_id in home_army.get(pool_name,[]):
				var pooled:Dictionary=GameState.citizen_by_id(int(citizen_id))
				if not pooled.is_empty() and bool(pooled.get("alive",true)): living_pool.append(int(citizen_id))
				else: removed.append(int(citizen_id))
			home_army[pool_name]=living_pool
			if pool_name=="wounded_ids": home_army["wounded_pool"]=living_pool.size()
			elif pool_name=="scattered_ids": home_army["scattered_pool"]=living_pool.size()
		var commander:Dictionary=home_army.get("commander",{})
		var commander_id:=int(commander.get("citizen_id",-1))
		if commander_id>=0:
			var commander_citizen:Dictionary=GameState.citizen_by_id(commander_id)
			if commander_citizen.is_empty() or not bool(commander_citizen.get("alive",true)):
				var marshal:Dictionary=GameState.leadership_positions.get("Marshal",{})
				if int(marshal.get("citizen_id",-2))==commander_id: GameState.leadership_positions.erase("Marshal")
				var successor:=_acting_field_commander(true)
				home_army["commander"]=successor
				GameState.council_inbox.push_front({"id":"natural_succession_%d_%d" % [int(GameState.elapsed_days),commander_id],"advisor":String(successor.get("name","Field command")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":"%s has died away from battle. %s assumes field command." % [String(commander.get("name","The commander")),String(successor.get("name","An acting captain"))],"urgency":0.88,"day":int(GameState.elapsed_days),"status":"unread"})
		_refresh_readiness()
	return {"removed":removed.size(),"citizen_ids":removed}


func _process_military_day()->void:
	if active_engagement.is_empty(): _reconcile_dead_military_citizens()
	_process_service_rest_day()
	_process_prisoner_custody_day()
	_process_equipment_production_day()
	_process_training_injuries_day()
	_process_training_day()
	_process_threat_day()
	if not active_engagement.is_empty(): return
	if home_army.is_empty() or not pending_aftermath.is_empty(): return
	var logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.5))
	_update_supply_day()
	_process_service_strain_day()
	_process_equipment_wear_day()
	var supply:=float(home_army.get("supply_level",1.0))
	var delivery_capacity:=_daily_delivery_capacity()
	var delivered:=_deliver_inventory_replacements(delivery_capacity)
	var ammunition_delivered:=_deliver_ammunition(maxi(0,delivery_capacity-delivered))
	var recovery_multiplier:=0.35+supply*0.55+_adoption("battlefield_medicine")*0.55
	var prepared:Dictionary=simulator.advance_preparation_day(home_army,{"equipment_replacements":0,"manpower_replacements":0,"organization_recovery":(0.025+logistics*0.055)*(0.35+supply*0.65),"recovery_multiplier":recovery_multiplier})
	home_army=prepared.force
	_rejoin_recovered_citizens("scattered_ids",int(prepared.scattered_returned))
	_rejoin_recovered_citizens("wounded_ids",int(prepared.wounded_returned))
	_release_recovered_to_recruits("scattered_ids",int(prepared.get("scattered_recovered",prepared.scattered_returned))-int(prepared.scattered_returned))
	_release_recovered_to_recruits("wounded_ids",int(prepared.get("wounded_recovered",prepared.wounded_returned))-int(prepared.wounded_returned))
	home_army["equipment_delivered_today"]=delivered
	home_army["ammunition_delivered_today"]=ammunition_delivered
	_refresh_readiness()
	home_army["campaign_day"]=int(GameState.elapsed_days)
	army_changed.emit(home_army.duplicate(true))


func _process_prisoner_custody_day()->Dictionary:
	if foreign_prisoners<=0:
		prisoner_escape_accumulator=0.0
		return {"escaped":0,"remaining":0}
	prisoner_custody_days+=1
	var custody:=prisoner_custody_snapshot()
	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.58)),0.0,1.0)
	var daily_escape_rate:=maxf(0.0,1.0-float(custody.guard_coverage))*0.006*(1.15-cohesion*0.35)
	prisoner_escape_accumulator+=float(foreign_prisoners)*daily_escape_rate
	var escaped:=mini(foreign_prisoners,floori(prisoner_escape_accumulator))
	prisoner_escape_accumulator-=float(escaped)
	foreign_prisoners-=escaped
	escaped_prisoners_total+=escaped
	if escaped>0: GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Prisoners escape","description":"%d prisoners escape inadequate custody." % escaped,"domain":"security","severity":"warning"})
	return {"escaped":escaped,"remaining":foreign_prisoners,"guard_coverage":custody.guard_coverage}


func _process_service_rest_day()->void:
	for citizen in GameState.living_citizens():
		if String(citizen.get("army_status","civilian")) not in ["civilian","deserter",""]: continue
		var strain:=float(citizen.get("service_strain",0.0))
		if strain<=0.0: continue
		citizen["service_strain"]=move_toward(strain,0.0,0.006+_adoption("battlefield_medicine")*0.003)


func _release_recovered_to_recruits(pool_name:String,count:int)->void:
	var remaining:=maxi(0,count)
	if remaining<=0: return
	var pool:Array=(home_army.get(pool_name,[]) as Array).duplicate()
	var numeric_name:="wounded_pool" if pool_name=="wounded_ids" else "scattered_pool"
	while remaining>0 and not pool.is_empty():
		var citizen_id:=int(pool.pop_front())
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if not citizen.is_empty() and bool(citizen.get("alive",true)):
			citizen["army_status"]="recruit"
			if citizen_id not in recruit_pool: recruit_pool.append(citizen_id)
		remaining-=1
	home_army[pool_name]=pool
	home_army[numeric_name]=pool.size()


func _process_service_strain_day()->Dictionary:
	var active_ids:Array=(home_army.get("soldier_ids",[]) as Array).duplicate()
	if active_ids.is_empty():
		home_army["service_strain"]=0.0
		home_army["desertion_pressure"]=0.0
		return {"deserted":0,"citizen_ids":[]}
	var supply:=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
	var morale:=clampf(float(home_army.get("morale",1.0)),0.0,1.0)
	var recent_combat:=1.0 if int(home_army.get("recent_combat_days",0))>0 else 0.0
	var commander:Dictionary=home_army.get("commander",{})
	var leadership:=clampf(float(commander.get("command",0.5))*0.55+float(commander.get("resolve",0.5))*0.45,0.0,1.0)
	var training:=0.0
	for formation in home_army.get("formations",[]): training+=float(formation.get("training",0.0))*float(formation.get("count",0))
	training=clampf(training/maxf(1.0,float(active_ids.size())),0.0,1.0)
	var discipline:=clampf(0.18+leadership*0.42+training*0.30+_adoption("professional_corps")*0.18,0.0,1.0)
	var daily_strain:=0.0015+(1.0-supply)*0.008+recent_combat*0.004+(1.0-morale)*0.003
	var total_strain:=0.0
	var candidates:Array[Dictionary]=[]
	var commander_id:=int(commander.get("citizen_id",-1))
	for citizen_id in active_ids:
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if citizen.is_empty(): continue
		citizen["military_service_days"]=int(citizen.get("military_service_days",0))+1
		var personal_resilience:=clampf(GameState.citizen_physical_capacity(citizen)*0.55+float(citizen.get("military_experience",0.0))*0.25+discipline*0.20,0.0,1.0)
		var strain:=clampf(float(citizen.get("service_strain",0.0))+daily_strain*(1.20-personal_resilience*0.40),0.0,1.0)
		citizen["service_strain"]=strain
		total_strain+=strain
		if int(citizen_id)!=commander_id: candidates.append({"citizen_id":int(citizen_id),"strain":strain})
	var average_strain:=total_strain/maxf(1.0,float(active_ids.size()))
	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.58)),0.0,1.0)
	var pressure:=(maxf(0.0,average_strain-0.42)*0.020+maxf(0.0,0.42-supply)*0.024+maxf(0.0,0.32-morale)*0.018)*(1.15-discipline*0.65)*(1.10-cohesion*0.35)
	var accumulator:=float(home_army.get("desertion_accumulator",0.0))+float(candidates.size())*pressure
	var desertion_count:=mini(candidates.size(),floori(accumulator))
	accumulator-=float(desertion_count)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if not is_equal_approx(float(a.strain),float(b.strain)): return float(a.strain)>float(b.strain)
		return posmod(hash("%d:%d" % [int(GameState.elapsed_days),int(a.citizen_id)]),100000)<posmod(hash("%d:%d" % [int(GameState.elapsed_days),int(b.citizen_id)]),100000))
	var deserted_ids:Array[int]=[]
	for index in desertion_count:
		var citizen_id:=int(candidates[index].citizen_id)
		if not _remove_active_citizen(citizen_id): continue
		var deserter:Dictionary=GameState.citizen_by_id(citizen_id)
		if not deserter.is_empty():
			deserter["army_status"]="deserter"
			deserter["desertion_day"]=int(GameState.elapsed_days)
			deserter["role"]=String(deserter.get("pre_army_role","Unassigned"))
		deserted_ids.append(citizen_id)
	if not deserted_ids.is_empty():
		home_army["morale"]=clampf(float(home_army.get("morale",1.0))-0.015*float(deserted_ids.size()),0.0,1.5)
		home_army["desertions_total"]=int(home_army.get("desertions_total",0))+deserted_ids.size()
		GameState.simulation_metrics["cohesion"]=clampf(cohesion-0.002*float(deserted_ids.size()),0.0,1.0)
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Soldiers desert","description":"%d exhausted soldiers abandon the host." % deserted_ids.size(),"domain":"security","severity":"warning"})
		GameState.synchronize_population_allocations()
	home_army["service_days"]=int(home_army.get("service_days",0))+1
	home_army["service_strain"]=average_strain
	home_army["discipline"]=discipline
	home_army["desertion_pressure"]=pressure
	home_army["desertion_accumulator"]=accumulator
	return {"deserted":deserted_ids.size(),"citizen_ids":deserted_ids,"pressure":pressure,"discipline":discipline,"strain":average_strain}


func _update_supply_day()->void:
	var provision_day:=int(home_army.get("provision_day",-1))
	var provision_current:=provision_day>=0 and provision_day>=int(GameState.elapsed_days)-1
	var nutrition:=clampf(float(home_army.get("provision_ratio",1.0)),0.0,1.0) if provision_current else clampf(float(GameState.simulation_metrics.get("food_intake_ratio",GameState.food_security))*field_provision_delivery_ratio(),0.0,1.0)
	var troops:=maxi(1,_mobilized_count())
	var logistics_workers:=float(GameState.population_allocations.get("Logistics",0))
	var commander_logistics:=clampf(float((home_army.get("commander",{}) as Dictionary).get("logistics",0.4)),0.0,1.0)
	var labor_coverage:=clampf(logistics_workers/maxf(1.0,float(troops)*0.08),0.0,1.0)
	var practice:=_adoption("supply_groups")
	var delivery:=clampf(0.30+labor_coverage*0.38+commander_logistics*0.20+practice*0.20,0.0,1.0)
	var target:=clampf(nutrition*0.74+delivery*0.26,0.0,1.0)
	var current:=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
	var change:=0.07 if target>current else 0.13
	home_army["supply_level"]=move_toward(current,target,change)
	home_army["supply_components"]={"nutrition":nutrition,"delivery":delivery,"target":target,"logistics_workers":logistics_workers,"provisions_required":float(home_army.get("provisions_required_today",0.0)),"provisions_delivered":float(home_army.get("provisions_delivered_today",0.0))}
	home_army["recent_combat_days"]=maxi(0,int(home_army.get("recent_combat_days",0))-1)


func _daily_delivery_capacity()->int:
	var workers:=int(GameState.population_allocations.get("Logistics",0))
	if workers<=0: return 0
	var commander_logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.4))
	return maxi(1,floori(float(workers)*(0.35+commander_logistics*0.45+_adoption("supply_groups")*0.40)))


func _process_equipment_wear_day()->void:
	var supply:=float(home_army.get("supply_level",1.0))
	var recent_combat:=int(home_army.get("recent_combat_days",0))>0
	var standardization:=_adoption("workshop_standards")
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var equipment:=int(formation.get("equipment",0))
		if equipment<=0: continue
		var daily_rate:=maxf(0.0002,0.0007+(0.0075 if recent_combat else 0.0)+(1.0-supply)*0.004-standardization*0.0004)
		var accumulator:=float(formation.get("wear_accumulator",0.0))+float(equipment)*daily_rate
		var damaged:=mini(equipment,floori(accumulator))
		formation["wear_accumulator"]=accumulator-float(damaged)
		if damaged>0:
			var item:=String(formation.get("weapon","improvised"))
			formation["equipment"]=equipment-damaged
			damaged_equipment[item]=int(damaged_equipment.get(item,0))+damaged
		formations[index]=formation
	home_army["formations"]=formations


func _deliver_inventory_replacements(delivery_limit:int)->int:
	var delivered:=0
	var remaining_capacity:=maxi(0,delivery_limit)
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		if remaining_capacity<=0: break
		var formation:Dictionary=formations[index]
		var item:=String(formation.get("weapon","improvised"))
		var available:=int(military_inventory.get(item,0))
		var required:=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		var missing:=maxi(0,required-int(formation.get("equipment",0)))
		var transfer:=mini(mini(available,missing),remaining_capacity)
		if transfer<=0: continue
		formation["equipment"]=int(formation.get("equipment",0))+transfer
		formations[index]=formation
		military_inventory[item]=available-transfer
		delivered+=transfer
		remaining_capacity-=transfer
	home_army["formations"]=formations
	return delivered


func _deliver_ammunition(delivery_limit:int)->int:
	var delivered:=0
	var remaining_capacity:=maxi(0,delivery_limit)
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		if remaining_capacity<=0: break
		var formation:Dictionary=formations[index]
		var weapon:=String(formation.get("weapon","improvised"))
		var ammunition_type:=_ammunition_type_for(weapon)
		if ammunition_type=="": continue
		var available:=maxi(0,int(military_consumables.get(ammunition_type,0)))
		if available<=0: continue
		var required:=maxi(0,int(formation.get("ammunition_required",_ammunition_required_for(weapon,int(formation.get("equipment_required",0))))))
		var missing:=maxi(0,required-int(formation.get("ammunition",0)))
		var transfer:=mini(mini(available,missing),remaining_capacity)
		if transfer<=0: continue
		formation["ammunition"]=int(formation.get("ammunition",0))+transfer
		formation["ammunition_required"]=required
		formations[index]=formation
		available-=transfer
		military_consumables[ammunition_type]=available
		remaining_capacity-=transfer
		delivered+=transfer
	home_army["formations"]=formations
	return delivered


func _rejoin_recovered_citizens(pool_name:String,count:int)->void:
	var pool:Array=home_army.get(pool_name,[]).duplicate()
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	var formations:Array=home_army.get("formations",[])
	for index in mini(count,pool.size()):
		var citizen_id:=int(pool.pop_front())
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if citizen.is_empty() or not bool(citizen.get("alive",true)): continue
		citizen["army_status"]="active"
		soldier_ids.append(citizen_id)
		for formation_index in formations.size():
			var member_ids:Array=(formations[formation_index].get("soldier_ids",[]) as Array).duplicate()
			if member_ids.size()>=int(formations[formation_index].get("count",0)): continue
			member_ids.append(citizen_id)
			formations[formation_index]["soldier_ids"]=member_ids
			break
	home_army[pool_name]=pool
	home_army["soldier_ids"]=soldier_ids
	home_army["formations"]=formations
	_refresh_formation_experience()


func _process_equipment_production_day()->void:
	if equipment_queue.is_empty(): return
	var crafting:=_production_rate()
	if crafting<=0.0: return
	var job:Dictionary=equipment_queue[0]
	job["progress_days"]=float(job.get("progress_days",0.0))+crafting
	var work_per_item:=maxf(0.01,float(job.get("work_per_item",float(job.get("required_days",1.0))/maxf(1.0,float(job.get("count",1))))))
	var previously_completed:=int(job.get("completed",0))
	var completed:=mini(int(job.count),floori(float(job.progress_days)/work_per_item))
	var produced:=maxi(0,completed-previously_completed)
	if produced>0:
		if String(job.get("job_type","production"))=="consumable": military_consumables[String(job.item)]=int(military_consumables.get(String(job.item),0))+produced
		elif String(job.get("job_type","production"))=="transport": GameState.resource_stockpiles["Transport Carts"]=float(GameState.resource_stockpiles.get("Transport Carts",0.0))+produced
		else: military_inventory[String(job.item)]=int(military_inventory.get(String(job.item),0))+produced
	job["completed"]=completed
	if completed>=int(job.count):
		equipment_queue.pop_front()
	else: equipment_queue[0]=job


func _process_training_day()->void:
	if training_queue.is_empty(): return
	var training_rate:=_effective_training_rate(_queued_trainees())
	var training_equipment_budget:=military_inventory.duplicate(true)
	for index in range(training_queue.size()-1,-1,-1):
		var training:Dictionary=training_queue[index]
		var weapon:=String(training.get("weapon","improvised"))
		var available_examples:=maxi(0,int(training_equipment_budget.get(weapon,0)))
		var examples_required:=_equipment_required_for(String(training.get("unit","levy")),int(training.get("count",1)))
		var examples:=mini(maxi(1,examples_required),available_examples)
		training_equipment_budget[weapon]=available_examples-examples
		var equipment_access:=clampf(float(examples)/maxf(1.0,float(examples_required)),0.0,1.0)
		var access_floor:=0.55 if weapon=="improvised" else 0.25
		var progress_increment:=training_rate*(access_floor+(1.0-access_floor)*equipment_access)
		training["progress_days"]=float(training.get("progress_days",0.0))+progress_increment
		training["equipment_access_today"]=equipment_access
		training["equipment_access_sum"]=float(training.get("equipment_access_sum",0.0))+equipment_access*progress_increment
		training["instruction_progress_sum"]=float(training.get("instruction_progress_sum",0.0))+progress_increment
		var completion:=clampf(float(training.progress_days)/maxf(1.0,float(training.required_days)),0.0,1.0)
		for citizen_id in training.soldier_ids:
			var trainee:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if not trainee.is_empty(): trainee["military_training"]=maxf(float(trainee.get("military_training",0.0)),completion)
		var intensity:=float({"levy":0.75,"line_infantry":1.0,"skirmisher":0.90,"cavalry":1.20}.get(String(training.unit),1.0))
		var average_condition:=_trainee_condition(training.soldier_ids)
		training["injury_accumulator"]=float(training.get("injury_accumulator",0.0))+float(training.count)*0.0012*intensity*(1.35-average_condition*0.55)
		var injuries:=mini(int(training.count),floori(float(training.injury_accumulator)))
		training["injury_accumulator"]=float(training.injury_accumulator)-float(injuries)
		for injury_index in injuries:
			if (training.soldier_ids as Array).is_empty(): break
			var selected:=posmod(int(training.get("id",1))*31+last_processed_day*17+injury_index,(training.soldier_ids as Array).size())
			var injured_id:=int((training.soldier_ids as Array).pop_at(selected))
			training["count"]=int(training.count)-1
			var injured:Dictionary=GameState.citizen_by_id(injured_id)
			if not injured.is_empty(): injured["army_status"]="training_injured"
			training_injuries.append({"citizen_id":injured_id,"remaining_days":5+posmod(injured_id+int(training.get("id",1)),8),"source_order_id":int(training.get("id",-1))})
		if int(training.count)<=0:
			training_queue.remove_at(index)
			continue
		if float(training.progress_days)<float(training.required_days):
			training_queue[index]=training
			continue
		_complete_training(training)
		training_queue.remove_at(index)


func _process_training_injuries_day()->void:
	for index in range(training_injuries.size()-1,-1,-1):
		var injury:Dictionary=training_injuries[index]
		injury["remaining_days"]=int(injury.get("remaining_days",1))-1
		if int(injury.remaining_days)>0:
			training_injuries[index]=injury
			continue
		var citizen_id:=int(injury.get("citizen_id",-1))
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if not citizen.is_empty() and bool(citizen.get("alive",true)):
			citizen["army_status"]="recruit"
			if citizen_id not in recruit_pool: recruit_pool.append(citizen_id)
		training_injuries.remove_at(index)


func _trainee_condition(citizen_ids:Array)->float:
	var citizens:Array[Dictionary]=[]
	for citizen_id in citizen_ids:
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not citizen.is_empty(): citizens.append(citizen)
	return _condition_average(citizens) if not citizens.is_empty() else 0.5


func _equipment_required_for(unit:String,personnel:int)->int:
	return ceili(float(maxi(0,personnel))/5.0) if unit=="field_artillery" else maxi(0,personnel)


func _ammunition_required_for(weapon:String,equipment_required:int)->int:
	if weapon=="bow": return maxi(0,equipment_required)*6
	if weapon=="field_gun": return maxi(0,equipment_required)*8
	return 0


func _ammunition_type_for(weapon:String)->String:
	if weapon=="bow": return "arrows"
	if weapon=="field_gun": return "artillery_rounds"
	return ""


func _complete_training(training:Dictionary)->void:
	if home_army.is_empty(): home_army=_empty_home_army()
	var count:=int(training.count)
	var weapon:=String(training.weapon)
	var member_ids:Array=(training.soldier_ids as Array).duplicate()
	var equipment_access_average:=clampf(float(training.get("equipment_access_sum",0.0))/maxf(0.01,float(training.get("instruction_progress_sum",training.get("required_days",1.0)))),0.0,1.0)
	var equipment_training_factor:=0.72+equipment_access_average*0.28
	var formations:Array=home_army.get("formations",[])
	var mode:=String(training.get("mode","new"))
	var target_index:=_formation_index(int(training.get("target_formation_id",-1))) if mode=="reinforce" else -1
	var equipment_needed:=_equipment_required_for(String(training.unit),count)
	if target_index>=0:
		var reinforcement_target:Dictionary=formations[target_index]
		equipment_needed=maxi(0,int(reinforcement_target.get("equipment_required",_equipment_required_for(String(training.unit),int(reinforcement_target.get("authorized_count",reinforcement_target.get("count",0))))))-int(reinforcement_target.get("equipment",0)))
	var issued:=mini(equipment_needed,int(military_inventory.get(weapon,0)))
	military_inventory[weapon]=int(military_inventory.get(weapon,0))-issued
	if target_index>=0:
		var target:Dictionary=formations[target_index]
		var old_count:=int(target.get("count",0))
		var new_training:=_training_quality(String(training.unit),member_ids)*equipment_training_factor
		target["count"]=old_count+count
		target["equipment"]=int(target.get("equipment",0))+issued
		target["ammunition_required"]=_ammunition_required_for(weapon,int(target.get("equipment_required",_equipment_required_for(String(training.unit),int(target.get("authorized_count",old_count))))))
		target["training"]=(float(target.get("training",0.5))*old_count+new_training*count)/maxf(1.0,float(old_count+count))
		var target_members:Array=(target.get("soldier_ids",[]) as Array).duplicate(); target_members.append_array(member_ids)
		target["soldier_ids"]=target_members
		target["experience"]=_citizen_experience(target_members)
		formations[target_index]=target
	else:
		var formation_id:=next_formation_id; next_formation_id+=1
		var equipment_required:=_equipment_required_for(String(training.unit),count)
		formations.append({"id":formation_id,"unit":String(training.unit),"weapon":weapon,"count":count,"authorized_count":count,"equipment":issued,"equipment_required":equipment_required,"ammunition":0,"ammunition_required":_ammunition_required_for(weapon,equipment_required),"training":_training_quality(String(training.unit),member_ids)*equipment_training_factor,"experience":_citizen_experience(member_ids),"soldier_ids":member_ids})
	var rebuilt:Dictionary=simulator.create_formation_force(_home_army_name(),formations,_campaign_morale(),1.0)
	rebuilt["commander"]=_marshal_commander()
	rebuilt["wounded_pool"]=int(home_army.get("wounded_pool",0))
	rebuilt["scattered_pool"]=int(home_army.get("scattered_pool",0))
	rebuilt["reserve_manpower"]=0
	rebuilt["wounded_ids"]=home_army.get("wounded_ids",[]).duplicate()
	rebuilt["scattered_ids"]=home_army.get("scattered_ids",[]).duplicate()
	rebuilt["captured_ids"]=home_army.get("captured_ids",[]).duplicate()
	for key in ["supply_level","supply_components","recent_combat_days","equipment_delivered_today","ammunition_delivered_today"]:
		if home_army.has(key): rebuilt[key]=home_army[key].duplicate(true) if home_army[key] is Dictionary else home_army[key]
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	for citizen_id in training.soldier_ids:
		soldier_ids.append(int(citizen_id))
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not citizen.is_empty(): citizen["army_status"]="active"
	rebuilt["soldier_ids"]=soldier_ids
	rebuilt["campaign_day"]=int(GameState.elapsed_days)
	home_army=rebuilt
	_refresh_readiness()


func _equipment_recipe(item:String)->Dictionary:
	return {
		"improvised":{"materials":{"Timber":0.35},"days":0.25},
		"spear":{"materials":{"Timber":0.65,"Stone":0.10},"days":0.55},
		"bow":{"materials":{"Timber":0.45,"Fiber Plants":0.30},"days":0.80},
		"sword_shield":{"materials":{"Timber":0.50,"Copper Ore":0.50,"Tin Ore":0.08},"days":1.60},
		"lance":{"materials":{"Timber":1.10,"Iron Ore":0.20},"days":1.25},
		"siege_kit":{"materials":{"Timber":3.20,"Fiber Plants":0.80,"Stone":0.45,"Iron Ore":0.12},"days":3.80},
		"field_gun":{"materials":{"Iron Ore":8.0,"Timber":4.0,"Fiber Plants":0.50},"days":12.0}
	}.get(item,{"materials":{},"days":1.0})


func _consumable_recipe(item:String)->Dictionary:
	return {
		"arrows":{"materials":{"Timber":0.08,"Fiber Plants":0.025,"Stone":0.015},"days":0.055},
		"artillery_rounds":{"materials":{"Sulfur":0.12,"Nitrates":0.18,"Iron Ore":0.20,"Timber":0.08},"days":0.18}
	}.get(item,{"materials":{},"days":1.0})


func _transport_recipe()->Dictionary:
	return {"materials":{"Timber":8.0,"Fiber Plants":1.5},"days":5.0}


func _knowledge_gate(discovery:String,minimum_adoption:float)->Dictionary:
	if discovery=="": return {"unlocked":true,"discovery":"","adoption":1.0,"minimum_adoption":0.0,"prerequisites":[],"reason":"Available through basic household practice."}
	if discovery=="__mount_population__": return {"unlocked":false,"discovery":"","physical_requirement":"domesticated_mounts","missing_system":true,"adoption":0.0,"minimum_adoption":1.0,"prerequisites":[],"reason":"Requires a domesticated mount population and husbandry system; doctrine alone cannot create cavalry."}
	var definition:Dictionary=DiscoverySystem.discovery_definition(discovery)
	var prerequisites:Array=(definition.get("requires",[]) as Array).duplicate()
	var gate_base:={"discovery":discovery,"minimum_adoption":minimum_adoption,"prerequisites":prerequisites,"available_day":int(definition.get("day",0))}
	if discovery not in GameState.known_discoveries:
		var label:=String(definition.get("name",discovery.replace("_"," ").capitalize()))
		gate_base.merge({"unlocked":false,"adoption":0.0,"reason":"Requires inquiry: %s." % label})
		return gate_base
	var adoption:=_adoption(discovery)
	if adoption<minimum_adoption:
		gate_base.merge({"unlocked":false,"adoption":adoption,"reason":"%s is known but only %.0f%% adopted; %.0f%% is required." % [discovery.replace("_"," ").capitalize(),adoption*100.0,minimum_adoption*100.0]})
		return gate_base
	gate_base.merge({"unlocked":true,"adoption":adoption,"reason":"Available at %.0f%% adoption." % (adoption*100.0)})
	return gate_base


func _adoption(discovery:String)->float:
	return DiscoverySystem.adoption(discovery) if discovery in GameState.known_discoveries else 0.0


func _training_rate()->float:
	var security:=float(GameState.society_capacities.get("security",0.38))
	return (0.42+security*0.55)*(1.0+_adoption("formation_drill")*0.35+_adoption("professional_corps")*0.55)


func training_capacity()->int:
	var defense_workers:=float(GameState.population_allocations.get("Defense",0))
	var commander:Dictionary=home_army.get("commander",_marshal_commander())
	var command:=clampf(float(commander.get("command",0.5)),0.0,1.0)
	var base:=3.0+defense_workers*0.30+command*3.0
	base*=1.0+_adoption("formation_drill")*0.45+_adoption("professional_corps")*0.70+_adoption("military_staffs")*0.20
	return maxi(1,floori(base))


func _effective_training_rate(trainees:int)->float:
	if trainees<=0: return _training_rate()
	var load_factor:=minf(1.0,float(training_capacity())/float(trainees))
	return _training_rate()*load_factor


func _training_quality(unit:String,trainee_ids:Array=[])->float:
	var base:=float({"levy":0.48,"line_infantry":0.58,"skirmisher":0.55,"cavalry":0.56}.get(unit,0.50))
	var commander:Dictionary=home_army.get("commander",_marshal_commander())
	var trainee_experience:=_citizen_experience(trainee_ids)
	var retained_training:=_citizen_training(trainee_ids)
	var doctrine_transfer:=_army_experience()*_adoption("professional_corps")
	return clampf(base+float(commander.get("command",0.5))*0.12+_adoption("formation_drill")*0.14+_adoption("professional_corps")*0.12+_adoption("military_staffs")*0.06+trainee_experience*0.12+retained_training*0.08+doctrine_transfer*0.12,0.30,1.15)


func _citizen_experience(citizen_ids:Array)->float:
	if citizen_ids.is_empty(): return 0.0
	var total:=0.0; var found:=0
	for citizen_id in citizen_ids:
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if citizen.is_empty(): continue
		total+=clampf(float(citizen.get("military_experience",0.0)),0.0,1.0); found+=1
	return total/maxf(1.0,float(found))


func _citizen_training(citizen_ids:Array)->float:
	if citizen_ids.is_empty(): return 0.0
	var total:=0.0; var found:=0
	for citizen_id in citizen_ids:
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if citizen.is_empty(): continue
		total+=clampf(float(citizen.get("military_training",0.0)),0.0,1.0); found+=1
	return total/maxf(1.0,float(found))


func _award_combat_experience(citizen:Dictionary,gain:float)->void:
	var prior:=clampf(float(citizen.get("military_experience",0.0)),0.0,1.0)
	citizen["military_experience"]=clampf(prior+gain*(1.0-prior),0.0,1.0)
	citizen["battles_survived"]=int(citizen.get("battles_survived",0))+1


func _refresh_formation_experience()->void:
	if home_army.is_empty(): return
	var formations:Array=home_army.get("formations",[])
	for index in formations.size(): formations[index]["experience"]=_citizen_experience(formations[index].get("soldier_ids",[]))
	home_army["formations"]=formations


func _army_experience()->float:
	return _citizen_experience(home_army.get("soldier_ids",[])) if not home_army.is_empty() else 0.0


func _refresh_readiness()->void:
	if home_army.is_empty(): return
	var formations:Array=home_army.get("formations",[])
	var supply:=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
	var discipline:=clampf(float(home_army.get("discipline",0.5)),0.0,1.0)
	for formation_index in formations.size():
		var formation:Dictionary=formations[formation_index]
		var formation_soldiers:Array[Dictionary]=[]
		for citizen_id in formation.get("soldier_ids",[]):
			var formation_citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
			if not formation_citizen.is_empty() and bool(formation_citizen.get("alive",true)): formation_soldiers.append(formation_citizen)
		var formation_condition:=_condition_average(formation_soldiers)
		formation["personnel_condition"]=formation_condition
		var formation_force:Dictionary={"formations":[formation],"morale":float(home_army.get("morale",1.0))}
		var formation_readiness:Dictionary=simulator.force_readiness(formation_force,formation_condition)
		formation["readiness"]=float(formation_readiness.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)
		formations[formation_index]=formation
	home_army["formations"]=formations
	var soldiers:Array[Dictionary]=[]
	for citizen_id in home_army.get("soldier_ids",[]):
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not citizen.is_empty() and bool(citizen.get("alive",true)): soldiers.append(citizen)
	var condition:=_condition_average(soldiers)
	var readiness:Dictionary=simulator.force_readiness(home_army,condition)
	home_army["readiness"]=float(readiness.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)
	home_army["readiness_components"]=readiness
	home_army.readiness_components["supply"]=supply
	home_army.readiness_components["discipline"]=discipline
	home_army.readiness_components["service_strain"]=clampf(float(home_army.get("service_strain",0.0)),0.0,1.0)


func _production_rate()->float:
	return _base_production_rate()*workshop_utilization()


func _base_production_rate()->float:
	var crafting:=float(GameState.population_allocations.get("Crafting",0))*0.16
	if crafting<=0.0: return 0.0
	return crafting*(0.55+float(GameState.society_capacities.get("production",0.12))*0.45+_adoption("workshop_standards")*0.45)


func _equipment_backlog_work()->float:
	var backlog:=0.0
	for job in equipment_queue: backlog+=maxf(0.0,float(job.get("required_days",0.0))-float(job.get("progress_days",0.0)))
	return backlog


func workshop_utilization()->float:
	if equipment_queue.is_empty(): return 0.0
	var base_rate:=_base_production_rate()
	if base_rate<=0.0: return 0.0
	var backlog_days:=_equipment_backlog_work()/base_rate
	return clampf(0.20+backlog_days/30.0,0.20,0.75)


func civilian_crafting_fraction()->float:
	return 1.0-workshop_utilization()


func _apply_campaign_prisoner_policy(policy:String,count:int,outcome:Dictionary)->void:
	var normalized:=policy.to_lower()
	if normalized=="exchange":
		var exchanged:=mini(count,(home_army.get("captured_ids",[]) as Array).size())
		var returned:=_return_home_captives(exchanged)
		outcome["exchanged_prisoners"]=returned.size()
		outcome["returned_citizen_ids"]=returned
		outcome["released_prisoners"]=count-returned.size()
	elif normalized in ["release","parole"]:
		outcome["released_prisoners"]=count
		_adjust_war_reputation(float(count)*0.006,0.0,-float(count)*0.004)
		if normalized=="parole": GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.015,0.0,1.0)
	elif normalized=="ransom":
		outcome["war_wealth_receipt"]=_receive_war_wealth(count*2.0,"state treasury","Ransom for prisoners of war")
		outcome["ransom_income"]=count*2
		_adjust_war_reputation(0.0,float(count)*0.001,float(count)*0.003)
	elif normalized=="execute":
		outcome["executed_prisoners"]=count
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.06,0.0,1.0)
		_adjust_war_reputation(0.0,float(count)*0.010,float(count)*0.014)
	elif normalized=="enslave":
		GameState.resource_stockpiles["Forced Labor"]=float(GameState.resource_stockpiles.get("Forced Labor",0.0))+count
		outcome["forced_laborers"]=count
		GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))-0.035,0.0,1.0)
		_adjust_war_reputation(0.0,float(count)*0.006,float(count)*0.012)
	else:
		foreign_prisoners+=count
		outcome["held_prisoners"]=count


func _return_home_captives(count:int)->Array[int]:
	var captured:Array=(home_army.get("captured_ids",[]) as Array).duplicate()
	var returned:Array[int]=[]
	for index in mini(maxi(0,count),captured.size()):
		var citizen_id:=int(captured.pop_front())
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if citizen.is_empty() or not bool(citizen.get("alive",true)): continue
		var captured_commander:=String(citizen.get("military_capture_kind",""))=="commander"
		var return_to_recruits:=not captured_commander or bool(citizen.get("capture_was_active_soldier",false))
		if return_to_recruits:
			citizen["army_status"]="recruit"
			if citizen_id not in recruit_pool: recruit_pool.append(citizen_id)
		else:
			citizen["army_status"]="civilian"
			citizen["role"]=String(citizen.get("pre_capture_role",citizen.get("role","Unassigned")))
		citizen.erase("military_capture_kind")
		citizen.erase("capture_was_active_soldier")
		citizen.erase("pre_capture_role")
		returned.append(citizen_id)
	home_army["captured_ids"]=captured
	if not returned.is_empty(): GameState.synchronize_population_allocations()
	return returned


func _apply_campaign_spoils_policy(policy:String,spoils:Dictionary,outcome:Dictionary)->void:
	var weapons:Dictionary=spoils.get("weapons",{})
	var consumables:Dictionary=spoils.get("consumables",{})
	var gear_total:=0
	var consumable_total:=0
	for weapon in weapons:
		var amount:=int(weapons[weapon]); gear_total+=amount
		if policy.to_lower()=="army stores": military_inventory[weapon]=int(military_inventory.get(weapon,0))+amount
	for item in consumables:
		var amount:=int(consumables[item]); consumable_total+=amount
		if policy.to_lower()=="army stores": military_consumables[item]=int(military_consumables.get(item,0))+amount
	var supplies:=int(spoils.get("supplies",0)); var carts:=int(spoils.get("carts",0)); var wealth:=int(spoils.get("wealth",0))
	var converted_value:=float(wealth)+float(gear_total)*2.0+float(consumable_total)*0.15+float(supplies)+float(carts)*5.0
	match policy.to_lower():
		"army stores":
			GameState.resource_stockpiles["Food"]=float(GameState.resource_stockpiles.get("Food",0.0))+supplies
			GameState.resource_stockpiles["Transport Carts"]=float(GameState.resource_stockpiles.get("Transport Carts",0.0))+carts
			outcome["war_wealth_receipt"]=_receive_war_wealth(float(wealth),"state treasury","Captured campaign wealth stored by the army")
		"reward troops":
			home_army["morale"]=clampf(float(home_army.get("morale",0.0))+0.10,0.0,1.5)
			outcome["war_wealth_receipt"]=_receive_war_wealth(converted_value,"troops","Campaign spoils distributed to the troops")
		"state treasury": outcome["war_wealth_receipt"]=_receive_war_wealth(converted_value,"state treasury","Campaign spoils transferred to the state treasury")
		"return property": GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.06,0.0,1.0)
		"unrestricted plunder":
			outcome["war_wealth_receipt"]=_receive_war_wealth(converted_value*1.35,"troops","Unrestricted campaign plunder")
			GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.04,0.0,1.0)
	if policy.to_lower()=="return property": _adjust_war_reputation(0.04,0.0,-0.025)
	elif policy.to_lower()=="unrestricted plunder": _adjust_war_reputation(0.0,0.035,0.065)
	outcome["spoils"]={"gear":gear_total,"ammunition":consumable_total,"supplies":supplies,"carts":carts,"wealth":wealth}


func _apply_campaign_general_policy(policy:String,aftermath:Dictionary,outcome:Dictionary)->void:
	var general:={"name":String(aftermath.get("commander","Unknown commander")),"captured_day":int(GameState.elapsed_days)}
	if policy.to_lower()=="hold": held_generals.append(general)
	elif policy.to_lower()=="ransom":
		outcome["general_war_wealth_receipt"]=_receive_war_wealth(50.0,"state treasury","Ransom for captured enemy commander")
		outcome["general_ransom_income"]=50
	elif policy.to_lower()=="release":
		GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.01,0.0,1.0)
		_adjust_war_reputation(0.025,0.0,-0.012)
	elif policy.to_lower()=="execute":
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.025,0.0,1.0)
		_adjust_war_reputation(0.0,0.06,0.09)
		outcome["general_executed"]=true
	outcome["general_policy"]=policy


func _receive_war_wealth(amount:float,destination:String,reason:String)->Dictionary:
	var accepted:=maxf(0.0,amount)
	var economy:=get_node_or_null("/root/EconomySystem")
	if economy!=null and economy.has_method("receive_war_wealth"):
		return economy.call("receive_war_wealth",accepted,destination,reason)
	GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+accepted
	return {"accepted":accepted,"destination":"collective stores","medium":"physical coin and bullion","material_deposited":accepted,"currency_deposited":0.0,"fallback":true}


func _adjust_war_reputation(mercy_delta:float,fear_delta:float,grievance_delta:float)->void:
	war_reputation["mercy"]=clampf(float(war_reputation.get("mercy",0.0))+mercy_delta,0.0,1.0)
	war_reputation["fear"]=clampf(float(war_reputation.get("fear",0.0))+fear_delta,0.0,1.0)
	war_reputation["grievance"]=clampf(float(war_reputation.get("grievance",0.0))+grievance_delta,0.0,1.0)


func _mark_home_prisoners(count:int)->void:
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	var captured_ids:Array=home_army.get("captured_ids",[]).duplicate()
	var marked:=mini(maxi(0,count),soldier_ids.size())
	var formations:Array=home_army.get("formations",[])
	for index in marked:
		var soldier_id:=int(soldier_ids.pop_back())
		var citizen:Dictionary=GameState.citizen_by_id(int(soldier_id))
		if citizen.is_empty(): continue
		citizen["army_status"]="captured"
		captured_ids.append(soldier_id)
		for formation_index in formations.size():
			var member_ids:Array=(formations[formation_index].get("soldier_ids",[]) as Array).duplicate()
			var member_position:=member_ids.find(soldier_id)
			if member_position<0: continue
			member_ids.remove_at(member_position)
			formations[formation_index]["soldier_ids"]=member_ids
			formations[formation_index]["count"]=int(formations[formation_index].get("count",0))-1
			break
	home_army["formations"]=formations
	home_army["troops"]=maxi(0,int(home_army.get("troops",0))-marked)
	home_army["soldier_ids"]=soldier_ids
	home_army["captured_ids"]=captured_ids
	_refresh_formation_experience()


func _record_council_battle(result:Dictionary)->void:
	GameState.council_inbox.push_front({"id":"battle_%d_%d" % [int(GameState.elapsed_days),int(result.seed)],"advisor":String((home_army.get("commander",{}) as Dictionary).get("name","Field command")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":"Battle resolved: %s. %d of our soldiers remain; morale %.0f%%." % [String(result.outcome).replace("_"," ").capitalize(),int(result.attacker.remaining_troops),float(result.attacker.morale)*100.0],"urgency":0.92,"day":int(GameState.elapsed_days),"status":"unread"})


func _aftermath_description(outcome:Dictionary)->String:
	return "Prisoner policy: %s. Spoils policy: %s. General policy: %s." % [outcome.prisoner_policy,outcome.spoils_policy,outcome.general_policy]
