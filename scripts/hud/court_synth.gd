extends RefCounted
## THE COURT'S SOUND KIT: the few pieces of signal arithmetic every court
## sound is made of (court_voice.gd, court_foley.gd, court_sound.gd).
##
## Everything the court hears is made here, in numbers, at 22050 samples a
## second, mono: no recording, no file. A sound is a PackedFloat32Array of
## samples in -1..1 until to_stream() turns it into an AudioStreamWAV (16-bit),
## the house's own precedent (chronicle_card.gd sting()).
##
## The pieces:
##   resonator  a two-pole formant (Klatt's): a vowel's F1/F2/F3, a bowl's ring
##   svf        a state-variable band (Zavalishin's, stable to the top): the
##              hiss of an s, wind through a gap, a bird's whistle
##   modal      a struck thing: decaying partials (wood, clay, bone, a board)
##   noise      white, and a pinker one for wind and fire
## Pure and deterministic: every random draw comes from the RandomNumberGenerator
## handed in, so the same seed makes the same sound, sample for sample. No node,
## no scene, no global state: safe to run on a worker thread.

const RATE:=22050
const NYQUIST:=11025.0

## Seconds to samples.
static func n_of(seconds:float)->int:
	return maxi(1,int(round(seconds*RATE)))

static func buffer(seconds:float)->PackedFloat32Array:
	var b:=PackedFloat32Array();b.resize(n_of(seconds))
	return b

# --- Turning samples into a stream ------------------------------------------------

## Samples in -1..1 to a 16-bit mono AudioStreamWAV. peak > 0 scales the loudest
## sample to that level first (0 leaves the level alone); everything passes a
## gentle soft clip so nothing ever cracks. loop: a seamless forward loop.
static func to_stream(buf:PackedFloat32Array,peak:=0.0,loop:=false,loop_from:=0)->AudioStreamWAV:
	var n:=buf.size()
	var gain:=1.0
	if peak>0.0:
		var top:=0.000001
		for i in n:top=maxf(top,absf(buf[i]))
		gain=peak/top
	var data:=PackedByteArray();data.resize(n*2)
	for i in n:
		var v:=buf[i]*gain
		# soft knee above 0.9
		if v>0.9:v=0.9+0.1*tanh((v-0.9)*10.0)
		elif v<-0.9:v=-0.9+0.1*tanh((v+0.9)*10.0)
		data.encode_s16(i*2,clampi(int(v*32767.0),-32768,32767))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=RATE;stream.stereo=false
	stream.data=data
	if loop:
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=clampi(loop_from,0,n-1);stream.loop_end=n
	return stream

## The samples of a 16-bit mono stream back, -1..1 (tests, the offline mixer).
static func samples_of(stream:AudioStreamWAV)->PackedFloat32Array:
	var out:=PackedFloat32Array()
	if stream==null:return out
	var data:=stream.data
	var n:=data.size()/2
	out.resize(n)
	for i in n:out[i]=float(data.decode_s16(i*2))/32767.0
	return out

static func peak_of(buf:PackedFloat32Array)->float:
	var top:=0.0
	for v in buf:top=maxf(top,absf(v))
	return top

static func rms_of(buf:PackedFloat32Array,from:=0,to:=-1)->float:
	if to<0 or to>buf.size():to=buf.size()
	if to<=from:return 0.0
	var s:=0.0
	for i in range(from,to):s+=buf[i]*buf[i]
	return sqrt(s/float(to-from))

static func scale(buf:PackedFloat32Array,gain:float)->void:
	for i in buf.size():buf[i]*=gain

## Short fades at both ends: no click where a sound starts or stops.
static func fade_edges(buf:PackedFloat32Array,in_s:=0.004,out_s:=0.012)->void:
	var n:=buf.size()
	var a:=mini(n,n_of(in_s));var b:=mini(n,n_of(out_s))
	for i in a:buf[i]*=float(i)/float(a)
	for i in b:buf[n-1-i]*=float(i)/float(b)

## A loop with no seam: the last `xfade` seconds are crossfaded (equal power)
## into the head and cut off, so the end flows into the start.
static func seamless(buf:PackedFloat32Array,xfade:=0.4)->PackedFloat32Array:
	var x:=n_of(xfade)
	var n:=buf.size()
	if n<=x*2:return buf
	var out:=buf.slice(0,n-x)
	for i in x:
		var t:=float(i)/float(x)
		out[i]=buf[i]*sin(t*PI*0.5)+buf[n-x+i]*cos(t*PI*0.5)
	return out

## A held middle that loops forever after its start: the samples up to
## `to` (seconds), with the last `xfade` before it crossfaded into what
## followed `from`, so playing on from `to` back to `from` has no seam.
## Loop it with to_stream(..., loop_from = n_of(from)).
static func hold_loop(buf:PackedFloat32Array,from:float,to:float,xfade:=0.5)->PackedFloat32Array:
	var a:=n_of(from);var b:=mini(n_of(to),buf.size());var x:=mini(n_of(xfade),a)
	var out:=buf.slice(0,b)
	for i in x:
		var t:=float(i)/float(x)
		var k:=b-x+i
		out[k]=buf[k]*cos(t*PI*0.5)+buf[a-x+i]*sin(t*PI*0.5)
	return out

## Adds src into dst at a sample offset, times gain (clipped to dst's length).
static func mix_into(dst:PackedFloat32Array,src:PackedFloat32Array,at:int,gain:=1.0)->void:
	var start:=maxi(0,at)
	var end:=mini(dst.size(),at+src.size())
	for i in range(start,end):dst[i]+=src[i-at]*gain

# --- Filters ----------------------------------------------------------------------

## One-pole low-pass, in place.
static func lowpass(buf:PackedFloat32Array,cutoff:float)->void:
	var a:=1.0-exp(-TAU*clampf(cutoff,10.0,NYQUIST)/RATE)
	var y:=0.0
	for i in buf.size():
		y+=a*(buf[i]-y);buf[i]=y

## Two-pole low-pass (two one-poles), in place: a thump stays a thump.
static func lowpass2(buf:PackedFloat32Array,cutoff:float)->void:
	lowpass(buf,cutoff);lowpass(buf,cutoff)

## One-pole high-pass, in place.
static func highpass(buf:PackedFloat32Array,cutoff:float)->void:
	var a:=1.0-exp(-TAU*clampf(cutoff,10.0,NYQUIST)/RATE)
	var y:=0.0
	for i in buf.size():
		y+=a*(buf[i]-y);buf[i]=buf[i]-y

## Klatt's two-pole resonator coefficients for a centre and bandwidth (Hz):
## y = a*x + b*y1 + c*y2, unity gain at DC.
static func reso(freq:float,bw:float)->Vector3:
	var f:=clampf(freq,20.0,NYQUIST*0.96)
	var c:=-exp(-TAU*bw/RATE)
	var b:=2.0*exp(-PI*bw/RATE)*cos(TAU*f/RATE)
	return Vector3(1.0-b-c,b,c)

## A resonator run over a whole buffer, in place (fixed centre).
static func resonate(buf:PackedFloat32Array,freq:float,bw:float)->void:
	var k:=reso(freq,bw)
	var y1:=0.0;var y2:=0.0
	for i in buf.size():
		var y:=k.x*buf[i]+k.y*y1+k.z*y2
		y2=y1;y1=y;buf[i]=y

## A state-variable band-pass over a buffer, in place: unity gain at its centre,
## q the sharpness (0.5 broad .. 20 a whistle).
static func bandpass(buf:PackedFloat32Array,freq:float,q:float)->void:
	var g:=tan(PI*clampf(freq,20.0,NYQUIST*0.98)/RATE)
	var k:=1.0/maxf(q,0.05)
	var a1:=1.0/(1.0+g*(g+k));var a2:=g*a1;var a3:=g*a2
	var ic1:=0.0;var ic2:=0.0
	for i in buf.size():
		var v3:=buf[i]-ic2
		var v1:=a1*ic1+a2*v3
		var v2:=ic2+a2*ic1+a3*v3
		ic1=2.0*v1-ic1;ic2=2.0*v2-ic2
		buf[i]=v1*k

## Band-pass whose centre moves: freq_at(i) is read every 32 samples from a
## track (Hz, one value a frame of 32 samples). Unity gain at the centre.
static func bandpass_track(buf:PackedFloat32Array,track:PackedFloat32Array,q:float)->void:
	var k:=1.0/maxf(q,0.05)
	var ic1:=0.0;var ic2:=0.0
	var a1:=0.0;var a2:=0.0;var a3:=0.0
	for i in buf.size():
		if i%32==0:
			var fi:=mini(i/32,track.size()-1)
			var g:=tan(PI*clampf(track[fi],20.0,NYQUIST*0.98)/RATE)
			a1=1.0/(1.0+g*(g+k));a2=g*a1;a3=g*a2
		var v3:=buf[i]-ic2
		var v1:=a1*ic1+a2*v3
		var v2:=ic2+a2*ic1+a3*v3
		ic1=2.0*v1-ic1;ic2=2.0*v2-ic2
		buf[i]=v1*k

# --- Sources ----------------------------------------------------------------------

static func white(seconds:float,rng:RandomNumberGenerator,amp:=1.0)->PackedFloat32Array:
	var b:=buffer(seconds)
	for i in b.size():b[i]=rng.randf_range(-amp,amp)
	return b

## A pinker noise (Paul Kellet's economy filter): wind, fire's roar, crowd air.
static func pink(seconds:float,rng:RandomNumberGenerator,amp:=1.0)->PackedFloat32Array:
	var b:=buffer(seconds)
	var b0:=0.0;var b1:=0.0;var b2:=0.0
	for i in b.size():
		var w:=rng.randf_range(-1.0,1.0)
		b0=0.99765*b0+w*0.0990460
		b1=0.96300*b1+w*0.2965164
		b2=0.57000*b2+w*1.0526913
		b[i]=(b0+b1+b2+w*0.1848)*0.25*amp
	return b

## Brown noise: the low rumble under wind and thunder.
static func brown(seconds:float,rng:RandomNumberGenerator,amp:=1.0)->PackedFloat32Array:
	var b:=buffer(seconds)
	var y:=0.0
	for i in b.size():
		y=(y+rng.randf_range(-1.0,1.0)*0.02)*0.998
		b[i]=y*3.5*amp
	return b

## A struck thing: partials [freq Hz, amp, decay seconds] rung from `at` (s),
## each with a random phase and a slightly detuned twin for a natural beat.
static func modal(buf:PackedFloat32Array,at:float,partials:Array,rng:RandomNumberGenerator,gain:=1.0)->void:
	var start:=n_of(at)
	for p:Vector3 in partials:
		var f:=p.x;var amp:=p.y*gain;var decay:=maxf(0.005,p.z)
		var length:=mini(buf.size()-start,n_of(decay*6.0))
		if length<=0 or f>=NYQUIST*0.95:continue
		var ph:=rng.randf()*TAU
		var detune:=1.0+rng.randf_range(-0.004,0.004)
		var w:=TAU*f/RATE
		var w2:=w*detune
		var k:=exp(-1.0/(decay*RATE))
		var env:=1.0
		for i in length:
			buf[start+i]+=(sin(ph+w*i)*0.7+sin(ph*1.3+w2*i)*0.3)*env*amp
			env*=k

## A short burst of noise (a click, a slap, a tap): `dur` seconds from `at`,
## band-passed at freq with q, decaying fast.
static func burst(buf:PackedFloat32Array,at:float,dur:float,freq:float,q:float,amp:float,rng:RandomNumberGenerator)->void:
	var piece:=white(dur,rng)
	var n:=piece.size()
	for i in n:piece[i]*=pow(1.0-float(i)/float(n),2.0)
	bandpass(piece,freq,q)
	mix_into(buf,piece,n_of(at),amp)

## A smooth random wander in 0..1 (a value a `step` seconds apart, eased
## between): the flutter of a flame, a gust's strength. One value a sample.
static func wander(seconds:float,step:float,rng:RandomNumberGenerator,low:=0.0,high:=1.0)->PackedFloat32Array:
	var b:=buffer(seconds)
	var every:=maxi(2,n_of(step))
	var a:=rng.randf_range(low,high);var z:=rng.randf_range(low,high)
	for i in b.size():
		var j:=i%every
		if j==0 and i>0:a=z;z=rng.randf_range(low,high)
		var t:=float(j)/float(every)
		t=t*t*(3.0-2.0*t)
		b[i]=lerpf(a,z,t)
	return b

## A tone whose pitch follows a track (Hz a sample): a whistle, a whine, a hum.
## harmonics: amplitudes of partials 1..n.
static func tone(track:PackedFloat32Array,harmonics:Array=[1.0])->PackedFloat32Array:
	var b:=PackedFloat32Array();b.resize(track.size())
	var ph:=0.0
	for i in track.size():
		ph+=track[i]/RATE
		if ph>=1.0:ph-=1.0
		var v:=0.0
		for h in harmonics.size():
			if float(h+1)*track[i]<NYQUIST*0.9:v+=sin(TAU*ph*float(h+1))*float(harmonics[h])
		b[i]=v
	return b

## A track (one value a sample) through the given points [[t seconds, value]...],
## eased between them.
static func track(seconds:float,points:Array)->PackedFloat32Array:
	var b:=buffer(seconds)
	if points.is_empty():return b
	var j:=0
	for i in b.size():
		var t:=float(i)/RATE
		while j<points.size()-1 and t>=float(points[j+1][0]):j+=1
		if j>=points.size()-1:b[i]=float(points[points.size()-1][1]);continue
		var t0:=float(points[j][0]);var t1:=float(points[j+1][0])
		var x:=clampf((t-t0)/maxf(t1-t0,0.0001),0.0,1.0)
		x=x*x*(3.0-2.0*x)
		b[i]=lerpf(float(points[j][1]),float(points[j+1][1]),x)
	return b

## Multiplies a buffer by an envelope through points [[t, gain]...] (eased).
static func shape(buf:PackedFloat32Array,points:Array)->void:
	var env:=track(float(buf.size())/RATE,points)
	for i in mini(buf.size(),env.size()):buf[i]*=env[i]

## A hash of a string to a seed (stable across runs and platforms).
static func seed_of(text:String)->int:
	return absi(text.hash())
