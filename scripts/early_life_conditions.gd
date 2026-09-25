extends RefCounted
## Early care practices and living conditions that decide how much avoidable
## death a young society carries.
##
## A band without clean-water habits, wound washing, known remedies, experienced
## birth attendants, shared child care, cooked weaning food or lean-season stores
## loses far more infants, children, mothers and adults than the baseline life
## table. Each practice removes part of that excess in proportion to its
## adoption. Later knowledge counts through the general effect channels, so a
## mature civilization that reached the same protections another way is never
## penalized. The excess never pushes mortality below the baseline table: this
## is an early-game model of what is not yet known, not a late-game bonus.
##
## Diet and hunger act separately and continuously. A monotonous or lean diet
## raises child mortality and lowers conception; an overworked population
## conceives less and loses more pregnancies. Infant deaths shorten the next
## birth interval (weaning ends early), so high child loss is partly replaced
## by births, as in pre-modern demography, without cancelling the loss.
##
## All results are aggregate factors for one numeric population; the profile is
## O(practices) and independent of population size.

## Each category removes the listed excess once fully covered. Coverage comes
## from the best of the listed practices (weights sum, capped at 1) and the
## general effect channels (value / scale, summed, capped at 1).
const CATEGORIES:Array[Dictionary]=[
	{"id":"water","label":"Clean water and waste","under5":0.80,"child":0.40,"adult":0.06,"neonatal":0.20,"maternal":0.0,
		"practices":{"clean_water":0.60,"well_siting":0.25,"drainage":0.20,"latrine_siting":0.30},
		"channels":{"water_safety":0.22,"sanitation":0.20},
		"missing":"Children die of fouled water and summer fevers."},
	{"id":"wounds","label":"Wound and injury care","under5":0.08,"child":0.12,"adult":0.14,"neonatal":0.0,"maternal":0.25,
		"practices":{"wound_cleaning":0.75,"labor_rotations":0.15,"splint_and_bracing_technique":0.25},
		"channels":{"injury_risk":-0.14},
		"missing":"Cuts, bites and falls fester; childbed fever goes untreated."},
	{"id":"remedies","label":"Remedies and care of the sick","under5":0.40,"child":0.28,"adult":0.10,"neonatal":0.0,"maternal":0.0,
		"practices":{"herbal_classification":0.65,"isolation_practice":0.35,"case_records":0.20,"dietary_healing_regimens":0.25},
		"channels":{"health_protection":0.22},
		"missing":"Fevers and coughs run their course with no known remedy."},
	{"id":"birth","label":"Birth care","under5":0.0,"child":0.0,"adult":0.0,"neonatal":1.10,"maternal":1.25,
		"practices":{"birth_attendants":0.70,"maternal_recovery":0.30,"trained_midwives":0.50,"labor_position_customs":0.20,"cord_afterbirth_handling":0.25},
		"channels":{"maternal_safety":0.20},
		"missing":"Mothers labor alone; difficult births and newborns are often lost."},
	{"id":"childcare","label":"Child care and weaning food","under5":0.56,"child":0.12,"adult":0.0,"neonatal":0.25,"maternal":0.0,
		"practices":{"shared_childcare":0.55,"food_pounding_mortars":0.20,"pulse_splitting":0.10,"food_steaming_vessels":0.15,"infant_swaddling_practice":0.15,"weaning_food_softening":0.20},
		"channels":{"neonatal_survival":0.18},
		"missing":"Toddlers are weaned onto hard food and left unwatched during work."},
	{"id":"cooking","label":"Cooked and sorted food","under5":0.26,"child":0.10,"adult":0.04,"neonatal":0.0,"maternal":0.0,
		"practices":{"edible_resource_recognition":0.35,"hearth_roasting_control":0.35,"earth_oven_cooking":0.15,"food_steaming_vessels":0.15,"ember_tending":0.10},
		"channels":{"nutrition_quality":0.20},
		"missing":"Raw or spoiled food and mistaken plants sicken the young."},
	{"id":"stores","label":"Lean-season stores","under5":0.30,"child":0.14,"adult":0.06,"neonatal":0.0,"maternal":0.0,
		"practices":{"food_drying":0.35,"smoking":0.30,"public_stores":0.20,"sealed_vessels":0.20},
		"channels":{"food_storage":0.30},
		"missing":"Nothing is put by, so each winter and failed season falls on the children."},
]
## Storage Pits count toward lean-season stores once built.
const STORAGE_WORKS:={"Storage Pits":0.30,"Public Stores":0.20}
## Days of food history averaged into the diet a child actually lives on.
const DIET_WINDOW_DAYS:=120
## New worlds apply the rules at once; older saves reach them over two years.
const BLEND_DAYS:=730.0
## First-year loss with every early protection in place; only loss above it
## shortens birth intervals, so an established society's fertility is unchanged.
const REFERENCE_INFANT_LOSS:=0.10
## Mortality condition factor of a healthy, fed and housed settlement.
const GOOD_CONDITIONS:=0.55

## --- research_600 pre-modern burden (Phase 3 balance) ---
## The baseline life table is close to a modern one in good conditions. Before
## germ theory, endemic infection, parasites, accidents and violence kept every
## age band far above it however well a society practiced what it knew, so
## life expectancy at birth stayed near 20-35 (docs/research/BENCHMARKS_600.md).
## ERA_BURDEN multiplies each band's hazard; general health knowledge lifts it
## only through its era-capped effect channels (SocietyModel.era_ceiling_for),
## so it lifts little before the modern era. Missing practices add their excess
## on top, weighted by EXCESS_WEIGHT. Old saves blend in with early_care_blend.
const ERA_BURDEN:={"under5":4.4,"child":5.0,"adult":4.5,"elder":2.3,"neonatal":2.1,"maternal":2.6}
const EXCESS_WEIGHT:={"under5":0.15,"child":0.35,"adult":0.5}
## Channel totals that relieve the burden, each over its modern limit.
const RELIEF_CHANNELS:={"health_protection":0.55,"sanitation":0.65,"water_safety":0.60,"disease_exposure":-0.55}
const RELIEF_POWER:=2.5
## Long nursing, infection-caused sterility and widowhood kept even well-fed
## pre-modern crude birth rates near 40-48 per 1,000 (docs/research/BENCHMARKS_600.md):
## above the knee the diet's lift to conception rises only at this slope (the
## best-fed society's 1.05 becomes 0.9), while hardship still lowers it in full.
const PREMODERN_FECUNDITY_KNEE:=0.8
## research_600: an infant's death ends nursing and shortens the next birth
## interval; each point of first-year loss above the reference adds this much
## to conception (1.3: about +20% at 250 infant deaths per 1,000, which keeps
## crude birth rates inside the benchmark's 44-48 instead of past 50).
const INFANT_LOSS_REPLACEMENT:=1.3
const PREMODERN_FECUNDITY_SLOPE:=0.4
## Hunger and sickness absorb at most this share of the burden (see age_multiplier).
const BURDEN_OVERLAP_FLOOR:=0.35

## --- research_600 carrying capacity (Phase 3 balance) ---
## Land, wild grounds and fields around each settlement feed only so many
## people with the era's methods. Past CROWDING_ONSET of that capacity, the
## crowded, hungrier and sicker population dies more and marries later, so
## growth settles near the capacity and follows it as methods, fields and
## daughter settlements extend it (booms and busts come from harvests).
## Capacity per settlement by game year (people, before improvements).
const TERRITORY_CAPACITY:Array=[[0.0,320.0],[100.0,420.0],[200.0,650.0],[300.0,880.0],[600.0,2600.0],[1500.0,9000.0],[2800.0,60000.0]]
const CROWDING_ONSET:=0.6
const CROWDING_MORTALITY:=0.3
const CROWDING_CONCEPTION:=1.2
## A remnant far below the founding territory's capacity finds land plentiful:
## couples marry earlier (the preventive check relaxes), so a thinned-out band
## recovers instead of dying out.
const SPARE_LAND_ONSET:=0.3
const SPARE_LAND_CONCEPTION:=2.0

## People the society's settled land can carry now: territory by era and
## settlement count, raised by (era-capped) cultivation, soil and storage
## knowledge and lowered by worn-out wild grounds.
static func carrying_capacity(state:Node,discovery:Node)->float:
	var era:=float(state.elapsed_days)/365.0
	var base:=float(TERRITORY_CAPACITY[TERRITORY_CAPACITY.size()-1][1])
	for index in range(1,TERRITORY_CAPACITY.size()):
		var high:Array=TERRITORY_CAPACITY[index]
		if era<=float(high[0]):
			var low:Array=TERRITORY_CAPACITY[index-1]
			base=lerpf(float(low[1]),float(high[1]),(era-float(low[0]))/(float(high[0])-float(low[0])))
			break
	var settlements:=maxi(1,(state.player_settlements as Array).size())
	# Daughter settlements claim less new land each than the first.
	var territory:=1.0+sqrt(float(settlements-1))*1.6
	var methods:=1.0+maxf(0.0,discovery.effect("cultivation_yield"))+maxf(0.0,discovery.effect("soil_productivity"))*0.6+maxf(0.0,discovery.effect("food_output"))*0.5+maxf(0.0,discovery.effect("food_storage"))*0.25
	var grounds:=0.0
	var sources:Dictionary=state.food_source_health
	for key:Variant in sources:grounds+=float(sources[key])
	grounds=clampf(grounds/maxf(1.0,float(sources.size())),0.4,1.0) if not sources.is_empty() else 1.0
	return base*territory*methods*lerpf(0.6,1.0,grounds)

## Care decrees (government_policy_catalog.gd) organize people to do what a
## missing practice would: fetch and store clean water, tend the sick and
## newborns, keep watch against fire, falls and beasts. Their policy channels
## add coverage to these categories while the decree runs.
const DECREE_COVER:={"water":"water_care_coverage","remedies":"sick_care_coverage","childcare":"sick_care_coverage","wounds":"injury_care_coverage"}

static func _decree_cover(category_id:String)->float:
	if not DECREE_COVER.has(category_id) or WorldSimulation.consequences==null:return 0.0
	return maxf(0.0,float(WorldSimulation.consequences.policy_effect(String(DECREE_COVER[category_id]))))

## Share (0..1) of the pre-modern burden lifted by general health knowledge.
static func burden_relief(discovery:Node)->float:
	var total:=0.0
	for channel:String in RELIEF_CHANNELS:
		total+=clampf(discovery.effect(channel)/float(RELIEF_CHANNELS[channel]),0.0,1.0)
	return pow(total/float(RELIEF_CHANNELS.size()),RELIEF_POWER)

## Measurement hook: probes set this to replay the rules before this change
## (blend held at 0) for before/after comparisons. Never set by the game.
static var legacy_comparison:=false

## Advances the save-compatibility blend and returns the current profile.
static func refresh(state:Node,discovery:Node,context:Dictionary={})->Dictionary:
	var blend:=clampf(float(state.early_care_blend),0.0,1.0)
	if legacy_comparison:
		state.early_care_blend=0.0
	elif blend<1.0:
		# A world still in its first month began under these rules. An older save
		# moves to them gradually instead of losing people on the day it loads.
		blend=1.0 if float(state.elapsed_days)<30.0 else minf(1.0,blend+float(WorldSimulation.span)/BLEND_DAYS)
		state.early_care_blend=blend
	var result:=profile(state,discovery,context)
	state.early_care=result
	# Tomorrow's conception uses today's first-year loss (weaning cut short).
	result["infant_loss_estimate"]=CivilizationIndicators.infant_mortality_per_1000(state,discovery)/1000.0
	return result

## Mutation-free profile for the given state. `context` may carry
## "overwork" (0..1) and "infant_loss" (first-year loss 0..1) from the day.
static func profile(state:Node,discovery:Node,context:Dictionary={})->Dictionary:
	var known:Array=state.known_discoveries
	var completed:Array=state.settlement_completed
	var blend:=clampf(float(state.early_care_blend),0.0,1.0)
	var excess:={"under5":0.0,"child":0.0,"adult":0.0,"neonatal":0.0,"maternal":0.0}
	var categories:Array[Dictionary]=[]
	for category:Dictionary in CATEGORIES:
		var practice_cover:=0.0
		var named:Array[String]=[]
		var missing_names:Array[String]=[]
		var practices:Dictionary=category.practices
		for id:String in practices:
			if id in known:
				var level:float=discovery.practiced(id) if discovery.has_method("practiced") else discovery.adoption(id)
				practice_cover+=float(practices[id])*clampf(level,0.0,1.0)
				named.append(_name(discovery,id))
			else:
				var entry:Dictionary=discovery.discovery_definition(id)
				if not entry.is_empty() and missing_names.size()<2:missing_names.append(String(entry.get("name",id)))
		if String(category.id)=="stores":
			for work:String in STORAGE_WORKS:
				if work in completed:
					practice_cover+=float(STORAGE_WORKS[work])
					named.append(work)
		var channel_cover:=0.0
		var channels:Dictionary=category.channels
		for channel:String in channels:
			var scale:=float(channels[channel])
			channel_cover+=maxf(0.0,discovery.effect(channel)/scale)
		# research_600: organized care decrees cover part of a missing practice.
		var coverage:=clampf(maxf(practice_cover,channel_cover)+_decree_cover(String(category.id)),0.0,1.0)
		for key:String in excess:
			var amount:=float(category.get(key,0.0))
			excess[key]=float(excess[key])+amount*(1.0-coverage)
		categories.append({"id":category.id,"label":category.label,"coverage":coverage,"known":named,"next":missing_names,"missing":String(category.missing)})
	var diet:=diet_window(state)
	var malnutrition:=clampf(float(state.malnutrition_burden),0.0,1.0)
	# Children feel a thin, monotonous diet long before adults starve.
	var nutrition:=clampf(1.0+malnutrition*1.1+maxf(0.0,0.66-diet)*2.2-maxf(0.0,diet-0.76)*0.45,0.85,2.2)
	var overwork:=clampf(float(context.get("overwork",(state.early_care as Dictionary).get("overwork",0.0))),0.0,1.0)
	var raw:={
		"under5":(1.0+float(excess.under5))*nutrition,
		"child":(1.0+float(excess.child))*(1.0+(nutrition-1.0)*0.5),
		"adult":1.0+float(excess.adult)+malnutrition*0.15,
		"neonatal":(1.0+float(excess.neonatal))*(1.0+maxf(0.0,0.58-diet)*0.9+malnutrition*0.5),
		"maternal":(1.0+float(excess.maternal))*(1.0+malnutrition*0.6+overwork*0.20),
	}
	# Conception: a well-fed mother conceives sooner; heavy labor delays it; an
	# infant's death ends nursing and shortens the next interval.
	var infant_loss:=clampf(float(context.get("infant_loss",(state.early_care as Dictionary).get("infant_loss",0.0))),0.0,0.6)
	var conception:=lerpf(0.80,1.05,clampf((diet-0.35)/0.45,0.0,1.0))
	if conception>PREMODERN_FECUNDITY_KNEE:conception=PREMODERN_FECUNDITY_KNEE+(conception-PREMODERN_FECUNDITY_KNEE)*PREMODERN_FECUNDITY_SLOPE
	conception*=(1.0-overwork*0.16)*(1.0+maxf(0.0,infant_loss-REFERENCE_INFANT_LOSS)*INFANT_LOSS_REPLACEMENT)
	var result:={"blend":blend,"diet":diet,"nutrition_factor":nutrition,"overwork":overwork,"infant_loss":infant_loss,"categories":categories}
	for key:String in raw:result[key]=lerpf(1.0,float(raw[key]),blend)
	result["conception"]=lerpf(1.0,conception,blend)
	var relief:=burden_relief(discovery)
	var capacity:=carrying_capacity(state,discovery)
	var crowding:=maxf(0.0,float(state.population_exact)/maxf(1.0,capacity)-CROWDING_ONSET)
	var burden:Dictionary={}
	for key:String in ERA_BURDEN:
		var crowd:=1.0+crowding*CROWDING_MORTALITY if key in ["under5","child","adult","elder"] else 1.0
		burden[key]=lerpf(1.0,(1.0+(float(ERA_BURDEN[key])-1.0)*(1.0-relief))*crowd,blend)
	# Spare land rescues only a remnant: it is judged against the founding
	# territory (not later capacity), so a band thinned below a few score
	# people recovers while a large but slow-growing society gets no boost.
	var founding:=float((TERRITORY_CAPACITY[0] as Array)[1])
	var spare:=maxf(0.0,SPARE_LAND_ONSET-float(state.population_exact)/founding)
	result["conception"]=float(result.conception)*lerpf(1.0,maxf(0.3,1.0-crowding*CROWDING_CONCEPTION)*(1.0+spare*SPARE_LAND_CONCEPTION),blend)
	result["carrying_capacity"]=capacity
	result["crowding"]=crowding
	var weights:Dictionary={}
	for key:String in EXCESS_WEIGHT:weights[key]=lerpf(1.0,float(EXCESS_WEIGHT[key]),blend)
	result["burden"]=burden
	result["excess_weight"]=weights
	result["burden_relief"]=relief
	result["pregnancy_risk"]=lerpf(1.0,1.0+overwork*0.35+maxf(0.0,0.5-diet)*0.6,blend)
	return result

static func _name(discovery:Node,id:String)->String:
	var entry:Dictionary=discovery.discovery_definition(id)
	return String(entry.get("name",id.capitalize()))

## Mean diet quality over recent food history; seasonal lean spells count.
static func diet_window(state:Node)->float:
	var history:Array=state.food_history
	if history.is_empty():return 0.62
	var total:=0.0
	var count:=0
	for index in range(history.size()-1,maxi(-1,history.size()-1-DIET_WINDOW_DAYS),-1):
		total+=float((history[index] as Dictionary).get("diet_quality",0.62))
		count+=1
	return clampf(total/maxf(1.0,float(count)),0.0,1.0)

## Life-table multiplier for one year of age under the current profile.
## `condition_factor` is GameState._mortality_condition_factor(): where hunger,
## exposure and sickness already raise every death rate, missing practices add
## proportionally less, so the same deaths are not counted twice.
static func age_multiplier(care:Dictionary,age:int,condition_factor:float=GOOD_CONDITIONS)->float:
	if care.is_empty():return 1.0
	var band:="adult"
	if age<5:band="under5"
	elif age<15:band="child"
	var raw:=float(care.get(band,1.0))
	var overlap:=clampf(pow(GOOD_CONDITIONS/maxf(0.01,condition_factor),1.5),0.4,1.0)
	var excess:=raw if raw<=1.0 else 1.0+(raw-1.0)*overlap
	var burden:Dictionary=care.get("burden",{})
	if burden.is_empty():return excess
	var weight:=float((care.get("excess_weight",{}) as Dictionary).get(band,1.0))
	# Hunger, exposure and sickness in the condition factor are largely the same
	# endemic killers, so the burden overlaps them just as missing practices do.
	var era_burden:=1.0+(float(burden.get("elder" if age>=45 else band,1.0))-1.0)*maxf(BURDEN_OVERLAP_FLOOR,overlap)
	return era_burden*(1.0+(excess-1.0)*weight)

## Newborn and maternal death multipliers including the pre-modern burden. The
## burden adds to the missing-care excess rather than compounding it: the same
## untended births are not lost twice.
static func neonatal_factor(care:Dictionary)->float:
	return float(care.get("neonatal",1.0))+float((care.get("burden",{}) as Dictionary).get("neonatal",1.0))-1.0

static func maternal_factor(care:Dictionary)->float:
	return float(care.get("maternal",1.0))+float((care.get("burden",{}) as Dictionary).get("maternal",1.0))-1.0

## Player-facing lines for the health view: what protects life, what is missing.
static func explanation(care:Dictionary)->Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	for category:Dictionary in care.get("categories",[]):
		var coverage:=float(category.get("coverage",0.0))
		var known:=", ".join(PackedStringArray(category.get("known",[])))
		var next:=", ".join(PackedStringArray(category.get("next",[])))
		var status:="Established" if coverage>=0.95 else ("Not yet practiced" if coverage<=0.02 else "Partly practiced")
		var detail:=""
		if coverage>=0.95:detail="In practice: %s." % known if known!="" else "Covered by later knowledge."
		elif known=="":detail=String(category.get("missing",""))+(" To learn: %s." % next if next!="" else "")
		else:detail="In practice: %s.%s" % [known," To learn: %s." % next if next!="" else ""]
		rows.append({"name":String(category.get("label","")),"coverage":coverage,"status":status,"detail":detail})
	return rows
