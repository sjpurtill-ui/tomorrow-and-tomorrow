extends RefCounted
## THE COURT'S FOLEY: every sound in the hall that is not a word.
##
## The room's breath (a gasp, the whole room's gasp, a laugh it cannot
## hold), its bodies (a snore, a stomach in a silent room, a cough fought
## down, a swallow, knees that knock, a faint), its things (a bowl that
## clatters and rolls round and round on its rim, a bundle set down with a
## grunt, a creaking board, footsteps on earth and on wood, cloth), its
## animals (the dog's whimper, sniff and bark, the goat, the hens), the fire
## and the weather (pops, a hiss of sap, a log settling, wind, birds), and the
## god's presence (a low swell under the hush, heavier for wrath, warmer for
## favour).
##
## Each sound is made from a small physical idea, so it reads as the real
## thing at a glance of the ear: a creak is wood sticking and slipping
## through the board's own ring; a dropped bowl rings with a bowl's partials,
## bounces closer and closer and then rolls on its rim faster and faster,
## the way a coin does; a growl is a gurgle wandering in pitch under the belly
## wall. Voices of the body (gasp, laugh, cough, grunt) use the voice in
## court_voice.gd. Every sound has a few variants, so nothing repeats exactly.
##
## make(name, variant) -> samples (court_synth.gd); stream(name, variant) ->
## AudioStreamWAV. CUES lists every name with its variants, its level and its
## kind. Pure and deterministic; safe on a worker thread.

const Synth:=preload("res://scripts/hud/court_synth.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const RATE:=22050

## Every one-shot: variants (how many takes), db (its level in the mix,
## before the Court bus), kind (body, voice, thing, animal, fire, weather,
## god: what the hush silences and what it lets through).
const CUES:={
	"gasp":{"variants":4,"db":-9.0,"kind":"voice"},
	"room_gasp":{"variants":2,"db":-7.0,"kind":"voice"},
	"snort_laugh":{"variants":3,"db":-11.0,"kind":"voice"},
	"laugh":{"variants":2,"db":-10.0,"kind":"voice"},
	"snore":{"variants":3,"db":-10.0,"kind":"body"},
	"stomach_growl":{"variants":3,"db":-6.0,"kind":"body"},
	"cough":{"variants":3,"db":-10.0,"kind":"voice"},
	"cough_fought":{"variants":3,"db":-11.0,"kind":"voice"},
	"swallow":{"variants":3,"db":-8.0,"kind":"body"},
	"creak":{"variants":3,"db":-9.0,"kind":"thing"},
	"bowl_drop":{"variants":2,"db":-7.0,"kind":"thing"},
	"bundle_thud":{"variants":2,"db":-8.0,"kind":"thing"},
	"strain":{"variants":2,"db":-12.0,"kind":"voice"},
	"heave":{"variants":2,"db":-11.0,"kind":"voice"},
	"step_earth":{"variants":4,"db":-16.0,"kind":"thing"},
	"step_wood":{"variants":4,"db":-15.0,"kind":"thing"},
	"dog_whimper":{"variants":2,"db":-12.0,"kind":"animal"},
	"dog_sniff":{"variants":3,"db":-13.0,"kind":"animal"},
	"dog_bark":{"variants":3,"db":-9.0,"kind":"animal"},
	"goat_bleat":{"variants":3,"db":-9.0,"kind":"animal"},
	"goat_chew":{"variants":1,"db":-18.0,"kind":"animal"},
	"hens":{"variants":3,"db":-15.0,"kind":"animal"},
	"knees_knock":{"variants":2,"db":-15.0,"kind":"body"},
	"faint_thump":{"variants":2,"db":-8.0,"kind":"thing"},
	"rustle":{"variants":4,"db":-19.0,"kind":"thing"},
	"ahem":{"variants":3,"db":-11.0,"kind":"voice"},
	"hmph":{"variants":2,"db":-12.0,"kind":"voice"},
	"yawn":{"variants":2,"db":-12.0,"kind":"voice"},
	"sigh":{"variants":3,"db":-13.0,"kind":"voice"},
	"shush":{"variants":2,"db":-14.0,"kind":"voice"},
	"hum_yes":{"variants":3,"db":-13.0,"kind":"voice"},
	"oof":{"variants":2,"db":-12.0,"kind":"voice"},
	"whimper_child":{"variants":2,"db":-14.0,"kind":"voice"},
	"spear_sharpen":{"variants":2,"db":-17.0,"kind":"thing"},
	"scribble":{"variants":2,"db":-19.0,"kind":"thing"},
	"fly_buzz":{"variants":2,"db":-20.0,"kind":"animal"},
	"slap":{"variants":2,"db":-12.0,"kind":"thing"},
	"stamp":{"variants":2,"db":-13.0,"kind":"thing"},
	"rub_hands":{"variants":2,"db":-20.0,"kind":"thing"},
	"breath_out":{"variants":2,"db":-17.0,"kind":"voice"},
	"bump":{"variants":2,"db":-11.0,"kind":"thing"},
	"fire_pop":{"variants":6,"db":-14.0,"kind":"fire"},
	"fire_hiss":{"variants":3,"db":-21.0,"kind":"fire"},
	"log_settle":{"variants":2,"db":-15.0,"kind":"fire"},
	"bird":{"variants":6,"db":-24.0,"kind":"weather"},
	"crow":{"variants":2,"db":-26.0,"kind":"weather"},
	"god_wrath_boom":{"variants":2,"db":-6.0,"kind":"god"},
	"snort_wake":{"variants":2,"db":-9.0,"kind":"body"},
	"dog_scratch":{"variants":2,"db":-15.0,"kind":"animal"},
	"dog_yawn":{"variants":2,"db":-13.0,"kind":"animal"},
	"dog_shake":{"variants":1,"db":-14.0,"kind":"animal"},
	"dog_thump":{"variants":2,"db":-16.0,"kind":"animal"},
	"dog_query":{"variants":2,"db":-14.0,"kind":"animal"},
	"paws":{"variants":3,"db":-24.0,"kind":"animal"},
	"grunt":{"variants":3,"db":-12.0,"kind":"voice"},
	"dog_flop":{"variants":2,"db":-15.0,"kind":"animal"},
	"whoosh":{"variants":3,"db":-16.0,"kind":"thing"},
	"kneel_cloth":{"variants":3,"db":-14.0,"kind":"thing"},
	"sniff":{"variants":2,"db":-14.0,"kind":"voice"},
	"soft_clap":{"variants":2,"db":-13.0,"kind":"thing"},
	"yelp_small":{"variants":3,"db":-12.0,"kind":"voice"},
	"snatch":{"variants":2,"db":-14.0,"kind":"thing"},
	"shoo":{"variants":2,"db":-13.0,"kind":"voice"},
	"scuff":{"variants":4,"db":-19.0,"kind":"thing"},
}

## Beds that loop under the room: seconds long, seamless.
const BEDS:={
	"fire":{"seconds":7.0,"db":-20.0},
	"wind_soft":{"seconds":11.0,"db":-28.0},
	"wind_hard":{"seconds":11.0,"db":-19.0},
	"wind_indoor":{"seconds":11.0,"db":-29.0},
	"murmur_small":{"seconds":9.0,"db":-18.0},
	"murmur":{"seconds":9.0,"db":-15.0},
	"murmur_hall":{"seconds":9.0,"db":-13.0},
	"room":{"seconds":6.0,"db":-38.0},
}

static func has(name:String)->bool:
	return CUES.has(name) or BEDS.has(name) or name.begins_with("god_swell")

static func variants(name:String)->int:
	return int((CUES.get(name,{}) as Dictionary).get("variants",1))

static func level(name:String)->float:
	name=name.get_slice("@",0)
	if CUES.has(name):return float(CUES[name].db)
	if BEDS.has(name):return float(BEDS[name].db)
	return -12.0

static func kind(name:String)->String:
	return String((CUES.get(name,{}) as Dictionary).get("kind","thing"))

static func rng_for(name:String,variant:int)->RandomNumberGenerator:
	var r:=RandomNumberGenerator.new();r.seed=Synth.seed_of("court_foley|%s|%d" % [name,variant])
	return r

## The sound as a stream (a bed loops).
static func stream(name:String,variant:=0)->AudioStreamWAV:
	var samples:=make(name,variant)
	if name.begins_with("god_swell"):
		# the swell rises once, then its middle holds for as long as the god speaks
		return Synth.to_stream(samples,0.0,true,Synth.n_of(SWELL_HOLD))
	return Synth.to_stream(samples,0.0,BEDS.has(name))

## Where the god's swell has risen and starts to hold (seconds).
const SWELL_HOLD:=2.6

## The sound's samples, at its natural level (about -3 dBFS at its loudest).
static func make(name:String,variant:=0)->PackedFloat32Array:
	var v:=posmod(variant,maxi(1,variants(name)))
	var rng:=rng_for(name,v)
	var b:PackedFloat32Array
	match name:
		"gasp":b=gasp(v,rng)
		"room_gasp":b=room_gasp(v,rng)
		"snort_laugh":b=snort_laugh(v,rng)
		"laugh":b=laugh(v,rng)
		"snore":b=snore(v,rng)
		"stomach_growl":b=stomach_growl(v,rng)
		"cough":b=cough(v,rng,false)
		"cough_fought":b=cough(v,rng,true)
		"swallow":b=swallow(v,rng)
		"creak":b=creak(v,rng)
		"bowl_drop":b=bowl_drop(v,rng)
		"bundle_thud":b=bundle_thud(v,rng)
		"strain":b=strain(v,rng)
		"heave":b=heave(v,rng)
		"step_earth":b=step(v,rng,false)
		"step_wood":b=step(v,rng,true)
		"dog_whimper":b=dog_whimper(v,rng)
		"dog_sniff":b=dog_sniff(v,rng)
		"dog_bark":b=dog_bark(v,rng)
		"goat_bleat":b=goat_bleat(v,rng)
		"goat_chew":b=goat_chew(v,rng)
		"hens":b=hens(v,rng)
		"knees_knock":b=knees_knock(v,rng)
		"faint_thump":b=faint_thump(v,rng)
		"rustle":b=rustle(v,rng,0.6)
		"ahem":b=ahem(v,rng)
		"hmph":b=hmph(v,rng)
		"yawn":b=yawn(v,rng)
		"sigh":b=sigh(v,rng)
		"shush":b=shush(v,rng)
		"hum_yes":b=hum_yes(v,rng)
		"oof":b=oof(v,rng)
		"whimper_child":b=whimper_child(v,rng)
		"spear_sharpen":b=spear_sharpen(v,rng)
		"scribble":b=scribble(v,rng)
		"fly_buzz":b=fly_buzz(v,rng)
		"slap":b=slap(v,rng)
		"stamp":b=stamp(v,rng)
		"rub_hands":b=rub_hands(v,rng)
		"breath_out":b=breath_out(v,rng)
		"bump":b=bump(v,rng)
		"fire_pop":b=fire_pop(v,rng)
		"fire_hiss":b=fire_hiss(v,rng)
		"log_settle":b=log_settle(v,rng)
		"bird":b=bird(v,rng)
		"crow":b=crow(v,rng)
		"god_wrath_boom":b=god_boom(v,rng)
		"grunt":b=grunt(v,rng)
		"snort_wake":b=snort_wake(v,rng)
		"dog_scratch":b=dog_scratch(v,rng)
		"dog_yawn":b=dog_yawn(v,rng)
		"dog_shake":b=dog_shake(v,rng)
		"dog_thump":b=dog_thump(v,rng)
		"dog_query":b=dog_query(v,rng)
		"paws":b=paws(v,rng)
		"dog_flop":b=dog_flop(v,rng)
		"whoosh":b=whoosh(v,rng)
		"kneel_cloth":b=kneel_cloth(v,rng)
		"sniff":b=sniff(v,rng)
		"soft_clap":b=soft_clap(v,rng)
		"yelp_small":b=yelp_small(v,rng)
		"snatch":b=snatch(v,rng)
		"shoo":b=shoo(v,rng)
		"scuff":b=scuff(v,rng)
		"god_swell_wrath":b=god_swell(true,rng)
		"god_swell_favour":b=god_swell(false,rng)
		"god_swell":b=god_swell(false,rng)
		_:
			if BEDS.has(name):b=bed(name,rng)
			else:b=Synth.buffer(0.05)
	if not BEDS.has(name) and not name.begins_with("god_swell"):Synth.fade_edges(b,0.002,0.02)
	var top:=Synth.peak_of(b)
	if top>0.0001:Synth.scale(b,0.7/top)
	return b

## A voice of the room for a variant: 0 a man, 1 a woman, 2 a child, 3 old.
static func _room_voice(v:int,salt:int)->Dictionary:
	var reg:String=["man","woman","boy","old_man","girl","old_woman"][posmod(v,6)]
	return Voice.plain(reg,salt+v*7)

# =============================================================================
# The room's breath
# =============================================================================

## One sharp intake: breath through an open mouth with a catch of voice.
static func gasp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,11)
	voice["breath"]=0.3
	var squeak:=0.12 if v!=0 else 0.06
	var steps:=[[0.012,"a",0.0,0.0,1.0],[0.045,"a",0.0,1.0,1.0],[0.06,"e",squeak,0.85,1.25],[0.11,"e",squeak*0.6,0.6,1.3],[0.09,"y",0.0,0.18,1.2],[0.06,"y",0.0,0.0,1.1]]
	var b:=Voice.gesture(voice,steps,rng.randi())
	Synth.highpass(b,300.0)
	return b

## The whole room at once: a few men, women, a child and the old, a hair
## apart, sharp, then nothing.
static func room_gasp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.75)
	for i in 8:
		var one:=gasp((i+v)%4,rng)
		Synth.mix_into(b,one,Synth.n_of(rng.randf_range(0.0,0.09)+(0.03 if i>5 else 0.0)),rng.randf_range(0.45,1.0))
	Synth.lowpass(b,6000.0)
	return b

## A laugh held behind closed lips: a snort through the nose (the nostrils
## flutter), then the shoulders shake "hm-hm-hm" at four or five a second,
## each pulse a burst of breath through the nose with a little voice in it,
## falling; a last small snort out.
static func snort_laugh(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,23)
	voice["breath"]=0.2;voice["rd"]=1.6
	var pulses:=3+v%2
	var rate:=4.6+0.3*float(v)
	var b:=Synth.buffer(0.2+float(pulses)/rate+0.35)
	# the snort: nasal turbulence, the nostrils fluttering at ~30 Hz
	_nose(b,0.0,0.13,1.0,32.0,rng)
	var t:=0.16
	var pitch:=1.25
	for k in pulses:
		var hm:=Voice.gesture(voice,[[0.01,"u",0.0,0.0,pitch,1.0],[0.075,"u",0.55-0.08*k,0.25,pitch*0.94,1.0],[0.03,"u",0.0,0.0,pitch*0.9,1.0]],rng.randi())
		Synth.mix_into(b,hm,Synth.n_of(t),0.75-0.1*k)
		_nose(b,t,0.11,0.55-0.08*k,0.0,rng)
		t+=1.0/rate*rng.randf_range(0.93,1.07)
		pitch*=0.93
	_nose(b,t+0.04,0.1,0.45,26.0,rng)
	return b

## Breath through the nose: noise in the nose's band, a quick onset and an
## easing off; flutter (Hz) shakes it like the nostrils do.
static func _nose(b:PackedFloat32Array,at:float,d:float,amp:float,flutter:float,rng:RandomNumberGenerator)->void:
	var s:=Synth.white(d,rng)
	var low:=s.duplicate()
	Synth.bandpass(s,2200.0,1.3);Synth.bandpass(low,700.0,2.5)
	for i in s.size():
		var tt:=float(i)/RATE
		var env:=minf(1.0,tt/0.008)*exp(-tt/(d*0.45))
		var fl:=1.0 if flutter<=0.0 else 0.55+0.45*sin(TAU*flutter*tt)
		s[i]=(s[i]+low[i]*0.6)*env*fl
	Synth.mix_into(b,s,Synth.n_of(at),amp)


## "Ha-ha-ha-ha": aspirated pulses at about four and a half a second, each an
## "h" of breath into a voiced "a" whose pitch falls, the whole run falling
## and fading; then the breath back in.
static func laugh(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,31)
	voice["breath"]=0.25;voice["rd"]=1.5
	var steps:Array=[[0.01,"a",0.0,0.0,1.5]]
	var p:=1.55
	var rate:=4.5+0.4*float(v)
	for i in 5:
		var whole:=1.0/rate*rng.randf_range(0.94,1.06)
		var key:="a" if i%3!=2 else "ae"
		steps.append([0.04,key,0.0,0.85,p])
		steps.append([whole*0.5,key,1.0-0.1*i,0.35,p*0.9])
		steps.append([whole*0.5-0.04,key,0.0,0.12,p*0.88])
		p*=0.92
	# the breath back in, a little rough
	steps.append([0.26,"e",0.08,0.55,1.3])
	steps.append([0.05,"y",0.0,0.0,1.0])
	return Voice.gesture(voice,steps,rng.randi())

# =============================================================================
# Bodies
# =============================================================================

## A snore: the soft palate flapping on the way in, a breath and a lip
## flutter on the way out ("khhrrr... pbbh").
static func snore(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=Voice.plain("old_man",41+v)
	voice["f0"]=34.0+rng.randf_range(-4.0,6.0);voice["jitter"]=0.12;voice["shimmer"]=0.3;voice["fry"]=0.2;voice["breath"]=0.6;voice["oq"]=0.5
	voice["tilt"]=1400.0
	var steps:=[[0.15,"o",0.1,0.15,1.0,0.7],[0.5,"o",0.75,0.45,1.15,0.8],[0.45,"o",0.6,0.3,0.9,0.8],[0.12,"o",0.0,0.05,0.9,0.8],
		[0.3,"y",0.0,0.0,1.0],[0.07,"u",0.0,0.6,1.0],[0.35,"u",0.0,0.45,1.0],[0.1,"u",0.0,0.0,1.0]]
	var b:=Voice.gesture(voice,steps,rng.randi())
	# the lips flutter on the way out
	var out_at:=Synth.n_of(1.52)
	for i in range(out_at,b.size()):
		var t:=float(i-out_at)/RATE
		b[i]*=0.6+0.4*sin(TAU*(17.0+v*3.0)*t)
	# one in three whistles faintly through the nose
	if v==2:
		var w:=Synth.tone(Synth.track(0.5,[[0.0,1700.0],[0.25,2100.0],[0.5,1800.0]]))
		Synth.shape(w,[[0.0,0.0],[0.1,0.05],[0.4,0.05],[0.5,0.0]])
		Synth.mix_into(b,w,out_at,1.0)
	Synth.lowpass(b,2400.0)
	return b

## A stomach in a silent room, built the way borborygmi are: gas and liquid
## pushed along the gut make a low pitched growl that wanders (90-300 Hz),
## shaken by the liquid at 8-20 Hz, and bursts of gurgles (short damped
## bubbles, 120-550 Hz, gliding) in irregular clusters; it swells and dies.
static func stomach_growl(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var seconds:=1.5+0.35*v
	var b:=Synth.buffer(seconds+0.2)
	# the growl: a wandering low pitch through the belly wall
	var pitch:=Synth.wander(seconds,0.18,rng,95.0,170.0+40.0*v)
	var wob:=Synth.wander(seconds,0.05,rng,0.85,1.18)
	for i in pitch.size():pitch[i]*=wob[i]
	var growl:=Synth.tone(pitch,[1.0,0.8,0.55,0.35,0.2])
	# the liquid shakes it: an irregular tremble at 8-20 Hz
	var shake:=Synth.wander(seconds,0.028,rng,0.0,1.0)
	for i in growl.size():growl[i]*=0.08+0.92*shake[i]*shake[i]
	Synth.bandpass(growl,220.0,1.2)
	Synth.shape(growl,[[0.0,0.0],[seconds*0.2,0.8],[seconds*0.5,1.0],[seconds*0.75,0.55],[seconds,0.0]])
	Synth.mix_into(b,growl,0,1.0)
	# the gurgles: damped bubbles in clusters, denser in the middle
	var t:=rng.randf_range(0.05,0.2)
	while t<seconds:
		var x:=t/seconds
		var density:=sin(PI*x)
		var f:=rng.randf_range(120.0,330.0) if rng.randf()<0.7 else rng.randf_range(330.0,550.0)
		var glide:=rng.randf_range(-0.35,0.45)
		var d:=rng.randf_range(0.02,0.07)
		var bub:=Synth.tone(Synth.track(d,[[0.0,f],[d,f*(1.0+glide)]]),[1.0,0.3])
		Synth.shape(bub,[[0.0,0.0],[0.003,1.0],[d,0.0]])
		Synth.mix_into(b,bub,Synth.n_of(t),rng.randf_range(0.4,0.9)*(0.4+0.6*density))
		# clusters: a quick run, then a wait
		t+=rng.randf_range(0.025,0.07) if rng.randf()<0.65 else rng.randf_range(0.12,0.35)/(0.4+density)
	# the end: one rising squeak of gas
	if v!=1:
		var at:=seconds*0.86
		var sq:=Synth.tone(Synth.track(0.16,[[0.0,260.0],[0.16,480.0+60.0*v]]),[1.0,0.4])
		Synth.shape(sq,[[0.0,0.0],[0.02,1.0],[0.12,0.6],[0.16,0.0]])
		Synth.mix_into(b,sq,Synth.n_of(at),0.35)
	Synth.lowpass2(b,700.0)
	Synth.highpass(b,60.0)
	return b


## A cough; fought: behind closed lips, "hmpf... hmpf", then a careful "hm".
static func cough(v:int,rng:RandomNumberGenerator,fought:bool)->PackedFloat32Array:
	var voice:=_room_voice(v,53)
	voice["breath"]=0.4;voice["jitter"]=0.03;voice["oq"]=0.48
	var steps:Array
	if fought:
		var nose:=1.0
		steps=[[0.01,"u",0.0,0.0,1.0,nose],[0.07,"u",0.3,1.0,1.05,nose],[0.09,"u",0.0,0.05,1.0,nose],[0.06,"u",0.25,0.8,1.1,nose],
			[0.25,"u",0.0,0.0,1.0,nose],[0.04,"u",0.2,0.6,1.0,nose],[0.18,"u",0.0,0.0,1.0,nose],[0.12,"y",0.5,0.1,0.95,0.6],[0.05,"y",0.0,0.0,0.9]]
	else:
		steps=[[0.01,"y",0.0,0.0,1.0],[0.03,"a",0.6,1.0,1.3],[0.12,"a",0.25,0.9,1.0],[0.08,"y",0.0,0.2,0.9],[0.12,"y",0.0,0.0,1.0],
			[0.025,"a",0.5,0.9,1.2],[0.09,"a",0.2,0.7,0.95],[0.06,"y",0.0,0.0,0.9]]
	var b:=Voice.gesture(voice,steps,rng.randi())
	if fought:
		Synth.lowpass(b,900.0)
		# the cheeks puff
		var thump:=Synth.white(0.04,rng)
		Synth.lowpass2(thump,220.0)
		Synth.shape(thump,[[0.0,0.0],[0.006,1.0],[0.04,0.0]])
		Synth.mix_into(b,thump,Synth.n_of(0.02),3.0)
	return b

## A swallow you can hear across the room: a wet click, the gulp, a smaller click.
static func swallow(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.42)
	Synth.burst(b,0.02,0.008,2600.0+v*200.0,3.0,0.5,rng)
	var gulp:=Synth.tone(Synth.track(0.11,[[0.0,190.0],[0.11,70.0]]),[1.0,0.3])
	Synth.shape(gulp,[[0.0,0.0],[0.012,1.0],[0.11,0.0]])
	Synth.mix_into(b,gulp,Synth.n_of(0.09),0.9)
	Synth.modal(b,0.09,[Vector3(320.0+v*30.0,0.25,0.03)],rng)
	Synth.burst(b,0.24,0.006,2000.0,3.0,0.25,rng)
	Synth.lowpass(b,4000.0)
	return b

## Knees that knock: a tiny bony clack, left and right, a little uneven.
static func knees_knock(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.4)
	var t:=0.02
	var side:=0
	while t<1.3:
		var amp:=rng.randf_range(0.5,1.0)*(1.0 if side==0 else 0.8)
		var f:=(1500.0 if side==0 else 1750.0)+rng.randf_range(-80,80)
		Synth.burst(b,t,0.005,f,4.0,amp,rng)
		Synth.modal(b,t,[Vector3(f*0.62,0.25*amp,0.012)],rng)
		t+=rng.randf_range(0.085,0.13)*(1.0+v*0.15)
		side=1-side
	Synth.shape(b,[[0.0,1.0],[1.0,1.0],[1.4,0.3]])
	return b

## A body going down in a faint: the cloth, a soft heavy thump, a breath out.
static func faint_thump(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	var cloth:=rustle(v,rng,0.25)
	Synth.mix_into(b,cloth,0,0.2)
	var thud:=Synth.tone(Synth.track(0.4,[[0.0,62.0],[0.4,38.0]]),[1.0,0.4])
	Synth.shape(thud,[[0.0,0.0],[0.006,1.0],[0.06,0.5],[0.4,0.0]])
	Synth.mix_into(b,thud,Synth.n_of(0.2),1.0)
	var dirt:=Synth.white(0.08,rng)
	Synth.lowpass2(dirt,450.0)
	Synth.shape(dirt,[[0.0,1.0],[0.08,0.0]])
	Synth.mix_into(b,dirt,Synth.n_of(0.2),0.6)
	var voice:=_room_voice(v,61)
	var huff:=Voice.gesture(voice,[[0.02,"y",0.0,0.0,1.0],[0.12,"y",0.0,0.5,1.0],[0.05,"y",0.0,0.0,1.0]],rng.randi())
	Synth.mix_into(b,huff,Synth.n_of(0.24),0.35)
	Synth.mix_into(b,rustle(v+1,rng,0.3),Synth.n_of(0.5),0.1)
	return b

## Cloth moving: a soft rustle of a few rubs.
static func rustle(v:int,rng:RandomNumberGenerator,seconds:=0.6)->PackedFloat32Array:
	var b:=Synth.white(seconds,rng)
	var centre:=Synth.wander(seconds,0.08,rng,1300.0,3600.0)
	Synth.bandpass_track(b,_frames(centre),0.9)
	var env:=Synth.wander(seconds,0.05+0.02*v,rng,0.0,1.0)
	for i in b.size():b[i]*=pow(env[i],2.0)
	Synth.shape(b,[[0.0,0.0],[seconds*0.15,1.0],[seconds*0.8,0.8],[seconds,0.0]])
	return b

## One value a 32-sample frame from a value a sample.
static func _frames(track:PackedFloat32Array)->PackedFloat32Array:
	var out:=PackedFloat32Array();out.resize(track.size()/32+1)
	for i in out.size():out[i]=track[mini(i*32,track.size()-1)]
	return out

# =============================================================================
# Things
# =============================================================================

## Wood that sticks and slips under a weight: each slip a short knock rung
## through the board's own modes. The slips come at 40-300 a second, so the
## train itself is the creak's pitch: slow and low as the weight comes on,
## quicker and higher as it slides, uneven (a slip skipped, a slip doubled).
## Variants: 0 a floor board, 1 a log or a bench (low groan), 2 a post (higher).
static func creak(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var seconds:float=[0.8,1.05,0.7][v]
	var b:=Synth.buffer(seconds+0.15)
	var slow_hz:float=[45.0,32.0,90.0][v]
	var fast_hz:float=[150.0,95.0,260.0][v]
	var modes:Array=[[[150.0,22.0,1.0],[340.0,26.0,0.8],[610.0,30.0,0.55],[980.0,40.0,0.3],[1600.0,60.0,0.12]],
		[[95.0,16.0,1.0],[230.0,20.0,0.85],[470.0,26.0,0.5],[820.0,34.0,0.25],[1350.0,50.0,0.1]],
		[[260.0,24.0,1.0],[560.0,28.0,0.7],[1020.0,36.0,0.45],[1650.0,50.0,0.25],[2500.0,70.0,0.1]]][v]
	# the train of slips
	var imp:=Synth.buffer(seconds+0.15)
	var t:=0.01
	var knock:=Synth.n_of(0.0009)
	while t<seconds:
		var x:=t/seconds
		var hz:=lerpf(slow_hz,fast_hz,sin(PI*minf(1.0,x*1.2)))
		var period:=1.0/hz*(1.0+rng.randf_range(-0.12,0.12))
		var amp:=sin(PI*minf(1.0,x*1.1))*rng.randf_range(0.55,1.0)
		if rng.randf()<0.06:amp*=0.15
		var i0:=Synth.n_of(t)
		# a slip is a short raised-cosine knock, not a single sample
		for k in knock:
			if i0+k<imp.size():imp[i0+k]+=amp*0.5*(1.0-cos(TAU*float(k)/float(knock)))
		t+=period*(2.0 if rng.randf()<0.04 else 1.0)
	for m in modes:
		var ring:=imp.duplicate()
		Synth.resonate(ring,float(m[0]),float(m[1]))
		Synth.mix_into(b,ring,0,float(m[2]))
	# a breath of friction noise riding the slips
	var fr:=Synth.white(seconds+0.15,rng)
	Synth.bandpass(fr,1800.0,1.2)
	for i in fr.size():fr[i]*=absf(imp[i])*4.0
	Synth.lowpass(fr,3000.0)
	Synth.mix_into(b,fr,0,0.06)
	Synth.highpass(b,50.0)
	return b


## A wooden bowl hits the earth floor, bounces, then rolls on its rim faster
## and faster until it settles (variant 1: a clay bowl, brighter).
static func bowl_drop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.2)
	var modes:Array=[Vector3(620,1.0,0.05),Vector3(1480,0.6,0.035),Vector3(2700,0.35,0.02),Vector3(3900,0.15,0.012)]
	if v==1:modes=[Vector3(1150,1.0,0.06),Vector3(2600,0.6,0.04),Vector3(4100,0.4,0.025),Vector3(5600,0.2,0.015)]
	var hits:=[[0.02,1.0],[0.19,0.55],[0.31,0.32],[0.385,0.2]]
	for h in hits:
		var at:=float(h[0]);var amp:=float(h[1])
		Synth.modal(b,at,modes,rng,amp*0.5)
		Synth.burst(b,at,0.012,900.0,0.8,amp*0.5,rng)
		var thud:=Synth.tone(Synth.track(0.08,[[0.0,110.0],[0.08,70.0]]))
		Synth.shape(thud,[[0.0,0.0],[0.004,1.0],[0.08,0.0]])
		Synth.mix_into(b,thud,Synth.n_of(at),amp*0.6)
	# the roll on its rim: taps closer and closer, softer and softer
	var t:=0.47;var gap:=0.075;var amp2:=0.18
	while gap>0.009 and t<2.0:
		Synth.modal(b,t,[Vector3(float(modes[0].x)*rng.randf_range(0.98,1.02),0.5,0.02),Vector3(float(modes[1].x),0.3,0.012)],rng,amp2)
		Synth.burst(b,t,0.004,2200.0,1.0,amp2*0.6,rng)
		t+=gap;gap*=0.93;amp2*=0.975
	# and a last little rattle as it settles flat
	for k in 6:
		Synth.burst(b,t+k*0.008,0.003,2500.0,1.5,0.05,rng)
	return b

## A heavy bundle set down: a grunt, the thump, its cloth settling.
static func bundle_thud(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	var voice:=_room_voice(0 if v==0 else 3,71)
	voice["oq"]=0.45;voice["breath"]=0.25
	var grunt:=Voice.gesture(voice,[[0.02,"y",0.0,0.0,1.0],[0.05,"y",0.9,0.3,1.12],[0.13,"y",0.7,0.3,0.85],[0.08,"y",0.0,0.4,0.8],[0.04,"y",0.0,0.0,0.8]],rng.randi())
	Synth.mix_into(b,grunt,0,0.6)
	var thud:=Synth.tone(Synth.track(0.35,[[0.0,85.0],[0.35,48.0]]),[1.0,0.5,0.2])
	Synth.shape(thud,[[0.0,0.0],[0.005,1.0],[0.05,0.6],[0.35,0.0]])
	Synth.mix_into(b,thud,Synth.n_of(0.17),1.0)
	var dirt:=Synth.white(0.1,rng)
	Synth.lowpass2(dirt,500.0)
	Synth.shape(dirt,[[0.0,1.0],[0.1,0.0]])
	Synth.mix_into(b,dirt,Synth.n_of(0.17),1.2)
	Synth.mix_into(b,rustle(v,rng,0.4),Synth.n_of(0.2),0.12)
	return b

## Straining under a load: "nnnngh", shaking.
static func strain(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(0 if v==0 else 1,79)
	voice["oq"]=0.42;voice["tremor"]=0.05;voice["tremor_hz"]=9.0;voice["breath"]=0.2
	return Voice.gesture(voice,[[0.03,"y",0.0,0.0,1.0],[0.5,"y",0.7,0.2,1.18,0.8],[0.15,"y",0.5,0.3,1.25,0.6],[0.2,"a",0.0,0.6,1.0],[0.05,"y",0.0,0.0,1.0]],rng.randi())

## A heave: "hup!"
static func heave(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(0 if v==0 else 1,83)
	voice["oq"]=0.45
	return Voice.gesture(voice,[[0.02,"u",0.0,0.0,1.0],[0.04,"u",0.0,0.8,1.0],[0.1,"u",0.9,0.2,1.25],[0.03,"u",0.0,0.0,1.1]],rng.randi())

## A footstep: on earth a soft thump with grit; on wood the plank answers.
static func step(v:int,rng:RandomNumberGenerator,wood:bool)->PackedFloat32Array:
	var b:=Synth.buffer(0.3)
	var heel:=Synth.white(0.07,rng)
	Synth.lowpass2(heel,240.0 if not wood else 420.0)
	Synth.shape(heel,[[0.0,0.0],[0.004,1.0],[0.07,0.0]])
	Synth.mix_into(b,heel,Synth.n_of(0.005),1.0)
	if wood:
		Synth.modal(b,0.005,[Vector3(170.0+v*12.0,0.5,0.07),Vector3(410.0+v*20.0,0.3,0.045),Vector3(950.0,0.12,0.02)],rng)
	else:
		# grit under the sole
		var t:=0.02
		while t<0.09:
			Synth.burst(b,t,0.002,rng.randf_range(2500.0,4500.0),2.0,rng.randf_range(0.015,0.045),rng)
			t+=rng.randf_range(0.004,0.015)
	# the toe comes down a breath later
	var toe:=Synth.white(0.04,rng)
	Synth.lowpass2(toe,320.0)
	Synth.shape(toe,[[0.0,0.0],[0.003,1.0],[0.04,0.0]])
	Synth.mix_into(b,toe,Synth.n_of(0.07+0.01*v),0.5)
	return b

# =============================================================================
# The animals
# =============================================================================

## The dog's whimper: a thin nasal whine, two breaths of it.
static func dog_whimper(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.1)
	for k in 2:
		var d:=0.35 if k==0 else 0.5
		var p:=Synth.track(d,[[0.0,720.0+v*40.0],[d*0.4,1050.0+rng.randf_range(-40,60)],[d,800.0]])
		for i in p.size():p[i]*=1.0+0.035*sin(TAU*6.5*float(i)/RATE)
		var w:=Synth.tone(p,[1.0,0.35,0.12])
		var air:=Synth.white(d,rng,0.05)
		Synth.bandpass(air,1400.0,1.5)
		for i in w.size():w[i]+=air[i]
		Synth.shape(w,[[0.0,0.0],[0.05,1.0],[d*0.7,0.8],[d,0.0]])
		Synth.mix_into(b,w,Synth.n_of(0.02+k*0.48),0.8 if k==0 else 1.0)
	Synth.lowpass(b,3500.0)
	return b

## The dog sniffing: quick little intakes through the nose.
static func dog_sniff(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var count:=4+v
	var b:=Synth.buffer(0.12*count+0.2)
	var t:=0.02
	for k in count:
		var s:=Synth.white(0.04,rng)
		Synth.bandpass(s,rng.randf_range(2600.0,3600.0),1.4)
		Synth.shape(s,[[0.0,0.0],[0.012,1.0],[0.04,0.0]])
		Synth.mix_into(b,s,Synth.n_of(t),rng.randf_range(0.6,1.0))
		t+=rng.randf_range(0.085,0.13)
	return b

## A bark: a rough voiced "wuf" from a mid-sized dog (variant 2: a low
## "boof" through a closed mouth).
static func dog_bark(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=Voice.plain("woman",91+v)
	voice["f0"]=390.0+v*30.0;voice["fs"]=1.05;voice["jitter"]=0.05;voice["shimmer"]=0.15;voice["oq"]=0.45;voice["breath"]=0.3;voice["tilt"]=3000.0
	if v==2:voice["f0"]=230.0
	var steps:=[[0.01,"a",0.0,0.0,1.0],[0.015,"a",0.0,1.0,1.0],[0.08,"a",1.0,0.5,0.82],[0.06,"o",0.6,0.4,0.62],[0.03,"u",0.0,0.1,0.6]]
	if v==2:steps=[[0.01,"u",0.0,0.0,1.0],[0.12,"u",0.9,0.4,0.75,0.8],[0.04,"u",0.0,0.0,0.7]]
	var b:=Voice.gesture(voice,steps,rng.randi())
	return b

## The goat: "mmeh-eh-eh-ehh", the bleat's warble.
static func goat_bleat(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=Voice.plain("woman",101+v)
	voice["f0"]=300.0+v*45.0;voice["fs"]=1.2;voice["jitter"]=0.04;voice["shimmer"]=0.1;voice["tremor"]=0.09;voice["tremor_hz"]=8.5;voice["breath"]=0.3;voice["oq"]=0.5
	var long:=0.55+0.15*v
	var steps:=[[0.01,"e",0.0,0.0,1.0,1.0],[0.06,"e",0.6,0.1,1.0,1.0],[long,"e",1.0,0.25,1.08,0.3],[0.18,"ae",0.8,0.3,0.92],[0.06,"y",0.0,0.1,0.85]]
	return Voice.gesture(voice,steps,rng.randi())

## The goat chewing: slow soft crunches.
static func goat_chew(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.4)
	var t:=0.05
	while t<2.3:
		for k in 3:Synth.burst(b,t+k*0.012,0.006,rng.randf_range(1200.0,2400.0),1.2,rng.randf_range(0.2,0.5),rng)
		t+=rng.randf_range(0.36,0.46)
	Synth.lowpass(b,3000.0)
	return b

## The hens: clucks, now and then a "b-gawk".
static func hens(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.0)
	var voice:=Voice.plain("girl",111+v)
	voice["fs"]=1.7;voice["jitter"]=0.03;voice["oq"]=0.5;voice["breath"]=0.2
	var t:=0.05
	while t<1.8:
		voice["f0"]=rng.randf_range(480.0,620.0)
		var cl:=Voice.gesture(voice,[[0.005,"o",0.0,0.0,1.0],[0.05,"o",1.0,0.2,0.72],[0.02,"u",0.0,0.0,0.7]],rng.randi())
		Synth.mix_into(b,cl,Synth.n_of(t),rng.randf_range(0.5,0.9))
		t+=rng.randf_range(0.14,0.4)
		if rng.randf()<0.18 and t<1.5:
			voice["f0"]=520.0
			var gawk:=Voice.gesture(voice,[[0.04,"o",0.8,0.2,0.8],[0.2,"a",1.0,0.3,1.25],[0.05,"a",0.0,0.0,1.0]],rng.randi())
			Synth.mix_into(b,gawk,Synth.n_of(t),0.8)
			t+=0.4
	return b

# =============================================================================
# Small vocal business
# =============================================================================

static func ahem(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,121)
	voice["fry"]=0.15;voice["oq"]=0.5
	return Voice.gesture(voice,[[0.01,"y",0.0,0.0,1.0],[0.03,"y",0.0,0.6,1.0],[0.11,"y",0.8,0.2,0.92,0.4],[0.07,"y",0.0,0.0,0.9],
		[0.12,"u",0.7,0.1,1.02,1.0],[0.05,"u",0.0,0.0,0.95,1.0]],rng.randi())

## Scorn through the nose.
static func hmph(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v*3,127)
	return Voice.gesture(voice,[[0.01,"u",0.0,0.0,1.0,1.0],[0.06,"u",0.0,1.0,1.0,1.0],[0.14,"u",0.6,0.2,0.85,1.0],[0.04,"u",0.0,0.0,0.8,1.0]],rng.randi())

static func yawn(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v*3,131)
	voice["breath"]=0.5
	return Voice.gesture(voice,[[0.05,"a",0.0,0.3,1.0],[0.4,"a",0.5,0.6,1.35],[0.6,"a",0.45,0.5,0.85],[0.25,"o",0.2,0.3,0.75],[0.1,"u",0.0,0.0,0.7,1.0]],rng.randi())

static func sigh(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,137)
	voice["breath"]=0.5
	return Voice.gesture(voice,[[0.04,"a",0.0,0.2,1.0],[0.3,"a",0.15,0.8,1.0],[0.45,"y",0.08,0.5,0.82],[0.12,"y",0.0,0.0,0.8]],rng.randi())

static func shush(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.5+0.15*v
	var b:=Synth.white(d,rng)
	Synth.bandpass(b,3000.0+v*200.0,1.6)
	Synth.shape(b,[[0.0,0.0],[0.05,1.0],[d*0.7,0.8],[d,0.0]])
	return b

## "Mm. Mm-hm." Agreeing, a little too much.
static func hum_yes(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,149)
	return Voice.gesture(voice,[[0.01,"u",0.0,0.0,1.0,1.0],[0.12,"u",0.7,0.05,1.08,1.0],[0.08,"u",0.0,0.0,1.0,1.0],[0.09,"u",0.6,0.05,1.15,1.0],[0.1,"u",0.6,0.05,0.95,1.0],[0.05,"u",0.0,0.0,0.9,1.0]],rng.randi())

## A breath knocked out: "oof".
static func oof(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,151)
	return Voice.gesture(voice,[[0.01,"u",0.0,0.0,1.0],[0.03,"u",0.0,0.9,1.0],[0.1,"u",0.6,0.4,0.8],[0.04,"u",0.0,0.1,0.75]],rng.randi())

## A frightened child's small whimper.
static func whimper_child(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(2+v*2,157)
	voice["breath"]=0.35;voice["tremor"]=0.04;voice["tremor_hz"]=7.0
	return Voice.gesture(voice,[[0.02,"u",0.0,0.0,1.0],[0.25,"i",0.5,0.4,1.2,0.5],[0.2,"i",0.3,0.3,1.05,0.5],[0.05,"y",0.0,0.0,1.0]],rng.randi())

static func breath_out(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(v,163)
	return Voice.gesture(voice,[[0.04,"a",0.0,0.3,1.0],[0.4,"y",0.0,0.6,1.0],[0.15,"y",0.0,0.0,1.0]],rng.randi())

## An effort: "hnh" (0), a longer strained "nnnh" (1), a woman's (2).
static func grunt(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice(1 if v==2 else 0,181)
	voice["oq"]=0.44;voice["breath"]=0.25
	if v==1:voice["tremor"]=0.04;voice["tremor_hz"]=9.0
	var hold:=0.12 if v!=1 else 0.38
	return Voice.gesture(voice,[[0.015,"y",0.0,0.0,1.0],[0.03,"y",0.0,0.7,1.0],[hold,"y",0.85,0.25,1.1 if v!=1 else 1.2,0.5],[0.08,"y",0.0,0.5,0.85],[0.04,"y",0.0,0.0,0.8]],rng.randi())

## A frightened little yelp: "ip!"
static func yelp_small(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=_room_voice([1,0,2][v],191)
	voice["breath"]=0.3
	return Voice.gesture(voice,[[0.01,"i",0.0,0.0,1.0],[0.02,"i",0.0,0.6,1.3],[0.07,"i",1.0,0.2,1.65],[0.04,"i",0.0,0.1,1.5]],rng.randi())

## A sniff through the nose (a person's: disdain, a cold).
static func sniff(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.35)
	var s:=Synth.white(0.16+0.06*v,rng)
	Synth.bandpass(s,1500.0+v*300.0,1.1)
	Synth.shape(s,[[0.0,0.0],[0.03,1.0],[0.12,0.6],[0.16+0.06*v,0.0]])
	Synth.mix_into(b,s,Synth.n_of(0.01),1.0)
	return b

## Shooing an animal off: "sh! sh!" with a flap of the hand.
static func shoo(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.7)
	for k in 2:
		var d:=0.14
		var s:=Synth.white(d,rng)
		Synth.bandpass(s,2900.0+v*200.0,1.6)
		Synth.shape(s,[[0.0,0.0],[0.015,1.0],[d*0.6,0.7],[d,0.0]])
		Synth.mix_into(b,s,Synth.n_of(0.02+k*0.24),1.0 if k==0 else 0.8)
	Synth.mix_into(b,whoosh(v,rng),Synth.n_of(0.05),0.4)
	return b

# =============================================================================
# Small business of hands and things
# =============================================================================

## Air moved by a hand or a sleeve: a swat that misses, a wave, a quick turn.
static func whoosh(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.18+0.05*v
	var b:=Synth.pink(d,rng,1.0)
	var c:=Synth.track(d,[[0.0,500.0],[d*0.5,1400.0+v*300.0],[d,700.0]])
	Synth.bandpass_track(b,_frames(c),1.2)
	Synth.shape(b,[[0.0,0.0],[d*0.5,1.0],[d,0.0]])
	return b

## Going down on a knee: the cloth, then the knee on the floor.
static func kneel_cloth(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.8)
	Synth.mix_into(b,rustle(v,rng,0.45),0,0.7)
	var knee:=Synth.white(0.06,rng)
	Synth.lowpass(knee,300.0)
	Synth.shape(knee,[[0.0,0.0],[0.004,1.0],[0.06,0.0]])
	Synth.mix_into(b,knee,Synth.n_of(0.32+0.04*v),1.2)
	var bone:=Synth.tone(Synth.track(0.08,[[0.0,140.0],[0.08,95.0]]))
	Synth.shape(bone,[[0.0,0.0],[0.004,1.0],[0.08,0.0]])
	Synth.mix_into(b,bone,Synth.n_of(0.32+0.04*v),0.4)
	return b

## A quiet clap or two: hands that mean well.
static func soft_clap(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	for k in 2+v:
		Synth.burst(b,0.02+k*0.27,0.014,rng.randf_range(1100.0,1500.0),0.9,rng.randf_range(0.7,1.0),rng)
		var cup:=Synth.tone(Synth.track(0.03,[[0.0,420.0],[0.03,380.0]]))
		Synth.shape(cup,[[0.0,0.0],[0.002,1.0],[0.03,0.0]])
		Synth.mix_into(b,cup,Synth.n_of(0.02+k*0.27),0.25)
	return b

## Something snatched up: a quick sleeve and a grab.
static func snatch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.45)
	Synth.mix_into(b,whoosh(v,rng),0,0.8)
	Synth.burst(b,0.16,0.01,900.0+v*300.0,0.8,0.6,rng)
	Synth.mix_into(b,rustle(v+2,rng,0.2),Synth.n_of(0.17),0.4)
	return b

## Feet shuffled over earth.
static func scuff(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.22+0.04*v
	var b:=Synth.white(d,rng)
	Synth.lowpass(b,1400.0)
	var grit:=Synth.wander(d,0.006,rng,0.3,1.0)
	for i in b.size():b[i]*=grit[i]
	Synth.shape(b,[[0.0,0.0],[0.03,1.0],[d*0.7,0.6],[d,0.0]])
	return b

## A stone worked along a spear point: three slow strokes, "shhk".
static func spear_sharpen(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.0)
	for k in 3:
		var d:=0.38+rng.randf_range(-0.04,0.05)
		var s:=Synth.white(d,rng)
		var grit:=Synth.wander(d,0.004,rng,0.2,1.0)
		for i in s.size():s[i]*=grit[i]
		Synth.bandpass(s,3400.0+v*300.0,2.0)
		Synth.shape(s,[[0.0,0.0],[d*0.6,1.0],[d*0.9,0.5],[d,0.0]])
		Synth.mix_into(b,s,Synth.n_of(0.05+k*0.62),1.0)
		Synth.modal(b,0.05+k*0.62+d*0.95,[Vector3(2400.0,0.2,0.02),Vector3(5200.0,0.1,0.01)],rng)
	return b

## A scribe's stylus at work.
static func scribble(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.6)
	var t:=0.03
	while t<1.5:
		var d:=rng.randf_range(0.03,0.09)
		var s:=Synth.white(d,rng)
		Synth.bandpass(s,rng.randf_range(2200.0,3800.0),1.5)
		Synth.shape(s,[[0.0,0.0],[d*0.2,1.0],[d,0.0]])
		Synth.mix_into(b,s,Synth.n_of(t),rng.randf_range(0.4,1.0))
		t+=d+rng.randf_range(0.01,0.12)
	return b

## A fly, going round someone's head.
static func fly_buzz(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.6
	var p:=Synth.wander(d,0.12,rng,185.0,235.0)
	var b:=Synth.tone(p,[1.0,0.6,0.45,0.3,0.2,0.12,0.08])
	var near:=Synth.wander(d,0.25,rng,0.2,1.0)
	for i in b.size():b[i]*=near[i]*(0.85+0.15*sin(TAU*31.0*float(i)/RATE))
	Synth.shape(b,[[0.0,0.0],[0.2,1.0],[d-0.2,1.0],[d,0.0]])
	Synth.bandpass(b,900.0,0.6)
	return b

## A hand slap (a swat that lands).
static func slap(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.25)
	Synth.burst(b,0.005,0.02,1600.0+v*300.0,0.7,1.0,rng)
	var pat:=Synth.tone(Synth.track(0.06,[[0.0,180.0],[0.06,120.0]]))
	Synth.shape(pat,[[0.0,0.0],[0.003,1.0],[0.06,0.0]])
	Synth.mix_into(b,pat,Synth.n_of(0.005),0.4)
	return b

## Feet stamped against the cold.
static func stamp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	for k in 2+v:
		var one:=step(k%4,rng,false)
		Synth.mix_into(b,one,Synth.n_of(0.02+k*0.24),1.0)
	Synth.lowpass(b,1500.0)
	return b

static func rub_hands(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.3)
	for k in 4:
		var d:=0.22
		var s:=Synth.white(d,rng)
		Synth.bandpass(s,1900.0+v*200.0,0.9)
		Synth.shape(s,[[0.0,0.0],[0.08,1.0],[d,0.0]])
		Synth.mix_into(b,s,Synth.n_of(0.03+k*0.29),1.0)
	return b

## A body bumped: an elbow, a nudge, backing into a post.
static func bump(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.35)
	var thud:=Synth.tone(Synth.track(0.15,[[0.0,150.0+v*60.0],[0.15,90.0]]),[1.0,0.5])
	Synth.shape(thud,[[0.0,0.0],[0.004,1.0],[0.15,0.0]])
	Synth.mix_into(b,thud,Synth.n_of(0.005),1.0)
	if v==1:Synth.modal(b,0.005,[Vector3(240,0.5,0.08),Vector3(620,0.25,0.04)],rng)
	Synth.mix_into(b,rustle(v,rng,0.2),0,0.3)
	return b

## The dog scratches: a hind paw drumming its flank at ~8 a second, the
## collar of fur rustling with it.
static func dog_scratch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.2+0.4*v
	var b:=Synth.buffer(d+0.1)
	var t:=0.02
	var rate:=7.5+1.5*v
	while t<d:
		var thump:=Synth.white(0.03,rng)
		Synth.lowpass2(thump,400.0)
		Synth.shape(thump,[[0.0,0.0],[0.003,1.0],[0.03,0.0]])
		Synth.mix_into(b,thump,Synth.n_of(t),rng.randf_range(0.6,1.0))
		var fur:=Synth.white(0.06,rng)
		Synth.bandpass(fur,2600.0,0.9)
		Synth.shape(fur,[[0.0,0.0],[0.01,1.0],[0.06,0.0]])
		Synth.mix_into(b,fur,Synth.n_of(t+0.005),0.25)
		t+=1.0/rate*rng.randf_range(0.9,1.1)
	Synth.shape(b,[[0.0,1.0],[d*0.8,1.0],[d,0.4]])
	return b

## The dog yawns: a long squeaky whine that opens and falls, jaws clapping shut.
static func dog_yawn(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	var d:=0.75+0.15*v
	var p:=Synth.track(d,[[0.0,650.0+60.0*v],[d*0.3,1100.0+80.0*v],[d,520.0]])
	var w:=Synth.tone(p,[1.0,0.5,0.25,0.1])
	var air:=Synth.white(d,rng,0.4)
	Synth.bandpass(air,1300.0,1.0)
	for i in w.size():w[i]=w[i]*0.6+air[i]
	Synth.bandpass(w,1100.0,0.8)
	Synth.shape(w,[[0.0,0.0],[0.08,0.6],[d*0.35,1.0],[d*0.85,0.5],[d,0.0]])
	Synth.mix_into(b,w,Synth.n_of(0.02),1.0)
	Synth.burst(b,d+0.05,0.01,900.0,1.0,0.6,rng)
	return b

## The dog shakes itself: a loose flapping of ears and coat, fast, slowing.
static func dog_shake(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	var t:=0.02;var gap:=0.045
	while t<0.85:
		var flap:=Synth.white(0.035,rng)
		Synth.bandpass(flap,rng.randf_range(700.0,1400.0),0.8)
		Synth.shape(flap,[[0.0,0.0],[0.004,1.0],[0.035,0.0]])
		Synth.mix_into(b,flap,Synth.n_of(t),rng.randf_range(0.5,1.0)*(1.0-t))
		t+=gap;gap*=1.04
	Synth.mix_into(b,rustle(v,rng,0.7),Synth.n_of(0.05),0.4)
	return b

## A wagging tail thumping the earth floor (the dog lying down).
static func dog_thump(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.4)
	var t:=0.02
	for k in 4+v:
		var th:=Synth.white(0.05,rng)
		Synth.lowpass2(th,260.0)
		Synth.shape(th,[[0.0,0.0],[0.004,1.0],[0.05,0.0]])
		Synth.mix_into(b,th,Synth.n_of(t),rng.randf_range(0.7,1.0))
		t+=rng.randf_range(0.2,0.28)
	return b

## The dog's head-tilt question: a tiny rising whine, "hm?"
static func dog_query(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.28+0.06*v
	var p:=Synth.track(d,[[0.0,780.0],[d*0.6,1050.0+80.0*v],[d,1250.0]])
	var w:=Synth.tone(p,[1.0,0.3])
	var air:=Synth.white(d,rng,0.05)
	Synth.bandpass(air,1500.0,1.5)
	for i in w.size():w[i]+=air[i]
	Synth.shape(w,[[0.0,0.0],[0.04,1.0],[d*0.7,0.8],[d,0.0]])
	return w

## Paws on earth: soft pads and a click of claws.
static func paws(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.2)
	var pad:=Synth.white(0.03,rng)
	Synth.lowpass2(pad,350.0)
	Synth.shape(pad,[[0.0,0.0],[0.003,1.0],[0.03,0.0]])
	Synth.mix_into(b,pad,Synth.n_of(0.01),1.0)
	Synth.burst(b,0.012+0.004*v,0.002,3200.0,2.0,0.25,rng)
	return b

## A waking snort: the breath catches in the throat ("hrrnk!"), a flutter of
## the soft palate, then a bewildered little "hm?".
static func snort_wake(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var voice:=Voice.plain("old_man" if v==0 else "man",197+v)
	voice["f0"]=40.0;voice["jitter"]=0.15;voice["shimmer"]=0.35;voice["fry"]=0.3;voice["breath"]=0.6;voice["rd"]=0.6
	var b:=Synth.buffer(0.9)
	var snort:=Voice.gesture(voice,[[0.01,"o",0.0,0.0,1.0,0.8],[0.16,"o",0.9,0.8,1.3,0.8],[0.03,"o",0.0,0.0,1.0,0.8]],rng.randi())
	for i in snort.size():snort[i]*=0.6+0.4*sin(TAU*36.0*float(i)/RATE)
	Synth.mix_into(b,snort,0,1.0)
	var hm:=Voice.plain("old_man" if v==0 else "man",199+v)
	var q:=Voice.gesture(hm,[[0.01,"u",0.0,0.0,1.0,1.0],[0.16,"u",0.6,0.05,1.25,1.0],[0.04,"u",0.0,0.0,1.3,1.0]],rng.randi())
	Synth.mix_into(b,q,Synth.n_of(0.42),0.5)
	return b

## The dog flops down: a soft weight on the earth and a sigh through the nose.
static func dog_flop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	var thud:=Synth.white(0.12,rng)
	Synth.lowpass(thud,250.0)
	Synth.shape(thud,[[0.0,0.0],[0.006,1.0],[0.12,0.0]])
	Synth.mix_into(b,thud,Synth.n_of(0.02),1.0)
	var huff:=Synth.white(0.35,rng)
	Synth.bandpass(huff,900.0+v*200.0,1.0)
	Synth.shape(huff,[[0.0,0.0],[0.05,1.0],[0.35,0.0]])
	Synth.mix_into(b,huff,Synth.n_of(0.3),0.35)
	return b

# =============================================================================
# The fire
# =============================================================================

## A pop of sap or a crack of a log (bigger variants are rarer).
static func fire_pop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.25)
	var big:=v>=4
	Synth.burst(b,0.002,0.003 if not big else 0.006,rng.randf_range(1800.0,3800.0),0.8,1.0,rng)
	if big:
		# a crack with its own quick crackle after
		for k in rng.randi_range(2,5):
			Synth.burst(b,0.01+rng.randf_range(0.0,0.08),0.002,rng.randf_range(2000.0,5000.0),1.0,rng.randf_range(0.2,0.5),rng)
		Synth.modal(b,0.002,[Vector3(rng.randf_range(700,1100),0.15,0.015)],rng)
	return b

## Sap boiling out of a log end: a thin hiss that swells and fades.
static func fire_hiss(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.8+0.4*v
	var b:=Synth.white(d,rng)
	Synth.bandpass(b,rng.randf_range(4200.0,6500.0),3.0)
	var flutter:=Synth.wander(d,0.03,rng,0.5,1.0)
	for i in b.size():b[i]*=flutter[i]
	Synth.shape(b,[[0.0,0.0],[d*0.4,1.0],[d*0.75,0.7],[d,0.0]])
	return b

## A log settling in the fire: a soft knock, the embers' rattle.
static func log_settle(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	var thud:=Synth.tone(Synth.track(0.2,[[0.0,140.0],[0.2,90.0]]),[1.0,0.5])
	Synth.shape(thud,[[0.0,0.0],[0.005,1.0],[0.2,0.0]])
	Synth.mix_into(b,thud,Synth.n_of(0.01),0.7)
	Synth.modal(b,0.01,[Vector3(320+v*60,0.4,0.05),Vector3(780,0.2,0.03)],rng)
	var t:=0.05
	while t<0.7:
		Synth.burst(b,t,0.003,rng.randf_range(2000.0,4500.0),1.2,rng.randf_range(0.1,0.35)*(1.0-t),rng)
		t+=rng.randf_range(0.01,0.05)
	return b

# =============================================================================
# The weather and the birds
# =============================================================================

## A bird far off: whistles, chirps and trills (six kinds).
static func bird(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.4)
	match v:
		0:
			# two-note whistle, "tee-oo"
			for k in 2:
				var d:=0.16
				var p:=Synth.track(d,[[0.0,3300.0 if k==0 else 2700.0],[d,3200.0 if k==0 else 2500.0]])
				var w:=Synth.tone(p,[1.0,0.05]);Synth.shape(w,[[0.0,0.0],[0.02,1.0],[d*0.8,0.8],[d,0.0]])
				Synth.mix_into(b,w,Synth.n_of(0.02+k*0.2),1.0)
		1:
			# a quick chirp run
			for k in 5:
				var d:=0.045
				var p:=Synth.track(d,[[0.0,4200.0],[d,2900.0]])
				var w:=Synth.tone(p);Synth.shape(w,[[0.0,0.0],[0.005,1.0],[d,0.0]])
				Synth.mix_into(b,w,Synth.n_of(0.02+k*0.075),1.0-k*0.08)
		2:
			# a trill
			var d:=0.7
			var p:=Synth.track(d,[[0.0,3800.0],[d,3500.0]])
			for i in p.size():p[i]+=350.0*sin(TAU*24.0*float(i)/RATE)
			var w:=Synth.tone(p);Synth.shape(w,[[0.0,0.0],[0.05,1.0],[d-0.1,0.8],[d,0.0]])
			Synth.mix_into(b,w,Synth.n_of(0.02),0.8)
		3:
			# a rising questioning whistle
			var d:=0.35
			var p:=Synth.track(d,[[0.0,2200.0],[d,3600.0]])
			var w:=Synth.tone(p,[1.0,0.08]);Synth.shape(w,[[0.0,0.0],[0.04,1.0],[d*0.85,0.9],[d,0.0]])
			Synth.mix_into(b,w,Synth.n_of(0.02),1.0)
		4:
			# three falling notes
			for k in 3:
				var d:=0.12
				var f:=3600.0-k*350.0
				var p:=Synth.track(d,[[0.0,f+300.0],[d,f]])
				var w:=Synth.tone(p);Synth.shape(w,[[0.0,0.0],[0.015,1.0],[d,0.0]])
				Synth.mix_into(b,w,Synth.n_of(0.02+k*0.16),1.0)
		_:
			# a warble
			var d:=0.9
			var p:=Synth.wander(d,0.05,rng,2600.0,3900.0)
			var w:=Synth.tone(p);
			var env:=Synth.wander(d,0.06,rng,0.0,1.0)
			for i in w.size():w[i]*=env[i]
			Synth.shape(w,[[0.0,0.0],[0.05,1.0],[d-0.1,1.0],[d,0.0]])
			Synth.mix_into(b,w,Synth.n_of(0.02),0.8)
	Synth.lowpass(b,5000.0)
	return b

## A crow far off: a harsh "kaah".
static func crow(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	var voice:=Voice.plain("woman",171+v)
	voice["f0"]=420.0;voice["fs"]=1.35;voice["jitter"]=0.12;voice["shimmer"]=0.3;voice["breath"]=0.4;voice["oq"]=0.45;voice["fry"]=0.1
	for k in 1+v:
		var c:=Voice.gesture(voice,[[0.01,"a",0.0,0.0,1.0],[0.22,"a",1.0,0.5,0.9],[0.05,"a",0.0,0.0,0.85]],rng.randi())
		Synth.mix_into(b,c,Synth.n_of(0.02+k*0.36),1.0)
	Synth.lowpass(b,3000.0)
	return b

# =============================================================================
# The god
# =============================================================================

## The god's presence under the hush: a low swell, a slow chord in a throat
## of stone, rising over a second, held, and let go when the god is done
## (court_sound.gd fades it). Wrath: lower and darker, with a slow beating
## that unsettles; favour: warmer and brighter, a major third in it.
static func god_swell(wrath:bool,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=9.0
	var b:=Synth.buffer(d)
	var root:=46.0 if wrath else 65.4
	var parts:Array
	# the low notes are felt; the upper ones (3x..6x) carry it on small speakers
	if wrath:parts=[[1.0,1.0],[1.5,0.35],[2.0,0.5],[2.03,0.18],[3.0,0.3],[4.0,0.22],[6.0,0.12]]
	else:parts=[[1.0,0.8],[1.5,0.45],[2.0,0.6],[2.5,0.32],[3.0,0.3],[4.0,0.18],[5.0,0.1]]
	for p in parts:
		var f:=root*float(p[0])
		var drift:=Synth.wander(d,1.1,rng,0.997,1.003)
		var track:=PackedFloat32Array();track.resize(drift.size())
		for i in drift.size():track[i]=f*drift[i]
		var w:=Synth.tone(track,[1.0,0.2])
		Synth.mix_into(b,w,0,float(p[1]))
	# a breath of choir through a throat ("ooo" for wrath, "aah" for favour)
	var air:=Synth.pink(d,rng,0.6)
	var choir:=air.duplicate()
	if wrath:
		var low:=air.duplicate()
		Synth.bandpass(choir,320.0,5.0);Synth.bandpass(low,560.0,6.0)
		for i in choir.size():choir[i]+=low[i]*0.5
	else:
		var a2:=air.duplicate()
		Synth.bandpass(choir,700.0,5.0);Synth.bandpass(a2,1150.0,5.0)
		for i in choir.size():choir[i]+=a2[i]*0.6
	Synth.mix_into(b,choir,0,0.9 if wrath else 0.6)
	if wrath:
		var rumble:=Synth.brown(d,rng,0.8)
		Synth.lowpass(rumble,90.0)
		Synth.mix_into(b,rumble,0,0.7)
	Synth.lowpass(b,1800.0 if not wrath else 900.0)
	Synth.shape(b,[[0.0,0.0],[1.4,0.75],[2.4,1.0],[d,1.0]])
	return Synth.hold_loop(b,SWELL_HOLD,d-0.2,0.8)

## The god's wrath landing: a deep soft boom, felt more than heard.
static func god_boom(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=3.2
	var b:=Synth.tone(Synth.track(d,[[0.0,58.0],[0.3,40.0],[d,32.0]]),[1.0,0.35,0.1])
	Synth.shape(b,[[0.0,0.0],[0.025,1.0],[0.4,0.6],[d,0.0]])
	var rumble:=Synth.brown(d,rng,1.0)
	Synth.lowpass(rumble,160.0+v*60.0)
	Synth.shape(rumble,[[0.0,0.0],[0.05,1.0],[1.2,0.5],[d,0.0]])
	Synth.mix_into(b,rumble,0,0.8)
	return b

# =============================================================================
# The beds
# =============================================================================

static func bed(name:String,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=float(BEDS[name].seconds)+0.6
	var b:PackedFloat32Array
	match name:
		"fire":b=fire_bed(d,rng)
		"wind_soft":b=wind_bed(d,rng,0.4,false)
		"wind_hard":b=wind_bed(d,rng,1.0,false)
		"wind_indoor":b=wind_bed(d,rng,0.5,true)
		"murmur_small":b=murmur_bed(d,rng,3)
		"murmur":b=murmur_bed(d,rng,6)
		"murmur_hall":b=murmur_bed(d,rng,11)
		"room":
			b=Synth.pink(d,rng,0.3);Synth.lowpass(b,400.0)
		_:b=Synth.buffer(d)
	var top:=Synth.peak_of(b)
	if top>0.0001:Synth.scale(b,0.6/top)
	return Synth.seamless(b,0.6)

## The fire's own breath: a low roar that flutters as the flames do, and a
## fine crackle in it (the pops and hisses come on top, at random).
static func fire_bed(d:float,rng:RandomNumberGenerator)->PackedFloat32Array:
	var roar:=Synth.pink(d,rng,1.0)
	Synth.lowpass2(roar,600.0)
	Synth.highpass(roar,60.0)
	var flutter:=Synth.wander(d,0.11,rng,0.35,1.0)
	var slow:=Synth.wander(d,1.3,rng,0.6,1.0)
	for i in roar.size():roar[i]*=flutter[i]*slow[i]
	var b:=roar
	# fine crackle: tiny ticks, many of them, soft
	var t:=0.0
	while t<d-0.01:
		Synth.burst(b,t,0.0015,rng.randf_range(2500.0,6000.0),1.0,rng.randf_range(0.02,0.12),rng)
		t+=rng.randf_range(0.01,0.09)
	return b

## Wind: noise through a slowly moving band, in gusts; hard wind whistles in
## the gaps; indoors it is muffled, outside the walls.
static func wind_bed(d:float,rng:RandomNumberGenerator,strength:float,indoor:bool)->PackedFloat32Array:
	var b:=Synth.pink(d,rng,1.0)
	var centre:=Synth.wander(d,1.6,rng,280.0,750.0+600.0*strength)
	Synth.bandpass_track(b,_frames(centre),0.9+strength)
	var gust:=Synth.wander(d,2.2-strength,rng,0.25,1.0)
	for i in b.size():b[i]*=gust[i]*gust[i]
	var low:=Synth.brown(d,rng,0.6)
	Synth.lowpass(low,120.0)
	for i in b.size():b[i]+=low[i]*(0.5+gust[i]*0.5)
	if strength>=0.9:
		# the howl in the gaps
		var howl:=Synth.pink(d,rng,1.0)
		var hc:=Synth.wander(d,0.9,rng,520.0,1250.0)
		Synth.bandpass_track(howl,_frames(hc),14.0)
		for i in howl.size():howl[i]*=gust[i]*gust[i]*gust[i]
		Synth.mix_into(b,howl,0,0.9)
	if indoor:Synth.lowpass(b,500.0)
	return b

## The people waiting: low talk of a few, of more, of a hall, in their own
## tongue (tongue: court_voice.gd phonology(); empty: a plain one), unclear
## and soft, as if from across the room. people: how many talk.
static func murmur_bed(d:float,rng:RandomNumberGenerator,people:int,tongue:Dictionary={})->PackedFloat32Array:
	return murmur_mix(murmur_tracks(tongue,rng.randi(),d+0.6),people,d,rng)

## Six of the people talking in turns, each a seamless loop `seconds` long
## (less the crossfade): men, women, the old. The murmur of any size is mixed
## from these (murmur_mix), so a hall full of talk costs six voices.
const MURMUR_VOICES:=["man","woman","old_man","woman","man","old_woman"]
static func murmur_tracks(tongue:Dictionary,seed_value:int,seconds:float)->Array[PackedFloat32Array]:
	var out:Array[PackedFloat32Array]=[]
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	for k in MURMUR_VOICES.size():
		var voice:=Voice.plain(String(MURMUR_VOICES[k]),301+k*13+seed_value%97)
		if not tongue.is_empty():voice["tongue"]=tongue
		var talk:=Voice.babble(voice,seconds,rng.randi(),false,{"joy":0.15} if k%2==0 else {})
		# each one talks for a while and then listens
		var turns:=Synth.wander(seconds,rng.randf_range(1.0,2.2),rng,0.0,1.0)
		for i in mini(talk.size(),turns.size()):talk[i]*=0.08+0.92*smoothstep(0.3,0.65,turns[i])
		# now and then someone laughs a little, or agrees
		if k==1 or k==4:
			var aside:=Voice.gesture(voice,[[0.01,"a",0.0,0.0,1.3],[0.05,"a",0.0,0.7,1.3],[0.1,"a",0.7,0.3,1.2],[0.06,"a",0.0,0.2,1.15],[0.1,"a",0.6,0.3,1.08],[0.05,"y",0.0,0.0,1.0]],rng.randi())
			Synth.mix_into(talk,aside,Synth.n_of(rng.randf_range(1.0,seconds-1.5)),0.7)
		var top:=Synth.peak_of(talk)
		if top>0.0:Synth.scale(talk,0.5/top)
		out.append(Synth.seamless(talk,0.6))
	return out

## A murmur of `people` voices from the six (the seventh and on are the six
## again, a little higher or lower and elsewhere in their talk), placed near
## and far, softened by the room. A seamless loop `seconds` long.
static func murmur_mix(tracks:Array[PackedFloat32Array],people:int,seconds:float,rng:RandomNumberGenerator)->PackedFloat32Array:
	var n:=Synth.n_of(seconds+0.6)
	var b:=PackedFloat32Array();b.resize(n)
	if tracks.is_empty():return Synth.seamless(b,0.6)
	for k in people:
		var src:PackedFloat32Array=tracks[k%tracks.size()]
		var m:=src.size()
		var ratio:=1.0 if k<tracks.size() else rng.randf_range(0.9,1.1)
		var pos:=rng.randf_range(0.0,float(m))
		var gain:=rng.randf_range(0.45,1.0)*(1.0 if k<tracks.size() else 0.75)
		for i in n:
			var j:=int(pos);var f:=pos-j
			b[i]+=lerpf(src[j%m],src[(j+1)%m],f)*gain
			pos+=ratio
			if pos>=m:pos-=m
	# across the room: the top of the voices softened, the boom of the lows
	# gone (it is talk, not rumble), two near walls answering
	Synth.lowpass(b,2400.0)
	Synth.highpass(b,180.0)
	var room:=b.duplicate()
	Synth.mix_into(b,room,Synth.n_of(0.023),0.22)
	Synth.mix_into(b,room,Synth.n_of(0.041),0.15)
	var air:=Synth.pink(seconds+0.6,rng,0.03*sqrt(float(people)))
	Synth.lowpass(air,700.0)
	for i in mini(b.size(),air.size()):b[i]+=air[i]
	return Synth.seamless(b,0.6)
