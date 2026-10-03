extends Node
## Captures of the court's modelled sets (scripts/hud/court_set_3d.gd) with
## the modelled figures (court_figure_3d.gd) standing on the set's marks, lit
## by the set's own lights (the lit twin of their toon), and the dog about:
## every set wide and in the court's strip, the camera's shots, the props
## answering the facts, the dog's clips, and a clip of the god's wrath.
## Windowed only (tools/run_isolated_gpu_probe.ps1, on a private desktop);
## it writes res://reports/court_set/*.png (reports/ is ignored).
## Headless it checks that each set builds with its marks.
##   ... -Scene res://tests/court_set_capture.tscn [-UserArguments "--only=fire"]
## The clip: run with --fixed-fps 24 and --only=clip; every frame is saved.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Animal:=preload("res://scripts/hud/court_animal_3d.gd")

const W:=1536
const H:=864
const STRIP:=[1318,330]
const SKIN_RAMP:=[[0.0,"f3dccb"],[0.15,"e8c3a5"],[0.30,"d6a37c"],[0.45,"bd8659"],[0.60,"9f6a43"],[0.75,"7d4e2f"],[0.90,"5b3622"],[1.0,"3f2519"]]
const HIDE:=["9c7a52","6e5541"]

const BAND:=[
	["petitioner",{"variant":"male_adult","outfit":"hide","hair":"long","beard":"beard_full","depth":0.62,"hair_colour":"1b1511","cloth":["a8782a","6e5541","a8432f"],"stance":"clasped"}],
	["officials_0",{"variant":"female_old","outfit":"hide","hair":"bun","depth":0.55,"hair_colour":"b5b0a6","cloth":["9c7a52","5b4130","c9a43c"],"stance":"staff"}],
	["officials_1",{"variant":"male_young","outfit":"hide","hair":"tail","depth":0.48,"hair_colour":"1d1813","cloth":["a8782a","6e5541","4f7a68"],"stance":"hip","without":["hide_cape"]}],
	["officials_2",{"variant":"female_adult","outfit":"hide","hair":"braids","depth":0.70,"hair_colour":"4a2a1a","cloth":["b07a35","6e5541","8e2f3a"],"stance":"folded","without":["hide_cape"]}],
	["officials_3",{"variant":"male_old","outfit":"hide","hair":"cropped","beard":"beard_long","depth":0.40,"hair_colour":"a8a49c","cloth":["9c7a52","5b4130","2f4a6e"],"stance":"belt"}],
	["crowd_0",{"variant":"female_adult","outfit":"hide","hair":"long_framed","depth":0.58,"hair_colour":"2a1a12","cloth":["a8782a","6e5541","a8432f"],"stance":"sit","without":["hide_cape"]}],
	["crowd_2",{"variant":"male_adult","outfit":"hide","hair":"curls","beard":"beard_short","depth":0.80,"hair_colour":"120e0b","cloth":["9c7a52","6e5541","c9a43c"],"stance":"sit"}],
	["crowd_5",{"variant":"male_young","outfit":"hide","hair":"cropped","depth":0.35,"hair_colour":"3a2618","cloth":["b07a35","6e5541","4f7a68"],"stance":"crouch","without":["hide_cape"]}],
]
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
const COURT:=[
	["petitioner",{"variant":"male_adult","outfit":"tunic","hair":"cropped","beard":"beard_short","depth":0.5,"hair_colour":"2a1a12","cloth":["4f7a68","6e5541","c9a43c"],"stance":"clasped"}],
	["officials_0",{"variant":"female_old","outfit":"robe","hair":"bun","depth":0.3,"hair_colour":"b8b2a6","cloth":["8e2f3a","c9a43c","d9ccb0"],"stance":"staff"}],
	["officials_1",{"variant":"male_old","outfit":"robe","hair":"cropped","beard":"beard_long","depth":0.6,"hair_colour":"a8a49c","cloth":["2f4a6e","c9a43c","8e2f3a"],"stance":"folded"}],
	["officials_2",{"variant":"male_adult","outfit":"robe","hair":"topknot","beard":"beard_chin","depth":0.75,"hair_colour":"0f0d0c","cloth":["c9a43c","2f4a6e","d9ccb0"],"stance":"clasped"}],
	["officials_3",{"variant":"female_adult","outfit":"robe","hair":"long_framed","depth":0.45,"hair_colour":"3b2416","cloth":["4f7a68","8e2f3a","c9a43c"],"stance":"belt"}],
	["officials_4",{"variant":"male_young","outfit":"tunic","hair":"curls","depth":0.85,"hair_colour":"0f0d0c","cloth":["a8432f","5b4130","d9ccb0"],"stance":"hip"}],
	["crowd_0",{"variant":"male_old","outfit":"robe","hair":"long","beard":"beard_full","depth":0.4,"hair_colour":"b5b0a6","cloth":["5b4130","a8782a","c9a43c"],"stance":"sit"}],
	["crowd_2",{"variant":"female_young","outfit":"tunic","hair":"braids","depth":0.6,"hair_colour":"2a1a12","cloth":["8e2f3a","c9a43c","d9ccb0"],"stance":"sit"}],
]
const CASTS:={"band":BAND,"hall":HALL,"court":COURT}

const TAGS_LATE:=["pottery","weaving","writing","farming","baking","candles","metal","masonry"]
const SHOTS:=[
	{"tag":"fire-wide","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide"},
	{"tag":"fire-strip","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"fire-war-hungry","era":"hearth_council","facts":{"food_days":1,"war":{"enemy":"x"},"tier":0,"era_tags":[]},"cast":"band","camera":"wide"},
	{"tag":"fire-push","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"push_in","who":"petitioner"},
	{"tag":"fire-reaction","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"reaction","who":"officials_0"},
	{"tag":"fire-winter","era":"hearth_council","facts":{"food":0.4,"tier":0,"era_tags":[],"season":"winter"},"cast":"band","camera":"wide"},
	{"tag":"fire-winter-strip","era":"hearth_council","facts":{"food":0.4,"tier":0,"era_tags":[],"season":"winter"},"cast":"band","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"shelter-summer","era":"elders_circle","facts":{"food":0.8,"tier":1,"era_tags":["pottery","farming"],"season":"summer"},"cast":"band","camera":"wide"},
	{"tag":"shelter-autumn-strip","era":"elders_circle","facts":{"food":0.8,"tier":1,"era_tags":["pottery","farming"],"season":"autumn"},"cast":"band","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"shelter-wide","era":"elders_circle","facts":{"food":0.7,"tier":1,"era_tags":["pottery","farming"]},"cast":"band","camera":"wide"},
	{"tag":"shelter-strip","era":"elders_circle","facts":{"food":0.7,"tier":1,"era_tags":["pottery","farming"]},"cast":"band","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"hall-wide","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving","baking"]},"cast":"hall","camera":"wide"},
	{"tag":"hall-strip","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving","baking"]},"cast":"hall","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"hall-two","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving"]},"cast":"hall","camera":"two_shot","who":"petitioner","with":"officials_1"},
	{"tag":"mudbrick-wide","era":"temple_palace","facts":{"food":0.8,"tier":2,"era_tags":TAGS_LATE},"cast":"court","camera":"wide"},
	{"tag":"mudbrick-strip","era":"temple_palace","facts":{"food":0.8,"tier":2,"era_tags":TAGS_LATE},"cast":"court","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"grand-wide","era":"imperial_court","facts":{"food":0.9,"tier":3,"era_tags":TAGS_LATE},"cast":"court","camera":"wide"},
	{"tag":"grand-strip","era":"imperial_court","facts":{"food":0.9,"tier":3,"era_tags":TAGS_LATE},"cast":"court","camera":"wide","size":STRIP,"insets":[40,40]},
	{"tag":"dog","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"dog"},
	{"tag":"goat-herds","era":"elders_circle","facts":{"food":0.8,"tier":1,"era_tags":["pottery","farming","dairy"]},"cast":"band","camera":"goat","clip":"graze","at":0.8,"frame":"wide"},
	{"tag":"goat-startle","era":"elders_circle","facts":{"food":0.8,"tier":1,"era_tags":["pottery","farming","dairy"]},"cast":"band","camera":"goat","clip":"startle","at":0.12},
	{"tag":"shelter-summer-spoil","era":"elders_circle","facts":{"food":0.95,"tier":1,"era_tags":["pottery","farming"],"season":"summer"},"cast":"band","camera":"rack"},
	{"tag":"fire-hull","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide","ink":"hull"},
	{"tag":"god-fire-speaks","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide","god":"speaks"},
	{"tag":"god-fire-wrath","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide","god":"wrath"},
	{"tag":"god-fire-favour","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","camera":"wide","god":"favour"},
	{"tag":"god-hall-speaks","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving"]},"cast":"hall","camera":"wide","god":"speaks"},
	{"tag":"god-hall-wrath","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving"]},"cast":"hall","camera":"wide","god":"wrath"},
	{"tag":"god-hall-favour","era":"chiefs_hall","facts":{"food":0.85,"tier":1,"era_tags":["pottery","weaving"]},"cast":"hall","camera":"wide","god":"favour"},
	{"tag":"dogsheet","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"none","camera":"dogsheet"},
]
const DOG_CLIPS:=["idle","sniff","walk","trot","sit_idle","scratch","lie_idle","cower_idle","tilt","bark","grab","wag"]

const PERF_SETS:=[["hearth_council",0,"band"],["elders_circle",1,"band"],["chiefs_hall",1,"hall"],["temple_palace",2,"court"],["imperial_court",3,"court"]]

var capture:=false
var out_dir:=""
var only:=""
## --toon: leave the figures on J's own toon (to measure the lit twin's cost)
var toon:=false
var noshaft:=false
## --hull: the old inked shells on every figure and piece, for comparison
var hull:=false
var inkdebug:=false
var nomsaa:=false
## --one=<era>: measure only that court
var one:=""
var failures:Array[String]=[]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
		if arg=="--toon":toon=true
		if arg=="--noshaft":noshaft=true
		if arg=="--hull":hull=true
		if arg=="--inkdebug":inkdebug=true
		if arg=="--nomsaa":nomsaa=true
		if arg.begins_with("--one="):one=arg.trim_prefix("--one=")
	out_dir=ProjectSettings.globalize_path("res://reports/court_set/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	if capture:get_window().size=Vector2i(W,H)
	await _frames(2)
	if not CourtSet.available():
		_fail("no court sets under %s" % CourtSet.DIR)
	elif only=="clip":
		if capture:await _clip()
	elif only=="godclip":
		if capture:await _god_clip()
	elif only=="goatclip":
		if capture:await _goat_clip()
	elif only=="perf":
		if capture:await _perf()
	else:
		for spec:Dictionary in SHOTS:
			if not only.is_empty() and not String(spec.tag).contains(only):continue
			await _shot(spec)
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
	# in a modelled court the figures take the set's light (as the stage asks)
	look["lit"]=true
	return look

## A set with its people on the marks, in a SubViewport of the capture's size.
func _stage(spec:Dictionary)->Array:
	var size:Array=spec.get("size",[W,H])
	var view:=SubViewport.new();view.name="Stage";view.size=Vector2i(int(size[0]),int(size[1]))
	view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_DISABLED if nomsaa else Viewport.MSAA_2X
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	CourtSet.ink="hull" if hull or String(spec.get("ink",""))=="hull" else "screen"
	var court:Node3D=CourtSet.build(String(spec.era),spec.get("facts",{}))
	view.add_child(court)
	if inkdebug and court.get("ink_pass")!=null:((court.get("ink_pass") as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("debug",1)
	if noshaft:
		for node in court.find_children("SunShaft*","MeshInstance3D",false,false):(node as Node3D).visible=false
	var cast:Array=CASTS.get(String(spec.get("cast","band")),[])
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
			var p:Marker3D=court.call("mark","petitioner")
			var to:=p.global_position-fig.global_position
			fig.rotation.y=lerp_angle(fig.rotation.y,atan2(to.x,to.z),0.45)
		fig.play(fig.rest_clip(),0.0,float(index)*0.77)
		if bool(m.get_meta("sit",false)):
			for node in fig.find_children("prop_stool","MeshInstance3D",true,false):(node as MeshInstance3D).visible=false
		for node in fig.find_children("*","MeshInstance3D",true,false):
			(node as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		fig.add_child(CourtSet.contact_shadow(0.85,0.6,0.5))
		if CourtSet.uses_screen_ink():_strip_shells(fig)
		if not toon:court.call("add_breath",fig)
		bodies[mark_name]=fig
		index+=1
	var insets:Array=spec.get("insets",[0,0])
	var rig:Node=court.get("rig")
	await _frames(2)
	rig.call("set_insets",float(insets[0]),float(insets[1]))
	var subjects:Array=[]
	for key in bodies.keys():
		if String(key).begins_with("petitioner") or String(key).begins_with("officials_"):subjects.append(bodies[key])
	rig.call("wide",subjects,0.0,bodies.get("petitioner"))
	return [view,court,bodies]

## TEST ONLY, until J's figures take the screen ink themselves: the figure's
## own inked shells are taken off (the stage ink draws their line instead).
func _strip_shells(fig:Node3D)->void:
	for node in fig.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=node as MeshInstance3D
		if mesh_node.mesh==null:continue
		for surface in mesh_node.mesh.get_surface_count():
			var mat:=mesh_node.get_surface_override_material(surface) as ShaderMaterial
			if mat==null or mat.next_pass==null:continue
			var bare:ShaderMaterial=_bare.get(mat)
			if bare==null:
				bare=mat.duplicate() as ShaderMaterial
				bare.next_pass=null
				_bare[mat]=bare
			mesh_node.set_surface_override_material(surface,bare)

var _bare:Dictionary={}

func _shot(spec:Dictionary)->void:
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	match String(spec.camera):
		"push_in":
			rig.call("push_in",bodies.get(String(spec.who)),0.0)
		"reaction":
			rig.call("reaction",bodies.get(String(spec.who)),0.0)
		"two_shot":
			rig.call("two_shot",bodies.get(String(spec.who)),bodies.get(String(spec.with)),0.0)
		"dog":
			var dog:Node3D=court.call("animal","dog")
			if dog==null:_fail("no dog in %s" % spec.tag)
			else:
				dog.call("set_active",false)
				dog.position=Vector3(0.9,0.0,2.9);dog.rotation.y=deg_to_rad(25.0)
				dog.call("play","lie_idle",0.0,0.5)
				rig.call("frame_animal",dog)
		"rack":
			# close on the meat rack, where the flies are
			var spot:Vector3=court.call("rack_centre")
			rig.call("frame_points",PackedVector3Array([spot+Vector3(-1.4,-1.4,0.4),spot+Vector3(1.4,0.6,-0.4)]),18.0,-6.0)
		"goat":
			var goat:Node3D=court.call("animal","goat")
			if goat==null:_fail("no goat in %s" % spec.tag)
			else:
				goat.call("set_active",false)
				goat.rotation.y=deg_to_rad(-40.0)
				goat.call("play",String(spec.get("clip","idle")),0.0,float(spec.get("at",0.5)))
				if String(spec.get("frame","animal"))=="animal":rig.call("frame_animal",goat)
		"dogsheet":
			var first:Node3D=court.call("animal","dog")
			if first!=null:first.visible=false
			var index:=0
			for clip_name in DOG_CLIPS:
				var beast:Node3D=Animal.new()
				beast.call("setup","dog",court,index)
				court.add_child(beast)
				beast.position=Vector3(-2.1+float(index%4)*1.4,0.0,4.6-float(index/4)*1.15)
				beast.rotation.y=deg_to_rad(70.0)
				beast.call("set_active",false)
				beast.call("play",clip_name,0.0,0.3)
				index+=1
			rig.call("frame_points",PackedVector3Array([Vector3(-2.6,0,5.1),Vector3(2.6,0,5.1),Vector3(-2.6,0.75,2.3),Vector3(2.6,0.75,2.3),Vector3(-2.6,0,1.9),Vector3(2.6,0,1.9)]),8.0,-22.0)
	if spec.has("god"):
		court.call("god_light",bodies.get("petitioner"),String(spec.god),0.0,0.0)
		if String(spec.god)=="wrath":
			var p:Node3D=bodies.get("petitioner")
			if p!=null:p.call("play","kneel",0.0,5.0)
			var dog:Node3D=court.call("animal","dog")
			if dog!=null:dog.call("cower",30.0)
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

## The god's wrath in the court's strip, at a fixed rate (8 s): the room; the
## god speaks to the petitioner (gold from the sky, the camera pushes in);
## wrath lands (cold light, a jolt, the fire gutters, the hides and the smoke
## are thrown aside, the petitioner goes down, the dog cowers); the hush; the
## light eases back and the camera returns to the room.
func _god_clip()->void:
	var spec:={"tag":"godclip","era":"hearth_council","facts":{"food":0.7,"tier":0,"era_tags":[]},"cast":"band","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var dog:Node3D=court.call("animal","dog")
	var p:Node3D=bodies.get("petitioner")
	if dog!=null:
		dog.call("hold",30.0)
		var spot:Marker3D=court.call("mark","animal_0")
		dog.position=spot.position;dog.rotation.y=deg_to_rad(-35.0)
		dog.call("play","sit_idle",0.0,0.4)
	var dir:=out_dir+"godclip/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	for frame in 192:
		match frame:
			24:
				court.call("god_light",p,"speaks",0.0,1.2)
				rig.call("push_in",p,3.0)
				if dog!=null:dog.call("on_god","speaks")
			96:
				court.call("god_light",p,"wrath",0.0,0.25)
				rig.call("shake",0.8)
				if p!=null:p.call("play","kneel",0.15)
				for key in ["officials_2","officials_3"]:
					var o:Node3D=bodies.get(key)
					if o!=null:o.call("play","bow",0.25)
				if dog!=null:dog.call("cower",6.0)
			160:
				court.call("god_light",null,"off",0.0,1.4)
				rig.call("wide",[],1.4)
		await get_tree().process_frame
		view.get_texture().get_image().save_png(dir+"frame_%03d.png" % frame)
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)

## The goat at the god's wrath: it is grazing by the fire when the wrath
## lands, jumps on the spot and stands there staring (4 s at a fixed rate).
func _goat_clip()->void:
	var spec:={"tag":"goatclip","era":"elders_circle","facts":{"food":0.8,"tier":1,"era_tags":["pottery","farming","dairy"]},"cast":"band","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var goat:Node3D=court.call("animal","goat")
	var dog:Node3D=court.call("animal","dog")
	if goat==null:
		_fail("no goat");view.queue_free();return
	goat.call("hold",30.0)
	goat.rotation.y=deg_to_rad(-40.0)
	goat.call("play","graze",0.0,0.3)
	if dog!=null:
		dog.call("hold",30.0)
		dog.position=Vector3(-0.3,0.0,1.0);dog.rotation.y=deg_to_rad(20.0)
		dog.call("play","sit_idle",0.0,0.4)
	rig.call("wide",[bodies.get("petitioner"),goat],0.0,bodies.get("petitioner"))
	var dir:=out_dir+"goatclip/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	for frame in 96:
		if frame==24:
			rig.call("shake",0.8)
			goat.call("on_god","wrath")
			if dog!=null:dog.call("cower",6.0)
		await get_tree().process_frame
		view.get_texture().get_image().save_png(dir+"frame_%03d.png" % frame)
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)

## Draw calls and frame times for every set in the court's strip, with its
## people, at high and low quality (printed as PERF lines).
func _perf()->void:
	for entry:Array in PERF_SETS:
		if not one.is_empty() and String(entry[0])!=one:continue
		for run in [["high",entry[2],"screen"],["high",entry[2],"hull"],["low",entry[2],"screen"],["high","none","screen"]]:
			var q:String=run[0]
			var spec:={"tag":"perf","era":entry[0],"facts":{"food":0.8,"tier":entry[1]},"cast":run[1],"size":STRIP,"insets":[40,40],"ink":run[2]}
			var made:=await _stage(spec)
			var view:SubViewport=made[0];var court:Node3D=made[1]
			court.call("set_quality",q,"perf")
			RenderingServer.viewport_set_measure_render_time(view.get_viewport_rid(),true)
			for i in 30:await get_tree().process_frame
			var gpu:=0.0;var cpu:=0.0;var n:=0
			for i in 60:
				await get_tree().process_frame
				gpu+=RenderingServer.viewport_get_measured_render_time_gpu(view.get_viewport_rid())
				cpu+=RenderingServer.viewport_get_measured_render_time_cpu(view.get_viewport_rid())
				n+=1
			var draws:=view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			var prims:=view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			var objects:=view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
			print("PERF %s %s %s ink=%s draws=%d objects=%d primitives=%d gpu_ms=%.2f cpu_ms=%.2f fps=%d" % [court.get("kind"),q,"people" if run[1]!="none" else "set-only",run[2],draws,objects,prims,gpu/float(n),cpu/float(n),Engine.get_frames_per_second()])
			view.queue_free()
			await _frames(2)

## The god's wrath in the court's strip, a frame for every frame at a fixed
## rate (run with --fixed-fps 24): the room, the god speaks and the camera
## pushes in on the petitioner, the wrath lands (a jolt, the petitioner goes
## down, the dog cowers), a cut to the eldest, back to the room.
func _clip()->void:
	var spec:={"tag":"clip","era":"hearth_council","facts":{"food":0.7,"tier":0,"era_tags":[]},"cast":"band","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var dog:Node3D=court.call("animal","dog")
	if dog!=null:
		dog.call("hold",30.0)
		var spot:Marker3D=court.call("mark","animal_0")
		dog.position=spot.position;dog.rotation.y=deg_to_rad(-35.0)
		dog.call("play","sit_idle",0.0,0.4)
	var dir:=out_dir+"clip/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	var fps:=24
	var frames:=fps*10
	var events:=[[24,"push"],[96,"wrath"],[100,"down"],[150,"reaction"],[200,"wide"]]
	var next:=0
	for frame in frames:
		while next<events.size() and frame>=int(events[next][0]):
			match String(events[next][1]):
				"push":rig.call("push_in",bodies.get("petitioner"),3.2)
				"wrath":
					rig.call("shake",0.8)
					if dog!=null:dog.call("cower",6.0)
				"down":
					var p:Node3D=bodies.get("petitioner")
					if p!=null:p.call("play","kneel",0.15)
					# the young one drops to a crouch, two bow their heads, the eldest stands and looks at him
					var young:Node3D=bodies.get("officials_1")
					if young!=null:young.call("play","crouch",0.2)
					for key in ["officials_2","officials_3"]:
						var o:Node3D=bodies.get(key)
						if o!=null:o.call("play","bow",0.25)
					var eldest:Node3D=bodies.get("officials_0")
					if eldest!=null and p!=null:eldest.call("look_at_point",p.global_position+Vector3(0.0,0.9,0.0),0.5)
				"reaction":rig.call("reaction",bodies.get("officials_0"),0.0)
				"wide":rig.call("wide",[],1.4)
			next+=1
		await get_tree().process_frame
		view.get_texture().get_image().save_png(dir+"frame_%03d.png" % frame)
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)
