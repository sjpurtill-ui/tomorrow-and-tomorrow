extends Node
## What the acting costs (K): eight court figures in the game's renderer,
## measured in four phases of 240 frames each (after 60 to settle):
##   none    the figures only (their AnimationPlayer; no acting bound)
##   idle    acting bound: breath, blinks, glances, moods
##   busy    acting with a reaction or speech on everyone
##   off     acting bound but switched off (active = false)
## For each: the frame's time (microseconds, vsync off), the process time,
## the acting's own time per figure, the blend-shape writes per frame and the
## viewport's measured render CPU / GPU time. Windowed only (private desktop):
##   powershell -File tools/run_isolated_gpu_probe.ps1 ... -Scene res://tools/court_acting_profile.tscn
## Prints COURT_ACTING_PROFILE lines.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const N:=8
const WARM:=60
const FRAMES:=240
const LOOKS:=[
	["male_adult","hide","long","beard_full","7d4e2f","1b1511","stand"],
	["female_adult","tunic","braids","","d6a37c","4a2a1a","hip"],
	["male_old","robe","cropped","beard_long","9f6a43","a8a49c","clasped"],
	["female_young","tunic","curls","","5b3622","0f0d0c","stand"],
	["male_young","tunic","tail","","e8c3a5","2a1c12","belt"],
	["female_old","hide","bun","","bd8659","b5b0a6","clasped"],
	["male_adult","tunic","topknot","beard_short","bd8659","3a2a1c","folded"],
	["child","tunic","cropped","","c98d62","3a2a1c","stand"],
]

var figures:Array[Node3D]=[]
var times:=PackedInt64Array()
var last:=0
var world:Node3D

func _ready()->void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	get_window().size=Vector2i(1536,864)
	world=Node3D.new();add_child(world)
	var env:=WorldEnvironment.new();var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR;e.background_color=Color("2b2118")
	env.environment=e;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-28,0);world.add_child(sun)
	var cam:=Camera3D.new();cam.fov=30.0;cam.position=Vector3(0,1.6,8.0);cam.rotation_degrees=Vector3(-6,0,0);world.add_child(cam);cam.current=true
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	await _phase("none",false,false)
	for f in figures:Acting.of(f)
	await _phase("idle",true,false)
	await _phase("busy",true,true)
	# a push-in: the same eight, near (faces large: everything drives)
	cam=get_viewport().get_camera_3d()
	cam.position=Vector3(0,1.55,3.2);cam.fov=34.0
	await _phase("busy_near",true,true)
	cam.position=Vector3(0,1.6,8.0);cam.fov=30.0
	for f in figures:(Acting.of(f) as SkeletonModifier3D).active=false
	await _phase("off",true,false)
	# every expression and viseme back to 0; each person's own face shapes stay
	_zero_morphs(false)
	await _phase("off_faces_only",true,false)
	# and the face shapes too: what the always-on face morphs cost
	_zero_morphs(true)
	await _phase("no_morphs",true,false)
	get_tree().quit(0)

func _zero_morphs(faces_too:bool)->void:
	var active:=0
	for f in figures:
		for m in f._meshes:
			if m.mesh==null:continue
			for i in m.get_blend_shape_count():
				var nm:=String(m.mesh.get_blend_shape_name(i))
				if nm.begins_with("face_") and not faces_too:
					if m.visible and absf(m.get_blend_shape_value(i))>0.0:active+=1
					continue
				m.set_blend_shape_value(i,0.0)
	print("COURT_ACTING_PROFILE nonzero face shapes on visible meshes: ",active)

func _make()->void:
	for f in figures:f.queue_free()
	figures.clear()
	await get_tree().process_frame
	for i in N:
		var p:Array=LOOKS[i]
		var f:Node3D=Figure3D.new()
		f.set_meta(&"person_name","profile %d" % i)
		world.add_child(f)
		f.setup({"variant":p[0],"outfit":p[1],"hair":p[2],"beard":p[3],"skin":Color(String(p[4])),"hair_colour":Color(String(p[5])),"stance":p[6]})
		f.position=Vector3((float(i)-3.5)*0.95,0.0,0.0)
		f.play(f.rest_clip(),0.0,float(i)*0.6)
		figures.append(f)

func _phase(name:String,acting:bool,busy:bool)->void:
	if name=="none":await _make()
	var clips:=["gasp","laugh","talk_explain","wring_hands","clap_soft","kneel","side_eye_l","stretch"]
	for i in WARM:await get_tree().process_frame
	times.clear()
	Acting.prof_usec=0;Acting.prof_steps=0;Acting.prof_morph_writes=0
	var proc:=0.0
	var rcpu:=0.0
	var rgpu:=0.0
	last=Time.get_ticks_usec()
	for i in FRAMES:
		if busy and i%45==0:
			for j in figures.size():
				var f:=figures[j]
				if j%2==0:Acting.play(f,String(clips[(j+i/45)%clips.size()]))
				else:Acting.speak(f,"Two men and a boy at the ford, and you come to me only now?",1.4,{"gestures":true})
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		times.append(now-last);last=now
		proc+=Performance.get_monitor(Performance.TIME_PROCESS)
		var vp:=get_viewport().get_viewport_rid()
		rcpu+=RenderingServer.viewport_get_measured_render_time_cpu(vp)
		rgpu+=RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var total:=0
	for t in times:total+=t
	var frame_us:=float(total)/float(FRAMES)
	var act_us:=float(Acting.prof_usec)/float(maxi(Acting.prof_steps,1))
	print("COURT_ACTING_PROFILE %s frame=%.0fus process=%.2fms acting_per_figure=%.0fus acting_all=%.2fms morph_writes_per_frame=%.1f render_cpu=%.2fms render_gpu=%.2fms" % [
		name,frame_us,proc/float(FRAMES)*1000.0,act_us,float(Acting.prof_usec)/float(FRAMES)/1000.0,float(Acting.prof_morph_writes)/float(FRAMES),rcpu/float(FRAMES),rgpu/float(FRAMES)])
