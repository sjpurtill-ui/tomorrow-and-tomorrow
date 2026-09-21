extends Node
## Isolated real-HUD navigation check. Never loads or writes campaign saves.
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok: failures.append(message);push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(551188)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	var terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	for i in 3:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	var hud=terrain.hud
	var labels:Array=[]
	for spec in hud.SECTIONS:labels.append(spec.label)
	check(labels.slice(0,9)==["Overview","People","Food","Materials","Wealth","Buildings","Production","Culture","Security"],"Approved label order")
	for spec in hud.SECTIONS:
		var target=String(spec.get("section",spec.id))
		var sub=int(spec.get("sub",0))
		hud.rail_buttons[spec.id].pressed.emit()
		for i in 3:await get_tree().process_frame
		check(hud.active_section==target and hud.dock.sub==sub,"Destination: "+spec.id)
		hud.rail_buttons[spec.id].pressed.emit()
		await get_tree().process_frame
		check(hud.active_section=="","Toggle closed: "+spec.id)
	for stage in ["reciprocity","weighed_metal","currency"]:
		GameState.economy_stage=stage
		GameState.public_treasury=1280
		GameState.private_currency=3460
		GameState.currency_hoards=820
		GameState.mutual_aid_reserve=240
		for canvas in [Vector2i(1600,1000),Vector2i(1024,640)]:
			get_window().size=canvas
			get_window().content_scale_size=canvas
			hud.open_dock("economy",2)
			for i in 8:await get_tree().process_frame
			check(hud.dock.get_global_rect().end.x<=canvas.x,"Wealth fits width: "+stage+str(canvas))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/navigation-"+stage+"-"+str(canvas.x)+".png")
	print("APPROVED_NAVIGATION_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
