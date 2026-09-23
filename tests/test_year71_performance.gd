extends GdUnitTestSuite
const Samples=preload("res://scripts/settlement_surface_samples.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
var height_calls:=0
var land_calls:=0
func sample_height(x:float,z:float)->float:
	height_calls+=1;return x*1.731+z*.329
func sample_land(p:Vector2)->bool:
	land_calls+=1;return p.x>=0
func test_exact_samples_reused_without_rounding_or_cross_build_staleness()->void:
	height_calls=0;land_calls=0
	var samples:=Samples.new(sample_height,sample_land)
	var first:=samples.height_at(5000.0000001,12.0)
	assert_float(samples.height_at(5000.0000001,12.0)).is_equal(first)
	samples.height_at(5000.0000002,12.0)
	assert_int(height_calls).is_equal(2)
	assert_bool(samples.land_at(Vector2.ONE)).is_true();assert_bool(samples.land_at(Vector2.ONE)).is_true()
	assert_int(land_calls).is_equal(1)
	var next:=Samples.new(sample_height,sample_land);next.height_at(5000.0000001,12.0)
	assert_int(height_calls).is_equal(3)
func test_small_fabric_is_camera_independent_but_large_or_dispersed_is_bounded()->void:
	var old_plots:=GameState.settlement_plots;var old_routes:=GameState.settlement_routes
	GameState.settlement_plots=[{"id":1,"centroid":Vector2.ZERO}];GameState.settlement_routes=[]
	var terrain:Terrain=auto_free(Terrain.new());terrain.camera=auto_free(Camera3D.new())
	for zoom:float in [.1,1,3,20,2000]:
		terrain.camera.size=zoom;terrain.camera_target=Vector3(zoom,0,-zoom)
		assert_int(terrain._settlement_morphology_lod()).is_equal(1)
		assert_str(terrain._settlement_morphology_view_signature(1)).is_equal("1")
	GameState.settlement_plots[0].centroid=Vector2(2,0)
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_plots[0].centroid=Vector2.ZERO
	GameState.settlement_routes=[{"points":PackedVector2Array([Vector2.ZERO,Vector2(3,0)])}]
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_routes=[]
	for i in 97:GameState.settlement_plots.append({"id":i+2,"centroid":Vector2.ZERO})
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_plots=old_plots;GameState.settlement_routes=old_routes
