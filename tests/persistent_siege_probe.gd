extends Node
func _ready()->void:
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	GameState.ensure_population_total(1000);GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Town guard",[{"id":1,"unit":"levy","weapon":"improvised","count":100,"authorized_count":100,"equipment":100,"training":.5}],.8,.8)
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert(MilitaryCampaign.begin_siege().get("ok",false))
	MilitaryCampaign.active_siege.blockade=.75
	var identity:=String(MilitaryCampaign.active_siege.id)
	for stage in [0,2,3,4]:
		MilitaryCampaign.settlement_defense.stage=stage
		for dimensions in [Vector2i(800,600),Vector2i(1280,900)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			var start:=Time.get_ticks_usec()
			preload("res://scripts/hud/siege_screen.gd").open(identity)
			var view:CanvasLayer=get_tree().root.get_meta("persistent_siege_view")
			await get_tree().process_frame;await get_tree().process_frame
			assert(is_instance_valid(view))
			assert(view.scene.figure_count<=192)
			assert(view.scene.building_count<=96)
			assert(get_viewport().get_visible_rect().encloses(view.stage.get_global_rect()))
			assert(get_viewport().get_visible_rect().encloses(view.feedback.get_global_rect()))
			view.scene.focus("gate");view.scene.focus("city");view.scene.focus("overview")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://artifacts/siege-%d-%d.png" % [stage,dimensions.x])
			print("SIEGE_ENTRY stage=",stage," size=",dimensions," us=",Time.get_ticks_usec()-start," figures=",view.scene.figure_count," buildings=",view.scene.building_count)
			view.queue_free();await get_tree().process_frame
			assert(String(MilitaryCampaign.active_siege.id)==identity)
	preload("res://scripts/hud/siege_screen.gd").open(identity)
	await get_tree().process_frame;await get_tree().process_frame
	var persistent:CanvasLayer=get_tree().root.get_meta("persistent_siege_view")
	persistent._siege_order("assault")
	assert(not MilitaryCampaign.active_engagement.is_empty())
	for turn in 16:
		if MilitaryCampaign.active_engagement.is_empty():break
		persistent._battle_order("push")
	assert(MilitaryCampaign.active_engagement.is_empty())
	assert(is_instance_valid(persistent))
	assert(not persistent.last_snapshot.active)
	persistent.queue_free();await get_tree().process_frame
	print("PERSISTENT_SIEGE_PASS open/unwalled/earthworks/palisade/stone, two sizes, camera, reopen")
	get_tree().quit()
