extends RefCounted
## Saved visual identity only; never participates in traits or simulation RNG.
const FAMILIES:=["kilnfold","reedwake","windseam","stoneweft","ashplain"]
static func initial_family(seed_value:int,owner:String)->String:
	return FAMILIES[posmod((str(seed_value)+":"+owner+":visual_ancestry").hash(),FAMILIES.size())]
static func family_for(seed_value:int,owner:String,records:Array=[])->String:
	if records.is_empty():
		var government:Node=GovernmentPeopleSystem if owner=="player" else WorldSimulation.actors.get(owner,{}).get("systems",{}).get("GovernmentPeopleSystem")
		if is_instance_valid(government):records=government.people
	for person:Dictionary in records:
		var saved:=String(person.get("early_art_profile",""))
		if FAMILIES.has(saved):return saved
	# The human's known diplomatic leader can precede the first government view.
	var foreign:Dictionary=ForeignDiplomacy.leaders.get(owner,{})
	var saved:=String(foreign.get("early_art_profile",""))
	return saved if FAMILIES.has(saved) else initial_family(seed_value,owner)
