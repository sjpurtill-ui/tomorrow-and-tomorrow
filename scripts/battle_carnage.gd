class_name BattleCarnage
extends Node3D

# Fixed visual budget: one burst per fallen representative, never per soldier.
const CAPACITY := 194
const DROPS := 12
const SPLATS := 5
var events: Array[Dictionary] = []
var ground_query:Callable=Callable()
var spray: MultiMeshInstance3D
var stains: MultiMeshInstance3D
var debris: MultiMeshInstance3D

func _ready()->void:
	spray=_pool(CAPACITY*DROPS,Color("df1938"))
	stains=_pool(CAPACITY*SPLATS,Color("a30b2a"),"splat")
	debris=_pool(CAPACITY*3,Color("b99256"),"debris")

func _pool(count:int,color:Color,kind:="spray")->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new()
	var mesh:Mesh
	var material:=StandardMaterial3D.new(); material.albedo_color=color
	material.roughness=.36 if kind=="spray" else .65
	if kind=="splat":
		mesh=_splat_mesh()
		material.vertex_color_use_as_albedo=true
		material.albedo_color=Color.WHITE
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
	elif kind=="debris":
		var shield:=CylinderMesh.new(); shield.top_radius=.78; shield.bottom_radius=1.0; shield.height=.42; shield.radial_segments=12
		mesh=shield; material.metallic=.65; material.roughness=.38
	else:
		var drop:=SphereMesh.new(); drop.radius=1; drop.height=2; drop.radial_segments=12; drop.rings=5
		mesh=drop
	node.material_override=material
	var instances:=MultiMesh.new(); instances.transform_format=MultiMesh.TRANSFORM_3D; instances.mesh=mesh
	instances.instance_count=count; instances.visible_instance_count=0
	node.multimesh=instances; node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

# A scalloped silhouette and darker rim keep splats crisp at close range.
func _splat_mesh()->ArrayMesh:
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var colors:=PackedColorArray()
	for i in 28:
		var a:=TAU*float(i)/28.0
		var b:=TAU*float(i+1)/28.0
		var ra:=1.0+.22*sin(i*2.7)+.10*cos(i*1.3)
		var rb:=1.0+.22*sin(((i+1)%28)*2.7)+.10*cos(((i+1)%28)*1.3)
		vertices.append_array(PackedVector3Array([Vector3.ZERO,Vector3(cos(a)*ra,0,sin(a)*ra),Vector3(cos(b)*rb,0,sin(b)*rb)]))
		normals.append_array(PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP]))
		colors.append_array(PackedColorArray([Color("c51b37"),Color("760e25"),Color("760e25")]))
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func reset()->void:
	events.clear()
	for pool in [spray,stains,debris]: pool.multimesh.visible_instance_count=0

func burst(at:Vector3,time:float)->void:
	if events.size()>=CAPACITY: return
	events.append({"at":at,"time":time})
	spray.multimesh.visible_instance_count=events.size()*DROPS
	stains.multimesh.visible_instance_count=events.size()*SPLATS
	debris.multimesh.visible_instance_count=events.size()*3
	update_effects(time)

func update_effects(time:float)->void:
	for index in events.size():
		var event:Dictionary=events[index]
		var age:=maxf(0,time-float(event.time))
		var origin:Vector3=event.at
		for i in DROPS:
			var angle:=i*2.399+index*.71
			var speed:=1.8+float((i*7+index)%6)*.48
			var t:=minf(age,1.6)
			var position:=origin+Vector3(cos(angle)*speed*t,1.1+(3.5+(i%4)*.65)*t-5.8*t*t,sin(angle)*speed*t)
			var radius:=.13+(i%3)*.055
			var scale:=Vector3(radius,radius*1.8,radius) if position.y>origin.y+.06 and age<1.6 else Vector3.ZERO
			spray.multimesh.set_instance_transform(index*DROPS+i,Transform3D(Basis.IDENTITY.scaled(scale),position))
		for i in SPLATS:
			var angle:=i*2.399+index
			var spread:=0.0 if i==0 else .55+i*.32
			var size:=(.9 if i==0 else .28+i*.055)*clampf(age*3,0,1)
			var position:=Vector3(origin.x+cos(angle)*spread,.025+(index%5)*.001,origin.z+sin(angle)*spread)
			if ground_query.is_valid(): position.y+=float(ground_query.call(Vector2(position.x,position.z)))
			stains.multimesh.set_instance_transform(index*SPLATS+i,Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(size,1.0,size*.7)),position))
		for i in 3:
			var t:=minf(age,1.3)
			var angle:=index*.9+i*2.1
			var position:=origin+Vector3(cos(angle)*t*2.7,maxf(.12,1.0+4.0*t-5*t*t),sin(angle)*t*2.7)
			var basis:=Basis(Vector3(1,.3,.5).normalized(),t*9+i).scaled(Vector3(.23,.10,.3))
			debris.multimesh.set_instance_transform(index*3+i,Transform3D(basis,position))
