extends RefCounted
## Human-scale silhouettes, one colored mesh per landmark, no per-piece nodes.
const C=preload("res://scripts/undertaking_catalog.gd")
const SHAPE_ALIASES:={"stair":"terrace","cistern":"basin","garden":"orchard","archive":"hall","library":"hall"}
const MATERIAL_TINTS:={"stone":Color("9b917a"),"brick":Color("9a5f45"),"timber":Color("72553a"),"earth":Color("a07f55"),"iron":Color("575c60"),"concrete":Color("b3b0a6")}
static var _halo_material:StandardMaterial3D
static var _ruin_material:StandardMaterial3D
static var _halo_mesh:QuadMesh

static func signature(cities:Array)->String:
	var parts:Array=[]
	for city:Dictionary in cities:
		for r:Dictionary in city.get("undertakings",[]):
			parts.append([city.get("id",""),city.get("position"),r.id,r.status,r.get("custom_name",""),floori(float(r.progress)/float(C.get_definition(r.id).work)*10),floori(float(r.condition)*5),r.get("site",{}),int(r.get("dedicated_day",-1))>=0,String(r.get("outcome",""))])
	return str(hash(parts))

## The conceived form (tower, colossus, dam...) and material of a work.
static func shape_of(r:Dictionary,d:Dictionary)->String:
	var shape:=String(d.get("shape",""))
	var parsed:=String(r.get("id","")).split(":")
	if shape.is_empty() and parsed.size()==7:shape=parsed[1]
	if shape.is_empty():shape=String(d.get("form","hall"))
	return String(SHAPE_ALIASES.get(shape,shape))

static func material_of(r:Dictionary,d:Dictionary)->String:
	var parsed:=String(r.get("id","")).split(":")
	return String(d.get("material",parsed[4] if parsed.size()==7 else ""))

static func _halo()->QuadMesh:
	if _halo_mesh==null:
		_halo_mesh=QuadMesh.new();_halo_mesh.size=Vector2(.17,.17);_halo_mesh.orientation=PlaneMesh.FACE_Y
		var gradient:=Gradient.new();gradient.set_color(0,Color(1,.86,.5,.55));gradient.set_color(1,Color(1,.8,.4,0))
		var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(.5,0);texture.width=64;texture.height=64
		_halo_material=StandardMaterial3D.new();_halo_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;_halo_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		_halo_material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;_halo_material.albedo_texture=texture;_halo_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		_ruin_material=_halo_material.duplicate() as StandardMaterial3D;_ruin_material.blend_mode=BaseMaterial3D.BLEND_MODE_MIX;_ruin_material.albedo_color=Color(.18,.16,.14,.7)
	return _halo_mesh

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
			var root:=Node3D.new();root.name="Undertaking_"+String(r.id).replace(":","_");root.position=origin;parent.add_child(root)
			var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var pieces:=forms(String(r.id),shape_of(r,d),material_of(r,d))
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
			var dedicated:bool=int(r.get("dedicated_day",-1))>=0 and r.status=="functioning"
			var folly:bool=r.status=="ruined" and String(r.get("outcome",""))=="collapse"
			var label:=Label3D.new();label.name="Name"
			var title:String=preload("res://scripts/undertaking_system.gd").display_name(r)
			var state:="Under construction" if r.status=="building" else ("A folly, fallen" if folly else String(r.status).capitalize())
			label.text=("\u2726 %s \u2726" % title if dedicated else title)+"\n"+("Dedicated" if dedicated else state)
			label.font_size=36 if dedicated else 32;label.pixel_size=.00008;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false
			label.position.y=.04 if dedicated else .034
			label.modulate=Color("ffe29a") if dedicated else (Color("b8b0a0") if ruin else Color("f3e4bc"))
			label.outline_modulate=Color("3a2a0c") if dedicated else Color("242c29");label.outline_size=10 if dedicated else 8
			label.visibility_range_end=12 if dedicated else 8;root.add_child(label)
			if dedicated or ruin:
				# A soft landmark glow on the ground for dedicated works; ruins get a dim scar.
				var halo:=MeshInstance3D.new();halo.name="Halo";halo.mesh=_halo();halo.material_override=_halo_material if dedicated else _ruin_material
				halo.position.y=.0018;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;halo.visibility_range_end=20
				if not dedicated:halo.scale=Vector3(.7,1,.7)
				root.add_child(halo)

static func forms(id:String,shape:String,material_key:String="")->Array:
	var result:Array=[]
	var stone:=Color("9b917a");var clay:=Color("ac8054");var wood:=Color("72553a");var thatch:=Color("a99b64")
	if MATERIAL_TINTS.has(material_key):stone=MATERIAL_TINTS[material_key]
	var water:=Color("5f8e9a")
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
		"tower","lighthouse":
			result.append(piece(Vector3.ZERO,Vector3(.022,.004,.022),stone.darkened(.1)))
			result.append(piece(Vector3(0,.004,0),Vector3(.013,.022,.013),stone))
			result.append(piece(Vector3(0,.026,0),Vector3(.016,.002,.016),stone.darkened(.15)))
			if shape=="lighthouse":result.append(piece(Vector3(0,.028,0),Vector3(.008,.005,.008),Color("f2cf6e")))
			else:result.append(piece(Vector3(0,.028,0),Vector3(.012,.008,.012),stone.darkened(.2),"roof"))
		"colossus":
			result.append(piece(Vector3.ZERO,Vector3(.024,.005,.018),stone.darkened(.15)))
			for x in [-.004,.004]:result.append(piece(Vector3(x,.005,0),Vector3(.005,.011,.006),stone))
			result.append(piece(Vector3(0,.016,0),Vector3(.013,.011,.008),stone))
			result.append(piece(Vector3(.009,.017,0),Vector3(.003,.013,.003),stone.lightened(.05)))
			result.append(piece(Vector3(0,.027,0),Vector3(.007,.007,.007),stone.lightened(.08),"dome"))
		"bridge":
			result.append(piece(Vector3(0,.007,0),Vector3(.1,.003,.014),stone))
			for x in [-.036,0.0,.036]:result.append(piece(Vector3(x,0,0),Vector3(.007,.007,.012),stone.darkened(.12)))
			result.append(piece(Vector3(0,.0006,0),Vector3(.11,.0004,.05),water))
		"dam":
			result.append(piece(Vector3(0,0,.008),Vector3(.1,.016,.012),stone))
			result.append(piece(Vector3(0,.0006,-.024),Vector3(.1,.0006,.03),water))
			for x in [-.03,0.0,.03]:result.append(piece(Vector3(x,.002,.016),Vector3(.006,.01,.004),Color("d7e6ea")))
		"canal":
			for z in [-.012,.012]:result.append(piece(Vector3(0,0,z),Vector3(.11,.0025,.005),stone))
			result.append(piece(Vector3(0,.0006,0),Vector3(.11,.0006,.019),water))
		"causeway":
			result.append(piece(Vector3(0,0,0),Vector3(.12,.004,.012),stone))
			for x in [-.045,-.015,.015,.045]:result.append(piece(Vector3(x,.004,0),Vector3(.004,.004,.004),stone.darkened(.15)))
		"gate":
			for x in [-.014,.014]:result.append(piece(Vector3(x,0,0),Vector3(.008,.02,.01),stone))
			result.append(piece(Vector3(0,.02,0),Vector3(.038,.006,.011),stone.darkened(.1)))
		"observatory":
			for i in 3:result.append(piece(Vector3(0,i*.003,0),Vector3(.06-i*.014,.003,.05-i*.012),stone))
			result.append(piece(Vector3(0,.009,0),Vector3(.012,.008,.012),stone.lightened(.05)))
			result.append(piece(Vector3(0,.017,0),Vector3(.014,.008,.014),Color("c9c3b4"),"dome"))
		"amphitheatre":
			for i in 14:
				var a2:=PI*float(i)/13.0
				for tier in 3:result.append(piece(Vector3(cos(a2)*(.02+tier*.009),tier*.003,-sin(a2)*(.016+tier*.008)),Vector3(.007,.003,.006),stone))
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
