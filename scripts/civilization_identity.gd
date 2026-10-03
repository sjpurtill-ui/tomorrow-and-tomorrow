extends RefCounted
## Fictional identities are selected without replacement, independently of simulation RNG.
## Each people's name and its first five towns come from its own tongue
## (people_language.gd): never shared across the world, no town named after
## its people. The colours, patterns and symbols are drawn as before.
const Lang:=preload("res://scripts/people_language.gd")
## How many fixed identities the roster once drew from (64 names with their
## towns, now gone: older saves keep the names they were given); the draw is
## still taken so every world keeps the colours and emblems it had.
const LEGACY_PROFILE_COUNT:=64
const PALETTES:=[
	["bd4454","ff9299","fff1d6"],["296ca3","85bdeb","fff1d6"],
	["d3a835","edcf70","142938"],["228873","64d1b4","fff1d6"],
	["70449e","bba1e6","fff1d6"],["c9702e","f0ad72","172d37"],
	["658b39","b5d77e","fff1d6"],["b64d83","efa2cb","fff1d6"],
	["7c929d","b9ced5","142938"],["459faf","8edee6","142938"],
	["9d7650","dec19a","fff1d6"],["d6cfb2","eee7c9","19333d"]
]
static var cached_seed:int=-9223372036854775807
static var cached:Array[Dictionary]=[]

static func roster(seed_value:int)->Array[Dictionary]:
	if cached_seed==seed_value and not cached.is_empty():return cached
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^0x4271d93a
	shuffled(LEGACY_PROFILE_COUNT,rng)
	var colors:=shuffled(PALETTES.size(),rng)
	var patterns:=shuffled(8,rng);var symbols:=shuffled(12,rng)
	var tongues:Array=Lang.roster(seed_value)
	cached=[];cached_seed=seed_value
	for i in 36:
		var people:Dictionary=tongues[i]
		var palette:Array=PALETTES[colors[i%12]]
		cached.append({"name":String(people.name),"cities":(people.cities as Array).duplicate(),"field":palette[0],"color":palette[1],"ink":palette[2],"pattern":patterns[(i%12+i/12)%8],"symbol":symbols[(i*5+i/12)%12]})
	return cached

static func shuffled(count:int,rng:RandomNumberGenerator)->Array[int]:
	var values:Array[int]=[]
	for i in count:values.append(i)
	for i in range(count-1,0,-1):
		var other:=rng.randi_range(0,i);var held:=values[i];values[i]=values[other];values[other]=held
	return values

static func index_for(id:String)->int:
	var number:=id.trim_prefix("civ_")
	if id.begins_with("civ_") and number.is_valid_int() and int(number)>0:return posmod(int(number)-1,36)
	return posmod(hash(id),36)

static func identity(seed_value:int,id:String)->Dictionary:
	return roster(seed_value)[index_for(id)]
