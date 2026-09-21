extends RefCounted
## Starting camp capacity is not evidence that a shelter project was completed.
static func describe(completed:Array,capacity:int,population:int)->Dictionary:
	var built:bool="Lean-to Shelters" in completed
	var places:=maxi(0,capacity)
	var detail:="Lean-to Shelters completed · %d total shelter places" % places if built else "No built shelters · %d starting camp shelter places" % places
	if population>places: detail+="\n%d people beyond shelter capacity" % (population-places)
	return {"built":built,"detail":detail,"empty_label":"NO BUILT SHELTERS"}
