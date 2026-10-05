extends "res://tests/own_town_capture.gd"
## Prepared records in the real page shell; no campaign is loaded or saved.
const Shell := preload("res://tests/trade_visual_acceptance_probe.gd")

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--overview-preview") or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		get_tree().quit(2)
		return
	call_deferred("_preview")

func _preview() -> void:
	var out := "res://artifacts/overview-folio"
	var mode := "light"
	var case := "late"
	var width := 1536
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--case="): case = arg.trim_prefix("--case=")
		if arg.begins_with("--width="): width = int(arg.trim_prefix("--width="))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(width, 1100)
	for node: Node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	_world(case)
	T.set_color_mode(mode)
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	var backdrop := ColorRect.new()
	backdrop.color = T.PAPER_SUNK.lerp(T.GREEN, 0.16)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var hud := Shell.TradeHud.new()
	add_child(hud)
	var terrain := StubTerrain.new()
	add_child(terrain)
	hud.register_provider("settlement", preload("res://scripts/hud/content/dock_content_settlement.gd").new(terrain, hud))
	hud._refresh_kpis()
	hud.drawer_open = true
	hud._sync_drawer()
	hud.open_dock("settlement", 0)
	for frame in 24: await get_tree().process_frame
	hud.force_dock_layout()
	for frame in 12: await get_tree().process_frame
	var label := Label.new()
	label.text = "UI PREVIEW\nPrepared town records\nNot integrated into the game"
	label.add_theme_color_override("font_color", T.INK)
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(hud.dock.position.x + hud.dock.size.x + 24, 90)
	add_child(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	await _capture_page(out + "/overview-top.png")
	hud.dock.body_scroll.scroll_vertical = 430
	for frame in 12: await get_tree().process_frame
	await _capture_page(out + "/overview-readings.png")
	var compare := hud.dock.find_child("CompareTowns", true, false) as Button
	if compare != null:
		compare.button_pressed = true
		hud.dock.rebuild_body()
		for frame in 12: await get_tree().process_frame
		compare = hud.dock.find_child("CompareTowns", true, false) as Button
		if compare == null or not compare.button_pressed:
			push_error("Town comparisons lost on refresh")
			get_tree().quit(1)
			return
		await _capture_page(out + "/overview-comparisons.png")
	print("OVERVIEW_PREVIEW_OK ", case, " ", mode, " ", width)
	get_tree().quit(0)

func _capture_page(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
