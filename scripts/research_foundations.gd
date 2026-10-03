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
	var catalog:Array=discovery.technology_catalog
	var eligible:Dictionary={};var opens:Dictionary={}
	# Each question's opening year (research_open_year), read once per catalog.
	var open_years:=discovery.technology_open_years()
	# The people's own age (the calendar plus its learning lead).
	var year:=float(discovery.learning_year())
	for index in open_years.size():
		# A foundation to start now is one near its own age (work before it
		# costs proportionally more; never a wall): research_years_ahead.
		if maxf(0.0,open_years[index]-year)>=NEAR_AGE: continue
		var entry:Dictionary=catalog[index]
		if discovery._scan_eligible(entry,int(WorldSimulation.state.elapsed_days)):eligible[String(entry.id)]=entry
	# Only a question naming an eligible foundation, and missing at most that
	# one of its shared foundations, can be opened by one; the others' material
	# checks and routes are pure reads that add nothing. The rest are taken in
	# catalog order, as a full pass meets them.
	var children:=discovery.foundation_children()
	var candidates:Dictionary={}
	for parent:String in eligible:
		for index:int in children.get(parent,[]):candidates[index]=true
	var order:Array=candidates.keys()
	order.sort()
	for index:int in order:
		var child:Dictionary=catalog[index]
		if known_set.has(String(child.id)) or eligible.has(String(child.id)) or not _one_foundation_away(child,known_set,eligible) or not discovery._resource_requirements_met(child.get("resource_requirements",[])):continue
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

## False when no single eligible foundation could ready any route of `entry`:
## every route keeps the entry's shared requires_all and requires_any, so
## with one foundation `p` added to the known ones, at most one shared
## requires_all (then `p` itself) may be unknown, and every requires_any group
## needs a known or eligible member.
static func _one_foundation_away(entry:Dictionary,known:Dictionary,eligible:Dictionary)->bool:
	var missing:=""
	for id:String in entry.get("requires_all",[]):
		if known.has(id):continue
		if missing!="" and missing!=id:return false
		missing=id
	if missing!="" and not eligible.has(missing):return false
	for group:Array in entry.get("requires_any",[]):
		var reachable:=false
		for id:String in group:
			if known.has(id) or eligible.has(id):reachable=true;break
		if not reachable:return false
	return true
