extends Node
## Whole-game persistence. A save is the world seed plus the mutable state of
## every simulation autoload: systems with curated export_state()/import_state()
## use them (they carry validation and migrations); the rest are captured by
## reflection over their script variables. RNG state is saved exactly; transient
## objects and Callables are excluded. Deterministic caches rebuild, and
## the terrain scene reconstructs itself from the restored state.

const SAVE_DIR:="user://saves"
const SAVE_VERSION:=1
# Rebuild the fixed catalogue index; it is not campaign history.
const SOCIETY_REFLECT_SKIP:=["definitions_by_id"]
const DEFAULT_SLOT:="quicksave"

const CURATED_SYSTEMS:Array[String]=["ProgressionSystem","MilitaryCampaign","CivilizationSystem","ForeignDiplomacy","GeneralCampaign","WorldSimulation"]
const REFLECTED_SYSTEMS:Array[String]=["GameState","DiscoverySystem","ResourceSystem","EconomySystem","SettlementModel","GovernmentPeopleSystem","WorldFacts","AdvisorSystem","FoodSystem","ConsequenceEngine","PronouncementInterpreter","PeopleDirection","HistoricalFigures","CommunityNetwork","ForeignDialogue","CivicImplementationSystem","GeneralDialogue"]
# Deterministic caches that rebuild from the seed; persisting them would bloat
# saves and freeze stale copies of static content.
const REFLECT_SKIP:Dictionary={
	"ResourceSystem":["_surface_front_cache"],
	"GameState":["resource_settlement_id"],
	"SettlementModel":["_local_population_scope","_claim_shape_cache"],
	"FoodSystem":["_access_cache","_lever_cache"],
	"DiscoverySystem":["catalog","catalog_by_id","catalog_by_channel","technology_catalog","technology_limits","initialized","latest_context","era_by_id"],
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
	# A world day running in bounded steps commits before capture; saves never
	# hold a partial day, so the format needs no unfinished-work records.
	WorldSimulation.flush_day()
	if slot==DEFAULT_SLOT and GeneralCampaign.active:slot="river_war"
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var payload:Dictionary={
		"version":SAVE_VERSION,
		"metadata":{
			"saved_unix":Time.get_unix_time_from_system(),
			"game_release":String(ProjectSettings.get_setting("application/config/version","development")),
			"world_seed":GameState.world_seed,
			"elapsed_days":GameState.elapsed_days,
			"settlement_name":GameState.settlement_name,
			"population":GameState.population_total,
		},
	}
	for system_name in REFLECTED_SYSTEMS:
		payload["reflected_%s" % system_name]=_capture_reflected(get_node("/root/"+system_name),REFLECT_SKIP.get(system_name,[]))
	payload["reflected_society_model"]=_capture_reflected(DiscoverySystem.society_model,SOCIETY_REFLECT_SKIP)
	for system_name in CURATED_SYSTEMS:
		payload["curated_%s" % system_name]=get_node("/root/"+system_name).export_state()
	var written:=_write_payload(slot_path(slot),payload)
	if written.has("error"):return written
	return {"ok":true,"message":"World saved — %s, day %d, population %d." % [GameState.settlement_name if GameState.settlement_name!="" else "the settlement",int(GameState.elapsed_days),GameState.population_total]}


func _write_payload(path:String,payload:Dictionary)->Dictionary:
	# Do not truncate the last good save until the replacement is fully written.
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		return {"error":"The save could not be written (%s)." % path}
	file.store_line("TTWORLD2")
	file.store_buffer(var_to_bytes(payload))
	file.flush()
	var write_error:=file.get_error()
	file.close()
	if write_error!=OK:
		DirAccess.remove_absolute(temporary)
		return {"error":"The save could not be completed. The previous save is unchanged."}
	if DirAccess.rename_absolute(temporary,path)!=OK:
		return {"error":"The new save could not replace the previous save. The game remains open."}
	return {"ok":true}


## Restores the saved world into the autoload layer. The caller must reload
## the terrain scene afterwards so the rendered world rebuilds from the
## restored state (mirrors how _restart_world already works).
func load_game(slot:String=DEFAULT_SLOT)->Dictionary:
	# Finish the current world's day first; its steps must not run on loaded state.
	WorldSimulation.flush_day()
	var payload:=_read_payload(slot)
	if payload.is_empty(): return {"error":"No readable save exists in that slot."}
	if int(payload.get("version",-1))!=SAVE_VERSION: return {"error":"This save was written by an incompatible version."}
	var metadata:Dictionary=payload.get("metadata",{})
	# Older releases could lose this entire section after its popup was closed.
	# The missing choice cannot be invented; restore the world and reopen choice.
	var direction_missing:=payload.has("reflected_PeopleDirection") and payload.reflected_PeopleDirection==null
	if direction_missing:payload.reflected_PeopleDirection={}
	for name in REFLECTED_SYSTEMS:
		if payload.has("reflected_"+name) and not payload["reflected_"+name] is Dictionary:
			return {"error":"This save has an unreadable "+name+" section."}
	var parity_check:=WorldSimulation.check_payload(payload.get("curated_WorldSimulation",{}))
	if parity_check.has("error"):return parity_check
	var legacy_campaign:=not bool(payload.get("curated_WorldSimulation",{}).get("enabled",false)) and float(metadata.get("elapsed_days",0))>0
	var seed:=int(metadata.get("world_seed",GameState.world_seed))
	var human_check:=_validate_human_payload(payload,seed)
	if human_check.has("error"):return human_check
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
	# Rebuild omitted catalog caches before restoring the saved random stream.
	# Lazy initialization on the next day would reseed research after loading.
	DiscoverySystem.initialize()
	for system_name in REFLECTED_SYSTEMS:
		_apply_reflected(get_node("/root/"+system_name),payload.get("reflected_%s" % system_name,{}))
	_apply_reflected(DiscoverySystem.society_model,payload.get("reflected_society_model",{}),SOCIETY_REFLECT_SKIP)
	var errors:Array[String]=[]
	for system_name in CURATED_SYSTEMS:
		if system_name=="ForeignDiplomacy" and not payload.has("curated_ForeignDiplomacy"): continue
		var result:Variant=get_node("/root/"+system_name).import_state(payload.get("curated_%s" % system_name,{}))
		if result is Dictionary and (result as Dictionary).has("error"): errors.append("%s: %s" % [system_name,String((result as Dictionary).error)])
	if not errors.is_empty(): return {"error":"  ".join(errors)}
	var message:="World restored — day %d, population %d." % [int(GameState.elapsed_days),GameState.population_total]
	if direction_missing:message+=" This older save did not retain your civilization direction; choose it again when the world opens."
	if legacy_campaign:message+=" This campaign keeps its original opponent model. Start a new world for equal civilization rules."
	return {"ok":true,"legacy_campaign":legacy_campaign,"message":message}


func _read_payload(slot:String)->Dictionary:
	var path:=slot_path(slot)
	if not FileAccess.file_exists(path): return {}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	var header:=file.get_line()
	var payload:Variant
	if header=="TTWORLD2":payload=bytes_to_var(file.get_buffer(file.get_length()-file.get_position()))
	else:
		file.seek(0)
		payload=str_to_var(file.get_as_text())
	file.close()
	return payload if payload is Dictionary else {}


static func _capture_reflected(target:Object,skip:Array)->Dictionary:
	var state:Dictionary={}
	for property in target.get_property_list():
		if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE==0: continue
		var property_name:=String(property.name)
		if property_name in skip: continue
		var value:Variant=target.get(property_name)
		# Closed UI nodes may remain as freed references in an autoload. Testing
		# their class before validity aborts the entire section's capture.
		if typeof(value)==TYPE_OBJECT:
			if is_instance_valid(value) and value is RandomNumberGenerator:
				state["rng_state:"+property_name]=value.state
			continue
		if typeof(value) in [TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID,TYPE_NIL]: continue
		state[property_name]=value
	return state.duplicate(true)


static func _apply_reflected(target:Object,state:Dictionary,skip:Array=[])->void:
	## Arrays and dictionaries mutate in place so typed properties keep their
	## element types; scalars assign directly.
	for property_name in state:
		if property_name in skip:continue
		if String(property_name).begins_with("rng_state:"):
			var generator:Variant=target.get(String(property_name).trim_prefix("rng_state:"))
			if generator is RandomNumberGenerator:generator.state=int(state[property_name])
			continue
		var current:Variant=target.get(property_name)
		var value:Variant=state[property_name]
		if current is Array and value is Array:
			(current as Array).assign(value)
		elif current is Dictionary and value is Dictionary:
			(current as Dictionary).clear()
			(current as Dictionary).merge(value)
		else:
			target.set(property_name,value)

func _validate_human_payload(payload:Dictionary,seed_value:int)->Dictionary:
	if not preload("res://scripts/civic_administration.gd").valid(payload.get("reflected_GovernmentPeopleSystem",{}).get("administration_records",preload("res://scripts/civic_administration.gd").empty_state())):return {"error":"Invalid civic administration records."}
	var nutrition:=preload("res://scripts/crop_nutrition.gd")
	var culture:Variant=payload.get("reflected_PeopleDirection",{}).get("cultural_memory",preload("res://scripts/cultural_inheritance.gd").empty())
	if not preload("res://scripts/cultural_inheritance.gd").valid(culture):return {"error":"Invalid cultural inheritance."}
	var state:Dictionary=payload.get("reflected_GameState",{})
	var clothing=preload("res://scripts/household_clothing.gd")
	if not preload("res://scripts/fire_practice.gd").valid(state.get("fire_practice",preload("res://scripts/fire_practice.gd").empty_state())):return {"error":"Invalid maintained fire records."}
	var opening=preload("res://scripts/civilian_goods.gd")
	if not preload("res://scripts/undertaking_system.gd").valid(state.get("player_settlements",[])):return {"error":"Invalid undertaking records."}
	if not opening.valid(state.get("civilian_goods",opening.empty_state())) or not opening.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid civilian goods records."}
	var opportunities=preload("res://scripts/opening_opportunities.gd")
	if not opportunities.valid(state.get("opening_opportunities",opportunities.empty_state())):return {"error":"Invalid opening opportunity records."}
	if not clothing.valid(state.get("household_clothing",clothing.empty_state())) or not clothing.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid household clothing records."}
	if not preload("res://scripts/water_conveyance_state.gd").valid_state(state):return {"error":"Invalid water conveyance records."}
	if not preload("res://scripts/water_waste_works_state.gd").valid_state(state):return {"error":"Invalid water and waste works records."}
	if not preload("res://scripts/rail_freight_state.gd").valid_state(state):return {"error":"Invalid rail freight records."}
	if not preload("res://scripts/civilian_care_state.gd").valid_state(state):return {"error":"Invalid civilian clinical care records."}
	var batches=preload("res://scripts/food_batches.gd")
	if not batches.valid(state.get("food_batches",batches.empty_state())) or not batches.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid food batch records."}
	if not preload("res://scripts/building_material_operations.gd").valid_state(state):return {"error":"Invalid building material or curing records."}
	var grain=preload("res://scripts/grain_processing.gd")
	if not grain.valid(state.get("grain_processing",grain.empty_state())) or not grain.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid grain processing records."}
	var microscopy=preload("res://scripts/microscopy_samples.gd")
	if not microscopy.valid(state.get("microscopy",microscopy.empty_state())) or not microscopy.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid microscopy records."}
	var botany=preload("res://scripts/field_botany.gd")
	if not botany.valid(state.get("field_botany",botany.empty_state())) or not botany.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid field botany records."}
	if not nutrition.valid(state.get("cultivation_nutrients",nutrition.empty_state())) or not nutrition.valid_settlements(state.get("player_settlements",[])):return {"error":"Invalid cultivation nutrient reserves."}
	if not preload("res://scripts/technology_operations.gd").valid(payload.get("reflected_GameState",{}).get("technology_operations",preload("res://scripts/technology_operations.gd").empty_state())):return {"error":"Invalid technology installation records."}
	if payload.get("reflected_GameState",{}).get("research_notification_mode","milestones") not in ["milestones","all","quiet"]:return {"error":"Invalid research notification preference."}
	if not preload("res://scripts/society_exchange.gd").valid(payload.get("reflected_GameState",{}).get("society_exchange",preload("res://scripts/society_exchange.gd").empty_state())):return {"error":"Invalid society exchange records."}
	# Validate in a disposable owner scope before resetting any live civilization.
	var id:="__save_validation__"
	if WorldSimulation.actors.has(id):return {"error":"A save validation is already in progress."}
	WorldSimulation.create_actor(id,seed_value)
	var result:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:
		for name in REFLECTED_SYSTEMS:
			if name not in WorldSimulation.OWNED_SYSTEMS:continue
			_apply_reflected(WorldSimulation.system(name),payload.get("reflected_"+name,{}))
		_apply_reflected(WorldSimulation.discovery.society_model,payload.get("reflected_society_model",{}),SOCIETY_REFLECT_SKIP)
		for name in CURATED_SYSTEMS:
			if name=="WorldSimulation":continue
			if name=="ForeignDiplomacy" and not payload.has("curated_ForeignDiplomacy"):continue
			var restored:Dictionary=WorldSimulation.system(name).import_state(payload.get("curated_"+name,{}))
			if restored.has("error"):return {"error":name+": "+String(restored.error),"details":restored.get("details",[])}
		return {"ok":true}
	)
	for instance in WorldSimulation.actors[id].systems.values():instance.free()
	WorldSimulation.actors.erase(id)
	return result
