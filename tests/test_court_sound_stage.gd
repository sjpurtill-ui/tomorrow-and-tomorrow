extends GdUnitTestSuite
## THE COURT'S SOUND IN THE REAL COURT (court_stage.gd as the integrator
## wired it, with the modelled set): the stage makes its sound node, the room
## gets its beds, and a sound made by someone on the left of the picture is
## heard on the left (the mix captured off the Master bus; headless, the Dummy
## driver still mixes). Offline; never calls a real API or writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Sound:=preload("res://scripts/hud/court_sound.gd")

var _root_size:=Vector2i.ZERO
var _volume:=1.0

func before_test()->void:
	Stage.directing=false
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	Stage.sound=Sound
	_volume=Sound.volume
	Sound.set_volume(1.0)
	Fixtures.new(self).base(false)
	_root_size=get_tree().root.size
	get_tree().root.size=Vector2i(1536,864)

func after_test()->void:
	Stage.directing=true
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	Stage.sound=null
	Sound.set_volume(_volume)
	get_tree().root.size=_root_size

func _open(id:String)->Control:
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal()
	await await_idle_frame()
	return modal

static func _balance(cap:AudioEffectCapture)->Vector2:
	var n:=cap.get_frames_available()
	var buf:=cap.get_buffer(n)
	var l:=0.0;var r:=0.0
	for v in buf:l+=v.x*v.x;r+=v.y*v.y
	return Vector2(sqrt(l/maxf(1.0,float(n))),sqrt(r/maxf(1.0,float(n))))

func test_in_the_court_a_sound_comes_from_where_its_maker_stands()->void:
	if not CourtSet.available() or not Figure3D.available():
		push_warning("court set or figures not imported; skipped");return
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	var modal:Control=await _open(String(Hall.summon(target).get("id","")))
	var stage:Control=modal.court_stage
	var sound:Node=stage.get_node_or_null("CourtSound")
	assert_object(sound).override_failure_message("the stage made no sound node").is_not_null()
	assert_object(Sound.current).is_same(sound)
	# the room has its beds (or is making them)
	assert_bool((sound.get("_bed_list") as Array).size()>=3).is_true()
	stage.settle()
	# the leftmost and rightmost people in the picture
	var left:Node3D=null;var right:Node3D=null
	var lx:=INF;var rx:=-INF
	for key in stage.cast_order:
		var f:Stage.Figure=stage.figure(key)
		if f==null or f.body3d==null:continue
		var x:=float(stage.world_to_stage(f.body3d.global_position).x)
		if x<lx:lx=x;left=f.body3d
		if x>rx:rx=x;right=f.body3d
	assert_object(left).is_not_null()
	assert_float(rx-lx).override_failure_message("everyone stands in one place").is_greater(200.0)
	# quiet the room, then listen
	sound.call("stop_all")
	var cap:=AudioEffectCapture.new();cap.buffer_length=3.0
	AudioServer.add_bus_effect(0,cap)
	var slot:=AudioServer.get_bus_effect_count(0)-1
	await get_tree().process_frame
	cap.clear_buffer()
	sound.call("cue","creak",left,{"variant":0,"pitch":1.0,"db":6.0})
	await get_tree().create_timer(0.7).timeout
	var from_left:=_balance(cap)
	cap.clear_buffer()
	sound.call("cue","creak",right,{"variant":0,"pitch":1.0,"db":6.0})
	await get_tree().create_timer(0.7).timeout
	var from_right:=_balance(cap)
	AudioServer.remove_bus_effect(0,slot)
	prints("court: left person L/R",from_left,"at x",lx," right person L/R",from_right,"at x",rx)
	assert_float(from_left.x+from_left.y).override_failure_message("nothing was heard").is_greater(0.0001)
	assert_float(from_left.x).is_greater(from_left.y*1.05)
	assert_float(from_right.y).is_greater(from_right.x*1.05)
