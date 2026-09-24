extends Node
## TEST capture of the caravan UI on the real map (run only through
## tools/run_isolated_gpu_probe.ps1). Writes PNGs to reports/caravans/.
## Not the player game: a fresh seeded world inside the probe process.

const Leader:=preload("res://scripts/caravan_leader.gd")
var terrain:Node
var hud:Control
var failures:Array[String]=[]

func frames(count:int=8)->void:
	for frame in count:await get_tree().process_frame

func capture(name:String)->void:
	await frames();await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://reports/caravans/%s.png" % name)
	get_viewport().get_texture().get_image().save_png(path)
	print("CARAVAN_CAPTURE ",path)

func advance_days(count:int)->void:
	for day in count:
		terrain.game_speed=1.0
		terrain.advance_world_time(1.0)
		terrain.game_speed=0.0
	terrain._update_time_interface()
	terrain.time_interface_day=-1
	terrain._update_time_interface()
	await frames(4)

func _ready()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/caravans"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	get_window().content_scale_size=Vector2i.ZERO
	get_window().size=Vector2i(1600,900)
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	await frames();hud=terrain.hud
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	await frames()
	# ---- the founding caravan: pick a destination and let the leader march
	var start:Vector2=CivilizationSystem.player_world_origin
	var started:=false
	for radius:float in [38.0,28.0,20.0]:
		for spoke in 12:
			var point:=start+Vector2.from_angle(TAU*float(spoke)/12.0)*radius
			if not bool(terrain._settlement_surface_assessment(Vector3(point.x,terrain._height_at(point.x,point.y),point.y)).get("valid",false)):continue
			terrain._move_settlers_to(Vector3(point.x,terrain._height_at(point.x,point.y)+0.002,point.y))
			if not (GameState.founding_journey.get("caravan",{}) as Dictionary).is_empty():
				started=true
				break
		if started:break
	if not started:failures.append("no founding caravan could be started")
	await advance_days(3)
	var here:Vector2=CivilizationSystem.player_world_origin
	terrain._set_camera_target(Vector3(here.x,terrain._height_at(here.x,here.y),here.y))
	await frames(12)
	await capture("founding-caravan-card")
	# ---- settle, then form an expansion caravan
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(here.x,0.0,here.y)
	GameState.founding_journey.clear()
	GameState.convoy_traveling=false
	GameState.ensure_population_total(900)
	GameState.food_stocks["Dry staples"]=float(GameState.food_stocks.get("Dry staples",0.0))+30000.0
	GameState.resource_stockpiles["Food"]=float(GameState.resource_stockpiles.get("Food",0.0))+30000.0
	GameState.resource_stockpiles["Timber"]=400.0
	GameState.resource_stockpiles["Fiber Plants"]=400.0
	CivilizationSystem.register_player_origin(here)
	CivilizationSystem._add_revealed_area(here,70.0,"probe chart")
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	terrain._refresh_settlement_network(true)
	await frames()
	terrain._open_caravan_formation()
	await capture("formation-card")
	var card:Control=terrain.caravan_formation_card
	if not is_instance_valid(card):failures.append("formation card did not open")
	else:
		var choose:Button=card.find_child("ChooseDestination",true,false)
		choose.pressed.emit()
	await frames()
	var destination:=Vector3.ZERO
	for radius:float in [45.0,34.0,26.0,18.0,12.0]:
		for spoke in 16:
			var point:=here+Vector2.from_angle(TAU*float(spoke)/16.0)*radius
			var candidate:=Vector3(point.x,terrain._height_at(point.x,point.y)+0.006,point.y)
			if bool(terrain._settlement_convoy_site_assessment(candidate,true).get("valid",false)):
				destination=candidate
				break
		if destination!=Vector3.ZERO:break
	if destination==Vector3.ZERO:failures.append("no valid expansion destination")
	else:
		terrain._begin_settlement_convoy(destination)
		await capture("caravan-review")
		# The ruler enlarges the party in the review: the quote reprices in place.
		var people:SpinBox=terrain.caravan_formation_controls.get("people")
		if is_instance_valid(people):
			people.value=minf(people.max_value,people.value+20.0)
			await frames()
			if int(terrain.settlement_convoy_pending_quote.get("population",0))!=roundi(people.value):failures.append("the review did not reprice the larger party")
			await capture("caravan-review-60")
		if is_instance_valid(terrain.settlement_convoy_confirm_button) and not terrain.settlement_convoy_confirm_button.disabled:
			terrain._confirm_settlement_convoy()
		else:
			failures.append("the review could not send: %s" % (terrain.settlement_convoy_confirm_status.text if is_instance_valid(terrain.settlement_convoy_confirm_status) else "no panel"))
		await advance_days(1)
		var convoy_position:Vector2=GameState.settlement_convoy.get("position",here)
		terrain._set_camera_target(Vector3(convoy_position.x,terrain._height_at(convoy_position.x,convoy_position.y),convoy_position.y))
		await frames(12)
		await capture("settler-caravan-card")
	if failures.is_empty():
		print("CARAVAN_VISUAL PASS")
		get_tree().quit(0)
	else:
		for failure in failures:push_error("CARAVAN_VISUAL FAIL: "+failure)
		get_tree().quit(1)
