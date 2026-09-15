extends RefCounted
## Presentation derived from the surveyed biome, never a second resource model.
## Stable world cells keep existing plants fixed when a convoy or patch moves.
const PATCH_RADIUS_KM:=.235
const PATCH_INNER_KM:=.13
const CROWN_FULL_FOOTPRINT_KM:=.26
const CROWN_HIDDEN_FOOTPRINT_KM:=.78
# Keep eight material batches, but choose the atlas cells that read as healthy
# aerial crowns. The omitted cells are pale or nearly leafless specimens whose
# exposed branches became dark rock-like marks over a continuous woodland.
const CROWN_ATLAS_CELLS:=[0,1,2,4,6,7,11,14]

static func detail_strength(vertical_span:float,aspect:float)->float:
	# Hand physical crowns back to continuous woodland albedo before the finite
	# detail patch becomes a dot on the map. Use its physical footprint, so the
	# same aerial distance cannot gain a square of trees on a wider display.
	var footprint:=maxf(0.0,vertical_span)*maxf(1.0,aspect)
	return 1.0-smoothstep(CROWN_FULL_FOOTPRINT_KM,CROWN_HIDDEN_FOOTPRINT_KM,footprint)

static func cell_seed(cell:Vector2i,world_seed:int,salt:int=0)->int:
	return hash("%d:%d:%d:%d:vegetation" % [world_seed,cell.x,cell.y,salt])
static func candidates(center:Vector2,radius:float,spacing:float,world_seed:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var minimum:=Vector2i(floori((center.x-radius)/spacing),floori((center.y-radius)/spacing))
	var maximum:=Vector2i(floori((center.x+radius)/spacing),floori((center.y+radius)/spacing))
	var rng:=RandomNumberGenerator.new()
	for z in range(minimum.y,maximum.y+1):
		for x in range(minimum.x,maximum.x+1):
			var cell:=Vector2i(x,z);var seed_value:=cell_seed(cell,world_seed)
			rng.seed=seed_value
			var point:=(Vector2(cell)+Vector2(rng.randf_range(.08,.92),rng.randf_range(.08,.92)))*spacing
			if absf(point.x-center.x)>radius or absf(point.y-center.y)>radius:continue
			result.append({"point":point,"seed":cell_seed(cell,world_seed,17)})
	return result
static func canopy_density(biome:Dictionary)->float:
	if String(biome.get("id","water")) in ["water","tundra"]:return 0.0
	return clampf(float(biome.get("woodland",0.0)),0.0,1.0)
static func scrub_density(biome:Dictionary)->float:
	if String(biome.get("id","water"))=="water":return 0.0
	var rain:=clampf(float(biome.get("precipitation",0.0)),0.0,1.0)
	var warmth:=clampf(float(biome.get("temperature",0.0)),0.0,1.0)
	return lerpf(.012,.22,rain)*lerpf(.20,1.0,smoothstep(.05,.35,warmth))
static func canopy_tint(biome:Dictionary,variation:float)->Color:
	var warmth:=float(biome.get("temperature",.5))
	var shade:=Color("344936").lerp(Color("69805a"),clampf(variation,0,1)*.62)
	if warmth<.40:shade=shade.lerp(Color("465d5b"),clampf((.40-warmth)*2.5,0,.65))
	return shade
static func scrub_tint(biome:Dictionary,variation:float)->Color:
	var rain:=float(biome.get("precipitation",0.0))
	var warmth:=float(biome.get("temperature",0.0))
	var dry:=Color("92805c").lerp(Color("b29a6a"),variation)
	var wet:=Color("50613d").lerp(Color("80915d"),variation)
	var shade:=dry.lerp(wet,smoothstep(.30,.62,rain))
	if warmth<.22:shade=shade.lerp(Color("8c9285"),.62)
	return shade
static func crown_variant(position:Vector3)->int:
	# Appearance is tied to its physical crown, not its changing draw-list index.
	return posmod(hash(Vector2i(roundi(position.x*100000),roundi(position.z*100000))),8)
