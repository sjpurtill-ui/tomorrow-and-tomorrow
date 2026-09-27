extends RefCounted
## Starting camp capacity is not evidence that a shelter project was completed.
static func describe(completed:Array,capacity:int,population:int)->Dictionary:
	var built:bool="Lean-to Shelters" in completed
	var places:=maxi(0,capacity)
	var detail:="Lean-to shelters are built: room for %d people in all." % places if built else "No shelters built yet. The camp's hides and branches cover %d people." % places
	if population>places: detail+=" %d people sleep in the open." % (population-places)
	elif population>0: detail+=" Everyone has a roof."
	return {"built":built,"detail":detail,"empty_label":"No shelters built yet"}
