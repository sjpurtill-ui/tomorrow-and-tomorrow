extends VBoxContainer
## Two readings in the same unit. UI only: callers supply ledger values.
const T=preload("res://scripts/hud/hud_tokens.gd")
const S=preload("res://scripts/hud/econ_sheet.gd")
const Icons=preload("res://scripts/resource_icons.gd")
var heading:Label
var mark:TextureRect
var captions:Array[Label]=[]
var values:Array[Label]=[]
var bars:Array[ProgressBar]=[]
var note:Label

func _init()->void:
	custom_minimum_size.x=164
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",4)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);add_child(top)
	mark=TextureRect.new();mark.custom_minimum_size=Vector2(22,22);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;top.add_child(mark)
	heading=T.make_label("",15,T.INK);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(heading)
	var pair:=HBoxContainer.new();pair.add_theme_constant_override("separation",12);add_child(pair)
	for index in 2:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",3);pair.add_child(column)
		var caption:=T.make_label("",12,T.INK_MUTED);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(caption);captions.append(caption)
		var value:=T.make_label("",21,T.INK);column.add_child(value);values.append(value)
		var bar:=ProgressBar.new();bar.custom_minimum_size=Vector2(36,5);bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(bar);bars.append(bar)
	note=T.make_label("",12,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)

func fill(title:String,left_label:String,left:Variant,right_label:String,right:Variant,unit:String="",resource:String="",detail:String="")->void:
	heading.text=title;captions[0].text=left_label;captions[1].text=right_label
	mark.visible=not resource.is_empty()
	if mark.visible:mark.texture=Icons.material_texture(resource,22)
	var numeric:bool=(left is float or left is int) and (right is float or right is int)
	var comparable:=numeric and float(left)>=0 and float(right)>=0
	var scale:=maxf(1,maxf(float(left),float(right))) if comparable else 1.0
	for index in 2:
		var reading:Variant=left if index==0 else right
		values[index].text=S.n(float(reading)) if reading is float or reading is int else String(reading)
		bars[index].visible=comparable
		if comparable:bars[index].max_value=scale;bars[index].value=float(reading)
		bars[index].add_theme_stylebox_override("background",T.flat(T.TRACK,Color.TRANSPARENT,0,2))
		bars[index].add_theme_stylebox_override("fill",T.flat(T.TEAL if index==0 else T.GOLD,Color.TRANSPARENT,0,2))
	note.text=unit;note.visible=not unit.is_empty();tooltip_text=detail
	set_meta("left",left);set_meta("right",right);set_meta("unit",unit)
