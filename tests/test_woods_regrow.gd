class_name WoodsRegrowTest
extends GdUnitTestSuite
## Woods: as many worked at once as the cutters fill, cut woods never hold a
## people to the ground it first knew, coppice grows them back faster
## (resource_system.gd working_fronts, MAX_FRONTS_EVER, woods_regrowth), and a
## large town's builders are not locked out by a per-head reserve
## (built_fabric.gd RESERVE_BASE).

const BF:=preload("res://scripts/built_fabric.gd")
var _known:Array
var _alloc:Dictionary

func before_test()->void:
	_known=GameState.known_discoveries.duplicate()
	_alloc=GameState.population_allocations.duplicate()

func after_test()->void:
	GameState.known_discoveries.clear(); GameState.known_discoveries.append_array(_known)
	GameState.population_allocations.clear(); GameState.population_allocations.merge(_alloc)

func test_a_band_works_one_wood_and_a_city_many()->void:
	GameState.population_allocations["Extraction"]=8
	assert_int(ResourceSystem.working_fronts()).is_equal(1)
	GameState.population_allocations["Extraction"]=2000
	var many:=ResourceSystem.working_fronts()
	assert_int(many).is_greater(10)
	assert_int(many).is_less_equal(ResourceSystem.MAX_WORKING_FRONTS)

func test_coppice_grows_woods_back_faster()->void:
	for id in ResourceSystem.COPPICE: GameState.known_discoveries.erase(id)
	GameState.elapsed_days=float(GameState.elapsed_days)+1.0
	var wild:=ResourceSystem.woods_regrowth()
	assert_float(wild).is_equal(ResourceSystem.WOOD_REGROWTH)
	GameState.known_discoveries.append("coppice_regrowth_cutting")
	GameState.elapsed_days=float(GameState.elapsed_days)+1.0
	assert_float(ResourceSystem.woods_regrowth()).is_equal_approx(wild*3.0,1e-9)
	GameState.known_discoveries.append("coppice_with_standards")
	GameState.elapsed_days=float(GameState.elapsed_days)+1.0
	assert_float(ResourceSystem.woods_regrowth()).is_equal_approx(wild*4.0,1e-9)

func test_a_band_keeps_its_store_and_a_city_keeps_a_share()->void:
	var stocks:={"Timber":10000.0,"Clay":0.0,"Stone":0.0,"Fiber Plants":0.0}
	# A band of 120 keeps 120 back, as before.
	assert_float(float(BF._spare(120.0,stocks).Timber)).is_less_equal(10000.0-120.0)
	# A city of 39,000 keeps about 5,900 back, not 39,000.
	var city:=float(BF._spare(39000.0,stocks).Timber)
	assert_float(city).is_greater(0.0)
	assert_float(city).is_less_equal(10000.0-(BF.RESERVE_BASE+BF.RESERVE_LARGE*39000.0)+0.001)
