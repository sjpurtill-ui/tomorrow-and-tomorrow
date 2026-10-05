extends RefCounted
## A bounded album of observed views, carried inside the normal campaign save.
## No reconstruction of unobserved years and no second settlement simulation.
const MAX_VIEWS := 24
const MAX_IMAGE_BYTES := 600000

static func current(id: String) -> Dictionary:
	var city := SettlementModel.settlement_record(id).duplicate()
	if city.is_empty(): return {}
	# Raw records store allocation/identity; the model owns the population total.
	city["population"] = roundi(SettlementModel._settlement_population(city))
	return SettlementModel.with_city_resources(id, func() -> Dictionary:
		return observations(city, GameState.settlement_plots, GameState.settlement_completed, int(GameState.elapsed_days)))

static func observations(city: Dictionary, plots: Array, completed: Array, day: int) -> Dictionary:
	var fields := 0.0
	var half_width := 0.035
	var half_depth := 0.035
	var fabric: Array = []
	for plot: Dictionary in plots:
		if String(plot.get("land_use", "")) != "field":
			fabric.append([int(plot.get("id", 0)), String(plot.get("form", "")), String(plot.get("status", ""))])
		if String(plot.get("status", "")) in ["abandoned", "ruin", "archaeological", "reclaimed", "vacant"]: continue
		if String(plot.get("land_use", "")) in ["field", "fields", "farm"]:
			fields += float(plot.get("area_ha", 0.0))
			continue # Outer fields must not make the inhabited village unreadably small.
		for point: Vector2 in plot.get("polygon", PackedVector2Array()):
			half_width = maxf(half_width, absf(point.x))
			half_depth = maxf(half_depth, absf(point.y))
	return {"id": String(city.get("id", "")), "name": String(city.get("name", "Our village")),
		"day": day, "population": int(city.get("population", 0)),
		"works": completed.size(), "field_ha": fields, "span": clampf(maxf(half_width * 1.2, half_depth * 1.85), 0.075, 12.0),
		"fabric": hash(fabric),
		"position": city.get("position", Vector2.ZERO), "founded_day": int(city.get("founded_day", -1))}

static func views(album: Dictionary, id: String) -> Array:
	return (album.get(id, {}) as Dictionary).get("views", [])

static func reason(album: Dictionary, state: Dictionary) -> String:
	var entries := views(album, String(state.get("id", "")))
	if entries.is_empty(): return "First recorded view"
	var last: Dictionary = entries.back()
	if int(state.day) < int(last.day): return "" # Loading an earlier save cannot borrow the future.
	if int(state.day) == int(last.day): return ""
	if int(state.works) > int(last.works): return "New building work"
	if int(state.works) < int(last.works): return "Buildings changed"
	if state.has("fabric") and last.has("fabric") and int(state.fabric) != int(last.fabric): return "The village changed"
	if absf(float(state.field_ha) - float(last.field_ha)) > maxf(0.01, float(last.field_ha) * 0.15): return "Fields changed"
	if int(state.day) / 365 > int(last.day) / 365: return "Another year"
	if abs(int(state.population) - int(last.population)) >= maxi(20, int(last.population) / 5): return "Our people changed"
	return ""

static func append_view(album: Dictionary, state: Dictionary, bytes: PackedByteArray, why: String) -> bool:
	var id := String(state.get("id", ""))
	if id.is_empty() or bytes.is_empty() or bytes.size() > MAX_IMAGE_BYTES or why.is_empty(): return false
	var entries := views(album, id).duplicate(true)
	if not entries.is_empty() and int(state.day) <= int((entries.back() as Dictionary).day): return false
	var entry := state.duplicate(true)
	entry["image"] = bytes
	entry["reason"] = why
	entries.append(entry)
	# Keep the first view and the most recent changes; bound save size.
	while entries.size() > MAX_VIEWS: entries.remove_at(1)
	album[id] = {"views": entries}
	return true

static func changes(album: Dictionary, state: Dictionary) -> String:
	var entries := views(album, String(state.get("id", "")))
	var previous: Dictionary = {}
	for entry: Dictionary in entries:
		if int(entry.day) <= int(state.day) - 365: previous = entry
	if previous.is_empty(): return "The visual record begins with your first recorded visit."
	return "Since Year %d · %s people · %s completed works · %s ha of fields" % [
		int(previous.day) / 365 + 1, signed(int(state.population) - int(previous.population)),
		signed(int(state.works) - int(previous.works)), "%+.2f" % (float(state.field_ha) - float(previous.field_ha))]

static func signed(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)

static func date(day: int) -> String:
	return "Year %d · day %d" % [day / 365 + 1, posmod(day, 365) + 1]
