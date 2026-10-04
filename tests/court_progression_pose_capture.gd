extends "res://tools/court_acting_capture.gd"
## Private-desktop diagnostic only. Close after capture; never the player game.
## All fitted families seated/talking/walking from two angles, plus the legacy
## garments and child at two stride phases. Explicit dress tests deformation,
## not discovery gating.
## Use "collar-only no-ink" to isolate outline artifacts in the four closeups.

func _ready()->void:
	out_dir=ProjectSettings.globalize_path("res://reports/court_progression_poses_no_ink/" if "no-ink" in OS.get_cmdline_user_args() else "res://reports/court_progression_poses/")
	var source_walk:="source-walk" in OS.get_cmdline_user_args()
	if source_walk:out_dir=ProjectSettings.globalize_path("res://reports/court_progression_poses_source_walk/")
	var selected:=PackedStringArray()
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("outfits="):selected=argument.trim_prefix("outfits=").split(",")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(W,H);get_window().content_scale_size=Vector2i(W,H)
	_stage()
	await _frames(3)
	var variants:=["male_adult","female_adult","female_old","male_old"]
	var captured:=0
	for outfit:String in ["medieval","courtcoat","formal","business","hide","tunic","robe"]:
		if not selected.is_empty() and not outfit in selected:continue
		var poses:Array=["sit","sit_talk","talk_both","walk_in","walk_out","walk_in_0","walk_out_0","kneel","sit_cross"]
		if outfit in ["hide","tunic","robe"]:poses=["walk_in","walk_out","walk_in_0","walk_out_0"]
		if "collar-only" in OS.get_cmdline_user_args():poses=[]
		for pose:String in poses:
			var row_variants:=variants.duplicate()
			if pose.begins_with("walk_"):row_variants[3]="child"
			for yaw in [-20,70]:
				_clear();await _frames(3)
				for i in row_variants.size():
					var f:=Figure3D.new();world.add_child(f)
					f.setup({"variant":row_variants[i],"outfit":outfit,"lit":true,"hair":"cropped","stance":"stand",
						"cloth":[Color("466557"),Color("ece5d4"),Color("a88949")],"skin":Color("bd8659"),
						"leather":Color("191b1d") if outfit=="business" else Color("5b3b24")})
					if source_walk:preload("res://scripts/hud/court_walk_clearance.gd").configure(f.player,f.skeleton,f.variant,outfit,0.0)
					_diagnostic_materials(f)
					f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
					Acting.of(f).active=false
					f.position=Vector3((float(i)-1.5)*1.10,0,0);f.rotation_degrees.y=float(yaw)
					figures.append(f)
					if pose in ["kneel","sit_cross"]:
						f.play("stand",0.0,0.0);Acting.play(f,pose,{"blend":0.0})
					else:f.play(pose.trim_suffix("_0"),0.0,0.0)
				_step_all(0.0 if pose.ends_with("_0") else (1.33 if pose in ["kneel","sit_cross"] else (.95 if pose=="talk_both" else (.24 if pose=="walk_out" else .55))))
				_frame_row(4.6,2.05)
				_title("TEST wardrobe deformation: %s / %s / %d degrees" % [outfit,pose,yaw])
				for i in figures.size():_label(row_variants[i].replace("_"," "),figures[i].position+Vector3(0,-.18,.2),16)
				await _shot("%s_%s_%d.png" % [outfit,pose,yaw])
				captured+=1
	for outfit:String in ["medieval","business"]:
		if source_walk or (not selected.is_empty() and not outfit in selected):continue
		for variant:String in ["male_adult","female_old"]:
			_clear();await _frames(3)
			var f:=Figure3D.new();world.add_child(f)
			f.setup({"variant":variant,"outfit":outfit,"lit":true,"hair":"cropped","stance":"sit",
				"cloth":[Color("787b77"),Color("ece5d4"),Color("70a28d")],"skin":Color("bd8659")})
			_diagnostic_materials(f)
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			Acting.of(f).active=false;figures.append(f);f.play("sit_talk",0.0,0.0)
			_step_all(1.05)
			var head:=f.global_position+Vector3(0,1.28 if variant=="male_adult" else 1.12,0)
			camera.position=head+Vector3(.08,.06,1.1);camera.look_at(head,Vector3.UP)
			_title("TEST seam closeup: %s / %s / seated speech" % [outfit,variant])
			await _shot("%s_%s_seated_close.png" % [outfit,variant])
			captured+=1
	print("COURT_PROGRESSION_POSES captured %d views; inspect pixels before assessing quality" % captured)
	get_tree().quit()

func _diagnostic_materials(f:Node3D)->void:
	if not "no-ink" in OS.get_cmdline_user_args():return
	for node:MeshInstance3D in f._merged.values():
		for surface in node.mesh.get_surface_count():
			var material=node.get_surface_override_material(surface).duplicate()
			material.next_pass=null;node.set_surface_override_material(surface,material)
