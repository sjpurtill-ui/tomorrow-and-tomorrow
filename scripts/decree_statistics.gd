class_name DecreeStatistics
extends RefCounted

# Model estimates are inputs to a bounded simulation, never claims about reality.
const METRICS := ["health", "cohesion", "knowledge", "security", "ecology", "legitimacy"]

## Alterable engine parameters for custom directives. Each entry names the
## ConsequenceEngine policy channel it drives and the largest effect a single
## order may have on it. A proposal uses a normalized strength in [-1, 1]; the
## engine multiplies it by "max" (and "sign"), then by feasibility and
## implementation. "engine" documents the simulation input that changes.
const PARAMETERS := {
	"fertility":{"channel":"conception_support","max":0.20,"label":"fertility","engine":"conception-rate factor in GameState reproduction (conceptions now, births about nine months later)"},
	"infant_mortality":{"channel":"neonatal_survival","sign":-1.0,"max":0.30,"label":"newborn deaths","engine":"newborn death rate in GameState.process_reproduction_day"},
	"disease":{"channel":"disease_risk","max":0.20,"label":"sickness","engine":"Illness mortality component and health target in ConsequenceEngine"},
	"health":{"channel":"health_target","max":0.06,"label":"health","engine":"population health target"},
	"cohesion":{"channel":"cohesion_target","max":0.07,"label":"cohesion","engine":"cohesion target (feeds labor, conception, security, legitimacy)"},
	"legitimacy":{"channel":"legitimacy_target","max":0.07,"label":"legitimacy","engine":"legitimacy target (feeds compliance with every later order)"},
	"security":{"channel":"security_target","max":0.07,"label":"security","engine":"security target (insecurity deaths, enforcement capacity)"},
	"violence":{"channel":"violence","max":0.15,"label":"violence","engine":"Insecurity mortality plus lower security and cohesion targets"},
	"knowledge":{"channel":"knowledge_gain","max":0.30,"label":"research pace","engine":"multiplier on daily knowledge gain (discovery pace)"},
	"labor":{"channel":"labor_multiplier","max":0.10,"label":"labor","engine":"labor efficiency multiplier (all production)"},
	"food_use":{"channel":"food_demand","max":0.12,"label":"food use","engine":"daily food demand multiplier"},
	"food_yield":{"channel":"food_yield","max":0.10,"label":"food yield","engine":"food production practice multiplier"},
	"materials":{"channel":"material_target","max":0.07,"label":"materials","engine":"material capacity target"},
	"logistics":{"channel":"logistics_target","max":0.07,"label":"hauling","engine":"logistics target"},
	"construction":{"channel":"construction_rate","max":0.25,"label":"building pace","engine":"construction work rate in SettlementConstruction"},
	"water":{"channel":"water_collection","max":0.30,"label":"water","engine":"organized water collection multiplier"},
	"ecology":{"channel":"ecology_delta","max":0.0004,"label":"land health","engine":"daily ecology change"},
	"migration":{"channel":"migration_pull","max":0.05,"label":"migration","engine":"annual share of population arriving (+) or leaving (-)"},
	"resentment":{"channel":"@resistance","max":0.45,"label":"resentment","engine":"directive resistance pressure lowering cohesion and legitimacy targets"},
}
const MAX_CUSTOM_EFFECTS := 8
## Every name an offline/recorded effect may carry: the six immediate metrics
## plus every alterable parameter. The interaction database keeps effects on any
## of these (InteractionContext.writable_metrics reads this list).
const OFFLINE_METRICS := ["health","cohesion","knowledge","security","ecology","legitimacy","fertility","infant_mortality","disease","violence","labor","food_use","food_yield","materials","logistics","construction","water","migration","resentment"]
## A recorded delta of this size on a metric equals full strength (1.0) on the
## same-named parameter. Other parameters use the record clamp (0.08).
const METRIC_EQUIVALENT := {"health":0.06,"cohesion":0.07,"legitimacy":0.07,"security":0.07,"knowledge":0.01,"ecology":0.02}

static func strength_from_delta(parameter:String,delta:float)->float:
	return clampf(delta/float(METRIC_EQUIVALENT.get(parameter,0.08)),-1.0,1.0)

static func delta_from_strength(parameter:String,strength:float)->float:
	return clampf(strength*float(METRIC_EQUIVALENT.get(parameter,0.08)),-0.08,0.08)

static func effects_from_offline(raw:Variant,default_days:float=180.0)->Array[Dictionary]:
	## Offline/recorded effects ({metric,delta,uncertainty,duration_days,reason})
	## become custom-directive effects on the same-named parameters.
	var converted:Array=[]
	if raw is Array:
		for item_variant in raw:
			if not item_variant is Dictionary: continue
			var item:Dictionary=item_variant
			var parameter:=String(item.get("metric",item.get("parameter","")))
			if not PARAMETERS.has(parameter) or not _number(item.get("delta")): continue
			converted.append({"parameter":parameter,"strength":strength_from_delta(parameter,float(item.delta)),
				"uncertainty":clampf(_number_or(item.get("uncertainty"),0.02)/float(METRIC_EQUIVALENT.get(parameter,0.08)),0.0,1.0),
				"days":_number_or(item.get("duration_days"),default_days),"delay_days":_number_or(item.get("delay_days"),0.0),
				"reason":String(item.get("reason","as ordered"))})
	return validate_custom_effects(converted)

static func offline_from_effects(effects:Array)->Array:
	## The reverse, for recording a live custom plan in the interaction database.
	var result:Array=[]
	for effect_variant in effects:
		if not effect_variant is Dictionary: continue
		var effect:Dictionary=effect_variant
		var parameter:=String(effect.get("parameter",""))
		if not PARAMETERS.has(parameter): continue
		result.append({"metric":parameter,"delta":delta_from_strength(parameter,float(effect.get("strength",0.0))),"uncertainty":clampf(float(effect.get("uncertainty",0.2))*float(METRIC_EQUIVALENT.get(parameter,0.08)),0.0,0.08),"duration_days":float(effect.get("days",180.0)),"reason":String(effect.get("reason",""))})
	return result

static func context() -> Dictionary:
	var writable: Dictionary = {}
	for metric in METRICS:
		writable[metric] = {"current":float(WorldSimulation.state.simulation_metrics.get(metric,0.5)),"unit":"fraction, 0 to 1; 0.01 is one percentage point", "max_abs_delta":0.08}
	return {"population":WorldSimulation.state.population_total,"working_age":WorldSimulation.state.population_cohorts.get("working_age",0),"statistics":_scalar_statistics(),"writable_direct_metrics":writable,"rule":"Propose immediate delta and uncertainty for relevant writable metrics, with a causal reason. Zero is valid. Engine scales estimates by implementation capacity and clamps final values. These are simulation assumptions, not measured causal facts. Population deaths are separate exact counted actions, never a metric delta. A counted worker action selects from the aggregate working-age pool; no named victim or offense is required. Do not ask for a name or invent a missing identity requirement. Food, water, labor, production and other read-only statistics change through their existing simulation systems. One-time actions have no standing-policy effects; other orders retain their catalog standing effects as well as the immediate estimates."}

static func _scalar_statistics()->Dictionary:
	# Nested forecasts and breakdowns only inflate the prompt.
	var result:Dictionary={}
	for key in WorldSimulation.state.simulation_metrics:
		var value:Variant=WorldSimulation.state.simulation_metrics[key]
		if value is float or value is int: result[key]=snappedf(float(value),0.0001)
		if result.size()>=48: break
	return result

static func parameter_contract() -> Dictionary:
	## Compact table for the model: parameter -> the engine input it drives.
	var table:Dictionary={}
	for parameter in PARAMETERS:
		table[parameter]=String((PARAMETERS[parameter] as Dictionary).get("engine",""))
	return table

static func validate(raw: Variant) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	if not raw is Array: return result
	for item in raw:
		if not item is Dictionary: continue
		var metric := String(item.get("metric",""))
		if metric not in METRICS or seen.has(metric): continue
		if not (item.get("delta") is float or item.get("delta") is int): continue
		if not (item.get("uncertainty") is float or item.get("uncertainty") is int): continue
		var delta := float(item.delta)
		var uncertainty := float(item.uncertainty)
		var reason := String(item.get("reason","")).strip_edges().substr(0,240)
		if not is_finite(delta) or not is_finite(uncertainty) or absf(delta)>0.08 or uncertainty<0.0 or uncertainty>0.08 or reason.is_empty(): continue
		seen[metric]=true
		result.append({"metric":metric,"delta":delta,"uncertainty":uncertainty,"reason":reason})
	return result

static func _number(value:Variant)->bool:
	return (value is float or value is int) and is_finite(float(value))

static func _number_or(value:Variant,fallback:float)->float:
	return float(value) if _number(value) else fallback

static func validate_custom_effects(raw:Variant)->Array[Dictionary]:
	## Normalized custom effects: parameter, strength [-1,1], uncertainty [0,1],
	## days [7,730], delay_days [0,3650], reason. Unknown parameters, duplicates,
	## non-finite values and missing reasons are dropped; values are clamped.
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	if not raw is Array: return result
	for item_variant in raw:
		if result.size()>=MAX_CUSTOM_EFFECTS: break
		if not item_variant is Dictionary: continue
		var item:Dictionary=item_variant
		var parameter:=String(item.get("parameter",""))
		if not PARAMETERS.has(parameter) or seen.has(parameter): continue
		if not _number(item.get("strength")): continue
		var reason:=String(item.get("reason","")).strip_edges().substr(0,200)
		if reason.is_empty(): continue
		var strength:=clampf(float(item.strength),-1.0,1.0)
		if absf(strength)<0.01: continue
		seen[parameter]=true
		result.append({
			"parameter":parameter,"strength":strength,
			"uncertainty":clampf(_number_or(item.get("uncertainty"),0.2),0.0,1.0),
			"days":clampf(_number_or(item.get("days"),180.0),7.0,730.0),
			"delay_days":clampf(_number_or(item.get("delay_days"),0.0),0.0,3650.0),
			"reason":reason,
		})
	return result

static func channel_value(parameter:String,strength:float)->float:
	var spec:Dictionary=PARAMETERS.get(parameter,{})
	if spec.is_empty(): return 0.0
	return clampf(strength,-1.0,1.0)*float(spec.get("max",0.0))*float(spec.get("sign",1.0))

static func label(parameter:String)->String:
	return String((PARAMETERS.get(parameter,{}) as Dictionary).get("label",parameter.replace("_"," ")))

static func _points(value:float)->String:
	return "%+.1f pts" % (value*100.0)

static func receipt(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("population_deaths"):
		var deaths:=int(effects.population_deaths)
		parts.append("%d %s died; the population and death ledger were updated by that count." % [deaths,"person" if deaths==1 else "people"] if deaths>0 else "No one died; there was no population removal or death entry.")
	for metric in METRICS:
		if effects.has(metric+"_delta") and absf(float(effects[metric+"_delta"]))>=0.0005:
			parts.append("%s %s" % [metric,_points(float(effects[metric+"_delta"]))])
	return " · ".join(parts)

static func effect_text(effect:Dictionary)->String:
	## "fertility +0.041" style; newborn deaths are stated as up/down.
	var parameter:=String(effect.get("parameter",""))
	var strength:=float(effect.get("strength",0.0))
	var value:=float(effect.get("value",channel_value(parameter,strength)))
	var text:=""
	match parameter:
		"resentment": text="resentment +%.2f" % absf(value) if value>=0.0 else "resentment -%.2f" % absf(value)
		"ecology": text="land health %+.5f/day" % value
		"infant_mortality": text="newborn deaths %s" % ("up" if strength>0.0 else "down")
		"disease": text="sickness %s" % ("up" if strength>0.0 else "down")
		"violence": text="violence %s" % ("up" if strength>0.0 else "down")
		"migration": text="%s" % ("arrivals up" if strength>0.0 else "departures up")
		_: text="%s %+.3f" % [label(parameter),value]
	var start:=int(effect.get("delay_days",0))
	if start>0: text+=" from day %d" % start
	return text

static func custom_receipt(realized:Array,direct_effects:Dictionary,costs:Dictionary,days:float)->String:
	## One compact numbers line for a custom directive: planned channel changes
	## (after feasibility and implementation), immediate shifts and real costs.
	## Unforeseen side effects are not listed here; they surface when they happen.
	var parts:Array[String]=[]
	for effect_variant in realized:
		var effect:Dictionary=effect_variant
		if bool(effect.get("side_effect",false)): continue
		if absf(float(effect.get("strength",0.0)))<0.005: continue
		parts.append(effect_text(effect))
	for metric in METRICS:
		if direct_effects.has(metric+"_delta") and absf(float(direct_effects[metric+"_delta"]))>=0.0005:
			parts.append("%s now %s" % [metric,_points(float(direct_effects[metric+"_delta"]))])
	if int(direct_effects.get("population_deaths",0))>0: parts.append("%d dead" % int(direct_effects.population_deaths))
	if float(costs.get("food_paid",0.0))>0.05: parts.append("%.0f food spent" % float(costs.food_paid))
	if float(costs.get("materials_paid",0.0))>0.05: parts.append("%.1f materials spent" % float(costs.materials_paid))
	parts.append("%d days" % roundi(days))
	return " · ".join(parts)
