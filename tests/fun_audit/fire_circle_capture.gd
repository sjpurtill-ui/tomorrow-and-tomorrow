extends Node
## Visual check of the fire-circle opening and the first-fire naming (isolated
## userdata, never saves). Captures go to the path in --out_dir.
var terrain:Node
var out_dir:=""
func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):get_tree().quit(2);return
	out_dir=_arg("out_dir","user://captures")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var size:=Vector2i(int(_arg("w","1600")),int(_arg("h","900")))
	get_window().size=size;get_window().content_scale_size=size
	GameState.reset_for_new_world(int(_arg("seed","424242")))
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(40)
	await _cap("fire-circle-question")
	var panel=PeopleDirection.panel
	panel.ambition_buttons[2].pressed.emit()
	await _frames(6)
	await _cap("fire-circle-answered")
	panel.more_button.pressed.emit()
	await _frames(6)
	await _cap("fire-circle-other-answers")
	panel.pages[0].get_node("ConfirmFocus").pressed.emit()
	await _frames(20)
	terrain._start_settlement_here()
	await _frames(20)
	await _cap("first-fire-naming")
	var naming=terrain.settlement_naming_panel
	if naming and naming.suggestions.get_child_count()>1:(naming.suggestions.get_child(1) as Button).pressed.emit()
	await _frames(6)
	await _cap("first-fire-named")
	print("FIRE_CIRCLE_CAPTURE DONE")
	get_tree().quit(0)
func _frames(n:int)->void:
	for i in n:await get_tree().process_frame
func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var path:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ",path)
