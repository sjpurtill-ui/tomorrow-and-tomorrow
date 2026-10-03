extends Node
## An execution acted out in the modelled court (L): the director's "exec"
## beats (court_director.gd _execution) played on the stage's people, the set
## and a few things brought in for it. Presentation only: the engine has put
## the person to death; this shows how. Until the figures (J), the acting (K),
## the set (M) and the sound (N) bring their own pieces, it makes plain
## stand-ins of its own: a club, an axe, a block, a pot and lid, spears and
## stones, a bone; the head of the person itself (a second body of the same
## person, all but the head drawn in); blood as a burst of red drops and
## pools on the floor. Each is asked of its owner first (has_method) so their
## work takes over as it lands.
## Lives only while an execution plays: nothing here runs when idle, and
## skip() brings everything to its end at once.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
## J's gore on the person's own figure (court_figure_gore.gd), when it is in.
const GORE_PATH:="res://scripts/hud/court_figure_gore.gd"
static var _gore:Script
static func gore_kit()->Script:
	if _gore==null and ResourceLoader.exists(GORE_PATH):_gore=load(GORE_PATH)
	return _gore

signal finished

var stage:Control
var method:=""
var victim:=""
var style:="full"
var _tweens:Array=[]
## Things brought in for this execution (freed at the end).
var _made:Array=[]
## Named things brought in: "club", "axe", "block", "pot", "lid", "bone", "head:<key>"...
var _things:Dictionary={}
## Bones drawn in (a body without its head, a head without its body).
var _shrinks:Array=[]
var _ended:=false
var _caption_text:=""

const BLOOD:=Color("9c1a12")
const BLOOD_DARK:=Color("6a0d08")
const WOOD:=Color("6b4a2e")
const BRONZE:=Color("b8803c")
const CLAY:=Color("8a5134")
const BONE:=Color("e8dcc4")
const STONE:=Color("8a857b")

func begin(on_stage:Control,method_id:String,victim_key:String,how:String)->void:
	stage=on_stage;method=method_id;victim=victim_key;style=how
	# The figures cut the person's own meshes ready for the blow (J).
	var b:=_body(victim)
	if style=="full" and b!=null and b.has_method("gore_prepare") and bool(b.call("gore_allowed")):b.call("gore_prepare")

## The pieces a person came apart into (J's split): {key: {name: Node3D}}.
var _pieces:Dictionary={}
## Where their neck was at the blow (the spray comes from there).
var _necks:Dictionary={}

# --- the beats ------------------------------------------------------------------------

## One of the director's exec beats.
func op(name:String,args:Dictionary)->void:
	if _ended or stage==null:return
	match name:
		"prop":_prop(args)
		"unprop":_unprop(String(args.get("id",args.get("name",""))))
		"approach":_approach(String(args.get("who","")),String(args.get("to",victim)),float(args.get("side",1.0)),float(args.get("dist",0.75)),float(args.get("time",0.9)))
		"twist":_twist(String(args.get("who","")),float(args.get("yaw",0.0)),float(args.get("time",0.3)))
		"lean":_lean(String(args.get("who",victim)),float(args.get("pitch",30.0)),float(args.get("time",0.5)))
		"lunge":_lunge(String(args.get("who","")),float(args.get("dist",0.25)),float(args.get("time",0.12)))
		"stick":_stick(String(args.get("id","")),String(args.get("in","block")))
		"retrieve":_retrieve(String(args.get("id","")),String(args.get("who","")))
		"behead":_behead(args)
		"fall":_fall(String(args.get("who",victim)),String(args.get("kind","forward")),float(args.get("time",0.6)))
		"spray":_spray_at(args)
		"pool":_pool_at(args)
		"drag":_drag(args)
		"dogs":_dogs(args)
		"fetch":_fetch(args)
		"throw":_throw(args)
		"char":_char(String(args.get("who",victim)),float(args.get("time",1.0)))
		"crumble":_crumble(String(args.get("who",victim)),float(args.get("time",1.2)))
		"drop":_drop(args)
		"vanish":_vanish(String(args.get("who",victim)))
		"caption":_caption(String(args.get("text","")))
		"blow","noise":pass
		"end":finish()

# --- people ---------------------------------------------------------------------------

func _fig(key:String)->Variant:
	return stage.call("figure",key) if stage!=null and key!="" else null

func _body(key:String)->Node3D:
	var f:Variant=_fig(key)
	return f.body3d if f!=null and f.body3d!=null and is_instance_valid(f.body3d) else null

func _court()->Node3D:
	var c:Variant=stage.get("court_set")
	return c as Node3D if c is Node3D else null

func _tween()->Tween:
	var t:=create_tween()
	_tweens.append(t)
	return t

## A world point the director names: a person ("p3", "main"), a set mark
## ("fire", "door"), a thing brought in ("pot", "block"), "god_feet" (on the
## floor before the god), "windbreak" (behind the hides, or the door).
func point(name:String)->Vector3:
	if _things.has(name) and is_instance_valid(_things[name]):return (_things[name] as Node3D).global_position
	if name.begins_with("front:"):
		var parts:=name.split(":")
		var from:=point(parts[1]) if parts.size()>1 else Vector3.ZERO
		return from-_camera_dir()*(float(parts[2]) if parts.size()>2 else 1.0)
	var b:=_body(name)
	if b!=null:return b.global_position
	var court:=_court()
	if court==null:return Vector3.ZERO
	match name:
		"god_feet":
			var front:Vector3=stage.call("set_point","petitioner")
			var god:Vector3=court.call("god_point")
			var toward:=Vector3(god.x-front.x,0.0,god.z-front.z)
			return front+toward.normalized()*minf(1.6,toward.length()*0.5) if toward.length()>0.01 else front
		"windbreak":
			var model:=court.get_node_or_null("Model")
			var wall:Node3D=model.find_child("Windbreak",true,false) as Node3D if model!=null else null
			if wall!=null:
				var fire:Vector3=stage.call("set_point","fire")
				var away:=Vector3(wall.global_position.x-fire.x,0.0,wall.global_position.z-fire.z)
				return wall.global_position+away.normalized()*1.2
			return stage.call("set_point","door_out")
	return stage.call("set_point",name)

## Moves someone in the hall (their nudge, so the stage keeps them in step).
func _move_to(key:String,world:Vector3,time:float,trans:=Tween.TRANS_SINE)->void:
	var f:Variant=_fig(key)
	if f==null or f.spot==null:return
	var local:Vector3=f.spot.to_local(world)-f._path_at(f.stroll)
	local.y=0.0
	var t:=_tween()
	t.tween_property(f,"nudge",local,maxf(time,0.05)).set_trans(trans).set_ease(Tween.EASE_IN_OUT)

func _approach(key:String,to:String,side:float,dist:float,time:float)->void:
	var b:=_body(key);var v:=_body(to)
	if b==null or v==null:return
	var cam:=_camera_dir()
	var across:=Vector3(-cam.z,0.0,cam.x).normalized()*side
	var spot:=v.global_position+across*dist
	_move_to(key,spot,time)
	var f:Variant=_fig(key)
	if f!=null:f.body3d.play("walk_in",0.2,0.0)
	var t:=_tween()
	t.tween_interval(time)
	t.tween_callback(func()->void:
		if is_instance_valid(b):
			b.play(String(f.rest_clip) if f!=null else "stand",0.3)
			var way:=v.global_position-b.global_position
			b.face(rad_to_deg(atan2(way.x,way.z))-rad_to_deg(b.get_parent_node_3d().global_rotation.y),0.2))

## Which way the camera looks along the floor.
func _camera_dir()->Vector3:
	var cam:Variant=stage.get("camera")
	if cam is Camera3D and (cam as Camera3D).is_inside_tree():
		var f:=-(cam as Camera3D).global_transform.basis.z
		f.y=0.0
		if f.length()>0.01:return f.normalized()
	return Vector3(0,0,-1)

func _twist(key:String,yaw:float,time:float)->void:
	var b:=_body(key)
	if b==null:return
	var t:=_tween()
	t.tween_property(b,"rotation_degrees:y",b.rotation_degrees.y+yaw,maxf(time,0.03)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if time<0.2 else Tween.EASE_IN_OUT)

func _lean(key:String,pitch:float,time:float)->void:
	var b:=_body(key)
	if b==null:return
	var t:=_tween()
	t.tween_property(b,"rotation_degrees:x",pitch,maxf(time,0.03)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## A quick step in (the blow) and back.
func _lunge(key:String,dist:float,time:float)->void:
	var f:Variant=_fig(key)
	var b:=_body(key)
	if f==null or b==null:return
	var ahead:=b.global_transform.basis.z;ahead.y=0.0
	var from:Vector3=f.nudge
	var t:=_tween()
	t.tween_property(f,"nudge",from+f.spot.global_transform.basis.inverse()*(ahead.normalized()*dist),time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(f,"nudge",from,0.35).set_trans(Tween.TRANS_SINE)

func _fall(key:String,kind:String,time:float)->void:
	var torso:Node3D=null
	for name in ["torso_limbs","torso"]:
		if _pieces.has(key) and (_pieces[key] as Dictionary).has(name):torso=(_pieces[key] as Dictionary)[name]
	if torso!=null and is_instance_valid(torso):
		# the body that is left goes over where it knelt
		var down:=_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var turn:=Vector3(-80.0 if kind=="back" else 80.0,0.0,0.0) if kind!="side" else Vector3(0.0,0.0,80.0)
		var ahead:=torso.global_transform.basis.z;ahead.y=0.0
		down.tween_property(torso,"rotation_degrees",torso.rotation_degrees+turn,time)
		down.parallel().tween_property(torso,"global_position",Vector3(torso.global_position.x,0.18,torso.global_position.z)+ahead.normalized()*0.3*(-1.0 if kind=="back" else 1.0),time)
		return
	var b:=_body(key)
	if b==null:return
	var t:=_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	match kind:
		"back":t.tween_property(b,"rotation_degrees:x",-84.0,time)
		"side":t.tween_property(b,"rotation_degrees:z",82.0,time)
		_:t.tween_property(b,"rotation_degrees:x",78.0,time)
	t.tween_callback(func()->void:if is_instance_valid(b) and b.player!=null:b.player.pause())

func _vanish(key:String)->void:
	var f:Variant=_fig(key)
	if f==null:return
	f.leaving=true
	f._vanish()

# --- things brought in ----------------------------------------------------------------

func _mat(colour:Color,unshaded:=false,metal:=0.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=colour
	m.roughness=0.85 if metal<=0.0 else 0.4
	m.metallic=metal
	if unshaded:m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _mesh(mesh:Mesh,colour:Color,metal:=0.0)->MeshInstance3D:
	var mi:=MeshInstance3D.new()
	mi.mesh=mesh
	mi.material_override=_mat(colour,false,metal)
	mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

## A thing by name, made plainly (its owner's model when there is one).
func _make(name:String)->Node3D:
	var court:=_court()
	if court!=null and court.has_method("exec_prop"):
		var theirs:Variant=court.call("exec_prop",name)
		if theirs is Node3D:return theirs
	var root:=Node3D.new();root.name="Exec_"+name
	match name:
		"club":
			var shaft:=CylinderMesh.new();shaft.top_radius=0.075;shaft.bottom_radius=0.03;shaft.height=0.8;shaft.radial_segments=10
			var s:=_mesh(shaft,WOOD);s.position.y=0.32;root.add_child(s)
			var knob:=SphereMesh.new();knob.radius=0.095;knob.height=0.17;knob.radial_segments=10;knob.rings=6
			var k:=_mesh(knob,WOOD.darkened(0.15));k.position.y=0.72;root.add_child(k)
		"axe":
			var handle:=CylinderMesh.new();handle.top_radius=0.022;handle.bottom_radius=0.026;handle.height=0.95;handle.radial_segments=8
			var h:=_mesh(handle,WOOD);h.position.y=0.38;root.add_child(h)
			var blade:=PrismMesh.new();blade.size=Vector3(0.26,0.22,0.03)
			var bl:=_mesh(blade,BRONZE,0.6);bl.position=Vector3(0.11,0.78,0.0);bl.rotation_degrees.z=-90.0;root.add_child(bl)
		"block":
			var box:=BoxMesh.new();box.size=Vector3(0.55,0.36,0.42)
			var b:=_mesh(box,WOOD.lightened(0.08));b.position.y=0.18;root.add_child(b)
		"pot":
			var pot:=CylinderMesh.new();pot.top_radius=0.26;pot.bottom_radius=0.2;pot.height=0.42;pot.radial_segments=16
			var p:=_mesh(pot,CLAY);p.position.y=0.21;root.add_child(p)
			var broth:=CylinderMesh.new();broth.top_radius=0.235;broth.bottom_radius=0.235;broth.height=0.02;broth.radial_segments=16
			var w:=_mesh(broth,Color("5a3a1c"));w.position.y=0.38;root.add_child(w)
		"lid":
			var lid:=CylinderMesh.new();lid.top_radius=0.2;lid.bottom_radius=0.28;lid.height=0.05;lid.radial_segments=16
			var l:=_mesh(lid,CLAY.darkened(0.1));root.add_child(l)
			var knob2:=SphereMesh.new();knob2.radius=0.04;knob2.height=0.06
			var n:=_mesh(knob2,CLAY.darkened(0.2));n.position.y=0.04;root.add_child(n)
		"bone":
			var shaft2:=CapsuleMesh.new();shaft2.radius=0.03;shaft2.height=0.36
			var bs:=_mesh(shaft2,BONE);bs.rotation_degrees.z=90.0;root.add_child(bs)
			for end in [-0.17,0.17]:
				var knuckle:=SphereMesh.new();knuckle.radius=0.045;knuckle.height=0.08
				var kn:=_mesh(knuckle,BONE);kn.position.x=end;root.add_child(kn)
		"spear":
			var pole:=CylinderMesh.new();pole.top_radius=0.018;pole.bottom_radius=0.02;pole.height=1.7;pole.radial_segments=6
			var sp:=_mesh(pole,WOOD.lightened(0.1));sp.position.y=0.0;root.add_child(sp)
			var tip:=PrismMesh.new();tip.size=Vector3(0.06,0.16,0.02)
			var tp:=_mesh(tip,STONE.darkened(0.25));tp.position.y=0.92;root.add_child(tp)
		"stone":
			var rock:=SphereMesh.new();rock.radius=0.09;rock.height=0.15;rock.radial_segments=7;rock.rings=4
			root.add_child(_mesh(rock,STONE))
		"boulder":
			var big:=SphereMesh.new();big.radius=0.62;big.height=1.05;big.radial_segments=9;big.rings=6
			var bb:=_mesh(big,STONE.darkened(0.08));bb.position.y=0.5;root.add_child(bb)
		"stake":
			var post:=CylinderMesh.new();post.top_radius=0.012;post.bottom_radius=0.06;post.height=2.1;post.radial_segments=8
			var pp:=_mesh(post,WOOD);pp.position.y=1.05;root.add_child(pp)
		"bow":
			var arc:=TorusMesh.new();arc.inner_radius=0.5;arc.outer_radius=0.53;arc.rings=12;arc.ring_segments=4
			var a:=_mesh(arc,WOOD);a.scale=Vector3(1.0,1.0,0.3);root.add_child(a)
		"arrow":
			var reed:=CylinderMesh.new();reed.top_radius=0.008;reed.bottom_radius=0.008;reed.height=0.7;reed.radial_segments=5
			var ar:=_mesh(reed,WOOD.lightened(0.2));root.add_child(ar)
			var fl:=BoxMesh.new();fl.size=Vector3(0.05,0.1,0.005)
			var f2:=_mesh(fl,Color("d9d0bd"));f2.position.y=-0.3;root.add_child(f2)
	return root

## A thing brought in: in someone's hand, or set down at a point.
func _prop(args:Dictionary)->void:
	var name:=String(args.get("name",""))
	var id:=String(args.get("id",name))
	if _things.has(id):_unprop(id)
	var node:=_make(name)
	_made.append(node)
	_things[id]=node
	var hand_of:=String(args.get("to",""))
	if hand_of!="":
		var holder:=_hand(hand_of,String(args.get("hand","R")))
		if holder!=null:
			holder.add_child(node)
			# held at the bottom of the shaft, the shaft along the fingers
			node.position=Vector3(0.0,0.02,0.02)
			node.rotation_degrees=Vector3(float(args.get("tilt",90.0)),0.0,0.0)
			return
	var court:=_court()
	if court==null:return
	court.add_child(node)
	var at:=point(String(args.get("at",victim)))
	var off:Vector3=args.get("offset",Vector3.ZERO)
	if args.get("front",0.0)!=0.0:
		var v:=_body(String(args.get("of",victim)))
		if v!=null:
			var ahead:=v.global_transform.basis.z;ahead.y=0.0
			off+=ahead.normalized()*float(args.front)
	if args.get("toward_camera",0.0)!=0.0:off+=-_camera_dir()*float(args.toward_camera)
	node.global_position=Vector3(at.x,0.0,at.z)+off
	if args.get("y",null)!=null:node.global_position.y=float(args.y)

func _unprop(id:String)->void:
	if not _things.has(id):return
	var node:=_things[id] as Node3D
	_things.erase(id)
	if is_instance_valid(node):node.queue_free()

## Someone's hand, to carry a thing in.
func _hand(key:String,side:String)->Node3D:
	var b:=_body(key)
	if b==null or b.get("skeleton")==null:return null
	var sk:Skeleton3D=b.skeleton
	var bone:=sk.find_bone("hand."+side)
	if bone<0:return null
	var name:="ExecHand_"+side
	var have:=sk.get_node_or_null(name) as BoneAttachment3D
	if have==null:
		have=BoneAttachment3D.new();have.name=name;have.bone_name="hand."+side
		sk.add_child(have)
		_made.append(have)
	return have

## The blade stays in the block: the thing leaves the hand where it is.
func _stick(id:String,into:String)->void:
	var node:=_things.get(id) as Node3D
	if node==null or not is_instance_valid(node):return
	var court:=_court()
	if court==null:return
	var at:=node.global_transform
	node.get_parent().remove_child(node)
	court.add_child(node)
	node.global_transform=at

func _retrieve(id:String,key:String)->void:
	var node:=_things.get(id) as Node3D
	var holder:=_hand(key,"R")
	if node==null or holder==null:return
	node.get_parent().remove_child(node)
	holder.add_child(node)
	node.position=Vector3(0.0,0.02,0.02);node.rotation_degrees=Vector3(90.0,0.0,0.0)

## Something falls or is let down onto a point (the boulder, the lid).
func _drop(args:Dictionary)->void:
	var id:=String(args.get("id",""))
	var node:=_things.get(id) as Node3D
	if node==null or not is_instance_valid(node):return
	var to:=point(String(args.get("at",victim)))+(args.get("offset",Vector3.ZERO) as Vector3)
	var from:=to+Vector3(0.0,float(args.get("height",2.5)),0.0)
	node.global_position=from
	var t:=_tween()
	t.tween_property(node,"global_position",to,float(args.get("time",0.35))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## Thrown or flung things: stones, spears, arrows, from someone to someone.
func _throw(args:Dictionary)->void:
	var name:=String(args.get("name","stone"))
	var from:=point(String(args.get("from","")))+Vector3(0.0,1.5,0.0)
	var to_key:=String(args.get("to",victim))
	var target:=_body(to_key)
	var to:=point(to_key)+Vector3(0.0,float(args.get("height",1.0)),0.0)+(args.get("miss",Vector3.ZERO) as Vector3)
	var node:=_make(name)
	var court:=_court()
	if court==null:return
	court.add_child(node);_made.append(node)
	node.global_position=from
	var time:=float(args.get("time",0.5))
	var up:=float(args.get("arc",0.6))
	var t:=_tween()
	t.tween_method(func(k:float)->void:
		if not is_instance_valid(node):return
		var p:=from.lerp(to,k)+Vector3(0.0,sin(k*PI)*up,0.0)
		var ahead:=from.lerp(to,minf(k+0.05,1.0))+Vector3(0.0,sin(minf(k+0.05,1.0)*PI)*up,0.0)
		node.global_position=p
		if name in ["spear","arrow"] and ahead.distance_to(p)>0.001:node.look_at(ahead,Vector3.UP,true)
		if name in ["spear","arrow"]:node.rotate_object_local(Vector3.RIGHT,PI*0.5),0.0,1.0,time)
	# A spear or arrow stays in them, riding with them as they fall.
	if bool(args.get("stick",name in ["spear","arrow"])) and target!=null and args.get("miss",Vector3.ZERO)==Vector3.ZERO:
		t.tween_callback(func()->void:
			if is_instance_valid(node) and is_instance_valid(target):
				var keep:=node.global_transform
				node.get_parent().remove_child(node);target.add_child(node);node.global_transform=keep)

# --- the head, and blood --------------------------------------------------------------

## A skeleton modifier that draws bones in (scale) after the clips and the acting.
class Shrink extends SkeletonModifier3D:
	var scales:Dictionary={}
	func _process_modification_with_delta(_delta:float)->void:
		var sk:=get_skeleton()
		if sk==null:return
		for bone:int in scales:sk.set_bone_pose_scale(bone,scales[bone])

func _shrink(body:Node3D,scales:Dictionary)->void:
	var sk:Skeleton3D=body.get("skeleton")
	if sk==null:return
	var mod:=Shrink.new();mod.name="ExecShrink"
	for name:String in scales:
		var bone:=sk.find_bone(name)
		if bone>=0:mod.scales[bone]=scales[name]
	sk.add_child(mod)
	_shrinks.append(mod)

## The head comes off: the body keeps a red stump; the head (the same person,
## the rest of them drawn in to nothing) flies, rolls or lands where it is sent.
## args: who, fly ("pot", "floor", a point name), time, spin (turns), roll,
## face_god, blink.
func _behead(args:Dictionary)->void:
	var key:=String(args.get("who",victim))
	var body:=_body(key)
	if body==null:return
	var court:=_court()
	if court==null:return
	var sk:Skeleton3D=body.get("skeleton")
	if sk==null:return
	var neck:=sk.find_bone("neck");var head_bone:=sk.find_bone("head");var chest:=sk.find_bone("chest")
	if neck<0 or head_bone<0:return
	var neck_world:=sk.global_transform*sk.get_bone_global_pose(neck).origin
	var head_world:=sk.global_transform*sk.get_bone_global_pose(head_bone).origin
	var head_scale:=body.global_transform.basis.get_scale().y
	_necks[key]=neck_world
	# J's split pieces when the figure has them; else the stand-in.
	var head:Node3D=null
	var theirs:=false
	if body.has_method("gore_split") and bool(body.call("gore_allowed")):
		var parts:Dictionary=body.call("gore_split","head")
		if parts.get("head") is Node3D:
			head=parts.head;theirs=true
			_pieces[key]=parts
	if head==null:
		head=_head_of(body,head_world,neck_world,head_scale)
		_shrink(body,{"neck":Vector3.ONE*0.02})
	if head==null:return
	_things["head:"+key]=head
	# the stump: a red cap where the neck was
	if chest>=0 and not theirs:
		var cap:=BoneAttachment3D.new();cap.name="ExecStump";cap.bone_name="chest"
		sk.add_child(cap);_made.append(cap)
		var disc:=CylinderMesh.new();disc.top_radius=0.055;disc.bottom_radius=0.06;disc.height=0.03;disc.radial_segments=12
		var stump:=_mesh(disc,BLOOD)
		cap.add_child(stump)
		stump.global_position=neck_world
	# where it goes
	var to_name:=String(args.get("fly","floor"))
	var to:Vector3
	if to_name=="floor" or to_name=="roll":
		to=Vector3(head_world.x,0.11*head_scale,head_world.z)-_camera_dir()*float(args.get("roll_dist",1.4))
	else:
		to=point(to_name)+Vector3(0.0,float(args.get("land_y",0.42)),0.0)
	var from:=head.global_position
	var time:=float(args.get("time",1.2))
	var up:=float(args.get("arc",1.6))
	var spin:=float(args.get("spin",3.0))
	var t:=_tween()
	t.tween_method(func(k:float)->void:
		if not is_instance_valid(head):return
		var p:=from.lerp(to,k)+Vector3(0.0,sin(k*PI)*up*(1.0-k*0.3),0.0)
		head.global_position=p
		head.rotation.x=k*spin*TAU,0.0,1.0,time)
	if bool(args.get("face_god",false)):
		# it settles upright, turned to the god, and blinks
		t.tween_property(head,"rotation:x",0.0,0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var god:Vector3=court.call("god_point")
		var yaw:=atan2(god.x-to.x,god.z-to.z)
		t.parallel().tween_property(head,"rotation:y",yaw,0.35).set_trans(Tween.TRANS_SINE)
		if bool(args.get("blink",true)):
			# blinks at the god (at blink_at seconds after the blow, if given)
			var wait:=maxf(float(args.get("blink_at",time+0.85))-time-0.35,0.1)
			t.tween_interval(wait)
			t.tween_callback(_blink.bind(head))
			t.tween_interval(0.45)
			t.tween_callback(_blink.bind(head))
	elif to_name!="floor" and to_name!="roll":
		# into the pot: it sinks out of sight
		t.tween_property(head,"global_position",to-Vector3(0.0,0.35,0.0),0.25)
		t.tween_callback(head.hide)

## A second body of the person, all but the head drawn in, its head where
## theirs is. Returns the pivot it rides on (the middle of the head).
func _head_of(body:Node3D,head_world:Vector3,neck_world:Vector3,head_scale:float)->Node3D:
	var court:=_court()
	var look:Dictionary=body.get("look") if body.get("look") is Dictionary else {}
	var copy:=Figure3D.new()
	if not copy.setup(look):
		copy.free();return null
	var pivot:=Node3D.new();pivot.name="ExecHead"
	court.add_child(pivot);_made.append(pivot)
	pivot.global_position=head_world+Vector3(0.0,0.09*head_scale,0.0)
	pivot.add_child(copy)
	copy.scale=body.global_transform.basis.get_scale()
	copy.set_mood("afraid")
	if copy.player!=null:copy.play("stand",0.0,0.0);copy.player.pause()
	# Everything below the neck drawn into the hips; the neck put back to
	# size, so the head is whole and the rest a speck inside it.
	_shrink(copy,{"hips":Vector3.ONE*0.01,"neck":Vector3.ONE*100.0})
	# The head of the copy (hips' place) to the pivot: hips stand at their height.
	var sk:Skeleton3D=copy.skeleton
	var hips:=sk.find_bone("hips") if sk!=null else -1
	var hips_local:=sk.get_bone_global_rest(hips).origin if hips>=0 else Vector3(0.0,0.95,0.0)
	var model_scale:=copy.model.scale if copy.model!=null else Vector3.ONE
	copy.position=-Vector3(hips_local.x*model_scale.x,hips_local.y*model_scale.y+0.11,hips_local.z*model_scale.z)
	copy.rotation.y=body.global_rotation.y
	_made.append(copy)
	return pivot

func _blink(head:Node3D)->void:
	if not is_instance_valid(head):return
	if head.has_method("blink"):
		head.call("blink",1)
		return
	for mi in head.find_children("*","MeshInstance3D",true,false):
		var node:=mi as MeshInstance3D
		var shape:=node.find_blend_shape_by_name(&"blink")
		if shape<0:continue
		var t:=_tween()
		t.tween_method(func(v:float)->void:if is_instance_valid(node):node.set_blend_shape_value(shape,v),0.0,1.0,0.08)
		t.tween_method(func(v:float)->void:if is_instance_valid(node):node.set_blend_shape_value(shape,v),1.0,0.0,0.12)

## Blood: a burst of red drops from a point (a neck, a pot, under a boulder).
## args: at (a person's neck "neck:<key>", or a point name), dir ("up", "fan",
## "camera"), seconds, amount, speed.
func _spray_at(args:Dictionary)->void:
	if style!="full":return
	var court:=_court()
	if court==null:return
	var at_name:=String(args.get("at",""))
	var origin:Vector3
	if at_name.begins_with("neck:") and _necks.has(at_name.trim_prefix("neck:")):
		origin=_necks[at_name.trim_prefix("neck:")]
	elif at_name.begins_with("neck:"):
		var b:=_body(at_name.trim_prefix("neck:"))
		if b==null:return
		var sk:Skeleton3D=b.get("skeleton")
		var neck:=sk.find_bone("neck") if sk!=null else -1
		origin=(sk.global_transform*sk.get_bone_global_pose(neck).origin) if neck>=0 else b.global_position+Vector3(0,1.4,0)
	else:
		origin=point(at_name)+Vector3(0.0,float(args.get("y",0.3)),0.0)
	if court.has_method("blood"):
		court.call("blood",String(args.get("kind","spray")),origin,args)
		return
	var p:=CPUParticles3D.new();p.name="ExecBlood"
	court.add_child(p);_made.append(p)
	p.global_position=origin
	var drop:=SphereMesh.new();drop.radius=0.022;drop.height=0.044;drop.radial_segments=6;drop.rings=3
	var m:=_mat(BLOOD,true)
	drop.material=m
	p.mesh=drop
	p.amount=int(args.get("amount",90))
	p.lifetime=float(args.get("life",1.1))
	p.one_shot=false
	p.explosiveness=float(args.get("burst",0.0))
	p.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius=0.04
	var dir:=String(args.get("dir","up"))
	match dir:
		"camera":
			var c:=-_camera_dir()
			p.direction=Vector3(c.x,1.1,c.z).normalized()
		"fan":p.direction=Vector3(0,1,0)
		_:p.direction=Vector3(0,1,0)
	p.spread=float(args.get("spread",22.0))
	p.initial_velocity_min=float(args.get("speed",3.4))*0.7
	p.initial_velocity_max=float(args.get("speed",3.4))*1.15
	p.gravity=Vector3(0,-9.8,0)
	p.scale_amount_min=0.6;p.scale_amount_max=1.6
	p.emitting=true
	var t:=_tween()
	t.tween_interval(float(args.get("seconds",1.2)))
	t.tween_callback(func()->void:if is_instance_valid(p):p.emitting=false)
	# where it lands, it pools
	if bool(args.get("pool",true)):
		t.tween_callback(func()->void:_pool_at({"at_world":Vector3(origin.x,0.0,origin.z)-(-_camera_dir() if dir=="camera" else Vector3.ZERO)*0.6,"r":float(args.get("pool_r",0.55))}))

## A red pool spreading on the floor.
func _pool_at(args:Dictionary)->void:
	if style!="full":return
	var court:=_court()
	if court==null:return
	var at:Vector3=args.get("at_world",Vector3.INF)
	if at==Vector3.INF:at=point(String(args.get("at",victim)))
	var disc:=CylinderMesh.new();disc.top_radius=1.0;disc.bottom_radius=1.0;disc.height=0.004;disc.radial_segments=20
	var pool:=MeshInstance3D.new();pool.name="ExecPool";pool.mesh=disc
	var m:=_mat(BLOOD_DARK)
	m.roughness=0.25
	pool.material_override=m
	pool.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	court.add_child(pool);_made.append(pool)
	pool.global_position=Vector3(at.x,0.012,at.z)
	pool.scale=Vector3(0.05,1.0,0.05)
	var r:=float(args.get("r",0.5))
	var t:=_tween()
	t.tween_property(pool,"scale",Vector3(r,1.0,r*0.8),float(args.get("time",1.6))).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

# --- dogs -----------------------------------------------------------------------------

var _pack:Array=[]

## The camp dogs: the set's own and one or two more, running to someone.
func _dogs(args:Dictionary)->void:
	var court:=_court()
	if court==null:return
	_pack.clear()
	var own:Variant=court.call("animal","dog") if court.has_method("animal") else null
	if own is Node3D:_pack.append(own)
	var more:=int(args.get("more",2))
	var Animal:Script=court.get_script().get("Animal") if court.get_script()!=null else null
	for i in more:
		if Animal==null:break
		var dog:Node3D=Animal.new()
		if not dog.call("setup","dog",court,7+i):
			dog.free();continue
		court.add_child(dog);_made.append(dog)
		var door:Vector3=court.to_local(point("door"))
		dog.position=door+Vector3(0.3*i,0.0,0.4*i)
		_pack.append(dog)
	var to:=court.to_local(point(String(args.get("to",victim))))
	for i in _pack.size():
		var dog:Node3D=_pack[i]
		var off:=Vector3(cos(i*2.1),0.0,sin(i*2.1))*0.45
		dog.call("go_to",court.to_global(to+off),"trot")

## The dogs drag the body off (to "windbreak", or a point), the dogs alongside.
func _drag(args:Dictionary)->void:
	var key:=String(args.get("who",victim))
	var court:=_court()
	if court==null:return
	var to:=point(String(args.get("to","windbreak")))
	var time:=float(args.get("time",2.6))
	_move_to(key,to,time,Tween.TRANS_LINEAR)
	for i in _pack.size():
		var dog:Node3D=_pack[i]
		if is_instance_valid(dog):dog.call("go_to",to+Vector3(cos(i*2.4),0.0,sin(i*2.4))*0.4,"walk")

## A dog comes back with a bone and drops it at the god's feet, and wags.
func _fetch(args:Dictionary)->void:
	if _pack.is_empty():return
	var dog:Node3D=_pack[0]
	if not is_instance_valid(dog):return
	var court:=_court()
	var bone:=_make("bone")
	dog.add_child(bone);_made.append(bone)
	bone.position=Vector3(0.0,0.42,0.42)
	bone.rotation_degrees.y=90.0
	if style=="off":bone.hide()
	var to:=point(String(args.get("to","god_feet")))
	dog.call("go_to",to,"trot",func()->void:
		if not is_instance_valid(dog):return
		var keep:=bone.global_transform
		bone.get_parent().remove_child(bone);court.add_child(bone)
		bone.global_transform=keep
		var down:=create_tween();_tweens.append(down)
		down.tween_property(bone,"global_position:y",0.04,0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		dog.call("face_toward",court.to_local(court.call("god_point")))
		dog.call("wag",4.0))

# --- fire -----------------------------------------------------------------------------

func _char(key:String,time:float)->void:
	var b:=_body(key)
	if b==null:return
	var kit:=gore_kit()
	if kit!=null and style=="full" and bool(kit.call("allowed",b)):
		kit.call("char",b,true)
		return
	var t:=_tween()
	t.tween_method(func(v:float)->void:if is_instance_valid(b):b.set_light(v),1.0,0.05,time)

func _crumble(key:String,time:float)->void:
	var b:=_body(key)
	if b==null:return
	var kit:=gore_kit()
	if kit!=null and style=="full" and bool(kit.call("allowed",b)):
		var fall:=_tween()
		fall.tween_method(func(v:float)->void:if is_instance_valid(b):kit.call("crumble",b,v),0.0,1.0,time)
		fall.tween_callback(func()->void:_vanish(key))
		return
	var t:=_tween()
	t.tween_property(b,"scale",Vector3(b.scale.x*1.25,0.02,b.scale.z*1.25),time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func()->void:_vanish(key))
	# a heap of ash where they stood
	var court:=_court()
	if court!=null:
		var heap:=SphereMesh.new();heap.radius=0.32;heap.height=0.22;heap.radial_segments=10;heap.rings=4
		var ash:=_mesh(heap,Color("3a3532"))
		court.add_child(ash);_made.append(ash)
		ash.global_position=Vector3(b.global_position.x,0.0,b.global_position.z)
		ash.scale=Vector3(0.05,0.05,0.05)
		t.parallel().tween_property(ash,"scale",Vector3.ONE,time)

# --- the caption, the end -------------------------------------------------------------

func _caption(text:String)->void:
	var told:=String(stage.get("exec_caption_override")) if stage.get("exec_caption_override")!=null else ""
	if not told.is_empty():text=told
	_caption_text=text
	if text.is_empty():return
	stage.call("caption",text,"narration",true)

## Everything to its end at once (a click): the person gone, the head where
## it lands, the things taken away, the caption said.
func skip()->void:
	if _ended:return
	for t in _tweens:
		if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(60.0)
	finish()

func finish()->void:
	if _ended:return
	_ended=true
	for t in _tweens:
		if t is Tween and (t as Tween).is_valid():(t as Tween).kill()
	_tweens.clear()
	_vanish(victim)
	var kit:=gore_kit()
	var b:=_body(victim)
	if kit!=null and b!=null:kit.call("release",b)
	for key in _pieces:
		for piece in (_pieces[key] as Dictionary).values():
			if is_instance_valid(piece):(piece as Node).queue_free()
	_pieces.clear()
	for node in _made:
		if is_instance_valid(node) and not String((node as Node).name).begins_with("ExecPool"):(node as Node).queue_free()
	# the pools fade over a few seconds
	for node in _made:
		if is_instance_valid(node) and String((node as Node).name).begins_with("ExecPool"):
			var pool:=node as MeshInstance3D
			var fade:=pool.create_tween()
			fade.tween_interval(4.0)
			fade.tween_property(pool,"scale",Vector3(0.01,1.0,0.01),3.0)
			fade.tween_callback(pool.queue_free)
	_made.clear();_things.clear();_pack.clear()
	finished.emit()
	queue_free()
