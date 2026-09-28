extends RefCounted
## WAR OR FEUD: one reading of how two peoples fight, by how many they are.
##
## "Towns of 120 people don't DECLARE WAR. They just fight and raid." Below
## the war line, fighting between two peoples is a FEUD: raids and
## counter-raids, ambushes on hunters and herders, stolen stores, killed or
## taken people. Nobody declares or opens a war, no generals take the field,
## and there are no heralds' terms, fronts, war goals or campaigns. Each
## side's war leader leads a handful of raiders (war_loop.gd). A feud cools
## with time, with exhaustion, with a blood price or an exchange of gifts, or
## with a marriage between the peoples, and it flares with new killings.
## A people whose raiders are out sends nobody to boast or demand in the hall
## of the people it raids (audience_hall.gd).
##
## Above the line, when BOTH peoples are organised for war, war can be
## declared and fought as a war: a host under one leader, fronts, terms and
## the benchmark war rates of EPOCHAL_SHIFTS.md s3.4 and s5.
##
## The line (calibration only; no real names reach the game):
##   - Bands of 25-50 and villages or clans of a few hundred to the low
##     thousands, with no ruler who can command, fight by raid, ambush and
##     blood feud. Raiding parties are 5-30 men; a feud is ended by
##     compensation (a blood price in livestock or goods), by exchanges of
##     gifts and marriages between the groups, or it simply cools when both
##     sides are worn out (the ethnographic record of village horticulturalists
##     and pastoralists, and the classic accounts of feud and blood money).
##   - Declared war with a leader who commands a host, feeds it through a
##     season and treats through heralds begins with chiefdoms, regional
##     polities of a few thousand people, and is the rule of states of tens
##     of thousands (the band / tribe / chiefdom / state sequence; the
##     "regional polity" threshold sits in the low thousands).
##   - At the pre-modern mobilisation cap (3-7% of the people, s3.4), 1,500
##     people put 45-105 fighters in the field: a war host, not a raiding
##     party. Below it the whole of a people's fighters is a raiding party.
## So a people is organised for war at WAR_POP people or more, and a war
## needs both sides to be. Every system asks formal_war() (or formal() for a
## people and the god's own); nothing keeps its own threshold.
##
## A war already declared between peoples organised for war is fought out
## while both keep HOLD_SHARE of the line: a lost battle or a hard winter does
## not turn it into a feud, and the line does not flicker as numbers move.
## Below that a people can no longer feed a host, and its war is a feud.
##
## Static helpers; preload. `world` is the civilization system to read (the
## one in play when omitted; CivilizationSystem passes itself).

## Organised for war: a chiefdom or more.
const WAR_POP:=1500.0
## A declared war holds while both peoples keep this share of the line.
const HOLD_SHARE:=0.8

static func _world(world:Variant)->Variant:
	if world!=null: return world
	if Engine.get_main_loop()==null: return null
	return WorldSimulation.world

## How many people a people counts, in the scope that asks. "player" is the
## people whose scope this is (the god's own people in play; a rival's own in
## its scope, where the god's people appear as another civilization).
static func people(civ_id:String,world:Variant=null)->float:
	if civ_id=="" or Engine.get_main_loop()==null: return 0.0
	if civ_id=="player":
		var state:Variant=WorldSimulation.state
		if state==null: return 0.0
		return maxf(float(state.population_exact),float(state.population_total))
	var w:Variant=_world(world)
	if w==null: return 0.0
	for civ in w.civilizations:
		if civ is Dictionary and String((civ as Dictionary).get("id",""))==civ_id: return maxf(0.0,float((civ as Dictionary).get("population",0.0)))
	return 0.0

## A people that can raise and feed a war host under one leader.
static func organised(civ_id:String,world:Variant=null)->bool:
	return people(civ_id,world)>=WAR_POP

## THE predicate: can these two peoples be at war, or only in a feud?
static func formal_war(a:String,b:String,world:Variant=null)->bool:
	var pa:=people(a,world); var pb:=people(b,world)
	if pa>=WAR_POP and pb>=WAR_POP: return true
	if pa<WAR_POP*HOLD_SHARE or pb<WAR_POP*HOLD_SHARE: return false
	return declared(a,b,world)

## A people and the god's own people.
static func formal(civ_id:String,world:Variant=null)->bool:
	return formal_war("player",civ_id,world)

## Is a war declared between peoples organised for war going on between
## these two now (their war record says it was declared as a war)?
static func declared(a:String,b:String,world:Variant=null)->bool:
	var w:Variant=_world(world)
	if w==null or not w.has_method("_war_record_index"): return false
	var relation:Dictionary={}
	for civ in w.civilizations:
		if not civ is Dictionary: continue
		var id:=String((civ as Dictionary).get("id",""))
		if (b=="player" and id==a) or (a=="player" and id==b):
			relation=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
			break
		if id==a and b!="player":
			var r:Variant=((civ as Dictionary).get("relations",{}) as Dictionary).get(b)
			relation=r if r is Dictionary else {}
			break
	if not bool(relation.get("at_war",false)): return false
	var at:int=w._war_record_index(String(relation.get("war_id","")))
	if at<0: return false
	var record:Dictionary=w.war_history[at]
	return String(record.get("status",""))=="active" and bool(record.get("formal",false))

## "war" or "feud": the word for fighting between this people and ours.
static func word(civ_id:String)->String:
	return "war" if formal(civ_id) else "feud"

## The same for two other peoples.
static func pair_word(a:String,b:String)->String:
	return "war" if formal_war(a,b) else "feud"
