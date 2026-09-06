extends "res://tests/focused_journey_probe.gd"
func key(code:int)->void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down;Input.parse_input_event(event);await get_tree().process_frame
	await frames()
func wait_return(tag:String)->void:
	hud.close_dock();await frames();await click_control(hud.speed_buttons[5])
	var deadline:=Time.get_ticks_msec()+230000;var report_day:=int(GameState.elapsed_days)
	while bool(CivilizationSystem.exploration_status().get("active",false)) and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
		if int(GameState.elapsed_days)>report_day+40:
			report_day=int(GameState.elapsed_days);print(tag," day=",report_day," speed=",terrain.game_speed)
	await click_control(hud.speed_buttons[0]);assert(not bool(CivilizationSystem.exploration_status().get("active",false)))
	print(tag," RETURN ",JSON.stringify(CivilizationSystem.exploration_status().last_outcome)," contacts=",CivilizationSystem.exploration_status().contacted_count)
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	assert(SaveSystem.load_game("coherent_after_long_return" if "--after-long" in OS.get_cmdline_user_args() else "coherent_long_departure").has("ok"));GameState.civic_api_enabled=false
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900)
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);await frames();hud=terrain.hud
	if "--after-long" not in OS.get_cmdline_user_args():await wait_return("RESUMED_SAME_WORLD")
	assert(SaveSystem.save_game("coherent_after_long_return").has("ok"))
	await click_control(hud.rail_buttons.world);await capture("continuous-year-two-contact-status")
	await click_label("SEND SCOUTS")
	var selector:OptionButton
	for option in terrain.scout_dispatch_panel.find_children("*","OptionButton",true,false):
		if option.get_item_text(0).begins_with("HEADING"):selector=option;break
	assert(selector!=null)
	selector.select(1);selector.item_selected.emit(1);await frames()
	assert(terrain.pending_scout_heading=="east")
	var dispatched:=false
	for duration in [365,90,30]:
		for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
			if not button.text.begins_with("SEND FOR %d DAYS"%duration):continue
			if button.disabled:
				print("EAST_OPTION_BLOCKED duration=",duration," reason=",button.tooltip_text," label=",button.text)
				await capture("continuous-east-blocked")
				continue
			await click_control(button);dispatched=true;break
		if dispatched:break
	assert(dispatched,"Inspect whether all east routes or affordable options are blocked")
	assert(bool(CivilizationSystem.exploration_status().active))
	if is_instance_valid(terrain.scout_dispatch_panel):
		for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
			if button.text=="CLOSE":await click_control(button);break
	assert(SaveSystem.save_game("coherent_east_departure").has("ok"))
	await wait_return("EAST_EXPLORATION")
	assert(SaveSystem.save_game("coherent_east_return").has("ok"))
	await click_control(hud.rail_buttons.world);await capture("continuous-east-return-contacts")
	print("COHERENT_CONTACT_CONTINUATION_COMPLETE ",JSON.stringify(CivilizationSystem.exploration_status()))
	get_tree().quit()
