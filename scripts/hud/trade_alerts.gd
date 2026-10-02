extends RefCounted
## TRADE NEWS UNDER THE CLOCK (hud/army_alerts.gd draws the marks): what
## trade between peoples did to us lately, told once each (the trade
## ledger's news, trade_ledger.gd, shown for NEWS_DAYS days after it
## happened, and once in the chronicle):
##   red    a people turns on our trade: an embargo, a squeeze, a toll on our
##          traders, raiders on our trading roads, war over trade, tribute
##          they stopped paying;
##   amber  a people yields to us, a shortage biting them (or us), a new
##          trade partner or meeting place, an answer that is not a yield.
## A click opens the Trade page. Nothing shows while nothing happened.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Words:=preload("res://scripts/trade_words.gd")

## [{id, tone, count, title, lines, page, resource?, war?}] in the alert row's shape.
static func alerts()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var red:=PackedStringArray(); var amber:=PackedStringArray()
	var red_good:=""; var amber_good:=""
	for item:Dictionary in Ledger.recent_news():
		var kind:=String(item.get("kind",""))
		if not kind in Words.ALERT_NEWS: continue
		# Our own acts are not news to us, only what others did.
		if String(item.get("a",""))=="player" and kind in ["embargo","squeeze","toll"]: continue
		var line:=String(item.get("text",""))
		if line=="": continue
		var against_us:=kind in Words.RED_NEWS and String(item.get("b",""))=="player" or kind in ["war","tribute_stopped"]
		if kind=="raided" and String(item.get("b",""))!="player": against_us=false
		if against_us:
			red.append(line)
			if red_good=="": red_good=String(item.get("good",""))
		else:
			amber.append(line)
			if amber_good=="": amber_good=String(item.get("good",""))
	if not red.is_empty():
		var mark:={"id":"trade_against","tone":"red","count":red.size(),"title":"Trade turned against us","lines":red,"page":"trade"}
		if red_good!="": mark["resource"]=red_good
		else: mark["war"]="raid"
		out.append(mark)
	if not amber.is_empty():
		var mark2:={"id":"trade_news","tone":"amber","count":amber.size(),"title":"Trade news","lines":amber,"page":"trade"}
		if amber_good!="": mark2["resource"]=amber_good
		else: mark2["glyph"]="supply"
		out.append(mark2)
	return out
