class_name InteractionContext
extends RefCounted
## Builds the coarse, identity-free context used to store and match
## interactions: era tier, population band and metric bands. Nothing here
## names a person, a place or a secret, so a signature is safe to keep on disk
## and to share in an exported bundle.

const POP_BANDS:Array[String]=["band","hamlet","village","town","city"]
const POP_BAND_LIMITS:Array[int]=[60,250,1000,5000]
const METRIC_BANDS:Array[String]=["low","mid","high"]
const FOOD_BANDS:Array[String]=["scarce","lean","ample"]
const DEFAULT_METRICS:Array[String]=["health","cohesion","knowledge","security","ecology","legitimacy"]
const TIER_TAGS:Array=[[],["farming","pottery"],["farming","pottery","weaving","metal","wheel","writing"],
	["farming","pottery","weaving","metal","wheel","writing","coin","masonry","institutions","boats","ships"]]

static func pop_band(population:int)->String:
	for i:int in POP_BAND_LIMITS.size():
		if population<POP_BAND_LIMITS[i]: return POP_BANDS[i]
	return POP_BANDS[POP_BANDS.size()-1]

static func pop_band_index(band:String)->int:
	return maxi(0,POP_BANDS.find(band))

static func metric_band(value:float)->String:
	if value<0.35: return "low"
	if value<0.65: return "mid"
	return "high"

static func food_band(food_days:float)->String:
	if food_days<10.0: return "scarce"
	if food_days<45.0: return "lean"
	return "ample"

## Writable decree metrics as RD defines them; guarded so a renamed or missing
## constant never breaks this file.
static var _metrics_cache:Array[String]=[]

static func writable_metrics()->Array[String]:
	if not _metrics_cache.is_empty(): return _metrics_cache
	var out:Array[String]=[]
	if ResourceLoader.exists("res://scripts/decree_statistics.gd"):
		var script:Script=load("res://scripts/decree_statistics.gd") as Script
		if script!=null:
			var constants:Dictionary=script.get_script_constant_map()
			# Custom-directive parameters too, so recorded and typed effects on
			# fertility, disease, violence, migration... are kept.
			var listed:Variant=constants.get("OFFLINE_METRICS",constants.get("METRICS",[]))
			if listed is Array:
				for m:Variant in listed: out.append(String(m))
	if out.is_empty(): out.assign(DEFAULT_METRICS)
	_metrics_cache=out
	return out

static func tags_for_tier(tier:int)->Array:
	return (TIER_TAGS[clampi(tier,0,TIER_TAGS.size()-1)] as Array).duplicate()

## Normalises a caller-supplied context: fills defaults, derives bands.
static func complete(ctx:Dictionary)->Dictionary:
	var out:Dictionary=ctx.duplicate(true)
	var population:int=maxi(1,int(out.get("population",150)))
	out["population"]=population
	if not out.has("working_age"): out["working_age"]=int(round(float(population)*0.55))
	var tier:int=clampi(int(out.get("era_tier",1)),0,3)
	out["era_tier"]=tier
	if not (out.get("era_tags") is Array): out["era_tags"]=tags_for_tier(tier)
	if not (out.get("metrics") is Dictionary): out["metrics"]={}
	out["feasibility"]=clampf(float(out.get("feasibility",1.0)),0.0,1.0)
	out["compliance"]=clampf(float(out.get("compliance",0.7)),0.0,1.0)
	return out

## The identity-free signature stored with each record.
static func signature(ctx:Dictionary)->Dictionary:
	var c:Dictionary=complete(ctx)
	var metrics:Dictionary=c.get("metrics",{})
	var bands:Dictionary={}
	for m:String in writable_metrics():
		if metrics.has(m): bands[m]=metric_band(float(metrics[m]))
	var sig:Dictionary={"era_tier":int(c.era_tier),"pop_band":pop_band(int(c.population)),"metric_bands":bands}
	if c.has("food_days"): sig["food_band"]=food_band(float(c.food_days))
	return sig

## 1.0 for identical signatures, falling toward 0 as bands diverge.
static func proximity(a:Dictionary,b:Dictionary)->float:
	if a.is_empty() or b.is_empty(): return 0.5
	var score:float=0.0
	var weight:float=0.0
	score+=1.0-absf(float(int(a.get("era_tier",1))-int(b.get("era_tier",1))))/3.0; weight+=1.0
	score+=1.0-absf(float(pop_band_index(String(a.get("pop_band","hamlet")))-pop_band_index(String(b.get("pop_band","hamlet")))))/4.0; weight+=1.0
	var ma:Dictionary=a.get("metric_bands",{})
	var mb:Dictionary=b.get("metric_bands",{})
	for key:Variant in ma:
		if mb.has(key):
			score+=0.5*(1.0-absf(float(METRIC_BANDS.find(String(ma[key]))-METRIC_BANDS.find(String(mb[key]))))/2.0); weight+=0.5
	return clampf(score/maxf(weight,0.001),0.0,1.0)

static func _node(name:String)->Object:
	var loop:MainLoop=Engine.get_main_loop()
	if not (loop is SceneTree): return null
	return (loop as SceneTree).root.get_node_or_null(name)

static func _prop(obj:Object,name:String,fallback:Variant)->Variant:
	if obj==null: return fallback
	var v:Variant=obj.get(name)
	return fallback if v==null else v

## Context drawn from the running game. Every read is guarded so this works
## in headless tests, early boot and after other systems are refactored.
static func from_live_state(extra:Dictionary={})->Dictionary:
	var ctx:Dictionary={}
	var world:Object=_node("WorldSimulation")
	var state:Object=null
	if world!=null:
		var s:Variant=world.get("state")
		if s is Object: state=s as Object
	var gs:Object=_node("GameState")
	var src:Object=state if state!=null else gs
	ctx["population"]=int(_prop(src,"population_total",150))
	var cohorts:Variant=_prop(src,"population_cohorts",{})
	if cohorts is Dictionary and (cohorts as Dictionary).has("working_age"): ctx["working_age"]=int((cohorts as Dictionary).working_age)
	var sim:Variant=_prop(src,"simulation_metrics",{})
	var metrics:Dictionary={}
	if sim is Dictionary:
		for m:String in writable_metrics():
			if (sim as Dictionary).has(m): metrics[m]=float((sim as Dictionary)[m])
		if (sim as Dictionary).has("food_days"): ctx["food_days"]=float((sim as Dictionary).food_days)
	ctx["metrics"]=metrics
	var tags:Array=[]
	var tier:int=1
	if ResourceLoader.exists("res://scripts/character_voice.gd"):
		var cv:Script=load("res://scripts/character_voice.gd") as Script
		if cv!=null and gs!=null:
			var t:Variant=cv.call("era_tags","player")
			if t is Array: tags=t as Array
			tier=int(cv.call("era_tier",tags))
	ctx["era_tags"]=tags
	ctx["era_tier"]=tier
	for key:Variant in extra: ctx[key]=extra[key]
	return complete(ctx)
