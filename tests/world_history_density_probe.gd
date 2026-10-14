extends "res://tests/own_town_capture.gd"
var failures:Array[String]=[]
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Isolated Test userdata required");get_tree().quit(2);return
	get_tree().create_timer(150).timeout.connect(func():get_tree().quit(3))
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late");GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	var terrain=load("res://local_terrain.tscn").instantiate();terrain.set("suppress_naming_prompt",true);add_child(terrain)
	await _frames(40);terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(terrain.get("settlement_naming_panel")):terrain.get("settlement_naming_panel").queue_free()
	await _frames(5);var hud=terrain.get("hud")
	for canvas in [Vector2i(2869,1337),Vector2i(1600,900),Vector2i(1024,768)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		terrain.call("_on_hud_section_requested","world",2);hud.force_dock_layout();await _frames(8)
		var b=hud.dock.find_child("WorldHistoryBoard",true,false);assert(b!=null)
		b.update_block({"entries":_entries(),"view":{}});hud.dock.body_scroll.scroll_vertical=0;await _frames(5)
		await _capture("recent",canvas.x,mode);_bounds(b,canvas.x)
		b.set_archive(true);await _frames(5);await _capture("archive",canvas.x,mode);_bounds(b,canvas.x)
		b.select_entry(b.chosen()[2]);await _frames(5);await _capture("selected",canvas.x,mode);_bounds(b,canvas.x)
		b.find_child("BackToResults",true,false).pressed.emit();await _frames(3);await _capture("back-results",canvas.x,mode)
		b.change_page(2);await _frames(4);await _capture("last-page",canvas.x,mode)
		b.search.text="amber";b.search.text_changed.emit("amber");await _frames(4);await _capture("search",canvas.x,mode)
		b.search.text="absent";b.search.text_changed.emit("absent");await _frames(4);await _capture("no-match",canvas.x,mode)
	print("WORLD_HISTORY_CHECKS ",failures);get_tree().quit(0 if failures.is_empty() else 1)
func _entries()->Array:
	var out:Array=[]
	var titles:=["Envoys returned from the Cedar People","Scouts found a river crossing","Peace agreed at the northern ford","Caravans reached the amber coast","A raid at the border farms","Word from the western towns"]
	for i in 17:out.append({"day":65000-i*160,"season":["Spring","Summer","Autumn","Winter"][i%4],"title":titles[i%6],"text":["The Cedar People received our envoys beside the old ford. They spoke of the new river road and the harvest in their northern towns.","Our scouts crossed the ridge and found a ford beside the cedar woods. Their report marks a route toward the northern towns.","Both peoples agreed to end the fighting at the northern ford. The settlement leaves the crossing open to caravans.","Caravans returned from the amber coast with news of the towns beyond the bay.","A raiding party reached the border farms. The watch raised the alarm and the defenders drove them back.","A messenger brought news of the western towns and their new market."][i%6],"group":["contact","scout","war"][i%3],"icon":["contact","scout","war"][i%3],"count":2 if i==0 else 1,"on_open":func():print("WORLD_HISTORY_RELATED_ACTION"),"action_label":"Open related page"})
	for entry:Dictionary in out:entry.season=preload("res://scripts/chronicle.gd").date_label(int(entry.day)).get_slice(" · ",1)
	return out
func _bounds(b:Control,width:int)->void:
	if b.get_combined_minimum_size().x>b.size.x+1:failures.append("Minimum exceeds content at "+str(width))
	if b.get_global_rect().end.x>width+1:failures.append("Content exceeds viewport at "+str(width))
func _frames(n:int)->void:
	for i in n:await get_tree().process_frame
func _capture(label:String,width:int,mode:String)->void:
	await RenderingServer.frame_post_draw
	var prefix:="world-history-first"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):prefix=arg.trim_prefix("--prefix=")
	var path:=ProjectSettings.globalize_path("res://artifacts/%s-%s-%d-%s.png" % [prefix,mode,width,label])
	get_viewport().get_texture().get_image().save_png(path);print("WORLD_HISTORY_CAPTURE ",path)
