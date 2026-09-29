extends VBoxContainer
## WHAT A THING DOES, SET OUT PLAINLY: an optional lead sentence, then each
## effect as a line: a small mark in its tone, what it touches, how much
## (right-aligned), and underneath, what that means in this town today.
## Lines come from the engine's own rules (building_impact.gd); the panel only
## lays them out. Block: {"type":"impact_lines", "lead":String, "lines":[{label,
## value, words, tone}], "columns":1|2}. Two columns on a wide dock.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const WIDE_AT:=760.0

var data:Dictionary={}
var grid:GridContainer


func setup(block:Dictionary)->void:
	data=block;name="ImpactPanel";add_theme_constant_override("separation",8)
	if String(block.get("lead",""))!="":
		var lead:=T.make_label(String(block.lead),13,T.BODY);lead.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		lead.add_theme_font_override("font",T.voice_font());lead.add_theme_font_size_override("font_size",15)
		add_child(lead)
	grid=GridContainer.new();grid.name="Lines";grid.columns=1
	grid.add_theme_constant_override("h_separation",28);grid.add_theme_constant_override("v_separation",10)
	add_child(grid)
	for line in block.get("lines",[]):grid.add_child(_line(line))
	resized.connect(_arrange)


func _arrange()->void:
	if grid==null:return
	var wanted:=2 if int(data.get("columns",2))>=2 and size.x>=WIDE_AT else 1
	if grid.columns!=wanted:grid.columns=wanted


func _line(line:Dictionary)->Control:
	var tone:=String(line.get("tone","plain"))
	var ink:=T.GREEN_TEXT if tone=="good" else (T.RED_TEXT if tone=="bad" else T.GOLD_TEXT)
	var box:=VBoxContainer.new();box.name="Line";box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",2)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);box.add_child(head)
	var mark:=ColorRect.new();mark.color=Color(ink,0.85);mark.custom_minimum_size=Vector2(3,16);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(mark)
	var label:=T.make_label(String(line.get("label","")),13,T.INK);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font",T.font("ui_strong"));head.add_child(label)
	var value:=T.make_label(String(line.get("value","")),14,ink);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_override("font",T.font("ui_strong"));head.add_child(value)
	if String(line.get("words",""))!="":
		var words:=T.make_label(String(line.words),12,T.TEXT_SOFT);words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var inset:=MarginContainer.new();inset.add_theme_constant_override("margin_left",11);inset.add_child(words);box.add_child(inset)
	return box
