extends RefCounted
## Presentation-only walk timing. The same curve moves the body and clocks
## its feet, including when a long route must fit the audience's time budget.

static func sample(progress:float,seconds:float)->Vector2:
	var u:=clampf(progress,0.0,1.0)
	var ramp:=minf(0.20,0.22/maxf(seconds,0.01))
	var area:=1.0-ramp
	var edge:=minf(u,1.0-u)
	if edge<ramp:
		var t:=edge/ramp
		var distance:=ramp*(t*t*t-0.5*t*t*t*t)/area
		return Vector2(distance if u<0.5 else 1.0-distance,smoothstep(0.0,1.0,t)/area)
	return Vector2((u-0.5*ramp)/area,1.0/area)
