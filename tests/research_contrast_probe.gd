extends Node
const T=preload("res://scripts/hud/hud_tokens.gd")
func _ready()->void:
	GameState.reset_for_new_world(424242);DiscoverySystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	get_window().size=Vector2i(1440,900)
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		assert(T.readable_report("[color=#ddd2b8]Condition[/color]").contains("Condition"))
		if mode=="light":assert(not T.readable_report("[color=#ddd2b8]Condition[/color]").contains("#ddd2b8"))
		var prefs=preload("res://scripts/display_preferences.gd").new()
		prefs.config_path="res://artifacts/contrast-missing.cfg";add_child(prefs)
		T.set_color_mode(mode);prefs.apply()
		var overlay:=CanvasLayer.new();add_child(overlay)
		var button:=Button.new();button.text="Overlay action";overlay.add_child(button)
		assert(button.get_theme_color("font_color")==T.BODY)
		var dialog:=ConfirmationDialog.new();overlay.add_child(dialog)
		assert(dialog.get_ok_button().get_theme_color("font_color")==T.BODY)
		assert(dialog.get_theme_stylebox("panel","AcceptDialog").bg_color==T.PANEL_BG_SOLID)
		overlay.queue_free()
		var view=preload("res://scripts/hud/research_atlas.gd").new();add_child(view);view.set_view("tree")
		for i in 12:await get_tree().process_frame
		assert(view.tabs.tree.modulate==Color.WHITE)
		assert(view.filter.get_theme_color("font_color")==T.BODY)
		assert(view.search.get_theme_color("font_color")==T.BODY)
		assert(view.locked_toggle.get_theme_color("font_color")==T.BODY)
		assert(view.announcements.get_popup().get_theme_color("font_color")==T.BODY)
		assert(view.panel.get_rect().end.y<=view.get_viewport_rect().size.y)
		assert(not view.plot.boxes.is_empty())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/research-contrast-"+mode+".png")
		view.queue_free();prefs.queue_free();await get_tree().process_frame
	print("RESEARCH_CONTRAST_PASS light and dark controls, popup inheritance and untinted tabs")
	get_tree().quit()
