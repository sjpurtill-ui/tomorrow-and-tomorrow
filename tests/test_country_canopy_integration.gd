extends GdUnitTestSuite
const Woods:=preload("res://scripts/close_woods.gd")

class Terrain extends "res://scripts/local_terrain.gd":
	func _biome_at(_x:float,_z:float,_height:float=NAN)->Dictionary:
		return {"woodland":0.8}

class Country extends Node3D:
	var clearing_revision:=0
	var requests:=0
	var marks:=PackedVector4Array([Vector4(14034,-2892,0.025,0.04)])
	var last_center:=Vector2.ZERO
	func woodland_ledgers()->Array:return []
	func canopy_clearings(center:Vector2,_limit:int=16)->PackedVector4Array:
		requests+=1;last_center=center
		return marks

class Harvest extends MultiMeshInstance3D:
	var received:=PackedVector4Array()
	func refresh(_center:Vector2,_span:float,areas:PackedVector4Array,_seed:int,_day:int,_cover:Callable,_revealed:Callable,_height:Callable,_force:bool=false)->void:
		received=areas.duplicate()

func _fixture()->Terrain:
	# The real map methods run without entering its game/HUD ready lifecycle.
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.size=0.2;terrain.camera_target=Vector3(14034,0,-2892)
	terrain.country_land=Country.new();terrain.add_child(terrain.country_land)
	terrain.woodland_harvest_detail=Harvest.new();terrain.add_child(terrain.woodland_harvest_detail)
	return terrain

func test_streamed_crowns_use_live_farm_masks_while_resources_and_stumps_do_not()->void:
	var terrain:=_fixture()
	var before:=GameState.resource_deposits.duplicate(true)
	var people_before:=GameState.population_exact
	terrain._refresh_woodland_visuals(true)
	var actual_density:=0.8*preload("res://scripts/landscape_resource_visuals.gd").retained_at(Vector2(14034,-2892),terrain.woodland_visual_areas)
	assert_float(terrain._woodland_density_at(14034,-2892)).is_equal_approx(actual_density,0.00001)
	assert_bool((terrain.woodland_harvest_detail as Harvest).received==terrain.woodland_visual_areas).is_true()
	assert_bool(terrain.woodland_visual_areas.has(Vector4(14034,-2892,0.025,0.04))).is_false()
	# CloseWoods takes precisely this registered material and retains it in
	# a pool, so changing the live uniform must also affect existing crowns.
	var woods:=Woods.new();terrain.add_child(woods);woods.terrain=terrain
	var crown:ShaderMaterial=woods._take_material()
	assert_int(int(crown.get_shader_parameter("woodland_area_count"))).is_equal(terrain.woodland_canopy_areas.size())
	var areas:PackedVector4Array=crown.get_shader_parameter("woodland_areas")
	assert_bool(areas.has(Vector4(14034,-2892,0.025,0.04))).is_true()
	var country:Country=terrain.country_land
	country.marks=PackedVector4Array([Vector4(14034,-2892,0.025,0.60)]);country.clearing_revision+=1
	terrain._refresh_woodland_visuals()
	areas=crown.get_shader_parameter("woodland_areas")
	assert_bool(areas.has(Vector4(14034,-2892,0.025,0.60))).is_true()
	assert_float(terrain._woodland_density_at(14034,-2892)).is_equal_approx(actual_density,0.00001)
	assert_array(GameState.resource_deposits).is_equal(before)
	assert_float(GameState.population_exact).is_equal(people_before)

func test_close_pan_refreshes_nearest_clearings_without_idle_rescans()->void:
	var terrain:=_fixture()
	terrain._refresh_woodland_visuals(true)
	var country:Country=terrain.country_land
	var requests:=country.requests
	for index in 30:terrain._refresh_woodland_visuals()
	assert_int(country.requests).is_equal(requests)
	terrain.camera_target.x+=0.32
	terrain._refresh_woodland_visuals()
	assert_int(country.requests).is_equal(requests+1)
	assert_vector(country.last_center).is_equal(Vector2(terrain.camera_target.x,terrain.camera_target.z))
