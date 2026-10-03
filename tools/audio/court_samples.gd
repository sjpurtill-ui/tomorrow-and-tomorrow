extends SceneTree
## Renders the court's sounds to .wav files for review by ear (nothing in the
## game reads these). Headless:
##   godot --headless --path <project> -s res://tools/audio/court_samples.gd -- <out_dir> [all]
## Writes the review set (our people's babble, two envoys, a gasp then
## silence, a snore, a stomach growl in a silent room, the fire bed, the god's
## swell for wrath and for favour) and, with "all", every cue under cues/.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const Music:=preload("res://scripts/hud/court_music.gd")

var out_dir:=""

func _init()->void:
	call_deferred("_run")

func _save(name:String,samples:PackedFloat32Array,peak:=0.7)->void:
	var s:=Synth.to_stream(samples,peak)
	var path:=out_dir.path_join(name+".wav")
	s.save_to_wav(path)
	print("wrote %s (%.1fs)" % [path,float(samples.size())/Synth.RATE])

func _save_stereo(name:String,interleaved:PackedFloat32Array)->void:
	var data:=PackedByteArray();data.resize(interleaved.size()*2)
	for i in interleaved.size():data.encode_s16(i*2,clampi(int(interleaved[i]*32767.0),-32768,32767))
	var s:=AudioStreamWAV.new();s.format=AudioStreamWAV.FORMAT_16_BITS;s.mix_rate=Synth.RATE;s.stereo=true;s.data=data
	s.save_to_wav(out_dir.path_join(name+".wav"))
	print("wrote %s" % name)

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	out_dir=args[0] if args.size()>0 else "user://court_samples"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var seed_value:=Sound.world_seed()
	if seed_value==0:seed_value=424242
	var started:=Time.get_ticks_msec()
	var lines:=["Great one, the stores are thin. We ask for rain, and for patience with the young ones.",
		"The herds came back from the river with three fewer. I counted them twice.",
		"Must we give them the whole field? They took the far one last spring!"]
	# Our people: a man, a woman, an elder, a child; then an envoy of each of two other peoples.
	var ours:=[["Hena Tuvasi","male",38,"neutral",""],["Suri Danek","female",33,"warm",""],["Ama Seld","female",71,"afraid",""],["Lio","male",7,"warm",""],["Orrin Vael","male",47,"defiant","War leader"]]
	var items:Array=[];var t:=0.3
	for i in ours.size():
		var who:Array=ours[i]
		var v:=Voice.spec({"name":who[0],"person_id":10+i,"sex":who[1],"age":who[2],"office_title":who[4]},"player",seed_value)
		var line:String=lines[i%lines.size()]
		var secs:=clampf(line.length()*0.025,0.35,4.0)
		items.append({"t":t,"voice":line,"seconds":secs,"mood":who[3],"spec":v})
		t+=secs+0.7
		if i==0:print("our people speak %s" % String(v.tongue.family))
	_save("01_our_people_babble",Sound.render_scene(items,t+0.3))
	# Two envoys of two other peoples (two different sound families).
	var families:={}
	var envoys:Array=[]
	for k in range(1,30):
		var owner:="civ_%02d" % k
		var fam:=String(Voice.phonology(owner,seed_value).family)
		if fam==String(Voice.phonology("player",seed_value).family) or families.has(fam):continue
		families[fam]=true;envoys.append(owner)
		if envoys.size()>=2:break
	for e in envoys.size():
		var owner:String=envoys[e]
		var v:=Voice.spec({"name":"Envoy %d" % e,"person_id":0,"sex":"female" if e==1 else "male","age":44},owner,seed_value,{"temper":"haughty" if e==0 else "nervous"})
		var line:String=lines[(e+1)%lines.size()]
		var secs:=clampf(line.length()*0.025,0.35,4.0)
		var mood:="proud" if e==0 else "afraid"
		var scene:=[{"t":0.2,"voice":line,"seconds":secs,"mood":mood,"spec":v},{"t":0.4+secs,"voice":lines[0],"seconds":3.0,"mood":"neutral","spec":v}]
		_save("02_envoy_%d_%s_babble" % [e+1,String(v.tongue.family)],Sound.render_scene(scene,secs+3.8))
	# The room's talk is in our people's own tongue.
	var tongue_key:=Sound.register_tongue("player",seed_value)
	# The room murmurs; the god's wrath lands: the gasp, the boom, the murmur
	# cut dead; the fire's breath; the silence; then talk creeps back.
	var scene2:=[{"t":0.0,"bed":"fire","until":9.0},{"t":0.0,"talk":tongue_key,"until":2.4,"release":0.06,"seed":3},
		{"t":2.35,"cue":"god_wrath_boom","variant":0,"db":-3.0},{"t":2.4,"cue":"room_gasp","variant":0},
		{"t":6.4,"talk":tongue_key,"until":9.0,"attack":1.5,"seed":4}]
	_save("03_gasp_then_silence",Sound.render_scene(scene2,9.0))
	_save("04_snore",Sound.render_scene([{"t":0.0,"bed":"fire","until":6.0,"db":-8.0},{"t":0.4,"cue":"snore","variant":0},{"t":3.4,"cue":"snore","variant":2}],6.0))
	_save("05_stomach_growl_silent_room",Sound.render_scene([{"t":0.0,"bed":"fire","until":5.0,"db":-6.0},{"t":0.0,"talk":tongue_key,"until":0.8,"release":0.06,"seed":5},{"t":1.6,"cue":"stomach_growl","variant":1},{"t":3.9,"cue":"swallow","variant":0}],5.0))
	var fire:=[{"t":0.0,"bed":"fire","until":12.0}]
	var rng:=RandomNumberGenerator.new();rng.seed=7
	var ft:=0.4
	while ft<11.5:
		var v:=rng.randi_range(0,5)
		if v>=4 and rng.randf()<0.6:v=rng.randi_range(0,3)
		fire.append({"t":ft,"cue":"fire_pop","variant":v,"db":rng.randf_range(-3.0,1.5)});ft+=rng.randf_range(0.25,1.6)
	fire.append({"t":4.0,"cue":"fire_hiss","variant":1});fire.append({"t":8.5,"cue":"log_settle","variant":0})
	_save("06_fire_bed",Sound.render_scene(fire,12.0))
	_save("07_god_swell_wrath",Sound.render_scene([{"t":0.0,"god":"god_swell_wrath","until":7.0,"release":2.2,"attack":1.2,"level":-11.0},{"t":0.2,"cue":"god_wrath_boom","variant":1,"db":-4.0}],7.5))
	_save("08_god_swell_favour",Sound.render_scene([{"t":0.0,"god":"god_swell_favour","until":7.0,"release":2.2,"attack":1.2,"level":-14.0}],7.5))
	# sustained vowels, to measure the voice against clinical norms (jitter, shimmer, HNR)
	for reg in ["man","woman"]:
		var sv:=Voice.spec({"name":"Held %s" % reg,"person_id":77,"sex":"male" if reg=="man" else "female","age":35},"player",seed_value)
		_save("09_sustained_%s" % reg,Voice.gesture(sv,[[0.06,"a",0.0,0.0,1.0],[2.2,"a",1.0,0.0,1.0],[0.12,"a",0.0,0.0,0.97]],5))
	# five minutes of the crowd as the court plays it: no loop to hear
	_save("10_crowd_5_minutes",Sound.render_scene([{"t":0.0,"bed":"fire","until":300.0,"db":-6.0},{"t":0.0,"talk":tongue_key,"until":300.0,"seed":9}],300.0))
	# where people stand: the same gasp from the left edge, the middle and the right edge
	var gasp:=Synth.samples_of(Sound.stream_for("gasp",0))
	var lr:=PackedFloat32Array();lr.resize(Synth.n_of(3.3)*2)
	var k_at:=0
	for k in [-Sound.PAN_STEPS,0,Sound.PAN_STEPS]:
		var pan:=float(k)*Sound.PAN_STEP
		# AudioEffectPanner's own sums, as the Court buses play them
		var lv:=clampf(1.0-pan,0.0,1.0);var rv:=clampf(1.0+pan,0.0,1.0)
		var at:=Synth.n_of(0.2+1.05*k_at)
		for i in gasp.size():
			var x:=gasp[i]*0.6
			lr[(at+i)*2]+=x*lv+x*(1.0-rv)
			lr[(at+i)*2+1]+=x*rv+x*(1.0-lv)
		k_at+=1
	_save_stereo("11_left_middle_right",lr)
	# the musician, by what the people know (each age), in our people's own way
	var ages:={"hum":[],"flute_drum":["bone_flutes_drums"],"reed_rattle":["bone_flutes_drums","rattles_drums_pipes"],
		"lyre":["bone_flutes_drums","rattles_drums_pipes","harps_and_lyres"],"temple":["bone_flutes_drums","rattles_drums_pipes","harps_and_lyres","temple_choirs"]}
	for age in ages:
		var mk:=Sound.register_music(tongue_key,ages[age])
		var tune:Array=[];var at:=0.3
		for k in [0,1,2]:
			tune.append({"t":at,"music":"music@"+mk,"variant":k})
			at+=Sound.stream_for("music@"+mk,k).get_length()+1.2
		_save("12_music_%s" % age,Sound.render_scene(tune,at+0.3))
	# two other peoples, the same age: their own scales and beats
	var pieces:Array=[];var at2:=0.3
	# two other peoples whose beat differs from ours and each other's
	var players:Array=["player"]
	var beats:={String(Music.METERS.get(String(Voice.phonology("player",seed_value).family),"four")):true}
	for k in range(1,30):
		var other:="civ_%02d" % k
		var beat:=String(Music.METERS.get(String(Voice.phonology(other,seed_value).family),"four"))
		if beats.has(beat):continue
		beats[beat]=true;players.append(other)
		if players.size()>=3:break
	for owner in players:
		var fam:=String(Voice.phonology(owner,seed_value).family)
		var mk2:=Sound.register_music(Sound.register_tongue(owner,seed_value),["bone_flutes_drums"])
		for k in [0,4]:
			pieces.append({"t":at2,"music":"music@"+mk2,"variant":k})
			at2+=Sound.stream_for("music@"+mk2,k).get_length()+0.6
		at2+=1.2
		print("music of %s (%s): %s, %s" % [owner,fam,str(Sound.music_spec(mk2).scale),String(Sound.music_spec(mk2).meter)])
	_save("13_music_three_peoples",Sound.render_scene(pieces,at2))
	# the god's wrath lands mid-phrase: the music stops dead (squeak, a stray
	# tap), silence but the fire; it creeps back, tentatively, then plays on
	var mk3:=Sound.register_music(tongue_key,["bone_flutes_drums"])
	var p2:=Sound.stream_for("music@"+mk3,2).get_length()
	var stop_scene:=[{"t":0.0,"bed":"fire","until":24.0,"db":-4.0},{"t":0.0,"talk":tongue_key,"until":3.0,"release":0.06,"seed":6},
		{"t":0.3,"music":"music@"+mk3,"variant":0,"until":3.0,"release":0.03},
		{"t":3.45,"cue":"god_wrath_boom","variant":0,"db":-4.0},{"t":3.8,"cue":"room_gasp","variant":1},
		{"t":3.0,"god":"god_swell_wrath","until":6.6,"release":2.2,"attack":0.8,"level":-11.0},
		{"t":3.0,"music":"musicstop@"+mk3,"variant":0,"db":5.0},{"t":3.29,"music":"musictap@"+mk3,"db":3.0},
		{"t":9.0,"talk":tongue_key,"until":24.0,"attack":1.5,"seed":7},
		{"t":11.0,"music":"music@"+mk3,"variant":1,"until":12.6,"release":0.6,"db":-9.0},
		{"t":15.5,"music":"music@"+mk3,"variant":2}]
	_save("14_music_wrath_stops_it_dead",Sound.render_scene(stop_scene,minf(24.0,15.8+p2)))
	# a gift taken: the musician plays it in
	var p3:=Sound.stream_for("music@"+mk3,3).get_length()
	_save("15_gift_flourish",Sound.render_scene([{"t":0.3,"music":"music@"+mk3,"variant":3},{"t":0.9+p3,"music":"musicfl@"+mk3,"db":3.0}],2.6+p3+Sound.stream_for("musicfl@"+mk3,0).get_length()))
	# seven-note peoples, each with its own mode, ornaments and rhythm (bone flute and drum)
	var seven:Array=[];var at4:=0.3
	for fam in ["semitic","indo_aryan","slavic","dravidian","romance","iranic"]:
		var spec:=Music.people(fam,seed_value,["bone_flutes_drums"])
		var tune:=Music.phrase(spec,0)
		var top:=Synth.peak_of(tune)
		if top>0.0:Synth.scale(tune,0.6/top)
		seven.append([at4,tune])
		print("seven-note %s: mode scale %s, ornament %s, %s" % [fam,str(spec.scale),String(spec.ornament),String(spec.meter)])
		at4+=float(tune.size())/Synth.RATE+1.0
	var seven_out:=Synth.buffer(at4)
	for piece in seven:Synth.mix_into(seven_out,piece[1],Synth.n_of(float(piece[0])),1.0)
	_save("16_seven_note_peoples",seven_out)
	if args.has("all"):
		DirAccess.make_dir_recursive_absolute(out_dir.path_join("cues"))
		for name in Foley.CUES:
			for v in Foley.variants(name):
				var s:=Sound.stream_for(name,v)
				s.save_to_wav(out_dir.path_join("cues/%s_%d.wav" % [name,v]))
		for name in Foley.BEDS:
			Sound.stream_for(name,0).save_to_wav(out_dir.path_join("cues/bed_%s.wav" % name))
	# a measure of the music's own character: each people's scale and beat
	var index:=FileAccess.open(out_dir.path_join("index.txt"),FileAccess.WRITE)
	if index!=null:
		index.store_string("""The court's sounds (all synthesized; levels as in the game, before the Court bus).
01_our_people_babble   our people: a man, a woman, a frightened elder, a child, the war leader (gravel)
02_envoy_*             two envoys of two other peoples (the family is in the name): a haughty one, a nervous one
03_gasp_then_silence   the room talking by the fire; the god's wrath lands (boom), the whole room gasps,
                       the talk cuts dead; only the fire; then the talk creeps back
04_snore               a snore by the fire, twice (the second whistles)
05_stomach_growl_...   the talk stops; silence; a stomach growls; someone swallows
06_fire_bed            the fire bed with its random pops, a sap hiss and a log settling
07_god_swell_wrath     the swell under the god's words in wrath (with the boom)
08_god_swell_favour    the same in favour
09_sustained_*         a held "aah" (man, woman): for measuring the voice, not for listening
10_crowd_5_minutes     five minutes of the crowd by the fire as the court plays it (it never loops)
11_left_middle_right   stereo: the same gasp from the left edge, the middle and the right edge
12_music_<age>         the court musician, three phrases, by what our people know: hum (nothing yet),
                       flute_drum (bone flute, frame drum), reed_rattle (reed pipe, clay drum, rattle),
                       lyre, temple (lyre and small cymbals)
13_music_three_peoples the same age (bone flute, frame drum) played by our people and two others with
                       other beats: each its own scale, beat, key and tunes
14_music_wrath_stops_it_dead  music by the fire; the musician stops dead (squeak, a stray tap) a beat
                       BEFORE the god's boom lands, then silence;
                       a tentative few notes later; then it plays on
15_gift_flourish       a phrase, then a gift taken: a run and a roll
16_seven_note_peoples  six peoples whose scales have seven notes (semitic, indo_aryan, slavic, dravidian,
                       romance, iranic), each its own mode, ornaments (mordents, slides, turns, gamaka
                       shakes, grace notes, trills) and rhythm
cues/                  every one-shot and bed on its own (name_variant.wav)
""")
		index.close()
	print("done in %d ms" % (Time.get_ticks_msec()-started))
	quit()
