extends GdUnitTestSuite
## THE COURT'S MODELLED SET (scripts/hud/court_set_3d.gd, court_camera.gd,
## court_animal_3d.gd). The court is a real place that grows with the people:
## - every set has the marks the stage and the director stand people on
##   (throne_gaze, petitioner, officials_*, crowd_*, envoy_*, fire, door,
##   animal_*), and a mark faces the way a person there should;
## - the court's civic stage picks the set, and a set not built yet falls
##   back to the nearest that is;
## - the props answer the facts: fuller baskets and racks with fuller stores,
##   more spears in war;
## - the camera's shots frame their subjects inside the free part of the view;
## - a dog in every age, herd animals and fowl only once the people keep them.
## Headless: nothing is drawn; nothing reads or writes the game's state.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const CourtCamera:=preload("res://scripts/hud/court_camera.gd")

const MARKS:=["throne_gaze","petitioner","fire","door","door_out","officials_0","officials_3","crowd_0","envoy_0","envoy_2","animal_0"]


func _built(era:String,facts:Dictionary={})->Node3D:
	var made:Node3D=CourtSet.build(era,facts)
	add_child(made)
	return auto_free(made)


func test_every_built_set_has_its_marks()->void:
	var sets:Dictionary=CourtSet.manifest().get("sets",{})
	assert_bool(sets.has("fire_ring")).is_true()
	assert_bool(sets.has("longhouse")).is_true()
	for kind:String in sets.keys():
		var made:=_built(kind)
		for mark_name:String in MARKS:
			assert_bool(made.call("has_mark",mark_name)).override_failure_message("%s lacks %s" % [kind,mark_name]).is_true()
		assert_int((made.call("marks_for","officials_") as Array).size()).is_greater_equal(4)
		assert_int((made.call("marks_for","crowd_") as Array).size()).is_greater_equal(4)


func test_marks_face_the_god_or_the_fire()->void:
	var made:=_built("hearth_council")
	var god:Vector3=made.call("god_point")
	var petitioner:Marker3D=made.call("mark","petitioner")
	var to_god:=(god-petitioner.position)
	to_god.y=0.0
	# a figure's front is +Z: the petitioner's +Z points at the god
	assert_float(petitioner.basis.z.normalized().dot(to_god.normalized())).is_greater(0.95)
	var fire:Marker3D=made.call("mark","fire")
	for crowd:Marker3D in made.call("marks_for","crowd_"):
		var to_fire:=fire.position-crowd.position
		to_fire.y=0.0
		assert_float(crowd.basis.z.normalized().dot(to_fire.normalized())).is_greater(0.95)


func test_sit_marks_carry_a_seat()->void:
	for era in ["hearth_council","chiefs_hall"]:
		var made:=_built(era)
		var sitting:=0
		for crowd:Marker3D in made.call("marks_for","crowd_"):
			if bool(crowd.get_meta("sit",false)):
				sitting+=1
				assert_float(float(crowd.get_meta("seat",0.0))).is_between(0.3,0.8)
				assert_float(crowd.position.y).is_equal_approx(0.0,0.01)
		assert_int(sitting).is_greater_equal(2)


func test_the_court_grows_with_the_people()->void:
	assert_str(CourtSet.kind_for("hearth_council",0)).is_equal("fire_ring")
	assert_str(CourtSet.kind_for("fire_circle",0)).is_equal("fire_ring")
	assert_str(CourtSet.kind_for("chiefs_hall",1)).is_equal("longhouse")
	assert_str(CourtSet.kind_for("tier_1")).is_equal("longhouse")
	# sets not built yet stand in with the nearest that is
	assert_str(CourtSet.kind_for("temple_palace",2)).is_not_empty()
	assert_bool((CourtSet.manifest().sets as Dictionary).has(CourtSet.kind_for("imperial_court",4))).is_true()
	assert_bool((CourtSet.manifest().sets as Dictionary).has(CourtSet.kind_for("elders_circle",0))).is_true()
	assert_str(CourtSet.kind_for("no_such_stage")).is_equal("fire_ring")


func test_props_answer_the_stores_and_war()->void:
	for era in ["hearth_council","chiefs_hall"]:
		var made:=_built(era,{"food":1.0,"war":false})
		var full:=int(made.call("shown","food"))
		var full_rack:=int(made.call("shown","rack"))
		var peace:=int(made.call("shown","spears"))
		assert_int(full).is_greater_equal(4)
		made.call("apply_facts",{"food":0.0})
		assert_int(int(made.call("shown","food"))).is_equal(0)
		assert_int(int(made.call("shown","rack"))).is_equal(0)
		made.call("apply_facts",{"food":0.5})
		var half:=int(made.call("shown","food"))
		assert_int(half).is_greater(0)
		assert_int(half).is_less(full)
		assert_int(int(made.call("shown","rack"))).is_less(full_rack)
		made.call("apply_facts",{"war":true})
		assert_int(int(made.call("shown","spears"))).is_greater(peace)


func test_a_dog_always_herds_and_fowl_only_when_kept()->void:
	assert_array(CourtSet.animals_for({})).contains(["dog"])
	assert_array(CourtSet.animals_for({})).not_contains(["goat","hen"])
	assert_array(CourtSet.animals_for({"herds":true})).contains(["dog","goat"])
	assert_array(CourtSet.animals_for({"fowl":true})).contains(["hen"])
	var made:=_built("hearth_council")
	var dog:Node3D=made.call("animal","dog")
	assert_object(dog).is_not_null()
	# it starts on an animal mark, and it has its clips
	var player:AnimationPlayer=dog.get("player")
	for clip in ["idle","walk","trot","sniff","sit","scratch","cower","lie","tilt","bark","grab"]:
		assert_bool(player.has_animation(clip)).override_failure_message("dog lacks %s" % clip).is_true()


func test_dog_answers_the_god()->void:
	var made:=_built("hearth_council")
	var dog:Node3D=made.call("animal","dog")
	dog.call("on_god","wrath")
	assert_str(String(dog.get("clip"))).is_equal("cower")
	assert_str(String(dog.get("mood"))).is_equal("afraid")
	dog.call("on_god","favour")
	assert_str(String(dog.get("clip"))).is_equal("wag")


func test_camera_frames_its_subjects_in_the_free_view()->void:
	var view:=SubViewport.new();view.size=Vector2i(1318,330);view.own_world_3d=true
	add_child(view);auto_free(view)
	var made:Node3D=CourtSet.build("hearth_council",{})
	view.add_child(made)
	var cam:Camera3D=made.get("camera")
	cam.call("set_insets",40.0,40.0)
	var subjects:Array=[]
	for key in ["petitioner","officials_0","officials_1","officials_2","officials_3"]:
		subjects.append((made.call("mark",key) as Marker3D).position)
	cam.call("wide",subjects,0.0)
	for p:Vector3 in subjects:
		for point in [p,p+Vector3.UP*1.7]:
			var px:=cam.unproject_position(point)
			assert_bool(cam.is_position_behind(point)).is_false()
			assert_float(px.x).is_between(0.0,1318.0)
			# feet above the name plates, heads below the buttons
			assert_float(px.y).is_between(40.0,330.0-40.0+1.0)
	# three-quarter from above, never a flat lineup
	var yaw:=rad_to_deg(atan2(cam.global_transform.basis.z.x,cam.global_transform.basis.z.z))
	assert_float(absf(yaw)).is_greater(10.0)
	assert_float(cam.global_position.y).is_greater(1.8)
	# a reaction comes closer than the wide shot
	var wide_dist:=cam.global_position.distance_to(subjects[1])
	cam.call("reaction",subjects[1],0.0)
	assert_float(cam.global_position.distance_to(subjects[1])).is_less(wide_dist)


func test_set_rests_when_hidden()->void:
	var made:=_built("chiefs_hall")
	made.call("set_active",false)
	assert_bool(made.is_processing()).is_false()
	for p:GPUParticles3D in made.get("particles"):
		assert_bool(p.emitting).is_false()
	made.call("set_active",true)
	assert_bool(made.is_processing()).is_true()
