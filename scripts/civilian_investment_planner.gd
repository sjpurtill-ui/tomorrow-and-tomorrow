extends RefCounted
## Shared demand planning; actual orders still pay for labor, materials and equipment.
static func recommendation()->Dictionary:
	var recommendation:=preload("res://scripts/civilian_care_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/power_investment_planner.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/scientific_instrument_planner.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/canning_investment_planner.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/machine_workshop_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/communications_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/building_material_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/water_conveyance_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/naval_dock_investment.gd").recommendation()
	if recommendation.is_empty():recommendation=preload("res://scripts/rail_freight_investment.gd").recommendation()
	if recommendation.is_empty():
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
	return recommendation
