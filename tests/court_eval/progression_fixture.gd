extends RefCounted
## A dated capability reference for presentation reviews, NOT a simulated save.
## Each snapshot includes all live, dated practices whose foundations can be
## reached by that year. It does not model labour, resources or research choice,
## and does not grant anything to GameState. Campaigns can advance or lag it.

const Research:=preload("res://scripts/research_600_catalog.gd")
const Eras:=preload("res://scripts/technology_eras.gd")
const Founding:=preload("res://scripts/founding_knowledge.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Chapters:=preload("res://scripts/hud/court_chapters.gd")

static func year_of(entry:Dictionary)->float:
	if entry.has("design_year"):return float(entry.design_year)
	var id:=String(entry.get("id",""))
	if Eras.HISTORICAL_YEAR.has(id):return Eras.game_year_for(float(Eras.HISTORICAL_YEAR[id]))
	return INF

static func _met(spec:Dictionary,held:Dictionary)->bool:
	for id in spec.get("requires_all",spec.get("requires",[])):
		if not held.has(String(id)):return false
	for group:Array in spec.get("requires_any",[]):
		if not group.any(func(id:Variant)->bool:return held.has(String(id))):return false
	return true

static func foundations_met(entry:Dictionary,held:Dictionary)->bool:
	if not _met(entry,held):return false
	var routes:Array=entry.get("learning_routes",[])
	return routes.is_empty() or routes.any(func(route:Dictionary)->bool:return _met(route,held))

static func known_at(year:float,excluded:Array=[])->Array[String]:
	DiscoverySystem.initialize()
	var held:Dictionary={}
	for id:String in Founding.PRACTICES:
		if not id in excluded:held[id]=true
	var pending:Array[Dictionary]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		var id:=String(entry.id)
		if not held.has(id) and not id in excluded and year_of(entry)<=year:pending.append(entry)
	pending.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.id)<String(b.id))
	var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in pending:
			if held.has(String(entry.id)) or not foundations_met(entry,held):continue
			held[String(entry.id)]=true;changed=true
	var known:Array[String]=[]
	for id:String in held:known.append(id)
	known.sort()
	return known

static func snapshot(year:float,known:Array)->Dictionary:
	var stage:=Stages.derive(known)
	return {"year":year,"known_count":known.size(),"stage":stage,
		"presentation":Presentation.from_knowledge(known,stage),
		"chapter":Chapters.derive(year*365.0,known,stage)}
