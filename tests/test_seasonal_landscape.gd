extends GdUnitTestSuite
const REGIONAL:=preload("res://scripts/terrain_patch_builder.gd")
const CLOSE:=preload("res://scripts/close_terrain_job.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func fixture(seed_value:int=873421)->Terrain:
	GameState.reset_for_new_world(seed_value)
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	return terrain

func test_seasonal_amplitude_is_the_existing_environment_authority()->void:
	fixture(873421)
	for seed_value:int in [42,873421,271828]:
		GameState.world_seed=seed_value
		for position:Vector2 in [Vector2.ZERO,Vector2(800,-4700),Vector2(-14000,6800)]:
			var profile:=PlanetEnvironment.profile_at(position)
			assert_float(PlanetEnvironment.seasonality_at(position)).is_equal_approx(profile.seasonality_c,.000001)
			for day:float in [0,91.25,273.75,912591.25]:
				var expected:float=profile.mean_temperature_c+PlanetEnvironment.season_wave(profile,day)*profile.seasonality_c
				assert_float(PlanetEnvironment.ambient_temperature_c(profile,day)).is_equal_approx(expected,.000001)

func test_hud_temperature_matches_season_and_hemisphere_instead_of_another_weather_clock()->void:
	var terrain:=fixture()
	GameState.settlement_site_committed=true
	for point:Vector2 in [Vector2(2000,-4700),Vector2(2000,4700)]:
		var height:=terrain._height_at(point.x,point.y)
		GameState.settlement_founded_at=Vector3(point.x,height,point.y)
		var climate:=terrain._climate_at(point.x,point.y,height)
		var profile:=PlanetEnvironment.profile_at(point,{"height":height,"temperature":climate.temperature,"precipitation":climate.precipitation})
		for day:float in [91.25,273.75]:
			assert_float(terrain.site_temperature_c(day)).is_equal_approx(PlanetEnvironment.ambient_temperature_c(profile,day),.00001)

func test_seasonal_channel_preserves_mesh_geometry_and_climate_in_both_builders()->void:
	var terrain:=fixture()
	var point:=Vector2(1600,-5200)
	var old:=REGIONAL.new(17,2,point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
	var season:=REGIONAL.new(17,2,point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
	while not old.advance(100000):pass
	while not season.advance(1):pass
	assert_bool(old.vertices==season.vertices and old.normals==season.normals and old.colors==season.colors and old.climate_uv==season.climate_uv and old.geology_uv==season.geology_uv).is_true()
	var arrays:=season.commit().surface_get_arrays(0)
	assert_int(arrays[Mesh.ARRAY_CUSTOM0].size()).is_equal(289)
	for i in range(0,season.vertices.size(),27):
		var p:Vector3=season.vertices[i]
		assert_float(arrays[Mesh.ARRAY_CUSTOM0][i]).is_equal_approx(PlanetEnvironment.seasonality_at(Vector2(p.x,p.z)),.00002)
	var sample:=func(x:float,z:float)->Array:return [terrain._height_at(x,z),Vector3.UP,terrain._terrain_color_at(x,z,terrain._height_at(x,z))]
	var close:=CLOSE.new(9,.42,point,sample,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
	while not close.advance(1):pass
	var close_arrays:=close.commit().surface_get_arrays(0)
	assert_int(close_arrays[Mesh.ARRAY_CUSTOM0].size()).is_equal(81)
	assert_float(close_arrays[Mesh.ARRAY_CUSTOM0][40]).is_equal_approx(PlanetEnvironment.seasonality_at(point),.00002)

func test_calendar_updates_materials_without_rebuilding_resources_or_geometry()->void:
	var terrain:=fixture()
	var resources:=GameState.resource_deposits.duplicate(true)
	var material:=terrain._create_terrain_material()
	var foliage:=terrain._vegetation_surface_material(0)
	GameState.elapsed_days=91.25
	terrain._refresh_seasonal_visuals()
	assert_float(material.get_shader_parameter("season_phase")).is_equal_approx(1,.00001)
	assert_float(foliage.get_shader_parameter("season_phase")).is_equal_approx(1,.00001)
	var last_day:=terrain.last_seasonal_day
	for i in 12:terrain._refresh_seasonal_visuals()
	assert_float(terrain.last_seasonal_day).is_equal(last_day)
	GameState.elapsed_days=273.75
	terrain._refresh_seasonal_visuals()
	assert_float(material.get_shader_parameter("season_phase")).is_equal_approx(-1,.00001)
	assert_float(foliage.get_shader_parameter("season_phase")).is_equal_approx(-1,.00001)
	assert_array(GameState.resource_deposits).is_equal(resources)
	assert_bool(terrain.terrain_patch_job==null and terrain.close_terrain_job==null).is_true()
	assert_int(terrain.seasonal_materials.size()).is_equal(2)
	foliage=null
	GameState.elapsed_days=300
	terrain._refresh_seasonal_visuals()
	assert_int(terrain.seasonal_materials.size()).is_equal(1)

func test_base_mesh_and_live_streaming_paths_include_seasonal_channel()->void:
	var terrain:=fixture()
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell:Vector2i in [Vector2i(200,100),Vector2i(201,100),Vector2i(200,101)]:terrain._add_terrain_vertex(surface,cell.x,cell.y)
	var arrays:=surface.commit().surface_get_arrays(0)
	assert_int(arrays[Mesh.ARRAY_CUSTOM0].size()).is_equal(3)
	for i in 3:
		var p:Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		assert_float(arrays[Mesh.ARRAY_CUSTOM0][i]).is_equal_approx(PlanetEnvironment.seasonality_at(Vector2(p.x,p.z)),.00002)
	terrain._rebuild_regional_terrain_patch(Vector2(12000,-3800),10)
	assert_bool(terrain.terrain_patch_job.season_sampler.is_valid()).is_true()
	terrain._request_close_terrain_job(Vector3(12000,1.54,-3800))
	assert_bool(terrain.close_terrain_job.season_sampler.is_valid()).is_true()
	# Water beneath an understory patch must not require terrestrial biome keys.
	var found_water:=false
	for point:Vector2 in [Vector2(20000,9000),Vector2(-20000,-9000),Vector2(19000,0)]:
		if terrain._height_at(point.x,point.y)>=0:continue
		assert_float(terrain._vegetation_climate(Vector3(point.x,0,point.y)).b).is_equal(0.0)
		found_water=true;break
	assert_bool(found_water).is_true()

func test_visual_cryosphere_is_climate_gated_and_uses_existing_structure()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/seasonal_surface.gdshaderinc")
	assert_str(source).contains("float cold=1.0-smoothstep(-1.5,3.5,temperature)")
	assert_str(source).contains("float snow_supply=smoothstep(0.045,0.38,rain)")
	assert_str(source).contains("float hard_frost=(1.0-smoothstep(-16.0,-8.0,temperature))")
	assert_str(source).contains("float drift=smoothstep(0.34,0.72,terrain_pattern)")
	var terrain_source:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_str(terrain_source).contains("regional*0.62+soil_patch*0.38")
	assert_str(terrain_source).contains("seasonal_terrain(earth,UV.y,UV.x-1.0")
