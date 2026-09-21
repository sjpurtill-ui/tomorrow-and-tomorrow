extends Node
## Synchronous, explicit civilization ownership. No player state is copied or
## swapped: existing rules run against independent instances of the same scripts.
## Scopes must never await; UI and network callbacks run in the human scope.

var actor_id := "player"
var _active:Dictionary={}
var actors:Dictionary={}
var human_projection:Dictionary={}
var market_orders:Dictionary={}
var geography_stock:Dictionary={}
var relation_baselines:Dictionary={}
var enabled:=false
var advancing:=false
var last_day:=-1
var water_provider:Callable
var start_provider:Callable
var route_provider:Callable
var surface_material_provider:Callable
var context_provider:Callable:
	set(value):
		context_provider=value
		surface_material_provider=Callable()
var _seed:=-2147483648

var state := GameState:
	get: return _active.get("GameState",GameState)
var discovery := DiscoverySystem:
	get: return _active.get("DiscoverySystem",DiscoverySystem)
var progression := ProgressionSystem:
	get: return _active.get("ProgressionSystem",ProgressionSystem)
var resources := ResourceSystem:
	get: return _active.get("ResourceSystem",ResourceSystem)
var economy := EconomySystem:
	get: return _active.get("EconomySystem",EconomySystem)
var settlements := SettlementModel:
	get: return _active.get("SettlementModel",SettlementModel)
var government := GovernmentPeopleSystem:
	get: return _active.get("GovernmentPeopleSystem",GovernmentPeopleSystem)
var figures := HistoricalFigures:
	get: return _active.get("HistoricalFigures",HistoricalFigures)
var direction := PeopleDirection:
	get: return _active.get("PeopleDirection",PeopleDirection)
var communities := CommunityNetwork:
	get: return _active.get("CommunityNetwork",CommunityNetwork)
var diplomacy := ForeignDiplomacy:
	get: return _active.get("ForeignDiplomacy",ForeignDiplomacy)
var dialogue := ForeignDialogue:
	get: return _active.get("ForeignDialogue",ForeignDialogue)
var facts := WorldFacts:
	get: return _active.get("WorldFacts",WorldFacts)
var advisors := AdvisorSystem:
	get: return _active.get("AdvisorSystem",AdvisorSystem)
var food := FoodSystem:
	get: return _active.get("FoodSystem",FoodSystem)
var consequences := ConsequenceEngine:
	get: return _active.get("ConsequenceEngine",ConsequenceEngine)
var civics := CivicImplementationSystem:
	get: return _active.get("CivicImplementationSystem",CivicImplementationSystem)
var world := CivilizationSystem:
	get: return _active.get("CivilizationSystem",CivilizationSystem)
var military := MilitaryCampaign:
	get: return _active.get("MilitaryCampaign",MilitaryCampaign)
var campaign := GeneralCampaign:
	get: return _active.get("GeneralCampaign",GeneralCampaign)
var general_dialogue := GeneralDialogue:
	get: return _active.get("GeneralDialogue",GeneralDialogue)

const OWNED_SYSTEMS:=["GameState", "DiscoverySystem", "ProgressionSystem", "ResourceSystem", "EconomySystem", "SettlementModel", "GovernmentPeopleSystem", "HistoricalFigures", "PeopleDirection", "CommunityNetwork", "ForeignDiplomacy", "ForeignDialogue", "WorldFacts", "AdvisorSystem", "FoodSystem", "ConsequenceEngine", "CivicImplementationSystem", "CivilizationSystem", "MilitaryCampaign", "GeneralCampaign", "GeneralDialogue"]

func system(system_name:String)->Node:
	if _active.has(system_name): return _active[system_name]
	return get_tree().root.get_node_or_null(system_name) if is_inside_tree() else null

func scoped(id:String,operation:Callable)->Variant:
	assert(id=="player" or actors.has(id),"Unknown civilization owner")
	var previous:=_active
	var previous_id:=actor_id
	actor_id=id
	_active={} if id=="player" else actors[id].systems
	var result:Variant=operation.call()
	_active=previous
	actor_id=previous_id
	return result

func clear()->void:
	assert(_active.is_empty())
	for actor in actors.values():
		for instance in actor.systems.values(): instance.free()
	actors.clear()
	human_projection.clear()
	market_orders.clear()
	geography_stock.clear()
	relation_baselines.clear()
	enabled=false
	last_day=-1

func create_actor(id:String,seed_value:int,origin:Vector2=Vector2.ZERO)->Dictionary:
	assert(id!="player" and not actors.has(id))
	var systems:Dictionary={}
	for system_name in OWNED_SYSTEMS:
		systems[system_name]=system(system_name).get_script().new()
	actors[id]={"systems":systems,"controller":"ai","last_day":0,"origin":origin,"orders":[],"sequence":0}
	scoped(id,func()->void:
		state.reset_for_new_world(seed_value)
		state.initialize_population_model()
		progression.reset_for_new_world()
		world.last_world_seed=seed_value
		world.player_world_origin=origin
		world.last_processed_day=0
		world.last_turn_day=0
		world._add_revealed_area(origin,72.0,"founding knowledge")
		military.simulator=military.COMBAT_SIMULATOR_SCRIPT.new()
		military.reset_for_new_world()
		resources.initialize()
		food.initialize()
		consequences.initialize()
		economy.initialize()
		discovery.initialize()
	)
	return actors[id]

func start_world()->void:
	if enabled and _seed==GameState.world_seed:
		bind_geography()
		refresh_projections()
		refresh_views()
		return
	if GameState.elapsed_days>0:
		# Legacy campaigns retain their original populations and opponent model.
		# SaveSystem reports that equal-rule starts require a new world.
		return
	clear()
	_seed=GameState.world_seed
	last_day=int(GameState.elapsed_days)
	for civ in CivilizationSystem.civilizations:
		var id:=String(civ.id)
		var origin:=CivilizationSystem._civilization_world_position(civ)
		if start_provider.is_valid():origin=start_provider.call(origin)
		civ.world_position=origin
		civ.position=Vector2(origin.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,origin.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
		create_actor(id,_seed,origin)
		actors[id]["identity"]=civ.duplicate(true)
		actors[id].last_day=last_day
		scoped(id,func()->void:
			state.elapsed_days=last_day
			state.settlement_name=String(civ.strategic_regions[-1].name)
			world.ground_survey_authority=CivilizationSystem.ground_survey_authority
			world.scout_land_authority=CivilizationSystem.scout_land_authority
			var geographic:=preload("res://scripts/civilization_day.gd").context(actors[id].origin)
			state.settlement_founded_at=geographic.origin
			state.province_terrain=String(geographic.environment_profile.get("biome","Plains"))
		)
	enabled=true
	bind_geography()
	refresh_projections()
	refresh_views()

func advance_rivals(target_day:int)->void:
	if not enabled or advancing or target_day<=last_day:return
	advancing=true
	while last_day<target_day:
		last_day+=1
		refresh_views()
		var ids:=actors.keys();ids.sort()
		for id:String in ids:
			if int(actors[id].last_day)>=last_day:continue
			scoped(id,func()->void:
				state.elapsed_days=last_day
				preload("res://scripts/civilization_controller.gd").choose_orders(id)
				var origin:Vector2=world.player_world_origin
				if state.settlement_site_committed:origin=Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z)
				var daily:=preload("res://scripts/civilization_day.gd").context(origin,state.convoy_traveling)
				preload("res://scripts/civilization_day.gd").advance(last_day,daily)
				world.advance_to_day(last_day)
			)
			actors[id].last_day=last_day
		refresh_projections()
	advancing=false

func refresh_projections()->void:
	if not CivilizationSystem.civilizations.is_empty():
		if human_projection.is_empty():
			human_projection=CivilizationSystem.civilizations[0].duplicate(true)
			human_projection.id="human"
			for region in human_projection.strategic_regions:
				region.id="human_"+String(region.id);region.controller="human";region.original_controller="human"
		human_projection.name=GameState.settlement_name
		human_projection.world_position=CivilizationSystem.player_world_origin
		scoped("player",func()->void:project(human_projection))
	for index in CivilizationSystem.civilizations.size():
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		var id:=String(civ.id)
		if not actors.has(id):continue
		scoped(id,func()->void:project(civ))

func project(civ:Dictionary)->void:
	# This is a read model for the existing atlas, diplomacy, and contact system.
	# It does not generate resources, people, troops, discoveries, or cities.
	civ.population=state.population_exact
	civ.cohorts={}
	for key in GameState.POPULATION_AGE_COHORTS:civ.cohorts[key]=float(state.population_cohorts.get(key,0))
	civ.health=state.population_health
	var metrics:=state.simulation_metrics
	for pair in [["cohesion","cohesion"],["knowledge","knowledge"],["production","material_capacity"],["logistics","logistics"],["ecology","ecology"]]:civ[pair[0]]=clampf(float(metrics.get(pair[1],0)),0.0,1.0)
	civ.food_days=maxf(0.0,float(metrics.get("food_days",0)))
	civ.institutions=float(state.society_capacities.get("institutions",0))
	civ.food_capacity=maxf(0,float(metrics.get("food_production",0)))
	# A population share is a bounded demographic summary, not the raw military
	# commitment ledger (which can retain absent personnel after population loss).
	civ.military_population=minf(float(military._mobilized_count()),maxf(0,state.population_exact))
	civ.military_share=float(civ.military_population)/maxf(1,state.population_exact)
	civ.military_readiness=float(military.home_army.get("readiness",0))
	civ.military_stockpile=0.0
	for amount in military.military_inventory.values():civ.military_stockpile+=int(amount)
	civ["local_allocations"]=state.population_allocation_percentages.duplicate(true)
	civ.allocations={}
	var total:=0.0
	for roles in [["sustenance","Food"],["growth","Construction","Survey"],["knowledge","Knowledge"],["production","Extraction","Crafting","Logistics"],["military","Defense"],["diplomacy","Administration"]]:
		var amount:=0.0
		for role in roles.slice(1):amount+=float(state.population_allocation_percentages.get(role,0))
		civ.allocations[roles[0]]=amount;total+=amount
	for role in civ.allocations:civ.allocations[role]/=maxf(1,total)
	civ.founding_focus=state.founding_focus
	if progression.cached_player_profile.is_empty():progression.cached_player_profile=progression._build_player_discovery_profile()
	civ.discovery_profile={"domains":progression.cached_player_profile.duplicate(true),"momentum":{}}
	for domain in progression.domain_levels:civ.discovery_profile.momentum[domain]=0.0
	civ["local_capacities"]=state.society_capacities.duplicate(true)
	civ.world_reach=world.progression_reach_snapshot().combined
	civ.progression_tiers=progression.domain_levels.duplicate(true)
	civ.settlement_count=state.player_settlements.size()
	civ.alive=state.population_total>0
	civ["shared_rules"]=true
	civ.territory=world._player_territory()
	civ["land_personnel"]=military._mobilized_count()-military.joint_operations.personnel()
	var regions:Array=civ.strategic_regions
	for region:Dictionary in regions:
		region["settlement_founded"]=false
		region.population=0.0
		region.fortification=0.0
		region["garrison"]=0
	var network:=settlements.settlement_network_snapshot()
	for index in network.settlements.size():
		var city:Dictionary=network.settlements[index]
		var primary:=bool(city.get("primary",false))
		var slot:int=4 if primary else (index-1 if index<5 else index)
		if slot>=regions.size():
			var added:Dictionary=(regions[4] as Dictionary).duplicate(true)
			added.id="%s_city_%d" % [civ.id,index]
			added.role="frontier";added.approach_index=slot
			regions.append(added)
		var region:Dictionary=regions[slot]
		var local:=settlements.city_resource_snapshot(String(city.id),false,true)
		region["settlement_founded"]=true
		region["local_city_id"]=String(city.id)
		region["position"]=city.position
		region["boundary"]=city.get("boundary",[]).duplicate()
		region.name=city.name
		region.population=local.population
		region.population_share=float(local.population)/maxf(1,state.population_exact)
		region.controller=String(city.get("occupied_by",civ.id))
		if region.controller=="human":region.controller="player"
		if String(region.controller).is_empty():region.controller=String(civ.id)
		region["local_metrics"]=local.metrics.duplicate(true)
		region.fortification=clampf(float(military.settlement_defense.get("stage",0))/5.0,0,1) if primary else 0.0
		region.garrison=int(military.home_army.get("troops",0)) if primary else 0
		region["stores"]=local.stores.duplicate(true)
		for occupied:Dictionary in military.recovery.data.occupied:
			if String(occupied.city_id)==String(city.id) and not bool(occupied.get("liberated",false)):
				for field in ["governance","damage","resistance","integration"]:region[field]=occupied.region.get(field,region.get(field,0))
	civ.strategic_regions=regions

func refresh_views()->void:
	preload("res://scripts/civilization_relations.gd").synchronize()
	var troops:=preload("res://scripts/civilization_combat.gd").troop_catalog()
	for id:String in actors:
		var observer:Node=actors[id].systems.CivilizationSystem
		var old_relations:Dictionary={}
		var previous_views:Dictionary={}
		for previous:Dictionary in observer.civilizations:
			old_relations[String(previous.id)]=previous.player_relation
			previous_views[String(previous.id)]=previous
		observer.civilizations.clear()
		for civ:Dictionary in CivilizationSystem.civilizations:
			if String(civ.id)==id:continue
			var visible:=_updated_observer_view(civ,previous_views.get(String(civ.id),{}))
			visible.player_relation=observer._relation_with_strategy_defaults(old_relations.get(String(civ.id),(civ.relations as Dictionary).get(id,{})),visible)
			_localize_controllers(visible,id)
			observer.civilizations.append(visible)
		if not human_projection.is_empty():
			var human:=_updated_observer_view(human_projection,previous_views.get("human",{}))
			human.player_relation=observer._relation_with_strategy_defaults(old_relations.get("human",{}),human)
			_localize_controllers(human,id)
			observer.civilizations.append(human)
		observer.foreign_formations.assign(preload("res://scripts/civilization_combat.gd").troop_views(id,troops))
	CivilizationSystem.foreign_formations.assign(preload("res://scripts/civilization_combat.gd").troop_views("player",troops))


func _updated_observer_view(source:Dictionary,previous:Dictionary)->Dictionary:
	var view:Dictionary={}
	for field in source:
		# The observer owns its relation; the caller restores and normalizes it.
		if field=="player_relation":continue
		var value:Variant=source[field]
		if value is Dictionary or value is Array:
			# Equal data is already a private copy belonging to this observer.
			# Changed data is copied before any observer-local mutations.
			view[field]=previous[field] if previous.has(field) and previous[field]==value else value.duplicate(true)
		else:view[field]=value
	return view

func submit(id:String,order:Dictionary)->Dictionary:
	if id!="player" and not actors.has(id):return {"error":"Unknown civilization."}
	return scoped(id,func()->Dictionary:
		var result:=preload("res://scripts/civilization_orders.gd").execute(order)
		if id!="player":
			actors[id].sequence+=1
			actors[id].orders.append({"sequence":actors[id].sequence,"day":int(state.elapsed_days),"order":order.duplicate(true),"result":result.duplicate(true)})
			if actors[id].orders.size()>32:actors[id].orders.pop_front()
		return result
	)

const SNAPSHOT=preload("res://scripts/save_system.gd")
const CURATED:=["MilitaryCampaign","ProgressionSystem","ForeignDiplomacy","GeneralCampaign"]

func capture_actor(id:String)->Dictionary:
	return scoped(id,func()->Dictionary:
		var payload:Dictionary={}
		for name in OWNED_SYSTEMS:
			var instance:=system(name)
			if name in CURATED:payload[name]=instance.export_state()
			else:
				var skip:Array=SNAPSHOT.REFLECT_SKIP.get(name,[]).duplicate()
				if name=="CivilizationSystem":skip.append_array(["civilizations","foreign_formations","open_scout_plan_cache"])
				payload[name]=SNAPSHOT._capture_reflected(instance,skip)

		payload["society_model"]=SNAPSHOT._capture_reflected(discovery.society_model,SNAPSHOT.SOCIETY_REFLECT_SKIP)
		payload["city_intelligence"]=world.city_intelligence.records.duplicate(true)
		payload["rumor_books"]=world.rumor_network.books.duplicate(true)
		payload["chronicle"]=world.chronicle.data.duplicate(true)
		payload["scouting_staff"]=world.scouting_staff.data.duplicate(true)
		payload["relations"]={}
		for civ in world.civilizations:payload.relations[String(civ.id)]=civ.player_relation.duplicate(true)
		return payload
	)

func export_state()->Dictionary:
	var result:={"version":1,"enabled":enabled,"seed":_seed,"last_day":last_day,"actors":{},"geography_stock":geography_stock.duplicate(true),"relation_baselines":relation_baselines.duplicate(true)}
	for id:String in actors:
		result.actors[id]={"controller":actors[id].controller,"last_day":actors[id].last_day,"origin":actors[id].origin,"sequence":actors[id].sequence,"orders":actors[id].orders.duplicate(true),"state":capture_actor(id)}
	return result

func validate_payload(payload:Dictionary)->String:
	if payload.is_empty():return ""
	if int(payload.get("version",0))!=1:return "Unsupported civilization simulation version."
	if not payload.get("actors") is Dictionary:return "Invalid civilization ownership register."
	if payload.actors.size()>CivilizationSystem.MAX_RIVAL_CIVILIZATIONS:return "Too many civilization owners."
	if not payload.get("geography_stock",{}) is Dictionary:return "Invalid shared world reserves."
	for reserve in payload.get("geography_stock",{}).values():
		if not reserve is Dictionary:return "Invalid world reserve."
		for key in ["remaining","initial_amount"]:
			var amount:Variant=reserve.get(key)
			if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)<0:return "Invalid world reserve balance."
	for id in payload.actors:
		if not id is String or id=="player" or String(id).length()>80:return "Invalid civilization identity."
		var actor:Variant=payload.actors[id]
		if not actor is Dictionary or not actor.get("state") is Dictionary:return "Missing owned civilization state."
		for name in OWNED_SYSTEMS:
			if not actor.state.get(name) is Dictionary:return "Missing civilization system: "+name
		if not actor.get("origin") is Vector2 or not actor.get("orders") is Array or not actor.get("sequence") is int:return "Invalid civilization controller state."
		for name in OWNED_SYSTEMS:
			if name in CURATED:continue
			var instance:=system(name)
			var property_types:Dictionary={}
			for property in instance.get_property_list():
				if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE:property_types[String(property.name)]=property.type
			for field:String in actor.state[name]:
				if field.begins_with("rng_state:"):
					if not instance.get(field.trim_prefix("rng_state:")) is RandomNumberGenerator or not actor.state[name][field] is int:return "Invalid civilization random generator."
					continue
				if not property_types.has(field):return "Unknown civilization field: "+field
				var saved_type:=typeof(actor.state[name][field]);var expected_type:=int(property_types[field])
				if expected_type!=TYPE_NIL and saved_type!=expected_type and not (saved_type in [TYPE_INT,TYPE_FLOAT] and expected_type in [TYPE_INT,TYPE_FLOAT]):return "Invalid civilization field type: "+field
		if not preload("res://scripts/civic_administration.gd").valid(actor.state.get("GovernmentPeopleSystem",{}).get("administration_records",preload("res://scripts/civic_administration.gd").empty_state())):return "Invalid civilization civic administration records."
		if not preload("res://scripts/water_conveyance_state.gd").valid_state(actor.state.GameState):return "Invalid civilization water conveyance records."
		if not preload("res://scripts/water_waste_works_state.gd").valid_state(actor.state.GameState):return "Invalid civilization water and waste works records."
		if not preload("res://scripts/rail_freight_state.gd").valid_state(actor.state.GameState):return "Invalid civilization rail freight records."
		if not preload("res://scripts/building_material_operations.gd").valid_state(actor.state.GameState):return "Invalid civilization building material or curing records."
		var nutrition:=preload("res://scripts/crop_nutrition.gd")
		var clothing=preload("res://scripts/household_clothing.gd")
		if not preload("res://scripts/fire_practice.gd").valid(actor.state.GameState.get("fire_practice",preload("res://scripts/fire_practice.gd").empty_state())):return "Invalid civilization maintained fire records."
		var opening=preload("res://scripts/opening_craft_practice.gd")
		if not opening.valid(actor.state.GameState.get("opening_craft_practice",opening.empty_state())) or not opening.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization opening craft records."
		var opportunities=preload("res://scripts/opening_opportunities.gd")
		if not opportunities.valid(actor.state.GameState.get("opening_opportunities",opportunities.empty_state())):return "Invalid civilization opening opportunity records."
		if not clothing.valid(actor.state.GameState.get("household_clothing",clothing.empty_state())) or not clothing.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization clothing records."
		if not preload("res://scripts/civilian_care_state.gd").valid_state(actor.state.GameState):return "Invalid civilian clinical care records."
		var batches=preload("res://scripts/food_batches.gd")
		if not batches.valid(actor.state.GameState.get("food_batches",batches.empty_state())) or not batches.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization food batch records."
		var grain=preload("res://scripts/grain_processing.gd")
		if not grain.valid(actor.state.GameState.get("grain_processing",grain.empty_state())) or not grain.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization grain processing records."
		var microscopy=preload("res://scripts/microscopy_samples.gd")
		if not microscopy.valid(actor.state.GameState.get("microscopy",microscopy.empty_state())) or not microscopy.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization microscopy records."
		var botany=preload("res://scripts/field_botany.gd")
		if not botany.valid(actor.state.GameState.get("field_botany",botany.empty_state())) or not botany.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization field botany records."
		if not nutrition.valid(actor.state.GameState.get("cultivation_nutrients",nutrition.empty_state())) or not nutrition.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization cultivation nutrient reserves."
		if not preload("res://scripts/technology_operations.gd").valid(actor.state.GameState.get("technology_operations",preload("res://scripts/technology_operations.gd").empty_state())):return "Invalid civilization technology installations."
		if not preload("res://scripts/society_exchange.gd").valid(actor.state.GameState.get("society_exchange",preload("res://scripts/society_exchange.gd").empty_state())):return "Invalid civilization exchange records."
		for mission:Variant in actor.state.CivilizationSystem.get("scout_missions",[])+[actor.state.CivilizationSystem.get("diplomatic_mission",{})]:
			if not mission is Dictionary or not preload("res://scripts/society_exchange.gd").valid_mission(mission):return "Invalid carried exchange records."
		if not CivilizationSystem.scouting_staff.valid(actor.state.get("scouting_staff",{})):return "Invalid civilization scouting allocation."
		var armed:Dictionary=actor.state.MilitaryCampaign
		for field in ["aggregate_recruits","training_injury_pool","next_field_army_id"]:
			var number:Variant=armed.get(field,0)
			if not (number is float or number is int) or not is_finite(float(number)) or float(number)<0:return "Invalid civilization military personnel or identifier."
		for field in ["military_inventory","military_consumables","damaged_equipment"]:
			if not armed.get(field,{}) is Dictionary:return "Invalid civilization military stores."
			for number in armed.get(field,{}).values():
				if not (number is float or number is int) or not is_finite(float(number)) or float(number)<0:return "Invalid civilization military stock balance."
		var owned:Dictionary=actor.state.GameState
		var population:Variant=owned.get("population_exact")
		if not (population is float or population is int) or not is_finite(float(population)) or float(population)<0:return "Invalid civilization population."
		if not owned.get("resource_stockpiles") is Dictionary:return "Invalid civilization stores."
		for amount in owned.resource_stockpiles.values():
			if not (amount is float or amount is int) or not is_finite(float(amount)) or float(amount)<0:return "Invalid civilization stock balance."
	return ""

func _restore_state(payload:Dictionary)->Dictionary:
	var error:=validate_payload(payload)
	if error!="":return {"error":error}
	if payload.is_empty():return {"ok":true,"legacy":true}
	clear()
	_seed=int(payload.seed);last_day=int(payload.last_day)
	geography_stock=payload.get("geography_stock",{}).duplicate(true)
	relation_baselines=payload.get("relation_baselines",{}).duplicate(true)
	var failures:Array[String]=[]
	for id:String in payload.actors:
		var saved:Dictionary=payload.actors[id]
		create_actor(id,_seed,saved.origin)
		for key in ["controller","last_day","sequence","orders"]:actors[id][key]=saved[key]
		scoped(id,func()->void:
			for name in OWNED_SYSTEMS:
				var instance:=system(name)
				var fields:Dictionary=saved.state[name].duplicate(true)
				if name in CURATED:
					var restored:Dictionary=instance.import_state(fields)
					if restored.has("error"):failures.append("Civilization %s: %s" % [id,restored.error])
				else:
					for key in fields.keys():
						if String(key).begins_with("rng_state:"):
							instance.get(String(key).trim_prefix("rng_state:")).state=int(fields[key]);fields.erase(key)
					SNAPSHOT._apply_reflected(instance,fields)
			SNAPSHOT._apply_reflected(discovery.society_model,saved.state.get("society_model",{}),SNAPSHOT.SOCIETY_REFLECT_SKIP)
			world.city_intelligence.records=saved.state.get("city_intelligence",{}).duplicate(true)
			world.rumor_network.books=saved.state.get("rumor_books",{}).duplicate(true)
			world.chronicle.data=saved.state.get("chronicle",world.chronicle.data).duplicate(true)
			world.scouting_staff.restore(saved.state.get("scouting_staff",{}))
			for other:String in saved.state.get("relations",{}):world.civilizations.append({"id":other,"player_relation":saved.state.relations[other].duplicate(true)})
		)
	if not failures.is_empty():return {"error":"; ".join(failures)}
	enabled=bool(payload.enabled)
	return {"ok":true}

func advance_day(day:int,daily_context:Dictionary,construction:Callable=Callable())->Dictionary:
	advance_rivals(day)
	var result:Dictionary=scoped("player",func()->Dictionary:return preload("res://scripts/civilization_day.gd").advance(day,daily_context,construction))
	CivilizationSystem.advance_to_day(day)
	refresh_projections()
	refresh_views()
	preload("res://scripts/civilization_joint_contact.gd").advance(day)
	preload("res://scripts/civilization_exchange.gd").settle(day)
	preload("res://scripts/civilization_exchange.gd").occupation(day)
	return result

func _localize_controllers(civ:Dictionary,observer:String)->void:
	for region:Dictionary in civ.get("strategic_regions",[]):
		var controller:=String(region.get("controller",civ.id))
		if controller==observer:region.controller="player"
		elif controller=="player":region.controller="human"

func import_state(payload:Dictionary)->Dictionary:
	return _stage_restore(payload,false)
func check_payload(payload:Dictionary)->Dictionary:
	return _stage_restore(payload,true)
func _stage_restore(payload:Dictionary,validate_only:bool)->Dictionary:
	var error:=validate_payload(payload)
	if error!="":return {"error":error}
	if payload.is_empty():return {"ok":true,"legacy":true}
	var previous:={"actors":actors,"human":human_projection,"enabled":enabled,"seed":_seed,"day":last_day,"geography":geography_stock,"relations":relation_baselines,"markets":market_orders}
	actors={};human_projection={};geography_stock={};relation_baselines={};market_orders={};enabled=false
	var result:=_restore_state(payload)
	if validate_only or result.has("error"):
		clear()
		actors=previous.actors;human_projection=previous.human;geography_stock=previous.geography;relation_baselines=previous.relations;market_orders=previous.markets
		enabled=previous.enabled;_seed=previous.seed;last_day=previous.day
	else:
		for actor in previous.actors.values():
			for instance in actor.systems.values():instance.free()
	return result

func bind_geography()->void:
	for id:String in actors:
		scoped(id,func()->void:
			world.ground_survey_authority=CivilizationSystem.ground_survey_authority
			world.scout_land_authority=CivilizationSystem.scout_land_authority
			military.joint_operations.geography.land_query=CivilizationSystem.scout_land_authority
			military.recovery.surface_assessor=MilitaryCampaign.recovery.surface_assessor
		)

func _exit_tree()->void:
	clear()
