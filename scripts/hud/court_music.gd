extends RefCounted
## THE COURT'S MUSICIAN: someone in the hall plays, softly, while the court
## waits on its god, on what the people know how to play and in the people's
## own way of making a tune.
##
## The instruments are the people's own discoveries (research_600.json):
##   nothing yet               someone hums (a voice, court_voice.gd)
##   bone_flutes_drums         a bone flute and a frame drum
##   rattles_drums_pipes       a reed pipe, a clay drum and a seed rattle
##   harps_and_lyres,
##   lyre_tuning_lessons       a lyre (the flute or the pipe now and then)
##   temple_choirs             small cymbals rung at the start of a phrase
## Each is made the way the real thing makes its sound: the lyre is a
## plucked string (Karplus-Strong: a burst of noise round a delay line the
## length of the string, losing its top each time round), the flute and the
## pipe are breath (noise) through a resonance at the note (and the pipe's
## reed buzzing in odd harmonics through its bore), the drums are membrane
## modes (a circular skin's own partials, 1 : 1.59 : 2.14 : 2.30 ...), struck
## at the middle ("dum") or the rim ("tek"), the rattle is seeds (many tiny
## clicks), the cymbal a ring of inharmonic partials.
##
## The tune is the people's: each sound family has its own scale (pentatonic,
## a maqam's neutral steps, a raga's, the equal sevens of a Tai-like tongue,
## the narrow gaps of a Finnic-like one) and its own beat (four, six, the
## limping seven, or free), and each people its own key, tempo and handful of
## motifs from its own seed, so two peoples' musicians never play alike.
##
## phrase(spec, k) -> samples: one phrase (2-4 bars) of the ensemble, k in
## 0..PHRASES-1; flourish(spec): a quick run and a roll (a gift taken);
## stop(spec, k): the sound of the playing stopping dead (a flute squeak, a
## reed's honk, a muted string, the hummer's "mm?"); tap(spec): the drum's
## last stray tap. spec = people(tongue, seed, known): who plays what, how.
## Pure and deterministic; safe on a worker thread.

const Synth:=preload("res://scripts/hud/court_synth.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const RATE:=22050
const PHRASES:=8

## A circular membrane's partials (Bessel zeros over the first), for drums.
const MEMBRANE:=[1.0,1.594,2.136,2.296,2.653,2.918,3.156,3.501]

## Each sound family's scale (cents above the key) and beat.
const SCALES:={
	"west_african":[0,200,400,700,900],"bantu":[0,200,400,500,700,900,1000],"ethiopic":[0,100,500,600,900],
	"polynesian":[0,200,350,500,700],"austronesian":[0,240,480,720,960],"turkic":[0,150,300,500,700,850,1000],
	"mongolic":[0,200,400,700,900],"sinitic":[0,200,400,700,900],"japonic":[0,100,500,700,800],
	"koreanic":[0,200,500,700,900],"tai_khmer":[0,171,343,514,686,857,1029],"nahuatl":[0,200,400,700,900],
	"mayan":[0,300,500,700,1000],"andean":[0,300,500,700,1000],"semitic":[0,150,350,500,700,850,1000],
	"iranic":[0,150,300,500,700,850,1000],"indo_aryan":[0,100,400,500,700,800,1100],"dravidian":[0,200,400,500,700,900,1100],
	"slavic":[0,200,300,500,700,900,1000],"germanic":[0,200,400,500,700,900,1000],"romance":[0,100,400,500,700,800,1000],
	"celtic":[0,200,400,700,900],"hellenic":[0,100,300,500,700,800,1000],"finnic":[0,200,300,500,700],
	"inuit":[0,200,500,700],"athabaskan":[0,300,500,700,1000],"algonquian":[0,300,500,700,1000],
	"kartvelian":[0,200,350,500,700,850,1000],"amazigh":[0,150,350,500,700,800,1000],"aboriginal":[0,200,300,500,700],
}
## The beat: "four" (eight pulses a bar), "six" (twelve: 3+3+3+3),
## "seven" (2+2+3, limping) or "free" (no bar, the drum only marks).
const METERS:={
	"west_african":"six","bantu":"six","ethiopic":"six","polynesian":"four","austronesian":"four","turkic":"seven",
	"mongolic":"free","sinitic":"free","japonic":"free","koreanic":"six","tai_khmer":"four","nahuatl":"four",
	"mayan":"four","andean":"six","semitic":"four","iranic":"six","indo_aryan":"four","dravidian":"four",
	"slavic":"seven","germanic":"four","romance":"six","celtic":"six","hellenic":"seven","finnic":"four",
	"inuit":"four","athabaskan":"four","algonquian":"four","kartvelian":"seven","amazigh":"six","aboriginal":"four",
}
## Pulses a bar, and the drum's strokes in it: [pulse, "d" (dum) or "t" (tek), how hard].
const BARS:={
	"four":{"pulses":8,"drum":[[0,"d",1.0],[3,"t",0.5],[4,"d",0.75],[6,"t",0.6],[7,"t",0.35]],"cells":[[2,2],[1,1,2],[3,1],[4],[2,1,1]]},
	"six":{"pulses":12,"drum":[[0,"d",1.0],[3,"t",0.5],[5,"t",0.45],[6,"d",0.8],[8,"t",0.5],[10,"t",0.6]],"cells":[[2,1],[3],[1,1,1],[1,2]]},
	"seven":{"pulses":7,"drum":[[0,"d",1.0],[2,"t",0.6],[4,"d",0.7],[6,"t",0.5]],"cells":[[2,2,3],[2,2],[3],[1,1,2]]},
	"free":{"pulses":8,"drum":[[0,"d",0.7]],"cells":[[3],[4],[2,3],[5]]},
}

# =============================================================================
# Who plays what
# =============================================================================

## What the people play, from what they know: {lead, leads (all they have,
## the newest first), drum ("frame", "clay" or ""), rattle, cymbal, name}.
static func ensemble(known:Array)->Dictionary:
	var leads:Array=[]
	if known.has("harps_and_lyres") or known.has("lyre_tuning_lessons"):leads.append("lyre")
	if known.has("rattles_drums_pipes"):leads.append("reed")
	if known.has("bone_flutes_drums"):leads.append("flute")
	if leads.is_empty():leads.append("hum")
	var drum:=""
	if known.has("rattles_drums_pipes"):drum="clay"
	elif known.has("bone_flutes_drums"):drum="frame"
	var e:={"lead":String(leads[0]),"leads":leads,"drum":drum,"rattle":known.has("rattles_drums_pipes"),"cymbal":known.has("temple_choirs")}
	e["name"]="%s.%s%s%s" % [e.lead,drum if drum!="" else "nodrum","+r" if e.rattle else "","+c" if e.cymbal else ""]
	return e

## How a people plays: their scale, beat, key, tempo and motifs, from their
## sound family and their own seed, and the ensemble they know.
static func people(family:String,seed_value:int,known:Array)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^0x6d757369
	var meter:=String(METERS.get(family,"four"))
	var spec:={"family":family,"scale":SCALES.get(family,[0,200,400,700,900]),"meter":meter,
		"bpm":rng.randf_range(72.0,104.0) if meter!="free" else rng.randf_range(56.0,70.0),
		"key":pow(2.0,float(rng.randi_range(-3,4))/12.0),"seed":seed_value,"ensemble":ensemble(known)}
	# a handful of motifs: scale steps (over two octaves) and lengths in pulses
	var motifs:Array=[]
	var n_scale:int=(spec.scale as Array).size()
	var cells:Array=BARS[meter].cells
	for m in 4:
		var notes:Array=[]
		var degree:=rng.randi_range(0,n_scale)
		var pulses:=0
		var bar:int=int(BARS[meter].pulses)
		while pulses<bar:
			var cell:Array=cells[rng.randi_range(0,cells.size()-1)]
			for d in cell:
				if pulses>=bar:break
				var step:int=[-1,-1,1,1,2,-2,0,3,-3][rng.randi_range(0,8)]
				degree=clampi(degree+step,0,n_scale*2-1)
				var length:=mini(int(d),bar-pulses)
				notes.append([degree,length])
				pulses+=length
		motifs.append(notes)
	spec["motifs"]=motifs
	return spec

## The pitch (Hz) of a step of the scale for an instrument's own range.
static func pitch(spec:Dictionary,degree:int,lead:String)->float:
	var scale:Array=spec.scale
	var n:=scale.size()
	var cents:=float(scale[posmod(degree,n)])+1200.0*floorf(float(degree)/float(n))
	var base:float={"flute":466.0,"reed":330.0,"lyre":196.0,"hum":147.0}.get(lead,300.0)
	return base*float(spec.key)*pow(2.0,cents/1200.0)

# =============================================================================
# Phrases
# =============================================================================

## One phrase of the people's music: two to four bars of motifs (one played
## again, changed a little, the last landing home), the lead on top, the drum
## under it, a rattle on the off-beats, a cymbal at the start in a temple age.
## Some phrases the drummer plays alone, or the lead without the drum.
static func phrase(spec:Dictionary,k:int)->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=int(spec.seed)*31+k*977
	var e:Dictionary=spec.ensemble
	var leads:Array=e.leads
	var lead:=String(leads[0]) if (k%3!=2 or leads.size()==1) else String(leads[1+k%(leads.size()-1)])
	var meter:=String(spec.meter)
	var bar:int=int(BARS[meter].pulses)
	var pulse:=60.0/float(spec.bpm)/2.0
	var motifs:Array=spec.motifs
	var order:Array=[k%4,k%4,(k+1)%4,(k+3)%4] if k%2==0 else [(k+1)%4,(k+2)%4,(k+1)%4]
	var bars:=order.size()
	var drum_only:=String(e.drum)!="" and k==5
	var lead_only:=String(e.drum)=="" or k==3
	var notes:Array=[]
	var t:=0.0
	for b in bars:
		var motif:Array=motifs[int(order[b])]
		var shift:=0 if b<2 else rng.randi_range(-1,1)
		for i in motif.size():
			var deg:=int(motif[i][0])+shift
			if b==bars-1 and i==motif.size()-1:deg=0 if rng.randf()<0.6 else (spec.scale as Array).size()
			var d:=float(motif[i][1])*pulse
			if meter=="free":d*=rng.randf_range(0.85,1.25)
			notes.append([t,d,pitch(spec,deg,lead),rng.randf_range(0.75,1.0)])
			t+=d
	var seconds:=t+(1.6 if lead=="lyre" else 0.6)
	var out:=Synth.buffer(seconds)
	if not drum_only:Synth.mix_into(out,play(lead,notes,seconds,rng,spec),0,1.0)
	if String(e.drum)!="" and not lead_only:
		var strokes:Array=BARS[meter].drum
		for b in bars:
			for s in strokes:
				var at:=float(b*bar+int(s[0]))*pulse
				if meter=="free":at=float(b*bar)*pulse*rng.randf_range(0.95,1.05)
				var hit:=drum(String(e.drum),String(s[1]),float(s[2])*rng.randf_range(0.8,1.0),rng)
				Synth.mix_into(out,hit,Synth.n_of(at+rng.randf_range(-0.008,0.008)),0.75 if not drum_only else 0.9)
			if drum_only and rng.randf()<0.5:
				# the drummer alone fills the bar's end
				for f in 3:Synth.mix_into(out,drum(String(e.drum),"t",0.4,rng),Synth.n_of(float(b*bar+bar-1)*pulse+f*pulse/3.0),0.6)
	if bool(e.rattle) and not lead_only:
		for p in bars*bar:
			if p%2==1:Synth.mix_into(out,rattle(rng.randf_range(0.5,0.9),rng),Synth.n_of(float(p)*pulse),0.22)
	if bool(e.cymbal) and k%4==0:Synth.mix_into(out,cymbal(rng),0,0.18)
	Synth.fade_edges(out,0.002,0.15)
	var top:=Synth.peak_of(out)
	if top>0.0001:Synth.scale(out,0.6/top)
	return out

## A gift is taken: a quick run up the scale to the top, the drum rolling under it.
static func flourish(spec:Dictionary)->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=int(spec.seed)^0x666c6f
	var e:Dictionary=spec.ensemble
	var lead:=String(e.lead)
	var n:int=(spec.scale as Array).size()
	var notes:Array=[]
	var t:=0.0
	for i in n+1:
		var d:=0.075 if i<n else 0.55
		notes.append([t,d,pitch(spec,i,lead),0.8+0.2*float(i)/float(n)]);t+=d
	var out:=Synth.buffer(t+1.4)
	Synth.mix_into(out,play(lead,notes,t+1.4,rng,spec),0,1.0)
	if String(e.drum)!="":
		var at:=0.0
		while at<t:
			Synth.mix_into(out,drum(String(e.drum),"t",0.3+0.5*at/t,rng),Synth.n_of(at),0.6);at+=0.055
		Synth.mix_into(out,drum(String(e.drum),"d",1.0,rng),Synth.n_of(t),0.9)
	if bool(e.rattle):Synth.mix_into(out,rattle(1.0,rng),Synth.n_of(t),0.4)
	if bool(e.cymbal):Synth.mix_into(out,cymbal(rng),Synth.n_of(t),0.3)
	Synth.fade_edges(out,0.002,0.2)
	var top:=Synth.peak_of(out)
	if top>0.0001:Synth.scale(out,0.6/top)
	return out

## The playing stopped dead: the lead's last sound as it breaks off.
static func stop(spec:Dictionary,k:int)->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=int(spec.seed)+k*131
	var lead:=String((spec.ensemble as Dictionary).lead)
	var f:=pitch(spec,rng.randi_range(2,5),lead)
	var out:PackedFloat32Array
	match lead:
		"flute":
			# overblown: the note jumps up and breaks into a shriek of air
			var d:=0.16
			var track:=Synth.track(d,[[0.0,f],[0.03,f*2.05],[d,f*2.2]])
			out=_breath_tone(track,Synth.track(d,[[0.0,0.6],[0.02,1.0],[d-0.02,0.9],[d,0.0]]),rng,0.55)
		"reed":
			# the reed honks and chokes
			var d:=0.2
			out=_reed(Synth.track(d,[[0.0,f],[0.05,f*0.82],[d,f*0.7]]),Synth.track(d,[[0.0,0.0],[0.01,1.0],[d-0.015,0.8],[d,0.0]]),rng)
		"lyre":
			# a string caught by a hand: a dull plunk, a buzz
			out=_string(f,0.35,0.2,rng)
			var buzz:=Synth.white(0.08,rng)
			Synth.bandpass(buzz,f*4.0,3.0)
			Synth.shape(buzz,[[0.0,1.0],[0.08,0.0]])
			Synth.mix_into(out,buzz,0,0.3)
		_:
			# the hummer: "mm-?" and nothing
			var v:=Voice.plain("woman" if int(spec.seed)%2==0 else "man",int(spec.seed)%97)
			v["f0"]=f
			out=Voice.gesture(v,[[0.01,"u",0.0,0.0,1.0,1.0],[0.12,"u",0.7,0.05,1.0,1.0],[0.08,"u",0.6,0.05,1.22,1.0],[0.02,"u",0.0,0.0,1.25,1.0]],rng.randi())
	Synth.fade_edges(out,0.002,0.01)
	var top:=Synth.peak_of(out)
	if top>0.0001:Synth.scale(out,0.6/top)
	return out

## The drum's one stray tap after everything has stopped.
static func tap(spec:Dictionary)->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=int(spec.seed)^0x746170
	var e:Dictionary=spec.ensemble
	var out:=drum(String(e.drum) if String(e.drum)!="" else "frame","t",0.45,rng)
	var top:=Synth.peak_of(out)
	if top>0.0001:Synth.scale(out,0.45/top)
	return out

# =============================================================================
# The instruments
# =============================================================================

## A line of notes [[t, seconds, Hz, how loud]...] on an instrument.
static func play(lead:String,notes:Array,seconds:float,rng:RandomNumberGenerator,spec:Dictionary)->PackedFloat32Array:
	match lead:
		"lyre":
			var out:=Synth.buffer(seconds)
			for note in notes:
				var s:=_string(float(note[2]),minf(2.2,float(note[1])+1.2),0.996,rng)
				Synth.mix_into(out,s,Synth.n_of(float(note[0])),float(note[3]))
			# the soundbox
			var box:=out.duplicate()
			Synth.resonate(box,260.0,70.0)
			Synth.mix_into(out,box,0,0.25)
			Synth.lowpass(out,4500.0)
			return out
		"hum":
			var v:=Voice.plain("woman" if int(spec.seed)%2==0 else "man",int(spec.seed)%97)
			var base:=float(notes[0][2]) if not notes.is_empty() else 165.0
			v["f0"]=base;v["breath"]=0.04
			var steps:Array=[[0.02,"u",0.0,0.0,1.0,1.0]]
			for note in notes:
				var m:=float(note[2])/base
				var d:=float(note[1])
				steps.append([d*0.85,"u",0.55*float(note[3]),0.04,m,1.0])
				steps.append([d*0.15,"u",0.25,0.03,m,1.0])
			steps.append([0.1,"u",0.0,0.0,1.0,1.0])
			return Voice.gesture(v,steps,rng.randi())
	# the winds: a pitch line with glides, and its breath
	var f0:=Synth.buffer(seconds)
	var env:=Synth.buffer(seconds)
	var last_f:=float(notes[0][2]) if not notes.is_empty() else 440.0
	for note in notes:
		var a:=Synth.n_of(float(note[0]));var b:=mini(f0.size(),Synth.n_of(float(note[0])+float(note[1])))
		var f:=float(note[2]);var vel:=float(note[3])
		var glide:=Synth.n_of(0.035)
		var held:=int(float(b-a)*0.88)
		for i in range(a,b):
			var j:=i-a
			var vib:=1.0+0.006*sin(TAU*5.2*float(j)/RATE)*clampf((float(j)/RATE-0.18)*4.0,0.0,1.0)
			f0[i]=lerpf(last_f,f,minf(1.0,float(j)/float(glide)))*vib
			var e:=minf(1.0,float(j)/float(Synth.n_of(0.03)))
			if j>held:e*=maxf(0.0,1.0-float(j-held)/float(maxi(1,b-a-held)))
			env[i]=e*vel
		last_f=f
	if lead=="reed":return _reed(f0,env,rng)
	var out:=_breath_tone(f0,env,rng,0.35)
	# a chiff of air at each note's start
	for note in notes:Synth.burst(out,float(note[0]),0.02,2800.0,1.2,0.12*float(note[3]),rng)
	return out

## Breath through a resonance at the note (a flute's jet on its bore): noise
## made into a whistle by a narrow band at the pitch, a little pure tone under
## it to steady it, and the air itself around it. noisy: how airy (0..1).
static func _breath_tone(f0:PackedFloat32Array,env:PackedFloat32Array,rng:RandomNumberGenerator,noisy:float)->PackedFloat32Array:
	var n:=f0.size()
	var jet:=Synth.white(float(n)/RATE,rng)
	for i in n:jet[i]*=env[i]
	var frames:=PackedFloat32Array();frames.resize(n/32+1)
	for i in frames.size():frames[i]=f0[mini(i*32,n-1)]
	# twice through the narrow band: the note, and little of the rest of the noise
	var whistle:=jet.duplicate()
	Synth.bandpass_track(whistle,frames,30.0)
	Synth.bandpass_track(whistle,frames,30.0)
	var tone:=Synth.tone(f0,[1.0,0.1,0.04])
	var air:=jet.duplicate()
	Synth.bandpass(air,3500.0,0.7)
	var out:=Synth.buffer(float(n)/RATE)
	for i in n:out[i]=whistle[i]*10.0+tone[i]*env[i]*0.5+air[i]*0.06*noisy
	Synth.lowpass(out,6000.0)
	return out

## A reed buzzing in a pipe: a tone rich in odd harmonics (the reed shuts the
## pipe at one end), coloured by the bore, with breath in it.
static func _reed(f0:PackedFloat32Array,env:PackedFloat32Array,rng:RandomNumberGenerator)->PackedFloat32Array:
	var n:=f0.size()
	var buzz:=Synth.tone(f0,[1.0,0.18,0.62,0.14,0.42,0.1,0.3,0.08,0.2,0.06,0.13])
	var breath:=Synth.white(float(n)/RATE,rng,0.08)
	var out:=Synth.buffer(float(n)/RATE)
	for i in n:out[i]=(buzz[i]+breath[i])*env[i]
	var bore:=out.duplicate()
	Synth.resonate(bore,1150.0,260.0)
	var horn:=out.duplicate()
	Synth.resonate(horn,2500.0,400.0)
	for i in n:out[i]=out[i]*0.35+bore[i]*0.9+horn[i]*0.35
	Synth.lowpass(out,5000.0)
	return out

## A plucked gut string (Karplus-Strong): a burst of soft noise round a delay
## line one period long, each pass averaged (losing its top) and kept by
## `keep`; seconds long.
static func _string(f:float,seconds:float,keep:float,rng:RandomNumberGenerator)->PackedFloat32Array:
	var out:=Synth.buffer(seconds)
	var period:=float(RATE)/maxf(40.0,f)
	var len:=maxi(2,int(period))
	var frac:=period-float(len)
	var line:=PackedFloat32Array();line.resize(len+1)
	# a gut string plucked with a finger: the burst is soft
	var y:=0.0
	for i in line.size():
		y+=0.5*(rng.randf_range(-1.0,1.0)-y)
		line[i]=y
	var idx:=0
	var prev:=0.0
	var ap_x:=0.0;var ap_y:=0.0
	var c:=(1.0-frac)/(1.0+frac)
	for i in out.size():
		var cur:=line[idx]
		var avg:=0.5*(cur+prev)*keep
		prev=cur
		# a fractional delay (first-order all-pass) keeps the string in tune
		var v:=c*avg+ap_x-c*ap_y
		ap_x=avg;ap_y=v
		line[idx]=v
		out[i]=cur
		idx=(idx+1)%len
	Synth.shape(out,[[0.0,1.0],[maxf(0.05,seconds-0.08),1.0],[seconds,0.0]])
	return out

## A drum stroke: "d" in the middle of the skin (the low partials ring), "t"
## at the rim (the high ones, short, with the slap of the fingers). frame: a
## big hide frame drum; clay: a goblet drum of clay, its "dum" dropping in pitch.
static func drum(kind:String,stroke:String,vel:float,rng:RandomNumberGenerator)->PackedFloat32Array:
	var f:=108.0 if kind=="frame" else 150.0
	var out:=Synth.buffer(0.7)
	if stroke=="d":
		var partials:Array=[]
		for i in MEMBRANE.size():
			var amp:float=[1.0,0.45,0.3,0.2,0.15,0.1,0.08,0.06][i]
			var decay:float=[0.38,0.22,0.16,0.12,0.1,0.08,0.07,0.06][i]
			partials.append(Vector3(f*float(MEMBRANE[i])*rng.randf_range(0.99,1.01),amp,decay*(0.8 if kind=="clay" else 1.0)))
		Synth.modal(out,0.0,partials,rng,vel)
		if kind=="clay":
			# the clay's dum drops as the skin settles
			var drop:=Synth.tone(Synth.track(0.3,[[0.0,f*1.1],[0.3,f*0.88]]),[1.0,0.3])
			Synth.shape(drop,[[0.0,0.0],[0.004,1.0],[0.3,0.0]])
			Synth.mix_into(out,drop,0,0.5*vel)
		var thump:=Synth.white(0.03,rng)
		Synth.lowpass(thump,600.0)
		Synth.shape(thump,[[0.0,1.0],[0.03,0.0]])
		Synth.mix_into(out,thump,0,0.6*vel)
	else:
		var partials:Array=[]
		for i in range(2,MEMBRANE.size()):
			partials.append(Vector3(f*float(MEMBRANE[i])*(3.0 if kind=="clay" else 2.2)*rng.randf_range(0.98,1.02),0.5/float(i),0.05))
		Synth.modal(out,0.0,partials,rng,vel)
		Synth.burst(out,0.0,0.018,2200.0 if kind=="frame" else 3200.0,0.9,0.8*vel,rng)
	Synth.lowpass(out,7000.0)
	return out

## Seeds in a gourd shaken once: many tiny clicks, thick at first, thinning.
static func rattle(vel:float,rng:RandomNumberGenerator)->PackedFloat32Array:
	var out:=Synth.buffer(0.2)
	var t:=0.0
	while t<0.16:
		Synth.burst(out,t,0.0015,rng.randf_range(3500.0,6500.0),1.5,rng.randf_range(0.3,1.0)*vel*(1.0-t/0.18),rng)
		t+=rng.randf_range(0.002,0.012)*(1.0+t*20.0)
	return out

## Small cymbals rung together: a ring of inharmonic partials, long and soft.
static func cymbal(rng:RandomNumberGenerator)->PackedFloat32Array:
	var out:=Synth.buffer(1.8)
	Synth.modal(out,0.0,[Vector3(2150.0,1.0,0.6),Vector3(3460.0,0.7,0.5),Vector3(5170.0,0.5,0.35),Vector3(7230.0,0.3,0.25),Vector3(2172.0,0.6,0.55)],rng,0.6)
	Synth.burst(out,0.0,0.01,6000.0,1.0,0.3,rng)
	return out
