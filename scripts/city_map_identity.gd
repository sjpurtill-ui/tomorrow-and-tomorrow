extends RefCounted
const IDENTITIES=preload("res://scripts/civilization_identity.gd")
static var cache:Dictionary={}
static var cache_seed:int=-9223372036854775807
static var player_crests:Dictionary={}
const CREST_FIELDS:=["74513c","596251","826b43","4b6265","755b56","5c6651","77684f","5b5969","6c6151","4d6762"]
## Every people's emblem comes from the one drawn-emblem engine
## (resource_icons.emblem_texture), so a people looks the same on its city
## cards, in the court, in reports and on the war chart. Strangers take an
## outline, a sign and a colour; two peoples who share a colour never share
## an outline. Our own people alone wear the round gold-banded seal with the
## home star, in the colour and sign chosen at the founding.
const ICONS=preload("res://scripts/resource_icons.gd")

static func player_crest(index:int)->Texture2D:
	var selected:=clampi(index,0,9)
	if player_crests.has(selected):return player_crests[selected]
	var field:=Color(String(CREST_FIELDS[selected])).lerp(ICONS.EMBLEM_INK,0.45)
	player_crests[selected]=ICONS.emblem_texture("seal",selected,field,ICONS.EMBLEM_GOLD,ICONS.EMBLEM_GOLD)
	return player_crests[selected]

## Anyone's emblem by id: ours for "player", else that people's.
static func emblem(civ_id:String)->Texture2D:
	if civ_id=="player":return player_crest(maxi(0,int(WorldSimulation.state.founding_banner_index)))
	return foreign(civ_id).texture

## The outline a stranger people's emblem takes. Roster entries i, i+12 and
## i+24 share a colour; their outlines are always different.
static func shape_for(civ_id:String)->String:
	if civ_id.is_empty():return "cushion"
	var i:=IDENTITIES.index_for(civ_id)
	var rng:=RandomNumberGenerator.new();rng.seed=int(WorldSimulation.state.world_seed)^0x51ed27
	var order:=IDENTITIES.shuffled(ICONS.EMBLEM_SHAPES.size(),rng)
	return String(ICONS.EMBLEM_SHAPES[order[(i+(i/12)*3)%ICONS.EMBLEM_SHAPES.size()]])

static func foreign(civ_id:String)->Dictionary:
	if cache_seed!=WorldSimulation.state.world_seed:cache.clear();cache_seed=WorldSimulation.state.world_seed
	if cache.has(civ_id):return cache[civ_id]
	var identity:Dictionary=IDENTITIES.identity(WorldSimulation.state.world_seed,civ_id).duplicate()
	if civ_id.is_empty():identity={"field":"7c8588","color":"bdc6c7","ink":"e7e4d4","pattern":0,"symbol":9}
	# Field a touch toward iron-gall so it sits in the chart's palette; the
	# band keeps the people's clear colour.
	var field:=Color(String(identity.field)).lerp(ICONS.EMBLEM_INK,0.12)
	var accent:=Color(String(identity.color))
	var shape:=shape_for(civ_id)
	var texture:=ICONS.emblem_texture(shape,int(identity.symbol),field,accent,Color(String(identity.ink)))
	if cache.size()>=128:cache.clear()
	cache[civ_id]={"color":accent.lerp(Color("e5d5b7"),0.45),"accent":accent,"field":field,"shape":shape,"symbol":int(identity.symbol),"texture":texture}
	return cache[civ_id]
static func banner_color(texture:Texture2D)->Color:
	if texture==null:return Color("e4c67a")
	var image:=texture.get_image()
	var sum:=Vector3.ZERO;var weight:=0.0
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			var c:=image.get_pixel(x,y)
			var w:=c.a*c.s*c.s*c.v
			sum+=Vector3(c.r,c.g,c.b)*w;weight+=w
	if weight<=.001:return Color("e4c67a")
	var color:=Color(sum.x/weight,sum.y/weight,sum.z/weight)
	return Color.from_hsv(color.h,maxf(.35,color.s),maxf(.88,color.v))
