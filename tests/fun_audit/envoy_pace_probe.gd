extends Node
## Short headless check of the envoy scheduler on a generated world: two
## peoples met, two stone-age years of daily audiences. Checks one envoy
## waiting at a time, the per-people gap, gift rarity and the known-country
## scouting reach. Under a minute; long-run pacing is modelled in
## envoy_pace_model.py.
const HALL=preload("res://scripts/audience_hall.gd")
const Chronicle=preload("res://scripts/chronicle.gd")
const SEED:=424242
const DAYS:=730
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _setup()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200); GameState.housing_capacity=260
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	FoodSystem.receive_external_food(3000)

func _placement_and_signs()->void:
	var Start:=preload("res://scripts/civilization_start.gd")
	var Signs:=preload("res://scripts/neighbor_signs.gd")
	for seed_value in [424242,77013,91420]:
		GameState.reset_for_new_world(seed_value)
		for group in 3:
			var anchor:=Start.candidate(seed_value,group*Start.REGION_SEATS)
			for member in range(1,Start.REGION_SEATS):
				var km:=Start.candidate(seed_value,group*Start.REGION_SEATS+member).distance_to(anchor)
				check(km>=Start.NEIGHBOR_MIN_KM-Start.REGION_CELL_KM and km<=Start.NEIGHBOR_MAX_KM*1.5,"seed %d seat %d is %.0f km from its region" % [seed_value,group*Start.REGION_SEATS+member,km])
	_setup()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var home:Vector2=CivilizationSystem._civilization_world_position(civ)
	var past:=func(miss:float)->Array:return [{"x":home.x-150,"z":home.y+miss},{"x":home.x+150,"z":home.y+miss}]
	var mine:=func(route:Array)->int:return Signs.read_route(CivilizationSystem,route,40).filter(func(x:Dictionary)->bool:return String(x.civ_id)==String(civ.id)).size()
	check(int(mine.call(past.call(80.0)))==1 and int(mine.call(past.call(140.0)))==1,"A route through a people's range brings no sign")
	check(int(mine.call(past.call(30.0)))==0 and int(mine.call(past.call(400.0)))==0,"Signs at contact distance or far beyond range")

func _ready()->void:
	_placement_and_signs()
	_setup()
	CivilizationSystem.player_world_origin=preload("res://scripts/civilization_start.gd").candidate(SEED,0)
	GameState.elapsed_days=3650
	var reach10:float=CivilizationSystem.scout_known_reach_km()
	GameState.elapsed_days=0
	var reach0:float=CivilizationSystem.scout_known_reach_km()
	check(reach0>=100.0 and reach0<=140.0,"Known reach at founding is %.0f km" % reach0)
	check(CivilizationSystem.scout_one_way_range(365)<=reach0+0.01,"A year-long party outruns known country")
	# The two nearest peoples are met today.
	var by_distance:=CivilizationSystem.civilizations.duplicate()
	by_distance.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return CivilizationSystem.player_world_origin.distance_to(CivilizationSystem._civilization_world_position(a))<CivilizationSystem.player_world_origin.distance_to(CivilizationSystem._civilization_world_position(b)))
	var met:Array[String]=[]
	for civ:Dictionary in by_distance.slice(0,2):
		civ.player_relation.contact_level=2; civ.player_relation.met_day=0; civ.player_relation.home_location_known=true
		met.append(String(civ.id))
		print("ENVOY_PACE met %s at %.0f km" % [String(civ.name),CivilizationSystem.player_world_origin.distance_to(CivilizationSystem._civilization_world_position(civ))])
	print("ENVOY_PACE known reach before contact: founding %.0f km, year 10 %.0f km" % [reach0,reach10])
	print("ENVOY_PACE era %d, global gap %d days, per-people gap %d days" % [HALL.era_tier(),HALL._gap(),HALL.civ_gap(met[0])])
	check(HALL.era_tier()==0,"A new people is not in the first era")
	check(HALL.civ_gap(met[0])>=900,"Stone-age per-people gap too short: %d" % HALL.civ_gap(met[0]))
	var arrivals:Array[Dictionary]=[]
	var rng:=RandomNumberGenerator.new(); rng.seed=SEED
	for day in range(1,DAYS+1):
		GameState.elapsed_days=day
		if day%60==0:
			var civ:Dictionary=ForeignDiplomacy.civilization(met[rng.randi_range(0,1)])
			if not civ.is_empty(): civ.player_relation.opinion=clampf(float(civ.player_relation.opinion)+rng.randf_range(-0.25,0.25),-0.9,0.9)
		for audience in HALL.daily(day):
			if String(audience.get("origin",""))=="foreign": arrivals.append(audience)
		var waiting_foreign:=HALL.waiting().filter(func(a:Dictionary)->bool:return String(a.origin)=="foreign")
		check(waiting_foreign.size()<=1,"%d envoys waiting at once on day %d" % [waiting_foreign.size(),day])
		for audience in waiting_foreign:
			if day-int(audience.arrived_day)>=4:
				var options:Array=HALL.options(String(audience.id)).filter(func(o:Dictionary)->bool:return bool(o.enabled))
				if not options.is_empty(): HALL.resolve(String(audience.id),String(options[rng.randi_range(0,options.size()-1)].id))
	var gifts:=0
	var last_by_civ:Dictionary={}
	for audience in arrivals:
		var type:=HALL._situation_type(audience)
		if type in HALL.PURE_GIFTS: gifts+=1
		var civ_id:=String(audience.civ_id)
		var crisis:=bool(audience.get("situation",{}).get("occasion",{}).get("crisis",false))
		if last_by_civ.has(civ_id) and not crisis: check(int(audience.arrived_day)-int(last_by_civ[civ_id])>=HALL.CIV_GAP,"%s sent envoys %d days apart" % [civ_id,int(audience.arrived_day)-int(last_by_civ[civ_id])])
		last_by_civ[civ_id]=int(audience.arrived_day)
		print("ENVOY_PACE   day %4d %-8s %s" % [int(audience.arrived_day),civ_id,type])
	var words:=0
	for entry in Chronicle.entries("whisper"):
		if String(entry.get("title","")).begins_with("Word of the"): words+=1
	print("ENVOY_PACE %d envoys in %d days (%.2f a year) from two peoples; %d pure gifts; %d Chronicle word lines" % [arrivals.size(),DAYS,float(arrivals.size())*365.0/DAYS,gifts,words])
	check(arrivals.size()<=3,"Too many stone-age envoys: %d in %d days" % [arrivals.size(),DAYS])
	check(gifts<=1,"More than one pure gift in two years")
	check(met.all(func(id:String)->bool:return last_by_civ.has(id)),"A newly met people's first envoy never came")
	print("ENVOY_PACE "+("PASS" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)
