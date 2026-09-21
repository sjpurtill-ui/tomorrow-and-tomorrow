extends Node
var failures:Array[String]=[]
func _ready()->void:
	GameState.reset_for_new_world(991704);MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(500)
	GameState.settlement_name="SeanTown";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy Band","entries":[{"unit":"levy","weapon":"improvised","count":20}]}]
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for i in 3:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	for canvas in [Vector2i(1600,1000),Vector2i(1024,640)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		for queued in [false,true]:
			MilitaryCampaign.recruit_deploy.reset();MilitaryCampaign.training_queue=[];MilitaryCampaign.aggregate_recruits=0
			if queued:MilitaryCampaign.recruit_deploy.add(1,2,2,false)
			terrain.hud.open_dock("military",1)
			for i in 12:await get_tree().process_frame
			var board=terrain.hud.dock.find_child("RecruitDeployBoard",true,false)
			if board==null:failures.append("Board missing")
			elif board.get_combined_minimum_size().x>terrain.hud.dock.body_scroll.size.x:failures.append("Horizontal overflow "+str(canvas))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/recruit-layout-"+str(canvas.x)+"-"+str(queued)+".png")
	print("RECRUIT_LAYOUT_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
