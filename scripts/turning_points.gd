extends RefCounted
## TURNING POINTS: the few discoveries that change what the god sees or can do.
##
## The people learn three to five practices a year; nearly all of them are
## told once a season in the Chronicle's digest. About once every five to ten
## years one of them turns daily life: pots at every hearth, the first sown
## ground, a tame herd, clean water. When it does, it gets its own moment card
## with a plain "What changes" line, and the change is real:
##   - a new choice at court (crisis_system.gd reads unlocks()),
##   - a new building at the camp (settlement_construction priority), or
##   - a mark on the map (a rite of dedication, court_lives rites).
## Only practices the people really know can turn; the card comes when the
## practice is known and the last turning point is at least five years past.
## Names and words are generic (alternative history).
##
## State lives in ForeignDiplomacy.audiences["turning_points"] (saved with the
## court; older saves start empty and tell nothing already past as new).

const Chronicle:=preload("res://scripts/chronicle.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const CONSTRUCTION:=preload("res://scripts/settlement_construction.gd")

const KEY:="turning_points"
const VERSION:=1
const FIRST_AFTER_DAYS:=3*365
const GAP_DAYS:=5*365

## In order of how much each changes daily life.
const POINTS:=[
	{"id":"planting","ids":["seed_selection","crop_calendars","managed_fallow"],"title":"The First Sown Ground",
		"text":"Seed kept back from the best plants now goes into cleared ground each spring, and the people wait for it to come up.",
		"changes":"In a hungry season you can order the seed eaten; in a dry year, the seed that needs little water can be sown.",
		"unlocks":["hunger:seed","drought:hardy_seed"],"rite":"stone","label":"the first sown ground"},
	{"id":"pots","ids":["clay_shaping","pit_firing","clay_tempering"],"title":"Pots at Every Hearth",
		"text":"Clay shaped by hand and fired in the pit: every hearth has pots now, for water and for boiling.",
		"changes":"When the stores run low you can order the pots kept boiling, which stretches food without cutting portions.",
		"unlocks":["hunger:pots"],"rite":"bonfire","label":"the first firing"},
	{"id":"herd","ids":["animal_taming"],"title":"The First Tame Herd",
		"text":"A few animals follow the people now, and sleep at the edge of the camp.",
		"changes":"In a hungry winter you can order animals killed from the herd.",
		"unlocks":["hunger:herd"],"rite":"procession","label":"the herd brought in"},
	{"id":"plants","ids":["herbal_classification","dietary_healing_regimens","poultices"],"title":"Those Who Know the Plants",
		"text":"Some among the people know which roots and leaves cool a fever and which ones kill.",
		"changes":"When sickness comes you can send for the plant-knowers, and fevers break sooner.",
		"unlocks":["sickness:herbs"],"rite":"cairn","label":"the plant-knowers"},
	{"id":"clean_water","ids":["household_water_boiling","clean_water"],"title":"Clean Water",
		"text":"Water for drinking is boiled now, or drawn above the camp and never below it.",
		"changes":"When the flux comes you can order the water boiled and the drinking place moved upstream.",
		"unlocks":["sickness:water"],"rite":"stone","label":"the clean spring"},
	{"id":"apart","ids":["contagion_avoidance_customs","fever_watch_customs","sickness_pattern_memory"],"title":"The Sick Kept Apart",
		"text":"The people have learned to watch for the first fever and to give the sick their own fire.",
		"changes":"Keeping the sick apart now works far better, and your officials do it on their own if you are silent.",
		"unlocks":["sickness:apart_plus"],"rite":"cairn","label":"the fire for the sick"},
	{"id":"counting","ids":["tallies","counting_words","mouths_against_store"],"title":"The Counting of Stores",
		"text":"A notch on a stick for every basket in the pits, and another for every mouth at the fire.",
		"changes":"The court now hears of a hungry season about a month sooner, while there is still time to act.",
		"unlocks":["hunger:early"],"rite":"stone","label":"the tally stick"},
	{"id":"boats","ids":["hide_floats","river_craft"],"title":"The First Boats",
		"text":"Hides stretched over frames, and hollowed logs: the people go out on the water now.",
		"changes":"In a flood you can order the stores and the old taken out by boat.",
		"unlocks":["flood:boats"],"rite":"procession","label":"the first boats"},
	{"id":"mounds","ids":["flood_house_mounds"],"title":"Houses on Mounds",
		"text":"The newest huts stand on raised earth, above the reach of the high water.",
		"changes":"Floods now reach fewer homes, and after one you can order the huts raised on mounds.",
		"unlocks":["flood:mounds"],"rite":"cairn","label":"the first mound"},
	{"id":"earth_walls","ids":["adobe_wall_construction","mould_made_mudbricks","dry_stone_walls"],"title":"Walls That Do Not Burn",
		"text":"Walls of packed earth and stone go up where there were only poles and hide.",
		"changes":"After a fire you can order the huts rebuilt in earth that will not burn.",
		"unlocks":["fire:earth"],"rite":"stone","label":"the first earth wall"},
	{"id":"common_store","ids":["public_stores"],"title":"The Common Store",
		"text":"The people agree to keep a counted store in common, watched by someone chosen for it.",
		"changes":"A common store is being built at the camp; you will see it rise on the map.",
		"unlocks":[],"building":"Public Stores","rite":"procession","label":"the common store"},
	{"id":"framed_hall","ids":["framed_construction"],"title":"The First Framed Hall",
		"text":"Posts set deep and beams laid across them: a roof big enough for everyone.",
		"changes":"A framed hall is being built at the camp; you will see it rise on the map.",
		"unlocks":[],"building":"Framed Hall","rite":"procession","label":"the framed hall"},
]

static func state()->Dictionary:
	# The court block is replaced when a new world begins: read it fresh.
	ForeignDiplomacy.ensure()
	var raw:Variant=ForeignDiplomacy.audiences.get(KEY,{})
	var s:Dictionary=raw if raw is Dictionary else {}
	if not s.is_empty() and (int(s.get("world_seed",GameState.world_seed))!=int(GameState.world_seed) or float(s.get("last_day",0))>GameState.elapsed_days+1.0): s.clear()
	if int(s.get("version",0))!=VERSION:
		if not s.get("told") is Dictionary: s["told"]={}
		for key in ["last","last_day"]:
			if not (s.get(key) is int or s.get(key) is float): s[key]=-99999 if key=="last" else 0
		s["world_seed"]=int(GameState.world_seed)
		s["version"]=VERSION
		# A save from before turning points: what was learned long ago is not
		# announced as new; the next one to turn comes in due course.
		if GameState.elapsed_days>float(FIRST_AFTER_DAYS) and not GameState.known_discoveries.is_empty():
			for point in POINTS:
				if _known(point): (s.told as Dictionary)[String(point.id)]=-1
			s.last=int(GameState.elapsed_days)-GAP_DAYS/2
	ForeignDiplomacy.audiences[KEY]=s
	return s

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.has("told") and (not d.told is Dictionary or (d.told as Dictionary).size()>POINTS.size()+4): return false
	return JSON.stringify(d).length()<8000

static func _known(point:Dictionary)->bool:
	for id in point.ids:
		if String(id) in GameState.known_discoveries: return true
	return false

static func unlocks(option_key:String)->bool:
	var told:Dictionary=state().told
	for point in POINTS:
		if told.has(String(point.id)) and option_key in (point.get("unlocks",[]) as Array): return true
	return false

static func told()->Array[String]:
	var out:Array[String]=[]
	for key in state().told: out.append(String(key))
	return out

static func daily(day:int)->Dictionary:
	## Tells at most one turning point, when its time has come. Returns it.
	if GameState.settlement_founded_day<0: return {}
	var s:=state()
	s.last_day=day
	if day-GameState.settlement_founded_day<FIRST_AFTER_DAYS or day-int(s.last)<GAP_DAYS: return {}
	var told_map:Dictionary=s.told
	for point in POINTS:
		if told_map.has(String(point.id)) or not _known(point): continue
		_tell(point,day)
		return point
	return {}

static func _tell(point:Dictionary,day:int)->void:
	var s:=state()
	(s.told as Dictionary)[String(point.id)]=day
	s.last=day
	var discovery_id:=""
	for id in point.ids:
		if String(id) in GameState.known_discoveries: discovery_id=String(id); break
	var building:=String(point.get("building",""))
	if building!="" and String(GameState.resource_settlement_id)!="":
		CONSTRUCTION.set_priority(String(GameState.resource_settlement_id),building)
	var rite:=String(point.get("rite",""))
	if rite!="": Lives._mark_rite(rite,String(point.get("label",point.title)),day,8)
	Chronicle.record({"key":"turning:%s" % String(point.id),"title":String(point.title),
		"text":"%s What changes: %s" % [String(point.text),String(point.changes)],"tier":"moment","priority":true,"kind":"discovery",
		"art":{"discovery_id":discovery_id},"action":{"kind":"section","section":"inquiry","sub":0},"domain":"knowledge","turning":String(point.id)})
