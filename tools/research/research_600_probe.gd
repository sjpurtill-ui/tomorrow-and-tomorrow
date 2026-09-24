extends RefCounted
## Best-case "earliest possible year" probe for the 600-year research layer.
##
## Starting from nothing, steps the calendar and, at each step, instantly learns
## every live discovery DiscoverySystem would open for a society that satisfies
## every design condition, has every activity signal and unlimited research.
## Real research takes years, so the result is a lower bound: no discovery can
## be learned earlier than the year recorded here. Used by
## tests/test_research_600.gd and tools/research/run_research_600_probe.gd.

const Pathways=preload("res://scripts/knowledge_pathways.gd")

## A society snapshot for which every design condition holds.
static func permissive_society()->Dictionary:
	return {"year":0.0,"population":1000000.0,"settlements":100,"resources":_all_resources(),
		"environment":{"river":true,"coast":true,"woodland":true,"dry":true},"institutions":1.0,"contact":true}


## {id: first year eligible} for every live entry opened within `horizon` years.
static func earliest_years(discovery:Node,horizon:float,step:float)->Dictionary:
	var society:=permissive_society()
	var context:Dictionary={}
	for entry:Dictionary in discovery.technology_catalog:
		for signal_name:Variant in entry.get("signals",[]): context[String(signal_name)]=2.0
		for route:Variant in entry.get("learning_routes",[]):
			for signal_name:Variant in (route as Dictionary).get("signals",[]): context[String(signal_name)]=2.0
	var known:Dictionary={}
	var first:Dictionary={}
	var pending:Array=discovery.technology_catalog.duplicate()
	var year:=0.0
	while year<=horizon+0.000001:
		society["year"]=year
		var changed:=true
		while changed:
			changed=false
			var remaining:Array=[]
			for entry:Dictionary in pending:
				var id:=String(entry.get("id",""))
				if discovery.research_600_open(entry,society) and Pathways.ready_for(entry,known,context):
					known[id]=true
					first[id]=year
					changed=true
				else:
					remaining.append(entry)
			pending=remaining
		year+=step
	return first


static func _all_resources()->Dictionary:
	var result:Dictionary={}
	for id:String in preload("res://scripts/research_600_catalog.gd").ids():
		var conditions:Dictionary=preload("res://scripts/research_600_catalog.gd").item(id).get("conditions",{})
		for resource:Variant in conditions.get("resources_known",[]): result[String(resource)]=true
	return result
