extends Node

var rng := RandomNumberGenerator.new()
var initialized := false

const FOUNDING_SURFACE_RESOURCES:=["Timber","Stone","Fertile Soil","Game","Fiber Plants"]

func reset_for_new_world()->void:
	initialized=false
	rng=RandomNumberGenerator.new()

# Internal-only knowledge about resources across the first two centuries.
# UI receives discovered deposits and present constraints, never this catalog.
var catalog := {
	"Timber":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["cordage","joinery"],"signals":["survey","construction"],"base":0.030},
	"Freshwater":{"family":"Water","renewable":true,"recognition_year":0,"access":["labor"],"processing":["clean_water","well_siting"],"signals":["survey","food"],"base":0.035},
	"Stone":{"family":"Mineral","renewable":false,"recognition_year":0,"access":["labor"],"processing":["joinery"],"signals":["survey","construction"],"base":0.026},
	"Fertile Soil":{"family":"Land","renewable":true,"recognition_year":0,"access":["labor"],"processing":["seed_selection"],"signals":["food","nature"],"base":0.028},
	"Game":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["seasonal_patterns"],"signals":["food","exploration"],"base":0.030},
	"Fiber Plants":{"family":"Organic","renewable":true,"recognition_year":0,"access":["labor"],"processing":["cordage"],"signals":["food","survey"],"base":0.024},
	"Clay":{"family":"Earth","renewable":false,"recognition_year":1,"access":["labor"],"processing":["clay_shaping"],"signals":["survey","materials"],"base":0.018},
	"Flint":{"family":"Mineral","renewable":false,"recognition_year":1,"access":["labor"],"processing":[],"signals":["survey","crafting"],"base":0.016},
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
	"Graphite":{"family":"Mineral","renewable":false,"recognition_year":145,"access":["mine","specialists"],"processing":["standard_measures"],"signals":["materials","information"],"base":0.0008}
}

func initialize() -> void:
	if initialized:
		return
	rng.seed = GameState.world_seed ^ 0x4f1bbcdc
	initialized = true
	var focus_start:Dictionary=GameState.founding_focus_definition().get("starting",{})
	var food_days:=30.0*(1.0+float(focus_start.get("food_days_ratio",0.0)))
	var material_ratio:=1.0+float(focus_start.get("starting_materials",0.0))
	if GameState.founding_manifest.is_empty():
		GameState.founding_manifest={"portable_shelters":30,"food_storage_rations":GameState.population_exact*maxf(30.0,food_days),"dry_storage_bulk":10.0,"covered_storage_bulk":4.0,"sealed_storage_bulk":1.0,"secure_storage_bulk":1.0,"water_vessel_days":3.0}
	if GameState.resource_stockpiles.is_empty():
		# The convoy arrives with three days in portable vessels, not an abstract
		# permanent water supply.  Continued survival requires a reachable source.
		GameState.resource_stockpiles = {"Food":GameState.population_exact*food_days, "Freshwater":GameState.population_exact*3.0, "Timber":12.0*material_ratio, "Stone":0.0, "Clay":0.0, "Fiber Plants":10.0*material_ratio}

func register_local_occurrences(sites: Array[Dictionary], terrain: String) -> void:
	initialize()
	if not GameState.resource_deposits.is_empty():
		return
	for i in sites.size():
		var site := sites[i]
		var resource_name: String = site.type
		if resource_name == "Fertile": resource_name = "Fertile Soil"
		var quality := rng.randf_range(0.55, 1.35)
		var amount := rng.randf_range(600.0, 4000.0)
		var deposit:=_deposit(resource_name,site.position,quality,amount,i)
		# Founders do not arrive unable to identify trees, exposed stone, game, or
		# usable soil.  A feature inside their actually charted starting ground is
		# recognized by kind; survey is still required to learn quality, extent,
		# access, and sustainable output.  Nothing beyond the fog is leaked.
		if bool(site.get("initially_observed",false)):
			_seed_founding_surface_recognition(deposit)
		GameState.resource_deposits.append(deposit)
	var possible := _terrain_occurrences(terrain)
	for resource_name in possible:
		if rng.randf() < 0.48:
			var position := Vector3(rng.randf_range(-38, 38), 0, rng.randf_range(-24, 24))
			GameState.resource_deposits.append(_deposit(resource_name, position, rng.randf_range(0.45, 1.5), rng.randf_range(800, 12000), GameState.resource_deposits.size()))

func _deposit(resource_name: String, position: Vector3, quality: float, amount: float, index: int) -> Dictionary:
	# Exposed surface water is directly observable; a deep aquifer remains hidden.
	var initial_stage:="surveyed" if resource_name=="Freshwater" else "unknown"
	return {"id":"%s_%d" % [resource_name.to_snake_case(), index], "resource":resource_name, "position":position, "quality":quality, "remaining":amount, "initial_amount":amount, "stage":initial_stage, "clues":1.0 if initial_stage=="surveyed" else 0.0, "survey":1.0 if initial_stage=="surveyed" else 0.0, "access":0.0, "blockers":[], "development":0.0, "route":0.0, "workers":0,"daily_yield":0.0,"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Access not organized","last_reported_bottleneck":""}


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
	initialize()
	var events: Array[Dictionary] = []
	var year := int(GameState.elapsed_days / 365.0)
	for deposit in GameState.resource_deposits:
		_ensure_deposit_fields(deposit)
		var resource_name: String = deposit.resource
		if not catalog.has(resource_name):
			continue
		var definition: Dictionary = catalog[resource_name]
		if year < definition.recognition_year:
			continue
		if deposit.stage == "unknown":
			var survey_effort := float(GameState.population_allocations.get("Survey", 0)) / 6.0*ConsequenceEngine.survey_factor()
			var nature_focus := float(GameState.research_allocations.get("ecology", 0)) * 0.15
			var material_focus := float(GameState.research_allocations.get("production", 0)) * 0.12
			deposit.clues += definition.base * (0.5 + survey_effort + nature_focus + material_focus) * _family_literacy(resource_name) * rng.randf_range(0.5, 1.5)
			if deposit.clues >= 1.0:
				deposit.stage = "recognized"
				_gain_practice(resource_name,"recognition",0.12)
				events.append(_event("Resource Indicated", "Evidence suggests %s is present. Its extent and accessibility remain unknown." % resource_name, deposit.id))
		elif deposit.stage == "recognized":
			var survey_effort := float(GameState.population_allocations.get("Survey",0)) / 6.0*ConsequenceEngine.survey_factor()
			deposit.survey += definition.base * 0.55 * survey_effort * (1.0+DiscoverySystem.effect("survey_speed")) * _family_literacy(resource_name) * rng.randf_range(0.7,1.3)
			if deposit.survey >= 1.0:
				deposit.stage = "surveyed"
				_gain_practice(resource_name,"survey",0.18)
				events.append(_event("Deposit Surveyed", "The extent and conditions of the %s occurrence are now understood." % resource_name, deposit.id))
		elif deposit.stage == "surveyed":
			deposit.access = _calculate_access(deposit, definition, context)
			deposit.blockers = _access_blockers(deposit,definition,context)
			if deposit.access >= 1.0 and deposit.blockers.is_empty():
				deposit.stage = "accessible"
				events.append(_event("Resource Accessible", "%s can now support organized extraction." % resource_name, deposit.id))
	var flow_events:=_process_material_flow(context)
	events.append_array(flow_events)
	events.append_array(_process_water_flow(context))
	for event in events:
		GameState.resource_events.push_front(event)
	if GameState.resource_events.size()>120: GameState.resource_events.resize(120)
	return events

func _process_water_flow(context:Dictionary={})->Array[Dictionary]:
	var events:Array[Dictionary]=[]
	var population:=maxf(1.0,GameState.population_exact)
	var required:=population
	var accessible_quality:=0.0
	var nearest_source_km:=INF
	var source_kind:="none"
	var source_id:=""
	var source_origin:="none"
	var origin:Vector3=context.get("origin",GameState.settlement_founded_at)
	for deposit_variant in GameState.resource_deposits:
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
	var carriers:=float(GameState.population_allocations.get("Logistics",0))
	var food_workers:=float(GameState.population_allocations.get("Food",0))
	# Water fetching is basic subsistence work. Food workers cover an emergency
	# collection floor; Logistics controls the organized surplus. This prevents a
	# society from ignoring a river and dying solely because the player did not yet
	# understand that water was hidden under a different allocation label.
	var collection_workers:=carriers+food_workers*0.22
	var distance_factor:=1.0/maxf(1.0,1.0+nearest_source_km*0.16) if nearest_source_km<INF else 0.0
	var collection_capacity:=collection_workers*28.0*clampf(float(GameState.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)*distance_factor
	var flow_factor:=clampf(0.75+accessible_quality*0.25,0.0,1.08)
	var collected:=minf(required*1.35,collection_capacity)*flow_factor if accessible_quality>0.0 else 0.0
	var portable_days:=float(GameState.founding_manifest.get("water_vessel_days",3.0))
	if "Storage Pits" in GameState.settlement_completed: portable_days+=2.0
	if "Open Work Area" in GameState.settlement_completed: portable_days+=1.0+DiscoverySystem.effect("container_capacity")*2.0
	var capacity:=population*portable_days
	var stored_before:=maxf(0.0,float(GameState.resource_stockpiles.get("Freshwater",0.0)))
	var available:=minf(capacity,stored_before+collected)
	var consumed:=minf(required,available)
	var stored:=maxf(0.0,available-consumed)
	GameState.resource_stockpiles["Freshwater"]=stored
	var intake:=clampf(consumed/maxf(0.01,required),0.0,1.0)
	GameState.water_metrics={"stored":stored,"capacity":capacity,"collected_today":collected,"required_today":required,"consumed_today":consumed,"intake_ratio":intake,"days":stored/maxf(0.01,required),"source_accessible":accessible_quality>0.0,"source_distance_km":nearest_source_km if nearest_source_km<INF else -1.0,"source_kind":source_kind,"source_id":source_id,"source_origin":source_origin,"recognized":accessible_quality>0.0,"renewable":accessible_quality>0.0,"supports_drinking":accessible_quality>0.0,"supports_food_gathering":accessible_quality>0.0,"collection_workers":collection_workers}
	GameState.water_history.append({"day":int(GameState.elapsed_days),"stored":stored,"collected":collected,"required":required,"consumed":consumed,"intake_ratio":intake,"source_distance_km":nearest_source_km if nearest_source_km<INF else -1.0,"source_id":source_id,"source_origin":source_origin})
	if GameState.water_history.size()>370: GameState.water_history.pop_front()
	if intake<0.98:
		events.append(_event("Water Shortfall","Only %d%% of today's drinking-water requirement was met. Assign carriers and secure an accessible freshwater source." % roundi(intake*100.0),"Freshwater"))
	return events


# Hydrology is a geographic source, not a fabricated point deposit. This fixed-
# shape snapshot lets map/resource views highlight the actual recognized river
# or drainage that supplies drinking, fishing, and sanitation work.
func water_access_snapshot(context:Dictionary={})->Dictionary:
	var water:Dictionary=GameState.water_metrics
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
		return 1.0 if int(GameState.population_allocations.get("Extraction",0))>0 and int(GameState.population_allocations.get("Logistics",0))>0 else 0.0
	var logistics := float(GameState.population_allocations.get("Logistics", 0)) / 5.0
	var construction := float(GameState.population_allocations.get("Construction", 0)) / 8.0
	var tools := float(context.get("tools", 0.25))
	var knowledge := 0.0
	for requirement in definition.processing:
		if requirement in GameState.known_discoveries:
			knowledge += 0.3*DiscoverySystem.adoption(String(requirement))
	var access_knowledge:=1.0+DiscoverySystem.effect("route_speed")+DiscoverySystem.effect("mine_safety")*0.5
	deposit.route = minf(1.0, deposit.route + 0.002 * construction * logistics*float(GameState.simulation_metrics.get("labor_efficiency",0.72))*access_knowledge)
	return deposit.route * 0.45 + tools * 0.25 + knowledge + 0.15+minf(0.18,_practice(resource_name_from(deposit),"survey")*0.04)

func _access_blockers(deposit: Dictionary, definition: Dictionary, context: Dictionary) -> Array[String]:
	var blockers: Array[String] = []
	for requirement in definition.access:
		if requirement == "labor" and int(GameState.population_allocations.get("Extraction",0)) <= 0:
			blockers.append("no extraction labor assigned")
		elif requirement == "logistics" and int(GameState.population_allocations.get("Logistics",0)) < 4:
			blockers.append("insufficient logistics capacity")
		elif requirement == "route" and float(deposit.route) < 0.65:
			blockers.append("no usable access route")
		elif requirement == "tools" and float(context.get("tools",0.25)) < 0.5:
			blockers.append("tools are inadequate")
		elif requirement == "specialists" and int(GameState.population_allocations.get("Knowledge",0)) < 5:
			blockers.append("specialist knowledge is unavailable")
		elif requirement == "mine" and (float(deposit.route) < 0.8 or int(GameState.population_allocations.get("Construction",0)) < 10):
			blockers.append("mining works have not been developed")
		elif requirement == "ventilation":
			blockers.append("safe underground ventilation is unknown")
		elif requirement == "containers" and "clay_shaping" not in GameState.known_discoveries:
			blockers.append("suitable containers are unavailable")
		elif requirement == "well_siting" and "well_siting" not in GameState.known_discoveries:
			blockers.append("deep-water siting is not understood")
		elif requirement == "lifting":
			blockers.append("deep lifting machinery is unavailable")
	return blockers

func _process_material_flow(context:Dictionary)->Array[Dictionary]:
	var events:Array[Dictionary]=[]
	var material_deposits:Array[Dictionary]=[]
	var origin:Vector3=context.get("origin",GameState.settlement_founded_at)
	for deposit in GameState.resource_deposits:
		deposit.extracted_today=0.0
		deposit.delivered_today=0.0
		if String(deposit.stage) not in ["accessible","developed"]: continue
		if not _is_material_resource(String(deposit.resource)): continue
		deposit.distance_km=Vector2(origin.x,origin.z).distance_to(Vector2(deposit.position.x,deposit.position.z))
		material_deposits.append(deposit)
	var extractors:=float(GameState.population_allocations.get("Extraction",0))
	var carriers:=float(GameState.population_allocations.get("Logistics",0))
	var labor_eff:=float(GameState.simulation_metrics.get("labor_efficiency",0.72))
	var total_weight:=0.0
	for deposit in material_deposits:
		total_weight+=_deposit_priority(deposit)
	var extracted_total:=0.0
	for deposit in material_deposits:
		var share:=_deposit_priority(deposit)/maxf(0.001,total_weight)
		var assigned:=extractors*share
		deposit.workers=roundi(assigned)
		var profile:=_material_profile(String(deposit.resource))
		var knowledge_multiplier:=1.0+DiscoverySystem.effect("extraction_yield")+DiscoverySystem.effect(String(deposit.resource).to_lower().replace(" ","_")+"_yield")
		if String(profile.family)=="metal": knowledge_multiplier+=DiscoverySystem.effect("metal_yield")
		var practice_multiplier:=1.0+minf(0.35,_practice(String(deposit.resource),"extraction")*0.035)
		deposit.daily_yield=assigned*float(profile.base_yield)*float(deposit.quality)*(0.55+float(context.get("tools",0.25))*0.75)*labor_eff*knowledge_multiplier*practice_multiplier*(1.0+GameState.founding_effect("resource_output")+ProgressionSystem.effect("extraction_yield"))
		var extracted:=minf(float(deposit.remaining),float(deposit.daily_yield))
		deposit.remaining=float(deposit.remaining)-extracted
		deposit.stock_at_source=float(deposit.stock_at_source)+extracted
		deposit.extracted_today=extracted
		deposit.lifetime_extracted=float(deposit.lifetime_extracted)+extracted
		extracted_total+=extracted
		if extracted>0.0:
			deposit.stage="developed"
			_gain_practice(String(deposit.resource),"extraction",extracted/maxf(1.0,assigned)*0.010)
		if bool(catalog[String(deposit.resource)].renewable):
			deposit.remaining=float(deposit.remaining)+minf(extracted*0.35,2.0)
	# Deliver shipments whose real travel time has elapsed.
	var delivered_total:=0.0
	for deposit in material_deposits:
		var still_moving:Array=[]
		for shipment_variant in deposit.shipments:
			var shipment:Dictionary=shipment_variant
			if int(shipment.arrival_day)<=int(GameState.elapsed_days):
				var quantity:=float(shipment.quantity)
				GameState.resource_stockpiles[String(deposit.resource)]=float(GameState.resource_stockpiles.get(String(deposit.resource),0.0))+quantity
				deposit.delivered_today=float(deposit.delivered_today)+quantity
				deposit.lifetime_delivered=float(deposit.lifetime_delivered)+quantity
				delivered_total+=quantity
			else: still_moving.append(shipment)
		deposit.shipments=still_moving
	# Carriers are distributed by waiting bulk and priority.  Distance lowers daily
	# throughput and separately creates a visible time-in-transit delay.
	var haul_weight:=0.0
	for deposit in material_deposits:
		haul_weight+=float(deposit.stock_at_source)*_deposit_priority(deposit)
	for deposit in material_deposits:
		var waiting:=float(deposit.stock_at_source)
		if waiting<=0.0001: continue
		var share:=waiting*_deposit_priority(deposit)/maxf(0.001,haul_weight)
		var assigned_carriers:=carriers*share
		var profile:=_material_profile(String(deposit.resource))
		var route_factor:=0.34+float(deposit.route)*0.66+DiscoverySystem.effect("route_speed")
		var distance_factor:=1.0+float(deposit.distance_km)/10.0
		var haul_capacity:=assigned_carriers*5.0/maxf(0.2,float(profile.bulk))*route_factor*labor_eff*(1.0+DiscoverySystem.effect("haul_capacity"))/distance_factor
		var dispatched:=minf(waiting,haul_capacity)
		if dispatched>0.0:
			deposit.stock_at_source=waiting-dispatched
			var speed_km_day:=maxf(1.0,8.0*route_factor*(1.0+DiscoverySystem.effect("travel_speed")))
			deposit.travel_days=maxi(1,ceili(float(deposit.distance_km)/speed_km_day))
			deposit.shipments.append({"quantity":dispatched,"departure_day":int(GameState.elapsed_days),"arrival_day":int(GameState.elapsed_days)+int(deposit.travel_days)})
		_update_deposit_bottleneck(deposit,carriers,events)
	var lost_total:=_apply_material_storage_losses(events)
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
	for deposit in material_deposits: active_shipments+=(deposit.get("shipments",[]) as Array).size()
	GameState.material_metrics={"extracted_today":extracted_total,"delivered_today":delivered_total,"lost_today":lost_total,"at_source":at_source,"in_transit":in_transit,"stored_bulk":stored_bulk,"storage_capacity":capacity_total,"flow_ratio":delivered_total/maxf(0.01,extracted_total),"capacities":capacities,"extraction_workers":extractors,"logistics_workers":carriers,"research_workers":float(GameState.population_allocations.get("Knowledge",0)),"labor_efficiency":labor_eff,"accessible_occurrences":material_deposits.size(),"active_shipments":active_shipments,"bounded":true}
	GameState.material_history.append({"day":int(GameState.elapsed_days),"extracted":extracted_total,"delivered":delivered_total,"lost":lost_total,"at_source":at_source,"in_transit":in_transit,"stored":stored_bulk})
	if GameState.material_history.size()>370: GameState.material_history.pop_front()
	return events

func _ensure_deposit_fields(deposit:Dictionary)->void:
	var defaults={"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Not yet accessible","last_reported_bottleneck":""}
	for key in defaults:
		if not deposit.has(key): deposit[key]=defaults[key].duplicate() if defaults[key] is Array else defaults[key]

func _is_material_resource(resource_name:String)->bool:
	return resource_name not in ["Freshwater","Fertile Soil","Game","Medicinal Plants"]

func _material_profile(resource_name:String)->Dictionary:
	var profiles={
		"Timber":{"family":"organic","bulk":1.35,"store":"yard","loss":0.0012,"base_yield":0.34},
		"Fiber Plants":{"family":"organic","bulk":0.45,"store":"dry","loss":0.0035,"base_yield":0.42},
		"Clay":{"family":"earth","bulk":1.25,"store":"covered","loss":0.0010,"base_yield":0.30},
		"Fine Sand":{"family":"earth","bulk":1.35,"store":"covered","loss":0.0006,"base_yield":0.31},
		"Peat":{"family":"fuel","bulk":0.90,"store":"dry","loss":0.0022,"base_yield":0.26},
		"Coal":{"family":"fuel","bulk":1.10,"store":"yard","loss":0.0003,"base_yield":0.18},
		"Bitumen":{"family":"chemical","bulk":0.85,"store":"sealed","loss":0.0020,"base_yield":0.16},
		"Salt":{"family":"mineral","bulk":0.80,"store":"dry","loss":0.0018,"base_yield":0.24},
		"Sulfur":{"family":"chemical","bulk":0.75,"store":"sealed","loss":0.0012,"base_yield":0.12},
		"Nitrates":{"family":"chemical","bulk":0.70,"store":"dry","loss":0.0025,"base_yield":0.10},
		"Coin":{"family":"metal","bulk":0.05,"store":"secure","loss":0.00005,"base_yield":0.0}
	}
	if profiles.has(resource_name): return profiles[resource_name]
	if "Ore" in resource_name or resource_name in ["Graphite","Lead Ore"]: return {"family":"metal","bulk":1.55,"store":"secure","loss":0.0002,"base_yield":0.14}
	return {"family":"mineral","bulk":1.65,"store":"yard","loss":0.00015,"base_yield":0.24}

func material_profile(resource_name:String)->Dictionary:
	return _material_profile(resource_name).duplicate(true)

func storage_capacities()->Dictionary:
	return _storage_capacities().duplicate(true)

func stored_bulk()->float:
	return _stored_bulk()


func resource_workforce_snapshot()->Dictionary:
	var metrics:Dictionary=GameState.material_metrics
	var extractors:=maxf(0.0,float(metrics.get("extraction_workers",GameState.population_allocations.get("Extraction",0))))
	var carriers:=maxf(0.0,float(metrics.get("logistics_workers",GameState.population_allocations.get("Logistics",0))))
	var researchers:=maxf(0.0,float(metrics.get("research_workers",GameState.population_allocations.get("Knowledge",0))))
	return {
		"population":GameState.population_total,"extractors":extractors,"carriers":carriers,"researchers":researchers,
		"extracted_today":float(metrics.get("extracted_today",0.0)),"delivered_today":float(metrics.get("delivered_today",0.0)),
		"per_extractor_output":float(metrics.get("extracted_today",0.0))/maxf(1.0,extractors),
		"labor_efficiency":float(metrics.get("labor_efficiency",GameState.simulation_metrics.get("labor_efficiency",0.72))),
		"accessible_occurrences":int(metrics.get("accessible_occurrences",0)),"active_shipments":int(metrics.get("active_shipments",0)),
		"bounded":true
	}

func in_transit_for(deposit:Dictionary)->float:
	var total:=0.0
	for shipment_variant in deposit.get("shipments",[]): total+=float((shipment_variant as Dictionary).get("quantity",0.0))
	return total

func _deposit_priority(deposit:Dictionary)->float:
	var named:=float(GameState.resource_priorities.get(String(deposit.resource),1.0))
	var stored:=float(GameState.resource_stockpiles.get(String(deposit.resource),0.0))
	var scarcity:=1.0+1.0/(1.0+stored/20.0)
	return maxf(0.05,named*scarcity*float(deposit.quality)/(1.0+float(deposit.distance_km)/45.0))

func _storage_capacities()->Dictionary:
	var pop:=GameState.population_exact
	# Capacity comes from named portable assets or completed works. Bare ground can
	# hold a small outdoor pile, but it is not dry, sealed, covered, or secure.
	var result={"yard":maxf(12.0,pop*0.10),"dry":float(GameState.founding_manifest.get("dry_storage_bulk",0.0)),"covered":float(GameState.founding_manifest.get("covered_storage_bulk",0.0)),"sealed":float(GameState.founding_manifest.get("sealed_storage_bulk",0.0)),"secure":float(GameState.founding_manifest.get("secure_storage_bulk",0.0))}
	if "Gathering Yard" in GameState.settlement_completed: result.yard+=320.0
	if "Open Work Area" in GameState.settlement_completed: result.yard+=160.0; result.covered+=55.0; result.secure+=20.0
	if "Lean-to Shelters" in GameState.settlement_completed: result.dry+=90.0
	if "Storage Pits" in GameState.settlement_completed: result.covered+=140.0; result.sealed+=25.0
	# Persistent storage plots are operational infrastructure, not decoration. Their
	# condition and staffing determine how much of the nominal space can be used.
	for plot in GameState.settlement_plots:
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
	result.dry*=1.0+DiscoverySystem.effect("dry_storage")
	result.covered*=1.0+DiscoverySystem.effect("container_capacity")
	result.sealed*=1.0+DiscoverySystem.effect("container_capacity")
	return result

func _stored_bulk()->float:
	var total:=0.0
	for resource_name in GameState.resource_stockpiles:
		if resource_name=="Food" or not _is_material_resource(String(resource_name)): continue
		total+=float(GameState.resource_stockpiles[resource_name])*float(_material_profile(String(resource_name)).bulk)
	return total

func _apply_material_storage_losses(events:Array[Dictionary])->float:
	var capacities:=_storage_capacities()
	var used={"yard":0.0,"dry":0.0,"covered":0.0,"sealed":0.0,"secure":0.0}
	var lost_total:=0.0
	for resource_name_variant in GameState.resource_stockpiles.keys():
		var resource_name:=String(resource_name_variant)
		if resource_name=="Food" or not _is_material_resource(resource_name): continue
		var amount:=float(GameState.resource_stockpiles[resource_name])
		if amount<=0.0: continue
		var profile:=_material_profile(resource_name)
		var store:=String(profile.store)
		var bulk:=float(profile.bulk)
		var decay:=amount*maxf(0.0,float(profile.loss)+DiscoverySystem.effect("storage_loss"))
		var available_bulk:=maxf(0.0,float(capacities[store])-float(used[store]))
		var overflow_units:=maxf(0.0,amount-available_bulk/bulk)
		var overflow_loss:=overflow_units*0.035
		var loss:=minf(amount,decay+overflow_loss)
		GameState.resource_stockpiles[resource_name]=amount-loss
		used[store]=float(used[store])+maxf(0.0,amount-loss)*bulk
		lost_total+=loss
	if lost_total>0.5:
		events.append(_event("Material Losses","%.1f units were lost today to exposure, leakage, damage, or overcrowded stores." % lost_total,"storage"))
	return lost_total

func _update_deposit_bottleneck(deposit:Dictionary,carriers:float,events:Array[Dictionary])->void:
	var bottleneck:="Flowing"
	if int(deposit.workers)<=0: bottleneck="No extractors assigned"
	elif float(deposit.stock_at_source)>maxf(2.0,float(deposit.extracted_today)*4.0): bottleneck="Material accumulating at source"
	elif carriers<=0.0: bottleneck="No carriers assigned"
	elif float(deposit.route)<0.45: bottleneck="Access route is slow"
	deposit.bottleneck=bottleneck
	if bottleneck!=String(deposit.last_reported_bottleneck) and bottleneck!="Flowing":
		deposit.last_reported_bottleneck=bottleneck
		events.append(_event("Resource Flow Constrained","%s: %s." % [String(deposit.resource),bottleneck],String(deposit.id)))

func _practice(resource_name:String,domain:String)->float:
	return float((GameState.resource_practice.get(resource_name,{}) as Dictionary).get(domain,0.0))

func _gain_practice(resource_name:String,domain:String,amount:float)->void:
	if not GameState.resource_practice.has(resource_name): GameState.resource_practice[resource_name]={}
	var practice:Dictionary=GameState.resource_practice[resource_name]
	practice[domain]=minf(10.0,float(practice.get(domain,0.0))+amount)

func _family_literacy(resource_name:String)->float:
	var family:=String((catalog.get(resource_name,{}) as Dictionary).get("family",""))
	var related:=0.0
	for practiced_resource in GameState.resource_practice:
		if String((catalog.get(practiced_resource,{}) as Dictionary).get("family",""))==family:
			for amount in (GameState.resource_practice[practiced_resource] as Dictionary).values(): related+=float(amount)
	return 1.0+minf(0.55,related*0.012)

func resource_name_from(deposit:Dictionary)->String:
	return String(deposit.get("resource",""))

func _event(title: String, description: String, deposit_id: String) -> Dictionary:
	return {"day":int(GameState.elapsed_days), "title":title, "description":description, "deposit_id":deposit_id}

func visible_deposits() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for deposit in GameState.resource_deposits:
		if deposit.stage != "unknown": visible.append(deposit)
	return visible

func lens_entries(origin: Vector3, radius_world_units: float, km_per_unit := 1.0) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for deposit in visible_deposits():
		var distance := Vector2(origin.x,origin.z).distance_to(Vector2(deposit.position.x,deposit.position.z))
		if distance > radius_world_units:
			continue
		var surveyed: bool = deposit.stage != "recognized"
		var retrievable: bool = deposit.stage == "accessible" or deposit.stage == "developed"
		var visible_blockers: Array = deposit.blockers.duplicate()
		if not surveyed:
			visible_blockers = ["deposit has not been surveyed"]
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
			"access":"Retrievable now" if retrievable else "Not currently retrievable",
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
