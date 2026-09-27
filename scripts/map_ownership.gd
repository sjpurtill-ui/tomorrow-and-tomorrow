extends RefCounted
## Who holds a known town, as the chart shows it: the mark on the map, the
## emblem on its card, and the plain words beside it. Our own holdings come
## from the world itself (our people know what they hold); everyone else's
## come from the last report, since that is all we know of them.
##
## status(report) -> {
##   kind:     "occupied" (a stranger's town we took and hold), "besieged"
##             (our siege is round it), "ruined" (burned or broken, as last
##             seen), "rival_capital" (a people's chief town), "foreign";
##   emblem:   whose emblem the card wears ("player" for a town we hold);
##   original: the people who held it before;
##   glyph:    its cell in resource_icons.settlement_atlas();
##   mark_px:  how large the mark is drawn (towns that matter read larger);
##   accent:   the holder's colour washed into the mark (alpha 0: none);
##   line:     who holds it, in words ("Ours · taken from the Esurai");
##   note:     since when, and who guards it ("Held since Year 87 · Spring");
##   garrison: fighters holding it for us (0 when none or not ours);
##   since:    the day it changed hands (-1 when unknown) }
const ICONS=preload("res://scripts/resource_icons.gd")
const Identity=preload("res://scripts/city_map_identity.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
## A report of this much damage or more reads as a burned or broken town.
const RUINED_DAMAGE:=0.6
## Mark sizes in design pixels: a plain stranger's town, and the ones that
## matter more (ours, a chief town, a siege).
const MARK_PX:=34.0
const MARK_PX_STRONG:=40.0

## Our hold on a stranger's town, from the world itself; {} when not ours.
static func player_hold(city_id:String)->Dictionary:
	var system:Node=CivilizationSystem
	if system==null or city_id.is_empty():return {}
	var location:Dictionary=system._region_location(city_id)
	if location.is_empty():return {}
	var civ:Dictionary=system.civilizations[int(location.owner_index)]
	var region:Dictionary=civ.strategic_regions[int(location.region_index)]
	var force:Dictionary=MilitaryCampaign.occupation_force_for_region(String(civ.id),city_id) if MilitaryCampaign!=null else {}
	if String(region.get("controller",""))!="player" and force.is_empty():return {}
	var since:=int(region.get("last_control_change_day",-1))
	if since<=0:since=int(force.get("committed_day",-1))
	return {"original":String(civ.id),"since":since,"garrison":maxi(0,int(force.get("troops",0))),"integration":float(region.get("integration",0.0))}

static func status(report:Dictionary)->Dictionary:
	var city_id:=String(report.get("city_id",""))
	var original:=String(report.get("civ_id",""))
	var hold:=player_hold(city_id)
	if not hold.is_empty():
		original=String(hold.original)
		var garrison:=int(hold.garrison)
		var note:="Held since "+EraWords.when(int(hold.since)) if int(hold.since)>=0 else "Held by us"
		note+=(" · %s hold it" % EraWords.grouped(garrison)) if garrison>0 else " · no one guards it"
		return {"kind":"occupied","emblem":"player","original":original,"glyph":ICONS.SETTLEMENT_GLYPH_OCCUPIED,"mark_px":MARK_PX_STRONG,
			"accent":_accent(original,0.55),"line":"Ours · taken from "+people(original),"note":note,"garrison":garrison,"since":int(hold.since)}
	var holder:=String(report.get("controller",""))
	if holder.is_empty():holder=original
	var result:={"kind":"foreign","emblem":holder,"original":original,"glyph":ICONS.SETTLEMENT_GLYPH_FOREIGN,"mark_px":MARK_PX,
		"accent":_accent(holder,0.8),"line":"","note":"","garrison":0,"since":-1}
	if holder=="player":
		# Our book says ours, the world no longer does: shown as we last knew it.
		result.kind="occupied";result.glyph=ICONS.SETTLEMENT_GLYPH_OCCUPIED;result.mark_px=MARK_PX_STRONG;result.line="Ours · taken from "+people(original)
	elif _our_siege(city_id):
		result.kind="besieged";result.glyph=ICONS.SETTLEMENT_GLYPH_BESIEGED;result.mark_px=MARK_PX_STRONG
		result.note="Our siege · day %d" % maxi(1,int(MilitaryCampaign.active_siege.get("days",0))+1)
	elif _damage(report)>=RUINED_DAMAGE:
		result.kind="ruined";result.glyph=ICONS.SETTLEMENT_GLYPH_RUINED;result.accent=Color(0,0,0,0)
		result.note="Burned or broken when last seen"
	elif not holder.is_empty() and holder==original and CivilizationSystem.city_intelligence.primary_id(holder)==city_id:
		result.kind="rival_capital";result.glyph=ICONS.SETTLEMENT_GLYPH_RIVAL_CAPITAL;result.mark_px=MARK_PX_STRONG-2.0
		result.note="Their chief town"
	return result

## "the Esurai", or "strangers" before we know their name.
static func people(civ_id:String)->String:
	var label:=String(CivilizationSystem.city_intelligence.controller_label(civ_id))
	if label in ["Unknown people","Unknown","Your settlement",""]:return "strangers"
	return "the "+label.substr(4) if label.to_lower().begins_with("the ") else "the "+label

static func _accent(civ_id:String,strength:float)->Color:
	if civ_id.is_empty() or civ_id=="player":return Color(0,0,0,0)
	var tint:Color=Identity.foreign(civ_id).get("accent",Color.WHITE)
	return Color(tint,strength)

static func _our_siege(city_id:String)->bool:
	if MilitaryCampaign==null:return false
	var siege:Dictionary=MilitaryCampaign.active_siege
	return bool(siege.get("active",false)) and String(siege.get("mode",""))=="offensive" and String(siege.get("region_id",""))==city_id

static func _damage(report:Dictionary)->float:
	var field:Dictionary=(report.get("fields",{}) as Dictionary).get("damage",{})
	if field.is_empty():return 0.0
	return (float(field.get("low",0))+float(field.get("high",0)))*0.5

## The chart's key: every kind of mark, as the map draws it, in plain words.
const LEGEND:=[
	{"glyph":2,"home":true,"words":"Our home"},
	{"glyph":1,"words":"Our town"},
	{"glyph":8,"words":"A town we took and hold"},
	{"glyph":7,"words":"A stranger's town, in its people's colour"},
	{"glyph":9,"words":"A people's chief town"},
	{"glyph":10,"words":"Under our siege"},
	{"glyph":11,"words":"Burned or ruined"},
]
