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
const Ink:=preload("res://scripts/map_life_ink.gd")
const NODE_NAME:="MapAmbience"
const UNIT:=0.001                 ## one metre in map units (km)
const MAX_BIRDS:=21
const BIRDS_PER_FLOCK:=7
const MAX_ANIMALS:=12
const ANIMALS_PER_HERD:=6
const MAX_FLOCKS:=3
const MAX_BUILDERS:=12
const BUILDERS_PER_WORK:=4
const BUILDER_MAX_VIEW:=2.2       ## the living map's figure band
const MAX_BOATS:=3
const MAX_DROPS:=1400
const CLOUD_FULL_BELOW:=6.0       ## camera.size (km): full cloud shadow at and below
const CLOUD_GONE_ABOVE:=24.0      ## gone before the chart takes over (map_chart.gdshaderinc)
const WEATHER_MAX_VIEW:=7.0       ## rain and snow drawn at and below this view
const LIFE_MAX_VIEW:=4.0          ## birds, herds and boats
const CLOUD_SPEED_KMH:=60.0       ## time-lapsed drift at full wind (real: 20-60 km/h): slow, secondary

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
## Cloud drift for shadows drawn on the land itself (map_cloud.gdshaderinc):
## its noise does not tile, so it wraps only once every 40,000 km.
var cloud_drift_land:=Vector2.ZERO
var cloud_mesh:MeshInstance3D
var drops:MultiMeshInstance3D
var birds:MultiMeshInstance3D
var herd:MultiMeshInstance3D
var boats:MultiMeshInstance3D
var builders:MultiMeshInstance3D
var builder_signature:=""
var builder_sites:Array[Vector3]=[]
var life_signature:=""
var frame_usec:=0.0
var last_report:Dictionary={}
var _cloud_material:ShaderMaterial
var _legibility:=-1.0
var _wind_targets:Array[WeakRef]=[]
var _cloud_targets:Array[WeakRef]=[]
var _land_clouds:=false            ## the land itself (terrain) draws cloud shadows
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
	# Trees in the round wherever the camera goes (codex/beauty-2), added
	# beside this layer once the map has finished adding it.
	if terrain!=null:(func()->void:preload("res://scripts/close_woods.gd").ensure(terrain)).call_deferred()
	_build_clouds()
	drops=_batch("Precipitation",_drop_quad(),drop_material(),MAX_DROPS,false)
	# Birds, beasts and boats are drawn in ink on one quad each
	# (scripts/map_life_ink.gd), animated in their shaders.
	birds=_batch("Birds",Ink.quad(),bird_material(),MAX_BIRDS,true)
	herd=_batch("Herd",Ink.quad(),herd_material(),MAX_ANIMALS,true)
	boats=_batch("Boats",Ink.quad(),boat_material(),MAX_BOATS,true)
	# Builders at rising great works share the living map's people.
	var living_script:=preload("res://scripts/living_map.gd")
	builders=_batch("GreatWorkBuilders",living_script.figure_mesh(),living_script.figure_material(),MAX_BUILDERS,true)
	# Placed in world coordinates at any work: shown only near one, never culled.
	builders.custom_aabb=AABB(Vector3(-40000,-100,-40000),Vector3(80000,200,80000))
	_seed_drops()
	day_tick()

func day_tick()->void:
	if terrain==null or not is_instance_valid(terrain):return
	_refresh_weather(true)
	_refresh_life()
	_refresh_builders()

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
	var camera:Camera3D=terrain.get("camera")
	if camera==null:return
	var size:=camera.size
	if size>CLOUD_GONE_ABOVE and _wind_targets.is_empty() and _wind_materials.is_empty():
		# Over the regional chart nothing here can be seen: keep the clocks
		# running and do nothing else.
		clock+=dt
		if cloud_mesh.visible or drops.visible or birds.visible or herd.visible or boats.visible or builders.visible:
			for node in [cloud_mesh,drops,birds,herd,boats,builders]:(node as Node3D).visible=false
		return
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
		cloud_drift_land+=wind_dir*wind*CLOUD_SPEED_KMH/3600.0*dt*8.0
		cloud_drift=Vector2(fposmod(cloud_drift.x,period),fposmod(cloud_drift.y,period))
		cloud_drift_land=Vector2(fposmod(cloud_drift_land.x,40000.0),fposmod(cloud_drift_land.y,40000.0))
	_push_wind(gust)
	var target:Vector3=terrain.get("camera_target") if terrain.get("camera_target") is Vector3 else Vector3.ZERO
	var home:=_home()
	var near_home:=Vector2(target.x-home.x,target.z-home.z).length()<maxf(3.0,size*2.0)
	# Cloud shadows: a full-screen pass, only while they can be seen.
	var cloud_fade:=1.0-smoothstep(CLOUD_FULL_BELOW,CLOUD_GONE_ABOVE,size)
	var shadow:=cloud_fade*clampf(cloud*1.15,0.0,1.0)
	# Materials that draw cloud shadows on the land itself take them over from
	# the flat screen pass, which cannot follow relief.
	var land_clouds:=_land_clouds
	var cloud_packed:=Vector4(cloud_drift_land.x,cloud_drift_land.y,clampf(cloud,0.0,0.9),cloud_fade*smoothstep(0.02,0.25,cloud))
	for ref in _cloud_targets:
		var material:=ref.get_ref() as ShaderMaterial
		if material==null:continue
		material.set_shader_parameter("map_cloud",cloud_packed)
		material.set_shader_parameter("map_cloud_scale",_cloud_scale())
	cloud_mesh.visible=shadow>0.01 and not land_clouds
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
	builders.visible=size<=BUILDER_MAX_VIEW and builders.multimesh.visible_instance_count>0 and _near_any(builder_sites,target,maxf(2.0,size*2.0))
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
	_cloud_targets.clear()
	_land_clouds=false
	var alive:Array[WeakRef]=[]
	for ref in _wind_materials:
		if ref.get_ref()!=null:alive.append(ref)
	_wind_materials=alive
	var lists:Array=[_wind_materials]
	if seasonal is Array:lists.append(seasonal)
	for list_index in lists.size():
		var list:Array=lists[list_index]
		for ref in list:
			var material:=(ref as WeakRef).get_ref() as ShaderMaterial if ref is WeakRef else null
			if material==null or material.shader==null or not material.shader.code.contains("map_wind"):continue
			if not _wind_targets.any(func(existing:WeakRef)->bool:return existing.get_ref()==material):
				_wind_targets.append(weakref(material))
				if material.shader.code.contains("map_cloud"):
					_cloud_targets.append(weakref(material))
					# Only the map's own seasonal materials (the land) replace the
					# screen pass; a bound building material alone does not.
					if list_index>0:_land_clouds=true
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
		# Gulls over the water are pale, rooks over the woods dark, the small
		# birds about home a warm brown.
		var over_water:=water_site!=Vector3.ZERO and f%centers.size()==0
		var over_woods:=not woods.is_empty() and center==_v2(woods[0])
		var plumage:=Color(0.90,0.88,0.82) if over_water else (Color(0.26,0.24,0.22) if over_woods else Color(0.56,0.46,0.36))
		var ground:=float(living.call("_local_height",center)) if living.has_method("_local_height") else 0.0
		for b in BIRDS_PER_FLOCK:
			birds.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(center.x,ground+0.045+rng.randf()*0.03,center.y)))
			# phase along the circle, radius share, speed share, flap phase
			birds.multimesh.set_instance_custom_data(index,Color(float(f)*0.31+float(b)*0.035+rng.randf()*0.01,0.75+rng.randf()*0.5,0.9+rng.randf()*0.2,rng.randf()))
			birds.multimesh.set_instance_color(index,plumage)
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
	_refresh_landing(anchor,water_site if settled else Vector3.ZERO,hulls)
	last_report["animals"]=animal_count

## The landing place at the water's edge (codex/beauty-5): where the people
## fish, their boats lie hauled up on the bank, bows to the water; a fish
## weir stands in the stream once weirs are known; a plank landing stage,
## then a stone quay, once landings are built. One mesh, rebuilt only when
## the site or what is known changes (with the rest of the life here).
var landing:MeshInstance3D
func _refresh_landing(anchor:Vector3,water_site:Vector3,hulls:int)->void:
	if landing==null:
		landing=MeshInstance3D.new();landing.name="LandingPlace"
		landing.material_override=preload("res://scripts/settlement_ink.gd").material()
		add_child(landing)
	landing.mesh=null
	if water_site==Vector3.ZERO or terrain==null or not terrain.has_method("_river_distance_at"):return
	var known:Dictionary=preload("res://scripts/early_settlement_ground.gd").known_crafts()
	var boats_here:=hulls
	if boats_here<=0 and not (bool(known.weirs) or bool(known.landing)):return
	var site:=Vector2(water_site.x,water_site.z)
	var inland:=Vector2(anchor.x,anchor.z)-site
	if inland.length()<0.001:inland=Vector2(0,-1)
	inland=inland.normalized()
	var bank:=Vector2.INF
	for step in 80:
		var p:=site+inland*float(step)*0.004
		if float(terrain.call("_river_distance_at",p.x,p.y))>0.014 and float(terrain.call("_height_at",p.x,p.y))>0.015:
			bank=p;break
	if bank==Vector2.INF:return
	var along:=_channel_tangent(water_site)
	var out:=-inland
	var shapes:=preload("res://scripts/settlement_kit_shapes.gd")
	var surface:=SurfaceTool.new()
	var placed:=[0]
	var put:=func(name:String,at:Vector2,forward:Vector2,y:float)->void:
		var mesh:ArrayMesh=shapes.prop(name)
		if mesh==null:return
		var basis:=Basis(Vector3.UP,atan2(forward.x,forward.y)).scaled(Vector3.ONE*0.001)
		surface.append_from(mesh,0,Transform3D(basis,Vector3(at.x-anchor.x,y-anchor.y,at.y-anchor.z)))
		placed[0]+=1
	var hull:="coracle" if bool(known.hide_boats) and not bool(known.landing) else "dugout"
	for k in mini(maxi(boats_here,1 if bool(known.landing) else 0),3):
		var at:=bank+along*(float(k)-1.0)*0.0034-out*0.0026
		put.call(hull,at,out.rotated(0.18*float(k-1)),float(terrain.call("_height_at",at.x,at.y))+0.00005)
	if bool(known.landing):
		var name:="quay" if bool(known.quay) else "jetty"
		var at:=bank+along*0.0075-out*(0.0005 if name=="jetty" else 0.0008)
		put.call(name,at,out,float(terrain.call("_height_at",at.x,at.y)))
	if bool(known.weirs):
		var at:=bank+out*0.009+along*0.028
		put.call("weir",at,along,water_site.y-0.0035)
	landing.position=anchor
	if int(placed[0])>0:landing.mesh=surface.commit()

var _water_cache_key:=""
var _water_cache:=Vector3.ZERO
func _water_site(anchor:Vector3)->Vector3:
	var key:="%s" % anchor
	if key==_water_cache_key:return _water_cache
	_water_cache_key=key
	_water_cache=Vector3.ZERO
	if terrain.has_method("_surface_water_site_near"):
		var site:Vector3=terrain.call("_surface_water_site_near",anchor)
		if site!=Vector3.ZERO and Vector2(site.x-anchor.x,site.z-anchor.z).length()<=0.6 and _open_water(site):_water_cache=site
	return _water_cache

## Water that shows on the map (codex/beauty-5): a river, a tributary or the
## sea. A dry swale the ground only tints is no place for boats or a landing.
func _open_water(site:Vector3)->bool:
	var p:=Vector2(site.x,site.z)
	if terrain.has_method("_main_river_distance_at") and float(terrain.call("_main_river_distance_at",p.x,p.y))<0.25:return true
	if terrain.has_method("_nearest_tributary_distance_at") and float(terrain.call("_nearest_tributary_distance_at",p))<0.12:return true
	if terrain.has_method("_height_at"):
		for k in 12:
			var q:=p+Vector2.from_angle(TAU*float(k)/12.0)*0.04
			if float(terrain.call("_height_at",q.x,q.y))<=0.0:return true
	return not terrain.has_method("_main_river_distance_at")

func _channel_tangent(site:Vector3)->Vector2:
	## Along the river: perpendicular to the direction in which distance grows.
	if not terrain.has_method("_river_distance_at"):return Vector2(1,0)
	var e:=0.01
	var gx:=float(terrain.call("_river_distance_at",site.x+e,site.z))-float(terrain.call("_river_distance_at",site.x-e,site.z))
	var gz:=float(terrain.call("_river_distance_at",site.x,site.z+e))-float(terrain.call("_river_distance_at",site.x,site.z-e))
	var g:=Vector2(gx,gz)
	if g.length()<0.000001:return Vector2(1,0)
	return Vector2(-g.y,g.x).normalized()

static func _near_any(points:Array[Vector3],target:Vector3,reach:float)->bool:
	for point in points:
		if Vector2(point.x-target.x,point.z-target.z).length()<=reach:return true
	return false

## People at work around each rising great work: a few hammering at the
## courses, one bent to the stone heap. Bounded; re-read once a day.
func _refresh_builders()->void:
	var root:Node=terrain.get("undertaking_visual_root") if "undertaking_visual_root" in terrain else null
	var sites:Array[Dictionary]=[]
	if is_instance_valid(root):
		for child in root.get_children():
			if not child.has_meta("map_mark"):continue
			var mark:Dictionary=child.get_meta("map_mark")
			if String(mark.get("state",""))!="building":continue
			sites.append({"at":(child as Node3D).position,"radius":float(mark.get("radius",0.015)),"top":float(mark.get("plinth_top",NAN)),
				"plinth":mark.get("plinth",Rect2()),"angle":float(mark.get("angle",0.0))})
			if sites.size()*BUILDERS_PER_WORK>=MAX_BUILDERS:break
	var signature:=str(sites)
	if signature==builder_signature:return
	builder_signature=signature
	builder_sites.clear()
	builders.position=Vector3.ZERO
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("builders|%s" % signature)
	var index:=0
	var cloth:Array=preload("res://scripts/living_map.gd").CLOTH
	for site in sites:
		var at:Vector3=site.at
		builder_sites.append(at)
		# On the dressed plinth, between the scaffold and its edge, where the
		# work is done: the plinth's own level (undertaking_map_visual map mark).
		var plinth:Rect2=site.plinth
		if not plinth.has_area():plinth=Rect2(-Vector2.ONE*float(site.radius)*0.7,Vector2.ONE*float(site.radius)*1.4)
		var inner:=plinth.grow(-minf(plinth.size.x,plinth.size.y)*0.12)
		for k in BUILDERS_PER_WORK:
			# Along the plinth's inner edge: two on the near sides, one at a
			# corner by the heap, one opposite (local x/z, then turned).
			var u:float=[0.25,0.75,0.85,0.4][k%4]
			var side:=k%4
			var local:=Vector2(lerpf(inner.position.x,inner.end.x,u),inner.position.y if side%2==0 else inner.end.y)
			if side>=2:local=Vector2(inner.position.x if side==3 else inner.end.x,lerpf(inner.position.y,inner.end.y,u))
			# Same turn as the landmark (Vector3.rotated(UP,-angle) on x/z).
			var turned:=local.rotated(float(site.angle))
			var spot:=Vector2(at.x,at.z)+turned
			var level:=float(site.top) if is_finite(float(site.top)) else at.y+0.0012
			var facing:=Vector3(at.x-spot.x,0,at.z-spot.y).normalized()
			var basis:=Basis.looking_at(facing,Vector3.UP).scaled(Vector3.ONE*UNIT*1.6)
			builders.multimesh.set_instance_transform(index,Transform3D(basis,Vector3(spot.x,level+0.00005,spot.y)))
			# The living map's poses: 2 hammering/chopping, 1 bent to lift.
			var pose:=1 if k==BUILDERS_PER_WORK-1 else 2
			builders.multimesh.set_instance_custom_data(index,Color(rng.randf(),float(pose),0.0,1.0))
			builders.multimesh.set_instance_color(index,cloth[rng.randi_range(0,cloth.size()-1)])
			index+=1
	builders.multimesh.visible_instance_count=index
	last_report["builders"]=index

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
	_bird_material=_ink_material("bird",16.0)
	return _bird_material

func herd_material()->ShaderMaterial:
	if _herd_material:return _herd_material
	_herd_material=_ink_material("beast",15.0)
	return _herd_material

func boat_material()->ShaderMaterial:
	if _boat_material:return _boat_material
	_boat_material=_ink_material("boat",24.0)
	return _boat_material

## Each layer gets its own copy of the ink shader's material (its own clock).
static func _ink_material(kind:String,min_px:float)->ShaderMaterial:
	var material:=Ink.material(kind).duplicate() as ShaderMaterial
	material.set_shader_parameter("min_px",min_px)
	return material

static func _material(code:String)->ShaderMaterial:
	var shader:=Shader.new();shader.code=code
	var material:=ShaderMaterial.new();material.shader=shader
	return material

static func _drop_quad()->Mesh:
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	return quad

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
uniform vec3 shade = vec3(0.78, 0.80, 0.87);

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
		VERTEX = view + vec3(VERTEX.xy * streak * (0.6 + 0.8 * r.w), 0.0);
	} else {
		VERTEX = view + axis * VERTEX.y * streak + side * VERTEX.x * streak * 0.06;
	}
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_alpha = fade * intensity;
	v_uv = UV;
}
void fragment() {
	vec2 q = v_uv * 2.0 - 1.0;
	float shape = snow > 0.5 ? 1.0 - smoothstep(0.35, 1.0, length(q)) : (1.0 - abs(q.x)) * (1.0 - smoothstep(0.6, 1.0, abs(q.y)));
	ALBEDO = snow > 0.5 ? vec3(0.97, 0.97, 0.99) : vec3(0.78, 0.82, 0.86);
	ALPHA = shape * v_alpha * (snow > 0.5 ? 0.8 : 0.34);
}
"""
