extends Node

signal army_changed(army: Dictionary)
signal battle_resolved(result: Dictionary)
signal aftermath_required(aftermath: Dictionary)

const COMBAT_SIMULATOR_SCRIPT:=preload("res://scripts/combat_simulator.gd")
const UNIT_KNOWLEDGE:Dictionary={"levy":"","line_infantry":"shield_wall","skirmisher":"bow_craft","cavalry":"mounted_warfare"}
const EQUIPMENT_KNOWLEDGE:Dictionary={"improvised":"","spear":"hafted_weapons","bow":"bow_craft","sword_shield":"bronze_weaponry","lance":"mounted_warfare"}

var simulator:RefCounted
var home_army:Dictionary={}
var battle_history:Array[Dictionary]=[]
var pending_aftermath:Dictionary={}
var military_inventory:Dictionary={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0}
var recruit_pool:Array[int]=[]
var training_queue:Array[Dictionary]=[]
var equipment_queue:Array[Dictionary]=[]
var foreign_prisoners:=0
var held_generals:Array[Dictionary]=[]
var last_world_seed:=-2147483648
var last_processed_day:=-1


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
	military_inventory={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0}
	recruit_pool.clear()
	training_queue.clear()
	equipment_queue.clear()
	foreign_prisoners=0
	held_generals.clear()


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
	for citizen in GameState.living_citizens():
		if String(citizen.get("army_status","civilian")) not in ["civilian",""]: continue
		if GameState.citizen_age_years(citizen)<16: continue
		candidates.append(citizen)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_defense:=1 if String(a.get("role",""))=="Defense" else 0
		var b_defense:=1 if String(b.get("role",""))=="Defense" else 0
		if a_defense!=b_defense: return a_defense>b_defense
		return GameState.citizen_physical_capacity(a)>GameState.citizen_physical_capacity(b))
	var capacity:=recruitment_capacity()
	var available_capacity:=maxi(0,capacity-recruit_pool.size()-_queued_trainees()-int(home_army.get("troops",0)))
	var raised:=0
	for index in mini(mini(maxi(0,count),candidates.size()),available_capacity):
		var citizen:Dictionary=candidates[index]
		citizen["army_status"]="recruit"
		citizen["role"]="Defense"
		recruit_pool.append(int(citizen.id))
		raised+=1
	if home_army.is_empty(): home_army=_empty_home_army()
	army_changed.emit(home_army.duplicate(true))
	return {"requested":count,"raised":raised,"recruit_pool":recruit_pool.size(),"capacity":capacity}


func start_training(unit:String,weapon:String,count:int)->Dictionary:
	if not simulator.UNIT_TYPES.has(unit): return {"error":"Unknown unit type: %s" % unit}
	if not simulator.WEAPONS.has(weapon): return {"error":"Unknown weapon type: %s" % weapon}
	var unit_gate:=_knowledge_gate(String(UNIT_KNOWLEDGE.get(unit,"")),0.10)
	if not bool(unit_gate.unlocked): return {"error":unit_gate.reason,"required_discovery":unit_gate.discovery}
	var weapon_gate:=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE.get(weapon,"")),0.10)
	if not bool(weapon_gate.unlocked): return {"error":weapon_gate.reason,"required_discovery":weapon_gate.discovery}
	var accepted:=mini(maxi(0,count),recruit_pool.size())
	if accepted<=0: return {"error":"No recruits are available for training."}
	var ids:Array[int]=[]
	for index in accepted: ids.append(recruit_pool.pop_front())
	var training_days:=int({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45}.get(unit,21))
	training_queue.append({"unit":unit,"weapon":weapon,"count":accepted,"soldier_ids":ids,"progress_days":0.0,"required_days":training_days})
	return {"accepted":accepted,"unit":unit,"weapon":weapon,"required_days":training_days}


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
	equipment_queue.append({"item":item,"count":amount,"progress_days":0.0,"required_days":float(recipe.days)*amount})
	return {"queued":amount,"item":item,"work_days":float(recipe.days)*amount}


func recruitment_capacity()->int:
	var population:=GameState.living_citizen_count()
	var share:=0.04
	if _adoption("watch_rotation")>=0.10: share=0.08
	if _adoption("public_levies")>=0.15: share=0.18
	if _adoption("professional_corps")>=0.20: share=0.30
	return maxi(1,roundi(float(population)*share))


func military_capabilities()->Dictionary:
	var units:Dictionary={}
	for unit in UNIT_KNOWLEDGE: units[unit]=_knowledge_gate(String(UNIT_KNOWLEDGE[unit]),0.10)
	var equipment:Dictionary={}
	for item in EQUIPMENT_KNOWLEDGE: equipment[item]=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE[item]),0.08)
	return {"units":units,"equipment":equipment,"recruitment_capacity":recruitment_capacity(),"training_rate":_training_rate(),"production_rate":_production_rate(),"medical_recovery":_adoption("battlefield_medicine"),"logistics_practice":_adoption("supply_groups"),"staff_planning":_adoption("military_staffs")}


func military_inquiry_context()->Dictionary:
	var active_military:=recruit_pool.size()+_queued_trainees()+int(home_army.get("troops",0))
	if active_military<=0 and equipment_queue.is_empty(): return {}
	return {"defense":0.15+float(recruit_pool.size()+_queued_trainees())*0.03,"training":minf(2.0,float(_queued_trainees())*0.08),"warfare":minf(2.0,float(home_army.get("troops",0))*0.035),"crafting":float(equipment_queue.size())*0.35,"materials":float(equipment_queue.size())*0.30,"logistics":float(GameState.population_allocations.get("Logistics",0))*0.06,"injury":0.45 if int(home_army.get("wounded_pool",0))>0 else 0.0}


func resolve_campaign_battle(enemy_force:Dictionary,options:Dictionary={})->Dictionary:
	if home_army.is_empty(): muster_home_army()
	if int(home_army.get("troops",0))<=0: return {"error":"No deployable home army."}
	var battle_options:=options.duplicate(true)
	battle_options["seed"]=int(battle_options.get("seed",GameState.world_seed^int(GameState.elapsed_days+1.0)*7919))
	battle_options["terrain_defense"]=float(battle_options.get("terrain_defense",_terrain_defense()))
	var result:Dictionary=simulator.simulate(home_army,enemy_force,battle_options)
	_apply_home_result(result.attacker,result.rounds)
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
	snapshot["recruits"]=recruit_pool.size()
	snapshot["training_queue"]=training_queue.duplicate(true)
	snapshot["equipment_queue"]=equipment_queue.duplicate(true)
	return snapshot


func _empty_home_army()->Dictionary:
	var force:Dictionary=simulator.create_formation_force(_home_army_name(),[],_campaign_morale(),0.0)
	force["commander"]=_marshal_commander()
	force["soldier_ids"]=[]
	force["wounded_ids"]=[]
	force["scattered_ids"]=[]
	force["campaign_day"]=int(GameState.elapsed_days)
	return force


func _queued_trainees()->int:
	var total:=0
	for entry in training_queue: total+=int(entry.get("count",0))
	return total


func _formations_for_strength(total:int)->Array[Dictionary]:
	var line_share:=0.42 if "formation_drill" in GameState.known_discoveries else 0.20
	var skirmish_share:=0.24 if "bow_making" in GameState.known_discoveries else 0.12
	var line:=roundi(float(total)*line_share)
	var skirmish:=roundi(float(total)*skirmish_share)
	var levy:=maxi(0,total-line-skirmish)
	var line_weapon:="spear" if "formation_drill" in GameState.known_discoveries else "improvised"
	var bow_weapon:="bow" if "bow_making" in GameState.known_discoveries else "improvised"
	return [
		{"unit":"levy","weapon":"improvised","count":levy,"authorized_count":levy,"equipment":levy,"equipment_required":levy},
		{"unit":"line_infantry","weapon":line_weapon,"count":line,"authorized_count":line,"equipment":line,"equipment_required":line},
		{"unit":"skirmisher","weapon":bow_weapon,"count":skirmish,"authorized_count":skirmish,"equipment":skirmish,"equipment_required":skirmish}
	]


func _marshal_commander()->Dictionary:
	var marshal:Dictionary=GameState.leadership_positions.get("Marshal",{})
	var security:=float(GameState.society_capacities.get("security",0.38))
	var logistics:=float(GameState.society_capacities.get("logistics",0.16))
	if marshal.is_empty(): return simulator.create_commander("Acting field captain",0.35+security*0.25,0.32+security*0.22,0.25+logistics*0.35,0.38)
	return simulator.create_commander(
		String(marshal.get("name","Marshal")),
		0.34+float(marshal.get("courage",0.5))*0.34+security*0.24,
		0.30+float(marshal.get("suspicion",0.5))*0.24+security*0.30,
		0.25+float(marshal.get("honesty",0.5))*0.18+logistics*0.48,
		0.30+float(marshal.get("courage",0.5))*0.42+float(marshal.get("pride",0.5))*0.12
	)


func _condition_average(soldiers:Array[Dictionary])->float:
	if soldiers.is_empty(): return 0.0
	return float(GameState.citizen_condition_profile(soldiers).average_capacity)


func _campaign_morale()->float:
	return clampf(float(GameState.simulation_metrics.get("cohesion",0.58))*0.55+float(GameState.simulation_metrics.get("security",0.38))*0.45,0.15,1.0)


func _terrain_defense()->float:
	return float({"Mountains":1.35,"Hills":1.20,"Forest":1.15,"Marsh":1.12,"Plains":1.0}.get(GameState.province_terrain,1.0))


func _home_army_name()->String:
	return "%s Host" % (GameState.settlement_name if GameState.settlement_name!="" else "Founding")


func _apply_home_result(side:Dictionary,rounds:Array)->void:
	var totals:={"killed":0,"wounded":0,"scattered":0}
	for round_data in rounds:
		var breakdown:Dictionary=round_data.get("attacker_casualties",{})
		for key in totals: totals[key]=int(totals[key])+int(breakdown.get(key,0))
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	var wounded_ids:Array=home_army.get("wounded_ids",[]).duplicate()
	var scattered_ids:Array=home_army.get("scattered_ids",[]).duplicate()
	var status_queue:Array[String]=[]
	for index in int(totals.killed): status_queue.append("killed")
	for index in int(totals.wounded): status_queue.append("wounded")
	for index in int(totals.scattered): status_queue.append("scattered")
	for index in mini(status_queue.size(),soldier_ids.size()):
		var citizen:Dictionary=GameState.citizen_by_id(int(soldier_ids.pop_back()))
		if citizen.is_empty(): continue
		citizen["army_status"]=status_queue[index]
		if status_queue[index]=="killed":
			citizen["alive"]=false
			citizen["death_day"]=int(GameState.elapsed_days)
			citizen["death_cause"]="Killed in battle"
		elif status_queue[index]=="wounded": wounded_ids.append(int(citizen.id))
		elif status_queue[index]=="scattered": scattered_ids.append(int(citizen.id))
	var persisted:=home_army.duplicate(true)
	persisted["formations"]=side.get("formations",[]).duplicate(true)
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


func _process_military_day()->void:
	_process_equipment_production_day()
	_process_training_day()
	if home_army.is_empty() or not pending_aftermath.is_empty(): return
	var logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.5))
	var delivered:=_deliver_inventory_replacements()
	var prepared:Dictionary=simulator.advance_preparation_day(home_army,{"equipment_replacements":0,"manpower_replacements":0,"organization_recovery":0.025+logistics*0.055})
	home_army=prepared.force
	_rejoin_recovered_citizens("scattered_ids",int(prepared.scattered_returned))
	_rejoin_recovered_citizens("wounded_ids",int(prepared.wounded_returned))
	home_army["equipment_delivered_today"]=delivered
	home_army["campaign_day"]=int(GameState.elapsed_days)
	army_changed.emit(home_army.duplicate(true))


func _deliver_inventory_replacements()->int:
	var delivered:=0
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var item:=String(formation.get("weapon","improvised"))
		var available:=int(military_inventory.get(item,0))
		var required:=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		var missing:=maxi(0,required-int(formation.get("equipment",0)))
		var transfer:=mini(available,missing)
		if transfer<=0: continue
		formation["equipment"]=int(formation.get("equipment",0))+transfer
		formations[index]=formation
		military_inventory[item]=available-transfer
		delivered+=transfer
	home_army["formations"]=formations
	return delivered


func _rejoin_recovered_citizens(pool_name:String,count:int)->void:
	var pool:Array=home_army.get(pool_name,[]).duplicate()
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	for index in mini(count,pool.size()):
		var citizen_id:=int(pool.pop_front())
		var citizen:Dictionary=GameState.citizen_by_id(citizen_id)
		if citizen.is_empty() or not bool(citizen.get("alive",true)): continue
		citizen["army_status"]="active"
		soldier_ids.append(citizen_id)
	home_army[pool_name]=pool
	home_army["soldier_ids"]=soldier_ids


func _process_equipment_production_day()->void:
	if equipment_queue.is_empty(): return
	var crafting:=_production_rate()
	var job:Dictionary=equipment_queue[0]
	job["progress_days"]=float(job.get("progress_days",0.0))+crafting
	if float(job.progress_days)>=float(job.required_days):
		military_inventory[String(job.item)]=int(military_inventory.get(String(job.item),0))+int(job.count)
		equipment_queue.pop_front()
	else: equipment_queue[0]=job


func _process_training_day()->void:
	if training_queue.is_empty(): return
	var training_rate:=_training_rate()
	for index in range(training_queue.size()-1,-1,-1):
		var training:Dictionary=training_queue[index]
		training["progress_days"]=float(training.get("progress_days",0.0))+training_rate
		if float(training.progress_days)<float(training.required_days):
			training_queue[index]=training
			continue
		_complete_training(training)
		training_queue.remove_at(index)


func _complete_training(training:Dictionary)->void:
	if home_army.is_empty(): home_army=_empty_home_army()
	var count:=int(training.count)
	var weapon:=String(training.weapon)
	var issued:=mini(count,int(military_inventory.get(weapon,0)))
	military_inventory[weapon]=int(military_inventory.get(weapon,0))-issued
	var formation:={"unit":String(training.unit),"weapon":weapon,"count":count,"authorized_count":count,"equipment":issued,"equipment_required":count,"training":1.0}
	var formations:Array=home_army.get("formations",[])
	formations.append(formation)
	var rebuilt:Dictionary=simulator.create_formation_force(_home_army_name(),formations,_campaign_morale(),1.0)
	rebuilt["commander"]=_marshal_commander()
	rebuilt["wounded_pool"]=int(home_army.get("wounded_pool",0))
	rebuilt["scattered_pool"]=int(home_army.get("scattered_pool",0))
	rebuilt["reserve_manpower"]=int(home_army.get("reserve_manpower",0))
	rebuilt["wounded_ids"]=home_army.get("wounded_ids",[]).duplicate()
	rebuilt["scattered_ids"]=home_army.get("scattered_ids",[]).duplicate()
	var soldier_ids:Array=home_army.get("soldier_ids",[]).duplicate()
	for citizen_id in training.soldier_ids:
		soldier_ids.append(int(citizen_id))
		var citizen:Dictionary=GameState.citizen_by_id(int(citizen_id))
		if not citizen.is_empty(): citizen["army_status"]="active"
	rebuilt["soldier_ids"]=soldier_ids
	rebuilt["campaign_day"]=int(GameState.elapsed_days)
	home_army=rebuilt


func _equipment_recipe(item:String)->Dictionary:
	return {
		"improvised":{"materials":{"Timber":0.35},"days":0.25},
		"spear":{"materials":{"Timber":0.65,"Stone":0.10},"days":0.55},
		"bow":{"materials":{"Timber":0.45,"Fiber Plants":0.30},"days":0.80},
		"sword_shield":{"materials":{"Timber":0.50,"Iron Ore":0.55},"days":1.60},
		"lance":{"materials":{"Timber":1.10,"Iron Ore":0.20},"days":1.25}
	}.get(item,{"materials":{},"days":1.0})


func _knowledge_gate(discovery:String,minimum_adoption:float)->Dictionary:
	if discovery=="": return {"unlocked":true,"discovery":"","adoption":1.0,"reason":"Available through basic household practice."}
	if discovery not in GameState.known_discoveries:
		var definition:Dictionary=DiscoverySystem.discovery_definition(discovery)
		var label:=String(definition.get("name",discovery.replace("_"," ").capitalize()))
		return {"unlocked":false,"discovery":discovery,"adoption":0.0,"reason":"Requires inquiry: %s." % label}
	var adoption:=_adoption(discovery)
	if adoption<minimum_adoption:
		return {"unlocked":false,"discovery":discovery,"adoption":adoption,"reason":"%s is known but only %.0f%% adopted; %.0f%% is required." % [discovery.replace("_"," ").capitalize(),adoption*100.0,minimum_adoption*100.0]}
	return {"unlocked":true,"discovery":discovery,"adoption":adoption,"reason":"Available at %.0f%% adoption." % (adoption*100.0)}


func _adoption(discovery:String)->float:
	return DiscoverySystem.adoption(discovery) if discovery in GameState.known_discoveries else 0.0


func _training_rate()->float:
	var security:=float(GameState.society_capacities.get("security",0.38))
	return (0.42+security*0.55)*(1.0+_adoption("formation_drill")*0.35+_adoption("professional_corps")*0.55)


func _production_rate()->float:
	var crafting:=maxf(0.20,float(GameState.population_allocations.get("Crafting",0))*0.20)
	return crafting*(0.55+float(GameState.society_capacities.get("production",0.12))*0.45+_adoption("workshop_standards")*0.45)


func _apply_campaign_prisoner_policy(policy:String,count:int,outcome:Dictionary)->void:
	var normalized:=policy.to_lower()
	if normalized in ["release","exchange","parole"]:
		outcome["released_prisoners"]=count
	elif normalized=="ransom":
		GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+count*2.0
		outcome["ransom_income"]=count*2
	elif normalized=="execute":
		outcome["executed_prisoners"]=count
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.06,0.0,1.0)
	elif normalized=="enslave":
		GameState.resource_stockpiles["Forced Labor"]=float(GameState.resource_stockpiles.get("Forced Labor",0.0))+count
		outcome["forced_laborers"]=count
	else:
		foreign_prisoners+=count
		outcome["held_prisoners"]=count


func _apply_campaign_spoils_policy(policy:String,spoils:Dictionary,outcome:Dictionary)->void:
	var weapons:Dictionary=spoils.get("weapons",{})
	var gear_total:=0
	for weapon in weapons:
		var amount:=int(weapons[weapon]); gear_total+=amount
		if policy.to_lower()=="army stores": military_inventory[weapon]=int(military_inventory.get(weapon,0))+amount
	var supplies:=int(spoils.get("supplies",0)); var carts:=int(spoils.get("carts",0)); var wealth:=int(spoils.get("wealth",0))
	match policy.to_lower():
		"army stores":
			GameState.resource_stockpiles["Food"]=float(GameState.resource_stockpiles.get("Food",0.0))+supplies
			GameState.resource_stockpiles["Transport Carts"]=float(GameState.resource_stockpiles.get("Transport Carts",0.0))+carts
			GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+wealth
		"reward troops": home_army["morale"]=clampf(float(home_army.get("morale",0.0))+0.10,0.0,1.5)
		"state treasury": GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+wealth+gear_total*2+supplies+carts*5
		"return property": GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.06,0.0,1.0)
		"unrestricted plunder":
			GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+(wealth+gear_total*2+supplies+carts*5)*1.35
			GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.04,0.0,1.0)
	outcome["spoils"]={"gear":gear_total,"supplies":supplies,"carts":carts,"wealth":wealth}


func _apply_campaign_general_policy(policy:String,aftermath:Dictionary,outcome:Dictionary)->void:
	var general:={"name":String(aftermath.get("commander","Unknown commander")),"captured_day":int(GameState.elapsed_days)}
	if policy.to_lower()=="hold": held_generals.append(general)
	elif policy.to_lower()=="ransom": GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+50.0
	outcome["general_policy"]=policy


func _mark_home_prisoners(count:int)->void:
	var marked:=0
	for soldier_id in home_army.get("soldier_ids",[]):
		if marked>=count: break
		var citizen:Dictionary=GameState.citizen_by_id(int(soldier_id))
		if citizen.is_empty(): continue
		citizen["army_status"]="captured"
		marked+=1


func _record_council_battle(result:Dictionary)->void:
	GameState.council_inbox.push_front({"id":"battle_%d_%d" % [int(GameState.elapsed_days),int(result.seed)],"advisor":String((home_army.get("commander",{}) as Dictionary).get("name","Field command")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":"Battle resolved: %s. %d of our soldiers remain; morale %.0f%%." % [String(result.outcome).replace("_"," ").capitalize(),int(result.attacker.remaining_troops),float(result.attacker.morale)*100.0],"urgency":0.92,"day":int(GameState.elapsed_days),"status":"unread"})


func _aftermath_description(outcome:Dictionary)->String:
	return "Prisoner policy: %s. Spoils policy: %s. General policy: %s." % [outcome.prisoner_policy,outcome.spoils_policy,outcome.general_policy]
