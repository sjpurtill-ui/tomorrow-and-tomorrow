extends Node
## FUN AUDIT UI captures (item #5): the founding screen, year 5 and year 25 of
## a fresh world, as the player sees them, each with the map alone and with
## the People view open. Also writes the UI measure (ui_measure.gd) at each
## mark. Isolated userdata only; never saves. Run it on a private desktop:
##   tools/run_isolated_gpu_probe.ps1 -Scene res://tests/fun_audit/ui_capture.tscn
##     -UserArguments "--out-dir=<dir> --years=25"
const UiMeasure:=preload("res://tests/fun_audit/ui_measure.gd")
var terrain:Node
var out_dir:=""
var log_file:FileAccess

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	out_dir=_arg("out-dir",ProjectSettings.globalize_path("user://ui_capture/"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	log_file=FileAccess.open(out_dir.path_join("ui_measure.jsonl"),FileAccess.WRITE)
	var years:=float(_arg("years","25"))
	GameState.reset_for_new_world(int(_arg("seed","424242")))
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose(_arg("ambition","makers"))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(20)
	var tries:=0
	while not GameState.settlement_site_committed and tries<40:
		tries+=1
		terrain._start_settlement_here()
		if not GameState.settlement_site_committed:
			terrain.advance_world_time(1.0);_clear();await _frames(2)
	await _frames(20)
	# What the player sees the moment the hearth is founded (naming prompt and all).
	await _cap("01-founding")
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	await _frames(12)
	await _cap("02-founding-map")
	_measure("founding")
	terrain._set_game_speed(5)
	for mark in [5,25]:
		if float(mark)>years:break
		while GameState.elapsed_days<mark*365.0:
			terrain.advance_world_time(1.0)
			_clear()
			if int(GameState.elapsed_days)%5==0:await get_tree().process_frame
		terrain._set_game_speed(0)
		_close_modals()
		await _frames(30)
		await _cap("%02d-year%d-map" % [mark/5+2,mark])
		terrain._on_hud_section_requested("overview",0)
		await _frames(12)
		await _cap("%02d-year%d-people" % [mark/5+2,mark])
		terrain._on_hud_section_requested("",0)
		await _frames(4)
		if terrain.hud.has_method("toggle_drawer"):
			terrain.hud.toggle_drawer()
			await _frames(6)
			await _cap("%02d-year%d-drawer" % [mark/5+2,mark])
			terrain.hud.toggle_drawer()
			await _frames(4)
		_measure("year %d" % mark)
		terrain._set_game_speed(5)
	log_file.close()
	print("UI_CAPTURE DONE")
	get_tree().quit(0)

func _measure(label:String)->void:
	var row:=UiMeasure.measure(terrain,label)
	row["day"]=int(GameState.elapsed_days)
	log_file.store_line(JSON.stringify(row))
	log_file.flush()

func _clear()->void:
	if terrain.game_speed<=0.0:
		if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		terrain._set_game_speed(5)
	_close_modals()

func _close_modals()->void:
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		var id:String=String(dir.modal.audience_id)
		var hall:GDScript=load("res://scripts/audience_hall.gd")
		var options:Array=hall.call("options",id)
		for option in options:
			if bool(option.get("enabled",true)):
				hall.call("resolve",id,String(option.id));break
		dir.modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
	if PeopleDirection.needs_century_choice():
		PeopleDirection.choose(_arg("ambition","makers"))
		if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var p:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(p)
	print("UI capture ",p)
