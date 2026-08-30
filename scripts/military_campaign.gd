extends Node

signal army_changed(army: Dictionary)
signal battle_resolved(result: Dictionary)
signal aftermath_required(aftermath: Dictionary)

const COMBAT_SIMULATOR_SCRIPT:=preload("res://scripts/combat_simulator.gd")

var simulator:RefCounted
var home_army:Dictionary={}
var battle_history:Array[Dictionary]=[]
var pending_aftermath:Dictionary={}
var military_inventory:Dictionary={"improvised":0,"spear":0,"bow":0,"sword_shield":0,"lance":0}
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
	foreign_prisoners=0
	held_generals.clear()


func muster_home_army(requested_strength:=-1)->Dictionary:
	GameState.initialize_citizen_registry()
	var desired:=int(GameState.population_allocations.get("Defense",0)) if requested_strength<0 else maxi(0,int(requested_strength))
	desired=mini(desired,GameState.living_citizen_count())
	var candidates:Array[Dictionary]=[]
	for citizen in GameState.living_citizens():
		if String(citizen.get("army_status","civilian")) in ["killed","captured","wounded"]: continue
		if GameState.citizen_age_years(citizen)<16: continue
		candidates.append(citizen)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_defense:=1 if String(a.get("role",""))=="Defense" else 0
		var b_defense:=1 if String(b.get("role",""))=="Defense" else 0
		if a_defense!=b_defense: return a_defense>b_defense
		return GameState.citizen_physical_capacity(a)>GameState.citizen_physical_capacity(b))
	)
	var soldiers:Array[Dictionary]=[]
	for index in mini(desired,candidates.size()):
		var citizen:Dictionary=candidates[index]
		citizen["army_status"]="active"
		citizen["role"]="Defense"
		soldiers.append(citizen)
	var formations:=_formations_for_strength(soldiers.size())
	var force:Dictionary=simulator.create_formation_force(_home_army_name(),formations,_campaign_morale(),1.0)
	force["commander"]=_marshal_commander()
	force["readiness"]=float(simulator.force_readiness(force,_condition_average(soldiers)).aggregate)
	force["soldier_ids"]=soldiers.map(func(person:Dictionary)->int: return int(person.id))
	force["reserve_manpower"]=maxi(0,int(GameState.population_allocations.get("Defense",0))-soldiers.size())
	force["campaign_day"]=int(GameState.elapsed_days)
	home_army=force
	army_changed.emit(home_army.duplicate(true))
	return home_army.duplicate(true)


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
	_record_council_battle(result)
	battle_resolved.emit(result.duplicate(true))
	if not pending_aftermath.is_empty() and String(pending_aftermath.get("type","continued"))!="continued":
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
	if home_army.is_empty(): muster_home_army()
	var snapshot:=home_army.duplicate(true)
	snapshot["foreign_prisoners"]=foreign_prisoners
	snapshot["held_generals"]=held_generals.duplicate(true)
	snapshot["military_inventory"]=military_inventory.duplicate(true)
	return snapshot


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
	home_army=side.duplicate(true)
	home_army["soldier_ids"]=soldier_ids
	home_army["campaign_day"]=int(GameState.elapsed_days)


func _process_military_day()->void:
	if home_army.is_empty() or not pending_aftermath.is_empty(): return
	var logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.5))
	var replacements:=roundi(2.0+float(GameState.population_allocations.get("Logistics",0))*0.25)
	var prepared:Dictionary=simulator.advance_preparation_day(home_army,{"equipment_replacements":replacements,"manpower_replacements":maxi(1,roundi(replacements*0.65)),"organization_recovery":0.025+logistics*0.055})
	home_army=prepared.force
	home_army["campaign_day"]=int(GameState.elapsed_days)
	army_changed.emit(home_army.duplicate(true))


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
