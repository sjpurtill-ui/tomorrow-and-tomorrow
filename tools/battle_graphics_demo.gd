extends Control

var screen: Control
var simulator := CombatSimulator.new()
var attacker: Dictionary
var defender: Dictionary
var rounds: Array = []
var timer: Timer

func _ready()->void:
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
	screen.view.reset(attacker,defender); screen.present(attacker,defender)
	timer=Timer.new(); timer.wait_time=3.4; timer.timeout.connect(_round); add_child(timer); timer.start()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			timer.stop()
			var capture_rounds:=1
			for option in OS.get_cmdline_user_args():
				if option.begins_with("--capture-rounds="): capture_rounds=clampi(int(option.trim_prefix("--capture-rounds=")),1,12)
			for step in capture_rounds:
				screen.view.round_clock=3.0
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
		pair[0]["troops"]=pair[1].remaining_troops; pair[0]["morale"]=pair[1].morale; pair[0]["formations"]=pair[1].formations
	screen.present(attacker,defender,record,String(result.outcome),rounds)
	screen.heading.text="RIVER HOST vs HILL GUARD • ROUND %d" % rounds.size()
	if result.outcome not in ["continued","inconclusive"] or rounds.size()>=12:
		timer.stop(); screen.status.text="%s · Remaining soldiers and their will to fight are shown above." % String(result.outcome).replace("_"," ").capitalize()
