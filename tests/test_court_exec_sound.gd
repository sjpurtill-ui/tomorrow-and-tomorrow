extends GdUnitTestSuite
## THE COURT'S EXECUTION SOUNDS (scripts/hud/court_gore_foley.gd, played by
## court_sound.gd): every comic gore sound is made, in range, without a click,
## the same each time; each act's track names only sounds that exist; an act
## plays with the drum roll first and the punchline on what the people can
## play (hands on a log, a drum, small cymbals only in a temple age); with the
## gore setting off nothing of it plays. Headless; no files, no save.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Gore:=preload("res://scripts/hud/court_gore_foley.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")

var _volume:=1.0

func before_test()->void:
	_volume=Sound.volume
	Sound.sync_render=true

func after_test()->void:
	Sound.set_volume(_volume)
	Sound.sync_render=false

func test_every_gore_sound_is_made_in_range_without_clicks()->void:
	for name in Gore.CUES:
		var samples:=Gore.make(String(name),0)
		assert_int(samples.size()).override_failure_message("%s is empty" % name).is_greater(500)
		assert_float(Synth.peak_of(samples)).override_failure_message("%s level" % name).is_between(0.3,0.75)
		assert_bool(is_finite(Synth.rms_of(samples))).is_true()
		assert_bool(absf(samples[0])<0.02 and absf(samples[samples.size()-1])<0.02).override_failure_message("%s clicks" % name).is_true()
	assert_bool(Gore.make("gore_splat",1)==Gore.make("gore_splat",1)).is_true()
	assert_bool(Gore.make("gore_splat",0)==Gore.make("gore_splat",1)).is_false()

func test_each_acts_track_names_sounds_that_exist()->void:
	for act in ["club_home_run","three_swing_beheading","dog_dinner"]:
		assert_bool(Gore.ACTS.has(act)).is_true()
	for act in Gore.ACTS:
		var punch:=false
		var roll:=false
		for item:Dictionary in Gore.ACTS[act]:
			var name:=String(item.cue)
			if name=="punch":punch=true;continue
			if name=="roll":roll=true;assert_float(float(item.t)).is_less(0.0);continue
			assert_bool(Gore.has(name) or Foley.CUES.has(name)).override_failure_message("%s: %s is not a sound" % [act,name]).is_true()
		assert_bool(punch and roll).override_failure_message("%s lacks the roll or the punchline" % act).is_true()

func _court(known:Array)->Node:
	var stage:=Control.new()
	add_child(stage)
	auto_free(stage)
	var sound:Node=Sound.attach(stage)
	Sound.set_volume(1.0)
	sound.call("ambience","fire_ring","summer",{"era_tier":1,"known":known})
	return sound

func _queued(sound:Node)->Array:
	var out:=[]
	for item in (sound.get("_queue") as Array):out.append(String(item.name))
	return out

func test_an_act_plays_its_roll_and_its_punchline_by_the_age()->void:
	var sound:=_court(["bone_flutes_drums"])
	var lead:float=sound.call("play_act","club_home_run",{},{})
	assert_float(lead).is_equal_approx(2.4,0.01)
	var names:=_queued(sound)
	assert_array(names).contains(["drum_roll","gore_crack","pot_plop","lid_clank","punch_drum"])
	assert_array(names).not_contains(["punch_cymbal","log_roll"])
	# the crack lands lead seconds from now
	var now:float=sound.call("_now")
	for item in (sound.get("_queue") as Array):
		if String(item.name)=="gore_crack":assert_float(float(item.at)).is_equal_approx(now+lead,0.01)
	# a temple age rings its cymbals on the punchline; before any drum, hands on a log
	var temple:=_court(["bone_flutes_drums","rattles_drums_pipes","harps_and_lyres","temple_choirs"])
	temple.call("play_act","three_swing_beheading",{},{})
	assert_array(_queued(temple)).contains(["punch_cymbal","axe_thunk","axe_clang","gore_chop","blood_geyser","blood_patter"])
	var early:=_court([])
	early.call("play_act","dog_dinner",{},{})
	assert_array(_queued(early)).contains(["log_roll","punch_log","crunch_loop","bone_drop"])

func test_with_gore_off_nothing_plays_and_mild_keeps_the_sounds()->void:
	var sound:=_court(["bone_flutes_drums"])
	assert_float(float(sound.call("play_act","dog_dinner",{},{"gore":"off"}))).is_equal(0.0)
	assert_int((sound.get("_queue") as Array).size()).is_equal(0)
	sound.call("play_act","dog_dinner",{},{"gore":"mild"})
	assert_array(_queued(sound)).contains(["crunch_loop"])

func test_the_queued_sounds_play_when_their_time_comes()->void:
	var sound:=_court(["bone_flutes_drums"])
	var lead:float=sound.call("play_act","club_home_run",{},{})
	sound.set("_clock",float(sound.call("_now"))+lead+0.01)
	sound.call("_tick")
	var heard:=[]
	for p in (sound.get("played") as Array):heard.append(String(p.name))
	assert_array(heard).contains(["drum_roll","windup","swing_whoosh","gore_crack"])

func test_all_twenty_five_acts_have_a_track()->void:
	assert_int(Gore.ACT_NUMBERS.size()).is_equal(26)
	for n in range(1,26):
		var act:String=Gore.ACT_NUMBERS[n]
		var track:Array=Gore.ACTS.get(act,[])
		assert_bool(track.is_empty()).override_failure_message("act %d (%s) has no track" % [n,act]).is_false()
		# roll before the blow, something at the blow, a punchline after it
		var at_blow:=false
		var punch_after:=false
		for item:Dictionary in track:
			if absf(float(item.t))<0.3 and String(item.cue) not in ["roll","punch"]:at_blow=true
			if String(item.cue)=="punch" and float(item.t)>0.5:punch_after=true
		assert_bool(at_blow and punch_after).override_failure_message("act %d lacks a blow or a late punchline" % n).is_true()
		# 6-12 s from the blow to the room's last word, and no longer before it than the roll
		var last:=0.0
		for item:Dictionary in track:last=maxf(last,float(item.t))
		assert_float(last).override_failure_message("act %d runs %.1f s after the blow" % [n,last]).is_between(2.5,9.5)

func test_a_terrified_hall_is_silent_and_the_hungry_eye_the_pot()->void:
	var sound:=_court(["bone_flutes_drums","rattles_drums_pipes"])
	sound.call("play_act",2,{},{"dread":0.9})
	var names:=_queued(sound)
	assert_array(names).not_contains(["room_gasp","lone_clap"])
	assert_array(names).contains(["swallow","knees_knock","gore_crack"])
	var fed:=_court(["bone_flutes_drums","rattles_drums_pipes"])
	fed.set("facts",{"stores_days":40})
	fed.call("play_act","boiled_in_pot",{},{})
	assert_array(_queued(fed)).not_contains(["stomach_growl"])
	assert_array(_queued(fed)).contains(["crowd_groan"])
	var starving:=_court(["bone_flutes_drums","rattles_drums_pipes"])
	starving.set("facts",{"stores_days":4})
	starving.call("play_act","boiled_in_pot",{},{})
	assert_array(_queued(starving)).contains(["stomach_growl"])
