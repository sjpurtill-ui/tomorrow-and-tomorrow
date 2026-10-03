extends Node
## Captures of the court's modelled sets (scripts/hud/court_set_3d.gd) with
## the modelled figures (court_figure_3d.gd) standing on the set's marks, lit
## by the set, and the dog about: the sets by era, the camera's shots, the
## props answering the facts, and a short clip (frames for a gif).
## Windowed only (tools/run_isolated_gpu_probe.ps1, on a private desktop);
## it writes res://reports/court_set/*.png (reports/ is ignored).
## Headless it checks that each set builds with its marks.
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> -Scene res://tests/court_set_capture.tscn -LogFile <log> [-UserArguments "--only=fire"]

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")

const W:=1536
const H:=864
const SKIN_RAMP:=[[0.0,"f3dccb"],[0.15,"e8c3a5"],[0.30,"d6a37c"],[0.45,"bd8659"],[0.60,"9f6a43"],[0.75,"7d4e2f"],[0.90,"5b3622"],[1.0,"3f2519"]]
const HIDE:=["9c7a52","6e5541"]

## A people of the early bands: [mark, look]
const BAND:=[
	["petitioner",{"variant":"male_adult","outfit":"hide","hair":"long","beard":"beard_full","depth":0.62,"hair_colour":"1b1511","cloth":["a8782a","6e5541","a8432f"],"stance":"clasped","mood":"afraid"}],
	["officials_0",{"variant":"female_old","outfit":"hide","hair":"bun","depth":0.55,"hair_colour":"b5b0a6","cloth":["9c7a52","5b4130","c9a43c"],"stance":"staff"}],
	["officials_1",{"variant":"male_young","outfit":"hide","hair":"tail","depth":0.48,"hair_colour":"1d1813","cloth":["a8782a","6e5541","4f7a68"],"stance":"hip","without":["hide_cape"]}],
	["officials_2",{"variant":"female_adult","outfit":"hide","hair":"braids","depth":0.70,"hair_colour":"4a2a1a","cloth":["b07a35","6e5541","8e2f3a"],"stance":"folded","without":["hide_cape"]}],
	["officials_3",{"variant":"male_old","outfit":"hide","hair":"cropped","beard":"beard_long","depth":0.40,"hair_colour":"a8a49c","cloth":["9c7a52","5b4130","2f4a6e"],"stance":"belt"}],
	["crowd_0",{"variant":"female_adult","outfit":"hide","hair":"long_framed","depth":0.58,"hair_colour":"2a1a12","cloth":["a8782a","6e5541","a8432f"],"stance":"sit","without":["hide_cape"]}],
	["crowd_2",{"variant":"male_adult","outfit":"hide","hair":"curls","beard":"beard_short","depth":0.80,"hair_colour":"120e0b","cloth":["9c7a52","6e5541","c9a43c"],"stance":"sit"}],
	["crowd_4",{"variant":"male_young","outfit":"hide","hair":"cropped","depth":0.35,"hair_colour":"3a2618","cloth":["b07a35","6e5541","4f7a68"],"stance":"crouch","without":["hide_cape"]}],
]
## The same people a few generations on, in the chief's hall.
const HALL:=[
	["petitioner",{"variant":"female_adult","outfit":"tunic","hair":"braids","depth":0.45,"hair_colour":"3b2416","cloth":["a8432f","5b4130","c9a43c"],"stance":"clasped"}],
	["officials_0",{"variant":"male_old","outfit":"robe","hair":"cropped","beard":"beard_long","depth":0.52,"hair_colour":"a8a49c","cloth":["2f4a6e","8e2f3a","c9a43c"],"stance":"staff"}],
	["officials_1",{"variant":"male_adult","outfit":"tunic","hair":"topknot","beard":"beard_short","depth":0.66,"hair_colour":"16110d","cloth":["4f7a68","5b4130","a8432f"],"stance":"folded"}],
	["officials_2",{"variant":"female_old","outfit":"robe","hair":"bun","depth":0.38,"hair_colour":"b8b2a6","cloth":["d9ccb0","4f7a68","a8432f"],"stance":"clasped"}],
	["officials_3",{"variant":"male_young","outfit":"tunic","hair":"curls","depth":0.86,"hair_colour":"0f0d0c","cloth":["c9a43c","5b4130","2f4a6e"],"stance":"belt"}],
	["officials_4",{"variant":"female_young","outfit":"tunic","hair":"tail","depth":0.22,"hair_colour":"6a3320","cloth":["8e2f3a","5b4130","d9ccb0"],"stance":"hip"}],
	["crowd_0",{"variant":"male_adult","outfit":"tunic","hair":"long","beard":"beard_full","depth":0.58,"hair_colour":"2a1a12","cloth":["a8782a","6e5541","a8432f"],"stance":"sit"}],
	["crowd_2",{"variant":"female_adult","outfit":"tunic","hair":"bun","depth":0.74,"hair_colour":"241a14","cloth":["2f4a6e","6e5541","c9a43c"],"stance":"sit"}],
]

## shot: [tag, set, facts, cast, camera]
const SHOTS:=[
	{"tag":"fire-wide","era":"hearth_council","facts":{"food":0.75,"war":false,"tier":0},"cast":"band","camera":"wide"},
	{"tag":"fire-wide-war-hungry","era":"hearth_council","facts":{"food":0.08,"war":true,"tier":0},"cast":"band","camera":"wide"},
	{"tag":"fire-push","era":"hearth_council","facts":{"food":0.75,"tier":0},"cast":"band","camera":"push_in","who":"petitioner"},
	{"tag":"fire-reaction","era":"hearth_council","facts":{"food":0.75,"tier":0},"cast":"band","camera":"reaction","who":"officials_0"},
	{"tag":"fire-strip","era":"hearth_council","facts":{"food":0.75,"tier":0},"cast":"band","camera":"wide","size":[1318,330],"insets":[40,40]},
	{"tag":"hall-wide","era":"chiefs_hall","facts":{"food":0.85,"tier":1},"cast":"hall","camera":"wide"},
	{"tag":"hall-two","era":"chiefs_hall","facts":{"food":0.85,"tier":1},"cast":"hall","camera":"two_shot","who":"petitioner","with":"officials_1"},
	{"tag":"hall-strip","era":"chiefs_hall","facts":{"food":0.85,"tier":1},"cast":"hall","camera":"wide","size":[1318,330],"insets":[40,40]},
	{"tag":"dog","era":"hearth_council","facts":{"food":0.75,"tier":0},"cast":"band","camera":"dog"},
	{"tag":"dogsheet","era":"hearth_council","facts":{"food":0.75,"tier":0},"cast":"none","camera":"dogsheet"},
]
const DOG_CLIPS:=["idle","sniff","walk","trot","sit_idle","scratch","lie_idle","cower_idle","tilt","bark","grab","wag"]

var capture:=false
var out_dir:=""
var only:=""
var failures:Array[String]=[]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
	out_dir=ProjectSettings.globalize_path("res://reports/court_set/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	if capture:
		get_window().size=Vector2i(W,H)
	await _frames(2)
	if not CourtSet.available():
		_fail("no court sets under %s" % CourtSet.DIR)
	else:
		for spec:Dictionary in SHOTS:
			if not only.is_empty() and not String(spec.tag).contains(only):continue
			await _shot(spec)
		if capture and (only.is_empty() or only=="clip"):await _clip()
	if failures.is_empty():
		print("COURT_SET_CAPTURE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("COURT_SET_CAPTURE FAIL: ",failure)
		get_tree().quit(1)

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

func _fail(message:String)->void:
	failures.append(message)

static func skin_at(depth:float)->Color:
	for i in range(1,SKIN_RAMP.size()):
		var a:Array=SKIN_RAMP[i-1];var b:Array=SKIN_RAMP[i]
		if depth<=float(b[0]):
			var t:=(depth-float(a[0]))/maxf(0.0001,float(b[0])-float(a[0]))
			return Color(String(a[1])).lerp(Color(String(b[1])),t)
	return Color(String(SKIN_RAMP[-1][1]))

func _look(raw:Dictionary,index:int)->Dictionary:
	var look:=raw.duplicate(true)
	look["skin"]=skin_at(float(raw.get("depth",0.5)))
	look["hair_colour"]=Color(String(raw.get("hair_colour","2b2018")))
	var cloth:Array=[]
	for c in raw.get("cloth",[]):cloth.append(Color(String(c)))
	if String(raw.get("outfit",""))=="hide":
		cloth[0]=Color(HIDE[0]).lerp(cloth[0],0.30);cloth[1]=Color(HIDE[1])
	look["cloth"]=cloth
	var face:={}
	for k in Figure3D.FACE_SHAPES.size():
		var shape:String=Figure3D.FACE_SHAPES[k]
		if shape=="aged":continue
		face[shape]=float(absi(("%d|%s" % [index,shape]).hash())%101)/50.0-1.0
	if String(raw.get("variant","")).ends_with("old"):face["aged"]=0.7
	look["face"]=face
	return look

## A set with its people on the marks, in a SubViewport of the capture's size.
func _stage(spec:Dictionary)->Array:
	var size:Array=spec.get("size",[W,H])
	var view:=SubViewport.new();view.name="Stage";view.size=Vector2i(int(size[0]),int(size[1]))
	view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	var court:Node3D=CourtSet.build(String(spec.era),spec.get("facts",{}))
	view.add_child(court)
	var cast:Array=BAND if String(spec.get("cast","band"))=="band" else ([] if String(spec.get("cast",""))=="none" else HALL)
	var bodies:Dictionary={}
	Figure3D.set_key_light(court.call("key_dir"))
	var index:=0
	for entry:Array in cast:
		var mark_name:=String(entry[0])
		if not court.call("has_mark",mark_name):
			_fail("%s has no mark %s" % [spec.tag,mark_name]);continue
		var fig:=Figure3D.new();fig.name="Figure_"+mark_name
		court.add_child(fig)
		if not fig.setup(_look(entry[1] as Dictionary,index)):
			_fail("figure for %s did not load" % mark_name);continue
		court.call("place",fig,mark_name)
		var m:Marker3D=court.call("mark",mark_name)
		if mark_name.begins_with("officials_"):
			# those standing about turn toward the one before the god
			var p:Marker3D=court.call("mark","petitioner")
			var to:=p.global_position-fig.global_position
			fig.rotation.y=lerp_angle(fig.rotation.y,atan2(to.x,to.z),0.45)
		fig.play(fig.rest_clip(),0.0,float(index)*0.77)
		if bool(m.get_meta("sit",false)):
			# a log or a bench is the seat: the figure's own stool is not needed
			for node in fig.find_children("prop_stool","MeshInstance3D",true,false):(node as MeshInstance3D).visible=false
			var seat:=float(m.get_meta("seat",0.47))
			fig.position.y+=seat-0.47
		for node in fig.find_children("*","MeshInstance3D",true,false):
			(node as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		fig.set_light(court.call("light_at",fig.global_position))
		var shade:MeshInstance3D=CourtSet.contact_shadow(0.85,0.6,0.5)
		fig.add_child(shade)
		bodies[mark_name]=fig
		index+=1
	var insets:Array=spec.get("insets",[0,0])
	var cam:Camera3D=court.get("camera")
	await _frames(2)
	cam.call("set_insets",float(insets[0]),float(insets[1]))
	var subjects:Array=[]
	for key in bodies.keys():
		if String(key).begins_with("petitioner") or String(key).begins_with("officials_"):subjects.append(bodies[key])
	cam.call("wide",subjects,0.0)
	return [view,court,bodies]

func _shot(spec:Dictionary)->void:
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var cam:Camera3D=court.get("camera")
	match String(spec.camera):
		"push_in":
			cam.call("push_in",bodies.get(String(spec.who)),0.0)
		"reaction":
			cam.call("reaction",bodies.get(String(spec.who)),0.0)
		"two_shot":
			cam.call("two_shot",bodies.get(String(spec.who)),bodies.get(String(spec.with)),0.0)
		"dog":
			var dog:Node3D=court.call("animal","dog")
			if dog==null:_fail("no dog in %s" % spec.tag)
			else:
				dog.call("set_active",false)
				dog.position=Vector3(0.9,0.0,2.9);dog.rotation.y=deg_to_rad(-35.0)
				dog.call("play","scratch",0.0,0.2)
				cam.call("frame_dog",dog)
	if String(spec.camera)=="dogsheet":
		var first:Node3D=court.call("animal","dog")
		if first!=null:first.visible=false
		var index:=0
		for clip_name in DOG_CLIPS:
			var beast:Node3D=load("res://scripts/hud/court_animal_3d.gd").new()
			beast.call("setup","dog",court,index)
			court.add_child(beast)
			beast.position=Vector3(-2.1+float(index%4)*1.4,0.0,4.6-float(index/4)*1.15)
			beast.rotation.y=deg_to_rad(70.0)
			beast.call("set_active",false)
			beast.call("play",clip_name,0.0,0.3)
			var aabb:=AABB()
			for mi in beast.find_children("*","MeshInstance3D",true,false):
				aabb=aabb.merge((mi as MeshInstance3D).get_aabb()) if aabb.size!=Vector3.ZERO else (mi as MeshInstance3D).get_aabb()
			print("DOG ",clip_name," aabb ",aabb)
			index+=1
		cam.call("frame_points",PackedVector3Array([Vector3(-2.6,0,5.1),Vector3(2.6,0,5.1),Vector3(-2.6,0.75,2.3),Vector3(2.6,0.75,2.3),Vector3(-2.6,0,1.9),Vector3(2.6,0,1.9)]),8.0,-22.0)
	# let the particles and clips run a moment
	for i in 40:await get_tree().process_frame
	if capture:
		var image:=view.get_texture().get_image()
		var path:=out_dir+"court-set-%s.png" % spec.tag
		image.save_png(path)
		print("CAPTURE ",path)
	_check_marks(court,String(spec.tag))
	view.queue_free()
	await _frames(2)

func _check_marks(court:Node3D,tag:String)->void:
	for needed in ["throne_gaze","petitioner","fire","door","officials_0","crowd_0","envoy_0","animal_0"]:
		if not court.call("has_mark",needed):_fail("%s: no mark %s" % [tag,needed])

## A short clip: the wide shot, a push onto the one before the god, the god's
## wrath (the camera jolts, the dog cowers), a cut to the eldest.
func _clip()->void:
	var spec:={"tag":"clip","era":"hearth_council","facts":{"food":0.7,"tier":0},"cast":"band","size":[960,540]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var cam:Camera3D=court.get("camera")
	var dog:Node3D=court.call("animal","dog")
	var dir:=out_dir+"clip/"
	DirAccess.make_dir_recursive_absolute(dir)
	var fps:=12
	var frames:=fps*9
	var step:=1.0/float(fps)
	var clock:=0.0
	var events:=[[0.6,"push"],[3.6,"wrath"],[5.6,"reaction"],[7.4,"wide"]]
	var next:=0
	var shot_index:=0
	var last:=Time.get_ticks_msec()
	while shot_index<frames:
		await get_tree().process_frame
		var now:=Time.get_ticks_msec()
		clock+=float(now-last)/1000.0;last=now
		while next<events.size() and clock>=float(events[next][0]):
			match String(events[next][1]):
				"push":cam.call("push_in",bodies.get("petitioner"),2.8)
				"wrath":
					cam.call("shake",0.75)
					if dog!=null:dog.call("on_god","wrath")
					var p:Node3D=bodies.get("petitioner")
					if p!=null:p.call("play","kneel",0.2)
				"reaction":cam.call("reaction",bodies.get("officials_0"),0.0)
				"wide":cam.call("wide",[],1.2)
			next+=1
		if clock>=float(shot_index)*step:
			view.get_texture().get_image().save_png(dir+"frame_%03d.png" % shot_index)
			shot_index+=1
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)
