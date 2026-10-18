extends Button
## Explicit town browser: a bounded, searchable grid anchored below the scope label.
## No native dropdown menu; town identity survives an intervening ledger refresh.
const T=preload("res://scripts/hud/hud_tokens.gd")
signal item_selected(index:int)
var selected:=-1
var choice:Control
var panel:PanelContainer
var item_count:int:
	get:return choice.item_count
func _init()->void:
	clip_text=true;text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	panel=PanelContainer.new();panel.name="TownTray";panel.set_as_top_level(true);panel.z_index=40;panel.visible=false;panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.RULE_STRONG,1,6,12));add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var header:=HBoxContainer.new();column.add_child(header)
	var label:=T.make_label("View a town",18,T.INK);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(label)
	var close:=Button.new();close.text="Close";T.apply_button_style(close);header.add_child(close);close.pressed.connect(func():panel.hide())
	choice=preload("res://scripts/hud/visible_choices.gd").new();choice.name="TownChoices";column.add_child(choice)
	choice.item_selected.connect(func(index:int):select(index);panel.hide();item_selected.emit(index))
	pressed.connect(func():panel.visible=not panel.visible;_place())
	resized.connect(_place)
func _notification(what:int)->void:
	if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and is_instance_valid(panel):panel.hide()
func _place()->void:
	if not is_inside_tree() or not panel.visible:return
	var view:=get_viewport_rect().size
	panel.reset_size();panel.size.x=minf(480,maxf(240,view.x-24))
	panel.global_position=Vector2(clampf(global_position.x,12,maxf(12,view.x-panel.size.x-12)),global_position.y+size.y+6)
func clear()->void:choice.clear();selected=-1
func add_item(words:String)->void:
	choice.add_item(words)
	if selected<0:select(0)
func set_item_metadata(index:int,value:Variant)->void:choice.set_item_metadata(index,value)
func get_item_metadata(index:int)->Variant:return choice.get_item_metadata(index)
func select(index:int)->void:
	selected=index;choice.select(index)
	if index>=0 and index<item_count:text="Town · "+choice.get_item_text(index);tooltip_text="Selected town: "+choice.get_item_text(index)+". Open the town tray or choose a town on the map."

func _unhandled_key_input(event:InputEvent)->void:
	if panel.visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		panel.hide();get_viewport().set_input_as_handled()
