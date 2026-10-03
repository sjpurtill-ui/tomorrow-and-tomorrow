extends GdUnitTestSuite
## THE COURT'S SOUND (scripts/hud/court_sound.gd, court_voice.gd,
## court_foley.gd, court_synth.gd):
## - every sound is made, in range, without a click at either end;
## - the same seed makes the same samples;
## - our people and another people's envoy babble differently (each in its
##   own tongue's sounds), and the babble keeps the mouth's own timing;
## - fear is higher than pride; a mutter is a whisper;
## - nothing plays while the court's sound is muted or the court is hidden;
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
	assert_bool(beds.has("murmur")).is_true()
	assert_bool(beds.has("fire")).is_true()
	sound.call("hush",true)
	assert_bool(sound.call("hushed")).is_true()
	sound.call("hush",false)
	assert_bool(sound.call("hushed")).is_false()
	# the god's words hush the room
	sound.call("god","Be still.",1.5,"favour")
	assert_bool(sound.call("hushed")).is_true()

func test_the_directors_heard_acts_have_sounds()->void:
	for act in Sound.BEAT_CUES:
		var name:=String(Sound.BEAT_CUES[act][0])
		if name.is_empty() or name in ["mutter","snort_wake"]:continue
		assert_bool(Foley.CUES.has(name)).override_failure_message("%s -> %s is not a sound" % [act,name]).is_true()
	if ResourceLoader.exists("res://scripts/hud/court_director.gd"):
		var consts:Dictionary=(load("res://scripts/hud/court_director.gd") as GDScript).get_script_constant_map()
		var acts:Dictionary=consts.get("ACTS",{}) if consts.get("ACTS") is Dictionary else {}
		if not acts.is_empty():
			# the director's silent-room bits are all heard
			for act in ["snore","stomach_growl","floor_creak","swallow_loud","stifle_cough","drop_bowl","gasp","knees_knock","faint","bleat","whimper","sniff","set_down_bundle","stifle_laugh"]:
				assert_bool(acts.has(act)).override_failure_message("director has no %s" % act).is_true()
				assert_bool(Sound.BEAT_CUES.has(act)).is_true()

func test_a_beat_plays_its_sound()->void:
	var made:=_court()
	var sound:Node=made[1]
	Sound.set_volume(1.0)
	sound.call("on_beat",{"t":0.0,"who":"main","act":"play","args":{"clip":"stomach_growl","beat":"stomach_growl"}},null)
	var heard:Array=sound.get("played")
	assert_int(heard.size()).is_equal(1)
	assert_str(String(heard[0].name)).is_equal("stomach_growl")
	# the mood and the look of the same act are silent
	sound.call("on_beat",{"t":0.0,"who":"main","act":"mood","args":{"beat":"stomach_growl"}},null)
	assert_int((sound.get("played") as Array).size()).is_equal(1)
	# a person does not bleat
	sound.call("on_beat",{"t":0.0,"who":"main","act":"play","args":{"beat":"bleat"}},null)
	assert_int((sound.get("played") as Array).size()).is_equal(1)
