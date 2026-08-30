extends Node

const ResourceKnowledgeCatalog = preload("res://scripts/resource_knowledge_catalog.gd")
const SocietyKnowledgeCatalog = preload("res://scripts/society_knowledge_catalog.gd")
const DiscoveryFrontierCatalog = preload("res://scripts/discovery_frontier_catalog.gd")
const SocietyModelScript = preload("res://scripts/society_model.gd")
var society_model = SocietyModelScript.new()

var rng := RandomNumberGenerator.new()
var initialized := false
var catalog_by_id:Dictionary={}
const BASE_DISCOVERY_COUNT:=24

func reset_for_new_world()->void:
	initialized=false
	catalog.resize(BASE_DISCOVERY_COUNT)
	catalog_by_id.clear()
	society_model=SocietyModelScript.new()
	rng=RandomNumberGenerator.new()

# This catalog is intentionally never exposed to player UI. It is the causal
# machinery that turns activity, environment, attention, and chance into history.
var catalog: Array[Dictionary] = [
	{"id":"seasonal_patterns","name":"Seasonal Patterns","direction":"Nature","chance":0.010,"day":0,"requires":[],"signals":["foraging","exploration"],"observation":"Gatherers report that plants and animals return in recurring cycles."},
	{"id":"seed_selection","name":"Selective Planting","direction":"Sustenance","chance":0.006,"day":20,"requires":["seasonal_patterns"],"signals":["foraging","food"],"observation":"Some gathered seeds consistently produce stronger plants."},
	{"id":"food_drying","name":"Food Drying","direction":"Sustenance","chance":0.009,"day":0,"requires":[],"signals":["food","storage"],"observation":"Food left in dry moving air spoils more slowly."},
	{"id":"smoking","name":"Smoke Preservation","direction":"Sustenance","chance":0.005,"day":18,"requires":["food_drying"],"signals":["food","fire"],"observation":"Food kept above smoky fires changes texture and lasts longer."},
	{"id":"cordage","name":"Twisted Cordage","direction":"Materials","chance":0.010,"day":3,"requires":[],"signals":["fiber","construction"],"observation":"Twisted plant fibers hold much more weight than loose strands."},
	{"id":"basketry","name":"Basketry","direction":"Materials","chance":0.006,"day":12,"requires":["cordage"],"signals":["fiber","storage"],"observation":"Interlaced fibers form containers that remain light and strong."},
	{"id":"charcoal","name":"Charcoal Production","direction":"Materials","chance":0.004,"day":35,"requires":[],"signals":["fire","timber"],"observation":"Wood heated beneath restricted air leaves an unusually hot-burning residue."},
	{"id":"clay_shaping","name":"Clay Vessels","direction":"Materials","chance":0.006,"day":15,"requires":[],"signals":["clay","storage"],"observation":"Local wet earth can be shaped into containers before it dries."},
	{"id":"pit_firing","name":"Pit Firing","direction":"Materials","chance":0.003,"day":50,"requires":["clay_shaping","charcoal"],"signals":["fire","clay"],"observation":"Clay exposed to sustained heat becomes permanently hard."},
	{"id":"joinery","name":"Wood Joinery","direction":"Infrastructure","chance":0.005,"day":22,"requires":["cordage"],"signals":["timber","construction"],"observation":"Carefully cut wooden members can lock together without cord."},
	{"id":"drainage","name":"Ground Drainage","direction":"Infrastructure","chance":0.007,"day":10,"requires":[],"signals":["construction","rain"],"observation":"Shallow channels keep occupied ground drier after storms."},
	{"id":"well_siting","name":"Well Siting","direction":"Infrastructure","chance":0.004,"day":40,"requires":["drainage"],"signals":["freshwater","construction"],"observation":"Certain terrain features reliably indicate water beneath the ground."},
	{"id":"wound_cleaning","name":"Wound Cleaning","direction":"Health","chance":0.007,"day":0,"requires":[],"signals":["injury","freshwater"],"observation":"Washed wounds become dangerous less often than untreated wounds."},
	{"id":"herbal_classification","name":"Medicinal Classification","direction":"Health","chance":0.004,"day":28,"requires":[],"signals":["foraging","illness"],"observation":"Healers begin separating plants by repeatable effects rather than appearance."},
	{"id":"clean_water","name":"Clean-Water Practice","direction":"Health","chance":0.004,"day":45,"requires":["wound_cleaning"],"signals":["freshwater","illness"],"observation":"Families using cleaner water suffer fewer stomach illnesses."},
	{"id":"tallies","name":"Material Tallies","direction":"Information","chance":0.007,"day":0,"requires":[],"signals":["storage","administration"],"observation":"Repeated marks can preserve quantities after memory becomes unreliable."},
	{"id":"standard_measures","name":"Shared Measures","direction":"Information","chance":0.003,"day":70,"requires":["tallies"],"signals":["trade","construction"],"observation":"Disputes fall when different workers use the same reference quantities."},
	{"id":"route_memory","name":"Encoded Routes","direction":"Information","chance":0.006,"day":12,"requires":[],"signals":["exploration","travel"],"observation":"Travelers develop repeatable stories that preserve direction and distance."},
	{"id":"labor_rotations","name":"Labor Rotations","direction":"Society","chance":0.007,"day":8,"requires":[],"signals":["administration","construction"],"observation":"Regular rotations distribute exhausting work without abandoning essential tasks."},
	{"id":"customary_law","name":"Customary Law","direction":"Society","chance":0.003,"day":55,"requires":["labor_rotations"],"signals":["dispute","administration"],"observation":"Repeated judgments are being remembered as rules that bind future decisions."},
	{"id":"public_stores","name":"Public Stores","direction":"Society","chance":0.003,"day":80,"requires":["tallies","labor_rotations"],"signals":["storage","administration"],"observation":"Shared reserves can support projects no household could sustain alone."},
	{"id":"watch_rotation","name":"Organized Watch","direction":"Warfare","chance":0.007,"day":6,"requires":[],"signals":["defense","danger"],"observation":"Scheduled sentries detect threats earlier and reduce exhaustion."},
	{"id":"formation_drill","name":"Formation Drill","direction":"Warfare","chance":0.003,"day":60,"requires":["watch_rotation","labor_rotations"],"signals":["defense","training"],"observation":"Groups moving under repeated commands retain cohesion under pressure."},
	{"id":"supply_groups","name":"Organized Supply Parties","direction":"Warfare","chance":0.003,"day":75,"requires":["tallies","route_memory"],"signals":["logistics","travel"],"observation":"Separating carriers from scouts allows groups to travel farther."}
]

func initialize() -> void:
	if initialized:
		return
	catalog_by_id.clear()
	rng.seed = GameState.world_seed ^ 0x6c8e9cf5
	catalog.append_array(ResourceKnowledgeCatalog.entries())
	catalog.append_array(SocietyKnowledgeCatalog.entries())
	catalog.append_array(DiscoveryFrontierCatalog.entries())
	for i in catalog.size():
		catalog[i]=_classify_discovery(catalog[i])
		catalog[i]=society_model.normalize_discovery(catalog[i])
		catalog_by_id[String(catalog[i].get("id",""))]=catalog[i]
	initialized = true
	_refresh_active_investigations()

func process_day(context: Dictionary) -> Array[Dictionary]:
	initialize()
	society_model.process_day(catalog,context)
	var results: Array[Dictionary] = []
	var current_day := int(floor(GameState.elapsed_days))
	_refresh_active_investigations()
	for channel_variant in GameState.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var discovery_id:=String(GameState.active_investigations.get(channel,""))
		var discovery:=discovery_definition(discovery_id)
		if discovery.is_empty(): continue
		var allocation:=_subcategory_allocation(String(discovery.dynamic),String(discovery.subcategory))
		var attention := 0.35 + allocation * 0.32
		var activity := 0.65
		for activity_signal in discovery.signals:
			activity += float(context.get(activity_signal, 0.0)) * 0.22
		var leader_factor := _leader_factor(String(discovery.dynamic))
		# Catalog chances describe relative discoverability. The global time scale keeps
		# knowledge unfolding across generations instead of exhausting an era in months.
		var material_evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
		var probability: float = discovery.chance * attention * activity * material_evidence * leader_factor*ConsequenceEngine.discovery_multiplier()*0.12
		var progress:=float(GameState.discovery_progress.get(discovery_id,0.0))
		progress+=probability*rng.randf_range(0.72,1.28)
		if rng.randf()<probability*0.10: progress+=rng.randf_range(0.025,0.085)
		GameState.discovery_progress[discovery_id]=clampf(progress,0.0,1.0)
		if progress>=1.0:
			GameState.known_discoveries.append(discovery.id)
			society_model.register_discovery(discovery,catalog)
			var event := {"day": current_day, "id":discovery.id, "name": discovery.name, "description": discovery.observation, "direction":discovery.dynamic,"dynamic":discovery.dynamic,"subcategory":discovery.subcategory,"effects":discovery.get("effects",{}).duplicate(true),"adoption":society_model.adoption(String(discovery.id))}
			GameState.discovery_log.push_front(event)
			GameState.active_investigations.erase(channel)
			GameState.discovery_progress.erase(discovery_id)
			results.append(event)
	_refresh_active_investigations()
	return results

func refresh_investigations()->void:
	initialize()
	_refresh_active_investigations()

func active_investigation_records()->Array[Dictionary]:
	initialize()
	_refresh_active_investigations()
	var records:Array[Dictionary]=[]
	for channel in GameState.active_investigations:
		var id:=String(GameState.active_investigations.get(channel,""))
		if id=="": continue
		var discovery:=discovery_definition(id).duplicate(true)
		if discovery.is_empty(): continue
		discovery["progress"]=float(GameState.discovery_progress.get(id,0.0))
		records.append(discovery)
	return records

func _refresh_active_investigations()->void:
	var current_day:=int(floor(GameState.elapsed_days))
	for channel_variant in GameState.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var id:=String(GameState.active_investigations.get(channel,""))
		var discovery:=discovery_definition(id)
		if discovery.is_empty() or _subcategory_allocation(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))<=0 or id in GameState.known_discoveries or not _discovery_is_eligible(discovery,current_day):
			GameState.active_investigations.erase(channel)
	for channel_data in _allocated_channels():
		var dynamic_id:=String(channel_data.dynamic)
		var subcategory:=String(channel_data.subcategory)
		var channel:=_channel_key(dynamic_id,subcategory)
		if String(GameState.active_investigations.get(channel,""))!="": continue
		var candidates:Array[Dictionary]=[]
		for discovery in catalog:
			if String(discovery.get("dynamic",""))!=dynamic_id or String(discovery.get("subcategory",""))!=subcategory: continue
			if _discovery_is_eligible(discovery,current_day): candidates.append(discovery)
		candidates.sort_custom(func(first:Dictionary,second:Dictionary)->bool:
			var first_order:int=int(first.get("day",0))+absi(hash("%s:%s" % [GameState.world_seed,first.get("id","")]))%240
			var second_order:int=int(second.get("day",0))+absi(hash("%s:%s" % [GameState.world_seed,second.get("id","")]))%240
			return first_order<second_order)
		if not candidates.is_empty():
			GameState.active_investigations[channel]=String(candidates[0].id)
	GameState.active_observations.clear()
	for record in active_investigation_records_shallow():
		GameState.active_observations.append(String(record.observation))

func active_investigation_records_shallow()->Array[Dictionary]:
	var records:Array[Dictionary]=[]
	for channel in GameState.active_investigations:
		var id:=String(GameState.active_investigations.get(channel,""))
		if id=="": continue
		var discovery:=discovery_definition(id)
		if not discovery.is_empty(): records.append(discovery)
	return records

func _discovery_is_eligible(discovery:Dictionary,current_day:int)->bool:
	var id:=String(discovery.get("id",""))
	if id in GameState.known_discoveries or current_day<int(discovery.get("day",0)): return false
	for requirement in discovery.get("requires",[]):
		if String(requirement) not in GameState.known_discoveries: return false
	return _resource_requirements_met(discovery.get("resource_requirements",[]))

func _resource_requirements_met(requirements: Array) -> bool:
	for requirement_variant in requirements:
		var requirement:Dictionary=requirement_variant
		var resource_name:=String(requirement.get("resource",""))
		var needed_stage:=String(requirement.get("stage","recognized"))
		var minimum_stock:=float(requirement.get("minimum_stock",0.0))
		var found:=false
		for deposit in GameState.resource_deposits:
			if String(deposit.get("resource",""))!=resource_name:
				continue
			if _stage_rank(String(deposit.get("stage","unknown")))>=_stage_rank(needed_stage):
				found=true
				break
		if not found and float(GameState.resource_stockpiles.get(resource_name,0.0))>=minimum_stock and minimum_stock>0.0:
			found=true
		if not found:
			return false
	return true

func _resource_evidence(requirements:Array)->float:
	if requirements.is_empty(): return 1.0
	var evidence:=0.0
	for requirement_variant in requirements:
		var requirement:Dictionary=requirement_variant
		var resource_name:=String(requirement.get("resource",""))
		var best:=0.0
		for deposit in GameState.resource_deposits:
			if String(deposit.get("resource",""))!=resource_name: continue
			var stage_score:=float(_stage_rank(String(deposit.get("stage","unknown"))))/4.0
			var worked:=clampf(float(deposit.get("lifetime_extracted",0.0))/200.0,0.0,0.35)
			best=maxf(best,0.65+stage_score*0.25+worked)
		if float(GameState.resource_stockpiles.get(resource_name,0.0))>0.0: best=maxf(best,0.82)
		evidence+=best
	return clampf(evidence/maxf(1.0,float(requirements.size())),0.55,1.25)

func _stage_rank(stage:String)->int:
	return {"unknown":0,"recognized":1,"surveyed":2,"accessible":3,"developed":4}.get(stage,0)

func effect(effect_id:String)->float:
	initialize()
	return society_model.effect(effect_id)

func adoption(discovery_id:String)->float:
	return society_model.adoption(discovery_id)

func validate_catalog()->Array[String]:
	initialize()
	return society_model.validate_catalog(catalog)

func reset_society_clock()->void:
	society_model.last_processed_day=-1

func discovery_definition(discovery_id:String)->Dictionary:
	initialize()
	return catalog_by_id.get(discovery_id,{})

func _leader_factor(direction: String) -> float:
	var mapping := {
		"demography":["Steward",["Medicine","Empathy"]],"nutrition":["Quartermaster",["Agriculture","Logistics"]],
		"health":["Steward",["Medicine","Administration"]],"labor":["Steward",["Delegation","Discipline"]],
		"knowledge":["Scholar",["Research","Education"]],"production":["Quartermaster",["Manufacturing","Engineering"]],
		"infrastructure":["Steward",["Construction","Engineering"]],"logistics":["Quartermaster",["Logistics","Trade"]],
		"ecology":["Scholar",["Natural Science","Research"]],"institutions":["Steward",["Administration","Law"]],
		"security":["Marshal",["Strategy","Tactics"]],"culture":["Envoy",["Oratory","Diplomacy"]]
	}
	var assignment: Array = mapping.get(direction,["Scholar",["Research"]])
	return AdvisorSystem.execution_modifier(assignment[0],assignment[1])

func _subcategory_allocation(dynamic_id:String,subcategory:String)->int:
	return int((GameState.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).get(subcategory,0))

func _channel_key(dynamic_id:String,subcategory:String)->String:
	return "%s::%s" % [dynamic_id,subcategory]

func _allocated_channels()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for dynamic_id in GameState.research_subcategory_allocations:
		var subcategories:Dictionary=GameState.research_subcategory_allocations[dynamic_id]
		for subcategory in subcategories:
			if int(subcategories[subcategory])>0: result.append({"dynamic":dynamic_id,"subcategory":subcategory})
	return result

func _classify_discovery(source:Dictionary)->Dictionary:
	var discovery:=source.duplicate(true)
	if discovery.has("dynamic") and discovery.has("subcategory"): return discovery
	var old_direction:=String(discovery.get("direction","Information"))
	var dynamic_id:String={"Sustenance":"nutrition","Materials":"production","Infrastructure":"infrastructure","Health":"health","Nature":"ecology","Information":"knowledge","Society":"institutions","Warfare":"security"}.get(old_direction,old_direction.to_lower())
	var text:=(String(discovery.get("name",""))+" "+String(discovery.get("observation",""))).to_lower()
	var subcategory:=String((DiscoveryFrontierCatalog.SUBCATEGORIES.get(dynamic_id,["Directed attention"]) as Array)[0])
	var keyword_map:Dictionary={
		"demography":{"birth":"Maternal safety","child":"Child survival","shelter":"Shelter capacity"},
		"nutrition":{"store":"Stored reserve","soil":"Land productivity","diet":"Diet quality","food":"Daily supply"},
		"health":{"water":"Water & sanitation","disease":"Disease control","wound":"Injury safety"},
		"labor":{"coord":"Coordination","workload":"Workload balance","efficien":"Work efficiency"},
		"knowledge":{"record":"Preserved knowledge","tall":"Preserved knowledge","memory":"Preserved knowledge","commun":"Communication","attention":"Directed attention"},
		"production":{"tool":"Tool quality","standard":"Standardization","craft":"Craft capacity"},
		"infrastructure":{"house":"Housing","public":"Public works","resilien":"Resilience"},
		"logistics":{"route":"Route quality","storage":"Storage system","trade":"Trade reach"},
		"ecology":{"recover":"Natural recovery","pollut":"Pollution control","resource":"Resource sustainability"},
		"institutions":{"legitim":"Legitimacy","law":"State capacity","reform":"Institutional flexibility"},
		"security":{"military":"Military readiness","defen":"Organized defense","crisis":"Crisis resilience"},
		"culture":{"memory":"Collective memory","inquiry":"Inquiry breadth","cohesion":"Social cohesion"}
	}
	for keyword in keyword_map.get(dynamic_id,{}):
		if String(keyword) in text: subcategory=String(keyword_map[dynamic_id][keyword]); break
	discovery["dynamic"]=dynamic_id
	discovery["subcategory"]=subcategory
	discovery["direction"]=dynamic_id
	return discovery
