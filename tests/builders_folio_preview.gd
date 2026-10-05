extends "res://tests/town_works_capture.gd"
## Actual runtime UI, prepared records, isolated userdata. Never a player launch.
const Shell := preload("res://tests/trade_visual_acceptance_probe.gd")

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--builders-preview") or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		get_tree().quit(2)
		return
	call_deferred("_preview")

func _preview() -> void:
	var out := "res://artifacts/builders-folio"
	var case := "building"
	var width := 1536
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--case="): case = arg.trim_prefix("--case=")
		if arg.begins_with("--width="): width = int(arg.trim_prefix("--width="))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(width, 1024)
	for node: Node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	_world(case)
	GameState.simulation_metrics.merge({"food_total_stock":10620.0,"food_consumption":118.0,"food_eaten":118.0,"food_production":132.0},true)
	GameState.water_metrics.merge({"stored":1652.0,"required_today":118.0,"collected_today":124.0},true)
	T.set_color_mode("light")
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	var backdrop := ColorRect.new()
	backdrop.color = T.PAPER_SUNK.lerp(T.GREEN, 0.16)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var hud := Shell.TradeHud.new()
	add_child(hud)
	var terrain := StubTerrain.new()
	add_child(terrain)
	hud.register_provider("construction", preload("res://scripts/hud/content/dock_content_construction.gd").new(terrain, hud))
	hud._refresh_kpis()
	hud.drawer_open = true
	hud._sync_drawer()
	hud.open_dock("construction", 0)
	for frame in 24: await get_tree().process_frame
	hud.force_dock_layout()
	for frame in 12: await get_tree().process_frame
	var label := Label.new()
	label.text = "UI PREVIEW\nPrepared construction records\nNot integrated into the game"
	label.add_theme_color_override("font_color", T.INK)
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(hud.dock.position.x + hud.dock.size.x + 24, 90)
	add_child(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	await _capture_page(out + "/builders-top.png")
	hud.dock.body_scroll.scroll_vertical = 540
	for frame in 12: await get_tree().process_frame
	await _capture_page(out + "/builders-town.png")
	var board: Control = hud.dock.find_child("BuildersTownFolio", true, false)
	if board == null:
		push_error("Builders folio missing")
		get_tree().quit(1)
		return
	var detail: Button = board.find_child("Details_work", true, false)
	if detail != null:
		detail.button_pressed = true
		# Change the live work so preservation crosses a real section rebuild.
		if case == "building": GameState.settlement_projects["Framed Hall"] += 1.0
		hud.dock.rebuild_body()
		for frame in 12: await get_tree().process_frame
		board = hud.dock.find_child("BuildersTownFolio", true, false)
		if not bool(board.view_state().get("work", false)):
			push_error("Open construction details lost during live refresh")
			get_tree().quit(1)
			return
		hud.dock.body_scroll.scroll_vertical = 0
		for frame in 12: await get_tree().process_frame
		await _capture_page(out + "/builders-details.png")
	hud.dock.body_scroll.scroll_vertical = 10000
	for frame in 12: await get_tree().process_frame
	await _capture_page(out + "/builders-fabric.png")
	print("BUILDERS_PREVIEW_OK ", case, " ", width)
	get_tree().quit(0)

func _capture_page(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
