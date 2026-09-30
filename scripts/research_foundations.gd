extends RefCounted
## Near-frontier option value: only inquiries whose material basis already
## exists and which one eligible foundation can make causally ready count.
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")
const NEAR_AGE:=preload("res://scripts/discovery_system.gd").NEAR_AGE_YEARS
static func recommendation()->Dictionary:
	var discovery:=WorldSimulation.discovery
	var known:Array=WorldSimulation.state.known_discoveries
	var known_set:=R.index_known(known)
	var eligible:Dictionary={};var opens:Dictionary={}
	# Questions come in order of opening year: once one stands NEAR_AGE ahead of
	# its age, every later one does too.
	for entry:Dictionary in discovery.technology_by_open_year():
		# A foundation to start now is one near its own age (work before it
		# costs proportionally more; never a wall).
		if discovery.research_years_ahead(entry)>=NEAR_AGE: break
		if discovery._scan_eligible(entry,int(WorldSimulation.state.elapsed_days)):eligible[String(entry.id)]=entry
	# Only a question naming an eligible foundation can be opened by one; the
	# others' material checks and routes are pure reads that add nothing. The
	# rest are taken in catalog order, as a full pass would meet them.
	var children:=discovery.foundation_children()
	var candidates:Dictionary={}
	for parent:String in eligible:
		for index:int in children.get(parent,[]):candidates[index]=true
	var order:Array=candidates.keys()
	order.sort()
	for index:int in order:
		var child:Dictionary=discovery.technology_catalog[index]
		if known_set.has(String(child.id)) or eligible.has(String(child.id)) or not discovery._resource_requirements_met(child.get("resource_requirements",[])):continue
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
