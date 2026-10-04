extends "res://tools/court_acting_capture.gd"
## Private-desktop review of every wardrobe/body in the real lit, merged shader.

func _ready()->void:
	out_dir=ProjectSettings.globalize_path("res://reports/court_wardrobe/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(W,H);get_window().content_scale_size=Vector2i(W,H)
	_stage()
	await _frames(3)
	for outfit in ["medieval","courtcoat","formal","business"]:
		for pose in ["stand","walk_in","sit","sit_cross","kneel"]:
			_clear()
			await _frames(3)
			for i in Figure3D.BODIES.size():
				var variant:String=Figure3D.BODIES[i]
				var f:=Figure3D.new();world.add_child(f)
				var a:=Color("34506c") if outfit=="business" else (Color("664630") if outfit=="formal" else Color("466557"))
				f.setup({"variant":variant,"outfit":outfit,"lit":true,"hair":"bun" if variant.begins_with("female") else "cropped",
					"cloth":[a,Color("ece5d4"),Color("a88949")],"stance":"stand","skin":Color("bd8659")})
				f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				Acting.of(f).active=false
				f.position=Vector3((float(i)-3)*1.05,0,0);f.rotation_degrees.y=-20
				figures.append(f)
				if pose in ["sit_cross","kneel"]:Acting.play(f,pose,{"blend":0.0})
				else:f.play(pose,0.0,0.0)
			_step_all(1.15 if pose in ["sit_cross","kneel"] else .55)
			_frame_row(7.35,2.05)
			_title("Court wardrobe: %s / %s" % [outfit,pose])
			for i in figures.size():_label(Figure3D.BODIES[i].replace("_"," "),figures[i].position+Vector3(0,-.18,.2),16)
			await _shot("%s_%s.png" % [outfit,pose])
	print("COURT_WARDROBE_CAPTURE PASS 28 combinations, five poses")
	get_tree().quit()
