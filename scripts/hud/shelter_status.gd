extends RefCounted
## Starting camp capacity is not evidence that a shelter project was completed.
## `carried` is how many of the places are the tents the founders carried
## (settlement_construction.gd carried_places); -1 leaves the split unsaid.
static func describe(completed:Array,capacity:int,population:int,carried:int=-1)->Dictionary:
	var built:bool="Lean-to Shelters" in completed
	var places:=maxi(0,capacity)
	var tents:=clampi(carried,0,places)
	var detail:="No shelters built yet. The tents carried on the journey cover %d people." % places
	if built:
		detail="Lean-to shelters are built: room for %d people in all" % places
		detail+=(", %d of them in the tents carried on the journey." % tents) if carried>=0 and tents>0 and tents<places else "."
	if population>places: detail+=" %d people sleep in the open." % (population-places)
	elif population>0: detail+=" Everyone has a roof."
	return {"built":built,"detail":detail,"empty_label":"No shelters built yet"}
