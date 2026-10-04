extends "res://tools/court_acting_capture.gd"
const Pose=preload("res://scripts/hud/court_pose_clearance.gd")

func _ready()->void:
	var label:="court_pose_clearance";var variants:Array=["male_adult","female_old"]
	var outfits:Array=["tunic"]
	var quick:="--quick" in OS.get_cmdline_user_args()
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):Pose.overrides=JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--profile=")))
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=").validate_filename()
		if arg.begins_with("--bodies="):variants=arg.trim_prefix("--bodies=").split(",")
		if arg.begins_with("--outfits="):outfits=arg.trim_prefix("--outfits=").split(",")
	out_dir=ProjectSettings.globalize_path("res://reports/"+label+"/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(W,H);get_window().content_scale_size=Vector2i(W,H)
	_stage();await _frames(3)
	var count:=0
	for outfit:String in outfits:
		for pose:String in ["stand","sit_cross","stance_cross","release_sit_cross","release_walk","settle_cross","depart_cross","kneel"]:
			if quick and pose in ["settle_cross","depart_cross"]:continue
			var times:Array=[0.0,.33,.5,.6,.7,.8,.9,1.0,1.33,1.6]
			if pose=="stand" or pose=="stance_cross":times=[0.0,1.0,2.0,3.0]
			if pose.begins_with("release_"):times=[0.0,.1,.2,.3,.4,.5]
			if pose in ["settle_cross","depart_cross"]:times=[0.0,.1,.2,.4,.6]
			if pose=="kneel":times=[.67,1.33,2.5]
			if quick:times=[.33,.67,.77,.87,1.33,1.6] if pose=="sit_cross" else ([.2] if pose.begins_with("release_") else [1.33])
			for at:float in times:
				for yaw:int in [-20,70]:
					_clear();await _frames(3)
					for i in variants.size():
						var f:=Figure3D.new();world.add_child(f)
						f.setup({"variant":variants[i],"outfit":outfit,"lit":true,"hair":"cropped","stance":"stand",
							"cloth":[Color("466557"),Color("ece5d4"),Color("a88949")],"skin":Color("bd8659"),"leather":Color("5b3b24")})
						f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
						Acting.of(f).active=false
						f.position=Vector3((float(i)-float(variants.size()-1)/2.0)*1.1,0,0);f.rotation_degrees.y=float(yaw)
						figures.append(f);f.play("stand",0.0,0.0)
						if pose!="stand":Acting.play(f,"sit_cross" if pose in ["release_walk","settle_cross","depart_cross"] else pose.trim_prefix("release_"),{"blend":0.0})
					if pose.begins_with("release_"):
						_step_all(1.6)
						for f in figures:
							Acting.stop(f,.4)
							if pose=="release_walk":f.play("walk_out",.4,0.0)
					if pose in ["settle_cross","depart_cross"]:
						_step_all(Acting.clip_length("sit_cross"))
						for f in figures:Acting.idle(f,"cross")
						if pose=="depart_cross":
							_step_all(1.0)
							for f in figures:
								Acting.idle(f,"stand")
								f.play("walk_out",.4,0.0)
					_step_all(at);_frame_row(maxf(4.6,variants.size()*1.1+.8),2.05)
					_title("TEST %s: %s / %s %.2f / %d degrees"%[label,outfit,pose,at,yaw])
					for i in figures.size():_label(String(variants[i]).replace("_"," "),figures[i].position+Vector3(0,-.18,.2),16)
					await _shot("%s_%s_%03d_%d.png"%[outfit,pose,int(at*100),yaw]);count+=1
	print("COURT_POSE_CLEARANCE captured ",count," views");get_tree().quit()
