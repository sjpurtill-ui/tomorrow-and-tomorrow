extends RefCounted
## Presentation readings from the existing calculators, evaluated by
## WorkforcePreview on its detached world. No new production/balance rules.
const Care = preload("res://scripts/food_care.gd")
const Goods = preload("res://scripts/civilian_goods.gd")
const Watch = preload("res://scripts/watch_military.gd")

static func local_reading() -> Dictionary:
	var state = WorldSimulation.state
	var land: Dictionary = WorldSimulation.resources.land_reading(0.0)
	var carriers := Care.carry_cover_of(state)
	var keepers := Care.keep_cover_of(state)
	var goods_room := maxf(0.0, Goods.ceiling() - Goods.stock())
	return {"population": maxf(0.0, float(state.population_exact)),
		"survey_target": float(land.get("target", 0.0)) * 100.0,
		"finds_month": float(land.get("finds_month", 0.0)) if bool(land.get("settled", false)) else 0.0,
		"extracted_today": maxf(0.0, float(state.material_metrics.get("extracted_today", 0.0))),
		# An upper bound, explicitly not delivered goods: arms, stock room,
		# materials and demand can all reduce actual production.
		"making_capacity": maxf(0.0, float(state.effective_workers("Crafting"))) * Goods.goods_per_maker_day(),
		"goods_room": goods_room,
		"fresh_rot_cut": (1.0 - Care.fresh_spoilage_factor(carriers)) * 100.0,
		"harvest_reach": (Care.reach_factor(carriers) - 1.0) * 100.0,
		"stored_rot_cut": (1.0 - Care.stored_spoilage_factor(keepers)) * 100.0,
		"care_target": Care.care_target_of(state) * 100.0,
		"care_current": Care.care_cover_of(state) * 100.0}

static func combine(towns: Array) -> Dictionary:
	var out: Dictionary = {}
	var population := 0.0
	for town: Dictionary in towns:
		population += float(town.get("work_impacts", {}).get("population", 0.0))
	for key: String in ["survey_target", "fresh_rot_cut", "harvest_reach", "stored_rot_cut", "care_target", "care_current"]:
		out[key] = 0.0
		for town: Dictionary in towns:
			var reading: Dictionary = town.get("work_impacts", {})
			out[key] += float(reading.get(key, 0.0)) * float(reading.get("population", 0.0)) / maxf(1.0, population)
	for key: String in ["finds_month", "extracted_today", "making_capacity", "goods_room"]:
		out[key] = 0.0
		for town: Dictionary in towns:
			out[key] += float(town.get("work_impacts", {}).get(key, 0.0))
	# Read the aggregate military ledger once outside any settlement scope.
	var guard := Watch.reading(WorldSimulation.military)
	out["guard"] = float(guard.get("guard", 0))
	out["guard_need"] = float(Watch.guard_needed())
	out["away"] = float(guard.get("away", 0))
	out["armed"] = float(guard.get("armed", 0.0)) * 100.0
	return out

## At most three graphical readings. Values always retain an explicit unit;
## stock/observed results are never relabelled as a future production change.
static func readings(result: Dictionary, role: String, settlement_id := "", comparing := false) -> Array:
	if not bool(result.get("ok", false)): return []
	var before: Dictionary = result.get("before", {})
	var after: Dictionary = result.get("after", {})
	var old: Dictionary = before.get("work_impacts", {})
	var next: Dictionary = after.get("work_impacts", {})
	var out: Array = []
	match role:
		"Food":
			out.append(_metric("Food brought in", before.get("food", {}), after.get("food", {}), "production", "rations/day", "Harvest estimate at today's weather and working conditions.", float(after.get("food", {}).get("required", 0))))
		"Survey":
			out.append(_metric("Land knowledge · settles toward", old, next, "survey_target", "%", "Coverage changes over time. Better searched land improves cutting and digging.", 100))
			out.append(_metric("Useful finds · expected average", old, next, "finds_month", "/month", "An average, not a scheduled discovery; the existing search rules determine finds."))
		"Extraction":
			out.append(_metric("Cutting & digging capacity", before.get("effective_workers", {}), after.get("effective_workers", {}), role, "fit workers", "Effective crew after injuries and other duties. Deposits, access and carrying limit deliveries."))
			out.append(_metric("Last measured extraction", old, next, "extracted_today", "loads/day", "Observed output before this assignment. More workers do not guarantee a proportional increase."))
		"Crafting":
			out.append(_metric("Making capacity · before supply limits", old, next, "making_capacity", "goods/day", "Potential household making at today's efficiency. Materials, arms work, demand and storage can reduce output."))
			out.append(_metric("Room for more goods", old, next, "goods_room", "goods", "Remaining space in homes and markets; making slows when this is full."))
		"Logistics":
			var water: Dictionary = after.get("water", {})
			if bool(water.get("known", false)):
				out.append(_metric("Drinking water collected · estimate", before.get("water", {}), water, "collected", "water/day", "Compared with drinking needs; sources, rain and household collection held fixed.", float(water.get("required", 0))))
			out.append(_metric("Fresh food spoilage prevented", old, next, "fresh_rot_cut", "%", "Reduction from carriers compared with having no carrying cover; full cover halves fresh spoilage.", 50))
			out.append(_metric("Extra ground supplying fresh food", old, next, "harvest_reach", "%", "Carriers bring food home from further away; full cover adds one quarter to the gathering reach.", 25))
		"Knowledge":
			var research: Dictionary = after.get("research", {})
			var previous: Dictionary = before.get("research", {})
			out.append(_metric("Research work · supplied capacity", previous, research, "effective_work", "effort/day", "Work after today's goods supply limits. This is research effort, not discoveries per day."))
			out.append(_metric("Research teams", previous, research, "teams", "teams", "Teams that can work at the same time; each question still has its own requirements."))
			out.append(_metric("Research supplies required", previous, research, "goods_a_day", "goods/day", "More learners use more goods. Shortages reduce the work shown above."))
		"Administration":
			out.append(_metric("Care coverage · settles toward", old, next, "care_target", "%", "Carers tend newborns, mothers and the sick. Skill adjusts gradually over about 60 days; this is the staffing target.", 100))
			out.append(_metric("Stored food spoilage prevented", old, next, "stored_rot_cut", "%", "Reduction from keepers compared with having no keeping cover; full cover prevents 40% of stored spoilage.", 40))
		"Defense":
			out.append(_metric("Home guard", old, next, "guard", "guards", "Home guard across our settlements, compared with the guard the towns need.", float(next.get("guard_need", 0))))
			out.append(_metric("Watch equipped", old, next, "armed", "%", "The share equipped from the actual arms ledger. Assigning people does not conjure equipment.", 100))
		"Construction":
			var housing := _housing(after, settlement_id)
			var prior_housing := _housing(before, settlement_id)
			if bool(housing.get("building", false)) and float(housing.get("work_per_day", 0)) > 0 and float(housing.get("days_left", -1)) >= 0:
				var entry := _metric("Next %d home places · estimate" % int(housing.get("batch", 0)), prior_housing, housing, "days_left", "days", "Time at this crew's pace and current supplies; later events can change it.")
				entry["lower_better"] = true
				if not bool(prior_housing.get("building", false)) or float(prior_housing.get("work_per_day", 0)) <= 0:
					entry["before"] = entry.after
					entry["words"] = "About %.0f days with this crew" % float(entry.after)
				out.append(entry)
			else:
				out.append(_metric("Home building crew", before.get("construction", {}), after.get("construction", {}), "homes", "fit workers", "Builders allocated to housing by the existing town priorities."))
			out.append(_metric("Repair crew", before.get("construction", {}), after.get("construction", {}), "repair", "fit workers", "Workers maintaining what already stands, compared with the repair crew wanted.", float(after.get("construction", {}).get("repair_want", 0))))
			out.append(_metric("Improving homes, roads & works", before.get("construction", {}), after.get("construction", {}), "fabric", "fit workers", "The crew left for town improvements after housing, repair and other commitments."))
	for entry: Dictionary in out:
		if not entry.has("words"):
			entry["words"] = ("%s → %s %s" % [_number(float(entry.before)), _number(float(entry.after)), entry.unit]) if comparing and not is_equal_approx(float(entry.before), float(entry.after)) else "%s %s" % [_number(float(entry.after)), entry.unit]
	return out

static func _metric(label: String, before: Dictionary, after: Dictionary, key: String, unit: String, note: String, need := 0.0) -> Dictionary:
	return {"label": label, "before": float(before.get(key, 0.0)), "after": float(after.get(key, 0.0)), "unit": unit, "note": note, "need": need}

static func _housing(plan: Dictionary, settlement_id: String) -> Dictionary:
	var construction: Dictionary = plan.get("construction", {})
	if not (construction.get("housing", {}) as Dictionary).is_empty(): return construction.housing
	for town: Dictionary in construction.get("towns", []):
		if String(town.get("id", "")) == settlement_id: return town.get("construction", {}).get("housing", {})
	return {}

static func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)): return str(roundi(value))
	if absf(value) < 0.1 and not is_zero_approx(value): return "%.2f" % value
	return "%.1f" % value
