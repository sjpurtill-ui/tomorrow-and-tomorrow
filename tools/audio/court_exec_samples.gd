extends SceneTree
## Renders the executions' sounds to .wav files for review by ear (nothing in
## the game reads these). Headless:
##   godot --headless --path <project> -s res://tools/audio/court_exec_samples.gd -- <out_dir> [all]
## The acts as the court plays them (play_act's track, the fire under them,
## the roll on a frame drum, the punchline by the age), a tour of every sound,
## and with "all" each sound on its own under cues/. The room's reactions:
## every kind in several people's voices, one act played three times in a
## hall of seven (a different room each time), and a terrified hall.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Gore:=preload("res://scripts/hud/court_gore_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const Reactions:=preload("res://scripts/hud/court_reactions.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")

class Figure extends RefCounted:
	var body3d:Node3D
	var person:Dictionary={}
	var leaving:=false

## A hall for play_act: figures standing across the picture.
class Hall extends Control:
	var extras:={}
	var cast_order:Array[String]=[]
	var audience_key:="samples"
	var figs:={}
	func figure(key:String)->Object:return figs.get(key)
	func world_to_stage(point:Vector3)->Vector2:return Vector2(768.0+point.x*200.0,400.0)

var out_dir:=""

func _init()->void:
	call_deferred("_run")

func _save(name:String,samples:PackedFloat32Array)->void:
	Synth.to_stream(samples,0.7).save_to_wav(out_dir.path_join(name+".wav"))
	print("wrote %s (%.1fs)" % [name,float(samples.size())/Synth.RATE])

## An act's track as play_act() resolves it (roll and punch by the age).
func _act(act:String,drum:String,cymbal:bool)->Array:
	var items:Array=[{"t":0.0,"bed":"fire","until":0.0,"db":-8.0}]
	var first:=0.0
	var last:=0.0
	for item:Dictionary in Gore.ACTS[act]:first=minf(first,float(item.t));last=maxf(last,float(item.t))
	var lead:=-first+0.3
	var end:=lead+last+3.0
	items[0]["until"]=end
	for item:Dictionary in Gore.ACTS[act]:
		if String(item.get("if",""))=="hungry":continue
		var cue:=String(item.cue)
		var v:=int(item.get("variant",0))
		if cue=="roll":
			cue="log_roll" if drum=="" else "drum_roll";v=1 if drum=="clay" else 0
		elif cue=="punch":
			cue="punch_cymbal" if cymbal else ("punch_log" if drum=="" else "punch_drum");v=1 if drum=="clay" else 0
		items.append({"t":lead+float(item.t),"cue":cue,"variant":v,"db":float(item.get("db",0.0))})
	return [items,end]

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	out_dir=args[0] if args.size()>0 else "user://court_exec_samples"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var started:=Time.get_ticks_msec()
	var plan:={"20_act02_club_home_run":["club_home_run","frame",false],
		"21_act10_three_swing_beheading":["three_swing_beheading","clay",true],
		"22_act04_dog_dinner":["dog_dinner","frame",false]}
	# every act, by number, at the age it needs (the punchline as that age plays it)
	var ages:={1:"",3:"",5:"frame",6:"",7:"frame",8:"frame",9:"frame",11:"clay",12:"clay",13:"clay",14:"clay",15:"clay",
		16:"clay",17:"clay",18:"clay",19:"clay",20:"clay",21:"clay",22:"clay",23:"clay",24:"clay",25:"clay"}
	for n in ages:
		var cym:=int(n)>=17
		plan["act%02d_%s" % [int(n),Gore.ACT_NUMBERS[int(n)]]]=[Gore.ACT_NUMBERS[int(n)],String(ages[n]),cym]
	for name in plan:
		var spec:Array=plan[name]
		var made:=_act(String(spec[0]),String(spec[1]),bool(spec[2]))
		_save(String(name),Sound.render_scene(made[0],float(made[1])))
	# every sound once, in order, a beat apart
	var tour:Array=[];var at:=0.3
	var order:Array=Gore.CUES.keys()
	for cue in order:
		tour.append({"t":at,"cue":String(cue),"variant":0})
		at+=Sound.stream_for(String(cue),0).get_length()+0.6
	_save("23_every_execution_sound",Sound.render_scene(tour,at+0.3))
	_reactions()
	var index:=FileAccess.open(out_dir.path_join("index.txt"),FileAccess.WRITE)
	if index!=null:
		var lines:="The executions' sounds (all synthesized; mixed at the game's levels, then lifted for listening).\n"
		lines+="20_act02_club_home_run          drum roll; wind-up; whoosh; CRACK; the head's whistle; plop in the pot; gasp; stir; lid; ba-DUM; a lone clap\n"
		lines+="21_act10_three_swing_beheading  roll; THUNK (stuck), creak, pull; CLANG (bounced), \"ow!\"; CHOP, pop, the roll across the floor, the geyser, gasp, patter on the front row, the blink; ba-dum-TSS (a temple age); retching\n"
		lines+="22_act04_dog_dinner             roll; snarls; dragged off; crunching behind the windbreak; groans; one more crunch; paws trotting back; the bone dropped; tail thumping; ba-DUM\n"
		lines+="actNN_<name>                    each of the 25 acts by number (the roll on a log before drums, a frame or clay drum after; cymbals from act 17 on)\n"
		lines+="23_every_execution_sound        every sound once, in this order: %s\n" % ", ".join(PackedStringArray(order))
		lines+="24_room_reactions_every_kind    each reaction (%s) in four voices: a girl of eight, a fawning courtier, an old woman, a young man of another people\n" % ", ".join(PackedStringArray(Reactions.KINDS))
		lines+="25_act10_three_times_with_people the three-swing beheading three times in a hall of seven (a child, a flatterer, a scribe, a proud captain, a farmer in the front row, a timid girl, an elder): each time different people react, in their own voices\n"
		lines+="26_act10_terrified_hall         the same act with the people in dread: nobody gasps or laughs; one swallow, knees knocking\n"
		lines+="cues/                           each sound and variant on its own\n"
		index.store_string(lines);index.close()
	if args.has("all"):
		DirAccess.make_dir_recursive_absolute(out_dir.path_join("cues"))
		for cue in Gore.CUES:
			for v in Gore.variants(String(cue)):
				Sound.stream_for(String(cue),v).save_to_wav(out_dir.path_join("cues/%s_%d.wav" % [cue,v]))
	print("done in %d ms" % (Time.get_ticks_msec()-started))
	quit()

## The room's reactions, by ear.
func _reactions()->void:
	var voices:=[Voice.spec({"name":"Pim","age":8,"sex":"female"},"player",7),
		Voice.spec({"name":"Sello","age":44,"sex":"male"},"player",7),
		Voice.spec({"name":"Abba","age":70,"sex":"female"},"player",7),
		Voice.spec({"name":"Kesh","age":19,"sex":"male"},"civ_03",7)]
	var tour:Array=[];var at:=0.3
	for kind in Reactions.KINDS:
		for k in voices.size():
			var b:=Reactions.make(String(kind),voices[k],31+k)
			tour.append({"t":at,"stream":Synth.to_stream(b),"db":float(Reactions.LEVELS[kind])})
			at+=float(b.size())/Synth.RATE+0.25
		at+=0.5
	_save("24_room_reactions_every_kind",Sound.render_scene(tour,at+0.3))
	Sound.sync_render=true
	var hall:=Hall.new();hall.size=Vector2(1536,864)
	root.add_child(hall)
	var cast:={"victim":[{"name":"Oru","age":40,"sex":"male"},{}],"headsman":[{"name":"Tak","age":35,"sex":"male"},{}],
		"kid":[{"name":"Pim","sex":"female"},{"role":"crowd","kind":"child","age":8}],
		"fawner":[{"name":"Sello","age":44,"sex":"male"},{}],
		"scribe":[{"name":"Ennu","age":50,"sex":"male"},{"role":"crowd","kind":"scribe"}],
		"captain":[{"name":"Rask","age":38,"sex":"male"},{"role":"crowd","pride":0.9,"courage":0.9}],
		"farmer":[{"name":"Dela","age":30,"sex":"female"},{"role":"crowd"}],
		"meek":[{"name":"Lin","age":22,"sex":"female"},{"role":"crowd","dread":0.8}],
		"elder":[{"name":"Abba","age":70,"sex":"female"},{"role":"crowd"}]}
	var x:=-3.0
	for key:String in cast:
		var f:=Figure.new();f.person=cast[key][0]
		var body:=Node3D.new();hall.add_child(body);body.position=Vector3(x,0,0);x+=0.75
		f.body3d=body;hall.figs[key]=f;hall.cast_order.append(key)
		if not (cast[key][1] as Dictionary).is_empty():hall.extras[key]=cast[key][1]
	var sound:Node=Sound.attach(hall)
	Sound.set_volume(1.0)
	sound.call("ambience","longhouse","autumn",{"era_tier":2,"known":["bone_flutes_drums","rattles_drums_pipes","harps_and_lyres","temple_choirs"]})
	var roles:={"victim":hall.figs.victim.body3d,"executioner":hall.figs.headsman.body3d,"flatterer":hall.figs.fawner.body3d,"front_row":hall.figs.farmer.body3d}
	var scene:Array=[];var offset:=0.3
	var said_log:=""
	for run in 3:
		var span:=_play_into(sound,roles,{},scene,offset)
		said_log+="  run %d: %s\n" % [run+1,_who_said(sound)]
		offset+=span+1.2
	_save("25_act10_three_times_with_people",Sound.render_scene(scene,offset))
	var dread:Array=[]
	var span2:=_play_into(sound,roles,{"dread":0.8},dread,0.3)
	_save("26_act10_terrified_hall",Sound.render_scene(dread,span2+0.6))
	var f2:=FileAccess.open(out_dir.path_join("25_who_reacted.txt"),FileAccess.WRITE)
	if f2!=null:f2.store_string("Who reacted in 25_act10_three_times_with_people (seconds after the act starts):\n"+said_log);f2.close()
	Sound.sync_render=false

## One act as the court queues it, laid into a scene from `offset`; returns its length.
func _play_into(sound:Node,roles:Dictionary,opts:Dictionary,scene:Array,offset:float)->float:
	(sound.get("_queue") as Array).clear()
	var now:float=sound.call("_now")
	sound.call("play_act","three_swing_beheading",roles,opts)
	var last:=0.0
	for item:Dictionary in (sound.get("_queue") as Array):
		var t:=float(item.at)-now
		if item.has("stream"):
			scene.append({"t":offset+t,"stream":item.stream,"db":float(item.db)})
			last=maxf(last,t+(item.stream as AudioStreamWAV).get_length())
		else:
			var o:Dictionary=item.opts
			var name:=String(item.name)
			scene.append({"t":offset+t,"cue":name,"variant":maxi(0,int(o.get("variant",0))),"db":float(o.get("db",0.0))})
			last=maxf(last,t+Sound.stream_for(name,maxi(0,int(o.get("variant",0)))).get_length())
	scene.append({"t":offset,"bed":"fire","until":offset+last+0.5,"db":-8.0})
	return last+0.5

func _who_said(sound:Node)->String:
	var now:float=sound.call("_now")
	var parts:PackedStringArray=[]
	for r:Dictionary in (sound.get("last_reactions") as Array):parts.append("%s (%s) %s at %.1f" % [r.who,r.temper,r.kind,float(r.at)-now])
	return ", ".join(parts)
