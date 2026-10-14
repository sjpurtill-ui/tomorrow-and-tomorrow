extends "res://tests/own_town_capture.gd"
## Actual Buildings providers in an isolated, disposable review fixture.
var audit_terrain:Node
var failures:Array[String]=[]
var prefix:="baseline"
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():
		push_error("Buildings probe needs isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(160.0).timeout.connect(func():get_tree().quit(3))
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):prefix=argument.trim_prefix("--label=")
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if "--late" in OS.get_cmdline_user_args() else "early")
	if "--late" in OS.get_cmdline_user_args():_add_review_works()
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud=audit_terrain.get("hud")
	for canvas in ([Vector2i(1024,720)] if "--only-landmarks" in OS.get_cmdline_user_args() else [Vector2i(1600,1000),Vector2i(1024,720)]):
		get_window().size=canvas;get_window().content_scale_size=canvas
		for sub in ([3] if "--only-landmarks" in OS.get_cmdline_user_args() else [0,1,2,3]):
			audit_terrain.call("_on_hud_section_requested","construction",sub);hud.call("force_dock_layout");await _frames(10)
			hud.dock.body_scroll.scroll_vertical=0;await _frames(3)
			await _capture_view(["town","civic","infrastructure","landmarks"][sub],canvas.x,mode)
			var board=hud.dock.find_child("BuildingsBoard",true,false)
			if board and board.get_combined_minimum_size().x>board.size.x+1:failures.append("Content overflows tab%d at%d"%[sub,canvas.x])
			hud.dock.body_scroll.scroll_vertical=100000;await _frames(6);await _capture_view(["town","civic","infrastructure","landmarks"][sub]+"-lower",canvas.x,mode)
	if "--late" in OS.get_cmdline_user_args():
		var view=hud.dock.find_child("Act_View",true,false) as Button
		if view==null or view.disabled:failures.append("Existing landmark View action is unavailable")
		else:
			view.pressed.emit();await _frames(15)
			var atlas=hud.find_child("GreatWorksAtlas",true,false)
			if atlas==null:failures.append("Landmark View did not reach the existing atlas")
			else:
				await _capture_view("landmark-detail",1024,mode)
				atlas.call("close");await _frames(4)
	var conceive=hud.dock.find_child("Act_Conceive",true,false) as Button
	if conceive==null or conceive.disabled:failures.append("Landmark conception is unavailable")
	else:
		conceive.pressed.emit();await _frames(20)
		var director=audit_terrain.find_child("AudienceDirector",true,false)
		if not director or not is_instance_valid(director.get("modal")):failures.append("Conception did not reach the existing court")
		else:await _capture_view("conception",1024,mode)
	print("BUILDINGS_REDESIGN_CHECKS ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame
func _capture_view(label:String,width:int,mode:String)->void:
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://artifacts/buildings-%s-%s-%d-%s.png"%[prefix,mode,width,label])
	get_viewport().get_texture().get_image().save_png(path);print("BUILDINGS_CAPTURE ",path)

func _add_review_works()->void:
	# Same bounded record shape as great_works_experience_probe; no save is written.
	var concept=preload("res://scripts/wonder_concept.gd")
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	if not city.has("undertakings"):city.undertakings=[]
	for index in 2:
		var id:=concept.make_id("stair","watch_heavens","grand","stone",1,"bldgreview%d"%index)
		var definition:=concept.definition(id)
		var amount:=float(definition.work)*(0.55 if index==0 else 1.0)
		city.undertakings.append({"id":id,"status":"building" if index==0 else "functioning","policy":"careful","progress":amount,"quality":amount,"condition":0.88,"strain":0,"stalled_days":0,"operating_days":20,"last_day":0,"started":0,"reason":"Crews at work.","legacy":"Unproven","gates":["design","stores","labor"],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0,"custom_name":"Stair of the Northern Sky" if index==0 else "The Stone Calendar","shift":0.0,"feasibility":0.6,"outcome":"success" if index==1 else "","architect":{"id":"","name":"Oskadi Tallyhand","vision":0.8,"ego":0.8,"talent":0.8,"style":"monumental","mood":0},"concept":{"name":"Stair of the Northern Sky" if index==0 else "The Stone Calendar","lore":"Raised to keep the seasons in memory."},"site":{"position":Vector2(0.2,0.12),"angle":0.0}})
