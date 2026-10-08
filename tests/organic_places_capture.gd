extends "res://tests/building_construction_capture.gd"
## Acceptance evidence through the ordinary saved-world terrain/country layer.
## Only the copied seat's place records are staged in memory; no save is written.
## The four states are labelled specimens, never fabricated campaign history.
## Use ignored override.cfg: custom user dir TomorrowOrganicPlacesQA, and run
## tools/run_isolated_gpu_probe.ps1 --organic-places-capture --save=<copy>.
## Optional --span=.6, --frames=90, --out=res://artifacts/organic-places.
## --parse-only is an initialized headless parser check, not GPU acceptance.
const Places := preload("res://scripts/settlement_places.gd")
const Growth := preload("res://scripts/settlement_country_growth.gd")
var place: Dictionary = {}
var country: Node3D
var source_path := ""
var source_hash := ""
var population_before := 0.0
var register_count_before := 0
var stockpiles_before := 0
var completed_before := 0
var day_before := 0
var detail_span := .6
var baseline_roofs: Dictionary = {}
var fixed_point := Vector2.ZERO
var fixture_days: Array[int] = []

func _run() -> void:
	if "--parse-only" in OS.get_cmdline_user_args():
		print("ORGANIC_PLACES_CAPTURE_PARSE PASS")
		get_tree().quit(0); return
	if "--organic-places-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless" or not OS.get_user_data_dir().contains("TomorrowOrganicPlacesQA"):
		push_error("Requires private TomorrowOrganicPlacesQA userdata and GPU --organic-places-capture.")
		get_tree().quit(2); return
	output = _arg("out", "res://artifacts/organic-places")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	source_path = _arg("save", "res://artifacts/organic-places/current.save")
	var absolute_source := ProjectSettings.globalize_path(source_path).replace("\\", "/").simplify_path()
	var private_artifacts := ProjectSettings.globalize_path("res://artifacts/").replace("\\", "/").simplify_path().trim_suffix("/") + "/"
	if not absolute_source.begins_with(private_artifacts) or not FileAccess.file_exists(source_path):
		_fail_setup("Copy the save into this worktree's ignored artifacts directory first."); return
	source_hash = FileAccess.get_sha256(source_path)
	var saves := Snapshot.new(); saves.source = source_path; add_child(saves)
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	var loaded: Dictionary = saves.load_game("copy")
	if loaded.has("error"): _fail_setup(str(loaded)); return
	GameState.civic_api_enabled = false
	population_before = float(GameState.population_exact)
	register_count_before = GameState.player_settlements.size()
	stockpiles_before = hash(var_to_bytes(GameState.resource_stockpiles))
	completed_before = hash(var_to_bytes(GameState.settlement_completed))
	day_before = int(GameState.elapsed_days)
	var saved_places: Array = Places.snapshot().get("places", []).duplicate(true)
	terrain = load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain._set_game_speed(0)
	origin = GameState.settlement_founded_at
	get_window().size = Vector2i(1600, 900)
	get_window().content_scale_size = Vector2i(1600, 900)
	var deadline := Time.get_ticks_msec() + 90000
	while not terrain.macro_render.ready() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	if not terrain.macro_render.ready(): _fail_setup("Saved-world terrain did not become ready."); return
	country = terrain.get_node_or_null("CountryLand")
	if country == null: _fail_setup("Ordinary terrain did not install CountryLand."); return
	if not _prepare_place(saved_places): _fail_setup("No real coastal founding site found in the copied world's bounded site search."); return
	fixed_point = place.position
	CivilizationSystem._add_revealed_area(fixed_point, 2.0, "private organic-place review")
	CivilizationSystem._add_revealed_area(Vector2(origin.x, origin.z), 1.5, "private root comparison")
	terrain.set_camera_distance_level(0); terrain.zoom_target_size = -1.0; terrain.zoom_preset_active = false
	terrain.camera_yaw = PI * .5; terrain.camera_pitch = deg_to_rad(-45.0)
	detail_span = clampf(float(_arg("span", ".6")), .08, 2.0)
	label_layer = CanvasLayer.new(); label_layer.layer = 100; add_child(label_layer)
	title = Label.new(); title.position = Vector2(22, 16)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("f5ead4"))
	title.add_theme_color_override("font_shadow_color", Color("201b14"))
	title.add_theme_constant_override("shadow_offset_x", 2); title.add_theme_constant_override("shadow_offset_y", 2)
	label_layer.add_child(title)
	report = {"scope": "Four staged place states on actual copied-save terrain using the production country layer; not historical campaign checkpoints", "source_copy": source_path, "source_sha256": source_hash, "user_data": OS.get_user_data_dir(), "population": population_before, "saved_day": day_before, "world_seed": GameState.world_seed, "original_places": saved_places, "place_id": place.id, "place_name": place.name, "position": str(fixed_point), "root": str(origin), "fixed_span_km": detail_span, "revealed_for_review": true, "captures": [], "failures": failures}
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	await _capture("root_same_scale", "Saved root — identical camera scale", origin, detail_span, false)
	for phase: String in ["founding", "mature", "flood", "ruin"]:
		_stage(phase)
		var facing: Vector2 = place.get("facing", Vector2.ZERO)
		var framed := fixed_point + facing * minf(.12, detail_span * .2)
		var target := Vector3(framed.x, terrain._height_at(framed.x, framed.y), framed.y)
		await _capture(phase, String({"founding": "First coastal place — founding families", "mature": "Mature coastal place — same root scale", "flood": "Flood setback — damaged water side", "ruin": "Abandoned place — roofless remains"}[phase]), target, detail_span, true)
		if phase == "mature":
			var shore_target := _shore_target()
			if shore_target != Vector3.INF:
				await _capture("mature_shore_detail", "Drawn-up hulls and working shore — close detail", shore_target, .16, true)
			var center := (fixed_point + Vector2(origin.x, origin.z)) * .5
			var chart_span := maxf(12.0, fixed_point.distance_to(Vector2(origin.x, origin.z)) * 2.4)
			CivilizationSystem._add_revealed_area(center, chart_span, "private place chart review")
			await _capture("mature_chart", "Inked place name and route to the seat", Vector3(center.x, terrain._height_at(center.x, center.y), center.y), chart_span, true)
	_check(float(GameState.population_exact) == population_before, "Place fixtures changed aggregate population")
	_check(GameState.player_settlements.size() == register_count_before, "Place fixtures added a daily simulation settlement")
	_check(hash(var_to_bytes(GameState.resource_stockpiles)) == stockpiles_before, "Place fixtures changed the central stockpile")
	_check(hash(var_to_bytes(GameState.settlement_completed)) == completed_before, "Place fixtures changed completed construction")
	_check(FileAccess.get_sha256(source_path) == source_hash, "Copied save changed on disk")
	report["fixture_days"] = fixture_days
	report["source_unchanged"] = FileAccess.get_sha256(source_path) == source_hash
	for key: String in images:
		var path := ProjectSettings.globalize_path(output.path_join(key + ".png"))
		_check((images[key] as Image).save_png(path) == OK, "Could not write " + path)
	report["passed"] = failures.is_empty(); report["failures"] = failures
	_write(output.path_join("capture-audit.json"), report)
	print("ORGANIC_PLACES_CAPTURE_DONE ", "PASS" if failures.is_empty() else "FAIL", " ", JSON.stringify(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func _fail_setup(message: String) -> void:
	_check(false, message)
	_write(output.path_join("capture-audit.json"), {"passed": false, "failures": failures})
	get_tree().quit(2)

func _prepare_place(saved: Array) -> bool:
	# Reuse the first actual coast record if possible, retaining its measured
	# founding position/facing/name. Otherwise ask the real engine to site one.
	var seat: Dictionary = Seat.seat_record()
	if seat.is_empty(): return false
	var records: Array = seat.get("places", [])
	for candidate: Dictionary in records:
		if String(candidate.get("kind", "")) == "coast" and candidate.get("position") is Vector2:
			if terrain._settlement_stage_land_at(candidate.position): place = candidate.duplicate(true); break
	seat["places"] = []
	if place.is_empty():
		for attempt in 8:
			var rng := RandomNumberGenerator.new(); rng.seed = hash("organic-place-capture:%d:%d" % [GameState.world_seed, attempt])
			var site: Dictionary = Places.choose_site(Vector2(origin.x, origin.z), population_before, rng)
			if String(site.get("kind", "")) != "coast": continue
			if not terrain._settlement_stage_land_at(site.position): continue
			place = Places.found(int(GameState.elapsed_days), site, population_before)
			break
	else:
		(seat.places as Array).append(place)
		GameState.settlement_network_revision += 1
	if place.is_empty():
		seat["places"] = saved.duplicate(true)
		return false
	_stage("founding")
	return true

func _stage(phase: String) -> void:
	# All changes below are explicit specimen data in the private loaded copy.
	# A 30-day key change uses the ordinary visual refresh cadence.
	GameState.elapsed_days += 30
	var today := int(GameState.elapsed_days)
	fixture_days.append(today)
	place.status = "ruin" if phase == "ruin" else "living"
	place.share = clampf(Places.FOUNDERS / maxf(1.0, population_before), .002, .03) if phase == "founding" else minf(.22, Places.away_limit(population_before))
	place.target = minf(.30, float(place.share) + .04) if phase == "founding" else place.share
	place.founded_day = today if phase == "founding" else today - 365 * 25
	place["setback_until"] = today + Places.FLOOD_SETBACK_DAYS if phase == "flood" else -1
	place["left_day"] = today - 365 * 4 if phase == "ruin" else -1
	if phase == "flood": place.target = float(place.share) * .6
	if phase == "ruin": place.share = 0.0; place.target = 0.0
	if phase in ["founding", "ruin"]: GameState.settlement_network_revision += 1

func _capture(key: String, description: String, target: Vector3, span: float, require_place: bool) -> void:
	title.text = "TEST COPIED SAVE | %s | %.2f km span\nStaged place state on actual world terrain; %s; aggregate %d people." % [description, span, place.name, roundi(population_before)]
	_set_camera(span, target)
	var settled := await _settle_place(require_place)
	_check(settled, key + ": terrain or place preparation did not finish before capture")
	for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if layer != label_layer: layer.visible = false
	for frame in 30: await get_tree().process_frame
	var entry: Dictionary = {"key": key, "description": description, "path": output.path_join(key + ".png"), "span_km": span, "actual_span_km": terrain.camera.size, "target": str(target), "camera_yaw": terrain.camera_yaw, "camera_pitch": terrain.camera_pitch, "place_snapshot": Places.snapshot(), "country": country.call("stats"), "map_people": _map_people_audit(), "settled": settled}
	_check(bool(entry.map_people.zero_people_batches), key + ": map contains human batches")
	_check(is_equal_approx(float(terrain.camera.size), span), key + ": camera span changed")
	if require_place:
		var patch := _place_patch()
		_check(patch != null, key + ": actual place patch is missing")
		if patch != null:
			entry["place_art"] = _place_audit(patch)
			_check(int(entry.place_art.parcels) <= Growth.MAX_PARCELS, key + ": parcel cap exceeded")
			_check(Vector2(patch.get_meta("country_seed_origin", Vector2.INF)) == fixed_point, key + ": place center moved")
			var roofs := _roof_fingerprint(patch)
			entry["roofs"] = roofs
			if key == "founding":
				baseline_roofs = roofs.duplicate(true)
				_check(not roofs.is_empty(), "Founding place has no visible roofs")
			elif key == "mature":
				var lost: Array[String] = []
				for id: String in baseline_roofs:
					if not roofs.has(id) or roofs[id] != baseline_roofs[id]: lost.append(id)
				entry["changed_founding_roofs"] = lost
				_check(lost.is_empty(), "Growth moved or removed a founding roof")
				_check(roofs.size() >= baseline_roofs.size(), "Mature place has fewer roofs than founding")
			elif key == "flood": _check(bool(patch.get_meta("country_place_flooded", false)), "Flood setback is not represented by the installed patch")
			elif key == "ruin": _check(String(patch.get_meta("country_place_status", "")) == "ruin", "Ruin is not represented by the installed patch")
			if key == "mature_chart":
				_check(bool(entry.place_art.label.get("in_view", false)), "Chart place name is outside the captured view")
				_check(bool(entry.place_art.label.get("visible", false)), "Chart place name is not visible")
	entry["timing"] = await _measure_frames(maxi(1, int(_arg("frames", "90"))))
	await RenderingServer.frame_post_draw
	images[key] = get_viewport().get_texture().get_image()
	report.captures.append(entry)
	print("ORGANIC_PLACES_CAPTURE ", key, " ", JSON.stringify({"ready": settled, "country": entry.country, "place": entry.get("place_art", {}), "timing": entry.timing}))

func _settle_place(require_place: bool) -> bool:
	var deadline := Time.get_ticks_msec() + 65000
	var frames := 0
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame; frames += 1
		if frames < 100 or terrain.terrain_patch_job != null: continue
		if terrain.regional_patch_resolution != Lod.resolution_for(terrain.regional_patch_span): continue
		if not require_place: return true
		var layer := _player_layer()
		if layer == null: continue
		var retained: RefCounted = layer.get("retained")
		var id := "homesteads:place:" + String(place.id)
		if not retained.installed.has(id) or not retained.desired.has(id): continue
		if retained.installed[id].signature != retained.desired[id].signature: continue
		var patch := _place_patch()
		if patch == null or not patch.has_meta("country_seed_plan"): continue
		var record := _place_record(layer)
		var projected: Dictionary = record.get("place", {})
		if int(projected.get("people", -1)) != Places.people(place): continue
		if bool(projected.get("flooded", false)) != (int(GameState.elapsed_days) < int(place.get("setback_until", -1))): continue
		if String(projected.get("status", "")) != String(place.status): continue
		return true
	return false

func _player_layer() -> Node3D:
	var layers: Dictionary = country.get("layers")
	return layers.player.node if layers.has("player") else null

func _place_record(layer: Node3D) -> Dictionary:
	var plan: Dictionary = layer.get("plan")
	for record: Dictionary in plan.get("homesteads", []):
		if String(record.get("id", "")) == "place:" + String(place.id): return record
	return {}

func _place_patch() -> Node3D:
	var layer := _player_layer()
	if layer == null: return null
	var retained: RefCounted = layer.get("retained")
	var id := "homesteads:place:" + String(place.id)
	return retained.installed[id].node if retained.installed.has(id) else null

func _shore_target() -> Vector3:
	var patch := _place_patch()
	if patch == null: return Vector3.INF
	for prop: Node3D in patch.find_children("*", "Node3D", true, false):
		if String(prop.get_meta("place_detail", "")) != "dugout": continue
		var facing: Vector2 = place.get("facing", Vector2.ZERO)
		var at := Vector2(prop.global_position.x, prop.global_position.z) + facing * .008
		return Vector3(at.x, terrain._height_at(at.x, at.y), at.y)
	return Vector3.INF

func _place_audit(patch: Node3D) -> Dictionary:
	var row: Dictionary = {"parcels": (patch.get_meta("country_seed_plots", []) as Array).size(), "homes": int(patch.get_meta("country_home_count", 0)), "visible": patch.is_visible_in_tree(), "details": patch.get_meta("place_detail_kinds", []), "detail_positions": patch.get_meta("place_detail_positions", []), "track_points": patch.get_meta("place_track_points", []), "damaged_roofs": patch.get_meta("place_damaged_roofs", 0), "label": {}, "geometry": _geometry(patch)}
	for field: String in ["id", "name", "kind", "status", "trend", "flooded", "fade"]:
		row[field] = patch.get_meta("country_place_" + field, null)
	var label := patch.find_child("PlaceChartName", true, false) as Label3D
	if label != null:
		var screen: Vector2 = terrain.camera.unproject_position(label.global_position)
		row.label = {"text": label.text, "visible": label.is_visible_in_tree(), "in_view": not terrain.camera.is_position_behind(label.global_position) and get_viewport().get_visible_rect().has_point(screen), "screen": str(screen), "font_size": label.font_size, "font": label.font.resource_path if label.font != null else "", "pixel_size": label.pixel_size}
	return row

func _roof_fingerprint(patch: Node3D) -> Dictionary:
	var result: Dictionary = {}
	var plan: Dictionary = patch.get_meta("country_seed_plan", {})
	for building: Dictionary in plan.get("buildings", []):
		var id := "%s:%s" % [str(building.get("plot_id", "")), str(building.get("id", building.get("site_id", building.get("position", Vector2.ZERO))))]
		result[id] = {"position": Vector2(building.get("position", Vector2.ZERO)) + fixed_point, "angle": building.get("angle", 0.0), "footprint": building.get("footprint", PackedVector2Array()), "scale": building.get("scale", Vector3.ONE)}
	return result
