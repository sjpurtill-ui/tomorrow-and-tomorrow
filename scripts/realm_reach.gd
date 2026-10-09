extends RefCounted
## REALM REACH: the country a people holds about its one settlement (the
## user, 2026-10-05: a smaller world AND land that grows with its people, so
## that lands come to meet and fronts follow; "everybody has one settlement
## that expands", no new towns: docs/WAR_GEOGRAPHY.md).
##
## Every people, ours and every other, by the same rule: a disc of country
## about its settlement, reaching
##
##     REACH_PER_ROOT × √people × (1 + REACH_GOVERN × world reach)   km
##
## where world reach (0..1) is the people's own measure of how far its routes,
## travel and knowledge of the world extend (civilization_system world_reach;
## ours progression_reach_snapshot().combined). A village of 400 ranges about
## 72 km about its hearth; a people of 25,000 with good roads 600 to 950 km.
## With the peoples of a continent about 1,100 km apart (civilization_start),
## lands come to meet in the middle centuries, as they did on Earth's
## continents.
##
## One ledger: the borders (nation_borders.gd claims, so the washes, the
## meeting lines and the fronts), the war map's lands and finds in another
## people's land (resource_system.gd _foreign_holds) all read this, and
## nothing else, for the country a people holds. Pure and static; nothing
## here is saved.

const REACH_PER_ROOT:=3.6
const REACH_GOVERN:=2.0
## Never smaller than the settlement's own fields, never wider than half a continent.
const MIN_KM:=4.0
const MAX_KM:=3200.0


## The reach of a people of `people` with world reach `world_reach` (km).
static func reach_km(people:float,world_reach:float)->float:
	return clampf(REACH_PER_ROOT*sqrt(maxf(0.0,people))*(1.0+REACH_GOVERN*clampf(world_reach,0.0,1.0)),MIN_KM,MAX_KM)


## Our own realm: {center, reach}; {} before we have a home.
static func ours()->Dictionary:
	if Engine.get_main_loop()==null or WorldSimulation.state==null: return {}
	if not bool(WorldSimulation.state.get("settlement_site_committed")): return {}
	# The people in scope: its own world's origin (WorldSimulation.world is
	# that people's CivilizationSystem in a rival's scope).
	var world:Variant=WorldSimulation.world if WorldSimulation.world!=null else CivilizationSystem
	var center:Vector2=world.player_world_origin
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) and city.get("position") is Vector2 and String(city.get("occupied_by","")) in ["","human","player"]:
			center=city.position
	var world_reach:=float((world.progression_reach_snapshot() as Dictionary).get("combined",0.0)) if world.has_method("progression_reach_snapshot") else 0.0
	# A people set on spreading its land reaches further (ambition_effects.gd).
	var course:=1.0+preload("res://scripts/ambition_effects.gd").effect("realm_reach")
	return {"owner":"player","center":center,"reach":clampf(reach_km(float(WorldSimulation.state.population_total),world_reach)*course,MIN_KM,MAX_KM)}


## Another people's realm: {owner, center (its settlement, while it holds
## it), reach}; {} when it holds none.
static func of(civ:Dictionary,sites:Dictionary={})->Dictionary:
	var civ_id:=String(civ.get("id",""))
	if civ_id=="" or Engine.get_main_loop()==null: return {}
	var capital:Dictionary={}
	for region:Dictionary in civ.get("strategic_regions",[]):
		if String(region.get("role",""))=="capital": capital=region
	if capital.is_empty() or not bool(capital.get("settlement_founded",true)): return {}
	var holder:=String(capital.get("controller",civ_id))
	if holder!="" and holder!=civ_id: return {}
	# Where the settlement stands: its place in the world, else as our book has it.
	var center:=Vector2.INF
	var place:Variant=capital.get("position",null)
	if place is Vector2: center=place
	elif sites.has(String(capital.get("id",""))):
		var at:Variant=sites[String(capital.get("id",""))]
		if at is Dictionary and not (at as Dictionary).is_empty(): center=Vector2(float(at.get("x",0.0)),float(at.get("z",0.0)))
	if not center.is_finite() and CivilizationSystem.has_method("_civilization_world_position"): center=CivilizationSystem._civilization_world_position(civ)
	if not center.is_finite(): return {}
	return {"owner":civ_id,"center":center,"reach":reach_km(float(civ.get("population",0.0)),float(civ.get("world_reach",0.0)))}


## Every other people's realm (not ours).
static func others()->Array:
	var out:Array=[]
	if Engine.get_main_loop()==null: return out
	var sites:=site_map()
	for civ:Dictionary in CivilizationSystem.civilizations:
		var realm:=of(civ,sites)
		if not realm.is_empty(): out.append(realm)
	return out


## Each settlement's place as our book has it: {city_id: {x, z}}.
static func site_map()->Dictionary:
	var out:={}
	var intel:Variant=CivilizationSystem.get("city_intelligence")
	if intel==null: return out
	var records:Variant=intel.get("records")
	var book:Dictionary=(records as Dictionary).get("player",{}) if records is Dictionary else {}
	for id in book:
		if book[id] is Dictionary: out[String(id)]=(book[id] as Dictionary).get("position",{})
	return out


## THE BORDER (fort_border.gd): what a people holds and watches, spanned by
## its forts, as distinct from the country its people live and work in
## (ours()/of(), which homesteads and places follow). {owner, center, reach,
## table (km at each bearing), points}; {} before a home.
static func border_ours()->Dictionary:
	if Engine.get_main_loop()==null or WorldSimulation.state==null: return {}
	if not bool(WorldSimulation.state.get("settlement_site_committed")): return {}
	return _border(WorldSimulation.state,"player")

## Another people's border, from its own forts; {} when it has no home.
static func border_of(civ:Dictionary)->Dictionary:
	var civ_id:=String(civ.get("id",""))
	if civ_id=="" or Engine.get_main_loop()==null: return {}
	var state:Node=preload("res://scripts/society_exchange.gd").owner_state(civ_id)
	if state==null or not bool(state.get("settlement_site_committed")): return {}
	if of(civ).is_empty(): return {}
	return _border(state,civ_id)

static func _border(state:Node,owner:String)->Dictionary:
	var shape:Dictionary=preload("res://scripts/fort_border.gd").outline(state)
	return {"owner":owner,"center":shape.center,"reach":maxf(float(shape.reach),MIN_KM),"table":shape.table,"points":shape.points}

## Every other people's border (not ours).
static func border_others()->Array:
	var out:Array=[]
	if Engine.get_main_loop()==null: return out
	for civ:Dictionary in CivilizationSystem.civilizations:
		var border:=border_of(civ)
		if not border.is_empty(): out.append(border)
	return out


## Whether `point` lies in another people's country, as the borders cut it:
## their realm scores higher there than ours does (score 1 - d/reach, as
## nation_border_partition scores a claim).
static func held_by_other(point:Vector2,others_list:Array=[],own:Dictionary={})->bool:
	var list:=others_list if not others_list.is_empty() else others()
	if own.is_empty(): own=ours()
	var mine:=_score(own,point) if not own.is_empty() else -INF
	for realm:Dictionary in list:
		var theirs:=_score(realm,point)
		if theirs>0.0 and theirs>mine: return true
	return false


static func _score(realm:Dictionary,point:Vector2)->float:
	var reach:=float(realm.reach)
	# A border with a shape (border_of): its reach in that bearing.
	if realm.get("table") is PackedFloat32Array and not (realm.table as PackedFloat32Array).is_empty():
		var table:PackedFloat32Array=realm.table
		var offset:=point-(realm.center as Vector2)
		reach=float(table[posmod(roundi(fposmod(offset.angle(),TAU)/TAU*float(table.size())),table.size())])
	return 1.0-(realm.center as Vector2).distance_to(point)/maxf(0.001,reach)
