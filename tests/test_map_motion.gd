extends GdUnitTestSuite
## Camera feel (codex/map-motion): the zoom glide eases in and out and never
## overshoots, a released pan coasts to a stop, keyboard panning eases, and
## reduced motion removes coasting and shortens every glide.
const MapMotion:=preload("res://scripts/map_motion.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

func after_test()->void:
	Motion.reduce_motion=false

func _glide(from:float,to:float,frames:int,dt:float=1.0/60.0)->Array[float]:
	var sizes:Array[float]=[from]
	var size:=from
	var velocity:=0.0
	for i in frames:
		var step:=MapMotion.zoom_step(size,velocity,to,dt)
		size=step.x;velocity=step.y
		sizes.append(size)
		if step.z>0.5:break
	return sizes

func test_zoom_glide_is_monotonic_and_lands_exactly()->void:
	for pair in [[5.0,3.98],[2.84,14.2],[14.2,150.0],[150.0,3000.0],[3000.0,2.84]]:
		var sizes:=_glide(float(pair[0]),float(pair[1]),600)
		var rising:=float(pair[1])>float(pair[0])
		for i in range(1,sizes.size()):
			if rising:assert_bool(sizes[i]>=sizes[i-1]-0.000001).is_true()
			else:assert_bool(sizes[i]<=sizes[i-1]+0.000001).is_true()
			# Never beyond the target.
			if rising:assert_bool(sizes[i]<=float(pair[1])*1.000001).is_true()
			else:assert_bool(sizes[i]>=float(pair[1])*0.999999).is_true()
		assert_float(sizes[-1]).is_equal_approx(float(pair[1]),0.000001)

func test_zoom_glide_eases_in_rather_than_jumping()->void:
	# From rest the first frame covers far less than an even share of the way.
	var sizes:=_glide(14.2,150.0,600)
	var total:=log(150.0/14.2)
	var first:=log(sizes[1]/sizes[0])
	assert_float(first).is_less(total*0.02)
	# ...yet a whole distance level still lands in about a second.
	assert_int(sizes.size()).is_less(90)

func test_zoom_glide_speed_is_capped()->void:
	var sizes:=_glide(3000.0,2.84,900)
	for i in range(1,sizes.size()):
		assert_float(absf(log(sizes[i]/sizes[i-1]))).is_less_equal(MapMotion.ZOOM_MAX_LOG_SPEED/60.0+0.0001)

func test_spring_with_stale_velocity_does_not_cross_target()->void:
	# Reversing mid-glide: velocity still points the old way, target is behind.
	var result:=MapMotion.spring_step(1.0,-30.0,0.9,9.0,1.0/60.0)
	assert_float(result.x).is_greater_equal(0.9-0.000001)
	var landed:=MapMotion.spring_step(0.905,-50.0,0.9,9.0,1.0/30.0)
	assert_float(landed.x).is_equal_approx(0.9,0.000001)
	assert_float(landed.y).is_equal(0.0)

func test_zoom_glide_is_frame_rate_independent()->void:
	var at60:=_glide(14.2,150.0,30,1.0/60.0)
	var at120:=_glide(14.2,150.0,60,1.0/120.0)
	assert_float(absf(log(at60[-1]/at120[-1]))).is_less(0.03)

func test_pan_coast_decays_to_rest_and_is_capped()->void:
	var view:=4.0
	var launch:=MapMotion.release_velocity(Vector3(400.0,0,0),view)
	assert_float(launch.length()).is_equal_approx(MapMotion.COAST_MAX_VIEWS*view,0.0001)
	var velocity:=launch
	var travelled:=0.0
	var frames:=0
	while velocity!=Vector3.ZERO and frames<600:
		travelled+=velocity.length()/60.0
		velocity=MapMotion.coast_step(velocity,1.0/60.0,view)
		frames+=1
	assert_int(frames).is_less(120)  # stops within two seconds
	# Coasting adds a short glide (about tau x speed), never a long slide.
	assert_float(travelled).is_less(launch.length()*MapMotion.COAST_SECONDS*1.05)
	assert_float(travelled).is_greater(0.0)

func test_key_pan_eases_up_and_settles()->void:
	var velocity:=Vector2.ZERO
	velocity=MapMotion.key_pan_step(velocity,Vector2.RIGHT,1.0/60.0)
	assert_float(velocity.x).is_greater(0.0)
	assert_float(velocity.x).is_less(0.3)
	for i in 30:velocity=MapMotion.key_pan_step(velocity,Vector2.RIGHT,1.0/60.0)
	assert_float(velocity.x).is_greater(0.99)
	assert_float(velocity.x).is_less_equal(1.0)
	for i in 60:velocity=MapMotion.key_pan_step(velocity,Vector2.ZERO,1.0/60.0)
	assert_vector(velocity).is_equal(Vector2.ZERO)

func test_reduced_motion_removes_coasting_and_shortens_glides()->void:
	var full:=_glide(14.2,150.0,600).size()
	Motion.reduce_motion=true
	assert_bool(MapMotion.reduced()).is_true()
	assert_vector(MapMotion.release_velocity(Vector3(5,0,0),4.0)).is_equal(Vector3.ZERO)
	assert_vector(MapMotion.coast_step(Vector3(5,0,0),1.0/60.0,4.0)).is_equal(Vector3.ZERO)
	assert_vector(MapMotion.key_pan_step(Vector2.ZERO,Vector2.RIGHT,1.0/60.0)).is_equal(Vector2.RIGHT)
	var reduced:=_glide(14.2,150.0,600).size()
	assert_int(reduced).is_less(full)
	assert_float(Motion.duration(Motion.SCENE)).is_equal(Motion.FAST)

func test_easing_curves_never_overshoot()->void:
	var previous_out:=0.0
	var previous_io:=0.0
	for i in 101:
		var t:=float(i)/100.0
		var a:=MapMotion.ease_out(t)
		var b:=MapMotion.ease_in_out(t)
		assert_bool(a>=previous_out-0.000001 and a<=1.0).is_true()
		assert_bool(b>=previous_io-0.000001 and b<=1.0).is_true()
		previous_out=a;previous_io=b
	assert_float(MapMotion.ease_out(1.0)).is_equal(1.0)
	assert_float(MapMotion.ease_in_out(1.0)).is_equal(1.0)
	assert_float(MapMotion.ease_in_out(0.0)).is_equal(0.0)
