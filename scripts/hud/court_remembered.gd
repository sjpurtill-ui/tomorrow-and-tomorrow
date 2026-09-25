extends RefCounted
## THE REMEMBERED: the court's roll of its dead, beneath the living roster.
## Read-only; the roll itself lives in court_lives.gd.

const Lives:=preload("res://scripts/court_lives.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const SHOWN:=5

static func mourning_holder()->String:
	## The name of whoever waits to bring a mourning before the god, or "".
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="mourning": return String((m.get("holder",{}) as Dictionary).get("name",""))
	return ""

static func line_for(entry:Dictionary)->String:
	var year:=int(int(entry.get("died",entry.get("day",0)))/365.0)+1
	var text:="%s · %s · died in year %d, aged %d. They %s." % [String(entry.get("name","")),String(entry.get("title","")),year,int(entry.get("age",0)),String(entry.get("deed","served"))]
	if String(entry.get("successor",""))!="": text+=" %s followed them." % String(entry.successor)
	return text

static func append_to(list:VBoxContainer,italic:Font=null)->void:
	_append_aims(list,italic)
	var dead:=Lives.remembered(SHOWN)
	if dead.is_empty(): return
	var head:=Tokens.make_label("THE REMEMBERED",10,Tokens.TEXT_DIM,.12);head.name="RememberedHead";list.add_child(head)
	var holder:=mourning_holder()
	if holder!="":
		var call:=Tokens.make_label("The court mourns. Summon %s to hear it and choose who follows." % holder,12,Tokens.GOLD_BRIGHT)
		call.name="MourningCall";call.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(call)
	for entry in dead:
		var row:=Tokens.make_label(line_for(entry),12,Tokens.TEXT_SOFT);row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		row.name="Remembered_%d" % int(entry.get("pid",0))
		if italic!=null: row.add_theme_font_override("font",italic)
		list.add_child(row)

## What the people strive for now, and what they are remembered for
## (legacy_aims.gd), above the roll of the dead.
static func _append_aims(list:VBoxContainer,italic:Font=null)->void:
	var Aims:=preload("res://scripts/legacy_aims.gd")
	var line:=String(Aims.court_line())
	var model:Dictionary=Aims.board_model()
	var legacies:Array=model.get("legacies",[])
	if line=="" and legacies.is_empty(): return
	var head:=Tokens.make_label("WHAT WE STRIVE FOR",10,Tokens.TEXT_DIM,.12);head.name="AimsHead";list.add_child(head)
	if line!="":
		var now:=Tokens.make_label(line,12,Tokens.GOLD_BRIGHT);now.name="AimNow";now.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(now)
	for legacy in legacies.slice(0,3):
		var row:=Tokens.make_label("Remembered: %s. %s, year %d." % [String(legacy.get("name","")),String(legacy.get("title","")),int(int(legacy.get("day",0))/365.0)+1],12,Tokens.TEXT_SOFT)
		row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.name="Legacy_%d" % int(legacy.get("day",0))
		if italic!=null: row.add_theme_font_override("font",italic)
		list.add_child(row)
