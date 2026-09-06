extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(90173);GameState.civic_api_enabled=false
	PeopleDirection.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	get_window().content_scale_size=Vector2i.ZERO
	for size in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=size;PeopleDirection.open_direction();await frames()
		var panel:Control=PeopleDirection.panel
		assert(panel.ambition_buttons.size()==8)
		assert(panel.ambition_buttons.filter(func(button):return button.is_visible_in_tree()).size()==4)
		await capture("founding-directions-%d"%size.x)
		await click_control(panel.more_choices)
		await click_control(panel.ambition_buttons[4])
		await capture("founding-review-%d"%size.x)
		assert(PeopleDirection.ambition=="" and GameState.founding_focus=="")
		await click_control(panel.review_back)
		await click_control(panel.more_choices)
		await click_control(panel.ambition_buttons[0])
		await capture("founding-review-first-%d"%size.x)
		if size.x==800:
			var people:=GameState.population_total;var known:=GameState.known_discoveries.duplicate()
			await click_control(panel.pages[0].get_node("ConfirmFocus"))
			assert(PeopleDirection.ambition=="horizons")
			assert(GameState.founding_focus=="collective_ambition")
			assert(GameState.population_total==people and GameState.known_discoveries==known)
		else:panel.queue_free();await frames()
	print("FOUNDING_DIRECTION_PASS four choices at a time, all eight reachable, review/back no mutation, actual confirmation at small size")
	get_tree().quit()
