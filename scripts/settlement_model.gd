extends Node

const VALID_STATUSES:= ["active","under_construction","stressed","damaged","vacant","ruin","reclaimed"]
const VALID_REPAIR_STATES:= ["maintained","emergency_stabilization","awaiting_assessment","awaiting_materials","repairing","rebuilding","salvaging","unrepairable"]
const VALID_REOCCUPATION_STATES:= ["occupied","evacuating","displaced","unsafe_return","temporary_use","returning","partially_reoccupied","reoccupied","contested_claim","permanently_abandoned"]
const VALID_LAND_USES:= ["residential_compound","mixed_household","temporary_encampment","communal","civic","sacred","market","workshop","dirty_industry","storage","hospitality","defense","water","waste","transport","field","pasture","vacant","ruin"]
const FOUNDING_NONRESIDENTIAL:= ["communal","storage","workshop","water","waste"]
const MAX_SIMULATED_PLOTS:=2048
const MAX_SIMULATED_ROUTES:=1024
const MAX_SIMULATED_NUCLEI:=128
const MAX_PLOT_HISTORY:=4096
const MAX_PLAYER_SETTLEMENTS:=256
const SETTLEMENT_BORDER_VERTICES:=32
const MAX_TERRITORY_ACCESS_AXES:=8
const MAX_OCCUPIED_STRATEGIC_REGIONS:=40
const MAX_BATTLE_DAMAGED_PLOTS:=24
const SETTLEMENT_CONVOY_KM_PER_DAY:=16.0
const COASTAL_CONTEXT_FIELDS:=["shoreline_access","marine_opportunity","salt_opportunity","storm_exposure","erosion_exposure","open_water_exposure"]
const FOUNDING_MATERIAL_VALUE:={"Timber":1.0,"Fiber Plants":1.0,"Clay":0.75,"Stone":0.55}
const SETTLEMENT_NAME_ROOTS:=["Alder","Ash","Bright","Cairn","Dawn","Deep","Elm","Fair","Flint","Green","High","Iron","Lake","Long","North","Oak","Red","River","Stone","Sun","Vale","West","Willow","Wind"]
const SETTLEMENT_NAME_ENDINGS:=["bank","bridge","cross","field","ford","gate","haven","hearth","holm","landing","march","meadow","rest","ridge","stead","vale","watch","wick"]

const CITY_RESOURCE_DEFAULTS:={
	"resource_stockpiles":{"Food":0.0,"Freshwater":0.0},"resource_deposits":[],
	"resource_events":[],"resource_practice":{},"resource_priorities":{},
	"material_metrics":{},"material_history":[],"water_metrics":{},"water_history":[],
	"food_stocks":{"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0},
	"food_source_health":{"Wild gathering":0.92,"Hunting":0.88,"Fishing":0.90,"Cultivation":0.94},
	"food_history":[],"food_issue_history":[],"nutrition_reserve":0.90,"malnutrition_burden":0.0,
	"founding_manifest":{},"settlement_completed":["Hearth Circle"],"settlement_projects":{},
	"settlement_plots":[],"settlement_morphology":{"classification":"founding outpost"},
	"housing_capacity":0,"housing_progress":0.0,
	"simulation_metrics":{},"economy_metrics":{},"economy_history":[],"economic_ledger":[],
	"economy_stage":"subsistence","market_prices":{},"economy_known_goods":{},
	"currency_supply":0.0,"public_treasury":0.0,"private_currency":0.0,"currency_hoards":0.0,
	"mutual_aid_reserve":0.0,"weighed_metal_circulation":0.0,"weighed_metal_composition":{},
	"monetary_reserve_metals":{},"civil_arrears":0.0,"military_arrears":0.0,"public_debt":0.0
}
var _local_population_scope:=false

func settlement_record(settlement_id:String)->Dictionary:
	for record in GameState.player_settlements:
		if String(record.get("id",""))==settlement_id: return record
	return {}

func selected_settlement()->Dictionary:
	_ensure_primary_settlement_record()
	var record:=settlement_record(GameState.selected_player_settlement_id)
	if not record.is_empty(): return record
	for candidate in GameState.player_settlements:
		if bool(candidate.get("primary",false)): return candidate
	return {}

func _ensure_city_resources(record:Dictionary)->void:
	if bool(record.get("primary",false)) or record.has("local_resources"): return
	record["local_resources"]=CITY_RESOURCE_DEFAULTS.duplicate(true)
	var local:Dictionary=record.local_resources
	local.housing_capacity=ceili(_settlement_population(record))
	local.founding_manifest={"portable_shelters":maxi(1,ceili(_settlement_population(record)/4.0)),"food_storage_rations":_settlement_population(record)*45.0,"dry_storage_bulk":10.0,"covered_storage_bulk":4.0,"sealed_storage_bulk":1.0,"secure_storage_bulk":1.0,"water_vessel_days":3.0}
	# Existing secondary records start empty, never with a copy of another city.
	record["resource_metrics"]={}

func city_resource_snapshot(settlement_id:String)->Dictionary:
	var record:=settlement_record(settlement_id)
	if record.is_empty(): return {}
	_ensure_city_resources(record)
	var local:Dictionary={}
	if bool(record.get("primary",false)):
		for field in CITY_RESOURCE_DEFAULTS: local[field]=GameState.get(field)
	else: local=record.local_resources
	return {"id":settlement_id,"name":String(record.name),"population":_settlement_population(record),"stores":(local.resource_stockpiles as Dictionary).duplicate(true),"deposits":(local.resource_deposits as Array).duplicate(true),"water":(local.water_metrics as Dictionary).duplicate(true),"food_history":(local.food_history as Array).duplicate(true),"metrics":(local.simulation_metrics as Dictionary).duplicate(true)}

## Existing resource systems run with bounded local counts. No resident objects,
## global population changes, or selected-city dependence enter the daily tick.
func with_local_population(operation:Callable)->Variant:
	if _local_population_scope or GameState.player_settlements.is_empty(): return operation.call()
	_local_population_scope=true
	var saved:Dictionary={}
	for field in ["population_exact","population_total","population_allocations","population_cohorts","pregnancy_cohorts"]:
		saved[field]=GameState.get(field)
	var record:=settlement_record(GameState.resource_settlement_id)
	var local_population:=_settlement_population(record) if not record.is_empty() else primary_population_exact()
	var ratio:=local_population/maxf(1.0,GameState.population_exact)
	GameState.population_exact=local_population
	GameState.population_total=roundi(local_population)
	for field in ["population_allocations","population_cohorts","pregnancy_cohorts"]:
		var scaled:Dictionary=(saved[field] as Dictionary).duplicate(true)
		for key in scaled: scaled[key]=float(scaled[key])*ratio
		GameState.set(field,scaled)
	if record.is_empty():
		for candidate in GameState.player_settlements:
			if bool(candidate.get("primary",false)): record=candidate; break
	var percentages:Dictionary=record.get("local_allocations",{})
	if not percentages.is_empty():
		var workforce:=0.0
		for amount in (saved.population_allocations as Dictionary).values(): workforce+=float(amount)*ratio
		for role in GameState.population_allocations: GameState.population_allocations[role]=workforce*float(percentages.get(role,0.0))/100.0
	var result:Variant=operation.call()
	for field in saved: GameState.set(field,saved[field])
	_local_population_scope=false
	return result

func with_city_resources(settlement_id:String,operation:Callable)->Variant:
	if settlement_id!="" and GameState.resource_settlement_id==settlement_id: return operation.call()
	var record:=settlement_record(settlement_id)
	if record.is_empty() or bool(record.get("primary",false)): return operation.call()
	_ensure_city_resources(record)
	var saved:Dictionary={}
	for field in CITY_RESOURCE_DEFAULTS:
		saved[field]=GameState.get(field)
		var value:Variant=record.local_resources[field]
		# Preserve typed Array fields when assigning serialized/default state.
		if saved[field] is Array:
			var typed:Array=(saved[field] as Array).duplicate()
			typed.assign(value)
			GameState.set(field,typed)
		else: GameState.set(field,value)
	var previous_id:=GameState.resource_settlement_id
	GameState.resource_settlement_id=settlement_id
	var result:Variant=operation.call()
	for field in CITY_RESOURCE_DEFAULTS:
		record.local_resources[field]=GameState.get(field)
		GameState.set(field,saved[field])
	GameState.resource_settlement_id=previous_id
	return result

func process_city_resources(settlement_id:String,context:Dictionary,daily_work:Callable=Callable())->void:
	var record:=settlement_record(settlement_id)
	if record.is_empty() or bool(record.get("primary",false)): return
	if int(record.get("last_resource_day",-1))>=int(GameState.elapsed_days): return
	with_city_resources(settlement_id,func()->void:
		ResourceSystem.process_day(context)
		record["resource_metrics"]=FoodSystem.process_day(context,float(GameState.simulation_metrics.get("labor_efficiency",0.72)),float(GameState.society_capacities.get("ecology",0.88)))
		var metrics:Dictionary=GameState.simulation_metrics.duplicate(true)
		metrics.merge(record.resource_metrics,true)
		metrics["labor_efficiency"]=float(metrics.get("labor_efficiency",0.72))
		metrics["housing_ratio"]=float(GameState.housing_capacity)/maxf(1.0,_settlement_population(record))
		GameState.simulation_metrics=metrics
		if daily_work.is_valid(): with_local_population(daily_work)
	)
	record["last_resource_day"]=int(GameState.elapsed_days)

const MAX_CITY_SHIPMENTS:=128
const CITY_TRADE_GOODS:=["Food","Timber","Stone","Clay","Fiber Plants","Salt","Medicinal Plants","Flint","Copper Ore","Tin Ore","Iron Ore","Coal"]

func city_trade_capacity()->Dictionary:
	var logistics:=clampf(float(GameState.society_capacities.get("logistics",0.0)),0.0,1.0)
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.0)),0.0,1.0)
	var transport:=maxf(0.0,DiscoverySystem.effect("route_speed")+ProgressionSystem.effect("route_speed"))
	var hauling:=maxf(0.0,DiscoverySystem.effect("haul_capacity")+ProgressionSystem.effect("haul_capacity"))
	return {"ready":logistics>=0.30 and institutions>=0.20,"logistics":logistics,"speed_km_per_day":8.0*(1.0+logistics+transport),"range_km":12.0+logistics*120.0+transport*180.0,"capacity_per_worker":(4.0+logistics*24.0)*(1.0+hauling),"reason":"Leaders need 30% logistics and 20% institutions to organize regular intercity deliveries."}

func _city_stores(record:Dictionary)->Dictionary:
	if bool(record.get("primary",false)): return GameState.resource_stockpiles
	_ensure_city_resources(record)
	return record.local_resources.resource_stockpiles

func _city_incoming(settlement_id:String,resource_name:String)->float:
	var incoming:=0.0
	for shipment in GameState.city_trade_shipments:
		if String(shipment.destination_id)==settlement_id and String(shipment.resource)==resource_name: incoming+=float(shipment.quantity)
	return incoming

func city_trade_snapshot(settlement_id:String)->Dictionary:
	var shipments:Array[Dictionary]=[]
	var history:Array[Dictionary]=[]
	for shipment in GameState.city_trade_shipments:
		if settlement_id in [String(shipment.source_id),String(shipment.destination_id)]: shipments.append(shipment.duplicate(true))
	for entry in GameState.city_trade_history:
		if settlement_id in [String(entry.source_id),String(entry.destination_id)]: history.append(entry.duplicate(true))
	return {"capacity":city_trade_capacity(),"shipments":shipments,"history":history}

func _record_city_trade(entry:Dictionary)->void:
	GameState.city_trade_history.push_front(entry.duplicate(true))
	if GameState.city_trade_history.size()>128: GameState.city_trade_history.resize(128)

func process_city_trade(route_assessor:Callable=Callable())->void:
	var today:=int(GameState.elapsed_days)
	if GameState.last_city_trade_day>=today: return
	GameState.last_city_trade_day=today
	# Departed shipments remain physical cargo even if logistics later declines.
	var pending:Array[Dictionary]=[]
	for shipment in GameState.city_trade_shipments:
		if float(shipment.arrival_day)>GameState.elapsed_days:
			pending.append(shipment)
			continue
		var destination:=settlement_record(String(shipment.destination_id))
		if destination.is_empty():
			pending.append(shipment)
			continue
		var quantity:=float(shipment.quantity)
		var delivered:=quantity*exp(-0.00035*float(shipment.travel_days)) if String(shipment.resource)=="Food" else quantity
		with_city_resources(String(destination.id),func()->void:
			if String(shipment.resource)=="Food": FoodSystem.receive_external_food(delivered)
			else: GameState.resource_stockpiles[shipment.resource]=float(GameState.resource_stockpiles.get(shipment.resource,0.0))+delivered
		)
		var arrived:=shipment.duplicate(true)
		arrived.merge({"status":"delivered","day":today,"delivered":delivered,"lost":quantity-delivered},true)
		_record_city_trade(arrived)
	GameState.city_trade_shipments=pending
	var capacity:=city_trade_capacity()
	if not bool(capacity.ready) or GameState.player_settlements.size()<2: return
	var available_transport:Dictionary={}
	for source in GameState.player_settlements:
		var share:=_settlement_population(source)/maxf(1.0,GameState.population_exact)
		var workforce:=0.0
		for amount in GameState.population_allocations.values(): workforce+=float(amount)
		var allocations:Dictionary=source.get("local_allocations",{})
		var carriers:=workforce*share*float(allocations.get("Logistics",0.0))/100.0 if not allocations.is_empty() else float(GameState.population_allocations.get("Logistics",0))*share
		var occupied:=0.0
		for shipment in GameState.city_trade_shipments:
			if String(shipment.source_id)==String(source.id): occupied+=float(shipment.quantity)*float(shipment.travel_days)
		available_transport[String(source.id)]=maxf(0.0,carriers*float(capacity.capacity_per_worker)-occupied)
	# One request per good per city; no citizen or merchant entities are created.
	for destination in GameState.player_settlements:
		var destination_population:=_settlement_population(destination)
		var destination_stores:=_city_stores(destination)
		for resource_name in CITY_TRADE_GOODS:
			if GameState.city_trade_shipments.size()>=MAX_CITY_SHIPMENTS: return
			var stored:=float(destination_stores.get(resource_name,0.0))
			var shortage_floor:=destination_population*14.0 if resource_name=="Food" else maxf(2.0,destination_population*0.02)
			if stored>=shortage_floor: continue
			var target:=destination_population*30.0 if resource_name=="Food" else maxf(6.0,destination_population*0.06)
			var requested:=target-stored-_city_incoming(String(destination.id),resource_name)
			if requested<=0.01: continue
			var donor:Dictionary={}
			var nearest:=INF
			var surplus:=0.0
			for source in GameState.player_settlements:
				if String(source.id)==String(destination.id) or float(available_transport.get(source.id,0.0))<=0.01: continue
				var distance:=_record_position(source).distance_to(_record_position(destination))
				if distance>float(capacity.range_km) or distance>=nearest: continue
				var reserve:=_settlement_population(source)*45.0 if resource_name=="Food" else maxf(20.0,_settlement_population(source)*0.15)
				var spare:=float(_city_stores(source).get(resource_name,0.0))-reserve
				if spare<=0.01: continue
				if not bool(known_route_assessment(_record_position(source),_record_position(destination)).get("known",false)): continue
				donor=source
				nearest=distance
				surplus=spare
			if donor.is_empty(): continue
			var route:Dictionary=route_assessor.call(donor,destination) if route_assessor.is_valid() else {"valid":true,"terrain_modifier":1.0}
			if not bool(route.get("valid",false)): continue
			var travel_days:=maxf(1.0,ceil(nearest/(float(capacity.speed_km_per_day)*clampf(float(route.get("terrain_modifier",1.0)),0.2,2.0))))
			var quantity:=minf(requested,minf(surplus,float(available_transport[donor.id])/travel_days))
			if quantity<=0.01: continue
			var sent:float=with_city_resources(String(donor.id),func()->float:
				if resource_name=="Food": return FoodSystem.issue_for_obligation(quantity,"city_trade","Trade to %s" % String(destination.name),travel_days,0)
				GameState.resource_stockpiles[resource_name]=float(GameState.resource_stockpiles.get(resource_name,0.0))-quantity
				return quantity
			)
			if sent<=0.01: continue
			available_transport[donor.id]=maxf(0.0,float(available_transport[donor.id])-sent*travel_days)
			var shipment:={"id":GameState.next_city_trade_id,"source_id":String(donor.id),"source_name":String(donor.name),"destination_id":String(destination.id),"destination_name":String(destination.name),"resource":resource_name,"quantity":sent,"departure_day":GameState.elapsed_days,"arrival_day":GameState.elapsed_days+travel_days,"travel_days":travel_days,"status":"in_transit","day":today,"reason":"Local leaders arranged a delivery to cover a %s shortage." % resource_name}
			GameState.next_city_trade_id+=1
			GameState.city_trade_shipments.append(shipment)
			_record_city_trade(shipment)

func reset_for_new_world()->void:
	# All authoritative data lives in GameState and is reset atomically there.
	pass

func _autoload_node(node_name:String)->Node:
	var tree:=Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(node_name) if tree and tree.root else null

func ensure_founded()->void:
	_ensure_primary_settlement_record()
	if not GameState.settlement_plots.is_empty():
		if GameState.settlement_morphology.is_empty(): rebuild_summary()
		return
	if "Hearth Circle" not in GameState.settlement_completed: return
	if GameState.settlement_founded_day<0: GameState.settlement_founded_day=int(floor(GameState.elapsed_days))
	_create_founding_nucleus()
	_create_founding_plots()
	_create_founding_routes()
	GameState.last_morphology_day=int(floor(GameState.elapsed_days/30.0))*30
	GameState.morphology_revision+=1
	rebuild_summary()

func _ensure_primary_settlement_record()->void:
	if "Hearth Circle" not in GameState.settlement_completed: return
	for settlement in GameState.player_settlements:
		if bool(settlement.get("primary",false)):
			settlement["position"]=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
			settlement["name"]=_primary_settlement_name()
			_ensure_settlement_management_fields(settlement)
			if GameState.selected_player_settlement_id=="": GameState.selected_player_settlement_id=String(settlement.get("id",""))
			return
	var record:={
		"id":"settlement_%03d" % GameState.next_player_settlement_id,
		"sequence":GameState.next_player_settlement_id,
		"primary":true,
		"name":_primary_settlement_name(),
		"position":Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z),
		"population_share":0.0,
		"founded_day":maxi(0,GameState.settlement_founded_day),
		"status":"established",
		"source_settlement_id":"",
		"territory_context":{},"environment_profile":{},"auto_manage":true,"management_focus":"establishment","leader_person_id":0
	}
	GameState.next_player_settlement_id+=1
	GameState.player_settlements.append(record)
	GameState.selected_player_settlement_id=String(record.id)
	GameState.settlement_network_revision+=1

func _primary_settlement_name()->String:
	var chosen:=GameState.settlement_name.strip_edges()
	return chosen if chosen!="" else "FIRST SETTLEMENT"


func _primary_settlement_id()->String:
	for settlement in GameState.player_settlements:
		if bool((settlement as Dictionary).get("primary",false)):
			return String((settlement as Dictionary).get("id",""))
	return ""


func _record_plot_building_event(plot:Dictionary,event_name:String,day:int,materials:Dictionary={},counts_materials:=false,note:String="")->void:
	GameState.record_building_event({
		"day":day,
		"settlement_id":_primary_settlement_id(),
		"settlement_name":_primary_settlement_name(),
		"event":event_name,
		"plot_id":int(plot.get("id",-1)),
		"kind":String(plot.get("form",plot.get("land_use","Building"))),
		"form":String(plot.get("form","")),
		"land_use":String(plot.get("land_use","")),
		"roof_plan":String(plot.get("roof_plan","")),
		"material_family":String(plot.get("material_family","")),
		"materials":materials,
		"counts_materials":counts_materials,
		"condition":float(plot.get("condition",1.0)),
		"status":String(plot.get("status","active")),
		"recipe":String(plot.get("construction_recipe","")),
		"note":note,
	})


func _ensure_settlement_management_fields(record:Dictionary)->void:
	if not record.has("auto_manage"): record["auto_manage"]=true
	if not record.has("management_focus"): record["management_focus"]="establishment" if int(GameState.elapsed_days)-int(record.get("founded_day",0))<365 else "balanced"
	if not record.has("leader_person_id"): record["leader_person_id"]=0
	if not record.has("status") or String(record.get("status",""))=="founding": record["status"]="established"


func settlement_by_id(settlement_id:String)->Dictionary:
	_ensure_primary_settlement_record()
	for settlement in GameState.player_settlements:
		if String(settlement.get("id",""))==settlement_id:
			var copy:=settlement.duplicate(true)
			var population:=_settlement_population(copy)
			copy["population"]=roundi(population)
			copy["classification"]=_settlement_classification(copy,population)
			return copy
	return {}


func select_settlement(settlement_id:String)->Dictionary:
	var selected:=settlement_by_id(settlement_id)
	if selected.is_empty(): return {"ok":false,"reason":"That settlement is not owned."}
	GameState.selected_player_settlement_id=settlement_id
	return {"ok":true,"settlement":selected}


func selected_settlement_snapshot()->Dictionary:
	_ensure_primary_settlement_record()
	var selected:=settlement_by_id(GameState.selected_player_settlement_id)
	if not selected.is_empty(): return selected
	for settlement in GameState.player_settlements:
		if bool(settlement.get("primary",false)):
			GameState.selected_player_settlement_id=String(settlement.get("id",""))
			return settlement_by_id(GameState.selected_player_settlement_id)
	return {}


func rename_settlement(settlement_id:String,new_name:String)->Dictionary:
	var clean:=new_name.strip_edges().substr(0,32)
	if clean=="": return {"ok":false,"reason":"A settlement name cannot be empty."}
	for index in GameState.player_settlements.size():
		var record:Dictionary=GameState.player_settlements[index]
		if String(record.get("id",""))!=settlement_id: continue
		for other in GameState.player_settlements:
			if String(other.get("id",""))!=settlement_id and String(other.get("name","")).to_lower()==clean.to_lower():
				return {"ok":false,"reason":"Another owned settlement already has that name."}
		record["name"]=clean
		GameState.player_settlements[index]=record
		if bool(record.get("primary",false)): GameState.settlement_name=clean
		GameState.settlement_network_revision+=1
		return {"ok":true,"settlement_id":settlement_id,"name":clean}
	return {"ok":false,"reason":"That settlement is not owned."}


func suggested_settlement_name(destination:Vector2,origin_name:String="")->String:
	var seed:=absi(hash("%d:place_name:%d:%d:%s" % [GameState.world_seed,roundi(destination.x*10.0),roundi(destination.y*10.0),origin_name]))
	var root:=String(SETTLEMENT_NAME_ROOTS[posmod(seed,SETTLEMENT_NAME_ROOTS.size())])
	var ending:=String(SETTLEMENT_NAME_ENDINGS[posmod(seed/37+11,SETTLEMENT_NAME_ENDINGS.size())])
	var suggestion:=root+ending
	var used:Array[String]=[]
	for settlement in GameState.player_settlements: used.append(String(settlement.get("name","")).to_lower())
	if suggestion.to_lower() in used: suggestion="%s %s" % [root,str(GameState.next_player_settlement_id)]
	return suggestion

func _record_position(record:Dictionary)->Vector2:
	var value:Variant=record.get("position",Vector2.ZERO)
	if value is Vector2: return value
	if value is Vector3: return Vector2(value.x,value.z)
	if value is Dictionary: return Vector2(float(value.get("x",0.0)),float(value.get("z",value.get("y",0.0))))
	if value is Array and value.size()>=2: return Vector2(float(value[0]),float(value[1]))
	return Vector2.ZERO

func _vector2_value(value:Variant)->Vector2:
	if value is Vector2: return value
	if value is Vector3: return Vector2(value.x,value.z)
	if value is Dictionary: return Vector2(float(value.get("x",0.0)),float(value.get("z",value.get("y",0.0))))
	if value is Array and value.size()>=2: return Vector2(float(value[0]),float(value[1]))
	return Vector2.ZERO

func _founding_material_plan(required_value:float)->Dictionary:
	var remaining:=maxf(0.0,required_value)
	var materials:Dictionary={}
	# Prefer light, portable material first. Clay and stone remain valid but more
	# bulk must be carried because they provide less shelter/cordage value per unit.
	for resource_name in ["Timber","Fiber Plants","Clay","Stone"]:
		if remaining<=0.001: break
		var value_per_unit:=float(FOUNDING_MATERIAL_VALUE[resource_name])
		var available:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		var taken:=minf(available,remaining/value_per_unit)
		if taken<=0.001: continue
		materials[resource_name]=taken
		remaining=maxf(0.0,remaining-taken*value_per_unit)
	return {
		"materials":materials,
		"required_value":required_value,
		"supplied_value":maxf(0.0,required_value-remaining),
		"missing_value":remaining
	}

func _sanitized_territory_context(context:Dictionary,previous:Dictionary={})->Dictionary:
	var sanitized:=previous.duplicate(true)
	for key in ["terrain_permeability","water_access","work_access","travel_access"]+COASTAL_CONTEXT_FIELDS:
		if context.has(key): sanitized[key]=clampf(float(context.get(key,0.0)),0.0,1.0)
	# Shore bearing and distance are geographic evidence rather than capacities. Keep
	# them separately from the normalized coastal fields so the playfield can put a
	# waterfront on the actual seaward edge instead of assigning generic port art to
	# an arbitrary city block.
	if context.has("coast_direction"):
		var coast_direction:=_vector2_value(context.get("coast_direction",Vector2.ZERO))
		if coast_direction.length_squared()>0.000001:
			sanitized["coast_direction"]=coast_direction.normalized()
	if context.has("nearest_open_water_km"):
		sanitized["nearest_open_water_km"]=clampf(float(context.get("nearest_open_water_km",INF)),0.0,1000.0)
	if context.has("access_axes"):
		var axes:Array[Dictionary]=[]
		for axis_variant in context.get("access_axes",[]):
			if axes.size()>=MAX_TERRITORY_ACCESS_AXES: break
			var axis:Dictionary=axis_variant
			var direction:=_vector2_value(axis.get("direction",Vector2.ZERO))
			if direction.length_squared()<0.000001: continue
			var kind:=String(axis.get("kind","travel"))
			if kind not in ["travel","route","work","river","terrain"]: kind="travel"
			axes.append({"kind":kind,"direction":direction.normalized(),"influence":clampf(float(axis.get("influence",axis.get("weight",0.5))),0.0,1.0)})
		sanitized["access_axes"]=axes
	return sanitized

func set_settlement_territory_context(settlement_id:String,context:Dictionary)->Dictionary:
	_ensure_primary_settlement_record()
	for index in GameState.player_settlements.size():
		var record:Dictionary=GameState.player_settlements[index]
		if String(record.get("id",""))!=settlement_id: continue
		var previous:Dictionary=record.get("territory_context",{})
		var sanitized:=_sanitized_territory_context(context,previous)
		record["territory_context"]=sanitized
		GameState.player_settlements[index]=record
		if sanitized!=previous: GameState.settlement_network_revision+=1
		return {"ok":true,"settlement_id":settlement_id,"territory_context":sanitized.duplicate(true),"axis_count":(sanitized.get("access_axes",[]) as Array).size()}
	return {"ok":false,"reason":"No owned settlement has that id."}


func set_settlement_environment_profile(settlement_id:String,profile:Dictionary)->Dictionary:
	_ensure_primary_settlement_record()
	for index in GameState.player_settlements.size():
		var record:Dictionary=GameState.player_settlements[index]
		if String(record.get("id",""))!=settlement_id: continue
		var previous_signature:=String((record.get("environment_profile",{}) as Dictionary).get("signature",""))
		record["environment_profile"]=profile.duplicate(true)
		GameState.player_settlements[index]=record
		if String(profile.get("signature",""))!=previous_signature: GameState.settlement_network_revision+=1
		return {"ok":true,"settlement_id":settlement_id,"environment_profile":profile.duplicate(true)}
	return {"ok":false,"reason":"No owned settlement has that id."}

func _province_terrain_permeability()->float:
	var terrain:=GameState.province_terrain.to_lower()
	if "mountain" in terrain: return 0.28
	if "hill" in terrain or "broken" in terrain: return 0.52
	if "wetland" in terrain or "marsh" in terrain: return 0.42
	if "forest" in terrain or "wood" in terrain: return 0.66
	if "desert" in terrain: return 0.58
	if "coast" in terrain: return 0.72
	return 0.86


func coastal_site_profile(record_or_context:Dictionary={})->Dictionary:
	# Coast is an aggregate site condition, not a free harbor or a spawned resource.
	# Immediate benefits represent shoreline gathering and near-shore food. Movement
	# and trade remain locked behind broad, research-driven civilization capacities.
	var context:Dictionary=record_or_context.get("territory_context",record_or_context)
	var shoreline:=clampf(float(context.get("shoreline_access",0.0)),0.0,1.0)
	var marine:=clampf(float(context.get("marine_opportunity",0.0)),0.0,1.0)*shoreline
	var salt:=clampf(float(context.get("salt_opportunity",0.0)),0.0,1.0)*shoreline
	var storm:=clampf(float(context.get("storm_exposure",0.0)),0.0,1.0)*shoreline
	var erosion:=clampf(float(context.get("erosion_exposure",0.0)),0.0,1.0)*shoreline
	var open_water:=clampf(float(context.get("open_water_exposure",0.0)),0.0,1.0)*shoreline
	var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
	var logistics_tier:=clampi(int(ProgressionSystem.domain_tier("logistics")),0,8)
	var knowledge_tier:=clampi(int(ProgressionSystem.domain_tier("knowledge")),0,8)
	var movement_gate:=1.0 if infrastructure_tier>=2 and logistics_tier>=2 and knowledge_tier>=2 else 0.0
	var trade_gate:=1.0 if infrastructure_tier>=3 and logistics_tier>=3 and knowledge_tier>=2 else 0.0
	var exposure:=clampf(storm*0.62+erosion*0.38,0.0,1.0)
	return {
		"coastal":shoreline>0.05,"shoreline_access":shoreline,"marine_opportunity":marine,
		"salt_opportunity":salt,"storm_exposure":storm,"erosion_exposure":erosion,
		"open_water_exposure":open_water,"food_output_bonus":minf(0.08,shoreline*0.035+marine*0.045),
		"foraging_bonus":minf(0.06,shoreline*0.025+marine*0.025+salt*0.010),
		"maintenance_pressure":exposure*0.07,"claim_multiplier":1.0-exposure*0.06,
		"maritime_movement_factor":shoreline*open_water*movement_gate,
		"maritime_trade_factor":shoreline*open_water*trade_gate,
		"movement_knowledge_ready":movement_gate>0.0,"trade_knowledge_ready":trade_gate>0.0
	}

func _territory_access_axes(record:Dictionary)->Array[Dictionary]:
	var context:Dictionary=record.get("territory_context",{})
	var axes:Array[Dictionary]=[]
	for axis_variant in context.get("access_axes",[]):
		if axes.size()>=MAX_TERRITORY_ACCESS_AXES: break
		axes.append((axis_variant as Dictionary).duplicate(true))
	if not bool(record.get("primary",false)): return axes
	# Existing paths and worked occurrences pull the claim in actual used
	# directions. Only a fixed sample is retained, independent of population.
	for route_variant in GameState.settlement_routes:
		if axes.size()>=MAX_TERRITORY_ACCESS_AXES: break
		var route:Dictionary=route_variant
		if not bool(route.get("active",true)): continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		if points.size()<2: continue
		var direction:=points[points.size()-1]-points[0]
		if direction.length_squared()<0.000001: continue
		axes.append({"kind":"route","direction":direction.normalized(),"influence":clampf(0.28+float(route.get("condition",0.2))*0.45,0.18,0.72)})
	var center:=_record_position(record)
	for deposit_variant in GameState.resource_deposits:
		if axes.size()>=MAX_TERRITORY_ACCESS_AXES: break
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("stage","")) not in ["surveyed","accessible","worked","developed"]: continue
		var direction:=_vector2_value(deposit.get("position",Vector2.ZERO))-center
		if direction.length_squared()<0.000001: continue
		var resource:=String(deposit.get("resource",""))
		axes.append({"kind":"river" if resource=="Freshwater" else "work","direction":direction.normalized(),"influence":0.58 if resource=="Freshwater" else 0.42})
	return axes

func _territory_drivers(record:Dictionary,population:float)->Dictionary:
	var context:Dictionary=record.get("territory_context",{})
	var able:=maxf(1.0,float(GameState.able_population()))
	var working:=0.0
	for role in ["Food","Survey","Extraction","Construction","Logistics"]:
		working+=maxf(0.0,GameState.effective_workers(role))
	var derived_work:=clampf(working/maxf(1.0,able*0.68),0.0,1.0)
	var route_condition:=0.0
	var active_routes:=0
	if bool(record.get("primary",false)):
		for route_variant in GameState.settlement_routes:
			var route:Dictionary=route_variant
			if not bool(route.get("active",true)): continue
			active_routes+=1
			route_condition+=clampf(float(route.get("condition",0.0)),0.0,1.0)
	if active_routes>0: route_condition/=float(active_routes)
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16))+DiscoverySystem.effect("route_speed")*0.25,0.0,1.0)
	var derived_travel:=clampf(float(active_routes)/48.0+route_condition*0.38+logistics*0.42,0.0,1.0)
	var water:=0.72 if bool(record.get("primary",false)) and bool(GameState.water_metrics.get("source_accessible",false)) else 0.08
	for deposit_variant in GameState.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))=="Freshwater" and String(deposit.get("stage","")) in ["surveyed","accessible","worked","developed"]:
			water=maxf(water,0.74)
	var age_days:=maxi(0,int(GameState.elapsed_days)-int(record.get("founded_day",0)))
	var terrain:=clampf(float(context.get("terrain_permeability",_province_terrain_permeability())),0.0,1.0)
	var work:=maxf(derived_work,clampf(float(context.get("work_access",0.0)),0.0,1.0))
	var travel:=maxf(derived_travel,clampf(float(context.get("travel_access",0.0)),0.0,1.0))
	water=maxf(water,clampf(float(context.get("water_access",0.0)),0.0,1.0))
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25))+DiscoverySystem.effect("state_capacity"),0.0,1.0)
	var delegated:Dictionary=record.get("delegated_effects",{})
	work=clampf(work+float(delegated.get("work",0.0)),0.0,1.0)
	travel=clampf(travel+float(delegated.get("travel",0.0)),0.0,1.0)
	water=clampf(water+float(delegated.get("water",0.0)),0.0,1.0)
	var population_pressure:=clampf(log(maxf(1.0,population)+1.0)/log(1_000_000_001.0),0.0,1.0)
	var maturity:=clampf(sqrt(float(age_days)/1825.0),0.0,1.0)
	var coast:=coastal_site_profile(record)
	travel=maxf(travel,float(coast.maritime_movement_factor)*0.34)
	var support:=clampf(population_pressure*0.22+work*0.18+travel*0.19+terrain*0.12+water*0.10+logistics*0.10+institutions*0.09+float(delegated.get("support",0.0))-float(coast.maintenance_pressure)*0.25,0.0,1.0)
	return {"population":population_pressure,"work":work,"travel":travel,"terrain":terrain,"water":water,"logistics":logistics,"institutions":institutions,"maturity":maturity,"support":support,"access_axes":_territory_access_axes(record),"coastal_site":coast}

func _committed_satellite_share(include_convoy:=true)->float:
	var share:=0.0
	for settlement in GameState.player_settlements:
		if not bool(settlement.get("primary",false)):
			share+=maxf(0.0,float(settlement.get("population_share",0.0)))
	if include_convoy and bool(GameState.settlement_convoy.get("active",false)):
		share+=maxf(0.0,float(GameState.settlement_convoy.get("population_share",0.0)))
	return clampf(share,0.0,0.92)

func primary_population_exact()->float:
	return maxf(1.0,GameState.population_exact*(1.0-_committed_satellite_share()))

func _primary_population()->int:
	return maxi(1,roundi(float(GameState.population_total)*(1.0-_committed_satellite_share())))

func _primary_able_population()->float:
	return maxf(1.0,float(GameState.able_population())*primary_population_exact()/maxf(1.0,GameState.population_exact))

func _settlement_population(record:Dictionary)->float:
	if bool(record.get("primary",false)): return primary_population_exact()
	return maxf(1.0,GameState.population_exact*maxf(0.0,float(record.get("population_share",0.0))))

func _settlement_classification(record:Dictionary,population:float)->String:
	if bool(record.get("primary",false)):
		return classification()
	var age_days:=maxi(0,int(GameState.elapsed_days)-int(record.get("founded_day",0)))
	if age_days<90 or population<80.0: return "founding settlement"
	if population<400.0: return "hamlet"
	if population<2500.0: return "village"
	if population<18000.0: return "town"
	if population<1000000.0: return "city"
	if population<10000000.0: return "metropolis"
	return "megalopolis"

func _base_claim_radius_km(record:Dictionary,population:float)->float:
	var territory:=_territory_drivers(record,population)
	var able:=maxf(1.0,float(GameState.able_population()))
	var survey_share:=clampf(GameState.effective_workers("Survey")/maxf(1.0,able*0.10),0.0,1.0)
	var administration_share:=clampf(GameState.effective_workers("Administration")/maxf(1.0,able*0.08),0.0,1.0)
	var logistics:=float(territory.logistics)
	var state_capacity:=clampf(float(GameState.society_capacities.get("institutions",0.25))+DiscoverySystem.effect("state_capacity"),0.0,1.0)
	var defense_factor:=0.0
	var military:=_autoload_node("MilitaryCampaign")
	if military and military.has_method("settlement_defense_snapshot"):
		var defense:Dictionary=military.settlement_defense_snapshot()
		defense_factor=clampf(float(defense.get("stage",0))/5.0*float(defense.get("integrity",1.0)),0.0,1.0)
	var reach:=0.62+survey_share*0.16+administration_share*0.18+logistics*0.16+state_capacity*0.11+defense_factor*0.08
	reach+=float(territory.work)*0.09+float(territory.travel)*0.09+float(territory.water)*0.05
	reach*=0.82+float(territory.terrain)*0.18
	var age_days:=maxi(0,int(GameState.elapsed_days)-int(record.get("founded_day",0)))
	var maturity:=clampf(0.48+sqrt(float(age_days)/730.0)*0.30,0.48,1.0)
	var worked_area_km2:=population/72.0*reach*reach*maturity
	if bool(record.get("primary",false)):
		worked_area_km2+=float(GameState.settlement_completed.size())*0.045+float(GameState.settlement_routes.size())*0.0015
	var radius:=sqrt(maxf(0.12,worked_area_km2)/PI)
	var coast:=coastal_site_profile(record)
	radius*=float(coast.claim_multiplier)
	if bool(record.get("primary",false)):
		var fabric_extent:=0.0
		for plot in GameState.settlement_plots:
			for point in (plot.get("polygon",PackedVector2Array()) as PackedVector2Array): fabric_extent=maxf(fabric_extent,point.length())
		radius=maxf(radius,fabric_extent+0.16)
	return clampf(radius,0.32,4600.0)

func _bounded_claim_radius(index:int,records:Array[Dictionary],base_radius:float)->float:
	if records.size()<=1: return base_radius
	var center:=_record_position(records[index])
	var nearest:=INF
	for other_index in records.size():
		if other_index==index: continue
		nearest=minf(nearest,center.distance_to(_record_position(records[other_index])))
	if nearest==INF: return base_radius
	return minf(base_radius,maxf(0.24,nearest*0.40))

func _claim_boundary(record:Dictionary,radius:float,drivers:Dictionary={})->PackedVector2Array:
	var center:=_record_position(record)
	var seed:=hash("%d:player_settlement_border:%s" % [GameState.world_seed,String(record.get("id","settlement"))])
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed
	var rotation:=rng.randf_range(0.0,TAU)
	var harmonic_a:=rng.randf_range(0.035,0.085)
	var harmonic_b:=rng.randf_range(0.020,0.055)
	var axes:Array=drivers.get("access_axes",[])
	var boundary:=PackedVector2Array()
	for vertex_index in SETTLEMENT_BORDER_VERTICES:
		var angle:=rotation+TAU*float(vertex_index)/float(SETTLEMENT_BORDER_VERTICES)
		var variation:=1.0+sin(angle*3.0+rotation)*harmonic_a+sin(angle*7.0-rotation*0.7)*harmonic_b+rng.randf_range(-0.018,0.018)
		var direction:=Vector2.from_angle(angle)
		var directional_pull:=0.0
		for axis_variant in axes:
			var axis:Dictionary=axis_variant
			var axis_direction:=_vector2_value(axis.get("direction",Vector2.ZERO))
			if axis_direction.length_squared()<0.000001: continue
			var alignment:=pow(maxf(0.0,direction.dot(axis_direction.normalized())),3.0)
			var kind_factor:float={"river":0.16,"route":0.13,"travel":0.11,"work":0.10,"terrain":0.08}.get(String(axis.get("kind","travel")),0.10)
			directional_pull+=alignment*clampf(float(axis.get("influence",0.0)),0.0,1.0)*kind_factor
		variation*=1.0+minf(0.22,directional_pull)
		boundary.append(center+Vector2.from_angle(angle)*radius*variation)
	return boundary

func settlement_network_snapshot()->Dictionary:
	_ensure_primary_settlement_record()
	var records:Array[Dictionary]=[]
	for settlement in GameState.player_settlements:
		_ensure_settlement_management_fields(settlement)
		records.append(settlement.duplicate(true))
	var public_settlements:Array[Dictionary]=[]
	for index in records.size():
		var record:=records[index]
		var population:=_settlement_population(record)
		var radius:=_bounded_claim_radius(index,records,_base_claim_radius_km(record,population))
		var drivers:=_territory_drivers(record,population)
		var boundary:=_claim_boundary(record,radius,drivers)
		record["population"]=roundi(population)
		record["classification"]=_settlement_classification(record,population)
		record["claim_radius_km"]=radius
		record["controlled_area_km2"]=_polygon_area_km2(boundary)
		record["boundary"]=boundary
		record["territory_drivers"]=drivers
		record["intrinsic_site"]=coastal_site_profile(record)
		if bool(record.get("primary",false)): record["name"]=_primary_settlement_name()
		public_settlements.append(record)
	return {
		"revision":GameState.settlement_network_revision+GameState.morphology_revision,
		"settlements":public_settlements,
		"count":public_settlements.size(),
		"limit":MAX_PLAYER_SETTLEMENTS,
		"convoy":GameState.settlement_convoy.duplicate(true),
		"represented_population":roundi(GameState.population_exact),
		"runtime_people_entities":0
	}

func territory_control_snapshot()->Dictionary:
	# Owned settlement claims and conquered strategic regions are two views of the
	# same civilization-scale territory. Neither creates tiles, residents, or
	# building records as population grows.
	var network:=settlement_network_snapshot()
	var claims:Array[Dictionary]=[]
	for settlement_variant in network.settlements:
		var settlement:Dictionary=settlement_variant
		claims.append({"id":String(settlement.get("id","")),"kind":"settlement_claim","name":String(settlement.get("name","SETTLEMENT")),"controller":"player","population":int(settlement.get("population",0)),"position":settlement.get("position",Vector2.ZERO),"boundary":settlement.get("boundary",PackedVector2Array()),"area_km2":float(settlement.get("controlled_area_km2",0.0)),"status":String(settlement.get("status","established")),"territory_drivers":settlement.get("territory_drivers",{})})
	var occupations:Array[Dictionary]=[]
	var civilization_system:=_autoload_node("CivilizationSystem")
	if civilization_system:
		var civilizations:Variant=civilization_system.get("civilizations")
		if civilizations is Array:
			for civ_variant in civilizations:
				var civ:Dictionary=civ_variant
				for region_variant in civ.get("strategic_regions",[]):
					if occupations.size()>=MAX_OCCUPIED_STRATEGIC_REGIONS: break
					var region:Dictionary=region_variant
					if String(region.get("controller",String(civ.get("id",""))))!="player": continue
					occupations.append({"id":String(region.get("id","")),"kind":"occupied_strategic_region","name":String(region.get("name","OCCUPIED REGION")),"controller":"player","original_controller":String(region.get("original_controller",civ.get("id",""))),"population":roundi(float(region.get("population",0.0))),"role":String(region.get("role","frontier")),"integration":clampf(float(region.get("integration",0.0)),0.0,1.0),"resistance":clampf(float(region.get("resistance",0.0)),0.0,1.0),"damage":clampf(float(region.get("damage",0.0)),0.0,1.0),"occupation_turns":maxi(0,int(region.get("occupation_turns",0)))})
	var occupied_population:=0
	for occupation in occupations: occupied_population+=int(occupation.get("population",0))
	return {"revision":int(network.revision)+(int(civilization_system.get("turn_index")) if civilization_system else 0),"settlement_claims":claims,"occupied_regions":occupations,"settlement_claim_count":claims.size(),"occupied_region_count":occupations.size(),"record_count":claims.size()+occupations.size(),"record_limit":MAX_PLAYER_SETTLEMENTS+MAX_OCCUPIED_STRATEGIC_REGIONS,"owned_population":roundi(GameState.population_exact),"occupied_population":occupied_population,"controlled_population":roundi(GameState.population_exact)+occupied_population,"runtime_people_entities":0,"bounded":true}

func _point_to_boundary_distance(point:Vector2,boundary:PackedVector2Array)->float:
	if boundary.is_empty(): return INF
	var closest:=INF
	for index in boundary.size():
		var next:=(index+1)%boundary.size()
		closest=minf(closest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,boundary[index],boundary[next])))
	return closest

func settlement_at_world(position:Vector2)->Dictionary:
	var nearest:Dictionary={}
	var nearest_edge_distance:=INF
	for settlement in settlement_network_snapshot().settlements:
		var boundary:PackedVector2Array=settlement.get("boundary",PackedVector2Array())
		var inside:=Geometry2D.is_point_in_polygon(position,boundary)
		var edge_distance:=_point_to_boundary_distance(position,boundary)
		if inside: edge_distance=-edge_distance
		if edge_distance<nearest_edge_distance:
			nearest_edge_distance=edge_distance
			nearest=settlement
	if nearest.is_empty(): return {}
	nearest["inside_border"]=nearest_edge_distance<=0.0
	nearest["distance_from_center_km"]=position.distance_to(_record_position(nearest))
	nearest["distance_from_border_km"]=maxf(0.0,nearest_edge_distance)
	return nearest

func known_land_assessment(position:Vector2)->Dictionary:
	if not is_finite(position.x) or not is_finite(position.y):
		return {"known":false,"reason":"The destination has no valid world position."}
	var civilization_system:=_autoload_node("CivilizationSystem")
	if civilization_system==null or not civilization_system.has_method("fog_snapshot"):
		return {"known":false,"reason":"No returned map record is available to verify this destination."}
	if civilization_system.has_method("initialize"): civilization_system.initialize()
	var fog:Dictionary=civilization_system.fog_snapshot()
	for area_variant in fog.get("areas",[]):
		var area:Dictionary=area_variant
		var radius:=maxf(0.0,float(area.get("radius",0.0)))
		if bool(civilization_system.call("_revealed_record_contains",area,position,1.05)):
			return {"known":true,"source":String(area.get("source","returned chart")),"charted_day":int(area.get("day",0)),"charted_center":Vector2(float(area.get("x",0.0)),float(area.get("z",0.0))),"charted_radius_km":radius,"charted_kind":String(area.get("kind","circle"))}
	return {"known":false,"reason":"That land is uncharted. A traveler or scout must return with the route before a founding convoy can be sent."}

func known_route_assessment(origin:Vector2,destination:Vector2)->Dictionary:
	var civilization_system:=_autoload_node("CivilizationSystem")
	if civilization_system==null or not civilization_system.has_method("fog_snapshot"):
		return {"known":false,"reason":"No returned map record can verify a route from the origin."}
	if civilization_system.has_method("initialize"): civilization_system.initialize()
	var distance:=origin.distance_to(destination)
	var samples:=clampi(ceili(distance/24.0)+1,2,256)
	for sample_index in samples:
		var point:=origin.lerp(destination,float(sample_index)/float(maxi(1,samples-1)))
		var known:=bool(civilization_system.call("_position_is_revealed",point))
		if not known:
			return {"known":false,"reason":"The destination is charted, but the route crosses uncharted ground. Return a continuous scout chart before sending settlers.","first_unknown":point,"progress":float(sample_index)/float(maxi(1,samples-1))}
	return {"known":true,"distance_km":distance,"samples":samples,"bounded":true}

func settlement_convoy_quote(destination:Vector2,duration_days:float)->Dictionary:
	_ensure_primary_settlement_record()
	if "Hearth Circle" not in GameState.settlement_completed:
		return {"ok":false,"reason":"A permanent first settlement must exist before another can be founded."}
	if bool(GameState.settlement_convoy.get("active",false)):
		return {"ok":false,"reason":"A settlement convoy is already underway."}
	if GameState.player_settlements.size()>=MAX_PLAYER_SETTLEMENTS:
		return {"ok":false,"reason":"The bounded settlement register is full."}
	var land:=known_land_assessment(destination)
	if not bool(land.get("known",false)):
		return {"ok":false,"reason":String(land.get("reason","That land is not part of any returned map record.")),"known_land":false}
	var network:Dictionary=settlement_network_snapshot()
	var origin:Dictionary={}
	var origin_distance:=INF
	for settlement in network.settlements:
		var distance:=destination.distance_to(_record_position(settlement))
		if distance<origin_distance:
			origin_distance=distance
			origin=settlement
	if origin.is_empty(): return {"ok":false,"reason":"No established settlement can provision the journey."}
	var route_assessment:=known_route_assessment(_record_position(origin),destination)
	if not bool(route_assessment.get("known",false)):
		return {"ok":false,"reason":String(route_assessment.get("reason","No continuous returned chart reaches that land.")),"known_land":true,"known_route":false}
	var minimum_distance:=maxf(2.0,float(origin.get("claim_radius_km",0.0))+0.75)
	if origin_distance<minimum_distance:
		return {"ok":false,"reason":"Choose ground at least %.1f km beyond %s's present border." % [minimum_distance,String(origin.get("name","the origin"))]}
	for settlement in network.settlements:
		var required_clearance:=maxf(1.2,float(settlement.get("claim_radius_km",0.0))+0.55)
		if destination.distance_to(_record_position(settlement))<required_clearance:
			return {"ok":false,"reason":"The destination lies inside %s's existing settlement territory." % String(settlement.get("name","an existing settlement"))}
	var available_primary:=_settlement_population(origin)
	var founders:=maxi(40,roundi(available_primary*0.02))
	founders=mini(founders,maxi(0,roundi(available_primary)-80))
	if founders<40:
		return {"ok":false,"reason":"At least 80 people must remain at the source settlement after a 40-person founding party is organized."}
	var duration:=maxf(0.5,maxf(duration_days,origin_distance/SETTLEMENT_CONVOY_KM_PER_DAY))
	var food_required:=float(founders)*(duration+45.0)
	# Settlers need portable shelter/tool supplies, not one botanically specific
	# resource. Timber and plant fiber are efficient; clay and stone can substitute
	# at a transport penalty. Local materials still matter without becoming a
	# centuries-long hard lock.
	var founding_material_required:=maxf(10.0,float(founders)*0.135)
	var material_plan:Dictionary=with_city_resources(String(origin.id),func()->Dictionary: return _founding_material_plan(founding_material_required))
	var founding_materials:Dictionary=material_plan.materials
	var food_available:=float(city_resource_snapshot(String(origin.id)).stores.get("Food",0.0))
	var blockers:Array[String]=[]
	if food_available<food_required: blockers.append("%.0f more travel rations" % (food_required-food_available))
	if float(material_plan.missing_value)>0.001:
		blockers.append("%.1f more founding supplies (use any mix of timber, plant fiber, clay, or stone)" % float(material_plan.missing_value))
	var population_share:=float(founders)/maxf(1.0,GameState.population_exact)
	if bool(origin.get("primary",false)) and _committed_satellite_share(false)+population_share>0.92: blockers.append("more population must remain in the established network")
	return {
		"ok":blockers.is_empty(),"reason":"Ready" if blockers.is_empty() else "Need %s." % ", ".join(blockers),
		"origin_id":String(origin.get("id","")),"origin_name":String(origin.get("name","ORIGIN")),"origin":_record_position(origin),
		"destination":destination,"distance_km":origin_distance,"duration_days":duration,"minimum_duration_days":maxf(0.5,origin_distance/SETTLEMENT_CONVOY_KM_PER_DAY),"population":founders,
		"population_share":population_share,"known_land":true,"known_route":true,"map_source":String(land.get("source","returned chart")),
		"population_sources":GameState.proportional_population_commitment(founders),
		"food":food_required,"materials":founding_materials,
		"suggested_name":suggested_settlement_name(destination,String(origin.get("name",""))),
		"material_required":founding_material_required,"material_supplied":float(material_plan.supplied_value),
		# Legacy fields remain readable for old UI/tests while no longer acting as
		# independent requirements.
		"timber":float(founding_materials.get("Timber",0.0)),"fiber":float(founding_materials.get("Fiber Plants",0.0))
	}

func begin_settlement_convoy(destination:Vector2,duration_days:float,settlement_name:String="")->Dictionary:
	var quote:=settlement_convoy_quote(destination,duration_days)
	if not bool(quote.get("ok",false)): return quote
	return with_city_resources(String(quote.origin_id),func()->Dictionary: return _depart_local_convoy(destination,quote,settlement_name))

func _depart_local_convoy(destination:Vector2,quote:Dictionary,settlement_name:String)->Dictionary:
	var food_system:=_autoload_node("FoodSystem")
	var food_removed:=0.0
	if food_system and food_system.has_method("remove_for_settlement_convoy"):
		food_removed=float(food_system.remove_for_settlement_convoy(float(quote.food),"Settlement convoy • %s" % String(quote.origin_name),float(quote.duration_days),int(quote.population)))
	else:
		food_removed=minf(float(quote.food),float(GameState.resource_stockpiles.get("Food",0.0)))
		GameState.resource_stockpiles["Food"]=maxf(0.0,float(GameState.resource_stockpiles.get("Food",0.0))-food_removed)
	if food_removed+0.01<float(quote.food):
		return {"ok":false,"reason":"The provision ledger changed before the convoy could be supplied."}
	var committed_materials:Dictionary=(quote.get("materials",{}) as Dictionary).duplicate(true)
	for resource_name_variant in committed_materials:
		var resource_name:=String(resource_name_variant)
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(committed_materials[resource_name]))
	var origin:=settlement_record(String(quote.origin_id))
	if not bool(origin.get("primary",false)): origin.population_share=maxf(0.0,float(origin.population_share)-float(quote.population_share))
	GameState.settlement_convoy={
		"active":true,"phase":"traveling","origin_id":String(quote.origin_id),"origin_name":String(quote.origin_name),
		"origin":quote.origin,"position":quote.origin,"destination":destination,"depart_day":GameState.elapsed_days,
		"arrival_day":GameState.elapsed_days+float(quote.duration_days),"duration_days":float(quote.duration_days),"progress":0.0,
		"population":int(quote.population),"population_share":float(quote.population_share),
		"population_sources":(quote.population_sources as Dictionary).duplicate(true),
		"food_committed":float(quote.food),"materials_committed":committed_materials,
		"settlement_name":settlement_name.strip_edges().substr(0,32) if settlement_name.strip_edges()!="" else String(quote.get("suggested_name",suggested_settlement_name(destination,String(quote.origin_name))))
	}
	GameState.settlement_network_revision+=1
	return quote

func update_settlement_convoy(position:Vector2,progress:float)->void:
	if not bool(GameState.settlement_convoy.get("active",false)): return
	var origin:=_vector2_value(GameState.settlement_convoy.get("origin",position))
	var destination:=_vector2_value(GameState.settlement_convoy.get("destination",position))
	var depart_day:=float(GameState.settlement_convoy.get("depart_day",GameState.elapsed_days))
	var duration:=maxf(0.5,float(GameState.settlement_convoy.get("duration_days",0.5)))
	var temporal_progress:=clampf((GameState.elapsed_days-depart_day)/duration,0.0,1.0)
	var authoritative_progress:=minf(clampf(progress,0.0,1.0),temporal_progress)
	GameState.settlement_convoy["position"]=origin.lerp(destination,authoritative_progress)
	GameState.settlement_convoy["progress"]=authoritative_progress
	GameState.settlement_convoy["phase"]="arrived" if authoritative_progress>=1.0 else "traveling"

func complete_settlement_convoy(destination:Vector2)->Dictionary:
	if not bool(GameState.settlement_convoy.get("active",false)): return {"ok":false,"reason":"No settlement convoy is underway."}
	var convoy:=GameState.settlement_convoy.duplicate(true)
	var planned_destination:=_vector2_value(convoy.get("destination",destination))
	if destination.distance_to(planned_destination)>0.01:
		return {"ok":false,"reason":"The convoy can establish only the charted destination approved at departure."}
	if GameState.elapsed_days+0.0001<float(convoy.get("arrival_day",GameState.elapsed_days)) or float(convoy.get("progress",0.0))<0.9999:
		return {"ok":false,"reason":"The founding convoy has not physically reached its destination."}
	var sequence:=GameState.next_player_settlement_id
	var record:={
		"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,
		"name":String(convoy.get("settlement_name",suggested_settlement_name(planned_destination,String(convoy.get("origin_name",""))))),"position":planned_destination,
		"population_share":float(convoy.get("population_share",0.0)),"founded_day":int(floor(GameState.elapsed_days)),
		"status":"established","source_settlement_id":String(convoy.get("origin_id","")),"territory_context":{},"environment_profile":{},
		"auto_manage":true,"management_focus":"establishment","leader_person_id":0
	}
	GameState.next_player_settlement_id+=1
	GameState.player_settlements.append(record)
	_ensure_city_resources(record)
	with_city_resources(String(record.id),func()->void:
		FoodSystem.receive_external_food(maxf(0.0,float(convoy.get("food_committed",0.0))-float(convoy.get("population",0))*float(convoy.get("duration_days",0.0))))
	)
	GameState.record_building_event({
		"day":int(floor(GameState.elapsed_days)),
		"settlement_id":String(record.id),
		"settlement_name":String(record.name),
		"event":"founded",
		"kind":"Founding settlement",
		"form":"founding_household_and_communal_fabric",
		"land_use":"communal",
		"materials":(convoy.get("materials_committed",{}) as Dictionary).duplicate(true),
		"counts_materials":true,
		"condition":1.0,
		"status":"active",
		"note":"Founders converted their carried construction supplies into the first enduring local fabric.",
	})
	GameState.settlement_convoy={}
	GameState.settlement_network_revision+=1
	return {"ok":true,"settlement":record.duplicate(true),"population":roundi(_settlement_population(record))}

func _create_founding_nucleus()->void:
	var nucleus_id:=GameState.next_settlement_nucleus_id
	GameState.next_settlement_nucleus_id+=1
	GameState.settlement_nuclei.append({"id":nucleus_id,"kind":"founding_hearth","position":Vector2.ZERO,"pull":1.0,"active":true,"created_day":GameState.settlement_founded_day,"absorbed_day":-1})

func _create_founding_plots()->void:
	GameState.initialize_population_model()
	# Plots are a bounded visual sample of the settlement fabric.  Their resident
	# counts are aggregate population cells, never homes backed by person records.
	var population:=primary_population_exact()
	var occupied_compound_equivalents:=population/5.2
	var residential_count:=clampi(roundi(sqrt(occupied_compound_equivalents)*3.0),14,96)
	var total_count:=residential_count+FOUNDING_NONRESIDENTIAL.size()
	var residents_remaining:=_primary_population()
	var accepted_centers:Array[Vector2]=[]
	var accepted_radii:Array[float]=[]
	for index in total_count:
		var plot_id:=GameState.next_settlement_plot_id
		GameState.next_settlement_plot_id+=1
		var plot_seed:=hash("%d:settlement_plot:%d" % [GameState.world_seed,plot_id])
		var rng:=RandomNumberGenerator.new()
		rng.seed=plot_seed
		var land_use:="residential_compound"
		if index<residential_count:
			land_use="mixed_household" if index%4==1 else "residential_compound"
		else:
			land_use=String(FOUNDING_NONRESIDENTIAL[index-residential_count])
		var radius:=rng.randf_range(0.0065,0.0105) if index<residential_count else rng.randf_range(0.008,0.013)
		var center:=Vector2.ZERO
		for attempt in 32:
			center=_founding_plot_center(index,total_count,land_use,rng,attempt)
			var clear:=true
			for prior_index in accepted_centers.size():
				if center.distance_to(accepted_centers[prior_index])<(radius+accepted_radii[prior_index])*1.16:
					clear=false
					break
			if clear: break
		accepted_centers.append(center)
		accepted_radii.append(radius)
		var polygon:=_irregular_polygon(center,radius,plot_seed)
		var resident_count:=0
		var resident_capacity:=0
		if index<residential_count:
			var plots_left:=residential_count-index
			resident_count=ceili(float(residents_remaining)/float(plots_left))
			residents_remaining-=resident_count
			resident_capacity=maxi(resident_count+2,8)
		var material_family:="organic"
		var material_mix:Dictionary={"Timber":0.38,"Fiber Plants":0.42,"Clay":0.08}
		if land_use in ["water","waste"]:
			material_family="earth"
			material_mix={"Clay":0.35,"Stone":0.12,"Fiber Plants":0.08}
		var created_day:=GameState.settlement_founded_day
		var plot_form:="portable_shelter_cluster" if index<residential_count else _founding_function_form(land_use)
		var plot:Dictionary={
			"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],
			"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
			"land_use":land_use,"secondary_use":"craft" if land_use=="mixed_household" else "",
			"form":plot_form,"roof_plan":_roof_plan_for(plot_seed,material_family,plot_form),
			"material_family":material_family,"material_mix":material_mix,"construction_recipe":"founding_salvage_and_local_materials",
			"supply_provenance":{"portable_convoy_assets":true,"founding_work":"collective settlement labor"},"replacement_debt":{},"roof_coverage":rng.randf_range(0.20,0.34) if index<residential_count else rng.randf_range(0.08,0.24),"storeys":1,
			"resident_capacity":resident_capacity,"resident_count":resident_count,"worker_capacity":2 if land_use in ["mixed_household","workshop","storage"] else 0,
			"worker_count":1 if land_use in ["mixed_household","workshop","storage"] else 0,"storage_capacity":4.0 if land_use=="storage" else (0.8 if index<residential_count else 0.0),
			"condition":rng.randf_range(0.72,0.88),"maintenance_debt":rng.randf_range(0.02,0.08),"service_access":clampf(1.0-center.length()/0.11,0.18,1.0),
			"hazard_exposure":rng.randf_range(0.06,0.18),"prosperity":rng.randf_range(0.28,0.48),"status":"active","pre_damage_use":"",
			"damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":rng.randf_range(0.0,0.04)},
			"habitability":0.84 if index<residential_count else 0.70,"repair_state":"maintained","reoccupation_state":"occupied",
			"displaced_households":0,"returning_households":0,"claim_pressure":0.0,
			"created_day":created_day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":created_day
		}
		GameState.settlement_plots.append(plot)
		GameState.settlement_plot_history.append({"day":created_day,"plot_id":plot_id,"event":"founded","new_state":"active","cause":"Initial settlement fabric established"})
		_record_plot_building_event(plot,"founded",created_day,{},false,"Raised from carried shelter, salvaged fabric, and locally gathered material.")

func _founding_plot_center(index:int,total_count:int,land_use:String,rng:RandomNumberGenerator,attempt:int)->Vector2:
	var seed_angle:=float(abs(GameState.world_seed)%6283)*0.001
	if land_use=="communal":
		return Vector2(rng.randf_range(-0.004,0.004),rng.randf_range(-0.004,0.004)) if attempt==0 else Vector2.from_angle(seed_angle+attempt*1.77)*float(attempt)*0.0028
	if land_use=="water":
		return Vector2.from_angle(seed_angle+PI*0.82+attempt*0.17)*rng.randf_range(0.066,0.084)
	if land_use=="waste":
		return Vector2.from_angle(seed_angle-PI*0.32+attempt*0.19)*rng.randf_range(0.080,0.105)
	var cluster_count:=4
	var cluster_index:int=(index*7+absi(GameState.world_seed))%cluster_count
	var cluster_angle:=seed_angle+float(cluster_index)*TAU/float(cluster_count)+sin(float(cluster_index*19+GameState.world_seed))*0.34
	var cluster_distance:=0.020+float(cluster_index%2)*0.012+rng.randf_range(-0.003,0.006)
	var cluster_center:=Vector2.from_angle(cluster_angle)*cluster_distance
	var local_angle:=seed_angle+float(index)*2.399963229728653+float(attempt)*1.37
	var local_radius:=rng.randf_range(0.008,0.027)+float(attempt)*0.0012
	if land_use=="storage":
		cluster_center*=0.45
		local_radius*=0.48
	elif land_use=="workshop":
		cluster_center*=0.74
		local_radius*=0.72
	var position:=cluster_center+Vector2.from_angle(local_angle)*local_radius
	# Preserve the founding hearth as a real nucleus. Household claims begin beyond
	# its shared working/meeting clearance instead of accidentally occupying it first.
	if land_use in ["residential_compound","mixed_household"] and position.length()<0.025:
		position=position.normalized()*0.025 if position.length()>0.0001 else Vector2.from_angle(local_angle)*0.025
	return position

func _irregular_polygon(center:Vector2,radius:float,plot_seed:int)->PackedVector2Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed^0x5f3759df
	var vertices:=rng.randi_range(5,8)
	var rotation:=rng.randf_range(0.0,TAU)
	var polygon:=PackedVector2Array()
	for vertex_index in vertices:
		var angle:=rotation+TAU*float(vertex_index)/float(vertices)+rng.randf_range(-0.11,0.11)
		var vertex_radius:=radius*rng.randf_range(0.72,1.18)
		polygon.append(center+Vector2(cos(angle),sin(angle))*vertex_radius)
	return polygon

func _founding_function_form(land_use:String)->String:
	return {"communal":"open_hearth_yard","storage":"guarded_cache","workshop":"open_work_yard","water":"carried_water_point","waste":"refuse_and_latrine_ground"}.get(land_use,"open_ground")

func _create_founding_routes()->void:
	var route_id:=1
	var connected_centers:Array[Vector2]=[Vector2.ZERO]
	var plots_by_distance:=GameState.settlement_plots.duplicate(false)
	plots_by_distance.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return Vector2(a.centroid).length()<Vector2(b.centroid).length())
	for plot in plots_by_distance:
		var plot_center:=Vector2(plot.centroid)
		var nearest:=connected_centers[0]
		var nearest_distance:=plot_center.distance_to(nearest)
		for candidate in connected_centers:
			var distance:=plot_center.distance_to(candidate)
			if distance<nearest_distance:
				nearest=candidate
				nearest_distance=distance
		var direction:=nearest-plot_center
		var side:=Vector2(-direction.y,direction.x).normalized()
		var bend_strength:=minf(0.005,nearest_distance*0.16)
		var bend_a:=plot_center.lerp(nearest,0.34)+side*sin(float(int(plot.id)*37+GameState.world_seed))*bend_strength
		var bend_b:=plot_center.lerp(nearest,0.69)-side*sin(float(int(plot.id)*19+GameState.world_seed)*0.73)*bend_strength*0.68
		var route:Dictionary={"id":route_id,"kind":"desire_path","points":PackedVector2Array([plot_center,bend_a,bend_b,nearest]),"condition":0.38+float(int(plot.id)%5)*0.025,"width_m":0.62+float(int(plot.id)%4)*0.11,"created_day":GameState.settlement_founded_day,"active":true}
		GameState.settlement_routes.append(route)
		plot["frontage_route_id"]=route_id
		connected_centers.append(plot_center)
		route_id+=1

func process_month(context:Dictionary={})->Array[Dictionary]:
	ensure_founded()
	if GameState.settlement_plots.is_empty(): return []
	var month_day:=int(floor(GameState.elapsed_days/30.0))*30
	if month_day<=GameState.last_morphology_day: return []
	GameState.last_morphology_day=month_day
	var events:Array[Dictionary]=[]
	var active_construction:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="under_construction": active_construction.append(plot)
	var builders:=GameState.effective_workers("Construction")
	var labor_efficiency:=float(GameState.simulation_metrics.get("labor_efficiency",0.72))
	var builders_per_site:=builders/float(maxi(1,active_construction.size()))
	for plot in GameState.settlement_plots:
		plot["last_update_day"]=month_day
		if String(plot.get("status",""))=="under_construction":
			var previous_progress:=float(plot.get("construction_progress",0.0))
			# Parallel projects divide the real monthly builder pool. A large population
			# can build concurrently, but no site receives the whole workforce for free.
			var directive_pace:=1.0+maxf(0.0,ConsequenceEngine.policy_effect("construction_rate"))
			plot["construction_progress"]=clampf(previous_progress+builders_per_site*labor_efficiency*directive_pace*0.10,0.0,1.0)
			if not is_equal_approx(previous_progress,float(plot.construction_progress)):
				GameState.morphology_revision+=1
			if float(plot.construction_progress)>=1.0:
				plot["status"]="active"
				plot["condition"]=0.92
				plot["repair_state"]="maintained"
				GameState.settlement_plot_history.append({"day":month_day,"plot_id":int(plot.id),"event":"construction_completed","new_state":"active","cause":String(plot.get("growth_cause","household pressure"))})
				_record_plot_building_event(plot,"completed",month_day,{},false,String(plot.get("growth_cause","Construction completed.")))
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":_completion_title(String(plot.get("land_use","residential_compound"))),"plot_id":int(plot.id)})
	_synchronize_early_works(month_day,events)
	_evolve_inherited_fabric(month_day,events)
	_update_plot_workforce(month_day,events)
	_update_plot_prosperity(month_day)
	_update_field_seasons(month_day)
	_process_occupancy_and_maintenance(month_day,events)
	_update_overflow_encampments(month_day,events)
	_attempt_mature_district_expansion(month_day,events,context)
	_attempt_secondary_nucleus(month_day,events,context)
	_attempt_overflow_encampment(month_day,events,context)
	_attempt_functional_growth(month_day,events,context)
	var construction_slots:=_monthly_construction_slots()
	var available_household_starts:=maxi(0,construction_slots-_active_construction_count())
	for action_index in available_household_starts:
		if not _attempt_household_growth(month_day,events,context,action_index): break
	_attempt_field_growth(month_day,events,context)
	_bound_morphology_state()
	rebuild_summary()
	return events

func _bound_morphology_state()->void:
	# Historical detail is summarized by current plot state; old event rows are
	# telemetry, not authoritative geometry.
	if GameState.settlement_plot_history.size()>MAX_PLOT_HISTORY:
		GameState.settlement_plot_history=GameState.settlement_plot_history.slice(GameState.settlement_plot_history.size()-MAX_PLOT_HISTORY)
	if GameState.settlement_routes.size()>MAX_SIMULATED_ROUTES:
		GameState.settlement_routes.resize(MAX_SIMULATED_ROUTES)
	if GameState.settlement_nuclei.size()>MAX_SIMULATED_NUCLEI:
		GameState.settlement_nuclei.resize(MAX_SIMULATED_NUCLEI)

func _can_add_plots(amount:=1)->bool:
	return GameState.settlement_plots.size()+maxi(0,amount)<=MAX_SIMULATED_PLOTS

func _active_construction_count()->int:
	var count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="under_construction": count+=1
	return count

func _monthly_construction_slots()->int:
	var builders:=GameState.effective_workers("Construction")
	if builders<4.0: return 0
	var efficiency:=clampf(float(GameState.simulation_metrics.get("labor_efficiency",0.72)),0.12,1.45)
	# One early household project occupies roughly six effective builder-months.
	# Administrative/logistical maturity raises the safe coordination ceiling but
	# does not conjure labor or materials.
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.12)),0.0,1.0)
	var coordination_cap:=3+floori(logistics*9.0)
	var directive_pace:=1.0+maxf(0.0,ConsequenceEngine.policy_effect("construction_rate"))
	return clampi(maxi(1,floori(builders*efficiency*directive_pace/6.0)),1,coordination_cap)

func _update_plot_prosperity(day:int)->void:
	var economy:=GameState.economy_metrics
	var market_access:=float(economy.get("market_access",0.0))
	var reliability:=float(economy.get("exchange_reliability",0.45))
	var shortage:=float(economy.get("shortage_pressure",0.0))
	var inequality:=float(economy.get("inequality",0.25))
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) in ["ruin","reclaimed"]: continue
		var use:=String(plot.get("land_use",""))
		var exchange_exposure:=0.22
		if use in ["market","workshop","storage","hospitality","transport"]: exchange_exposure=0.48
		elif use in ["mixed_household","civic","communal"]: exchange_exposure=0.34
		elif use in ["field","pasture","water"]: exchange_exposure=0.16
		var service:=clampf(float(plot.get("service_access",0.2)),0.0,1.0)
		var condition:=clampf(float(plot.get("condition",0.6)),0.0,1.0)
		var target:=clampf(0.12+market_access*exchange_exposure+reliability*0.16+service*0.14+condition*0.10-shortage*0.34-maxf(0.0,inequality-0.30)*0.18,0.03,0.94)
		var prior:=float(plot.get("prosperity",0.30))
		plot["prosperity"]=lerpf(prior,target,0.12)
		if absf(float(plot.prosperity)-prior)>0.001: GameState.morphology_revision+=1
		plot["last_economy_update_day"]=day

func _attempt_secondary_nucleus(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if not _can_add_plots(): return
	var occupied_households:Array[Dictionary]=[]
	var effective_household_units:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		if String(plot.get("status","")) not in ["active","stressed","damaged"]: continue
		occupied_households.append(plot)
		effective_household_units+=maxi(1,int(plot.get("infill_units",0))+1)
	var desired_nuclei:=clampi(1+floori(float(maxi(0,effective_household_units-24))/28.0),1,8)
	if _active_nuclei()>=desired_nuclei: return
	var route_by_id:Dictionary={}
	for route in GameState.settlement_routes:
		if bool(route.get("active",true)): route_by_id[int(route.get("id",-1))]=route
	var best_plot:Dictionary={}
	var best_score:=-INF
	for plot in occupied_households:
		var candidate:=Vector2(plot.get("centroid",Vector2.ZERO))
		var nearest_nucleus:=INF
		for nucleus in GameState.settlement_nuclei:
			if bool(nucleus.get("active",true)):
				nearest_nucleus=minf(nearest_nucleus,candidate.distance_to(Vector2(nucleus.get("position",Vector2.ZERO))))
		if nearest_nucleus<0.085: continue
		var route:Dictionary=route_by_id.get(int(plot.get("frontage_route_id",-1)),{})
		var hierarchy_bonus:float=float({"path":0.0,"lane":0.42,"main_approach":0.86,"farm_lane":0.24}.get(String(route.get("hierarchy","path")),0.0))
		var score:=nearest_nucleus*5.4+float(route.get("traffic",0.0))*0.92+float(hierarchy_bonus)+float(plot.get("service_access",0.0))*0.34
		var origin:Vector3=context.get("settlement_origin",GameState.settlement_founded_at)
		var height_callable:Callable=context.get("terrain_height_at",Callable())
		if height_callable.is_valid():
			var sample:=0.015
			var world_x:=origin.x+candidate.x
			var world_z:=origin.z+candidate.y
			var slope:=maxf(absf(float(height_callable.call(world_x+sample,world_z))-float(height_callable.call(world_x-sample,world_z))),absf(float(height_callable.call(world_x,world_z+sample))-float(height_callable.call(world_x,world_z-sample))))/(sample*2.0)
			if slope>0.28: continue
			score-=slope*2.6
		if score>best_score:
			best_score=score
			best_plot=plot
	if best_plot.is_empty(): return
	var nucleus_id:=GameState.next_settlement_nucleus_id
	GameState.next_settlement_nucleus_id+=1
	var nucleus_kind:="market_crossing" if nucleus_id%3==0 else "neighborhood_hearth"
	var nucleus_position:=Vector2(best_plot.get("centroid",Vector2.ZERO))
	GameState.settlement_nuclei.append({"id":nucleus_id,"kind":nucleus_kind,"position":nucleus_position,"pull":0.78 if nucleus_kind=="market_crossing" else 0.66,"active":true,"created_day":day,"absorbed_day":-1,"founding_plot_id":int(best_plot.get("id",-1))})
	best_plot["nucleus_id"]=nucleus_id
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(best_plot.get("id",-1)),"event":"secondary_nucleus_formed","new_state":nucleus_kind,"cause":"outer households and inherited route traffic formed a durable local focus"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"A New Local Centre Emerged","plot_id":int(best_plot.get("id",-1)),"nucleus_id":nucleus_id})

func _attempt_mature_district_expansion(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if not _can_add_plots(6): return
	# Dense inherited compounds can absorb population for centuries, but a capable
	# city also externalizes service load into new quarters. This annual process is
	# deliberately separate from ordinary housing pressure: it founds a connected
	# satellite only when real coordination, route knowledge, labour and delivered
	# material can support another daily centre.
	if day%360!=0 or _settlement_age_years(day)<4.0: return
	var population:=_primary_population()
	if population<1800: return
	var builders:=int(GameState.population_allocations.get("Construction",0))
	var logisticians:=int(GameState.population_allocations.get("Logistics",0))
	var administrators:=int(GameState.population_allocations.get("Administration",0))
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.0)),0.0,1.0)
	if builders<24 or logisticians<12 or administrators<8 or logistics<0.28: return
	if "route_memory" not in GameState.known_discoveries and "graded_roads" not in GameState.known_discoveries: return
	var satellite_count:=0
	for nucleus in GameState.settlement_nuclei:
		if bool(nucleus.get("active",true)) and String(nucleus.get("kind","")) in ["satellite_quarter","industrial_satellite","river_quarter"]:
			satellite_count+=1
	var desired_satellites:=clampi(1+floori(float(maxi(0,population-1800))/3500.0),1,6)
	if satellite_count>=desired_satellites: return
	var recipe:=_available_household_recipe()
	if recipe.is_empty(): return
	var cluster_cost:Dictionary={}
	for resource_name in recipe.cost:
		# The bill covers the outer focus and the inhabited approach that makes it a
		# connected quarter. A long empty line between two roof clusters is not urban
		# expansion and must not be created for the price of one household plot.
		cluster_cost[resource_name]=float(recipe.cost[resource_name])*14.0
	if not _can_pay_fabric_cost(cluster_cost): return
	var occupied_extent:=0.10
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="reclaimed": continue
		occupied_extent=maxf(occupied_extent,Vector2(plot.get("centroid",Vector2.ZERO)).length())
	var ring_distance:=clampf(occupied_extent+0.11,0.19,1.05)
	var district_seed:=hash("%d:district:%d:%d" % [GameState.world_seed,GameState.next_settlement_nucleus_id,day])
	var rng:=RandomNumberGenerator.new()
	rng.seed=district_seed
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	for attempt in 96:
		var angle:=rng.randf()*TAU
		var candidate:=Vector2.from_angle(angle)*ring_distance*rng.randf_range(0.94,1.08)
		var nearest_nucleus_distance:=INF
		for nucleus in GameState.settlement_nuclei:
			if bool(nucleus.get("active",true)):
				nearest_nucleus_distance=minf(nearest_nucleus_distance,candidate.distance_to(Vector2(nucleus.get("position",Vector2.ZERO))))
		if nearest_nucleus_distance<0.12: continue
		var score:=_growth_site_score(candidate,0.014,"mixed_household",context)
		if score<=-9000.0: continue
		# A quarter is valuable when it extends the inherited settlement without
		# becoming an isolated new town. Gentle seeded asymmetry prevents rings.
		score+=exp(-absf(candidate.length()-ring_distance)/0.10)*1.35
		score+=rng.randf_range(-0.12,0.12)
		if score>best_score:
			best_score=score
			best_center=candidate
	if best_score<=-9000.0: return
	for resource_name in cluster_cost:
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(cluster_cost[resource_name]))
	var nucleus_id:=GameState.next_settlement_nucleus_id
	GameState.next_settlement_nucleus_id+=1
	var previous_nucleus_position:=Vector2.ZERO
	var previous_distance:=INF
	for nucleus in GameState.settlement_nuclei:
		if not bool(nucleus.get("active",true)): continue
		var nucleus_position:=Vector2(nucleus.get("position",Vector2.ZERO))
		var distance:=best_center.distance_to(nucleus_position)
		if distance<previous_distance:
			previous_distance=distance
			previous_nucleus_position=nucleus_position
	GameState.settlement_nuclei.append({"id":nucleus_id,"kind":"satellite_quarter","position":best_center,"pull":0.82,"active":true,"created_day":day,"absorbed_day":-1})
	var generation:=clampi(_supported_fabric_tier(day),0,4)
	var created_plots:Array[Dictionary]=[]
	created_plots.append(_make_district_seed_plot(best_center,0.014,"mixed_household",recipe,day,nucleus_id,generation,0))
	for companion_index in 2:
		var companion_angle:=rng.randf()*TAU+float(companion_index)*PI
		var companion_center:=best_center+Vector2.from_angle(companion_angle)*rng.randf_range(0.030,0.037)
		if _growth_site_score(companion_center,0.009,"residential_compound",context)<=-9000.0: continue
		created_plots.append(_make_district_seed_plot(companion_center,0.009,"residential_compound",recipe,day,nucleus_id,generation,companion_index+1))
	var corridor_direction:=best_center-previous_nucleus_position
	var corridor_side:=Vector2(-corridor_direction.y,corridor_direction.x).normalized()
	for corridor_index in 5:
		var corridor_t:=0.18+float(corridor_index)*0.155
		var corridor_center:=previous_nucleus_position.lerp(best_center,corridor_t)
		corridor_center+=corridor_side*sin(float(corridor_index+1)*1.71+float(district_seed%997)*0.013)*rng.randf_range(0.010,0.023)
		if _growth_site_score(corridor_center,0.0075,"residential_compound",context)<=-9000.0: continue
		var separated:=true
		for seeded_plot in created_plots:
			if corridor_center.distance_to(Vector2(seeded_plot.centroid))<0.024:
				separated=false
				break
		if not separated: continue
		created_plots.append(_make_district_seed_plot(corridor_center,0.0075,"residential_compound",recipe,day,nucleus_id,generation,corridor_index+3))
	var connector_id:=_create_district_connector(best_center,previous_nucleus_position,day)
	for created_index in created_plots.size():
		var plot:Dictionary=created_plots[created_index]
		if created_index==0: plot["frontage_route_id"]=connector_id
		GameState.settlement_plots.append(plot)
		if created_index>0: _create_growth_route(plot,day)
		GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"district_ground_claimed","new_state":String(plot.land_use),"cause":"regional service pressure, route access, administration, construction labour, and delivered materials"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"A Connected Quarter Was Founded","plot_id":int(created_plots[0].id),"nucleus_id":nucleus_id,"plots":created_plots.size()})

func _make_district_seed_plot(center:Vector2,radius:float,land_use:String,recipe:Dictionary,day:int,nucleus_id:int,generation:int,member_index:int)->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	GameState.next_settlement_plot_id+=1
	var plot_seed:=hash("%d:district_plot:%d:%d" % [GameState.world_seed,plot_id,member_index])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var polygon:=_irregular_polygon(center,radius,plot_seed)
	var form:=_fabric_form_for(land_use,generation,String(recipe.form))
	var era_names:=["founding","foothold","hamlet","village","local_centre"]
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":nucleus_id,"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":land_use,"secondary_use":"exchange" if land_use=="mixed_household" else "","form":form,"roof_plan":_roof_plan_for(plot_seed,String(recipe.family),form),"material_family":recipe.family,"material_mix":recipe.mix.duplicate(true),"construction_recipe":"connected_district_seed","supply_provenance":recipe.cost.duplicate(true),"replacement_debt":{},"roof_coverage":0.34 if land_use=="mixed_household" else 0.28,"storeys":1,
		"resident_capacity":rng.randi_range(12,18) if land_use=="mixed_household" else rng.randi_range(7,10),"resident_count":0,"worker_capacity":5 if land_use=="mixed_household" else 1,"worker_count":0,"storage_capacity":2.4 if land_use=="mixed_household" else 0.8,
		"condition":0.60,"maintenance_debt":0.0,"service_access":0.42,"hazard_exposure":rng.randf_range(0.08,0.20),"prosperity":0.34,"status":"under_construction","construction_progress":0.0,"growth_cause":"connected district expansion","fabric_generation":generation,"morphology_era":era_names[generation],
		"pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied","displaced_households":0,"returning_households":0,"claim_pressure":0.0,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _create_district_connector(start:Vector2,finish:Vector2,day:int)->int:
	var route_id:=1
	for route in GameState.settlement_routes: route_id=maxi(route_id,int(route.get("id",0))+1)
	var direction:=finish-start
	var side:=Vector2(-direction.y,direction.x).normalized()
	var bend:=minf(0.060,direction.length()*0.16)
	var graded:="graded_roads" in GameState.known_discoveries
	GameState.settlement_routes.append({
		"id":route_id,"kind":"district_connector","hierarchy":"main_approach","points":PackedVector2Array([start,start.lerp(finish,0.18)+side*bend*0.72,start.lerp(finish,0.39)+side*bend,start.lerp(finish,0.62)-side*bend*0.48,start.lerp(finish,0.82)-side*bend*0.22,finish]),
		"condition":0.72 if graded else 0.48,"width_m":4.6 if graded else 2.8,"surface_tier":3 if graded else 1,"surface":"drained_earth" if graded else "cleared_earth","traffic":0.44,"created_day":day,"active":true
	})
	return route_id

func _permanent_resident_capacity()->int:
	var capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		if String(plot.get("status","")) not in ["active","stressed","damaged"]: continue
		capacity+=int(plot.get("resident_capacity",0))
	return capacity

func _update_overflow_encampments(day:int,events:Array[Dictionary])->void:
	var camps:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))=="temporary_encampment": camps.append(plot)
	camps.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.get("created_day",0))<int(b.get("created_day",0)))
	var remaining:=maxi(0,_primary_population()-_permanent_resident_capacity())
	for camp in camps:
		var prior_population:=int(camp.get("resident_count",0))
		var target:=int(camp.get("camp_target_population",90))
		var assigned:=mini(remaining,target)
		remaining-=assigned
		camp["resident_count"]=assigned
		camp["last_update_day"]=day
		var previous_status:=String(camp.get("status","active"))
		if assigned<=0:
			camp["vacant_months"]=int(camp.get("vacant_months",0))+1
			if int(camp.vacant_months)>=3: camp["status"]="vacant"
		else:
			camp["vacant_months"]=0
			camp["status"]="active"
		if prior_population!=assigned or String(camp.get("status","active"))!=previous_status:
			GameState.morphology_revision+=1
			if previous_status!="vacant" and String(camp.status)=="vacant":
				GameState.settlement_plot_history.append({"day":day,"plot_id":int(camp.id),"event":"overflow_camp_emptied","new_state":"vacant","cause":"permanent household capacity absorbed the displaced population"})
				events.append({"type":"morphology","title":"A Temporary Camp Emptied","plot_id":int(camp.id)})

func _attempt_overflow_encampment(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if not _can_add_plots(): return
	var permanent_capacity:=_permanent_resident_capacity()
	var represented_in_camps:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))=="temporary_encampment" and String(plot.get("status",""))=="active": represented_in_camps+=int(plot.get("resident_count",0))
	var unrepresented:=_primary_population()-permanent_capacity-represented_in_camps
	if unrepresented<28: return
	var camp_labor:=int(GameState.population_allocations.get("Construction",0))+int(GameState.population_allocations.get("Logistics",0))
	if camp_labor<4: return
	var plot:=_create_overflow_encampment(day,unrepresented,context)
	if plot.is_empty(): return
	_create_growth_route(plot,day,"camp_path")
	GameState.settlement_plots.append(plot)
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"overflow_camp_formed","new_state":"active","cause":"population exceeded durable household capacity; families occupied temporary ground using carried and salvaged cover"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"Families Occupied Temporary Ground","plot_id":int(plot.id)})

func _create_overflow_encampment(day:int,unrepresented:int,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:overflow_encampment:%d" % [GameState.world_seed,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var target_population:=mini(unrepresented,rng.randi_range(72,132))
	# Temporary family ground is still real ground. Derive its footprint from a
	# crowded but plausible open-camp density instead of squeezing a hundred people
	# into a decorative twenty-metre speck. This keeps the scale bar honest and
	# makes emergency expansion legible from the aerial camera.
	var camp_density_per_hectare:=rng.randf_range(210.0,340.0)
	var radius:=clampf(sqrt((float(target_population)/camp_density_per_hectare)/100.0/PI),0.027,0.045)
	var anchors:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("status","")) in ["ruin","reclaimed","vacant"]: continue
		if String(existing.get("land_use","")) in ["water","waste","field"]: continue
		anchors.append(existing)
	if anchors.is_empty(): return {}
	anchors.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return Vector2(a.get("centroid",Vector2.ZERO)).length()>Vector2(b.get("centroid",Vector2.ZERO)).length())
	var outer_count:=maxi(1,ceili(float(anchors.size())*0.42))
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	for attempt in 80:
		var anchor:Dictionary=anchors[rng.randi_range(0,outer_count-1)]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_radius:=sqrt(_polygon_area_km2(anchor.get("polygon",PackedVector2Array()))/PI)
		var nucleus_position:=Vector2.ZERO
		var nearest_nucleus_distance:=INF
		for nucleus in GameState.settlement_nuclei:
			if not bool(nucleus.get("active",true)): continue
			var candidate_position:=Vector2(nucleus.get("position",Vector2.ZERO))
			var distance:=anchor_center.distance_to(candidate_position)
			if distance<nearest_nucleus_distance:
				nearest_nucleus_distance=distance
				nucleus_position=candidate_position
		var outward:=(anchor_center-nucleus_position).normalized()
		if outward.length_squared()<0.01: outward=Vector2.from_angle(rng.randf()*TAU)
		var direction:=outward.rotated(rng.randf_range(-0.72,0.72))
		var center:=anchor_center+direction*(anchor_radius+radius+rng.randf_range(0.006,0.018))
		var score:=_growth_site_score(center,radius,"residential_compound",context)
		score+=center.distance_to(nucleus_position)*2.1
		if center.distance_to(nucleus_position)>0.72: score-=8.0
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	GameState.next_settlement_plot_id+=1
	var polygon:=_irregular_polygon(best_center,radius,plot_seed)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":_nearest_nucleus_id(best_center),"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":"temporary_encampment","secondary_use":"displaced_households","form":"emergency_open_encampment","roof_plan":"mixed_light_shelters","material_family":"organic","material_mix":{"Fiber Plants":0.10,"Timber":0.03},"construction_recipe":"carried_cover_and_salvaged_ground","supply_provenance":{"Personal Baggage":"retained","Salvage":"local"},"replacement_debt":{"Fiber Plants":0.90},"roof_coverage":rng.randf_range(0.045,0.085),"storeys":1,
		"resident_capacity":0,"resident_count":target_population,"camp_target_population":target_population,"shelter_capacity":roundi(float(target_population)*rng.randf_range(0.16,0.34)),"worker_capacity":0,"worker_count":0,"storage_capacity":0.2,"condition":rng.randf_range(0.28,0.46),"maintenance_debt":0.72,"service_access":0.12,"hazard_exposure":rng.randf_range(0.22,0.42),"prosperity":0.08,
		"status":"active","construction_progress":1.0,"growth_cause":"population exceeded permanent shelter capacity","pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.18},"habitability":0.18,"repair_state":"awaiting_materials","reoccupation_state":"displaced","vacant_months":0,
		"displaced_households":ceili(float(target_population)/5.0),"returning_households":0,"claim_pressure":0.38,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _completion_title(land_use:String)->String:
	return {
		"workshop":"New Working Ground Entered Use",
		"storage":"New Stores Entered Use",
		"residential_compound":"New Household Ground Occupied",
		"mixed_household":"New Household Ground Occupied"
	}.get(land_use,"New Ground Entered Use")

func _has_active_construction()->bool:
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="under_construction": return true
	return false

func _recognized_fertile_ground()->Dictionary:
	for deposit in GameState.resource_deposits:
		if String(deposit.get("resource",""))=="Fertile Soil" and String(deposit.get("stage","unknown")) in ["surveyed","accessible","developed"]:
			return deposit
	return {}

func _update_field_seasons(day:int)->void:
	var visual_state_changed:=false
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))!="field": continue
		var previous_phase:=String(plot.get("cultivation_phase","prepared"))
		var previous_cover:=float(plot.get("crop_cover",0.0))
		var phase:="fallow"
		var cover:=0.08
		if int(plot.get("worker_count",0))>0 and String(plot.get("status","active"))=="active":
			var local_day:=fposmod(float(day+(absi(int(plot.get("seed",1)))%29)-14),365.0)
			if local_day<48.0:
				phase="fallow"; cover=0.10
			elif local_day<82.0:
				phase="prepared"; cover=0.16
			elif local_day<205.0:
				phase="growing"; cover=lerpf(0.32,0.88,(local_day-82.0)/123.0)
			elif local_day<258.0:
				phase="mature"; cover=0.94
			elif local_day<310.0:
				phase="harvested"; cover=0.22
			else:
				phase="fallow"; cover=0.09
			if float(plot.get("condition",1.0))<0.46:
				phase="stressed"
				cover*=0.46
		plot["cultivation_phase"]=phase
		plot["crop_cover"]=clampf(cover,0.0,1.0)
		if phase!=previous_phase or absf(cover-previous_cover)>=0.03: visual_state_changed=true
	if visual_state_changed: GameState.morphology_revision+=1

func _update_plot_workforce(day:int,events:Array[Dictionary])->void:
	var role_by_use:Dictionary={"field":"Food","workshop":"Crafting","storage":"Logistics"}
	for land_use in role_by_use:
		var role:=String(role_by_use[land_use])
		var available:=maxi(0,int(GameState.population_allocations.get(role,0)))
		var candidates:Array[Dictionary]=[]
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use",""))!=land_use: continue
			if String(plot.get("status","")) in ["under_construction","ruin","reclaimed"]: continue
			candidates.append(plot)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			return float(a.get("service_access",0.0))+float(a.get("condition",0.0))*0.25>float(b.get("service_access",0.0))+float(b.get("condition",0.0))*0.25)
		for plot in candidates:
			var capacity:=maxi(0,int(plot.get("worker_capacity",0)))
			var assigned:=mini(capacity,available)
			available-=assigned
			plot["worker_count"]=assigned
			var idle_months:=int(plot.get("idle_months",0))
			var previous_status:=String(plot.get("status","active"))
			if assigned<=0:
				idle_months+=1
				plot["idle_months"]=idle_months
				if idle_months>=6 and previous_status not in ["damaged","ruin"]:
					plot["status"]="vacant"
					plot["reoccupation_state"]="temporary_use" if idle_months<36 else "permanently_abandoned"
			else:
				plot["idle_months"]=0
				if previous_status=="vacant" and float(plot.get("condition",0.0))>=0.28:
					plot["status"]="active"
					plot["reoccupation_state"]="reoccupied"
			if String(plot.get("status",""))!=previous_status:
				GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"work_ground_idled" if assigned<=0 else "work_ground_reoccupied","new_state":String(plot.status),"cause":"%s labor allocation changed" % role})
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":"%s %s" % [land_use.capitalize(),"Fell Idle" if assigned<=0 else "Returned to Use"],"plot_id":int(plot.id)})

func _attempt_field_growth(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if not _can_add_plots(): return
	if "seed_selection" not in GameState.known_discoveries: return
	var food_workers:=int(GameState.population_allocations.get("Food",0))
	if food_workers<10: return
	var fertile_ground:=_recognized_fertile_ground()
	if fertile_ground.is_empty(): return
	var field_count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))=="field" and String(plot.get("status","")) not in ["ruin","reclaimed"]: field_count+=1
	# One field plot is an aggregate worked by at most twelve assigned people.
	# Keep enough persistent plots to represent the labor that actually exists;
	# the old cap of eighteen visually erased hundreds of food workers.
	var target_fields:=clampi(ceili(float(food_workers)/12.0),1,72)
	if field_count>=target_fields: return
	var plot:=_create_field_plot(day,fertile_ground,field_count,context)
	if plot.is_empty(): return
	_create_growth_route(plot,day,"field_track")
	GameState.settlement_plots.append(plot)
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"field_opened","new_state":"active","cause":"seed selection, assigned food labor, and surveyed fertile soil"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"Cultivation Opened at the Settlement Fringe","plot_id":int(plot.id)})

func _create_field_plot(day:int,fertile_ground:Dictionary,field_index:int,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_field:%d" % [GameState.world_seed,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var settlement_world:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var deposit_position:Vector3=fertile_ground.get("position",GameState.settlement_founded_at)
	var direction:=Vector2(deposit_position.x,deposit_position.z)-settlement_world
	if direction.length()<0.01: direction=Vector2.from_angle(rng.randf()*TAU)
	direction=direction.normalized()
	# A single authoritative plot represents a household-scale smallholding.  The
	# former 14-26 m base radius produced 0.4-0.8 ha cards that dominated the close
	# aerial view; several smaller inherited parcels create the observed patchwork.
	var radius:=rng.randf_range(0.010,0.019)
	var center:=Vector2.ZERO
	var found:=false
	var best_center:=Vector2.ZERO
	var best_site_score:=-INF
	var origin:Vector3=context.get("settlement_origin",GameState.settlement_founded_at)
	var height_callable:Callable=context.get("terrain_height_at",Callable())
	var river_callable:Callable=context.get("river_distance_at",Callable())
	var drainage_tangent_callable:Callable=context.get("drainage_tangent_at",Callable())
	var moisture_callable:Callable=context.get("moisture_at",Callable())
	var buildable_callable:Callable=context.get("buildable_land_at",Callable())
	var existing_fields:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("land_use",""))=="field" and String(existing.get("status","")) not in ["ruin","reclaimed"]: existing_fields.append(existing)
	for attempt in 80:
		if not existing_fields.is_empty() and rng.randf()<0.78:
			var anchor:Dictionary=existing_fields[rng.randi_range(0,existing_fields.size()-1)]
			var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
			var anchor_radius:=sqrt(_polygon_area_km2(anchor.get("polygon",PackedVector2Array()))/PI)
			var seam_angle:=direction.angle()+PI*0.5*rng.randi_range(-1,1)+rng.randf_range(-0.42,0.42)
			center=anchor_center+Vector2.from_angle(seam_angle)*(anchor_radius+radius+rng.randf_range(0.0015,0.0040))
		else:
			var angle:=direction.angle()+rng.randf_range(-0.88,0.88)+float(field_index)*0.17
			center=Vector2.from_angle(angle)*rng.randf_range(0.11,0.24)
		var clear:=true
		for existing in GameState.settlement_plots:
			var existing_polygon:PackedVector2Array=existing.get("polygon",PackedVector2Array())
			var existing_radius:=sqrt(_polygon_area_km2(existing_polygon)/PI)
			var clearance_factor:=1.045 if String(existing.get("land_use",""))=="field" else 1.12
			if center.distance_to(Vector2(existing.get("centroid",Vector2.ZERO)))<(radius+existing_radius)*clearance_factor:
				clear=false
				break
		if not clear: continue
		var world_x:=origin.x+center.x
		var world_z:=origin.z+center.y
		if buildable_callable.is_valid() and not bool(buildable_callable.call(world_x,world_z)): continue
		var site_score:=rng.randf_range(-0.035,0.035)
		if height_callable.is_valid():
			var slope_sample:=0.036
			var slope_gradient:=Vector2(
				float(height_callable.call(world_x+slope_sample,world_z))-float(height_callable.call(world_x-slope_sample,world_z)),
				float(height_callable.call(world_x,world_z+slope_sample))-float(height_callable.call(world_x,world_z-slope_sample))
			)/(slope_sample*2.0)
			var slope:=slope_gradient.length()
			if slope>0.30: continue
			site_score-=slope*3.8
		if river_callable.is_valid():
			var candidate_water_distance:=float(river_callable.call(world_x,world_z))
			if candidate_water_distance<0.014: continue
			if candidate_water_distance<INF:
				# Early hand cultivation favors moist but non-inundated ground. The
				# optimum remains broad because swales can be intermittent or unreliable.
				site_score+=exp(-absf(candidate_water_distance-0.095)/0.14)*0.82
		if moisture_callable.is_valid():
			var candidate_moisture:=float(moisture_callable.call(world_x,world_z))
			site_score+=clampf(candidate_moisture+0.18,-0.18,0.42)*0.68
		if not existing_fields.is_empty(): site_score+=0.24
		# Retain the surveyed soil bearing without forcing a geometric ray of fields.
		site_score+=maxf(0.0,center.normalized().dot(direction))*0.18
		if site_score>best_site_score:
			best_site_score=site_score
			best_center=center
			found=true
	if not found: return {}
	center=best_center
	GameState.next_settlement_plot_id+=1
	var world_x:=origin.x+center.x
	var world_z:=origin.z+center.y
	var river_distance:=INF
	if river_callable.is_valid(): river_distance=float(river_callable.call(world_x,world_z))
	var moisture:=0.0
	if moisture_callable.is_valid(): moisture=float(moisture_callable.call(world_x,world_z))
	var field_pattern:="dryland_patchwork"
	if river_distance<0.42: field_pattern="irrigated_beds"
	elif moisture>0.04: field_pattern="smallholder_mosaic"
	# Crop identity is authoritative simulation state, not a renderer tint. Early
	# cultivation is heterogeneous even before formal botany: households favor
	# different gathered grains, pulses, roots, fibres, and mixed garden staples.
	var crop_families:=["mixed_staples","grain","pulses","roots","fibre_crop"]
	var crop_family:String=crop_families[absi(plot_seed)%crop_families.size()]
	if field_pattern=="irrigated_beds" and absi(plot_seed)%3==0: crop_family="garden_beds"
	var field_rotation:=direction.angle()+rng.randf_range(-0.68,0.68)+sin(float(field_index)*1.73)*0.22
	if drainage_tangent_callable.is_valid() and river_distance<0.24:
		var drainage_tangent:Vector2=drainage_tangent_callable.call(world_x,world_z)
		if drainage_tangent.length_squared()>0.1:
			# Long field edges and access strips tend to follow a nearby channel while
			# retaining household-scale irregularity. The influence fades before the
			# broad 'irrigated' classification does, preventing ruler-straight valleys.
			var drainage_alignment:=clampf(1.0-river_distance/0.24,0.0,1.0)*0.68
			field_rotation=lerp_angle(field_rotation,drainage_tangent.angle(),drainage_alignment)
	if height_callable.is_valid():
		var sample_radius:=0.045
		var gradient:=Vector2(
			float(height_callable.call(world_x+sample_radius,world_z))-float(height_callable.call(world_x-sample_radius,world_z)),
			float(height_callable.call(world_x,world_z+sample_radius))-float(height_callable.call(world_x,world_z-sample_radius))
		)/(sample_radius*2.0)
		if gradient.length()>0.002:
			var contour_angle:=Vector2(-gradient.y,gradient.x).angle()
			field_rotation=lerp_angle(field_rotation,contour_angle,clampf(gradient.length()*7.5,0.18,0.82))
	var polygon:=_irregular_field_polygon(center,radius,plot_seed,field_rotation,field_pattern)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":"field","secondary_use":"seasonal_grazing","form":"hand_cultivated_clearance","field_pattern":field_pattern,"crop_family":crop_family,"cultivation_phase":"prepared","crop_cover":0.16,"material_family":"earth","material_mix":{"Soil":0.86,"Fiber Plants":0.04},"construction_recipe":"clearing_and_hand_cultivation","supply_provenance":{"Fertile Soil":String(fertile_ground.get("id","local occurrence"))},"replacement_debt":{},"roof_coverage":0.0,"storeys":0,
		"resident_capacity":0,"resident_count":0,"worker_capacity":12,"worker_count":mini(12,int(GameState.population_allocations.get("Food",0))),"storage_capacity":0.0,"condition":0.82,"maintenance_debt":0.02,"service_access":0.28,"hazard_exposure":rng.randf_range(0.08,0.22),"prosperity":0.30,
		"status":"active","reclamation":0.0,"pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied","displaced_households":0,"returning_households":0,"claim_pressure":0.0,
		"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _irregular_field_polygon(center:Vector2,radius:float,plot_seed:int,rotation:float,field_pattern:String="smallholder_mosaic")->PackedVector2Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed^0x7f4a7c15
	var right:=Vector2.from_angle(rotation)
	var forward:=Vector2(-right.y,right.x)
	var half_length:=radius*rng.randf_range(1.08,1.62)
	var half_width:=radius*rng.randf_range(0.60,0.94)
	if field_pattern=="irrigated_beds":
		half_length*=rng.randf_range(1.12,1.42)
		half_width*=rng.randf_range(0.58,0.78)
	elif field_pattern=="dryland_patchwork":
		half_length*=rng.randf_range(0.82,1.08)
		half_width*=rng.randf_range(0.90,1.22)
	var bottom_shift:=right*rng.randf_range(-radius*0.16,radius*0.16)
	var top_shift:=right*rng.randf_range(-radius*0.18,radius*0.18)
	var left_length:=half_length*rng.randf_range(0.84,1.08)
	var right_length:=half_length*rng.randf_range(0.88,1.12)
	# Agricultural ground is inherited as skewed strips and trapezoids following
	# drainage, tenure and plough direction. The former six equal corners survived
	# feathering as a conspicuous strategy-game hex.
	return PackedVector2Array([
		center-right*left_length-forward*half_width+bottom_shift,
		center+right*right_length-forward*half_width-bottom_shift*0.35,
		center+right*right_length+forward*half_width+top_shift,
		center-right*left_length+forward*half_width-top_shift*0.30
	])

func _process_occupancy_and_maintenance(day:int,events:Array[Dictionary])->void:
	var residential:Array[Dictionary]=[]
	var total_capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		if String(plot.get("status","")) in ["ruin","reclaimed","under_construction"]: continue
		residential.append(plot)
		total_capacity+=int(plot.get("resident_capacity",0))
	residential.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var score_a:=float(a.get("service_access",0.0))+float(a.get("condition",0.0))*0.35-float(a.get("hazard_exposure",0.0))*0.20
		var score_b:=float(b.get("service_access",0.0))+float(b.get("condition",0.0))*0.35-float(b.get("hazard_exposure",0.0))*0.20
		return score_a>score_b)
	var primary_population:=_primary_population()
	var occupancy_ratio:=clampf(float(primary_population)/maxf(1.0,float(total_capacity)),0.0,1.0)
	var assigned:=0
	for index in residential.size():
		var plot:=residential[index]
		var desired:=mini(int(plot.get("resident_capacity",0)),roundi(float(plot.get("resident_capacity",0))*occupancy_ratio))
		if index==residential.size()-1: desired=mini(int(plot.get("resident_capacity",0)),maxi(0,primary_population-assigned))
		plot["resident_count"]=desired
		assigned+=desired
		var previous_status:=String(plot.get("status","active"))
		var vacant_months:=int(plot.get("vacant_months",0))
		if desired<=0:
			vacant_months+=1
			plot["vacant_months"]=vacant_months
			if vacant_months>=6 and previous_status not in ["damaged","ruin"]:
				plot["status"]="vacant"
				plot["abandoned_day"]=day if int(plot.get("abandoned_day",-1))<0 else int(plot.abandoned_day)
				plot["reoccupation_state"]="permanently_abandoned" if vacant_months>=60 else "displaced"
		else:
			plot["vacant_months"]=0
			if previous_status=="vacant" and float(plot.get("condition",0.0))>=0.32:
				plot["status"]="active"
				plot["reoccupation_state"]="reoccupied"
				plot["abandoned_day"]=-1
		if String(plot.get("status",""))!=previous_status:
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"vacated" if String(plot.status)=="vacant" else "reoccupied","new_state":plot.status,"cause":"population redistribution across usable household ground"})
			_record_plot_building_event(plot,"vacated" if String(plot.status)=="vacant" else "reoccupied",day,{},false,"Population redistributed across usable household ground.")
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Ground %s" % ("Vacated" if String(plot.status)=="vacant" else "Reoccupied"),"plot_id":int(plot.id)})
	var builders:=GameState.effective_workers("Construction")
	var labor_efficiency:=float(GameState.simulation_metrics.get("labor_efficiency",0.72))
	var maintained_plots:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) in ["ruin","reclaimed","under_construction"]: continue
		maintained_plots+=1
	var maintenance_per_plot:=builders*labor_efficiency/maxf(1.0,float(maintained_plots))*0.0032
	var hardship:=clampf(1.0-float(GameState.simulation_metrics.get("health",GameState.population_health)),0.0,1.0)
	var rng:=RandomNumberGenerator.new()
	rng.seed=GameState.world_seed^day^0x27d4eb2d
	for plot in GameState.settlement_plots:
		var status:=String(plot.get("status","active"))
		if status in ["under_construction","ruin","reclaimed"]: continue
		var temporary_ground:=String(plot.get("land_use",""))=="temporary_encampment"
		var previous_condition:=float(plot.get("condition",1.0))
		var exposure:=float(plot.get("hazard_exposure",0.1))
		var decay:=0.00065+exposure*0.00055+hardship*0.0012
		if status=="vacant": decay+=0.0018
		var maintenance:=maintenance_per_plot if status in ["active","stressed","damaged"] else 0.0
		plot["condition"]=clampf(previous_condition-decay+maintenance,0.0,1.0)
		plot["maintenance_debt"]=clampf(float(plot.get("maintenance_debt",0.0))+decay-maintenance,0.0,1.0)
		if status=="vacant":
			plot["reclamation"]=clampf(float(plot.get("reclamation",0.0))+0.012+float(plot.get("vacant_months",0))*0.00012,0.0,1.0)
		elif status=="active": plot["reclamation"]=maxf(0.0,float(plot.get("reclamation",0.0))-0.03)
		if temporary_ground:
			# Tents and salvaged cover do not become masonry-style ruins. Once empty,
			# their paths and bare patches are gradually reclaimed; occupied cover can
			# fail and become stressed, but remains temporary fabric in the record.
			if status=="vacant" and float(plot.get("reclamation",0.0))>=0.72:
				plot["status"]="reclaimed"
				plot["condition"]=0.0
				plot["repair_state"]="ground_reclaimed"
				GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"temporary_ground_reclaimed","new_state":"reclaimed","cause":"the overflow camp emptied and vegetation returned across its temporary footprint"})
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":"Temporary Ground Was Reclaimed","plot_id":int(plot.id)})
			elif status in ["active","stressed"] and rng.randf()<exposure*0.0015:
				plot["condition"]=maxf(0.06,float(plot.condition)-rng.randf_range(0.06,0.22))
				plot["status"]="stressed"
				plot["repair_state"]="cover_failed"
				GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"temporary_cover_failed","new_state":"stressed","cause":"weather or fire damaged temporary family cover"})
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":"Temporary Cover Failed","plot_id":int(plot.id)})
			elif status=="active" and float(plot.condition)<0.34:
				plot["status"]="stressed"
				GameState.morphology_revision+=1
			elif status=="stressed" and float(plot.condition)>=0.46:
				plot["status"]="active"
				GameState.morphology_revision+=1
			if absf(float(plot.condition)-previous_condition)>0.018:
				GameState.morphology_revision+=1
			continue
		if status in ["active","stressed"] and rng.randf()<exposure*0.0015:
			var severity:=rng.randf_range(0.06,0.22)
			plot["condition"]=maxf(0.0,float(plot.condition)-severity)
			plot["status"]="damaged" if float(plot.condition)>=0.16 else "ruin"
			plot["pre_damage_use"]=String(plot.get("land_use",""))
			plot["damaged_day"]=day
			plot["repair_state"]="awaiting_assessment" if String(plot.status)=="damaged" else "unrepairable"
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"damage","new_state":plot.status,"cause":"localized fire, weather, or structural failure"})
			_record_plot_building_event(plot,"destroyed" if String(plot.status)=="ruin" else "damaged",day,{},false,"Localized fire, weather, or structural failure.")
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Ground Damaged","plot_id":int(plot.id)})
		elif status=="active" and float(plot.condition)<0.48:
			plot["status"]="stressed"
			GameState.morphology_revision+=1
		elif status=="stressed" and float(plot.condition)>=0.58:
			plot["status"]="active"
			GameState.morphology_revision+=1
		elif status=="damaged" and float(plot.condition)<0.14:
			plot["status"]="ruin"
			plot["repair_state"]="unrepairable"
			GameState.morphology_revision+=1
		if absf(float(plot.condition)-previous_condition)>0.018:
			GameState.morphology_revision+=1
	# A route's importance comes from its own frontage and every occupied branch
	# feeding into it. Propagate demand through the inherited route tree so a
	# heavily used approach can emerge organically instead of every segment being
	# assessed as an isolated household path.
	var route_direct_users:Dictionary={}
	var route_frontage_plots:Dictionary={}
	var route_parent:Dictionary={}
	var route_by_id:Dictionary={}
	for route in GameState.settlement_routes:
		if bool(route.get("active",true)): route_by_id[int(route.id)]=route
	for route_id in route_by_id:
		route_direct_users[route_id]=0
		route_frontage_plots[route_id]=0
	for plot in GameState.settlement_plots:
		var frontage_id:=int(plot.get("frontage_route_id",-1))
		if not route_by_id.has(frontage_id): continue
		route_frontage_plots[frontage_id]=int(route_frontage_plots.get(frontage_id,0))+1
		route_direct_users[frontage_id]=int(route_direct_users.get(frontage_id,0))+int(plot.get("resident_count",0))+int(plot.get("worker_count",0))
	for route_id in route_by_id:
		var route:Dictionary=route_by_id[route_id]
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		var parent_id:=-1
		if points.size()>=2:
			var terminal:=points[points.size()-1]
			var nearest_parent_distance:=0.0022
			for candidate_id in route_by_id:
				if int(candidate_id)==int(route_id): continue
				var candidate:Dictionary=route_by_id[candidate_id]
				var candidate_points:PackedVector2Array=candidate.get("points",PackedVector2Array())
				if candidate_points.is_empty(): continue
				var distance:=terminal.distance_to(candidate_points[0])
				if distance<nearest_parent_distance:
					nearest_parent_distance=distance
					parent_id=int(candidate_id)
		route_parent[route_id]=parent_id
	var route_total_users:Dictionary={}
	for route_id in route_by_id: route_total_users[route_id]=0
	for source_id in route_by_id:
		var carried_users:=int(route_direct_users.get(source_id,0))
		var current_id:=int(source_id)
		var visited:Dictionary={}
		for depth in 24:
			if current_id<0 or visited.has(current_id): break
			visited[current_id]=true
			route_total_users[current_id]=int(route_total_users.get(current_id,0))+carried_users
			current_id=int(route_parent.get(current_id,-1))
	# A route can be busy without being a settlement-scale trunk. Rank mature
	# non-field routes by inherited users so "main approach" remains a scarce,
	# legible hierarchy rather than eventually spreading to every old path.
	var main_candidates:Array[Dictionary]=[]
	for route_id in route_by_id:
		var candidate:Dictionary=route_by_id[route_id]
		if String(candidate.get("kind","desire_path")) in ["field_track","camp_path"]: continue
		var inherited_users:=int(route_total_users.get(route_id,0))
		if inherited_users<120 or float(candidate.get("condition",0.0))<0.70: continue
		if day-int(candidate.get("created_day",day))<720: continue
		main_candidates.append({"id":int(route_id),"score":float(inherited_users)+float(candidate.get("traffic",0.0))*48.0+float(candidate.get("condition",0.0))*18.0})
	main_candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score))
	var main_approach_limit:=clampi(1+floori(float(_primary_population())/1800.0),1,8)
	var main_approach_ids:Dictionary={}
	for candidate_index in mini(main_approach_limit,main_candidates.size()):
		main_approach_ids[int(main_candidates[candidate_index].id)]=true
	for route_id in route_by_id:
		var route:Dictionary=route_by_id[route_id]
		var frontage_users:=int(route_total_users.get(route_id,0))
		var direct_users:=int(route_direct_users.get(route_id,0))
		var frontage_plots:=int(route_frontage_plots.get(route_id,0))
		var frontage_occupied:=direct_users>0
		route["condition"]=clampf(float(route.get("condition",0.3))+(0.008 if frontage_occupied else -0.005),0.02,1.0)
		var observed_traffic:=clampf(float(frontage_users)/42.0+float(maxi(0,frontage_plots-1))*0.045,0.0,1.0)
		route["traffic"]=lerpf(float(route.get("traffic",0.0)),observed_traffic,0.16)
		var traffic:=float(route.traffic)
		var route_kind:=String(route.get("kind","desire_path"))
		var hierarchy:="field_track" if route_kind=="field_track" else ("camp_path" if route_kind=="camp_path" else "path")
		if route_kind=="field_track":
			if traffic>=0.34 and float(route.condition)>=0.42: hierarchy="farm_lane"
		elif route_kind!="camp_path":
			if traffic>=0.30 and float(route.condition)>=0.48: hierarchy="lane"
			if main_approach_ids.has(int(route_id)) and traffic>=0.72: hierarchy="main_approach"
		route["hierarchy"]=hierarchy
		var target_width:=0.72 if route_kind=="field_track" else (0.34 if route_kind=="camp_path" else 0.62)
		if hierarchy=="farm_lane": target_width=1.35+traffic*0.55
		elif hierarchy=="lane": target_width=1.25+traffic*1.15
		elif hierarchy=="main_approach": target_width=2.25+traffic*1.55
		var widening_capacity:=clampf(builders*labor_efficiency/18.0,0.04,0.46)
		route["width_m"]=move_toward(float(route.get("width_m",target_width)),target_width,0.035+widening_capacity*0.09)
	if day%90==0:
		GameState.morphology_revision+=1

func _synchronize_early_works(day:int,events:Array[Dictionary])->void:
	if "Lean-to Shelters" in GameState.settlement_completed:
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"] or String(plot.get("form","")) not in ["portable_shelter_cluster","light_shelter_cluster"]: continue
			plot["form"]="lean_to_household_cluster"
			plot["converted_day"]=day
			plot["roof_coverage"]=maxf(float(plot.get("roof_coverage",0.0)),0.22)
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"converted","new_state":"lean_to_household_cluster","cause":"Lean-to Shelters"})
			_record_plot_building_event(plot,"converted",day,{},false,"Portable shelter became a rooted lean-to household cluster.")
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Shelters Took Root","plot_id":int(plot.id)})
	var work_forms:Dictionary={"Storage Pits":{"use":"storage","from":"guarded_cache","to":"lined_storage_pits"},"Open Work Area":{"use":"workshop","from":"open_work_yard","to":"sheltered_work_area"}}
	for work_name in work_forms:
		if work_name not in GameState.settlement_completed: continue
		var definition:Dictionary=work_forms[work_name]
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use",""))!=String(definition.use) or String(plot.get("form",""))!=String(definition.from): continue
			plot["form"]=definition.to
			plot["converted_day"]=day
			plot["roof_coverage"]=maxf(float(plot.get("roof_coverage",0.0)),0.28)
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"converted","new_state":definition.to,"cause":work_name})
			_record_plot_building_event(plot,"converted",day,{},false,"%s changed this inherited ground." % work_name)
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"%s Changed the Ground" % work_name,"plot_id":int(plot.id)})

func _settlement_age_years(day:int)->float:
	var founded_day:=GameState.settlement_founded_day
	if founded_day<0: founded_day=day
	return maxf(0.0,float(day-founded_day)/365.0)

func _age_fabric_ceiling(age_years:float)->int:
	# These are opportunity thresholds from the morphology specification, not free
	# upgrades. `_supported_fabric_tier` applies the material, labour, knowledge and
	# institutional ceiling that decides whether an old plot can actually change.
	if age_years<0.25: return 0
	if age_years<1.0: return 1
	if age_years<3.0: return 2
	if age_years<10.0: return 3
	if age_years<25.0: return 4
	if age_years<40.0: return 5
	if age_years<80.0: return 6
	if age_years<125.0: return 7
	if age_years<175.0: return 8
	if age_years<300.0: return 9
	if age_years<700.0: return 10
	if age_years<1500.0: return 11
	return 12

func _supported_fabric_tier(day:int)->int:
	var age_ceiling:=_age_fabric_ceiling(_settlement_age_years(day))
	var builders:=int(GameState.population_allocations.get("Construction",0))
	var craftspeople:=int(GameState.population_allocations.get("Crafting",0))
	var logisticians:=int(GameState.population_allocations.get("Logistics",0))
	var administrators:=int(GameState.population_allocations.get("Administration",0))
	var support:=0
	if "Lean-to Shelters" in GameState.settlement_completed and builders>=4: support=1
	if GameState.settlement_completed.size()>=3 and craftspeople>=4: support=2
	if craftspeople>=8 and logisticians>=4: support=3
	if craftspeople>=14 and logisticians>=8 and _active_nuclei()>=2: support=4
	var logistics_metric:=float(GameState.simulation_metrics.get("logistics",0.0))
	var labor_efficiency:=float(GameState.simulation_metrics.get("labor_efficiency",0.0))
	var construction_effect:=DiscoverySystem.effect("construction_rate")
	var route_effect:=DiscoverySystem.effect("route_speed")
	var craft_effect:=DiscoverySystem.effect("craft_output")
	if craftspeople>=24 and logisticians>=12 and labor_efficiency>=0.48: support=5
	if craftspeople>=36 and logisticians>=20 and administrators>=4 and logistics_metric+route_effect>=0.24: support=6
	if craftspeople>=54 and logisticians>=30 and administrators>=8 and construction_effect+craft_effect>=0.035: support=7
	if craftspeople>=80 and logisticians>=48 and administrators>=16 and construction_effect+route_effect+craft_effect>=0.075: support=8
	if craftspeople>=120 and logisticians>=72 and administrators>=28 and construction_effect+route_effect+craft_effect>=0.13: support=9
	var standardization:=DiscoverySystem.effect("standardization")
	var state_capacity:=DiscoverySystem.effect("state_capacity")
	var tool_quality:=DiscoverySystem.effect("tool_quality")
	if craftspeople>=200 and logisticians>=120 and administrators>=60 and construction_effect+route_effect+craft_effect+standardization>=0.22: support=10
	if craftspeople>=350 and logisticians>=220 and administrators>=120 and construction_effect+route_effect+craft_effect+standardization+tool_quality>=0.34: support=11
	if craftspeople>=600 and logisticians>=400 and administrators>=250 and construction_effect+route_effect+craft_effect+standardization+tool_quality+state_capacity>=0.50: support=12
	return mini(age_ceiling,support)

func _fabric_form_for(use:String,tier:int,current_form:String)->String:
	if use in ["residential_compound","mixed_household"]:
		return [current_form,"durable_household_cluster","joined_kin_compound","courtyard_household_compound","subdivided_frontage_compound","dense_mixed_frontage","compact_courtyard_row","inherited_urban_block","subdivided_urban_block","layered_historic_block","serviced_urban_block","industrial_age_tenement_block","metropolitan_mixed_block"][clampi(tier,0,12)]
	if use=="workshop":
		return [current_form,"covered_work_yard","household_craft_yard","specialist_craft_cluster","route_side_workshop","workshop_frontage","craft_quarter_yard","specialist_production_court","production_precinct","converted_inner_workshop","standardized_manufactory","powered_production_block","advanced_production_campus"][clampi(tier,0,12)]
	if use=="storage":
		return [current_form,"protected_household_store","communal_store","granary_compound","loading_yard","guarded_warehouse","warehouse_frontage","warehouse_row","bulk_distribution_court","historic_depot_complex","regional_freight_depot","industrial_warehouse_block","metropolitan_logistics_hub"][clampi(tier,0,12)]
	if use in ["communal","civic","sacred","market"]:
		return [current_form,"maintained_gathering_ground","customary_precinct","durable_assembly_compound","periodic_market_court","civic_frontage","institutional_court","ward_precinct","regional_civic_precinct","layered_civic_quarter","regional_institutional_campus","industrial_civic_complex","metropolitan_public_precinct"][clampi(tier,0,12)]
	if use=="field":
		return [current_form,"worked_clearance","household_garden_strip","inherited_smallholding","bounded_field_mosaic","consolidated_field_strips","market_garden_mosaic","managed_hinterland_field","regional_supply_field","historic_agricultural_parcel","surveyed_agricultural_block","mechanized_field_system","intensive_regional_foodscape"][clampi(tier,0,12)]
	return current_form

func _fabric_upgrade_cost(plot:Dictionary,target_tier:int)->Dictionary:
	var family:=_fabric_material_family_for(plot,target_tier)
	var scale:=0.22+float(target_tier)*0.075
	if String(plot.get("land_use",""))=="field":
		return {"Timber":scale*0.22,"Fiber Plants":scale*0.18}
	if family=="stone": return {"Stone":scale*2.4,"Timber":scale*0.48}
	if family=="earth": return {"Clay":scale*2.0,"Timber":scale*0.42,"Fiber Plants":scale*0.24}
	return {"Timber":scale*1.55,"Fiber Plants":scale*0.82}

func _fabric_material_family_for(plot:Dictionary,target_tier:int)->String:
	# Material transitions are discoveries plus supply, never an era palette swap.
	# Seeded parcel preference leaves mixed roofscapes instead of replacing an
	# entire town with one fashionable construction system.
	var current:=String(plot.get("material_family","organic"))
	var parcel_variant:=absi(int(plot.get("seed",1)))%10
	var stone_program:=ConsequenceEngine.policy_effect("stone_priority")>0.01
	var stone_tier:=1 if stone_program else 7
	var stone_variants:=[0,1,3,4,6,8] if stone_program else [0,3,6,8]
	if target_tier>=stone_tier and "stone_selection" in GameState.known_discoveries and float(GameState.resource_stockpiles.get("Stone",0.0))>=2.0 and parcel_variant in stone_variants:
		return "stone"
	if target_tier>=4 and "clay_shaping" in GameState.known_discoveries and float(GameState.resource_stockpiles.get("Clay",0.0))>=1.5 and parcel_variant in [1,2,4,5,7]:
		return "earth"
	return current

func _can_pay_fabric_cost(cost:Dictionary)->bool:
	for resource_name in cost:
		if float(GameState.resource_stockpiles.get(resource_name,0.0))<float(cost[resource_name]): return false
	return true

func _evolve_inherited_fabric(day:int,events:Array[Dictionary])->void:
	# A quarterly bounded conversion keeps centuries affordable and ensures that an
	# era remains a heterogeneous accretion of old and new fabric. Population never
	# repaints the whole settlement in one frame.
	if day%90!=0 or int(GameState.population_allocations.get("Construction",0))<4: return
	var target_tier:=_supported_fabric_tier(day)
	if target_tier<=0: return
	var candidates:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) not in ["active","stressed"]: continue
		if String(plot.get("land_use","")) in ["temporary_encampment","water","waste","pasture","vacant","ruin"]: continue
		var current_tier:=int(plot.get("fabric_generation",0))
		if current_tier>=target_tier: continue
		var next_tier:=current_tier+1
		var cost:=_fabric_upgrade_cost(plot,next_tier)
		if not _can_pay_fabric_cost(cost): continue
		var route_access:=float(plot.get("service_access",0.0))
		var occupancy:=float(plot.get("resident_count",0)+plot.get("worker_count",0))
		var age:=maxf(0.0,float(day-int(plot.get("created_day",day)))/365.0)
		var score:=route_access*0.72+occupancy*0.028+age*0.018+float(plot.get("prosperity",0.0))*0.42
		candidates.append({"plot":plot,"next_tier":next_tier,"cost":cost,"score":score})
	if candidates.is_empty(): return
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score))
	var builders:=int(GameState.population_allocations.get("Construction",0))
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.0)),0.0,1.0)
	var upgrade_slots:=clampi(1+floori(float(builders)/80.0)+floori(logistics*2.0),1,12)
	for candidate_index in mini(upgrade_slots,candidates.size()):
		var chosen:Dictionary=candidates[candidate_index]
		if not _can_pay_fabric_cost(chosen.cost): continue
		_apply_fabric_upgrade(chosen,day,events)

func _apply_fabric_upgrade(chosen:Dictionary,day:int,events:Array[Dictionary])->void:
	var chosen_plot:Dictionary=chosen.plot
	var next_tier:int=chosen.next_tier
	var cost:Dictionary=chosen.cost
	for resource_name in cost:
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(cost[resource_name]))
	var previous_form:=String(chosen_plot.get("form","inherited_plot"))
	var use:=String(chosen_plot.get("land_use",""))
	var target_family:=_fabric_material_family_for(chosen_plot,next_tier)
	chosen_plot["form"]=_fabric_form_for(use,next_tier,previous_form)
	if target_family!=String(chosen_plot.get("material_family","organic")):
		chosen_plot["material_family"]=target_family
		chosen_plot["material_mix"]={"Stone":0.76,"Timber":0.16,"Clay":0.04} if target_family=="stone" else {"Clay":0.68,"Timber":0.19,"Fiber Plants":0.06}
		chosen_plot["roof_plan"]=_roof_plan_for(int(chosen_plot.get("seed",1)),target_family,String(chosen_plot.form))
	chosen_plot["fabric_generation"]=next_tier
	chosen_plot["morphology_era"]=["founding","foothold","hamlet","village","local_centre","town","mature_town","urban_system","city_consolidation","historic_landscape","regional_system","industrial_age","metropolitan_age"][next_tier]
	chosen_plot["converted_day"]=day
	chosen_plot["last_update_day"]=day
	chosen_plot["roof_coverage"]=minf(0.72,float(chosen_plot.get("roof_coverage",0.0))+(0.018 if use=="field" else 0.032))
	if use in ["residential_compound","mixed_household"]:
		var durable:=String(chosen_plot.get("material_family","organic")) in ["earth","stone"]
		var new_storeys:=1
		if durable and next_tier>=5: new_storeys=2
		if durable and next_tier>=8 and DiscoverySystem.effect("construction_rate")>=0.025: new_storeys=3
		chosen_plot["storeys"]=maxi(int(chosen_plot.get("storeys",1)),new_storeys)
		var capacity_gain:=2+next_tier+maxi(0,int(chosen_plot.storeys)-1)*4
		chosen_plot["resident_capacity"]=int(chosen_plot.get("resident_capacity",0))+capacity_gain
	chosen_plot["condition"]=minf(0.96,float(chosen_plot.get("condition",0.7))+0.08)
	var provenance:Dictionary=chosen_plot.get("supply_provenance",{}).duplicate(true)
	for resource_name in cost: provenance[resource_name]=float(provenance.get(resource_name,0.0))+float(cost[resource_name])
	chosen_plot["supply_provenance"]=provenance
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(chosen_plot.id),"event":"fabric_evolved","old_form":previous_form,"new_state":String(chosen_plot.form),"cause":"sustained use, inherited access, skilled labour, and delivered replacement material","fabric_generation":next_tier})
	_record_plot_building_event(chosen_plot,"rebuilt",day,cost.duplicate(true),true,"%s became %s as inherited fabric was renewed." % [previous_form.replace("_"," "),String(chosen_plot.form).replace("_"," ")])
	# Route surfacing records cumulative public work separately from hierarchy. A
	# lane may remain geometrically ancient while its surface changes repeatedly.
	var frontage_id:=int(chosen_plot.get("frontage_route_id",-1))
	for route in GameState.settlement_routes:
		if int(route.get("id",-2))!=frontage_id: continue
		var surface_tier:=mini(next_tier,5)
		route["surface_tier"]=maxi(int(route.get("surface_tier",0)),surface_tier)
		route["surface"]=["trodden","cleared_earth","compacted_earth","drained_earth","gravel_or_rubble","maintained_hard_surface"][surface_tier]
		route["condition"]=minf(1.0,float(route.get("condition",0.3))+0.06)
		break
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"Inherited Ground Changed With Use","plot_id":int(chosen_plot.id),"form":String(chosen_plot.form)})

func _functional_plot_count(land_use:String)->int:
	var count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))==land_use and String(plot.get("status","")) not in ["ruin","reclaimed"]: count+=1
	return count

func _available_functional_recipe(land_use:String)->Dictionary:
	var stocks:=GameState.resource_stockpiles
	var recipes:Array[Dictionary]=[]
	if land_use=="workshop":
		recipes=[
			{"family":"organic","form":"timber_work_shelter","cost":{"Timber":2.6,"Fiber Plants":1.0},"mix":{"Timber":0.58,"Fiber Plants":0.28,"Clay":0.04}},
			{"family":"earth","form":"earthen_work_shelter","requires":"clay_shaping","cost":{"Clay":4.0,"Timber":0.8},"mix":{"Clay":0.66,"Timber":0.18,"Fiber Plants":0.06}},
			{"family":"stone","form":"stone_work_shelter","requires":"stone_selection","cost":{"Stone":5.2,"Timber":1.2},"mix":{"Stone":0.70,"Timber":0.17,"Fiber Plants":0.03}}
		]
	elif land_use=="storage":
		recipes=[
			{"family":"organic","form":"raised_timber_store","cost":{"Timber":2.2,"Fiber Plants":1.1},"mix":{"Timber":0.50,"Fiber Plants":0.32,"Clay":0.06}},
			{"family":"earth","form":"sealed_earthen_store","requires":"clay_shaping","cost":{"Clay":4.4,"Fiber Plants":0.8},"mix":{"Clay":0.72,"Fiber Plants":0.14,"Timber":0.05}},
			{"family":"stone","form":"dry_stone_store","requires":"stone_selection","cost":{"Stone":5.8,"Timber":0.8},"mix":{"Stone":0.75,"Timber":0.12,"Fiber Plants":0.03}}
		]
	elif land_use=="market":
		recipes=[
			{"family":"organic","form":"covered_exchange_court","cost":{"Timber":3.4,"Fiber Plants":1.5},"mix":{"Timber":0.48,"Fiber Plants":0.31,"Clay":0.05}},
			{"family":"earth","form":"earthen_market_court","requires":"clay_shaping","cost":{"Clay":5.2,"Timber":1.4},"mix":{"Clay":0.60,"Timber":0.24,"Fiber Plants":0.06}},
			{"family":"stone","form":"stone_exchange_court","requires":"stone_selection","cost":{"Stone":6.8,"Timber":1.5},"mix":{"Stone":0.66,"Timber":0.23,"Fiber Plants":0.03}}
		]
	elif land_use=="hospitality":
		recipes=[
			{"family":"organic","form":"travellers_court","cost":{"Timber":3.0,"Fiber Plants":1.7},"mix":{"Timber":0.44,"Fiber Plants":0.36,"Clay":0.05}},
			{"family":"earth","form":"route_side_guest_compound","requires":"clay_shaping","cost":{"Clay":4.8,"Timber":1.5},"mix":{"Clay":0.58,"Timber":0.25,"Fiber Plants":0.08}}
		]
	elif land_use=="civic":
		recipes=[
			{"family":"organic","form":"assembly_hall_compound","cost":{"Timber":5.2,"Fiber Plants":1.8},"mix":{"Timber":0.62,"Fiber Plants":0.22,"Clay":0.04}},
			{"family":"earth","form":"earthen_civic_court","requires":"clay_shaping","cost":{"Clay":7.2,"Timber":2.2},"mix":{"Clay":0.65,"Timber":0.21,"Fiber Plants":0.04}},
			{"family":"stone","form":"durable_civic_precinct","requires":"stone_selection","cost":{"Stone":9.0,"Timber":2.4},"mix":{"Stone":0.70,"Timber":0.18,"Fiber Plants":0.02}}
		]
	elif land_use=="dirty_industry":
		recipes=[
			{"family":"earth","form":"fuel_and_processing_yard","requires":"clay_shaping","cost":{"Clay":6.5,"Timber":2.4,"Stone":1.8},"mix":{"Clay":0.50,"Stone":0.22,"Timber":0.18}},
			{"family":"stone","form":"heavy_processing_yard","requires":"stone_selection","cost":{"Stone":8.5,"Timber":2.8},"mix":{"Stone":0.62,"Timber":0.22,"Clay":0.08}}
		]
	for recipe in recipes:
		var discovery:=String(recipe.get("requires",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries: continue
		var available:=true
		for resource_name in recipe.cost:
			if float(stocks.get(resource_name,0.0))<float(recipe.cost[resource_name]):
				available=false
				break
		if available: return recipe
	return {}

func _attempt_functional_growth(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if not _can_add_plots(): return
	if _has_active_construction() or int(GameState.population_allocations.get("Construction",0))<4: return
	var candidates:Array[Dictionary]=[]
	if "Open Work Area" in GameState.settlement_completed:
		var crafting:=int(GameState.population_allocations.get("Crafting",0))
		var desired_workshops:=clampi(floori(float(crafting)/6.0),1,14)
		var existing_workshops:=_functional_plot_count("workshop")
		if existing_workshops<desired_workshops:
			candidates.append({"use":"workshop","pressure":float(desired_workshops-existing_workshops)+float(crafting)/20.0})
	if "Storage Pits" in GameState.settlement_completed:
		var logistics:=int(GameState.population_allocations.get("Logistics",0))
		var desired_storage:=clampi(floori(float(logistics)/5.0),1,14)
		var stored_bulk:=float(GameState.simulation_metrics.get("material_stored_bulk",0.0))
		var capacity:=float(GameState.simulation_metrics.get("material_storage_capacity",1.0))
		if stored_bulk>capacity*0.72: desired_storage+=1
		var existing_storage:=_functional_plot_count("storage")
		if existing_storage<desired_storage:
			candidates.append({"use":"storage","pressure":float(desired_storage-existing_storage)+stored_bulk/maxf(1.0,capacity)})
	var settlement_age:=_settlement_age_years(day)
	var logistics_workers:=int(GameState.population_allocations.get("Logistics",0))
	var administration_workers:=int(GameState.population_allocations.get("Administration",0))
	var extraction_workers:=int(GameState.population_allocations.get("Extraction",0))
	if settlement_age>=10.0 and logistics_workers>=12:
		var desired_markets:=clampi(1+floori(float(logistics_workers)/90.0),1,10)
		var existing_markets:=_functional_plot_count("market")
		if existing_markets<desired_markets: candidates.append({"use":"market","pressure":float(desired_markets-existing_markets)+float(logistics_workers)/120.0})
	if settlement_age>=15.0 and logistics_workers>=20:
		var desired_hospitality:=clampi(1+floori(float(logistics_workers)/140.0),1,8)
		var existing_hospitality:=_functional_plot_count("hospitality")
		if existing_hospitality<desired_hospitality: candidates.append({"use":"hospitality","pressure":float(desired_hospitality-existing_hospitality)+float(logistics_workers)/180.0})
	if settlement_age>=25.0 and administration_workers>=8:
		var desired_civic:=clampi(1+floori(float(administration_workers)/110.0),1,8)
		var existing_civic:=_functional_plot_count("civic")
		if existing_civic<desired_civic: candidates.append({"use":"civic","pressure":float(desired_civic-existing_civic)+float(administration_workers)/160.0})
	if settlement_age>=40.0 and extraction_workers>=18 and "stone_selection" in GameState.known_discoveries:
		var desired_industry:=clampi(1+floori(float(extraction_workers)/70.0),1,12)
		var existing_industry:=_functional_plot_count("dirty_industry")
		if existing_industry<desired_industry: candidates.append({"use":"dirty_industry","pressure":float(desired_industry-existing_industry)+float(extraction_workers)/100.0})
	if candidates.is_empty(): return
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.pressure)>float(b.pressure))
	for candidate in candidates:
		var land_use:=String(candidate.use)
		var recipe:=_available_functional_recipe(land_use)
		if recipe.is_empty(): continue
		var plot:=_create_functional_growth_plot(day,land_use,recipe,context)
		if plot.is_empty(): continue
		for resource_name in recipe.cost:
			GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(recipe.cost[resource_name]))
		_create_growth_route(plot,day)
		GameState.settlement_plots.append(plot)
		GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"construction_started","new_state":"under_construction","cause":String(plot.growth_cause)})
		_record_plot_building_event(plot,"started",day,(recipe.cost as Dictionary).duplicate(true),true,String(plot.growth_cause))
		GameState.morphology_revision+=1
		events.append({"type":"morphology","title":"%s Claimed" % ("New Working Ground" if land_use=="workshop" else "New Storage Ground"),"plot_id":int(plot.id)})
		return

func _growth_site_score(candidate:Vector2,radius:float,land_use:String,context:Dictionary)->float:
	# Reject occupied ground first. The remaining terms make settlement growth
	# follow inherited lanes, useful nuclei, water and buildable terrain instead of
	# adding rings around an abstract population centre.
	for existing in GameState.settlement_plots:
		var existing_radius:=sqrt(_polygon_area_km2(existing.get("polygon",PackedVector2Array()))/PI)
		if candidate.distance_to(Vector2(existing.get("centroid",Vector2.ZERO)))<(radius+existing_radius)*1.18:
			return -10000.0
	var nearest_route:=INF
	for route in GameState.settlement_routes:
		if not bool(route.get("active",true)): continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		for point_index in points.size()-1:
			nearest_route=minf(nearest_route,Geometry2D.get_closest_point_to_segment(candidate,points[point_index],points[point_index+1]).distance_to(candidate))
	var route_access:=exp(-nearest_route/0.018) if nearest_route<INF else 0.0
	var nucleus_pull:=0.0
	var nearest_nucleus_distance:=INF
	for nucleus in GameState.settlement_nuclei:
		if not bool(nucleus.get("active",true)): continue
		var distance:=candidate.distance_to(Vector2(nucleus.get("position",Vector2.ZERO)))
		nearest_nucleus_distance=minf(nearest_nucleus_distance,distance)
		nucleus_pull=maxf(nucleus_pull,float(nucleus.get("pull",1.0))*exp(-distance/0.14))
	var core_distance:=candidate.length()
	var compactness:=exp(-nearest_nucleus_distance/0.22) if nearest_nucleus_distance<INF else exp(-core_distance/0.22)
	var edge_preference:=exp(-absf(nearest_nucleus_distance-0.095)/0.065) if nearest_nucleus_distance<INF else exp(-absf(core_distance-0.095)/0.065)
	var score:=route_access*2.8+nucleus_pull*0.72
	if land_use=="storage": score+=compactness*1.25
	elif land_use in ["workshop","dirty_industry"]: score+=edge_preference*1.12-route_access*0.10
	else: score+=compactness*0.86
	var origin:Vector3=context.get("settlement_origin",GameState.settlement_founded_at)
	var world_x:=origin.x+candidate.x
	var world_z:=origin.z+candidate.y
	var buildable_callable:Callable=context.get("buildable_land_at",Callable())
	if buildable_callable.is_valid() and not bool(buildable_callable.call(world_x,world_z)): return -10000.0
	var height_callable:Callable=context.get("terrain_height_at",Callable())
	if height_callable.is_valid():
		var sample:=0.012
		var east_west:=absf(float(height_callable.call(world_x+sample,world_z))-float(height_callable.call(world_x-sample,world_z)))
		var north_south:=absf(float(height_callable.call(world_x,world_z+sample))-float(height_callable.call(world_x,world_z-sample)))
		var slope:=maxf(east_west,north_south)/(sample*2.0)
		if slope>0.34: return -10000.0
		score-=slope*3.2
	var river_callable:Callable=context.get("river_distance_at",Callable())
	if river_callable.is_valid():
		var river_distance:=float(river_callable.call(world_x,world_z))
		if river_distance<0.025: return -10000.0
		score+=exp(-absf(river_distance-0.16)/0.20)*0.24
	return score

func _nearest_nucleus_id(position:Vector2)->int:
	var nearest_id:=1
	var nearest_distance:=INF
	for nucleus in GameState.settlement_nuclei:
		if not bool(nucleus.get("active",true)): continue
		var distance:=position.distance_to(Vector2(nucleus.get("position",Vector2.ZERO)))
		if distance<nearest_distance:
			nearest_distance=distance
			nearest_id=int(nucleus.get("id",1))
	return nearest_id

func _create_functional_growth_plot(day:int,land_use:String,recipe:Dictionary,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_%s:%d" % [GameState.world_seed,land_use,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var radius:=rng.randf_range(0.009,0.014) if land_use in ["workshop","market","hospitality"] else (rng.randf_range(0.012,0.019) if land_use in ["civic","dirty_industry"] else rng.randf_range(0.008,0.012))
	var anchors:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("status","")) in ["ruin","reclaimed"]: continue
		var existing_use:=String(existing.get("land_use",""))
		if existing_use==land_use or existing_use in ["communal","mixed_household"]: anchors.append(existing)
	if anchors.is_empty(): return {}
	var center:=Vector2.ZERO
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	for attempt in 80:
		var anchor:Dictionary=anchors[rng.randi_range(0,anchors.size()-1)]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_radius:=sqrt(_polygon_area_km2(anchor.get("polygon",PackedVector2Array()))/PI)
		var outward:=anchor_center.normalized() if anchor_center.length()>0.005 else Vector2.from_angle(rng.randf()*TAU)
		var direction:=outward.rotated(rng.randf_range(-1.20,1.20))
		center=anchor_center+direction*(anchor_radius+radius+rng.randf_range(0.003,0.009))
		var score:=_growth_site_score(center,radius,land_use,context)
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	center=best_center
	GameState.next_settlement_plot_id+=1
	var polygon:=_irregular_polygon(center,radius,plot_seed)
	var worker_role:=String({"workshop":"Crafting","storage":"Logistics","market":"Logistics","hospitality":"Logistics","civic":"Administration","dirty_industry":"Extraction"}.get(land_use,"Logistics"))
	var workers:=int(GameState.population_allocations.get(worker_role,0))
	var worker_capacity:=rng.randi_range(5,8) if land_use not in ["civic","dirty_industry"] else rng.randi_range(10,18)
	var secondary_use:=String({"workshop":"craft","storage":"provisions","market":"exchange","hospitality":"lodging","civic":"administration","dirty_industry":"bulk_processing"}.get(land_use,"service"))
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":_nearest_nucleus_id(center),"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":land_use,"secondary_use":secondary_use,"form":recipe.form,"roof_plan":_roof_plan_for(plot_seed,String(recipe.family),String(recipe.form)),"material_family":recipe.family,"material_mix":recipe.mix,"construction_recipe":"specialized_%s_expansion" % land_use,"supply_provenance":recipe.cost.duplicate(true),"replacement_debt":{},"roof_coverage":0.42 if land_use=="workshop" else (0.36 if land_use in ["market","civic"] else 0.54),"storeys":1,
		"resident_capacity":rng.randi_range(8,16) if land_use=="hospitality" else 0,"resident_count":0,"worker_capacity":worker_capacity,"worker_count":mini(workers,worker_capacity),"storage_capacity":rng.randf_range(10.0,18.0) if land_use=="storage" else (rng.randf_range(4.0,9.0) if land_use in ["market","dirty_industry"] else 1.4),"condition":0.58,"maintenance_debt":0.0,"service_access":0.38,"hazard_exposure":rng.randf_range(0.18,0.34) if land_use=="dirty_industry" else rng.randf_range(0.10,0.24),"prosperity":0.34,
		"status":"under_construction","construction_progress":0.0,"growth_cause":"assigned %s labor, construction labor, and delivered materials" % ("craft" if land_use=="workshop" else "logistics"),"pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied",
		"displaced_households":0,"returning_households":0,"claim_pressure":0.0,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _resident_capacity_for_growth()->int:
	var capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) in ["active","stressed","under_construction"]:
			capacity+=int(plot.get("resident_capacity",0))
	return capacity

func _available_household_recipe()->Dictionary:
	var stocks:=GameState.resource_stockpiles
	# A stone-housing directive changes which feasible recipe builders choose; it
	# cannot bypass the material discovery or the delivered stock requirement.
	if ConsequenceEngine.policy_effect("stone_priority")>0.01 and "stone_selection" in GameState.known_discoveries and float(stocks.get("Stone",0.0))>=4.2 and float(stocks.get("Timber",0.0))>=0.8:
		return {"family":"stone","form":"dry_stone_household","cost":{"Stone":4.2,"Timber":0.8},"mix":{"Stone":0.72,"Timber":0.12,"Fiber Plants":0.06}}
	if float(stocks.get("Timber",0.0))>=1.8 and float(stocks.get("Fiber Plants",0.0))>=1.2:
		return {"family":"organic","form":"timber_and_fibre_household","cost":{"Timber":1.8,"Fiber Plants":1.2},"mix":{"Timber":0.52,"Fiber Plants":0.34,"Clay":0.05}}
	if "clay_shaping" in GameState.known_discoveries and float(stocks.get("Clay",0.0))>=3.2 and float(stocks.get("Fiber Plants",0.0))>=0.6:
		return {"family":"earth","form":"earthen_household","cost":{"Clay":3.2,"Fiber Plants":0.6},"mix":{"Clay":0.68,"Fiber Plants":0.16,"Timber":0.08}}
	if "stone_selection" in GameState.known_discoveries and float(stocks.get("Stone",0.0))>=4.2 and float(stocks.get("Timber",0.0))>=0.8:
		return {"family":"stone","form":"dry_stone_household","cost":{"Stone":4.2,"Timber":0.8},"mix":{"Stone":0.72,"Timber":0.12,"Fiber Plants":0.06}}
	return {}

func _attempt_household_growth(day:int,events:Array[Dictionary],context:Dictionary={},action_index:=0)->bool:
	if not _can_add_plots(): return false
	var capacity:=_resident_capacity_for_growth()
	if _primary_population()<=roundi(float(capacity)*0.88): return false
	if int(GameState.population_allocations.get("Construction",0))<4: return false
	var recipe:=_available_household_recipe()
	if recipe.is_empty(): return false
	# Some pressure becomes roofed infill inside a viable inherited compound;
	# other months still create edge plots. This keeps dense cores and irregular
	# expansion in tension instead of choosing one morphology forever.
	var monthly_phase:=(floori(float(day)/30.0)+action_index)%4
	if monthly_phase!=3 and _attempt_household_infill(day,recipe,events,action_index): return true
	var plot:=_create_household_growth_plot(day,recipe,context)
	if plot.is_empty(): return false
	for resource_name in recipe.cost:
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(recipe.cost[resource_name]))
	_create_growth_route(plot,day)
	GameState.settlement_plots.append(plot)
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"construction_started","new_state":"under_construction","cause":"household crowding, available labor, and delivered materials"})
	_record_plot_building_event(plot,"started",day,(recipe.cost as Dictionary).duplicate(true),true,"Household crowding, available labor, and delivered materials.")
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"New Household Ground Claimed","plot_id":int(plot.id)})
	return true

func _attempt_household_infill(day:int,recipe:Dictionary,events:Array[Dictionary],action_index:=0)->bool:
	var route_by_id:Dictionary={}
	for route in GameState.settlement_routes:
		if bool(route.get("active",true)): route_by_id[int(route.get("id",-1))]=route
	var best_plot:Dictionary={}
	var best_score:=-INF
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		if String(plot.get("status","")) not in ["active","stressed"]: continue
		var coverage:=float(plot.get("roof_coverage",0.0))
		var infill_units:=int(plot.get("infill_units",0))
		if coverage>=0.62 or infill_units>=3: continue
		if float(plot.get("area_ha",0.0))<0.012: continue
		var route:Dictionary=route_by_id.get(int(plot.get("frontage_route_id",-1)),{})
		var score:=float(plot.get("service_access",0.0))*1.15+float(route.get("traffic",0.0))*0.78+float(plot.get("area_ha",0.0))*4.0-float(plot.get("hazard_exposure",0.0))*0.62-float(infill_units)*0.28
		if score>best_score:
			best_score=score
			best_plot=plot
	if best_plot.is_empty(): return false
	var cost_scale:=0.58+float(int(best_plot.get("infill_units",0)))*0.12
	for resource_name in recipe.cost:
		var required:=float(recipe.cost[resource_name])*cost_scale
		if float(GameState.resource_stockpiles.get(resource_name,0.0))<required: return false
	for resource_name in recipe.cost:
		var required:=float(recipe.cost[resource_name])*cost_scale
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-required)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:infill:%d:%d:%d" % [GameState.world_seed,int(best_plot.id),day,action_index])
	var capacity_gain:=rng.randi_range(3,6)
	best_plot["infill_units"]=int(best_plot.get("infill_units",0))+1
	best_plot["resident_capacity"]=int(best_plot.get("resident_capacity",0))+capacity_gain
	best_plot["roof_coverage"]=minf(0.64,float(best_plot.get("roof_coverage",0.0))+rng.randf_range(0.065,0.105))
	best_plot["secondary_use"]="shared_yard" if String(best_plot.get("secondary_use",""))=="" else String(best_plot.secondary_use)
	best_plot["condition"]=maxf(0.32,float(best_plot.get("condition",0.7))-0.018)
	best_plot["hazard_exposure"]=clampf(float(best_plot.get("hazard_exposure",0.1))+0.012,0.0,1.0)
	best_plot["last_update_day"]=day
	var provenance:Dictionary=best_plot.get("supply_provenance",{}).duplicate(true)
	for resource_name in recipe.cost: provenance[resource_name]=float(provenance.get(resource_name,0.0))+float(recipe.cost[resource_name])*cost_scale
	best_plot["supply_provenance"]=provenance
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(best_plot.id),"event":"compound_infilled","new_state":"active","cause":"household pressure, route access, construction labor, and delivered materials roofed part of an inherited yard","capacity_gain":capacity_gain})
	var infill_materials:Dictionary={}
	for resource_name in recipe.cost: infill_materials[String(resource_name)]=float(recipe.cost[resource_name])*cost_scale
	_record_plot_building_event(best_plot,"infilled",day,infill_materials,true,"Roofed part of an inherited yard; gained capacity for %d people." % capacity_gain)
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"An Inherited Compound Was Infilled","plot_id":int(best_plot.id),"capacity_gain":capacity_gain})
	return true

func _create_growth_route(plot:Dictionary,day:int,route_kind:String="desire_path")->void:
	var plot_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var nearest:=Vector2.ZERO
	var nearest_distance:=INF
	for existing in GameState.settlement_plots:
		var candidate:=Vector2(existing.get("centroid",Vector2.ZERO))
		var distance:=plot_center.distance_to(candidate)
		if distance<nearest_distance:
			nearest=candidate
			nearest_distance=distance
	var route_id:=1
	for route in GameState.settlement_routes: route_id=maxi(route_id,int(route.get("id",0))+1)
	var direction:=nearest-plot_center
	var side:=Vector2(-direction.y,direction.x).normalized()
	var bend_strength:=minf(0.004,nearest_distance*0.16)
	var bend_a:=plot_center.lerp(nearest,0.36)+side*sin(float(int(plot.id)*29+GameState.world_seed))*bend_strength
	var bend_b:=plot_center.lerp(nearest,0.72)-side*sin(float(int(plot.id)*17+GameState.world_seed)*0.67)*bend_strength*0.62
	GameState.settlement_routes.append({"id":route_id,"kind":route_kind,"points":PackedVector2Array([plot_center,bend_a,bend_b,nearest]),"condition":0.10 if route_kind=="camp_path" else (0.16 if route_kind=="field_track" else 0.22),"width_m":0.34 if route_kind=="camp_path" else (0.72 if route_kind=="field_track" else 0.58),"created_day":day,"active":true})
	plot["frontage_route_id"]=route_id

func _create_household_growth_plot(day:int,recipe:Dictionary,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_growth:%d" % [GameState.world_seed,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var radius:=rng.randf_range(0.007,0.010)
	var center:=Vector2.ZERO
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	var anchors:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("land_use","")) in ["residential_compound","mixed_household","communal","workshop"] and String(existing.get("status","")) not in ["ruin","reclaimed"]:
			anchors.append(existing)
	if anchors.is_empty(): return {}
	var active_nuclei:Array[Dictionary]=[]
	for nucleus in GameState.settlement_nuclei:
		if bool(nucleus.get("active",true)): active_nuclei.append(nucleus)
	var target_nucleus:Dictionary=active_nuclei[absi(plot_seed)%active_nuclei.size()] if not active_nuclei.is_empty() else {"id":1,"position":Vector2.ZERO}
	var target_nucleus_position:=Vector2(target_nucleus.get("position",Vector2.ZERO))
	anchors.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return Vector2(a.get("centroid",Vector2.ZERO)).distance_to(target_nucleus_position)<Vector2(b.get("centroid",Vector2.ZERO)).distance_to(target_nucleus_position))
	var cluster_growth:=anchors.size()>=34 and plot_id%10 in [0,1,2]
	var cluster_phase:=floori(float(plot_id)/10.0)
	var cluster_angle:=fmod(float(hash("%d:outer_cluster:%d" % [GameState.world_seed,cluster_phase]))*0.000001,TAU)
	var cluster_target:=target_nucleus_position+Vector2.from_angle(cluster_angle)*((0.090+float(cluster_phase%4)*0.014) if cluster_growth else 0.0)
	for attempt in 72:
		var anchor_index:=mini(anchors.size()-1,floori(pow(rng.randf(),2.15)*float(anchors.size())))
		if cluster_growth:
			var outer_start:=clampi(floori(float(anchors.size())*0.62),0,anchors.size()-1)
			anchor_index=rng.randi_range(outer_start,anchors.size()-1)
		var anchor:Dictionary=anchors[anchor_index]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_polygon:PackedVector2Array=anchor.get("polygon",PackedVector2Array())
		var anchor_radius:=sqrt(_polygon_area_km2(anchor_polygon)/PI)
		var nucleus_outward:=anchor_center-target_nucleus_position
		var outward:=nucleus_outward.normalized() if nucleus_outward.length()>0.004 else Vector2.from_angle(rng.randf()*TAU)
		var angle:=rng.randf()*TAU
		if rng.randf()<0.28:
			angle=outward.angle()+rng.randf_range(-0.92,0.92)
		center=anchor_center+Vector2.from_angle(angle)*(anchor_radius+radius+rng.randf_range(0.0022,0.0065))
		var score:=_growth_site_score(center,radius,"residential_compound",context)
		# Most households infill, but a stable seeded minority follows the outer
		# frontage so a settlement develops irregular arms rather than a disk.
		if (plot_id+GameState.world_seed)%5==0: score+=exp(-absf(center.distance_to(target_nucleus_position)-0.11)/0.075)*0.82
		if cluster_growth: score+=exp(-center.distance_to(cluster_target)/0.075)*1.48
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	center=best_center
	GameState.next_settlement_plot_id+=1
	var polygon:=_irregular_polygon(center,radius,plot_seed)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":_nearest_nucleus_id(center),"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":"residential_compound","secondary_use":"","form":recipe.form,"roof_plan":_roof_plan_for(plot_seed,String(recipe.family),String(recipe.form)),"material_family":recipe.family,"material_mix":recipe.mix,"construction_recipe":"household_expansion","supply_provenance":recipe.cost.duplicate(true),"replacement_debt":{},"roof_coverage":0.30,"storeys":1,
		"resident_capacity":rng.randi_range(7,10),"resident_count":0,"worker_capacity":1,"worker_count":0,"storage_capacity":0.8,"condition":0.58,"maintenance_debt":0.0,"service_access":0.34,"hazard_exposure":rng.randf_range(0.08,0.20),"prosperity":0.31,
		"status":"under_construction","construction_progress":0.0,"growth_cause":"household crowding, available labor, and delivered materials","pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied",
		"displaced_households":0,"returning_households":0,"claim_pressure":0.0,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _roof_plan_for(plot_seed:int,material_family:String,form:String)->String:
	if form in ["portable_shelter_cluster","light_shelter_cluster"]:
		return ["round_light_shelter","tapered_light_shelter","ridge_light_shelter"][absi(plot_seed)%3]
	if material_family=="earth":
		return ["irregular_flat","courtyard_flat","mixed_earthen_span"][absi(plot_seed)%3]
	if material_family=="stone":
		return ["rubble_slab","timber_span_on_rubble","rubble_slab"][absi(plot_seed)%3]
	return ["round_thatch","tapered_thatch","timber_ridge","long_thatch"][absi(plot_seed)%4]

func rebuild_summary()->Dictionary:
	var active_plots:=0
	var occupied_area:=0.0
	var built_area:=0.0
	var condition_total:=0.0
	var vacant:=0
	var ruins:=0
	var temporary_camp_population:=0
	var temporary_shelter_capacity:=0
	var uses:Dictionary={}
	var occupied_capacity:=0
	var fabric_generation_total:=0.0
	var era_counts:Dictionary={}
	for plot in GameState.settlement_plots:
		var area:=float(plot.get("area_ha",0.0))
		built_area+=area
		condition_total+=float(plot.get("condition",0.0))
		var status:=String(plot.get("status","active"))
		if status in ["active","stressed","damaged","under_construction"]:
			active_plots+=1
			occupied_area+=area
		if status=="vacant": vacant+=1
		if status=="ruin": ruins+=1
		if String(plot.get("land_use",""))=="temporary_encampment" and status=="active":
			temporary_camp_population+=int(plot.get("resident_count",0))
			temporary_shelter_capacity+=int(plot.get("shelter_capacity",0))
		if status in ["active","stressed"]: occupied_capacity+=int(plot.get("resident_capacity",0))
		if status not in ["vacant","ruin","reclaimed"]: uses[String(plot.get("land_use","vacant"))]=true
		if status not in ["reclaimed"]:
			fabric_generation_total+=float(plot.get("fabric_generation",0))
			var era_key:=String(plot.get("morphology_era","founding"))
			era_counts[era_key]=int(era_counts.get(era_key,0))+1
	var count:=GameState.settlement_plots.size()
	var population:=_primary_population()
	var mean_fabric_generation:=fabric_generation_total/maxf(1.0,float(count))
	var fabric_maturity:=clampf(mean_fabric_generation/12.0,0.0,1.0)
	var surfaced_routes:=0
	for route in GameState.settlement_routes:
		if int(route.get("surface_tier",0))>=2: surfaced_routes+=1
	var surfaced_route_share:=float(surfaced_routes)/maxf(1.0,float(GameState.settlement_routes.size()))
	var permanence:=clampf(0.16+float(active_plots)/maxf(1.0,float(count))*0.15+float(GameState.settlement_completed.size())*0.035+fabric_maturity*0.34,0.0,1.0)
	var specialization:=clampf(float(GameState.population_allocations.get("Crafting",0)+GameState.population_allocations.get("Extraction",0)+GameState.population_allocations.get("Knowledge",0)+GameState.population_allocations.get("Administration",0)+GameState.population_allocations.get("Logistics",0))/maxf(1.0,_primary_able_population()),0.0,1.0)
	var exchange:=clampf(float(GameState.economy_metrics.get("market_access",float(GameState.simulation_metrics.get("logistics",0.16))*0.35+DiscoverySystem.effect("trade_capacity")*0.40)),0.0,1.0)
	var institutions:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.62))*0.35+GameState.effective_workers("Administration")/maxf(1.0,float(population)*0.06)*0.25,0.0,1.0)
	var connectivity:=clampf(float(GameState.simulation_metrics.get("logistics",0.16))*0.55+DiscoverySystem.effect("route_speed")*0.30,0.0,1.0)
	var infrastructure:=clampf(float(GameState.settlement_completed.size())/10.0+DiscoverySystem.effect("construction_rate")*0.20+fabric_maturity*0.26+surfaced_route_share*0.18,0.0,1.0)
	var service_population:=roundi(float(population)*(1.0+exchange*0.55+connectivity*0.35))
	var food_import_share:=clampf(float(GameState.simulation_metrics.get("food_import_share",0.0)),0.0,1.0)
	var summary:Dictionary={
		"classification":"founding camp","classification_confidence":0.80,"resident_population":population,"service_population":service_population,
		"built_area_ha":built_area,"occupied_area_ha":occupied_area,"vacancy_ratio":float(vacant)/maxf(1.0,float(count)),"ruin_ratio":float(ruins)/maxf(1.0,float(count)),
		"mean_condition":condition_total/maxf(1.0,float(count)),"density_people_ha":float(population)/maxf(0.01,occupied_area),"permanence":permanence,
		"specialization":specialization,"exchange":exchange,"institutions":institutions,"connectivity":connectivity,"infrastructure":infrastructure,
		"price_stability":clampf(1.0-absf(float(GameState.economy_metrics.get("inflation",0.0)))*8.0,0.0,1.0),"inequality":float(GameState.economy_metrics.get("inequality",0.0)),
		"diversity":clampf(float(uses.size())/12.0,0.0,1.0),"mean_fabric_generation":mean_fabric_generation,"fabric_maturity":fabric_maturity,"morphology_eras":era_counts,"surfaced_route_share":surfaced_route_share,"food_import_share":food_import_share,"active_nuclei":_active_nuclei(),"district_count":maxi(1,_active_nuclei()),
		"usable_resident_capacity":occupied_capacity,"population_without_permanent_housing":maxi(0,population-occupied_capacity),"temporary_camp_population":temporary_camp_population,"temporary_shelter_capacity":temporary_shelter_capacity,"unsheltered_population":maxi(0,population-occupied_capacity-temporary_shelter_capacity),"limiting_factors":[]
	}
	var classification_result:=_classify(summary)
	summary["classification"]=classification_result.classification
	summary["classification_confidence"]=classification_result.confidence
	summary["limiting_factors"]=classification_result.limits
	GameState.settlement_morphology=summary
	return summary

func _classify(summary:Dictionary)->Dictionary:
	var limits:Array[String]=[]
	if float(summary.permanence)<0.35: return {"classification":"founding camp","confidence":0.90,"limits":["permanent household fabric has not yet stabilized"]}
	if float(summary.permanence)<0.50:
		return {"classification":"hamlet","confidence":0.78,"limits":["permanence remains below village level"]}
	var communal_functions:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) in ["communal","storage","water","civic","sacred"] and String(plot.get("status",""))=="active": communal_functions+=1
	var resident_population:=int(summary.resident_population)
	var city_functions:=float(summary.exchange)>=0.55 and float(summary.institutions)>=0.50 and float(summary.infrastructure)>=0.50 and float(summary.food_import_share)>=0.15 and int(summary.district_count)>=3 and float(summary.service_population)>=float(summary.resident_population)*1.5
	if resident_population>=10000000 and city_functions and float(summary.connectivity)>=0.68 and float(summary.infrastructure)>=0.75 and float(summary.specialization)>=0.55 and int(summary.district_count)>=6:
		return {"classification":"megalopolis","confidence":0.76,"limits":[]}
	if resident_population>=1000000 and city_functions and float(summary.connectivity)>=0.55 and float(summary.infrastructure)>=0.64 and float(summary.specialization)>=0.45 and int(summary.district_count)>=4:
		return {"classification":"metropolis","confidence":0.74,"limits":[]}
	if city_functions:
		return {"classification":"city","confidence":0.72,"limits":[]}
	if float(summary.exchange)>=0.35 and float(summary.specialization)>=0.30 and float(summary.connectivity)>=0.30 and int(summary.service_population)>int(summary.resident_population):
		return {"classification":"town","confidence":0.74,"limits":[]}
	if float(summary.permanence)>=0.50 and communal_functions>=2:
		if float(summary.exchange)<0.35: limits.append("exchange remains local or periodic")
		if float(summary.connectivity)<0.30: limits.append("regional travel remains costly")
		return {"classification":"village","confidence":0.76,"limits":limits}
	limits.append("shared permanent functions remain insufficient")
	return {"classification":"hamlet","confidence":0.70,"limits":limits}

func classification()->String:
	if GameState.settlement_morphology.is_empty(): rebuild_summary()
	return String(GameState.settlement_morphology.get("classification","founding camp"))

func classification_reason()->String:
	if GameState.settlement_morphology.is_empty(): rebuild_summary()
	var limits:Array=GameState.settlement_morphology.get("limiting_factors",[])
	return "Functional gates satisfied." if limits.is_empty() else "; ".join(limits)

func plots_for_lod(lod:int)->Array[Dictionary]:
	ensure_founded()
	return GameState.settlement_plots.duplicate(true)

func apply_plot_damage(plot_id:int,severity:float,cause:String)->Dictionary:
	for plot in GameState.settlement_plots:
		if int(plot.get("id",-1))!=plot_id: continue
		_apply_damage_to_plot_record(plot,clampf(severity,0.0,1.0),cause)
		_record_plot_damage_history(plot,cause)
		GameState.morphology_revision+=1
		rebuild_summary()
		return plot
	return {}


func apply_bounded_siege_damage(seed:int,severity:float,extent_share:float,cause:String)->Array[int]:
	# A battle damages a coherent part of the persistent aggregate fabric. It never
	# spawns one record per building: even a billion-person megalopolis changes at most
	# this fixed number of already-simulated plots in one engagement.
	var eligible:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		if String(plot.get("status","active")) in ["vacant","ruin","reclaimed"]: continue
		if String(plot.get("land_use","")) in ["field","pasture","water","waste"]: continue
		eligible.append(plot)
	if eligible.is_empty(): return []
	var epicenter:Vector2=Vector2(eligible[posmod(seed,eligible.size())].get("centroid",Vector2.ZERO))
	eligible.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_distance:=Vector2(a.get("centroid",Vector2.ZERO)).distance_squared_to(epicenter)
		var b_distance:=Vector2(b.get("centroid",Vector2.ZERO)).distance_squared_to(epicenter)
		if not is_equal_approx(a_distance,b_distance): return a_distance<b_distance
		return posmod(int(a.get("id",0))^seed,2147483647)<posmod(int(b.get("id",0))^seed,2147483647)
	)
	var affected_count:=clampi(ceili(float(eligible.size())*clampf(extent_share,0.01,1.0)),1,mini(MAX_BATTLE_DAMAGED_PLOTS,eligible.size()))
	var bounded_severity:=clampf(severity,0.0,1.0)
	var affected:Array[int]=[]
	for index in affected_count:
		var plot:Dictionary=eligible[index]
		var falloff:=lerpf(1.0,0.38,float(index)/maxf(1.0,float(affected_count-1)))
		_apply_damage_to_plot_record(plot,bounded_severity*falloff,cause)
		_record_plot_damage_history(plot,cause)
		affected.append(int(plot.get("id",-1)))
	if not affected.is_empty():
		GameState.morphology_revision+=1
		if GameState.settlement_plot_history.size()>MAX_PLOT_HISTORY:
			GameState.settlement_plot_history=GameState.settlement_plot_history.slice(GameState.settlement_plot_history.size()-MAX_PLOT_HISTORY)
		rebuild_summary()
	return affected


func _apply_damage_to_plot_record(plot:Dictionary,severity:float,cause:String)->void:
	var bounded:=clampf(severity,0.0,1.0)
	if String(plot.get("pre_damage_use",""))=="": plot["pre_damage_use"]=String(plot.get("land_use",""))
	plot["condition"]=clampf(float(plot.get("condition",1.0))-bounded,0.0,1.0)
	plot["damaged_day"]=int(floor(GameState.elapsed_days))
	var damage:Dictionary=plot.get("damage",{}).duplicate(true)
	var channel:="fire" if "fire" in cause.to_lower() else "structural"
	damage[channel]=clampf(float(damage.get(channel,0.0))+bounded,0.0,1.0)
	plot["damage"]=damage
	plot["status"]="ruin" if float(plot.condition)<0.20 else "damaged"
	plot["repair_state"]="unrepairable" if String(plot.status)=="ruin" else "awaiting_assessment"


func _record_plot_damage_history(plot:Dictionary,cause:String)->void:
	GameState.settlement_plot_history.append({"day":int(floor(GameState.elapsed_days)),"plot_id":int(plot.get("id",-1)),"event":"damage","new_state":plot.status,"cause":cause})
	_record_plot_building_event(plot,"destroyed" if String(plot.get("status",""))=="ruin" else "damaged",int(floor(GameState.elapsed_days)),{},false,cause)

func apply_area_damage(center_km:Vector2,radius_km:float,severity:float,cause:String)->Array[int]:
	var affected:Array[int]=[]
	for plot in GameState.settlement_plots:
		var distance:=Vector2(plot.get("centroid",Vector2.ZERO)).distance_to(center_km)
		if distance>radius_km: continue
		var falloff:=1.0-distance/maxf(0.001,radius_km)
		apply_plot_damage(int(plot.id),severity*falloff,cause)
		affected.append(int(plot.id))
	return affected

func abandon_plot(plot_id:int,cause:String)->Dictionary:
	for plot in GameState.settlement_plots:
		if int(plot.get("id",-1))!=plot_id: continue
		plot["status"]="vacant"
		plot["reoccupation_state"]="displaced"
		plot["abandoned_day"]=int(floor(GameState.elapsed_days))
		plot["resident_count"]=0
		GameState.settlement_plot_history.append({"day":int(floor(GameState.elapsed_days)),"plot_id":plot_id,"event":"abandoned","new_state":"vacant","cause":cause})
		_record_plot_building_event(plot,"abandoned",int(floor(GameState.elapsed_days)),{},false,cause)
		GameState.morphology_revision+=1
		rebuild_summary()
		return plot
	return {}

func validate_state()->PackedStringArray:
	var errors:=PackedStringArray()
	var ids:Dictionary={}
	for plot in GameState.settlement_plots:
		var id:=int(plot.get("id",-1))
		if id<1: errors.append("plot has invalid id")
		elif ids.has(id): errors.append("duplicate plot id %d" % id)
		ids[id]=true
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		if polygon.size()<3: errors.append("plot %d has fewer than three vertices" % id)
		if _polygon_area_km2(polygon)<=0.0: errors.append("plot %d has non-positive area" % id)
		if String(plot.get("status","")) not in VALID_STATUSES: errors.append("plot %d has invalid status" % id)
		if String(plot.get("repair_state","")) not in VALID_REPAIR_STATES: errors.append("plot %d has invalid repair state" % id)
		if String(plot.get("reoccupation_state","")) not in VALID_REOCCUPATION_STATES: errors.append("plot %d has invalid reoccupation state" % id)
		if String(plot.get("land_use","")) not in VALID_LAND_USES: errors.append("plot %d has invalid land use" % id)
	errors.append_array(validate_settlement_network())
	return errors

func validate_settlement_network()->PackedStringArray:
	var errors:=PackedStringArray()
	if GameState.player_settlements.size()>MAX_PLAYER_SETTLEMENTS: errors.append("settlement register exceeds its bounded record limit")
	var ids:Dictionary={}
	var primary_count:=0
	var satellite_share:=0.0
	for settlement in GameState.player_settlements:
		var id:=String(settlement.get("id",""))
		if id=="": errors.append("settlement has no id")
		elif ids.has(id): errors.append("duplicate settlement id %s" % id)
		ids[id]=true
		if bool(settlement.get("primary",false)): primary_count+=1
		else:
			var share:=float(settlement.get("population_share",-1.0))
			if not is_finite(share) or share<=0.0: errors.append("settlement %s has an invalid population share" % id)
			satellite_share+=maxf(0.0,share)
		var position:=_record_position(settlement)
		if not is_finite(position.x) or not is_finite(position.y): errors.append("settlement %s has an invalid position" % id)
		var territory_context:Dictionary=settlement.get("territory_context",{})
		for driver in ["terrain_permeability","water_access","work_access","travel_access"]:
			if not territory_context.has(driver): continue
			var value:=float(territory_context.get(driver,0.0))
			if not is_finite(value) or value<0.0 or value>1.0: errors.append("settlement %s has an invalid %s territory driver" % [id,driver])
		var axes:Array=territory_context.get("access_axes",[])
		if axes.size()>MAX_TERRITORY_ACCESS_AXES: errors.append("settlement %s exceeds its bounded territory access axes" % id)
		for axis_variant in axes:
			var axis:Dictionary=axis_variant
			if _vector2_value(axis.get("direction",Vector2.ZERO)).length_squared()<0.000001: errors.append("settlement %s has an invalid territory access direction" % id)
	if not GameState.player_settlements.is_empty() and primary_count!=1: errors.append("settlement register must contain exactly one primary settlement")
	if bool(GameState.settlement_convoy.get("active",false)):
		var convoy_share:=float(GameState.settlement_convoy.get("population_share",-1.0))
		if not is_finite(convoy_share) or convoy_share<=0.0: errors.append("settlement convoy has an invalid population share")
		satellite_share+=maxf(0.0,convoy_share)
		if float(GameState.settlement_convoy.get("duration_days",0.0))<=0.0: errors.append("settlement convoy has an invalid duration")
		var convoy_progress:=float(GameState.settlement_convoy.get("progress",-1.0))
		if not is_finite(convoy_progress) or convoy_progress<0.0 or convoy_progress>1.0: errors.append("settlement convoy has invalid progress")
		if String(GameState.settlement_convoy.get("phase","")) not in ["traveling","arrived"]: errors.append("settlement convoy has an invalid lifecycle phase")
	if satellite_share>0.92: errors.append("satellite settlements and convoys consume too much of the aggregate population")
	for settlement in settlement_network_snapshot().settlements:
		var boundary:PackedVector2Array=settlement.get("boundary",PackedVector2Array())
		if boundary.size()!=SETTLEMENT_BORDER_VERTICES: errors.append("settlement %s has an invalid bounded border" % String(settlement.get("id","")))
		var radius:=float(settlement.get("claim_radius_km",0.0))
		if not is_finite(radius) or radius<=0.0: errors.append("settlement %s has an invalid claim radius" % String(settlement.get("id","")))
	return errors

func _polygon_area_km2(polygon:PackedVector2Array)->float:
	if polygon.size()<3: return 0.0
	var twice_area:=0.0
	for index in polygon.size():
		var next:=(index+1)%polygon.size()
		twice_area+=polygon[index].x*polygon[next].y-polygon[next].x*polygon[index].y
	return absf(twice_area)*0.5

func _polygon_centroid(polygon:PackedVector2Array)->Vector2:
	if polygon.is_empty(): return Vector2.ZERO
	var sum:=Vector2.ZERO
	for point in polygon: sum+=point
	return sum/float(polygon.size())

func _active_nuclei()->int:
	var count:=0
	for nucleus in GameState.settlement_nuclei:
		if bool(nucleus.get("active",true)): count+=1
	return count
