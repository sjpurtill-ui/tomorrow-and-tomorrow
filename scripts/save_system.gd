extends Node
## Whole-game persistence. A save is the world seed plus the mutable state of
## every simulation autoload: systems with curated export_state()/import_state()
## use them (they carry validation and migrations); the rest are captured by
## reflection over their script variables. Objects, Callables, and RNGs are
## never serialized — deterministic caches rebuild from the seed on load, and
## the terrain scene reconstructs itself from the restored state.

const SAVE_DIR:="user://saves"
const SAVE_VERSION:=1
const DEFAULT_SLOT:="quicksave"

const CURATED_SYSTEMS:Array[String]=["ProgressionSystem","MilitaryCampaign","CivilizationSystem","ForeignDiplomacy"]
const REFLECTED_SYSTEMS:Array[String]=["GameState","DiscoverySystem","ResourceSystem","EconomySystem","SettlementModel","GovernmentPeopleSystem","WorldFacts","AdvisorSystem","FoodSystem","ConsequenceEngine","PronouncementInterpreter"]
# Deterministic caches that rebuild from the seed; persisting them would bloat
# saves and freeze stale copies of static content.
const REFLECT_SKIP:Dictionary={
	"GameState":["resource_settlement_id"],
	"SettlementModel":["_local_population_scope"],
	"DiscoverySystem":["catalog","catalog_by_id","catalog_by_channel","technology_catalog","technology_limits","initialized","latest_context"],
	# In-flight HTTP requests contain transient nodes and authorization headers.
	# They are neither world state nor safe save-file content; the matching civic
	# order is persisted and reopened as an interrupted conversation on load.
	"PronouncementInterpreter":["_requests","_request_serial","_semantic_cache","_semantic_cache_order","_routing_stats"],
}


func slot_path(slot:String)->String:
	return "%s/%s.save" % [SAVE_DIR,slot]


func save_metadata(slot:String=DEFAULT_SLOT)->Dictionary:
	var payload:=_read_payload(slot)
	return (payload.get("metadata",{}) as Dictionary).duplicate(true)


func save_game(slot:String=DEFAULT_SLOT)->Dictionary:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var payload:Dictionary={
		"version":SAVE_VERSION,
		"metadata":{
			"saved_unix":Time.get_unix_time_from_system(),
			"world_seed":GameState.world_seed,
			"elapsed_days":GameState.elapsed_days,
			"settlement_name":GameState.settlement_name,
			"population":GameState.population_total,
		},
	}
	for system_name in REFLECTED_SYSTEMS:
		payload["reflected_%s" % system_name]=_capture_reflected(get_node("/root/"+system_name),REFLECT_SKIP.get(system_name,[]))
	payload["reflected_society_model"]=_capture_reflected(DiscoverySystem.society_model,[])
	for system_name in CURATED_SYSTEMS:
		payload["curated_%s" % system_name]=get_node("/root/"+system_name).export_state()
	var file:=FileAccess.open(slot_path(slot),FileAccess.WRITE)
	if file==null:
		return {"error":"The save could not be written (%s)." % slot_path(slot)}
	file.store_string(var_to_str(payload))
	file.close()
	return {"ok":true,"message":"World saved — %s, day %d, population %d." % [GameState.settlement_name if GameState.settlement_name!="" else "the settlement",int(GameState.elapsed_days),GameState.population_total]}


## Restores the saved world into the autoload layer. The caller must reload
## the terrain scene afterwards so the rendered world rebuilds from the
## restored state (mirrors how _restart_world already works).
func load_game(slot:String=DEFAULT_SLOT)->Dictionary:
	var payload:=_read_payload(slot)
	if payload.is_empty(): return {"error":"No readable save exists in that slot."}
	if int(payload.get("version",-1))!=SAVE_VERSION: return {"error":"This save was written by an incompatible version."}
	var metadata:Dictionary=payload.get("metadata",{})
	var seed:=int(metadata.get("world_seed",GameState.world_seed))
	# Clean baseline on the saved seed first, so unsaved caches sit at known
	# values; then lay the saved state over it.
	GameState.reset_for_new_world(seed)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldFacts.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	for system_name in REFLECTED_SYSTEMS:
		_apply_reflected(get_node("/root/"+system_name),payload.get("reflected_%s" % system_name,{}))
	_apply_reflected(DiscoverySystem.society_model,payload.get("reflected_society_model",{}))
	var errors:Array[String]=[]
	for system_name in CURATED_SYSTEMS:
		if system_name=="ForeignDiplomacy" and not payload.has("curated_ForeignDiplomacy"): continue
		var result:Variant=get_node("/root/"+system_name).import_state(payload.get("curated_%s" % system_name,{}))
		if result is Dictionary and (result as Dictionary).has("error"): errors.append("%s: %s" % [system_name,String((result as Dictionary).error)])
	if not errors.is_empty(): return {"error":"  ".join(errors)}
	return {"ok":true,"message":"World restored — day %d, population %d." % [int(GameState.elapsed_days),GameState.population_total]}


func _read_payload(slot:String)->Dictionary:
	var path:=slot_path(slot)
	if not FileAccess.file_exists(path): return {}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	var payload:Variant=str_to_var(file.get_as_text())
	file.close()
	return payload if payload is Dictionary else {}


static func _capture_reflected(target:Object,skip:Array)->Dictionary:
	var state:Dictionary={}
	for property in target.get_property_list():
		if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE==0: continue
		var property_name:=String(property.name)
		if property_name in skip: continue
		var value:Variant=target.get(property_name)
		if typeof(value) in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID,TYPE_NIL]: continue
		state[property_name]=value
	return state.duplicate(true)


static func _apply_reflected(target:Object,state:Dictionary)->void:
	## Arrays and dictionaries mutate in place so typed properties keep their
	## element types; scalars assign directly.
	for property_name in state:
		var current:Variant=target.get(property_name)
		var value:Variant=state[property_name]
		if current is Array and value is Array:
			(current as Array).assign(value)
		elif current is Dictionary and value is Dictionary:
			(current as Dictionary).clear()
			(current as Dictionary).merge(value)
		else:
			target.set(property_name,value)
