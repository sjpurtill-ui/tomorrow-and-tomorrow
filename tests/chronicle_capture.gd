extends Node
## Visual check of the Chronicle: a moment card over the live map and the
## Chronicle dock. Isolated userdata only (override.cfg); never saves.
##   run through tools/run_isolated_gpu_probe.ps1 with -UserArguments "--out=<dir>"
const Chronicle:=preload("res://scripts/chronicle.gd")
var terrain:Node
var out_dir:=""

func _ready()->void:
	if not OS.get_user_data_dir().get_file().begins_with("TomorrowFun"):get_tree().quit(2);return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out_dir=a.substr(6)
	if out_dir=="":out_dir=OS.get_user_data_dir()+"/chronicle_capture/"
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
	for i in 240:
		terrain.advance_world_time(1.0)
		_release()
		if i%10==0:await get_tree().process_frame
	# Earlier moments have had their time; show the next one fresh.
	var shown:Variant=terrain.hud.get_meta("chronicle_card") if terrain.hud.has_meta("chronicle_card") else null
	if is_instance_valid(shown):
		shown.queue.clear();shown.showing=false;shown.panel.visible=false
	# A real first-in-its-field discovery, presented as the day loop presents it.
	var id:=""
	for candidate in ["seed_selection","food_drying","cordage","drainage","clay_shaping"]:
		if candidate not in GameState.known_discoveries:id=candidate;break
	GameState.known_discoveries.append(id)
	GameState.elapsed_days+=40.0
	var found:Array[Dictionary]=[DiscoverySystem.player_facing_discovery_event({"id":id,"day":int(GameState.elapsed_days)})]
	var none:Array[Dictionary]=[]
	terrain._commit_world_day({"discoveries":found,"resources":none,"events":none.duplicate(),"progression":none.duplicate()})
	terrain._set_game_speed(0)
	await _frames(50)
	await _cap("chronicle-01-moment-card")
	terrain._on_hud_section_requested("chronicle",0)
	await _frames(20)
	await _cap("chronicle-02-feed")
	terrain._on_hud_section_requested("chronicle",1)
	await _frames(20)
	await _cap("chronicle-03-feed-seasons")
	var ok:bool=Chronicle.entries("moment").size()>=2 and terrain.hud.active_section=="chronicle"
	print("CHRONICLE_CAPTURE %s moments=%d entries=%d" % ["PASS" if ok else "FAIL",Chronicle.entries("moment").size(),Chronicle.entries().size()])
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
	print("CHRONICLE capture ",p)
