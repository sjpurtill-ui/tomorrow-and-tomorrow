extends RefCounted
## Near-frontier option value: only inquiries whose material basis already
## exists and which one eligible foundation can make causally ready count.
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")
static func recommendation()->Dictionary:
	var discovery:=WorldSimulation.discovery
	var known:Array=WorldSimulation.state.known_discoveries
	var eligible:Dictionary={};var opens:Dictionary={}
	for entry:Dictionary in discovery.technology_catalog:
		if discovery._discovery_is_eligible(entry,int(WorldSimulation.state.elapsed_days)):eligible[String(entry.id)]=entry
	for child:Dictionary in discovery.technology_catalog:
		if child.id in known or eligible.has(String(child.id)) or not discovery._resource_requirements_met(child.get("resource_requirements",[])):continue
		for route:Dictionary in P.routes(child):
			if String(route.id).begins_with("experimental") and float(route.get("support",0))<.25:continue
			for parent:String in R.parents(route):
				if not eligible.has(parent):continue
				var potential:=known.duplicate();potential.append(parent)
				if not bool(R.evaluate(route,potential).ready):continue
				if not opens.has(parent):opens[parent]=[]
				if child.id not in opens[parent]:opens[parent].append(child.id)
	var best:Dictionary={};var score:=-INF
	for id:String in opens:
		# One specialist continuation alone is not a breadth justification.
		if opens[id].size()<2:continue
		var value:=float(opens[id].size())+clampf(float(WorldSimulation.state.discovery_progress.get(id,0)),0,1)*.5
		if value>score:
			score=value;best={"id":id,"domain":String(eligible[id].dynamic),"opens":opens[id].duplicate(),"reason":"Investigate a foundation shared by several supported questions"}
	return best
