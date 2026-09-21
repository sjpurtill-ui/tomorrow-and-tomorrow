extends Node
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="SeanTown";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	var city:=GameState.selected_player_settlement_id
	var history:=preload("res://scripts/strategic_history.gd")
	for day in range(0,730,30):history.record(GameState.strategic_history,day,{city:{"population":120+day/4,"food_days":40+sin(day*.02)*12,"water_days":5}})
	GameState.discovery_log=[{"id":"cordage","name":"Cordage","day":640,"causal_mechanism":"Twisted fibers carry loads that loose strands cannot."},{"id":"clay_shaping","name":"Clay shaping","day":300,"causal_mechanism":"Clay holds a useful form when worked and dried."}]
	for day in range(40,600,40):GameState.record_building_event({"day":day,"settlement_id":city,"kind":"Lean-to Shelters","event":"built","material_family":"Timber and plant fibers"})
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for i in 3:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	var hud=terrain.hud
	for canvas in [Vector2i(1600,1000),Vector2i(1024,640)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		for sub in [0,1]:
			hud.open_dock("settlement",sub)
			for i in 8:await get_tree().process_frame
			check(hud.dock.get_global_rect().end.x<=canvas.x,"Fits window "+str(canvas))
			check(hud.dock.find_child("SettlementOverview" if sub==0 else "SettlementChronicle",true,false)!=null,"Illustrated view is wired")
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/settlement-"+str(sub)+"-"+str(canvas.x)+".png")
	var expected:=preload("res://scripts/hud/person_portrait.gd").texture(GovernmentPeopleSystem.settlement_leader(city)) as AtlasTexture
	for sub in [1,2]:
		hud.open_dock("economy",sub)
		for i in 4:await get_tree().process_frame
		var portrait=hud.dock.find_child("Portrait",true,false)
		check(portrait!=null,"Economy portrait exists")
		if portrait:check(portrait.texture.region==expected.region,"Same actual leader in economy "+str(sub))
	print("SETTLEMENT_PRESENTATION_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
