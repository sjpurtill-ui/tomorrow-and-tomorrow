extends Node
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok: failures.append(message);push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Sean"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	var primary:=GameState.selected_player_settlement_id
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","primary":false,"position":Vector2(22,-8),"population_share":0.25,"founded_day":0})
	var terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	for i in 3: await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	CivilizationSystem._add_revealed_area(Vector2(12,-8),30.0,"city selection test")
	# A previous open survey must disappear when entering either owned city.
	terrain._build_lens(terrain.interface_layer)
	terrain.lens_requested_visible=true
	terrain.lens_panel.show()
	for entry in [{"id":primary,"point":Vector3(12.002,0,-8.002)},{"id":"second","point":Vector3(22,0,-8)}]:
		terrain._inspect_location(entry.point)
		for i in 4: await get_tree().process_frame
		check(GameState.selected_player_settlement_id==entry.id,"Click selects the actual city")
		check(not terrain.lens_requested_visible and not terrain.lens_panel.visible,"City click closes the old survey")
		check(terrain.hud.dock.visible and terrain.hud.dock.find_child("SettlementOverview",true,false)!=null,"City ground opens illustrated overview")
	check(not terrain._open_owned_settlement_at(Vector3(10000,0,10000)),"Uncharted land does not reveal a city")
	check(not terrain._open_owned_settlement_at(Vector3(30,0,-8)),"Known ground outside city keeps survey routing")
	terrain._inspect_location(Vector3(30,0,-8))
	check(terrain.lens_requested_visible,"Outside-city inspection remains available")
	terrain._inspect_location(Vector3(12,0,-8))
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/city-ground-selection.png")
	print("CITY_GROUND_SELECTION_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
