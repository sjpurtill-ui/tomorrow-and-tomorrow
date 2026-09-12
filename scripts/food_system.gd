extends Node

# Match the supported settlement count: a 16-site cache thrashed once a
# civilization reached 17 cities. Only deterministic climate is retained.
const FORECAST_SITE_LIMIT:=256
var _forecast_climate_cache:Dictionary={}

# Food is measured internally in adult-equivalent daily rations. One ration is
# displayed as roughly 2,400 kcal. Demand is calculated from numeric age,
# labor, pregnancy, lactation, travel, military, and climate cohorts.

const Operations=preload("res://scripts/technology_operations.gd")
const KCAL_PER_RATION := 2400.0
const BASE_SUBSISTENCE_YIELD_CALIBRATION:=1.34
const FOOD_TYPES := ["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]
const FOOD_ISSUE_HISTORY_LIMIT:=96
const SPOILAGE := {
	"Fresh plants":0.022,
	"Fresh meat":0.045,
	"Fish":0.060,
	"Dry staples":0.0012,
	"Preserved food":0.00035
}

var initialized := false
var _environment_cache_key:=""
var _environment_cache:Dictionary={}

func reset_for_new_world()->void:
	_forecast_climate_cache.clear()
	initialized=false
	_environment_cache_key=""
	_environment_cache={}

func initialize() -> void:
	if initialized and not WorldSimulation.state.food_stocks.is_empty():
		return
	if WorldSimulation.state.founding_manifest.is_empty(): WorldSimulation.resources.initialize()
	initialized=true
	if WorldSimulation.state.food_stocks.is_empty():
		var existing:=float(WorldSimulation.state.resource_stockpiles.get("Food",WorldSimulation.state.population_exact*30.0))
		WorldSimulation.state.food_stocks={
			"Fresh plants":existing*0.01,
			"Fresh meat":existing*0.01,
			"Fish":0.0,
			"Dry staples":existing*0.58,
			"Preserved food":existing*0.40
		}
	_sync_total()

func process_day(context: Dictionary,labor_efficiency: float,ecology: float) -> Dictionary:
	return WorldSimulation.settlements.with_local_population(func()->Dictionary: return _process_local_day(context,labor_efficiency,ecology))

func _process_local_day(context: Dictionary,labor_efficiency: float,ecology: float) -> Dictionary:
	initialize()
	var traveling:=bool(context.get("traveling",WorldSimulation.state.convoy_traveling))
	var workers:=WorldSimulation.state.effective_workers("Food")
	var logistics:=WorldSimulation.state.effective_workers("Logistics")
	var makers:=WorldSimulation.state.effective_workers("Crafting")
	var military_campaign:Node=WorldSimulation.system("MilitaryCampaign") if WorldSimulation.state.resource_settlement_id=="" else null
	if military_campaign!=null and military_campaign.has_method("civilian_crafting_fraction"):
		makers*=clampf(float(military_campaign.civilian_crafting_fraction()),0.0,1.0)
	var demand_breakdown:=_calculate_demand(traveling)
	var nutrient_report:Dictionary={}
	var harvest:=_produce(workers,labor_efficiency,ecology,traveling,true,nutrient_report)
	if WorldSimulation.state.resource_settlement_id.is_empty() and not traveling:
		var access:=WorldSimulation.military.siege_home_food_access()
		for food_type in harvest: harvest[food_type]*=access
		for key:String in ["base_harvest","bonus","harvest"]:
			if nutrient_report.has(key):nutrient_report[key]=float(nutrient_report[key])*access
	for food_type in harvest:
		WorldSimulation.state.food_stocks[food_type]=float(WorldSimulation.state.food_stocks.get(food_type,0.0))+float(harvest[food_type])
	var preserved:=_preserve(logistics,makers,traveling)
	var canned:Dictionary=preload("res://scripts/canning_preservation.gd").preserve(float(demand_breakdown.total),traveling)
	for food_type:String in canned:preserved[food_type]=float(preserved.get(food_type,0.0))+float(canned[food_type])
	var spoilage:=_spoil(traveling)
	var demand:=float(demand_breakdown.total)
	var army_original:=float(demand_breakdown.get("army_field",0.0))
	var credited:Dictionary=military_campaign.draw_delivered_field_rations(army_original) if military_campaign!=null else {"total":0.0,"by_army":{}}
	demand=maxf(0,demand-float(credited.total))
	var army_required:=maxf(0,army_original-float(credited.total))
	var provision_delivery_ratio:=1.0
	if military_campaign!=null and military_campaign.has_method("field_provision_delivery_ratio"):
		provision_delivery_ratio=clampf(float(military_campaign.field_provision_delivery_ratio()),0.0,1.0)
	var army_accessible:=army_required*provision_delivery_ratio
	var accessible_demand:=maxf(0.0,demand-army_required+army_accessible)
	var consumed:=_consume(accessible_demand)
	# People can eat today's harvest before excess stock is discarded for lack of
	# storage. Capacity constrains what survives the day, not what can be consumed.
	var storage_loss:=_apply_storage_capacity()
	for food_type in storage_loss:
		spoilage[food_type]=float(spoilage.get(food_type,0.0))+float(storage_loss[food_type])
	var eaten:=0.0
	for amount in consumed.values(): eaten+=float(amount)
	var intake_ratio:=clampf(eaten/maxf(0.01,demand),0.0,1.0)
	var accessible_intake:=clampf(eaten/maxf(0.01,accessible_demand),0.0,1.0)
	var army_delivered:=army_accessible*accessible_intake
	if military_campaign!=null and military_campaign.has_method("record_daily_provisions"):
		military_campaign.record_daily_provisions(army_original,army_delivered,credited)
	var diet_quality:=_diet_quality(consumed,eaten)
	_update_nutrition(intake_ratio,diet_quality)
	_update_source_health(harvest,workers,traveling)
	var total:=_stock_total()
	var spoilage_total:=0.0
	for amount in spoilage.values(): spoilage_total+=float(amount)
	var production_total:=0.0
	for amount in harvest.values(): production_total+=float(amount)
	var net:=production_total-eaten-spoilage_total
	var effective_daily_loss:=maxf(0.01,demand-production_total+spoilage_total)
	var projected_days:=9999.0 if net>=0.0 else total/effective_daily_loss
	var food_days:=total/maxf(0.01,demand)
	var sources:=_source_report(harvest,workers,traveling)
	var milestones:Dictionary={}
	var forecast_90:=_forecast(90,harvest,demand_breakdown,traveling,provision_delivery_ratio,milestones,nutrient_report)
	var forecast_30:Dictionary=milestones[30]
	var weather_factor:=_weather_yield_factor(_environment_mix(),WorldSimulation.state.elapsed_days)
	var result:={
		"cultivation_base_harvest":float(nutrient_report.get("base_harvest",0)),
		"cultivation_nutrient_inputs":nutrient_report.get("inputs",{}).duplicate(),
		"cultivation_nutrient_bonus":float(nutrient_report.get("bonus",0)),
		"food_days":food_days,
		"food_production":production_total,
		"food_consumption":demand,
		"food_eaten":eaten,
		"food_shortfall":maxf(0.0,demand-eaten),
		"food_intake_ratio":intake_ratio,
		"food_balance":production_total/maxf(0.01,demand)-1.0,
		"food_net":net,
		"food_spoilage":spoilage_total,
		"food_projected_days":projected_days,
		"food_forecast_30":forecast_30,
		"food_forecast_90":forecast_90,
		"food_diet_quality":diet_quality,
		"food_weather_factor":weather_factor,
		"nutrition_reserve":WorldSimulation.state.nutrition_reserve,
		"malnutrition_burden":WorldSimulation.state.malnutrition_burden,
		"food_stocks":WorldSimulation.state.food_stocks.duplicate(true),
		"food_harvest":harvest,
		"food_consumed_by_type":consumed,
		"food_spoilage_by_type":spoilage,
		"food_preserved":preserved,
		"food_demand_breakdown":demand_breakdown,
		"army_provisions_required":army_required,
		"army_provisions_delivered":army_delivered,
		"army_provision_delivery_ratio":provision_delivery_ratio,
		"food_sources":sources,
		"food_kcal_required":demand*KCAL_PER_RATION,
		"food_kcal_eaten":eaten*KCAL_PER_RATION
	}
	WorldSimulation.state.food_history.append({
		"day":int(WorldSimulation.state.elapsed_days),"stored":total,"produced":production_total,
		"required":demand,"eaten":eaten,"spoiled":spoilage_total,"net":net,
		"diet_quality":diet_quality,"intake_ratio":intake_ratio
	})
	if WorldSimulation.state.food_history.size()>370: WorldSimulation.state.food_history.pop_front()
	_sync_total()
	return result

func _calculate_demand(traveling: bool) -> Dictionary:
	return _calculate_aggregate_demand(traveling)

func _calculate_aggregate_demand(traveling: bool) -> Dictionary:
	var total:=maxf(1.0,WorldSimulation.state.population_exact)
	var children:=float(WorldSimulation.state.population_cohorts.get("children",roundi(total*0.32)))
	var elders:=float(WorldSimulation.state.population_cohorts.get("elders",roundi(total*0.08)))
	var adults:=maxf(0.0,total-children-elders)
	# Mission parties (scouts, envoys, convoys) took their full travel rations
	# at departure; while away they are not mouths at the home fires. Without
	# this the settlement pays for them twice.
	var civilization_system:=WorldSimulation.system("CivilizationSystem")
	var away_adults:=0.0
	if WorldSimulation.state.resource_settlement_id=="" and civilization_system!=null and civilization_system.has_method("mission_absent_personnel"):
		away_adults=maxf(0.0,float(civilization_system.mission_absent_personnel()))
	if WorldSimulation.state.resource_settlement_id=="":
		# Escaped groups already leave the local settlement count; preparation is
		# still local, but uses its reserved food, including family members.
		var recovery=WorldSimulation.military.recovery
		if not recovery.data.remnant.is_empty():away_adults=maxf(0,away_adults-int(recovery.data.remnant.people))
		if not recovery.data.preparation.is_empty():
			var prepared:Dictionary=recovery.data.preparation
			var young:=float(prepared.cohorts.get("children",0));var old:=float(prepared.cohorts.get("elders",0))
			away_adults=maxf(0,away_adults-young-old)
			children=maxf(0,children-young);elders=maxf(0,elders-old)
	if WorldSimulation.state.resource_settlement_id=="" and WorldSimulation.campaign.active:away_adults+=int(WorldSimulation.campaign.army().get("troops",0))
	away_adults=clampf(away_adults,0.0,adults)
	adults-=away_adults
	# Children are a full 0–13 cohort, including infancy; its weighted average
	# is lower than the need of an older child. These are adult-equivalent rations.
	var children_base:=children*0.60
	var adult_base:=adults
	var elder_base:=elders*0.86
	var base:=children_base+adult_base+elder_base
	var labor:=0.0
	var extras:={"Food":0.17,"Extraction":0.18,"Construction":0.18,"Defense":0.12,"Survey":0.13,"Logistics":0.14,"Crafting":0.08,"Knowledge":0.04,"Administration":0.04}
	for role in GameState.POPULATION_ROLES:
		labor+=float(WorldSimulation.state.population_allocations.get(role,0))*float(extras.get(role,0.02))
	# Role allocations still count mission-absent people; their exertion ration
	# travels with them, so scale the home labor surcharge down proportionally.
	labor*=1.0-clampf(away_adults/maxf(1.0,float(WorldSimulation.state.able_population())),0.0,0.45)
	var pregnancy:=float(WorldSimulation.state.estimated_active_pregnancies())*0.12
	var lactation:=total*0.012*0.21
	var environment:=_environment_mix()
	var season_wave:=PlanetEnvironment.season_wave(environment,WorldSimulation.state.elapsed_days)
	var ambient_temperature:=PlanetEnvironment.ambient_temperature_c(environment,WorldSimulation.state.elapsed_days)
	var cold_load:=clampf((12.0-ambient_temperature)/28.0,0.0,1.0)
	var heat_load:=clampf((ambient_temperature-31.0)/17.0,0.0,1.0)
	var climate:=base*(cold_load*0.075+heat_load*0.045)
	var travel:=base*0.12 if traveling else 0.0
	var prisoners:=0.0
	var army_field:=0.0
	var occupation_relief:=0.0
	var military_campaign:Node=WorldSimulation.system("MilitaryCampaign") if WorldSimulation.state.resource_settlement_id=="" else null
	if military_campaign!=null:
		if military_campaign.has_method("prisoner_food_demand"): prisoners=maxf(0.0,float(military_campaign.prisoner_food_demand()))
		var field_personnel:=maxi(0,int(military_campaign.home_army.get("troops",0)))
		if military_campaign.has_method("field_army_active_personnel"): field_personnel+=maxi(0,int(military_campaign.field_army_active_personnel()))
		if military_campaign.has_method("occupation_active_personnel"): field_personnel+=maxi(0,int(military_campaign.occupation_active_personnel()))
		if WorldSimulation.campaign.active:field_personnel=maxi(0,field_personnel-int(WorldSimulation.campaign.army().get("troops",0)))
		army_field=float(field_personnel)*(1.12+(0.12 if traveling else 0.0)+maxf(0.0,-season_wave)*0.06)
	if not WorldSimulation.enabled and WorldSimulation.state.resource_settlement_id=="" and civilization_system!=null and civilization_system.has_method("player_effects"):
		occupation_relief=maxf(0.0,float(civilization_system.player_effects().get("occupation_relief_demand",0.0)))
	var ration_factor:=1.0+_policy_effect("food_demand")
	var pre_ration:=base+labor+pregnancy+lactation+travel+climate+prisoners
	return {"base":base,"children":children_base,"adults":adult_base,"elders":elder_base,"mission_absent":away_adults,"labor":labor,"pregnancy":pregnancy,"lactation":lactation,"travel":travel,"climate":climate,"prisoner_custody":prisoners,"army_field":minf(pre_ration,army_field*ration_factor),"occupation_relief":occupation_relief,"rationing":pre_ration*(1.0-ration_factor),"total":pre_ration*ration_factor+occupation_relief}

func _age_need(age: float) -> float:
	if age<0.5: return 0.08 # represented mostly through lactation demand
	if age<3.0: return 0.42
	if age<6.0: return 0.55
	if age<10.0: return 0.70
	if age<14.0: return 0.84
	if age<18.0: return 0.95
	if age<60.0: return 1.00
	if age<75.0: return 0.88
	return 0.78

func _produce(workers: float,labor_efficiency: float,ecology: float,traveling: bool,commit_nutrients:bool=false,nutrient_report:Dictionary={}) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
	var occupation_transfer:=0.0
	var civilization_system:=WorldSimulation.system("CivilizationSystem")
	if not WorldSimulation.enabled and WorldSimulation.state.resource_settlement_id=="" and civilization_system!=null and civilization_system.has_method("player_effects") and not traveling:
		occupation_transfer=maxf(0.0,float(civilization_system.player_effects().get("occupation_food_transfer",0.0)))
	if workers<=0.0:
		result["Dry staples"]=occupation_transfer
		return result
	var access:=_food_resource_access()
	var coastal:=_coastal_food_profile(traveling)
	var environment:=_environment_mix()
	var weather_factor:=_weather_yield_factor(environment,WorldSimulation.state.elapsed_days)
	var environmental_water:=clampf(float(environment.get("water_access",0.0)),0.0,1.0)
	var coastal_fishing_weight:=float(coastal.shoreline_access)*0.07+float(coastal.marine_opportunity)*0.05
	var fishing_weight:=maxf(0.16*maxf(float(access.freshwater),environmental_water),coastal_fishing_weight)
	var cultivation_weight:=0.0
	if "seed_selection" in WorldSimulation.state.known_discoveries and WorldSimulation.state.settlement_site_committed:
		cultivation_weight=(0.22+float(environment.get("fertility",0.0))*0.20+float(access.fertile)*0.08)*maxf(0.05,WorldSimulation.discovery.adoption("seed_selection"))
	var remaining:=maxf(0.0,1.0-fishing_weight-cultivation_weight)
	var hunting_weight:=remaining*(0.31+float(access.game)*0.09)
	var gathering_weight:=maxf(0.0,remaining-hunting_weight)
	var plant_season:=_season_factor("Fresh plants",WorldSimulation.state.elapsed_days)
	var game_season:=_season_factor("Fresh meat",WorldSimulation.state.elapsed_days)
	var fish_season:=_season_factor("Fish",WorldSimulation.state.elapsed_days)
	var crop_season:=_season_factor("Dry staples",WorldSimulation.state.elapsed_days)
	var terrain_gather:=lerpf(0.54,1.34,clampf(float(environment.get("forage",0.45)),0.0,1.0))
	var terrain_hunt:=lerpf(0.52,1.38,clampf(float(environment.get("game",0.40)),0.0,1.0))
	var efficiency:=lerpf(0.76,1.08,clampf(labor_efficiency,0.0,1.0))
	var ecological:=lerpf(0.58,1.04,clampf(ecology,0.0,1.0))
	var practice:=1.0
	practice+=WorldSimulation.discovery.effect("foraging_yield")
	practice+=WorldSimulation.discovery.effect("food_output")
	practice+=WorldSimulation.state.founding_effect("food_yield")+WorldSimulation.progression.effect("food_output")
	practice+=_modifier_strength("abundant_game")-_modifier_strength("lean_harvest")
	practice+=_policy_effect("food_yield")
	var rng:=RandomNumberGenerator.new()
	rng.seed=WorldSimulation.state.world_seed^int(WorldSimulation.state.elapsed_days+1.0)*7919
	var variation:=rng.randf_range(0.93,1.07)
	var route_factor:=0.48+clampf(WorldSimulation.state.effective_workers("Logistics")/maxf(1.0,WorldSimulation.state.population_exact*0.08),0.0,1.0)*0.08 if traveling else 1.0
	result["Fresh plants"]=workers*gathering_weight*4.55*BASE_SUBSISTENCE_YIELD_CALIBRATION*terrain_gather*plant_season*efficiency*ecological*float(WorldSimulation.state.food_source_health.get("Wild gathering",0.9))*practice*variation*route_factor*(1.0+float(coastal.foraging_bonus))*_food_type_weather_multiplier("Fresh plants",weather_factor)
	result["Fresh meat"]=workers*hunting_weight*4.85*BASE_SUBSISTENCE_YIELD_CALIBRATION*terrain_hunt*game_season*efficiency*ecological*float(WorldSimulation.state.food_source_health.get("Hunting",0.9))*(1.0+float(access.game)*0.18)*(1.0+WorldSimulation.discovery.effect("hunting_yield"))*practice*variation*route_factor*_food_type_weather_multiplier("Fresh meat",weather_factor)
	var fishing_access:=maxf(float(access.freshwater),float(coastal.marine_opportunity)*0.90)
	result["Fish"]=workers*fishing_weight*5.00*BASE_SUBSISTENCE_YIELD_CALIBRATION*fish_season*efficiency*float(WorldSimulation.state.food_source_health.get("Fishing",0.9))*(0.76+fishing_access*0.34)*practice*variation*route_factor*(1.0+float(coastal.food_output_bonus))*_food_type_weather_multiplier("Fish",weather_factor)
	if cultivation_weight>0.0 and not traveling:
		var agronomy:Dictionary=preload("res://scripts/agronomy_knowledge.gd").factors(traveling)
		result["Dry staples"]=workers*cultivation_weight*5.65*crop_season*efficiency*float(WorldSimulation.state.food_source_health.get("Cultivation",0.9))*(0.68+float(environment.get("fertility",0.0))*0.38+float(access.fertile)*0.12)*(1.0+WorldSimulation.discovery.effect("soil_productivity")+WorldSimulation.discovery.effect("cultivation_yield"))*variation*float(agronomy["yield"])*preload("res://scripts/agronomy_knowledge.gd").weather_factor(_food_type_weather_multiplier("Dry staples",weather_factor),agronomy)
		if "nutrient_response_trials" in WorldSimulation.state.known_discoveries:
			var nutrition:=preload("res://scripts/crop_nutrition.gd").cultivation(float(result["Dry staples"]),commit_nutrients)
			nutrient_report.merge(nutrition,true)
			result["Dry staples"]=float(nutrition.harvest)
	result["Dry staples"]+=occupation_transfer
	return result


func _coastal_food_profile(traveling:bool)->Dictionary:
	var empty:={"shoreline_access":0.0,"marine_opportunity":0.0,"food_output_bonus":0.0,"foraging_bonus":0.0}
	if traveling or not WorldSimulation.state.settlement_site_committed: return empty
	for settlement_variant in WorldSimulation.state.player_settlements:
		var settlement:Dictionary=settlement_variant
		if (String(settlement.get("id",""))==WorldSimulation.state.resource_settlement_id if WorldSimulation.state.resource_settlement_id!="" else bool(settlement.get("primary",false))):
			return WorldSimulation.settlements.coastal_site_profile(settlement)
	return empty


func _environment_mix()->Dictionary:
	for settlement in WorldSimulation.state.player_settlements:
		var local_match:=String(settlement.get("id",""))==WorldSimulation.state.resource_settlement_id if WorldSimulation.state.resource_settlement_id!="" else bool(settlement.get("primary",false))
		if not local_match: continue
		var profile:Dictionary=settlement.get("environment_profile",{})
		return profile if not profile.is_empty() else PlanetEnvironment.profile_at(WorldSimulation.settlements._record_position(settlement))
	return PlanetEnvironment.profile_at(Vector2(WorldSimulation.state.settlement_founded_at.x,WorldSimulation.state.settlement_founded_at.z))


func current_environment_profile()->Dictionary:
	return _environment_mix().duplicate(true)

func _food_resource_access() -> Dictionary:
	var result:={"game":0.0,"freshwater":0.0,"fertile":0.0}
	# Authored hydrology is authoritative. A settlement with direct access to a
	# visible river must not lose fishing/water effects because no point-deposit
	# record happened to be scattered beside it.
	if bool(WorldSimulation.state.water_metrics.get("source_accessible",false)):
		result.freshwater=1.0
	for deposit in WorldSimulation.state.resource_deposits:
		if String(deposit.get("stage","unknown")) not in ["accessible","developed"]: continue
		var key:=String(deposit.get("resource","")).to_lower()
		if key=="game": result.game=maxf(float(result.game),float(deposit.get("quality",0.7)))
		elif key=="freshwater": result.freshwater=maxf(float(result.freshwater),float(deposit.get("quality",0.7)))
		elif key=="fertile soil": result.fertile=maxf(float(result.fertile),float(deposit.get("quality",0.7)))
	return result

func _preserve(logistics: float,makers: float,traveling: bool) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0}
	if traveling: return result
	var capacity:=(logistics*0.16+makers*0.18)*(1.0+WorldSimulation.discovery.effect("food_storage"))
	if "food_drying" in WorldSimulation.state.known_discoveries:
		var plant_amount:=minf(float(WorldSimulation.state.food_stocks.get("Fresh plants",0.0)),capacity*0.55*maxf(0.05,WorldSimulation.discovery.adoption("food_drying")))
		WorldSimulation.state.food_stocks["Fresh plants"]-=plant_amount
		WorldSimulation.state.food_stocks["Dry staples"]+=plant_amount*0.88
		result["Fresh plants"]=plant_amount
		capacity=maxf(0.0,capacity-plant_amount)
	if "smoking" in WorldSimulation.state.known_discoveries and capacity>0.0:
		for food_type in ["Fresh meat","Fish"]:
			var amount:=minf(float(WorldSimulation.state.food_stocks.get(food_type,0.0)),capacity*0.5*maxf(0.05,WorldSimulation.discovery.adoption("smoking")))
			WorldSimulation.state.food_stocks[food_type]-=amount
			WorldSimulation.state.food_stocks["Preserved food"]+=amount*0.82
			result[food_type]=amount
	return result

func _spoil(traveling: bool) -> Dictionary:
	var result:={}
	var storage_multiplier:=0.72 if "Storage Pits" in WorldSimulation.state.settlement_completed else 1.0
	storage_multiplier*=maxf(0.30,1.0+WorldSimulation.discovery.effect("food_spoilage"))
	if traveling: storage_multiplier*=1.28
	var cooling:=Operations.refrigeration_multiplier(Operations.service("cold_storage") if not traveling else 0.0,WorldSimulation.state.food_stocks)
	for food_type in FOOD_TYPES:
		var amount:=float(WorldSimulation.state.food_stocks.get(food_type,0.0))
		var loss:=amount*float(SPOILAGE[food_type])*storage_multiplier*WorldSimulation.discovery.food_storage_multiplier(food_type,traveling)*(cooling if food_type in ["Fresh plants","Fresh meat","Fish"] else 1.0)
		WorldSimulation.state.food_stocks[food_type]=maxf(0.0,amount-loss)
		result[food_type]=loss
	return result

func _apply_storage_capacity() -> Dictionary:
	var losses:={}
	var capacity:=float(WorldSimulation.state.founding_manifest.get("food_storage_rations",0.0))
	if "Storage Pits" in WorldSimulation.state.settlement_completed: capacity+=WorldSimulation.state.population_exact*84.0
	var excess:=maxf(0.0,_stock_total()-capacity)
	for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]:
		if excess<=0.0: break
		var discard:=minf(excess,float(WorldSimulation.state.food_stocks.get(food_type,0.0)))
		WorldSimulation.state.food_stocks[food_type]-=discard
		losses[food_type]=discard
		excess-=discard
	return losses

func _consume(required: float) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
	var remaining:=required
	# Perishables are used first. A small preserved share is deliberately opened
	# each day so a stocked convoy does not report a nutritionally empty diet.
	for food_type in ["Fish","Fresh meat","Fresh plants","Dry staples","Preserved food"]:
		var available:=float(WorldSimulation.state.food_stocks.get(food_type,0.0))
		var amount:=minf(remaining,available)
		WorldSimulation.state.food_stocks[food_type]=available-amount
		result[food_type]=amount
		remaining-=amount
		if remaining<=0.001: break
	return result

func _diet_quality(consumed: Dictionary,total: float) -> float:
	if total<=0.001: return 0.0
	var plant_share:=(float(consumed.get("Fresh plants",0.0))+float(consumed.get("Dry staples",0.0)))/total
	var protein_share:=(float(consumed.get("Fresh meat",0.0))+float(consumed.get("Fish",0.0))+float(consumed.get("Preserved food",0.0))*0.45)/total
	var categories:=0
	for amount in consumed.values():
		if float(amount)>total*0.03: categories+=1
	var diversity:=clampf(float(categories)/4.0,0.0,1.0)
	return clampf(0.24+minf(plant_share,0.48)*0.65+minf(protein_share,0.30)*0.95+diversity*0.22+WorldSimulation.discovery.effect("nutrition_quality"),0.05,1.0)

func _update_nutrition(intake_ratio: float,diet_quality: float) -> void:
	var reserve_delta:=(intake_ratio-0.94)*0.010+(diet_quality-0.55)*0.0018
	WorldSimulation.state.nutrition_reserve=clampf(WorldSimulation.state.nutrition_reserve+reserve_delta,0.0,1.0)
	var burden_target:=clampf((1.0-intake_ratio)*0.68+(0.58-diet_quality)*0.24+(0.28-WorldSimulation.state.nutrition_reserve)*0.45,0.0,1.0)
	WorldSimulation.state.malnutrition_burden=lerpf(WorldSimulation.state.malnutrition_burden,burden_target,0.045 if burden_target>WorldSimulation.state.malnutrition_burden else 0.012)

func _update_source_health(harvest: Dictionary,workers: float,traveling: bool) -> void:
	var able:=maxf(1.0,float(WorldSimulation.state.able_population()))
	var pressure:=workers/able
	var recovery:=(0.0007 if traveling else 0.00035)*(1.0+WorldSimulation.discovery.effect("ecology_recovery"))
	var mapping:={"Wild gathering":"Fresh plants","Hunting":"Fresh meat","Fishing":"Fish","Cultivation":"Dry staples"}
	for source in mapping:
		var current:=float(WorldSimulation.state.food_source_health.get(source,0.9))
		var used:=float(harvest.get(mapping[source],0.0))>0.01
		var damage:=maxf(0.0,pressure-0.42)*0.0018*(1.0+WorldSimulation.discovery.effect("ecological_pressure")) if used else 0.0
		if source=="Cultivation" and used: damage=maxf(0.0,pressure-0.55)*0.0011*float(preload("res://scripts/agronomy_knowledge.gd").factors(traveling).soil_damage)
		WorldSimulation.state.food_source_health[source]=clampf(current+recovery-damage,0.12,1.0)

func _source_report(harvest: Dictionary,workers: float,traveling: bool) -> Array[Dictionary]:
	var access:=_food_resource_access()
	var reports:Array[Dictionary]=[]
	for entry in [
		["Wild gathering","Fresh plants","Ambient land","available"],
		["Hunting","Fresh meat","Game deposit","retrievable game grounds" if float(access.game)>0.0 else "ambient wildlife only"],
		["Fishing","Fish","Fresh water","retrievable" if float(access.freshwater)>0.0 else "unconfirmed or inaccessible"],
		["Cultivation","Dry staples","Fertile soil","retrievable" if float(access.fertile)>0.0 else "unconfirmed or inaccessible"]
	]:
		var amount:=float(harvest.get(entry[1],0.0))
		var status:=String(entry[3])
		if entry[0]=="Cultivation" and "seed_selection" not in WorldSimulation.state.known_discoveries: status="practice not discovered"
		reports.append({"name":entry[0],"food_type":entry[1],"produced":amount,"resource":entry[2],"access":status,"source_health":float(WorldSimulation.state.food_source_health.get(entry[0],0.9)),"travel_limited":traveling})
	return reports

func _forecast(horizon: int,current_harvest: Dictionary,demand_breakdown: Dictionary,traveling: bool,provision_delivery_ratio:=1.0,milestones:Dictionary={},nutrient_report:Dictionary={}) -> Dictionary:
	var projected_stocks:Dictionary=WorldSimulation.state.food_stocks.duplicate(true)
	var current_day:=WorldSimulation.state.elapsed_days
	var environment:=_environment_mix()
	var climate_key:=[WorldSimulation.state.world_seed,environment.get("position",Vector2.ZERO),environment.get("seasonality_c",12.0),environment.get("growing_season",0.5),environment.get("precipitation",0.5),environment.get("game",0.4),environment.get("water_access",0.0),environment.get("rainfall_variability",0.35)]
	if not _forecast_climate_cache.has(climate_key):
		if _forecast_climate_cache.size()>=FORECAST_SITE_LIMIT:_forecast_climate_cache.erase(_forecast_climate_cache.keys()[0])
		_forecast_climate_cache[climate_key]={}
	var climate_days:Dictionary=_forecast_climate_cache[climate_key]
	var current_climate:=_forecast_climate(environment,current_day,climate_days)
	var pre_ration_current:=float(demand_breakdown.get("total",0.0))+float(demand_breakdown.get("rationing",0.0))
	var non_climate:=maxf(0.0,pre_ration_current-float(demand_breakdown.get("climate",0.0)))
	var ration_factor:=1.0+_policy_effect("food_demand")
	var inaccessible_army_rations:=float(demand_breakdown.get("army_field",0.0))*(1.0-clampf(provision_delivery_ratio,0.0,1.0))
	var first_shortage:=-1
	var total_produced:=0.0
	var total_required:=0.0
	var total_spoiled:=0.0
	# These inputs are constant across one forecast. Resolve the measured climate
	# once instead of re-reading the same society and watershed hundreds of times.
	var current_seasons:Dictionary={};var current_weather_types:Dictionary={}
	for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples"]:
		current_seasons[food_type]=maxf(.05,float(current_climate[food_type][0]))
		current_weather_types[food_type]=maxf(.05,float(current_climate[food_type][1]))
	var storage_multiplier:=0.72 if "Storage Pits" in WorldSimulation.state.settlement_completed else 1.0
	if traveling:storage_multiplier*=1.28
	var preservation:Dictionary={}
	for food_type:String in FOOD_TYPES:preservation[food_type]=WorldSimulation.discovery.food_storage_multiplier(food_type,traveling)
	# A projection mutates only projected food, never installed services. With
	# no current cooling, none of its future days can promise refrigeration.
	var has_cooling:=not traveling and Operations.service("cold_storage")>0.0
	var has_nutrients:=not traveling and float(nutrient_report.get("adoption",0))>0 and float(nutrient_report.get("bonus",0))>0
	var projected_nutrients:Dictionary=WorldSimulation.state.cultivation_nutrients.duplicate(true) if has_nutrients else {}
	var projected_inputs:Dictionary={}
	if has_nutrients:
		for resource:String in preload("res://scripts/crop_nutrition.gd").INPUTS:projected_inputs[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))
	for offset in range(1,horizon+1):
		var future_day:=current_day+float(offset)
		var future_climate_factors:=_forecast_climate(environment,future_day,climate_days)
		for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples"]:
			var current_season:=float(current_seasons[food_type])
			var future_season:=float(future_climate_factors[food_type][0])
			var current_weather_type:=float(current_weather_types[food_type])
			var future_weather_type:=float(future_climate_factors[food_type][1])
			var future_yield:=float(current_harvest.get(food_type,0.0))*future_season/current_season*future_weather_type/current_weather_type
			if food_type=="Dry staples" and has_nutrients:
				var scale:=future_season/current_season*future_weather_type/current_weather_type
				var nutrition:=preload("res://scripts/crop_nutrition.gd").projection(float(nutrient_report.base_harvest)*scale,projected_inputs,projected_nutrients,float(nutrient_report.adoption))
				future_yield=future_yield-float(nutrient_report.bonus)*scale+float(nutrition.bonus)
			projected_stocks[food_type]=float(projected_stocks.get(food_type,0.0))+future_yield
			total_produced+=future_yield
		var season_wave:=sin(fmod(future_day,365.0)/365.0*TAU)
		var future_climate:=non_climate*maxf(0.0,-season_wave)*0.06
		var future_required:=maxf(0.0,(non_climate+future_climate)*ration_factor-inaccessible_army_rations)
		total_required+=future_required
		var cooling:=Operations.refrigeration_multiplier(Operations.forecast_service("cold_storage",offset),projected_stocks) if has_cooling else 1.0
		for food_type in FOOD_TYPES:
			var amount:=float(projected_stocks.get(food_type,0.0))
			var loss:=amount*float(SPOILAGE[food_type])*storage_multiplier*float(preservation[food_type])*(cooling if food_type in ["Fresh plants","Fresh meat","Fish"] else 1.0)
			projected_stocks[food_type]=maxf(0.0,amount-loss)
			total_spoiled+=loss
		var eaten:=_consume_projection(projected_stocks,future_required)
		if eaten<future_required*0.98 and first_shortage<0: first_shortage=offset
		if offset==30 or offset==horizon:
			milestones[offset]=_forecast_summary(offset,projected_stocks,current_day,non_climate,ration_factor,inaccessible_army_rations,first_shortage,total_produced,total_required,total_spoiled)
	return milestones.get(horizon,{})

func _forecast_climate(environment:Dictionary,day:float,days:Dictionary)->Dictionary:
	# Overlapping forecasts ask about the same future dates. Cache only the
	# deterministic climate factors; recompute stocks, demand and shortages.
	if days.has(day):return days[day]
	var weather:=_weather_yield_factor(environment,day)
	var result:Dictionary={}
	for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples"]:
		result[food_type]=[PlanetEnvironment.food_season_factor(food_type,environment,day),_food_type_weather_multiplier(food_type,weather)]
	if days.size()>=128:days.erase(days.keys()[0])
	days[day]=result
	return result

func _forecast_summary(horizon:int,projected_stocks:Dictionary,current_day:float,non_climate:float,ration_factor:float,inaccessible_army_rations:float,first_shortage:int,total_produced:float,total_required:float,total_spoiled:float)->Dictionary:
	var ending_total:=0.0
	for amount in projected_stocks.values(): ending_total+=float(amount)
	var ending_need:=maxf(0.01,(non_climate+non_climate*maxf(0.0,-sin(fmod(current_day+float(horizon),365.0)/365.0*TAU))*0.06)*ration_factor-inaccessible_army_rations)
	return {
		"horizon":horizon,"ending_rations":ending_total,"ending_days":ending_total/maxf(0.01,ending_need),
		"first_shortage_day":first_shortage,"average_production":total_produced/float(horizon),
		"average_required":total_required/float(horizon),"spoilage":total_spoiled
	}

func _consume_projection(stocks: Dictionary,required: float) -> float:
	var remaining:=required
	for food_type in ["Fish","Fresh meat","Fresh plants","Dry staples","Preserved food"]:
		var available:=float(stocks.get(food_type,0.0))
		var amount:=minf(remaining,available)
		stocks[food_type]=available-amount
		remaining-=amount
		if remaining<=0.001: break
	return required-remaining

func _season_factor(food_type: String,day: float) -> float:
	return PlanetEnvironment.food_season_factor(food_type,_environment_mix(),day)


func _weather_yield_factor(profile:Dictionary,day:float)->float:
	## Weather is a smooth, deterministic aggregate—not one entity per storm.
	## Ordinary spells move yields modestly; climates with unreliable rainfall
	## can suffer a broad bad season or enjoy a favorable one. This prevents an
	## automatic steward from turning food into a perfectly flat solved number.
	var variability:=clampf(float(profile.get("rainfall_variability",0.35)),0.0,1.0)
	var phase_a:=float(absi(WorldSimulation.state.world_seed*31)%997)
	var phase_b:=float(absi(WorldSimulation.state.world_seed*73)%991)
	var rolling:=sin((day+phase_a)/53.0)*0.62+sin((day+phase_b)/127.0)*0.38
	var factor:=1.0+rolling*(0.035+variability*0.105)
	var year:=floori(maxf(0.0,day)/365.0)
	var day_of_year:=fmod(maxf(0.0,day),365.0)
	var annual_rng:=RandomNumberGenerator.new()
	annual_rng.seed=WorldSimulation.state.world_seed^(year+17)*86028121^roundi(variability*1000.0)*32452843
	var annual_roll:=annual_rng.randf()
	var center:=annual_rng.randf_range(65.0,300.0)
	var half_width:=annual_rng.randf_range(28.0,78.0)
	var pulse:=maxf(0.0,1.0-absf(day_of_year-center)/half_width)
	var drought_chance:=0.08+variability*0.34
	if annual_roll<drought_chance:
		var severity:=annual_rng.randf_range(0.12,0.18+variability*0.32)
		factor*=1.0-severity*pulse
	elif annual_roll>0.88:
		factor*=1.0+annual_rng.randf_range(0.08,0.18)*pulse
	return clampf(factor,0.52,1.24)


func _food_type_weather_multiplier(food_type:String,weather_factor:float)->float:
	match food_type:
		"Fresh plants": return weather_factor
		"Dry staples": return clampf(pow(weather_factor,1.25),0.46,1.30)
		"Fresh meat": return lerpf(1.0,weather_factor,0.38)
		"Fish": return lerpf(1.0,weather_factor,0.28)
	return 1.0

func _stock_total() -> float:
	var total:=0.0
	for amount in WorldSimulation.state.food_stocks.values(): total+=float(amount)
	return total


func total_stored()->float:
	initialize()
	return _stock_total()

func issue_for_obligation(requested:float,category:String="external",label:String="External transfer",duration_days:float=0.0,personnel:int=0)->float:
	initialize()
	var stock_before:=_stock_total()
	var removed:=0.0
	for amount in _consume(maxf(0.0,requested)).values(): removed+=float(amount)
	_sync_total()
	if removed>0.0001:
		var daily_need:=maxf(0.01,float(WorldSimulation.state.simulation_metrics.get("food_consumption",WorldSimulation.state.population_exact)))
		var departure_day:=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.state.food_issue_history.append({
			"id":"food_issue_%d_%d" % [departure_day,WorldSimulation.state.food_issue_history.size()],
			"day":departure_day,"end_day":departure_day+ceili(maxf(0.0,duration_days)),"category":category,"label":label,
			"amount":removed,"requested":maxf(0.0,requested),"duration_days":maxf(0.0,duration_days),
			"personnel":maxi(0,personnel),"stock_before":stock_before,"stock_after":_stock_total(),
			"settlement_days":removed/daily_need,"withdrawal_timing":"departure","charged_at_departure":true,"recurring":false
		})
		while WorldSimulation.state.food_issue_history.size()>FOOD_ISSUE_HISTORY_LIMIT: WorldSimulation.state.food_issue_history.pop_front()
	return removed


func remove_for_external_trade(requested:float)->float:
	return issue_for_obligation(requested,"external","External transfer")


func remove_for_settlement_convoy(requested:float,label:String="Founding convoy",duration_days:float=0.0,personnel:int=0)->float:
	# A founding party carries real aggregate rations from the same food ledger
	# used by daily consumption. This remains one fixed stock dictionary at any
	# population scale; it never creates ration or traveler entities.
	return issue_for_obligation(requested,"settlement_convoy",label,duration_days,personnel)


func issued_on_day(day:int)->float:
	var total:=0.0
	for issue_variant in WorldSimulation.state.food_issue_history:
		var issue:Dictionary=issue_variant
		if int(issue.get("day",-1))==day: total+=float(issue.get("amount",0.0))
	return total


# A bounded audit surface for the food panel. Daily consumers and mission
# withdrawals are deliberately separate: scouts, envoys, and settlement
# convoys take all travel rations once at departure and never create a hidden
# recurring food charge while away.
func food_account_snapshot(window_days:int=30)->Dictionary:
	initialize()
	var day:=int(WorldSimulation.state.elapsed_days)
	var demand:Dictionary=WorldSimulation.state.simulation_metrics.get("food_demand_breakdown",{})
	if demand.is_empty(): demand=_calculate_aggregate_demand(bool(WorldSimulation.state.convoy_traveling))
	var total_daily:=maxf(0.0,float(demand.get("total",0.0)))
	var army_daily:=clampf(float(demand.get("army_field",0.0)),0.0,total_daily)
	var occupation_daily:=clampf(float(demand.get("occupation_relief",0.0)),0.0,maxf(0.0,total_daily-army_daily))
	var settlement_daily:=maxf(0.0,total_daily-army_daily-occupation_daily)
	var daily_consumers:Array[Dictionary]=[
		{"id":"settlement_population","label":"SETTLEMENT POPULATION","amount":settlement_daily,"recurring":"daily","detail":{
			"children":float(demand.get("children",0.0)),"adults":float(demand.get("adults",0.0)),"elders":float(demand.get("elders",0.0)),
			"work_exertion":float(demand.get("labor",0.0)),"pregnancy_and_nursing":float(demand.get("pregnancy",0.0))+float(demand.get("lactation",0.0)),
			"travel":float(demand.get("travel",0.0)),"climate":float(demand.get("climate",0.0)),"prisoner_custody":float(demand.get("prisoner_custody",0.0)),
			"rationing_adjustment":float(demand.get("rationing",0.0))
		}},
		{"id":"field_military","label":"FIELD MILITARY","amount":army_daily,"recurring":"daily"},
		{"id":"occupation_relief","label":"OCCUPIED-CIVILIAN RELIEF","amount":occupation_daily,"recurring":"daily"}
	]
	var recent_issues:Array[Dictionary]=[]
	var active_commitments:Array[Dictionary]=[]
	var withdrawn_window:=0.0
	var window_start:=day-maxi(0,window_days)+1
	for index in range(WorldSimulation.state.food_issue_history.size()-1,-1,-1):
		var source:Dictionary=WorldSimulation.state.food_issue_history[index]
		var issue:=source.duplicate(true)
		var issue_day:=int(issue.get("day",-1))
		var end_day:=int(issue.get("end_day",issue_day+ceili(maxf(0.0,float(issue.get("duration_days",0.0))))))
		issue["end_day"]=end_day
		issue["withdrawal_timing"]="departure"
		issue["charged_at_departure"]=true
		issue["recurring"]=false
		issue["mission_active"]=float(issue.get("duration_days",0.0))>0.0 and day<end_day
		if issue_day>=window_start:
			withdrawn_window+=maxf(0.0,float(issue.get("amount",0.0)))
			if recent_issues.size()<32: recent_issues.append(issue)
		if bool(issue.mission_active) and active_commitments.size()<16: active_commitments.append(issue)
	return {
		"day":day,"stored":_stock_total(),"daily_total":total_daily,"daily_consumers":daily_consumers,
		"withdrawn_today":issued_on_day(day),"withdrawn_in_window":withdrawn_window,"window_days":maxi(0,window_days),
		"recent_departure_issues":recent_issues,"active_mission_provisions":active_commitments,
		"history_limit":FOOD_ISSUE_HISTORY_LIMIT,"charged_once_at_departure":true,"bounded":true
	}

func receive_external_food(requested:float)->float:
	initialize()
	var received:=maxf(0.0,requested)
	WorldSimulation.state.food_stocks["Dry staples"]=float(WorldSimulation.state.food_stocks.get("Dry staples",0.0))+received
	_sync_total()
	return received

func _sync_total() -> void:
	WorldSimulation.state.resource_stockpiles["Food"]=_stock_total()

func _modifier_strength(effect_id: String) -> float:
	var engine:=WorldSimulation.system("ConsequenceEngine")
	if engine and engine.has_method("modifier_strength"):
		return float(engine.call("modifier_strength",effect_id))
	return 0.0

func _policy_effect(channel:String)->float:
	var engine:=WorldSimulation.system("ConsequenceEngine")
	if engine and engine.has_method("policy_effect"):
		return float(engine.call("policy_effect",channel))
	return 0.0
