extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_GeneralCampaign_Test"))
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();GameState.civic_api_enabled=false
	GeneralCampaign.launch_requested=true
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await frames();hud=terrain.hud
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,800)
	await frames()
	assert(GeneralCampaign.active and GeneralCampaign.state.rivals.size()==2)
	var ui:Control=GeneralCampaign.screen
	await capture("general-opening")
	ui.entry.text="What would an attack cost us?";await click_control(ui.send)
	assert(GeneralCampaign.state.mission.is_empty())
	await capture("general-question")
	ui.entry.text="attack Bracken Hold";await click_control(ui.send)
	await click_control(ui.commit)
	assert(GeneralCampaign.resolving)
	var start:=GameState.elapsed_days
	var deadline:=Time.get_ticks_msec()+75000
	while GeneralCampaign.resolving and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	assert(not GeneralCampaign.resolving,"Mission must produce a report")
	assert(GameState.elapsed_days>start)
	await capture("general-first-report")
	print("GENERAL_FIRST_REPORT ",JSON.stringify(GeneralCampaign.state.reports[-1]))
	if not GeneralCampaign.state.battle.is_empty():
		for frame in 180:await get_tree().process_frame
		await capture("general-battle")
		var prior_zoom:=float(ui.diorama.zoom)
		for wheel in 5:
			var event:=InputEventMouseButton.new();event.position=ui.stage.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_WHEEL_UP;event.pressed=true;Input.parse_input_event(event);await frames();event.pressed=false;Input.parse_input_event(event);await frames()
		assert(ui.diorama.zoom<prior_zoom)
		await capture("general-battle-close")
	get_window().size=Vector2i(800,600);await frames();await capture("general-small")
	assert(get_viewport().get_visible_rect().encloses(ui.entry.get_global_rect()))
	assert(get_viewport().get_visible_rect().encloses(ui.commit.get_global_rect()))
	ui.entry.text="withdraw"
	await click_control(ui.send)
	print("WITHDRAW_DRAFT ",GeneralCampaign.state.proposal," UI ",ui.status.text)
	assert(GeneralCampaign.state.proposal.get("action","")=="withdraw")
	await click_control(ui.commit)
	print("WITHDRAW_COMMIT ",GeneralCampaign.state.status," cell ",GeneralCampaign.state.cell," UI ",ui.status.text)
	assert(GeneralCampaign.resolving or GeneralCampaign.state.cell==Vector2i.ZERO)
	deadline=Time.get_ticks_msec()+70000
	while GeneralCampaign.resolving and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	print("GENERAL_WITHDRAWAL ",JSON.stringify(GeneralCampaign.state.reports[-1]))
	assert(GeneralCampaign.state.cell==Vector2i.ZERO,"General must actually bring the survivors home")
	ui.entry.text="recover";await click_control(ui.send);await click_control(ui.commit)
	deadline=Time.get_ticks_msec()+10000
	while GeneralCampaign.resolving and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await capture("general-returned-home")
	var civilization_errors:=CivilizationSystem.validate_state()
	print("GENERAL_CIV_VALIDATION ",civilization_errors)
	assert(civilization_errors.is_empty())
	var saved:=SaveSystem.save_game("general_journey")
	assert(saved.has("ok"))
	var restored:=SaveSystem.load_game("general_journey")
	print("GENERAL_SAVE_RESTORE ",restored)
	assert(restored.has("ok"))
	print("GENERAL_CAMPAIGN_JOURNEY_PASS actual UI question, objective, commitment, world time, report, and small-window controls")
	get_tree().quit()

func click_control(node:Control)->void:
	var motion:=InputEventMouseMotion.new()
	motion.position=node.get_global_rect().get_center()
	Input.parse_input_event(motion)
	await frames()
	await super.click_control(node)
