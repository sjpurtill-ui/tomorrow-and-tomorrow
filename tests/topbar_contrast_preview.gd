extends Node
## Private-desktop visual proof, with prepared values and optional map photo.
const T = preload("res://scripts/hud/hud_tokens.gd")
const Shell = preload("res://tests/trade_visual_acceptance_probe.gd")

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--topbar-preview") or not OS.get_user_data_dir().contains("acceptance"):
		get_tree().quit(2)
		return
	call_deferred("_preview")

func _preview() -> void:
	var map_path := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--map="): map_path = argument.trim_prefix("--map=")
	for node: Node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(1920, 320)
	T.set_color_mode("light")
	Shell.prepare_fixture("barter")
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not map_path.is_empty():
		var source := Image.load_from_file(map_path)
		if source == null:
			get_tree().quit(2)
			return
		var atlas := AtlasTexture.new()
		atlas.atlas = ImageTexture.create_from_image(source)
		# Show only terrain below the supplied screenshot's existing HUD.
		atlas.region = Rect2(78, 72, source.get_width() - 78, source.get_height() - 72)
		background.texture = atlas
	add_child(background)
	var hud := Shell.TradeHud.new()
	add_child(hud)
	hud.toolbar.hide()
	hud.time_text.text = "[b]Year 119 · Autumn[/b] · Warm →"
	hud.city_selector.clear()
	hud.city_selector.add_item("Ashfire")
	hud._style_speed_controls(1)
	var readings: Array[Dictionary] = []
	for spec: Array in [["population", "PEOPLE", "435 souls"], ["food", "STORES", "225 days"], ["water", "WATER", "5.3 days"], ["health", "LIVES", "31 winters"], ["science", "LORE", "548 known"]]:
		readings.append({"id":spec[0], "caption":spec[1], "value":spec[2], "note":"", "note_color":T.GREEN, "section":"overview", "sub":0})
	for frame in 12: await get_tree().process_frame
	hud.top_readings.show_readings(readings)
	# Explicitly exercise the fully transparent case visible in the user's shot.
	hud.get_node("MapTopTint").hide()
	var label := Label.new()
	label.position = Vector2(110, 120)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("eee4c9"))
	preload("res://scripts/hud/topbar_ink.gd").apply(label)
	add_child(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/topbar-contrast"))
	for dark: bool in [false, true]:
		background.modulate = Color(0.22, 0.28, 0.23) if dark else Color.WHITE
		label.text = "PREVIEW · " + ("Dark terrain" if dark else "Pale terrain from your screenshot")
		for frame in 8: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "res://artifacts/topbar-contrast/" + ("dark.png" if dark else "pale.png")
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("TOPBAR_CONTRAST_PREVIEW_OK: pale and dark, actual HUD controls, prepared values")
	get_tree().quit(0)
