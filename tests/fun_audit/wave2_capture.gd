extends Node
## Fun wave 2 GPU captures (isolated userdata, never saves): the founding
## screen, day 30 at the 200 m opening height, and year 5 with the Court and
## the Known World's aim sheet. Envoys are answered with the first enabled
## option; aim proposals are taken up like a plausible player. Writes the UI
## measure (ui_measure.gd) at each mark to ui_measure.jsonl.
##   tools/run_isolated_gpu_probe.ps1 -Scene res://tests/fun_audit/wave2_capture.tscn
##     -UserArguments "--out-dir=<dir> --seed=424242"
const UiMeasure:=preload("res://tests/fun_audit/ui_measure.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const OPENING_FEET:=656.17
var terrain:Node
var out_dir:=""
var log_file:FileAccess
var aims_taken:Array[String]=[]

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	out_dir=_arg("out-dir",ProjectSettings.globalize_path("user://wave2_capture/"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	log_file=FileAccess.open(out_dir.path_join("ui_measure.jsonl"),FileAccess.WRITE)
	var size:=Vector2i(1600,900)
	get_window().size=size;get_window().content_scale_size=size
	GameState.reset_for_new_world(int(_arg("seed","424242")))
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose(_arg("ambition","makers"))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(90)
	# 1. The founding screen: the opening view, then the hearth being named.
	await _cap("01-founding-opening")
	var tries:=0
	while not GameState.settlement_site_committed and tries<40:
		tries+=1
		terrain._start_settlement_here()
		if not GameState.settlement_site_committed:
			terrain.advance_world_time(1.0);_clear();await _frames(2)
	await _frames(30)
	await _cap("02-founding")
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	await _frames(12)
	_measure("founding")
	# 2. Day 30 at 200 m, with the HUD as the player has it.
	await _advance_to(30)
	await _look_at_hearth(OPENING_FEET)
	await _cap("03-day30-200m")
	_measure("day 30")
	# 3. Year 5: the map, the Court and the aim sheet.
	await _advance_to(5*365)
	await _look_at_hearth(OPENING_FEET)
	await _cap("04-year5-map")
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and dir.has_method("open_court"):
		dir.open_court({})
		await _frames(90)
		await _cap("05-year5-court")
		if is_instance_valid(dir.get("modal")):(dir.modal as Node).queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.clear()
		await _frames(10)
	terrain._on_hud_section_requested("world",0)
	await _frames(40)
	await _cap("06-year5-aim-sheet")
	terrain._on_hud_section_requested("",0)
	await _frames(6)
	_measure("year 5")
	log_file.close()
	var live:=Aims.active()
	print("WAVE2_CAPTURE DONE aim=%s taken=%s" % [String(live.get("title","")),str(aims_taken)])
	get_tree().quit(0)

func _advance_to(day:int)->void:
	terrain._set_game_speed(5)
	while GameState.elapsed_days<day:
		_clear()
		terrain.advance_world_time(1.0)
		_take_aim()
		if int(GameState.elapsed_days)%5==0:await get_tree().process_frame
	_clear()
	terrain._set_game_speed(0)
	await _frames(20)

func _take_aim()->void:
	## A plausible player summons whoever holds an aim proposal and takes it up.
	for m in Hall.matters():
		if String(m.get("situation_type",""))!="aim":continue
		var opened:=Hall.open_matter(String(m.id))
		var id:=String(opened.get("id",""))
		if id=="":continue
		var pick:=""
		for o in Hall.options(id):
			if String(o.id).begins_with("aim_adopt:") and pick=="":pick=String(o.id)
		if pick=="":
			for o in Hall.options(id):
				if bool(o.get("enabled",true)) and pick=="":pick=String(o.id)
		Hall.resolve(id,pick)
		aims_taken.append(pick)

func _clear()->void:
	var pause:=preload("res://scripts/hud/simulation_pause.gd")
	if terrain.game_speed<=0.0:
		if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
		pause.owners.clear()
		terrain._set_game_speed(5)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.get("modal")):
		var id:String=String(dir.modal.audience_id)
		for option in Hall.options(id):
			if bool(option.get("enabled",true)):
				Hall.resolve(id,String(option.id));break
		dir.modal.queue_free()
		pause.owners.clear()
	if PeopleDirection.needs_century_choice():
		PeopleDirection.choose(_arg("ambition","makers"))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()

func _look_at_hearth(feet:float)->void:
	var at:=GameState.settlement_founded_at
	terrain._set_camera_target(Vector3(at.x,terrain._height_at(at.x,at.z),at.z))
	terrain._inspect_aerial_altitude(feet)
	await _frames(150)

func _measure(label:String)->void:
	var row:=UiMeasure.measure(terrain,label)
	row["day"]=int(GameState.elapsed_days)
	log_file.store_line(JSON.stringify(row))
	log_file.flush()

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var p:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(p)
	print("WAVE2 capture ",p)
