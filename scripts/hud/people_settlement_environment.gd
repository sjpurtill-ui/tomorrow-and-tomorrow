extends RefCounted
## Bounded landscape context sampled from the same seeded land cover and river
## courses as the map. It never builds or changes the live terrain's nodes.
const Cover=preload("res://scripts/landscape_cover.gd")
const MAX_PLANTS:=360

static func render(terrain:Node,data:Dictionary,bounds:Rect2,point:Callable,parent:Node3D)->void:
	if not is_instance_valid(terrain) or not terrain.has_method("_biome_at"):return
	_foliage(terrain,data,bounds,point,parent)
	_water(terrain,data,bounds,point,parent)

static func _clear(at:Vector2,plots:Array,routes:Array)->bool:
	for plot:Dictionary in plots:
		if String(plot.get("status","active"))=="reclaimed":continue
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		if polygon.size()>2 and Geometry2D.is_point_in_polygon(at,polygon):return false
	for route:Dictionary in routes:
		if not bool(route.get("active",true)):continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		for i in range(1,points.size()):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at,points[i-1],points[i]))<maxf(.002,float(route.get("width_m",2))*.0005):return false
	return true

static func _foliage(terrain:Node,data:Dictionary,bounds:Rect2,point:Callable,parent:Node3D)->void:
	if not terrain.has_method("_create_irregular_canopy_mesh"):return
	var moisture:FastNoiseLite=terrain.get("moisture_noise");var detail:FastNoiseLite=terrain.get("detail_noise")
	if moisture==null or detail==null:return
	var origin:=Vector2(data.origin.x,data.origin.z)
	var radius:=minf(.40,maxf(bounds.size.x,bounds.size.y)*.5)
	var center:=bounds.get_center()+origin
	var rng:=RandomNumberGenerator.new();var trees:Array[Transform3D]=[];var colors:Array[Color]=[]
	# These are the map's exact close-cover candidates and woodland decision,
	# evaluated read-only when its camera has not built close vegetation here.
	for candidate:Dictionary in Cover.candidates(center,radius,.008,GameState.world_seed):
		if trees.size()>=MAX_PLANTS:break
		var world:Vector2=candidate.point;var local:=world-origin
		if not bounds.has_point(local) or not _clear(local,data.plots,data.routes):continue
		if float(terrain.call("_height_at",world.x,world.y))<=0.0:continue
		var biome:Dictionary=terrain.call("_biome_at",world.x,world.y)
		var wet:=moisture.get_noise_2d(world.x,world.y)
		var mass:=detail.get_noise_2d(world.x*16.0+71.0,world.y*16.0-39.0)
		var neighbourhood:=detail.get_noise_2d(world.x*92.0-143.0,world.y*92.0+211.0)
		var edge:=detail.get_noise_2d(world.x*430.0+317.0,world.y*430.0-173.0)
		var field:=mass*.62+neighbourhood*.31+edge*.13+wet*.38
		var drainage:=float(terrain.call("_local_drainage_distance_at",world.x,world.y))
		if drainage<.16:field+=pow(1.0-drainage/.16,1.35)*(.28+maxf(0,wet)*.18)
		var chance:=clampf((field-.015)*1.08,.012,.54) if field>.015 else .002
		chance*=clampf(Cover.canopy_density(biome)*2,0,1)
		rng.seed=int(candidate.seed)
		var canopy:=rng.randf()<chance
		var scrub:=Cover.scrub_density(biome)*clampf(.65+maxf(0,field),.5,1.4)
		if "Hearth Circle" in GameState.settlement_completed:scrub*=lerpf(.35,1,smoothstep(.08,.40,local.length()))
		if not canopy and rng.randf()>scrub:continue
		var scale:=rng.randf_range(.74,1.34) if canopy else rng.randf_range(.22,.42)
		var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale)
		trees.append(Transform3D(basis,point.call(local,.0002)))
		colors.append(Cover.canopy_tint(biome,rng.randf()).lightened(.16) if canopy else Cover.scrub_tint(biome,rng.randf()))
	if trees.is_empty():return
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
	batch.mesh=terrain.call("_create_irregular_canopy_mesh",.0037,.00235);batch.instance_count=trees.size()
	for i in trees.size():batch.set_instance_transform(i,trees[i]);batch.set_instance_color(i,colors[i])
	var node:=MultiMeshInstance3D.new();node.name="ActualSeededWoodland";node.multimesh=batch
	var paint:=StandardMaterial3D.new();paint.vertex_color_use_as_albedo=true;paint.vertex_color_is_srgb=true;paint.roughness=1
	node.material_override=paint;parent.add_child(node)
	node.set_meta("bounded_instances",trees.size())

static func _water(terrain:Node,data:Dictionary,bounds:Rect2,point:Callable,parent:Node3D)->void:
	if not terrain.has_method("_world_river_x"):return
	var origin:=Vector2(data.origin.x,data.origin.z);var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count:=0;var courses:Array=[]
	var trunk:=PackedVector2Array()
	for i in 65:
		var z:=bounds.position.y+origin.y+bounds.size.y*i/64.0
		var x:=float(terrain.call("_world_river_x",z))
		if is_finite(x):trunk.append(Vector2(x,z)-origin)
	if trunk.size()>1:courses.append({"points":trunk,"width":.105})
	var tributaries:Array=terrain.get("world_tributary_courses")
	for course:Array in tributaries:
		var points:=PackedVector2Array()
		for entry:Vector3 in course:points.append(Vector2(entry.x,entry.z)-origin)
		courses.append({"points":points,"width":.029})
	var clip:=PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	for course:Dictionary in courses:
		var points:PackedVector2Array=course.points
		for i in range(1,points.size()):
			var segment:=Rect2(points[i-1],Vector2.ZERO).expand(points[i]).grow(course.width)
			if not segment.intersects(bounds):continue
			var middle:Vector2=(points[i-1]+points[i])*.5+origin
			if float(terrain.call("_height_at",middle.x,middle.y))<0:continue
			var side:Vector2=(points[i]-points[i-1]).normalized().orthogonal()*float(course.width)
			var ribbon:=PackedVector2Array([points[i-1]+side,points[i]+side,points[i]-side,points[i-1]-side])
			for polygon:PackedVector2Array in Geometry2D.intersect_polygons(ribbon,clip):
				for index in Geometry2D.triangulate_polygon(polygon):
					surface.set_normal(Vector3.UP);surface.add_vertex(point.call(polygon[index],.00016));count+=1
	if count==0:return
	var node:=MeshInstance3D.new();node.name="RecordedWaterCourses";node.mesh=surface.commit()
	var paint:=StandardMaterial3D.new();paint.albedo_color=Color("638d91");paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node)
