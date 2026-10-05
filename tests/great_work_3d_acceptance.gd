extends Node
## Real Atlas/Director views, prepared in memory through the existing engine.
## No save, player window or network narration. Capture via private desktop only.
const Fixture = preload("res://tests/great_works_experience_probe.gd")
const GW = preload("res://scripts/great_works.gd")
const U = preload("res://scripts/undertaking_system.gd")
const Concept = preload("res://scripts/wonder_concept.gd")
const Atlas = preload("res://scripts/hud/great_works_atlas.gd")
const Director = preload("res://scripts/audience_director.gd")
const Pause = preload("res://scripts/hud/simulation_pause.gd")
const T = preload("res://scripts/hud/hud_tokens.gd")

class Host extends Node:
	var game_speed := 1.0
	var capture_render_active := false
	func _set_game_speed(speed: float) -> void: game_speed = speed
	func _blocking_modal_or_report_open() -> bool: return false

var capture := false
var require_3d := false
var out := "res://artifacts/great-work-3d"
var only_case := ""
var checks := 0
var failures: Array[String] = []
var report := {"seed": 515151, "cases": [], "checks": [], "idle_viewports": []}
var host: Host
var director: Node
var city: Dictionary
var work: Dictionary

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--great-work-acceptance") or not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)) or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		printerr("Requires --great-work-acceptance and an isolated acceptance userdata override.")
		get_tree().quit(2)
		return
	capture = args.has("--capture")
	require_3d = args.has("--require-3d")
	for arg in args:
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--case="): only_case = arg.trim_prefix("--case=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	var cases := [
		{"id":"01-early-foundations", "era":"early", "fraction":.03},
		{"id":"02-early-raising", "era":"early", "fraction":.45, "live":true, "initial_speed":0.0},
		{"id":"03-early-crowning", "era":"early", "fraction":.82},
		{"id":"04-stalled", "era":"early", "fraction":.45, "state":"stalled"},
		{"id":"05-ruin", "era":"early", "fraction":1.0, "state":"ruined"},
		{"id":"06-middle-building", "era":"middle", "fraction":.60},
		{"id":"07-future-building", "era":"future", "fraction":.60},
		{"id":"08-completed", "era":"future", "fraction":.999999, "state":"complete"},
		{"id":"09-early-dedication", "era":"early", "ceremony":true, "mode":"offering"},
		{"id":"10-ribbon-dedication", "era":"industrial", "ceremony":true, "mode":"ribbon"},
		{"id":"11-future-dedication", "era":"future", "ceremony":true, "mode":"illumination"},
		{"id":"12-narrow-dedication", "era":"middle", "ceremony":true, "mode":"unveiling", "narrow":true, "dark":true}]
	for spec: Dictionary in cases:
		if not only_case.is_empty() and String(spec.id) not in only_case.split(","): continue
		await _prepare(spec)
		if work.is_empty(): continue
		if bool(spec.get("ceremony", false)): await _ceremony_case(spec)
		else: await _atlas_case(spec)
	await _clear()
	_check(not report.cases.is_empty(), "At least one named case ran")
	report["passed"] = checks - failures.size()
	report["total"] = checks
	report["failures"] = failures
	report["requires_3d"] = require_3d
	report["display"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	var path := out.path_join("capture.json" if capture else "functional.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "  "))
	print("GREAT_WORK_3D_ACCEPTANCE ", JSON.stringify({"passed":report.passed, "total":checks, "failures":failures, "report":path}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _clear() -> void:
	if is_instance_valid(director): director.queue_free()
	if is_instance_valid(host): host.queue_free()
	await _frames(4)

func _prepare(spec: Dictionary) -> void:
	print("GREAT_WORK_CASE ", spec.id)
	await _clear()
	# Reuse the existing experience probe's established founder/contact fixture,
	# without adding that probe to the tree or invoking its automatic test run.
	var fixture := Fixture.new()
	fixture._setup_world()
	city = fixture.city
	fixture.free()
	GameState.water_metrics = {"intake_ratio":1.0}
	GameState.population_allocations["Construction"] = 80
	GameState.population_allocations["Crafting"] = 24
	var era := String(spec.era)
	GameState.known_discoveries.clear()
	GameState.discovery_adoption.clear()
	var known: Array = []
	if era == "middle": known = ["masonry_bond_patterns", "joinery", "seasonal_patterns", "masonry_buttressing", "fitted_tailoring", "broad_treadle_loom"]
	if era == "industrial": known = ["masonry_bond_patterns", "joinery", "steel_refining", "rotative_steam_engine", "sewing_machine_mechanisms"]
	if era == "future": known = ["masonry_bond_patterns", "joinery", "steel_refining", "clinker_cement", "concrete_mix_design", "electrical_generators", "radio_broadcasting", "garment_size_grading", "solid_state_lighting"]
	for id: String in known:
		GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id] = 1.0
	DiscoverySystem.refresh_operating_effects()
	GameState.elapsed_days = 12.0 if era == "early" else float({"middle":2000,"industrial":2700,"future":3000}[era]) * 365.0
	for resource in ["Stone", "Timber", "Clay", "Fiber Plants", "Coal", "Iron Ore"]: GameState.resource_stockpiles[resource] = 60000.0
	var form := "ring" if era == "early" else ("observatory" if era == "middle" else "tower")
	var material := "concrete" if era == "future" else ("iron" if era == "industrial" else "stone")
	var tier := Concept.tier(GameState.known_discoveries)
	var id := Concept.make_id(form, "watch_heavens" if form == "observatory" else "bind_tribes", "modest", material, tier, "accept" + String(spec.id).left(2))
	var concept := {"id":id, "name":"The " + era.capitalize() + " Work", "lore":"A prepared acceptance commission, raised with this people's recorded skills."}
	var commissioned := GW.commission(String(city.id), concept, "modest", "player", func(_point:Vector2)->float:return 0.0, func(_point:Vector2)->bool:return true)
	_check(bool(commissioned.get("ok", false)), String(spec.id) + " commissions through the real capability/site gates: " + str(commissioned.get("error", "")))
	work = U.find(city, String(commissioned.get("id", "")))
	if work.is_empty(): return
	_check(Concept.parse(String(work.id)).tier == tier, String(spec.id) + " preserves the supported construction tier")
	# Explicit prepared elapsed construction. The engine still owns all state
	# changes tested below; this is not a simulated multi-century campaign.
	work.progress = U.total_work(work) * float(spec.get("fraction", .999999))
	work.quality = float(work.progress)
	work.gates = ["design", "stores", "labor"]
	work.erase("decision")
	work.last_day = int(GameState.elapsed_days) - 1
	if spec.get("state", "") == "stalled":
		for resource in Concept.definition(String(work.id)).cost: GameState.resource_stockpiles[resource] = 0.0
		var before := U.fraction(work)
		U.advance_record(GameState, work, int(GameState.elapsed_days), city)
		_check(work.status == "stalled" and is_equal_approx(U.fraction(work), before), String(spec.id) + " genuinely stalls without materials")
	elif spec.get("state", "") == "ruined":
		U.apply_outcome(GameState, work, city, int(GameState.elapsed_days), "collapse")
		_check(work.status == "ruined" and GW.pending_ceremonies().is_empty(), String(spec.id) + " collapse creates a ruin without dedication")
	elif spec.get("state", "") == "complete" or spec.get("ceremony", false):
		# Finish the last fraction through the daily engine; outcome remains its
		# seeded decision, never a visual-only status flag.
		U.advance_record(GameState, work, int(GameState.elapsed_days), city)
		_check(work.status == "functioning", String(spec.id) + " daily engine completes a standing work: " + String(work.get("outcome", "")))
	else:
		U.advance_record(GameState, work, int(GameState.elapsed_days), city)
		_check(work.status == "building" and float(work.get("last_work",0)) > 0, String(spec.id) + " actual daily work supplies active crews")
	T.set_color_mode("dark" if spec.get("dark", false) else "light")
	get_window().size = Vector2i(1138,640) if spec.get("narrow", false) else Vector2i(1920,1080)
	host = Host.new()
	host.game_speed = float(spec.get("initial_speed", 1.0))
	add_child(host)
	director = Director.new()
	director.terrain = host
	add_child(director)
	director.voice.force_offline = true
	director.set_process(false)
	await _frames(3)

func _atlas_case(spec: Dictionary) -> void:
	var view := Atlas.open(host, host, director, "player/%s/%s" % [String(city.id), String(work.id)])
	await _frames(10)
	_check(host.game_speed == 0.0 and Pause.blocks(host), String(spec.id) + " Atlas owns its simulation pause")
	var status := view.find_child("StatusLine", true, false) as Label
	_check(status != null and not status.text.is_empty(), String(spec.id) + " reads the actual work status")
	_check(Rect2(Vector2.ZERO, Vector2(get_window().size)).encloses(view.panel.get_global_rect()), String(spec.id) + " Atlas fits the viewport")
	var model := view.find_child("DetailModel", true, false)
	var metrics: Dictionary = {}
	if require_3d:
		_check(model != null and model.has_method("report"), String(spec.id) + " mounts the actual retained 3D view")
	if model != null and model.has_method("report"):
		metrics = model.report()
		_check(model.model_root != null and model.find_children("*", "MeshInstance3D", true, false).size() > 0, String(spec.id) + " has actual mesh geometry")
		_check(is_equal_approx(float(metrics.progress), U.fraction(work)), String(spec.id) + " 3D progress matches the engine")
		_check(int(metrics.worker_count) <= 6 and (int(metrics.worker_count) > 0 if work.status == "building" else int(metrics.worker_count) == 0), String(spec.id) + " bounded crew follows actual daily work and status")
		var root_id: int = model.model_root.get_instance_id()
		var before: int = int(metrics.builds)
		model.orbit_by(Vector2(55,-12))
		model.zoom_by(1.0)
		await _frames(4)
		_check(model.model_root.get_instance_id() == root_id and int(model.report().builds) == before, String(spec.id) + " orbit and zoom retain geometry")
		var idle: int = int(model.report().viewport_updates)
		await _frames(20)
		_check(int(model.report().viewport_updates) == idle, String(spec.id) + " paused idle view does not request redraws")
		if DisplayServer.get_name() != "headless":
			# SubViewport's getter retains the requested UPDATE_ONCE value; the
			# render server disables its own state. Verify actual rendered pixels.
			await RenderingServer.frame_post_draw
			var frozen: PackedByteArray = model.viewport.get_texture().get_image().get_data()
			model.model_root.visible = false
			await _frames(4)
			await RenderingServer.frame_post_draw
			var slept: bool = frozen == model.viewport.get_texture().get_image().get_data()
			model.orbit_by(Vector2(1,0))
			await _frames(4)
			await RenderingServer.frame_post_draw
			var woke: bool = frozen != model.viewport.get_texture().get_image().get_data()
			report.idle_viewports.append({"id":spec.id,"pixels_unchanged_without_request":slept,"pixels_changed_after_request":woke})
			_check(slept and woke, String(spec.id) + " GPU freezes idle pixels and redraws only after an explicit view request")
			model.model_root.visible = true
			model.orbit_by(Vector2(-1,0))
			await _frames(4)
		model.reset_view()
	if bool(spec.get("live", false)) and require_3d:
		var watch := view.find_child("WatchLive", true, false) as Button
		_check(watch != null, String(spec.id) + " exposes watching through the existing clock")
		if watch != null:
			var before_live: Dictionary = model.report() if is_instance_valid(model) else {}
			var live_root: int = model.model_root.get_instance_id() if is_instance_valid(model) else 0
			watch.pressed.emit()
			await _frames(3)
			_check(host.game_speed == (3.0 if float(spec.get("initial_speed",1.0)) == 0.0 else float(spec.get("initial_speed",1.0))), String(spec.id) + " watching uses Normal from pause or preserves the original pace")
			GameState.elapsed_days += 1.0
			U.advance_record(GameState, work, int(GameState.elapsed_days), city)
			await get_tree().create_timer(.7).timeout
			if is_instance_valid(model):
				_check(is_equal_approx(float(model.report().progress), U.fraction(work)), String(spec.id) + " watching updates from real daily progress")
				if int(model.report().course) == int(before_live.course):
					_check(int(model.report().builds) == int(before_live.builds) and model.model_root.get_instance_id() == live_root, String(spec.id) + " daily progress within a course retains geometry")
			watch.pressed.emit()
			await _frames(3)
			_check(host.game_speed == 0.0, String(spec.id) + " stopping watch restores the Atlas pause")
	if is_instance_valid(model) and model.has_method("report"): metrics = model.report()
	await _capture(String(spec.id))
	report.cases.append({"id":spec.id, "state":work.status, "year":floori(GameState.elapsed_days/365.0), "stage":U.stage_of(work), "progress":U.fraction(work), "concept":Concept.parse(String(work.id)), "model":metrics})
	view.close()
	await _frames(4)
	_check(host.game_speed == float(spec.get("initial_speed",1.0)) and not Pause.blocks(host), String(spec.id) + " closing restores the original speed and pause ownership")

func _ceremony_case(spec: Dictionary) -> void:
	var pending: Dictionary = {}
	for entry: Dictionary in GW.pending_ceremonies():
		if entry.work_id == work.id: pending = entry
	_check(not pending.is_empty(), String(spec.id) + " completion produces a real pending dedication")
	if pending.is_empty(): return
	var before := _economy()
	director._offer_ceremony()
	_check(not is_instance_valid(director.ceremony), String(spec.id) + " offers completion without opening an unsolicited ceremony")
	var view: Control = director.open_ceremony(String(work.id))
	_check(view != null, String(spec.id) + " opens through the actual AudienceDirector")
	if view == null: return
	await _frames(8)
	view.skip_reveal()
	await _frames(5)
	_check(host.game_speed == 0.0 and Pause.blocks(host), String(spec.id) + " ceremony pauses simulation")
	_check(_economy() == before, String(spec.id) + " preview gives no gifts or rewards")
	var diagnostics: Dictionary = {}
	if require_3d: _check(view.plate.has_method("diagnostics"), String(spec.id) + " presents the actual 3D ceremonial stage")
	if view.plate.has_method("diagnostics"):
		diagnostics = view.plate.diagnostics()
		_check(int(diagnostics.mesh_count) > 0 and int(diagnostics.cast_count) <= 6, String(spec.id) + " bounds the real 3D cast and model")
		_check(int(diagnostics.cast_count) >= 2 and int(diagnostics.body_count) == int(diagnostics.cast_count), String(spec.id) + " mounts every recorded visual participant as a real court figure")
		_check(not diagnostics.committed and not diagnostics.viewport_active, String(spec.id) + " preview settles without a dedication or ongoing viewport draw")
		if spec.has("mode"): _check(String(diagnostics.mode) == String(spec.mode), String(spec.id) + " uses the appropriate dedication action")
	_check(Rect2(Vector2.ZERO, Vector2(get_window().size)).encloses(view.stage.get_global_rect()), String(spec.id) + " ceremony fits the viewport: " + str(view.stage.get_global_rect()))
	if require_3d:
		for control_name in ["NameInput", "Dedicate", "Later"]:
			var control := view.find_child(control_name, true, false) as Control
			_check(control != null and Rect2(Vector2.ZERO, Vector2(get_window().size)).encloses(control.get_global_rect()), String(spec.id) + " keeps " + control_name + " reachable")
	await _capture(String(spec.id) + "-before")
	if require_3d and String(spec.era) in ["early", "future"]:
		var whole := view.find_child("SeeWholeWork", true, false) as Button
		_check(whole != null, String(spec.id) + " offers the whole-work shot")
		if whole != null:
			whole.pressed.emit()
			view.plate.settle()
			_check(view.plate.diagnostics().camera_shot == "work", String(spec.id) + " whole-work camera uses the actual stage")
			await _capture(String(spec.id) + "-whole")
	view.close()
	await _frames(5)
	_check(host.game_speed == 1.0 and not Pause.blocks(host), String(spec.id) + " postponing releases its pause")
	_check(_economy() == before and not GW.pending_ceremonies().is_empty(), String(spec.id) + " postponing preserves the pending record")
	view = director.open_ceremony(String(work.id))
	await _frames(8)
	view.skip_reveal()
	var retained_model: int = int(view.plate.diagnostics().model_node_id) if view.plate.has_method("diagnostics") else 0
	var sums := _gift_totals(pending.attendees)
	var title := "The Accepted " + String(spec.era).capitalize() + " Work"
	var result: Dictionary = view.dedicate_with(title)
	_check(bool(result.get("ok", false)), String(spec.id) + " dedicates through the engine")
	_check(not result.get("gifts", []).is_empty(), String(spec.id) + " receives a real planned gift")
	await _frames(8)
	_check(work.get("ceremony", {}).get("status", "") == "dedicated" and U.display_name(work) == title, String(spec.id) + " records dedication and the chosen name")
	_check(_gift_totals(pending.attendees) == sums, String(spec.id) + " conserves gifts across real donor and recipient stores")
	var after := _economy()
	view.dedicate_with(title)
	var duplicate := GW.dedicate(String(city.id), String(work.id), title)
	_check(duplicate.has("error") and _economy() == after, String(spec.id) + " repeated UI and engine requests cannot deliver gifts twice")
	view.skip_reveal()
	if view.plate.has_method("diagnostics"):
		var after_stage: Dictionary = view.plate.diagnostics()
		_check(after_stage.committed and int(after_stage.model_node_id) == retained_model and not after_stage.viewport_active, String(spec.id) + " dedication settles its action while retaining the monument")
		diagnostics["after"] = after_stage
	if require_3d:
		var close_button := view.find_child("CloseCeremony", true, false) as Control
		_check(close_button != null and Rect2(Vector2.ZERO, Vector2(get_window().size)).encloses(close_button.get_global_rect()), String(spec.id) + " result close remains reachable")
	await _capture(String(spec.id) + "-after")
	report.cases.append({"id":spec.id, "year":floori(GameState.elapsed_days/365.0), "concept":Concept.parse(String(work.id)), "stage":diagnostics, "attendees":pending.attendees, "result":result})
	view.close()
	await _frames(5)
	_check(host.game_speed == 1.0 and not Pause.blocks(host), String(spec.id) + " final close releases its pause")
	_check(director.open_ceremony(String(work.id)) == null, String(spec.id) + " completed dedication cannot be reopened as pending")

func _economy() -> PackedByteArray:
	var stocks: Array = [GameState.resource_stockpiles, GameState.simulation_metrics, work]
	for owner in ["rival_a", "rival_b"]: stocks.append(U.owner_state(owner).resource_stockpiles)
	return var_to_bytes(stocks)

func _gift_totals(attendees: Array) -> Dictionary:
	var totals := {}
	for entry: Dictionary in attendees:
		var gift: Dictionary = entry.get("gift", {})
		if gift.is_empty(): continue
		var resource := String(gift.resource)
		var total := float(GameState.resource_stockpiles.get(resource, 0.0))
		for other: Dictionary in attendees: total += float(U.owner_state(String(other.civ_id)).resource_stockpiles.get(resource,0.0))
		totals[resource] = snappedf(total, .00001)
	return totals

func _frames(count: int) -> void:
	for frame in count: await get_tree().process_frame

func _capture(id: String) -> void:
	if not capture or DisplayServer.get_name() == "headless": return
	await _frames(4)
	await RenderingServer.frame_post_draw
	_check(get_viewport().get_texture().get_image().save_png(out.path_join(id + ".png")) == OK, "Capture saves " + id)

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.checks.append({"ok":ok, "message":message})
	if not ok:
		failures.append(message)
		printerr("GREAT_WORK_ACCEPTANCE_FAILED ", message)
