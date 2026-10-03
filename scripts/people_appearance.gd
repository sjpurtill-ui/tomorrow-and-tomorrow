extends RefCounted
## HOW A PEOPLE LOOKS: the range of their skin, their hair and the dyes of
## their cloth, the same every time for a world.
##
## Every people is drawn from one of the thirteen painted populations of the
## first-age art (character_appearance.gd FAMILIES; the paintings themselves
## are assets/ui/early-paper/*-scenes-v1.png and the Stoneweft sheet, each
## made as "one invented human population, not a named real-world group").
## A people's look starts from the population its portraits show, so what the
## card says and what the paintings show never disagree, and moves a little
## within it: its own skin range, its own dyes. The world's peoples together
## span the human range of skin, from very pale to very deep brown.
##
## Portraits (hud/person_portrait.gd) use it twice:
## - in the first age every person is painted in their people's own set
##   (rulers, envoys, officials, generals, court people alike);
## - later, everyone shares one five-face painting (founding_leaders.png),
##   so each people is given the faces nearest its skin range first
##   (late_cells). Skin is never repainted: recolouring a painted face
##   without a mask reads as a filter laid over a person, not as who they are.
##
## The look is apart from a people's tongue (people_language.gd): neither
## says anything about the other, and neither changes any number of the game.
## Static helpers; preload. No simulation RNG is used.

const Appearance:=preload("res://scripts/character_appearance.gd")

const NO_SEED:=-9223372036854775807

## What each painted population looks like, from the paintings' own briefs:
## skin depth (0 the palest skin, 1 the deepest), hair colours and growth,
## and the plain words for it.
const LOOKS:={
	"kilnfold":{"depth":0.85,"hair":["1b1511","2b2018"],"hair_words":"coarse, loosely coiled dark hair","skin_words":"deep brown"},
	"reedwake":{"depth":0.50,"hair":["1a1512","2a211a"],"hair_words":"straight dark hair","skin_words":"weathered golden-brown"},
	"windseam":{"depth":0.30,"hair":["4a2a1a","5d3420"],"hair_words":"coarse dark reddish-brown hair","skin_words":"pale copper"},
	"stoneweft":{"depth":0.52,"hair":["1d1813","2c241c"],"hair_words":"dark, coarse hair","skin_words":"olive-brown"},
	"ashplain":{"depth":0.38,"hair":["8a6a48","a07e58"],"hair_words":"dense, loose pale-brown curls","skin_words":"freckled tawny"},
	"rillmark":{"depth":0.95,"hair":["0f0d0c","1c1816"],"hair_words":"straight, coarse black hair","skin_words":"very deep cool brown"},
	"flintmere":{"depth":0.56,"hair":["121010","221c18"],"hair_words":"wavy black hair","skin_words":"warm olive-brown"},
	"morrowfen":{"depth":0.44,"hair":["6a3320","7f3f25"],"hair_words":"tightly coiled dark copper hair","skin_words":"warm light brown, freckled"},
	"thornbank":{"depth":0.08,"hair":["0e1016","1a1c24"],"hair_words":"thick, straight blue-black hair","skin_words":"very pale, cool"},
	"sunhollow":{"depth":0.80,"hair":["a88c62","bfa57a"],"hair_words":"springy ash-blond curls","skin_words":"deep bronze-brown"},
	"greyfold":{"depth":0.46,"hair":["6b5a48","7d6a56"],"hair_words":"fine, straight ash-brown hair","skin_words":"copper-olive"},
	"ochrestep":{"depth":0.66,"hair":["c2a878","a88d5e"],"hair_words":"straight, pale sandy hair","skin_words":"russet-brown"},
	"hollowreed":{"depth":0.20,"hair":["15110e","231c16"],"hair_words":"tightly curled near-black hair","skin_words":"pale golden"},
}
## Human skin from the palest (0) to the deepest (1).
const SKIN_RAMP:=[[0.0,"f3dccb"],[0.15,"e8c3a5"],[0.30,"d6a37c"],[0.45,"bd8659"],[0.60,"9f6a43"],[0.75,"7d4e2f"],[0.90,"5b3622"],[1.0,"3f2519"]]
## Dyes a people may favour: [name, colour].
const DYES:=[["madder red","a8432f"],["kermes crimson","8e2f3a"],["weld yellow","c9a43c"],["saffron","d08a2b"],["indigo","2f4a6e"],["woad blue","5a7894"],
	["walnut brown","5b4130"],["oak-gall black","2e2a26"],["undyed cream","d9ccb0"],["lichen purple","6d4b6b"],["verdigris green","4f7a68"],["ochre","b07a35"],
	["iron grey","6f6c66"],["nettle green","5f8a5a"]]
## founding_leaders.png, the later five-face painting: each face's skin depth,
## read from the painting (median of the cheeks, cells left to right).
const LATE_CELLS:=[0.85,0.35,0.50,0.30,0.20]
## A face fits a people when it lies within this of their skin range.
const LATE_FIT:=0.15

static var _cache:Dictionary={}

## A people's look: {family, depth [lightest, deepest], skin [three colours,
## light to deep], hair [colours], hair_words, skin_words, cloth [three dye
## colours], dyes [their names], words: one plain sentence}.
static func profile(owner:String="player",seed_value:int=NO_SEED)->Dictionary:
	if seed_value==NO_SEED:seed_value=int(GameState.world_seed) if GameState!=null else 0
	if owner=="":owner="player"
	var family:=Appearance.family_for(seed_value,owner)
	var key:="%d|%s|%s" % [seed_value,owner,family]
	if _cache.has(key):return _cache[key]
	if _cache.size()>256:_cache.clear()
	var look:Dictionary=LOOKS.get(family,LOOKS.stoneweft)
	var rng:=RandomNumberGenerator.new();rng.seed=("%d:look:%s" % [seed_value,owner]).hash()
	var center:=clampf(float(look.depth)+rng.randf_range(-0.05,0.05),0.03,0.97)
	var low:=clampf(center-0.08,0.0,1.0);var high:=clampf(center+0.08,0.0,1.0)
	var dyes:Array=_dyes(seed_value,owner)
	var made:={"family":family,"depth":[low,high],"skin":[skin_at(low),skin_at(center),skin_at(high)],
		"hair":(look.hair as Array).duplicate(),"hair_words":String(look.hair_words),"skin_words":String(look.skin_words),
		"cloth":dyes.map(func(d:Array)->String:return String(d[1])),"dyes":dyes.map(func(d:Array)->String:return String(d[0]))}
	made["words"]="%s skin, %s; cloth dyed %s" % [_first_upper(String(look.skin_words)),String(look.hair_words),_and(made.dyes)]
	_cache[key]=made
	return made

## A skin colour (hex) at a depth, 0 the palest to 1 the deepest.
static func skin_at(depth:float)->String:
	var d:=clampf(depth,0.0,1.0)
	for i in range(1,SKIN_RAMP.size()):
		var a:Array=SKIN_RAMP[i-1];var b:Array=SKIN_RAMP[i]
		if d<=float(b[0]):
			var t:=(d-float(a[0]))/maxf(0.0001,float(b[0])-float(a[0]))
			return Color(String(a[1])).lerp(Color(String(b[1])),t).to_html(false)
	return String(SKIN_RAMP[-1][1])

## Three dyes for a people: every people of a world has its own three.
static func _dyes(seed_value:int,owner:String)->Array:
	var combos:Array=[]
	for a in DYES.size():
		for b in range(a+1,DYES.size()):
			for c in range(b+1,DYES.size()):combos.append([a,b,c])
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^0x6d1e5
	for i in range(combos.size()-1,0,-1):
		var j:=rng.randi_range(0,i);var held:Variant=combos[i];combos[i]=combos[j];combos[j]=held
	var slot:=0
	if owner!="player":
		var number:=owner.trim_prefix("civ_")
		slot=int(number) if owner.begins_with("civ_") and number.is_valid_int() else 40+posmod(owner.hash(),300)
	var chosen:Array=combos[posmod(slot,combos.size())]
	return chosen.map(func(i:int)->Array:return DYES[i])

static func _first_upper(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _and(words:Array)->String:
	if words.size()<=1:return "".join(PackedStringArray(words))
	return "%s and %s" % [", ".join(PackedStringArray(words.slice(0,words.size()-1))),String(words[-1])]

## The later painting's faces in the order they suit a people: those within
## its skin range first (nearest the middle first), then the rest by nearness.
static func late_cells(owner:String="player",seed_value:int=NO_SEED)->Array:
	var look:=profile(owner,seed_value)
	var low:=float(look.depth[0]);var high:=float(look.depth[1]);var middle:=(low+high)*0.5
	var order:Array=range(LATE_CELLS.size())
	order.sort_custom(func(a:int,b:int)->bool:
		var da:=_outside(float(LATE_CELLS[a]),low,high);var db:=_outside(float(LATE_CELLS[b]),low,high)
		if not is_equal_approx(da,db):return da<db
		return absf(float(LATE_CELLS[a])-middle)<absf(float(LATE_CELLS[b])-middle))
	return order

## The later faces that fit a people (at least the nearest one).
static func late_fitting(owner:String="player",seed_value:int=NO_SEED)->Array:
	var look:=profile(owner,seed_value)
	var ranked:=late_cells(owner,seed_value)
	var out:Array=[]
	for cell:int in ranked:
		if _outside(float(LATE_CELLS[cell]),float(look.depth[0]),float(look.depth[1]))<=LATE_FIT:out.append(cell)
	if out.is_empty():out.append(ranked[0])
	return out

static func _outside(value:float,low:float,high:float)->float:
	if value<low:return low-value
	if value>high:return value-high
	return 0.0
