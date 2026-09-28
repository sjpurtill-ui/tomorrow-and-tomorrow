extends RefCounted
## THE GROUND A BATTLE IS FOUGHT ON, from the map itself.
##
## The frontage of a battle (battle_blocks.gd) depends on the ground: open
## country, broken hills, a forest edge, a marsh, a pass, a ford, or the walls
## of a town. This reads the kind of ground at the place of the fight from the
## same survey the map is drawn from (or the planet's own terrain estimate
## before the map is surveyed), checks for a river between the two sides, and
## for a town's walls. Decided once, when the battle starts, and kept on the
## battle so it never changes under it. Static helpers; preload.

const Blocks:=preload("res://scripts/battle_blocks.gd")
const Route:=preload("res://scripts/army_land_route.gd")

## Survey thresholds (slope: rise over run near the place).
const FOREST_WOODLAND:=0.55
const PASS_SLOPE:=0.2
const ROUGH_SLOPE:=0.08
## A river this close to the place of the fight, with water between the two
## sides, means one side is crossing it.
const RIVER_NEAR_KM:=0.4
## A town's defended ground at or above this has walls to fight over.
const WALLED:=1.2


## The ground kind for a sample of the survey (pure).
static func classify(sample:Dictionary,crossing:bool=false)->String:
	if crossing: return "ford"
	var biome:=String(sample.get("biome",""))
	var slope:=float(sample.get("slope",absf(float(sample.get("relief",0.0)))))
	if biome=="wetland" or biome=="marsh": return "marsh"
	if slope>=PASS_SLOPE and biome in ["upland","mountain","alpine","highland"]: return "pass"
	if float(sample.get("woodland",0.0))>=FOREST_WOODLAND: return "forest"
	if slope>=ROUGH_SLOPE or biome in ["upland","mountain","alpine","highland"]: return "rough"
	return "open"


## The ground for a town's defences: its walls if it has them.
static func town(terrain_defense:float,engineers:bool)->String:
	if terrain_defense>=WALLED: return "breach" if engineers else "gate"
	return "rough"


## A home settlement's own defences: its palisade or walls, else its land.
static func home(stage:int,province_terrain:String,engineers:bool)->String:
	if stage>=3: return "breach" if engineers else "gate"
	if stage==2: return "rough"
	return String({"Mountains":"rough","Hills":"rough","Forest":"forest","Marsh":"marsh"}.get(province_terrain,"open"))


## Whether a column going from `from` to `to` must cross water (a river it can
## wade): some of the line is wet, none of it more than a ford.
static func crossing(from:Vector2,to:Vector2,land:Callable)->bool:
	if not land.is_valid() or from.distance_to(to)<0.05: return false
	var samples:=clampi(ceili(from.distance_to(to)/0.05),2,200)
	var wet:=false
	var run:=0.0
	var step:=from.distance_to(to)/float(samples)
	for i in samples+1:
		if bool(land.call(from.lerp(to,float(i)/float(samples)))): run=0.0; continue
		wet=true; run+=step
		if run>Route.FORD_KM: return false
	return wet


## The survey sample at a place: the map's own ground where it is drawn, the
## planet's estimate elsewhere.
static func sample(at:Vector2)->Dictionary:
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world!=null:
		var survey:Variant=(world as Object).get("ground_survey_authority")
		if survey is Callable and (survey as Callable).is_valid():
			var found:Variant=(survey as Callable).call(at)
			if found is Dictionary: return found
	var planet:Node=Engine.get_main_loop().root.get_node_or_null("PlanetEnvironment") if Engine.get_main_loop()!=null else null
	if planet!=null and planet.has_method("profile_at"): return planet.call("profile_at",at)
	return {}


## The ground for a battle, as battle_blocks.GROUNDS wants it: {kind, label}.
## context: {kind: field|raid|assault, terrain_defense, at (Vector2), from
## (Vector2, where the attacker comes from), home_stage (-1 when not the home
## settlement), province_terrain, engineers (the attacker brings engines or
## guns)}.
static func of(context:Dictionary)->Dictionary:
	var kind:=String(context.get("kind","field"))
	var terrain:=float(context.get("terrain_defense",1.0))
	var engineers:=bool(context.get("engineers",false))
	var ground:=""
	if int(context.get("home_stage",-1))>=0:
		ground=home(int(context.home_stage),String(context.get("province_terrain","")),engineers)
	elif kind=="assault":
		ground=town(terrain,engineers)
	else:
		var at:Variant=context.get("at",null)
		if at is Vector2:
			var survey:=sample(at)
			var from:Variant=context.get("from",null)
			var wet:=false
			if from is Vector2 and float(survey.get("river_distance_km",INF))<=RIVER_NEAR_KM:
				wet=crossing(from,at,Route.world_land())
			ground=classify(survey,wet)
		else:
			ground="rough" if terrain>=1.25 else "open"
	return {"kind":ground,"label":String((Blocks.GROUNDS.get(ground,Blocks.GROUNDS.open) as Dictionary).words)}


## Whether a force brings engineers, engines or guns to a wall.
static func has_engineers(force:Dictionary)->bool:
	for formation_variant in force.get("formations",[]):
		if not formation_variant is Dictionary: continue
		var formation:Dictionary=formation_variant
		if int(formation.get("count",0))<=0: continue
		if Blocks.arm_of(String(formation.get("unit","")),String(formation.get("weapon",""))) in ["engineers","guns"]: return true
	return false
