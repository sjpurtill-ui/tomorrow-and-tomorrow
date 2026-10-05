extends RefCounted
## Read-only speech subjects. A purpose is an intention, never a new benefit or
## an invented event in the settlement's history.
const Design:=preload("res://scripts/hud/great_work_design.gd")
const FOCUS:={
	"form:ring":"the circle of uprights",
	"form:mound":"the rise of the terraced earthwork",
	"form:stair":"the long ascent of the stair",
	"form:tower":"the tower rising above its footings",
	"form:hall":"the gathering space beneath the great roof",
	"form:cistern":"the basin at the heart of the water court",
	"form:granary":"the storehouses lifted above the ground",
	"form:bridge":"the spans carrying the crossing",
	"form:causeway":"the raised road stretching across the ground",
	"form:dam":"the river wall and its spillways",
	"form:colossus":"the great figure above its plinth",
	"form:garden":"the planting beds and garden walks",
	"form:observatory":"the court turned toward the heavens",
	"form:gate":"the threshold between the gatehouses",
	"form:canal":"the waterway between its banks",
	"form:archive":"the galleries surrounding the reading court",
	"form:amphitheatre":"the rising tiers around the open stage",
	"form:lighthouse":"the lantern crowning the beacon tower",
	"legacy:ancestor_ring":"the ancestor stones around the remembrance circle",
	"legacy:great_hall":"the long frame sheltering the many hearths",
	"legacy:rain_court":"the collecting basin and its rain channels",
	"legacy:flood_terraces":"the planted terraces climbing the high ground",
	"legacy:star_steps":"the sky steps and their sighting stones",
	"legacy:kiln_court":"the firing chambers around the kiln court",
	"legacy:long_song":"the sounding galleries of the singers' hall",
	"legacy:common_stores":"the raised bins around the covenant court",
	"legacy:safe_passage":"the open thresholds of the sanctuary",
	"legacy:living_orchard":"the groves along the orchard walks",
	"legacy:stone_crown":"the crown of terraces upon the ridge",
	"legacy:measures_house":"the paired halls of the measuring court",
}
const VOWS:={
	"honor_dead":"to honour those we remember",
	"bind_tribes":"to give our people a common promise",
	"tame_flood":"to meet the force of the waters",
	"feed_people":"to provide for the people",
	"watch_heavens":"to study the heavens",
	"awe_rivals":"to show our resolve before our rivals",
	"remember_knowledge":"to keep knowledge for those who follow",
	"welcome_strangers":"to welcome those who come as strangers",
	"master_craft":"to honour the skill of the makers",
	"defy_gods":"to declare our defiance of the gods",
	"mark_triumph":"to remember the triumph named in its purpose",
	"give_thanks":"to give thanks",
}

static func subjects(ctx:Dictionary)->Dictionary:
	var design:=Design.describe({"id":String(ctx.get("key",""))})
	return {"work_detail":String(FOCUS.get(design.design_id,"the work before us")),
		"purpose_vow":String(VOWS.get(design.purpose,"to give this place meaning"))}
