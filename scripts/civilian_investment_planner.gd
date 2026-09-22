extends RefCounted
## Chooses the next civilian investment: the first planner with a recommendation wins.
const CHAIN:=["res://scripts/civilian_care_investment.gd","res://scripts/power_investment_planner.gd","res://scripts/scientific_instrument_planner.gd","res://scripts/canning_investment_planner.gd","res://scripts/machine_workshop_investment.gd","res://scripts/communications_investment.gd","res://scripts/building_material_investment.gd","res://scripts/water_conveyance_investment.gd","res://scripts/naval_dock_investment.gd","res://scripts/rail_freight_investment.gd"]

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
	parts.append(["plan_production",func()->void:
		if not shared.recommendation.is_empty():return
		var recommendation:Dictionary={}
		var candidate:=preload("res://scripts/civilian_production_planner.gd").recommendation(true)
		if not candidate.is_empty():
			var recipe:=preload("res://scripts/civilian_industry.gd").product(String(candidate.item))
			if float(recipe.get("power",0))<=0:recommendation=candidate
			else:
				var added_demand:=float(recipe.get("daily_power",0))
				for job:Dictionary in WorldSimulation.military.equipment_queue:
					if String(job.get("item",""))==String(candidate.item):added_demand=0.0;break
				if preload("res://scripts/power_investment_planner.gd").can_supply(added_demand):recommendation=candidate
				else:recommendation=preload("res://scripts/power_investment_planner.gd").recommendation(added_demand)
		if recommendation.is_empty():recommendation=preload("res://scripts/civilian_production_planner.gd").recommendation()
		shared.recommendation=recommendation
	])
	return parts
