extends RefCounted
## Expansion caravans — settler parties formed in an established settlement from
## real people and real stores, led by a caravan leader, marched over the map by
## the same brain as the founding journey (caravan_leader.gd), and founding the
## new settlement on arrival through SettlementModel.complete_settlement_convoy.
##
## The caravan lives inside GameState.settlement_convoy["caravan"], so saves keep
## their format and every existing reader of settlement_convoy (population
## shares, labor absence, map marker) keeps working. One expansion caravan is in
## flight per civilization, as before; the founding journey is the first caravan.
##
## The travelling party's food, water, health and deaths are simulated here,
## at its actual map position each day: carried rations and waterskins are
## consumed, refilled at water and supplemented by foraging. Deaths reduce the
## real aggregate population (never a free loss or a free survival).

const Leader:=preload("res://scripts/caravan_leader.gd")
const SPEED_KM_DAY:=16.0
const ESTABLISHMENT_DAYS:=45.0
const MIN_FOUNDERS:=40
const REMAIN_AT_ORIGIN:=80
const VESSEL_DAYS:=3.0
const AUDIENCE_SCRIPT:="res://scripts/audience_hall.gd"

# --------------------------------------------------------------- formation

## The leader's formation advice: founders bounds, route plan and suggested
## rations for one proposed destination. party: population, food,
## leader_person_id (all optional).
static func formation(origin:Vector2,destination:Vector2,available_people:float,party:Dictionary={})->Dictionary:
	var leader:=Leader.choose_leader(int(party.get("leader_person_id",0)),"expansion")
	var max_founders:=maxi(0,roundi(available_people)-REMAIN_AT_ORIGIN)
	var default_founders:=mini(maxi(MIN_FOUNDERS,roundi(available_people*0.02)),max_founders)
	var founders:=clampi(int(party.get("population",default_founders)),MIN_FOUNDERS,maxi(MIN_FOUNDERS,max_founders))
	var plan:=Leader.plan_route(origin,destination,{"daily_km":SPEED_KM_DAY,"vessel_days":VESSEL_DAYS,"competency":float(leader.competency),"start_water_days":VESSEL_DAYS})
	var travel_days:=float(plan.get("days",origin.distance_to(destination)/SPEED_KM_DAY))
	var suggested:=float(founders)*(travel_days*Leader.food_margin(float(leader.competency))+ESTABLISHMENT_DAYS)
	var minimum:=float(founders)*travel_days*0.6
	var advice:=String(plan.get("summary","")) if bool(plan.get("ok",false)) else String(plan.get("reason",""))
	return {
		"leader":leader,"plan":plan,"ok":bool(plan.get("ok",false)),"founders":founders,"default_founders":default_founders,
		"min_founders":MIN_FOUNDERS,"max_founders":max_founders,"travel_days":travel_days,
		"suggested_food":suggested,"minimum_food":minimum,"advice":advice,
	}

## The leader's plain-words judgment of a party's route and rations.
static func rations_comment(formation:Dictionary,population:int,food:float)->String:
	var leader:Dictionary=formation.get("leader",{})
	var name:=String(leader.get("name","The caravan leader"))
	var advice:=String(formation.get("advice",""))
	if not bool(formation.get("ok",false)):return "%s: %s" % [name,advice]
	var travel_days:=float(formation.get("travel_days",1.0))
	var per_person:=food/maxf(1.0,float(population))
	var minimum:=float(population)*travel_days*0.6
	var verdict:=""
	if food+0.01<minimum:verdict="I will not lead them out with fewer than %.0f rations." % minimum
	elif per_person<travel_days*1.1:verdict="Rations are thin for a %s march; I will camp to forage along the way, which will make the journey longer." % Leader._days_words(travel_days)
	elif per_person<travel_days+ESTABLISHMENT_DAYS*0.5:verdict="Enough for the march, but little to spare once we arrive."
	else:verdict="Enough for the march and about %.0f days to establish the new home." % maxf(0.0,per_person-travel_days)
	return "%s: %s %s" % [name,advice,verdict]

## Called by SettlementModel before anything leaves the origin: the leader must
## accept the route and the rations. Returns {ok,reason,leader,plan}.
static func prepare(quote:Dictionary,party:Dictionary)->Dictionary:
	var origin:Vector2=quote.get("origin",Vector2.ZERO)
	var destination:Vector2=quote.get("destination",origin)
	var leader:=Leader.choose_leader(int(party.get("leader_person_id",0)),"expansion")
	var plan:Dictionary=party.get("plan",{})
	if plan.is_empty() or (plan.get("path",[]) as Array).is_empty() or (plan.path[0] as Vector2).distance_to(origin)>0.05 or (plan.path[-1] as Vector2).distance_to(destination)>0.05:
		plan=Leader.plan_route(origin,destination,{"daily_km":SPEED_KM_DAY,"vessel_days":VESSEL_DAYS,"competency":float(leader.competency),"start_water_days":VESSEL_DAYS})
	if not bool(plan.get("ok",false)):
		return {"ok":false,"reason":"%s refuses: %s" % [String(leader.name),String(plan.get("reason","we cannot reach that ground."))],"leader":leader,"plan":plan,"alternative":plan.get("alternative")}
	var founders:=float(quote.get("population",MIN_FOUNDERS))
	var food:=float(quote.get("food",0.0))
	var minimum:=founders*float(plan.get("days",0.5))*0.6
	if food+0.01<minimum:
		return {"ok":false,"reason":"%s will not lead %d people into a %s march with rations for %.0f days. Carry at least %.0f." % [String(leader.name),roundi(founders),Leader._days_words(float(plan.days)),food/maxf(1.0,founders),minimum],"leader":leader,"plan":plan}
	return {"ok":true,"leader":leader,"plan":plan}

## Builds the caravan record for a convoy that has just departed.
static func attach(convoy:Dictionary,leader:Dictionary,plan:Dictionary)->Dictionary:
	var origin:Vector2=convoy.get("origin",Vector2.ZERO)
	var destination:Vector2=convoy.get("destination",origin)
	var record:=Leader.new_record("expansion",leader,origin,destination,plan,float(WorldSimulation.state.elapsed_days))
	var population:=int(convoy.get("population",MIN_FOUNDERS))
	record["population"]=population
	record["population_start"]=population
	record["food"]=float(convoy.get("food_committed",0.0))
	record["food_start"]=float(record.food)
	record["water_capacity"]=float(population)*VESSEL_DAYS
	record["water"]=float(record.water_capacity)
	record["health"]=0.86
	record["death_progress"]=0.0
	record["water_short_days"]=0.0
	record["food_short_days"]=0.0
	record["origin_id"]=String(convoy.get("origin_id",""))
	Leader.departure(record,situation(record,1.0))
	convoy["caravan"]=record
	convoy["duration_days"]=maxf(maxf(0.5,float(convoy.get("duration_days",0.5))),float(plan.get("days",0.5)))
	convoy["arrival_day"]=float(convoy.get("depart_day",WorldSimulation.state.elapsed_days))+float(convoy.duration_days)
	return record

## Old saves: a settlement convoy on the road without a leader gains one. The
## legacy ledger assumed a ration per person-day already eaten; the rest is in
## the carts. Waterskins are assumed filled at the last water.
static func ensure(convoy:Dictionary)->Dictionary:
	var caravan:Dictionary=convoy.get("caravan",{})
	if not caravan.is_empty() or not bool(convoy.get("active",false)):return caravan
	var here:=_vector(convoy.get("position",convoy.get("origin",Vector2.ZERO)))
	var destination:=_vector(convoy.get("destination",here))
	var leader:=Leader.choose_leader(0,"expansion")
	var plan:=Leader.plan_route(here,destination,{"daily_km":SPEED_KM_DAY,"vessel_days":VESSEL_DAYS,"competency":float(leader.competency),"start_water_days":VESSEL_DAYS})
	if not bool(plan.get("ok",false)):
		plan=Leader._finish_plan([here,destination],Leader.profile_path([here,destination]),"direct",{"safe_dry_km":0.0,"daily_km":SPEED_KM_DAY,"vessel_days":VESSEL_DAYS,"direct_km":here.distance_to(destination),"direct_longest_dry_km":0.0},{"skip_route_provider":true})
	var record:=Leader.new_record("expansion",leader,here,destination,plan,float(WorldSimulation.state.elapsed_days))
	record["home"]=_vector(convoy.get("origin",here))
	var population:=int(convoy.get("population",MIN_FOUNDERS))
	var travelled:=maxf(0.0,float(WorldSimulation.state.elapsed_days)-float(convoy.get("depart_day",WorldSimulation.state.elapsed_days)))
	record["population"]=population
	record["population_start"]=population
	record["food"]=maxf(0.0,float(convoy.get("food_committed",0.0))-float(population)*travelled)
	record["food_start"]=float(record.food)
	record["water_capacity"]=float(population)*VESSEL_DAYS
	record["water"]=float(record.water_capacity)
	record["health"]=0.82
	record["death_progress"]=0.0
	record["water_short_days"]=0.0
	record["food_short_days"]=0.0
	record["origin_id"]=String(convoy.get("origin_id",""))
	Leader.report(record,"departure","A caravan leader takes charge","%s now leads the settlers to %s. %s" % [String(leader.name),String(convoy.get("settlement_name","the new ground")),String(record.summary)],"notice",true,"migrated")
	convoy["caravan"]=record
	# The legacy food ledger is now carried explicitly; arrival hands over what remains.
	convoy["food_ledger"]="caravan"
	return record

# --------------------------------------------------------------- daily march

static func situation(record:Dictionary,days:float)->Dictionary:
	var population:=maxf(1.0,float(record.get("population",1)))
	var here:=Leader.position(record)
	var forage_moving:=clampf(Leader.forage_at(here)*0.40,0.0,0.6)
	var food_days:=float(record.get("food",0.0))/population
	var supported:=food_days/maxf(0.08,1.0-forage_moving)
	var health:=float(record.get("health",0.85))
	var factor:=clampf(0.30+health*0.70,0.3,1.0)
	return {
		"population":population,"water_days":float(record.get("water",0.0))/population,
		"water_capacity_days":maxf(0.5,float(record.get("water_capacity",population*VESSEL_DAYS))/population),
		"supported_days":supported,"food_days":food_days,"health":health,
		"daily_km":SPEED_KM_DAY*float(record.get("speed_scale",1.0))*factor,"days":days,"day":float(WorldSimulation.state.elapsed_days),
	}

## One calendar step for the owner's expansion caravan. Returns the founding
## result on arrival (same shape as complete_settlement_convoy), or {}.
static func advance(days:float)->Dictionary:
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	if not bool(convoy.get("active",false)):return {}
	var record:=ensure(convoy)
	var whole:=maxi(1,roundi(days))
	for _day_index in whole:
		var mode:=String(record.get("mode","marching"))
		if mode in ["arrived","returned"]:break
		_consume_day(convoy,record)
		if not bool(convoy.get("active",false)):return {}
		var step:=Leader.step(record,situation(record,1.0))
		var here:=Leader.position(record)
		convoy["position"]=here
		convoy["progress"]=Leader.progress_ratio(record) if not bool(record.get("returning",false)) else 0.0
		convoy["phase"]="traveling"
		if bool(step.get("returned",false)):
			return _dissolve_home(convoy,record)
		if bool(step.get("arrived",false)):
			convoy["progress"]=1.0
			convoy["phase"]="arrived"
			convoy["arrival_day"]=float(WorldSimulation.state.elapsed_days)
			convoy["duration_days"]=maxf(0.5,float(WorldSimulation.state.elapsed_days)-float(convoy.get("depart_day",0.0)))
			convoy["position"]=_vector(convoy.get("destination",here))
			WorldSimulation.state.settlement_convoy=convoy
			var completed:Dictionary=WorldSimulation.settlements.complete_settlement_convoy(_vector(convoy.get("destination",here)))
			if bool(completed.get("ok",false)):
				completed["caravan"]=record
				_install_leader(completed,record)
			return completed
	var remaining_days:=Leader.remaining_km(record)/maxf(1.0,float(situation(record,1.0).daily_km))
	convoy["arrival_day"]=float(WorldSimulation.state.elapsed_days)+remaining_days
	convoy["caravan"]=record
	WorldSimulation.state.settlement_convoy=convoy
	return {}

## Real consumption at the caravan's present position.
static func _consume_day(convoy:Dictionary,record:Dictionary)->void:
	var population:=maxf(1.0,float(record.get("population",1)))
	var here:=Leader.position(record)
	var data:=Leader.sample(here)
	var mode:=String(record.get("mode","marching"))
	var camped:=mode in Leader.CAMP_MODES or mode=="held"
	# Water: households fetch from a nearby source; a camp at the water refills
	# the waterskins. Beyond six kilometres only the skins remain.
	var water_km:=float(data.get("water_km",-1.0))
	var source_ratio:=1.18
	if water_km>=0.0:
		source_ratio=0.0 if water_km>6.0 else (1.18 if water_km<=1.0 else lerpf(1.18,0.38,(water_km-1.0)/5.0))
	var collected:=population*source_ratio*(1.0 if camped else 0.85)
	if camped and source_ratio>=1.0:collected+=population*0.6
	var capacity:=float(record.get("water_capacity",population*VESSEL_DAYS))
	var water_available:=float(record.get("water",0.0))+collected
	var drink:=minf(population,water_available)
	record["water"]=clampf(water_available-drink,0.0,capacity)
	var water_intake:=drink/population
	# Food: carried rations plus what the party can gather on this ground.
	var forage:=Leader.forage_at(here)
	# A camp sends hunting, fishing and gathering parties out; on the march the
	# people take only what lies along the way.
	var gathered:=population*clampf(forage*(1.55 if camped else 0.40),0.0,1.4)
	var food_available:=float(record.get("food",0.0))+gathered
	var eaten:=minf(population,food_available)
	record["food"]=maxf(0.0,food_available-eaten)
	record["food_gathered"]=float(record.get("food_gathered",0.0))+gathered
	record["food_eaten"]=float(record.get("food_eaten",0.0))+eaten
	var food_intake:=eaten/population
	record["water_short_days"]=float(record.get("water_short_days",0.0))+1.0 if water_intake<0.98 else maxf(0.0,float(record.get("water_short_days",0.0))-2.0)
	record["food_short_days"]=float(record.get("food_short_days",0.0))+1.0 if food_intake<0.95 else maxf(0.0,float(record.get("food_short_days",0.0))-2.0)
	var target:=0.86-(1.0-food_intake)*0.55-(1.0-water_intake)*0.9-(0.0 if camped else 0.04)
	var health:=float(record.get("health",0.85))
	record["health"]=clampf(lerpf(health,target,0.12 if target<health else 0.06),0.02,0.97)
	# The same curves the settled simulation uses for dehydration and hunger.
	var water_deficit:=clampf(1.0-water_intake,0.0,1.0)
	var water_ramp:=clampf((float(record.water_short_days)-1.0)/4.0,0.0,1.0)
	var food_ramp:=clampf((float(record.food_short_days)-5.0)/45.0,0.0,1.0)
	var annual_rate:=pow(water_deficit,3.0)*(0.35+water_ramp*5.0)+maxf(0.0,1.0-food_intake)*(0.08+food_ramp*0.90)+maxf(0.0,0.50-float(record.health))*0.055
	record["death_progress"]=float(record.get("death_progress",0.0))+population*annual_rate/365.0
	var deaths:=floori(float(record.death_progress))
	if deaths>0:
		record["death_progress"]=float(record.death_progress)-float(deaths)
		var cause:="Dehydration" if water_deficit>0.1 else ("Hunger" if food_intake<0.95 else "Illness")
		_apply_deaths(convoy,record,deaths,cause)

## Deaths on the road leave the aggregate population. Every settlement keeps
## its own headcount; only the caravan's share shrinks.
static func _apply_deaths(convoy:Dictionary,record:Dictionary,deaths:int,cause:String)->void:
	var state=WorldSimulation.state
	var population:=int(record.get("population",1))
	var count:=mini(deaths,maxi(0,population-1))
	if count<=0:return
	var before:=maxf(1.0,float(state.population_exact))
	var result:Dictionary=state.register_population_deaths(count,"%s on the road" % cause)
	var removed:=int(result.get("count",count))
	var after:=maxf(1.0,float(state.population_exact))
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):continue
		city["population_share"]=float(city.get("population_share",0.0))*before/after
	convoy["population_share"]=maxf(0.0,float(convoy.get("population_share",0.0))*before-float(removed))/after
	record["population"]=population-removed
	record["deaths"]=int(record.get("deaths",0))+removed
	convoy["population"]=int(record.population)
	if int(record.deaths)==removed or removed>=maxi(1,population/20):
		Leader.report(record,"loss","Losses on the road","%d of the settlers died of %s. %s" % [removed,cause.to_lower(),"We make for water now." if cause=="Dehydration" else "I am doing what the ground allows."],"danger",true,"loss_%d" % int(state.elapsed_days))

## The public figure who led the settlers is the natural first leader of the
## place they founded. The cast's own rules decide; a refusal changes nothing.
static func _install_leader(completed:Dictionary,record:Dictionary)->void:
	var person_id:=int((record.get("leader",{}) as Dictionary).get("person_id",0))
	var settlement:Dictionary=completed.get("settlement",{})
	var government:Object=WorldSimulation.government
	if person_id<=0 or settlement.is_empty() or government==null or not government.has_method("assign_settlement_leader"):return
	var assigned:Variant=government.call("assign_settlement_leader",String(settlement.get("id","")),person_id)
	if assigned is Dictionary and bool((assigned as Dictionary).get("ok",false)):completed["leader_installed"]=true

## A recalled caravan home again: people rejoin the origin, carried stores
## return to its storehouses, and the convoy slot is free.
static func _dissolve_home(convoy:Dictionary,record:Dictionary)->Dictionary:
	var origin_id:=String(convoy.get("origin_id",""))
	var origin:Dictionary=WorldSimulation.settlements.settlement_record(origin_id)
	if not origin.is_empty() and not bool(origin.get("primary",false)):
		origin["population_share"]=float(origin.get("population_share",0.0))+float(convoy.get("population_share",0.0))
	var food:=float(record.get("food",0.0))
	var materials:Dictionary=convoy.get("materials_committed",{})
	if not origin_id.is_empty():
		WorldSimulation.settlements.with_city_resources(origin_id,func()->void:
			WorldSimulation.food.receive_external_food(food)
			for resource_name:String in materials:
				WorldSimulation.state.resource_stockpiles[resource_name]=float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))+float(materials[resource_name])
		)
	WorldSimulation.state.settlement_convoy={}
	WorldSimulation.state.settlement_network_revision+=1
	return {"ok":false,"returned":true,"caravan":record,"population":int(record.get("population",0)),"reason":"The caravan returned to %s." % String(convoy.get("origin_name","its home settlement"))}

# --------------------------------------------------------------- overrides

static func hold_expansion()->Dictionary:
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	var record:=ensure(convoy)
	if record.is_empty():return {"error":"No settlement caravan is on the road."}
	return {"ok":true,"message":Leader.hold(record)}

static func resume_expansion()->Dictionary:
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	var record:=ensure(convoy)
	if record.is_empty():return {"error":"No settlement caravan is on the road."}
	return {"ok":true,"message":Leader.resume(record,situation(record,1.0))}

static func recall_expansion()->Dictionary:
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	var record:=ensure(convoy)
	if record.is_empty():return {"error":"No settlement caravan is on the road."}
	return {"ok":true,"message":Leader.recall(record,situation(record,1.0))}

# --------------------------------------------------------------- presentation

## Status cards for every caravan of the current owner: the founding journey
## (while under way) and the expansion caravan.
static func status_cards()->Array[Dictionary]:
	var cards:Array[Dictionary]=[]
	var state=WorldSimulation.state
	var journey:Dictionary=state.founding_journey
	var founding:Dictionary=journey.get("caravan",{})
	if not founding.is_empty() and not bool(state.settlement_site_committed) and String(founding.get("mode",""))!="arrived":
		var travel:=preload("res://scripts/civilization_travel.gd").situation()
		var status:=Leader.status(founding)
		status["id"]="founding"
		status["title"]="FOUNDING CARAVAN"
		status["people"]=int(state.population_total)
		status["food_days"]=float(travel.supported_days)
		status["water_days"]=float(travel.water_days)
		status["health"]=float(travel.health)
		status["can_hold"]=String(founding.get("mode",""))!="held"
		status["can_resume"]=String(founding.get("mode",""))=="held" or String(founding.get("mode","")) in Leader.CAMP_MODES
		status["can_recall"]=false
		cards.append(status)
	var convoy:Dictionary=state.settlement_convoy
	if bool(convoy.get("active",false)):
		var record:=ensure(convoy)
		var status:=Leader.status(record)
		var now:=situation(record,1.0)
		status["id"]="expansion"
		status["title"]="SETTLER CARAVAN → %s" % String(convoy.get("settlement_name","NEW SETTLEMENT")).to_upper()
		status["people"]=int(record.get("population",convoy.get("population",0)))
		status["food_days"]=float(now.supported_days)
		status["water_days"]=float(now.water_days)
		status["health"]=float(now.health)
		status["can_hold"]=String(record.get("mode",""))!="held" and not bool(record.get("returning",false))
		status["can_resume"]=String(record.get("mode",""))=="held" or String(record.get("mode","")) in Leader.CAMP_MODES
		status["can_recall"]=not bool(record.get("returning",false))
		cards.append(status)
	return cards

## Leader reports waiting for the human ruler, oldest first.
static func drain_reports()->Array:
	var reports:Array=[]
	var journey:Dictionary=WorldSimulation.state.founding_journey
	var founding:Dictionary=journey.get("caravan",{})
	if not founding.is_empty():reports.append_array(Leader.drain_reports(founding))
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	var expansion:Dictionary=convoy.get("caravan",{})
	if not expansion.is_empty():reports.append_array(Leader.drain_reports(expansion))
	return reports

## Hands a major report to the audience hall when that system is present.
## Harmless when absent.
static func forward_to_audience(entry:Dictionary)->bool:
	if not ResourceLoader.exists(AUDIENCE_SCRIPT):return false
	var payload:={"kind":"report","speaker":String(entry.get("leader","The caravan leader")),"role":"Caravan leader","title":String(entry.get("title","")),"text":String(entry.get("text","")),"day":int(entry.get("day",0)),"source":"caravan","severity":String(entry.get("severity","notice"))}
	var loop:=Engine.get_main_loop()
	if loop is SceneTree:
		var node:=(loop as SceneTree).root.get_node_or_null("AudienceHall")
		if node!=null and node.has_method("enqueue"):
			node.call("enqueue",payload)
			return true
	var script:Resource=load(AUDIENCE_SCRIPT)
	if script is Script:
		for method:Dictionary in (script as Script).get_script_method_list():
			if String(method.get("name",""))=="enqueue" and int(method.get("flags",0))&METHOD_FLAG_STATIC!=0:
				script.call("enqueue",payload)
				return true
	return false

static func _vector(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Vector3:return Vector2((value as Vector3).x,(value as Vector3).z)
	if value is Dictionary:return Vector2(float((value as Dictionary).get("x",0.0)),float((value as Dictionary).get("y",(value as Dictionary).get("z",0.0))))
	return Vector2.ZERO
