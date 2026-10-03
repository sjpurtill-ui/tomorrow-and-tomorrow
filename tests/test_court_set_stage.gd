extends GdUnitTestSuite
## THE COURT IN ITS MODELLED PLACE (court_stage.gd with court_set_3d.gd).
## When the set's models are there, the people of an audience stand in it:
## - the one before the god on the petitioner's mark (an envoy on the envoy's),
##   our officials in the arc about the fire, onlookers on the logs; the
##   painted backdrop steps aside and the set's camera frames them, clear of
##   the buttons laid over the stage;
## - their name plates and bubbles follow them on the screen as the camera moves;
## - they walk in from the door and leave by it, never through the fire;
## - they are lit by the set (and cast shadows), their eyes roll inside the
##   lids (the white writes a stencil the iris reads);
## - wrath jolts the frame and the dog cowers;
## - a dropped bowl lies on the floor and a bundle rides between the hands.
## Presentation only. Offline; never calls a real API or writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

var _root_size:=Vector2i.ZERO


func before_test()->void:
	Stage.directing=false
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	Fixtures.new(self).base(false)
	_root_size=get_tree().root.size
	get_tree().root.size=Vector2i(1920,1080)


func after_test()->void:
	Backdrop.tier_override=-1
	Stage.directing=true
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	get_tree().root.size=_root_size


func _home_audience()->String:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	return String(Hall.summon(target).get("id",""))


func _envoy_audience()->String:
	for kind in ["gift","news","request","threat","proposal"]:
		var made:=Hall.debug_force(kind)
		if not made.is_empty():return String(made.id)
	return ""


func _open(id:String)->Control:
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal()
	await await_idle_frame()
	return modal


func _ready_or_skip()->bool:
	if not CourtSet.available() or not Figure3D.available():
		push_warning("court set or figures not imported; set-stage tests skipped")
		return false
	return true


func test_the_people_stand_on_the_sets_marks_and_its_camera_frames_them()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	assert_object(stage.court_set).is_not_null()
	assert_bool(stage.view3d.transparent_bg).is_false()
	assert_object(stage.camera).is_same(stage.court_set.get("camera"))
	# The painting stays behind as the fallback, hidden.
	assert_bool(modal.backdrop.visible).is_false()
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	assert_str(main.mark_name).is_equal("petitioner")
	stage.settle()
	var seen:=0
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f==null or f.body3d==null:continue
		seen+=1
		assert_object(f.spot).is_not_null()
		if f.role=="court":assert_bool(f.mark_name.begins_with("officials_") or f.mark_name.begins_with("crowd_")).is_true()
		# Their box on the screen stands over their feet in the set.
		var feet:Vector2=stage.world_to_stage(f.body3d.global_position)
		assert_float(feet.distance_to(f.home)).override_failure_message("%s: box at %s, feet at %s" % [key,f.home,feet]).is_less(3.0)
	assert_int(seen).is_greater_equal(2)
	# Nobody shares a mark.
	var marks:={}
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f!=null and not f.mark_name.is_empty():
			assert_bool(marks.has(f.mark_name)).override_failure_message("two on "+f.mark_name).is_false()
			marks[f.mark_name]=key


func test_an_envoy_stands_on_the_envoys_mark_with_their_company_behind()->void:
	if not _ready_or_skip():return
	var id:=_envoy_audience()
	if id.is_empty():return
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	assert_str(stage.figure(Stage.MAIN).mark_name).is_equal("envoy_0")
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f!=null and f.role=="attendant":assert_bool(f.mark_name in ["envoy_1","envoy_2"] or f.mark_name.is_empty()).is_true()


func test_they_walk_in_from_the_door_and_out_by_it_never_through_the_fire()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	stage.settle()
	assert_float(main.stroll).is_equal(0.0)
	# Out: along a way that keeps clear of the fire.
	main._path=main._route(main.spot.to_local(stage.set_point("door_out")))
	var fire:Vector3=stage.set_point("fire")
	for i in 21:
		var at:Vector3=main.spot.to_global(main._path_at(float(i)/20.0))
		assert_float(Vector2(at.x-fire.x,at.z-fire.z).length()).override_failure_message("through the fire at %d: %s, fire %s, spot %s, path %s, set %s" % [i,at,fire,main.spot.global_position,main._path,stage.court_set.name]).is_greater(1.0)
	stage.conclude(0.0,"bow")
	stage.settle()
	assert_bool(main.body3d.visible).is_false()


func test_they_are_lit_by_the_set_and_their_eyes_roll_inside_the_lids()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var body:Node3D=stage.figure(Stage.MAIN).body3d
	var eyes:MeshInstance3D=null
	var body_mesh:MeshInstance3D=null
	for node in body.find_children("*","MeshInstance3D",true,false):
		if node.name=="Eyes":eyes=node
		if node.name=="Body":body_mesh=node
	assert_object(body_mesh).is_not_null()
	var skin:ShaderMaterial=body_mesh.get_surface_override_material(0)
	assert_object(skin.shader).is_same(Figure3D.TOON_LIT)
	assert_int(body_mesh.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	assert_object(eyes).is_not_null()
	assert_int(eyes.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	# The gaze morphs are there when the bodies have them (built with them).
	if eyes.find_blend_shape_by_name(&"eyes_left")>=0:
		for key in ["eyes_left","eyes_right","eyes_up","eyes_down"]:assert_int(eyes.find_blend_shape_by_name(StringName(key))).is_greater_equal(0)
	var read:=false;var wrote:=false
	for i in eyes.mesh.get_surface_count():
		var made:ShaderMaterial=eyes.get_surface_override_material(i)
		if made==null:continue
		if made.shader.code.contains("stencil_mode read"):read=true
		if made.shader.code.contains("stencil_mode write"):wrote=true
	assert_bool(wrote).is_true()
	if eyes.mesh.get_surface_count()>3:assert_bool(read).is_true()


func test_wrath_jolts_the_frame_and_the_dog_cowers()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	stage.settle()
	var dog:Node3D=stage.court_set.call("animal","dog")
	stage.event("divine",{"action":"terrify","response":"cower"})
	assert_bool(stage.rig.call("is_moving")).is_true()
	if dog!=null:assert_str(String(dog.get("clip"))).contains("cower")
	# The director's shots land on the set's camera.
	stage.shot("push_in",{"target":Stage.MAIN})
	assert_str(String(stage.rig.get("current_shot"))).is_equal("push_in")
	stage.shot("wide")
	assert_str(String(stage.rig.get("current_shot"))).is_equal("wide")


func test_a_dropped_bowl_lies_on_the_floor_and_a_bundle_rides_the_hands()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	stage.settle()
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	var body:Node3D=main.body3d
	# A bowl: they drop it, it falls to the floor and they stand empty-handed.
	var look:Dictionary=body.look.duplicate();look["stance"]="bowl"
	body.setup(look);body.play("bowl",0.0)
	var fallen:Node3D=body.drop_held("clasped")
	assert_object(fallen).is_not_null()
	assert_str(String(body.stance)).is_equal("clasped")
	for i in 40:await await_idle_frame()
	assert_float(fallen.global_position.y-body.global_position.y).is_less(0.12)
	# A bundle: it rides between the hands until it is set down, then stays.
	var bundle:MeshInstance3D=null
	for node in body.find_children("prop_bundle","MeshInstance3D",true,false):bundle=node
	if bundle==null:return
	body.carry("bundle",true)
	assert_bool(bundle.visible).is_true()
	assert_bool(body.is_processing()).is_true()
	body.set_down()
	assert_bool(body.is_processing()).is_false()
	assert_float(bundle.global_position.y-body.global_position.y).is_less(0.2)


func test_the_acted_ways_out_play_the_actings_own_walks()->void:
	# With the acting (K) plugged in, backing out bowing plays its back_out
	# and storming off its storm_walk; they still leave by the door and are
	# gone at the end.
	if not _ready_or_skip():return
	if not Acting.has_clip("back_out") or not Acting.has_clip("storm_walk"):return
	Stage.acting=Acting.service()
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	stage.settle()
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	var other:Stage.Figure=null
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f!=null and f!=main and f.spot!=null and f.body3d!=null:other=f;break
	main.leave(-1.0,1.0,0.0,"backward_bump")
	main._move.custom_step(1.0)
	var acting:Node=Acting.of(main.body3d)
	assert_object(acting).is_not_null()
	assert_str(String(acting.get("_a").clip)).is_equal("back_out")
	if other!=null:
		other.leave(-1.0,1.0,0.0,"storm_back")
		other._move.custom_step(0.3)
		assert_str(String(Acting.of(other.body3d).get("_a").clip)).is_equal("storm_walk")
	stage.settle()
	assert_bool(main.body3d.visible).is_false()


## Everyone standing in the hall (not seated, not leaving).
func _standing(stage:Control)->Array:
	var out:=[]
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f==null or f.leaving or f.spot==null or f.body3d==null:continue
		if String(f.body3d.stance)=="sit":continue
		out.append(f)
	return out


func test_nobody_stands_on_another_or_in_a_thing_and_one_clasp_a_room()->void:
	# With the director's onlookers too. Marks are taken once each; standing
	# people keep a body's room apart; nobody stands on a log, a post or the
	# fire; the hall has at most one pair of hands clasped before them.
	if not _ready_or_skip():return
	Stage.directing=true
	# Every hall: the fire circle, the longhouse, the mudbrick hall, the grand hall.
	var seen:={}
	for tier in [0,1,2,3]:
		Backdrop.tier_override=tier
		for id in ([_home_audience(),_envoy_audience()] if tier<2 else [_home_audience()]):
			if String(id).is_empty():continue
			await _check_room(String(id),seen)
	assert_int(seen.size()).is_greater_equal(3)


func _check_room(id:String,seen:Dictionary)->void:
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	stage.settle()
	seen[String(stage.court_set.get("kind"))]=true
	var room:Variant=Paths.room_of(stage.court_set)
	assert_object(room).is_not_null()
	var standing:=_standing(stage)
	assert_int(standing.size()).is_greater_equal(2)
	var clasped:=0
	for i in standing.size():
		var a:Stage.Figure=standing[i]
		var pa:Vector3=a.spot.position
		if String(a.body3d.stance)=="clasped":clasped+=1
		assert_bool(Paths.solid_at(room,Vector2(pa.x,pa.z))).override_failure_message("%s stands in a thing at %s (%s, %s)" % [a.key,pa,a.mark_name,stage.court_set.get("kind")]).is_false()
		for j in range(i+1,standing.size()):
			var b:Stage.Figure=standing[j]
			var pb:Vector3=b.spot.position
			assert_float(Vector2(pa.x-pb.x,pa.z-pb.z).length()).override_failure_message("%s and %s stand %s apart" % [a.key,b.key,Vector2(pa.x-pb.x,pa.z-pb.z).length()]).is_greater(0.55)
	assert_int(clasped).override_failure_message("%d clasp their hands in the %s" % [clasped,stage.court_set.get("kind")]).is_less_equal(1)
	modal.queue_free()
	await await_idle_frame()


func test_the_way_in_goes_round_people_and_things()->void:
	# Each standing person's way in from the door keeps a body's room from
	# everyone else standing and from the set's things (bar the door and
	# their own mark at either end).
	if not _ready_or_skip():return
	Stage.directing=true
	for tier in [0,1,2,3]:
		Backdrop.tier_override=tier
		await _check_ways_in(_home_audience())


func _check_ways_in(id:String)->void:
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	stage.settle()
	var room:Variant=Paths.room_of(stage.court_set)
	var door:Vector3=stage.set_point("door")
	var standing:=_standing(stage)
	var walked:=0
	for f:Stage.Figure in standing:
		var way:PackedVector3Array=stage.plan_walk(f,f.spot.to_local(door))
		if way.size()<2:continue
		walked+=1
		f._path=way
		var length:=f._path_length()
		for i in 61:
			var at:Vector3=f.spot.to_global(f._path_at(float(i)/60.0))
			var along:=length*float(i)/60.0
			if along<0.45 or length-along<0.7:continue
			var here:Vector3=(stage.court_set as Node3D).to_local(at)
			assert_bool(Paths.solid_at(room,Vector2(here.x,here.z))).override_failure_message("%s walks through a thing at %s in the %s" % [f.key,here,stage.court_set.get("kind")]).is_false()
			for other:Stage.Figure in standing:
				if other==f:continue
				var them:Vector3=other.spot.global_position
				assert_float(Vector2(at.x-them.x,at.z-them.z).length()).override_failure_message("%s walks through %s at %s in the %s" % [f.key,other.key,at,stage.court_set.get("kind")]).is_greater(0.4)
	assert_int(walked).is_greater_equal(2)
	modal.queue_free()
	await await_idle_frame()
