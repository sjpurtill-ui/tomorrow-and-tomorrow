extends GdUnitTestSuite
## The map's weather and wild life (codex/map-motion): a deterministic sky
## from the home climate, bounded representatives, no per-frame rebuilds, and
## reduced motion stilling the weather and the birds.
const MapWeather:=preload("res://scripts/map_weather.gd")
const Ambience:=preload("res://scripts/map_ambience.gd")
const Living:=preload("res://scripts/living_map.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

const WET:={"precipitation":0.9,"mean_temperature_c":12.0,"seasonality_c":8.0,"position":Vector2(0,-500)}
const DRY:={"precipitation":0.1,"mean_temperature_c":20.0,"seasonality_c":10.0,"position":Vector2(0,-500)}
const COLD:={"precipitation":0.7,"mean_temperature_c":-2.0,"seasonality_c":14.0,"position":Vector2(0,-2500)}

class Host extends Node3D:
	var settler_marker:=Node3D.new()
	var camera:=Camera3D.new()
	var camera_target:=Vector3.ZERO
	var game_speed:=4.0
	var travel_active:=false
	var seasonal_materials:Array[WeakRef]=[]
	func _init()->void:
		add_child(settler_marker)
		add_child(camera)
		camera.size=1.0
	func _height_at(_x:float,_z:float)->float:return 0.1
	func _speed_hours_per_second()->float:return 24.0

func before_test()->void:
	GameState.reset_for_new_world(4242)
	GameState.population_total=120
	GameState.population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":5,"Logistics":5,"Knowledge":4,"Administration":3,"Defense":3}
	GameState.simulation_metrics["food_sources"]=[{"name":"Wild gathering","produced":40.0},{"name":"Hunting","produced":30.0},{"name":"Fishing","produced":30.0}]
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3(12.0,0.1,-8.0)
	GameState.hearth_season={"start_day":0,"born":0,"buried":0}

func after_test()->void:
	Motion.reduce_motion=false
	Ambience.forced_weather={}

func _share(climate:Dictionary,key:String,threshold:float)->float:
	var hits:=0
	for day in 730:
		if float(MapWeather.state(77,float(day)+0.5,climate)[key])>threshold:hits+=1
	return float(hits)/730.0

func test_weather_is_deterministic()->void:
	var a:=MapWeather.state(123,40.25,WET)
	var b:=MapWeather.state(123,40.25,WET)
	assert_dict(a).is_equal(b)
	assert_bool(MapWeather.state(124,40.25,WET)==a).is_false()

func test_weather_changes_gradually()->void:
	# Hour to hour the sky never flips: fronts pass over days.
	var previous:=MapWeather.state(9,0.0,WET)
	for hour in range(1,24*120):
		var now:=MapWeather.state(9,float(hour)/24.0,WET)
		assert_float(absf(float(now.cloud)-float(previous.cloud))).is_less(0.08)
		assert_float(absf(float(now.rain)+float(now.snow)-float(previous.rain)-float(previous.snow))).is_less(0.12)
		assert_float((now.wind_dir as Vector2).angle_to(previous.wind_dir)).is_less(0.05)
		previous=now

func test_wet_climates_are_cloudier_and_rainier_than_dry()->void:
	assert_float(_share(WET,"cloud",0.4)).is_greater(_share(DRY,"cloud",0.4)+0.15)
	assert_float(_share(WET,"rain",0.1)).is_greater(_share(DRY,"rain",0.1))
	# A wet place still has fair days.
	assert_float(_share(WET,"rain",0.1)).is_less(0.6)

func test_snow_only_when_cold_and_never_with_rain()->void:
	var snowy:=0
	for day in 730:
		var cold:=MapWeather.state(5,float(day),COLD)
		var warm:=MapWeather.state(5,float(day),DRY)
		assert_float(float(warm.snow)).is_equal(0.0)
		assert_bool(float(cold.rain)>0.0 and float(cold.snow)>0.0 and float(cold.rain)+float(cold.snow)>1.0001).is_false()
		if float(cold.snow)>0.1:
			snowy+=1
			assert_float(float(cold.temperature_c)).is_less(1.0)
	assert_int(snowy).is_greater(0)

func test_representatives_are_bounded()->void:
	for warmth in [-1.0,-0.5,0.0,1.0]:
		for water in [true,false]:
			assert_int(Ambience.bird_flocks(warmth,water,true)*Ambience.BIRDS_PER_FLOCK).is_less_equal(Ambience.MAX_BIRDS)
	assert_int(Ambience.bird_flocks(-0.9,true,true)).is_equal(1)  # winter: few birds
	assert_int(Ambience.herd_size(0.1,10.0)).is_equal(0)          # no game, no herd
	assert_int(Ambience.herd_size(1.0,1000.0)).is_less_equal(Ambience.ANIMALS_PER_HERD)
	assert_int(Ambience.herd_size(1.0,1000.0)).is_greater(Ambience.herd_size(0.3,0.0))
	assert_int(Ambience.boat_count(0.0,1.0)).is_equal(0)
	assert_int(Ambience.boat_count(1000.0,1.0)).is_equal(Ambience.MAX_BOATS)
	assert_int(Ambience.boat_count(2.0,1.0)).is_equal(1)

func _host()->Host:
	var host:Host=auto_free(Host.new())
	add_child(host)
	host.camera.position=GameState.settlement_founded_at+Vector3(0,0.3,0.1)
	host.camera_target=GameState.settlement_founded_at
	Living.open_on_people(host)
	return host

func test_layer_builds_once_and_does_not_rebuild_per_frame()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	assert_object(layer).is_not_null()
	var children:=layer.get_child_count()
	var signature:String=layer.life_signature
	var birds:int=layer.birds.multimesh.visible_instance_count
	for i in 30:layer._frame(1.0/60.0)
	assert_int(layer.get_child_count()).is_equal(children)
	assert_str(layer.life_signature).is_equal(signature)
	assert_int(layer.birds.multimesh.visible_instance_count).is_equal(birds)
	# A new day with nothing changed rebuilds nothing.
	Living.refresh(host)
	assert_str(layer.life_signature).is_equal(signature)
	assert_int(layer.birds.multimesh.visible_instance_count).is_less_equal(Ambience.MAX_BIRDS)
	assert_int(layer.herd.multimesh.visible_instance_count).is_less_equal(Ambience.MAX_ANIMALS)
	assert_int(layer.boats.multimesh.visible_instance_count).is_less_equal(Ambience.MAX_BOATS)
	assert_int(layer.drops.multimesh.instance_count).is_equal(Ambience.MAX_DROPS)

func test_population_growth_never_adds_nodes()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	var children:=layer.get_child_count()
	GameState.population_total=50000
	GameState.population_allocations={"Food":20000,"Survey":3000,"Extraction":8000,"Construction":8000,"Crafting":5000,"Logistics":3000,"Knowledge":1000,"Administration":1000,"Defense":1000}
	Living.refresh(host)
	layer._frame(1.0/60.0)
	assert_int(layer.get_child_count()).is_equal(children)
	assert_int(layer.birds.multimesh.visible_instance_count).is_less_equal(Ambience.MAX_BIRDS)
	assert_int(layer.herd.multimesh.visible_instance_count).is_less_equal(Ambience.MAX_ANIMALS)

func test_rain_shows_at_close_view_and_fades_by_the_chart()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	Ambience.forced_weather={"rain":1.0,"snow":0.0,"cloud":0.8}
	layer._refresh_weather(true)
	layer.rain=1.0;layer.cloud=0.8
	host.camera.size=2.8
	layer._frame(1.0/60.0)
	assert_bool(layer.drops.visible).is_true()
	assert_bool(layer.cloud_mesh.visible).is_true()
	host.camera.size=900.0
	layer._frame(1.0/60.0)
	assert_bool(layer.drops.visible).is_false()
	assert_bool(layer.cloud_mesh.visible).is_false()

func test_reduced_motion_stills_weather_and_birds()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	Ambience.forced_weather={"rain":1.0,"snow":0.0,"cloud":0.8,"wind":1.0}
	layer._refresh_weather(true)
	layer.rain=1.0;layer.cloud=0.8
	host.camera.size=1.0
	Motion.reduce_motion=true
	var drift:Vector2=layer.cloud_drift
	for i in 20:layer._frame(1.0/60.0)
	assert_bool(layer.drops.visible).is_false()
	assert_bool(layer.birds.visible).is_false()
	assert_vector(layer.cloud_drift).is_equal(drift)

func test_smoke_follows_the_wind()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	Ambience.forced_weather={"wind":1.0,"wind_dir":Vector2(0,1)}
	layer._refresh_weather(true)
	layer.wind_dir=Vector2(0,1);layer.wind=1.0
	layer._frame(1.0/60.0)
	var smoke_wind:Vector2=Living.smoke_material().get_shader_parameter("wind")
	assert_float(smoke_wind.y).is_greater(0.01)
	assert_float(absf(smoke_wind.x)).is_less(0.002)

func test_wind_reaches_bound_materials()->void:
	var host:=_host()
	var layer:Node=host.get_node_or_null("MapAmbience")
	var shader:=Shader.new()
	shader.code="shader_type spatial;\nuniform vec4 map_wind;\nuniform float map_wind_clock;\nvoid fragment(){ALBEDO=vec3(map_wind.z+map_wind_clock*0.0);}\n"
	var material:=ShaderMaterial.new();material.shader=shader
	Ambience.bind_wind_material(material)
	layer._frame(1.0/60.0)
	var packed:Vector4=material.get_shader_parameter("map_wind")
	assert_float(Vector2(packed.x,packed.y).length()).is_equal_approx(1.0,0.01)
	assert_float(packed.z).is_between(0.0,1.0)

class WorksHost extends Host:
	var undertaking_visual_root:=Node3D.new()
	func _init()->void:
		super._init()
		add_child(undertaking_visual_root)

func test_builders_work_only_at_rising_works_and_are_bounded()->void:
	var host:WorksHost=auto_free(WorksHost.new())
	add_child(host)
	host.camera.position=GameState.settlement_founded_at+Vector3(0,0.3,0.1)
	host.camera_target=GameState.settlement_founded_at
	for i in 5:
		var work:=Node3D.new()
		work.position=GameState.settlement_founded_at+Vector3(0.1*i,0,0.05)
		work.set_meta("map_mark",{"state":"building" if i!=2 else "dedicated","radius":0.02})
		host.undertaking_visual_root.add_child(work)
	Living.open_on_people(host)
	var layer:Node=host.get_node("MapAmbience")
	layer.day_tick()
	var count:int=layer.builders.multimesh.visible_instance_count
	assert_int(count).is_less_equal(Ambience.MAX_BUILDERS)
	assert_int(count).is_equal(Ambience.MAX_BUILDERS)  # three rising works shown, four hands each
	host.camera.size=1.0
	layer._frame(1.0/60.0)
	assert_bool(layer.builders.visible).is_true()
	host.camera.size=40.0
	layer._frame(1.0/60.0)
	assert_bool(layer.builders.visible).is_false()
	# A day with nothing changed keeps the same people at the same places.
	var signature:String=layer.builder_signature
	layer.day_tick()
	assert_str(layer.builder_signature).is_equal(signature)
