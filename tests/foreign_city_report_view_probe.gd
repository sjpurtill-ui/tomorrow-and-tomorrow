extends Node
## Isolated actual DockPanel/ForeignCity provider UI; prepared report, not a save.
## Run only through tools/run_isolated_gpu_probe.ps1 --foreign-city-report-view.
const Dock := preload("res://scripts/hud/dock_panel.gd")
const Provider := preload("res://scripts/hud/content/dock_detail_foreign_city.gd")
const Folio := preload("res://scripts/hud/reference_folio.gd")
const T := preload("res://scripts/hud/hud_tokens.gd")
const OUT := "res://artifacts/foreign-city-report-view"
var failures: Array[String] = []
var rows: Array = []
var city_id := ""
var region: Dictionary = {}

class ProbeHud extends Control:
	signal section_requested(section: String, sub: int)
	func request_immediate_dock_refresh() -> void: pass
	func open_detail(_provider: Object) -> void: pass

class PublicTerrain extends Node:
	var focused_city := ""
	## Explicit public topography fixture; no hidden demographic reads.
	func _height_at(x: float, z: float) -> float: return .0007 * x + .0012 * sin(z * 12.0)
	func _focus_known_city(id: String) -> void: focused_city = id

func _ready() -> void: call_deferred("_run")

func _run() -> void:
	if "--foreign-city-report-view" not in OS.get_cmdline_user_args() or not OS.get_user_data_dir().contains("TomorrowPeopleGrownLandQA"):
		push_error("Requires explicit probe flag and private QA userdata"); get_tree().quit(2); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for node: Node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	_prepare_report()
	for shape: Vector2i in [Vector2i(1907,658), Vector2i(1280,900), Vector2i(640,800)]:
		await _capture(shape)
	var audit := {"passed": failures.is_empty(), "failures": failures, "scope": "Prepared observed-city report rendered through actual ForeignCity provider and DockPanel; public terrain fixture; no campaign claim", "observed_population": 7600, "home_population": 18000, "age_days": 40, "city_id": city_id, "views": rows}
	FileAccess.open(OUT + "/audit.json", FileAccess.WRITE).store_string(JSON.stringify(audit, "  "))
	print("FOREIGN_CITY_REPORT_VIEW ", JSON.stringify(audit))
	get_tree().quit(0 if failures.is_empty() else 1)

func _prepare_report() -> void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242); GameState.civic_api_enabled = false
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); DiscoverySystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world(); ForeignDiplomacy.reset_for_new_world()
	GameState.initialize_population_model(); GameState.ensure_population_total(18000)
	GameState.settlement_name = "Wallyfire"; GameState.settlement_site_committed = true
	GameState.settlement_completed = ["Hearth Circle"]; SettlementModel.ensure_founded()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	CivilizationSystem.set_scout_geography_authority(func(_point: Vector2) -> bool: return true)
	GameState.elapsed_days = 1000
	var civ: Dictionary = CivilizationSystem.civilizations[0]
	civ.name = "The Eastern League of the Long River and High Valleys"
	civ.player_relation.contact_level = 2
	region = civ.strategic_regions[0]
	region.name = "Felik"; region.population = 7600.0
	region.position = CivilizationSystem.player_world_origin + Vector2(60, 0)
	city_id = String(region.id)
	var intel = CivilizationSystem.city_intelligence
	var record: Dictionary = intel.capture("player", city_id, .8, 960, "physical reconnaissance", "prepared-ui-fixture", 40, .8)
	var fields := {"population": Vector2(7600,7600), "garrison": Vector2(120,180), "fortification": Vector2(.3,.4), "production": Vector2(.4,.55), "logistics": Vector2(.35,.5), "supply": Vector2(35,55), "damage": Vector2(0,.025), "life_expectancy": Vector2(40,47)}
	record.name = "Felik"; record.fields = {}
	for key: String in fields:
		var value: Vector2 = fields[key]
		record.fields[key] = {"low": value.x, "high": value.y, "observed_day": 960, "quality": .8, "source": "physical reconnaissance", "reference": "prepared-ui-fixture"}
	intel.publish("player", record, 960)
	_check(not record.is_empty(), "Prepared report must be published")

func _capture(shape: Vector2i) -> void:
	var port := SubViewport.new(); port.size = shape
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(port)
	var backdrop := ColorRect.new(); backdrop.color = T.PAPER
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); port.add_child(backdrop)
	var hud := ProbeHud.new(); port.add_child(hud); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var terrain := PublicTerrain.new(); add_child(terrain)
	if shape.x == 640:
		CivilizationSystem.city_intelligence.records.player[city_id].name = "Felik at the Meeting of the Long River and the Eastern Valleys"
	var provider := Provider.new(terrain, hud, city_id)
	var dock := Dock.new(); dock.back_mode = true; hud.add_child(dock)
	dock.position = Vector2(Folio.RAIL_WIDTH, Folio.TOP_HEIGHT)
	dock.size = Vector2(Folio.page_width(shape.x), shape.y - Folio.TOP_HEIGHT)
	dock.present(provider, 0)
	for frame in 30: await get_tree().process_frame
	var viewer: Control = dock.find_child("ReportedCityView", true, false)
	_check(viewer != null, "Actual dock must contain ReportedCityView at " + str(shape))
	if viewer == null:
		port.queue_free(); terrain.queue_free(); await get_tree().process_frame; return
	var picture: TextureRect = viewer.get("picture")
	var report_view: SubViewport = viewer.get("view")
	var model: Node3D = viewer.get("model")
	var camera: Camera3D = viewer.get("camera")
	var frozen: Dictionary = viewer.get("frozen_report")
	var before_stats: Dictionary = viewer.call("stats")
	var fingerprint := _geometry(model)
	var bounds := _house_bounds(model, camera)
	var outside: Rect2 = Rect2(Vector2.ZERO, Vector2(shape))
	_check(outside.grow(1).encloses(dock.get_global_rect()), "Dock must fit viewport " + str(shape))
	_check(dock.get_global_rect().encloses(dock.title_label.get_global_rect()), "Title must fit dock " + str(shape))
	_check(dock.body_scroll.get_global_rect().grow(1).encloses(picture.get_global_rect()), "City picture must be fully visible at initial scroll " + str(shape))
	_check(float(frozen.fields.population.low) == 7600.0 and float(frozen.fields.population.high) == 7600.0, "View must use observed population, not projected band")
	_check(int(before_stats.building_count) > 0 and int(before_stats.building_count) <= 128, "Representatives stay bounded")
	_check(int(before_stats.model_builds) == 1 and int(before_stats.height_samples) <= 1090, "One bounded model/height build")
	_check(int(before_stats.viewport_updates) > 0, "Visible report viewport must have rendered at " + str(shape))
	_check(_human_nodes(model) == 0, "Report must have no people")
	_check(int(bounds.central_visible) >= 6, "Default view must show central houses at " + str(shape))
	var own := provider.home(provider.report())
	_check(is_equal_approx(float((own.get("values", {}) as Dictionary).get("population", 0)), 18000.0), "Home comparison must use18000")
	await RenderingServer.frame_post_draw
	var stem := "report-%dx%d" % [shape.x, shape.y]
	port.get_texture().get_image().save_png(OUT + "/" + stem + ".png")
	if shape.x == 1907:
		report_view.get_texture().get_image().save_png(OUT + "/reported-city-native.png")
		port.get_texture().get_image().get_region(Rect2i(dock.get_global_rect())).save_png(OUT + "/report-dock-detail.png")
	# Neither an unseen population change nor an idle frame may rebuild evidence.
	region.population = 76000.0; region.damage = .9
	for frame in 30: await get_tree().process_frame
	var idle_stats: Dictionary = viewer.call("stats")
	_check(_geometry(model) == fingerprint, "Hidden live changes must not move current report geometry")
	_check(idle_stats.model_builds == before_stats.model_builds and idle_stats.viewport_updates == before_stats.viewport_updates, "Idle report must stop rebuilding and rendering")
	var whole: Button = viewer.find_child("WholeTown", true, false)
	var whole_bounds: Dictionary = {}
	var whole_stats: Dictionary = {}
	_check(whole != null, "Whole town control must be available")
	if whole != null:
		whole.pressed.emit()
		for frame in 10: await get_tree().process_frame
		whole_bounds = _house_bounds(model, camera)
		whole_stats = viewer.call("stats")
		_check(bool(whole_bounds.fits), "Whole town must fit all house bounds at " + str(shape))
		_check(int(whole_stats.viewport_updates) > int(idle_stats.viewport_updates), "Whole town action must render its changed camera")
		_check(whole_stats.model_builds == before_stats.model_builds and _geometry(model) == fingerprint, "Whole town action changes framing without rebuilding houses")
		if shape.x == 1907:
			await RenderingServer.frame_post_draw
			report_view.get_texture().get_image().save_png(OUT + "/reported-city-whole.png")
	var stored_fingerprint := str(fingerprint).sha256_text()
	dock.rebuild_body()
	for frame in 15: await get_tree().process_frame
	var rebuilt: Control = dock.find_child("ReportedCityView", true, false)
	_check(rebuilt != null, "Refreshed dock retains report viewer")
	if rebuilt != null:
		_check(_geometry(rebuilt.get("model")) == fingerprint, "Reopened report geometry must ignore hidden truth")
		var visit: Button = rebuilt.find_child("VisitReportedCity", true, false)
		_check(visit != null, "Map visit action remains reachable")
		if visit != null: visit.pressed.emit(); _check(terrain.focused_city == city_id, "Map visit must focus exact reported city")
	rows.append({"size": str(shape), "dock": str(dock.get_global_rect()), "picture": str(picture.get_global_rect()) if is_instance_valid(picture) else "replaced", "native_viewport": str(report_view.size) if is_instance_valid(report_view) else "replaced", "stats": before_stats, "idle_stats": idle_stats, "house_bounds": bounds, "display_median_house_width_px": float(bounds.median_width_pixels) * picture.size.x / float(report_view.size.x) if is_instance_valid(picture) and is_instance_valid(report_view) else -1, "whole_town_bounds": whole_bounds, "whole_town_stats": whole_stats, "geometry_fingerprint": stored_fingerprint, "image": OUT + "/" + stem + ".png"})
	port.queue_free(); terrain.queue_free(); await get_tree().process_frame

func _geometry(node: Node) -> Array:
	var result: Array = []
	if node is MultiMeshInstance3D:
		var batch: MultiMesh = node.multimesh
		var poses: Array = []
		for index in batch.instance_count: poses.append([batch.get_instance_transform(index), batch.get_instance_color(index) if batch.use_colors else Color.WHITE])
		result.append(["batch", node.transform, batch.instance_count, _mesh_hash(batch.mesh), poses])
	elif node is MeshInstance3D:
		result.append(["mesh", node.transform, _mesh_hash(node.mesh)])
	for child: Node in node.get_children(): result.append_array(_geometry(child))
	return result

func _mesh_hash(mesh: Mesh) -> Array:
	var result: Array = []
	if mesh == null: return result
	for surface in mesh.get_surface_count(): result.append(hash(mesh.surface_get_arrays(surface)))
	return result

func _house_bounds(model: Node3D, camera: Camera3D) -> Dictionary:
	var low := Vector2(INF,INF); var high := Vector2(-INF,-INF); var behind := false; var count := 0
	var size: Vector2 = camera.get_viewport().get_visible_rect().size
	var screen := Rect2(Vector2.ZERO, size).grow(-2)
	var houses: Array[Dictionary] = []
	var widths: Array[float] = []
	for child: Node in model.get_children():
		if not child is MultiMeshInstance3D or not String(child.name).begins_with("ForeignHouses_"): continue
		var batch: MultiMesh = child.multimesh
		for index in batch.instance_count:
			var pose: Transform3D = child.global_transform * batch.get_instance_transform(index)
			var house_low := Vector2(INF,INF); var house_high := Vector2(-INF,-INF)
			for corner in 8:
				var point: Vector3 = pose * batch.mesh.get_aabb().get_endpoint(corner)
				var projected: Vector2 = camera.unproject_position(point)
				behind = behind or camera.is_position_behind(point)
				low = low.min(projected); high = high.max(projected)
				house_low = house_low.min(projected); house_high = house_high.max(projected)
			var visible_house := screen.encloses(Rect2(house_low,house_high-house_low))
			houses.append({"distance": Vector2(pose.origin.x,pose.origin.z).length_squared(), "visible": visible_house})
			if visible_house: widths.append(house_high.x-house_low.x)
			count += 1
	houses.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	var central_visible := 0
	for index in mini(12, houses.size()):
		if bool(houses[index].visible): central_visible += 1
	widths.sort()
	return {"instances": count, "central_visible": central_visible, "visible_instances": widths.size(), "median_width_pixels": widths[widths.size()/2] if not widths.is_empty() else 0.0, "low": str(low), "high": str(high), "viewport": str(size), "fits": count > 0 and not behind and screen.encloses(Rect2(low,high-low))}

func _human_nodes(node: Node) -> int:
	var count := 1 if node is Skeleton3D or node is AnimationPlayer else 0
	for child: Node in node.get_children(): count += _human_nodes(child)
	return count

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
