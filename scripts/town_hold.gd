extends RefCounted
## THE ONE RULE FOR HOLDING A TOWN. Every place that asks whether a force
## holds a town, how many men a garrison needs, or whether victors can keep a
## town they stormed reads it here: the garrison as it is set, its drafts,
## the order to reinforce it, the town's control, the capture of a town and
## of a people's home.
##
## A force's holding strength is its men, times how well they are fed (the
## one supply number: provision_ratio, the share of a ration eaten today;
## supply_level for a force that keeps no ration record), times half again of
## their readiness:
##     strength = men x fed x (0.5 + 0.5 x readiness)
## It holds the town while that strength reaches what the town asks
## (CivilizationSystem.occupation_requirement: more for a large or resentful
## town, more again for a capital). need() is the men that takes; for a force
## so hungry that each man counts for less than FED_FLOOR, the need is
## reckoned at FED_FLOOR (more men cannot make up for no food).
## Static; preload.

const FED_FLOOR:=0.05


## The one supply number of a force (supply_state.gd fed): today's ration
## share when it keeps one.
static func fed(force:Dictionary)->float:
	return preload("res://scripts/supply_state.gd").fed(force)


## How much one man counts for in holding a town: fed x (0.5 + 0.5 x readiness).
static func worth(fed_share:float,readiness:float)->float:
	return clampf(fed_share,0.0,1.0)*(0.5+0.5*clampf(readiness,0.0,1.0))


static func strength(men:int,fed_share:float,readiness:float)->float:
	return float(maxi(0,men))*worth(fed_share,readiness)


## The men a town asking `required` needs, at this fed share and readiness
## (enough that holds() is true: the strength reaches the whole requirement).
static func need(required:float,fed_share:float,readiness:float)->int:
	if required<=0.0: return 0
	return ceili(ceilf(required)/maxf(FED_FLOOR,worth(fed_share,readiness)))


## A force (men in troops, or remaining_troops after a battle) against a
## town's requirement.
static func force_strength(force:Dictionary)->float:
	return strength(int(force.get("remaining_troops",force.get("troops",0))),fed(force),float(force.get("readiness",1.0)))


static func force_need(force:Dictionary,required:float)->int:
	return need(required,fed(force),float(force.get("readiness",1.0)))


static func holds(force:Dictionary,required:float)->bool:
	return force_strength(force)>=ceilf(maxf(0.0,required))


## What a town we hold asks of its garrison today (the world's own
## occupation_requirement for its people and their temper); `fallback` when
## the town is not known.
static func town_required(civ_id:String,region_id:String,fallback:float=0.0)->float:
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world==null or civ_id=="" or region_id=="" or not world.has_method("occupation_requirement"): return fallback
	var index:int=world._civilization_index(civ_id)
	if index<0: return fallback
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	if region.is_empty(): return fallback
	return float(world.occupation_requirement(world.civilizations[index],region))
