extends Node3D
## The god's rites, visible on the map for a few days: a great fire, a funeral
## fire, a cairn, a standing stone or a procession around the camp. Presentation
## only; court_lives.gd decides which rites are burning. At most three show at
## once, each a handful of procedural meshes (no image assets, no lights).

const LIVES_PATH:="res://scripts/court_lives.gd"
const NODE_NAME:="RiteMarks"
const UNIT:=0.001            ## one metre in map units
const RING:=0.03             ## rites stand about 30 m from the camp centre

var terrain:Node3D
var signature:=""
var _clock:=0.0
var _flames:Array[Node3D]=[]
var _glows:Array[MeshInstance3D]=[]
var _rings:Array[Node3D]=[]
static var _materials:Dictionary={}

static func refresh(host:Node3D)->void:
	## Called once per committed day by the map. Cheap when nothing changed.
	if host==null or not is_instance_valid(host): return
	if not "Hearth Circle" in GameState.settlement_completed: return
	var marks:=host.get_node_or_null(NODE_NAME) as Node3D
	if marks==null:
		marks=(load("res://scripts/rite_marks.gd") as GDScript).new()
		marks.name=NODE_NAME
		marks.set("terrain",host)
		host.add_child(marks)
	marks.call("rebuild")

func rebuild()->void:
	var lives:=load(LIVES_PATH) as GDScript
	if lives==null: return
	var rites:Array=lives.call("active_rites",-1)
	var keys:PackedStringArray=PackedStringArray()
	for rite in rites: keys.append("%s|%d|%d" % [String(rite.get("kind","")),int(rite.get("day",0)),int(rite.get("slot",0))])
	var next:="|".join(keys)
	if next==signature: return
	signature=next
	for child in get_children(): child.queue_free()
	_flames.clear(); _glows.clear(); _rings.clear()
	var center:Vector3=GameState.settlement_founded_at
	for rite_variant in rites:
		var rite:Dictionary=rite_variant
		var kind:=String(rite.get("kind","cairn"))
		var angle:=float(int(rite.get("slot",0)))*TAU/8.0
		var at:=Vector2(center.x,center.z)+Vector2(cos(angle),sin(angle))*RING
		if kind=="procession": at=Vector2(center.x,center.z)
		var root:=Node3D.new(); root.name="Rite_%s_%d" % [kind,int(rite.get("day",0))]
		root.position=Vector3(at.x,_height(at.x,at.y),at.y)
		root.set_meta("rite",rite.duplicate())
		add_child(root)
		match kind:
			"bonfire": _fire(root,1.0)
			"pyre": _pyre(root)
			"stone": _stone(root)
			"procession": _procession(root)
			_: _cairn(root)

func _height(x:float,z:float)->float:
	if terrain!=null and is_instance_valid(terrain) and terrain.has_method("_height_at"): return float(terrain.call("_height_at",x,z))
	return 0.0

static func _material(key:String,color:Color,emission:float=0.0,alpha:float=1.0)->StandardMaterial3D:
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(color.r,color.g,color.b,alpha)
	m.roughness=0.95
	if alpha<1.0:
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission>0.0:
		m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=emission
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[key]=m
	return m

func _mesh(parent:Node3D,mesh:Mesh,material:Material,at:Vector3,rotation_y:float=0.0)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.mesh=mesh; node.material_override=material
	node.position=at; node.rotation.y=rotation_y
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _fire(root:Node3D,size:float)->void:
	var stones:=SphereMesh.new(); stones.radius=0.35*UNIT*size; stones.height=0.5*UNIT*size; stones.radial_segments=6; stones.rings=3
	for i in 8:
		var a:=float(i)*TAU/8.0
		_mesh(root,stones,_material("stone",Color(0.42,0.40,0.37)),Vector3(cos(a),0.1,sin(a))*1.6*UNIT*size)
	var flame_root:=Node3D.new(); flame_root.name="Flame"; root.add_child(flame_root)
	var flame:=CylinderMesh.new(); flame.top_radius=0.0; flame.bottom_radius=1.1*UNIT*size; flame.height=3.2*UNIT*size; flame.radial_segments=7
	_mesh(flame_root,flame,_material("flame",Color(1.0,0.55,0.16),2.4),Vector3(0,1.6*UNIT*size,0))
	var core:=CylinderMesh.new(); core.top_radius=0.0; core.bottom_radius=0.6*UNIT*size; core.height=2.0*UNIT*size; core.radial_segments=6
	_mesh(flame_root,core,_material("core",Color(1.0,0.85,0.45),3.0),Vector3(0,1.0*UNIT*size,0),0.5)
	_flames.append(flame_root)
	var smoke:=CylinderMesh.new(); smoke.top_radius=3.5*UNIT; smoke.bottom_radius=0.8*UNIT; smoke.height=26.0*UNIT; smoke.radial_segments=8
	_mesh(root,smoke,_material("smoke",Color(0.55,0.55,0.55),0.0,0.13),Vector3(0,16.0*UNIT,0))
	# Firelight on the ground: a soft unshaded glow, not a scene light (a real
	# light at map scale floods the whole camp white).
	var glow:=CylinderMesh.new(); glow.top_radius=4.5*UNIT*size; glow.bottom_radius=4.5*UNIT*size; glow.height=0.05*UNIT; glow.radial_segments=16
	var glow_node:=_mesh(root,glow,_material("glow",Color(1.0,0.6,0.25),0.0,0.22),Vector3(0,0.05*UNIT,0))
	_glows.append(glow_node)

func _pyre(root:Node3D)->void:
	var log_mesh:=BoxMesh.new(); log_mesh.size=Vector3(3.6,0.5,0.5)*UNIT
	for layer in 3:
		for i in 3:
			var offset:=(float(i)-1.0)*0.9*UNIT
			var at:=Vector3(offset,(0.3+float(layer)*0.5)*UNIT,0) if layer%2==0 else Vector3(0,(0.3+float(layer)*0.5)*UNIT,offset)
			_mesh(root,log_mesh,_material("wood",Color(0.36,0.25,0.16)),at,0.0 if layer%2==0 else PI*0.5)
	var top:=Node3D.new(); top.position=Vector3(0,1.6*UNIT,0); root.add_child(top)
	_fire(top,0.8)

func _cairn(root:Node3D)->void:
	var radii:=[1.3,1.05,0.8,0.6,0.42]
	var y:=0.0
	for i in radii.size():
		var r:=float(radii[i])*UNIT
		var stone:=SphereMesh.new(); stone.radius=r; stone.height=r*1.3; stone.radial_segments=7; stone.rings=4
		_mesh(root,stone,_material("cairn",Color(0.55,0.53,0.49)),Vector3(sin(float(i)*1.7)*0.12*UNIT,y+r*0.6,cos(float(i)*1.3)*0.12*UNIT))
		y+=r*1.15

func _stone(root:Node3D)->void:
	var slab:=BoxMesh.new(); slab.size=Vector3(1.4,5.2,0.7)*UNIT
	var node:=_mesh(root,slab,_material("standing",Color(0.33,0.33,0.34)),Vector3(0,2.5*UNIT,0),0.4)
	node.rotation.z=0.05
	_cairn(root)

func _procession(root:Node3D)->void:
	var ring:=Node3D.new(); ring.name="Walkers"; root.add_child(ring)
	var walker:=CapsuleMesh.new(); walker.radius=0.26*UNIT; walker.height=1.7*UNIT; walker.radial_segments=6; walker.rings=2
	for i in 12:
		var a:=float(i)*TAU/12.0
		var at:=Vector3(cos(a),0,sin(a))*14.0*UNIT
		var h:=_height(root.position.x+at.x,root.position.z+at.z)-root.position.y
		_mesh(ring,walker,_material("walker",Color(0.47,0.36,0.26)),at+Vector3(0,h+0.85*UNIT,0))
	_rings.append(ring)
	var torch:=Node3D.new(); torch.position=Vector3(0,0,0); root.add_child(torch)
	_fire(torch,0.7)

func _process(delta:float)->void:
	if _flames.is_empty() and _rings.is_empty(): return
	_clock+=delta
	for i in _flames.size():
		var flame:=_flames[i]
		if not is_instance_valid(flame): continue
		var s:=1.0+0.12*sin(_clock*9.0+float(i)*1.7)+0.06*sin(_clock*23.0+float(i))
		flame.scale=Vector3(1.0,s,1.0)
	for i in _glows.size():
		if is_instance_valid(_glows[i]): _glows[i].scale=Vector3.ONE*(1.0+0.06*sin(_clock*11.0+float(i)*2.1))
	for ring in _rings:
		if is_instance_valid(ring): ring.rotation.y+=delta*0.08
