extends RefCounted
## An older save made from the current world: the whole-game save with the
## sections and fields later releases added taken out again. Loading it shows
## that each missing piece starts from a safe default and the world goes on.
## Test-only; it writes to the given slot and nowhere else.

## Whole sections an older release did not write: the general-led campaign
## and its dialogue (release 2026.09.05.14).
const SECTIONS:=["curated_GeneralCampaign","reflected_GeneralDialogue"]
## Fields inside one system's saved state that later releases added.
const FIELDS:={
	# Several battles at once: an older save keeps one active_engagement.
	"MilitaryCampaign":["engagements","focused_engagement","focus_before"],
	# What the air and sea war costs in people.
	"MilitaryCampaign.joint_operations":["wounded","captured_holding","raiding","raids_out","war_ledger"],
	# Beaten bands stay beaten.
	"CivilizationSystem":["formation_memory"],
	# Soldiers' rations kept apart from the food at home.
	"ConsequenceEngine":["_home_intake_today"],
}
## Where each system's state sits in a save: the player's own, then each rival's.
const HUMAN_SECTION:={"MilitaryCampaign":"curated_MilitaryCampaign","CivilizationSystem":"curated_CivilizationSystem","ConsequenceEngine":"reflected_ConsequenceEngine"}


## Saves the current world to `slot`, then rewrites it as an older release
## would have written it. Returns {ok, removed:[what was taken out], metadata}
## or {error}.
static func write(slot:String)->Dictionary:
	var saved:Dictionary=SaveSystem.save_game(slot)
	if saved.has("error"):return saved
	var payload:Dictionary=SaveSystem._read_payload(slot)
	if payload.is_empty():return {"error":"The new save could not be read back."}
	var removed:Array[String]=[]
	for section:String in SECTIONS:
		if payload.erase(section):removed.append(section)
	for name:String in HUMAN_SECTION:
		_strip(payload.get(HUMAN_SECTION[name]),name,"player",removed)
	var actors:Variant=(payload.get("curated_WorldSimulation",{}) as Dictionary).get("actors",{})
	if actors is Dictionary:
		for id:String in actors:
			var state:Variant=(actors[id] as Dictionary).get("state",{})
			if not state is Dictionary:continue
			for name:String in HUMAN_SECTION:_strip((state as Dictionary).get(name),name,id,removed)
	var written:Dictionary=SaveSystem._write_payload(SaveSystem.slot_path(slot),payload)
	if written.has("error"):return written
	return {"ok":true,"removed":removed,"metadata":(payload.get("metadata",{}) as Dictionary).duplicate(true)}


static func _strip(state:Variant,name:String,owner:String,removed:Array[String])->void:
	if not state is Dictionary:return
	for field:String in FIELDS.get(name,[]):
		if (state as Dictionary).erase(field):removed.append("%s %s.%s" % [owner,name,field])
	if name=="MilitaryCampaign":_strip((state as Dictionary).get("joint_operations"),"MilitaryCampaign.joint_operations",owner,removed)
