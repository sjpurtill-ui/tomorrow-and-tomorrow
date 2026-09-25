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

## Design blocks (one approved design window each), merged in manifest order:
## {"blocks":[{"id","data","effects_dir","art","window_start","window_end"}]}.
## A later block may use earlier-block ids as foundations and precedents.
## Built by tools/research/build_research_block.py.
const MANIFEST_PATH:="res://data/research/blocks.json"
const DATA_PATH:="res://data/research/research_600.json"
const EFFECTS_DIR:="res://data/research/effects"
const ART_PATH:="res://data/research/art_600.json"
## Game year at which the FIRST design window ends. Gating uses
## window_end_year(), the end of the latest block loaded: undated entries
## outside every registry are conservatively held until then.
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
## research_3000: the curve continues through every design block to 3000.
const PACE_BY_YEAR:Array=[[0.0,7.0],[100.0,5.5],[200.0,2.4],[300.0,1.0],[450.0,0.7],[600.0,0.65],[700.0,0.30],[1200.0,0.20],[1800.0,0.17],[2400.0,0.15],[3000.0,0.10]]
## research_3000 parallel research capacity. A band of a few hundred works one
## question per staffed channel; a large, literate, well-governed society runs
## many investigations at once (academies, universities, laboratories), so a
## staffed channel's progress multiplies with the society's size beyond
## PARALLEL_POPULATION_REF, scaled by its institutions and literacy. It is 1 for
## every society below the reference (the whole 0-600 window as calibrated).
const PARALLEL_POPULATION_REF:=4000.0
## Extra parallel teams per tenfold population beyond the reference.
const PARALLEL_PER_DECADE:=0.25
const PARALLEL_LITERACY:=1.0
## research_3000 superseded practice: a registry item whose relevance the
## society's era has left more than STALE_GRACE years behind is slower to take
## up (nobody works the old way any more; the society adopts what replaced it),
## doubling its difficulty every STALE_DOUBLING years. An item stays relevant
## while any later registry item still builds on it (relevance_year: the latest
## design year among the item and everything that transitively requires it), so
## foundations of current questions never go stale; only dead-end practices do.
## A typical society therefore never learns about a third of the registry
## (benchmarks' discoveries_known), and no strategy catches up the whole backlog.
const STALE_GRACE:=60.0
const STALE_DOUBLING:=30.0
## Past this difficulty multiplier a superseded practice is abandoned: no
## channel takes it up (an investigation already running on it pauses and keeps
## its progress). Foundations of current questions are never abandoned.
const STALE_ABANDON:=4.0
## Candidate-score penalty for a dead-end registry item (nothing later builds on
## it): lines take up questions that open further work first, and a dead end
## only with spare attention, so a society with little to spare never learns
## many of them (they are abandoned once superseded).
const DEAD_END_PENALTY:=200.0
## Share of the registry's dead ends (outside key thresholds) a given world's
## people ever meet: which dead-end practices a society encounters depends on its
## land and history, so each world offers a seeded subset (DiscoverySystem
## _path_is_viable). Key thresholds and every foundation stay open everywhere.
const DEAD_END_VIABLE:=0.5
static var _relevance:Dictionary={}
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
## Loaded blocks in order (manifest rows plus their "meta"); id -> block id.
static var _blocks:Array[Dictionary]=[]
static var _block_of:Dictionary={}
static var _block_ids:Dictionary={}
## Tests point the loader at a fixture manifest (see use_manifest).
static var _manifest_path:=MANIFEST_PATH


static func ensure_loaded()->void:
	if _loaded: return
	_loaded=true
	_items.clear();_ids.clear();_effects.clear();_meta.clear();_redates.clear();_relevance.clear()
	_blocks.clear();_block_of.clear();_block_ids.clear()
	for block:Dictionary in _manifest_blocks():
		_load_block(block)
	if not _blocks.is_empty(): _meta=_blocks[0].get("meta",{})


## Manifest rows; without a manifest, the single original 0-600 block.
static func _manifest_blocks()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if FileAccess.file_exists(_manifest_path):
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(_manifest_path))
		if parsed is Dictionary:
			for row:Variant in (parsed as Dictionary).get("blocks",[]):
				if row is Dictionary and not String((row as Dictionary).get("data","")).is_empty(): result.append((row as Dictionary).duplicate(true))
		if not result.is_empty(): return result
		push_error("Research600: cannot read "+_manifest_path)
	result.append({"id":"y0_600","data":DATA_PATH,"effects_dir":EFFECTS_DIR,"art":ART_PATH,"window_start":0.0,"window_end":WINDOW_END_YEAR})
	return result


static func _load_block(block:Dictionary)->void:
	var data_path:=String(block.get("data",""))
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(data_path))
	if not parsed is Dictionary:
		push_error("Research600: cannot read "+data_path)
		return
	var block_id:=String(block.get("id",data_path))
	block["meta"]=(parsed as Dictionary).get("meta",{})
	_blocks.append(block)
	var own:Array[String]=[]
	# A later block's redates win; a designed item always wins over a redate.
	var redates:Variant=(parsed as Dictionary).get("redates",{})
	if redates is Dictionary:
		for redate_id:Variant in redates: _redates[String(redate_id)]=redates[redate_id]
	for row:Variant in (parsed as Dictionary).get("items",[]):
		if not row is Dictionary: continue
		var item:Dictionary=row
		var id:=String(item.get("id",""))
		# First block wins; the build tool rejects cross-block duplicates.
		if id.is_empty() or _items.has(id): continue
		_items[id]=item
		_ids.append(id)
		_block_of[id]=block_id
		own.append(id)
	_block_ids[block_id]=own
	var effects_dir:=String(block.get("effects_dir",EFFECTS_DIR))
	for line:Variant in (parsed as Dictionary).get("lines",[]):
		var path:="%s/%s.json" % [effects_dir,String(line)]
		if not FileAccess.file_exists(path): continue
		var effects_file:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not effects_file is Dictionary: continue
		var rows:Variant=(effects_file as Dictionary).get("items",{})
		if not rows is Dictionary: continue
		# A block's effect files only author that block's own ids.
		for effect_id:Variant in rows:
			if rows[effect_id] is Dictionary and String(_block_of.get(String(effect_id),""))==block_id: _effects[String(effect_id)]=rows[effect_id]


## Drops the cached data (tests, or after regenerating the JSON).
static func reload()->void:
	_loaded=false
	ensure_loaded()


## Loads another block manifest ("" restores the game's own). Tests only.
static func use_manifest(path:String)->void:
	_manifest_path=path if not path.is_empty() else MANIFEST_PATH
	reload()


## Meta of the first (0-600) block; block_meta() gives the others.
static func meta()->Dictionary:
	ensure_loaded()
	return _meta


## Loaded block ids, in manifest order.
static func blocks()->Array[String]:
	ensure_loaded()
	var result:Array[String]=[]
	for block:Dictionary in _blocks: result.append(String(block.get("id","")))
	return result


static func block_meta(block_id:String)->Dictionary:
	ensure_loaded()
	for block:Dictionary in _blocks:
		if String(block.get("id",""))==block_id: return block.get("meta",{})
	return {}


## Ids designed by one block, in its order.
static func block_ids(block_id:String)->Array[String]:
	ensure_loaded()
	var result:Array[String]=[]
	result.assign(_block_ids.get(block_id,[]))
	return result


## Block that designs `id`, or "".
static func block_of(id:String)->String:
	ensure_loaded()
	return String(_block_of.get(id,""))


## Art manifests (res:// paths) of the loaded blocks, in order.
static func art_manifests()->Array[String]:
	ensure_loaded()
	var result:Array[String]=[]
	for block:Dictionary in _blocks:
		var path:=String(block.get("art",""))
		if not path.is_empty(): result.append(path)
	return result


## End year of the latest design window loaded (600 with only the first block).
static func window_end_year()->float:
	ensure_loaded()
	var end:=0.0
	for block:Dictionary in _blocks: end=maxf(end,float(block.get("window_end",WINDOW_END_YEAR)))
	return end if end>0.0 else WINDOW_END_YEAR


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


## research_3000: parallel research capacity (>= 1) for a society of
## `population` with institutions capacity and literacy (both 0..1).
static func parallel_capacity(population:float,institutions:float,literacy:float)->float:
	var decades:=maxf(0.0,log(maxf(1.0,population)/PARALLEL_POPULATION_REF)/log(10.0))
	return 1.0+PARALLEL_PER_DECADE*decades*lerpf(0.6,1.2,clampf(institutions,0.0,1.0))*(1.0+PARALLEL_LITERACY*clampf(literacy,0.0,1.0))


## research_3000: difficulty multiplier for registry item `id` in a society of
## era `society_era` (1 until its relevance is STALE_GRACE years behind; 1 for
## entries outside the registry).
static func stale_factor(id:String,society_era:float)->float:
	var relevance:=relevance_year(id)
	if relevance<0.0: return 1.0
	return pow(2.0,minf(20.0,maxf(0.0,society_era-relevance-STALE_GRACE)/STALE_DOUBLING))


## research_3000: how long (in STALE_DOUBLING units) registry item `id` has been
## left behind by the society's era; lines prefer questions of their age, so a
## channel takes up the current frontier before older leftovers (0 outside the
## registry and for foundations of current questions).
static func staleness(id:String,society_era:float)->float:
	var relevance:=relevance_year(id)
	if relevance<0.0: return 0.0
	return maxf(0.0,society_era-relevance)/STALE_DOUBLING


## research_3000: true for a registry item no later registry item builds on.
static func dead_end(id:String)->bool:
	var relevance:=relevance_year(id)
	return relevance>=0.0 and relevance<=float(item(id).get("proposed_year",0.0))+0.5


## research_3000: true when registry item `id` is only worth spare attention (a
## dead end, or left behind past STALE_GRACE): a staffed line then works on the
## foundations of its current questions first (DiscoverySystem foundation work).
static func deferred(id:String,society_era:float)->bool:
	var relevance:=relevance_year(id)
	if relevance<0.0: return false
	return dead_end(id) or society_era-relevance>STALE_GRACE


## research_3000: whether registry item `id` is among the dead ends this world
## offers (`draw` is the world's 0..1 draw for the item).
static func dead_end_offered(id:String,draw:float)->bool:
	if not dead_end(id) or bool(item(id).get("key_threshold",false)): return true
	return draw<DEAD_END_VIABLE


## research_3000: false once registry item `id` is abandoned as superseded.
static func pursued(id:String,society_era:float)->bool:
	return stale_factor(id,society_era)<=STALE_ABANDON


## Latest design year among registry item `id` and every registry item that
## requires it, directly or through others (requires_all and requires_any); -1
## outside the registry.
static func relevance_year(id:String)->float:
	ensure_loaded()
	if _relevance.is_empty() and not _items.is_empty(): _build_relevance()
	return float(_relevance.get(id,-1.0))


static func _build_relevance()->void:
	var children:Dictionary={}
	for id:String in _ids:
		var item:Dictionary=_items[id]
		_relevance[id]=float(item.get("proposed_year",0.0))
		var parents:Array=(item.get("requires_all",[]) as Array).duplicate()
		for group:Variant in item.get("requires_any",[]):
			if group is Array: parents.append_array(group)
		for parent:Variant in parents:
			if not children.has(String(parent)): children[String(parent)]=[]
			(children[String(parent)] as Array).append(id)
	# Latest design year first: every dependent is final before its parents.
	var order:Array[String]=_ids.duplicate()
	order.sort_custom(func(a:String,b:String)->bool: return float(_items[a].get("proposed_year",0.0))>float(_items[b].get("proposed_year",0.0)))
	for _pass in 3:
		var changed:=false
		for id:String in order:
			var best:=float(_relevance[id])
			for child:Variant in children.get(id,[]):best=maxf(best,float(_relevance.get(String(child),-1.0)))
			if best>float(_relevance[id]):
				_relevance[id]=best
				changed=true
		if not changed: break


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
	# An entry dated after a design window never opens inside it (the 0.9
	# margin alone let year-660 iron open at 594): every loaded window that
	# ends before the entry's era is a floor.
	if dated:
		var floor_year:=0.0
		for block:Dictionary in _blocks:
			var end:=float(block.get("window_end",WINDOW_END_YEAR))
			if end<era: floor_year=maxf(floor_year,end)
		return maxf(floor_year,era*ERA_BAND_FRACTION)
	return maxf(window_end_year(),era*ERA_BAND_FRACTION)


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
