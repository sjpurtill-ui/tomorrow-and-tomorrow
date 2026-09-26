extends RefCounted
const Research600=preload("res://scripts/research_600_catalog.gd")
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
	"seed_selection":{"goal":2.0,"waiting":"two tended sowing cycles harvested from finite retained seed"},
	"animal_taming":{"goal":60.0,"waiting":"a suitable encountered herd population fed and handled beside the settlement"},
}

const SEED_MATURITY_DAYS:=90
const SEED_TENDING_DAYS:=70
const HERD_BIRTH_INTERVAL:=45

static func empty_state()->Dictionary:
	return {"last_day":-1,"evidence":{},"programs":{"seed":{"retained":0.0,"plots":[],"harvests":0},"herd":{"animals":0.0,"continuity_days":0,"last_birth_day":-1,"source_id":"","care_coverage":0.0,"unfed_days":0}}}

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
	_advance_seed_program(state,context,day)
	_advance_herd_program(state,context,day)

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
	var programs:Variant=value.get("programs",{})
	if not programs is Dictionary:return false
	var seed:Variant=programs.get("seed",{"retained":0.0,"plots":[],"harvests":0})
	var herd:Variant=programs.get("herd",{"animals":0.0,"continuity_days":0,"last_birth_day":-1,"source_id":"","care_coverage":0.0,"unfed_days":0})
	if not seed is Dictionary or not herd is Dictionary:return false
	if not _finite_range(seed.get("retained",0.0),0.0,1e9) or not seed.get("plots",[]) is Array or (seed.plots as Array).size()>2:return false
	if not _finite_range(seed.get("harvests",0),0.0,100000.0):return false
	for plot:Variant in seed.plots:
		if not plot is Dictionary or not _finite_range(plot.get("planted_day",-1),-1.0,1e12) or not _finite_range(plot.get("tended_days",0),0.0,SEED_MATURITY_DAYS) or not _finite_range(plot.get("seed",0.0),0.0,1e6):return false
	if not _finite_range(herd.get("animals",0.0),0.0,1e9) or not _finite_range(herd.get("continuity_days",0),0.0,1e12) or not _finite_range(herd.get("last_birth_day",-1),-1.0,1e12):return false
	if not _finite_range(herd.get("care_coverage",0.0),0.0,1.0) or not _finite_range(herd.get("unfed_days",0),0.0,1e12):return false
	return herd.get("source_id","") is String

static func practice_factor(id:String)->float:
	# Read-only and called per effect rebuild. Every writer keeps this record
	# valid and loads validate it, so skip data()'s full structural check.
	var current:Variant=WorldSimulation.state.opening_opportunities
	var programs:Dictionary=(current if current is Dictionary else data()).get("programs",{})
	if id=="seed_selection":
		var seed:Dictionary=programs.get("seed",{})
		return clampf(float(seed.get("retained",0.0))/_seed_target(),0.0,1.0)
	if id in ["animal_taming","pack_animals","domesticated_mounts","mounted_scouts"]:
		var herd:Dictionary=programs.get("herd",{})
		return clampf(float(herd.get("animals",0.0))/_herd_target(),0.0,1.0)*clampf(float(herd.get("care_coverage",0.0)),0.0,1.0)
	return 1.0

static func program_report()->Dictionary:
	return data().get("programs",{}).duplicate(true)

static func _programs(state:Dictionary)->Dictionary:
	if not state.has("programs") or not state.programs is Dictionary:state.programs={}
	if not state.programs.has("seed"):state.programs.seed={"retained":0.0,"plots":[],"harvests":0}
	if not state.programs.has("herd"):state.programs.herd={"animals":0.0,"continuity_days":0,"last_birth_day":-1,"source_id":"","care_coverage":0.0,"unfed_days":0}
	return state.programs

static func _advance_seed_program(state:Dictionary,context:Dictionary,day:int)->void:
	if not _opening_program_active(context) or "seasonal_patterns" not in WorldSimulation.state.known_discoveries or not _recognized_resource("Fertile Soil"):return
	var seed:Dictionary=_programs(state).seed
	var target:=_seed_target()
	var available:=maxf(0.0,float(WorldSimulation.state.food_stocks.get("Stored food",0.0)))
	var retained:=maxf(0.0,float(seed.get("retained",0.0)))
	var moved:=minf(minf(target-retained,available),maxf(.02,WorldSimulation.state.population_exact*.001))
	if moved>0.0:
		WorldSimulation.state.food_stocks["Stored food"]=available-moved
		retained+=moved
	seed.retained=retained
	if "seed_selection" in WorldSimulation.state.known_discoveries:return
	var plots:Array=seed.get("plots",[])
	if plots.is_empty():
		var sow:=maxf(.10,WorldSimulation.state.population_exact*.001)
		if retained>=sow:
			seed.retained=retained-sow
			plots.append({"planted_day":day,"tended_days":0,"seed":sow})
			seed.plots=plots
		return
	var plot:Dictionary=plots[0]
	plot.tended_days=minf(SEED_MATURITY_DAYS,float(plot.get("tended_days",0))+1.0)
	if day-int(plot.get("planted_day",day))<SEED_MATURITY_DAYS:return
	plots.remove_at(0);seed.plots=plots
	if float(plot.tended_days)<SEED_TENDING_DAYS:return
	seed.retained=minf(target*1.5,float(seed.retained)+float(plot.seed)*1.35)
	seed.harvests=int(seed.get("harvests",0))+1
	_add(state,"seed_selection",1.0)

static func _advance_herd_program(state:Dictionary,context:Dictionary,day:int)->void:
	var herd:Dictionary=_programs(state).herd
	herd.care_coverage=0.0
	if not _opening_program_active(context) or "seasonal_patterns" not in WorldSimulation.state.known_discoveries:
		_miss_herd_care(herd);return
	var animals:=maxf(0.0,float(herd.get("animals",0.0)))
	if animals<.5:
		var source:=_suitable_game_population()
		if source.is_empty():return
		var captured:=_withdraw_animals(source,4.0)
		if captured<2.0:return
		animals=captured;herd.animals=animals;herd.source_id=String(source.get("id","game_population"))
	var has_water:=float(context.get("freshwater",0.0))>=.5 or bool(WorldSimulation.state.water_metrics.get("source_accessible",false))
	if not has_water:
		_miss_herd_care(herd);return
	var feed_needed:=animals*.01
	var plants:=maxf(0.0,float(WorldSimulation.state.food_stocks.get("Fresh food",0.0)))
	var plant_feed:=minf(plants,feed_needed)
	WorldSimulation.state.food_stocks["Fresh food"]=plants-plant_feed
	var staples_needed:=feed_needed-plant_feed
	var staples:=maxf(0.0,float(WorldSimulation.state.food_stocks.get("Stored food",0.0)))
	if staples+plant_feed+.000001<feed_needed:
		_miss_herd_care(herd);return
	WorldSimulation.state.food_stocks["Stored food"]=staples-staples_needed
	herd.care_coverage=1.0;herd.unfed_days=0
	herd.continuity_days=int(herd.get("continuity_days",0))+1
	_add(state,"animal_taming",1.0)
	if day-int(herd.get("last_birth_day",-1))>=HERD_BIRTH_INTERVAL:
		herd.animals=minf(_herd_target()*1.5,animals+maxf(1.0,floorf(animals*.25)))
		herd.last_birth_day=day

static func _miss_herd_care(herd:Dictionary)->void:
	if float(herd.get("animals",0.0))<=0.0:return
	herd.unfed_days=int(herd.get("unfed_days",0))+1
	if int(herd.unfed_days)>3:herd.animals=maxf(0.0,float(herd.animals)*.98)

static func _opening_program_active(context:Dictionary)->bool:
	return WorldSimulation.state.settlement_site_committed and not bool(context.get("traveling",WorldSimulation.state.convoy_traveling)) and _workers("Food")>=2.0

static func _recognized_resource(resource:String)->bool:
	for deposit:Variant in WorldSimulation.state.resource_deposits:
		if deposit is Dictionary and String(deposit.get("resource",""))==resource and String(deposit.get("stage","unknown")) in ["recognized","surveyed","accessible","developed"]:return true
	# The settlement's own farmland or clay needs no mapped deposit to be known.
	if resource in Research600.HOME_SURFACE_RESOURCES:
		return Research600.home_surface_resources(WorldSimulation.state.player_settlements,WorldSimulation.food.current_environment_profile() if WorldSimulation.food!=null else {}).has(resource)
	return false

static func _suitable_game_population()->Dictionary:
	for deposit:Variant in WorldSimulation.state.resource_deposits:
		if not deposit is Dictionary or String(deposit.get("resource",""))!="Game" or String(deposit.get("stage","unknown")) not in ["recognized","surveyed","accessible","developed"]:continue
		if maxf(float(deposit.get("potential",0.0)),float(deposit.get("quality",0.0)))>=.55 and float(deposit.get("remaining",0.0))>=2.0:return deposit
	return {}

static func _withdraw_animals(deposit:Dictionary,requested:float)->float:
	var amount:=minf(requested,maxf(0.0,float(deposit.get("remaining",0.0))))
	if amount<=0.0:return 0.0
	if deposit.has("world_key"):
		amount=preload("res://scripts/civilization_resources.gd").withdraw(deposit,amount)
		preload("res://scripts/civilization_resources.gd").available(deposit)
	else:deposit.remaining=float(deposit.get("remaining",0.0))-amount
	return amount

static func _seed_target()->float:
	return maxf(.5,WorldSimulation.state.population_exact*.01)

static func _herd_target()->float:
	return maxf(4.0,WorldSimulation.state.population_exact*.02)

static func _finite_range(value:Variant,minimum:float,maximum:float)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum

static func _add(state:Dictionary,id:String,amount:float)->void:
	if amount<=0.0:return
	var evidence:Dictionary=state.evidence
	evidence[id]=minf(float(RULES[id].goal),float(evidence.get(id,0.0))+amount*WorldSimulation.span)
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
