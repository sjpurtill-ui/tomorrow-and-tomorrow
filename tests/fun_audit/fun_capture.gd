extends Node
## FUN AUDIT visual pass (uncommitted). Real game scene, fresh world, captures
## what a new player sees: ambition screen, first map, after founding, a year
## in, the dock sections and the Court. Isolated userdata only; never saves.
const Hall:=preload("res://scripts/audience_hall.gd")
var terrain:Node
var out_dir:=""
var n:=0
var pending:=false

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowFunAuditTests"):get_tree().quit(2);return
	out_dir=ProjectSettings.globalize_path("res://docs/fun_audit_captures/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(40)
	await _cap("01-opening-ambition-screen")
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(30)
	await _cap("02-first-map-convoy")
	terrain._start_settlement_here()
	await _frames(20)
	await _cap("03-founding-naming")
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	terrain._set_game_speed(5)
	for i in 120:
		terrain.advance_world_time(1.0)
		_clear()
		if pending:await _envoy()
		await get_tree().process_frame
	await _frames(20)
	await _cap("04-day120-map")
	for i in 245:
		terrain.advance_world_time(1.0)
		_clear()
		if pending:await _envoy()
		if i%5==0:await get_tree().process_frame
	terrain._set_game_speed(0)
	await _frames(30)
	await _cap("05-year1-map")
	for sec in [["overview",0],["economy",0],["production",0],["civ",0],["inquiry",0],["world",0],["military",0],["government",0]]:
		terrain._on_hud_section_requested(sec[0],sec[1])
		await _frames(12)
		await _cap("06-dock-%s" % sec[0])
		terrain._on_hud_section_requested(sec[0],sec[1])
		await _frames(4)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir:
		var court:Control=dir.open_court()
		await _frames(30)
		if court.has_method("skip_reveal"):court.skip_reveal()
		await _cap("07-court-at-rest")
		court._close()
		await _frames(4)
	# zoom-in on settlement
	terrain.camera.size=1.2;terrain.camera_target=GameState.settlement_founded_at
	await _frames(40)
	await _cap("08-settlement-close")
	get_tree().quit(0)

func _clear()->void:
	if terrain.game_speed<=0.0:
		if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		terrain._set_game_speed(5)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		var id:String=String(dir.modal.audience_id)
		if n==0 and id!="":
			n=1
			pending=true
			return
		dir.modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())

func _envoy()->void:
	pending=false
	await _frames(40)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		if dir.modal.has_method("skip_reveal"):dir.modal.skip_reveal()
		await _frames(4)
		await _cap("09-first-envoy-day%d" % int(GameState.elapsed_days))
		dir.modal.queue_free()
	preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
	terrain._set_game_speed(5)

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var p:=out_dir+label+".png"
	get_viewport().get_texture().get_image().save_png(p)
	print("FUN capture ",p)
