extends RefCounted
## Human-scale silhouettes, one colored mesh per landmark, no per-piece nodes.
const C=preload("res://scripts/undertaking_catalog.gd")
static func signature(cities:Array)->String:
	var parts:Array=[]
	for city:Dictionary in cities:
		for r:Dictionary in city.get("undertakings",[]):
			parts.append([city.get("id",""),city.get("position"),r.id,r.status,r.get("custom_name",""),floori(float(r.progress)/float(C.get_definition(r.id).work)*10),floori(float(r.condition)*5),r.get("site",{})])
	return str(hash(parts))

static func render(cities:Array,parent:Node3D,height:Callable)->void:
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=1
	for city:Dictionary in cities:
		var point:Vector2=city.get("position",Vector2.ZERO)
		var index:=0
		for r:Dictionary in city.get("undertakings",[]):
			var d:=C.get_definition(String(r.id))
			if d.is_empty():continue
			var site:Dictionary=r.get("site",{"position":point+Vector2(.18+index*.12,.16),"angle":0.0})
			index+=1
			var p:Vector2=site.position
			var origin:=Vector3(p.x,float(height.call(p.x,p.y)),p.y)
			var root:=Node3D.new();root.name="Undertaking_"+String(r.id);root.position=origin;parent.add_child(root)
			var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var pieces:=forms(String(r.id),String(d.form))
			var progress:=clampf(float(r.progress)/float(d.work),0,1)
			var count:=maxi(1,ceili(float(pieces.size())*progress))
			var ruin:bool=r.status in ["ruined","abandoned"]
			for i in mini(count,pieces.size()):
				var part:Dictionary=pieces[i].duplicate()
				if ruin:
					part.size.y*=.2+.12*(i%3);part.position.y*=.25
					part.color=(part.color as Color).lerp(Color("706856"),.65)
				elif progress<1 and i==count-1:part.size.y*=.3
				append_piece(surface,part,origin,float(site.angle),height)
			surface.generate_normals()
			var mesh:=MeshInstance3D.new();mesh.name="Landmark";mesh.mesh=surface.commit();mesh.material_override=material;mesh.visibility_range_end=20;root.add_child(mesh)
			var label:=Label3D.new();label.name="Name"
			label.text=preload("res://scripts/undertaking_system.gd").display_name(r)+"\n"+("Under construction" if r.status=="building" else String(r.status).capitalize())
			label.font_size=32;label.pixel_size=.00008;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false
			label.position.y=.034;label.modulate=Color("f3e4bc");label.outline_modulate=Color("242c29");label.outline_size=8;label.visibility_range_end=8;root.add_child(label)

static func forms(id:String,shape:String)->Array:
	var result:Array=[]
	var stone:=Color("9b917a");var clay:=Color("ac8054");var wood:=Color("72553a");var thatch:=Color("a99b64")
	result.append(piece(Vector3.ZERO,Vector3(.085,.0007,.065),Color("796c50")))
	match shape:
		"ring":
			for i in 12:
				if id=="safe_passage" and i in [0,6]:continue
				var a:=TAU*i/12
				result.append(piece(Vector3(cos(a)*.035,0,sin(a)*.028),Vector3(.004,.009 if id=="ancestor_ring" else .004,.004),stone))
			if id=="safe_passage":
				for x in [-.023,.023]:result.append(piece(Vector3(x,.004,0),Vector3(.012,.005,.023),thatch,"roof"))
		"orchard":
			for row in 4:
				for col in 5:
					if row==0 and col==2:continue
					var p:=Vector3((col-2)*.016,0,(row-1.5)*.018)
					result.append(piece(p,Vector3(.0015,.004,.0015),wood))
					result.append(piece(p+Vector3(0,.003,0),Vector3(.012,.009,.012),Color("536840"),"dome"))
		"kilns":
			for i in 8:result.append(piece(Vector3((i%4-1.5)*.019,0,(-1 if i<4 else 1)*.022),Vector3(.012,.008,.012),clay,"dome"))
		"basin":
			for x in [-.034,.034]:result.append(piece(Vector3(x,0,0),Vector3(.004,.003,.06),stone))
			for z in [-.028,.028]:result.append(piece(Vector3(0,0,z),Vector3(.068,.003,.004),stone))
			# Capacity alone must not depict water that isn't there.
			result.append(piece(Vector3(0,.0008,0),Vector3(.061,.0004,.049),clay))
		"terrace", "mound":
			for i in 4:result.append(piece(Vector3(0,i*.003,0),Vector3(.085-i*.016,.003,.065-i*.012),Color("647249") if id=="flood_terraces" else stone))
			if id=="star_steps":
				for x in [-.011,.011]:result.append(piece(Vector3(x,.012,0),Vector3(.003,.007,.003),stone))
		"granary":
			for i in 3:
				var x:=float(i-1)*.027
				for z in [-.011,.011]:result.append(piece(Vector3(x,0,z),Vector3(.004,.003,.004),stone))
				result.append(piece(Vector3(x,.003,0),Vector3(.020,.006,.027),clay))
				result.append(piece(Vector3(x,.009,0),Vector3(.023,.007,.031),thatch,"roof"))
		_:
			var wings:=2 if id=="measures_house" else 1
			for i in wings:
				var x:=0.0 if wings==1 else (i-.5)*.041
				result.append(piece(Vector3(x,0,0),Vector3(.027,.006,.055),wood))
				result.append(piece(Vector3(x,.006,0),Vector3(.034,.011,.063),thatch,"roof"))
				for j in 4:result.append(piece(Vector3(x-.019,0,(j-1.5)*.014),Vector3(.0015,.006,.0015),wood))
	return result

static func piece(position:Vector3,size:Vector3,color:Color,kind:String="box")->Dictionary:
	return {"position":position,"size":size,"color":color,"kind":kind}

static func append_piece(surface:SurfaceTool,part:Dictionary,origin:Vector3,angle:float,height:Callable)->void:
	var vertices:PackedVector3Array;var indices:PackedInt32Array
	if part.kind=="roof":
		vertices=PackedVector3Array([Vector3(-.5,0,-.5),Vector3(.5,0,-.5),Vector3(0,1,-.5),Vector3(-.5,0,.5),Vector3(.5,0,.5),Vector3(0,1,.5)])
		indices=PackedInt32Array([0,2,1,3,4,5,0,3,5,0,5,2,1,2,5,1,5,4,0,1,4,0,4,3])
	else:
		var mesh:PrimitiveMesh
		if part.kind=="dome":
			var dome:=SphereMesh.new();dome.radius=.5;dome.height=1;dome.radial_segments=8;dome.rings=3;mesh=dome
		else:mesh=BoxMesh.new()
		var arrays:=mesh.surface_get_arrays(0);vertices=arrays[Mesh.ARRAY_VERTEX];indices=arrays[Mesh.ARRAY_INDEX]
		for i in vertices.size():vertices[i].y+=.5
	var local:Vector3=part.position
	var ground_point:=Vector2(local.x,local.z).rotated(angle)+Vector2(origin.x,origin.z)
	var base:float=float(height.call(ground_point.x,ground_point.y))-origin.y
	for i in indices:
		var v:Vector3=vertices[i]*Vector3(part.size)+local
		var rotated:=Vector2(v.x,v.z).rotated(angle)
		surface.set_color(part.color);surface.add_vertex(Vector3(rotated.x,v.y+base+.0005,rotated.y))
