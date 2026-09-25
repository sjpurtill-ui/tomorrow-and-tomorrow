class_name CivilizationIndicators
extends RefCounted
## One authoritative translation from simulation state into the civilization's
## player-facing health, output and science indicators.

const ECONOMIC_ROLES:Array[String]=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]

static func infant_mortality_per_1000(state:Node=GameState,discovery:Node=DiscoverySystem)->float:
	var metrics:Dictionary=state.simulation_metrics
	var context:Dictionary={
		"health":state.population_health,
		"food_security":state.food_security,
		"housing_ratio":float(metrics.get("housing_ratio",0.5)),
		"cohesion":float(metrics.get("cohesion",0.58)),
		"traveling":bool(metrics.get("traveling",false)),
		"neonatal_survival":discovery.effect("neonatal_survival"),
	}
	# Deaths in the whole first year per 1,000 live births: newborn deaths at
	# delivery conditions, then the age-0 life-table hazard for the rest of the
	# year. Both carry the early-care factors the daily simulation uses.
	var care:Dictionary=state.early_care
	var risk:float=state._pregnancy_risk_multiplier(context)*clampf(float(care.get("pregnancy_risk",1.0)),0.5,2.5)
	var neonatal:=clampf((0.018+(risk-1.0)*0.025)*(1.0-clampf(float(context.neonatal_survival),0.0,0.60))*clampf(preload("res://scripts/early_life_conditions.gd").neonatal_factor(care),0.5,4.0),0.004,0.18)
	var conditions:float=state._mortality_condition_factor()
	var later:=clampf(state._baseline_mortality_hazard_at_age(0)*conditions*preload("res://scripts/early_life_conditions.gd").age_multiplier(care,0,conditions),0.0,0.9)
	return (neonatal+(1.0-neonatal)*later)*1000.0

static func health(state:Node=GameState,discovery:Node=DiscoverySystem)->Dictionary:
	return {"life_expectancy":state.projected_life_expectancy(),"infant_mortality_per_1000":infant_mortality_per_1000(state,discovery)}

static func economy(state:Node=GameState)->Dictionary:
	var effective:=0.0
	var assigned:=0.0
	for role:String in ECONOMIC_ROLES:
		assigned+=maxf(0.0,float(state.population_allocations.get(role,0.0)))
		effective+=maxf(0.0,state.effective_workers(role))
	var productivity:=clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.0,1.5)
	var output:=effective*productivity
	return {"gdp":output,"gdp_per_capita":output/maxf(1.0,float(state.population_total)),"productivity":productivity,"assigned_workers":assigned,"effective_workers":effective}

static func education_index(state:Node=GameState)->float:
	var knowledge:Dictionary=state.society_subcategories.get("knowledge",{})
	if knowledge.is_empty():return clampf(state.combined_intelligence,0.01,1.0)
	var preservation:=float(knowledge.get("Preserved knowledge",state.combined_intelligence))
	var communication:=float(knowledge.get("Communication",state.combined_intelligence))
	return clampf(preservation*0.58+communication*0.42,0.01,1.0)

static func science(state:Node=GameState)->Dictionary:
	var minds:=maxf(0.0,state.effective_workers("Knowledge"))
	var education:=education_index(state)
	return {"capacity":minds*education,"minds":minds,"education":education}
