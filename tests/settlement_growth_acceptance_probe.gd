extends Node
## Isolated prepared-history acceptance of the live settlement refresh path.
## No quicksave is read. Capture mode is deliberately separate from timing mode.
const Fixture = preload("res://tests/city_evolution_visual_fixture.gd")
const Ink = preload("res://scripts/settlement_ink.gd")
const Ground = preload("res://scripts/settlement_grounds.gd")
const MAX_DRAIN_FRAMES := 240
const SAMPLE_FRAMES := 45

class Terrain extends Fixture.FlatRenderer:
	func _process(_delta: float) -> void: pass

var terrain: Node3D
var camera: Camera3D
var title: Label
var failures: Array[String] = []
var checks: int = 0
var capture := false
var output := "res://artifacts/settlement-growth"
var report: Dictionary = {"fixture_seed": 625114, "stages": [], "checks": [], "scope": "Prepared settlement records through the live footprint and patch queue; flat terrain; no saved campaign or full simulation benchmark."}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--settlement-growth-acceptance"):
		printerr("Requires --settlement-growth-acceptance and isolated test userdata.")
		get_tree().quit(2)
		return
	capture = OS.get_cmdline_user_args().has("--capture")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	report["mode"] = "capture" if capture else "timing"
	report["display"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	report["viewport"] = str(get_viewport().get_visible_rect().size)
	Fixture.initialize()
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	GameState.civic_api_enabled = false
	GameState.settlement_completed = ["Hearth Circle", "Lean-to Shelters", "Storage Pits"]
	GameState.initialize_population_model()
	var snapshot := Fixture.snapshot(3)
	GameState.settlement_plots.assign(snapshot.plots.slice(0, 4))
	GameState.settlement_routes.assign([snapshot.routes[0]])
	GameState.next_settlement_plot_id = 101
	GameState.settlement_nuclei = [{"id": 1, "position": Vector2.ZERO, "kind": "founding_hearth", "active": true}]
	GameState.city_form = {"tier": 3.0}
	SettlementModel.rebuild_summary()
	_setup_scene()
	if not terrain.has_method("settlement_patch_stats") or not terrain.has_method("_process_settlement_visual_jobs"):
		_check(false, "Live renderer provides persistent patch diagnostics and queue entry point")
		_finish()
		return
	if not SettlementModel.has_method("_new_fabric_tier"):
		_check(false, "Settlement model provides the supported new-construction generation policy")
		_finish()
		return
	if OS.get_cmdline_user_args().has("--stress-only"):
		report["run_scope"] = "stress-only diagnostic"
		await _stress_growth()
		if capture and OS.get_cmdline_user_args().has("--isolate-ground"): await _isolate_ground_layers()
		_finish()
		return
	var initial := await _refresh("01-old-quarter")
	var old_records := _record_geometry(GameState.settlement_plots)
	var old_nodes := _keys(initial)
	_check(not old_nodes.is_empty(), "Initial quarter installs persistent render patches")
	_check(not initial.get("plot_geometry", {}).is_empty(), "Initial quarter contains real plot meshes")
	await _sample_frames("initial-steady", false)

	# This is an explicitly prepared construction record, using the same plot
	# grammar and rendered history as the city-evolution fixture. Its new quarter
	# has a separate frontage and lies across a fixed spatial patch boundary.
	var adjoining := Fixture.plot(101, Vector2(.30, .02))
	adjoining["fabric_generation"] = int(GameState.settlement_plots[0].get("fabric_generation", 0))
	adjoining["form"] = GameState.settlement_plots[0].form
	adjoining["material_family"] = GameState.settlement_plots[0].material_family
	adjoining["roof_plan"] = GameState.settlement_plots[0].roof_plan
	adjoining["frontage_route_id"] = 101
	GameState.settlement_plots.append(adjoining)
	GameState.next_settlement_plot_id = 102
	GameState.settlement_routes.append(_route(101, .27, .35, .042))
	_changed()
	var grown := await _refresh("02-adjoining-quarter")
	_check(_record_geometry(GameState.settlement_plots.slice(0, 4)) == old_records, "Adjoining quarter preserves all original parcel geometry and construction records")
	_check(_retained_nodes(old_nodes, _keys(grown)) == _plot_node_count(old_nodes), "Adjoining growth retains every old-quarter plot patch")
	_check(initial.get("root_id", -1) == grown.get("root_id", -2), "Growth retains the live settlement root")
	_check(int(grown.get("builds", 0)) > int(initial.get("builds", 0)), "Adjoining growth installs new geometry")

	# Keep the inherited city; only newly commissioned construction adopts the
	# later supported generation. This calls the model's actual district creation
	# path at a reproducible adjoining site, then explicitly prepares completion.
	_prepare_later_capability()
	_changed()
	var aged := await _refresh("03-inherited-quarter-later-age")
	var recipe: Dictionary = SettlementModel._available_household_recipe()
	var contemporary_tier: int = SettlementModel.call("_new_fabric_tier", int(GameState.elapsed_days))
	var modern: Dictionary = SettlementModel._make_district_seed_plot(Vector2(.55, .02), .014, "mixed_household", recipe, int(GameState.elapsed_days), 2, contemporary_tier, 0)
	_check(not modern.is_empty(), "Contemporary district creation produces a construction record")
	if not modern.is_empty():
		_check(int(modern.get("fabric_generation", 0)) > int(adjoining.get("fabric_generation", 0)), "New household begins with the supported contemporary generation")
		modern["frontage_route_id"] = 102
		modern["status"] = "active"
		modern["construction_progress"] = 1.0
		modern["condition"] = .94
		GameState.settlement_plots.append(modern)
		GameState.settlement_routes.append(_route(102, .52, .60, .042))
	_changed()
	var later := await _refresh("04-later-construction")
	_check(_record_geometry(GameState.settlement_plots.slice(0, 4)) == old_records, "Later construction leaves inherited buildings and parcels unchanged")
	_check(_retained_nodes(_keys(aged), _keys(later)) == _plot_node_count(_keys(aged)), "Later construction retains every inherited plot patch")

	# Repair is a visual state mutation on a known existing record; other records
	# must retain geometry. This is not a war or adjudication fixture.
	adjoining["condition"] = .18
	adjoining["status"] = "damaged"
	adjoining["damage"] = {"structural": .8, "fire": .3}
	_changed()
	var damaged := await _refresh("05-damaged-building")
	_check(int(damaged.get("builds", 0)) > int(later.get("builds", 0)), "Damage changes the affected live appearance")
	_check(damaged.get("plot_geometry", {}) != later.get("plot_geometry", {}), "Damage changes actual plot mesh data")
	adjoining["condition"] = .94
	adjoining["status"] = "active"
	adjoining["damage"] = {}
	_changed()
	var repaired := await _refresh("06-repaired-building")
	_check(int(repaired.get("builds", 0)) > int(damaged.get("builds", 0)), "Repair changes the affected live appearance")
	_check(repaired.get("plot_geometry", {}) != damaged.get("plot_geometry", {}), "Repair changes actual plot mesh data")
	_check(_retained_nodes(_keys(damaged), _keys(repaired)) > 0, "Repair retains unrelated live patch nodes")
	await _sample_frames("paused-camera-pan-zoom", true)
	await _era_matrix()
	await _stress_growth()
	if capture and OS.get_cmdline_user_args().has("--isolate-ground"):
		await _isolate_ground_layers()
	_finish()

func _isolate_ground_layers() -> void:
	var keys := _keys(_stats())
	var material: ShaderMaterial = terrain.detail_terrain_patch.material_override
	var frames = material.get_shader_parameter("sg_frames")
	var halos = material.get_shader_parameter("sg_halos")
	for mode in ["no-stage", "no-props", "no-shared", "no-ground-frames", "no-ground-halos", "no-ground-texture"]:
		material.set_shader_parameter("sg_frames", frames)
		material.set_shader_parameter("sg_halos", halos)
		for key in keys:
			var node := instance_from_id(int(keys[key].node_id)) as Node3D
			if key == "stage": node.visible = mode not in ["no-stage", "no-shared"]
			if key == "props": node.visible = mode not in ["no-props", "no-shared"]
		if mode in ["no-ground-frames", "no-ground-halos", "no-ground-texture"]:
			var empty := PackedVector4Array()
			empty.resize(8)
			if mode != "no-ground-halos": material.set_shader_parameter("sg_frames", empty)
			if mode != "no-ground-frames": material.set_shader_parameter("sg_halos", empty)
		title.text = "TEST · Diagnostic layer isolation · " + mode
		for frame in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("isolation-" + mode + ".png"))
	material.set_shader_parameter("sg_frames", frames)
	material.set_shader_parameter("sg_halos", halos)


func _stress_growth() -> void:
	# Cross the actual detailed-layout boundary, retaining the original records
	# while prepared completed districts fill neighboring spatial patches.
	GameState.known_discoveries.clear()
	GameState.discovery_adoption.clear()
	_prepare_later_capability()
	GameState.next_settlement_plot_id = 1
	GameState.settlement_plots.clear()
	GameState.settlement_routes.clear()
	Ground.clear()
	var generation: int = SettlementModel.call("_new_fabric_tier", int(GameState.elapsed_days))
	var recipe: Dictionary = SettlementModel._available_household_recipe()
	var previous: Dictionary = {}
	var records_before := PackedByteArray()
	var stress: Array = []
	camera.size = .80
	camera.position = Vector3(.58, .55, .68)
	camera.look_at(Vector3(.25, 0, .24))
	terrain.camera_target = Vector3(.25, 0, .24)
	Ink.set_pixel(camera.size / get_viewport().get_visible_rect().size.y)
	for count in [96, 128, 129]:
		var before_count := GameState.settlement_plots.size()
		var old_plots := GameState.settlement_plots.duplicate(true)
		for index in range(before_count, count):
			var row: int = index / 12
			var at := Vector2(.04 + (index % 12) * .039, .04 + row * .039)
			var route_id := 300 + row
			if index % 12 == 0: GameState.settlement_routes.append(_route(route_id, .018, .50, at.y + .020))
			var plot: Dictionary = SettlementModel._make_district_seed_plot(at, .014, "mixed_household", recipe, int(GameState.elapsed_days), 2, generation, index)
			plot["frontage_route_id"] = route_id
			plot["status"] = "active"
			plot["construction_progress"] = 1.0
			plot["condition"] = .94
			GameState.settlement_plots.append(plot)
		_changed()
		var current := await _refresh("stress-%03d-plots" % count)
		_check(not current.get("plot_geometry", {}).is_empty(), "%d-plot specimen has live geometry" % count)
		if not previous.is_empty():
			_check(_record_geometry(GameState.settlement_plots.slice(0, before_count)) == records_before, "%d-plot growth preserves existing parcel and construction records" % count)
			# Both additions cross a complete stable ID shard, so no new plot
			# shares an old patch. Hidden cached specimens do not count.
			_check(_retained_nodes(_keys(previous), _keys(current)) == _plot_node_count(_keys(previous)), "%d-plot growth retains every inherited active plot patch" % count)
			stress.append({"plots": count, "changed_existing_plot_patches": _changed_plot_nodes(_keys(previous), _keys(current)), "retained_plot_patches": _retained_nodes(_keys(previous), _keys(current)), "new_plot_patches": _plot_node_count(_keys(current)) - _plot_node_count(_keys(previous)), "inherited_record_changes": _record_changes(old_plots, GameState.settlement_plots)})
		previous = current
		records_before = _record_geometry(GameState.settlement_plots)
	# Repair the first parcel past the legacy128-parcel detailed-layout limit.
	var repaired: Dictionary = GameState.settlement_plots[-1]
	repaired["status"] = "damaged"
	repaired["condition"] = .16
	repaired["damage"] = {"structural": .8, "fire": .4}
	_changed()
	var damaged := await _refresh("stress-129-damaged")
	repaired["status"] = "active"
	repaired["condition"] = .94
	repaired["damage"] = {}
	_changed()
	var restored := await _refresh("stress-129-repaired")
	var changed := _changed_plot_nodes(_keys(damaged), _keys(restored))
	_check(changed > 0, "Repair beyond128 detailed plots refreshes an affected plot patch")
	_check(changed < _plot_node_count(_keys(damaged)), "Single repair at129 plots leaves unrelated plot patches installed")
	_check(damaged.get("plot_geometry", {}) != restored.get("plot_geometry", {}), "Repair at129 plots changes actual mesh data")
	_check(_record_geometry(GameState.settlement_plots) == records_before, "Repair at129 plots preserves parcel geometry and building generation")
	stress.append({"plots": 129, "repair_changed_plot_patches": changed, "repair_retained_plot_patches": _retained_nodes(_keys(damaged), _keys(restored))})
	report["stress_growth"] = stress
	await _sample_frames("stress-129-steady", false)

func _era_matrix() -> void:
	# Independent capability specimens spanning the entire supported history.
	# Time alone is insufficient: all inputs to the model's actual selector are
	# supplied and recorded, and knowledge is limited to eligible catalogue dates.
	var years := [0, 1, 3, 10, 25, 40, 80, 125, 175, 300, 600, 2600, 3000]
	var rows: Array = []
	GameState.settlement_nuclei = [{"id": 1, "position": Vector2.ZERO, "active": true}, {"id": 2, "position": Vector2(.27, .02), "active": true}]
	GameState.population_allocations["Construction"] = 100
	GameState.population_allocations["Crafting"] = 1000
	GameState.population_allocations["Logistics"] = 700
	GameState.population_allocations["Administration"] = 400
	GameState.simulation_metrics["labor_efficiency"] = .9
	GameState.simulation_metrics["logistics"] = .9
	for generation in years.size():
		# These are independent specimens, unlike the persistent main sequence.
		Ground.clear()
		var year: int = years[generation]
		GameState.elapsed_days = year * 365.0
		GameState.settlement_completed.assign(["Hearth Circle"] if generation == 0 else ["Hearth Circle", "Lean-to Shelters", "Storage Pits"])
		GameState.city_form = {"tier": float(generation), "condition": .9}
		GameState.known_discoveries.clear()
		GameState.discovery_adoption.clear()
		for entry: Dictionary in DiscoverySystem.catalog:
			if float(entry.get("earliest_year", INF)) > year: continue
			var id := String(entry.get("id", ""))
			if id.is_empty(): continue
			GameState.known_discoveries.append(id)
			GameState.discovery_adoption[id] = 1.0
		DiscoverySystem.refresh_operating_effects()
		var chosen: int = SettlementModel.call("_new_fabric_tier", int(GameState.elapsed_days))
		var recipe: Dictionary = SettlementModel._available_household_recipe()
		var plot: Dictionary = SettlementModel._make_district_seed_plot(Vector2(.27, .02), .02, "mixed_household", recipe, int(GameState.elapsed_days), 2, chosen, 0)
		plot["status"] = "active"
		plot["construction_progress"] = 1.0
		plot["condition"] = .94
		plot["frontage_route_id"] = 103
		GameState.settlement_plots.assign([plot])
		GameState.settlement_routes.assign([_route(103, .24, .30, .044)])
		_changed()
		camera.size = .16
		camera.position = Vector3(.34, .10, .14)
		camera.look_at(Vector3(.27, 0, .02))
		terrain.camera_target = Vector3(.27, 0, .02)
		Ink.set_pixel(camera.size / get_viewport().get_visible_rect().size.y)
		var stats := await _refresh("era-%02d-year-%04d" % [generation, year])
		_check(chosen == generation, "Year %d capability fixture selects generation %d through actual model policy" % [year, generation])
		_check(int(plot.get("fabric_generation", -1)) == chosen, "Era %d construction preserves the model-selected generation" % generation)
		_check(not stats.get("plot_geometry", {}).is_empty(), "Era %d has actual live plot geometry" % generation)
		_check(int(stats.get("building_instances", 0)) + int(stats.get("fallback_roof_vertices", 0)) > 0, "Era %d renders a building or roof, beyond parcel ground alone" % generation)
		rows.append({"year": year, "requested_generation": generation, "selected_generation": chosen, "form": plot.get("form", ""), "kit_kind": Fixture.Kit.kind(plot), "style": Fixture.Kit.style_for(plot), "storeys": plot.get("storeys", 1), "building_instances": stats.get("building_instances", 0), "fallback_roof_vertices": stats.get("fallback_roof_vertices", 0), "eligible_known_discoveries": GameState.known_discoveries.size(), "capability_inputs": SettlementModel.fabric_era_inputs(), "rendered_plot_patches": stats.get("plot_geometry", {})})
	report["era_matrix"] = rows

func _setup_scene() -> void:
	terrain = Terrain.new()
	add_child(terrain)
	terrain.settler_marker = Area3D.new()
	terrain.add_child(terrain.settler_marker)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = .80
	camera.near = .0001
	camera.far = 5.0
	camera.position = Vector3(.43, .50, .65)
	add_child(camera)
	camera.look_at(Vector3(.27, 0, .02))
	camera.make_current()
	terrain.camera = camera
	terrain.camera_target = Vector3(.27, 0, .02)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("c9c8b0")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .8
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = .9
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2, 2)
	ground.mesh = plane
	var mask := Image.create(2, 2, false, Image.FORMAT_RGB8)
	mask.fill(Color.WHITE)
	terrain.discovery_mask_texture = ImageTexture.create_from_image(mask)
	ground.material_override = terrain._create_terrain_material()
	ground.position.y = -.0001
	add_child(ground)
	# The flat specimen supplies an installed detail surface so exercising the
	# live LOD/camera path cannot enqueue unrelated terrain generation.
	terrain.detail_terrain_patch = ground
	title = Label.new()
	title.position = Vector2(26, 22)
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color("26302b")
	add_child(title)
	Ink.set_pixel(camera.size / get_viewport().get_visible_rect().size.y)

func _prepare_later_capability() -> void:
	GameState.elapsed_days = 40.0 * 365.0
	GameState.city_form = {"tier": 5.0, "condition": .9}
	GameState.population_allocations["Construction"] = 12
	GameState.population_allocations["Crafting"] = 36
	GameState.population_allocations["Logistics"] = 20
	GameState.population_allocations["Administration"] = 4
	GameState.simulation_metrics["labor_efficiency"] = .72
	GameState.simulation_metrics["logistics"] = .9
	for id: String in ["clay_shaping", "stone_selection"]:
		if id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id] = 1.0
	DiscoverySystem.refresh_operating_effects()
	GameState.resource_stockpiles = {"Clay": 10000.0, "Stone": 10000.0, "Timber": 10000.0, "Fiber Plants": 10000.0}

func _route(id: int, start: float, end: float, z: float) -> Dictionary:
	return {"id": id, "active": true, "kind": "street", "hierarchy": "lane", "surface_tier": 1, "width_m": 2.0, "condition": .9, "traffic": .8, "points": PackedVector2Array([Vector2(start, z), Vector2(end, z)])}

func _changed() -> void:
	GameState.morphology_revision += 1
	SettlementModel.rebuild_summary()

func _stats() -> Dictionary:
	return terrain.call("settlement_patch_stats").duplicate(true)

func _keys(stats: Dictionary) -> Dictionary:
	var active: Dictionary = {}
	var records: Dictionary = stats.get("keys", {})
	for key in records:
		if bool(records[key].get("visible", true)): active[key] = records[key]
	return active

func _retained_nodes(before: Dictionary, after: Dictionary) -> int:
	var retained := 0
	for key in before:
		if not String(key).begins_with("plots:"): continue
		if after.has(key) and before[key].get("node_id", -1) == after[key].get("node_id", -2): retained += 1
	return retained

func _plot_node_count(keys: Dictionary) -> int:
	var count := 0
	for key in keys:
		if String(key).begins_with("plots:"): count += 1
	return count

func _changed_plot_nodes(before: Dictionary, after: Dictionary) -> int:
	var count := 0
	for key in before:
		if not String(key).begins_with("plots:") or not after.has(key): continue
		if before[key].get("node_id", -1) != after[key].get("node_id", -2): count += 1
	return count

func _queued_geometry_retained(before: Dictionary, after: Dictionary) -> bool:
	# Matrix specimens may retire absent patches; patches still requested must
	# keep their installed node until the queued replacement has been built.
	for key in before:
		if after.has(key) and before[key].get("node_id", -1) != after[key].get("node_id", -2): return false
	return true

func _plot_geometry(stats: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys := _keys(stats)
	for key in keys:
		if not String(key).begins_with("plots:"): continue
		var node := instance_from_id(int(keys[key].get("node_id", 0))) as Node
		if not is_instance_valid(node): continue
		var payload: Array = []
		_collect_geometry(node, payload)
		if not payload.is_empty(): result[key] = hash(var_to_bytes(payload))
	return result

func _collect_geometry(node: Node, payload: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count(): payload.append(node.mesh.surface_get_arrays(surface))
	elif node is MultiMeshInstance3D and node.multimesh != null:
		payload.append(node.multimesh.buffer)
		if node.multimesh.mesh != null:
			for surface in node.multimesh.mesh.get_surface_count(): payload.append(node.multimesh.mesh.surface_get_arrays(surface))
	for child in node.get_children(): _collect_geometry(child, payload)

func _building_counts(node: Node) -> Vector2i:
	var result := Vector2i.ZERO
	if node is Node3D and not node.visible: return result
	if node is MultiMeshInstance3D and node.multimesh != null and (String(node.name).begins_with("EarlySettlement_") or String(node.name).begins_with("OrganicTown_") or String(node.name).begins_with("SettlementArchitecture_")):
		result.x += node.multimesh.instance_count
	if node is MeshInstance3D and node.mesh != null and String(node.name) == "PersistentRoofFabric":
		for surface in node.mesh.get_surface_count(): result.y += node.mesh.surface_get_array_len(surface)
	for child in node.get_children(): result += _building_counts(child)
	return result

func _record_geometry(plots: Array) -> PackedByteArray:
	var records: Array = []
	for plot: Dictionary in plots:
		records.append([plot.id, plot.polygon, plot.centroid, plot.form, plot.get("fabric_generation", 0), plot.material_family, plot.roof_plan])
	return var_to_bytes(records)

func _record_changes(before: Array, after: Array) -> Array:
	var changes: Array = []
	for index in before.size():
		var fields: Array[String] = []
		for key in after[index]:
			if var_to_bytes(before[index].get(key)) != var_to_bytes(after[index][key]): fields.append(String(key))
		if not fields.is_empty(): changes.append({"id": before[index].id, "fields": fields})
	return changes

func _refresh(label: String) -> Dictionary:
	title.text = "TEST · Persistent settlement growth\n" + label + " · prepared records · simulation paused"
	var ground_signature_before := Ground.signature
	var begin := Time.get_ticks_usec()
	terrain._refresh_settlement_footprint()
	var submit_ms := (Time.get_ticks_usec() - begin) / 1000.0
	var slices: Array[float] = []
	var max_builds_per_slice := 0
	var max_pending := 0
	var previous := _stats()
	var queued_checked := false
	# A prime-plan-only refresh can schedule drawing for the following refresh.
	for frame in MAX_DRAIN_FRAMES:
		begin = Time.get_ticks_usec()
		terrain._refresh_settlement_footprint()
		var queued := _stats()
		max_pending = maxi(max_pending, int(queued.get("pending", 0)))
		if not queued_checked and int(queued.get("pending", 0)) > 0 and not _keys(previous).is_empty() and not label.begins_with("era-") and label != "stress-096-plots":
			_check(_queued_geometry_retained(_keys(previous), _keys(queued)), label + " keeps old geometry attached while replacements are queued")
			queued_checked = true
		terrain.call("_process_settlement_visual_jobs")
		slices.append((Time.get_ticks_usec() - begin) / 1000.0)
		var current := _stats()
		max_builds_per_slice = maxi(max_builds_per_slice, int(current.get("builds", 0)) - int(previous.get("builds", 0)))
		previous = current
		await get_tree().process_frame
		if int(current.get("pending", 0)) == 0 and frame >= 2: break
	var stats := _stats()
	terrain._update_scale_lod()
	stats["plot_geometry"] = _plot_geometry(stats)
	stats["root_id"] = terrain.settlement_land_use_root.get_instance_id() if is_instance_valid(terrain.settlement_land_use_root) else 0
	var buildings := _building_counts(terrain.settlement_land_use_root)
	stats["building_instances"] = buildings.x
	stats["fallback_roof_vertices"] = buildings.y
	_check(int(stats.get("pending", -1)) == 0, label + " queue drains")
	_check(max_builds_per_slice <= 2, label + " executes at most two rebuild jobs per slice")
	_check(int(stats.get("cached", -1)) <= int(stats.get("cache_limit", -2)), label + " keeps the hidden geometry cache within its limit")
	var stage := {"label": label, "submit_ms": submit_ms, "slice_ms": _distribution(slices), "max_builds_per_slice": max_builds_per_slice, "max_pending": max_pending, "stats": stats, "plots": GameState.settlement_plots.size(), "routes": GameState.settlement_routes.size(), "memory_bytes": OS.get_static_memory_usage(), "draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)}
	stage["ground"] = Ground.report.duplicate(true)
	stage["ground_signature_before"] = ground_signature_before
	stage["ground_signature_after"] = Ground.signature
	stage["ground_signature_changed"] = ground_signature_before != Ground.signature
	if capture and DisplayServer.get_name() != "headless":
		for frame in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := output.path_join(label + ".png")
		_check(get_viewport().get_texture().get_image().save_png(path) == OK, "Capture saves " + label)
		stage["image"] = path
	report.stages.append(stage)
	return stats

func _sample_frames(label: String, move_camera: bool) -> void:
	# Ground streaming deliberately installs at most one tile per LOD update.
	# Finish the retained view's cold tiles before measuring its steady behavior.
	for frame in 4:
		terrain._update_scale_lod()
		await get_tree().process_frame
	var before := _stats()
	var ground_before := Ground.tile_builds
	var frames: Array[float] = []
	var refresh_cost: Array[float] = []
	for frame in SAMPLE_FRAMES:
		var started := Time.get_ticks_usec()
		if move_camera:
			camera.size = .76 + .08 * sin(float(frame) * .2)
			terrain.camera_target = Vector3(.27 + .008 * sin(float(frame) * .17), 0, .02)
			camera.position.x = .43 + .008 * sin(float(frame) * .17)
			camera.look_at(terrain.camera_target)
			Ink.set_pixel(camera.size / get_viewport().get_visible_rect().size.y)
		var begin := Time.get_ticks_usec()
		terrain._update_scale_lod()
		terrain._refresh_settlement_footprint()
		terrain.call("_process_settlement_visual_jobs")
		refresh_cost.append((Time.get_ticks_usec() - begin) / 1000.0)
		await get_tree().process_frame
		frames.append((Time.get_ticks_usec() - started) / 1000.0)
	var after := _stats()
	_check(int(after.get("builds", 0)) == int(before.get("builds", 0)), label + " performs zero geometry rebuilds in retained view")
	_check(_keys(before) == _keys(after), label + " retains every patch node and signature")
	_check(Ground.tile_builds == ground_before, label + " performs zero ground texture rebuilds in retained view")
	report.stages.append({"label": label, "frame_ms": _distribution(frames), "refresh_ms": _distribution(refresh_cost), "before": before, "after": after, "ground_builds_before": ground_before, "ground_builds_after": Ground.tile_builds, "ground_cache_hits": Ground.tile_cache_hits})

func _distribution(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted: total += value
	return {"samples": sorted.size(), "mean": total / sorted.size(), "p50": sorted[floori((sorted.size() - 1) * .50)], "p95": sorted[floori((sorted.size() - 1) * .95)], "max": sorted[-1]}

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.checks.append({"ok": ok, "message": message})
	if not ok:
		failures.append(message)
		printerr("SETTLEMENT_GROWTH_CHECK_FAILED ", message)

func _finish() -> void:
	report["failures"] = failures
	report["passed"] = checks - failures.size()
	report["total"] = checks
	var path := output.path_join("capture.json" if capture else "timing.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("SETTLEMENT_GROWTH_ACCEPTANCE ", JSON.stringify({"passed": checks - failures.size(), "total": checks, "failures": failures, "report": path, "mode": report.mode}))
	if is_instance_valid(terrain):
		terrain.settlement_fabric_shader = null
		terrain.free()
	get_tree().quit(0 if failures.is_empty() else 1)
