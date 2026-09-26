extends RefCounted
## The one coastline both planet height authorities share (LocalTerrain's
## rendered world and PlanetEnvironment's simulation world).
##
## The continental signal alone is ~600 km+ noise, so its zero contour drew
## coasts as straight lines or smooth arcs across whole regional views, and the
## land formula jumped from -60 m to +60 m plus full relief at that contour: a
## kilometres-high cliff that rendered as a dark stepped line. Here the signal is
## roughened only near its zero crossing (bays, headlands and inlets from ~150 km
## down to a few hundred metres), and land relief grows in from the shore so the
## height field is continuous across sea level. World units are kilometres.

## |signal| beyond which no coast can occur; perturbation fades to zero here.
const COAST_BAND_INNER:=0.028
const COAST_BAND_OUTER:=0.04
## Land relief reaches full strength over this much continental signal (~1-3 km):
## a continuous slope, not a cliff, yet coastal ground keeps its hills and stone.
const SHORE_RELIEF_RAMP:=0.0015
## Base land height (the former flat +60 m), reached within a kilometre or two
## of the water so coastal ground stays dry, walkable, settleable land.
const SHORE_BASE_HEIGHT:=0.06
const SHORE_BASE_RAMP:=0.0012
const SEAWARD_BIAS:=0.009
## The sea floor reaches ~20 m within a few kilometres of the shore instead of
## leaving tens of kilometres of centimetre-deep water.
const SHORE_DROP:=0.02
const SHORE_DROP_RAMP:=0.004


static func roughen(land_signal:float,x:float,z:float,terrain:FastNoiseLite,detail:FastNoiseLite)->float:
	var band:=1.0-smoothstep(COAST_BAND_INNER,COAST_BAND_OUTER,absf(land_signal))
	if band<=0.0:return land_signal
	var offset:=terrain.get_noise_2d(x*1.9+5310.0,z*1.9-2270.0)*0.010
	offset+=detail.get_noise_2d(x*0.61-4410.0,z*0.61+3920.0)*0.004
	offset+=detail.get_noise_2d(x*3.3+1290.0,z*3.3-770.0)*0.0015
	offset+=detail.get_noise_2d(x*14.0-3170.0,z*14.0+2630.0)*0.0004
	# One-sided: the roughened shore only ever grows seaward, so no ground that
	# was already land (founded sites, camps, routes in existing saves) floods.
	# The bias exceeds nearly every negative excursion of the noise; where the
	# clamp did bite, the old straight contour came back as ruler-straight coast.
	return land_signal+maxf(0.0,offset+SEAWARD_BIAS)*band


static func sea_height(land_signal:float)->float:
	## A shelf that starts at sea level instead of sixty metres down.
	return -SHORE_DROP*smoothstep(0.0,SHORE_DROP_RAMP,-land_signal)-pow(-land_signal,1.22)*6.8


static func relief_weight(land_signal:float)->float:
	return smoothstep(0.0,SHORE_RELIEF_RAMP,land_signal)


static func land_base(land_signal:float)->float:
	return SHORE_BASE_HEIGHT*smoothstep(0.0,SHORE_BASE_RAMP,land_signal)+land_signal*1.48
