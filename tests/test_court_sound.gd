extends GdUnitTestSuite
## THE COURT'S SOUND (scripts/hud/court_sound.gd, court_voice.gd,
## court_foley.gd, court_synth.gd):
## - every sound is made, in range, without a click at either end;
## - the same seed makes the same samples;
## - our people and another people's envoy babble differently (each in its
##   own tongue's sounds), and the babble keeps the mouth's own timing;
## - fear is higher than pride; a mutter is a whisper;
## - nothing plays while the court's sound is muted or the court is hidden;
## - the glottis is a proper LF pulse; the crowd murmurs in our own tongue;
##   the dog is heard now and then; a sound comes from where its maker stands;
## - the director's acts that are heard map to sounds that exist, and the
##   hush cuts the crowd's murmur dead.
## Headless; no files, no network, no save.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const Language:=preload("res://scripts/people_language.gd")

const SEED:=424242
const LINE:="Great one, the stores are thin. We ask for rain, and for patience."
var _volume:=1.0

func before_test()->void:
	_volume=Sound.volume
	Sound.sync_render=true

func after_test()->void:
	Sound.set_volume(_volume)
	Sound.sync_render=false

static func _clean_edges(samples:PackedFloat32Array)->bool:
	return absf(samples[0])<0.02 and absf(samples[samples.size()-1])<0.02

func test_every_cue_is_made_in_range_without_clicks()->void:
	for name in Foley.CUES:
		var samples:=Foley.make(String(name),0)
		assert_int(samples.size()).override_failure_message("%s is empty" % name).is_greater(200)
		var top:=Synth.peak_of(samples)
		assert_float(top).override_failure_message("%s peak %f" % [name,top]).is_between(0.05,1.0)
		assert_bool(is_finite(Synth.rms_of(samples))).is_true()
		assert_bool(_clean_edges(samples)).override_failure_message("%s clicks at an end" % name).is_true()

func test_a_bed_loops_without_a_seam()->void:
	var s:=Sound.stream_for("fire",0)
	assert_int(s.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	var samples:=Synth.samples_of(s)
	assert_float(samples.size()/float(Synth.RATE)).is_greater(5.0)
	# the end flows into the start: no jump larger than the bed's own steps
	var jump:=absf(samples[0]-samples[samples.size()-1])
	var typical:=0.0
	for i in range(1,2000):typical=maxf(typical,absf(samples[i]-samples[i-1]))
	assert_float(jump).is_less_equal(typical*1.5+0.01)

func test_the_same_seed_makes_the_same_sound()->void:
	var a:=Foley.make("creak",1)
	var b:=Foley.make("creak",1)
	assert_bool(a==b).is_true()
	assert_bool(Foley.make("creak",0)==a).override_failure_message("variants should differ").is_false()
	var v:=Voice.spec({"name":"Hena Tuvasi","person_id":7,"sex":"female","age":38},"player",SEED)
	var one:=Voice.render(v,LINE,1.6,"neutral")
	var two:=Voice.render(v,LINE,1.6,"neutral")
	assert_bool(one.data==two.data).is_true()

func test_peoples_babble_in_their_own_sounds()->void:
	var ours:=Voice.phonology("player",SEED)
	assert_str(String(ours.family)).is_equal(String(Language.profile("player",SEED).family))
	var other:=""
	for k in range(1,30):
		var owner:="civ_%02d" % k
		if String(Voice.phonology(owner,SEED).family)!=String(ours.family):other=owner;break
	assert_str(other).is_not_empty()
	var person:={"name":"Hena Tuvasi","person_id":7,"sex":"male","age":38}
	var a:=Voice.spec(person,"player",SEED)
	var b:=Voice.spec(person,other,SEED)
	# the syllables come from each tongue's own sounds
	var plan_a:=Voice.plan(a,LINE,2.0)
	var plan_b:=Voice.plan(b,LINE,2.0)
	assert_int(plan_a.size()).is_equal(plan_b.size())
	var same:=0
	for i in plan_a.size():
		if str(plan_a[i].onset)==str(plan_b[i].onset) and str(plan_a[i].vowel)==str(plan_b[i].vowel):same+=1
	assert_float(float(same)/plan_a.size()).is_less(0.5)
	var sa:=Voice.render_samples(a,LINE,2.0)
	var sb:=Voice.render_samples(b,LINE,2.0)
	assert_bool(sa==sb).is_false()

func test_babble_keeps_the_mouths_timing()->void:
	var items:=Voice.schedule(LINE,2.0)
	var count:=0
	for raw in LINE.split(" ",false):
		var word:=raw.strip_edges().rstrip(",.!?")
		if not word.is_empty():count+=Voice.mouth_syllables(word).size()
	assert_int(items.size()).is_equal(count)
	# with the acting layer present, the same syllables in the same places
	if ResourceLoader.exists("res://scripts/hud/court_acting.gd"):
		var acting:GDScript=load("res://scripts/hud/court_acting.gd")
		var has_it:=false
		for m in acting.get_script_method_list():
			if String(m.name)=="_syllables":has_it=true
		if has_it:
			for word in ["patience","stores","rain","bowed"]:
				assert_str(str(Voice.mouth_syllables(word))).is_equal(str(acting.call("_syllables",word)))
	# the voice sounds in its syllables and falls quiet in the pause after "thin."
	var v:=Voice.spec({"name":"Suri Danek","person_id":8,"sex":"female","age":33},"player",SEED)
	var samples:=Voice.render_samples(v,LINE,2.0)
	var thin:=0
	for i in items.size():
		if String(items[i].tail)==".":thin=i;break
	var gap_from:=float(items[thin].t)+float(items[thin].len)+0.04
	var gap_to:=float(items[thin+1].t)-0.06
	var speaking:=Synth.rms_of(samples,Synth.n_of(float(items[0].t)),Synth.n_of(float(items[thin].t)+float(items[thin].len)))
	var pause:=Synth.rms_of(samples,Synth.n_of(gap_from),Synth.n_of(gap_to))
	assert_float(pause).is_less(speaking*0.25)

static func _mean_pitch(voice:Dictionary,mood:String)->float:
	var sc:=Voice.Score.new(2.3,float(voice.f0))
	Voice.paint_line(sc,voice,Voice.plan(voice,LINE,2.0),Voice.feeling(mood),false)
	var total:=0.0;var n:=0
	for i in sc.n:
		if sc.av[i]>0.5:total+=sc.f0[i];n+=1
	return total/maxf(1.0,n)

func test_fear_is_high_and_pride_is_low()->void:
	var v:=Voice.spec({"name":"Brann Ute","person_id":5,"sex":"male","age":30},"player",SEED)
	var afraid:=_mean_pitch(v,"afraid")
	var proud:=_mean_pitch(v,"proud")
	var calm:=_mean_pitch(v,"neutral")
	assert_float(afraid).is_greater(calm*1.08)
	assert_float(proud).is_less(calm)
	# a child chirps above a grown man; an old voice wavers
	var child:=Voice.spec({"name":"Lio","person_id":0,"sex":"male","age":7},"player",SEED)
	assert_float(float(child.f0)).is_greater(float(v.f0)*1.8)
	var elder:=Voice.spec({"name":"Ama Seld","person_id":9,"sex":"female","age":74},"player",SEED)
	assert_float(float(elder.tremor)).is_greater(0.0)
	var war:=Voice.spec({"name":"Orrin Vael","person_id":3,"sex":"male","age":47,"office_title":"War leader"},"player",SEED)
	assert_float(float(war.gravel)).is_greater(0.0)

func test_a_mutter_is_a_whisper()->void:
	var v:=Voice.spec({"name":"Brann Ute","person_id":5,"sex":"male","age":30},"player",SEED)
	var sc:=Voice.Score.new(2.3,float(v.f0))
	Voice.paint_line(sc,v,Voice.plan(v,LINE,2.0),Voice.feeling("neutral"),true)
	var voiced:=0.0
	for i in sc.n:voiced=maxf(voiced,sc.av[i])
	assert_float(voiced).is_less(0.05)

func _court()->Array:
	var stage:=Control.new()
	add_child(stage)
	var sound:Node=Sound.attach(stage)
	return [auto_free(stage),sound]

func test_nothing_plays_when_muted_or_hidden()->void:
	var made:=_court()
	var stage:Control=made[0]
	var sound:Node=made[1]
	Sound.set_volume(0.0)
	assert_bool(Sound.muted()).is_true()
	assert_bool(sound.call("cue","gasp",null,{})).is_false()
	assert_bool(sound.call("voice",null,LINE,1.6,"neutral","player",{})).is_false()
	assert_bool(sound.call("god","Hear me.",1.0,"wrath")).is_false()
	assert_int((sound.get("played") as Array).size()).is_equal(0)
	Sound.set_volume(0.8)
	assert_bool(sound.call("cue","gasp",null,{})).is_true()
	stage.visible=false
	assert_bool(sound.call("cue","gasp",null,{})).is_false()
	assert_bool(sound.call("voice",null,LINE,1.6,"neutral","player",{})).is_false()
	stage.visible=true
	assert_bool(sound.call("voice",null,LINE,1.6,"neutral","player",{})).is_true()

func test_the_hush_cuts_the_murmur()->void:
	var made:=_court()
	var sound:Node=made[1]
	Sound.set_volume(1.0)
	sound.call("ambience","fire_ring","summer",{"era_tier":0,"dread":0.2})
	var beds:Dictionary=sound.get("_beds")
	assert_bool(beds.has("fire")).is_true()
	assert_int((sound.get("_slots") as Array).size()).is_greater_equal(3)
	sound.call("hush",true)
	assert_bool(sound.call("hushed")).is_true()
	# nobody in the crowd may start talking again while the god holds the room
	var now:float=sound.call("_now")
	for at in (sound.get("_slot_free") as PackedFloat32Array):assert_float(at).is_greater(now+100.0)
	sound.call("hush",false)
	assert_bool(sound.call("hushed")).is_false()
	# they come back one at a time, a beat late
	var free:=sound.get("_slot_free") as PackedFloat32Array
	var soonest:=INF;var latest:=0.0
	for at in free:soonest=minf(soonest,at);latest=maxf(latest,at)
	assert_float(soonest).is_greater(now+0.5)
	assert_float(latest-soonest).is_greater(1.0)
	# the god's words hush the room
	sound.call("god","Be still.",1.5,"favour")
	assert_bool(sound.call("hushed")).is_true()

func test_the_crowd_never_says_the_same_thing_twice()->void:
	# five minutes of the crowd: no run repeats another (who, from where, at
	# what pitch), the room grows quieter and busier by turns
	var runs:=Sound.murmur_schedule(11,300.0,"murmur")
	assert_int(runs.size()).is_greater(80)
	var seen:={}
	for run:Dictionary in runs:
		var key:="%d|%.2f|%.3f" % [int(run.talker),float(run.from),float(run.pitch)]
		assert_bool(seen.has(key)).override_failure_message("a run repeats: "+key).is_false()
		seen[key]=true
	var least:=99;var most:=0
	for second in range(10,290,2):
		var talking:=0
		for run:Dictionary in runs:
			if not bool(run.aside) and float(run.t)<=second and second<float(run.t)+float(run.length)/float(run.pitch):talking+=1
		least=mini(least,talking);most=maxi(most,talking)
	assert_int(least).is_less_equal(1)
	assert_int(most).is_greater_equal(4)

func test_every_sound_the_director_names_is_made()->void:
	for act in Sound.BEAT_CUES:
		var name:=String(Sound.BEAT_CUES[act][0])
		if name.is_empty() or name in ["mutter","snort_wake"]:continue
		assert_bool(Foley.CUES.has(name)).override_failure_message("%s -> %s is not a sound" % [act,name]).is_true()
	for key in Sound.SOUND_NAMES:
		var cue:=String(Sound.SOUND_NAMES[key][0])
		assert_bool(Foley.CUES.has(cue) or cue=="snort_wake").override_failure_message("%s -> %s is not a sound" % [key,cue]).is_true()
	if not ResourceLoader.exists("res://scripts/hud/court_director.gd"):return
	var consts:Dictionary=(load("res://scripts/hud/court_director.gd") as GDScript).get_script_constant_map()
	var sounds:Dictionary=consts.get("SOUNDS",{}) if consts.get("SOUNDS") is Dictionary else {}
	for act in sounds:
		var name:=String(sounds[act][0])
		if name.is_empty():continue
		assert_bool(Sound.knows(name)).override_failure_message("the director's %s (for %s) is not made" % [name,act]).is_true()
	if consts.has("HUSH_SOUND"):assert_bool(Sound.knows(String(consts.HUSH_SOUND))).is_true()
	for name in ["gasp_room","babble_mutter"]:assert_bool(Sound.knows(name)).is_true()

func test_a_sound_beat_plays_its_sound()->void:
	var made:=_court()
	var sound:Node=made[1]
	Sound.set_volume(1.0)
	sound.call("on_beat",{"t":0.0,"who":"main","act":"sound","args":{"name":"growl","gain":0.8,"who":"main"}},null)
	var heard:Array=sound.get("played")
	assert_int(heard.size()).is_equal(1)
	assert_str(String(heard[0].name)).is_equal("stomach_growl")
	# the mood and the look of an act are silent; with a director that names
	# its sounds, so is the act itself (its sound came as its own beat)
	sound.call("on_beat",{"t":0.0,"who":"main","act":"mood","args":{"beat":"stomach_growl"}},null)
	if Sound.director_names_sounds():
		sound.call("on_beat",{"t":0.0,"who":"main","act":"play","args":{"clip":"stomach_growl","beat":"stomach_growl"}},null)
	assert_int((sound.get("played") as Array).size()).is_equal(1)
	# a person does not bleat
	sound.call("sound_for_act","bleat","main",null,{})
	assert_int((sound.get("played") as Array).size()).is_equal(1)
	# the room's hush is a murmur cut
	sound.call("on_beat",{"t":0.0,"who":"room","act":"sound","args":{"name":"murmur_cut","dur":2.0,"who":"room"}},null)
	assert_bool(sound.call("hushed")).is_true()
	# footsteps at a pace are queued, a mutter is a whispered voice
	sound.call("on_beat",{"t":0.0,"who":"main","act":"sound","args":{"name":"footsteps","pace":"stomp","gain":0.9}},null)
	assert_int((sound.get("_queue") as Array).size()).is_greater(1)
	sound.call("on_beat",{"t":0.0,"who":"main","act":"sound","args":{"name":"babble_mutter","words":5,"people":"player","gain":0.5}},null)
	assert_str(String((sound.get("played") as Array).back().name)).is_equal("voice")

func test_the_glottis_is_an_lf_pulse()->void:
	# a period of flow derivative that returns the flow to where it began, its
	# sharpest fall at -1; breathier shapes have a stronger first harmonic
	var h12:=[]
	for rd in [0.5,1.1,2.2]:
		var made:Array=Voice.lf_pulse(rd,256)
		var pulse:PackedFloat32Array=made[0]
		var total:=0.0;var low:=0.0
		for i in 256:total+=pulse[i];low=minf(low,pulse[i])
		assert_float(absf(total/256.0)).is_less(0.01)
		assert_float(low).is_between(-1.05,-0.8)
		var re1:=0.0;var im1:=0.0;var re2:=0.0;var im2:=0.0
		for i in 256:
			var a:=TAU*float(i)/256.0
			re1+=pulse[i]*cos(a);im1+=pulse[i]*sin(a);re2+=pulse[i]*cos(2.0*a);im2+=pulse[i]*sin(2.0*a)
		h12.append(10.0*log((re1*re1+im1*im1)/(re2*re2+im2*im2))/log(10.0))
	assert_float(float(h12[1])).is_greater(float(h12[0]))
	assert_float(float(h12[2])).is_greater(float(h12[1]))

func test_the_murmur_speaks_our_tongue()->void:
	var ours:=Voice.phonology("player",SEED)
	var tracks:=Foley.murmur_tracks(ours,7,2.0)
	assert_int(tracks.size()).is_equal(Foley.MURMUR_VOICES.size())
	var plain:=Foley.murmur_tracks({},7,2.0)
	assert_bool(tracks[0]==plain[0]).is_false()
	var rng:=RandomNumberGenerator.new();rng.seed=3
	var hall:=Foley.murmur_mix(tracks,10,1.5,rng)
	assert_float(float(hall.size())/Synth.RATE).is_between(1.45,1.55)
	assert_float(Synth.rms_of(hall)).is_greater(0.001)

func test_the_dog_is_heard_now_and_then()->void:
	var made:=_court()
	var sound:Node=made[1]
	Sound.set_volume(1.0)
	assert_bool(sound.call("animal","dog","sniff",null)).is_true()
	# not again at once
	assert_bool(sound.call("animal","dog","sniff",null)).is_false()
	assert_bool(sound.call("animal","dog","bark",null)).is_true()
	assert_bool(sound.call("animal","dog","bark",null)).is_true()
	# a clip with no sound, a beast we do not know
	assert_bool(sound.call("animal","dog","idle",null)).is_false()
	assert_bool(sound.call("animal","ox","bark",null)).is_false()
	Sound.set_volume(0.0)
	assert_bool(sound.call("animal","dog","scratch",null)).is_false()

class FakeStage extends Control:
	var extras:={}
	var audience_key:="test"
	func figure(_key:String)->Object:return null
	## A camera's view of the hall: x metres to pixels across a 1536 wide stage.
	func world_to_stage(point:Vector3)->Vector2:return Vector2(768.0+point.x*200.0,400.0)

static func _balance(cap:AudioEffectCapture)->Vector2:
	var n:=cap.get_frames_available()
	var buf:=cap.get_buffer(n)
	var l:=0.0;var r:=0.0
	for v in buf:l+=v.x*v.x;r+=v.y*v.y
	return Vector2(sqrt(l/maxf(1.0,float(n))),sqrt(r/maxf(1.0,float(n))))

func _heard(sound:Node,cap:AudioEffectCapture,body:Node3D)->Vector2:
	cap.clear_buffer()
	sound.call("cue","creak",body,{"variant":0,"pitch":1.0,"db":6.0})
	await get_tree().create_timer(0.7).timeout
	return _balance(cap)

func test_sounds_come_from_where_people_stand()->void:
	# someone at the left edge of the picture is heard 4-6 dB to the left,
	# someone in the middle in the middle
	var stage:=FakeStage.new();stage.size=Vector2(1536,864)
	var left:=Node3D.new();stage.add_child(left);left.position=Vector3(-3.0,0.0,0.0)
	var middle:=Node3D.new();stage.add_child(middle)
	var right:=Node3D.new();stage.add_child(right);right.position=Vector3(3.0,0.0,0.0)
	add_child(stage)
	auto_free(stage)
	stage.size=Vector2(1536,864)
	var sound:Node=Sound.attach(stage)
	Sound.set_volume(1.0)
	for k in range(-Sound.PAN_STEPS,Sound.PAN_STEPS+1):assert_int(AudioServer.get_bus_index(Sound.pan_bus(k))).is_greater_equal(0)
	assert_int(sound.call("pan_of",left)).is_equal(-Sound.PAN_STEPS)
	assert_int(sound.call("pan_of",middle)).is_equal(0)
	var cap:=AudioEffectCapture.new();cap.buffer_length=3.0
	AudioServer.add_bus_effect(0,cap)
	var slot:=AudioServer.get_bus_effect_count(0)-1
	await get_tree().process_frame
	var from_left:Vector2=await _heard(sound,cap,left)
	var from_middle:Vector2=await _heard(sound,cap,middle)
	var from_right:Vector2=await _heard(sound,cap,right)
	AudioServer.remove_bus_effect(0,slot)
	var db_left:=20.0*log(from_left.x/maxf(from_left.y,0.000001))/log(10.0)
	var db_right:=20.0*log(from_right.y/maxf(from_right.x,0.000001))/log(10.0)
	var db_middle:=20.0*log(from_middle.x/maxf(from_middle.y,0.000001))/log(10.0)
	prints("left %.1f dB, middle %.1f dB, right %.1f dB" % [db_left,db_middle,db_right])
	assert_float(from_left.x+from_left.y).override_failure_message("nothing was heard").is_greater(0.0001)
	assert_float(db_left).is_between(4.0,7.0)
	assert_float(db_right).is_between(4.0,7.0)
	assert_float(absf(db_middle)).is_less(0.5)
