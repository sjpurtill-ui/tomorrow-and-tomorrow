extends Node
func _ready()->void:
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false;GameState.settlement_name="Old Home"
	GameState.ensure_population_total(200);GameState.settlement_completed=["Hearth Circle"];GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();SettlementModel.reset_for_new_world();SettlementModel.ensure_founded()
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(10000);GameState.resource_stockpiles.Timber=1000.0
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert(MilitaryCampaign.begin_siege().get("ok",false))
	for dimensions in [Vector2i(800,600),Vector2i(1280,900)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		preload("res://scripts/hud/recovery_screen.gd").open()
		await get_tree().process_frame;await get_tree().process_frame
		var view:CanvasLayer=get_tree().root.get_meta("recovery_view")
		for index in 3:
			view.tabs.current_tab=index
			await get_tree().process_frame;await get_tree().process_frame
			for child:Node in view.find_children("*","Button",true,false):
				if child.is_visible_in_tree():assert(get_viewport().get_visible_rect().encloses(child.get_global_rect()))
			assert(get_viewport().get_visible_rect().encloses(view.feedback.get_global_rect()))
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://artifacts/recovery-%d-%d.png" % [index,dimensions.x])
		view._prepare();assert(not MilitaryCampaign.recovery.data.preparation.is_empty())
		view._cancel();assert(MilitaryCampaign.recovery.data.preparation.is_empty())
		view.queue_free();await get_tree().process_frame
	print("RECOVERY_VIEW_PASS three tabs at two sizes, real prepare/cancel actions")
	get_tree().quit()
