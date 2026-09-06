extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0);await frames();hud=terrain.hud
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900);await frames()
	var template:Dictionary=MilitaryCampaign.army_template_snapshot().templates[0]
	var id:=int(template.template_id)
	MilitaryCampaign.adjust_template_entry(id,"levy","improvised",6-int(template.required_total))
	var target:=int(MilitaryCampaign.army_template_snapshot().templates[0].required_total)
	MilitaryCampaign.military_inventory.improvised=100;FoodSystem.receive_external_food(10000)
	hud.open_dock("military",0);await capture("army-command")
	await click_label("PREPARE AN ARMY");await capture("army-designs")
	await click_label(String(template.name));await capture("army-composition")
	await click_label("2 · RECRUIT & TRAIN");await capture("army-recruitment")
	var population:=GameState.population_total
	await click_label("RECRUIT & TRAIN")
	assert(not MilitaryCampaign.training_queue.is_empty())
	var count:=MilitaryCampaign._queued_trainees()
	await click_label("RECRUIT & TRAIN");assert(MilitaryCampaign._queued_trainees()==count)
	await capture("army-training-active")
	for day in 400:
		if MilitaryCampaign.training_queue.is_empty():break
		GameState.elapsed_days+=1;MilitaryCampaign.last_processed_day=int(GameState.elapsed_days);MilitaryCampaign._process_training_day()
	assert(MilitaryCampaign.training_queue.is_empty(),"A supplied class must complete its real instruction")
	await click_label("3 · DEPLOY");await capture("army-deployment")
	await click_label("DEPLOY %d SOLDIERS"%target)
	assert(MilitaryCampaign.field_armies.size()==1)
	assert(int(MilitaryCampaign.field_armies[0].troops)==target)
	assert(GameState.population_total==population)
	await after_deployment()
	get_window().size=Vector2i(800,600);await frames()
	hud.open_dock("military",1);await frames();await click_label(String(template.name));assert(hud.detail_dock.visible and not hud.dock.visible)
	for step in 3:
		await click_control(hud.detail_dock.tab_buttons[step]);assert(hud.detail_dock.visible and hud.detail_dock.sub==step);await capture("army-step-%d-small"%step)
		assert(get_viewport().get_visible_rect().encloses(hud.detail_dock.close_button.get_global_rect()))
	await click_control(hud.detail_dock.tab_buttons[1]);await click_label("REQUIREMENTS & NEXT STEPS");await capture("army-shortfall-small")
	await click_label("PERSONNEL ACCOUNT");await capture("army-personnel-small")
	await click_control(hud.detail_dock.close_button);await click_control(hud.detail_dock.close_button)
	GameState.resource_stockpiles.Timber=100.0
	MilitaryCampaign.equipment_queue.clear()
	hud.open_dock("military",3);await frames();await click_label("MAKE EQUIPMENT");await click_label("IMPROVISED")
	var timber:=float(GameState.resource_stockpiles.Timber)
	var gear:=int(MilitaryCampaign.military_inventory.improvised)
	await capture("equipment-order-small")
	assert(float(GameState.resource_stockpiles.Timber)==timber)
	await click_label("MAKE 5 SETS")
	assert(MilitaryCampaign.equipment_queue.size()==1)
	assert(is_equal_approx(float(GameState.resource_stockpiles.Timber),timber-1.75))
	assert(int(MilitaryCampaign.military_inventory.improvised)==gear)
	await capture("equipment-queued-small")
	print("EQUIPMENT_ORDER_PASS actual small-screen manufacture, preview read-only, materials reserved once, no instant equipment")
	print("ARMY_PREPARATION_PASS real recruit, no duplicate intake, completed instruction, ",target," deployed from reserve, population conserved; three focused stages at two sizes")
	get_tree().quit()

func after_deployment()->void:
	pass
