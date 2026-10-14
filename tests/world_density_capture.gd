extends "res://tests/own_town_capture.gd"
## Private GPU review of production World pages at real dock widths.
var audit_terrain:Node
var failures:Array[String]=[]

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("Requires isolated test userdata");get_tree().quit(2);return
	_world("early")
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	audit_terrain=load("res://local_terrain.tscn").instantiate()
	audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50)
	audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(6)
	for index in 18:
		CivilizationSystem.scout_reports.append({"mission_id":1000+index,"day":int(GameState.elapsed_days)-index*7,"personnel":4,"returned_personnel":4,"target_id":"open_world","target_label":"Open exploration","route":[{"x":0,"z":0},{"x":20+index,"z":-20-index}],"distance_km":40+index,"archive_reviewed":true,"discoveries":[{"kind":"deposit","title":"Copper above the river" if index%2==0 else "Timber in the valley","description":"A scout report from the northern woodland"}],"journal":["They crossed the woodland."]})
	var out:=ProjectSettings.globalize_path("res://artifacts/popup-audit/world-density")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in ["dark","light"]:
		T.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			for entry:Array in [["peoples","world",0],["expeditions","world",1],["history","world",2],["standing","standing",0],["spies","eyes",0]]:
				audit_terrain.call("_on_hud_section_requested",String(entry[1]),int(entry[2]))
				audit_terrain.get("hud").call("force_dock_layout")
				await _frames(10)
				var panel:Control=audit_terrain.get("hud").get("dock")
				if panel.get_global_rect().end.x>dimensions.x+1:failures.append("Dock exceeds viewport: "+str(entry))
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out+"/%s-%s-%d.png" % [String(entry[0]),mode,dimensions.x])
				if String(entry[0])=="expeditions":
					var expeditions:=panel.find_child("ExpeditionsBoard",true,false)
					if expeditions.visible_items.size()!=3:failures.append("Expeditions digest must show three reports")
					(expeditions.find_child("BrowseReports",true,false) as Button).pressed.emit();await _frames(10)
					if expeditions.visible_items.size()!=6 or expeditions.top.visible:failures.append("Expeditions archive must focus six records")
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(out+"/expeditions-archive-%s-%d.png" % [mode,dimensions.x])
					(expeditions.find_child("BrowseReports",true,false) as Button).pressed.emit()
	print("WORLD_DENSITY ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame
