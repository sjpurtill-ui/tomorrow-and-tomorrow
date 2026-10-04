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
		for pose:String in ["sit","talk_both","walk_in"]:
			for yaw in [-20,70]:
				_clear();await _frames(3)
				for i in variants.size():
					var f:=Figure3D.new();world.add_child(f)
					f.setup({"variant":variants[i],"outfit":outfit,"lit":true,"hair":"cropped","stance":"stand",
						"cloth":[Color("466557"),Color("ece5d4"),Color("a88949")],"skin":Color("bd8659")})
					f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
					Acting.of(f).active=false
					f.position=Vector3((float(i)-1.5)*1.10,0,0);f.rotation_degrees.y=float(yaw)
					figures.append(f);f.play(pose,0.0,0.0)
				_step_all(0.95 if pose=="talk_both" else 0.55)
				_frame_row(4.6,2.05)
				_title("TEST wardrobe deformation: %s / %s / %d degrees" % [outfit,pose,yaw])
				for i in figures.size():_label(variants[i].replace("_"," "),figures[i].position+Vector3(0,-.18,.2),16)
				await _shot("%s_%s_%d.png" % [outfit,pose,yaw])
	print("COURT_PROGRESSION_POSES captured 12 views; inspect pixels before assessing quality")
	get_tree().quit()
