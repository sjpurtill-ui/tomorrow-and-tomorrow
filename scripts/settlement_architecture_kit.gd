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
	if installed_features(plot)&1:family="timber"
	var type:=posmod(int(plot.get("seed",plot.get("id",1))),4)
	if use=="market":type=4
	elif use in ["civic","communal","sacred"]:type=5
	elif use in ["workshop","dirty_industry"]:type=6
	elif use=="storage":type=7
	return family+"_"+TYPES[type]

static func floors(plot:Dictionary)->int:
	return clampi(int(plot.get("storeys",1)),1,18)

static func mesh_for(name:String,storeys:int=3,features:int=0)->ArrayMesh:
	var key:=name+":"+str(storeys)+":"+str(features)
	if cache.has(key):return cache[key]
	var modern:=name.begins_with("modern_")
	var industrial:=name.begins_with("industrial_")
	var type:=name.get_slice("_",1)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall:Color=Color("d3c8b0") if not industrial else Color("a46650")
	if modern:wall=Color("d9d9d0")
	if name.begins_with("timber_"):wall=Color("9a7959")
	var trim:=Color("eee0c6") if not modern else Color("eef1e9")
	var glass:=Color("365058") if not modern else Color("658f9b")
	var roof:=Color("655a51") if industrial else Color("976c55")
	if modern:roof=Color("6d7b77")
	var height:=3.1*storeys
	match type:
		"courtyard":
			_block(surface,Vector3(-3,0,0),Vector3(2,height,10),wall,glass,trim,features)
			_block(surface,Vector3(3,0,0),Vector3(2,height,10),wall,glass,trim,features)
			_block(surface,Vector3(0,0,-4),Vector3(4,height,2),wall,glass,trim,features)
			_box(surface,Vector3(0,.12,0),Vector3(3,.24,5),Color("71845c"))
		"corner":
			_block(surface,Vector3(-1.5,0,0),Vector3(5,height,10),wall,glass,trim,features)
			_block(surface,Vector3(2.5,0,2.7),Vector3(3,height*.78,4.6),wall,glass,trim,features)
		"villa":
			_block(surface,Vector3(0,0,-1),Vector3(7,height*.75,7),wall,glass,trim,features)
			_box(surface,Vector3(0,.18,3.1),Vector3(7,.36,2.5),trim)
			for x in [-2.6,2.6]:_box(surface,Vector3(x,1.4,3.3),Vector3(.22,2.8,.22),trim)
			_box(surface,Vector3(0,2.8,3.1),Vector3(7,.24,2.5),roof)
		"arcade":
			_block(surface,Vector3(0,0,-1),Vector3(8,height,7),wall,glass,trim,features)
			for x in [-3.5,-1.2,1.2,3.5]:_box(surface,Vector3(x,1.6,3.7),Vector3(.32,3.2,.32),trim)
			_box(surface,Vector3(0,3.3,3.5),Vector3(8,.4,2.8),roof)
		"hall":
			_block(surface,Vector3(0,0,-1.5),Vector3(8,height,6.5),wall,glass,trim,features)
			for x in [-3,3]:_block(surface,Vector3(x,0,2.5),Vector3(2,height*.6,5),wall,glass,trim,features)
			_box(surface,Vector3(0,.18,3),Vector3(4,.36,4),trim)
			if modern:_box(surface,Vector3(0,height+.8,-1.5),Vector3(6,1.6,4),glass)
			else:_roof(surface,Vector3(0,height,-1.5),Vector2(8.4,6.9),1.7,roof)
		"workshop", "warehouse":
			height=maxf(4,minf(height,9))
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim,features)
			if type=="workshop":
				for z in [-3.4,0,3.4]:_roof(surface,Vector3(0,height,z),Vector2(8.2,3.2),1.0,roof)
				if industrial:_box(surface,Vector3(3,height*.9,-3.5),Vector3(.8,height*1.8,.8),wall.darkened(.18))
			else:_roof(surface,Vector3(0,height,0),Vector2(8.4,10.4),1.2,roof)
			_box(surface,Vector3(0,1.6,5.05),Vector3(3.8,3.2,.18),Color("505859"))
		_:
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim,features)
			if modern and storeys>=5:
				_block(surface,Vector3(0,height,0),Vector3(5,3.1,7),wall,glass,trim,features)
			else:_roof(surface,Vector3(0,height,0),Vector2(8.4,10.4),1.4 if not modern else .18,roof)
	if modern and type not in ["workshop","warehouse"]:
		# Roof gardens and raised parapets retain readable, restrained roof detail.
		_box(surface,Vector3(-2,height+.22,-2.6),Vector3(2.2,.44,2.4),Color("6d875b"))
	surface.generate_normals()
	var mesh:=surface.commit();cache[key]=mesh;return mesh

static func _block(s:SurfaceTool,base:Vector3,size:Vector3,wall:Color,glass:Color,trim:Color,features:int=0)->void:
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
	if features:
		var bounds:=AABB(base-Vector3(size.x*.5,0,size.z*.5),size)
		s.append_from(detail_mesh(bounds,features,1.0),0,Transform3D.IDENTITY)
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
		var key:=name+":"+str(floors(record.plot))+":"+str(installed_features(record.plot))
		if not groups.has(key):groups[key]=[]
		groups[key].append(record)
	for key:String in groups:
		var group:Array=groups[key];var first:Dictionary=group[0]
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=mesh_for_plot(first.plot);batch.instance_count=group.size()
		for i in group.size():
			var record:Dictionary=group[i];var point:Vector2=record.position+Vector2(center.x,center.z)
			batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(record.angle)).scaled(Vector3.ONE*.001),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y)))
			var wear:=1-clampf(float(record.plot.get("condition",1)),0,1)
			var tint:Color=[Color("fff7e8"),Color("e8eee6"),Color("e7e1d9"),Color("eedbd0")][posmod(int(record.plot.get("seed",1)),4)]
			batch.set_instance_color(i,tint.lerp(Color("554b40"),wear*.6))
		var node:=MultiMeshInstance3D.new();node.name="SettlementArchitecture_"+key;node.multimesh=batch;node.material_override=material;parent.add_child(node)

static func installed_features(plot:Dictionary)->int:
	var installed:Variant=plot.get("fabric_components",{})
	if not installed is Dictionary:return 0
	var flags:=0
	var mapping:Dictionary={"timber_post_beam_connections":1,"timber_splice_connections":1,"timber_lateral_bracing":2,"timber_moisture_movement_design":4,"building_drainage_coordination":8,"roof_flashing_interfaces":16,"rainscreen_wall_assemblies":32,"building_shading_design":64,"building_capillary_breaks":128}
	for method:String in mapping:
		if not installed.has(method):continue
		var record:Variant=installed[method]
		if preload("res://scripts/settlement_fabric_operations.gd").valid_record(record,int(plot.get("id",0)),true) and record.job.method==method:
			flags|=int(mapping[method])
	return flags

static func mesh_for_plot(plot:Dictionary)->ArrayMesh:
	return mesh_for(kind(plot),floors(plot),installed_features(plot))

static func _add_installed_details(surface:SurfaceTool,height:float,flags:int)->void:
	var wood:=Color("624831")
	if flags&1:
		for x in [-3.8,-1.2,1.2,3.8]:_box(surface,Vector3(x,height*.5,5.12),Vector3(.18,height,.18),wood)
		_box(surface,Vector3(0,height-.12,5.12),Vector3(8,.22,.18),wood)
	if flags&2:
		var bottom:=Vector3(-3.5,.35,5.15)
		var top:=Vector3(-.5,minf(height-.3,2.7),5.15)
		var delta:=top-bottom
		var brace:=BoxMesh.new();brace.size=Vector3(.18,delta.length(),.18)
		var arrays:=brace.get_mesh_arrays()
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var rotation:=Basis(Vector3.BACK,atan2(-delta.x,delta.y))
		for index in indices:
			surface.set_color(wood);surface.add_vertex(rotation*vertices[index]+(bottom+top)*.5)
	if flags&4:_box(surface,Vector3(0,height*.5,5.14),Vector3(.06,height,.08),Color("302e29"))
	if flags&8:
		_box(surface,Vector3(4.3,.1,0),Vector3(.35,.2,10.8),Color("827969"))
		_box(surface,Vector3(4.3,height*.5,4.8),Vector3(.16,height,.16),Color("827969"))
	if flags&16:_box(surface,Vector3(0,height+.04,5.12),Vector3(8.4,.08,.28),Color("977251"))
	if flags&32:
		for x in 16:
			if x in [6,7,8,9]:continue # Retain the central entrance.
			_box(surface,Vector3(-3.75+float(x)*.5,height*.5,5.2),Vector3(.34,height,.12),Color("a28b6c"))
	if flags&64:
		var shade_height:=minf(2.5,height*.85)
		for x in 9:_box(surface,Vector3(-3.6+float(x)*.9,shade_height,5.65),Vector3(.18,.12,1.3),wood)
		_box(surface,Vector3(0,shade_height,6.22),Vector3(8,.12,.12),wood)
	if flags&128:_box(surface,Vector3(0,.18,0),Vector3(8.2,.12,10.2),Color("524e46"))

static func detail_mesh(bounds:AABB,features:int,wall_ratio:float=.8)->ArrayMesh:
	var key:="details:"+str(bounds)+":"+str(features)+":"+str(wall_ratio)
	if cache.has(key):return cache[key]
	var raw:=SurfaceTool.new();raw.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_installed_details(raw,maxf(.5,bounds.size.y*wall_ratio),features)
	raw.generate_normals()
	var source:=raw.commit()
	var baked:=SurfaceTool.new()
	var scale:=Vector3(maxf(.1,bounds.size.x)/8.0,1.0,maxf(.1,bounds.size.z)/10.0)
	var origin:=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	baked.append_from(source,0,Transform3D(Basis.from_scale(scale),origin))
	var result:=baked.commit();cache[key]=result;return result

static func early_detail_mesh(bounds:AABB,name:String,features:int)->ArrayMesh:
	# Finite authored asset profiles: roof envelopes are not wall dimensions.
	var round_wall:=name=="round_household"
	var ratio:=.58 if round_wall else (.9 if name in ["earthen_household","rubble_household","covered_workshop","raised_store"] else .55)
	var width_ratio:=.88 if round_wall else .9
	var size:=Vector3(bounds.size.x*width_ratio,bounds.size.y*ratio,bounds.size.z*width_ratio)
	var center:=bounds.get_center()
	var walls:=AABB(Vector3(center.x-size.x*.5,bounds.position.y,center.z-size.z*.5),size)
	var source:=detail_mesh(walls,features,1.0)
	if not round_wall:return source
	var key:="round_details:"+str(bounds)+":"+str(features)
	if cache.has(key):return cache[key]
	var arrays:=source.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	if indices.is_empty():
		for i in vertices.size():indices.append(i)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var v:=vertices[index]
		var relative_x:float=(v.x-center.x)/maxf(.1,size.x*.5)
		if v.z>center.z+size.z*.4 and absf(relative_x)<=1.0:
			v.z+=size.z*.5*(sqrt(maxf(0,1-relative_x*relative_x))-1.0)
		surface.set_color(colors[index]);surface.add_vertex(v)
	surface.generate_normals()
	var mesh:=surface.commit();cache[key]=mesh;return mesh
