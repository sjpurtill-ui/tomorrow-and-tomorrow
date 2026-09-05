class_name PermanentInjuries
extends RefCounted

## Two aggregate functional-severity cohorts, not diagnoses or citizen records.
## Capacity assumptions depend on physical demands; literacy/intellect are not
## assumed lost because a veteran cannot march or carry a heavy load.
const RETAINED_CAPACITY:Dictionary={
	"Food":Vector2(.72,.32),"Survey":Vector2(.65,.22),
	"Extraction":Vector2(.55,.15),"Construction":Vector2(.60,.20),
	"Crafting":Vector2(.82,.55),"Logistics":Vector2(.60,.20),
	"Knowledge":Vector2(.97,.88),"Administration":Vector2(.97,.88),
	"Defense":Vector2(.55,.15)
}

static func effective(headcount:float,role:String,injuries:Dictionary,civilian_workers:float)->float:
	if headcount<=0 or civilian_workers<=0: return maxf(0,headcount)
	var limited:=maxf(0,float(injuries.get("limited",0)))
	var severe:=maxf(0,float(injuries.get("severe",0)))
	var scale:=minf(1.0,civilian_workers/maxf(1,limited+severe))
	var retained:Vector2=RETAINED_CAPACITY.get(role,Vector2(.85,.65))
	var reduction:float=(limited*(1-retained.x)+severe*(1-retained.y))*scale/civilian_workers
	return headcount*clampf(1-reduction,0,1)

static func total(injuries:Dictionary)->int:
	return roundi(maxf(0,float(injuries.get("limited",0)))+maxf(0,float(injuries.get("severe",0))))
