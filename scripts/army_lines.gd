extends RefCounted
## THE ARMY'S LINES: the one break line and the one strength line. Every
## check of whether a band or an army breaks, withdraws, rests or is ready
## again reads them from here, so the map, the reports, the war leader and
## the fight itself call a band broken or weak by the same numbers.
##
##   BREAK     A band or army breaks when its will to fight falls below a
##             quarter. In battle a side below it breaks and runs
##             (combat_simulator.gd for the whole army, battle_blocks.gd for
##             each block in the line); out of battle a band below it is
##             broken, and the war leader takes it out of the fighting to
##             rest (band_upkeep.gd).
##   STRENGTH  A band with fewer than half its men is under strength. It
##             does not seek battle; the war leader brings it back to rest
##             and refill near home or a town we hold. A band whose men fall
##             below half of those it took into a fight pulls out of it.
##   READY     A resting band is ready again when its will is back to half
##             and three in four of its places are filled (or nobody more can
##             come for it while the army stands at the size the ruler set).
## Static; preload.

const BREAK:=0.25
const BREAK_WORDS:="breaks when will falls below a quarter"
const STRENGTH:=0.5
const STRENGTH_WORDS:="under half its men"
const READY_WILL:=0.5
const READY_STRENGTH:=0.75


## Will below the break line.
static func broken(will:float)->bool:
	return will<BREAK


## Men below the strength line of `full`.
static func weak(men:int,full:int)->bool:
	return full>0 and float(maxi(0,men))<float(full)*STRENGTH


## A band's full strength: every place in its formations, filled or not (as
## the army bar counts it, hud/army_marks.gd full_strength).
static func full_strength(force:Dictionary)->int:
	var full:=0
	for formation in force.get("formations",[]):
		if formation is Dictionary: full+=maxi(maxi(0,int(formation.get("count",0))),int(formation.get("authorized_count",0)))
	return maxi(full,maxi(0,int(force.get("troops",0))))


## Broken or under strength: the band should not be sent to fight.
static func unfit(force:Dictionary)->bool:
	return broken(float(force.get("morale",1.0))) or weak(int(force.get("troops",0)),full_strength(force))


## Rested and refilled enough to take the field again.
static func rested(force:Dictionary,nothing_more_coming:bool=false)->bool:
	if float(force.get("morale",1.0))<READY_WILL: return false
	var full:=full_strength(force)
	return nothing_more_coming or full<=0 or float(int(force.get("troops",0)))>=float(full)*READY_STRENGTH


## "will 18%, below a quarter: they break" / "8 of 20, under half its men".
static func why_unfit(force:Dictionary)->String:
	var will:=float(force.get("morale",1.0))
	var men:=int(force.get("troops",0))
	var full:=full_strength(force)
	var parts:PackedStringArray=[]
	if broken(will): parts.append("will %d%%: a band %s" % [roundi(will*100.0),BREAK_WORDS])
	if weak(men,full): parts.append("%d of %d men, %s" % [men,full,STRENGTH_WORDS])
	return "; ".join(parts)
