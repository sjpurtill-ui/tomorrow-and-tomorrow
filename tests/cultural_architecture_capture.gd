extends "res://tests/building_construction_capture.gd"
## Private saved-terrain finish specimens; does not manufacture campaign history.
## --cultural-architecture-capture [--save=<read-only copy>] [--frames=120]
## Neutral and styled controls use the same current production shader/geometry.
const Culture := preload("res://scripts/settlement_culture_visual.gd")
const Values := preload("res://scripts/societal_values_model.gd")
var site_labels: Array[Label] = []

func _run() -> void:
	if "--cultural-architecture-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		get_tree().quit(2); return
	output = _arg("out", "res://artifacts/cultural-architecture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var source := _arg("save", "res://artifacts/wall-scale/current.save")
	var saves := Snapshot.new(); saves.source = source; add_child(saves)
	var loaded: Dictionary = saves.load_game("copy")
	if loaded.has("error"):
		_check(false, str(loaded)); get_tree().quit(2); return
	GameState.civic_api_enabled = false
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	terrain = load("res://local_terrain.tscn").instantiate(); add_child(terrain); terrain._set_game_speed(0)
	print("CULTURAL_CAPTURE_SOURCE_LOADED")
	origin = GameState.settlement_founded_at
	get_window().size = Vector2i(1600, 900); get_window().content_scale_size = Vector2i(1600, 900)
	var deadline := Time.get_ticks_msec() + 90000
	while not terrain.macro_render.ready() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	terrain.set_camera_distance_level(0); terrain.zoom_target_size = -1.0; terrain.zoom_preset_active = false
	terrain.camera_yaw = PI * .5; terrain.camera_pitch = deg_to_rad(-45.0)
	_set_camera(.050, origin); await _settle(); terrain.set_process(false)
	for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false): layer.visible = false
	var hidden: Array[Node3D] = []
	for field: String in ["settlement_visual_root", "settlement_land_use_root", "settlement_network_fabric_root", "settlement_border_root", "settlement_network_marker_root", "country_land"]:
		var node: Node3D = terrain.get(field)
		if is_instance_valid(node) and node.visible: hidden.append(node); node.visible = false
	_prepare_specimens(); _create_labels()
	var crafts: Array = ["clay_shaping", "lime_mortar", "mineral_pigment_preparation", "pictographic_records"]
	var profiles: Array[Dictionary] = [
		{"key": "neutral", "name": "Neutral recorded finish", "finish": Culture.neutral()},
		{"key": "ordered", "name": "Ordered lived values | smoke roofs, lime walls, formal trim", "finish": Culture.capture(_values(.8, .3), crafts)},
		{"key": "open", "name": "Open lived values | warm roofs, rose plaster, painted trim", "finish": Culture.capture(_values(.3, .8), crafts)}
	]
	report = {"scope": "Prepared cultural finish specimens on genuine saved terrain; not historical campaign checkpoints", "timing_scope": "Neutral and styled controls share the current shader, geometry, fixed camera and frozen map background; does not compare old shader binary cost", "source": source, "source_sha256": FileAccess.get_sha256(source), "population": GameState.population_total, "day": GameState.elapsed_days, "origin": str(origin), "crafts": crafts, "comparisons": [], "failures": failures}
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var references: Dictionary = {}
	var cases: Array[Dictionary] = [{"profile": 0, "entry": "root"}, {"profile": 1, "entry": "root"}, {"profile": 2, "entry": "root"}, {"profile": 0, "entry": "expansion"}, {"profile": 2, "entry": "expansion"}]
	for current: Dictionary in cases:
		var profile: Dictionary = profiles[int(current.profile)]
		var entry := String(current.entry)
		for plot: Dictionary in specimens: plot.cultural_appearance = profile.finish.duplicate(true)
		var specimen_hash := hash(var_to_bytes(specimens))
		specimen_plan = Early.layout(specimens, roads, _local_land); _assert_plot_coverage()
		var parent := Node3D.new(); parent.name = "CultureSpecimen"; terrain.add_child(parent)
		var renderer: Node3D
		var started := Time.get_ticks_usec()
		if entry == "root": Early.render(specimen_plan, origin, _height, parent)
		else:
			renderer = Country.new(); terrain.add_child(renderer)
			renderer.configure(func(point: Vector2) -> float: return _height(point.x, point.y), _world_land)
			var record: Dictionary = {"id": "cultural-review", "kind": "cluster", "group": "homesteads", "position": Vector2(origin.x, origin.z), "settlement_plots": specimens.duplicate(true), "settlement_routes": roads.duplicate(true), "track_from": Vector2(origin.x, origin.z)}
			renderer._build_patch(parent, record, {"style": {}, "road_tier": 0})
		var build_usec := Time.get_ticks_usec() - started
		title.text = "TEST CULTURE SPECIMEN | %s | %s\nSame sites, forms and recorded materials; culture supplies the finish." % [profile.name, entry]
		_position_labels()
		for frame in 120: await get_tree().process_frame
		var timing: Dictionary = await _measure_frames(int(_arg("frames", "120")))
		await RenderingServer.frame_post_draw
		images[String(profile.key) + "_" + entry] = get_viewport().get_texture().get_image()
		var geometry: Dictionary = _geometry(parent)
		var fingerprint: Dictionary = _placed_fingerprint(parent)
		if not references.has(entry): references[entry] = {"geometry": geometry.duplicate(true), "fingerprint": fingerprint}
		else:
			var reference: Dictionary = references[entry]
			_check(geometry == reference.geometry, entry + ": finish changed mesh counts or vertex counts")
			_check(fingerprint == reference.fingerprint, entry + ": finish changed building geometry or placement")
		_check(hash(var_to_bytes(specimens)) == specimen_hash, "Production renderer mutated cultural specimens")
		var audit: Dictionary = {"profile": profile.key, "finish": profile.finish, "entry": entry, "build_usec": build_usec, "geometry": geometry, "fingerprint": fingerprint, "codes": _culture_codes(parent), "timing": timing}
		report.comparisons.append(audit); print("CULTURAL_CAPTURE ", JSON.stringify(audit))
		parent.queue_free()
		if renderer != null: renderer.queue_free()
		for frame in 4: await get_tree().process_frame
	for node: Node3D in hidden:
		if is_instance_valid(node): node.visible = true
	for label: Label in site_labels: label.hide()
	terrain.set_process(true); _set_camera(.75, origin); await _settle()
	title.text = "TEST REVIEW | Actual loaded settlement | %d people | no population or campaign-time edits" % GameState.population_total
	for frame in 120: await get_tree().process_frame
	report["map_people"] = _map_people_audit()
	_check(bool(report.map_people.zero_people_batches), "Map human batches must remain empty")
	report["map_timing"] = await _measure_frames(int(_arg("frames", "120")))
	await RenderingServer.frame_post_draw
	images["saved_map_context"] = get_viewport().get_texture().get_image()
	for key: String in images: (images[key] as Image).save_png(ProjectSettings.globalize_path(output.path_join(key + ".png")))
	report["failures"] = failures; report["passed"] = failures.is_empty()
	_write(output.path_join("capture-audit.json"), report)
	print("CULTURAL_CAPTURE_DONE ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _values(order: float, openness: float) -> Dictionary:
	var values := Values.initial_state("", 1301, "builders")
	for axis: String in Values.VALUE_ORDER: values.lived[axis] = .5
	values.lived.centralization = order; values.lived.hierarchy = order
	for axis: String in ["openness", "experimentation", "pluralism"]: values.lived[axis] = openness
	return values

func _prepare_specimens() -> void:
	for index in 2:
		var center := Vector2((float(index) - .5) * .042, 0)
		var polygon := PackedVector2Array([Vector2(-.014, -.014), Vector2(.014, -.014), Vector2(.014, .014), Vector2(-.014, .014)])
		for corner in polygon.size(): polygon[corner] += center
		specimens.append({"id": index + 1, "seed": 91, "centroid": center, "polygon": polygon, "frontage_route_id": 1, "area_ha": .0784, "roof_coverage": .16, "resident_count": 5, "material_family": "organic" if index == 0 else "earth", "land_use": "residential_compound", "form": "timber_household" if index == 0 else "compact_courtyard_row", "roof_plan": "timber_ridge" if index == 0 else "courtyard_flat", "status": "active", "construction_progress": 1.0, "condition": .9, "storeys": 1, "fabric_generation": 0 if index == 0 else 6})
	roads.append({"id": 1, "kind": "camp_path", "width_m": .6, "points": PackedVector2Array([Vector2(-.042, .016), Vector2(.042, .016)])})

func _assert_plot_coverage() -> void:
	var represented: Dictionary = {}
	for building: Dictionary in specimen_plan.get("buildings", []): represented[int(building.plot_id)] = true
	for plot: Dictionary in specimens: _check(represented.has(int(plot.id)), "Real land/layout omitted cultural specimen %d" % int(plot.id))

func _create_labels() -> void:
	label_layer = CanvasLayer.new(); label_layer.layer = 100; add_child(label_layer)
	title = _label(22); title.position = Vector2(24, 18)
	for text: String in ["EARLY | timber household", "LATER | masonry courtyard"]:
		var label := _label(20); label.text = text; site_labels.append(label)

func _label(font_size: int) -> Label:
	var label := Label.new(); label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f5ead4")); label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2); label.add_theme_constant_override("shadow_offset_y", 2)
	label_layer.add_child(label); return label

func _position_labels() -> void:
	for index in specimens.size():
		var local: Vector2 = specimens[index].centroid + Vector2(0, .017)
		var point := Vector3(origin.x + local.x, _height(origin.x + local.x, origin.z + local.y), origin.z + local.y)
		var screen: Vector2 = terrain.camera.unproject_position(point)
		var label: Label = site_labels[index]
		label.position = screen - Vector2(label.get_minimum_size().x * .5, 0)

func _placed_fingerprint(parent: Node) -> Dictionary:
	var rows: Array[String] = []
	for node: MultiMeshInstance3D in parent.find_children("*", "MultiMeshInstance3D", true, false):
		var mesh: Mesh = node.multimesh.mesh
		var vertices: Array = []
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			if arrays.size() > Mesh.ARRAY_VERTEX: vertices.append(arrays[Mesh.ARRAY_VERTEX])
		var transforms: Array = []
		for index in node.multimesh.instance_count: transforms.append(node.multimesh.get_instance_transform(index))
		rows.append("%d:%d" % [hash(var_to_bytes(vertices)), hash(var_to_bytes(transforms))])
	rows.sort()
	return {"batches": rows.size(), "mesh_and_transform_hash": hash(var_to_bytes(rows))}

func _culture_codes(parent: Node) -> Array:
	var rows: Array = []
	for node: MultiMeshInstance3D in parent.find_children("*", "MultiMeshInstance3D", true, false):
		if node.has_meta("cultural_codes"): rows.append({"node": String(node.name), "codes": node.get_meta("cultural_codes")})
	return rows
