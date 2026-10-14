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
	var candidates:=Cover.candidates(center,radius,.008,GameState.world_seed)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return (Vector2(a.point)-center).length_squared()<(Vector2(b.point)-center).length_squared())
	for candidate:Dictionary in candidates:
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
		colors.append(Cover.canopy_tint(biome,rng.randf()).lightened(.04) if canopy else Cover.scrub_tint(biome,rng.randf()))
	if trees.is_empty():return
	# The aerial map's shallow crowns need depth at this human camera angle.
	# Keep the exact seeded tree sites, adding a trunk and overlapping volumes;
	# these are presentation variants, never additional timber deposits.
	var crown:=SphereMesh.new();crown.radius=.0025;crown.height=.0044;crown.radial_segments=9;crown.rings=5
	var trunk:=CylinderMesh.new();trunk.top_radius=.00018;trunk.bottom_radius=.00042;trunk.height=.0042;trunk.radial_segments=7
	var leaf_transforms:Array[Transform3D]=[];var leaf_colors:Array[Color]=[];var trunks:Array[Transform3D]=[]
	for i in trees.size():
		var tree:Transform3D=trees[i]
		for lobe:Vector3 in [Vector3(-.0012,.0042,0),Vector3(.0013,.0048,.0005),Vector3(0,.0063,-.0005)]:
			leaf_transforms.append(tree*Transform3D(Basis.IDENTITY,lobe));leaf_colors.append(colors[i])
		trunks.append(tree*Transform3D(Basis.IDENTITY,Vector3(0,.0021,0)))
	_batch(parent,"ActualSeededWoodland",crown,leaf_transforms,leaf_colors,Color.WHITE)
	_batch(parent,"WoodlandTrunks",trunk,trunks,[],Color("66513c"))
	var shade:=SurfaceTool.new();shade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tree:Transform3D in trees:
		var shadow_radius:=tree.basis.x.length()*.0045
		var shadow_center:=Vector2(tree.origin.x,tree.origin.z)+Vector2(shadow_radius*.55,shadow_radius*.45)
		for i in 14:
			for at:Vector2 in [shadow_center,shadow_center+Vector2.from_angle(TAU*i/14)*shadow_radius,shadow_center+Vector2.from_angle(TAU*(i+1)/14)*shadow_radius]:
				shade.set_color(Color(1,1,1,.5 if at==shadow_center else 0));shade.add_vertex(point.call(at,.00023))
	var shadow:=MeshInstance3D.new();shadow.name="DrapedWoodlandShadows";shadow.mesh=shade.commit()
	var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded,blend_mul,depth_draw_never,cull_disabled,shadows_disabled; void fragment(){ALBEDO=mix(vec3(1),vec3(.45,.48,.40),COLOR.a);}"
	var material:=ShaderMaterial.new();material.shader=shader;shadow.material_override=material;parent.add_child(shadow)

static func _batch(parent:Node3D,label:String,mesh:Mesh,transforms:Array[Transform3D],colors:Array[Color],tint:Color)->void:
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=not colors.is_empty()
	batch.mesh=mesh;batch.instance_count=transforms.size()
	for i in transforms.size():
		batch.set_instance_transform(i,transforms[i])
		if batch.use_colors:batch.set_instance_color(i,colors[i])
	var node:=MultiMeshInstance3D.new();node.name=label;node.multimesh=batch
	var paint:=ShaderMaterial.new();var shader:=Shader.new();shader.code=TREE_SHADER;paint.shader=shader
	paint.set_shader_parameter("tint",tint);node.material_override=paint;parent.add_child(node)
	node.set_meta("bounded_instances",transforms.size())

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

const TREE_SHADER:="""shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0);
varying vec3 world_normal;varying vec3 at;
void vertex(){world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);at=VERTEX;}
void fragment(){
float key=smoothstep(-.4,.85,dot(normalize(world_normal),normalize(vec3(-.55,.8,.6))));
float leaf=fract(sin(dot(floor(at*2300.0),vec3(127.1,311.7,45.1)))*43758.5);
vec3 base=COLOR.rgb*tint.rgb;
ALBEDO=base*mix(vec3(.52,.65,.63),vec3(1.35,1.34,.95),key)*(.90+leaf*.16);
}
"""
