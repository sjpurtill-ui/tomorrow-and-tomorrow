extends RefCounted
## THE NOTICES: one list of what the player is told, shown in one place (the
## stack at the top right, hud/notification_stack.gd) and kept in a short log.
##
## Every notice has:
##   category  what it is about (War, People, Food & Water, Court, Learning,
##             Building, Trade, Spies, Weather, Neighbours, Scouts, Travel,
##             Faith, Sickness); its colour and procedural icon come from here;
##   tier      urgent  stays until dismissed, highlighted (asks the god's hand);
##             notable stays NOTABLE_SECONDS, then goes to the log;
##             minor   never pops up; the log keeps it;
##             card    the Chronicle's illustrated moment card tells it
##                     (hud/chronicle_card.gd); the log keeps it;
##   title     what happened, in a few words;
##   text      one plain sentence: where, and why it matters, with numbers;
##   action    what a click opens (the same shapes as the Chronicle's card:
##             court, prisoner, scout_report, battle, section, ceremony, plus
##             "map" {x,z} and "call" {callable}).
##
## Sources:
##   - the Chronicle (chronicle.gd record() queues what it tells in
##     Chronicle.pending_notes; from_chronicle() turns each into a notice);
##   - anything else calls NotificationModel.push({...}) with the fields above
##     (a missing tier is "notable", a missing category "story").
## Repeats merge: a notice whose group (default: category and title) matches
## one still on screen raises that one's count instead of adding another.
##
## Presentation only: nothing here changes the game. The log lives for the
## session; the Chronicle is the record that is saved.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

const NOTABLE_SECONDS:=9.0
const HISTORY_MAX:=80
const PENDING_MAX:=40
const TIERS:=["minor","card","notable","urgent"]

## id: [label, colour, icon family, icon id]
const CATEGORIES:={
	"war":["War",Color("a34435"),"moment","war"],
	"people":["People",Color("5d6f34"),"domain","demography"],
	"food":["Food & Water",Color("8a6118"),"moment","hunger"],
	"health":["Sickness",Color("6c7428"),"moment","sickness"],
	"court":["Court",Color("7a5414"),"moment","court"],
	"learning":["Learning",Color("4d6389"),"moment","discovery"],
	"building":["Building",Color("6e5636"),"domain","infrastructure"],
	"trade":["Trade",Color("356f66"),"domain","wealth"],
	"spies":["Spies",Color("695587"),"moment","stranger"],
	"weather":["Weather",Color("3f6c86"),"domain","ecology"],
	"neighbours":["Neighbours",Color("94582a"),"moment","contact"],
	"scouts":["Scouts",Color("4f6f3a"),"moment","scout"],
	"travel":["Travel",Color("6c5a2e"),"domain","logistics"],
	"faith":["Faith",Color("6f5585"),"moment","omen"],
	"land":["Land & Finds",Color("7b5a2c"),"domain","production"],
	"aims":["Aims",Color("8a6118"),"moment","milestone"],
	"story":["Chronicle",Color("6b5a3e"),"moment","hearth_count"],
}

## Chronicle card kinds to categories.
const KIND_CATEGORY:={"war":"war","contact":"neighbours","scout":"scouts","court":"court","death":"people","birth":"people",
	"discovery":"learning","settlement":"building","founding":"people","ceremony":"faith","omen":"faith","milestone":"people",
	"hearth_count":"people","drought":"weather","flood":"weather","cold":"weather","fire":"building","sickness":"health",
	"hunger":"food","thinning":"food","stranger":"spies","annal":"story"}
## Ledger domains to categories.
const DOMAIN_CATEGORY:={"nutrition":"food","food":"food","water":"food","infrastructure":"building","construction":"building","production":"building",
	"wealth":"trade","trade":"trade","economy":"trade","security":"war","military":"war","health":"health","knowledge":"learning",
	"demography":"people","population":"people","ecology":"weather","weather":"weather","institutions":"court","court":"court",
	"logistics":"travel","settlement":"building","diplomacy":"neighbours","culture":"faith","labor":"people"}
## Words that settle a category when kind and domain do not (checked in order).
const WORD_CATEGORY:=[
	["spy","spies"],["spies","spies"],["agent","spies"],["assassin","spies"],["saboteur","spies"],["informer","spies"],
	["caravan","travel"],["barter","trade"],["trade","trade"],["market","trade"],["goods","trade"],
	["flood","weather"],["drought","weather"],["storm","weather"],["frost","weather"],["snow","weather"],[" rain","weather"],["dry year","weather"],
	["thirst","food"],["water","food"],[" well","food"],["food","food"],["hunger","food"],["harvest","food"],["stores","food"],["famine","food"],["granary","food"],
	["sick","health"],["fever","health"],["plague","health"],["outbreak","health"],
	["scout","scouts"],["battle","war"],["raid","war"],["siege","war"],["besieg","war"],["war","war"],["feud","war"],["band","war"],
	["built","building"],["raised","building"],["hall","building"],["wall","building"],["road","building"],
	["envoy","neighbours"],["stranger","neighbours"],["neighbour","neighbours"],
	["order","court"],["council","court"],["official","court"],["heir","court"],
	["born","people"],["died","people"],["buried","people"],["people","people"],
]
## The primary notices: the only routine lines that pop up. War, strangers
## and envoys, hunger and thirst, weather and sickness, spies, what came of the
## god's orders, a great work, a death in the court, a first in learning. Every
## other told line (a town built, a birth, a scout's sighting, a road report)
## goes to the log.
const PRIMARY_CATEGORIES:=["war","neighbours","food","health","weather","spies","court"]
const PRIMARY_KINDS:=["fire","ceremony","death","founding"]
const PRIMARY_KEYS:=["great_work","court:","crisis:","town_fate:"]
## Told lines that ask the god to act: urgent.
const URGENT_KEYS:=["crisis:","war:declared:","war:raid:","war:battle:","town_fate:","court_war:","split_food:"]

## From the content audit of the player's own Chronicle (year 150 save,
## codex/notifications): what each frequent line is about, whether it pops
## up, and where a click goes. [key prefix, category, tier ("" keeps the
## graded tier), action ({} keeps the card's own)].
const KEY_RULES:=[
	["split_food:","food","urgent",{"kind":"section","section":"settlement","sub":0,"label":"the town and its work"}],
	["split_fed:","food","notable",{"kind":"section","section":"settlement","sub":0,"label":"the town and its work"}],
	# A cairn or fire raised for an order or the dead: told on the map, kept in the log.
	["court:rite:","faith","minor",{}],
	["land_find:","land","",{}],
	["work_done:","building","",{}],
	["aim:","aims","",{}],
	["annal:","story","",{}],
	["age:","story","",{}],
	["court:death:","people","",{}],
	["genius","people","",{}],
	["leaders_founded:","people","",{}],
	["business_","trade","",{}],
	["demo|","people","",{}],
]
## The clerk's ledger titles (key "ev|day|Title|..."): their category, tier
## and a plainer headline ("" keeps the title). An order is already tracked
## card by card at the bottom right ("Your orders"), so only its outcome pops up.
const LEDGER_RULES:={
	"Directive Issued":["court","minor","Your order is under way"],
	"Your Order Is Being Carried Out":["court","minor","Your order is being carried out"],
	"Directive Succeeded":["court","notable","Your order took hold"],
	"Directive Partly Succeeded":["court","notable","Your order partly took hold"],
	"Directive Failed":["court","notable","Your order failed"],
	"Settlement Named":["people","minor","A town is named"],
	"The Court Changes":["court","notable",""],
	"SCOUTS LOST":["scouts","notable","A scout party is lost"],
	"Drinking Water Is Short":["food","urgent",""],
}

## Notices waiting for the stack to show them (any system may push).
static var pending:Array[Dictionary]=[]
## The session's log, newest first.
static var history:Array[Dictionary]=[]
static var _serial:=0


static func push(notice:Dictionary)->Dictionary:
	var n:=normalize(notice)
	if n.is_empty():return {}
	pending.append(n)
	while pending.size()>PENDING_MAX:pending.pop_front()
	return n


static func normalize(notice:Dictionary)->Dictionary:
	var title:=String(notice.get("title","")).strip_edges()
	var text:=String(notice.get("text","")).strip_edges()
	if title.is_empty() and text.is_empty():return {}
	if title.is_empty():
		title=_first_sentence(text).trim_suffix(".")
		text=text.substr(_first_sentence(text).length()).strip_edges()
	_serial+=1
	var n:=notice.duplicate(true)
	n["id"]=_serial
	n["title"]=title.left(90)
	n["text"]=one_sentence(text)
	var category:=String(notice.get("category",""))
	n["category"]=category if CATEGORIES.has(category) else "story"
	var tier:=String(notice.get("tier","notable"))
	n["tier"]=tier if tier in TIERS else "notable"
	if not n.has("day"):n["day"]=int(GameState.elapsed_days) if Engine.get_main_loop()!=null else 0
	if String(n.get("group","")).is_empty():n["group"]="%s|%s" % [n.category,_family(String(n.title))]
	n["count"]=maxi(1,int(notice.get("count",1)))
	return n


## A Chronicle entry (chronicle.gd record) as a notice. `mode` is the
## player's discovery setting (GameState.research_notification_mode).
static func from_chronicle(entry:Dictionary,mode:String="milestones")->Dictionary:
	var category:=category_of(entry)
	var tier:=tier_of(entry,category,mode)
	var title:=String(entry.get("title",""))
	var action:Dictionary=(entry.get("action",{}) as Dictionary).duplicate(true) if entry.get("action") is Dictionary else {}
	var key:=String(entry.get("key",""))
	var rule:=rule_for(key)
	if not rule.is_empty():
		category=String(rule.category)
		if String(rule.tier)!="" and tier!="card":tier=String(rule.tier)
		if String(rule.get("title",""))!="":title=String(rule.title)
		if not (rule.get("action",{}) as Dictionary).is_empty():action=(rule.action as Dictionary).duplicate(true)
	var notice:={"source":"chronicle","key":key,"title":title,"text":String(entry.get("base_text",entry.get("text",""))),
		"category":category,"tier":tier,"day":int(entry.get("day",0)),"action":action}
	# A repeat the Chronicle folded into an earlier card: it counts on that
	# notice, and never pops up by itself.
	if String(entry.get("same_as",""))!="":
		notice["merge_key"]=String(entry.same_as)
		if tier!="urgent":notice["tier"]="minor"
	var group:=String(entry.get("fold_as",entry.get("family","")))
	if group!="":notice["group"]="%s|%s" % [category,group]
	return normalize(notice)


## The audit's rule for a told line's key ({} when none): category, tier,
## title and action.
static func rule_for(key:String)->Dictionary:
	if key.begins_with("ev|"):
		var title:=key.get_slice("|",2)
		if LEDGER_RULES.has(title):
			var r:Array=LEDGER_RULES[title]
			return {"category":String(r[0]),"tier":String(r[1]),"title":String(r[2])}
		return {}
	for r:Array in KEY_RULES:
		if key.begins_with(String(r[0])):return {"category":String(r[1]),"tier":String(r[2]),"action":r[3]}
	return {}


static func category_of(entry:Dictionary)->String:
	var tagged:=String(entry.get("category",""))
	if CATEGORIES.has(tagged):return tagged
	var ruled:=rule_for(String(entry.get("key","")))
	if not ruled.is_empty():return String(ruled.category)
	var action:Dictionary=entry.get("action",{}) if entry.get("action") is Dictionary else {}
	match String(action.get("kind","")):
		"prisoner":return "spies"
		"scout_report":return "scouts"
		"battle":return "war"
		"ceremony":return "faith"
	var key:=String(entry.get("key",""))
	if key.begins_with("war") or key.begins_with("court_war") or key.begins_with("aftermath"):return "war"
	if key.begins_with("spy") or key.begins_with("captive") or key.begins_with("prisoner"):return "spies"
	if key.begins_with("discovery:") or key.begins_with("learned:"):return "learning"
	if key.begins_with("build") or key.begins_with("great_work") or key.begins_with("construction"):return "building"
	if key.begins_with("court:callback") or key.begins_with("court:succession") or key.begins_with("court:rival"):return "court"
	var lower:=(" "+String(entry.get("title",""))+" ").to_lower()
	var kind:=String(entry.get("kind",""))
	# The kind of the card, unless the words say plainly what it is about.
	if kind in ["war","scout","discovery","contact","death","birth","omen","ceremony","drought","flood","cold","sickness","hunger","thinning","stranger"]:
		return String(KIND_CATEGORY[kind])
	for pair in WORD_CATEGORY:
		if lower.contains(String(pair[0])):return String(pair[1])
	if KIND_CATEGORY.has(kind):return String(KIND_CATEGORY[kind])
	var domain:=String(entry.get("domain",""))
	if DOMAIN_CATEGORY.has(domain):return String(DOMAIN_CATEGORY[domain])
	return "story"


static func tier_of(entry:Dictionary,category:String,mode:String="milestones")->String:
	var tier:=String(entry.get("tier","notice"))
	var key:=String(entry.get("key",""))
	var action:Dictionary=entry.get("action",{}) if entry.get("action") is Dictionary else {}
	var urgent:=bool(entry.get("alert",false)) or String(action.get("kind",""))=="prisoner"
	for prefix in URGENT_KEYS:
		if key.begins_with(prefix):urgent=true
	if tier=="moment":return "card"
	if tier=="whisper":return "urgent" if urgent and not bool(entry.get("folded",false)) else "minor"
	if urgent:return "urgent"
	# The player's own discovery setting: "quiet" keeps learning in the log;
	# "milestones" pops up only the firsts and turnings (the Chronicle's card
	# tells those), so a season's tally of what was learned stays in the log.
	if category=="learning" and (mode=="quiet" or (mode=="milestones" and not bool(entry.get("first",false)))):return "minor"
	return "notable" if is_primary(entry,category) else "minor"


## True for the few told lines that pop up (see PRIMARY_CATEGORIES). A first in
## learning is primary: tier_of has already put the season's tally in the log.
static func is_primary(entry:Dictionary,category:String)->bool:
	if category=="learning":return true
	if category in PRIMARY_CATEGORIES or String(entry.get("kind","")) in PRIMARY_KINDS:return true
	var key:=String(entry.get("key",""))
	for prefix in PRIMARY_KEYS:
		if key.begins_with(prefix):return true
	return false


## The one sentence a notice shows: the first sentence of `text`, cut at a
## word if it runs long.
static func one_sentence(text:String,limit:int=190)->String:
	var first:=_first_sentence(text.strip_edges())
	# A short first sentence keeps the next one when both fit ("Memi died
	# aged 37. She kept the stores through the lean seasons.").
	var rest:=text.strip_edges().substr(first.length()).strip_edges()
	if first.length()<90 and rest!="":
		var second:=_first_sentence(rest)
		if first.length()+1+second.length()<=limit:first=first+" "+second
	if first.length()<=limit:return first
	var cut:=first.left(limit)
	var space:=cut.rfind(" ")
	if space>limit/2:cut=cut.left(space)
	return cut.strip_edges().trim_suffix(",").trim_suffix(";").trim_suffix(":")+"…"


static func _first_sentence(text:String)->String:
	var clean:=text.strip_edges()
	for i in clean.length():
		if clean[i] in [".","!","?"] and (i==clean.length()-1 or clean[i+1]==" "):
			# "Mr." style stops are rare in this game's words; a quote closing
			# after the stop belongs to the sentence.
			var end:=i+1
			if end<clean.length() and clean[end] in ["”","\"","’"]:end+=1
			return clean.left(end)
	return clean


static func _family(title:String)->String:
	var words:PackedStringArray=[]
	for word in title.to_lower().split(" ",false):
		if word.is_valid_int():continue
		words.append(word.trim_suffix(",").trim_suffix("."))
	return " ".join(words).left(40)


## Merges `incoming` into `existing` (same group or key): one more time, and
## the newest words. Returns `existing`.
static func merge(existing:Dictionary,incoming:Dictionary)->Dictionary:
	existing["count"]=int(existing.get("count",1))+maxi(1,int(incoming.get("count",1)))
	if String(incoming.get("text",""))!="":existing["text"]=String(incoming.text)
	existing["latest_title"]=String(incoming.get("title",existing.get("title","")))
	existing["day"]=int(incoming.get("day",existing.get("day",0)))
	if TIERS.find(String(incoming.get("tier","")))>TIERS.find(String(existing.get("tier",""))) and String(incoming.tier)!="card":existing["tier"]=String(incoming.tier)
	return existing


## True when `incoming` adds to `existing` instead of standing alone.
static func same(existing:Dictionary,incoming:Dictionary)->bool:
	if String(incoming.get("merge_key",""))!="" and String(incoming.merge_key)==String(existing.get("key","")):return true
	if String(incoming.get("key",""))!="" and String(incoming.key)==String(existing.get("key","")):return true
	return String(existing.get("group",""))!="" and String(existing.get("group",""))==String(incoming.get("group",""))


## The headline as shown: the title, and with repeats, how many ("3 scout
## parties came home" when the source gave a "plural" form).
static func headline(n:Dictionary)->String:
	var count:=int(n.get("count",1))
	if count>1 and String(n.get("plural",""))!="":return String(n.plural) % count
	# A repeat shows the newest line's own words ("Ochre earth found near
	# Koka"), and the count says how many came.
	if count>1 and String(n.get("latest_title",""))!="":return String(n.latest_title)
	return String(n.get("title",""))


static func count_words(n:Dictionary)->String:
	var count:=int(n.get("count",1))
	if count<=1 or String(n.get("plural",""))!="":return ""
	return "%d times" % count


static func label(category:String)->String:
	return String((CATEGORIES.get(category,CATEGORIES.story) as Array)[0])


static func color(category:String)->Color:
	var base:Color=(CATEGORIES.get(category,CATEGORIES.story) as Array)[1]
	if T.is_light():return T.legible(base,T.PAPER_RAISED,4.5)
	return T.legible(base.lightened(0.35),T.PAPER_RAISED,4.5)


static func icon(category:String,px:int=48)->Texture2D:
	var spec:Array=CATEGORIES.get(category,CATEGORIES.story)
	var accent:Color=spec[1]
	if String(spec[2])=="domain":return Icons.domain_texture(String(spec[3]),accent)
	return Icons.moment_texture(String(spec[3]),accent,px)


static func date_words(day:int)->String:
	return preload("res://scripts/chronicle.gd").date_label(day)


## Adds `n` to the session's log (merging a repeat of the newest same notice).
static func remember(n:Dictionary)->void:
	for kept in history.slice(0,6):
		if same(kept,n) and int(n.get("day",0))-int(kept.get("day",0))<=30:
			merge(kept,n)
			return
	history.push_front(n.duplicate(true))
	while history.size()>HISTORY_MAX:history.pop_back()


static func reset()->void:
	pending.clear();history.clear();_serial=0
