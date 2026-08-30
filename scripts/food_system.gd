extends Node

# Food is measured internally in adult-equivalent daily rations. One ration is
# displayed as roughly 2,400 kcal, but actual demand is calculated citizen by
# citizen from age, work, pregnancy, lactation, travel, and climate.

const KCAL_PER_RATION := 2400.0
const FOOD_TYPES := ["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]
const SPOILAGE := {
	"Fresh plants":0.022,
	"Fresh meat":0.045,
	"Fish":0.060,
	"Dry staples":0.0012,
	"Preserved food":0.00035
}

var initialized := false

func reset_for_new_world()->void:
	initialized=false

func initialize() -> void:
	if initialized and not GameState.food_stocks.is_empty():
		return
	initialized=true
	if GameState.food_stocks.is_empty():
		var existing:=float(GameState.resource_stockpiles.get("Food",GameState.population_exact*30.0))
		GameState.food_stocks={
			"Fresh plants":existing*0.01,
			"Fresh meat":existing*0.01,
			"Fish":0.0,
			"Dry staples":existing*0.58,
			"Preserved food":existing*0.40
		}
	_sync_total()

func process_day(context: Dictionary,labor_efficiency: float,ecology: float) -> Dictionary:
	initialize()
	var traveling:=bool(context.get("traveling",GameState.convoy_traveling))
	var workers:=float(GameState.population_allocations.get("Food",0))
	var logistics:=float(GameState.population_allocations.get("Logistics",0))
	var makers:=float(GameState.population_allocations.get("Crafting",0))
	var military_campaign:=get_node_or_null("/root/MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("civilian_crafting_fraction"):
		makers*=clampf(float(military_campaign.civilian_crafting_fraction()),0.0,1.0)
	var demand_breakdown:=_calculate_demand(traveling)
	var harvest:=_produce(workers,labor_efficiency,ecology,traveling)
	for food_type in harvest:
		GameState.food_stocks[food_type]=float(GameState.food_stocks.get(food_type,0.0))+float(harvest[food_type])
	var preserved:=_preserve(logistics,makers,traveling)
	var spoilage:=_spoil(traveling)
	var storage_loss:=_apply_storage_capacity()
	for food_type in storage_loss:
		spoilage[food_type]=float(spoilage.get(food_type,0.0))+float(storage_loss[food_type])
	var demand:=float(demand_breakdown.total)
	var army_required:=float(demand_breakdown.get("army_field",0.0))
	var provision_delivery_ratio:=1.0
	if military_campaign!=null and military_campaign.has_method("field_provision_delivery_ratio"):
		provision_delivery_ratio=clampf(float(military_campaign.field_provision_delivery_ratio()),0.0,1.0)
	var army_accessible:=army_required*provision_delivery_ratio
	var accessible_demand:=maxf(0.0,demand-army_required+army_accessible)
	var consumed:=_consume(accessible_demand)
	var eaten:=0.0
	for amount in consumed.values(): eaten+=float(amount)
	var intake_ratio:=clampf(eaten/maxf(0.01,demand),0.0,1.0)
	var accessible_intake:=clampf(eaten/maxf(0.01,accessible_demand),0.0,1.0)
	var army_delivered:=army_accessible*accessible_intake
	if military_campaign!=null and military_campaign.has_method("record_daily_provisions"):
		military_campaign.record_daily_provisions(army_required,army_delivered)
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
	var forecast_30:=_forecast(30,harvest,demand_breakdown,traveling,provision_delivery_ratio)
	var forecast_90:=_forecast(90,harvest,demand_breakdown,traveling,provision_delivery_ratio)
	var result:={
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
		"nutrition_reserve":GameState.nutrition_reserve,
		"malnutrition_burden":GameState.malnutrition_burden,
		"food_stocks":GameState.food_stocks.duplicate(true),
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
	GameState.food_history.append({
		"day":int(GameState.elapsed_days),"stored":total,"produced":production_total,
		"required":demand,"eaten":eaten,"spoiled":spoilage_total,"net":net,
		"diet_quality":diet_quality,"intake_ratio":intake_ratio
	})
	if GameState.food_history.size()>370: GameState.food_history.pop_front()
	_sync_total()
	return result

func _calculate_demand(traveling: bool) -> Dictionary:
	var base:=0.0
	var labor:=0.0
	var pregnancy:=0.0
	var lactation:=0.0
	var travel:=0.0
	var climate:=0.0
	var prisoner_custody:=0.0
	var army_field:=0.0
	var active_pregnancies:Dictionary={}
	for record in GameState.active_pregnancies():
		active_pregnancies[int(record.get("mother_id",-1))]=record
	var day:=int(GameState.elapsed_days)
	var season_wave:=sin(fmod(GameState.elapsed_days,365.0)/365.0*TAU)
	var climate_factor:=maxf(0.0,-season_wave)*0.06
	for person in GameState.living_citizens():
		var age_days:=maxi(0,day-int(person.get("birth_day",day)))
		var age:=float(age_days)/365.0
		var need:=_age_need(age)
		base+=need
		var role:=String(person.get("role","Unassigned"))
		var work_extra:=need*float({
			"Food":0.17,"Extraction":0.18,"Construction":0.18,"Defense":0.12,
			"Survey":0.13,"Logistics":0.14,"Crafting":0.08,"Knowledge":0.04,
			"Administration":0.04
		}.get(role,0.02))
		labor+=work_extra
		if String(person.get("army_status","civilian"))=="active": army_field+=need+work_extra+need*climate_factor+(need*0.12 if traveling else 0.0)
		if active_pregnancies.has(int(person.get("id",-1))):
			var gestation:=day-int((active_pregnancies[int(person.id)] as Dictionary).get("conception_day",day))
			pregnancy+=0.05 if gestation<91 else (0.12 if gestation<182 else 0.20)
		elif age>=15.0 and age<=49.9 and day-int(person.get("last_birth_day",-100000))<=365:
			lactation+=0.21
		if traveling:
			travel+=need*0.12
		climate+=need*climate_factor
	var military_campaign:=get_node_or_null("/root/MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("prisoner_food_demand"):
		prisoner_custody=maxf(0.0,float(military_campaign.prisoner_food_demand()))
	var ration_factor:=1.0-_modifier_strength("rationing")*0.30
	var pre_ration:=base+labor+pregnancy+lactation+travel+climate+prisoner_custody
	return {
		"base":base,"labor":labor,"pregnancy":pregnancy,"lactation":lactation,
		"travel":travel,"climate":climate,"prisoner_custody":prisoner_custody,"army_field":army_field*ration_factor,"rationing":pre_ration*(1.0-ration_factor),
		"total":pre_ration*ration_factor
	}

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
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
	if workers<=0.0: return result
	var access:=_food_resource_access()
	var fishing_weight:=0.16 if float(access.freshwater)>0.0 else 0.0
	var cultivation_weight:=0.0
	if "seed_selection" in GameState.known_discoveries and GameState.settlement_site_committed:
		cultivation_weight=(0.34+float(access.fertile)*0.10)*maxf(0.05,DiscoverySystem.adoption("seed_selection"))
	var remaining:=maxf(0.0,1.0-fishing_weight-cultivation_weight)
	var hunting_weight:=remaining*(0.31+float(access.game)*0.09)
	var gathering_weight:=maxf(0.0,remaining-hunting_weight)
	var plant_season:=_season_factor("Fresh plants",GameState.elapsed_days)
	var game_season:=_season_factor("Fresh meat",GameState.elapsed_days)
	var fish_season:=_season_factor("Fish",GameState.elapsed_days)
	var crop_season:=_season_factor("Dry staples",GameState.elapsed_days)
	var terrain:=String(GameState.province_terrain)
	var terrain_gather:=float({"Plains":1.04,"Forest":1.12,"Hills":0.91,"Mountains":0.68,"Marsh":0.96}.get(terrain,0.90))
	var terrain_hunt:=float({"Plains":0.96,"Forest":1.12,"Hills":1.02,"Mountains":0.78,"Marsh":0.82}.get(terrain,0.90))
	var efficiency:=lerpf(0.76,1.08,clampf(labor_efficiency,0.0,1.0))
	var ecological:=lerpf(0.58,1.04,clampf(ecology,0.0,1.0))
	var practice:=1.0
	practice+=DiscoverySystem.effect("foraging_yield")
	practice+=DiscoverySystem.effect("food_output")
	practice+=_modifier_strength("abundant_game")-_modifier_strength("lean_harvest")
	practice+=_modifier_strength("foraging_drive")*0.42-_modifier_strength("conservation_order")*0.18
	var rng:=RandomNumberGenerator.new()
	rng.seed=GameState.world_seed^int(GameState.elapsed_days+1.0)*7919
	var variation:=rng.randf_range(0.93,1.07)
	var route_factor:=0.48+clampf(float(GameState.population_allocations.get("Logistics",0))/maxf(1.0,GameState.population_exact*0.08),0.0,1.0)*0.08 if traveling else 1.0
	result["Fresh plants"]=workers*gathering_weight*4.55*terrain_gather*plant_season*efficiency*ecological*float(GameState.food_source_health.get("Wild gathering",0.9))*practice*variation*route_factor
	result["Fresh meat"]=workers*hunting_weight*4.85*terrain_hunt*game_season*efficiency*ecological*float(GameState.food_source_health.get("Hunting",0.9))*(1.0+float(access.game)*0.18)*(1.0+DiscoverySystem.effect("hunting_yield"))*practice*variation*route_factor
	result["Fish"]=workers*fishing_weight*5.00*fish_season*efficiency*float(GameState.food_source_health.get("Fishing",0.9))*(0.82+float(access.freshwater)*0.28)*practice*variation*route_factor
	if cultivation_weight>0.0 and not traveling:
		result["Dry staples"]=workers*cultivation_weight*5.65*crop_season*efficiency*float(GameState.food_source_health.get("Cultivation",0.9))*(0.82+float(access.fertile)*0.30)*(1.0+DiscoverySystem.effect("soil_productivity")+DiscoverySystem.effect("cultivation_yield"))*variation
	return result

func _food_resource_access() -> Dictionary:
	var result:={"game":0.0,"freshwater":0.0,"fertile":0.0}
	for deposit in GameState.resource_deposits:
		if String(deposit.get("stage","unknown")) not in ["accessible","developed"]: continue
		var key:=String(deposit.get("resource","")).to_lower()
		if key=="game": result.game=maxf(float(result.game),float(deposit.get("quality",0.7)))
		elif key=="freshwater": result.freshwater=maxf(float(result.freshwater),float(deposit.get("quality",0.7)))
		elif key=="fertile soil": result.fertile=maxf(float(result.fertile),float(deposit.get("quality",0.7)))
	return result

func _preserve(logistics: float,makers: float,traveling: bool) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0}
	if traveling: return result
	var capacity:=(logistics*0.16+makers*0.18)*(1.0+DiscoverySystem.effect("food_storage"))
	if "food_drying" in GameState.known_discoveries:
		var plant_amount:=minf(float(GameState.food_stocks.get("Fresh plants",0.0)),capacity*0.55*maxf(0.05,DiscoverySystem.adoption("food_drying")))
		GameState.food_stocks["Fresh plants"]-=plant_amount
		GameState.food_stocks["Dry staples"]+=plant_amount*0.88
		result["Fresh plants"]=plant_amount
		capacity=maxf(0.0,capacity-plant_amount)
	if "smoking" in GameState.known_discoveries and capacity>0.0:
		for food_type in ["Fresh meat","Fish"]:
			var amount:=minf(float(GameState.food_stocks.get(food_type,0.0)),capacity*0.5*maxf(0.05,DiscoverySystem.adoption("smoking")))
			GameState.food_stocks[food_type]-=amount
			GameState.food_stocks["Preserved food"]+=amount*0.82
			result[food_type]=amount
	return result

func _spoil(traveling: bool) -> Dictionary:
	var result:={}
	var storage_multiplier:=0.72 if "Storage Pits" in GameState.settlement_completed else 1.0
	storage_multiplier*=maxf(0.30,1.0+DiscoverySystem.effect("food_spoilage"))
	if traveling: storage_multiplier*=1.28
	for food_type in FOOD_TYPES:
		var amount:=float(GameState.food_stocks.get(food_type,0.0))
		var loss:=amount*float(SPOILAGE[food_type])*storage_multiplier
		GameState.food_stocks[food_type]=maxf(0.0,amount-loss)
		result[food_type]=loss
	return result

func _apply_storage_capacity() -> Dictionary:
	var losses:={}
	var capacity:=GameState.population_exact*(120.0 if "Storage Pits" in GameState.settlement_completed else 36.0)
	var excess:=maxf(0.0,_stock_total()-capacity)
	for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]:
		if excess<=0.0: break
		var discard:=minf(excess,float(GameState.food_stocks.get(food_type,0.0)))
		GameState.food_stocks[food_type]-=discard
		losses[food_type]=discard
		excess-=discard
	return losses

func _consume(required: float) -> Dictionary:
	var result:={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
	var remaining:=required
	# Perishables are used first. A small preserved share is deliberately opened
	# each day so a stocked convoy does not report a nutritionally empty diet.
	for food_type in ["Fish","Fresh meat","Fresh plants","Dry staples","Preserved food"]:
		var available:=float(GameState.food_stocks.get(food_type,0.0))
		var amount:=minf(remaining,available)
		GameState.food_stocks[food_type]=available-amount
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
	return clampf(0.24+minf(plant_share,0.48)*0.65+minf(protein_share,0.30)*0.95+diversity*0.22+DiscoverySystem.effect("nutrition_quality"),0.05,1.0)

func _update_nutrition(intake_ratio: float,diet_quality: float) -> void:
	var reserve_delta:=(intake_ratio-0.94)*0.010+(diet_quality-0.55)*0.0018
	GameState.nutrition_reserve=clampf(GameState.nutrition_reserve+reserve_delta,0.0,1.0)
	var burden_target:=clampf((1.0-intake_ratio)*0.68+(0.58-diet_quality)*0.24+(0.28-GameState.nutrition_reserve)*0.45,0.0,1.0)
	GameState.malnutrition_burden=lerpf(GameState.malnutrition_burden,burden_target,0.045 if burden_target>GameState.malnutrition_burden else 0.012)

func _update_source_health(harvest: Dictionary,workers: float,traveling: bool) -> void:
	var able:=maxf(1.0,float(GameState.able_population()))
	var pressure:=workers/able
	var recovery:=(0.0007 if traveling else 0.00035)*(1.0+DiscoverySystem.effect("ecology_recovery"))
	var mapping:={"Wild gathering":"Fresh plants","Hunting":"Fresh meat","Fishing":"Fish","Cultivation":"Dry staples"}
	for source in mapping:
		var current:=float(GameState.food_source_health.get(source,0.9))
		var used:=float(harvest.get(mapping[source],0.0))>0.01
		var damage:=maxf(0.0,pressure-0.42)*0.0018*(1.0+DiscoverySystem.effect("ecological_pressure")) if used else 0.0
		if source=="Cultivation" and used: damage=maxf(0.0,pressure-0.55)*0.0011
		GameState.food_source_health[source]=clampf(current+recovery-damage,0.12,1.0)

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
		if entry[0]=="Cultivation" and "seed_selection" not in GameState.known_discoveries: status="practice not discovered"
		reports.append({"name":entry[0],"food_type":entry[1],"produced":amount,"resource":entry[2],"access":status,"source_health":float(GameState.food_source_health.get(entry[0],0.9)),"travel_limited":traveling})
	return reports

func _forecast(horizon: int,current_harvest: Dictionary,demand_breakdown: Dictionary,traveling: bool,provision_delivery_ratio:=1.0) -> Dictionary:
	var projected_stocks:Dictionary=GameState.food_stocks.duplicate(true)
	var current_day:=GameState.elapsed_days
	var pre_ration_current:=float(demand_breakdown.get("total",0.0))+float(demand_breakdown.get("rationing",0.0))
	var non_climate:=maxf(0.0,pre_ration_current-float(demand_breakdown.get("climate",0.0)))
	var ration_factor:=1.0-_modifier_strength("rationing")*0.30
	var inaccessible_army_rations:=float(demand_breakdown.get("army_field",0.0))*(1.0-clampf(provision_delivery_ratio,0.0,1.0))
	var first_shortage:=-1
	var total_produced:=0.0
	var total_required:=0.0
	var total_spoiled:=0.0
	for offset in range(1,horizon+1):
		var future_day:=current_day+float(offset)
		for food_type in ["Fresh plants","Fresh meat","Fish","Dry staples"]:
			var current_season:=maxf(0.05,_season_factor(food_type,current_day))
			var future_season:=_season_factor(food_type,future_day)
			var future_yield:=float(current_harvest.get(food_type,0.0))*future_season/current_season
			projected_stocks[food_type]=float(projected_stocks.get(food_type,0.0))+future_yield
			total_produced+=future_yield
		var season_wave:=sin(fmod(future_day,365.0)/365.0*TAU)
		var future_climate:=non_climate*maxf(0.0,-season_wave)*0.06
		var future_required:=maxf(0.0,(non_climate+future_climate)*ration_factor-inaccessible_army_rations)
		total_required+=future_required
		var storage_multiplier:=0.72 if "Storage Pits" in GameState.settlement_completed else 1.0
		if traveling: storage_multiplier*=1.28
		for food_type in FOOD_TYPES:
			var amount:=float(projected_stocks.get(food_type,0.0))
			var loss:=amount*float(SPOILAGE[food_type])*storage_multiplier
			projected_stocks[food_type]=maxf(0.0,amount-loss)
			total_spoiled+=loss
		var eaten:=_consume_projection(projected_stocks,future_required)
		if eaten<future_required*0.98 and first_shortage<0: first_shortage=offset
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
	var day_of_year:=fmod(day,365.0)
	var wave:=sin(day_of_year/365.0*TAU)
	match food_type:
		"Fresh plants": return clampf(0.92+wave*0.48,0.36,1.42)
		"Fresh meat": return clampf(0.96-wave*0.12,0.74,1.14)
		"Fish": return clampf(0.94+sin(day_of_year/365.0*TAU+0.8)*0.20,0.68,1.18)
		"Dry staples": return clampf(0.72+wave*0.68,0.05,1.48)
	return 1.0

func _stock_total() -> float:
	var total:=0.0
	for amount in GameState.food_stocks.values(): total+=float(amount)
	return total

func _sync_total() -> void:
	GameState.resource_stockpiles["Food"]=_stock_total()

func _modifier_strength(effect_id: String) -> float:
	var engine:=get_node_or_null("/root/ConsequenceEngine")
	if engine and engine.has_method("modifier_strength"):
		return float(engine.call("modifier_strength",effect_id))
	return 0.0
