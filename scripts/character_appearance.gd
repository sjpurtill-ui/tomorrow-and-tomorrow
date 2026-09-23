extends RefCounted
## Saved visual identity only; never participates in traits or simulation RNG.
const FAMILIES:=["kilnfold","reedwake","windseam","stoneweft","ashplain","rillmark","flintmere","morrowfen","thornbank","sunhollow","greyfold","ochrestep","hollowreed"]
static func initial_family(seed_value:int,owner:String)->String:
	var slot:=0
	if owner!="player":
		var suffix:=owner.trim_prefix("civ_")
		slot=int(suffix) if owner.begins_with("civ_") and suffix.is_valid_int() and int(suffix)>0 else posmod(owner.hash(),FAMILIES.size())
	var offset:=posmod((str(seed_value)+":visual_ancestry").hash(),FAMILIES.size())
	return FAMILIES[posmod(offset+slot,FAMILIES.size())]
static func family_for(seed_value:int,owner:String,records:Array=[])->String:
	if records.is_empty():
		var government:Node=GovernmentPeopleSystem if owner=="player" else WorldSimulation.actors.get(owner,{}).get("systems",{}).get("GovernmentPeopleSystem")
		if is_instance_valid(government):records=government.people
	for person:Dictionary in records:
		var saved:=String(person.get("early_art_profile",""))
		if FAMILIES.has(saved):return saved
	# The human's known diplomatic leader can precede the first government view.
	var foreign:Dictionary=ForeignDiplomacy.leaders.get(owner,{}) if ForeignDiplomacy.seed_value==seed_value else {}
	var saved:=String(foreign.get("early_art_profile",""))
	return saved if FAMILIES.has(saved) else initial_family(seed_value,owner)
