extends RefCounted
## Every seat uses the same seeded planet sampling and viability search. No
## distance calculation is relative to the human player's selected location.
static func candidate(seed_value:int,seat:int)->Vector2:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value^((seat+1)*32452843)
	var desired:=Vector2(rng.randf_range(-18000,18000),rng.randf_range(-8000,8000))
	return PlanetEnvironment.nearest_viable_land(desired,seed_value^((seat+1)*104729))

static func choose(origin:Vector2,ground:Callable)->Vector2:
	var best:=origin;var score:=INF
	for radius:float in [0,2,5,10,20,40,80,160]:
		for spoke in (1 if radius==0 else 32):
			var point:=origin+Vector2.from_angle(TAU*float(spoke)/32.0)*radius
			var sample:Dictionary=ground.call(point)
			if float(sample.get("height",-1))<=.02 or float(sample.get("slope",1))>.48:continue
			if not bool(sample.get("founding_valid",true)):continue
			var water:=float(sample.get("river_distance_km",INF))
			if water>6:continue
			var value:=radius*.02+water*3.0+float(sample.get("slope",0))*12.0-float(sample.get("fertility",0))
			if value<score:score=value;best=point
	return best
