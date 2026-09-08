extends RefCounted
## Standing service policy; UI orders never advance the training clock.
const POLICIES:Dictionary={
	"suspended":{"label":"Suspend","share":0.0,"target":0.0,"intake":0.0,"description":"Stop instruction and exercises. Keep forces available and conserve supplies."},
	"maintain":{"label":"Maintain","share":0.10,"target":0.55,"intake":0.65,"description":"Small training rotations. Preserve basic proficiency with low recurring expense."},
	"regular":{"label":"Regular","share":0.25,"target":0.70,"intake":1.0,"description":"Sustained preparation. Staff rotate less-prepared personnel through instruction."},
	"intensive":{"label":"Intensive","share":0.50,"target":0.85,"intake":1.25,"description":"A major investment in proficiency. More personnel, stores and equipment committed to training."}
}
const EXERCISE_TIME_MULTIPLIER:=6.0
const EXERCISE_COST_MULTIPLIER:=4.0
const RESERVE_DAYS:=7.0
var host:Node
var data:Dictionary={}
func _init(campaign:Node)->void:host=campaign;reset()
func reset()->void:
	data={"policies":{"army":"regular","navy":"regular","air":"regular"},"army_last_day":-1,"status":{},"food_spent":{},"materials_spent":{}}
func load_state(saved:Dictionary)->void:
	reset()
	for service in ["army","navy","air"]:
		var choice:=String(saved.get("policies",{}).get(service,"regular"))
		if POLICIES.has(choice):data.policies[service]=choice
	for key in ["army_last_day","food_spent","materials_spent"]:
		if saved.has(key):data[key]=saved[key].duplicate(true) if saved[key] is Dictionary else saved[key]
func policy(service:String,owner:String="player")->Dictionary:
	var id:=String(data.policies.get(service,"regular"))
	if owner!="player":
		var index:=CivilizationSystem._civilization_index(owner)
		if index>=0:id=rival_policy(CivilizationSystem.civilizations[index])
	var result:Dictionary=POLICIES.get(id,POLICIES.regular).duplicate(true);result.id=id
	return result
static func rival_policy(civ:Dictionary)->String:
	if float(civ.get("food_days",0))<RESERVE_DAYS:return "suspended"
	if bool(civ.get("player_relation",{}).get("at_war",false)):return "maintain"
	return "intensive" if String(civ.get("strategy","")) in ["expansion","fortification"] else "regular"
func set_policy(service:String,id:String)->Dictionary:
	if service not in ["army","navy","air"] or not POLICIES.has(id):return {"error":"Choose a service and training policy."}
	data.policies[service]=id
	if service=="army" and id=="suspended" and not host.training_program.is_empty():
		host.training_program.paused_reason="Training suspended by national policy."
	host.army_changed.emit(host.home_army.duplicate(true))
	return {"ok":true,"message":"%s training: %s. Staff handle selection, rotations and supplies automatically." % [service.capitalize(),POLICIES[id].label]}
static func initial_days(days:float)->float:return maxf(45.0,days*3.0)
static func service_days(days:float)->float:return maxf(90.0,days*3.0)
func spendable_food()->float:
	return maxf(0.0,FoodSystem.total_stored()-maxf(1.0,GameState.population_exact)*0.9*RESERVE_DAYS)
func snapshot(service:String)->Dictionary:
	var result:=policy(service)
	result.status=String(data.status.get(service,"Staff will review eligible units on the next day."))
	result.food_spent=float(data.food_spent.get(service,0.0))
	result.materials_spent=float(data.materials_spent.get(service,0.0))
	result.active=host.training_program.duplicate(true) if service=="army" else {}
	if service in ["navy","air"]:result.merge(service_overview(service),true)
	return result
func service_overview(service:String)->Dictionary:
	var op=host.joint_operations
	var forces:Array[Dictionary]=[]
	var day:=int(op.state.last_day)
	for record:Dictionary in op.state.forces:
		if record.owner!="player" or record.domain!=service:continue
		forces.append(record);day=maxi(day,int(record.get("staff_training_day",-1)))
	var overview:Dictionary={"groups":{"training":0,"assigned":0,"target":0,"paused":0},"forces":forces.size(),"personnel":0,"attending":0,"report_day":day,"pause_reasons":{}}
	for record:Dictionary in forces:
		var report:=service_force_report(record,day)
		overview.groups[report.group]+=1
		overview.personnel+=op.crew(record);overview.attending+=int(report.attending)
		if report.group=="paused":overview.pause_reasons[report.reason]=int(overview.pause_reasons.get(report.reason,0))+1
	var unit_name:="task forces" if service=="navy" else "air wings"
	if forces.is_empty():
		overview.status="No %s commissioned. Staff will apply your policy when crews enter service." % unit_name
	else:
		overview.status="%d %s · %d crew · %d attending training." % [forces.size(),unit_name,overview.personnel,overview.attending]
		var reasons:Array=overview.pause_reasons.keys();reasons.sort()
		var lines:Array[String]=[]
		for reason in reasons:lines.append("%d · %s" % [overview.pause_reasons[reason],reason])
		overview.pause_details="\n".join(lines)
		if not lines.is_empty():overview.status+="\n"+"\n".join(lines.slice(0,3))
		if lines.size()>3:overview.status+="\nMore reasons in the Paused indicator."
	return overview
func service_force_report(record:Dictionary,day:int)->Dictionary:
	var op=host.joint_operations
	var result:Dictionary={"group":"paused","attending":0,"reason":"Awaiting the next staff review"}
	var origin:Dictionary=op.base(int(record.base_id))
	if not op.base_ready(origin) or not op.base_owned(origin,String(record.owner)):
		result.reason="Home base unavailable";return result
	if op.crew(record)<=0:result.reason="Replacement equipment and crew needed";return result
	var fresh:=day>=0 and int(record.get("staff_training_day",-1))==day
	if bool(record.get("repairing",false)) or float(record.condition)<maxf(.8,float(record.get("repair_threshold",.6))):
		result.reason=String(record.get("training_status","Repairs before training")) if fresh else "Repairs before training"
		if result.reason=="":result.reason="Repairs before training"
		return result
	if fresh and int(record.get("training_attending",0))>0:
		result.group="training";result.attending=mini(op.crew(record),int(record.training_attending));return result
	var at_base:bool=op.force_position(record).distance_to(op.point(origin))<2 and record.get("route",[]).is_empty()
	if not at_base or op.logistics.busy(int(record.id)) or String(record.mission)!="hold":
		result.group="assigned";return result
	var current:=policy(String(record.domain))
	if current.id!="suspended" and float(record.training)>=1 and float(record.get("proficiency",.45))>=float(current.target):
		result.group="target";return result
	if current.id=="suspended":result.reason="Training suspended by policy"
	elif fresh and String(record.get("training_status",""))!="":result.reason=String(record.training_status)
	return result
func army_rotation()->Dictionary:
	var current:=policy("army")
	var entries:Array[Dictionary]=[]
	var total:=0
	for force:Dictionary in host._exercise_forces():
		for formation:Dictionary in force.get("formations",[]):
			formation["training_attending"]=0
			total+=maxi(0,int(formation.get("count",0)))
			if float(formation.get("training",0.0))>=float(current.target) or float(formation.get("personnel_condition",1.0))<.70:continue
			if int(formation.get("equipment",0))<float(formation.get("equipment_required",formation.get("count",0)))*.5:continue
			entries.append({"formation":formation,"force":force})
	entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.formation.get("training",0))<float(b.formation.get("training",0)))
	var places:=floori(total*float(current.share))
	if total>0 and float(current.share)>0:places=maxi(1,places)
	var attending:=0
	for entry:Dictionary in entries:
		var count:=mini(places,maxi(0,int(entry.formation.get("count",0))))
		entry.formation.training_attending=count;attending+=count;places-=count
	return {"attending":attending,"total":total,"entries":entries}
func prepare_army_day()->bool:
	var current:=policy("army")
	for force:Dictionary in [host.home_army]+host.field_armies:
		for formation:Dictionary in force.get("formations",[]):formation.training_attending=0
	var reason:=""
	if current.id=="suspended":reason="Training suspended."
	elif not host.active_engagement.is_empty() or not host.active_threat.is_empty() or not host.pending_aftermath.is_empty():reason="Staff released training rotations for the military emergency."
	elif spendable_food()<=0:reason="Training paused to protect seven days of civilian food."
	var rotation:=army_rotation() if reason=="" else {"attending":0,"total":0}
	if reason=="" and int(rotation.attending)==0:reason="No training rotation: units meet the target, need equipment, or are recovering."
	if reason!="":
		data.status.army=reason
		if not host.training_program.is_empty():host.training_program.paused_reason=reason;host.training_program.last_efficiency=0.0;host.training_program.participants=0
		return false
	if host.training_program.is_empty():
		var choice:="camp_drill"
		if float(host.home_army.get("supply_level",1))<.8:choice="route_rehearsal"
		elif current.id=="intensive" and not host._training_program_gate("field_exercise",true).has("error"):choice="field_exercise"
		elif host.training_program_cycles%4==1:choice="rally_drill"
		elif host.training_program_cycles%4==2:choice="reconnaissance_drill"
		elif host.training_program_cycles%4==3:choice="signal_drill"
		var started:Dictionary=host.start_training_program(choice)
		if started.has("error"):data.status.army=started.error;return false
	data.status.army="%d of %d soldiers in staff-managed training rotations." % [rotation.attending,rotation.total]
	return true
func record_food(service:String,amount:float)->void:data.food_spent[service]=float(data.food_spent.get(service,0.0))+amount
func report_service_training(record:Dictionary,message:String)->void:
	record.training_status=message
	if record.owner=="player":data.status[String(record.domain)]=message
func pause_service_training(record:Dictionary,day:int,message:String)->void:
	record.training_attending=0;record.staff_training_day=day
	report_service_training(record,message)
func service_training(record:Dictionary,origin:Dictionary,day:int)->bool:
	var op=host.joint_operations
	var initial:=float(record.get("training",0))<1.0
	if int(record.get("staff_training_day",-1))==day:return initial
	record["training_attending"]=0;record["training_status"]=""
	record.staff_training_day=day
	var service:=String(record.domain)
	var current:=policy(service,String(record.owner))
	var at_base:bool=op.force_position(record).distance_to(op.point(origin))<2 and record.get("route",[]).is_empty()
	# A repair spell ends at the same readiness threshold as normal operations.
	# Suspending instruction does not suspend maintenance or return travel.
	if float(record.condition)>=.98:record["repairing"]=false
	var needs_repairs:=bool(record.get("repairing",false)) or float(record.condition)<maxf(.8,float(record.get("repair_threshold",.6)))
	if needs_repairs:record["repairing"]=true
	var reason:=""
	if needs_repairs:reason="Staff prioritizing repairs before training"
	elif current.id=="suspended":reason="Staff training suspended by policy"
	elif not at_base:reason="Training waits for return to home base"
	elif not initial and float(record.get("proficiency",.45))>=float(current.target):
		report_service_training(record,"Training target met");return false
	elif op.logistics.busy(int(record.id)):reason="Crew committed to transport duty"
	if reason!="":
		report_service_training(record,reason)
		if initial:
			record.status=reason
			if at_base and needs_repairs and not op.logistics.busy(int(record.id)):
				var repair:Dictionary=op.repair_at_base(record,origin)
				if float(record.condition)>=.98:record.repairing=false
				record.status=String(repair.get("error",repair.get("message",reason)))
				report_service_training(record,String(record.status))
			if not at_base and not record.get("route",[]).is_empty() and op.pay_fuel(record):op.geography.travel(record,op.speed(record))
		return initial
	var capacity:=float(origin.get("capacity",0))
	var stationed:=0
	for other:Dictionary in op.state.forces:
		if other.base_id==record.base_id:stationed+=op.hardware(other)
	# New crews are already withheld from service for full-time instruction.
	# The rotation share applies to qualified crews; intensity governs intake pace.
	var share:=float(current.intake if initial else current.share)*minf(1.0,capacity/maxf(1.0,stationed))
	var costs:Dictionary={}
	var duration:=90.0
	for type_id:String in record.units:
		var unit:Dictionary=op.C.UNITS[type_id]
		duration=maxf(duration,service_days(float(unit.training_days)))
		for material:String in unit.materials:costs[material]=float(costs.get(material,0))+float(unit.materials[material])*int(record.units[type_id])*.00075*share
	var food:float=op.crew(record)*.18*share
	var fuel_exact:=float(op.fuel_cost(record))*.5*share+float(record.get("training_fuel_fraction",0))
	var fuel:=floori(fuel_exact)
	var paid:=false
	var shortages:Array[String]=[]
	if record.owner=="player":
		paid=bool(SettlementModel.with_city_resources(String(origin.city_id),func():
			if spendable_food()<food:shortages.append("extra rations above the civilian reserve")
			if int(host.military_consumables.get("fuel",0))<fuel:shortages.append("%d fuel" % fuel)
			for material:String in costs:
				if float(GameState.resource_stockpiles.get(material,0))<float(costs[material]):shortages.append(ResourceSystem.display_name(material)+" at "+String(origin.name))
			if not shortages.is_empty():return false
			for material:String in costs:GameState.resource_stockpiles[material]=float(GameState.resource_stockpiles.get(material,0))-float(costs[material])
			host.military_consumables.fuel=int(host.military_consumables.get("fuel",0))-fuel
			FoodSystem.issue_for_obligation(food,"military_training",service.capitalize()+" staff exercises",1.0,op.crew(record))
			return true))
	else:
		var bill:float=fuel*.25
		for amount in costs.values():bill+=float(amount)
		var index:=CivilizationSystem._civilization_index(String(record.owner))
		if index>=0:
			var civ:Dictionary=CivilizationSystem.civilizations[index]
			var food_days:=food/maxf(1,float(civ.get("population",1))*.9)
			if float(civ.get("food_days",0))-food_days>=RESERVE_DAYS:
				paid=op.rival.spend(String(record.owner),bill)
				if paid:civ.food_days=float(civ.food_days)-food_days
	if not paid:
		report_service_training(record,"Staff waiting for "+", ".join(shortages) if not shortages.is_empty() else "Training paused: food reserve, fuel or training materials unavailable")
		if initial:record.status=record.training_status
		return initial
	record.training_fuel_fraction=fuel_exact-fuel
	record.training_attending=ceili(op.crew(record)*minf(1,share))
	if record.owner=="player":
		record_food(service,food)
		for amount in costs.values():data.materials_spent[service]=float(data.materials_spent.get(service,0))+float(amount)
	if initial:
		record.training=minf(1.0,float(record.training)+share/duration)
		record.proficiency=maxf(float(record.get("proficiency",0)),float(record.training)*.45)
		record.status="Staff instruction · %d%% · %d days at current policy" % [roundi(float(record.training)*100),ceili((1-float(record.training))*duration/maxf(.001,share))]
		report_service_training(record,String(record.status))
	else:
		record.proficiency=minf(float(current.target),float(record.get("proficiency",.45))+.065/84.0*share)
		record.condition=maxf(0,float(record.condition)-.0003*share)
		report_service_training(record,"Staff exercises · %d%% of crews rotating" % roundi(share*100))
	return initial
