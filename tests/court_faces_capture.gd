extends Node
## Faces for review (figures, J): eight men and eight women of three peoples
## and two children, head and shoulders, three-quarter, in the lit longhouse
## (M's set, court_set_3d.gd), each through the one accessor
## (CourtStage.figure_look) and then their own shade within their people
## (court_figure_look.gd); then one slow push-in's end on a face, the room
## behind. Windowed, on a private desktop (tools/run_isolated_gpu_probe.ps1).
## Writes reports/court_figures/faces_sheet.png (+ faces_sheet.json, the
## labels) and faces_pushin.png.

const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Looks:=preload("res://scripts/people_appearance.gd")

const TILE:=Vector2i(300,360)
const PEOPLES:=["kilnfold","thornbank","ochrestep"]
## [sex, age] for each people's men and women (three, three, two).
const MEN:=[["male",22],["male",36],["male",64],["male",27],["male",45],["male",58],["male",33],["male",70]]
const WOMEN:=[["female",19],["female",34],["female",61],["female",25],["female",47],["female",66],["female",29],["female",40]]
const NAMES:=["Aru","Bekka","Cosa","Dimo","Eshe","Faro","Gudi","Hana","Ilo","Jessa","Kopa","Lumi","Mavo","Nedi","Oska","Pera","Quen","Rimi"]

var failures:Array[String]=[]
var labels:Array=[]

func _ready()->void:
	var capture:=DisplayServer.get_name()!="headless"
	if capture:get_window().size=Vector2i(1536,864)
	await _frames(2)
	if not CourtSet.available() or not Figure3D.available():
		failures.append("set or figures missing")
	else:
		var owners:=_owners_for(PEOPLES)
		print("OWNERS ",owners)
		var sheet:=Image.create(TILE.x*9,TILE.y*2,false,Image.FORMAT_RGBA8)
		var people:=[]
		# row one: eight men and a child; row two: eight women and a child
		for row in 2:
			var list:Array=MEN if row==0 else WOMEN
			for i in 9:
				var spec:Dictionary
				if i<8:
					var p:int=[0,0,0,1,1,1,2,2][i]
					spec={"owner":owners[PEOPLES[p]],"people":PEOPLES[p],"sex":String(list[i][0]),"age":int(list[i][1]),"name":NAMES[(row*9+i)%NAMES.size()]+" "+PEOPLES[p].capitalize()}
				else:
					var p2:=1 if row==0 else 2
					spec={"owner":owners[PEOPLES[p2]],"people":PEOPLES[p2],"sex":"male" if row==0 else "female","age":8,"name":"Little "+NAMES[(row*9+i)%NAMES.size()]}
				spec["slot"]=Vector2i(i,row)
				people.append(spec)
		var view:=SubViewport.new();view.size=TILE;view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X
		view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		add_child(view)
		var court:Node3D=CourtSet.build("tier_1",{"food":0.7,"tier":1,"dogs":false})
		view.add_child(court)
		await _frames(2)
		Figure3D.set_key_light(court.call("key_dir"))
		var cam:Camera3D=court.get("camera")
		for spec:Dictionary in people:
			var fig:=Figure3D.new();fig.name="Sitter"
			court.add_child(fig)
			var person:={"name":String(spec.name),"person_id":9000+people.find(spec),"sex":String(spec.sex),"age":int(spec.age),
				"appearance_civ_id":String(spec.owner),"appearance_world_seed":4242}
			var look:Dictionary=Stage.figure_look(person,{}).duplicate()
			look["years"]=int(spec.age)
			look["lit"]=true
			look["stance"]="stand"
			look["keep_stance"]=true
			if not fig.setup(look):
				failures.append("no figure for %s" % spec.name);fig.queue_free();continue
			court.call("place",fig,"petitioner")
			fig.play("stand",0.0,0.6)
			fig.set_light(float(court.call("light_at",fig.global_position)))
			await _frames(3)
			var head:Vector3=fig.head_top()
			var front:=fig.global_transform.basis.z.normalized()
			var side:=fig.global_transform.basis.x.normalized()
			var tall:=float(fig.body_height)/1.72
			var pts:=PackedVector3Array([head+Vector3.UP*0.05*tall,head-Vector3.UP*0.44*tall,head-Vector3.UP*0.30*tall+side*0.22*tall,head-Vector3.UP*0.30*tall-side*0.22*tall])
			var yaw:=rad_to_deg(atan2(front.x,front.z))+28.0
			cam.call("frame_points",pts,yaw,-3.0)
			for i in 12:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var shot:=view.get_texture().get_image()
			shot.convert(Image.FORMAT_RGBA8)
			var slot:Vector2i=spec.slot
			sheet.blit_rect(shot,Rect2i(Vector2i.ZERO,TILE),Vector2i(slot.x*TILE.x,slot.y*TILE.y))
			var made:Dictionary=fig.look
			labels.append({"x":slot.x,"y":slot.y,"name":String(spec.name),"people":String(spec.people),"age":int(spec.age),
				"variant":String(made.get("variant","")),"hair":String(made.get("hair","")),"beard":String(made.get("beard","")),
				"hair_colour":Color(made.get("hair_colour",Color.BLACK)).to_html(false),"skin":Color(made.get("skin",Color.BLACK)).to_html(false),"build":String(made.get("build",""))})
			print("FACE ",labels[-1])
			fig.queue_free()
			await _frames(1)
		var dir:=ProjectSettings.globalize_path("res://reports/court_figures/")
		DirAccess.make_dir_recursive_absolute(dir)
		if capture:
			sheet.save_png(dir+"faces_sheet.png")
			var f:=FileAccess.open(dir+"faces_sheet.json",FileAccess.WRITE)
			if f!=null:f.store_string(JSON.stringify(labels,"  "))
		# One face at the end of a push-in, the hall around it.
		view.size=Vector2i(1536,864)
		var cast:=[["petitioner",{"name":"Tamo Ochre","sex":"male","age":38},"ochrestep"],["officials_0",{"name":"Wessa Kiln","sex":"female","age":52},"kilnfold"],
			["officials_1",{"name":"Rauk Thorn","sex":"male","age":29},"thornbank"],["officials_2",{"name":"Iba Ochre","sex":"female","age":63},"ochrestep"]]
		var main:Node3D=null
		for entry:Array in cast:
			var fig:=Figure3D.new();court.add_child(fig)
			var person:Dictionary=(entry[1] as Dictionary).duplicate();person["person_id"]=9500+cast.find(entry)
			person["appearance_civ_id"]=owners[String(entry[2])];person["appearance_world_seed"]=4242
			var look:Dictionary=Stage.figure_look(person,{}).duplicate()
			look["years"]=int(person.age);look["lit"]=true
			if String(entry[0])=="petitioner":look["stance"]="clasped";look["keep_stance"]=true
			fig.setup(look)
			court.call("place",fig,String(entry[0]))
			fig.play(fig.rest_clip(),0.0,0.3*float(cast.find(entry)))
			fig.set_light(float(court.call("light_at",fig.global_position)))
			if main==null:main=fig
			else:fig.look_at_point(main.head_top(),0.0)
		await _frames(3)
		main.look_at_point(court.call("god_point"),0.0)
		cam.call("set_insets",40.0,24.0)
		cam.call("push_in",main,0.0)
		for i in 20:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if capture:view.get_texture().get_image().save_png(dir+"faces_pushin.png")
		# chest up, and a true close-up of the face, three-quarter: a man of
		# the deepest people, a woman of the fairest, a man between
		var sitters:=[["kilnfold","male",38,"Odu Kiln"],["thornbank","female",31,"Sela Thorn"],["ochrestep","male",44,"Tamo Ochre"]]
		var row:=0
		for sitter:Array in sitters:
			var person:={"name":String(sitter[3]),"person_id":9600+row,"sex":String(sitter[1]),"age":int(sitter[2]),"appearance_civ_id":owners[String(sitter[0])],"appearance_world_seed":4242}
			var look:Dictionary=Stage.figure_look(person,{}).duplicate()
			look["years"]=int(sitter[2]);look["lit"]=true;look["stance"]="clasped";look["keep_stance"]=true
			main.setup(look)
			court.call("place",main,"petitioner")
			main.play(main.rest_clip(),0.0,0.5)
			main.set_light(float(court.call("light_at",main.global_position)))
			await _frames(3)
			main.look_at_point(court.call("god_point"),0.0)
			var head:Vector3=main.head_top()
			var front:=main.global_transform.basis.z.normalized()
			var side:=main.global_transform.basis.x.normalized()
			var yaw:=rad_to_deg(atan2(front.x,front.z))+24.0
			for shot in [["chestup",0.62,0.30],["closeup",0.27,0.13]]:
				var down:=float(shot[1]);var wide:=float(shot[2])
				cam.call("frame_points",PackedVector3Array([head+Vector3.UP*0.03,head-Vector3.UP*down,head-Vector3.UP*down*0.5+side*wide,head-Vector3.UP*down*0.5-side*wide]),yaw,-3.0)
				for i in 12:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				if capture:view.get_texture().get_image().save_png(dir+"faces_%s_%s.png" % [String(shot[0]),String(sitter[0])])
			row+=1
		print("CAPTURE ",dir+"faces_sheet.png")
	if failures.is_empty():
		print("COURT_FACES PASS");get_tree().quit(0)
	else:
		for f in failures:printerr("COURT_FACES FAIL: ",f)
		get_tree().quit(1)

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

## An owner whose people (for this world seed) is each of the wanted families.
func _owners_for(wanted:Array)->Dictionary:
	var out:={}
	for i in 4000:
		var owner:="civ_face_%d" % i
		var family:=String(Looks.profile(owner,4242).get("family",""))
		if family in wanted and not out.has(family):out[family]=owner
		if out.size()==wanted.size():break
	for family in wanted:
		if not out.has(family):
			failures.append("no owner of the %s people" % family);out[family]="player"
	return out
