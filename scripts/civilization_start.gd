extends RefCounted
## Every seat uses the same seeded planet sampling and viability search. No
## distance calculation is relative to the human player's selected location.
##
## A SMALLER WORLD (the user, 2026-10-05: "can't we just make the world
## smaller?" and "6-7 on one continent and 6-7 on another (think Europe and
## Asia)"). A world's peoples live on two continents of the planet, each a
## region REGION_HALF_X_KM by REGION_HALF_Z_KM about a centre drawn from the
## seed, at least CONTINENT_APART_KM apart: seats alternate between them, so
## ours (seat 0) shares its continent with six peoples and six live on the
## other, instead of all scattered over the whole globe. Each seat is placed anywhere in that region the
## shared founding kit can live, and never nearer than SEAT_SEPARATION_KM to
## any seat placed before it. The player's people is seat 0 and is placed
## first by the same draw; every other people keeps the same distance from
## every other, the player's included. So the nearest people is about 1,100
## km off: nobody is glimpsed in the first fifteen years and nobody's party can
## reach another people's home in the first quarter century
## (tests/test_far_peoples.gd), but their lands, which grow with them
## (realm_reach.gd), come to meet in the middle centuries, and the frontiers,
## realms and fronts of docs/WAR_GEOGRAPHY.md follow. Worlds already made
## keep their stored positions; this only shapes new worlds.
const SEAT_SEPARATION_KM:=1100.0
## The region every people of a world lives in: half its width and depth (km).
const REGION_HALF_X_KM:=3200.0
const REGION_HALF_Z_KM:=2000.0
## The two continents' centres stand at least this far apart (km).
const CONTINENT_APART_KM:=8000.0
## The planet's own half extents (CivilizationSystem.CIVILIZATION_WORLD_RADIUS_*).
const PLANET_HALF_X_KM:=18000.0
const PLANET_HALF_Z_KM:=8000.0
## Draws the first seat takes (as every seat did before separation).
const FIRST_DRAWS:=48
## More draws a later seat may take to keep its distance from earlier seats.
const SEPARATION_DRAWS:=600
## Seats already placed, per world: {"seed:world_seed": [Vector2, ...]}. A seat
## depends on every seat before it, so each world is placed once, in order.
static var _placed:Dictionary={}

static func candidate(seed_value:int,seat:int)->Vector2:
	var key:="%d:%d" % [seed_value,int(WorldSimulation.state.world_seed)]
	if not _placed.has(key):
		if _placed.size()>=8:_placed.clear()
		_placed[key]=[]
	var placed:Array=_placed[key]
	while placed.size()<=seat:placed.append(_planet_candidate(seed_value,placed.size(),placed))
	return placed[seat]

## Kilometres from `point` to the nearest of `seats` (INF when there are none).
static func separation(point:Vector2,seats:Array)->float:
	var nearest:=INF
	for other:Vector2 in seats:nearest=minf(nearest,point.distance_to(other))
	return nearest

static func _planet_candidate(seed_value:int,seat:int,earlier:Array=[])->Vector2:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value^((seat+1)*32452843)
	var best:=Vector2.ZERO;var best_score:=-INF
	# A crowded or watery planet: the place farthest from every earlier seat,
	# preferring one where the founding kit can live.
	var far:=Vector2.ZERO;var far_value:=-INF
	# Generated communities share a generalist founding kit. Select places where
	# that kit has a plausible subsistence base, not merely a patch of dry ground.
	# This does not restrict later player settlement or grant local resources.
	var centre:=region_centre(seed_value,seat%2)
	for attempt in FIRST_DRAWS+(0 if earlier.is_empty() else SEPARATION_DRAWS):
		# A crowded continent: its later draws reach a little past its edges.
		var spread:=1.0 if attempt<FIRST_DRAWS+SEPARATION_DRAWS/2 else 1.35
		var desired:=centre+Vector2(rng.randf_range(-REGION_HALF_X_KM,REGION_HALF_X_KM),rng.randf_range(-REGION_HALF_Z_KM,REGION_HALF_Z_KM))*spread
		var point:=PlanetEnvironment.nearest_viable_land(desired,seed_value^((seat+1)*104729+attempt))
		var profile:=PlanetEnvironment.profile_at(point)
		var score:=float(profile.food_potential)+minf(.3,float(profile.growing_season)*.3)
		if score>best_score:best=point;best_score=score
		var fits:=supports_founders(profile)
		var apart:=separation(point,earlier)
		if fits and apart>=SEAT_SEPARATION_KM:return point
		var value:=minf(apart,SEAT_SEPARATION_KM)+(100000.0 if fits else 0.0)
		if value>far_value:far=point;far_value=value
	return best if earlier.is_empty() else far

## The centres of a world's two continents: of two dozen seeded places in
## the planet's middle latitudes, the one whose region holds the most land,
## then the best of the rest at least CONTINENT_APART_KM from it. `which` 0 is
## ours (seat 0's), 1 the other.
static var _centres:Dictionary={}
static func region_centre(seed_value:int,which:=0)->Vector2:
	var key:="%d:%d" % [seed_value,int(WorldSimulation.state.world_seed)]
	if not _centres.has(key):
		var rng:=RandomNumberGenerator.new()
		rng.seed=seed_value^0x5eedc0de
		var options:Array=[]
		for option in 24:
			var centre:=Vector2(rng.randf_range(-(PLANET_HALF_X_KM-REGION_HALF_X_KM),PLANET_HALF_X_KM-REGION_HALF_X_KM),rng.randf_range(-(PLANET_HALF_Z_KM-REGION_HALF_Z_KM)*0.6,(PLANET_HALF_Z_KM-REGION_HALF_Z_KM)*0.6))
			var land:=0
			for i in 7:
				for j in 5:
					if PlanetEnvironment.is_land(centre+Vector2((float(i)/6.0*2.0-1.0)*REGION_HALF_X_KM*0.9,(float(j)/4.0*2.0-1.0)*REGION_HALF_Z_KM*0.9)):land+=1
			options.append([land,centre])
		options.sort_custom(func(a:Array,b:Array)->bool:return int(a[0])>int(b[0]))
		var first:Vector2=options[0][1]
		var second:=first+Vector2(CONTINENT_APART_KM*1.5,0.0)
		for option:Array in options:
			if (option[1] as Vector2).distance_to(first)>=CONTINENT_APART_KM:second=option[1];break
		if _centres.size()>=8:_centres.clear()
		_centres[key]=[first,second]
	return (_centres[key] as Array)[clampi(which,0,1)]


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
