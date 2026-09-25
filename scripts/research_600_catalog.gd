extends RefCounted
## Data-driven research layer for the approved 600-year design (twelve lines,
## 1,101 discoveries). DiscoverySystem consults it while building its catalog:
##
## * Registry ids already in the catalog keep their authored effects, recipes
##   and art, but their foundations (requires_all / requires_any), historical
##   era, ordering day and research pace come from the design.
## * NEW registry ids are registered in the catalog's own entry format, with a
##   small per-line default effect until Phase 2 fills res://data/research/effects.
## * Every live entry gets an earliest year. Registry items open at the low edge
##   of their design band; everything else is held to its dated era (see
##   TechnologyEras) or, when undated, to the end of the 600-year window.
## * Design conditions (population, settlements, known resources, environment,
##   institutions, contact) gate availability. Nothing here grants or revokes
##   knowledge: known discoveries always stay known.
##
## The player and rival civilizations use the same predicates; only the
## `society` snapshot passed in differs (see DiscoverySystem.research_600_*).
## Source data: tools/research/build_research_600.py -> research_600.json.

const DATA_PATH:="res://data/research/research_600.json"
const EFFECTS_DIR:="res://data/research/effects"
## Game year at which the design window ends. Undated entries outside the
## registry are conservatively held until then.
const WINDOW_END_YEAR:=600.0
## Dated entries outside the registry open at this fraction of their era year,
## the same relative margin the design bands allow (roughly -10%).
const ERA_BAND_FRACTION:=0.9
## Rivals see materials as landscape potential; the same floor their research
## already uses for resource requirements.
const RIVAL_RESOURCE_FLOOR:=0.16
## Contact level at which two peoples have actually met (CivilizationSystem).
const CONTACT_MET_LEVEL:=2
## Each known precedent makes research this much faster, up to the cap.
const PRECEDENT_BONUS:=0.10
const PRECEDENT_CAP:=1.30
## Research years convert to the catalog's daily chance at full attention:
## DiscoverySystem progress per day = chance * 0.12 * (attention factors).
const DAILY_SCALE:=0.12
## Phase 3 pacing: a design research year is what a line achieves with the
## partial staffing a real society gives it, not with a fully staffed team. A
## founding band has few observers per line; a Bronze Age city has scribes and
## a large population behind each line, so the pace factor falls with the
## item's design year. Calibrated with tools/sim so milestones land inside their
## design bands (docs/research/BENCHMARKS_600.md).
const PACE_BY_YEAR:Array=[[0.0,7.0],[100.0,5.5],[200.0,2.4],[300.0,1.0],[450.0,0.7],[600.0,0.65]]
## Keys the design governs; Phase 2 effect files cannot override them.
const PROTECTED_KEYS:=["id","dynamic","direction","requires","requires_all","requires_any","learning_routes","day","chance","research_600","earliest_year","design_year","precedents","conditions"]
## Safe minimal consequence per line for NEW entries until Phase 2 authors them.
const DEFAULT_EFFECTS:={
	"knowledge":{"knowledge_preservation":0.004},"institutions":{"state_capacity":0.003},
	"culture":{"cohesion":0.003},"labor":{"labor_efficiency":0.003},
	"production":{"craft_output":0.004},"infrastructure":{"construction_rate":0.004},
	"nutrition":{"food_output":0.003},"health":{"health_protection":0.003},
	"demography":{"maternal_safety":0.003},"logistics":{"haul_capacity":0.004},
	"ecology":{"ecology_recovery":0.003},"security":{"security_efficiency":0.004}
}

static var _items:Dictionary={}
static var _ids:Array[String]=[]
static var _effects:Dictionary={}
static var _meta:Dictionary={}
## Phase 3 amendments: earliest years of live entries left outside the registry.
static var _redates:Dictionary={}
static var _loaded:=false


static func ensure_loaded()->void:
	if _loaded: return
	_loaded=true
	_items.clear();_ids.clear();_effects.clear();_meta.clear();_redates.clear()
	var text:=FileAccess.get_file_as_string(DATA_PATH)
	var parsed:Variant=JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Research600: cannot read "+DATA_PATH)
		return
	_meta=(parsed as Dictionary).get("meta",{})
	var redates:Variant=(parsed as Dictionary).get("redates",{})
	if redates is Dictionary: _redates=(redates as Dictionary).duplicate()
	for row:Variant in (parsed as Dictionary).get("items",[]):
		if not row is Dictionary: continue
		var item:Dictionary=row
		var id:=String(item.get("id",""))
		if id.is_empty() or _items.has(id): continue
		_items[id]=item
		_ids.append(id)
	for line:Variant in (parsed as Dictionary).get("lines",[]):
		var path:="%s/%s.json" % [EFFECTS_DIR,String(line)]
		if not FileAccess.file_exists(path): continue
		var effects_file:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not effects_file is Dictionary: continue
		var rows:Variant=(effects_file as Dictionary).get("items",{})
		if not rows is Dictionary: continue
		for effect_id:Variant in rows:
			if rows[effect_id] is Dictionary and _items.has(String(effect_id)): _effects[String(effect_id)]=rows[effect_id]


## Drops the cached data (tests, or after regenerating the JSON).
static func reload()->void:
	_loaded=false
	ensure_loaded()


static func meta()->Dictionary:
	ensure_loaded()
	return _meta


static func ids()->Array[String]:
	ensure_loaded()
	return _ids


static func has(id:String)->bool:
	ensure_loaded()
	return _items.has(id)


static func item(id:String)->Dictionary:
	ensure_loaded()
	return _items.get(id,{})


static func effect_row(id:String)->Dictionary:
	ensure_loaded()
	return _effects.get(id,{})


static func chance_for(research_years:float,design_year:float=0.0)->float:
	return pace_for(design_year)/(DAILY_SCALE*365.0*maxf(0.25,research_years))


## Research pace for an item of `design_year` (PACE_BY_YEAR, linear between points).
static func pace_for(design_year:float)->float:
	if design_year<=float(PACE_BY_YEAR[0][0]): return float(PACE_BY_YEAR[0][1])
	for index in range(1,PACE_BY_YEAR.size()):
		if design_year<=float(PACE_BY_YEAR[index][0]):
			var low:Array=PACE_BY_YEAR[index-1]
			var high:Array=PACE_BY_YEAR[index]
			return lerpf(float(low[1]),float(high[1]),(design_year-float(low[0]))/(float(high[0])-float(low[0])))
	return float(PACE_BY_YEAR[PACE_BY_YEAR.size()-1][1])


## Registry entries that the authored catalog does not already define, in the
## catalog's own entry format.
static func new_entries(existing:Dictionary)->Array[Dictionary]:
	ensure_loaded()
	var result:Array[Dictionary]=[]
	for id:String in _ids:
		if existing.has(id): continue
		var source:Dictionary=_items[id]
		var line:=String(source.get("line","knowledge"))
		var entry:Dictionary={
			"id":id,"name":String(source.get("name",id)),"direction":line,"dynamic":line,
			"subcategory":String(source.get("subcategory","")),
			"signals":(source.get("signals",["information"]) as Array).duplicate(),
			"observation":String(source.get("observation","")),
			"effects":(DEFAULT_EFFECTS.get(line,{}) as Dictionary).duplicate(true),
			"research_600_new":true
		}
		result.append(apply(entry))
	return result


## Design override for a registry id; other entries are returned unchanged.
static func apply(entry:Dictionary)->Dictionary:
	ensure_loaded()
	var id:=String(entry.get("id",""))
	if not _items.has(id): return entry
	var source:Dictionary=_items[id]
	var result:=entry
	var requires_all:Array=(source.get("requires_all",[]) as Array).duplicate()
	result["requires_all"]=requires_all
	result["requires"]=requires_all.duplicate()
	result["requires_any"]=(source.get("requires_any",[]) as Array).duplicate(true)
	# The design's AND/OR foundations replace the authored primary ("local")
	# route, which would otherwise add requirements the design does not make.
	# Other authored approaches (model-assisted, experimental, imported) stay as
	# optional alternatives: the design route below is always open once the
	# common foundations are known, so they can only speed or credit research.
	var authored_routes:Array=entry.get("learning_routes",[])
	var authored_local:Array=entry.get("requires",[])
	for route:Variant in authored_routes:
		if route is Dictionary and String((route as Dictionary).get("id",""))=="local":
			authored_local=(route as Dictionary).get("requires_all",(route as Dictionary).get("requires",[]))
	var alternatives:Array=[]
	for route:Variant in authored_routes:
		if not route is Dictionary or String((route as Dictionary).get("id",""))=="local": continue
		var alternative:Dictionary=(route as Dictionary).duplicate(true)
		# Model overlays ("mathematical:local", "mechanical:local") extend the
		# authored primary route; rebase them on the design route by keeping only
		# the model's own foundations.
		if String(alternative.get("id","")).ends_with(":local"):
			var own:Array=[]
			for parent:Variant in alternative.get("requires_all",alternative.get("requires",[])):
				if not parent in authored_local: own.append(parent)
			alternative["requires_all"]=own
			alternative.erase("requires")
		alternatives.append(alternative)
	if alternatives.is_empty(): result.erase("learning_routes")
	else:
		var routes:Array=[{"id":"local","label":"Local practice","requires_all":[]}]
		routes.append_array(alternatives)
		result["learning_routes"]=routes
	result["precedents"]=(source.get("precedents",[]) as Array).duplicate()
	result["conditions"]=(source.get("conditions",{}) as Dictionary).duplicate(true)
	result["design_year"]=float(source.get("proposed_year",0.0))
	result["earliest_year"]=float(source.get("min_year",0.0))
	result["day"]=int(round(float(source.get("proposed_year",0.0))*365.0))
	result["chance"]=chance_for(float(source.get("research_years",4.0)),float(source.get("proposed_year",0.0)))
	result["research_600"]=true
	var authored:Dictionary=_effects.get(id,{})
	for key:Variant in authored:
		if String(key) in PROTECTED_KEYS or String(key)=="art": continue
		var value:Variant=authored[key]
		if value is Dictionary: value=(value as Dictionary).duplicate(true)
		elif value is Array: value=(value as Array).duplicate(true)
		result[String(key)]=value
	return result


## Earliest game year an entry may open. `era` is DiscoverySystem.discovery_era;
## `dated` says whether TechnologyEras dates this id directly.
static func earliest_year(entry:Dictionary,era:float,dated:bool)->float:
	var id:=String(entry.get("id",""))
	if has(id): return float(item(id).get("min_year",0.0))
	if _redates.has(id): return float(_redates[id])
	# An entry dated after the window never opens inside it (the 0.9 margin
	# alone let year-660 iron open at 594).
	if dated: return era*ERA_BAND_FRACTION if era<=WINDOW_END_YEAR else maxf(WINDOW_END_YEAR,era*ERA_BAND_FRACTION)
	return maxf(WINDOW_END_YEAR,era*ERA_BAND_FRACTION)


## Phase 3 re-dated earliest year of a live entry outside the registry, or -1.
static func redate(id:String)->float:
	ensure_loaded()
	return float(_redates.get(id,-1.0))


static func has_conditions(id:String)->bool:
	return not (item(id).get("conditions",{}) as Dictionary).is_empty()


## Human-readable unmet conditions for `id` in `society` (see society keys in
## DiscoverySystem.research_600_player_society). Empty when all are met.
static func unmet_conditions(id:String,society:Dictionary)->Array[String]:
	var reasons:Array[String]=[]
	var conditions:Dictionary=item(id).get("conditions",{})
	if conditions.is_empty(): return reasons
	if conditions.has("min_population") and float(society.get("population",0.0))<float(conditions.min_population):
		reasons.append("A population of at least %d" % int(conditions.min_population))
	if conditions.has("min_settlements") and int(society.get("settlements",0))<int(conditions.min_settlements):
		reasons.append("At least %d settlements" % int(conditions.min_settlements))
	var resources:Dictionary=society.get("resources",{})
	for resource:Variant in conditions.get("resources_known",[]):
		if not resources.has(String(resource)): reasons.append("Knowledge of %s" % String(resource))
	var environments:Array=conditions.get("environment",[])
	if not environments.is_empty():
		var tags:Dictionary=society.get("environment",{})
		var found:=false
		for tag:Variant in environments:
			if tags.has(String(tag)): found=true;break
		if not found: reasons.append("A settlement by %s" % " or ".join(PackedStringArray(environments.map(func(tag:Variant)->String: return _environment_label(String(tag))))))
	if conditions.has("institutions_min") and float(society.get("institutions",0.0))<float(conditions.institutions_min):
		reasons.append("Institutional capacity of at least %d%%" % int(round(float(conditions.institutions_min)*100.0)))
	if bool(conditions.get("contact_required",false)) and not bool(society.get("contact",false)):
		reasons.append("Contact with another people")
	return reasons


static func conditions_met(id:String,society:Dictionary)->bool:
	return unmet_conditions(id,society).is_empty()


static func _environment_label(tag:String)->String:
	return {"river":"a river","coast":"the coast","woodland":"woodland","dry":"dry country"}.get(tag,tag)


## Environment tags (river, coast, woodland, dry) of a PlanetEnvironment profile.
static func environment_tags(profile:Dictionary,into:Dictionary={})->Dictionary:
	if profile.is_empty(): return into
	var biome:=String(profile.get("biome",""))
	var river_distance:=float(profile.get("river_distance_km",INF))
	if river_distance<12.0 or biome in ["floodplain","wetland"]: into["river"]=true
	# Unobserved (planetary) profiles carry no river distance. A wet, low-relief
	# landscape reliably carries running water, so it counts as river country.
	elif is_inf(river_distance) and float(profile.get("precipitation",0.0))>=0.55 and float(profile.get("relief",1.0))<0.4 and biome!="steppe": into["river"]=true
	if bool(profile.get("coastal",false)): into["coast"]=true
	if float(profile.get("woodland",0.0))>=0.42 or biome=="woodland": into["woodland"]=true
	var hazards:Dictionary=profile.get("hazards",{})
	if biome=="steppe" or float(profile.get("precipitation",1.0))<0.36 or float(hazards.get("drought",0.0))>=0.6: into["dry"]=true
	return into


## Known precedents make an item quicker to research; they are never required.
static func precedent_factor(id:String,known:Variant)->float:
	if not has(id): return 1.0
	var factor:=1.0
	for precedent:Variant in item(id).get("precedents",[]):
		if String(precedent) in known: factor+=PRECEDENT_BONUS
	return minf(PRECEDENT_CAP,factor)


## Illustration for a registry entry without its own subject art: a Phase 2
## `art` path, otherwise the research line's painting.
static func art_key(entry:Dictionary)->String:
	var id:=String(entry.get("id",""))
	if not has(id): return ""
	var authored:=String(effect_row(id).get("art",""))
	if not authored.is_empty(): return authored
	return "res://assets/ui/research/%s-v1.png" % String(item(id).get("line","knowledge"))
