extends VBoxContainer
## Returned intelligence first; exploration and contacts remain close at hand.
const T=preload("res://scripts/hud/hud_tokens.gd")
var columns:BoxContainer
var sidebar:VBoxContainer

func setup(data:Dictionary)->void:
	name="WorldBoard"
	add_theme_constant_override("separation",22)
	var toolbar:=VBoxContainer.new()
	toolbar.add_theme_constant_override("separation",8)
	add_child(toolbar)
	_label(toolbar,String(data.title),24,T.INK)
	_label(toolbar,String(data.subtitle),14,T.MUTED)
	var actions:=HFlowContainer.new()
	actions.add_theme_constant_override("h_separation",10)
	actions.add_theme_constant_override("v_separation",8)
	toolbar.add_child(actions)
	for action:Dictionary in data.actions:
		_button(actions,action)
	columns=BoxContainer.new()
	columns.add_theme_constant_override("separation",28)
	add_child(columns)
	for index:int in range(data.sections.size()):
		var section:Dictionary=data.sections[index]
		var column:=VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.size_flags_stretch_ratio=2.0 if index==0 else 1.0
		column.add_theme_constant_override("separation",0)
		columns.add_child(column)
		if index==1:sidebar=column
		var heading:=_label(column,String(section.title),12,T.GOLD)
		heading.custom_minimum_size.y=34
		for item:Dictionary in section.items:
			_item(column,item,index==0)
	resized.connect(_layout)
	_layout()

func _layout()->void:
	columns.vertical=size.x<850

func _item(parent:Node,item:Dictionary,report:bool)->void:
	var frame:=PanelContainer.new()
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=T.flat(T.FIELD_BG if report else Color.TRANSPARENT)
	style.border_color=T.BORDER_SOFT
	style.border_width_bottom=1
	style.content_margin_left=16 if report else 0
	style.content_margin_right=16 if report else 0
	style.content_margin_top=14
	style.content_margin_bottom=14
	frame.add_theme_stylebox_override("panel",style)
	parent.add_child(frame)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",6)
	frame.add_child(stack)
	var tag:=String(item.get("tag",""))
	if bool(item.get("unread",false)):tag="NEW · "+tag
	_label(stack,tag,11,T.TEAL if bool(item.get("unread",false)) else T.MUTED)
	_label(stack,String(item.title),19 if report else 16,T.INK)
	_label(stack,String(item.get("detail","")),13,T.MUTED)
	if item.has("on_press"):
		var action:Dictionary={"label":item.get("action","Read report"),"on_press":item.on_press}
		var button:=_button(stack,action)
		button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		button.add_theme_font_size_override("font_size",13)

func _button(parent:Node,action:Dictionary)->Button:
	var button:=Button.new()
	button.text=String(action.label)
	button.custom_minimum_size.y=36
	button.add_theme_font_size_override("font_size",14)
	var primary:=bool(action.get("primary",false))
	button.add_theme_color_override("font_color",T.INK)
	button.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if primary else T.FIELD_BG,T.BORDER,1,3,10))
	button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,3,10))
	button.add_theme_stylebox_override("focus",T.gold_outline_style())
	button.disabled=bool(action.get("disabled",false))
	button.tooltip_text=String(action.get("tip",""))
	button.pressed.connect(action.on_press)
	parent.add_child(button)
	return button

func _label(parent:Node,value:String,font_size:int,color:Color)->Label:
	var label:=T.make_label(value,font_size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	label.visible=not value.is_empty()
	return label
