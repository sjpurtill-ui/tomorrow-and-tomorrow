extends GdUnitTestSuite
## Synthetic furniture isolates the room contract from asset import/order.
const Paths:=preload("res://scripts/hud/court_paths.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Exec:=preload("res://scripts/hud/court_exec_stage.gd")

class Interior extends Node3D:
	var kind:="interior_seating_fixture"
	var marks:Dictionary={}
	var hearth:=false
	var info:Dictionary={"floor":"PLANK"}
	var temporary_fire:=false
	var temporary_at:=Vector3.ZERO
	func has_mark(key:String)->bool:return marks.has(key)
	func mark(key:String)->Marker3D:return marks.get(key)
	func has_hearth()->bool:return hearth
	func indoors()->bool:return true
	func marks_for(prefix:String)->Array[Marker3D]:
		var out:Array[Marker3D]=[]
		for key:String in marks:
			if key.begins_with(prefix):out.append(marks[key])
		return out
	func execution_fire(at:Vector3,on:bool)->void:temporary_at=at;temporary_fire=on
	func add_mark(key:String,at:Vector3)->Marker3D:
		var m:=Marker3D.new();m.name=key;add_child(m);m.position=at;marks[key]=m
		return m

class QuietStage extends Stage:
	func _ready()->void:pass

class SoundCapture extends Node:
	var heard:Dictionary={}
	func ambience(_kind:String,_season:String,room_facts:Dictionary)->void:heard=room_facts

func _room()->Interior:
	var court:Interior=auto_free(Interior.new());add_child(court)
	var model:=Node3D.new();model.name="Model";court.add_child(model)
	court.add_mark("door",Vector3(3,0,3));court.add_mark("door_out",Vector3(4,0,3))
	court.add_mark("focus",Vector3(0,0,3));court.add_mark("execution",Vector3(1,0,3))
	var seat:=court.add_mark("officials_0",Vector3(-2,0,0))
	seat.rotation.y=PI
	seat.set_meta("sit",true);seat.set_meta("external_seat",true);seat.set_meta("seat",0.47)
	seat.set_meta("seat_exit",[-2,0,1.15])
	_box(model,"ChairSeat",Vector3(-2,0.43,0),Vector3(.54,.08,.56))
	_box(model,"ChairBack",Vector3(-2,.75,-.32),Vector3(.54,.7,.08))
	_box(model,"Table",Vector3(0,.75,0),Vector3(2,.15,3))
	return court

func _box(parent:Node,name:String,at:Vector3,size:Vector3)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name
	var box:=BoxMesh.new();box.size=size;mesh.mesh=box
	parent.add_child(mesh);mesh.position=at
	return mesh

func _stage(court:Interior)->QuietStage:
	var stage:QuietStage=auto_free(QuietStage.new());add_child(stage)
	stage.court_set=court
	stage.facts={"presentation":{"period":"modern","outfit":"tunic","rustic_props":false,"stance_policy":"seated"}}
	return stage

func test_chair_routes_use_the_authored_aisle_in_both_directions()->void:
	var court:=_room();var room:=Paths.room_of(court)
	var seat:=Vector2(-2,0);var approach:=Vector2(-2,1.15);var door:=Vector2(3,3)
	var way:=Paths.route_with_seats(court,room,seat,door)
	assert_int(way.size()).is_greater_equal(3)
	assert_vector(way[0]).is_equal(seat);assert_vector(way[1]).is_equal(approach)
	for i in range(1,way.size()-1):assert_bool(Paths.clear_line(room,way[i],way[i+1])).is_true()
	var back:=Paths.route_with_seats(court,room,door,seat)
	assert_vector(back[back.size()-2]).is_equal(approach)
	assert_vector(back[back.size()-1]).is_equal(seat)
	assert_bool(Paths.solid_at(room,seat)).is_true()
	# A chair back is still physical, including on the explicit seat leg.
	court.mark("officials_0").set_meta("seat_exit",[-2,0,-1.15])
	assert_int(Paths.route_with_seats(court,room,seat,door).size()).is_equal(0)
	# An erroneous approach through the table is rejected, never dug through.
	court.mark("officials_0").set_meta("seat_exit",[1,0,0])
	assert_int(Paths.route_with_seats(court,room,seat,door).size()).is_equal(0)

func test_same_named_chapters_do_not_share_stale_furniture_or_hearth_obstacles()->void:
	var first:=_room();var original:=Paths.room_of(first)
	var other:=_room()
	other.get_node("Model/Table").position.x=3.0
	var changed:=Paths.room_of(other)
	assert_bool(original==changed).is_false()
	assert_bool(Paths.solid_at(original,Vector2.ZERO)).is_true()
	assert_bool(Paths.solid_at(changed,Vector2.ZERO)).is_false()
	other.add_mark("fire",Vector3(-3,0,3))
	var cold:=Paths.room_of(other)
	assert_bool(Paths.solid_at(cold,Vector2(-3,3))).is_false()
	other.hearth=true
	assert_bool(Paths.solid_at(Paths.room_of(other),Vector2(-3,3))).is_true()

func test_a_diagonal_chair_and_bent_access_keep_the_real_back_solid()->void:
	var court:=_room()
	court.get_node("Model/ChairSeat").free();court.get_node("Model/ChairBack").free()
	var chair:=Node3D.new();chair.name="DiagonalChair";court.get_node("Model").add_child(chair)
	chair.position=Vector3(-2,0,0);chair.rotation.y=-.55
	_box(chair,"Seat",Vector3(0,.435,0),Vector3(.56,.07,.56))
	_box(chair,"Back",Vector3(0,.75,-.245),Vector3(.55,.5,.08))
	var front:=chair.transform*Vector3(0,0,.55)
	var exit:=chair.transform*Vector3(-.7,0,1.15)
	var mark:=court.mark("officials_0")
	mark.set_meta("seat_approach",[front.x,0,front.z]);mark.set_meta("seat_exit",[exit.x,0,exit.z])
	var room:=Paths.room_of(court)
	var route:=Paths.route_with_seats(court,room,Vector2(-2,0),Vector2(3,3))
	assert_int(route.size()).is_greater_equal(4)
	assert_vector(route[1]).is_equal(Vector2(front.x,front.z))
	assert_vector(route[2]).is_equal(Vector2(exit.x,exit.z))
	var behind:=chair.transform*Vector3(0,0,-1.15)
	assert_bool(Paths._seat_geometry_clear(court,Vector2(-2,0),Vector2(behind.x,behind.z),.57)).is_false()

func test_authored_official_chair_has_no_portable_stool_and_only_sits_after_arrival()->void:
	var court:=_room();var stage:=_stage(court)
	var person:=Stage.Figure.new();stage.add_child(person)
	person.key="official";person.role="court";person.person={"name":"Clerk","sex":"male","age":37}
	stage.figures[person.key]=person;stage.cast_order.append(person.key)
	stage._embody(person)
	assert_object(person.body3d).is_not_null()
	assert_bool(person.external_seat).is_true()
	assert_str(person.rest_clip).is_equal("sit")
	var stool:MeshInstance3D=person.body3d._mesh_named("prop_stool")
	assert_bool(stool.visible).is_false()
	person.enter_from(1,3,.2);person._move.pause()
	assert_str(String(person.body3d.clip)).is_equal("walk_in")
	assert_str(String(person.body3d.stance)).is_equal("stand")
	for i in 240:
		if not person._move.is_valid():break
		person._move.custom_step(1.0/30.0)
	assert_str(String(person.body3d.clip)).is_equal("sit")
	assert_str(String(person.body3d.stance)).is_equal("sit")
	assert_bool(stool.visible).is_false()
	person.leave(1,3,1,"nod");person._move.pause();person._move.custom_step(.5)
	assert_str(String(person.body3d.clip)).is_equal("stand")
	assert_str(String(person.body3d.stance)).is_equal("stand")
	assert_bool(stool.visible).is_false()
	assert_vector(person._path[1]).is_equal_approx(Vector3(0,0,1.15),Vector3.ONE*.001)
	person._move.kill()

func test_unreachable_room_route_never_falls_back_through_furniture()->void:
	var court:=_room();var stage:=_stage(court)
	_box(court.get_node("Model"),"Wall",Vector3(0,.8,2),Vector3(30,1.6,.3))
	var person:=Stage.Figure.new();stage.add_child(person)
	person.spot=Node3D.new();court.add_child(person.spot);person.spot.position=Vector3(-2,0,0)
	person._stage=weakref(stage)
	var way:=person._route(Vector3(5,0,3))
	assert_int(way.size()).is_equal(2)
	assert_vector(way[0]).is_equal(way[1])

func test_no_hearth_execution_uses_explicit_mark_and_leaves_no_temporary_fire()->void:
	var court:=_room();var stage:=_stage(court)
	var execution:=Exec.new();stage.add_child(execution);execution.stage=stage;execution.victim="absent"
	assert_vector(execution.point("fire")).is_equal(court.mark("execution").global_position)
	assert_vector(stage.focus_point()).is_equal(court.mark("focus").global_position)
	# Cleanup must work even when the victim was removed during a skip.
	court.execution_fire(execution.point("fire"),true);execution._temporary_fire=true
	execution.skip()
	assert_bool(court.temporary_fire).is_false()
	assert_bool(court.has_mark("fire")).is_false()

func test_room_sound_receives_actual_floor_and_hearth_without_mutating_facts()->void:
	var court:=_room();var stage:=_stage(court)
	var sound:=SoundCapture.new();stage.add_child(sound);stage._sound=sound
	stage._ambience()
	assert_bool(sound.heard.has_hearth).is_false()
	assert_bool(sound.heard.indoor).is_true()
	assert_str(sound.heard.floor).is_equal("PLANK")
	assert_bool(stage.facts.has("has_hearth")).is_false()
