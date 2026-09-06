extends "res://tests/manual_city_assault.gd"
var besiege_button:Button
func _ready()->void:
	await super._ready()
	# Establish a valid food-oriented founding choice so the real time controls work.
	# Military size/equipment and the dry target fixture above are unchanged.
	GameState.select_founding_focus("provision")
	MilitaryCampaign.set_process(true)
	besiege_button=Button.new();besiege_button.text="BESIEGE TEST RIVER CITY";besiege_button.custom_minimum_size.y=46;attack_button.get_parent().add_child(besiege_button);besiege_button.pressed.connect(_besiege)
	for node in find_children("*","Label",true,false):
		if node.text.begins_with("  NEW BATTLE HUD"):node.text=node.text.replace("NEW BATTLE HUD","NEW SIEGE HUD")
	get_window().title="NEW SIEGE HUD · 180 vs 119 · ISOLATED CAMPAIGN"
	for node in find_children("*","Button",true,false):
		if node.text=="RESET TEST":
			for connection in node.pressed.get_connections():node.pressed.disconnect(connection.callable)
			node.pressed.connect(func():OS.create_process(OS.get_executable_path(),["--path",ProjectSettings.globalize_path("res://"),"--fullscreen","res://tests/manual_city_siege.tscn"]);get_tree().quit())
	print("MANUAL_SIEGE_READY ",JSON.stringify({"seed":74017,"attackers":180,"defenders":119,"residents":600,"paused":terrain.game_speed==0,"siege_started":not MilitaryCampaign.active_siege.is_empty(),"user_data":OS.get_user_data_dir()}))
	if "--verify-siege-hud" in OS.get_cmdline_user_args():await _verify_siege_hud();get_tree().quit()
func _process(delta:float)->void:
	super._process(delta)
	if is_instance_valid(action_panel):action_panel.visible=action_panel.visible and MilitaryCampaign.active_siege.is_empty() and not _siege_open()
func _siege_open()->bool:return get_tree().root.has_meta("persistent_siege_view") and is_instance_valid(get_tree().root.get_meta("persistent_siege_view"))
func _besiege()->void:
	var result:Dictionary=MilitaryCampaign.order_city_operation(army_id,civ_id,city_id,true)
	if result.has("error"):action_note.text=String(result.error);return
	terrain._set_game_speed(0);preload("res://scripts/hud/siege_screen.gd").open(String(MilitaryCampaign.active_siege.id))
func _verify_siege_hud()->void:
	var marker:Node3D=terrain.player_field_army_markers[str(army_id)]
	await click(terrain.camera.unproject_position(marker.global_position))
	for frame in 5:await get_tree().process_frame
	assert(terrain.selected_army_id==army_id)
	await click(besiege_button.get_global_rect().get_center())
	for frame in 8:await get_tree().process_frame
	assert(not MilitaryCampaign.active_siege.is_empty());assert(CivilizationSystem.civilizations[0].player_relation.at_war)
	var identity:=String(MilitaryCampaign.active_siege.id)
	var hud:CanvasLayer=get_tree().root.get_meta("persistent_siege_view")
	assert(hud.last_snapshot.active and MilitaryCampaign.active_engagement.is_empty())
	await _siege_capture("orders")
	await click(hud.camera_buttons.gate.get_global_rect().get_center());assert(is_equal_approx(hud.scene.zoom,.12 if hud.terrain!=null else 65.0))
	await click(hud.camera_buttons.overview.get_global_rect().get_center())
	var stable:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	for attempt in 20:
		await click(hud.order_buttons.continue.get_global_rect().get_center())
		assert(MilitaryCampaign.export_state()==stable and terrain.game_speed==0)
		assert(not is_instance_valid(terrain.founding_focus_panel) and not is_instance_valid(PeopleDirection.panel))
		assert(not is_instance_valid(MilitaryCommandUI.battle_graphics))
	await click(hud.order_buttons.negotiate.get_global_rect().get_center())
	for frame in 4:await get_tree().process_frame
	assert(is_instance_valid(ForeignDiplomacy.panel));ForeignDiplomacy.panel.queue_free()
	for frame in 4:await get_tree().process_frame
	await click(hud.order_buttons.relief.get_global_rect().get_center())
	for frame in 4:await get_tree().process_frame
	assert(is_instance_valid(ForeignDiplomacy.panel));ForeignDiplomacy.panel.queue_free()
	for frame in 4:await get_tree().process_frame
	assert(String(MilitaryCampaign.active_siege.id)==identity)
	var before:=float(GameState.elapsed_days)
	await click(hud.time_buttons["3"].get_global_rect().get_center())
	for attempt in 12:
		await click(hud.order_buttons.continue.get_global_rect().get_center())
		await get_tree().create_timer(.3).timeout
		assert(not is_instance_valid(MilitaryCommandUI.battle_graphics))
	await click(hud.time_buttons["0"].get_global_rect().get_center())
	assert(GameState.elapsed_days>before and int(MilitaryCampaign.active_siege.days)>=1)
	var state:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	hud._close();for frame in 4:await get_tree().process_frame
	assert(MilitaryCampaign.import_state(state).get("ok",false))
	preload("res://scripts/hud/siege_screen.gd").open(identity)
	for frame in 5:await get_tree().process_frame
	hud=get_tree().root.get_meta("persistent_siege_view");assert(String(hud.siege_id)==identity)
	hud._set_details("city");hud._set_commands("activity");await _siege_capture("city-progress")
	get_window().size=Vector2i(1000,720);for frame in 8:await get_tree().process_frame
	await _siege_capture("small-supplies")
	await click(hud.narrow_toggle.get_global_rect().get_center());hud._set_commands("orders");await _siege_capture("small-orders")
	if "--verify-lift" in OS.get_cmdline_user_args():
		await click(hud.order_buttons.withdraw.get_global_rect().get_center())
		assert(MilitaryCampaign.active_siege.is_empty() and MilitaryCampaign.active_engagement.is_empty());await _siege_capture("lifted")
		hud._close();for frame in 4:await get_tree().process_frame
		print("SIEGE_HUD_MOUSE_PASS map,besiege,war,orders,real-clock,pause,save-reopen,small-window,lift,return")
		return
	await click(hud.assault.get_global_rect().get_center())
	for frame in 10:await get_tree().process_frame
	assert(not MilitaryCampaign.active_engagement.is_empty() and MilitaryCampaign.active_siege.is_empty())
	assert(is_instance_valid(MilitaryCommandUI.battle_graphics) and int(MilitaryCampaign.active_engagement.round)==0)
	var battle:BattleGraphicsScreen=MilitaryCommandUI.battle_graphics
	for round_index in 16:
		if battle.phase=="ended":break
		if battle.phase=="result":await click(battle.result_primary.get_global_rect().get_center())
		battle._hold_all();await click(battle.resolve_button.get_global_rect().get_center());await click(battle.skip_button.get_global_rect().get_center())
	assert(battle.phase=="ended")
	var linked_seed:=int(battle.context.seed)
	var newer:Dictionary=MilitaryCampaign.battle_history.front().duplicate(true);newer.seed=linked_seed+1;MilitaryCampaign.battle_history.push_front(newer)
	battle._close();for frame in 4:await get_tree().process_frame
	preload("res://scripts/hud/siege_screen.gd").open(identity)
	for frame in 5:await get_tree().process_frame
	hud=get_tree().root.get_meta("persistent_siege_view");assert(not hud.last_snapshot.active);await _siege_capture("outcome")
	await click(hud.result_action.get_global_rect().get_center())
	for frame in 5:await get_tree().process_frame
	assert(int(MilitaryCommandUI.battle_graphics.context.seed)==linked_seed)
	MilitaryCommandUI.battle_graphics._close();for frame in 4:await get_tree().process_frame
	print("SIEGE_HUD_MOUSE_PASS map,besiege,war,orders,real-clock,pause,save-reopen,small-window,assault,new-battle,resolve,outcome,return")
func _siege_capture(suffix:String)->void:
	for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var hud:CanvasLayer=get_tree().root.get_meta("persistent_siege_view")
	for node in hud.canvas.find_children("*","Button",true,false):
		if not node.is_visible_in_tree():continue
		var rect:Rect2=node.get_global_rect()
		assert(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=hud.canvas.size.x+1 and rect.end.y<=hud.canvas.size.y+1,"Siege button outside window: "+node.text)
		if hud.details_panel.is_ancestor_of(node) or hud.commands_panel.is_ancestor_of(node):assert(rect.end.y<=hud.bottom.position.y,"Siege panel overlaps controls: "+node.text)
	get_viewport().get_texture().get_image().save_png("res://artifacts/siege-hud-"+suffix+".png")
