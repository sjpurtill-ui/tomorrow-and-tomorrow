extends Node
## Headless behavioral probe for the caravan leader (founding journey and
## expansion caravans). Synthetic but physically consistent geography: the same
## water function drives the leader's planning AND the daily water ledger, so a
## caravan that camps in a dry place really goes thirsty.
##
## Prints CARAVAN_LEADER PASS and exits 0 when every scenario holds.

const Leader:=preload("res://scripts/caravan_leader.gd")
const Travel:=preload("res://scripts/civilization_travel.gd")
const Caravans:=preload("res://scripts/caravan_system.gd")
const Day:=preload("res://scripts/civilization_day.gd")

var failures:Array[String]=[]
var rivers:Array=[]
var springs:Array=[]
var summary:Array[String]=[]

func _ready()->void:
	call_deferred("run")

func run()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	Leader.geography_provider=Callable(self,"geo")
	Leader.forage_provider=Callable()
	WorldSimulation.context_provider=Callable(self,"context_at")
	WorldSimulation.route_provider=func(from:Vector3,to:Vector3)->Dictionary:
		return {"valid":true,"distance_km":Vector2(from.x,from.z).distance_to(Vector2(to.x,to.z)),"terrain_modifier":1.0}
	scenario_route_follows_river()
	scenario_low_provisions_camp_and_resume()
	scenario_straight_line_into_dry_country()
	scenario_impossible_trip_refused()
	scenario_expansion_caravan()
	scenario_old_save_migration()
	scenario_real_terrain_planning()
	for line in summary:print(line)
	if failures.is_empty():
		print("CARAVAN_LEADER PASS  route follows water, forage camps rebuild and resume, no dry halts or thirst deaths, impossible trip refused with reason, expansion caravan founds with conserved people/stores, old saves migrate")
		get_tree().quit(0)
	else:
		for failure in failures:push_error("CARAVAN_LEADER FAIL: "+failure)
		print("CARAVAN_LEADER FAIL (%d)" % failures.size())
		get_tree().quit(1)

func expect(condition:bool,message:String)->void:
	if not condition:failures.append(message)

# ------------------------------------------------------------ geography

func geo(point:Vector2)->Dictionary:
	var best:=INF
	for river:Array in rivers:
		for index in range(river.size()-1):
			var a:Vector2=river[index]
			var b:Vector2=river[index+1]
			best=minf(best,point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)))
	for spring:Vector3 in springs:
		best=minf(best,maxf(0.0,point.distance_to(Vector2(spring.x,spring.y))-spring.z))
	var lush:=clampf(1.0-best/8.0,0.0,1.0)
	return {"water_km":best if is_finite(best) else 9999.0,"land":true,"forage":0.15+lush*0.7,"game":0.1+lush*0.6,"water_kind":"river"}

func context_at(origin:Vector2)->Dictionary:
	var data:=geo(origin)
	var forage:=float(data.forage)
	return {
		"surface_water_distance_km":float(data.water_km),"surface_water_recognized":true,"surface_water_kind":"river","surface_water_id":"probe_river",
		"environment_profile":{"signature":"probe","land":true,"forage":forage,"game":float(data.game),"fertility":0.5,"precipitation":0.5,"temperature":0.6,"biome":"grassland","resource_potentials":{"Fertile Soil":0.6,"Game":float(data.game)},"food_potential":0.2+forage*0.8,"subsistence_multiplier":0.7+forage*0.6,"hazards":{},"ecological_resilience":0.6},
		"surface_material_catchments":{"Timber":{"density":0.3,"position":Vector3(origin.x+1.0,0.0,origin.y)},"Stone":{"density":0.2,"position":Vector3(origin.x,0.0,origin.y+1.0)},"Fiber Plants":{"density":0.25,"position":Vector3(origin.x-1.0,0.0,origin.y)}},
		"woodland_catchment":{"density":0.3,"position":Vector3(origin.x+1.0,0.0,origin.y)},
	}

func wet(point:Vector2)->bool:
	return float(geo(point).water_km)<=Leader.WET_KM+0.05

# ------------------------------------------------------------ world setup

func fresh_founding_world(seed_value:int,population:int)->void:
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(population)
	ResourceSystem.initialize();FoodSystem.initialize();ConsequenceEngine.initialize();EconomySystem.initialize()
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool:return true)

func set_food(days:float)->void:
	var total:=GameState.population_exact*days
	for key in GameState.food_stocks.keys():GameState.food_stocks[key]=0.0
	GameState.food_stocks["Dry staples"]=total
	GameState.resource_stockpiles["Food"]=total

## Runs the real calendar day (resources, food, consequences, travel) at the
## caravan's true position until it arrives or the limit passes. Returns an
## audit of every day.
func run_founding_days(limit:int)->Dictionary:
	var audit:={"days":0,"dry_camps":0,"thirst_days":0,"deaths":0,"thirst_deaths":0,"hunger_deaths":0,"camps":[],"modes":[],"min_water_days":INF,"positions":[]}
	var day:=int(GameState.elapsed_days)
	for step in limit:
		day+=1
		var point:=CivilizationSystem.player_world_origin
		var deaths_before:=GameState.lifetime_deaths
		Day.advance(day,Day.context(point,GameState.convoy_traveling))
		GameState.elapsed_days=float(day)
		audit.days=int(audit.days)+1
		var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
		var mode:=String(caravan.get("mode",""))
		var here:=CivilizationSystem.player_world_origin
		(audit.positions as Array).append(here)
		if (audit.modes as Array).is_empty() or String((audit.modes as Array)[-1])!=mode:(audit.modes as Array).append(mode)
		if mode in Leader.CAMP_MODES:
			if not wet(here):audit.dry_camps=int(audit.dry_camps)+1
			if (audit.camps as Array).is_empty() or String((audit.camps as Array)[-1])!=mode:(audit.camps as Array).append(mode)
		var intake:=float(GameState.water_metrics.get("intake_ratio",1.0))
		if intake<0.98:audit.thirst_days=int(audit.thirst_days)+1
		audit.min_water_days=minf(float(audit.min_water_days),float(GameState.water_metrics.get("days",0.0)))
		var died:=GameState.lifetime_deaths-deaths_before
		if died>0:
			audit.deaths=int(audit.deaths)+died
			var components:Dictionary=GameState.simulation_metrics.get("mortality_components",{})
			var dominant:="Natural causes"
			for cause:String in components:
				if float(components[cause])>float(components.get(dominant,0.0)):dominant=cause
			if dominant=="Dehydration":audit.thirst_deaths=int(audit.thirst_deaths)+died
			if dominant=="Hunger":audit.hunger_deaths=int(audit.hunger_deaths)+died
		if OS.has_environment("CARAVAN_DEBUG"):
			var situation:=Travel.situation()
			print("DAY %d %s pos=(%.1f,%.1f) km=%.1f water=%.2f cap=%.2f supported=%.1f food=%.1f prod=%.0f need=%.0f health=%.2f intake=%.2f intent=%s" % [day,mode,here.x,here.y,float(caravan.get("progress_km",0.0)),float(situation.water_days),float(situation.water_capacity_days),float(situation.supported_days),float(situation.food_days),float(GameState.simulation_metrics.get("food_production",0.0)),float(GameState.simulation_metrics.get("food_consumption",0.0)),float(situation.health),intake,String(caravan.get("intent",""))])
		if mode=="arrived":break
	return audit

# ------------------------------------------------------------ scenarios

## (1) A river bends away from the straight line: the leader follows water.
func scenario_route_follows_river()->void:
	rivers=[[Vector2(0,-10),Vector2(0,60),Vector2(70,60)]]
	springs=[]
	fresh_founding_world(7101,120)
	# Founding vessels hold two days of water at dawn (see civilization_travel.situation).
	var plan:=Leader.plan_route(Vector2(0.4,0.0),Vector2(60,60.4),{"daily_km":14.0,"vessel_days":2.0,"competency":0.6,"start_water_days":2.0})
	expect(bool(plan.get("ok",false)),"(1) plan should succeed: %s" % String(plan.get("reason","")))
	expect(String(plan.get("route_kind",""))=="water_route","(1) expected a water route, got %s" % String(plan.get("route_kind","")))
	expect(float(plan.get("direct_longest_dry_km",0.0))>float(plan.get("safe_dry_km",0.0)),"(1) the straight line should be too dry")
	expect(float(plan.get("longest_dry_km",999.0))<=float(plan.get("safe_dry_km",0.0))+0.01,"(1) planned route keeps dry runs within the vessels' reach")
	var path:Array=plan.get("path",[])
	var near:=0.0
	var total:=0.0
	for index in range(path.size()-1):
		var a:Vector2=path[index]
		var b:Vector2=path[index+1]
		var km:=a.distance_to(b)
		var pieces:=maxi(1,ceili(km))
		for piece in pieces:
			var point:=a.lerp(b,(float(piece)+0.5)/float(pieces))
			total+=km/float(pieces)
			if float(geo(point).water_km)<=4.0:near+=km/float(pieces)
	expect(total>0.0 and near/total>=0.7,"(1) route should stay near the river (%.0f%% within 4 km)" % (near/maxf(0.001,total)*100.0))
	summary.append("(1) ROUTE  straight dry run %.0f km > safe %.0f km; leader route %.0f km, longest dry %.0f km, %.0f%% within 4 km of water. \"%s\"" % [float(plan.direct_longest_dry_km),float(plan.safe_dry_km),float(plan.total_km),float(plan.longest_dry_km),near/maxf(0.001,total)*100.0,String(plan.summary)])

## (2) Provisions run low mid-route along a river: camp, rebuild, resume, arrive.
func scenario_low_provisions_camp_and_resume()->void:
	rivers=[[Vector2(0,-20),Vector2(0,220)]]
	springs=[]
	fresh_founding_world(7202,120)
	CivilizationSystem.register_player_origin(Vector2(0.3,0.0))
	set_food(2.5)
	var begun:=WorldSimulation.submit("player",{"kind":"move","destination":Vector2(0.3,150.0)})
	expect(bool(begun.get("ok",false)),"(2) the move order should be accepted: %s" % str(begun))
	var audit:=run_founding_days(160)
	var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
	expect(String(caravan.get("mode",""))=="arrived","(2) caravan should arrive (mode %s after %d days)" % [String(caravan.get("mode","")),int(audit.days)])
	expect("foraging" in (audit.camps as Array) or "provisioning" in (audit.camps as Array),"(2) the leader should camp to forage when stores run low (camps %s)" % str(audit.camps))
	expect(int(audit.dry_camps)==0,"(2) no camp in a dry place")
	expect(int(audit.thirst_deaths)==0 and int(audit.hunger_deaths)==0,"(2) no thirst or hunger deaths (thirst %d, hunger %d)" % [int(audit.thirst_deaths),int(audit.hunger_deaths)])
	expect(CivilizationSystem.player_world_origin.distance_to(Vector2(0.3,150.0))<0.05,"(2) the caravan ends at the destination")
	summary.append("(2) LOW PROVISIONS  %d days, modes %s, deaths %d (thirst %d, hunger %d), leader %s: %s" % [int(audit.days),str(audit.modes),int(audit.deaths),int(audit.thirst_deaths),int(audit.hunger_deaths),String((caravan.get("leader",{}) as Dictionary).get("name","")),_log_titles(caravan)])

## (3) The old failure: a straight line through waterless country, with food
## running short on the way. No halt in a dry place; no thirst deaths.
func scenario_straight_line_into_dry_country()->void:
	rivers=[[Vector2(0,-30),Vector2(0,30)]]
	springs=[Vector3(21.0,7.0,0.8),Vector3(42.0,0.0,1.2)]
	fresh_founding_world(7303,120)
	CivilizationSystem.register_player_origin(Vector2(0.3,0.0))
	set_food(4.0)
	var begun:=WorldSimulation.submit("player",{"kind":"move","destination":Vector2(42.0,0.0)})
	expect(bool(begun.get("ok",false)),"(3) the move should be accepted via the spring: %s" % str(begun))
	var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
	var passes_spring:=false
	for point:Vector2 in caravan.get("path",[]):
		if point.distance_to(Vector2(21,7))<=3.0:passes_spring=true
	expect(passes_spring,"(3) the planned route should pass the spring at (21,7)")
	var audit:=run_founding_days(160)
	caravan=GameState.founding_journey.get("caravan",{})
	expect(String(caravan.get("mode",""))=="arrived","(3) caravan should arrive (mode %s)" % String(caravan.get("mode","")))
	expect(int(audit.dry_camps)==0,"(3) never camp in a dry place (%d dry camp days)" % int(audit.dry_camps))
	expect(int(audit.thirst_deaths)==0,"(3) zero thirst deaths (%d)" % int(audit.thirst_deaths))
	expect(int(audit.thirst_days)<=1,"(3) at most one short water day (%d)" % int(audit.thirst_days))
	expect(GameState.convoy_emergency_halt_reason=="","(3) no blind emergency halt")
	summary.append("(3) DRY STRAIGHT LINE  route via spring, %d days, modes %s, dry camps %d, thirst days %d, deaths %d (thirst %d). %s" % [int(audit.days),str(audit.modes),int(audit.dry_camps),int(audit.thirst_days),int(audit.deaths),int(audit.thirst_deaths),_log_titles(caravan)])

## (4) Genuinely impossible: 140 km of desert with no water anywhere.
func scenario_impossible_trip_refused()->void:
	rivers=[[Vector2(0,-30),Vector2(0,30)]]
	springs=[Vector3(150.0,0.0,1.0)]
	fresh_founding_world(7404,120)
	CivilizationSystem.register_player_origin(Vector2(0.3,0.0))
	var refused:=WorldSimulation.submit("player",{"kind":"move","destination":Vector2(150.0,0.0)})
	expect(refused.has("error"),"(4) an impossible trip must be refused")
	expect(String(refused.get("error","")).contains("without water"),"(4) the refusal should say why: %s" % String(refused.get("error","")))
	expect(GameState.founding_journey.is_empty() or not bool(GameState.founding_journey.get("active",false)),"(4) nobody leaves on a refused trip")
	summary.append("(4) IMPOSSIBLE  refused: %s" % String(refused.get("error","")))

## (5) Expansion caravan: form in a settlement, march by water, found.
func scenario_expansion_caravan()->void:
	rivers=[[Vector2(0,-10),Vector2(0,60),Vector2(80,60)]]
	springs=[]
	fresh_founding_world(7505,1000)
	GameState.settlement_name="Firsthome"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(0.3,0.0,0.0)
	CivilizationSystem.register_player_origin(Vector2(0.3,0.0))
	CivilizationSystem._add_revealed_area(Vector2(30,30),110.0,"probe chart")
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":20000.0,"Preserved food":0.0}
	GameState.resource_stockpiles["Food"]=20000.0
	GameState.resource_stockpiles["Timber"]=500.0
	GameState.resource_stockpiles["Fiber Plants"]=500.0
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	var candidates:=Leader.candidates(6)
	expect(not candidates.is_empty(),"(5) the government cast should offer caravan leaders")
	var chosen:Dictionary=candidates[0] if not candidates.is_empty() else {}
	var destination:=Vector2(70.0,60.4)
	var formation:=Caravans.formation(Vector2(0.3,0.0),destination,1000.0,{"population":60,"leader_person_id":int(chosen.get("person_id",0))})
	expect(bool(formation.get("ok",false)),"(5) the leader should accept the destination: %s" % String(formation.get("advice","")))
	var population_before:=GameState.population_total
	var food_before:=float(GameState.resource_stockpiles.get("Food",0.0))
	var rations:=60.0*6.5
	var started:=SettlementModel.begin_settlement_convoy(destination,1.0,"Reedwater",false,{"population":60,"food":rations,"leader_person_id":int(chosen.get("person_id",0))})
	expect(bool(started.get("ok",false)),"(5) the caravan should depart: %s" % String(started.get("reason","")))
	var record:Dictionary=GameState.settlement_convoy.get("caravan",{})
	expect(not record.is_empty(),"(5) the convoy should carry a caravan record")
	expect(String((record.get("leader",{}) as Dictionary).get("name",""))==String(chosen.get("name","?")),"(5) the chosen leader leads")
	expect(int(record.get("population",0))==60,"(5) 60 settlers depart")
	expect(absf(food_before-float(GameState.resource_stockpiles.get("Food",0.0))-rations)<1.0,"(5) exactly the chosen rations leave the stores")
	var dry_camps:=0
	var modes:Array[String]=[]
	var completed:Dictionary={}
	var start_food:=float(record.get("food",0.0))
	for day in 200:
		GameState.elapsed_days+=1.0
		completed=Day.advance_convoy()
		if not completed.is_empty():break
		record=GameState.settlement_convoy.get("caravan",{})
		var mode:=String(record.get("mode",""))
		if modes.is_empty() or modes[-1]!=mode:modes.append(mode)
		if mode in Leader.CAMP_MODES and not wet(Leader.position(record)):dry_camps+=1
	expect(bool(completed.get("ok",false)),"(5) the caravan should found the settlement: %s" % str(completed.get("reason","")))
	var final_record:Dictionary=completed.get("caravan",record)
	expect(int(final_record.get("deaths",0))==0,"(5) zero deaths on the road (%d)" % int(final_record.get("deaths",0)))
	expect(dry_camps==0,"(5) no dry camps")
	expect(GameState.population_total==population_before,"(5) aggregate population conserved (%d -> %d)" % [population_before,GameState.population_total])
	var network:Dictionary=SettlementModel.settlement_network_snapshot()
	expect(int(network.get("count",0))==2,"(5) a second settlement exists")
	var represented:=0
	for settlement:Dictionary in network.get("settlements",[]):represented+=int(settlement.get("population",0))
	expect(represented==GameState.population_total,"(5) every person is in a settlement (%d of %d)" % [represented,GameState.population_total])
	var ledger:=start_food+float(final_record.get("food_gathered",0.0))-float(final_record.get("food_eaten",0.0))
	expect(absf(ledger-float(final_record.get("food",-1.0)))<0.5,"(5) carried food ledger balances")
	var new_id:=String((completed.get("settlement",{}) as Dictionary).get("id",""))
	var new_food:=float(SettlementModel.city_resource_snapshot(new_id,false).get("stores",{}).get("Food",0.0))
	expect(absf(new_food-float(final_record.get("food",0.0)))<1.0,"(5) the new settlement receives exactly the food carried in (%.1f vs %.1f)" % [new_food,float(final_record.get("food",0.0))])
	expect(SettlementModel.validate_settlement_network().is_empty(),"(5) network valid: %s" % str(SettlementModel.validate_settlement_network()))
	summary.append("(5) EXPANSION  %s led 60 settlers %.0f km (%s) in %d days; modes %s; deaths %d; rations %.0f -> %.0f (+%.0f foraged); new town food %.0f; leader installed %s" % [String((final_record.get("leader",{}) as Dictionary).get("name","")),float(final_record.get("total_km",0.0)),String(final_record.get("route_kind","")),int(GameState.elapsed_days),str(modes),int(final_record.get("deaths",0)),start_food,float(final_record.get("food",0.0)),float(final_record.get("food_gathered",0.0)),new_food,str(completed.get("leader_installed",false))])

## (6) Saves written before caravan leaders: a founding journey and a settlement
## convoy on the road continue under a leader; a caravan survives a save.
func scenario_old_save_migration()->void:
	rivers=[[Vector2(0,-20),Vector2(0,220)]]
	springs=[]
	fresh_founding_world(7606,120)
	CivilizationSystem.register_player_origin(Vector2(0.3,15.0))
	GameState.founding_journey={"ok":true,"active":true,"origin":Vector2(0.3,0.0),"destination":Vector2(0.3,60.0),"duration_days":60.0/16.0,"elapsed":15.0/16.0}
	GameState.convoy_traveling=true
	GameState.simulation_metrics["travel_speed_factor"]=1.0
	Travel.advance(1.0)
	var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
	expect(not caravan.is_empty(),"(6) an old founding journey gains a caravan leader")
	var after:=CivilizationSystem.player_world_origin
	expect(after.y>15.5 and after.y<=31.5,"(6) it continues from where it was (now at %.1f km)" % after.y)
	# Save round trip of the live record.
	var bytes:=var_to_bytes(GameState.founding_journey)
	var restored:Variant=bytes_to_var(bytes)
	expect(restored is Dictionary and ((restored as Dictionary).get("caravan",{}) as Dictionary).get("path",[]) is Array,"(6) the caravan record survives serialization")
	GameState.founding_journey=restored
	var audit:=run_founding_days(20)
	expect(String((GameState.founding_journey.get("caravan",{}) as Dictionary).get("mode",""))=="arrived","(6) the migrated journey arrives (%s)" % str(audit.modes))
	# Legacy settlement convoy.
	fresh_founding_world(7607,1000)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(0.3,0.0,0.0)
	SettlementModel.ensure_founded()
	GameState.elapsed_days=10.0
	GameState.settlement_convoy={"active":true,"phase":"traveling","origin_id":"","origin_name":"Firsthome","origin":Vector2(0.3,0.0),"position":Vector2(0.3,16.0),"destination":Vector2(0.3,48.0),"depart_day":9.0,"arrival_day":12.0,"duration_days":3.0,"progress":0.33,"population":40,"population_share":0.04,"population_sources":{},"food_committed":2000.0,"materials_committed":{"Timber":6.0},"settlement_name":"Oldford"}
	var population_before:=GameState.population_total
	var completed:Dictionary={}
	for day in 30:
		GameState.elapsed_days+=1.0
		completed=Day.advance_convoy()
		if not completed.is_empty():break
	var record:Dictionary=completed.get("caravan",{})
	expect(bool(completed.get("ok",false)),"(6) the legacy settlement convoy founds its town: %s" % str(completed.get("reason","")))
	# Two person-days per settler were already eaten under the old ledger (days 9-11).
	expect(absf(float(record.get("food_start",0.0))-(2000.0-40.0*2.0))<0.5,"(6) legacy rations migrate from the old ledger (%.0f)" % float(record.get("food_start",0.0)))
	expect(GameState.population_total==population_before,"(6) legacy convoy population conserved")
	summary.append("(6) MIGRATION  founding journey resumed at %.1f km under %s; legacy convoy founded %s after %d days with %.0f rations carried in" % [after.y,String(caravan.get("leader",{}).get("name","")),String(completed.get("settlement",{}).get("name","")),int(GameState.elapsed_days-10.0),float(record.get("food",0.0))])

func _log_titles(caravan:Dictionary)->String:
	var titles:Array[String]=[]
	for entry:Dictionary in caravan.get("log",[]):titles.append(String(entry.get("title","")))
	return " | ".join(titles)

## (7) The real map: plans over authored rivers, drainage and heights stay
## within the vessels' reach and finish in bounded time.
func scenario_real_terrain_planning()->void:
	GameState.reset_for_new_world(9241)
	CivilizationSystem.reset_for_new_world()
	var terrain=load("res://scripts/local_terrain.gd").new()
	terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
	Leader.geography_provider=Callable(terrain,"_caravan_geography_at")
	Leader.forage_provider=Callable(terrain,"_caravan_forage_at")
	var previous_route:=WorldSimulation.route_provider
	WorldSimulation.route_provider=Callable(terrain,"_analyze_convoy_route")
	var start:Vector2=terrain._civilization_start(preload("res://scripts/civilization_start.gd").candidate(GameState.world_seed,0))
	var accepted:=0
	var refused:=0
	var slowest:=0
	var water_routes:=0
	for spoke in 8:
		var destination:=start+Vector2.from_angle(TAU*float(spoke)/8.0)*55.0
		var began:=Time.get_ticks_msec()
		var plan:=Leader.plan_route(start,destination,{"daily_km":12.0,"vessel_days":2.0,"competency":0.55,"start_water_days":2.0})
		var elapsed:=Time.get_ticks_msec()-began
		slowest=maxi(slowest,elapsed)
		if bool(plan.get("ok",false)):
			accepted+=1
			if String(plan.get("route_kind",""))=="water_route":water_routes+=1
			expect(float(plan.get("longest_dry_km",0.0))<=float(plan.get("safe_dry_km",0.0))+0.01 or not bool(plan.get("water_known",true)),"(7) real plan %d exceeds the vessels (%.1f > %.1f)" % [spoke,float(plan.longest_dry_km),float(plan.safe_dry_km)])
		else:
			refused+=1
			expect(String(plan.get("reason","")).length()>20,"(7) refusal %d explains itself" % spoke)
	expect(slowest<4000,"(7) planning should stay bounded (%d ms)" % slowest)
	summary.append("(7) REAL MAP  seed 9241 start (%.0f,%.0f): 8 destinations at 55 km -> %d planned (%d along water), %d refused with reasons; slowest plan %d ms" % [start.x,start.y,accepted,water_routes,refused,slowest])
	WorldSimulation.route_provider=previous_route
	Leader.geography_provider=Callable(self,"geo")
	Leader.forage_provider=Callable()
	terrain.free()
