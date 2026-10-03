extends Node
## Phase 1 prototype captures of the modelled court figures standing in the
## court: the hall's own backdrop (court_backdrop.gd) behind one transparent
## SubViewport holding the 3D figures (scripts/hud/court_figure_3d.gd, made by
## tools/blender/court_figures.py), and the court stage's speech bubble
## (court_stage.gd Bubble) hung over the speaker's head as projected.
## Not wired into the Court yet: this only shows how the figures look there.
## Windowed only (tools/run_isolated_gpu_probe.ps1, on a private desktop); it
## writes res://reports/court_figures/godot_court_*.png (reports/ is ignored).
## Headless it checks that every figure loads, dresses and plays its clips.
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> -Scene res://tests/court_figures_capture.tscn -LogFile <log>

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")

const SKIN_RAMP:=[[0.0,"f3dccb"],[0.15,"e8c3a5"],[0.30,"d6a37c"],[0.45,"bd8659"],[0.60,"9f6a43"],[0.75,"7d4e2f"],[0.90,"5b3622"],[1.0,"3f2519"]]
const HIDE:=["9c7a52","6e5541"]

## Each scene: the court's stage and tier, and who stands where.
## person: [name, title, look, x, z, clip, at, yaw]
const SCENES:=[
	{"tag":"fire","tier":0,"stage":"hearth_council","speaker":0,
	 "words":"The watch is too thin. Varrow's men cross at the ford by night, and we see them only at dawn.",
	 "people":[
		["Zola Tall-Grass","Hearth Chief",{"variant":"male_adult","outfit":"hide","hair":"long","beard":"beard_full","depth":0.86,"hair_colour":"1b1511","cloth":["a8782a","6e5541","a8432f"]},-0.75,0.55,"talk",1.1,12.0],
		["Diru","Pathfinder",{"variant":"female_adult","outfit":"hide","hair":"braids","depth":0.30,"hair_colour":"4a2a1a","cloth":["b07a35","6e5541","8e2f3a"],"without":["hide_cape"]},1.15,-0.35,"listen_r",2.0,-22.0],
		["Old Tamsa","Keeper of Tales",{"variant":"female_old","outfit":"hide","hair":"bun","depth":0.60,"hair_colour":"b5b0a6","cloth":["9c7a52","5b4130","c9a43c"]},2.35,-0.9,"idle_clasped",1.6,-30.0],
		["Kel","Hunter",{"variant":"male_young","outfit":"hide","hair":"tail","depth":0.48,"hair_colour":"1d1813","cloth":["a8782a","6e5541","4f7a68"],"without":["hide_cape"]},-2.35,-0.75,"listen_l",3.1,28.0],
	]},
	{"tag":"hall","tier":2,"stage":"temple_palace","speaker":1,
	 "words":"Count the stores again before the moon is full, and let the scribes write what they find.",
	 "people":[
		["Ama Reedwake","Steward",{"variant":"female_adult","outfit":"robe","hair":"long_framed","depth":0.40,"hair_colour":"8a6a48","cloth":["d9ccb0","4f7a68","a8432f"]},-1.55,-0.4,"listen_r",0.7,24.0],
		["Hosk the Elder","High Speaker",{"variant":"male_old","outfit":"robe","hair":"cropped","beard":"beard_long","depth":0.52,"hair_colour":"a8a49c","cloth":["2f4a6e","8e2f3a","c9a43c"]},0.15,0.55,"raise_hand",1.2,0.0],
		["Neru","Scribe",{"variant":"male_young","outfit":"tunic","hair":"curls","depth":0.95,"hair_colour":"0f0d0c","cloth":["c9a43c","5b4130","2f4a6e"]},1.85,-0.55,"listen_l",1.9,-26.0],
		["Ilse","Keeper of Stores",{"variant":"female_young","outfit":"tunic","hair":"tail","depth":0.12,"hair_colour":"6a3320","cloth":["a8432f","5b4130","d9ccb0"]},-2.75,-1.0,"idle_clasped",2.6,30.0],
	]},
]

var capture:=false
var out_dir:=""
var failures:Array[String]=[]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_figures/")
	if capture:
		DirAccess.make_dir_recursive_absolute(out_dir)
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
	await _frames(2)
	if not Figure3D.available():
		_fail("no court figures under %s" % Figure3D.DIR)
	else:
		for spec:Dictionary in SCENES:await _scene(spec)
	if failures.is_empty():
		print("COURT_FIGURES_CAPTURE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("COURT_FIGURES_CAPTURE FAIL: ",failure)
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

func _look(raw:Dictionary)->Dictionary:
	var look:=raw.duplicate(true)
	look["skin"]=skin_at(float(raw.get("depth",0.5)))
	look["hair_colour"]=Color(String(raw.get("hair_colour","2b2018")))
	var cloth:Array=[]
	for c in raw.get("cloth",[]):cloth.append(Color(String(c)))
	if String(raw.get("outfit",""))=="hide":
		# hides are hides: the people's dye shows as a tint and in the cord
		cloth[0]=Color(HIDE[0]).lerp(cloth[0],0.30);cloth[1]=Color(HIDE[1])
	look["cloth"]=cloth
	return look

func _scene(spec:Dictionary)->void:
	var root:=Control.new();root.name="CourtFigures_"+String(spec.tag)
	add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.size=Vector2(1920,1080) if capture else Vector2(1280,720)
	var backdrop:=Backdrop.new();backdrop.name="Backdrop";backdrop.animate=false
	root.add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(int(spec.tier),false,String(spec.stage))
	var container:=SubViewportContainer.new();container.name="Figures";container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(container);container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view:=SubViewport.new();view.name="FigureView";view.transparent_bg=true;view.own_world_3d=true
	view.msaa_3d=Viewport.MSAA_4X;view.size=Vector2i(root.size)
	container.add_child(view)
	var camera:=Camera3D.new();camera.name="Camera";camera.fov=28.0
	view.add_child(camera)
	camera.position=Vector3(0.0,1.62,8.2);camera.look_at(Vector3(0.0,0.95,0.0))
	Figure3D.set_key_light(Vector3(-0.35,0.62,0.70))
	var figures:Array=[]
	for raw:Array in spec.people:
		var fig:=Figure3D.new();fig.name="Figure_"+String(raw[0]).replace(" ","_")
		view.add_child(fig)
		if not fig.setup(_look(raw[2] as Dictionary)):
			_fail("%s did not load" % raw[0]);continue
		fig.position=Vector3(float(raw[3]),0.0,float(raw[4]))
		fig.rotation_degrees.y=float(raw[7])
		for clip:String in ["idle","talk","listen_l","listen_r","bow","kneel","walk_in","raise_hand"]:
			if fig.player==null or not fig.player.has_animation(clip):_fail("%s has no clip %s" % [raw[0],clip])
		fig.play(String(raw[5]),0.0,float(raw[6]))
		view.add_child(_shadow(fig.position))
		figures.append([fig,raw])
	await _frames(3)
	if capture:
		# let the clips run a moment, then hold still for the picture
		await get_tree().create_timer(0.4).timeout
		for item:Array in figures:
			var fig:Node3D=item[0]
			if fig.player:fig.player.pause()
		await _frames(2)
	var plates:=Control.new();plates.name="Plates";plates.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(plates);plates.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for item:Array in figures:
		var fig:Node3D=item[0];var raw:Array=item[1]
		var foot:=camera.unproject_position(fig.global_position)
		plates.add_child(_plate(String(raw[0]),String(raw[1]),foot,item==figures[int(spec.speaker)]))
	var speaker:Node3D=(figures[int(spec.speaker)] as Array)[0]
	var head:=camera.unproject_position(speaker.head_top())
	var bubble:=Stage.Bubble.new();bubble.name="Speech";bubble.kind="speech"
	plates.add_child(bubble)
	bubble.setup(String(spec.words),HudTokens.voice_font(false),19,Stage.BUBBLE_INK,Stage.BUBBLE_PAPER,Stage.BUBBLE_RULE,440.0)
	var x:=clampf(head.x-bubble.size.x*.5,8.0,root.size.x-bubble.size.x-8.0)
	bubble.position=Vector2(x,head.y-Stage.TAIL-bubble.size.y-6.0)
	bubble.tail_side="down";bubble.tip=Vector2(head.x-x,bubble.size.y+Stage.TAIL)
	bubble.queue_redraw()
	if capture:
		await _frames(4)
		await RenderingServer.frame_post_draw
		var path:=out_dir+"godot_court_%s.png" % String(spec.tag)
		get_viewport().get_texture().get_image().save_png(path)
		print("COURT_FIGURES capture ",path)
	root.queue_free()
	await _frames(2)

func _shadow(at:Vector3)->MeshInstance3D:
	## A soft pool of shade under the feet: the figures stand on the floor.
	var quad:=QuadMesh.new();quad.size=Vector2(0.95,0.55)
	var shade:=ShaderMaterial.new();shade.shader=Shader.new()
	shade.shader.code="shader_type spatial;render_mode unshaded,blend_mix,depth_draw_never,cull_disabled;void fragment(){vec2 p=(UV-0.5)*2.0;float d=length(p);ALBEDO=vec3(0.16,0.11,0.07);ALPHA=0.42*(1.0-smoothstep(0.25,1.0,d));}"
	var made:=MeshInstance3D.new();made.mesh=quad;made.material_override=shade
	made.rotation_degrees.x=-90.0;made.position=at+Vector3(0.0,0.004,0.02)
	return made

func _plate(who:String,title:String,foot:Vector2,big:bool)->Control:
	var plate:=PanelContainer.new();plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new();style.bg_color=Stage.PLATE_BG;style.set_corner_radius_all(3)
	style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=3;style.content_margin_bottom=4
	plate.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);plate.add_child(box)
	var name_label:=HudTokens.make_label(who,16 if big else 13,Stage.CREAM)
	name_label.add_theme_font_override("font",HudTokens.font("ui_strong"));name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var title_label:=HudTokens.make_label(title,13 if big else 12,Stage.CREAM_DIM);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	plate.size=plate.get_combined_minimum_size()
	plate.position=(foot+Vector2(-plate.size.x*.5,10.0)).round()
	return plate
