extends Node
const Sheet=preload("res://scripts/hud/exchange_collection_panel.gd")
const E=preload("res://scripts/society_exchange.gd")
var failures:Array[String]=[]
func check(value:bool,message:String)->void:
	if not value:failures.append(message);push_error(message)
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowKnowledgeExchangeTests"):
		get_tree().quit(2);return
	WorldSimulation.clear();GameState.reset_for_new_world(777)
	CivilizationSystem.reset_for_new_world();DiscoverySystem.reset_for_new_world()
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=230
	GameState.population_allocations.Knowledge=20;GameState.population_allocations.Administration=8
	GameState.simulation_metrics={"food_days":30,"food_intake_ratio":1.0};GameState.water_metrics={"intake_ratio":1.0}
	E.data().integration=[{"origin":"cedar","count":12.0,"remaining":9.0}]
	for pair in [["clay_shaping","artifact","Clay trial vessel","Cedar River",1.0],["oral_epics","culture","An account of Oral Epics","Hillhaven",.65],["stone_sorting","specimen","Stone specimen","Eastern foothills",.15]]:
		var id:="sample:"+String(pair[0]);E.data().collections[id]={"id":id,"kind":pair[1],"name":pair[2],"source_id":"cedar","source_name":pair[3],"position":{"x":12.0,"z":2.0},"observed_day":20,"returned_day":40,"discovery_id":pair[0],"study":pair[4],"work":90.0,"signals":[]}
	E.data().evidence.clay_shaping="sample:clay_shaping"
	DirAccess.make_dir_recursive_absolute("res://artifacts/knowledge-exchange")
	FileAccess.open("res://artifacts/knowledge-exchange/.gdignore",FileAccess.WRITE).close()
	for shape:Vector2i in [Vector2i(960,720),Vector2i(340,640)]:
		var viewport:=SubViewport.new();viewport.size=shape;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var layer:=CanvasLayer.new();viewport.add_child(layer);var sheet:=Sheet.new();layer.add_child(sheet)
		for frame in 8:await get_tree().process_frame
		check(Rect2(Vector2.ZERO,shape).encloses(sheet.panel.get_global_rect()),"Panel stays within "+str(shape))
		check(sheet.cards.get_child_count()==3,"Three distinct finds shown")
		check(sheet.panel.get_global_rect().encloses(sheet.filter.get_global_rect()),"Filter reachable at "+str(shape))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://artifacts/knowledge-exchange/collection-%dx%d.png" % [shape.x,shape.y])
		if shape.x>700:
			var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(40,180);viewport.push_input(click,true)
		else:
			var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;viewport.push_input(escape,true)
		for frame in 4:await get_tree().process_frame
		check(not is_instance_valid(sheet),"Map click / Escape closes collection")
		viewport.queue_free();await get_tree().process_frame
	print("EXCHANGE_VISUAL ","PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
