extends "res://tests/building_construction_capture.gd"
## Actual saved map, fixed-camera yard-only ablation; no campaign edits.
## The separately labelled detail strip shows production mesh assets only.
const YardController := preload("res://scripts/settlement_yard_details.gd")
const YardMeshes := preload("res://scripts/settlement_yard_meshes.gd")
const YardInk := preload("res://scripts/settlement_ink.gd")
var yards: YardController

func _run() -> void:
	if "--lived-in-yards-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		get_tree().quit(2); return
	output = _arg("out", "res://artifacts/lived-in-yards")
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
	print("YARDS_CAPTURE_SOURCE_LOADED")
	origin = GameState.settlement_founded_at
	get_window().size = Vector2i(1600, 900); get_window().content_scale_size = Vector2i(1600, 900)
	var deadline := Time.get_ticks_msec() + 90000
	while not terrain.macro_render.ready() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	terrain.set_camera_distance_level(0); terrain.zoom_target_size = -1.0; terrain.zoom_preset_active = false
	terrain.camera_yaw = PI * .5; terrain.camera_pitch = deg_to_rad(-45.0)
	_set_camera(.08, origin); await _settle()
	terrain.call("_process_settlement_yards")
	yards = terrain.get("settlement_yards") as YardController
	if yards == null:
		_check(false, "Normal terrain did not create settlement_yards"); get_tree().quit(2); return
	await _settle_yards()
	_check(not yards.displayed.is_empty(), "Actual saved settlement has no admitted yard props")
	if not yards.displayed.is_empty():
		var nearest: Dictionary = yards.displayed[0]
		for row: Dictionary in yards.displayed:
			if Vector2(row.position).distance_squared_to(Vector2(origin.x, origin.z)) < Vector2(nearest.position).distance_squared_to(Vector2(origin.x, origin.z)): nearest = row
		var point: Vector2 = nearest.position
		origin = Vector3(point.x, _height(point.x, point.y), point.y)
	_set_camera(.045, origin); await _settle(); await _settle_yards()
	# Only visibility of the new retained yard layer differs during comparison.
	# Keep ordinary buildings, terrain, routes, plants and camera exactly fixed.
	terrain.set_process(false)
	for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false): layer.visible = false
	label_layer = CanvasLayer.new(); label_layer.layer = 100; add_child(label_layer)
	title = _make_label(label_layer, 22); title.position = Vector2(24, 18)
	report = {"scope": "Genuine saved map: only new yard visibility toggled; separate asset detail strip is explicitly a specimen", "source": source, "source_sha256": FileAccess.get_sha256(source), "population": GameState.population_total, "day": GameState.elapsed_days, "target": str(origin), "comparisons": [], "failures": failures}
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var near_rows := _rows_by_id()
	var initial_stats: Dictionary = yards.stats()
	report["near"] = initial_stats; report["placement_audit"] = _placement_audit()
	for enabled: bool in [false, true]:
		yards.visible = enabled
		title.text = "TEST SAVED MAP | Yard details %s | %d people\nSame camera, buildings and terrain; no population or campaign-time edits." % ["ON" if enabled else "OFF", GameState.population_total]
		for frame in 120: await get_tree().process_frame
		var timing: Dictionary = await _measure_frames(int(_arg("frames", "120")))
		await RenderingServer.frame_post_draw
		var key := "yards_on" if enabled else "yards_off"
		images[key] = get_viewport().get_texture().get_image()
		report.comparisons.append({"enabled": enabled, "timing": timing, "stats": yards.stats()})
		print("YARDS_CAPTURE ", key, " ", JSON.stringify(timing))
	_check(_rows_by_id() == near_rows, "Settled visibility toggle changed world placements")
	report["lifecycle"] = await _lifecycle(near_rows)
	report["map_people"] = _map_people_audit()
	_check(bool(report.map_people.zero_people_batches), "Map human batches must remain empty")
	images["five_prop_detail_strip"] = await _detail_strip()
	# Save only after all frame-time samples; encoding cannot pollute the results.
	for key: String in images: (images[key] as Image).save_png(ProjectSettings.globalize_path(output.path_join(key + ".png")))
	report["failures"] = failures; report["passed"] = failures.is_empty()
	_write(output.path_join("capture-audit.json"), report)
	print("YARDS_CAPTURE_DONE ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _settle_yards() -> void:
	var deadline := Time.get_ticks_msec() + 12000
	for frame in 3:
		yards.process_jobs(1000, 4); await get_tree().process_frame
	while int(yards.stats().get("pending", 0)) > 0 and Time.get_ticks_msec() < deadline:
		yards.process_jobs(1000, 4); await get_tree().process_frame
	_check(int(yards.stats().get("pending", 0)) == 0, "Yard placement queue did not settle")

func _rows_by_id() -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in yards.displayed: result[String(row.house_id) + "/" + String(row.kind)] = yards.global_transform * Transform3D(row.transform)
	return result

func _lifecycle(original: Dictionary) -> Dictionary:
	var center := Vector2(origin.x, origin.z)
	var before: Dictionary = yards.stats()
	_set_camera(.75, origin); yards.set_view(center, .75)
	var far_started := Time.get_ticks_usec()
	for index in 120: yards.process_jobs(1000, 4)
	var far_usec := Time.get_ticks_usec() - far_started
	var far: Dictionary = yards.stats()
	_check(not yards.visible, "Yards visible beyond strict close-view span")
	_check(int(far.placement_builds) == int(before.placement_builds), "Far view performed placement work")
	_set_camera(.045, origin); yards.set_view(center, .045); await _settle_yards()
	_check(_rows_by_id() == original, "Re-entering close view relocated yards")
	var pan_center := center + Vector2(.064, 0)
	_set_camera(.045, Vector3(pan_center.x, origin.y, pan_center.y)); yards.set_view(pan_center, .045)
	await _settle_yards(); var pan: Dictionary = yards.stats()
	_check(int(pan.props) <= YardController.MAX_PROPS and int(pan.batches) <= 5, "Pan exceeded global budget")
	_set_camera(.045, origin); yards.set_view(center, .045); await _settle_yards()
	var returned: Dictionary = yards.stats()
	_check(_rows_by_id() == original, "Pan and return changed original world placements")
	_check(int(returned.placement_builds) == int(pan.placement_builds), "Cached re-entry rebuilt yard placements")
	return {"far": far, "far_120_calls_usec": far_usec, "pan": pan, "returned": returned, "world_stable": _rows_by_id() == original}

func _placement_audit() -> Dictionary:
	var buildings: Dictionary = {}; var roads: Dictionary = {}
	for bucket: Array in yards.get("_obstacles").values():
		for row: Dictionary in bucket: buildings[String(row.id)] = row
	for bucket: Array in yards.get("_roads").values():
		for row: Dictionary in bucket: roads[hash(var_to_bytes(row.polygon))] = row.polygon
	var house_hits := 0; var road_hits := 0; var water_hits := 0; var prop_hits := 0
	var kinds: Dictionary = {}; var rows: Array[Dictionary] = yards.displayed
	for index in rows.size():
		var row: Dictionary = rows[index]; var footprint: PackedVector2Array = row.local_footprint
		kinds[String(row.kind)] = int(kinds.get(String(row.kind), 0)) + 1
		for house: Dictionary in buildings.values():
			if not Geometry2D.intersect_polygons(footprint, house.footprint).is_empty(): house_hits += 1
		for road: PackedVector2Array in roads.values():
			if not Geometry2D.intersect_polygons(footprint, road).is_empty(): road_hits += 1
		for other in range(index + 1, rows.size()):
			if not Geometry2D.intersect_polygons(footprint, rows[other].local_footprint).is_empty(): prop_hits += 1
		for point: Vector2 in row.footprint:
			if yards.water_at.is_valid() and bool(yards.water_at.call(point)): water_hits += 1
	_check(rows.size() <= YardController.MAX_PROPS and int(yards.stats().batches) <= 5, "Yards exceeded global 96-prop/five-batch cap")
	_check(house_hits == 0 and road_hits == 0 and water_hits == 0 and prop_hits == 0, "Yard footprint overlaps building, route, water or another prop")
	return {"props": rows.size(), "kinds": kinds, "building_overlaps": house_hits, "route_overlaps": road_hits, "water_samples": water_hits, "prop_overlaps": prop_hits}

func _make_label(parent: Node, size: int) -> Label:
	var label := Label.new(); label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f5ead4")); label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2); label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label); return label

func _detail_strip() -> Image:
	var viewport := SubViewport.new(); viewport.size = Vector2i(1600, 600)
	viewport.own_world_3d = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(viewport)
	var scene := Node3D.new(); viewport.add_child(scene)
	var environment := Environment.new(); environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("777d65"); environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE; environment.ambient_light_energy = .8
	var world := WorldEnvironment.new(); world.environment = environment; scene.add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -35, 0); sun.light_energy = .6; scene.add_child(sun)
	var floor := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(.024, .010)
	floor.mesh = plane; var ground := StandardMaterial3D.new(); ground.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.albedo_color = Color("8a8c70"); floor.material_override = ground; scene.add_child(floor)
	var camera := Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = .0075; camera.near = .00005; camera.far = .1; scene.add_child(camera)
	camera.position = Vector3(0, .006, .012); camera.look_at(Vector3(0, .0006, 0)); camera.make_current()
	var layer := CanvasLayer.new(); viewport.add_child(layer)
	var heading := _make_label(layer, 23); heading.position = Vector2(25, 18)
	heading.text = "TEST ASSET DETAIL | Five production yard meshes | metre scale\nSeparate review scene; not a campaign checkpoint or invented fishing settlement."
	var mesh_audit: Array = []
	for index in YardMeshes.KINDS.size():
		var kind: String = YardMeshes.KINDS[index]
		var prop := MeshInstance3D.new(); prop.mesh = YardMeshes.mesh(kind); prop.material_override = YardInk.material()
		prop.scale = Vector3.ONE * .001; prop.position = Vector3((float(index) - 2.0) * .004, .00003, 0); scene.add_child(prop)
		var label := _make_label(layer, 21); label.text = kind.replace("_", " ")
		var screen := camera.unproject_position(prop.position + Vector3(0, 0, .002))
		label.position = screen - Vector2(label.get_minimum_size().x * .5, 0)
		mesh_audit.append({"kind": kind, "triangles": YardMeshes.triangles(kind), "height_m": YardMeshes.height_m(kind), "radius_m": YardMeshes.radius_m(kind)})
	for frame in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	report["mesh_assets"] = mesh_audit; viewport.queue_free(); await get_tree().process_frame
	return image
