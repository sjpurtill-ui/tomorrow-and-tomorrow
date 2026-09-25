extends RefCounted
## Forms of rule and court, derived only from what a people knows.
##
## The stages live in data/civic/civic_stages.json (see docs/CIVIC_EVOLUTION.md).
## Nothing here is saved: a people's stage is re-derived from its known
## discoveries every time it is asked, so older saves find their court without
## any new field. GovernmentPeopleSystem stays the owner of offices and people;
## this only tells it which titles, extra offices and ceremony the era allows.
##
## Two tracks diverge after the chief's hall: peoples whose institutions lean
## toward assemblies (elected magistrates, lot, majority votes) get an assembly
## and a council house; peoples leaning toward kingship get a palace, then an
## imperial court. Stages marked "any" are open to both.

const DATA_PATH:="res://data/civic/civic_stages.json"
## The single mapping of 1200-1800 research ids onto stages, tracks and
## offices. Those ids activate once a built research block makes them known.
const Y1200_PATH:="res://data/civic/y1200_triggers.json"
const Voice:=preload("res://scripts/character_voice.gd")
const DEFAULT_ID:="hearth_council"

## Tests and captures may pin the stage; "" follows the people's knowledge.
static var stage_override:=""
static var _data:Dictionary={}
static var _by_id:Dictionary={}
static var _cache_key:=""
static var _cache:Dictionary={}
static var _cache_held:Dictionary={}
## Last stage seen per civilization this session (not saved), for dated
## "the court changes" events. The first sighting after a load is silent.
static var _seen:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data=parsed if parsed is Dictionary else {"stages":[]}
		_by_id.clear()
		for stage_variant in _data.get("stages",[]):
			var entry:Dictionary=stage_variant
			_by_id[String(entry.get("id",""))]=entry
		_merge_y1200()
	return _data

static func _merge_y1200()->void:
	## Fold the 1200-1800 id mapping into the loaded stages: an alternative
	## requirement set per stage, extra track markers and office triggers.
	if not FileAccess.file_exists(Y1200_PATH): return
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(Y1200_PATH))
	if not parsed is Dictionary: return
	var later:Dictionary=parsed
	var alternatives:Dictionary=later.get("stages",{})
	for stage_id in alternatives:
		if not _by_id.has(String(stage_id)): continue
		var entry:Dictionary=_by_id[String(stage_id)]
		entry["alt_requires"]=(entry.get("alt_requires",[]) as Array)+(alternatives[stage_id] as Array)
	var tracks:Dictionary=_data.get("tracks",{})
	var extra_tracks:Dictionary=later.get("tracks",{})
	for track in extra_tracks:
		tracks[track]=(tracks.get(track,[]) as Array)+(extra_tracks[track] as Array)
	_data["tracks"]=tracks
	var office_ids:Dictionary=later.get("offices",{})
	for office_variant in _data.get("offices",[]):
		var office:Dictionary=office_variant
		var key:=String(office.get("key",""))
		if office_ids.has(key): office["requires_any"]=(office.get("requires_any",[]) as Array)+(office_ids[key] as Array)

static func reload()->void:
	_data={};_by_id.clear();_cache_key="";_cache={};_cache_held={}

static func stages()->Array:
	return data().get("stages",[])

static func stage(stage_id:String)->Dictionary:
	data()
	return _by_id.get(stage_id,_by_id.get(DEFAULT_ID,{}))

static func ids()->Array[String]:
	var out:Array[String]=[]
	for stage_variant in stages(): out.append(String((stage_variant as Dictionary).get("id","")))
	return out

static func rank_of(stage_id:String)->int:
	return int(stage(stage_id).get("rank",0))

static func known_for(owner:String="player")->Array:
	## The player's knowledge honours CharacterVoice.knowledge_override so the
	## court, the officials' speech and their titles always agree.
	if owner=="player" or owner=="":
		if Voice.knowledge_override.has("player"): return Voice.knowledge_override["player"]
		if Engine.get_main_loop()!=null and WorldSimulation.actor_id!="player":
			return WorldSimulation.state.known_discoveries
	return Voice.known_ids(owner)

static func _set_of(known:Array)->Dictionary:
	var out:Dictionary={}
	for id in known: out[String(id)]=true
	return out

static func _group_met(group:Dictionary,known:Dictionary)->bool:
	var need:=maxi(1,int(group.get("min",1)))
	var have:=0
	for id in group.get("any",[]):
		if known.has(String(id)):
			have+=1
			if have>=need: return true
	return false

static func _groups_met(groups:Array,known:Dictionary)->bool:
	for group in groups:
		if not _group_met(group,known): return false
	return true

static func requirements_met(stage_record:Dictionary,known:Dictionary)->bool:
	## The stage's own requirements, or any alternative set (the 1200-1800 ids).
	## A stage marked y1200_only has no requirements of its own.
	if not bool(stage_record.get("y1200_only",false)) and _groups_met(stage_record.get("requires",[]),known): return true
	for alternative in stage_record.get("alt_requires",[]):
		if not (alternative as Array).is_empty() and _groups_met(alternative,known): return true
	return false

static func lean(known:Variant,form:String="")->String:
	## "assembly" or "throne": which way this people's institutions point.
	var held:Dictionary=known if known is Dictionary else _set_of(known as Array)
	var tracks:Dictionary=data().get("tracks",{})
	var throne:=0
	var assembly:=0
	for id in tracks.get("throne",[]):
		if held.has(String(id)): throne+=1
	for id in tracks.get("assembly",[]):
		if held.has(String(id)): assembly+=1
	if assembly>throne: return "assembly"
	if assembly==throne and assembly>0 and form!="centralized": return "assembly"
	return "throne"

static func derive(known:Array,form:String="")->Dictionary:
	## The stage record this knowledge supports, plus "lean" and "era_tier".
	var held:=_set_of(known)
	var way:=lean(held,form)
	var eligible:Array[Dictionary]=[]
	for stage_variant in stages():
		var record:Dictionary=stage_variant
		if requirements_met(record,held): eligible.append(record)
	# Keep to the people's own track when that track offers anything at all;
	# a would-be city-state still had chiefs and kings before its assembly.
	var own_track:=eligible.any(func(r:Dictionary)->bool:return String(r.get("track","any"))==way)
	var best:Dictionary=stage(DEFAULT_ID)
	for record in eligible:
		var track:=String(record.get("track","any"))
		if own_track and track!="any" and track!=way: continue
		if int(record.get("rank",0))>int(best.get("rank",0)): best=record
	# The era floor: a people whose material world outran its recorded
	# institutions (older saves, catalog-only worlds) keeps a fitting court.
	var tier:=Voice.era_tier(_tags_for(held))
	var floors:Array=data().get("floor_by_tier",[])
	if tier<floors.size():
		var minimum:=stage(String(floors[tier]))
		var minimum_track:=String(minimum.get("track","any"))
		var allowed:=minimum_track=="any" or minimum_track==way or not own_track
		if allowed and int(minimum.get("rank",0))>int(best.get("rank",0)): best=minimum
	var result:=best.duplicate()
	result["lean"]=way
	result["era_tier"]=tier
	return result

static func _tags_for(held:Dictionary)->Array[String]:
	var out:Array[String]=[]
	for tag:String in Voice.ERA_GATES:
		for id in Voice.ERA_GATES[tag].ids:
			if held.has(String(id)): out.append(tag); break
	return out

static func _form_hint()->String:
	if Engine.get_main_loop()==null: return ""
	return GovernmentPeopleSystem.government_form()

static func current(owner:String="player")->Dictionary:
	## The court stage of this people now. Cached on its knowledge.
	if stage_override!="":
		var pinned:=stage(stage_override).duplicate()
		pinned["lean"]=String(pinned.get("track","throne")) if String(pinned.get("track","any"))!="any" else "throne"
		return pinned
	_refresh(owner)
	return _cache

static func held(owner:String="player")->Dictionary:
	## The people's known discoveries as a set, cached with current().
	_refresh(owner)
	return _cache_held

static func _scope(owner:String)->String:
	if owner!="player" and owner!="": return owner
	if Engine.get_main_loop()!=null and WorldSimulation.actor_id!="player": return String(WorldSimulation.actor_id)
	return "player"

static func _refresh(owner:String)->void:
	var known:=known_for(owner)
	var scope:=_scope(owner)
	var form:=_form_hint() if scope=="player" else ""
	var tail:=""
	if known.size()<256: tail=str(hash(known))
	elif not known.is_empty(): tail=String(known.back())
	var key:="%s|%s|%d|%s|%s" % [scope,form,known.size(),tail,stage_override]
	if key==_cache_key and not _cache.is_empty(): return
	_cache_held=_set_of(known)
	_cache=derive(known,form)
	_cache_key=key

static func current_id(owner:String="player")->String:
	return String(current(owner).get("id",DEFAULT_ID))

static func office_title(stage_record:Dictionary,office_key:String)->String:
	## The stage's title for an office, or "" when the stage keeps the older
	## size-and-form titles (the hearth council does).
	return String((stage_record.get("titles",{}) as Dictionary).get(office_key,""))

static func office_definitions()->Array:
	return data().get("offices",[])

static func office_open(definition:Dictionary,stage_record:Dictionary,known:Variant,government_stage:int)->bool:
	## Whether an office added by discovery (HighPriest, Justice, Treasurer)
	## sits at this people's court now.
	if government_stage<int(definition.get("min_government_stage",0)): return false
	if int(stage_record.get("rank",0))<int(definition.get("min_rank",0)): return false
	if String(definition.get("key","")) in (stage_record.get("abolish",[]) as Array): return false
	var held:Dictionary=known if known is Dictionary else _set_of(known as Array)
	for id in definition.get("requires_any",[]):
		if held.has(String(id)): return true
	return false

static func address_options(stage_record:Dictionary)->Array:
	if String(stage_record.get("address_mode","dialect"))!="stage": return []
	return stage_record.get("address",[])

static func protocol_line(stage_record:Dictionary)->String:
	return String((stage_record.get("protocol",{}) as Dictionary).get("line",""))

static func art_path(stage_id:String)->String:
	return "%s/%s.png" % [String(data().get("art_dir","res://assets/ui/court")),stage_id]

static func note_change(owner:String="player")->Dictionary:
	## {} normally; the old and new stage when this people's court changed
	## since last asked this session. The first sighting only records.
	var now:=current_id(owner)
	var scope:=_scope(owner)
	var before:=String(_seen.get(scope,""))
	_seen[scope]=now
	if before=="" or before==now: return {}
	return {"from":before,"to":now}
