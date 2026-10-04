extends RefCounted
## One derived presentation for a people's clothes and ordinary court manners.
## No calendar, learned discoveries, government state or save fields are changed.

const Stages:=preload("res://scripts/civic_stages.gd")
const PERIODS:=["early","ancient","medieval","early_modern","industrial","modern"]
## Two independent known practices keep one isolated late discovery from
## redressing a whole society. Civic institutions can also establish a period.
const GATES:={
	"medieval":["fitted_tailoring","broad_treadle_loom","homage_commendation","royal_chancery_office","sworn_town_commune"],
	"early_modern":["screw_press_printing","secretaries_of_state","privy_council_minutes","resident_ambassadors","grand_palace_court","cabinet_first_minister"],
	"industrial":["rotative_steam_engine","iron_power_loom_sheds","sewing_machine_mechanisms","public_steam_railway","single_minister_departments","competitive_civil_service"],
	"modern":["garment_size_grading","radio_broadcasting","national_income_accounts","labor_ministry","unified_defence_ministry","online_government_services","digital_identity_register","one_party_state"]
}
const MEDIEVAL_STAGES:=["feudal_hall","chancery_court","chartered_commune","estates_assembly"]
const CLOTH:=["plain_weaving","warp_weighted_looms","garment_pattern_cutting","fitted_tailoring","sewing_machine_mechanisms","garment_size_grading"]
const FITTED:=["fitted_tailoring","sewing_machine_mechanisms","garment_size_grading"]
const DYES:=["textile_dye_extraction","alum_mordant_dyeing","shellfish_purple_dye","reduction_vat_blue_dye","resist_dyeing","textile_printing","textile_dye_fixation","coal_tar_dyes"]
const ESTABLISHED_DYES:=["alum_mordant_dyeing","shellfish_purple_dye","reduction_vat_blue_dye","resist_dyeing","textile_printing","textile_dye_fixation","coal_tar_dyes"]
const LETTERS:=["pictographic_records","phonetic_notation","formal_archives","parchment_record_preparation","paper_making","printing_process"]

static func for_owner(owner:String="player")->Dictionary:
	return from_knowledge(Stages.known_for(owner),Stages.current(owner))

static func from_knowledge(known:Array,stage_record:Dictionary={})->Dictionary:
	var stage:=Stages.derive(known) if stage_record.is_empty() else stage_record
	var held:Dictionary={}
	for id in known:held[String(id)]=true
	var rank:=int(stage.get("rank",0))
	var id:=String(stage.get("id",Stages.DEFAULT_ID))
	var period:="ancient" if rank>=3 else "early"
	if id in MEDIEVAL_STAGES:period="medieval"
	var institutional:=String(stage.get("presentation_period",""))
	if institutional in PERIODS:period=institutional
	for candidate:String in GATES:
		if PERIODS.find(candidate)>PERIODS.find(period) and _count(held,GATES[candidate])>=2:period=candidate
	var lean:=String(stage.get("lean",stage.get("track","throne")))
	if lean=="any":lean=Stages.lean(known)
	var formal:=rank>=3 or PERIODS.find(period)>=2
	# Institutions establish protocol, not the ability to cut a fitted coat.
	# Later garment practices are sufficient evidence for older saves that do
	# not redundantly record every earlier foundation; an office title is not.
	var woven:=_count(held,CLOTH)>0
	var fitted:=_count(held,FITTED)>0
	var outfit:="hide"
	var options:Array=["hide"]
	var dress_code:="hide"
	if woven:
		outfit="robe" if formal and period!="medieval" else "tunic"
		options=["tunic","robe"] if formal else ["tunic"]
		dress_code="draped" if period=="ancient" else "layered"
		if fitted:
			match period:
				"medieval":outfit="medieval";dress_code="fitted"
				"early_modern":outfit="courtcoat";dress_code="coat"
				"industrial":outfit="formal";dress_code="frock"
				"modern":outfit="business";dress_code="business"
			if outfit in ["medieval","courtcoat","formal","business"]:options=[outfit]
	var dye_level:=2 if _count(held,ESTABLISHED_DYES)>0 else (1 if _count(held,DYES)>0 else 0)
	var posture:=String((stage.get("protocol",{}) as Dictionary).get("posture",""))
	var greeting:="nod"
	if period=="early_modern" and lean=="throne":greeting="bow_small"
	elif period=="medieval" and lean=="throne":greeting="bow"
	elif period=="ancient" and lean=="throne":
		greeting="kneel" if "kneel" in posture or "prostrat" in posture else "bow"
	elif period=="early" and rank>=2:greeting="bow_small"
	var stance:="floor" if period=="early" else "seated"
	if period in ["ancient","medieval","early_modern"] and "stand" in posture:stance="standing"
	return {"period":period,"outfit":outfit,"dress_options":options,"dress_code":dress_code,
		"dye_level":dye_level,"tailored_colour_weight":0.72 if outfit=="courtcoat" else (0.40 if outfit=="formal" else 0.33),
		"routine_greeting":greeting,
		"routine_departure":"bow_small" if greeting in ["bow","kneel"] else greeting,
		"stance_policy":stance,"formal":formal,"lean":lean,"stage_id":id,
		"protocol":Stages.protocol_line(stage),"paperwork":_count(held,LETTERS)>0 or PERIODS.find(period)>=3,
		"rustic_props":period=="early" or (period=="ancient" and rank<3),
		"court_animals":period=="early"}

static func _count(held:Dictionary,ids:Array)->int:
	var count:=0
	for id in ids:
		if held.has(String(id)):count+=1
	return count
