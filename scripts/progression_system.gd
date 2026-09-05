extends Node

signal milestone_unlocked(event:Dictionary)

const Catalog=preload("res://scripts/civilization_progression_catalog.gd")
const FrontierCatalog=preload("res://scripts/discovery_frontier_catalog.gd")
const MAX_TRANSITION_LOG:=192
const MAX_UNLOCK_LOG:=MAX_TRANSITION_LOG

# Broad-scale effects remain small. The real advantages come from adopted
# discoveries; a scale transition only represents the ability to coordinate
# those practices across a larger civilization.
const EFFECTS_PER_TIER:Dictionary={
	"demography":{"conception_support":0.012,"maternal_safety":0.015,"neonatal_survival":0.015},
	"nutrition":{"food_output":0.025,"food_storage":0.018,"nutrition_quality":0.012},
	"health":{"health_protection":0.018,"disease_exposure":-0.018,"injury_risk":-0.012},
	"labor":{"labor_efficiency":0.018,"task_coordination":0.015,"fatigue":-0.008},
	"knowledge":{"knowledge_rate":0.025,"knowledge_preservation":0.018,"adoption_rate":0.012},
	"production":{"tool_quality":0.015,"craft_output":0.025,"extraction_yield":0.020},
	"infrastructure":{"construction_rate":0.025,"housing_output":0.020,"disaster_resilience":0.015},
	"logistics":{"haul_capacity":0.022,"route_speed":0.020,"trade_capacity":0.018},
	"ecology":{"ecology_recovery":0.018,"ecological_pressure":-0.015,"pollution":-0.012},
	"institutions":{"state_capacity":0.022,"legitimacy":0.012,"institutional_rigidity":-0.006},
	"security":{"warfare_readiness":0.020,"security_efficiency":0.020,"disaster_resilience":0.008},
	"culture":{"cohesion":0.015,"adoption_rate":0.012,"knowledge_preservation":0.008}
}

var domain_levels:Dictionary={}
var unlock_log:Array[Dictionary]=[]
var effect_totals:Dictionary={}
var last_world_seed:=-2147483648
var last_evaluated_day:=-1
var cached_player_profile:Dictionary={}
var cached_profile_day=-1
var cached_known_count=-1


func _ready()->void:
	set_process(true)
	reset_for_new_world()


func _process(_delta:float)->void:
	if GameState.world_seed!=last_world_seed: reset_for_new_world()
	var day:=int(floor(GameState.elapsed_days))
	if day!=last_evaluated_day: process_day(day)


func reset_for_new_world()->void:
	last_world_seed=GameState.world_seed
	last_evaluated_day=-1
	cached_profile_day=-1
	cached_known_count=-1
	cached_player_profile.clear()
	domain_levels.clear()
	unlock_log.clear()
	for domain in Catalog.DOMAINS: domain_levels[domain]=0
	_rebuild_effects()


func process_day(day:int=-1)->Array[Dictionary]:
	if GameState.world_seed!=last_world_seed: reset_for_new_world()
	var evaluated_day:=int(floor(GameState.elapsed_days)) if day<0 else day
	var known_count:=GameState.known_discoveries.size()
	if evaluated_day==last_evaluated_day and known_count==cached_known_count: return []
	last_evaluated_day=evaluated_day
	# Full profile scans are fixed by the discovery catalog, never population.
	# Re-evaluate monthly, or immediately when a discovery is established.
	if cached_profile_day<0 or floori(float(evaluated_day)/30.0)!=floori(float(cached_profile_day)/30.0) or known_count!=cached_known_count:
		cached_player_profile=_build_player_discovery_profile()
		cached_profile_day=evaluated_day
		cached_known_count=known_count
	var context:=player_context()
	var events:Array[Dictionary]=[]
	for _pass in Catalog.ERA_NAMES.size():
		var changed:=false
		for domain in Catalog.DOMAINS:
			var tier:=domain_tier(domain)
			if tier>=Catalog.ERA_NAMES.size()-1: continue
			var next_definition:=Catalog.node(domain,tier+1)
			var status:=_scale_status(next_definition,context,domain_levels)
			if not (status.blockers as Array).is_empty(): continue
			domain_levels[domain]=tier+1
			var event:Dictionary={
				"day":evaluated_day,"type":"capability_scale","domain":domain,
				"tier":tier+1,"era":String(next_definition.era),
				"name":String(next_definition.name),"outcome":String(next_definition.outcome)
			}
			unlock_log.push_front(event)
			if unlock_log.size()>MAX_TRANSITION_LOG: unlock_log.resize(MAX_TRANSITION_LOG)
			events.append(event)
			milestone_unlocked.emit(event)
			changed=true
		if not changed: break
	_rebuild_effects()
	return events


func domains()->Array[String]:
	return Catalog.DOMAINS.duplicate()


func domain_tier(domain:String)->int:
	return clampi(int(domain_levels.get(domain,0)),0,Catalog.ERA_NAMES.size()-1)


func domain_summary(domain:String)->Dictionary:
	if domain not in Catalog.DOMAINS: return {}
	var tier:=domain_tier(domain)
	var current:=Catalog.node(domain,tier)
	var profile:Dictionary=cached_player_profile.get(domain,{})
	if profile.is_empty():
		cached_player_profile=_build_player_discovery_profile()
		profile=cached_player_profile.get(domain,{})
	var frontier:=DiscoverySystem.frontier_snapshot(domain)
	return {
		"domain":domain,"tier":tier,"era":String(current.era),"name":String(current.name),
		"outcome":String(current.outcome),"purpose":String(current.purpose),
		"known_count":int(profile.get("count",0)),"maturity":int(profile.get("maturity",0)),
		"breadth":int(profile.get("breadth",0)),"lens_count":int(profile.get("lens_count",0)),
		"adoption":float(profile.get("adoption",0.0)),"frontier":frontier,
		"complete":tier>=Catalog.ERA_NAMES.size()-1
	}


# Broad scale status remains available to simulation diagnostics, but future
# bands are not included in player snapshots or enumerated in the interface.
func node_status(domain:String,tier:int)->Dictionary:
	var definition:=Catalog.node(domain,tier)
	if definition.is_empty(): return {}
	return _scale_status(definition,player_context(),domain_levels)


func tree_snapshot()->Dictionary:
	var domain_records:Array[Dictionary]=[]
	for domain in Catalog.DOMAINS: domain_records.append({"id":domain,"summary":domain_summary(domain)})
	var context:=player_context()
	return {
		"population":GameState.population_exact,"population_uncapped":true,
		"world_reach":float(context.reach),"domains":domain_records,
		"known_discoveries":GameState.known_discoveries.size(),
		"active_inquiries":GameState.active_investigations.size(),
		"catalog_hidden":true,"log":unlock_log.duplicate(true)
	}


func unlocked_count()->int:
	return GameState.known_discoveries.size()


func effect(effect_id:String)->float:
	return float(effect_totals.get(effect_id,0.0))


func domain_factor(domain:String,per_tier:=0.035)->float:
	return 1.0+float(domain_tier(domain))*per_tier


func player_context()->Dictionary:
	if cached_player_profile.is_empty(): cached_player_profile=_build_player_discovery_profile()
	var settlement_count:=GameState.player_settlements.size()
	if settlement_count==0 and GameState.settlement_site_committed: settlement_count=1
	var reach:=0.0
	var reach_snapshot:Dictionary={}
	var civilization_system:=get_node_or_null("/root/CivilizationSystem")
	if civilization_system!=null and civilization_system.has_method("progression_reach_snapshot"):
		reach_snapshot=civilization_system.progression_reach_snapshot()
		reach=float(reach_snapshot.get("combined",0.0))
	return {
		"population":maxf(1.0,GameState.population_exact),"settlements":settlement_count,
		"capacities":GameState.society_capacities.duplicate(true),
		"discovery_profile":cached_player_profile.duplicate(true),
		"reach":clampf(reach,0.0,1.0),"reach_snapshot":reach_snapshot
	}


func _build_player_discovery_profile()->Dictionary:
	var profile:Dictionary={}
	var subcategories:Dictionary={}
	var lenses:Dictionary={}
	var adoption_sums:Dictionary={}
	for domain in Catalog.DOMAINS:
		profile[domain]={"count":0,"maturity":0,"breadth":0,"lens_count":0,"adoption":0.0}
		subcategories[domain]={}
		lenses[domain]={}
		adoption_sums[domain]=0.0
	for discovery_id_variant in GameState.known_discoveries:
		var discovery_id:=String(discovery_id_variant)
		var definition:Dictionary=DiscoverySystem.discovery_definition(discovery_id)
		var domain:=String(definition.get("dynamic",""))
		if domain not in Catalog.DOMAINS: continue
		var record:Dictionary=profile[domain]
		record["count"]=int(record.count)+1
		record["maturity"]=maxi(int(record.maturity),int(definition.get("maturity",1)))
		var subcategory:=String(definition.get("subcategory","General practice"))
		var lens:=String(definition.get("lens","Lived practice"))
		(subcategories[domain] as Dictionary)[subcategory]=true
		(lenses[domain] as Dictionary)[lens]=true
		adoption_sums[domain]=float(adoption_sums[domain])+clampf(float(GameState.discovery_adoption.get(discovery_id,0.025)),0.0,1.0)
		profile[domain]=record
	for domain in Catalog.DOMAINS:
		var record:Dictionary=profile[domain]
		record["breadth"]=(subcategories[domain] as Dictionary).size()
		record["lens_count"]=(lenses[domain] as Dictionary).size()
		record["adoption"]=float(adoption_sums[domain])/maxf(1.0,float(record.count))
		record["subcategories"]=(subcategories[domain] as Dictionary).keys()
		record["lenses"]=(lenses[domain] as Dictionary).keys()
		profile[domain]=record
	return profile


func advance_rival(civ:Dictionary)->Dictionary:
	var result:=_advance_rival_discoveries(civ.duplicate(true))
	var tiers:Dictionary=result.get("progression_tiers",{})
	for domain in Catalog.DOMAINS:
		if not tiers.has(domain): tiers[domain]=0
	var population:=maxf(1.0,float(result.get("population",1.0)))
	var settlement_count:=maxi(1,int(result.get("settlement_count",1)))
	if float(result.get("production",0.0))>=0.16 and float(result.get("institutions",0.0))>=0.16:
		settlement_count=maxi(settlement_count,mini(256,ceili(sqrt(population/250.0))))
	result["settlement_count"]=settlement_count
	var context:=_rival_context(result)
	for _pass in Catalog.ERA_NAMES.size():
		var changed:=false
		for domain in Catalog.DOMAINS:
			var tier:=clampi(int(tiers.get(domain,0)),0,Catalog.ERA_NAMES.size()-1)
			if tier>=Catalog.ERA_NAMES.size()-1: continue
			var status:=_scale_status(Catalog.node(domain,tier+1),context,tiers)
			if (status.blockers as Array).is_empty(): tiers[domain]=tier+1; changed=true
		if not changed: break
	result["progression_tiers"]=tiers
	return result


func initial_rival_discovery_profile(civ_id:String,founding_focus:String,strategy:String)->Dictionary:
	var domain_records:Dictionary={}
	var momentum:Dictionary={}
	var emphasis:=_rival_emphasis({"founding_focus":founding_focus,"strategy":strategy,"allocations":{}})
	var seed_value:=GameState.world_seed^hash(civ_id)^0x27d4eb2d
	for domain in Catalog.DOMAINS:
		var subcategory_list:Array=FrontierCatalog.SUBCATEGORIES[domain]
		var specialty:=String(subcategory_list[posmod(hash("%s:%s:subcategory" % [seed_value,domain]),subcategory_list.size())])
		var lens:=String(FrontierCatalog.LENSES[posmod(hash("%s:%s:lens" % [seed_value,domain]),FrontierCatalog.LENSES.size())].name)
		domain_records[domain]={"count":0,"maturity":0,"breadth":0,"lens_count":0,"adoption":0.0,"specialty":specialty,"tradition":lens}
		momentum[domain]=0.0
	return {"seed":seed_value,"cycle":0,"domains":domain_records,"momentum":momentum,"emphasis":emphasis,"research_workforce":0.0,"research_capacity":0.0,"research_slots":2}


func _advance_rival_discoveries(civ:Dictionary)->Dictionary:
	var profile:Dictionary=civ.get("discovery_profile",{})
	if profile.is_empty(): profile=initial_rival_discovery_profile(String(civ.get("id","rival")),String(civ.get("founding_focus","provision")),String(civ.get("strategy","sustenance")))
	var cycle:=int(profile.get("cycle",0))+1
	profile["cycle"]=cycle
	var domains_profile:Dictionary=profile.get("domains",{})
	var momentum:Dictionary=profile.get("momentum",{})
	var emphasis:=_rival_emphasis(civ)
	profile["emphasis"]=emphasis
	var allocations:Dictionary=civ.get("allocations",{})
	var population:=maxf(1.0,float(civ.get("population",1.0)))
	var research_share:=clampf(float(allocations.get("knowledge",0.1)),0.0,1.0)
	var research_workforce:=population*research_share*0.58
	var workforce_scale:=1.0+log(maxf(1.0,research_workforce))/log(10.0)*0.62
	var food_support:=clampf(float(civ.get("food_capacity",population))/population,0.25,1.25)
	var physical_support:=0.46+food_support*0.16+clampf(float(civ.get("production",0.1)),0.0,1.0)*0.15+clampf(float(civ.get("logistics",0.1)),0.0,1.0)*0.10+clampf(float(civ.get("institutions",0.1)),0.0,1.0)*0.13
	var points:=(0.18+clampf(float(civ.get("knowledge",0.1)),0.0,1.0)*0.74+research_share*1.35+clampf(float(civ.get("adaptability",0.5)),0.0,1.0)*0.22)*workforce_scale*physical_support
	var research_slots:=clampi(2+floori(log(maxf(1.0,research_workforce))/log(10.0)/2.0),2,Catalog.DOMAINS.size())
	profile["research_workforce"]=research_workforce
	profile["research_capacity"]=points
	profile["research_slots"]=research_slots
	var seed_value:=int(profile.get("seed",GameState.world_seed))
	for slot in research_slots:
		var domain:=_weighted_domain(seed_value,cycle,slot,emphasis)
		momentum[domain]=float(momentum.get(domain,0.0))+points*(1.0 if slot==0 else 0.62)
		if float(momentum[domain])<1.0: continue
		momentum[domain]=float(momentum[domain])-1.0
		var record:Dictionary=domains_profile.get(domain,{})
		var count:=mini(384,int(record.get("count",0))+1)
		record["count"]=count
		record["maturity"]=mini(12,1+floori(float(count)/12.0))
		record["breadth"]=mini(4,1+floori(float(count)/8.0))
		record["lens_count"]=mini(8,1+floori(float(count)/18.0))
		var capacity:=float((_rival_capacities(civ) as Dictionary).get(domain,0.0))
		record["adoption"]=clampf(float(record.get("adoption",0.0))*0.96+(float(civ.get("knowledge",0.1))*0.55+capacity*0.45)*0.04,0.02,1.0)
		domains_profile[domain]=record
	profile["domains"]=domains_profile
	profile["momentum"]=momentum
	civ["discovery_profile"]=profile
	return civ


func _rival_emphasis(civ:Dictionary)->Dictionary:
	var weights:Dictionary={}
	for domain in Catalog.DOMAINS: weights[domain]=0.35
	var allocation_links:Dictionary={
		"sustenance":["nutrition","ecology","health","demography"],"growth":["demography","labor","infrastructure","nutrition"],
		"knowledge":["knowledge","culture","health","institutions"],"production":["production","infrastructure","logistics","labor"],
		"military":["security","logistics","institutions","production"],"diplomacy":["culture","institutions","logistics","knowledge"]
	}
	var allocations:Dictionary=civ.get("allocations",{})
	for allocation_id in allocation_links:
		var strength:=float(allocations.get(allocation_id,0.10))*4.0
		var linked:Array=allocation_links[allocation_id]
		for index in linked.size(): weights[String(linked[index])]=float(weights[linked[index]])+strength*(1.0-float(index)*0.16)
	var focus_links:Dictionary={
		"provision":["nutrition","ecology","logistics"],"generations":["demography","health","culture"],
		"inquiry":["knowledge","culture","institutions"],"industry":["production","labor","infrastructure"],
		"defense":["security","logistics","institutions"],"exchange":["logistics","culture","institutions"]
	}
	var focus:=String(civ.get("founding_focus","provision"))
	var focus_domains:Array=focus_links.get(focus,[])
	for index in focus_domains.size():
		var domain:=String(focus_domains[index])
		weights[domain]=float(weights[domain])+1.30-float(index)*0.22
	return weights


func _weighted_domain(seed_value:int,cycle:int,slot:int,weights:Dictionary)->String:
	var total:=0.0
	for domain in Catalog.DOMAINS: total+=maxf(0.01,float(weights.get(domain,0.01)))
	var roll:=float(posmod(hash("%s:%s:%s" % [seed_value,cycle,slot]),1_000_000))/1_000_000.0*total
	for domain in Catalog.DOMAINS:
		roll-=maxf(0.01,float(weights.get(domain,0.01)))
		if roll<=0.0: return domain
	return Catalog.DOMAINS[-1]


func rival_effect(civ:Dictionary,effect_id:String)->float:
	var tiers:Dictionary=civ.get("progression_tiers",{})
	var total:=0.0
	for domain in EFFECTS_PER_TIER:
		var effects:Dictionary=EFFECTS_PER_TIER[domain]
		if effects.has(effect_id): total+=float(effects[effect_id])*float(tiers.get(domain,0))
	return clampf(total,-0.45,0.80)


func _rival_context(civ:Dictionary)->Dictionary:
	var profile:Dictionary=civ.get("discovery_profile",{})
	return {
		"population":maxf(1.0,float(civ.get("population",1.0))),"settlements":int(civ.get("settlement_count",1)),
		"capacities":_rival_capacities(civ),"discovery_profile":profile.get("domains",{}),
		"reach":clampf(float(civ.get("world_reach",0.0)),0.0,1.0)
	}


func _rival_capacities(civ:Dictionary)->Dictionary:
	var population:=maxf(1.0,float(civ.get("population",1.0)))
	var food_ratio:=clampf(float(civ.get("food_capacity",population))/population,0.0,1.25)
	var health:=clampf(float(civ.get("health",0.5)),0.0,1.0)
	var cohesion:=clampf(float(civ.get("cohesion",0.5)),0.0,1.0)
	var knowledge:=clampf(float(civ.get("knowledge",0.1)),0.0,1.0)
	var production:=clampf(float(civ.get("production",0.1)),0.0,1.0)
	var logistics:=clampf(float(civ.get("logistics",0.1)),0.0,1.0)
	var institutions:=clampf(float(civ.get("institutions",0.1)),0.0,1.0)
	var ecology:=clampf(float(civ.get("ecology",0.7)),0.0,1.0)
	var security:=clampf(float(civ.get("military_readiness",0.3)),0.0,1.0)
	return {
		"demography":health*0.45+food_ratio*0.35+cohesion*0.20,
		"nutrition":food_ratio*0.70+clampf(float(civ.get("food_days",0.0))/90.0,0.0,1.0)*0.30,
		"health":health,"labor":health*0.40+cohesion*0.30+production*0.30,"knowledge":knowledge,"production":production,
		"infrastructure":production*0.38+logistics*0.27+institutions*0.20+minf(0.15,float(civ.get("territory",0.0))/8.0),
		"logistics":logistics,"ecology":ecology,"institutions":institutions,"security":security,"culture":cohesion*0.62+institutions*0.38
	}


func _scale_status(definition:Dictionary,context:Dictionary,levels:Dictionary)->Dictionary:
	var status:=definition.duplicate(true)
	var domain:=String(definition.domain)
	var tier:=int(definition.tier)
	var is_established:=int(levels.get(domain,0))>=tier
	var blockers:Array[String]=[]
	if tier>=2:
		for support in Catalog.SUPPORT_DOMAINS[domain]:
			if int(levels.get(String(support),0))<tier-1: blockers.append("Supporting %s capability has not reached comparable scale" % String(support))
	var population:=float(context.population)
	var settlements:=int(context.settlements)
	var capacity:=float((context.capacities as Dictionary).get(domain,0.0))
	var profile:Dictionary=(context.discovery_profile as Dictionary).get(domain,{})
	var count:=int(profile.get("count",0))
	var maturity:=int(profile.get("maturity",0))
	var breadth:=int(profile.get("breadth",0))
	var lens_count:=int(profile.get("lens_count",0))
	var adoption:=float(profile.get("adoption",0.0))
	var reach:=float(context.reach)
	if population<Catalog.POPULATION_FLOORS[tier]: blockers.append("Population scale is not yet sufficient")
	if settlements<Catalog.SETTLEMENT_FLOORS[tier]: blockers.append("Settlement network is not yet sufficient")
	if capacity<Catalog.CAPACITY_FLOORS[tier]: blockers.append("Real %s capacity remains too low" % domain)
	if count<Catalog.DISCOVERY_COUNT_FLOORS[tier]: blockers.append("Too little established %s knowledge" % domain)
	if maturity<Catalog.MATURITY_FLOORS[tier]: blockers.append("No investigative tradition has matured far enough")
	if breadth<Catalog.BREADTH_FLOORS[tier]: blockers.append("Knowledge is too narrow across lived conditions")
	if lens_count<Catalog.LENS_FLOORS[tier]: blockers.append("Too few independent investigative traditions")
	if adoption<Catalog.ADOPTION_FLOORS[tier]: blockers.append("Established findings are not broadly adopted")
	if reach<Catalog.REACH_FLOORS[tier]: blockers.append("Observed and connected world reach remains too limited")
	var ratios:Array[float]=[1.0]
	if Catalog.POPULATION_FLOORS[tier]>1.0: ratios.append(population/Catalog.POPULATION_FLOORS[tier])
	if Catalog.SETTLEMENT_FLOORS[tier]>0: ratios.append(float(settlements)/Catalog.SETTLEMENT_FLOORS[tier])
	if Catalog.CAPACITY_FLOORS[tier]>0.0: ratios.append(capacity/Catalog.CAPACITY_FLOORS[tier])
	if Catalog.DISCOVERY_COUNT_FLOORS[tier]>0: ratios.append(float(count)/Catalog.DISCOVERY_COUNT_FLOORS[tier])
	if Catalog.MATURITY_FLOORS[tier]>0: ratios.append(float(maturity)/Catalog.MATURITY_FLOORS[tier])
	if Catalog.BREADTH_FLOORS[tier]>0: ratios.append(float(breadth)/Catalog.BREADTH_FLOORS[tier])
	if Catalog.LENS_FLOORS[tier]>0: ratios.append(float(lens_count)/Catalog.LENS_FLOORS[tier])
	if Catalog.ADOPTION_FLOORS[tier]>0.0: ratios.append(adoption/Catalog.ADOPTION_FLOORS[tier])
	if Catalog.REACH_FLOORS[tier]>0.0: ratios.append(reach/Catalog.REACH_FLOORS[tier])
	var progress:=1.0
	for ratio in ratios: progress=minf(progress,clampf(ratio,0.0,1.0))
	status["unlocked"]=is_established
	status["blockers"]=[] if is_established else blockers
	status["progress"]=1.0 if is_established else progress
	status["current"]={"population":population,"settlements":settlements,"capacity":capacity,"discoveries":count,"maturity":maturity,"breadth":breadth,"traditions":lens_count,"adoption":adoption,"reach":reach}
	return status


func _rebuild_effects()->void:
	effect_totals.clear()
	for domain in EFFECTS_PER_TIER:
		var tier:=domain_tier(String(domain))
		for effect_id in (EFFECTS_PER_TIER[domain] as Dictionary):
			effect_totals[effect_id]=float(effect_totals.get(effect_id,0.0))+float(EFFECTS_PER_TIER[domain][effect_id])*float(tier)
	for effect_id in effect_totals: effect_totals[effect_id]=clampf(float(effect_totals[effect_id]),-0.45,0.80)


func validate_state()->Array[String]:
	var errors:Array[String]=[]
	if domain_levels.size()!=Catalog.DOMAINS.size(): errors.append("Progression must contain exactly twelve aggregate domains.")
	for domain in Catalog.DOMAINS:
		var level:=int(domain_levels.get(domain,-1))
		if level<0 or level>=Catalog.ERA_NAMES.size(): errors.append("%s has an invalid capability scale." % domain)
	if unlock_log.size()>MAX_TRANSITION_LOG: errors.append("Capability transition log exceeds its fixed bound.")
	return errors


func export_state()->Dictionary:
	return {"world_seed":last_world_seed,"last_evaluated_day":last_evaluated_day,"domain_levels":domain_levels.duplicate(true),"unlock_log":unlock_log.duplicate(true)}


func import_state(payload:Dictionary)->Dictionary:
	var previous:=export_state()
	last_world_seed=int(payload.get("world_seed",GameState.world_seed))
	last_evaluated_day=int(payload.get("last_evaluated_day",-1))
	if payload.has("domain_levels"):
		domain_levels=(payload.get("domain_levels",{}) as Dictionary).duplicate(true)
	else:
		domain_levels={}
		var old:Dictionary=payload.get("unlocked_by_domain",{})
		for domain in Catalog.DOMAINS: domain_levels[domain]=clampi((old.get(domain,[]) as Array).size()-1,0,8)
	unlock_log.assign((payload.get("unlock_log",[]) as Array).duplicate(true))
	var errors:=validate_state()
	if not errors.is_empty():
		last_world_seed=int(previous.world_seed)
		last_evaluated_day=int(previous.last_evaluated_day)
		domain_levels=previous.domain_levels
		unlock_log.assign(previous.unlock_log)
		return {"error":"Invalid progression state.","details":errors}
	cached_profile_day=-1
	cached_known_count=-1
	_rebuild_effects()
	return {"ok":true}


func _compact_number(value:float)->String:
	if value>=1_000_000_000_000.0: return "%.1fT" % (value/1_000_000_000_000.0)
	if value>=1_000_000_000.0: return "%.1fB" % (value/1_000_000_000.0)
	if value>=1_000_000.0: return "%.1fM" % (value/1_000_000.0)
	if value>=10_000.0: return "%.1fK" % (value/1_000.0)
	return "%d" % roundi(value)
