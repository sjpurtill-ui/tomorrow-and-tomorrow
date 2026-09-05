class_name DecreeStatistics
extends RefCounted

# Model estimates are inputs to a bounded simulation, never claims about reality.
const METRICS := ["health", "cohesion", "knowledge", "security", "ecology", "legitimacy"]

static func context() -> Dictionary:
	var writable: Dictionary = {}
	for metric in METRICS:
		writable[metric] = {"current":float(GameState.simulation_metrics.get(metric,0.5)),"unit":"fraction, 0 to 1; 0.01 is one percentage point", "max_abs_delta":0.08}
	return {"population":GameState.population_total,"working_age":GameState.population_cohorts.get("working_age",0),"statistics":GameState.simulation_metrics.duplicate(true),"writable_direct_metrics":writable,"rule":"Propose immediate delta and uncertainty for relevant writable metrics, with a causal reason. Zero is valid. Engine scales estimates by implementation capacity and clamps final values. These are simulation assumptions, not measured causal facts. Population deaths are separate exact counted actions, never a metric delta. A counted worker action selects from the aggregate working-age pool; no named victim or offense is required. Do not ask for a name or invent a missing identity requirement. Food, water, labor, production and other read-only statistics change through their existing simulation systems. One-time actions have no standing-policy effects; other orders retain their catalog standing effects as well as the immediate estimates."}

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

static func receipt(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("population_deaths"):
		var deaths:=int(effects.population_deaths)
		parts.append("%d %s died; the population and death ledger were updated by that count." % [deaths,"person" if deaths==1 else "people"] if deaths>0 else "No one died; there was no population removal or death entry.")
	for metric in METRICS:
		if effects.has(metric+"_delta"):
			parts.append("%s %+.2f percentage points" % [metric.capitalize(),float(effects[metric+"_delta"])*100.0])
	return " ".join(parts)
