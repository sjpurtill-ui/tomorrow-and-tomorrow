extends RefCounted
## Within one people, nobody alike (figures, J). CourtStage.figure_look reads
## a person's appearance from their people's profile (people_appearance.gd):
## the people's skin range, its two hair colours, its three dyes. A people
## shares those, but its members do not share one tone, one shape and one
## dress: this spreads each person within the people's look, kept for life
## (seeded by the person), so a hall of one people reads as many people.
##   - hair: the profile's colour, lighter or darker by the person and their
##     age (fair children darken as they grow; near-black hair runs from
##     blue-black to dark brown); greying hair stays grey, steel to white;
##   - skin: a little lighter or darker within the people's range;
##   - build and height: average, stocky, lanky, round or slight, and a few
##     centimetres either way (drawn as the model's scale; feet stay down);
##   - dress: the dyes fresher or worn and faded, each garment its own;
##   - stance: hands clasped at the waist is the court's polite default, so
##     most of those it falls to stand some other way of their own.
## A look may carry "seed" and "years" (the stage's accessor knows them);
## without them they are read from the person's own face and body.
## Presentation only: nothing here reads or changes the game's state.

const Self:=preload("res://scripts/hud/court_figure_look.gd")

const BUILDS:=["average","average","average","stocky","lanky","round","slight"]
## The model's scale for a build: (width, height, depth).
const BUILD_SCALE:={"average":Vector3(1.0,1.0,1.0),"stocky":Vector3(1.045,0.98,1.04),"lanky":Vector3(0.955,1.03,0.96),
	"round":Vector3(1.05,0.99,1.08),"slight":Vector3(0.955,0.985,0.95)}
## The stances taken instead of the polite clasp (each person keeps theirs).
const OWN_STANCES:=["hip","folded","hip","folded","stand","belt"]
## How often a person the clasp falls to keeps it.
const KEEP_CLASP:=0.25

## The person's own seed: the look's, else their face (the accessor makes
## each person's face from their identity).
static func seed_of(look:Dictionary)->int:
	if look.has("seed"):return absi(int(look.seed))
	var face:Dictionary=look.get("face",{})
	var keys:=face.keys();keys.sort()
	var text:=String(look.get("variant",""))+"|"+String(look.get("hair",""))
	for key in keys:text+="|%s=%.3f" % [key,float(face[key])]
	return absi(text.hash())

## About how old they are: the look's, else from their body and face.
static func years_of(look:Dictionary)->int:
	if look.has("years"):return int(look.years)
	var aged:=float((look.get("face",{}) as Dictionary).get("aged",0.0))
	if aged>0.0:return 46+int(aged*24.0)
	var band:=String(look.get("variant","")).get_slice("_",1)
	return 19 if band=="young" else (60 if band=="old" else 32)

## The look spread within the people (once: a varied look is kept as it is).
static func vary(look:Dictionary)->Dictionary:
	if bool(look.get("varied",false)):return look
	var out:=look.duplicate()
	out["varied"]=true
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_of(look)
	var years:=years_of(look)
	out["hair_colour"]=hair_for(Color(look.get("hair_colour",Color("2b2018"))),rng,years)
	out["skin"]=skin_for(Color(look.get("skin",Color("bd8659"))),rng)
	var cloth:Array=[]
	for c in look.get("cloth",[]):cloth.append(worn(Color(c),rng))
	if not cloth.is_empty():out["cloth"]=cloth
	if not look.has("build"):out["build"]=String(BUILDS[rng.randi()%BUILDS.size()])
	if not look.has("tall"):out["tall"]=rng.randf_range(0.955,1.045)
	# A child (the accessor gives their years): a child's body, no beard, the
	# hair of a child, and a child's way of standing about.
	if years<13:
		out["variant"]="child"
		out["beard"]=""
		if String(look.get("hair","")) in ["balding","shaved"]:out["hair"]="cropped"
		out["stance"]=String(["stand","hip","crouch","stand","sit"][absi(seed_of(look)>>3)%5])
		out["build"]="average" if String(out.get("build",""))=="round" else out.get("build","average")
	var stance:=String(out.get("stance",""))
	var roll:=rng.randf()
	var pick:=String(OWN_STANCES[rng.randi()%OWN_STANCES.size()])
	if stance=="clasped" and not bool(look.get("keep_stance",false)) and roll>=KEEP_CLASP:out["stance"]=pick
	return out

## Hair of the people's colour, the person's own shade of it.
static func hair_for(hair:Color,rng:RandomNumberGenerator,years:int)->Color:
	var h:=hair.h;var s:=hair.s;var v:=hair.v
	var t:=rng.randf()
	if years>=56 or (s<0.14 and v>0.38):
		# grey already: steel, pewter or white
		v=clampf(v*lerpf(0.80,1.10,t),0.0,0.92)
	elif v>0.40:
		# fair hair: children fairest; grown, it darkens toward a mid brown,
		# and it reads gold or honey, never ash-white
		var darken:=lerpf(0.88,1.06,t) if years<16 else lerpf(0.40,1.0,pow(t,0.8))
		v*=darken
		s=clampf(s*rng.randf_range(1.15,1.45),0.0,0.62)
		h=fposmod(h+rng.randf_range(-0.018,0.010),1.0)
	elif v<0.20:
		# near-black: blue-black, black, very dark brown
		v=clampf(v*lerpf(0.85,1.9,t),0.04,0.30)
		s=clampf(s*rng.randf_range(0.8,1.3),0.0,0.7)
		h=fposmod(h+rng.randf_range(-0.010,0.022),1.0)
	else:
		v*=lerpf(0.78,1.18,t)
		s=clampf(s*rng.randf_range(0.9,1.2),0.0,0.8)
	return Color.from_hsv(h,s,clampf(v,0.0,1.0))

## Skin a little lighter or darker, a little warmer or cooler.
static func skin_for(skin:Color,rng:RandomNumberGenerator)->Color:
	var shift:=rng.randf_range(-1.0,1.0)
	return Color.from_hsv(fposmod(skin.h+shift*0.010+rng.randf_range(-0.006,0.006),1.0),clampf(skin.s*rng.randf_range(0.92,1.08),0.0,1.0),clampf(skin.v*(1.0+shift*0.075),0.0,1.0))

## A garment's dye, fresher or worn and faded toward the undyed stuff.
static func worn(colour:Color,rng:RandomNumberGenerator)->Color:
	var faded:=colour.lerp(Color("8f8270"),rng.randf_range(0.0,0.24))
	return Color.from_hsv(faded.h,faded.s,clampf(faded.v*rng.randf_range(0.90,1.08),0.0,1.0))

## The model's scale for a look (build and height).
static func scale_of(look:Dictionary)->Vector3:
	var b:Vector3=BUILD_SCALE.get(String(look.get("build","average")),Vector3.ONE)
	var tall:=float(look.get("tall",1.0))
	return Vector3(b.x*tall,b.y*tall,b.z*tall)

## For the stage (it knows the room): a stance for this look so that at most
## one person standing in a room keeps the clasp. taken: the stances already
## in the room, {stance: count}; it is updated.
static func room_stance(look:Dictionary,taken:Dictionary)->String:
	var stance:=String(look.get("stance","stand"))
	if stance=="clasped" and int(taken.get("clasped",0))>=1 and not bool(look.get("keep_stance",false)):
		var rng:=RandomNumberGenerator.new();rng.seed=seed_of(look)+7
		var least:=""
		for pick in ["hip","folded","belt","stand"]:
			if least.is_empty() or int(taken.get(pick,0))<int(taken.get(least,0)):least=pick
		stance=least if rng.randf()<0.6 else String(OWN_STANCES[rng.randi()%OWN_STANCES.size()])
	taken[stance]=int(taken.get(stance,0))+1
	return stance
