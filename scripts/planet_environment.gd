extends Node

## Deterministic environmental authority for the whole planet. Rendered ground may
## supply higher-resolution observations, but player settlements and off-screen
## civilizations consume the same bounded climate, ecology, geology and hazard model.

const PLANET_WIDTH_KM:=40075.0
const PLANET_DEPTH_KM:=20004.0
const SEA_LEVEL:=0.0

var _configured_seed:=2147483647
var _continent:=FastNoiseLite.new()
var _mountains:=FastNoiseLite.new()
var _terrain:=FastNoiseLite.new()
var _detail:=FastNoiseLite.new()
var _moisture:=FastNoiseLite.new()
var _geology_a:=FastNoiseLite.new()
var _geology_b:=FastNoiseLite.new()
var _geology_c:=FastNoiseLite.new()
var _viable_land_cache:Dictionary={}
var _profile_cache:Dictionary={}


func _ready()->void:
	reset_for_new_world()


func reset_for_new_world()->void:
	_configured_seed=2147483647
	_ensure_configured()


func _ensure_configured()->void:
	var seed_value:=GameState.world_seed
	if seed_value==_configured_seed: return
	_configured_seed=seed_value
	_viable_land_cache.clear()
	_profile_cache.clear()
	_configure_noise(_continent,seed_value,0.000105,5,FastNoiseLite.FRACTAL_FBM)
	_continent.fractal_lacunarity=2.05
	_continent.fractal_gain=0.52
	_configure_noise(_mountains,seed_value^0x2c9277b5,0.00072,5,FastNoiseLite.FRACTAL_RIDGED)
	_configure_noise(_terrain,seed_value^104729,0.0032,5,FastNoiseLite.FRACTAL_FBM)
	_configure_noise(_detail,(seed_value^104729)^0x45d9f3b,0.028,4,FastNoiseLite.FRACTAL_FBM)
	_configure_noise(_moisture,seed_value^0x71a94c31,0.00048,4,FastNoiseLite.FRACTAL_FBM)
	_configure_noise(_geology_a,seed_value^0x19a5d30f,0.00019,4,FastNoiseLite.FRACTAL_FBM)
	_configure_noise(_geology_b,seed_value^0x43f6a98d,0.00047,4,FastNoiseLite.FRACTAL_RIDGED)
	_configure_noise(_geology_c,seed_value^0x6c8e9cf5,0.0011,3,FastNoiseLite.FRACTAL_FBM)


func _configure_noise(noise:FastNoiseLite,seed_value:int,frequency:float,octaves:int,fractal:int)->void:
	noise.seed=seed_value
	noise.frequency=frequency
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type=fractal
	noise.fractal_octaves=octaves


func world_height_at(position:Vector2)->float:
	## Planet-scale counterpart of LocalTerrain's authored height field. LocalTerrain
	## remains authoritative for close samples and passes its measured height back in.
	_ensure_configured()
	var x:=position.x
	var z:=position.y
	var latitude:=clampf(absf(z)/(PLANET_DEPTH_KM*0.5),0.0,1.0)
	var continental:=_continent.get_noise_2d(x,z)*0.78
	continental+=_continent.get_noise_2d(x*0.47+7813.0,z*0.47-4197.0)*0.34
	var cradle:=exp(-pow(x/1150.0,2.0)-pow(z/880.0,2.0))*1.05
	var land_signal:=continental+cradle-0.075-pow(latitude,3.2)*0.72
	if land_signal<=0.0: return -0.06-pow(-land_signal,1.22)*6.8
	var rolling:=_terrain.get_noise_2d(x,z)
	var local_detail:=_detail.get_noise_2d(x,z)
	var hill_signal:=maxf(0.0,_terrain.get_noise_2d(x+820.0,z-460.0)+0.10)
	var ridge:=1.0-absf(_mountains.get_noise_2d(x,z))
	ridge=pow(clampf((ridge-0.34)/0.66,0.0,1.0),2.35)
	var belt:=clampf((_mountains.get_noise_2d(x*0.41+9200.0,z*0.41-3800.0)+0.18)*1.55,0.0,1.0)
	return 0.06+land_signal*1.48+rolling*1.42+local_detail*0.56+pow(hill_signal,2.0)*2.05+ridge*belt*8.4


func is_land(position:Vector2)->bool:
	return world_height_at(position)>SEA_LEVEL+0.015


func nearest_viable_land(desired:Vector2,search_seed:int=0)->Vector2:
	## Rival origins use actual land instead of being dropped on the nearest point of
	## an abstract ellipse. The search is fixed-size and deterministic. The global
	## fallback is important: an ocean basin can be wider than a regional search,
	## and returning the cradle for every miss would pile distant societies at 0,0.
	_ensure_configured()
	var cache_key:="%d:%d:%d:%d" % [_configured_seed,search_seed,roundi(desired.x),roundi(desired.y)]
	if _viable_land_cache.has(cache_key): return _viable_land_cache[cache_key]
	if is_land(desired):
		_viable_land_cache[cache_key]=desired
		return desired
	var phase:=float(abs(search_seed)%10007)/10007.0*TAU
	for ring in range(1,17):
		var radius:=float(ring)*140.0
		for spoke in 20:
			var angle:=phase+TAU*float(spoke)/20.0
			var candidate:=desired+Vector2.from_angle(angle)*radius
			candidate.x=clampf(candidate.x,-PLANET_WIDTH_KM*0.495,PLANET_WIDTH_KM*0.495)
			candidate.y=clampf(candidate.y,-PLANET_DEPTH_KM*0.495,PLANET_DEPTH_KM*0.495)
			if is_land(candidate):
				_viable_land_cache[cache_key]=candidate
				return candidate
	# Sample the whole planet with a seeded low-discrepancy sequence, then choose
	# the viable point nearest the requested origin. This remains bounded and gives
	# every polity a distinct candidate set instead of sharing a fixed grid.
	var best:=Vector2.ZERO
	var best_distance:=INF
	var seed_phase:=float(abs(search_seed*31+_configured_seed)%65521)/65521.0
	for sample_index in 256:
		var sequence_index:=sample_index+1
		var u:=fmod(_radical_inverse(sequence_index,2)+seed_phase,1.0)
		var v:=fmod(_radical_inverse(sequence_index,3)+seed_phase*0.61803398875,1.0)
		var candidate:=Vector2(lerpf(-PLANET_WIDTH_KM*0.495,PLANET_WIDTH_KM*0.495,u),lerpf(-PLANET_DEPTH_KM*0.495,PLANET_DEPTH_KM*0.495,v))
		if not is_land(candidate): continue
		var candidate_distance:=candidate.distance_squared_to(desired)
		if candidate_distance<best_distance:
			best=candidate
			best_distance=candidate_distance
	# The seeded cradle is deliberately viable and is safer than an ocean record.
	_viable_land_cache[cache_key]=best
	return best


func _radical_inverse(index:int,base:int)->float:
	var result:=0.0
	var fraction:=1.0/float(base)
	var remaining:=index
	while remaining>0:
		result+=float(remaining%base)*fraction
		remaining/=base
		fraction/=float(base)
	return result


func profile_at(position:Vector2,observed:Dictionary={})->Dictionary:
	_ensure_configured()
	var cache_key:="%d:%d:%d" % [_configured_seed,roundi(position.x*10.0),roundi(position.y*10.0)]
	if observed.is_empty() and _profile_cache.has(cache_key): return (_profile_cache[cache_key] as Dictionary).duplicate(true)
	var height:=float(observed.get("height",world_height_at(position)))
	var latitude:=clampf(absf(position.y)/(PLANET_DEPTH_KM*0.5),0.0,1.0)
	var latitude_warmth:=1.0-latitude
	var temperature:=clampf(latitude_warmth-maxf(0.0,height)*0.055,0.0,1.0)
	var moisture:=_moisture.get_noise_2d(position.x,position.y)
	var regional_weather:=_terrain.get_noise_2d(position.x+1700.0,position.y-2300.0)
	var interior:=clampf((_continent.get_noise_2d(position.x,position.y)-0.05)*1.2,0.0,0.5)
	var precipitation:=clampf(0.48+moisture*0.52+regional_weather*0.34-interior*0.55,0.0,1.0)
	precipitation=clampf(0.5+(precipitation-0.5)*1.9,0.0,1.0)
	if observed.has("temperature"): temperature=clampf(float(observed.temperature),0.0,1.0)
	if observed.has("precipitation"): precipitation=clampf(float(observed.precipitation),0.0,1.0)
	var river_distance:=float(observed.get("river_distance_km",INF))
	if river_distance<16.0:
		precipitation=clampf(precipitation+(1.0-river_distance/16.0)*0.28,0.0,1.0)
	var coastal:=bool(observed.get("coastal",_coastal_at(position,height)))
	var biome:=String(observed.get("biome",_biome_id(height,temperature,precipitation,river_distance)))
	var woodland:=clampf(float(observed.get("woodland",_woodland(height,temperature,precipitation))),0.0,1.0)
	var fertility:=clampf(float(observed.get("fertility",_fertility(biome,precipitation))),0.0,1.0)
	var forage:=clampf(precipitation*0.60+woodland*0.30+(0.25 if biome=="wetland" else 0.0),0.0,1.0)
	var game:=clampf(woodland*(1.60-woodland)+(0.20 if biome in ["grassland","floodplain"] else 0.0),0.0,1.0)
	var relief:=clampf(absf(float(observed.get("relief",0.0)))*1.8+maxf(0.0,height)/7.0,0.0,1.0)
	var stone:=clampf(float(observed.get("stone",relief*(1.0-woodland*0.55)+(0.28 if biome=="upland" else 0.0))),0.0,1.0)
	var mean_temp_c:=lerpf(-6.0,28.0,temperature)
	var continentality:=clampf(absf(position.x)/(PLANET_WIDTH_KM*0.5)*0.35+interior*1.2,0.0,1.0)
	var seasonality_c:=lerpf(5.0,22.0,latitude)*lerpf(0.78,1.20,continentality)
	var rainfall_mm:=lerpf(160.0,2200.0,precipitation)
	var rainfall_variability:=clampf(0.18+(1.0-precipitation)*0.46+absf(_geology_c.get_noise_2d(position.x+1900.0,position.y))*0.22,0.08,0.92)
	var growing_season:=clampf((temperature*1.20)*(0.46+precipitation*0.72),0.04,1.0)
	var water_access:=maxf(1.0-river_distance/18.0 if river_distance<INF else 0.0,0.72 if coastal else 0.0)
	var geology:=_geology(position,height)
	var hazards:={
		"drought":clampf((1.0-precipitation)*0.76+rainfall_variability*0.28,0.0,1.0),
		"flood":clampf((1.0-river_distance/7.0 if river_distance<7.0 else 0.0)*0.72+maxf(0.0,precipitation-0.72)*0.74,0.0,1.0),
		"cold":clampf((0.34-temperature)*2.0+seasonality_c/60.0,0.0,1.0),
		"heat":clampf((temperature-0.78)*2.6+(1.0-precipitation)*0.20,0.0,1.0),
		"disease":clampf(precipitation*temperature*0.82+(0.18 if biome=="wetland" else 0.0),0.0,1.0),
		"storm":clampf((0.40+precipitation*0.35)*float(coastal)+absf(_moisture.get_noise_2d(position.x+8100.0,position.y-3700.0))*0.18,0.0,1.0)
	}
	var resources:=_resource_potentials(position,biome,temperature,precipitation,woodland,fertility,forage,game,stone,water_access,coastal,geology)
	var food_potential:=clampf(forage*0.26+game*0.20+fertility*0.30+water_access*0.13+(0.16 if coastal else 0.0)-float(hazards.drought)*0.12,0.10,1.20)
	var construction_potential:=clampf(maxf(maxf(float(resources.Timber),float(resources.Stone)),float(resources.Clay))*0.68+float(resources["Fiber Plants"])*0.18+float(geology.mineralization)*0.20,0.08,1.15)
	var route_potential:=clampf(0.74-relief*0.46+water_access*0.18+(0.18 if coastal else 0.0),0.12,1.05)
	var profile:Dictionary={
		"position":position,"height":height,"land":height>SEA_LEVEL,"biome":biome,"archetype":_archetype(biome,temperature,precipitation,coastal,relief),
		"temperature":temperature,"mean_temperature_c":mean_temp_c,"seasonality_c":seasonality_c,
		"precipitation":precipitation,"annual_rainfall_mm":rainfall_mm,"rainfall_variability":rainfall_variability,"growing_season":growing_season,
		"river_distance_km":river_distance,"coastal":coastal,"water_access":water_access,
		"woodland":woodland,"fertility":fertility,"forage":forage,"game":game,"stone":stone,"relief":relief,
		"hazards":hazards,"geology":geology,"resource_potentials":resources,
		"food_potential":food_potential,"construction_potential":construction_potential,"route_potential":route_potential,
		"subsistence_multiplier":lerpf(0.62,1.34,clampf(food_potential,0.0,1.0)),
		"health_pressure":clampf(float(hazards.disease)*0.42+float(hazards.cold)*0.30+float(hazards.heat)*0.20+float(hazards.flood)*0.08,0.0,1.0),
		"ecological_resilience":clampf(0.25+precipitation*0.30+growing_season*0.28-rainfall_variability*0.16,0.08,0.96),
		"signature":environment_signature_from_values(biome,temperature,precipitation,geology,coastal)
	}
	if observed.is_empty(): _profile_cache[cache_key]=profile.duplicate(true)
	return profile


func _coastal_at(position:Vector2,height:float)->bool:
	if height<=SEA_LEVEL: return false
	for radius in [3.0,12.0,36.0]:
		for spoke in 8:
			if world_height_at(position+Vector2.from_angle(TAU*float(spoke)/8.0)*radius)<=SEA_LEVEL: return true
	return false


func _woodland(height:float,temperature:float,precipitation:float)->float:
	var value:=clampf((precipitation-0.40)*2.6,0.0,1.0)*clampf((temperature-0.16)*3.4,0.0,1.0)
	if height>3.2: value*=1.0-clampf((height-3.2)/5.2,0.0,0.74)
	return value


func _biome_id(height:float,temperature:float,precipitation:float,river_distance:float)->String:
	if height<SEA_LEVEL: return "water"
	var woodland:=_woodland(height,temperature,precipitation)
	if temperature<0.16: return "tundra"
	if height>6.0: return "upland"
	if river_distance<3.2 and height<3.0: return "floodplain"
	if precipitation>0.70 and height<0.9 and river_distance<18.0: return "wetland"
	if woodland>0.42: return "woodland"
	if precipitation<0.36: return "steppe"
	return "grassland"


func _fertility(biome:String,precipitation:float)->float:
	match biome:
		"floodplain": return 0.95
		"grassland": return 0.55+precipitation*0.25
		"wetland": return 0.60
		"woodland": return 0.34
		"steppe": return 0.14
	return 0.05


func _geology(position:Vector2,height:float)->Dictionary:
	var a:=(_geology_a.get_noise_2d(position.x,position.y)+1.0)*0.5
	var b:=(_geology_b.get_noise_2d(position.x-5300.0,position.y+2100.0)+1.0)*0.5
	var c:=(_geology_c.get_noise_2d(position.x+1700.0,position.y-7900.0)+1.0)*0.5
	var igneous:=clampf(b*0.72+maxf(0.0,height)/9.0*0.28,0.0,1.0)
	var sedimentary:=clampf(a*0.76+(1.0-b)*0.24,0.0,1.0)
	var metamorphic:=clampf((1.0-a)*0.40+b*0.38+c*0.22,0.0,1.0)
	return {"igneous":igneous,"sedimentary":sedimentary,"metamorphic":metamorphic,"mineralization":clampf(absf(b-c)*1.45+igneous*0.28,0.0,1.0),"basin":clampf(sedimentary*(1.0-maxf(0.0,height)/8.0),0.0,1.0),"weathering":clampf(c*0.64+(1.0-b)*0.36,0.0,1.0)}


func _resource_potentials(position:Vector2,biome:String,temperature:float,precipitation:float,woodland:float,fertility:float,forage:float,game:float,stone:float,water:float,coastal:bool,geology:Dictionary)->Dictionary:
	var local_variation:=(_geology_c.get_noise_2d(position.x*1.7+430.0,position.y*1.7-910.0)+1.0)*0.5
	var wetland:=1.0 if biome in ["wetland","floodplain"] else 0.0
	var arid:=1.0-precipitation
	var sediment:=float(geology.sedimentary)
	var igneous:=float(geology.igneous)
	var metamorphic:=float(geology.metamorphic)
	var mineral:=float(geology.mineralization)
	var basin:=float(geology.basin)
	var weathering:=float(geology.weathering)
	return {
		"Timber":clampf(woodland*1.08,0.0,1.0),"Freshwater":clampf(water,0.0,1.0),"Stone":stone,
		"Fertile Soil":fertility,"Game":game,"Fiber Plants":clampf(forage*0.68+wetland*0.24+woodland*0.12,0.0,1.0),
		"Clay":clampf(sediment*0.42+wetland*0.32+weathering*0.30,0.0,1.0),"Flint":clampf(sediment*0.72*(1.0-igneous*0.32),0.0,1.0),
		"Salt":clampf(arid*0.54+(0.48 if coastal else 0.0)+basin*0.20,0.0,1.0),"Medicinal Plants":clampf(forage*0.56+temperature*precipitation*0.42,0.0,1.0),
		"Peat":clampf(wetland*0.62+precipitation*(1.0-temperature)*0.30,0.0,1.0),"Limestone":clampf(sediment*0.76+basin*0.18-local_variation*0.16,0.0,1.0),
		"Copper Ore":clampf(mineral*0.62+igneous*0.26+local_variation*0.12,0.0,1.0),"Tin Ore":clampf(mineral*metamorphic*0.92,0.0,1.0),
		"Lead Ore":clampf(mineral*0.48+sediment*0.22+metamorphic*0.20,0.0,1.0),"Bitumen":clampf(basin*sediment*0.88,0.0,1.0),
		"Fine Sand":clampf(arid*0.32+(0.48 if coastal else 0.0)+wetland*0.18,0.0,1.0),"Iron Ore":clampf(metamorphic*0.46+igneous*0.36+weathering*0.16,0.0,1.0),
		"Coal":clampf(basin*precipitation*0.82+wetland*0.10,0.0,1.0),"Sulfur":clampf(igneous*mineral*0.94,0.0,1.0),
		"Nitrates":clampf(arid*weathering*0.62+(0.18 if coastal else 0.0),0.0,1.0),"Deep Aquifer":clampf(sediment*0.40+basin*0.35+precipitation*0.18,0.0,1.0),
		"Refractory Clay":clampf(weathering*0.50+igneous*0.28+sediment*0.12,0.0,1.0),"Phosphate Rock":clampf(sediment*0.44+(0.28 if coastal else 0.0)+local_variation*0.18,0.0,1.0),
		"Graphite":clampf(metamorphic*mineral*0.86,0.0,1.0)
	}


func _archetype(biome:String,temperature:float,precipitation:float,coastal:bool,relief:float)->String:
	if coastal and precipitation>0.58: return "wet maritime"
	if coastal: return "dry maritime"
	if relief>0.62: return "rugged highland"
	if temperature<0.25: return "cold continental"
	if precipitation<0.30: return "arid interior"
	if biome=="floodplain": return "river basin"
	if biome=="woodland": return "forest country"
	return "temperate interior"


func environment_signature_from_values(biome:String,temperature:float,precipitation:float,geology:Dictionary,coastal:bool)->String:
	return "%s:%d:%d:%d:%d" % [biome,roundi(temperature*5.0),roundi(precipitation*5.0),roundi(float(geology.mineralization)*4.0),1 if coastal else 0]


func season_wave(profile:Dictionary,day:float)->float:
	var position:Vector2=profile.get("position",Vector2.ZERO)
	var hemisphere:=-1.0 if position.y>0.0 else 1.0
	return sin(fmod(day,365.0)/365.0*TAU)*hemisphere


func food_season_factor(food_type:String,profile:Dictionary,day:float)->float:
	var wave:=season_wave(profile,day)
	var seasonality:=clampf(float(profile.get("seasonality_c",12.0))/20.0,0.25,1.35)
	var growing:=clampf(float(profile.get("growing_season",0.5)),0.04,1.0)
	var precipitation:=clampf(float(profile.get("precipitation",0.5)),0.0,1.0)
	match food_type:
		"Fresh plants": return clampf((0.58+growing*0.52)+wave*0.40*seasonality,0.16,1.52)
		"Fresh meat": return clampf(0.88+float(profile.get("game",0.4))*0.20-wave*0.10*seasonality,0.58,1.22)
		"Fish": return clampf(0.86+float(profile.get("water_access",0.0))*0.22+sin(fmod(day,365.0)/365.0*TAU+0.8)*0.14,0.52,1.24)
		"Dry staples": return clampf(0.30+growing*0.70+wave*0.56*seasonality-(1.0-precipitation)*0.18,0.02,1.58)
	return 1.0
