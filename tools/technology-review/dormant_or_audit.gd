extends RefCounted
## Editorial audit only. These identities are never added to the runtime graph.
const SOURCE:="res://docs/technology-review/master-catalog/biology-measurement-depth.json"
const PARENT_SOURCE:="res://docs/technology-review/master-catalog/medicine-biology-computation.json"
const DECLARATIONS:=[
	{"child":"plant_transpiration_measurement","parent":"photosynthetic_process_analysis","group":["photosynthetic_process_analysis","crop_calendars"]},
	{"child":"plant_pathology_diagnosis","parent":"germ_theory","group":["germ_theory","experimental_controls"]}
]
static func pending(catalog:Array)->Array:
	var index:Dictionary={}
	for entry:Dictionary in catalog:index[String(entry.get("id",""))]=true
	var result:Array=[]
	for declaration:Dictionary in DECLARATIONS:
		if index.has(declaration.child) and not index.has(declaration.parent):result.append(declaration.duplicate(true))
	return result

static func verify(index:Dictionary,declarations:Array)->Dictionary:
	var result:={"approved":[],"errors":[]}
	if declarations.is_empty():return result
	var source:Variant=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not source is Array:
		result.errors.append("Dormant OR audit: authored source unavailable or malformed")
		return result
	var authored:Dictionary={}
	for row:Variant in source:
		if row is Dictionary and row.get("id") is String:authored[row.id]=row
	var parent_rows:Variant=JSON.parse_string(FileAccess.get_file_as_string(PARENT_SOURCE))
	if not parent_rows is Array:
		result.errors.append("Dormant OR audit: authored parent source unavailable or malformed")
		return result
	var authored_parents:Dictionary={}
	for row:Variant in parent_rows:
		if row is Dictionary and row.get("id") is String:authored_parents[row.id]=row
	var seen:Dictionary={}
	for value:Variant in declarations:
		if not value is Dictionary or value.size()!=3 or not value.get("child") is String or not value.get("parent") is String or not value.get("group") is Array:
			result.errors.append("Dormant OR audit: malformed declaration");continue
		var d:Dictionary=value
		var key:=String(d.child)+":"+String(d.parent)
		if d not in DECLARATIONS or seen.has(key):
			result.errors.append("Dormant OR audit: unknown or duplicate declaration "+key);continue
		seen[key]=true
		if not index.has(d.child) or index.has(d.parent) or not authored.has(d.child) or not authored_parents.has(d.parent):
			result.errors.append("Dormant OR audit: invalid live/dormant identity "+key);continue
		var row:Dictionary=authored[d.child]
		var entry:Dictionary=index[d.child]
		if row.get("requires_all",[])!=entry.get("requires_all",entry.get("requires",[])) or row.get("requires_any",[])!=entry.get("requires_any",[]) or d.group not in row.get("requires_any",[]) or d.parent not in d.group:
			result.errors.append("Dormant OR audit: authored predicates differ "+key);continue
		if d.parent in entry.get("requires_all",entry.get("requires",[])):
			result.errors.append("Dormant OR audit: AND prerequisite cannot be dormant "+key);continue
		var live:=false
		for parent:Variant in d.group:
			if parent is String and index.has(parent):live=true
		if not live:
			result.errors.append("Dormant OR audit: no live OR alternative "+key);continue
		result.approved.append(d.duplicate(true))
	return result

## KnowledgePathways.graph_entry expands common predicates onto each route.
## Factor those exact suffixes back out in an AUDIT COPY so declarations refer
## to common OR edges, never to an acquisition route's own prerequisites.
static func factor_common(graph:Array,catalog:Array)->Array:
	var result:Array=graph.duplicate(true)
	var sources:Dictionary={}
	for entry:Dictionary in catalog:sources[String(entry.get("id",""))]=entry
	for projected:Dictionary in result:
		var selected:=false
		for d:Dictionary in DECLARATIONS:
			if d.child==projected.id:selected=true
		if not selected or not sources.has(projected.id):continue
		var entry:Dictionary=sources[projected.id]
		var common_all:Array=entry.get("requires_all",entry.get("requires",[]))
		var common_any:Array=entry.get("requires_any",[])
		var routes:Array=projected.get("learning_routes",[])
		if routes.is_empty() or not projected.get("requires_all",[]).is_empty() or not projected.get("requires_any",[]).is_empty():continue
		var matching:=true
		for route:Dictionary in routes:
			var all:Array=route.get("requires_all",[]);var any:Array=route.get("requires_any",[])
			if all.size()<common_all.size() or any.size()<common_any.size():matching=false;break
			if all.slice(all.size()-common_all.size())!=common_all or any.slice(any.size()-common_any.size())!=common_any:matching=false;break
		if not matching:continue
		projected.requires_all=common_all.duplicate()
		projected.requires_any=common_any.duplicate(true)
		for route:Dictionary in routes:
			route.requires_all=route.requires_all.slice(0,route.requires_all.size()-common_all.size())
			route.requires_any=route.requires_any.slice(0,route.requires_any.size()-common_any.size())
	return result
