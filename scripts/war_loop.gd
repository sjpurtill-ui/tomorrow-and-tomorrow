extends RefCounted
## WAR IN THE LIVING WORLD: refusals that bite, raids, and general-led war.
##
## - Follow-through. A tribute demand that was not a bluff, refused or answered
##   with threats, is followed through by the ruler's trait and the real
##   strength of both peoples: most such rulers come within two years. The
##   ladder runs raid (outlying fields, herds, the gathering grounds, a hunting
##   or scouting party) -> border skirmish -> war. Called bluffs still collapse
##   (rival_rulers.bluff_called); this module never touches them.
## - Grudges feed it. A ruler's grudge weight (rival_rulers.rival_character)
##   raises the chance and the rung, and a heavy old grudge can send raiders
##   without a new demand.
## - War in the player's own world. Nothing restarts the world. The war leader
##   (the Marshal office; the Hearth Chief when there is none) carries a court
##   matter. The god summons them and gives an objective in conversation
##   (offline: a choice list; online: typed words, see typed_choice): hold the
##   approaches, go after the raiders, burn their stores, bring me their chief,
##   send for a truce, pay, or "do as you judge". The general runs the
##   operation; the combat simulator (MilitaryCampaign.simulator) resolves each
##   clash. Results come back as Chronicle moments and a report matter:
##   casualties from the real population on both sides, captives, loot, grudges.
##   A general left without word acts on their own judgment.
## - Scale. Bands are capped at the pre-modern mobilisation benchmark
##   (EPOCHAL_SHIFTS.md s3.4: 3-7% of the population), so a stone-age raid is a
##   handful of hunters and a war is a few small war bands.
## - Endings. Wars end in a truce (a messenger, or both sides worn out),
##   tribute (paid by the side that is losing; a captured chief is ransomed) or
##   exhaustion (the war is simply dropped after years of it).
## - Rival wars drag the player in. Standing with kin (a marriage or alliance)
##   in their war sends your fighters to it: war with their enemy. Standing
##   with a people you are not bound to only earns their enemy's raiders.
## - FEUD, NOT WAR, FOR SMALL PEOPLES (conflict_scale.gd). Below the war line
##   nothing declares or opens a war: the top of the ladder is an ambush that
##   kills, a killed envoy starts a blood feud, and standing with kin in a
##   feud earns their enemy's raiders. The war leader answers with the feud's
##   own acts: guard, pursue, track, burn (a home we know), strike at their
##   headman, send word, pay a blood price, or let it pass. A feud is hot
##   while blood was spilled within FEUD_HOT_DAYS (no envoys come from them
##   then, audience_hall.gd); it cools after FEUD_COLD_DAYS of quiet, with a
##   blood price, a parley that holds, their exhaustion or a marriage, and
##   flares with every new killing. A small people found "at war" (an older
##   save, a war opened before this rule) becomes a feud (reconcile()): the
##   dead, the raids and the grudges stay; fronts, terms and the general's
##   campaign go. The god's own attack on a small people keeps the engine's
##   war flag only while our band is out against them or holds a town of
##   theirs, and is told as the feud.
##
## State lives in ForeignDiplomacy.audiences["war"] (saved with the audience
## hall; older saves start with an empty ledger). Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Scale:=preload("res://scripts/conflict_scale.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const COUNCIL_PATH:="res://scripts/war_council.gd"
const Standing:=preload("res://scripts/standing.gd")

const VERSION:=1
const TICK:=5
## Pre-modern mobilisation cap (EPOCHAL_SHIFTS.md s3.4): 3-7% of the people.
const MOBILIZE_MIN:=0.03
const MOBILIZE_MAX:=0.07
## No single clash kills more than this share of a people.
const CLASH_DEATH_CAP:=0.025
const LOG_MAX:=120
const REFUSALS_MAX:=80
const TRUCE_DAYS:=3*365
const WAR_COOLDOWN:=6*365
const GENERAL_WAIT:=30
const GUARD_DAYS:=180
## What one fighter carries home, in Food.
const CARRY:=14.0
## Clashes kept to be watched in the battle panel (hud/battle_view.gd): the
## newest few, small enough to leave the saved ledger well inside its bound.
const OBSERVED_MAX:=6
const OBSERVED_CHARS:=40000
const STATE_CHARS:=190000
## Where a raid's fight was, by what they came for.
const WHERE:={"fields":"at the planted fields","herds":"out with the herds","gathering":"at the gathering grounds","racks":"at the drying racks","hunters":"out on the hunt","scouts":"out on the scouting trail"}
## Where our band's fight was, by what it went to do.
const OP_WHERE:={"war_pursue":"on the raiders' trail","war_burn":"at their stores","war_chief":"where their chief was","war_track":"on the raiders' trail"}
## Orders that must reach the enemy's home: nobody goes there until the way is
## known (relation.home_location_known). Until then the band follows the
## raiders' trail to find it (war_track), whoever gave the word.
const NEEDS_HOME:=["war_burn","war_chief"]
## A tracking party: a few good trackers, never a war band.
const TRACKERS_MIN:=2
const TRACKERS_MAX:=6
const TERMS_WAIT:=60
const LEVEL_DECAY_DAYS:=4*365
## A war in which neither side has fought for this long goes quiet: a truce.
const QUIET_DAYS:=365
## Worn-out raiders stop coming; the war can then go quiet.
const ENEMY_SPENT:=0.55
## A feud is hot while either side has spilled the other's blood (or struck at
## them) within this many days, while their raiders are on the way or a band
## of ours is out against them: that people sends nobody into the hall.
const FEUD_HOT_DAYS:=365
## With no blood spilled either way for this long, a feud goes cold.
const FEUD_COLD_DAYS:=3*365
## A worn-out or frightened people's peace-seeker comes only after the raids
## have stopped this long, and at most once a year.
const PEACE_QUIET_DAYS:=120
const PEACE_GAP:=365
## Worn out enough to send a peace-seeker (the feud's own exhaustion), or
## dreading the god this much (divine_regard.gd via court_lives.rival_dread).
const PEACE_WORN:=0.4
const PEACE_DREAD:=0.35
## A blood price: Food for each life of theirs we took, never less than this.
const PRICE_PER_DEAD:=15.0
const PRICE_MIN:=10.0
## A feud settled (a blood price, a parley, a marriage) keeps the raiders
## home this long.
const SETTLED_DAYS:=3*365
## "Bring me their chief" stands this long: a band of ours that beats the
## defenders of their chief town within it takes him (_chief_seized).
const CHIEF_DAYS:=180
## A people with no town of its own left and fewer than this many living is
## broken past feuding (broken()): a band of three would be most of its men.
const BROKEN_PEOPLE:=10.0
## A killing ambush, the feud's top rung, after a fight at the border.
const AMBUSH_CHANCE:=0.35
## Envoy business a hot conflict still lets through: those who come to end it.
## In a feud only after the raids have stopped a while (envoy_gate()).
const PEACE_TYPES:=["feud_peace","dread_tribute","peace_feeler","town_return","captive_plea","people_plea"]

## How often a ruler with a real grievance comes, by signature trait.
const FOLLOW:={"grudge":0.9,"hunter":0.8,"ledger":0.72,"bluffer":0.7,"magpie":0.62,"matchmaker":0.5}
const OBJECTIVES:=["war_guard","war_pursue","war_burn","war_chief","war_parley","war_pay","war_general","war_let","war_rest","war_track","war_price"]
const TARGETS:={
	"fields":{"words":"the planted fields","who":"field hands","lethal":true},
	"herds":{"words":"the herds","who":"herders","lethal":true},
	"gathering":{"words":"the gathering grounds","who":"gatherers","lethal":true},
	"racks":{"words":"the drying racks","who":"the old ones minding the racks","lethal":true},
	"hunters":{"words":"a hunting party","who":"hunters","lethal":true},
	"scouts":{"words":"our scouting party","who":"scouts","lethal":false},
}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:war:%s" % [int(GameState.world_seed),key])
	return rng

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get("war")
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed):
		s={"version":VERSION,"world_seed":int(GameState.world_seed),"fronts":{},"refusals":[],"log":[],"stats":{},"serial":0}
		holder["war"]=s
	var d:Dictionary=s
	for key in ["fronts","stats"]:
		if not d.get(key) is Dictionary: d[key]={}
	for key in ["refusals","log","battles"]:
		if not d.get(key) is Array: d[key]=[]
	return d

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	if not d.get("fronts",{}) is Dictionary or (d.get("fronts",{}) as Dictionary).size()>64: return false
	for key in ["refusals","log"]:
		if not d.get(key,[]) is Array: return false
	if (d.get("refusals",[]) as Array).size()>REFUSALS_MAX or (d.get("log",[]) as Array).size()>LOG_MAX: return false
	if not d.get("battles",[]) is Array or (d.get("battles",[]) as Array).size()>OBSERVED_MAX: return false
	if not d.get("stats",{}) is Dictionary: return false
	if d.has("league"):
		if not d.league is Dictionary or not (d.league as Dictionary).get("members",[]) is Array or ((d.league as Dictionary).get("members",[]) as Array).size()>16: return false
		for member in (d.league as Dictionary).get("members",[]):
			if not member is String: return false
	return JSON.stringify(d).length()<=200000

static func _stat(key:String,amount:int=1)->void:
	var stats:Dictionary=state().stats
	stats[key]=int(stats.get(key,0))+amount

static func front(civ_id:String)->Dictionary:
	var fronts:Dictionary=state().fronts
	if not fronts.get(civ_id) is Dictionary:
		fronts[civ_id]={"level":0,"last_harm":-99999,"pending":{},"war":{},"guard_until":-1,"taken":0.0,"last_war_end":-99999,"matter_day":-1}
	return fronts[civ_id]

static func _log(civ_id:String,kind:String,text:String,extra:Dictionary={})->void:
	var entry:={"day":_day(),"civ":civ_id,"kind":kind,"text":text.substr(0,300)}
	entry.merge(extra,true)
	var list:Array=state().log
	list.push_front(entry)
	while list.size()>LOG_MAX: list.pop_back()

static func summary()->Dictionary:
	## Plain numbers for tests, probes and the playtest harness.
	var s:=state()
	var real:=0; var followed:=0; var within:=0
	for r in s.refusals:
		if not r is Dictionary: continue
		real+=1
		if bool(r.get("follow",false)): followed+=1
		if int(r.get("harm_day",-1))>=0 and int(r.harm_day)-int(r.day)<=730: within+=1
	var at_war:Array=[]
	var feuding:Array=[]
	for civ_id in s.fronts:
		var f:Dictionary=s.fronts[civ_id]
		if not (f.get("war",{}) as Dictionary).is_empty(): at_war.append(String(civ_id))
		elif int(f.get("level",0))>=1: feuding.append(String(civ_id))
	return {"stats":(s.stats as Dictionary).duplicate(),"real_refusals":real,"followed":followed,"harmed_within_2y":within,"at_war":at_war,"feuding":feuding}

# --------------------------------------------------------------------------
# Peoples, strength and bands
# --------------------------------------------------------------------------

static func _civ(civ_id:String)->Dictionary:
	var index:=Hall._civ_index(civ_id)
	return WorldSimulation.world.civilizations[index] if index>=0 else {}

static func _relation(civ_id:String)->Dictionary:
	var civ:=_civ(civ_id)
	return civ.get("player_relation",{}) if not civ.is_empty() else {}

static func _name(civ_id:String)->String:
	return Hall._civ_name(civ_id)

static func _the(name:String)->String:
	return name if name.begins_with("The ") or name.begins_with("the ") else name

static func _their_pop(civ_id:String)->float:
	return maxf(10.0,float(_civ(civ_id).get("population",100.0)))

static func _our_pop()->float:
	return Hall._player_population()

static func _band_size(pop:float,share:float)->int:
	return maxi(3,roundi(pop*clampf(share,MOBILIZE_MIN,MOBILIZE_MAX)))

## Our soldiers as the war council counts them (war_council.gd _forces): at
## home, free to go beyond the watch that stays, and all under arms.
static func _soldiers()->Dictionary:
	var forces:Dictionary=_council().call("_forces")
	var all:=int(forces.get("home",0))
	for army in WorldSimulation.military.field_armies:
		if army is Dictionary: all+=maxi(0,int((army as Dictionary).get("troops",0)))
	return {"home":int(forces.get("home",0)),"free":int(forces.get("free",0)),"all":all}

## Their fighters as the world counts their army (land_military_population).
static func _their_fighters(civ_id:String)->int:
	var civ:=_civ(civ_id)
	if civ.is_empty() or not WorldSimulation.world.has_method("land_military_population"): return 0
	return floori(float(WorldSimulation.world.land_military_population(civ)))

## "They have about 240 under arms; we have 90." from the real counts.
static func _strength_words(civ_id:String)->String:
	var theirs:=_their_fighters(civ_id)
	var ours:=int(_soldiers().all)
	var they:="They keep no soldiers to speak of" if theirs<=0 else "They have about %s under arms" % EraWords.grouped(theirs)
	return "%s; %s." % [they,"we have none trained" if ours<=0 else "we have %s" % EraWords.grouped(ours)]

static func ratio(civ_id:String)->float:
	## Their fighting strength over ours: people, warriors and readiness on one
	## scale (standing.gd), not a guess. A people that keeps trained, ready
	## warriors is not the same prey as one that keeps none.
	var civ:=_civ(civ_id)
	if civ.is_empty(): return 1.0
	return clampf(Standing.their_fighting_strength(civ)/Standing.our_fighting_strength(),0.2,5.0)

static func _rival(civ_id:String)->Dictionary:
	var r:GDScript=_rivals()
	return r.call("rival_character",civ_id) if r!=null else {}

static func _our_tech()->float:
	var inventory:Dictionary=WorldSimulation.military.military_inventory
	if int(inventory.get("bow",0))>0: return 0.55
	if int(inventory.get("spear",0))>0: return 0.3
	return 0.15

static func _band(label:String,count:int,tech:float,readiness:float,leader:String,skill:float)->Dictionary:
	var formations:Array[Dictionary]=[]
	if tech>=0.52:
		var archers:=roundi(count*0.28); var line:=roundi(count*0.38)
		formations=[{"unit":"levy","weapon":"improvised","count":count-archers-line},{"unit":"line_infantry","weapon":"spear","count":line},{"unit":"skirmisher","weapon":"bow","count":archers,"ammunition":archers*6}]
	elif tech>=0.27:
		var spears:=roundi(count*0.42)
		formations=[{"unit":"levy","weapon":"improvised","count":count-spears},{"unit":"line_infantry","weapon":"spear","count":spears}]
	else:
		formations=[{"unit":"levy","weapon":"improvised","count":count}]
	var force:Dictionary=WorldSimulation.military.simulator.create_formation_force(label,formations,clampf(0.5+readiness*0.35,0.3,0.95),clampf(readiness,0.1,1.0))
	force["commander"]=WorldSimulation.military.simulator.create_commander(leader,skill,skill,0.5,clampf(skill+0.1,0.0,1.0))
	return force

static func _clash(attacker:Dictionary,defender:Dictionary,terrain:float,key:String)->Dictionary:
	## One fight, resolved by the shared combat simulator. Deaths are the share
	## of casualties who do not come home; the rest are wounded or scattered.
	# Raids and feuds: each war leader fights as his band can (battle_tactics.gd).
	var Tactics:=preload("res://scripts/battle_tactics.gd")
	var tactics:Dictionary=Tactics.plan({"attacker":{"force":attacker,"known":Tactics.known_from_force(attacker,0.2)},"defender":{"force":defender,"known":Tactics.known_from_force(defender,0.2)}},{"kind":"raid","terrain":terrain},hash(key))
	var result:Dictionary=WorldSimulation.military.simulator.simulate(attacker,defender,{"seed":hash(key),"terrain_defense":terrain,"max_rounds":6,"casualty_intensity":0.8,"tactics":tactics})
	var a:Dictionary=result.get("attacker",{}); var d:Dictionary=result.get("defender",{})
	var outcome:=String(result.get("outcome","inconclusive"))
	var rng:=_rng("clash:"+key)
	return {"outcome":outcome,"tactics":tactics,"won":outcome=="attacker_victory" or (outcome=="inconclusive" and rng.randf()<0.4),
		"att_dead":roundi(float(a.get("casualties",0))*rng.randf_range(0.3,0.5)),"def_dead":roundi(float(d.get("casualties",0))*rng.randf_range(0.3,0.5)),"result":result}


## The clashes kept to be watched, newest first (read only; nothing is made).
static func observed_battles()->Array:
	var holder:Variant=ForeignDiplomacy.get("audiences")
	var s:Variant=(holder as Dictionary).get("war") if holder is Dictionary else null
	if not s is Dictionary: return []
	var list:Variant=(s as Dictionary).get("battles",[])
	return list if list is Array else []


## Keeps a clash for the battle panel: the block battle as fought, each
## side's numbers and general, and where. home: our side's role. Returns
## the seed the panel opens it by (-1 when there is nothing to keep).
## told: what the Chronicle and the court were told (and the peoples'
## ledgers registered): {home_dead, away_dead, home_taken, away_taken}. The
## kept battle says the same (_match_told).
static func _observe(key:String,title:String,where:String,civ_id:String,home:String,fight:Dictionary,told:Dictionary={})->int:
	var result:Dictionary=fight.get("result",{}) if fight.get("result") is Dictionary else {}
	var battle:Variant=result.get("battle",{})
	if not battle is Dictionary or (battle as Dictionary).is_empty(): return -1
	var seed:=hash("seen:"+key) & 0x7fffffff
	var rounds:Array=[]
	for round_variant in result.get("rounds",[]):
		var r:Dictionary=round_variant
		rounds.append({"attacker_casualties":(r.get("attacker_casualties",{}) as Dictionary).duplicate(),"defender_casualties":(r.get("defender_casualties",{}) as Dictionary).duplicate(),
			"attacker_losses":int(r.get("attacker_losses",0)),"defender_losses":int(r.get("defender_losses",0))})
	var record:={"id":"war:"+key,"seed":seed,"observed":true,"day":_day(),"home_side":home,
		"attacker":_slim_force(result.get("attacker",{})),"defender":_slim_force(result.get("defender",{})),
		"threat":{"source_civ_id":civ_id,"source_name":_name(civ_id),"discovered_day":_day(),"field_encounter":true},
		"battle":(battle as Dictionary).duplicate(true),"tactics":(fight.get("tactics",{}) as Dictionary).duplicate(true),"outcome":String(result.get("outcome","")),
		"termination":(result.get("termination",{}) as Dictionary).duplicate(true),"rounds":rounds,"where":where,"headline":title}
	if not told.is_empty(): _match_told(record,told)
	var s:=state()
	var list:Array=s.battles
	list.push_front(record)
	while list.size()>OBSERVED_MAX: list.pop_back()
	while list.size()>1 and (JSON.stringify(list).length()>OBSERVED_CHARS or JSON.stringify(s).length()>STATE_CHARS): list.pop_back()
	if JSON.stringify(s).length()>STATE_CHARS: list.clear(); return -1
	return seed


## The kept battle's dead and taken made what was told: each side's killed
## are the dead counted (the rest of its losses hurt or scattered, each
## exchange's losses unchanged), and those taken are the beaten side's
## captives told. A war leader's clash takes nobody in the fight itself.
static func _match_told(record:Dictionary,told:Dictionary)->void:
	var home:=String(record.get("home_side","defender"))
	var away:="defender" if home=="attacker" else "attacker"
	var rounds:Array=record.get("rounds",[])
	for pair in [[home,int(told.get("home_dead",-1))],[away,int(told.get("away_dead",-1))]]:
		var side:=String(pair[0])
		var want:=int(pair[1])
		var have:=0
		for r in rounds:
			var c:Dictionary=(r as Dictionary).get(side+"_casualties",{})
			c["scattered"]=int(c.get("scattered",0))+int(c.get("captured",0)); c["captured"]=0
			have+=int(c.get("killed",0))
		if want<0: continue
		var shift:=have-want
		for r in rounds:
			if shift==0: break
			var c:Dictionary=(r as Dictionary).get(side+"_casualties",{})
			if shift>0:
				var down:=mini(shift,int(c.get("killed",0)))
				c["killed"]=int(c.get("killed",0))-down; c["wounded"]=int(c.get("wounded",0))+down; shift-=down
			else:
				var from_wounded:=mini(-shift,int(c.get("wounded",0)))
				c["wounded"]=int(c.get("wounded",0))-from_wounded; c["killed"]=int(c.get("killed",0))+from_wounded; shift+=from_wounded
				var from_scattered:=mini(-shift,int(c.get("scattered",0)))
				c["scattered"]=int(c.get("scattered",0))-from_scattered; c["killed"]=int(c.get("killed",0))+from_scattered; shift+=from_scattered
	var termination:Dictionary=record.get("termination",{})
	var beaten_home:=String(termination.get("defeated",""))==String((record.get(home,{}) as Dictionary).get("name","~"))
	termination["prisoners"]=maxi(0,int(told.get("home_taken" if beaten_home else "away_taken",0)))


static func _slim_force(force:Dictionary)->Dictionary:
	var out:={"commander":(force.get("commander",{}) as Dictionary).duplicate(true)}
	for key in ["name","initial_troops","remaining_troops","casualties","morale","routed","captured_in_battle","dead","wounded_pool","scattered_pool","captured_pool"]:
		if force.has(key): out[key]=force[key]
	return out

static func _cap_dead(n:int,pop:float)->int:
	return clampi(n,0,maxi(1,ceili(pop*CLASH_DEATH_CAP)))

## The official who carries the war's matters at court: the Marshal, else the
## headman, who stands in for the war (court_war_orders.war_leader).
static func _general()->Dictionary:
	return Hall._relevant_official(["Marshal","Steward"])

static func _general_skill(general:Dictionary)->float:
	var skills:Dictionary=general.get("skills",{}) if general.get("skills") is Dictionary else {}
	return clampf(float(skills.get("Defense",40.0))/100.0*0.6+float(general.get("courage",0.5))*0.25+0.1,0.2,0.9)

# --------------------------------------------------------------------------
# Losses on both sides, from the real population
# --------------------------------------------------------------------------

static func _our_deaths(count:int)->int:
	if count<=0: return 0
	return int(GameState.register_population_deaths(count,"Killed in battle").get("count",0))

static func _our_captives_lost(count:int,civ_id:String)->int:
	if count<=0: return 0
	var taken:=int(GameState.register_population_departures(count,"Taken captive by %s" % _name(civ_id),{"children":1.2,"youth":1.4,"early_adults":1.0,"established_adults":0.6,"mature_adults":0.3,"elders":0.1}).get("count",0))
	# Kept with the holder, ages as taken, for a ransom (trade_ledger.gd note_captives).
	if taken>0: (load("res://scripts/trade_ledger.gd") as GDScript).call("note_captives",civ_id,"player",taken,(GameState.last_population_removal_by_cohort as Dictionary).duplicate())
	return taken

static func _their_deaths(civ_id:String,count:int)->int:
	if count<=0: return 0
	if WorldSimulation.actors.has(civ_id):
		return int(WorldSimulation.scoped(civ_id,func()->int:return int(WorldSimulation.state.register_population_deaths(count,"Killed in battle").get("count",0))))
	var index:=Hall._civ_index(civ_id)
	if index<0: return 0
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var before:=float(civ.get("population",0.0))
	var dead:=minf(float(count),maxf(0.0,before-1.0))
	if dead<=0.0: return 0
	civ["population"]=before-dead
	civ["military_population"]=maxf(0.0,float(civ.get("military_population",0.0))-dead*0.7)
	if civ.get("cohorts") is Dictionary and world.has_method("_remove_weighted_cohort_population"):
		civ["cohorts"]=world._scaled_cohorts(world._remove_weighted_cohort_population(civ.cohorts,dead,{"children":0.08,"youth":1.3,"early_adults":1.85,"established_adults":1.7,"mature_adults":1.05,"elders":0.18}),float(civ.population))
	if world.has_method("_scale_strategic_region_populations"): civ=world._scale_strategic_region_populations(civ,float(civ.population)/maxf(1.0,before))
	world.civilizations[index]=civ
	return roundi(dead)

static func _their_captives(civ_id:String,count:int)->int:
	## Captives brought home join the people's hearths.
	if count<=0: return 0
	var taken:=0
	if WorldSimulation.actors.has(civ_id):
		taken=int(WorldSimulation.scoped(civ_id,func()->int:return int(WorldSimulation.state.register_population_departures(count,"Taken captive").get("count",0))))
	else:
		taken=_their_deaths(civ_id,count)
	if taken>0: GameState.register_population_arrivals(taken,"Captives from %s" % _name(civ_id))
	return taken

static func _names(count:int,key:String,women_share:float)->Array[String]:
	## The named dead: the people are counted in aggregate, but the Chronicle
	## gives the first few their names.
	var used:Dictionary={}
	var fallen:Array=state().get("fallen",[]) if state().get("fallen") is Array else []
	for given_name in fallen: used["given:"+String(given_name)]=true
	var out:Array[String]=[]
	for i in mini(count,3):
		var serial:=posmod(hash("%s:%d" % [key,i]),800000)+100000
		var woman:=_rng("%s:%d:w" % [key,i]).randf()<women_share
		var identity:Dictionary=EraNames.make(int(GameState.world_seed),serial,woman,"player",used)
		var given:=String(identity.get("given",String(identity.get("name","")).get_slice(" ",0)))
		if given=="" or used.has("given:"+given): continue
		used["given:"+given]=true
		out.append(given)
		fallen.push_front(given)
	while fallen.size()>60: fallen.pop_back()
	state()["fallen"]=fallen
	return out

static func _dead_words(count:int,names:Array[String],who:String)->String:
	if count<=0: return "No one of ours was killed."
	var listed:=", ".join(PackedStringArray(names)) if names.size()<=2 else "%s and %s" % [", ".join(PackedStringArray(names.slice(0,names.size()-1))),names[-1]]
	if names.size()==2: listed="%s and %s" % [names[0],names[1]]
	# "the old ones minding the racks" is said once: "of the old ones ...".
	var group:=who.trim_prefix("the ")
	if count>names.size() and not names.is_empty(): return "%s and %d more of the %s were killed." % [listed,count-names.size(),group]
	if names.is_empty(): return "%d of the %s were killed." % [count,group]
	return "%s %s killed." % [listed,"was" if count==1 else "were"]

static func _record_battle(civ_id:String,name:String,our_dead:int,their_dead:int,taken:int,result:String)->void:
	var war:Dictionary=front(civ_id).get("war",{})
	var war_id:=String(war.get("war_id",""))
	if war_id=="" or not WorldSimulation.world.has_method("_record_war_battle"): return
	WorldSimulation.world._record_war_battle(war_id,{"day":_day(),"name":name,"location":"frontier","outcome":result,
		"losses":{"player":{"military_dead":our_dead,"civilian_dead":0,"wounded":our_dead,"captured":0,"displaced":0},civ_id:{"military_dead":their_dead,"civilian_dead":0,"wounded":their_dead,"captured":taken,"displaced":0}}})

static func _exhaust(civ_id:String,our_dead:int,their_dead:int)->void:
	var war:Dictionary=front(civ_id).get("war",{})
	if war.is_empty(): return
	preload("res://scripts/deeds.gd").blood(civ_id,their_dead,false)
	war["our_dead"]=int(war.get("our_dead",0))+our_dead
	war["their_dead"]=int(war.get("their_dead",0))+their_dead
	war["our_exh"]=clampf(float(war.get("our_exh",0.0))+0.04+float(our_dead)/_our_pop()*6.0,0.0,1.0)
	war["their_exh"]=clampf(float(war.get("their_exh",0.0))+0.04+float(their_dead)/_their_pop(civ_id)*6.0,0.0,1.0)
	var index:=Hall._civ_index(civ_id)
	if index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[index].player_relation
		relation["player_war_exhaustion"]=maxf(float(relation.get("player_war_exhaustion",0.0)),float(war.our_exh))
		relation["rival_war_exhaustion"]=maxf(float(relation.get("rival_war_exhaustion",0.0)),float(war.their_exh))

## battle_seed: a clash kept to be watched (the Chronicle offers to).
static func _chronicle(key:String,title:String,text:String,tier:String,civ_id:String,battle_seed:int=-1)->void:
	var action:={"kind":"court","focus":{"civ_id":civ_id}}
	if battle_seed>=0: action["battle_seed"]=battle_seed
	Chronicle.record({"key":"war:"+key,"title":title.substr(0,70),"text":text,"tier":tier,"kind":"war","domain":"security",
		"action":action})

static func _pick_target(civ_id:String,rng:RandomNumberGenerator)->String:
	var known:Array=GameState.known_discoveries
	var weights:={"gathering":1.0,"racks":0.8,"hunters":0.9}
	if "tillage" in known or "seed_selection" in known: weights["fields"]=1.4
	if "animal_taming" in known: weights["herds"]=1.2
	if not (WorldSimulation.world.scout_missions as Array).is_empty(): weights["scouts"]=0.35
	var total:=0.0
	for k in weights: total+=float(weights[k])
	var roll:=rng.randf()*total
	for k in weights:
		roll-=float(weights[k])
		if roll<=0.0: return String(k)
	return "gathering"

# --------------------------------------------------------------------------
# Refusals and follow-through
# --------------------------------------------------------------------------

static func after_answer(audience:Dictionary,option_id:String)->void:
	## Called by rival_rulers.after_answer for every foreign answer.
	if String(audience.get("origin",""))!="foreign" or WorldSimulation.actor_id!="player": return
	var civ_id:=String(audience.get("civ_id",""))
	if civ_id=="": return
	var kind:=String(audience.get("kind",""))
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var type:=String(situation.get("type",""))
	var bluff:=bool((audience.get("hidden",{}) as Dictionary).get("bluff",false)) if audience.get("hidden") is Dictionary else false
	# Their peace-seeker, or frightened tribute brought while we feud: taking it
	# ends the feud; turning it away keeps it.
	if type=="feud_peace" or (type=="dread_tribute" and feuding(civ_id) and option_id in ["accept","accept_return"]):
		_peace_answered(audience,option_id)
		return
	if kind=="threat" and option_id in ["defy","counter"] and not bluff: on_refusal(audience,option_id)
	elif kind=="threat" and option_id in ["defy","counter"] and bluff: _stat("bluffs_called")
	elif kind=="threat" and option_id=="pay": _stat("paid")
	if type=="war_support" and option_id=="stand": _stand_with(civ_id,String(situation.get("enemy","")))
	# A tributary's call for protection, answered (world_answer.gd).
	if type=="war_support": (load("res://scripts/world_answer.gd") as GDScript).call("protection_answered",civ_id,String(situation.get("enemy","")),option_id)

static func on_refusal(audience:Dictionary,option_id:String)->Dictionary:
	## A real demand refused: the ruler decides, by trait and strength, whether
	## and when to come.
	var civ_id:=String(audience.civ_id)
	var s:=state()
	var day:=_day()
	var rival:=_rival(civ_id)
	var trait_id:=String(rival.get("trait",""))
	var grudge:=float(rival.get("grudge_weight",0.0))
	var r:=ratio(civ_id)
	var civ:=_civ(civ_id)
	var chance:=float(FOLLOW.get(trait_id,0.7))+minf(grudge,1.5)*0.1+clampf(r-1.0,-0.6,0.8)*0.3+(0.1 if option_id=="counter" else 0.0)+(0.08 if Hall._hungry(civ) else 0.0)
	chance=clampf(chance,0.2,0.95)
	var rng:=_rng("refusal:"+String(audience.id))
	var follow:=rng.randf()<chance
	var entry:={"day":day,"civ":civ_id,"id":String(audience.id),"type":String((audience.get("situation",{}) as Dictionary).get("type","")),"follow":follow,"harm_day":-1,"chance":snappedf(chance,0.01)}
	(s.refusals as Array).push_front(entry)
	while (s.refusals as Array).size()>REFUSALS_MAX: (s.refusals as Array).pop_back()
	_stat("real_refusals")
	if follow:
		var lo:=20 if trait_id=="hunter" else 40
		var hi:=150 if trait_id=="hunter" else 260
		_schedule(civ_id,day+rng.randi_range(lo,hi),"refusal",String(audience.id))
	else:
		_log(civ_id,"stood_down","%s let the refusal pass." % String(rival.get("name",_name(civ_id))),{"ref":String(audience.id)})
	return entry

static func _schedule(civ_id:String,due:int,cause:String,ref:String)->void:
	var f:=front(civ_id)
	var pending:Dictionary=f.pending
	if pending.is_empty() or due<int(pending.get("day",due)):
		f["pending"]={"day":due,"cause":cause,"ref":ref,"stack":int(pending.get("stack",0))+1}
		_foresee(civ_id,f.pending)
	else:
		pending["stack"]=int(pending.get("stack",1))+1

## CUNNING SEES THEM COMING (standing.gd forewarn_odds, forewarn_days): when a
## raid is set for a day, our watchers see it coming on our cunning's odds,
## that many days ahead (seeded; stated on the Standing page). Seen, the watch
## keeps the approaches from the warning until the raiders come, and meets
## them on ground of our choosing (_raid's guard).
static func _foresee(civ_id:String,pending:Dictionary)->void:
	var cunning:=Standing.art_of("player","cunning")
	var odds:=Standing.forewarn_odds(cunning)
	var due:=int(pending.get("day",_day()))
	pending["seen_odds"]=snappedf(odds,0.01)
	if _rng("foresee:%s:%d" % [civ_id,due]).randf()>=odds: return
	pending["seen"]=true
	pending["warn_day"]=maxi(_day(),due-Standing.forewarn_days(cunning))

## The warning comes on its day: told under the clock, and the watch keeps
## the approaches through the day they come.
static func _forewarn(civ_id:String,f:Dictionary,day:int)->void:
	var pending:Dictionary=f.pending
	if pending.is_empty() or not bool(pending.get("seen",false)) or bool(pending.get("warned",false)) or day<int(pending.get("warn_day",day)): return
	pending["warned"]=true
	var due:=int(pending.get("day",day))
	f["guard_until"]=maxi(int(f.get("guard_until",-1)),due+TICK+1)
	var name:=_name(civ_id)
	_chronicle("forewarned:%s:%d" % [civ_id,due],"Raiders From %s Seen Gathering" % name,"Our watchers saw %s's raiders gathering: they may come within %d days. The watch keeps the approaches until they do. (We see raiders coming %d times in 100, by our cunning.)" % [name,maxi(1,due-day),roundi(float(pending.get("seen_odds",0.5))*100.0)],"notice",civ_id)
	_log(civ_id,"seen_coming","Our watchers saw %s's raiders gathering, about %d days before they came." % [name,maxi(1,due-day)])

static func _mark_harm(civ_id:String,day:int)->void:
	for r in state().refusals:
		if r is Dictionary and String(r.get("civ",""))==civ_id and int(r.get("harm_day",-1))<0 and day-int(r.get("day",0))<=730 and day>=int(r.get("day",0)):
			r["harm_day"]=day

## Bound to leave us alone (a truce, a pact, a feud settled with a price or a
## parley, kin by marriage): their envoys bring no threats or demands.
static func keeps_peace(civ_id:String,day:int)->bool:
	return _truce_binds(civ_id,day)

static func _truce_binds(civ_id:String,day:int)->bool:
	var relation:=_relation(civ_id)
	if String(relation.get("treaty","none"))=="non_aggression" or int(relation.get("truce_until_day",0))>day: return true
	# A feud settled with a blood price or a parley, and kin by marriage, keep
	# their raiders home.
	if int(_peek(civ_id).get("settled_until",-1))>day: return true
	# A people that bowed and pays its tribute keeps its raiders home.
	if bool((load("res://scripts/world_answer.gd") as GDScript).call("is_tributary",civ_id)): return true
	return not _married(civ_id).is_empty()

## A marriage between our peoples (rival_rulers.gd bonds): kin do not raid kin.
## Read only: a ruler whose character is not yet made has no bonds (asking
## never makes one; the character's birth and death stay where they fall).
static func _married(civ_id:String)->Dictionary:
	var known:Variant=ForeignDiplomacy.leaders.get(civ_id,{})
	var c:Variant=(known as Dictionary).get("character") if known is Dictionary else null
	if not c is Dictionary: return {}
	for b in (c as Dictionary).get("bonds",[]):
		if b is Dictionary and String((b as Dictionary).get("kind",""))=="marriage" and int((b as Dictionary).get("until",1<<30))>_day(): return b
	return {}

static func _execute(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var pending:Dictionary=f.pending
	f["pending"]={}
	var relation:=_relation(civ_id)
	var formal:=Scale.formal(civ_id)
	# In a war their host comes (_enemy_op); in a feud their raiders come even
	# while our own band is out against them.
	if relation.is_empty() or (bool(relation.get("at_war",false)) and formal): return
	if _truce_binds(civ_id,day):
		var why:="%s kept to the truce." % _name(civ_id)
		if not _married(civ_id).is_empty(): why="%s did not come: kin by marriage do not raid kin." % _name(civ_id)
		elif int(f.get("settled_until",-1))>day: why="%s kept to the settlement of the feud." % _name(civ_id)
		_log(civ_id,"held_back",why)
		return
	# A people broken past fighting has nobody to send (broken()).
	if broken(civ_id):
		_log(civ_id,"stood_down","No raiders came from %s: no town of theirs is left, and too few of them live." % _name(civ_id),{"ref":String(pending.get("ref",""))})
		return
	# A people worn out by the feud keeps its raiders home.
	if not formal and float(f.get("their_exh",0.0))>=ENEMY_SPENT:
		_log(civ_id,"stood_down","%s has buried too many of its own; no raiders came." % _name(civ_id),{"ref":String(pending.get("ref",""))})
		return
	if day-int(f.last_harm)>LEVEL_DECAY_DAYS: f["level"]=maxi(0,int(f.level)-1)
	var rival:=_rival(civ_id)
	var rng:=_rng("rung:%s:%d" % [civ_id,day])
	var level:=int(f.level)
	var cause:=String(pending.get("cause","refusal"))
	# The ladder is strict: the top rung comes only after they have already
	# fought us at the border (a skirmish of theirs within three years). Among
	# peoples organised for war that rung is war; among small peoples it is an
	# ambush that kills (conflict_scale.gd): nobody declares anything.
	if level>=2 and day-int(f.get("last_skirmish",-99999))<=3*365:
		if formal and day-int(f.last_war_end)>=WAR_COOLDOWN:
			var p_war:=clampf(0.12+ratio(civ_id)*0.12+float(rival.get("grudge_weight",0.0))*0.1+(0.1 if String(rival.get("trait","")) in ["grudge","hunter"] else 0.0),0.1,0.5)
			if rng.randf()<p_war:
				declare(civ_id,day,_cause_words(civ_id,cause))
				return
		elif not formal and rng.randf()<AMBUSH_CHANCE+minf(float(rival.get("grudge_weight",0.0)),1.0)*0.1:
			_raid(civ_id,day,cause,true,true)
			return
	if level>=1 and rng.randf()<0.6: _raid(civ_id,day,cause,true)
	else: _raid(civ_id,day,cause,false)

static func _cause_words(civ_id:String,cause:String)->String:
	match cause:
		"refusal": return "the tribute you would not pay"
		"grudge":
			var rival:=_rival(civ_id)
			var grudges:Array=rival.get("grudges",[])
			if not grudges.is_empty(): return (_rivals().call("narrate",String((grudges[0] as Dictionary).get("text","an old wrong"))) as String)
			return "an old wrong"
		"sided": return "your siding with their enemy"
		"vengeance": return "the blood your fighters spilled"
		"envy": return "our full stores, with too few to guard them"
	return "old wrongs"

# --------------------------------------------------------------------------
# Raids and skirmishes
# --------------------------------------------------------------------------

## THEIR RAID ON US, fought by the one war engine. A simulated people that
## knows a town of ours and has men to spare sends a real band by the land
## road (its own war council, war_council.gd: our watch may go out to meet it,
## the map shows it coming, the battle is the engine's and both armies bury
## their own). Otherwise their raiders fall on our people out at the work
## here and now: men of their real army (a band formed from their levy, or
## their counted fighters), against our watch (our real soldiers at home,
## when the war leader keeps the approaches: Defend) or against those out at
## the work. The dead on each side come off the real ledgers: their army,
## our army or our people.
static func _raid(civ_id:String,day:int,cause:String,skirmish:bool,ambush:bool=false)->Dictionary:
	if not ambush and _their_council_marches(civ_id,day,cause):
		_log(civ_id,"raid_called","%s's war leader calls a raid on us, by the land road." % _name(civ_id),{"cause":cause})
		_stat("raids_marched")
		came_to_us(civ_id,day,"raiders")
		return {}
	# Raiders who cannot march a real band to us walk no farther than a
	# neighbour's road: a people whose country is nowhere near ours, or across
	# the sea, sends no raiders out of nowhere.
	if not near_us(civ_id):
		_log(civ_id,"stood_down","No raiders came from %s: their country lies too far from ours." % _name(civ_id),{"cause":cause})
		_stat("raids_too_far")
		return {}
	var f:=front(civ_id)
	var name:=_name(civ_id)
	var key:="raid:%s:%d" % [civ_id,day]
	var rng:=_rng(key)
	var target:=_pick_target(civ_id,rng)
	# An ambush waits for people out in the open: hunters, herders, gatherers.
	if ambush and not target in AMBUSHED: target=String(AMBUSHED[rng.randi_range(0,AMBUSHED.size()-1)])
	if ambush and target=="herds" and not "animal_taming" in GameState.known_discoveries: target="hunters"
	var t:Dictionary=TARGETS[target]
	var guarded:=int(f.guard_until)>day
	# Their raiders: the benchmark share of their people (3-7%), as far as
	# their real army has the men.
	var want:=_band_size(_their_pop(civ_id),rng.randf_range(0.05,0.07) if skirmish else rng.randf_range(0.03,0.05))
	var raiders:=_their_raiders(civ_id,want,name)
	var their_n:=int(raiders.get("n",0))
	if their_n<RAIDERS_MIN:
		_log(civ_id,"stood_down","No raiders came from %s: they have too few under arms to send." % name,{"cause":cause})
		_stat("raids_unmanned")
		return {}
	came_to_us(civ_id,day,"raiders")
	var general:=_general()
	var mc:Variant=WorldSimulation.military
	# Ours: the watch at the approaches (our real soldiers at home) while the
	# war leader keeps it; else those out at the work, who are no soldiers.
	var soldiers:bool=guarded and not ambush and mc!=null and int(mc.home_army.get("troops",0))>0 and not bool(mc._home_battle_running())
	var defender:Dictionary
	var our_n:=0
	var guard_words:=""
	if soldiers:
		defender=mc._home_defense_force(true)
		our_n=int(defender.get("troops",0))
		guard_words=_home_guard_words(defender)
	else:
		our_n=_band_size(_our_pop(),rng.randf_range(0.02,0.035) if ambush else (rng.randf_range(0.04,0.06) if skirmish else rng.randf_range(0.02,0.035)))
		defender=_band(String(GameState.settlement_name),our_n,_our_tech(),0.4,String(general.get("name","")),0.4)
	# An ambush strikes from cover; the watch at the approaches takes that away.
	var fight:=_clash(raiders.force,defender,1.35 if guarded else (0.85 if ambush else 1.0),key)
	var won:=bool(fight.won)
	var lethal:=bool(t.lethal)
	var our_dead:=0
	if soldiers: our_dead=_commit_watch(fight,defender,civ_id,key)
	else: our_dead=_cap_dead(_killed(fight.get("result",{}),"defender"),_our_pop()) if lethal else 0
	var their_dead:=_commit_raiders(civ_id,raiders,fight,key)
	var stock:=Hall.player_stock("Food")
	var loot:=0.0
	# They came for blood, not stores: an ambush carries off little.
	if won: loot=minf(stock*rng.randf_range(0.05,0.12)*(0.25 if ambush else (1.4 if skirmish else 1.0)),float(their_n)*CARRY)
	elif rng.randf()<0.4 and not ambush: loot=minf(stock*0.02,float(their_n)*4.0)
	if target=="scouts": loot=minf(loot,12.0)
	var taken:=EXCHANGE.take("player","Food",loot) if loot>=1.0 else 0.0
	if taken>0.0: Hall._credit_civ(civ_id,"Food",taken*(0.5 if target=="fields" else 1.0))
	var captives:=0
	if won and lethal and target in ["gathering","hunters","herds"] and rng.randf()<(0.35 if ambush else (0.3 if skirmish else 0.18)): captives=1
	var names:=_names(our_dead,key,0.5 if target in ["gathering","racks"] else 0.15)
	if not soldiers: our_dead=_our_deaths(our_dead)
	captives=_our_captives_lost(captives,civ_id)
	Hall._shift_relation(civ_id,-0.06 if skirmish else -0.04,0.14 if skirmish else 0.1)
	var rivals:=_rivals()
	if cause=="refusal": rivals.call("settle_grudges",civ_id,0.4)
	if their_dead>0: rivals.call("grudge",civ_id,"the %s we lost at your %s" % ["hunters" if their_dead>1 else "hunter",String(t.words).trim_prefix("the ").trim_prefix("a ").trim_prefix("our ")],0.25,"raid_dead:"+key)
	var fresh:=int(f.get("feud_since",-1))<0 or day-int(f.last_harm)>LEVEL_DECAY_DAYS or int(f.level)<1
	f["level"]=maxi(int(f.level),2 if skirmish else 1)
	if fresh: _begin_feud(f,day)
	f["last_harm"]=day
	if skirmish: f["last_skirmish"]=day
	f["taken"]=taken
	f["last_raid"]={"day":day,"target":target,"their_n":their_n,"our_dead":our_dead,"their_dead":their_dead,"taken":roundi(taken),"captives":captives,"skirmish":skirmish,"ambush":ambush,"cause":cause,"names":names,"watch":soldiers}
	_tally(civ_id,"raids",our_dead+captives,their_dead)
	_mark_harm(civ_id,day)
	_stat("ambushes" if ambush else ("skirmishes" if skirmish else "raids"))
	# Blood asks for blood: raiders who left their own dead on our ground may
	# come back for them, unless the feud has worn them out.
	if their_dead>0 and (f.pending as Dictionary).is_empty() and float(f.get("their_exh",0.0))<ENEMY_SPENT:
		var again:=clampf(0.3+minf(float(_rival(civ_id).get("grudge_weight",0.0)),2.5)*0.1,0.3,0.55)
		if rng.randf()<again: _schedule(civ_id,day+rng.randi_range(60,240),"vengeance",key)
	# Vengeance that drew no blood is not yet paid: they may come again.
	if cause=="vengeance" and our_dead+captives<=0 and (f.pending as Dictionary).is_empty() and float(f.get("their_exh",0.0))<ENEMY_SPENT and rng.randf()<0.5:
		_schedule(civ_id,day+rng.randi_range(60,240),"vengeance",key)
	# Told plainly: who came, where, who met them, who died, what was taken, and why.
	var where:=String(t.words)
	var text:=""
	var who:=String(t.who)
	if soldiers: who="watch"
	if target=="scouts":
		text="%d %s men caught %s in the open and drove them home. They took %d Food from the packs." % [their_n,name,where,roundi(taken)]
	elif ambush:
		text="%d %s men lay in wait for our %s and fell on them. %s" % [their_n,name,String(t.who),_dead_words(our_dead,names,String(t.who))]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
		if taken>=1.0: text+=" They took %d Food." % roundi(taken)
	elif soldiers:
		text="%d %s fighters came for %s and %s met them at the approaches. %s" % [their_n,name,where,guard_words,_dead_words(our_dead,names,"watch")]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
		text+=" They took %d Food." % roundi(taken) if taken>=1.0 else " They took nothing."
	elif skirmish:
		text="%d %s fighters crossed the border at %s and our people met them. %s" % [their_n,name,where,_dead_words(our_dead,names,String(t.who))]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
		text+=" They took %d Food." % roundi(taken) if taken>=1.0 else " They took nothing."
	else:
		text="At first light %d %s men came for %s. %s" % [their_n,name,where,_dead_words(our_dead,names,String(t.who))]
		text+=" They carried off %d Food." % roundi(taken) if taken>=1.0 else " They were driven off empty-handed."
		if their_dead>0: text+=" %d of the raiders did not go home." % their_dead
	if captives>0: text+=" One of ours was taken away with them."
	if guarded and not won and not soldiers: text+=" The watch at the approaches held."
	text+=" It was for %s." % _cause_words(civ_id,cause) if cause!="" else ""
	var title:="%s Ambush Our %s" % [name,_cap(String(t.who))] if ambush else "%s %s at %s" % [name,"Fighters" if skirmish else "Raiders",_title_place(where.trim_prefix("our "))]
	var seen:=_observe(key,title,String(WHERE.get(target,"")),civ_id,"defender",fight,{"home_dead":our_dead,"away_dead":their_dead,"home_taken":captives,"away_taken":0})
	_chronicle(key,title,text,"moment" if our_dead>0 or skirmish or captives>0 else "notice",civ_id,seen)
	ForeignDiplomacy.remember(civ_id,"Our %s went against the god's people at %s and came home with %d Food." % ["fighters" if skirmish else "raiders",where,roundi(taken)])
	_log(civ_id,"ambush" if ambush else ("skirmish" if skirmish else "raid"),text,{"our_dead":our_dead,"their_dead":their_dead,"taken":roundi(taken),"captives":captives,"target":target,"cause":cause,"watch":soldiers})
	_file(civ_id,"raided",text,day)
	return f.last_raid

## The fewest raiders worth the name.
const RAIDERS_MIN:=3

## A simulated people that knows a town of ours and has men to spare: its
## war council sends the raid as a real band (war_council.call_raid). True
## when the raid went to their council.
static func _their_council_marches(civ_id:String,day:int,cause:String)->bool:
	if not WorldSimulation.enabled or not WorldSimulation.actors.has(civ_id): return false
	return bool(WorldSimulation.scoped(civ_id,func()->bool:
		var council:=_council()
		if (council.call("known_towns","human") as Array).is_empty(): return false
		if int((council.call("_forces") as Dictionary).get("free",0))<RAIDERS_MIN: return false
		council.call("call_raid","human",cause,"war_loop:%s:%d" % [civ_id,day])
		return true))

## Their raiders, out of their real army: {n, force, band_id}. In a world of
## simulated peoples a band formed from their own levy at home (their watch
## stays), which fights and is folded back (_commit_raiders); else as many of
## their counted fighters (CivilizationSystem.land_military_population).
static func _their_raiders(civ_id:String,want:int,name:String)->Dictionary:
	if WorldSimulation.enabled and WorldSimulation.actors.has(civ_id):
		return WorldSimulation.scoped(civ_id,func()->Dictionary:
			var mc:Variant=WorldSimulation.military
			var home:=int(mc.home_army.get("troops",0))
			var n:=mini(want,home-ceili(float(home)*0.2))
			if n<RAIDERS_MIN: return {"n":0}
			var made:Dictionary=mc.create_field_army(n,"%s raiders" % name)
			if made.has("error"): return {"n":0}
			var band:Dictionary=made.army
			return {"n":int(band.get("troops",0)),"force":band.duplicate(true),"band_id":int(band.get("army_id",0))})
	var civ:=_civ(civ_id)
	var have:=floori(float(WorldSimulation.world.land_military_population(civ))) if WorldSimulation.world.has_method("land_military_population") else 0
	var n:=mini(want,have)
	if n<RAIDERS_MIN: return {"n":0}
	return {"n":n,"force":_band("%s raiders" % name,n,float(civ.get("knowledge",0.15)),float(civ.get("military_readiness",0.5)),"their war leader",0.5),"band_id":0}

## Those of a side killed in a fight, as the engine counts them (its rounds).
static func _killed(result:Dictionary,side:String)->int:
	var n:=0
	for r in result.get("rounds",[]):
		if r is Dictionary: n+=int(((r as Dictionary).get(side+"_casualties",{}) as Dictionary).get("killed",0))
	return n

## Our watch fought them: the fight is committed to our real army at home
## (MilitaryCampaign: its dead, hurt and scattered, the watch's neighbours who
## stood with it sent back to work), recorded like any battle of ours. The
## killed of ours.
static func _commit_watch(fight:Dictionary,defender:Dictionary,civ_id:String,key:String)->int:
	var mc:Variant=WorldSimulation.military
	var result:Dictionary=(fight.get("result",{}) as Dictionary).duplicate(true)
	result["home_side"]="defender"
	result["home_force_kind"]="field"
	result["militia_id"]=int(defender.get("emergency_militia_id",-1))
	# The home guard posted in our other towns stood there (watch_military.gd).
	result["posted_guard"]=(defender.get("posted_guard",{}) as Dictionary).duplicate(true)
	result["campaign_mode"]="defensive"
	result["threat"]={"source_civ_id":civ_id,"source_name":_name(civ_id),"incident_kind":"raid","campaign_mode":"defensive","war_loop":key}
	mc._commit_campaign_battle(result)
	return _killed(result,"defender")

## Their raiders' losses off their real army: a simulated people's band takes
## the fight (civilization_combat.commit_enemy) and what is left of it goes
## back into their levy; else their counted fighters and people. The killed.
static func _commit_raiders(civ_id:String,raiders:Dictionary,fight:Dictionary,key:String)->int:
	var result:Dictionary=(fight.get("result",{}) as Dictionary).duplicate(true)
	var killed:=_killed(result,"attacker")
	var band_id:=int(raiders.get("band_id",0))
	if band_id>0 and WorldSimulation.actors.has(civ_id):
		result["home_side"]="defender"
		result["threat"]={"source_civ_id":civ_id,"owned_target":{"actor":civ_id,"field_id":band_id,"city_id":""},"war_loop":key}
		preload("res://scripts/civilization_combat.gd").commit_enemy(result)
		WorldSimulation.scoped(civ_id,func()->void:
			var mc:Variant=WorldSimulation.military
			if mc._field_army_index(band_id)>=0: mc.disband_field_army(band_id))
		return killed
	return _their_deaths(civ_id,_cap_dead(killed,_their_pop(civ_id)))

## Who of ours stood at home, as _home_defense_force mustered them, in
## words: "our 47 fighters, 3 on watch and 9 townsfolk".
static func _home_guard_words(defender:Dictionary)->String:
	var everyone:=int(defender.get("troops",0))
	var militia:=preload("res://scripts/civilization_combat.gd").home_militia()
	var untrained:=mini(everyone,int(defender.get("emergency_militia_personnel",0)))
	var rise:=mini(untrained,int(militia.rise))
	var watch:=untrained-rise
	var parts:PackedStringArray=[]
	if everyone-untrained>0:parts.append("our %d fighters" % (everyone-untrained))
	if watch>0:parts.append(("%d of our watch" if parts.is_empty() else "%d on watch") % watch)
	if rise>0:parts.append(("%d of our townsfolk" if parts.is_empty() else "%d townsfolk") % rise)
	if parts.is_empty():return "our people"
	if parts.size()==1:return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[parts.size()-1]

## Where an ambush waits: people out at their work in the open.
const AMBUSHED:=["hunters","gathering","herds"]

## A feud begins (or begins again after going cold): its own count of the
## dead, the raids and the strikes starts now; the grudges carry over.
static func _begin_feud(f:Dictionary,day:int)->void:
	f["feud_since"]=day
	for key in ["our_dead","their_dead","raids","strikes"]: f[key]=0
	f["our_exh"]=0.0; f["their_exh"]=0.0
	f.erase("cold_day")

## One exchange of the feud, counted: who struck ("raids" theirs, "strikes"
## ours), the dead on each side, and how worn each people is by it (the same
## measure a war keeps, _exhaust).
static func _tally(civ_id:String,kind:String,our_dead:int,their_dead:int)->void:
	# Their dead are remembered a generation (deeds.gd): raiders killed at our
	# hearths are feared more than resented.
	preload("res://scripts/deeds.gd").blood(civ_id,their_dead,kind=="raids")
	var f:=front(civ_id)
	f[kind]=int(f.get(kind,0))+1
	f["our_dead"]=int(f.get("our_dead",0))+our_dead
	f["their_dead"]=int(f.get("their_dead",0))+their_dead
	f["our_exh"]=clampf(float(f.get("our_exh",0.0))+0.03+float(our_dead)/_our_pop()*6.0,0.0,1.0)
	f["their_exh"]=clampf(float(f.get("their_exh",0.0))+0.03+float(their_dead)/_their_pop(civ_id)*6.0,0.0,1.0)

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

## A place as a Chronicle title names it: "the drying racks" -> "the Drying
## Racks", "planted fields" -> "Planted Fields".
static func _title_place(text:String)->String:
	var words:=text.split(" ",false)
	for i in words.size():
		if i>0 and words[i] in ["the","of","at","by","in","on","and","to"]: continue
		if i==0 and words[i] in ["the","a","an"] and words.size()>1: continue
		words[i]=_cap(words[i])
	return " ".join(words)

# --------------------------------------------------------------------------
# War: declaration, the general's operations, the enemy's, the ending
# --------------------------------------------------------------------------

static func declare(civ_id:String,day:int,cause:String,ally:String="")->bool:
	## War between peoples organised for it. Between smaller peoples nothing is
	## declared: the feud flares instead (blood_feud) and false is returned.
	var index:=Hall._civ_index(civ_id)
	if index<0: return false
	if not Scale.formal(civ_id):
		blood_feud(civ_id,day,cause,ally)
		return false
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	if bool(relation.get("at_war",false)): _adopt(civ_id,day); return true
	relation["at_war"]=true; relation["treaty"]="war"; relation["stance"]="hostile"; relation["trade"]=0.0
	relation["contact_level"]=maxi(2,int(relation.get("contact_level",0)))
	relation["opinion"]=clampf(float(relation.get("opinion",0.0))-0.2,-1.0,1.0); relation["border_tension"]=maxf(0.8,float(relation.get("border_tension",0.0)))
	relation["war_goal"]="defend"; relation["war_target_region_id"]=""; relation["war_score"]=0.0; relation["conflict_turns"]=0
	relation["war_started_day"]=day; relation["last_war_result"]="ongoing"
	relation["war_id"]=String(world._start_war("player",civ_id,"defend","",day,"War over %s" % cause)) if world.has_method("_start_war") else ""
	civ["player_relation"]=relation
	world.civilizations[index]=civ
	var f:=front(civ_id)
	f["level"]=3
	f["last_harm"]=day
	var rng:=_rng("war:%s:%d" % [civ_id,day])
	f["war"]={"start":day,"war_id":String(relation.war_id),"cause":cause.substr(0,120),"our_dead":0,"their_dead":0,"our_exh":0.0,"their_exh":0.0,"score":0,
		"op":{},"objective":"","queued":"","next_enemy":day+rng.randi_range(25,70),"filed_day":day,"chief_held":false,"ally":ally,"terms":{},"terms_day":-1,"ops":0}
	_stat("wars")
	var name:=_name(civ_id)
	var text:="%s has come to war over %s. %s" % [name,cause,_strength_words(civ_id)]
	if ally!="": text="Your fighters go to stand with %s. %s is at war with us now. %s" % [_name(ally),name,_strength_words(civ_id)]
	var general:=_general()
	if not general.is_empty(): text+=" %s waits at the fire for your word." % EraNames.given_of(String(general.get("name","")))
	_chronicle("declared:%s:%d" % [civ_id,day],"War With %s" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"We went to war with the god's people over %s." % cause)
	_log(civ_id,"war",text,{"ally":ally})
	_mark_harm(civ_id,day)
	_file(civ_id,"war",text,day)
	return true

static func _adopt(civ_id:String,day:int)->void:
	## A war opened by other means (an invasion, an uprising, a declaration the
	## god sent): the general takes it up. Against a small people there is no
	## war to take up: the god's own band is out against them, and that is the
	## feud (_feud_from_attack).
	var f:=front(civ_id)
	if not (f.war as Dictionary).is_empty(): return
	if not Scale.formal(civ_id):
		_feud_from_attack(civ_id,day)
		return
	var relation:=_relation(civ_id)
	var rng:=_rng("adopt:%s:%d" % [civ_id,day])
	f["level"]=3
	f["war"]={"start":int(relation.get("war_started_day",day)),"war_id":String(relation.get("war_id","")),"cause":"the war","our_dead":0,"their_dead":0,"our_exh":0.0,"their_exh":0.0,"score":0,
		"op":{},"objective":"","queued":"","next_enemy":day+rng.randi_range(30,80),"filed_day":day,"chief_held":false,"ally":"","terms":{},"terms_day":-1,"ops":0}
	_stat("wars_adopted")
	_file(civ_id,"war","War with %s has begun. The war leader asks what you want done." % _name(civ_id),day)

static func _stand_with(ally:String,enemy:String)->void:
	if enemy=="" or enemy=="player" or Hall._civ_index(enemy)<0: return
	var day:=_day()
	# Kin, and a people that bows to us and pays for our protection.
	var kin:=not (_rivals().call("has_bond",ally,["marriage","ally","tributary"]) as Dictionary).is_empty()
	if kin and not _truce_binds(enemy,day) and not bool(_relation(enemy).get("at_war",false)):
		declare(enemy,day,"your fighters standing with %s" % _name(ally),ally)
		_stat("dragged_in")
	elif not kin and _rng("sided:%s:%s:%d" % [ally,enemy,day]).randf()<0.5 and int(_relation(enemy).get("contact_level",0))>=1:
		_schedule(enemy,day+_rng("sided_day:%s:%d" % [enemy,day]).randi_range(60,240),"sided","stand:"+ally)

static func stand_words(civ_id:String,enemy:String,name:String,enemy_name:String)->String:
	## The option text for standing with a people at war (or in a feud).
	var bond:Dictionary=_rivals().call("has_bond",civ_id,["marriage","ally","tributary"])
	var kin:=not bond.is_empty()
	if String(bond.get("kind",""))=="tributary":
		if enemy!="" and not Scale.formal(enemy): return "%s pays you tribute for this: your fighters go to protect them, and %s will count you in the feud and send raiders. Stay out and they will withhold their tribute." % [name,enemy_name]
		return "%s pays you tribute for this: your fighters go to their war, and %s will be at war with you. Stay out and they will withhold their tribute." % [name,enemy_name]
	if kin and enemy!="" and not Scale.formal(enemy): return "You are kin to %s: your fighters go to stand with them, and %s will count you in the feud and send raiders." % [name,enemy_name]
	if kin: return "You are kin to %s: your fighters go to their war, and %s will be at war with you." % [name,enemy_name]
	return "Warmer with %s; %s will count you an enemy's friend, and may send raiders." % [name,enemy_name]

# --------------------------------------------------------------------------
# Feuds: small peoples fight by raid and vengeance (conflict_scale.gd)
# --------------------------------------------------------------------------

static func formal(civ_id:String)->bool:
	return Scale.formal(civ_id)

## The front if it exists, never made by asking (nor the ledger itself).
static func _peek(civ_id:String)->Dictionary:
	var holder:Variant=ForeignDiplomacy.get("audiences")
	var s:Variant=(holder as Dictionary).get("war") if holder is Dictionary else null
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed): return {}
	var fronts:Variant=(s as Dictionary).get("fronts")
	var v:Variant=(fronts as Dictionary).get(civ_id) if fronts is Dictionary else null
	return v if v is Dictionary else {}

## Is fighting between this people and ours hot today? A war is; a feud is
## while blood was spilled either way within FEUD_HOT_DAYS, while their
## raiders are on the way, while a band of ours is out against them, or while
## the god's own band fights them (the engine's war flag). A hot people sends
## nobody into the hall but a rare peace-seeker (envoy_gate).
static func hot(civ_id:String,day:int=-1)->bool:
	if day<0: day=_day()
	if bool(_relation(civ_id).get("at_war",false)): return true
	if broken(civ_id): return false
	var f:=_peek(civ_id)
	if f.is_empty(): return false
	if not (f.get("war",{}) as Dictionary).is_empty(): return true
	if not (f.get("pending",{}) as Dictionary).is_empty() and not _truce_binds(civ_id,day): return true
	var op:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	if not op.is_empty() and String(op.get("objective",""))!="war_parley": return true
	if _bands_out(civ_id): return true
	return int(f.get("level",0))>=1 and day-int(f.get("last_harm",-99999))<FEUD_HOT_DAYS

## Is there a feud with this people (hot or simmering, not yet cold)?
static func feuding(civ_id:String,day:int=-1)->bool:
	if day<0: day=_day()
	if Scale.formal(civ_id) and bool(_relation(civ_id).get("at_war",false)): return false
	# A broken people keeps no feud (its end is told once, _end_broken).
	if broken(civ_id) and not bool(_relation(civ_id).get("at_war",false)): return false
	var f:=_peek(civ_id)
	if f.is_empty(): return bool(_relation(civ_id).get("at_war",false))
	if not (f.get("war",{}) as Dictionary).is_empty(): return false
	return int(f.get("level",0))>=1 or bool(_relation(civ_id).get("at_war",false))

## BROKEN PAST FEUDING: a people that has no town of its own left (burned,
## held by us or lost: envoy_aftermath.silenced) and fewer than BROKEN_PEOPLE
## living, or none at all. Its feud with us is over (_end_broken, told once),
## no raid of theirs comes, the hall hears nobody from them and the map shows
## its survivors, not a feud (survivors()).
static func broken(civ_id:String)->bool:
	var civ:=_civ(civ_id)
	if civ.is_empty(): return false
	if not bool(civ.get("alive",true)): return true
	if float(civ.get("population",0.0))>=BROKEN_PEOPLE: return false
	return bool(Hall._aftermath().call("silenced",civ_id))

## A broken people's survivors as the map and court tell them: {} when the
## people is not broken. {civ_id, name, living (whole people, 0 when none),
## where (their last town's name), position (Vector2), towns_lost [names]}.
static func survivors(civ_id:String)->Dictionary:
	if not broken(civ_id): return {}
	var civ:=_civ(civ_id)
	var st:Dictionary=Hall._aftermath().call("standing",civ_id)
	var lost:Array=[]
	for town:Dictionary in st.get("held",[]): lost.append(String(town.get("name","")))
	for town_name in st.get("burned",[]): if not String(town_name) in lost: lost.append(String(town_name))
	var where:=String(st.get("capital_name",""))
	if where=="" and not lost.is_empty(): where=String(lost[0])
	var home:Variant=(civ.get("player_relation",{}) as Dictionary).get("home_position",{})
	var position:=Vector2(float((home as Dictionary).get("x",0.0)),float((home as Dictionary).get("z",0.0))) if home is Dictionary else Vector2.ZERO
	var living:=roundi(float(civ.get("population",0.0))) if bool(civ.get("alive",true)) else 0
	return {"civ_id":civ_id,"name":_name(civ_id),"living":living,"where":where,"position":position,"towns_lost":lost}

## The feud with a people broken past fighting ends, told once: no town of
## theirs stands and only a few of them live, so nobody is left to raid us or
## to answer for it. Their raiders scheduled to come never come; the grudges
## stay (survivors remember).
static func _end_broken(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var name:=_name(civ_id)
	var left:=survivors(civ_id)
	var living:=int(left.get("living",0))
	var where:=String(left.get("where",""))
	var lost:=("%s is ash or ours, and " % where) if where!="" else ""
	var who:="nobody of them is left" if living<=0 else ("only %s of them %s, in the hills" % [EraWords.count_word(living),"lives" if living==1 else "live"])
	var text:="The feud with %s is over: %s%s. Nobody is left to raid us or to answer for it. In all, %d of ours and %d of theirs died in the feud." % [name,lost,who,int(f.get("our_dead",0)),int(f.get("their_dead",0))]
	f["level"]=0; f["pending"]={}; f["op"]={}
	f["feud_end"]={"day":day,"why":"broken"}
	f["guard_until"]=-1
	_chronicle("feud_broken:%s:%d" % [civ_id,day],"The Feud With %s Is Over" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"Our towns are gone and the god's people are no longer fought: %s." % ("nobody is left" if living<=0 else "a few of us live on in the hills"))
	_log(civ_id,"feud_end",text,{"why":"broken","living":living,"our_dead":int(f.get("our_dead",0)),"their_dead":int(f.get("their_dead",0))})
	_stat("feud_ends_broken")
	_drop_matters(civ_id)

## Days since blood was last spilled either way (99999 when never).
static func quiet_days(civ_id:String,day:int=-1)->int:
	if day<0: day=_day()
	var f:=_peek(civ_id)
	return day-int(f.get("last_harm",-99999)) if not f.is_empty() else 99999

## The feud as the court, the map and the tests read it: {} when there is
## none. {civ_id, name, hot, since, days, raids, strikes, our_dead,
## their_dead, last_harm, quiet, home_known, way, cause, open_fight}.
static func feud_view(civ_id:String,day:int=-1)->Dictionary:
	if day<0: day=_day()
	if not feuding(civ_id,day): return {}
	var f:=_peek(civ_id)
	var since:=int(f.get("feud_since",f.get("last_harm",day))) if not f.is_empty() else day
	if since<0: since=int(f.get("last_harm",day))
	var relation:=_relation(civ_id)
	if bool(relation.get("at_war",false)) and (f.is_empty() or int(f.get("level",0))<1): since=int(relation.get("war_started_day",day))
	return {"civ_id":civ_id,"name":_name(civ_id),"hot":hot(civ_id,day),"since":since,"days":maxi(0,day-since),"raids":int(f.get("raids",0)),"strikes":int(f.get("strikes",0)),
		"our_dead":int(f.get("our_dead",0)),"their_dead":int(f.get("their_dead",0)),"last_harm":int(f.get("last_harm",-1)),"quiet":quiet_days(civ_id,day),
		"home_known":home_known(civ_id),"way":_way_words(civ_id) if home_known(civ_id) else "","cause":String(f.get("cause","")),"open_fight":bool(relation.get("at_war",false)),
		"last_raid":(f.get("last_raid",{}) as Dictionary).duplicate() if f.get("last_raid") is Dictionary else {}}

## Every feud with a people we know, the hottest first.
static func feuds(day:int=-1)->Array[Dictionary]:
	if day<0: day=_day()
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or not bool((civ as Dictionary).get("alive",true)): continue
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player": continue
		var relation:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(relation.get("contact_level",0))<=0 and not bool(relation.get("at_war",false)): continue
		var view:=feud_view(id,day)
		if not view.is_empty(): out.append(view)
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.last_harm)>int(b.last_harm))
	return out

## "the killing of their envoy", "the tribute you would not pay": why they fight.
static func _feud_cause(civ_id:String)->String:
	var f:=_peek(civ_id)
	var cause:=String(f.get("cause",""))
	if cause!="": return cause
	var raid:Dictionary=f.get("last_raid",{}) if f.get("last_raid") is Dictionary else {}
	if not raid.is_empty(): return _cause_words(civ_id,String(raid.get("cause","")))
	return "old wrongs"

## A feud begins or flares: a killing, a war that cannot be (declare() between
## small peoples), kin standing together. Their raiders will come (a raid is
## scheduled unless one already is); nothing hostile of theirs waits to come
## to the hall; the war leader carries the matter. Returns what was told.
static func blood_feud(civ_id:String,day:int,cause:String,ally:String="",source:String="")->String:
	var index:=Hall._civ_index(civ_id)
	if index<0: return ""
	var f:=front(civ_id)
	var fresh:=int(f.level)<1 or int(f.get("feud_since",-1))<0 or day-int(f.last_harm)>FEUD_COLD_DAYS
	if fresh: _begin_feud(f,day)
	f["level"]=maxi(int(f.level),2)
	f["last_harm"]=maxi(int(f.last_harm),day)
	if cause!="": f["cause"]=cause.substr(0,120)
	f.erase("settled_until")
	Hall._shift_relation(civ_id,-0.12,0.2)
	var rng:=_rng("blood:%s:%d" % [civ_id,day])
	if (f.pending as Dictionary).is_empty(): _schedule(civ_id,day+rng.randi_range(20,90),"vengeance",source if source!="" else "blood")
	_purge_occasions(civ_id)
	var name:=_name(civ_id)
	var text:=""
	if ally!="": text="Your fighters go to stand with %s. %s counts you in its feud now, and its raiders will come for us too." % [_name(ally),name]
	else: text="%s will have vengeance for %s. Their raiders will come for blood, and every killing on either side will ask for another." % [name,cause]
	var general:=_general()
	if not general.is_empty(): text+=" %s waits at the fire for your word." % EraNames.given_of(String(general.get("name","")))
	_chronicle("feud:%s:%d" % [civ_id,day],"Blood Feud With %s" % name if fresh else "The Feud With %s Flares" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"We will have blood for %s." % cause if ally=="" else "The god's people stand with %s against us." % _name(ally))
	_log(civ_id,"feud",text,{"ally":ally,"fresh":fresh})
	_stat("blood_feuds" if fresh else "feud_flares")
	_mark_harm(civ_id,day)
	_file(civ_id,"feud",text,day)
	return text

## Their envoy was killed at our court (court_commands.gd). A small people
## answers with a blood feud at once; a people organised for war prepares for
## war (rival_rulers.gd). Returns true when the feud began.
static func envoy_slain(civ_id:String,envoy_name:String)->bool:
	if Scale.formal(civ_id): return false
	var who:=envoy_name.get_slice(" ",0) if envoy_name!="" else "their envoy"
	blood_feud(civ_id,_day(),"the killing of their envoy %s" % who,"","envoy")
	return true

## The god's own band is out against a small people (the engine's war flag):
## that is the feud, hot from today. Struck at home, they answer with raiders
## of their own unless the feud has worn them out.
static func _feud_from_attack(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	if int(f.level)<1 or int(f.get("feud_since",-1))<0 or day-int(f.last_harm)>FEUD_COLD_DAYS: _begin_feud(f,day)
	f["level"]=maxi(int(f.level),2)
	f["last_harm"]=maxi(int(f.last_harm),day)
	f["last_strike"]=day
	f["strikes"]=int(f.get("strikes",0))+1
	if String(f.get("cause",""))=="": f["cause"]="our attack on them"
	f.erase("settled_until")
	_purge_occasions(civ_id)
	var rng:=_rng("answer:%s:%d" % [civ_id,day])
	if (f.pending as Dictionary).is_empty() and float(f.get("their_exh",0.0))<ENEMY_SPENT and rng.randf()<0.5: _schedule(civ_id,day+rng.randi_range(20,120),"vengeance","attack")
	_stat("feuds_from_attack")

## Have our spears struck this people since that day (a band of ours at their
## stores, their chief or their raiders; the god's own attack)?
static func struck_since(civ_id:String,day:int)->bool:
	var f:=_peek(civ_id)
	if int(f.get("last_strike",-99999))>=day: return true
	for e in state().log:
		if e is Dictionary and String((e as Dictionary).get("civ",""))==civ_id and int((e as Dictionary).get("day",-1))>=day and String((e as Dictionary).get("kind","")) in ["op_burn","op_chief","op_pursue"]: return true
	return false

## Their business still waiting to come to the hall, gone: a people at feud
## brings no demands, boasts or gifts. Those who come to end it are kept.
static func _purge_occasions(civ_id:String)->void:
	var list:Array=Hall.state().occasions
	for occasion in list.duplicate():
		if not occasion is Dictionary or String((occasion as Dictionary).get("civ_id",""))!=civ_id: continue
		if String((occasion as Dictionary).get("type","")) in ["feud_peace","peace_possible"]: continue
		if String((occasion as Dictionary).get("type","")) in Hall.COURT_OCCASIONS: continue
		list.erase(occasion)

## Whether an envoy of this people may come, and with what business:
## "" (no fight between us: the hall's own business stands), "none" (a hot
## feud or war: nobody comes), or "peace" (only those who come to end it:
## allowed() then says which business).
static func envoy_gate(civ_id:String,day:int=-1)->String:
	if day<0: day=_day()
	if not hot(civ_id,day): return ""
	if not feuding(civ_id,day): return "peace"
	return "peace" if peace_due(civ_id,day) else "none"

## A feud's peace-seeker may come: the raids stopped PEACE_QUIET_DAYS ago,
## nobody of ours is out against them, and they are worn out, dread the god,
## or are beaten (towns lost, people taken).
static func peace_due(civ_id:String,day:int=-1)->bool:
	if day<0: day=_day()
	var f:=_peek(civ_id)
	if f.is_empty() or quiet_days(civ_id,day)<PEACE_QUIET_DAYS: return false
	var op:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	if not op.is_empty() and String(op.get("objective",""))!="war_parley": return false
	if _bands_out(civ_id): return false
	if not (f.get("pending",{}) as Dictionary).is_empty(): return false
	return float(f.get("their_exh",0.0))>=PEACE_WORN or _dread(civ_id)>=PEACE_DREAD or bool(Hall._aftermath().call("defeated",civ_id))

static func _dread(civ_id:String)->float:
	var lives:=Hall._lives()
	return float(lives.call("rival_dread",civ_id)) if lives!=null else 0.0

## The envoy business a hot conflict lets through (PEACE_TYPES), as weights.
static func peace_mix(civ_id:String,mix:Dictionary)->Dictionary:
	var out:={}
	var feud:=feuding(civ_id)
	for type in mix:
		if not String(type) in PEACE_TYPES: continue
		# A feud has no heralds under a sign of truce: its peace-seeker brings a
		# gift or a blood price (feud_peace).
		if feud and String(type)=="peace_feeler": continue
		out[type]=mix[type]
	if feud and peace_due(civ_id): out["feud_peace"]=maxf(1.0,float(out.get("feud_peace",0.0)))
	return out

## What their peace-seeker brings: Food for our dead (a blood price) or a gift
## to end it. {resource, amount, price(bool)}; {} when they have nothing.
static func peace_terms(civ_id:String)->Dictionary:
	var f:=_peek(civ_id)
	var dead:=int(f.get("our_dead",0))
	var want:=maxf(PRICE_MIN,float(dead)*PRICE_PER_DEAD)
	var have:=Hall.foreign_stock(civ_id,"Food")
	var amount:=Hall._nice(minf(want,have*0.4)) if have>=0.0 else Hall._nice(want)
	if have>=0.0 and have<PRICE_MIN: return {}
	return {"resource":"Food","amount":amount,"price":dead>0}

## A feud ends: a blood price, a parley that held, a peace-seeker heard, a
## marriage, a ransom. Grudges are settled in part; their raiders stay home
## for SETTLED_DAYS; the dead of the whole feud are told once.
static func _end_feud(civ_id:String,day:int,why:String,text:String)->void:
	var f:=front(civ_id)
	var name:=_name(civ_id)
	var told:="%s In all, %d of ours and %d of theirs died in the feud." % [text,int(f.get("our_dead",0)),int(f.get("their_dead",0))]
	f["level"]=0; f["pending"]={}
	f["settled_until"]=day+SETTLED_DAYS
	f["feud_end"]={"day":day,"why":why}
	f["guard_until"]=-1
	_peace_made(f)
	_rivals().call("settle_grudges",civ_id,0.6)
	# The peace sets down the whole feud's wrongs, not only the heaviest: an
	# old killing of theirs does not start the feud again the day after
	# (rival_rulers._war_preparation). What they suffered is still told
	# (deeds.gd); a price paid or a marriage eases it.
	_rivals().call("settle_wrongs_before",civ_id,day)
	if why in ["blood price","marriage"]: preload("res://scripts/deeds.gd").amends(civ_id,"the %s that ended the feud" % why)
	Hall._shift_relation(civ_id,0.08,-0.2)
	_chronicle("feud_end:%s:%d" % [civ_id,day],"The Feud With %s Is Settled" % name,told,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"The feud with the god's people is settled: %s." % why)
	_log(civ_id,"feud_end",told,{"why":why,"our_dead":int(f.get("our_dead",0)),"their_dead":int(f.get("their_dead",0))})
	_stat("feud_ends_"+why.replace(" ","_"))
	_drop_matters(civ_id)

## No blood either way for FEUD_COLD_DAYS: the feud goes cold. Nobody made
## peace and nobody forgot (the grudges stay, and can send raiders again).
static func _feud_cold(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var name:=_name(civ_id)
	f["level"]=0
	f["cold_day"]=day
	var winters:=maxi(1,roundi(float(day-int(f.last_harm))/365.0))
	var text:="Neither side has spilled blood for %s %s. The feud with %s has gone cold. Nobody made peace, and nobody has forgotten: %d of ours and %d of theirs died in it." % [EraWords.count_word(winters),"winter" if winters==1 else "winters",name,int(f.get("our_dead",0)),int(f.get("their_dead",0))]
	_chronicle("feud_cold:%s:%d" % [civ_id,day],"The Feud With %s Goes Cold" % name,text,"notice",civ_id)
	_log(civ_id,"feud_cold",text,{"our_dead":int(f.get("our_dead",0)),"their_dead":int(f.get("their_dead",0))})
	_stat("feuds_cold")
	_drop_matters(civ_id)

## The blood price we would pay them: Food for each life of theirs we took in
## the feud (never less than PRICE_MIN).
static func blood_price(civ_id:String)->float:
	var f:=_peek(civ_id)
	return Hall._nice(maxf(PRICE_MIN,float(int(f.get("their_dead",0)))*PRICE_PER_DEAD))

## Now and then a worn-out or frightened people at feud sends someone to end
## it (feud_peace), never while the raids go on, at most once a year.
static func _peace_seeker(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	if day-int(f.get("peace_asked",-99999))<PEACE_GAP or not peace_due(civ_id,day): return
	if Hall.foreign_stock(civ_id,"Food")>=0.0 and peace_terms(civ_id).is_empty(): return
	var chance:=0.012+float(f.get("their_exh",0.0))*0.02+_dread(civ_id)*0.02
	if _rng("peace_seek:%s:%d" % [civ_id,day]).randf()>=chance: return
	f["peace_asked"]=day
	Hall._add_occasion({"key":"feud_peace:%s:%d" % [civ_id,day],"type":"feud_peace","civ_id":civ_id,"day":day,"not_before":day,"expires":day+90,"crisis":true,
		"data":{"text":"they come to end the feud"}})
	_stat("peace_seekers")

## The god's answer to their peace-seeker (audience_hall feud_peace).
static func _peace_answered(audience:Dictionary,option_id:String)->void:
	var civ_id:=String(audience.get("civ_id",""))
	var day:=_day()
	var name:=_name(civ_id)
	if option_id in ["accept","accept_return"]:
		var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
		_end_feud(civ_id,day,"peace sought","%s sent %s to end the feud, and you took it. Their raiders will not come for it." % [name,Hall._terms_text(terms)])
		return
	if option_id in ["refuse","decline"]:
		var f:=front(civ_id)
		f["peace_asked"]=day
		_rivals().call("grudge",civ_id,"how you turned away our peace",0.25,"peace_refused:%d" % day)
		_log(civ_id,"peace_refused","%s's peace was turned away; the feud goes on." % name)

static func _objective_for_general(civ_id:String,general:Dictionary,at_war:bool)->String:
	## What the war leader does without the god's word, by their own character.
	var courage:=float(general.get("courage",0.5))
	var p:Dictionary=general.get("personality",{}) if general.get("personality") is Dictionary else {}
	var care:=float(p.get("empathy",0.5))
	var r:=ratio(civ_id)
	var war:Dictionary=front(civ_id).get("war",{})
	if at_war:
		if float(war.get("our_exh",0.0))>0.45 and care>0.5: return "war_parley"
		# A bold leader strikes their stores, but only a home we can find.
		if r<0.85 and courage>0.55: return "war_burn" if home_known(civ_id) else "war_track"
		if r<0.7 and courage>0.75: return "war_chief"
		return "war_guard"
	if r<1.1 and courage>0.55: return "war_pursue"
	if care>0.65: return "war_parley"
	return "war_guard"

## Do we know where this people lives? (The same flag the map and the court's
## "their home not yet found" read.)
static func home_known(civ_id:String)->bool:
	return bool(_relation(civ_id).get("home_location_known",false))

## Our home and theirs on the world plane, and the km between (40 when the
## world cannot say).
static func _homes(civ_id:String)->Dictionary:
	var world=WorldSimulation.world
	var civ:=_civ(civ_id)
	if world==null or civ.is_empty() or not world.has_method("_civilization_world_position"): return {"here":Vector2.ZERO,"there":Vector2(40,0),"km":40.0}
	var there:Vector2=world._civilization_world_position(civ)
	var here:Vector2=world.player_world_origin
	return {"here":here,"there":there,"km":maxf(1.0,here.distance_to(there))}

## The chance a tracking party finds their home: the farther, the colder the
## trail; a skilled war leader reads it better. Stated in the order, rolled on
## the op's own seed.
static func track_chance(civ_id:String,skill:float)->float:
	return clampf(0.85-float(_homes(civ_id).km)/250.0+(skill-0.5)*0.3,0.15,0.9)

static func _track_odds_words(chance:float)->String:
	if chance>=0.7: return "The trail is fresh; they should find it."
	if chance>=0.45: return "They may find it or lose the trail."
	return "It is far and the trail is old; they may not find it."

## "3 days' walk west": how far their home lies from ours.
static func _way_words(civ_id:String)->String:
	var homes:=_homes(civ_id)
	var d:Vector2=(homes.there as Vector2)-(homes.here as Vector2)
	if d.length()<0.5: return ""
	var days:=maxi(1,ceili(float(homes.km)/18.0))
	var dir:String=["east","southeast","south","southwest","west","northwest","north","northeast"][posmod(roundi(rad_to_deg(d.angle())/45.0),8)]
	return ("a day's walk %s" % dir) if days==1 else ("%d days' walk %s" % [days,dir])

## Their home is found: on our chart (city_intelligence, which sets the
## relation's home_location_known for their chief town) and, where no town is
## charted, on the relation itself with the land around it revealed. Returns
## where it lies ("3 days' walk west").
static func _find_home(civ_id:String,day:int,source:String,reference:String)->String:
	var world=WorldSimulation.world
	var civ:=_civ(civ_id)
	if world==null or civ.is_empty(): return ""
	var chart=world.get("city_intelligence")
	var home_id:=String(chart.primary_id(civ_id)) if chart!=null else ""
	if home_id!="": chart.publish("player",chart.capture("player",home_id,0.55,day,source,"war:"+reference),day)
	var relation:=_relation(civ_id)
	if not bool(relation.get("home_location_known",false)):
		var there:Vector2=_homes(civ_id).there
		relation["home_location_known"]=true; relation["home_position"]={"x":there.x,"z":there.y}
		relation["home_location_source"]=source; relation["last_observed_day"]=day
		if world.has_method("_add_revealed_area"): world._add_revealed_area(there,72.0,"foreign settlement observed")
	return _way_words(civ_id)

## A band of ours has been to their home already (a raid on their stores or a
## strike at their chief, from before the way had to be known): it knows the
## way, so the map shows it. Their raiders who came to us (THEIR_VISITS) and
## their envoys who stood in our hall (audience_hall.gd ledger) showed the
## way too (came_to_us). Once per people.
static func _knows_the_way_from_before(civ_id:String,day:int)->void:
	if home_known(civ_id): return
	for entry in state().log:
		if not entry is Dictionary or String((entry as Dictionary).get("civ",""))!=civ_id: continue
		var kind:=String((entry as Dictionary).get("kind",""))
		if kind in THEIR_VISITS:
			came_to_us(civ_id,day,"raiders")
			return
		if not kind in ["op_burn","op_chief"]: continue
		var name:=_name(civ_id)
		var way:=_find_home(civ_id,day,"a band that went there","struck:"+civ_id)
		_chronicle("way:%s" % civ_id,"The Way to %s" % name,"Our band that went to %s's home knows the way there%s. It is on our map now." % [name,(", "+way) if way!="" else ""],"notice",civ_id)
		return

## Every people whose envoy the hall's ledger remembers (audience_hall.gd),
## whose home we still do not know: came_to_us, once each.
static func _envoys_from_before(day:int)->void:
	var hall:=load("res://scripts/audience_hall.gd") as GDScript
	if hall==null: return
	for entry in (hall.call("state") as Dictionary).get("ledger",[]):
		if not entry is Dictionary: continue
		var key:=String((entry as Dictionary).get("speaker",""))
		if key.begins_with("civ:"): came_to_us(key.trim_prefix("civ:"),day,"envoy")

## The war ledger's kinds for their raiders reaching us (_raid, by the land
## road or at once).
const THEIR_VISITS:=["raid","skirmish","ambush","raid_called","seen_coming"]

## They came to us, so we know the way to them: whoever reaches our town
## (their envoy, their raiders) comes from somewhere and goes home by a road
## our people can follow. Every people learns the other's home by the same
## rule; their councils already chart ours before they send anyone. `how`
## is "envoy" or "raiders". Once per people; nothing when already known.
static func came_to_us(civ_id:String,day:int,how:String)->void:
	if civ_id=="" or home_known(civ_id) or _civ(civ_id).is_empty(): return
	var name:=_name(civ_id)
	var source:="their envoy's road home" if how=="envoy" else "their raiders' trail home"
	var way:=_find_home(civ_id,day,source,"came:%s:%s" % [how,civ_id])
	var who:="Their envoy came to us and went home by the road" if how=="envoy" else "Their raiders came to us and left a trail home"
	_chronicle("way:%s" % civ_id,"The Way to %s" % name,"%s. Our people followed it: %s live%s. It is on our map now." % [who,name,(" "+way) if way!="" else ""],"notice",civ_id)

static func _march_days(civ_id:String,rng:RandomNumberGenerator)->int:
	var civ:=_civ(civ_id)
	var world:=WorldSimulation.world
	var km:=40.0
	if world.has_method("_civilization_world_position") and GameState.settlement_site_committed:
		var there:Vector2=world._civilization_world_position(civ)
		var here:Vector2=world.player_world_origin
		km=maxf(5.0,here.distance_to(there))
	return clampi(ceili(km/18.0)+rng.randi_range(1,4),3,30)

## The god's word on a people (a court matter's choice, the War screen's
## blood price): the old objectives are the war council's stances now
## (war_council.gd), carried out with the real army.
##   war_guard            Defend      war_burn, war_pursue  Punish
##   war_chief            Take their chief town              war_parley  Seek peace
##   war_let              Leave them be                       war_general the war
##                        leader's own judgment (no stance: he defends)
## war_track sends trackers, war_price and war_pay settle at once.
static func order(civ_id:String,objective:String,auto:bool=false)->String:
	var day:=_day()
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var at_war:=not war.is_empty()
	var general:=_general()
	var gname:=EraNames.given_of(String(general.get("name","The war leader"))) if not general.is_empty() else "The war leader"
	var name:=_name(civ_id)
	if objective=="war_rest": objective="war_guard" if at_war else "war_let"
	_stat("orders_auto" if auto else "orders")
	match objective:
		"war_track":
			if home_known(civ_id):
				var where:=_way_words(civ_id)
				return "We know where %s live already%s. Say what you want done there." % [name,(": "+where) if where!="" else ""]
			return send_trackers(civ_id)
		"war_pay":
			var terms:Dictionary=war.get("terms",{})
			var paid:=Hall._debit_player("Food",float(terms.get("amount",0.0)))
			if paid>0.0: Hall._credit_civ(civ_id,"Food",paid)
			_close_war(civ_id,day,"tribute paid","You paid %d Food. %s's fighters went home." % [roundi(paid),name])
			return "You paid %d Food to %s, and the war is over." % [roundi(paid),name]
		"war_price":
			# A blood price ends a feud; a war ends only on its own terms.
			if at_war: return "This is a war. Only their terms, a truce or their exhaustion end it."
			var price:=blood_price(civ_id)
			var short:=Hall._short("Food",price)
			if short!="": return "%s The blood price for %s's dead is %d Food." % [short,name,roundi(price)]
			var paid2:=Hall._debit_player("Food",price)
			if paid2>0.0: Hall._credit_civ(civ_id,"Food",paid2)
			var dead:=int(f.get("their_dead",0))
			_end_feud(civ_id,day,"blood price","You sent %d Food to %s as a blood price%s. The blood between us is paid, and their raiders will not come for it." % [roundi(paid2),name,(" for the %d of theirs we killed" % dead) if dead>0 else ""])
			_log(civ_id,"order","price",{"auto":auto,"paid":roundi(paid2)})
			# The feud is settled: nothing more goes out against them.
			f["stance"]="leave"
			return "%s carries %d Food to %s as a blood price. The feud is settled; their raiders will not come for it." % [gname,roundi(paid2),name]
		"war_general":
			# The war leader's own judgment: no stance from the god, so he holds
			# the approaches (war_council.stance_of) until told otherwise.
			var held:Dictionary=_council().call("order",civ_id,"defend",{})
			f.erase("stance")
			_log(civ_id,"order","general",{"auto":auto})
			return "%s will see to it as he judges. %s" % [gname,String(held.get("says",""))]
	var stance:=String({"war_guard":"defend","war_burn":"punish","war_pursue":"punish","war_chief":"punish","war_parley":"peace","war_let":"leave"}.get(objective,""))
	if stance=="": return "%s does not know what you want done." % gname
	var options:={"asked":objective}
	# Their chief sits in their chief town: a band that beats its defenders
	# brings him (_chief_seized); it holds no town.
	if objective=="war_chief":
		var chart=WorldSimulation.world.get("city_intelligence") if WorldSimulation.world!=null else null
		var chief_town:=String(chart.primary_id(civ_id)) if chart!=null else ""
		if chief_town=="" or chart.known("player",chief_town).is_empty():
			return "%s does not know which town %s's chief sits in. Scouts must find it first." % [gname,name]
		options["place"]={"city_id":chief_town,"name":String(chart.known("player",chief_town).get("name",""))}
		f["chief_at"]={"city_id":chief_town,"day":day}
	var done:Dictionary=_council().call("order",civ_id,stance,options)
	_log(civ_id,"order",objective,{"auto":auto,"stance":stance})
	if at_war:
		war["objective"]=objective
		war["ordered_day"]=day
	return String(done.get("says",done.get("outcome","")))

static func _council()->GDScript:
	return load(COUNCIL_PATH) as GDScript

## A few trackers follow their raiders' trail to find where they live (the
## war council's first step when nobody knows the way). Their odds are stated;
## the roll is the op's own when they come back (_resolve_op). Said once, in
## plain words: why the trackers go first, what they do, their odds, and what
## follows. The band goes when the way is found only while the stance toward
## them sends one (war_council.gd: Punish or Take a town); otherwise the found
## home goes on the map and the god gives the word.
static func send_trackers(civ_id:String,asked:String="")->String:
	var day:=_day()
	var f:=front(civ_id)
	var general:=_general()
	var gname:=EraNames.given_of(String(general.get("name","The war leader"))) if not general.is_empty() else "The war leader"
	var name:=_name(civ_id)
	var war:Dictionary=f.get("war",{})
	var out_now:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	if out_now.is_empty() and war.get("op") is Dictionary: out_now=war.op
	if not out_now.is_empty():
		return "%s is already out against %s; the trackers wait for them." % [String(out_now.get("general",gname)),name]
	var rng:=_rng("order:%s:war_track:%d" % [civ_id,day])
	var band:=clampi(_band_size(_our_pop(),0.02),TRACKERS_MIN,TRACKERS_MAX)
	var due:=day+_march_days(civ_id,rng)
	var op:={"objective":"war_track","start":day,"due":due,"band":band,"general_pid":int(general.get("person_id",0)),"general":gname,"auto":false}
	if not war.is_empty(): war["op"]=op
	else: f["op"]=op
	_log(civ_id,"order","war_track",{"band":band,"due":due})
	var people:=name if name.to_lower().begins_with("the ") else "the "+name
	var why:="their chief is out of reach for now" if asked=="war_chief" else "there is nothing of theirs to strike at yet"
	var odds:=_track_odds_words(track_chance(civ_id,_general_skill(general)))
	var next:="When the way is found, the war band goes." if String(f.get("stance","")) in ["punish","take"] else "When they find it, it goes on our map, and the war band waits for your word."
	return "Nobody here knows where %s live, so %s. %s takes %d to follow %s raiders' trail and find where they live. %s They should be back in about %d days. %s" % [people,why,gname,band,people,odds,due-day,next]

## Two messengers go to ask for an end to it (the war council's Seek peace).
## A truce or the feud's end is rolled when they come back (_resolve_op).
static func send_messengers(civ_id:String)->String:
	var day:=_day()
	var f:=front(civ_id)
	var general:=_general()
	var gname:=EraNames.given_of(String(general.get("name","The war leader"))) if not general.is_empty() else "The war leader"
	var rng:=_rng("order:%s:war_parley:%d" % [civ_id,day])
	var due:=day+_march_days(civ_id,rng)
	var op:={"objective":"war_parley","start":day,"due":due,"band":2,"general_pid":int(general.get("person_id",0)),"general":gname,"auto":false}
	var war:Dictionary=f.get("war",{})
	if not war.is_empty(): war["op"]=op
	else: f["op"]=op
	_log(civ_id,"order","war_parley",{"band":2,"due":due})
	return "%s sends two messengers to %s to ask for an end to it. They should be back in %d days." % [gname,_name(civ_id),due-day]

## Leave them be: the dead are buried and their grudge cools, unless they
## are the kind to come back bolder.
static func let_be(civ_id:String)->String:
	var day:=_day()
	var rng:=_rng("order:%s:war_let:%d" % [civ_id,day])
	_log(civ_id,"order","let",{})
	_rivals().call("settle_grudges",civ_id,0.3)
	if String(_rival(civ_id).get("trait","")) in ["hunter","bluffer","grudge"] and rng.randf()<0.35:
		_schedule(civ_id,day+rng.randi_range(120,330),"grudge","bolder")
	return "The dead are buried. No one goes after %s this year; their raids are met at home." % _name(civ_id)

static func _resolve_op(civ_id:String,op:Dictionary,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var at_war:=not war.is_empty()
	var name:=_name(civ_id)
	var objective:=String(op.get("objective",""))
	var gname:=String(op.get("general","The war leader"))
	var key:="op:%s:%s:%d" % [civ_id,objective,int(op.get("start",day))]
	var rng:=_rng(key)
	_stat("ops")
	if at_war: war["ops"]=int(war.get("ops",0))+1
	if objective=="war_parley":
		if not at_war and int(f.get("level",0))<=0:
			# The feud was set down while they were on the road: peace holds,
			# and there is nothing more to settle or tell.
			_peace_made(f)
			_log(civ_id,"parley_ok","nothing left to settle")
			return
		var rival:=_rival(civ_id)
		var accept:=0.25+(float(war.get("their_exh",0.0))*0.9 if at_war else 0.35)+float(war.get("score",0))*0.06-float(rival.get("grudge_weight",0.0))*0.12-(0.15 if String(rival.get("trait",""))=="grudge" else 0.0)+float(rival.get("dread",0.0))*0.2
		if rng.randf()<clampf(accept,0.05,0.9):
			if at_war: _close_war(civ_id,day,"truce","The messengers came back with a truce. %s's fighters are going home." % name)
			elif int(f.level)>=2 or int(f.get("our_dead",0))+int(f.get("their_dead",0))>0:
				# Blood was spilled: word that holds ends the feud itself.
				_end_feud(civ_id,day,"parley","%s's messengers came back: %s will send no more raiders, and the feud is set down." % [gname,name])
			else:
				f["level"]=maxi(0,int(f.level)-1); f["pending"]={}
				_rivals().call("settle_grudges",civ_id,0.5)
				_peace_made(f)
				_chronicle(key,"Words With %s" % name,"%s's messengers came back: %s will send no more raiders. The matter is closed." % [gname,name],"notice",civ_id)
			_log(civ_id,"parley_ok","accepted")
		else:
			var refusal:="%s's messengers came back with nothing. %s will not hear of it." % [gname,name]
			_chronicle(key,"%s Will Not Talk" % name,refusal,"notice",civ_id)
			_log(civ_id,"parley_refused",refusal)
			if at_war: _file(civ_id,"report",refusal,day)
		return
	if objective=="war_track":
		var tracker:=Hall._official(int(op.get("general_pid",0)))
		if tracker.is_empty(): tracker=_general()
		var chance:=track_chance(civ_id,_general_skill(tracker))
		var found:=rng.randf()<chance
		var said:=""
		if found:
			var way:=_find_home(civ_id,day,"trail followed by %s" % gname,key)
			said="%s's trackers followed %s's raiders' trail%s to their home. It is on our map now." % [gname,name,(" "+way) if way!="" else ""]
		else:
			said="%s's trackers lost %s's raiders' trail and came back. Where they live is still not known." % [gname,name]
		_chronicle(key,("%s's Home Found" % name) if found else "The Trail Went Cold",said,"notice",civ_id)
		_log(civ_id,"op_track",said,{"found":found,"chance":snappedf(chance,0.01)})
		if at_war: _file(civ_id,"report",said,day)
		return
	# A band of the old reckoning out on a save from before the war council
	# (pursue, burn, their chief): it had no men of our army in it, so it
	# comes home without a fight, told once. The council's real bands do this
	# work now (war_council.gd).
	_log(civ_id,"op_dropped","%s's band came back from %s without a fight: the war council sends the real bands now." % [gname,name],{"objective":objective})
	_stat("ops_dropped")

## A band of ours sent for their chief ("Bring me their chief": war_chief)
## beat the defenders of their chief town: their chief is taken.
static func _chief_seized(civ_id:String,r:Dictionary,when:int,place:String)->void:
	var f:=front(civ_id)
	var at:Dictionary=f.get("chief_at",{}) if f.get("chief_at") is Dictionary else {}
	if at.is_empty(): return
	if when-int(at.get("day",when))>CHIEF_DAYS:
		f.erase("chief_at")
		return
	var threat:Dictionary=r.get("threat",{}) if r.get("threat") is Dictionary else {}
	var target:=String(r.get("target_region_id",threat.get("target_region_id","")))
	if target!=String(at.get("city_id","")) or when<int(at.get("day",0)): return
	f.erase("chief_at")
	chief_taken(civ_id,place if place!="" else "their chief town",when)

## Their chief taken at his own town by a band of ours. At war they ransom him
## and ask for peace (_check_end); in a feud they ransom him and swear off it.
## Either way nothing more goes out against them.
static func chief_taken(civ_id:String,town:String,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var name:=_name(civ_id)
	f["stance"]="leave"
	if not war.is_empty():
		war["chief_held"]=true
		_log(civ_id,"chief_taken","Our band beat the defenders of %s and took %s's chief." % [town,name])
		return
	if not feuding(civ_id): return
	var ransom:=EXCHANGE.take(civ_id,"Food",maxf(10.0,Hall.foreign_stock(civ_id,"Food")*0.25))
	if ransom>0.0: EXCHANGE.receive("player","Food",ransom)
	_log(civ_id,"chief_taken","Our band beat the defenders of %s and took %s's chief; ransomed for %d Food." % [town,name,roundi(ransom)])
	_end_feud(civ_id,day,"chief ransomed","Our band beat the defenders of %s and took %s's chief. They ransomed him for %d Food and swore off the feud." % [town,name,roundi(ransom)])

static func _check_end(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.war
	var name:=_name(civ_id)
	var ours:=float(war.get("our_exh",0.0)); var theirs:=float(war.get("their_exh",0.0))
	var score:=int(war.get("score",0))
	var length:=day-int(war.get("start",day))
	if bool(war.get("chief_held",false)):
		var ransom:=EXCHANGE.take(civ_id,"Food",maxf(10.0,Hall.foreign_stock(civ_id,"Food")*0.25))
		if ransom>0.0: EXCHANGE.receive("player","Food",ransom)
		_close_war(civ_id,day,"tribute received","%s ransomed its chief for %d Food and asked for peace." % [name,roundi(ransom)])
		return
	if theirs>=0.6 or (theirs>=0.4 and score>=2):
		var tribute:=EXCHANGE.take(civ_id,"Food",maxf(8.0,Hall.foreign_stock(civ_id,"Food")*0.15))
		if tribute>0.0: EXCHANGE.receive("player","Food",tribute)
		_close_war(civ_id,day,"tribute received","%s has had enough. Its herald brought %d Food and asked for peace." % [name,roundi(tribute)])
		return
	if (ours>=0.6 or (ours>=0.4 and score<=-2)) and (war.terms as Dictionary).is_empty():
		var amount:=Hall._nice(maxf(10.0,Hall.player_stock("Food")*0.2))
		war["terms"]={"resource":"Food","amount":amount}
		war["terms_day"]=day
		var text:="%s's herald came to the edge of the camp: pay %d Food and the fighting stops." % [name,roundi(amount)]
		_chronicle("terms:%s:%d" % [civ_id,day],"%s Names Its Price" % name,text,"notice",civ_id)
		_file(civ_id,"terms",text,day)
		return
	if not (war.terms as Dictionary).is_empty() and day-int(war.get("terms_day",day))>=TERMS_WAIT and (war.op as Dictionary).is_empty() and not _bands_out(civ_id):
		_close_war(civ_id,day,"exhaustion","No one answered %s's herald. Our people stopped going out to fight, and so did theirs." % name)
		return
	# A handful of fighters on each side cannot keep a war alive with no one
	# fighting: after a quiet year with no band out, the feud goes quiet.
	if day-int(war.get("last_fight",war.get("start",day)))>=QUIET_DAYS and (war.op as Dictionary).is_empty() and not _bands_out(civ_id):
		_close_war(civ_id,day,"quiet","Neither side has sent fighters for a year. The feud has gone quiet.")
		return
	if (length>=int(2.5*365) and ours>=0.3 and theirs>=0.3) or length>=4*365:
		_close_war(civ_id,day,"exhaustion","After %d winters of it, neither side sends fighters any more. No one made peace; the war just stopped." % maxi(1,roundi(length/365.0)))

static func _close_war(civ_id:String,day:int,result:String,text:String)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var index:=Hall._civ_index(civ_id)
	var world:=WorldSimulation.world
	if index>=0:
		var civ:Dictionary=world.civilizations[index]
		var relation:Dictionary=civ.player_relation
		if bool(relation.get("at_war",false)):
			relation["at_war"]=false; relation["treaty"]="truce"; relation["stance"]="watchful"; relation["border_tension"]=0.35
			relation["truce_until_day"]=day+TRUCE_DAYS; relation["last_war_result"]=result
			if world.has_method("_end_war"): world._end_war(String(relation.get("war_id",war.get("war_id",""))),day,result)
			if world.has_method("_remove_pending_player_incidents"): world._remove_pending_player_incidents(civ_id)
			civ["player_relation"]=relation
			world.civilizations[index]=civ
	var name:=_name(civ_id)
	var told:="%s In all, %d of ours and %d of theirs died in it." % [text,int(war.get("our_dead",0)),int(war.get("their_dead",0))]
	_chronicle("peace:%s:%d" % [civ_id,day],"The War With %s Is Over" % name,told,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"The war with the god's people ended: %s." % result)
	_rivals().call("settle_grudges",civ_id,0.6)
	if result=="tribute received": _rivals().call("grudge",civ_id,"the war you made us pay for",0.35,"lost_war:%d" % day)
	_stat("ends_"+result.replace(" ","_"))
	_log(civ_id,"war_end",told,{"result":result,"our_dead":int(war.get("our_dead",0)),"their_dead":int(war.get("their_dead",0)),"days":day-int(war.get("start",day))})
	f["war"]={}; f["pending"]={}; f["level"]=1; f["last_war_end"]=day; f["guard_until"]=-1; f["op"]={}
	_peace_made(f)
	_drop_matters(civ_id)

## Peace is made with them (a truce, the feud set down, the matter closed):
## the god's word to seek peace, to punish them or to take a town of theirs
## has done its work and is set down, so the war leader sends no more
## messengers or raiders for it (a punishing band left standing would start
## the feud again the day after the peace). A word to defend stays.
static func _peace_made(f:Dictionary)->void:
	if String(f.get("stance","")) in ["peace","punish","take"]: f.erase("stance")
	f.erase("punish_at")

# --------------------------------------------------------------------------
# Daily
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player" or not GameState.settlement_site_committed or day%TICK!=0: return
	# The authored General Campaign runs its own war; leave it alone.
	if WorldSimulation.system("GeneralCampaign")!=null and bool(WorldSimulation.campaign.active): return
	var s:=state()
	# Envoys who stood in our hall before the rule showed us the way home too.
	_envoys_from_before(day)
	# The real fights since the last look (ours and, in a world of simulated
	# peoples, theirs against us) go into the feud's and the war's ledger.
	from_battles(day)
	# A small people found "at war" fights on as a feud once no band of ours is
	# out against it (an older save, a war opened before the rule).
	reconcile(day)
	# Wars opened by other means are taken up by the war leader; the god's own
	# attack on a small people is the feud, hot from the day it began.
	for civ in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if not bool(relation.get("at_war",false)) or not bool(civ.get("alive",true)) or bool(civ.get("general_campaign_owned",false)) or int(relation.get("contact_level",0))<1: continue
		var cid:=String(civ.id)
		if Scale.formal(cid):
			if (front(cid).war as Dictionary).is_empty(): _adopt(cid,day)
		else: _open_fight(cid,relation,day)
	for civ_id in (s.fronts as Dictionary).keys():
		var id:=String(civ_id)
		var f:=front(id)
		var civ:=_civ(id)
		# Nobody left to fight: the feud ends, told once (no town of theirs
		# stands and only a handful live, or none).
		if not civ.is_empty() and int(f.get("level",0))>=1 and (f.war as Dictionary).is_empty() and not bool(_relation(id).get("at_war",false)) and broken(id):
			_end_broken(id,day)
			continue
		if civ.is_empty() or not bool(civ.get("alive",true)):
			if not (f.war as Dictionary).is_empty(): f["war"]={}
			continue
		_knows_the_way_from_before(id,day)
		var war:Dictionary=f.war
		if war.is_empty():
			var pending:Dictionary=f.pending
			_forewarn(id,f,day)
			if not pending.is_empty() and day>=int(pending.get("day",day)): _execute(id,day)
			var op:Dictionary=f.get("op",{})
			if not op.is_empty() and day>=int(op.get("due",day)):
				f["op"]={}
				_resolve_op(id,op,day)
			_feud_day(id,day)
			continue
		if not bool(_relation(id).get("at_war",false)):
			_close_war(id,day,"truce","%s and your people have made peace." % _name(id))
			continue
		# The trackers or messengers out in the war (the war council's small
		# parties) come back. Our bands and their host are the real army's
		# (war_council.gd, MilitaryCampaign): nothing here fights for either.
		var op2:Dictionary=war.get("op",{})
		if not op2.is_empty() and day>=int(op2.get("due",day)):
			war["op"]={}
			_resolve_op(id,op2,day)
			if (front(id).war as Dictionary).is_empty(): continue
		if not (front(id).war as Dictionary).is_empty(): _check_end(id,day)
	if day%30==0:
		# What is told of us: towns taken or burned, captives driven off (deeds.gd).
		preload("res://scripts/deeds.gd").monthly(day)
		# Who stands together against us, before anyone moves.
		preload("res://scripts/fear_league.gd").monthly(day)
		# What each people does about us: bow, or come with everything.
		(load("res://scripts/world_answer.gd") as GDScript).call("monthly",day)
		_grudges(day)
		_rival_wars(day)
	# Feuds between two other simulated peoples are fought for real.
	preload("res://scripts/rival_feuds.gd").tick(day,TICK)

## Battles already counted into the ledger (by record), the newest kept.
const BATTLES_SEEN_MAX:=80
## A battle older than this when first looked at is history, not news.
const BATTLES_LOOK_DAYS:=60

## THE ONE LEDGER FROM THE REAL FIGHTS. Every battle our army fought against
## a people (MilitaryCampaign.battle_history: our bands' raids, sieges and
## assaults, our watch against their raiders, our band meeting theirs in the
## field) and, in a world of simulated peoples, every battle their army
## fought against ours (their own records: we are "human" there), is counted
## once into the feud's or the war's ledger: the dead on each side, who
## struck, the heat, the exhaustion and their answer. The raids already
## counted where they were fought (_raid) carry their own mark and are passed.
static func from_battles(day:int)->void:
	var s:=state()
	var seen:Dictionary=s.get("battles_seen",{}) if s.get("battles_seen") is Dictionary else {}
	var mc:Variant=WorldSimulation.military
	if mc!=null:
		for record in mc.battle_history:
			if not record is Dictionary: continue
			var r:Dictionary=record
			if day-int(r.get("day",-99999))>BATTLES_LOOK_DAYS: break
			var threat:Dictionary=r.get("threat",{}) if r.get("threat") is Dictionary else {}
			if String(threat.get("war_loop",""))!="": continue
			var civ_id:=String(threat.get("source_civ_id",""))
			# Their side of a fight in their world, told back to ours: counted
			# from their own record below.
			if civ_id in ["","human","player"]: continue
			var key:="ours:%d:%d" % [int(r.get("seed",0)),int(r.get("day",0))]
			if seen.has(key): continue
			seen[key]=day
			_count_battle(civ_id,r,String(r.get("home_side","attacker")),day,false)
	if WorldSimulation.enabled:
		for id in WorldSimulation.actors.keys():
			var systems:Dictionary=WorldSimulation.actors[id].get("systems",{})
			var theirs:Variant=systems.get("MilitaryCampaign")
			if theirs==null: continue
			for record in theirs.battle_history:
				if not record is Dictionary: continue
				var r:Dictionary=record
				if day-int(r.get("day",-99999))>BATTLES_LOOK_DAYS: break
				var threat:Dictionary=r.get("threat",{}) if r.get("threat") is Dictionary else {}
				if String(threat.get("source_civ_id",""))!="human" or String(threat.get("war_loop",""))!="": continue
				var key:="theirs:%s:%d:%d" % [String(id),int(r.get("seed",0)),int(r.get("day",0))]
				if seen.has(key): continue
				seen[key]=day
				var their_side:=String(r.get("home_side","attacker"))
				_count_battle(String(id),r,"defender" if their_side=="attacker" else "attacker",day,true)
	while seen.size()>BATTLES_SEEN_MAX: seen.erase(seen.keys()[0])
	s["battles_seen"]=seen

## One real battle into the ledger. our_side: which side of the record is
## ours. told_here: the battle is theirs, told back to us (their band at our
## town): the Chronicle and the war leader hear of it from here.
static func _count_battle(civ_id:String,r:Dictionary,our_side:String,day:int,told_here:bool)->void:
	if _civ(civ_id).is_empty(): return
	var their_side:="defender" if our_side=="attacker" else "attacker"
	var ours:Dictionary=r.get(our_side,{}) if r.get(our_side) is Dictionary else {}
	var theirs:Dictionary=r.get(their_side,{}) if r.get(their_side) is Dictionary else {}
	var our_dead:=maxi(0,int(ours.get("dead",_killed(r,our_side))))
	var their_dead:=maxi(0,int(theirs.get("dead",_killed(r,their_side))))
	var we_struck:=our_side=="attacker"
	var when:=int(r.get("day",day))
	var termination:Dictionary=r.get("termination",{}) if r.get("termination") is Dictionary else {}
	var we_won:=String(termination.get("captor",""))!="" and String(termination.get("captor",""))==String(ours.get("name","~"))
	var they_won:=String(termination.get("captor",""))!="" and String(termination.get("captor",""))==String(theirs.get("name","~"))
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
	var name:=_name(civ_id)
	var strategic:Dictionary=r.get("strategic_outcome",{}) if r.get("strategic_outcome") is Dictionary else {}
	var spoils:Dictionary=strategic.get("raid_spoils",{}) if strategic.get("raid_spoils") is Dictionary else {}
	var taken:=roundi(float(spoils.get("Food",0.0)))
	var place:=String(r.get("target_region_name",(r.get("threat",{}) as Dictionary).get("target_region_name","") if r.get("threat") is Dictionary else ""))
	if not war.is_empty():
		war["score"]=int(war.get("score",0))+(1 if we_won else (-1 if they_won else 0))
		war["last_fight"]=maxi(int(war.get("last_fight",-99999)),when)
		_exhaust(civ_id,our_dead,their_dead)
		if not we_struck: war["last_attack"]={"day":when,"target":"town","our_dead":our_dead,"taken":taken,"won":they_won}
	else:
		if int(f.get("level",0))<1 or int(f.get("feud_since",-1))<0 or when-int(f.get("last_harm",-99999))>FEUD_COLD_DAYS: _begin_feud(f,when)
		f["level"]=maxi(int(f.get("level",0)),2)
		f["last_harm"]=maxi(int(f.get("last_harm",-99999)),when)
		f.erase("settled_until")
		if we_struck: f["last_strike"]=when
		else:
			f["last_skirmish"]=when
			f["last_raid"]={"day":when,"target":"town","their_n":int(theirs.get("initial_troops",0)),"our_dead":our_dead,"their_dead":their_dead,"taken":taken,"captives":0,"skirmish":true,"ambush":false,"cause":"raid","names":[],"place":place}
		_tally(civ_id,"strikes" if we_struck else "raids",our_dead,their_dead)
		# Blood for blood: a people we struck, or whose raiders we killed, may
		# come back for more unless the feud has worn them out.
		if their_dead>0 and (f.get("pending",{}) as Dictionary).is_empty() and float(f.get("their_exh",0.0))<ENEMY_SPENT:
			var rng:=_rng("answer:%s:%d:%d" % [civ_id,when,int(r.get("seed",0))])
			if rng.randf()<(0.6 if we_struck else 0.4): _schedule(civ_id,when+rng.randi_range(60,300),"vengeance","battle:%d" % int(r.get("seed",0)))
	if their_dead>0: _rivals().call("grudge",civ_id,"the %s you killed in the fighting" % ("fighters" if their_dead>1 else "fighter"),0.3 if we_struck else 0.2,"battle_dead:%d" % int(r.get("seed",0)))
	_mark_harm(civ_id,when)
	_stat("battles_counted")
	_log(civ_id,"battle_ours" if we_struck else "battle_theirs","%s: %d of ours and %d of theirs killed." % [place if place!="" else name,our_dead,their_dead],{"our_dead":our_dead,"their_dead":their_dead,"won":we_won,"lost":they_won,"seed":int(r.get("seed",0))})
	if we_struck and we_won: _chief_seized(civ_id,r,when,place)
	if told_here:
		# Their band came at a town of ours: the battle was fought in their
		# world and told back to ours; told here once, as the raid it was.
		var where:=place if place!="" else String(GameState.settlement_name)
		var text:="%d %s fighters came for %s and our people met them. %s" % [int(theirs.get("initial_troops",0)),name,where,"%d of ours were killed." % our_dead if our_dead>0 else "No one of ours was killed."]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
		text+=(" They carried off %d Food." % taken) if taken>0 else (" They were driven off." if not they_won else "")
		var key:="battle:%s:%d" % [civ_id,int(r.get("seed",0))]
		var seen_seed:=_observe(key,"%s Raiders at %s" % [name,_title_place(where)],"at %s" % where,civ_id,"defender",{"result":r,"tactics":r.get("tactics",{})},{"home_dead":our_dead,"away_dead":their_dead,"home_taken":0,"away_taken":0})
		_chronicle(key,"%s Raiders at %s" % [name,_title_place(where)],text,"moment" if our_dead>0 or they_won else "notice",civ_id,seen_seed)
		_file(civ_id,"raided" if war.is_empty() else "report",text,day)

## A band of ours out against this people on the war council's errand. One
## whose errand is over (on its way home, resting, home) is not: a band that
## rested at home for years after its raid kept the feud hot, and the war
## leader sent messengers to settle it again every season.
static func _bands_out(civ_id:String)->bool:
	var mc:Variant=WorldSimulation.military
	if mc==null: return false
	for army in mc.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0: continue
		var c:Variant=(army as Dictionary).get("council")
		if not c is Dictionary or String((c as Dictionary).get("civ",""))!=civ_id: continue
		if String((c as Dictionary).get("phase","")) in ["home","done"]: continue
		return true
	return false

## The god's own band against a small people (the engine's war flag): the feud
## is hot from the day the fight began, and while blood is being spilled.
static func _open_fight(civ_id:String,relation:Dictionary,day:int)->void:
	var f:=front(civ_id)
	var started:=int(relation.get("war_started_day",day))
	if int(f.get("fight_from",-99999))!=started:
		f["fight_from"]=started
		_feud_from_attack(civ_id,day)
	elif _battle_live(civ_id): f["last_harm"]=day

## A fight of ours with them is on right now (a siege, a battle, their band
## met in the field).
static func _battle_live(civ_id:String)->bool:
	var mc:Variant=WorldSimulation.military
	return mc!=null and mc.has_method("has_active_operation_for_civ") and bool(mc.has_active_operation_for_civ(civ_id))

## A band of ours is out against them, fighting them, or holds a town of
## theirs: the engine's war flag stays while the god's own fight goes on.
static func _our_fight_live(civ_id:String)->bool:
	var mc:Variant=WorldSimulation.military
	if mc==null: return false
	if _battle_live(civ_id): return true
	for a in mc.field_armies:
		if not a is Dictionary: continue
		var op:Variant=(a as Dictionary).get("city_operation")
		if op is Dictionary and String((op as Dictionary).get("civ_id",""))==civ_id: return true
		var ordered:Variant=(a as Dictionary).get("court_order")
		if ordered is Dictionary and String((ordered as Dictionary).get("civ_id",""))==civ_id and String((a as Dictionary).get("status",""))=="moving": return true
	for force in mc.occupation_forces:
		if force is Dictionary and String((force as Dictionary).get("civ_id",""))==civ_id and int((force as Dictionary).get("troops",0))>0: return true
	return false

## Each tick of a feud: kin by marriage end it, three quiet winters make it go
## cold, and a worn-out or frightened people may send someone to end it.
static func _feud_day(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	if int(f.level)<1 or bool(_relation(civ_id).get("at_war",false)): return
	if not _married(civ_id).is_empty():
		_end_feud(civ_id,day,"marriage","The marriage between our peoples has ended the feud with %s: kin do not raid kin." % _name(civ_id))
		return
	if day-int(f.last_harm)>=FEUD_COLD_DAYS and (f.pending as Dictionary).is_empty() and (f.get("op",{}) as Dictionary).is_empty() and not _bands_out(civ_id):
		_feud_cold(civ_id,day)
		return
	_peace_seeker(civ_id,day)

## ONE RULE FOR OLD AND NEW: a small people found "at war" with us (a save
## from before the rule; a war opened by other means) fights on as a feud. The
## dead, the raids and the grudges stay; the fronts, the terms and the
## general's campaign go at once. The engine's war flag itself stays while a
## band of ours is out against them or we hold a town of theirs (the god's own
## fight), and goes when that fight is over. Two small peoples at war with each
## other feud too (CivilizationSystem.reconcile_rival_feuds). Runs on load and
## each tick. Returns the peoples whose war (or open fight) became the feud.
static func reconcile(day:int=-1)->Array:
	if day<0: day=_day()
	var out:Array=[]
	var world:Variant=WorldSimulation.world
	if world==null: return out
	for index in world.civilizations.size():
		var civ:Dictionary=world.civilizations[index]
		var id:=String(civ.get("id",""))
		if id=="" or bool(civ.get("general_campaign_owned",false)) or not bool(civ.get("alive",true)): continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		if not bool(relation.get("at_war",false)) or Scale.formal(id): continue
		if _our_fight_live(id):
			# Our band is still out: their war from before the rule is a feud
			# already, and the engine's flag waits for our band.
			if not (_peek(id).get("war",{}) as Dictionary).is_empty():
				_war_to_feud(id,day,true)
				out.append(id)
			continue
		_war_to_feud(id,day)
		out.append(id)
	if world.has_method("reconcile_rival_feuds"): world.reconcile_rival_feuds(day)
	return out

## The dead of the engine's war record for this fight not yet in the feud's
## count ({ours, theirs}): the god's own strikes are fought by the field army
## (MilitaryCampaign), whose battles the record keeps. Each record is counted
## once, however often the feud reads it.
static func _record_dead(f:Dictionary,civ_id:String,war_id:String)->Dictionary:
	var out:={"ours":0,"theirs":0}
	var world:Variant=WorldSimulation.world
	if war_id=="" or world==null or not world.has_method("_war_record_index"): return out
	var at:int=world._war_record_index(war_id)
	if at<0: return out
	var casualties:Dictionary=world.war_history[at].get("casualties",{}) if world.war_history[at].get("casualties") is Dictionary else {}
	var ours:=0; var theirs:=0
	for side in casualties:
		var c:Dictionary=casualties[side] if casualties[side] is Dictionary else {}
		var n:=int(c.get("military_dead",0))+int(c.get("civilian_dead",0))
		if String(side)=="player": ours+=n
		elif String(side)==civ_id: theirs+=n
	var seen:Dictionary=f.get("war_dead_seen",{}) if f.get("war_dead_seen") is Dictionary else {}
	var before:Dictionary=seen.get(war_id,{}) if seen.get(war_id) is Dictionary else {}
	out.ours=maxi(0,ours-int(before.get("ours",0)))
	out.theirs=maxi(0,theirs-int(before.get("theirs",0)))
	seen[war_id]={"ours":ours,"theirs":theirs}
	while seen.size()>4: seen.erase(seen.keys()[0])
	f["war_dead_seen"]=seen
	return out

## Why a war that became a feud was fought, in words: a killed envoy first
## (rival_rulers.gd keeps the wrong), else the war's own cause.
static func _war_cause(civ_id:String,war:Dictionary,relation:Dictionary)->String:
	var r:GDScript=_rivals()
	if r!=null and not ForeignDiplomacy.leader(civ_id).is_empty():
		var wronged:=String(r.call("envoy_wrong_words",civ_id))
		if wronged!="": return wronged
	var cause:=String(war.get("cause",""))
	if cause!="" and cause!="the war": return cause
	var world:Variant=WorldSimulation.world
	var war_id:=String(relation.get("war_id",war.get("war_id","")))
	if world!=null and war_id!="" and world.has_method("_war_record_index"):
		var at:int=world._war_record_index(war_id)
		if at>=0:
			var said:=String(world.war_history[at].get("cause",""))
			for lead in ["Vengeance for ","War over "]: said=said.trim_prefix(lead)
			# The god's own attack (record_player_hostile_order, declare_war).
			for ours in ["A player","A commanded","War declared by"]:
				if said.begins_with(ours): return "our attack on them"
			if said!="" and not said.begins_with("Ongoing"): return (_rivals().call("narrate",said) as String) if r!=null else said
	return "old wrongs"

## One war, as a feud (reconcile): what it cost both sides is kept, their
## raiders keep coming, and nothing of a war is left. keep_flag: a band of
## ours is still out against them, so the engine's war flag and record stay
## until it is home. When the god's own strike on a people already feuding
## with us is over, the feud simply goes on (no new word in the Chronicle).
## The engine's war flag on a small people lowered (no host marches against
## them: a feud, or a settlement).
static func _lower_war_flag(civ_id:String,day:int,war_id:String,why:String,stance:String)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	relation["at_war"]=false; relation["treaty"]="none"; relation["stance"]=stance
	relation["war_goal"]="limited"; relation["war_target_region_id"]=""; relation["war_score"]=0.0; relation["conflict_turns"]=0
	relation["last_war_result"]=why
	civ["player_relation"]=relation
	world.civilizations[index]=civ
	if war_id!="" and world.has_method("_end_war"): world._end_war(war_id,day,why)
	if world.has_method("_remove_pending_player_incidents"): world._remove_pending_player_incidents(civ_id)

static func _war_to_feud(civ_id:String,day:int,keep_flag:bool=false)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	var f:=front(civ_id)
	var war:Dictionary=(f.war as Dictionary).duplicate(true)
	var started:=int(relation.get("war_started_day",war.get("start",day)))
	if started<0: started=int(war.get("start",day))
	started=mini(started,day)
	# A fight that ended in a settlement (their chief ransomed, a blood price
	# paid) lowers the engine's flag and leaves the feud settled.
	if war.is_empty() and int(f.get("level",0))<1 and int((f.get("feud_end",{}) as Dictionary).get("day",-99999))>=started:
		if not keep_flag: _lower_war_flag(civ_id,day,String(relation.get("war_id","")),"settled","watchful")
		return
	var last:=maxi(int(war.get("last_fight",war.get("start",started))),int((war.get("last_attack",{}) as Dictionary).get("day",-99999)))
	last=maxi(last,int(f.get("last_harm",-99999)))
	if last<0: last=started
	var had:=int(f.level)>=1 and int(f.get("feud_since",-1))>=0 and started-int(f.last_harm)<=FEUD_COLD_DAYS
	# The god's own strike, over, on a people the feud already counts.
	var quiet:=had and war.is_empty()
	var cause:=String(f.get("cause","")) if had and String(f.get("cause",""))!="" else _war_cause(civ_id,war,relation)
	if not had: _begin_feud(f,started)
	# What the war cost both sides is the feud's own count (the war leader's
	# own tally, or the field army's battles in the war record, whichever
	# counted more); its raids and strikes are counted from the log (one ledger).
	var war_id:=String(relation.get("war_id",war.get("war_id","")))
	var recorded:=_record_dead(f,civ_id,war_id)
	f["our_dead"]=int(f.get("our_dead",0))+maxi(int(war.get("our_dead",0)),int(recorded.ours))
	f["their_dead"]=int(f.get("their_dead",0))+maxi(int(war.get("their_dead",0)),int(recorded.theirs))
	f["our_exh"]=maxf(float(f.get("our_exh",0.0)),float(war.get("our_exh",0.0)))
	f["their_exh"]=maxf(float(f.get("their_exh",0.0)),float(war.get("their_exh",0.0)))
	var raids:=0; var strikes:=0
	for e in state().log:
		if not e is Dictionary or String((e as Dictionary).get("civ",""))!=civ_id or int((e as Dictionary).get("day",-1))<int(f.feud_since): continue
		var kind:=String((e as Dictionary).get("kind",""))
		if kind in ["raid","skirmish","ambush","enemy_attack"]: raids+=1
		elif kind in ["op_burn","op_chief","op_pursue"]: strikes+=1
	f["raids"]=maxi(int(f.get("raids",0)),raids); f["strikes"]=maxi(int(f.get("strikes",0)),strikes)
	f["level"]=2
	f["last_harm"]=last
	f["cause"]=cause.substr(0,120)
	f["fight_from"]=int(relation.get("war_started_day",-1))
	f.erase("settled_until")
	# Our band out in the war comes back in the feud; the general's own
	# campaign, the terms and the next host of theirs are gone.
	var op:Dictionary=war.get("op",{}) if war.get("op") is Dictionary else {}
	if not op.is_empty() and (f.get("op",{}) as Dictionary).is_empty(): f["op"]=op
	f["war"]={}
	if (f.pending as Dictionary).is_empty() and day-last<FEUD_HOT_DAYS:
		var next:=maxi(day+20,int(war.get("next_enemy",day+_rng("feud_next:%s:%d" % [civ_id,day]).randi_range(30,90))))
		_schedule(civ_id,next,"vengeance","war")
	if not keep_flag: _lower_war_flag(civ_id,day,war_id,"became a feud","hostile")
	var r:GDScript=_rivals()
	if r!=null and not ForeignDiplomacy.leader(civ_id).is_empty():
		var c:Dictionary=r.call("character",civ_id)
		c.erase("war_prep_day"); c.erase("war_due_day")
	_purge_occasions(civ_id)
	var had_matter:=false
	for m in Hall.state().matters:
		if m is Dictionary and String(m.get("situation_type",""))=="war_campaign" and String((((m.get("audience",{}) as Dictionary).get("situation",{}) as Dictionary).get("war",{}) as Dictionary).get("civ_id",""))==civ_id: had_matter=true
	var name:=_name(civ_id)
	var text:="%s still wants vengeance for %s. No host will march: it is a feud, and their raiders will come instead, and ours may answer them. So far %d of ours and %d of theirs have died." % [name,cause,int(f.our_dead),int(f.their_dead)]
	_log(civ_id,"war_to_feud",text,{"our_dead":int(f.our_dead),"their_dead":int(f.their_dead),"war_id":war_id,"quiet":quiet,"band_out":keep_flag})
	if quiet:
		_stat("strikes_home")
		return
	_chronicle("war_to_feud:%s:%d" % [civ_id,day],"The Feud With %s" % name,text,"notice",civ_id)
	_stat("wars_to_feuds")
	if had_matter or day-last<FEUD_HOT_DAYS: _file(civ_id,"feud",text,day)

## Neighbouring peoples go to war with each other at about the benchmark rate
## for general war (EPOCHAL_SHIFTS.md s5: 0.15-0.6 wars per people per game
## century before the modern era), faster when they are hungry, hostile,
## pressed at the border or ruled by a grudge-holder or a far hunter. The
## declaration is carried and the war fought by CivilizationSystem.
## Annual war onset per people (split across its neighbours), before the
## multipliers of its condition.
const RIVAL_WAR_BASE:=0.0018
const RIVAL_WAR_CAP:=0.012
## Two peoples are neighbours when their countries (realm_reach.gd) come
## within NEIGHBOUR_MARGIN_KM of meeting: about a month's march, the distance
## bulk goods are still worth carrying (envoy_requests.gd BULK_KM). Peoples
## founded 1,100 km apart (civilization_start.gd) become neighbours as their
## lands grow toward each other; a people across the sea never is.
const NEIGHBOUR_MARGIN_KM:=450.0
const RealmReach:=preload("res://scripts/realm_reach.gd")

## Whether a people's country comes within NEIGHBOUR_MARGIN_KM of ours (the
## same rule as neighbours, with our realm as one side). True before we have
## a home, when there is no country of ours to measure from.
static func near_us(civ_id:String)->bool:
	var ours:=RealmReach.ours()
	if ours.is_empty(): return true
	var civ:=_civ(civ_id)
	if civ.is_empty(): return false
	var theirs:=RealmReach.of(civ)
	var center:Vector2=theirs.get("center",WorldSimulation.world._civilization_world_position(civ))
	var reach:=float(theirs.get("reach",RealmReach.reach_km(float(civ.get("population",0.0)),float(civ.get("world_reach",0.0)))))
	return (ours.center as Vector2).distance_to(center)<=float(ours.reach)+reach+NEIGHBOUR_MARGIN_KM

static func neighbours(first:Dictionary,second:Dictionary)->bool:
	var world=WorldSimulation.world
	var a:Vector2=world._civilization_world_position(first); var b:Vector2=world._civilization_world_position(second)
	var reach:=RealmReach.reach_km(float(first.get("population",0.0)),float(first.get("world_reach",0.0)))+RealmReach.reach_km(float(second.get("population",0.0)),float(second.get("world_reach",0.0)))
	return a.distance_to(b)<=reach+NEIGHBOUR_MARGIN_KM

static func rival_war_hazard(first:Dictionary,second:Dictionary,relation:Dictionary,neighbours:float=1.0)->float:
	## Annual chance that these two neighbours go to war, from their condition.
	## `neighbours` is the pair's mean count of neighbours: a people's hazard
	## is shared across its borders, not multiplied by them.
	var opinion:=float(relation.get("opinion",0.0))
	var tension:=float(relation.get("border_tension",0.0))
	var factor:=1.0+maxf(0.0,-opinion)*3.0+tension*2.0+(float(first.get("aggression",0.3))+float(second.get("aggression",0.3)))*0.8
	for civ in [first,second]:
		if Hall._hungry(civ): factor+=1.0
		var known:Variant=ForeignDiplomacy.leaders.get(String(civ.id),{})
		var c:Variant=(known as Dictionary).get("character") if known is Dictionary else null
		if c is Dictionary and String((c as Dictionary).get("trait","")) in ["grudge","hunter"]: factor+=0.5
	return clampf(RIVAL_WAR_BASE*factor,0.0,RIVAL_WAR_CAP)/maxf(1.0,neighbours)

static func neighbour_counts()->Dictionary:
	var counts:={}
	var civs:=WorldSimulation.world.civilizations
	for i in civs.size():
		for j in range(i+1,civs.size()):
			if not bool(civs[i].get("alive",true)) or not bool(civs[j].get("alive",true)): continue
			if not neighbours(civs[i],civs[j]): continue
			counts[String(civs[i].id)]=int(counts.get(String(civs[i].id),0))+1
			counts[String(civs[j].id)]=int(counts.get(String(civs[j].id),0))+1
	return counts

static func _rival_wars(day:int)->void:
	var world:=WorldSimulation.world
	var civs:=world.civilizations
	var counts:=neighbour_counts()
	for i in civs.size():
		for j in range(i+1,civs.size()):
			var first:Dictionary=civs[i]; var second:Dictionary=civs[j]
			if not bool(first.get("alive",true)) or not bool(second.get("alive",true)): continue
			if bool(first.get("general_campaign_owned",false)) or bool(second.get("general_campaign_owned",false)): continue
			# A people down to a handful starts no quarrel and is worth none.
			if minf(float(first.get("population",0.0)),float(second.get("population",0.0)))<BROKEN_PEOPLE: continue
			if not neighbours(first,second): continue
			var relation:Dictionary=(first.get("relations",{}) as Dictionary).get(String(second.id),{})
			if relation.is_empty() or bool(relation.get("at_war",false)) or String(relation.get("pending_message",""))!="" or String(relation.get("treaty","none")) in ["non_aggression","truce","trade"]: continue
			# Already feuding: the feud runs its own course (CivilizationSystem).
			if world.has_method("rival_feud_hot") and bool(world.rival_feud_hot(relation,day)): continue
			# One bowed to the other lately and pays it tribute (rival_feuds.gd).
			if not preload("res://scripts/rival_feuds.gd").bowed(relation,day).is_empty(): continue
			var monthly:=rival_war_hazard(first,second,relation,(float(counts.get(String(first.id),1))+float(counts.get(String(second.id),1)))*0.5)/12.0
			if _rng("rivalwar:%s:%s:%d" % [String(first.id),String(second.id),day]).randf()>=monthly: continue
			# Two small peoples do not declare war: the same quarrel is a feud,
			# fought by raiders (conflict_scale.gd). The benchmark hazard is the
			# onset of fighting either way; only peoples organised for war carry
			# a declaration and fight a war (EPOCHAL_SHIFTS.md s5).
			if not Scale.formal_war(String(first.id),String(second.id)):
				if world.has_method("start_rival_feud"): world.start_rival_feud(i,j,day,"old quarrels on the border")
				_stat("rival_feuds")
				continue
			# Two simulated peoples declare their own wars, through their own
			# leaders' diplomacy; a note here would never be carried.
			if WorldSimulation.enabled and WorldSimulation.actors.has(String(first.id)) and WorldSimulation.actors.has(String(second.id)): continue
			var carried:=relation.duplicate(true)
			carried["pending_message"]="war"
			carried["pending_message_sent_day"]=day
			carried["pending_message_due_day"]=day+(world._intercivilization_message_days(first,second,false) if world.has_method("_intercivilization_message_days") else 10)
			carried["border_tension"]=maxf(0.55,float(carried.get("border_tension",0.0)))
			carried["opinion"]=minf(-0.25,float(carried.get("opinion",0.0)))
			world._set_pair_relation(i,j,carried)
			_stat("rival_wars")

static func _grudges(day:int)->void:
	## A heavy old grudge sends raiders without a new demand; so does envy of a
	## people rich in stores and works that too few guard (standing.gd).
	var our:=Standing.strengths()
	for civ_id in ForeignDiplomacy.leaders.keys():
		var id:=String(civ_id)
		var relation:=_relation(id)
		if relation.is_empty() or int(relation.get("contact_level",0))<2 or bool(relation.get("at_war",false)) or _truce_binds(id,day): continue
		var f:=front(id)
		if not (f.pending as Dictionary).is_empty() or day-int(f.last_harm)<365: continue
		var chance:=grudge_raid_chance(id)
		if chance>0.0 and _rng("grudge:%s:%d" % [id,day]).randf()<chance:
			_schedule(id,day+_rng("grudge_day:%s:%d" % [id,day]).randi_range(20,90),"grudge","grudge")
			continue
		var envy_chance:=envy_raid_chance(id,float(Standing.view_of(id,our).get("envy",0.0)))
		if envy_chance>0.0 and _rng("envy:%s:%d" % [id,day]).randf()<envy_chance:
			_schedule(id,day+_rng("envy_day:%s:%d" % [id,day]).randi_range(15,60),"envy","envy")

## This month's chance that a heavy old grudge sends raiders (checked monthly
## by _grudges; the Standing page states it).
static func grudge_raid_chance(civ_id:String)->float:
	if broken(civ_id): return 0.0
	var rival:=_rival(civ_id)
	var weight:=float(rival.get("grudge_weight",0.0))
	if weight<0.9: return 0.0
	return clampf((weight-0.8)*0.03,0.0,0.035)*(1.3 if String(rival.get("trait",""))=="grudge" else 1.0)*_league_backing(civ_id)

## This month's chance that envy of our stores and works sends raiders.
static func envy_raid_chance(civ_id:String,envy:float)->float:
	if envy<=Standing.ENVY_RAID_FLOOR or broken(civ_id): return 0.0
	return clampf((envy-Standing.ENVY_RAID_FLOOR)*0.06,0.0,0.03)*(1.3 if String(_rival(civ_id).get("trait","")) in ["hunter","magpie"] else 1.0)*_league_backing(civ_id)

## Peoples bound together against us back each other's raids (fear_league.gd).
static func _league_backing(civ_id:String)->float:
	var league:=preload("res://scripts/fear_league.gd")
	return league.RAID_BACKING if league.is_member(civ_id) else 1.0

# --------------------------------------------------------------------------
# The court: the war leader's matter, options, answers
# --------------------------------------------------------------------------

static func has_campaign(civ_id:String)->bool:
	return not (front(civ_id).war as Dictionary).is_empty()

static func _drop_matters(civ_id:String)->void:
	var list:Array=Hall.state().matters
	for m in list.duplicate():
		if m is Dictionary and String(m.get("situation_type",""))=="war_campaign" and String((((m.get("audience",{}) as Dictionary).get("situation",{}) as Dictionary).get("war",{}) as Dictionary).get("civ_id",""))==civ_id: list.erase(m)

## extra: merged into the matter's war part (a battle's seed and the war
## leader's whole account, which he speaks in full when summoned).
static func _file(civ_id:String,mode:String,summary:String,day:int,extra:Dictionary={})->Dictionary:
	var general:=_general()
	if general.is_empty(): return {}
	_drop_matters(civ_id)
	var name:=_name(civ_id)
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(general.get("name","")).substr(0,100),"title":String(general.get("office_title","War Leader")).substr(0,100),"person_id":int(general.get("person_id",0)),"role":"official"}
	var headline:String={"raided":"comes about the raid","war":"comes about the war","feud":"comes about the feud","report":"reports from the field","terms":"brings the enemy's terms"}.get(mode,"comes about the war" if Scale.formal(civ_id) else "comes about the feud")
	var text:=summary.substr(0,380)
	audience.petition={"topic":"campaign","summary":text,"suggested_decree":""}
	audience.situation={"type":"war_campaign","ask":"war:%s:%s:%d" % [civ_id,mode,day],"headline":headline,"summary":text,
		"occasion":{"type":"war_campaign","text":"%s and %s" % [mode,name],"day":day,"crisis":mode!="report"},
		"war":{"civ_id":civ_id,"civ_name":name,"mode":mode,"filed":day}}
	(audience.situation.war as Dictionary).merge(extra,true)
	var entry:=Hall._file_matter(audience,[])
	entry["urgency"]=0.95 if mode in ["war","terms"] else 0.85
	front(civ_id)["matter_day"]=day
	var war:Dictionary=front(civ_id).war
	if not war.is_empty(): war["filed_day"]=day
	return entry

static func _war_part(audience:Dictionary)->Dictionary:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	return situation.get("war",{}) if situation.get("war") is Dictionary else {}

static func _odds_words(odds:float)->String:
	if odds>=1.3: return "I think we win it."
	if odds>=0.95: return "It could go either way."
	if odds>=0.7: return "It will be hard."
	return "I would not bet on it."

static func _odds(civ_id:String,objective:String)->float:
	var r:=ratio(civ_id)
	var terrain:float={"war_pursue":1.0,"war_burn":1.15,"war_chief":1.6}.get(objective,1.0)
	return 1.0/maxf(0.2,r*terrain)

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var part:=_war_part(audience)
	var civ_id:=String(part.get("civ_id",""))
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var name:=_name(civ_id)
	var mode:=String(part.get("mode",""))
	# A war that became a feud (reconcile) is still to be answered as the feud.
	if civ_id=="" or _civ(civ_id).is_empty() or (mode in ["war","terms"] and war.is_empty() and not feuding(civ_id)):
		out.append(Hall._option("war_rest","It is past","That war is over.","neutral"))
		return out
	# The war council's real numbers: the soldiers at home, and those free to
	# go beyond the watch that stays (war_council.gd).
	var men:=_soldiers()
	var free:=EraWords.grouped(int(men.free))
	var home:=EraWords.grouped(int(men.home))
	# Trackers or messengers already out: the next go when they are back.
	var note:=" (after those now out are back)" if not (f.get("op",{}) as Dictionary).is_empty() else ""
	# Their stores and chief are at a home we must first find (NEEDS_HOME).
	var findable:=home_known(civ_id)
	var track:=Hall._option("war_track","Find where they live","Nobody knows where %s live. A few trackers follow their raiders' trail home. %s%s" % [name,_track_odds_words(track_chance(civ_id,_general_skill(_general()))),note],"neutral")
	if not war.is_empty():
		out.append(Hall._option("war_guard","Hold the approaches","The %s soldiers at home hold the approaches, and go out to meet their band when the watch sees it coming." % home,"neutral"))
		if findable:
			out.append(Hall._option("war_burn","Burn their stores","A raiding band from our %s free soldiers against %s's stores by night. %s" % [free,name,_odds_words(_odds(civ_id,"war_burn"))],"hostile"))
			out.append(Hall._option("war_chief","Bring me their chief","A band from our %s free soldiers strikes at %s's chief town, where their chief sits. %s If he is taken, they will ransom him and ask for peace." % [free,name,_odds_words(_odds(civ_id,"war_chief"))],"hostile"))
		else: out.append(track)
		out.append(Hall._option("war_parley","Send for a truce","Two messengers to %s. %s" % [name,"They may listen now." if float(war.get("their_exh",0.0))>=0.3 else "They are not tired of it yet."],"warm"))
		var terms:Dictionary=war.get("terms",{})
		if not terms.is_empty():
			var short:=Hall._short("Food",float(terms.get("amount",0.0)))
			out.append(Hall._option("war_pay","Pay what they ask","%d Food, and the war ends." % roundi(float(terms.get("amount",0.0))),"neutral",short=="",short))
		out.append(Hall._option("war_general","Do as you judge","The war leader chooses.","neutral"))
		return out
	# A feud (or raids short of war): the feud's own acts.
	var raid:Dictionary=f.get("last_raid",{})
	var small:=not Scale.formal(civ_id)
	out.append(Hall._option("war_pursue","Go after them","A band from our %s free soldiers goes after them%s. %s Blood may answer blood." % [free," to take back the %d Food" % int(raid.get("taken",0)) if int(raid.get("taken",0))>0 else "",_odds_words(_odds(civ_id,"war_pursue"))],"hostile"))
	if findable:
		out.append(Hall._option("war_burn","Burn their stores in return","A raiding band from our %s free soldiers against %s's stores. %s %s" % [free,name,_odds_words(_odds(civ_id,"war_burn")),("%s will want blood for it." % name) if small else ("%s may come to war over it." % name)],"hostile"))
		# Their chief sits in their chief town: a band that beats its defenders
		# takes him, and he is ransomed (chief_taken).
		if int(f.level)>=2: out.append(Hall._option("war_chief","Bring me their chief","A band from our %s free soldiers strikes at %s's chief town, where their chief sits. %s If he is taken, they will ransom him and swear off the feud." % [free,name,_odds_words(_odds(civ_id,"war_chief"))],"hostile"))
	else: out.append(track)
	out.append(Hall._option("war_guard","Guard the approaches","The %s soldiers at home keep the approaches. The next raiders meet spears." % home,"neutral"))
	out.append(Hall._option("war_parley","Send word: enough","Messengers to %s to settle it. Some will call it weakness." % name,"warm"))
	# A blood price for the lives of theirs we took settles the feud itself.
	if int(f.level)>=2 or int(f.get("their_dead",0))>0:
		var price:=blood_price(civ_id)
		var short:=Hall._short("Food",price)
		var dead:=int(f.get("their_dead",0))
		out.append(Hall._option("war_price","Pay a blood price","%d Food to %s%s. It settles the blood between us; some here will call it weakness." % [roundi(price),name,(" for the %d of theirs we killed" % dead) if dead>0 else ""],"warm",short=="",short))
	out.append(Hall._option("war_let","Let it pass","Bury the dead and do nothing. %s may take it for weakness." % name,"neutral"))
	return out

static func on_open(audience:Dictionary)->void:
	var part:=_war_part(audience)
	if part.is_empty(): return
	var civ_id:=String(part.get("civ_id",""))
	var speaker:Dictionary=audience.get("speaker",{})
	var general:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if general.is_empty(): general={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	var name:=_name(civ_id)
	var mode:=String(part.get("mode",""))
	var free:=int(_soldiers().free)
	var said:=""
	var at_war_now:=not (front(civ_id).war as Dictionary).is_empty()
	# A war that became a feud is spoken of as the feud.
	if mode in ["war","terms"] and not at_war_now and feuding(civ_id): mode="feud"
	match mode:
		"feud":
			var f:=front(civ_id)
			var dead:=""
			if int(f.get("our_dead",0))+int(f.get("their_dead",0))>0: dead=" So far %d of ours and %d of theirs have died in it." % [int(f.get("our_dead",0)),int(f.get("their_dead",0))]
			var can:="keep a watch at the approaches, go after their raiders, %s, or send word to settle it" % ("strike at their stores" if home_known(civ_id) else "find where they live")
			said="%s wants vengeance for %s. Their raiders will come, a few at a time, when we least look for them.%s I can %s. Tell me which." % [name,_feud_cause(civ_id),dead,can]
		"raided":
			var raid:Dictionary=front(civ_id).get("last_raid",{})
			said="%s came to %s. %s" % [name,String((TARGETS.get(String(raid.get("target","gathering")),TARGETS.gathering) as Dictionary).words),"We lost %d." % int(raid.get("our_dead",0)) if int(raid.get("our_dead",0))>0 else "No one of ours died."]
			if int(raid.get("taken",0))>0: said+=" They took %d Food." % int(raid.get("taken",0))
			said+=(" I can take a band of our %s free soldiers after them, or keep the approaches. Tell me which." % EraWords.grouped(free)) if free>=RAIDERS_MIN else " We have no soldiers free to go after them; I can keep the approaches."
		"war":
			said="%s is at war with us. %s Tell me what you want done, and I will see to it." % [name,_strength_words(civ_id)]
		"report":
			if String(part.get("account",""))!="":
				# A battle: the war leader tells the whole account himself.
				said=String(part.account)
			else:
				said=String((audience.get("petition",{}) as Dictionary).get("summary","")).substr(0,300)
				said+=" What now?"
		"terms":
			var terms:Dictionary=(front(civ_id).war as Dictionary).get("terms",{})
			said="%s's herald wants %d Food to end it. Our people are worn down. It is your word." % [name,int(float(terms.get("amount",0.0)))]
	var advice:="" if String(part.get("account",""))!="" else _objective_for_general(civ_id,general,at_war_now)
	var advice_words:String={"war_guard":"If it were mine to say, I would hold the approaches and let them come to us.","war_burn":"If it were mine to say, I would burn their stores.",
		"war_chief":"If it were mine to say, I would go for their chief.","war_pursue":"If it were mine to say, I would go after them now, while the trail is fresh.",
		"war_parley":"If it were mine to say, I would send for a truce." if at_war_now else "If it were mine to say, I would send word to settle it.",
		"war_track":"If it were mine to say, I would find where they live first. Nobody here knows the way."}.get(advice,"")
	if said!="": Hall.append_line(String(audience.id),{"speaker":String(general.get("name","")),"role":"official","person_id":int(general.get("person_id",0)),"civ_id":"player","text":said,"day":_day(),"aside":false})
	if advice_words!="": Hall.append_line(String(audience.id),{"speaker":String(general.get("name","")),"role":"official","person_id":int(general.get("person_id",0)),"civ_id":"player","text":advice_words,"day":_day(),"aside":false})

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var part:=_war_part(audience)
	var civ_id:=String(part.get("civ_id",""))
	if option_id=="war_rest" and (front(civ_id).war as Dictionary).is_empty() and String(part.get("mode","")) in ["war","terms"]:
		return {"outcome":"That war is already over.","reaction":"neutral"}
	if not option_id in OBJECTIVES: return {"error":"That is not an order the war leader can carry."}
	var at_war_now:=not (front(civ_id).war as Dictionary).is_empty()
	# "Burn their stores" at a home nobody has found went to the trackers; the
	# war leader answers the words the god said (order() says why).
	var asked:=String(audience.get("typed_asked",""))
	audience.erase("typed_asked")
	var outcome:=order(civ_id,asked if option_id=="war_track" and asked in NEEDS_HOME else option_id,false)
	var pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if pid>0: GovernmentPeopleSystem.record_person_memory(pid,"The god gave me the %s with %s: %s" % ["war" if at_war_now else "feud",_name(civ_id),outcome.substr(0,160)],"audience",0.6,{"emotion":"duty"})
	return {"outcome":outcome,"reaction":"pleased" if option_id in ["war_general","war_guard"] else "neutral"}

const TYPED:=[
	["war_track",["where they live","where their home","find their home","find their village","find their camp","find the way","track them home","find them"]],
	["war_chief",["chief","ruler","leader","bring me","capture","their head"]],
	["war_burn",["burn","stores","granary","granaries","raid them","strike them","hit them","their food"]],
	# "Go to war with them", "declare war on them", "attack them": a strike at
	# them (at a home we know; trackers first when we do not). Marked true:
	# when a town is named outright ("Attack Tsaren") it is the court's own
	# order about that town (court_war_orders.names_a_town), not this.
	["war_burn",["attack","go to war","war on","make war","declare war","wage war"],true],
	["war_pursue",["after them","pursue","take back","chase","follow","get it back","hunt them"]],
	["war_guard",["defend","hold","guard","ford","watch","approach","protect","keep them out","wall"]],
	["war_price",["blood price","blood-price","pay for their dead","pay for the dead","pay the price","compensate","make amends"]],
	["war_parley",["peace","truce","talk","parley","messenger","end it","enough","settle"]],
	["war_pay","pay"],
	["war_price","pay"],
	["war_let",["let it pass","leave it","do nothing","bury"]],
	["war_general",["you judge","your judgment","you decide","as you see","your call","do what you"]],
]

static func typed_choice(audience_id:String,text:String)->String:
	## The god's own words mapped onto an order the war leader can carry. A
	## question is discussion, never an order ("Who holds Tsaren?" is not
	## "hold"), and words match whole ("holds", "afford", "repay" are not
	## "hold", "ford", "pay").
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or _war_part(audience).is_empty(): return ""
	if preload("res://scripts/legacy_aims.gd").asks(text): return ""
	var lower:=text.to_lower()
	var open:Dictionary={}
	for option in Hall.options(audience_id):
		if bool(option.get("enabled",true)): open[String(option.id)]=true
	var names_town:=-1
	for row in TYPED:
		var words:Array=row[1] if row[1] is Array else [row[1]]
		var generic:=(row as Array).size()>2 and bool(row[2])
		for word in words:
			if RegEx.create_from_string("\\b%s(s|es)?\\b" % String(word)).search(lower)==null: continue
			if generic:
				if names_town<0: names_town=1 if bool((load("res://scripts/court_war_orders.gd") as GDScript).call("names_a_town",text)) else 0
				if names_town==1: continue
			if open.has(String(row[0])): return String(row[0])
			# Their stores or their chief, at a home nobody has found: the
			# trackers go first, and the war leader says why (NEEDS_HOME).
			if String(row[0]) in NEEDS_HOME and open.has("war_track"):
				audience["typed_asked"]=String(row[0])
				return "war_track"
	return ""
