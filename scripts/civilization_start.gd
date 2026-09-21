extends RefCounted
## Every seat uses the same seeded planet sampling and viability search. No
## distance calculation is relative to the human player's selected location.
static func candidate(seed_value:int,seat:int)->Vector2:
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
