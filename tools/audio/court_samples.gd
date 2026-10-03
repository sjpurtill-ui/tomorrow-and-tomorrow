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

var out_dir:=""

func _init()->void:
	call_deferred("_run")

func _save(name:String,samples:PackedFloat32Array,peak:=0.7)->void:
	var s:=Synth.to_stream(samples,peak)
	var path:=out_dir.path_join(name+".wav")
	s.save_to_wav(path)
	print("wrote %s (%.1fs)" % [path,float(samples.size())/Synth.RATE])

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
	var talk_bed:="murmur@"+Sound.register_tongue("player",seed_value)
	# The room murmurs; the god's wrath lands: the gasp, the boom, the murmur
	# cut dead; the fire's breath; the silence; then talk creeps back.
	var scene2:=[{"t":0.0,"bed":"fire","until":9.0},{"t":0.0,"bed":talk_bed,"until":2.4,"release":0.06},
		{"t":2.35,"cue":"god_wrath_boom","variant":0,"db":-3.0},{"t":2.4,"cue":"room_gasp","variant":0},
		{"t":6.4,"bed":talk_bed,"until":9.0,"attack":2.4}]
	_save("03_gasp_then_silence",Sound.render_scene(scene2,9.0))
	_save("04_snore",Sound.render_scene([{"t":0.0,"bed":"fire","until":6.0,"db":-8.0},{"t":0.4,"cue":"snore","variant":0},{"t":3.4,"cue":"snore","variant":2}],6.0))
	_save("05_stomach_growl_silent_room",Sound.render_scene([{"t":0.0,"bed":"fire","until":5.0,"db":-6.0},{"t":0.0,"bed":talk_bed,"until":0.8,"release":0.06},{"t":1.6,"cue":"stomach_growl","variant":1},{"t":3.9,"cue":"swallow","variant":0}],5.0))
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
	if args.has("all"):
		DirAccess.make_dir_recursive_absolute(out_dir.path_join("cues"))
		for name in Foley.CUES:
			for v in Foley.variants(name):
				var s:=Sound.stream_for(name,v)
				s.save_to_wav(out_dir.path_join("cues/%s_%d.wav" % [name,v]))
		for name in Foley.BEDS:
			Sound.stream_for(name,0).save_to_wav(out_dir.path_join("cues/bed_%s.wav" % name))
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
cues/                  every one-shot and bed on its own (name_variant.wav)
""")
		index.close()
	print("done in %d ms" % (Time.get_ticks_msec()-started))
	quit()
