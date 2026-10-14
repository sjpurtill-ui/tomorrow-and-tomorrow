extends "res://tests/own_town_capture.gd"
var audit_terrain:Node
var failures:Array[String]=[]
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Isolated Test userdata required");get_tree().quit(2);return
	get_tree().create_timer(150).timeout.connect(func():get_tree().quit(3))
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late");GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	if "--known" in OS.get_cmdline_user_args():_known_profile()
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(40);audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(5)
	var hud=audit_terrain.get("hud")
	for canvas in [Vector2i(2869,1337),Vector2i(1600,900),Vector2i(1024,768)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		audit_terrain.call("_on_hud_section_requested","world",0);hud.force_dock_layout();await _frames(10)
		var board=hud.dock.find_child("PeoplesKnownBoard",true,false)
		assert(board!=null)
		var chosen:=""
		for row:Dictionary in board.model.rows:
			if not bool(row.us):chosen=String(row.civ_id);break
		board.select_people(chosen);await _frames(6);hud.dock.body_scroll.scroll_vertical=0;await _frames(3)
		await _capture_profile("foreign",canvas.x,mode)
		_check_bounds(board,canvas.x)
		hud.dock.body_scroll.scroll_vertical=440;await _frames(5);await _capture_profile("regard",canvas.x,mode)
		board.toggle(chosen);await _frames(5);hud.dock.body_scroll.scroll_vertical=900;await _frames(5);await _capture_profile("towns",canvas.x,mode)
		board.select_people("player");hud.dock.body_scroll.scroll_vertical=0;await _frames(5);await _capture_profile("ours",canvas.x,mode)
		_check_bounds(board,canvas.x)
		if canvas.x==1024:
			for row:Dictionary in board.model.rows:
				if not bool(row.us) and String(row.civ_id)!=chosen:
					board.select_people(String(row.civ_id));hud.dock.body_scroll.scroll_vertical=0;await _frames(5);await _capture_profile("limited-intelligence",canvas.x,mode);_check_bounds(board,canvas.x);break
	print("WORLD_PROFILE_CHECKS ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func _check_bounds(board:Control,width:int)->void:
	if board.get_combined_minimum_size().x>board.size.x+1:failures.append("Minimum exceeds content at "+str(width))
	if board.get_global_rect().end.x>width+1:failures.append("Content exceeds viewport at "+str(width))

func _known_profile()->void:
	# Prepared intelligence fixture, confined to this test process.
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_intelligence=0.9
	var id:=String(civ.id)
	if not WorldSimulation.actors.has(id):WorldSimulation.create_actor(id,727272)
	var state=WorldSimulation.actors[id].systems.GameState
	state.elapsed_days=GameState.elapsed_days
	state.simulation_metrics.standing_day=GameState.elapsed_days
	var index:=0
	for spec:Array in preload("res://scripts/standing.gd").STRENGTHS:
		state.simulation_metrics["standing_"+String(spec[0])]=0.2+float(index)*0.07;index+=1
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	var fields:={}
	for key:String in {"population":1800.0,"garrison":80.0,"supply":40.0,"production":0.6,"science_capacity":15.0,"life_expectancy":42.0,"gdp":500.0,"fortification":0.45}:
		var value:float={"population":1800.0,"garrison":80.0,"supply":40.0,"production":0.6,"science_capacity":15.0,"life_expectancy":42.0,"gdp":500.0,"fortification":0.45}[key]
		fields[key]={"low":value*0.95,"high":value*1.05,"quality":0.9,"observed_day":int(GameState.elapsed_days)-5,"source":"envoys","reference":"profile fixture"}
	var report:={"city_id":String(region.id),"civ_id":id,"name":"Tsaren","controller":id,"position":{"x":80.0,"z":40.0},"observed_day":int(GameState.elapsed_days)-5,"quality":0.9,"source":"envoys","reference":"profile fixture","fields":fields}
	CivilizationSystem.city_intelligence.publish("player",report,int(GameState.elapsed_days)-5)
	preload("res://scripts/standing.gd").forget()
func _frames(n:int)->void:
	for i in n:await get_tree().process_frame
func _capture_profile(label:String,width:int,mode:String)->void:
	await RenderingServer.frame_post_draw
	var prefix:="world-profile-first"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--prefix="):prefix=argument.trim_prefix("--prefix=")
	var path:=ProjectSettings.globalize_path("res://artifacts/%s-%s-%d-%s.png" % [prefix,mode,width,label])
	get_viewport().get_texture().get_image().save_png(path);print("WORLD_PROFILE_CAPTURE ",path)

