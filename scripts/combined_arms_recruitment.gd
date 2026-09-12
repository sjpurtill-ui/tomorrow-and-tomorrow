extends RefCounted
## Home-force composition advice; no troops, gear or tactical orders are granted.
const D=preload("res://scripts/combined_arms_doctrine.gd")
const Strategy=preload("res://scripts/civilization_strategy.gd")
static func recommendation(primary:String,plan:Dictionary,can_supply:Callable)->Dictionary:
	var host=WorldSimulation.military
	if primary.is_empty() or host.aggregate_recruits<=0 or bool(plan.get("hungry",false)) or String(plan.get("training",""))=="suspended":return {}
	var counts:Dictionary={}
	for force:Dictionary in host._exercise_forces():
		for formation:Dictionary in force.get("formations",[]):
			var unit:=String(formation.get("unit",""))
			counts[unit]=int(counts.get(unit,0))+maxi(0,int(formation.get("count",0)))
	# Count committed recruits as future support, not as current fighting power.
	for order:Dictionary in host.training_queue:
		var unit:=String(order.get("unit",""))
		counts[unit]=int(counts.get(unit,0))+maxi(0,int(order.get("count",0)))
	var best:Dictionary={};var score:=-INF
	var levels:=D.levels()
	for id:String in levels:
		if float(levels[id])<.25:continue
		var rule:Dictionary=D.RULES[id]
		if primary not in rule.targets:continue
		var targets:=0;var support:=0
		for unit:String in rule.targets:targets+=int(counts.get(unit,0))
		for unit:String in rule.support:support+=int(counts.get(unit,0))
		var desired:=ceili(targets*D.SUPPORT_PER_TARGET);var gap:=desired-support
		if gap<=0:continue
		for unit:String in rule.support:
			var definition:Dictionary=host.UnitCatalog.ARCHETYPES[unit]
			for weapon:String in definition.equipment:
				var gate:Dictionary=host._training_gate(unit,weapon)
				if gate.has("error") or bool(gate.get("prototype",false)) or not bool(can_supply.call(weapon)):continue
				var value:=float(gap)/maxf(1,desired)*float(rule.defense)+Strategy.unit_score(definition,plan)*.001
				if value>score:
					score=value;best={"unit":unit,"weapon":weapon,"count":mini(gap,host.aggregate_recruits),"doctrine":id}
	return best
