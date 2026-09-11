extends RefCounted
## Reuse the preserved crafted-object artwork only for a real producing civ.
## These are conservative presentation gates, not new discovery definitions.
const REQUIREMENTS := [
	["controlled_flaking","pictographic_records"],
	["cordage","controlled_flaking","pictographic_records"],
	["tallies","controlled_flaking","pictographic_records"],
	["pit_firing","clay_tempering","festival_calendar","pictographic_records"],
	["woven_carriers","fiber_grading","cordage","pictographic_records"],
	["pictographic_records","controlled_flaking"],
	["standard_measures","joinery","pictographic_records"],
	["cordage","controlled_flaking","pictographic_records"],
	["pictographic_records","customary_law","controlled_flaking"],
	["clay_shaping","pit_firing","festival_calendar","pictographic_records"],
	["controlled_flaking","festival_calendar","pictographic_records"],
	["pictographic_records","joinery","tallies"],
	["clay_shaping","pit_firing","clay_tempering","pictographic_records"],
	["woven_carriers","fiber_grading","joinery","pictographic_records"],
	["route_memory","controlled_flaking","pictographic_records"],
	["seasonal_patterns","tallies","controlled_flaking","pictographic_records"]
]
# Only variants whose depicted material matches the existing paid recipe.
const MATCHES := {"pit_firing":3,"basketry":4,"joinery":6,"tallies":11,"clay_shaping":12}

static func ready(form:int,known:Array,adoption:Dictionary)->bool:
	if form<0 or form>=REQUIREMENTS.size():return false
	for requirement:String in REQUIREMENTS[form]:
		if requirement not in known or float(adoption.get(requirement,0))<.35:return false
	return true

static func apply(item:Dictionary,known:Array,adoption:Dictionary)->void:
	if item.get("kind","")!="artifact" or String(item.get("source_id","")).is_empty():return
	item["artifact_origin"]="civilization"
	var form:=int(MATCHES.get(String(item.discovery_id),-1))
	if not ready(form,known,adoption):return
	item["art_collection"]="early-civ-v1"
	item["catalogue_id"]=form
	item["maker_requirements"]=REQUIREMENTS[form].duplicate()
	item["name"]=["","","","Clay ceremonial bowl · etched river","Woven fragment · etched river","","Wood measuring rod · etched river","","","","","Wood painted panel · etched river","Clay storage jar · etched river"][form]
