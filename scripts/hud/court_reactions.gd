extends RefCounted
## THE HALL'S OWN REACTIONS: when something happens before the god, the
## people standing there react in their own voices (court_voice.gd), each as
## the sort of person they are. The child goes "ewww" or giggles; the elder
## tuts or harrumphs; the flatterer gives a delighted "oh!" and claps; the
## pedant tuts; the proud harrumph or say nothing; the timid gasp and
## whimper; the kind wince and groan; and anyone may be sick or mutter an
## aside in their own tongue. Who reacts, how and when is drawn from the
## event's seed, so a long session never hears the same room twice.
##
## temper_of(person, entry, role) -> a temper; pick(temper, moment, rng) ->
## a reaction kind; make(kind, voice, seed) -> samples in that voice.
## Moments: "shock" (the blow lands), "disgust" (the aftermath), "amusement"
## (the punchline), "applause" (the flatterer's moment), "sick".
## Pure; make() is safe on a worker thread.

const Voice:=preload("res://scripts/hud/court_voice.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const RATE:=22050

const KINDS:=["gasp","groan","eugh","ewww","retch","laugh","giggle","oh","tut","hmph","whimper","mm","oof","mutter"]
## Each kind's level (dB) in the hall.
const LEVELS:={"gasp":-11.0,"groan":-12.0,"eugh":-12.0,"ewww":-12.0,"retch":-10.0,"laugh":-12.0,"giggle":-13.0,"oh":-11.0,
	"tut":-13.0,"hmph":-12.0,"whimper":-14.0,"mm":-13.0,"oof":-12.0,"mutter":-16.0}
## Literary voice models (character_voice.gd) that are pedants or flatterers at heart.
const PEDANTS:=["polonius","judge","cicero","aurelius","nestor","atticus"]
const FLATTERERS:=["falstaff","sancho","iago"]
## What each temper does at each moment: [kind, weight]... ("" says nothing).
const CHOICES:={
	"child":{"shock":[["whimper",3],["gasp",3],["ewww",1]],"disgust":[["ewww",5],["giggle",1]],"amusement":[["giggle",4],["ewww",1]],"sick":[["ewww",1]]},
	"elder":{"shock":[["gasp",2],["hmph",1],["tut",1]],"disgust":[["tut",2],["groan",2],["hmph",1]],"amusement":[["hmph",1],["laugh",1],["tut",1]],"sick":[["groan",1],["retch",1]]},
	"flatterer":{"shock":[["oh",3],["gasp",1]],"disgust":[["mm",2],["oh",1],["eugh",1]],"amusement":[["laugh",3],["oh",2]],"applause":[["oh",2],["mm",1]],"sick":[["oof",1]]},
	"pedant":{"shock":[["tut",2],["gasp",1]],"disgust":[["tut",3],["eugh",1]],"amusement":[["tut",2],["hmph",1]],"sick":[["tut",1]]},
	"proud":{"shock":[["hmph",2],["",2]],"disgust":[["hmph",2],["",1]],"amusement":[["hmph",2],["laugh",1]],"sick":[["hmph",1]]},
	"timid":{"shock":[["gasp",3],["whimper",2]],"disgust":[["eugh",2],["whimper",1],["retch",1]],"amusement":[["laugh",2],["whimper",1]],"sick":[["retch",2],["eugh",1]]},
	"kind":{"shock":[["gasp",2],["oof",2]],"disgust":[["groan",2],["eugh",2],["retch",1]],"amusement":[["laugh",1],["oof",1]],"sick":[["retch",2],["groan",1]]},
	"plain":{"shock":[["gasp",4],["oof",1]],"disgust":[["groan",2],["eugh",2],["retch",1]],"amusement":[["laugh",3],["hmph",1]],"sick":[["retch",2],["eugh",1]]},
}

## The sort of person someone is, from what the court knows of them: their
## role in the scene, age, kind (a director's extra), voice model, pride,
## courage, warmth, love and dread of the god.
static func temper_of(person:Dictionary,entry:Dictionary={},role:="")->String:
	if role=="flatterer":return "flatterer"
	var age:Variant=entry.get("age",person.get("age",35))
	var years:=int(age) if (age is int or age is float) else (9 if String(age)=="child" else (66 if String(age) in ["old","elder"] else 35))
	var kind:=String(entry.get("kind",person.get("kind","")))
	if years<13 or kind=="child":return "child"
	var model:=String(entry.get("voice",person.get("voice_model","")))
	if kind=="scribe" or model in PEDANTS:return "pedant"
	if model in FLATTERERS:return "flatterer"
	var pride:=float(entry.get("pride",person.get("pride",0.5)))
	var courage:=float(entry.get("courage",person.get("courage",0.5)))
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var empathy:=float(entry.get("empathy",personality.get("empathy",0.5)))
	var love:=float(entry.get("love",0.4))
	var dread:=float(entry.get("dread",0.2))
	if years>=56 or kind=="elder":return "elder"
	if pride>0.7 and courage>0.6:return "proud"
	if love>0.7 and pride<0.35:return "flatterer"
	if dread>0.55 or courage<0.3:return "timid"
	if empathy>0.7:return "kind"
	return "plain"

## A reaction for a temper at a moment ("" for silence).
static func pick(temper:String,moment:String,rng:RandomNumberGenerator)->String:
	var table:Dictionary=CHOICES.get(temper,CHOICES.plain)
	var options:Array=table.get(moment,table.get("shock",[]))
	var total:=0.0
	for o in options:total+=float(o[1])
	var roll:=rng.randf()*total
	for o in options:
		roll-=float(o[1])
		if roll<=0.0:return String(o[0])
	return ""

## A reaction in a person's own voice (their court_voice.gd spec), varied by
## the seed: each step a little longer or shorter, a little higher or lower.
static func make(kind:String,voice:Dictionary,seed_value:int)->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var v:=voice.duplicate()
	var s:=func(d:float)->float:return d*rng.randf_range(0.85,1.2)
	var p:=func(m:float)->float:return m*rng.randf_range(0.96,1.05)
	var b:PackedFloat32Array
	match kind:
		"gasp":
			v["breath"]=0.3
			b=Voice.gesture(v,[[0.012,"a",0.0,0.0,1.0],[s.call(0.05),"a",0.0,1.0,1.0],[s.call(0.07),"e",0.15,0.8,p.call(1.3)],[s.call(0.1),"e",0.1,0.5,p.call(1.35)],[0.06,"y",0.0,0.1,1.2]],rng.randi(),{"fear":0.5})
			Synth.highpass(b,250.0)
		"groan":
			v["breath"]=0.2
			b=Voice.gesture(v,[[0.02,"u",0.0,0.0,1.0],[s.call(0.15),"u",0.7,0.2,p.call(1.05)],[s.call(0.45),"a",0.65,0.25,p.call(0.8)],[0.08,"a",0.0,0.1,0.78]],rng.randi(),{"tired":0.4})
		"eugh":
			v["fry"]=float(v.get("fry",0.0))+0.15
			b=Voice.gesture(v,[[0.02,"e",0.0,0.0,1.0],[s.call(0.12),"e",0.8,0.15,p.call(1.15)],[s.call(0.28),"u",0.7,0.2,p.call(0.85)],[0.05,"u",0.0,0.0,0.8]],rng.randi(),{"anger":0.3})
		"ewww":
			b=Voice.gesture(v,[[0.02,"i",0.0,0.0,1.0],[s.call(0.1),"i",0.8,0.1,p.call(1.2)],[s.call(0.5),"u",0.8,0.1,p.call(1.05)],[s.call(0.12),"u",0.5,0.15,p.call(0.9)],[0.04,"u",0.0,0.0,0.9]],rng.randi())
		"retch":
			v["breath"]=0.5;v["fry"]=float(v.get("fry",0.0))+0.25
			var heave:=Voice.gesture(v,[[0.05,"a",0.0,0.6,1.0],[0.02,"a",0.0,0.0,1.0],[s.call(0.22),"o",0.9,0.5,0.8],[0.06,"a",0.0,0.0,0.75]],rng.randi())
			var again:=Voice.gesture(v,[[0.03,"a",0.0,0.6,1.0],[s.call(0.3),"a",1.0,0.6,0.72],[0.06,"a",0.0,0.0,0.7]],rng.randi())
			b=Synth.buffer(1.3)
			Synth.mix_into(b,heave,0,0.8)
			Synth.mix_into(b,again,Synth.n_of(0.5),1.0)
			var splash:=Synth.white(0.4,rng)
			Synth.bandpass(splash,1300.0,0.9)
			Synth.shape(splash,[[0.0,0.0],[0.01,1.0],[0.4,0.0]])
			Synth.mix_into(b,splash,Synth.n_of(0.68),0.5)
		"laugh","giggle":
			v["breath"]=0.3
			var steps:Array=[[0.01,"e",0.0,0.0,1.0]]
			var m:=1.2 if kind=="laugh" else 1.5
			for k in rng.randi_range(2,4):
				steps.append([0.03,"e",0.0,0.7,m])
				steps.append([s.call(0.07 if kind=="laugh" else 0.05),"e" if k%2==0 else "a",0.8,0.3,m*0.94])
				steps.append([s.call(0.07),"e",0.0,0.1,m*0.9])
				m*=0.93
			steps.append([0.05,"y",0.0,0.0,1.0])
			b=Voice.gesture(v,steps,rng.randi(),{"fear":0.3 if kind=="laugh" else 0.0,"joy":0.4})
		"oh":
			b=Voice.gesture(v,[[0.01,"o",0.0,0.0,1.1],[s.call(0.08),"o",1.0,0.1,p.call(1.4)],[s.call(0.3),"o",1.0,0.1,p.call(1.15)],[0.06,"u",0.0,0.0,1.1]],rng.randi(),{"joy":0.8})
		"mm":
			b=Voice.gesture(v,[[0.01,"u",0.0,0.0,1.0,1.0],[s.call(0.12),"u",0.8,0.05,p.call(1.15),1.0],[s.call(0.22),"u",0.8,0.05,p.call(1.25),1.0],[0.04,"u",0.0,0.0,1.2,1.0]],rng.randi(),{"joy":0.6})
		"hmph":
			b=Voice.gesture(v,[[0.01,"u",0.0,0.0,1.0,1.0],[0.06,"u",0.0,1.0,1.0,1.0],[s.call(0.14),"u",0.6,0.2,p.call(0.85),1.0],[0.04,"u",0.0,0.0,0.8,1.0]],rng.randi(),{"scorn":0.6})
		"whimper":
			v["tremor"]=0.05;v["tremor_hz"]=7.0;v["breath"]=0.35
			b=Voice.gesture(v,[[0.02,"u",0.0,0.0,1.1],[s.call(0.22),"i",0.5,0.35,p.call(1.35),0.5],[s.call(0.2),"i",0.3,0.3,p.call(1.2),0.5],[0.05,"y",0.0,0.0,1.1]],rng.randi(),{"fear":0.8})
		"oof":
			b=Voice.gesture(v,[[0.01,"u",0.0,0.0,1.0],[0.03,"u",0.0,0.9,1.0],[s.call(0.12),"u",0.6,0.4,p.call(0.85)],[0.05,"u",0.0,0.1,0.8]],rng.randi())
		"tut":
			# tsk-tsk: two sharp clicks of the tongue (no voice), sometimes three
			# (a small mouth clicks higher than a big one)
			var mouth:=float(v.get("fs",1.0))
			b=Synth.buffer(0.6)
			var at:=0.02
			for k in rng.randi_range(2,3):
				Synth.burst(b,at,0.004,rng.randf_range(2600.0,3600.0)*mouth,2.0,1.0,rng)
				Synth.burst(b,at+0.002,0.01,1200.0*mouth,1.5,0.3,rng)
				at+=rng.randf_range(0.16,0.22)*(2.0-mouth)
		"mutter":
			var words:=["ma","ta","ko","ne","ri","sa","lu","de"]
			var text:=""
			for k in rng.randi_range(3,6):text+=String(words[rng.randi_range(0,words.size()-1)])+String(words[rng.randi_range(0,words.size()-1)])+(" " if k<5 else ".")
			b=Voice.render_samples(v,text,rng.randf_range(0.9,1.5),"neutral",true)
		_:
			b=Synth.buffer(0.05)
	Synth.fade_edges(b,0.002,0.02)
	var top:=Synth.peak_of(b)
	if top>0.0001:Synth.scale(b,0.6/top)
	return b
