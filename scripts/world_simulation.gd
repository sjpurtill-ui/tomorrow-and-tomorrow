extends Node
## Synchronous, explicit civilization ownership. No player state is copied or
## swapped: existing rules run against independent instances of the same scripts.
## Scopes must never await; UI and network callbacks run in the human scope.

const DaySpan=preload("res://scripts/day_span.gd")
const DayJob=preload("res://scripts/day_job.gd")

var actor_id := "player"
var _active:Dictionary={}
var actors:Dictionary={}
var human_projection:Dictionary={}
var market_orders:Dictionary={}
var geography_stock:Dictionary={}
var relation_baselines:Dictionary={}
var enabled:=false
var advancing:=false
# The world day being run in bounded steps, if any. Never saved: saves and
# loads finish it first (flush_day), so the save format is unchanged.
var _day_job:DayJob=null
var _day_number:=-1
## Day whose closing views are still current. Rival catch-up skips its opening
## refresh when nothing has changed since then.
var _views_day:=-1
## Days the current owner's step covers; always 1 for the human civilization.
## See day_span.gd. `span_limit` 1 restores strictly daily rivals.
var span:=1
var span_limit:=DaySpan.MAX_SPAN
# Autoload system references for the human scope, in _bind_scope order.
var _player_binding:Array=[]
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

var state := GameState
var discovery := DiscoverySystem
var progression := ProgressionSystem
var resources := ResourceSystem
var economy := EconomySystem
var settlements := SettlementModel
var government := GovernmentPeopleSystem
var figures := HistoricalFigures
var direction := PeopleDirection
var communities := CommunityNetwork
var diplomacy := ForeignDiplomacy
var dialogue := ForeignDialogue
var facts := WorldFacts
var advisors := AdvisorSystem
var food := FoodSystem
var consequences := ConsequenceEngine
var civics := CivicImplementationSystem
var world := CivilizationSystem
var military := MilitaryCampaign
var campaign := GeneralCampaign
var general_dialogue := GeneralDialogue

const OWNED_SYSTEMS:=["GameState", "DiscoverySystem", "ProgressionSystem", "ResourceSystem", "EconomySystem", "SettlementModel", "GovernmentPeopleSystem", "HistoricalFigures", "PeopleDirection", "CommunityNetwork", "ForeignDiplomacy", "ForeignDialogue", "WorldFacts", "AdvisorSystem", "FoodSystem", "ConsequenceEngine", "CivicImplementationSystem", "CivilizationSystem", "MilitaryCampaign", "GeneralCampaign", "GeneralDialogue"]

func system(system_name:String)->Node:
	if _active.has(system_name): return _active[system_name]
	return get_tree().root.get_node_or_null(system_name) if is_inside_tree() else null

func scoped(id:String,operation:Callable)->Variant:
	assert(id=="player" or actors.has(id),"Unknown civilization owner")
	# Already in this owner's scope: nothing to switch or restore.
	if id==actor_id and (id=="player")==_active.is_empty():return operation.call()
	var previous:=_active
	var previous_id:=actor_id
	actor_id=id
	_active={} if id=="player" else actors[id].systems
	_bind_scope()
	var result:Variant=operation.call()
	_active=previous
	actor_id=previous_id
	_bind_scope()
	return result

## The scoped system fields are plain variables rebound on every scope change;
## hot simulation code reads them hundreds of thousands of times per day.
## Each owner's system references are gathered once into an array, in the
## order below; actor instances are only created by create_actor.
func _bind_scope()->void:
	var b:Array
	if _active.is_empty():
		if _player_binding.is_empty():_player_binding=_build_binding({})
		b=_player_binding
		span=1
	else:
		var actor:Dictionary=actors[actor_id]
		if not actor.has("binding"):actor["binding"]=_build_binding(_active)
		b=actor.binding
		span=int(actor.get("span",1))
	state=b[0]
	discovery=b[1]
	progression=b[2]
	resources=b[3]
	economy=b[4]
	settlements=b[5]
	government=b[6]
	figures=b[7]
	direction=b[8]
	communities=b[9]
	diplomacy=b[10]
	dialogue=b[11]
	facts=b[12]
	advisors=b[13]
	food=b[14]
	consequences=b[15]
	civics=b[16]
	world=b[17]
	military=b[18]
	campaign=b[19]
	general_dialogue=b[20]

func _build_binding(active:Dictionary)->Array:
	return [active.get("GameState",GameState),active.get("DiscoverySystem",DiscoverySystem),active.get("ProgressionSystem",ProgressionSystem),active.get("ResourceSystem",ResourceSystem),active.get("EconomySystem",EconomySystem),active.get("SettlementModel",SettlementModel),active.get("GovernmentPeopleSystem",GovernmentPeopleSystem),active.get("HistoricalFigures",HistoricalFigures),active.get("PeopleDirection",PeopleDirection),active.get("CommunityNetwork",CommunityNetwork),active.get("ForeignDiplomacy",ForeignDiplomacy),active.get("ForeignDialogue",ForeignDialogue),active.get("WorldFacts",WorldFacts),active.get("AdvisorSystem",AdvisorSystem),active.get("FoodSystem",FoodSystem),active.get("ConsequenceEngine",ConsequenceEngine),active.get("CivicImplementationSystem",CivicImplementationSystem),active.get("CivilizationSystem",CivilizationSystem),active.get("MilitaryCampaign",MilitaryCampaign),active.get("GeneralCampaign",GeneralCampaign),active.get("GeneralDialogue",GeneralDialogue)]

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
	_views_day=-1
	_day_job=null
	advancing=false

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

func advance_rivals(target_day:int,timings:Dictionary={})->void:
	assert(_day_job==null,"A scheduled world day is still in progress")
	var job:=DayJob.new()
	_plan_rivals(job,target_day,timings)
	job.run_all()

## Rival catch-up, one group per owner per day, in the synchronous order.
func _plan_rivals(job:DayJob,target_day:int,timings:Dictionary)->void:
	if not enabled or advancing or target_day<=last_day:return
	var S=preload("res://scripts/day_job.gd")
	advancing=true
	for day in range(last_day+1,target_day+1):
		job.add_group("player",[S.step("rival_views",timings,func()->Array:
			last_day=day
			# Yesterday's closing views are unchanged unless an order intervened.
			if _views_day==day-1:return []
			return _view_steps(timings,"rival_views")
		)])
		var ids:=actors.keys();ids.sort()
		for id:String in ids:
			var detail:Dictionary={} if timings.is_empty() else timings.get_or_add(id,{"enabled":true,"phases":{"enabled":true},"secondary":{"enabled":true}})
			var run:Dictionary={"day":day}
			job.add_group(id,[S.step("controller_start",detail,func()->Variant:
				if int(actors[id].last_day)>=day:
					run.skip=true;run.halt=true
					return null
				var gap:=maxi(1,day-int(actors[id].last_day))
				if gap<span_limit and _span_waits(id,day):
					run.skip=true;run.halt=true
					return null
				actors[id]["span"]=gap;span=gap
				actors[id]["last_gap"]=gap
				state.elapsed_days=day
				return DayJob.from_parts(preload("res://scripts/civilization_controller.gd").order_steps(id),detail)
			),S.step("context",detail,func()->Array:
				var origin:Vector2=world.player_world_origin
				if state.settlement_site_committed:origin=Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z)
				var daily:=preload("res://scripts/civilization_day.gd").context(origin,state.convoy_traveling)
				var phases:=preload("res://scripts/civilization_day.gd").plan(day,daily,Callable(),detail.get("secondary",{}))
				return preload("res://scripts/civilization_day.gd").steps(phases,detail.get("phases",{}))
			),S.step("world",detail,func()->Array:
				world.initialize()
				return DayJob.from_parts(world.owned_day_steps(day),detail)
			)],run,func()->void:
				if not bool(run.get("skip",false)):actors[id].last_day=day
				actors[id]["span"]=1
				if actor_id==id:span=1
			)
		job.add_group("player",[S.step("rival_projections",timings,func()->Array:return _projection_steps(timings,"rival_projections"))],{},func()->void:
			if day==target_day:advancing=false
		)

## A calm rival waits for its own phase day, covering the gap in one step.
## Monthly reviews keep their exact day. Runs in the rival's scope.
func _span_waits(id:String,day:int)->bool:
	# The id goes last: String.hash multiplies by 33, so a fixed suffix would
	# give every owner the same phase modulo 3.
	if posmod(day+posmod(hash("span:"+id),span_limit),span_limit)==0:return false
	if preload("res://scripts/civilization_controller.gd").review_due(id,day):return false
	return DaySpan.calm()

## Whether a rival is expected to advance on `day`, from the same schedule
## `_span_waits` applies. A rival that stepped daily is assumed to continue.
func _advances_on(id:String,day:int)->bool:
	if span_limit<=1:return true
	var actor:Dictionary=actors[id]
	if int(actor.get("last_gap",1))==1:return true
	if day-int(actor.last_day)>=span_limit:return true
	if posmod(day+posmod(hash("span:"+id),span_limit),span_limit)==0:return true
	return preload("res://scripts/civilization_controller.gd").review_due(id,day)

func refresh_projections()->void:
	for next:Dictionary in _projection_steps():next.call.call()

## Per-owner read-model steps. Each civilization's projection is written whole.
func _projection_steps(timings:Dictionary={},label:String="projections")->Array:
	var S=preload("res://scripts/day_job.gd")
	var result:Array=[]
	if not CivilizationSystem.civilizations.is_empty():
		result.append(S.step(label,timings,func()->void:
			if human_projection.is_empty():
				human_projection=CivilizationSystem.civilizations[0].duplicate(true)
				human_projection.id="human"
				for region in human_projection.strategic_regions:
					region.id="human_"+String(region.id);region.controller="human";region.original_controller="human"
			human_projection.name=GameState.settlement_name
			human_projection.world_position=CivilizationSystem.player_world_origin
			# Contact and route queries read normalized position, not world_position.
			human_projection.position=Vector2(CivilizationSystem.player_world_origin.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,CivilizationSystem.player_world_origin.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
			scoped("player",func()->void:project(human_projection))
		))
	for index in CivilizationSystem.civilizations.size():
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		var id:=String(civ.id)
		if not actors.has(id):continue
		result.append(S.step(label,timings,func()->void:
			if not actors.has(id):return
			# With multi-day rival steps a rival that has not advanced since its
			# last projection would project the same read model again.
			if span_limit>1 and int(actors[id].get("projected_day",-1))==int(actors[id].last_day):return
			actors[id]["projected_day"]=int(actors[id].last_day)
			scoped(id,func()->void:project(civ))
		))
	return result

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
	civ.military_readiness=clampf(float(military.home_army.get("readiness",0)),0.0,1.0)
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
		# Local work snapshots floor each town at one person. The atlas must use
		# unfloored shares or a declining multi-town civ gains phantom residents.
		var record:Dictionary=settlements.settlement_record(String(city.id))
		var share:float=1.0-settlements._committed_satellite_share() if primary else maxf(0.0,float(record.get("population_share",0.0)))
		region.population=maxf(0.0,state.population_exact)*share
		region.population_share=share
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
	for next:Dictionary in _view_steps():next.call.call()

## Relations first, then one private foreign view per observer, then the human's.
## With `next_day`, a rival's private view is refreshed only if that rival is
## expected to advance on `next_day` (see day_span.gd); the others keep their
## view until the evening before their next step.
func _view_steps(timings:Dictionary={},label:String="views",next_day:int=-1)->Array:
	var S=preload("res://scripts/day_job.gd")
	var shared:Dictionary={}
	var result:Array=[S.step(label,timings,func()->void:
		preload("res://scripts/civilization_relations.gd").synchronize()
		shared.troops=preload("res://scripts/civilization_combat.gd").troop_catalog()
	)]
	for id:String in actors:
		result.append(S.step(label,timings,func()->void:
			if actors.has(id) and (next_day<0 or _advances_on(id,next_day)):_refresh_observer_view(id,shared.troops)
		))
	result.append(S.step(label,timings,func()->void:
		CivilizationSystem.foreign_formations.assign(preload("res://scripts/civilization_combat.gd").troop_views("player",shared.troops))
	))
	return result

func _refresh_observer_view(id:String,troops:Variant)->void:
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
	_views_day=-1
	return scoped(id,func()->Dictionary:
		var result:=preload("res://scripts/civilization_orders.gd").execute(order)
		if id!="player":
			actors[id].sequence+=1
			actors[id].orders.append({"sequence":actors[id].sequence,"day":int(state.elapsed_days),"order":order.duplicate(true),"result":result.duplicate(true)})
			if actors[id].orders.size()>32:actors[id].orders.pop_front()
		return result
	)

const SNAPSHOT=preload("res://scripts/save_system.gd")
## Saved fields of systems that no longer exist; older saves may still hold
## them. Their contents are folded in elsewhere (see civilian_goods.gd).
const RETIRED_FIELDS:={"GameState":["opening_craft_practice"],"FoodSystem":["_forecast_climate_cache","_environment_cache_key","_environment_cache"]}
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
	var result:={"version":1,"enabled":enabled,"seed":_seed,"last_day":last_day,"actors":{},"geography_stock":geography_stock.duplicate(true),"relation_baselines":relation_baselines.duplicate(true),"human_projection":human_projection.duplicate(true)}
	for id:String in actors:
		result.actors[id]={"controller":actors[id].controller,"last_day":actors[id].last_day,"origin":actors[id].origin,"sequence":actors[id].sequence,"orders":actors[id].orders.duplicate(true),"state":capture_actor(id)}
	return result

func validate_payload(payload:Dictionary)->String:
	if payload.is_empty():return ""
	if int(payload.get("version",0))!=1:return "Unsupported civilization simulation version."
	if not payload.get("actors") is Dictionary:return "Invalid civilization ownership register."
	if payload.actors.size()>CivilizationSystem.MAX_RIVAL_CIVILIZATIONS:return "Too many civilization owners."
	if not payload.get("geography_stock",{}) is Dictionary:return "Invalid shared world reserves."
	if not payload.get("human_projection",{}) is Dictionary:return "Invalid human civilization projection."
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
				if field in RETIRED_FIELDS.get(name,[]):continue
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
		var opening=preload("res://scripts/civilian_goods.gd")
		if not opening.valid(actor.state.GameState.get("civilian_goods",opening.empty_state())) or not opening.valid_settlements(actor.state.GameState.get("player_settlements",[])):return "Invalid civilization civilian goods records."
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
			if not (amount is float or amount is int) or not is_finite(float(amount)) or float(amount)<-0.000000001:return "Invalid civilization stock balance."
	return ""

func _restore_state(payload:Dictionary)->Dictionary:
	var error:=validate_payload(payload)
	if error!="":return {"error":error}
	if payload.is_empty():return {"ok":true,"legacy":true}
	clear()
	_seed=int(payload.seed);last_day=int(payload.last_day)
	geography_stock=payload.get("geography_stock",{}).duplicate(true)
	relation_baselines=payload.get("relation_baselines",{}).duplicate(true)
	human_projection=payload.get("human_projection",{}).duplicate(true)
	var failures:Array[String]=[]
	for id:String in payload.actors:
		var saved:Dictionary=payload.actors[id]
		create_actor(id,_seed,saved.origin)
		for key in ["controller","last_day","sequence"]:actors[id][key]=saved[key]
		# New orders must not mutate the caller's reusable save snapshot.
		actors[id].orders=saved.orders.duplicate(true)
		scoped(id,func()->void:
			for name in OWNED_SYSTEMS:
				var instance:=system(name)
				var fields:Dictionary=saved.state[name].duplicate(true)
				if name=="GameState":
					# Older fuel withdrawals can leave sub-nanounit floating residue.
					# Validation above still rejects actual overdrafts and nonfinite stock.
					for item:String in fields.resource_stockpiles:
						if float(fields.resource_stockpiles[item])<0:fields.resource_stockpiles[item]=0.0
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
	# Older saves omitted the human observer view. Rebuild it before rivals act.
	if enabled and not payload.has("human_projection"):refresh_projections()
	return {"ok":true}

## Synchronous day: the same scheduled steps, run to completion. A day already
## in progress is finished first so days always commit in calendar order.
func advance_day(day:int,daily_context:Dictionary,construction:Callable=Callable(),timings:Dictionary={})->Dictionary:
	flush_day()
	begin_day(day,daily_context,construction,Callable(),timings)
	var job:=_day_job
	flush_day()
	return job.result

## Queues one world day: rival catch-up, the human owner's phases, then the
## shared read models, contact and exchange. Nothing is applied out of order;
## `on_complete(result)` runs in the human scope when the last step finishes.
func begin_day(day:int,daily_context:Dictionary,construction:Callable=Callable(),on_complete:Callable=Callable(),timings:Dictionary={})->void:
	assert(_day_job==null,"A scheduled world day is still in progress")
	var S=DayJob
	var job:=DayJob.new()
	_plan_rivals(job,day,timings)
	var phases:Dictionary={} if timings.is_empty() else timings.get_or_add("player_phases",{"enabled":true})
	var clock=preload("res://scripts/civilization_day.gd")
	var run:=clock.plan(day,daily_context,construction)
	job.add_group("player",clock.steps(run,phases),run)
	job.add_group("player",[
		S.step("player_world",timings,func()->Array:
			CivilizationSystem.initialize()
			if not enabled:
				CivilizationSystem.advance_to_day(day)
				return []
			return DayJob.from_parts(CivilizationSystem.owned_day_steps(day),timings)
	),
		S.step("projections",timings,func()->Array:return _projection_steps(timings,"projections")),
		S.step("views",timings,func()->Array:
			var steps:=_view_steps(timings,"views",day+1)
			steps.append(S.step("views",timings,func()->void:_views_day=day))
			return steps
	),
		S.step("joint_contact",timings,func()->void:preload("res://scripts/civilization_joint_contact.gd").advance(day)),
		S.step("exchange",timings,func()->void:
			preload("res://scripts/civilization_exchange.gd").settle(day)
			preload("res://scripts/civilization_exchange.gd").occupation(day)
	),
	],{},func()->void:
		job.result=run.result
		if _day_job==job:_day_job=null
		if on_complete.is_valid():on_complete.call(run.result)
	)
	_day_job=job
	_day_number=day

func day_in_progress()->bool:
	return _day_job!=null

func day_in_progress_number()->int:
	return _day_number if _day_job!=null else -1

## Runs scheduled steps for about `budget_usec` (always at least one step).
## Returns true when no day remains in progress.
func pump_day(budget_usec:int)->bool:
	if _day_job==null:return true
	var job:=_day_job
	job.run_for(budget_usec)
	return _day_job==null

## Finishes the day in progress before saves, loads and synchronous callers.
func flush_day()->void:
	while _day_job!=null:
		var job:=_day_job
		job.run_all()
		if _day_job==job:_day_job=null

func day_job_stats()->Dictionary:
	if _day_job==null:return {}
	return {"day":_day_number,"steps_run":_day_job.steps_run,"longest_step_usec":_day_job.longest_step_usec,"groups_left":_day_job.groups.size()}

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
	_views_day=-1
	var previous:={"actors":actors,"human":human_projection,"enabled":enabled,"seed":_seed,"day":last_day,"geography":geography_stock,"relations":relation_baselines,"markets":market_orders,"job":_day_job,"advancing":advancing}
	actors={};human_projection={};geography_stock={};relation_baselines={};market_orders={};enabled=false
	var result:=_restore_state(payload)
	if validate_only or result.has("error"):
		clear()
		actors=previous.actors;human_projection=previous.human;geography_stock=previous.geography;relation_baselines=previous.relations;market_orders=previous.markets
		enabled=previous.enabled;_seed=previous.seed;last_day=previous.day
		# Validating another save must not cancel the current world's day.
		_day_job=previous.job;advancing=previous.advancing
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
