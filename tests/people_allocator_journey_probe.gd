extends "res://tests/people_portrait_journey_probe.gd"
## Actual HUD allocator journey. Uses the existing private-desktop fixture.
const Preview = preload("res://scripts/hud/workforce_preview.gd")

func _ready() -> void:
	if not "Test" in OS.get_user_data_dir(): push_error("Allocator probe requires isolated Test data"); get_tree().quit(2); return
	get_tree().create_timer(240.0).timeout.connect(func(): get_tree().quit(3))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): art_case = argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="): art_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="): capture_prefix = argument.trim_prefix("--prefix=")
	var config := ConfigFile.new()
	config.set_value("display", "visual_system", 1); config.set_value("display", "color_theme", art_mode); config.save("user://display.cfg")
	_world("late" if art_case == "mature" else "early")
	GameState.civic_api_enabled = false; GameState.select_founding_focus("provision"); PeopleDirection.choose("makers")
	get_window().size = Vector2i(1600, 1000); get_window().content_scale_size = Vector2i(1600, 1000)
	audit_terrain = load("res://local_terrain.tscn").instantiate()
	audit_terrain.set("suppress_naming_prompt", true); add_child(audit_terrain)
	await _frames(50); audit_terrain.call("_set_game_speed", 0)
	for director: Node in get_tree().get_nodes_in_group("court_director"): director.set_process(false)
	if is_instance_valid(PeopleDirection.panel): PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")): audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud: Control = audit_terrain.get("hud")
	var ledger := _work_ledger()
	hud.section_requested.emit("overview", 0); hud.force_dock_layout(); await _frames(20)
	var board: Control = hud.dock.find_child("CivilizationPeopleScreen", true, false)
	_expect(board != null, "Actual Home People provider opens allocator")
	if board == null: get_tree().quit(1); return
	_expect(board.get_script().resource_path.ends_with("people_allocator_screen.gd"), "Production uses standard allocator")
	_expect(board._art.texture != null, "Population artwork remains a backdrop")
	_expect(_work_ledger() == ledger, "Opening allocator and shared estimate do not mutate the world")
	_check_layout(board, "wide")
	await _capture("overview-wide")
	for role: String in ROLES:
		var select: Button = board.rows[role].select
		hud.dock.body_scroll.ensure_control_visible(select); await _frames(2)
		await _click(select.get_global_rect().get_center()); await _frames(2)
		_expect(board.active_role == role, "Native selection explains " + role)
		_expect(_work_ledger() == ledger, "Reading " + role + " does not change work")
	var original_instance := board.get_instance_id()
	hud.dock.body_scroll.scroll_vertical = 0; await _frames(3)
	var target := int(Manual.percents(Preview.capture().shares).Knowledge)
	var expected_draft := Preview.step(Preview.capture(), "Knowledge", 5)
	var expected := Preview.evaluate(expected_draft)
	var button: Button = board.rows.Knowledge.steps[5]
	hud.dock.body_scroll.ensure_control_visible(button); await _frames(3)
	var fixed := button.get_global_rect()
	var scroll: int = hud.dock.body_scroll.scroll_vertical
	await _click(fixed.get_center()); await _frames(10)
	_expect(int(Manual.percents().Knowledge) == target + 5, "Native +5 changes requested target immediately")
	_expect(not PeopleDirection.automatic_work, "Explicit step takes existing manual authority")
	_expect(Manual.counts() == expected.after.counts, "Actual worker counts match protected preview")
	_expect(board.forecast.after.food == expected.after.food, "Displayed food consequences use the real evaluation")
	_expect(button.get_global_rect() == fixed, "Assignment button does not shift")
	_expect(hud.dock.body_scroll.scroll_vertical == scroll, "Assignment preserves dock scroll")
	_expect(board.get_instance_id() == original_instance, "Immediate refresh retains allocator controls")
	_expect(board.find_child("ApplyWorkDraft", true, false) == null, "No Apply step")
	await _capture("learning-after-wide")
	for index in 3: await _click(board.rows.Knowledge.steps[1].get_global_rect().get_center())
	await _frames(8)
	_expect(int(Manual.percents().Knowledge) == target + 8, "Rapid clicks retain all three commands")
	button = board.rows.Administration.steps[1]
	button.grab_focus(); await _frames(2)
	var care_before := int(Manual.percents().Administration)
	await _key(KEY_ENTER); await _frames(8)
	_expect(int(Manual.percents().Administration) == care_before + 1, "Keyboard Enter applies one care step")
	_expect(board.active_role == "Administration", "Adjustment selects its own consequences")
	await _capture("care-after-wide")
	GameState.elapsed_days += 1; hud.live_refresh_dock(); await _frames(5)
	var held := int(Manual.percents().Knowledge)
	await _click(board.rows.Knowledge.steps[-1].get_global_rect().get_center()); await _frames(8)
	_expect(int(Manual.percents().Knowledge) == held - 1, "Later-day adjustment captures fresh state")
	for resolution: Vector2i in [Vector2i(1024,720), Vector2i(2869,1337)]:
		get_window().size = resolution; get_window().content_scale_size = resolution; hud.force_dock_layout(); await _frames(15)
		hud.dock.body_scroll.scroll_vertical = 0; await _frames(3)
		_check_layout(board, str(resolution.x)); await _capture("overview-" + str(resolution.x))
		button = board.rows.Crafting.steps[1]
		hud.dock.body_scroll.ensure_control_visible(button); await _frames(3)
		fixed = button.get_global_rect(); scroll = hud.dock.body_scroll.scroll_vertical
		await _click(fixed.get_center()); await _frames(8)
		_expect(button.get_global_rect() == fixed and hud.dock.body_scroll.scroll_vertical == scroll, "Controls and scroll fixed at " + str(resolution.x))
		_check_layout(board, str(resolution.x) + " after")
		await _capture("making-after-" + str(resolution.x))
		hud.dock.body_scroll.scroll_vertical = 100000; await _frames(3); await _capture("consequences-" + str(resolution.x))
	var saved: Dictionary = board.view_state()
	var command_counts := Manual.counts()
	board.restore_view_state(saved)
	_expect(Manual.counts() == command_counts, "Restoring selected work never replays actions")
	board.refs.delegate.pressed.emit(); await _frames(8)
	_expect(PeopleDirection.automatic_work, "Existing delegation restores leaders")
	print("PEOPLE_ALLOCATOR_JOURNEY ", checks, " checks; failures: ", failures)
	PlanetEnvironment.set_macro_bake_enabled(false)
	audit_terrain.queue_free(); await _frames(2)
	get_tree().quit(0 if failures.is_empty() else 1)

func _key(key: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new(); event.keycode = key; event.pressed = pressed
		get_viewport().push_input(event, true); await get_tree().process_frame

func _check_layout(board: Control, label: String) -> void:
	_expect(board.rows.size() == 9, "Exactly nine allocator rows: " + label)
	_expect(board.find_child("AssignmentToolbar",true,false).size.y < 90, "Toolbar remains compact: " + label)
	_expect(board.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x + 1, "Allocator fits viewport width: " + label)
	if get_viewport().get_visible_rect().size.x >= 1024:
		_expect(board.rows.Defense.steps[1].get_global_rect().end.y <= get_viewport().get_visible_rect().size.y, "Every work control is above the fold: " + label)
		_expect(board.refs.risk.get_parent().get_global_rect().end.y <= get_viewport().get_visible_rect().size.y, "Food risk is above the fold: " + label)
	var rectangles: Array[Rect2] = []
	for role: String in ROLES:
		var row: Dictionary = board.rows[role]
		var rect: Rect2 = row.panel.get_global_rect()
		_expect(row.panel.is_visible_in_tree(), "Role remains visible: " + label + " " + role)
		for point: int in [-1,1,5]:
			var button: Button = row.steps[point]
			_expect(rect.encloses(button.get_global_rect()), "Step stays within row: " + label + " " + role)
			_expect(button.get_global_rect().end.x <= board.get_global_rect().end.x + 1, "Step fits width: " + label + " " + role)
		for other: Rect2 in rectangles: _expect(not rect.intersects(other), "Rows never overlap: " + label + " " + role)
		rectangles.append(rect)
		_expect(String(row.count.text) == preload("res://scripts/hud/era_words.gd").grouped(int(Manual.counts().get(role,0))), "Actual heads match ledger: " + role)
		_expect(String(row.share.text) == "%d%%" % int(Manual.percents(Preview.capture().shares).get(role,0)), "Target matches requested share: " + role)

func _work_ledger() -> PackedByteArray:
	return var_to_bytes([GameState.population_allocations, GameState.population_total, GameState.food_stocks, GameState.resource_stockpiles, PeopleDirection.automatic_work, GameState.elapsed_days, GameState.settlement_plots, GameState.settlement_routes, DiscoverySystem.rng.state, ResourceSystem.rng.state])

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := "res://artifacts/popup-audit/people-allocator/%s-%s-%s" % [capture_prefix, art_case, art_mode]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png"))
