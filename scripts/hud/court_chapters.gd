extends RefCounted
## Buildings renew every 200 elapsed campaign years. The calendar chooses a
## design, while actual construction knowledge bounds it and actual discoveries
## supply its equipment. This never grants discoveries or changes government.

const Stages:=preload("res://scripts/civic_stages.gd")
const YEARS_PER_CHAPTER:=200
const DAYS_PER_YEAR:=365.0
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
## Nominal historical sequence follows TechnologyEras.CURVE: the medieval
## chapters are 1400, 1600 and 1800; 2400 is about the start of industrialization.
const CONSTRUCTION:={
	1:["central_hall_houses"],
	2:["lime_plastered_floors","seasonal_wall_replastering"],
	3:["dressed_stone_masonry","ashlar_masonry"],
	6:["columned_stone_temple","vaulted_masonry_roofs","long_span_timber_halls","clerestory_halls"],
	7:["plank_walled_timber_halls"],
	8:["round_arch_great_houses","great_hall_of_justice","belfry_town_halls"],
	9:["chancery_enrolment_rolls","fixed_capital_archives"],
	11:["secretaries_of_state","privy_council_minutes","grand_palace_court"],
	13:["ministry_office_block","single_minister_departments"],
	15:["reinforced_concrete","welded_steel_frames","precast_panel_housing"]
}
const STAGE_CEILINGS:={"elders_circle":1,"chiefs_hall":1,"temple_palace":3,
	"palace_bureaucracy":3,"citizen_assembly":6,"imperial_court":6,
	"senate_house":6,"late_antique_hall":6,"feudal_hall":8,
	"chancery_court":9,"chartered_commune":9,"estates_assembly":9,
	"privy_state_council":11,"parliamentary_council":11,
	"ministerial_cabinet":13,"executive_council":15}
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

static func index_for_days(days:float)->int:
	return clampi(floori(maxf(0.0,days)/(YEARS_PER_CHAPTER*DAYS_PER_YEAR)),0,15)

static func for_owner(owner:="player")->Dictionary:
	var days:=0.0
	var loop:=Engine.get_main_loop() as SceneTree
	if loop!=null:
		var state:=loop.root.get_node_or_null("GameState")
		if state!=null:days=float(state.get("elapsed_days"))
	return derive(days,Stages.known_for(owner),Stages.current(owner))

static func derive(days:float,known:Array,stage_record:Dictionary={})->Dictionary:
	var chapter:=index_for_days(days)
	var stage:=Stages.derive(known) if stage_record.is_empty() else stage_record
	var held:Dictionary={}
	for id in known:held[String(id)]=true
	var ceiling:=int(STAGE_CEILINGS.get(String(stage.get("id","")),0))
	for limit:int in CONSTRUCTION:
		if _has_any(held,CONSTRUCTION[limit]):ceiling=maxi(ceiling,limit)
	var design:=mini(chapter,ceiling)
	var capabilities:Dictionary={}
	for capability:String in CAPABILITIES:
		capabilities[capability]=_has_any(held,CAPABILITIES[capability])
	# Flat-panel computers replace CRTs only with both foundations; a society
	# can know displays without possessing desktop computing.
	capabilities.flat_screen=bool(capabilities.flat_screen) and bool(capabilities.computer)
	capabilities.fluorescent=bool(capabilities.fluorescent) and bool(capabilities.electricity)
	var lean:=String(stage.get("lean",stage.get("track","throne")))
	if lean=="any":lean=Stages.lean(known)
	return {"index":chapter,"start_year":chapter*YEARS_PER_CHAPTER,
		"design":design,"set_kind":"chapter_%02d" % design,"name":NAMES[design],"description":DESCRIPTIONS[design],
		"limited":design<chapter,"renewal":chapter,"lean":lean,"capabilities":capabilities}

static func _has_any(held:Dictionary,ids:Array)->bool:
	for id in ids:
		if held.has(String(id)):return true
	return false
