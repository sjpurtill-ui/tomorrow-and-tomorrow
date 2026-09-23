extends RefCounted
## Human-scale working ground attached to recorded buildings and service parcels.
## Geometry is in kilometres; no population, research or cultural style switches.
const EARLY := preload("res://scripts/early_settlement_visual.gd")
const SERVICE_FORMS := ["open_hearth_yard", "guarded_cache", "lined_storage_pits", "open_work_yard", "carried_water_point", "refuse_and_latrine_ground"]

static func handles(plot: Dictionary) -> bool:
	return EARLY.supports(plot) or String(plot.get("form", "")) in SERVICE_FORMS

static func render(plan: Dictionary, plots: Array[Dictionary], routes: Array[Dictionary], center: Vector3, height: Callable, land: Callable, parent: Node3D) -> void:
	var ground := SurfaceTool.new(); ground.begin(Mesh.PRIMITIVE_TRIANGLES)
	var props := SurfaceTool.new(); props.begin(Mesh.PRIMITIVE_TRIANGLES)
	var counts := {"ground":0, "props":0}
	var soil := Color(.29,.23,.14,.30)
	for route in routes:
		if not bool(route.get("active",true)): continue
		var points: PackedVector2Array = route.get("points",PackedVector2Array())
		var width := clampf(float(route.get("width_m",.8))*.0005,.00025,.0025)
		for i in range(1,points.size()):
			trail(ground,points[i-1],points[i],width,soil,center,height,land,counts)
	# Footprint bounds let each footpath skip buildings it cannot cross.
	var bounds: Array[Rect2] = []
	for other in plan.buildings:
		var footprint: PackedVector2Array = other.footprint
		var rect := Rect2(footprint[0],Vector2.ZERO) if footprint.size()>0 else Rect2(Vector2.INF,Vector2.ZERO)
		for corner in footprint: rect=rect.expand(corner)
		bounds.append(rect)
	for record in plan.buildings:
		var plot: Dictionary = record.plot
		if String(plot.get("status","active")) in ["vacant","reclaimed"]: continue
		var position: Vector2 = record.position
		var forward := Vector2(sin(float(record.angle)),cos(float(record.angle)))
		var door := position + forward * minf(float(record.radius)*.65,.0024)
		var nearest := door; var distance := INF
		for route in routes:
			if not bool(route.get("active",true)) or int(route.id)!=int(plot.get("frontage_route_id",-1)): continue
			var points: PackedVector2Array = route.points
			for i in range(1,points.size()):
				var point := Geometry2D.get_closest_point_to_segment(door,points[i-1],points[i])
				if point.distance_squared_to(door)<distance: nearest=point;distance=point.distance_squared_to(door)
		# Worn thresholds replace full-parcel polygon mats.
		patch(ground,door,.0016,soil,center,height,land,counts)
		var clear := true
		var path := Rect2(door,Vector2.ZERO).expand(nearest)
		for other_index in plan.buildings.size():
			var other = plan.buildings[other_index]
			if other.id==record.id: continue
			if not bounds[other_index].grow(0.000001).intersects(path,true): continue
			for i in 9:
				if Geometry2D.is_point_in_polygon(door.lerp(nearest,float(i)/8),other.footprint): clear=false;break
			if not clear: break
		if clear: trail(ground,door,nearest,.00027,soil,center,height,land,counts)
		if String(plot.get("status","active")) == "under_construction":
			for corner in record.footprint:
				box(props,corner,Vector3(.00012,.0015,.00012),.00075,Color(.27,.17,.075),center,height,counts)
	for plot in plots:
		var form := String(plot.get("form",""))
		if form not in SERVICE_FORMS or String(plot.get("status","active")) in ["vacant","ruin","reclaimed","under_construction"]: continue
		var p: Vector2 = plot.get("centroid",Vector2.ZERO)
		if not bool(land.call(p)): continue
		patch(ground,p,.004 if form=="open_hearth_yard" else .0025,soil,center,height,land,counts)
		if form=="open_hearth_yard":
			patch(ground,p,.0008,Color(.12,.10,.075,.85),center,height,land,counts)
			for i in 10:
				var point := p+Vector2.from_angle(i*TAU/10)*.00065
				box(props,point,Vector3(.00024,.00019,.00022),.0001,Color(.35,.34,.29),center,height,counts)
			box(props,p,Vector3(.0003,.00035,.0003),.00018,Color(.82,.34,.065),center,height,counts)
			for i in 3:
				var point := p+Vector2.from_angle(i*TAU/3+.4)*.0024
				box(props,point,Vector3(.0016,.00028,.00032),.00019,Color(.24,.14,.06),center,height,counts)
		elif form in ["guarded_cache","lined_storage_pits"]:
			for i in 4:
				var point := p+Vector2((i%2-.5)*.0012,(i/2-.5)*.0012)
				patch(ground,point,.00048,Color(.13,.105,.07,.8),center,height,land,counts)
				for j in 5:
					box(props,point+Vector2(0,(j-2)*.00017),Vector3(.0009,.00008,.00012),.00004,Color(.36,.26,.12),center,height,counts)
		elif form=="open_work_yard":
			for i in 5:
				box(props,p+Vector2(i*.00024-.0005,0),Vector3(.00017,.00019,.0018),.0001,Color(.30,.19,.085),center,height,counts)
			box(props,p+Vector2(.0015,0),Vector3(.0011,.0006,.00055),.0003,Color(.26,.18,.095),center,height,counts)
		elif form=="carried_water_point":
			for i in 3:
				box(props,p+Vector2(i*.0006,0),Vector3(.0004,.0005,.0004),.00025,Color(.40,.27,.14),center,height,counts)
		elif form=="refuse_and_latrine_ground":
			patch(ground,p,.0012,Color(.19,.16,.08,.55),center,height,land,counts)
	commit(ground,"EarlyWorkingGround",true,counts.ground,parent)
	commit(props,"EarlyCommunalObjects",false,counts.props,parent)

static func vertex(surface: SurfaceTool, p: Vector2, color: Color, center: Vector3, height: Callable) -> void:
	var world := p+Vector2(center.x,center.z)
	surface.set_color(color);surface.set_normal(Vector3.UP)
	surface.add_vertex(Vector3(world.x,float(height.call(world.x,world.y))+.000035,world.y))

static func patch(surface: SurfaceTool, p: Vector2, radius: float, color: Color, center: Vector3, height: Callable, land: Callable, counts: Dictionary) -> void:
	for i in 20:
		var a := p+Vector2.from_angle(i*TAU/20)*radius*(1+.07*sin(i*3.7))
		var b := p+Vector2.from_angle((i+1)*TAU/20)*radius*(1+.07*sin((i+1)*3.7))
		if not bool(land.call(a)) or not bool(land.call(b)) or not bool(land.call(p)): continue
		vertex(surface,p,color,center,height)
		vertex(surface,b,Color(color,0),center,height);vertex(surface,a,Color(color,0),center,height)
		counts.ground+=1

static func trail(surface: SurfaceTool, a: Vector2, b: Vector2, width: float, color: Color, center: Vector3, height: Callable, land: Callable, counts: Dictionary) -> void:
	if a.distance_to(b)<.0001: return
	var steps := clampi(ceili(a.distance_to(b)/.0008),1,256)
	var side := (b-a).orthogonal().normalized()*width
	for i in steps:
		var start := a.lerp(b,float(i)/steps);var end := a.lerp(b,float(i+1)/steps)
		if not bool(land.call(start)) or not bool(land.call(end)): continue
		for sign_value in [-1,1]:
			var points := [start,end,end+side*sign_value,start+side*sign_value]
			for index in [0,1,2,0,2,3]:
				vertex(surface,points[index],color if index<2 else Color(color,0),center,height)
			counts.ground+=2

static func box(surface: SurfaceTool, p: Vector2, size: Vector3, y: float, color: Color, center: Vector3, height: Callable, counts: Dictionary) -> void:
	var mesh := BoxMesh.new();mesh.size=size
	var arrays := mesh.surface_get_arrays(0);var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL];var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var world := p+Vector2(center.x,center.z)
	var origin := Vector3(world.x,float(height.call(world.x,world.y))+y,world.y)
	for index in indices:
		surface.set_color(color);surface.set_normal(normals[index]);surface.add_vertex(vertices[index]+origin)
	counts.props+=1

static func commit(surface: SurfaceTool, name: String, transparent: bool, count: int, parent: Node3D) -> void:
	if count==0: return
	var node := MeshInstance3D.new();node.name=name;node.mesh=surface.commit()
	var material := StandardMaterial3D.new();material.vertex_color_use_as_albedo=true
	material.roughness=1;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	if transparent: material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override=material;parent.add_child(node)
