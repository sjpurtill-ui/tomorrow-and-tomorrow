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
