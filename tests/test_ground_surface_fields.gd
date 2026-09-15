extends GdUnitTestSuite

func test_satellite_woodland_has_firm_visual_edges_without_changing_density_authority()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_str(source).contains("float forest_stand_edge=smoothstep(0.18,0.72,forest_mask)")
	assert_str(source).contains("country_detail*(1.0-close_detail*0.68)*0.56")
	assert_bool(source.find("forest_mask=mix(forest_mask,forest_stand_edge,forest_edge_weight)")<source.find("float retained_woodland=woodland_retained")).is_true()

func test_regional_orthophoto_retains_resolved_tone_and_restrained_chroma()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_str(source).contains("regional_photo_detail*0.96")
	assert_str(source).contains("regional_photo_detail*0.20")
	assert_str(source).contains("vec3(0.82),vec3(1.18)")

func test_unresolved_surface_noise_is_guarded_by_its_existing_lod_weight()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/ground_surface.gdshaderinc")
	assert_str(source).contains("if (regional_grain>0.0)")
	assert_str(source).contains("if (resolved>0.0)")
	assert_str(source).contains("if (band_detail>0.0 && sediment>0.0)")
	assert_str(source).contains("if (fine>0.0)")
	assert_str(source).contains("if (soil_detail>0.0)")
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
func test_material_fields_match_actual_survey_climate_and_resource_geology()->void:
	var terrain:=fixture();var visited:=0
	for position:Vector2 in [Vector2.ZERO,Vector2(500,-500),Vector2(-2300,4100),Vector2(1800,-5400),Vector2(6600,2100)]:
		var height:=terrain._height_at(position.x,position.y)
		var surveyed:=terrain._climate_at(position.x,position.y,height)
		var profile:=PlanetEnvironment.profile_at(position,{"height":height,"temperature":surveyed.temperature,"precipitation":surveyed.precipitation})
		var fields:=terrain._terrain_surface_fields_at(position.x,position.y,height)
		var geology:Dictionary=profile.geology;var total:float=geology.sedimentary+geology.igneous+geology.metamorphic
		assert_float(fields.x-1).is_equal_approx(surveyed.precipitation,.000001)
		assert_float(fields.y).is_equal_approx(surveyed.temperature,.000001)
		assert_float(fields.z).is_equal_approx(geology.sedimentary/total,.000001)
		assert_float(fields.w).is_equal_approx(geology.igneous/total,.000001)
		assert_float(fields.z+fields.w).is_less_equal(1.0)
		assert_dict(profile.resource_potentials).is_equal(PlanetEnvironment.profile_at(position,{"height":height,"temperature":surveyed.temperature,"precipitation":surveyed.precipitation}).resource_potentials)
		visited+=1
	assert_int(visited).is_equal(5)
func test_regional_channels_preserve_geometry_and_match_sliced_jobs()->void:
	var terrain:=fixture()
	var bare:=REGIONAL.new(17,2.0,Vector2(50,30),terrain._height_at,terrain._terrain_color_at)
	var full:=REGIONAL.new(17,2.0,Vector2(50,30),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
	var sliced:=REGIONAL.new(17,2.0,Vector2(50,30),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
	while not bare.advance(100000):pass
	while not full.advance(100000):pass
	while not sliced.advance(1):pass
	assert_bool(bare.vertices==full.vertices and bare.normals==full.normals and bare.indices==full.indices and bare.colors==full.colors).is_true()
	assert_bool(full.climate_uv==sliced.climate_uv and full.geology_uv==sliced.geology_uv).is_true()
	var mesh:=full.commit().surface_get_arrays(0)
	assert_int(mesh[Mesh.ARRAY_TEX_UV].size()).is_equal(289)
	for i in range(0,full.vertices.size(),31):
		var p:Vector3=full.vertices[i];var fields:=terrain._terrain_surface_fields_at(p.x,p.z,p.y)
		assert_vector(full.climate_uv[i]).is_equal(Vector2(fields.x,fields.y))
		assert_vector(full.geology_uv[i]).is_equal(Vector2(fields.z,fields.w))
func test_close_and_base_meshes_carry_the_same_physical_channels()->void:
	var terrain:=fixture()
	var sample:=func(x:float,z:float)->Array:return [terrain._height_at(x,z),Vector3.UP,terrain._terrain_color_at(x,z,terrain._height_at(x,z))]
	var job:=CLOSE.new(9,.42,Vector2.ZERO,sample,terrain._terrain_surface_fields_at)
	while not job.advance(1):pass
	var arrays:=job.commit().surface_get_arrays(0)
	assert_int(arrays[Mesh.ARRAY_TEX_UV].size()).is_equal(81)
	for i in job.vertices.size():
		var p:Vector3=job.vertices[i];var fields:=terrain._terrain_surface_fields_at(p.x,p.z,p.y)
		assert_float(job.climate_uv[i].distance_to(Vector2(fields.x,fields.y))).is_less(.000002)
		assert_float(job.geology_uv[i].distance_to(Vector2(fields.z,fields.w))).is_less(.000002)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell:Vector2i in [Vector2i(240,120),Vector2i(241,120),Vector2i(240,121)]:terrain._add_terrain_vertex(surface,cell.x,cell.y)
	var base:=surface.commit().surface_get_arrays(0)
	for i in 3:
		var p:Vector3=base[Mesh.ARRAY_VERTEX][i];var fields:=terrain._terrain_surface_fields_at(p.x,p.z,p.y)
		assert_float(base[Mesh.ARRAY_TEX_UV][i].x).is_equal_approx(fields.x,.002)
		assert_float(base[Mesh.ARRAY_TEX_UV2][i].x).is_equal_approx(fields.z,.002)
func test_geology_projection_tracks_world_seed_without_changing_resources()->void:
	var terrain:=fixture(42);var position:=Vector2(510,-800)
	var old:=PlanetEnvironment.surface_geology_at(position,1.0)
	var before:=GameState.resource_deposits.duplicate(true)
	GameState.world_seed=271828
	var current:=PlanetEnvironment.surface_geology_at(position,1.0)
	assert_bool(old!=current).is_true()
	assert_dict(current).is_equal(PlanetEnvironment.profile_at(position,{"height":1.0}).geology)
	assert_array(GameState.resource_deposits).is_equal(before)
	assert_bool(terrain!=null).is_true()
