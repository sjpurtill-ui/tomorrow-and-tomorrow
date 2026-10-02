extends Node

var rng := RandomNumberGenerator.new()
var initialized := false
const SPAN:=preload("res://scripts/day_span.gd")
const SURFACE_FRONT_SPACING_KM:=3.0
const MAX_SURFACE_FRONT_RING:=3
## Carriers at work for each ring of new ground searched past the first.
const SURFACE_SEARCH_CARRIERS:=6.0
const MAX_SURFACE_FRONTS_PER_RESOURCE:=24

# Identification follows observations and existing methods, never campaign age.
# These gates apply to unknown occurrences only; saved recognition is retained.
const RECOGNITION_RULES={
	"Ochre Earth":{"requires_all":["stone_sorting","clay_testing"]},
	"Zinc Ore":{"requires_all":["ore_assaying"]},
	"Kaolin":{"requires_all":["clay_testing"],"requires_any":[["high_fire_stoneware","pale_hard_fired_ware"]]},
	"Rutile Ore":{"requires_all":["ore_assaying"]},
	"Bauxite":{"requires_all":["ore_assaying"]},
	"Nickel Ore":{"requires_all":["ore_assaying"]},
	"Silver Ore":{"requires_all":["ore_assaying"]},
	"Gold Ore":{"requires_all":["ore_assaying"]},
	"Crude Oil":{"requires_all":["mineral_specific_gravity"],"requires_any":[["chemical_distillation","coal_grading"]]},
	"Deep Aquifer":{"requires_all":["well_siting"]},
	"Refractory Clay":{"requires_all":["pit_firing"]},
	"Phosphate Rock":{"requires_any":[["soil_assays","chemical_distillation"]]},
	"Uranium Ore":{"requires_all":["ore_assaying"],"requires_any":[["chemical_distillation","radiation_measurement"]]},
	"Nitrates":{"requires_all":["charcoal"],"requires_any":[["salt_working","chemical_distillation"]]},
	"Graphite":{"requires_any":[["stone_sorting","tallies"]]}
}
func recognition_ready(resource_name:String)->bool:
	if not catalog.has(resource_name):return false
	return bool(preload("res://scripts/technology_requirements.gd").evaluate(RECOGNITION_RULES.get(resource_name,{}),WorldSimulation.state.known_discoveries).ready)

const FOUNDING_SURFACE_RESOURCES:=["Timber","Stone","Fertile Soil","Game","Fiber Plants"]

# Keep the simulation/save key stable while giving players a name that describes
# the usable material rather than an unexplained class of plants.
## The name the player's people use; ores keep a plain name until their metal is known.
func display_name(resource_name:String)->String:
	return preload("res://scripts/resource_names.gd").label(resource_name)

func plain_language_description(resource_name:String)->String:
	if resource_name=="Stone": return "Loose surface stone can be gathered across rocky ground. Heavy blocks and deeper deposits still require better tools and access; gathered stone does not regrow."
	if resource_name=="Timber": return "Trees grow across woodland. Local cutting areas share extraction labor; tools, carrying distance and regrowth limit delivered timber."
	if resource_name=="Fiber Plants":
		return "Workable reeds, grasses, bark fibers, and flax- or hemp-like plants used for cordage, baskets, mats, and thatch."
	if resource_name=="Medicinal Plants": return "Recognized medicinal plants are gathered as finite bulk for remedies and care. Access does not imply free inventory."
	return ""

var _surface_front_cache:Dictionary={}
const SURFACE_FRONT_CACHE_LIMIT:=256

func reset_for_new_world()->void:
	_surface_front_cache.clear()
	initialized=false
	rng=RandomNumberGenerator.new()

# Internal resource definitions. recognition_year is retained legacy metadata,
# not a recognition, survey or extraction eligibility gate.
# UI receives discovered deposits and present constraints, never this catalog.
var catalog := {
	"Timber":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["cordage","joinery"],"signals":["survey","construction"],"base":0.030},
	"Freshwater":{"family":"Water","renewable":true,"recognition_year":0,"access":["labor"],"processing":["clean_water","well_siting"],"signals":["survey","food"],"base":0.035},
	"Stone":{"family":"Mineral","renewable":false,"recognition_year":0,"access":["labor"],"processing":["joinery"],"signals":["survey","construction"],"base":0.026},
	"Fertile Soil":{"family":"Land","renewable":true,"recognition_year":0,"access":["labor"],"processing":["seed_selection"],"signals":["food","nature"],"base":0.028},
	"Game":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["seasonal_patterns"],"signals":["food","exploration"],"base":0.030},
	"Fiber Plants":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["cordage"],"signals":["food","survey"],"base":0.024},
	"Clay":{"family":"Earth","renewable":false,"recognition_year":1,"access":["labor"],"processing":["clay_shaping"],"signals":["survey","materials"],"base":0.018},
	"Flint":{"family":"Mineral","renewable":false,"recognition_year":1,"access":["labor"],"processing":["controlled_flaking"],"signals":["survey","crafting"],"base":0.016},
	"Salt":{"family":"Mineral","renewable":false,"recognition_year":3,"access":["labor","logistics"],"processing":["food_drying"],"signals":["survey","food"],"base":0.010},
	"Medicinal Plants":{"family":"Organic","renewable":true,"recognition_year":2,"access":["labor"],"processing":["herbal_classification"],"signals":["health","nature"],"base":0.012},
	"Peat":{"family":"Fuel","renewable":true,"recognition_year":5,"access":["labor"],"processing":["charcoal"],"signals":["survey","materials"],"base":0.008},
	"Limestone":{"family":"Mineral","renewable":false,"recognition_year":8,"access":["route","tools"],"processing":["pit_firing"],"signals":["construction","materials"],"base":0.007},
	"Copper Ore":{"family":"Metal Ore","renewable":false,"recognition_year":12,"access":["route","tools","specialists"],"processing":["pit_firing","charcoal"],"signals":["materials","crafting"],"base":0.0045},
	"Tin Ore":{"family":"Metal Ore","renewable":false,"recognition_year":20,"access":["route","tools","specialists"],"processing":["pit_firing","charcoal"],"signals":["materials","trade"],"base":0.0030},
	"Lead Ore":{"family":"Metal Ore","renewable":false,"recognition_year":24,"access":["route","tools","specialists"],"processing":["pit_firing"],"signals":["materials","crafting"],"base":0.0030},
	"Bitumen":{"family":"Chemical","renewable":false,"recognition_year":18,"access":["route","containers"],"processing":["clay_shaping"],"signals":["survey","construction"],"base":0.0035},
	"Fine Sand":{"family":"Earth","renewable":true,"recognition_year":22,"access":["labor","containers"],"processing":["pit_firing"],"signals":["materials","nature"],"base":0.0040},
	"Iron Ore":{"family":"Metal Ore","renewable":false,"recognition_year":45,"access":["route","tools","specialists"],"processing":["pit_firing","charcoal"],"signals":["materials","warfare"],"base":0.0022},
	"Coal":{"family":"Fuel","renewable":false,"recognition_year":55,"access":["mine","ventilation","logistics"],"processing":["charcoal"],"signals":["materials","infrastructure"],"base":0.0018},
	"Sulfur":{"family":"Chemical","renewable":false,"recognition_year":65,"access":["mine","containers"],"processing":["pit_firing"],"signals":["materials","nature"],"base":0.0015},
	"Nitrates":{"family":"Chemical","renewable":true,"recognition_year":80,"access":["specialists","containers"],"processing":["tallies"],"signals":["nature","materials"],"base":0.0013},
	"Deep Aquifer":{"family":"Water","renewable":true,"recognition_year":85,"access":["well_siting","lifting","specialists"],"processing":["clean_water"],"signals":["infrastructure","nature"],"base":0.0015},
	"Refractory Clay":{"family":"Earth","renewable":false,"recognition_year":95,"access":["tools","specialists"],"processing":["pit_firing"],"signals":["materials","crafting"],"base":0.0012},
	"Phosphate Rock":{"family":"Mineral","renewable":false,"recognition_year":125,"access":["mine","specialists","logistics"],"processing":["standard_measures"],"signals":["sustenance","nature"],"base":0.0009},
	"Uranium Ore":{"family":"Metal Ore","renewable":false,"recognition_year":250,"access":["mine","specialists","logistics"],"processing":["atomic_physics","reactor_engineering"],"signals":["materials","knowledge"],"base":0.0006},
	"Graphite":{"family":"Mineral","renewable":false,"recognition_year":145,"access":["mine","specialists"],"processing":["standard_measures"],"signals":["materials","information"],"base":0.0008},
	"Silver Ore":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying","lead_smelting"],"signals":["materials","trade"],"base":0.0012},
	"Gold Ore":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying"],"signals":["materials","trade"],"base":0.0007},
	"Crude Oil":{"family":"Fuel","renewable":false,"recognition_year":0,"access":["mine","containers","logistics"],"processing":["chemical_distillation"],"signals":["materials","infrastructure"],"base":0.0007},
	"Nickel Ore":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying","nickel_metal_recovery"],"signals":["materials","crafting"],"base":0.0010},
	"Bauxite":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying","alumina_refining"],"signals":["materials","crafting"],"base":0.0012},
	"Rutile Ore":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying","industrial_catalyst_design"],"signals":["materials","crafting"],"base":0.0010},
	"Ochre Earth":{"family":"Earth","renewable":false,"recognition_year":0,"access":["labor","containers"],"processing":["mineral_pigment_preparation"],"signals":["materials","survey"],"base":0.006},
	"Zinc Ore":{"family":"Metal Ore","renewable":false,"recognition_year":0,"access":["mine","specialists","logistics"],"processing":["ore_assaying","cementation_brass"],"signals":["materials","crafting"],"base":0.0014},
	"Kaolin":{"family":"Earth","renewable":false,"recognition_year":0,"access":["labor","tools"],"processing":["clay_testing","kaolin_porcelain"],"signals":["materials","crafting"],"base":0.0020}
}

func initialize() -> void:
	if initialized:
		return
	rng.seed = WorldSimulation.state.world_seed ^ 0x4f1bbcdc
	initialized = true
	var focus_start:Dictionary=WorldSimulation.state.founding_focus_definition().get("starting",{})
	var food_days:=30.0*(1.0+float(focus_start.get("food_days_ratio",0.0)))
	var material_ratio:=1.0+float(focus_start.get("starting_materials",0.0))
	if WorldSimulation.state.founding_manifest.is_empty():
		WorldSimulation.state.founding_manifest={"portable_shelters":30,"food_storage_rations":WorldSimulation.state.population_exact*maxf(30.0,food_days),"dry_storage_bulk":10.0,"covered_storage_bulk":4.0,"sealed_storage_bulk":1.0,"secure_storage_bulk":1.0,"water_vessel_days":3.0}
	if WorldSimulation.state.resource_stockpiles.is_empty():
		# The convoy arrives with three days in portable vessels, not an abstract
		# permanent water supply.  Continued survival requires a reachable source.
		WorldSimulation.state.resource_stockpiles = {"Food":WorldSimulation.state.population_exact*food_days, "Freshwater":WorldSimulation.state.population_exact*3.0, "Timber":12.0*material_ratio, "Stone":0.0, "Clay":0.0, "Fiber Plants":10.0*material_ratio}
		if WorldSimulation.state.elapsed_days<=0:
			WorldSimulation.state.resource_stockpiles.merge(preload("res://scripts/founding_knowledge.gd").portable_supplies(WorldSimulation.state.population_exact),true)

func register_local_occurrences(sites: Array[Dictionary], terrain: String, environment_profile:Dictionary={}) -> void:
	initialize()
	var has_unscoped_saved_deposits:=false
	for existing_variant in WorldSimulation.state.resource_deposits:
		var existing_scope:=String((existing_variant as Dictionary).get("origin_scope",""))
		if existing_scope=="founding_region": return
		if existing_scope=="": has_unscoped_saved_deposits=true
	# Older saves predate geographic provenance. Their non-empty deposit ledger is
	# authoritative; never duplicate it merely because it lacks the new scope field.
	if has_unscoped_saved_deposits: return
	var profile:=environment_profile
	if profile.is_empty():
		var position:=Vector2.ZERO
		if not sites.is_empty():
			var first_position:Vector3=sites[0].get("position",Vector3.ZERO)
			position=Vector2(first_position.x,first_position.z)
		profile=PlanetEnvironment.profile_at(position)
	var potentials:Dictionary=profile.get("resource_potentials",{})
	for i in sites.size():
		var site := sites[i]
		var resource_name: String = site.type
		if resource_name == "Fertile": resource_name = "Fertile Soil"
		var potential:=clampf(float(site.get("potential",potentials.get(resource_name,0.50))),0.0,1.0)
		var quality := clampf(0.42+potential*0.86+rng.randf_range(-0.12,0.12),0.25,1.50)
		var amount := rng.randf_range(520.0,2400.0)*(0.50+potential*1.35)
		var deposit:=_deposit(resource_name,site.position,quality,amount,WorldSimulation.state.resource_deposits.size(),"founding_region",potential,String(profile.get("signature","")))
		# Founders do not arrive unable to identify trees, exposed stone, game, or
		# usable soil.  A feature inside their actually charted starting ground is
		# recognized by kind; survey is still required to learn quality, extent,
		# access, and sustainable output.  Nothing beyond the fog is leaked.
		if bool(site.get("initially_observed",false)):
			_seed_founding_surface_recognition(deposit)
		WorldSimulation.state.resource_deposits.append(deposit)
	# Buried and less obvious occurrences follow geology and climate rather than a
	# universal province label. They remain unknown until the civilization can
	# recognize their signals.
	for resource_variant in catalog.keys():
		var resource_name:=String(resource_variant)
		if resource_name in FOUNDING_SURFACE_RESOURCES or resource_name=="Freshwater": continue
		var potential:=clampf(float(potentials.get(resource_name,0.0)),0.0,1.0)
		if potential<0.14 or rng.randf()>0.08+potential*0.58: continue
		var anchor:Vector3=sites[rng.randi_range(0,sites.size()-1)].get("position",Vector3.ZERO) if not sites.is_empty() else Vector3.ZERO
		var position:=anchor+Vector3(rng.randf_range(-5.0,5.0),0.0,rng.randf_range(-5.0,5.0))
		WorldSimulation.state.resource_deposits.append(_deposit(resource_name,position,rng.randf_range(0.38,0.82)+potential*0.58,rng.randf_range(700.0,8500.0)*(0.45+potential),WorldSimulation.state.resource_deposits.size(),"founding_region",potential,String(profile.get("signature",""))))


func register_settlement_occurrences(settlement_id:String,sites:Array[Dictionary],environment_profile:Dictionary)->void:
	initialize()
	# Older saves kept satellite occurrences in the primary ledger. Terrain moves
	# those physical records into their owner before new generation is permitted.
	var city:=WorldSimulation.settlements.settlement_record(settlement_id)
	if not city.is_empty() and not bool(city.get("primary",false)):
		for deposit in WorldSimulation.state.resource_deposits:
			if String(deposit.get("source_settlement_id",""))==settlement_id: return
	WorldSimulation.settlements.with_city_resources(settlement_id,func()->void: _register_local_occurrences(settlement_id,sites,environment_profile))

func _register_local_occurrences(settlement_id:String,sites:Array[Dictionary],environment_profile:Dictionary)->void:
	initialize()
	if settlement_id=="": return
	for existing_variant in WorldSimulation.state.resource_deposits:
		if String((existing_variant as Dictionary).get("source_settlement_id",""))==settlement_id: return
	var potentials:Dictionary=environment_profile.get("resource_potentials",{})
	var local_rng:=RandomNumberGenerator.new()
	local_rng.seed=hash("%d:%s:deposits" % [WorldSimulation.state.world_seed,settlement_id])
	var added:=0
	for site_variant in sites:
		var site:Dictionary=site_variant
		var resource_name:=String(site.get("type",""))
		if resource_name=="" or resource_name=="Freshwater" or not catalog.has(resource_name): continue
		var potential:=clampf(float(site.get("potential",potentials.get(resource_name,0.0))),0.0,1.0)
		var surface:=resource_name in FOUNDING_SURFACE_RESOURCES
		var chance:=(0.20 if surface else 0.06)+potential*(0.66 if surface else 0.58)
		if potential<0.16 or local_rng.randf()>chance: continue
		var quality:=clampf(0.34+potential*0.92+local_rng.randf_range(-0.10,0.12),0.22,1.50)
		var amount:=local_rng.randf_range(520.0,7600.0)*(0.42+potential)
		var deposit:=_deposit(resource_name,site.get("position",Vector3.ZERO),quality,amount,WorldSimulation.state.resource_deposits.size(),settlement_id,potential,String(environment_profile.get("signature","")))
		deposit["source_settlement_id"]=settlement_id
		if bool(site.get("initially_observed",false)) and surface: _seed_founding_surface_recognition(deposit)
		WorldSimulation.state.resource_deposits.append(deposit)
		added+=1
		if added>=12: break

func _deposit(resource_name: String, position: Vector3, quality: float, amount: float, index: int,origin_scope:String="",environment_potential:float=0.5,environment_signature:String="") -> Dictionary:
	# Exposed surface water is directly observable; a deep aquifer remains hidden.
	var initial_stage:="surveyed" if resource_name=="Freshwater" else "unknown"
	return {"id":"%s_%d" % [resource_name.to_snake_case(), index], "resource":resource_name, "position":position, "quality":quality, "remaining":amount, "initial_amount":amount, "stage":initial_stage, "clues":1.0 if initial_stage=="surveyed" else 0.0, "survey":1.0 if initial_stage=="surveyed" else 0.0, "access":0.0, "blockers":[], "development":0.0, "route":0.0, "workers":0,"daily_yield":0.0,"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Access not organized","last_reported_bottleneck":"","origin_scope":origin_scope,"environment_potential":environment_potential,"environment_signature":environment_signature,"source_settlement_id":""}

func register_expedition_occurrence(resource_name:String,position:Vector2,profile:Dictionary)->Dictionary:
	if not catalog.has(resource_name) or not recognition_ready(resource_name):return {}
	if WorldSimulation.enabled:return preload("res://scripts/civilization_resources.gd").survey_occurrence(resource_name,position)
	for existing_variant in WorldSimulation.state.resource_deposits:
		var existing:Dictionary=existing_variant
		var location:Vector3=existing.get("position",Vector3.ZERO)
		if String(existing.get("resource",""))==resource_name and Vector2(location.x,location.z).distance_to(position)<24.0:return {}
	var potential:=clampf(float(profile.get("resource_potentials",{}).get(resource_name,0.0)),0.0,1.0)
	if potential<.38:return {}
	var local_rng:=RandomNumberGenerator.new();local_rng.seed=hash("%s:%s:%s:prospect" % [WorldSimulation.state.world_seed,resource_name,position.round()])
	var deposit:=_deposit(resource_name,Vector3(position.x,0.0,position.y),clampf(.42+potential*.78+local_rng.randf_range(-.08,.08),.25,1.4),local_rng.randf_range(900.0,9000.0)*(.45+potential),WorldSimulation.state.resource_deposits.size(),"expedition",potential,String(profile.get("signature","")))
	deposit["stage"]="surveyed";deposit["clues"]=1.0;deposit["survey"]=1.0
	WorldSimulation.state.resource_deposits.append(deposit)
	return deposit


func _seed_founding_surface_recognition(deposit:Dictionary)->void:
	var resource_name:=String(deposit.get("resource",""))
	if resource_name=="Freshwater":
		deposit["stage"]="surveyed"
		deposit["clues"]=1.0
		deposit["survey"]=1.0
	elif resource_name in FOUNDING_SURFACE_RESOURCES:
		deposit["stage"]="recognized"
		deposit["clues"]=1.0
		deposit["survey"]=0.0

func _terrain_occurrences(terrain: String) -> Array[String]:
	var common: Array[String] = ["Clay", "Flint", "Medicinal Plants", "Limestone", "Fine Sand"]
	if terrain == "Mountains" or terrain == "Hills": common.append_array(["Copper Ore", "Tin Ore", "Lead Ore", "Iron Ore", "Coal", "Graphite"])
	if terrain == "Marsh": common.append_array(["Peat", "Nitrates"])
	if terrain == "Plains": common.append_array(["Salt", "Phosphate Rock", "Deep Aquifer"])
	return common

func process_day(context: Dictionary) -> Array[Dictionary]:
	return WorldSimulation.settlements.with_local_population(func()->Array[Dictionary]: return _process_local_day(context))

func _process_local_day(context: Dictionary) -> Array[Dictionary]:
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	initialize()
	if WorldSimulation.enabled:
		var origin:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
		preload("res://scripts/civilization_resources.gd").initialize(Vector2(origin.x,origin.z))
	var events: Array[Dictionary] = []
	stamp=trace.mark("resource_initialize",stamp)
	var method_factors:Dictionary=preload("res://scripts/geoscience_knowledge.gd").factors()
	# Filled only if this city still has an eligible recognition/survey task.
	# Family practice changes during the pass and remains evaluated per deposit.
	var survey_inputs:Dictionary={}
	var access_inputs:Dictionary={}
	# Known discoveries do not change inside this pass.
	var recognizable:Dictionary={}
	# Family literacy changes only when this pass records practice; the memo is
	# cleared at each such point.
	var literacy:Dictionary={}
	for deposit in WorldSimulation.state.resource_deposits:
		_ensure_deposit_fields(deposit)
		var resource_name: String = deposit.resource
		if not catalog.has(resource_name):
			continue
		var definition: Dictionary = catalog[resource_name]
		if deposit.stage == "unknown":
			if not recognizable.has(resource_name):recognizable[resource_name]=recognition_ready(resource_name)
			if not recognizable[resource_name]:continue
			if survey_inputs.is_empty():survey_inputs=_local_survey_inputs()
			var survey_effort := float(survey_inputs.effort) * float(method_factors.get(resource_name,{}).get("recognition",1.0))
			deposit.clues += definition.base * (0.5 + survey_effort + float(survey_inputs.nature) + float(survey_inputs.material)) * _memo_literacy(resource_name,literacy) * rng.randf_range(0.5, 1.5) * WorldSimulation.span
			if deposit.clues >= 1.0:
				deposit.stage = "recognized"
				_gain_practice(resource_name,"recognition",0.12)
				literacy.clear()
				events.append(_event("Resource Indicated", "Evidence suggests %s is present. Its extent and accessibility remain unknown." % resource_name, deposit.id))
		elif deposit.stage == "recognized":
			if survey_inputs.is_empty():survey_inputs=_local_survey_inputs()
			var survey_effort := float(survey_inputs.effort) * float(method_factors.get(resource_name,{}).get("survey",1.0))
			deposit.survey += definition.base * 0.55 * survey_effort * float(survey_inputs.speed) * _memo_literacy(resource_name,literacy) * rng.randf_range(0.7,1.3) * WorldSimulation.span
			if deposit.survey >= 1.0:
				deposit.stage = "surveyed"
				_gain_practice(resource_name,"survey",0.18)
				literacy.clear()
				events.append(_event("Deposit Surveyed", "The extent and conditions of the %s occurrence are now understood." % resource_name, deposit.id))
		elif deposit.stage == "surveyed":
			if access_inputs.is_empty():access_inputs=_access_work_inputs()
			deposit.access = _calculate_access(deposit, definition, context, access_inputs)
			deposit.blockers = _access_blockers(deposit,definition,context)
			if deposit.access<1.0 and deposit.blockers.is_empty():
				deposit.blockers.append(_access_practice_blocker(definition))
			if deposit.access >= 1.0 and deposit.blockers.is_empty():
				deposit.stage = "accessible"
				events.append(_event("Resource Accessible", "%s can now support organized extraction." % resource_name, deposit.id))
	stamp=trace.mark("resource_deposits",stamp)
	# The searched land moves and a new month rolls for a find, before the
	# cutters and diggers work it.
	_advance_land(context)
	var flow_events:=_process_material_flow(context)
	events.append_array(flow_events)
	stamp=trace.mark("resource_material_flow",stamp)
	events.append_array(_process_water_flow(context))
	trace.mark("resource_water",stamp)
	for event in events:
		WorldSimulation.state.resource_events.push_front(event)
	if WorldSimulation.state.resource_events.size()>120: WorldSimulation.state.resource_events.resize(120)
	return events

func _process_water_flow(context:Dictionary={})->Array[Dictionary]:
	var events:Array[Dictionary]=[]
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var drinking_required:=population
	var wound_cleaning_required:=0.0
	if "wound_cleaning" in WorldSimulation.state.known_discoveries:
		wound_cleaning_required=population*.015*WorldSimulation.discovery.adoption("wound_cleaning")
	var clean_water_required:=0.0
	if "clean_water" in WorldSimulation.state.known_discoveries:
		clean_water_required=population*.05*WorldSimulation.discovery.adoption("clean_water")
	var practice_required:=wound_cleaning_required+clean_water_required
	var total_required:=drinking_required+practice_required
	# The one source search (site_water): the same rule judges a new town's site.
	var source:=site_water(context,WorldSimulation.state.resource_deposits,true)
	var accessible_quality:=float(source.quality)
	var nearest_source_km:=float(source.distance_km)
	var source_kind:=String(source.kind)
	var source_id:=String(source.id)
	var source_origin:=String(source.origin)
	var carriers:=WorldSimulation.state.effective_workers("Logistics")
	var food_workers:=WorldSimulation.state.effective_workers("Food")
	# Water fetching is basic household subsistence, not a specialist occupation
	# that vanishes when the player changes a labor slider. People beside exposed
	# surface water can meet their immediate drinking need themselves; assigned
	# Food and Logistics workers create the organized surplus and carry from more
	# distant sources. Sanitation, irrigation, storage and dense urban distribution
	# still depend on knowledge and infrastructure elsewhere in the simulation.
	var collection_workers:=carriers+food_workers*0.22
	# Wells, cisterns, channels and pipes (research: water access) bring the
	# water nearer: the walk counts shorter than the ground (research_mechanics.gd).
	var walk_km:float=nearest_source_km*preload("res://scripts/research_mechanics.gd").water_walk_factor() if nearest_source_km<INF else INF
	var distance_factor:=1.0/maxf(1.0,1.0+walk_km*0.16) if walk_km<INF else 0.0
	var household_access_ratio:=_household_surface_water_access_ratio(walk_km) if accessible_quality>0.0 else 0.0
	var household_collection:=total_required*household_access_ratio
	var organized_collection:=collection_workers*28.0*clampf(float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)*distance_factor*(1.0+clampf(WorldSimulation.discovery.effect("haul_capacity"),-0.4,1.5))
	organized_collection*=1.0+maxf(0.0,WorldSimulation.consequences.policy_effect("water_collection"))
	var collection_capacity:=household_collection+organized_collection
	var flow_factor:=clampf(0.75+accessible_quality*0.25,0.0,1.08)
	var collected:=minf(total_required*1.35,collection_capacity)*flow_factor if accessible_quality>0.0 else 0.0
	var conveyed:=preload("res://scripts/water_conveyance.gd").delivery(context,int(WorldSimulation.state.elapsed_days),maxf(0.0,total_required*1.35-household_collection*flow_factor))
	var works:Dictionary=preload("res://scripts/water_waste_works.gd").advance(context,int(WorldSimulation.state.elapsed_days),total_required)
	var rain_collected:=maxf(0.0,float(works.get("rain_collected",0.0)))
	collected=minf(total_required*1.35+float(works.get("cistern_capacity",0.0)),collected+conveyed+rain_collected)
	var portable_days:=float(WorldSimulation.state.founding_manifest.get("water_vessel_days",3.0))
	portable_days+=maxf(0.0,WorldSimulation.consequences.policy_effect("water_storage"))
	if "Storage Pits" in WorldSimulation.state.settlement_completed: portable_days+=2.0
	if "Open Work Area" in WorldSimulation.state.settlement_completed: portable_days+=1.0+WorldSimulation.discovery.effect("container_capacity")*2.0
	var capacity:=population*portable_days+maxf(0.0,float(works.get("cistern_capacity",0.0)))
	capacity+=preload("res://scripts/undertaking_rewards.gd").local_bonus(WorldSimulation.state,"water_capacity")
	var stored_before:=maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get("Freshwater",0.0)))
	var available:=minf(capacity,stored_before+collected)
	var drinking_consumed:=minf(drinking_required,available)
	var remaining:=maxf(0.0,available-drinking_consumed)
	var wound_cleaning_used:=minf(wound_cleaning_required,remaining)
	remaining=maxf(0.0,remaining-wound_cleaning_used)
	var clean_water_used:=minf(clean_water_required,remaining)
	var consumed:=drinking_consumed+wound_cleaning_used+clean_water_used
	var stored:=maxf(0.0,available-consumed)
	WorldSimulation.state.resource_stockpiles["Freshwater"]=stored
	var intake:=clampf(drinking_consumed/maxf(0.01,drinking_required),0.0,1.0)
	var wound_cleaning_coverage:=clampf(wound_cleaning_used/maxf(.000001,wound_cleaning_required),0.0,1.0) if wound_cleaning_required>.000001 else 0.0
	var clean_water_coverage:=clampf(clean_water_used/maxf(.000001,clean_water_required),0.0,1.0) if clean_water_required>.000001 else 0.0
	WorldSimulation.state.water_metrics={"stored":stored,"capacity":capacity,"collected_today":collected,"conveyed_today":conveyed,"rain_collected_today":rain_collected,"cistern_capacity":float(works.get("cistern_capacity",0.0)),"household_collected_today":minf(collected,household_collection*flow_factor),"organized_collection_capacity":organized_collection*flow_factor,"required_today":drinking_required,"practice_required_today":practice_required,"total_required_today":total_required,"consumed_today":consumed,"drinking_consumed_today":drinking_consumed,"wound_cleaning_water_used":wound_cleaning_used,"clean_water_water_used":clean_water_used,"wound_cleaning_coverage":wound_cleaning_coverage,"clean_water_coverage":clean_water_coverage,"intake_ratio":intake,"days":stored/maxf(0.01,drinking_required),"source_accessible":accessible_quality>0.0,"source_distance_km":nearest_source_km if nearest_source_km<INF else -1.0,"source_kind":source_kind,"source_id":source_id,"source_origin":source_origin,"recognized":accessible_quality>0.0,"renewable":accessible_quality>0.0,"supports_drinking":accessible_quality>0.0,"supports_food_gathering":accessible_quality>0.0,"collection_workers":collection_workers}
	WorldSimulation.state.water_history.append({"day":int(WorldSimulation.state.elapsed_days),"stored":stored,"collected":collected,"household_collected":minf(collected,household_collection*flow_factor),"required":drinking_required,"practice_required":practice_required,"consumed":consumed,"drinking_consumed":drinking_consumed,"wound_cleaning_coverage":wound_cleaning_coverage,"clean_water_coverage":clean_water_coverage,"intake_ratio":intake,"source_distance_km":nearest_source_km if nearest_source_km<INF else -1.0,"source_id":source_id,"source_origin":source_origin})
	if WorldSimulation.state.water_history.size()>370: WorldSimulation.state.water_history.pop_front()
	# ConsequenceEngine runs after resource flow, so rebuild the society totals now
	# using today's physical service coverage.
	WorldSimulation.discovery.refresh_operating_effects()
	if intake<0.98:
		var remedy:="The source is present; shorten the carry or increase organized collection and distribution." if accessible_quality>0.0 else "Secure a recognized freshwater source."
		events.append(_event("Water Shortfall","Only %d%% of today's drinking-water requirement was met. %s" % [roundi(intake*100.0),remedy],"Freshwater"))
	return events


func _household_surface_water_access_ratio(distance_km:float)->float:
	## Immediate drinking water is self-provisioned at household scale. Adjacent
	## riverbanks provide a modest refill surplus; the floor falls away with the
	## physical carry so a six-kilometre source still needs organized labor.
	if distance_km<0.0 or distance_km==INF or distance_km>DRINKING_REACH_KM: return 0.0
	if distance_km<=1.0: return 1.18
	return lerpf(1.18,0.38,clampf((distance_km-1.0)/5.0,0.0,1.0))


## How far people walk for their daily drinking water (the 6 km collection limit).
const DRINKING_REACH_KM:=6.0

## Where a place drinks: the one reading of a place's water. Every town's day
## (_process_water_flow) and every test of a new town's site (the leaders'
## council, the court, the settle order, a wandering people's camp) use it.
## A mapped river or drainage within 6 km of the place counts (the same
## hydrology as the map), and so do the freshwater sources the people living
## at that place have found: surveyed within 6 km, or organized at any
## distance. A new site has found nothing yet, so it is judged by the map's
## water alone, never by the capital's ledger. `record` writes each source's
## distance on the people's own records (their town's own day only).
## {accessible, distance_km (INF when none), kind, id, origin, quality,
## household_share: 0..1, the share of the drinking the families fetch
## themselves at that carry (1 beside the water, 0 beyond reach)}.
func site_water(context:Dictionary,deposits:Array=[],record:bool=false)->Dictionary:
	var origin:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
	var here:=Vector2(origin.x,origin.z)
	var found:={"accessible":false,"distance_km":INF,"kind":"none","id":"","origin":"none","quality":0.0}
	for deposit_variant in deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))!="Freshwater": continue
		var stage:=String(deposit.get("stage","unknown"))
		if stage not in ["surveyed","accessible","developed"]: continue
		var position:Vector3=deposit.get("position",Vector3.ZERO)
		var distance_km:=here.distance_to(Vector2(position.x,position.z))
		if record: deposit["distance_km"]=distance_km
		# Surveyed exposed water is already a collectable geographic feature. Formal
		# access work improves organization; it is not a prerequisite for drinking.
		if (stage in ["accessible","developed"] or distance_km<=DRINKING_REACH_KM) and distance_km<float(found.distance_km):
			found={"distance_km":distance_km,"quality":float(deposit.get("quality",0.85)),
				"kind":"surveyed surface water" if stage=="surveyed" else "organized water source",
				"id":String(deposit.get("id","freshwater_occurrence")),"origin":"recognized_occurrence"}
	var hydrology_distance:=float(context.get("surface_water_distance_km",INF))
	if hydrology_distance<=DRINKING_REACH_KM and hydrology_distance<float(found.distance_km):
		found={"distance_km":hydrology_distance,"quality":1.0,
			"kind":String(context.get("surface_water_kind","visible river or drainage")),
			"id":String(context.get("surface_water_id","local_surface_hydrology")),"origin":"mapped_hydrology"}
	found["accessible"]=float(found.quality)>0.0
	# Wells and channels shorten the walk (research_mechanics.water_walk_factor),
	# exactly as the town's day counts it.
	var walk_km:float=float(found.distance_km)*preload("res://scripts/research_mechanics.gd").water_walk_factor() if bool(found.accessible) else INF
	found["household_share"]=clampf(_household_surface_water_access_ratio(walk_km)/_household_surface_water_access_ratio(0.0),0.0,1.0)
	return found


# Hydrology is a geographic source, not a fabricated point deposit. This fixed-
# shape snapshot lets map/resource views highlight the actual recognized river
# or drainage that supplies drinking, fishing, and sanitation work.
# It shows the town in scope its OWN water ledger. It never judges another
# place: a site for a new town is judged by site_water (the capital's ledger
# once stood in for every candidate site and sent settlers to dry ground).
func water_access_snapshot(context:Dictionary={})->Dictionary:
	var water:Dictionary=WorldSimulation.state.water_metrics
	var accessible:=bool(water.get("source_accessible",false))
	var recognized:=bool(water.get("recognized",accessible))
	var source_id:=String(water.get("source_id",""))
	var source_kind:=String(water.get("source_kind","none"))
	var source_origin:=String(water.get("source_origin","none"))
	var distance_km:=float(water.get("source_distance_km",-1.0))
	# The map exists before the first simulation tick. If actual authored
	# hydrology lies inside the charted founding range, expose it immediately as
	# recognized geography even though no day's collection ledger exists yet.
	# This is deliberately not a fabricated point deposit or free stored water.
	var mapped_distance:=float(context.get("surface_water_distance_km",INF))
	var mapped_recognized:=bool(context.get("surface_water_recognized",mapped_distance<INF and mapped_distance<=72.0))
	if mapped_recognized and (not recognized or distance_km<0.0 or mapped_distance<distance_km):
		recognized=true
		accessible=mapped_distance<=6.0
		distance_km=mapped_distance
		source_id=String(context.get("surface_water_id","local_surface_hydrology"))
		source_kind=String(context.get("surface_water_kind","visible river or drainage"))
		source_origin="mapped_hydrology"
	return {
		"accessible":accessible,"recognized":recognized,
		"source_id":source_id,"source_kind":source_kind,
		"source_origin":source_origin,"distance_km":distance_km,
		"renewable":bool(water.get("renewable",accessible)),"supports_drinking":bool(water.get("supports_drinking",accessible)),
		"supports_food_gathering":bool(water.get("supports_food_gathering",accessible)),
		"collection_workers":float(water.get("collection_workers",0.0)),"collected_today":float(water.get("collected_today",0.0)),
		"required_today":float(water.get("required_today",0.0)),"intake_ratio":float(water.get("intake_ratio",0.0)),
		"bounded":true
	}

func _access_work_inputs()->Dictionary:
	# Invariant during one local resource pass; never retained across city scopes.
	return {"logistics":WorldSimulation.state.effective_workers("Logistics")/5.0,"construction":WorldSimulation.state.effective_workers("Construction")/8.0,"knowledge":1.0+WorldSimulation.discovery.effect("route_speed")+WorldSimulation.discovery.effect("mine_safety")*.5}

func _calculate_access(deposit: Dictionary, definition: Dictionary, context: Dictionary,work:Dictionary={}) -> float:
	if String(deposit.get("resource",""))=="Freshwater":
		# Carrying from exposed surface water needs assigned hands, not years of
		# roadbuilding or advanced hydrological practice.
		return 1.0 if int(WorldSimulation.state.population_allocations.get("Extraction",0))>0 and int(WorldSimulation.state.population_allocations.get("Logistics",0))>0 else 0.0
	if work.is_empty():work=_access_work_inputs()
	var logistics:float=work.logistics
	var construction:float=work.construction
	var tools := float(context.get("tools", 0.25))
	var knowledge := 0.0
	for requirement in definition.processing:
		if requirement in WorldSimulation.state.known_discoveries:
			knowledge += 0.3*WorldSimulation.discovery.adoption(String(requirement))
	var access_knowledge:float=work.knowledge
	deposit.route = minf(1.0, deposit.route + 0.002 * construction * logistics*float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72))*access_knowledge)
	return deposit.route * 0.45 + tools * 0.25 + knowledge + 0.15+minf(0.18,_practice(resource_name_from(deposit),"survey")*0.04)

func _access_blockers(deposit: Dictionary, definition: Dictionary, context: Dictionary) -> Array[String]:
	var blockers: Array[String] = []
	for requirement in definition.access:
		if requirement == "labor" and int(WorldSimulation.state.population_allocations.get("Extraction",0)) <= 0:
			blockers.append("no extraction labor assigned")
		elif requirement == "logistics" and int(WorldSimulation.state.population_allocations.get("Logistics",0)) < 4:
			blockers.append("insufficient logistics capacity")
		elif requirement == "route" and float(deposit.route) < 0.65:
			blockers.append("no usable access route")
		elif requirement == "tools" and float(context.get("tools",0.25)) < 0.5:
			blockers.append("tools are inadequate")
		elif requirement == "specialists" and int(WorldSimulation.state.population_allocations.get("Knowledge",0)) < 5:
			blockers.append("specialist knowledge is unavailable")
		elif requirement == "mine" and (float(deposit.route) < 0.8 or int(WorldSimulation.state.population_allocations.get("Construction",0)) < 10):
			blockers.append("mining works have not been developed")
		elif requirement == "ventilation" and "mine_airways" not in WorldSimulation.state.known_discoveries:
			blockers.append("safe underground ventilation is unknown")
		elif requirement == "containers" and "clay_shaping" not in WorldSimulation.state.known_discoveries:
			blockers.append("suitable containers are unavailable")
		elif requirement == "well_siting" and "well_siting" not in WorldSimulation.state.known_discoveries:
			blockers.append("deep-water siting is not understood")
		elif requirement == "lifting" and "mine_drainage" not in WorldSimulation.state.known_discoveries:
			blockers.append("deep lifting machinery is unavailable")
	return blockers

func _access_practice_blocker(definition:Dictionary)->String:
	var missing:Array[String]=[]
	var developing:Array[String]=[]
	for requirement_variant in definition.get("processing",[]):
		var requirement:=String(requirement_variant)
		var label:=requirement.replace("_"," ").capitalize()
		if requirement not in WorldSimulation.state.known_discoveries:missing.append(label)
		elif WorldSimulation.discovery.adoption(requirement)<0.95:developing.append(label)
	if not missing.is_empty():return "Access practice needed: %s" % " or ".join(missing)
	if not developing.is_empty():return "Access practice is still spreading: %s" % " or ".join(developing)
	return "Access work is incomplete"

func _ensure_woodland_supply(context:Dictionary)->void:
	_ensure_surface_supply("Timber",context.get("woodland_catchment",{}),context,"woodland_catchment",600.0)

func _ensure_surface_material_supplies(context:Dictionary)->void:
	var fields:Dictionary=context.get("surface_material_catchments",{})
	_ensure_surface_supply("Stone",fields.get("Stone",{}),context,"surface_stone_catchment",1000.0)
	_ensure_surface_supply("Fiber Plants",fields.get("Fiber Plants",{}),context,"plant_fiber_catchment",180.0)

func _ensure_surface_supply(resource:String,field:Dictionary,context:Dictionary,source:String,stock_per_km2:float)->void:
	# Surface cover is directly usable. Survey refines knowledge; it does not
	# make familiar trees, loose stone or fibrous vegetation appear from nothing.
	if field.is_empty() or not bool(context.get("settled",false)): return
	var density:=clampf(float(field.get("density",0.0)),0.0,1.0)
	var minimum_density:=0.03 if resource=="Stone" else 0.08
	var existing_fronts:Array[Dictionary]=[]
	for deposit in WorldSimulation.state.resource_deposits:
		if String(deposit.get("landscape_source",""))!=source:continue
		existing_fronts.append(deposit)
		if float(deposit.get("remaining",0.0))>0.001:
			# Founding surveys already create these exposed surface fronts. They
			# need the same access transition as newly created fronts, not mining.
			deposit.stage="developed" if String(deposit.stage)=="developed" else "accessible"
			deposit.clues=1.0;deposit.access=1.0;deposit.blockers=[]
			# A trickle of regrowth is not a working supply. Keep the depleted
			# front and its recovery, but seek another real front when its reserve
			# is below the same working threshold used by extraction allocation.
			if float(deposit.remaining)>=maxf(1.0,float(deposit.get("initial_amount",1.0))*.05):return
	if existing_fronts.size()>=MAX_SURFACE_FRONTS_PER_RESOURCE:return
	if not existing_fronts.is_empty() or density<minimum_density:
		field=_next_surface_front(resource,source,context,minimum_density)
		if field.is_empty():return
		density=clampf(float(field.get("density",0.0)),0.0,1.0)
	var position:Vector3=field.get("position",context.get("origin",WorldSimulation.state.settlement_founded_at))
	var supply:Dictionary={}
	# Adopt an older nearby point record once before opening a new working front.
	# This preserves its inventory, shipments and save identity.
	if existing_fronts.is_empty():
		for deposit in WorldSimulation.state.resource_deposits:
			if String(deposit.get("resource",""))==resource and String(deposit.get("landscape_source",""))=="" and (deposit.position as Vector3).distance_to(position)<=2.5:
				supply=deposit
				break
	if WorldSimulation.enabled:
		if supply.is_empty():
			supply=preload("res://scripts/civilization_resources.gd").surface(resource,source,field,stock_per_km2)
			WorldSimulation.state.resource_deposits.append(supply)
	if supply.is_empty():
		for deposit in WorldSimulation.state.resource_deposits:
			if String(deposit.get("resource",""))==resource and (deposit.position as Vector3).distance_to(position)<=2.5:
				supply=deposit
				break
	if supply.is_empty():
		supply=_deposit(resource,position,0.45+density*0.65,maxf(1.0,float(field.get("area_km2",9.0)))*density*stock_per_km2,WorldSimulation.state.resource_deposits.size(),"local_surface",density)
		WorldSimulation.state.resource_deposits.append(supply)
	supply["landscape_source"]=source
	supply["area_km2"]=float(field.get("area_km2",9.0))
	supply["surface_density"]=density
	if resource=="Timber": supply["woodland_density"]=density
	supply["stage"]="accessible" if String(supply.stage)!="developed" else "developed"
	supply["clues"]=1.0
	supply["access"]=1.0
	supply["blockers"]=[]

## How many rings of new ground (SURFACE_FRONT_SPACING_KM apart) the people
## search for new timber, stone and fibre once the fronts they work run low:
## one more ring for every 6 carriers at work (_next_surface_front).
func surface_search_rings()->int:
	return clampi(1+int(WorldSimulation.state.effective_workers("Logistics")/SURFACE_SEARCH_CARRIERS),1,MAX_SURFACE_FRONT_RING)


## The people's wood, for the screens and the court: {timber in store,
## stands_known, stands_working (a working reserve left), reach_km (how far
## the carriers look for new woods), next_km and carriers_for_next (the
## carriers on the roll, at today's share still working, who would look one
## ring farther; 0 at the farthest ring)}.
func woodland_outlook()->Dictionary:
	var known:=0;var working:=0
	for deposit_variant in WorldSimulation.state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))!="Timber":continue
		known+=1
		if float(deposit.get("remaining",0.0))>=maxf(1.0,float(deposit.get("initial_amount",1.0))*.05):working+=1
	var rings:=surface_search_rings()
	var raw:=float(WorldSimulation.state.population_allocations.get("Logistics",0))
	var at_work:=WorldSimulation.state.effective_workers("Logistics")
	var share:=at_work/raw if raw>0.0 else 1.0
	var next:=0
	if rings<MAX_SURFACE_FRONT_RING:next=ceili(SURFACE_SEARCH_CARRIERS*float(rings)/maxf(0.05,share)-0.0001)
	return {"timber":float(WorldSimulation.state.resource_stockpiles.get("Timber",0.0)),"stands_known":known,"stands_working":working,
		"reach_km":SURFACE_FRONT_SPACING_KM*rings,"next_km":SURFACE_FRONT_SPACING_KM*(rings+1) if next>0 else 0.0,"carriers_for_next":next}


func _next_surface_front(resource:String,source:String,context:Dictionary,minimum_density:float)->Dictionary:
	if not WorldSimulation.context_provider.is_valid():return {}
	var used:Dictionary={}
	for deposit_variant in WorldSimulation.state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("landscape_source",""))!=source:continue
		used[_surface_front_key(resource,deposit)]=true
	var origin_value:Variant=context.get("origin",WorldSimulation.state.settlement_founded_at)
	var origin:=Vector2(origin_value.x,origin_value.z) if origin_value is Vector3 else Vector2(origin_value.x,origin_value.y)
	var max_ring:=surface_search_rings()
	# Only the authored-terrain provider promises stable catchment potential.
	# Cache failed searches too; a desert should not be resurveyed every day.
	# New fronts, more logistics, a new origin/seed or provider all change the key.
	var cacheable:=WorldSimulation.surface_material_provider.is_valid()
	var cache_key:=[WorldSimulation.state.world_seed,origin,resource,source,minimum_density,max_ring,used.keys(),WorldSimulation.surface_material_provider]
	if cacheable and _surface_front_cache.has(cache_key):return (_surface_front_cache[cache_key] as Dictionary).duplicate(true)
	var result:=_search_surface_front(resource,origin,max_ring,used,minimum_density)
	if cacheable:
		if _surface_front_cache.size()>=SURFACE_FRONT_CACHE_LIMIT:_surface_front_cache.erase(_surface_front_cache.keys()[0])
		_surface_front_cache[cache_key]=result.duplicate(true)
	return result

func _search_surface_front(resource:String,origin:Vector2,max_ring:int,used:Dictionary,minimum_density:float)->Dictionary:
	for ring in range(1,max_ring+1):
		var best:Dictionary={}
		var best_density:=-1.0
		for z in range(-ring,ring+1):
			for x in range(-ring,ring+1):
				if absi(x)!=ring and absi(z)!=ring:continue
				var point:=origin+Vector2(x,z)*SURFACE_FRONT_SPACING_KM
				var candidate:Dictionary
				if WorldSimulation.surface_material_provider.is_valid():
					candidate=WorldSimulation.surface_material_provider.call(point).get(resource,{})
				else:
					var nearby:Dictionary=WorldSimulation.context_provider.call(point)
					candidate=nearby.get("woodland_catchment",{}) if resource=="Timber" else (nearby.get("surface_material_catchments",{}) as Dictionary).get(resource,{})
				var candidate_density:=clampf(float(candidate.get("density",0.0)),0.0,1.0)
				if candidate_density<minimum_density or used.has(_surface_front_key(resource,candidate)):continue
				if candidate_density>best_density:best=candidate;best_density=candidate_density
		if not best.is_empty():return best
	return {}

func _surface_front_key(resource:String,field:Dictionary)->String:
	if field.has("world_key"):return String(field.world_key)
	var point:Vector3=field.get("position",Vector3.ZERO)
	var tile:=Vector2i(floori(point.x/SURFACE_FRONT_SPACING_KM),floori(point.z/SURFACE_FRONT_SPACING_KM))
	return "surface:%d:%d:%s" % [tile.x,tile.y,resource]

func _process_material_flow(context:Dictionary)->Array[Dictionary]:
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	_ensure_woodland_supply(context)
	_ensure_surface_material_supplies(context)
	stamp=trace.mark("flow_fronts",stamp)
	var events:Array[Dictionary]=[]
	var material_deposits:Array[Dictionary]=[]
	var origin:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
	for deposit in WorldSimulation.state.resource_deposits:
		if WorldSimulation.enabled:preload("res://scripts/civilization_resources.gd").available(deposit)
		deposit.extracted_today=0.0
		deposit.delivered_today=0.0
		if String(deposit.stage) not in ["accessible","developed"]: continue
		if not _is_material_resource(String(deposit.resource)): continue
		deposit.distance_km=Vector2(origin.x,origin.z).distance_to(Vector2(deposit.position.x,deposit.position.z))
		material_deposits.append(deposit)
	stamp=trace.mark("flow_available",stamp)
	var extractors:=WorldSimulation.state.effective_workers("Extraction")
	var carriers:=WorldSimulation.state.effective_workers("Logistics")
	var labor_eff:=float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72))
	var storage_priorities:=_storage_gathering_priorities()
	stamp=trace.mark("flow_workers_and_storage",stamp)
	var total_weight:=0.0
	# Orders stay the same for this whole pass; see _stone_drive.
	var pass_inputs:Dictionary={}
	# A deposit's priority is read once: nothing it depends on (stores, orders,
	# its own reserve) changes before its share is taken below.
	var weights:=PackedFloat64Array()
	weights.resize(material_deposits.size())
	for index in material_deposits.size():
		var deposit:Dictionary=material_deposits[index]
		weights[index]=_extraction_priority(deposit,storage_priorities,pass_inputs) if float(deposit.remaining)>0.0 else 0.0
		total_weight+=weights[index]
	# Owner-wide inputs, read once for every deposit in this pass.
	var extraction_effect:=WorldSimulation.discovery.effect("extraction_yield")
	var metal_effect:=WorldSimulation.discovery.effect("metal_yield")
	# Drainage, hoists, pumps and blasting (research: mine output) raise the
	# yield of mined deposits only (research_mechanics.gd is_mined).
	var mining_effect:float=preload("res://scripts/research_mechanics.gd").mining_bonus()
	# The Gathering Yard organises digging and cutting at every deposit (civic_building_effects.gd).
	var output_bonus:=1.0+WorldSimulation.state.founding_effect("resource_output")+WorldSimulation.progression.effect("extraction_yield")+preload("res://scripts/civic_building_effects.gd").effect("extraction")
	var tool_factor:=0.55+float(context.get("tools",0.25))*0.75
	# Searched land: × (0.75 + 0.5 × cover), an older save's blended in (land_yield_factor).
	var land_factor:=land_yield_factor()
	# What one cutter brings in a day at today's spread of the work (role_effect).
	var per_cutter:=0.0
	# A multi-day step (day_span.gd) extracts, regrows and hauls `span` days of
	# work; reported "today" figures remain per day.
	var span:=float(WorldSimulation.span)
	var extracted_total:=0.0
	# Knowledge multipliers depend only on the resource; each is summed once,
	# in the same order, for the first deposit of that resource.
	var knowledge_by_resource:Dictionary={}
	var Resources:=preload("res://scripts/civilization_resources.gd")
	var practice:Dictionary=WorldSimulation.state.resource_practice
	for index in material_deposits.size():
		var deposit:Dictionary=material_deposits[index]
		var resource_name:=String(deposit.resource)
		var share:=weights[index]/maxf(0.001,total_weight) if float(deposit.remaining)>0.0 else 0.0
		var assigned:=extractors*share
		deposit.workers=roundi(assigned)
		var profile:=_material_profile(resource_name)
		var known_multiplier:Variant=knowledge_by_resource.get(resource_name)
		var knowledge_multiplier:float
		if known_multiplier!=null:knowledge_multiplier=known_multiplier
		else:
			knowledge_multiplier=1.0+extraction_effect+WorldSimulation.discovery.effect(resource_name.to_lower().replace(" ","_")+"_yield")
			if String(profile.family)=="metal": knowledge_multiplier+=metal_effect
			if preload("res://scripts/research_mechanics.gd").is_mined(catalog.get(resource_name,{}),profile): knowledge_multiplier+=mining_effect
			# Research names the fibre bonus "fiber_yield"; the resource is "Fiber Plants".
			if resource_name=="Fiber Plants": knowledge_multiplier+=WorldSimulation.discovery.effect("fiber_yield")
			knowledge_by_resource[resource_name]=knowledge_multiplier
		var practice_multiplier:=1.0+minf(0.35,float((practice.get(resource_name,{}) as Dictionary).get("extraction",0.0))*0.035)
		var daily_yield:=assigned*float(profile.base_yield)*float(deposit.quality)*tool_factor*labor_eff*knowledge_multiplier*practice_multiplier*output_bonus*land_factor
		per_cutter+=share*float(profile.base_yield)*float(deposit.quality)*tool_factor*labor_eff*knowledge_multiplier*practice_multiplier*output_bonus*land_factor
		deposit.daily_yield=daily_yield
		var extracted:=Resources.withdraw(deposit,daily_yield*span) if WorldSimulation.enabled else minf(float(deposit.remaining),daily_yield*span)
		deposit.remaining=float(deposit.remaining)-extracted
		deposit.stock_at_source=float(deposit.stock_at_source)+extracted
		deposit.extracted_today=extracted/span
		deposit.lifetime_extracted=float(deposit.lifetime_extracted)+extracted
		extracted_total+=extracted
		if extracted>0.0:
			deposit.stage="developed"
			_gain_practice(resource_name,"extraction",extracted/maxf(1.0,assigned)*0.010)
		if WorldSimulation.enabled and deposit.has("world_key"):
			Resources.renew(deposit,extracted)
		elif String(deposit.get("landscape_source","")) in ["woodland_catchment","plant_fiber_catchment"]:
			# Standing growth returns slowly even when cutting is paused. It stays
			# at the source until labor harvests and hauls it, and cannot exceed the
			# original carrying capacity of this local woodland.
			var capacity:=float(deposit.initial_amount)
			var recovery:=0.001 if String(deposit.landscape_source)=="plant_fiber_catchment" else 0.00003
			deposit.remaining=minf(capacity,float(deposit.remaining)+capacity*recovery*span)
		elif bool(catalog[resource_name].renewable):
			deposit.remaining=float(deposit.remaining)+minf(extracted*0.35,2.0*span)
	# Deliver shipments whose real travel time has elapsed.
	stamp=trace.mark("flow_extraction",stamp)
	var delivered_total:=0.0
	var today:=int(WorldSimulation.state.elapsed_days)
	var stockpiles:Dictionary=WorldSimulation.state.resource_stockpiles
	for deposit in material_deposits:
		# Loads on the road are kept in order of arrival (_add_shipment), so the
		# loads due today are the first ones; the rest are not touched.
		var moving:=_normalized_shipments(deposit)
		if moving.is_empty() or int((moving[0] as Array)[0])>today:continue
		var resource_name:=String(deposit.resource)
		while not moving.is_empty() and int((moving[0] as Array)[0])<=today:
			var quantity:=float((moving.pop_front() as Array)[1])
			stockpiles[resource_name]=float(stockpiles.get(resource_name,0.0))+quantity
			deposit.delivered_today=float(deposit.delivered_today)+quantity
			deposit.lifetime_delivered=float(deposit.lifetime_delivered)+quantity
			delivered_total+=quantity
			deposit.in_transit=float(deposit.in_transit)-quantity
		if moving.is_empty():deposit.in_transit=0.0
	# Carriers are distributed by waiting bulk and priority.  Distance lowers daily
	# throughput and separately creates a visible time-in-transit delay.
	stamp=trace.mark("flow_deliveries",stamp)
	var haul_weight:=0.0
	storage_priorities=_storage_gathering_priorities()
	var route_speed_effect:=WorldSimulation.discovery.effect("route_speed")
	var haul_effect:=1.0+WorldSimulation.discovery.effect("haul_capacity")
	var travel_effect:=1.0+WorldSimulation.discovery.effect("travel_speed")
	# As with extraction, each deposit's hauling priority is read once.
	var haul_priorities:=PackedFloat64Array()
	haul_priorities.resize(material_deposits.size())
	for index in material_deposits.size():
		var deposit:Dictionary=material_deposits[index]
		haul_priorities[index]=_deposit_priority(deposit,storage_priorities,pass_inputs)
		haul_weight+=float(deposit.stock_at_source)*haul_priorities[index]
	for index in material_deposits.size():
		var deposit:Dictionary=material_deposits[index]
		var waiting:=float(deposit.stock_at_source)
		if waiting<=0.0001: continue
		var share:=waiting*haul_priorities[index]/maxf(0.001,haul_weight)
		var assigned_carriers:=carriers*share
		var profile:=_material_profile(String(deposit.resource))
		var route_factor:=0.34+float(deposit.route)*0.66+route_speed_effect
		var distance_factor:=1.0+float(deposit.distance_km)/10.0
		var haul_capacity:=assigned_carriers*5.0/maxf(0.2,float(profile.bulk))*route_factor*labor_eff*haul_effect/distance_factor*span
		var dispatched:=minf(waiting,haul_capacity)
		if dispatched>0.0:
			deposit.stock_at_source=waiting-dispatched
			var speed_km_day:=maxf(1.0,8.0*route_factor*travel_effect)
			deposit.travel_days=maxi(1,ceili(float(deposit.distance_km)/speed_km_day))
			_add_shipment(deposit,today+int(deposit.travel_days),dispatched)
		_update_deposit_bottleneck(deposit,carriers,events)
	stamp=trace.mark("flow_hauling",stamp)
	var loss_report:=_apply_material_storage_losses(events)
	stamp=trace.mark("flow_storage_loss",stamp)
	var lost_total:=float(loss_report.total)
	var at_source:=0.0
	var in_transit:=0.0
	var active_shipments:=0
	var workable_occurrences:=0
	for deposit in material_deposits:
		at_source+=float(deposit.stock_at_source)
		in_transit+=float(deposit.in_transit)
		active_shipments+=(deposit.shipments as Array).size()
		if not deposit_exhausted(deposit):workable_occurrences+=1
	var capacities:=_storage_capacities()
	var stored_bulk:=_stored_bulk()
	var capacity_total:=0.0
	for amount in capacities.values(): capacity_total+=float(amount)
	WorldSimulation.state.material_metrics={"extracted_today":extracted_total/span,"delivered_today":delivered_total/span,"lost_today":lost_total/span,"losses_by_resource":loss_report.by_resource,"storage_used_by_type":loss_report.used_by_type,"at_source":at_source,"in_transit":in_transit,"stored_bulk":stored_bulk,"storage_capacity":capacity_total,"flow_ratio":delivered_total/maxf(0.01,extracted_total),"capacities":capacities,"extraction_workers":extractors,"logistics_workers":carriers,"research_workers":WorldSimulation.state.effective_workers("Knowledge"),"labor_efficiency":labor_eff,"accessible_occurrences":workable_occurrences,"active_shipments":active_shipments,"land_factor":land_factor,"per_cutter":per_cutter,"bounded":true}
	WorldSimulation.state.material_history.append({"day":int(WorldSimulation.state.elapsed_days),"extracted":extracted_total,"delivered":delivered_total,"lost":lost_total,"at_source":at_source,"in_transit":in_transit,"stored":stored_bulk})
	if WorldSimulation.state.material_history.size()>370: WorldSimulation.state.material_history.pop_front()
	stamp=trace.mark("flow_summary",stamp)
	return events

const DEPOSIT_FIELD_DEFAULTS:={"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Not yet accessible","last_reported_bottleneck":""}

const DEPOSIT_FIELD_KEYS:=["stock_at_source","shipments","extracted_today","delivered_today","lifetime_extracted","lifetime_delivered","distance_km","travel_days","bottleneck","last_reported_bottleneck"]
func _ensure_deposit_fields(deposit:Dictionary)->void:
	if deposit.has_all(DEPOSIT_FIELD_KEYS):return
	for key in DEPOSIT_FIELD_DEFAULTS:
		if not deposit.has(key): deposit[key]=DEPOSIT_FIELD_DEFAULTS[key].duplicate() if DEPOSIT_FIELD_DEFAULTS[key] is Array else DEPOSIT_FIELD_DEFAULTS[key]

## A deposit's loads on the road: [arrival day, quantity] in order of
## arrival, with their total in `in_transit`. A deposit without that total
## (an older save, or one made before its first haul) has its loads put in
## that form and order once (normalize_shipments).
func _normalized_shipments(deposit:Dictionary)->Array:
	var moving:Array=deposit.shipments
	if not deposit.has("in_transit") or (not moving.is_empty() and moving[0] is Dictionary):
		normalize_shipments(deposit)
		return deposit.shipments
	return moving

## Older saves kept each load as {quantity, departure_day, arrival_day}, in the
## order sent (the day it left is never read). Loads due the same day keep the
## order they were sent.
static func normalize_shipments(deposit:Dictionary)->void:
	var moving:Array=deposit.get("shipments",[])
	var loads:Array=[]
	var ordered:=true
	for index in moving.size():
		var item:Variant=moving[index]
		var entry:Array=[int(item.get("arrival_day",0)),float(item.get("quantity",0.0))] if item is Dictionary else [int(item[0]),float(item[1])]
		if not loads.is_empty() and int(entry[0])<int((loads[-1] as Array)[0]):ordered=false
		loads.append(entry)
	if not ordered:
		var keyed:Array=[]
		for index in loads.size():keyed.append([int((loads[index] as Array)[0]),index,loads[index]])
		keyed.sort_custom(func(a:Array,b:Array)->bool:return int(a[0])<int(b[0]) or (int(a[0])==int(b[0]) and int(a[1])<int(b[1])))
		loads=keyed.map(func(entry:Array)->Array:return entry[2])
	var total:=0.0
	for entry:Array in loads:total+=float(entry[1])
	deposit["shipments"]=loads
	deposit["in_transit"]=total

## Puts a load on the road in order of arrival (after any load due the same
## day) and adds it to the deposit's `in_transit`.
func _add_shipment(deposit:Dictionary,arrival:int,quantity:float)->void:
	var moving:=_normalized_shipments(deposit)
	var at:=moving.size()
	while at>0 and int((moving[at-1] as Array)[0])>arrival:at-=1
	if at==moving.size():moving.append([arrival,quantity])
	else:moving.insert(at,[arrival,quantity])
	deposit.in_transit=float(deposit.in_transit)+quantity

func _is_material_resource(resource_name:String)->bool:
	# Civilian Goods are maintained household things in use. CivilianGoods applies
	# their wear; raw-yard loss must not charge it again.
	return not NOT_MATERIAL.has(resource_name)
static var NOT_MATERIAL:={"Freshwater":true,"Fertile Soil":true,"Game":true,preload("res://scripts/civilian_goods.gd").GOODS:true}

const MATERIAL_PROFILES:={
		"Timber":{"family":"organic","bulk":1.35,"store":"yard","loss":0.0012,"base_yield":0.34},
		"Fiber Plants":{"family":"organic","bulk":0.45,"store":"dry","loss":0.0035,"base_yield":0.42},
		"Clay":{"family":"earth","bulk":1.25,"store":"covered","loss":0.0010,"base_yield":0.30},
		"Fine Sand":{"family":"earth","bulk":1.35,"store":"covered","loss":0.0006,"base_yield":0.31},
		"Peat":{"family":"fuel","bulk":0.90,"store":"dry","loss":0.0022,"base_yield":0.26},
		"Coal":{"family":"fuel","bulk":1.10,"store":"yard","loss":0.0003,"base_yield":0.18},
		"Bitumen":{"family":"chemical","bulk":0.85,"store":"sealed","loss":0.0020,"base_yield":0.16},
		"Crude Oil":{"family":"fuel","bulk":0.78,"store":"sealed","loss":0.0015,"base_yield":0.10},
		"Salt":{"family":"mineral","bulk":0.80,"store":"dry","loss":0.0018,"base_yield":0.24},
		"Sulfur":{"family":"chemical","bulk":0.75,"store":"sealed","loss":0.0012,"base_yield":0.12},
		"Nitrates":{"family":"chemical","bulk":0.70,"store":"dry","loss":0.0025,"base_yield":0.10},
		"Medicinal Plants":{"family":"organic","bulk":0.20,"store":"dry","loss":0.006,"base_yield":0.16},
		"Coin":{"family":"metal","bulk":0.05,"store":"secure","loss":0.00005,"base_yield":0.0}
}
const ORE_PROFILE:={"family":"metal","bulk":1.55,"store":"secure","loss":0.0002,"base_yield":0.14}
const MINERAL_PROFILE:={"family":"mineral","bulk":1.65,"store":"yard","loss":0.00015,"base_yield":0.24}

func _material_profile(resource_name:String)->Dictionary:
	var known:Variant=_profile_by_name.get(resource_name)
	if known!=null:return known
	var profile:Dictionary
	if MATERIAL_PROFILES.has(resource_name): profile=MATERIAL_PROFILES[resource_name]
	elif "Ore" in resource_name or resource_name in ["Graphite","Lead Ore"]: profile=ORE_PROFILE
	else: profile=MINERAL_PROFILE
	_profile_by_name[resource_name]=profile
	return profile
## Each material's profile (constants), found once per name.
static var _profile_by_name:Dictionary={}

func material_profile(resource_name:String)->Dictionary:
	return _material_profile(resource_name).duplicate(true)

func storage_capacities()->Dictionary:
	return _storage_capacities().duplicate(true)

func stored_bulk()->float:
	return _stored_bulk()


func resource_workforce_snapshot()->Dictionary:
	var metrics:Dictionary=WorldSimulation.state.material_metrics
	var extractors:=maxf(0.0,float(metrics.get("extraction_workers",WorldSimulation.state.population_allocations.get("Extraction",0))))
	var carriers:=maxf(0.0,float(metrics.get("logistics_workers",WorldSimulation.state.population_allocations.get("Logistics",0))))
	var researchers:=maxf(0.0,float(metrics.get("research_workers",WorldSimulation.state.population_allocations.get("Knowledge",0))))
	return {
		"population":WorldSimulation.state.population_total,"extractors":extractors,"carriers":carriers,"researchers":researchers,
		"extracted_today":float(metrics.get("extracted_today",0.0)),"delivered_today":float(metrics.get("delivered_today",0.0)),
		"per_extractor_output":float(metrics.get("extracted_today",0.0))/maxf(1.0,extractors),
		"labor_efficiency":float(metrics.get("labor_efficiency",WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72))),
		"accessible_occurrences":int(metrics.get("accessible_occurrences",0)),"active_shipments":int(metrics.get("active_shipments",0)),
		"bounded":true
	}

func in_transit_for(deposit:Dictionary)->float:
	var total:=0.0
	for shipment_variant in deposit.get("shipments",[]): total+=float(shipment_variant.get("quantity",0.0)) if shipment_variant is Dictionary else float(shipment_variant[1])
	return total

func deposit_exhausted(deposit:Dictionary)->bool:
	if String(deposit.get("stage","")) not in ["accessible","developed"]:return false
	if not deposit.has("remaining"):return false
	return float(deposit.get("remaining",0.0))<=0.001 and float(deposit.get("stock_at_source",0.0))<=0.001 and in_transit_for(deposit)<=0.001

static var gathering_recipe_reserves:Dictionary={}

# Holder object (never captured by saves) for _gathering_startup_reserves.
var _startup_reserve_cache:=RefCounted.new()

func _gathering_startup_reserves()->Dictionary:
	# Fixed recipe metadata only. Eligibility is read from this society each time.
	if gathering_recipe_reserves.is_empty():
		for recipe:Dictionary in preload("res://scripts/civilian_industry.gd").PRODUCTS.values():
			var gate:=String(recipe.get("gate",""))
			if not gathering_recipe_reserves.has(gate):gathering_recipe_reserves[gate]={}
			var amounts:Dictionary=recipe.get("materials",{}).duplicate()
			for resource_name:String in recipe.get("tooling",{}):amounts[resource_name]=float(amounts.get(resource_name,0))+float(recipe.tooling[resource_name])
			# Former recipes steer gathering toward the raw materials they need;
			# their manufactured parts are now raw materials plus Civilian Goods.
			amounts=preload("res://scripts/goods_bills.gd").flatten(amounts).duplicate()
			amounts.erase("Civilian Goods")
			for resource_name:String in amounts:
				gathering_recipe_reserves[gate][resource_name]=maxf(float(gathering_recipe_reserves[gate].get(resource_name,0)),float(amounts[resource_name])*2.0)
	# Depends only on the known-discovery list; reuse it while that list's
	# content hash is unchanged. Callers only read the returned reserves.
	var key:=WorldSimulation.state.known_discoveries.hash()
	if _startup_reserve_cache.has_meta("key") and _startup_reserve_cache.get_meta("key")==key:return _startup_reserve_cache.get_meta("value")
	var result:Dictionary={}
	for gate:String in WorldSimulation.state.known_discoveries:
		for resource_name:String in gathering_recipe_reserves.get(gate,{}):
			result[resource_name]=maxf(float(result.get(resource_name,0)),float(gathering_recipe_reserves[gate][resource_name]))
	result.make_read_only()
	_startup_reserve_cache.set_meta("key",key);_startup_reserve_cache.set_meta("value",result)
	return result

func _storage_gathering_priorities()->Dictionary:
	# Preserve samples and useful inputs, but do not keep filling an overflowing
	# store with unused ores while the same workers could gather scarce timber.
	# This is a local, transient allocation: neither stocks nor labor are created.
	var needed:Dictionary={}
	for resource_name:String in ["Timber","Stone","Clay","Fiber Plants","Flint","Salt","Medicinal Plants"]:
		needed[resource_name]=true
	var campaign:=WorldSimulation.military
	for job:Dictionary in campaign.equipment_queue:
		if bool(job.get("paused",false)):continue
		if bool(job.get("persistent",false)) and int(job.get("target_stock",0))>0 and float(job.get("progress_days",0))<=0.0:
			if preload("res://scripts/persistent_production.gd").stock(campaign,job)>=int(job.target_stock):continue
		for resource_name:String in job.get("materials",{}):needed[resource_name]=true
	for id:String in WorldSimulation.state.technology_operations.get("plants",{}):
		var record:Dictionary=WorldSimulation.state.technology_operations.plants[id]
		if int(record.get("installed",0))<=0 or not bool(record.get("enabled",true)):continue
		for resource_name:String in preload("res://scripts/technology_operations.gd").PLANTS.get(id,{}).get("inputs",{}):needed[resource_name]=true
	var capacities:=_storage_capacities()
	var startup_reserves:=_gathering_startup_reserves()
	var used:Dictionary={}
	for resource_name:String in WorldSimulation.state.resource_stockpiles:
		if resource_name=="Food" or not _is_material_resource(resource_name):continue
		var profile:=_material_profile(resource_name)
		used[profile.store]=float(used.get(profile.store,0))+maxf(0,float(WorldSimulation.state.resource_stockpiles[resource_name]))*float(profile.bulk)
	var result:Dictionary={}
	for resource_name:String in WorldSimulation.state.resource_stockpiles:
		if needed.has(resource_name) or float(WorldSimulation.state.resource_priorities.get(resource_name,1.0))>1.0:continue
		# A known craft can accumulate setup plus a first batch before a line
		# exists. The margin also covers ordinary daily losses and transport.
		if float(WorldSimulation.state.resource_stockpiles[resource_name])<=maxf(1.0,float(startup_reserves.get(resource_name,0))):continue
		var store:=String(_material_profile(resource_name).store)
		if float(used.get(store,0))>float(capacities.get(store,0)):result[resource_name]=0.05
	return result

func _deposit_priority(deposit:Dictionary,storage_priorities:Dictionary={},pass_inputs:Dictionary={})->float:
	var resource_name:=String(deposit.resource)
	var named:=float(WorldSimulation.state.resource_priorities.get(resource_name,1.0))
	if resource_name=="Stone":
		# A civic stone drive redirects existing extractors and carriers; it does
		# not create workers, reveal deposits, or produce stone from nothing.
		named*=_stone_drive(pass_inputs)
	var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))
	# Once a local store is well supplied, release its share of the same finite
	# workforce. The previous floor of 1 kept most workers gathering already
	# overflowing materials while essential timber had no stock at all.
	var working_stock:=maxf(20.0,WorldSimulation.state.population_exact*.08)
	var scarcity:=2.0/(1.0+maxf(0.0,stored)/working_stock)
	return maxf(0.05,named*scarcity*float(deposit.quality)/(1.0+float(deposit.distance_km)/45.0))*float(storage_priorities.get(resource_name,1.0))

func _extraction_priority(deposit:Dictionary,storage_priorities:Dictionary={},pass_inputs:Dictionary={})->float:
	var reserve:=float(deposit.get("remaining",0.0))
	var working_reserve:=maxf(1.0,float(deposit.get("initial_amount",1.0))*0.05)
	return _deposit_priority(deposit,storage_priorities,pass_inputs)*clampf(reserve/working_reserve,0.0,1.0)

## The stone drive's weight on Stone deposits. Orders do not change during one
## material pass, so the pass reads it once (in `pass_inputs`) instead of
## searching every order for each Stone deposit's four priority readings.
func _stone_drive(pass_inputs:Dictionary)->float:
	if not pass_inputs.has("stone_drive"):
		pass_inputs["stone_drive"]=1.0+maxf(0.0,WorldSimulation.consequences.policy_effect("stone_priority"))*3.0
	return float(pass_inputs["stone_drive"])

func _storage_capacities()->Dictionary:
	var pop:=WorldSimulation.state.population_exact
	# Capacity comes from named portable assets or completed works. Bare ground can
	# hold a small outdoor pile, but it is not dry, sealed, covered, or secure.
	var result={"yard":maxf(12.0,pop*0.10),"dry":float(WorldSimulation.state.founding_manifest.get("dry_storage_bulk",0.0)),"covered":float(WorldSimulation.state.founding_manifest.get("covered_storage_bulk",0.0)),"sealed":float(WorldSimulation.state.founding_manifest.get("sealed_storage_bulk",0.0)),"secure":float(WorldSimulation.state.founding_manifest.get("secure_storage_bulk",0.0))}
	if "Gathering Yard" in WorldSimulation.state.settlement_completed: result.yard+=320.0
	if "Open Work Area" in WorldSimulation.state.settlement_completed: result.yard+=160.0; result.covered+=55.0; result.secure+=20.0
	if "Lean-to Shelters" in WorldSimulation.state.settlement_completed: result.dry+=90.0
	if "Storage Pits" in WorldSimulation.state.settlement_completed: result.covered+=140.0; result.sealed+=25.0
	# Built storage is part of the city's capacities; its condition and staffing
	# already limit how much of the nominal space can be used.
	var built:Dictionary=WorldSimulation.settlements.city_capacities().get("storage_bulk",{})
	for kind:String in built:result[kind]=float(result[kind])+float(built[kind])
	result.dry*=1.0+WorldSimulation.discovery.effect("dry_storage")
	result.covered*=1.0+WorldSimulation.discovery.effect("container_capacity")
	result.sealed*=1.0+WorldSimulation.discovery.effect("container_capacity")
	return result

func _stored_bulk()->float:
	var total:=0.0
	for resource_name in WorldSimulation.state.resource_stockpiles:
		if resource_name=="Food" or not _is_material_resource(String(resource_name)): continue
		total+=float(WorldSimulation.state.resource_stockpiles[resource_name])*float(_material_profile(String(resource_name)).bulk)
	return total

func _apply_material_storage_losses(events:Array[Dictionary])->Dictionary:
	var capacities:=_storage_capacities()
	var used={"yard":0.0,"dry":0.0,"covered":0.0,"sealed":0.0,"secure":0.0}
	var lost_total:=0.0
	var losses_by_resource:Dictionary={}
	for resource_name_variant in WorldSimulation.state.resource_stockpiles.keys():
		var resource_name:=String(resource_name_variant)
		if resource_name=="Food" or not _is_material_resource(resource_name): continue
		var amount:=float(WorldSimulation.state.resource_stockpiles[resource_name])
		if amount<=0.0: continue
		var profile:=_material_profile(resource_name)
		var store:=String(profile.store)
		var bulk:=float(profile.bulk)
		var decay:=amount*SPAN.rate(maxf(0.0,float(profile.loss)+WorldSimulation.discovery.effect("storage_loss")))
		var available_bulk:=maxf(0.0,float(capacities[store])-float(used[store]))
		var overflow_units:=maxf(0.0,amount-available_bulk/bulk)
		# Exposed stone/flint is durable. An overfull yard adds handling loss,
		# not the rapid spoilage used for organic or containment-dependent stock.
		var exposure_rate:=0.0005 if String(profile.family)=="mineral" and store=="yard" else 0.035
		var overflow_loss:=overflow_units*SPAN.rate(exposure_rate)
		var loss:=minf(amount,decay+overflow_loss)
		WorldSimulation.state.resource_stockpiles[resource_name]=amount-loss
		used[store]=float(used[store])+maxf(0.0,amount-loss)*bulk
		lost_total+=loss
		if loss>0.0001:losses_by_resource[resource_name]=loss
	if lost_total>0.5:
		events.append(_event("Material Losses","%.1f units were lost today to exposure, leakage, damage, or overcrowded stores." % lost_total,"storage"))
	return {"total":lost_total,"by_resource":losses_by_resource,"used_by_type":used}

func _update_deposit_bottleneck(deposit:Dictionary,carriers:float,events:Array[Dictionary])->void:
	var bottleneck:="Flowing"
	if deposit_exhausted(deposit):bottleneck="Source exhausted"
	elif float(deposit.get("daily_yield",0.0))<=0.0: bottleneck="No extractors assigned"
	elif float(deposit.stock_at_source)>maxf(2.0,float(deposit.extracted_today)*4.0): bottleneck="Material accumulating at source"
	elif carriers<=0.0: bottleneck="No carriers assigned"
	elif float(deposit.route)<0.45: bottleneck="Access route is slow"
	deposit.bottleneck=bottleneck
	if bottleneck!=String(deposit.last_reported_bottleneck) and bottleneck!="Flowing":
		deposit.last_reported_bottleneck=bottleneck
		events.append(_event("Resource Flow Constrained","%s: %s." % [String(deposit.resource),bottleneck],String(deposit.id)))

func _practice(resource_name:String,domain:String)->float:
	return float((WorldSimulation.state.resource_practice.get(resource_name,{}) as Dictionary).get(domain,0.0))

func _gain_practice(resource_name:String,domain:String,amount:float)->void:
	if not WorldSimulation.state.resource_practice.has(resource_name): WorldSimulation.state.resource_practice[resource_name]={}
	var practice:Dictionary=WorldSimulation.state.resource_practice[resource_name]
	practice[domain]=minf(10.0,float(practice.get(domain,0.0))+amount)

func _memo_literacy(resource_name:String,memo:Dictionary)->float:
	if not memo.has(resource_name):memo[resource_name]=_family_literacy(resource_name)
	return float(memo[resource_name])

func _family_literacy(resource_name:String)->float:
	var family:=String((catalog.get(resource_name,{}) as Dictionary).get("family",""))
	var related:=0.0
	for practiced_resource in WorldSimulation.state.resource_practice:
		if String((catalog.get(practiced_resource,{}) as Dictionary).get("family",""))==family:
			for amount in (WorldSimulation.state.resource_practice[practiced_resource] as Dictionary).values(): related+=float(amount)
	return 1.0+minf(0.55,related*0.012)

func resource_name_from(deposit:Dictionary)->String:
	return String(deposit.get("resource",""))

func _event(title: String, description: String, deposit_id: String) -> Dictionary:
	return {"day":int(WorldSimulation.state.elapsed_days), "title":title, "description":description, "deposit_id":deposit_id}

func visible_deposits() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for deposit in WorldSimulation.state.resource_deposits:
		if deposit.stage != "unknown": visible.append(deposit)
	return visible

func lens_entries(origin: Vector3, radius_world_units: float, km_per_unit := 1.0) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for deposit in visible_deposits():
		var distance := Vector2(origin.x,origin.z).distance_to(Vector2(deposit.position.x,deposit.position.z))
		if distance > radius_world_units:
			continue
		var surveyed: bool = deposit.stage != "recognized"
		var stage_retrievable:bool=deposit.stage=="accessible" or deposit.stage=="developed"
		var exhausted:=deposit_exhausted(deposit)
		var retrievable:bool=stage_retrievable and not exhausted
		var visible_blockers: Array = deposit.blockers.duplicate()
		if not surveyed:
			visible_blockers = ["deposit has not been surveyed"]
		elif exhausted:
			visible_blockers=["known source is exhausted"]
		elif not retrievable and visible_blockers.is_empty():
			visible_blockers = ["access work is incomplete"]
		entries.append({
			"id":deposit.id,
			"resource":deposit.resource,
			"distance_km":distance*km_per_unit,
			"knowledge":"surveyed" if surveyed else "indicated",
			"quality":_quality_label(deposit.quality) if surveyed else "unknown",
			"abundance":_abundance_label(deposit) if surveyed else "unknown",
			"retrievable":retrievable,
			"access":"Retrievable now" if retrievable else "Source exhausted" if exhausted else "Not currently retrievable",
			"blockers":visible_blockers
		})
	return entries

func _quality_label(quality: float) -> String:
	if quality >= 1.2: return "exceptional"
	if quality >= 0.9: return "good"
	if quality >= 0.65: return "ordinary"
	return "poor"

func _abundance_label(deposit: Dictionary) -> String:
	var ratio: float = deposit.remaining / maxf(1.0,deposit.initial_amount)
	var effective: float = deposit.initial_amount * deposit.quality
	if ratio < 0.08: return "nearly exhausted"
	if effective >= 6500: return "abundant"
	if effective >= 2500: return "common"
	if effective >= 900: return "limited"
	return "traces"

# These inputs are invariant only within one local-city resource pass. Do not
# cache them across days, city scopes, allocation changes or policy changes.
# Research attention counts by its share of the plan, in common steps, so the
# same plan helps the search the same for every ruler.
func _local_survey_inputs()->Dictionary:
	var steps:=preload("res://scripts/research_600_catalog.gd").attention_steps(WorldSimulation.state.research_allocations)
	return {"effort":WorldSimulation.state.effective_workers("Survey") / 6.0*WorldSimulation.consequences.survey_factor(),"nature":float(steps.get("ecology",0.0))*.15,"material":float(steps.get("production",0.0))*.12,"speed":1.0+WorldSimulation.discovery.effect("survey_speed")}

# --- Searching the land: how well it is searched, and what searchers find --------------

## Each people, and each town in its own scope (settlement_model.gd
## CITY_RESOURCE_DEFAULTS "land_survey"), keeps how well its land is searched:
## `cover`, 0..1. Every people follows the same rules; only the work differs.
##   target  = r / (r + 2/3), r = searchers ÷ (people ÷ 60): one searcher for
##             every 60 people holds the land near 0.6 (land_target).
##   rising  : the gap to the target closes by 1 − (1 − 0.45 × r)^years, at
##             most 0.9 of it a year, so it is near 0.6 in a few years.
##   sagging : above the target it loses a twentieth a year (paths overgrow,
##             finds are forgotten), never below the target (land_step).
## Cutters and diggers yield × (0.75 + 0.5 × cover) (land_yield, applied in
## _process_material_flow). Once a month one seeded roll at the stated odds,
## p = 1 − e^(−0.016 × searchers × (1 + survey speed)) (land_find_odds), makes
## a find: a deposit of the land the people can recognise but have not
## measured; else new ground 4 to 20 km out, on land and in no other people's
## hold (a deposit the world's geology really holds there, or, where the world
## keeps none, the registration an expedition's find uses); else a richer part
## of a deposit being worked (a tenth more, at most twice each). Water, woods
## and fibre are never a searcher's find. Each find is told once, to the god's
## own people only, in the Chronicle: a year's finds gather on one card. An
## older save starts from its survey history (the share of the land's
## deposits it had found) and blends into the new yield over a year.
const LAND_PEOPLE_PER_SEARCHER:=60.0
const LAND_HALF:=2.0/3.0
const LAND_RISE_YEAR:=0.45
const LAND_RISE_MAX:=0.9
const LAND_SAG_YEAR:=0.05
const LAND_YIELD_BASE:=0.75
const LAND_YIELD_SPAN:=0.5
## An older save's yield moves from the old rule (×1) to the new over this long.
const LAND_BLEND_DAYS:=365.0
## A land first kept this long after its founding is an older save's.
const LAND_OLD_SAVE_DAYS:=30
## The history start never claims the whole land searched.
const LAND_HISTORY_CAP:=0.9
const LAND_FIND_RATE:=0.016
const LAND_MONTH_DAYS:=30
const LAND_RICHER:=0.10
const LAND_RICHER_TIMES:=2
const LAND_QUALITY_CAP:=1.5
## New ground lies this far from the town (km).
const LAND_FIND_NEAR_KM:=4.0
const LAND_FIND_FAR_KM:=20.0
## Spots of new ground looked at for one find before the searchers give up.
const LAND_FIND_TRIES:=3
## The least promise of the ground (its potential) where new ground is opened,
## as an expedition's find needs (register_expedition_occurrence).
const LAND_FIND_POTENTIAL:=0.38
const LAND_FINDS_KEPT:=12
## A find told within this many days of the last card of finds is one quiet
## line on that card (chronicle.gd folding).
const LAND_FOLD_DAYS:=365
## Kinds new ground is never searched for: food grounds, and the woods and
## fibre the carriers find (surface_search_rings). Water of every kind is
## never a searcher's find either (_land_water).
const LAND_NOT_FOUND:=["Freshwater","Fertile Soil","Game","Timber","Fiber Plants"]
## Searched land this close to where it is heading is held there (the words).
const LAND_STEADY:=0.005
const LAND_COMPASS:=["east","south-east","south","south-west","west","north-west","north","north-east"]
## Test seam: when 0 or more, stands in for the month's seeded roll
## (tests/test_survey_cover.gd). Never set by the game.
static var forced_land_roll:=-1.0

## Searchers for every 60 people, the measure of the searching.
static func land_ratio(searchers:float,people:float)->float:
	return maxf(0.0,searchers)*LAND_PEOPLE_PER_SEARCHER/maxf(1.0,people)

## Where the searched land heads with these searchers for these people.
static func land_target(searchers:float,people:float)->float:
	var r:=land_ratio(searchers,people)
	return r/(r+LAND_HALF)

## What cutters and diggers get from land searched this well.
static func land_yield(cover:float)->float:
	return LAND_YIELD_BASE+LAND_YIELD_SPAN*clampf(cover,0.0,1.0)

## The searched land after `days` with these searchers and people (the one rule).
static func land_step(cover:float,searchers:float,people:float,days:float)->float:
	if days<=0.0:return cover
	var years:=days/365.0
	var target:=land_target(searchers,people)
	if target>cover:
		var rate:=clampf(LAND_RISE_YEAR*land_ratio(searchers,people),0.0,LAND_RISE_MAX)
		return clampf(cover+(target-cover)*(1.0-pow(1.0-rate,years)),0.0,1.0)
	return clampf(maxf(target,cover*pow(1.0-LAND_SAG_YEAR,years)),0.0,1.0)

func _land_searchers()->float:
	return maxf(0.0,WorldSimulation.state.effective_workers("Survey"))

func _land_people()->float:
	return maxf(1.0,float(WorldSimulation.state.population_exact))

## The month's chance of a find with these searchers (-1: those at work now):
## the odds every screen states and the roll is made against.
func land_find_odds(searchers:float=-1.0)->float:
	var n:=_land_searchers() if searchers<0.0 else maxf(0.0,searchers)
	var speed:=maxf(-0.5,WorldSimulation.discovery.effect("survey_speed"))
	return 1.0-exp(-LAND_FIND_RATE*n*(1.0+speed))

## Water of every kind (surface water, deep aquifers) is found by other work,
## never by the searchers.
func _land_water(resource:String)->bool:
	return String((catalog.get(resource,{}) as Dictionary).get("family",""))=="Water"

## A deposit of the land searchers look for: a material of the catalog, not
## water or a food ground, and not a worked front of woods, stone or fibre
## (those the carriers find, _ensure_surface_supply).
func _land_kind(deposit:Dictionary)->bool:
	var resource:=String(deposit.get("resource",""))
	if not catalog.has(resource) or not _is_material_resource(resource) or _land_water(resource):return false
	return String(deposit.get("landscape_source",""))==""

## A kind new ground may be opened for: a material the people can recognise,
## never water, a food ground, or the woods and fibre the carriers find.
func _land_new_kind(resource:String)->bool:
	if resource in LAND_NOT_FOUND or not catalog.has(resource) or not _is_material_resource(resource) or _land_water(resource):return false
	return recognition_ready(resource)

## How much of its land a people had searched before the land was kept: the
## share of the deposits it can recognise that it had found (half for one
## seen but not measured), at most 0.9. With nothing to judge by, an older
## save starts where its searchers hold the land now, a new one at 0.
func _land_history_cover(older:bool)->float:
	var known:=0.0;var total:=0.0
	var ready:Dictionary={}
	for deposit_variant in WorldSimulation.state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if not _land_kind(deposit):continue
		var resource:=String(deposit.get("resource",""))
		var stage:=String(deposit.get("stage","unknown"))
		if stage=="unknown":
			if not ready.has(resource):ready[resource]=recognition_ready(resource)
			if not bool(ready[resource]):continue
		total+=1.0
		if stage=="recognized":known+=0.5
		elif stage!="unknown":known+=1.0
	if total<=0.0:return land_target(_land_searchers(),_land_people()) if older else 0.0
	return clampf(known/total,0.0,LAND_HISTORY_CAP)

## A new land record for this scope (not stored): an older save (first kept
## more than 30 days after its founding) starts from its survey history and
## blends into the new yield over a year; a new people or town starts from
## what its founders saw, at once.
func _land_new_record()->Dictionary:
	var state=WorldSimulation.state
	var day:=int(state.elapsed_days)
	var founded:=int(state.settlement_founded_day)
	var older:=founded>=0 and day-founded>LAND_OLD_SAVE_DAYS
	var start:=_land_history_cover(older)
	return {"cover":start,"start_cover":start,"day":day,"find_month":floori(float(day)/LAND_MONTH_DAYS),"blend_from":day if older else -1,"finds":[],"last_roll":{}}

## The land's record in this scope, made on first use.
func _land_record()->Dictionary:
	var land:Dictionary=WorldSimulation.state.land_survey
	if not land.has("cover"):land.merge(_land_new_record(),true)
	return land

## The yield an older save's cutters get on `day`: the new rule's, blended
## in from the old (×1) over a year.
static func _land_applied(land:Dictionary,day:int)->float:
	var full:=land_yield(float(land.get("cover",0.0)))
	var from:=int(land.get("blend_from",-1))
	if from<0:return full
	return 1.0+(full-1.0)*clampf(float(day-from)/LAND_BLEND_DAYS,0.0,1.0)

## What cutters and diggers get from the searched land today, as the engine
## applies it. A people still on the road works no land of its own: ×1.
func land_yield_factor()->float:
	var state=WorldSimulation.state
	if not (state.land_survey as Dictionary).has("cover") and not state.settlement_site_committed:return 1.0
	return _land_applied(_land_record(),int(state.elapsed_days))

## The land's day (_process_local_day, before the cutters work): the cover
## moves for the days gone by; a new month rolls once, at the stated odds,
## for a find. A people still on the road searches no land of its own.
func _advance_land(context:Dictionary)->void:
	var state=WorldSimulation.state
	if not bool(context.get("settled",state.settlement_site_committed)):return
	var land:=_land_record()
	var day:=int(state.elapsed_days)
	var days:=clampi(day-int(land.get("day",day)),0,3650)
	if days>0:
		land.cover=land_step(float(land.cover),_land_searchers(),_land_people(),float(days))
		land.day=day
	if int(land.get("blend_from",-1))>=0 and float(day-int(land.blend_from))>=LAND_BLEND_DAYS:land.blend_from=-1
	var month:=floori(float(day)/LAND_MONTH_DAYS)
	var last:=int(land.get("find_month",month))
	if month<=last:return
	land.find_month=month
	# A step over several months (a calm rival, a load) rolls once for them all.
	var months:=mini(12,month-last)
	var p:=1.0-pow(1.0-land_find_odds(),float(months))
	var roll:=_land_rng(month,"roll").randf() if forced_land_roll<0.0 else forced_land_roll
	land.last_roll={"day":day,"p":p,"roll":roll,"months":months,"searchers":_land_searchers()}
	if roll>=p:return
	var origin:=_land_origin(context)
	# What is found is picked by its own seed, never the roll's.
	var find:=_land_find(origin,_land_rng(month,"pick"))
	if find.is_empty():
		land.last_roll["found"]="nothing new"
		return
	var deposit:Dictionary=find.deposit
	var entry:={"day":day,"kind":String(find.kind),"resource":String(deposit.get("resource","")),"deposit_id":String(deposit.get("id","")),"km":snappedf(_land_km(deposit,origin),0.1),"way":_land_way(origin,deposit),"told":false}
	if String(find.kind)=="richer":entry.merge({"quality_before":float(find.before),"quality":float(deposit.get("quality",1.0))},true)
	if bool(find.get("seen",false)):entry["seen"]=true
	land.last_roll["found"]=String(find.kind)
	var finds:Array=land.get("finds",[])
	finds.push_front(entry)
	if finds.size()>LAND_FINDS_KEPT:finds.resize(LAND_FINDS_KEPT)
	land.finds=finds
	_tell_land_find(entry)

## A month's roll ("roll") or the pick of what is found ("pick"), each its own
## seed: reproducible from the world's seed, the land's place and the month,
## so viewing never rolls again and a load rolls the same.
func _land_rng(month:int,salt:String="roll")->RandomNumberGenerator:
	var at:Vector3=WorldSimulation.state.settlement_founded_at
	var generator:=RandomNumberGenerator.new()
	generator.seed=hash("%d:land_%s:%d:%d:%d" % [int(WorldSimulation.state.world_seed),salt,roundi(at.x*10.0),roundi(at.z*10.0),month])
	return generator

func _land_origin(context:Dictionary)->Vector3:
	var value:Variant=context.get("origin",WorldSimulation.state.settlement_founded_at)
	if value is Vector2:return Vector3((value as Vector2).x,0.0,(value as Vector2).y)
	return value if value is Vector3 else WorldSimulation.state.settlement_founded_at

static func _land_km(deposit:Dictionary,origin:Vector3)->float:
	var at:Variant=deposit.get("position",origin)
	var point:Vector3=at if at is Vector3 else origin
	return Vector2(origin.x,origin.z).distance_to(Vector2(point.x,point.z))

static func _land_way(origin:Vector3,deposit:Dictionary)->String:
	var at:Variant=deposit.get("position",origin)
	var point:Vector3=at if at is Vector3 else origin
	var offset:=Vector2(point.x-origin.x,point.z-origin.z)
	if offset.length()<0.5:return ""
	return LAND_COMPASS[posmod(roundi(offset.angle()/(PI/4.0)),8)]

static func _weighted(pick:RandomNumberGenerator,weights:Array)->int:
	var total:=0.0
	for weight in weights:total+=maxf(0.0,float(weight))
	var at:=pick.randf()*total
	for index in weights.size():
		at-=maxf(0.0,float(weights[index]))
		if at<=0.0:return index
	return weights.size()-1

## A seeded spot 4 to 20 km out from the town.
static func _land_spot(origin:Vector3,pick:RandomNumberGenerator)->Vector2:
	var angle:=pick.randf()*TAU
	var km:=pick.randf_range(LAND_FIND_NEAR_KM,LAND_FIND_FAR_KM)
	return Vector2(origin.x,origin.z)+Vector2(cos(angle),sin(angle))*km

## The ground's own profile at a spot: the map's reading where it gives one,
## else the planet's.
func _land_profile_at(point:Vector2)->Dictionary:
	if WorldSimulation.context_provider.is_valid():
		var spot:Variant=WorldSimulation.context_provider.call(point)
		if spot is Dictionary:
			var profile:Variant=(spot as Dictionary).get("environment_profile",{})
			if profile is Dictionary and not (profile as Dictionary).is_empty():return profile
	return PlanetEnvironment.profile_at(point)

## The land other peoples hold, read once for a find: each town of theirs
## by its outline or, where it keeps none, by the reach its people give it
## (nation_borders.gd estimated_radius). Land we hold is ours.
func _foreign_holds()->Array:
	var holds:Array=[]
	var world=WorldSimulation.world
	if world==null or world.get("city_intelligence")==null:return holds
	var places:Dictionary={}
	for site:Dictionary in world.city_intelligence.sites(false):places[String(site.get("city_id",""))]=site.get("position",{})
	var us:=String(WorldSimulation.actor_id)
	var borders=load("res://scripts/nation_borders.gd")
	for civ:Dictionary in world.civilizations:
		for region:Dictionary in civ.get("strategic_regions",[]):
			var id:=String(region.get("id",""))
			if not places.has(id):continue
			var holder:=String(region.get("controller",civ.get("id","")))
			# Our own holds: in a rival's view its holdings read "player"
			# (_localize_controllers), so "player" is ours in every scope.
			if holder=="" or holder in [us,"player"] or (us=="player" and holder=="human"):continue
			var boundary:Variant=region.get("boundary",[])
			if (boundary is PackedVector2Array or boundary is Array) and int(boundary.size())>=3:
				holds.append({"boundary":PackedVector2Array(boundary)})
				continue
			var place:Dictionary=places[id]
			holds.append({"center":Vector2(float(place.get("x",0.0)),float(place.get("z",0.0))),"reach":float(borders.estimated_radius(float(region.get("population",800.0))))})
	return holds

static func _in_holds(point:Vector2,holds:Array)->bool:
	for hold:Dictionary in holds:
		if hold.has("boundary"):
			if Geometry2D.is_point_in_polygon(point,hold.boundary):return true
		elif (hold.center as Vector2).distance_to(point)<=float(hold.reach):return true
	return false

## Whether `point` lies in land another people holds.
func _foreign_land(point:Vector2)->bool:
	return _in_holds(point,_foreign_holds())

## One find, when the month's roll came up: {kind ("new" | "richer"),
## deposit, seen (it had been seen, not measured), before (the quality before,
## for a richer find)}, or {} when the land holds nothing more the people can
## find.
##   1. A deposit of this land they can recognise but have not measured (the
##      nearer the likelier): it is found and measured at once.
##   2. New ground 4 to 20 km out, on land and in no other people's hold.
##   3. A richer part of a deposit being worked (never a worked front of
##      woods, stone or fibre): a tenth more from each cutter there, at most
##      twice for each deposit and never past 1.5.
func _land_find(origin:Vector3,pick:RandomNumberGenerator)->Dictionary:
	var state=WorldSimulation.state
	var waiting:Array=[];var nearness:Array=[]
	var ready:Dictionary={}
	for deposit_variant in state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if not _land_kind(deposit):continue
		var stage:=String(deposit.get("stage",""))
		if stage not in ["unknown","recognized"]:continue
		var resource:=String(deposit.resource)
		if stage=="unknown":
			if not ready.has(resource):ready[resource]=recognition_ready(resource)
			if not bool(ready[resource]):continue
		if WorldSimulation.enabled:preload("res://scripts/civilization_resources.gd").available(deposit)
		if float(deposit.get("remaining",0.0))<=0.0:continue
		waiting.append(deposit);nearness.append(1.0/(1.0+_land_km(deposit,origin)/10.0))
	if not waiting.is_empty():
		var found:Dictionary=waiting[_weighted(pick,nearness)]
		var seen:=String(found.stage)=="recognized"
		found.stage="surveyed";found.clues=1.0;found.survey=1.0
		_gain_practice(String(found.resource),"survey",0.18)
		return {"kind":"new","deposit":found,"seen":seen}
	var opened:=_land_new_ground_world(origin,pick) if WorldSimulation.enabled else _land_new_ground_local(origin,pick)
	if not opened.is_empty():
		_gain_practice(String(opened.resource),"survey",0.18)
		return {"kind":"new","deposit":opened}
	var worked:Array=[]
	for deposit_variant in state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if not _land_kind(deposit):continue
		if String(deposit.get("stage","")) not in ["accessible","developed"] or deposit_exhausted(deposit):continue
		if int(deposit.get("richer_finds",0))>=LAND_RICHER_TIMES or float(deposit.get("quality",1.0))>=LAND_QUALITY_CAP:continue
		worked.append(deposit)
	if worked.is_empty():return {}
	var richer:Dictionary=worked[pick.randi_range(0,worked.size()-1)]
	var before:=float(richer.get("quality",1.0))
	richer.quality=minf(LAND_QUALITY_CAP,before*(1.0+LAND_RICHER))
	richer["richer_finds"]=int(richer.get("richer_finds",0))+1
	return {"kind":"richer","deposit":richer,"before":before}

## New ground where the world keeps one geology for every people: a 16 km
## cell at a spot 4 to 20 km out, and one deposit that cell really holds
## (civilization_resources.gd cell_occurrences), of a kind searchers find, on
## land, in no other people's hold and not worked out, that this people does
## not know yet (the likelier where the ground promises more). Only that
## deposit joins the people's list, measured; a cell with nothing to find
## adds nothing.
func _land_new_ground_world(origin:Vector3,pick:RandomNumberGenerator)->Dictionary:
	var Resources:=preload("res://scripts/civilization_resources.gd")
	var state=WorldSimulation.state
	var keys:Dictionary=Resources._world_keys()
	var holds:=_foreign_holds()
	for attempt in LAND_FIND_TRIES:
		var point:=_land_spot(origin,pick)
		var options:Array=[];var promise:Array=[]
		for deposit:Dictionary in Resources.cell_occurrences(Vector2i(floori(point.x/16.0),floori(point.y/16.0)),keys):
			if not _land_new_kind(String(deposit.resource)):continue
			var at:Vector3=deposit.position
			if _in_holds(Vector2(at.x,at.z),holds):continue
			var reserve:Dictionary=WorldSimulation.geography_stock.get(String(deposit.world_key),{})
			if not reserve.is_empty() and float(reserve.get("remaining",0.0))<=0.0:continue
			options.append(deposit);promise.append(maxf(0.05,float(deposit.get("environment_potential",0.5))))
		if options.is_empty():continue
		var found:Dictionary=options[_weighted(pick,promise)]
		var key:=String(found.world_key)
		if not WorldSimulation.geography_stock.has(key):WorldSimulation.geography_stock[key]={"remaining":float(found.initial_amount),"initial_amount":float(found.initial_amount),"last_day":int(state.elapsed_days)}
		found.remaining=float(WorldSimulation.geography_stock[key].remaining)
		found.id="%s_%d" % [String(found.resource).to_snake_case(),state.resource_deposits.size()]
		found.stage="surveyed";found.clues=1.0;found.survey=1.0
		found["found_by"]="searchers"
		state.resource_deposits.append(found)
		return found
	return {}

## New ground where the world keeps no shared geology (an older campaign):
## a spot 4 to 20 km out, on land and in no other people's hold, and a kind
## its own ground promises (potential at least 0.38), registered as an
## expedition's find is (register_expedition_occurrence).
func _land_new_ground_local(origin:Vector3,pick:RandomNumberGenerator)->Dictionary:
	var holds:=_foreign_holds()
	for attempt in LAND_FIND_TRIES:
		var point:=_land_spot(origin,pick)
		if not WorldSimulation.world._scout_land_at(point) or _in_holds(point,holds):continue
		var profile:=_land_profile_at(point)
		var potentials:Dictionary=profile.get("resource_potentials",{})
		var kinds:Array=[];var promise:Array=[]
		for resource_variant in catalog.keys():
			var resource:=String(resource_variant)
			var potential:=float(potentials.get(resource,0.0))
			if potential<LAND_FIND_POTENTIAL or not _land_new_kind(resource):continue
			kinds.append(resource);promise.append(potential)
		if kinds.is_empty():continue
		var opened:=register_expedition_occurrence(String(kinds[_weighted(pick,promise)]),point,profile)
		if opened.is_empty():continue
		opened["found_by"]="searchers"
		return opened
	return {}

## A find told once, plainly, to the god's own people (the Chronicle only). A
## new find is a notice; finds told within a year of the last card of finds
## gather on that card, each one quiet line. A richer seam is a quiet line.
func _tell_land_find(entry:Dictionary)->void:
	if WorldSimulation.actor_id!="player":return
	var chronicle:=load("res://scripts/chronicle.gd") as GDScript
	if chronicle==null:return
	var home:=String(WorldSimulation.state.settlement_name)
	if home=="":home="our town"
	var what:=display_name(String(entry.resource)).to_lower()
	var named:=what.left(1).to_upper()+what.substr(1)
	var way:=String(entry.get("way",""))
	var km:=float(entry.get("km",0.0))
	var where:="close by %s" % home if km<1.0 or way=="" else "about %d km %s of %s" % [maxi(1,roundi(km)),way,home]
	var action:={"kind":"section","section":"economy","sub":1}
	var moment:={"kind":"economy","action":action,"key":"land_find:%s:%d:%s" % [String(WorldSimulation.state.resource_settlement_id),int(entry.day),String(entry.deposit_id)]}
	if String(entry.kind)=="richer":
		moment.merge({"tier":"whisper","title":"A richer part of the %s near %s" % [what,home],"text":"A richer part of the %s, %s: about a tenth more from each cutter there." % [what,where]})
	else:
		if bool(entry.get("seen",false)):
			moment.merge({"title":"The %s near %s is measured" % [what,home],"text":"Searchers traced the %s they had seen signs of, %s. It is measured and can be opened for work." % [what,where]})
		else:
			moment.merge({"title":"%s found near %s" % [named,home],"text":"Searchers found %s %s. It is measured and can be opened for work." % [what,where]})
		moment.merge({"tier":"notice","fold_as":"land_find","fold_days":LAND_FOLD_DAYS})
		# Within the year of the last card of finds: one quiet line on it.
		var c:Variant=chronicle.call("data")
		var head:Variant=chronicle.call("_fold_head",c,"land_find","",String(chronicle.call("action_sign",action)),int(WorldSimulation.state.elapsed_days),LAND_FOLD_DAYS)
		if head is Dictionary and not (head as Dictionary).is_empty():moment.text="%s, %s." % [named,where]
	var told:Variant=chronicle.call("record",moment)
	entry["told"]=told is Dictionary and not (told as Dictionary).is_empty()


# --- The land as the screens show it ---------------------------------------------------

## The searched land as the screens show it, in this scope's own numbers
## (read-only: nothing is made or rolled): {settled, cover, target,
## searchers, people, yield (at this cover), applied (as the engine applies
## it today, with an older save's blend), blend_days_left, find_month (the
## month's odds), finds (latest first), plus_ten {searchers, target, yield,
## find_month} with `extra` more searching}.
func land_reading(extra:float=10.0)->Dictionary:
	return WorldSimulation.settlements.with_local_population(func()->Dictionary:return _land_reading(extra))

func _land_reading(extra:float=10.0)->Dictionary:
	var state=WorldSimulation.state
	var kept:Dictionary=state.land_survey
	var land:Dictionary=kept if kept.has("cover") else _land_new_record()
	var day:=int(state.elapsed_days)
	var searchers:=_land_searchers()
	var people:=_land_people()
	var cover:=float(land.get("cover",0.0))
	var settled:=bool(state.settlement_site_committed)
	var from:=int(land.get("blend_from",-1))
	var more:=searchers+extra
	var plus:=land_target(more,people)
	return {"settled":settled,"cover":cover,"target":land_target(searchers,people),"searchers":searchers,"people":people,
		"yield":land_yield(cover),"applied":_land_applied(land,day) if settled else 1.0,
		"blend_days_left":maxi(0,ceili(LAND_BLEND_DAYS-float(day-from))) if from>=0 else 0,
		"find_month":land_find_odds(searchers),"finds":(land.get("finds",[]) as Array).duplicate(true),
		"plus_ten":{"searchers":more,"target":plus,"yield":land_yield(plus),"find_month":land_find_odds(more)}}

## The searched land of the whole people, as the People screen reads every
## task: each lived-in town read in its own scope, its cover, target and
## yields averaged by its people, the searchers summed, and the month's
## chance of at least one find anywhere. Ten more searchers are spread over
## the towns by their people. Read from outside any town's scope; inside
## one, that place's own reading.
func realm_land_reading()->Dictionary:
	var model=WorldSimulation.settlements
	var state=WorldSimulation.state
	if state.player_settlements.is_empty() or String(state.resource_settlement_id)!="" or bool(model._local_population_scope):return land_reading()
	var readings:Array=[]
	for record:Dictionary in model.lived_in():
		if not String(record.get("occupied_by","")).is_empty():continue
		if bool(record.get("primary",false)):readings.append(land_reading(0.0))
		else:readings.append(model.with_city_resources(String(record.get("id","")),func()->Dictionary:return land_reading(0.0)))
	var settled:Array=readings.filter(func(r:Dictionary)->bool:return bool(r.get("settled",false)))
	if settled.is_empty():return land_reading()
	var people:=0.0;var searchers:=0.0
	for r:Dictionary in settled:
		people+=float(r.people)
		searchers+=float(r.searchers)
	var cover:=0.0;var target:=0.0;var applied:=0.0;var more_target:=0.0
	var none:=1.0;var more_none:=1.0;var blend:=0
	for r:Dictionary in settled:
		var share:=float(r.people)/maxf(1.0,people)
		var more:=float(r.searchers)+10.0*share
		cover+=float(r.cover)*share;target+=float(r.target)*share;applied+=float(r.applied)*share
		more_target+=land_target(more,float(r.people))*share
		none*=1.0-float(r.find_month);more_none*=1.0-land_find_odds(more)
		blend=maxi(blend,int(r.blend_days_left))
	return {"settled":true,"towns":settled.size(),"cover":cover,"target":target,"searchers":searchers,"people":people,
		"yield":land_yield(cover),"applied":applied,"blend_days_left":blend,"find_month":1.0-none,"finds":[],
		"plus_ten":{"searchers":searchers+10.0,"target":more_target,"yield":land_yield(more_target),"find_month":1.0-more_none}}

## A month's odds in plain words: "about 1 in 7", "about 6 in 10".
static func odds_words(p:float)->String:
	if p<=0.0005:return "none"
	if p>=0.95:return "almost sure"
	if p>=0.5:return "about %d in 10" % roundi(p*10.0)
	return "about 1 in %d" % maxi(2,roundi(1.0/p))

static func _in_100(value:float)->int:
	return roundi(clampf(value,0.0,1.0)*100.0)

static func _searcher_words(n:float)->String:
	if n<0.05:return "nobody"
	if n<0.5:return "less than one"
	return "%d" % roundi(n)

## Which way the searched land is going, in words: from where it heads
## against where it stands, never from a rounded head count.
static func land_heading(r:Dictionary)->String:
	var cover:=float(r.get("cover",0.0));var target:=float(r.get("target",0.0))
	var searchers:=float(r.get("searchers",0.0))
	if target>cover+LAND_STEADY:return "rising toward %d with %s searching" % [_in_100(target),_searcher_words(searchers)]
	if target<cover-LAND_STEADY:
		if searchers<0.05:return "losing a twentieth of it a year with nobody searching"
		return "losing a twentieth of it a year toward %d with only %s searching" % [_in_100(target),_searcher_words(searchers)]
	if searchers<0.05:return "with nobody searching"
	return "held there by %s searching" % _searcher_words(searchers)

## What cutting and digging get as the engine applies it today; in an older
## save's blend year, also where it is going.
static func land_yield_words(r:Dictionary)->String:
	var line:="×%.2f" % float(r.get("applied",1.0))
	if int(r.get("blend_days_left",0))>0:line+=" today, ×%.2f once the change has settled in %d days" % [float(r.get("yield",1.0)),int(r.blend_days_left)]
	return line

## The searched land in one plain line (the Materials page); "" for a people
## on the road.
func land_words()->String:
	var r:=land_reading()
	if not bool(r.settled):return ""
	return "Searched land %d in 100, %s. Cutting and digging %s (×0.75 on unsearched land, up to ×1.25). A find in the next month: %s." % [_in_100(float(r.cover)),land_heading(r),land_yield_words(r),odds_words(float(r.find_month))]

## What a role does now and what ten more people there would do, in the
## engine's numbers, for the People view: "Survey" (searching the land) and
## "Extraction" (cutting and digging); {} for other roles.
## `settlement_id` names the town read, its land with its own people and
## searchers: "" is the place in scope (the first town when none is). Read
## from outside any town's scope; a town other than the one in scope cannot
## be read from inside another's scope, and gives {}.
## {role, now, plus_ten (plain words), numbers {...}}.
func role_effect(role:String,settlement_id:String="")->Dictionary:
	if role not in ["Survey","Extraction"]:return {}
	if settlement_id=="":return _role_effect_here(role)
	var model=WorldSimulation.settlements
	var record:Dictionary=model.settlement_record(settlement_id)
	if record.is_empty():return {}
	var scope:="" if bool(record.get("primary",false)) else settlement_id
	var current:=String(WorldSimulation.state.resource_settlement_id)
	if scope==current:return _role_effect_here(role)
	if current!="" or bool(model._local_population_scope):return {}
	return model.with_city_resources(settlement_id,func()->Dictionary:return _role_effect_here(role))

func _role_effect_here(role:String)->Dictionary:
	var r:=land_reading()
	var plus:Dictionary=r.plus_ten
	if role=="Survey":
		var now:="The searched land is %d in 100, %s. Cutters and diggers get %s. A find in the next month: %s." % [_in_100(float(r.cover)),land_heading(r),land_yield_words(r),odds_words(float(r.find_month))]
		var ten:="Ten more searching: the land would head to %d in 100 (cutting and digging ×%.2f once there), and a find in the next month would be %s." % [_in_100(float(plus.target)),float(plus.yield),odds_words(float(plus.find_month))]
		return {"role":role,"now":now,"plus_ten":ten,"numbers":r}
	var local:Dictionary=WorldSimulation.settlements.with_local_population(func()->Dictionary:
		return {"cutters":maxf(0.0,WorldSimulation.state.effective_workers("Extraction")),"flows":(WorldSimulation.state.material_metrics as Dictionary).duplicate()})
	var flows:Dictionary=local.flows
	var cutters:=float(local.cutters)
	var per:=float(flows.get("per_cutter",0.0))
	var cut:=float(flows.get("extracted_today",0.0))
	var numbers:={"cutters":cutters,"extracted_today":cut,"per_cutter":per,"land_factor":float(r.applied),"land_yield":float(r.yield),"plus_ten_loads":per*10.0}
	var crew:="Nobody" if cutters<0.5 else "%d" % roundi(cutters)
	var now_words:="%s cut and dig %.1f loads a day; the searched land gives them %s." % [crew,cut,land_yield_words(r)]
	var ten_words:="Ten more would bring in nothing until a deposit is opened for work."
	if per>0.0:ten_words="Ten more would bring in about %.1f more loads a day (%.2f each at today's yield)." % [per*10.0,per]
	return {"role":role,"now":now_words,"plus_ten":ten_words,"numbers":numbers}
