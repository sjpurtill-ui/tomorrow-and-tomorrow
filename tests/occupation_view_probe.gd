extends Node
func _ready()->void:
	GameState.reset_for_new_world(424242); GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize(); MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var region:Dictionary=civ.strategic_regions[0]; region.controller="player"
	for dimensions in [Vector2i(800,600),Vector2i(1280,900)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		var view:=preload("res://scripts/hud/occupation_view.gd").new()
		view.civ_id=String(civ.id);view.region_id=String(region.id);add_child(view)
		await get_tree().process_frame;await get_tree().process_frame
		assert(get_viewport().get_visible_rect().encloses(view.summary.get_global_rect()))
		for button:Button in view.policy_buttons.values():
			if button.is_visible_in_tree(): assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
		assert(get_viewport().get_visible_rect().encloses(view.feedback.get_global_rect()))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/occupation-%d.png" % dimensions.x)
		view.queue_free();await get_tree().process_frame
	print("OCCUPATION_VIEW_PASS two sizes, bounded controls")
	get_tree().quit()
