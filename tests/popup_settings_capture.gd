extends Control
## Private, self-terminating UI fixture. No network request, saved credential
## access or campaign persistence. Use tools/run_isolated_gpu_probe.ps1.
func _ready()->void:
	get_window().content_scale_size=get_window().size
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var T:=preload("res://scripts/hud/hud_tokens.gd")
	var Store:=preload("res://scripts/ai_connection_store.gd")
	Store.loaded=true;Store.issue="";Store.backend=Callable()
	for key:String in ["LEVIATHAN_AI_API_KEY","OPENAI_API_KEY","ANTHROPIC_API_KEY","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_ENDPOINT"]:OS.unset_environment(key)
	var out:="res://artifacts/popup-audit/ai.png"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--night":T.set_color_mode("dark")
	var background:=ColorRect.new();background.color=T.PAPER;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var panel:=preload("res://scripts/hud/ai_connection_panel.gd").new();add_child(panel)
	if "--advanced" in OS.get_cmdline_user_args():panel._toggle_advanced()
	for frame in 10:await get_tree().process_frame
	if "--bottom" in OS.get_cmdline_user_args():
		var scroll:=panel.card.find_child("Body",true,false) as ScrollContainer
		if scroll:scroll.scroll_vertical=100000
	for frame in 4:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("POPUP_SETTINGS_CAPTURE ",out)
	get_tree().quit()
