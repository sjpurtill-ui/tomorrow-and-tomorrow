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
##   r4_*.png              round 4 ("r4"): a child at court, sitting cross-legged, mirrored twins

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
	["child","tunic","cropped","","c98d62","3a2a1c",["b07a35","6e5541","4f7a68"],"stand"],
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
	elif mode=="face":await _face_close()
	elif mode=="mouth":await _mouth_test()
	elif mode=="r3":await _sheets_r3()
	elif mode=="r4":await _sheets_r4()
	elif mode=="exec":await _exec_all()
	elif mode.begins_with("exec:"):await _exec(mode.trim_prefix("exec:"))
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
		if stance=="log":_prop("log",f.position+Vector3(0.0,float(spec.get("seat",0.43))-0.13,0.05),1.0)
		if stance=="fire":_prop("fire",f.position+Vector3(0.0,0.10,0.75))
	_step_all(0.6)
	for i in n:
		var spec:Dictionary=specs[i]
		var f:=figures[i]
		if spec.has("look_at"):Acting.look_toward(f,figures[int(spec.look_at)],1.0)
		var c:=String(spec.get("clip",""))
		# a clip by name, else one of the director's words
		if Acting.has_clip(c):Acting.play(f,c)
		elif not c.is_empty():Acting.perform(f,{"beat":c})
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
		if String(p[3])=="log":_prop("log",f.position+Vector3(0.0,0.40-0.13,0.05))
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

## A face up close (as a push-in shows it): the words in the mouth, a gasp,
## a laugh, a side-eye. Frames to face/frame_####.png at 30 a second; the
## line's syllable times are printed to check the mouth against them.
func _face_close()->void:
	_clear()
	DirAccess.make_dir_recursive_absolute(out_dir+"face")
	var f:=_person(1,"stand")
	f.position=Vector3.ZERO;f.rotation_degrees.y=-12.0
	var a=Acting.of(f)
	Acting.set_ambient(f,0.0)
	var head:int=f.skeleton.find_bone("head")
	_step_all(0.4)
	var h:Vector3=f.skeleton.global_transform*f.skeleton.get_bone_global_pose(head).origin
	camera.fov=18.0
	camera.position=h+Vector3(0.15,0.02,1.25);camera.look_at(h+Vector3(0.0,0.0,0.0),Vector3.UP)
	var line:="Two men and a boy at the ford, and you come to me only now?"
	var done:={}
	var frames:=int(9.0/DT)
	for k in frames:
		var t:=float(k)*DT
		if t>=0.4 and not done.has("speak"):
			done.speak=true
			Acting.speak(f,line,3.4,{"gestures":false})
			print("COURT_ACTING_CAPTURE syllables ",a._syl_t)
		if t>=4.2 and not done.has("gasp"):
			done.gasp=true;Acting.play(f,"gasp")
		if t>=6.0 and not done.has("laugh"):
			done.laugh=true;Acting.play(f,"laugh_polite")
		if t>=7.6 and not done.has("eye"):
			done.eye=true;Acting.play(f,"side_eye_l")
		_frame(f)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir+"face/frame_%04d.png" % k)
	print("COURT_ACTING_CAPTURE face frames ",frames)

func _sheets_r3()->void:
	camera.fov=26.0
	_frame_row(5.0)
	await _row("The rest of the director's words (1)",[
		{"clip":"cover_eyes_l","t":0.9,"label":"covers a child's eyes","who":5},{"clip":"make_room_r","t":0.8,"label":"makes room","who":1},
		{"clip":"grab_l","t":0.6,"label":"grabs","who":0},{"clip":"count_fingers","t":1.0,"label":"counts it off","who":2},
		{"clip":"point_r","t":0.7,"label":"points","who":6}],"r3_words_1.png",1.0)
	await _row("(2)",[
		{"clip":"point_up","t":0.9,"label":"points up at the god","who":4},{"clip":"raise_finger","t":0.6,"label":"ah, but","who":2},
		{"clip":"clap_soft","t":0.58,"label":"claps, softly","who":3},{"clip":"shoo_r","t":0.4,"label":"shoos the dog","who":5},
		{"clip":"tug_sleeve_l","t":0.45,"label":"tugs a sleeve","who":1}],"r3_words_2.png",1.0)
	await _row("(3)",[
		{"clip":"over_thank","t":0.4,"label":"thanks, and thanks","who":0},{"clip":"clear_throat","t":0.32,"label":"clears the throat","who":2},
		{"clip":"smooth_clothes","t":0.5,"label":"smooths the clothes","who":6},{"clip":"sit_floor","t":1.6,"label":"sits down","who":4},
		{"clip":"wave","t":0.5,"label":"waves at the god","who":3}],"r3_words_3.png",1.0)
	await _row("(4)",[
		{"clip":"mortified","t":0.6,"label":"mortified","who":1},{"clip":"count_heads","t":1.1,"label":"counts heads","who":2},
		{"clip":"thumb_measure","t":0.8,"label":"measures the hall","who":4},{"clip":"stroke_chin","t":0.8,"label":"appraises","who":6},
		{"clip":"fiddle","t":0.9,"label":"works a knot","who":5}],"r3_words_4.png",1.0)
	await _row("(5)",[
		{"clip":"arrange_floor","t":1.0,"label":"lines up the bowls","who":3},{"clip":"sniff_disdain","t":1.45,"label":"sniffs","who":6},
		{"clip":"brush_sleeve","t":0.42,"label":"brushes the sleeve","who":0},{"clip":"rub_hands_greedy","t":0.5,"label":"rubs the hands","who":2},
		{"clip":"scribble","t":0.9,"label":"scribbles","who":4}],"r3_words_5.png",1.0)
	await _row("Readable now at court distance",[
		{"clip":"rub_belly","t":0.9,"label":"stomach rumbles","who":4},{"clip":"stretch","t":1.2,"label":"stretch","who":0},
		{"clip":"fan_self","t":0.6,"label":"fans","who":1},{"clip":"wring_hands","t":0.7,"label":"wrings the hands","who":5},
		{"stance":"cord","t":1.6,"label":"cord","who":3}],"r3_readable.png",1.0)
	_frame_row(4.6)
	await _row("The catch under the arms; warming at the fire",[
		{"clip":"faint_caught_l","t":0.65,"label":"0.65 s","who":1,"x":-1.6,"yaw":0.0},{"clip":"half_catch_r","t":0.65,"label":"","who":0,"x":-0.85,"yaw":0.0},
		{"clip":"faint_caught_l","t":1.1,"label":"1.1 s","who":1,"x":0.25,"yaw":0.0},{"clip":"half_catch_r","t":1.1,"label":"","who":0,"x":1.0,"yaw":0.0},
		{"stance":"fire","t":2.0,"label":"by the fire","who":4,"x":2.0,"yaw":-20.0}],"r3_catch_fire.png")

# --- executions: a timing test of each act on the test stage ----------------------------
# Stand-in props, head and blood (M and J make the real ones); the plan, the
# clips, the held props and the cues are the real ones (court_acting.gd).
# Frames to exec_<act>/frame_####.png at 30 a second.

var _bits:Array[Node]=[]

func _mat(col:Color,glow:=0.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=col;m.roughness=0.9
	if glow>0.0:
		m.emission_enabled=true;m.emission=col;m.emission_energy_multiplier=glow
	return m

func _bit(mesh:Mesh,col:Color,at:=Vector3.ZERO)->MeshInstance3D:
	var m:=MeshInstance3D.new();m.mesh=mesh;m.material_override=_mat(col);m.position=at
	world.add_child(m);_bits.append(m)
	return m

func _cyl(r:float,h:float)->CylinderMesh:
	var c:=CylinderMesh.new();c.top_radius=r;c.bottom_radius=r;c.height=h
	return c

## A held stand-in: origin at the grip, +Y along the handle, +Z the blade.
func _held(kind:String)->Node3D:
	var root:=Node3D.new();world.add_child(root);_bits.append(root)
	var wood:=Color("6b4a2e")
	match kind:
		"club":
			var h:=MeshInstance3D.new();h.mesh=_cyl(0.022,0.74);h.position=Vector3(0,0.25,0);h.material_override=_mat(wood);root.add_child(h)
			var s:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=0.075;sm.height=0.24;s.mesh=sm;s.position=Vector3(0,0.72,0);s.material_override=_mat(wood);root.add_child(s)
		"axe":
			var h:=MeshInstance3D.new();h.mesh=_cyl(0.02,0.84);h.position=Vector3(0,0.34,0);h.material_override=_mat(wood);root.add_child(h)
			var b:=MeshInstance3D.new();var bm:=BoxMesh.new();bm.size=Vector3(0.03,0.15,0.16);b.mesh=bm;b.position=Vector3(0,0.66,0.07);b.material_override=_mat(Color("8a8f96"));root.add_child(b)
		"ladle":
			var h:=MeshInstance3D.new();h.mesh=_cyl(0.012,0.47);h.position=Vector3(0,0.185,0);h.material_override=_mat(wood);root.add_child(h)
			var s:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=0.055;sm.height=0.11;s.mesh=sm;s.position=Vector3(0,0.47,0);s.material_override=_mat(wood);root.add_child(s)
		"lid":
			var d:=MeshInstance3D.new();d.mesh=_cyl(0.20,0.02);d.position=Vector3(0,0.05,0);d.material_override=_mat(Color("8a6a4a"));root.add_child(d)
			var k:=MeshInstance3D.new();k.mesh=_cyl(0.02,0.06);k.material_override=_mat(Color("8a6a4a"));root.add_child(k)
	return root

## A stand-in dog: a body, a head, ears and a tail, +Z its nose.
func _stand_in_dog()->Node3D:
	var root:=Node3D.new();world.add_child(root);_bits.append(root)
	var fur:=Color("6d4f33")
	var body:=MeshInstance3D.new();var cm:=CapsuleMesh.new();cm.radius=0.13;cm.height=0.72;body.mesh=cm
	body.rotation_degrees=Vector3(90,0,0);body.position=Vector3(0,0.36,0);body.material_override=_mat(fur);root.add_child(body)
	var head:=MeshInstance3D.new();var hm:=SphereMesh.new();hm.radius=0.11;hm.height=0.2;head.mesh=hm;head.position=Vector3(0,0.46,0.40);head.material_override=_mat(fur);root.add_child(head)
	var snout:=MeshInstance3D.new();var sn:=BoxMesh.new();sn.size=Vector3(0.08,0.07,0.12);snout.mesh=sn;snout.position=Vector3(0,0.42,0.52);snout.material_override=_mat(fur.darkened(0.3));root.add_child(snout)
	for x in [-1.0,1.0]:
		var leg:=MeshInstance3D.new();leg.mesh=_cyl(0.035,0.3);leg.position=Vector3(0.08*x,0.15,0.22);leg.material_override=_mat(fur);root.add_child(leg)
		var leg2:=MeshInstance3D.new();leg2.mesh=_cyl(0.035,0.3);leg2.position=Vector3(0.08*x,0.15,-0.22);leg2.material_override=_mat(fur);root.add_child(leg2)
	var tail:=MeshInstance3D.new();tail.mesh=_cyl(0.02,0.25);tail.rotation_degrees=Vector3(-50,0,0);tail.position=Vector3(0,0.48,-0.42);tail.material_override=_mat(fur);root.add_child(tail)
	return root

## A stand-in head: a skin ball with a cap of hair and two dark eyes, +Z its face.
func _stand_in_head(f:Node3D)->Node3D:
	var root:=Node3D.new();world.add_child(root);_bits.append(root)
	var skin:=Color("9f6a43")
	var b:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=0.10;sm.height=0.24;b.mesh=sm;b.material_override=_mat(skin);root.add_child(b)
	var hair:=MeshInstance3D.new();var hm:=SphereMesh.new();hm.radius=0.105;hm.height=0.16;hm.is_hemisphere=true;hair.mesh=hm;hair.position=Vector3(0,0.03,-0.01);hair.material_override=_mat(Color("1b1511"));root.add_child(hair)
	for x in [-0.035,0.035]:
		var e:=MeshInstance3D.new();var em:=SphereMesh.new();em.radius=0.014;em.height=0.028;e.mesh=em;e.position=Vector3(x,0.01,0.09);e.material_override=_mat(Color("120c08"));root.add_child(e)
	var red:=MeshInstance3D.new();red.mesh=_cyl(0.05,0.01);red.position=Vector3(0,-0.11,0);red.material_override=_mat(Color("b0141a"),0.3);root.add_child(red)
	return root

## Stand-in blood: a burst (spray) or a fountain (geyser) of red drops.
func _blood(at:Vector3,dir:Vector3,kind:String)->void:
	var p:=CPUParticles3D.new()
	world.add_child(p);_bits.append(p)
	p.position=at
	var drop:=SphereMesh.new();drop.radius=0.022;drop.height=0.044
	p.mesh=drop;p.material_override=_mat(Color("c0141c"),0.25)
	p.direction=dir.normalized() if dir.length()>0.01 else Vector3.UP
	p.gravity=Vector3(0,-9.8,0)
	p.lifetime=1.4
	p.local_coords=false
	if kind=="geyser":
		p.amount=260;p.explosiveness=0.0;p.spread=14.0;p.initial_velocity_min=4.5;p.initial_velocity_max=6.0
		p.one_shot=true
	else:
		p.amount=90;p.explosiveness=0.95;p.spread=35.0;p.initial_velocity_min=2.5;p.initial_velocity_max=4.5;p.one_shot=true
	p.scale_amount_min=0.6;p.scale_amount_max=1.6
	p.emitting=true

func _clear_bits()->void:
	for b in _bits:
		if is_instance_valid(b):b.queue_free()
	_bits.clear()

func _exec_all()->void:
	for act in ["club_home_run","three_swing_beheading","dog_dinner"]:
		await _exec(act)

func _exec(act:String)->void:
	_clear();_clear_bits()
	var plan:=Acting.exec_plan(act)
	var dir:="exec_"+act
	DirAccess.make_dir_recursive_absolute(out_dir+dir)
	var cast:={}
	var who:={"victim":0,"executioner":4,"cook":2}
	for role:String in plan.roles:
		var r:Dictionary=plan.roles[role]
		var f:=_person(int(who.get(role,1)),"stand")
		var at:Array=r.get("at",[0,0,0])
		f.position=Vector3(float(at[0]),float(at[1]),float(at[2]));f.rotation_degrees.y=float(r.get("yaw",0.0))
		cast[role]=f
		for side:String in (r.get("props",{}) as Dictionary):
			var prop:=_held(String(r.props[side]))
			Acting.hold(f,prop,side)
			if String(r.props[side])=="lid":
				var rest:Array=r.get("lid_rests",[0.30,0.62,0.28])
				prop.global_transform=Transform3D(Basis(Vector3.RIGHT,PI),f.to_global(Vector3(float(rest[0]),float(rest[1]),float(rest[2]))))
	# the room: a front row at the sides, a child among them
	var row:=[[-1.6,0.0,1.1,110.0,1],[-2.2,0.0,1.7,120.0,7],[1.6,0.0,1.3,-120.0,5],[2.1,0.0,0.5,-100.0,6],[-1.0,0.0,2.1,150.0,3]]
	if act=="club_home_run":row=[[-2.0,0.0,1.4,110.0,1],[-2.2,0.0,2.2,120.0,7],[1.6,0.0,1.4,-120.0,5],[2.2,0.0,0.4,-100.0,6],[-1.3,0.0,2.5,150.0,3]]
	var room:=[]
	for p in row:
		var f:=_person(int(p[4]),"")
		f.position=Vector3(float(p[0]),0.0,float(p[2]));f.rotation_degrees.y=float(p[3])
		Acting.look_toward(f,cast.victim,1.0)
		room.append(f)
	var things:Dictionary=plan.get("things",{})
	if things.has("block"):
		var bm:=BoxMesh.new();bm.size=Vector3(0.40,float(things.block.top),0.40)
		_bit(bm,Color("7a5a3a"),Vector3(float(things.block.at[0]),float(things.block.top)*0.5,float(things.block.at[2])))
	if things.has("pot"):
		_bit(_cyl(0.26,0.55),Color("4a2f22"),Vector3(float(things.pot.at[0]),0.275,float(things.pot.at[2])))
	var wall_at:=-1.6
	var dogs:=[]
	var bone:MeshInstance3D=null
	if act=="dog_dinner":
		var wb:=BoxMesh.new();wb.size=Vector3(3.2,1.5,0.06)
		_bit(wb,Color("9a7b55"),Vector3(0.0,0.75,wall_at))
		for i in 2:dogs.append(_stand_in_dog())
		bone=_bit(_cyl(0.025,0.42),Color("efe6d2"))
		bone.visible=false
	# the camera: the god's view
	var cam:Dictionary=plan.get("camera",{"from":[0.0,2.0,6.4],"at":[0.0,0.7,-0.2]})
	camera.fov=36.0
	camera.position=Vector3(float(cam.from[0]),float(cam.from[1]),float(cam.from[2]))
	camera.look_at(Vector3(float(cam.at[0]),float(cam.at[1]),float(cam.at[2])))
	var god:=camera.global_position
	# the victim's beats: the split, the blood
	var victim:Node3D=cast.victim
	var va=Acting.of(victim)
	var state:={"split":-1.0,"head":null,"part":{}}
	var on_cue:=func(_f:Node3D,e:Dictionary)->void:
		var nm:=String(e.name)
		var neck:Vector3=victim.skeleton.global_transform*victim.skeleton.get_bone_global_pose(victim.skeleton.find_bone("neck")).origin
		if nm=="split":
			state.split=1.0
			var h:=_stand_in_head(victim)
			h.global_position=neck+Vector3(0,0.12,0)
			state.head=h
			state.from=neck+Vector3(0,0.12,0)
		elif nm=="spray" or nm=="geyser":
			var d:Array=e.get("dir",[0,1,0])
			_blood(neck,victim.global_transform.basis*Vector3(float(d[0]),float(d[1]),float(d[2])),nm)
	va.cue.connect(on_cue)
	# play
	var t:=0.0
	var clips_at:={}
	for role:String in plan.roles:
		var r:Dictionary=plan.roles[role]
		if r.has("clip"):Acting.play(cast[role],String(r.clip),{"blend":0.3})
	var parts:Array=plan.get("parts",[])
	var cues:Array=plan.get("cues",[])
	var cue_i:=0
	var frames:=int((float(plan.length)+0.8)/DT)
	var head_b:int=victim.skeleton.find_bone("head")
	var seq:Array=(plan.roles.victim as Dictionary).get("clips",[])
	var seq_i:=0
	var moving:=Vector3.ZERO
	var labels_made:=false
	for k in frames:
		t=float(k)*DT
		# the victim's run of clips (the dogs)
		while seq_i<seq.size() and float(seq[seq_i].t)<=t+0.0001:
			var c:Dictionary=seq[seq_i]
			Acting.play(victim,String(c.clip),{"blend":0.12 if seq_i>0 else 0.05})
			var mv:Array=c.get("move",[0,0,0])
			moving=Vector3(float(mv[0]),float(mv[1]),float(mv[2]))
			state.until=float(c.get("until",1e9))
			seq_i+=1
		if moving!=Vector3.ZERO and t<float(state.get("until",1e9)):victim.position+=moving*DT
		# stand-in dogs at the ankles, out of sight, then one back with a bone
		for i in dogs.size():
			var d:Node3D=dogs[i]
			if t<6.6:
				var feet:=0.52*clampf((t-0.1)/0.5,0.0,1.0)
				d.position=victim.position+Vector3(0.13 if i==0 else -0.13,0.0,-feet-0.62)
				d.rotation_degrees=Vector3(-6.0,8.0*sin(t*14.0+float(i)*1.7),0.0)
			elif i==0 and t>=9.0:
				var path:=[d.get_meta(&"from",d.position),Vector3(1.9,0.0,-1.4),Vector3(1.2,0.0,0.6),Vector3(0.0,0.0,1.45)]
				if not d.has_meta(&"from"):d.set_meta(&"from",d.position)
				var u:=clampf((t-9.0)/1.6,0.0,1.0)*3.0
				var seg:=mini(int(u),2)
				var a:Vector3=path[seg];var b:Vector3=path[seg+1]
				d.position=a.lerp(b,u-float(seg))
				if u<3.0:d.look_at(d.position+(a-b),Vector3.UP)
				else:d.rotation_degrees=Vector3(0.0,0.0+10.0*sin(t*18.0),0.0)
				bone.visible=true
				if t<10.6:bone.global_transform=Transform3D(Basis(Vector3.FORWARD,PI*0.5),d.to_global(Vector3(0.0,0.28,0.48)))
				else:bone.global_transform=Transform3D(Basis(Vector3.FORWARD,PI*0.5),Vector3(0.0,0.03,1.62))
		# the room on its cues
		while cue_i<cues.size() and float(cues[cue_i].t)<=t+0.0001:
			var cue:=String(cues[cue_i].cue)
			match cue:
				"impact","clang","thunk":
					Acting.play(room[0],"room_flinch_splash" if cue=="impact" else "flinch")
					if cue=="impact":
						Acting.play(room[2],"faint_r");Acting.play(room[1],"room_cover_eyes_peek")
				"splash":
					Acting.play(room[0],"room_wipe_face")
				"plop":
					var pot_at:=Vector3(float(plan.things.pot.at[0]),0.6,float(plan.things.pot.at[2]))
					for f in room:Acting.look_toward(f,pot_at,1.0)
				"crunch":
					for i in [0,2,3]:Acting.play(room[i],"room_wince_crunch")
				"grab":
					Acting.play(room[3],"gasp")
				"bone_dropped":
					for f in room:Acting.look_toward(f,Vector3(0,0.0,1.6),1.0)
				"after":
					Acting.play(room[3],"room_applaud_alone");Acting.play(room[4],"room_vomit")
					if act!="dog_dinner":Acting.play(room[0],"room_wipe_face")
					Acting.perform(room[1],{"beat":"cover_eyes_peek"})
			cue_i+=1
		for role:String in cast:_frame(cast[role])
		for f in room:_frame(f)
		# the head gone from the body; the stand-in where the plan sends it
		if float(state.split)>0.0:
			victim.skeleton.set_bone_pose_scale(head_b,Vector3.ONE*0.001)
			var h:Node3D=state.head
			for part:Dictionary in parts:
				if t<float(part.t0):continue
				var to:Vector3
				var target:Variant=part.get("to","pot")
				if target is Array:to=Vector3(float(target[0]),float(target[1])+0.11,float(target[2]))
				else:to=Vector3(float(plan.things.pot.at[0]),0.62,float(plan.things.pot.at[2]))
				h.global_transform=Acting.part_at(part,state.from,to,t,(god-to)*Vector3(1,0,1))
				if String(part.get("then",""))=="in_pot" and t>=float(part.t1):
					h.visible=false
					if not state.has("splash"):
						state.splash=true;_blood(to,Vector3.UP,"spray")
		if not labels_made:
			labels_made=true
			_title("%s  (timing test: stand-in props, head and blood; the real ones are J's and M's)" % act.replace("_"," "))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir+dir+"/frame_%04d.png" % k)
	print("COURT_ACTING_CAPTURE exec ",act," frames ",frames)
	_clear_bits()

## Round 4: the child (J's child body) beside grown-ups, the floor seat, the mirrored twins.
func _sheets_r4()->void:
	camera.fov=26.0
	_frame_row(5.0)
	await _row("A child at court: hides behind a grown-up, peeks out, copies the bow, waves at the god",[
		{"clip":"","t":0.6,"label":"","who":0,"x":-1.75,"z":0.0,"yaw":0.0},
		{"clip":"hide_behind_l","t":0.9,"label":"hides","who":7,"x":-2.0,"z":-0.38,"yaw":0.0},
		{"clip":"","t":0.6,"label":"","who":2,"x":-0.35,"z":0.0,"yaw":0.0},
		{"clip":"peek_out_l","t":0.75,"label":"peeks out","who":7,"x":-0.6,"z":-0.38,"yaw":0.0},
		{"clip":"bow_deep","t":1.1,"label":"","who":1,"x":0.75,"z":0.0,"yaw":0.0},
		{"clip":"copy","t":1.2,"label":"copies the bow","who":7,"x":1.35,"z":0.05,"yaw":0.0},
		{"clip":"wave","t":0.75,"label":"waves at the god","who":7,"x":2.2,"z":0.1,"yaw":0.0}],"r4_child_1.png")
	await _row("Giggles; shushed and frozen; clings to its mother; sits cross-legged",[
		{"clip":"giggle","t":0.7,"label":"giggles","who":7,"x":-2.2,"z":0.1,"yaw":0.0},
		{"clip":"shush_r","t":0.6,"label":"","who":5,"x":-0.95,"z":0.0,"yaw":-10.0},
		{"clip":"shushed","t":0.9,"label":"shushed","who":7,"x":-1.55,"z":0.15,"yaw":15.0},
		{"clip":"","t":0.6,"label":"","who":1,"x":0.15,"z":0.0,"yaw":0.0},
		{"clip":"child_cling_r","t":0.9,"label":"clings","who":7,"x":0.45,"z":0.06,"yaw":0.0},
		{"clip":"sit_cross","t":1.6,"label":"sits cross-legged","who":7,"x":1.35,"z":0.2,"yaw":0.0},
		{"stance":"cross","t":2.0,"label":"and an elder too","who":2,"x":2.2,"z":0.0,"yaw":-10.0}],"r4_child_2.png")
	_frame_row(4.6)
	await _row("Right-hand twins made from their left ones in a mirror (the file keeps only the left)",[
		{"clip":"hide_behind_l","t":0.9,"label":"hide behind, left","who":3},{"clip":"hide_behind_r","t":0.9,"label":"right (mirrored)","who":3},
		{"clip":"point_l","t":0.7,"label":"point, left","who":6},{"clip":"point_r","t":0.7,"label":"right (mirrored)","who":6},
		{"clip":"whisper_r","t":0.8,"label":"whisper, right (mirrored)","who":1}],"r4_mirrors.png",0.95)

## The mouth's morphs by hand (no acting): rest, jaw_open, v_aa, v_oo, smile.
func _mouth_test()->void:
	_clear()
	var f:=_person(1,"stand")
	f.position=Vector3.ZERO;f.rotation_degrees.y=0.0
	_step_all(0.3)
	var a=Acting.of(f);a.active=false
	var head:int=f.skeleton.find_bone("head")
	var h:Vector3=f.skeleton.global_transform*f.skeleton.get_bone_global_pose(head).origin
	camera.fov=12.0
	camera.position=h+Vector3(0.0,-0.02,1.2);camera.look_at(h+Vector3(0.0,-0.03,0.0),Vector3.UP)
	for state in ["rest","jaw_open","v_aa","v_oo","smile"]:
		for m in f._meshes:
			if not m.visible or m.mesh==null:continue
			for i in m.get_blend_shape_count():
				var nm:String=String(m.mesh.get_blend_shape_name(i))
				if nm in ["jaw_open","v_aa","v_oo","smile","v_ee","v_mm","v_fv"]:m.set_blend_shape_value(i,1.0 if nm==state else 0.0)
		var listed:=PackedStringArray()
		for m in f._meshes:
			if m.visible and m.mesh!=null:
				var idx:int=m.find_blend_shape_by_name(StringName(state))
				listed.append("%s:%s=%s" % [m.name,idx,m.get_blend_shape_value(idx) if idx>=0 else -1])
		print("COURT_ACTING_CAPTURE mouth ",state," ",listed)
		await _shot("mouth_%s.png" % state)

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
