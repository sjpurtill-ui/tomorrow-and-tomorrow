class_name InteractionStore
extends RefCounted
## Append-only local database of player interactions.
##
## Two stores are read as one:
##   * shipped   res://data/interactions/**/*.jsonl  (curated packs, read-only)
##   * player    user://interactions/interactions_NNNNNN.jsonl  (append-only,
##               rotated, bounded; stays on this device, never committed)
## One JSON record per line. Every write is appended and flushed immediately, so
## a crash can lose at most a partial last line, which loading skips. Loading is
## lazy: nothing is read until the first query. See docs/INTERACTION_DATABASE.md.

const _Text:=preload("res://scripts/interaction_text.gd")
const _Types:=preload("res://scripts/interaction_types.gd")
const _Context:=preload("res://scripts/interaction_context.gd")
const _Mode:=preload("res://scripts/ai_mode.gd")

const SCHEMA_VERSION:=1
const SHIPPED_ROOT:="res://data/interactions/"
const DEFAULT_USER_ROOT:="user://interactions/"
const FILE_PREFIX:="interactions_"
const BUNDLE_MAGIC:="tomorrow-interactions-bundle"
const SOURCES:Array[String]=["live","seed","curated","imported","offline"]
const MAX_TEXT:=600
const MAX_REPLY:=1600

static var user_root:String=DEFAULT_USER_ROOT
static var shipped_root:String=SHIPPED_ROOT
static var max_file_bytes:int=1000000
static var max_files:int=24
static var include_shipped:bool=true

static var _loaded:bool=false
static var _records:Array=[]
static var _ids:Dictionary={}
static var _revision:int=0
static var _serial:int=0
static var last_error:String=""

# ---------------------------------------------------------------- recording

## Appends one interaction. Missing intent/context fields are derived. Returns
## the stored id, or "" when recording is disabled or the write failed.
static func record(raw:Dictionary,force:bool=false)->String:
	if not force and not _Mode.records_interactions(): return ""
	var rec:Dictionary=sanitize(raw)
	if rec.is_empty(): return ""
	if not _append_line(JSON.stringify(rec)): return ""
	if _loaded: _add(rec)
	return String(rec.id)

## Normalises and bounds a record to the stored schema. Unknown fields are
## dropped; credentials are redacted; context is reduced to a band signature.
static func sanitize(raw:Dictionary)->Dictionary:
	var text_raw:String=_Text.redact(String(raw.get("player_text_raw",raw.get("player_text","")))).strip_edges().substr(0,MAX_TEXT)
	if text_raw.is_empty(): return {}
	_serial+=1
	var id:String=String(raw.get("id",""))
	if id.is_empty(): id="i%d-%d-%04d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()%1000000,_serial%10000]
	var surface:String=String(raw.get("surface","civic")).to_lower().substr(0,24)
	var intent_in:Dictionary=raw.get("intent",{}) if raw.get("intent") is Dictionary else {}
	var cls:Dictionary={}
	if not intent_in.has("type_id") or not intent_in.has("speech_act"): cls=_Types.classify(text_raw)
	var intent:Dictionary={
		"speech_act":String(intent_in.get("speech_act",cls.get("speech_act","order"))).substr(0,16),
		"type_id":String(intent_in.get("type_id",cls.get("type_id",_Types.FALLBACK_TYPE))).substr(0,48),
		"type_confidence":clampf(float(intent_in.get("type_confidence",cls.get("confidence",0.0))),0.0,1.0),
		"topic":String(intent_in.get("topic",cls.get("topic",""))).substr(0,80),
		"policy_ids":_string_list(intent_in.get("policy_ids",cls.get("policy_ids",[])),6,48),
		"directive_type":String(intent_in.get("directive_type","")).substr(0,48),
	}
	var ctx_in:Variant=raw.get("context",{})
	var sig:Dictionary={}
	if ctx_in is Dictionary:
		var c:Dictionary=ctx_in as Dictionary
		sig=_clean_signature(c) if c.has("pop_band") else _Context.signature(c)
	var speaker_in:Dictionary=raw.get("speaker",{}) if raw.get("speaker") is Dictionary else {}
	var model_id:String=String(speaker_in.get("model","")).to_lower().substr(0,32)
	var speaker:Dictionary={"role":String(speaker_in.get("role","")).substr(0,40),"model":model_id,
		"family":String(speaker_in.get("family",_Types.family_for_model(model_id) if not model_id.is_empty() else "")).substr(0,24)}
	var out_in:Dictionary=raw.get("output",{}) if raw.get("output") is Dictionary else {}
	var output:Dictionary={
		"reply":_Text.redact(String(out_in.get("reply",""))).strip_edges().substr(0,MAX_REPLY),
		"summary":_Text.redact(String(out_in.get("summary",""))).strip_edges().substr(0,300),
		"effects":_clean_effects(out_in.get("effects",[])),
		"side_effects":_clean_side(out_in.get("side_effects",[])),
		"policy_ids":_string_list(out_in.get("policy_ids",[]),6,48),
	}
	if out_in.has("reply_template"): output["reply_template"]=String(out_in.reply_template).substr(0,MAX_REPLY)
	if out_in.get("counted") is Dictionary:
		var cnt:Dictionary=out_in.counted
		output["counted"]={"kind":String(cnt.get("kind","")).substr(0,32),"count":clampi(int(cnt.get("count",0)),0,1000000)}
	var source:String=String(raw.get("source","live"))
	if not (source in SOURCES): source="live"
	var usage_in:Dictionary=raw.get("usage",{}) if raw.get("usage") is Dictionary else {}
	var usage:Dictionary={}
	for k:String in ["prompt_tokens","completion_tokens","total_tokens"]:
		if usage_in.get(k) is int or usage_in.get(k) is float: usage[k]=maxi(0,int(usage_in[k]))
	var rec:Dictionary={"v":SCHEMA_VERSION,"id":id.substr(0,64),"day":int(raw.get("day",-1)),"ts":int(raw.get("ts",int(Time.get_unix_time_from_system()))),
		"surface":surface,"speaker":speaker,"player_text_raw":text_raw,"player_text":_Text.normalize(text_raw),
		"intent":intent,"context":sig,"output":output,"source":source,"model":String(raw.get("model","")).substr(0,80),"usage":usage,
		"accepted":bool(raw.get("accepted",true))}
	if raw.has("latency_ms"): rec["latency_ms"]=maxi(0,int(raw.latency_ms))
	return rec

static func _string_list(v:Variant,limit:int,width:int)->Array:
	var out:Array=[]
	if v is Array:
		for x:Variant in v:
			if out.size()>=limit: break
			var s:String=String(x).substr(0,width)
			if not s.is_empty(): out.append(s)
	return out

static func _clean_signature(c:Dictionary)->Dictionary:
	var bands:Dictionary={}
	var mb:Variant=c.get("metric_bands",{})
	if mb is Dictionary:
		for k:Variant in mb:
			var b:String=String((mb as Dictionary)[k])
			if b in _Context.METRIC_BANDS: bands[String(k).substr(0,32)]=b
	var sig:Dictionary={"era_tier":clampi(int(c.get("era_tier",1)),0,3),"pop_band":String(c.get("pop_band","hamlet")) if String(c.get("pop_band","")) in _Context.POP_BANDS else "hamlet","metric_bands":bands}
	if String(c.get("food_band","")) in _Context.FOOD_BANDS: sig["food_band"]=String(c.food_band)
	return sig

static func _clean_effects(v:Variant)->Array:
	var out:Array=[]
	if not (v is Array): return out
	for e:Variant in v:
		if out.size()>=8: break
		if not (e is Dictionary): continue
		var d:Dictionary=e as Dictionary
		var metric:String=String(d.get("metric","")).substr(0,32)
		var delta:float=float(d.get("delta",0.0))
		var unc:float=float(d.get("uncertainty",0.0))
		if metric.is_empty() or not is_finite(delta) or not is_finite(unc): continue
		out.append({"metric":metric,"delta":clampf(delta,-0.08,0.08),"uncertainty":clampf(unc,0.0,0.08),
			"duration_days":clampf(float(d.get("duration_days",0.0)),0.0,3650.0),"reason":String(d.get("reason","")).substr(0,240)})
	return out

static func _clean_side(v:Variant)->Array:
	var out:Array=[]
	if not (v is Array): return out
	for e:Variant in v:
		if out.size()>=6: break
		if e is Dictionary:
			var d:Dictionary=e as Dictionary
			out.append({"id":String(d.get("id","")).substr(0,40),"odds":clampf(float(d.get("odds",0.0)),0.0,1.0),"description":String(d.get("description","")).substr(0,200)})
	return out

# ---------------------------------------------------------------- files

static func _user_files()->PackedStringArray:
	var files:PackedStringArray=PackedStringArray()
	if not DirAccess.dir_exists_absolute(user_root): return files
	for f:String in DirAccess.get_files_at(user_root):
		if f.begins_with(FILE_PREFIX) and f.ends_with(".jsonl"): files.append(f)
	files.sort()
	return files

static func user_files()->PackedStringArray:
	var out:PackedStringArray=PackedStringArray()
	for f:String in _user_files(): out.append(user_root.path_join(f))
	return out

static func user_bytes()->int:
	var total:int=0
	for p:String in user_files():
		var fa:FileAccess=FileAccess.open(p,FileAccess.READ)
		if fa!=null: total+=int(fa.get_length())
	return total

static func _seq_of(file_name:String)->int:
	return int(file_name.trim_prefix(FILE_PREFIX).trim_suffix(".jsonl"))

static func _append_line(line:String)->bool:
	if not DirAccess.dir_exists_absolute(user_root):
		var mk:Error=DirAccess.make_dir_recursive_absolute(user_root)
		if mk!=OK:
			last_error="Could not create %s (%s)." % [user_root,error_string(mk)]
			return false
	var files:PackedStringArray=_user_files()
	var seq:int=1 if files.is_empty() else _seq_of(files[files.size()-1])
	var path:String=user_root.path_join("%s%06d.jsonl" % [FILE_PREFIX,seq])
	var bytes:int=line.to_utf8_buffer().size()+1
	if FileAccess.file_exists(path):
		var probe:FileAccess=FileAccess.open(path,FileAccess.READ)
		if probe!=null and int(probe.get_length())+bytes>max_file_bytes and int(probe.get_length())>0:
			seq+=1
			path=user_root.path_join("%s%06d.jsonl" % [FILE_PREFIX,seq])
		probe=null
	var fa:FileAccess=FileAccess.open(path,FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path,FileAccess.WRITE)
	if fa==null:
		last_error="Could not open %s (%s)." % [path,error_string(FileAccess.get_open_error())]
		return false
	fa.seek_end()
	fa.store_line(line)
	fa.flush()
	fa=null
	_prune()
	return true

## Keeps at most max_files rotated files; the oldest are removed first.
static func _prune()->void:
	var files:PackedStringArray=_user_files()
	var excess:int=files.size()-max_files
	for i:int in range(maxi(0,excess)):
		var err:Error=DirAccess.remove_absolute(user_root.path_join(files[i]))
		if err!=OK: last_error="Could not rotate %s (%s)." % [files[i],error_string(err)]

static func _read_jsonl(path:String,into:Array)->int:
	var fa:FileAccess=FileAccess.open(path,FileAccess.READ)
	if fa==null: return 0
	var n:int=0
	var parser:JSON=JSON.new()
	while not fa.eof_reached():
		var line:String=fa.get_line().strip_edges()
		if line.is_empty() or not line.begins_with("{"): continue
		if parser.parse(line)!=OK: continue
		var data:Variant=parser.data
		if data is Dictionary and (data as Dictionary).has("player_text_raw"):
			into.append(data); n+=1
	return n

static func _walk_jsonl(root:String,out:Array[String])->void:
	if not DirAccess.dir_exists_absolute(root): return
	for f:String in DirAccess.get_files_at(root):
		if f.ends_with(".jsonl"): out.append(root.path_join(f))
	for d:String in DirAccess.get_directories_at(root): _walk_jsonl(root.path_join(d),out)

# ---------------------------------------------------------------- loading

static func ensure_loaded()->void:
	if _loaded: return
	_loaded=true
	_records.clear(); _ids.clear()
	var found:Array=[]
	if include_shipped:
		var shipped:Array[String]=[]
		_walk_jsonl(shipped_root,shipped)
		shipped.sort()
		for p:String in shipped: _read_jsonl(p,found)
	for p:String in user_files(): _read_jsonl(p,found)
	for r:Variant in found: _add(r as Dictionary)
	_revision+=1

static func _add(rec:Dictionary)->void:
	var id:String=String(rec.get("id",""))
	if not id.is_empty() and _ids.has(id): return
	if not id.is_empty(): _ids[id]=_records.size()
	_records.append(rec)
	_revision+=1

static func records()->Array:
	ensure_loaded()
	return _records

static func size()->int:
	ensure_loaded()
	return _records.size()

static func revision()->int:
	return _revision

static func is_loaded()->bool:
	return _loaded

## Forget everything in memory; the next query reloads from disk.
static func reload_from_disk()->void:
	_loaded=false
	_records.clear(); _ids.clear()
	_revision+=1

## Adds already-sanitised records to memory only (synthetic tests, previews).
static func add_in_memory(list:Array)->void:
	ensure_loaded()
	for r:Variant in list:
		if r is Dictionary: _add(r as Dictionary)

## Tests: point both stores at isolated folders and forget cached state.
static func configure_for_tests(user_dir:String,shipped_dir:String,file_bytes:int=1000000,file_count:int=24)->void:
	user_root=user_dir
	shipped_root=shipped_dir
	max_file_bytes=file_bytes
	max_files=file_count
	reload_from_disk()

# ---------------------------------------------------------------- portability

## Writes a portable JSONL bundle: a header line, then one record per line.
## By default only the player's own records are exported.
static func export_bundle(path:String="",with_shipped:bool=false)->Dictionary:
	ensure_loaded()
	var target:String=path
	if target.is_empty():
		var exports:String=user_root.path_join("exports")
		var mk:Error=DirAccess.make_dir_recursive_absolute(exports)
		if mk!=OK and not DirAccess.dir_exists_absolute(exports): return {"ok":false,"error":"Could not create %s." % exports}
		target=exports.path_join("interactions_%s.jsonl" % Time.get_datetime_string_from_system(true).replace(":","").replace("-",""))
	var chosen:Array=[]
	for r:Variant in _records:
		var rec:Dictionary=r as Dictionary
		if with_shipped or not (String(rec.get("source","live")) in ["seed","curated"]): chosen.append(rec)
	_ensure_parent(target)
	var fa:FileAccess=FileAccess.open(target,FileAccess.WRITE)
	if fa==null: return {"ok":false,"error":"Could not write %s (%s)." % [target,error_string(FileAccess.get_open_error())]}
	fa.store_line(JSON.stringify({"bundle":BUNDLE_MAGIC,"schema":SCHEMA_VERSION,"count":chosen.size(),"exported_unix":int(Time.get_unix_time_from_system()),"types_version":1}))
	for rec:Variant in chosen: fa.store_line(JSON.stringify(rec))
	fa.flush()
	return {"ok":true,"path":target,"count":chosen.size()}

## Reads a bundle (or any interaction JSONL). Every record is re-sanitised and
## de-duplicated by id. target "user" appends to this device's store; any other
## value is treated as an output .jsonl path (curation into res://data/interactions/),
## with records relabelled to `relabel_source` when given.
static func import_bundle(path:String,target:String="user",relabel_source:String="")->Dictionary:
	var fa:FileAccess=FileAccess.open(path,FileAccess.READ)
	if fa==null: return {"ok":false,"error":"Could not read %s." % path}
	ensure_loaded()
	var parser:JSON=JSON.new()
	var added:int=0
	var skipped:int=0
	var out:FileAccess=null
	var seen:Dictionary={}
	if target!="user":
		_ensure_parent(target)
		out=FileAccess.open(target,FileAccess.WRITE)
		if out==null: return {"ok":false,"error":"Could not write %s." % target}
	while not fa.eof_reached():
		var line:String=fa.get_line().strip_edges()
		if line.is_empty(): continue
		if parser.parse(line)!=OK or not (parser.data is Dictionary): skipped+=1; continue
		var raw:Dictionary=parser.data as Dictionary
		if raw.has("bundle"): continue
		if not relabel_source.is_empty(): raw["source"]=relabel_source
		elif target=="user" and String(raw.get("source","live"))=="live": raw["source"]="imported"
		var rec:Dictionary=sanitize(raw)
		if rec.is_empty(): skipped+=1; continue
		var id:String=String(rec.id)
		if seen.has(id) or (target=="user" and _ids.has(id)): skipped+=1; continue
		seen[id]=true
		if target=="user":
			if _append_line(JSON.stringify(rec)): _add(rec); added+=1
			else: skipped+=1
		else:
			out.store_line(JSON.stringify(rec)); added+=1
	if out!=null: out.flush()
	return {"ok":true,"added":added,"skipped":skipped,"target":target}

static func _ensure_parent(path:String)->void:
	var dir:String=path.get_base_dir()
	if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
		var err:Error=DirAccess.make_dir_recursive_absolute(dir)
		if err!=OK: last_error="Could not create %s (%s)." % [dir,error_string(err)]

static func stats()->Dictionary:
	ensure_loaded()
	var by_source:Dictionary={}
	var by_surface:Dictionary={}
	var by_type:Dictionary={}
	var prompt:int=0
	var completion:int=0
	for r:Variant in _records:
		var rec:Dictionary=r as Dictionary
		var s:String=String(rec.get("source",""))
		by_source[s]=int(by_source.get(s,0))+1
		var sf:String=String(rec.get("surface",""))
		by_surface[sf]=int(by_surface.get(sf,0))+1
		var intent:Dictionary=rec.get("intent",{})
		var t:String=String(intent.get("type_id",""))
		by_type[t]=int(by_type.get(t,0))+1
		var usage:Dictionary=rec.get("usage",{})
		prompt+=int(usage.get("prompt_tokens",0)); completion+=int(usage.get("completion_tokens",0))
	return {"records":_records.size(),"by_source":by_source,"by_surface":by_surface,"by_type":by_type,"user_files":user_files().size(),
		"user_bytes":user_bytes(),"prompt_tokens":prompt,"completion_tokens":completion}
