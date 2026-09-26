extends Node
## A century of envoys, twice: once with the hall's own business only, once
## with the wider requests (envoy_requests.gd). The world is shaken the same
## way both times (hunger, sickness, tension, wars between others, new
## rulers) and eras advance; envoys are answered by the same seeded policy.
## Prints visit counts and the mix of business, and a sample of requests.
## Checks the pace stays the same and no business dominates or repeats.
## Days advance STEP at a time, and the hall runs its envoy-only surrogate
## (AudienceHall.envoys_only: no court, aims, crises, lives or war loops), to
## stay under two minutes.
const Hall:=preload("res://scripts/audience_hall.gd")
const ER:=preload("res://scripts/envoy_requests.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const SEED:=424242
const YEARS:=100
const STEP:=10
var failures:Array[String]=[]
var daily_us:=0

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _setup()->Array[String]:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(220); GameState.housing_capacity=300
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	FoodSystem.receive_external_food(6000)
	for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=400.0
	CivilizationSystem.player_world_origin=preload("res://scripts/civilization_start.gd").candidate(SEED,0)
	var met:Array[String]=[]
	for index in 4:
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.player_relation.contact_level=2; civ.player_relation.met_day=0; civ.player_relation.home_location_known=true
		met.append(String(civ.id))
		# A ledger of their own, so they can pay, trade and give from real stores.
		WorldSimulation.create_actor(String(civ.id),SEED+index,CivilizationSystem._civilization_world_position(civ))
	_restock(met,RandomNumberGenerator.new())
	return met

func _restock(met:Array[String],rng:RandomNumberGenerator)->void:
	for id in met:
		WorldSimulation.scoped(id,func()->void:
			for res in ["Timber","Stone","Clay","Fiber Plants"]: WorldSimulation.state.resource_stockpiles[res]=rng.randf_range(20.0,260.0)
			if WorldSimulation.food.total_stored()<300.0: WorldSimulation.food.receive_external_food(400.0))

func _run(wider:bool)->Dictionary:
	ER.enabled=wider
	var met:=_setup()
	var world:=RandomNumberGenerator.new(); world.seed=SEED
	var arrivals:Array[Dictionary]=[]
	var answered:=0
	for day in range(STEP,YEARS*365,STEP):
		GameState.elapsed_days=day
		var year:=day/365
		if day%3650<STEP: print("ENVOY_VARIETY_PROGRESS wider=%s year %d at %.1f s (hall %.1f s), %d arrivals" % [str(wider),year,float(Time.get_ticks_msec())/1000.0,float(daily_us)/1e6,arrivals.size()])
		# Eras advance as a people would: farming by year 25, metal by year 60.
		if year==25 and not "seed_selection" in GameState.known_discoveries: GameState.known_discoveries.append("seed_selection")
		if year==60 and not "copper_smelting" in GameState.known_discoveries: GameState.known_discoveries.append("copper_smelting")
		if FoodSystem.total_stored()<2000.0: FoodSystem.receive_external_food(1500)
		for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=maxf(200.0,float(GameState.resource_stockpiles.get(res,0.0)))
		if day%365<STEP: _restock(met,world)
		if day%30<STEP:
			var civ:=ForeignDiplomacy.civilization(met[world.randi_range(0,met.size()-1)])
			if not civ.is_empty():
				civ.player_relation.opinion=clampf(float(civ.player_relation.opinion)+world.randf_range(-0.25,0.25),-0.9,0.9)
				civ.food_days=clampf(world.randf_range(6.0,90.0),0.0,180.0)
				civ.health=world.randf_range(0.35,0.95)
				civ.player_relation.border_tension=clampf(float(civ.player_relation.border_tension)+world.randf_range(-0.2,0.2),0.0,1.0)
				var other:=met[world.randi_range(0,met.size()-1)]
				if other!=String(civ.id):
					var roll:=world.randf()
					var rel:={"border_tension":world.randf_range(0.0,0.9),"at_war":roll<0.12}
					(civ.relations as Dictionary)[other]=rel
					var mirror:=ForeignDiplomacy.civilization(other)
					if not mirror.is_empty(): (mirror.relations as Dictionary)[String(civ.id)]=rel.duplicate()
				if world.randf()<0.04: civ.player_relation.recruitment_visits=int(civ.player_relation.get("recruitment_visits",0))+1
		var t0:=Time.get_ticks_usec()
		var came:=Hall.daily(day)
		daily_us+=Time.get_ticks_usec()-t0
		for audience in came:
			if String(audience.get("origin",""))=="foreign": arrivals.append(audience)
		for audience in Hall.waiting():
			if String(audience.origin)!="foreign" or day-int(audience.arrived_day)<3: continue
			var options:Array=Hall.options(String(audience.id)).filter(func(o:Dictionary)->bool:return bool(o.enabled))
			if options.is_empty(): continue
			var pick:=RandomNumberGenerator.new(); pick.seed=hash("%d:%d" % [SEED,int(audience.arrived_day)])
			Hall.resolve(String(audience.id),String(options[pick.randi_range(0,options.size()-1)].id))
			answered+=1
	var counts:={}
	var families:={}
	var repeats:=0
	var last:=""
	for audience in arrivals:
		var t:=Hall._situation_type(audience)
		counts[t]=int(counts.get(t,0))+1
		var f:=String(ER.family(t))
		families[f]=int(families.get(f,0))+1
		if t==last: repeats+=1
		last=t
	return {"arrivals":arrivals,"counts":counts,"families":families,"repeats":repeats,"answered":answered,"pledges":ER.pledges().size()}

func _sorted(d:Dictionary)->String:
	var keys:=d.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:return int(d[a])>int(d[b]))
	var parts:PackedStringArray=PackedStringArray()
	for k in keys: parts.append("%s %d" % [String(k),int(d[k])])
	return ", ".join(parts)

func _ready()->void:
	var started:=Time.get_ticks_msec()
	Hall.envoys_only=true
	var alone:=_run(false)
	var wider:=_run(true)
	var a:int=(alone.arrivals as Array).size()
	var w:int=(wider.arrivals as Array).size()
	print("ENVOY_VARIETY %d years, step %d days, 4 peoples met" % [YEARS,STEP])
	print("ENVOY_VARIETY visits: hall alone %d, with wider requests %d" % [a,w])
	print("ENVOY_VARIETY hall alone kinds: "+_sorted(alone.counts))
	print("ENVOY_VARIETY wider kinds (%d distinct): %s" % [(wider.counts as Dictionary).size(),_sorted(wider.counts)])
	print("ENVOY_VARIETY families alone: "+_sorted(alone.families))
	print("ENVOY_VARIETY families wider: "+_sorted(wider.families))
	print("ENVOY_VARIETY same kind back to back: alone %d, wider %d" % [int(alone.repeats),int(wider.repeats)])
	var shown:=0
	for audience in wider.arrivals:
		var t:=Hall._situation_type(audience)
		if not ER.TYPES.has(t) or shown>=24: continue
		shown+=1
		print("ENVOY_VARIETY   y%-3d %-18s %s — %s | answered: %s" % [int(audience.arrived_day)/365,t,String(audience.situation.get("headline","")),String(audience.situation.get("summary","")).substr(0,170),String(audience.get("outcome","")).substr(0,120)])
	check(a>=20,"Too few envoys to judge: %d" % a)
	check(absf(float(w-a))<=maxf(3.0,float(a)*0.12),"Visit pace changed: %d vs %d" % [w,a])
	check((wider.counts as Dictionary).size()>=(alone.counts as Dictionary).size()+6,"Too little new variety")
	var top:=0
	for k in wider.counts: top=maxi(top,int(wider.counts[k]))
	check(float(top)<=float(w)*0.25,"One kind dominates: %d of %d" % [top,w])
	check(int(wider.families.get("food",0))<int(alone.families.get("food",0)) or int(alone.families.get("food",0))==0,"Food asks not reduced")
	print("ENVOY_VARIETY took %.1f s" % [float(Time.get_ticks_msec()-started)/1000.0])
	print("ENVOY_VARIETY "+("PASS" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	ER.enabled=true
	Hall.envoys_only=false
	get_tree().quit(0 if failures.is_empty() else 1)
