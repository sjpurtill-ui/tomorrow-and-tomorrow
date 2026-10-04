extends GdUnitTestSuite
## Imported room geometry, furnishing gates, and circulation across the timeline.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Chapters:=preload("res://scripts/hud/court_chapters.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")

func _capabilities(on:bool)->Dictionary:
	var out:Dictionary={}
	for key in Chapters.CAPABILITIES:out[key]=on
	return out

func _room(index:int,extra:Dictionary={})->Node3D:
	var facts:={"dogs":false,"herds":false,"fowl":false,"rustic_props":false,"season":"winter",
		"chapter":{"set_kind":"chapter_%02d" % index,"index":index,"design":index,"renewal":index,"lean":"throne","capabilities":_capabilities(true)}}
	facts.merge(extra,true)
	var made:=CourtSet.build("chapter_%02d" % index,facts)
	add_child(made);auto_free(made)
	return made

func test_all_sixteen_rooms_have_real_models_and_complete_marks()->void:
	for index in 16:
		var made:=_room(index)
		assert_str(String(made.kind)).is_equal("chapter_%02d" % index)
		assert_object(made.model).is_not_null()
		for mark in ["petitioner","door","door_out","focus","execution","officials_0","officials_5"]:
			assert_bool(made.has_mark(mark)).override_failure_message("%s missing %s" % [made.kind,mark]).is_true()
		var meshes:Array=made.model.find_children("*","MeshInstance3D",true,false)
		assert_int(meshes.size()).is_between(8,180)
		for node:MeshInstance3D in meshes:assert_object(node.mesh).is_not_null()

func test_enclosed_rooms_have_no_indoor_snow_breath_or_phantom_hearth()->void:
	for index in 16:
		var made:=_room(index)
		if made.indoors():
			assert_object(made.snowfall).is_null()
			assert_array(made.flies).is_empty()
			var body:=Node3D.new();made.add_child(body)
			assert_object(made.add_breath(body)).is_null()
			assert_object(made.find_child("Smoke",true,false)).is_null()
		if not made.has_hearth():
			assert_bool(made.has_mark("fire")).is_false()
			assert_object(made.fire_light).is_null()
			assert_object(made.bounce).is_null()
			assert_object(made.shimmer).is_null()
			assert_object(made.find_child("Smoke",true,false)).is_null()
			made._process(0.1)

func test_equipment_gates_resolve_real_meshes_and_follow_actual_capabilities()->void:
	for index in 16:
		var made:=_room(index)
		var specs:Dictionary=made.info.get("technology_gates",{})
		for key:String in specs:
			assert_bool(Chapters.CAPABILITIES.has(key.trim_prefix("no_"))).override_failure_message("unknown capability "+key).is_true()
			assert_int((made.technology_gates[key] as Array).size()).is_equal((specs[key] as Array).size())
		for enabled:bool in [false,true]:
			made.apply_facts({"chapter":{"capabilities":_capabilities(enabled),"lean":"assembly"}})
			for key:String in made.technology_gates:
				for node:Node3D in made.technology_gates[key]:
					assert_bool(node.visible).override_failure_message("%s %s" % [made.kind,key]).is_equal(enabled!=key.begins_with("no_"))

func test_every_room_has_a_clear_arrival_and_seat_approach()->void:
	for index in 16:
		var made:=_room(index)
		var room:=Paths.room_of(made)
		var door:Vector3=made.mark("door_out").position
		for key:String in made.marks:
			if not (key in ["petitioner","envoy_0","execution"] or key.begins_with("officials_")):continue
			var mark:Marker3D=made.mark(key)
			var goal:Vector3=mark.position
			if bool(mark.get_meta("external_seat",false)):
				assert_bool(mark.has_meta("seat_exit")).override_failure_message("%s %s missing chair approach" % [made.kind,key]).is_true()
				goal=CourtSet._vec(mark.get_meta("seat_exit",[goal.x,goal.y,goal.z]))
			var route:=Paths.route(room,Vector2(door.x,door.z),Vector2(goal.x,goal.z))
			assert_int(route.size()).override_failure_message("%s has no route to %s at %s" % [made.kind,key,goal]).is_greater_equal(2)
			if bool(mark.get_meta("external_seat",false)):
				var seated:=Paths.route_with_seats(made,room,Vector2(door.x,door.z),Vector2(mark.position.x,mark.position.z))
				assert_int(seated.size()).override_failure_message("%s has no complete chair route to %s" % [made.kind,key]).is_greater_equal(3)

func test_lagging_societies_renovate_without_new_materials_or_losing_routes()->void:
	var first:=_room(0,{"chapter":Chapters.derive(200.0*365.0,[])})
	var next:=_room(0,{"chapter":Chapters.derive(400.0*365.0,[])})
	assert_str(String(first.kind)).is_equal("chapter_00")
	assert_str(String(next.kind)).is_equal("chapter_00")
	assert_float(first.model.scale.x).is_less(0.0)
	assert_float(next.model.scale.x).is_greater(0.0)
	assert_str(Paths.room_of(first).key).is_not_equal(Paths.room_of(next).key)
	for made in [first,next]:
		var start:Vector3=made.mark("door_out").position
		var end:Vector3=made.mark("petitioner").position
		assert_int(Paths.route(Paths.room_of(made),Vector2(start.x,start.z),Vector2(end.x,end.z)).size()).is_greater_equal(2)

func test_explicit_fire_effect_is_temporary_in_a_conference_room()->void:
	var made:=_room(15)
	var before:=(made._flame_mats as Array).size()
	assert_object(made.find_child("ExecutionFire",true,false)).is_null()
	made.execution_fire(made.mark("execution").global_position,true)
	assert_object(made.get("_execution_fire")).is_not_null()
	assert_int((made._flame_mats as Array).size()).is_equal(before+3)
	made.execution_fire(Vector3.ZERO,false)
	await await_idle_frame()
	assert_object(made.find_child("ExecutionFire",true,false)).is_null()
	assert_int((made._flame_mats as Array).size()).is_equal(before)

func test_working_offices_do_not_rebuild_camp_trophies_from_lifetime_deaths()->void:
	for index in range(9,16):
		var made:=_room(index,{"executions":20,"execution_days":[0.0,1.0]})
		assert_int(int(made.facts.executions)).is_equal(20)
		for key in ["stakes","heap","stains"]:assert_int(int(made.trophies[key])).is_equal(0)

func test_office_finishes_do_not_inherit_peeling_plaster_or_banded_tapestries()->void:
	var medieval:=_room(8)
	assert_int(int(medieval._material("PLASTER",false).get_shader_parameter("pattern"))).is_equal(10)
	for index in range(10,16):
		var made:=_room(index)
		assert_int(int(made._material("PLASTER",false).get_shader_parameter("pattern"))).is_equal(0)
		assert_int(int(made._material("WEAVE_B",false).get_shader_parameter("pattern"))).is_equal(18)
		assert_int(int(made._material("PLANK",false).get_shader_parameter("pattern"))).is_equal(16)
