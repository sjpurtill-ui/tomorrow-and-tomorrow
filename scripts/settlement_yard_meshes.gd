extends RefCounted
## Five shared, static yard groups. Coordinates and bounds are in metres;
## callers convert to world km once and use the actual bounds for placement.
## No materials, nodes, animation, transparent cards or per-grain objects.
const Shapes:=preload("res://scripts/settlement_kit_shapes.gd")
const KINDS:=["woodpile","pots","drying_rack","stored_grain","fishing_net"]
const MAX_TRIANGLES:=512
const NET_COLUMNS:=7
const NET_ROWS:=5
const NET_LEFT:=-.825
const NET_RIGHT:=.825
const NET_BOTTOM:=.32
const NET_TOP:=1.48
const NET_Z:=.04
static var _meshes:Dictionary={}

static func mesh(kind:String)->Mesh:
	if kind not in KINDS:return null
	if _meshes.has(kind):return _meshes[kind]
	var result:Mesh
	if kind in ["woodpile","pots","drying_rack"]:
		result=Shapes.prop(kind)
	else:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		if kind=="stored_grain":_stored_grain(surface)
		else:_fishing_net(surface)
		result=surface.commit()
		result.set_meta("yard_kind",kind)
		result.set_meta("yard_units","metres")
	_meshes[kind]=result
	return result

static func bounds(kind:String)->AABB:
	var resource:=mesh(kind)
	return resource.get_aabb() if resource!=null else AABB()

static func radius_m(kind:String)->float:
	var box:=bounds(kind)
	var extent:=box.position.abs().max(box.end.abs())
	return Vector2(extent.x,extent.z).length()

static func height_m(kind:String)->float:return bounds(kind).size.y

static func triangles(kind:String)->int:
	var resource:=mesh(kind)
	if resource==null:return 0
	var count:=0
	for surface in resource.get_surface_count():
		var arrays:=resource.surface_get_arrays(surface)
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		count+=(indices.size() if not indices.is_empty() else vertices.size())/3
	return count

static func _stored_grain(surface:SurfaceTool)->void:
	# Three low woven stores on two offcuts. Opaque, coarse grain surfaces
	# communicate a stored staple without rendering individual kernels.
	for x in [-.36,.36]:
		Shapes._box(surface,Vector3(x,.035,.23),Vector3(.13,.07,1.5),Shapes.TIMBER_DARK)
	var places:=[Vector3(-.40,.07,-.18),Vector3(.32,.07,.04),Vector3(-.04,.07,.62)]
	var heights:=[.52,.62,.43]
	for index in places.size():
		var at:Vector3=places[index];var height:float=heights[index]
		var straw:=Shapes.STRAW_DARK.lightened(.05*float(index))
		Shapes._frustum(surface,at,.23,.31,height,8,straw,.06)
		for fraction in [.32,.79]:
			var radius:=lerpf(.23,.31,float(fraction))+.014
			Shapes._frustum(surface,at+Vector3(0,height*float(fraction),0),radius,radius,.027,8,Shapes.TIMBER,.04)
		Shapes._frustum(surface,at+Vector3(0,height+.005,0),.277,.13,.065,8,Color("bda46b"),.10)

static func _fishing_net(surface:SurfaceTool)->void:
	# A net hung to dry between two braced poles. The lattice is twelve
	# opaque cord prisms with real open cells, not a transparent full card.
	for x in [-.95,.95]:
		Shapes._beam(surface,Vector3(x,.055,0),Vector3(x,1.65,0),.055,Shapes.TIMBER)
		Shapes._beam(surface,Vector3(x,.045,.45),Vector3(x,1.50,0),.045,Shapes.TIMBER_DARK)
	Shapes._beam(surface,Vector3(-1.08,1.59,0),Vector3(1.08,1.59,0),.055,Shapes.TIMBER_DARK)
	var cord:=Color("a08b63")
	for column in NET_COLUMNS:
		var x:=lerpf(NET_LEFT,NET_RIGHT,float(column)/float(NET_COLUMNS-1))
		Shapes._beam(surface,Vector3(x,NET_BOTTOM,NET_Z),Vector3(x,NET_TOP,NET_Z),.022,cord)
	for row in NET_ROWS:
		var y:=lerpf(NET_BOTTOM,NET_TOP,float(row)/float(NET_ROWS-1))
		Shapes._beam(surface,Vector3(NET_LEFT,y,NET_Z),Vector3(NET_RIGHT,y,NET_Z),.021,cord.darkened(.09))
	# Five sinkers make the lower edge and the fishing use readable.
	for index in 5:
		var x:=lerpf(NET_LEFT,NET_RIGHT,float(index)/4.0)
		Shapes._frustum(surface,Vector3(x,NET_BOTTOM-.075,NET_Z),.044,.035,.09,6,Color("756c5b"),.06)
