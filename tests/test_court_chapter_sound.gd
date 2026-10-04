extends GdUnitTestSuite
## Physical room facts drive ambient audio; a staged act can still deliberately
## make fire sounds in a room that has no permanent hearth.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
var _volume:=1.0

func before_test()->void:
	_volume=Sound.volume;Sound.sync_render=true;Sound.set_volume(1.0)

func after_test()->void:
	Sound.set_volume(_volume);Sound.sync_render=false

func _court()->Node:
	var stage:=Control.new();add_child(stage);auto_free(stage)
	return Sound.attach(stage)

func _played(sound:Node)->Array:
	var names:Array=[]
	for item:Dictionary in sound.get("played"):names.append(String(item.name))
	return names

func test_legacy_rooms_keep_their_hearth_air_and_floor_defaults()->void:
	assert_array(Sound.beds_for("fire_ring","summer",{})).is_equal([["fire","fire",0.0],["wind","wind_soft",0.0]])
	assert_array(Sound.beds_for("shelter","winter",{})).is_equal([["fire","fire",0.0],["wind","wind_hard",-3.0]])
	assert_array(Sound.beds_for("longhouse","winter",{})).is_equal([["fire","fire",-2.0],["wind","wind_indoor",6.0],["room","room",0.0]])
	assert_str(Sound.step_for("grand_hall",{})).is_equal("step_wood")
	assert_str(Sound.step_for("fire_ring",{})).is_equal("step_earth")

func test_explicit_room_facts_override_names_for_open_air_and_no_hearth()->void:
	assert_array(Sound.beds_for("chapter_00","winter",{"indoor":false,"has_hearth":true})).is_equal(Sound.beds_for("fire_ring","winter",{}))
	assert_array(Sound.beds_for("chapter_15","summer",{"indoor":true,"has_hearth":false})).is_equal([["wind","wind_indoor",0.0],["room","room",0.0]])
	assert_array(Sound.beds_for("fire_ring","summer",{"indoor":true,"has_hearth":false})).is_equal([["wind","wind_indoor",0.0],["room","room",0.0]])
	assert_array(Sound.beds_for("grand_hall","summer",{"indoor":false,"has_hearth":false})).is_equal([["wind","wind_soft",0.0]])

func test_reverb_uses_physical_enclosure_for_chapter_rooms()->void:
	var sound:=_court()
	sound.call("ambience","chapter_00","summer",{"indoor":false,"has_hearth":true,"known":[]})
	var room:=AudioServer.get_bus_effect(Sound.ensure_bus(),0) as AudioEffectReverb
	assert_float(room.wet).is_less(.05)
	assert_float(room.room_size).is_less(.2)
	var open_wet:=room.wet;var open_size:=room.room_size
	sound.call("ambience","chapter_15","summer",{"indoor":true,"has_hearth":false,"known":[]})
	assert_float(room.wet).is_greater(open_wet)
	assert_float(room.room_size).is_greater(open_size)
	var office_wet:=room.wet;var office_size:=room.room_size
	# A furnished conference room has an indoor return without the long,
	# hard reverberation of the stone hall that the former constant implied.
	sound.call("ambience","chapter_08","summer",{"indoor":true,"floor":"stone","known":[]})
	assert_float(room.wet).is_greater(office_wet)
	assert_float(room.room_size).is_greater(office_size)

func test_switching_to_a_cold_room_stops_an_existing_fire_bed()->void:
	var sound:=_court()
	sound.call("ambience","fire_ring","summer",{"known":[]})
	var fire:AudioStreamPlayer=(sound.get("_beds") as Dictionary).get("fire")
	assert_object(fire).is_not_null()
	assert_bool(fire.playing).is_true()
	sound.call("ambience","chapter_15","summer",{"indoor":true,"has_hearth":false,"known":[]})
	assert_bool(fire.playing).is_false()
	assert_bool((sound.get("_beds") as Dictionary).has("fire")).is_false()
	assert_bool((sound.get("_bed_db") as Dictionary).has("fire")).is_false()
	assert_bool((sound.get("_bed_tweens") as Dictionary).has("fire")).is_false()

func test_cold_room_schedules_no_idle_fire_but_explicit_fire_cues_still_play()->void:
	var sound:=_court()
	sound.call("ambience","chapter_15","summer",{"indoor":true,"has_hearth":false,"known":[]})
	sound.set("_next",{"fire_pop":0.0,"fire_hiss":0.0,"log_settle":0.0})
	sound.call("_tick")
	assert_array(_played(sound)).not_contains(["fire_pop","fire_hiss","log_settle"])
	# A cue explicitly requested by an act is not ambient room life.
	assert_bool(sound.call("cue","fire_pop",null,{"variant":0})).is_true()
	assert_array(_played(sound)).contains(["fire_pop"])
	assert_bool(sound.call("cue","fire_hiss",null,{"variant":0,"delay":0.1})).is_true()
	sound.set("_clock",float(sound.call("_now"))+0.2)
	sound.call("_tick")
	assert_array(_played(sound)).contains(["fire_hiss"])

func test_real_hearth_keeps_its_random_fire_life()->void:
	var sound:=_court()
	sound.call("ambience","chapter_07","winter",{"indoor":true,"has_hearth":true,"known":[]})
	sound.set("_next",{"fire_pop":0.0,"fire_hiss":0.0,"log_settle":0.0})
	sound.call("_tick")
	assert_array(_played(sound)).contains(["fire_pop","fire_hiss","log_settle"])

func test_authored_floor_selects_matching_queued_steps_without_changing_explicit_cues()->void:
	var sound:=_court()
	sound.set("set_kind","chapter_15")
	for row:Array in [["PLANK","step_wood"],["wood","step_wood"],["FLAGS","step_stone"],["STONE_BLOCK","step_stone"],["concrete","step_stone"],["GROUND","step_earth"]]:
		sound.set("facts",{"floor":row[0]});sound.set("_queue",[])
		sound.call("footsteps",null,0.4)
		var queue:Array=sound.get("_queue")
		assert_array(queue).is_not_empty()
		for item:Dictionary in queue:assert_str(String(item.name)).is_equal(row[1])
	sound.set("_queue",[])
	sound.call("footsteps",null,0.4,1.8,false,"stamp")
	for item:Dictionary in sound.get("_queue"):assert_str(String(item.name)).is_equal("stamp")

func test_stone_steps_are_deterministic_finite_click_free_and_distinct_from_wood()->void:
	assert_bool(Foley.CUES.has("step_stone")).is_true()
	for variant in Foley.variants("step_stone"):
		var samples:=Foley.make("step_stone",variant)
		assert_int(samples.size()).is_greater(200)
		assert_float(Synth.peak_of(samples)).is_between(0.05,1.0)
		assert_bool(is_finite(Synth.rms_of(samples))).is_true()
		assert_float(absf(samples[0])).is_less(0.02)
		assert_float(absf(samples[samples.size()-1])).is_less(0.02)
		assert_bool(samples==Foley.make("step_stone",variant)).is_true()
		assert_bool(samples==Foley.make("step_wood",variant)).is_false()
		assert_bool(samples==Foley.make("step_earth",variant)).is_false()
	assert_bool(Foley.make("step_stone",0)==Foley.make("step_stone",1)).is_false()
	assert_object(Sound.stream_for("step_stone",1)).is_same(Sound.stream_for("step_stone",1))
