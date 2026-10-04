extends GdUnitTestSuite
## THE COURT'S EXECUTION SOUNDS (scripts/hud/court_gore_foley.gd, played by
## court_sound.gd): every comic gore sound is made, in range, without a click,
## the same each time; each act's track names only sounds that exist; an act
## plays with the drum roll first and the punchline on what the people can
## play (hands on a log, a drum, small cymbals only in a temple age); with the
## gore setting off nothing of it plays. The room's reactions come from the
## people standing there, each in their own voice and as their temper has it,
## drawn afresh for each act; a terrified hall makes none. Headless; no files,
## no save.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Gore:=preload("res://scripts/hud/court_gore_foley.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const Reactions:=preload("res://scripts/hud/court_reactions.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")

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
	for item in (sound.get("_queue") as Array):out.append(String(item.get("name",item.get("label",""))))
	return out

func test_an_act_plays_its_roll_and_its_punchline_by_the_age()->void:
	var sound:=_court(["bone_flutes_drums"])
	var lead:float=sound.call("play_act","club_home_run",{},{})
	# K's clip: the club's first tap 3.17 s before the crack
	assert_float(lead).is_equal_approx(3.17,0.01)
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
	assert_array(_queued(early)).contains(["log_roll","punch_log","tug","slip","crunch","bone_drop"])

func test_with_gore_off_nothing_plays_and_mild_keeps_the_sounds()->void:
	var sound:=_court(["bone_flutes_drums"])
	assert_float(float(sound.call("play_act","dog_dinner",{},{"gore":"off"}))).is_equal(0.0)
	assert_int((sound.get("_queue") as Array).size()).is_equal(0)
	sound.call("play_act","dog_dinner",{},{"gore":"mild"})
	assert_array(_queued(sound)).contains(["crunch"])

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
		# 2.5-11.5 s from the blow to the room's last word (the dog's walk back is long)
		var last:=0.0
		for item:Dictionary in track:last=maxf(last,float(item.t))
		assert_float(last).override_failure_message("act %d runs %.1f s after the blow" % [n,last]).is_between(2.5,11.5)

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

# --- The room's reactions, from the people present ---------------------------

class FakeFigure extends RefCounted:
	var body3d:Node3D
	var person:Dictionary={}
	var leaving:=false

class FakeStage extends Control:
	var extras:={}
	var cast_order:Array[String]=[]
	var audience_key:="exec_test"
	var figs:={}
	func figure(key:String)->Object:return figs.get(key)
	func world_to_stage(point:Vector3)->Vector2:return Vector2(768.0+point.x*200.0,400.0)

## A hall with a victim and an executioner, a child, a fawning courtier, a
## scribe, a proud captain, a farmer and a timid girl, and a dog; returns
## [sound, roles].
func _hall()->Array:
	var stage:=FakeStage.new();stage.size=Vector2(1536,864)
	add_child(stage);auto_free(stage)
	var cast:={
		"victim":[{"name":"Oru","age":40,"sex":"male"},{}],
		"headsman":[{"name":"Tak","age":35,"sex":"male"},{}],
		"kid":[{"name":"Pim","sex":"female"},{"role":"crowd","kind":"child","age":8}],
		"fawner":[{"name":"Sello","age":44,"sex":"male"},{}],
		"scribe":[{"name":"Ennu","age":50,"sex":"male"},{"role":"crowd","kind":"scribe"}],
		"captain":[{"name":"Rask","age":38,"sex":"male"},{"role":"crowd","pride":0.9,"courage":0.9}],
		"farmer":[{"name":"Dela","age":30,"sex":"female"},{"role":"crowd"}],
		"meek":[{"name":"Lin","age":22,"sex":"female"},{"role":"crowd","dread":0.8}],
		"dog":[{"name":"dog"},{"role":"animal","kind":"dog"}],
	}
	var x:=-3.0
	for key:String in cast:
		var f:=FakeFigure.new()
		f.person=cast[key][0]
		var body:=Node3D.new();stage.add_child(body);body.position=Vector3(x,0,0);x+=0.75
		f.body3d=body
		stage.figs[key]=f;stage.cast_order.append(key)
		if not (cast[key][1] as Dictionary).is_empty():stage.extras[key]=cast[key][1]
	var sound:Node=Sound.attach(stage)
	Sound.set_volume(1.0)
	sound.call("ambience","fire_ring","summer",{"era_tier":1,"known":["bone_flutes_drums"]})
	var roles:={"victim":stage.figs.victim.body3d,"executioner":stage.figs.headsman.body3d,
		"flatterer":stage.figs.fawner.body3d,"front_row":stage.figs.farmer.body3d}
	return [sound,roles]

func _kinds_of(temper:String,moment:String)->Array:
	var out:=[]
	for o in ((Reactions.CHOICES[temper] as Dictionary).get(moment,[]) as Array):out.append(String(o[0]))
	return out

func _signature(sound:Node)->String:
	var sig:=""
	var now:float=sound.call("_now")
	for r:Dictionary in (sound.get("last_reactions") as Array):sig+="%s:%s:%.2f " % [r.who,r.kind,float(r.at)-now]
	return sig

func test_the_rooms_reactions_come_from_the_people_present_by_temper()->void:
	var made:=_hall()
	var sound:Node=made[0]
	var tempers:={"kid":"child","fawner":"flatterer","scribe":"pedant","captain":"proud","farmer":"plain","meek":"timid"}
	var heard_people:={}
	for n in 12:
		sound.call("play_act","three_swing_beheading",made[1],{})
		var said:Array=sound.get("last_reactions")
		assert_bool(said.is_empty()).is_false()
		for r:Dictionary in said:
			var who:=String(r.who)
			# never the one put to death, the executioner or the dog
			assert_bool(tempers.has(who)).override_failure_message("%s reacted" % who).is_true()
			assert_str(String(r.temper)).is_equal(String(tempers.get(who,"")))
			heard_people[who]=true
			var kind:=String(r.kind)
			if kind in ["retch","mutter"]:continue
			var fits:=false
			for moment in ["shock","disgust","amusement","applause","sick"]:
				if kind in _kinds_of(String(r.temper),moment):fits=true
			assert_bool(fits).override_failure_message("%s (%s) made a %s" % [who,r.temper,kind]).is_true()
	# over a dozen acts most of the hall has been heard
	assert_int(heard_people.size()).is_greater_equal(4)
	# the generic gasp gives way to the people's own; the front row retches in her own voice
	var labels:=_queued(sound)
	assert_array(labels).not_contains(["room_gasp","retch"])
	assert_bool(labels.has("react_retch")).is_true()

func test_the_flatterer_says_oh_with_his_clap_and_the_child_says_ewww()->void:
	var made:=_hall()
	var sound:Node=made[0]
	var fawner:={}
	var kid:={}
	for n in 20:
		sound.call("play_act","club_home_run",made[1],{})
		for r:Dictionary in (sound.get("last_reactions") as Array):
			if String(r.who)=="fawner":fawner[String(r.kind)]=true
			if String(r.who)=="kid":kid[String(r.kind)]=true
	assert_bool(fawner.has("oh")).is_true()
	assert_array(_queued(sound)).contains(["lone_clap"])
	for k:String in fawner:assert_bool(k in ["oh","mm","gasp","laugh","eugh","oof","mutter"]).override_failure_message("flatterer: %s" % k).is_true()
	for k:String in kid:assert_bool(k in ["whimper","gasp","ewww","giggle","mutter"]).override_failure_message("child: %s" % k).is_true()

func test_reactions_are_drawn_afresh_for_each_act_and_the_same_for_the_same_seed()->void:
	var made:=_hall()
	var sound:Node=made[0]
	var seen:={}
	var first:=""
	for n in 8:
		sound.call("play_act","three_swing_beheading",made[1],{})
		var sig:=_signature(sound)
		if n==0:first=sig
		seen[sig]=true
	assert_int(seen.size()).override_failure_message("only %d different rooms in 8 acts" % seen.size()).is_greater_equal(7)
	# the same court on the same act draws the same first room (seeded, not random)
	var again:=_hall()
	(again[0] as Node).call("play_act","three_swing_beheading",again[1],{})
	assert_str(_signature(again[0])).is_equal(first)

func test_a_terrified_hall_makes_no_reactions()->void:
	var made:=_hall()
	var sound:Node=made[0]
	sound.call("play_act","three_swing_beheading",made[1],{"dread":0.75})
	assert_bool((sound.get("last_reactions") as Array).is_empty()).is_true()
	for label in _queued(sound):assert_bool(String(label).begins_with("react_")).override_failure_message(String(label)).is_false()
	assert_array(_queued(sound)).contains(["swallow","knees_knock"])

func test_the_reactions_play_at_their_people()->void:
	var made:=_hall()
	var sound:Node=made[0]
	var lead:float=sound.call("play_act","three_swing_beheading",made[1],{})
	sound.set("_clock",float(sound.call("_now"))+lead+12.0)
	sound.call("_tick")
	var reacted:=0
	for p in (sound.get("played") as Array):
		if String(p.name).begins_with("react_"):reacted+=1
	assert_int(reacted).is_greater(0)

func test_each_reaction_is_made_in_range_in_each_voice()->void:
	var a:=Voice.spec({"name":"Pim","age":8,"sex":"female"},"player",7)
	var b:=Voice.spec({"name":"Rask","age":60,"sex":"male"},"civ_03",7)
	for kind in Reactions.KINDS:
		var one:=Reactions.make(String(kind),a,11)
		var two:=Reactions.make(String(kind),b,11)
		for buf:PackedFloat32Array in [one,two]:
			assert_int(buf.size()).override_failure_message("%s is empty" % kind).is_greater(1500)
			assert_float(Synth.peak_of(buf)).override_failure_message("%s level" % kind).is_between(0.3,0.75)
			assert_bool(is_finite(Synth.rms_of(buf))).is_true()
			assert_bool(absf(buf[0])<0.02 and absf(buf[buf.size()-1])<0.02).override_failure_message("%s clicks" % kind).is_true()
		assert_bool(one==two).override_failure_message("%s is the same in both voices" % kind).is_false()
		# the seed varies it; the same seed repeats it
		assert_bool(Reactions.make(String(kind),a,11)==one).is_true()
		assert_bool(Reactions.make(String(kind),a,12)==one).override_failure_message("%s ignores its seed" % kind).is_false()

func test_cancel_act_keeps_other_sound_and_discards_late_reactions()->void:
	var sound:=_court([])
	sound.call("play_act","into_the_fire",{},{})
	var epoch:=int(sound.get("_act_epoch"))
	sound.call("cue","creak",null,{"delay":30.0})
	assert_bool((_queued(sound) as Array).has("whoomph")).is_true()
	sound.call("stop_act")
	assert_array(_queued(sound)).is_equal(["creak"])
	# A worker may finish rendering after the user has skipped the scene.
	var late:={"at":float(sound.call("_now"))+2.0,"stream":Synth.to_stream(Synth.buffer(0.02)),"body_id":0,"kind":"gasp","act":epoch}
	sound.call("_reactions_ready",[late])
	assert_array(_queued(sound)).is_equal(["creak"])
