extends HBoxContainer
## Stock and flow are deliberately separate columns with explicit units.
## Values arrive from the caller's ledger; no inferred consumption or totals.
const T=preload("res://scripts/hud/hud_tokens.gd")
const S=preload("res://scripts/hud/econ_sheet.gd")
var values:Array[Label]=[]
var notes:Array[Label]=[]
var icons:Array[TextureRect]=[]
func _init()->void:
	name="ResourceFlow";size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",8)
	for index in 3:
		if index>0:
			var arrow:=T.make_label("→",16,T.MUTED);arrow.size_flags_vertical=Control.SIZE_SHRINK_CENTER;add_child(arrow)
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.custom_minimum_size.x=70;cell.add_theme_constant_override("separation",3);add_child(cell)
		var icon:=S.icon("carry" if index==0 else "stores" if index==1 else "make",24,"people");icon.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;cell.add_child(icon);icons.append(icon)
		var caption:=T.make_label(["ARRIVING","IN STORE","LEAVING"][index],12,T.INK_MUTED);cell.add_child(caption)
		var value:=T.make_label("",18,T.INK);value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cell.add_child(value);values.append(value)
		var note:=T.make_label("",12,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cell.add_child(note);notes.append(note)
func fill(incoming:String,stock:String,outgoing:String,left_note:String,stock_note:String,right_note:String)->void:
	for index in 3:
		values[index].text=[incoming,stock,outgoing][index];notes[index].text=[left_note,stock_note,right_note][index]
