extends SceneTree
## Renders the executions' sounds to .wav files for review by ear (nothing in
## the game reads these). Headless:
##   godot --headless --path <project> -s res://tools/audio/court_exec_samples.gd -- <out_dir> [all]
## The acts as the court plays them (play_act's track, the fire under them,
## the roll on a frame drum, the punchline by the age), a tour of every sound,
## and with "all" each sound on its own under cues/.

const Sound:=preload("res://scripts/hud/court_sound.gd")
const Gore:=preload("res://scripts/hud/court_gore_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")

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
	var end:=lead+last+3.5
	items[0]["until"]=end
	for item:Dictionary in Gore.ACTS[act]:
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
	var index:=FileAccess.open(out_dir.path_join("index.txt"),FileAccess.WRITE)
	if index!=null:
		var lines:="The executions' sounds (all synthesized; mixed at the game's levels, then lifted for listening).\n"
		lines+="20_act02_club_home_run          drum roll; wind-up; whoosh; CRACK; the head's whistle; plop in the pot; gasp; stir; lid; ba-DUM; a lone clap\n"
		lines+="21_act10_three_swing_beheading  roll; THUNK (stuck), creak, pull; CLANG (bounced), \"ow!\"; CHOP, pop, the roll across the floor, the geyser, gasp, patter on the front row, the blink; ba-dum-TSS (a temple age); retching\n"
		lines+="22_act04_dog_dinner             roll; snarls; dragged off; crunching behind the windbreak; groans; one more crunch; paws trotting back; the bone dropped; tail thumping; ba-DUM\n"
		lines+="23_every_execution_sound        every sound once, in this order: %s\n" % ", ".join(PackedStringArray(order))
		lines+="cues/                           each sound and variant on its own\n"
		index.store_string(lines);index.close()
	if args.has("all"):
		DirAccess.make_dir_recursive_absolute(out_dir.path_join("cues"))
		for cue in Gore.CUES:
			for v in Gore.variants(String(cue)):
				Sound.stream_for(String(cue),v).save_to_wav(out_dir.path_join("cues/%s_%d.wav" % [cue,v]))
	print("done in %d ms" % (Time.get_ticks_msec()-started))
	quit()
