extends RefCounted
## Additive clothes use the existing body, face morphs and animation skeleton.
## The bundle's skin copy changes coverage only. Bind indices are translated by
## bone name, never assumed to match the order chosen by the glTF importer.
const OUTFITS:=["medieval","courtcoat","formal","business"]
const DIR:="res://assets/court_figures/wardrobe/"
const LEGACY_OUTFITS:=["hide","tunic","robe"]
const LEGACY_DIR:="res://assets/court_figures/legacy/"
const LEGACY_CACHE_LIMIT:=14
static var _cache:Dictionary={}
static var _legacy_manifest:Dictionary={}
static var _legacy_cache:Dictionary={}

static func parts(variant:String,target:Skin,skeleton:Skeleton3D)->Dictionary:
	if _cache.has(variant):return _cache[variant]
	var path:=DIR+"court_wardrobe_"+variant+".glb"
	var result:=_load_parts(path,target,skeleton)
	if not result.is_empty():_cache[variant]=result
	return result

## An absent or incomplete approved outfit keeps the original complete outfit.
## Each bundle keeps its original skin channels: G hide, B tunic, A robe.
static func legacy_manifest()->Dictionary:
	if _legacy_manifest.is_empty():
		var path:=LEGACY_DIR+"court_legacy.json"
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_legacy_manifest=parsed if parsed is Dictionary else {"variants":{}}
	return _legacy_manifest

static func legacy_parts(variant:String,outfit:String,target:Skin,skeleton:Skeleton3D)->Dictionary:
	if not outfit in LEGACY_OUTFITS or target==null or skeleton==null:return {}
	var catalog:=legacy_manifest()
	var entry:Dictionary=catalog.get("variants",{}).get(variant,{})
	if not outfit in entry.get("outfits",[]):return {}
	var names:Array=entry.get("parts",{}).get(outfit,[])
	if names.is_empty():return {}
	for name:Variant in names:
		if not name is String or not String(name).begins_with(outfit+"_"):return {}
	var file:=String(entry.get("file",""))
	if file.is_empty() or file.get_file()!=file:return {}
	var revision:="%s:%s:%s" % [String(catalog.get("revision","")),file,String(entry.get("sha256",""))]
	# Rebinding depends on the target order, even when two rigs use one body.
	var binds:=PackedStringArray()
	for i in target.get_bind_count():binds.append(String(_bind_name(target,skeleton,i)))
	var key:=revision+"|"+",".join(binds)
	var bundle:Dictionary=_legacy_cache.get(key,{})
	if bundle.is_empty():
		bundle=_load_parts(LEGACY_DIR+file,target,skeleton)
	if not bundle.has("LegacyBody"):return {}
	var chosen:Dictionary={}
	for name:String in names:
		if not bundle.has(name):return {}
		chosen[name]=bundle[name]
	if not _legacy_cache.has(key):
		if _legacy_cache.size()>=LEGACY_CACHE_LIMIT:_legacy_cache.erase(_legacy_cache.keys()[0])
		_legacy_cache[key]=bundle
	return {"skin":bundle.LegacyBody,"parts":chosen,"key":revision+":"+outfit}

static func _load_parts(path:String,target:Skin,skeleton:Skeleton3D)->Dictionary:
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
