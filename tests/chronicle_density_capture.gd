extends "res://tests/own_town_capture.gd"
## Isolated actual Chronicle widgets with centuries of records; no save calls.
var out_dir:="res://artifacts/popup-modern-c/chronicle-density"
var failures:Array[String]=[]
func check(ok:bool,why:String)->void:
	if not ok:failures.append(why);push_error(why)
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):get_tree().quit(2);return
	_world("early")
	var history:=preload("res://scripts/chronicle.gd").data()
	history.annals=[];history.entries=[]
	for year in 32:
		history.annals.append({"y":year,"name":"the year of new paths" if year==31 else "","crises":0,"deaths":0,"learned":8,"pop":90+year*3,"born":5,"buried":2,"km":year*30})
		for event in 8:history.entries.push_front({"key":"density:%d:%d" % [year,event],"day":year*365+event*40,"tier":"notice","kind":"discovery" if event%2==0 else "work","title":["The riverbank granary was renewed","Twisted cordage holds our tools","The potters roof their kiln","The ford now has a timber crossing"][event%4],"text":"The makers used the last dry weeks to finish their work. Families have more room and stronger tools; the people remember those who carried the timber."})
	history.annal_year=31;GameState.elapsed_days=32*365-1
	GameState.building_ledger=[]
	for index in 120:GameState.building_ledger.append({"id":index,"day":index*90,"kind":["Granary","Workshop","House","Well"][index%4],"event":"rebuilt" if index%3==0 else "completed","materials":{"Timber":12+index,"Clay":8},"counts_materials":true,"settlement_id":GameState.selected_player_settlement_id,"settlement_name":"Riverbank","note":"Neighbors replaced the worn beams and sealed the walls before winter. The recorded materials were taken from the stores."})
	var backdrop:=ColorRect.new();backdrop.color=Color("172B32");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	for mode in ["dark","light"]:
		T.set_color_mode(mode)
		backdrop.color=T.PAPER
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions;await _frames(4)
			var panel:=DockPanel.new();hud.add_child(panel);hud.dock=panel;panel.category_title="Chronicle"
			panel.position=Vector2(20,20);panel.size=Vector2(minf(1120,dimensions.x-40),dimensions.y-40)
			var provider=load("res://scripts/hud/content/dock_content_chronicle.gd").new(null,hud)
			panel.present(provider,0);await _frames(6)
			var feed=panel.find_child("ChronicleFeed",true,false)
			check(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()<=3,"Default Chronicle has at most3events")
			await _shot("years-%s-%d" % [mode,dimensions.x])
			feed.browse_toggle.pressed.emit();await _frames(4)
			check(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()==6,"Chronicle archive has6events")
			await _shot("archive-%s-%d" % [mode,dimensions.x])
			feed.open_key=String(feed.archive_records()[0].entry.key);feed._render_list();await _frames(3)
			await _shot("reading-%s-%d" % [mode,dimensions.x])
			panel.present(provider,2);await _frames(6)
			var works=panel.find_child("ChronicleWorksReader",true,false)
			check(works.data.records.size()==120,"Every building record retained")
			await _shot("built-%s-%d" % [mode,dimensions.x])
			works.browse_button.pressed.emit();await _frames(4)
			var building_choices:Array=works.choices.get_children().filter(func(node:Node)->bool:return node is PanelContainer)
			check(building_choices.size()==6,"Six building records are shown")
			check((building_choices.back() as Control).get_global_rect().end.y<=dimensions.y-20,"All six building choices fit the viewport")
			await _shot("built-archive-%s-%d" % [mode,dimensions.x])
			panel.queue_free();await _frames(3)
		var narrow=preload("res://scripts/hud/chronicle_feed.gd").new();narrow.position=Vector2(20,20);narrow.size=Vector2(420,680);hud.add_child(narrow)
		var narrow_provider=load("res://scripts/hud/content/dock_content_chronicle.gd").new(null,hud)
		narrow.setup(narrow_provider.tab(0).blocks[0]);await _frames(5)
		check(narrow.event_reader.visible and not narrow.event_choices.visible,"Narrow overview prioritizes full telling")
		await _shot("years-component420-%s" % mode)
		narrow.event_back.pressed.emit();await _frames(3)
		check(narrow.event_choices.visible and not narrow.event_reader.visible,"Narrow Back restores event choices")
		await _shot("choices-component420-%s" % mode)
		narrow.queue_free();await _frames(3)
	print("CHRONICLE_DENSITY ","PASS" if failures.is_empty() else "FAIL "+str(failures));get_tree().quit(0 if failures.is_empty() else 1)
func _frames(n:int)->void:
	for i in n:await get_tree().process_frame
func _shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var path:=ProjectSettings.globalize_path(out_dir.path_join(name+".png"));get_viewport().get_texture().get_image().save_png(path);print("SHOT ",path)
