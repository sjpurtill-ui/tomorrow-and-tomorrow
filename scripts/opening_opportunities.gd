extends RefCounted
## The opening tree is exposed by accumulated cases, not by the calendar. Each
## value below is a bounded count of days on which the civilization actually
## encountered the problem while assigning people who could notice it.

const RULES:Dictionary={
	"seasonal_patterns":{"goal":18.0,"waiting":"repeated gathering observations across changing conditions"},
	"drainage":{"goal":6.0,"waiting":"wet occupied ground observed by settlement builders"},
	"wound_cleaning":{"goal":3.0,"waiting":"injuries treated where usable freshwater is available"},
	"herbal_classification":{"goal":8.0,"waiting":"recognized medicinal plants compared through gathering or care"},
	"tallies":{"goal":10.0,"waiting":"stored quantities repeatedly counted by logistics or administration"},
	"route_memory":{"goal":8.0,"waiting":"journey days or returned route observations"},
	"labor_rotations":{"goal":12.0,"waiting":"several simultaneous work obligations in a settled community"},
	"watch_rotation":{"goal":10.0,"waiting":"sustained guard duty, accelerated by real danger"},
}

static func empty_state()->Dictionary:
	return {"last_day":-1,"evidence":{}}

static func data()->Dictionary:
	var current:Variant=WorldSimulation.state.opening_opportunities
	if not current is Dictionary or not valid(current):
		WorldSimulation.state.opening_opportunities=empty_state()
	return WorldSimulation.state.opening_opportunities

static func advance(context:Dictionary)->void:
	var state:=data()
	var day:=int(floor(WorldSimulation.state.elapsed_days))
	if int(state.get("last_day",-1))==day:return
	state.last_day=day
	_add(state,"seasonal_patterns",1.0 if _workers("Food")>=1.0 and float(context.get("foraging",0.0))>=.25 else 0.0)
	var rain:=clampf(float(context.get("precipitation",context.get("rain",0.0))),0.0,1.0)
	_add(state,"drainage",clampf(rain,.25,1.0) if bool(context.get("settled",WorldSimulation.state.settlement_site_committed)) and _workers("Construction")>=1.0 and rain>=.10 else 0.0)
	var injuries:=_injuries()
	_add(state,"wound_cleaning",minf(1.0,injuries) if injuries>0.0 and float(context.get("freshwater",0.0))>=.5 else 0.0)
	_add(state,"herbal_classification",1.0 if _medicinal_access() and (_workers("Food")+_workers("Survey")>=1.0 or float(context.get("illness",0.0))>.0) else 0.0)
	_add(state,"tallies",1.0 if _stored_quantity()>=20.0 and _workers("Logistics")+_workers("Administration")>=1.0 else 0.0)
	_add(state,"route_memory",1.0 if bool(context.get("traveling",false)) or float(context.get("travel",0.0))>=.75 else 0.0)
	_add(state,"labor_rotations",1.0 if _competing_roles()>=3 and WorldSimulation.state.settlement_site_committed else 0.0)
	var guard_duty:=_workers("Defense")
	var danger:=maxf(0.0,float(context.get("danger",0.0)))
	_add(state,"watch_rotation",minf(1.5,.5+danger) if guard_duty>=2.0 else 0.0)

static func ready(id:String)->bool:
	if not RULES.has(id):return true
	if _outside_evidence(id):return true
	return progress(id)>=float(RULES[id].goal)

static func progress(id:String)->float:
	if not RULES.has(id):return 0.0
	return clampf(float(data().evidence.get(id,0.0)),0.0,float(RULES[id].goal))

static func remaining(id:String)->String:
	if not RULES.has(id) or ready(id):return ""
	var rule:Dictionary=RULES[id]
	return "%s (%.1f of %.1f qualifying days)" % [String(rule.waiting),progress(id),float(rule.goal)]

static func record(id:String,amount:float)->void:
	## Explicit evidence entry point for authored events and deterministic tests.
	if RULES.has(id) and is_finite(amount) and amount>0.0:_add(data(),id,amount)

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	var last_day:Variant=value.get("last_day",-1)
	if not (last_day is int or last_day is float) or not is_finite(float(last_day)) or floorf(float(last_day))!=float(last_day):return false
	var evidence:Variant=value.get("evidence",{})
	if not evidence is Dictionary:return false
	for id:Variant in evidence:
		if not id is String or not RULES.has(String(id)):return false
		var amount:Variant=evidence[id]
		if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)<0.0 or float(amount)>float(RULES[String(id)].goal):return false
	return true

static func _add(state:Dictionary,id:String,amount:float)->void:
	if amount<=0.0:return
	var evidence:Dictionary=state.evidence
	evidence[id]=minf(float(RULES[id].goal),float(evidence.get(id,0.0))+amount)
	state.evidence=evidence

static func _workers(role:String)->float:
	return maxf(0.0,WorldSimulation.state.effective_workers(role))

static func _injuries()->float:
	var total:=0.0
	for amount:Variant in WorldSimulation.state.civilian_injuries.values():total+=maxf(0.0,float(amount))
	var military:=WorldSimulation.system("MilitaryCampaign")
	if military!=null:
		total+=maxf(0.0,float(military.get("training_injury_pool")))
		var home:Variant=military.get("home_army")
		if home is Dictionary:total+=maxf(0.0,float(home.get("wounded_pool",0)))
	return total

static func _medicinal_access()->bool:
	if float(WorldSimulation.state.resource_stockpiles.get("Medicinal Plants",0.0))>0.0:return true
	for deposit:Variant in WorldSimulation.state.resource_deposits:
		if deposit is Dictionary and String(deposit.get("resource",""))=="Medicinal Plants" and String(deposit.get("stage","unknown")) in ["recognized","surveyed","accessible","developed"]:return true
	return false

static func _stored_quantity()->float:
	var total:=0.0
	for amount:Variant in WorldSimulation.state.resource_stockpiles.values():total+=maxf(0.0,float(amount))
	for amount:Variant in WorldSimulation.state.food_stocks.values():total+=maxf(0.0,float(amount))
	return total

static func _competing_roles()->int:
	var result:=0
	for role:String in WorldSimulation.state.POPULATION_ROLES:
		if _workers(role)>=1.0:result+=1
	return result

static func _outside_evidence(id:String)->bool:
	var exchange:Variant=WorldSimulation.state.society_exchange
	if not exchange is Dictionary:return false
	var evidence:Variant=exchange.get("evidence",{})
	var collections:Variant=exchange.get("collections",{})
	if not evidence is Dictionary or not collections is Dictionary:return false
	var collection_id:=String(evidence.get(id,""))
	if collection_id.is_empty():return false
	var item:Variant=collections.get(collection_id,{})
	return item is Dictionary and float(item.get("study",0.0))>=1.0 and int(item.get("returned_day",0))<=int(WorldSimulation.state.elapsed_days)
