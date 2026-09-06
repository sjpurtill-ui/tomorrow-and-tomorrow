extends Node
var terrain:Node
var view:CanvasLayer
func click(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;get_viewport().push_input(motion)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;get_viewport().push_input(event)
		await get_tree().process_frame
func capture(name:String)->void:
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/occupation-decision-"+name+".png")
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_CityAssault_Test") or OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	assert(not SaveSystem.load_game("city_encounter_review").has("error"))
	GameState.civic_api_enabled=false
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	for frame in 12:await get_tree().process_frame
	if is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.hide()
	assert(not MilitaryCampaign.occupation_forces.is_empty())
	var force:Dictionary=MilitaryCampaign.occupation_forces[0]
	view=preload("res://scripts/hud/occupation_view.gd").new();view.civ_id=String(force.civ_id);view.region_id=String(force.region_id);add_child(view)
	await capture("government")
	for index in view.tabs.get_tab_count():
		await click(view.tabs.get_tab_bar().get_global_transform()*view.tabs.get_tab_bar().get_tab_rect(index).get_center())
		await capture("tab-%d"%index)
		for button in view.find_children("*","Button",true,false):
			if button.is_visible_in_tree():assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
	var before:Dictionary=CivilizationSystem.region_snapshot(view.civ_id,view.region_id).duplicate(true)
	view._review("raze");await capture("destruction-review")
	assert(CivilizationSystem.region_snapshot(view.civ_id,view.region_id)==before,"Reviewing must not execute destruction")
	view.decision.hide();view.tabs.show();view.pending_decision="";view.tabs.current_tab=0
	var chosen:="equal_citizenship" if String(view.current.policy)!="equal_citizenship" else "self_rule"
	await click(view.policy_buttons[chosen].get_global_rect().get_center())
	assert(CivilizationSystem.region_snapshot(view.civ_id,view.region_id)==before)
	if view.policy_commit.disabled:
		GameState.elapsed_days=maxf(GameState.elapsed_days,float(view.current.last_order_day)+30);view._refresh()
	await click(view.policy_commit.get_global_rect().get_center())
	assert(String(CivilizationSystem.occupation_governance_snapshot(view.civ_id,view.region_id).policy)==chosen)
	assert(float(CivilizationSystem.region_snapshot(view.civ_id,view.region_id).population)==float(before.population))
	await capture("policy-feedback")
	view.tabs.current_tab=2;await get_tree().process_frame
	view._preview_transfer()
	var reviewed:String=view.reviewed_transfer
	view.transfer_count.value+=1;assert(view.transfer_commit.disabled and view.reviewed_transfer.is_empty())
	get_window().size=Vector2i(1000,720)
	for index in view.tabs.get_tab_count():
		view.tabs.current_tab=index;await capture("compact-%d"%index)
		for button in view.find_children("*","Button",true,false):
			if button.is_visible_in_tree():assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
	print("OCCUPATION_DECISION_PASS actual copied-save city, four mouse tabs, review without mutation, policy commit and cooldown, transfer review invalidation, 1000x720 controls; quote_available=",not reviewed.is_empty())
	get_tree().quit()
