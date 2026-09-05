extends Control

var screen: Control
var simulator := CombatSimulator.new()
var attacker: Dictionary
var defender: Dictionary
var rounds: Array = []
var timer: Timer

func _ready()->void:
	DisplayServer.window_set_title("BATTLE DEMONSTRATION — sampled world terrain — campaign unchanged")
	GameState.reset_for_new_world(864209)
	GameState.select_founding_focus("provision")
	var source_view:=SubViewport.new(); source_view.size=Vector2i(32,32); source_view.render_target_update_mode=SubViewport.UPDATE_DISABLED; add_child(source_view)
	var terrain:=preload("res://local_terrain.tscn").instantiate(); source_view.add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0); terrain.process_mode=Node.PROCESS_MODE_DISABLED
	var center:Vector2=Vector2(terrain.settler_marker.position.x,terrain.settler_marker.position.z)
	var anchor:=center
	var best:=-1.0
	for index in 36:
		var candidate:=anchor+Vector2(sin(index*2.4),cos(index*2.4))*float(index)*.7
		var sample:Dictionary=terrain._survey_ground_at(candidate)
		var score:=float(sample.woodland)-float(sample.slope)*2
		if float(sample.height)>0 and score>best: best=score; center=candidate
	attacker=simulator.create_formation_force("THE RIVER HOST",[
		{"id":1,"unit":"line_infantry","weapon":"spear","count":700,"visual_model":"pike_phalanx"},
		{"id":2,"unit":"skirmisher","weapon":"bow","count":300,"visual_model":"longbowman"},
		{"id":3,"unit":"cavalry","weapon":"lance","count":150},
		{"id":4,"unit":"field_artillery","weapon":"field_gun","count":60,"visual_model":"bombard"}],1.0,.9)
	defender=simulator.create_formation_force("THE HILL GUARD",[
		{"id":5,"unit":"line_infantry","weapon":"sword_shield","count":750,"visual_model":"armored_foot"},
		{"id":6,"unit":"skirmisher","weapon":"bow","count":340,"visual_model":"pavise_crossbowman"},
		{"id":7,"unit":"cavalry","weapon":"lance","count":150},
		{"id":8,"unit":"siege_engineer","weapon":"siege_kit","count":90,"visual_model":"counterweight_trebuchet"}],1.0,.9)
	var demo_names:Dictionary={}
	var first:=HistoricalNameGenerator.make(703,0,true,"Highlands",demo_names); demo_names[first.name]=true
	var second:=HistoricalNameGenerator.make(703,1,false,"Highlands",demo_names)
	attacker["commander"]=simulator.create_commander(first.name)
	defender["commander"]=simulator.create_commander(second.name)
	screen=preload("res://scripts/battle_graphics_screen.gd").new(); screen.campaign_mode=false; add_child(screen)
	screen.heading.text="RIVER HOST vs HILL GUARD • BATTLE DEMONSTRATION"
	screen.status.text="Isolated simulation · Real round results · Your campaign is unchanged"
	screen.view.landscape.build(center,CivilizationSystem.ground_survey_authority)
	screen.view.reset(attacker,defender); screen.present(attacker,defender)
	if "--front-line" in OS.get_cmdline_user_args():
		screen.view.zoom=28; screen.view.elevation=.5; screen.view.target=Vector3(0,1,0); screen.view._camera_update()
	timer=Timer.new(); timer.wait_time=5.0; timer.timeout.connect(_round); add_child(timer); timer.start()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			timer.stop()
			var capture_rounds:=1
			for option in OS.get_cmdline_user_args():
				if option.begins_with("--capture-rounds="): capture_rounds=clampi(int(option.trim_prefix("--capture-rounds=")),1,12)
			for step in capture_rounds:
				screen.view.round_clock=3.0
				screen.view.clock=maxf(screen.view.clock,3.0)
				screen.view.contact.advance(screen.view)
				_round()
			await get_tree().create_timer(1.4).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()

func _round()->void:
	if not is_instance_valid(screen): timer.stop(); return
	# View pause never changes campaign time; this isolated demo waits for it.
	if screen.view.playback_speed==0 or screen.view.round_clock<2.4: return
	var result:=simulator.simulate(attacker,defender,{"seed":703+rounds.size()*7919,"max_rounds":1,"terrain_defense":1.15})
	if result.rounds.is_empty(): timer.stop(); return
	var record:Dictionary=result.rounds[0]; record["termination"]=result.get("termination",{}); record["round"]=rounds.size()+1; rounds.append(record)
	for pair in [[attacker,result.attacker],[defender,result.defender]]:
		for pool in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","dead"]: pair[0][pool]=pair[1].get(pool,0)
		pair[0]["troops"]=pair[1].remaining_troops; pair[0]["morale"]=pair[1].morale; pair[0]["formations"]=pair[1].formations
	screen.present(attacker,defender,record,String(result.outcome),rounds)
	screen.heading.text="BATTLE DEMONSTRATION • ROUND %d" % rounds.size()
	if result.outcome not in ["continued","inconclusive"] or rounds.size()>=12:
		timer.stop(); screen.status.text="%s · Remaining soldiers and their will to fight are shown above." % String(result.outcome).replace("_"," ").capitalize()
