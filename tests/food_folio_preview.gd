extends "res://tests/own_town_capture.gd"
const Shell = preload("res://tests/trade_visual_acceptance_probe.gd")
const Fixture = preload("res://tests/test_food_folio.gd")

class FoodProvider extends "res://scripts/hud/content/dock_content_economy.gd":
	func _provisions_data() -> Dictionary:
		var result := super._provisions_data()
		var example := preload("res://tests/test_food_folio.gd").prepared_food()
		for key: String in example:
			if not key.begins_with("on_"): result[key] = example[key]
		return result

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--food-preview") or not OS.get_user_data_dir().contains("acceptance"):
		get_tree().quit(2)
		return
	call_deferred("_preview_food")

func _preview_food() -> void:
	var mode := "dark"
	var width := 1536
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--width="): width = int(arg.trim_prefix("--width="))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(width, 1080)
	for node: Node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	_world("early")
	GameState.settlement_name = "Ashfire"
	SettlementModel.settlement_record(GameState.selected_player_settlement_id)["name"] = "Ashfire"
	var purse: Dictionary = preload("res://scripts/realm_purse.gd").state()
	purse.rations = 71188.0
	purse.balance = 71188.0
	T.set_color_mode(mode)
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	var background := ColorRect.new()
	background.color = T.PAPER_SUNK.lerp(T.GREEN, 0.16)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var hud := Shell.TradeHud.new()
	add_child(hud)
	var terrain := StubTerrain.new()
	add_child(terrain)
	hud.register_provider("economy", FoodProvider.new(terrain, hud))
	hud._refresh_kpis()
	hud.open_dock("economy", 0)
	for sample: Array in [["population", "435 souls"], ["food", "226 days"], ["water", "5.3 days"], ["health", "31 winters"], ["science", "548 known"]]:
		hud._update_kpi(sample[0], sample[1], "Prepared preview figure", T.GREEN, "")
	hud._layout()
	for frame in 20: await get_tree().process_frame
	hud.force_dock_layout()
	var label := Label.new()
	label.text = "FOOD PAGE PREVIEW\nPrepared figures\nNot integrated into the game"
	label.position = Vector2(hud.dock.position.x + hud.dock.size.x + 24, 100)
	label.add_theme_color_override("font_color", T.INK)
	add_child(label)
	var out := "res://artifacts/food-folio-" + mode + "-" + str(width)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for frame in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out + "/food.png"))
	var board := hud.dock.find_child("PurseBoard", true, false)
	if board:
		board.disclosure.button_pressed = true
		for frame in 5: await get_tree().process_frame
		if not board.details.visible: get_tree().quit(1); return
	print("FOOD_FOLIO_PREVIEW_OK ", mode, " ", width)
	get_tree().quit(0)
