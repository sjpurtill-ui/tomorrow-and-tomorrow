extends RefCounted
## THE BATTLE EVALUATION HARNESS: plays one war situation end to end through
## the real engine (MilitaryCampaign's day, the block battle, the generals'
## tactics, the aftermath, the court's daily war step) and checks everything
## the player would see of it, against the engine's own ledgers:
##
##   range      outcomes stay within historical ranges (docs/ADJUDICATION.md)
##   ledger     forces add up before and after: troops, killed / wounded /
##              fled / taken, captives, stores; the record adds up in itself
##   report     exactly one report per battle, in the war leader's voice,
##              with the right numbers; its Chronicle entry
##   record     the battle record steps through without being fought again
##              and says what the report says
##   panel      the battle panel's view model (hud/battle_view.gd list_now,
##              battle_record.gd view) agrees with the engine each day; the
##              battle screen draws the engine's own blocks day by day (men,
##              where they stand, broken, fled), and its strength bars,
##              balance, days, arrows and era mark agree with the engine and
##              the map
##   marker     the map's battle marks (hud/battle_marker_source.gd through
##              the war chart's own collect) agree with the engine and panel
##   aftermath  captives and spoils are settled by the general and never
##              block an order; no march is refused over paperwork
##   front      a tiny party gets no front or worm
##   timing     one phase a day; lopsided or tiny fights decided at once
##   speed      a day of many battles stays fast
##   expect     what the scenario itself is about (the overrun, the rout...)
##
## run(scenario) returns {id, kind, era, ok, fails:[{code,text}], notes, ms}.
## Scenarios are data (tests/battle_eval/scenarios.gd). Nothing here writes a
## save or touches the player's files.

const Record:=preload("res://scripts/battle_record.gd")
const Account:=preload("res://scripts/battle_account.gd")
const View:=preload("res://scripts/hud/battle_view.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Source:=preload("res://scripts/hud/battle_marker_source.gd")
const OverlayScript:=preload("res://scripts/hud/war_front_overlay.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const FieldRations:=preload("res://scripts/field_rations.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")

const WORLD_SEED:=74017
const DAY0:=88*365
## Historical ranges (docs/ADJUDICATION.md; tests/test_battle_scale.gd).
## Pre-industrial pitched battles: a winner usually lost well under a fifth
## of those it took in, very rarely more than a third; the beaten side lost
## far more, most of it fled or taken rather than killed. Wounded outnumber
## the killed. An overrun costs the big side almost nobody.
const WINNER_LOSS_MAX:=0.35
const WINNER_KILLED_MAX:=0.12
const LOSER_KILLED_MAX:=0.55
const KILLED_SHARE_MAX:=0.62
## A routed side is cut down as it runs: more of its casualties are dead.
const ROUTED_KILLED_SHARE_MAX:=0.78
const OVERRUN_BIG_LOSS_MAX:=0.06
## Longest a battle is fought (hours of fighting), by the larger side's size.
const HOURS_SMALL:=8.0
const HOURS_ANY:=24.0
const SMALL_SIDE:=60
## The least a pitched battle between large, comparable hosts (each at least
## LARGE_SIDE, the smaller at least COMPARABLE of the larger) is fought, in
## hours, by age: before gunpowder an hour and a half or more (Marathon,
## Cannae, Hastings: one to eight hours); pike, shot and muskets a long day,
## three hours or more of the engine's six-exchange day (Breitenfeld, Rocroi,
## Waterloo); the rifle and armour ages at least two of the engine's days of
## fighting, eight hours (Antietam, Sedan; armoured battles days).
const LARGE_SIDE:=5000
const COMPARABLE:=0.6
const MIN_HOURS_BY_AGE:=[1.5,1.5,1.5,3.0,8.0,8.0]
## In the rifle and armour ages a winning host loses at most this share of
## its strength an hour of fighting (divisions in hard fighting: a few in a
## hundred a day).
const WINNER_LOSS_PER_HOUR_LATE:=0.03
## A day of this many battles must be fought within this many milliseconds.
const DAY_BUDGET_MS:=900.0

var suite:Node
var s:Dictionary={}
var fails:Array=[]
var notes:Array=[]
var civ_id:=""
var civ2_id:=""
var city_id:=""
var city2_id:=""
var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city2:=Vector2.ZERO
var overlay:Control=null
var resolved:Array=[]
var traces:Dictionary={}
var water:Array=[]
var hills:Array=[]
var forest:Array=[]
var river:Array=[]
var today_fights:Dictionary={}
var _listening:=false


func _init(host:Node=null)->void:
	suite=host


# =============================================================================
# Running one scenario
# =============================================================================

func run(scenario:Dictionary)->Dictionary:
	s=scenario
	fails=[]; notes=[]; resolved=[]; traces={}; water=[]; hills=[]; forest=[]; river=[]
	var started:=Time.get_ticks_usec()
	_listen(true)
	overlay=OverlayScript.new()
	var t0:=Time.get_ticks_usec()
	reset_world(scenario)
	if OS.get_environment("BATTLE_EVAL_PROFILE")=="1": _note("reset %.0f ms" % (float(Time.get_ticks_usec()-t0)/1000.0))
	var kind:=String(scenario.get("kind","field"))
	if has_method("_run_"+kind): call("_run_"+kind)
	else: _fail("setup","no runner for kind "+kind)
	_listen(false)
	if is_instance_valid(overlay): overlay.free()
	overlay=null
	var ms:=float(Time.get_ticks_usec()-started)/1000.0
	var budget:=float(scenario.get("budget_ms",6000.0))
	if ms>budget: _fail("speed","the scenario took %.0f ms (budget %.0f)" % [ms,budget])
	var codes:={}
	for f in fails: codes[String((f as Dictionary).code)]=true
	return {"id":String(scenario.get("id","")),"kind":kind,"era":int(scenario.get("era",0)),"ok":fails.is_empty(),"fails":fails.duplicate(true),"notes":notes.duplicate(),"ms":ms,"codes":codes.keys()}


func _listen(on:bool)->void:
	if on and not _listening:
		MilitaryCampaign.battle_resolved.connect(_on_resolved); _listening=true
	elif not on and _listening:
		if MilitaryCampaign.battle_resolved.is_connected(_on_resolved): MilitaryCampaign.battle_resolved.disconnect(_on_resolved)
		_listening=false


func _on_resolved(result:Dictionary)->void:
	resolved.append({"seed":int(result.get("seed",0)),"id":String(result.get("id","")),"day":int(GameState.elapsed_days)})


func _fail(code:String,text:String)->void:
	fails.append({"code":code,"text":text})


func _check(ok:bool,code:String,text:String)->bool:
	if not ok: _fail(code,text)
	return ok


func _note(text:String)->void:
	notes.append(text)


# =============================================================================
# The world
# =============================================================================

func reset_world(scenario:Dictionary)->void:
	WorldSimulation.enabled=false
	WorldSimulation.clear()
	var key:="officials" if bool(scenario.get("officials",false)) else "plain"
	if not bases.has(key): bases[key]=_build_base(key=="officials")
	var base:Dictionary=bases[key]
	var problem:=_restore(base.snap)
	if problem!="": _fail("setup","the world did not restore: "+problem)
	civ_id=String(base.civ_id); civ2_id=String(base.civ2_id); city_id=String(base.city_id); city2_id=String(base.city2_id)
	home=base.home; city=base.city; city2=base.city2
	# What this scenario changes in the world.
	var people:=int(scenario.get("population",1400))
	if people>int(GameState.population_total): GameState.ensure_population_total(people); GameState.housing_capacity=people+400
	GameState.resource_stockpiles["Food"]=float(scenario.get("food",1000000.0))
	GameState.known_discoveries.clear()
	for id in _discoveries_for(int(scenario.get("era",0))): GameState.known_discoveries.append(id)
	GameState.population_allocations["Defense"]=int(scenario.get("watch",3))
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._region_index(civ,city_id)]
	region["population"]=float(scenario.get("town_people",400.0))
	for r in scenario.get("water",[]): water.append(_rect(r))
	for r in scenario.get("hills",[]): hills.append(_rect(r))
	for r in scenario.get("forest",[]): forest.append(_rect(r))
	for r in scenario.get("river",[]): river.append(_rect(r))
	Route.clear_cache()
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	CivilizationSystem.set_ground_survey_authority(Callable(self,"_survey"))
	MilitaryCampaign.last_processed_day=DAY0
	for part in (scenario.get("practice",{}) as Dictionary): MilitaryCampaign.set_aftermath_practice(String(part),String(scenario.practice[part]))


## The worlds built once per run (by whether the court's officials are
## appointed) and restored for each scenario from a snapshot of every
## simulation autoload, as the court evaluation does (~25 ms, not ~1.5 s).
var bases:Dictionary={}


func _build_base(officials:bool)->Dictionary:
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(WORLD_SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure(); GovernmentPeopleSystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	GameState.ensure_population_total(1400); GameState.housing_capacity=1800
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.elapsed_days=DAY0
	if officials:
		GameState.society_capacities["institutions"]=0.4
		GovernmentPeopleSystem._update_government_stage(false)
		GovernmentPeopleSystem.initialize()
	var out:={}
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	out["civ_id"]=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation["at_war"]=true; relation["contact_level"]=2; relation["home_location_known"]=true; relation["met_day"]=0
	# The world's own rule: a people at war with us is under the war treaty state.
	relation["treaty"]="war"; relation["opinion"]=-0.4; relation["border_tension"]=0.7
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	out["city_id"]=String(region.id)
	out["home"]=CivilizationSystem.player_world_origin
	out["city"]=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	# The world's own site for Tsaren is where our chart draws it (in play the
	# two agree; every observation re-publishes the true site).
	region["position"]=out.city
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(out.city_id),.8,DAY0,"scout report","test"),DAY0)
	CivilizationSystem.city_intelligence.records.player[String(out.city_id)]["position"]={"x":(out.city as Vector2).x,"z":(out.city as Vector2).y}
	out["civ2_id"]=""; out["city2_id"]=""; out["city2"]=Vector2.INF
	if CivilizationSystem.civilizations.size()>1:
		var other:Dictionary=CivilizationSystem.civilizations[1]
		other["name"]="Cedar League"
		out["civ2_id"]=String(other.id)
		var r2:Dictionary=other.player_relation
		r2["contact_level"]=2; r2["home_location_known"]=true; r2["met_day"]=0
		var index2:=CivilizationSystem._frontline_region_index(other)
		if index2>=0:
			var region2:Dictionary=other.strategic_regions[index2]
			region2["name"]="Varrow"
			out["city2_id"]=String(region2.id)
			out["city2"]=CivilizationSystem.player_world_origin+Vector2(30.0,-12.0)
			region2["position"]=out.city2
			CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(out.city2_id),.8,DAY0,"scout report","test"),DAY0)
			CivilizationSystem.city_intelligence.records.player[String(out.city2_id)]["position"]={"x":(out.city2 as Vector2).x,"z":(out.city2 as Vector2).y}
	MilitaryCampaign.last_processed_day=DAY0
	out["snap"]=_snapshot()
	return out


const Save:=preload("res://scripts/save_system.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")


func _node(name:String)->Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/"+name)


func _snapshot()->Dictionary:
	var out:={}
	for name in Save.REFLECTED_SYSTEMS: out["r:"+name]=Save._capture_reflected(_node(name),Save.REFLECT_SKIP.get(name,[]))
	out["society"]=Save._capture_reflected(DiscoverySystem.society_model,Save.SOCIETY_REFLECT_SKIP)
	for name in Save.CURATED_SYSTEMS: out["c:"+name]=_node(name).export_state()
	return out


func _restore(snap:Dictionary)->String:
	WorldSimulation.flush_day()
	for name in Save.REFLECTED_SYSTEMS: Save._apply_reflected(_node(name),(snap["r:"+name] as Dictionary).duplicate(true))
	Save._apply_reflected(DiscoverySystem.society_model,(snap.society as Dictionary).duplicate(true),Save.SOCIETY_REFLECT_SKIP)
	for name in Save.CURATED_SYSTEMS:
		var r:Variant=_node(name).import_state((snap["c:"+name] as Dictionary).duplicate(true))
		if r is Dictionary and (r as Dictionary).has("error"): return "%s: %s %s" % [name,str((r as Dictionary).error),str((r as Dictionary).get("details","")).substr(0,300)]
	Chronicle.pending_cards.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	return ""


## The known discoveries for an age: the words the war leader uses follow
## them (hud/era_words.gd stage: hearth, lettered, reckoned).
func _discoveries_for(era:int)->Array:
	if era>=3: return ["pictographic_records","printing_process"]
	if era==2: return ["pictographic_records"]
	return []


## Rects given relative to home, in km: [x, z, width, height].
func _rect(r:Variant)->Rect2:
	var a:Array=r
	return Rect2(home.x+float(a[0]),home.y+float(a[1]),float(a[2]),float(a[3]))


func _land(p:Vector2)->bool:
	for r in water:
		if (r as Rect2).has_point(p): return false
	for r in river:
		if (r as Rect2).has_point(p): return false
	return true


func _survey(p:Vector2)->Dictionary:
	var out:={"biome":"grassland","slope":0.01,"woodland":0.1,"river_distance_km":INF}
	for r in hills:
		if (r as Rect2).has_point(p): out["biome"]="upland"; out["slope"]=0.14
	for r in forest:
		if (r as Rect2).has_point(p): out["woodland"]=0.8
	for r in river:
		var rect:Rect2=r
		var d:=maxf(maxf(rect.position.x-p.x,p.x-rect.end.x),maxf(rect.position.y-p.y,p.y-rect.end.y))
		out["river_distance_km"]=minf(float(out.river_distance_km),maxf(0.0,d))
	if String(s.get("ground",""))=="pass": out["biome"]="mountain"; out["slope"]=0.3
	elif String(s.get("ground",""))=="marsh": out["biome"]="wetland"
	elif String(s.get("ground",""))=="forest": out["woodland"]=0.8
	elif String(s.get("ground",""))=="rough": out["biome"]="upland"; out["slope"]=0.12
	return out


# =============================================================================
# Forces
# =============================================================================

## Fully armed formations for one of our armies or their bands.
func formations(spec:Array,ours:bool)->Array:
	var out:Array=[]
	for f_variant in spec:
		var f:Dictionary=f_variant
		var unit:=String(f.get("unit","levy")); var weapon:=String(f.get("weapon","improvised")); var n:=int(f.get("count",0))
		var sim:CombatSimulator=MilitaryCampaign.simulator
		var eq:=sim.equipment_required_for_weapon(weapon,n)
		var am:=sim.ammunition_required_for_weapon(weapon,eq,n)
		var formation:={"unit":unit,"weapon":weapon,"count":n,"authorized_count":n,"equipment":int(f.get("equipment",eq)),"equipment_required":eq,"ammunition":am,"ammunition_required":am,
			"training":float(f.get("training",0.6)),"experience":float(f.get("experience",0.1)),"personnel_condition":1.0}
		if ours:
			formation["id"]=MilitaryCampaign.next_formation_id; MilitaryCampaign.next_formation_id+=1
		out.append(formation)
	return out


## One of our field armies, formed at home from new formations and set in
## the field `at` (km from home). opts: name, morale, supply, hungry, general
## ({name, skill, resolve}), at (Vector2 offset), status.
func our_army(spec:Array,opts:Dictionary={})->int:
	var additions:=formations(spec,true)
	var total:=0
	for f in additions: total+=int((f as Dictionary).count)
	MilitaryCampaign._rebuild_home_army_with(additions)
	var made:Dictionary=MilitaryCampaign.create_field_army(total,String(opts.get("name","")))
	if made.has("error"):
		_fail("setup","could not form our army: %s" % String(made.error))
		return 0
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	var offset:Vector2=opts.get("at",Vector2(5.0,0.0))
	army["position"]={"x":home.x+offset.x,"z":home.y+offset.y}
	army["status"]=String(opts.get("status","stationed"))
	if offset.length()>1.0: army["location_id"]="field_position"; army["location_name"]="Commanded ground"
	army["supply_level"]=float(opts.get("supply",1.0))
	if opts.has("morale"): army["morale"]=float(opts.morale)
	if bool(opts.get("hungry",false)): army["hungry_days"]=6.0; army["supply_level"]=0.3
	var general:Dictionary=opts.get("general",{})
	if not general.is_empty():
		# Skill and resolve only: the name stays the general's own (his
		# HistoricalFigures record decides who he is and whether he lives).
		var commander:Dictionary=(army.get("commander",{}) as Dictionary).duplicate(true)
		for key in ["command","tactics"]: commander[key]=float(general.get("skill",commander.get(key,0.5)))
		commander["resolve"]=float(general.get("resolve",commander.get("resolve",0.5)))
		army["commander"]=commander
	MilitaryCampaign.field_armies[index]=army
	MilitaryCampaign._refresh_readiness()
	if opts.has("morale"): MilitaryCampaign.field_armies[index]["morale"]=float(opts.morale)
	return army_id


func army(army_id:int)->Dictionary:
	var index:=MilitaryCampaign._field_army_index(army_id)
	return MilitaryCampaign.field_armies[index] if index>=0 else {}


## Their band: explicit formations, morale and readiness (matching ours
## unless given), a general.
func their_force(spec:Array,opts:Dictionary={},like_army:int=0)->Dictionary:
	var ours:Dictionary=army(like_army) if like_army>0 else {}
	var morale:=float(opts.get("morale",ours.get("morale",0.7)))
	var readiness:=float(opts.get("readiness",ours.get("readiness",0.6)))
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force(String(opts.get("name","Esurai band")),formations(spec,false),morale,readiness)
	var general:Dictionary=opts.get("general",{})
	var skill:=float(general.get("skill",0.5))
	force["commander"]=MilitaryCampaign.simulator.create_commander(String(general.get("name","Tavo Kesh")),skill,skill,0.5,float(general.get("resolve",0.55)))
	if bool(opts.get("hungry",false)): force["hungry_days"]=6.0
	return force


func count_of(spec:Array)->int:
	var n:=0
	for f in spec: n+=int((f as Dictionary).get("count",0))
	return n


# =============================================================================
# Beginning battles (the engine's own entry points)
# =============================================================================

## Our army meets their band in the field (a contact on the march): the
## threat the world would raise, then the battle begun by the engine.
func field_contact(army_id:int,enemy:Dictionary,opts:Dictionary={})->Dictionary:
	var at:=_v2(army(army_id).get("position",{}))
	var there:Vector2=at+Vector2(opts.get("toward",Vector2(0.3,0.0)))
	var formation:=String(opts.get("formation","f%d" % army_id))
	MilitaryCampaign._create_civilization_threat({"id":"contact-"+formation,"source_civ_id":String(opts.get("civ",civ_id)),"source_name":String(opts.get("people","Esurai")),"incident_kind":"campaign",
		"field_encounter":true,"formation_id":formation,"strength":int(enemy.get("troops",0)),"technology":0.2,"readiness":float(enemy.get("readiness",0.5)),
		"target_position":{"x":there.x,"z":there.y},"terrain_defense":float(opts.get("terrain",1.0)),"field_army_id":army_id},"offensive")
	var threat:Dictionary=MilitaryCampaign.active_threat
	threat["enemy_force"]=enemy
	threat["estimated_strength"]=int(enemy.get("troops",0))
	threat["seed"]=int(opts.get("seed",s.get("seed",11)))
	if opts.has("approach"): threat["approach"]=(opts.approach as Dictionary).duplicate(true)
	# As launch_map_engagement: begun, and a hopeless fight settled at once.
	var started:Dictionary=MilitaryCampaign.begin_threat_engagement(false)
	if started.has("error"): _fail("setup","the battle did not begin: %s" % String(started.error))
	elif bool(MilitaryCampaign.active_engagement.get("overrun_expected",false)): return MilitaryCampaign.settle_overrun_now()
	return started


## Their band comes against home; our watch answers ("defend": the engine's
## own response).
func home_attack(enemy:Dictionary,opts:Dictionary={})->Dictionary:
	MilitaryCampaign._create_civilization_threat({"id":"attack-home","source_civ_id":civ_id,"source_name":"Esurai","incident_kind":String(opts.get("incident","raid")),
		"strength":int(enemy.get("troops",0)),"technology":0.2,"readiness":float(enemy.get("readiness",0.5))},"defensive")
	var threat:Dictionary=MilitaryCampaign.active_threat
	threat["enemy_force"]=enemy
	threat["estimated_strength"]=int(enemy.get("troops",0))
	threat["seed"]=int(opts.get("seed",s.get("seed",11)))
	threat["routine_raid"]=preload("res://scripts/raid_policy.gd").routine(threat,MilitaryCampaign._home_defense_force(false))
	var answer:Dictionary=MilitaryCampaign.respond_to_threat(String(opts.get("response","defend")))
	if answer.has("error"): _fail("setup","the defence did not begin: %s" % String(answer.error))
	return answer


## Sets the home watch: trained defenders at home, and the Defense
## allocation (the standing watch, the rest of it untrained militia).
func home_watch(spec:Array,watch:int)->void:
	MilitaryCampaign._rebuild_home_army_with(formations(spec,true))
	GameState.population_allocations["Defense"]=watch
	MilitaryCampaign._refresh_readiness()


# =============================================================================
# The day, and what the player sees while a battle is fought
# =============================================================================

## One world day as the game runs it: the military day (movement, sieges,
## every battle's phase), then the court's daily war step.
func day()->void:
	var t0:=Time.get_ticks_usec()
	GameState.elapsed_days=float(int(GameState.elapsed_days)+1)
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	MilitaryCampaign._process_military_day()
	var t1:=Time.get_ticks_usec()
	WO.daily(int(GameState.elapsed_days))
	if OS.get_environment("BATTLE_EVAL_PROFILE")=="1": _note("day %.0f ms (+court %.0f)" % [float(t1-t0)/1000.0,float(Time.get_ticks_usec()-t1)/1000.0])


## Every battle being fought now, ours and our generals'.
func live()->Array:
	return View.live_engagements()


## A fingerprint of an engagement: anything viewing must never change.
func _print(e:Dictionary)->int:
	return hash(var_to_str([e.get("round",0),(e.get("rounds",[]) as Array).size(),e.get("battle",{}),int((e.get("attacker",{}) as Dictionary).get("troops",0)),int((e.get("defender",{}) as Dictionary).get("troops",0))]))


## A trace is kept for every battle of ours seen live: how it went, day by
## day, for the checks when it ends.
func _trace(e:Dictionary)->Dictionary:
	var id:=String(e.get("id",""))
	if not traces.has(id):
		var home_side:=String(e.get("home_side","attacker"))
		traces[id]={"id":id,"seed":int(e.get("seed",0)),"home_side":home_side,"began":int(GameState.elapsed_days),"days":[],"observed":0,
			"initial":int(e.get(home_side+"_initial",0)),"quick":MilitaryCampaign._quick_fight(e),"phase_len":int((e.get("battle",{}) as Dictionary).get("phase_len",4)),"force":_force_key(e),
			"before":_force_ledger(e),"skirmish":false}
	return traces[id]


func _force_key(e:Dictionary)->Dictionary:
	return {"kind":String(e.get("home_force_kind","field")),"id":int(e.get("home_force_id",0)),"civ":String(e.get("home_force_civ_id","")),"region":String(e.get("home_force_region_id",""))}


## What the player sees of every battle being fought now, checked against
## the engine: the panel's list and view, the map's marks, and that none of
## it fought anything.
func observe()->void:
	var engagements:=live()
	if engagements.is_empty(): return
	var prints:={}
	for e_variant in engagements:
		var e:Dictionary=e_variant
		prints[String(e.get("id",""))]=_print(e)
		_trace(e)
	var t0:=Time.get_ticks_usec()
	var listed:Array=View.list_now()
	var inputs:Dictionary=overlay.collect() if is_instance_valid(overlay) else {}
	if OS.get_environment("BATTLE_EVAL_PROFILE")=="1": _note("collect %.0f ms" % (float(Time.get_ticks_usec()-t0)/1000.0))
	var marks:Array=inputs.get("battles",[])
	var clashes:Array=inputs.get("engagements",[])
	var views:={}
	for e_variant in engagements:
		var e:Dictionary=e_variant
		var id:=String(e.get("id",""))
		views[id]=Record.view(e,View.words(e,true))
		View.find(id)
	# Viewing never fights.
	for e_variant in engagements:
		var e:Dictionary=e_variant
		var id:=String(e.get("id",""))
		_check(_print(e)==int(prints[id]),"record","viewing the battle %s changed it (the panel or the map fought it)" % id)
	for e_variant in engagements:
		var e:Dictionary=e_variant
		_observe_one(e,listed,marks,clashes,views.get(String(e.get("id","")),{}))


func _observe_one(e:Dictionary,listed:Array,marks:Array,clashes:Array,view:Dictionary)->void:
	var id:=String(e.get("id",""))
	var t:=_trace(e)
	t.observed=int(t.observed)+1
	var home_side:=String(e.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var battle:Dictionary=e.get("battle",{})
	var ours:=int((e.get(home_side,{}) as Dictionary).get("troops",0))
	var theirs:=int((e.get(enemy_side,{}) as Dictionary).get("troops",0))
	var progress:=Blocks.progress_for(battle,home_side) if not battle.is_empty() else 0.0
	var fought:=int(e.get("round",0))>0
	# The panel's list: once, the right sides, numbers, progress and status.
	var mine:=listed.filter(func(item:Dictionary)->bool: return String(item.get("id",""))==id)
	if _check(mine.size()==1,"panel","battle %s is listed %d times in the battle panel's list (should be once)" % [id,mine.size()]):
		var item:Dictionary=mine[0]
		var sides:Dictionary=item.get("sides",{})
		_check(String((sides.get("a",{}) as Dictionary).get("civ_id",""))=="player","panel","battle %s: the panel's side a is not ours" % id)
		_check(int((sides.get("a",{}) as Dictionary).get("troops",-1))==ours,"panel","battle %s: the panel says we have %d, the engine %d" % [id,int((sides.get("a",{}) as Dictionary).get("troops",-1)),ours])
		_check(int((sides.get("b",{}) as Dictionary).get("troops",-1))==theirs,"panel","battle %s: the panel says they have %d, the engine %d" % [id,int((sides.get("b",{}) as Dictionary).get("troops",-1)),theirs])
		_check(absf(float(item.get("progress",0.0))-progress)<0.001,"panel","battle %s: the panel's progress %.2f is not the engine's %.2f" % [id,float(item.get("progress",0.0)),progress])
		var status:=String(item.get("status",""))
		_check(status==("fighting" if fought else "drawn up"),"panel","battle %s: the panel says '%s' after %d exchanges" % [id,status,int(e.get("round",0))])
		t["panel_place"]=String(item.get("place_name",""))
	# The panel's own view of the battle.
	if not view.is_empty():
		var left:Dictionary=((view.get("sides",{}) as Dictionary).get("left",{}) as Dictionary).get("totals",{})
		_check(int(left.get("went_in",-1))==int(e.get(home_side+"_initial",0)),"panel","battle %s: the panel's view says %d of ours went in, the engine %d" % [id,int(left.get("went_in",-1)),int(e.get(home_side+"_initial",0))])
		_check(int(left.get("standing",-1))==ours,"panel","battle %s: the panel's view has %d of ours standing, the engine %d" % [id,int(left.get("standing",-1)),ours])
		_check(absf(float(view.get("progress",0.0))-progress)<0.001,"panel","battle %s: the panel's bar %.2f is not the engine's progress %.2f" % [id,float(view.get("progress",0.0)),progress])
		_check(signf(float(view.get("progress",0.0)))==signf(progress) or absf(progress)<0.001,"panel","battle %s: the panel's bar leans the wrong way" % id)
		var hours:=String(view.get("hours",""))
		var status_words:=String(view.get("status",""))
		_check(status_words==("Fighting, %s so far" % hours if fought else "Drawn up, about to fight"),"panel","battle %s: the panel says '%s' after %d exchanges" % [id,status_words,int(e.get("round",0))])
		# Its plates add up to the engine's men.
		var plates:Dictionary=view.get("phases",[])[-1].get("plates",{}) if not (view.get("phases",[]) as Array).is_empty() else {}
		var standing:=_plates_men(plates.get("left",{}),["front","reserve"])
		if not plates.is_empty(): _check(standing==ours,"panel","battle %s: the panel's blocks hold %d of ours, the engine %d" % [id,standing,ours])
	# The map: one mark for this battle, agreeing with the engine and the panel.
	var mapped:=marks.filter(func(m:Dictionary)->bool: return String(m.get("id",""))==id)
	if _check(mapped.size()==1,"marker","battle %s is marked %d times on the map (should be once)" % [id,mapped.size()]):
		var m:Dictionary=mapped[0]
		var sides:Dictionary=m.get("sides",{})
		_check(bool(m.get("ours",false)),"marker","battle %s: the map does not mark it as ours" % id)
		_check(int((sides.get("a",{}) as Dictionary).get("troops",-1))==ours,"marker","battle %s: the map says we have %d, the engine %d" % [id,int((sides.get("a",{}) as Dictionary).get("troops",-1)),ours])
		_check(int((sides.get("b",{}) as Dictionary).get("troops",-1))==theirs,"marker","battle %s: the map says they have %d, the engine %d" % [id,int((sides.get("b",{}) as Dictionary).get("troops",-1)),theirs])
		_check(absf(float(m.get("progress",0.0))-progress)<0.001,"marker","battle %s: the map's progress %.2f is not the engine's %.2f" % [id,float(m.get("progress",0.0)),progress])
		var status:=String(m.get("status",""))
		_check(status==("fighting" if fought else "drawn up"),"marker","battle %s: the map says '%s' after %d exchanges" % [id,status,int(e.get("round",0))])
		var days:=int(t.get("fought_days",0))
		_check(int(m.get("day",0))==maxi(1,days),"timing","battle %s: the map says day %d after %d days of fighting" % [id,int(m.get("day",0)),days])
		# The same place as the panel: both name the same town, or neither does.
		var panel_town:=_town_in(String(t.get("panel_place","")))
		var map_town:=_town_in(String(m.get("place_name","")))
		_check(panel_town==map_town,"marker","battle %s: the panel places it at '%s', the map at '%s'" % [id,String(t.get("panel_place","")),String(m.get("place_name",""))])
		t["skirmish"]=bool(m.get("skirmish",false))
		t["map_pos"]=m.get("pos",Vector2.INF)
		# The battle panel itself, opened once a day has been fought: its day
		# line says the day the map letters.
		if int(t.get("fought_days",0))>=1 and not bool(t.get("panel_opened",false)) and is_instance_valid(suite):
			t["panel_opened"]=true
			var panel:Control=View.open(id,suite)
			if _check(panel!=null,"panel","battle %s cannot be opened in the battle panel" % id):
				var words:=String(panel.call("_battle_day_words"))
				var said:=words.trim_prefix("Day ").trim_suffix(" of the battle")
				_check(said==_number_word(int(m.get("day",0))) or said==str(int(m.get("day",0))),"timing","battle %s: the panel says '%s', the map day %d" % [id,words,int(m.get("day",0))])
				_check_live_screen(panel,e,m,ours,progress)
				View.close_open(suite)
	# Its clash on the war chart (the worm and arrows): once.
	var seed:=int(e.get("seed",0))
	var mine_clashes:=clashes.filter(func(c:Dictionary)->bool: return int(c.get("seed",-1))==seed and not bool(c.get("finished",false)))
	_check(mine_clashes.size()==1,"marker","battle %s has %d live clashes on the war chart (should be one)" % [id,mine_clashes.size()])
	if mine_clashes.size()==1:
		var c:Dictionary=mine_clashes[0]
		_check(int(c.get("our_troops",-1))==ours and int(c.get("their_troops",-1))==theirs,"marker","battle %s: the war chart's clash has %d against %d, the engine %d against %d" % [id,int(c.get("our_troops",-1)),int(c.get("their_troops",-1)),ours,theirs])
		var at:Vector2=t.get("map_pos",Vector2.INF)
		if at.is_finite(): _check((c.pos as Vector2).distance_to(at)<=3.0,"marker","battle %s: its clash is drawn %.1f km from its battle mark" % [id,(c.pos as Vector2).distance_to(at)])
	(t.days as Array).append({"day":int(GameState.elapsed_days),"exchange":int(battle.get("exchange",0)),"round":int(e.get("round",0)),"ours":ours,"theirs":theirs,"progress":progress})


func _number_word(n:int)->String:
	var words:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return words[n] if n>=0 and n<words.size() else str(n)


## The town a place name names ("Near Tsaren" and "Tsaren" name Tsaren).
func _town_in(place:String)->String:
	var p:=place.strip_edges().trim_prefix("Near ").trim_prefix("near ").trim_prefix("at ").trim_prefix("before ")
	if p=="" or p.to_lower() in ["in the field","at home","in the open country"] or p.contains(" km ") or p.ends_with(" km") or p.begins_with("about "): return ""
	for word in ["north","south","east","west"]:
		if p.to_lower().ends_with(word) and (p.contains("km") or p.contains("a day") or p.contains("hour")): return ""
	return p


func _plates_men(side:Variant,states:Array)->int:
	if not side is Dictionary: return 0
	var n:=0
	for row in ["front","rear"]:
		for plate in (side as Dictionary).get(row,[]):
			if String((plate as Dictionary).get("state",""))in states: n+=int((plate as Dictionary).get("men",0))
	return n


## Days run until every battle of ours is over (or `max_days`), observing
## each day, and checking the timing of each day's fighting.
func fight_out(max_days:int=30,timed:bool=false)->int:
	var days:=0
	observe()
	while not live().is_empty() and days<max_days:
		_fight_one_day(timed and days==0)
		days+=1
	_check(live().is_empty(),"timing","battles still being fought after %d days" % days)
	return days


## A few days of fighting (the battles may go on after).
func fight_days(n:int)->void:
	observe()
	for i in n:
		if live().is_empty(): return
		_fight_one_day(false)


func _fight_one_day(timed:bool)->void:
	var before:={}
	for e in live(): before[String((e as Dictionary).get("id",""))]={"exchange":int(((e as Dictionary).get("battle",{}) as Dictionary).get("exchange",0)),"quick":MilitaryCampaign._quick_fight(e),"phase_len":int(((e as Dictionary).get("battle",{}) as Dictionary).get("phase_len",4))}
	var began:=Time.get_ticks_usec()
	day()
	if timed:
		var spent:=float(Time.get_ticks_usec()-began)/1000.0
		_note("a day of %d battles: %.0f ms" % [before.size(),spent])
		_check(spent<=DAY_BUDGET_MS,"speed","a day of %d battles took %.0f ms (budget %.0f)" % [before.size(),spent,DAY_BUDGET_MS])
	for id in before:
		var t:Dictionary=traces.get(id,{})
		if t.is_empty(): continue
		t["fought_days"]=int(t.get("fought_days",0))+1
		var now:=_live_by_id(String(id))
		var info:Dictionary=before[id]
		if now.is_empty(): continue
		var moved:=int((now.get("battle",{}) as Dictionary).get("exchange",0))-int(info.exchange)
		if bool(info.quick): _check(false,"timing","battle %s is a lopsided or tiny fight but was not decided the day it was fought (%d exchanges that day)" % [id,moved])
		else: _check(moved==int(info.phase_len),"timing","battle %s: a day's fighting was %d exchanges, not one phase (%d)" % [id,moved,int(info.phase_len)])
	observe()


func _live_by_id(id:String)->Dictionary:
	for e in live():
		if String((e as Dictionary).get("id",""))==id: return e
	return {}


# =============================================================================
# The ledgers
# =============================================================================

## What our side has before a battle: the force that fights it, and what the
## people hold (captives, bondservants, stores).
func _force_ledger(e:Dictionary)->Dictionary:
	return _ledger_for(_force_key(e))


func _ledger_for(key:Dictionary)->Dictionary:
	var force:=_force_now(key)
	return {"troops":int(force.get("troops",0)),"dead":int(force.get("dead",0)),"wounded":int(force.get("wounded_pool",0)),"scattered":int(force.get("scattered_pool",0)),"captured":int(force.get("captured_pool",0)),
		"prisoners":int(MilitaryCampaign.foreign_prisoners),"bound":float(GameState.resource_stockpiles.get("Forced Labor",0.0)),"food":float(GameState.resource_stockpiles.get("Food",0.0)),
		"carts":float(GameState.resource_stockpiles.get("Transport Carts",0.0)),"gear":_gear_total(),"population":int(GameState.population_total),"generals":MilitaryCampaign.held_generals.size()}


func _force_now(key:Dictionary)->Dictionary:
	match String(key.kind):
		"field_army": return army(int(key.id))
		"occupation": return MilitaryCampaign.occupation_force_for_region(String(key.civ),String(key.region))
	return MilitaryCampaign.home_army


func _inventory_total()->int:
	var n:=0
	for item in MilitaryCampaign.military_inventory: n+=int(MilitaryCampaign.military_inventory[item])
	return n

## The stores and what has left them for bands away and their drafts (gear
## follows the supply line, military_campaign.gear_sent_out).
func _gear_total()->int:
	return _inventory_total()+int(MilitaryCampaign.gear_sent_out)


func _sum_rounds(record:Dictionary,side:String)->Dictionary:
	var out:={"losses":0,"killed":0,"wounded":0,"scattered":0,"captured":0}
	for r_variant in record.get("rounds",[]):
		var r:Dictionary=r_variant
		out.losses+=int(r.get(side+"_losses",0))
		var c:Dictionary=r.get(side+"_casualties",{})
		for k in ["killed","wounded","scattered","captured"]: out[k]+=int(c.get(k,0))
	return out


# =============================================================================
# Checking a finished battle
# =============================================================================

## The finished battle's record in the history (by engagement id, else seed).
func record_of(id:String,seed:int=-1)->Dictionary:
	for r in MilitaryCampaign.battle_history:
		var rec:Dictionary=r
		if id!="" and String(rec.get("id",""))==id: return rec
	for r in MilitaryCampaign.battle_history:
		var rec:Dictionary=r
		if seed>=0 and int(rec.get("seed",-1))==seed: return rec
	return {}


## Everything the player can read or count about a finished battle.
func check_finished(record:Dictionary,trace:Dictionary={},opts:Dictionary={})->Dictionary:
	if record.is_empty():
		_fail("report","a battle ended with no record in the history")
		return {}
	var id:=String(record.get("id",""))
	var seed:=int(record.get("seed",0))
	var home_side:=String(record.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var ours:Dictionary=record.get(home_side,{})
	var theirs:Dictionary=record.get(enemy_side,{})
	var term:Dictionary=record.get("termination",{})
	var account:=Account.build(record,Account.gather(record))
	var kind:=String(account.kind)
	var rounds:Array=record.get("rounds",[])
	var label:="battle %s" % (id if id!="" else str(seed))
	# --- The record adds up in itself.
	for side in ["attacker","defender"]:
		var sum:=_sum_rounds(record,side)
		var force:Dictionary=record.get(side,{})
		_check(int(force.get("initial_troops",0))-int(force.get("remaining_troops",0))==int(sum.losses),"ledger","%s: the %s went in %d and left %d, but the exchanges lost %d" % [label,side,int(force.get("initial_troops",0)),int(force.get("remaining_troops",0)),int(sum.losses)])
		for r_variant in rounds:
			var r:Dictionary=r_variant
			var c:Dictionary=r.get(side+"_casualties",{})
			var split:=int(c.get("killed",0))+int(c.get("wounded",0))+int(c.get("scattered",0))+int(c.get("captured",0))
			if split!=int(r.get(side+"_losses",0)):
				_fail("ledger","%s: in exchange %d the %s lost %d but killed+wounded+fled+taken is %d" % [label,int(r.get("round",0)),side,int(r.get(side+"_losses",0)),split]); break
	# --- Our force: before = after + what the battle cost.
	if not trace.is_empty():
		var before:Dictionary=trace.get("before",{})
		var after:=_force_now(trace.get("force",{}))
		var lost:=_sum_rounds(record,home_side)
		var taken_at_end:=int(term.get("prisoners",0)) if kind in ["lost","withdrew"] else 0
		var detached:=int(record.get("detached",0))
		var expected:=int(before.get("troops",0))-int(lost.losses)-mini(taken_at_end,int(ours.get("remaining_troops",0)))-detached
		var now_troops:=int(after.get("troops",0)) if not after.is_empty() else 0
		if not bool(opts.get("force_moves",false)):
			_check(now_troops==expected,"ledger","%s: our force had %d, lost %d in the fight, %d taken at the end, %d left to hold a town; it should have %d but has %d" % [label,int(before.get("troops",0)),int(lost.losses),taken_at_end,detached,expected,now_troops])
			_check(int(after.get("dead",0))-int(before.get("dead",0))==int(lost.killed),"ledger","%s: %d of ours were killed but the force's dead grew by %d" % [label,int(lost.killed),int(after.get("dead",0))-int(before.get("dead",0))])
		# The band is led after the fight by the man who led it, or by the
		# one who took over when he fell or was taken; never by anyone else.
		if not after.is_empty() and String((trace.get("force",{}) as Dictionary).get("kind",""))=="field_army":
			var led:=String((ours.get("commander",{}) as Dictionary).get("name",""))
			var succession:Dictionary=record.get("commander_succession",{}) if record.get("commander_succession") is Dictionary else {}
			var should:=String(succession.get("now",led)) if not succession.is_empty() else led
			var leads:=String((after.get("commander",{}) as Dictionary).get("name",""))
			_check(leads==should,"ledger","%s: %s led the band into the fight%s, but %s leads it now" % [label,led,(" and %s took over" % should) if should!=led else "",leads])
		# Report "present" is the force as it stands.
		if not after.is_empty() and not bool(opts.get("force_moves",false)) and String((trace.get("force",{}) as Dictionary).get("kind",""))=="field_army":
			_check(int((account.ours as Dictionary).present)==now_troops,"report","%s: the report says %d are still with the band, the army has %d" % [label,int((account.ours as Dictionary).present),now_troops])
		# Captives: what we took, and where the general put them.
		var their_taken:=int(_sum_rounds(record,enemy_side).captured)+(int(term.get("prisoners",0)) if kind in ["won","taken","uncontested"] else 0)
		_check(int((account.theirs as Dictionary).taken)==their_taken,"report","%s: the report says we took %d captive, the battle %d" % [label,int((account.theirs as Dictionary).taken),their_taken])
		var settled:Dictionary=record.get("aftermath_settled",{}) if record.get("aftermath_settled") is Dictionary else {}
		var held:=int(MilitaryCampaign.foreign_prisoners)-int(before.get("prisoners",0))
		var bound:=roundi(float(GameState.resource_stockpiles.get("Forced Labor",0.0))-float(before.get("bound",0.0)))
		var alone:=resolved.size()<=1
		if their_taken>0 and alone and not bool(opts.get("captives_move",false)):
			var policy:=String(settled.get("prisoner_policy","hold")) if not settled.is_empty() else "hold"
			var placed:=held+bound
			var expected_placed:=their_taken if policy in ["hold","enslave"] else 0
			if policy=="hold": expected_placed=their_taken
			_check(placed==expected_placed,"ledger","%s: we took %d captive and the general's word was '%s', but %d are held and %d bound" % [label,their_taken,policy,held,bound])
			if not settled.is_empty():
				_check(int(settled.get("prisoners",0))==their_taken,"ledger","%s: the general settled %d captives but %d were taken" % [label,int(settled.get("prisoners",0)),their_taken])
		# Spoils into the stores, as the settlement says.
		if alone and not settled.is_empty() and bool(settled.get("has_spoils",false)) and String(settled.get("spoils_policy",""))=="army stores" and not bool(opts.get("stores_move",false)):
			var taken:Dictionary=settled.get("spoils_taken",{})
			var carts:=roundi(float(GameState.resource_stockpiles.get("Transport Carts",0.0))-float(before.get("carts",0.0)))
			_check(carts==int(taken.get("carts",0)),"ledger","%s: the spoils had %d carts, the stores gained %d" % [label,int(taken.get("carts",0)),carts])
			var weapons:=0
			for w in (taken.get("weapons",{}) as Dictionary): weapons+=int(taken.weapons[w])
			_check(_gear_total()-int(before.get("gear",0))>=weapons,"ledger","%s: the spoils had %d weapons, the stores gained %d (with what went out to the bands)" % [label,weapons,_gear_total()-int(before.get("gear",0))])
	# --- The report: once, from the war leader, with the right numbers.
	var cards:=resolved.filter(func(r:Dictionary)->bool: return int(r.seed)==seed)
	_check(cards.size()==1,"report","%s: its report was sent %d times (should be once)" % [label,cards.size()])
	var matters:=GameState.council_inbox.filter(func(m:Dictionary)->bool: return int(m.get("battle_seed",-1))==seed)
	if _check(matters.size()==1,"report","%s: %d battle reports in the council (should be one)" % [label,matters.size()]):
		var matter:Dictionary=matters[0]
		_check(String(matter.get("advisor",""))=="WAR LEADER","report","%s: the report comes from '%s', not the war leader" % [label,String(matter.get("advisor",""))])
		var text:=String(matter.get("text",""))
		var line:=Account.ledger_line(account.ours)
		var went:="%s went in" % Account._cap(Account.exact(int((account.ours as Dictionary).in_fight)))
		_check(text.contains(went),"report","%s: the report does not say '%s' (it says: %s)" % [label,went,text.substr(0,160)])
		_check(int((account.ours as Dictionary).in_fight)==int(ours.get("initial_troops",0)),"report","%s: the report's %d went in is not the %d who fought" % [label,int((account.ours as Dictionary).in_fight),int(ours.get("initial_troops",0))])
		var lost:=_sum_rounds(record,home_side)
		_check(int((account.ours as Dictionary).killed)==int(lost.killed),"report","%s: the report's %d killed is not the battle's %d" % [label,int((account.ours as Dictionary).killed),int(lost.killed)])
		if int(lost.killed)>0: _check(text.contains("%s killed" % Account.exact(int(lost.killed))),"report","%s: the report does not say %s killed" % [label,Account.exact(int(lost.killed))])
		_check(not line.contains("about"),"report","%s: the report guesses at our own numbers: %s" % [label,line])
		_check(not text.contains("FIELD STAFF") and not text.contains("FIELD HOST") and not text.contains("_"),"report","%s: the report shows internal names: %s" % [label,text.substr(0,160)])
		_check(line!="" and text.contains(line),"report","%s: the report's own ledger line is not in it (%s)" % [label,line])
	var court:=_court_reports(seed)
	_check(court.size()<=1,"report","%s: the war leader came to court %d times about it (at most once)" % [label,court.size()])
	if bool(opts.get("court",false)): _check(court.size()==1,"report","%s: the war leader never came to court to report it" % label)
	# --- The Chronicle: one entry.
	var entries:=(GameState.chronicle.get("entries",[]) as Array).filter(func(entry:Dictionary)->bool: return String(entry.get("key","")).begins_with("battle:%d:" % seed))
	if _check(entries.size()==1,"report","%s: %d Chronicle entries (should be one)" % [label,entries.size()]):
		var entry:Dictionary=entries[0]
		var headline:=String(account.headline).trim_suffix(".")
		_check(String(entry.get("title",""))==headline.substr(0,70) or bool(entry.get("folded",false)) or entry.has("same_as"),"report","%s: the Chronicle says '%s', the report '%s'" % [label,String(entry.get("title","")),headline])
	# --- The record, stepped through, says what the report says.
	var before_record:=var_to_str(record)
	var view:=Record.view(record,View.words(record,false))
	var again:=Record.view(record,View.words(record,false))
	_check(var_to_str(record)==before_record,"record","%s: reading the record changed it" % label)
	_check(var_to_str(view)==var_to_str(again),"record","%s: reading the record twice gave two different battles" % label)
	var left:Dictionary=((view.get("sides",{}) as Dictionary).get("left",{}) as Dictionary).get("totals",{})
	var right:Dictionary=((view.get("sides",{}) as Dictionary).get("right",{}) as Dictionary).get("totals",{})
	var a:Dictionary=account.ours
	_check(int(left.get("went_in",-1))==int(a.in_fight),"record","%s: the battle view says %d went in, the report %d" % [label,int(left.get("went_in",-1)),int(a.in_fight)])
	for pair in [["killed","killed"],["wounded","wounded"],["fled","fled"],["captured","captured"]]:
		_check(int(left.get(pair[0],-1))==int(a.get(pair[1],0)),"record","%s: the battle view says %d of ours %s, the report %d" % [label,int(left.get(pair[0],-1)),String(pair[0]),int(a.get(pair[1],0))])
	_check(int(right.get("captured",-1))==int((account.theirs as Dictionary).taken),"record","%s: the battle view says %d of theirs taken, the report %d" % [label,int(right.get("captured",-1)),int((account.theirs as Dictionary).taken)])
	_check_screen(id,record,account,label)
	var phases:Array=view.get("phases",[])
	if not phases.is_empty() and not rounds.is_empty():
		# The phases cover the fight from the first exchange to the last.
		var first:=int((phases[0] as Dictionary).get("from",0)); var last:=int((phases[-1] as Dictionary).get("to",0))
		_check(first==1 and last==rounds.size(),"record","%s: the phases run from exchange %d to %d, the battle had %d" % [label,first,last,rounds.size()])
		for i in range(1,phases.size()):
			if int((phases[i] as Dictionary).from)!=int((phases[i-1] as Dictionary).to)+1: _fail("record","%s: phase %d does not follow phase %d" % [label,i+1,i]); break
		# Each side's losses by phase add up to the battle's.
		for side_key in ["left","right"]:
			var role:=home_side if side_key=="left" else enemy_side
			var sum:=_sum_rounds(record,role)
			var by_phase:=0
			for p in phases: by_phase+=int(((p as Dictionary).losses as Dictionary)[side_key].total)
			_check(by_phase==int(sum.losses),"record","%s: the phases show %d of the %s side lost, the exchanges %d" % [label,by_phase,side_key,int(sum.losses)])
		# The last phase shows the field as it was left.
		var plates:Dictionary=(phases[-1] as Dictionary).get("plates",{})
		for side_key in ["left","right"]:
			var role:=home_side if side_key=="left" else enemy_side
			var men:=_plates_men(plates.get(side_key,{}),["front","reserve","fled","broken"])
			var remaining:=int((record.get(role,{}) as Dictionary).get("remaining_troops",0))
			_check(men==remaining,"record","%s: the last phase shows %d of the %s side left, the battle %d" % [label,men,side_key,remaining])
	var p:=float(view.get("progress",0.0))
	if kind in ["won","taken"]: _check(p>0.0,"record","%s: we won but the bar leans against us (%.2f)" % [label,p])
	elif kind in ["lost","withdrew"]: _check(p<0.0,"record","%s: we lost but the bar leans our way (%.2f)" % [label,p])
	_check(String(view.get("status",""))==("Over after %s of fighting" % String(view.get("hours","")) if not rounds.is_empty() else "Over at once"),"record","%s: the view says '%s'" % [label,String(view.get("status",""))])
	_check(String(account.duration)==Account.duration_words(rounds.size()),"record","%s: the report's %s is not %d exchanges" % [label,String(account.duration),rounds.size()])
	# --- The aftermath: settled, nothing waits, nothing blocked.
	_check(MilitaryCampaign.pending_aftermath.is_empty(),"aftermath","%s: its aftermath still waits on the ruler" % label)
	_check(not Account.text(account).contains("wait on your word first"),"aftermath","%s: the report still says captives wait on the ruler" % label)
	var settled2:Dictionary=record.get("aftermath_settled",{}) if record.get("aftermath_settled") is Dictionary else {}
	if not settled2.is_empty(): _check(String(account.now).contains(String(settled2.get("line","~"))),"aftermath","%s: the report does not say what the general did with the captives" % label)
	# --- Historical ranges.
	_check_ranges(record,kind,label)
	if OS.get_environment("BATTLE_EVAL_REPORTS")=="1": _note("REPORT %s" % Account.text(account))
	var ours_lost:=_sum_rounds(record,home_side); var theirs_lost:=_sum_rounds(record,enemy_side)
	_note("%s %s %d v %d, %d exch (%d days seen), ground %s, ours -%d (k%d w%d f%d c%d), theirs -%d (k%d w%d f%d c%d), %s, taken %d" % [label,kind,int(ours.get("initial_troops",0)),int(theirs.get("initial_troops",0)),rounds.size(),int(trace.get("fought_days",0)),
		String((view.get("ground",{}) as Dictionary).get("kind","")),int(ours_lost.losses),int(ours_lost.killed),int(ours_lost.wounded),int(ours_lost.scattered),int(ours_lost.captured),
		int(theirs_lost.losses),int(theirs_lost.killed),int(theirs_lost.wounded),int(theirs_lost.scattered),int(theirs_lost.captured),String(term.get("type","")),int(term.get("prisoners",0))])
	return {"record":record,"account":account,"view":view,"kind":kind}


## The war leader's court matters about a battle (audience_hall.gd keeps
## court business as matters, each with its audience).
func _court_reports(seed:int)->Array:
	var out:Array=[]
	for m in _war_matters():
		if int((m.war as Dictionary).get("battle_seed",-1))==seed: out.append(m)
	return out


## Every war matter at court: [{matter, audience, war, text}].
func _war_matters()->Array:
	var out:Array=[]
	for m in Hall.state().get("matters",[]):
		if not m is Dictionary: continue
		var audience:Dictionary=(m as Dictionary).get("audience",{}) if (m as Dictionary).get("audience") is Dictionary else {}
		var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
		var war:Dictionary=situation.get("war",{}) if situation.get("war") is Dictionary else {}
		if war.is_empty(): continue
		out.append({"matter":m,"audience":audience,"war":war,"text":String((audience.get("petition",{}) as Dictionary).get("summary",""))})
	return out


## The battle screen on a battle being fought, against the engine and the
## map: the field draws the engine's blocks as they stand (each block's men
## and whether it is in the line, waiting, broken or fled), our strength bar
## counts the engine's men, the balance is the engine's progress, and the
## battle's mark is the one the map crosses over it.
func _check_live_screen(panel:Control,e:Dictionary,m:Dictionary,ours:int,progress:float)->void:
	var id:=String(e.get("id",""))
	if bool((panel.get("view") as Dictionary).get("skirmish",false)): return
	var field:Control=panel.find_child("Field",true,false)
	if not _check(field!=null,"panel","battle %s: the battle screen has no field" % id): return
	var battle:Dictionary=e.get("battle",{})
	var home_side:=String(e.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	for role in [home_side,enemy_side]:
		var key:="left" if role==home_side else "right"
		var defs:Array=((battle.get("sides",{}) as Dictionary).get(role,{}) as Dictionary).get("blocks",[])
		var rows:Array=[]
		for b in ((battle.get("live",{}) as Dictionary).get(role,[]) as Array): rows.append([int(b.men),0,int(Blocks.STATE_CODE.get(String(b.st),1)),int(b.slot)])
		_check_field_blocks(field,defs,rows,key,"battle %s now" % id)
	var strip:Control=panel.find_child("SideLeft",true,false).find_child("Strength",true,false)
	var standing:=int((strip.get("totals") as Dictionary).get("standing",-1))
	_check(standing==ours,"panel","battle %s: the screen's strength bar has %d of ours standing, the engine %d" % [id,standing,ours])
	var balance:Control=panel.find_child("Progress",true,false)
	_check(absf(float(balance.get("value"))-progress)<0.001,"panel","battle %s: the screen's balance %.2f is not the engine's progress %.2f" % [id,float(balance.get("value")),progress])
	var year:=BattleMarks.battle_year(m)
	if year>=0.0:
		var mark:Control=panel.find_child("EraMark",true,false)
		_check(int(mark.get("era"))==BattleMarks.weapons_era(year),"marker","battle %s: the battle screen crosses era %d weapons, the map era %d" % [id,int(mark.get("era")),BattleMarks.weapons_era(year)])


## The field's blocks for one side against the engine's blocks at one moment
## (battle_blocks snapshot rows [men, heart, state code, slot]): every block
## drawn once, with its men and its state.
func _check_field_blocks(field:Control,defs:Array,rows:Array,key:String,label:String)->void:
	var drawn:Array=((field.get("layout") as Dictionary).get("blocks",[]) as Array).filter(func(b:Dictionary)->bool: return String(b.key)==key)
	var expected:=mini(defs.size(),rows.size())
	if not _check(drawn.size()==expected,"panel","%s: the field draws %d %s blocks, the engine has %d" % [label,drawn.size(),key,expected]): return
	var by_id:={}
	for b in drawn: by_id[String(b.id)]=b
	for i in expected:
		var bid:=String((defs[i] as Dictionary).get("id",""))
		var block:Dictionary=by_id.get(bid,{})
		if not _check(not block.is_empty(),"panel","%s: block %s is not on the field" % [label,bid]): return
		var row:Array=rows[i]
		var state:=String(Blocks.CODE_STATE[clampi(int(row[2]),0,3)])
		if not _check(int(block.men)==maxi(0,int(row[0])) and String(block.state)==state,"panel","%s: block %s is drawn with %d men, %s; the engine has %d, %s" % [label,bid,int(block.men),String(block.state),int(row[0]),state]): return


## The battle screen opened on the finished battle and played back day by
## day against the engine. Each day the field draws the engine's blocks as
## its record holds them; the strength bars count the men those blocks hold;
## the balance is the engine's progress; the track has a stop for every day;
## every rout arrow is a block that broke that day and every reserve arrow a
## slot the record says a reserve went into. At the end the strips say what
## the report says, and the captives we took are ours to count, so the
## screen says their number exactly.
func _check_screen(id:String,record:Dictionary,account:Dictionary,label:String)->void:
	if id=="" or not is_instance_valid(suite): return
	var panel:Control=View.open(id,suite)
	if not _check(panel!=null,"panel","%s cannot be opened in the battle panel once it is over" % label): return
	var taken:=int((account.theirs as Dictionary).taken)
	var view:Dictionary=panel.get("view")
	if bool(view.get("skirmish",false)):
		var side:Node=panel.find_child("SideRight",true,false)
		var shown:=""
		var lost:Label=side.find_child("Lost",true,false) as Label if side!=null else null
		if lost!=null:
			for part in lost.text.trim_suffix(".").split(", "):
				if part.ends_with(" taken"): shown=part.trim_suffix(" taken")
		if taken>0: _check(shown==EraWords.grouped(taken),"panel","%s: the battle card says '%s' of theirs taken, the report %d" % [label,shown,taken])
		View.close_open(suite)
		return
	var home_side:=String(record.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var battle:Dictionary=record.get("battle",{}) if record.get("battle") is Dictionary else {}
	var phases:Array=battle.get("phases",[])
	var count:=(view.get("phases",[]) as Array).size()
	var field:Control=panel.find_child("Field",true,false)
	var days:Control=panel.find_child("Days",true,false)
	if not _check(field!=null and days!=null,"panel","%s: the battle screen has no field or no days" % label):
		View.close_open(suite)
		return
	if battle.has("sides"):
		_check(count==phases.size(),"panel","%s: the screen has %d days, the engine fought %d phases" % [label,count,phases.size()])
		_check((days.get("labels") as Array).size()==phases.size()+1,"panel","%s: the track has %d stops for %d days" % [label,(days.get("labels") as Array).size(),phases.size()])
	for k in count+1:
		panel.call("_select",k,false)
		if not battle.has("sides"): continue
		var snap:Dictionary={}
		if k==0: snap=battle.get("start",{})
		elif k-1<phases.size(): snap=(phases[k-1] as Dictionary).get("snap",{})
		if snap.is_empty(): continue
		for role in [home_side,enemy_side]:
			var key:="left" if role==home_side else "right"
			var defs:Array=((battle.sides as Dictionary).get(role,{}) as Dictionary).get("blocks",[])
			var rows:Array=snap.get(role,[])
			_check_field_blocks(field,defs,rows,key,"%s day %d" % [label,k])
			# The strength bar counts the men the field's blocks hold (in the
			# line or waiting); at the end, the battle's own count.
			var on_field:=0
			for row in rows:
				if int((row as Array)[2])<=1: on_field+=maxi(0,int((row as Array)[0]))
			var strip:Control=panel.find_child("Side"+key.capitalize(),true,false).find_child("Strength",true,false)
			var standing:=int((strip.get("totals") as Dictionary).get("standing",-1))
			if k<count: _check(standing==on_field,"panel","%s day %d: the %s strength bar has %d standing, its blocks hold %d" % [label,k,key,standing,on_field])
		if k>0 and k-1<phases.size():
			var p:=float((phases[k-1] as Dictionary).get("progress",0.0))*(1.0 if home_side=="attacker" else -1.0)
			var balance:Control=panel.find_child("Progress",true,false)
			_check(absf(float(balance.get("value"))-p)<0.001,"panel","%s day %d: the screen's balance %.2f is not the engine's %.2f" % [label,k,float(balance.get("value")),p])
			_check_arrows(field,battle,k,home_side,label)
	# At the end: what the report says.
	var a:Dictionary=account.ours
	var left:Node=panel.find_child("SideLeft",true,false)
	for pair in [["Killed","killed"],["Wounded","wounded"],["Fled","fled"],["Taken","captured"]]:
		var value:Label=left.find_child(String(pair[0]),true,false).find_child("Value",true,false) as Label
		var n:=int(a.get(String(pair[1]),0))
		_check(value.text==("none" if n<=0 else EraWords.grouped(n)),"panel","%s: the screen says '%s' of ours %s, the report %d" % [label,value.text,String(pair[1]),n])
	var item:Node=panel.find_child("SideRight",true,false).find_child("Taken",true,false)
	var shown_taken:=(item.find_child("Value",true,false) as Label).text if item!=null else ""
	_check(shown_taken==("none" if taken<=0 else EraWords.grouped(taken)),"panel","%s: the battle screen says '%s' of theirs taken, the report %d" % [label,shown_taken,taken])
	View.close_open(suite)


## The day's arrows against the engine's record of it: one rout arrow for
## each block that broke that day (six a side at most), and no more reserve
## arrows than the slots the record says reserves went into.
func _check_arrows(field:Control,battle:Dictionary,k:int,home_side:String,label:String)->void:
	var phases:Array=battle.get("phases",[])
	var now:Dictionary=(phases[k-1] as Dictionary).get("snap",{})
	var then:Dictionary=battle.get("start",{}) if k==1 else (phases[k-2] as Dictionary).get("snap",{})
	var slots:={"left":0,"right":0}
	for event in ((phases[k-1] as Dictionary).get("events",[]) as Array):
		if String((event as Dictionary).get("k",""))=="reserve_in":
			var side_key:="left" if String((event as Dictionary).get("side",""))==home_side else "right"
			slots[side_key]=int(slots[side_key])+((event as Dictionary).get("slots",[]) as Array).size()
	var broke:={"left":0,"right":0}
	for role in ["attacker","defender"]:
		var key:="left" if role==home_side else "right"
		var a:Array=then.get(role,[]); var b:Array=now.get(role,[])
		for i in mini(a.size(),b.size()):
			if int((b[i] as Array)[2])==2 and int((a[i] as Array)[2])<=1: broke[key]=int(broke[key])+1
	var routs:={"left":0,"right":0}
	var reserves:={"left":0,"right":0}
	for arrow in ((field.get("layout") as Dictionary).get("arrows",[]) as Array):
		var arrow_key:=String((arrow as Dictionary).key)
		match String((arrow as Dictionary).kind):
			"rout": routs[arrow_key]=int(routs[arrow_key])+1
			"reserve": reserves[arrow_key]=int(reserves[arrow_key])+1
	for key in ["left","right"]:
		_check(int(routs[key])==mini(6,int(broke[key])),"panel","%s day %d: %d %s rout arrows for %d blocks that broke" % [label,k,int(routs[key]),key,int(broke[key])])
		_check(int(reserves[key])<=int(slots[key]),"panel","%s day %d: %d %s reserve arrows, the record has %d going in" % [label,k,int(reserves[key]),key,int(slots[key])])


func _check_ranges(record:Dictionary,kind:String,label:String)->void:
	var home_side:=String(record.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var term:Dictionary=record.get("termination",{})
	var overrun:=String(term.get("type",""))=="overrun"
	var rounds:Array=record.get("rounds",[])
	for role in ["attacker","defender"]:
		var force:Dictionary=record.get(role,{})
		var went:=maxi(1,int(force.get("initial_troops",0)))
		var sum:=_sum_rounds(record,role)
		var won:bool=(String(role)==home_side and kind in ["won","taken"]) or (String(role)==enemy_side and kind in ["lost","withdrew"])
		var loss:=float(sum.losses)/float(went)
		if overrun and won:
			_check(float(int(sum.killed)+int(sum.wounded))/float(went)<=OVERRUN_BIG_LOSS_MAX+2.0/float(went),"range","%s: the side that overran lost %d of %d" % [label,int(sum.killed)+int(sum.wounded),went])
		elif won:
			_check(loss<=WINNER_LOSS_MAX,"range","%s: the winners lost %d of %d (%.0f%%)" % [label,int(sum.losses),went,loss*100.0])
			_check(float(sum.killed)/float(went)<=WINNER_KILLED_MAX+1.0/float(went),"range","%s: the winners had %d of %d killed" % [label,int(sum.killed),went])
		elif not overrun:
			_check(float(sum.killed)/float(went)<=LOSER_KILLED_MAX,"range","%s: the beaten side had %d of %d killed" % [label,int(sum.killed),went])
		if int(sum.killed)+int(sum.wounded)>=10:
			_check(float(sum.killed)/float(int(sum.killed)+int(sum.wounded))<=(KILLED_SHARE_MAX if won else ROUTED_KILLED_SHARE_MAX),"range","%s: %d killed against %d wounded on the %s side" % [label,int(sum.killed),int(sum.wounded),role])
	var a_in:=int((record.get("attacker",{}) as Dictionary).get("initial_troops",0))
	var d_in:=int((record.get("defender",{}) as Dictionary).get("initial_troops",0))
	var biggest:=maxi(a_in,d_in)
	var smallest:=mini(a_in,d_in)
	var hours:=float(rounds.size())*0.5
	_check(hours<=(HOURS_SMALL if biggest<=SMALL_SIDE else HOURS_ANY),"range","%s: %d against %d fought for %.1f hours" % [label,a_in,d_in,hours])
	var age:=clampi(int((record.get("battle",{}) as Dictionary).get("era",0)),0,MIN_HOURS_BY_AGE.size()-1)
	if not overrun and smallest>=LARGE_SIDE and float(smallest)>=float(biggest)*COMPARABLE:
		_check(hours>=float(MIN_HOURS_BY_AGE[age]),"range","%s: %d against %d in the %s age were decided in %.1f hours (at least %.1f)" % [label,a_in,d_in,["first","bronze","classical","gunpowder","rifle","armour"][age],hours,float(MIN_HOURS_BY_AGE[age])])
	if not overrun and age>=4 and kind in ["won","taken","lost","withdrew"] and hours>0.0:
		var winner:=home_side if kind in ["won","taken"] else enemy_side
		var went:=maxi(1,int((record.get(winner,{}) as Dictionary).get("initial_troops",0)))
		var lost:=_sum_rounds(record,winner)
		var rate:=float(int(lost.killed)+int(lost.wounded))/float(went)/hours
		_check(rate<=WINNER_LOSS_PER_HOUR_LATE,"range","%s: the winners lost %.1f%% of their strength an hour of fighting" % [label,rate*100.0])


## Checks every battle of ours that ended in this scenario (by trace).
func check_all(opts:Dictionary={})->Array:
	var out:Array=[]
	for id in traces:
		var t:Dictionary=traces[id]
		var rec:=record_of(String(id),int(t.seed))
		out.append(check_finished(rec,t,opts))
	return out


# =============================================================================
# The map: fronts and marks
# =============================================================================

## Whether the war chart draws a front, a face-off or a worm for the tiny
## party of this battle (it must not).
func check_no_front(label:String)->void:
	if not is_instance_valid(overlay): return
	var inputs:Dictionary=overlay.collect()
	var built:Dictionary=OverlayScript.compose(inputs)
	for clash in built.get("clashes",[]):
		_check(bool((clash as Dictionary).get("skirmish",false)),"front","%s: a tiny party's clash is drawn as a battle line" % label)
	_check((built.get("fronts",[]) as Array).is_empty(),"front","%s: the chart draws a front for a tiny party" % label)
	_check((built.get("faceoffs",[]) as Array).is_empty(),"front","%s: the chart draws a face-off for a tiny party" % label)


# =============================================================================
# Small helpers
# =============================================================================

func _v2(p:Variant)->Vector2:
	if p is Vector2: return p
	if p is Dictionary and (p as Dictionary).has("x"): return Vector2(float(p.get("x",0.0)),float(p.get("z",0.0)))
	return Vector2.INF


func expect_outcome(record:Dictionary,kind:String)->void:
	var want:=String((s.get("expect",{}) as Dictionary).get("winner","either"))
	if want=="ours": _check(kind in ["won","taken"],"expect","we should have won (it was %s)" % kind)
	elif want=="theirs": _check(kind in ["lost","withdrew"],"expect","we should have lost (it was %s)" % kind)
	var overrun:=String((record.get("termination",{}) as Dictionary).get("type",""))=="overrun"
	var e:Dictionary=s.get("expect",{})
	if e.has("overrun"): _check(overrun==bool(e.overrun),"expect","overrun should be %s (termination %s)" % [str(bool(e.overrun)),String((record.get("termination",{}) as Dictionary).get("type",""))])
