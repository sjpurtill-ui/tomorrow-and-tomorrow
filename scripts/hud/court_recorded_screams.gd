extends RefCounted
## Recorded performances; do not route these through the speech synthesizer.
## Sources, licenses and editing notes: assets/audio/court/SOURCES.md.
const MALE:=preload("res://assets/audio/court/scream-male.wav")
const FEMALE:=preload("res://assets/audio/court/scream-female.wav")
static func samples(voice:Dictionary)->PackedFloat32Array:
	var female:=String(voice.get("register","man")) in ["woman","old_woman","youth_f","girl"]
	var clip:AudioStreamWAV=FEMALE if female else MALE
	# Both assets are mono PCM16/22050. Tiny individual variation preserves acting.
	var rate:=0.98+float(posmod(int(voice.get("seed",0)),101))*0.0004
	var bytes:=clip.data
	var n:=bytes.size()/2
	var out:=PackedFloat32Array();out.resize(int(float(n-1)/rate))
	for i in out.size():
		var at:=i*rate;var a:=int(at)
		out[i]=lerpf(float(bytes.decode_s16(a*2)),float(bytes.decode_s16(mini(a+1,n-1)*2)),at-a)/32768.0
	return out
