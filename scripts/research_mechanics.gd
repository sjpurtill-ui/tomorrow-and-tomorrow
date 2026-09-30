extends RefCounted
## RESEARCH MECHANICS: how eight research effects act on the physical world,
## one small bounded formula each, read by every people through the same code.
##
## Each effect total comes from SocietyModel (WorldSimulation.discovery.effect,
## scoped to the people being simulated, player or not). This script is the one
## place that reads these eight totals, clamps them and turns them into factors;
## the systems that do the work call it, and the research explainer
## (effect_explainer.gd) shows the same numbers. The pure "_of" functions take
## explicit amounts so tests and the explainer can compute any case.

# --- Water access --------------------------------------------------------------
## Wells, cisterns, channels and pipes bring the water nearer. The walk to the
## nearest source counts this share shorter per 1.0 of water access
## (ResourceSystem._process_water_flow): households fetch their own water from
## farther away, and carriers bring in more each day.
const WATER_WALK_CUT:=0.75
const WATER_ACCESS_LIMITS:=Vector2(-0.35,0.80)

## The share of the walk to water that still counts, for a water access total.
static func water_walk_factor_of(access:float)->float:
	return 1.0-WATER_WALK_CUT*clampf(access,WATER_ACCESS_LIMITS.x,WATER_ACCESS_LIMITS.y)

static func water_walk_factor()->float:
	return water_walk_factor_of(WorldSimulation.discovery.effect("water_access"))

# --- Fuel -------------------------------------------------------------------------
## One factor on every fire the people keep: the kept hearth (fire_practice.gd),
## smoking food (food_system.gd _preserve) and the fuel of installed kilns and
## engines (technology_operations.gd). Fuel economy (charcoal, bellows, closed
## ovens and kilns, chimneys, stoves, better engines) saves this share of the
## usual fuel per 1.0; the fuel the people's ways need (firing pots and bricks,
## smoking, boiling water, baths, glass) adds this share per 1.0.
const FUEL_ECONOMY_SAVING:=0.6
const FUEL_DEMAND_COST:=1.0
const FUEL_ECONOMY_LIMITS:=Vector2(-0.40,0.85)
const FUEL_DEMAND_LIMITS:=Vector2(-0.35,0.70)
## Never less than this share of the usual fuel, nor more than the upper value.
const FUEL_FACTOR_LIMITS:=Vector2(0.30,2.20)
## Stores that installed plants burn as fuel.
const FUEL_ITEMS:=["Timber","Coal","Peat","Charcoal"]

## Fuel burned per task, as a share of the usual amount.
static func fuel_factor_of(economy:float,demand:float)->float:
	var saving:=1.0-FUEL_ECONOMY_SAVING*clampf(economy,FUEL_ECONOMY_LIMITS.x,FUEL_ECONOMY_LIMITS.y)
	var need:=1.0+FUEL_DEMAND_COST*clampf(demand,FUEL_DEMAND_LIMITS.x,FUEL_DEMAND_LIMITS.y)
	return clampf(saving*need,FUEL_FACTOR_LIMITS.x,FUEL_FACTOR_LIMITS.y)

static func fuel_factor()->float:
	return fuel_factor_of(WorldSimulation.discovery.effect("fuel_efficiency"),WorldSimulation.discovery.effect("fuel_demand"))

# --- Repair skill ------------------------------------------------------------------
## Resharpening and re-hafting, sound joints and footings, repointing and
## flashing: things last longer and mending goes further.
## Household goods in use (tools, pots, baskets, cloth) wear out this share
## slower per 1.0 (civilian_goods.gd daily_wear); the builders' monthly mending
## of the town goes this share further per 1.0 (settlement_model.gd
## _advance_city_form, and the same factor in upkeep_warnings.gd facts).
const REPAIR_WEAR_CUT:=0.5
const REPAIR_MENDING_GAIN:=1.0
const REPAIR_LIMITS:=Vector2(-0.30,0.75)

static func repair_skill_of(repair:float)->float:
	return clampf(repair,REPAIR_LIMITS.x,REPAIR_LIMITS.y)

## The share of the usual daily wear of household goods.
static func goods_wear_factor_of(repair:float)->float:
	return 1.0-REPAIR_WEAR_CUT*repair_skill_of(repair)

## How far the builders' mending goes, against the usual.
static func mending_factor_of(repair:float)->float:
	return 1.0+REPAIR_MENDING_GAIN*repair_skill_of(repair)

static func goods_wear_factor()->float:
	return goods_wear_factor_of(WorldSimulation.discovery.effect("repair_capacity"))

static func mending_factor()->float:
	return mending_factor_of(WorldSimulation.discovery.effect("repair_capacity"))

# --- Supply endurance ----------------------------------------------------------------
## Pack animals and saddles, waystations and food caches, relay carrying and
## preserved travel food. Per 1.0: the carriers eat this share less of each
## load for each day of hauling (supply_state.gd haul_share), so food reaches
## bands farther from home; and a band short of food counts its hungry days
## this share slower (field_rations.gd mark_day), so it holds out longer before
## hunger weakens it.
const ENDURANCE_HAUL_CUT:=0.5
const ENDURANCE_HUNGER_SLOW:=0.5
const ENDURANCE_LIMITS:=Vector2(-0.35,0.70)

static func endurance_of(endurance:float)->float:
	return clampf(endurance,ENDURANCE_LIMITS.x,ENDURANCE_LIMITS.y)

## The share of the usual daily loss of a hauled load, for an endurance total.
static func haul_loss_factor_of(endurance:float)->float:
	return 1.0-ENDURANCE_HAUL_CUT*endurance_of(endurance)

## How fast a band short of food counts hungry days, against the usual.
static func hunger_pace_of(endurance:float)->float:
	return 1.0-ENDURANCE_HUNGER_SLOW*endurance_of(endurance)

## The people's supply endurance today (engine and screens read this one).
static func supply_endurance()->float:
	return endurance_of(WorldSimulation.discovery.effect("logistics_endurance"))

static func hunger_pace()->float:
	return hunger_pace_of(supply_endurance())

# --- Seafaring ------------------------------------------------------------------------
## Sealed and caulked hulls, masts, sails and rigging, pilots and sailing
## calendars: boats and sailors reach farther out. One factor, this share more
## per 1.0, on the sea coast's part of the fishing grounds and on how far each
## fisher reaches at sea (food_system.gd), and on the open water a scouting
## party's craft can cross (civilization_system.gd _scout_water_crossing_allowance_km).
const SEA_REACH_GAIN:=1.0
const NAVAL_LIMITS:=Vector2(-0.30,0.90)

static func sea_reach_of(naval:float)->float:
	return 1.0+SEA_REACH_GAIN*clampf(naval,NAVAL_LIMITS.x,NAVAL_LIMITS.y)

static func sea_reach()->float:
	return sea_reach_of(WorldSimulation.discovery.effect("naval_capacity"))

## Rations a day the fishing grounds hold, before the settlement's reach
## (FoodSystem.wild_food_capacity): shore and river water, and the sea coast
## worked as far out as the people's boats go.
static func fishing_ground_of(water:float,shoreline:float,reach:float)->float:
	return 15.0+water*80.0+shoreline*40.0*reach

## How well fishers reach fish (FoodSystem._produce): the better of fresh water
## and the sea, the sea as far out as the people's boats go; at most 1.
static func fishing_access_of(freshwater:float,marine:float,reach:float)->float:
	return maxf(freshwater,minf(1.0,marine*0.90*reach))

# --- Mining ------------------------------------------------------------------------
## Drainage, hoists, pumps and blasting let mines work deeper and faster. Mine
## output is added to the same yield multiplier as extraction yield and ore
## yield (ResourceSystem._process_material_flow), for mined deposits only.
const MINING_OUTPUT_LIMITS:=Vector2(-0.35,0.80)

## Deposits dug from pits and shafts: every ore, and whatever the resource
## catalog says needs mine works (coal, sulfur, graphite, phosphate, oil).
## Stone, clay, sand, salt pans, peat, timber and plants are cut or gathered.
static func is_mined(definition:Dictionary,profile:Dictionary)->bool:
	return String(profile.get("family",""))=="metal" or "mine" in (definition.get("access",[]) as Array)

static func mining_bonus_of(output:float)->float:
	return clampf(output,MINING_OUTPUT_LIMITS.x,MINING_OUTPUT_LIMITS.y)

static func mining_bonus()->float:
	return mining_bonus_of(WorldSimulation.discovery.effect("mining_output"))

# --- Chemical control ------------------------------------------------------------
## Knowing what fumes, acids and wastes do and how to hold them back. Cuts this
## share of the harm smoke, slag and fouled water from the people's works do to
## their health and to the land (ConsequenceEngine), per 1.0; only harm is cut.
const CHEMICAL_HARM_CUT:=1.5
const CHEMICAL_HARM_CUT_LIMIT:=0.60

static func chemical_harm_cut_of(control:float)->float:
	return clampf(control*CHEMICAL_HARM_CUT,0.0,CHEMICAL_HARM_CUT_LIMIT)

static func chemical_harm_cut()->float:
	return chemical_harm_cut_of(WorldSimulation.discovery.effect("chemical_control"))
