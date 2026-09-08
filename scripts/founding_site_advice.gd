extends RefCounted
## Read-only advice from the map's existing hydrology and returned knowledge.
## This is deliberately separate from dry-ground checks used by army recovery.

const NEAR_WATER_KM:=1.0
const COLLECTION_LIMIT_KM:=6.0
const SEARCH_RADIUS_KM:=12.0
const GOOD:=Color("8ed9ae")
const CAUTION:=Color("e9bf70")
const BLOCKED:=Color("e58e7d")
var terrain:Node3D
var cache:Dictionary={}
var revision:=""

func _init(world:Node3D)->void:
	terrain=world

func assess(position:Vector3,fresh:bool=false)->Dictionary:
	var next_revision:="%d:%d" % [GameState.world_seed,CivilizationSystem.fog_revision]
	if next_revision!=revision:
		cache.clear();revision=next_revision
	# Only display reads share a 25 m cell. Commit always rechecks the exact point.
	var key:=Vector2(position.x,position.z).snapped(Vector2.ONE*.025)
	if not fresh and cache.has(key):return cache[key].duplicate(true)
	var result:=_assess(position)
	var neighbors:Dictionary=CivilizationSystem.settlement_siting.preview(Vector2(position.x,position.z))
	result["neighbors"]=neighbors
	result["water_recommended"]=bool(result.recommended)
	if float(neighbors.penalty)>0:
		result.recommended=false
		if bool(result.valid):result.color=BLOCKED if float(neighbors.penalty)>=.35 else CAUTION
	if cache.size()>=256:cache.clear()
	cache[key]=result.duplicate(true)
	return result

func _assess(position:Vector3)->Dictionary:
	var result:Dictionary={"valid":false,"recommended":false,"status":"blocked","color":BLOCKED,"position":position,"household_ratio":0.0,"distance_km":INF}
	if not terrain._world_position_is_revealed(position):
		result.merge({"title":"WATER SUPPLY UNKNOWN","reason":"Scout this ground first. No returned report confirms a water source here."},true)
		return result
	var ground:Dictionary=terrain._settlement_surface_assessment(position)
	if not bool(ground.get("valid",false)):
		result.merge({"title":"CHOOSE DRY GROUND","reason":String(ground.get("reason","This ground cannot support a settlement."))},true)
		return result
	var nearest:Dictionary={}
	var distance:=INF
	for source:Dictionary in terrain._founding_water_sources(position):
		var point:Vector3=source.position
		if not terrain._world_position_is_revealed(point):continue
		var candidate_distance:=float(source.distance_km)
		if candidate_distance<distance:
			nearest=source;distance=candidate_distance
	if nearest.is_empty() or distance>COLLECTION_LIMIT_KM:
		result.merge({"title":"NO USABLE WATER CONFIRMED","reason":"No known fresh water within the 6 km collection limit. Choose another site or scout more ground before founding."},true)
		return result
	var ratio:=ResourceSystem._household_surface_water_access_ratio(distance)
	var nearby:=distance<=NEAR_WATER_KM
	var bearing:=compass(position,nearest.position)
	var source_text:="%s · %.1f km %s" % [String(nearest.kind),distance,bearing]
	var detail:="Dry ground near known fresh water. Households can cover basic drinking needs."
	if not nearby:
		detail="Long daily carry. Households cover about %d%% of basic drinking needs; plan water-hauling labor." % roundi(minf(1.0,ratio)*100.0)
		if ratio>=1.0:detail="Water is usable, but a longer daily carry. Moving closer leaves more time for other work."
	result.merge({"valid":true,"recommended":nearby,"status":"good" if nearby else "caution","color":GOOD if nearby else CAUTION,"title":"NEARBY FRESH WATER" if nearby else "LONG WATER CARRY","reason":detail,"source_text":source_text,"source_position":nearest.position,"source_kind":nearest.kind,"distance_km":distance,"household_ratio":ratio},true)
	return result

func suggestions(origin:Vector3,later_city:bool=false)->Array[Dictionary]:
	var found:Array[Dictionary]=[]
	if not terrain._world_position_is_revealed(origin):return found
	# Bounded and run on request, never a planet-wide or per-frame search.
	for radius:float in [.5,1.0,2.0,3.0,4.0,6.0,9.0,SEARCH_RADIUS_KM]:
		for spoke:int in 16:
			var angle:=TAU*float(spoke)/16.0
			var point:=origin+Vector3(cos(angle)*radius,0,sin(angle)*radius)
			if not terrain._world_position_is_revealed(point):continue
			point.y=terrain._height_at(point.x,point.z)+.002
			var advice:=assess(point,true)
			if not bool(advice.recommended):continue
			if later_city and not bool(terrain._settlement_convoy_site_assessment(point).get("valid",false)):continue
			var known_route:=true
			var steps:=ceili(radius/.5)
			for step:int in range(1,steps):
				if not terrain._world_position_is_revealed(origin.lerp(point,float(step)/float(steps))):known_route=false;break
			if not known_route:continue
			var route:Dictionary=terrain._analyze_convoy_route(origin,point)
			if not bool(route.get("valid",false)):continue
			var separate:=true
			for previous:Dictionary in found:
				if Vector2(point.x,point.z).distance_to(Vector2(previous.position.x,previous.position.z))<.8:separate=false;break
			if not separate:continue
			advice["travel_distance_km"]=radius
			found.append(advice)
			if found.size()==3:return found
	return found

static func compass(origin:Vector3,destination:Vector3)->String:
	var offset:=Vector2(destination.x-origin.x,destination.z-origin.z)
	return ["E","SE","S","SW","W","NW","N","NE"][posmod(roundi(offset.angle()/(PI/4.0)),8)]
