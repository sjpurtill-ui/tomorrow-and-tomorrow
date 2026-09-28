extends RefCounted
## ONE NAME FOR A TOWN (docs/ADJUDICATION.md: one state, one reading).
##
## A town of another people is named as the map's own label names it: our
## chart's record of the town (city_intelligence, what the label reads),
## else the world's name for its region, else what the caller was told (an
## occupation's region_name, a ledger's name). The supply map, the army
## bar, the war chart's garrison tags and the court all ask here, so a town
## we hold is never called two things at once.
## Static helpers; preload.

static func of(civ_id:String,region_id:String,fallback:String="")->String:
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world!=null and region_id!="":
		var intel:Variant=world.get("city_intelligence")
		if intel!=null:
			var book:Dictionary=(intel.records as Dictionary).get("player",{})
			var name:=String((book.get(region_id,{}) as Dictionary).get("name",""))
			# "Reported home of ..." is a scout's placeholder, not the town's name.
			if name!="" and not name.begins_with("Reported home of "): return name
		if civ_id!="" and world.has_method("region_snapshot"):
			var region:Dictionary=world.region_snapshot(civ_id,region_id)
			var name:=String(region.get("name",""))
			if name!="": return name
	return fallback
