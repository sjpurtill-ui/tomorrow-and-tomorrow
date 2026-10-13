extends RefCounted
## ARE THESE TWO PEOPLES FIGHTING? One answer, asked in one place.
##
## The fact is kept once. A formal war is on the record of the pair (at_war),
## which both sides share (civilization_relations.gd). A feud is on the feud's
## own record: ours with a people in war_loop.gd, two other peoples' on their
## pair (feud_since, feud_last). Nothing else decides it; the trade ledger,
## the war council, the fleets, the envoys and the court all ask here.
##
## `world` is whose book is read: the people whose turn it is by default, so
## a rival's council reads its own book as ours reads ours.
const WAR_PATH:="res://scripts/war_loop.gd"

static func _book(world:Variant)->Variant:
	return world if world!=null else WorldSimulation.world

static func _civ(id:String,world:Variant)->Dictionary:
	var book:Variant=_book(world)
	if book==null or id=="player": return {}
	for civ:Variant in book.civilizations:
		if civ is Dictionary and String((civ as Dictionary).get("id",""))==id: return civ
	return {}

## The record of the pair. With us it is the people's record of us; between
## two other peoples it is the first's record of the second.
static func relation(a:String,b:String,world:Variant=null)->Dictionary:
	if a==b: return {}
	var ours:=a=="player" or b=="player"
	var civ:=_civ((b if a=="player" else a) if ours else a,world)
	if civ.is_empty(): return {}
	var found:Variant=civ.get("player_relation",{}) if ours else (civ.get("relations",{}) as Dictionary).get(b,{})
	return found if found is Dictionary else {}

## A declared war between the two.
static func at_war(a:String,b:String,world:Variant=null)->bool:
	return bool(relation(a,b,world).get("at_war",false))

## A feud between the two that is still hot (raids going, or lately).
static func feud(a:String,b:String,day:int=-1,world:Variant=null)->bool:
	if a==b or at_war(a,b,world): return false
	if a=="player" or b=="player":
		var war:=load(WAR_PATH) as GDScript
		return war!=null and bool(war.call("hot",b if a=="player" else a,day))
	var book:Variant=_book(world)
	if book==null or not book.has_method("rival_feud_hot"): return false
	return bool(book.rival_feud_hot(relation(a,b,world),day if day>=0 else int(WorldSimulation.state.elapsed_days)))

## "war", "feud" or "peace".
static func between(a:String,b:String,day:int=-1,world:Variant=null)->String:
	if at_war(a,b,world): return "war"
	return "feud" if feud(a,b,day,world) else "peace"

static func fighting(a:String,b:String,day:int=-1,world:Variant=null)->bool:
	return between(a,b,day,world)!="peace"
