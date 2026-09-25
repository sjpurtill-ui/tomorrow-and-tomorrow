extends RefCounted
## Every seat uses the same seeded planet sampling and viability search. No
## distance calculation is relative to the human player's selected location.
##
## Seats come in regional groups. Early peoples did not live alone on a
## continent: each group's first seat is placed anywhere on the planet, and its
## other seats settle within a few days' walk of it on connected land. Every
## seat (the player's included) is placed by the same rule, so the regions are
## part of the seeded world, not arranged around the player.
const REGION_SEATS:=3
const NEIGHBOR_MIN_KM:=95.0
const NEIGHBOR_MAX_KM:=210.0
const NEIGHBOR_SEPARATION_KM:=80.0

static func candidate(seed_value:int,seat:int)->Vector2:
	var anchor_seat:=seat-posmod(seat,REGION_SEATS)
	if anchor_seat==seat:return _planet_candidate(seed_value,seat)
	var anchor:=_planet_candidate(seed_value,anchor_seat)
	var siblings:Array[Vector2]=[anchor]
	for earlier in range(anchor_seat+1,seat):siblings.append(candidate(seed_value,earlier))
	var neighbor:=_regional_candidate(seed_value,seat,siblings)
	return neighbor if is_finite(neighbor.x) else _planet_candidate(seed_value,seat)

static func _regional_candidate(seed_value:int,seat:int,siblings:Array[Vector2])->Vector2:
	var anchor:=siblings[0]
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value^((seat+1)*15485863)
	var cells:=_reachable_ring(anchor)
	# Seeded order over the reachable ring; the first viable, separated cell wins.
	for index in range(cells.size()-1,0,-1):
		var swap:=rng.randi_range(0,index)
		var held:Vector2=cells[index];cells[index]=cells[swap];cells[swap]=held
	for point:Vector2 in cells:
		var apart:=true
		for other in siblings:
			if other.distance_to(point)<NEIGHBOR_SEPARATION_KM:apart=false;break
		if apart and supports_founders(PlanetEnvironment.profile_at(point)):return point
	return Vector2.INF

const REGION_CELL_KM:=12.0
const REGION_WATER_CELLS:=2

static func _reachable_ring(anchor:Vector2)->Array[Vector2]:
	## Land a band could walk to from the anchor: a bounded grid flood fill that
	## may cross at most two cells (about 24 km) of water at a time, as over a
	## strait or a wide river. Returns land cells in the neighbour window.
	var limit:=ceili(NEIGHBOR_MAX_KM/REGION_CELL_KM)
	var best_run:Dictionary={Vector2i.ZERO:0}
	var queue:Array[Vector2i]=[Vector2i.ZERO]
	var cursor:=0
	var ring:Array[Vector2]=[]
	while cursor<queue.size():
		var cell:=queue[cursor];cursor+=1
		var run:=int(best_run[cell])
		for direction:Vector2i in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			var next:=cell+direction
			if absi(next.x)>limit or absi(next.y)>limit:continue
			var point:=anchor+Vector2(next)*REGION_CELL_KM
			if absf(point.x)>PlanetEnvironment.PLANET_WIDTH_KM*.49 or absf(point.y)>PlanetEnvironment.PLANET_DEPTH_KM*.49:continue
			var land:=PlanetEnvironment.is_land(point)
			var next_run:=0 if land else run+1
			if next_run>REGION_WATER_CELLS or int(best_run.get(next,999))<=next_run:continue
			var first_visit:=not best_run.has(next)
			best_run[next]=next_run
			queue.append(next)
			var distance:=point.distance_to(anchor)
			if first_visit and land and distance>=NEIGHBOR_MIN_KM and distance<=NEIGHBOR_MAX_KM:ring.append(point)
	return ring

static func _planet_candidate(seed_value:int,seat:int)->Vector2:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value^((seat+1)*32452843)
	var best:=Vector2.ZERO;var best_score:=-INF
	# Generated communities share a generalist founding kit. Select places where
	# that kit has a plausible subsistence base, not merely a patch of dry ground.
	# This does not restrict later player settlement or grant local resources.
	for attempt in 48:
		var desired:=Vector2(rng.randf_range(-18000,18000),rng.randf_range(-8000,8000))
		var point:=PlanetEnvironment.nearest_viable_land(desired,seed_value^((seat+1)*104729+attempt))
		var profile:=PlanetEnvironment.profile_at(point)
		var score:=float(profile.food_potential)+minf(.3,float(profile.growing_season)*.3)
		if score>best_score:best=point;best_score=score
		if supports_founders(profile):return point
	return best

static func supports_founders(profile:Dictionary)->bool:
	return bool(profile.get("land",false)) and float(profile.get("food_potential",0))>=.4 and float(profile.get("mean_temperature_c",-100))>=6.0 and float(profile.get("growing_season",0))>=.35

## The kinds of country early peoples made their first homes in. Each seat
## draws a seeded order of these from its own planet point, then settles in the
## first kind its real surroundings offer within a few days' walk (the same
## ground survey the map draws). Where none is offered it keeps the plain best
## site: open country. Coast and dry country are rarer on the ground than in
## this order, so they are weighted up to be found where they exist.
const SETTINGS:={"river":0.2,"forest_edge":0.14,"coast":0.24,"hills":0.2,"dry":0.22}
## How far (km) a people looks for its kind of country around its seed point.
const SETTING_REACH_KM:=80.0
## Rain below this (the renderer's 0..1 precipitation) reads as dry country:
## the ground starts to brown and the grass runs short.
const DRY_RAIN:=0.52
## Words for each kind of country (and for open country, "").
const SETTING_WORDS:={"river":"a river valley","forest_edge":"the edge of the forest","coast":"the sea coast","hills":"the hills","dry":"dry country","":"open country"}

## Seeded preference order of settings for the seat whose planet point is `origin`.
static func setting_order(origin:Vector2)->Array[String]:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%d|founding_setting" % [roundi(origin.x),roundi(origin.y)])
	var pool:=SETTINGS.duplicate()
	var order:Array[String]=[]
	while not pool.is_empty():
		var total:=0.0
		for key in pool:total+=float(pool[key])
		var roll:=rng.randf()*total
		var picked:=String(pool.keys()[0])
		for key in pool:
			roll-=float(pool[key])
			if roll<=0.0:picked=String(key);break
		order.append(picked);pool.erase(picked)
	return order

## Whether a surveyed point (local_terrain._survey_ground_at) is that kind of country.
static func setting_match(setting:String,sample:Dictionary)->bool:
	var biome:=String(sample.get("biome",""))
	var woodland:=float(sample.get("woodland",0.0))
	match setting:
		# The valley floor beside the water, or the flood country itself.
		"river":return biome in ["floodplain","wetland"] or (float(sample.get("river_distance_km",INF))<=0.25 and float(sample.get("relief",0.0))<0.0)
		# Open ground with the wood's edge close: trees for timber and game, room to plant.
		"forest_edge":return biome!="woodland" and woodland>=0.28 and woodland<0.42
		"coast":return bool(sample.get("coastal",false))
		"hills":return biome=="upland" or float(sample.get("relief",0.0))>=0.22 or float(sample.get("height",0.0))>=3.4
		# Thin rain: short grass and a river that matters more than any cloud.
		"dry":return biome=="steppe" or float(sample.get("precipitation",1.0))<DRY_RAIN
	return false

## The kind of country a founding site is, in its seat's order ("" = open country).
static func setting_of(origin:Vector2,site:Dictionary)->String:
	for setting in setting_order(origin):
		if setting_match(setting,site):return setting
	return ""

## The same for a site alone, in a fixed order (for text about a loaded world).
static func country_of(site:Dictionary)->String:
	for setting in ["coast","hills","dry","river","forest_edge"]:
		if setting_match(setting,site):return setting
	return ""

static func choose(origin:Vector2,ground:Callable)->Vector2:
	var best:=origin;var score:=INF
	var order:=setting_order(origin)
	# Best plain score per setting within reach, in the seat's preference order.
	var by_setting:Dictionary={}
	for radius:float in [0,2,5,10,20,40,80,160,320,640]:
		if radius>SETTING_REACH_KM and score<INF:break
		for spoke in (1 if radius==0 else 32):
			var point:=origin+Vector2.from_angle(TAU*float(spoke)/32.0)*radius
			var sample:Dictionary=ground.call(point)
			if float(sample.get("height",-1))<=.02 or float(sample.get("slope",1))>.48:continue
			if not bool(sample.get("founding_valid",true)):continue
			if sample.has("environment_profile") and not supports_founders(sample.environment_profile):continue
			if sample.has("surface_material_catchments") and not supports_founding_materials(sample.surface_material_catchments):continue
			var water:=float(sample.get("river_distance_km",INF))
			if water>6:continue
			var value:=radius*.02+water*3.0+float(sample.get("slope",0))*12.0-float(sample.get("fertility",0))
			if value<score:score=value;best=point
			if radius>SETTING_REACH_KM:continue
			for setting in order:
				if not setting_match(setting,sample):continue
				# Of the dry places, the driest that still has its water.
				var fitted:=value+(float(sample.get("precipitation",0.0))*6.0 if setting=="dry" else 0.0)
				if not by_setting.has(setting) or fitted<float((by_setting[setting] as Array)[0]):by_setting[setting]=[fitted,point]
	# The first kind of country in this seat's order that its land really offers.
	for setting in order:
		if by_setting.has(setting):return (by_setting[setting] as Array)[1]
	return best

static func supports_founding_materials(fields:Dictionary)->bool:
	# The inherited generalist kit depends on wood handles, stone tools and
	# bindings. Generated starts need actual working catchments, not macro-map
	# potential. Later deliberate settlement may depend on trade or substitutes.
	for item:String in ["Timber","Stone","Fiber Plants"]:
		if float(fields.get(item,{}).get("density",0))<(.03 if item=="Stone" else .08):return false
	return true
