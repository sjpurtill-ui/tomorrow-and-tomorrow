extends GdUnitTestSuite
const RELIEF:=preload("res://scripts/terrain_mountain_relief.gd")
class NoRelief extends "res://scripts/terrain_mountain_relief.gd":
	func height_at(_x:float,_z:float,_uplift:float)->float:return 0.0
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

func setup(seed_value:int)->Terrain:
	GameState.reset_for_new_world(seed_value)
	var terrain:=Terrain.new();terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	return terrain

func test_lowlands_are_exactly_unchanged()->void:
	var relief:=RELIEF.new();relief.configure(873421)
	for point in [Vector2.ZERO,Vector2(6600,-3280),Vector2(-18000,8000)]:
		for uplift:float in [-1.0,0.0,.1,.35]:
			assert_float(relief.height_at(point.x,point.y,uplift)).is_equal(0.0)

func test_relief_is_bounded_across_seeds_and_uplifts()->void:
	var relief:=RELIEF.new()
	for seed_value:int in [42,873421,424242,-1831]:
		relief.configure(seed_value)
		for i in 256:
			for uplift:float in [.36,1.5,2.8,8.4]:
				var h:=relief.height_at(float(i)*.127+6600,float(i)*.239-3280,uplift)
				assert_float(h).is_between(-.18,.62)

func test_same_seed_is_repeatable_and_another_seed_changes_structure()->void:
	var a:=RELIEF.new();a.configure(873421)
	var b:=RELIEF.new();b.configure(873421)
	var c:=RELIEF.new();c.configure(424242)
	var difference:=0.0
	for i in 100:
		var x:=55.0+float(i)*.1
		assert_float(a.height_at(x,0,4)).is_equal(b.height_at(x,0,4))
		difference+=absf(a.height_at(x,0,4)-c.height_at(x,0,4))
	assert_float(difference).is_greater(.1)

func test_foothill_activation_is_continuous()->void:
	var relief:=RELIEF.new();relief.configure(873421)
	for uplift:float in [.35,2.8]:
		for i in 100:
			var x:=6600.0+float(i)*.13
			assert_float(absf(relief.height_at(x,-3280,uplift-.0001)-relief.height_at(x,-3280,uplift+.0001))).is_less(.000001)

func test_no_coordinate_tile_seams_at_distant_positions()->void:
	var relief:=RELIEF.new();relief.configure(873421)
	for i in 100:
		var x:=6600.0+float(i)*.1
		var h:=relief.height_at(x,-3280,4)
		assert_float(absf(h-relief.height_at(x+.001,-3280,4))).is_less(.01)

func test_local_terrain_uses_the_same_physical_relief_as_the_shared_model()->void:
	var terrain:=setup(873421)
	var relief:RefCounted=terrain.mountain_relief
	var change:=0.0
	for point:Vector2 in [Vector2(-4400,3320),Vector2(6600,-3280),Vector2(2320,120),Vector2(55,0)]:
		var actual:=terrain._height_at(point.x,point.y)
		terrain.mountain_relief=NoRelief.new()
		var baseline:=terrain._height_at(point.x,point.y)
		terrain.mountain_relief=relief
		assert_float(absf(actual-baseline)).is_less_equal(.620001)
		change+=absf(actual-baseline)
	assert_float(change).is_greater(.001)
	terrain.free()

func test_coastline_and_ocean_classifications_remain_unchanged()->void:
	for seed_value:int in [873421,424242]:
		var terrain:=setup(seed_value)
		var relief:RefCounted=terrain.mountain_relief
		var none:=NoRelief.new()
		for z in range(-8000,8001,800):
			for x in range(-18000,18001,900):
				var actual:=terrain._height_at(x,z)
				terrain.mountain_relief=none
				var baseline:=terrain._height_at(x,z)
				terrain.mountain_relief=relief
				assert_bool(actual>.015).is_equal(baseline>.015)
				if baseline<=.2:assert_float(actual).is_equal(baseline)
		terrain.free()

func test_planet_and_local_terrain_apply_identical_mountain_detail()->void:
	var terrain:=setup(873421)
	PlanetEnvironment.reset_for_new_world()
	var local_relief:RefCounted=terrain.mountain_relief
	var planet_relief:RefCounted=PlanetEnvironment._mountain_relief
	var none:=NoRelief.new()
	# Outside the authored cradle/river: both authorities have the same mountain
	# uplift envelope. Existing broad-vs-local differences are not erased here.
	for i in 20:
		var point:=Vector2(2000.0+float(i)*.137,-1000)
		var detailed_local:=terrain._height_at(point.x,point.y)
		var detailed_planet:=PlanetEnvironment.world_height_at(point)
		terrain.mountain_relief=none;PlanetEnvironment._mountain_relief=none
		var base_local:=terrain._height_at(point.x,point.y)
		var base_planet:=PlanetEnvironment.world_height_at(point)
		terrain.mountain_relief=local_relief;PlanetEnvironment._mountain_relief=planet_relief
		assert_float(detailed_local-base_local).is_equal_approx(detailed_planet-base_planet,.000001)
		assert_float(absf(detailed_local-base_local)).is_greater(.000001)
	terrain.free()
