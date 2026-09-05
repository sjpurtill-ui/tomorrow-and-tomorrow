extends Node
func _ready()->void:
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();PeopleDirection.choose("inquiry")
	var terrain:=preload("res://local_terrain.tscn").instantiate();add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0);terrain.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.known_discoveries.append("food_drying");GameState.discovery_adoption["food_drying"]=1.0
	var known_before:Array=GameState.known_discoveries.duplicate()
	for dimensions in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		for mode:String in ["inquiry","economy"]:
			terrain.hud.open_dock(mode,1)
			await get_tree().process_frame;await get_tree().process_frame
			var layer:CanvasLayer=terrain.hud.get_meta("knowledge_atlas")
			var atlas=layer.get_child(0)
			assert(not terrain.hud.dock.visible)
			assert(atlas.plot.size.x>=700 and atlas.plot.size.y>=130)
			assert(get_viewport().get_visible_rect().encloses(atlas.action.get_global_rect()))
			for item:Dictionary in atlas.records:
				if item.status=="LOCKED":assert(item.name=="Unexplored question" and item.effects.is_empty())
			atlas.plot.fit();atlas.step(1);atlas.plot.fit()
			assert(GameState.known_discoveries==known_before)
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://artifacts/%s-atlas-%d.png" % [mode,dimensions.x])
			atlas._ledger();await get_tree().process_frame
			assert(terrain.hud.dock.visible)
	terrain.hud.open_dock("inquiry",1)
	await get_tree().process_frame
	var atlas=terrain.hud.get_meta("knowledge_atlas").get_child(0)
	atlas.domain="";atlas.refresh(true)
	var chosen:=""
	for item:Dictionary in atlas.records:
		if item.ready:chosen=String(item.id);break
	assert(chosen!="")
	atlas.select(chosen);atlas.action.pressed.emit()
	assert(chosen in GameState.research_targets.values())
	assert(GameState.known_discoveries==known_before)
	print("KNOWLEDGE_ATLAS_PASS: real tabs open expanded surfaces; two sizes, selection, controls, preserved ledger, hidden outcomes withheld")
	get_tree().quit()
