extends Node
## Visual check of generational aims: the court hearing an aim proposal, the
## Known World's "What we strive for" sheet, and the court at rest.
## Isolated userdata only (override.cfg); never saves.
##   run through tools/run_isolated_gpu_probe.ps1 with -UserArguments "--out=<dir>"
const Hall:=preload("res://scripts/audience_hall.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
var terrain:Node
var out_dir:=""

func _ready()->void:
	if not OS.get_user_data_dir().get_file().begins_with("TomorrowFun"):get_tree().quit(2);return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out_dir=a.substr(6)
	if out_dir=="":out_dir=OS.get_user_data_dir()+"/aims_capture/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(10)
	terrain._start_settlement_here()
	await _frames(10)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	terrain._set_game_speed(5)
	var waited:=0
	while waited<400:
		terrain.advance_world_time(1.0)
		_release()
		waited+=1
		if waited%10==0:await get_tree().process_frame
		var found:=false
		for m in Hall.matters():
			if String(m.get("situation_type",""))=="aim":found=true
		if found:break
	terrain._set_game_speed(0)
	var matter:Dictionary={}
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="aim":matter=m
	var ok:=not matter.is_empty()
	if ok:
		var opened:=Hall.open_matter(String(matter.id))
		var dir:Node=get_tree().get_first_node_in_group("court_director")
		var modal:Control=dir.open_audience(String(opened.id)) if dir else null
		await _frames(90)
		if modal and modal.has_method("skip_reveal"):modal.skip_reveal()
		await _frames(20)
		await _cap("aims-01-court-proposal")
		var pick:=""
		for o in Hall.options(String(opened.id)):
			if String(o.id).begins_with("aim_adopt:") and pick=="":pick=String(o.id)
		if modal and modal.has_method("choose"):modal.choose(pick)
		else:Hall.resolve(String(opened.id),pick)
		await _frames(30)
		await _cap("aims-02-court-taken-up")
		if is_instance_valid(modal):modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		await _frames(10)
		terrain._set_game_speed(5)
		for i in 200:
			terrain.advance_world_time(1.0);_release()
			if i%10==0:await get_tree().process_frame
		terrain._set_game_speed(0)
		terrain._on_hud_section_requested("world",0)
		await _frames(30)
		await _cap("aims-03-known-world")
		if dir and dir.has_method("open_court"):
			dir.open_court({})
			await _frames(60)
			await _cap("aims-04-court-at-rest")
	ok=ok and Aims.has_active()
	print("AIMS_CAPTURE %s aim=%s" % ["PASS" if ok else "FAIL",String(Aims.active().get("title",""))])
	get_tree().quit(0 if ok else 1)

func _release()->void:
	if terrain.game_speed<=0.0:
		if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		terrain._set_game_speed(5)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		dir.modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var p:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(p)
	print("AIMS capture ",p)
