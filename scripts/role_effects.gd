extends RefCounted
## WHAT EACH WORK DOES, IN ONE LINE (docs/PEOPLE_FIRST.md, F): the People
## view's line under every task, what the people on it do now and what ten
## more would do, in plain short words with the engine's own numbers.
##
## One function per role, each returning {now, plus_ten}. Each reads today's
## engine metrics by the rule the engine applies (the constants are
## task_impact.gd's, which names each rule's source). As the workstreams land
## their own role_effect(role) (fresh food and carers: food_system.gd /
## early_life_conditions.gd; survey cover: resource_system.gd; goods:
## civilian_goods.gd; the watch as the army: military_campaign.gd; learning
## without a cap: discovery_system.gd), each function here is re-pointed with
## one line. "Ten more" is always the gain over now. Each line keeps to
## twelve words or fewer, as the People view's labels do. The People view
## reads all nine through all_cached(): worked out again when the work changes
## or a week has passed, not every day. Static; preload.

const Impact:=preload("res://scripts/task_impact.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")
const CIVIC:=preload("res://scripts/civic_building_effects.gd")
const Mechanics:=preload("res://scripts/research_mechanics.gd")

## "Ten more" is this many people.
const MORE:=10
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
## Days the People view keeps a reading while the work stands as it is.
const CACHE_DAYS:=7

static var _cache_key:=""
static var _cache:Dictionary={}

## All nine roles' lines, kept while the work stands and for CACHE_DAYS:
## {role: {now, plus_ten}}.
static func all_cached()->Dictionary:
	var state=_state()
	# A gifted person coming of age or dying changes the work at once (geniuses.gd).
	var key:="%s|%d|%d|%d|%d|%d" % [String(WorldSimulation.actor_id),int(state.world_seed),int(state.elapsed_days)/CACHE_DAYS,int(state.population_total),state.population_allocations.hash(),WorldSimulation.figures.genius_bonus.hash() if WorldSimulation.figures!=null else 0]
	if key!=_cache_key:
		var fresh:={}
		for role:String in ROLES:fresh[role]=of(role)
		_cache=fresh
		_cache_key=key
	return _cache

static func of(role:String)->Dictionary:
	match role:
		"Food":return food()
		"Survey":return survey()
		"Extraction":return extraction()
		"Construction":return construction()
		"Crafting":return crafting()
		"Logistics":return logistics()
		"Knowledge":return knowledge()
		"Administration":return administration()
		"Defense":return defense()
	return {"now":"","plus_ten":""}

# --- Getting food -------------------------------------------------------------------

## Food brought in a day against what is eaten; ten more bring about their
## share at today's yield a getter (less as the wild grounds wear).
static func food()->Dictionary:
	var metrics:Dictionary=_state().simulation_metrics
	var harvest:Dictionary=metrics.get("food_harvest",{}) if metrics.get("food_harvest") is Dictionary else {}
	var brought:=0.0
	for kind:String in ["Fresh plants","Fresh meat","Fish","Dry staples"]:brought+=float(harvest.get(kind,0.0))
	# Before the harvest is told by kind, the day's count of it.
	if brought<=0.0:brought=float(metrics.get("food_production",0.0))
	var eaten:=float(metrics.get("food_consumption",0.0))
	var getters:=_workers("Food")
	if getters<=0.0:
		return _row("Nobody gets food; the stores only run down.","Ten more would bring food in again.")
	if brought<=0.0 and eaten<=0.0:
		return _row("The day's food is counted at dawn.","Ten more would bring in more each day.")
	var each:=brought/getters
	return _row("%s rations a day come in; %s are eaten." % [_whole(brought),_whole(eaten)],
		"Ten more: about %s more a day, less as grounds wear." % _whole(each*_ten("Food")))

# --- Searching the land -------------------------------------------------------------

## How much faster hidden deposits turn up than with nobody searching
## (resource_system.gd clues: 0.5 + effort + what research helps, effort =
## searchers ÷ 6 × survey skill).
static func survey()->Dictionary:
	var searchers:=_workers("Survey")
	var inputs:Dictionary=ResourceSystem._local_survey_inputs()
	var helped:=float(inputs.get("nature",0.0))+float(inputs.get("material",0.0))
	var per:=float(WorldSimulation.consequences.survey_factor())/6.0
	var pace:=func(effort:float)->float:return (0.5+effort+helped)/maxf(0.01,0.5+helped)
	var hidden:=(Impact._deposits_by_stage().hidden as Array).size()
	var now:=float(pace.call(per*searchers))
	var more:=float(pace.call(per*(searchers+_ten("Survey"))))
	if hidden==0:
		return _row("Nothing left here they know how to find.","Ten more: nothing new until they learn new kinds.")
	if searchers<=0.0:
		return _row("Nobody searches; %s finds show only by chance." % _count(hidden),"Ten more: finds come %s times as fast." % _one(more))
	return _row("Finds come %s times as fast as with nobody searching." % _one(now),"Ten more: finds come %s times as fast as now." % _one(more/maxf(0.01,now)))

# --- Cutting and digging ------------------------------------------------------------

## Loads cut and dug a day; ten more bring in about their share at today's
## yield a cutter, while there are open deposits to work.
static func extraction()->Dictionary:
	var flows:Dictionary=_state().material_metrics
	var cut:=float(flows.get("extracted_today",0.0))
	var cutters:=_workers("Extraction")
	if cutters<=0.0:
		return _row("Nobody cuts or digs: no timber, stone or clay.","Ten more would work the open deposits again.")
	if cut<=0.0:
		return _row("Nothing cut today: no open deposit is worked.","Ten more: nothing until a deposit is opened.")
	return _row("%s loads cut and dug a day." % _whole(cut),"Ten more: about %s more loads a day." % _whole(cut/cutters*_ten("Extraction")))

# --- Building -----------------------------------------------------------------------

## The town's work in hand, at today's pace (settlement_construction.gd
## daily_work: builders ÷ 8 × crews × pace), and with ten more.
static func construction()->Dictionary:
	var state=_state()
	var builders:=_workers("Construction")
	var pace:=Construction.daily_work()
	var per:=pace/builders if builders>0.0 else float(state.simulation_metrics.get("labor_efficiency",.72))/8.0*(.82+float(state.population_allocations.get("Logistics",0))/30.0+float(state.population_allocations.get("Crafting",0))/50.0)
	var faster:=pace+per*_ten("Construction")
	var project:Dictionary=Construction._current_settlement_project()
	if not project.is_empty():
		var done:=float(state.settlement_projects.get(String(project.name),0.0))
		var left:=maxf(0.0,float(project.days)-done)
		var name:=String(project.name)
		if pace<=0.0:return _row("Nobody builds: the %s stands unfinished." % name,"Ten more: done in %s." % Impact._days(left/maxf(0.0001,faster)))
		return _row("The %s: %s left." % [name,Impact._days(left/pace)],"Ten more: done %s sooner." % Impact._days(left/pace-left/maxf(0.0001,faster)))
	if Construction.housing_under_way():
		var homes:=Construction.housing_work_per_day()
		var homes_more:=homes+homes/maxf(0.01,builders)*_ten("Construction") if builders>0.0 else homes
		var batch:=Construction.HOUSING_BATCH_WORK
		return _row("New homes: %d places every %s." % [Construction.housing_batch_places(),Impact._days(batch/maxf(0.0001,homes))],
			"Ten more: each batch %s sooner." % Impact._days(batch/maxf(0.0001,homes)-batch/maxf(0.0001,homes_more)))
	# Upkeep: builders at 5 in 100 of the people mend the town's monthly wear.
	var pop:=_pop()
	var mending:float=Mechanics.mending_factor()
	var monthly:=func(people:float)->float:return Impact.BUILD_MEND*clampf(people/maxf(1.0,pop*Impact.BUILD_UPKEEP_SHARE),0.0,1.0)*mending-Impact.BUILD_WEAR
	return _row("No work waits; repair moves %s points a month." % Impact._signed(float(monthly.call(builders))*100.0),
		"Ten more: %s points a month." % Impact._signed((float(monthly.call(builders+_ten("Construction")))-float(monthly.call(builders)))*100.0))

# --- Making -------------------------------------------------------------------------

## The goods makers make a day and their worth, arms while the watch lacks
## them, and what ten more makers would add (civilian_goods.gd role_effect).
static func crafting()->Dictionary:
	return Goods.role_effect("Crafting")

# --- Carrying -----------------------------------------------------------------------

## Water fetched against the need (resource_system.gd: each carrier about
## 28 × pace ÷ (1 + walk × 0.16) a day) and how smoothly things move
## (consequence_engine.gd: carriers ÷ 8 in 100 of the people × 55 points).
static func logistics()->Dictionary:
	var state=_state()
	var water:Dictionary=state.water_metrics
	var pop:=_pop()
	var km:=float(water.get("source_distance_km",-1.0))
	var walk:=maxf(0.0,km)*Mechanics.water_walk_factor()
	var labor:=clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)
	var each:=Impact.CARRIER_WATER*labor/(1.0+walk*0.16)*(1.0+clampf(WorldSimulation.discovery.effect("haul_capacity"),-0.4,1.5)) if km>=0.0 else 0.0
	var needed:=float(water.get("total_required_today",water.get("required_today",0.0)))
	var collected:=float(water.get("collected_today",0.0))
	var lift:=func(people:float)->float:return people/maxf(1.0,pop*Impact.CARRIER_SHARE)*Impact.CARRIER_POINTS*100.0
	var raw:=_raw("Logistics")
	var moving:=roundi(float(lift.call(raw+MORE))-float(lift.call(raw)))
	var water_now:=("water %d of 100 needed" % roundi(minf(1.0,collected/needed)*100.0)) if needed>0.0 else ("no water source known" if km<0.0 else "water counted at dawn")
	var water_more:=("about %s more water a day" % _whole(each*_ten("Logistics"))) if each>0.0 else "no water source known"
	return _row("Moving things +%d points; %s." % [roundi(float(lift.call(raw))),water_now],"Ten more: +%d points, %s." % [moving,water_more])

# --- Learning -----------------------------------------------------------------------

## What the people know, a year (consequence_engine.gd knowledge gain:
## learners × pace × attention ÷ (92 × people, at least 3000)), the questions
## worked at once and how much faster ten more make the research
## (discovery_system.gd role_effect: learning without a cap, goods counted).
static func knowledge()->Dictionary:
	var state=_state()
	var learners:=_workers("Knowledge")
	var pop:=_pop()
	var asked:=Research600.keepers_asked(state.research_allocations)
	var labor:=float(state.simulation_metrics.get("labor_efficiency",0.72))
	var rate:=(1.0+WorldSimulation.discovery.effect("knowledge_rate"))*lerpf(0.55,1.45,float(state.combined_intelligence))
	var gain:=func(people:float)->float:
		var fit:=1.0 if asked<=maxf(1.0,floorf(people)) else clampf(people/maxf(1.0,asked),0.15,1.0)
		return people*labor*fit/maxf(3000.0,pop*92.0)*rate*365.0*100.0
	var more:=learners+_ten("Knowledge")
	var research:Dictionary=WorldSimulation.discovery.role_effect("Knowledge",_ten("Knowledge"))
	return _row("What we know: +%s points a year; %s questions at once." % [_points(float(gain.call(learners))),_count(int(research.get("teams",0)))],
		"Ten more learners: +%s points a year, research %s." % [_points(float(gain.call(more))-float(gain.call(learners))),faster(float(research.get("pace_gain",0.0)))])

## A research pace gain in a few words: "61 in 100 faster", "twice as fast".
static func faster(gain:float)->String:
	if gain>=0.995:return "%s times as fast" % _one(1.0+gain)
	if gain>=0.01:return "%d in 100 faster" % roundi(gain*100.0)
	return "a little faster" if gain>0.0 else "no faster"

# --- Keeping and caring -------------------------------------------------------------

## What keepers add to how the people hold together and trust the chiefs
## (consequence_engine.gd admin coverage: keepers × the hall's reach ÷ 3.5 in
## 100 of the people, up to 1.25; cohesion 20 points, trust 10 a unit).
static func administration()->Dictionary:
	var pop:=_pop()
	var reach:=1.0+CIVIC.effect("admin_reach")
	var keepers:=_workers("Administration")
	var cover:=func(people:float)->float:return clampf(people*reach/maxf(1.0,pop*Impact.STEWARD_SHARE),0.0,1.25)
	var now:=float(cover.call(keepers))
	var more:=float(cover.call(keepers+_ten("Administration")))
	var later:="Ten more: cohesion +%d, trust +%d." % [roundi((more-now)*Impact.STEWARD_COHESION*100.0),roundi((more-now)*Impact.STEWARD_TRUST*100.0)]
	if now>=1.25:later="Ten more: nothing more; they are full at %s." % _count(ceili(pop*Impact.STEWARD_SHARE*1.25/reach))
	return _row("Cohesion +%d points, trust in the chiefs +%d." % [roundi(now*Impact.STEWARD_COHESION*100.0),roundi(now*Impact.STEWARD_TRUST*100.0)],later)

# --- Keeping watch ------------------------------------------------------------------

## The watch is the army (watch_military.gd role_effect): how many keep
## watch and guard home, and the safety ten more lift the people toward.
static func defense()->Dictionary:
	return preload("res://scripts/watch_military.gd").role_effect(WorldSimulation.military)

# --- Helpers ------------------------------------------------------------------------

static func _row(now:String,plus_ten:String)->Dictionary:
	return {"now":now,"plus_ten":plus_ten}

static func _state()->Variant:
	return WorldSimulation.state

static func _workers(role:String)->float:
	return maxf(0.0,float(_state().effective_workers(role)))

static func _raw(role:String)->float:
	return maxf(0.0,float(_state().population_allocations.get(role,0)))

static func _pop()->float:
	return maxf(1.0,float(_state().population_exact))

## Ten more people on this work, as the work counts them today (the share
## that is fit and free to work, as for those already on it).
static func _ten(role:String)->float:
	var raw:=_raw(role)
	var ratio:=_workers(role)/raw if raw>0.0 else 1.0
	return float(MORE)*clampf(ratio,0.0,1.5)

static func _whole(value:float)->String:
	return Impact._whole(value)

static func _one(value:float)->String:
	return Impact._one(value)

## Small amounts to two places, larger ones as the impact panel writes them.
static func _points(value:float)->String:
	return Impact._two(value) if absf(value)<1.0 else Impact._one(value)

static func _count(n:int)->String:
	return Impact._count(n)
