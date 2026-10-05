extends RefCounted
## FRESH FOOD, SMALL STORES, KEEPERS AND CARERS (docs/PEOPLE_FIRST.md, B).
##
## One place for the numbers the food and health rules share, and the plain
## effects of the three roles they read, so every screen says what the engine
## does:
##   getting food (Food)      fresh food each day; the fresh share of what is
##                            eaten leans health up or down (FRESH_HEALTH).
##   carrying (Logistics)     fresh food reaches mouths before it turns: less
##                            fresh spoilage and a wider daily harvest.
##   keeping and caring       keepers stop stored food rotting; carers tend
##   (Administration)         newborns, the sick, mothers and the hurt
##                            (early_life_conditions.gd), and lift health.
##                            The same people keep the stores, care for the
##                            people and do the office work (reach, records,
##                            cohesion: consequence_engine.gd admin_coverage):
##                            each of the three counts all of them, against
##                            its own share of the people.
## A store is a lean buffer, not wealth: food security counts it only up to
## LEAN_DAYS, and deaths and sickness read what is eaten, never the store.
## Every people follows these rules; each town reads its own people.

const SPAN:=preload("res://scripts/day_span.gd")

## Days of food that carry the people through a lean spell. Food security
## counts the store up to here (consequence_engine.gd), and the realm's
## relief brings a hungry town back to it (realm_purse.gd RELIEF_TARGET).
const LEAN_DAYS:=20.0
## Food-security points the lean buffer gives when it is full.
const LEAN_WEIGHT:=0.30
## Health leans by FRESH_HEALTH × (fresh share of what is eaten − 0.5) above
## half fresh (up to +0.06 on fresh food alone), and by FRESH_PENALTY × the
## same below it (at most −0.02 on stores alone): a farming town living on
## its grain is not ruined for it, while more fresh food still pays.
const FRESH_HEALTH:=0.12
const FRESH_PENALTY:=0.04
const FRESH_EVEN:=0.5
## Carriers: full cover at CARRY_SHARE of the people. Full cover halves fresh
## spoilage and widens the ground whose harvest arrives fresh by CARRY_REACH.
const CARRY_SHARE:=0.03
const CARRY_FRESH_CUT:=0.5
const CARRY_REACH:=0.25
## Keepers (Administration): full cover at KEEP_SHARE of the people cuts
## stored spoilage by KEEP_STORED_CUT (beside the Quartermaster's hand).
const KEEP_SHARE:=0.02
const KEEP_STORED_CUT:=0.40
## Carers (Administration): full cover at CARE_SHARE of the people, so the
## usual 4 in 100 on keeping and caring give about half, and a people that
## leans hard on caring gets the rest. Their cover of each early-life category
## is early_life_conditions.gd CARER_COVER and CARER_BURDEN; full cover also
## lifts health by CARE_HEALTH. Care is learned by doing: the cover settles
## toward the hands on it over CARE_SETTLE_DAYS.
const CARE_SHARE:=0.08
const CARE_HEALTH:=0.03
const CARE_SETTLE_DAYS:=60.0
## "What ten more would do" on the People view.
const MORE:=10.0
## The reserve the planners aim for (GovernmentPeopleSystem.RESERVE_TARGET_DAYS
## keeps it as a plain number for the fast sim): the lean buffer and half again.
const RESERVE_DAYS:=LEAN_DAYS*1.5
## The rulers' store gates (civilization_strategy.gd preferences: founding a
## town, marching to war, seeking peace, scouting, hard drill; a great work's
## start, pace and extra crews; food gifts; civilization_controller.gd) were set
## when the planners kept 60 days and the pits filled for months. The planners
## now keep RESERVE_DAYS, so each gate asks STORE_GATE of the days it did, and
## founding a town never asks more than full stores (RESERVE_DAYS).
const STORE_GATE:=0.5

# --- The rules -------------------------------------------------------------------------

## 0..1: how much of a lean spell the store carries the people through.
static func lean_buffer(food_days:float)->float:
	return clampf(food_days/LEAN_DAYS,0.0,1.0)

## Food security's target from the day's food (consequence_engine.gd), and
## what is eaten (fed): the same with the store counted full, which deaths
## and sickness read. `production_ratio` is what came in over the need,
## `intake` what was eaten over it. {security, fed, lean}.
static func security_targets(food_days:float,production_ratio:float,intake:float,diet:float,reserve:float,malnutrition:float)->Dictionary:
	var eaten:=0.05+minf(1.15,production_ratio)*0.25+intake*0.18+diet*0.12+reserve*0.10-malnutrition*0.24
	var lean:=lean_buffer(food_days)
	return {"security":clampf(eaten+lean*LEAN_WEIGHT,0.02,0.98),"fed":clampf(eaten+LEAN_WEIGHT,0.02,0.98),"lean":lean}

## Health points from the fresh share (0..1) of what is eaten.
static func fresh_health(fresh_share:float)->float:
	var past:=clampf(fresh_share,0.0,1.0)-FRESH_EVEN
	return (FRESH_HEALTH if past>=0.0 else FRESH_PENALTY)*past

static func carry_cover(carriers:float,people:float)->float:
	return clampf(maxf(0.0,carriers)/maxf(1.0,people*CARRY_SHARE),0.0,1.0)

static func keep_cover(keepers:float,people:float)->float:
	return clampf(maxf(0.0,keepers)/maxf(1.0,people*KEEP_SHARE),0.0,1.0)

static func care_cover(carers:float,people:float)->float:
	return clampf(maxf(0.0,carers)/maxf(1.0,people*CARE_SHARE),0.0,1.0)

## Fresh spoilage multiplier from carriers' cover (1 = no carriers).
static func fresh_spoilage_factor(cover:float)->float:
	return 1.0-CARRY_FRESH_CUT*clampf(cover,0.0,1.0)

## Stored spoilage multiplier from keepers' cover (1 = no keepers).
static func stored_spoilage_factor(cover:float)->float:
	return 1.0-KEEP_STORED_CUT*clampf(cover,0.0,1.0)

## Wild ground whose harvest arrives fresh, as a multiple of what the
## gatherers reach on their own.
static func reach_factor(cover:float)->float:
	return 1.0+CARRY_REACH*clampf(cover,0.0,1.0)

## The people the town's covers are measured against (its own count in its day).
static func _people(state:Node)->float:
	return maxf(1.0,float(state.population_exact))

## The hands on each role today, as the engine counts them (effective workers:
## the hurt count less; records-keepers reserved by civic_administration.gd
## are not tending the stores or the sick).
static func carriers_of(state:Node)->float:
	return maxf(0.0,float(state.effective_workers("Logistics")))

static func keepers_of(state:Node)->float:
	return maxf(0.0,float(state.effective_workers("Administration")))

static func carry_cover_of(state:Node)->float:
	return carry_cover(carriers_of(state),_people(state))

static func keep_cover_of(state:Node)->float:
	return keep_cover(keepers_of(state),_people(state))

## The carers' cover the hands on keeping and caring would give at once.
static func care_target_of(state:Node)->float:
	return care_cover(keepers_of(state),_people(state))

## The carers' cover the engine applies today (settled, early_life_conditions.gd).
static func care_cover_of(state:Node)->float:
	return clampf(float((state.early_care as Dictionary).get("carer_cover",0.0)),0.0,1.0)

## A ruler's store gate of `days` (set when stores ran to months), today.
static func store_gate(days:float)->float:
	return days*STORE_GATE

## A day's settling of the carers' cover toward `target` (a multi-day step
## settles for each day it covers).
static func settle_care(previous:float,target:float)->float:
	return lerpf(clampf(previous,0.0,1.0),clampf(target,0.0,1.0),SPAN.rate(1.0/CARE_SETTLE_DAYS))

# --- What each role does, for the People view (docs/PEOPLE_FIRST.md F) -------------------

## What a role's people do for fresh food, the stores and care now, and what
## ten more there would do, in the engine's numbers. `role` is "Food",
## "Logistics" or "Administration"; any other role gives {}.
## {role, people, lines:[{label, value, words, tone}], now:{...}, more:{...}}:
## a line has the shape task_impact.gd uses; `now` and `more` hold the bare
## numbers (covers 0..1, rations a day, health points, infant deaths in 1,000).
static func role_effect(role:String)->Dictionary:
	match role:
		"Food":return _getting_food()
		"Logistics":return _carrying()
		"Administration":return _keeping_and_caring()
	return {}

## Ten more people on `role`, as the engine would count them (the hurt and
## the reserved counted as today).
static func _ten_more(state:Node,role:String)->float:
	var raw:=maxf(0.0,float(state.population_allocations.get(role,0)))
	var effective:=maxf(0.0,float(state.effective_workers(role)))
	return MORE*(effective/raw if raw>0.5 else 1.0)

static func _getting_food()->Dictionary:
	var state=WorldSimulation.state
	var m:Dictionary=state.simulation_metrics
	var getters:=maxf(0.0,float(state.effective_workers("Food")))
	var eaten:=maxf(0.0,float(m.get("food_eaten",0.0)))
	var consumed:Dictionary=m.get("food_consumed_by_type",{}) if m.get("food_consumed_by_type") is Dictionary else {}
	var fresh_eaten:=float(consumed.get("Fresh food",0.0))
	var share:=clampf(float(m.get("food_fresh_share",fresh_eaten/eaten if eaten>0.0 else 0.0)),0.0,1.0)
	var harvest:Dictionary=m.get("food_harvest",{}) if m.get("food_harvest") is Dictionary else {}
	var fresh_in:=float(harvest.get("Fresh plants",0.0))+float(harvest.get("Fresh meat",0.0))+float(harvest.get("Fish",0.0))
	var extra:=_more_fresh(state,getters,fresh_in)
	# What reaches mouths: fresh food is eaten first, so more fresh food raises
	# the fresh share until it feeds everyone; the rest is put by or spoils.
	var spoil:=_fresh_rate(state)
	var more_share:=clampf((fresh_eaten+extra*(1.0-spoil))/eaten,0.0,1.0) if eaten>0.0 else share
	var now_points:=fresh_health(share)*100.0
	var more_points:=fresh_health(more_share)*100.0
	var lines:Array=[]
	if eaten<=0.0:
		lines.append(_line("Fresh food","counted at dawn","How much of what is eaten is fresh is counted after the first day. Fresh food keeps people well; stored food alone does not.","plain"))
	else:
		var more_words:="Ten more getting food would bring about %s more fresh rations a day; " % _whole(extra)
		more_words+="everything eaten is already fresh, so the rest is put by or spoils." if share>=0.995 else "%d in 10 would be eaten fresh, health %s points." % [roundi(more_share*10.0),_signed(more_points)]
		lines.append(_line("Fresh food","%d in 10 eaten fresh" % roundi(share*10.0),
			"%s of the %s rations eaten today were fresh. %s %s" % [_whole(fresh_eaten),_whole(eaten),fresh_sentence(share),more_words],
			"good" if share>=FRESH_EVEN else "bad"))
	return {"role":"Food","people":getters,"lines":lines,
		"now":{"fresh_share":share,"fresh_rations":fresh_in,"health_points":now_points},
		"more":{"fresh_share":more_share,"fresh_rations":fresh_in+extra,"health_points":more_points}}

## Fresh rations a day ten more getters would add, by the harvest rule itself
## (food_system.gd _produce: wild grounds give less the harder they are worked).
static func _more_fresh(state:Node,getters:float,fresh_in:float)->float:
	var food:Variant=WorldSimulation.food
	var more:=_ten_more(state,"Food")
	if food==null or not food.has_method("_produce"):return fresh_in/maxf(1.0,getters)*more
	var labor:=clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)
	var ecology:=clampf(float(state.simulation_metrics.get("ecology",0.88)),0.04,1.0)
	var traveling:=bool(state.convoy_traveling)
	var base:Dictionary=food._produce(getters,labor,ecology,traveling)
	var grown:Dictionary=food._produce(getters+more,labor,ecology,traveling)
	var before:=float(base.get("Fresh plants",0.0))+float(base.get("Fresh meat",0.0))+float(base.get("Fish",0.0))
	var after:=float(grown.get("Fresh plants",0.0))+float(grown.get("Fresh meat",0.0))+float(grown.get("Fish",0.0))
	# Scaled to today's real harvest (siege, blockade and the day's luck alike).
	if before>0.001 and fresh_in>0.0:return maxf(0.0,(after-before)*fresh_in/before)
	return maxf(0.0,after-before)

static func _fresh_rate(state:Node)->float:
	var food:Variant=WorldSimulation.food
	if food==null or not food.has_method("_spoilage_rates"):return 0.04
	return clampf(float((food._spoilage_rates(bool(state.convoy_traveling)) as Array)[0]),0.0,1.0)

static func _carrying()->Dictionary:
	var state=WorldSimulation.state
	var m:Dictionary=state.simulation_metrics
	var people:=_people(state)
	var carriers:=carriers_of(state)
	var cover:=carry_cover(carriers,people)
	var more_cover:=carry_cover(carriers+_ten_more(state,"Logistics"),people)
	var spoiled:Dictionary=m.get("food_spoilage_by_type",{}) if m.get("food_spoilage_by_type") is Dictionary else {}
	var fresh_lost:=float(spoiled.get("Fresh food",0.0))
	# Today's fresh spoilage was already cut by the cover; without carriers it
	# would have been fresh_lost ÷ factor.
	var bare:=fresh_lost/maxf(0.05,fresh_spoilage_factor(cover))
	var saved:=bare-fresh_lost
	var more_saved:=bare*(1.0-fresh_spoilage_factor(more_cover))
	var lines:Array=[]
	var more_words:="It is full already." if cover>=1.0 else "Ten more would make it %d in 100 less, about %s rations a day saved." % [roundi(CARRY_FRESH_CUT*more_cover*100.0),_one(more_saved)]
	lines.append(_line("Fresh food kept from spoiling","%d in 100 less spoils" % roundi(CARRY_FRESH_CUT*cover*100.0) if cover>0.0 else "none",
		"%s About %s rations a day are saved. %s" % [carrying_sentence(cover,people),_one(saved),more_words],
		"good" if cover>0.0 else "bad"))
	lines.append(_line("Reach of the daily harvest","+%d in 100 ground" % roundi(CARRY_REACH*cover*100.0) if cover>0.0 else "none",
		"With carriers the food getters work %d in 100 more ground whose food still arrives fresh, so the wild harvest gives more where the land is pressed and wears it less.%s" % [roundi(CARRY_REACH*cover*100.0),"" if cover>=1.0 else " Ten more carriers: +%d in 100." % roundi(CARRY_REACH*more_cover*100.0)],
		"good" if cover>0.0 else "plain"))
	return {"role":"Logistics","people":carriers,"lines":lines,
		"now":{"carry_cover":cover,"fresh_spoilage_cut":CARRY_FRESH_CUT*cover,"rations_saved":saved,"reach":CARRY_REACH*cover},
		"more":{"carry_cover":more_cover,"fresh_spoilage_cut":CARRY_FRESH_CUT*more_cover,"rations_saved":more_saved,"reach":CARRY_REACH*more_cover}}

static func _keeping_and_caring()->Dictionary:
	var state=WorldSimulation.state
	var m:Dictionary=state.simulation_metrics
	var people:=_people(state)
	var hands:=keepers_of(state)
	var more_hands:=hands+_ten_more(state,"Administration")
	var keep:=keep_cover(hands,people)
	var more_keep:=keep_cover(more_hands,people)
	var spoiled:Dictionary=m.get("food_spoilage_by_type",{}) if m.get("food_spoilage_by_type") is Dictionary else {}
	var stored_lost:=float(spoiled.get("Stored food",0.0))
	var bare:=stored_lost/maxf(0.05,stored_spoilage_factor(keep))
	var saved:=bare-stored_lost
	var more_saved:=bare*(1.0-stored_spoilage_factor(more_keep))
	var care_now:=care_cover_of(state)
	# Ten more raise the cover the hands are settling toward; the cover
	# already learned stays: now + (target with ten more − target now).
	var care_more:=clampf(care_now+care_cover(more_hands,people)-care_target_of(state),0.0,1.0)
	var infants:=_infant_deaths(state,care_now)
	var infants_more:=_infant_deaths(state,care_more)
	var lines:Array=[]
	var keep_more:="It is full already." if keep>=1.0 else "Ten more would make it %d in 100 less, about %s rations a day saved." % [roundi(KEEP_STORED_CUT*more_keep*100.0),_one(more_saved)]
	lines.append(_line("Stores kept from rotting","%d in 100 less rots" % roundi(KEEP_STORED_CUT*keep*100.0) if keep>0.0 else "none",
		"%s About %s rations a day are saved. %s" % [keeping_sentence(keep,people),_one(saved),keep_more],
		"good" if keep>0.0 else "bad"))
	var care_more_words:=" Ten more carers: about %d in 1,000." % roundi(infants_more) if care_more>care_now+0.005 else ""
	lines.append(_line("Newborns, mothers and the sick tended","%d in 100 of full care" % roundi(care_now*100.0) if care_now>0.005 else "none",
		"%s About %d in 1,000 babies die before their first year now.%s" % [caring_sentence(care_now,care_target_of(state),people),roundi(infants),care_more_words],
		"good" if care_now>=0.5 else ("plain" if care_now>0.005 else "bad")))
	return {"role":"Administration","people":hands,"lines":lines,
		"now":{"keep_cover":keep,"stored_spoilage_cut":KEEP_STORED_CUT*keep,"rations_saved":saved,"care_cover":care_now,"care_target":care_target_of(state),"infant_deaths_per_1000":infants,"health_points":CARE_HEALTH*care_now*100.0},
		"more":{"keep_cover":more_keep,"stored_spoilage_cut":KEEP_STORED_CUT*more_keep,"rations_saved":more_saved,"care_cover":care_more,"infant_deaths_per_1000":infants_more,"health_points":CARE_HEALTH*care_more*100.0}}

## Babies who die before their first year in 1,000 with carers' cover `cover`,
## by the indicator the health screen shows (the care profile recomputed with
## that cover; nothing is kept).
static func _infant_deaths(state:Node,cover:float)->float:
	var discovery:Variant=WorldSimulation.discovery
	if discovery==null:return 0.0
	var stored:Dictionary=state.early_care
	if is_equal_approx(cover,care_cover_of(state)) and not stored.is_empty():
		return CivilizationIndicators.infant_mortality_per_1000(state,discovery)
	# Loaded, not preloaded: early_life_conditions.gd preloads this script.
	var care:Dictionary=load("res://scripts/early_life_conditions.gd").profile(state,discovery,{"carer_cover":cover,"overwork":float(stored.get("overwork",0.0)),"infant_loss":float(stored.get("infant_loss",0.0))})
	state.early_care=care
	var result:=CivilizationIndicators.infant_mortality_per_1000(state,discovery)
	state.early_care=stored
	return result

# --- Words for the Food and Health pages ---------------------------------------------------

## The store as a lean buffer: how much of one it holds and what that is worth.
static func store_sentence(food_days:float)->String:
	if food_days<0.0:return ""
	var lean:=lean_buffer(food_days)
	if lean>=1.0:
		return "The stores hold %s of food, more than the %d days that carry the people through a lean spell; food security counts no more than that. What keeps people alive and well is what they eat each day." % [_days(food_days),roundi(LEAN_DAYS)]
	return "The stores hold %s of the %d days of food that carry the people through a lean spell; food security is %d points short until they do. No one sickens for a small store, only for going without." % [_days(food_days),roundi(LEAN_DAYS),roundi((1.0-lean)*LEAN_WEIGHT*100.0)]

## What the fresh share of what is eaten does to health.
static func fresh_sentence(share:float)->String:
	return "Fresh food keeps people well: health leans %s points for it (from %s when nothing eaten is fresh to %s when all of it is)." % [_signed(fresh_health(share)*100.0),_signed(fresh_health(0.0)*100.0),_signed(fresh_health(1.0)*100.0)]

## The carriers' hand on the fresh store.
static func carrying_sentence(cover:float,people:float)->String:
	var full:=_count(maxi(1,roundi(people*CARRY_SHARE)))
	if cover<=0.0:return "No one is carrying, so fresh food turns before it reaches every hearth. Carriers at 3 in 100 of the people (%s) would halve its spoiling." % full
	return "Carriers bring the day's harvest in before it turns: fresh food spoils %d in 100 less (half at most, at 3 in 100 of the people: %s)." % [roundi(CARRY_FRESH_CUT*clampf(cover,0.0,1.0)*100.0),full]

## The keepers' hand on the stored food.
static func keeping_sentence(cover:float,people:float)->String:
	var full:=_count(maxi(1,roundi(people*KEEP_SHARE)))
	if cover<=0.0:return "No one keeps the stores, so stored food rots as it will. Keepers at 2 in 100 of the people (%s) would cut the rot by %d in 100." % [full,roundi(KEEP_STORED_CUT*100.0)]
	return "Keepers turn, dry and guard the stored food: it rots %d in 100 less (%d at most, at 2 in 100 of the people: %s)." % [roundi(KEEP_STORED_CUT*clampf(cover,0.0,1.0)*100.0),roundi(KEEP_STORED_CUT*100.0),full]

## The carers' hand on newborns, mothers and the sick (Health page).
static func caring_sentence(cover:float,target:float,people:float)->String:
	var full:=_count(maxi(1,roundi(people*CARE_SHARE)))
	var settling:=""
	if target>cover+0.02:settling=" More hands are learning the work; it reaches %d in 100 over the coming months." % roundi(target*100.0)
	elif target<cover-0.02:settling=" Fewer hands are on it now; it falls toward %d in 100." % roundi(target*100.0)
	if cover<=0.005:return "No one tends the newborns, the sick and mothers beyond their own families. Carers at %d in 100 of the people (%s) would watch the small children, nurse the sick, keep the water clean and dress wounds.%s" % [roundi(CARE_SHARE*100.0),full,settling]
	return "Carers watch the small children, nurse the sick, keep the water clean and dress wounds where the people's own ways fall short: %d in 100 of full care (full at %d in 100 of the people: %s), and health leans %s points for it. The same people keep the stores and the office.%s" % [roundi(cover*100.0),roundi(CARE_SHARE*100.0),full,_signed(CARE_HEALTH*cover*100.0),settling]

static func _days(days:float)->String:
	if days>=3650.0:return "years"
	if days>=60.0:return "%d months" % roundi(days/30.0)
	if roundi(days)==1:return "a day"
	return "%d days" % roundi(days)

# --- Words ---------------------------------------------------------------------------------

static func _line(label:String,value:String,words:String,tone:String)->Dictionary:
	return {"label":label,"value":value,"words":words,"tone":tone}

static func _count(n:int)->String:
	return _words().count_word(n) if n<=12 else _whole(float(n))

static func _whole(value:float)->String:
	return _words().grouped(roundi(value))

## The people's counting words (hud/era_words.gd), loaded when first told: the
## rulers' scripts preload this one, so it preloads nothing that reaches them.
static func _words()->GDScript:
	return load("res://scripts/hud/era_words.gd")

static func _one(value:float)->String:
	return str(roundi(value)) if absf(value)>=10.0 or is_equal_approx(value,roundf(value)) else "%.1f" % value

static func _signed(value:float)->String:
	return ("+" if value>=0.0 else "−")+_one(absf(value))
