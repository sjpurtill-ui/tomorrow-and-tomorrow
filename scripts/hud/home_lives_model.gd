extends RefCounted
## Home's factual reader. No allocation, clock, RNG roll or order is invoked.
## Ordinary snapshots read existing receipts; only an explicit comparison runs
## WorkforcePreview's detached calculators. Town readings never become realm facts.

const Preview = preload("res://scripts/hud/workforce_preview.gd")
const Manual = preload("res://scripts/manual_work.gd")
const Indicators = preload("res://scripts/civilization_indicators.gd")
const Care = preload("res://scripts/food_care.gd")
const EarlyCare = preload("res://scripts/early_life_conditions.gd")
const Fabric = preload("res://scripts/built_fabric.gd")
const Culture = preload("res://scripts/hud/culture_model.gd")
const Explainer = preload("res://scripts/effect_explainer.gd")
const History = preload("res://scripts/strategic_history.gd")
const Defense = preload("res://scripts/home_defense.gd")
const Combat = preload("res://scripts/civilization_combat.gd")
const Research = preload("res://scripts/research_600_catalog.gd")
const POINT_EFFECTS = ["cohesion", "legitimacy", "institutions", "security", "health", "carrying", "trade"]
static var _comparison_draft: Dictionary = {}
static var _comparison_result: Dictionary = {}
static var _comparison_key := ""

static func snapshot(settlement_id: String = "") -> Dictionary:
	if WorldSimulation.advancing or WorldSimulation.settlements._local_population_scope:
		return {"ok": false, "reason": "Wait for the current settlement reading to finish."}
	if not WorldSimulation.direction.initialized or WorldSimulation.direction.seed_value != WorldSimulation.state.world_seed:
		return {"ok": false, "reason": "The new world's condition readings are not available yet."}
	# Existing presentation helpers may lazily seed older-save defaults. Give
	# just those containers private copies, then restore their exact references.
	# This is not the expensive simulation capture/evaluation used by previews.
	var state = WorldSimulation.state
	var saved: Dictionary = {}
	for field in ["player_settlements", "fabric_realm", "built_fabric", "early_care", "early_care_blend", "society_exchange", "population_cohorts", "pregnancy_cohorts", "population_total", "population_exact", "border_forts", "simulation_events", "city_form"]:
		var value: Variant = state.get(field)
		saved[field] = value
		if value is Dictionary or value is Array: state.set(field, value.duplicate(true))
	var memory: Dictionary = WorldSimulation.direction.cultural_memory
	WorldSimulation.direction.cultural_memory = memory.duplicate(true)
	var defense: Dictionary = WorldSimulation.military.settlement_defense
	WorldSimulation.military.settlement_defense = defense.duplicate(true)
	var national := WorldSimulation.settlements._national_population_in_scope
	var fraction := WorldSimulation.settlements._national_civilian_workforce_fraction
	var out := _snapshot(settlement_id)
	for field: String in saved: state.set(field, saved[field])
	WorldSimulation.direction.cultural_memory = memory
	WorldSimulation.military.settlement_defense = defense
	WorldSimulation.settlements._national_population_in_scope = national
	WorldSimulation.settlements._national_civilian_workforce_fraction = fraction
	return out

static func _snapshot(settlement_id: String) -> Dictionary:
	var state = WorldSimulation.state
	var realm_population := int(state.population_total)
	var record: Dictionary = WorldSimulation.settlements.settlement_record(settlement_id)
	if record.is_empty():
		for city: Dictionary in state.player_settlements:
			if bool(city.get("primary", false)): record = city; break
	var id := String(record.get("id", ""))
	var primary := record.is_empty() or bool(record.get("primary", false))
	var national_reading := {"research": _research(), "culture": _culture(), "regard": _regard()}
	var guard: Dictionary = Combat.home_defenders() if record.is_empty() else Combat.guard_of(record)
	var watch: Dictionary = Defense.reading() if primary else {"known": false, "status": "local", "blockers": [], "reason": "Home fortification plans belong to the founding settlement."}
	watch["standing"] = int(guard.get("trained", 0)) + int(guard.get("watch", 0))
	watch["mobilisable"] = int(guard.get("rise", 0))
	watch["known"] = true
	var result: Dictionary = WorldSimulation.settlements.with_city_resources(id, func() -> Dictionary:
		return WorldSimulation.settlements.with_local_population(func() -> Dictionary: return _local(id, realm_population, primary)))
	result["scope"] = {"id": id, "name": String(record.get("name", state.settlement_name)), "population": result.population.current,
		"national_population": realm_population, "primary": primary, "label": "This settlement", "civilization_label": "Across our civilization"}
	result.foundations["watch"] = watch
	result.merge(national_reading)
	result["ok"] = true
	result["day"] = int(state.elapsed_days)
	return result

static func _local(id: String, realm_population: int, primary: bool) -> Dictionary:
	var state = WorldSimulation.state
	var metrics: Dictionary = state.simulation_metrics
	var water: Dictionary = state.water_metrics
	var fabric := Fabric.report()
	var care: Dictionary = state.care_profile() if WorldSimulation.discovery.initialized else state.early_care
	var healthy := bool(WorldSimulation.discovery.initialized)
	var infant_risk := Indicators.infant_mortality_per_1000(state, WorldSimulation.discovery) if healthy else -10.0
	var capacity := maxi(0, int(state.housing_capacity))
	var people := int(state.population_total)
	var conditions := {
		"water": {"known": water.has("intake_ratio") and float(water.get("required_today", 0)) > 0, "intake_ratio": float(water.get("intake_ratio", -1)),
			"collected": float(water.get("collected_today", -1)), "required": float(water.get("required_today", -1)),
			"stock": float(state.resource_stockpiles.get("Freshwater", water.get("stored", 0))), "days": float(water.get("days", -1)), "period": "Latest measured day"},
		"food": _food(),
		"care": {"known": not care.is_empty(), "current": Care.care_cover_of(state), "target": Care.care_target_of(state),
			"workers": Care.keepers_of(state), "worker_unit": "effective worker-equivalents", "assigned": float(state.population_allocations.get("Administration", 0)), "settle_days": Care.CARE_SETTLE_DAYS, "practices": EarlyCare.explanation(care)},
		"housing": {"capacity": capacity, "population": people, "spare": maxi(0, capacity - people),
			"coverage": minf(1.0, float(capacity) / maxf(1.0, people)), "quality": float(fabric.quality),
			"illness_factor": 1.0 - Fabric.HOME_ILLNESS * float(fabric.quality), "upkeep": float(fabric.kept.get("homes", 1.0))},
		"infant_risk": {"known": healthy, "per_100": infant_risk / 10.0,
			"period": "Before the first birthday", "note": "Projected risk under current conditions, not recorded deaths."},
		"life_expectancy": -1.0, "life_expectancy_note": "No town-specific long-term hardship estimate is recorded."}
	return {"population": _population(id, realm_population, primary), "conditions": conditions,
		"foundations": {"known": true, "service_coverage": float(fabric.cover), "road_quality": float(fabric.roads),
			"craft": float(fabric.craft), "craft_max": Fabric.CRAFT_MAX, "road_kind": Fabric.ROAD_WORDS[int(fabric.road_kind)],
			"making_multiplier": 1.0 + Fabric.WORKSHOP_MAKING * Fabric.works_cover("workshops"),
			"stored_rot_multiplier": 1.0 - Fabric.GRANARY_ROT * Fabric.works_cover("granaries"),
			"haul_multiplier": 1.0 + Fabric.ROAD_HAUL * float(fabric.roads)}}

static func _food() -> Dictionary:
	var state = WorldSimulation.state
	var m: Dictionary = state.simulation_metrics
	var stock := 0.0
	for amount: Variant in state.food_stocks.values(): stock += maxf(0.0, float(amount))
	var required := float(m.get("food_consumption", -1))
	return {"known": m.has_all(["food_production", "food_consumption", "food_eaten", "food_spoilage", "food_net"]),
		"production": float(m.get("food_production", -1)), "required": required, "eaten": float(m.get("food_eaten", -1)),
		"spoilage": float(m.get("food_spoilage", -1)), "net": float(m.get("food_net", -1)), "stock": stock,
		"stored_days": stock / required if required > 0 else -1.0, "intake_ratio": float(m.get("food_intake_ratio", -1)),
		"unit": "rations", "period": "Latest recorded daily flow", "reserve_note": "Current reserves divided by daily need; not a starvation countdown."}

static func _population(id: String, _realm_population: int, _primary: bool) -> Dictionary:
	var state = WorldSimulation.state
	var day := int(state.elapsed_days)
	var start_day := int(day / 365) * 365
	var trend := History.points(state.strategic_history, id if not id.is_empty() else "civilization")
	var out := {"current": int(state.population_total), "year_start_known": false, "year_start": 0, "year_delta": 0,
		"year_start_day": start_day, "trend": trend, "vitals": _vitals()}
	for point: Dictionary in trend:
		if int(point.get("day", -1)) == start_day and point.has("population"):
			out.year_start_known = true; out.year_start = int(point.population); break
	# Chronicle's annual accumulator may have started midway through an older
	# save and has no baseline date. It cannot prove a start-of-year population.
	if out.year_start_known: out.year_delta = int(out.current) - int(out.year_start)
	return out

static func _vitals() -> Dictionary:
	var state = WorldSimulation.state
	var today := int(state.elapsed_days)
	var first := maxi(0, today - 364)
	var tracked := int(state.vital_statistics_tracking_start_day)
	var known: bool = tracked >= 0 and not state.vital_statistics_history.is_empty()
	if tracked >= 0: first = maxi(first, tracked)
	var births := 0; var deaths := 0
	for row: Dictionary in state.vital_statistics_history:
		if int(row.get("day", -1)) < first or int(row.get("day", -1)) > today: continue
		births += int(row.get("births", 0)); deaths += int(row.get("deaths", 0))
	return {"known": known, "births": births, "deaths": deaths, "natural_change": births - deaths,
		"from_day": first, "to_day": today, "tracked_days": today - first + 1 if known else 0,
		"requested_days": 365, "label": "Recorded births and deaths", "note": "Natural change is births minus deaths; it does not measure migration or explain the whole population change."}

static func _research() -> Dictionary:
	var state = WorldSimulation.state
	var out := {"known": bool(WorldSimulation.discovery.initialized), "active_count": 0, "known_count": state.known_discoveries.size(), "adopted_count": 0, "count_label": "Methods with recorded adoption", "current": {}, "empty": "No active question is recorded."}
	if not out.known: out.empty = "Research readings are not available yet."; return out
	for id: String in state.known_discoveries:
		if WorldSimulation.discovery.adoption(id) > 0.0: out.adopted_count += 1
	var ids: Array[String] = []
	for value: Variant in state.active_investigations.values():
		var id := String(value)
		if not id.is_empty() and not ids.has(id): ids.append(id)
	out.active_count = ids.size()
	ids.sort_custom(func(a: String, b: String) -> bool: return float(state.discovery_progress.get(a, 0)) > float(state.discovery_progress.get(b, 0)))
	if ids.is_empty(): return out
	var id := ids[0]
	var definition: Dictionary = WorldSimulation.discovery.discovery_definition(id)
	if definition.is_empty(): return out
	# EffectExplainer has a frame cache; preserve it so this town reading cannot
	# leak its temporary scope into another screen's explanation in this frame.
	var cache_key: Array = Explainer._cache_key
	var cache: Dictionary = Explainer._cache
	Explainer.invalidate()
	var effects := Explainer.discovery_rows(id, false)
	Explainer._cache_key = cache_key; Explainer._cache = cache
	out.current = {"id": id, "name": String(definition.get("name", id)), "progress": float(state.discovery_progress.get(id, 0)),
		"effects": effects, "adoption": WorldSimulation.discovery.adoption(id) if state.known_discoveries.has(id) else Research.trial_share(float(state.discovery_progress.get(id, 0))), "usage": "Benefits depend on practice and its required supplies; discovery alone is not full use.",
		"requirements": (definition.get("resource_requirements", []) as Array).duplicate(true)}
	return out

static func _culture() -> Dictionary:
	var state = WorldSimulation.state
	if (state.societal_values as Dictionary).is_empty(): return {"known": false, "course": {}, "effects": [], "values": [], "alignment": {}}
	var values: Dictionary = state.societal_values
	var identity := Culture.ValuesModel.identity_snapshot(values)
	var effects: Array = []
	for row: Dictionary in Culture.ledger(values):
		var inactive := String(row.id) in ["adoption", "trade"]
		var amount := float(row.course) if inactive else float(row.total)
		effects.append({"id": row.id, "label": row.short, "amount": amount * 100.0,
			"unit": "points" if row.id in POINT_EFFECTS else "%", "course": row.course, "values": row.values, "inactive_values": inactive})
	return {"known": true, "course": Culture.course(), "effects": effects, "values": Culture.value_rows(values), "alignment": Culture.alignment(values, identity)}

static func _regard() -> Dictionary:
	var metrics: Dictionary = WorldSimulation.state.simulation_metrics
	var contributors: Array = []
	for pair in [["might", "Might"], ["splendor", "Works"], ["genius", "Learning"], ["wealth", "Plenty"], ["order", "Order"], ["persuasion", "Good words"]]:
		if metrics.has("standing_" + pair[0]): contributors.append({"id": pair[0], "name": pair[1], "value": float(metrics["standing_" + pair[0]])})
	return {"known": metrics.has_all(["standing_awe", "standing_allure"]), "awe": float(metrics.get("standing_awe", -1)),
		"draw": float(metrics.get("standing_allure", -1)), "contributors": contributors, "day": int(metrics.get("standing_day", -1)),
		"note": "Latest civilization standing: awe reflects might, works and learning; draw also reflects culture, plenty, order and diplomacy. These are age-relative readings, not percentages of foreigners."}

## Explicit user comparison only. Existing percentage command, actual donor
## and protection-adjusted result; neither a ten-person claim nor an Apply path.
static func compare_care(settlement_id: String = "", points: int = 5) -> Dictionary:
	points = clampi(points, 1, 5)
	var key := "%s:%d" % [settlement_id, points]
	if key == _comparison_key and not _comparison_draft.is_empty() and Preview.is_current(_comparison_draft): return _comparison_result.duplicate(true)
	var captured := Preview.capture()
	if not bool(captured.get("ok", false)): return captured
	var draft := Preview.step(captured, "Administration", points)
	var result := Preview.evaluate(draft)
	if not bool(result.get("ok", false)): return result
	var id := settlement_id
	if id.is_empty():
		for city: Dictionary in WorldSimulation.state.player_settlements:
			if bool(city.get("primary", false)): id = String(city.id); break
	var before := _comparison_town(result.before, id)
	var after := _comparison_town(result.after, id)
	if before.is_empty() or after.is_empty(): return {"ok": false, "reason": "No forecast is available for this settlement."}
	var actual: Array = []
	for role: String in Manual.ROLES:
		var a := int(result.before.counts.get(role, 0)); var b := int(result.after.counts.get(role, 0))
		if a != b: actual.append({"role": role, "before": a, "after": b, "delta": b - a})
	var out := {"ok": true, "points": points, "label": "+%d percentage points to Keeping & caring" % points,
		"scope": "Civilization-wide allocation; consequences shown for %s" % String(after.get("name", "this settlement")),
		"before": before, "after": after, "transfers": draft.changes.duplicate(true), "actual_transfers": actual,
		"warnings": result.warnings.duplicate(true), "assumptions": result.assumptions.duplicate(),
		"risk_note": "No combined future infant-risk forecast is available. Care builds gradually; food and other conditions can change.", "token": result.token}
	_comparison_draft = captured; _comparison_key = key; _comparison_result = out.duplicate(true)
	return out

static func _comparison_town(plan: Dictionary, id: String) -> Dictionary:
	for town: Dictionary in plan.get("towns", []):
		if String(town.get("id", "")) != id: continue
		var impacts: Dictionary = town.get("work_impacts", {})
		return {"id": id, "name": town.get("name", "This settlement"), "food": (town.food as Dictionary).duplicate(true),
			"care": {"current": float(impacts.get("care_current", 0)) / 100.0, "target": float(impacts.get("care_target", 0)) / 100.0,
				"settle_days": Care.CARE_SETTLE_DAYS, "stored_rot_cut": float(impacts.get("stored_rot_cut", 0)) / 100.0}, "safeguard": town.get("safeguard", {}).duplicate(true)}
	return {}
