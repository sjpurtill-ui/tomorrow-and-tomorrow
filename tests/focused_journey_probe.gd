extends Node
var terrain:Node
var hud:Control
func frames()->void:
	for frame in 8:await get_tree().process_frame
func click_label(text:String)->void:
	for label in hud.find_children("*","Label",true,false):
		if label.text!=text or not label.is_visible_in_tree():continue
		var node:Node=label
		while node!=null and not node is Button:node=node.get_parent()
		if node==null:continue
		var point:Vector2=node.get_global_rect().get_center()
		assert(get_viewport().get_visible_rect().has_point(point),"Action must be visible without scrolling: "+text)
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;Input.parse_input_event(event);await get_tree().process_frame
		await frames();return
	assert(false,"Action not found: "+text)
func capture(name:String)->void:
	await frames();await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/journey-"+name+".png")
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	await frames();hud=terrain.hud
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	get_window().content_scale_size=Vector2i.ZERO
	for dimensions in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=dimensions;await frames()
		hud.open_dock("settlement",0);await capture("settlement-"+str(dimensions.x))
		await click_label("LOCAL PRIORITY")
		assert(hud.detail_dock.visible and not hud.dock.visible)
		var id:=GameState.selected_player_settlement_id
		await click_label("RESEARCH")
		assert(String(GovernmentPeopleSystem.settlement_management(id).focus)=="research")
		await capture("priority-"+str(dimensions.x))
		hud.close_detail();await frames();assert(hud.dock.visible and hud.dock.sub==0)
		await click_label("LOCAL LEADERSHIP");assert(not hud.dock.visible)
		hud.close_detail();await frames()
		hud.open_dock("economy",0);await capture("economy-"+str(dimensions.x))
		hud.providers.economy._open_water();await frames()
		var water_before:=GameState.water_metrics.duplicate(true)
		await click_label("PRIORITIZE WATER");assert(String(GovernmentPeopleSystem.settlement_management(id).focus)=="water")
		assert(GameState.water_metrics==water_before,"Direction must not create instant water")
		GameState.elapsed_days+=1
		ResourceSystem.process_day(terrain._discovery_context())
		assert(GameState.water_metrics.has("required_today"))
		hud.request_immediate_dock_refresh();await frames()
		await capture("water-"+str(dimensions.x));hud.close_detail();await frames()
		await click_label("TODAY’S FOOD");await capture("food-flow-"+str(dimensions.x))
		var parent=hud.detail_dock.provider
		hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,hud));await frames()
		hud.handle_escape();await frames();assert(hud.detail_dock.provider==parent and not hud.dock.visible)
		hud.handle_escape();await frames();assert(hud.dock.visible and not hud.detail_dock.visible)
		hud.handle_escape();assert(not hud.dock.visible)
	print("FOCUSED_JOURNEY_PASS 1280x900 and 800x600: first actions visible, real priority changed, one report at a time, nested Back and map return")
	get_tree().quit()
