extends RefCounted
## The sky over the home settlement, for the map's ambient motion only.
##
## Presentation: nothing here changes the simulation or the save. The game
## keeps no day-by-day weather, so the sky is derived deterministically from
## what it does keep: the world seed, the calendar day, and the home ground's
## real climate (annual rainfall, mean temperature and seasonal swing, and the
## season). A wet coast sees more cloud and rain than a dry interior; winter
## brings snow where the ground is cold; the same day of the same world always
## shows the same sky. Weather fronts pass over a few days, so the sky never
## flips from one hour to the next.
##
## state() is pure and cheap (a handful of hashes), so tests can walk years.

const FRONT_DAYS:=4.3           ## typical spacing of passing weather fronts
const WIND_TURN_DAYS:=9.0       ## prevailing wind wanders on this scale

## A deterministic value in [0,1) for an integer lattice point.
static func _hash01(seed:int,index:int,salt:int)->float:
	var h:=hash(Vector3i(seed,index,salt))
	return float(posmod(h,1000003))/1000003.0

## Smooth 1-D value noise over days, in [0,1]; continuous and C1 in `day`.
static func _smooth_noise(seed:int,day:float,period:float,salt:int)->float:
	var x:=day/maxf(period,0.001)
	var i:=floori(x)
	var f:=x-float(i)
	var a:=_hash01(seed,i,salt)
	var b:=_hash01(seed,i+1,salt)
	var t:=f*f*(3.0-2.0*f)
	return lerpf(a,b,t)

## The day's sky. `climate` takes the PlanetEnvironment profile keys
## precipitation (0..1), mean_temperature_c, seasonality_c and position.
## Returns cloud (0..1 cover), rain and snow (0..1 intensity; at most one is
## non-zero), mist (0..1), wind_dir (unit Vector2 in map x/z), wind (0..1).
static func state(seed:int,day:float,climate:Dictionary)->Dictionary:
	var wet:=clampf(float(climate.get("precipitation",0.5)),0.0,1.0)
	var mean_c:=float(climate.get("mean_temperature_c",11.0))
	var swing:=float(climate.get("seasonality_c",12.0))
	var position:Vector2=climate.get("position",Vector2.ZERO) if climate.get("position") is Vector2 else Vector2.ZERO
	var hemisphere:=-1.0 if position.y>0.0 else 1.0
	var season:=sin(fmod(day,365.0)/365.0*TAU)*hemisphere  # +1 midsummer, -1 midwinter
	# Two overlapping front scales give irregular spells rather than a metronome.
	var front:=0.62*_smooth_noise(seed,day,FRONT_DAYS,11)+0.38*_smooth_noise(seed,day+1.7,FRONT_DAYS*2.6,23)
	# Wetter climates and cooler seasons are cloudier.
	var cloud:=clampf((front-0.30)*1.35+wet*0.42-maxf(0.0,season)*0.10-0.08,0.0,0.9)
	var wetness:=clampf((front-0.58)*3.2,0.0,1.0)*clampf(0.25+wet*0.95,0.0,1.0)
	var temperature_c:=mean_c+season*swing+(front-0.5)*4.0
	var snow:=wetness*clampf((1.0-temperature_c)/3.0,0.0,1.0)
	var rain:=wetness-snow
	# Mist: calm, damp, cool days after rain.
	var calm:=1.0-_smooth_noise(seed,day,FRONT_DAYS*0.8,37)
	var mist:=clampf((wet-0.35)*1.6,0.0,1.0)*clampf((calm-0.45)*2.5,0.0,1.0)*clampf((14.0-temperature_c)/10.0,0.0,1.0)*(1.0-wetness*0.6)
	# Prevailing wind from the world's westerly quarter, wandering slowly.
	var base_angle:=PI+(_hash01(seed,0,51)-0.5)*1.4
	var wander:=(_smooth_noise(seed,day,WIND_TURN_DAYS,53)-0.5)*1.6
	var wind_dir:=Vector2.from_angle(base_angle+wander)
	var wind:=clampf(0.22+front*0.55+wetness*0.18-mist*0.3,0.05,1.0)
	return {"cloud":cloud,"rain":clampf(rain,0.0,1.0),"snow":clampf(snow,0.0,1.0),"mist":mist,
		"wind_dir":wind_dir,"wind":wind,"temperature_c":temperature_c,"front":front}
