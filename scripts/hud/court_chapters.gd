extends RefCounted
## Room milestones follow the host's actual construction and civic practices.
## Time alone never selects a room or renews its layout.
const Stages:=preload("res://scripts/civic_stages.gd")
const NAMES:=["The common hearth","The community hall","The courtyard of records",
	"The audience hall","The colonnaded council","The vaulted council house",
	"The chamber of records","The timber great hall","The stone great hall",
	"The chancery chamber","The secretariat","The cabinet council room",
	"The ministerial office","The department office","The executive conference room",
	"The government conference room"]
const DESCRIPTIONS:=["a shared fire, windbreaks and a circle of seats",
	"a timber roof, benches and a clear central passage",
	"plastered walls, a shaded court and a place for records",
	"masonry piers, a formal audience space and sheltered side rooms",
	"columns and council benches around an open speaking floor",
	"vaulted bays, clerical tables and recessed record storage",
	"a clerestory, divided working bays and a wall of records",
	"exposed timber trusses, trestle tables and a cross-passage",
	"a stone great hall, high table and doorway to the private chamber",
	"a working chancery with a clerk's desk, window seats and record chests",
	"clerks' desks, a secretary's station and a record cupboard",
	"a cabinet table, paneled walls and a secretary's station",
	"a minister's desk, consultation table and filing cupboards",
	"tall windows, clerical workstations and a waiting area",
	"a rounded meeting table, broad windows and a briefing sideboard",
	"a conference table, briefing wall and separate reception area"]
## Each authored room has its own relevant milestone; these are discoveries,
## not historical dates. Equipment remains independently gated below.
const CONSTRUCTION:={
	1:["central_hall_houses"],
	2:["lime_plastered_floors","seasonal_wall_replastering"],
	3:["dressed_stone_masonry","ashlar_masonry"],
	4:["columned_stone_temple"],
	5:["vaulted_masonry_roofs"],
	6:["long_span_timber_halls","clerestory_halls"],
	7:["plank_walled_timber_halls"],
	8:["round_arch_great_houses","great_hall_of_justice","belfry_town_halls"],
	9:["chancery_enrolment_rolls","fixed_capital_archives"],
	10:["secretaries_of_state","privy_council_minutes"],
	11:["grand_palace_court","cabinet_first_minister"],
	12:["single_minister_departments","appointed_department_prefects"],
	13:["ministry_office_block"],
	14:["reinforced_concrete","welded_steel_frames"],
	15:["precast_panel_housing"]
}
const CAPABILITIES:={
	"glazing":["house_glass_windows","sash_windows","cast_window_glass","glazed_windows"],
	"paper":["paper_making"],"bound_records":["bookbinding_assemblies"],
	"printing":["printing_process","screw_press_printing"],
	"typewriter":["typewriter"],"telephone":["telephone_circuits"],
	"electricity":["filament_lamp_works","electric_street_lighting"],
	"fluorescent":["fluorescent_lighting"],"radiator":["radiator_central_heating"],
	"air_conditioning":["refrigerated_air_conditioning"],
	"computer":["desk_computers","desktop_office_work"],
	"flat_screen":["flat_panel_displays"]
}

static func for_owner(owner:="player")->Dictionary:
	return derive(0.0,Stages.known_for(owner),Stages.current(owner))

static func derive(_days:float,known:Array,stage_record:Dictionary={})->Dictionary:
	# Keep the date argument for callers and saved-campaign probes; it cannot
	# influence appearance. Institutions still determine the political lean.
	var stage:=Stages.derive(known) if stage_record.is_empty() else stage_record
	var held:Dictionary={}
	for id in known:held[String(id)]=true
	var design:=0
	for milestone:int in CONSTRUCTION:
		if _has_any(held,CONSTRUCTION[milestone]):design=maxi(design,milestone)
	var capabilities:Dictionary={}
	for capability:String in CAPABILITIES:
		capabilities[capability]=_has_any(held,CAPABILITIES[capability])
	# Flat-panel computers replace CRTs only with both foundations; a society
	# can know displays without possessing desktop computing.
	capabilities.flat_screen=bool(capabilities.flat_screen) and bool(capabilities.computer)
	capabilities.fluorescent=bool(capabilities.fluorescent) and bool(capabilities.electricity)
	var lean:=String(stage.get("lean",stage.get("track","throne")))
	if lean=="any":lean=Stages.lean(known)
	return {"index":design,
		"design":design,"set_kind":"chapter_%02d" % design,"name":NAMES[design],"description":DESCRIPTIONS[design],
		"limited":false,"renewal":design,"lean":lean,"capabilities":capabilities}

static func _has_any(held:Dictionary,ids:Array)->bool:
	for id in ids:
		if held.has(String(id)):return true
	return false
