extends GdUnitTestSuite

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Walk:=preload("res://scripts/hud/court_motion.gd")

func test_facing_crosses_the_angle_seam_without_spinning()->void:
	var body:Node3D=auto_free(Figure3D.new());add_child(body)
	for direction in [-1.0,1.0]:
		body.rotation_degrees.y=179.0*direction
		body.face(-179.0*direction,0.4)
		body._yaw_tween.pause()
		body._yaw_tween.custom_step(0.2)
		assert_float(absf(body.rotation_degrees.y)).is_greater(179.0)
		body._yaw_tween.custom_step(0.2)
		assert_float(absf(wrapf(body.rotation_degrees.y+179.0*direction,-180.0,180.0))).is_less(0.01)

func test_walk_starts_and_stops_gently_and_covers_its_whole_route()->void:
	for seconds in [0.8,1.4,6.5]:
		assert_vector(Walk.sample(0.0,seconds)).is_equal(Vector2.ZERO)
		assert_vector(Walk.sample(1.0,seconds)).is_equal(Vector2(1.0,0.0))
		assert_float(Walk.sample(0.02,seconds).y).is_less(Walk.sample(0.5,seconds).y)
		for fps in [30,60,144]:
			var count:=int(round(seconds*fps))
			var travelled:=0.0
			var previous:=0.0
			for i in count:
				var sample:=Walk.sample(float(i+1)/count,seconds)
				assert_float(sample.x).is_greater_equal(previous)
				previous=sample.x
				travelled+=sample.y/count
			# Integral of the foot clock equals the translated distance.
			assert_float(travelled).is_equal_approx(1.0,0.006)

func test_capped_travel_time_scales_the_feet_and_releases_them_at_rest()->void:
	var figure:Stage.Figure=auto_free(Stage.Figure.new());add_child(figure)
	var body:Node3D=auto_free(Figure3D.new());add_child(body)
	body.player=AnimationPlayer.new();body.add_child(body.player)
	figure.body3d=body
	figure._path=PackedVector3Array([Vector3.ZERO,Vector3(0,0,9)])
	figure._move=figure.create_tween()
	figure._queue_stroll(0.0,1.0,3.0,1.0,false)
	figure._move.pause()
	figure._move.custom_step(1.5)
	assert_float(figure.stroll).is_equal_approx(0.5,0.001)
	assert_float(body.player.speed_scale).is_greater(3.0)
	assert_float(body.locomotion_rate).is_equal_approx(body.player.speed_scale,0.00001)
	figure._move.custom_step(1.51)
	assert_float(figure.stroll).is_equal(1.0)
	assert_float(body.locomotion_rate).is_equal(1.0)
	assert_float(body.player.speed_scale).is_equal(1.0)

func test_walking_turns_consistently_at_low_and_high_frame_rates()->void:
	var figure:Stage.Figure=auto_free(Stage.Figure.new());add_child(figure)
	var body:Node3D=auto_free(Figure3D.new());add_child(body)
	figure.body3d=body
	figure._path=PackedVector3Array([Vector3.ZERO,Vector3(0,0,2),Vector3(2,0,2)])
	var headings:Array[float]=[]
	for fps in [30,144]:
		body.rotation.y=0.0
		figure.stroll=0.0
		figure._travel_progress=0.0
		for i in int(fps*1.3):
			figure._travel_step(float(i+1)/(fps*2.0),0.0,1.0,2.0,2.0,false)
		headings.append(body.rotation.y)
	assert_float(absf(headings[0]-headings[1])).is_less(deg_to_rad(4.0))
