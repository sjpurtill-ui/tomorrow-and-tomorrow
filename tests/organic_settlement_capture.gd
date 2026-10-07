extends "res://tests/people_grown_land_capture.gd"
## The existing private map capture, with read-only seed/plot diagnostics and
## equal-scale root/expansion views. Third view targets a representative cluster.
## --expansion-x=<world x> --expansion-z=<world z> fixes the comparison position.
var shot_index := 0
var actual_targets: Array[Vector3] = []
var layout_audit: Dictionary = {}
var expansion_target := Vector3.ZERO
var seed_audits: Array[Dictionary] = []

func _wait_country_ready(country: Node, deadline: int) -> bool:
	if _arg("prefix", "before") == "before": return await super._wait_country_ready(country, deadline)
	var audit: Dictionary = _seed_readiness(country)
	while not bool(audit.ready) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		audit = _seed_readiness(country)
	seed_audits.append(audit)
	print("ORGANIC_SEEDS_READY ", JSON.stringify(audit))
	return bool(audit.ready)

func _seed_readiness(country: Node) -> Dictionary:
	var rows: Array = []
	var ready := true
	if country == null: return {"ready": false, "seeds": rows}
	var owners: Dictionary = country.get("layers")
	if not owners.has("player"): return {"ready": false, "seeds": rows}
	var node: Node = owners.player.node
	var retained: Variant = node.get("retained")
	var plan: Dictionary = node.get("plan")
	for record: Dictionary in plan.get("homesteads", []):
		if not record.has("settlement_growth"): continue
		var key := "homesteads:" + String(record.id)
		var row: Dictionary = {"id": record.id, "position": str(record.position), "ready": false}
		if retained.installed.has(key) and retained.desired.has(key):
			var installed: Dictionary = retained.installed[key]
			var patch: Node = installed.node
			row["ready"] = installed.signature == retained.desired[key].signature and patch.has_meta("country_seed_plan")
			row["plots"] = (patch.get_meta("country_seed_plots", []) as Array).size()
			row["routes"] = (patch.get_meta("country_seed_routes", []) as Array).size()
			row["homes"] = int(patch.get_meta("country_home_count", 0))
			row["home_positions"] = patch.get_meta("country_home_positions", [])
		ready = ready and bool(row.ready)
		rows.append(row)
	return {"ready": ready and not rows.is_empty(), "seeds": rows}

func _set_camera(span: float, target: Vector3) -> void:
	if layout_audit.is_empty(): _read_layout(target)
	var chosen := expansion_target if shot_index == 2 else target
	actual_targets.append(chosen)
	shot_index += 1
	super._set_camera(span, chosen)

func _read_layout(origin: Vector3) -> void:
	var clusters: Array = []
	var selected: Dictionary = {}
	var farthest := -1.0
	var country: Node = terrain.get_node_or_null("CountryLand")
	if country != null:
		country.call("refresh", terrain)
		var owners: Dictionary = country.get("layers")
		if owners.has("player"):
			var plan: Dictionary = owners.player.node.get("plan")
			for record: Dictionary in plan.get("homesteads", []):
				if String(record.get("kind", "")) != "cluster": continue
				clusters.append(record.duplicate(true))
				var point: Vector2 = record.position
				var distance := point.distance_to(Vector2(origin.x, origin.z))
				if distance > farthest and terrain._settlement_stage_land_at(point):
					farthest = distance
					selected = record
	expansion_target = origin
	if not selected.is_empty():
		var point: Vector2 = selected.position
		expansion_target = Vector3(point.x, terrain._height_at(point.x, point.y), point.y)
	if _arg("expansion-x") != "" and _arg("expansion-z") != "":
		expansion_target.x = float(_arg("expansion-x"))
		expansion_target.z = float(_arg("expansion-z"))
		expansion_target.y = terrain._height_at(expansion_target.x, expansion_target.z)
	var plots: Array = []
	for plot: Dictionary in GameState.settlement_plots:
		plots.append({"id": plot.get("id"), "nucleus_id": plot.get("nucleus_id"), "centroid": plot.get("centroid"), "land_use": plot.get("land_use"), "status": plot.get("status"), "form": plot.get("form"), "area_ha": plot.get("area_ha")})
	layout_audit = {"root": [origin.x, origin.y, origin.z], "expansion_target": [expansion_target.x, expansion_target.y, expansion_target.z], "selected_cluster": selected, "clusters": clusters, "cluster_count": clusters.size(), "plots": plots, "nuclei": GameState.settlement_nuclei.duplicate(true), "population_exact": GameState.population_exact}
	print("ORGANIC_SETTLEMENT_LAYOUT population=", GameState.population_total, " name=", GameState.settlement_name, " clusters=", clusters.size(), " expansion=", expansion_target)

func _write(path: String, value: Variant) -> void:
	if value is Dictionary and value.has("captures"):
		value["settlement_layout"] = layout_audit
		for index in mini(actual_targets.size(), value.captures.size()):
			value.captures[index]["target"] = str(actual_targets[index])
			if index < seed_audits.size(): value.captures[index]["seed_readiness"] = seed_audits[index]
		super._write(path, value)
	else:
		super._write(path, value)
