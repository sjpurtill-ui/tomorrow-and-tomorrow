extends RefCounted
## Bounded painted daylight through authored openings. Opaque room geometry and
## people still occlude it; this is atmosphere, never another source of light.
const SHADER:=preload("res://assets/court_sets/shaders/court_daylight.gdshader")
const MAX_RAYS:=2

static func build(apertures:Array,direction:Vector3,colour:Color,strength:float,z:=-3.78,scale_x:=1.0)->Array[MeshInstance3D]:
	var result:Array[MeshInstance3D]=[]
	if direction.y>=-.15 or direction.z<=.05 or strength<=0.0:return result
	var selected:Array=[]
	for raw in apertures:
		if raw is Array and raw.size()>=4 and float(raw[1])>.1 and float(raw[2])>.1 and float(raw[3])>float(raw[2]):selected.append(raw)
	if selected.size()>MAX_RAYS:selected=[selected.front(),selected.back()]
	for raw:Array in selected:
		var x:=float(raw[0])*scale_x;var half:=float(raw[1])*absf(scale_x)*.46
		var low:=float(raw[2])+.04;var high:=float(raw[3])-.04
		var points:Array[Vector3]=[Vector3(x-half,low,z),Vector3(x+half,low,z),Vector3(x+half,high,z),Vector3(x-half,high,z)]
		for i in 4:points.append(points[i]+direction*((points[i].y-.045)/-direction.y))
		var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array()
		for side in 4:
			var next:=(side+1)%4
			var corners:Array[Vector3]=[points[side],points[next],points[next+4],points[side+4]]
			var normal:=(corners[1]-corners[0]).cross(corners[2]-corners[0]).normalized()
			for index:int in [0,1,2,0,2,3]:
				vertices.append(corners[index]);normals.append(normal)
				uv.append([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)][index])
		var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv
		var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var mat:=ShaderMaterial.new();mat.shader=SHADER
		mat.set_shader_parameter("colour",colour);mat.set_shader_parameter("strength",clampf(strength,0.0,.12))
		var ray:=MeshInstance3D.new();ray.name="WindowDaylight%d"%result.size()
		ray.mesh=mesh;ray.material_override=mat;ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		result.append(ray)
	return result
