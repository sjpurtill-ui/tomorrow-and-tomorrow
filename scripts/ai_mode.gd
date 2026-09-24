class_name AiMode
extends RefCounted
## Player setting for how conversation surfaces use the language-model API.
##   live    - call the API as today and record every exchange (default).
##   hybrid  - answer from the offline interaction database when a stored
##             match is confident enough; otherwise call the API (saves money).
##   offline - never call the API; the offline engine always answers.
## Stored on this device only (user://ai_mode.cfg). LEVIATHAN_AI_MODE overrides
## it for a launch. This file only answers questions; call sites decide.

const LIVE:="live"
const HYBRID:="hybrid"
const OFFLINE:="offline"
const MODES:Array[String]=[LIVE,HYBRID,OFFLINE]
const SETTINGS_PATH:="user://ai_mode.cfg"
const DEFAULT_HYBRID_THRESHOLD:=0.72
const LABELS:Dictionary={
	LIVE:"Live - always ask the model; record every exchange",
	HYBRID:"Hybrid - reuse confident offline matches, ask the model otherwise",
	OFFLINE:"Offline - never contact the API",
}

static var _loaded:bool=false
static var _mode:String=LIVE
static var _threshold:float=DEFAULT_HYBRID_THRESHOLD
static var _record:bool=true
static var settings_path:String=SETTINGS_PATH

static func _ensure()->void:
	if _loaded: return
	_loaded=true
	var cfg:ConfigFile=ConfigFile.new()
	if cfg.load(settings_path)==OK:
		var saved:String=String(cfg.get_value("ai","mode",LIVE))
		if saved in MODES: _mode=saved
		_threshold=clampf(float(cfg.get_value("ai","hybrid_threshold",DEFAULT_HYBRID_THRESHOLD)),0.3,0.99)
		_record=bool(cfg.get_value("ai","record_interactions",true))

## Current mode; the LEVIATHAN_AI_MODE environment variable wins for this launch.
static func mode()->String:
	_ensure()
	var env:String=OS.get_environment("LEVIATHAN_AI_MODE").strip_edges().to_lower()
	if env in MODES: return env
	return _mode

static func set_mode(value:String,persist:bool=true)->bool:
	_ensure()
	var m:String=value.strip_edges().to_lower()
	if not (m in MODES): return false
	_mode=m
	if persist: _save()
	return true

static func hybrid_threshold()->float:
	_ensure()
	return _threshold

static func set_hybrid_threshold(value:float,persist:bool=true)->void:
	_ensure()
	_threshold=clampf(value,0.3,0.99)
	if persist: _save()

## Whether a call site may contact the API at all.
static func allows_api()->bool:
	return mode()!=OFFLINE

## Whether a call site should consult InteractionMatcher before the API.
static func consult_offline_first()->bool:
	return mode()!=LIVE

## Given InteractionMatcher.resolve()'s result, should the offline answer be
## used instead of calling the API? Offline: always. Hybrid: only a stored
## match at or above the threshold. Live: never.
static func should_use_offline(resolution:Dictionary)->bool:
	var m:String=mode()
	if m==OFFLINE: return true
	if m==LIVE: return false
	return String(resolution.get("source",""))=="match" and float(resolution.get("confidence",0.0))>=hybrid_threshold()

## Whether live API exchanges are written to the local interaction database.
static func records_interactions()->bool:
	_ensure()
	return _record

static func set_records_interactions(value:bool,persist:bool=true)->void:
	_ensure()
	_record=value
	if persist: _save()

static func label(value:String="")->String:
	return String(LABELS.get(value if not value.is_empty() else mode(),""))

static func status()->Dictionary:
	return {"mode":mode(),"label":label(),"hybrid_threshold":hybrid_threshold(),"records_interactions":records_interactions(),
		"env_override":OS.get_environment("LEVIATHAN_AI_MODE").strip_edges().to_lower() in MODES,"allows_api":allows_api()}

## Tests: forget cached settings and read from another file.
static func reset_for_tests(path:String)->void:
	settings_path=path
	_loaded=false
	_mode=LIVE
	_threshold=DEFAULT_HYBRID_THRESHOLD
	_record=true

static func _save()->void:
	var cfg:ConfigFile=ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("ai","mode",_mode)
	cfg.set_value("ai","hybrid_threshold",_threshold)
	cfg.set_value("ai","record_interactions",_record)
	cfg.save(settings_path)
