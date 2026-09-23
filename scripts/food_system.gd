extends Node

# Food is measured internally in adult-equivalent daily rations. One ration is
# displayed as roughly 2,400 kcal. Demand is calculated from numeric age,
# labor, pregnancy, lactation, travel, military, and climate cohorts.
#
# Food is held in two pools. Fresh food (gathered plants, game and fish) spoils
# quickly and is eaten first. Stored food (cultivated staples and everything
# preserved) spoils slowly and is the reserve. Food-processing discoveries are
# techniques: once adopted they reduce spoilage, preserve more of the fresh
# surplus, improve the diet or raise yields, in proportion to Civilian Goods
# coverage (the tools, vessels and racks households actually hold).

const SPAN=preload("res://scripts/day_span.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
const Operations=preload("res://scripts/technology_operations.gd")
const KCAL_PER_RATION := 2400.0
const BASE_SUBSISTENCE_YIELD_CALIBRATION:=1.34
const FRESH:="Fresh food"
const STORED:="Stored food"
const FOOD_TYPES := [FRESH,STORED]
## Harvest sources; each lands in a pool.
const SOURCES:=["Fresh plants","Fresh meat","Fish","Dry staples"]
const FOOD_ISSUE_HISTORY_LIMIT:=96
const SPOILAGE := {FRESH:0.040,STORED:0.0010}
## Former five-type stocks, folded into the two pools when an older save loads.
const LEGACY_FRESH:=["Fresh plants","Fresh meat","Fish"]
const LEGACY_STORED:=["Dry staples","Preserved food"]
## Days between forecast refreshes; the outlook is estimated in weekly steps.
const FORECAST_REFRESH_DAYS:=7
## Technique levers: fresh_spoilage and stored_spoilage reduce spoilage,
## preservation raises fresh-to-stored throughput, diet adds diet quality,
## cultivation and gathering raise yields. Values are for full adoption.
const TECHNIQUES:={
	"threshing_frames":{"cultivation":.03,"stored_spoilage":.04},
	"winnowing_practice":{"cultivation":.03,"stored_spoilage":.04},
	"grain_moisture_testing":{"stored_spoilage":.06},
	"forced_air_grain_drying":{"stored_spoilage":.08},
	"roller_grain_milling":{"diet":.02},
	"flour_sifting":{"diet":.02},
	"grain_malting":{"diet":.02},
	"acorn_leaching":{"gathering":.03},"cereal_dehulling":{"diet":.01,"stored_spoilage":.02},"controlled_baking":{"diet":.02},
	"dough_leavening":{"diet":.01},"fermentation_starter_cultures":{"diet":.01,"stored_spoilage":.02},"food_acidity_measurement":{"stored_spoilage":.02},
	"food_batch_traceability":{"stored_spoilage":.02},"food_package_barrier_testing":{"stored_spoilage":.03},"food_package_leak_detection":{"stored_spoilage":.03},
	"food_pounding_mortars":{"diet":.01},"food_process_hazard_analysis":{"stored_spoilage":.03},"food_water_activity_measurement":{"stored_spoilage":.03},
	"fruit_pulp_screening":{"diet":.01},"grain_parboiling":{"diet":.01,"stored_spoilage":.03},"hand_dough_forming":{"diet":.01},
	"humidity_measurement":{"stored_spoilage":.02},"indirect_solar_food_drying":{"preservation":.20},"nut_kernel_shelling":{"gathering":.02},
	"postharvest_loss_measurement":{"stored_spoilage":.03,"fresh_spoilage":.03},"pulse_splitting":{"diet":.01},"root_grating_dewatering":{"gathering":.02},
	"starch_washing_separation":{"diet":.01},
	"edible_resource_recognition":{"gathering":.12},
	"food_retorts":{"preservation":.50,"stored_spoilage":.10},"thermal_process_validation":{"stored_spoilage":.05},
	"double_seaming":{"preservation":.10},"can_body_forming":{"preservation":.10},
	"nutrient_response_trials":{"cultivation":.06},"mineral_nitrate_dressing":{"cultivation":.08},"phosphate_solubilization":{"cultivation":.06},
	"ammonium_sulfate_fertilizer":{"cultivation":.10},"catalytic_ammonia_synthesis":{"cultivation":.15},
	"habitat_observation_records":{"cultivation":.03},"heredity_experiments":{"cultivation":.05},"plant_pathology_diagnosis":{"cultivation":.04},
	"plant_resistance_trait_trials":{"cultivation":.05},"plant_transpiration_measurement":{"cultivation":.02},
	"ember_tending":{"diet":.02},"hearth_heat_retention":{"diet":.01},
	"hearth_roasting_control":{"diet":.03},"earth_oven_cooking":{"diet":.03},"food_steaming_vessels":{"diet":.03},
}
const LEVER_LIMITS:={"fresh_spoilage":.40,"stored_spoilage":.60,"preservation":2.0,"diet":.25,"cultivation":.60,"gathering":.30}

var initialized := false
## Per-city access to game, water and fertile soil, refreshed monthly.
var _access_cache:Dictionary={}
## Technique levers per city and day; see _technique_levers.
var _lever_cache:Dictionary={}

func reset_for_new_world()->void:
	initialized=false
	_access_cache.clear()
	_lever_cache.clear()

func initialize() -> void:
	if initialized and not WorldSimulation.state.food_stocks.is_empty():
		_fold_legacy_pools()
		return
	if WorldSimulation.state.founding_manifest.is_empty(): WorldSimulation.resources.initialize()
	initialized=true
	if WorldSimulation.state.food_stocks.is_empty():
		var existing:=float(WorldSimulation.state.resource_stockpiles.get("Food",WorldSimulation.state.population_exact*30.0))
		WorldSimulation.state.food_stocks={FRESH:existing*0.02,STORED:existing*0.98}
	_fold_legacy_pools()
	_sync_total()

## Older saves hold five food types plus grain and batch ledgers.
func _fold_legacy_pools()->void:
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	if not stocks.has("Dry staples") and not stocks.has("Fresh plants") and stocks.has(FRESH):return
	var fresh:=float(stocks.get(FRESH,0.0));var stored:=float(stocks.get(STORED,0.0))
	for key:String in LEGACY_FRESH:fresh+=maxf(0.0,float(stocks.get(key,0.0)));stocks.erase(key)
	for key:String in LEGACY_STORED:stored+=maxf(0.0,float(stocks.get(key,0.0)));stocks.erase(key)
	stored+=_legacy_ledger_rations()
	stocks[FRESH]=fresh;stocks[STORED]=stored

## Food held in the retired grain and batch ledgers, which are then cleared.
func _legacy_ledger_rations()->float:
	var total:=0.0
	var state=WorldSimulation.state
	var grain:Dictionary=state.grain_processing if state.get("grain_processing") is Dictionary else {}
	for amount in (grain.get("stocks",{}) as Dictionary).values():total+=maxf(0.0,float(amount))
	for batch in grain.get("batches",[]):total+=maxf(0.0,float((batch as Dictionary).get("amount",0.0)))
	var batches:Dictionary=state.food_batches if state.get("food_batches") is Dictionary else {}
	for lot in batches.get("lots",[]):total+=maxf(0.0,float((lot as Dictionary).get("amount",0.0)))
	if not grain.is_empty():state.grain_processing=preload("res://scripts/grain_processing.gd").empty_state()
	if not batches.is_empty():state.food_batches=preload("res://scripts/food_batches.gd").empty_state()
	return total

func process_day(context: Dictionary,labor_efficiency: float,ecology: float) -> Dictionary:
	return WorldSimulation.settlements.with_local_population(func()->Dictionary: return _process_local_day(context,labor_efficiency,ecology))

## Total strength of one lever from adopted food techniques, 0 when none.
func technique_lever(lever:String)->float:
	return float(_technique_levers()[lever])

## All levers for the current city, resolved once per day. Adoption and goods
## coverage change at most once a day for a city, outside the food step.
func _technique_levers()->Dictionary:
	var state=WorldSimulation.state
	var key:=[WorldSimulation.actor_id,state.resource_settlement_id,int(state.elapsed_days),state.known_discoveries.size()]
	var cached:Variant=_lever_cache.get(key)
	if cached!=null:return cached
	var totals:Dictionary={}
	for lever:String in LEVER_LIMITS:totals[lever]=0.0
	var known:Array=state.known_discoveries
	for id:String in TECHNIQUES:
		if id not in known:continue
		var adoption:=clampf(WorldSimulation.discovery.adoption(id),0.0,1.0)
		var levers:Dictionary=TECHNIQUES[id]
		for lever:String in levers:totals[lever]=float(totals[lever])+float(levers[lever])*adoption
	var coverage:=Goods.coverage()
	for lever:String in totals:totals[lever]=minf(float(LEVER_LIMITS[lever]),float(totals[lever])*coverage)
	if _lever_cache.size()>=512:_lever_cache.clear()
	_lever_cache[key]=totals
	return totals

func _process_local_day(context: Dictionary,labor_efficiency: float,ecology: float) -> Dictionary:
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	initialize()
	_fold_legacy_pools()
	var initial_stock:=_stock_total()
	var traveling:=bool(context.get("traveling",WorldSimulation.state.convoy_traveling))
	# A multi-day step (day_span.gd) is one pass with `span` days of labor and
	# need; per-day rates are scaled and reported figures stay per day.
	var span:=float(WorldSimulation.span)
	var workers:=WorldSimulation.state.effective_workers("Food")*span
	var logistics:=WorldSimulation.state.effective_workers("Logistics")*span
	var makers:=WorldSimulation.state.effective_workers("Crafting")*span
	var military_campaign:Node=WorldSimulation.system("MilitaryCampaign") if WorldSimulation.state.resource_settlement_id=="" else null
	if military_campaign!=null and military_campaign.has_method("civilian_crafting_fraction"):
		makers*=clampf(float(military_campaign.civilian_crafting_fraction()),0.0,1.0)
	var demand_breakdown:=_calculate_demand(traveling)
	var need:=float(demand_breakdown.total)*span
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var wants_fire:=("hearth_roasting_control" in WorldSimulation.state.known_discoveries and float(demand_breakdown.total)>0.0) or ("smoking" in WorldSimulation.state.known_discoveries and float(stocks.get(FRESH,0.0))>0.0)
	var fire_report:=preload("res://scripts/fire_practice.gd").advance(int(WorldSimulation.state.elapsed_days),wants_fire,traveling)
	var harvest:=_produce(workers,labor_efficiency,ecology,traveling)
	if WorldSimulation.state.resource_settlement_id.is_empty() and not traveling:
		var access:=WorldSimulation.military.siege_home_food_access()
		for source in harvest: harvest[source]*=access
	stocks[FRESH]=float(stocks.get(FRESH,0.0))+float(harvest["Fresh plants"])+float(harvest["Fresh meat"])+float(harvest["Fish"])
	stocks[STORED]=float(stocks.get(STORED,0.0))+float(harvest["Dry staples"])+float(harvest.get("Transferred",0.0))
	stamp=trace.mark("food_harvest",stamp)
	var clothing:=preload("res://scripts/household_clothing.gd").advance(0.0,WorldSimulation.state.population_exact,traveling,float(harvest.get("Fresh meat",0)))
	var preservation_inputs:Dictionary={}
	var preserved:=_preserve(logistics,makers,traveling,preservation_inputs)
	var spoilage:=_spoil(traveling,float(harvest["Fresh plants"])+float(harvest["Fresh meat"])+float(harvest["Fish"]))
	stamp=trace.mark("food_processing",stamp)
	var demand:=need
	var army_original:=float(demand_breakdown.get("army_field",0.0))*span
	var credited:Dictionary=military_campaign.draw_delivered_field_rations(army_original) if military_campaign!=null else {"total":0.0,"by_army":{}}
	demand=maxf(0,demand-float(credited.total))
	var army_required:=maxf(0,army_original-float(credited.total))
	var provision_delivery_ratio:=1.0
	if military_campaign!=null and military_campaign.has_method("field_provision_delivery_ratio"):
		provision_delivery_ratio=clampf(float(military_campaign.field_provision_delivery_ratio(army_original,credited)),0.0,1.0)
	var army_accessible:=army_required*provision_delivery_ratio
	var accessible_demand:=maxf(0.0,demand-army_required+army_accessible)
	var consumed:=_consume(accessible_demand)
	# People can eat today's harvest before excess stock is discarded for lack of
	# storage. Capacity constrains what survives the day, not what can be consumed.
	var storage_loss:=_apply_storage_capacity()
	for pool in storage_loss:
		spoilage[pool]=float(spoilage.get(pool,0.0))+float(storage_loss[pool])
	var eaten:=float(consumed[FRESH])+float(consumed[STORED])
	var intake_ratio:=clampf(eaten/maxf(0.01,demand),0.0,1.0)
	var accessible_intake:=clampf(eaten/maxf(0.01,accessible_demand),0.0,1.0)
	var army_delivered:=army_accessible*accessible_intake
	if military_campaign!=null and military_campaign.has_method("record_daily_provisions"):
		military_campaign.record_daily_provisions(army_original,army_delivered,credited)
	var diet_quality:=_diet_quality(consumed,eaten,harvest)
	_update_nutrition(intake_ratio,diet_quality)
	_update_source_health(harvest,workers/span,traveling)
	if span>1.0:
		# The report, forecast and history describe one representative day.
		for record:Dictionary in [harvest,consumed,spoilage,preserved]:
			for key in record:record[key]=float(record[key])/span
		demand/=span;eaten/=span;army_required/=span;army_delivered/=span;workers/=span
		initial_stock=_stock_total()-(_stock_total()-initial_stock)/span
	var total:=_stock_total()
	var spoilage_total:=0.0
	for amount in spoilage.values(): spoilage_total+=float(amount)
	var production_total:=0.0
	for source in SOURCES: production_total+=float(harvest.get(source,0.0))
	var net:=total-initial_stock
	var effective_daily_loss:=maxf(0.01,demand-production_total+spoilage_total)
	var projected_days:=9999.0 if net>=0.0 else total/effective_daily_loss
	var food_days:=total/maxf(0.01,demand)
	stamp=trace.mark("food_consumption",stamp)
	var sources:=_source_report(harvest,workers,traveling)
	var forecast:=_forecast(harvest,demand_breakdown,provision_delivery_ratio)
	stamp=trace.mark("food_forecast",stamp)
	var weather_factor:=_weather_yield_factor(_environment_mix(),WorldSimulation.state.elapsed_days)
	var working_total:=0.0
	for role:String in WorldSimulation.state.POPULATION_ROLES:working_total+=maxf(0.0,WorldSimulation.state.effective_workers(role))
	var result:={
		"food_labor_share":workers/maxf(1.0,working_total),
		"clothing":clothing.coverage,
		"clothing_workers":0.0,
		"food_days":food_days,
		"food_total_stock":total,
		"food_production":production_total,
		"food_consumption":demand,
		"food_eaten":eaten,
		"food_shortfall":maxf(0.0,demand-eaten),
		"food_intake_ratio":intake_ratio,
		"food_balance":production_total/maxf(0.01,demand)-1.0,
		"food_net":net,
		"food_spoilage":spoilage_total,
		"food_projected_days":projected_days,
		"food_forecast_day":int(forecast.get("day",int(WorldSimulation.state.elapsed_days))),
		"food_forecast_30":forecast[30],
		"food_forecast_90":forecast[90],
		"food_diet_quality":diet_quality,
		"fire_practice":fire_report,
		"food_weather_factor":weather_factor,
		"nutrition_reserve":WorldSimulation.state.nutrition_reserve,
		"malnutrition_burden":WorldSimulation.state.malnutrition_burden,
		"food_stocks":stocks.duplicate(true),
		"food_harvest":harvest,
		"food_consumed_by_type":consumed,
		"food_spoilage_by_type":spoilage,
		"food_preserved":preserved,
		"food_preservation_inputs":preservation_inputs,
		"food_demand_breakdown":demand_breakdown,
		"food_techniques":_technique_levers().duplicate(),
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
	stamp=trace.mark("food_report",stamp)
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

func _produce(workers: float,labor_efficiency: float,ecology: float,traveling: bool) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Transferred":0.0}
	var civilization_system:=WorldSimulation.system("CivilizationSystem")
	if not WorldSimulation.enabled and WorldSimulation.state.resource_settlement_id=="" and civilization_system!=null and civilization_system.has_method("player_effects") and not traveling:
		result["Transferred"]=maxf(0.0,float(civilization_system.player_effects().get("occupation_food_transfer",0.0)))
	if workers<=0.0:
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
		var seed_coverage:=preload("res://scripts/opening_opportunities.gd").practice_factor("seed_selection")
		cultivation_weight=(0.22+float(environment.get("fertility",0.0))*0.20+float(access.fertile)*0.08)*WorldSimulation.discovery.adoption("seed_selection")*seed_coverage
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
	var gathering_bonus:=1.0+technique_lever("gathering")
	result["Fresh plants"]=workers*gathering_weight*4.55*BASE_SUBSISTENCE_YIELD_CALIBRATION*terrain_gather*plant_season*efficiency*ecological*float(WorldSimulation.state.food_source_health.get("Wild gathering",0.9))*practice*variation*route_factor*(1.0+float(coastal.foraging_bonus))*_food_type_weather_multiplier("Fresh plants",weather_factor)*gathering_bonus
	result["Fresh meat"]=workers*hunting_weight*4.85*BASE_SUBSISTENCE_YIELD_CALIBRATION*terrain_hunt*game_season*efficiency*ecological*float(WorldSimulation.state.food_source_health.get("Hunting",0.9))*(1.0+float(access.game)*0.18)*(1.0+WorldSimulation.discovery.effect("hunting_yield"))*practice*variation*route_factor*_food_type_weather_multiplier("Fresh meat",weather_factor)
	var fishing_access:=maxf(float(access.freshwater),float(coastal.marine_opportunity)*0.90)
	result["Fish"]=workers*fishing_weight*5.00*BASE_SUBSISTENCE_YIELD_CALIBRATION*fish_season*efficiency*float(WorldSimulation.state.food_source_health.get("Fishing",0.9))*(0.76+fishing_access*0.34)*practice*variation*route_factor*(1.0+float(coastal.food_output_bonus))*_food_type_weather_multiplier("Fish",weather_factor)
	if cultivation_weight>0.0 and not traveling:
		var agronomy:Dictionary=preload("res://scripts/agronomy_knowledge.gd").factors(traveling)
		result["Dry staples"]=workers*cultivation_weight*5.65*crop_season*efficiency*float(WorldSimulation.state.food_source_health.get("Cultivation",0.9))*(0.68+float(environment.get("fertility",0.0))*0.38+float(access.fertile)*0.12)*(1.0+WorldSimulation.discovery.effect("soil_productivity")+WorldSimulation.discovery.effect("cultivation_yield"))*variation*float(agronomy["yield"])*preload("res://scripts/agronomy_knowledge.gd").weather_factor(_food_type_weather_multiplier("Dry staples",weather_factor),agronomy)*(1.0+technique_lever("cultivation"))
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
	# Deposits and hydrology change slowly; resolve each city's access monthly.
	var key:=[WorldSimulation.actor_id,WorldSimulation.state.resource_settlement_id,int(WorldSimulation.state.elapsed_days)/30,bool(WorldSimulation.state.water_metrics.get("source_accessible",false)),WorldSimulation.state.resource_deposits.size()]
	var cached:Variant=_access_cache.get(key)
	if cached!=null:return cached
	var result:={"game":0.0,"freshwater":0.0,"fertile":0.0}
	# Authored hydrology is authoritative. A settlement with direct access to a
	# visible river must not lose fishing/water effects because no point-deposit
	# record happened to be scattered beside it.
	if bool(WorldSimulation.state.water_metrics.get("source_accessible",false)):
		result.freshwater=1.0
	for deposit in WorldSimulation.state.resource_deposits:
		if String(deposit.get("stage","unknown")) not in ["accessible","developed"]: continue
		var resource:=String(deposit.get("resource","")).to_lower()
		if resource=="game": result.game=maxf(float(result.game),float(deposit.get("quality",0.7)))
		elif resource=="freshwater": result.freshwater=maxf(float(result.freshwater),float(deposit.get("quality",0.7)))
		elif resource=="fertile soil": result.fertile=maxf(float(result.fertile),float(deposit.get("quality",0.7)))
	if _access_cache.size()>=512:_access_cache.clear()
	_access_cache[key]=result
	return result

func _preserve(logistics: float,makers: float,traveling: bool,inputs:Dictionary={}) -> Dictionary:
	# Moves part of the fresh surplus into the stored pool: drying, smoking and,
	# later, canning. Throughput comes from Logistics and Crafting workers.
	var result:={"dried":0.0,"smoked":0.0,"canned":0.0}
	if traveling: return result
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var capacity:=(logistics*0.16+makers*0.18)*(1.0+WorldSimulation.discovery.effect("food_storage"))*(1.0+technique_lever("preservation"))
	if "food_drying" in WorldSimulation.state.known_discoveries:
		var drying_weather:=_drying_weather_factor(_environment_mix(),WorldSimulation.state.elapsed_days)
		var amount:=minf(float(stocks.get(FRESH,0.0)),capacity*0.55*clampf(WorldSimulation.discovery.adoption("food_drying"),0.0,1.0)*Goods.factor("food_drying")*drying_weather)
		stocks[FRESH]=float(stocks[FRESH])-amount
		stocks[STORED]=float(stocks.get(STORED,0.0))+amount*0.88
		result.dried=amount
		capacity=maxf(0.0,capacity-amount)
	preload("res://scripts/fire_practice.gd").ensure_initialized()
	if "smoking" in WorldSimulation.state.known_discoveries and preload("res://scripts/fire_practice.gd").available() and capacity>0.0:
		var amount:=minf(float(stocks.get(FRESH,0.0)),capacity*0.5*clampf(WorldSimulation.discovery.adoption("smoking"),0.0,1.0)*Goods.factor("smoking"))
		# Smoking must maintain an actual wood fire; knowledge alone supplies no heat.
		amount=minf(amount,maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get("Timber",0.0)))/0.04)
		var fuel:=amount*0.04
		if fuel>0.0:
			WorldSimulation.state.resource_stockpiles.Timber=maxf(0,float(WorldSimulation.state.resource_stockpiles.Timber)-fuel)
			inputs["Timber"]=float(inputs.get("Timber",0.0))+fuel
		stocks[FRESH]=float(stocks[FRESH])-amount
		stocks[STORED]=float(stocks.get(STORED,0.0))+amount*0.82
		result.smoked=amount
	# Installed canning lines add their preservation service on top.
	var canning:=minf(float(stocks.get(FRESH,0.0)),Operations.service("food_preservation")*float(WorldSimulation.span))
	if canning>0.0:
		stocks[FRESH]=float(stocks[FRESH])-canning
		stocks[STORED]=float(stocks.get(STORED,0.0))+canning*0.90
		Operations.data().services["food_preservation"]=maxf(0.0,Operations.service("food_preservation")-canning/float(WorldSimulation.span))
		result.canned=canning
	return result

func _drying_weather_factor(profile:Dictionary,day:float)->float:
	# Open-air drying remains possible in damp country, but cool humid seasons
	# demand much more rack time. Hot, dry air helps without creating free output.
	var precipitation:=clampf(float(profile.get("precipitation",0.5)),0.0,1.0)
	var temperature:=PlanetEnvironment.ambient_temperature_c(profile,day)
	var warmth:=clampf((temperature+5.0)/35.0,0.0,1.0)
	return clampf(0.38+(1.0-precipitation)*0.52+warmth*0.25,0.25,1.15)

func _spoil(traveling: bool,fresh_arrived:float=0.0) -> Dictionary:
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var preservation:=WorldSimulation.discovery.food_storage_multipliers(["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"],traveling)
	var fresh_preservation:=(float(preservation["Fresh plants"])+float(preservation["Fresh meat"])+float(preservation["Fish"]))/3.0
	var stored_preservation:=(float(preservation["Dry staples"])+float(preservation["Preserved food"]))*0.5
	var storage_multiplier:=0.72 if "Storage Pits" in WorldSimulation.state.settlement_completed else 1.0
	storage_multiplier*=maxf(0.30,1.0+WorldSimulation.discovery.effect("food_spoilage"))
	if not traveling:storage_multiplier*=1.0-preload("res://scripts/undertaking_rewards.gd").local_bonus(WorldSimulation.state,"spoilage")
	if traveling: storage_multiplier*=1.28
	var cooling:=Operations.refrigeration_multiplier(Operations.service("cold_storage") if not traveling else 0.0,stocks)
	var fresh:=float(stocks.get(FRESH,0.0));var stored:=float(stocks.get(STORED,0.0))
	var fresh_rate:=float(SPOILAGE[FRESH])*storage_multiplier*fresh_preservation*cooling*(1.0-technique_lever("fresh_spoilage"))
	var stored_rate:=float(SPOILAGE[STORED])*storage_multiplier*stored_preservation*(1.0-technique_lever("stored_spoilage"))
	# In a multi-day step (day_span.gd) stored food spoils for every covered day;
	# each day's harvest is mostly eaten on arrival, so it keeps one day's exposure.
	var arrived:=clampf(fresh_arrived,0.0,fresh)
	var fresh_loss:=(fresh-arrived)*SPAN.rate(clampf(fresh_rate,0.0,1.0))+arrived*clampf(fresh_rate,0.0,1.0)
	var stored_loss:=stored*SPAN.rate(clampf(stored_rate,0.0,1.0))
	stocks[FRESH]=maxf(0.0,fresh-fresh_loss)
	stocks[STORED]=maxf(0.0,stored-stored_loss)
	return {FRESH:fresh_loss,STORED:stored_loss}

func _apply_storage_capacity() -> Dictionary:
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var excess:=maxf(0.0,_stock_total()-_food_storage_capacity())
	var losses:={}
	for pool in [FRESH,STORED]:
		if excess<=0.0: break
		var discard:=minf(excess,float(stocks.get(pool,0.0)))
		stocks[pool]=float(stocks.get(pool,0.0))-discard
		losses[pool]=discard
		excess-=discard
	return losses

func _food_storage_capacity()->float:
	var capacity:=float(WorldSimulation.state.founding_manifest.get("food_storage_rations",0.0))
	if "Storage Pits" in WorldSimulation.state.settlement_completed:capacity+=WorldSimulation.state.population_exact*84.0
	if "Public Stores" in WorldSimulation.state.settlement_completed:capacity+=WorldSimulation.state.population_exact*120.0*Goods.factor("public_stores")
	capacity+=Goods.sealed_storage_rations()
	capacity+=preload("res://scripts/undertaking_rewards.gd").local_bonus(WorldSimulation.state,"food_capacity")
	return capacity

func _consume(required: float) -> Dictionary:
	# Fresh food is eaten first; stored food is the reserve.
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var fresh:=minf(maxf(0.0,required),maxf(0.0,float(stocks.get(FRESH,0.0))))
	stocks[FRESH]=float(stocks.get(FRESH,0.0))-fresh
	var stored:=minf(maxf(0.0,required-fresh),maxf(0.0,float(stocks.get(STORED,0.0))))
	stocks[STORED]=float(stocks.get(STORED,0.0))-stored
	return {FRESH:fresh,STORED:stored}

func _diet_quality(consumed: Dictionary,total: float,harvest:Dictionary) -> float:
	if total<=0.001: return 0.0
	# Fresh food carries today's mix of gathered plants and game or fish; stored
	# food is mostly staples with some preserved protein.
	var plants:=float(harvest.get("Fresh plants",0.0));var protein:=float(harvest.get("Fresh meat",0.0))+float(harvest.get("Fish",0.0))
	var plant_fraction:=plants/(plants+protein) if plants+protein>0.001 else 0.5
	var fresh:=float(consumed.get(FRESH,0.0));var stored:=float(consumed.get(STORED,0.0))
	var plant_share:=(fresh*plant_fraction+stored*0.75)/total
	var protein_share:=(fresh*(1.0-plant_fraction)+stored*0.25*0.45)/total
	var harvested:=0.0
	for source in SOURCES:harvested+=float(harvest.get(source,0.0))
	var categories:=0
	for source in SOURCES:
		if float(harvest.get(source,0.0))>maxf(0.001,harvested)*0.03: categories+=1
	if stored>total*0.03 and float(harvest.get("Dry staples",0.0))<=harvested*0.03:categories+=1
	var diversity:=clampf(float(categories)/4.0,0.0,1.0)
	return clampf(0.24+minf(plant_share,0.48)*0.65+minf(protein_share,0.30)*0.95+diversity*0.22+WorldSimulation.discovery.effect("nutrition_quality")+technique_lever("diet"),0.05,1.0)

func _update_nutrition(intake_ratio: float,diet_quality: float) -> void:
	var reserve_delta:=((intake_ratio-0.94)*0.010+(diet_quality-0.55)*0.0018)*WorldSimulation.span
	WorldSimulation.state.nutrition_reserve=clampf(WorldSimulation.state.nutrition_reserve+reserve_delta,0.0,1.0)
	var burden_target:=clampf((1.0-intake_ratio)*0.68+(0.58-diet_quality)*0.24+(0.28-WorldSimulation.state.nutrition_reserve)*0.45,0.0,1.0)
	WorldSimulation.state.malnutrition_burden=lerpf(WorldSimulation.state.malnutrition_burden,burden_target,SPAN.rate(0.045 if burden_target>WorldSimulation.state.malnutrition_burden else 0.012))

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
		WorldSimulation.state.food_source_health[source]=clampf(current+(recovery-damage)*WorldSimulation.span,0.12,1.0)

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

## The 30- and 90-day outlook, estimated in weekly steps from seasonal
## yields, spoilage and need. It is refreshed weekly, and at once when stores
## run low, rather than stepped through every future day.
func _forecast(harvest: Dictionary,demand_breakdown: Dictionary,provision_delivery_ratio:=1.0) -> Dictionary:
	var day:=int(WorldSimulation.state.elapsed_days)
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	var last:=int(metrics.get("food_forecast_day",-100000))
	var stored_days:=_stock_total()/maxf(0.01,float(demand_breakdown.get("total",1.0)))
	if day-last<FORECAST_REFRESH_DAYS and day>=last and stored_days>=30.0 and metrics.get("food_forecast_90") is Dictionary and metrics.get("food_forecast_30") is Dictionary:
		var aged:=day-last
		return {"day":last,30:_aged_forecast(metrics.food_forecast_30,aged),90:_aged_forecast(metrics.food_forecast_90,aged)}
	var environment:=_environment_mix()
	var current_day:=float(day)
	var now_factors:=_forecast_climate(environment,current_day,{})
	var pre_ration_current:=float(demand_breakdown.get("total",0.0))+float(demand_breakdown.get("rationing",0.0))
	var non_climate:=maxf(0.0,pre_ration_current-float(demand_breakdown.get("climate",0.0)))
	var ration_factor:=1.0+_policy_effect("food_demand")
	var inaccessible_army_rations:=float(demand_breakdown.get("army_field",0.0))*(1.0-clampf(provision_delivery_ratio,0.0,1.0))
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var fresh:=float(stocks.get(FRESH,0.0));var stored:=float(stocks.get(STORED,0.0))
	var fresh_daily:=1.0-pow(1.0-clampf(float(SPOILAGE[FRESH])*(1.0-technique_lever("fresh_spoilage")),0.0,1.0),7.0)
	var stored_daily:=1.0-pow(1.0-clampf(float(SPOILAGE[STORED])*(1.0-technique_lever("stored_spoilage")),0.0,1.0),7.0)
	var first_shortage:=-1;var produced_total:=0.0;var required_total:=0.0;var spoiled_total:=0.0
	var result:={"day":day}
	for week in 13:
		var mid_day:=current_day+float(week)*7.0+3.5
		var factors:=_forecast_climate(environment,mid_day,{})
		var week_fresh:=0.0;var week_stored:=0.0
		for source in SOURCES:
			var now:Array=now_factors[source];var then:Array=factors[source]
			var scale:=float(then[0])/maxf(.05,float(now[0]))*float(then[1])/maxf(.05,float(now[1]))
			var amount:=float(harvest.get(source,0.0))*scale*7.0
			if source=="Dry staples":week_stored+=amount
			else:week_fresh+=amount
		var season_wave:=sin(fmod(mid_day,365.0)/365.0*TAU)
		var required:=maxf(0.0,(non_climate+non_climate*maxf(0.0,-season_wave)*0.06)*ration_factor-inaccessible_army_rations)*7.0
		fresh+=week_fresh;stored+=week_stored
		produced_total+=week_fresh+week_stored;required_total+=required
		var eaten_fresh:=minf(fresh,required);fresh-=eaten_fresh
		var eaten_stored:=minf(stored,required-eaten_fresh);stored-=eaten_stored
		var eaten:=eaten_fresh+eaten_stored
		if eaten<required*0.98 and first_shortage<0:
			# Food ran out during this week; estimate the day it did.
			first_shortage=maxi(1,week*7+roundi(7.0*eaten/maxf(0.01,required)))
		var fresh_loss:=fresh*fresh_daily;var stored_loss:=stored*stored_daily
		fresh-=fresh_loss;stored-=stored_loss;spoiled_total+=fresh_loss+stored_loss
		var horizon:=(week+1)*7
		if week==3 or week==12:
			var ending_need:=maxf(0.01,required/7.0)
			var summary:={"horizon":30 if week==3 else 90,"ending_rations":fresh+stored,"ending_days":(fresh+stored)/ending_need,"first_shortage_day":first_shortage,"average_production":produced_total/float(horizon),"average_required":required_total/float(horizon),"spoilage":spoiled_total}
			result[30 if week==3 else 90]=summary
	return result

## A cached outlook seen some days later: the shortage is that much nearer.
func _aged_forecast(summary:Dictionary,aged:int)->Dictionary:
	var result:=summary.duplicate()
	var shortage:=int(result.get("first_shortage_day",-1))
	if shortage>0:result["first_shortage_day"]=maxi(1,shortage-aged)
	return result

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
	WorldSimulation.state.food_stocks[STORED]=float(WorldSimulation.state.food_stocks.get(STORED,0.0))+received
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
