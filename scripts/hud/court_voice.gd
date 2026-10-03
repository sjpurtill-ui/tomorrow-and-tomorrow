extends RefCounted
## THE COURT'S VOICES: a babble for every speech bubble, never the words.
##
## Each person in the hall speaks in their own people's sounds. The syllables
## are made from that people's tongue (people_language.gd: its onsets, vowels,
## vowel pairs, codas and endings, and how often each comes), so our people and
## each envoy's people audibly sound different: a Kartvelian-sounding envoy
## clicks out clusters and ejectives, a Polynesian-sounding one flows in open
## vowels, a Sinitic-sounding one sings its tones. Nobody says the words; the
## words only time it: one syllable for each opening of the mouth that the
## acting layer (court_acting.gd talk(), K) makes from the same text, over the
## same seconds, pausing where it pauses.
##
## The sound itself is a small source-filter voice (Klatt's way): a glottal
## pulse with its jitter and shimmer, breath, three formants and a fourth for
## presence, a nasal murmur, and frication shaped where the tongue makes it.
## Each person keeps their voice for life (a hash of who they are): age and sex
## set the pitch and the size of the throat; the old crackle and waver, a child
## chirps, a war leader's voice has gravel in it. The mood moves it: fear is
## high, clipped and quick, with a crack; pride is low, slow-sounding and
## level; anger is pressed; joy bounces; grief sags and breathes. A mutter is
## whispered.
##
## Kept soft on purpose: a gentle spectral tilt, sibilants held down, a quiet
## level, no two lines alike (each line's syllables come from its own text).
##
## Pure and deterministic: spec() reads the people's tongue (main thread);
## render() only does arithmetic on what spec() returned (any thread).
## The same person, line, seconds and mood make the same samples.

const Synth:=preload("res://scripts/hud/court_synth.gd")
const RATE:=22050
## Samples a control frame (formants, amplitudes and pitch move once a frame).
const FRAME:=32

## The voice of an age and sex: f0 (Hz), fs (formant scale: the size of the
## throat), range (pitch movement), breath, oq (open quotient: higher is
## softer), tilt (Hz: how much top the voice has), jitter, shimmer, tremor
## (an old voice's waver), fry (crackle: a long irregular pulse now and then).
const REGISTERS:={
	"man":{"f0":112.0,"fs":1.0,"range":1.0,"breath":0.05,"oq":0.58,"tilt":2300.0,"jitter":0.006,"shimmer":0.04,"tremor":0.0,"fry":0.0},
	"woman":{"f0":204.0,"fs":1.15,"range":1.1,"breath":0.10,"oq":0.66,"tilt":2700.0,"jitter":0.005,"shimmer":0.035,"tremor":0.0,"fry":0.0},
	"youth_m":{"f0":136.0,"fs":1.07,"range":1.1,"breath":0.07,"oq":0.6,"tilt":2600.0,"jitter":0.007,"shimmer":0.04,"tremor":0.0,"fry":0.0},
	"youth_f":{"f0":216.0,"fs":1.19,"range":1.15,"breath":0.10,"oq":0.66,"tilt":2900.0,"jitter":0.005,"shimmer":0.035,"tremor":0.0,"fry":0.0},
	"boy":{"f0":272.0,"fs":1.30,"range":1.3,"breath":0.08,"oq":0.64,"tilt":3200.0,"jitter":0.008,"shimmer":0.05,"tremor":0.0,"fry":0.0},
	"girl":{"f0":288.0,"fs":1.34,"range":1.35,"breath":0.09,"oq":0.66,"tilt":3300.0,"jitter":0.008,"shimmer":0.05,"tremor":0.0,"fry":0.0},
	"old_man":{"f0":121.0,"fs":0.98,"range":0.85,"breath":0.17,"oq":0.62,"tilt":2000.0,"jitter":0.026,"shimmer":0.12,"tremor":0.024,"fry":0.07},
	"old_woman":{"f0":186.0,"fs":1.10,"range":0.9,"breath":0.19,"oq":0.68,"tilt":2200.0,"jitter":0.022,"shimmer":0.11,"tremor":0.028,"fry":0.05},
}

## How each sound family carries its voice: melody "stress" (a stressed
## syllable, at stress initial/penult/final), "tone" (each syllable its own
## contour), "register" (high and low syllables, stepping down), "accent" (a
## high then a drop in each word), "phrase" (a rise at a phrase's end);
## range (pitch movement), asp (breath after p t k), ejective (how often a
## voiceless stop is popped), devoice (high vowels whispered between voiceless
## sounds), unasp (b d g said as plain voiceless stops).
const PROSODY:={
	"west_african":{"melody":"register","range":1.1,"asp":0.25},
	"bantu":{"melody":"register","range":1.0,"asp":0.2,"stress":"penult"},
	"ethiopic":{"melody":"stress","stress":"final","asp":0.3,"ejective":0.18},
	"polynesian":{"melody":"stress","stress":"penult","range":1.15,"asp":0.15},
	"austronesian":{"melody":"stress","stress":"penult","asp":0.15},
	"turkic":{"melody":"stress","stress":"final","asp":0.45},
	"mongolic":{"melody":"stress","stress":"initial","range":0.9,"asp":0.5},
	"sinitic":{"melody":"tone","range":1.3,"asp":0.75,"unasp":true},
	"japonic":{"melody":"accent","range":1.0,"asp":0.3,"devoice":true},
	"koreanic":{"melody":"phrase","range":0.95,"asp":0.55,"unasp":true},
	"tai_khmer":{"melody":"tone","range":1.2,"asp":0.6},
	"nahuatl":{"melody":"stress","stress":"penult","asp":0.2},
	"mayan":{"melody":"stress","stress":"final","asp":0.25,"ejective":0.22},
	"andean":{"melody":"stress","stress":"penult","asp":0.3,"ejective":0.08},
	"semitic":{"melody":"stress","stress":"penult","asp":0.35},
	"iranic":{"melody":"stress","stress":"final","asp":0.45},
	"indo_aryan":{"melody":"stress","stress":"penult","asp":0.6},
	"dravidian":{"melody":"stress","stress":"initial","asp":0.3},
	"slavic":{"melody":"stress","stress":"penult","range":1.1,"asp":0.1},
	"germanic":{"melody":"stress","stress":"initial","asp":0.7},
	"romance":{"melody":"stress","stress":"penult","range":1.15,"asp":0.1},
	"celtic":{"melody":"stress","stress":"initial","range":1.2,"asp":0.5},
	"hellenic":{"melody":"stress","stress":"penult","asp":0.2},
	"finnic":{"melody":"stress","stress":"initial","range":0.8,"asp":0.15},
	"inuit":{"melody":"stress","stress":"final","range":0.9,"asp":0.35},
	"athabaskan":{"melody":"register","range":0.95,"asp":0.5,"ejective":0.14},
	"algonquian":{"melody":"stress","stress":"penult","asp":0.3},
	"kartvelian":{"melody":"stress","stress":"initial","asp":0.4,"ejective":0.26},
	"amazigh":{"melody":"stress","stress":"penult","asp":0.35},
	"aboriginal":{"melody":"stress","stress":"initial","range":1.1,"asp":0.05},
}

## Vowels: F1, F2, F3 (Hz) of a grown man's throat. The mouth-shape class the
## acting layer uses for each (0 open "a", 1 wide "e i", 2 round "o u").
const VOWELS:={
	"a":[740.0,1230.0,2500.0],"e":[480.0,1850.0,2550.0],"i":[290.0,2250.0,2950.0],"o":[470.0,860.0,2450.0],"u":[320.0,760.0,2250.0],
	"ae":[620.0,1700.0,2450.0],"eo":[560.0,1080.0,2450.0],"eu":[360.0,1400.0,2350.0],"y":[450.0,1450.0,2450.0],
}
const VOWEL_LETTERS:="aeiouy"
const MONO_PAIRS:={"koreanic":["eo","eu","ae","oo"]}

## The simple sounds every spelling becomes. kind: stop, fric, nasal, lat,
## tap, trill, glide, h; v: voiced; f/q: where the noise is (Hz) and how
## narrow; amp: how loud the noise; locus: F2 where the tongue starts; f1,f2,f3:
## formants of an approximant or a nasal's colour.
const PHONES:={
	"P":{"kind":"stop","v":0,"f":900.0,"q":0.7,"amp":0.7,"locus":800.0},
	"B":{"kind":"stop","v":1,"f":900.0,"q":0.7,"amp":0.55,"locus":800.0},
	"T":{"kind":"stop","v":0,"f":4200.0,"q":0.9,"amp":0.8,"locus":1750.0},
	"D":{"kind":"stop","v":1,"f":4000.0,"q":0.9,"amp":0.6,"locus":1700.0},
	"K":{"kind":"stop","v":0,"f":2100.0,"q":1.4,"amp":0.8,"locus":1900.0},
	"G":{"kind":"stop","v":1,"f":2000.0,"q":1.4,"amp":0.6,"locus":1850.0},
	"Q":{"kind":"stop","v":0,"f":1150.0,"q":1.4,"amp":0.8,"locus":1150.0},
	"GB":{"kind":"stop","v":1,"f":1000.0,"q":0.8,"amp":0.7,"locus":1000.0,"double":2000.0},
	"KP":{"kind":"stop","v":0,"f":1000.0,"q":0.8,"amp":0.8,"locus":1000.0,"double":2100.0},
	"F":{"kind":"fric","v":0,"f":4800.0,"q":0.45,"amp":0.22,"locus":900.0},
	"V":{"kind":"fric","v":1,"f":4600.0,"q":0.45,"amp":0.14,"locus":900.0},
	"TH":{"kind":"fric","v":0,"f":5200.0,"q":0.45,"amp":0.2,"locus":1500.0},
	"DH":{"kind":"fric","v":1,"f":5000.0,"q":0.45,"amp":0.12,"locus":1500.0},
	"S":{"kind":"fric","v":0,"f":6000.0,"q":1.6,"amp":0.42,"locus":1700.0},
	"Z":{"kind":"fric","v":1,"f":5800.0,"q":1.6,"amp":0.26,"locus":1700.0},
	"SH":{"kind":"fric","v":0,"f":3100.0,"q":1.5,"amp":0.46,"locus":1950.0},
	"ZH":{"kind":"fric","v":1,"f":3000.0,"q":1.5,"amp":0.28,"locus":1950.0},
	"X":{"kind":"fric","v":0,"f":1700.0,"q":1.3,"amp":0.34,"locus":1500.0},
	"GH":{"kind":"fric","v":1,"f":1600.0,"q":1.3,"amp":0.2,"locus":1500.0},
	"LH":{"kind":"fric","v":0,"f":3600.0,"q":0.8,"amp":0.34,"locus":1500.0},
	"H":{"kind":"h","v":0,"amp":0.55},
	"M":{"kind":"nasal","v":1,"locus":950.0,"f2":1000.0},
	"N":{"kind":"nasal","v":1,"locus":1650.0,"f2":1600.0},
	"NG":{"kind":"nasal","v":1,"locus":1950.0,"f2":2000.0},
	"NY":{"kind":"nasal","v":1,"locus":2200.0,"f2":2200.0},
	"L":{"kind":"lat","v":1,"f1":360.0,"f2":1150.0,"f3":2700.0},
	"LY":{"kind":"lat","v":1,"f1":300.0,"f2":2000.0,"f3":2800.0},
	"R":{"kind":"tap","v":1,"f1":420.0,"f2":1400.0,"f3":1900.0},
	"RR":{"kind":"trill","v":1,"f1":420.0,"f2":1400.0,"f3":1900.0},
	"RH":{"kind":"tap","v":0,"f1":420.0,"f2":1400.0,"f3":1900.0},
	"W":{"kind":"glide","v":1,"f1":300.0,"f2":700.0,"f3":2200.0},
	"Y":{"kind":"glide","v":1,"f1":280.0,"f2":2250.0,"f3":3000.0},
	"?":{"kind":"stop","v":0,"f":600.0,"q":0.5,"amp":0.05,"locus":1500.0},
}
## Spellings to sounds, longest first. A family may say a spelling its own way.
const SPELL:={
	"tch":["T","SH"],"ngg":["NG","G"],"sh":["SH"],"ch":["T","SH"],"kh":["X"],"th":["TH"],"ph":["F"],"gh":["GH"],"zh":["ZH"],
	"ng":["NG"],"ny":["NY"],"ts":["T","S"],"tz":["T","S"],"dz":["D","Z"],"tl":["T","LH"],"ll":["L"],"rr":["RR"],"kw":["K","W"],
	"gw":["G","W"],"bh":["B","H"],"dh":["DH"],"gb":["GB"],"kp":["KP"],"qh":["Q","H"],"mb":["M","B"],"nd":["N","D"],"nj":["N","D","ZH"],
	"nz":["N","Z"],"mw":["M","W"],"rh":["RH"],"nk":["NG","K"],"nt":["N","T"],"mp":["M","P"],"ly":["LY"],"rl":["R","L"],"rn":["R","N"],
	"dd":["DH"],"ff":["F"],
	"p":["P"],"b":["B"],"t":["T"],"d":["D"],"k":["K"],"g":["G"],"q":["Q"],"c":["K"],"f":["F"],"v":["V"],"s":["S"],"z":["Z"],"h":["H"],
	"m":["M"],"n":["N"],"l":["L"],"r":["R"],"w":["W"],"y":["Y"],"j":["D","ZH"],"x":["X"],
}
const SPELL_KEYS:=["tch","ngg","sh","ch","kh","th","ph","gh","zh","ng","ny","ts","tz","dz","tl","ll","rr","kw","gw","bh","dh","gb","kp","qh",
	"mb","nd","nj","nz","mw","rh","nk","nt","mp","ly","rl","rn","dd","ff"]
const FAMILY_SPELL:={
	"sinitic":{"x":["SH"],"q":["T","SH"],"j":["D","ZH"],"zh":["D","ZH"],"z":["T","S"],"c":["T","S"],"r":["ZH"]},
	"tai_khmer":{"ph":["P","H"],"th":["T","H"],"kh":["K","H"]},
	"indo_aryan":{"ph":["P","H"],"th":["T","H"],"kh":["K","H"],"dh":["D","H"],"gh":["G","H"]},
	"dravidian":{"th":["T","H"]},
	"nahuatl":{"x":["SH"]},"mayan":{"x":["SH"]},
	"celtic":{"ll":["LH"],"ch":["X"],"dd":["DH"]},
	"andean":{"ll":["LY"]},"romance":{"ll":["L"],"c":["K"]},
	"finnic":{"j":["Y"]},"germanic":{"j":["Y"]},"slavic":{"j":["Y"]},
	"hellenic":{"ph":["F"],"kh":["X"]},
}

const MOODS:=["joy","fear","anger","scorn","awe","tired"]
## The stage's mood words (court_figure_3d.gd MOODS) as feelings.
const MOOD_WORDS:={"warm":{"joy":0.6},"afraid":{"fear":0.8},"defiant":{"anger":0.5,"scorn":0.3},"grieved":{"tired":0.6,"fear":0.2},
	"neutral":{},"proud":{"scorn":0.7},"haughty":{"scorn":0.75},"angry":{"anger":0.8},"awed":{"awe":0.7},"tired":{"tired":0.7},
	"dread":{"fear":0.9},"reverence":{"awe":0.6,"joy":0.2},"defy":{"anger":0.5,"scorn":0.4},"endure":{"tired":0.4},"glad":{"joy":0.7},"joy":{"joy":0.7}}

# =============================================================================
# Who speaks: a voice for life
# =============================================================================

## A voice for a person, kept for life: their register (age and sex), their
## own pitch and throat within it, their gravel if they lead in war, and their
## people's sounds. person: a game person ({name, person_id, sex, age,
## office_title}); owner: whose people ("player", "civ_07"); world_seed;
## extra: {kind (elder, child, door_guard, guard, envoy...), temper, variant
## (the figure's body: male_adult, female_old...)}.
## Reads the people's tongue (people_language.gd): call on the main thread.
static func spec(person:Dictionary,owner:String,world_seed:int,extra:Dictionary={})->Dictionary:
	if owner.is_empty():owner="player"
	var identity:="%s|%d|%s" % [owner,int(person.get("person_id",0)),String(person.get("name",extra.get("name","someone")))]
	var h:=Synth.seed_of(identity+"|voice")
	var sex:=String(person.get("sex",extra.get("sex","")))
	var variant:=String(extra.get("variant",""))
	if not sex in ["male","female"] and variant.contains("_"):sex=variant.get_slice("_",0)
	if not sex in ["male","female"]:sex="female" if (h>>3)%2==1 else "male"
	var years:=_years(person.get("age",extra.get("age",null)),variant,h)
	var kind:=String(extra.get("kind",""))
	if kind=="child" and years>=14:years=9
	var reg:="man"
	if years<13:reg="girl" if sex=="female" else "boy"
	elif years<20:reg="youth_f" if sex=="female" else "youth_m"
	elif years>=56:reg="old_woman" if sex=="female" else "old_man"
	else:reg="woman" if sex=="female" else "man"
	var v:Dictionary=(REGISTERS[reg] as Dictionary).duplicate()
	# Each person's own within the register.
	v["f0"]=float(v.f0)*(0.9+float(h%1000)/1000.0*0.2)
	v["fs"]=float(v.fs)*(0.965+float((h>>10)%1000)/1000.0*0.07)
	v["breath"]=float(v.breath)*(0.75+float((h>>20)%1000)/1000.0*0.6)
	v["tilt"]=float(v.tilt)*(0.88+float((h>>30)%1000)/1000.0*0.24)
	v["nasal"]=float((h>>40)%1000)/1000.0*0.14
	# The very old crackle more.
	if years>=72:
		v["fry"]=float(v.fry)+0.05;v["jitter"]=float(v.jitter)*1.3;v["tremor"]=float(v.tremor)*1.3
	# A fighter's gravel: a war leader, a guard, a spear-carrier.
	var office:=String(person.get("office_title",person.get("title",extra.get("office","")))).to_lower()
	var gravel:=0.0
	for word in ["war","spear","host","guard","shield","hunt","fight","captain","champion","warrior"]:
		if office.contains(word):gravel=0.55;break
	if kind in ["guard","door_guard"]:gravel=maxf(gravel,0.4)
	if gravel>0.0 and sex=="male" and reg in ["man","old_man"]:
		v["gravel"]=gravel;v["f0"]=float(v.f0)*0.9;v["fry"]=float(v.fry)+0.04;v["oq"]=float(v.oq)-0.05
	else:v["gravel"]=0.0
	v["register"]=reg
	v["owner"]=owner
	v["seed"]=h
	v["temper"]=String(extra.get("temper",""))
	var tongue:=phonology(owner,world_seed)
	v["tongue"]=tongue
	return v

static func _years(raw:Variant,variant:String,h:int)->int:
	if raw is int or raw is float:return int(raw)
	match String(raw if raw!=null else "").to_lower():
		"child":return 9
		"young","youth":return 18
		"old","oldest","elder","aged":return 66
		"adult","grown":return 35
	if variant.ends_with("_old"):return 64
	if variant.ends_with("_young"):return 19
	return 24+(h>>17)%30

## The sounds of a people's tongue, as the voice uses them: {family, on, mid,
## v, dip, pd, cod, pc, fin, pf, fix, prosody}. From people_language.gd's
## profile of that people (its family's sounds, kept or dropped as that people
## does); the family alone when the profile cannot be made.
static func phonology(owner:String,world_seed:int)->Dictionary:
	var p:Dictionary={}
	var language:GDScript=load("res://scripts/people_language.gd") if ResourceLoader.exists("res://scripts/people_language.gd") else null
	if language!=null:
		p=language.call("profile",owner,world_seed)
	return phonology_of(p)

## The voice's view of a tongue profile (people_language.gd profile() or _base()).
static func phonology_of(p:Dictionary)->Dictionary:
	var family:=String(p.get("family","west_african"))
	var out:={"family":family}
	for k in ["on","mid","v","dip","cod","fin"]:
		var list:Array=[]
		for x in p.get(k,[]):list.append(String(x))
		out[k]=list
	if (out.v as Array).is_empty():out.v=["a","e","i","o","u"]
	if (out.on as Array).is_empty():out.on=["k","t","m","n","s","l",""]
	if (out.mid as Array).is_empty():out.mid=(out.on as Array).duplicate()
	for k in ["pd","pc","pf"]:out[k]=float(p.get(k,0.0))
	out["fix"]=(p.get("fix",{}) as Dictionary).duplicate() if p.get("fix") is Dictionary else {}
	out["prosody"]=(PROSODY.get(family,{"melody":"stress","stress":"penult"}) as Dictionary).duplicate()
	out["spell"]=FAMILY_SPELL.get(family,{})
	out["mono"]=MONO_PAIRS.get(family,[])
	return out

## A feeling for a mood: a stage mood word ("afraid", "warm", "defiant",
## "grieved", "proud"...), or the acting layer's vector {joy, fear, anger,
## scorn, awe, tired}.
static func feeling(mood:Variant)->Dictionary:
	var out:={}
	for m in MOODS:out[m]=0.0
	if mood is Dictionary:
		for m in MOODS:out[m]=clampf(float((mood as Dictionary).get(m,0.0)),0.0,1.0)
	elif mood is String or mood is StringName:
		var words:Dictionary=MOOD_WORDS.get(String(mood),{})
		for m in words:out[m]=float(words[m])
	return out

# =============================================================================
# When: the mouth's own timing (mirrors court_acting.gd talk())
# =============================================================================

## Where the mouth opens for each syllable of the text over `seconds`, exactly
## as the acting layer times it: [{t, len, shape, word, first, last, stress,
## tail}], shape 0 open, 1 wide, 2 round, 3 lips closed (m b p), 4 lip on
## teeth (f v); tail the punctuation after the word ("." "?" "!" "," or "").
static func schedule(text:String,seconds:float)->Array:
	var units:=0.0
	var items:Array=[]
	var index:=0
	for raw in text.replace("\n"," ").split(" ",false):
		var word:=raw.strip_edges()
		var tail:=""
		while not word.is_empty() and ",.;:!?-–—\"')".contains(word[word.length()-1]):
			tail=word[word.length()-1]+tail;word=word.substr(0,word.length()-1)
		word=word.lstrip("\"'(")
		if word.is_empty():continue
		if units>0.0:units+=0.3
		var first:=word[0]
		var stressed:=word.length()>=6 or (index>0 and first==first.to_upper() and first!=first.to_lower()) or tail.contains("!")
		var shapes:=mouth_syllables(word)
		for s in shapes.size():
			items.append({"u":units,"shape":shapes[s],"word":index,"first":s==0,"last":s==shapes.size()-1,"stress":stressed,"tail":"","n_in_word":shapes.size(),"pos":s})
			units+=1.0
		var mark:=""
		if tail.contains("?"):mark="?"
		elif tail.contains("!"):mark="!"
		elif tail.contains("."):mark="."
		elif not tail.is_empty() and not tail.contains("'") and not tail.contains(")") and not tail.contains("\""):mark=","
		if not items.is_empty():(items[items.size()-1] as Dictionary)["tail"]=mark
		if tail.contains(".") or tail.contains("!") or tail.contains("?"):units+=2.4
		elif not tail.is_empty() and not tail.contains("'") and not tail.contains(")") and not tail.contains("\""):units+=1.4
		index+=1
	if units<=0.0 or seconds<=0.05:return []
	var per:=seconds*0.92/units
	for item:Dictionary in items:
		item["t"]=float(item.u)*per;item["len"]=per*0.95
	return items

## The acting layer's syllables of a word as mouth shapes (court_acting.gd
## _syllables, kept identical so voice and mouth agree).
static func mouth_syllables(word:String)->PackedInt32Array:
	var out:=PackedInt32Array()
	var w:=word.to_lower()
	var in_vowel:=false
	var first:=w[0] if not w.is_empty() else ""
	if first in ["m","b","p"]:out.append(3)
	elif first in ["f","v"]:out.append(4)
	for i in w.length():
		var c:=w[i]
		var v:=c in ["a","e","i","o","u","y"]
		if v and not in_vowel:
			out.append(0 if c=="a" else (1 if c in ["e","i","y"] else 2))
		in_vowel=v
	var n:=w.length()
	if n>3 and out.size()>1:
		if w.ends_with("e") and not w.ends_with("le"):out.remove_at(out.size()-1)
		elif w.ends_with("es") and not "sxzh".contains(w[n-3]):out.remove_at(out.size()-1)
		elif w.ends_with("ed") and not "td".contains(w[n-3]):out.remove_at(out.size()-1)
	if out.is_empty():out.append(0)
	return out

# =============================================================================
# What: syllables of the people's tongue for each opening of the mouth
# =============================================================================

## The babble's syllables for a line: one plan per mouth opening, each
## {t, len, onset:[phones], vowel:[vowel keys], coda:[phones], shape, stress,
## accent, tail, first, last, hold (lips-closed units are the next onset)}.
static func plan(voice:Dictionary,text:String,seconds:float)->Array:
	var tongue:Dictionary=voice.get("tongue",phonology_of({}))
	var items:=schedule(text,seconds)
	var rng:=RandomNumberGenerator.new()
	rng.seed=Synth.seed_of("%d|%s|%.2f" % [int(voice.get("seed",0)),text,seconds])
	var out:Array=[]
	var carry:Array=[]
	for i in items.size():
		var it:Dictionary=items[i]
		var shape:=int(it.shape)
		var p:={"t":float(it.t),"len":float(it.len),"shape":shape,"stress":bool(it.stress),"tail":String(it.tail),"first":bool(it.first),"last":bool(it.last),
			"word":int(it.word),"pos":int(it.pos),"n_in_word":int(it.n_in_word),"onset":[],"vowel":[],"coda":[],"hold":false}
		if shape>=3:
			# Lips closed (m b p) or lip on teeth (f v): this opening is the
			# next syllable's onset, held while the mouth is shut.
			p.hold=true
			p.onset=_labial(tongue,rng,shape==4)
			out.append(p)
			carry=p.onset
			continue
		var cv:=_syllable(tongue,rng,bool(it.first) and carry.is_empty(),bool(it.last),shape)
		if not carry.is_empty():cv.onset=[]
		p.onset=cv.onset;p.vowel=cv.vowel;p.coda=cv.coda
		carry=[]
		out.append(p)
	return out

static func _pick(list:Array,rng:RandomNumberGenerator)->String:
	return String(list[rng.randi_range(0,list.size()-1)]) if not list.is_empty() else ""

## The people's own sounds for a lips-closed opening (m, b, p, mb...) or a
## lip-on-teeth one (f, v, ph...), else the nearest they have.
static func _labial(tongue:Dictionary,rng:RandomNumberGenerator,teeth:bool)->Array:
	var pool:Array=[]
	for x in (tongue.on as Array)+(tongue.mid as Array):
		var s:=String(x)
		if s.is_empty():continue
		if teeth and (s.begins_with("f") or s.begins_with("v") or s=="ph"):pool.append(s)
		elif not teeth and (s.begins_with("m") or s.begins_with("b") or s.begins_with("p")):pool.append(s)
	if pool.is_empty():pool=["w","h"] if teeth else ["m"]
	return spell(_pick(pool,rng),tongue)

## One syllable of the tongue whose vowel makes the mouth's shape: {onset,
## vowel, coda}, each a list of sounds.
static func _syllable(tongue:Dictionary,rng:RandomNumberGenerator,initial:bool,last:bool,shape:int)->Dictionary:
	var onset:=_pick(tongue.on if initial else tongue.mid,rng)
	# The vowel: the tongue's own, of the mouth's shape; a vowel pair now and then.
	var pool:Array=[]
	var source:Array=tongue.v
	if not (tongue.dip as Array).is_empty() and rng.randf()<float(tongue.pd)*1.5:source=tongue.dip
	for x in source:
		if _shape_of(String(x))==shape:pool.append(String(x))
	if pool.is_empty():
		for x in tongue.v:
			if _shape_of(String(x))==shape:pool.append(String(x))
	if pool.is_empty():pool=["a"] if shape==0 else (["e","i"] if shape==1 else ["o","u"])
	var nucleus:=_pick(pool,rng)
	var cv:=onset+nucleus
	var fix:Dictionary=tongue.fix
	if fix.has(cv):cv=String(fix[cv])
	var coda:=""
	if last and not (tongue.fin as Array).is_empty() and rng.randf()<float(tongue.pf):coda=_pick(tongue.fin,rng)
	elif not last and not (tongue.cod as Array).is_empty() and rng.randf()<float(tongue.pc):coda=_pick(tongue.cod,rng)
	# Split the spelling into onset, vowels and coda again (a fix or a
	# syllabic vowel like "ang" moves letters across).
	var whole:=cv+coda
	var lead:="";var mid:="";var tail:=""
	var i:=0
	while i<whole.length() and not VOWEL_LETTERS.contains(whole[i]):lead+=whole[i];i+=1
	while i<whole.length() and VOWEL_LETTERS.contains(whole[i]):mid+=whole[i];i+=1
	tail=whole.substr(i)
	# A "y" between vowels or first is a consonant.
	if mid.begins_with("y") and mid.length()>1:lead+="y";mid=mid.substr(1)
	return {"onset":spell(lead,tongue),"vowel":vowels(mid,tongue),"coda":spell(tail,tongue)}

static func _shape_of(spelling:String)->int:
	for i in spelling.length():
		var c:=spelling[i]
		if VOWEL_LETTERS.contains(c):return 0 if c=="a" else (1 if c in ["e","i","y"] else 2)
	return 0

## A spelling of consonants as sounds ("tch" -> T SH; the family's own way first).
static func spell(text:String,tongue:Dictionary)->Array:
	var out:Array=[]
	var own:Dictionary=tongue.get("spell",{})
	var i:=0
	var s:=text.to_lower()
	while i<s.length():
		var took:=false
		for key in own:
			var k:=String(key)
			if s.substr(i,k.length())==k and k.length()>1:
				out.append_array(own[k]);i+=k.length();took=true;break
		if took:continue
		for k:String in SPELL_KEYS:
			if s.substr(i,k.length())==k:
				out.append_array(own.get(k,SPELL[k]));i+=k.length();took=true;break
		if took:continue
		var c:=s[i]
		# a doubled consonant is held longer
		if i+1<s.length() and s[i+1]==c and SPELL.has(c):
			out.append_array(own.get(c,SPELL[c]));out.append(":");i+=2;continue
		if own.has(c):out.append_array(own[c])
		elif SPELL.has(c):out.append_array(SPELL[c])
		i+=1
	return out

## Vowel letters as vowel keys: a monophthong spelt with two letters stays
## one ("eo" in a Koreanic tongue); a long vowel is marked; others glide.
static func vowels(text:String,tongue:Dictionary)->Array:
	var out:Array=[]
	var mono:Array=tongue.get("mono",[])
	var i:=0
	while i<text.length():
		var two:=text.substr(i,2)
		if two.length()==2 and two in mono:
			out.append("u" if two=="oo" else two);i+=2;continue
		var c:=text[i]
		if i+1<text.length() and text[i+1]==c:
			out.append(c);out.append(":");i+=2;continue
		out.append(c);i+=1
	if out.is_empty():out.append("a")
	return out

# =============================================================================
# How it sounds: painting the score and voicing it
# =============================================================================

## A line in this voice: the babble for `text` over `seconds`, in `mood`,
## whispered when `whisper` (a mutter). 22050 Hz mono, about -4 dBFS at its
## loudest; a quarter second of tail. Pure: any thread.
static func render(voice:Dictionary,text:String,seconds:float,mood:Variant="neutral",whisper:=false)->AudioStreamWAV:
	return Synth.to_stream(render_samples(voice,text,seconds,mood,whisper),0.62)

static func render_samples(voice:Dictionary,text:String,seconds:float,mood:Variant="neutral",whisper:=false)->PackedFloat32Array:
	var syllables:=plan(voice,text,seconds)
	var feel:=feeling(mood)
	var sc:=Score.new(seconds+0.3,float(voice.get("f0",120.0)))
	paint_line(sc,voice,syllables,feel,whisper)
	return voice_score(sc,voice,feel,Synth.seed_of("%d|%s|line" % [int(voice.get("seed",0)),text]))

## A voice's tracks a frame at a time: formants, voicing, breath, noise and
## its band, nasality and pitch.
class Score:
	var n:=0
	var f1:=PackedFloat32Array()
	var f2:=PackedFloat32Array()
	var f3:=PackedFloat32Array()
	var av:=PackedFloat32Array()
	var ah:=PackedFloat32Array()
	var af:=PackedFloat32Array()
	var ff:=PackedFloat32Array()
	var fq:=PackedFloat32Array()
	var nas:=PackedFloat32Array()
	var f0:=PackedFloat32Array()
	## Pitch multipliers painted after smoothing (a voice crack jumps).
	var jump:=PackedFloat32Array()
	func _init(seconds:float,f0_base:float)->void:
		n=maxi(2,int(ceil(seconds*RATE/FRAME)))
		f1.resize(n);f2.resize(n);f3.resize(n);av.resize(n);ah.resize(n);af.resize(n)
		ff.resize(n);fq.resize(n);nas.resize(n);f0.resize(n);jump.resize(n)
		f1.fill(500.0);f2.fill(1500.0);f3.fill(2500.0);ff.fill(4000.0);fq.fill(1.0);f0.fill(f0_base);jump.fill(1.0)
	func at(t:float)->int:
		return clampi(int(t*RATE/FRAME),0,n)
	func put(track:PackedFloat32Array,t0:float,t1:float,v:float)->void:
		for i in range(at(t0),at(t1)):track[i]=v
	func ramp(track:PackedFloat32Array,t0:float,t1:float,v0:float,v1:float)->void:
		var a:=at(t0);var b:=at(t1)
		for i in range(a,b):track[i]=lerpf(v0,v1,float(i-a)/maxf(1.0,float(b-a)))
	func smooth(track:PackedFloat32Array,tau:float)->void:
		var k:=1.0-exp(-float(FRAME)/(RATE*maxf(tau,0.0005)))
		var y:=track[0]
		for i in n:
			y+=k*(track[i]-y);track[i]=y
	## Smoothed forward and back: no lag, no overshoot.
	func smooth2(track:PackedFloat32Array,tau:float)->void:
		smooth(track,tau)
		var k:=1.0-exp(-float(FRAME)/(RATE*maxf(tau,0.0005)))
		var y:=track[n-1]
		for i in range(n-1,-1,-1):
			y+=k*(track[i]-y);track[i]=y

## Paints a line's syllables onto the score: where each sound sits in its
## syllable, the formants it aims for, the voicing and noise, and the melody.
static func paint_line(sc:Score,voice:Dictionary,syllables:Array,feel:Dictionary,whisper:bool)->void:
	var tongue:Dictionary=voice.get("tongue",phonology_of({}))
	var pros:Dictionary=tongue.get("prosody",{})
	var base:=float(voice.get("f0",120.0))
	var fear:=float(feel.fear);var joy:=float(feel.joy);var anger:=float(feel.anger);var scorn:=float(feel.scorn);var awe:=float(feel.awe);var tired:=float(feel.tired)
	if String(voice.get("temper",""))=="haughty":scorn=maxf(scorn,0.45)
	var pitch:=1.0+0.2*fear+0.07*joy+0.05*anger-0.09*scorn-0.06*tired-0.03*awe
	var range_k:=float(voice.get("range",1.0))*float(pros.get("range",1.0))*clampf(1.0+0.35*fear+0.3*joy+0.1*anger-0.4*scorn-0.3*tired,0.4,1.8)
	# How much of each syllable's slot is voiced: fear clips them short, pride
	# and weariness draw them out.
	var artic:=clampf(0.9-0.3*fear+0.12*scorn+0.1*tired+0.06*awe,0.5,1.0)
	var loud:=clampf(1.0+0.25*anger-0.12*fear-0.12*tired,0.6,1.4)
	var asp:=float(pros.get("asp",0.3))
	var eject:=float(pros.get("ejective",0.0))
	var melody:=String(pros.get("melody","stress"))
	var stress_at:=String(pros.get("stress","penult"))
	var fs:=float(voice.get("fs",1.0))
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(voice.get("seed",0))^0x5f3759df
	var crack_at:=-1
	if fear>0.45 and syllables.size()>=4:
		# One syllable cracks: the one nearest two-thirds through.
		crack_at=int(syllables.size()*0.62)
	var word_tone:=1.0
	var last_end:=0.0
	var tone_step:=1.0
	# Each sentence's span, for the fall across it.
	var spans:Array=[]
	var start_i:=0
	for i in syllables.size():
		var tail:=String((syllables[i] as Dictionary).tail)
		if tail in [".","?","!"] or i==syllables.size()-1:
			spans.append([start_i,i]);start_i=i+1
	for span in spans:
		var a:=int(span[0]);var b:=int(span[1])
		var t_a:=float((syllables[a] as Dictionary).t)
		var t_b:=float((syllables[b] as Dictionary).t)+float((syllables[b] as Dictionary).len)
		var final_mark:=String((syllables[b] as Dictionary).tail)
		tone_step=1.0
		for i in range(a,b+1):
			var syl:Dictionary=syllables[i]
			var t0:=float(syl.t);var slot:=float(syl.len)
			# A breath before a phrase after a pause.
			if t0-last_end>0.28 and i>0:
				var bt:=t0-minf(0.16,(t0-last_end)*0.5)
				sc.put(sc.ah,bt,t0-0.02,0.05 if not whisper else 0.04)
				sc.put(sc.f1,bt,t0,620.0*fs);sc.put(sc.f2,bt,t0,1300.0*fs);sc.put(sc.f3,bt,t0,2500.0*fs)
			var progress:=clampf((t0-t_a)/maxf(0.05,t_b-t_a),0.0,1.0)
			# The melody of this syllable: [start, end] pitch multipliers.
			var m0:=1.0;var m1:=1.0
			var decl:=lerpf(1.05,0.93,progress)
			var accent:=false
			match melody:
				"tone":
					var tone:=rng.randi_range(0,4)
					var tones:=[[1.12,1.12],[0.94,1.18],[1.16,0.86],[1.0,0.9],[0.92,0.92]]
					m0=float(tones[tone][0]);m1=float(tones[tone][1])
				"register":
					var high:=rng.randf()<0.5
					if bool(syl.first):tone_step*=0.97
					m0=(1.1 if high else 0.93)*tone_step;m1=m0*(0.99 if high else 0.98)
				"accent":
					var drop_at:=rng.randi_range(0,maxi(0,int(syl.n_in_word)-1)) if bool(syl.first) else -1
					if bool(syl.first):word_tone=1.1
					m0=word_tone;m1=word_tone
					if int(syl.pos)==drop_at or int(syl.pos)>=1:word_tone=0.94
				"phrase":
					m0=1.0;m1=1.0
					if bool(syl.last) and String(syl.tail)!="":m0=1.0;m1=1.12
				_:
					var n_w:=int(syl.n_in_word);var pos:=int(syl.pos)
					var where:=0 if stress_at=="initial" else (n_w-1 if stress_at=="final" else maxi(0,n_w-2))
					if syl.hold:where=-99
					accent=pos==where
					if accent:m0=1.09;m1=1.13
					else:m0=0.98;m1=0.97
			if bool(syl.stress) and bool(syl.first):m0*=1.06;m1*=1.08
			if i==b:
				match final_mark:
					"?":m0*=1.02;m1*=1.32
					"!":m0*=1.18;m1*=0.98
					_:m1*=0.84
			elif String(syl.tail)==",":m1*=1.04
			var p0:=base*pitch*decl*(1.0+(m0-1.0)*range_k)
			var p1:=base*pitch*decl*(1.0+(m1-1.0)*range_k)
			if float(voice.get("gravel",0.0))>0.0 and i==b:p1*=0.88
			var end:=_paint_syllable(sc,voice,tongue,syl,t0,slot,artic,loud*(1.15 if (accent or bool(syl.stress)) else 1.0),asp,eject,p0,p1,whisper,rng,fs)
			last_end=end
			if i==crack_at:
				# The voice cracks up, briefly, on the vowel.
				var v0:=t0+slot*0.35;var v1:=t0+slot*0.35+minf(0.09,slot*0.55)
				for f in range(sc.at(v0),sc.at(v1)):sc.jump[f]=1.55
	# Smooth the tracks into one moving throat.
	sc.smooth2(sc.f1,0.012);sc.smooth2(sc.f2,0.016);sc.smooth2(sc.f3,0.02)
	sc.smooth2(sc.av,0.005);sc.smooth(sc.ah,0.004);sc.smooth(sc.af,0.0012)
	sc.smooth2(sc.f0,0.022);sc.smooth(sc.nas,0.008)

## One syllable on the score from t0 over its slot; returns where it ends.
static func _paint_syllable(sc:Score,voice:Dictionary,tongue:Dictionary,syl:Dictionary,t0:float,slot:float,artic:float,loud:float,asp:float,eject:float,
		p0:float,p1:float,whisper:bool,rng:RandomNumberGenerator,fs:float)->float:
	var onset:Array=syl.onset
	var vowel:Array=syl.vowel
	var coda:Array=syl.coda
	var pros:Dictionary=tongue.get("prosody",{})
	var voiced_slot:=slot*artic
	if bool(syl.hold):
		# Lips shut for this opening: hold its sound (a hum, a closure, a hiss).
		var hold:=minf(voiced_slot,0.11)
		var t:=t0+maxf(0.0,slot-hold)
		_paint_phones(sc,onset,t,hold,"",asp,eject,whisper,loud,rng,fs,p0)
		return t0+slot
	# The vowel's first target, for the consonant before it to lead into.
	var v_first:=String(vowel[0]) if not vowel.is_empty() else "a"
	var on_len:=0.0
	if not onset.is_empty():
		on_len=clampf(voiced_slot*0.32,0.022,0.07)*(1.0 if onset.size()==1 else 1.35)
	var coda_len:=0.0
	if not coda.is_empty():coda_len=clampf(voiced_slot*0.2,0.02,0.06)
	var v_len:=maxf(0.03,voiced_slot-on_len-coda_len)
	if not onset.is_empty():_paint_phones(sc,onset,t0,on_len,v_first,asp,eject,whisper,loud,rng,fs,p0)
	var vt:=t0+on_len
	# Devoiced high vowels between voiceless sounds (a Japonic habit).
	var devoice:=false
	if bool(pros.get("devoice",false)) and v_first in ["i","u"] and not onset.is_empty() and int((PHONES.get(String(onset[onset.size()-1]),{}) as Dictionary).get("v",1))==0:
		if coda.is_empty() and rng.randf()<0.5:devoice=true
	_paint_vowels(sc,vowel,vt,v_len,whisper or devoice,loud,fs)
	sc.ramp(sc.f0,vt,vt+v_len,p0,p1)
	if not coda.is_empty():
		_paint_phones(sc,coda,vt+v_len,coda_len,"",asp*0.3,0.0,whisper,loud,rng,fs,p1)
	elif artic>=0.85 and not whisper:
		# legato: the vowel trails off into the gap instead of stopping dead
		var gap_end:=minf(t0+slot,vt+v_len+0.05)
		sc.ramp(sc.av,vt+v_len,gap_end,loud*0.5,0.0)
	# The pitch carries through the consonants too.
	sc.put(sc.f0,t0,vt,p0)
	sc.put(sc.f0,vt+v_len,t0+slot,p1)
	return vt+v_len+coda_len

static func _vowel_formants(key:String,fs:float)->Array:
	var f:Array=VOWELS.get(key,VOWELS.y)
	return [float(f[0])*fs,float(f[1])*fs,float(f[2])*fs]

static func _paint_vowels(sc:Score,vowel:Array,t0:float,dur:float,whisper:bool,loud:float,fs:float)->void:
	var keys:Array=[]
	for x in vowel:
		if String(x)==":":
			if not keys.is_empty():keys.append(keys[keys.size()-1])
		else:keys.append(String(x))
	if keys.is_empty():keys=["a"]
	var step:=dur/float(keys.size())
	for i in keys.size():
		var f:=_vowel_formants(String(keys[i]),fs)
		var a:=t0+step*i;var b:=a+step
		sc.put(sc.f1,a,b,float(f[0]));sc.put(sc.f2,a,b,float(f[1]));sc.put(sc.f3,a,b,float(f[2]))
		if whisper:sc.put(sc.ah,a,b,0.42*loud)
		else:sc.put(sc.av,a,b,1.0*loud)
	# a soft end: the voice dies away into the next sound
	if not whisper:sc.ramp(sc.av,t0+dur*0.8,t0+dur,loud,loud*0.55)

## Consonants laid end to end over `dur` from t0, leading into vowel v_next.
static func _paint_phones(sc:Score,phones:Array,t0:float,dur:float,v_next:String,asp:float,eject:float,whisper:bool,loud:float,rng:RandomNumberGenerator,fs:float,pitch:float)->void:
	var list:Array=[]
	for x in phones:
		if String(x)==":":
			if not list.is_empty():list[list.size()-1]=[String(list[list.size()-1][0]),1.6]
		else:list.append([String(x),1.0])
	if list.is_empty():return
	var total:=0.0
	for item in list:total+=float(item[1])
	var t:=t0
	var nf:=_vowel_formants(v_next if v_next!="" else "y",fs)
	for idx in list.size():
		var key:=String(list[idx][0])
		var d:=dur*float(list[idx][1])/total
		var ph:Dictionary=PHONES.get(key,PHONES["?"])
		var voiced:=int(ph.get("v",0))==1 and not whisper
		var kind:=String(ph.kind)
		var locus:=float(ph.get("locus",1500.0))*fs
		match kind:
			"stop":
				# closure, then the burst, then breath (more for a people that aspirates)
				var close:=d*0.6;var rel:=d-close
				sc.put(sc.av,t,t+close,0.12*loud if voiced else 0.0)
				sc.put(sc.f1,t,t+d,240.0*fs);sc.put(sc.f2,t,t+d,locus)
				var popped:=not voiced and eject>0.0 and rng.randf()<eject
				var burst_len:=minf(0.012,rel*0.6)
				var amp:=float(ph.get("amp",0.6))*(1.6 if popped else 1.0)*loud
				sc.put(sc.af,t+close,t+close+burst_len,amp)
				sc.put(sc.ff,t+close,t+close+burst_len,float(ph.get("f",2000.0))*sqrt(fs));sc.put(sc.fq,t+close,t+close+burst_len,float(ph.get("q",1.0)))
				if ph.has("double"):
					sc.put(sc.af,t+close+burst_len,t+close+burst_len*1.6,amp*0.7)
					sc.put(sc.ff,t+close+burst_len,t+close+burst_len*1.6,float(ph.double)*sqrt(fs))
				if popped:
					# an ejective: a hard pop, a catch of silence, then the vowel
					sc.put(sc.av,t+close+burst_len,t+d,0.0)
				elif not voiced:
					var a_len:=minf(rel-burst_len,0.008+0.05*asp)
					sc.put(sc.ah,t+close+burst_len,t+close+burst_len+a_len,0.5*asp*loud)
					sc.put(sc.f1,t+close,t+d,float(nf[0])*0.7);sc.put(sc.f2,t+close,t+d,lerpf(locus,float(nf[1]),0.5));sc.put(sc.f3,t+close,t+d,float(nf[2]))
				else:
					sc.put(sc.av,t+close+burst_len,t+d,0.6*loud)
			"fric":
				sc.put(sc.af,t,t+d,float(ph.get("amp",0.3))*loud)
				sc.put(sc.ff,t,t+d,float(ph.get("f",4000.0))*sqrt(fs));sc.put(sc.fq,t,t+d,float(ph.get("q",1.0)))
				sc.put(sc.f2,t,t+d,locus);sc.put(sc.f1,t,t+d,300.0*fs)
				if voiced:sc.put(sc.av,t,t+d,0.35*loud)
				# the noise eases in and out
				sc.ramp(sc.af,t,t+d*0.25,0.0,float(ph.get("amp",0.3))*loud)
			"h":
				sc.put(sc.ah,t,t+d,float(ph.get("amp",0.5))*loud)
				sc.put(sc.f1,t,t+d,float(nf[0]));sc.put(sc.f2,t,t+d,float(nf[1]));sc.put(sc.f3,t,t+d,float(nf[2]))
			"nasal":
				if whisper:sc.put(sc.ah,t,t+d,0.15*loud)
				else:sc.put(sc.av,t,t+d,0.55*loud)
				sc.put(sc.nas,t,t+d,1.0)
				sc.put(sc.f1,t,t+d,260.0*fs);sc.put(sc.f2,t,t+d,float(ph.get("f2",1500.0))*fs);sc.put(sc.f3,t,t+d,2500.0*fs)
			"lat","glide":
				if whisper:sc.put(sc.ah,t,t+d,0.25*loud)
				else:sc.put(sc.av,t,t+d,(0.75 if kind=="lat" else 0.85)*loud)
				sc.put(sc.f1,t,t+d,float(ph.f1)*fs);sc.put(sc.f2,t,t+d,float(ph.f2)*fs);sc.put(sc.f3,t,t+d,float(ph.f3)*fs)
			"tap","trill":
				var taps:=1 if kind=="tap" else 3
				var seg:=d/float(taps*2)
				for k in taps:
					var a:=t+seg*2*k
					sc.put(sc.av,a,a+seg,(0.7 if voiced else 0.0)*loud)
					sc.put(sc.av,a+seg,a+seg*2,(0.25 if voiced else 0.0)*loud)
					if not voiced:sc.put(sc.ah,a,a+seg*2,0.3*loud)
				sc.put(sc.f1,t,t+d,float(ph.f1)*fs);sc.put(sc.f2,t,t+d,float(ph.f2)*fs);sc.put(sc.f3,t,t+d,float(ph.f3)*fs)
		sc.put(sc.f0,t,t+d,pitch)
		t+=d

## Voices a painted score: the glottis, breath, the throat's formants, the
## nose, and the noise of the tongue, sample by sample. Returns samples.
static func voice_score(sc:Score,voice:Dictionary,feel:Dictionary,seed_value:int)->PackedFloat32Array:
	var n:=sc.n*FRAME
	var out:=PackedFloat32Array();out.resize(n)
	var fs:=float(voice.get("fs",1.0))
	var fear:=float(feel.get("fear",0.0));var anger:=float(feel.get("anger",0.0));var tired:=float(feel.get("tired",0.0));var awe:=float(feel.get("awe",0.0))
	var oq:=clampf(float(voice.get("oq",0.6))-0.08*anger+0.05*tired,0.4,0.8)
	var tp:=oq*0.68;var tn:=oq*0.32
	var jitter:=float(voice.get("jitter",0.006))*(1.0+fear)
	var shimmer:=float(voice.get("shimmer",0.04))
	var tremor:=float(voice.get("tremor",0.0))
	var tremor_hz:=float(voice.get("tremor_hz",5.4))
	var fry:=float(voice.get("fry",0.0))
	var gravel:=float(voice.get("gravel",0.0))
	var breath:=clampf(float(voice.get("breath",0.06))+0.12*fear+0.15*tired+0.1*awe,0.0,0.6)
	var nasal_base:=float(voice.get("nasal",0.0))
	var trem_fear:=0.13*fear
	var tilt_a:=1.0-exp(-TAU*float(voice.get("tilt",2400.0))/RATE)
	var b1:=65.0;var b2:=95.0;var b3:=150.0
	var f4:=3500.0*fs;var k4:=Synth.reso(f4,280.0)
	var kn:=Synth.reso(270.0*fs,110.0)
	var lcg:=seed_value&0x7fffffff
	var ph:=0.0;var pj:=1.0;var sh:=1.0;var pulse:=0
	var y11:=0.0;var y12:=0.0;var y21:=0.0;var y22:=0.0;var y31:=0.0;var y32:=0.0;var y41:=0.0;var y42:=0.0
	var yn1:=0.0;var yn2:=0.0
	var ic1:=0.0;var ic2:=0.0
	var tilt_y:=0.0
	var dc:=0.0
	var lp:=0.0
	var t:=0.0
	var dt:=1.0/RATE
	var last:=sc.n-1
	for fi in sc.n:
		var nas:=clampf(sc.nas[fi]+nasal_base,0.0,1.0)
		var k1:=Synth.reso(lerpf(sc.f1[fi],270.0*fs,nas*0.6),b1+nas*90.0)
		var k2:=Synth.reso(sc.f2[fi],b2+nas*140.0)
		var k3:=Synth.reso(sc.f3[fi],b3+nas*120.0)
		var g:=tan(PI*clampf(sc.ff[fi],200.0,10400.0)/RATE)
		var kq:=1.0/maxf(sc.fq[fi],0.1)
		var a1:=1.0/(1.0+g*(g+kq));var a2:=g*a1;var a3:=g*a2
		var nx:=mini(fi+1,last)
		var av0:=sc.av[fi];var dav:=(sc.av[nx]-av0)/FRAME
		var ah0:=sc.ah[fi];var dah:=(sc.ah[nx]-ah0)/FRAME
		var af0:=sc.af[fi];var daf:=(sc.af[nx]-af0)/FRAME
		var f0a:=sc.f0[fi]*sc.jump[fi];var df0:=(sc.f0[nx]*sc.jump[nx]-f0a)/FRAME
		for s in FRAME:
			var av:=av0+dav*s;var ah:=ah0+dah*s;var af:=af0+daf*s
			var f0:=(f0a+df0*s)*(1.0+tremor*sin(TAU*tremor_hz*t))
			if trem_fear>0.0:av*=1.0+trem_fear*sin(TAU*7.5*t)
			ph+=f0*dt*pj
			if ph>=1.0:
				ph-=1.0;pulse+=1
				lcg=(lcg*1103515245+12345)&0x7fffffff
				pj=1.0+(float(lcg)/1073741823.5-1.0)*jitter
				lcg=(lcg*1103515245+12345)&0x7fffffff
				sh=1.0+(float(lcg)/1073741823.5-1.0)*shimmer
				if gravel>0.0 and pulse%2==1:sh*=1.0-gravel*0.45;pj*=1.0-gravel*0.06
				if fry>0.0:
					lcg=(lcg*1103515245+12345)&0x7fffffff
					if float(lcg)/2147483647.0<fry:pj*=0.5;sh*=0.6
			var glot:=0.0
			if ph<tp:glot=sin(PI*ph/tp)*(0.5*PI/tp)
			elif ph<tp+tn:glot=-sin(0.5*PI*(ph-tp)/tn)*(0.5*PI/tn)
			lcg=(lcg*1103515245+12345)&0x7fffffff
			var noise:=float(lcg)/1073741823.5-1.0
			var open:=1.0 if ph<tp+tn else 0.3
			var src:=glot*0.12*sh*av+noise*(ah+breath*av*open)*0.55
			tilt_y+=tilt_a*(src-tilt_y)
			var o:=k1.x*tilt_y+k1.y*y11+k1.z*y12;y12=y11;y11=o
			o=k2.x*o+k2.y*y21+k2.z*y22;y22=y21;y21=o
			o=k3.x*o+k3.y*y31+k3.z*y32;y32=y31;y31=o
			o=k4.x*o+k4.y*y41+k4.z*y42;y42=y41;y41=o
			if nas>0.01:
				var m:=kn.x*tilt_y+kn.y*yn1+kn.z*yn2;yn2=yn1;yn1=m
				o=lerpf(o,m*1.4,nas*0.55)
			# the tongue's noise
			lcg=(lcg*1103515245+12345)&0x7fffffff
			var fx:=(float(lcg)/1073741823.5-1.0)*af
			var v3:=fx-ic2
			var v1:=a1*ic1+a2*v3
			var v2:=ic2+a2*ic1+a3*v3
			ic1=2.0*v1-ic1;ic2=2.0*v2-ic2
			var y:=o+v1*kq*1.1
			# no rumble, a soft top
			dc+=0.0085*(y-dc)
			y-=dc
			lp+=0.8*(y-lp)
			out[fi*FRAME+s]=lp
			t+=dt
	Synth.fade_edges(out,0.003,0.03)
	return out

# =============================================================================
# Wordless sounds in a voice (court_foley.gd uses these: laughs, grunts, gasps)
# =============================================================================

## A vocal gesture in this voice, from a list of steps [seconds, vowel key or
## "" for the last, voicing 0..1, breath 0..1, pitch multiplier at the step's
## end, nasal 0..1]: a laugh is "h a" steps, a grunt one pressed short "y".
## Returns samples.
static func gesture(voice:Dictionary,steps:Array,seed_value:int,feel:Dictionary={})->PackedFloat32Array:
	var total:=0.05
	for step in steps:total+=float(step[0])
	var sc:=Score.new(total,float(voice.get("f0",120.0)))
	var fs:=float(voice.get("fs",1.0))
	var t:=0.0
	var pitch:=float(voice.get("f0",120.0))
	var key:="y"
	for step in steps:
		var d:=float(step[0])
		if String(step[1])!="":key=String(step[1])
		var f:=_vowel_formants(key,fs)
		sc.put(sc.f1,t,t+d,float(f[0]));sc.put(sc.f2,t,t+d,float(f[1]));sc.put(sc.f3,t,t+d,float(f[2]))
		sc.put(sc.av,t,t+d,float(step[2]));sc.put(sc.ah,t,t+d,float(step[3]))
		var p1:=float(voice.get("f0",120.0))*float(step[4])
		sc.ramp(sc.f0,t,t+d,pitch,p1);pitch=p1
		if step.size()>5:sc.put(sc.nas,t,t+d,float(step[5]))
		t+=d
	sc.put(sc.f0,t,float(total),pitch)
	sc.smooth2(sc.f1,0.01);sc.smooth2(sc.f2,0.014);sc.smooth2(sc.f3,0.018)
	sc.smooth(sc.av,0.006);sc.smooth(sc.ah,0.006);sc.smooth2(sc.f0,0.015);sc.smooth(sc.nas,0.008)
	var full:={"joy":0.0,"fear":0.0,"anger":0.0,"scorn":0.0,"awe":0.0,"tired":0.0}
	full.merge(feel,true)
	return voice_score(sc,voice,full,seed_value)

## A plain voice of a register with no people (wordless sounds of the room).
static func plain(register:String,seed_value:int=1)->Dictionary:
	var v:Dictionary=(REGISTERS.get(register,REGISTERS.man) as Dictionary).duplicate()
	v["gravel"]=0.0;v["nasal"]=0.0;v["seed"]=seed_value;v["register"]=register;v["temper"]=""
	v["f0"]=float(v.f0)*(0.92+float(seed_value%100)/100.0*0.16)
	v["tongue"]=phonology_of({})
	return v

## A stretch of babble in a voice with no line behind it (the crowd's murmur):
## phrases of a few syllables with pauses between, `seconds` long.
static func babble(voice:Dictionary,seconds:float,seed_value:int,whisper:=false,feel:Dictionary={})->PackedFloat32Array:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var words:PackedStringArray=PackedStringArray()
	var syl:=["ka","lo","me","ti","su","na","re","vo","ba","di"]
	var text:=""
	# Make a text whose timing gives natural phrases at about 5 syllables a second.
	var count:=int(seconds*4.2)
	for i in count:
		var w:=""
		for k in rng.randi_range(1,3):w+=String(syl[rng.randi_range(0,syl.size()-1)])
		if rng.randf()<0.18:w+="."
		elif rng.randf()<0.12:w+=","
		words.append(w)
	text=" ".join(words)
	var sc:=Score.new(seconds+0.3,float(voice.get("f0",120.0)))
	var full:={"joy":0.0,"fear":0.0,"anger":0.0,"scorn":0.0,"awe":0.0,"tired":0.0}
	full.merge(feel,true)
	var v:=voice.duplicate()
	v["seed"]=seed_value
	paint_line(sc,v,plan(v,text,seconds*0.95),full,whisper)
	return voice_score(sc,v,full,seed_value)
