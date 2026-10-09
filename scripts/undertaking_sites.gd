extends RefCounted
## Site search for a landmark. Coordinates and footprint radii are kilometers.
const RADIUS:float=.07
## Rings searched always (a village's landmark stands close in); a town
## searches on past its built ground, to OUTSKIRT_KM beyond its farthest plot,
## never more than MAX_RINGS rings (about 10 km) out.
const NEAR_RINGS:=4
const RING_KM:=.16
const OUTSKIRT_KM:=.6
const MAX_RINGS:=60
## Rise across a footprint, km: level ground first; failing that anywhere in
## reach, ground the builders can terrace.
const LEVEL_KM:=.008
const TERRACE_KM:=.02

static func choose(city:Dictionary,plots:Array,seed:int,height:Callable,land:Callable)->Dictionary:
	var center:Vector2=city.get("position",Vector2.ZERO)
	var turn:=float(posmod(hash(str(seed)+String(city.get("id",""))),360))*PI/180.0
	# The standing plots as circles, read once; and how far the built ground reaches.
	var circles:Array=[]
	var reach:=0.0
	for plot:Dictionary in plots:
		if String(plot.get("status","active")) in ["reclaimed","vacant"]:continue
		var radius:=maxf(.008,sqrt(maxf(0,float(plot.get("area_ha",.01)))*.01/PI))
		var at:=center+Vector2(plot.get("centroid",Vector2.ZERO))
		circles.append([at,radius])
		reach=maxf(reach,at.distance_to(center)+radius)
	var rings:=clampi(ceili((reach+OUTSKIRT_KM-.20)/RING_KM)+1,NEAR_RINGS,MAX_RINGS)
	for rise:float in [LEVEL_KM,TERRACE_KM]:
		var site:=_search(city,center,turn,rings,circles,height,land,rise)
		if not site.is_empty():
			if rise>LEVEL_KM:site["terraced"]=true
			return site
	return {}

static func _search(city:Dictionary,center:Vector2,turn:float,rings:int,circles:Array,height:Callable,land:Callable,rise:float)->Dictionary:
	for ring in rings:
		for spoke in 16:
			var angle:=turn+TAU*float(spoke)/16.0+ring*.19
			var p:=center+Vector2(cos(angle),sin(angle))*(.20+ring*RING_KM)
			if not suitable(p,height,land,rise):continue
			var clear:=true
			for circle:Array in circles:
				if p.distance_to(circle[0])<RADIUS+float(circle[1])+.01:clear=false;break
			var legacy_index:=0
			for r:Dictionary in city.get("undertakings",[]):
				var other:Vector2=r.get("site",{}).get("position",center+Vector2(.18+legacy_index*.12,.16))
				legacy_index+=1
				if p.distance_to(other)<RADIUS*2+.025:clear=false;break
			if clear:return {"position":p,"angle":angle}
	return {}

static func suitable(p:Vector2,height:Callable,land:Callable,rise:float=LEVEL_KM)->bool:
	var low:=INF;var high:=-INF
	for offset in [Vector2.ZERO,Vector2(-RADIUS,-RADIUS),Vector2(-RADIUS,RADIUS),Vector2(RADIUS,-RADIUS),Vector2(RADIUS,RADIUS)]:
		var q:Vector2=p+offset
		if not bool(land.call(q)):return false
		var y:float=height.call(q)
		if not is_finite(y):return false
		low=minf(low,y);high=maxf(high,y)
	return high-low<=rise

static func valid(site:Variant)->bool:
	if not site is Dictionary:return false
	if not site.get("position") is Vector2:return false
	if not (site.get("angle") is float or site.get("angle") is int):return false
	return site.position.is_finite() and is_finite(float(site.angle))
