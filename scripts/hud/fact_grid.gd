extends RefCounted
## THE FACT GRID: the one way a page lists ordinary facts (the page's
## headline figures are its tile row). Each fact is one line: a mark, its
## name, its value at the right, an optional thin bar with its scale in the
## pointer, and an optional button beside the figure it changes. The lines
## flow into one, two or three columns as the page widens, so a wide window
## is used and nothing stacks label over value over note.
##
## Block: {type:"fact_grid", heading?, items:[{label, value, tone?
## ("good","warn","bad"), icon? (Texture2D), bar? (0..1), tip?, on_click?
## (Callable: the whole line), button? ({label, on_press, tip?})}],
## min_column? (px, default 300)}.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const ROW_HEIGHT:=30.0

static func render(parent:VBoxContainer,block:Dictionary)->GridContainer:
	var grid:=GridContainer.new();grid.name="FactGrid"
	grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",2)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	var widest:=float(block.get("min_column",300.0))
	var fit:=func()->void:
		if grid.size.x>0.0:grid.columns=clampi(floori((grid.size.x+24.0)/(widest+24.0)),1,3)
	grid.resized.connect(fit)
	grid.columns=2
	for item:Dictionary in block.get("items",[]):grid.add_child(_line(item))
	return grid


static func _line(item:Dictionary)->Control:
	var cell:=PanelContainer.new();cell.name="Fact_"+String(item.get("label","")).validate_node_name()
	cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.custom_minimum_size.y=ROW_HEIGHT
	var rest:=T.flat(Color(0,0,0,0),Color(0,0,0,0),0,3);rest.content_margin_left=4;rest.content_margin_right=4
	rest.border_width_bottom=1;rest.border_color=Color(T.RULE,0.45)
	var lit:=rest.duplicate() as StyleBoxFlat;lit.bg_color=T.HOVER_BG
	cell.add_theme_stylebox_override("panel",rest)
	cell.tooltip_text=String(item.get("tip",""))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(row)
	var icon:Variant=item.get("icon")
	if icon is Texture2D:
		var mark:=TextureRect.new();mark.texture=icon;mark.custom_minimum_size=Vector2(18,18);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(mark)
	var label:=T.make_label(String(item.get("label","")),13,T.BODY);label.name="Label"
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)
	if item.has("bar"):
		var bar:=ProgressBar.new();bar.name="Bar";bar.show_percentage=false;bar.min_value=0.0;bar.max_value=1.0;bar.value=clampf(float(item.bar),0.0,1.0)
		bar.custom_minimum_size=Vector2(56,5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background",T.flat(Color(T.INK,0.12),Color(0,0,0,0),0,2))
		bar.add_theme_stylebox_override("fill",T.flat(_tone(String(item.get("tone","")),T.GOLD),Color(0,0,0,0),0,2))
		row.add_child(bar)
	var value:=T.make_label(String(item.get("value","")),13,_tone(String(item.get("tone","")),T.INK));value.name="Value"
	value.add_theme_font_override("font",T.font("ui_strong"));value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;value.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(value)
	var button:Dictionary=item.get("button",{}) if item.get("button") is Dictionary else {}
	if not button.is_empty():
		var go:=Button.new();go.name="Do";go.text=String(button.get("label",""));go.focus_mode=Control.FOCUS_NONE
		go.tooltip_text=String(button.get("tip",""));go.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		go.add_theme_font_size_override("font_size",12);go.custom_minimum_size.y=24
		go.add_theme_stylebox_override("normal",T.gold_outline_style());go.add_theme_stylebox_override("hover",T.gold_outline_style())
		go.add_theme_color_override("font_color",T.GOLD_TEXT)
		var press:Variant=button.get("on_press")
		if press is Callable:go.pressed.connect(press)
		row.add_child(go)
	var click:Variant=item.get("on_click")
	if click is Callable and (click as Callable).is_valid():
		cell.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		cell.mouse_entered.connect(func()->void:cell.add_theme_stylebox_override("panel",lit))
		cell.mouse_exited.connect(func()->void:cell.add_theme_stylebox_override("panel",rest))
		cell.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:cell.accept_event();(click as Callable).call())
	return cell


static func _tone(tone:String,fallback:Color)->Color:
	match tone:
		"good":return T.GREEN_TEXT
		"warn":return T.AMBER_TEXT
		"bad":return T.RED_TEXT
	return fallback
