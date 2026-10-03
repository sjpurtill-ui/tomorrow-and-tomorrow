extends "res://tools/court_acting_capture.gd"
## Same pose sheets, using the lit merged meshes/materials used by the court.
## The older acting sheet uses the unlit preview material (which culls backs).

func _person(i:int,stance:="")->Node3D:
	var f:=super._person(i,stance)
	f.look["lit"]=true
	f._dress()
	return f

func _bodies_row(spec:String)->void:
	for item0 in spec.split(","):
		var stance:=item0.get_slice("#",1) if item0.contains("#") else "stand"
		var item:=item0.get_slice("#",0)
		var clip:=item.get_slice("@",0)
		var at:=float(item.get_slice("@",1)) if item.contains("@") else Acting.clip_length(clip)
		for outfit in ["hide","tunic","robe"]:
			_clear()
			for i in BODY_ROW.size():
				var f:Node3D=Figure3D.new()
				world.add_child(f)
				f.setup({"variant":BODY_ROW[i][0],"outfit":outfit,"lit":true,
					"hair":"bun" if String(BODY_ROW[i][0]).begins_with("female") else "cropped",
					"skin":Color("bd8659"),"hair_colour":Color(String(BODY_ROW[i][1])),"stance":stance})
				f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				f.play(f.rest_clip(),0.0,0.0)
				Acting.of(f).active=false
				f.position=Vector3((float(i)-(BODY_ROW.size()-1)*0.5)*1.25,0.0,0.0)
				f.rotation_degrees.y=-35.0
				figures.append(f)
			_step_all(0.3)
			for f in figures:
				if Acting.library(String(f.variant)).has(clip):Acting.play(f,clip,{"blend":0.05})
			var elapsed:=0.0
			while elapsed<at-0.001:
				for f in figures:_frame(f)
				elapsed+=DT
			camera.fov=30.0;camera.position=Vector3(0.0,1.6,9.6);camera.rotation_degrees=Vector3(-8.0,0.0,0.0)
			_title("Court clothing: %s at %.2f s (%s)" % [clip,at,outfit])
			for i in BODY_ROW.size():_label(String(BODY_ROW[i][0]).replace("_"," "),figures[i].position+Vector3(0.0,-0.25,0.6),15)
			await _shot("clothing_%s_%s_%s.png" % [clip,String.num(at,2),outfit])
