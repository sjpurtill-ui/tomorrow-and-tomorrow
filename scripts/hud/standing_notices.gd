extends RefCounted
## WHAT STANDS NOW: the conditions and the people waiting on the god's answer
## that the one notice stack (hud/notification_stack.gd) keeps on screen for as
## long as they last. They are not news with a clock: a row stays while the
## thing is true and leaves the day it stops being true.
##
##   waiting   an envoy in the antechamber (audience_hall.gd): one click opens
##             the court;
##   now       what is wrong or under way (hud/army_alerts.gd: a band coming
##             at us, a battle, men hungry, will breaking, a hot feud, gear
##             short, bands thin, pay unpaid; trade turned against us
##             (hud/trade_alerts.gd); spies caught (covert_ops.gd)): one click
##             opens the screen that deals with it.
##
## Each row: {key, standing:true, kind ("waiting" or "now"), tone ("red",
## "amber" or "gold"), category, title, text, count, lines, action, verb (the
## one word on its button), days (days left, where it has a clock)}.
## Every row has its button, and every row is counted: the header's number
## is the rows that stand, and each rail button's badge is its share of
## them (rail_of). Red rows and those waiting stand first (urgent()).
## Nothing here is counted afresh: every line is the source's own.

const Alerts:=preload("res://scripts/hud/army_alerts.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const RED:=Color("#a8463a")
const AMBER:=Color("#a8782a")
const GOLD:=Color("#8a6118")
## Which notice category (its label and colour) an alert belongs to.
const CATEGORY:={"trade_against":"trade","trade_news":"trade","covert_caught":"spies","covert_done":"spies","unpaid":"trade"}
## Where a click goes, said in the row's tooltip.
const PAGE_WORDS:={"economy":"the Economy screen","military":"the War screen"}
## The one word on a row's button: what the god goes to do about it.
const VERBS:={"attack":"Defend","hungry":"Feed","gear":"Arm","men":"Recruit","unpaid":"Pay","trade_against":"Trade"}
const NO_CLOCK:=1000000


## Everything standing now: who waits first, then the conditions, worst first.
static func rows(mc:Node=null)->Array[Dictionary]:
	var out:Array[Dictionary]=waiting()
	out.append_array(home())
	for alert:Dictionary in Alerts.alerts(mc):out.append(from_alert(alert))
	return out


## What stands wrong at home and abroad, each once and each with its screen:
## food or water truly short (food_danger, water_danger), peoples who have
## moved against us (standing.gd's monthly reading), strangers in sight of
## our land (civilization_system.gd local_observation_snapshot).
static func home()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if WorldSimulation.state==null:return out
	var metrics:Dictionary=GameState.simulation_metrics
	var water:Dictionary=GameState.water_metrics
	var EraWords:=preload("res://scripts/hud/era_words.gd")
	if food_danger(metrics):
		var fact:="%s left · %d in 10 eat enough" % [EraWords.days(maxf(0.0,float(metrics.get("food_days",0.0)))),roundi(clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.0)*10.0)]
		out.append({"key":"standing:food","standing":true,"kind":"now","tone":"red","category":"food","title":"Food is running short","text":fact,"count":1,"lines":PackedStringArray([fact]),"verb":"Feed","days":NO_CLOCK,
			"action":{"kind":"section","section":"economy","sub":0,"label":"the Economy screen"}})
	if water_danger(water):
		var fact:="%d in 10 drink enough" % roundi(clampf(float(water.get("intake_ratio",1.0)),0.0,1.0)*10.0)
		out.append({"key":"standing:water","standing":true,"kind":"now","tone":"red","category":"food","title":"Water is running short","text":fact,"count":1,"lines":PackedStringArray([fact]),"verb":"Water","days":NO_CLOCK,
			"action":{"kind":"section","section":"economy","sub":0,"label":"the Economy screen"}})
	# Regard is available in World; a persistent opinion is not an interruption.
	var seen:=int(CivilizationSystem.local_observation_snapshot().get("visible_count",0))
	if seen>0:
		var fact:="%d of theirs seen near our land" % seen
		out.append({"key":"standing:strangers","standing":true,"kind":"now","tone":"amber","category":"neighbours","title":"Strangers in sight","text":fact,"count":seen,"lines":PackedStringArray([fact]),"verb":"See","days":NO_CLOCK,
			"action":{"kind":"section","section":"world","sub":0,"label":"the World screen"}})
	return out


## Food truly short: an interruption, not a live gauge. Reserve size crosses
## round numbers every day; only a sustained shortfall, or a bare store
## still falling (food_care.gd), counts.
static func food_danger(metrics:Dictionary)->bool:
	var intake:=clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var days:=maxf(0.0,float(metrics.get("food_days",30.0)))
	return GameState.consecutive_food_shortage_days>=2.0 or intake<0.90 or (preload("res://scripts/food_care.gd").store_level(days)=="bare" and float(metrics.get("food_net",0.0))<0.0)


## Water truly short: two days running with people going thirsty.
static func water_danger(water:Dictionary)->bool:
	return maxf(0.0,float(water.get("required_today",0.0)))>0.0 and GameState.consecutive_water_shortage_days>=2.0 and clampf(float(water.get("intake_ratio",1.0)),0.0,1.0)<0.95


## Envoys waiting on an answer: the only visitors who come unbidden.
static func waiting()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if WorldSimulation.state==null:return out
	var today:=int(WorldSimulation.state.elapsed_days)
	for audience:Dictionary in (load("res://scripts/audience_hall.gd") as GDScript).call("waiting"):
		if String(audience.get("origin",""))!="foreign":continue
		var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
		var people:=String(audience.get("civ_name",""))
		var who:=String(speaker.get("name",""))
		var left:=int(audience.get("expires_day",today))-today
		var line:=("%s waits · " % who if who!="" else "Waiting · ")+("leaves in %d %s" % [left,"day" if left==1 else "days"] if left>0 else "leaves today")
		out.append({"key":"standing:envoy:%s" % String(audience.get("id","")),"standing":true,"kind":"waiting","tone":"gold","category":"neighbours","verb":"Answer","days":maxi(0,left),
			"title":"Envoy of %s" % people if people!="" else "An envoy","text":line,"count":1,"lines":PackedStringArray([line]),
			"day":int(audience.get("arrived_day",today)),"action":{"kind":"court","focus":{},"label":"the court"}})
	return out


## One alert of hud/army_alerts.gd as a standing row.
static func from_alert(alert:Dictionary)->Dictionary:
	var id:=String(alert.get("id",""))
	var lines:PackedStringArray=alert.get("lines",PackedStringArray())
	# One fact line: the source's short form where it gives one, else its first line.
	var text:=String(alert.get("fact",""))
	if text=="":text=String(lines[0]) if not lines.is_empty() else ""
	# More than one: said in the line itself, never a bare number beside it.
	if lines.size()>1:text+=" · +%d more" % (lines.size()-1)
	var dock:Array=alert.get("dock",[]) if alert.get("dock") is Array else []
	var action:Dictionary
	if dock.size()==2:action={"kind":"section","section":String(dock[0]),"sub":int(dock[1]),"label":String(PAGE_WORDS.get(String(dock[0]),"the page it is about"))}
	else:action={"kind":"war","page":String(alert.get("page","forces")),"label":"the War screen"}
	return {"key":"standing:"+id,"standing":true,"kind":"now","tone":String(alert.get("tone","amber")),"category":String(CATEGORY.get(id,"war")),
		"title":String(alert.get("title","")),"text":text,"count":int(alert.get("count",1)),"lines":lines,"action":action,"alert":alert,"verb":String(VERBS.get(id,"See")),"days":int(alert.get("days",NO_CLOCK))}


static func tone_color(tone:String)->Color:
	return RED if tone=="red" else (GOLD if tone=="gold" else AMBER)


## The row's glyph: the alert's own (a war, logistics, goods or command
## glyph); an envoy's is the neighbours' mark.
static func icon(row:Dictionary)->Texture2D:
	var tone:=tone_color(String(row.get("tone","amber")))
	var alert:Dictionary=row.get("alert",{}) if row.get("alert") is Dictionary else {}
	if alert.has("war"):return Icons.war_texture(String(alert.war),tone,64)
	if alert.has("logistics"):return Icons.logistics_texture(String(alert.logistics),tone.darkened(0.15),64)
	if alert.has("resource"):return Icons.texture_for(String(alert.resource))
	if alert.has("glyph"):return Icons.command_texture(String(alert.glyph),tone.darkened(0.15),64)
	return Icons.moment_texture("contact",tone,64)


## The pointer's words: the title, every line, and where a click goes.
static func tip(row:Dictionary)->String:
	var action:Dictionary=row.get("action",{}) if row.get("action") is Dictionary else {}
	return "%s\n%s\nClick to open %s." % [String(row.get("title","")),"\n".join(row.get("lines",PackedStringArray()) as PackedStringArray),String(action.get("label","it"))]


## Whether a row will not wait: someone waits on an answer, or it is red.
static func urgent(row:Dictionary)->bool:
	return String(row.get("kind",""))=="waiting" or String(row.get("tone",""))=="red"


## The column's order for what stands: threats first, then by days left
## (a band here in 6 days stands above an envoy leaving in 9), then the
## rest that need the god, then what only wants seeing to.
static func sorted(list:Array[Dictionary])->Array[Dictionary]:
	var out:Array[Dictionary]=list.duplicate()
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _rank(a)<_rank(b))
	return out


static func _rank(row:Dictionary)->int:
	var id:=String((row.get("alert",{}) as Dictionary).get("id","")) if row.get("alert") is Dictionary else ""
	var days:=mini(int(row.get("days",NO_CLOCK)),9999)
	if id in ["attack","battle"]:return days
	if urgent(row):return 10000+days
	return 30000


## The rail button a row belongs to: "military", "economy", "world", ...
## An envoy belongs to World: that is where other peoples are.
static func rail_of(row:Dictionary)->String:
	var action:Dictionary=row.get("action",{}) if row.get("action") is Dictionary else {}
	match String(action.get("kind","")):
		"war","battle":return "military"
		"court","prisoner":return "world"
		"section":
			var category:Dictionary=preload("res://scripts/hud/command_rail_hud.gd").category_of(String(action.get("section","")))
			return String(category.get("id",""))
	return ""
