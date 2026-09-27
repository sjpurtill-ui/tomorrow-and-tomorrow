extends RefCounted
## THE AIR AND SEA WAR'S COST TO PEOPLE.
##
## Fleets and air wings work inside drawn zones run by their commanders
## (joint_operations.gd). This module says what their work does to people on
## both sides, in bounded, historically calibrated amounts:
##   strike_city()      bombing, port strikes and coastal bombardment of a city:
##                      civilian deaths, people driven out, damaged and ruined
##                      buildings that persist, burned stores, fear, weaker
##                      cohesion and morale, hardened grudges, war-weariness.
##   crew_casualties()  what happens to the crews of lost and damaged hulls and
##                      airframes: killed, wounded, rescued, captured.
##   note_losses()      war totals (CivilizationSystem._record_war_battle),
##                      war exhaustion on both sides, and the Chronicle.
##   opposed_landing()  an amphibious landing fought on the beach.
## Static helpers; everything runs through the ordinary owned systems of the
## civilization concerned (WorldSimulation.scoped), never a copy.
##
## HISTORICAL CALIBRATION (alternative history: real events only calibrate).
## - Civilian deaths from bombing. First-generation raids (airships, early
##   bombers) killed about 0.02% of a large city's people over four years of
##   war. The heaviest four-engine campaigns killed 1-3% of a heavily bombed
##   city's people across a war (one exceptional firestorm week about 2%); a
##   single large raid 0.05-0.5%; a long night blitz of a capital about 0.35%
##   over eight months. A day at full strike weight here kills 0.0003% (early
##   aircraft), 0.008% (heavy bombers), 0.012% (jet bombers) of the city, so a
##   year of daily raids at full weight kills about 0.1%, 3% or 4%; a single
##   day is capped at 0.15%. Shelling a town from the sea killed about 0.2% of
##   a port's people in a three-day bombardment: 0.004% a day here.
## - People driven out. Bombed cities lost a third to a half of their housing
##   and emptied as people fled; about eight people left for each killed.
##   Capped at 2% of the city a day (and 35% a step by displace()).
## - Buildings. A heavy raid destroyed or damaged 5-10% of a city's buildings;
##   here at most 2% of the fabric is struck a day, and struck buildings stay
##   damaged or ruined until builders repair them (settlement_model.gd):
##   damaged houses take months, ruins a few years, as after the real wars.
## - Stores. Warehouses burned: at most 0.6% of a city's food and materials a
##   day at full weight, never more than 2%.
## - Crews. Of the crews of lost ships and aircraft: oared and sailing ships
##   (crews often swam ashore, or struck and were taken) 25-40% killed; steel
##   warships 35-50% killed; submarines 75-80%; aircrew over their own ground
##   about 40% killed (most bailed out), over enemy ground 60-70% killed and
##   25-30% taken prisoner. Died of wounds: 25% (oar and sail), 12% (steam and
##   early flight), 5% (modern). A fifth of the wounded never return.
## - Merchant shipping. Commerce raiding at its worst sank about a quarter of
##   the ships leaving port in its worst month; sea trade here falls at most
##   by half from raiding (and by a further bounded share from blockade).
## - Landings. An opposed landing lost 6% (a well-supported landing) to 17-25%
##   (a hard beach) of the landing force; a failed raid over half.
## - Air defence. Bombers lost about 4% a raid to guns and fighters together;
##   ground guns alone take at most 0.7% of a wing's airframes a day here.

const Combat=preload("res://scripts/civilization_combat.gd")
const Chronicle=preload("res://scripts/chronicle.gd")
const C=preload("res://scripts/joint_force_catalog.gd")
const Tactics=preload("res://scripts/battle_tactics.gd")

const MAX_STRIKE:=0.025
const CIVILIAN_DEATH_RATE:={"early_air":0.000003,"air":0.00008,"jet":0.00012,"sea":0.00004}
const DEATH_CAP_PER_DAY:=0.0015
const DISPLACED_PER_DEAD:=8.0
const DISPLACED_SHARE_PER_DAY:=0.0006
const DISPLACED_CAP_PER_DAY:=0.02
const STORES_LOSS_PER_DAY:=0.006
const STORES_LOSS_CAP:=0.02
const PLOT_EXTENT:=0.02
const PLOT_SEVERITY:=0.30
const MERCHANT_LOSS_CAP:=0.5
const MERCHANT_DEATH_RATE:=0.000002
## Ground guns: at most this share of a wing's airframes a day.
const AA_LOSS_CAP:=0.007
const AA_BASELINE:=0.001
## Ground fire over a battle takes close-support aircraft.
const GROUND_FIRE_LOSS:=0.004
const RECOVERY_DAYS:=90
const DISABLED_SHARE:=0.2
const WAR_LEDGER_DAYS:=30
const MAX_WOUNDED_COHORTS:=64
const STORE_MATERIALS:=["Timber","Stone","Clay","Iron Ore","Fiber Plants","Iron","Bronze","Copper","Tin","Coal","Fuel","Cloth","Tools","Civilian Goods"]

## Crew fate shares for a lost hull or airframe: [killed, wounded, rescued, captured].
const CREW_PROFILES:={
	"oared":{"own":[.30,.15,.50,.05],"away":[.40,.10,.20,.30]},
	"sail":{"own":[.25,.20,.45,.10],"away":[.30,.15,.15,.40]},
	"steel":{"own":[.35,.15,.45,.05],"away":[.50,.10,.15,.25]},
	"submarine":{"own":[.75,.05,.15,.05],"away":[.80,.02,.03,.15]},
	"early_air":{"own":[.30,.20,.50,.0],"away":[.55,.05,.05,.35]},
	"fighter":{"own":[.40,.20,.40,.0],"away":[.60,.05,.05,.30]},
	"bomber":{"own":[.45,.20,.35,.0],"away":[.70,.03,.02,.25]},
	"rotary":{"own":[.40,.25,.30,.05],"away":[.50,.15,.10,.25]},
	"remote":{"own":[.0,.0,1.0,.0],"away":[.0,.0,1.0,.0]},
}
const DIED_OF_WOUNDS:={"oared":.25,"sail":.25,"steel":.12,"submarine":.12,"early_air":.12,"fighter":.08,"bomber":.08,"rotary":.05,"remote":.0}

static func profile(type_id:String)->String:
	match type_id:
		"war_canoe","galley","heavy_galley":return "oared"
		"sailing_warship","sailing_frigate","ship_of_line","convoy_transport":return "sail"
		"submarine","nuclear_submarine":return "submarine"
		"observation_balloon","airship","recon_plane":return "early_air"
		"fighter","heavy_fighter","jet_fighter","close_air_support":return "fighter"
		"tactical_bomber","strategic_bomber","naval_bomber","jet_bomber","transport_aircraft":return "bomber"
		"transport_helicopter","attack_helicopter":return "rotary"
		"recon_drone","strike_drone":return "remote"
	return "steel"

## Global owner id ("player" is the human) to the id another owner's world uses for it.
static func view_id(global_owner:String)->String:
	return "human" if global_owner=="player" else global_owner

## The global owner of the current scope.
static func here()->String:
	return String(WorldSimulation.actor_id)

## The current scope's relation with another civilization ({} if unknown).
static func relation(view:String)->Dictionary:
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if String(civ.get("id",""))==view:
			if not civ.get("player_relation") is Dictionary:civ["player_relation"]={}
			return civ.player_relation
	return {}

static func _in(owner:String,operation:Callable)->Variant:
	if not WorldSimulation.enabled or owner==here():return operation.call()
	if owner!="player" and not WorldSimulation.actors.has(owner):return null
	return WorldSimulation.scoped(owner,operation)

# --------------------------------------------------------------------------
# Authority: striking a city is the ruler's decision
# --------------------------------------------------------------------------

## The restricted means a force would use against a city.
static func means_of(force:Dictionary)->String:
	if String(force.get("domain",""))=="navy":return "naval_bombardment"
	for type_id:String in force.get("units",{}):
		if int(force.units[type_id])<=0:continue
		var means:=preload("res://scripts/sovereign_weapons.gd").means_of_equipment(String(C.UNITS[type_id].equipment))
		if means!="":return means
	return "aerial_bombardment"

## Whether this force may strike a city now (the scope's own ruler decides).
static func city_gate(force:Dictionary)->Dictionary:
	return WorldSimulation.military.general_use_gate(means_of(force),{"target":"city"})

# --------------------------------------------------------------------------
# Strikes on cities
# --------------------------------------------------------------------------

static func strike_class(force:Dictionary)->String:
	if String(force.get("domain",""))=="navy":return "sea"
	var units:Dictionary=force.get("units",{})
	if int(units.get("jet_bomber",0))>0:return "jet"
	if "advanced_airframes" in WorldSimulation.state.known_discoveries:return "air"
	return "early_air"

## One day's strike by `force` (in its owner's scope) on a known hostile city.
## `damage` is the day's strike weight (0..MAX_STRIKE). `civilian` says whether
## the ruler's authority covers the town itself; without it only military
## targets (fortifications, defenders, bases, stores behind the lines) are hit.
static func strike_city(force:Dictionary,city:Dictionary,damage:float,mission:String,civilian:bool)->Dictionary:
	var view:=String(city.get("controller",city.get("civ_id","")))
	if view=="":view=String(city.get("civ_id",""))
	var region_id:=String(city.get("city_id",""))
	var intensity:=clampf(damage/MAX_STRIKE,0.0,1.0)*Tactics.zone_factor(String(force.get("tactic","")),"damage")
	intensity=clampf(intensity,0.0,1.2)
	var attacker:=here() if String(force.get("owner","player"))=="player" else String(force.owner)
	var klass:=strike_class(force)
	var outcome:={"dead":0,"displaced":0,"plots":0,"stores":0.0,"troops":0,"intensity":intensity,"civilian":civilian}
	if intensity<=0.0 or region_id=="":return outcome
	if not WorldSimulation.enabled and view!="player":
		return _strike_legacy_rival(force,view,region_id,damage,mission,civilian,intensity,klass,outcome)
	var target:=Combat.owner(view) if WorldSimulation.enabled else "player"
	var local:=region_id if view=="player" else Combat.local_city(view,region_id)
	if target!="player" and not WorldSimulation.actors.has(target):return outcome
	var carry_key:="strike_carry"
	var carry:=float(force.get(carry_key,0.0))
	var result:Dictionary=_in(target,func()->Dictionary:
		var local_outcome:Dictionary=WorldSimulation.settlements.with_city_resources(local,func()->Dictionary:
			var out:={"dead":0,"displaced":0,"plots":0,"stores":0.0,"carry":carry,"name":String(WorldSimulation.settlements.settlement_record(local).get("name",WorldSimulation.state.settlement_name))}
			var population:float=WorldSimulation.settlements.with_local_population(func()->float:return WorldSimulation.state.population_exact)
			if civilian:
				var expected:=population*float(CIVILIAN_DEATH_RATE.get(klass,0.00008))*intensity+float(out.carry)
				var requested:=mini(floori(expected),roundi(population*DEATH_CAP_PER_DAY))
				out.carry=clampf(expected-float(requested),0.0,50.0)
				if requested>0:
					out.dead=int(WorldSimulation.settlements.with_local_population(func()->int:return int(WorldSimulation.state.register_population_deaths(requested,"Civilian deaths in war").get("count",0)),true))
				var fled:=mini(roundi(float(out.dead)*DISPLACED_PER_DEAD+population*DISPLACED_SHARE_PER_DAY*intensity),roundi(population*DISPLACED_CAP_PER_DAY))
				if fled>0:out.displaced=Combat.displace("player",local,fled)
				var seed:=hash("%s:%s:%d" % [attacker,local,int(WorldSimulation.state.elapsed_days)])
				out.plots=WorldSimulation.settlements.apply_bounded_siege_damage(seed,PLOT_SEVERITY*intensity,PLOT_EXTENT*intensity,"Bombed from the air" if klass!="sea" else "Shelled from the sea").size()
				WorldSimulation.settlements.damage_city_form(damage*.5)
			if civilian or mission=="logistics_strike":
				out.stores=_burn_stores(minf(STORES_LOSS_CAP,STORES_LOSS_PER_DAY*intensity))
			return out)
		# The people who were struck: fear, cohesion, and the army's morale.
		if civilian and intensity>0.0:
			var metrics:Dictionary=WorldSimulation.state.simulation_metrics
			metrics["war_fear"]=clampf(float(metrics.get("war_fear",0.0))+.02*intensity,0.0,1.0)
			for pair in [["cohesion",.0015],["security",.002],["legitimacy",.0008]]:
				metrics[pair[0]]=clampf(float(metrics.get(pair[0],.5))-float(pair[1])*intensity,.05,1.0)
			var army:Dictionary=WorldSimulation.military.home_army
			if not army.is_empty():army["morale"]=clampf(float(army.get("morale",1.0))-.004*intensity,.3,1.5)
		if mission=="invasion_support" or civilian:
			local_outcome["troops"]=_bombard_defenders(local,intensity,attacker)
		# Airfields and harbours in the town; a port strike goes for the harbour.
		for base:Dictionary in WorldSimulation.military.joint_operations.state.bases:
			if String(base.city_id)!=local or String(base.owner)!="player":continue
			if mission=="port_strike" and String(base.domain)!="navy":continue
			base.condition=maxf(0,float(base.condition)-damage*(2.0 if mission=="port_strike" else 1.0))
		if civilian and int(local_outcome.get("dead",0))+int(local_outcome.get("plots",0))>0:
			_event_once(WorldSimulation.military.joint_operations,("Enemy aircraft struck %s" if klass!="sea" else "Enemy ships shelled %s") % String(local_outcome.get("name","our town")),": %d killed, %d fled, %d buildings hit." % [int(local_outcome.get("dead",0)),int(local_outcome.get("displaced",0)),int(local_outcome.get("plots",0))],"air" if klass!="sea" else "navy")
		# Grudge: the struck people's view of whoever bombed them.
		var theirs:=relation(view_id(attacker))
		if not theirs.is_empty() and civilian:theirs["opinion"]=clampf(float(theirs.get("opinion",0.0))-.01*intensity,-1.0,1.0)
		return local_outcome)
	if result==null:return outcome
	force[carry_key]=float(result.get("carry",0.0))
	for key in ["dead","displaced","plots","stores","troops"]:outcome[key]=result.get(key,outcome[key])
	outcome["name"]=String(result.get("name",""))
	if civilian and int(outcome.dead)+int(outcome.plots)>0 and String(force.get("owner",""))=="player":
		_event_once(WorldSimulation.military.joint_operations,"%s struck %s" % [String(force.get("name","Our force")),String(outcome.get("name","their town"))],": about %d of their people killed and %d buildings hit." % [int(outcome.dead),int(outcome.plots)],String(force.get("domain","air")))
	if civilian:
		_attacker_consequences(attacker,target,view,region_id,int(outcome.dead),intensity)
		note_losses(target,attacker,{"civilian_dead":int(outcome.dead),"displaced":int(outcome.displaced)},{"raid":1,"city":String(outcome.get("name","")),"force":String(force.get("name",""))})
	return outcome

## A joint event told at most once a month for the same subject.
static func _event_once(op,subject:String,detail:String,domain:String)->void:
	var day:=int(op.state.get("last_day",0))
	for event:Dictionary in op.state.events:
		if day-int(event.get("day",-9999))>30:break
		if String(event.get("text","")).begins_with(subject):return
	op._event(subject+detail,domain)

## What the attacker's own side records: the struck people's dread of the god
## (when the god's own people bombed them) and the struck ruler's grudge.
static func _attacker_consequences(attacker:String,target:String,view:String,region_id:String,dead:int,intensity:float)->void:
	if attacker!="player" or target=="player" or here()!="player":return
	var name:=String(WorldSimulation.world.city_intelligence.site(region_id).get("name","their town"))
	preload("res://scripts/divine_regard.gd").add_civ_dread(view,.01*intensity+minf(.05,float(dead)*.0005))
	preload("res://scripts/rival_rulers.gd").grudge(view,"Your bombers struck %s and killed our people." % name,.06*intensity,"bombing:"+region_id)

static func _strike_legacy_rival(force:Dictionary,view:String,region_id:String,damage:float,mission:String,civilian:bool,intensity:float,klass:String,outcome:Dictionary)->Dictionary:
	var location:Dictionary=WorldSimulation.world._region_location(region_id)
	if location.is_empty():return outcome
	var civ:Dictionary=WorldSimulation.world.civilizations[int(location.owner_index)]
	var region:Dictionary=civ.strategic_regions[int(location.region_index)]
	if mission=="invasion_support":region.fortification=maxf(0,float(region.fortification)-damage)
	if civilian or mission=="logistics_strike":region.damage=minf(1,float(region.damage)+damage)
	if mission=="logistics_strike":civ.logistics=maxf(.02,float(civ.logistics)-damage*.2)
	for base:Dictionary in WorldSimulation.military.joint_operations.state.bases:
		if String(base.city_id)==region_id and (mission!="port_strike" or String(base.domain)=="navy"):base.condition=maxf(0,float(base.condition)-damage*(2.0 if mission=="port_strike" else 1.0))
	if civilian:
		var population:=float(region.get("population",0))
		var expected:=population*float(CIVILIAN_DEATH_RATE.get(klass,0.00008))*intensity+float(force.get("strike_carry",0.0))
		var requested:=mini(floori(expected),roundi(population*DEATH_CAP_PER_DAY))
		force["strike_carry"]=clampf(expected-float(requested),0.0,50.0)
		if requested>0:
			var dead:Dictionary=WorldSimulation.world._apply_rival_civilian_deaths(civ,region_id,requested)
			WorldSimulation.world.civilizations[int(location.owner_index)]=dead.civilization
			outcome.dead=int(dead.dead)
		_attacker_consequences("player",String(civ.id),String(civ.id),region_id,int(outcome.dead),intensity)
		note_losses(String(civ.id),"player",{"civilian_dead":int(outcome.dead)},{"raid":1,"city":String(region.get("name","")),"force":String(force.get("name",""))})
	return outcome

## Burns a share of this city's food and materials. Returns the food burned.
static func _burn_stores(share:float)->float:
	if share<=0.0:return 0.0
	var food:=WorldSimulation.food.total_stored()*share
	var burned:=WorldSimulation.food.issue_for_obligation(food,"war_loss","Stores burned in a raid") if food>.01 else 0.0
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for material in STORE_MATERIALS:
		if float(stocks.get(material,0.0))>0.0:stocks[material]=float(stocks[material])*(1.0-share)
	return burned

## Bombardment and naval gunfire on the defenders of a city (in its owner's
## scope). Only the capital's home army stands in a city. Returns casualties.
static func _bombard_defenders(local:String,intensity:float,attacker:String)->int:
	var military=WorldSimulation.military
	var defense:Dictionary=military.settlement_defense
	if not defense.is_empty():defense["integrity"]=clampf(float(defense.get("integrity",1.0))-.01*intensity,0.0,1.0)
	var primary:=bool(WorldSimulation.settlements.settlement_record(local).get("primary",local==WorldSimulation.settlements._primary_settlement_id()))
	if not primary:return 0
	var troops:=int(military.home_army.get("troops",0))
	if troops<=0:return 0
	var dug_in:=clampf(float(defense.get("integrity",1.0))*float(defense.get("stage",0))/5.0,0.0,1.0)
	var expected:=float(troops)*.002*intensity*(1.0-.6*dug_in)
	var carry:=float(military.home_army.get("bombardment_carry",0.0))+expected
	var hit:=mini(floori(carry),troops)
	military.home_army["bombardment_carry"]=carry-float(hit)
	if hit<=0:return 0
	var killed:=roundi(float(hit)*.3)
	remove_home_troops(hit,killed)
	note_losses(here(),attacker if attacker!=here() else "",{"military_dead":killed,"wounded":hit-killed},{})
	return hit

## Removes `count` defenders from the home army's formations (last first):
## `killed` die, the rest join the army's wounded, as in battle.
static func remove_home_troops(count:int,killed:int)->void:
	var army:Dictionary=WorldSimulation.military.home_army
	var remaining:=mini(count,int(army.get("troops",0)))
	var total:=remaining
	var formations:Array=army.get("formations",[])
	for index in range(formations.size()-1,-1,-1):
		if remaining<=0:break
		var formation:Dictionary=formations[index]
		var removed:=mini(remaining,maxi(0,int(formation.get("count",0))))
		formation["count"]=int(formation.get("count",0))-removed
		remaining-=removed
	var taken:=total-remaining
	army["troops"]=maxi(0,int(army.get("troops",0))-taken)
	var dead:=mini(killed,taken)
	army["wounded_pool"]=int(army.get("wounded_pool",0))+taken-dead
	if dead>0:
		WorldSimulation.state.register_population_deaths(dead,"Killed in battle")
		WorldSimulation.military._record_aggregate_military_deaths(dead,"Killed under bombardment")

# --------------------------------------------------------------------------
# Air defence over a target
# --------------------------------------------------------------------------

## The share of a raiding wing's airframes a city's ground defences bring down
## today (runs in the attacker's scope, reads the defender's own army).
static func ground_fire_share(city:Dictionary)->float:
	var view:=String(city.get("controller",city.get("civ_id","")))
	if view=="":return AA_BASELINE
	var region_id:=String(city.get("city_id",""))
	var target:=Combat.owner(view) if WorldSimulation.enabled else view
	if WorldSimulation.enabled and target!="player" and not WorldSimulation.actors.has(target):return AA_BASELINE
	if not WorldSimulation.enabled and target!="player":
		var truth:=WorldSimulation.world.city_intelligence.truth(region_id)
		return AA_BASELINE+AA_LOSS_CAP*.5*clampf(float(truth.get("values",{}).get("fortification",0.0)),0.0,1.0)
	var local:=region_id if view=="player" else Combat.local_city(view,region_id)
	var share:Variant=_in(target,func()->float:return defence_strength(local))
	return AA_BASELINE+AA_LOSS_CAP*clampf(float(share if share!=null else 0.0),0.0,1.0)

## 0..1: how well a city (in its owner's scope) can shoot at aircraft overhead.
## Antiaircraft batteries in the home army count most; walls and guns once
## there are aircraft to aim at; nothing before flight is known.
static func defence_strength(local:String)->float:
	if not ("powered_flight" in WorldSimulation.state.known_discoveries or "aerial_bombardment" in WorldSimulation.state.known_discoveries):return 0.0
	var military=WorldSimulation.military
	var batteries:=0
	for army:Dictionary in [military.home_army]+military.field_armies:
		for formation in army.get("formations",[]):
			if formation is Dictionary and String((formation as Dictionary).get("unit",""))=="anti_air":batteries+=int(formation.get("count",0))
	var primary:=local=="" or bool(WorldSimulation.settlements.settlement_record(local).get("primary",false))
	var walls:=clampf(float(military.settlement_defense.get("stage",0))/5.0,0.0,1.0) if primary else 0.0
	return clampf(float(batteries)/(float(batteries)+60.0)+walls*.25,0.0,1.0)

# --------------------------------------------------------------------------
# Crews
# --------------------------------------------------------------------------

## What happened to the crews of `lost` hulls or airframes of one type.
## `own_ground`: lost over or near their own waters and ground.
## Small crews are counted whole: fractions are settled by a seeded draw so a
## one-seat fighter's pilot is killed about as often as the profile says.
static func crew_casualties(type_id:String,lost:int,own_ground:bool,seed:int=0)->Dictionary:
	var people:=maxi(0,lost)*int(C.UNITS.get(type_id,{}).get("crew",0))
	var shares:Array=CREW_PROFILES[profile(type_id)]["own" if own_ground else "away"]
	var rng:=RandomNumberGenerator.new();rng.seed=seed^hash("%s:%d:%d" % [type_id,lost,int(own_ground)])
	var killed:=mini(people,_whole(float(people)*float(shares[0]),rng))
	var wounded:=mini(people-killed,_whole(float(people)*float(shares[1]),rng))
	var captured:=mini(people-killed-wounded,_whole(float(people)*float(shares[3]),rng))
	return {"killed":killed,"wounded":wounded,"captured":captured,"rescued":people-killed-wounded-captured,"people":people}

static func _whole(expected:float,rng:RandomNumberGenerator)->int:
	var whole:=floori(expected)
	return whole+(1 if rng.randf()<expected-float(whole) else 0)

## Casualties among the crews of hulls hit but still afloat or flying:
## `fraction` is the day's damage as a share of the force's strength.
static func damaged_crew_casualties(crew:int,fraction:float,seed:int=0)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed^0x5bd1e995
	var hit:=mini(crew,_whole(float(crew)*clampf(fraction,0.0,1.0)*.1,rng))
	var killed:=_whole(float(hit)*.3,rng)
	return {"killed":killed,"wounded":hit-killed}

# --------------------------------------------------------------------------
# War totals, exhaustion and the Chronicle
# --------------------------------------------------------------------------

## Records losses suffered by `victim` (a global owner) at the hands of
## `enemy` (global owner, may be empty): the victim's war ledger (flushed to
## the war record monthly), war exhaustion on both sides, and the Chronicle.
## `fields`: military_dead, civilian_dead, wounded, captured, displaced.
## `story`: optional {sunk, downed, raid, drowned, city, force, type}.
static func note_losses(victim:String,enemy:String,fields:Dictionary,story:Dictionary)->void:
	var dead:=int(fields.get("military_dead",0))+int(fields.get("civilian_dead",0))
	if not WorldSimulation.enabled:
		# The older world model owns only the human's people; rivals are summaries.
		var own_op=WorldSimulation.military.joint_operations
		if victim=="player":
			_ledger_add(own_op,enemy,"ours",fields)
			var ours:=relation(enemy)
			if not ours.is_empty() and dead>0:ours["player_war_exhaustion"]=clampf(float(ours.get("player_war_exhaustion",0.0))+float(dead)/maxf(1.0,WorldSimulation.state.population_exact+float(dead))*5.0,0.0,1.0)
			_tell(true,true,fields,story)
		elif enemy=="player":
			_ledger_add(own_op,victim,"theirs",fields)
			var theirs:=relation(victim)
			if not theirs.is_empty() and dead>0:theirs["rival_war_exhaustion"]=clampf(float(theirs.get("rival_war_exhaustion",0.0))+float(dead)/_population_of(victim)*5.0,0.0,1.0)
			_tell(true,false,fields,story)
		return
	_in(victim,func()->void:
		var op=WorldSimulation.military.joint_operations
		var enemy_view:=view_id(enemy) if enemy!="" else ""
		_ledger_add(op,enemy_view,"ours",fields)
		if enemy_view!="" and dead>0:
			var ours:=relation(enemy_view)
			if not ours.is_empty():ours["player_war_exhaustion"]=clampf(float(ours.get("player_war_exhaustion",0.0))+float(dead)/maxf(1.0,WorldSimulation.state.population_exact+float(dead))*5.0,0.0,1.0)
		_tell(WorldSimulation.state==GameState,true,fields,story))
	if enemy=="" or enemy==victim:return
	_in(enemy,func()->void:
		var op=WorldSimulation.military.joint_operations
		_ledger_add(op,view_id(victim),"theirs",fields)
		if dead>0:
			var theirs:=relation(view_id(victim))
			if not theirs.is_empty():theirs["rival_war_exhaustion"]=clampf(float(theirs.get("rival_war_exhaustion",0.0))+float(dead)/maxf(1.0,float(_population_of(view_id(victim))))*5.0,0.0,1.0)
		_tell(WorldSimulation.state==GameState,false,fields,story))

static func _population_of(view:String)->float:
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if String(civ.get("id",""))==view:return maxf(1.0,float(civ.get("population",1.0)))
	return 1000.0

static func _ledger_add(op,enemy_view:String,side:String,fields:Dictionary)->void:
	if enemy_view=="":return
	var ledger:Dictionary=op.state.get_or_add("war_ledger",{})
	if ledger.size()>=32 and not ledger.has(enemy_view):return
	var entry:Dictionary=ledger.get_or_add(enemy_view,{"since":int(WorldSimulation.state.elapsed_days),"ours":{},"theirs":{}})
	var totals:Dictionary=entry[side]
	for key in ["military_dead","civilian_dead","wounded","captured","displaced"]:
		if int(fields.get(key,0))>0:totals[key]=int(totals.get(key,0))+int(fields[key])

## Monthly: each enemy's air and sea losses become one entry in the war's
## record (CivilizationSystem._record_war_battle), so war totals include them.
static func flush_war_ledger(op,day:int)->void:
	var ledger:Dictionary=op.state.get("war_ledger",{})
	for enemy_view in ledger.keys():
		var entry:Dictionary=ledger[enemy_view]
		if day-int(entry.get("since",day))<WAR_LEDGER_DAYS:continue
		ledger.erase(enemy_view)
		var ours:Dictionary=entry.get("ours",{});var theirs:Dictionary=entry.get("theirs",{})
		if ours.is_empty() and theirs.is_empty():continue
		var war_id:=String(relation(String(enemy_view)).get("war_id",""))
		if war_id=="":continue
		WorldSimulation.world._record_war_battle(war_id,{"day":day,"name":"The war at sea and in the air","location":"sea and air","outcome":"continued","losses":{"player":ours.duplicate(),String(enemy_view):theirs.duplicate()}})

## The Chronicle (the human's own people only). A sinking of a large ship, a
## bad day in the air, a bombed town (once a month each) and every drowned
## troop transport are told; the rest is folded into the year's entry.
static func _tell(active:bool,ours:bool,fields:Dictionary,story:Dictionary)->void:
	if not active or not Chronicle.active():return
	var day:=int(GameState.elapsed_days)
	var fact:={"sunk":0,"downed":0,"crew_dead":0,"civilians":0,"raids":0,"drowned":0,"enemy_sunk":0,"enemy_downed":0,"enemy_civilians":0,"enemy_raids":0}
	var sunk:=int(story.get("sunk",0));var downed:=int(story.get("downed",0))
	if ours:
		fact.sunk=sunk;fact.downed=downed;fact.crew_dead=int(fields.get("military_dead",0))
		fact.civilians=int(fields.get("civilian_dead",0));fact.raids=int(story.get("raid",0));fact.drowned=int(story.get("drowned",0))
	else:
		fact.enemy_sunk=sunk;fact.enemy_downed=downed;fact.enemy_civilians=int(fields.get("civilian_dead",0));fact.enemy_raids=int(story.get("raid",0))
	preload("res://scripts/chronicle_annals.gd").note_war_losses(Chronicle.data(),fact)
	var boats:=_boat_word()
	var label:=String(story.get("type_label","")).to_lower()
	var force:=String(story.get("force",""))
	var dead:=int(fields.get("military_dead",0))
	var taken:=int(fields.get("captured",0))
	if int(story.get("drowned",0))>0 and ours:
		Chronicle.record({"title":"Transports Went Down","text":"Transports carrying %s went down. %d soldiers drowned; %d were pulled from the water%s." % [force if force!="" else "our soldiers",int(story.drowned),int(story.get("saved",0)),"; %d were taken by the enemy" % taken if taken>0 else ""],"kind":"war","tier":"notice","key":"drowned:%d:%s" % [day,force]})
		return
	if sunk>0 and int(story.get("crew",0))>=100:
		if ours:Chronicle.record({"title":"%s Lost" % (force if force!="" else "A Ship"),"text":"%s lost %d %s. %d of the crew died%s." % [force,sunk,label if label!="" else boats,dead,"; %d were taken prisoner" % taken if taken>0 else ""],"kind":"war","tier":"notice","key":"sunk:%d:%s" % [day,force]})
		else:Chronicle.record({"title":"Enemy %s Sunk" % _cap(boats),"text":"Our %s sank %d of their %s. %d of their crews died%s." % [String(story.get("by","ships")),sunk,label if label!="" else boats,dead,"; %d were brought in as prisoners" % taken if taken>0 else ""],"kind":"war","tier":"notice","key":"enemy_sunk:%d:%s" % [day,force]})
		return
	if downed>=3 and ours:
		Chronicle.record({"title":"A Bad Day in the Air","text":"%s lost %d %s. %d airmen died%s." % [force,downed,label if label!="" else "aircraft",dead,"; %d came down behind their lines and were taken" % taken if taken>0 else ""],"kind":"war","tier":"notice","key":"downed:%d:%s" % [day/7,force]})
		return
	if int(story.get("raid",0))>0 and ours and String(story.get("city",""))!="":
		var city:=String(story.city)
		if int(fields.get("civilian_dead",0))>0:
			Chronicle.record({"title":"%s Bombed" % city,"text":"Enemy aircraft struck %s. %d people were killed and %d fled their homes." % [city,int(fields.get("civilian_dead",0)),int(fields.get("displaced",0))],"kind":"war","tier":"notice","key":"raid:%s:%d" % [city,day/30]})

static func _boat_word()->String:
	return "boats" if preload("res://scripts/hud/era_words.gd").stage()=="hearth" else "ships"

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

## Soldiers aboard lost troop transports: [killed, wounded, rescued, captured]
## = 45/10/40/5%. Sinkings far from help drowned most aboard; near escorts
## most were pulled out.
static func transport_fates(people:int,enemy:String)->Dictionary:
	var killed:=roundi(float(people)*.45)
	var wounded:=mini(people-killed,roundi(float(people)*.10))
	var captured:=mini(people-killed-wounded,roundi(float(people)*.05)) if enemy!="" else 0
	return {"killed":killed,"wounded":wounded,"captured":captured,"rescued":people-killed-wounded-captured}

## A lost transport's soldiers reach the war record, the enemy's prisoners
## and the Chronicle (runs in the transport owner's scope).
static func transport_lost(army:Dictionary,fate:Dictionary,enemy:String)->void:
	var captured:=int(fate.get("captured",0))
	if captured>0 and enemy!="":_in(enemy,func()->void:WorldSimulation.military.receive_scout_captives(captured))
	note_losses(here(),enemy,{"military_dead":int(fate.killed),"wounded":int(fate.wounded),"captured":captured},{"drowned":int(fate.killed),"saved":int(fate.rescued),"force":String(army.get("name","A troop transport"))})

# --------------------------------------------------------------------------
# Opposed landings
# --------------------------------------------------------------------------

## Fights the landing of `army` at the destination city of `convoy` (runs in
## the landing side's scope). Both sides lose people; a beach held too strongly
## throws the landing back. Returns {repulsed, attacker_killed, attacker_wounded,
## defender_hit}.
static func opposed_landing(army:Dictionary,convoy:Dictionary,naval_support:float)->Dictionary:
	var attackers:=int(army.get("troops",0))
	var outcome:={"repulsed":false,"attacker_killed":0,"attacker_wounded":0,"defender_hit":0,"defenders":0}
	if attackers<=0:return outcome
	var view:=String(convoy.get("destination_owner",""))
	var region_id:=String(convoy.get("destination_id",""))
	var truth:=WorldSimulation.world.city_intelligence.truth(region_id)
	var values:Dictionary=truth.get("values",{})
	var garrison:=maxf(0.0,float(values.get("garrison",0.0)))
	var fort:=clampf(float(values.get("fortification",0.0)),0.0,1.0)
	# Only part of a garrison can stand on the beach; the rest holds the town.
	var defenders:=garrison*.3+float(attackers)*.02
	outcome.defenders=roundi(defenders)
	var ratio:=defenders/maxf(1.0,defenders+float(attackers))
	var support:=clampf(naval_support,0.0,1.0)
	var loss:=clampf(.02+.30*ratio*(1.0+fort)*(1.0-.4*support),.02,.35)
	outcome.repulsed=ratio*(1.0+fort)*(1.0-.3*support)>.55
	if bool(outcome.repulsed):loss=clampf(loss*1.6,.3,.55)
	var hit:=roundi(float(attackers)*loss)
	var killed:=roundi(float(hit)*.35)
	outcome.attacker_killed=killed;outcome.attacker_wounded=hit-killed
	_remove_field_army_troops(army,hit,killed)
	var defender_loss:=clampf(.05+.25*(1.0-ratio)*(.7+.6*support),.03,.4)
	var defender_hit:=roundi(defenders*defender_loss)
	var target:=Combat.owner(view) if WorldSimulation.enabled else view
	if WorldSimulation.enabled and (target=="player" or WorldSimulation.actors.has(target)):
		var local:=Combat.local_city(view,region_id)
		var removed:Variant=_in(target,func()->int:
			var primary:=bool(WorldSimulation.settlements.settlement_record(local).get("primary",false))
			if not primary:return 0
			var available:=mini(defender_hit,int(WorldSimulation.military.home_army.get("troops",0)))
			remove_home_troops(available,roundi(float(available)*.35))
			return available)
		outcome.defender_hit=int(removed if removed!=null else 0)
	elif not WorldSimulation.enabled and view!="player":
		var location:Dictionary=WorldSimulation.world._region_location(region_id)
		if not location.is_empty():
			var civ:Dictionary=WorldSimulation.world.civilizations[int(location.owner_index)]
			civ["military_population"]=maxf(0.0,float(civ.get("military_population",0))-float(defender_hit))
			outcome.defender_hit=defender_hit
	var enemy:=target if WorldSimulation.enabled else ""
	note_losses(here(),enemy,{"military_dead":killed,"wounded":hit-killed},{})
	if enemy!="" and int(outcome.defender_hit)>0:
		note_losses(enemy,here(),{"military_dead":roundi(float(outcome.defender_hit)*.35),"wounded":int(outcome.defender_hit)-roundi(float(outcome.defender_hit)*.35)},{})
	return outcome

static func _remove_field_army_troops(army:Dictionary,count:int,killed:int)->void:
	var remaining:=mini(count,int(army.get("troops",0)))
	var total:=remaining
	for formation:Dictionary in army.get("formations",[]):
		if remaining<=0:break
		var removed:=mini(remaining,maxi(0,int(formation.get("count",0))))
		formation["count"]=int(formation.get("count",0))-removed
		remaining-=removed
	var taken:=total-remaining
	army["troops"]=maxi(0,int(army.get("troops",0))-taken)
	var dead:=mini(killed,taken)
	army["wounded_pool"]=int(army.get("wounded_pool",0))+taken-dead
	if dead>0:
		WorldSimulation.state.register_population_deaths(dead,"Killed in battle")
		WorldSimulation.military._record_aggregate_military_deaths(dead,"Killed in a landing")

# --------------------------------------------------------------------------
# Commerce raiding and blockades across civilizations
# --------------------------------------------------------------------------

## Raiding pressure (0..MERCHANT_LOSS_CAP) on a people's sea trade from raiders
## worth `raid` against escorts worth `escort`.
static func raiding_level(raid:float,escort:float)->float:
	if raid<=0.0:return 0.0
	return clampf(MERCHANT_LOSS_CAP*raid/(raid+escort*1.5+20.0),0.0,MERCHANT_LOSS_CAP)
