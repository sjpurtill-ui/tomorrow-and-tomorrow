extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_Coherence_Test"))
	assert(SaveSystem.load_game("coherence_contact").has("ok"))
	GameState.civic_api_enabled="--live-dialogue" in OS.get_cmdline_user_args()
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900)
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);await frames();hud=terrain.hud
	var contact:Dictionary=CivilizationSystem.contact_encounters_snapshot()[0]
	var id:=String(contact.civ_id)
	await click_control(hud.rail_buttons.world)
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,hud,id));await frames();await capture("contact-evidence")
	await click_label("SPEAK WITH THEIR LEADER")
	var ui:=ForeignDiplomacy.panel
	assert(is_instance_valid(ui));await capture("contact-audience-quote")
	await click_control(ui.audience_button)
	assert(not CivilizationSystem.diplomatic_mission.is_empty())
	for button in ui.find_children("*","Button",true,false):
		if button.text=="RETURN":await click_control(button);break
	hud.close_detail();hud.close_dock();await click_control(hud.speed_buttons[5])
	var deadline:=Time.get_ticks_msec()+90000
	while not CivilizationSystem.diplomatic_mission.is_empty() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0])
	assert(ForeignDialogue.access(id).ok,"Actual delegates must return to establish the channel")
	ForeignDiplomacy.open(id);await frames();ui=ForeignDiplomacy.panel
	await capture("contact-audience-returned")
	if GameState.civic_api_enabled:
		var before:=GameState.elapsed_days
		ui.entry.text="What would cooperating on safer travel involve? I want to understand your concerns before deciding.";await click_control(ui.ask_button)
		deadline=Time.get_ticks_msec()+55000
		while ForeignDialogue.pending.has(id) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
		assert(not ForeignDialogue.thread(id).retryable)
		assert(GameState.elapsed_days==before)
		await capture("contact-live-question")
		ui.entry.text="Propose cooperation on routes, treating us as equals, with the standard contribution. Explain what our people would actually do.";await click_control(ui.ask_button)
		deadline=Time.get_ticks_msec()+55000
		while ForeignDialogue.pending.has(id) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
		assert(not ForeignDialogue.thread(id).retryable)
		await capture("contact-live-proposal")
		print("CONTACT_LIVE_TRANSCRIPT ",JSON.stringify(ForeignDialogue.thread(id)))
	assert(SaveSystem.save_game("coherence_audience").has("ok"))
	print("CONTACT_DIALOGUE_JOURNEY_PASS natural saved encounter, located home, actual delegates returned, channel accessible day=",GameState.elapsed_days)
	get_tree().quit()
