extends RefCounted
## Human-scale silhouettes, one colored mesh per landmark, no per-piece nodes.
## Each work stands on its own plinth, levelled over the slope it was built on,
## so it never sinks into a hillside as a sliver. Faces are flat-shaded and
## wound outward. Its name and its chart emblem are not drawn here: each root
## carries a `map_mark` (see `map_mark`) that the shared screen-space label
## layer (scripts/hud/city_labels.gd) sets as a paper card and inked emblem.
const C=preload("res://scripts/undertaking_catalog.gd")
const U=preload("res://scripts/undertaking_system.gd")
const SHAPE_ALIASES:={"stair":"terrace","cistern":"basin","garden":"orchard","archive":"hall","library":"hall"}
const MATERIAL_TINTS:={"stone":Color("9b917a"),"brick":Color("9a5f45"),"timber":Color("72553a"),"earth":Color("a07f55"),"iron":Color("575c60"),"concrete":Color("b3b0a6")}
const WOOD:=Color("6d5236")
const WEATHERED:=Color("6f675a")
## How far the plinth reaches past the work's own footprint (km).
const PLINTH_MARGIN:=.006
## Height of the plinth's dressed top above the highest ground under it (km).
const PLINTH_RISE:=.0012
## The fewest courses shown once work has begun, as a fraction of full height.
const FIRST_COURSES:=.08
static var _halo_material:StandardMaterial3D
static var _ruin_material:StandardMaterial3D
static var _halo_mesh:QuadMesh
static var _material:StandardMaterial3D
static var _unit_shapes:Dictionary={}

static func signature(cities:Array)->String:
	var parts:Array=[]
	for city:Dictionary in cities:
		for r:Dictionary in city.get("undertakings",[]):
			parts.append([city.get("id",""),city.get("position"),r.id,r.status,r.get("custom_name",""),floori(U.fraction(r)*10),floori(float(r.condition)*5),r.get("site",{}),int(r.get("dedicated_day",-1))>=0,String(r.get("outcome",""))])
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

## The work's state as the map shows it.
static func state_of(r:Dictionary)->String:
	var status:=String(r.get("status",""))
	if status in ["building","stalled"]:return "building"
	if status=="abandoned":return "abandoned"
	if status=="ruined":return "ruined"
	return "dedicated" if int(r.get("dedicated_day",-1))>=0 else "standing"

## A short line for the work's map card: empty for a plain standing work.
static func status_line(state:String,progress:float,folly:bool=false)->String:
	match state:
		"building":return "Rising · %d%%" % (floori(progress*10.0)*10)
		"abandoned":return "Abandoned · %d%%" % (floori(progress*10.0)*10)
		"ruined":return "A folly, fallen" if folly else "In ruins"
		"dedicated":return "Dedicated"
	return ""

static func _halo()->QuadMesh:
	if _halo_mesh==null:
		_halo_mesh=QuadMesh.new();_halo_mesh.size=Vector2(1,1);_halo_mesh.orientation=PlaneMesh.FACE_Y
		var gradient:=Gradient.new();gradient.set_color(0,Color(1,.86,.5,.42));gradient.set_color(1,Color(1,.8,.4,0))
		var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(.5,0);texture.width=64;texture.height=64
		_halo_material=StandardMaterial3D.new();_halo_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;_halo_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		_halo_material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;_halo_material.albedo_texture=texture;_halo_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		_ruin_material=_halo_material.duplicate() as StandardMaterial3D;_ruin_material.blend_mode=BaseMaterial3D.BLEND_MODE_MIX;_ruin_material.albedo_color=Color(.18,.16,.14,.55)
	return _halo_mesh

static func _landmark_material()->StandardMaterial3D:
	if _material==null:
		_material=StandardMaterial3D.new();_material.vertex_color_use_as_albedo=true;_material.vertex_color_is_srgb=true
		_material.roughness=.92;_material.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	return _material

static func render(cities:Array,parent:Node3D,height:Callable)->void:
	for city:Dictionary in cities:
		var point:Vector2=city.get("position",Vector2.ZERO)
		var index:=0
		for r:Dictionary in city.get("undertakings",[]):
			var d:=C.get_definition(String(r.id))
			if d.is_empty():continue
			var site:Dictionary=r.get("site",{"position":point+Vector2(.18+index*.12,.16),"angle":0.0})
			index+=1
			var p:Vector2=site.position
			var angle:=float(site.get("angle",0.0))
			var origin:=Vector3(p.x,float(height.call(p.x,p.y)),p.y)
			var root:=Node3D.new();root.name="Undertaking_"+String(r.id).replace(":","_");root.position=origin;parent.add_child(root)
			var shape:=shape_of(r,d)
			var state:=state_of(r)
			var progress:=U.fraction(r)
			var built:=build(forms(String(r.id),shape,material_of(r,d)),state,progress,angle,origin,height)
			var mesh:=MeshInstance3D.new();mesh.name="Landmark";mesh.mesh=built.mesh;mesh.material_override=_landmark_material();mesh.visibility_range_end=20;root.add_child(mesh)
			var plinth:Rect2=built.plinth
			if state=="dedicated" or state=="ruined":
				# A soft glow over the dressed plinth for dedicated works; ruins get a dim
				# scar. Laid on the plinth, so it never cuts into the slope beside it.
				var halo:=MeshInstance3D.new();halo.name="Halo";halo.mesh=_halo();halo.material_override=_halo_material if state=="dedicated" else _ruin_material
				halo.position=Vector3(plinth.get_center().x,float(built.top)+.0004,plinth.get_center().y).rotated(Vector3.UP,-angle)
				halo.rotation.y=-angle;halo.scale=Vector3(plinth.size.x,1,plinth.size.y)
				halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;halo.visibility_range_end=20
				root.add_child(halo)
			var folly:bool=state=="ruined" and String(r.get("outcome",""))=="collapse"
			root.set_meta("map_mark",{"id":String(r.id),"city_id":String(city.get("id","")),"title":U.display_name(r),"shape":shape,"state":state,"progress":progress,
				"status":status_line(state,progress,folly),"anchor":origin+Vector3(0,float(built.top)+float(built.height)*.5,0),"radius":plinth.size.length()*.5})

## The map mark a rendered work root carries (empty for anything else).
static func map_mark(root:Node)->Dictionary:
	return root.get_meta("map_mark",{}) if root!=null and root.has_meta("map_mark") else {}

## One work's mesh: a levelled plinth, then its pieces raised in courses while
## building, whole when standing, broken and weathered as a ruin. Returns the
## mesh, the plinth rectangle (local, before rotation), the plinth top and the
## design height of the finished work.
static func build(pieces:Array,state:String,progress:float,angle:float,origin:Vector3,height:Callable)->Dictionary:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bounds:=footprint(pieces)
	var plinth:=bounds.grow(PLINTH_MARGIN)
	var ground:=_ground_span(plinth,angle,origin,height)
	var top:=ground.y+PLINTH_RISE
	var bottom:=ground.x-.003
	var tone:Color=pieces[0].color if not pieces.is_empty() else Color("9b917a")
	# The plinth: an earthen bank down into the slope, in the map's own soil
	# tone so it reads as levelled ground, then a dressed top course.
	var bank:=Color("6f6a48").lerp(tone,.2)
	append_piece(surface,piece(Vector3(plinth.get_center().x,bottom,plinth.get_center().y),Vector3(plinth.size.x,top-bottom-.0006,plinth.size.y),bank),angle)
	append_piece(surface,piece(Vector3(plinth.get_center().x,top-.0006,plinth.get_center().y),Vector3(plinth.size.x-.0016,.0006,plinth.size.y-.0016),tone.lerp(Color("c8b98f"),.45)),angle)
	var design_height:=0.0
	for part:Dictionary in pieces:
		if part.kind!="water":design_height=maxf(design_height,float(part.position.y)+float(part.size.y))
	var unfinished:=state in ["building","abandoned"]
	var level:=design_height*maxf(progress,FIRST_COURSES) if unfinished else design_height
	for i in pieces.size():
		var part:Dictionary=pieces[i].duplicate()
		var base:=float(part.position.y)
		if unfinished:
			# Courses rise from the ground; no water stands in an unfinished basin.
			if part.kind=="water" or base>=level-.00005:continue
			if base+float(part.size.y)>level:
				part.size.y=level-base
				part.kind="box"
			if state=="abandoned":part.color=(part.color as Color).lerp(WEATHERED,.5)
		elif state=="ruined":
			if part.kind=="water":continue
			# Everything above the break has fallen. Pieces through the break end in
			# jagged tops above it, never below, so nothing is left floating.
			var cut:=maxf(design_height*.42,.002)
			if base>=cut:continue
			if base+float(part.size.y)>cut:
				part.size.y=minf(float(part.size.y),cut*(1.0+.3*float((i*7)%5)/4.0)-base)
				part.kind="box"
			part.color=(part.color as Color).lerp(WEATHERED,.6)
		part.position.y=base+top
		append_piece(surface,part,angle)
	if state=="building":
		_scaffold(surface,bounds,level,design_height,top,angle)
	elif state=="ruined":
		for k in 6:
			var t:=float(k)/6.0*TAU+.4
			var at:=bounds.get_center()+Vector2(cos(t)*bounds.size.x*.55,sin(t)*bounds.size.y*.55)
			append_piece(surface,piece(Vector3(at.x,top,at.y),Vector3(.004+.002*(k%2),.0018,.003),WEATHERED.lerp(tone,.3)),angle)
	return {"mesh":surface.commit(),"plinth":plinth,"top":top,"height":design_height}

## Timber poles at the corners of the rising work, ledgers at the working
## level, and a heap of material beside it.
static func _scaffold(surface:SurfaceTool,bounds:Rect2,level:float,design_height:float,top:float,angle:float)->void:
	var frame:=bounds.grow(.0025)
	var pole_height:=maxf(.006,minf(design_height,level+design_height*.18)+.002)
	for corner:Vector2 in [frame.position,Vector2(frame.end.x,frame.position.y),frame.end,Vector2(frame.position.x,frame.end.y)]:
		append_piece(surface,piece(Vector3(corner.x,top,corner.y),Vector3(.0012,pole_height,.0012),WOOD),angle)
	for ledger:float in [level,level*.5]:
		if ledger<.002:continue
		var y:=top+minf(ledger,pole_height-.0008)
		append_piece(surface,piece(Vector3(frame.get_center().x,y,frame.position.y),Vector3(frame.size.x,.0006,.0007),WOOD),angle)
		append_piece(surface,piece(Vector3(frame.get_center().x,y,frame.end.y),Vector3(frame.size.x,.0006,.0007),WOOD),angle)
		append_piece(surface,piece(Vector3(frame.position.x,y,frame.get_center().y),Vector3(.0007,.0006,frame.size.y),WOOD),angle)
		append_piece(surface,piece(Vector3(frame.end.x,y,frame.get_center().y),Vector3(.0007,.0006,frame.size.y),WOOD),angle)
	append_piece(surface,piece(Vector3(frame.end.x-.004,top,frame.end.y-.003),Vector3(.008,.004,.006),Color("8a7a5c"),"dome"),angle)

## The pieces' footprint on the ground (local x/z, before rotation).
static func footprint(pieces:Array)->Rect2:
	var rect:=Rect2()
	var first:=true
	for part:Dictionary in pieces:
		var half:=Vector2(float(part.size.x),float(part.size.z))*.5
		var r:=Rect2(Vector2(float(part.position.x),float(part.position.z))-half,half*2.0)
		rect=r if first else rect.merge(r)
		first=false
	if first:rect=Rect2(-.015,-.015,.03,.03)
	# Very small works still get a plinth a reader can see.
	var wide:=maxf(0.0,.015-rect.size.x*.5);var deep:=maxf(0.0,.015-rect.size.y*.5)
	return rect.grow_individual(wide,deep,wide,deep)

## Lowest and highest ground under a local rectangle, relative to the origin.
static func _ground_span(rect:Rect2,angle:float,origin:Vector3,height:Callable)->Vector2:
	var low:=INF;var high:=-INF
	for u in 3:
		for v in 3:
			var world:=(rect.position+rect.size*Vector2(u*.5,v*.5)).rotated(angle)+Vector2(origin.x,origin.z)
			var h:=float(height.call(world.x,world.y))-origin.y
			low=minf(low,h);high=maxf(high,h)
	return Vector2(low,high)

static func forms(id:String,shape:String,material_key:String="")->Array:
	var result:Array=[]
	var stone:=Color("9b917a");var clay:=Color("ac8054");var wood:=Color("72553a");var thatch:=Color("a99b64")
	if MATERIAL_TINTS.has(material_key):stone=MATERIAL_TINTS[material_key]
	var water:=Color("5f8e9a")
	match shape:
		"ring":
			for i in 12:
				if id=="safe_passage" and i in [0,6]:continue
				var a:=TAU*i/12
				result.append(piece(Vector3(cos(a)*.035,0,sin(a)*.028),Vector3(.004,.009 if id=="ancestor_ring" else .006,.004),stone))
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
			result.append(piece(Vector3(0,0,0),Vector3(.061,.0012,.049),clay))
		"terrace", "mound":
			for i in 4:result.append(piece(Vector3(0,i*.003,0),Vector3(.085-i*.016,.003,.065-i*.012),Color("647249") if id=="flood_terraces" else stone.darkened(.04*i)))
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
			result.append(piece(Vector3(0,0,0),Vector3(.11,.0008,.05),water,"water"))
		"dam":
			result.append(piece(Vector3(0,0,.008),Vector3(.1,.016,.012),stone))
			result.append(piece(Vector3(0,0,-.024),Vector3(.1,.0012,.03),water,"water"))
			for x in [-.03,0.0,.03]:result.append(piece(Vector3(x,.002,.0145),Vector3(.006,.01,.0015),Color("d7e6ea")))
		"canal":
			for z in [-.012,.012]:result.append(piece(Vector3(0,0,z),Vector3(.11,.0025,.005),stone))
			result.append(piece(Vector3(0,0,0),Vector3(.11,.0012,.019),water,"water"))
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

## Unit shapes (x,z in -0.5..0.5, y in 0..1) as flat triangle lists.
static func _unit(kind:String)->PackedVector3Array:
	if _unit_shapes.has(kind):return _unit_shapes[kind]
	var vertices:PackedVector3Array;var indices:PackedInt32Array
	if kind=="roof":
		vertices=PackedVector3Array([Vector3(-.5,0,-.5),Vector3(.5,0,-.5),Vector3(0,1,-.5),Vector3(-.5,0,.5),Vector3(.5,0,.5),Vector3(0,1,.5)])
		indices=PackedInt32Array([0,2,1,3,4,5,0,3,5,0,5,2,1,2,5,1,5,4,0,1,4,0,4,3])
	else:
		var mesh:PrimitiveMesh
		if kind=="dome":
			var dome:=SphereMesh.new();dome.radius=.5;dome.height=1;dome.radial_segments=10;dome.rings=5;mesh=dome
		else:mesh=BoxMesh.new()
		var arrays:=mesh.surface_get_arrays(0);vertices=arrays[Mesh.ARRAY_VERTEX];indices=arrays[Mesh.ARRAY_INDEX]
		for i in vertices.size():vertices[i].y+=.5
	var list:=PackedVector3Array()
	for i in indices:list.append(vertices[i])
	_unit_shapes[kind]=list
	return list

## Appends one piece as flat-shaded triangles. Every triangle is wound so its
## front (clockwise, Godot's convention) faces away from the piece's centre
## and carries that face's own normal: no face renders inside out, and boxes
## do not get the smeared corner shading of shared normals.
static func append_piece(surface:SurfaceTool,part:Dictionary,angle:float)->void:
	var size:Vector3=part.size
	if size.x<=0.0 or size.y<=0.0 or size.z<=0.0:return
	var kind:=String(part.kind)
	var unit:=_unit(kind if kind in ["roof","dome"] else "box")
	var local:Vector3=part.position
	var inner:=Vector3(0,.5*size.y,0)+local
	if kind=="roof":inner=Vector3(0,.3*size.y,0)+local
	var color:Color=part.color
	for i in range(0,unit.size(),3):
		var a:=unit[i]*size+local;var b:=unit[i+1]*size+local;var c:=unit[i+2]*size+local
		var normal:=(c-a).cross(b-a)
		if normal.length_squared()<1e-20:continue
		normal=normal.normalized()
		if normal.dot((a+b+c)/3.0-inner)<0.0:
			var swap:=b;b=c;c=swap;normal=-normal
		var world_normal:=normal.rotated(Vector3.UP,-angle)
		for v:Vector3 in [a,b,c]:
			surface.set_color(color);surface.set_normal(world_normal)
			surface.add_vertex(v.rotated(Vector3.UP,-angle))
