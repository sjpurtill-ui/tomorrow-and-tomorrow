extends "res://tools/court_acting_capture.gd"
## Private-desktop diagnostic only. Close after capture; never the player game.
## Existing fitted medieval and business meshes, seated/talking/walking from
## two angles. These explicit garments test deformation, not discovery gating.

func _ready()->void:
	out_dir=ProjectSettings.globalize_path("res://reports/court_progression_poses/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(W,H);get_window().content_scale_size=Vector2i(W,H)
	_stage()
	await _frames(3)
	var variants:=["male_adult","female_adult","female_old","male_old"]
	for outfit:String in ["medieval","business"]:
		for pose:String in ["sit","sit_talk","talk_both","walk_in"]:
			for yaw in [-20,70]:
				_clear();await _frames(3)
				for i in variants.size():
					var f:=Figure3D.new();world.add_child(f)
					f.setup({"variant":variants[i],"outfit":outfit,"lit":true,"hair":"cropped","stance":"stand",
						"cloth":[Color("466557"),Color("ece5d4"),Color("a88949")],"skin":Color("bd8659"),
						"leather":Color("191b1d") if outfit=="business" else Color("5b3b24")})
					f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
					Acting.of(f).active=false
					f.position=Vector3((float(i)-1.5)*1.10,0,0);f.rotation_degrees.y=float(yaw)
					figures.append(f);f.play(pose,0.0,0.0)
				_step_all(0.95 if pose=="talk_both" else 0.55)
				_frame_row(4.6,2.05)
				_title("TEST wardrobe deformation: %s / %s / %d degrees" % [outfit,pose,yaw])
				for i in figures.size():_label(variants[i].replace("_"," "),figures[i].position+Vector3(0,-.18,.2),16)
				await _shot("%s_%s_%d.png" % [outfit,pose,yaw])
	for outfit:String in ["medieval","business"]:
		for variant:String in ["male_adult","female_old"]:
			_clear();await _frames(3)
			var f:=Figure3D.new();world.add_child(f)
			f.setup({"variant":variant,"outfit":outfit,"lit":true,"hair":"cropped","stance":"sit",
				"cloth":[Color("787b77"),Color("ece5d4"),Color("70a28d")],"skin":Color("bd8659")})
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			Acting.of(f).active=false;figures.append(f);f.play("sit_talk",0.0,0.0)
			_step_all(1.05)
			var head:=f.global_position+Vector3(0,1.28 if variant=="male_adult" else 1.12,0)
			camera.position=head+Vector3(.08,.06,1.1);camera.look_at(head,Vector3.UP)
			_title("TEST seam closeup: %s / %s / seated speech" % [outfit,variant])
			await _shot("%s_%s_seated_close.png" % [outfit,variant])
	print("COURT_PROGRESSION_POSES captured 20 views; inspect pixels before assessing quality")
	get_tree().quit()
