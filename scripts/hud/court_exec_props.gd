extends RefCounted
## The props of the court's executions (EXECUTIONS.md), made in Blender by
## tools/blender/court_exec_props.py (assets/court_sets/exec/): the cooking pot
## with its lid and paddle, the club, the block and the bronze axe, the
## thighbone and the skull, the skull on a stake, the boulder; more act by act.
##   CourtExecProps.make(name, court_set)  a prop, dressed in the set's own paint
##                                         and ink (court_set_3d.gd dress())
##   CourtExecProps.info(name)             its size, grip, seats, era needs
##   CourtExecProps.hold(prop, figure, hand)  put it in someone's hand
##   CourtExecProps.seat(prop, on, seat)   set it on another's seat (the lid
##                                         on the pot, the axe in the block)
##   CourtExecProps.available(name, tags)  whether the people can have it
##   CourtExecProps.pick(role, tags)       the prop for a part in an act the
##                                         people can have ("cook": the pot once
##                                         they make pots, else the paunch on its
##                                         tripod), or "" if none
##   CourtExecProps.lid_for(name)          a pot's lid ("cook_pot" -> "cook_pot_lid")
##   CourtExecProps.throw(prop, from, to, seconds, arc)  fly it there on an arc,
##                                         spinning (stones) or tip first (spears,
##                                         arrows); returns the Tween
##   CourtExecProps.stick(prop, into, at, dir)  stuck in someone (or a wall)
##                                         where it hit, quivering a moment
## Presentation only.

const DIR:="res://assets/court_sets/exec/"
const MANIFEST:=DIR+"court_exec_props.json"

static var _manifest:Dictionary={}
static var _scene:PackedScene

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(MANIFEST)
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"props":{}}
	return _manifest

static func info(prop_name:String)->Dictionary:
	return (manifest().get("props",{}) as Dictionary).get(prop_name,{})

static func names()->Array:
	return (manifest().get("props",{}) as Dictionary).keys()

## Whether the people can have this prop: what it needs among their era
## tags, and (when their known discoveries are given) one of the discoveries
## it asks for ("known_any", e.g. the bow: bow_craft or composite_bow).
static func available(prop_name:String,tags:Array,known:Array=[])->bool:
	var spec:=info(prop_name)
	if spec.is_empty():return false
	for need in spec.get("needs",[]):
		if not tags.has(String(need)):return false
	var any:Array=spec.get("known_any",[])
	if not any.is_empty() and not known.is_empty():
		for id in any:
			if known.has(String(id)):return true
		return false
	return true

## The props that can play a part, best first (the first the people can have
## is used): the cook's pot is a clay pot once they make pots, before that a
## paunch slung from a tripod and boiled with hot stones.
const ROLES:={
	"cook":["cook_pot","cook_bag"],
	"stirrer":["cook_ladle"],
	"club":["club"],
	"block":["block"],
	"axe":["axe_bronze"],
	"bone":["thighbone"],
	"skull":["skull"],
	"boulder":["boulder"],
	"ledge":["boulder_ledge"],
	"trophy_stake":["skull_stake"],
	"ash":["ash_pile"],
	"spear":["spear_bronze","spear_flint"],
	"stone":["stone_b","stone_a","stone_c"],
	"cauldron":["cauldron_bronze","cauldron_clay"],
	"stake":["impaling_stake"],
	"bow":["bow"],
	"arrow":["arrow"],
	"noose":["noose_rope"],
	"gallows":["gallows"],
	"wheel":["wheel_solid"],
	"catapult":["catapult"],
	"cannon":["cannon"],
	"falling_blade":["blade_frame"],
	"crucible":["crucible"],
	"hoist":["hoist"],
	"monolith":["monolith"],
	"monolith_rig":["monolith_rig"],
	"pit_gate":["pit_gate"],
	"plinth":["plinth"],
}

static func pick(role:String,tags:Array,known:Array=[])->String:
	for prop_name in ROLES.get(role,[role]):
		if available(String(prop_name),tags,known):return String(prop_name)
	return ""

static func lid_for(prop_name:String)->String:
	return prop_name+"_lid" if not info(prop_name+"_lid").is_empty() else ""

static func _ensure()->bool:
	if _scene!=null:return true
	var path:=DIR+String(manifest().get("glb","court_exec_props.glb"))
	if not ResourceLoader.exists(path):return false
	_scene=load(path) as PackedScene
	return _scene!=null

## A prop by name, dressed by the set it will stand in (null: plain paint).
## (The props' scene is made and the rest let go: a dozen nodes, a few times
## an act; the meshes themselves are shared.)
static func make(prop_name:String,court_set:Node=null)->Node3D:
	if not _ensure():return null
	var whole:=_scene.instantiate() as Node3D
	if whole==null:return null
	var made:=whole.find_child(prop_name,true,false) as Node3D
	if made!=null:
		made.get_parent().remove_child(made)
		made.owner=null
		for child in made.find_children("*","",true,false):child.owner=null
	whole.free()
	if made==null:return null
	made.name=prop_name
	made.transform=Transform3D.IDENTITY
	made.set_meta("prop",prop_name)
	if court_set!=null and court_set.has_method("dress"):court_set.call("dress",made)
	return made

static func _vec(a:Variant)->Vector3:
	if a is Array and (a as Array).size()>=3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
	return Vector3.ZERO

## How a held thing lies in the hand (the figures' hand bones, J's rig): the
## haft runs through the fist along the bone's X (the staff's line), its head
## toward -X (above the thumb); the edge or striking face looks the way the
## hand points (+Y), and the palm is a little down the hand from the wrist.
const GRIP_BASIS:=Basis(Vector3(0,0,-1),Vector3(-1,0,0),Vector3(0,1,0))
const PALM:=Vector3(0.0,0.07,0.015)

## Put a prop in someone's hand (a figure's "hand.R" or "hand.L" bone): its
## grip in the fist, the haft through it, the head above the thumb. The
## figure's own staff or bowl in that hand is put away.
static func hold(prop:Node3D,figure:Node3D,hand:="hand.R")->bool:
	if prop==null or figure==null:return false
	var skels:=figure.find_children("*","Skeleton3D",true,false)
	if skels.is_empty():return false
	var skel:=skels[0] as Skeleton3D
	if skel.find_bone(hand)<0:return false
	var key:="Hold_"+hand.replace(".","_")
	var attach:=skel.get_node_or_null(key) as BoneAttachment3D
	if attach==null:
		attach=BoneAttachment3D.new();attach.name=key;attach.bone_name=hand
		skel.add_child(attach)
	if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
	attach.add_child(prop)
	var grip:=_vec(info(String(prop.get_meta("prop",prop.name))).get("grip",[0,0,0]))
	prop.transform=Transform3D(GRIP_BASIS,PALM-GRIP_BASIS*grip)
	for own in ["prop_staff","prop_bowl"]:
		for node in figure.find_children(own,"MeshInstance3D",true,false):(node as Node3D).visible=false
	return true

## Fly a prop from `from` to `to` (global points) over `seconds`, rising
## `arc` above the line at its middle: a stone tumbles, a spear or an arrow
## flies tip first along its arc. It is put in `into` (the set) first. The
## Tween is returned (tween_callback on it for the hit).
static func throw(prop:Node3D,into:Node,from:Vector3,to:Vector3,seconds:=0.7,arc:=0.8)->Tween:
	if prop==null or into==null or not into.is_inside_tree():return null
	if prop.get_parent()!=into:
		if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
		into.add_child(prop)
	var pointed:bool=not (info(String(prop.get_meta("prop",prop.name))).get("tip",[]) as Array).is_empty()
	var spin:=Vector3(randf_range(-9.0,9.0),randf_range(-6.0,6.0),randf_range(-9.0,9.0))
	var fly:=func(k:float)->void:
		if not is_instance_valid(prop):return
		var at:=from.lerp(to,k)+Vector3(0.0,4.0*arc*k*(1.0-k),0.0)
		if pointed:
			# along the arc's tangent, tip first
			var d:=(to-from)+Vector3(0.0,4.0*arc*(1.0-2.0*k),0.0)
			prop.global_transform=Transform3D(_along(d.normalized()),at-_along(d.normalized())*_tip(prop))
		else:
			prop.global_transform=Transform3D(Basis.from_euler(spin*k*seconds),at)
	var t:=prop.create_tween()
	t.tween_method(fly,0.0,1.0,maxf(seconds,0.05))
	return t

## Stick a pointed prop (a spear, an arrow) into what it hit: into a figure
## it rides the nearest of its chest, head or hips; into the set it stays
## where it is. `at` the hit point, `dir` the way it was flying (global).
## It quivers, then settles. Returns the node it now rides.
static func stick(prop:Node3D,into:Node3D,at:Vector3,dir:Vector3,depth:=0.12)->Node3D:
	if prop==null or into==null:return null
	var holder:Node3D=into
	var skels:=into.find_children("*","Skeleton3D",true,false)
	if not skels.is_empty():
		var skel:=skels[0] as Skeleton3D
		var best:="";var best_d:=1e9
		for bone in ["chest","spine","head","hips","pelvis","thigh.L","thigh.R","upper_arm.L","upper_arm.R"]:
			var i:=skel.find_bone(bone)
			if i<0:continue
			var d:=(skel.global_transform*skel.get_bone_global_pose(i).origin).distance_to(at)
			if d<best_d:best_d=d;best=bone
		if not best.is_empty():
			var key:="Stuck_"+best.replace(".","_")
			var attach:=skel.get_node_or_null(key) as BoneAttachment3D
			if attach==null:
				attach=BoneAttachment3D.new();attach.name=key;attach.bone_name=best
				skel.add_child(attach)
			holder=attach
	var basis:=_along(dir.normalized())
	var xf:=Transform3D(basis,at-basis*(_tip(prop)-Vector3(0.0,depth,0.0)))
	if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
	holder.add_child(prop)
	prop.global_transform=xf
	if prop.is_inside_tree():
		# it quivers where it went in, then settles
		var rest:=prop.transform
		var tip_local:=_tip(prop)-Vector3(0.0,depth,0.0)
		var quiver:=func(k:float)->void:
			if not is_instance_valid(prop):return
			var wob:=sin(k*40.0)*(1.0-k)*0.12
			var turn:=Basis(Vector3.RIGHT,wob)*Basis(Vector3.FORWARD,wob*0.6)
			prop.transform=rest*Transform3D(turn,tip_local-turn*tip_local)
		var q:=prop.create_tween()
		q.tween_method(quiver,0.0,1.0,0.9)
	return holder

static func _tip(prop:Node3D)->Vector3:
	return _vec(info(String(prop.get_meta("prop",prop.name))).get("tip",[0,0,0]))

## A basis whose +Y runs along `d` (the prop's length, tip first).
static func _along(d:Vector3)->Basis:
	if d.length_squared()<0.0001:return Basis.IDENTITY
	var y:=d.normalized()
	var x:=y.cross(Vector3.UP if absf(y.y)<0.95 else Vector3.RIGHT).normalized()
	return Basis(x,y,x.cross(y).normalized())

## Take it out of their hand and leave it where it is (top level in `into`).
static func let_go(prop:Node3D,into:Node)->void:
	if prop==null or into==null:return
	var xf:=prop.global_transform
	if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
	into.add_child(prop)
	prop.global_transform=xf

## Set a prop on another's seat ("lid_seat", "head_seat", "axe_bite", ...).
static func seat(prop:Node3D,on:Node3D,seat_name:String)->bool:
	if prop==null or on==null:return false
	var at:=_vec(info(String(on.get_meta("prop",on.name))).get(seat_name,null))
	if prop.get_parent()!=on:
		if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
		on.add_child(prop)
	var edge:Variant=info(String(prop.get_meta("prop",prop.name))).get("edge",null)
	if seat_name.ends_with("_bite") and edge!=null:
		# a blade bitten into the wood: the edge sunk a little at the seat, the
		# haft rising out of it at a slant (30 degrees up, toward -z)
		var tilt:=Basis(Vector3.RIGHT,deg_to_rad(120.0))
		prop.transform=Transform3D(tilt,at-tilt*_vec(edge)+Vector3(0.0,-0.035,0.0))
	else:
		prop.transform=Transform3D(Basis.IDENTITY,at)
	return true
