extends GdUnitTestSuite
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
var _reduce_before:=false

func before_test()->void:
	_reduce_before=Motion.reduce_motion
	Motion.reduce_motion=false

func after_test()->void:
	Motion.reduce_motion=_reduce_before

func _room(kind:="chapter_15",chapter:Dictionary={})->Node3D:
	var facts:={"dogs":false,"herds":false,"fowl":false}
	if not chapter.is_empty():facts.chapter=chapter
	var room:=CourtSet.build(kind,facts)
	add_child(room);auto_free(room)
	return room

func _body(room:Node3D,at:=Vector3(-1,0,1))->Node3D:
	var body:=Node3D.new();room.add_child(body);body.position=at
	return body

func test_each_indoor_chapter_uses_an_actual_opening()->void:
	for index in range(1,16):
		var room:=_room("chapter_%02d" % index)
		var body:=_body(room)
		room.god_light(body,"wrath",0.0,0.0)
		var source:Vector3=room.god_shaft.global_transform*Vector3(0,.5,0)
		var belongs:=false
		for opening:Array in room.info.apertures:
			if absf(source.x-float(opening[0]))<.01 and source.y>float(opening[2]) and source.y<float(opening[3]) and absf(source.z+3.78)<.01:belongs=true
		assert_bool(belongs).override_failure_message("chapter %d has no authored source" % index).is_true()
		assert_float(room.god_spot.global_basis.z.dot((room.god_spot.global_position-body.global_position-Vector3.UP).normalized())).is_greater(.999)

func test_mirrored_renewal_and_transformed_room_keep_beam_on_window()->void:
	var room:=_room("chapter_07",{"limited":true,"renewal":1,"set_kind":"chapter_07"})
	room.position=Vector3(20,4,-5);room.rotation.y=.7
	var body:=_body(room)
	room.god_light(body,"speaks",0.0,0.0)
	var source:=room.to_local(room.god_shaft.global_transform*Vector3(0,.5,0))
	var belongs:=false
	for opening:Array in room.info.apertures:
		if absf(source.x-float(opening[0])*room.model.scale.x)<.01:belongs=true
	assert_bool(belongs).is_true()
	assert_float(source.z).is_equal_approx(-3.78,.001)
	assert_vector(room.god_pool.global_position).is_equal_approx(body.global_position+Vector3(0,.03,0),Vector3.ONE*.001)

func test_light_follows_walking_listener_without_jumping_windows()->void:
	var room:=_room();var body:=_body(room)
	room.god_light(body,"speaks",0.0,0.0)
	var source:Vector3=room._god_origin
	body.position.x+=3.0;room._process(.2)
	assert_vector(room._god_target).is_equal(body.global_position)
	assert_vector(room._god_origin).is_equal(source)
	assert_float(room.god_pool.global_position.x).is_equal_approx(body.global_position.x,.001)
	var to_body:Vector3=(body.global_position+Vector3.UP-room.god_spot.global_position).normalized()
	assert_float((-room.god_spot.global_basis.z).dot(to_body)).is_greater(.999)

func test_retargeted_light_does_not_follow_previous_listener()->void:
	var room:=_room();var first:=_body(room);var next:=_body(room,Vector3(2,0,1))
	room.god_light(first,"wrath",0.0,0.0)
	room.god_light(next,"favour",0.0,0.0)
	first.position.x+=4.0;room._process(.1)
	assert_vector(room._god_target).is_equal(next.global_position)
	room.god_light(Vector3.ZERO,"speaks",0.0,0.0)
	next.position.x+=2.0;room._process(.1)
	assert_vector(room._god_target).is_equal(Vector3.ZERO)

func test_hidden_and_freed_listener_release_light_without_retargeting()->void:
	var room:=_room();var body:=_body(room)
	room.god_light(body,"wrath",0.0,0.0)
	body.hide();room._process(.1)
	assert_str(room.god_tone).is_equal("off")
	assert_object(room._god_target_ref).is_null()
	body.show();room.god_light(body,"favour",0.0,0.0)
	body.free();room._process(.1)
	assert_str(room.god_tone).is_equal("off")

func test_held_light_obeys_quality_and_hidden_modal_immediately()->void:
	var room:=_room();room.set_quality("high")
	room.god_light(_body(room),"favour",0.0,0.0)
	assert_bool(room.god_dust.emitting).is_true()
	room.set_quality("low")
	assert_bool(room.god_dust.visible).is_false()
	assert_bool(room.god_dust.emitting).is_false()
	room.set_quality("high");room.set_active(false)
	for part:Node3D in [room.god_dust,room.god_pool,room.god_spot,room.god_shaft]:assert_bool(part.visible).is_false()
	assert_float(room.god_dust.speed_scale).is_equal(0.0)
	room.set_active(true)
	assert_bool(room.god_spot.visible).is_true()
	assert_bool(room.god_dust.emitting).is_true()

func test_reduced_motion_has_still_light_without_wind_or_motes()->void:
	var room:=_room("longhouse");var body:=_body(room)
	Motion.reduce_motion=true
	var original:Basis=room.sun.basis
	room.god_light(body,"wrath",0.0,0.0)
	assert_bool(room.sun.basis.is_equal_approx(original)).is_true()
	assert_bool(room.god_dust.emitting).is_false()
	assert_float(float(room._god_shaft_mat.get_shader_parameter("motion"))).is_equal(0.0)
	for mat:ShaderMaterial in room._gust_mats:assert_float(float(mat.get_shader_parameter("gust"))).is_equal(0.0)
	Motion.reduce_motion=false;room._process(.1)
	assert_float(float(room._god_shaft_mat.get_shader_parameter("motion"))).is_equal(1.0)
	assert_bool(room.god_spot.visible).is_true()

func test_wrath_hush_survives_frames_and_authored_braziers_keep_their_energy()->void:
	var room:=_room("longhouse");var body:=_body(room)
	room.god_light(body,"wrath",0.0,0.0)
	for frame in 12:
		room._process(.1)
		assert_float(room.bounce.light_energy).is_less(.20)
		for i in room.flame_lights.size():assert_float(room.flame_lights[i].light_energy).is_less(room._flame_energies[i]*.5)
	room.god_light(null,"off",0.0,0.0);room._process(.1)
	assert_float(room.bounce.light_energy).is_between(.39,.51)
	for i in room.flame_lights.size():assert_float(room.flame_lights[i].light_energy).is_between(room._flame_energies[i]*.8,room._flame_energies[i]*1.2)

func test_new_address_during_release_restores_original_room()->void:
	var room:=_room();var body:=_body(room)
	var ambient:float=room.world_env.environment.ambient_light_energy
	var fills:Array=[]
	for fill:OmniLight3D in room.fill_lights:fills.append(fill.light_energy)
	room.god_light(body,"wrath",0.0,0.0)
	room.god_light(null,"off",0.0,1.0)
	room._god_step(.999)
	room.god_light(body,"favour",0.0,0.0)
	room.god_light(null,"off",0.0,0.0)
	assert_float(room.world_env.environment.ambient_light_energy).is_equal_approx(ambient,.00001)
	for i in fills.size():assert_float(room.fill_lights[i].light_energy).is_equal_approx(float(fills[i]),.00001)

func test_direct_cue_does_not_inherit_old_spoken_release()->void:
	var room:=_room();var body:=_body(room)
	room.god_moment(body,"wrath",1.0)
	room.god_light(body,"favour",1.0,0.0)
	assert_float(room._god_out).is_equal(-1.0)

func test_old_hold_callback_cannot_extinguish_new_address()->void:
	var room:=_room();var first:=_body(room);var next:=_body(room,Vector3(2,0,1))
	room.god_light(first,"wrath",.02,0.0)
	room.god_light(next,"favour",.5,0.0)
	await get_tree().create_timer(.07).timeout
	assert_str(room.god_tone).is_equal("favour")
	assert_vector(room._god_target).is_equal(next.global_position)
	assert_bool(room.god_spot.visible).is_true()

func test_quality_change_during_wrath_restores_new_shadow_quality()->void:
	var room:=_room();room.set_quality("high")
	room.god_light(_body(room),"wrath",0.0,0.0)
	room.set_quality("low")
	assert_float(room.sun.shadow_blur).is_equal_approx(.2,.001)
	room.god_light(null,"off",0.0,0.0)
	assert_float(room.sun.shadow_blur).is_equal(1.0)
