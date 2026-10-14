extends "res://tests/own_town_capture.gd"
## Private graphical review: explicit fixture state and isolated preferences.
var audit_terrain:Node
var failures:Array[String]=[]
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():
		push_error("Home probe needs isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(150.0).timeout.connect(func():get_tree().quit(3))
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme","light" if "--light" in OS.get_cmdline_user_args() else "dark");config.save("user://display.cfg")
	_world("late" if "--late" in OS.get_cmdline_user_args() else "early")
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud=audit_terrain.get("hud")
	var canvases:Array[Vector2i]=[Vector2i(2869,1337),Vector2i(1600,1000),Vector2i(1024,720)]
	if "--overview-only" in OS.get_cmdline_user_args():canvases.append_array([Vector2i(1600,1000),Vector2i(1024,720)])
	for canvas in canvases:
		get_window().size=canvas;get_window().content_scale_size=canvas
		for entry:Array in [["overview","settlement",0],["people","overview",0],["culture","civ",0],["council","civ",1]]:
			if "--overview-only" in OS.get_cmdline_user_args() and entry[0]!="overview":continue
			audit_terrain.call("_on_hud_section_requested",String(entry[1]),int(entry[2]));hud.call("force_dock_layout");await _frames(10)
			await _capture_view(String(entry[0]),canvas.x)
			var board=hud.dock.find_child({"overview":"SettlementOverview","people":"PeopleScreen","culture":"CulturePanel"}.get(entry[0],"Missing"),true,false)
			if board and board.get_combined_minimum_size().x>board.size.x+1:failures.append("Content overflows "+String(entry[0])+" "+str(canvas.x))
			if board and board.get_global_rect().end.x>canvas.x+1:failures.append("Page exceeds viewport "+String(entry[0])+" "+str(canvas.x))
			if entry[0]=="people":
				var faces:Array=hud.dock.find_children("Face_*","Button",true,false)
				if not faces.is_empty():faces[0].pressed.emit();await _frames(8);await _capture_view("person",canvas.x)
				var ruler=hud.dock.find_child("WorkRuler",true,false)
				if ruler:
					ruler.pressed.emit();await _frames(10);hud.dock.body_scroll.scroll_vertical=0;await _capture_view("manual-work",canvas.x)
					var leaders=hud.dock.find_child("WorkLeaders",true,false)
					if leaders:leaders.pressed.emit();await _frames(8)
			if entry[0] in ["overview","people","culture"]:
				hud.dock.body_scroll.scroll_vertical=100000;await _frames(8);await _capture_view(String(entry[0])+"-lower",canvas.x)
		if "--overview-only" in OS.get_cmdline_user_args():continue
		for detail:Array in [["health","dock_detail_health",0],["hardships","dock_detail_health",1],["population","dock_detail_population_ledger",0],["deaths","dock_detail_population_ledger",1],["capacity","dock_detail_capacity",0],["leadership","dock_detail_settlement_people",0]]:
			var script=load("res://scripts/hud/content/"+String(detail[1])+".gd")
			var provider=script.new(audit_terrain,hud,GameState.selected_player_settlement_id) if detail[0]=="leadership" else script.new(audit_terrain,hud)
			hud.open_detail(provider,int(detail[2]));hud.force_dock_layout();await _frames(10);hud.dock.body_scroll.scroll_vertical=0;await _frames(3)
			await _capture_view(String(detail[0]),canvas.x)
			hud.dock.body_scroll.scroll_vertical=100000;await _frames(6);await _capture_view(String(detail[0])+"-lower",canvas.x)
	if not "--overview-only" in OS.get_cmdline_user_args():await _record_proofs(hud)
	print("HOME_REDESIGN_CHECKS ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _record_proofs(hud:Control)->void:
	# Explicit review fixtures, kept entirely in this isolated process.
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720)
	GameState.known_discoveries.append("clinical_observation_rounds");GameState.discovery_adoption["clinical_observation_rounds"]=1.0
	var care_provider=preload("res://scripts/hud/content/dock_detail_health.gd").new(audit_terrain,hud)
	hud.open_detail(care_provider,0);hud.force_dock_layout();await _frames(10);hud.dock.body_scroll.scroll_vertical=0;await _frames(3)
	await _capture_view("care-available",1024)
	var data:Dictionary=care_provider.tab(0)
	for block:Dictionary in data.blocks:
		if String(block.get("type",""))=="actions" and String(block.get("heading","")).contains("lore keepers"):
			(block.items[2].on_press as Callable).call()
			if not is_equal_approx(float(preload("res://scripts/civilian_care.gd").data().staff_share),0.5):failures.append("Care half-share callback did not apply")
	var log:Dictionary=preload("res://scripts/hardship_log.gd").state();log.entries=[]
	GameState.demographic_ledger.clear();GameState.lifetime_deaths=24
	for index in 12:
		var day:=int(GameState.elapsed_days)-index*60
		log.entries.append({"id":"review:%d"%index,"type":"sickness" if index%2==0 else "flood","name":"River fever" if index%2==0 else "Flood at Seanstone","start":day,"end":day+10,"dead":2,"ill":12,"place":"Seanstone"})
		GameState.demographic_ledger.append({"kind":"death","day":day,"cause":"Sickness" if index%2==0 else "Flood","location":"Seanstone","target_id":"review_seat","count":2})
	log.revision=int(log.get("revision",0))+1
	for entry:Array in [["hardships-filled",care_provider,1],["deaths-filled",preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(audit_terrain,hud),1]]:
		hud.open_detail(entry[1],entry[2]);hud.force_dock_layout();await _frames(10);hud.dock.body_scroll.scroll_vertical=0;await _frames(3);await _capture_view(entry[0],1024)
		hud.dock.body_scroll.scroll_vertical=100000;await _frames(5);await _capture_view(entry[0]+"-lower",1024)

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame

func _capture_view(label:String,width:int)->void:
	await RenderingServer.frame_post_draw
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	var prefix:="home-modern"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--prefix="):prefix=argument.trim_prefix("--prefix=")
	var path:String=ProjectSettings.globalize_path("res://artifacts/%s-%s-%d-%s.png" % [prefix,mode,width,label])
	get_viewport().get_texture().get_image().save_png(path)
	print("HOME_CAPTURE ",path)
