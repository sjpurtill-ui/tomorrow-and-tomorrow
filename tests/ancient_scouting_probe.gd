extends Node
const Sheet=preload("res://scripts/hud/scouting_policy_panel.gd")
var failures:Array[String]=[]
func check(ok:bool, message:String)->void:
	if not ok: failures.append(message); push_error(message)
func settle()->void:
	for frame in 5: await get_tree().process_frame
func click(viewport:SubViewport, control:Control)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=control.get_global_rect().get_center()
		viewport.push_input(event,true)
	await settle()
func capture(viewport:SubViewport, name:String)->void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/ancient-scouting/"+name+".png")
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowAncientScoutingTests"):
		get_tree().quit(2);return
	WorldSimulation.clear();GameState.reset_for_new_world(7751);CivilizationSystem.reset_for_new_world();ProgressionSystem.reset_for_new_world()
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	GameState.ensure_population_total(360);GameState.elapsed_days=72;GameState.settlement_site_committed=true
	GameState.housing_capacity=360;GameState.simulation_metrics={"food_days":30.0};GameState.water_metrics={"intake_ratio":1.0}
	CivilizationSystem.scouting_staff.set_policy(.05,"exploration")
	CivilizationSystem.scouting_staff.data.status="Staff replace returning parties."
	CivilizationSystem.scout_missions.assign([
		{"mission_id":1,"start_day":0,"return_day":90,"personnel":6,"provisions":297.0,"target_kind":"explore","target_label":"Northern hills"},
		{"mission_id":2,"start_day":50,"return_day":80,"personnel":6,"provisions":99.0,"target_kind":"recruit_people_visit","target_label":"Flintwick"}])
	GameState.society_exchange.collections.a={"name":"Selected cutting stone","kind":"specimen","discovery_id":"stone_sorting","source_name":"Northern hills","returned_day":70,"study":.5}
	DirAccess.make_dir_recursive_absolute("res://artifacts/ancient-scouting")
	for shape:Vector2i in [Vector2i(1440,1000),Vector2i(960,720),Vector2i(340,640)]:
		var viewport:=SubViewport.new();viewport.size=shape;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var sheet:=Sheet.new();viewport.add_child(sheet);sheet.close_requested.connect(sheet.queue_free)
		await settle()
		check(Rect2(Vector2.ZERO,shape).encloses(sheet.panel.get_global_rect()),"Panel fits "+str(shape))
		check(sheet.panel.get_global_rect().encloses(sheet.close_button.get_global_rect()),"Close fits "+str(shape))
		check(sheet.panel.get_global_rect().encloses(sheet.done_button.get_global_rect()),"Done fits "+str(shape))
		await capture(viewport,"overview-%dx%d" % [shape.x,shape.y])
		sheet.scroll.ensure_control_visible(sheet.focus_buttons.recruitment);await settle()
		await click(viewport,sheet.focus_buttons.recruitment)
		check(CivilizationSystem.scouting_staff.data.focus=="recruitment","Real focus click updates policy")
		check(sheet.reception_card.visible,"Reception hold shown independently of visits")
		sheet.scroll.ensure_control_visible(sheet.reception_toggle);await settle()
		await click(viewport,sheet.reception_toggle)
		check(sheet.reception.visible,"Real why click reveals housing reasons")
		await capture(viewport,"reception-%dx%d" % [shape.x,shape.y])
		sheet.scroll.ensure_control_visible(sheet.mission_rows[1].toggle);await settle()
		await click(viewport,sheet.mission_rows[1].toggle)
		check(sheet.mission_rows[1].detail.visible,"Real party click expands the row")
		check(sheet.scroll.get_global_rect().encloses(sheet.mission_rows[1].detail.get_global_rect()),"Expanded party detail scrolls into view")
		var same:Button=sheet.mission_rows[1].toggle
		GameState.elapsed_days+=1;sheet.refresh();await settle()
		check(sheet.mission_rows[1].toggle==same and sheet.mission_rows[1].detail.visible,"Daily refresh retains input and expansion")
		await capture(viewport,"party-%dx%d" % [shape.x,shape.y])
		# Native input reaches the slider, not an ornamental substitute.
		sheet.scroll.scroll_vertical=0;await settle()
		sheet.slider.grab_focus()
		var right:=InputEventKey.new();right.keycode=KEY_RIGHT;right.pressed=true;viewport.push_input(right,true);await settle()
		check(is_equal_approx(float(CivilizationSystem.scouting_staff.data.share),.055),"Keyboard slider step changes real allocation")
		CivilizationSystem.scouting_staff.set_policy(.05,"exploration")
		if shape.x==1440:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2(10,10);viewport.push_input(event,true)
		elif shape.x==960: await click(viewport,sheet.close_button)
		else: await click(viewport,sheet.done_button)
		await settle();check(not is_instance_valid(sheet),"Map, close or Done dismisses the panel")
		viewport.queue_free();await settle()
	# A fresh off policy has no imaginary parties or finds.
	CivilizationSystem.scout_missions.clear();GameState.society_exchange.collections.clear();CivilizationSystem.scouting_staff.set_policy(0,"exploration")
	var viewport:=SubViewport.new();viewport.size=Vector2i(960,720);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	var sheet:=Sheet.new();viewport.add_child(sheet);sheet.close_requested.connect(sheet.queue_free);await settle()
	check(not sheet.latest_card.visible and sheet.mission_rows.is_empty(),"Empty world has no sample content")
	await capture(viewport,"off-empty")
	ProgressionSystem.domain_levels.production=5
	sheet.queue_free();await settle()
	sheet=Sheet.new();viewport.add_child(sheet);sheet.close_requested.connect(sheet.queue_free);await settle()
	check(not sheet.ancient,"Advanced capability switches away from ancient party art")
	await capture(viewport,"advanced-neutral")
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;viewport.push_input(escape,true);await settle()
	check(not is_instance_valid(sheet),"Escape dismisses panel")
	viewport.queue_free();await settle()
	print("ANCIENT_SCOUTING_CAPTURE ","PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
