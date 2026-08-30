extends Node

var rng := RandomNumberGenerator.new()
var initialized := false

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
	if GameState.resource_stockpiles.is_empty():
		GameState.resource_stockpiles = {"Food":GameState.population_exact*30.0, "Timber":0.0, "Stone":0.0, "Clay":0.0, "Fiber Plants":4.0}

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
		GameState.resource_deposits.append(_deposit(resource_name, site.position, quality, amount, i))
	var possible := _terrain_occurrences(terrain)
	for resource_name in possible:
		if rng.randf() < 0.48:
			var position := Vector3(rng.randf_range(-38, 38), 0, rng.randf_range(-24, 24))
			GameState.resource_deposits.append(_deposit(resource_name, position, rng.randf_range(0.45, 1.5), rng.randf_range(800, 12000), GameState.resource_deposits.size()))

func _deposit(resource_name: String, position: Vector3, quality: float, amount: float, index: int) -> Dictionary:
	return {"id":"%s_%d" % [resource_name.to_snake_case(), index], "resource":resource_name, "position":position, "quality":quality, "remaining":amount, "initial_amount":amount, "stage":"unknown", "clues":0.0, "survey":0.0, "access":0.0, "blockers":[], "development":0.0, "route":0.0, "workers":0, "daily_yield":0.0,"stock_at_source":0.0,"shipments":[],"extracted_today":0.0,"delivered_today":0.0,"lifetime_extracted":0.0,"lifetime_delivered":0.0,"distance_km":0.0,"travel_days":0,"bottleneck":"Not yet recognized","last_reported_bottleneck":""}

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
	for event in events:
		GameState.resource_events.push_front(event)
	return events

func _calculate_access(deposit: Dictionary, definition: Dictionary, context: Dictionary) -> float:
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
		deposit.daily_yield=assigned*float(profile.base_yield)*float(deposit.quality)*(0.55+float(context.get("tools",0.25))*0.75)*labor_eff*knowledge_multiplier*practice_multiplier
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
	GameState.material_metrics={"extracted_today":extracted_total,"delivered_today":delivered_total,"lost_today":lost_total,"at_source":at_source,"in_transit":in_transit,"stored_bulk":stored_bulk,"storage_capacity":capacity_total,"flow_ratio":delivered_total/maxf(0.01,extracted_total),"capacities":capacities}
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
		"Nitrates":{"family":"chemical","bulk":0.70,"store":"dry","loss":0.0025,"base_yield":0.10}
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
	var result={"yard":90.0+pop*0.75,"dry":16.0+pop*0.12,"covered":10.0,"sealed":2.0,"secure":5.0}
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
