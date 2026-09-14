extends RefCounted
## Ancient finds and civilization-made objects have disjoint artwork namespaces.
const COLLECTIONS := ["prehistoric-v1","early-civ-v1"]
const Early=preload("res://scripts/early_civ_artifacts.gd")
const Prehistory=preload("res://scripts/prehistoric_artifacts.gd")
const CACHE_LIMIT := 48
static var approved:Dictionary={}
static var loaded:=false
static var textures:Dictionary={}
static var order:Array[String]=[]

static func ensure_index()->void:
	if loaded:return
	loaded=true
	for collection:String in COLLECTIONS:
		var index_path:="res://assets/ui/artifacts/%s/index.json" % collection
		if not FileAccess.file_exists(index_path):continue
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(index_path))
		if parsed is Dictionary and parsed.get("version")==1 and parsed.get("approved") is Dictionary:approved[collection]=parsed.approved

static func image_path(item:Dictionary)->String:
	if item.get("kind","")!="artifact" or not item.has("catalogue_id"):return ""
	item=presentation(item)
	var id:=int(item.catalogue_id)
	if id<0 or id>=4096:return ""
	var collection:=String(item.get("art_collection",""))
	if collection=="prehistoric-v1":
		if item.get("artifact_origin")!="prehistoric" or item.get("source_id","")!="":return ""
	elif collection=="early-civ-v1":
		if item.get("artifact_origin")!="civilization" or String(item.get("source_id","")).is_empty():return ""
		if item.get("maker_requirements",[])!=Early.REQUIREMENTS[id%16]:return ""
	else:return ""
	ensure_index()
	var entry:Dictionary=approved.get(collection,{}).get(str(id),{})
	var expected:="res://assets/ui/artifacts/%s/artifact-%04d.png" % [collection,id]
	return expected if entry.get("path","")==expected else ""

static func presentation(item:Dictionary)->Dictionary:
	# Saves made before the art bank was integrated contain the stable catalogue
	# id but no origin namespace. Present physically recovered, ownerless objects
	# through the same prehistoric catalogue without mutating their study ledger.
	if item.get("kind","")=="artifact" and String(item.get("source_id","")).is_empty() and item.has("catalogue_id") and not item.has("artifact_origin"):
		var result:=item.duplicate(true)
		result.merge(Prehistory.definition(int(item.catalogue_id)),true)
		return result
	return item

static func texture(item:Dictionary)->Texture2D:
	var path:=image_path(item)
	if path.is_empty():return null
	if textures.has(path):
		order.erase(path);order.append(path)
		return textures[path]
	if not ResourceLoader.exists(path):return null
	var result:=load(path) as Texture2D
	if result==null:return null
	textures[path]=result;order.append(path)
	while order.size()>CACHE_LIMIT:textures.erase(order.pop_front())
	return result
