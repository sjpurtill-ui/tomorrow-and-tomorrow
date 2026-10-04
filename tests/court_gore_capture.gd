extends Node
## What the court's executions make of a person (figures, J), on two people
## of different peoples, in the fire circle: alive, beheaded (the head on the
## floor), quartered, sawn in half, a skeleton, charred, pressed flat, bronze,
## and the loose head with its eyes open and blinking. Windowed, on a private
## desktop (tools/run_isolated_gpu_probe.ps1). Writes
## reports/court_figures/gore_sheet.png. Presentation only.

const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Gore:=preload("res://scripts/hud/court_figure_gore.gd")
const Looks:=preload("res://scripts/people_appearance.gd")

const TILE:=Vector2i(640,420)
const VARIANTS:=["alive","beheaded","quartered","sawn","skeleton","charred","rug","bronze","head"]

var failures:Array[String]=[]
var court:Node3D
var cam:Camera3D
var owners:={}

func _ready()->void:
	var capture:=DisplayServer.get_name()!="headless"
	if capture:get_window().size=Vector2i(1536,864)
	await _frames(2)
	for i in 4000:
		var owner:="civ_face_%d" % i
		var family:=String(Looks.profile(owner,4242).get("family",""))
		if family in ["kilnfold","thornbank"] and not owners.has(family):owners[family]=owner
		if owners.size()==2:break
	var view:=SubViewport.new();view.size=TILE;view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	court=CourtSet.build("hearth_council",{"food":0.7,"tier":0,"dogs":false})
	view.add_child(court)
	await _frames(2)
	Figure3D.set_key_light(court.call("key_dir"))
	cam=court.get("camera")
	var sheet:=Image.create(TILE.x*3,TILE.y*3,false,Image.FORMAT_RGBA8)
	for v in VARIANTS.size():
		var name:String=VARIANTS[v]
		var a:=_person("kilnfold","male",34,"Odu Kiln",Vector3(-0.55,0,2.0))
		var b:=_person("thornbank","female",29,"Sela Thorn",Vector3(0.55,0,2.0))
		await _frames(4)
		var extra:=[]
		for fig in [a,b]:extra.append_array(await _make(fig,name))
		var close:=name=="head"
		var pts:=PackedVector3Array([Vector3(-1.25,0.0,2.0),Vector3(1.25,0.0,2.0),Vector3(-1.25,1.85,2.0),Vector3(1.25,1.85,2.0)]) if not close else PackedVector3Array([Vector3(-0.95,0.0,2.3),Vector3(0.95,0.0,2.3),Vector3(-0.95,0.5,2.3),Vector3(0.95,0.5,2.3)])
		cam.call("frame_points",pts,8.0,-14.0 if not close else -22.0)
		for i in 10:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shot:=view.get_texture().get_image();shot.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(shot,Rect2i(Vector2i.ZERO,TILE),Vector2i((v%3)*TILE.x,(v/3)*TILE.y))
		print("GORE ",name," pieces ",extra.size())
		for node in [a,b]+extra:
			if is_instance_valid(node):(node as Node).queue_free()
		await _frames(2)
	if capture:
		var dir:=ProjectSettings.globalize_path("res://reports/court_figures/")
		DirAccess.make_dir_recursive_absolute(dir)
		sheet.save_png(dir+"gore_sheet.png")
		print("CAPTURE ",dir+"gore_sheet.png")
	# a child never comes apart
	var child:=Figure3D.new();court.add_child(child)
	child.setup({"variant":"child","outfit":"hide","hair":"cropped","stance":"stand","lit":true,"years":8})
	if not Gore.split(child,"head").is_empty():failures.append("a child came apart")
	if Gore.bones(child)!=null:failures.append("a child became bones")
	child.queue_free()
	if failures.is_empty():
		print("COURT_GORE PASS");get_tree().quit(0)
	else:
		for f in failures:printerr("COURT_GORE FAIL: ",f)
		get_tree().quit(1)

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

func _person(people:String,sex:String,age:int,name:String,at:Vector3)->Node3D:
	var fig:=Figure3D.new();court.add_child(fig)
	var person:={"name":name,"person_id":9700+absi(name.hash())%100,"sex":sex,"age":age,"appearance_civ_id":String(owners.get(people,"player")),"appearance_world_seed":4242}
	var look:Dictionary=Stage.figure_look(person,{}).duplicate()
	look["years"]=age;look["lit"]=true;look["stance"]="stand";look["keep_stance"]=true
	fig.setup(look)
	fig.position=at
	fig.play("stand",0.0,0.4)
	fig.set_light(1.0)
	fig.call("gore_prepare")
	return fig

## Makes the variant on one person; returns any new pieces.
func _make(fig:Node3D,name:String)->Array:
	var made:=[]
	var at:=fig.global_position
	match name:
		"beheaded","head":
			var pieces:Dictionary=fig.call("gore_split","head")
			var head:Node3D=pieces.get("head")
			if head==null:failures.append("no head");return made
			head.global_position=at+Vector3(0.30,0.10,0.25)
			head.rotation=Vector3(0.0,0.0,deg_to_rad(80.0))
			if name=="head":
				var body:Node3D=pieces.get("torso_limbs")
				if body!=null:body.visible=false
				head.global_position=at+Vector3(0.0,0.10,0.55)
				head.rotation=Vector3(deg_to_rad(-8.0),0.0,deg_to_rad(80.0))
				# the one on the right has shut its eyes in a blink
				if at.x>0.0:
					for node in head.find_children("*","MeshInstance3D",true,false):
						var mi:=node as MeshInstance3D
						var i:=mi.find_blend_shape_by_name(&"blink")
						if i>=0:mi.set_blend_shape_value(i,1.0)
				else:head.call("look","up")
			made.append_array(pieces.values())
		"quartered":
			var pieces:Dictionary=fig.call("gore_split","all")
			var push:={"arm.L":Vector3(0.45,-0.55,0.15),"arm.R":Vector3(-0.45,-0.55,0.15),"leg.L":Vector3(0.30,-0.40,0.45),"leg.R":Vector3(-0.30,-0.40,0.45),"head":Vector3(0.0,-0.75,0.55),"torso":Vector3(0.0,-0.65,0.0)}
			var spin:={"arm.L":Vector3(0,0,1.4),"arm.R":Vector3(0,0,-1.4),"leg.L":Vector3(1.4,0,0.3),"leg.R":Vector3(1.4,0,-0.3),"head":Vector3(0,0,1.3),"torso":Vector3(-1.45,0,0)}
			for key in pieces:
				var p:Node3D=pieces[key]
				p.global_position+=push.get(key,Vector3.ZERO)
				p.rotation=spin.get(key,Vector3.ZERO)
			made.append_array(pieces.values())
		"sawn":
			var pieces:Dictionary=fig.call("gore_split","halves")
			for key in pieces:
				var p:Node3D=pieces[key]
				# falling apart, the cut sides turned to us
				var sd:=1.0 if key=="left" else -1.0
				p.global_position+=Vector3(sd*0.24,-0.03,0)
				p.rotation=Vector3(0.0,sd*0.95,sd*0.14)
				p.call("blink",1)
			made.append_array(pieces.values())
		"skeleton":
			Gore.bones(fig,true)
		"charred":
			Gore.char(fig,true)
		"rug":
			Gore.rug(fig,true)
		"bronze":
			fig.play("raise_hand",0.0,0.6)
			var body:=(fig.get("_merged") as Dictionary).get("Body") as MeshInstance3D
			if body!=null:
				for key in ["jaw_open","eyes_wide","brows_up"]:
					var i:=body.find_blend_shape_by_name(StringName(key))
					if i>=0:body.set_blend_shape_value(i,0.9)
			await _frames(3)
			Gore.bronze(fig,true)
	return made
