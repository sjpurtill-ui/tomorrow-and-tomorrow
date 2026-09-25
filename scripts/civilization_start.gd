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

static func choose(origin:Vector2,ground:Callable)->Vector2:
	var best:=origin;var score:=INF
	for radius:float in [0,2,5,10,20,40,80,160,320,640]:
		if radius>160 and score<INF:break
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
	return best

static func supports_founding_materials(fields:Dictionary)->bool:
	# The inherited generalist kit depends on wood handles, stone tools and
	# bindings. Generated starts need actual working catchments, not macro-map
	# potential. Later deliberate settlement may depend on trade or substitutes.
	for item:String in ["Timber","Stone","Fiber Plants"]:
		if float(fields.get(item,{}).get("density",0))<(.03 if item=="Stone" else .08):return false
	return true
