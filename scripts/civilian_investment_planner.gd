extends RefCounted
## Chooses the next civilian investment: the first planner with a recommendation wins.
## Planners install plants and infrastructure. There is no production fallback:
## civilian manufactures are Civilian Goods made by Crafting households.
const CHAIN:=["res://scripts/kiln_investment.gd","res://scripts/civilian_care_investment.gd","res://scripts/power_investment_planner.gd","res://scripts/scientific_instrument_planner.gd","res://scripts/canning_investment_planner.gd","res://scripts/machine_workshop_investment.gd","res://scripts/communications_investment.gd","res://scripts/water_conveyance_investment.gd","res://scripts/naval_dock_investment.gd","res://scripts/rail_freight_investment.gd"]

static func recommendation()->Dictionary:
	var shared:Dictionary={}
	for part:Array in recommendation_steps(shared):(part[1] as Callable).call()
	return shared.recommendation

## The same chain as ordered [label, callable] parts writing shared.recommendation.
## Each part does nothing once an earlier part has found a recommendation.
static func recommendation_steps(shared:Dictionary)->Array:
	shared.recommendation={}
	var parts:Array=[]
	for path:String in CHAIN:
		parts.append(["plan_"+path.get_file().get_basename(),func()->void:
			if shared.recommendation.is_empty():shared.recommendation=load(path).recommendation()
		])
	return parts
