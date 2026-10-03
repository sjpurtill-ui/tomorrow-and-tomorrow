extends GdUnitTestSuite
## THE COURT'S MODELLED SET (scripts/hud/court_set_3d.gd, court_camera.gd,
## court_animal_3d.gd). The court is a real place that grows with the people:
## - every set has the marks the stage and the director stand people on
##   (throne_gaze, petitioner, officials_*, crowd_*, envoy_*, fire, door,
##   animal_*), and a mark's -Z faces the way a person there should;
## - the court's civic stage picks the set: the fire ring, the shelter, the
##   longhouse, the mudbrick hall, the grand hall;
## - the props answer the facts, in the stage's own words (food_days, hungry,
##   war): fuller baskets with fuller stores, every spear racked in war, and
##   pots, looms and tablets only once the people know how to make them;
## - the camera's shots frame their subjects inside the free part of the
##   view; on the court's wide strip the one before the god fills it;
## - the camera rig takes the stage's camera and its shots by name;
## - a dog in every age, herd animals and fowl only once the people keep them.
## Headless: nothing is drawn; nothing reads or writes the game's state.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const CourtCamera:=preload("res://scripts/hud/court_camera.gd")

const KINDS:=["fire_ring","shelter","longhouse","mudbrick_hall","grand_hall"]
const MARKS:=["throne_gaze","petitioner","fire","door","door_out","officials_0","officials_3","crowd_0","envoy_0","envoy_2","animal_0"]


func _built(era:String,facts:Dictionary={})->Node3D:
	var made:Node3D=CourtSet.build(era,facts)
	add_child(made)
	return auto_free(made)


func test_every_set_is_built_with_its_marks()->void:
	var sets:Dictionary=CourtSet.manifest().get("sets",{})
	for kind:String in KINDS:
		assert_bool(sets.has(kind)).override_failure_message("no %s set" % kind).is_true()
		var made:=_built(kind)
		assert_str(String(made.get("kind"))).is_equal(kind)
		for mark_name:String in MARKS:
			assert_bool(made.call("has_mark",mark_name)).override_failure_message("%s lacks %s" % [kind,mark_name]).is_true()
		assert_int((made.call("marks_for","officials_") as Array).size()).is_greater_equal(4)
		assert_int((made.call("marks_for","crowd_") as Array).size()).is_greater_equal(4)
		# modest: a mid-range laptop draws it
		assert_int(int((sets[kind] as Dictionary).get("triangles",0))).is_less(90000)


func test_marks_face_the_god_or_the_fire_along_minus_z()->void:
	for kind:String in KINDS:
		var made:=_built(kind)
		var god:Vector3=made.call("god_point")
		var petitioner:Marker3D=made.call("mark","petitioner")
		var to_god:=god-petitioner.position
		to_god.y=0.0
		assert_float((-petitioner.basis.z).normalized().dot(to_god.normalized())).is_greater(0.95)
		var fire:Marker3D=made.call("mark","fire")
		for crowd:Marker3D in made.call("marks_for","crowd_"):
			var to_fire:=fire.position-crowd.position
			to_fire.y=0.0
			assert_float((-crowd.basis.z).normalized().dot(to_fire.normalized())).is_greater(0.95)


func test_place_turns_a_figure_front_to_the_mark()->void:
	var made:=_built("hearth_council")
	var body:=Node3D.new()
	made.add_child(body)
	made.call("place",body,"petitioner")
	var m:Marker3D=made.call("mark","petitioner")
	# a figure's front is +Z: it ends up along the mark's -Z
	assert_float(body.global_transform.basis.z.dot(-m.global_transform.basis.z)).is_greater(0.99)
	assert_vector(body.global_position).is_equal_approx(m.global_position,Vector3(0.01,0.01,0.01))


func test_the_stage_s_cast_is_given_marks()->void:
	var made:=_built("hearth_council")
	var cast:=[{"key":"main","role":"main","stance":"clasped"},{"key":"p1","role":"court","stance":"staff"},
		{"key":"p2","role":"court","stance":"sit"},{"key":"p3","role":"court","stance":"hip"}]
	var marks:Dictionary=made.call("assign_marks",cast,"home")
	assert_str(String(marks.main)).is_equal("petitioner")
	assert_str(String(marks.p1)).is_equal("officials_0")
	# the one who sits takes a seat
	assert_bool(bool((made.call("mark",String(marks.p2)) as Marker3D).get_meta("sit",false))).is_true()
	assert_str(String(marks.p3)).is_equal("officials_1")
	var envoy:Dictionary=made.call("assign_marks",[{"key":"main","role":"main"},{"key":"att0","role":"attendant"},{"key":"att1","role":"attendant"}],"envoy")
	assert_str(String(envoy.main)).is_equal("envoy_0")
	assert_str(String(envoy.att0)).is_equal("envoy_1")
	assert_str(String(envoy.att1)).is_equal("envoy_2")
	# nobody shares a mark, however many there are
	var many:Array=[]
	for i in 30:many.append({"key":"k%d" % i,"role":"court","stance":"stand"})
	var spread:Dictionary=made.call("assign_marks",many,"home")
	var seen:={}
	for key in spread:
		assert_bool(seen.has(spread[key])).is_false()
		seen[spread[key]]=true


func test_sit_marks_carry_a_seat()->void:
	for era in ["hearth_council","elders_circle","chiefs_hall","temple_palace","imperial_court"]:
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
	assert_str(CourtSet.kind_for("hearth_council",1)).is_equal("shelter")
	assert_str(CourtSet.kind_for("elders_circle",0)).is_equal("shelter")
	assert_str(CourtSet.kind_for("chiefs_hall",1)).is_equal("longhouse")
	assert_str(CourtSet.kind_for("temple_palace",2)).is_equal("mudbrick_hall")
	assert_str(CourtSet.kind_for("palace_bureaucracy",2)).is_equal("mudbrick_hall")
	assert_str(CourtSet.kind_for("imperial_court",4)).is_equal("grand_hall")
	assert_str(CourtSet.kind_for("estates_assembly",4)).is_equal("grand_hall")
	assert_str(CourtSet.kind_for("tier_1")).is_equal("longhouse")
	assert_str(CourtSet.kind_for("no_such_stage")).is_equal("fire_ring")


func test_props_answer_the_stores_and_war()->void:
	for era in ["hearth_council","elders_circle","chiefs_hall","temple_palace","imperial_court"]:
		var made:=_built(era,{"food":1.0,"war":false})
		var full:=int(made.call("shown","food"))
		var peace:=int(made.call("shown","spears"))
		assert_int(full).is_greater_equal(4)
		made.call("apply_facts",{"food":0.0})
		assert_int(int(made.call("shown","food"))).is_equal(0)
		assert_int(int(made.call("shown","rack"))).is_equal(0)
		made.call("apply_facts",{"food":0.5})
		var half:=int(made.call("shown","food"))
		assert_int(half).is_greater(0)
		assert_int(half).is_less(full)
		made.call("apply_facts",{"war":true})
		assert_int(int(made.call("shown","spears"))).is_greater(peace)


func test_the_stage_s_own_fact_names_are_understood()->void:
	var made:=_built("hearth_council",{"food_days":60,"war":{}})
	var full:=int(made.call("shown","food"))
	var peace:=int(made.call("shown","spears"))
	made.call("apply_facts",{"food_days":1})
	assert_int(int(made.call("shown","food"))).is_less(full)
	made.call("apply_facts",{"food_days":40,"hungry":true})
	assert_int(int(made.call("shown","food"))).is_less_equal(1)
	made.call("apply_facts",{"war":{"enemy":"Varrow","kind":"war"}})
	assert_int(int(made.call("shown","spears"))).is_greater(peace)
	made.call("apply_facts",{"war":{},"at_war":false})
	assert_int(int(made.call("shown","spears"))).is_equal(peace)
	assert_bool(bool(CourtSet.normal_facts({"era_tags":["dairy"]}).get("herds",false))).is_true()


func test_things_appear_only_once_the_people_can_make_them()->void:
	var early:=_built("hearth_council",{"era_tags":[]})
	assert_bool(early.call("gate_shown","pottery")).is_false()
	assert_bool(early.call("gate_shown","no_pottery")).is_true()
	early.call("apply_facts",{"era_tags":["pottery"]})
	assert_bool(early.call("gate_shown","pottery")).is_true()
	assert_bool(early.call("gate_shown","no_pottery")).is_false()
	var hall:=_built("chiefs_hall",{"era_tags":["pottery"]})
	assert_bool(hall.call("gate_shown","weaving")).is_false()
	hall.call("apply_facts",{"era_tags":["pottery","weaving"]})
	assert_bool(hall.call("gate_shown","weaving")).is_true()
	var temple:=_built("temple_palace",{"era_tags":["pottery"]})
	assert_bool(temple.call("gate_shown","writing")).is_false()
	temple.call("apply_facts",{"era_tags":["pottery","writing"]})
	assert_bool(temple.call("gate_shown","writing")).is_true()


func test_a_dog_always_herds_and_fowl_only_when_kept()->void:
	assert_array(CourtSet.animals_for({})).contains(["dog"])
	assert_array(CourtSet.animals_for({})).not_contains(["goat","hen"])
	assert_array(CourtSet.animals_for({"herds":true})).contains(["dog","goat"])
	assert_array(CourtSet.animals_for({"fowl":true})).contains(["hen"])
	var made:=_built("hearth_council")
	var dog:Node3D=made.call("animal","dog")
	assert_object(dog).is_not_null()
	var player:AnimationPlayer=dog.get("player")
	for clip in ["idle","walk","trot","sniff","sit","scratch","cower","lie","lie_idle","tilt","bark","grab"]:
		assert_bool(player.has_animation(clip)).override_failure_message("dog lacks %s" % clip).is_true()


func test_dog_answers_the_god()->void:
	var made:=_built("hearth_council")
	var dog:Node3D=made.call("animal","dog")
	dog.call("on_god","wrath")
	assert_str(String(dog.get("clip"))).is_equal("cower")
	assert_str(String(dog.get("mood"))).is_equal("afraid")
	dog.call("on_god","favour")
	assert_str(String(dog.get("clip"))).is_equal("wag")


func test_herd_goat_comes_with_kept_herds_and_answers_in_its_own_way()->void:
	var none:=_built("chiefs_hall",{"era_tags":["pottery"]})
	assert_object(none.call("animal","goat")).is_null()
	var kept:=_built("chiefs_hall",{"era_tags":["pottery","dairy"]})
	var goat:Node3D=kept.call("animal","goat")
	assert_object(goat).is_not_null()
	var player:AnimationPlayer=goat.get("player")
	for clip in ["idle","graze","bleat","walk","startle","lie","look"]:
		assert_bool(player.has_animation(clip)).override_failure_message("goat lacks %s" % clip).is_true()
	# the court's acts in the goat's own way: sniffing is grazing, wrath a startle
	goat.call("play","sniff",0.0)
	assert_str(String(goat.get("clip"))).is_equal("graze")
	goat.call("on_god","wrath")
	assert_str(String(goat.get("clip"))).is_equal("startle")


func _strip_view(era:String,w:int,h:int)->Array:
	var view:=SubViewport.new();view.size=Vector2i(w,h);view.own_world_3d=true
	add_child(view);auto_free(view)
	var made:Node3D=CourtSet.build(era,{})
	view.add_child(made)
	return [view,made]


func test_camera_frames_its_subjects_in_the_free_view()->void:
	var built:=_strip_view("hearth_council",1536,864)
	var made:Node3D=built[1]
	var rig:Node=made.get("rig")
	var lens:Camera3D=made.get("camera")
	rig.call("set_insets",40.0,40.0)
	var subjects:Array=[]
	for key in ["petitioner","officials_0","officials_1","officials_2","officials_3"]:
		subjects.append((made.call("mark",key) as Marker3D).position)
	rig.call("wide",subjects,0.0)
	for p:Vector3 in subjects:
		for point in [p,p+Vector3.UP*1.7]:
			var px:=lens.unproject_position(point)
			assert_bool(lens.is_position_behind(point)).is_false()
			assert_float(px.x).is_between(0.0,1536.0)
			assert_float(px.y).is_between(40.0,864.0-40.0+1.0)
	var yaw:=rad_to_deg(atan2(lens.global_transform.basis.z.x,lens.global_transform.basis.z.z))
	assert_float(absf(yaw)).is_greater(10.0)
	assert_float(lens.global_position.y).is_greater(1.5)
	var wide_dist:=lens.global_position.distance_to(subjects[1])
	rig.call("reaction",subjects[1],0.0)
	assert_float(lens.global_position.distance_to(subjects[1])).is_less(wide_dist)


func test_on_the_court_strip_the_one_before_the_god_fills_it()->void:
	var built:=_strip_view("hearth_council",1318,330)
	var made:Node3D=built[1]
	var rig:Node=made.get("rig")
	var lens:Camera3D=made.get("camera")
	rig.call("set_insets",40.0,40.0)
	var main:=(made.call("mark","petitioner") as Marker3D).position
	var subjects:Array=[main]
	for key in ["officials_0","officials_1","officials_2","officials_3","officials_4","officials_5"]:
		subjects.append((made.call("mark",key) as Marker3D).position)
	rig.call("wide",subjects,0.0,main)
	var head:=lens.unproject_position(main+Vector3.UP*1.7)
	var knee:=lens.unproject_position(main+Vector3.UP*0.5)
	# head below the buttons; from head to knee most of the strip's height
	assert_float(head.y).is_greater(35.0)
	assert_float(knee.y-head.y).is_greater(330.0*0.5)


func test_the_rig_takes_the_stage_s_camera_and_shots_by_name()->void:
	var built:=_strip_view("chiefs_hall",1318,330)
	var view:SubViewport=built[0];var made:Node3D=built[1]
	var stage_camera:=Camera3D.new();stage_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	view.add_child(stage_camera)
	var facade:Node=auto_free(CourtCamera.new())
	facade.call("attach",null,stage_camera,made)
	assert_bool(stage_camera.current).is_true()
	assert_int(stage_camera.projection).is_equal(Camera3D.PROJECTION_PERSPECTIVE)
	assert_object((made.get("rig") as Node).get("lens")).is_same(stage_camera)
	var before:=stage_camera.global_transform
	facade.call("shot","reaction",{"target":(made.call("mark","officials_0") as Marker3D).position})
	assert_bool(stage_camera.global_transform.is_equal_approx(before)).is_false()
	facade.call("shot","shake",{"strength":0.4})
	assert_bool((made.get("rig") as Node).call("is_moving")).is_true()


func test_set_rests_when_hidden()->void:
	var made:=_built("chiefs_hall")
	made.call("set_active",false)
	assert_bool(made.is_processing()).is_false()
	for p:GPUParticles3D in made.get("particles"):
		assert_bool(p.emitting).is_false()
	made.call("set_active",true)
	assert_bool(made.is_processing()).is_true()
