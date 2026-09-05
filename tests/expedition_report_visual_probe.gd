extends Node

func _ready()->void:
	GameState.reset_for_new_world(1919)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.ground_survey_authority=func(_point:Vector2)->Dictionary: return {"biome":"steppe","label":"dry steppe","height":1.0}
	var route:Array=[{"x":0.0,"z":0.0},{"x":500.0,"z":-100.0},{"x":1100.0,"z":-500.0},{"x":1600.0,"z":-300.0},{"x":2200.0,"z":-900.0},{"x":2900.0,"z":-1300.0}]
	var mission:={"mission_id":12,"duration_days":365}
	var windfalls:=CivilizationSystem._resolve_scout_windfalls(mission,route,1524)
	var report:={"day":1524,"duration_days":365,"actual_days":391,"personnel":6,"returned_personnel":6,"distance_km":6820,"recruits":0,"route":route,"discoveries":mission.discoveries,"windfalls":windfalls,"journal":["Across dry grassland, then into the ridges beyond. Six travelers returned with a chart of the road."]}
	DisplayServer.window_set_size(Vector2i(1000,1100))
	get_window().size=Vector2i(1000,1100)
	get_window().content_scale_size=Vector2i(1000,1100)
	var background:=ColorRect.new()
	background.color=Color("#050d10")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var dock:PanelContainer=load("res://scripts/hud/dock_panel.gd").new()
	dock.position=Vector2(110,24)
	dock.size=Vector2(780,1052)
	add_child(dock)
	var provider:RefCounted=load("res://scripts/hud/content/dock_detail_scout_report.gd").new(null,null,report)
	dock.present(provider)
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/expedition-report.png")
		dock.present(provider,1)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/expedition-journey.png")
		var scene_journals:Dictionary={"forest":"Through ancient woodland.","desert":"Across sun-scoured drylands.","mountains":"The road climbed through high bare ground.","river":"They forded running water once."}
		for scene in scene_journals:
			provider.report["journal"]=[scene_journals[scene]]
			assert(provider._cover_path().ends_with("chronicle-%s.png" % scene))
			dock.present(provider,0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/expedition-%s.png" % scene)
	print("EXPEDITION_REPORT_VISUAL_PROBE PASS")
	get_tree().quit()
