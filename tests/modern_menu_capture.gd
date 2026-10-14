extends "res://tests/modern_map_capture.gd"
## Actual menu disclosures and bounded AI form. Isolated fixture; no actions
## are committed, no credentials read, no network requests or game saves.
func run()->void:
	output="res://artifacts/popup-audit/settings"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var store=preload("res://scripts/ai_connection_store.gd")
	store.loaded=true;store.issue="";store.backend=Callable()
	for key in ["LEVIATHAN_AI_API_KEY","OPENAI_API_KEY","ANTHROPIC_API_KEY","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_ENDPOINT"]:OS.unset_environment(key)
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	GameState.select_founding_focus("provision")
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await frames(24)
	if WorldSimulation.direction.needs_century_choice():WorldSimulation.direction.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	terrain._set_game_speed(0)
	for mode in ["dark","light"]:
		terrain.display_preferences.ui_scale=1.0;terrain.display_preferences.color_theme=mode;T.set_color_mode(mode);terrain.display_preferences.apply()
		get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720)
		for page in ["main","Displayandsound","Writtenreplies","Startagain","Controls"]:
			terrain._open_world_menu();await frames()
			var menu:Control=terrain.world_menu_panel
			if page!="main":
				var toggle:=menu.find_child(page+"Toggle",true,false) as Button
				if toggle==null:push_error("Missing menu disclosure "+page);get_tree().quit(1);return
				toggle.pressed.emit()
			await shot("menu-%s-%s" % [page,mode])
			var scroll:=menu.find_child("PauseMenuScroll",true,false) as ScrollContainer
			scroll.scroll_vertical=100000;await shot("menu-%s-bottom-%s" % [page,mode])
			var resume:=menu.find_child("Resume",true,false) as Control
			if not Rect2(Vector2.ZERO,Vector2(1024,720)).encloses(resume.get_global_rect()):push_error("Resume outside viewport");get_tree().quit(1);return
			if page=="Startagain":
				var confirmation:=preload("res://scripts/hud/game_menu.gd").confirm(menu,"Start a new world?","A different land and different neighbours. This game is lost unless you have saved it.","Start a new world",Callable())
				await shot("menu-confirm-%s" % mode);confirmation.queue_free()
			terrain._close_world_menu();await frames()
		get_viewport().gui_embed_subwindows=true
		terrain._request_quit();await shot("quit-%s" % mode)
		print("QUIT_SIZE ",mode," dialog=",terrain.quit_dialog.size," scale=",terrain.quit_dialog.content_scale_factor," canvas=",terrain.quit_dialog.content_scale_size," button=",terrain.quit_dialog.get_ok_button().size," min=",terrain.quit_dialog.get_ok_button().custom_minimum_size)
		if terrain.quit_dialog.get_ok_button().size.y<44 or terrain.quit_dialog.get_cancel_button().size.y<40:push_error("Native quit controls are below target height");get_tree().quit(1);return
		terrain.quit_dialog.hide();terrain._close_world_menu();await frames()
		GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
		terrain._open_settlement_naming_panel();await shot("rename-%s" % mode)
		terrain._dismiss_settlement_naming_panel();await frames()
		var ai:=preload("res://scripts/hud/ai_connection_panel.gd").new();add_child(ai)
		await shot("ai-%s" % mode)
		ai._toggle_advanced();await shot("ai-advanced-%s" % mode)
		var body:=ai.card.find_child("Body",true,false) as ScrollContainer
		if body:body.scroll_vertical=100000
		await shot("ai-bottom-%s" % mode)
		for action:Node in ai.find_children("*","Button",true,false):
			if (action as Button).text=="Forget the saved connection":(action as Button).pressed.emit();break
		await shot("ai-forget-%s" % mode)
		for child:Node in ai.get_children():
			if child is ConfirmationDialog:
				if child.get_ok_button().size.y<44 or child.get_cancel_button().size.y<40:push_error("Native forget controls are below target height");get_tree().quit(1);return
				child.canceled.emit()
		ai.queue_free();await frames()
	print("MODERN_MENU_CAPTURE PASS")
	get_tree().quit(0)
