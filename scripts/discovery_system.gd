extends Node

const ResourceKnowledgeCatalog = preload("res://scripts/resource_knowledge_catalog.gd")
const SocietyKnowledgeCatalog = preload("res://scripts/society_knowledge_catalog.gd")
const DiscoveryFrontierCatalog = preload("res://scripts/discovery_frontier_catalog.gd")
const SocietyModelScript = preload("res://scripts/society_model.gd")
var society_model = SocietyModelScript.new()

var rng := RandomNumberGenerator.new()
var initialized := false
var technology_catalog:Array[Dictionary]=[]
var technology_limits:Dictionary={}
var catalog_by_id:Dictionary={}
var catalog_by_channel:Dictionary={}
var latest_context:Dictionary={}
var established_threads_cache:Array[Dictionary]=[]
var established_threads_signature:=""
const BASE_DISCOVERY_COUNT:=31
const FRONTIER_PATH_AVAILABILITY:=7200
const EFFECT_DISPLAY_NAMES:Dictionary={
	"conception_support":"safe conception support","maternal_safety":"maternal safety","food_output":"usable food output","nutrition_quality":"diet quality",
	"health_protection":"health protection","disease_exposure":"disease exposure","labor_efficiency":"labor efficiency","task_coordination":"task coordination",
	"knowledge_rate":"rate of learning","knowledge_preservation":"knowledge preservation","tool_quality":"tool quality","craft_output":"craft output",
	"construction_rate":"construction rate","disaster_resilience":"disaster resilience","haul_capacity":"carrying capacity","route_speed":"travel speed",
	"ecology_recovery":"ecological recovery","ecological_pressure":"ecological pressure","state_capacity":"state capacity","legitimacy":"legitimacy",
	"security_efficiency":"security efficiency","warfare_readiness":"military readiness","cohesion":"social cohesion","adoption_rate":"spread of new practices"
}

func reset_for_new_world()->void:
	initialized=false
	catalog.resize(BASE_DISCOVERY_COUNT)
	technology_catalog.clear()
	technology_limits.clear()
	catalog_by_id.clear()
	catalog_by_channel.clear()
	latest_context.clear()
	established_threads_cache.clear()
	established_threads_signature=""
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
	{"id":"supply_groups","name":"Organized Supply Parties","direction":"Warfare","chance":0.003,"day":75,"requires":["tallies","route_memory"],"signals":["logistics","travel"],"observation":"Separating carriers from scouts allows groups to travel farther."},
	# — Domestication line. The physical mount population the military's
	# cavalry gate has always demanded, and the transformative stride for
	# scouting range.
	{"id":"animal_taming","name":"Animal Taming","dynamic":"ecology","subcategory":"Resource sustainability","direction":"ecology","chance":0.005,"day":90,"requires":["seasonal_patterns"],"signals":["foraging","exploration"],"observation":"Orphaned young of herd animals raised beside the settlement stay, breed, and follow.","effects":{"food_output":0.004}},
	{"id":"pack_animals","name":"Pack Animal Husbandry","dynamic":"logistics","subcategory":"Carrying capacity","direction":"logistics","chance":0.004,"day":220,"requires":["animal_taming"],"signals":["logistics","travel"],"observation":"Tamed beasts under saddle-frames carry loads no human team matches, day after day.","effects":{"haul_capacity":0.008,"route_speed":0.004}},
	{"id":"domesticated_mounts","name":"Domesticated Mounts","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.003,"day":400,"requires":["pack_animals"],"signals":["travel","defense"],"observation":"Selected bloodlines accept riders. A mounted person moves like weather, not like walking.","effects":{"route_speed":0.010}},
	{"id":"mounted_scouts","name":"Mounted Scouting","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.004,"day":460,"requires":["domesticated_mounts"],"signals":["exploration","travel"],"observation":"Riders range in days across country that costs walkers weeks, and return fresh enough to tell it.","effects":{"route_speed":0.012}},
	# — Watercraft line. From river floats to coastal passage; open water stops
	# being an absolute wall for scout parties.
	{"id":"hide_floats","name":"Hide Floats","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.005,"day":140,"requires":["cordage"],"signals":["freshwater","travel"],"observation":"Inflated hides lashed into rafts carry people and bundles across still water."},
	{"id":"river_craft","name":"River Craft","dynamic":"logistics","subcategory":"Carrying capacity","direction":"logistics","chance":0.004,"day":320,"requires":["hide_floats","basketry"],"signals":["freshwater","logistics"],"observation":"Framed hulls with paddles run the river both ways; the current becomes a road.","effects":{"haul_capacity":0.006,"route_speed":0.006}},
	{"id":"coastal_watercraft","name":"Coastal Watercraft","dynamic":"logistics","subcategory":"Trade reach","direction":"logistics","chance":0.003,"day":600,"requires":["river_craft","joinery"],"signals":["travel","exploration"],"observation":"Sewn-plank hulls hold a heading along the coast and cross the mouths of bays.","effects":{"route_speed":0.008}}
]

func initialize() -> void:
	if initialized:
		return
	catalog_by_id.clear()
	catalog_by_channel.clear()
	rng.seed = GameState.world_seed ^ 0x6c8e9cf5
	catalog.append_array(ResourceKnowledgeCatalog.entries())
	catalog.append_array(SocietyKnowledgeCatalog.entries())
	catalog.append_array(preload("res://scripts/technology_branch_catalog.gd").entries())
	catalog.append_array(DiscoveryFrontierCatalog.entries())
	for i in catalog.size():
		catalog[i]=_classify_discovery(catalog[i])
		catalog[i]=society_model.normalize_discovery(catalog[i])
		var discovery:Dictionary=catalog[i]
		catalog_by_id[String(discovery.get("id",""))]=discovery
		if not bool(discovery.get("frontier",false)): technology_catalog.append(discovery)
		if bool(discovery.get("frontier",false)): continue
		var channel:=_channel_key(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
		if not catalog_by_channel.has(channel): catalog_by_channel[channel]=[]
		(catalog_by_channel[channel] as Array).append(discovery)
	# Candidate order depends only on the world seed and static definition, so
	# sort each fixed research channel once instead of sorting the full frontier
	# on every simulated day.
	for channel_variant in catalog_by_channel:
		var channel_catalog:Array=catalog_by_channel[channel_variant]
		channel_catalog.sort_custom(func(first:Dictionary,second:Dictionary)->bool:
			var first_order:int=int(first.get("day",0))+absi(hash("%s:%s" % [GameState.world_seed,first.get("id","")]))%240
			var second_order:int=int(second.get("day",0))+absi(hash("%s:%s" % [GameState.world_seed,second.get("id","")]))%240
			return first_order<second_order)
		catalog_by_channel[channel_variant]=channel_catalog
	initialized = true
	_refresh_active_investigations()

func process_day(context: Dictionary) -> Array[Dictionary]:
	initialize()
	HistoricalFigures.advance(int(GameState.elapsed_days))
	PeopleDirection.advance(int(GameState.elapsed_days))
	CommunityNetwork.advance(int(GameState.elapsed_days))
	ForeignDiplomacy.advance(int(GameState.elapsed_days))
	var effective_context:=context.duplicate(true)
	var military_campaign:=get_node_or_null("/root/MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("military_inquiry_context"):
		var military_context:Dictionary=military_campaign.military_inquiry_context()
		for signal_name in military_context:
			effective_context[signal_name]=float(effective_context.get(signal_name,0.0))+float(military_context[signal_name])
	latest_context=effective_context.duplicate(true)
	society_model.process_day(catalog,effective_context)
	var results: Array[Dictionary] = []
	var current_day := int(floor(GameState.elapsed_days))
	_refresh_active_investigations()
	for channel_variant in GameState.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var discovery_id:=String(GameState.active_investigations.get(channel,""))
		var discovery:=discovery_definition(discovery_id)
		if discovery.is_empty(): continue
		var allocation:=_subcategory_allocation(String(discovery.dynamic),String(discovery.subcategory))
		var research_capacity:=research_capacity_for(String(discovery.dynamic),String(discovery.subcategory))
		var attention:=float(research_capacity.get("progress_multiplier",0.0))
		if attention<=0.0: continue
		var activity := 0.65
		for activity_signal in discovery.signals:
			activity += float(effective_context.get(activity_signal, 0.0)) * 0.22
		var leader_factor := _leader_factor(String(discovery.dynamic))
		# Catalog chances describe relative discoverability. The global time scale keeps
		# knowledge unfolding across generations instead of exhausting an era in months.
		var material_evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
		var probability: float = discovery.chance / research_difficulty(discovery,GameState.world_seed) * attention * activity * material_evidence * leader_factor*ConsequenceEngine.discovery_multiplier()*(1.0+ProgressionSystem.effect("knowledge_rate"))*0.12
		var progress:=float(GameState.discovery_progress.get(discovery_id,0.0))
		progress+=probability*rng.randf_range(0.72,1.28)
		if rng.randf()<probability*0.10: progress+=rng.randf_range(0.025,0.085)
		GameState.discovery_progress[discovery_id]=clampf(progress,0.0,1.0)
		if progress>=1.0:
			GameState.known_discoveries.append(discovery.id)
			HistoricalFigures.record_discovery(String(discovery.dynamic),String(discovery.name),current_day)
			society_model.register_discovery(discovery,catalog)
			var event := player_facing_discovery_event({"day": current_day, "id":discovery.id, "name": discovery.name, "description": discovery.observation, "ability_reason":String(discovery.get("ability_reason","")),"social_consequence":String(discovery.get("social_consequence","")),"effect_summary":_effect_summary(discovery.get("effects",{})),"direction":discovery.dynamic,"dynamic":discovery.dynamic,"subcategory":discovery.subcategory,"effects":discovery.get("effects",{}).duplicate(true),"adoption":society_model.adoption(String(discovery.id))})
			GameState.discovery_log.push_front(event)
			if GameState.discovery_log.size()>512: GameState.discovery_log.resize(512)
			GameState.active_investigations.erase(channel)
			GameState.discovery_progress.erase(discovery_id)
			results.append(event)
	_refresh_active_investigations()
	return results

func refresh_investigations()->void:
	initialize()
	_refresh_active_investigations()


func set_domain_research_priority(dynamic_id:String,weight:int)->void:
	initialize()
	if not GameState.research_subcategory_allocations.has(dynamic_id): return
	var bounded_weight:=clampi(weight,0,12)
	GameState.research_allocations[dynamic_id]=bounded_weight
	_auto_allocate_domain_attention(dynamic_id,bounded_weight,int(floor(GameState.elapsed_days)))
	_refresh_active_investigations()


func _auto_allocate_domain_attention(dynamic_id:String,weight:int,current_day:int)->void:
	# The player chooses one macro emphasis. Programs distribute that fixed attention
	# among the domain's four possible problem areas according to viable evidence,
	# lived activity and civilizational affinity. This is a constant 4-channel pass,
	# independent of population and hidden discoveries.
	var subcategories:Dictionary=(GameState.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).duplicate(true)
	if subcategories.is_empty(): return
	for subcategory in subcategories: subcategories[subcategory]=0
	GameState.research_subcategory_allocations[dynamic_id]=subcategories
	var channels:Array[Dictionary]=[]
	for subcategory_variant in subcategories:
		var subcategory:=String(subcategory_variant)
		var channel:=_channel_key(dynamic_id,subcategory)
		var candidate:=_best_candidate_for_channel(channel,current_day)
		if not candidate.is_empty(): channels.append({"subcategory":subcategory,"candidate":candidate,"live":true})
	# If evidence is temporarily unavailable, preserve the broad priority as quiet
	# preparatory attention rather than deleting it or leaking it into another domain.
	if channels.is_empty():
		for subcategory_variant in subcategories:
			channels.append({"subcategory":String(subcategory_variant),"candidate":{},"live":false})
	for _unit in maxi(0,weight):
		var best:Dictionary={}
		var best_score:=-INF
		for channel_data in channels:
			var subcategory:=String(channel_data.subcategory)
			var assigned:=int((GameState.research_subcategory_allocations[dynamic_id] as Dictionary).get(subcategory,0))
			var candidate:Dictionary=channel_data.candidate
			var score:=_candidate_score(candidate) if not candidate.is_empty() else float(posmod(hash("%s:%s:%s:auto_research" % [GameState.world_seed,dynamic_id,subcategory]),10_000))/100.0
			score-=float(assigned)*14.0
			if score>best_score:
				best_score=score
				best=channel_data
		if best.is_empty(): break
		var target:=String(best.subcategory)
		var allocations:Dictionary=GameState.research_subcategory_allocations[dynamic_id]
		allocations[target]=int(allocations.get(target,0))+1
		GameState.research_subcategory_allocations[dynamic_id]=allocations

func active_investigation_records()->Array[Dictionary]:
	initialize()
	_refresh_active_investigations()
	var records:Array[Dictionary]=[]
	for channel in GameState.active_investigations:
		var id:=String(GameState.active_investigations.get(channel,""))
		if id=="": continue
		var discovery:=discovery_definition(id).duplicate(true)
		if discovery.is_empty(): continue
		var progress:=float(GameState.discovery_progress.get(id,0.0))
		var allocation:=_subcategory_allocation(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
		var leader_factor:=_leader_factor(String(discovery.get("dynamic","")))
		var material_evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
		var research_capacity:=research_capacity_for(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
		var baseline_momentum:=float(discovery.get("chance",0.001))/research_difficulty(discovery,GameState.world_seed)*float(research_capacity.get("progress_multiplier",0.0))*material_evidence*leader_factor*ConsequenceEngine.discovery_multiplier()*(1.0+ProgressionSystem.effect("knowledge_rate"))*0.12
		discovery["discovery_name"]=String(discovery.get("name","Undetermined discovery"))
		discovery["name"]=String(discovery.get("name","Investigation"))
		discovery["progress"]=progress
		discovery["observer_allocation"]=allocation
		discovery["research_workforce"]=float(research_capacity.get("researchers",0.0))
		discovery["research_share"]=float(research_capacity.get("workforce_share",0.0))
		discovery["research_capacity_multiplier"]=float(research_capacity.get("progress_multiplier",0.0))
		discovery["leader_factor"]=leader_factor
		discovery["material_evidence"]=material_evidence
		discovery["project_goal"]=_project_goal(discovery)
		discovery["project_method"]=_project_method(discovery)
		discovery["unlock_summary"]=String(discovery.get("observation",""))+"\n"+_effect_summary(discovery.get("effects",{}))
		discovery["bottleneck"]=_investigation_bottleneck(discovery,allocation,leader_factor,material_evidence,progress,research_capacity)
		discovery["estimated_days"]=ceili((1.0-progress)/maxf(0.000001,baseline_momentum))
		records.append(discovery)
	return records


func _default_line_name(discovery:Dictionary)->String:
	## Base-catalog discoveries carry no authored line name; draw a varied one
	## deterministically so the investigations page never reads as one
	## sentence repeated with the noun swapped.
	var templates:Array=DiscoveryFrontierCatalog.LINE_NAME_TEMPLATES
	var index:=absi(hash("%s:%s:line" % [GameState.world_seed,String(discovery.get("id",""))]))%templates.size()
	return String(templates[index]).format({"subject":String(discovery.get("subcategory","an unresolved condition")).to_lower(),"lens":"practical evidence"})


func _project_goal(discovery:Dictionary) -> String:
	var explicit:=String(discovery.get("question",""))
	if explicit!="": return explicit
	var subcategory:=String(discovery.get("subcategory","this condition")).to_lower()
	return "Can repeated evidence turn %s into a reliable, teachable advantage?" % subcategory


func _project_method(discovery:Dictionary) -> String:
	var explicit:=String(discovery.get("method",""))
	if explicit!="": return explicit
	var signals:Array=discovery.get("signals",[])
	var signal_text:=", ".join(PackedStringArray(signals)) if not signals.is_empty() else "daily work"
	return "Observers compare %s and preserve results until the method can be repeated." % signal_text


func _effect_summary(effects:Dictionary) -> String:
	if effects.is_empty(): return "Unlocks a prerequisite used by later practical methods."
	var parts:Array[String]=[]
	for effect_id in effects:
		var value:=float(effects[effect_id])
		parts.append("%s %+.1f%%" % [String(EFFECT_DISPLAY_NAMES.get(String(effect_id),String(effect_id).replace("_"," "))).capitalize(),value*100.0])
	return "ESTABLISHED CAPACITY CHANGE  •  "+"  •  ".join(parts)


func _investigation_bottleneck(discovery:Dictionary,allocation:int,leader_factor:float,material_evidence:float,progress:float,research_capacity:Dictionary={}) -> String:
	if allocation<=0: return "NO RESEARCH PRIORITY — project is paused"
	var research_workforce:=float(research_capacity.get("researchers",0.0))
	if research_workforce<1.0: return "RESEARCH WORKFORCE — this emphasis receives less than one full-time-equivalent researcher"
	if material_evidence<0.78: return "MATERIAL BASIS — survey or work the required resource"
	if leader_factor<0.72: return "LEADERSHIP — the responsible office is weak or vacant"
	if float(research_capacity.get("support_multiplier",1.0))<0.82: return "RESEARCH SUPPORT — food, tools, records, or administration are constraining the program"
	if progress<0.25: return "EARLY EVIDENCE — more repeated cases are required"
	if progress<0.75: return "REPLICATION — the proposed method is being tested across cases"
	return "VALIDATION — the result is close to becoming established knowledge"

func _refresh_active_investigations()->void:
	var current_day:=int(floor(GameState.elapsed_days))
	for channel_variant in GameState.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var id:=String(GameState.active_investigations.get(channel,""))
		var discovery:=discovery_definition(id)
		if discovery.is_empty() or _subcategory_allocation(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))<=0 or id in GameState.known_discoveries or not _discovery_is_eligible(discovery,current_day):
			GameState.active_investigations.erase(channel)
	# Attention is a strategic resource, not a queue of forty-eight tiny chores.
	# When a line completes or temporarily runs out of evidence, keep the same
	# number of observers working by redirecting them toward a live frontier. The
	# redirect prefers the same broad domain, then the civilization's seeded focus,
	# actual activity, leadership and material evidence decide the specific line.
	_redistribute_stranded_attention(current_day)
	for channel_data in _allocated_channels():
		var dynamic_id:=String(channel_data.dynamic)
		var subcategory:=String(channel_data.subcategory)
		var channel:=_channel_key(dynamic_id,subcategory)
		if String(GameState.active_investigations.get(channel,""))!="": continue
		var candidate:=_best_candidate_for_channel(channel,current_day)
		if not candidate.is_empty(): GameState.active_investigations[channel]=String(candidate.id)
	GameState.active_observations.clear()
	for record in active_investigation_records_shallow():
		GameState.active_observations.append(String(record.observation))


func _redistribute_stranded_attention(current_day:int)->void:
	var stranded:Array[Dictionary]=[]
	for dynamic_variant in GameState.research_subcategory_allocations:
		var dynamic_id:=String(dynamic_variant)
		var subcategories:Dictionary=GameState.research_subcategory_allocations[dynamic_variant]
		for subcategory_variant in subcategories:
			var subcategory:=String(subcategory_variant)
			var allocation:=int(subcategories[subcategory_variant])
			if allocation<=0: continue
			var channel:=_channel_key(dynamic_id,subcategory)
			if not _best_candidate_for_channel(channel,current_day).is_empty(): continue
			stranded.append({"dynamic":dynamic_id,"subcategory":subcategory,"count":allocation})
			subcategories[subcategory_variant]=0
		GameState.research_subcategory_allocations[dynamic_variant]=subcategories
	if stranded.is_empty(): return
	var live_channels:Array[Dictionary]=[]
	for dynamic_variant in GameState.research_subcategory_allocations:
		var dynamic_id:=String(dynamic_variant)
		for subcategory_variant in (GameState.research_subcategory_allocations[dynamic_variant] as Dictionary):
			var subcategory:=String(subcategory_variant)
			var channel:=_channel_key(dynamic_id,subcategory)
			var candidate:=_best_candidate_for_channel(channel,current_day)
			if candidate.is_empty(): continue
			live_channels.append({"dynamic":dynamic_id,"subcategory":subcategory,"channel":channel,"candidate":candidate})
	if live_channels.is_empty():
		# A genuine evidence drought should not erase the player's broad emphasis.
		# Leave the allocation waiting quietly; a later encounter/day gate will wake it.
		for entry in stranded:
			var restored:Dictionary=GameState.research_subcategory_allocations.get(String(entry.dynamic),{})
			restored[String(entry.subcategory)]=int(restored.get(String(entry.subcategory),0))+int(entry.count)
			GameState.research_subcategory_allocations[String(entry.dynamic)]=restored
		_rebuild_research_domain_totals()
		return
	for entry in stranded:
		for _observer in int(entry.count):
			var best:Dictionary={}
			var best_score:=-INF
			for live in live_channels:
				var target_dynamic:=String(live.dynamic)
				# Macro emphasis is authoritative. A Nutrition priority may shift between
				# food questions, but it can never silently become Military or Culture.
				if target_dynamic!=String(entry.dynamic): continue
				var target_subcategory:=String(live.subcategory)
				var current_allocation:=_subcategory_allocation(target_dynamic,target_subcategory)
				var candidate:Dictionary=live.candidate
				var score:=_candidate_score(candidate)-float(current_allocation)*14.0
				if score>best_score:
					best_score=score
					best=live
			if best.is_empty():
				var restored:Dictionary=GameState.research_subcategory_allocations.get(String(entry.dynamic),{})
				restored[String(entry.subcategory)]=int(restored.get(String(entry.subcategory),0))+1
				GameState.research_subcategory_allocations[String(entry.dynamic)]=restored
				continue
			var target_allocations:Dictionary=GameState.research_subcategory_allocations.get(String(best.dynamic),{})
			target_allocations[String(best.subcategory)]=int(target_allocations.get(String(best.subcategory),0))+1
			GameState.research_subcategory_allocations[String(best.dynamic)]=target_allocations
	_rebuild_research_domain_totals()


func _rebuild_research_domain_totals()->void:
	for dynamic_variant in GameState.research_subcategory_allocations:
		var total:=0
		for allocation in (GameState.research_subcategory_allocations[dynamic_variant] as Dictionary).values():
			total+=int(allocation)
		GameState.research_allocations[String(dynamic_variant)]=total

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
	if not _path_is_viable(discovery): return false
	for requirement in discovery.get("requires",[]):
		if String(requirement) not in GameState.known_discoveries: return false
	return _resource_requirements_met(discovery.get("resource_requirements",[]))


func _best_candidate_for_channel(channel:String,current_day:int)->Dictionary:
	var best:Dictionary={}
	var best_score:=-INF
	for discovery_variant in (catalog_by_channel.get(channel,[]) as Array):
		var discovery:Dictionary=discovery_variant
		if not _discovery_is_eligible(discovery,current_day): continue
		var score:=_candidate_score(discovery)
		if String(GameState.research_targets.get(channel,""))==String(discovery.id): score+=100000.0
		if score>best_score:
			best_score=score
			best=discovery
	return best


# Each world has a different but generous subset of the 4,608 latent routes.
# Availability is decided per entire investigative tradition, not per person or
# per day, so it is reproducible, save-free, and constant-time at population scale.
func _path_is_viable(discovery:Dictionary,civilization_seed:int=0)->bool:
	# Old generated maturity/lens entries remain readable for saved bonuses and
	# history, but are retired from both player and rival research pools.
	if bool(discovery.get("frontier",false)): return false
	return true

func _legacy_path_was_viable(discovery:Dictionary,civilization_seed:int=0)->bool:
	if not bool(discovery.get("frontier",false)): return true
	var seed_value:=GameState.world_seed if civilization_seed==0 else civilization_seed
	var path_key:=String(discovery.get("path_key",discovery.get("id","")))
	var channel:=_channel_key(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
	var lens_index:=int(discovery.get("lens_index",0))
	# Every subcondition always has at least two viable traditions. The remaining
	# routes are contingent, giving worlds meaningful divergence without dead ends.
	var guaranteed_a:=posmod(hash("%s:%s:anchor" % [seed_value,channel]),DiscoveryFrontierCatalog.LENSES.size())
	var guaranteed_b:=posmod(guaranteed_a+3+posmod(hash("%s:%s:counter" % [seed_value,channel]),4),DiscoveryFrontierCatalog.LENSES.size())
	if lens_index==guaranteed_a or lens_index==guaranteed_b: return true
	return posmod(hash("%s:%s:viability" % [seed_value,path_key]),10_000)<FRONTIER_PATH_AVAILABILITY


func _candidate_score(discovery:Dictionary)->float:
	var id:=String(discovery.get("id",""))
	var score:=research_affinity(discovery,GameState.world_seed,FoodSystem.current_environment_profile())
	var dynamic_id:=String(discovery.get("dynamic",""))
	var subcategory:=String(discovery.get("subcategory",""))
	var allocation:=_subcategory_allocation(dynamic_id,subcategory)
	score+=float(allocation)*8.0
	for signal_name in discovery.get("signals",[]):
		score+=clampf(float(latest_context.get(signal_name,0.0)),0.0,4.0)*13.0
	var subcategory_scores:Dictionary=GameState.society_subcategories.get(dynamic_id,{})
	score+=clampf(float(subcategory_scores.get(subcategory,0.0)),0.0,1.0)*12.0
	score+=_founding_lens_affinity(String(discovery.get("lens","")))*18.0
	# Once a society has invested in a viable tradition, its deeper methods have
	# a modest continuity advantage, but other routes can still overtake it.
	score+=float(discovery.get("stage_index",0))*3.5
	return score


func _founding_lens_affinity(lens:String)->float:
	var favored:Dictionary={
		"provision":["Seasonal Comparison","Household Experience","Environmental Contrast"],
		"generations":["Household Experience","Recorded Cases","Institutional Trial"],
		"inquiry":["Recorded Cases","Regional Comparison","Material Experiment"],
		"industry":["Material Experiment","Workplace Practice","Institutional Trial"],
		"defense":["Workplace Practice","Institutional Trial","Regional Comparison"],
		"exchange":["Regional Comparison","Seasonal Comparison","Recorded Cases"]
	}
	var focus:=GameState.founding_focus if GameState.founding_focus!="" else "provision"
	var list:Array=favored.get(focus,[])
	var index:=list.find(lens)
	return 1.0-float(index)*0.22 if index>=0 else 0.0


# Saved discovery events are historical facts, but old saves may contain the
# former adjective-permutation titles and prose. Always resolve authored fields
# from the current definition so the repaired knowledge record takes effect
# without deleting a player's campaign.
func player_facing_discovery_event(source:Dictionary)->Dictionary:
	initialize()
	var event:=source.duplicate(true)
	var discovery_id:=String(event.get("id",""))
	var definition:Dictionary=catalog_by_id.get(discovery_id,{})
	if definition.is_empty(): return event
	for field in ["name","thread_key","thread_name","milestone_key","breakthrough_name","route_name","causal_mechanism","evidence_method","operating_capability","ability_reason","social_consequence","maturity","lens"]:
		if definition.has(field): event[field]=definition[field]
	event["dynamic"]=String(definition.get("dynamic",event.get("dynamic",event.get("direction","knowledge"))))
	event["direction"]=event["dynamic"]
	event["subcategory"]=String(definition.get("subcategory",event.get("subcategory","Established practice")))
	event["description"]=String(definition.get("causal_mechanism",definition.get("observation",event.get("description",""))))
	event["effects"]=(definition.get("effects",event.get("effects",{})) as Dictionary).duplicate(true)
	event["effect_summary"]=_effect_summary(event["effects"])
	return event


# The library is organized around concrete bodies of knowledge rather than an
# archaeological dump of every survey/measurement/validation step. Each row is
# one practical thread; its details retain the actual breakthroughs, route,
# evidence, date, adoption, and cumulative consequences.
func established_knowledge_threads()->Array[Dictionary]:
	initialize()
	var log_signature:="%d:%d" % [GameState.discovery_log.size(),hash(GameState.discovery_log)]
	if log_signature==established_threads_signature:
		return established_threads_cache.duplicate(true)
	var by_thread:Dictionary={}
	var thread_order:Array[String]=[]
	for event_variant in GameState.discovery_log:
		if not event_variant is Dictionary: continue
		var event:=player_facing_discovery_event(event_variant)
		var definition:Dictionary=catalog_by_id.get(String(event.get("id","")),{})
		var dynamic_id:=String(event.get("dynamic",event.get("direction","knowledge")))
		var subcategory:=String(event.get("subcategory","Established practice"))
		var thread_key:=String(event.get("thread_key","%s::%s" % [dynamic_id,subcategory])) if bool(definition.get("frontier",false)) else String(event.get("id","%s::%s" % [dynamic_id,subcategory]))
		if not by_thread.has(thread_key):
			var thread:=event.duplicate(true)
			thread["thread_key"]=thread_key
			thread["name"]=String(event.get("thread_name",event.get("name",subcategory))) if bool(definition.get("frontier",false)) else String(event.get("name",subcategory))
			thread["legacy_refinement"]=bool(definition.get("frontier",false))
			thread["latest_breakthrough"]=String(event.get("name","Established practice"))
			thread["latest_stage_name"]=String(event.get("breakthrough_name","Established practice"))
			thread["breakthrough_count"]=0
			thread["raw_event_count"]=0
			thread["effects"]={}
			thread["history"]=[]
			thread["_milestones"]={}
			by_thread[thread_key]=thread
			thread_order.append(thread_key)
		var current:Dictionary=by_thread[thread_key]
		current["raw_event_count"]=int(current.get("raw_event_count",0))+1
		var history:Array=current.get("history",[])
		if history.size()<12: history.append(event)
		current["history"]=history
		var milestone_token:=String(event.get("milestone_key",event.get("id","")))
		var milestones:Dictionary=current.get("_milestones",{})
		if milestone_token=="" or not milestones.has(milestone_token):
			if milestone_token!="": milestones[milestone_token]=true
			current["breakthrough_count"]=int(current.get("breakthrough_count",0))+1
			var cumulative_effects:Dictionary=current.get("effects",{})
			for effect_id in (event.get("effects",{}) as Dictionary):
				cumulative_effects[effect_id]=float(cumulative_effects.get(effect_id,0.0))+float((event.effects as Dictionary)[effect_id])
			current["effects"]=cumulative_effects
		current["_milestones"]=milestones
		by_thread[thread_key]=current
	var result:Array[Dictionary]=[]
	for thread_key in thread_order:
		var thread:Dictionary=by_thread[thread_key]
		thread.erase("_milestones")
		var count:=int(thread.get("breakthrough_count",1))
		thread["description"]="Latest breakthrough: %s\n%s" % [String(thread.get("latest_breakthrough","Established practice")),String(thread.get("description",""))]
		thread["effect_summary"]=_effect_summary(thread.get("effects",{}))
		thread["record_summary"]="Archived practice · %d historical refinements · no further repeat research" % count if bool(thread.get("legacy_refinement",false)) else "Discovered once · day %d" % int(thread.get("day",0))
		result.append(thread)
	established_threads_signature=log_signature
	established_threads_cache=result.duplicate(true)
	return result


# Player-facing summaries intentionally describe only knowledge the civilization
# has established and the shape of its current frontier. Hidden candidate names,
# total route counts, and future order never leave this API.
func frontier_snapshot(dynamic_id:String)->Dictionary:
	initialize()
	var known:Array[Dictionary]=[]
	var recent:Array[Dictionary]=[]
	var lenses:Dictionary={}
	var subcategories:Dictionary={}
	var highest_maturity:=0
	for id_variant in GameState.known_discoveries:
		var definition:Dictionary=catalog_by_id.get(String(id_variant),{})
		if String(definition.get("dynamic",""))!=dynamic_id: continue
		known.append(definition)
		highest_maturity=maxi(highest_maturity,int(definition.get("maturity",1)))
		var lens:=String(definition.get("lens","Practical experience"))
		lenses[lens]=int(lenses.get(lens,0))+1
		var subcategory:=String(definition.get("subcategory","General practice"))
		subcategories[subcategory]=int(subcategories.get(subcategory,0))+1
	for event_variant in established_knowledge_threads():
		var event:Dictionary=event_variant
		if String(event.get("dynamic",event.get("direction","")))==dynamic_id:
			recent.append(event.duplicate(true))
			if recent.size()>=8: break
	var active:Array[Dictionary]=[]
	for record in active_investigation_records():
		if String(record.get("dynamic",""))==dynamic_id: active.append(record)
	var viable_now:=0
	var viable_later:=0
	var current_day:=int(floor(GameState.elapsed_days))
	for channel_variant in catalog_by_channel:
		var channel:=String(channel_variant)
		if not channel.begins_with(dynamic_id+"::"): continue
		for definition_variant in (catalog_by_channel[channel] as Array):
			var definition:Dictionary=definition_variant
			if String(definition.get("id","")) in GameState.known_discoveries or not _path_is_viable(definition): continue
			if _discovery_is_eligible(definition,current_day): viable_now+=1
			else: viable_later+=1
	var emphasis:Array[Dictionary]=[]
	var allocations:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
	for subcategory in allocations:
		var observers:=int(allocations[subcategory])
		if observers>0: emphasis.append({"name":String(subcategory),"observers":observers})
	emphasis.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.observers)>int(b.observers))
	var opportunity_signal:="QUIET"
	if viable_now>=12: opportunity_signal="ABUNDANT"
	elif viable_now>=4: opportunity_signal="SEVERAL LIVE LEADS"
	elif viable_now>0: opportunity_signal="NARROW LEADS"
	elif viable_later>0: opportunity_signal="LATENT"
	return {
		"domain":dynamic_id,"known_count":known.size(),"highest_maturity":highest_maturity,
		"subcategory_breadth":subcategories.size(),"tradition_breadth":lenses.size(),
		"traditions":_ranked_keys(lenses,4),"emphasis":emphasis,"active":active,
		"recent":recent,"opportunity_signal":opportunity_signal,"catalog_hidden":true
	}


func _ranked_keys(counts:Dictionary,limit:int)->Array[String]:
	var keys:Array=counts.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:
		var delta:=int(counts.get(a,0))-int(counts.get(b,0))
		return String(a)<String(b) if delta==0 else delta>0)
	var result:Array[String]=[]
	for index in mini(limit,keys.size()): result.append(String(keys[index]))
	return result


# Internal deterministic probes used by tests and rival simulation diagnostics.
# This is never called by UI code.
func candidate_ids_for_channel(channel:String,civilization_seed:int,limit:int=16)->Array[String]:
	initialize()
	var scored:Array[Dictionary]=[]
	for definition_variant in (catalog_by_channel.get(channel,[]) as Array):
		var definition:Dictionary=definition_variant
		if not _path_is_viable(definition,civilization_seed): continue
		scored.append({"id":String(definition.id),"score":posmod(hash("%s:%s" % [civilization_seed,definition.id]),10_000)})
	scored.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.score)>int(b.score))
	var result:Array[String]=[]
	for index in mini(limit,scored.size()): result.append(String(scored[index].id))
	return result

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
	# The named-person government has seven canonical aptitudes. Specific fields
	# of inquiry still differ, but they are composed from those visible skills so
	# an excellent Scholar or Steward actually changes research throughput.
	var mapping := {
		"demography":["Steward",["Provisioning","Diplomacy"]],"nutrition":["Quartermaster",["Provisioning","Logistics"]],
		"health":["Steward",["Provisioning","Knowledge"]],"labor":["Steward",["Administration","Construction"]],
		"knowledge":["Scholar",["Knowledge","Administration"]],"production":["Quartermaster",["Construction","Logistics"]],
		"infrastructure":["Steward",["Construction","Administration"]],"logistics":["Quartermaster",["Logistics","Administration"]],
		"ecology":["Scholar",["Knowledge","Provisioning"]],"institutions":["Steward",["Administration","Diplomacy"]],
		"security":["Marshal",["Defense","Administration"]],"culture":["Envoy",["Diplomacy","Knowledge"]]
	}
	var assignment: Array = mapping.get(direction,["Scholar",["Knowledge"]])
	return AdvisorSystem.execution_modifier(assignment[0],assignment[1])*ForeignDiplomacy.multiplier(direction)*HistoricalFigures.multiplier(direction)*PeopleDirection.research_multiplier(direction)*CommunityNetwork.multiplier(direction)

func _subcategory_allocation(dynamic_id:String,subcategory:String)->int:
	return int((GameState.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).get(subcategory,0))


# Research allocation values are strategic weights, never person records. The
# Knowledge labor role supplies the aggregate workforce; emphasis divides that
# workforce among at most 48 fixed inquiry channels. More people therefore
# create more parallel and faster science without creating runtime work per
# researcher. Logarithmic team returns prevent a billion people from completing
# every discovery in a single tick, while knowledge, institutions, materials,
# and food compound the civilization's ability to use that scale.
func research_capacity_for(dynamic_id:String,subcategory:String)->Dictionary:
	var weight:=maxi(0,_subcategory_allocation(dynamic_id,subcategory))
	var total_weight:=research_emphasis_total()
	var total_researchers:=maxf(0.0,float(GameState.population_allocations.get("Knowledge",0)))
	var workforce_share:=float(weight)/maxf(1.0,float(total_weight)) if weight>0 else 0.0
	var researchers:=total_researchers*workforce_share
	var team_scale:=0.0
	if researchers>0.0:
		team_scale=researchers if researchers<1.0 else 1.0+log(researchers)/log(10.0)*0.78
	var food_support:=lerpf(0.62,1.08,clampf(float(GameState.food_security),0.0,1.0))
	var material_capacity:=clampf(float(GameState.simulation_metrics.get("material_capacity",GameState.society_capacities.get("production",0.12))),0.0,1.2)
	var material_support:=lerpf(0.72,1.12,material_capacity/1.2)
	var institutional_capacity:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	var knowledge_capacity:=clampf(float(GameState.society_capacities.get("knowledge",0.18)),0.0,1.0)
	var support_multiplier:=food_support*material_support*lerpf(0.78,1.18,institutional_capacity)*lerpf(0.82,1.24,knowledge_capacity)
	return {
		"weight":weight,"total_weight":total_weight,"total_researchers":total_researchers,
		"workforce_share":workforce_share,"researchers":researchers,"team_scale":team_scale,
		"support_multiplier":support_multiplier,"progress_multiplier":team_scale*support_multiplier
	}


func research_emphasis_total()->int:
	var total:=0
	for dynamic_id in GameState.research_subcategory_allocations:
		for value in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary).values(): total+=maxi(0,int(value))
	return total


func research_program_summary()->Dictionary:
	var active_lines:=0
	var weighted_capacity:=0.0
	var total_weight:=research_emphasis_total()
	for dynamic_id in GameState.research_subcategory_allocations:
		for subcategory in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary):
			var weight:=_subcategory_allocation(String(dynamic_id),String(subcategory))
			if weight<=0: continue
			active_lines+=1
			weighted_capacity+=float(research_capacity_for(String(dynamic_id),String(subcategory)).get("progress_multiplier",0.0))*float(weight)
	return {
		"researchers":maxi(0,int(GameState.population_allocations.get("Knowledge",0))),
		"emphasis_total":total_weight,"active_lines":active_lines,
		"average_line_capacity":weighted_capacity/maxf(1.0,float(total_weight))
	}

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
	if discovery.has("dynamic") and discovery.has("subcategory"):
		if not discovery.has("social_consequence"): discovery["social_consequence"]=String(DiscoveryFrontierCatalog.SOCIAL_RESULTS.get(String(discovery.dynamic),"Collective expectations change as the practice spreads"))
		return discovery
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
	discovery["social_consequence"]=String(DiscoveryFrontierCatalog.SOCIAL_RESULTS.get(dynamic_id,"Collective expectations change as the practice spreads"))
	return discovery

## Concrete authored technologies are the live tree. Historical generated entries
## stay in the catalog solely so existing discoveries retain their effects.
func technology_tree(dynamic_id:String="")->Array[Dictionary]:
	initialize()
	var rows:Array[Dictionary]=[]
	var children:Dictionary={}
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)): continue
		for requirement in entry.get("requires",[]):
			if not children.has(String(requirement)): children[String(requirement)]=[]
			(children[String(requirement)] as Array).append(String(entry.name))
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)): continue
		if dynamic_id!="" and String(entry.dynamic)!=dynamic_id: continue
		var id:=String(entry.id)
		var row:=entry.duplicate(true)
		var missing:Array[String]=[]
		for requirement in entry.get("requires",[]):
			if String(requirement) not in GameState.known_discoveries: missing.append(String(catalog_by_id.get(String(requirement),{}).get("name",requirement)))
		if int(GameState.elapsed_days)<int(entry.get("day",0)): missing.append("earliest day %d" % int(entry.day))
		if not _resource_requirements_met(entry.get("resource_requirements",[])):
			for requirement in entry.get("resource_requirements",[]): missing.append("%s: %s access" % [String(requirement.get("resource","material")),String(requirement.get("stage","recognized"))])
		var known:=id in GameState.known_discoveries
		row["ready"]=not known and missing.is_empty()
		row["missing"]=missing
		row["leads_to"]=children.get(id,[])
		row["progress"]=float(GameState.discovery_progress.get(id,0.0))
		row["research_difficulty"]=research_difficulty(entry,GameState.world_seed)
		var channel:=_channel_key(String(entry.dynamic),String(entry.subcategory))
		row["status"]="DISCOVERED" if known else ("RESEARCHING" if String(GameState.active_investigations.get(channel,""))==id else ("AVAILABLE" if missing.is_empty() else "LOCKED"))
		rows.append(row)
	return rows

func select_research_target(discovery_id:String)->Dictionary:
	initialize()
	var discovery:Dictionary=catalog_by_id.get(discovery_id,{})
	if discovery.is_empty() or not _discovery_is_eligible(discovery,int(GameState.elapsed_days)): return {"ok":false,"reason":"This technology is not currently researchable."}
	var domain:=String(discovery.dynamic)
	var subcategory:=String(discovery.subcategory)
	var channel:=_channel_key(domain,subcategory)
	var allocations:Dictionary=GameState.research_subcategory_allocations.get(domain,{})
	if int(allocations.get(subcategory,0))<=0:
		for other in allocations:
			if int(allocations[other])>0:
				allocations[other]=int(allocations[other])-1
				break
		allocations[subcategory]=1
	GameState.research_subcategory_allocations[domain]=allocations
	GameState.research_targets[channel]=discovery_id
	GameState.active_investigations[channel]=discovery_id
	_rebuild_research_domain_totals()
	return {"ok":true}

## A stable seeded draw: saves/reloads never reroll the same technology.
## Bounded variance changes pace without bypassing any causal eligibility gate.
func research_difficulty(discovery:Dictionary,civilization_seed:int)->float:
	return 0.85+_research_draw(String(discovery.id),civilization_seed,"cost")*0.30

func research_affinity(discovery:Dictionary,civilization_seed:int,environment:Dictionary)->float:
	var score:=_research_draw(String(discovery.id),civilization_seed,"affinity")*100.0
	var domain:=String(discovery.get("dynamic",""))
	var hazards:Dictionary=environment.get("hazards",{})
	if domain=="nutrition": score+=float(hazards.get("drought",0.0))*25.0+float(environment.get("fertility",0.0))*20.0
	if domain=="health": score+=float(hazards.get("disease",0.0))*30.0
	if domain=="logistics": score+=float(environment.get("route_potential",0.0))*25.0
	if domain=="infrastructure": score+=float(environment.get("relief",0.0))*20.0+float(hazards.get("cold",0.0))*20.0
	for requirement in discovery.get("resource_requirements",[]): score+=float((environment.get("resource_potentials",{}) as Dictionary).get(String(requirement.get("resource","")),0.0))*15.0
	return score

func rival_research_candidates(civ:Dictionary,domain:String)->Array[Dictionary]:
	initialize()
	var profile:Dictionary=civ.get("discovery_profile",{})
	var known:Array=profile.get("technologies",[])
	var environment:Dictionary=civ.get("environment_profile",{})
	var resources:Dictionary=environment.get("resource_potentials",{})
	var candidates:Array[Dictionary]=[]
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)) or String(entry.dynamic)!=domain or String(entry.id) in known: continue
		if int(GameState.elapsed_days)<int(entry.get("day",0)): continue
		var viable:=true
		for requirement in entry.get("requires",[]):
			if String(requirement) not in known: viable=false; break
		if not viable: continue
		for requirement in entry.get("resource_requirements",[]):
			if float(resources.get(String(requirement.get("resource","")),0.0))<0.16: viable=false; break
			var access:=String(requirement.get("stage","recognized"))
			var capacity_floor:=0.12 if access=="recognized" else (0.20 if access=="surveyed" else (0.35 if access=="accessible" else 0.55))
			if minf(float(civ.get("production",0.0)),float(civ.get("logistics",0.0)))<capacity_floor: viable=false; break
		if viable: candidates.append(entry)
	var seed_value:=int(profile.get("seed",GameState.world_seed))
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return research_affinity(a,seed_value,environment)>research_affinity(b,seed_value,environment))
	return candidates

func technology_depth(id:String,visiting:Dictionary={})->int:
	if visiting.has(id): return 0
	var entry:Dictionary=catalog_by_id.get(id,{})
	if entry.has("causal_depth"): return int(entry.causal_depth)
	var path:=visiting.duplicate()
	path[id]=true
	var depth:=1
	for parent in entry.get("requires",[]): depth=maxi(depth,1+technology_depth(String(parent),path))
	entry["causal_depth"]=depth
	return depth

func domain_technology_limits(domain:String)->Dictionary:
	initialize()
	if technology_limits.has(domain): return technology_limits[domain]
	var total:=0
	var depth:=1
	var conditions:Dictionary={}
	for entry in technology_catalog:
		if String(entry.dynamic)!=domain: continue
		total+=1
		depth=maxi(depth,technology_depth(String(entry.id)))
		conditions[String(entry.subcategory)]=true
	var limits:={"available_count":total,"available_maturity":depth,"available_breadth":conditions.size(),"available_lens_count":1}
	technology_limits[domain]=limits
	return limits

func _research_draw(id:String,seed_value:int,purpose:String)->float:
	var random:=RandomNumberGenerator.new()
	random.seed=hash(id+":"+purpose)^(seed_value*0x45d9f3b)
	return random.randf()
