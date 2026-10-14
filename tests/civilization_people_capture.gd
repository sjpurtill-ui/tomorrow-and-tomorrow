extends "res://tests/own_town_capture.gd"
## Private TEST scene only. Actual provider, HUD, living renderer and draft API.
var audit_terrain:Node
var failures:Array[String]=[]
var out_prefix:="first"
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Requires isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(180.0).timeout.connect(func():get_tree().quit(3))
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):out_prefix=arg.trim_prefix("--prefix=")
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if "--late" in OS.get_cmdline_user_args() else "early")
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(45);audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(5)
	var hud=audit_terrain.get("hud")
	for canvas:Vector2i in [Vector2i(1600,1000),Vector2i(2869,1337),Vector2i(1024,768)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		audit_terrain.call("_on_hud_section_requested","overview",0);hud.force_dock_layout();await _frames(12)
		var screen=hud.dock.find_child("CivilizationPeopleScreen",true,false)
		if screen==null:failures.append("Actual People route absent");break
		screen._cancel_draft();screen._return_overview();hud.dock.body_scroll.scroll_vertical=0;await _frames(25)
		await _capture("overview",canvas.x,mode)
		if screen.markers.size()!=9:failures.append("Missing work area")
		if hud.dock.get_global_rect().end.x>get_viewport().get_visible_rect().size.x+1:failures.append("Spatial shell exceeds viewport")
		var before:=var_to_bytes([GameState.population_allocations,PeopleDirection.automatic_work,PeopleDirection.work_baseline])
		(screen.markers.Food.button as Button).pressed.emit();await _frames(35)
		await _capture("food",canvas.x,mode)
		screen.focus_work("Construction");screen.five_button.pressed.emit();await _frames(35)
		await _capture("building-draft",canvas.x,mode)
		if before!=var_to_bytes([GameState.population_allocations,PeopleDirection.automatic_work,PeopleDirection.work_baseline]):failures.append("Preview changed live allocations")
		if not screen.stage.get_global_rect().encloses(screen.focus_panel.get_global_rect()):failures.append("Draft panel exceeds scene at %d"%canvas.x)
		if not screen.stage.get_global_rect().encloses(screen.evidence_panel.get_global_rect()):failures.append("Consequences exceed scene at %d"%canvas.x)
		if screen.get_global_rect().end.x>canvas.x+1:failures.append("People content exceeds viewport")
		screen._cancel_draft();screen._return_overview()
	print("CIVILIZATION_PEOPLE_CAPTURE ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func _frames(count:int)->void:
	for i in count:await get_tree().process_frame
func _capture(kind:String,width:int,mode:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/people-living-b")
	get_viewport().get_texture().get_image().save_png("res://artifacts/people-living-b/%s-%s-%s-%d.png"%[out_prefix,kind,mode,width])
