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

## Whether the people can have this prop (what it needs, among their era tags).
static func available(prop_name:String,tags:Array)->bool:
	for need in info(prop_name).get("needs",[]):
		if not tags.has(String(need)):return false
	return not info(prop_name).is_empty()

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
	"trophy_stake":["skull_stake"],
}

static func pick(role:String,tags:Array)->String:
	for prop_name in ROLES.get(role,[role]):
		if available(String(prop_name),tags):return String(prop_name)
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
