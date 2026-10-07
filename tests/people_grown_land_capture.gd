extends Node
## Isolated, explicitly labelled review evidence. Reads a COPY of a campaign
## save; never saves it. Only --pace-seconds advances the in-memory copy.
## --population makes a labelled specimen,
## never a campaign checkpoint. Run GPU mode on run_isolated_gpu_probe.ps1.
## --people-grown-land --save=<copy> --out=<dir> --prefix=before|after
## --sizes=.75,240,1800 [--population=N] [--reveal] [--census=<paths.txt>]
## Without --save: --seed=N reconstructs a labelled founding, not a checkpoint.
## --site-detail adds a close view of a recorded worked site; --pace-seconds=N
## then measures rendered playback on the private desktop after captures.
const Seat = preload("res://scripts/one_seat.gd")
const Realm = preload("res://scripts/realm_reach.gd")
const Lod = preload("res://scripts/terrain_lod.gd")

class Snapshot extends "res://scripts/save_system.gd":
	var source := ""
	func slot_path(_slot: String) -> String: return source

class NoCountry extends Node3D:
	## Capture-only ablation: same map/scheduler, country drawing work disabled.
	var clearing_revision := 0
	var layers: Dictionary = {}
	func refresh(_owner: Node3D) -> void: pass
	func process_jobs(_budget: int, _jobs: int) -> void: pass
	func woodland_ledgers() -> Array: return []
	func canopy_clearings(_center: Vector2) -> Array[Vector4]: return []
	func stats() -> Dictionary: return {"owners": {}, "pending": 0, "disabled_for_comparison": true}

var terrain: Node3D
var report: Dictionary = {}

func _ready() -> void: call_deferred("_run")

func _arg(name: String, fallback := "") -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--" + name + "="): return arg.substr(name.length() + 3)
	return fallback

func _run() -> void:
	if not "--people-grown-land" in OS.get_cmdline_user_args():
		get_tree().quit(2)
		return
	if not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		push_error("Requires private TomorrowPeopleGrownLandQA userdata override.")
		get_tree().quit(2)
		return
	var saves := Snapshot.new()
	add_child(saves)
	if _arg("census") != "":
		var rows: Array = []
		for path in FileAccess.get_file_as_string(_arg("census")).split("\n", false):
			saves.source = path.strip_edges()
			var payload: Dictionary = saves._read_payload("copy")
			var metadata: Dictionary = payload.get("metadata", {}).duplicate()
			metadata["source"] = saves.source
			rows.append(metadata)
			print("CAMPAIGN_METADATA ", JSON.stringify(metadata))
		_write(_arg("out", "res://artifacts/people-grown-land").path_join("census.json"), rows)
		get_tree().quit(0)
		return
	AudioServer.set_bus_mute(0, true)
	var source := _arg("save")
	if source != "":
		saves.source = source
		var loaded: Dictionary = saves.load_game("copy")
		if loaded.has("error"):
			push_error(str(loaded))
			get_tree().quit(1)
			return
		print("PEOPLE_GROWN_LAND_LOADED ", GameState.population_total, " day=", GameState.elapsed_days)
	else:
		WorldSimulation.clear()
		GameState.reset_for_new_world(int(_arg("seed", "184271")))
		GameState.select_founding_focus("provision")
		PeopleDirection.choose("makers")
	GameState.civic_api_enabled = false
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	if _arg("population") != "":
		GameState.ensure_population_total(int(_arg("population")))
	var fabric_specimen: Dictionary = {}
	if _arg("fabric-year") != "":
		# Explicit visual specimen, using the live construction conversion.
		# This does not claim the copied campaign reached this date or fabric.
		var prepared := preload("res://tests/city_evolution_visual_fixture.gd").snapshot(int(_arg("fabric-year")))
		fabric_specimen = {"year": prepared.year, "tier": prepared.tier, "plots": prepared.plots.size(), "scope": "Prepared construction specimen, not a simulated campaign"}
	terrain = load("res://local_terrain.tscn").instantiate()
	if "--without-country" in OS.get_cmdline_user_args():
		var country := NoCountry.new()
		country.name = "CountryLand"
		terrain.country_land = country
		terrain.add_child(country)
	print("PEOPLE_GROWN_LAND_SCENE_LOADED")
	add_child(terrain)
	print("PEOPLE_GROWN_LAND_TERRAIN_READY")
	terrain._set_game_speed(0)
	await get_tree().process_frame
	if source == "":
		GameState.settlement_site_committed = true
		GameState.settlement_founded_at = terrain.settler_marker.position
		if not "Hearth Circle" in GameState.settlement_completed: GameState.settlement_completed.append("Hearth Circle")
		SettlementModel.ensure_founded()
		terrain._refresh_settlement_footprint(true)
	var realm: Dictionary = Realm.ours()
	var core := Seat.core_km()
	var reach := Seat.reach_km()
	var evidence := "Exact saved campaign" if source != "" else "Reconstructed founding - not original campaign checkpoint"
	if _arg("population") != "": evidence = "Population specimen - not a campaign checkpoint"
	if not fabric_specimen.is_empty(): evidence = "Prepared construction year %d, tier %d - not campaign history" % [fabric_specimen.year, fabric_specimen.tier]
	report = {"evidence": evidence, "source_copy": source, "source_sha256": FileAccess.get_sha256(source) if source != "" else "", "population_override": _arg("population"), "seed": GameState.world_seed, "population": GameState.population_total, "day": GameState.elapsed_days, "name": GameState.settlement_name, "core_km": core, "worked_km": reach, "realm_km": realm.get("reach", 0.0), "deposits": GameState.resource_deposits.size(), "revealed_for_review": "--reveal" in OS.get_cmdline_user_args(), "captures": []}
	report["stage"] = Seat.stage()
	if not fabric_specimen.is_empty(): report["fabric_specimen"] = fabric_specimen
	report["settlements"] = GameState.player_settlements.size()
	report["country_disabled_for_comparison"] = "--without-country" in OS.get_cmdline_user_args()
	var target: Vector3 = GameState.settlement_founded_at
	if "--reveal" in OS.get_cmdline_user_args(): CivilizationSystem._add_revealed_area(Vector2(target.x, target.z), float(realm.get("reach", reach)) * 1.3, "isolated review visibility")
	var deadline := Time.get_ticks_msec() + 120000
	while not terrain.macro_render.ready() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	print("PEOPLE_GROWN_LAND_MACRO_READY ", terrain.macro_render.ready())
	terrain.set_camera_distance_level(0)
	terrain.zoom_target_size = -1.0
	terrain.zoom_preset_active = false
	var sizes := _arg("sizes", ".75,%s,%s" % [maxf(reach * 2.5, 30.0), float(realm.get("reach", 30.0)) * 2.5]).split(",")
	var labels := _arg("labels", "town,homesteads,realm").split(",")
	if "--details-only" in OS.get_cmdline_user_args():
		sizes = PackedStringArray()
		labels = PackedStringArray()
	var targets: Array[Vector3] = []
	for index in sizes.size(): targets.append(target)
	if "--site-detail" in OS.get_cmdline_user_args():
		var picked: Dictionary = {}
		var largest_distance := -1.0
		for site: Dictionary in GameState.resource_deposits:
			if String(site.get("stage", "")) not in ["accessible", "developed"]: continue
			if float(site.get("workers", 0)) <= 0: continue
			var place: Variant = site.get("position")
			if not place is Vector3: continue
			var distance := Vector2(place.x - target.x, place.z - target.z).length()
			if distance > largest_distance and distance <= reach:
				picked = site
				largest_distance = distance
		if not picked.is_empty():
			sizes.append("6")
			labels.append("worked-site")
			targets.append(picked.position)
			report["detail_site"] = {"id": picked.get("id"), "resource": picked.get("resource"), "workers": picked.get("workers"), "distance_km": largest_distance, "remaining": picked.get("remaining"), "position": str(picked.position)}
	if "--homestead-detail" in OS.get_cmdline_user_args():
		var country := terrain.get_node_or_null("CountryLand")
		if country:
			country.call("refresh", terrain)
			var owners: Dictionary = country.get("layers")
			if owners.has("player"):
				var plan: Dictionary = owners.player.node.get("plan")
				for farm: Dictionary in plan.get("homesteads", []):
					if _arg("homestead-id") != "" and String(farm.id) != _arg("homestead-id"): continue
					if _arg("homestead-kind") != "" and String(farm.get("kind","")) != _arg("homestead-kind"): continue
					var point: Vector2 = farm.position
					if not terrain._settlement_stage_land_at(point): continue
					var farm_spans := _arg("homestead-span", ".8").split(",")
					for farm_index in farm_spans.size():
						sizes.append(farm_spans[farm_index])
						labels.append("homestead-detail" if farm_spans.size() == 1 else "homestead-detail-%d" % farm_index)
						targets.append(Vector3(point.x, terrain._height_at(point.x, point.y), point.y))
						report["detail_homestead"] = {"id": farm.id, "kind": farm.get("kind","homestead"), "houses": farm.get("buildings",1), "position": str(point), "distance_km": farm.distance_km, "representative": true}
					break
	if _arg("homestead-id") != "" and not report.has("detail_homestead"):
		push_error("Requested diagnostic homestead was not found on admitted land: " + _arg("homestead-id"))
		get_tree().quit(2)
		return
	var directory := _arg("out", "res://artifacts/people-grown-land")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var title_layer := CanvasLayer.new()
	title_layer.layer = 100
	add_child(title_layer)
	var title := Label.new()
	title.position = Vector2(22, 15)
	title.add_theme_color_override("font_color", Color("efe6d4"))
	title.add_theme_color_override("font_shadow_color", Color("1f1a14"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_font_size_override("font_size", 18)
	title_layer.add_child(title)
	for index in sizes.size():
		var span := float(sizes[index])
		var label: String = labels[index] if index < labels.size() else "detail%d" % index
		title.text = "TEST REVIEW | %s | %d people | day %d | %s | %.2f km span" % [evidence, GameState.population_total, int(GameState.elapsed_days), label, span]
		title.text += "\nCore %.0f km | Worked %.0f km | Realm %.0f km" % [core, reach, float(realm.get("reach", 0))]
		title.text += " | Revealed for review" if "--reveal" in OS.get_cmdline_user_args() else ""
		var shot_target: Vector3 = targets[index]
		_set_camera(span, shot_target)
		var frames := 0
		deadline = Time.get_ticks_msec() + 30000
		while Time.get_ticks_msec() < deadline and (frames < 65 or terrain.terrain_patch_job != null or terrain.regional_patch_resolution != Lod.resolution_for(terrain.regional_patch_span)):
			await get_tree().process_frame
			frames += 1
		for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if layer != title_layer: (layer as CanvasLayer).visible = false
		for frame in 60: await get_tree().process_frame
		var country := terrain.get_node_or_null("CountryLand")
		deadline = Time.get_ticks_msec() + 30000
		if not await _wait_country_ready(country, deadline):
			push_error("Required visible country geometry did not finish before capture")
			get_tree().quit(1)
			return
		RenderingServer.force_sync()
		RenderingServer.force_draw(true, 0.0)
		var path := directory.path_join("%s_%s.png" % [_arg("prefix", "review"), label])
		var png_size := Vector2i.ZERO
		if DisplayServer.get_name() != "headless":
			var captured_image: Image = get_viewport().get_texture().get_image()
			png_size = captured_image.get_size()
			captured_image.save_png(ProjectSettings.globalize_path(path))
		var entry := {"path": path, "png_size": str(png_size), "span_km": span, "actual_camera_span_km": terrain.camera.size, "target": str(shot_target), "frames": frames}
		if country and country.has_method("stats"): entry["country_land"] = country.call("stats")
		entry["map_people"] = _map_people_audit()
		entry["farm_scale"] = _farm_scale_audit()
		if "--ground-audit" in OS.get_cmdline_user_args() and span <= 2.0: entry["farm_ground"] = _farm_ground_audit(shot_target, span)
		if "--chart-compare" in OS.get_cmdline_user_args() and span >= 10.0:
			entry["country_charts"] = _country_chart_audit()
			entry["charts_hidden_capture"] = await _capture_charts_hidden(path.replace(".png", "_charts-hidden.png"))
		report.captures.append(entry)
		print("PEOPLE_GROWN_LAND_CAPTURE ", path, " span=", span, " frames=", frames)
	if float(_arg("pace-seconds", "0")) > 0.0:
		report["rendered_playback"] = await _measure_playback(float(_arg("pace-seconds")))
	_write(directory.path_join(_arg("prefix", "review") + ".json"), report)
	print("PEOPLE_GROWN_LAND_DONE ", directory, " prefix=", _arg("prefix", "review"), " population=", GameState.population_total)
	get_tree().quit(0)

func _wait_country_ready(country: Node, deadline: int) -> bool:
	while country and country.has_method("stats") and int(country.call("stats").get("pending", 0)) > 0 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return true

func _set_camera(span: float, target: Vector3) -> void:
	terrain.camera.size = span
	terrain.zoom_target_size = -1.0
	terrain.camera_target = target
	terrain._update_camera()

func _map_people_audit() -> Dictionary:
	var batches := {}
	var clear := true
	for path: String in ["LivingMap/Workers", "LivingMap/Children", "LivingMap/Processions", "MapAmbience/GreatWorkBuilders"]:
		var node := terrain.get_node_or_null(path) as MultiMeshInstance3D
		var count := node.multimesh.instance_count if node and node.multimesh else 0
		var visible_count := node.multimesh.visible_instance_count if node and node.multimesh else 0
		var visible := node.is_visible_in_tree() if node else false
		batches[path] = {"exists": node != null, "instances": count, "visible_instances": visible_count, "visible_in_tree": visible}
		if count > 0 or visible_count > 0: clear = false
	var rite_walkers: Array[String] = []
	for node: Node in terrain.find_children("Walkers", "", true, false):
		rite_walkers.append(str(node.get_path()))
	if not rite_walkers.is_empty(): clear = false
	return {"zero_people_batches": clear, "batches": batches, "rite_walkers": rite_walkers}

func _farm_scale_audit() -> Dictionary:
	var count := 0
	var largest_metres := 0.0
	var samples: Array = []
	var country := terrain.get_node_or_null("CountryLand")
	if country:
		for node: Node in country.find_children("ScatteredHomes", "MultiMeshInstance3D", true, false):
			var homes := node as MultiMeshInstance3D
			var batch: MultiMesh = homes.multimesh
			if not batch or not batch.mesh: continue
			for index in batch.instance_count:
				var transform := batch.get_instance_transform(index)
				var bounds: AABB = Transform3D(transform.basis, Vector3.ZERO) * batch.mesh.get_aabb()
				var metres := bounds.size * 1000.0
				largest_metres = maxf(largest_metres, maxf(metres.x, maxf(metres.y, metres.z)))
				count += 1
				if samples.size() < 4: samples.append({"metres": str(metres), "basis_scale": str(transform.basis.get_scale())})
	return {"instances": count, "largest_dimension_metres": largest_metres, "samples": samples}

func _country_chart_audit() -> Dictionary:
	var country := terrain.get_node_or_null("CountryLand")
	var rows: Array = []
	var onscreen := 0
	var visible := 0
	var total := 0
	if country:
		for node: Node in country.find_children("CountryChart_*", "MeshInstance3D", true, false):
			var chart := node as MeshInstance3D
			if not chart.mesh: continue
			total += 1
			if chart.is_visible_in_tree(): visible += 1
			var anchor := chart.global_transform * chart.mesh.get_aabb().get_center()
			var projected: Vector2 = terrain.camera.unproject_position(anchor)
			var behind: bool = terrain.camera.is_position_behind(anchor)
			var in_view: bool = not behind and get_viewport().get_visible_rect().has_point(projected)
			if in_view: onscreen += 1
			if in_view:
				var material := chart.material_override as ShaderMaterial
				rows.append({"node": str(chart.get_path()), "record": chart.get_meta("country_chart_record", ""), "visible": chart.is_visible_in_tree(),
					"anchor": str(anchor), "behind_camera": behind, "screen_viewport_units": str(projected), "mesh_aabb": str(chart.mesh.get_aabb()),
					"node_custom_aabb": str(chart.custom_aabb), "shader": material.shader.resource_path if material and material.shader else ""})
	return {"nodes": total, "visible_nodes": visible, "onscreen_anchors": onscreen, "onscreen_samples": rows,
		"viewport_rect": str(get_viewport().get_visible_rect()), "reported_texture_size": str(get_viewport().get_texture().get_size())}

func _capture_charts_hidden(path: String) -> Dictionary:
	var states: Array = []
	var country := terrain.get_node_or_null("CountryLand")
	if country:
		for node: Node in country.find_children("CountryChart_*", "MeshInstance3D", true, false):
			states.append({"node": node, "visible": node.visible})
			node.visible = false
	# Apply the visibility toggle in this same process frame so unrelated
	# map animation uniforms do not advance between the comparison images.
	RenderingServer.force_sync()
	RenderingServer.force_draw(true, 0.0)
	if DisplayServer.get_name() != "headless": get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	var hidden_audit := _country_chart_audit()
	for state: Dictionary in states:
		if is_instance_valid(state.node): state.node.visible = state.visible
	for frame in 2: await get_tree().process_frame
	return {"path": path, "toggled_nodes": states.size(), "visible_while_hidden": hidden_audit.visible_nodes}

func _farm_ground_audit(target: Vector3, span: float) -> Array:
	var rows: Array = []
	var country := terrain.get_node_or_null("CountryLand")
	if not country: return rows
	for node: Node in country.find_children("ScatteredHomes", "MultiMeshInstance3D", true, false):
		var homes := node as MultiMeshInstance3D
		var batch: MultiMesh = homes.multimesh
		if not batch or not batch.mesh: continue
		for index in batch.instance_count:
			var transform := homes.global_transform * batch.get_instance_transform(index)
			var at := Vector2(transform.origin.x, transform.origin.z)
			if at.distance_to(Vector2(target.x, target.z)) > maxf(span, 0.05): continue
			var bounds: AABB = transform * batch.mesh.get_aabb()
			var ground_center := float(terrain._harvest_ground_height_at(at))
			var corners: Array = []
			var screen_bounds := Rect2(terrain.camera.unproject_position(bounds.position), Vector2.ZERO)
			for corner in 8:
				var vertex := bounds.get_endpoint(corner)
				screen_bounds = screen_bounds.expand(terrain.camera.unproject_position(vertex))
				if corner < 4:
					var point := Vector2(bounds.position.x if corner % 2 == 0 else bounds.end.x, bounds.position.z if corner < 2 else bounds.end.z)
					corners.append({"xz": str(point), "drawn_ground_metres": float(terrain._harvest_ground_height_at(point)) * 1000.0})
			var earth := homes.get_parent().get_node_or_null("WorkedEarth") as MeshInstance3D
			var ink_height := _triangle_height_at(earth, at)
			rows.append({"node": str(homes.get_path()), "instance": index, "origin": str(transform.origin), "ground_center_metres": ground_center * 1000.0,
				"base_above_ground_metres": (bounds.position.y - ground_center) * 1000.0, "roof_above_ground_metres": (bounds.end.y - ground_center) * 1000.0,
				"roof_world_metres": bounds.end.y * 1000.0, "mesh_dimensions_metres": str(bounds.size * 1000.0), "screen_bounds_viewport_units": str(screen_bounds),
				"footprint_corners": corners, "worked_earth_at_origin": ink_height, "visible": homes.is_visible_in_tree()})
	return rows

func _triangle_height_at(node: MeshInstance3D, point: Vector2) -> Dictionary:
	if not node or not node.mesh: return {"hit": false}
	var highest := -INF
	var hits := 0
	for surface in node.mesh.get_surface_count():
		var arrays := node.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := indices.size() if not indices.is_empty() else vertices.size()
		for triangle in range(0, count - 2, 3):
			var a: Vector3 = node.global_transform * vertices[indices[triangle] if not indices.is_empty() else triangle]
			var b: Vector3 = node.global_transform * vertices[indices[triangle + 1] if not indices.is_empty() else triangle + 1]
			var c: Vector3 = node.global_transform * vertices[indices[triangle + 2] if not indices.is_empty() else triangle + 2]
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var ac := Vector2(c.x - a.x, c.z - a.z)
			var ap := point - Vector2(a.x, a.z)
			var area := ab.cross(ac)
			if absf(area) < 0.000000001: continue
			var u := ap.cross(ac) / area
			var v := ab.cross(ap) / area
			if u < -0.00001 or v < -0.00001 or u + v > 1.00001: continue
			highest = maxf(highest, a.y + u * (b.y - a.y) + v * (c.y - a.y))
			hits += 1
	return {"hit": hits > 0, "overlapping_triangles": hits, "highest_metres": highest * 1000.0 if hits > 0 else 0.0}

func _measure_playback(seconds: float) -> Dictionary:
	# Measures the actual isolated GPU scene scheduler, after camera warm-up.
	# This opts into advancing the in-memory copy only; no save is written.
	terrain._set_game_speed(5)
	var warmup_start := Time.get_ticks_usec()
	var warmup_target := floori(float(GameState.elapsed_days)) + 2
	while floori(float(GameState.elapsed_days)) < warmup_target and Time.get_ticks_usec() - warmup_start < 30000000:
		await get_tree().process_frame
	var warmup_seconds := float(Time.get_ticks_usec() - warmup_start) / 1000000.0
	var warmup_completed := floori(float(GameState.elapsed_days)) >= warmup_target
	var first_day := float(GameState.elapsed_days)
	var before_cost := _playback_cost_snapshot()
	var start := Time.get_ticks_usec()
	var last := start
	var frames: Array[float] = []
	while Time.get_ticks_usec() - start < int(seconds * 1000000.0):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frames.append(float(now - last) / 1000.0)
		last = now
	var duration := float(last - start) / 1000000.0
	var days := float(GameState.elapsed_days) - first_day
	frames.sort()
	var after_cost := _playback_cost_snapshot()
	terrain._set_game_speed(0)
	WorldSimulation.flush_day()
	var reading := {"seconds": duration, "start_day": first_day, "days": days, "days_per_second": days / duration, "frames_per_second": frames.size() / duration, "p50_ms": frames[frames.size() / 2], "p95_ms": frames[int(frames.size() * .95)], "max_ms": frames[-1], "rivals": WorldSimulation.actors.size(), "warmup_days": 2, "warmup_completed": warmup_completed, "warmup_seconds": warmup_seconds, "scope": "Actual private-desktop GPU map frame loop, speed 5; HUD hidden; current camera fixed; two simulation days warm-up."}
	reading["before_cost"] = before_cost
	reading["after_cost"] = after_cost
	reading["map_people_after"] = _map_people_audit()
	print("PEOPLE_GROWN_LAND_PLAYBACK ", JSON.stringify(reading))
	return reading

func _playback_cost_snapshot() -> Dictionary:
	var country := terrain.get_node_or_null("CountryLand")
	var builds := 0
	var requests := 0
	var pending := 0
	if country:
		var stats: Dictionary = country.call("stats")
		pending = int(stats.get("pending", 0))
		for owner: Dictionary in stats.get("owners", {}).values():
			builds += int(owner.get("builds", 0))
			requests += int(owner.get("requests", 0))
	return {"country_builds": builds, "country_requests": requests, "country_pending": pending, "day_cost_usec": terrain.get("_day_cost_usec"), "frame_other_usec": terrain.get("_frame_other_usec"), "frame_sim_usec": terrain.get("_frame_sim_usec")}

func _write(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  "))
	file.close()
