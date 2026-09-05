extends MultiMeshInstance3D
## Bounded visual representatives of saved cutting, never resource entities.
const LANDSCAPE:=preload("res://scripts/landscape_resource_visuals.gd")
const CELL:=0.016
const MAX_INSTANCES:=121
var refresh_key:=""

static func samples(center:Vector2,areas:PackedVector4Array,world_seed:int,cover:Callable,revealed:Callable)->PackedVector2Array:
	var points:=PackedVector2Array()
	if areas.is_empty(): return points
	var anchor:=Vector2i(floori(center.x/CELL),floori(center.y/CELL))
	for z in range(-5,6):
		for x in range(-5,6):
			var cell:=anchor+Vector2i(x,z)
			var rng:=RandomNumberGenerator.new()
			rng.seed=world_seed ^ (cell.x*73856093) ^ (cell.y*19349663)
			var point:=(Vector2(cell)+Vector2(rng.randf_range(0.15,0.85),rng.randf_range(0.15,0.85)))*CELL
			var probability:float=clampf(float(cover.call(point)),0.0,1.0)*(1.0-LANDSCAPE.retained_at(point,areas))
			if rng.randf()<probability and bool(revealed.call(point)): points.append(point)
	return points

func refresh(center:Vector2,span:float,areas:PackedVector4Array,world_seed:int,day:int,cover:Callable,revealed:Callable,height:Callable,force:bool=false)->void:
	visible=span<0.35 and not areas.is_empty()
	if not visible:
		refresh_key=""
		return
	if multimesh==null:
		var stump:=CylinderMesh.new()
		stump.top_radius=0.00018
		stump.bottom_radius=0.00027
		stump.height=0.0005
		stump.radial_segments=8
		var material:=ShaderMaterial.new()
		var shader:=Shader.new()
		shader.code="""shader_type spatial;
render_mode cull_back;
uniform vec2 focus;
uniform float span;
varying vec3 world;
varying float cut_top;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;cut_top=max(NORMAL.y,0.0);}
void fragment(){
ALBEDO=mix(vec3(0.19,0.12,0.065),vec3(0.65,0.48,0.27),cut_top);
ROUGHNESS=0.95;
ALPHA=(1.0-smoothstep(0.04,0.06,distance(world.xz,focus)))*(1.0-smoothstep(0.18,0.35,span));
ALPHA_HASH_SCALE=1.0;
}"""
		material.shader=shader
		material_override=material
		multimesh=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=stump
	material_override.set_shader_parameter("focus",center)
	material_override.set_shader_parameter("span",span)
	var key:="%d:%d:%d" % [floori(center.x/CELL),floori(center.y/CELL),day]
	if not force and key==refresh_key: return
	refresh_key=key
	var points:=samples(center,areas,world_seed,cover,revealed)
	multimesh.instance_count=points.size()
	for index in points.size():
		var point:=points[index]
		multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(point.x,float(height.call(point))+0.0007,point.y)))
