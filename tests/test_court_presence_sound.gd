extends GdUnitTestSuite
## Silent/Dummy-driver checks of the live envelope, cancellation and room mix.
const Sound:=preload("res://scripts/hud/court_sound.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
var _volume:=1.0

func before_test()->void:
	_volume=Sound.volume
	Sound.sync_render=true;Sound.set_volume(1.0)

func after_test()->void:
	Sound.set_volume(_volume);Sound.sync_render=false

func _sound()->Node:
	var made:Node=auto_free(Sound.new())
	add_child(made);made.set_process(false)
	return made

func test_presence_has_hush_attack_quiet_words_and_finite_distinct_tails()->void:
	var peaks:={};var tails:={}
	for tone in ["wrath","favour","awe"]:
		var p:=Sound.presence_plan(4.0,tone)
		assert_float(Sound.presence_db_at(p,float(p.lead)*.5)).is_equal(-65.0)
		var peak:=Sound.presence_db_at(p,float(p.lead)+float(p.attack))
		assert_float(peak).is_equal(float(p.peak))
		assert_float(Sound.presence_db_at(p,2.0)).is_less_equal(peak-8.0)
		assert_float(Sound.presence_db_at(p,4.0+float(p.tail)*.5)).is_less(float(p.bed)-15.0)
		assert_float(Sound.presence_db_at(p,float(p.end))).is_equal(-65.0)
		assert_float(float(p.end)).is_less_equal(5.6)
		peaks[peak]=true;tails[p.tail]=true
	assert_int(peaks.size()).is_equal(3)
	assert_int(tails.size()).is_equal(3)

func test_actual_cached_swell_envelope_has_no_click_or_peak_overload()->void:
	for tone in ["wrath","favour","awe"]:
		var p:=Sound.presence_plan(4.0,tone)
		var stream:=Sound.stream_for("god_swell_wrath" if tone=="wrath" else "god_swell_favour")
		var source:=Synth.samples_of(stream)
		var start:=Synth.n_of(Foley.SWELL_HOLD)
		var loud:=0.0;var step:=0.0;var previous:=0.0
		var attack_energy:=0.0;var speech_energy:=0.0
		for n in Synth.n_of(float(p.end)+.1):
			var t:=float(n)/Synth.RATE
			var sample:=source[start+n%(source.size()-start)]*db_to_linear(Sound.presence_db_at(p,t)) if t<float(p.end) else 0.0
			loud=maxf(loud,absf(sample));step=maxf(step,absf(sample-previous));previous=sample
			if t>=.2 and t<1.2:attack_energy+=sample*sample
			if t>=2.0 and t<3.0:speech_energy+=sample*sample
		assert_float(loud).override_failure_message(tone).is_between(.005,.29)
		assert_float(step).override_failure_message(tone+" click").is_less(.03)
		assert_float(speech_energy).override_failure_message(tone+" crowds the words").is_less(attack_energy*.50)

func test_repeated_line_extends_presence_without_retrigger_or_stale_stop()->void:
	var sound:=_sound()
	assert_bool(sound.call("god","Hear me",2.0,"wrath")).is_true()
	sound.set("_clock",1.0);sound.call("_advance_presence")
	var player:AudioStreamPlayer=sound.get("_god")
	assert_float(player.volume_db).is_equal(-22.0)
	sound.call("god","And now",5.0,"wrath")
	var plan:Dictionary=sound.get("_presence")
	assert_float(float(plan.peak)).is_equal(-22.0)
	sound.set("_clock",4.0);sound.call("_advance_presence")
	assert_bool(player.playing).is_true()
	assert_float(player.volume_db).is_equal(-22.0)
	sound.set("_clock",7.61);sound.call("_advance_presence")
	assert_bool(player.playing).is_false()
	assert_bool((sound.get("_presence") as Dictionary).is_empty()).is_true()

func test_close_cancels_fades_queued_impacts_and_inflight_voice_before_reopen()->void:
	var sound:=_sound()
	sound.call("ambience","chapter_07","winter",{"indoor":true,"has_hearth":true,"floor":"wood","known":[]})
	sound.call("god","",3.0,"wrath")
	sound.call("cue","god_wrath_boom",null,{"delay":.45})
	var old_fades:Array=(sound.get("_bed_tweens") as Dictionary).values().duplicate()
	sound.set("_talk",{0:123})
	sound.call("on_event","close",{})
	for tw:Tween in old_fades:assert_bool(tw.is_valid()).is_false()
	assert_bool((sound.get("_queue") as Array).is_empty()).is_true()
	assert_bool((sound.get("_presence") as Dictionary).is_empty()).is_true()
	assert_bool(sound.call("hushed")).is_false()
	assert_bool(sound.call("_voice_ready",Sound.stream_for("gasp"),0,123,0.0,-13.0)).is_false()
	sound.call("ambience","chapter_15","summer",{"indoor":true,"has_hearth":false,"floor":"stone","known":[]})
	sound.call("god","",5.0,"favour")
	sound.set("_clock",4.0);sound.call("_advance_presence")
	assert_bool((sound.get("_god") as AudioStreamPlayer).playing).is_true()
	assert_float((sound.get("_god") as AudioStreamPlayer).volume_db).is_equal(-23.0)

func test_actual_room_changes_acoustics_without_calendar_or_hearth_invention()->void:
	var stone:=Sound.acoustics_for("chapter_08",{"indoor":true,"floor":"stone"})
	var wood:=Sound.acoustics_for("chapter_07",{"indoor":true,"floor":"wood"})
	var office:=Sound.acoustics_for("chapter_15",{"indoor":true,"floor":"stone"})
	assert_float(float(stone.wet)).is_greater(float(wood.wet))
	assert_float(float(wood.wet)).is_greater(float(office.wet))
	assert_float(float(office.damping)).is_greater(float(stone.damping))
	assert_dict(Sound.acoustics_for("chapter_07",{"indoor":true,"floor":"wood","elapsed_year":3000})).is_equal(wood)
	assert_str(String(Sound.acoustics_for("chapter_15",{"indoor":false}).kind)).is_equal("open")
	var sound:=_sound()
	sound.call("ambience","chapter_15","winter",{"indoor":true,"has_hearth":false,"floor":"stone","known":[]})
	var room:=AudioServer.get_bus_effect(AudioServer.get_bus_index(Sound.BUS),0) as AudioEffectReverb
	assert_float(room.wet).is_equal_approx(float(office.wet),.0001)
	assert_float(room.damping).is_equal_approx(float(office.damping),.0001)
	assert_bool((sound.get("_beds") as Dictionary).has("fire")).is_false()

func test_execution_music_fade_cannot_stop_a_reopened_audience()->void:
	var sound:=_sound()
	var player:AudioStreamPlayer=sound.get("_music")
	player.stream=Sound.stream_for("god_swell_favour");player.volume_db=-23.0;player.play()
	sound.call("play_act","club_home_run",{}, {})
	var fade:Tween=sound.get("_music_tw")
	assert_object(fade).is_not_null()
	assert_bool(fade.is_valid()).is_true()
	sound.call("stop_all")
	assert_bool(fade.is_valid()).is_false()
	player.play()
	await get_tree().create_timer(.55).timeout
	assert_bool(player.playing).is_true()

func test_unknown_divine_action_does_not_add_a_cue_or_presence()->void:
	var sound:=_sound()
	sound.call("on_event","divine",{"action":"unadjudicated_idea","response":"cower"})
	assert_bool((sound.get("played") as Array).is_empty()).is_true()
	assert_bool((sound.get("_queue") as Array).is_empty()).is_true()
	assert_bool((sound.get("_presence") as Dictionary).is_empty()).is_true()

func test_muting_and_hidden_stage_cancel_presence_without_revival()->void:
	var stage:Control=auto_free(Control.new());add_child(stage)
	var sound:Node=Sound.attach(stage);sound.set_process(false)
	sound.call("god","",2.0,"favour")
	stage.hide()
	assert_bool((sound.get("_presence") as Dictionary).is_empty()).is_true()
	assert_bool(sound.call("god","",2.0,"wrath")).is_false()
	stage.show();Sound.set_volume(0.0)
	assert_bool(sound.call("god","",2.0,"wrath")).is_false()
	assert_bool(sound.call("hushed")).is_false()
	Sound.set_volume(1.0);sound.call("god","",2.0,"wrath")
	Sound.set_volume(0.0);sound.call("_advance_presence")
	Sound.set_volume(1.0);sound.call("_advance_presence")
	assert_bool((sound.get("_god") as AudioStreamPlayer).playing).is_false()
