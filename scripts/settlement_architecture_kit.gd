extends RefCounted
## Detailed, neutral building families for completed, recorded settlement fabric.
## Metres in cached meshes; existing parcel placement remains authoritative.
const FAMILIES := ["masonry", "industrial", "modern"]
const TYPES := ["terrace", "courtyard", "corner", "villa", "arcade", "hall", "workshop", "warehouse"]
static var cache:Dictionary={}
static var material:StandardMaterial3D

static func kind(plot:Dictionary)->String:
	var generation:=int(plot.get("fabric_generation",0))
	if generation<4:return ""
	var use:=String(plot.get("land_use",""))
	if use not in ["residential_compound","mixed_household","market","civic","communal","sacred","workshop","storage","dirty_industry","hospitality"]:return ""
	var family:="modern" if generation>=12 else ("industrial" if generation>=11 else "masonry")
	var type:=posmod(int(plot.get("seed",plot.get("id",1))),4)
	if use=="market":type=4
	elif use in ["civic","communal","sacred"]:type=5
	elif use in ["workshop","dirty_industry"]:type=6
	elif use=="storage":type=7
	return family+"_"+TYPES[type]

static func floors(plot:Dictionary)->int:
	return clampi(int(plot.get("storeys",1)),1,18)

static func mesh_for(name:String,storeys:int=3)->ArrayMesh:
	var key:=name+":"+str(storeys)
	if cache.has(key):return cache[key]
	var modern:=name.begins_with("modern_")
	var industrial:=name.begins_with("industrial_")
	var type:=name.get_slice("_",1)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall:Color=Color("d3c8b0") if not industrial else Color("a46650")
	if modern:wall=Color("d9d9d0")
	var trim:=Color("eee0c6") if not modern else Color("eef1e9")
	var glass:=Color("365058") if not modern else Color("658f9b")
	var roof:=Color("655a51") if industrial else Color("976c55")
	if modern:roof=Color("6d7b77")
	var height:=3.1*storeys
	match type:
		"courtyard":
			_block(surface,Vector3(-3,0,0),Vector3(2,height,10),wall,glass,trim)
			_block(surface,Vector3(3,0,0),Vector3(2,height,10),wall,glass,trim)
			_block(surface,Vector3(0,0,-4),Vector3(4,height,2),wall,glass,trim)
			_box(surface,Vector3(0,.12,0),Vector3(3,.24,5),Color("71845c"))
		"corner":
			_block(surface,Vector3(-1.5,0,0),Vector3(5,height,10),wall,glass,trim)
			_block(surface,Vector3(2.5,0,2.7),Vector3(3,height*.78,4.6),wall,glass,trim)
		"villa":
			_block(surface,Vector3(0,0,-1),Vector3(7,height*.75,7),wall,glass,trim)
			_box(surface,Vector3(0,.18,3.1),Vector3(7,.36,2.5),trim)
			for x in [-2.6,2.6]:_box(surface,Vector3(x,1.4,3.3),Vector3(.22,2.8,.22),trim)
			_box(surface,Vector3(0,2.8,3.1),Vector3(7,.24,2.5),roof)
		"arcade":
			_block(surface,Vector3(0,0,-1),Vector3(8,height,7),wall,glass,trim)
			for x in [-3.5,-1.2,1.2,3.5]:_box(surface,Vector3(x,1.6,3.7),Vector3(.32,3.2,.32),trim)
			_box(surface,Vector3(0,3.3,3.5),Vector3(8,.4,2.8),roof)
		"hall":
			_block(surface,Vector3(0,0,-1.5),Vector3(8,height,6.5),wall,glass,trim)
			for x in [-3,3]:_block(surface,Vector3(x,0,2.5),Vector3(2,height*.6,5),wall,glass,trim)
			_box(surface,Vector3(0,.18,3),Vector3(4,.36,4),trim)
			if modern:_box(surface,Vector3(0,height+.8,-1.5),Vector3(6,1.6,4),glass)
			else:_roof(surface,Vector3(0,height,-1.5),Vector2(8.4,6.9),1.7,roof)
		"workshop", "warehouse":
			height=maxf(4,minf(height,9))
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim)
			if type=="workshop":
				for z in [-3.4,0,3.4]:_roof(surface,Vector3(0,height,z),Vector2(8.2,3.2),1.0,roof)
				if industrial:_box(surface,Vector3(3,height*.9,-3.5),Vector3(.8,height*1.8,.8),wall.darkened(.18))
			else:_roof(surface,Vector3(0,height,0),Vector2(8.4,10.4),1.2,roof)
			_box(surface,Vector3(0,1.6,5.05),Vector3(3.8,3.2,.18),Color("505859"))
		_:
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim)
			if modern and storeys>=5:
				_block(surface,Vector3(0,height,0),Vector3(5,3.1,7),wall,glass,trim)
			else:_roof(surface,Vector3(0,height,0),Vector2(8.4,10.4),1.4 if not modern else .18,roof)
	if modern and type not in ["workshop","warehouse"]:
		# Roof gardens and raised parapets retain readable, restrained roof detail.
		_box(surface,Vector3(-2,height+.22,-2.6),Vector3(2.2,.44,2.4),Color("6d875b"))
	surface.generate_normals()
	var mesh:=surface.commit();cache[key]=mesh;return mesh

static func _block(s:SurfaceTool,base:Vector3,size:Vector3,wall:Color,glass:Color,trim:Color)->void:
	_box(s,base+Vector3(0,size.y*.5,0),size,wall)
	var floors:=maxi(1,floori(size.y/3.1))
	for floor in floors:
		var y:=base.y+1.7+floor*3.1
		for side in [-1,1]:
			for x in range(maxi(1,floori(size.x/2))):
				var offset:=-size.x*.5+(x+.5)*size.x/maxi(1,floori(size.x/2))
				_box(s,Vector3(base.x+offset,y,base.z+side*(size.z*.5+.025)),Vector3(.85,1.35,.06),glass)
			for z in range(maxi(1,floori(size.z/2.5))):
				var offset:=-size.z*.5+(z+.5)*size.z/maxi(1,floori(size.z/2.5))
				_box(s,Vector3(base.x+side*(size.x*.5+.025),y,base.z+offset),Vector3(.06,1.35,.85),glass)
		_box(s,base+Vector3(0,(floor+1)*3.1-.08,0),Vector3(size.x+.12,.16,size.z+.12),trim)
	_box(s,base+Vector3(0,1.05,size.z*.5+.05),Vector3(.9,2.1,.12),Color("514e44"))
static func _box(s:SurfaceTool,center:Vector3,size:Vector3,color:Color)->void:
	var box:=BoxMesh.new();box.size=size
	var arrays:=box.get_mesh_arrays();var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in indices:s.set_color(color);s.add_vertex(vertices[i]+center)
static func _roof(s:SurfaceTool,base:Vector3,size:Vector2,rise:float,color:Color)->void:
	var a:=base+Vector3(-size.x*.5,0,-size.y*.5);var b:=base+Vector3(size.x*.5,0,-size.y*.5)
	var c:=base+Vector3(size.x*.5,0,size.y*.5);var d:=base+Vector3(-size.x*.5,0,size.y*.5)
	var e:=base+Vector3(0,rise,-size.y*.5);var f:=base+Vector3(0,rise,size.y*.5)
	for v in [a,d,f,a,f,e,e,f,c,e,c,b,a,e,b,d,c,f]:s.set_color(color);s.add_vertex(v)

static func render(plan:Dictionary,center:Vector3,height:Callable,parent:Node3D)->void:
	if material==null:
		material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.78;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var groups:Dictionary={}
	for record:Dictionary in plan.buildings:
		var name:=kind(record.plot)
		if name=="" or String(record.plot.get("status","active")) in ["ruin","reclaimed","under_construction"]:continue
		if float(record.plot.get("damage",{}).get("structural",0))>.65:continue
		var key:=name+":"+str(floors(record.plot))
		if not groups.has(key):groups[key]=[]
		groups[key].append(record)
	for key:String in groups:
		var group:Array=groups[key];var first:Dictionary=group[0]
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=mesh_for(kind(first.plot),floors(first.plot));batch.instance_count=group.size()
		for i in group.size():
			var record:Dictionary=group[i];var point:Vector2=record.position+Vector2(center.x,center.z)
			batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(record.angle)).scaled(Vector3.ONE*.001),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y)))
			var wear:=1-clampf(float(record.plot.get("condition",1)),0,1)
			var tint:Color=[Color("fff7e8"),Color("e8eee6"),Color("e7e1d9"),Color("eedbd0")][posmod(int(record.plot.get("seed",1)),4)]
			batch.set_instance_color(i,tint.lerp(Color("554b40"),wear*.6))
		var node:=MultiMeshInstance3D.new();node.name="SettlementArchitecture_"+key;node.multimesh=batch;node.material_override=material;parent.add_child(node)
