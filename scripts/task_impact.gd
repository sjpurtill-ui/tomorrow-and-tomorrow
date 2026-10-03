extends RefCounted
## WHAT EACH DAILY TASK DOES, IN NUMBERS: the People screen's explanations
## (hud/people_screen.gd, opened from a task's name). Every line is computed
## from the rule the engine applies, named beside it, so the screen says what
## the people on that work change today and what more or fewer would do.
## Work rows are GameState.POPULATION_ROLES (manual_work.gd names them):
##   Food            food_system.gd (harvest, wild grounds), resource_system.gd
##                   (water), consequence_engine.gd (strain, land)
##   Survey          resource_system.gd (finding, measuring), settlement_model.gd
##                   (claim), standing.gd (cunning)
##   Extraction      resource_system.gd (yield, opening), consequence_engine.gd
##                   (tools, accidents, land)
##   Construction    settlement_construction.gd (works, homes), settlement_model.gd
##                   (upkeep), military_campaign.gd (walls), undertaking_system.gd
##   Crafting        consequence_engine.gd (materials), civilian_goods.gd (goods),
##                   food_system.gd (preserving), military_campaign.gd (weapons)
##   Logistics       resource_system.gd (water, hauling), consequence_engine.gd
##                   (movement), settlement_model.gd (stores), civilian_goods.gd
##   Knowledge       consequence_engine.gd (learning), discovery_system.gd (teams),
##                   society_model.gd (upkeep of keepers, teaching)
##   Administration  consequence_engine.gd (cohesion, orders), society_model.gd
##                   (institutions), economy_system.gd, society_exchange.gd
##   Defense         consequence_engine.gd (safety, deaths, orders),
##                   military_campaign.gd (garrison, training, walls, prisoners)
## of(role) -> {lead, lines}; a line: {label, value, words, tone ("good" |
## "bad" | "plain")}. The People screen never shows "%": amounts are in points
## (of 100), "in 100", rations, days or times as much.

const CIVIC:=preload("res://scripts/civic_building_effects.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")
const Society:=preload("res://scripts/society_model.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")
const Undertakings:=preload("res://scripts/undertaking_system.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const EarlyLife:=preload("res://scripts/early_life_conditions.gd")
const Injuries:=preload("res://scripts/permanent_injuries.gd")
const Mechanics:=preload("res://scripts/research_mechanics.gd")

## Extra food a person on each task eats a day, in rations
## (food_system.gd _daily_food_demand extras; checked by the tests).
const EXERTION:={"Food":0.17,"Extraction":0.18,"Construction":0.18,"Defense":0.12,"Survey":0.13,"Logistics":0.14,"Crafting":0.08,"Knowledge":0.04,"Administration":0.04}
## Food getters: the share of their day spent on food (food_system.gd
## FOOD_WORK_SHARE), the water each fetches as a carrier (resource_system.gd),
## and the share on food past which the land wears (consequence_engine.gd).
const FOOD_SHARE:=0.7
const FOOD_WATER:=0.22
const FOOD_LAND_SHARE:=0.48
const FOOD_LAND_WEAR:=0.00105
## Heavy work (food, cutting, building): past this share of the workers the
## people are overworked (consequence_engine.gd overwork).
const HEAVY_ONSET:=0.74
const HEAVY_SPAN:=0.22
const HEAVY_EASE:=0.08
## Cutters' wear on the land a day per share of the workers (consequence_engine.gd).
const DIG_LAND_WEAR:=0.00052
## Searchers: the share of the able that counts in full toward the town's claim,
## and the reach points they give (settlement_model.gd _base_claim_radius_km).
const CLAIM_SEARCHERS:=0.10
const CLAIM_SEARCH_POINTS:=16.0
const CLAIM_BASE_POINTS:=62.0
## Stewards' part of the claim (the same rule).
const CLAIM_STEWARDS:=0.08
const CLAIM_STEWARD_POINTS:=18.0
## Standing's cunning: the share searching that counts in full, and its weight
## (standing.gd cunning).
const CUNNING_SEARCHERS:=0.08
const CUNNING_WEIGHT:=0.4
## Builders: the share of the people that keeps the town in full repair, and a
## month's mending and wear (settlement_model.gd _advance_city_upkeep).
const BUILD_UPKEEP_SHARE:=0.05
const BUILD_MEND:=0.04
const BUILD_WEAR:=0.02
## Makers: the share of the people that equips everyone, and what they add to
## tools and materials (consequence_engine.gd craft_coverage).
const MAKER_SHARE:=0.05
const MAKER_POINTS:=0.38
## Food put by a day per carrier and per maker (food_system.gd preservation).
const CARRIER_PRESERVE:=0.16
const MAKER_PRESERVE:=0.18
## Carriers: the share of the people that moves the town fully, and what they
## add to its movement (consequence_engine.gd logistics_target).
const CARRIER_SHARE:=0.08
const CARRIER_POINTS:=0.55
const CARRIER_WATER:=28.0
## Stewards: coverage share and what it adds (consequence_engine.gd).
const STEWARD_SHARE:=0.035
const STEWARD_COHESION:=0.20
const STEWARD_TRUST:=0.10
const STEWARD_INSTITUTION_SHARE:=0.06
const STEWARD_INSTITUTION:=0.38
const STEWARD_SETTLES:=8.0
const STEWARD_INVITES:=12.0
## The watch: the share of the people that counts fully toward safety, what it
## adds, and lawlessness below safety 30 (consequence_engine.gd).
const WATCH_SHARE:=0.05
const WATCH_SAFETY:=0.42
const LAWLESS_BELOW:=0.30
const LAWLESS_DEATHS:=0.025
const WATCH_PRISONER_GUARDS:=0.18
const WATCH_WALL_WORK:=0.38
const WATCH_REPAIR:=0.20


## The task's explanation: {lead, lines}, with what the people's gifted add
## and, for learning and keeping and caring, the chance a gifted child is
## noticed (geniuses.gd).
static func of(role:String)->Dictionary:
	var result:=_of(role)
	preload("res://scripts/geniuses.gd").explain(role,result)
	return result

static func _of(role:String)->Dictionary:
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
	return {"lead":"","lines":[]}


# --- Getting food -------------------------------------------------------------------

static func food()->Dictionary:
	var state=WorldSimulation.state
	var getters:=_workers("Food")
	var metrics:Dictionary=state.simulation_metrics
	var harvest:Dictionary=metrics.get("food_harvest",{}) if metrics.get("food_harvest") is Dictionary else {}
	var lines:Array=[]
	var brought:=0.0
	var parts:PackedStringArray=[]
	for kind:String in ["Fresh plants","Fresh meat","Fish","Dry staples"]:
		var amount:=float(harvest.get(kind,0.0))
		brought+=amount
		if amount>=0.5:parts.append("%s %s" % [{"Fresh plants":"gathered","Fresh meat":"hunted","Fish":"fished","Dry staples":"from the fields"}[kind],_whole(amount)])
	var need:=float(metrics.get("food_consumption",0.0))
	if getters<=0.0:
		lines.append(_line("Food brought in","none","Nobody is getting food: the people live on their stores until they run out.","bad"))
	elif brought<=0.0 and need<=0.0:
		lines.append(_line("Food brought in","counted at dawn","The day's harvest has not been counted yet. Seven tenths of a food getter's day goes to food, the rest to their own fetching and carrying.","plain"))
	else:
		lines.append(_line("Food brought in","%s rations a day" % _whole(brought),
			"%s brought in %s rations today%s, about %s each; the people eat %s a day. Seven tenths of a food getter's day goes to food, the rest to their own fetching and carrying." % [_people(getters),_whole(brought)," ("+", ".join(parts)+")" if not parts.is_empty() else "",_one(brought/getters),_whole(need)],
			"good" if brought>=need else "bad"))
	# Wild grounds: the more is taken the less each extra hand finds, and taking
	# more than grows back wears them (food_system.gd wild catch, source health).
	var grounds:Dictionary=state.food_source_health
	var gather:=float(grounds.get("Wild gathering",0.9));var game:=float(grounds.get("Hunting",0.9));var fish:=float(grounds.get("Fishing",0.9))
	var worst:=minf(gather,minf(game,fish))
	lines.append(_line("The wild grounds","%d of 100" % roundi(worst*100.0),
		"Each extra hand finds less once the country is worked hard, and taking more than grows back wears the grounds down. Gathering grounds %d of 100, game %d, fish %d." % [roundi(gather*100.0),roundi(game*100.0),roundi(fish*100.0)],
		"good" if worst>=0.7 else ("bad" if worst<0.45 else "plain")))
	lines.append(_line("Water on the way home","%s carriers' worth" % _one(getters*FOOD_WATER),
		"Food getters bring water back as they go: each counts about a fifth of a carrier (%s)." % _two(FOOD_WATER),"good" if getters>0.0 else "plain"))
	lines.append(_heavy_line())
	# The land: more than 48 in 100 of the workers on food wears it (consequence_engine.gd).
	var share:=_raw("Food")/_able()
	var over:=maxf(0.0,share-FOOD_LAND_SHARE)
	if over>0.0:
		lines.append(_line("The land","−%s points a year" % _one(over*FOOD_LAND_WEAR*365.0*100.0),
			"%d in 100 of the workers are on food; past %d the land's health wears down, faster the more there are." % [roundi(share*100.0),roundi(FOOD_LAND_SHARE*100.0)],"bad"))
	else:
		lines.append(_line("The land","no wear","%d in 100 of the workers are on food; the land starts to wear only past %d." % [roundi(share*100.0),roundi(FOOD_LAND_SHARE*100.0)],"plain"))
	# Townsfolk: the fewer on food, the more live as townsfolk; past a quarter
	# fewer children are born (civilization_indicators.gd, early_life_conditions.gd).
	var urban:=Indicators.urban_share(state)
	if float(state.population_exact)>Indicators.URBAN_MIN_POPULATION:
		var fewer:=EarlyLife.TRANSITION_URBAN*maxf(0.0,urban-EarlyLife.URBAN_ONSET)
		lines.append(_line("Townsfolk and births","%d in 100 townsfolk" % roundi(urban*100.0),
			("The fewer on food, the more people live as townsfolk. Past %d in 100 of them, couples choose fewer children: %s in 100 fewer now." % [roundi(EarlyLife.URBAN_ONSET*100.0),_one(fewer*100.0)]) if fewer>0.0 else "The fewer on food, the more people live as townsfolk. Past %d in 100 of them, couples choose fewer children." % roundi(EarlyLife.URBAN_ONSET*100.0),
			"bad" if fewer>0.0 else "plain"))
	# Fresh food, carrying, keeping and caring (food_care.gd role_effect).
	lines.append_array(preload("res://scripts/food_care.gd").role_effect("Food").get("lines",[]))
	_great_work_line(lines,"Food")
	lines.append(_cost_line("Food"))
	return {"lead":"Food getters gather, hunt, fish and tend the fields. What the people do not eat the same day is put by in the stores.","lines":lines}


# --- Searching the land ------------------------------------------------------------

## Searchers find hidden deposits, measure found ones (only they can), push the
## claim outward and make the people cunning (resource_system.gd deposits,
## settlement_model.gd claim, standing.gd).
static func survey()->Dictionary:
	var state=WorldSimulation.state
	var searchers:=_workers("Survey")
	var inputs:Dictionary=ResourceSystem._local_survey_inputs()
	var effort:=float(inputs.get("effort",0.0))
	var helped:=float(inputs.get("nature",0.0))+float(inputs.get("material",0.0))
	var lines:Array=[]
	var deposits:=_deposits_by_stage()
	# Finding: every hidden deposit the people can recognise gathers signs each
	# day at base × (0.5 + effort + research) (resource_system.gd clues).
	var hidden:Array=deposits.hidden
	var pace:=(0.5+effort+helped)/maxf(0.01,0.5+helped)
	var next_find:=_soonest(hidden,"clues",func(deposit:Dictionary)->float:
		return 0.5+effort*_method(deposit,"recognition")+helped)
	var alone:=_soonest(hidden,"clues",func(_deposit:Dictionary)->float:return 0.5+helped)
	if hidden.is_empty():
		lines.append(_line("Finding new materials","nothing left",
			"Every deposit your people know how to recognise here has been found. New kinds turn up only as the people learn to recognise them.","plain"))
	elif searchers<=0.0:
		lines.append(_line("Finding new materials","slow",
			"Nobody is searching, so the %s hidden deposits your people could recognise show themselves only by chance: the next in about %s." % [_count(hidden.size()),_days(alone)],"bad"))
	else:
		lines.append(_line("Finding new materials","×%s as fast" % _one(pace),
			"%s searching turn up hidden deposits %s times as fast as nobody searching. %s left they could recognise; the next in about %s (%s with nobody searching)." % [_people(searchers),_one(pace),_cap(_count(hidden.size())),_days(next_find),_days(alone)],"good"))
	# Measuring: only searchers survey a found deposit, base × 0.55 × effort ×
	# survey speed a day; until then it cannot be opened for work.
	var found:Array=deposits.found
	var speed:=float(inputs.get("speed",1.0))
	if found.is_empty():
		lines.append(_line("Measuring what is found","none waiting",
			"Only searchers can measure a found deposit so carriers and builders can open it for work. None is waiting now.","plain"))
	elif searchers<=0.0 or effort<=0.0:
		lines.append(_line("Measuring what is found","stopped",
			"%s found but can never be opened for work while nobody searches: only searchers measure a deposit (%s)." % [_cap(_count(found.size())),_names(found)],"bad"))
	else:
		var measure:=_soonest(found,"survey",func(deposit:Dictionary)->float:
			return 0.55*effort*_method(deposit,"survey")*speed)
		lines.append(_line("Measuring what is found","next in %s" % _days(measure),
			"%s found and waiting to be measured (%s). Searchers work on all of them at once; more searchers measure each sooner, and nobody else can do it." % [_cap(_count(found.size())),_names(found)],"good"))
	# Searched land and finds (resource_system.gd land_survey): its own rule and odds.
	_land_lines(lines)
	# The claim: survey share × 16 points of reach (settlement_model.gd).
	var able:=_able()
	var share:=clampf(searchers/maxf(1.0,able*CLAIM_SEARCHERS),0.0,1.0)
	lines.append(_line("Land the town claims","+%d points of reach" % roundi(share*CLAIM_SEARCH_POINTS),
		"A town's claim reaches out from %d points; searchers add up to %d more, in full when a tenth of the workers search (%s would). Now %d of %d." % [roundi(CLAIM_BASE_POINTS),roundi(CLAIM_SEARCH_POINTS),_count(ceili(able*CLAIM_SEARCHERS)),roundi(share*CLAIM_SEARCH_POINTS),roundi(CLAIM_SEARCH_POINTS)],"good" if share>0.0 else "plain"))
	# Standing's cunning: 40 in 100 of it from those searching (standing.gd). It
	# is shown on the Standing page; nothing else reads it yet.
	var pop:=maxf(1.0,float(state.population_total))
	var watching:=clampf(_raw("Survey")/maxf(1.0,float(state.population_exact)*CUNNING_SEARCHERS),0.0,1.0)
	lines.append(_line("Our cunning","%d of %d points" % [roundi(watching*CUNNING_WEIGHT*100.0),roundi(CUNNING_WEIGHT*100.0)],
		"Four tenths of the cunning shown on the Standing page comes from people out watching and finding, full when %s search; the rest is the chief scout's skill. It changes nothing else yet." % _count(ceili(pop*CUNNING_SEARCHERS)),"good" if watching>0.0 else "plain"))
	lines.append(_cost_line("Survey"))
	return {"lead":"Searchers walk the country for useful materials and measure what they find, so carriers and builders can open it for work. They do not scout for strangers; scouting parties are sent from court.","lines":lines}

## The searched land's two lines, for the whole people as every line here is
## (resource_system.gd realm_land_reading: each town's own land, averaged by
## its people): how well it is searched and what it gives cutting and
## digging, and the chance of a find in the next month; each with what ten
## more searchers would do.
static func _land_lines(lines:Array)->void:
	var R=WorldSimulation.resources
	var land:Dictionary=R.realm_land_reading()
	if not bool(land.get("settled",false)):return
	var plus:Dictionary=land.plus_ten
	var cover:=roundi(float(land.cover)*100.0)
	lines.append(_line("Searched land","%d in 100" % cover,
		"Cutters and diggers get %s from it (×0.75 unsearched, up to ×1.25). One searcher for every 60 people holds it near 60; it is %s. Ten more searching would take it toward %d (×%s)." % [String(R.land_yield_words(land)),String(R.land_heading(land)),roundi(float(plus.target)*100.0),_two(float(plus.yield))],"good" if cover>=50 else "plain"))
	var odds:=String(R.odds_words(float(land.find_month)))
	lines.append(_line("Finds","%s a month" % odds,
		"A find in the next month: %s. A find is a deposit not yet measured, new ground, or a richer part of one being worked. Ten more searching: %s." % [odds,String(R.odds_words(float(plus.find_month)))],"good" if float(land.find_month)>0.0 else "plain"))

## The deposits by what searchers can still do: hidden ones the people could
## recognise, and found ones waiting to be measured.
static func _deposits_by_stage()->Dictionary:
	var hidden:Array=[];var found:Array=[];var measured:Array=[]
	var ready:Dictionary={}
	for deposit_variant in WorldSimulation.state.resource_deposits:
		if not deposit_variant is Dictionary:continue
		var deposit:Dictionary=deposit_variant
		var resource:=String(deposit.get("resource",""))
		if not ResourceSystem.catalog.has(resource):continue
		match String(deposit.get("stage","")):
			"unknown":
				if not ready.has(resource):ready[resource]=ResourceSystem.recognition_ready(resource)
				if bool(ready[resource]):hidden.append(deposit)
			"recognized":found.append(deposit)
			"surveyed":measured.append(deposit)
	return {"hidden":hidden,"found":found,"measured":measured}

## Expected days until the first of these deposits fills its field (clues or
## survey) to 1, at base × rate(deposit) × the people's lore of it a day.
static func _soonest(deposits:Array,field:String,rate:Callable)->float:
	var best:=INF
	for deposit:Dictionary in deposits:
		var resource:=String(deposit.get("resource",""))
		var base:=float((ResourceSystem.catalog.get(resource,{}) as Dictionary).get("base",0.03))
		var daily:=base*float(rate.call(deposit))*ResourceSystem._family_literacy(resource)
		if daily<=0.0:continue
		best=minf(best,maxf(0.0,1.0-float(deposit.get(field,0.0)))/daily)
	return best

## Prospecting know-how's help on this deposit's material (geoscience_knowledge.gd).
static func _method(deposit:Dictionary,phase:String)->float:
	var factors:Dictionary=preload("res://scripts/geoscience_knowledge.gd").factors()
	return float((factors.get(String(deposit.get("resource","")),{}) as Dictionary).get(phase,1.0))

static func _names(deposits:Array)->String:
	var names:PackedStringArray=[]
	for deposit:Dictionary in deposits:
		var name:=String(ResourceSystem.display_name(String(deposit.get("resource","")))).to_lower()
		if not name in names:names.append(name)
	return ", ".join(names.slice(0,4))+(" and more" if names.size()>4 else "")


# --- Cutting and digging ----------------------------------------------------------

static func extraction()->Dictionary:
	var state=WorldSimulation.state
	var cutters:=_workers("Extraction")
	var flows:Dictionary=state.material_metrics
	var lines:Array=[]
	var cut:=float(flows.get("extracted_today",0.0))
	var worked:=int(flows.get("accessible_occurrences",0))
	if cutters<=0.0:
		lines.append(_line("Materials brought in","none","Nobody is cutting or digging: no timber, stone, clay or fibre comes in, and the stores only run down.","bad"))
	elif cut<=0.0:
		lines.append(_line("Materials brought in","none today","Nothing was cut or dug today: no open deposit is being worked. Deposits are opened once searchers have measured them.","bad"))
	else:
		lines.append(_line("Materials brought in","%s loads a day" % _whole(cut),
			"%s cut and dug %s loads today from %s, about %s each; carriers moved %s of it to the stores." % [_people(cutters),_whole(cut),"one worked deposit" if worked==1 else "%s worked deposits" % _count(worked),_one(cut/cutters),_whole(float(flows.get("delivered_today",0.0)))],"good"))
	# Tools: output × (0.55 + tools × 0.75), tools from the makers' materials
	# (resource_system.gd tool_factor, consequence_engine.gd tools_factor).
	var tools:float=WorldSimulation.consequences.tools_factor()
	var tool_factor:=0.55+tools*0.75
	lines.append(_line("Tools in hand","×%s" % _two(tool_factor),
		"Each cutter's work goes ×%s with today's tools: ×0.69 with the poorest, up to ×1.38 with the best. Makers raise it." % _two(tool_factor),"good" if tool_factor>=1.0 else "plain"))
	# Searched land: × (0.75 + 0.5 × how well it is searched) (resource_system.gd land_yield).
	var land:Dictionary=WorldSimulation.resources.realm_land_reading()
	if bool(land.get("settled",false)):
		lines.append(_line("Searched land","×%s" % _two(float(land.applied)),
			"Cutters and diggers get %s from land searched %d in 100: ×0.75 where nobody has searched, up to ×1.25 where all of it is known. Searchers raise it." % [String(WorldSimulation.resources.land_yield_words(land)),roundi(float(land.cover)*100.0)],"good" if float(land.applied)>=1.0 else "bad"))
	var waiting:=0
	for deposit:Dictionary in _deposits_by_stage().measured:
		if String(deposit.get("resource",""))!="Freshwater":waiting+=1
	lines.append(_line("Opening deposits","%s waiting" % _count(waiting) if waiting>0 else "none waiting",
		"A measured deposit is opened for work only while someone cuts and digs, and water from far off needs a cutter and a carrier. %s" % ("%s measured deposits wait to be opened." % _cap(_count(waiting)) if waiting>0 else "None is waiting now."),"bad" if waiting>0 and cutters<=0.0 else "plain"))
	# Accidents: (0.2 + 2.5 × the share digging) in 100 a year, times how hard
	# the deposits are worked (consequence_engine.gd "Work accidents").
	var components:Dictionary=state.simulation_metrics.get("mortality_components",{}) if state.simulation_metrics.get("mortality_components") is Dictionary else {}
	var accidents:=float(components.get("Work accidents",0.0))
	var dead:=accidents*float(state.population_exact)
	lines.append(_line("Accidents","%s deaths a year" % _one(dead) if dead>=0.05 else "hardly any",
		"Accidents at work kill more the larger the share digging and the harder the deposits are worked; knowing how to keep mines safe lowers it. %s" % ("About %s in 1000 of the people a year now." % _one(accidents*1000.0) if dead>=0.05 else "The deposits are worked too lightly now for many accidents."),"bad" if dead>=0.5 else "plain"))
	var share:=_raw("Extraction")/_able()
	lines.append(_line("The land","−%s points a year" % _one(share*DIG_LAND_WEAR*365.0*100.0),
		"Cutting and digging wear the land's health, in step with the share of workers at it (%d in 100 now)." % roundi(share*100.0),"bad" if share>0.0 else "plain"))
	lines.append(_line("Knowing the ground","finds come easier",
		"Every day worked on a material teaches the people its kind: searchers find and measure related deposits up to %s times as fast." % _two(1.55),"good" if cutters>0.0 else "plain"))
	var wood:=_wood_line()
	if not wood.is_empty():lines.append(wood)
	lines.append(_heavy_line())
	_great_work_line(lines,"Extraction")
	lines.append(_cost_line("Extraction"))
	return {"lead":"Cutters and diggers work the deposits the people have opened: timber, stone, clay, fibre and ore. What they bring in builds, arms and equips the town.","lines":lines}


# --- Building ---------------------------------------------------------------------

static func construction()->Dictionary:
	var state=WorldSimulation.state
	var builders:=_workers("Construction")
	var lines:Array=[]
	# Town works: builders ÷ 8 × (0.82 + carriers ÷ 30 + makers ÷ 50) × work pace
	# a day (settlement_construction.gd daily_work).
	var pace:=Construction.daily_work()
	var project:Dictionary=Construction._current_settlement_project()
	if project.is_empty():
		lines.append(_line("Town works","nothing to raise","No work the people know how to build is waiting. Builders keep the town in repair and put up homes.","plain"))
	elif builders<=0.0 or pace<=0.0:
		lines.append(_line("Town works","stopped","Nobody is building, so the %s stands unfinished." % String(project.name),"bad"))
	else:
		var done:=float(state.settlement_projects.get(String(project.name),0.0))
		var left:=maxf(0.0,float(project.days)-done)
		var faster:=pace+pace/maxf(1.0,builders)
		lines.append(_line("Town works","%s left" % _days(left/pace),
			"Raising the %s: %d in 100 done, about %s more at today's pace. Builders set the pace, carriers and makers help; one more builder would finish it about %s sooner." % [String(project.name),roundi(clampf(done/maxf(0.01,float(project.days)),0.0,1.0)*100.0),_days(left/pace),_days(maxf(0.0,left/pace-left/faster))],"good"))
	# Homes: builders ÷ 8 × pace a day, 28 a batch (settlement_construction.gd).
	if Construction.housing_under_way():
		var per_day:=Construction.housing_work_per_day()
		lines.append(_line("New homes","%d places every %s" % [Construction.housing_batch_places(),_days(Construction.HOUSING_BATCH_WORK/maxf(0.0001,per_day))],
			"More people live here than 8 in 10 of the places, so builders put up homes: a batch of %d places for every %d days of work." % [Construction.housing_batch_places(),roundi(Construction.HOUSING_BATCH_WORK)],"good" if per_day>0.0 else "bad"))
	elif not "Lean-to Shelters" in state.settlement_completed:
		lines.append(_line("New homes","after the Lean-tos","Builders start putting up homes of their own once the Lean-to Shelters stand.","plain"))
	else:
		lines.append(_line("New homes","room for all","Builders start more homes when the people pass 8 in 10 of the places (%s people)." % _grouped(Construction.housing_trigger_people()),"plain"))
	# Upkeep: a month's wear of 2 points, mended up to 4 × repair skill by
	# builders at 5 in 100 of the people, when materials are paid
	# (settlement_model.gd _advance_city_form, research_mechanics.gd mending_factor).
	var pop:=maxf(1.0,float(state.population_exact))
	var share:=clampf(builders/maxf(1.0,pop*BUILD_UPKEEP_SHARE),0.0,1.0)
	var mending:float=Mechanics.mending_factor()
	var monthly:=BUILD_MEND*share*mending-BUILD_WEAR
	var condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0.0,1.0)
	var skill:=" Repair skill makes their mending go %s times as far." % _two(mending) if not is_equal_approx(mending,1.0) else ""
	lines.append(_line("Keeping the town up","%s points a month" % _signed(monthly*100.0),
		"The town wears %d points a month; builders mend up to %s when 5 in 100 of the people build (%s would) and the materials are paid.%s Its condition is %d of 100, and it scales what the stores, workshop, hall and shrines do." % [roundi(BUILD_WEAR*100.0),_one(BUILD_MEND*mending*100.0),_count(ceili(pop*BUILD_UPKEEP_SHARE)),skill,roundi(condition*100.0)],"good" if monthly>=0.0 else "bad"))
	# Walls and ditches: builders and a fifth of the watch mend them
	# (military_campaign.gd integrity repair).
	var walls:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var integrity:=float(walls.get("integrity",1.0))
	if int(walls.get("stage",0))>0 and integrity<1.0:
		# Those of the watch at home mend them, not its bands away.
		var menders:=_raw("Construction")+float(MilitaryCampaign.watch_at_home())*WATCH_REPAIR
		lines.append(_line("Mending the walls","+%s points a day" % _two(minf(0.006,menders*0.00012)*100.0),
			"The %s stand at %d of 100. Builders and a fifth of the watch mend them, faster with more hands." % [String(walls.get("name","defences")).to_lower(),roundi(integrity*100.0)],"good" if menders>0.0 else "bad"))
	# Great works take their crews from the builders (undertaking_system.gd).
	var taken:=Undertakings.share(state)
	if taken>0.0:
		lines.append(_line("Crews for great works","%d in 100 taken" % roundi(taken*100.0),
			"Great works being raised take a fifth of the builders each (half when pressed), and each standing one keeps a few to tend it.","plain"))
	lines.append(_heavy_line())
	_great_work_line(lines,"Construction")
	lines.append(_cost_line("Construction"))
	return {"lead":"Builders raise the town's works and homes, keep the town and its walls in repair, and lay the water lines and roads.","lines":lines}


# --- Making -------------------------------------------------------------------------

static func crafting()->Dictionary:
	var state=WorldSimulation.state
	var makers:=_workers("Crafting")
	var pop:=maxf(1.0,float(state.population_exact))
	var lines:Array=[]
	# Tools and materials: makers ÷ (5 in 100 of the people), up to ×1.25, adds
	# 38 points a unit to the target (consequence_engine.gd craft_coverage).
	var civilian:=clampf(MilitaryCampaign.civilian_crafting_fraction(),0.0,1.0)
	var coverage:=clampf(_raw("Crafting")*civilian/maxf(1.0,pop*MAKER_SHARE),0.0,1.25)
	var material:=float(state.simulation_metrics.get("material_capacity",0.12))
	lines.append(_line("Tools and materials","+%d points" % roundi(coverage*MAKER_POINTS*100.0),
		"Makers lift the tools and materials everyone works with by %d points when 5 in 100 of the people make things (%s would), up to %d with more. The people's tools and materials stand at %d of 100 and climb slowly toward where the makers lift them." % [roundi(MAKER_POINTS*100.0),_count(ceili(pop*MAKER_SHARE)),roundi(1.25*MAKER_POINTS*100.0),roundi(material*100.0)],"good" if coverage>0.0 else "bad"))
	# Household goods: about 0.72 a maker a day at today's skills; how well homes
	# are stocked scales what every practiced craft does (civilian_goods.gd).
	var stocked:=Goods.coverage()
	lines.append(_line("Household goods","%d of 100 stocked" % roundi(stocked*100.0),
		"Makers turn out the pots, baskets, cloth and tools homes need, about %s a day each at today's skills. How well stocked the homes are scales what every craft the people practice does for them." % _two(0.18*4.0*Goods.technique_output()),"good" if stocked>=0.66 else ("bad" if stocked<0.33 else "plain")))
	lines.append(_line("Putting food by","%s rations a day" % _one(makers*MAKER_PRESERVE*(1.0+WorldSimulation.discovery.effect("food_storage"))),
		"Makers dry, smoke and seal the day's fresh surplus: each can put by about %s rations a day (a carrier %s), more with what the people know of preserving." % [_two(MAKER_PRESERVE),_two(CARRIER_PRESERVE)],"good" if makers>0.0 else "plain"))
	var arming:=1.0-civilian
	if arming>0.0:
		lines.append(_line("Weapons","%d in 100 of their work" % roundi(arming*100.0),
			"The workshops are making weapons and gear for the army with %d in 100 of the makers' work; the rest goes to the people." % roundi(arming*100.0),"plain"))
	lines.append(_line("Building faster","+%s a day" % _two(_raw("Crafting")/50.0*_pace_scale()),
		"Makers speed the builders: each adds a fiftieth of a builder's pace to the day's work on the town.","good" if makers>0.0 else "plain"))
	_great_work_line(lines,"Crafting")
	lines.append(_cost_line("Crafting"))
	return {"lead":"Makers turn materials into tools, household goods and stores of preserved food, and into weapons when the army needs them.","lines":lines}


# --- Carrying -----------------------------------------------------------------------

static func logistics()->Dictionary:
	var state=WorldSimulation.state
	var carriers:=_workers("Logistics")
	var pop:=maxf(1.0,float(state.population_exact))
	var water:Dictionary=state.water_metrics
	var lines:Array=[]
	# Water: each carrier brings about 28 × work pace ÷ (1 + walk × 0.16) a day,
	# the walk being the distance shortened by wells and channels
	# (resource_system.gd organized_collection, research_mechanics.gd water_walk_factor).
	var km:=float(water.get("source_distance_km",-1.0))
	var walk:=maxf(0.0,km)*Mechanics.water_walk_factor()
	var labor:=clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)
	var each:=CARRIER_WATER*labor/(1.0+walk*0.16)*(1.0+clampf(WorldSimulation.discovery.effect("haul_capacity"),-0.4,1.5)) if km>=0.0 else 0.0
	var needed:=float(water.get("total_required_today",water.get("required_today",0.0)))
	var collected:=float(water.get("collected_today",0.0))
	var households:=float(water.get("household_collected_today",0.0))
	var off:="from %s km off" % _one(km) if is_equal_approx(walk,maxf(0.0,km)) else "from %s km off, which wells and channels make a %s km walk" % [_one(km),_one(walk)]
	if km<0.0:
		lines.append(_line("Drinking water","no source known","No water source is known yet: searchers must find and measure one before carriers can fetch from it.","bad"))
	elif needed<=0.0:
		lines.append(_line("Drinking water","counted at dawn","The day's water has not been counted yet. Each carrier brings about %s a day %s." % [_one(each),off],"plain"))
	else:
		lines.append(_line("Drinking water","%d of 100 needed" % roundi(minf(1.0,collected/needed)*100.0),
			"%s of the %s water the people need came in today; households beside the water fetched %s themselves. Each carrier brings about %s a day %s, less the farther it is." % [_whole(collected),_whole(needed),_whole(households),_one(each),off],
			"good" if collected>=needed else "bad"))
	# Moving things: carriers ÷ (8 in 100 of the people) × 55 points
	# (consequence_engine.gd logistics_target).
	var lift:=_raw("Logistics")/maxf(1.0,pop*CARRIER_SHARE)*CARRIER_POINTS
	lines.append(_line("Moving things about","+%d points" % roundi(lift*100.0),
		"Carriers lift how smoothly goods and people move around the town: %d points when 8 in 100 of the people carry (%s would). It is %d of 100 now, and it adds to safety, trade and the army's supply." % [roundi(CARRIER_POINTS*100.0),_count(ceili(pop*CARRIER_SHARE)),roundi(float(state.simulation_metrics.get("logistics",0.16))*100.0)],"good" if lift>0.0 else "bad"))
	# New ground: when the woods, stone and fibre the people work run low, the
	# carriers look for more one ring farther for every 6 at work
	# (resource_system.gd surface_search_rings, woodland_outlook).
	var wood:=_wood_line()
	if not wood.is_empty():lines.append(wood)
	else:
		var reach:Dictionary=WorldSimulation.resources.woodland_outlook()
		var farther:=" %s carrying would take them to %d km." % [_cap(_count(int(reach.carriers_for_next))),roundi(float(reach.next_km))] if int(reach.carriers_for_next)>0 else " That is as far as they ever look."
		lines.append(_line("Looking for new ground","within %d km" % roundi(float(reach.reach_km)),
			"When the woods, stone and fibre the people work run low, carriers look for new ground within %d km.%s" % [roundi(float(reach.reach_km)),farther],"plain"))
	var flows:Dictionary=state.material_metrics
	var cut:=float(flows.get("extracted_today",0.0))
	if cut>0.0:
		var moved:=float(flows.get("delivered_today",0.0))
		lines.append(_line("Hauling materials","%d of 100 moved" % roundi(clampf(moved/cut,0.0,1.0)*100.0),
			"Materials cut away from the stores reach them only as carriers bring them, slower the farther and heavier: %s of the %s cut today." % [_whole(moved),_whole(cut)],"good" if moved>=cut*0.9 else "bad"))
	# Stores: built storage works as carriers staff it; the Public Stores need
	# carriers at 4 in 100 and stewards at 2 in 100 (settlement_model.gd, civilian_goods.gd).
	var staffing:=clampf(carriers/maxf(1.0,pop*0.10),0.15,1.0)
	lines.append(_line("Staffing the stores","%d of 100 staffed" % roundi(staffing*100.0),
		"Built storage holds its full share only when carriers staff it, full at a tenth of the people (%s would).%s" % [_count(ceili(pop*0.10))," The Public Stores also need carriers at 4 in 100 of the people." if "Public Stores" in state.settlement_completed else ""],"good" if staffing>=1.0 else "plain"))
	lines.append(_line("Putting food by","%s rations a day" % _one(carriers*CARRIER_PRESERVE*(1.0+WorldSimulation.discovery.effect("food_storage"))),
		"Carriers help dry and store the day's fresh surplus: each can put by about %s rations a day." % _two(CARRIER_PRESERVE),"good" if carriers>0.0 else "plain"))
	# Soldiers' food and stores (carriers.gd): each carrier drives a lorry or a
	# cart if there is one, else carries 16 loads; every band away asks its
	# bread and stores times its round trip; bread goes first.
	var reading:Dictionary=MilitaryCampaign.carrier_reading()
	if float(reading.get("demand",0.0))>0.0:
		var fed:=float(reading.get("food",1.0))
		lines.append(_line("Feeding soldiers","%d of 100 of their bread" % roundi(fed*100.0),
			"The bands away and the garrisons ask %s loads a day (bread %s, fodder, fuel and rounds %s). At their distances our carriers bring %s a day: a porter 16 loads a trip, a cart %s, a lorry %s, each out and back at its own pace. Bread goes first; stores get %d of 100." % [_whole(float(reading.demand)),_whole(float(reading.get("bread",0.0))),_whole(float(reading.get("stores_asked",0.0))),_whole(float(reading.moved)),_whole(float((reading.fleet as Dictionary).get("cart_load",250.0))),_whole(float((reading.fleet as Dictionary).get("lorry_load",2000.0))),roundi(float(reading.get("stores",1.0))*100.0)],"good" if fed>=0.8 else "bad"))
	lines.append(_line("Building faster","+%s a day" % _two(_raw("Logistics")/30.0*_pace_scale()),
		"Carriers speed the builders: each adds a thirtieth of a builder's pace to the day's work on the town.","good" if carriers>0.0 else "plain"))
	# Fresh food, carrying, keeping and caring (food_care.gd role_effect).
	lines.append_array(preload("res://scripts/food_care.gd").role_effect("Logistics").get("lines",[]))
	_great_work_line(lines,"Logistics")
	lines.append(_cost_line("Logistics"))
	return {"lead":"Carriers fetch the water, haul materials from the deposits, stock and staff the stores, and keep soldiers supplied.","lines":lines}


# --- Learning -----------------------------------------------------------------------

static func knowledge()->Dictionary:
	var state=WorldSimulation.state
	var keepers:=_workers("Knowledge")
	var lines:Array=[]
	# Attention: two keepers are asked for each research line followed
	# (research_600_catalog.gd keepers_asked, consequence_engine.gd focus_quality).
	var asked:=Research600.keepers_asked(state.research_allocations)
	var lines_followed:=roundi(asked/2.0)
	var fit:=1.0 if asked<=maxf(1.0,floorf(keepers)) else clampf(keepers/maxf(1.0,asked),0.15,1.0)
	if asked<=0.0:
		lines.append(_line("Learners for the research","no lines followed","No research line is followed, so the learners only watch and remember; set the research to give them lines to carry.","plain"))
	else:
		lines.append(_line("Learners for the research","%s of %s" % [_whole(keepers),_whole(asked)],
			"Two learners are asked for each research line followed (%s lines). With %s, learning runs at %d in 100 of full attention." % [_count(lines_followed),_whole(keepers),roundi(fit*100.0)],"good" if fit>=1.0 else "bad"))
	# Learning: keepers × work pace × attention ÷ (92 × people, at least 3000)
	# a day, times what helps it (consequence_engine.gd knowledge_gain).
	var pop:=maxf(1.0,float(state.population_exact))
	var labor:=float(state.simulation_metrics.get("labor_efficiency",0.72))
	var gain:=keepers*labor*fit/maxf(3000.0,pop*92.0)*(1.0+WorldSimulation.discovery.effect("knowledge_rate"))*lerpf(0.55,1.45,float(state.combined_intelligence))
	lines.append(_line("What the people know","+%s points a year" % _two(gain*365.0*100.0),
		"Learners add to what the people know, which speeds every discovery. It stands at %d of 100; the learners add about %s points a year at today's pace." % [roundi(float(state.simulation_metrics.get("knowledge",0.18))*100.0),_two(gain*365.0*100.0)],"good" if gain>0.0 else "bad"))
	# Every learner counts, without a cap (research_600_catalog.gd team_capacity;
	# discovery_system.gd role_effect reads the engine's numbers).
	var now:Dictionary=WorldSimulation.discovery.role_effect("Knowledge",1.0)
	var ten:Dictionary=WorldSimulation.discovery.role_effect("Knowledge",10.0)
	if keepers<=0.0:
		lines.append(_line("One more learner","starts the research",
			"Nobody is learning, so no research moves. Every learner counts; there is no cap on how many learn.","bad"))
	else:
		lines.append(_line("One more learner",_gain_value(float(now.pace_gain)),
			"Every learner counts; there is no cap. %s learners work %s questions at once. One more makes the research go %s; ten more, %s (%s questions at once). On one question, twice the people do about 1.8 times the work." % [_whole(keepers),_count(int(now.teams)),_faster(float(now.pace_gain)),_faster(float(ten.pace_gain)),_count(int(ten.teams_more))],"good"))
	# Learners use goods: tallies, writing stuff, tools (Research600.goods_cover).
	var cover:=float(now.goods_cover)
	lines.append(_line("Goods for the learners","%d of 100 covered" % roundi(cover*100.0) if keepers>0.0 else "none asked",
		"Learners use goods: tallies, writing stuff and tools, one for each %d days of learning, and the same again for every %d years our learning runs ahead of the calendar. %s learners ask %s goods a day and our stores hold %s. Makers make them; short of goods, learning slows, to half its pace with none. Now it goes at %d in 100." % [roundi(Research600.LEARNER_DAYS_PER_GOOD),roundi(Research600.LEAD_GOODS_YEARS),_whole(keepers),_two(float(now.goods_a_day)),_one(float(now.goods_held)),roundi(float(now.goods_factor)*100.0)],"good" if cover>=0.99 else "bad"))
	# Our own age: learners past what the age can spare carry it ahead of the
	# calendar (Research600.lead_rate, discovery_system.gd learning_lead).
	var lead:=float(now.lead_years)
	var rate:=float(now.lead_rate)
	var drift:="ahead about %s years every ten years" % _one(rate*10.0) if rate>0.0 else ("back toward the calendar about %s years every ten years" % _one(-rate*10.0) if rate<0.0 and lead>0.0 else "level with the calendar")
	lines.append(_line("Ahead of the calendar","%s years" % _one(lead) if lead>=0.5 else "level",
		"The age can spare %d in 100 of the able as learners; %d in 100 learn. Past that, our learning runs ahead of the calendar; below it the calendar catches up. Ours is moving %s. Questions are dated from our own age, and what we know pays off to the age our knowledge has reached." % [roundi(float(now.sustainable_share)*100.0),roundi(float(now.share)*100.0),drift],"good" if lead>=0.5 or rate>0.0 else "plain"))
	# Too many keepers: past the share the age can spare, each costs work,
	# weariness, cohesion and births (society_model.gd specialist upkeep).
	var model=WorldSimulation.discovery.society_model
	# What the economy can spare follows its real age, not the learners' lead.
	var era:=float(model.economy_era()) if model!=null else 0.0
	var sustainable:=Society._rise(Society.SUSTAINABLE_SPECIALISTS,era)
	var able:=_able()
	var excess:=float(model.specialist_excess) if model!=null else 0.0
	if excess>0.0:
		lines.append(_line("Too many learners","%s over" % _whole(excess*able),
			"The people can spare %d in 100 of the workers as full-time learners at this age (%s people). Past that the extra ones cost more work for everyone, weariness, cohesion and births." % [roundi(sustainable*100.0),_whole(sustainable*able)],"bad"))
	else:
		lines.append(_line("Learners the people can spare","up to %s" % _whole(sustainable*able),
			"The people can spare %d in 100 of the workers as full-time learners at this age. Past that the extra ones cost more work for everyone, weariness, cohesion and births." % roundi(sustainable*100.0),"plain"))
	# Teaching: keepers spread practices to the rest (society_model.gd teaching).
	var teaching:=_raw("Knowledge")/pop*0.055
	var all_teaching:=teaching+_raw("Administration")/pop*0.018+_raw("Crafting")/pop*0.012
	lines.append(_line("Teaching new ways","%d in 100 of the teaching" % roundi(teaching/maxf(0.000001,all_teaching)*100.0) if all_teaching>0.0 else "none",
		"New practices spread to more households each month as people teach them; learners teach most, stewards and makers some.","good" if teaching>0.0 else "plain"))
	if CIVIC.SHRINE_HOUSE in state.settlement_completed:
		var tended:=CIVIC.keepers_ratio()
		lines.append(_line("Tending the Shrine House","%d of 100" % roundi(minf(1.0,tended)*100.0),
			"The Shrine House does its full good only while learners tend it, 1 in 100 of the people (%s would)." % _count(ceili(pop*CIVIC.SHRINE_KEEPERS_SHARE)),"good" if tended>=1.0 else "bad"))
	_great_work_line(lines,"Knowledge")
	lines.append(_cost_line("Knowledge"))
	return {"lead":"Learners watch, remember and try things out. They carry the research lines forward and teach new ways to everyone else. Every learner counts; they eat, use goods and make no food.","lines":lines}


# --- Keeping and caring -------------------------------------------------------------

static func administration()->Dictionary:
	var state=WorldSimulation.state
	var stewards:=_workers("Administration")
	var pop:=maxf(1.0,float(state.population_exact))
	var lines:Array=[]
	# Cohesion and trust: coverage = stewards × (1 + the hall's reach) ÷ 3.5 in
	# 100 of the people, up to 1.25 (consequence_engine.gd admin_coverage).
	var coverage:=clampf(stewards*(1.0+CIVIC.effect("admin_reach"))/maxf(1.0,pop*STEWARD_SHARE),0.0,1.25)
	var hall:=" The Framed Hall lets each steward reach further." if CIVIC.HALL in state.settlement_completed else ""
	lines.append(_line("Holding together","+%d points" % roundi(coverage*STEWARD_COHESION*100.0),
		"Stewards settle quarrels and share out fairly: the people's cohesion leans %d points higher and their trust in the chiefs %d. Full at 3.5 in 100 of the people (%s would), a quarter more past that.%s" % [roundi(coverage*STEWARD_COHESION*100.0),roundi(coverage*STEWARD_TRUST*100.0),_count(ceili(pop*STEWARD_SHARE)),hall],"good" if coverage>0.0 else "bad"))
	# Institutions: stewards ÷ (6 in 100 of the people) × 38 points (society_model.gd).
	var institution:=_raw("Administration")/maxf(1.0,pop*STEWARD_INSTITUTION_SHARE)*STEWARD_INSTITUTION
	lines.append(_line("Strength of government","+%d points" % roundi(institution*100.0),
		"Stewards give the people's ways of ruling their strength: %d points at 6 in 100 of the people. It stands at %d of 100 and feeds research support, trust, the economy and land claims." % [roundi(STEWARD_INSTITUTION*100.0),roundi(float(state.society_capacities.get("institutions",0.25))*100.0)],"good" if institution>0.0 else "bad"))
	# Newcomers: each steward settles 8 newcomers without strain and makes room
	# to invite 12 (society_exchange.gd).
	var unsettled:=float(Exchange.pressure().get("unsettled",0.0))
	lines.append(_line("Settling newcomers","%s unsettled" % _whole(unsettled) if unsettled>=0.5 else "none waiting",
		"Each steward can see %d newcomers settled without strain and makes room to invite %d; beyond that newcomers cost cohesion and add to the chiefs' load." % [roundi(STEWARD_SETTLES),roundi(STEWARD_INVITES)],"bad" if unsettled>stewards*STEWARD_SETTLES else "plain"))
	var able:=_able()
	var share:=clampf(stewards/maxf(1.0,able*CLAIM_STEWARDS),0.0,1.0)
	lines.append(_line("Land the town claims","+%d points of reach" % roundi(share*CLAIM_STEWARD_POINTS),
		"Stewards add up to %d points to how far the town's claim reaches, in full at 8 in 100 of the workers (%s would)." % [roundi(CLAIM_STEWARD_POINTS),_count(ceili(able*CLAIM_STEWARDS))],"good" if share>0.0 else "plain"))
	var market:=stewards/maxf(1.0,pop*0.05)*0.14
	lines.append(_line("Markets and dues","+%d points" % roundi(market*100.0),
		"Stewards widen the market by 14 points at 5 in 100 of the people, and once there is money they assess and collect what is owed.","good" if market>0.0 else "plain"))
	if "Public Stores" in state.settlement_completed:
		var stores:=clampf(minf(_workers("Logistics")/maxf(1.0,pop*0.04),stewards/maxf(1.0,pop*0.02)),0.0,1.0)
		lines.append(_line("The Public Stores","%d of 100 kept" % roundi(stores*100.0),
			"The Public Stores do their full good only with stewards at 2 in 100 of the people and carriers at 4 in 100.","good" if stores>=1.0 else "bad"))
	# Orders from court: 1 + institutions × 6 + up to 2 for stewards at 4 in 100
	# (consequence_engine.gd order slots).
	var institutions:=clampf(float(state.society_capacities.get("institutions",0.25)),0.0,1.0)
	var slots:=1+floori(institutions*6.0)+floori(clampf(_raw("Administration")/pop/0.04,0.0,1.0)*2.0)
	lines.append(_line("Orders at once","%d" % slots,
		"How many standing orders the court can keep in force: one, more as government grows, and up to two more when 4 in 100 of the people are stewards.","plain"))
	# Fresh food, carrying, keeping and caring (food_care.gd role_effect).
	lines.append_array(preload("res://scripts/food_care.gd").role_effect("Administration").get("lines",[]))
	_great_work_line(lines,"Administration")
	lines.append(_cost_line("Administration"))
	return {"lead":"Keepers keep the stores and tallies, settle quarrels, take in newcomers and carry the chiefs' word.","lines":lines}


# --- Keeping watch ------------------------------------------------------------------

static func defense()->Dictionary:
	var state=WorldSimulation.state
	# The watch at home keeps order (consequence_engine.gd reads the same):
	# its bands away and garrisons do not (watch_military.gd at_home).
	var watch:=float(WorldSimulation.military.watch_at_home())
	var pop:=maxf(1.0,float(state.population_exact))
	var lines:Array=[]
	# Safety: + watch ÷ (5 in 100 of the people) × 42 points, the whole held
	# between 4 and 96 (consequence_engine.gd security_target).
	var lift:=watch/maxf(1.0,pop*WATCH_SHARE)*WATCH_SAFETY
	var safety:=clampf(float(state.simulation_metrics.get("security",0.38)),0.0,1.0)
	lines.append(_line("Safety","+%d points" % roundi(lift*100.0),
		"The watch lifts the safety the people settle toward by %d points for every 5 in 100 of them on watch (%s would). Safety is %d of 100 and moves toward its mark a little each day." % [roundi(WATCH_SAFETY*100.0),_count(ceili(pop*WATCH_SHARE)),roundi(safety*100.0)],"good" if lift>0.0 else "bad"))
	var lawless:=maxf(0.0,LAWLESS_BELOW-safety)*LAWLESS_DEATHS
	lines.append(_line("Deaths from lawlessness","%s a year" % _one(lawless*pop) if lawless>0.0 else "none",
		("Below %d of 100 safety people are killed in quarrels and theft: about %s a year now." % [roundi(LAWLESS_BELOW*100.0),_one(lawless*pop)]) if lawless>0.0 else "Below %d of 100 safety people start dying in quarrels and theft; safety is above that now." % roundi(LAWLESS_BELOW*100.0),
		"bad" if lawless>0.0 else "good"))
	# Home guard: the trained and the watch stand as the garrison; a town needs
	# 3.5 in 100 of its people, at least 8 (military_campaign.gd
	# settlement_defense_snapshot). The townsfolk who rise are told apart:
	# they fight when raiders come, but they are no guard.
	var walls:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var required:=int(walls.get("garrison_required",maxi(8,ceili(pop*0.035))))
	var guard:=int(walls.get("garrison_guard",roundi(watch)))
	lines.append(_line("Guard at home","%d of %d" % [guard,required],
		"The watch at home is home's guard (the watch is the army): in a raid or siege they defend it; the home guard posted in our other towns stands there. A town needs 3.5 in 100 of its people on guard, at least 8.","good" if guard>=required else "bad"))
	var townsfolk:=int(walls.get("garrison_townsfolk",0))
	lines.append(_line("Townsfolk who would fight","%s at home" % _count(townsfolk) if townsfolk>0 else "none",
		"When raiders come, about 1 in 10 of the town's grown people take up arms beside the watch. They are untrained and are not counted as the guard.","plain"))
	# The watch is the army and drills at home (watch_military.gd).
	var drill:Dictionary=preload("res://scripts/watch_military.gd").role_effect(MilitaryCampaign)
	lines.append(_line("Drill of the watch","%d in 100" % roundi(float(drill.drill)*100.0),
		"Everyone keeping watch is under arms and drills at home every day%s. Ten more: %s" % [(", most of a newcomer's drill in about %d days" % int(drill.drill_days)) if int(drill.drill_days)>0 else "",String(drill.ten_more).trim_prefix("Ten more: ")],"good" if watch>0.0 else "plain"))
	# Walls and ditches: only the watch builds them (military_campaign.gd).
	var project:Dictionary=walls.get("construction",{}) if walls.get("construction") is Dictionary else {}
	if bool(project.get("active",false)):
		var daily:=minf(float(project.get("work_required",0.0))*0.04,watch*clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.15,1.25)*WATCH_WALL_WORK)
		var left:=maxf(0.0,float(project.get("work_required",0.0))-float(project.get("work_done",0.0)))
		lines.append(_line("Building defences",("%s left" % _days(left/daily)) if daily>0.0 else "stopped",
			"Only the watch builds the town's defences: the %s has %s of %s work left." % [String(project.get("name","works")).to_lower(),_whole(left),_whole(float(project.get("work_required",0.0)))],"good" if daily>0.0 else "bad"))
	else:
		lines.append(_line("Building defences","none under way","Only the watch builds the town's defences; order them from the military page or the court.","plain"))
	var custody:Dictionary=MilitaryCampaign.prisoner_custody_snapshot()
	if int(custody.get("prisoners",0))+int(custody.get("held_generals",0))>0:
		lines.append(_line("Guarding prisoners","%d of 100 guarded" % roundi(float(custody.get("guard_coverage",0.0))*100.0),
			"About one in five of the watch guards the prisoners; the fewer guarded, the more escape.","good" if float(custody.get("guard_coverage",0.0))>=1.0 else "bad"))
	# The court's orders: enforcement and the most punishments a year
	# (consequence_engine.gd security_capacity, directive death capacity).
	var enforce:=clampf(safety*0.72+clampf(watch/pop/0.08,0.0,1.0)*0.28,0.0,1.0)
	var punish:=mini(maxi(0,roundi(pop)-1),roundi(watch*3.0+pop*enforce*0.002))
	lines.append(_line("Enforcing orders","%d of 100" % roundi(enforce*100.0),
		"Orders that need force are carried out as far as the watch and safety allow, and the court can punish at most %d people a year." % punish,"good" if enforce>=0.5 else "plain"))
	_great_work_line(lines,"Defense")
	lines.append(_cost_line("Defense"))
	return {"lead":"The watch guards the town day and night: it keeps the peace, stands as the home guard, trains soldiers and builds the defences.","lines":lines}


# --- Shared lines ----------------------------------------------------------------------

## No wood left: every stand of trees the people know is cut down; how far
## the carriers look for new woods and how many would look farther
## (resource_system.gd woodland_outlook). {} while a stand still gives wood.
static func _wood_line()->Dictionary:
	var wood:Dictionary=WorldSimulation.resources.woodland_outlook()
	if int(wood.stands_known)<=0 or int(wood.stands_working)>0:return {}
	var farther:=" With %s carrying they would look as far as %d km." % [_count(int(wood.carriers_for_next)),roundi(float(wood.next_km))] if int(wood.carriers_for_next)>0 else " That is as far as they ever look."
	return _line("No wood left","%s in store" % _one(float(wood.timber)),
		"Every stand of trees the people know is cut down, so tools, weapons and building that need wood wait. Carriers look for new woods within %d km.%s" % [roundi(float(wood.reach_km)),farther],"bad")


## Heavy work: food, cutting and building together. Past 74 in 100 of the
## workers the people are overworked (consequence_engine.gd work_strain, overwork).
static func _heavy_line()->Dictionary:
	var heavy:=clampf((_raw("Food")+_raw("Extraction")+_raw("Construction"))/_able(),0.0,1.2)
	var over:=clampf((heavy-HEAVY_ONSET)/HEAVY_SPAN,0.0,1.0)
	if over>0.0:
		return _line("Heavy work","overworked",
			"%d in 100 of the workers are at heavy work (food, cutting, building). Past %d mothers die more often in childbirth and fewer children are conceived." % [roundi(heavy*100.0),roundi(HEAVY_ONSET*100.0)],"bad")
	return _line("Heavy work","%d in 100" % roundi(heavy*100.0),
		"Food, cutting and building are heavy work: the fewer at it, the better the people hold together (up to %d points). Past %d in 100 mothers die more often in childbirth and fewer children are conceived." % [roundi(HEAVY_EASE*100.0),roundi(HEAVY_ONSET*100.0)],"plain")

## A great work that favours this task makes each worker count for more
## (undertaking_system.gd benefit).
static func _great_work_line(lines:Array,role:String)->void:
	var bonus:=Undertakings.benefit(WorldSimulation.state,role)
	if bonus<=0.0:return
	lines.append(_line("Great works","+%d in 100" % roundi(bonus*100.0),"A great work that favours this work makes each person on it count for %d in 100 more." % roundi(bonus*100.0),"good"))

## The food a task's people eat beyond the everyday ration (every head set
## to it, as food_system.gd counts them), and what injuries leave.
static func _cost_line(role:String)->Dictionary:
	# Food for the work is eaten by every head set to it (food_system.gd counts
	# the role's people, not the work they get done).
	var workers:=_raw(role)
	var extra:=float(EXERTION.get(role,0.02))
	var kept:Vector2=Injuries.RETAINED_CAPACITY.get(role,Vector2(.85,.65))
	return _line("What it costs","%s rations a day" % _one(workers*extra),
		"Each person on this work eats %s of a ration a day beyond the everyday ration and is not doing other work. The hurt keep %d in 100 of their strength here, the badly hurt %d." % [_two(extra),roundi(kept.x*100.0),roundi(kept.y*100.0)],"bad" if workers>0.0 else "plain")


# --- Helpers ---------------------------------------------------------------------------

static func _workers(role:String)->float:
	return maxf(0.0,float(WorldSimulation.state.effective_workers(role)))

static func _raw(role:String)->float:
	return maxf(0.0,float(WorldSimulation.state.population_allocations.get(role,0)))

static func _able()->float:
	return maxf(1.0,float(WorldSimulation.state.able_population()))

## What one unit of builder pace is worth today (daily_work without the crews).
static func _pace_scale()->float:
	var builders:=_workers("Construction")
	return float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72))*builders/8.0*(1.0+WorldSimulation.discovery.effect("construction_rate"))

static func _line(label:String,value:String,words:String,tone:String)->Dictionary:
	return {"label":label,"value":value,"words":words,"tone":tone}

static func _people(count:float)->String:
	var n:=roundi(count)
	return "One person" if n==1 else "%s people" % _cap(_count(n))

static func _count(n:int)->String:
	return preload("res://scripts/hud/era_words.gd").count_word(n) if n<=12 else _grouped(n)

static func _grouped(n:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(n)

static func _whole(value:float)->String:
	return _grouped(roundi(value))

static func _days(days:float)->String:
	if days==INF or days>3650.0:return "more than ten years"
	if days>=540.0:return "%s years" % _one(days/365.0)
	if days>=60.0:return "%d months" % roundi(days/30.0)
	if days<0.5:return "less than a day"
	if roundi(days)==1:return "a day"
	return "%d days" % roundi(days)

static func _signed(value:float)->String:
	return ("+" if value>=0.0 else "−")+_one(absf(value))

static func _one(value:float)->String:
	return str(roundi(value)) if absf(value)>=10.0 or is_equal_approx(value,roundf(value)) else "%.1f" % value

static func _two(value:float)->String:
	return "%.2f" % value

## A pace gain in words: "about 12 in 100 faster", "about twice as fast".
static func _faster(gain:float)->String:
	if gain>=0.995:return "about %s times as fast" % _one(1.0+gain)
	if gain>=0.01:return "about %d in 100 faster" % roundi(gain*100.0)
	if gain>=0.0005:return "about %d in 1000 faster" % maxi(1,roundi(gain*1000.0))
	return "less than 1 in 1000 faster"

## A pace gain as a short value: "+12 in 100", "+4 in 1000", "2 times as fast".
static func _gain_value(gain:float)->String:
	if gain>=0.995:return "%s times as fast" % _one(1.0+gain)
	if gain>=0.01:return "+%d in 100" % roundi(gain*100.0)
	if gain>=0.0005:return "+%d in 1000" % maxi(1,roundi(gain*1000.0))
	return "+less than 1 in 1000"

static func _cap(text:String)->String:
	return text.left(1).to_upper()+text.substr(1)
