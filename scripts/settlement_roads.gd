extends Node3D
## ROADS BETWEEN PLACES (codex/beauty-5): the tracks, then the roads, that
## join the people's settlements to each other and to the strangers' towns
## they know, drawn at the valley and regional views (about 1.5-60 km across)
## the way a hand-inked chart draws them.
##
## - Which places are joined: the settlement network (every player
##   settlement and every foreign city the people have seen, near home) as a
##   shortest spanning tree, plus each town's link to its nearest neighbour.
## - Where the road runs: the straight line between them, bent round water
##   (a road never crosses the sea), then eased into gentle curves with the
##   small wanderings a walked route has. Found a few samples per call, never
##   in one frame's budget, and kept for the world (never per-frame work).
## - How it is drawn, by what the people know: a dashed footpath; a cart
##   track (two ruts) once wheels are known; a made road (a pale bed between
##   two ink lines) once roads are graded. Where it crosses a river: stepping
##   stones at a ford, a plank bridge once timber bridges are known, a stone
##   bridge later. Widths are held in screen pixels by the shader, so one
##   mesh serves every zoom.
## - Where it meets a town: it fades a little short of the houses, and the
##   town's painted ground (settlement_grounds.gd) wears an approach track out
##   along the same bearing, so the road runs on into the streets.
## Visual only: it reads the network and the discovery log, and changes
## nothing in the simulation or the save.

const MAX_NODES:=28
const MAX_LINK_KM:=90.0
const SAMPLE_KM:=0.35
const BUDGET_USEC:=650
const LAND_EPSILON:=0.015

var terrain:Node
## edge key -> {"points":PackedVector3Array,"crossings":PackedFloat32Array}
static var routes:Dictionary={}
static var routes_world:=""
var pending:Array[Dictionary]=[]
var working:Dictionary={}
var edges_signature:=0
var edges:Array=[]
var mesh_key:=0
var mesh_instance:MeshInstance3D
static var _material:ShaderMaterial
var last_pixel:=-1.0

func setup(owner_terrain:Node)->void:
	terrain=owner_terrain
	name="SettlementRoads"
	mesh_instance=MeshInstance3D.new();mesh_instance.name="RoadInk"
	mesh_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.material_override=material()
	add_child(mesh_instance)

static func material()->ShaderMaterial:
	if _material and is_instance_valid(_material):return _material
	var shader:=Shader.new();shader.code=SHADER
	_material=ShaderMaterial.new();_material.shader=shader
	_material.render_priority=2
	return _material

## What the people know of roads and bridges (from the discovery log):
## tier 0 footpath, 1 cart track, 2 made road; bridge 0 ford, 1 timber, 2 stone.
static var _knowledge_key:=-1
static var _knowledge:Dictionary={}
static func knowledge()->Dictionary:
	# The roads drawn follow the roads the builders have laid and keep
	# (built_fabric.gd: the road index), never better than what is known.
	var laid:=preload("res://scripts/built_fabric.gd").drawn_road_tier(GameState)
	var size_key:=GameState.discovery_log.size()*100003+GameState.known_discoveries.size()*7+laid
	if size_key==_knowledge_key:return _knowledge
	_knowledge_key=size_key
	var ids:Dictionary={}
	for entry in GameState.discovery_log:
		if entry is Dictionary:ids[String(entry.get("id",""))]=true
	for id in GameState.known_discoveries:ids[String(id)]=true
	var any:=func(list:Array)->bool:
		for id in list:
			if ids.has(id):return true
		return false
	var tier:=0
	if any.call(["solid_wheel_assembly","cart_running_gear","cart_bed_framing","transport_cart","spoked_wheel_assembly","brushwood_trackways","plank_trackways"]):tier=1
	if any.call(["graded_roads","drained_intertown_roads","paved_haul_roads","aggregate_road_foundations","road_stations","turnpike_trust_roads"]):tier=2
	tier=mini(tier,laid)
	var bridge:=0
	if any.call(["timber_bridges"]):bridge=1
	if any.call(["stone_arch_bridges"]):bridge=2
	_knowledge={"tier":tier,"bridge":bridge}
	return _knowledge

## The places the network joins: [world Vector2, radius km, key].
func _places()->Array:
	var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var out:Array=[]
	for settlement in GameState.player_settlements:
		if not settlement is Dictionary:continue
		var at:Variant=settlement.get("position",Vector2.ZERO)
		if not at is Vector2 or (at as Vector2)==Vector2.ZERO:continue
		if bool(settlement.get("primary",false)):home=at
		out.append([at,0.10,"p:"+String(settlement.get("id",""))])
	if out.is_empty() and "Hearth Circle" in GameState.settlement_completed:out.append([home,0.10,"p:home"])
	if CivilizationSystem.city_intelligence!=null:
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,home,MAX_LINK_KM*1.4):
			var location:Dictionary=city.get("position",{})
			out.append([Vector2(float(location.get("x",0.0)),float(location.get("z",0.0))),0.12,"f:"+String(city.get("city_id",""))])
	out.sort_custom(func(a:Array,b:Array)->bool:return (a[0] as Vector2).distance_squared_to(home)<(b[0] as Vector2).distance_squared_to(home))
	if out.size()>MAX_NODES:out.resize(MAX_NODES)
	return out

## The links: a shortest spanning tree over the places (links no longer
## than MAX_LINK_KM), plus each player town's nearest neighbour.
static func links(places:Array)->Array:
	var result:Array=[]
	var seen:Dictionary={}
	if places.size()<2:return result
	var inside:Array[int]=[0]
	var best:=PackedFloat32Array();var from:=PackedInt32Array()
	for i in places.size():
		best.append((places[i][0] as Vector2).distance_to(places[0][0]));from.append(0)
	best[0]=-1.0
	for step in places.size()-1:
		var pick:=-1;var low:=INF
		for i in places.size():
			if best[i]>=0.0 and best[i]<low:low=best[i];pick=i
		if pick<0:break
		if low<=MAX_LINK_KM:
			var key:=_key(places[from[pick]][2],places[pick][2])
			if not seen.has(key):seen[key]=true;result.append([from[pick],pick])
		best[pick]=-1.0
		for i in places.size():
			if best[i]<0.0:continue
			var d:=(places[i][0] as Vector2).distance_to(places[pick][0])
			if d<best[i]:best[i]=d;from[i]=pick
	for i in places.size():
		if not String(places[i][2]).begins_with("p:"):continue
		var nearest:=-1;var low:=INF
		for j in places.size():
			if j==i:continue
			var d:=(places[i][0] as Vector2).distance_to(places[j][0])
			if d<low:low=d;nearest=j
		if nearest>=0 and low<=MAX_LINK_KM:
			var key:=_key(places[i][2],places[nearest][2])
			if not seen.has(key):seen[key]=true;result.append([i,nearest])
	return result

static func _key(a:String,b:String)->String:
	return a+"|"+b if a<b else b+"|"+a

## Called on the map's network tick: keeps the link set current and routes a
## few samples of any link not yet found (bounded), rebuilding the one mesh
## only when a route has been completed or the knowledge changed.
var _checked_at:=-100000
func refresh()->void:
	if terrain==null:return
	# The places change rarely: look again every two seconds unless a road
	# is still being found.
	var now:=Time.get_ticks_msec()
	if pending.is_empty() and working.is_empty() and now-_checked_at<2000:return
	_checked_at=now
	var world:="%d" % GameState.world_seed
	if routes_world!=world:routes.clear();routes_world=world
	var places:=_places()
	var signature:=hash(places.map(func(p:Array)->Array:return [p[2],snappedf((p[0] as Vector2).x,0.01),snappedf((p[0] as Vector2).y,0.01)]))
	if signature!=edges_signature:
		edges_signature=signature
		edges.clear();pending.clear();working={}
		for link in links(places):
			var a:Array=places[link[0]];var b:Array=places[link[1]]
			var entry:={"key":_key(a[2],b[2]),"a":a[0],"b":b[0],"ra":a[1],"rb":b[1]}
			edges.append(entry)
			if not routes.has(entry.key):pending.append(entry)
	var began:=Time.get_ticks_usec()
	var completed:=false
	while Time.get_ticks_usec()-began<BUDGET_USEC:
		if working.is_empty():
			if pending.is_empty():break
			working=_start(pending.pop_front())
		if _step(working):
			if not (working.get("failed",false) as bool):routes[working.key]={"points":working.points,"crossings":working.crossings}
			else:routes[working.key]={"points":PackedVector3Array(),"crossings":PackedFloat32Array()}
			working={}
			completed=true
	var know:=knowledge()
	var key:=hash([edges.map(func(e:Dictionary)->String:return String(e.key)+":"+str((routes.get(e.key,{}) as Dictionary).get("points",PackedVector3Array()).size())),know])
	if completed or key!=mesh_key:
		if key!=mesh_key:
			mesh_key=key
			_rebuild(know)

# --- Routing ------------------------------------------------------------------

func _start(edge:Dictionary)->Dictionary:
	var a:Vector2=edge.a;var b:Vector2=edge.b
	var length:=a.distance_to(b)
	var count:=clampi(ceili(length/SAMPLE_KM),6,320)
	return {"key":edge.key,"a":a,"b":b,"count":count,"i":0,"flat":PackedVector2Array(),"failed":false,"stage":0,"points":PackedVector3Array(),"crossings":PackedFloat32Array(),"seed":absi(hash(edge.key))}

func _land(p:Vector2)->bool:
	return float(terrain.call("_height_at",p.x,p.y))>0.0+LAND_EPSILON

## One unit of work; true when the route is finished.
func _step(state:Dictionary)->bool:
	var a:Vector2=state.a;var b:Vector2=state.b
	var count:int=state.count
	if int(state.stage)==0:
		# Walk the line, stepping round water.
		var i:int=state.i
		var t:=float(i)/float(count)
		var p:=a.lerp(b,t)
		var side:=(b-a).normalized().orthogonal()
		var flat:PackedVector2Array=state.flat
		if i==0 or i==count or _land(p):
			flat.append(p)
		else:
			var found:=false
			# Prefer the side the previous detour took, so the road holds one shore.
			var last_side:=float(state.get("last_side",1.0))
			for k in range(1,28):
				for sign in [last_side,-last_side]:
					var q:=p+side*float(sign)*float(k)*0.45
					if _land(q):
						flat.append(q);state["last_side"]=sign;found=true;break
				if found:break
			if not found:
				state.failed=true
				return true
		state.flat=flat
		state.i=i+1
		if i+1>count:state.stage=1
		return false
	# Ease it: two rounds of corner cutting, a walked meander, then drape it
	# and find where it crosses rivers.
	var flat:PackedVector2Array=state.flat
	var eased:=flat
	for round_index in 2:eased=_chaikin(eased)
	var length:=a.distance_to(b)
	var along:=0.0
	var meander:=PackedVector2Array()
	var rng_phase:=float(int(state.seed)%1000)*0.01
	for i in eased.size():
		if i>0:along+=eased[i].distance_to(eased[i-1])
		var t:=along/maxf(length,0.001)
		var dir:=(eased[mini(i+1,eased.size()-1)]-eased[maxi(i-1,0)]).normalized()
		var wobble:=(sin(along*0.9+rng_phase)*0.6+sin(along*2.3-rng_phase*1.7)*0.4)*minf(0.12,length*0.01)*sin(t*PI)
		var q:=eased[i]+dir.orthogonal()*wobble
		meander.append(q if _land(q) else eased[i])
	var points:=PackedVector3Array()
	var crossings:=PackedFloat32Array()
	var wet:=false
	for i in meander.size():
		var p:=meander[i]
		points.append(Vector3(p.x,float(terrain.call("_height_at",p.x,p.y)),p.y))
		var river:=float(terrain.call("_main_river_distance_at",p.x,p.y))
		var tributary:=float(terrain.call("_nearest_tributary_distance_at",p)) if terrain.has_method("_nearest_tributary_distance_at") else INF
		var in_water:=river<0.13 or tributary<0.045
		if in_water and not wet:crossings.append(float(i))
		wet=in_water
	state.points=points;state.crossings=crossings
	return true

static func _chaikin(points:PackedVector2Array)->PackedVector2Array:
	if points.size()<3:return points
	var out:=PackedVector2Array([points[0]])
	for i in points.size()-1:
		out.append(points[i].lerp(points[i+1],0.25));out.append(points[i].lerp(points[i+1],0.75))
	out.append(points[points.size()-1])
	return out

# --- Drawing --------------------------------------------------------------------

## One ribbon per road along its centreline: NORMAL is the across direction,
## UV.x the side (-1/+1), UV.y the distance along (km), UV2.x the distance to
## the nearer end (km), UV2.y how near a river crossing (1 at the water).
func _rebuild(know:Dictionary)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drawn:=0
	var approaches:Dictionary={}
	for edge:Dictionary in edges:
		var route:Dictionary=routes.get(edge.key,{})
		var points:PackedVector3Array=route.get("points",PackedVector3Array())
		if points.size()<2:continue
		var crossings:PackedFloat32Array=route.get("crossings",PackedFloat32Array())
		var total:=0.0
		var distances:=PackedFloat32Array([0.0])
		for i in range(1,points.size()):
			total+=Vector2(points[i].x,points[i].z).distance_to(Vector2(points[i-1].x,points[i-1].z))
			distances.append(total)
		var crossing_at:=PackedFloat32Array()
		for c in crossings:crossing_at.append(distances[int(c)])
		for i in points.size()-1:
			var p0:=points[i];var p1:=points[i+1]
			var d0:=Vector2(p1.x-p0.x,p1.z-p0.z)
			if d0.length()<0.00001:continue
			var n0:=_across(points,i);var n1:=_across(points,i+1)
			var v:=[[p0,n0,distances[i]],[p1,n1,distances[i+1]]]
			var corners:Array=[]
			for entry in v:
				var at:Vector3=entry[0];var across:Vector3=entry[1];var dist:float=entry[2]
				var near_crossing:=0.0
				for c in crossing_at:near_crossing=maxf(near_crossing,1.0-smoothstep(0.05,0.16,absf(dist-c)))
				var to_end:=minf(dist,total-dist)
				for side in [-1.0,1.0]:
					corners.append([at,across,Vector2(side,dist),Vector2(to_end,near_crossing)])
			for index in [0,2,1,1,2,3]:
				var c:Array=corners[index]
				surface.set_normal(c[1]);surface.set_uv(c[2]);surface.set_uv2(c[3]);surface.set_color(Color(1,1,1,1))
				surface.add_vertex(c[0])
		drawn+=1
		# Where the road leaves each end, for the town's painted approach.
		for end in [0,1]:
			var at:Vector3=points[0] if end==0 else points[points.size()-1]
			var next:Vector3=points[mini(3,points.size()-1)] if end==0 else points[maxi(points.size()-4,0)]
			var key:="%d:%d" % [roundi(at.x*100.0),roundi(at.z*100.0)]
			if not approaches.has(key):approaches[key]={"center":Vector2(at.x,at.z),"bearings":[]}
			(approaches[key].bearings as Array).append(Vector2(next.x-at.x,next.z-at.z).angle())
	preload("res://scripts/settlement_grounds.gd").set_approaches(approaches)
	mesh_instance.mesh=surface.commit() if drawn>0 else null
	var m:=material()
	m.set_shader_parameter("tier",int(know.tier))
	m.set_shader_parameter("bridge",int(know.bridge))
	set_meta("roads_drawn",drawn)

static func _across(points:PackedVector3Array,i:int)->Vector3:
	var a:=points[maxi(i-1,0)];var b:=points[mini(i+1,points.size()-1)]
	var d:=Vector2(b.x-a.x,b.z-a.z)
	if d.length()<0.000001:return Vector3(1,0,0)
	d=d.normalized()
	return Vector3(-d.y,0.0,d.x)

## The zoom: widths in pixels, and how strongly roads show at this view.
func update_view(camera_size:float,pixel_km:float)->void:
	visible=camera_size>=1.1 and camera_size<=120.0 and mesh_instance.mesh!=null
	if not visible:return
	if absf(pixel_km-last_pixel)<=last_pixel*0.01:return
	last_pixel=pixel_km
	var m:=material()
	m.set_shader_parameter("pixel_km",pixel_km)
	m.set_shader_parameter("fade",smoothstep(1.1,2.0,camera_size)*(1.0-smoothstep(60.0,120.0,camera_size)))
	# Short of the houses at the valley view (the streets take over there);
	# up to the town's mark when the town is only a mark.
	m.set_shader_parameter("town_km",maxf(0.16*(1.0-smoothstep(3.0,8.0,camera_size)),pixel_km*7.0))

const SHADER:="""
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float pixel_km = 0.001;
uniform float fade = 1.0;
uniform float town_km = 0.1;
uniform int tier = 0;
uniform int bridge = 0;
varying float across_px;
varying float along_px;
varying float to_end;
varying float wet;
varying float half_px;
void vertex() {
	wet = UV2.y;
	float body = tier == 2 ? 3.0 : (tier == 1 ? 2.2 : 1.5);
	float span = bridge > 0 ? 3.4 : 2.4;
	half_px = mix(body, max(body, span), smoothstep(0.0, 0.4, wet));
	VERTEX += NORMAL*UV.x*half_px*pixel_km;
	// A little proud of the land, in pixels, so coarse relief never hides it.
	VERTEX.y += pixel_km*5.0;
	across_px = UV.x*half_px;
	along_px = UV.y/pixel_km;
	to_end = UV2.x;
}
float line(float d, float width) { return 1.0-smoothstep(width*0.5, width*0.5+0.9, abs(d)); }
void fragment() {
	vec3 ink = vec3(0.30, 0.215, 0.13)*0.75;
	vec3 bed = vec3(0.80, 0.70, 0.52);
	vec3 colour = ink;
	float a = 0.0;
	if (tier == 0) {
		// A footpath: a fine dashed line of sepia ink.
		float dash = step(fract(along_px/10.0), 0.62);
		a = line(across_px, 1.1)*dash*0.82;
	} else if (tier == 1) {
		// A cart track: two fine ruts side by side, unbroken, the way an
		// old chart draws a way wheels use.
		a = line(abs(across_px)-1.2, 0.7)*0.62;
	} else {
		// A made road: a pale bed between two ink lines.
		float edge = line(abs(across_px)-2.5, 0.9);
		float inside = 1.0-smoothstep(2.0, 2.5, abs(across_px));
		colour = mix(bed, ink, edge);
		a = max(edge*0.9, inside*0.72);
	}
	if (wet > 0.01) {
		vec3 c2 = ink; float a2 = 0.0;
		if (bridge == 0) {
			// A ford: stepping stones across the water.
			vec2 cell = vec2((fract(along_px/5.0)-0.5)*5.0, across_px*0.9);
			float stone = 1.0-smoothstep(1.1, 1.9, length(cell));
			c2 = mix(vec3(0.62, 0.58, 0.50), ink, smoothstep(0.6, 1.4, length(cell)));
			a2 = stone*0.95;
		} else {
			// A bridge: a deck with rails, planks across it (timber), or a
			// paler stone deck with heavier parapets.
			float rail = line(abs(across_px)-3.0, bridge == 2 ? 1.4 : 1.0);
			float deck = 1.0-smoothstep(2.6, 3.0, abs(across_px));
			float plank = bridge == 1 ? line(fract(along_px/2.6)-0.5, 0.35)*0.35 : 0.0;
			vec3 surface = bridge == 1 ? vec3(0.62, 0.48, 0.32) : vec3(0.80, 0.77, 0.70);
			c2 = mix(surface*(1.0-plank), ink, rail);
			a2 = max(rail, deck*0.95);
		}
		colour = mix(colour, c2, wet);
		a = mix(a, a2, wet);
	}
	// It stops a little short of the town, where the streets take over.
	a *= smoothstep(town_km*0.55, town_km, to_end);
	ALBEDO = colour;
	ALPHA = a*fade;
}
"""
