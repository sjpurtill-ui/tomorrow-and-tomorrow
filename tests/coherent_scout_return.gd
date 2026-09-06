extends "res://tests/coherent_early_journey.gd"
func after_scout_departure()->void:
	if is_instance_valid(terrain.scout_dispatch_panel):
		for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
			if button.text=="CLOSE":await click_control(button);break
	hud.close_dock();await frames();await click_control(hud.speed_buttons[5])
	var deadline:=Time.get_ticks_msec()+60000
	var last_day:=int(GameState.elapsed_days)
	while bool(CivilizationSystem.exploration_status().get("active",false)) and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
		if int(GameState.elapsed_days)>last_day+10:
			last_day=int(GameState.elapsed_days);print("SCOUT_WAIT day=",last_day," speed=",terrain.game_speed," status=",JSON.stringify(CivilizationSystem.exploration_status()))
	await click_control(hud.speed_buttons[0])
	assert(not bool(CivilizationSystem.exploration_status().get("active",false)),"Scouts must return through ordinary time; inspect a real pause or delay")
	await click_control(hud.rail_buttons.world);await capture("continuous-first-return-contacts")
	await click_control(hud.dock.tab_buttons[1]);await capture("continuous-first-return-scouting")
	print("SCOUT_RETURN_ACTUAL day=",GameState.elapsed_days," exploration=",JSON.stringify(CivilizationSystem.exploration_status()))
	await click_label("EXPEDITION ARCHIVE");await capture("continuous-first-return-archive")
	print("COHERENT_SCOUT_RETURN_PASS first real expedition returns in same new world; World Scouting and archive reached through UI")
	var results:Node=hud.detail_dock.find_child("ReportResults",true,false)
	assert(results!=null and results.get_child_count()>0)
	await click_control(results.get_child(0));await capture("continuous-first-return-full-report")
	await click_label("BACK TO ARCHIVE")
	if "--first-return-only" in OS.get_cmdline_user_args():return

	await click_control(hud.detail_dock.close_button);await click_control(hud.dock.tab_buttons[0]);await click_label("SEND SCOUTS")
	var launched:=false
	for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
		if button.text.begins_with("SEND FOR 365 DAYS"):
			assert(not button.disabled,"Inspect real resources if longer exploration is unavailable")
			await click_control(button);launched=true;break
	assert(launched)
	if is_instance_valid(terrain.scout_dispatch_panel):
		for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
			if button.text=="CLOSE":await click_control(button);break
	hud.close_dock();await frames();await click_control(hud.speed_buttons[5])
	assert(SaveSystem.save_game("coherent_long_departure").has("ok"))
	deadline=Time.get_ticks_msec()+230000;last_day=int(GameState.elapsed_days)
	while bool(CivilizationSystem.exploration_status().get("active",false)) and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
		if int(GameState.elapsed_days)>last_day+30:
			last_day=int(GameState.elapsed_days);print("LONG_SCOUT_WAIT day=",last_day," speed=",terrain.game_speed," population=",GameState.population_total," days_remaining=",CivilizationSystem.exploration_status().get("days_remaining",-1))
	await click_control(hud.speed_buttons[0]);await click_control(hud.rail_buttons.world);await capture("continuous-long-return-contacts")
	print("LONG_SCOUT_RESULT ",JSON.stringify(CivilizationSystem.exploration_status()))
	assert(not bool(CivilizationSystem.exploration_status().get("active",false)))
	assert(SaveSystem.save_game("coherent_after_long_return").has("ok"))
