extends Node

signal army_changed(army: Dictionary)
signal battle_resolved(result: Dictionary)
signal battle_started(engagement: Dictionary)
signal aftermath_required(aftermath: Dictionary)
signal threat_changed(threat: Dictionary)
signal settlement_defense_changed(defense: Dictionary)

const COMBAT_SIMULATOR_SCRIPT:=preload("res://scripts/combat_simulator.gd")
const MILITARY_DEVELOPMENT:=preload("res://scripts/military_development_catalog.gd")
const SAVE_VERSION:=7
const MAX_OCCUPATION_FORCES:=40
const ABSOLUTE_MAX_FIELD_ARMIES:=12
const RUNNER_INTERVAL_DAYS:=5
const RUNNER_SPEED_KM_DAY:=30.0
const RUNNERS_PER_ARMY:=2
const MAP_ENGAGEMENT_RANGE_KM:=6.0
const ABSOLUTE_MAX_PRODUCTION_LINES:=12
const FIELD_FORTIFICATION_MAX_BONUS:=0.22
const FORTIFIED_STORES_MAX_PROTECTION:=0.60
const EQUIPMENT_DELIVERY_LOAD:Dictionary={"improvised":0.80,"spear":1.00,"bow":0.80,"sword_shield":1.80,"lance":1.60,"siege_kit":6.00,"field_gun":10.00,"service_rifle":1.15,"machine_gun":8.0,"motorized_kit":12.0,"armored_vehicle":28.0,"modern_field_gun":18.0}
const AMMUNITION_DELIVERY_LOAD:Dictionary={"arrows":0.08,"artillery_rounds":0.65,"small_arms_ammunition":0.04,"heavy_shells":0.90}
# Unit identity, gating, lineage, and fielding data live in the archetype
# catalog (design bible Â§17â€“18); these constants are parse-time views kept for
# the many existing call sites.
const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")
const EQUIPMENT_KNOWLEDGE:Dictionary=UnitCatalog.EQUIPMENT_GATES
const TRAINING_PROGRAMS:Dictionary={
	"route_rehearsal":{"label": "ROUTE & SUPPLY PRACTICE", "duration_days": 18.0, "food_per_participant": 0.07, "training_gain": 0.03, "experience_gain": 0.0, "readiness_gain": 0.04, "fatigue_per_day": 0.00045, "wear_rate": 0.00012, "command_gain": {"logistics": 0.04, "resolve": 0.01}, "description": "Practice load distribution, route finding, and resupply. Builds logistics and resolve across unit types.", "scope": "army", "required_discovery": "", "minimum_adoption": 0.0},
	"reconnaissance_drill":{"label": "RECONNAISSANCE & TERRAIN", "duration_days": 20.0, "food_per_participant": 0.08, "training_gain": 0.045, "experience_gain": 0.01, "readiness_gain": 0.035, "fatigue_per_day": 0.0005, "wear_rate": 0.00015, "command_gain": {"tactics": 0.04, "logistics": 0.01}, "description": "Practice observation, cover, and interpreting terrain. Builds tactics for every type of formation.", "scope": "army", "required_discovery": "", "minimum_adoption": 0.0},
	"rally_drill":{"label": "RALLY & DISCIPLINE", "duration_days": 12.0, "food_per_participant": 0.04, "training_gain": 0.035, "experience_gain": 0.0, "readiness_gain": 0.05, "fatigue_per_day": 0.00025, "wear_rate": 4e-05, "command_gain": {"resolve": 0.04, "command": 0.01}, "description": "Rehearse regrouping and maintaining order under pressure. Builds resolve and command.", "scope": "army", "required_discovery": "", "minimum_adoption": 0.0},
	"signal_drill":{"label": "SIGNALS & COORDINATION", "duration_days": 16.0, "food_per_participant": 0.05, "training_gain": 0.045, "experience_gain": 0.0, "readiness_gain": 0.04, "fatigue_per_day": 0.0002, "wear_rate": 5e-05, "command_gain": {"command": 0.04, "tactics": 0.01}, "description": "Practice messengers, agreed calls, and coordinated movements. Builds command without requiring modern communications.", "scope": "army", "required_discovery": "", "minimum_adoption": 0.0},
	"camp_drill":{"label":"CAMP DRILL","scope":"army","duration_days":14.0,"required_discovery":"","minimum_adoption":0.0,"food_per_participant":0.035,"training_gain":0.065,"experience_gain":0.0,"readiness_gain":0.055,"fatigue_per_day":0.00025,"wear_rate":0.00004,"command_gain":{"resolve":0.008},"description":"Repeated musters, signals, and formation changes. Low cost; improves formation training and short-term readiness."},
	"field_exercise":{"label":"FIELD EXERCISE","scope":"army","duration_days":28.0,"required_discovery":"formation_drill","minimum_adoption":0.08,"food_per_participant":0.12,"training_gain":0.10,"experience_gain":0.025,"readiness_gain":0.085,"fatigue_per_day":0.00065,"wear_rate":0.00028,"command_gain":{"command":0.018,"tactics":0.030,"resolve":0.010},"description":"The field army practices movement, contact, and recovery. Strong army and tactical gains, but higher ration use, fatigue, and equipment wear."},
	"staff_exercise":{"label":"STAFF EXERCISE","scope":"command","duration_days":21.0,"required_discovery":"military_staffs","minimum_adoption":0.08,"food_per_participant":0.09,"training_gain":0.018,"experience_gain":0.0,"readiness_gain":0.035,"fatigue_per_day":0.00008,"wear_rate":0.0,"command_gain":{"command":0.045,"logistics":0.055,"tactics":0.018},"description":"Command cadres rehearse maps, orders, reserves, and supply schedules. Develops command and logistics with little equipment wear."},
	"war_games":{"label":"WAR GAMES","scope":"army","duration_days":42.0,"required_discovery":"professional_corps","minimum_adoption":0.12,"food_per_participant":0.18,"training_gain":0.12,"experience_gain":0.045,"readiness_gain":0.11,"fatigue_per_day":0.00090,"wear_rate":0.00055,"command_gain":{"command":0.035,"tactics":0.060,"logistics":0.025,"resolve":0.025},"description":"Opposed maneuvers test the whole command system. Broadest preparation gains; consumes the most food and wears equipment fastest."}
}
const SETTLEMENT_DEFENSE_STAGES:=[
	{"name":"OPEN SETTLEMENT","short":"Open ground","work":0.0,"materials":{},"defense_bonus":0.0,"observation_km":28.0,"store_protection":0.0,"description":"No prepared perimeter. Defenders rely on terrain and their field formations."},
	{"name":"WATCH POSTS","short":"Watch posts","work":40.0,"materials":{"Timber":10.0,"Fiber Plants":4.0},"defense_bonus":0.04,"observation_km":40.0,"store_protection":0.05,"description":"Raised lookouts and warning posts reveal nearby movement sooner and give defenders time to assemble."},
	{"name":"DITCH AND EARTHWORKS","short":"Earthwork ring","work":180.0,"materials":{"Timber":45.0,"Stone":25.0,"Fiber Plants":12.0},"defense_bonus":0.12,"observation_km":50.0,"store_protection":0.14,"description":"A continuous ditch, berm, and controlled approaches slow an assault around the inhabited core."},
	{"name":"PALISADE AND GATES","short":"Palisade","work":620.0,"materials":{"Timber":180.0,"Stone":75.0,"Fiber Plants":35.0},"defense_bonus":0.24,"observation_km":62.0,"store_protection":0.26,"description":"A defended timber perimeter and gated roads turn the settlement into a prepared strongpoint."},
	{"name":"WALLED DISTRICTS","short":"Walled districts","work":2200.0,"materials":{"Stone":760.0,"Timber":220.0,"Clay":180.0},"defense_bonus":0.40,"observation_km":76.0,"store_protection":0.40,"description":"Linked stone defenses protect the settlement's strategic districts without simulating individual walls."},
	{"name":"BASTION NETWORK","short":"Bastion network","work":7200.0,"materials":{"Stone":2200.0,"Timber":520.0,"Clay":480.0},"defense_bonus":0.62,"observation_km":92.0,"store_protection":0.54,"description":"An integrated defensive network provides deep warning, protected stores, and layered resistance to siege."}
]

var simulator:RefCounted
var home_army:Dictionary={}
var battle_history:Array[Dictionary]=[]
var pending_aftermath:Dictionary={}
var military_inventory:Dictionary={}
var military_consumables:Dictionary={}
var damaged_equipment:Dictionary={}
var aggregate_recruits:=0
var training_queue:Array[Dictionary]=[]
var training_injury_pool:=0
var training_injury_recovery_accumulator:=0.0
var training_program:Dictionary={}
var last_training_program:Dictionary={}
var command_development:Dictionary={"command":0.0,"tactics":0.0,"logistics":0.0,"resolve":0.0}
var training_program_cycles:=0
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
var active_siege:Dictionary={}
var siege_history:Array[Dictionary]=[]
var war_reputation:Dictionary={"mercy":0.0,"fear":0.0,"grievance":0.0}
var occupation_forces:Array[Dictionary]=[]
var occupation_transfers=preload("res://scripts/occupation_transfers.gd").new()
var recovery=preload("res://scripts/siege_recovery.gd").new()
var field_armies:Array[Dictionary]=[]
var next_field_army_id:=1
## Runner messages in flight from field armies back to the settlement. Until
## signal-era development, the government knows only what runners deliver.
var runner_messages:Array[Dictionary]=[]
## Army build templates: a named composition of unit/weapon counts. Training
## fills the build from the recruit pool; deployment lifts matching trained
## formations out of the home force as one field army.
var army_templates:Array[Dictionary]=[]
var next_army_template_id:=1
var settlement_defense:Dictionary={}


func _ready()->void:
	simulator=COMBAT_SIMULATOR_SCRIPT.new()
	if military_inventory.is_empty(): military_inventory=_empty_equipment_inventory()
	if military_consumables.is_empty(): military_consumables=_empty_consumable_inventory()
	if damaged_equipment.is_empty(): damaged_equipment=_empty_equipment_inventory()
	set_process(true)


func _empty_equipment_inventory()->Dictionary:
	var inventory:Dictionary={}
	for item in EQUIPMENT_KNOWLEDGE: inventory[item]=0
	return inventory


func _empty_consumable_inventory()->Dictionary:
	return {"arrows":0,"artillery_rounds":0,"small_arms_ammunition":0,"heavy_shells":0}


func _process(_delta:float)->void:
	if GameState.world_seed!=last_world_seed:
		reset_for_new_world()
	var current_day:=int(GameState.elapsed_days)
	if last_processed_day<0: last_processed_day=current_day
	while last_processed_day<current_day:
		last_processed_day+=1
		_process_military_day()


func reset_for_new_world()->void:
	recovery.reset()
	occupation_transfers.reset()
	last_world_seed=GameState.world_seed
	last_processed_day=int(GameState.elapsed_days)
	home_army={}
	battle_history.clear()
	pending_aftermath.clear()
	active_siege.clear(); siege_history.clear()
	military_inventory=_empty_equipment_inventory()
	military_consumables=_empty_consumable_inventory()
	damaged_equipment=_empty_equipment_inventory()
	aggregate_recruits=0
	training_queue.clear()
	training_injury_pool=0
	training_injury_recovery_accumulator=0.0
	training_program.clear()
	last_training_program.clear()
	command_development={"command":0.0,"tactics":0.0,"logistics":0.0,"resolve":0.0}
	training_program_cycles=0
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
	occupation_forces.clear()
	field_armies.clear()
	runner_messages.clear()
	next_field_army_id=1
	army_templates=_default_army_templates()
	next_army_template_id=army_templates.size()+1
	settlement_defense=_default_settlement_defense()
	settlement_defense_changed.emit(settlement_defense_snapshot())


func muster_home_army(requested_strength:=-1)->Dictionary:
	# Compatibility entry point: reach the requested total mobilized strength,
	# but do not conjure trained or equipped formations. Call start_training()
	# to field recruits. Repeated muster calls must not mobilize the same target twice.
	if home_army.is_empty(): home_army=_empty_home_army()
	var desired:=int(GameState.population_allocations.get("Defense",0)) if requested_strength<0 else maxi(0,int(requested_strength))
	raise_recruits(maxi(0,desired-_mobilized_count()))
	return campaign_army_snapshot()


func raise_recruits(count:int)->Dictionary:
	GameState.initialize_population_model()
	if home_army.is_empty(): home_army=_empty_home_army()
	var capacity:=recruitment_capacity()
	var raised:=mini(maxi(0,count),maxi(0,capacity-_mobilized_count()))
	aggregate_recruits+=raised
	army_changed.emit(home_army.duplicate(true))
	var message:="%d people entered the recruit reserve; %d now await training." % [raised,aggregate_recruits] if raised>0 else "No recruits were raised; mobilization capacity is full or the available labor cohort is exhausted."
	return {"requested":count,"raised":raised,"recruit_reserve":aggregate_recruits,"capacity":capacity,"message":message}

func _stand_down_aggregate(requested:int)->Dictionary:
	var available:=int(home_army.get("troops",0)); var released:=mini(requested,available)
	if released<=0: return {"requested":requested,"released":0,"returned_equipment":{}}
	var remaining:=released; var returned:Dictionary={}; var formations:Array=home_army.get("formations",[])
	for index in range(formations.size()-1,-1,-1):
		if remaining<=0: break
		var formation:Dictionary=formations[index]
		var removed:=mini(remaining,int(formation.get("count",0))); var old_count:=int(formation.get("count",0)); var old_equipment:=int(formation.get("equipment",0))
		var gear:=mini(old_equipment,roundi(float(old_equipment)*float(removed)/maxf(1.0,float(old_count))))
		formation["count"]=old_count-removed; formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",old_count))-removed)
		formation["equipment"]=old_equipment-gear; formation["equipment_required"]=_equipment_required_for(String(formation.get("unit","levy")),int(formation.authorized_count))
		var weapon:=String(formation.get("weapon","improvised")); military_inventory[weapon]=int(military_inventory.get(weapon,0))+gear; returned[weapon]=int(returned.get(weapon,0))+gear
		remaining-=removed
		if int(formation.count)<=0: formations.remove_at(index)
		else: formations[index]=formation
	home_army["formations"]=formations; home_army["troops"]=available-released
	_refresh_readiness()
	return {"requested":requested,"released":released,"returned_equipment":returned}


func stand_down(count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before standing formations down."}
	var requested:=maxi(0,count)
	if requested<=0: return {"error":"Stand-down count must be positive."}
	var result:=_stand_down_aggregate(requested)
	army_changed.emit(home_army.duplicate(true))
	return result


func demobilize(count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before demobilizing personnel."}
	var requested:=maxi(0,count)
	if requested<=0: return {"error":"Demobilization count must be positive."}
	var injured_release:=_demobilize_disabled(requested)
	var recruit_release:=mini(requested-injured_release,aggregate_recruits)
	aggregate_recruits-=recruit_release
	var field_result:={"released":0,"returned_equipment":{}}
	if requested>recruit_release+injured_release: field_result=_stand_down_aggregate(requested-recruit_release-injured_release)
	army_changed.emit(home_army.duplicate(true))
	return {
		"requested":requested,
		"released":injured_release+recruit_release+int(field_result.released),
		"released_injured_veterans":injured_release,
		"released_recruits":recruit_release,
		"released_field_soldiers":int(field_result.get("released",0)),
		"returned_equipment":field_result.get("returned_equipment",{}),
		"message":"%d people returned to civilian life: %d with lasting injuries, %d recruits, %d field troops. Injured veterans remain living population; their effective work capacity depends on the task." % [injured_release+recruit_release+int(field_result.released),injured_release,recruit_release,int(field_result.released)]
	}


func start_training(unit:String,weapon:String,count:int)->Dictionary:
	var gate:=_training_gate(unit,weapon)
	if gate.has("error"): return gate
	var accepted:=mini(maxi(0,count),aggregate_recruits)
	if accepted<=0: return {"error":"No recruits are available for training."}
	var prototype:=bool(gate.get("prototype",false))
	if prototype: accepted=mini(accepted,PROTOTYPE_COHORT_LIMIT)
	var base_training_days:=UnitCatalog.training_days(unit)
	var training_days:=maxf(3.0,base_training_days*(PROTOTYPE_TRAINING_MULTIPLIER if prototype else 1.0))
	var order_id:=next_training_order_id; next_training_order_id+=1
	aggregate_recruits-=accepted
	training_queue.append({"id":order_id,"unit":unit,"weapon":weapon,"count":accepted,"initial_count":accepted,"experience":0.0,"progress_days":0.0,"start_day":int(GameState.elapsed_days),"required_days":training_days,"injury_accumulator":0.0,"prototype":prototype})
	if prototype:
		return {"id":order_id,"accepted":accepted,"unit":unit,"weapon":weapon,"required_days":training_days,"prototype":true,"message":"An experimental cohort of %d begins learning %s from first principles â€” %.0f days at exceptional cost. The practice is understood, not yet established." % [accepted,unit.replace("_"," "),training_days]}
	return {"id":order_id,"accepted":accepted,"unit":unit,"weapon":weapon,"required_days":training_days,"message":"Training begun for %d %s with %s; baseline %.0f days, with %d/%d training places now committed." % [accepted,unit.replace("_"," "),weapon.replace("_"," "),training_days,_queued_trainees(),training_capacity()]}


func training_program_catalog()->Dictionary:
	var catalog:Dictionary={}
	for program_id in TRAINING_PROGRAMS:
		var definition:Dictionary=(TRAINING_PROGRAMS[program_id] as Dictionary).duplicate(true)
		var gate:=_training_program_gate(String(program_id),false)
		definition["unlocked"]=not gate.has("error")
		definition["reason"]=String(gate.get("error",definition.description))
		definition["id"]=String(program_id)
		catalog[program_id]=definition
	return catalog


func training_program_snapshot()->Dictionary:
	_ensure_training_program_state()
	return {
		"active":training_program.duplicate(true),
		"last_completed":last_training_program.duplicate(true),
		"command_development":command_development.duplicate(true),
		"readiness_bonus":clampf(float(home_army.get("exercise_readiness_bonus",0.0)),0.0,0.20),
		"completed_cycles":training_program_cycles,
		"catalog":training_program_catalog()
	}


func start_training_program(program_id:String)->Dictionary:
	_ensure_training_program_state()
	if not training_program.is_empty():
		return {"error":"%s is already under way; complete or cancel it before choosing another program." % String(training_program.get("label","A training program"))}
	var gate:=_training_program_gate(program_id,true)
	if gate.has("error"): return gate
	var definition:Dictionary=(TRAINING_PROGRAMS[program_id] as Dictionary).duplicate(true)
	training_program={
		"id":program_id,
		"label":String(definition.label),
		"scope":String(definition.scope),
		"started_day":int(GameState.elapsed_days),
		"progress_days":0.0,
		"duration_days":float(definition.duration_days),
		"participants":_training_program_participants(definition),
		"food_required_total":0.0,
		"food_consumed_total":0.0,
		"wear_accumulator":0.0,
		"equipment_worn":0,
		"paused_reason":"",
		"last_efficiency":0.0
	}
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"program":training_program.duplicate(true),"message":"%s begun: %.0f effective training days. %s" % [String(definition.label),float(definition.duration_days),String(definition.description)]}


func cancel_training_program()->Dictionary:
	if training_program.is_empty(): return {"error":"No army or command exercise is active."}
	var cancelled:=training_program.duplicate(true)
	training_program.clear()
	army_changed.emit(home_army.duplicate(true))
	return {"cancelled":true,"program":cancelled,"message":"%s cancelled after %.1f of %.0f effective days. Gains already earned remain; spent provisions and equipment wear are not recovered." % [String(cancelled.get("label","Training program")),float(cancelled.get("progress_days",0.0)),float(cancelled.get("duration_days",1.0))]}


func reinforce_formation(formation_id:int,count:int)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before assigning reinforcements."}
	var formation_index:=_formation_index(formation_id)
	if formation_index<0: return {"error":"Formation %d was not found." % formation_id}
	var formation:Dictionary=home_army.formations[formation_index]
	var gate:=_training_gate(String(formation.unit),String(formation.weapon))
	if gate.has("error"): return gate
	var vacancies:=maxi(0,int(formation.get("authorized_count",formation.count))-int(formation.count))
	var accepted:=mini(mini(maxi(0,count),aggregate_recruits),vacancies)
	if accepted<=0: return {"error":"The formation has no open authorized positions or no recruits are available."}
	var base_days:=float({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45,"siege_engineer":48,"field_artillery":60}.get(String(formation.unit),21))
	var order_id:=next_training_order_id; next_training_order_id+=1
	var required_days:=maxf(3.0,base_days*0.58)
	aggregate_recruits-=accepted
	training_queue.append({"id":order_id,"mode":"reinforce","target_formation_id":formation_id,"unit":String(formation.unit),"weapon":String(formation.weapon),"count":accepted,"initial_count":accepted,"experience":0.0,"progress_days":0.0,"start_day":int(GameState.elapsed_days),"required_days":required_days,"injury_accumulator":0.0})
	return {"id":order_id,"accepted":accepted,"target_formation_id":formation_id,"required_days":required_days,"message":"%d replacements entered training for %s; baseline %.0f days before they rejoin formation %d." % [accepted,String(formation.unit).replace("_"," "),required_days,formation_id]}


func retrain_formation(formation_id:int,unit:String,weapon:String)->Dictionary:
	if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before retraining a formation."}
	var formation_index:=_formation_index(formation_id)
	if formation_index<0: return {"error":"Formation %d was not found." % formation_id}
	var gate:=_training_gate(unit,weapon)
	if gate.has("error"): return gate
	var formation:Dictionary=home_army.formations[formation_index]
	var personnel_count:=int(formation.get("count",0))
	if personnel_count<=0: return {"error":"The formation has no active personnel to retrain."}
	var retained_experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
	var old_weapon:=String(formation.get("weapon","improvised"))
	var returned_gear:=int(formation.get("equipment",0))
	military_inventory[old_weapon]=int(military_inventory.get(old_weapon,0))+returned_gear
	var ammunition_type:=_ammunition_type_for(old_weapon)
	var returned_ammunition:=int(formation.get("ammunition",0)) if ammunition_type!="" else 0
	if returned_ammunition>0: military_consumables[ammunition_type]=int(military_consumables.get(ammunition_type,0))+returned_ammunition
	(home_army.formations as Array).remove_at(formation_index)
	home_army["troops"]=maxi(0,int(home_army.get("troops",0))-personnel_count)
	var base_days:=float({"levy":7,"line_infantry":30,"skirmisher":21,"cavalry":45,"siege_engineer":48,"field_artillery":60}.get(unit,21))
	var required_days:=maxf(3.0,base_days*(0.72-retained_experience*0.24))
	var order_id:=next_training_order_id; next_training_order_id+=1
	training_queue.append({"id":order_id,"mode":"retrain","unit":unit,"weapon":weapon,"count":personnel_count,"experience":retained_experience,"progress_days":0.0,"start_day":int(GameState.elapsed_days),"required_days":required_days,"injury_accumulator":0.0})
	_refresh_readiness()
	return {"id":order_id,"accepted":personnel_count,"returned_equipment":returned_gear,"returned_ammunition":returned_ammunition,"required_days":required_days,"message":"%d experienced personnel left the field to retrain as %s with %s; baseline %.0f days." % [personnel_count,unit.replace("_"," "),weapon.replace("_"," "),required_days]}


func cancel_training(order_id:int)->Dictionary:
	for order:Dictionary in training_queue:
		if int(order.get("id",-1))!=order_id:continue
		var batch:=int(order.get("build_batch",-1))
		var returned:=0
		for index in range(training_queue.size()-1,-1,-1):
			var member:Dictionary=training_queue[index]
			if int(member.get("id",-1))!=order_id and (batch<0 or int(member.get("build_batch",-1))!=batch):continue
			returned+=maxi(0,int(member.get("count",0)))
			var weapon:=String(member.get("weapon","improvised"))
			military_inventory[weapon]=int(military_inventory.get(weapon,0))+int(member.get("reserved_equipment",0))
			training_queue.remove_at(index)
		aggregate_recruits+=returned
		if batch>=0:cancel_template_recruitment(batch)
		return {"cancelled":true,"order_id":order_id,"returned":returned,"progress_retained":float(order.get("progress_days",0.0)),"message":"Training cancelled for the whole order; %d personnel returned to the recruit reserve and reserved equipment returned to stores." % returned}
	return {"error":"Training order %d was not found." % order_id}


func queue_equipment_production(item:String,count:int)->Dictionary:
	if not simulator.WEAPONS.has(item): return {"error":"Unknown equipment type: %s" % item}
	var line_gate:=_production_line_gate()
	if line_gate.has("error"): return line_gate
	var gate:=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE.get(item,"")),0.08)
	var amount:=maxi(0,count)
	if amount<=0: return {"error":"Production amount must be positive."}
	var experimental:=false
	if not bool(gate.unlocked):
		# Â§18.1 prototype path: an UNDERSTOOD item can be produced as a small
		# experimental workshop batch (slow, bounded) before it is adopted
		# practice. Tier-gated industry has no such shortcut.
		var item_discovery:=String(EQUIPMENT_KNOWLEDGE.get(item,""))
		var holdings:=int(military_inventory.get(item,0))
		for job_variant in equipment_queue:
			if String((job_variant as Dictionary).get("item",""))==item: holdings+=maxi(0,int((job_variant as Dictionary).get("count",0)))
		if item_discovery!="" and not item_discovery.begins_with("__") and item_discovery in GameState.known_discoveries and holdings+amount<=12:
			experimental=true
		else:
			return {"error":gate.reason,"required_discovery":gate.discovery}
	var recipe:Dictionary=_equipment_recipe(item)
	if experimental: recipe=recipe.duplicate(true); recipe["days"]=float(recipe.days)*2.0
	for material in recipe.materials:
		var required:=float(recipe.materials[material])*amount
		if float(GameState.resource_stockpiles.get(material,0.0))<required:
			return {"error":"Insufficient %s: need %.1f." % [material,required]}
	for material in recipe.materials:
		GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0.0))-float(recipe.materials[material])*amount
	var job_id:=next_equipment_job_id; next_equipment_job_id+=1
	var reserved:Dictionary={}
	for material in recipe.materials: reserved[material]=float(recipe.materials[material])*amount
	equipment_queue.append({"id":job_id,"job_type":"production","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved,"allocation":1.0,"efficiency":0.20,"experimental":experimental})
	if experimental:
		return {"id":job_id,"queued":amount,"item":item,"work_days":float(recipe.days)*amount,"experimental":true,"message":"Queued %d experimental %s â€” understood but unpracticed, at double workshop time. At most 12 can exist before the practice is established." % [amount,item.replace("_"," ")]}
	return {"id":job_id,"queued":amount,"item":item,"work_days":float(recipe.days)*amount,"message":"Queued %d %s; %.1f workshop-days reserved with %d jobs waiting." % [amount,item.replace("_"," "),float(recipe.days)*amount,equipment_queue.size()]}


func queue_consumable_production(item:String,count:int)->Dictionary:
	var line_gate:=_production_line_gate()
	if line_gate.has("error"): return line_gate
	var discovery:=String({"arrows":"bow_craft","artillery_rounds":"powder_artillery","small_arms_ammunition":"__military_tier_5__","heavy_shells":"__military_tier_6__"}.get(item,""))
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
	equipment_queue.append({"id":job_id,"job_type":"consumable","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved,"allocation":1.0,"efficiency":0.20})
	return {"id":job_id,"queued":amount,"item":item,"work_days":float(recipe.days)*amount,"message":"Queued %d %s; %.1f workshop-days reserved with %d jobs waiting." % [amount,item.replace("_"," "),float(recipe.days)*amount,equipment_queue.size()]}


func queue_transport_cart_production(count:int)->Dictionary:
	var line_gate:=_production_line_gate()
	if line_gate.has("error"): return line_gate
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
	equipment_queue.append({"id":job_id,"job_type":"transport","item":"transport_cart","count":amount,"completed":0,"progress_days":0.0,"work_per_item":float(recipe.days),"required_days":float(recipe.days)*amount,"reserved_materials":reserved,"allocation":1.0,"efficiency":0.20})
	return {"id":job_id,"queued":amount,"item":"transport_cart","work_days":float(recipe.days)*amount,"message":"Queued %d transport cart%s; %.1f workshop-days reserved with %d jobs waiting." % [amount,"" if amount==1 else "s",float(recipe.days)*amount,equipment_queue.size()]}


func queue_equipment_repair(item:String,count:int)->Dictionary:
	if not simulator.WEAPONS.has(item): return {"error":"Unknown equipment type: %s" % item}
	var line_gate:=_production_line_gate()
	if line_gate.has("error"): return line_gate
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
	equipment_queue.append({"id":job_id,"job_type":"repair","item":item,"count":amount,"completed":0,"progress_days":0.0,"work_per_item":work_per_item,"required_days":work_per_item*amount,"reserved_materials":reserved,"reserved_damaged":amount,"allocation":1.0,"efficiency":0.35})
	return {"id":job_id,"queued":amount,"item":item,"repair_work_days":work_per_item*amount,"message":"Queued repair of %d %s; %.1f workshop-days reserved." % [amount,item.replace("_"," "),work_per_item*amount]}


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
		return {"cancelled":true,"job_id":job_id,"completed":completed,"unfinished":remaining,"materials_refunded":refunded,"damaged_items_returned":remaining if String(job.get("job_type","production"))=="repair" else 0,"message":"Workshop job %d cancelled; %d completed and %d unfinished units reconciled." % [job_id,completed,remaining]}
	return {"error":"Equipment job %d was not found." % job_id}


func production_line_capacity()->int:
	return clampi(int(military_development_snapshot().get("production_lines",1)),1,ABSOLUTE_MAX_PRODUCTION_LINES)


func _production_line_gate()->Dictionary:
	var capacity:=production_line_capacity()
	if equipment_queue.size()>=capacity:
		return {"error":"All %d military production lines are assigned. Complete or cancel a line, or develop broader production, logistics, institutions, and security capacity." % capacity,"capacity":capacity}
	return {}


func set_production_line_allocation(job_id:int,allocation:float)->Dictionary:
	for index in equipment_queue.size():
		var job:Dictionary=equipment_queue[index]
		if int(job.get("id",-1))!=job_id: continue
		job["allocation"]=clampf(allocation,0.05,4.0)
		equipment_queue[index]=job
		return {"ok":true,"job_id":job_id,"allocation":float(job.allocation),"message":"Production line %d priority set to %.0f%%." % [job_id,float(job.allocation)*100.0]}
	return {"error":"Production line %d was not found." % job_id}


func production_lines_snapshot()->Dictionary:
	var lines:Array[Dictionary]=[]
	var weight_total:=0.0
	for job in equipment_queue: weight_total+=maxf(0.05,float(job.get("allocation",1.0)))
	var total_rate:=_production_rate()
	for job_variant in equipment_queue:
		var job:Dictionary=job_variant
		var weight:=maxf(0.05,float(job.get("allocation",1.0)))
		var share:=weight/maxf(0.05,weight_total)
		var efficiency:=clampf(float(job.get("efficiency",0.20)),0.10,1.0)
		var remaining:=maxf(0.0,float(job.get("required_days",0.0))-float(job.get("progress_days",0.0)))
		lines.append({"id":int(job.get("id",0)),"item":String(job.get("item","equipment")),"job_type":String(job.get("job_type","production")),"ordered":int(job.get("count",0)),"completed":int(job.get("completed",0)),"allocation":weight,"share":share,"efficiency":efficiency,"daily_work":total_rate*share*efficiency,"remaining_work":remaining})
	return {"capacity":production_line_capacity(),"active":lines.size(),"idle":maxi(0,production_line_capacity()-lines.size()),"total_daily_work":total_rate,"lines":lines}


func recruitment_capacity()->int:
	var population:=GameState.able_population()
	var share:=0.04
	if _adoption("watch_rotation")>=0.10: share=0.08
	if _adoption("public_levies")>=0.15: share=0.18
	if _adoption("professional_corps")>=0.20: share=0.30
	return maxi(1,roundi(float(population)*share))


func _mobilized_count()->int:
	return aggregate_recruits+_queued_trainees()+training_injury_pool+int(home_army.get("troops",0))+int(home_army.get("wounded_pool",0))+int(home_army.get("scattered_pool",0))+int(home_army.get("captured_pool",0))+_field_army_force_total()+_occupation_force_total()


# Fixed aggregate categories only. This is the authoritative bridge between
# military readiness and population accounting: mobilization above the Defense
# allocation must displace other work instead of becoming duplicate people.
func personnel_ledger()->Dictionary:
	var wounded:=training_injury_pool
	var absent:=0
	for force in [home_army]+field_armies+occupation_forces:
		wounded+=maxi(0,int(force.get("wounded_pool",0)))
		absent+=maxi(0,int(force.get("scattered_pool",0)))+maxi(0,int(force.get("captured_pool",0)))
	var occupation:=0
	for force in occupation_forces: occupation+=maxi(0,int(force.get("troops",0)))
	return {"total":_mobilized_count(),"home":int(home_army.get("troops",0)),"field":field_army_active_personnel(),"occupation":occupation,"recruits":aggregate_recruits,"training":_queued_trainees(),"recovering":wounded,"missing":absent,"capacity":recruitment_capacity()}


func population_commitment_snapshot()->Dictionary:
	var training_and_reserve:=maxi(0,aggregate_recruits)+maxi(0,_queued_trainees())+maxi(0,training_injury_pool)
	var home:=maxi(0,int(home_army.get("troops",0)))+maxi(0,int(home_army.get("wounded_pool",0)))+maxi(0,int(home_army.get("scattered_pool",0)))+maxi(0,int(home_army.get("captured_pool",0)))
	var field:=maxi(0,_field_army_force_total())
	var occupation:=maxi(0,_occupation_force_total())
	var total:=training_and_reserve+home+field+occupation
	var allocated_defense:=maxi(0,int(GameState.population_allocations.get("Defense",0)))
	return {
		"total":total,"allocated_defense":allocated_defense,"excess_beyond_defense":maxi(0,total-allocated_defense),
		"records":[
			{"id":"training_and_reserve","label":"TRAINING & RECRUIT RESERVE","personnel":training_and_reserve},
			{"id":"home_forces","label":"HOME FORCES","personnel":home},
			{"id":"field_armies","label":"FIELD ARMIES","personnel":field},
			{"id":"occupation_forces","label":"OCCUPATION FORCES","personnel":occupation}
		],
		"bounded":true
	}


func _field_army_force_total()->int:
	var total:=0
	for force in field_armies:
		total+=maxi(0,int(force.get("troops",0)))+maxi(0,int(force.get("wounded_pool",0)))+maxi(0,int(force.get("scattered_pool",0)))+maxi(0,int(force.get("captured_pool",0)))
	return total


func field_army_active_personnel()->int:
	var total:=0
	for force in field_armies: total+=maxi(0,int(force.get("troops",0)))
	return total


func _occupation_force_total()->int:
	var total:=0
	for force in occupation_forces:
		total+=maxi(0,int(force.get("troops",0)))+maxi(0,int(force.get("wounded_pool",0)))+maxi(0,int(force.get("scattered_pool",0)))+maxi(0,int(force.get("captured_pool",0)))
	return total


func occupation_active_personnel()->int:
	var total:=0
	for force in occupation_forces: total+=maxi(0,int(force.get("troops",0)))
	return total


func occupation_force_for_region(civ_id:String,region_id:String)->Dictionary:
	for force in occupation_forces:
		if String(force.get("civ_id",""))==civ_id and String(force.get("region_id",""))==region_id: return force.duplicate(true)
	return {}


func occupation_snapshot()->Array[Dictionary]:
	return occupation_forces.duplicate(true)


func _occupation_force_index(civ_id:String,region_id:String)->int:
	for index in occupation_forces.size():
		if String(occupation_forces[index].get("civ_id",""))==civ_id and String(occupation_forces[index].get("region_id",""))==region_id: return index
	return -1


func establish_occupation_force(civ_id:String,region:Dictionary,required:float,source_field_army_id:int=0)->Dictionary:
	var region_id:=String(region.get("id",""))
	if region_id=="": return {"error":"Occupation target has no strategic-region ID."}
	var existing:=_occupation_force_index(civ_id,region_id)
	if existing>=0: return occupation_forces[existing].duplicate(true)
	if occupation_forces.size()>=MAX_OCCUPATION_FORCES: return {"error":"The bounded occupation-force table is full."}
	var source_index:=_field_army_index(source_field_army_id) if source_field_army_id>0 else -1
	var source_commander:Dictionary=(field_armies[source_index].get("commander",{}) as Dictionary).duplicate(true) if source_index>=0 else (home_army.get("commander",{}) as Dictionary).duplicate(true)
	var fielded:=int(field_armies[source_index].get("troops",0)) if source_index>=0 else int(home_army.get("troops",0))
	var requested:=mini(fielded,maxi(1,ceili(required)))
	var detached:=_detach_field_army_formations(source_field_army_id,requested) if source_index>=0 else _detach_occupation_formations(requested)
	var committed:=0
	for formation in detached: committed+=int(formation.get("count",0))
	if committed<=0: return {"error":"No surviving field personnel were available to hold the captured region.","troops":0,"required":required}
	var force:Dictionary=simulator.create_formation_force("OCCUPATION â€¢ %s" % String(region.get("name","STRATEGIC REGION")),detached,clampf(float(home_army.get("morale",0.55))*0.92,0.20,1.0),clampf(float(home_army.get("readiness",0.45))*0.90,0.15,1.0))
	force["civ_id"]=civ_id
	force["region_id"]=region_id
	force["region_name"]=String(region.get("name","STRATEGIC REGION"))
	force["required"]=required
	force["supply_level"]=clampf(field_provision_delivery_ratio(),0.10,1.0)
	force["committed_day"]=int(GameState.elapsed_days)
	force["commander"]=source_commander
	occupation_forces.append(force)
	_refresh_readiness()
	army_changed.emit(home_army.duplicate(true))
	return force.duplicate(true)


func _detach_field_army_formations(army_id:int,requested:int)->Array[Dictionary]:
	var index:=_field_army_index(army_id)
	if index<0: return []
	# Reuse the exact aggregate split/conservation path used by occupations while
	# keeping the home reserve and maneuver army as distinct bounded records.
	var home_reserve:=home_army
	home_army=field_armies[index].duplicate(true)
	var detached:=_detach_occupation_formations(requested)
	field_armies[index]=home_army
	home_army=home_reserve
	return detached


func _detach_occupation_formations(requested:int)->Array[Dictionary]:
	var detached:Array[Dictionary]=[]
	var remaining:=maxi(0,requested)
	var formations:Array=home_army.get("formations",[])
	for index in range(formations.size()-1,-1,-1):
		if remaining<=0: break
		var formation:Dictionary=formations[index]
		var original_count:=maxi(0,int(formation.get("count",0)))
		if original_count<=0: continue
		var take:=mini(remaining,original_count)
		var split:Dictionary=formation.duplicate(true)
		var equipment_take:=mini(int(formation.get("equipment",0)),roundi(float(formation.get("equipment",0))*float(take)/float(original_count)))
		var ammunition_take:=mini(int(formation.get("ammunition",0)),roundi(float(formation.get("ammunition",0))*float(take)/float(original_count)))
		split["count"]=take
		split["authorized_count"]=take
		split["equipment"]=equipment_take
		split["equipment_required"]=_equipment_required_for(String(split.get("unit","levy")),take)
		split["ammunition"]=ammunition_take
		split["ammunition_required"]=_ammunition_required_for(String(split.get("weapon","improvised")),int(split.equipment_required))
		detached.push_front(split)
		formation["count"]=original_count-take
		formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",original_count))-take)
		formation["equipment"]=maxi(0,int(formation.get("equipment",0))-equipment_take)
		formation["equipment_required"]=_equipment_required_for(String(formation.get("unit","levy")),int(formation.authorized_count))
		formation["ammunition"]=maxi(0,int(formation.get("ammunition",0))-ammunition_take)
		formation["ammunition_required"]=_ammunition_required_for(String(formation.get("weapon","improvised")),int(formation.equipment_required))
		remaining-=take
		if int(formation.count)<=0: formations.remove_at(index)
		else: formations[index]=formation
	home_army["formations"]=formations
	home_army["troops"]=maxi(0,int(home_army.get("troops",0))-(requested-remaining))
	return detached


func remove_occupation_force(civ_id:String,region_id:String,return_survivors:bool=false)->Dictionary:
	var index:=_occupation_force_index(civ_id,region_id)
	if index<0: return {"removed":0}
	var force:Dictionary=occupation_forces[index]
	occupation_forces.remove_at(index)
	var survivors:=maxi(0,int(force.get("troops",0)))
	var wounded:=maxi(0,int(force.get("wounded_pool",0)))
	var scattered:=maxi(0,int(force.get("scattered_pool",0)))
	var captured:=maxi(0,int(force.get("captured_pool",0)))
	var returned_equipment:Dictionary={}
	if return_survivors:
		if survivors+scattered>0: aggregate_recruits+=survivors+scattered
		if wounded>0:
			var disabled:=clampi(int(force.get("disabled_pool",0)),0,wounded)
			training_injury_pool+=wounded-disabled
			home_army["wounded_pool"]=int(home_army.get("wounded_pool",0))+disabled
			home_army["disabled_pool"]=int(home_army.get("disabled_pool",0))+disabled
			home_army["severe_disabled_pool"]=int(home_army.get("severe_disabled_pool",0))+clampi(int(force.get("severe_disabled_pool",0)),0,disabled)
		if captured>0: home_army["captured_pool"]=int(home_army.get("captured_pool",0))+captured
		for formation in force.get("formations",[]):
			var weapon:=String(formation.get("weapon","improvised"))
			var equipment:=maxi(0,int(formation.get("equipment",0)))
			if equipment>0: military_inventory[weapon]=int(military_inventory.get(weapon,0))+equipment; returned_equipment[weapon]=int(returned_equipment.get(weapon,0))+equipment
			var ammunition_type:=_ammunition_type_for(weapon)
			var ammunition:=maxi(0,int(formation.get("ammunition",0)))
			if ammunition_type!="" and ammunition>0: military_consumables[ammunition_type]=int(military_consumables.get(ammunition_type,0))+ammunition
	army_changed.emit(home_army.duplicate(true))
	return {"removed":survivors+wounded+scattered+captured,"returned_to_recruits":survivors+scattered if return_survivors else 0,"returned_to_recovery":wounded if return_survivors else 0,"preserved_captives":captured if return_survivors else 0,"returned_equipment":returned_equipment}


func occupation_action_availability(civ_id:String,region_id:String,action:String)->Dictionary:
	var region:=CivilizationSystem.region_snapshot(civ_id,region_id)
	if region.is_empty(): return {"error":"Select a valid strategic region."}
	if String(region.get("controller",""))!="player": return {"error":"This region is not under your occupation."}
	var force:=occupation_force_for_region(civ_id,region_id)
	match action:
		"reinforce_occupation":
			var source_id:=0
			var available:=0
			for army in field_armies:
				if String(army.get("location_id",""))==region_id and String(army.get("status",""))=="stationed" and int(army.get("troops",0))>available:
					source_id=int(army.army_id); available=int(army.troops)
			if available<=0: return {"error":"March a field army to this region first. Reinforcements must arrive before joining its garrison."}
			var required:=CivilizationSystem.occupation_requirement(CivilizationSystem.civilizations[CivilizationSystem._civilization_index(civ_id)],region)
			var gap:=maxi(1,ceili(required)-int(force.get("troops",0)))
			return {"ok":true,"amount":mini(gap,available),"required":required,"source_army_id":source_id}
		"evacuate_occupation":
			if force.is_empty() or int(force.get("troops",0))<=0: return {"error":"No occupation force is stationed here."}
			if field_armies.size()>=ABSOLUTE_MAX_FIELD_ARMIES: return {"error":"The field-force table is full. Return and dissolve one army before forming this withdrawal column."}
			if not active_engagement.is_empty(): return {"error":"Finish the active battle before ordering a withdrawal march."}
			if _movement_destination("player_home").is_empty(): return {"error":"No known home destination is available for this return march."}
			return {"ok":true,"amount":int(force.get("troops",0))}
	return {"error":"Unknown occupation order."}


func reinforce_occupation(civ_id:String,region_id:String)->Dictionary:
	var availability:=occupation_action_availability(civ_id,region_id,"reinforce_occupation")
	if availability.has("error"): return availability
	var region:=CivilizationSystem.region_snapshot(civ_id,region_id)
	var existing_index:=_occupation_force_index(civ_id,region_id)
	if existing_index<0: return establish_occupation_force(civ_id,region,float(availability.required),int(availability.source_army_id))
	var detached:=_detach_field_army_formations(int(availability.source_army_id),int(availability.amount))
	var force:Dictionary=occupation_forces[existing_index]
	var combined:Array=force.get("formations",[]).duplicate(true)
	combined.append_array(detached)
	var reinforced:Dictionary=simulator.create_formation_force(String(force.get("name","OCCUPATION")),combined,float(force.get("morale",0.55)),float(force.get("readiness",0.45)))
	for key in ["civ_id","region_id","region_name","required","supply_level","committed_day","commander","wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool"]:
		if force.has(key): reinforced[key]=force[key].duplicate(true) if force[key] is Dictionary or force[key] is Array else force[key]
	occupation_forces[existing_index]=reinforced
	_refresh_readiness()
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"transferred":int(availability.amount),"force":reinforced.duplicate(true),"message":"%d trained personnel reinforced %s." % [int(availability.amount),String(region.name)]}


func evacuate_occupation(civ_id:String,region_id:String)->Dictionary:
	var availability:=occupation_action_availability(civ_id,region_id,"evacuate_occupation")
	if availability.has("error"): return availability
	var region:=CivilizationSystem.region_snapshot(civ_id,region_id)
	var occupation_index:=_occupation_force_index(civ_id,region_id)
	var force:Dictionary=occupation_forces[occupation_index].duplicate(true)
	var army_id:=next_field_army_id
	var position:Dictionary=CivilizationSystem.city_intelligence.site(region_id).get("position",{})
	if not CivilizationSystem.city_intelligence.valid_point(position): return {"error":"The occupation's location is unavailable; no return route can be issued."}
	# Transfer the complete record, including injuries, captives and issued gear.
	# A withdrawal can exceed normal command capacity but never the hard bound.
	force.merge({"army_id":army_id,"name":"Withdrawal from %s" % String(region.name),"status":"stationed","location_id":region_id,"location_name":String(region.name),"position":position.duplicate(true),"destination_id":"","distance_total_km":0.0,"distance_remaining_km":0.0,"runner_count":RUNNERS_PER_ARMY,"last_runner_departure_day":int(GameState.elapsed_days)},true)
	force["last_report"]=_army_report_snapshot(force)
	field_armies.append(force)
	var result:=return_field_army(army_id)
	if result.has("error"):
		field_armies.pop_back()
		return result
	next_field_army_id+=1
	occupation_forces.remove_at(occupation_index)
	army_changed.emit(home_army.duplicate(true))
	result["army_id"]=army_id
	result["message"]="The garrison is marching home from %s. Its people and equipment remain with the column until it arrives; the region is now unsupported." % String(region.name)
	return result


func field_army_capacity()->int:
	return clampi(int(military_development_snapshot().get("fronts",1)),1,ABSOLUTE_MAX_FIELD_ARMIES)


func field_armies_snapshot()->Dictionary:
	return {"armies":field_armies.duplicate(true),"active":field_armies.size(),"capacity":field_army_capacity(),"live_reports":_live_army_reporting(),"runner_messages_in_flight":runner_messages.size(),"destinations":CivilizationSystem.military_movement_destinations() if CivilizationSystem!=null and CivilizationSystem.has_method("military_movement_destinations") else []}


func set_formation_visual(army_id:int,formation_id:int,model_id:String)->Dictionary:
	if not active_engagement.is_empty(): return {"error":"Finish the active engagement before changing appearance."}
	var force:Dictionary=home_army
	if army_id!=0:
		var index:=_field_army_index(army_id)
		if index<0: return {"error":"Field army was not found."}
		force=field_armies[index]
	for formation:Dictionary in force.get("formations",[]):
		if int(formation.get("id",-1))!=formation_id: continue
		var options:Array=UnitVisualCatalog.VARIANTS.get(String(formation.get("unit","")),[])
		if model_id!="" and not model_id in options: return {"error":"That appearance is not available for this formation."}
		formation["visual_model"]=model_id
		army_changed.emit(home_army.duplicate(true))
		return {"message":"Appearance updated. Equipment, strength, and combat role are unchanged."}
	return {"error":"Formation was not found."}


func set_army_visual_theme(army_id:int,theme:String)->Dictionary:
	if not theme in UnitVisualCatalog.THEMES: return {"error":"Unknown appearance."}
	if not active_engagement.is_empty(): return {"error":"Finish the active engagement before changing appearance."}
	var force:Dictionary=home_army
	if army_id!=0:
		var index:=_field_army_index(army_id)
		if index<0: return {"error":"Field army was not found."}
		force=field_armies[index]
	force["visual_theme"]=theme
	var formations:Array=force.get("formations",[])
	for i in formations.size():
		formations[i].erase("visual_model")
		formations[i]["visual_model"]=UnitVisualCatalog.model(formations[i],theme,i)
	army_changed.emit(home_army.duplicate(true))
	return {"message":"Army appearance updated. No equipment or combat statistics changed."}


func front_force_snapshot(civ_id:String,region_id:String)->Dictionary:
	# Front consumers need assignment totals, not formation arrays. Keep this one
	# bounded record per maneuver army and never infer that the home reserve is at
	# a distant objective merely because a war exists.
	var stationed:=0
	var inbound:=0
	var weighted_supply:=0.0
	var weighted_readiness:=0.0
	var assigned:Array[Dictionary]=[]
	for force_variant in field_armies:
		var force:Dictionary=force_variant
		var status:=String(force.get("status","stationed"))
		var assigned_here:=status=="stationed" and String(force.get("location_id",""))==region_id
		var inbound_here:=status=="moving" and String(force.get("destination_id",""))==region_id
		if not assigned_here and not inbound_here: continue
		var personnel:=maxi(0,int(force.get("troops",0)))
		if assigned_here:
			stationed+=personnel
			weighted_supply+=float(force.get("supply_level",0.0))*float(personnel)
			weighted_readiness+=float(force.get("readiness",0.0))*float(personnel)
		else:
			inbound+=personnel
		assigned.append({"army_id":int(force.get("army_id",0)),"name":String(force.get("name","FIELD ARMY")),"status":status,"personnel":personnel,"supply":float(force.get("supply_level",0.0)),"readiness":float(force.get("readiness",0.0)),"eta_day":int(force.get("arrival_day",-1)) if inbound_here else -1})
	var occupation:=occupation_force_for_region(civ_id,region_id)
	var occupation_personnel:=maxi(0,int(occupation.get("troops",0)))
	var effective_personnel:=stationed+occupation_personnel
	var effective_supply:=0.0
	var effective_readiness:=0.0
	if effective_personnel>0:
		effective_supply=(weighted_supply+float(occupation.get("supply_level",0.0))*float(occupation_personnel))/float(effective_personnel)
		effective_readiness=(weighted_readiness+float(occupation.get("readiness",0.0))*float(occupation_personnel))/float(effective_personnel)
	return {"civ_id":civ_id,"region_id":region_id,"field_personnel":stationed,"inbound_personnel":inbound,"occupation_personnel":occupation_personnel,"effective_personnel":effective_personnel,"reserve_personnel":maxi(0,int(home_army.get("troops",0)))+maxi(0,aggregate_recruits),"supply":clampf(effective_supply,0.0,1.25),"readiness":clampf(effective_readiness,0.0,1.25),"armies":assigned,"bounded":true}


func _field_army_index(army_id:int)->int:
	for index in field_armies.size():
		if int(field_armies[index].get("army_id",0))==army_id: return index
	return -1


func _movement_destination(destination_id:String)->Dictionary:
	if destination_id=="player_home" and recovery.home_unavailable():return {}
	if CivilizationSystem==null or not CivilizationSystem.has_method("military_movement_destinations"): return {}
	for destination_variant in CivilizationSystem.military_movement_destinations():
		var destination:Dictionary=destination_variant
		if String(destination.get("id",""))==destination_id: return destination.duplicate(true)
	return {}


func create_field_army(personnel:int,custom_name:String="")->Dictionary:
	if not active_engagement.is_empty() or not pending_aftermath.is_empty(): return {"error":"Finish the active battle and aftermath before reorganizing armies."}
	if field_armies.size()>=field_army_capacity(): return {"error":"Command capacity is full: %d/%d field armies. Broader security, logistics, production, and institutions expand it." % [field_armies.size(),field_army_capacity()]}
	var requested:=maxi(0,personnel)
	var available:=maxi(0,int(home_army.get("troops",0)))
	if requested<=0: return {"error":"Choose a positive number of trained personnel."}
	if requested>available: return {"error":"Only %d unassigned trained personnel are at home." % available}
	var detached:=_detach_occupation_formations(requested)
	return _assemble_field_army(detached,custom_name)


func _assemble_field_army(detached:Array[Dictionary],custom_name:String="")->Dictionary:
	var actual:=0
	for formation in detached: actual+=maxi(0,int(formation.get("count",0)))
	if actual<=0: return {"error":"No trained formations could be assigned."}
	var army_id:=next_field_army_id; next_field_army_id+=1
	var label:=custom_name.strip_edges()
	if label=="": label="%s Army" % _ordinal_army_name(army_id)
	var force:Dictionary=simulator.create_formation_force(label,detached,float(home_army.get("morale",_campaign_morale())),float(home_army.get("readiness",0.5)))
	var home_destination:=_movement_destination("player_home")
	force["army_id"]=army_id
	force["status"]="stationed"
	force["location_id"]="player_home"
	force["location_name"]=String(home_destination.get("label","HOME SETTLEMENT"))
	force["position"]=(home_destination.get("position",{"x":0.0,"z":0.0}) as Dictionary).duplicate(true)
	force["destination_id"]=""
	force["destination_name"]=""
	force["destination_position"]={}
	force["distance_total_km"]=0.0
	force["distance_remaining_km"]=0.0
	force["departure_day"]=-1
	force["arrival_day"]=-1
	force["supply_level"]=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
	force["commander"]=HistoricalFigures.commander(_acting_field_commander(false),"army_%d" % army_id)
	force["visual_theme"]=String(home_army.get("visual_theme","equipment"))
	# Runners carry the army's reports home; without them (and before signal-era
	# development) the government would know nothing of a distant force.
	force["exercise_readiness_bonus"]=float(home_army.get("exercise_readiness_bonus",0.0))
	force["runner_count"]=RUNNERS_PER_ARMY
	force["last_runner_departure_day"]=int(GameState.elapsed_days)
	force["last_report"]=_army_report_snapshot(force)
	field_armies.append(force)
	_refresh_readiness()
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"army":force.duplicate(true),"message":"%s formed with %d trained personnel. Select a known destination and issue MOVE." % [label,actual]}


func _ordinal_army_name(number:int)->String:
	var suffix:="TH"
	if number%100 not in [11,12,13]:
		if number%10==1: suffix="ST"
		elif number%10==2: suffix="ND"
		elif number%10==3: suffix="RD"
	return "%d%s FIELD" % [number,suffix]


func _field_army_speed(force:Dictionary)->float:
	# Sustained daily marches, including rest and baggage. A motorized escort
	# cannot carry an attached infantry or siege column merely by averaging.
	var slowest:=INF
	var personnel:=0
	var quality:=0.0
	for formation_variant in force.get("formations",[]):
		var formation:Dictionary=formation_variant
		var count:=maxi(0,int(formation.get("count",0)))
		if count==0: continue
		var unit:=String(formation.get("unit","levy"))
		var pace:=float({"levy":24.0,"line_infantry":26.0,"skirmisher":32.0,"cavalry":55.0,"siege_engineer":14.0,"field_artillery":18.0,"rifle_infantry":28.0,"machine_gun_company":22.0,"motorized_infantry":140.0,"armored_formation":95.0,"modern_artillery":80.0}.get(unit,24.0))
		slowest=minf(slowest,pace)
		quality+=count*(0.65+0.20*clampf(float(formation.get("training",0.5)),0.0,1.0)+0.15*clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0))
		personnel+=count
	if personnel==0: return 0.0
	var logistics:=clampf(float((force.get("commander",{}) as Dictionary).get("logistics",0.4))*0.35+float(GameState.simulation_metrics.get("logistics",0.16))*0.35+float(force.get("supply_level",0.5))*0.30,0.15,1.0)
	return maxf(2.0,slowest*(quality/float(personnel))*(0.55+logistics*0.45)*(0.5+0.5*clampf(float(force.get("supply_level",0.5)),0.0,1.0)))


func move_field_army(army_id:int,destination_id:String)->Dictionary:
	if not active_siege.is_empty() and int(active_siege.army_id)==army_id: return {"error":"Lift the siege before moving its investing army."}
	var index:=_field_army_index(army_id)
	if index<0: return {"error":"Select a valid field army."}
	if int(field_armies[index].get("troops",0))<=0:return {"error":"This force has no active soldiers. Its remaining recovery and occupation records are available in Military."}
	if not active_engagement.is_empty(): return {"error":"Finish the active engagement before issuing another strategic move."}
	var destination:=_movement_destination(destination_id)
	if destination.is_empty(): return {"error":"That destination is unknown. Only returned exploration and contact reports can support an army movement order."}
	var army:Dictionary=field_armies[index]
	army.erase("city_operation")
	var current_position:Dictionary=army.get("position",{})
	var target_position:Dictionary=destination.get("position",{})
	var start:=Vector2(float(current_position.get("x",0.0)),float(current_position.get("z",0.0)))
	var target:=Vector2(float(target_position.get("x",0.0)),float(target_position.get("z",0.0)))
	var distance:=start.distance_to(target)
	if distance<0.5:
		army["status"]="stationed"; army["location_id"]=destination_id; army["location_name"]=String(destination.get("label",destination_id)); army["position"]=target_position.duplicate(true); army["destination_id"]=""; army["distance_remaining_km"]=0.0; field_armies[index]=army
		return {"ok":true,"message":"%s is already at %s." % [String(army.name),String(army.location_name)]}
	var speed:=_field_army_speed(army)
	army["status"]="moving"
	army["origin_position"]=current_position.duplicate(true)
	army["destination_id"]=destination_id
	army["destination_name"]=String(destination.get("label",destination_id))
	army["destination_position"]=target_position.duplicate(true)
	army["distance_total_km"]=distance
	army["distance_remaining_km"]=distance
	army["departure_day"]=int(GameState.elapsed_days)
	army["arrival_day"]=int(GameState.elapsed_days)+ceili(distance/maxf(0.1,speed))
	army["speed_km_day"]=speed
	field_armies[index]=army
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"army":army.duplicate(true),"message":"%s is moving to %s: %.0f km, about %d days at %.1f km/day." % [String(army.name),String(army.destination_name),distance,ceili(distance/maxf(0.1,speed)),speed]}


func move_field_army_to_position(army_id:int,x:float,z:float,label:String="FIELD POSITION")->Dictionary:
	if not active_siege.is_empty() and int(active_siege.army_id)==army_id: return {"error":"Lift the siege before moving its investing army."}
	## Map-order movement to a free position on scouted ground. The caller (the
	## map layer) validates that the point is charted, dry land before issuing;
	## this guard re-checks so a stray order can never march into the unknown.
	var index:=_field_army_index(army_id)
	if index<0: return {"error":"Select a valid field army."}
	if int(field_armies[index].get("troops",0))<=0:return {"error":"This force has no active soldiers. Its remaining recovery and occupation records are available in Military."}
	if not active_engagement.is_empty(): return {"error":"Finish the active engagement before issuing another strategic move."}
	var target:=Vector2(x,z)
	if CivilizationSystem!=null:
		if CivilizationSystem.has_method("_position_is_revealed") and not CivilizationSystem._position_is_revealed(target):
			return {"error":"That ground is uncharted. Armies march only where returned scout reports have charted land; send scouts first."}
		if CivilizationSystem.has_method("_scout_land_at") and not CivilizationSystem._scout_land_at(target):
			return {"error":"That point is open water. Armies need a charted land destination."}
	var army:Dictionary=field_armies[index]
	army.erase("city_operation")
	var current_position:Dictionary=army.get("position",{})
	var start:=Vector2(float(current_position.get("x",0.0)),float(current_position.get("z",0.0)))
	var distance:=start.distance_to(target)
	if distance<0.5: return {"ok":true,"message":"%s is already at that position." % String(army.get("name","The army"))}
	var speed:=_field_army_speed(army)
	army["status"]="moving"
	army["origin_position"]=current_position.duplicate(true)
	army["destination_id"]="field_position"
	army["destination_name"]=label
	army["destination_position"]={"x":target.x,"z":target.y}
	army["distance_total_km"]=distance
	army["distance_remaining_km"]=distance
	army["departure_day"]=int(GameState.elapsed_days)
	army["arrival_day"]=int(GameState.elapsed_days)+ceili(distance/maxf(0.1,speed))
	army["speed_km_day"]=speed
	field_armies[index]=army
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"army":army.duplicate(true),"message":"%s marches to the marked ground: %.0f km, about %d days at %.1f km/day. Runners will carry its reports home." % [String(army.name),distance,ceili(distance/maxf(0.1,speed)),speed]}


func map_engagement_availability(army_id:int,formation_id:String)->Dictionary:
	if not active_siege.is_empty():return {"can_order":false,"can_engage":false,"error":"Resolve the current siege first."}
	var index:=_field_army_index(army_id)
	if index<0: return {"can_order":false,"can_engage":false,"error":"Select one field army first."}
	if not active_engagement.is_empty(): return {"can_order":false,"can_engage":false,"error":"Finish the active battle before ordering another engagement."}
	if not active_threat.is_empty(): return {"can_order":false,"can_engage":false,"error":"Resolve the active campaign decision before ordering another engagement."}
	if not pending_aftermath.is_empty(): return {"can_order":false,"can_engage":false,"error":"Resolve the current battle aftermath first."}
	var sighting:Dictionary=CivilizationSystem.visible_formation_sighting(formation_id)
	if sighting.is_empty(): return {"can_order":false,"can_engage":false,"error":"Contact has been lost. Reacquire the formation before issuing an order."}
	var army:Dictionary=field_armies[index]
	if int(army.get("troops",0))<=0: return {"can_order":false,"can_engage":false,"error":"The selected field army has no personnel able to fight."}
	var army_position:Dictionary=army.get("position",{})
	var target_position:Dictionary=sighting.get("position",{})
	var distance:=Vector2(float(army_position.get("x",0.0)),float(army_position.get("z",0.0))).distance_to(Vector2(float(target_position.get("x",0.0)),float(target_position.get("z",0.0))))
	return {"can_order":true,"can_engage":distance<=MAP_ENGAGEMENT_RANGE_KM,"distance_km":distance,"army":army.duplicate(true),"sighting":sighting.duplicate(true)}


func order_field_army_intercept(army_id:int,formation_id:String)->Dictionary:
	var availability:=map_engagement_availability(army_id,formation_id)
	if not bool(availability.get("can_order",false)): return {"error":String(availability.get("error","No engagement order can be issued."))}
	if bool(availability.get("can_engage",false)): return launch_map_engagement(army_id,formation_id)
	var sighting:Dictionary=availability.sighting
	var position:Dictionary=sighting.get("position",{})
	var label:="INTERCEPT Â· %s" % String(sighting.get("label","FOREIGN FORMATION"))
	var result:=move_field_army_to_position(army_id,float(position.get("x",0.0)),float(position.get("z",0.0)),label)
	if not bool(result.get("ok",false)): return result
	var index:=_field_army_index(army_id)
	if index>=0:
		field_armies[index]["target_formation_id"]=formation_id
		field_armies[index]["order_kind"]="intercept"
		result["army"]=field_armies[index].duplicate(true)
	result["underway"]=true
	result["message"]="INTERCEPT ORDER UNDERWAY â€” %s is tracking %s. If contact holds, battle begins automatically at close range." % [String((result.get("army",{}) as Dictionary).get("name","The army")),String(sighting.get("label","the foreign formation"))]
	return result


func launch_map_engagement(army_id:int,formation_id:String)->Dictionary:
	var availability:=map_engagement_availability(army_id,formation_id)
	if not bool(availability.get("can_engage",false)):
		return {"error":String(availability.get("error","Move the selected army into contact first.")) if not bool(availability.get("can_order",false)) else "The selected army is %.0f km away. Order an intercept before attempting battle." % float(availability.get("distance_km",0.0))}
	var army:Dictionary=availability.army
	if bool((availability.sighting as Dictionary).get("carries_report",false)):
		var caught:=CivilizationSystem.resolve_foreign_scout_interception(formation_id,"capture",-1.0,army_id)
		var pursuit_index:=_field_army_index(army_id)
		if pursuit_index>=0:
			field_armies[pursuit_index]["status"]="stationed"
			field_armies[pursuit_index].erase("target_formation_id")
			field_armies[pursuit_index].erase("order_kind")
		return caught
	var incident:Dictionary=CivilizationSystem.foreign_formation_engagement_data(formation_id,int(army.get("troops",0)))
	if incident.has("error"): return incident
	incident["field_army_id"]=army_id
	_create_civilization_threat(incident,"offensive")
	active_threat["field_encounter"]=true
	active_threat["formation_id"]=formation_id
	var index:=_field_army_index(army_id)
	if index>=0:
		field_armies[index].erase("target_formation_id")
		field_armies[index].erase("order_kind")
	var engagement:=begin_threat_engagement()
	if engagement.has("error"):return engagement
	active_engagement.threat["war_id"]=CivilizationSystem.record_player_hostile_order(String(incident.source_civ_id),"","A player army attacked a foreign field force.")
	return {"ok":true,"engagement_started":true,"engagement":engagement,"message":"CONTACT â€” %s has engaged %s. Open WAR PLANNING to order HOLD, PUSH, or RETREAT." % [String(army.get("name","The field army")),String((availability.sighting as Dictionary).get("label","the enemy formation"))]}


func return_field_army(army_id:int)->Dictionary:
	return move_field_army(army_id,"player_home")


func disband_field_army(army_id:int)->Dictionary:
	if recovery.home_unavailable():return {"error":"The home settlement is occupied. Reach a free settlement before dissolving the army."}
	var index:=_field_army_index(army_id)
	if index<0: return {"error":"Select a valid field army."}
	var army:Dictionary=field_armies[index]
	if String(army.get("status","stationed"))!="stationed" or String(army.get("location_id",""))!="player_home": return {"error":"Return the army home before releasing it to the unassigned field pool."}
	var additions:Array=(army.get("formations",[]) as Array).duplicate(true)
	field_armies.remove_at(index)
	_rebuild_home_army_with(additions)
	for pool in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool"]:
		home_army[pool]=int(home_army.get(pool,0))+int(army.get(pool,0))
	army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"returned":int(army.get("troops",0)),"message":"%s dissolved at home; %d trained personnel and their issued equipment returned to the unassigned field pool." % [String(army.get("name","Field army")),int(army.get("troops",0))]}


# --- Army builds (templates) -------------------------------------------------

func _default_army_templates()->Array[Dictionary]:
	# The starter build must respect the same mobilization ceiling the player's
	# own designs are clamped to, or TRAIN under-delivers on day one.
	return [{"template_id":1,"name":"LEVY BAND","entries":[{"unit":"levy","weapon":"improvised","count":clampi(recruitment_capacity(),1,20)}]}]


func _ensure_army_templates()->void:
	if army_templates.is_empty():
		army_templates=_default_army_templates()
		next_army_template_id=army_templates.size()+1


func _template_index(template_id:int)->int:
	_ensure_army_templates()
	for index in army_templates.size():
		if int((army_templates[index] as Dictionary).get("template_id",0))==template_id: return index
	return -1


func _matching_home_count(unit:String,weapon:String)->int:
	var total:=0
	for formation_variant in home_army.get("formations",[]):
		var formation:Dictionary=formation_variant
		if String(formation.get("unit",""))==unit and String(formation.get("weapon",""))==weapon: total+=maxi(0,int(formation.get("count",0)))
	return total


func _matching_training_count(unit:String,weapon:String)->int:
	var total:=0
	for order_variant in training_queue:
		var order:Dictionary=order_variant
		if String(order.get("mode",""))=="reinforce": continue
		if String(order.get("unit",""))==unit and String(order.get("weapon",""))==weapon: total+=maxi(0,int(order.get("count",0)))
	return total


func army_template_snapshot()->Dictionary:
	_ensure_army_templates()
	var capabilities_units:Dictionary={}
	for unit in UnitCatalog.ARCHETYPES: capabilities_units[unit]=_knowledge_gate(UnitCatalog.gate_for(unit),0.10)
	var templates:Array[Dictionary]=[]
	for template_variant in army_templates:
		var template:Dictionary=template_variant
		var entries:Array[Dictionary]=[]
		var required_total:=0
		var ready_total:=0
		var training_total:=0
		var deployable:=true
		for entry_variant in (template.get("entries",[]) as Array):
			var entry:Dictionary=entry_variant
			var unit:=String(entry.get("unit","levy"))
			var weapon:=String(entry.get("weapon","improvised"))
			var count:=maxi(0,int(entry.get("count",0)))
			var ready:=_matching_home_count(unit,weapon)
			var training:=mini(_matching_training_count(unit,weapon),maxi(0,count-ready))
			required_total+=count
			ready_total+=mini(ready,count)
			training_total+=training
			if ready<count: deployable=false
			entries.append({"unit":unit,"weapon":weapon,"count":count,"ready":mini(ready,count),"home_available":ready,"in_training":training,"unfilled":maxi(0,count-ready-training),"unlocked":bool((capabilities_units.get(unit,{}) as Dictionary).get("unlocked",false)) if capabilities_units.get(unit) is Dictionary else true})
		templates.append({"template_id":int(template.get("template_id",0)),"name":String(template.get("name","ARMY BUILD")),"entries":entries,"required_total":required_total,"ready_total":ready_total,"in_training_total":training_total,"deployable":deployable and required_total>0 and field_armies.size()<field_army_capacity(),"missing":maxi(0,required_total-ready_total),"unfilled":maxi(0,required_total-ready_total-training_total),"recruitment_requested":bool(template.get("recruitment_requested",false)),"blocker":" ".join(template_training_quote(int(template.template_id)).get("blockers",[]))})
	return {"templates":templates,"recruit_reserve":aggregate_recruits,"army_capacity":field_army_capacity(),"armies_active":field_armies.size()}


func create_army_template(name:String="")->Dictionary:
	if army_templates.size()>=8: return {"error":"Keep at most eight army builds; delete one first."}
	var label:=name.strip_edges()
	if label=="": label="BUILD %d" % next_army_template_id
	var template:Dictionary={"template_id":next_army_template_id,"name":label.to_upper(),"entries":[]}
	next_army_template_id+=1
	army_templates.append(template)
	return {"ok":true,"template":template.duplicate(true)}


func delete_army_template(template_id:int)->Dictionary:
	var index:=_template_index(template_id)
	if index<0: return {"error":"That army build no longer exists."}
	if army_templates.size()<=1: return {"error":"Keep at least one army build."}
	army_templates.remove_at(index)
	return {"ok":true}


func adjust_template_entry(template_id:int,unit:String,weapon:String,delta:int)->Dictionary:
	var index:=_template_index(template_id)
	if index<0: return {"error":"That army build no longer exists."}
	var gate:=_training_gate(unit,weapon)
	if gate.has("error"): return gate
	var template:Dictionary=army_templates[index]
	var entries:Array=template.get("entries",[])
	var applied:=delta
	if delta>0:
		# A build is a mobilization order. Its target can never exceed what the
		# society could actually raise, otherwise TRAIN silently under-delivers.
		var planned:=0
		for entry_variant in entries: planned+=maxi(0,int((entry_variant as Dictionary).get("count",0)))
		applied=mini(delta,maxi(0,recruitment_capacity()-planned))
		if applied<=0: return {"error":"Mobilization capacity is %d and this build already claims all of it. Population growth and security practices such as an organized watch or public levies raise the ceiling." % recruitment_capacity()}
	var found:=false
	for entry_index in range(entries.size()-1,-1,-1):
		var entry:Dictionary=entries[entry_index]
		if String(entry.get("unit",""))!=unit or String(entry.get("weapon",""))!=weapon: continue
		entry["count"]=maxi(0,int(entry.get("count",0))+applied)
		found=true
		if int(entry.count)<=0: entries.remove_at(entry_index)
		else: entries[entry_index]=entry
		break
	if not found and applied>0:
		entries.append({"unit":unit,"weapon":weapon,"count":applied})
	template["entries"]=entries
	army_templates[index]=template
	var result:Dictionary={"ok":true,"template":template.duplicate(true)}
	if applied<delta: result["message"]="Added %d of %d â€” the build is now at the mobilization capacity of %d." % [applied,delta,recruitment_capacity()]
	return result


func template_training_quote(template_id:int)->Dictionary:
	var index:=_template_index(template_id)
	if index<0:return {"error":"Build not found."}
	var template:Dictionary=army_templates[index]
	var required:=0;var missing:=0;var active:=0;var shortfalls:Array[Dictionary]=[]
	var blockers:Array[String]=[];var equipment:Dictionary={};var baseline_days:=0.0
	for entry:Dictionary in template.get("entries",[]):
		var unit:=String(entry.unit);var weapon:=String(entry.weapon);var count:=int(entry.count)
		var gate:=_training_gate(unit,weapon)
		if gate.has("error"):blockers.append(String(gate.error))
		var home:=_matching_home_count(unit,weapon);var training:=_matching_training_count(unit,weapon)
		var need:=maxi(0,count-home-training)
		if bool(gate.get("prototype",false)) and need>PROTOTYPE_COHORT_LIMIT:blockers.append("Prototype intake exceeds the experimental cohort limit.")
		required+=count;missing+=need;active+=training
		if need>0:shortfalls.append({"unit":unit,"weapon":weapon,"missing":need})
		baseline_days=maxf(baseline_days,UnitCatalog.training_days(unit))
		var held:=0
		for formation:Dictionary in home_army.get("formations",[]):
			if String(formation.get("unit",""))==unit and String(formation.get("weapon",""))==weapon:held+=int(formation.get("equipment",0))
		equipment[weapon]=int(equipment.get(weapon,0))+maxi(0,_equipment_required_for(unit,count)-held)
	if active>0:blockers.append("%d people are already training; the next full intake waits for their outcome." % active)
	if required>training_capacity()-_queued_trainees():blockers.append("Full-build class needs %d places; %d available. More Defense instructors or established training practices expand capacity." % [required,maxi(0,training_capacity()-_queued_trainees())])
	var people_room:=aggregate_recruits+maxi(0,recruitment_capacity()-_mobilized_count())
	if missing>people_room:blockers.append("%d recruits needed; %d can currently be mobilized." % [missing,people_room])
	for weapon:String in equipment:
		var shortfall:=maxi(0,int(equipment[weapon])-int(military_inventory.get(weapon,0)))
		if shortfall>0:blockers.append("%d %s equipment sets missing; produce them in Supply." % [shortfall,weapon.replace("_"," ")])
	var food:=float(required)*baseline_days
	if FoodSystem.total_stored()<food:blockers.append("At least %.0f rations needed for the full class; %.0f stored." % [food,FoodSystem.total_stored()])
	if not active_engagement.is_empty() or not pending_aftermath.is_empty():blockers.append("Resolve the battle or aftermath first.")
	if recovery.home_unavailable():blockers.append("Home is occupied.")
	return {"can_start":blockers.is_empty() and missing>0,"missing":missing,"required":required,"shortfalls":shortfalls,"blockers":blockers,"food":food}
func queue_template_training(template_id:int,retain_order:bool=true)->Dictionary:
	var index:=_template_index(template_id)
	if index<0:return {"error":"Build not found."}
	var template:Dictionary=army_templates[index]
	if retain_order:template.recruitment_requested=true
	var quote:=template_training_quote(template_id)
	if int(quote.get("missing",0))<=0:return {"ok":true,"queued":0,"message":"The build's people are assembled or already training. Check condition and equipment before deployment."}
	if not bool(quote.get("can_start",false)):
		return {"ok":true,"queued":0,"waiting":true,"message":"WAITING — no partial intake started. "+" ".join(quote.get("blockers",[]))}
	# All entries pass together before any people or equipment move.
	var needed:=int(quote.missing)
	if aggregate_recruits<needed:raise_recruits(needed-aggregate_recruits)
	var queued:=0
	for entry:Dictionary in template.get("entries",[]):
		var unit:=String(entry.unit);var weapon:=String(entry.weapon);var count:=int(entry.count)
		var existing:=mini(count,_matching_home_count(unit,weapon))
		var detached:=_detach_matching_formations([{"unit":unit,"weapon":weapon,"count":existing}]) if existing>0 else []
		var experience_sum:=0.0;var condition_sum:=float(count-existing)*_trainee_condition();var skill_sum:=0.0
		for formation:Dictionary in detached:
			var people:=int(formation.count)
			experience_sum+=float(formation.get("experience",0))*people
			condition_sum+=float(formation.get("personnel_condition",1))*people
			skill_sum+=float(formation.get("training",0))*people
			military_inventory[weapon]=int(military_inventory.get(weapon,0))+int(formation.get("equipment",0))
			# Ammunition remains in the home stock, not lost during instruction.
			var ammo:=_ammunition_type_for(weapon)
			if ammo!="":military_consumables[ammo]=int(military_consumables.get(ammo,0))+int(formation.get("ammunition",0))
		aggregate_recruits+=existing
		var result:=start_training(unit,weapon,count)
		var order:Dictionary=training_queue[-1]
		order.build_batch=template_id;order.experience=experience_sum/maxi(1,count)
		order.prior_skill=skill_sum/maxi(1,existing);order.prior_personnel=existing
		order.personnel_condition=condition_sum/maxi(1,count)
		var reserved:=_equipment_required_for(unit,count)
		order.reserved_equipment=reserved
		military_inventory[weapon]=int(military_inventory.get(weapon,0))-reserved
		queued+=int(result.get("accepted",0))
	return {"ok":true,"queued":queued,"message":"All %d soldiers entered the build's training together, including existing personnel. Equipment is reserved; the complete intake finishes together." % queued}


func _detach_matching_formations(entries:Array)->Array[Dictionary]:
	var detached:Array[Dictionary]=[]
	var formations:Array=home_army.get("formations",[])
	var taken_total:=0
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		var unit:=String(entry.get("unit","levy"))
		var weapon:=String(entry.get("weapon","improvised"))
		var remaining:=maxi(0,int(entry.get("count",0)))
		for index in range(formations.size()-1,-1,-1):
			if remaining<=0: break
			var formation:Dictionary=formations[index]
			if String(formation.get("unit",""))!=unit or String(formation.get("weapon",""))!=weapon: continue
			var original_count:=maxi(0,int(formation.get("count",0)))
			if original_count<=0: continue
			var take:=mini(remaining,original_count)
			var split:Dictionary=formation.duplicate(true)
			var equipment_take:=mini(int(formation.get("equipment",0)),roundi(float(formation.get("equipment",0))*float(take)/float(original_count)))
			var ammunition_take:=mini(int(formation.get("ammunition",0)),roundi(float(formation.get("ammunition",0))*float(take)/float(original_count)))
			split["count"]=take
			split["authorized_count"]=take
			split["equipment"]=equipment_take
			split["equipment_required"]=_equipment_required_for(unit,take)
			split["ammunition"]=ammunition_take
			split["ammunition_required"]=_ammunition_required_for(weapon,int(split.equipment_required))
			detached.push_front(split)
			formation["count"]=original_count-take
			formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",original_count))-take)
			formation["equipment"]=maxi(0,int(formation.get("equipment",0))-equipment_take)
			formation["equipment_required"]=_equipment_required_for(unit,int(formation.authorized_count))
			formation["ammunition"]=maxi(0,int(formation.get("ammunition",0))-ammunition_take)
			formation["ammunition_required"]=_ammunition_required_for(weapon,int(formation.equipment_required))
			remaining-=take
			taken_total+=take
			if int(formation.count)<=0: formations.remove_at(index)
			else: formations[index]=formation
	home_army["formations"]=formations
	home_army["troops"]=maxi(0,int(home_army.get("troops",0))-taken_total)
	return detached


func template_deployment_availability(template_id:int)->Dictionary:
	if not active_engagement.is_empty() or not pending_aftermath.is_empty(): return {"error":"Finish the active battle and aftermath before reorganizing armies."}
	if field_armies.size()>=field_army_capacity(): return {"error":"Command capacity is full: %d/%d field armies." % [field_armies.size(),field_army_capacity()]}
	var index:=_template_index(template_id)
	if index<0: return {"error":"That army build no longer exists."}
	var template:Dictionary=army_templates[index]
	var entries:Array=template.get("entries",[])
	if entries.is_empty(): return {"error":"The build has no cohorts. Add units to it first."}
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		var unit:=String(entry.get("unit","levy"))
		var weapon:=String(entry.get("weapon","improvised"))
		if _matching_home_count(unit,weapon)<int(entry.get("count",0)):
			return {"error":"%s needs %d trained %s (%s); only %d are ready at home. Queue the build's training first." % [String(template.get("name","The build")),int(entry.get("count",0)),unit.replace("_"," "),weapon.replace("_"," "),_matching_home_count(unit,weapon)]}
	return {"ok":true,"message":"Form the army at home, then choose its destination on the map."}


func deploy_army_from_template(template_id:int,custom_name:String="")->Dictionary:
	var available:=template_deployment_availability(template_id)
	if available.has("error"): return available
	var template:Dictionary=army_templates[_template_index(template_id)]
	var entries:Array=template.get("entries",[])
	var detached:=_detach_matching_formations(entries)
	var label:=custom_name.strip_edges()
	if label=="": label="%s Army" % _ordinal_army_name(next_field_army_id)
	var result:=_assemble_field_army(detached,label)
	if result.has("ok"):
		template.recruitment_requested=false
		result["message"]="%s deployed with %d soldiers. %d remain in the home reserve; %d trained soldiers total. Deployment transfers soldiers; it does not remove them." % [label,int(result.get("army",{}).get("troops",0)),int(home_army.get("troops",0)),int(home_army.get("troops",0))+field_army_active_personnel()]
	return result


func _rebuild_home_army_with(additions:Array)->void:
	var previous:=home_army.duplicate(true)
	var formations:Array=(home_army.get("formations",[]) as Array).duplicate(true)
	for addition_variant in additions:
		var addition:Dictionary=(addition_variant as Dictionary).duplicate(true)
		var merged:=false
		for index in formations.size():
			var existing:Dictionary=formations[index]
			if int(existing.get("id",-1))!=int(addition.get("id",-2)) or String(existing.get("unit",""))!=String(addition.get("unit","")) or String(existing.get("weapon",""))!=String(addition.get("weapon","")): continue
			var old_count:=maxi(0,int(existing.get("count",0))); var added_count:=maxi(0,int(addition.get("count",0))); var combined:=old_count+added_count
			existing["count"]=combined; existing["authorized_count"]=maxi(combined,int(existing.get("authorized_count",old_count))+int(addition.get("authorized_count",added_count)))
			existing["equipment"]=maxi(0,int(existing.get("equipment",0))+int(addition.get("equipment",0)))
			existing["equipment_required"]=_equipment_required_for(String(existing.get("unit","levy")),int(existing.authorized_count))
			existing["ammunition"]=maxi(0,int(existing.get("ammunition",0))+int(addition.get("ammunition",0)))
			existing["ammunition_required"]=_ammunition_required_for(String(existing.get("weapon","improvised")),int(existing.equipment_required))
			for quality in ["training","experience","personnel_condition"]: existing[quality]=(float(existing.get(quality,0.0))*old_count+float(addition.get(quality,0.0))*added_count)/maxf(1.0,float(combined))
			formations[index]=existing; merged=true; break
		if not merged:
			var duplicate_id:=false
			for existing in formations:
				if int(existing.get("id",-1))==int(addition.get("id",-2)): duplicate_id=true; break
			if duplicate_id: addition["id"]=next_formation_id; next_formation_id+=1
			formations.append(addition)
	var rebuilt:Dictionary=simulator.create_formation_force(_home_army_name(),formations,float(previous.get("morale",_campaign_morale())),float(previous.get("readiness",0.5)))
	for key in previous:
		if key in ["name","troops","attack","defense","armor","penetration","formations"]: continue
		rebuilt[key]=previous[key].duplicate(true) if previous[key] is Array or previous[key] is Dictionary else previous[key]
	home_army=rebuilt
	_refresh_readiness()


func _process_field_army_movement_day()->void:
	for index in field_armies.size():
		var army:Dictionary=field_armies[index]
		if String(army.get("status","stationed"))!="moving": continue
		var intercept_target_id:=String(army.get("target_formation_id",""))
		if not intercept_target_id.is_empty():
			var tracked:Dictionary=CivilizationSystem.visible_formation_sighting(intercept_target_id)
			if tracked.is_empty():
				army["status"]="stationed"
				army["location_name"]="LAST KNOWN CONTACT"
				army["destination_id"]=""
				army.erase("target_formation_id")
				army.erase("order_kind")
				field_armies[index]=army
				GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Intercept lost contact","description":"%s reached the last observation but the foreign formation was no longer in sight. No battle occurred." % String(army.get("name","The field army")),"domain":"security","severity":"warning"})
				continue
			var tracked_position:Dictionary=tracked.get("position",{})
			var current_position:Dictionary=army.get("position",{})
			var current_point:=Vector2(float(current_position.get("x",0.0)),float(current_position.get("z",0.0)))
			var tracked_point:=Vector2(float(tracked_position.get("x",0.0)),float(tracked_position.get("z",0.0)))
			var tracked_distance:=current_point.distance_to(tracked_point)
			army["origin_position"]=current_position.duplicate(true)
			army["destination_position"]=tracked_position.duplicate(true)
			army["distance_total_km"]=tracked_distance
			army["distance_remaining_km"]=tracked_distance
			army["destination_name"]="INTERCEPT Â· %s" % String(tracked.get("label","FOREIGN FORMATION"))
		var remaining:=maxf(0.0,float(army.get("distance_remaining_km",0.0)))
		var speed:=_field_army_speed(army)
		var traveled:=minf(remaining,speed)
		remaining=maxf(0.0,remaining-traveled)
		army["speed_km_day"]=speed
		army["distance_remaining_km"]=remaining
		var total:=maxf(0.001,float(army.get("distance_total_km",1.0)))
		var progress:=clampf(1.0-remaining/total,0.0,1.0)
		var origin_data:Dictionary=army.get("origin_position",army.get("position",{}))
		var destination_data:Dictionary=army.get("destination_position",{})
		var origin:=Vector2(float(origin_data.get("x",0.0)),float(origin_data.get("z",0.0)))
		var destination:=Vector2(float(destination_data.get("x",0.0)),float(destination_data.get("z",0.0)))
		var current:=origin.lerp(destination,progress)
		army["position"]={"x":current.x,"z":current.y}
		army["supply_level"]=clampf(move_toward(float(army.get("supply_level",0.75)),field_provision_delivery_ratio(),0.025)-0.0008*traveled,0.05,1.0)
		if remaining<=0.001:
			army["status"]="stationed"
			army["location_id"]=String(army.get("destination_id",""))
			army["location_name"]=String(army.get("destination_name","DESTINATION"))
			army["destination_id"]=""
			army["arrival_day"]=int(GameState.elapsed_days)
			if _army_is_home(army) or _live_army_reporting():
				GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Army arrived","description":"%s reached %s with %d personnel and %d%% supply." % [String(army.name),String(army.location_name),int(army.troops),roundi(float(army.supply_level)*100.0)],"domain":"security","severity":"notice"})
			else:
				# Arrival is itself only known at home once a runner delivers it.
				army=_dispatch_army_runner(army,int(GameState.elapsed_days))
		field_armies[index]=army
		if remaining<=0.001 and army.has("city_operation"):
			var planned:Dictionary=army.city_operation.duplicate(true)
			field_armies[index].erase("city_operation")
			var result:=order_city_operation(int(army.army_id),String(planned.civ_id),String(planned.region_id),bool(planned.besiege))
			GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"City order blocked" if result.has("error") else "City engagement begins","description":String(result.get("error","The army reached its ordered city and began hostilities.")),"domain":"security","severity":"warning"})
		if remaining<=0.001 and not intercept_target_id.is_empty():
			var contact_result:=launch_map_engagement(int(army.get("army_id",0)),intercept_target_id)
			if contact_result.has("error"):
				field_armies[index].erase("target_formation_id")
				field_armies[index].erase("order_kind")
				GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Intercept did not engage","description":String(contact_result.error),"domain":"security","severity":"warning"})


func _live_army_reporting()->bool:
	## Signal-era development (telegraph/radio tier) replaces physical runners.
	return int(military_development_snapshot().get("tier",0))>=5


func _army_report_snapshot(army:Dictionary)->Dictionary:
	var carried:Dictionary={}
	var position:Dictionary=army.get("position",{})
	if int(army.get("troops",0))>0 and CivilizationSystem.city_intelligence.valid_point(position):
		CivilizationSystem.city_intelligence.stage(carried,"player",CivilizationSystem.city_intelligence.vector(position),.65,int(GameState.elapsed_days),"army:%s" % str(army.get("army_id",0)))
	return {
		"city_observations":carried.get("city_observations",{}),
		"day":int(GameState.elapsed_days),
		"position":(army.get("position",{}) as Dictionary).duplicate(true),
		"status":String(army.get("status","stationed")),
		"location_name":String(army.get("location_name","")),
		"destination_name":String(army.get("destination_name","")),
		"troops":int(army.get("troops",0)),
		"supply_level":float(army.get("supply_level",1.0)),
		"morale":float(army.get("morale",0.5)),
		"readiness":float(army.get("readiness",0.5)),
		"distance_remaining_km":float(army.get("distance_remaining_km",0.0)),
		"arrival_day":int(army.get("arrival_day",-1)),
	}


func _army_is_home(army:Dictionary)->bool:
	return String(army.get("status","stationed"))=="stationed" and String(army.get("location_id",""))=="player_home"


func _dispatch_army_runner(army:Dictionary,day:int)->Dictionary:
	if int(army.get("runner_count",0))<=0: return army
	var position:Dictionary=army.get("position",{})
	var here:=Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
	var home_destination:=_movement_destination("player_home")
	var home_position:Dictionary=home_destination.get("position",{"x":0.0,"z":0.0})
	var home:=Vector2(float(home_position.get("x",0.0)),float(home_position.get("z",0.0)))
	var travel_days:=maxi(0,ceili(here.distance_to(home)/maxf(1.0,RUNNER_SPEED_KM_DAY)))
	runner_messages.append({"army_id":int(army.get("army_id",0)),"army_name":String(army.get("name","FIELD ARMY")),"sent_day":day,"arrival_day":day+travel_days,"snapshot":_army_report_snapshot(army)})
	army["last_runner_departure_day"]=day
	return army


func _process_army_runners_day()->void:
	var day:=int(GameState.elapsed_days)
	var live:=_live_army_reporting()
	for index in field_armies.size():
		var army:Dictionary=field_armies[index]
		if live or _army_is_home(army):
			# At home (or with signal-era communications) the government simply
			# knows; runners are only the early-game information carrier.
			army["last_report"]=_army_report_snapshot(army)
			CivilizationSystem.city_intelligence.deliver(army.last_report,"player",day)
			field_armies[index]=army
			continue
		if day-int(army.get("last_runner_departure_day",day))>=RUNNER_INTERVAL_DAYS:
			army=_dispatch_army_runner(army,day)
		field_armies[index]=army
	if runner_messages.is_empty(): return
	var remaining_messages:Array[Dictionary]=[]
	for message_variant in runner_messages:
		var message:Dictionary=message_variant
		if day<int(message.get("arrival_day",day)):
			remaining_messages.append(message)
			continue
		CivilizationSystem.city_intelligence.deliver(message.get("snapshot",{}),"player",day)
		var army_index:=_field_army_index(int(message.get("army_id",-1)))
		if army_index>=0:
			var army:Dictionary=field_armies[army_index]
			var snapshot:Dictionary=message.get("snapshot",{})
			# Never let an older runner overwrite a newer report.
			if int(snapshot.get("day",-1))>int((army.get("last_report",{}) as Dictionary).get("day",-1)):
				army["last_report"]=snapshot.duplicate(true)
				field_armies[army_index]=army
				var report_day:=int(snapshot.get("day",day))
				var status_text:="held position at %s" % String(snapshot.get("location_name","the field")) if String(snapshot.get("status","stationed"))=="stationed" else "was marching on %s with %.0f km remaining" % [String(snapshot.get("destination_name","its objective")),float(snapshot.get("distance_remaining_km",0.0))]
				GameState.simulation_events.push_front({"day":day,"title":"Runner arrives","description":"A runner from %s reports: as of day %d the army %s with %d personnel and %d%% supply." % [String(message.get("army_name","the field army")),report_day,status_text,int(snapshot.get("troops",0)),roundi(float(snapshot.get("supply_level",1.0))*100.0)],"domain":"security","severity":"notice"})
	runner_messages=remaining_messages


func military_capabilities()->Dictionary:
	var units:Dictionary={}
	for unit in UnitCatalog.ARCHETYPES:
		var unit_gate:Dictionary=_knowledge_gate(UnitCatalog.gate_for(unit),0.10)
		unit_gate["capability"]=unit_capability_state(String(unit))
		unit_gate["archetype"]=UnitCatalog.archetype(String(unit))
		units[unit]=unit_gate
	var equipment:Dictionary={}
	for item in EQUIPMENT_KNOWLEDGE: equipment[item]=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE[item]),0.08)
	var queued_trainees:=_queued_trainees()
	return {"development":military_development_snapshot(),"organization":formation_organization_snapshot(),"production_lines":production_lines_snapshot(),"field_armies":field_armies_snapshot(),"fronts":CivilizationSystem.military_fronts_snapshot() if CivilizationSystem!=null and CivilizationSystem.has_method("military_fronts_snapshot") else {"fronts":[]},"units":units,"equipment":equipment,"unit_equipment":_unit_equipment_view(),"training_programs":training_program_catalog(),"training_program":training_program_snapshot(),"transport_carts":_knowledge_gate("joinery",0.10),"progression_errors":validate_military_progression(),"recruitment_capacity":recruitment_capacity(),"training_rate":_effective_training_rate(queued_trainees),"base_training_rate":_training_rate(),"training_capacity":training_capacity(),"training_load":queued_trainees,"training_bottleneck":maxi(0,queued_trainees-training_capacity()),"training_injury_multiplier":_training_injury_risk_multiplier(),"production_rate":_production_rate(),"base_production_rate":_base_production_rate(),"workshop_utilization":workshop_utilization(),"civilian_crafting_fraction":civilian_crafting_fraction(),"equipment_backlog_work":_equipment_backlog_work(),"medical_recovery":_adoption("battlefield_medicine"),"logistics_practice":_adoption("supply_groups"),"staff_planning":_adoption("military_staffs"),"delivery_load_capacity":_daily_delivery_capacity(),"equipment_delivery_load":EQUIPMENT_DELIVERY_LOAD.duplicate(true),"ammunition_delivery_load":AMMUNITION_DELIVERY_LOAD.duplicate(true),"veteran_experience":_army_experience(),"doctrine_transfer":_army_experience()*_adoption("professional_corps")}


func military_development_snapshot()->Dictionary:
	var tiers:Dictionary={
		"security":ProgressionSystem.domain_tier("security"),
		"production":ProgressionSystem.domain_tier("production"),
		"logistics":ProgressionSystem.domain_tier("logistics"),
		"institutions":ProgressionSystem.domain_tier("institutions")
	}
	var era:Dictionary=MILITARY_DEVELOPMENT.era_for_tiers(int(tiers.security),int(tiers.production),int(tiers.logistics),int(tiers.institutions))
	era["support_tiers"]=tiers
	era["research_driven"]=true
	era["next_requirement"]="A broader body of adopted security findings, supported by production, logistics, and institutions." if int(era.tier)<8 else "Planet-scale capability reached; discoveries continue to refine doctrine and equipment."
	return era


func formation_organization_snapshot()->Dictionary:
	var formations:Array=(home_army.get("formations",[]) as Array).duplicate(true)
	for army in field_armies: formations.append_array((army.get("formations",[]) as Array).duplicate(true))
	for force in occupation_forces: formations.append_array((force.get("formations",[]) as Array).duplicate(true))
	return MILITARY_DEVELOPMENT.organization_snapshot(formations)


func validate_military_progression()->Array[String]:
	var errors:Array[String]=[]
	var unit_gate_map:Dictionary={}
	for unit in UnitCatalog.ARCHETYPES: unit_gate_map[unit]=UnitCatalog.gate_for(String(unit))
	for gate_map in [unit_gate_map,EQUIPMENT_KNOWLEDGE]:
		for gate_name in gate_map:
			var discovery:=String(gate_map[gate_name])
			if discovery=="" or discovery.begins_with("__"): continue
			if DiscoverySystem.discovery_definition(discovery).is_empty(): errors.append("%s references missing discovery %s." % [String(gate_name),discovery])
	for unit in UnitCatalog.ARCHETYPES:
		for item in UnitCatalog.equipment_for(String(unit)):
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
		var enemy_force:Dictionary=active_engagement.get(_engagement_enemy_side(active_engagement),active_engagement.get("enemy_force",{}))
		threat_strength=maxi(threat_strength,int(enemy_force.get("troops",0)))
	var recent_combat_days:=maxi(0,int(home_army.get("recent_combat_days",0)))
	var wounded:=maxi(0,int(home_army.get("wounded_pool",0)))+training_injury_pool
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
	HistoricalFigures.record_battle(result)
	var home_side:=String(result.get("home_side","attacker"))
	var home_result:Dictionary=result.get(home_side,result.get("attacker",{}))
	var home_force_kind:=String(result.get("home_force_kind","field"))
	if home_force_kind=="occupation":
		_apply_occupation_result(String(result.get("home_force_civ_id","")),String(result.get("home_force_region_id","")),home_result,result.rounds,int(result.seed),home_side)
	elif home_force_kind=="field_army":
		_apply_field_army_result(int(result.get("home_force_id",0)),home_result,result.rounds,int(result.seed),home_side)
	else:
		_apply_home_result(home_result,result.rounds,int(result.seed),home_side)
		home_army["recent_combat_days"]=7
		home_army["supply_level"]=clampf(float(home_army.get("supply_level",1.0))-0.06,0.0,1.0)
	var termination:Dictionary=result.get("termination",{})
	if home_force_kind=="field": _apply_home_commander_fate(termination)
	var home_force_name:=String(home_result.get("name",home_army.get("name","")))
	var home_won:=String(termination.get("captor",""))==home_force_name
	var home_lost:=String(termination.get("defeated",""))==home_force_name and not home_won
	if home_lost and int(termination.get("prisoners",0))>0:
		_mark_engaged_force_prisoners(
			home_force_kind,
			int(result.get("home_force_id",0)),
			String(result.get("home_force_civ_id","")),
			String(result.get("home_force_region_id","")),
			int(termination.prisoners)
		)
	var termination_summary:=String(termination.get("summary",""))
	if termination_summary!="": result["message"]=termination_summary
	var record:=result.duplicate(true)
	record["day"]=int(GameState.elapsed_days)
	battle_history.push_front(record)
	if battle_history.size()>40: battle_history.resize(40)
	pending_aftermath=termination.duplicate(true) if home_won else {}
	if not pending_aftermath.is_empty(): pending_aftermath["home_force_name"]=home_force_name
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
	var home_won:=String(pending_aftermath.get("captor",""))==String(pending_aftermath.get("home_force_name",home_army.get("name","")))
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
	outcome["message"]=_aftermath_description(outcome)
	pending_aftermath.clear()
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Battle aftermath resolved","description":_aftermath_description(outcome),"domain":"security","severity":"notice"})
	army_changed.emit(home_army.duplicate(true))
	return outcome


func campaign_army_snapshot()->Dictionary:
	if home_army.is_empty(): home_army=_empty_home_army()
	_synchronize_field_commander()
	var snapshot:=home_army.duplicate(true)
	snapshot["foreign_prisoners"]=foreign_prisoners
	snapshot["held_generals"]=held_generals.duplicate(true)
	snapshot["military_inventory"]=military_inventory.duplicate(true)
	snapshot["military_consumables"]=military_consumables.duplicate(true)
	snapshot["damaged_equipment"]=damaged_equipment.duplicate(true)
	snapshot["recruits"]=aggregate_recruits
	snapshot["training_queue"]=training_queue.duplicate(true)
	snapshot["training_injuries"]=training_injury_pool
	snapshot["training_program"]=training_program_snapshot()
	snapshot["equipment_queue"]=equipment_queue.duplicate(true)
	snapshot["mobilization_cost"]=_mobilization_cost()
	snapshot["prisoner_custody"]=prisoner_custody_snapshot()
	snapshot["economic_burden"]=economic_burden_snapshot()
	snapshot["occupation_forces"]=occupation_forces.duplicate(true)
	snapshot["field_armies"]=field_armies.duplicate(true)
	return snapshot


func economic_burden_snapshot()->Dictionary:
	var mobilized:=_mobilized_count(); var home_soldiers:=int(home_army.get("troops",0)); var army_soldiers:=field_army_active_personnel(); var field_soldiers:=home_soldiers+army_soldiers; var occupation_soldiers:=_occupation_force_total(); var queued:=_queued_trainees(); var recruits:=aggregate_recruits
	var provisions:=float(home_army.get("provisions_required_today",0.0))
	if int(home_army.get("provision_day",-1))<int(GameState.elapsed_days)-1: provisions=float(home_soldiers)*0.90+float(army_soldiers)*1.05
	else:
		for army in field_armies: provisions+=float(army.get("provisions_required_today",0.0))
	provisions+=float(occupation_soldiers)*0.72
	var issued_equipment:=0
	for formation in home_army.get("formations",[]): issued_equipment+=int(formation.get("equipment",0))
	for army in field_armies:
		for formation in army.get("formations",[]): issued_equipment+=int(formation.get("equipment",0))
	var stored_equipment:=0; var damaged:=0
	for item in military_inventory: stored_equipment+=int(military_inventory[item])
	for item in damaged_equipment: damaged+=int(damaged_equipment[item])
	var currency_upkeep_units:=float(field_soldiers)*0.025+float(maxi(0,mobilized-field_soldiers))*0.012+float(issued_equipment+stored_equipment)*0.001+float(foreign_prisoners)*0.006
	return {"mobilized_population":mobilized,"field_personnel":field_soldiers,"home_personnel":home_soldiers,"maneuver_army_personnel":army_soldiers,"field_armies":field_armies.size(),"occupation_personnel":occupation_soldiers,"occupation_regions":occupation_forces.size(),"recruits":recruits,"trainees":queued,"training_injuries":training_injury_pool,"exercise_participants":int(training_program.get("participants",0)),"exercise_extra_rations":float(training_program.get("food_required_total",0.0)),"population_withheld_by_role":_mobilization_cost().former_roles,"daily_field_provisions":provisions,"workshop_diversion":1.0-civilian_crafting_fraction(),"equipment_backlog_work":_equipment_backlog_work(),"issued_equipment":issued_equipment,"stored_equipment":stored_equipment,"damaged_equipment":damaged,"foreign_prisoners":foreign_prisoners,"currency_upkeep_units":currency_upkeep_units}


func combat_summary(force:Dictionary={},opponent:Dictionary={},terrain_modifier:float=1.0)->Dictionary:
	var home_side:=_engagement_home_side(active_engagement)
	var enemy_side:=_engagement_enemy_side(active_engagement)
	var subject:=force if not force.is_empty() else ((active_engagement.get(home_side,{}) as Dictionary) if not active_engagement.is_empty() else home_army)
	var opposing:=opponent if not opponent.is_empty() else ((active_engagement.get(enemy_side,{}) as Dictionary) if not active_engagement.is_empty() else {"formations":[]})
	var cohorts:Array[Dictionary]=simulator.evaluate_force(subject,opposing,terrain_modifier)
	var formations:Array=subject.get("formations",[])
	var attack_strength:=0.0; var defense_strength:=0.0; var raw_attack_strength:=0.0; var raw_defense_strength:=0.0; var base_effective_strength:=0.0
	for index in cohorts.size():
		var cohort:Dictionary=cohorts[index]
		var count:=float(cohort.get("count",0))
		var cohort_attack:=count*float(cohort.get("attack",0.0)); var cohort_defense:=count*float(cohort.get("defense",0.0))
		var cohort_readiness:=clampf(float((formations[index] as Dictionary).get("readiness",subject.get("readiness",1.0))),0.0,1.5) if index<formations.size() else clampf(float(subject.get("readiness",1.0)),0.0,1.5)
		raw_attack_strength+=cohort_attack; raw_defense_strength+=cohort_defense
		attack_strength+=cohort_attack*cohort_readiness; defense_strength+=cohort_defense*cohort_readiness
		base_effective_strength+=count*sqrt(maxf(0.0,float(cohort.get("attack",0.0))*float(cohort.get("defense",0.0))))
	var readiness_components:Dictionary=simulator.force_readiness(subject,_force_personnel_condition(subject))
	var supply:=clampf(float(subject.get("supply_level",home_army.get("supply_level",1.0))),0.0,1.0); var discipline:=clampf(float(subject.get("discipline",home_army.get("discipline",0.5))),0.0,1.0)
	readiness_components["supply"]=supply; readiness_components["discipline"]=discipline
	var calculated_readiness:=float(readiness_components.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)
	var readiness:=clampf(float(subject.get("readiness",calculated_readiness)),0.0,1.5)
	var morale:=clampf(float(subject.get("morale",1.0)),0.0,1.5)
	var commander:Dictionary=subject.get("commander",{})
	var command_factor:=0.90+clampf(float(commander.get("command",0.5)),0.0,1.0)*0.20
	var effective_strength:=base_effective_strength*maxf(CombatSimulator.MIN_EFFECTIVE_STRENGTH,morale)*readiness*command_factor
	return {"troops":int(subject.get("troops",0)),"attack_strength":attack_strength,"defense_strength":defense_strength,"raw_attack_strength":raw_attack_strength,"raw_defense_strength":raw_defense_strength,"base_effective_strength":base_effective_strength,"effective_strength":effective_strength,"average_attack":attack_strength/maxf(1.0,float(subject.get("troops",0))),"average_defense":defense_strength/maxf(1.0,float(subject.get("troops",0))),"readiness":readiness,"calculated_readiness":calculated_readiness,"readiness_components":readiness_components,"morale":morale,"command_factor":command_factor,"commander":commander.duplicate(true)}


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


func _engagement_home_side(engagement:Dictionary)->String:
	return String(engagement.get("home_side","attacker"))


func _engagement_enemy_side(engagement:Dictionary)->String:
	return "defender" if _engagement_home_side(engagement)=="attacker" else "attacker"


func _home_defense_force(allocate_id:bool=true)->Dictionary:
	var force:=home_army.duplicate(true)
	force.readiness=float(force.get("readiness",.5))*recovery.defense_factor()
	var trained:=maxi(0,int(force.get("troops",0)))
	var militia:=maxi(0,_home_garrison_target()-trained)
	if militia<=0: return force
	var formations:Array=(force.get("formations",[]) as Array).duplicate(true)
	var formation_id:=next_formation_id if allocate_id else -1
	if allocate_id:next_formation_id+=1
	formations.append({"id":formation_id,"unit":"levy","weapon":"improvised","count":militia,"authorized_count":militia,"equipment":0,"equipment_required":militia,"ammunition":0,"ammunition_required":0,"training":0.20,"experience":0.0,"personnel_condition":_trainee_condition(),"emergency_militia":true})
	var assembled:Dictionary=simulator.create_formation_force(_home_army_name(),formations,float(force.get("morale",_campaign_morale())),maxf(0.08,float(force.get("readiness",0.18))))
	assembled["commander"]=(force.get("commander",_marshal_commander()) as Dictionary).duplicate(true)
	assembled["supply_level"]=float(force.get("supply_level",1.0))
	assembled["emergency_militia_personnel"]=militia
	return assembled


func begin_threat_engagement()->Dictionary:
	if not active_siege.is_empty(): return {"error":"Use the siege assault or sortie order to begin combat."}
	if not active_engagement.is_empty(): return engagement_snapshot()
	if active_threat.is_empty(): return {"error":"No military threat is awaiting a response."}
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	var target_civ_id:=String(active_threat.get("source_civ_id",""))
	var target_region_id:=String(active_threat.get("target_region_id",""))
	var occupation_index:=_occupation_force_index(target_civ_id,target_region_id) if target_region_id!="" else -1
	var defending_occupation:=String(active_threat.get("campaign_mode","defensive"))=="defensive" and occupation_index>=0
	var offensive:=String(active_threat.get("campaign_mode","defensive"))=="offensive"
	var field_army_id:=int(active_threat.get("field_army_id",0)) if offensive else 0
	var field_army_index:=_field_army_index(field_army_id) if field_army_id>0 else -1
	var local_defense:=_home_defense_force() if not offensive and not defending_occupation else {}
	var available_home_troops:=int(occupation_forces[occupation_index].get("troops",0)) if defending_occupation else (int(field_armies[field_army_index].get("troops",0)) if field_army_index>=0 else int(local_defense.get("troops",0)))
	if available_home_troops<=0: return {"error":"No local watch or trained force is available for this campaign."}
	_refresh_readiness()
	var threat:=active_threat.duplicate(true)
	var home_force:Dictionary=occupation_forces[occupation_index].duplicate(true) if defending_occupation else (field_armies[field_army_index].duplicate(true) if field_army_index>=0 else local_defense)
	var attacker:Dictionary=home_force if offensive else threat.enemy_force.duplicate(true)
	var defender:Dictionary=threat.enemy_force.duplicate(true) if offensive else home_force
	var battle_ground:=float(threat.get("terrain_defense",1.0)) if offensive or defending_occupation else _terrain_defense()
	active_engagement={"threat":threat,"campaign_mode":String(threat.get("campaign_mode","defensive")),"home_side":"attacker" if offensive else "defender","home_force_kind":"occupation" if defending_occupation else ("field_army" if field_army_index>=0 else "field"),"home_force_id":field_army_id if field_army_index>=0 else 0,"home_force_civ_id":target_civ_id if defending_occupation else "","home_force_region_id":target_region_id if defending_occupation else "","attacker":attacker,"defender":defender,"attacker_initial":int(attacker.troops),"defender_initial":int(defender.troops),"round":0,"rounds":[],"seed":int(threat.seed),"terrain_defense":battle_ground,"status":"active","last_order":"hold"}
	active_threat.clear(); threat_changed.emit({}); army_changed.emit(home_army.duplicate(true))
	battle_started.emit(active_engagement.duplicate(true))
	return engagement_snapshot()


func set_battle_formation_order(index:int,kind:String,target:int=-1)->Dictionary:
	if active_engagement.is_empty():return {"error":"No active battle."}
	var side:=_engagement_home_side(active_engagement);var enemy:=_engagement_enemy_side(active_engagement)
	var error:=BattleRoundOrders.validate(active_engagement[side].get("formations",[]),active_engagement[enemy].get("formations",[]),index,kind,target)
	if error!="":return {"error":error}
	if not active_engagement.has("formation_orders"):active_engagement["formation_orders"]={}
	active_engagement.formation_orders[str(index)]={"kind":kind,"target":target}
	return {"ok":true}

func advance_engagement(order:String="hold")->Dictionary:
	if active_engagement.is_empty(): return {"error":"No campaign battle is active."}
	active_engagement.erase("awaiting_player_view")
	var command:=order.to_lower()
	if command not in ["hold","push","retreat"]: return {"error":"Unknown battle order: %s" % order}
	if command=="retreat": return _finish_active_engagement(true,{})
	var attacker:Dictionary=(active_engagement.attacker as Dictionary).duplicate(true)
	var defender:Dictionary=(active_engagement.defender as Dictionary).duplicate(true)
	var round_options:Dictionary={"seed":int(active_engagement.seed)+(int(active_engagement.round)+1)*7919,"terrain_defense":float(active_engagement.terrain_defense),"max_rounds":1}
	var home_side:=_engagement_home_side(active_engagement)
	var front_stance:=String((active_engagement.get("threat",{}) as Dictionary).get("front_stance","balanced"))
	if front_stance=="cautious":
		if home_side=="attacker": attacker["attack_modifier"]=float(attacker.get("attack_modifier",1.0))*0.90; attacker["defense_modifier"]=float(attacker.get("defense_modifier",1.0))*1.08; round_options["attacker_exposure_modifier"]=0.82
		else: defender["attack_modifier"]=float(defender.get("attack_modifier",1.0))*0.90; defender["defense_modifier"]=float(defender.get("defense_modifier",1.0))*1.08; round_options["defender_exposure_modifier"]=0.82
	elif front_stance=="offensive":
		round_options["casualty_intensity"]=1.12
		if home_side=="attacker": attacker["attack_modifier"]=float(attacker.get("attack_modifier",1.0))*1.12; round_options["attacker_exposure_modifier"]=1.08
		else: defender["attack_modifier"]=float(defender.get("attack_modifier",1.0))*1.12; round_options["defender_exposure_modifier"]=1.08
	if command=="push":
		if home_side=="attacker": attacker["attack_modifier"]=float(attacker.get("attack_modifier",1.0))*1.25
		else: defender["attack_modifier"]=float(defender.get("attack_modifier",1.0))*1.25
		round_options["casualty_intensity"]=1.30
		if home_side=="attacker": round_options["attacker_exposure_modifier"]=1.12
		else: round_options["defender_exposure_modifier"]=1.12
	var directives:Dictionary=active_engagement.get("formation_orders",{})
	if not directives.is_empty():
		var commanded:Dictionary=attacker if home_side=="attacker" else defender
		var opposing:Dictionary=defender if home_side=="attacker" else attacker
		var orders_context:=BattleRoundOrders.apply(commanded,opposing,directives)
		round_options[home_side+"_exposure_modifier"]=float(round_options.get(home_side+"_exposure_modifier",1))*float(orders_context.exposure)
		round_options["casualty_intensity"]=float(round_options.get("casualty_intensity",1))*float(orders_context.intensity)
		round_options[("defender" if home_side=="attacker" else "attacker")+"_ordered_targets"]=orders_context.targets
	var next_round:=int(active_engagement.round)+1
	var result:Dictionary=simulator.simulate(attacker,defender,round_options)
	BattleRoundOrders.clear_transient(result.attacker);BattleRoundOrders.clear_transient(result.defender)
	if (result.get("rounds",[]) as Array).is_empty(): return _finish_active_engagement(false,result)
	var record:Dictionary=(result.rounds[0] as Dictionary).duplicate(true); record["round"]=next_round; record["order"]=command; record["formation_orders"]=directives.duplicate(true)
	(active_engagement.rounds as Array).append(record)
	active_engagement["round"]=next_round; active_engagement["attacker"]=_force_from_round_result(active_engagement.attacker,result.attacker); active_engagement["defender"]=_force_from_round_result(active_engagement.defender,result.defender); active_engagement["last_order"]=command; active_engagement["last_result"]=result.duplicate(true)
	# The resolver calls an undecided round "inconclusive"; it is still an active
	# engagement. Do not prematurely finish every battle after its first round.
	if String(result.get("outcome","inconclusive")) not in ["continued","inconclusive"] or next_round>=CombatSimulator.MAX_ROUNDS:
		return _finish_active_engagement(false,result)
	army_changed.emit(home_army.duplicate(true))
	return {"active":true,"engagement":engagement_snapshot(),"round":record}


func _force_from_round_result(previous:Dictionary,side:Dictionary)->Dictionary:
	var updated:=previous.duplicate(true)
	for key in ["remaining_troops","morale","formations","reserve_manpower","wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","dead"]:
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
	var home_side:=_engagement_home_side(engagement)
	var enemy_side:=_engagement_enemy_side(engagement)
	var outcome:=String(last_result.get("outcome","continued")); var termination:Dictionary=(last_result.get("termination",{}) as Dictionary).duplicate(true)
	if retreated:
		outcome="%s_retreat" % home_side
		termination=_retreat_termination(engagement[home_side],engagement[enemy_side],int(engagement.seed),int(engagement.round))
	elif outcome=="continued": termination={"type":"continued","summary":"Both forces remain capable of further action."}
	var attacker_result:Dictionary=simulator._force_result(attacker,int(engagement.attacker_initial),int(attacker.troops),float(attacker.morale))
	var defender_result:Dictionary=simulator._force_result(defender,int(engagement.defender_initial),int(defender.troops),float(defender.morale))
	var threat:Dictionary=(engagement.get("threat",{}) as Dictionary).duplicate(true)
	var final_result:Dictionary={"seed":int(engagement.seed),"outcome":outcome,"winner":String((engagement[enemy_side] as Dictionary).name) if retreated else String(last_result.get("winner","")),"round_count":int(engagement.round),"rounds":engagement.rounds.duplicate(true),"attacker":attacker_result,"defender":defender_result,"home_side":home_side,"home_force_kind":String(engagement.get("home_force_kind","field")),"home_force_id":int(engagement.get("home_force_id",0)),"home_force_civ_id":String(engagement.get("home_force_civ_id","")),"home_force_region_id":String(engagement.get("home_force_region_id","")),"campaign_mode":String(engagement.get("campaign_mode","defensive")),"field_encounter":bool(threat.get("field_encounter",false)),"formation_id":String(threat.get("formation_id","")),"target_region_id":String(threat.get("target_region_id","")),"target_region_name":String(threat.get("target_region_name","")),"threat":threat,"terrain_defense":float(engagement.terrain_defense),"effective_terrain_defense":float(last_result.get("effective_terrain_defense",engagement.terrain_defense)),"termination":termination,"orders":{"retreated":retreated}}
	var source_civ_id:=String((engagement.get("threat",{}) as Dictionary).get("source_civ_id",""))
	active_engagement.clear(); threats_resolved+=1
	var committed:=_commit_campaign_battle(final_result)
	_apply_home_siege_damage(final_result)
	if source_civ_id!="":
		var strategic_outcome:Dictionary=CivilizationSystem.resolve_player_battle(source_civ_id,final_result)
		if String(threat.get("incident_kind","campaign"))=="raid" and String(final_result.get("campaign_mode","defensive"))=="defensive" and bool(strategic_outcome.get("decisive",false)) and not bool(strategic_outcome.get("player_won",false)):
			var raid_losses:=_apply_raid_store_losses(threat,0.65)
			strategic_outcome["raid_losses"]=raid_losses
			GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Raiders break into the stores","description":"The defeated garrison could not prevent the raiders from taking portable food and materials.","domain":"security","severity":"danger"})
		if bool(final_result.get("field_encounter",false)):
			CivilizationSystem.resolve_foreign_formation_after_battle(String(final_result.get("formation_id","")),final_result)
		if bool(strategic_outcome.get("region_captured",false)):
			var garrison:=establish_occupation_force(source_civ_id,strategic_outcome.get("region",{}),float(strategic_outcome.get("occupation_required",0.0)),int(final_result.get("home_force_id",0)))
			strategic_outcome["occupation_force"]=garrison
		elif bool(strategic_outcome.get("region_recaptured",false)):
			strategic_outcome["occupation_force_loss"]=remove_occupation_force(source_civ_id,String(strategic_outcome.get("target_region_id",final_result.target_region_id)),false)
		if bool(strategic_outcome.get("decisive",false)) and not bool(strategic_outcome.get("player_won",false)) and String(final_result.campaign_mode)=="defensive" and String(final_result.target_region_id).is_empty() and not bool(final_result.field_encounter) and String(threat.get("incident_kind","campaign"))!="raid":
			strategic_outcome["player_occupation"]=recovery.capture(source_civ_id)
		committed["strategic_outcome"]=strategic_outcome
	return committed


func _apply_raid_store_losses(threat:Dictionary,battle_modifier:float=1.0)->Dictionary:
	var losses:Dictionary={}
	var protection:=store_protection()
	var fraction:=clampf(float(threat.get("plunder_fraction",0.12))*float(protection.get("exposed_share",1.0))*battle_modifier,0.0,0.35)
	for resource_name in ["Food","Timber","Stone","Fiber Plants"]:
		var available:=float(GameState.resource_stockpiles.get(resource_name,0.0))
		var requested:=available*fraction
		var removed:=FoodSystem.issue_for_obligation(requested,"raid_loss","Stores seized after a failed defense") if resource_name=="Food" else requested
		if resource_name!="Food": GameState.resource_stockpiles[resource_name]=maxf(0.0,available-removed)
		losses[resource_name]=removed
	return losses


func _retreat_termination(attacker:Dictionary,defender:Dictionary,battle_seed:int,round_number:int)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=battle_seed^(round_number+1)*65537^0x45d9f3b
	var commander:Dictionary=attacker.get("commander",{})
	var withdrawal_skill:=clampf(float(commander.get("command",0.5))*0.30+float(commander.get("tactics",0.5))*0.30+float(commander.get("logistics",0.5))*0.20+float(commander.get("resolve",0.5))*0.20,0.0,1.0)
	var enemy_commander:Dictionary=defender.get("commander",{})
	var enemy_leadership:=clampf(float(enemy_commander.get("command",0.5))*0.45+float(enemy_commander.get("tactics",0.5))*0.55,0.0,1.0)
	var enemy_cavalry:=0
	for formation in defender.get("formations",[]):
		if String(formation.get("unit",""))=="cavalry": enemy_cavalry+=maxi(0,int(formation.get("count",0)))
	var cavalry_share:=float(enemy_cavalry)/maxf(1.0,float(defender.get("troops",0)))
	var morale:=clampf(float(attacker.get("morale",0.5)),0.0,1.0)
	var pursuit_pressure:=clampf(0.18+enemy_leadership*0.22+cavalry_share*0.40-withdrawal_skill*0.35-morale*0.20,0.0,0.55)
	var remaining:=maxi(0,int(attacker.get("troops",0)))
	var prisoners:=clampi(roundi(float(remaining)*pursuit_pressure*rng.randf_range(0.02,0.08)),0,remaining)
	var commander_fate:="escaped"
	var captured_general:=false
	var fate_roll:=rng.randf()
	if fate_roll<pursuit_pressure*0.16:
		commander_fate="captured"
		captured_general=true
	elif fate_roll<pursuit_pressure*0.195:
		commander_fate="killed"
	elif fate_roll<pursuit_pressure*0.295:
		commander_fate="wounded, but escaped"
	var spoils:Dictionary=simulator._battle_spoils(attacker,defender,"withdrawal",rng) if pursuit_pressure>0.02 else {}
	var summary:="%s breaks contact under pursuit" % String(attacker.get("name","The withdrawing army"))
	if prisoners>0: summary+=", leaving %d stragglers captive" % prisoners
	summary+=". %s is %s." % [String(commander.get("name","The commander")),commander_fate]
	return {"type":"withdrawal","summary":summary,"defeated":String(attacker.get("name","Attacker")),"captor":String(defender.get("name","Defender")),"prisoners":prisoners,"spoils":spoils,"captured_general":captured_general,"commander":String(commander.get("name","The commander")),"commander_record":commander.duplicate(true),"commander_fate":commander_fate,"pursuit_pressure":pursuit_pressure}


func respond_to_threat(response:String)->Dictionary:
	if active_threat.is_empty(): return {"error":"No military threat is awaiting a response."}
	var choice:=response.to_lower()
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	var threat:=active_threat.duplicate(true)
	if choice=="defend":
		return begin_threat_engagement()
	if choice=="tribute":
		if String(threat.get("target_region_id",""))!="":
			return {"error":"A strategic-region recapture campaign cannot be bought off with settlement food. Defend the occupation or withdraw from the region."}
		var demanded:=float(threat.get("tribute_food",0.0)); var available:=FoodSystem.total_stored()
		if available<demanded: return {"error":"The demanded tribute requires %.1f Food; only %.1f is stored." % [demanded,available]}
		var paid:=FoodSystem.issue_for_obligation(demanded,"tribute","Tribute under threat")
		if paid+0.0001<demanded:
			FoodSystem.receive_external_food(paid)
			return {"error":"The physical food stores changed before tribute could be transferred."}
		GameState.simulation_metrics["security"]=clampf(float(GameState.simulation_metrics.get("security",0.38))-0.035,0.0,1.0)
		CivilizationSystem.resolve_player_incident(String(threat.get("source_civ_id","")),"tribute",{"food":paid})
		_resolve_threat_without_battle("Tribute paid","The settlement surrendered %.1f Food to avoid battle." % paid)
		return {"resolved":true,"response":choice,"food_paid":paid}
	if choice=="withdraw":
		var target_region_id:=String(threat.get("target_region_id",""))
		if target_region_id!="":
			var source_civ_id:=String(threat.get("source_civ_id",""))
			var abandonment:=CivilizationSystem.abandon_occupied_region(source_civ_id,target_region_id)
			remove_occupation_force(source_civ_id,target_region_id,false)
			_resolve_threat_without_battle("Occupation withdrawn",String(abandonment.get("message","The occupation force yielded the strategic region.")))
			return {"resolved":true,"response":choice,"region_abandoned":target_region_id,"strategic_outcome":abandonment}
		var losses:Dictionary={}
		var protected:Dictionary={}
		var protection:Dictionary=store_protection()
		var base_plunder_fraction:=clampf(float(threat.get("plunder_fraction",0.12)),0.0,1.0)
		var effective_plunder_fraction:=base_plunder_fraction*float(protection.exposed_share)
		for resource_name in ["Food","Timber","Stone","Fiber Plants"]:
			var available:=float(GameState.resource_stockpiles.get(resource_name,0.0))
			var amount:=available*effective_plunder_fraction
			var removed:=FoodSystem.issue_for_obligation(amount,"raid_loss","Food seized during withdrawal") if resource_name=="Food" else amount
			protected[resource_name]=maxf(0.0,available*base_plunder_fraction-removed)
			if resource_name!="Food": GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-removed)
			losses[resource_name]=removed
		var message:="The population yielded ground. Raiders took %.0f%% of reserves; fortified stores protected %.0f%% of the threatened share." % [effective_plunder_fraction*100.0,float(protection.seizure_reduction)*100.0]
		CivilizationSystem.resolve_player_incident(String(threat.get("source_civ_id","")),"withdraw",{"resources":losses})
		_resolve_threat_without_battle("Settlement yields ground",message)
		return {"resolved":true,"response":choice,"resources_lost":losses,"resources_protected":protected,"base_plunder_fraction":base_plunder_fraction,"effective_plunder_fraction":effective_plunder_fraction,"store_protection":protection,"message":message}
	return {"error":"Unknown threat response: %s" % response}


func has_active_operation_for_civ(civ_id:String)->bool:
	if not active_siege.is_empty() and civ_id in [active_siege.attacker_id,active_siege.defender_id]: return true
	if not active_threat.is_empty() and String(active_threat.get("source_civ_id",""))==civ_id: return true
	if not active_engagement.is_empty() and String((active_engagement.get("threat",{}) as Dictionary).get("source_civ_id",""))==civ_id: return true
	return false


func offensive_campaign_availability(civ_id:String,region_id:String="",army_id:int=0)->Dictionary:
	if not active_siege.is_empty(): return {"error":"Resolve the current siege before starting another operation."}
	if not active_engagement.is_empty(): return {"error":"Finish the active campaign engagement first."}
	if not active_threat.is_empty(): return {"error":"Resolve the approaching campaign before launching another."}
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	if region_id=="": return {"error":"Select a known strategic objective before assigning an army to attack it."}
	if field_armies.is_empty(): return {"error":"Form a field army from trained home formations, then move it to the selected strategic objective. Campaign forces no longer teleport from the reserve."}
	var maneuver_army:Dictionary={}
	for force_variant in field_armies:
		var force:Dictionary=force_variant
		if (army_id==0 or int(force.get("army_id",0))==army_id) and String(force.get("status","stationed"))=="stationed" and String(force.get("location_id",""))==region_id and int(force.get("troops",0))>0:
			maneuver_army=force; break
	if maneuver_army.is_empty(): return {"error":"Move a field army to the selected region before launching this campaign. Army movement is no longer instantaneous."}
	var committed_strength:=int(maneuver_army.get("troops",0))
	var incident:=CivilizationSystem.offensive_campaign_data(civ_id,committed_strength,region_id)
	if incident.has("error"): return incident
	incident["field_army_id"]=int(maneuver_army.get("army_id",0))
	return {"ok":true,"incident":incident,"field_army":maneuver_army.duplicate(true)}


func city_force_summary(region_id:String)->String:
	var garrison:=0;var scattered:=0
	for force:Dictionary in occupation_forces:
		if String(force.get("region_id",""))==region_id:garrison+=int(force.get("troops",0))
	for force:Dictionary in field_armies:
		if String(force.get("location_id",""))==region_id:scattered+=int(force.get("scattered_pool",0))
	var text:="%d soldiers in your garrison · %d scattered personnel." % [garrison,scattered]
	for battle:Dictionary in battle_history:
		if String(battle.get("target_region_id",""))!=region_id:continue
		var side:Dictionary=battle.get(String(battle.get("home_side","attacker")),{})
		text="Battle day %d: %d killed, %d wounded, %d scattered. " % [int(battle.get("day",0)),int(side.get("dead",0)),int(side.get("wounded_pool",0)),int(side.get("scattered_pool",0))]+text
		break
	return text

func city_operation_quote(army_id:int,civ_id:String,region_id:String)->Dictionary:
	if not active_engagement.is_empty() or not active_siege.is_empty() or not active_threat.is_empty() or not pending_aftermath.is_empty():return {"error":"Resolve the current battle, siege or aftermath first."}
	var index:=_field_army_index(army_id)
	if index<0 or int(field_armies[index].get("troops",0))<=0:return {"error":"No active soldiers in the selected army. Choose another army."}
	var report:Dictionary=CivilizationSystem.city_intelligence.known("player",region_id)
	if report.is_empty() or _movement_destination(region_id).is_empty():return {"error":"No returned report identifies this destination."}
	if civ_id=="" or civ_id=="player":return {"error":"Identify the foreign settlement before ordering an attack."}
	var point:Dictionary=field_armies[index].get("position",{})
	if not point.has_all(["x","z"]):return {"error":"The army has no valid physical position."}
	var distance:=Vector2(float(point.x),float(point.z)).distance_to(Vector2(float(report.position.x),float(report.position.z)))
	return {"ok":true,"at_target":distance<=0.5,"distance_km":distance,"days":ceili(distance/maxf(.1,_field_army_speed(field_armies[index])))}

func order_city_operation(army_id:int,civ_id:String,region_id:String,besiege:bool=false)->Dictionary:
	var quote:=city_operation_quote(army_id,civ_id,region_id)
	if quote.has("error"):return quote
	var index:=_field_army_index(army_id)
	if not bool(quote.at_target):
		var result:=move_field_army(army_id,region_id)
		if result.has("error"):return result
		field_armies[index]["city_operation"]={"civ_id":civ_id,"region_id":region_id,"besiege":besiege}
		return {"ok":true,"queued":true,"message":"%s: marching %.1f km, about %d days, then %s. War starts on hostile contact, not departure." % [String(field_armies[index].name),float(quote.distance_km),int(quote.days),"besieging the city" if besiege else "attacking the city"]}
	var old_location:=String(field_armies[index].get("location_id",""));var old_status:=String(field_armies[index].get("status","stationed"))
	field_armies[index]["location_id"]=region_id;field_armies[index]["status"]="stationed";field_armies[index].erase("city_operation")
	var result:=start_offensive_siege(civ_id,region_id,army_id) if besiege else launch_offensive(civ_id,region_id,army_id)
	if result.has("error"):
		field_armies[index]["location_id"]=old_location;field_armies[index]["status"]=old_status
	return result

func launch_offensive(civ_id:String,region_id:String="",army_id:int=0)->Dictionary:
	var availability:=offensive_campaign_availability(civ_id,region_id,army_id)
	if availability.has("error"): return availability
	var incident:Dictionary=availability.incident
	_create_civilization_threat(incident,"offensive")
	var result:=begin_threat_engagement()
	if not result.has("error"):
		active_engagement.threat["war_id"]=CivilizationSystem.record_player_hostile_order(civ_id,region_id,"A player army attacked the settlement without awaiting a declaration.")
	return result


func raid_campaign_availability(civ_id:String,region_id:String="")->Dictionary:
	if not active_siege.is_empty(): return {"error":"Resolve the siege before launching a raid."}
	if not active_engagement.is_empty() or not active_threat.is_empty(): return {"error":"Resolve the current military operation first."}
	if not pending_aftermath.is_empty(): return {"error":"Resolve the current battle aftermath first."}
	if region_id=="": return {"error":"Select a known strategic region to raid."}
	var maneuver_army:Dictionary={}
	for force_variant in field_armies:
		var force:Dictionary=force_variant
		if String(force.get("status","stationed"))=="stationed" and String(force.get("location_id",""))==region_id and int(force.get("troops",0))>0:
			maneuver_army=force
			break
	if maneuver_army.is_empty(): return {"error":"Move a field army to the selected region before ordering a raid."}
	var incident:=CivilizationSystem.offensive_campaign_data(civ_id,int(maneuver_army.get("troops",0)),region_id,true)
	if incident.has("error"): return incident
	incident["field_army_id"]=int(maneuver_army.get("army_id",0))
	return {"ok":true,"incident":incident,"field_army":maneuver_army.duplicate(true)}


func launch_raid(civ_id:String,region_id:String="")->Dictionary:
	var availability:=raid_campaign_availability(civ_id,region_id)
	if availability.has("error"): return availability
	_create_civilization_threat(availability.incident,"offensive")
	return begin_threat_engagement()


func _resolve_threat_without_battle(title:String,description:String)->void:
	active_threat.clear(); threats_resolved+=1; threat_changed.emit({})
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":title,"description":description,"domain":"security","severity":"warning"})


func _process_threat_day()->void:
	if not active_siege.is_empty(): return
	if not active_engagement.is_empty():
		if bool(active_engagement.get("awaiting_player_view",false)):return
		advance_engagement("hold")
		return
	if not active_threat.is_empty():
		if int(GameState.elapsed_days)>int(active_threat.get("deadline_day",GameState.elapsed_days)) and pending_aftermath.is_empty():
			var occupation_defense:=occupation_force_for_region(String(active_threat.get("source_civ_id","")),String(active_threat.get("target_region_id","")))
			if int(settlement_defense.get("stage",0))>=1 and String(active_threat.get("target_region_id",""))=="" and not bool(active_threat.get("field_encounter",false)) and String(active_threat.get("incident_kind","campaign"))!="raid":
				var investment:=begin_siege()
				if bool(investment.get("ok",false)): return
			respond_to_threat("defend" if int(settlement_defense_snapshot().get("garrison_personnel",0))>0 or int(occupation_defense.get("troops",0))>0 else "withdraw")
			while not active_engagement.is_empty() and not bool(active_engagement.get("awaiting_player_view",false)): advance_engagement("hold")
		return
	if not GameState.settlement_site_committed or int(GameState.elapsed_days)<90 or not pending_aftermath.is_empty(): return
	var incident:=CivilizationSystem.consume_player_incident()
	if incident.is_empty(): return
	_create_civilization_threat(incident,"defensive")


func _create_civilization_threat(incident:Dictionary,campaign_mode:String="defensive")->void:
	var strength:=maxi(3,int(incident.get("strength",3)))
	var technology:=clampf(float(incident.get("technology",0.15)),0.0,1.0)
	var readiness:=clampf(float(incident.get("readiness",0.5)),0.1,1.0)
	var source_name:=String(incident.get("source_name","RIVAL POLITY"))
	var rng:=RandomNumberGenerator.new(); rng.seed=GameState.world_seed^int(GameState.elapsed_days)*104729^String(incident.get("id","")).hash()
	var enemy_formations:Array[Dictionary]=[]
	if technology>=0.52:
		var archers:=roundi(float(strength)*0.28); var line:=roundi(float(strength)*0.38); var levy:=strength-archers-line
		enemy_formations=[{"unit":"levy","weapon":"improvised","count":levy,"equipment":levy},{"unit":"line_infantry","weapon":"spear","count":line,"equipment":line},{"unit":"skirmisher","weapon":"bow","count":archers,"equipment":archers,"ammunition":archers*6}]
	elif technology>=0.27:
		var line:=roundi(float(strength)*0.42); enemy_formations=[{"unit":"levy","weapon":"improvised","count":strength-line,"equipment":strength-line},{"unit":"line_infantry","weapon":"spear","count":line,"equipment":line}]
	else: enemy_formations=[{"unit":"levy","weapon":"improvised","count":strength,"equipment":strength}]
	var enemy_morale:=clampf(0.42+readiness*0.42+float(war_reputation.get("grievance",0.0))*0.08-float(war_reputation.get("fear",0.0))*0.07,0.32,0.92)
	var enemy:Dictionary=simulator.create_formation_force("%s FIELD HOST" % source_name,enemy_formations,enemy_morale,readiness)
	enemy["commander"]=simulator.create_commander("%s FIELD STAFF" % source_name,rng.randf_range(0.38,0.72),rng.randf_range(0.38,0.72),rng.randf_range(0.30,0.68),rng.randf_range(0.42,0.78))
	var offensive:=campaign_mode=="offensive"
	var is_raid:=String(incident.get("incident_kind","campaign"))=="raid"
	var target_name:=String(incident.get("target_region_name",""))
	var threat_title:="Raid on %s" % target_name if is_raid and offensive else ("%s raiders approaching" % source_name if is_raid else ("Campaign for %s" % target_name if offensive and target_name!="" else ("Campaign against %s" % source_name if offensive else ("%s moves to recapture %s" % [source_name,target_name] if target_name!="" else "%s campaign approaching" % source_name))))
	var report_text:="The raiding column is committed against %s: scouts estimate about %d defenders. Victory may seize portable stores but will not occupy the region." % [target_name,strength] if is_raid and offensive else ("Watchers report roughly %d %s raiders moving toward local stores. Muster the garrison, pay them off, or yield before they arrive." % [strength,source_name] if is_raid else ("The field host is committed against %s: scouts estimate an aggregate defending capacity of %d." % [target_name if target_name!="" else source_name,strength] if offensive else ("%s is moving roughly %d personnel to retake %s. Its occupation force will defend within seven days." % [source_name,strength,target_name] if target_name!="" else "Scouts identify an organized %s field host of roughly %d. A response is required within seven days." % [source_name,strength])))
	active_threat={"id":"threat_%d_%d" % [int(GameState.elapsed_days),threats_resolved],"title":threat_title,"incident_kind":String(incident.get("incident_kind","campaign")),"campaign_mode":campaign_mode,"source_civ_id":String(incident.get("source_civ_id","")),"source_name":source_name,"field_encounter":bool(incident.get("field_encounter",false)),"formation_id":String(incident.get("formation_id","")),"target_region_id":String(incident.get("target_region_id","")),"target_position":incident.get("target_position",{}).duplicate(true),"target_region_name":String(incident.get("target_region_name","")),"target_region_role":String(incident.get("target_region_role","")),"target_population":float(incident.get("target_population",0.0)),"occupation_required":float(incident.get("occupation_required",0.0)),"recapture_campaign":bool(incident.get("recapture_campaign",false)),"field_army_id":int(incident.get("field_army_id",0)),"discovered_day":int(GameState.elapsed_days),"deadline_day":int(GameState.elapsed_days)+(9999 if offensive else 7),"terrain_defense":float(incident.get("terrain_defense",_terrain_defense())),"enemy_force":enemy,"estimated_strength":strength,"tribute_food":maxf(5.0,float(strength)*2.5),"plunder_fraction":rng.randf_range(0.08,0.18),"seed":rng.randi()}
	GameState.council_inbox.push_front({"id":String(active_threat.id),"advisor":"MARSHAL'S OFFICE","office":"Marshal","topic":"security","act":{"type":"report"},"text":report_text,"urgency":0.96,"day":int(GameState.elapsed_days),"status":"unread"})
	threat_changed.emit(active_threat.duplicate(true))


func prisoner_food_demand()->float:
	return float(foreign_prisoners)*0.65+float(held_generals.size())


func receive_scout_captives(count:int)->Dictionary:
	var accepted:=maxi(0,count)
	foreign_prisoners+=accepted
	return {"accepted":accepted,"foreign_prisoners":foreign_prisoners}


func register_scout_interrogation(method:String,deaths:int=0)->Dictionary:
	var normalized:=method.to_lower()
	var removed:=mini(maxi(0,deaths),foreign_prisoners)
	foreign_prisoners-=removed
	match normalized:
		"question": _adjust_war_reputation(0.002,0.0,0.0)
		"coerce": _adjust_war_reputation(0.0,0.012,0.025)
		"torture": _adjust_war_reputation(0.0,0.055,0.090)
	return {"method":normalized,"deaths":removed,"foreign_prisoners":foreign_prisoners,"reputation":war_reputation.duplicate(true)}


func field_provision_delivery_ratio()->float:
	if recovery.home_unavailable():return 0.0
	var troops:=int(home_army.get("troops",0))+field_army_active_personnel()+occupation_active_personnel()
	if troops<=0: return 1.0
	var workers:=float(GameState.population_allocations.get("Logistics",0))
	var labor_coverage:=clampf(workers/maxf(1.0,float(troops)*0.09),0.0,1.0)
	var commander_logistics:=clampf(float((home_army.get("commander",{}) as Dictionary).get("logistics",0.4)),0.0,1.0)
	var carts:=float(GameState.resource_stockpiles.get("Transport Carts",0.0))
	var cart_coverage:=clampf(carts/maxf(1.0,float(troops)/24.0),0.0,1.0)
	return clampf(0.08+labor_coverage*0.42+commander_logistics*0.20+_adoption("supply_groups")*0.20+cart_coverage*0.10,0.0,1.0)


func record_daily_provisions(required:float,delivered:float)->void:
	if home_army.is_empty() and occupation_forces.is_empty() and field_armies.is_empty(): return
	var need:=maxf(0.0,required)
	var received:=clampf(delivered,0.0,need)
	var total_active:=maxi(1,int(home_army.get("troops",0))+field_army_active_personnel()+occupation_active_personnel())
	var provision_ratio:=received/maxf(0.01,need) if need>0.0 else 1.0
	if not home_army.is_empty():
		var home_share:=float(maxi(0,int(home_army.get("troops",0))))/float(total_active)
		var home_need:=need*home_share
		var home_received:=received*home_share
		home_army["provisions_required_today"]=home_need
		home_army["provisions_delivered_today"]=home_received
		home_army["provision_ratio"]=provision_ratio
		home_army["provision_day"]=int(GameState.elapsed_days)
		var shortfall:=maxf(0.0,home_need-home_received)
		home_army["provision_shortfall_total"]=float(home_army.get("provision_shortfall_total",0.0))+shortfall
		home_army["provision_shortfall_days"]=int(home_army.get("provision_shortfall_days",0))+1 if shortfall>0.01 else 0
		var condition_target:=clampf(GameState.population_health*0.55+GameState.food_security*0.20+provision_ratio*0.25-float(home_army.get("service_strain",0))*.20,0.0,1.0)
		var formations:Array=home_army.get("formations",[])
		for index in formations.size(): formations[index]["personnel_condition"]=move_toward(float(formations[index].get("personnel_condition",condition_target)),condition_target,0.014)
		home_army["formations"]=formations
	for force_index in field_armies.size():
		var force:Dictionary=field_armies[force_index]
		var share:=float(maxi(0,int(force.get("troops",0))))/float(total_active)
		force["provisions_required_today"]=need*share
		force["provisions_delivered_today"]=received*share
		force["provision_ratio"]=provision_ratio
		force["provision_day"]=int(GameState.elapsed_days)
		force["supply_level"]=move_toward(float(force.get("supply_level",0.5)),provision_ratio,0.055 if String(force.get("status","stationed"))=="stationed" else 0.025)
		var field_condition:=clampf(GameState.population_health*0.48+GameState.food_security*0.17+provision_ratio*0.35,0.0,1.0)
		var field_formations:Array=force.get("formations",[])
		for formation_index in field_formations.size(): field_formations[formation_index]["personnel_condition"]=move_toward(float(field_formations[formation_index].get("personnel_condition",field_condition)),field_condition,0.016)
		force["formations"]=field_formations
		field_armies[force_index]=force
	for force_index in occupation_forces.size():
		var force:Dictionary=occupation_forces[force_index]
		var share:=float(maxi(0,int(force.get("troops",0))))/float(total_active)
		force["provisions_required_today"]=need*share
		force["provisions_delivered_today"]=received*share
		force["provision_ratio"]=provision_ratio
		force["provision_day"]=int(GameState.elapsed_days)
		force["supply_level"]=move_toward(float(force.get("supply_level",0.5)),provision_ratio,0.08)
		var occupation_condition:=clampf(GameState.population_health*0.48+GameState.food_security*0.17+provision_ratio*0.35,0.0,1.0)
		var occupation_formations:Array=force.get("formations",[])
		for formation_index in occupation_formations.size(): occupation_formations[formation_index]["personnel_condition"]=move_toward(float(occupation_formations[formation_index].get("personnel_condition",occupation_condition)),occupation_condition,0.018)
		force["formations"]=occupation_formations
		occupation_forces[force_index]=force


func prisoner_custody_snapshot()->Dictionary:
	var guards:=float(GameState.population_allocations.get("Defense",0))*0.18
	var coverage:=clampf(guards/maxf(1.0,float(foreign_prisoners)+float(held_generals.size())*2.0),0.0,1.0)
	return {"prisoners":foreign_prisoners,"held_generals":held_generals.size(),"custody_days":prisoner_custody_days,"guard_coverage":coverage,"food_demand":prisoner_food_demand(),"escape_risk":maxf(0.0,1.0-coverage),"escaped_total":escaped_prisoners_total}


func exchange_prisoners(count:int)->Dictionary:
	var home_captives:=maxi(0,int(home_army.get("captured_pool",0)))
	var exchanges:=mini(maxi(0,count),mini(foreign_prisoners,home_captives))
	if exchanges<=0: return {"error":"No matched prisoner cohorts are available for exchange."}
	foreign_prisoners-=exchanges
	var returned:=_return_home_captives(exchanges)
	return {"exchanged":returned,"returned_population":returned,"foreign_prisoners":foreign_prisoners}


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
	HistoricalFigures.resolve_captive(String(general.get("figure_id","")),normalized)
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
	if normalized_prisoners=="exchange" and prisoners_before>0 and int(home_army.get("captured_pool",0))<=0: return {"error":"No home captive cohort is available for a prisoner exchange."}
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
	var total:=_mobilized_count()
	var defense_allocation:=int(GameState.population_allocations.get("Defense",0))
	var assigned_defense:=mini(total,defense_allocation)
	var by_role:Dictionary={"Defense":assigned_defense}
	if total>assigned_defense: by_role["Other labor displaced"]=total-assigned_defense
	return {"population_withheld":total,"former_roles":by_role,"defense_allocation":defense_allocation}


func export_state()->Dictionary:
	return {
		"version":SAVE_VERSION,
		"world_seed":GameState.world_seed,
		"historical_figures":HistoricalFigures.export_state(),
		"people_direction":PeopleDirection.export_state(),
		"last_processed_day":last_processed_day,
		"home_army":home_army.duplicate(true),
		"battle_history":battle_history.duplicate(true),
		"pending_aftermath":pending_aftermath.duplicate(true),
		"military_inventory":military_inventory.duplicate(true),
		"military_consumables":military_consumables.duplicate(true),
		"damaged_equipment":damaged_equipment.duplicate(true),
		"aggregate_recruits":aggregate_recruits,
		"training_queue":training_queue.duplicate(true),
		"training_injury_pool":training_injury_pool,
		"training_injury_recovery_accumulator":training_injury_recovery_accumulator,
		"training_program":training_program.duplicate(true),
		"last_training_program":last_training_program.duplicate(true),
		"command_development":command_development.duplicate(true),
		"training_program_cycles":training_program_cycles,
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
		"active_siege":active_siege.duplicate(true),
		"siege_history":siege_history.duplicate(true),
		"war_reputation":war_reputation.duplicate(true),
		"occupation_forces":occupation_forces.duplicate(true),
		"occupation_transfers":occupation_transfers.data.duplicate(true),
		"siege_recovery":recovery.data.duplicate(true),
		"field_armies":field_armies.duplicate(true),
		"runner_messages":runner_messages.duplicate(true),
		"army_templates":army_templates.duplicate(true),
		"next_army_template_id":next_army_template_id,
		"next_field_army_id":next_field_army_id,
		"settlement_defense":settlement_defense.duplicate(true)
	}


func import_state(payload:Dictionary)->Dictionary:
	if not payload.get("siege_recovery",{}) is Dictionary:return {"error":"Invalid siege recovery state."}
	var recovery_errors:Array[String]=preload("res://scripts/siege_recovery.gd").validate(payload.get("siege_recovery",{}))
	if not recovery_errors.is_empty():return {"error":"Invalid siege recovery state.","details":recovery_errors}
	if not payload.get("occupation_transfers",{}) is Dictionary: return {"error":"Invalid occupation population state."}
	var transfer_errors:Array[String]=preload("res://scripts/occupation_transfers.gd").validate(payload.get("occupation_transfers",{}))
	if not transfer_errors.is_empty(): return {"error":"Invalid occupation population state.","details":transfer_errors}
	if not payload.get("runner_messages",[]) is Array: return {"error":"Invalid runner messages."}
	for message in payload.get("runner_messages",[]):
		if not message is Dictionary or not message.get("snapshot",{}) is Dictionary or not CivilizationSystem.city_intelligence.valid_carried(message.get("snapshot",{})): return {"error":"Invalid carried city observation."}
	var siege_error:=SiegeModel.validate(payload.get("active_siege",{}))
	if not siege_error.is_empty(): return {"error":siege_error}
	if not payload.get("siege_history",[]) is Array or payload.get("siege_history",[]).size()>SiegeModel.HISTORY_LIMIT: return {"error":"Invalid siege history."}
	for history in payload.get("siege_history",[]):
		var history_error:=SiegeModel.validate(history)
		if not history_error.is_empty(): return {"error":history_error}
	var incoming:=payload.duplicate(true)
	var incoming_version:=int(incoming.get("version",-1))
	if incoming_version in [1,2,3]: incoming=_migrate_legacy_state(incoming)
	elif incoming_version in [4,5,6]:
		if incoming_version==4: incoming["settlement_defense"]=_default_settlement_defense()
		incoming["field_armies"]=[]
		incoming["next_field_army_id"]=1
		incoming["version"]=SAVE_VERSION
	elif incoming_version!=SAVE_VERSION: return {"error":"Unsupported military save version."}
	if int(incoming.get("world_seed",GameState.world_seed))!=GameState.world_seed: return {"error":"Military save belongs to a different world."}
	var previous:=export_state()
	if incoming.has("historical_figures"):
		var figure_result:=HistoricalFigures.import_state(incoming.historical_figures)
		if figure_result.has("error"): return figure_result
	if incoming.has("people_direction"):
		var direction_result:=PeopleDirection.import_state(incoming.people_direction)
		if direction_result.has("error"):
			HistoricalFigures.import_state(previous.historical_figures)
			return direction_result
	_apply_imported_state(incoming)
	var errors:=validate_state()
	if not errors.is_empty():
		_apply_imported_state(previous)
		HistoricalFigures.import_state(previous.historical_figures)
		PeopleDirection.import_state(previous.people_direction)
		return {"error":"Invalid military save state.","details":errors}
	last_world_seed=GameState.world_seed
	return {"ok":true,"version":SAVE_VERSION}


func _migrate_legacy_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	var army:Dictionary=migrated.get("home_army",{})
	var formation_id:=1
	for formation in army.get("formations",[]):
		formation["id"]=formation_id; formation_id+=1
		formation["experience"]=clampf(float(formation.get("experience",0.0)),0.0,1.0)
		formation.erase("soldier_ids")
	army.erase("soldier_ids")
	army.erase("wounded_ids")
	army.erase("scattered_ids")
	army.erase("captured_ids")
	army["supply_level"]=float(army.get("supply_level",1.0))
	army["supply_components"]=army.get("supply_components",{"nutrition":1.0,"delivery":1.0,"target":1.0})
	migrated["home_army"]=army
	var order_id:=1
	for order in migrated.get("training_queue",[]):
		order["id"]=int(order.get("id",order_id)); order_id=maxi(order_id+1,int(order.id)+1)
		order["injury_accumulator"]=float(order.get("injury_accumulator",0.0))
		order.erase("soldier_ids")
	migrated["aggregate_recruits"]=maxi(0,int(migrated.get("aggregate_recruits",(migrated.get("recruit_pool",[]) as Array).size())))
	migrated.erase("recruit_pool")
	migrated["training_injury_pool"]=maxi(0,int(migrated.get("training_injury_pool",(migrated.get("training_injuries",[]) as Array).size())))
	migrated["training_injury_recovery_accumulator"]=0.0
	migrated.erase("training_injuries")
	migrated["damaged_equipment"]=migrated.get("damaged_equipment",{})
	migrated["next_training_order_id"]=order_id
	migrated["next_formation_id"]=formation_id
	migrated["occupation_forces"]=migrated.get("occupation_forces",[])
	migrated["field_armies"]=[]
	migrated["next_field_army_id"]=1
	migrated["settlement_defense"]=_default_settlement_defense()
	migrated["version"]=SAVE_VERSION
	return migrated


func validate_state()->Array[String]:
	var errors:Array[String]=[]
	var siege_error:=SiegeModel.validate(active_siege)
	if not siege_error.is_empty(): errors.append(siege_error)
	if not active_siege.is_empty():
		if not active_engagement.is_empty() or not active_threat.is_empty(): errors.append("A siege cannot duplicate another active encounter.")
		if String(active_siege.get("mode",""))=="offensive" and _field_army_index(int(active_siege.get("army_id",0)))<0: errors.append("The siege references a missing field army.")
	if siege_history.size()>SiegeModel.HISTORY_LIMIT: errors.append("Siege history exceeds its bound.")
	for history in siege_history:
		var history_error:=SiegeModel.validate(history)
		if not history_error.is_empty(): errors.append(history_error)
	var formations:Array=home_army.get("formations",[])
	var formation_total:=0
	var formation_ids:Dictionary={}
	for formation in formations:
		var count:=int(formation.get("count",0))
		var authorized:=int(formation.get("authorized_count",count))
		var equipment:=int(formation.get("equipment",0))
		var expected_equipment_required:=_equipment_required_for(String(formation.get("unit","levy")),authorized)
		var equipment_required:=int(formation.get("equipment_required",expected_equipment_required))
		formation_total+=count
		if count<0 or equipment<0: errors.append("Formation has a negative personnel or equipment count.")
		if authorized<count or authorized<0: errors.append("Formation personnel exceeds its authorized strength.")
		if equipment_required!=expected_equipment_required: errors.append("Formation equipment requirement does not match its authorized strength.")
		if equipment>equipment_required: errors.append("Formation has more issued equipment than its authorized capacity.")
		var ammunition:=int(formation.get("ammunition",0))
		var ammunition_required:=int(formation.get("ammunition_required",0))
		if ammunition<0 or ammunition_required<0 or ammunition>ammunition_required: errors.append("Formation ammunition is outside its authorized capacity.")
		if formation.has("soldier_ids"): errors.append("Formation contains forbidden individual soldier records.")
		var formation_id:=int(formation.get("id",-1))
		if formation_id<=0 or formation_ids.has(formation_id): errors.append("Formation IDs must be positive and unique.")
		formation_ids[formation_id]=true
		for bounded_value in ["training","experience","personnel_condition"]:
			var value:=float(formation.get(bounded_value,0.0))
			if not is_finite(value) or value<0.0 or value>1.25: errors.append("Formation %s is outside its valid range." % bounded_value)
	if formation_total!=int(home_army.get("troops",0)): errors.append("Formation manpower does not equal army troop total.")
	for forbidden_key in ["soldier_ids","wounded_ids","scattered_ids","captured_ids"]:
		if home_army.has(forbidden_key): errors.append("Army contains forbidden individual-person roster: %s." % forbidden_key)
	for pool_key in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool","reserve_manpower"]:
		if int(home_army.get(pool_key,0))<0: errors.append("Military population pool %s cannot be negative." % pool_key)
	if int(home_army.get("disabled_pool",0))>int(home_army.get("wounded_pool",0)) or int(home_army.get("severe_disabled_pool",0))>int(home_army.get("disabled_pool",0)): errors.append("Disabling injuries must remain subsets of surviving wounded.")
	if aggregate_recruits<0 or training_injury_pool<0: errors.append("Military population pools cannot be negative.")
	for command_skill in ["command","tactics","logistics","resolve"]:
		var development:=float(command_development.get(command_skill,0.0))
		if not is_finite(development) or development<0.0 or development>0.30: errors.append("Command development %s is outside its bounded range." % command_skill)
	var exercise_bonus:=float(home_army.get("exercise_readiness_bonus",0.0))
	if not is_finite(exercise_bonus) or exercise_bonus<0.0 or exercise_bonus>0.20: errors.append("Exercise readiness is outside its bounded range.")
	if training_program_cycles<0: errors.append("Completed training cycle count cannot be negative.")
	if not training_program.is_empty():
		var program_id:=String(training_program.get("id",""))
		if not TRAINING_PROGRAMS.has(program_id): errors.append("Active training program references an unknown choice.")
		else:
			var program_progress:=float(training_program.get("progress_days",-1.0))
			var program_duration:=float(training_program.get("duration_days",0.0))
			if not is_finite(program_progress) or not is_finite(program_duration) or program_progress<0.0 or program_duration<=0.0 or program_progress>=program_duration: errors.append("Active training-program progress is outside its duration.")
			for program_counter in ["food_required_total","food_consumed_total","wear_accumulator"]:
				var counter_value:=float(training_program.get(program_counter,0.0))
				if not is_finite(counter_value) or counter_value<0.0: errors.append("Training-program %s must be finite and nonnegative." % program_counter)
			if int(training_program.get("participants",0))<0 or int(training_program.get("equipment_worn",0))<0: errors.append("Training-program aggregate counts cannot be negative.")
	var training_order_ids:Dictionary={}
	var planned_reinforcements:Dictionary={}
	for training in training_queue:
		var training_id:=int(training.get("id",-1))
		if training_id<=0 or training_order_ids.has(training_id): errors.append("Training order IDs must be positive and unique.")
		training_order_ids[training_id]=true
		var training_mode:=String(training.get("mode","new"))
		var training_unit:=String(training.get("unit",""))
		var training_weapon:=String(training.get("weapon",""))
		var training_count:=int(training.get("count",0))
		var training_progress:=float(training.get("progress_days",0.0))
		var training_required:=float(training.get("required_days",0.0))
		var injury_progress:=float(training.get("injury_accumulator",0.0))
		if int(training.get("reserved_equipment",0))<0:errors.append("Reserved training equipment cannot be negative.")
		if training.has("build_batch") and int(training.build_batch)<=0:errors.append("Invalid training batch identity.")
		if training.has("soldier_ids"): errors.append("Training order contains forbidden individual soldier records.")
		if training_mode not in ["new","reinforce","retrain"]: errors.append("Training order has an unknown mode.")
		if not simulator.UNIT_TYPES.has(training_unit): errors.append("Training order references an unknown unit type.")
		if not simulator.WEAPONS.has(training_weapon) or training_weapon not in UnitCatalog.equipment_for(training_unit): errors.append("Training order uses incompatible equipment.")
		if training_count<=0: errors.append("Training order headcount must be positive.")
		if not is_finite(training_progress) or not is_finite(training_required) or training_progress<0.0 or training_required<=0.0 or (training_progress>=training_required and not training.has("build_batch")): errors.append("Training order progress is outside its duration.")
		if not is_finite(injury_progress) or injury_progress<0.0 or injury_progress>=1.0: errors.append("Training injury accumulation is outside its valid range.")
		if training_mode=="reinforce":
			var target_formation_id:=int(training.get("target_formation_id",-1))
			if not formation_ids.has(target_formation_id): errors.append("Reinforcement order targets a missing formation.")
			else: planned_reinforcements[target_formation_id]=int(planned_reinforcements.get(target_formation_id,0))+training_count
	for formation in formations:
		var formation_id:=int(formation.get("id",-1))
		var vacancies:=maxi(0,int(formation.get("authorized_count",formation.get("count",0)))-int(formation.get("count",0)))
		if int(planned_reinforcements.get(formation_id,0))>vacancies: errors.append("Reinforcement orders exceed a formation's authorized vacancies.")
	for item in military_inventory:
		if int(military_inventory[item])<0: errors.append("Military inventory for %s is negative." % item)
	for item in military_consumables:
		if int(military_consumables[item])<0: errors.append("Military consumables for %s are negative." % item)
	for item in damaged_equipment:
		if int(damaged_equipment[item])<0: errors.append("Damaged-equipment inventory for %s is negative." % item)
	if foreign_prisoners<0 or prisoner_custody_days<0 or escaped_prisoners_total<0: errors.append("Prisoner custody counters cannot be negative.")
	if not is_finite(prisoner_escape_accumulator) or prisoner_escape_accumulator<0.0: errors.append("Prisoner escape accumulation must be finite and nonnegative.")
	if not active_threat.is_empty() and not active_engagement.is_empty(): errors.append("A pending threat and active engagement cannot coexist.")
	if not active_engagement.is_empty():
		if String(active_engagement.get("home_side","")) not in ["attacker","defender"]: errors.append("Active engagement does not identify the home force side.")
		if String(active_engagement.get("campaign_mode","")) not in ["offensive","defensive"]: errors.append("Active engagement has an invalid campaign mode.")
		if String(active_engagement.get("home_force_kind","field")) not in ["field","field_army","occupation"]: errors.append("Active engagement has an invalid home-force kind.")
	if occupation_forces.size()>MAX_OCCUPATION_FORCES: errors.append("Occupation forces exceed their fixed strategic-region bound.")
	var occupation_keys:Dictionary={}
	for force_variant in occupation_forces:
		if not force_variant is Dictionary: errors.append("Occupation force record is malformed."); continue
		var force:Dictionary=force_variant
		var civ_id:=String(force.get("civ_id","")); var region_id:=String(force.get("region_id",""))
		var key:="%s:%s" % [civ_id,region_id]
		if civ_id=="" or region_id=="" or occupation_keys.has(key): errors.append("Occupation forces must identify one unique strategic region.")
		occupation_keys[key]=true
		var occupation_formation_total:=0
		for formation in force.get("formations",[]):
			occupation_formation_total+=maxi(0,int(formation.get("count",0)))
			if formation.has("soldier_ids"): errors.append("Occupation formation contains forbidden individual soldier records.")
		if occupation_formation_total!=int(force.get("troops",0)): errors.append("Occupation formation manpower does not equal its troop total.")
		if int(force.get("troops",0))<0 or not is_finite(float(force.get("required",0.0))) or float(force.get("required",0.0))<0.0: errors.append("Occupation force strength or requirement is invalid.")
	if field_armies.size()>ABSOLUTE_MAX_FIELD_ARMIES: errors.append("Field armies exceed the fixed command bound.")
	var field_army_ids:Dictionary={}
	var greatest_field_army_id:=0
	for force_variant in field_armies:
		if not force_variant is Dictionary: errors.append("Field army record is malformed."); continue
		var force:Dictionary=force_variant
		var army_id:=int(force.get("army_id",0)); greatest_field_army_id=maxi(greatest_field_army_id,army_id)
		if army_id<=0 or field_army_ids.has(army_id): errors.append("Field army IDs must be positive and unique.")
		field_army_ids[army_id]=true
		if String(force.get("status","")) not in ["stationed","moving","besieging"]: errors.append("Field army has an invalid movement status.")
		var investing:=not active_siege.is_empty() and String(active_siege.get("mode",""))=="offensive" and int(active_siege.get("army_id",0))==army_id
		if (String(force.get("status",""))=="besieging")!=investing: errors.append("Field army siege status does not match its operation.")
		if investing and String(force.get("location_id",""))!=String(active_siege.get("region_id","")): errors.append("Investing army is not at its siege target.")
		var field_total:=0
		for formation in force.get("formations",[]):
			field_total+=maxi(0,int(formation.get("count",0)))
			if formation.has("soldier_ids"): errors.append("Field army formation contains forbidden individual soldier records.")
		if field_total!=int(force.get("troops",0)): errors.append("Field army formation manpower does not equal its troop total.")
		if int(force.get("troops",0))<0: errors.append("Field army personnel cannot be negative.")
		for pool_key in ["wounded_pool","scattered_pool","captured_pool"]:
			if int(force.get(pool_key,0))<0: errors.append("Field army population pool %s cannot be negative." % pool_key)
		for distance_key in ["distance_total_km","distance_remaining_km"]:
			var distance_value:=float(force.get(distance_key,0.0))
			if not is_finite(distance_value) or distance_value<0.0: errors.append("Field army movement distance is invalid.")
		var position:Variant=force.get("position",{})
		if not position is Dictionary or not is_finite(float(position.get("x",NAN))) or not is_finite(float(position.get("z",NAN))): errors.append("Field army position is malformed.")
	if next_field_army_id<=greatest_field_army_id: errors.append("Next field army ID would duplicate an existing army.")
	var equipment_job_ids:Dictionary={}
	if equipment_queue.size()>ABSOLUTE_MAX_PRODUCTION_LINES: errors.append("Military production exceeds the fixed line bound.")
	for job in equipment_queue:
		var job_id:=int(job.get("id",-1))
		if job_id<=0 or equipment_job_ids.has(job_id): errors.append("Equipment job IDs must be positive and unique.")
		equipment_job_ids[job_id]=true
		var job_count:=int(job.get("count",0))
		var job_completed:=int(job.get("completed",0))
		var job_progress:=float(job.get("progress_days",0.0))
		var job_work_per_item:=float(job.get("work_per_item",0.0))
		var line_allocation:=float(job.get("allocation",1.0))
		var line_efficiency:=float(job.get("efficiency",0.20))
		if job_count<=0 or job_completed<0 or job_completed>=job_count: errors.append("Equipment job completion is outside its order size.")
		if not is_finite(job_progress) or not is_finite(job_work_per_item) or job_progress<0.0 or job_work_per_item<=0.0: errors.append("Equipment job work values must be finite and positive.")
		if not is_finite(line_allocation) or line_allocation<0.05 or line_allocation>4.0: errors.append("Production line allocation is outside its bounded range.")
		if not is_finite(line_efficiency) or line_efficiency<0.10 or line_efficiency>1.0: errors.append("Production line efficiency is outside its bounded range.")
	if next_training_order_id<_next_available_training_order_id(): errors.append("Next training order ID would duplicate an existing order.")
	if next_formation_id<_next_available_formation_id(): errors.append("Next formation ID would duplicate an existing formation.")
	if next_equipment_job_id<_next_available_equipment_job_id(): errors.append("Next equipment job ID would duplicate an existing job.")
	_ensure_settlement_defense()
	var defense_stage:=int(settlement_defense.get("stage",-1)); var defense_project:=int(settlement_defense.get("project_stage",-2))
	if defense_stage<0 or defense_stage>=SETTLEMENT_DEFENSE_STAGES.size(): errors.append("Settlement defense stage is outside its fixed progression.")
	if defense_project<-1 or defense_project>=SETTLEMENT_DEFENSE_STAGES.size(): errors.append("Settlement defense project stage is invalid.")
	if defense_project>=0 and defense_project!=defense_stage+1: errors.append("Settlement defense project must advance exactly one stage.")
	for value_key in ["integrity","project_progress"]:
		var value:=float(settlement_defense.get(value_key,-1.0))
		if not is_finite(value) or value<0.0 or value>1.0: errors.append("Settlement defense %s must be normalized." % value_key)
	if not settlement_defense.get("reserved_materials",{}) is Dictionary: errors.append("Settlement defense material reserve is malformed.")
	return errors

func _apply_imported_state(payload:Dictionary)->void:
	recovery.reset()
	recovery.data.merge(payload.get("siege_recovery",{}).duplicate(true),true)
	occupation_transfers.reset()
	occupation_transfers.data.merge(payload.get("occupation_transfers",{}).duplicate(true),true)
	active_siege=(payload.get("active_siege",{}) as Dictionary).duplicate(true)
	siege_history.assign(payload.get("siege_history",[]))
	last_processed_day=int(payload.get("last_processed_day",int(GameState.elapsed_days)))
	home_army=(payload.get("home_army",{}) as Dictionary).duplicate(true)
	_normalize_formation_ammunition()
	battle_history.assign(payload.get("battle_history",[]))
	pending_aftermath=(payload.get("pending_aftermath",{}) as Dictionary).duplicate(true)
	military_inventory=_empty_equipment_inventory()
	for item in (payload.get("military_inventory",{}) as Dictionary): military_inventory[item]=int(payload.military_inventory[item])
	military_consumables=_empty_consumable_inventory()
	for item in (payload.get("military_consumables",{}) as Dictionary): military_consumables[item]=int(payload.military_consumables[item])
	damaged_equipment=_empty_equipment_inventory()
	for item in (payload.get("damaged_equipment",{}) as Dictionary): damaged_equipment[item]=int(payload.damaged_equipment[item])
	aggregate_recruits=maxi(0,int(payload.get("aggregate_recruits",0)))
	training_queue.assign(payload.get("training_queue",[]))
	for order in training_queue: order.erase("soldier_ids")
	training_injury_pool=maxi(0,int(payload.get("training_injury_pool",0)))
	training_injury_recovery_accumulator=maxf(0.0,float(payload.get("training_injury_recovery_accumulator",0.0)))
	training_program=(payload.get("training_program",{}) as Dictionary).duplicate(true)
	last_training_program=(payload.get("last_training_program",{}) as Dictionary).duplicate(true)
	command_development={"command":0.0,"tactics":0.0,"logistics":0.0,"resolve":0.0}
	for command_skill in (payload.get("command_development",{}) as Dictionary):
		if command_skill in command_development: command_development[command_skill]=clampf(float(payload.command_development[command_skill]),0.0,0.30)
	training_program_cycles=maxi(0,int(payload.get("training_program_cycles",0)))
	_ensure_training_program_state()
	equipment_queue.assign(payload.get("equipment_queue",[]))
	_normalize_equipment_jobs()
	foreign_prisoners=maxi(0,int(payload.get("foreign_prisoners",0)))
	held_generals.clear()
	for held_general_variant in payload.get("held_generals",[]):
		if held_general_variant is Dictionary: held_generals.append((held_general_variant as Dictionary).duplicate(true))
		else: held_generals.append({})
	next_training_order_id=int(payload.get("next_training_order_id",_next_available_training_order_id()))
	next_formation_id=int(payload.get("next_formation_id",_next_available_formation_id()))
	next_equipment_job_id=int(payload.get("next_equipment_job_id",_next_available_equipment_job_id()))
	next_training_order_id=maxi(next_training_order_id,_next_available_training_order_id())
	next_formation_id=maxi(next_formation_id,_next_available_formation_id())
	next_equipment_job_id=maxi(next_equipment_job_id,_next_available_equipment_job_id())
	prisoner_custody_days=maxi(0,int(payload.get("prisoner_custody_days",0)))
	prisoner_escape_accumulator=maxf(0.0,float(payload.get("prisoner_escape_accumulator",0.0)))
	escaped_prisoners_total=maxi(0,int(payload.get("escaped_prisoners_total",0)))
	active_threat=(payload.get("active_threat",{}) as Dictionary).duplicate(true)
	threats_resolved=maxi(0,int(payload.get("threats_resolved",0)))
	active_engagement=(payload.get("active_engagement",{}) as Dictionary).duplicate(true)
	war_reputation={"mercy":0.0,"fear":0.0,"grievance":0.0}
	for key in (payload.get("war_reputation",{}) as Dictionary): war_reputation[key]=clampf(float(payload.war_reputation[key]),0.0,1.0)
	occupation_forces.clear()
	for force_variant in payload.get("occupation_forces",[]):
		if force_variant is Dictionary: occupation_forces.append((force_variant as Dictionary).duplicate(true))
	field_armies.clear()
	for force_variant in payload.get("field_armies",[]):
		if force_variant is Dictionary: field_armies.append((force_variant as Dictionary).duplicate(true))
	runner_messages.clear()
	for message_variant in payload.get("runner_messages",[]):
		if message_variant is Dictionary: runner_messages.append((message_variant as Dictionary).duplicate(true))
	army_templates.clear()
	for template_variant in payload.get("army_templates",[]):
		if template_variant is Dictionary: army_templates.append((template_variant as Dictionary).duplicate(true))
	if army_templates.is_empty(): army_templates=_default_army_templates()
	next_army_template_id=maxi(1,int(payload.get("next_army_template_id",army_templates.size()+1)))
	next_field_army_id=maxi(1,int(payload.get("next_field_army_id",1)))
	for force in field_armies: next_field_army_id=maxi(next_field_army_id,int(force.get("army_id",0))+1)
	settlement_defense=(payload.get("settlement_defense",_default_settlement_defense()) as Dictionary).duplicate(true)
	_ensure_settlement_defense()


func _empty_home_army()->Dictionary:
	var force:Dictionary=simulator.create_formation_force(_home_army_name(),[],_campaign_morale(),0.0)
	force["commander"]=_marshal_commander()
	force["captured_pool"]=0
	force["captive_days"]=0
	force["captive_return_accumulator"]=0.0
	force["reserve_manpower"]=0
	force["supply_level"]=1.0
	force["supply_components"]={"nutrition":1.0,"delivery":1.0,"target":1.0}
	force["provisions_required_today"]=0.0
	force["provisions_delivered_today"]=0.0
	force["provision_ratio"]=1.0
	force["provision_day"]=-1
	force["provision_shortfall_total"]=0.0
	force["provision_shortfall_days"]=0
	force["delivery_load_bank"]=0.0
	force["delivery_load_capacity_today"]=0.0
	force["delivery_load_used_today"]=0.0
	force["recent_combat_days"]=0
	force["service_days"]=0
	force["service_strain"]=0.0
	force["discipline"]=0.5
	force["desertion_pressure"]=0.0
	force["desertion_accumulator"]=0.0
	force["desertions_total"]=0
	force["exercise_readiness_bonus"]=0.0
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
		job["allocation"]=clampf(float(job.get("allocation",1.0)),0.05,4.0)
		job["efficiency"]=clampf(float(job.get("efficiency",0.20)),0.10,1.0)
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


const PROTOTYPE_COHORT_LIMIT:=8
const PROTOTYPE_TRAINING_MULTIPLIER:=2.5


## Â§18.1 capability ladder. Knowledge reveals a capability; this ladder says
## how far the society has actually carried it: unobserved â†’ observed (the
## problem or foreign solution is visible) â†’ understood (the principle is
## established knowledge) â†’ established (adopted practice; normal fielding) â†’
## scalable (production and spread support reproduction) â†’ mature (fielded
## formations carry real experience). Legacy is future work â€” nothing
## obsolesces yet.
func unit_capability_state(unit:String)->Dictionary:
	var gate_id:=UnitCatalog.gate_for(unit)
	var gate:=_knowledge_gate(gate_id,0.10)
	var fielded:=_fielded_unit_count(unit)
	var result:Dictionary={"unit":unit,"gate":gate,"fielded":fielded,"can_prototype":false,"can_field":bool(gate.unlocked)}
	var state:String
	if bool(gate.unlocked):
		state="established"
		var adoption:=float(gate.get("adoption",1.0))
		if adoption>=0.25 and production_line_capacity()>=2: state="scalable"
		if state=="scalable" and fielded>0 and _army_experience()>=0.25: state="mature"
	elif gate_id.begins_with("__military_tier_"):
		var required:=int(gate_id.trim_prefix("__military_tier_").trim_suffix("__"))
		state="observed" if int(military_development_snapshot().get("tier",0))>=required-1 else "unobserved"
	elif gate_id in GameState.known_discoveries:
		state="understood"
		result["can_prototype"]=true
	else:
		var definition:Dictionary=DiscoverySystem.discovery_definition(gate_id)
		var prerequisites_met:=true
		for requirement in definition.get("requires",[]):
			if String(requirement) not in GameState.known_discoveries: prerequisites_met=false
		state="observed" if not definition.is_empty() and prerequisites_met and int(GameState.elapsed_days)>=int(definition.get("day",0)) else "unobserved"
	result["state"]=state
	return result


func _fielded_unit_count(unit:String)->int:
	var total:=0
	for formation_variant in (home_army.get("formations",[]) as Array):
		if String((formation_variant as Dictionary).get("unit",""))==unit: total+=maxi(0,int((formation_variant as Dictionary).get("count",0)))
	for army in field_armies:
		for formation_variant in (army.get("formations",[]) as Array):
			if String((formation_variant as Dictionary).get("unit",""))==unit: total+=maxi(0,int((formation_variant as Dictionary).get("count",0)))
	return total


func _training_gate(unit:String,weapon:String)->Dictionary:
	if not simulator.UNIT_TYPES.has(unit): return {"error":"Unknown unit type: %s" % unit}
	if not simulator.WEAPONS.has(weapon): return {"error":"Unknown weapon type: %s" % weapon}
	if weapon not in UnitCatalog.equipment_for(unit): return {"error":"%s cannot be trained with %s." % [unit.replace("_"," ").capitalize(),weapon.replace("_"," ").capitalize()],"compatible_equipment":UnitCatalog.equipment_for(unit)}
	var unit_gate:=_knowledge_gate(UnitCatalog.gate_for(unit),0.10)
	var weapon_gate:=_knowledge_gate(String(EQUIPMENT_KNOWLEDGE.get(weapon,"")),0.10)
	if bool(unit_gate.unlocked) and bool(weapon_gate.unlocked): return {}
	# Â§18.1 prototype path: with the principle UNDERSTOOD (known, not yet
	# adopted practice), one small experimental cohort can be raised at
	# exceptional cost and risk. Understanding is required for both the unit
	# and its equipment; observation alone fields nothing.
	var unit_understood:=bool(unit_gate.unlocked) or bool(unit_capability_state(unit).get("can_prototype",false))
	var weapon_discovery:=String(EQUIPMENT_KNOWLEDGE.get(weapon,""))
	var weapon_understood:=bool(weapon_gate.unlocked) or (weapon_discovery!="" and not weapon_discovery.begins_with("__") and weapon_discovery in GameState.known_discoveries)
	if unit_understood and weapon_understood:
		if _prototype_formation_exists(unit): return {"error":"An experimental %s cohort already exists; establish the practice (adoption) before raising more." % unit.replace("_"," ")}
		return {"prototype":true}
	if not bool(unit_gate.unlocked): return {"error":unit_gate.reason,"required_discovery":unit_gate.discovery}
	return {"error":weapon_gate.reason,"required_discovery":weapon_gate.discovery}


func _prototype_formation_exists(unit:String)->bool:
	for order in training_queue:
		if String((order as Dictionary).get("unit",""))==unit and bool((order as Dictionary).get("prototype",false)): return true
	for force in [home_army]+field_armies+occupation_forces:
		for formation in force.get("formations",[]):
			if String(formation.get("unit",""))==unit and bool(formation.get("prototype",false)): return true
	return false


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
	if marshal.is_empty(): return HistoricalFigures.commander(_acting_field_commander(false),"home")
	# Field command now derives from the same visible aptitudes used by every
	# other appointment. Compatibility composites keep older commanders valid.
	var command:=clampf(GovernmentPeopleSystem.skill_value(marshal,"Strategy",50.0)/100.0*0.68+security*0.32,0.0,1.0)
	var tactics:=clampf(GovernmentPeopleSystem.skill_value(marshal,"Tactics",50.0)/100.0*0.72+security*0.28,0.0,1.0)
	var supply_command:=clampf(GovernmentPeopleSystem.skill_value(marshal,"Logistics",50.0)/100.0*0.66+logistics*0.34,0.0,1.0)
	var resolve:=clampf(GovernmentPeopleSystem.skill_value(marshal,"Discipline",50.0)/100.0*0.60+security*0.40,0.0,1.0)
	var commander:Dictionary=simulator.create_commander(String(marshal.get("name","MARSHAL'S OFFICE")),command,tactics,supply_command,resolve)
	commander["office"]="Marshal"
	commander["institutional"]=true
	return _apply_command_development(commander)


func _apply_command_development(commander:Dictionary)->Dictionary:
	for skill in ["command","tactics","logistics","resolve"]:
		commander[skill]=clampf(float(commander.get(skill,0.5))+float(command_development.get(skill,0.0)),0.0,1.0)
	commander["training_development"]=command_development.duplicate(true)
	return commander


func _apply_home_commander_fate(termination:Dictionary)->void:
	if String(termination.get("defeated",""))!=String(home_army.get("name","")): return
	var fate:=String(termination.get("commander_fate","escaped"))
	if fate not in ["killed","captured"]: return
	var former:Dictionary=home_army.get("commander",{})
	var successor:=HistoricalFigures.commander(_acting_field_commander(false),"home")
	home_army["commander"]=successor
	var command_effect:="was destroyed" if fate=="killed" else "was captured"
	GameState.council_inbox.push_front({"id":"command_succession_%d" % int(GameState.elapsed_days),"advisor":String(successor.get("name","ACTING FIELD STAFF")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":"%s %s. %s has assumed field coordination with reduced effectiveness." % [String(former.get("name","The field command element")),command_effect,String(successor.get("name","The acting field staff"))],"urgency":0.98,"day":int(GameState.elapsed_days),"status":"unread"})


func _record_military_deaths(_legacy_names:Array[String],cause:String)->void:
	# Legacy save compatibility: personal rosters are no longer accepted.
	if not _legacy_names.is_empty(): _record_aggregate_military_deaths(_legacy_names.size(),cause)

func _record_aggregate_military_deaths(count:int,cause:String)->void:
	if count<=0: return
	var location:=GameState.settlement_name if GameState.settlement_name!="" else "the campaign"
	var record:Dictionary={"id":"military_deaths_%d_%d" % [int(GameState.elapsed_days),GameState.demographic_ledger.size()],"day":int(GameState.elapsed_days),"start_day":int(GameState.elapsed_days),"end_day":int(GameState.elapsed_days),"title":"%s military deaths near %s" % [_compact_count(count),location],"description":"%s personnel were killed during military operations." % _compact_count(count),"domain":"population","severity":"demographic","kind":"death","count":count,"cause":cause,"location":location,"population_after":GameState.population_total,"affected_cohorts":{"early_adults":roundi(count*0.46),"established_adults":roundi(count*0.39),"mature_adults":count-roundi(count*0.46)-roundi(count*0.39)}}
	GameState.demographic_ledger.push_front(record)
	if GameState.demographic_ledger.size()>120: GameState.demographic_ledger.resize(120)
	GameState.simulation_events.push_front(record)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)

func _compact_count(value:int)->String:
	if value>=1_000_000_000: return "%.2fB" % (float(value)/1_000_000_000.0)
	if value>=1_000_000: return "%.2fM" % (float(value)/1_000_000.0)
	if value>=1_000: return "%.1fK" % (float(value)/1_000.0)
	return str(value)


func _acting_field_commander(assign_office:bool)->Dictionary:
	var security:=clampf(float(GameState.society_capacities.get("security",0.38)),0.0,1.0)
	var logistics:=clampf(float(GameState.society_capacities.get("logistics",0.16)),0.0,1.0)
	var knowledge:=clampf(float(GameState.society_capacities.get("knowledge",0.18)),0.0,1.0)
	var competence:=clampf(0.28+security*0.30+knowledge*0.16,0.30,0.70)
	var institution:={"institution_id":"acting_field_staff","name":"ACTING FIELD STAFF","background":"Temporary collective command","institutional":true,"traits":["Distributed","Adaptive"],"skills":{"Strategy":roundi(competence*100.0),"Tactics":roundi(competence*92.0),"Logistics":roundi((competence*0.65+logistics*0.35)*100.0),"Discipline":roundi(competence*88.0)},"relationships":{"sovereign":{"trust":0.46,"respect":0.52,"fear":0.18,"resentment":0.0,"obligation":0.62}},"honesty":0.52,"courage":clampf(competence+0.10,0.0,1.0),"pride":0.42,"suspicion":0.48,"support":roundi(competence*75.0),"acting":true}
	if assign_office: GameState.leadership_positions["Marshal"]=institution
	var commander:Dictionary=simulator.create_commander(String(institution.name),competence,competence*0.92,clampf(competence*0.65+logistics*0.35,0.0,1.0),clampf(competence+0.08,0.0,1.0))
	commander["office"]="Marshal"
	commander["acting"]=true
	commander["institutional"]=true
	return _apply_command_development(commander)


func _synchronize_field_commander()->void:
	if home_army.is_empty(): return
	var marshal:Dictionary=GameState.leadership_positions.get("Marshal",{})
	home_army["commander"]=_marshal_commander()
	for force in field_armies+occupation_forces:
		var commander:Dictionary=force.get("commander",{}).duplicate(true)
		if commander.is_empty(): commander=home_army["commander"].duplicate(true)
		else:
			var prior:Dictionary=commander.get("training_development",{})
			for skill in command_development:
				commander[skill]=clampf(float(commander.get(skill,0.5))-float(prior.get(skill,0.0))+float(command_development[skill]),0.0,1.0)
			commander["training_development"]=command_development.duplicate(true)
		force["commander"]=commander



func force_condition_profile(force:Dictionary={})->Dictionary:
	var subject:=force if not force.is_empty() else home_army
	var bands:Array[Dictionary]=[
		{"id":"ready","label":"Ready","count":0,"color":"#5f9f73"},
		{"id":"capable","label":"Capable","count":0,"color":"#a4a85c"},
		{"id":"strained","label":"Strained","count":0,"color":"#c68b4f"},
		{"id":"unfit","label":"Unfit","count":0,"color":"#a8514d"}
	]
	var total:=0
	for formation in subject.get("formations",[]):
		var count:=maxi(0,int(formation.get("count",0)))
		var capacity:=clampf(float(formation.get("personnel_condition",GameState.population_health)),0.0,1.0)
		total+=count
		var band_index:=0 if capacity>=0.72 else (1 if capacity>=0.50 else (2 if capacity>=0.30 else 3))
		bands[band_index]["count"]=int(bands[band_index].count)+count
	for band in bands: band["share"]=float(band.count)/maxf(1.0,float(total))
	return {"total":total,"bands":bands}


func _campaign_morale()->float:
	return clampf(float(GameState.simulation_metrics.get("cohesion",0.58))*0.55+float(GameState.simulation_metrics.get("security",0.38))*0.45,0.15,1.0)


func _default_settlement_defense()->Dictionary:
	return {"stage":0,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":int(GameState.elapsed_days)}


func _ensure_settlement_defense()->void:
	if settlement_defense.is_empty(): settlement_defense=_default_settlement_defense()
	settlement_defense["stage"]=clampi(int(settlement_defense.get("stage",0)),0,SETTLEMENT_DEFENSE_STAGES.size()-1)
	settlement_defense["integrity"]=clampf(float(settlement_defense.get("integrity",1.0)),0.0,1.0)
	settlement_defense["project_stage"]=clampi(int(settlement_defense.get("project_stage",-1)),-1,SETTLEMENT_DEFENSE_STAGES.size()-1)
	settlement_defense["project_progress"]=clampf(float(settlement_defense.get("project_progress",0.0)),0.0,1.0)
	settlement_defense["project_work"]=maxf(0.0,float(settlement_defense.get("project_work",0.0)))
	if not settlement_defense.get("reserved_materials",{}) is Dictionary: settlement_defense["reserved_materials"]={}


func settlement_defense_upgrade_availability()->Dictionary:
	_ensure_settlement_defense()
	if not GameState.settlement_site_committed: return {"available":false,"reason":"Found a permanent settlement before preparing a fixed defensive perimeter."}
	if int(settlement_defense.project_stage)>=0:
		var active_stage:Dictionary=SETTLEMENT_DEFENSE_STAGES[int(settlement_defense.project_stage)]
		return {"available":false,"active":true,"reason":"%s is already under construction." % String(active_stage.name),"stage":active_stage.duplicate(true)}
	var next_stage:=int(settlement_defense.stage)+1
	if next_stage>=SETTLEMENT_DEFENSE_STAGES.size(): return {"available":false,"complete":true,"reason":"The settlement already has the strongest bounded defense network.","stage":SETTLEMENT_DEFENSE_STAGES[-1].duplicate(true)}
	var stage:Dictionary=SETTLEMENT_DEFENSE_STAGES[next_stage]
	var missing:Array[String]=[]
	for material in (stage.materials as Dictionary):
		var required:=float(stage.materials[material]); var stored:=float(GameState.resource_stockpiles.get(material,0.0))
		if stored+0.0001<required: missing.append("%s %.0f/%.0f" % [String(material),stored,required])
	var labor:=int(GameState.population_allocations.get("Defense",0))
	if labor<=0: missing.append("assign population to Defense")
	var reason:="Ready: reserve the listed materials and commit aggregate Defense labor."
	if not missing.is_empty(): reason="Needs "+", ".join(missing)+"."
	return {"available":missing.is_empty(),"reason":reason,"stage_index":next_stage,"stage":stage.duplicate(true),"materials":stage.materials.duplicate(true),"work":float(stage.work)}


func start_settlement_defense_upgrade()->Dictionary:
	var availability:=settlement_defense_upgrade_availability()
	if not bool(availability.get("available",false)): return {"error":String(availability.get("reason","The next defense stage is unavailable."))}
	var stage_index:=int(availability.stage_index); var stage:Dictionary=SETTLEMENT_DEFENSE_STAGES[stage_index]
	for material in (stage.materials as Dictionary):
		GameState.resource_stockpiles[material]=maxf(0.0,float(GameState.resource_stockpiles.get(material,0.0))-float(stage.materials[material]))
	settlement_defense["project_stage"]=stage_index
	settlement_defense["project_progress"]=0.0
	settlement_defense["project_work"]=0.0
	settlement_defense["reserved_materials"]=(stage.materials as Dictionary).duplicate(true)
	settlement_defense_changed.emit(settlement_defense_snapshot())
	return {"ok":true,"message":"Construction started: %s. Materials are committed; Defense labor now advances the project." % String(stage.name),"defense":settlement_defense_snapshot()}


func settlement_defense_snapshot()->Dictionary:
	_ensure_settlement_defense()
	var stage_index:=int(settlement_defense.stage); var stage:Dictionary=SETTLEMENT_DEFENSE_STAGES[stage_index]
	var project_index:=int(settlement_defense.project_stage)
	var trained_troops:=maxi(0,int(home_army.get("troops",0)))
	# Defense labor is physically present and serves in the watch while its basic
	# training rotates automatically. Formal formations remain separately visible.
	var troops:=maxi(trained_troops,_home_garrison_target())
	var garrison_required:=maxi(8,ceili(maxf(1.0,GameState.population_exact)*0.035))
	var garrison_coverage:=clampf(float(troops)/float(garrison_required),0.0,1.0)
	var integrity:=float(settlement_defense.integrity)
	var construction:Dictionary={}
	if project_index>=0:
		var project:Dictionary=SETTLEMENT_DEFENSE_STAGES[project_index]
		construction={"active":true,"stage":project_index,"name":String(project.name),"progress":float(settlement_defense.project_progress),"work_done":float(settlement_defense.project_work),"work_required":float(project.work),"materials":(settlement_defense.reserved_materials as Dictionary).duplicate(true)}
	return {"stage":stage_index,"name":String(stage.name),"short":String(stage.short),"description":String(stage.description),"integrity":integrity,"defense_bonus":float(stage.defense_bonus)*integrity,"observation_radius_km":float(stage.observation_km)*(0.82+integrity*0.18),"store_protection":float(stage.store_protection)*integrity,"garrison_personnel":troops,"garrison_trained":trained_troops,"garrison_militia":maxi(0,troops-trained_troops),"garrison_required":garrison_required,"garrison_coverage":garrison_coverage,"basic_training_automatic":true,"construction":construction,"next":settlement_defense_upgrade_availability()}


func _process_settlement_defense_day()->void:
	_ensure_settlement_defense()
	var changed:=false
	var project_index:=int(settlement_defense.project_stage)
	if project_index>=0:
		var project:Dictionary=SETTLEMENT_DEFENSE_STAGES[project_index]
		var workers:=maxf(0.0,float(GameState.population_allocations.get("Defense",0)))
		var efficiency:=clampf(float(GameState.simulation_metrics.get("labor_efficiency",0.72)),0.15,1.25)
		# A bounded project can use vast aggregate labor without creating per-worker
		# tasks or completing more than 4% of a strategic stage in one simulated day.
		var daily_work:=minf(float(project.work)*0.04,workers*efficiency*0.38)
		if daily_work>0.0:
			settlement_defense["project_work"]=minf(float(project.work),float(settlement_defense.project_work)+daily_work)
			settlement_defense["project_progress"]=clampf(float(settlement_defense.project_work)/maxf(0.01,float(project.work)),0.0,1.0)
			changed=true
		if float(settlement_defense.project_progress)>=0.999999:
			settlement_defense["stage"]=project_index
			settlement_defense["integrity"]=1.0
			settlement_defense["project_stage"]=-1
			settlement_defense["project_progress"]=0.0
			settlement_defense["project_work"]=0.0
			settlement_defense["reserved_materials"]={}
			settlement_defense["completed_day"]=int(GameState.elapsed_days)
			GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"%s completed" % String(project.name).capitalize(),"description":String(project.description),"domain":"security","severity":"notice"})
	var integrity:=float(settlement_defense.integrity)
	if integrity<1.0 and active_engagement.is_empty():
		var repair_workers:=maxf(0.0,float(GameState.population_allocations.get("Construction",0)))+maxf(0.0,float(GameState.population_allocations.get("Defense",0)))*0.20
		if repair_workers>0.0:
			settlement_defense["integrity"]=move_toward(integrity,1.0,minf(0.006,repair_workers*0.00012))
			changed=true
	if changed: settlement_defense_changed.emit(settlement_defense_snapshot())


func _apply_home_siege_damage(result:Dictionary)->void:
	if String(result.get("campaign_mode",""))!="defensive" or String(result.get("target_region_id",""))!="": return
	_ensure_settlement_defense()
	var rounds:=maxi(1,int(result.get("round_count",(result.get("rounds",[]) as Array).size())))
	var outcome:=String(result.get("outcome","inconclusive"))
	var breached:=outcome in ["attacker_victory","defender_retreat"]
	var damage:=clampf(float(rounds)*0.025+(0.14 if breached else 0.035),0.03,0.34)
	if int(settlement_defense.stage)>0:
		settlement_defense["integrity"]=clampf(float(settlement_defense.integrity)-damage,0.0,1.0)
		settlement_defense_changed.emit(settlement_defense_snapshot())
	# Fortifications are not the settlement. Fighting at home now marks a bounded,
	# contiguous group of aggregate plots, which the map renders through the same
	# GREAT -> DESTROYED grid ladder used for maintenance and prosperity. An unfortified
	# settlement is therefore more exposed, not magically immune to urban damage.
	if not GameState.settlement_plots.is_empty():
		var battle_seed:=int(result.get("seed",hash("%d:%s:%d:home_siege" % [int(GameState.elapsed_days),outcome,rounds])))
		var fabric_severity:=clampf(float(rounds)*0.018+(0.16 if breached else 0.035),0.035,0.42)
		var exposed_share:=clampf(0.04+float(rounds)*0.018+(0.12 if breached else 0.0),0.04,0.32)
		SettlementModel.apply_bounded_siege_damage(battle_seed,fabric_severity,exposed_share,"home siege combat")


func defensive_position()->Dictionary:
	var terrain:=String(GameState.province_terrain)
	var terrain_base:=float({"Mountains":1.35,"Hills":1.20,"Forest":1.15,"Marsh":1.12,"Plains":1.0}.get(terrain,1.0))
	var fieldworks_adoption:=_adoption("field_fortifications")
	var fieldworks_bonus:=fieldworks_adoption*FIELD_FORTIFICATION_MAX_BONUS
	var defense:=settlement_defense_snapshot()
	var settlement_bonus:=float(defense.defense_bonus)
	return {
		"terrain":terrain,
		"terrain_base":terrain_base,
		"fieldworks_adoption":fieldworks_adoption,
		"fieldworks_bonus":fieldworks_bonus,
		"settlement_stage":int(defense.stage),
		"settlement_name":String(defense.name),
		"settlement_bonus":settlement_bonus,
		"settlement_integrity":float(defense.integrity),
		"modifier":clampf(terrain_base+fieldworks_bonus+settlement_bonus,0.75,2.25)
	}


func store_protection()->Dictionary:
	var adoption:=_adoption("fortified_stores")
	var learned_protection:=adoption*FORTIFIED_STORES_MAX_PROTECTION
	var structural_protection:=float(settlement_defense_snapshot().store_protection)
	var seizure_reduction:=1.0-(1.0-learned_protection)*(1.0-structural_protection)
	return {"adoption":adoption,"structural_protection":structural_protection,"seizure_reduction":seizure_reduction,"exposed_share":1.0-seizure_reduction}


func _terrain_defense()->float:
	return float(defensive_position().modifier)


func _home_army_name()->String:
	return "%s Host" % (GameState.settlement_name if GameState.settlement_name!="" else "Founding")


func _apply_home_result(side:Dictionary,rounds:Array,_battle_seed:int,home_side:String="attacker")->void:
	var totals:={"killed":0,"wounded":0,"scattered":0}
	var equipment_loss_by_formation:Array[int]=[]
	for round_data in rounds:
		var breakdown:Dictionary=round_data.get("%s_casualties" % home_side,{})
		for key in totals: totals[key]=int(totals[key])+int(breakdown.get(key,0))
		var round_equipment:Array=round_data.get("%s_cohort_equipment_losses" % home_side,[])
		while equipment_loss_by_formation.size()<round_equipment.size(): equipment_loss_by_formation.append(0)
		for index in round_equipment.size(): equipment_loss_by_formation[index]+=int(round_equipment[index])
	var old_formations:Array=home_army.get("formations",[])
	var result_formations:Array=side.get("formations",[]).duplicate(true)
	var experience_gain:=clampf(float(rounds.size())*0.014,0.008,0.12)
	for index in result_formations.size():
		var prior_experience:=float(old_formations[index].get("experience",0.0)) if index<old_formations.size() else 0.0
		result_formations[index]["experience"]=clampf(prior_experience+experience_gain*(1.0-prior_experience),0.0,1.0)
		result_formations[index].erase("soldier_ids")
	if int(totals.killed)>0:
		GameState.register_population_deaths(int(totals.killed),"Killed in battle")
		_record_aggregate_military_deaths(int(totals.killed),"Killed in battle")
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
	persisted["wounded_pool"]=maxi(0,int(side.get("wounded_pool",persisted.get("wounded_pool",0))))
	persisted["disabled_pool"]=clampi(int(side.get("disabled_pool",persisted.get("disabled_pool",0))),0,int(persisted.wounded_pool))
	persisted["severe_disabled_pool"]=clampi(int(side.get("severe_disabled_pool",persisted.get("severe_disabled_pool",0))),0,int(persisted.disabled_pool))
	persisted["scattered_pool"]=maxi(0,int(side.get("scattered_pool",persisted.get("scattered_pool",0))))
	persisted["dead"]=int(side.get("dead",persisted.get("dead",0)))
	for forbidden_key in ["soldier_ids","wounded_ids","scattered_ids","captured_ids"]: persisted.erase(forbidden_key)
	home_army=persisted
	home_army["campaign_day"]=int(GameState.elapsed_days)


func _apply_occupation_result(civ_id:String,region_id:String,side:Dictionary,rounds:Array,battle_seed:int,home_side:String)->void:
	var index:=_occupation_force_index(civ_id,region_id)
	if index<0: return
	var field_army:=home_army
	home_army=occupation_forces[index].duplicate(true)
	_apply_home_result(side,rounds,battle_seed,home_side)
	var updated:=home_army
	updated["supply_level"]=clampf(float(updated.get("supply_level",1.0))-0.08,0.0,1.0)
	occupation_forces[index]=updated
	home_army=field_army


func _apply_field_army_result(army_id:int,side:Dictionary,rounds:Array,battle_seed:int,home_side:String)->void:
	var index:=_field_army_index(army_id)
	if index<0: return
	var home_reserve:=home_army
	home_army=field_armies[index].duplicate(true)
	_apply_home_result(side,rounds,battle_seed,home_side)
	var updated:=home_army
	updated["recent_combat_days"]=7
	updated["supply_level"]=clampf(float(updated.get("supply_level",1.0))-0.08,0.0,1.0)
	field_armies[index]=updated
	home_army=home_reserve


func _reconcile_external_military_mortality()->Dictionary:
	# Population mortality is reconciled directly against numeric cohorts when it
	# occurs. No roster scan is required or permitted.
	return {"removed":0}


func _process_military_day()->void:
	recovery.advance(last_processed_day)
	if recovery.home_unavailable():
		_process_field_army_movement_day()
		_process_army_runners_day()
		occupation_transfers.advance(last_processed_day)
		return
	if active_engagement.is_empty(): _reconcile_external_military_mortality()
	_process_settlement_defense_day()
	_process_service_rest_day()
	_process_prisoner_custody_day()
	_process_home_captives_day()
	_process_equipment_production_day()
	_process_training_injuries_day()
	_process_requested_templates()
	_ensure_automatic_basic_training()
	_process_training_day()
	_process_training_program_day()
	_process_field_army_movement_day()
	_process_army_runners_day()
	_process_siege_day()
	occupation_transfers.advance(int(GameState.elapsed_days))
	_process_threat_day()
	if not active_engagement.is_empty(): return
	if home_army.is_empty() or not pending_aftermath.is_empty(): return
	var logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.5))
	_update_supply_day()
	_process_service_strain_day()
	_process_equipment_wear_day()
	var supply:=float(home_army.get("supply_level",1.0))
	var daily_delivery_capacity:=_daily_delivery_capacity()
	var delivery_bank_cap:=maxf(10.0,daily_delivery_capacity*3.0)
	var available_delivery_load:=minf(delivery_bank_cap,maxf(0.0,float(home_army.get("delivery_load_bank",0.0)))+daily_delivery_capacity)
	var delivered:=_deliver_inventory_replacements(available_delivery_load)
	var equipment_load_used:=float(home_army.get("equipment_delivery_load_used",0.0))
	var remaining_delivery_load:=maxf(0.0,available_delivery_load-equipment_load_used)
	# Do not let light ammunition consume a convoy being assembled for a heavier
	# replacement. Once the pending item fits, any residual capacity can carry ammo.
	var pending_equipment_load:=_next_equipment_delivery_load()
	var ammunition_delivered:=_deliver_ammunition(remaining_delivery_load if pending_equipment_load<=0.0 else 0.0)
	var ammunition_load_used:=float(home_army.get("ammunition_delivery_load_used",0.0))
	home_army["delivery_load_bank"]=maxf(0.0,remaining_delivery_load-ammunition_load_used)
	home_army["delivery_load_capacity_today"]=daily_delivery_capacity
	home_army["delivery_load_used_today"]=equipment_load_used+ammunition_load_used
	var recovery_multiplier:=0.35+supply*0.55+_adoption("battlefield_medicine")*0.55
	var prepared:Dictionary=simulator.advance_preparation_day(home_army,{"equipment_replacements":0,"manpower_replacements":0,"organization_recovery":(0.025+logistics*0.055)*(0.35+supply*0.65),"recovery_multiplier":recovery_multiplier})
	home_army=prepared.force
	_rejoin_recovered_population("scattered_pool",int(prepared.scattered_returned))
	_rejoin_recovered_population("wounded_pool",int(prepared.wounded_returned))
	_release_recovered_to_recruits("scattered_pool",int(prepared.get("scattered_recovered",prepared.scattered_returned))-int(prepared.scattered_returned))
	_release_recovered_to_recruits("wounded_pool",int(prepared.get("wounded_recovered",prepared.wounded_returned))-int(prepared.wounded_returned))
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


func home_captive_snapshot()->Dictionary:
	var count:=maxi(0,int(home_army.get("captured_pool",0)))
	var days:=maxi(0,int(home_army.get("captive_days",0)))
	var chance:=_home_captive_return_chance({},days)
	return {"count":count,"oldest_days":days,"average_daily_return_chance":chance}


func _home_captive_return_chance(_cohort:Dictionary,days_captive:int)->float:
	var security:=clampf(float(GameState.society_capacities.get("security",0.38)),0.0,1.0)
	var mercy:=clampf(float(war_reputation.get("mercy",0.0)),0.0,1.0)
	var grievance:=clampf(float(war_reputation.get("grievance",0.0)),0.0,1.0)
	return clampf(0.00035+minf(365.0,float(maxi(0,days_captive)))*0.000008+security*0.00060+mercy*0.00120-grievance*0.00135,0.00010,0.008)


func _process_home_captives_day(return_chance_override:float=-1.0)->Dictionary:
	var held:=mini(recovery.held_military(),maxi(0,int(home_army.get("captured_pool",0))))
	var captured:=maxi(0,int(home_army.get("captured_pool",0))-held)
	if captured<=0:
		home_army["captive_days"]=0
		home_army["captive_return_accumulator"]=0.0
		return {"returned":0}
	var days:=maxi(0,int(home_army.get("captive_days",0)))+1
	var chance:=return_chance_override if return_chance_override>=0.0 else _home_captive_return_chance({},days)
	var accumulator:=float(home_army.get("captive_return_accumulator",0.0))+float(captured)*clampf(chance,0.0,1.0)
	var returned:=mini(captured,floori(accumulator))
	accumulator-=returned
	home_army["captured_pool"]=captured-returned+held
	home_army["captive_days"]=days if captured>returned else 0
	home_army["captive_return_accumulator"]=accumulator if captured>returned else 0.0
	if returned>0:
		aggregate_recruits+=returned
		var message:="%s captives returned from enemy custody and entered the recruit reserve." % _compact_count(returned)
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Captive cohort returns","description":message,"domain":"security","severity":"notice"})
		GameState.council_inbox.push_front({"id":"captive_return_%d" % int(GameState.elapsed_days),"advisor":String((home_army.get("commander",{}) as Dictionary).get("name","FIELD COMMAND")),"office":"Marshal","topic":"security","act":{"type":"report"},"text":message,"urgency":0.58,"day":int(GameState.elapsed_days),"status":"unread"})
	return {"returned":returned}


func _process_service_rest_day()->void:
	# Demobilized personnel immediately rejoin the aggregate civilian labor cohort.
	pass


func _release_recovered_to_recruits(pool_name:String,count:int)->void:
	var released:=mini(maxi(0,count),maxi(0,int(home_army.get(pool_name,0))))
	if released<=0: return
	home_army[pool_name]=int(home_army.get(pool_name,0))-released
	aggregate_recruits+=released


func _process_service_strain_day()->Dictionary:
	return _process_aggregate_service_strain_day()

func _process_aggregate_service_strain_day()->Dictionary:
	var troops:=int(home_army.get("troops",0))
	if troops<=0: home_army["service_strain"]=0.0; home_army["desertion_pressure"]=0.0; return {"deserted":0}
	var supply:=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0); var morale:=clampf(float(home_army.get("morale",1.0)),0.0,1.0)
	var commander:Dictionary=home_army.get("commander",{}); var leadership:=clampf(float(commander.get("command",0.5))*0.55+float(commander.get("resolve",0.5))*0.45,0.0,1.0)
	var weighted_training:=0.0
	for formation in home_army.get("formations",[]): weighted_training+=float(formation.get("training",0.0))*float(formation.get("count",0))
	var training:=clampf(weighted_training/maxf(1.0,float(troops)),0.0,1.0); var discipline:=clampf(0.18+leadership*0.42+training*0.30+_adoption("professional_corps")*0.18,0.0,1.0)
	# Home duty is a rotating civic obligation, not an endless expedition. Quiet,
	# supplied garrisons recover strain; only combat, privation, or broken morale can
	# drive sustained desertion. The old unconditional daily increase eventually
	# erased every peacetime garrison.
	# Strain tends toward current hardship; moderate supply is not an endless
	# daily debt. Recovery and fatigue belong to daily simulation, never UI reads.
	var combat:=int(home_army.get("recent_combat_days",0))>0
	var hardship:=clampf(maxf(0,.70-supply)/.70+maxf(0,.50-morale)*1.5+(.55 if combat else 0),0,1)
	var current_strain:=float(home_army.get("service_strain",0.0))
	var average_strain:=move_toward(current_strain,hardship,.012 if hardship<current_strain else .006)

	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.58)),0.0,1.0)
	var pressure:=(maxf(0.0,average_strain-0.42)*0.020*clampf(hardship*2.0,0,1)+maxf(0.0,0.42-supply)*0.024+maxf(0.0,0.32-morale)*0.018)*(1.15-discipline*0.65)*(1.10-cohesion*0.35)
	var accumulator:=float(home_army.get("desertion_accumulator",0.0))+float(troops)*pressure; var deserted:=mini(troops,floori(accumulator)); accumulator-=deserted
	if deserted>0:
		_stand_down_aggregate(deserted); home_army["desertions_total"]=int(home_army.get("desertions_total",0))+deserted
		home_army["morale"]=clampf(morale-minf(0.12,float(deserted)/maxf(1.0,float(troops))*0.5),0.0,1.5)
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Soldiers desert","description":"%s exhausted soldiers abandon the host." % _compact_count(deserted),"domain":"security","severity":"warning"})
	home_army["service_days"]=int(home_army.get("service_days",0))+1; home_army["service_strain"]=average_strain; home_army["discipline"]=discipline; home_army["desertion_pressure"]=pressure; home_army["desertion_accumulator"]=accumulator
	return {"deserted":deserted,"pressure":pressure,"discipline":discipline,"strain":average_strain}


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


func _daily_delivery_capacity()->float:
	var workers:=int(GameState.population_allocations.get("Logistics",0))
	if workers<=0: return 0.0
	var commander_logistics:=float((home_army.get("commander",{}) as Dictionary).get("logistics",0.4))
	var practice:=_adoption("supply_groups")
	var carts:=minf(float(workers),maxf(0.0,float(GameState.resource_stockpiles.get("Transport Carts",0.0))))
	return maxf(0.50,float(workers)*(0.35+commander_logistics*0.45+practice*0.40)+carts*(0.75+practice*0.45))


func _equipment_delivery_load(item:String)->float:
	return maxf(0.05,float(EQUIPMENT_DELIVERY_LOAD.get(item,1.0)))


func _ammunition_delivery_load(item:String)->float:
	return maxf(0.01,float(AMMUNITION_DELIVERY_LOAD.get(item,0.25)))


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


func _deliver_inventory_replacements(delivery_limit:float)->int:
	var delivered:=0
	var remaining_capacity:=maxf(0.0,delivery_limit)
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		if remaining_capacity<=0.0001: break
		var formation:Dictionary=formations[index]
		var item:=String(formation.get("weapon","improvised"))
		var available:=int(military_inventory.get(item,0))
		var required:=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		var missing:=maxi(0,required-int(formation.get("equipment",0)))
		var item_load:=_equipment_delivery_load(item)
		var transfer:=mini(mini(available,missing),floori((remaining_capacity+0.000001)/item_load))
		if transfer<=0: continue
		formation["equipment"]=int(formation.get("equipment",0))+transfer
		formations[index]=formation
		military_inventory[item]=available-transfer
		delivered+=transfer
		remaining_capacity-=float(transfer)*item_load
	home_army["formations"]=formations
	home_army["equipment_delivery_load_used"]=maxf(0.0,delivery_limit-remaining_capacity)
	return delivered


func _next_equipment_delivery_load()->float:
	var next_load:=INF
	for formation in home_army.get("formations",[]):
		var item:=String(formation.get("weapon","improvised"))
		if int(military_inventory.get(item,0))<=0: continue
		var required:=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		if int(formation.get("equipment",0))<required: next_load=minf(next_load,_equipment_delivery_load(item))
	return 0.0 if is_inf(next_load) else next_load


func _deliver_ammunition(delivery_limit:float)->int:
	var delivered:=0
	var remaining_capacity:=maxf(0.0,delivery_limit)
	var formations:Array=home_army.get("formations",[])
	for index in formations.size():
		if remaining_capacity<=0.0001: break
		var formation:Dictionary=formations[index]
		var weapon:=String(formation.get("weapon","improvised"))
		var ammunition_type:=_ammunition_type_for(weapon)
		if ammunition_type=="": continue
		var available:=maxi(0,int(military_consumables.get(ammunition_type,0)))
		if available<=0: continue
		var required:=maxi(0,int(formation.get("ammunition_required",_ammunition_required_for(weapon,int(formation.get("equipment_required",0))))))
		var missing:=maxi(0,required-int(formation.get("ammunition",0)))
		var ammunition_load:=_ammunition_delivery_load(ammunition_type)
		var transfer:=mini(mini(available,missing),floori((remaining_capacity+0.000001)/ammunition_load))
		if transfer<=0: continue
		formation["ammunition"]=int(formation.get("ammunition",0))+transfer
		formation["ammunition_required"]=required
		formations[index]=formation
		available-=transfer
		military_consumables[ammunition_type]=available
		remaining_capacity-=float(transfer)*ammunition_load
		delivered+=transfer
	home_army["formations"]=formations
	home_army["ammunition_delivery_load_used"]=maxf(0.0,delivery_limit-remaining_capacity)
	return delivered


func _rejoin_recovered_population(_pool_name:String,_count:int)->void:
	# CombatSimulator already moves recovered numeric cohorts back into formation
	# counts; there is no person roster to reconcile.
	pass


func _process_equipment_production_day()->void:
	if equipment_queue.is_empty(): return
	var crafting:=_production_rate()
	if crafting<=0.0: return
	var weight_total:=0.0
	for job in equipment_queue: weight_total+=maxf(0.05,float(job.get("allocation",1.0)))
	for index in range(equipment_queue.size()-1,-1,-1):
		var job:Dictionary=equipment_queue[index]
		var allocation:=maxf(0.05,float(job.get("allocation",1.0)))
		var efficiency:=clampf(float(job.get("efficiency",0.20)),0.10,1.0)
		job["progress_days"]=float(job.get("progress_days",0.0))+crafting*allocation/maxf(0.05,weight_total)*efficiency
		job["efficiency"]=move_toward(efficiency,1.0,0.0025*(0.65+_adoption("workshop_standards")))
		var work_per_item:=maxf(0.01,float(job.get("work_per_item",float(job.get("required_days",1.0))/maxf(1.0,float(job.get("count",1))))))
		var previously_completed:=int(job.get("completed",0))
		var completed:=mini(int(job.count),floori(float(job.progress_days)/work_per_item))
		var produced:=maxi(0,completed-previously_completed)
		if produced>0:
			if String(job.get("job_type","production"))=="consumable": military_consumables[String(job.item)]=int(military_consumables.get(String(job.item),0))+produced
			elif String(job.get("job_type","production"))=="transport": GameState.resource_stockpiles["Transport Carts"]=float(GameState.resource_stockpiles.get("Transport Carts",0.0))+produced
			else: military_inventory[String(job.item)]=int(military_inventory.get(String(job.item),0))+produced
		job["completed"]=completed
		if completed>=int(job.count): equipment_queue.remove_at(index)
		else: equipment_queue[index]=job


func _training_program_gate(program_id:String,include_campaign_state:bool=true)->Dictionary:
	if not TRAINING_PROGRAMS.has(program_id): return {"error":"Unknown military training program: %s." % program_id}
	var definition:Dictionary=TRAINING_PROGRAMS[program_id]
	var discovery:=String(definition.get("required_discovery",""))
	var adoption_required:=float(definition.get("minimum_adoption",0.0))
	var knowledge_gate:=_knowledge_gate(discovery,adoption_required)
	if not bool(knowledge_gate.get("unlocked",false)): return {"error":String(knowledge_gate.reason),"required_discovery":knowledge_gate.discovery}
	if String(definition.get("scope","army"))=="army" and exercise_personnel()<=0:
		return {"error":"Have at least one trained formation stationed at home before ordering %s." % String(definition.label).capitalize()}
	if String(definition.get("scope","army"))=="command" and int(GameState.population_allocations.get("Defense",0))<3:
		return {"error":"Staff exercises require at least 3 people committed to Defense administration."}
	if include_campaign_state:
		if not active_engagement.is_empty(): return {"error":"Training cannot begin during a live battle."}
		if not active_threat.is_empty(): return {"error":"Resolve the approaching threat before beginning a training program."}
		if not pending_aftermath.is_empty(): return {"error":"Resolve the battle aftermath before beginning a training program."}
	return {}


func _exercise_forces()->Array[Dictionary]:
	var forces:Array[Dictionary]=[home_army]
	for force in field_armies:
		if String(force.get("status",""))=="stationed" and String(force.get("location_id",""))=="player_home": forces.append(force)
	return forces


func exercise_personnel()->int:
	var total:=0
	for force in _exercise_forces(): total+=maxi(0,int(force.get("troops",0)))
	return total


func _training_program_participants(definition:Dictionary)->int:
	if String(definition.get("scope","army"))=="command":
		return mini(maxi(0,int(GameState.population_allocations.get("Defense",0))),maxi(1,ceili(float(exercise_personnel())*0.012)))
	return exercise_personnel()


func _ensure_training_program_state()->void:
	for skill in ["command","tactics","logistics","resolve"]:
		command_development[skill]=clampf(float(command_development.get(skill,0.0)),0.0,0.30)
	if not home_army.is_empty(): home_army["exercise_readiness_bonus"]=clampf(float(home_army.get("exercise_readiness_bonus",0.0)),0.0,0.20)
	training_program_cycles=maxi(0,training_program_cycles)


func _process_training_program_day()->void:
	_ensure_training_program_state()
	for force in [home_army]+field_armies:
		var decay:=0.00010 if not training_program.is_empty() and force in _exercise_forces() else 0.00045
		force["exercise_readiness_bonus"]=move_toward(float(force.get("exercise_readiness_bonus",0.0)),0.0,decay)
	if training_program.is_empty(): return
	var program_id:=String(training_program.get("id",""))
	if not TRAINING_PROGRAMS.has(program_id):
		training_program.clear()
		return
	var definition:Dictionary=TRAINING_PROGRAMS[program_id]
	var interruption:=""
	if not active_engagement.is_empty(): interruption="Paused during a live battle."
	elif not active_threat.is_empty(): interruption="Paused while the army responds to an approaching threat."
	elif not pending_aftermath.is_empty(): interruption="Paused until the battle aftermath is resolved."
	var participants:=_training_program_participants(definition)
	if String(definition.scope)=="army" and participants<=0: interruption="Paused: no trained soldiers are stationed at home."
	if String(definition.scope)=="command" and participants<=0: interruption="Paused because no command cadre is available."
	training_program["participants"]=participants
	if interruption!="":
		training_program["paused_reason"]=interruption
		training_program["last_efficiency"]=0.0
		_refresh_readiness()
		return
	var required_food:=float(participants)*float(definition.food_per_participant)
	var available_food:=FoodSystem.total_stored()
	var food_taken:=FoodSystem.issue_for_obligation(minf(required_food,available_food),"military_training","%s â€¢ %d participants" % [String(definition.get("label",program_id.replace("_"," ").capitalize())),participants],1.0,participants) if required_food>0.0 else 0.0
	var ration_coverage:=clampf(food_taken/maxf(0.001,required_food),0.0,1.0) if required_food>0.0 else 1.0
	var supply_coverage:=field_provision_delivery_ratio() if String(definition.scope)=="army" else clampf(0.45+float(GameState.society_capacities.get("institutions",0.25))*0.30+float(GameState.society_capacities.get("logistics",0.16))*0.25,0.0,1.0)
	var commander:Dictionary=home_army.get("commander",_marshal_commander())
	var instruction:=clampf(0.48+float(commander.get("command",0.5))*0.22+float(GameState.society_capacities.get("security",0.38))*0.20+_adoption("formation_drill")*0.10,0.35,1.15)
	var efficiency:=clampf(instruction*ration_coverage*(0.45+supply_coverage*0.55),0.0,1.20)
	training_program["food_required_total"]=float(training_program.get("food_required_total",0.0))+required_food
	training_program["food_consumed_total"]=float(training_program.get("food_consumed_total",0.0))+food_taken
	training_program["last_efficiency"]=efficiency
	training_program["paused_reason"]="" if efficiency>=0.05 else "Paused by an acute ration or delivery shortfall."
	if efficiency<0.05:
		_refresh_readiness()
		return
	var duration:=maxf(1.0,float(definition.duration_days))
	efficiency=minf(efficiency,maxf(0.0,duration-float(training_program.get("progress_days",0.0))))
	var progress_fraction:=efficiency/duration
	var formations:Array=[]
	for force in _exercise_forces():
		var force_formations:Array=force.get("formations",[])
		for formation_index in force_formations.size():
			var formation:Dictionary=force_formations[formation_index]
			formation["training"]=clampf(float(formation.get("training",0.4))+float(definition.training_gain)*progress_fraction,0.0,1.15)
			formation["experience"]=clampf(float(formation.get("experience",0.0))+float(definition.experience_gain)*progress_fraction,0.0,1.0)
			formation["personnel_condition"]=clampf(float(formation.get("personnel_condition",1.0))-float(definition.fatigue_per_day)*efficiency,0.0,1.0)
			force_formations[formation_index]=formation
		force["formations"]=force_formations
		force["exercise_readiness_bonus"]=clampf(float(force.get("exercise_readiness_bonus",0.0))+float(definition.readiness_gain)*progress_fraction,0.0,0.20)
		formations.append_array(force_formations)
	var command_focus_multiplier:=1.0+GameState.founding_effect("command_development")+ProgressionSystem.effect("warfare_readiness")*0.30
	for skill in (definition.get("command_gain",{}) as Dictionary):
		command_development[skill]=clampf(float(command_development.get(skill,0.0))+float(definition.command_gain[skill])*progress_fraction*command_focus_multiplier,0.0,0.30)
	var issued_equipment:=0
	for formation in formations: issued_equipment+=maxi(0,int(formation.get("equipment",0)))
	training_program["wear_accumulator"]=float(training_program.get("wear_accumulator",0.0))+float(issued_equipment)*float(definition.wear_rate)*efficiency
	var worn:=floori(float(training_program.wear_accumulator))
	if worn>0:
		training_program["wear_accumulator"]=float(training_program.wear_accumulator)-float(worn)
		var worn_actual:=_apply_exercise_equipment_wear(worn)
		training_program["equipment_worn"]=int(training_program.get("equipment_worn",0))+worn_actual
	training_program["progress_days"]=float(training_program.get("progress_days",0.0))+efficiency
	_refresh_readiness()
	if float(training_program.progress_days)>=duration: _complete_training_program(definition)


func _apply_exercise_equipment_wear(requested:int)->int:
	var remaining:=maxi(0,requested)
	for force in _exercise_forces():
		var formations:Array=force.get("formations",[])
		for formation_index in formations.size():
			if remaining<=0: break
			var formation:Dictionary=formations[formation_index]
			var damaged:=mini(remaining,maxi(0,int(formation.get("equipment",0))))
			if damaged<=0: continue
			formation["equipment"]=int(formation.get("equipment",0))-damaged
			var weapon:=String(formation.get("weapon","improvised"))
			damaged_equipment[weapon]=int(damaged_equipment.get(weapon,0))+damaged
			formations[formation_index]=formation
			remaining-=damaged
		force["formations"]=formations
	return requested-remaining


func _complete_training_program(definition:Dictionary)->void:
	var completed:=training_program.duplicate(true)
	completed["completed_day"]=int(GameState.elapsed_days)
	completed["readiness_bonus"]=float(home_army.get("exercise_readiness_bonus",0.0))
	completed["command_development"]=command_development.duplicate(true)
	completed["description"]=String(definition.description)
	last_training_program=completed
	training_program.clear()
	training_program_cycles+=1
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"%s complete" % String(definition.label).capitalize(),"description":"The exercise improved aggregate formation preparation and command practice. It consumed %.1f extra rations and wore %d issued equipment." % [float(completed.get("food_consumed_total",0.0)),int(completed.get("equipment_worn",0))],"domain":"security","severity":"notice"})
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	_refresh_readiness()
	army_changed.emit(home_army.duplicate(true))


func _process_training_day()->void:
	if training_queue.is_empty(): return
	var training_rate:=_effective_training_rate(_queued_trainees())
	var training_equipment_budget:=military_inventory.duplicate(true)
	for index in range(training_queue.size()-1,-1,-1):
		var training:Dictionary=training_queue[index]
		if training.has("build_batch") and float(training.progress_days)>=float(training.required_days):continue
		var weapon:=String(training.get("weapon","improvised"))
		var reserved_examples:=maxi(0,int(training.get("reserved_equipment",0)))
		var available_examples:=maxi(0,int(training_equipment_budget.get(weapon,0)))+reserved_examples
		var examples_required:=_equipment_required_for(String(training.get("unit","levy")),int(training.get("count",1)))
		var examples:=mini(maxi(1,examples_required),available_examples)
		training_equipment_budget[weapon]=maxi(0,available_examples-examples-reserved_examples)
		var equipment_access:=clampf(float(examples)/maxf(1.0,float(examples_required)),0.0,1.0)
		var access_floor:=0.55 if weapon=="improvised" else 0.25
		if training.has("personnel_condition"):training.personnel_condition=move_toward(float(training.personnel_condition),_trainee_condition(),.014)
		var progress_increment:=training_rate*(access_floor+(1.0-access_floor)*equipment_access)
		training["progress_days"]=float(training.get("progress_days",0.0))+progress_increment
		training["equipment_access_today"]=equipment_access
		training["equipment_access_sum"]=float(training.get("equipment_access_sum",0.0))+equipment_access*progress_increment
		training["instruction_progress_sum"]=float(training.get("instruction_progress_sum",0.0))+progress_increment
		var intensity:=float({"levy":0.75,"line_infantry":1.0,"skirmisher":0.90,"cavalry":1.20}.get(String(training.unit),1.0))
		var average_condition:=clampf(GameState.population_health*0.50+GameState.food_security*0.25+_population_shelter_condition()*0.25,0.0,1.0)
		training["injury_accumulator"]=float(training.get("injury_accumulator",0.0))+float(training.count)*0.0012*intensity*(1.35-average_condition*0.55)*_training_injury_risk_multiplier()
		var injuries:=mini(int(training.count),floori(float(training.injury_accumulator)))
		training["injury_accumulator"]=float(training.injury_accumulator)-float(injuries)
		if injuries>0:
			training["count"]=int(training.count)-injuries
			training_injury_pool+=injuries
		if int(training.count)<=0:
			military_inventory[weapon]=int(military_inventory.get(weapon,0))+int(training.get("reserved_equipment",0))
			training_queue.remove_at(index)
			continue
		if float(training.progress_days)<float(training.required_days):
			training_queue[index]=training
			continue
		if training.has("build_batch"):
			training_queue[index]=training;continue
		_complete_training(training)
		training_queue.remove_at(index)
	_complete_ready_build_batches()


func _process_training_injuries_day()->void:
	if training_injury_pool<=0:
		training_injury_recovery_accumulator=0.0
		return
	var recovery_rate:=clampf(0.045+_adoption("wound_cleaning")*0.035+_adoption("battlefield_medicine")*0.075,0.03,0.18)
	training_injury_recovery_accumulator+=float(training_injury_pool)*recovery_rate
	var recovered:=mini(training_injury_pool,floori(training_injury_recovery_accumulator))
	training_injury_recovery_accumulator-=recovered
	training_injury_pool-=recovered
	aggregate_recruits+=recovered


func _home_garrison_target()->int:
	# The macro Defense allocation is the standing local watch. It is distinct from
	# maneuver armies and occupation forces, which are explicitly away from home.
	return maxi(0,int(GameState.population_allocations.get("Defense",0)))


func _automatic_basic_trainees()->int:
	var total:=0
	for order_variant in training_queue:
		var order:Dictionary=order_variant
		if bool(order.get("automated_basic",false)): total+=maxi(0,int(order.get("count",0)))
	return total


func _ensure_automatic_basic_training()->void:
	# Assignment to Defense is enough to start basic levy/watch instruction. Players
	# still order every advanced unit, weapon conversion, reinforcement, and exercise.
	if not active_engagement.is_empty() or not pending_aftermath.is_empty(): return
	for template:Dictionary in army_templates:
		if bool(template.get("recruitment_requested",false)):return
	var target:=_home_garrison_target()
	var committed:=maxi(0,int(home_army.get("troops",0)))+_automatic_basic_trainees()
	var shortage:=maxi(0,target-committed)
	if shortage<=0: return
	var training_room:=maxi(0,training_capacity()-_queued_trainees())
	var mobilization_room:=maxi(0,recruitment_capacity()-_mobilized_count())
	var accepted:=mini(shortage,mini(training_room,mobilization_room))
	if accepted<=0: return
	var order_id:=next_training_order_id
	next_training_order_id+=1
	training_queue.append({"id":order_id,"mode":"new","automated_basic":true,"unit":"levy","weapon":"improvised","count":accepted,"initial_count":accepted,"experience":0.0,"progress_days":0.0,"required_days":maxf(3.0,float(UnitCatalog.training_days("levy"))),"injury_accumulator":0.0})
	army_changed.emit(home_army.duplicate(true))


func _training_injury_risk_multiplier()->float:
	return clampf(1.0-_adoption("wound_cleaning")*0.18-_adoption("battlefield_medicine")*0.42,0.35,1.0)


func _trainee_condition(_legacy_roster:Array=[])->float:
	return clampf(GameState.population_health*0.50+GameState.food_security*0.25+_population_shelter_condition()*0.25,0.0,1.0)


func _population_shelter_condition()->float:
	var capacity_ratio:=clampf(float(GameState.housing_capacity)/maxf(1.0,GameState.population_exact),0.0,1.0)
	var infrastructure:=clampf(float(GameState.society_capacities.get("infrastructure",0.05)),0.0,1.0)
	return clampf(capacity_ratio*0.82+infrastructure*0.18,0.0,1.0)


func _equipment_required_for(unit:String,personnel:int)->int:
	var default_weapon:=String(UnitCatalog.equipment_for(unit)[0])
	return simulator.equipment_required_for_weapon(default_weapon,personnel)


func _ammunition_required_for(weapon:String,equipment_required:int)->int:
	var authorized:=equipment_required
	if weapon in ["bow","service_rifle"]: authorized=equipment_required
	return simulator.ammunition_required_for_weapon(weapon,equipment_required,authorized)


func _ammunition_type_for(weapon:String)->String:
	return String({"bow":"arrows","field_gun":"artillery_rounds","service_rifle":"small_arms_ammunition","machine_gun":"small_arms_ammunition","motorized_kit":"small_arms_ammunition","armored_vehicle":"heavy_shells","modern_field_gun":"heavy_shells"}.get(weapon,""))


func _complete_training(training:Dictionary)->void:
	if home_army.is_empty(): home_army=_empty_home_army()
	var previous_army:Dictionary=home_army.duplicate(true)
	var count:=maxi(0,int(training.get("count",0)))
	if count<=0: return
	var weapon:=String(training.get("weapon","improvised"))
	var retained_experience:=clampf(float(training.get("experience",0.0)),0.0,1.0)
	var equipment_access_average:=clampf(float(training.get("equipment_access_sum",0.0))/maxf(0.01,float(training.get("instruction_progress_sum",training.get("required_days",1.0)))),0.0,1.0)
	var equipment_training_factor:=0.72+equipment_access_average*0.28
	var formations:Array=home_army.get("formations",[])
	var mode:=String(training.get("mode","new"))
	var target_index:=_formation_index(int(training.get("target_formation_id",-1))) if mode=="reinforce" else -1
	var equipment_needed:=_equipment_required_for(String(training.unit),count)
	if target_index>=0:
		var reinforcement_target:Dictionary=formations[target_index]
		equipment_needed=maxi(0,int(reinforcement_target.get("equipment_required",_equipment_required_for(String(training.unit),int(reinforcement_target.get("authorized_count",reinforcement_target.get("count",0))))))-int(reinforcement_target.get("equipment",0)))
	var reserved:=int(training.get("reserved_equipment",0))
	var issued:=mini(equipment_needed,reserved+int(military_inventory.get(weapon,0)))
	military_inventory[weapon]=int(military_inventory.get(weapon,0))+reserved-issued
	var new_training:=_training_quality(String(training.unit),retained_experience)*equipment_training_factor
	if training.has("prior_skill"):new_training=maxf(new_training,float(training.prior_skill))
	if target_index>=0:
		var target:Dictionary=formations[target_index]
		var old_count:=int(target.get("count",0))
		target["count"]=old_count+count
		target["equipment"]=int(target.get("equipment",0))+issued
		target["ammunition_required"]=_ammunition_required_for(weapon,int(target.get("equipment_required",_equipment_required_for(String(training.unit),int(target.get("authorized_count",old_count))))))
		target["training"]=(float(target.get("training",0.5))*old_count+new_training*count)/maxf(1.0,float(old_count+count))
		target["experience"]=(float(target.get("experience",0.0))*old_count+retained_experience*count)/maxf(1.0,float(old_count+count))
		target.erase("soldier_ids")
		formations[target_index]=target
	else:
		var formation_id:=next_formation_id; next_formation_id+=1
		var equipment_required:=_equipment_required_for(String(training.unit),count)
		var completed_formation:Dictionary={"id":formation_id,"unit":String(training.unit),"weapon":weapon,"count":count,"authorized_count":count,"equipment":issued,"equipment_required":equipment_required,"ammunition":0,"ammunition_required":_ammunition_required_for(weapon,equipment_required),"training":new_training,"experience":retained_experience,"personnel_condition":float(training.get("personnel_condition",_trainee_condition()))}
		if bool(training.get("prototype",false)): completed_formation["prototype"]=true
		formations.append(completed_formation)
	var rebuilt:Dictionary=simulator.create_formation_force(_home_army_name(),formations,float(previous_army.get("morale",_campaign_morale())),float(previous_army.get("readiness",1.0)))
	var structural_keys:Array[String]=["name","troops","attack","defense","armor","penetration","formations"]
	for key in previous_army:
		if key in structural_keys or key in ["soldier_ids","wounded_ids","scattered_ids","captured_ids"]: continue
		var prior_value:Variant=previous_army[key]
		rebuilt[key]=prior_value.duplicate(true) if prior_value is Array or prior_value is Dictionary else prior_value
	if not rebuilt.has("commander"): rebuilt["commander"]=_marshal_commander()
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
		"field_gun":{"materials":{"Iron Ore":8.0,"Timber":4.0,"Fiber Plants":0.50},"days":12.0},
		"service_rifle":{"materials":{"Iron Ore":1.8,"Timber":0.55,"Copper Ore":0.10},"days":2.2},
		"machine_gun":{"materials":{"Iron Ore":14.0,"Timber":1.5,"Copper Ore":0.8},"days":18.0},
		"motorized_kit":{"materials":{"Iron Ore":18.0,"Copper Ore":2.5,"Fiber Plants":1.0},"days":26.0},
		"armored_vehicle":{"materials":{"Iron Ore":65.0,"Copper Ore":5.0,"Tin Ore":1.0},"days":80.0},
		"modern_field_gun":{"materials":{"Iron Ore":24.0,"Copper Ore":1.5,"Timber":2.0},"days":34.0}
	}.get(item,{"materials":{},"days":1.0})


func _consumable_recipe(item:String)->Dictionary:
	return {
		"arrows":{"materials":{"Timber":0.08,"Fiber Plants":0.025,"Stone":0.015},"days":0.055},
		"artillery_rounds":{"materials":{"Sulfur":0.12,"Nitrates":0.18,"Iron Ore":0.20,"Timber":0.08},"days":0.18},
		"small_arms_ammunition":{"materials":{"Sulfur":0.025,"Nitrates":0.04,"Iron Ore":0.035,"Copper Ore":0.012},"days":0.018},
		"heavy_shells":{"materials":{"Sulfur":0.35,"Nitrates":0.48,"Iron Ore":0.85,"Copper Ore":0.05},"days":0.42}
	}.get(item,{"materials":{},"days":1.0})


func _transport_recipe()->Dictionary:
	return {"materials":{"Timber":8.0,"Fiber Plants":1.5},"days":5.0}


func _unit_equipment_view()->Dictionary:
	var view:Dictionary={}
	for unit in UnitCatalog.ARCHETYPES: view[unit]=UnitCatalog.equipment_for(String(unit)).duplicate()
	return view


func _knowledge_gate(discovery:String,minimum_adoption:float)->Dictionary:
	if discovery=="": return {"unlocked":true,"discovery":"","adoption":1.0,"minimum_adoption":0.0,"prerequisites":[],"reason":"Available through basic household practice."}
	# Old saves may still carry the legacy sentinel; it now resolves to the
	# real domestication discovery instead of a permanent lock.
	if discovery=="__mount_population__": discovery="domesticated_mounts"
	if discovery.begins_with("__military_tier_"):
		var required_tier:=int(discovery.trim_prefix("__military_tier_").trim_suffix("__"))
		var development:=military_development_snapshot()
		var current_tier:=int(development.get("tier",0))
		return {"unlocked":current_tier>=required_tier,"discovery":"","military_tier":current_tier,"required_military_tier":required_tier,"adoption":1.0 if current_tier>=required_tier else 0.0,"minimum_adoption":1.0,"prerequisites":[],"reason":"Available through %s." % String(development.label).capitalize() if current_tier>=required_tier else "Requires military development band %d, produced by adopted security research plus supporting production, logistics, and institutions." % required_tier}
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
	return (0.42+security*0.55)*(1.0+_adoption("formation_drill")*0.35+_adoption("professional_corps")*0.55+GameState.founding_effect("training_rate")+ProgressionSystem.effect("warfare_readiness"))


func training_capacity()->int:
	var defense_workers:=float(GameState.population_allocations.get("Defense",0))
	var commander:Dictionary=home_army.get("commander",_marshal_commander())
	var command:=clampf(float(commander.get("command",0.5)),0.0,1.0)
	var base:=3.0+defense_workers*0.30+command*3.0
	base*=1.0+_adoption("formation_drill")*0.45+_adoption("professional_corps")*0.70+_adoption("military_staffs")*0.20+GameState.founding_effect("training_capacity")+ProgressionSystem.effect("security_efficiency")*0.60
	return maxi(1,floori(base))


func _effective_training_rate(trainees:int)->float:
	if trainees<=0: return _training_rate()
	var load_factor:=minf(1.0,float(training_capacity())/float(trainees))
	return _training_rate()*load_factor


func _training_quality(unit:String,retained_experience:float=0.0)->float:
	var base:=float({"levy":0.48,"line_infantry":0.58,"skirmisher":0.55,"cavalry":0.56}.get(unit,0.50))
	var commander:Dictionary=home_army.get("commander",_marshal_commander())
	var doctrine_transfer:=_army_experience()*_adoption("professional_corps")
	return clampf(base+float(commander.get("command",0.5))*0.12+_adoption("formation_drill")*0.14+_adoption("professional_corps")*0.12+_adoption("military_staffs")*0.06+retained_experience*0.20+doctrine_transfer*0.12+GameState.founding_effect("command_development")*0.08,0.30,1.15)


func _refresh_formation_experience()->void:
	if home_army.is_empty(): return
	var formations:Array=home_army.get("formations",[])
	for index in formations.size(): formations[index]["experience"]=clampf(float(formations[index].get("experience",0.0)),0.0,1.0)
	home_army["formations"]=formations


func _army_experience()->float:
	if home_army.is_empty(): return 0.0
	var weighted:=0.0
	var personnel:=0
	for formation in home_army.get("formations",[]):
		var count:=maxi(0,int(formation.get("count",0)))
		weighted+=float(formation.get("experience",0.0))*count
		personnel+=count
	return weighted/maxf(1.0,float(personnel))


func _refresh_readiness()->void:
	if home_army.is_empty(): return
	_synchronize_field_commander()
	for force in field_armies:
		var condition:=_force_personnel_condition(force)
		var prepared:Dictionary=simulator.force_readiness(force,condition)
		force["readiness"]=clampf(float(prepared.aggregate)*(0.48+clampf(float(force.get("supply_level",1.0)),0.0,1.0)*0.52)+float(force.get("exercise_readiness_bonus",0.0)),0.0,1.25)
	var formations:Array=home_army.get("formations",[])
	var supply:=clampf(float(home_army.get("supply_level",1.0)),0.0,1.0)
	var discipline:=clampf(float(home_army.get("discipline",0.5)),0.0,1.0)
	var exercise_bonus:=clampf(float(home_army.get("exercise_readiness_bonus",0.0)),0.0,0.20)
	var base_condition:=clampf(GameState.population_health*0.55+GameState.food_security*0.18+_population_shelter_condition()*0.12+supply*0.15,0.0,1.0)
	for formation_index in formations.size():
		var formation:Dictionary=formations[formation_index]
		var formation_condition:=clampf(float(formation.get("personnel_condition",base_condition)),0.0,1.0)
		formation["personnel_condition"]=formation_condition
		var formation_force:Dictionary={"formations":[formation],"morale":float(home_army.get("morale",1.0))}
		var formation_readiness:Dictionary=simulator.force_readiness(formation_force,formation_condition)
		formation["readiness"]=clampf(float(formation_readiness.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)+exercise_bonus,0.0,1.25)
		formations[formation_index]=formation
	home_army["formations"]=formations
	var readiness:Dictionary=simulator.force_readiness(home_army,_force_personnel_condition(home_army))
	home_army["readiness"]=clampf(float(readiness.aggregate)*(0.48+supply*0.52)*(0.88+discipline*0.12)+exercise_bonus,0.0,1.25)
	home_army["readiness_components"]=readiness
	home_army.readiness_components["supply"]=supply
	home_army.readiness_components["discipline"]=discipline
	home_army.readiness_components["exercise_preparation"]=exercise_bonus
	home_army.readiness_components["service_strain"]=clampf(float(home_army.get("service_strain",0.0)),0.0,1.0)


func _production_rate()->float:
	return _base_production_rate()*workshop_utilization()


func _base_production_rate()->float:
	var crafting:=float(GameState.population_allocations.get("Crafting",0))*0.16
	if crafting<=0.0: return 0.0
	var industrial_scale:=ProgressionSystem.domain_factor("production",0.18)
	var logistics_scale:=ProgressionSystem.domain_factor("logistics",0.07)
	return crafting*(0.55+float(GameState.society_capacities.get("production",0.12))*0.45+_adoption("workshop_standards")*0.45)*industrial_scale*logistics_scale


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
		var exchanged:=mini(count,maxi(0,int(home_army.get("captured_pool",0))))
		var returned:=_return_home_captives(exchanged)
		outcome["exchanged_prisoners"]=returned
		outcome["returned_population"]=returned
		outcome["released_prisoners"]=count-returned
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


func _return_home_captives(count:int)->int:
	var held:=mini(recovery.held_military(),maxi(0,int(home_army.get("captured_pool",0))))
	var captured:=maxi(0,int(home_army.get("captured_pool",0))-held)
	var returned:=mini(maxi(0,count),captured)
	home_army["captured_pool"]=captured-returned+held
	if returned>0: aggregate_recruits+=returned
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
	var general:Dictionary=(aftermath.get("commander_record",{}) as Dictionary).duplicate(true)
	general["name"]=String(general.get("name",aftermath.get("commander","CAPTURED COMMAND STAFF")))
	general["institutional"]=true
	general["captured_day"]=int(GameState.elapsed_days)
	for skill in ["command","tactics","logistics","resolve"]: general[skill]=clampf(float(general.get(skill,0.5)),0.0,1.0)
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
	HistoricalFigures.resolve_captive(String(general.get("figure_id","")),policy.to_lower())
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
	var available:=maxi(0,int(home_army.get("troops",0)))
	var marked:=mini(maxi(0,count),available)
	if marked<=0: return
	var remaining:=marked
	var formations:Array=home_army.get("formations",[])
	for index in range(formations.size()-1,-1,-1):
		if remaining<=0: break
		var formation:Dictionary=formations[index]
		var removed:=mini(remaining,maxi(0,int(formation.get("count",0))))
		formation["count"]=int(formation.get("count",0))-removed
		remaining-=removed
		formations[index]=formation
	home_army["formations"]=formations
	home_army["troops"]=available-marked
	home_army["captured_pool"]=maxi(0,int(home_army.get("captured_pool",0)))+marked
	home_army["captive_days"]=0
	_refresh_readiness()


func _mark_engaged_force_prisoners(force_kind:String,force_id:int,civ_id:String,region_id:String,count:int)->void:
	var requested:=maxi(0,count)
	if requested<=0: return
	if force_kind=="field_army":
		var army_index:=_field_army_index(force_id)
		if army_index<0: return
		var field_home_reserve:=home_army
		home_army=field_armies[army_index].duplicate(true)
		_mark_home_prisoners(requested)
		field_armies[army_index]=home_army
		home_army=field_home_reserve
		return
	if force_kind=="occupation":
		var occupation_index:=_occupation_force_index(civ_id,region_id)
		if occupation_index<0: return
		var occupation_home_reserve:=home_army
		home_army=occupation_forces[occupation_index].duplicate(true)
		_mark_home_prisoners(requested)
		occupation_forces[occupation_index]=home_army
		home_army=occupation_home_reserve
		return
	_mark_home_prisoners(requested)


func battle_report_text(result:Dictionary)->String:
	var home_side:=String(result.get("home_side","attacker"))
	var home:Dictionary=result.get(home_side,{})
	var enemy:Dictionary=result.get("defender" if home_side=="attacker" else "attacker",{})
	var threat:Dictionary=result.get("threat",{})
	var opponent:=String(threat.get("source_name",enemy.get("name","an unidentified force")))
	var place:=String(result.get("target_region_name",threat.get("target_region_name",GameState.settlement_name)))
	if place.is_empty(): place="the settlement"
	var losses:=maxi(0,int(home.get("initial_troops",home.get("troops",0)))-int(home.get("remaining_troops",0)))
	return "%s at %s against %s. Our force: %d remaining; %d lost or removed from the field; morale %.0f%%. %s" % [String(result.get("outcome","inconclusive")).replace("_"," ").capitalize(),place,opponent,int(home.get("remaining_troops",0)),losses,float(home.get("morale",0.0))*100.0,"We defended against an approaching attack." if home_side=="defender" else "Our force was conducting an offensive operation."]

func _record_council_battle(result:Dictionary)->void:
	GameState.council_inbox.push_front({"id":"battle_%d_%d" % [int(GameState.elapsed_days),int(result.seed)],"advisor":"FIELD COMMAND","office":"Marshal","topic":"security","act":{"type":"warn"},"text":battle_report_text(result),"urgency":1.0,"severity":"critical","day":int(GameState.elapsed_days),"status":"unread","battle_seed":int(result.seed)})


func _aftermath_description(outcome:Dictionary)->String:
	var aftermath:Dictionary=outcome.get("aftermath",{})
	var summary:=String(aftermath.get("summary",""))
	var home_won:=String(aftermath.get("captor",""))==String(home_army.get("name",""))
	if not home_won:
		var lost_prisoners:=int(aftermath.get("prisoners",0))
		if lost_prisoners>0: return "%s%d field personnel were taken captive." % [summary+" " if summary!="" else "",lost_prisoners]
		return summary if summary!="" else "The army returned without captured spoils."
	var parts:Array[String]=[]
	var prisoners:=int(aftermath.get("prisoners",0))
	if prisoners>0:
		match String(outcome.get("prisoner_policy","hold")).to_lower():
			"hold": parts.append("%d prisoners held" % prisoners)
			"release": parts.append("%d prisoners released" % prisoners)
			"parole": parts.append("%d prisoners paroled" % prisoners)
			"exchange": parts.append("%d captives exchanged" % int(outcome.get("exchanged_prisoners",0)))
			"ransom": parts.append("%d prisoners ransomed" % prisoners)
			"execute": parts.append("%d prisoners executed" % prisoners)
			"enslave": parts.append("%d prisoners enslaved" % prisoners)
	if bool(aftermath.get("captured_general",false)):
		var general_policy:=String(outcome.get("general_policy","hold")).to_lower()
		var general_result:=String({"hold":"held","release":"released","ransom":"ransomed","execute":"executed"}.get(general_policy,general_policy))
		parts.append("%s %s" % [String(aftermath.get("commander","Enemy commander")),general_result])
	var spoils:Dictionary=outcome.get("spoils",{})
	var spoil_parts:Array[String]=[]
	for entry in [["gear","gear"],["ammunition","ammunition"],["supplies","supplies"],["carts","carts"],["wealth","wealth"]]:
		var amount:=int(spoils.get(String(entry[0]),0))
		if amount>0: spoil_parts.append("%d %s" % [amount,String(entry[1])])
	if not spoil_parts.is_empty(): parts.append("Spoils: %s" % ", ".join(spoil_parts))
	return ". ".join(parts)+"." if not parts.is_empty() else (summary if summary!="" else "Battle aftermath resolved.")

func _demobilize_disabled(requested:int)->int:
	var amount:=mini(maxi(0,requested),mini(int(home_army.get("disabled_pool",0)),int(home_army.get("wounded_pool",0))))
	if amount<=0: return 0
	var severe:=mini(amount,int(home_army.get("severe_disabled_pool",0)))
	home_army["disabled_pool"]=int(home_army.get("disabled_pool",0))-amount
	home_army["severe_disabled_pool"]=int(home_army.get("severe_disabled_pool",0))-severe
	home_army["wounded_pool"]=int(home_army.get("wounded_pool",0))-amount
	GameState.receive_injured_veterans(amount,severe)
	return amount


func offensive_siege_availability(civ_id:String,region_id:String,army_id:int=0)->Dictionary:
	var available:=offensive_campaign_availability(civ_id,region_id,army_id)
	if available.has("error"): return available
	if bool(available.incident.get("liberation_campaign",false)): return {"error":"Sieges currently require an opponent-owned settlement; use the existing liberation campaign for occupied foreign regions."}
	return available

func start_offensive_siege(civ_id:String,region_id:String,army_id:int=0)->Dictionary:
	var available:=offensive_siege_availability(civ_id,region_id,army_id)
	if available.has("error"): return available
	_create_civilization_threat(available.incident,"offensive")
	var result:=begin_siege()
	if not result.has("error"):
		active_siege.threat["war_id"]=CivilizationSystem.record_player_hostile_order(civ_id,region_id,"A player army began a hostile siege.")
	else:active_threat.clear()
	return result

func begin_siege()->Dictionary:
	if not active_siege.is_empty() or not active_engagement.is_empty() or not pending_aftermath.is_empty(): return {"error":"Resolve the current military operation first."}
	if active_threat.is_empty() or bool(active_threat.get("field_encounter",false)) or String(active_threat.get("incident_kind","campaign"))=="raid": return {"error":"A siege needs a settlement campaign, not a passing raid or field encounter."}
	var offensive:=String(active_threat.get("campaign_mode","defensive"))=="offensive"
	if not offensive and not String(active_threat.get("target_region_id","")).is_empty(): return {"error":"This siege interface currently supports the home settlement and field-army offensives; defend the occupation through its existing battle controls."}
	var army_id:=int(active_threat.get("field_army_id",0))
	var index:=_field_army_index(army_id)
	if offensive and (index<0 or int(field_armies[index].get("troops",0))<=0): return {"error":"The investing army is no longer available."}
	var rival:=String(active_threat.get("source_civ_id",""))
	if rival.is_empty(): return {"error":"The besieging force has no known campaign owner."}
	var day:=int(GameState.elapsed_days)
	var region_id:=String(active_threat.get("target_region_id",""))
	if offensive and (String(field_armies[index].get("status",""))!="stationed" or String(field_armies[index].get("location_id",""))!=region_id): return {"error":"The investing army must be stationed at the selected settlement."}
	var position:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	if offensive:
		var point:Dictionary=field_armies[index].get("position",{})
		if not point.has_all(["x","z"]): return {"error":"The investing army has no valid physical position."}
		position=Vector2(float(point.x),float(point.z))
	active_threat["target_position"]={"x":position.x,"z":position.y}
	active_siege={"id":"siege_%d_%d_%d_%d" % [GameState.world_seed,day,army_id,threats_resolved],"active":true,"mode":"offensive" if offensive else "defensive","attacker_id":"player" if offensive else rival,"defender_id":rival if offensive else "player","start_day":day,"last_day":day,"days":0,"target_position":{"x":position.x,"z":position.y},"region_id":region_id,"army_id":army_id,"threat":active_threat.duplicate(true),"pressure":0.0,"fatigue":0.0,"blockade":0.0,"hardship":0.0,"starving_days":0,"relief":[]}
	if not offensive:active_siege.home_city={"id":SettlementModel._primary_settlement_id(),"name":GameState.settlement_name,"population":SettlementModel.primary_population_exact(),"defense_stage":int(settlement_defense.get("stage",0))}
	active_threat.clear()
	if offensive: field_armies[index]["status"]="besieging"
	if not offensive and ForeignDiplomacy.has_method("notify_defensive_siege"): ForeignDiplomacy.call("notify_defensive_siege",rival,"player",String(active_siege.id),day)
	threat_changed.emit({}); army_changed.emit(home_army.duplicate(true))
	return {"ok":true,"siege":siege_public_snapshot(),"message":"The army takes positions around the approaches. Supply and endurance now change over time; no assault or population transfer has occurred."}

func siege_snapshot()->Dictionary:
	return siege_public_snapshot()

func siege_public_snapshot(siege_id:String="")->Dictionary:
	if active_siege.is_empty() or (not siege_id.is_empty() and siege_id!=String(active_siege.id)): return {}
	var result:Dictionary={}
	for key in ["id","active","mode","attacker_id","defender_id","start_day","days","target_position","region_id","pressure","blockade"]: result[key]=active_siege.get(key)
	var offensive:=String(active_siege.mode)=="offensive"
	result["own_supply_ratio"]=_siege_own_supply()
	result["own_food_days"]=maxf(0,float(GameState.simulation_metrics.get("food_days",0))) if not offensive else -1.0
	result["enemy_supply_assessment"]="No reliable count of enemy stores."
	result["enemy_supply_report_day"]=-1
	var rival:=String(active_siege.defender_id if offensive else active_siege.attacker_id)
	if offensive:
		var city:Dictionary=CivilizationSystem.city_intelligence.known("player",String(active_siege.region_id))
		var supply:Dictionary=city.get("fields",{}).get("supply",{})
		if not supply.is_empty():
			result["enemy_supply_assessment"]="Regional reserve outlook observed at this city: %d–%d days; %s." % [roundi(float(supply.low)),roundi(float(supply.high)),"stale" if bool(supply.stale) else "dated estimate"]
			result["enemy_supply_report_day"]=int(supply.observed_day)
	result["civilian_hardship"]=("Critical: people lack reliable food access." if float(active_siege.hardship)>.6 else "Strained: approaches and outside work are restricted.") if not offensive else "Civilian access is restricted; exact stores and hunger inside are unconfirmed."
	result["besieger_endurance"]=("Exhausted" if float(active_siege.fatigue)>.7 else ("Strained" if float(active_siege.fatigue)>.35 else "Holding")) if offensive else "Enemy endurance is not directly known."
	result["relief_camps"]=(active_siege.get("relief",[]) as Array).size()
	result["target_name"]=String((active_siege.threat as Dictionary).get("target_region_name","Home settlement"))
	if String(result.target_name).is_empty(): result.target_name="Home settlement"
	return result

func _siege_own_supply()->float:
	if active_siege.is_empty(): return 1.0
	var index:=_field_army_index(int(active_siege.get("army_id",0)))
	if String(active_siege.mode)=="offensive" and index>=0: return clampf(float(field_armies[index].get("provision_ratio",field_armies[index].get("supply_level",.5))),0,1)
	return clampf(float(GameState.simulation_metrics.get("food_intake_ratio",GameState.food_security)),0,1)

func siege_home_food_access()->float:
	if active_siege.is_empty() or String(active_siege.mode)!="defensive": return 1.0
	return clampf(1-float(active_siege.get("blockade",0))*.8,.2,1)

func siege_effects_for_civilization(civ_id:String)->Dictionary:
	var share:=0.0
	if not active_siege.is_empty() and String(active_siege.mode)=="offensive" and String(active_siege.defender_id)==civ_id:
		for civ:Dictionary in CivilizationSystem.civilizations:
			if String(civ.id)!=civ_id: continue
			for region:Dictionary in civ.get("strategic_regions",[]):
				if String(region.get("id",""))==String(active_siege.region_id): share=clampf(float(region.get("population",0))/maxf(1,float(civ.population)),0,1)
	var closure:=float(active_siege.get("blockade",0))*share
	return {"food_output_multiplier":clampf(1-closure*.8,.2,1),"logistics_multiplier":clampf(1-closure*.7,.3,1)}

func _process_siege_day()->void:
	if active_siege.is_empty(): return
	var day:=last_processed_day
	if day<=int(active_siege.last_day): return
	var offensive:=String(active_siege.mode)=="offensive"
	var rival:=String(active_siege.defender_id if offensive else active_siege.attacker_id)
	var enemy:Dictionary={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==rival: enemy=civ; break
	if enemy.is_empty(): _end_siege("The opposing campaign is no longer active."); return
	var relation:Dictionary=enemy.get("player_relation",{})
	if not bool(relation.get("at_war",false)): _end_siege("A ceasefire lifts the siege."); return
	var army_index:=_field_army_index(int(active_siege.army_id))
	if offensive and (army_index<0 or int(field_armies[army_index].get("troops",0))<=0): _end_siege("The investing force can no longer hold the approaches."); return
	var threat:Dictionary=active_siege.threat
	var enemy_force:Dictionary=threat.get("enemy_force",{})
	var own_strength:=int(field_armies[army_index].get("troops",0)) if offensive else int(settlement_defense_snapshot().get("garrison_personnel",0))
	var enemy_strength:=int(enemy_force.get("troops",0))
	var enemy_supply:=clampf(float(enemy.get("food_days",0))/10,0,1)*clampf(.35+float(enemy.get("logistics",.3)),0,1)
	var besieger_relief:=0.0; var defender_relief:=0.0
	var camps:Array=active_siege.get("relief",[])
	for index in range(camps.size()-1,-1,-1):
		var camp:Dictionary=camps[index]
		var ration:=maxf(0,float(camp.troops))*.55
		var supplied:=clampf(float(camp.food)/maxf(.01,ration),0,1)
		camp["food"]=maxf(0,float(camp.food)-ration)
		if supplied<.1:
			_return_siege_relief(camp); camps.remove_at(index); continue
		if String(camp.beneficiary_id)==String(active_siege.attacker_id): besieger_relief+=float(camp.troops)*supplied
		else: defender_relief+=float(camp.troops)*supplied
	active_siege["relief"]=camps
	var inputs:={"besiegers":(own_strength if offensive else enemy_strength)+besieger_relief,"defenders":enemy_strength if offensive else own_strength,"population":float(threat.get("target_population",1000)) if offensive else SettlementModel.primary_population_exact(),"defender_relief":defender_relief,"besieger_supply":_siege_own_supply() if offensive else enemy_supply,"defender_food_days":float(enemy.get("food_days",0)) if offensive else float(GameState.simulation_metrics.get("food_days",0)),"fortification":clampf(float(threat.get("terrain_defense",1.0))-1,0,1) if offensive else float(settlement_defense_snapshot().get("defense_bonus",0))}
	active_siege=SiegeModel.advance(active_siege,day,inputs)
	if float(active_siege.fatigue)>=.98 or int(active_siege.starving_days)>=7: _end_siege("The besiegers abandon the investment as their supply and endurance fail."); return
	army_changed.emit(home_army.duplicate(true))

func siege_order(siege_id:String,order:String)->Dictionary:
	if active_siege.is_empty() or siege_id!=String(active_siege.id): return {"error":"This siege is no longer active."}
	if order=="continue": return {"ok":true,"message":"The existing siege orders continue. Time, supply and access determine its progress."}
	var saved:=active_siege.duplicate(true)
	if order=="assault":
		var field_index:=_field_army_index(int(saved.army_id))
		var troops:=int(field_armies[field_index].get("troops",0)) if String(saved.mode)=="offensive" and field_index>=0 else (int(_home_defense_force().get("troops",0)) if String(saved.mode)=="defensive" else 0)
		if troops<=0 or not pending_aftermath.is_empty() or not active_engagement.is_empty(): return {"error":"No available local force can enter battle; the siege orders remain in place."}
		_end_siege("The forces leave siege positions for battle.",false,false)
		active_threat=(saved.threat as Dictionary).duplicate(true)
		var result:=begin_threat_engagement()
		if result.has("error"): return result
		active_engagement["terrain_defense"]=1+(float(active_engagement.terrain_defense)-1)*(1-float(saved.pressure)*.65)
		var besieger_key:="attacker"
		active_engagement[besieger_key]["readiness"]=float(active_engagement[besieger_key].get("readiness",.5))*(1-float(saved.fatigue)*.45)
		return {"ok":true,"message":"The assault or sortie begins from current siege conditions.","engagement":engagement_snapshot()}
	if order=="withdraw":
		_end_siege("The player orders withdrawal from the siege.",true,String(saved.mode)=="offensive")
		if String(saved.mode)=="defensive":
			threats_resolved+=1
			return recovery.capture(String(saved.attacker_id))
		return {"ok":true,"message":"The siege is lifted; the field army begins its physical return route if available."}
	return {"error":"Unknown siege order."}

func _end_siege(reason:String,return_army:bool=true,count_resolved:bool=true)->void:
	if active_siege.is_empty(): return
	var ended:=active_siege.duplicate(true)
	for camp:Dictionary in ended.get("relief",[]): _return_siege_relief(camp)
	active_siege.clear()
	var index:=_field_army_index(int(ended.get("army_id",0)))
	if index>=0:
		field_armies[index]["status"]="stationed"
		if return_army:
			var return_route:=move_field_army(int(ended.army_id),"player_home")
			if return_route.has("error"): reason+=" The army remains at its position: "+String(return_route.error)
	ended["active"]=false; ended["ended_day"]=int(GameState.elapsed_days); ended["summary"]=reason; ended["relief"]=[]
	siege_history.push_front(ended)
	if siege_history.size()>SiegeModel.HISTORY_LIMIT: siege_history.resize(SiegeModel.HISTORY_LIMIT)
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Siege ended","description":reason,"domain":"security","severity":"major"})
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	if count_resolved: threats_resolved+=1
	army_changed.emit(home_army.duplicate(true))

func siege_negotiation_available(siege_id:String,civ_id:String)->Dictionary:
	if active_siege.is_empty() or String(active_siege.id)!=siege_id or civ_id=="player" or civ_id not in [active_siege.attacker_id,active_siege.defender_id]: return {"ok":false,"reason":"No opposing siege is available for these talks."}
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==civ_id and not bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return {"ok":true,"reason":"An agreed ceasefire permits withdrawal."}
	if float(active_siege.fatigue)>=.7: return {"ok":true,"reason":"Visible exhaustion makes lifting the siege credible."}
	return {"ok":false,"reason":"No ceasefire or credible withdrawal condition has been established. Continue talks; no agreement is assumed."}

func negotiated_siege_withdrawal(siege_id:String,civ_id:String)->Dictionary:
	var available:=siege_negotiation_available(siege_id,civ_id)
	if not bool(available.ok): return {"error":available.reason}
	_end_siege("Returned envoys confirm the siege will be lifted without a territorial transfer.")
	return {"ok":true,"message":"The siege is lifted. Forces return by their existing routes; no territory changes hands."}

func receive_siege_relief(siege_id:String,receipt_id:String)->Dictionary:
	if active_siege.is_empty() or String(active_siege.id)!=siege_id: return {"error":"The siege ended before relief arrived."}
	var camps:Array=active_siege.get("relief",[])
	if camps.size()>=SiegeModel.RELIEF_LIMIT: return {"error":"The siege already has its bounded relief-camp capacity."}
	for camp:Dictionary in camps:
		if String(camp.receipt_id)==receipt_id: return {"error":"This relief delivery has already been received."}
	if not CivilizationSystem.has_method("consume_siege_relief_receipt"): return {"error":"No verified relief delivery is available."}
	var receipt:Dictionary=CivilizationSystem.call("consume_siege_relief_receipt",receipt_id,siege_id)
	if not bool(receipt.get("ok",false)): return receipt
	if String(receipt.get("beneficiary_id","")) not in [active_siege.attacker_id,active_siege.defender_id]:
		_return_siege_relief({"receipt_id":receipt_id,"troops":int(receipt.get("troops",0)),"food":float(receipt.get("food",0))})
		return {"error":"Relief belongs to another operation and is returning to its donor."}
	var camp:={"receipt_id":receipt_id,"donor_civ_id":String(receipt.get("donor_civ_id","")),"beneficiary_id":String(receipt.beneficiary_id),"troops":maxi(0,int(receipt.get("troops",0))),"food":maxf(0,float(receipt.get("food",0)))}
	camps.append(camp); active_siege["relief"]=camps
	return {"ok":true,"message":"A physically delivered allied camp supports the approaches. Its people remain part of their own society."}

func _return_siege_relief(camp:Dictionary)->void:
	if ForeignDiplomacy.has_method("complete_siege_relief"): ForeignDiplomacy.call("complete_siege_relief",String(camp.receipt_id),int(camp.troops),float(camp.food))


func training_progress_snapshot()->Dictionary:
	var result:Dictionary={}
	var budget:=military_inventory.duplicate(true)
	var trainees:=_queued_trainees()
	var capacity:=training_capacity()
	var base_rate:=_effective_training_rate(trainees)
	for index in range(training_queue.size()-1,-1,-1):
		var order:Dictionary=training_queue[index]
		var weapon:=String(order.get("weapon","improvised"))
		var needed:=_equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))
		var examples:=mini(maxi(1,needed),maxi(0,int(budget.get(weapon,0))))
		budget[weapon]=maxi(0,int(budget.get(weapon,0))-examples)
		var access:=clampf(float(examples)/maxf(1,needed),0,1)
		var floor_access:=.55 if weapon=="improvised" else .25
		var rate:=base_rate*(floor_access+(1-floor_access)*access)
		var progress:=float(order.get("progress_days",0)); var required:=maxf(1,float(order.get("required_days",1)))
		var reasons:Array[String]=[]
		if trainees>capacity: reasons.append("Crowded classes: %d trainees / %d places" % [trainees,capacity])
		if access<.999: reasons.append("Limited practice equipment: %d of %d" % [examples,needed])
		if reasons.is_empty(): reasons.append("Normal instruction pace")
		result[int(order.id)]={"id":int(order.id),"count":int(order.count),"unit":String(order.unit),"weapon":weapon,"progress":progress,"required":required,"percent":roundi(clampf(progress/required,0,1)*100),"rate":rate,"estimated_days":ceili(maxf(0,required-progress)/rate) if rate>0 else -1,"elapsed_days":maxi(0,int(GameState.elapsed_days)-int(order.start_day)) if order.has("start_day") else -1,"reason":" · ".join(reasons),"injured":maxi(0,int(order.get("initial_count",order.count))-int(order.count))}
	return result

func siege_visual_snapshot(siege_id:String="")->Dictionary:
	var operation:Dictionary=active_siege
	if operation.is_empty() or (siege_id!="" and String(operation.id)!=siege_id):
		operation={}
		for past:Dictionary in siege_history:
			if siege_id=="" or String(past.id)==siege_id: operation=past;break
	if operation.is_empty():return {}
	var offensive:=String(operation.mode)=="offensive"
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player",String(operation.region_id)) if offensive else {}
	var population:=SettlementModel.primary_population_exact() if not offensive else -1.0
	var damage:=0.0
	var defense_stage:=int(settlement_defense.get("stage",0)) if not offensive else -1
	var description:="Your settlement and its current defenses."
	if offensive:
		var fields:Dictionary=city.get("fields",{})
		var count:Dictionary=fields.get("population",{})
		if not count.is_empty():population=(float(count.low)+float(count.high))*.5
		var fort:Dictionary=fields.get("fortification",{})
		if not fort.is_empty():
			# Foreign reports currently describe strength, not architectural material.
			# Show reported earthworks, never infer stone walls from an abstract score.
			defense_stage=2 if float(fort.low)>.1 else 0
		var ruin:Dictionary=fields.get("damage",{})
		if not ruin.is_empty():damage=(float(ruin.low)+float(ruin.high))*.5
		description="Representative layout from dated reports. Building materials and exact interior layout are unconfirmed."
	var archived_home:Dictionary=operation.get("home_city",{})
	var same_home:=String(archived_home.get("id",SettlementModel._primary_settlement_id()))==SettlementModel._primary_settlement_id() and not recovery.home_unavailable()
	if not offensive and not same_home:
		population=float(archived_home.get("population",population));defense_stage=int(archived_home.get("defense_stage",defense_stage))
		description="Last observed city layout at the siege. Occupation and recovery continue through Survival & Independence."
	var own_force:Dictionary={}
	if offensive:
		var index:=_field_army_index(int(operation.get("army_id",0)))
		if index>=0:own_force=field_armies[index].duplicate(true)
	elif same_home:own_force=_home_defense_force(false)
	var battle:Dictionary={}
	var seed_value:=int((operation.get("threat",{}) as Dictionary).get("seed",-1))
	if not active_engagement.is_empty() and int(active_engagement.get("seed",-2))==seed_value:battle=engagement_snapshot()
	else:
		for past_battle:Dictionary in battle_history:
			if int(past_battle.get("seed",-2))==seed_value:battle=past_battle.duplicate(true);break
	return {"id":String(operation.id),"active":not active_siege.is_empty() and String(active_siege.id)==String(operation.id),"mode":String(operation.mode),"name":String(city.get("name",(String(archived_home.get("name",GameState.settlement_name)) if String(archived_home.get("name",GameState.settlement_name))!="" else "Home settlement") if not offensive else "Reported settlement")),"population":population,"defense_stage":defense_stage,"damage":damage,"blockade":float(operation.get("blockade",0)),"description":description,"own_force":own_force,"battle":battle,"battle_active":not active_engagement.is_empty() and int(active_engagement.get("seed",-2))==seed_value,"summary":String(operation.get("summary","")),"region_id":String(operation.region_id),"rival":String(operation.defender_id if offensive else operation.attacker_id)}

func template_recruitment_blocker()->String:
	if not active_engagement.is_empty() or not pending_aftermath.is_empty():return "Resolve the battle or aftermath before recruiting."
	if recovery.home_unavailable():return "Home is occupied."
	if _mobilized_count()>=recruitment_capacity() and aggregate_recruits<=0:return "Mobilization full: %d of %d people; growth or military institutions must expand capacity." % [_mobilized_count(),recruitment_capacity()]
	return "Available places will enter training on the next simulation day while the order is active."
func cancel_template_recruitment(template_id:int)->Dictionary:
	var index:=_template_index(template_id)
	if index<0:return {"error":"Build not found."}
	army_templates[index].recruitment_requested=false
	return {"ok":true,"message":"Further recruitment stopped. Existing soldiers and queued trainees remain."}
func _process_requested_templates()->void:
	if not active_engagement.is_empty() or not pending_aftermath.is_empty():return
	for template:Dictionary in army_templates:
		if bool(template.get("recruitment_requested",false)):queue_template_training(int(template.template_id),false)
func grouped_home_formations(force:Dictionary={})->Array[Dictionary]:
	var source:=home_army if force.is_empty() else force
	var groups:Dictionary={}
	for formation:Dictionary in source.get("formations",[]):
		var key:=str([formation.get("unit","levy"),formation.get("weapon","improvised"),formation.get("prototype",false)])
		if not groups.has(key):
			groups[key]={"unit":formation.get("unit","levy"),"weapon":formation.get("weapon","improvised"),"prototype":formation.get("prototype",false),"count":0,"authorized_count":0,"equipment":0,"equipment_required":0,"ammunition":0,"ammunition_required":0,"training":0.0,"personnel_condition":0.0,"cohorts":0,"lowest_condition":1.0,"highest_condition":0.0}
		var group:Dictionary=groups[key];var count:=int(formation.get("count",0))
		group.cohorts=int(group.cohorts)+1
		for field in ["count","authorized_count","equipment","equipment_required","ammunition","ammunition_required"]:group[field]=int(group[field])+int(formation.get(field,0))
		for field in ["training","personnel_condition"]:group[field]=float(group[field])+float(formation.get(field,0))*count
		group.lowest_condition=minf(float(group.lowest_condition),float(formation.get("personnel_condition",1)))
		group.highest_condition=maxf(float(group.highest_condition),float(formation.get("personnel_condition",1)))
	var result:Array[Dictionary]=[]
	for group:Dictionary in groups.values():
		for field in ["training","personnel_condition"]:group[field]=float(group[field])/maxi(1,int(group.count))
		result.append(group)
	return result

func _complete_ready_build_batches()->void:
	var batches:Dictionary={}
	for order:Dictionary in training_queue:
		if order.has("build_batch"):
			var id:=int(order.build_batch)
			batches[id]=bool(batches.get(id,true)) and float(order.progress_days)>=float(order.required_days)
	for id in batches:
		if not bool(batches[id]):continue
		for index in range(training_queue.size()-1,-1,-1):
			var order:Dictionary=training_queue[index]
			if int(order.get("build_batch",-1))==int(id):
				_complete_training(order);training_queue.remove_at(index)
