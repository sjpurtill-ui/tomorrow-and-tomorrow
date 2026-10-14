extends RefCounted
## THE STRATEGY-SCREEN BLOCKS: dense, glyph-and-number pieces every provider
## builds its tabs from, so a tab reads like a game panel, not a slide.
## dock_blocks.gd routes "fact_grid", "table", "costs" and "frame" here; the
## KPI strip is the dock's own row (a tab's "kpis", dock_panel.gd).
##
## fact_grid  ordinary facts, one line each (mark, name, value at the right,
##         an optional thin bar, an optional verb beside the figure), flowing
##         into 1-3 columns as the page widens:
##   {type:"fact_grid", heading?, min_column? (px, 300), items:[{label,
##    value, tone?, icon?: Texture2D, bar? (0..1), tip?, on_click?, wrap?,
##    button?:{label, on_press, tip?, disabled?}}]}
##
## table   one line per item, columns aligned, the distinguishing fact first,
##         status as a small coloured tag, a verb button on the row:
##   {type:"table", heading?, note?, empty?: "one small line when no rows",
##    icon_size? (px, 18; 24-28 for small portraits),
##    head?: false (continue a table split around an opened row),
##    columns:[{key, label, width? (px), align? ("left"|"right")}],
##    rows:[{cells:{key:String}, icon?: Texture2D, group?: String (a group
##           header line is drawn when it changes), tag?:{text, tone},
##           bar?:{value 0..1, tone?}, button?:{label, on_press, tip?,
##           disabled?}, buttons?:[button, ...], tip?, on_click?: Callable,
##           tone?}]}
## costs   what a work needs against what is in store, one line, each good
##         an icon, "have / need" in green or red and five pips; the button
##         that starts it beside the cost:
##   {type:"costs", heading?, label?, items:[{resource, have, need}],
##    button?:{label, on_press, tip?, disabled?}}
## frame   a ruled panel holding other blocks, its title and verbs on one
##         line (an inline planner, a group of rows that belong together):
##   {type:"frame", heading, actions?:[{label, on_press, tip?}], blocks:[...]}
## Tones everywhere: "good", "warn", "bad", "" (ink).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const ROW_HEIGHT:=28.0
const FACT_HEIGHT:=30.0


## A small verb button: the one action on a row or beside a figure.
static func verb(label:String,on_press:Variant,tip:String="",disabled:=false)->Button:
	var go:=Button.new();go.name="Verb_"+label.validate_node_name();go.text=label;go.focus_mode=Control.FOCUS_NONE
	go.tooltip_text=tip;go.disabled=disabled;go.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	go.add_theme_font_override("font",T.font("ui_strong"));go.add_theme_font_size_override("font_size",12);go.custom_minimum_size=Vector2(0,22)
	for state:String in ["normal","hover","pressed"]:
		var skin:=T.gold_outline_style().duplicate() as StyleBoxFlat
		skin.content_margin_left=9;skin.content_margin_right=9;skin.content_margin_top=1;skin.content_margin_bottom=1
		if state!="normal":skin.bg_color=Color(T.GOLD,0.18)
		go.add_theme_stylebox_override(state,skin)
	var off:=T.flat(Color(0,0,0,0),T.RULE,1,4);off.content_margin_left=9;off.content_margin_right=9;off.content_margin_top=1;off.content_margin_bottom=1
	go.add_theme_stylebox_override("disabled",off);go.add_theme_color_override("font_disabled_color",T.INK_MUTED)
	go.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	go.add_theme_color_override("font_color",T.GOLD_TEXT);go.add_theme_color_override("font_hover_color",T.INK)
	if on_press is Callable and (on_press as Callable).is_valid():go.pressed.connect(on_press)
	return go


## A small coloured state tag ("At war", "Unread", "Short").
static func tag(text:String,tone:String)->PanelContainer:
	var pill:=PanelContainer.new();pill.name="Tag";pill.mouse_filter=Control.MOUSE_FILTER_IGNORE;pill.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var ink:=tone_color(tone,T.INK_MUTED)
	var skin:=T.flat(Color(ink,0.14),Color(ink,0.6),1,8);skin.content_margin_left=6;skin.content_margin_right=6;skin.content_margin_top=0;skin.content_margin_bottom=0
	pill.add_theme_stylebox_override("panel",skin)
	var words:=T.make_label(text,11,ink);words.add_theme_font_override("font",T.font("ui_strong"));words.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pill.add_child(words)
	return pill


static func tone_color(tone:String,fallback:Color)->Color:
	match tone:
		"good":return T.GREEN_TEXT
		"warn":return T.AMBER_TEXT
		"bad":return T.RED_TEXT
	return fallback


static func _bar(value:float,tone:String,width:float=56.0)->ProgressBar:
	var bar:=ProgressBar.new();bar.name="Bar";bar.show_percentage=false;bar.min_value=0.0;bar.max_value=1.0;bar.value=clampf(value,0.0,1.0)
	bar.custom_minimum_size=Vector2(width,5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",T.flat(Color(T.INK,0.12),Color(0,0,0,0),0,2))
	bar.add_theme_stylebox_override("fill",T.flat(tone_color(tone,T.GOLD) if tone!="" else T.GOLD,Color(0,0,0,0),0,2))
	return bar


# --- fact grid -------------------------------------------------------------------

static func render_fact_grid(parent:VBoxContainer,block:Dictionary)->GridContainer:
	var grid:=GridContainer.new();grid.name="FactGrid"
	grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",2)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	var widest:=float(block.get("min_column",300.0))
	var fit:=func()->void:
		if grid.size.x>0.0:grid.columns=clampi(floori((grid.size.x+24.0)/(widest+24.0)),1,3)
	grid.resized.connect(fit)
	grid.columns=2
	for item:Dictionary in block.get("items",[]):grid.add_child(_fact(item))
	return grid


static func _fact(item:Dictionary)->Control:
	var cell:=PanelContainer.new();cell.name="Fact_"+String(item.get("label","")).validate_node_name()
	cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.custom_minimum_size.y=FACT_HEIGHT
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
	# Never cut short: a long name wraps onto a second line.
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)
	if item.has("bar"):
		var bar:=ProgressBar.new();bar.name="Bar";bar.show_percentage=false;bar.min_value=0.0;bar.max_value=1.0;bar.value=clampf(float(item.bar),0.0,1.0)
		bar.custom_minimum_size=Vector2(56,5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background",T.flat(Color(T.INK,0.12),Color(0,0,0,0),0,2))
		bar.add_theme_stylebox_override("fill",T.flat(tone_color(String(item.get("tone","")),T.GOLD),Color(0,0,0,0),0,2))
		row.add_child(bar)
	var value:=T.make_label(String(item.get("value","")),13,tone_color(String(item.get("tone","")),T.INK));value.name="Value"
	value.add_theme_font_override("font",T.font("ui_strong"));value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;value.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(value)
	var button:Dictionary=item.get("button",{}) if item.get("button") is Dictionary else {}
	if not button.is_empty():row.add_child(verb(String(button.get("label","")),button.get("on_press"),String(button.get("tip","")),bool(button.get("disabled",false))))
	var click:Variant=item.get("on_click")
	if click is Callable and (click as Callable).is_valid():
		cell.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		cell.mouse_entered.connect(func()->void:cell.add_theme_stylebox_override("panel",lit))
		cell.mouse_exited.connect(func()->void:cell.add_theme_stylebox_override("panel",rest))
		cell.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:cell.accept_event();(click as Callable).call())
	return cell


# --- table ---------------------------------------------------------------------

static func render_table(parent:VBoxContainer,block:Dictionary)->VBoxContainer:
	var list:=VBoxContainer.new();list.name="Table";list.add_theme_constant_override("separation",0);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(list)
	var columns:Array=block.get("columns",[])
	var rows:Array=block.get("rows",[])
	if rows.is_empty():
		var empty:=String(block.get("empty",""))
		if empty!="":list.add_child(T.make_label(empty,12,T.INK_MUTED))
		return list
	var icon_size:=float(block.get("icon_size",18.0))
	# "head":false continues a table split around an opened row (no second header).
	var head:HBoxContainer=null
	if bool(block.get("head",true)):
		head=HBoxContainer.new();head.name="Head";head.add_theme_constant_override("separation",8);head.custom_minimum_size.y=20;list.add_child(head)
		var icon_gap:=Control.new();icon_gap.custom_minimum_size.x=icon_size;head.add_child(icon_gap)
		for column:Dictionary in columns:head.add_child(_cell(String(column.get("label","")),column,11,T.INK_MUTED,true))
		var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;list.add_child(rule)
	var group:=""
	var index:=0
	var extras:Array[Control]=[]
	for row:Dictionary in rows:
		var this_group:=String(row.get("group",""))
		if this_group!="" and this_group!=group:
			group=this_group
			var title:=T.make_label(group.to_upper(),11,T.GOLD_TEXT,0.06);title.name="Group_%d" % index;title.custom_minimum_size.y=22;title.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
			list.add_child(title)
		var line:=_row(row,columns,icon_size);line.name="Row_%d" % index
		list.add_child(line);index+=1
		var more:=line.find_child("Extras",true,false) as Control
		if more:extras.append(more)
	# The bars, tags and verbs at a row's end share one column, as wide as the
	# widest, so every row's cells stand under their own headings.
	var widest:=0.0
	for more:Control in extras:widest=maxf(widest,more.get_combined_minimum_size().x)
	if widest>0.0:
		for more:Control in extras:more.custom_minimum_size.x=widest
		if head:
			var gap:=Control.new();gap.name="Extras";gap.custom_minimum_size.x=widest;head.add_child(gap)
	return list


static func _cell(text:String,column:Dictionary,font_size:int,ink:Color,head:=false)->Label:
	var label:=T.make_label(text,font_size,ink);label.name="Cell_"+String(column.get("key","")).validate_node_name()
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	if head:label.add_theme_font_override("font",T.font("ui_strong"))
	# No cell is ever cut short ("…"): a fixed column grows to its words, a
	# free column wraps them onto a second line.
	var width:=float(column.get("width",0.0))
	if width>0.0:label.custom_minimum_size.x=width
	else:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if String(column.get("align",""))=="right":label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	return label


static func _row(row:Dictionary,columns:Array,icon_size:=18.0)->PanelContainer:
	var panel:=PanelContainer.new();panel.name="Row";panel.custom_minimum_size.y=ROW_HEIGHT;panel.tooltip_text=String(row.get("tip",""))
	var rest:=T.flat(Color(0,0,0,0),Color(0,0,0,0),0,2);rest.content_margin_left=2;rest.content_margin_right=2;rest.border_width_bottom=1;rest.border_color=Color(T.RULE,0.4)
	var lit:=rest.duplicate() as StyleBoxFlat;lit.bg_color=T.HOVER_BG
	panel.add_theme_stylebox_override("panel",rest)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var mark:=TextureRect.new();mark.custom_minimum_size=Vector2(icon_size,icon_size);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if icon_size<=18.0 else TextureRect.STRETCH_KEEP_ASPECT_COVERED;mark.clip_contents=true
	mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if row.get("icon") is Texture2D:mark.texture=row.icon
	line.add_child(mark)
	var cells:Dictionary=row.get("cells",{})
	var first:=true
	for column:Dictionary in columns:
		var ink:=tone_color(String(row.get("tone","")),T.INK) if first else T.BODY
		var label:=_cell(String(cells.get(String(column.get("key","")),"")),column,13,ink)
		if first:label.add_theme_font_override("font",T.font("ui_strong"))
		line.add_child(label);first=false
	# Bar, tag and verb sit right-aligned in the row's end column (render_table
	# gives every row's end column the same width).
	var end:=HBoxContainer.new();end.name="Extras";end.alignment=BoxContainer.ALIGNMENT_END;end.add_theme_constant_override("separation",6);end.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(end)
	var bar:Dictionary=row.get("bar",{}) if row.get("bar") is Dictionary else {}
	if not bar.is_empty():
		# A blank bar keeps the column's width on a row that has none, so columns stay aligned.
		if bool(bar.get("blank",false)):
			var gap:=Control.new();gap.custom_minimum_size.x=56.0;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;end.add_child(gap)
		else:end.add_child(_bar(float(bar.get("value",0.0)),String(bar.get("tone",""))))
	var state:Dictionary=row.get("tag",{}) if row.get("tag") is Dictionary else {}
	if not state.is_empty():end.add_child(tag(String(state.get("text","")),String(state.get("tone",""))))
	var button:Dictionary=row.get("button",{}) if row.get("button") is Dictionary else {}
	if not button.is_empty():end.add_child(verb(String(button.get("label","")),button.get("on_press"),String(button.get("tip","")),bool(button.get("disabled",false))))
	# Several verbs on one row (− and + beside a share).
	for more:Variant in row.get("buttons",[]):
		var spec:Dictionary=more if more is Dictionary else {}
		if spec.is_empty() or bool(spec.get("blank",false)):
			# A blank verb holds its place so the columns before it line up.
			var gap:=Control.new();gap.custom_minimum_size.x=float(spec.get("width",26.0));gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;end.add_child(gap)
		else:
			var go:=verb(String(spec.get("label","")),spec.get("on_press"),String(spec.get("tip","")),bool(spec.get("disabled",false)))
			if spec.has("width"):go.custom_minimum_size.x=float(spec.width)
			end.add_child(go)
	var click:Variant=row.get("on_click")
	if click is Callable and (click as Callable).is_valid():
		panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit))
		panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",rest))
		panel.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:panel.accept_event();(click as Callable).call())
	return panel


# --- costs -----------------------------------------------------------------------

const PIPS:=5

static func render_costs(parent:VBoxContainer,block:Dictionary)->HBoxContainer:
	var line:=HBoxContainer.new();line.name="Costs";line.add_theme_constant_override("separation",14);line.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(line)
	if String(block.get("label",""))!="":
		var label:=T.make_label(String(block.label),13,T.INK);label.add_theme_font_override("font",T.font("ui_strong"));label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		line.add_child(label)
	for item:Dictionary in block.get("items",[]):line.add_child(cost_chip(String(item.get("resource","")),float(item.get("have",0.0)),float(item.get("need",0.0))))
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(spacer)
	var button:Dictionary=block.get("button",{}) if block.get("button") is Dictionary else {}
	if not button.is_empty():line.add_child(verb(String(button.get("label","")),button.get("on_press"),String(button.get("tip","")),bool(button.get("disabled",false))))
	return line


## One good of a cost: its icon, have / need in green (enough) or red
## (short), and five pips filled by the share in hand.
static func cost_chip(resource:String,have:float,need:float)->HBoxContainer:
	var chip:=HBoxContainer.new();chip.name="Cost_"+resource.validate_node_name();chip.add_theme_constant_override("separation",4)
	var enough:=have+0.001>=need
	var ink:=T.GREEN_TEXT if enough else T.RED_TEXT
	chip.tooltip_text="%s: %s in store of %s needed." % [resource,_n(have),_n(need)]
	var icon:=TextureRect.new();icon.texture=Icons.texture_for(resource);icon.custom_minimum_size=Vector2(18,18);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(icon)
	var words:=T.make_label("%s / %s" % [_n(have),_n(need)],12,ink);words.add_theme_font_override("font",T.font("ui_strong"));words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;words.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chip.add_child(words)
	var pips:=Pips.new();pips.share=clampf(have/maxf(0.001,need),0.0,1.0);pips.ink=ink;pips.custom_minimum_size=Vector2(PIPS*7,8);pips.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	chip.add_child(pips)
	return chip


static func _n(value:float)->String:
	return preload("res://scripts/hud/production_plain.gd").number(value)


class Pips extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var share:=0.0
	var ink:=Color.WHITE
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		var filled:=roundi(share*5.0)
		for i in 5:
			var at:=Vector2(3.0+i*7.0,size.y*0.5)
			if i<filled:draw_circle(at,2.6,ink)
			else:draw_arc(at,2.4,0.0,TAU,12,Color(T.INK,0.35),1.0,true)


# --- frame -----------------------------------------------------------------------

static func render_frame(parent:VBoxContainer,block:Dictionary)->PanelContainer:
	var frame:=PanelContainer.new();frame.name="Frame";frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var skin:=T.flat(Color(T.PAPER_RAISED,0.5),T.RULE,1,4);skin.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel",skin)
	parent.add_child(frame)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);box.add_child(top)
	var title:=T.make_label(String(block.get("heading","")).to_upper(),11,T.GOLD_TEXT,0.06);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
	for action:Dictionary in block.get("actions",[]):top.add_child(verb(String(action.get("label","")),action.get("on_press"),String(action.get("tip",""))))
	var inner:=VBoxContainer.new();inner.add_theme_constant_override("separation",6);box.add_child(inner)
	var children:Array=[]
	for child:Dictionary in block.get("blocks",[]):
		var copy:=child.duplicate();copy.erase("heading_shown")
		children.append(copy)
	preload("res://scripts/hud/dock_blocks.gd").render(inner,children)
	return frame
