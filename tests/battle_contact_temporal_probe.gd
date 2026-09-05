extends Node

func _ready()->void:
	var simulator:=CombatSimulator.new()
	var a:=simulator.create_formation_force("PIKES",[{"id":1,"unit":"line_infantry","weapon":"spear","visual_model":"pike_phalanx","count":700}],1,.9)
	var b:=simulator.create_formation_force("SWORDS",[{"id":2,"unit":"line_infantry","weapon":"sword_shield","visual_model":"armored_foot","count":700}],1,.9)
	var screen:=BattleGraphicsScreen.new(); screen.campaign_mode=false; add_child(screen)
	screen.view.reset(a,b)
	screen.present(a,b,{"round":1},"continued")
	screen.view.set_process(false)
	screen.view.zoom=18; screen.view.elevation=.48; screen.view.target=Vector3(0,1,-5); screen.view._camera_update()
	await get_tree().process_frame
	await get_tree().process_frame
	var roots:Dictionary={}; var attack_samples:=0; var guard_samples:=0; var maximum_drift:=0.0
	var output:=ProjectSettings.globalize_path("res://artifacts/contact-motion")
	DirAccess.make_dir_recursive_absolute(output)
	for frame in 100:
		screen.view.clock=3.0+float(frame)/20
		screen.view.contact.advance(screen.view)
		for group:Dictionary in screen.view.groups:
			for index in group.poses.size():
				var key:="%d/%d" % [group.side,index]
				var pose:Transform3D=group.batch.multimesh.get_instance_transform(index)
				if not roots.has(key): roots[key]=pose.origin
				maximum_drift=maxf(maximum_drift,pose.origin.distance_to(roots[key]))
				var state:float=group.batch.multimesh.get_instance_custom_data(index).a
				if state>3.5: attack_samples+=1
				elif state>2.5: guard_samples+=1
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output+"/frame_%03d.png" % frame)
	assert(maximum_drift<.001,"paired roots slide after approach")
	assert(attack_samples>0 and guard_samples>attack_samples,"guard/recovery must occupy more time than striking")
	assert(screen.view.contact.strike_count>0,"weapon contact beats never fired")
	print("CONTACT_TEMPORAL PASS frames=100 seconds=5 root_drift=",maximum_drift," attack_samples=",attack_samples," guard_samples=",guard_samples," impacts=",screen.view.contact.strike_count)
	screen.free(); get_tree().quit()
