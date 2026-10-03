extends RefCounted
## GIFTED CHILDREN (geniuses): rare gifts born among every people's children.
##
## The player, 2026-10-02: "randomly births geniuses in your country. You learn
## of their brilliance as children. They are brilliant in any of the 9 game
## layers, and when you find out their genius you get a clear hint of them.
## Architects also included, so you can make a great work if that happens
## with them. Otherwise, they greatly enhance their specialty while they are
## alive." Extremes a little beyond history, never crazy; no free lunch: a gift
## only pays where people do that work.
##
## Every people, by the same rules (docs/STANDING_DESIGN.md section 9), in its
## own WorldSimulation scope: the records live in that scope's
## HistoricalFigures (`geniuses`, `genius_bonus`, `genius_*`), so they save
## with it, and grown geniuses are figures there (extended, not duplicated).
## Each step is a seeded roll at stated odds (docs/ADJUDICATION.md):
##
## 1. BORN. Once a year, the gifted births among that year's births are a
##    Poisson draw with mean RATE x sqrt(births a year): about one every 12
##    years for a people of 300 (some 12 births a year), so with ordinary care
##    (half of them noticed) one seen about every generation (24 years); every
##    3.8 years for 3,000; 0.8 a year for 30,000; 2.6 a year for 300,000.
##    Each has one of the nine works (evenly, nudged by NUDGE toward the work
##    the people do most), a gift 0..1, a sex and a home town. At most
##    MAX_LIVING children and grown at once.
## 2. NOTICED, once, at an age of 6 to 10: chance NOTICE_BASE + NOTICE_CARE x
##    carer cover + NOTICE_TEACH x teacher cover, 10..90 in 100. Carer cover is
##    the carers' own rule (food_care.gd): the cover of full care the engine
##    applies today, full at 8 in 100 of the people on keeping and caring.
##    Teacher cover is the learners at work over TEACHER_SHARE of the people,
##    at most 1. The usual split notices about half. Unnoticed, the child
##    grows up ordinary: no record, no effect. That is the cost of neglect.
## 3. GROWN at 16, a noticed child becomes a figure of the work's calling
##    (FIGURE_ROLE) and greatly enhances that work while alive: strength
##    STRENGTH_BASE..+STRENGTH_SPAN by gift (x PATRON with the god's
##    patronage), felt in full by up to REACH people on the work and by the
##    cube root of REACH / workers beyond: half at 1,600, a third at 5,400
##    (one person can teach and lead only so many; their ways spread slowly).
##    Several gifted in one work combine as 1 - product(1 - each), at most
##    LAYER_CAP. The seam is GameState.effective_workers: each person
##    on the work counts for that much more, the reading every role's output
##    already takes, beside the great works' own benefit.
##    - Keeping watch: nothing reads the watch's effective workers, so a war
##      leader of rare gift adds strength x COMMAND_SHARE to each of their own
##      command skills (HistoricalFigures.general_skill) and is sent first
##      when a war leader is wanted (HistoricalFigures.commander).
##    - Building: a master builder of rare gift asks once to raise a great
##      work (undertaking pitch "genius"; a computer ruler's conception
##      trigger), is chosen first as its master builder and raises its odds
##      (wonder_concept.assess: capability + strength x ARCHITECT_CAPABILITY).
## 4. DEATH by the people's own mortality: each year, a roll at the genius's
##    age from the life table life expectancy reads (GameState
##    life_expectancy_from), so hunger, sickness and poor care take them too.
##
## The player is told of their own gifted children (a Chronicle card) and of a
## known people's gifted grown (contact only). Older saves start with none:
## counting starts the day they first run. Static; preload.

const LAYERS:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
## The calling a gifted child grows into (HistoricalFigures.ROLES).
const FIGURE_ROLE:={"Food":"Agronomist","Survey":"Explorer","Extraction":"Quarrier","Construction":"Architect","Crafting":"Maker","Logistics":"Carrier","Knowledge":"Scholar","Administration":"Physician","Defense":"General"}
## The gift, in the People view's words for the work.
const GIFT:={"Food":"getting food","Survey":"searching the land","Extraction":"cutting and digging","Construction":"building","Crafting":"making","Logistics":"carrying","Knowledge":"learning","Administration":"keeping and caring","Defense":"keeping watch"}
## One person on the work.
const WORKER:={"Food":"food-getter","Survey":"searcher","Extraction":"cutter and digger","Construction":"builder","Crafting":"maker","Logistics":"carrier","Knowledge":"learner","Administration":"keeper and carer","Defense":"fighter"}
## What the court calls them grown.
const TITLE:={"Food":"gifted grower","Survey":"gifted pathfinder","Extraction":"gifted quarrier","Construction":"gifted master builder","Crafting":"gifted maker","Logistics":"gifted carrier","Knowledge":"gifted scholar","Administration":"gifted healer","Defense":"gifted war leader"}
## The Chronicle card's picture (a field of knowledge).
const ART_DOMAIN:={"Food":"nutrition","Survey":"ecology","Extraction":"production","Construction":"infrastructure","Crafting":"production","Logistics":"logistics","Knowledge":"knowledge","Administration":"health","Defense":"security"}
## The byname a band gives them (era_names.gd SKILL_EPITHETS).
const NAME_SKILL:={"Food":"Provisioning","Survey":"Logistics","Extraction":"Construction","Construction":"Construction","Logistics":"Logistics","Knowledge":"Knowledge","Administration":"Administration","Defense":"Defense"}

## Gifted births a year = RATE x sqrt(births a year).
const RATE:=0.024
const NOTICE_MIN_YEARS:=6
const NOTICE_MAX_YEARS:=10
const ADULT_YEARS:=16
const NOTICE_BASE:=0.20
const NOTICE_CARE:=0.35
const NOTICE_TEACH:=0.35
const NOTICE_FLOOR:=0.10
const NOTICE_CEILING:=0.90
## Learners at work, as a share of the people, for full teacher cover (carers
## are reckoned by food_care.gd, CARE_SHARE).
const TEACHER_SHARE:=0.06
## A grown genius's strength: STRENGTH_BASE + STRENGTH_SPAN x gift.
const STRENGTH_BASE:=0.15
const STRENGTH_SPAN:=0.10
## Patronage (HistoricalFigures.support) makes it this many times as much.
const PATRON:=1.2
## People on the work one gifted person reaches in full (cube root beyond).
const REACH:=200.0
## Most all the gifted in one work add together.
const LAYER_CAP:=0.40
## A gifted war leader's strength added to each of their command skills.
const COMMAND_SHARE:=0.5
## A gifted master builder's strength added to a great work's capability.
const ARCHITECT_CAPABILITY:=0.6
## How far the people's own work tilts which gift is born.
const NUDGE:=0.25
## Gifted children and grown alive at once in one people.
const MAX_LIVING:=30
## Dead gifted figures kept when the roster must make room.
const KEEP_DEAD:=48
## A grown genius's figure lasts at most this long (the yearly roll ends it first).
const OLDEST_YEARS:=100
const OLD_AGE:=55
## Name draws for the gifted start here, apart from ordinary figures'.
const NAME_KEY:=500000

# --- The day ---------------------------------------------------------------------

## Called each day a people's figures advance (HistoricalFigures.advance), in
## that people's scope.
static func advance(figures:Node,day:int)->void:
	var state:=WorldSimulation.state
	if state==null:return
	if int(figures.genius_since)<0 or day<int(figures.genius_since):
		figures.genius_since=day
		figures.genius_births_seen=int(state.lifetime_births)
		refresh(figures,state)
		return
	if day-int(figures.genius_since)>=365:_year(figures,state,day)
	_children(figures,state,day)
	refresh(figures,state)

## The year's gifted births and the year's deaths among the gifted.
static func _year(figures:Node,state:Node,day:int)->void:
	var since:=int(figures.genius_since)
	var years:=maxf(1.0/365.0,float(day-since)/365.0)
	var births:=maxi(0,int(state.lifetime_births)-int(figures.genius_births_seen))
	figures.genius_since=day
	figures.genius_births_seen=int(state.lifetime_births)
	_mortality(figures,state,day)
	if births<=0:return
	var rng:=_rng(figures,"births/%d" % day)
	var count:=_poisson(rng,expected_per_year(float(births)/years)*years)
	for i in count:
		if (figures.geniuses as Array).size()>=MAX_LIVING:break
		_born(figures,state,rng,since,day)

## Expected gifted births a year among `births_per_year` births.
static func expected_per_year(births_per_year:float)->float:
	return RATE*sqrt(maxf(0.0,births_per_year))

static func _born(figures:Node,state:Node,rng:RandomNumberGenerator,since:int,day:int)->void:
	figures.genius_serial=int(figures.genius_serial)+1
	var serial:=int(figures.genius_serial)
	var born:=rng.randi_range(maxi(since,day-364),day)
	var g:={"id":"gift_%d" % serial,"serial":serial,"layer":pick_layer(state,rng.randf()),"gift":snappedf(rng.randf(),0.001),"born":born,
		"female":rng.randf()<0.5,"home":_home(state,rng.randf()),"notice_day":born+rng.randi_range(NOTICE_MIN_YEARS*365,NOTICE_MAX_YEARS*365),
		"status":"child","noticed":-1,"name":"","figure_id":"","last_roll":born}
	(figures.geniuses as Array).append(g)
	_count(figures,"born")

## The work a gift is for: the nine evenly, nudged toward the work the people
## do most (weight 1 + NUDGE x (9 x share - 1), 0.5..2). `roll` is 0..1.
static func pick_layer(state:Node,roll:float)->String:
	var weights:=layer_weights(state)
	var total:=0.0
	for layer:String in LAYERS:total+=float(weights[layer])
	var pick:=roll*total
	for layer:String in LAYERS:
		pick-=float(weights[layer])
		if pick<=0.0:return layer
	return String(LAYERS[-1])

static func layer_weights(state:Node)->Dictionary:
	var heads:=0.0
	for layer:String in LAYERS:heads+=maxf(0.0,float(state.population_allocations.get(layer,0)))
	var weights:={}
	for layer:String in LAYERS:
		var share:=maxf(0.0,float(state.population_allocations.get(layer,0)))/heads if heads>0.0 else 1.0/LAYERS.size()
		weights[layer]=clampf(1.0+NUDGE*(LAYERS.size()*share-1.0),0.5,2.0)
	return weights

## A town of this people, by its share of the people; "" before any town.
static func _home(state:Node,roll:float)->String:
	var towns:Array=[]
	var satellites:=0.0
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["",WorldSimulation.actor_id]:continue
		if not bool(city.get("primary",false)):satellites+=maxf(0.0,float(city.get("population_share",0.0)))
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["",WorldSimulation.actor_id]:continue
		var weight:=maxf(0.05,1.0-satellites) if bool(city.get("primary",false)) else maxf(0.0,float(city.get("population_share",0.0)))
		if weight>0.0:towns.append([String(city.get("id","")),weight])
	if towns.is_empty():return ""
	var total:=0.0
	for town:Array in towns:total+=float(town[1])
	var pick:=roll*total
	for town:Array in towns:
		pick-=float(town[1])
		if pick<=0.0:return String(town[0])
	return String(towns[-1][0])

static func home_name(state:Node,id:String)->String:
	for city:Dictionary in state.player_settlements:
		if String(city.get("id",""))==id and id!="":return String(city.get("name","our town"))
	return String(state.settlement_name) if String(state.settlement_name)!="" else "our camp"

## Children reach the age they are noticed or not, and the noticed grow up.
static func _children(figures:Node,state:Node,day:int)->void:
	for g:Dictionary in (figures.geniuses as Array).duplicate():
		if String(g.get("status",""))!="child":continue
		if int(g.noticed)<0:
			if day>=int(g.notice_day):_notice(figures,state,g,day)
		elif day>=int(g.born)+ADULT_YEARS*365:
			_grow(figures,state,g,day)

## The one roll: is the gift seen? Stated odds from today's carers and learners.
static func _notice(figures:Node,state:Node,g:Dictionary,day:int)->void:
	var odds:=notice_parts(state)
	var roll:=_rng(figures,"notice/"+String(g.id)).randf()
	g["notice_roll"]=snappedf(roll,0.0001)
	if roll>=float(odds.chance):
		# Unseen, the child grows up ordinary, one of the many.
		(figures.geniuses as Array).erase(g)
		_count(figures,"missed")
		return
	g.noticed=day
	var traditions:Array=preload("res://scripts/historical_name_generator.gd").POOLS.keys()
	var made:Dictionary=figures.name_identity(NAME_KEY+int(g.serial),bool(g.female),String(traditions[posmod(int(figures.seed_value)+int(g.serial),traditions.size())]),{"skill":String(NAME_SKILL.get(String(g.layer),""))})
	g.name=String(made.get("name","")) if String(made.get("name",""))!="" else "Child of %s" % home_name(state,String(g.home))
	figures.used[String(g.name)]=true
	_count(figures,"noticed")
	_tell_noticed(state,g,day,float(odds.chance))

static func _grow(figures:Node,state:Node,g:Dictionary,day:int)->void:
	var p:Dictionary=figures.create_genius(g,day,home_name(state,String(g.home)))
	if p.is_empty():
		(figures.geniuses as Array).erase(g)
		return
	# The grown stay listed by their figure only (layer and gift live there).
	for key in g.keys():
		if String(key) not in ["id","serial","status","figure_id","last_roll","born"]:g.erase(key)
	g.status="adult"
	g.figure_id=String(p.id)
	_count(figures,"grown")
	refresh(figures,state)
	_tell_grown(figures,state,p,day)

## Each year's deaths among the gifted, at their own ages, from the people's
## own life table this year.
static func _mortality(figures:Node,state:Node,day:int)->void:
	if (figures.geniuses as Array).is_empty():return
	var table:=_life_table(state)
	for g:Dictionary in (figures.geniuses as Array).duplicate():
		var from:=maxi(int(g.get("last_roll",g.born)),int(g.born))
		g.last_roll=day
		if day<=from:continue
		var survive:=1.0
		var t:=from
		while t<day:
			var age:=(t-int(g.born))/365
			var end:=mini(day,int(g.born)+(age+1)*365)
			survive*=pow(1.0-annual_death_chance(table,age),float(end-t)/365.0)
			t=end
		if _rng(figures,"death/%s/%d" % [String(g.id),day]).randf()>=1.0-survive:continue
		var age_now:=(day-int(g.born))/365
		if String(g.status)=="adult":
			(figures.geniuses as Array).erase(g)
			figures.record_death(String(g.figure_id),day,"old age" if age_now>=OLD_AGE else "illness")
		else:
			(figures.geniuses as Array).erase(g)
			_count(figures,"lost_young")
			if int(g.noticed)>=0:_tell_lost(state,g,day,age_now)

## This year's reading of the life table (GameState.life_expectancy_from's).
static func _life_table(state:Node)->Dictionary:
	var inputs:Dictionary=state.life_inputs()
	var condition:=lerpf(1.90,0.64,clampf(float(inputs.get("health",0.72)),0.0,1.0))*lerpf(2.40,0.78,clampf(float(inputs.get("food",0.82)),0.0,1.0))*lerpf(1.65,0.88,clampf(float(inputs.get("housing",1.0)),0.0,1.0))
	return {"condition":condition,"hazard":maxf(0.0,float(inputs.get("hazard",0.0))),"care":state.care_profile(),"base":state.BASELINE_HAZARD_BY_AGE}

## The chance of dying within a year at `age`, by that reading.
static func annual_death_chance(table:Dictionary,age:int)->float:
	var base:Array=table.base
	var at:=clampi(age,0,base.size()-1)
	var hazard:=float(base[at])*preload("res://scripts/early_life_conditions.gd").age_multiplier(table.care,at,float(table.condition))
	return clampf(hazard*float(table.condition)+float(table.hazard),0.0001,0.98)

# --- What the grown add ------------------------------------------------------------

## Every work's share more from its gifted grown, today: {role: 0..LAYER_CAP}.
## Drops the grown who died by other hands (battle, the god's judgment).
static func refresh(figures:Node,state:Node)->void:
	if (figures.geniuses as Array).is_empty():
		if not (figures.genius_bonus as Dictionary).is_empty():figures.genius_bonus={}
		return
	var kept:={}
	for g:Dictionary in (figures.geniuses as Array).duplicate():
		if String(g.get("status",""))!="adult":continue
		var p:Dictionary=figures.by_id(String(g.figure_id))
		if p.is_empty() or String(p.get("status",""))=="dead":
			(figures.geniuses as Array).erase(g)
			continue
		if String(p.status)!="living":continue
		var layer:=String((p.genius as Dictionary).get("layer",""))
		if layer=="Defense" or layer not in LAYERS:continue
		kept[layer]=float(kept.get(layer,1.0))*(1.0-contribution(p,state))
	var table:={}
	for layer in kept:table[layer]=snappedf(minf(LAYER_CAP,1.0-float(kept[layer])),0.0001)
	figures.genius_bonus=table

## A grown genius's strength (patronage included), before reach.
static func strength(p:Dictionary)->float:
	var info:Dictionary=p.get("genius",{}) if p.get("genius") is Dictionary else {}
	if info.is_empty():return 0.0
	return (STRENGTH_BASE+STRENGTH_SPAN*clampf(float(info.get("gift",0.0)),0.0,1.0))*(PATRON if bool(p.get("supported",false)) else 1.0)

## A gift's strength before patronage, for a child not yet grown.
static func strength_of_gift(gift:float)->float:
	return STRENGTH_BASE+STRENGTH_SPAN*clampf(gift,0.0,1.0)

## How much of the work one gifted person reaches: 1 up to REACH people on
## it, the cube root of REACH / people beyond.
static func reach(state:Node,layer:String)->float:
	var workers:=maxf(1.0,float(state.population_allocations.get(layer,0)))
	return minf(1.0,pow(REACH/workers,1.0/3.0))

static func contribution(p:Dictionary,state:Node)->float:
	return strength(p)*reach(state,String((p.genius as Dictionary).get("layer","")))

## The share more each person on `role` counts for (GameState.effective_workers).
## Hot: a dictionary read in the current scope.
static func bonus(state:Object,role:String)->float:
	var figures:Variant=WorldSimulation.figures if state==WorldSimulation.state else figures_of(state)
	if figures==null:return 0.0
	var table:Dictionary=figures.genius_bonus
	return float(table.get(role,0.0)) if not table.is_empty() else 0.0

## The figures of the people whose GameState this is, in any scope.
static func figures_of(state:Object)->Node:
	if state==GameState:return HistoricalFigures
	for actor:Dictionary in WorldSimulation.actors.values():
		var systems:Dictionary=actor.get("systems",{})
		if systems.get("GameState")==state:return systems.get("HistoricalFigures")
	return null

## A gifted war leader's lift to each of their command skills while living.
static func command_bonus(p:Dictionary)->float:
	if not p.get("genius") is Dictionary or String(p.get("status",""))!="living":return 0.0
	if String((p.genius as Dictionary).get("layer",""))!="Defense":return 0.0
	return strength(p)*COMMAND_SHARE

## A great work's master builder's lift to its capability (wonder_concept.assess).
static func architect_capability(architect:Dictionary)->float:
	return clampf(float(architect.get("genius",0.0)),0.0,1.0)*ARCHITECT_CAPABILITY

## The figure talent a gift makes (0.90..0.98).
static func talent_of(gift:float)->float:
	return snappedf(0.90+0.08*clampf(gift,0.0,1.0),0.001)

## The chance a gifted child is noticed today, and why:
## {chance, care, teach, learners, people}. Carers count by the carers' one
## rule (food_care.gd): the cover of full care the engine applies today, and
## for `more_carers` the cover they would settle toward, as food_care's own
## "ten more" reckons it. Learners count as the work they do (effective
## workers: a gifted scholar teaches more).
static func notice_parts(state:Node,more_carers:float=0.0,more_learners:float=0.0)->Dictionary:
	var people:=maxf(1.0,float(state.population_exact))
	var care:=care_cover(state,more_carers)
	var learners:=maxf(0.0,float(state.effective_workers("Knowledge")))+more_learners
	var teach:=clampf(learners/(people*TEACHER_SHARE),0.0,1.0)
	return {"chance":clampf(NOTICE_BASE+NOTICE_CARE*care+NOTICE_TEACH*teach,NOTICE_FLOOR,NOTICE_CEILING),"care":care,"teach":teach,"learners":learners,"people":people}

## The carers' cover of full care (food_care.gd): applied today, settling
## toward the hands on keeping and caring; before the first day's care is
## reckoned, what those hands give at once.
static func care_cover(state:Node,more_carers:float=0.0)->float:
	var FoodCare:=preload("res://scripts/food_care.gd")
	var target:=FoodCare.care_target_of(state)
	var care:=FoodCare.care_cover_of(state) if (state.early_care as Dictionary).has("carer_cover") else target
	if more_carers>0.0:care+=FoodCare.care_cover(FoodCare.keepers_of(state)+more_carers,maxf(1.0,float(state.population_exact)))-target
	return clampf(care,0.0,1.0)

# --- Great works ---------------------------------------------------------------------

## A grown master builder of rare gift who has not yet led a work: the
## trigger that moves a people to raise one ({} when none). `mark`: the
## player's pitch asks once (a computer ruler is moved until one is begun).
static func architect_trigger(figures:Node,day:int,mark:bool=true)->Dictionary:
	if figures==null:return {}
	var busy:Array=(figures.assignments as Dictionary).values()
	for g:Dictionary in figures.geniuses:
		if String(g.get("status",""))!="adult":continue
		var p:Dictionary=figures.by_id(String(g.figure_id))
		if p.is_empty() or String(p.get("status",""))!="living" or String(p.get("role",""))!="Architect" or String(p.id) in busy:continue
		var info:Dictionary=p.genius
		if int(info.get("led",-1))>=0 or (mark and int(info.get("pitched",-1))>=0):continue
		if mark:info["pitched"]=day
		return {"kind":"genius","day":day,"text":"%s, our gifted master builder, would raise a great work" % String(p.name),"figure_id":String(p.id)}
	return {}

# --- Words ----------------------------------------------------------------------------

static func layer_of(p:Dictionary)->String:
	return String((p.get("genius",{}) as Dictionary).get("layer","")) if p.get("genius") is Dictionary else ""

## "Gifted master builder": what the court calls a grown genius.
static func court_title(p:Dictionary)->String:
	var title:=String(TITLE.get(layer_of(p),"gifted one"))
	return title.substr(0,1).to_upper()+title.substr(1)

## What the gift does now, in a few plain words (the court's fact sheet).
static func gift_words(p:Dictionary,state:Node=null)->String:
	var layer:=layer_of(p)
	if layer=="":return ""
	var s:Node=state if state!=null else WorldSimulation.state
	if layer=="Defense":
		return "a rare gift for keeping watch: when leading, each command skill runs %d in 100 above their own" % roundi(command_bonus(p)*100.0)
	return "a rare gift for %s: every %s counts for %d in 100 more while they live" % [String(GIFT[layer]),String(WORKER[layer]),roundi(contribution(p,s)*100.0)]

## What the god's patronage does for a grown genius, in plain words with the
## engine's numbers (HistoricalFigures.support: three places at most). Their
## gift is a fifth stronger (PATRON); discoveries in their field, if their
## calling has one, come quicker by their patronage lift (HistoricalFigures
## patron_lift; a field gains at most 40 in 100 from all it supports); a war
## leader's skills rise by a fifth of that lift too; a great work begun under
## a supported master builder is a little likelier to stand.
static func patronage_words(figures:Node,p:Dictionary,state:Node=null)->String:
	var layer:=layer_of(p)
	if layer=="":return ""
	var s:Node=state if state!=null else WorldSimulation.state
	var on:=bool(p.get("supported",false))
	var lift:=float(figures.patron_lift(p))
	var her:="her" if String(p.get("gender",""))=="woman" else "his"
	var she:="she" if String(p.get("gender",""))=="woman" else "he"
	var gift:=command_bonus(p) if layer=="Defense" else contribution(p,s)
	var plain:=gift/PATRON if on else gift
	var helped:=plain*PATRON
	var verb:=func(word:String)->String:return word+("s" if on else "")
	var parts:PackedStringArray=[]
	if layer=="Defense":
		parts.append("%s %s lead over an ordinary war leader from %d to %d in 100 on each skill" % [verb.call("raise"),her,roundi(plain*100.0),roundi((helped+lift*0.2)*100.0)])
	else:
		parts.append("%s %s gift a fifth stronger (%d in 100 instead of %d)" % [verb.call("make"),her,roundi(helped*100.0),roundi(plain*100.0)])
	var field:=String(((load("res://scripts/chronicle.gd") as GDScript).get_script_constant_map().get("DOMAIN_NAMES",{}) as Dictionary).get(String(p.get("domain","")),"")).replace(" & "," and ")
	if field!="":parts.append("%s our discoveries in %s by %d in 100 while %s lives" % [verb.call("quicken"),field,roundi(lift*100.0),she])
	if layer=="Construction":parts.append("%s a great work begun under %s a little likelier to stand" % [verb.call("make"),"her" if she=="she" else "him"])
	var joined:=" and ".join(parts) if parts.size()<3 else ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[-1]
	return ("Your patronage %s." if on else "Your patronage (three at most at once) would %s.") % joined

## The hint the player reads when a child is noticed, and when grown.
static func hint(layer:String,share:float,pronoun:String,grown:bool)->String:
	var their:="her" if pronoun=="she" else "his"
	if layer=="Defense":
		return "%s %s our fighters as few can: when %s leads, %s command, tactics, marching and hold on the fighters each run about %d in 100 above an ordinary war leader's" % [pronoun,"leads" if grown else "will lead",pronoun,their,roundi(share*100.0)]
	var line:="every %s counts for %d in 100 more while %s lives" % [String(WORKER[layer]),roundi(share*100.0),pronoun] if grown else "%s will make every %s count for about %d in 100 more while %s lives" % [pronoun,String(WORKER[layer]),roundi(share*100.0),pronoun]
	if layer=="Construction":line+=", and %s may ask to raise a great work: with %s as master builder it is likelier to stand" % [pronoun,"her" if pronoun=="she" else "him"]
	return line

const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]
static func number_word(n:int)->String:
	return String(NUMBER_WORDS[n]) if n>=0 and n<NUMBER_WORDS.size() else str(n)

static func _given(name:String)->String:
	return name.get_slice(" ",0)

static func _player_scope()->bool:
	return WorldSimulation.actor_id=="player"

static func _chronicle()->GDScript:
	return load("res://scripts/chronicle.gd") as GDScript

## The noticed child: a card, once. Only the god's own people are told.
static func _tell_noticed(state:Node,g:Dictionary,day:int,chance:float)->void:
	if not _player_scope():return
	var layer:=String(g.layer)
	var age:=(day-int(g.born))/365
	var she:="she" if bool(g.female) else "he"
	var town:=home_name(state,String(g.home))
	var share:=strength_of_gift(float(g.gift))*(COMMAND_SHARE if layer=="Defense" else reach(state,layer))
	var years:=maxi(1,ADULT_YEARS-age)
	# The odds in plain words: of the children born with such a gift, how many
	# our carers and learners spot (notice_parts), and what more of them would do.
	var text:="%s, a %s of %s in %s, shows a rare gift for %s. Grown, in %s %s, %s. We were lucky to see it: with the carers and learners we have now, about %d in 100 gifted children are spotted, and the ones we miss grow up ordinary, their gift lost. More carers or learners would spot more." % [String(g.name),"girl" if bool(g.female) else "boy",number_word(age),town,String(GIFT[layer]),number_word(years),"year" if years==1 else "years",hint(layer,share,she,false),roundi(chance*100.0)]
	_chronicle().record({"key":"genius:%s" % String(g.id),"day":day,"title":"A gifted child in %s" % town,"text":text,"tier":"moment","kind":"birth","domain":String(ART_DOMAIN[layer]),"art":{"domain":String(ART_DOMAIN[layer])},"fold":false})

static func _tell_grown(figures:Node,state:Node,p:Dictionary,day:int)->void:
	var layer:=layer_of(p)
	var she:="she" if String(p.get("gender",""))=="woman" else "he"
	if _player_scope():
		var share:=command_bonus(p) if layer=="Defense" else contribution(p,state)
		var text:="%s of %s, the child with a gift for %s, is grown. From today %s. %s" % [String(p.name),String(p.get("origin","our town")),String(GIFT[layer]),hint(layer,share,she,true),patronage_words(figures,p,state)]
		_chronicle().record({"key":"genius-grown:%s" % String(p.id),"day":day,"title":"%s comes of age" % _given(String(p.name)),"text":text,"tier":"notice","kind":"court","domain":String(ART_DOMAIN[layer]),
			"action":{"kind":"court","focus":{"figure_id":String(p.id)}}})
		return
	# A known people's gifted grown: word travels only where there is contact.
	var owner:=String(WorldSimulation.actor_id)
	var civ_name:=""
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.get("id",""))!=owner:continue
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=1:civ_name=String(civ.get("name",""))
		break
	if civ_name=="":return
	var told:="Word comes from the %s: %s, a %s, has come of age among them." % [civ_name,String(p.name),String(TITLE[layer])]
	var key:="genius-foreign:%s:%s" % [owner,String(p.id)]
	WorldSimulation.scoped("player",func()->void:
		_chronicle().record({"key":key,"day":day,"title":"A %s among the %s" % [String(TITLE[layer]),civ_name],"text":told,"tier":"notice","kind":"contact","domain":String(ART_DOMAIN[layer]),"fold_as":"foreign_gift"}))

static func _tell_lost(state:Node,g:Dictionary,day:int,age:int)->void:
	if not _player_scope():return
	var she:="her" if bool(g.female) else "him"
	_chronicle().record({"key":"genius-lost:%s" % String(g.id),"day":day,"title":"A gifted child is lost","tier":"notice","kind":"death",
		"text":"%s of %s, the child with a gift for %s, has died at %s. The gift is lost with %s." % [String(g.name),home_name(state,String(g.home)),String(GIFT[String(g.layer)]),number_word(age),she]})

## A grown genius's early life, for the figures' book.
static func biography(p:Dictionary)->String:
	var info:Dictionary=p.genius
	var layer:=String(info.get("layer",""))
	var she:="She" if String(p.get("gender",""))=="woman" else "He"
	var noticed_age:=maxi(0,(int(info.get("noticed",p.emerged))-int(p.born))/365)
	return "%s was born in %s. As a child of %s %s was seen to have a rare gift for %s, and came of age at %d.\n\n%s\n\n%s is %s, with an ambition to %s. %s" % [String(p.name),String(p.get("origin","our town")),number_word(noticed_age),she.to_lower(),String(GIFT.get(layer,"the work")),ADULT_YEARS,String(p.get("turning_point","")),she,String(p.get("temperament","")),String(p.get("motive","")),gift_words(p).substr(0,1).to_upper()+gift_words(p).substr(1)+"."]

## The People view's line under a work (twelve words or so); "" when none.
static func row_words(role:String)->String:
	var figures:=WorldSimulation.figures
	if figures==null:return ""
	var names:PackedStringArray=[]
	for p:Dictionary in grown_in(figures,role):names.append(_given(String(p.name)))
	if not names.is_empty():
		if role=="Defense":return "Gifted %s leads fighters %d in 100 above most." % [" and ".join(names),roundi(command_bonus(grown_in(figures,role)[0])*100.0)]
		return "Gifted %s: each counts for %d in 100 more." % [" and ".join(names),roundi(float(figures.genius_bonus.get(role,0.0))*100.0)]
	for g:Dictionary in figures.geniuses:
		if String(g.get("status",""))=="child" and int(g.get("noticed",-1))>=0 and String(g.get("layer",""))==role:
			return "A gifted child, %s, will grow up to this work." % _given(String(g.name))
	return ""

## The living grown gifted of a work.
static func grown_in(figures:Node,role:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for g:Dictionary in figures.geniuses:
		if String(g.get("status",""))!="adult":continue
		var p:Dictionary=figures.by_id(String(g.figure_id))
		if not p.is_empty() and String(p.get("status",""))=="living" and layer_of(p)==role:out.append(p)
	return out

## The task explanation's lines (task_impact.gd of): what the gifted add to
## this work now, the children coming, and for learning and keeping and
## caring, the chance a gifted child is noticed and what ten more would do.
static func explain(role:String,result:Dictionary)->void:
	var figures:=WorldSimulation.figures
	if figures==null:return
	var state:=WorldSimulation.state
	var lines:Array=result.get("lines",[]) if result.get("lines") is Array else []
	var grown:=grown_in(figures,role)
	for p:Dictionary in grown:
		var she:="she" if String(p.get("gender",""))=="woman" else "he"
		var age:=(int(state.elapsed_days)-int(p.born))/365
		if role=="Defense":
			var lift:=command_bonus(p)
			lines.append(_line("Gifted %s" % _given(String(p.name)),"+%d in 100" % roundi(lift*100.0),"%s, a gifted war leader (%d), leads with command, tactics, marching and hold on the fighters each %d in 100 above their own, and is sent first when a war leader is wanted. %s" % [String(p.name),age,roundi(lift*100.0),patronage_words(figures,p,state)],"good"))
			continue
		var share:=contribution(p,state)
		var full:=reach(state,role)>=1.0
		lines.append(_line("Gifted %s" % _given(String(p.name)),"+%d in 100" % roundi(share*100.0),
			"%s, a %s (%d), makes each person on this work count for %d in 100 more while %s lives. %s %s" % [String(p.name),String(TITLE[role]),age,roundi(share*100.0),she,
			"All of them feel it in full." if full else "One person reaches %d in full; with %d here it thins." % [int(REACH),roundi(float(state.population_allocations.get(role,0)))],
			patronage_words(figures,p,state)],"good"))
	if grown.size()>1 and role!="Defense":
		lines.append(_line("All the gifted","+%d in 100" % roundi(float(figures.genius_bonus.get(role,0.0))*100.0),"Together they add %d in 100 (at most %d)." % [roundi(float(figures.genius_bonus.get(role,0.0))*100.0),roundi(LAYER_CAP*100.0)],"good"))
	for g:Dictionary in figures.geniuses:
		if String(g.get("status",""))!="child" or int(g.get("noticed",-1))<0 or String(g.get("layer",""))!=role:continue
		var child_age:=(int(state.elapsed_days)-int(g.born))/365
		lines.append(_line("A gifted child","%s, %d" % [_given(String(g.name)),child_age],"%s will be grown in %s." % [String(g.name),_years(ADULT_YEARS-child_age)],"plain"))
	if role in ["Knowledge","Administration"]:
		var now:=notice_parts(state)
		var more:=notice_parts(state,10.0 if role=="Administration" else 0.0,10.0 if role=="Knowledge" else 0.0)
		var births:=float(state.rolling_vital_balance(365).get("births",0))
		var per_year:=expected_per_year(births)
		var born:="A gifted child is born about once in %d years among our %d births a year." % [roundi(1.0/per_year),roundi(births)] if per_year>0.0 else "No child was born to us this past year, so no gifted one either."
		lines.append(_line("Gifted children noticed","%d in 100" % roundi(float(now.chance)*100.0),
			"%s With carers giving %d in 100 of full care and %d learners at work, about %d in 100 gifted children are spotted; the ones we miss grow up ordinary, their gift lost. With ten more on this work: %d in 100." % [born,roundi(float(now.care)*100.0),roundi(float(now.learners)),roundi(float(now.chance)*100.0),roundi(float(more.chance)*100.0)],"plain"))
	result["lines"]=lines

static func _years(n:int)->String:
	return "%s %s" % [number_word(maxi(1,n)),"year" if maxi(1,n)==1 else "years"]

static func _line(label:String,value:String,words:String,tone:String)->Dictionary:
	return {"label":label,"value":value,"words":words,"tone":tone}

# --- Validation -----------------------------------------------------------------------

## A grown genius's figure fields (HistoricalFigures.import_state).
static func valid_figure(p:Dictionary)->bool:
	if not p.get("genius") is Dictionary:return false
	var info:Dictionary=p.genius
	if String(info.get("layer","")) not in LAYERS or String(FIGURE_ROLE[String(info.layer)])!=String(p.get("role","")):return false
	for key in ["gift"]:
		if not (info.get(key) is float or info.get(key) is int) or not is_finite(float(info[key])) or float(info[key])<0.0 or float(info[key])>1.0:return false
	for key in ["noticed","grown","pitched","led"]:
		if info.has(key) and not (info[key] is int or info[key] is float):return false
	return info.get("home","") is String

# --- Rolls ----------------------------------------------------------------------------

static func _rng(_figures:Node,key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s|genius|%s" % [int(WorldSimulation.state.world_seed),String(WorldSimulation.actor_id),key])
	return rng

## A Poisson draw (Knuth), for small means.
static func _poisson(rng:RandomNumberGenerator,mean:float)->int:
	if mean<=0.0:return 0
	var limit:=exp(-minf(mean,30.0))
	var product:=rng.randf()
	var count:=0
	while product>limit and count<64:
		count+=1
		product*=rng.randf()
	return count

static func _count(figures:Node,key:String)->void:
	var tally:Dictionary=figures.genius_tally
	tally[key]=int(tally.get(key,0))+1
