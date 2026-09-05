extends Node
func _ready()->void:
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();PeopleDirection.choose("horizons")
	var terrain:=preload("res://local_terrain.tscn").instantiate();add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0);terrain.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	get_window().size=Vector2i(800,600);get_window().content_scale_size=Vector2i(800,600)
	for index in 24:
		CivilizationSystem.scout_missions.append({"mission_id":index+1,"start_day":0,"return_day":100+index,"duration_days":100+index,"personnel":8,"route":[],"target_label":"A long scouting journey beyond familiar ground number %d" % (index+1),"target_id":"open_world","planned_heading":"northeast"})
	terrain._open_scout_dispatch_panel()
	await get_tree().process_frame;await get_tree().process_frame
	var modal:Control=terrain.scout_dispatch_panel.get_child(1)
	var sizes:Array=[]
	for frame in 60:
		await get_tree().process_frame
		var content:Control=modal.get_child(0)
		if content.get_script()==preload("res://scripts/viewport_fit_panel.gd"): content=content.get_child(0)
		sizes.append([modal.size,content.size,content.scale,content.position])
	var changes:=0
	for i in range(1,sizes.size()):
		if sizes[i]!=sizes[i-1]:changes+=1
	print("SCOUT_LAYOUT size=",modal.size," position=",modal.position," changes=",changes," viewport=",get_viewport().get_visible_rect())
	if "--assert-fit" in OS.get_cmdline_user_args():
		assert(get_viewport().get_visible_rect().encloses(modal.get_global_rect()))
		assert(changes==0)
		var scroll:ScrollContainer=modal.find_child("ScoutContentScroll",true,false)
		assert(scroll!=null and scroll.get_v_scroll_bar().max_value>scroll.size.y)
		scroll.scroll_vertical=100
		await get_tree().process_frame
		var retained:=scroll.scroll_vertical
		assert(retained>0)
		for frame in 20:await get_tree().process_frame
		assert(scroll.scroll_vertical==retained)
		print("SCOUT_LAYOUT_PASS: crowded content scrolls inside stable viewport bounds")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/scout-layout.png")
	terrain._close_scout_dispatch_panel()
	CivilizationSystem.scout_missions.clear()
	terrain.pending_scout_target_id="open_world";terrain.pending_scout_heading="north"
	terrain._open_scout_dispatch_panel()
	await get_tree().process_frame;await get_tree().process_frame
	assert(terrain.pending_scout_target_id=="open_world" and terrain.pending_scout_heading=="north")
	assert(get_viewport().get_visible_rect().encloses((terrain.scout_dispatch_panel.get_child(1) as Control).get_global_rect()))
	terrain._close_scout_dispatch_panel()
	print("SCOUT_NORMAL_PASS: empty-party dispatch remains selectable and bounded")
	get_tree().quit()
