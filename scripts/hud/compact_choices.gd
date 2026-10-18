extends HBoxContainer
## Small fixed set of direct choices. Selection never emits an action on refresh.
const T=preload("res://scripts/hud/hud_tokens.gd")
signal item_selected(index:int)
var selected:=-1
var buttons:Array[Button]=[]
func _init()->void:add_theme_constant_override("separation",2)
func add_item(words:String)->void:
	var index:=buttons.size();var button:=Button.new();button.text=words;button.toggle_mode=true;button.custom_minimum_size.y=32;button.add_theme_font_size_override("font_size",12);button.tooltip_text=words;T.apply_button_style(button);add_child(button);buttons.append(button)
	button.pressed.connect(func():select(index);item_selected.emit(index))
func select(index:int)->void:
	selected=index
	for i in buttons.size():buttons[i].set_pressed_no_signal(i==index)
