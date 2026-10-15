extends RefCounted
## A disposable allocation draft and a read-only consequence preview.
## No live setter, order, clock tick, save or live ledger write is called here.
## Existing commands and rules run synchronously on detached system instances.
## Committing belongs to the provider: check is_current, require an explicit
## assignment action, then replay through the original Manual.move_share.

const Manual = preload("res://scripts/manual_work.gd")
const Fabric = preload("res://scripts/built_fabric.gd")
const Construction = preload("res://scripts/settlement_construction.gd")
const Research = preload("res://scripts/research_600_catalog.gd")
const WorkImpacts = preload("res://scripts/hud/people_work_impacts.gd")
const BINDINGS := ["state", "discovery", "progression", "resources", "economy", "settlements", "government", "figures", "direction", "communities", "diplomacy", "dialogue", "facts", "advisors", "food", "consequences", "civics", "world", "military"]
const ASSUMPTIONS := [
	"Food compares one representative day at the captured season, weather, population, stores and working conditions. It is an estimate, not yesterday's observed output.",
	"The existing 30/90-day seasonal outlook holds this workforce and demand pattern. It does not predict future population, wars, orders, discoveries or deaths.",
	"Town leaders may move extra workers to food when the existing food safeguard activates. The proposed result includes today's safeguard; future intervention can change the outlook.",
	"Water scales the last measured organized collection by its effective crew; household supply, sources, rain and conveyance stay fixed. Without a measured crew, the new flow is unknown.",
	"Research shows team work capacity and goods needed, not discoveries per day. Construction shows assigned crews and current housing pace, not guaranteed completion.",
	"Material deliveries are not extrapolated from worker counts: accessible deposits, carrying capacity and material demand can limit them."
]
static var _busy := false
# Authored definitions are copied once into the detached snapshot. The rules
# used here only read them. Mutable adoption, stocks, effects and workers are
# still independently copied for each evaluation and checked by the token.
const DEFINITIONS := ["catalog", "technology_catalog", "technology_limits", "catalog_by_id", "catalog_by_channel", "definitions_by_id"]
const DEFINITION_INDICES := ["technology_catalog", "catalog_by_id", "catalog_by_channel", "definitions_by_id"]
const TRANSIENT_READERS := ["_candidate_index", "_scan", "_today"]
static var _before_token := 0
static var _before_result: Dictionary = {}

static func capture() -> Dictionary:
	if _busy or WorldSimulation.advancing:
		return {"ok": false, "reason": "Wait for the current simulation step to finish."}
	var frozen := _capture_systems()
	var counts := _counts(WorldSimulation.state)
	var manual := not bool(WorldSimulation.direction.automatic_work)
	# Taking control snapshots current heads, not the inactive saved ruler split.
	var shares := Manual._shares_of(counts)
	if manual:
		var saved: Dictionary = WorldSimulation.direction.work_baseline
		if not saved.is_empty() and _sum(saved) > 0.0:
			shares = saved.duplicate(true)
	return {"ok": true, "token": _token(frozen), "actor": WorldSimulation.actor_id,
		"manual": manual, "able": int(_sum(counts)), "shares": shares,
		"original_shares": shares.duplicate(true), "has_changes": false,
		"counts": counts.duplicate(true), "original_counts": counts,
		"commands": [], "changes": [], "_snapshot": frozen}

## Each point has the exact largest-donor/tie rule used by move_share.
## The input and its captured snapshot are never changed.
static func step(draft: Dictionary, role: String, points: int) -> Dictionary:
	var out := draft.duplicate(false)
	out["commands"] = (draft.get("commands", []) as Array).duplicate(true)
	out["shares"] = (draft.get("shares", {}) as Dictionary).duplicate(true)
	out["counts"] = (draft.get("counts", {}) as Dictionary).duplicate(true)
	out["changes"] = (draft.get("changes", []) as Array).duplicate(true)
	if not bool(draft.get("ok", false)) or role not in Manual.ROLES or points == 0:
		return out
	var shares := Manual.percents(out.shares)
	var moved := 0
	for index in absi(points):
		if points > 0:
			var donor := Manual._most(shares, role)
			if donor.is_empty(): break
			shares[donor] = int(shares[donor]) - 1
			shares[role] = int(shares[role]) + 1
		else:
			if int(shares[role]) <= 0: break
			var recipient := Manual._most(shares, role, 0)
			if recipient.is_empty(): break
			shares[role] = int(shares[role]) - 1
			shares[recipient] = int(shares[recipient]) + 1
		moved += 1
	if moved == 0: return out
	out.shares = shares
	out.counts = Manual.whole_people(shares, int(draft.able))
	out.commands.append({"role": role, "points": points})
	out["has_changes"] = shares != Manual.percents(draft.original_shares)
	if not bool(out.has_changes):
		out.shares = (draft.original_shares as Dictionary).duplicate(true)
		out.counts = (draft.original_counts as Dictionary).duplicate(true)
		out.commands = []
	out.changes = []
	for task: String in Manual.ROLES:
		var before := int(draft.original_counts.get(task, 0))
		var after := int(out.counts.get(task, 0))
		if before != after:
			out.changes.append({"role": task, "before": before, "after": after, "delta": after - before})
	return out

static func is_current(draft: Dictionary) -> bool:
	if _busy or WorldSimulation.advancing or not bool(draft.get("ok", false)):
		return false
	return String(draft.get("actor", "")) == WorldSimulation.actor_id and int(draft.get("token", 0)) == _token(_capture_systems(true))

static func evaluate(draft: Dictionary) -> Dictionary:
	if _busy or not bool(draft.get("ok", false)) or not draft.get("_snapshot") is Dictionary:
		return {"ok": false, "reason": "No captured allocation to preview."}
	if not is_current(draft):
		return {"ok": false, "stale": true, "reason": "The world changed. Refresh this draft before comparing or applying it."}
	if _before_token != int(draft.token) or _before_result.is_empty():
		_before_result = _isolated(draft._snapshot, func() -> Dictionary: return _read_plan(false, draft))
		_before_token = int(draft.token)
	var before: Dictionary = _before_result.duplicate(true)
	var after: Dictionary = before.duplicate(true) if (draft.commands as Array).is_empty() else _isolated(draft._snapshot, func() -> Dictionary: return _read_plan(true, draft))
	if before.is_empty() or after.is_empty():
		return {"ok": false, "reason": "The current allocation could not be estimated."}
	var warnings: Array = []
	for town: Dictionary in after.towns:
		var food: Dictionary = town.food
		if String(food.hunger_risk) == "now":
			warnings.append({"kind": "starvation", "town": town.name, "days": 0,
				"text": "%s: this split cannot feed everyone from the available food. Starvation is a risk if the shortfall continues." % town.name})
		elif int(food.shortage_day) >= 0:
			warnings.append({"kind": "food_shortage", "town": town.name, "days": food.shortage_day,
				"text": "%s: the seasonal outlook reaches a food shortage in about %d days. Continued shortage risks starvation." % [town.name, food.shortage_day]})
		if bool(town.water.known) and float(town.water.ratio) < 0.98:
			warnings.append({"kind": "water", "town": town.name,
				"text": "%s: estimated collection covers %d%% of drinking needs." % [town.name, roundi(float(town.water.ratio) * 100.0)]})
		if bool(town.get("safeguard", {}).get("active", false)):
			warnings.append({"kind": "safeguard", "town": town.name,
				"text": "%s: its leader currently puts extra hands on food; the preview includes that intervention." % town.name})
	return {"ok": true, "before": before, "after": after, "warnings": warnings,
		"assumptions": ASSUMPTIONS.duplicate(), "token": draft.token}

static func _read_plan(proposed: bool, draft: Dictionary) -> Dictionary:
	var guards: Dictionary = {}
	if proposed: guards = _replay(draft)
	var state = WorldSimulation.state
	var counts := _counts(state)
	var effective: Dictionary = {}
	for role: String in Manual.ROLES: effective[role] = state.effective_workers(role)
	# Tomorrow's work uses goods still held, not a cached receipt for today's
	# former crew. Both sides use the same captured remaining inventory.
	WorldSimulation.discovery._learning_day.day = -1
	var learning: Dictionary = WorldSimulation.discovery.role_effect("Knowledge", 0.0)
	var research := {"learners": learning.learners, "teams": learning.teams,
		"work": learning.work, "goods_factor": learning.goods_factor,
		"effective_work": float(learning.work) * float(learning.goods_factor),
		"goods_a_day": learning.goods_a_day, "goods_cover": learning.goods_cover,
		"lead_rate": learning.lead_rate}
	var towns: Array = []
	var cities: Array = state.player_settlements.duplicate(true)
	if cities.is_empty():
		var town := _read_town()
		town["id"] = ""
		town["name"] = state.settlement_name if not String(state.settlement_name).is_empty() else "Your people"
		town["safeguard"] = {}
		towns.append(town)
	else:
		for city: Dictionary in cities:
			if not String(city.get("occupied_by", "")).is_empty() or WorldSimulation.settlements.abandoned(city): continue
			var id := String(city.get("id", ""))
			var town: Dictionary = WorldSimulation.settlements.with_city_resources(id, func() -> Dictionary:
				return WorldSimulation.settlements.with_local_population(func() -> Dictionary: return _read_town()))
			town["id"] = id
			town["name"] = String(city.get("name", "Your town"))
			town["safeguard"] = guards.get(id, {})
			towns.append(town)
	var result := {"counts": counts, "effective_workers": effective, "research": research, "towns": towns}
	result["food"] = _combined_food(towns)
	result["water"] = _combined_water(towns)
	result["work_impacts"] = WorkImpacts.combine(towns)
	# Crew effort can be added; individual housing ETAs cannot.
	var construction: Dictionary = {}
	for key in ["builders", "homes", "civic", "repair", "repair_want", "infra", "walls", "fabric"]:
		construction[key] = 0.0
		for town: Dictionary in towns: construction[key] = float(construction[key]) + float(town.construction[key])
	construction["housing"] = towns[0].construction.housing if towns.size() == 1 else {}
	construction["towns"] = towns.map(func(t: Dictionary) -> Dictionary: return {"id": t.id, "name": t.name, "construction": t.construction})
	result["construction"] = construction
	result["materials"] = {"forecast_available": false, "extractors": effective.Extraction, "carriers": effective.Logistics,
		"reason": "Output also depends on accessible deposits, carrying capacity and demand."}
	return result

## The original government calculation runs on detached systems. Chronicle
## itself only publishes when WorldSimulation.state == the live GameState,
## so this scope cannot write a Chronicle entry or call an external narrator.
static func _lay_requested_split(shares: Dictionary) -> Dictionary:
	if not _busy or WorldSimulation.state == GameState: return {}
	WorldSimulation.direction.automatic_work = false
	WorldSimulation.direction.work_baseline = shares.duplicate(true)
	WorldSimulation.government._lay_ruler_split()
	return _guards()

static func _replay(draft: Dictionary) -> Dictionary:
	if not _busy or WorldSimulation.state == GameState: return {}
	var previous_relaid: bool = Manual.relaid
	if not Manual.manual(): Manual.set_manual(true)
	for command: Dictionary in draft.commands: Manual.move_share(String(command.role), int(command.points))
	Manual.relaid = previous_relaid
	return _guards()

static func _guards() -> Dictionary:
	var applied := Manual.applied_percentages()
	var guards: Dictionary = {}
	for city: Dictionary in WorldSimulation.state.player_settlements:
		var actual := float(city.get("local_allocations", {}).get("Food", applied.Food))
		guards[String(city.get("id", ""))] = {"active": bool(city.get("fed_by_leader", false)) and actual > float(applied.Food) + 0.01,
			"requested_food": applied.Food, "food": actual, "allocations": city.get("local_allocations", {}).duplicate(true)}
	return guards

static func _read_town() -> Dictionary:
	var state = WorldSimulation.state
	var water := _water()
	var work_impacts := WorkImpacts.local_reading()
	var crews := Fabric.crews()
	crews["housing"] = Construction.housing()
	var metrics: Dictionary = state.simulation_metrics
	# Force a fresh existing forecast; an old weekly cache describes the old
	# workforce. Caches and every mutated receipt are private to this clone.
	metrics.erase("food_forecast_day")
	var stock := 0.0
	WorldSimulation.food.initialize()
	for value in state.food_stocks.values(): stock += maxf(0.0, float(value))
	var food: Dictionary = WorldSimulation.food._process_local_day({"traveling": state.convoy_traveling}, float(metrics.get("labor_efficiency", 0.72)), float(metrics.get("ecology", 0.88)))
	var required := float(food.food_consumption)
	var deficit := required + float(food.food_spoilage) - float(food.food_production)
	var shortage := int(food.food_forecast_90.get("first_shortage_day", -1))
	var risk := "now" if float(food.food_intake_ratio) < 0.995 else ("forecast" if shortage >= 0 else "none")
	if risk == "now": shortage = 0
	var reading := {"production": food.food_production, "required": required, "eaten": food.food_eaten,
		"spoilage": food.food_spoilage, "net": food.food_net, "stock": stock,
		"ending_stock": food.food_total_stock, "stored_days": stock / required if required > 0.0 else -1.0,
		"depletion_days": stock / deficit if deficit > 0.01 else -1.0,
		"shortage_day": shortage, "hunger_risk": risk, "intake_ratio": food.food_intake_ratio,
		"forecast30": food.food_forecast_30, "forecast90": food.food_forecast_90,
		"sources": food.food_sources,
		"trajectory": [{"day": 0, "stock": stock}, {"day": 1, "stock": food.food_total_stock},
			{"day": 30, "stock": food.food_forecast_30.ending_rations}, {"day": 90, "stock": food.food_forecast_90.ending_rations}]}
	return {"food": reading, "water": water, "construction": crews, "work_impacts": work_impacts}

static func _water() -> Dictionary:
	var state = WorldSimulation.state
	var measured: Dictionary = state.water_metrics
	var required := float(measured.get("required_today", 0.0))
	var old_hands := float(measured.get("collection_workers", 0.0))
	var organized := float(measured.get("organized_collection_capacity", -1.0))
	var hands := float(state.effective_workers("Logistics")) + float(state.effective_workers("Food")) * 0.22
	var known := required > 0.0 and old_hands > 0.01 and organized >= 0.0
	var collected := -1.0
	if known:
		collected = minf(float(measured.get("total_required_today", required)) * 1.35 + float(measured.get("cistern_capacity", 0.0)),
			float(measured.get("household_collected_today", 0.0)) + organized * hands / old_hands + float(measured.get("conveyed_today", 0.0)) + float(measured.get("rain_collected_today", 0.0)))
	return {"known": known, "estimate": true, "required": required, "collected": collected,
		"ratio": clampf(collected / required, 0.0, 1.0) if known else -1.0, "collection_workers": hands,
		"stock": float(state.resource_stockpiles.get("Freshwater", measured.get("stored", 0.0)))}

static func _combined_food(towns: Array) -> Dictionary:
	if towns.size() == 1: return (towns[0].food as Dictionary).duplicate(true)
	var out := {"shortage_day": -1, "hunger_risk": "none", "trajectory": []}
	for horizon in [30, 90]:
		out["forecast%d" % horizon] = {"horizon": horizon, "aggregate": true, "ending_rations": 0.0, "ending_days": -1.0, "first_shortage_day": -1, "average_production": 0.0, "average_required": 0.0, "spoilage": 0.0}
	for key in ["production", "required", "eaten", "spoilage", "net", "stock", "ending_stock"]: out[key] = 0.0
	for town: Dictionary in towns:
		var food: Dictionary = town.food
		for key in ["production", "required", "eaten", "spoilage", "net", "stock", "ending_stock"]: out[key] = float(out[key]) + float(food[key])
		for key in ["forecast30", "forecast90"]:
			for field in ["ending_rations", "average_production", "average_required", "spoilage"]: out[key][field] = float(out[key][field]) + float(food[key][field])
			var first := int(food[key].first_shortage_day)
			if first >= 0 and (int(out[key].first_shortage_day) < 0 or first < int(out[key].first_shortage_day)): out[key].first_shortage_day = first
		if int(food.shortage_day) >= 0 and (int(out.shortage_day) < 0 or int(food.shortage_day) < int(out.shortage_day)): out.shortage_day = food.shortage_day
		if String(food.hunger_risk) == "now" or (String(food.hunger_risk) == "forecast" and String(out.hunger_risk) == "none"): out.hunger_risk = food.hunger_risk
	out["stored_days"] = float(out.stock) / float(out.required) if float(out.required) > 0.0 else -1.0
	var deficit := float(out.required) + float(out.spoilage) - float(out.production)
	out["depletion_days"] = float(out.stock) / deficit if deficit > 0.01 else -1.0
	out["intake_ratio"] = float(out.eaten) / float(out.required) if float(out.required) > 0.0 else 1.0
	# A realm total is not a shared pantry: the individual town forecasts own
	# their days-of-food readings. Do not turn a rich town into a poor one's food.
	out.trajectory = [{"day": 0, "stock": out.stock}, {"day": 1, "stock": out.ending_stock}, {"day": 30, "stock": out.forecast30.ending_rations}, {"day": 90, "stock": out.forecast90.ending_rations}]
	return out

static func _combined_water(towns: Array) -> Dictionary:
	if towns.size() == 1: return (towns[0].water as Dictionary).duplicate(true)
	var out := {"known": not towns.is_empty(), "estimate": true, "required": 0.0, "collected": 0.0, "stock": 0.0, "ratio": -1.0}
	for town: Dictionary in towns:
		out.known = bool(out.known) and bool(town.water.known)
		for key in ["required", "collected", "stock"]: out[key] = float(out[key]) + maxf(0.0, float(town.water[key]))
	if bool(out.known) and float(out.required) > 0.0: out.ratio = clampf(float(out.collected) / float(out.required), 0.0, 1.0)
	return out

static func _counts(state: Node) -> Dictionary:
	var out: Dictionary = {}
	for role: String in Manual.ROLES: out[role] = maxi(0, roundi(float(state.population_allocations.get(role, 0))))
	return out

static func _sum(values: Dictionary) -> float:
	var total := 0.0
	for role: String in Manual.ROLES: total += maxf(0.0, float(values.get(role, 0.0)))
	return total

static func _token(frozen: Dictionary) -> int:
	var data: Dictionary = {}
	for name: String in frozen: data[name] = _mutable_record(frozen[name])
	return hash([WorldSimulation.actor_id, data])

static func _mutable_record(frozen: Dictionary) -> Dictionary:
	var fields: Dictionary = frozen.fields.duplicate(false)
	for name: String in DEFINITIONS: fields.erase(name)
	var children: Dictionary = {}
	for name: String in frozen.children: children[name] = _mutable_record(frozen.children[name])
	return {"fields": fields, "children": children, "rng": frozen.rng}

## Copy data, including nested helper ledgers and RNG state. Owner Node refs,
## callbacks and caches are deliberately not shared with the calculation.
static func _capture_systems(signature_only: bool = false) -> Dictionary:
	var out: Dictionary = {}
	for name: String in WorldSimulation.OWNED_SYSTEMS:
		out[name] = _freeze_object(WorldSimulation.system(name), 0, signature_only)
	return out

static func _freeze_object(source: Object, depth: int = 0, signature_only: bool = false) -> Dictionary:
	var out := {"fields": {}, "children": {}, "rng": {}, "indices": {}}
	if depth > 12: return out
	for property: Dictionary in source.get_property_list():
		if not int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE: continue
		var name := String(property.name)
		if "cache" in name or "memo" in name or name in TRANSIENT_READERS: continue
		if signature_only and name in DEFINITIONS: continue
		var value: Variant = source.get(name)
		# Discovery indices point back into the same authored catalog. Preserve
		# their exact order/keys, without copying each 20MB definition pool four
		# more times. Rebuild them from the detached catalog when thawing.
		if name in DEFINITION_INDICES:
			if name == "catalog_by_channel":
				var channels: Dictionary = {}
				for channel in value: channels[channel] = (value[channel] as Array).map(func(d: Dictionary) -> String: return String(d.get("id", "")))
				out.indices[name] = channels
			elif value is Array: out.indices[name] = value.map(func(d: Dictionary) -> String: return String(d.get("id", "")))
			else: out.indices[name] = value.keys()
		elif value is RandomNumberGenerator:
			out.rng[name] = {"seed": value.seed, "state": value.state}
		elif value is RefCounted and value.get_script() != null and not value is Resource:
			out.children[name] = _freeze_object(value, depth + 1, signature_only)
		elif not typeof(value) in [TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID, TYPE_NIL]:
			out.fields[name] = _plain(value)
	return out

static func _plain(value: Variant) -> Variant:
	# Model containers are serializable ledger data. Native deep duplication
	# avoids walking the research catalogs repeatedly in interpreted GDScript.
	# The snapshot regression rejects object/callback references in containers.
	if value is Dictionary or value is Array: return value.duplicate(true)
	return value

static func _thaw_object(target: Object, frozen: Dictionary, definitions: Dictionary = {}) -> void:
	if frozen.fields.get("catalog") is Array:
		definitions = {}
		for definition: Dictionary in frozen.fields.catalog: definitions[String(definition.get("id", ""))] = definition
	for name: String in frozen.fields:
		var value: Variant = frozen.fields[name]
		var current: Variant = target.get(name)
		if name in DEFINITIONS:
			# This aliases the private captured definitions, never the live ones.
			target.set(name, value)
		elif current is Array:
			current.assign((value as Array).duplicate(true))
		elif current is Dictionary:
			current.clear()
			current.merge((value as Dictionary).duplicate(true))
		else: target.set(name, value)
	for name: String in frozen.rng:
		var rng: RandomNumberGenerator = target.get(name)
		if rng != null:
			rng.seed = int(frozen.rng[name].seed)
			rng.state = int(frozen.rng[name].state)
	for name: String in frozen.children:
		var child: Variant = target.get(name)
		if child is RefCounted: _thaw_object(child, frozen.children[name], definitions)
	for name: String in frozen.get("indices", {}):
		var index: Variant = frozen.indices[name]
		var current: Variant = target.get(name)
		current.clear()
		if name == "catalog_by_channel":
			for channel in index:
				var entries: Array = []
				for id: String in index[channel]:
					if definitions.has(id): entries.append(definitions[id])
				current[channel] = entries
		else:
			for id: String in index:
				if not definitions.has(id): continue
				if current is Array: current.append(definitions[id])
				else: current[id] = definitions[id]

static func _isolated(frozen: Dictionary, operation: Callable) -> Dictionary:
	if _busy or not operation.is_valid(): return {}
	for name: String in WorldSimulation.OWNED_SYSTEMS:
		if not frozen.get(name) is Dictionary: return {}
		for field in ["fields", "children", "rng"]:
			if not frozen[name].get(field) is Dictionary: return {}
	_busy = true
	var copies: Dictionary = {}
	var previous: Array = []
	for name: String in WorldSimulation.OWNED_SYSTEMS:
		var copy: Node = WorldSimulation.system(name).get_script().new()
		copies[name] = copy
		_thaw_object(copy, frozen[name])
	for field: String in BINDINGS: previous.append(WorldSimulation.get(field))
	var old_active: Dictionary = WorldSimulation._active
	var old_span: int = WorldSimulation.span
	WorldSimulation._active = copies
	WorldSimulation.span = 1
	for index in BINDINGS.size(): WorldSimulation.set(BINDINGS[index], copies[WorldSimulation.OWNED_SYSTEMS[index]])
	var value: Variant = operation.call()
	# Synchronous scope: restore even when the operation returns no result.
	for index in BINDINGS.size(): WorldSimulation.set(BINDINGS[index], previous[index])
	WorldSimulation._active = old_active
	WorldSimulation.span = old_span
	for copy: Node in copies.values(): copy.free()
	_busy = false
	return value if value is Dictionary else {}
