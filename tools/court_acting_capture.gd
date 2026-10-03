extends Node
## Court acting captures (K): the acting vocabulary in the game's own renderer
## (J's figures and toon shader, court_acting.gd driving them), at the
## player's screen size. A test stage, not the Court: a plain warm wall and
## floor, a row of people of different bodies and dress.
##
## Windowed only, on the private desktop:
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> \
##     -Scene res://tools/court_acting_capture.tscn -LogFile <log> [-UserArguments "sheets" | "room"]
## Writes res://reports/court_acting/ (reports/ is ignored):
##   sheet_reactions.png   one person a reaction, each at its strongest moment
##   sheet_<clip>.png      one reaction through time, a person a moment
##   sheet_talk.png        talking gestures at their beat
##   sheet_idle.png        people at rest: glances, weight, breath (nobody stares out)
##   room/frame_####.png   a room taking the god's wrath, 30 fps (the "room" run)
##   r2_*.png              round 2 ("r2"): laughs, side-eye, the catch, stances, business, exits
##   room2/frame_####.png  a fire circle hears the god ("room2")

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const W:=1536
const H:=864
const DT:=1.0/30.0

## People of the test row: variant, outfit, hair, beard, skin, hair colour, cloth a/b/c, stance.
const PEOPLE:=[
	["male_adult","hide","long","beard_full","7d4e2f","1b1511",["a8782a","6e5541","a8432f"],"stand"],
	["female_adult","tunic","braids","","d6a37c","4a2a1a",["b07a35","6e5541","8e2f3a"],"hip"],
	["male_old","robe","cropped","beard_long","9f6a43","a8a49c",["2f4a6e","8e2f3a","c9a43c"],"clasped"],
	["female_young","tunic","curls","","5b3622","0f0d0c",["a8432f","5b4130","d9ccb0"],"stand"],
	["male_young","tunic","tail","","e8c3a5","2a1c12",["4f7a68","5b4130","d08a2b"],"belt"],
	["female_old","hide","bun","","bd8659","b5b0a6",["9c7a52","5b4130","c9a43c"],"clasped"],
	["male_adult","tunic","topknot","beard_short","bd8659","3a2a1c",["6d4b6b","2f4a6e","c9a43c"],"folded"],
]

var out_dir:=""
var camera:Camera3D
var world:Node3D
var labels:CanvasLayer
var figures:Array[Node3D]=[]

func _ready()->void:
	out_dir=ProjectSettings.globalize_path("res://reports/court_acting/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size=Vector2i(W,H);get_window().content_scale_size=Vector2i(W,H)
	_stage()
	await _frames(3)
	var mode:="sheets"
	for a in OS.get_cmdline_user_args():mode=String(a)
	if mode=="room":await _room()
	elif mode=="room2":await _room2()
	elif mode=="r2":await _sheets_r2()
	else:await _sheets()
	print("COURT_ACTING_CAPTURE DONE ",out_dir)
	get_tree().quit(0)

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

func _stage()->void:
	world=Node3D.new();world.name="World";add_child(world)
	var env:=WorldEnvironment.new()
	var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR;e.background_color=Color("2b2118")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("b49a7a");e.ambient_light_energy=0.6
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.light_color=Color("ffd9a8");sun.light_energy=1.1
	sun.rotation_degrees=Vector3(-42.0,-28.0,0.0);world.add_child(sun)
	Figure3D.set_key_light(Vector3(-0.35,0.65,0.68))
	var floor_mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new();plane.size=Vector2(30.0,14.0);floor_mesh.mesh=plane
	var fm:=StandardMaterial3D.new();fm.albedo_color=Color("6e5640");fm.roughness=1.0;floor_mesh.material_override=fm
	world.add_child(floor_mesh)
	var wall:=MeshInstance3D.new()
	var quad:=QuadMesh.new();quad.size=Vector2(30.0,8.0);wall.mesh=quad
	var wm:=StandardMaterial3D.new();wm.albedo_color=Color("8a6d4e");wm.roughness=1.0;wall.material_override=wm
	wall.position=Vector3(0.0,4.0,-3.2);world.add_child(wall)
	camera=Camera3D.new();camera.fov=30.0
	camera.position=Vector3(0.0,1.75,8.6);camera.rotation_degrees=Vector3(-6.5,0.0,0.0)
	world.add_child(camera);camera.current=true
	labels=CanvasLayer.new();add_child(labels)

func _person(i:int,stance:="")->Node3D:
	var p:Array=PEOPLE[i%PEOPLE.size()]
	var f:Node3D=Figure3D.new()
	f.set_meta(&"person_name","capture %d" % i)
	world.add_child(f)
	var cloth:Array=[]
	for c in p[6]:cloth.append(Color(String(c)))
	f.setup({"variant":p[0],"outfit":p[1],"hair":p[2],"beard":p[3],"skin":Color(String(p[4])),"hair_colour":Color(String(p[5])),
		"cloth":cloth,"stance":stance if not stance.is_empty() else String(p[7])})
	f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	f.play(f.rest_clip(),0.0,float(i)*0.7)
	var a=Acting.of(f)
	a.active=false   # stepped by hand below, one frame at a time
	figures.append(f)
	return f

func _clear()->void:
	for f in figures:f.queue_free()
	figures.clear()
	for c in labels.get_children():c.queue_free()
	for c in props:c.queue_free()
	props.clear()

var props:Array[Node3D]=[]

## A plain prop for context (a log to sit on, a fire's glow): the capture's own, not the set's.
func _prop(kind:String,at:Vector3,scale_k:=1.0)->void:
	var m:=MeshInstance3D.new()
	var mat:=StandardMaterial3D.new();mat.roughness=1.0
	match kind:
		"log":
			var c:=CylinderMesh.new();c.top_radius=0.13*scale_k;c.bottom_radius=0.14*scale_k;c.height=0.9
			m.mesh=c;m.rotation_degrees=Vector3(0.0,0.0,90.0);mat.albedo_color=Color("5a3e26")
		"fire":
			var sph:=SphereMesh.new();sph.radius=0.16;sph.height=0.22
			m.mesh=sph;mat.albedo_color=Color("ff9a3c");mat.emission_enabled=true;mat.emission=Color("ff7a1c");mat.emission_energy_multiplier=2.5
			var glow:=OmniLight3D.new();glow.light_color=Color("ffb060");glow.light_energy=2.0;glow.omni_range=3.0;glow.position=Vector3(0,0.4,0)
			m.add_child(glow)
	m.material_override=mat
	m.position=at
	world.add_child(m)
	props.append(m)

## Frame a row tighter (fewer people, nearer): width of the row in metres.
func _frame_row(width:float,height:=2.05)->void:
	var half:=tan(deg_to_rad(camera.fov*0.5))
	var dist:=maxf(width*1.05*0.5/(half*float(W)/float(H)),height*0.62/half)
	camera.position=Vector3(0.0,height*0.5+dist*tan(deg_to_rad(6.5)),dist)
	camera.rotation_degrees=Vector3(-6.5,0.0,0.0)

## A row of moments: each spec {clip, t, label, who, stance, seat, x, z, yaw, look_at}.
func _row(title:String,specs:Array,file:String,gap:=0.95)->void:
	_clear()
	var n:=specs.size()
	for i in n:
		var spec:Dictionary=specs[i]
		var stance:=String(spec.get("stance",""))
		var own:=Acting.OWN_STANCES.has(stance)
		var f:=_person(int(spec.get("who",i)),"" if own else stance)
		f.position=Vector3(float(spec.get("x",(float(i)-(n-1)*0.5)*gap)),0.0,float(spec.get("z",0.0)))
		f.rotation_degrees.y=float(spec.get("yaw",-6.0+12.0*float(i)/maxf(1.0,float(n-1))))
		if own:Acting.idle(f,stance,{"seat":float(spec.seat)} if spec.has("seat") else {})
		if stance=="log":_prop("log",f.position+Vector3(0.0,float(spec.get("seat",0.43))*f.body_height/1.72-0.13,0.05),1.0)
		if stance=="fire":_prop("fire",f.position+Vector3(0.0,0.10,0.75))
	_step_all(0.6)
	for i in n:
		var spec:Dictionary=specs[i]
		var f:=figures[i]
		if spec.has("look_at"):Acting.look_toward(f,figures[int(spec.look_at)],1.0)
		if not String(spec.get("clip","")).is_empty():Acting.play(f,String(spec.clip))
	# everyone runs together (a pair acts in time); each stops at their own moment
	var longest:=0.0
	for spec:Dictionary in specs:longest=maxf(longest,float(spec.get("t",0.0)))
	var t:=0.0
	while t<longest-0.001:
		for i in n:
			if t<float((specs[i] as Dictionary).get("t",0.0))-0.001:_frame(figures[i])
		t+=DT
	for i in n:
		var spec:Dictionary=specs[i]
		_label(String(spec.get("label","")),figures[i].position+Vector3(0.0,2.0*figures[i].body_height/1.72,0.0),16)
	_title(title)
	await _shot(file)

func _step_all(seconds:float)->void:
	for i in int(round(seconds/DT)):
		for f in figures:_frame(f)

func _frame(f:Node3D)->void:
	f.skeleton.reset_bone_poses()
	f.player.advance(DT)
	Acting.of(f).step(DT)

func _label(text:String,at:Vector3,size:=17,colour:=Color("f3e6cc"))->void:
	var l:=Label.new();l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",colour)
	l.add_theme_color_override("font_outline_color",Color("1d150e"));l.add_theme_constant_override("outline_size",5)
	labels.add_child(l)
	var p:=camera.unproject_position(at)
	l.position=p-Vector2(l.get_minimum_size().x*0.5,0.0)

func _shot(name:String)->void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var img:=get_viewport().get_texture().get_image()
	img.save_png(out_dir+name)
	print("COURT_ACTING_CAPTURE wrote ",out_dir+name)

func _title(text:String)->void:
	var l:=Label.new();l.text=text
	l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",Color("f3e6cc"))
	l.position=Vector2(32.0,22.0);labels.add_child(l)

## A row of people, each frozen at one moment of their own clip.
func _moments(title:String,specs:Array,file:String)->void:
	_clear()
	var n:=specs.size()
	var gap:=1.02
	for i in n:
		var spec:Array=specs[i]
		var f:=_person(int(spec[3]) if spec.size()>3 else i,String(spec[4]) if spec.size()>4 else "")
		f.position=Vector3((float(i)-(n-1)*0.5)*gap,0.0,0.0)
		f.rotation_degrees.y=-8.0+16.0*float(i)/maxf(1.0,float(n-1))
	_step_all(0.4)
	for i in n:
		var spec:Array=specs[i]
		var f:=figures[i]
		if not String(spec[0]).is_empty():Acting.play(f,String(spec[0]))
		var t:=float(spec[1])
		for k in int(round(t/DT)):_frame(f)
		_label(String(spec[2]),f.position+Vector3(0.0,2.08,0.0),16)
	_title(title)
	await _shot(file)

func _sheets()->void:
	await _moments("Reactions at their strongest moment",[
		["gasp",0.62,"gasp",0],["flinch",0.30,"flinch",1],["laugh",1.62,"laugh",2],["laugh_stifled",0.9,"stifled laugh",3],
		["side_eye_l",1.0,"side-eye",4],["defiant",1.6,"defiant",6],["kneel",2.4,"kneel",5]],"sheet_reactions.png")
	await _moments("Bows: shallow, deep, over-deep (and the peek up)",[
		["bow_shallow",0.9,"shallow",1],["bow_deep",1.5,"deep",2],["bow_overdeep",0.75,"over-deep: plunge",0],
		["bow_overdeep",1.5,"wobble",0],["bow_overdeep",2.8,"peek up",0],["bow_overdeep",3.25,"pops up",0]],"sheet_bows.png")
	await _moments("Gasp, moment by moment",[
		["gasp",0.0,"0.00",3],["gasp",0.10,"0.10 breath in",3],["gasp",0.27,"0.27 snatched",3],["gasp",0.6,"0.60 held",3],
		["gasp",1.1,"1.10 easing",3],["gasp",1.6,"1.60 letting go",3]],"sheet_gasp.png")
	await _moments("Talking: gestures at their beat",[
		["talk_explain",0.95,"explain",0],["talk_emphatic",0.46,"emphatic",6,"stand"],["talk_hesitant",1.0,"hesitant",1,"stand"],
		["talk_plead",1.0,"plead",3],["talk_one",0.7,"one thing",4],["talk_dismiss",0.5,"dismiss",2,"stand"]],"sheet_talk.png")
	await _moments("For the director: the falls, the frights, the funny business",[
		["faint_l",1.2,"faint",1],["half_catch_l",0.75,"half-catch",2],["knees_knock",0.24,"knees knock",3],["kneel_bound",1.6,"forced down, bound",6],
		["yawn",0.9,"yawn",4],["doze",2.4,"dozing",5],["bolt_l",0.7,"bolt",0]],"sheet_director_1.png")
	await _moments("For the director: more",[
		["jerk_awake",0.1,"jerk awake",5],["snap_alert",0.6,"snap alert",4],["elbow_l",0.22,"elbow",6],["drop_bowl",0.45,"drop the bowl",3,"bowl"],
		["struggle_bundle",0.5,"heave a bundle",0],["wobble",0.3,"wobble",1],["hide_behind_l",1.2,"hide behind",2]],"sheet_director_2.png")
	await _idle_sheet()

func _sheets_r2()->void:
	camera.fov=26.0
	_frame_row(5.0)
	await _row("The laugh, big and polite; the side-eye",[
		{"clip":"laugh","t":0.6,"label":"laugh: thrown back","who":0},{"clip":"laugh","t":1.58,"label":"laugh: slaps the thigh","who":0},
		{"clip":"laugh_polite","t":0.5,"label":"polite laugh","who":1},{"clip":"side_eye_l","t":1.4,"label":"side-eye","who":4},
		{"clip":"side_eye_r","t":1.4,"label":"side-eye","who":6}],"r2_laughs.png",1.0)
	_frame_row(3.2)
	await _row("She faints; he half-catches her",[
		{"clip":"faint_caught_l","t":0.7,"label":"0.7 s","who":1,"x":-1.15,"yaw":0.0},{"clip":"half_catch_r","t":0.7,"label":"","who":0,"x":-0.42,"yaw":0.0},
		{"clip":"faint_caught_l","t":1.25,"label":"1.25 s","who":1,"x":0.45,"yaw":0.0},{"clip":"half_catch_r","t":1.25,"label":"","who":0,"x":1.18,"yaw":0.0}],"r2_catch.png")
	_frame_row(5.0)
	await _row("Stances for life",[
		{"stance":"cord","t":2.0,"label":"cord","who":3},{"stance":"bundle","t":2.0,"label":"bundle","who":1},
		{"stance":"guard","t":3.0,"label":"guard on his staff","who":0},{"stance":"log","seat":0.38,"t":2.0,"label":"elder on a log","who":2},
		{"stance":"fire","t":2.0,"label":"by the fire","who":4}],"r2_stances.png",1.05)
	await _row("The room's business",[
		{"clip":"cough","t":0.55,"label":"cough","who":5},{"clip":"keep_apart_r","t":0.9,"label":"keeps apart","who":3},
		{"clip":"rub_belly","t":1.0,"label":"stomach rumbles","who":4},{"clip":"stamp_feet","t":0.3,"label":"cold","who":1},
		{"clip":"whisper_l","t":0.9,"label":"whispers","who":6}],"r2_business_1.png",1.0)
	await _row("More business",[
		{"clip":"swat_fly","t":0.76,"label":"swats a fly","who":0},{"clip":"stretch","t":1.0,"label":"stretch","who":4},
		{"clip":"sharpen_spear","t":0.6,"label":"sharpens","who":6,"stance":"staff"},{"clip":"rub_hands","t":1.1,"label":"blows on hands","who":3},
		{"clip":"shush_l","t":0.6,"label":"shush","who":5}],"r2_business_2.png",1.0)
	await _row("Ways out",[
		{"clip":"back_out","t":0.5,"label":"backs out bowing","who":0,"yaw":0.0},{"clip":"bump_post","t":0.4,"label":"bumps a post","who":0,"yaw":0.0},
		{"clip":"storm_stop","t":0.85,"label":"storms off: forgot!","who":6,"yaw":0.0},{"clip":"snatch_up","t":0.42,"label":"snatches it up","who":6,"yaw":0.0},
		{"clip":"walk_led","t":0.4,"label":"led away","who":4,"yaw":40.0}],"r2_exits.png",1.0)

## A fire circle when the god speaks (a demonstration of the vocabulary; the
## director decides who does what in the game).
func _room2()->void:
	camera.fov=28.0
	_clear()
	DirAccess.make_dir_recursive_absolute(out_dir+"room2")
	var cast:=[]
	var places:=[[-2.0,-0.6,30.0,"guard"],[-0.8,0.0,10.0,""],[0.0,0.25,0.0,""],[1.05,0.05,-12.0,""],[2.05,-0.5,-28.0,"log"],[0.5,-1.1,0.0,"fire"]]
	var who:=[0,1,3,4,2,5]
	for i in places.size():
		var p:Array=places[i]
		var f:=_person(who[i],"")
		f.position=Vector3(float(p[0]),0.0,float(p[1]));f.rotation_degrees.y=float(p[2])
		if not String(p[3]).is_empty():Acting.idle(f,String(p[3]),{"seat":0.40} if String(p[3])=="log" else {})
		if String(p[3])=="log":_prop("log",f.position+Vector3(0.0,0.40*f.body_height/1.72-0.13,0.05))
		cast.append(f)
	_prop("fire",Vector3(0.5,0.1,-0.35))
	camera.position=Vector3(0.0,1.9,6.6);camera.rotation_degrees=Vector3(-8.0,0.0,0.0)
	var god:=camera.global_position+Vector3(0.0,2.0,-0.5)
	Acting.play(cast[0],"bored")
	var frames:=int(9.0/DT)
	var done:={}
	for k in frames:
		var t:=float(k)*DT
		if t>=0.8 and not done.has("god"):
			done.god=true
			for f in cast:
				Acting.look_toward(f,god,1.0);Acting.hush(f,true)
			Acting.play(cast[0],"snap_alert")
		if t>=2.6 and not done.has("blow"):
			done.blow=true
			Acting.play(cast[1],"faint_caught_l");Acting.set_mood(cast[1],{"fear":0.9})
			Acting.play(cast[3],"flinch")
			Acting.gesture(cast[4],"jolt")
		if t>=2.75 and not done.has("catch"):
			done.catch=true
			Acting.play(cast[2],"half_catch_r");Acting.look_toward(cast[2],cast[1],1.0)
		if t>=4.6 and not done.has("laugh"):
			done.laugh=true
			Acting.play(cast[3],"laugh_stifled")
		if t>=5.2 and not done.has("eye"):
			done.eye=true
			Acting.look_toward(cast[4],cast[3],1.0);Acting.play(cast[4],"side_eye_r")
		if t>=6.0 and not done.has("shush"):
			done.shush=true
			Acting.play(cast[5],"shush_l")
		for f in cast:_frame(f)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir+"room2/frame_%04d.png" % k)
	print("COURT_ACTING_CAPTURE room2 frames ",frames)

## People at rest for a while: where are they looking?
func _idle_sheet()->void:
	_clear()
	for i in 7:
		var f:=_person(i)
		f.position=Vector3((float(i)-3.0)*1.0,0.0,0.0)
		f.rotation_degrees.y=-10.0+20.0*float(i)/6.0
	_step_all(6.0)
	_title("At rest, six seconds in: breath, weight, glances (nobody stares out)")
	for f in figures:_label(String(f.stance),f.position+Vector3(0.0,2.08,0.0),15)
	await _shot("sheet_idle.png")

## The room takes the god's wrath: every face lifts to the voice; then the
## blow lands and each takes it their own way. (A demonstration of the
## acting vocabulary; in the game the director decides who does what.)
func _room()->void:
	_clear()
	DirAccess.make_dir_recursive_absolute(out_dir+"room")
	var cast:=[]
	for i in 7:
		var f:=_person(i)
		f.position=Vector3((float(i)-3.0)*1.0,0.0,-0.3*absf(float(i)-3.0))
		f.rotation_degrees.y=-14.0+28.0*float(i)/6.0
		cast.append(f)
	var god:=camera.global_position+Vector3(0.0,2.2,-1.0)
	var frames:=int(8.0/DT)
	var done:={}
	# the old man is asleep on his feet when it begins
	Acting.play(cast[2],"doze")
	for k in frames:
		var t:=float(k)*DT
		if t>=0.6 and not done.has("god"):
			done.god=true
			for f in cast:Acting.look_toward(f,god,1.0);Acting.hush(f,true)
			Acting.play(cast[2],"jerk_awake")
		if t>=2.4 and not done.has("wrath"):
			done.wrath=true
			Acting.play(cast[3],"kneel");Acting.set_mood(cast[3],{"fear":0.9})
			Acting.play(cast[1],"knees_knock");Acting.set_mood(cast[1],{"fear":0.9})
			Acting.play(cast[0],"bow_overdeep")
			Acting.play(cast[5],"gasp")
			Acting.gesture(cast[6],"flinch_small")
		if t>=2.9 and not done.has("laugh"):
			done.laugh=true
			Acting.play(cast[4],"laugh_stifled")
		if t>=3.25 and not done.has("elbow"):
			done.elbow=true
			Acting.play(cast[5],"elbow_r");Acting.look_toward(cast[5],cast[4],1.0)
		if t>=3.45 and not done.has("look"):
			done.look=true
			Acting.look_toward(cast[6],cast[4],1.0);Acting.play(cast[6],"side_eye_r")
		if t>=3.7 and not done.has("faint"):
			done.faint=true
			Acting.play(cast[1],"faint_l")
		if t>=3.85 and not done.has("catch"):
			done.catch=true
			Acting.play(cast[2],"half_catch_r");Acting.look_toward(cast[2],cast[1],1.0)
		for f in cast:_frame(f)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir+"room/frame_%04d.png" % k)
	print("COURT_ACTING_CAPTURE room frames ",frames)
