extends RefCounted
## Additive clothes use the existing body, face morphs and animation skeleton.
## The bundle's skin copy changes coverage only. Bind indices are translated by
## bone name, never assumed to match the order chosen by the glTF importer.
const OUTFITS:=["medieval","courtcoat","formal","business"]
const DIR:="res://assets/court_figures/wardrobe/"
static var _cache:Dictionary={}

static func parts(variant:String,target:Skin,skeleton:Skeleton3D)->Dictionary:
	if _cache.has(variant):return _cache[variant]
	var path:=DIR+"court_wardrobe_"+variant+".glb"
	if not ResourceLoader.exists(path):return {}
	var packed:=load(path) as PackedScene
	if packed==null:return {}
	var root:=packed.instantiate()
	var rigs:=root.find_children("*","Skeleton3D",true,false)
	if rigs.is_empty():root.free();return {}
	var rig:=rigs[0] as Skeleton3D
	var result:Dictionary={}
	for node:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or node.skin==null:continue
		var mapped:=_rebind(node.mesh,node.skin,rig,target,skeleton)
		if mapped==null:root.free();return {}
		result[String(node.name)]=mapped
	root.free()
	_cache[variant]=result
	return result

static func _bind_name(skin:Skin,rig:Skeleton3D,index:int)->StringName:
	var named:=skin.get_bind_name(index)
	if not named.is_empty():return named
	var bone:=skin.get_bind_bone(index)
	return rig.get_bone_name(bone) if bone>=0 and bone<rig.get_bone_count() else &""

static func _rebind(mesh:Mesh,source:Skin,rig:Skeleton3D,target:Skin,skeleton:Skeleton3D)->Mesh:
	var names:Dictionary={}
	for i in target.get_bind_count():names[_bind_name(target,skeleton,i)]=i
	var mapping:=PackedInt32Array()
	var identity:=true
	for i in source.get_bind_count():
		var name:=_bind_name(source,rig,i)
		if not names.has(name):push_error("Court wardrobe bone missing: "+String(name));return null
		mapping.append(int(names[name]))
		if mapping[i]!=i:identity=false
	if identity:return mesh
	var made:=ArrayMesh.new()
	made.blend_shape_mode=mesh.blend_shape_mode
	for i in mesh.get_blend_shape_count():made.add_blend_shape(mesh.get_blend_shape_name(i))
	for surface in mesh.get_surface_count():
		var arrays:=mesh.surface_get_arrays(surface)
		var bones:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		for i in bones.size():bones[i]=mapping[bones[i]]
		arrays[Mesh.ARRAY_BONES]=bones
		made.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,mesh.surface_get_blend_shape_arrays(surface))
		made.surface_set_material(surface,mesh.surface_get_material(surface))
	return made
