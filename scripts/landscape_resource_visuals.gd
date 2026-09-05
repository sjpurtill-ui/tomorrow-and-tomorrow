extends RefCounted

const MAX_AREAS:=32
const CUTTING_SHADER:="""
uniform int woodland_area_count=0;
uniform vec4 woodland_areas[32];
float woodland_retained(vec2 point){
	float retained=1.0;
	for(int i=0;i<woodland_area_count;i++){
		vec4 area=woodland_areas[i];
		vec2 offset=abs(point-area.xy);
		float edge=max(offset.x,offset.y)/max(area.z,0.01);
		float weight=1.0-smoothstep(0.82,1.0,edge);
		retained=min(retained,mix(1.0,area.w,weight));
	}
	return retained;
}
"""

static func areas_from_ledgers(ledgers:Array,center:Vector2)->PackedVector4Array:
	var candidates:Array[Vector4]=[]
	for ledger in ledgers:
		for deposit in ledger:
			if String(deposit.get("landscape_source",""))!="woodland_catchment": continue
			var capacity:=float(deposit.get("initial_amount",0.0))
			if capacity<=0.0: continue
			var remaining:=clampf(float(deposit.get("remaining",capacity))/capacity,0.0,1.0)
			if remaining>0.999: continue
			var point:Vector3=deposit.get("position",Vector3.ZERO)
			candidates.append(Vector4(point.x,point.z,sqrt(maxf(0.01,float(deposit.get("area_km2",9.0))))*0.5,remaining))
	candidates.sort_custom(func(a:Vector4,b:Vector4)->bool: return Vector2(a.x,a.y).distance_squared_to(center)<Vector2(b.x,b.y).distance_squared_to(center))
	if candidates.size()>MAX_AREAS: candidates.resize(MAX_AREAS)
	return PackedVector4Array(candidates)

static func retained_at(point:Vector2,areas:PackedVector4Array)->float:
	var retained:=1.0
	for area in areas:
		var offset:=(point-Vector2(area.x,area.y)).abs()
		var edge:=maxf(offset.x,offset.y)/maxf(area.z,0.01)
		retained=minf(retained,lerpf(1.0,area.w,1.0-smoothstep(0.82,1.0,edge)))
	return retained

static func surface_style(resource:String)->Dictionary:
	match resource:
		"Clay", "Refractory Clay": return {"soil":Color("#94664c"),"rock":Color("#a4795c"),"outcrops":false}
		"Limestone", "Fine Sand", "Salt": return {"soil":Color("#b1a58a"),"rock":Color("#c2bba4"),"outcrops":resource=="Limestone","layered":true}
		"Iron Ore": return {"soil":Color("#865741"),"rock":Color("#775043"),"outcrops":true}
		"Copper Ore": return {"soil":Color("#6c7960"),"rock":Color("#66776a"),"outcrops":true}
		"Coal", "Graphite": return {"soil":Color("#4c4b43"),"rock":Color("#41443e"),"outcrops":true,"layered":true}
		"Peat", "Bitumen": return {"soil":Color("#534c37"),"rock":Color("#554d3f"),"outcrops":false}
		"Medicinal Plants", "Fiber Plants", "Game", "Fertile Soil": return {"soil":Color("#637946"),"rock":Color("#778361"),"outcrops":false}
		_: return {"soil":Color("#8c8974"),"rock":Color("#949486"),"outcrops":resource in ["Stone","Flint","Tin Ore","Lead Ore","Phosphate Rock","Sulfur"]}
