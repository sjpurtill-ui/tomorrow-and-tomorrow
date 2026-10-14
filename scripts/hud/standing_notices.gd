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
## "amber" or "gold"), category, title, text, count, lines, action, icon}.
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


## Everything standing now: who waits first, then the conditions, worst first.
static func rows(mc:Node=null)->Array[Dictionary]:
	var out:Array[Dictionary]=waiting()
	for alert:Dictionary in Alerts.alerts(mc):out.append(from_alert(alert))
	return out


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
		out.append({"key":"standing:envoy:%s" % String(audience.get("id","")),"standing":true,"kind":"waiting","tone":"gold","category":"neighbours",
			"title":"Envoy of %s" % people if people!="" else "An envoy","text":line,"count":1,"lines":PackedStringArray([line]),
			"day":int(audience.get("arrived_day",today)),"action":{"kind":"court","focus":{},"label":"the court"}})
	return out


## One alert of hud/army_alerts.gd as a standing row.
static func from_alert(alert:Dictionary)->Dictionary:
	var id:=String(alert.get("id",""))
	var lines:PackedStringArray=alert.get("lines",PackedStringArray())
	var text:=String(lines[0]) if not lines.is_empty() else ""
	if lines.size()>1:text+="  · +%d more" % (lines.size()-1)
	var dock:Array=alert.get("dock",[]) if alert.get("dock") is Array else []
	var action:Dictionary
	if dock.size()==2:action={"kind":"section","section":String(dock[0]),"sub":int(dock[1]),"label":String(PAGE_WORDS.get(String(dock[0]),"the page it is about"))}
	else:action={"kind":"war","page":String(alert.get("page","forces")),"label":"the War screen"}
	return {"key":"standing:"+id,"standing":true,"kind":"now","tone":String(alert.get("tone","amber")),"category":String(CATEGORY.get(id,"war")),
		"title":String(alert.get("title","")),"text":text,"count":int(alert.get("count",1)),"lines":lines,"action":action,"alert":alert}


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


## What will not wait, for the red count on the rail's War button.
static func urgent_count(list:Array)->int:
	var alerts:Array=[]
	for row:Dictionary in list:
		if row.get("alert") is Dictionary:alerts.append(row.alert)
	return Alerts.urgent_count(alerts)
