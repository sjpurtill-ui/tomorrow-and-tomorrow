extends Node

var rng := RandomNumberGenerator.new()
var initialized := false
const SURFACE_FRONT_SPACING_KM:=3.0
const MAX_SURFACE_FRONT_RING:=3
const MAX_SURFACE_FRONTS_PER_RESOURCE:=24

# Identification follows observations and existing methods, never campaign age.
# These gates apply to unknown occurrences only; saved recognition is retained.
const RECOGNITION_RULES={
	"Ochre Earth":{"requires_all":["stone_sorting","clay_testing"]},
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
func display_name(resource_name:String)->String:
	return "Plant Fiber" if resource_name=="Fiber Plants" else resource_name

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
	"Ochre Earth":{"family":"Earth","renewable":false,"recognition_year":0,"access":["labor","containers"],"processing":["mineral_pigment_preparation"],"signals":["materials","survey"],"base":0.006}
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
	initialize()
	if WorldSimulation.enabled:
		var origin:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
		preload("res://scripts/civilization_resources.gd").initialize(Vector2(origin.x,origin.z))
	var events: Array[Dictionary] = []
	var method_factors:Dictionary=preload("res://scripts/geoscience_knowledge.gd").factors()
	# Filled only if this city still has an eligible recognition/survey task.
	# Family practice changes during the pass and remains evaluated per deposit.
	var survey_inputs:Dictionary={}
	for deposit in WorldSimulation.state.resource_deposits:
		_ensure_deposit_fields(deposit)
		var resource_name: String = deposit.resource
		if not catalog.has(resource_name):
			continue
		var definition: Dictionary = catalog[resource_name]
		if deposit.stage == "unknown":
			if not recognition_ready(resource_name):continue
			if survey_inputs.is_empty():survey_inputs=_local_survey_inputs()
			var survey_effort := float(survey_inputs.effort) * float(method_factors.get(resource_name,{}).get("recognition",1.0))
			deposit.clues += definition.base * (0.5 + survey_effort + float(survey_inputs.nature) + float(survey_inputs.material)) * _family_literacy(resource_name) * rng.randf_range(0.5, 1.5)
			if deposit.clues >= 1.0:
				deposit.stage = "recognized"
				_gain_practice(resource_name,"recognition",0.12)
				events.append(_event("Resource Indicated", "Evidence suggests %s is present. Its extent and accessibility remain unknown." % resource_name, deposit.id))
		elif deposit.stage == "recognized":
			if survey_inputs.is_empty():survey_inputs=_local_survey_inputs()
			var survey_effort := float(survey_inputs.effort) * float(method_factors.get(resource_name,{}).get("survey",1.0))
			deposit.survey += definition.base * 0.55 * survey_effort * float(survey_inputs.speed) * _family_literacy(resource_name) * rng.randf_range(0.7,1.3)
			if deposit.survey >= 1.0:
				deposit.stage = "surveyed"
				_gain_practice(resource_name,"survey",0.18)
				events.append(_event("Deposit Surveyed", "The extent and conditions of the %s occurrence are now understood." % resource_name, deposit.id))
		elif deposit.stage == "surveyed":
			deposit.access = _calculate_access(deposit, definition, context)
			deposit.blockers = _access_blockers(deposit,definition,context)
			if deposit.access<1.0 and deposit.blockers.is_empty():
				deposit.blockers.append(_access_practice_blocker(definition))
			if deposit.access >= 1.0 and deposit.blockers.is_empty():
				deposit.stage = "accessible"
				events.append(_event("Resource Accessible", "%s can now support organized extraction." % resource_name, deposit.id))
	var flow_events:=_process_material_flow(context)
	events.append_array(flow_events)
	events.append_array(_process_water_flow(context))
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
	var accessible_quality:=0.0
	var nearest_source_km:=INF
	var source_kind:="none"
	var source_id:=""
	var source_origin:="none"
	var origin:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
	for deposit_variant in WorldSimulation.state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))!="Freshwater": continue
		var stage:=String(deposit.get("stage","unknown"))
		if stage not in ["surveyed","accessible","developed"]: continue
		var distance_km:=Vector2(origin.x,origin.z).distance_to(Vector2(deposit.position.x,deposit.position.z))
		deposit["distance_km"]=distance_km
		# Surveyed exposed water is already a collectable geographic feature. Formal
		# access work improves organization; it is not a prerequisite for drinking.
		if stage in ["accessible","developed"] or distance_km<=6.0:
			if distance_km<nearest_source_km:
				nearest_source_km=distance_km
				accessible_quality=float(deposit.get("quality",0.85))
				source_kind="surveyed surface water" if stage=="surveyed" else "organized water source"
				source_id=String(deposit.get("id","freshwater_occurrence"))
				source_origin="recognized_occurrence"
	var hydrology_distance:=float(context.get("surface_water_distance_km",INF))
	if hydrology_distance<=6.0 and hydrology_distance<nearest_source_km:
		nearest_source_km=hydrology_distance
		accessible_quality=1.0
		source_kind=String(context.get("surface_water_kind","visible river or drainage"))
		source_id=String(context.get("surface_water_id","local_surface_hydrology"))
		source_origin="mapped_hydrology"
	var carriers:=WorldSimulation.state.effective_workers("Logistics")
	var food_workers:=WorldSimulation.state.effective_workers("Food")
	# Water fetching is basic household subsistence, not a specialist occupation
	# that vanishes when the player changes a labor slider. People beside exposed
	# surface water can meet their immediate drinking need themselves; assigned
	# Food and Logistics workers create the organized surplus and carry from more
	# distant sources. Sanitation, irrigation, storage and dense urban distribution
	# still depend on knowledge and infrastructure elsewhere in the simulation.
	var collection_workers:=carriers+food_workers*0.22
	var distance_factor:=1.0/maxf(1.0,1.0+nearest_source_km*0.16) if nearest_source_km<INF else 0.0
	var household_access_ratio:=_household_surface_water_access_ratio(nearest_source_km) if accessible_quality>0.0 else 0.0
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
	if distance_km<0.0 or distance_km==INF or distance_km>6.0: return 0.0
	if distance_km<=1.0: return 1.18
	return lerpf(1.18,0.38,clampf((distance_km-1.0)/5.0,0.0,1.0))


# Hydrology is a geographic source, not a fabricated point deposit. This fixed-
# shape snapshot lets map/resource views highlight the actual recognized river
# or drainage that supplies drinking, fishing, and sanitation work.
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

func _calculate_access(deposit: Dictionary, definition: Dictionary, context: Dictionary) -> float:
	if String(deposit.get("resource",""))=="Freshwater":
		# Carrying from exposed surface water needs assigned hands, not years of
		# roadbuilding or advanced hydrological practice.
		return 1.0 if int(WorldSimulation.state.population_allocations.get("Extraction",0))>0 and int(WorldSimulation.state.population_allocations.get("Logistics",0))>0 else 0.0
	var logistics := WorldSimulation.state.effective_workers("Logistics") / 5.0
	var construction := WorldSimulation.state.effective_workers("Construction") / 8.0
	var tools := float(context.get("tools", 0.25))
	var knowledge := 0.0
	for requirement in definition.processing:
		if requirement in WorldSimulation.state.known_discoveries:
			knowledge += 0.3*WorldSimulation.discovery.adoption(String(requirement))
	var access_knowledge:=1.0+WorldSimulation.discovery.effect("route_speed")+WorldSimulation.discovery.effect("mine_safety")*0.5
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

func _next_surface_front(resource:String,source:String,context:Dictionary,minimum_density:float)->Dictionary:
	if not WorldSimulation.context_provider.is_valid():return {}
	var used:Dictionary={}
	for deposit_variant in WorldSimulation.state.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("landscape_source",""))!=source:continue
		used[_surface_front_key(resource,deposit)]=true
	var origin_value:Variant=context.get("origin",WorldSimulation.state.settlement_founded_at)
	var origin:=Vector2(origin_value.x,origin_value.z) if origin_value is Vector3 else Vector2(origin_value.x,origin_value.y)
	var max_ring:=clampi(1+int(WorldSimulation.state.effective_workers("Logistics")/6.0),1,MAX_SURFACE_FRONT_RING)
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
	_ensure_woodland_supply(context)
	_ensure_surface_material_supplies(context)
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
	var extractors:=WorldSimulation.state.effective_workers("Extraction")
	var carriers:=WorldSimulation.state.effective_workers("Logistics")
	var labor_eff:=float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72))
	var storage_priorities:=_storage_gathering_priorities()
	var total_weight:=0.0
	for deposit in material_deposits:
		total_weight+=_extraction_priority(deposit,storage_priorities) if float(deposit.remaining)>0.0 else 0.0
	var extracted_total:=0.0
	for deposit in material_deposits:
		var share:=_extraction_priority(deposit,storage_priorities)/maxf(0.001,total_weight) if float(deposit.remaining)>0.0 else 0.0
		var assigned:=extractors*share
		deposit.workers=roundi(assigned)
		var profile:=_material_profile(String(deposit.resource))
		var knowledge_multiplier:=1.0+WorldSimulation.discovery.effect("extraction_yield")+WorldSimulation.discovery.effect(String(deposit.resource).to_lower().replace(" ","_")+"_yield")
		if String(profile.family)=="metal": knowledge_multiplier+=WorldSimulation.discovery.effect("metal_yield")
		var practice_multiplier:=1.0+minf(0.35,_practice(String(deposit.resource),"extraction")*0.035)
		deposit.daily_yield=assigned*float(profile.base_yield)*float(deposit.quality)*(0.55+float(context.get("tools",0.25))*0.75)*labor_eff*knowledge_multiplier*practice_multiplier*(1.0+WorldSimulation.state.founding_effect("resource_output")+WorldSimulation.progression.effect("extraction_yield"))
		var extracted:=preload("res://scripts/civilization_resources.gd").withdraw(deposit,float(deposit.daily_yield)) if WorldSimulation.enabled else minf(float(deposit.remaining),float(deposit.daily_yield))
		deposit.remaining=float(deposit.remaining)-extracted
		deposit.stock_at_source=float(deposit.stock_at_source)+extracted
		deposit.extracted_today=extracted
		deposit.lifetime_extracted=float(deposit.lifetime_extracted)+extracted
		extracted_total+=extracted
		if extracted>0.0:
			deposit.stage="developed"
			_gain_practice(String(deposit.resource),"extraction",extracted/maxf(1.0,assigned)*0.010)
		if WorldSimulation.enabled and deposit.has("world_key"):
			preload("res://scripts/civilization_resources.gd").renew(deposit,extracted)
		elif String(deposit.get("landscape_source","")) in ["woodland_catchment","plant_fiber_catchment"]:
			# Standing growth returns slowly even when cutting is paused. It stays
			# at the source until labor harvests and hauls it, and cannot exceed the
			# original carrying capacity of this local woodland.
			var capacity:=float(deposit.initial_amount)
			var recovery:=0.001 if String(deposit.landscape_source)=="plant_fiber_catchment" else 0.00003
			deposit.remaining=minf(capacity,float(deposit.remaining)+capacity*recovery)
		elif bool(catalog[String(deposit.resource)].renewable):
			deposit.remaining=float(deposit.remaining)+minf(extracted*0.35,2.0)
	# Deliver shipments whose real travel time has elapsed.
	var delivered_total:=0.0
	for deposit in material_deposits:
		var still_moving:Array=[]
		for shipment_variant in deposit.shipments:
			var shipment:Dictionary=shipment_variant
			if int(shipment.arrival_day)<=int(WorldSimulation.state.elapsed_days):
				var quantity:=float(shipment.quantity)
				WorldSimulation.state.resource_stockpiles[String(deposit.resource)]=float(WorldSimulation.state.resource_stockpiles.get(String(deposit.resource),0.0))+quantity
				deposit.delivered_today=float(deposit.delivered_today)+quantity
				deposit.lifetime_delivered=float(deposit.lifetime_delivered)+quantity
				delivered_total+=quantity
			else: still_moving.append(shipment)
		deposit.shipments=still_moving
	# Carriers are distributed by waiting bulk and priority.  Distance lowers daily
	# throughput and separately creates a visible time-in-transit delay.
	var haul_weight:=0.0
	storage_priorities=_storage_gathering_priorities()
	for deposit in material_deposits:
		haul_weight+=float(deposit.stock_at_source)*_deposit_priority(deposit,storage_priorities)
	for deposit in material_deposits:
		var waiting:=float(deposit.stock_at_source)
		if waiting<=0.0001: continue
		var share:=waiting*_deposit_priority(deposit,storage_priorities)/maxf(0.001,haul_weight)
		var assigned_carriers:=carriers*share
		var profile:=_material_profile(String(deposit.resource))
		var route_factor:=0.34+float(deposit.route)*0.66+WorldSimulation.discovery.effect("route_speed")
		var distance_factor:=1.0+float(deposit.distance_km)/10.0
		var haul_capacity:=assigned_carriers*5.0/maxf(0.2,float(profile.bulk))*route_factor*labor_eff*(1.0+WorldSimulation.discovery.effect("haul_capacity"))/distance_factor
		var dispatched:=minf(waiting,haul_capacity)
		if dispatched>0.0:
			deposit.stock_at_source=waiting-dispatched
			var speed_km_day:=maxf(1.0,8.0*route_factor*(1.0+WorldSimulation.discovery.effect("travel_speed")))
			deposit.travel_days=maxi(1,ceili(float(deposit.distance_km)/speed_km_day))
			deposit.shipments.append({"quantity":dispatched,"departure_day":int(WorldSimulation.state.elapsed_days),"arrival_day":int(WorldSimulation.state.elapsed_days)+int(deposit.travel_days)})
		_update_deposit_bottleneck(deposit,carriers,events)
	var loss_report:=_apply_material_storage_losses(events)
	var lost_total:=float(loss_report.total)
	var at_source:=0.0
	var in_transit:=0.0
	for deposit in material_deposits:
		at_source+=float(deposit.stock_at_source)
		for shipment_variant in deposit.shipments: in_transit+=float((shipment_variant as Dictionary).quantity)
	var capacities:=_storage_capacities()
	var stored_bulk:=_stored_bulk()
	var capacity_total:=0.0
	for amount in capacities.values(): capacity_total+=float(amount)
	var active_shipments:=0
	var workable_occurrences:=0
	for deposit in material_deposits:
		active_shipments+=(deposit.get("shipments",[]) as Array).size()
		if not deposit_exhausted(deposit):workable_occurrences+=1
	WorldSimulation.state.material_metrics={"extracted_today":extracted_total,"delivered_today":delivered_total,"lost_today":lost_total,"losses_by_resource":loss_report.by_resource,"storage_used_by_type":loss_report.used_by_type,"at_source":at_source,"in_transit":in_transit,"stored_bulk":stored_bulk,"storage_capacity":capacity_total,"flow_ratio":delivered_total/maxf(0.01,extracted_total),"capacities":capacities,"extraction_workers":extractors,"logistics_workers":carriers,"research_workers":WorldSimulation.state.effective_workers("Knowledge"),"labor_efficiency":labor_eff,"accessible_occurrences":workable_occurrences,"active_shipments":active_shipments,"bounded":true}
	WorldSimulation.state.material_history.append({"day":int(WorldSimulation.state.elapsed_days),"extracted":extracted_total,"delivered":delivered_total,"lost":lost_total,"at_source":at_source,"in_transit":in_transit,"stored":stored_bulk})
	if WorldSimulation.state.material_history.size()>370: WorldSimulation.state.material_history.pop_front()
	return events

func _ensure_deposit_fields(deposit:Dictionary)->void:
	var defaults={"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Not yet accessible","last_reported_bottleneck":""}
	for key in defaults:
		if not deposit.has(key): deposit[key]=defaults[key].duplicate() if defaults[key] is Array else defaults[key]

func _is_material_resource(resource_name:String)->bool:
	# Household craft stocks represent maintained tools/containers in use. Their
	# owner applies material-specific wear; raw-yard loss must not charge it again.
	return resource_name not in ["Freshwater","Fertile Soil","Game"] and resource_name not in preload("res://scripts/opening_craft_practice.gd").DECAY

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
	if MATERIAL_PROFILES.has(resource_name): return MATERIAL_PROFILES[resource_name]
	if "Ore" in resource_name or resource_name in ["Graphite","Lead Ore"]: return ORE_PROFILE
	return MINERAL_PROFILE

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
	for shipment_variant in deposit.get("shipments",[]): total+=float((shipment_variant as Dictionary).get("quantity",0.0))
	return total

func deposit_exhausted(deposit:Dictionary)->bool:
	if String(deposit.get("stage","")) not in ["accessible","developed"]:return false
	if not deposit.has("remaining"):return false
	return float(deposit.get("remaining",0.0))<=0.001 and float(deposit.get("stock_at_source",0.0))<=0.001 and in_transit_for(deposit)<=0.001

static var gathering_recipe_reserves:Dictionary={}

func _gathering_startup_reserves()->Dictionary:
	# Fixed recipe metadata only. Eligibility is read from this society each time.
	if gathering_recipe_reserves.is_empty():
		for recipe:Dictionary in preload("res://scripts/civilian_industry.gd").PRODUCTS.values():
			var gate:=String(recipe.get("gate",""))
			if not gathering_recipe_reserves.has(gate):gathering_recipe_reserves[gate]={}
			var amounts:Dictionary=recipe.get("materials",{}).duplicate()
			for resource_name:String in recipe.get("tooling",{}):amounts[resource_name]=float(amounts.get(resource_name,0))+float(recipe.tooling[resource_name])
			for resource_name:String in amounts:
				gathering_recipe_reserves[gate][resource_name]=maxf(float(gathering_recipe_reserves[gate].get(resource_name,0)),float(amounts[resource_name])*2.0)
	var result:Dictionary={}
	for gate:String in WorldSimulation.state.known_discoveries:
		for resource_name:String in gathering_recipe_reserves.get(gate,{}):
			result[resource_name]=maxf(float(result.get(resource_name,0)),float(gathering_recipe_reserves[gate][resource_name]))
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

func _deposit_priority(deposit:Dictionary,storage_priorities:Dictionary={})->float:
	var resource_name:=String(deposit.resource)
	var named:=float(WorldSimulation.state.resource_priorities.get(resource_name,1.0))
	if resource_name=="Stone":
		# A civic stone drive redirects existing extractors and carriers; it does
		# not create workers, reveal deposits, or produce stone from nothing.
		named*=1.0+maxf(0.0,WorldSimulation.consequences.policy_effect("stone_priority"))*3.0
	var stored:=float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))
	# Once a local store is well supplied, release its share of the same finite
	# workforce. The previous floor of 1 kept most workers gathering already
	# overflowing materials while essential timber had no stock at all.
	var working_stock:=maxf(20.0,WorldSimulation.state.population_exact*.08)
	var scarcity:=2.0/(1.0+maxf(0.0,stored)/working_stock)
	return maxf(0.05,named*scarcity*float(deposit.quality)/(1.0+float(deposit.distance_km)/45.0))*float(storage_priorities.get(resource_name,1.0))

func _extraction_priority(deposit:Dictionary,storage_priorities:Dictionary={})->float:
	var reserve:=float(deposit.get("remaining",0.0))
	var working_reserve:=maxf(1.0,float(deposit.get("initial_amount",1.0))*0.05)
	return _deposit_priority(deposit,storage_priorities)*clampf(reserve/working_reserve,0.0,1.0)

func _storage_capacities()->Dictionary:
	var pop:=WorldSimulation.state.population_exact
	# Capacity comes from named portable assets or completed works. Bare ground can
	# hold a small outdoor pile, but it is not dry, sealed, covered, or secure.
	var result={"yard":maxf(12.0,pop*0.10),"dry":float(WorldSimulation.state.founding_manifest.get("dry_storage_bulk",0.0)),"covered":float(WorldSimulation.state.founding_manifest.get("covered_storage_bulk",0.0)),"sealed":float(WorldSimulation.state.founding_manifest.get("sealed_storage_bulk",0.0)),"secure":float(WorldSimulation.state.founding_manifest.get("secure_storage_bulk",0.0))}
	if "Gathering Yard" in WorldSimulation.state.settlement_completed: result.yard+=320.0
	if "Open Work Area" in WorldSimulation.state.settlement_completed: result.yard+=160.0; result.covered+=55.0; result.secure+=20.0
	if "Lean-to Shelters" in WorldSimulation.state.settlement_completed: result.dry+=90.0
	if "Storage Pits" in WorldSimulation.state.settlement_completed: result.covered+=140.0; result.sealed+=25.0
	# Persistent storage plots are operational infrastructure, not decoration. Their
	# condition and staffing determine how much of the nominal space can be used.
	for plot in WorldSimulation.state.settlement_plots:
		if String(plot.get("land_use",""))!="storage" or String(plot.get("status","")) not in ["active","stressed","damaged"]: continue
		var staffing:=clampf(float(plot.get("worker_count",0))/maxf(1.0,float(plot.get("worker_capacity",1))),0.15,1.0)
		var usable:=float(plot.get("storage_capacity",0.0))*clampf(float(plot.get("condition",0.0)),0.10,1.0)*staffing
		var form:=String(plot.get("form",""))
		if "earthen" in form or "pit" in form:
			result.covered+=usable*0.62
			result.sealed+=usable*0.38
		elif "stone" in form:
			result.covered+=usable*0.72
			result.secure+=usable*0.28
		else:
			result.dry+=usable*0.58
			result.covered+=usable*0.42
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
		var decay:=amount*maxf(0.0,float(profile.loss)+WorldSimulation.discovery.effect("storage_loss"))
		var available_bulk:=maxf(0.0,float(capacities[store])-float(used[store]))
		var overflow_units:=maxf(0.0,amount-available_bulk/bulk)
		# Exposed stone/flint is durable. An overfull yard adds handling loss,
		# not the rapid spoilage used for organic or containment-dependent stock.
		var exposure_rate:=0.0005 if String(profile.family)=="mineral" and store=="yard" else 0.035
		var overflow_loss:=overflow_units*exposure_rate
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
func _local_survey_inputs()->Dictionary:
	return {"effort":WorldSimulation.state.effective_workers("Survey") / 6.0*WorldSimulation.consequences.survey_factor(),"nature":float(WorldSimulation.state.research_allocations.get("ecology",0))*.15,"material":float(WorldSimulation.state.research_allocations.get("production",0))*.12,"speed":1.0+WorldSimulation.discovery.effect("survey_speed")}
