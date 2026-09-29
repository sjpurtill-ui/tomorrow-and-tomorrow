extends RefCounted
## WHAT THE TOWN'S HALL, SHRINES AND YARD DO, and the one place that says so.
##
## These civic works act on the people through the same targets the rest of
## the simulation uses, and the engine reads effect() here:
##   consequence_engine.gd  cohesion and legitimacy targets, and the reach of
##                          the stewards (admin coverage)
##   divine_regard.gd       the people's love and dread of the god
##   food_system.gd         the offerings, a share of the food the people eat
##   resource_system.gd     the yard's organised digging and cutting
## Each is scaled by what keeps it in use (factor()): the town's repair (its
## condition), and for the Shrine House the keepers who tend it. The
## Buildings page reads the same FULL table, factor() and effect(), so what it
## shows is what the engine applies. Every people builds and gains these
## under the same rules; only the god's people have a god to love or dread.

const HALL:="Framed Hall"
const HEARTH_SHRINE:="Hearth Shrine"
const SHRINE_HOUSE:="Shrine House"
const YARD:="Gathering Yard"

## Each work's effects at full repair (and, for the Shrine House, fully kept).
##   cohesion, legitimacy  added to their targets (0..1)
##   admin_reach           stewards count this much more toward the council's reach
##   devotion              added to the people's love of the god (0..1)
##   dread_eased           taken off the people's dread of the god (0..1)
##   offerings             share of the people's daily food given at the shrine
##   extraction            added to the output of every deposit worked
const FULL:={
	"Framed Hall":{"legitimacy":0.035,"cohesion":0.02,"admin_reach":0.15},
	"Hearth Shrine":{"cohesion":0.015,"devotion":0.04,"offerings":0.003},
	"Shrine House":{"cohesion":0.03,"legitimacy":0.03,"devotion":0.08,"dread_eased":0.05,"offerings":0.01},
	"Gathering Yard":{"extraction":0.12},
}
## Keepers a Shrine House needs to be fully tended: lore keepers (the
## Knowledge work), this share of the people.
const SHRINE_KEEPERS_SHARE:=0.01


## How fully a work acts today (0..1): 0 until it stands; then the town's
## repair, and for the Shrine House also whether its keepers are at work.
static func factor(title:String)->float:
	if title not in WorldSimulation.state.settlement_completed: return 0.0
	var condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0.0,1.0)
	if title==SHRINE_HOUSE: return clampf(minf(condition,keepers_ratio()),0.0,1.0)
	return condition


## The Shrine House's keepers against those it needs (1 = fully tended).
static func keepers_ratio()->float:
	var need:=maxf(1.0,WorldSimulation.state.population_exact*SHRINE_KEEPERS_SHARE)
	return clampf(WorldSimulation.state.effective_workers("Knowledge")/need,0.0,1.0)


## The keepers the Shrine House needs, in people.
static func keepers_needed()->int:
	return maxi(1,ceili(WorldSimulation.state.population_exact*SHRINE_KEEPERS_SHARE))


## The sum of one effect over every standing work, as the engine applies it.
static func effect(key:String)->float:
	var total:=0.0
	for title in FULL:
		var amount:=float((FULL[title] as Dictionary).get(key,0.0))
		if amount!=0.0: total+=amount*factor(String(title))
	return total


## One work's effects as they act today: {factor, full:{key:amount},
## now:{key:amount}}. Empty maps when the work has none of its own.
static func of(title:String)->Dictionary:
	var full:Dictionary=(FULL.get(title,{}) as Dictionary).duplicate()
	var f:=factor(title)
	var now:={}
	for key in full: now[key]=float(full[key])*f
	return {"factor":f,"full":full,"now":now}
