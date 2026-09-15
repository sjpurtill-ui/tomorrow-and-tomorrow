extends RefCounted
## Kilometre-scale mountain structure beneath the continental uplift envelope.
## This is a deterministic ridged terrain model, not a water-flow simulation.
var noise:=FastNoiseLite.new()

func configure(seed_value:int)->void:
	noise.seed=seed_value^0x39b8d217
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency=.18
	noise.fractal_type=FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves=5
	noise.fractal_lacunarity=2.13
	noise.fractal_gain=.48
	noise.fractal_weighted_strength=.82

func height_at(x:float,z:float,uplift:float)->float:
	# Fade continuously into existing foothills. Flat lowlands, coasts and ocean
	# do not receive a planet-wide covering of identical sharp mountains.
	var strength:=smoothstep(.35,2.8,uplift)
	if strength<=0:return 0.0
	var ridge:=clampf(noise.get_noise_2d(x,z)*.5+.5,0,1)
	# Nonlinear profile leaves broad lower slopes and narrow connected crests.
	# Units are km: bounded modification [-180 m,+620 m] at full uplift.
	return (pow(ridge,2.2)*.8-.18)*strength
