extends Node3D
## THE MAP'S WEATHER AND WILD LIFE: motion around the people, visual only.
##
## Nothing here changes the simulation or the save. Everything is bounded,
## procedural (no image assets) and animated on the GPU from one clock, so the
## CPU cost per frame is a few uniform writes:
## - Wind. One wind (scripts/map_weather.gd) drives hearth smoke drift, cloud
##   drift and rain slant. Other map materials can follow it: a ShaderMaterial
##   declaring `uniform vec4 map_wind` (xy direction, z strength 0..1, w gust)
##   and `uniform float map_wind_clock` (seconds of wind-weighted time, use
##   for sway phase) receives both when registered with bind_wind_material(),
##   or automatically when it is in the terrain's seasonal_materials list.
## - Cloud shadows drift over the ground at close and valley heights and fade
##   out toward the regional chart.
## - Rain or snow falls over the view at close heights on wet days.
## - Birds wheel over the water and the woods near home (fewer in winter).
## - A wild herd grazes the open ground where the land holds game and the
##   people hunt it.
## - Boats work the water when the people fish it.
## Representatives are bounded stand-ins, never one per animal or person:
## at most MAX_BIRDS birds, MAX_ANIMALS animals, MAX_BOATS boats, MAX_DROPS drops.
## Reduced motion keeps cloud shadows still and hides rain, snow and birds.

const MapWeather:=preload("res://scripts/map_weather.gd")
const MapMotion:=preload("res://scripts/map_motion.gd")
const NODE_NAME:="MapAmbience"
const UNIT:=0.001                 ## one metre in map units (km)
const MAX_BIRDS:=21
const BIRDS_PER_FLOCK:=7
const MAX_ANIMALS:=12
const ANIMALS_PER_HERD:=6
const MAX_FLOCKS:=3
const MAX_BOATS:=3
const MAX_DROPS:=1400
const CLOUD_FULL_BELOW:=18.0      ## camera.size (km): full cloud shadow at and below
const CLOUD_GONE_ABOVE:=55.0      ## gone before the pattern shrinks to speckle
const WEATHER_MAX_VIEW:=7.0       ## rain and snow drawn at and below this view
const LIFE_MAX_VIEW:=4.0          ## birds, herds and boats
const CLOUD_SPEED_KMH:=120.0      ## time-lapsed drift at full wind (real: 20-60 km/h)

static var enabled:=true
## Capture harnesses only: merged over the derived sky (never set in play).
static var forced_weather:Dictionary={}
static var _wind_materials:Array[WeakRef]=[]

var terrain:Node3D
var weather:Dictionary={}
var weather_day:=-1.0
var climate:Dictionary={}
var climate_anchor:=Vector3(INF,0,INF)
var wind_dir:=Vector2(-1,0)
var wind:=0.3
var cloud:=0.3
var rain:=0.0
var snow:=0.0
var clock:=0.0
var wind_clock:=0.0
var cloud_drift:=Vector2.ZERO
var cloud_mesh:MeshInstance3D
var drops:MultiMeshInstance3D
var birds:MultiMeshInstance3D
var herd:MultiMeshInstance3D
var boats:MultiMeshInstance3D
var life_signature:=""
var frame_usec:=0.0
var last_report:Dictionary={}
var _cloud_material:ShaderMaterial
var _legibility:=-1.0
var _wind_targets:Array[WeakRef]=[]
var _wind_scan_key:=""
var _drop_material:ShaderMaterial
var _bird_material:ShaderMaterial
var _herd_material:ShaderMaterial
var _boat_material:ShaderMaterial

# --------------------------------------------------------------------------
# Hooks (called from living_map.gd, so the map itself needs no new lines)
# --------------------------------------------------------------------------

static func ensure(host:Node3D)->Node3D:
	if not enabled or host==null or not is_instance_valid(host):return null
	var layer:=host.get_node_or_null(NODE_NAME) as Node3D
	if layer==null:
		layer=(load("res://scripts/map_ambience.gd") as GDScript).new()
		layer.name=NODE_NAME
		layer.set("terrain",host)
		host.add_child(layer)
	return layer

static func refresh(host:Node3D)->void:
	## Once per committed day.
	var layer:=ensure(host)
	if layer!=null:layer.call("day_tick")

## Let another map material follow the wind (see the header for uniforms).
static func bind_wind_material(material:ShaderMaterial)->void:
	if material==null:return
	for ref in _wind_materials:
		if ref.get_ref()==material:return
	_wind_materials.append(weakref(material))

# --------------------------------------------------------------------------
# Lifecycle
# --------------------------------------------------------------------------

func _ready()->void:
	_build_clouds()
	drops=_batch("Precipitation",_drop_quad(),drop_material(),MAX_DROPS,false)
	birds=_batch("Birds",_bird_mesh(),bird_material(),MAX_BIRDS,false)
	herd=_batch("Herd",_animal_mesh(),herd_material(),MAX_ANIMALS,true)
	boats=_batch("Boats",_boat_mesh(),boat_material(),MAX_BOATS,true)
	_seed_drops()
	day_tick()

func day_tick()->void:
	if terrain==null or not is_instance_valid(terrain):return
	_refresh_weather(true)
	_refresh_life()

func _home()->Vector3:
	if GameState.settlement_site_committed and GameState.settlement_founded_at!=Vector3.ZERO:return GameState.settlement_founded_at
	var marker:Node3D=terrain.get("settler_marker")
	return marker.position if marker else Vector3.ZERO

func _refresh_weather(force:bool=false)->void:
	var home:=_home()
	if climate.is_empty() or Vector2(home.x-climate_anchor.x,home.z-climate_anchor.z).length()>2.0:
		climate_anchor=home
		climate=PlanetEnvironment.profile_at(Vector2(home.x,home.z)) if PlanetEnvironment.has_method("profile_at") else {}
	var day:=float(GameState.elapsed_days)
	if not force and absf(day-weather_day)<0.05:return
	weather_day=day
	weather=MapWeather.state(int(GameState.world_seed),day,climate)
	if not forced_weather.is_empty():weather.merge(forced_weather,true)

# --------------------------------------------------------------------------
# Per frame: a few smoothed values and uniform writes
# --------------------------------------------------------------------------

func _process(delta:float)->void:
	if terrain==null or not is_instance_valid(terrain):return
	var began:=Time.get_ticks_usec()
	_frame(delta)
	frame_usec=lerpf(frame_usec,float(Time.get_ticks_usec()-began),0.05)

func _pace()->float:
	var hours:=float(terrain.call("_speed_hours_per_second")) if terrain.has_method("_speed_hours_per_second") else 12.0
	return clampf(sqrt(maxf(hours/24.0,0.01))*1.3,0.55,2.3)

func _frame(delta:float)->void:
	var paused:=float(terrain.get("game_speed"))<=0.0
	var reduced:=MapMotion.reduced()
	var dt:=0.0 if paused else delta*_pace()
	_refresh_weather()
	# Weather changes over a few seconds, never in one frame.
	var target_dir:Vector2=weather.get("wind_dir",wind_dir)
	wind_dir=wind_dir.slerp(target_dir,1.0-exp(-delta/3.0)).normalized() if wind_dir.length()>0.1 else target_dir
	wind=MapMotion.approach(wind,float(weather.get("wind",wind)),delta,3.0)
	cloud=MapMotion.approach(cloud,float(weather.get("cloud",cloud)),delta,4.0)
	rain=MapMotion.approach(rain,float(weather.get("rain",0.0)),delta,2.5)
	snow=MapMotion.approach(snow,float(weather.get("snow",0.0)),delta,2.5)
	clock+=dt
	var gust:=0.5+0.5*sin(clock*0.37)*sin(clock*0.11+1.3)
	wind_clock+=dt*(0.4+wind*(0.8+0.6*gust))
	if not reduced:
		cloud_drift+=wind_dir*wind*CLOUD_SPEED_KMH/3600.0*dt*8.0
		var period:=289.0*_cloud_scale()
		cloud_drift=Vector2(fposmod(cloud_drift.x,period),fposmod(cloud_drift.y,period))
	_push_wind(gust)
	var camera:Camera3D=terrain.get("camera")
	if camera==null:return
	var size:=camera.size
	var target:Vector3=terrain.get("camera_target") if terrain.get("camera_target") is Vector3 else Vector3.ZERO
	var home:=_home()
	var near_home:=Vector2(target.x-home.x,target.z-home.z).length()<maxf(3.0,size*2.0)
	# Cloud shadows: a full-screen pass, only while they can be seen.
	var cloud_fade:=1.0-smoothstep(CLOUD_FULL_BELOW,CLOUD_GONE_ABOVE,size)
	var shadow:=cloud_fade*clampf(cloud*1.15,0.0,1.0)
	cloud_mesh.visible=shadow>0.01
	if cloud_mesh.visible:
		_cloud_material.set_shader_parameter("drift",cloud_drift)
		_cloud_material.set_shader_parameter("ground_y",target.y)
		_cloud_material.set_shader_parameter("cover",clampf(cloud,0.0,0.9))
		_cloud_material.set_shader_parameter("strength",cloud_fade*smoothstep(0.02,0.25,cloud))
	# Rain or snow over the view.
	var fall:=maxf(rain,snow)
	var weather_fade:=1.0-smoothstep(WEATHER_MAX_VIEW*0.55,WEATHER_MAX_VIEW,size)
	drops.visible=not reduced and fall>0.02 and weather_fade>0.01
	if drops.visible:
		var count:=clampi(roundi(float(MAX_DROPS)*clampf(fall,0.0,1.0)),40,MAX_DROPS)
		if drops.multimesh.visible_instance_count!=count:drops.multimesh.visible_instance_count=count
		_drop_material.set_shader_parameter("clock",clock)
		_drop_material.set_shader_parameter("center",target)
		_drop_material.set_shader_parameter("box",size*1.7)
		_drop_material.set_shader_parameter("column",size*0.55)
		_drop_material.set_shader_parameter("wind",wind_dir*wind*(0.35 if snow>rain else 0.28))
		_drop_material.set_shader_parameter("snow",1.0 if snow>rain else 0.0)
		_drop_material.set_shader_parameter("intensity",weather_fade*clampf(0.35+fall*0.65,0.0,1.0))
		_drop_material.set_shader_parameter("streak",size*(0.006 if snow>rain else 0.022))
	# Wild life near home, at close heights only.
	var life:=size<=LIFE_MAX_VIEW and near_home
	var legible:=clampf(size/0.55,1.0,2.6)
	birds.visible=life and not reduced and birds.multimesh.visible_instance_count>0
	herd.visible=life and herd.multimesh.visible_instance_count>0
	boats.visible=life and boats.multimesh.visible_instance_count>0
	if birds.visible or herd.visible or boats.visible:
		for material in [_bird_material,_herd_material,_boat_material]:
			(material as ShaderMaterial).set_shader_parameter("clock",clock)
			if absf(legible-_legibility)>0.01:(material as ShaderMaterial).set_shader_parameter("legibility",legible)
		_legibility=legible

func _cloud_scale()->float:
	return 1.3

func _push_wind(gust:float)->void:
	var packed:=Vector4(wind_dir.x,wind_dir.y,wind,gust)
	var smoke:=preload("res://scripts/living_map.gd").smoke_material()
	# Hearth smoke leans downwind: a few metres on a still day, tens in a gale.
	smoke.set_shader_parameter("wind",wind_dir*(0.004+0.020*wind*(0.8+0.4*gust)))
	_rescan_wind_targets()
	for ref in _wind_targets:
		var material:=ref.get_ref() as ShaderMaterial
		if material==null:continue
		material.set_shader_parameter("map_wind",packed)
		material.set_shader_parameter("map_wind_clock",wind_clock)

## Materials that follow the wind, re-read only when a list changes size.
func _rescan_wind_targets()->void:
	var seasonal:Variant=terrain.get("seasonal_materials")
	var key:="%d|%d" % [_wind_materials.size(),(seasonal as Array).size() if seasonal is Array else -1]
	if key==_wind_scan_key:return
	_wind_scan_key=key
	_wind_targets.clear()
	var alive:Array[WeakRef]=[]
	for ref in _wind_materials:
		if ref.get_ref()!=null:alive.append(ref)
	_wind_materials=alive
	var lists:Array=[_wind_materials]
	if seasonal is Array:lists.append(seasonal)
	for list in lists:
		for ref in list:
			var material:=(ref as WeakRef).get_ref() as ShaderMaterial if ref is WeakRef else null
			if material==null or material.shader==null or not material.shader.code.contains("map_wind"):continue
			if not _wind_targets.any(func(existing:WeakRef)->bool:return existing.get_ref()==material):_wind_targets.append(weakref(material))
	_wind_scan_key="%d|%d" % [_wind_materials.size(),(seasonal as Array).size() if seasonal is Array else -1]

# --------------------------------------------------------------------------
# Life: birds, a herd and boats, placed once per site and season
# --------------------------------------------------------------------------

func _living()->Node:
	return terrain.get_node_or_null("LivingMap")

static func bird_flocks(season_warmth:float,has_water:bool,has_woods:bool)->int:
	## Fewer birds in the depth of winter; none where there is nowhere to go.
	var flocks:=int(has_water)+int(has_woods)+1
	if season_warmth< -0.45:flocks=mini(flocks,1)
	return clampi(flocks,0,MAX_FLOCKS)

static func herd_size(game:float,hunters:float)->int:
	## A herd appears where the land holds game; more of it where the people hunt.
	if game<0.25:return 0
	return clampi(roundi(2.0+game*3.0+minf(hunters,8.0)*0.25),0,ANIMALS_PER_HERD)

static func boat_count(fishers:float,fish_share:float)->int:
	if fishers<=0.0 or fish_share<=0.0:return 0
	return clampi(ceili(fishers/6.0),1,MAX_BOATS)

func _refresh_life()->void:
	var living:=_living()
	if living==null:return
	var anchor:Vector3=living.get("anchor")
	var spots:Dictionary=living.get("spots") if living.get("spots") is Dictionary else {}
	var settled:=bool(living.get("settled"))
	var shares:Dictionary=preload("res://scripts/living_map.gd").activity_shares()
	var warmth:=PlanetEnvironment.season_wave({"position":Vector2(anchor.x,anchor.z)},GameState.elapsed_days)
	var fish:Array=spots.get("fish",[])
	var water_site:=_water_site(anchor)
	var woods:Array=spots.get("gather",[])
	var game:=float(climate.get("game",0.4))
	var flocks:=bird_flocks(warmth,water_site!=Vector3.ZERO,not woods.is_empty()) if settled else 0
	var animals:=herd_size(game,float(shares.get("hunt",0.0))) if settled else 0
	var fishers:=float(shares.get("fish",0.0))
	var hulls:=boat_count(fishers,1.0 if fishers>0.0 else 0.0) if settled and water_site!=Vector3.ZERO else 0
	var signature:="%s|%d|%d|%d|%s" % [anchor,flocks,animals,hulls,water_site]
	last_report={"flocks":flocks,"birds":flocks*BIRDS_PER_FLOCK,"animals":animals,"boats":hulls,"cloud":cloud,"rain":rain,"snow":snow,"wind":wind}
	if signature==life_signature:return
	life_signature=signature
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("ambience|%d|%s" % [int(GameState.world_seed),anchor])
	for node in [birds,herd,boats]:(node as Node3D).position=anchor
	# Birds: one flock over the water, one over the woods, one over home.
	var centers:Array[Vector2]=[]
	if water_site!=Vector3.ZERO:centers.append(Vector2(water_site.x-anchor.x,water_site.z-anchor.z))
	if not woods.is_empty():centers.append(_v2(woods[0]))
	centers.append(Vector2(0.03,-0.02))
	var index:=0
	for f in flocks:
		var center:Vector2=centers[f%centers.size()]
		var ground:=float(living.call("_local_height",center)) if living.has_method("_local_height") else 0.0
		for b in BIRDS_PER_FLOCK:
			birds.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(center.x,ground+0.045+rng.randf()*0.03,center.y)))
			# phase along the circle, radius share, speed share, flap phase
			birds.multimesh.set_instance_custom_data(index,Color(float(f)*0.31+float(b)*0.035+rng.randf()*0.01,0.75+rng.randf()*0.5,0.9+rng.randf()*0.2,rng.randf()))
			index+=1
	birds.multimesh.visible_instance_count=index
	# The herd: on open ground beyond the fields (the hunters' ground).
	var grounds:Array=spots.get("hunt",[])
	if grounds.is_empty():grounds=spots.get("open",[])
	var animal_count:=animals if not grounds.is_empty() else 0
	var herd_center:=_v2(grounds[0]) if not grounds.is_empty() else Vector2.ZERO
	for a in animal_count:
		var at:=herd_center+Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*0.018
		var h:=float(living.call("_local_height",at)) if living.has_method("_local_height") else 0.0
		herd.multimesh.set_instance_transform(a,Transform3D(Basis(Vector3.UP,rng.randf()*TAU),Vector3(at.x,h,at.y)))
		herd.multimesh.set_instance_custom_data(a,Color(rng.randf(),rng.randf(),0,0))
		herd.multimesh.set_instance_color(a,Color(0.42,0.30,0.20).lerp(Color(0.52,0.40,0.28),rng.randf()))
	herd.multimesh.visible_instance_count=animal_count
	# Boats: on the channel nearest home, lying along the current.
	var placed:=0
	if hulls>0:
		var along:=_channel_tangent(water_site)
		for k in hulls:
			var offset:=along*(float(k)-float(hulls-1)*0.5)*0.035
			var at:=Vector2(water_site.x-anchor.x,water_site.z-anchor.z)+offset
			var yaw:=atan2(along.x,along.y)+rng.randf_range(-0.25,0.25)
			boats.multimesh.set_instance_transform(placed,Transform3D(Basis(Vector3.UP,yaw),Vector3(at.x,water_site.y-anchor.y-0.0025,at.y)))
			boats.multimesh.set_instance_custom_data(placed,Color(rng.randf(),rng.randf(),0,0))
			boats.multimesh.set_instance_color(placed,Color(0.33,0.23,0.15))
			placed+=1
	boats.multimesh.visible_instance_count=placed
	last_report["boats"]=placed
	last_report["animals"]=animal_count

var _water_cache_key:=""
var _water_cache:=Vector3.ZERO
func _water_site(anchor:Vector3)->Vector3:
	var key:="%s" % anchor
	if key==_water_cache_key:return _water_cache
	_water_cache_key=key
	_water_cache=Vector3.ZERO
	if terrain.has_method("_surface_water_site_near"):
		var site:Vector3=terrain.call("_surface_water_site_near",anchor)
		if site!=Vector3.ZERO and Vector2(site.x-anchor.x,site.z-anchor.z).length()<=0.6:_water_cache=site
	return _water_cache

func _channel_tangent(site:Vector3)->Vector2:
	## Along the river: perpendicular to the direction in which distance grows.
	if not terrain.has_method("_river_distance_at"):return Vector2(1,0)
	var e:=0.01
	var gx:=float(terrain.call("_river_distance_at",site.x+e,site.z))-float(terrain.call("_river_distance_at",site.x-e,site.z))
	var gz:=float(terrain.call("_river_distance_at",site.x,site.z+e))-float(terrain.call("_river_distance_at",site.x,site.z-e))
	var g:=Vector2(gx,gz)
	if g.length()<0.000001:return Vector2(1,0)
	return Vector2(-g.y,g.x).normalized()

func ambience_report()->Dictionary:
	var report:=last_report.duplicate()
	report["frame_usec"]=snappedf(frame_usec,0.1)
	report["cloud_visible"]=cloud_mesh.visible if cloud_mesh else false
	report["drops_visible"]=drops.visible if drops else false
	report["drops"]=drops.multimesh.visible_instance_count if drops else 0
	report["weather"]=weather.duplicate()
	return report

static func _v2(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Vector3:return Vector2((value as Vector3).x,(value as Vector3).z)
	return Vector2.ZERO

# --------------------------------------------------------------------------
# Construction
# --------------------------------------------------------------------------

func _batch(label:String,mesh:Mesh,material:Material,count:int,colors:bool)->MultiMeshInstance3D:
	var multimesh:=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data=true
	multimesh.use_colors=colors
	multimesh.mesh=mesh
	multimesh.instance_count=count
	multimesh.visible_instance_count=0
	var node:=MultiMeshInstance3D.new();node.name=label
	node.multimesh=multimesh;node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb=AABB(Vector3(-0.8,-0.2,-0.8),Vector3(1.6,0.6,1.6))
	node.visible=false
	add_child(node)
	return node

func _build_clouds()->void:
	var quad:=QuadMesh.new();quad.size=Vector2(2,2)
	cloud_mesh=MeshInstance3D.new();cloud_mesh.name="CloudShadows"
	cloud_mesh.mesh=quad
	_cloud_material=ShaderMaterial.new()
	var shader:=Shader.new();shader.code=CLOUD_SHADER
	_cloud_material.shader=shader
	_cloud_material.set_shader_parameter("scale_km",_cloud_scale())
	cloud_mesh.material_override=_cloud_material
	cloud_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A screen pass: never frustum culled.
	cloud_mesh.custom_aabb=AABB(Vector3(-40000,-100,-40000),Vector3(80000,200,80000))
	cloud_mesh.visible=false
	add_child(cloud_mesh)

func _seed_drops()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=7717
	var mm:=drops.multimesh
	for i in MAX_DROPS:
		mm.set_instance_transform(i,Transform3D.IDENTITY)
		mm.set_instance_custom_data(i,Color(rng.randf(),rng.randf(),rng.randf(),rng.randf()))
	# Drops are placed in the shader around the view: never culled.
	drops.custom_aabb=AABB(Vector3(-40000,-100,-40000),Vector3(80000,200,80000))

func drop_material()->ShaderMaterial:
	if _drop_material:return _drop_material
	_drop_material=_material(DROP_SHADER)
	return _drop_material

func bird_material()->ShaderMaterial:
	if _bird_material:return _bird_material
	_bird_material=_material(BIRD_SHADER)
	return _bird_material

func herd_material()->ShaderMaterial:
	if _herd_material:return _herd_material
	_herd_material=_material(HERD_SHADER)
	return _herd_material

func boat_material()->ShaderMaterial:
	if _boat_material:return _boat_material
	_boat_material=_material(BOAT_SHADER)
	return _boat_material

static func _material(code:String)->ShaderMaterial:
	var shader:=Shader.new();shader.code=code
	var material:=ShaderMaterial.new();material.shader=shader
	return material

static func _drop_quad()->Mesh:
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	return quad

static func _bird_mesh()->ArrayMesh:
	## A gull-wing chevron in metres, nose toward +Z. UV.x is the distance
	## from the body (the shader lifts the wingtips).
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nose:=Vector3(0,0,0.28);var tail:=Vector3(0,0,-0.18)
	var left_elbow:=Vector3(-0.42,0.05,0.02);var right_elbow:=Vector3(0.42,0.05,0.02)
	var left_tip:=Vector3(-1.0,0,-0.24);var right_tip:=Vector3(1.0,0,-0.24)
	for tri in [[nose,left_elbow,tail],[left_elbow,left_tip,tail],[nose,tail,right_elbow],[right_elbow,tail,right_tip]]:
		for v:Vector3 in tri:
			st.set_uv(Vector2(absf(v.x),0));st.set_normal(Vector3.UP);st.add_vertex(v)
	return st.commit()

static func _box(st:SurfaceTool,center:Vector3,size:Vector3,part:int)->void:
	var h:=size*0.5
	var c:=[Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3(-h.x,-h.y,h.z),
		Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]
	for face in [[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]:
		for index in [0,2,1,0,3,2]:
			st.set_uv(Vector2(float(part),0));st.add_vertex(center+(c[face[index]] as Vector3))

static func _animal_mesh()->ArrayMesh:
	## A grazing beast in metres, facing +Z: 0 body, 1 neck and head, 2/3 the
	## diagonal leg pairs (a walking gait swings them in opposition).
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(st,Vector3(0,0.95,0),Vector3(0.42,0.44,1.25),0)
	_box(st,Vector3(0,1.20,0.70),Vector3(0.16,0.42,0.18),1)
	_box(st,Vector3(0,1.38,0.86),Vector3(0.18,0.20,0.36),1)
	_box(st,Vector3(-0.14,0.38,0.48),Vector3(0.09,0.76,0.09),2)
	_box(st,Vector3(0.14,0.38,-0.48),Vector3(0.09,0.76,0.09),2)
	_box(st,Vector3(0.14,0.38,0.48),Vector3(0.09,0.76,0.09),3)
	_box(st,Vector3(-0.14,0.38,-0.48),Vector3(0.09,0.76,0.09),3)
	st.generate_normals()
	return st.commit()

static func _boat_mesh()->ArrayMesh:
	## A dugout with one paddler, in metres, bow toward +Z: 0 hull, 1 paddler.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(st,Vector3(0,0.18,0),Vector3(0.7,0.36,4.2),0)
	_box(st,Vector3(0,0.20,2.3),Vector3(0.36,0.30,0.5),0)
	_box(st,Vector3(0,0.20,-2.3),Vector3(0.36,0.30,0.5),0)
	_box(st,Vector3(0,0.70,-0.6),Vector3(0.34,0.70,0.26),1)
	_box(st,Vector3(0,1.18,-0.6),Vector3(0.20,0.22,0.20),1)
	st.generate_normals()
	return st.commit()

# --------------------------------------------------------------------------
# Shaders
# --------------------------------------------------------------------------

## Soft cloud shadows over whatever is drawn. The Compatibility renderer
## offers no depth texture here, so each pixel's view ray meets a level plane
## at the ground height of the view's centre: at map heights relief shifts a
## shadow by at most a few pixels, and it stays fixed to the ground as the
## camera pans.
const CLOUD_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;
uniform vec2 drift = vec2(0.0);
uniform float cover = 0.35;
uniform float strength = 0.0;
uniform float scale_km = 2.4;
uniform float ground_y = 0.0;
uniform vec3 shade = vec3(0.64, 0.67, 0.76);

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}
float h21(vec2 p) {
	p = mod(p, 289.0);
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), u.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 xy = SCREEN_UV * 2.0 - 1.0;
	// Any point on the pixel's ray (depth conventions differ by renderer);
	// the ray starts at the camera and must point into the view (-Z).
	vec4 p_view = INV_PROJECTION_MATRIX * vec4(xy, 0.5, 1.0);
	vec3 ray = normalize(p_view.xyz / p_view.w);
	if (ray.z > 0.0) { ray = -ray; }
	vec3 origin = INV_VIEW_MATRIX[3].xyz;
	vec3 dir = normalize((INV_VIEW_MATRIX * vec4(ray, 0.0)).xyz);
	float hit = dir.y < -0.0001 ? (ground_y - origin.y) / dir.y : -1.0;
	vec2 world = origin.xz + dir.xz * max(hit, 0.0);
	vec2 p = (world - drift) / scale_km;
	float n = vnoise(p) * 0.55 + vnoise(p * 2.0 + 17.0) * 0.28 + vnoise(p * 4.0 + 41.0) * 0.12 + vnoise(p * 8.0 + 73.0) * 0.05;
	float edge = 1.0 - cover;
	float c = smoothstep(edge - 0.10, edge + 0.16, n) * step(0.0, hit);
	ALBEDO = mix(vec3(1.0), shade, c * strength * 0.9);
}
"""

## Rain streaks or snowflakes, placed and animated entirely here. Drops are
## anchored to the world (wrapped in a box around the view), so panning does
## not drag the weather along with the camera.
const DROP_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;
uniform float clock = 0.0;
uniform vec3 center = vec3(0.0);
uniform float box = 3.0;
uniform float column = 1.0;
uniform vec2 wind = vec2(0.0);
uniform float snow = 0.0;
uniform float intensity = 0.0;
uniform float streak = 0.05;
varying float v_alpha;
varying vec2 v_uv;
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float speed = mix(0.55, 0.11, snow) * mix(0.85, 1.15, r.z);
	float fall = fract(r.y + clock * speed);
	vec2 low = center.xz - vec2(box * 0.5);
	vec2 at = low + mod(r.xz * box * vec2(1.0, 1.0) + vec2(r.w, r.x) * box * 0.37 - low, vec2(box));
	at += wind * column * fall;
	at += snow * vec2(sin(clock * 1.3 + r.z * 19.0), cos(clock * 1.1 + r.w * 23.0)) * streak * 1.4;
	float y = center.y + column * (1.0 - fall);
	vec2 edge = abs(at - center.xz) / (box * 0.5);
	float fade = (1.0 - smoothstep(0.55, 1.0, max(edge.x, edge.y))) * smoothstep(0.0, 0.12, fall) * (1.0 - smoothstep(0.85, 1.0, fall));
	vec3 view = (VIEW_MATRIX * vec4(at.x, y, at.y, 1.0)).xyz;
	vec3 axis = normalize((VIEW_MATRIX * vec4(wind.x, -1.0, wind.y, 0.0)).xyz);
	vec3 side = normalize(cross(axis, vec3(0.0, 0.0, 1.0)) + vec3(1e-5, 0.0, 0.0));
	if (snow > 0.5) {
		VERTEX = view + vec3(VERTEX.xy * streak, 0.0);
	} else {
		VERTEX = view + axis * VERTEX.y * streak + side * VERTEX.x * streak * 0.035;
	}
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_alpha = fade * intensity;
	v_uv = UV;
}
void fragment() {
	vec2 q = v_uv * 2.0 - 1.0;
	float shape = snow > 0.5 ? 1.0 - smoothstep(0.35, 1.0, length(q)) : (1.0 - abs(q.x)) * (1.0 - smoothstep(0.6, 1.0, abs(q.y)));
	ALBEDO = snow > 0.5 ? vec3(0.97, 0.97, 0.99) : vec3(0.78, 0.82, 0.86);
	ALPHA = shape * v_alpha * (snow > 0.5 ? 0.85 : 0.30);
}
"""

## Birds wheeling in loose circles, flapping and gliding.
const BIRD_SHADER:="""
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform float clock = 0.0;
uniform float legibility = 1.0;
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float radius = 0.05 * r.y;
	float t = clock * 0.23 * r.z + r.x * 6.2831;
	vec3 at = vec3(cos(t) * radius, 0.0, sin(t) * radius * 0.72);
	at.x += sin(t * 2.3 + r.w * 9.0) * radius * 0.16;
	at.y += sin(t * 1.7 + r.w * 5.0) * 0.004;
	vec2 heading = normalize(vec2(-sin(t), cos(t) * 0.72));
	// Flap in bursts, then glide.
	float burst = step(0.1, sin(clock * 0.9 + r.w * 11.0));
	float flap = sin(clock * 16.0 + r.w * 40.0) * burst;
	vec3 v = VERTEX;
	v.y += UV.x * UV.x * (0.55 * flap + 0.12);
	float span = 4.0 * 0.001 * legibility;
	float c = heading.y; float s = heading.x;
	v = vec3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
	VERTEX = at + v * span;
}
void fragment() {
	ALBEDO = vec3(0.21, 0.18, 0.15);
}
"""

## A grazing herd: heads down most of the time, drifting slowly across the
## ground, legs swinging when an animal walks on.
const HERD_SHADER:="""
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float clock = 0.0;
uniform float legibility = 1.0;
varying vec3 v_color;
mat3 rot_x(float a) { float c = cos(a); float s = sin(a); return mat3(vec3(1.0,0.0,0.0), vec3(0.0,c,s), vec3(0.0,-s,c)); }
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float t = clock * 0.06 + r.x * 6.2831;
	// Wander a few metres, facing the way it goes.
	vec2 path = vec2(sin(t) + 0.4 * sin(t * 2.7 + r.y * 7.0), cos(t * 0.8 + r.y * 3.0)) * 0.006;
	vec2 step_dir = vec2(cos(t) + 1.08 * cos(t * 2.7 + r.y * 7.0), -0.8 * sin(t * 0.8 + r.y * 3.0));
	float walking = smoothstep(0.35, 0.8, sin(clock * 0.21 + r.y * 12.0));
	float yaw = atan(step_dir.x, step_dir.y);
	float part = floor(UV.x + 0.5);
	vec3 v = VERTEX;
	if (part > 1.5) {
		float swing = sin(clock * 6.0 + r.x * 20.0) * 0.45 * walking * (part > 2.5 ? -1.0 : 1.0);
		vec3 hip = vec3(v.x, 0.76, v.z > 0.0 ? 0.48 : -0.48);
		v = rot_x(swing) * (v - hip) + hip;
	}
	if (part > 0.5 && part < 1.5) {
		// Graze: the head goes down to the grass and nods.
		float down = (1.0 - walking) * (1.05 + 0.12 * sin(clock * 2.2 + r.x * 30.0));
		vec3 neck = vec3(0.0, 1.05, 0.58);
		v = rot_x(down) * (v - neck) + neck;
	}
	float c = cos(yaw); float s = sin(yaw);
	v = vec3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
	float scale = 0.001 * 1.6 * legibility;
	VERTEX = vec3(path.x, 0.0, path.y) * mix(0.35, 1.0, walking) + v * scale;
	v_color = COLOR.rgb * (part > 0.5 && part < 1.5 ? 0.85 : 1.0);
}
void fragment() {
	ALBEDO = v_color;
	ROUGHNESS = 0.95;
}
"""

## Boats riding the water: a gentle bob and roll, working slowly along the
## channel and back, a paddler's stroke.
const BOAT_SHADER:="""
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float clock = 0.0;
uniform float legibility = 1.0;
varying vec3 v_color;
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float t = clock * 0.05 + r.x * 6.2831;
	float along = sin(t) * 0.018;
	float part = floor(UV.x + 0.5);
	vec3 v = VERTEX;
	float roll = sin(clock * 1.7 + r.y * 9.0) * 0.06;
	v = vec3(v.x * cos(roll) - v.y * sin(roll), v.x * sin(roll) + v.y * cos(roll), v.z);
	if (part > 0.5) { v.x += sin(clock * 2.6 + r.y * 4.0) * 0.08 * step(1.0, v.y); }
	float scale = 0.001 * 1.6 * legibility;
	VERTEX = vec3(0.0, sin(clock * 1.2 + r.x * 11.0) * 0.0002, along) + v * scale;
	v_color = part > 0.5 ? vec3(0.46, 0.36, 0.26) : COLOR.rgb;
}
void fragment() {
	ALBEDO = v_color;
	ROUGHNESS = 0.9;
}
"""
