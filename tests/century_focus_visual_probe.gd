extends Node

func _ready()->void:
	GameState.reset_for_new_world(90173)
	PeopleDirection.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	get_window().size=Vector2i(1440,900)
	get_window().content_scale_size=Vector2i(1440,900)
	PeopleDirection.open_direction()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(PeopleDirection.panel.ambition_buttons.size()==8)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/century-focus.png")
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.panel._show_page(1)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/century-advice.png")
	print("CENTURY_FOCUS_VISUAL PASS")
	get_tree().quit()
