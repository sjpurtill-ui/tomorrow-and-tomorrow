extends RefCounted
## Fixed-size site search. Coordinates and footprint radii are kilometers.
const RADIUS:float=.07
static func choose(city:Dictionary,plots:Array,seed:int,height:Callable,land:Callable)->Dictionary:
	var center:Vector2=city.get("position",Vector2.ZERO)
	var turn:=float(posmod(hash(str(seed)+String(city.get("id",""))),360))*PI/180.0
	for ring in 4:
		for spoke in 16:
			var angle:=turn+TAU*float(spoke)/16.0+ring*.19
			var p:=center+Vector2(cos(angle),sin(angle))*(.20+ring*.16)
			if not suitable(p,height,land):continue
			var clear:=true
			for plot:Dictionary in plots:
				if String(plot.get("status","active")) in ["reclaimed","vacant"]:continue
				var radius:=maxf(.008,sqrt(maxf(0,float(plot.get("area_ha",.01)))*.01/PI))
				if p.distance_to(center+Vector2(plot.get("centroid",Vector2.ZERO)))<RADIUS+radius+.01:clear=false;break
			var legacy_index:=0
			for r:Dictionary in city.get("undertakings",[]):
				var other:Vector2=r.get("site",{}).get("position",center+Vector2(.18+legacy_index*.12,.16))
				legacy_index+=1
				if p.distance_to(other)<RADIUS*2+.025:clear=false;break
			if clear:return {"position":p,"angle":angle}
	return {}

static func suitable(p:Vector2,height:Callable,land:Callable)->bool:
	var low:=INF;var high:=-INF
	for offset in [Vector2.ZERO,Vector2(-RADIUS,-RADIUS),Vector2(-RADIUS,RADIUS),Vector2(RADIUS,-RADIUS),Vector2(RADIUS,RADIUS)]:
		var q:Vector2=p+offset
		if not bool(land.call(q)):return false
		var y:float=height.call(q)
		if not is_finite(y):return false
		low=minf(low,y);high=maxf(high,y)
	return high-low<=.008

static func valid(site:Variant)->bool:
	if not site is Dictionary:return false
	if not site.get("position") is Vector2:return false
	if not (site.get("angle") is float or site.get("angle") is int):return false
	return site.position.is_finite() and is_finite(float(site.angle))
