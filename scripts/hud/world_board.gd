extends VBoxContainer
## World intelligence board. Every card comes from returned or observed records.
const T=preload("res://scripts/hud/hud_tokens.gd")
var columns:GridContainer
func setup(data:Dictionary)->void:
	name="WorldBoard"
	add_theme_constant_override("separation",18)
	var banner:=_card(self)
	_label(banner,String(data.title),26,T.INK)
	_label(banner,String(data.subtitle),14,T.MUTED)
	var actions:=HFlowContainer.new();banner.add_child(actions)
	for action:Dictionary in data.actions:
		var button:=Button.new();button.text=String(action.label);button.custom_minimum_size.y=38
		button.add_theme_color_override("font_color",T.INK)
		button.add_theme_stylebox_override("normal",T.flat(T.BUTTON_BG,T.BORDER,1,3))
		button.disabled=bool(action.get("disabled",false));button.tooltip_text=String(action.get("tip",""))
		button.pressed.connect(action.on_press);actions.add_child(button)
	columns=GridContainer.new();columns.columns=2;columns.add_theme_constant_override("h_separation",18);columns.add_theme_constant_override("v_separation",18);add_child(columns)
	for section:Dictionary in data.sections:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);columns.add_child(column)
		_label(column,String(section.title),15,T.GOLD)
		for item:Dictionary in section.items:
			var card:=_card(column)
			var person:Dictionary=item.get("known_leader",{})
			if not person.is_empty():
				var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",14);card.add_child(identity)
				identity.add_child(preload("res://scripts/hud/person_portrait.gd").picture(person,112,112))
				var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",8);identity.add_child(text)
				card=text
				_label(card,String(person.get("name","")),14,T.INK)
			_label(card,String(item.get("tag","")),11,T.GOLD)
			_label(card,String(item.title),19,T.INK)
			_label(card,String(item.detail),13,T.BODY)
			if item.has("on_press"):
				var button:=Button.new();button.text=String(item.get("action","Open report"));button.custom_minimum_size.y=34
				button.add_theme_color_override("font_color",T.INK)
				button.add_theme_stylebox_override("normal",T.flat(T.BUTTON_BG,T.BORDER,1,3))
				button.pressed.connect(item.on_press);card.add_child(button)
	resized.connect(_layout);_layout()
func _layout()->void:
	columns.columns=2 if size.x>=850 else 1
func _card(parent:Node)->VBoxContainer:
	var frame:=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=T.flat(T.FIELD_BG,T.BORDER_SOFT,1,4)
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=14;style.content_margin_bottom=14
	frame.add_theme_stylebox_override("panel",style);parent.add_child(frame)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",8);frame.add_child(stack);return stack
func _label(parent:Node,value:String,font_size:int,color:Color)->void:
	if value.is_empty():return
	var label:=T.make_label(value,font_size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)
