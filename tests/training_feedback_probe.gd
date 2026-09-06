extends Node
var terrain:Node
var hud:Control
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(count:=4)->void:
	for i in count:await get_tree().process_frame
func texts(node:Node)->String:
	var result:=""
	if node is Label:result=node.text+"\n"
	for child in node.get_children():result+=texts(child)
	return result
func exercise_label(node:Node)->Label:
	if node is Label and "extra rations used" in node.text:return node
	for child in node.get_children():
		var found:=exercise_label(child)
		if found:return found
	return null
func button_with_label(node:Node,label:String)->BaseButton:
	if node is Label and node.text==label:
		var parent:=node.get_parent()
		while parent and not parent is BaseButton:parent=parent.get_parent()
		return parent as BaseButton
	for child in node.get_children():
		var found:=button_with_label(child,label)
		if found:return found
	return null
func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(551188)
	GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0);await frames();hud=terrain.hud
	var template:Dictionary=MilitaryCampaign.army_template_snapshot().templates[0]
	var id:=int(template.template_id)
	MilitaryCampaign.adjust_template_entry(id,"levy","improvised",3-int(template.required_total))
	MilitaryCampaign.military_inventory.improvised=100;FoodSystem.receive_external_food(10000)
	hud.open_dock("military",1)
	hud.providers.military._open_build(id)
	hud.detail_dock.present(hud.detail_dock.provider,1)
	await frames()
	var training_button:=button_with_label(hud.detail_dock,"RECRUIT & TRAIN")
	check(training_button!=null,"recruit button found")
	if not training_button:get_tree().quit(1);return
	hud.detail_dock.body_scroll.ensure_control_visible(training_button)
	await frames()
	# Headless Godot fixes the cursor at (0,0). Put the test panel under it so
	# the real interaction guard stays active; no production hook is needed.
	hud.detail_dock.position=hud.detail_dock.get_global_mouse_position()
	check(hud._dock_interaction_active(hud.detail_dock),"pointer stays over active training tab")
	var population:=GameState.population_total
	# The dock may rebuild during the frames used to finish scrolling.
	# Click its current button, not a reference captured before those frames.
	training_button=button_with_label(hud.detail_dock,"RECRUIT & TRAIN")
	if not is_instance_valid(training_button):
		push_error("Recruit button missing after scrolling")
		get_tree().quit(1);return
	training_button.pressed.emit()
	await frames(6)
	check(MilitaryCampaign._queued_trainees()==3,"three people enter actual training")
	check(hud.detail_dock.visible and hud.detail_dock.sub==1,"same training tab remains open")
	check("IN TRAINING" in texts(hud.detail_dock),"training rows appear without leaving tab")
	var feedback:Control=hud.action_feedback
	print("FEEDBACK_RECT: ",feedback.get_global_rect()," CHILDREN ",feedback.get_children())
	check("All 3 soldiers" in texts(feedback),"feedback contains action result")
	check(get_window().get_visible_rect().encloses(feedback.get_global_rect()),"feedback stays inside viewport")
	for label in feedback.find_children("*","Label",true,false):
		check(label.size.x>0 and label.size.y>0,"feedback label has visible size")
		check(feedback.get_global_rect().encloses(label.get_global_rect()),"feedback text fits panel")
	hud.detail_dock.position=hud.detail_dock.get_global_mouse_position()
	var before:=texts(hud.detail_dock)
	for day in 3:
		GameState.elapsed_days+=1;MilitaryCampaign.last_processed_day=int(GameState.elapsed_days);MilitaryCampaign._process_training_day()
	await get_tree().create_timer(0.6).timeout
	hud.live_refresh_dock()
	var after:=texts(hud.detail_dock)
	check(before!=after,"training progresses visibly on same hovered tab")
	check(GameState.population_total==population,"training preserves aggregate population")
	for day in 400:
		if MilitaryCampaign.training_queue.is_empty():break
		GameState.elapsed_days+=1;MilitaryCampaign.last_processed_day=int(GameState.elapsed_days);MilitaryCampaign._process_training_day()
	hud.open_dock("military",2)
	await frames()
	var exercise_result:=MilitaryCampaign.start_training_program("camp_drill")
	check(not exercise_result.has("error"),"camp drill starts with real trained personnel")
	terrain._report_military_action(exercise_result)
	hud.request_immediate_dock_refresh();await frames()
	hud.dock.position=hud.dock.get_global_mouse_position()
	check(hud._dock_interaction_active(hud.dock),"pointer stays over exercise tab")
	var progress_label:=exercise_label(hud.dock)
	check(progress_label!=null,"exercise progress label exists")
	var exercise_before:=progress_label.text if progress_label else ""
	for day in 2:
		GameState.elapsed_days+=1;MilitaryCampaign._process_training_program_day()
	await get_tree().create_timer(0.6).timeout
	hud.live_refresh_dock()
	check(float(MilitaryCampaign.training_program.get("progress_days",0))>0,"exercise state advances")
	check(is_instance_valid(progress_label) and exercise_before!=progress_label.text,"same exercise label updates while hovered")
	for day in 100:
		if MilitaryCampaign.training_program.is_empty():break
		GameState.elapsed_days+=1;MilitaryCampaign._process_training_program_day()
	await get_tree().create_timer(0.6).timeout
	check(is_instance_valid(progress_label) and "Last completed" in progress_label.text,"same label shows exercise completion")
	check(button_with_label(hud.dock,"CANCEL EXERCISE").disabled,"cancel disables after completion")
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	check(not hud.providers.military._ammunition_known(),"ammunition entry locked before discovery")
	for item:String in MilitaryCampaign.CONSUMABLE_KNOWLEDGE:
		check(MilitaryCampaign.queue_consumable_production(item,1).has("error"),"undiscovered ammo rejected: "+item)
	check(GameState.resource_stockpiles==stocks and MilitaryCampaign.equipment_queue.is_empty(),"locked orders do not spend or queue")
	GameState.known_discoveries.append("bow_craft");GameState.discovery_adoption["bow_craft"]=0.01
	check(MilitaryCampaign.queue_consumable_production("arrows",1).has("error"),"insufficient adoption rejected")
	GameState.discovery_adoption["bow_craft"]=1.0
	check(hud.providers.military._ammunition_known(),"arrows unlock ammunition entry")
	var catalog:Dictionary=hud.providers.military._ammunition_catalog()
	check(not catalog.blocks[0].items[0].disabled and catalog.blocks[0].items[1].disabled,"catalog independently gates later ammunition")
	for resource in ["Timber","Stone","Fiber Plants"]:GameState.resource_stockpiles[resource]=100.0
	var ammo_before:=MilitaryCampaign.military_consumables.duplicate(true)
	check(int(MilitaryCampaign.queue_consumable_production("arrows",5).get("queued",0))==5,"unlocked order queues five arrows")
	check(is_equal_approx(float(GameState.resource_stockpiles.Timber),99.6),"arrow order reserves exact timber")
	check(MilitaryCampaign.military_consumables==ammo_before,"queued ammunition is not instantly inventory")
	MilitaryCampaign.equipment_queue.clear();GameState.resource_stockpiles.Timber=0.0
	stocks=GameState.resource_stockpiles.duplicate(true)
	check(MilitaryCampaign.queue_consumable_production("arrows",5).has("error"),"material shortage rejects unlocked order")
	check(GameState.resource_stockpiles==stocks and MilitaryCampaign.equipment_queue.is_empty(),"failed order preserves resources and queue")
	print("TRAINING_FEEDBACK_CHECKS: ",checks,"; FAILURES: ",failures)
	terrain.queue_free();await frames();get_tree().quit(1 if failures else 0)
