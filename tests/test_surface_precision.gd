extends GdUnitTestSuite
const PRECISION:=preload("res://scripts/surface_precision.gd")
func test_local_wave_phases_reproduce_world_waves_in_all_quadrants()->void:
	# Keep decimal frequencies as doubles, matching actual shader coefficients.
	var coefficients:Array[Array]=[[76.0,42.0],[-53.0,86.0],[9.7,-11.1],[-7.3,5.1],[780.0,390.0],[631.8,315.9]]
	for point:Vector2 in [Vector2.ZERO,Vector2(20000,9800),Vector2(-20000,-9800),Vector2(-17000,7600),Vector2(6600,-3280)]:
		var parameters:=PRECISION.water_parameters(point)
		var phases:Array[float]=[parameters.wave_phase.x,parameters.wave_phase.y,parameters.wave_phase.z,parameters.wave_phase.w,parameters.ripple_phase.x,parameters.ripple_phase.y]
		for i in 6:
			assert_float(phases[i]).is_between(0.0,TAU)
			var x:=float(point.x)+.000317;var z:=float(point.y)-.000211
			var expected:=sin(x*coefficients[i][0]+z*coefficients[i][1])
			var local:=sin((x-float(parameters.surface_origin.x))*coefficients[i][0]+(z-float(parameters.surface_origin.y))*coefficients[i][1]+phases[i])
			assert_float(local).is_equal_approx(expected,.000002)
func test_reanchoring_preserves_wave_phase_at_the_same_world_point()->void:
	var point:=Vector2(19999.5,-9855.5)
	var a:=PRECISION.water_parameters(point);var b:=PRECISION.water_parameters(point+Vector2(64,-64))
	assert_vector(a.surface_origin).is_not_equal(b.surface_origin)
	for delta:float in [0.0,.0001,.001,.03]:
		var x:=float(point.x)+delta;var z:=float(point.y)-delta
		var old:=sin((x-a.surface_origin.x)*780.0+(z-a.surface_origin.y)*390.0+a.ripple_phase.x)
		var new:=sin((x-b.surface_origin.x)*780.0+(z-b.surface_origin.y)*390.0+b.ripple_phase.x)
		assert_float(old).is_equal_approx(new,.000002)
func test_water_material_receives_small_consistent_phase_values()->void:
	var material:=ShaderMaterial.new();material.shader=preload("res://scripts/coastal_water.gdshader")
	PRECISION.configure_water(material,Vector2(20000,-9800))
	var expected:=PRECISION.water_parameters(Vector2(20000,-9800))
	for key:String in expected:assert_that(material.get_shader_parameter(key)).is_equal(expected[key])
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func test_near_vertical_camera_keeps_its_orientation_at_far_coordinates()->void:
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	var camera:=Camera3D.new();terrain.add_child(camera);terrain.camera=camera
	camera.fov=35;camera.size=1.895074;terrain.camera_yaw=.72;terrain.camera_pitch=-PI*.5+.0001
	terrain.camera_target=Vector3.ZERO;terrain._update_camera();var home:=camera.basis
	for point:Vector3 in [Vector3(20000,1,0),Vector3(-17400,4.29,-7790),Vector3(6600,.18,-3280)]:
		terrain.camera_target=point;terrain._update_camera()
		assert_float(camera.basis.x.distance_to(home.x)).is_less(.0001)
		assert_float(camera.basis.y.distance_to(home.y)).is_less(.0001)
		assert_float(camera.basis.z.distance_to(home.z)).is_less(.0001)
func test_camera_orientation_preserves_existing_oblique_angles_and_roll()->void:
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	var camera:=Camera3D.new();terrain.add_child(camera);terrain.camera=camera;camera.size=40
	for pitch:float in [-.4,-.98,-1.5]:
		for yaw:float in [-2.7,-.72,0,.72,2.7]:
			terrain.camera_pitch=pitch;terrain.camera_yaw=yaw;terrain.camera_target=Vector3.ZERO;terrain._update_camera()
			var expected:=Transform3D(Basis.IDENTITY,camera.position).looking_at(Vector3.ZERO,Vector3.UP).basis
			assert_float(camera.basis.x.distance_to(expected.x)).is_less(.000001)
			assert_float(camera.basis.y.distance_to(expected.y)).is_less(.000001)
			assert_float(camera.basis.z.distance_to(expected.z)).is_less(.000001)
