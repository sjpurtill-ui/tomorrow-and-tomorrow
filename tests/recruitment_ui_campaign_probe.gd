extends Node
func _ready()->void:
	assert(SaveSystem.load_game().has("ok"));GameState.civic_api_enabled=false
	var before:=GameState.population_total
	get_window().size=Vector2i(1400,900);get_window().content_scale_size=Vector2i(1400,900)
	var terrain:=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	for sub in [0,1]:
		terrain.hud.section_requested.emit("military",sub)
		for frame in 12:await get_tree().process_frame
		if sub==1:
			var result:=MilitaryCampaign.queue_template_training(1)
			assert(int(result.get("queued",-1))==0);assert(result.get("waiting",false))
			terrain.hud.request_immediate_dock_refresh()
			for frame in 12:await get_tree().process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/recruitment-actual-%d.png" % sub)
	assert(GameState.population_total==before)
	assert(MilitaryCampaign.grouped_home_formations().size()==1)
	assert(MilitaryCampaign.personnel_ledger().home==6)
	assert(MilitaryCampaign.training_queue.is_empty())
	print("RECRUITMENT_ACTUAL_UI_PASS home6grouped, target8, waitingwholeintake, peopleunchanged; quote=",JSON.stringify(MilitaryCampaign.template_training_quote(1)))
	get_tree().quit()
