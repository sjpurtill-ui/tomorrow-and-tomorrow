extends Control
## Command Rail HUD shell: left rail, time pill, KPI strip, decision queue,
## and map toolbar. The map stays visible and interactive behind everything.
## Design source: design_handoff_command_rail_hud (1920x1080, values final).

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const DockPanelScript:=preload("res://scripts/hud/dock_panel.gd")

signal section_requested(section:String,sub:int)
signal menu_requested
signal escape_pressed

const SECTIONS:Array[Dictionary]=[
	{"id":"settlement","glyph":"ST","label":"SETTLEMENT","tooltip":"People, labor, works, defense · F1"},
	{"id":"economy","glyph":"EC","label":"ECONOMY","tooltip":"Food, water, materials · F2"},
	{"id":"civ","glyph":"CV","label":"CIVILIZATION","tooltip":"Society, government, council · F3"},
	{"id":"inquiry","glyph":"IN","label":"INQUIRY","tooltip":"Research attention and findings · F4"},
	{"id":"world","glyph":"WD","label":"WORLD","tooltip":"Contacts, scouting, standing · F5"},
	{"id":"military","glyph":"ML","label":"MILITARY","tooltip":"Formations, training, supply · F6"},
]
const SPEED_TOOLTIPS:Array[String]=["Pause · 0","0.5 h/s","2 h/s","8 h/s","1 day/s","3 days/s"]
const SPEED_GLYPHS:Array[String]=["Ⅱ","1","2","3","4","5"]
const MAX_QUEUE_CARDS:=3

var city_selector:OptionButton
var city_selector_signature:String=""
var terrain:Node

var active_section:String=""
var dismissed_alert_ids:Array=[]
var layers:Dictionary={"resources":true,"borders":false,"charted":false}

var rail_panel:PanelContainer
var rail_buttons:Dictionary={}
var rail_badges:Dictionary={}
var time_pill:PanelContainer
var time_text:RichTextLabel
var speed_buttons:Array[Button]=[]
var kpi_strip:VBoxContainer
var kpi_chips:Dictionary={}
var queue_root:VBoxContainer
var queue_footer:Label
var toolbar:PanelContainer
var toolbar_wrap:Control
var toolbar_action_buttons:Dictionary={}
var toolbar_layer_buttons:Dictionary={}
var scale_line:ColorRect
var scale_label:Label
var compass_label:Button

var dock:PanelContainer
var detail_dock:PanelContainer
var providers:Dictionary={}
var _dock_signature:Array=[]
var _detail_signature:Array=[]
var detail_history:Array=[]

var _queue_signature:String=""
var _kpi_signature:String=""
var _badge_signature:String=""
var _time_signature:String=""
var _toolbar_signature:String=""

func _ready()->void:
	name="CommandRailHud"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_build_rail()
	_build_time_pill()
	_build_kpi_strip()
	_build_decision_queue()
	_build_toolbar()
	_build_dock()
	get_viewport().size_changed.connect(_layout)
	_layout()
	refresh()

func _layout()->void:
	var view:=get_viewport().get_visible_rect().size
	if rail_panel:
		rail_panel.position=Vector2.ZERO
		rail_panel.size=Vector2(Tokens.RAIL_WIDTH,view.y)
	if time_pill:
		time_pill.position=Vector2(view.x*0.5-time_pill.size.x*0.5,Tokens.DOCK_MARGIN_Y)
	if kpi_strip:
		kpi_strip.position=Vector2(view.x-Tokens.EDGE_MARGIN-kpi_strip.size.x,Tokens.DOCK_MARGIN_Y)
	if queue_root:
		queue_root.position=Vector2(view.x-Tokens.EDGE_MARGIN-Tokens.QUEUE_WIDTH,view.y-Tokens.EDGE_MARGIN-queue_root.size.y)
	if dock:
		dock.position=Vector2(Tokens.DOCK_X,Tokens.DOCK_MARGIN_Y)
		# Before the first container sort, autowrap labels report inflated
		# minimum heights and set_size clamps upward; defer so the assignment
		# lands after layout settles.
		dock.set_deferred("size",Vector2(minf(Tokens.DOCK_WIDTH,view.x-Tokens.DOCK_X-12),view.y-Tokens.DOCK_MARGIN_Y*2.0))
	if detail_dock:
		detail_dock.position=Vector2(Tokens.DOCK_X,Tokens.DOCK_MARGIN_Y)
		detail_dock.set_deferred("size",Vector2(minf(Tokens.DOCK_WIDTH,view.x-Tokens.DOCK_X-12),view.y-Tokens.DOCK_MARGIN_Y*2.0))
	_position_toolbar()

func force_dock_layout()->void:
	## Synchronous layout for the capture harness (no idle frames before draw).
	var view:=get_viewport().get_visible_rect().size
	for panel in [dock,detail_dock]:
		if panel==null or not panel.visible: continue
		for sort_pass in 3:
			panel.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)
		panel.size=Vector2(minf(Tokens.DOCK_WIDTH,view.x-Tokens.DOCK_X-12),view.y-Tokens.DOCK_MARGIN_Y*2.0)
		for sort_pass in 3:
			panel.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)

func _position_toolbar()->void:
	if toolbar==null: return
	var view:=get_viewport().get_visible_rect().size
	var free_left:=Tokens.DOCK_DETAIL_X if active_section!="" else Tokens.RAIL_WIDTH
	toolbar.position=Vector2(free_left+(view.x-free_left)*0.5-toolbar.size.x*0.5,view.y-Tokens.EDGE_MARGIN-toolbar.size.y)

# --- Rail -------------------------------------------------------------------

func _build_rail()->void:
	rail_panel=PanelContainer.new()
	rail_panel.name="CommandRail"
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,Tokens.BORDER,0,0)
	style.border_color=Tokens.BORDER
	style.border_width_right=1
	style.content_margin_top=12.0
	style.content_margin_bottom=12.0
	style.content_margin_left=8.0
	style.content_margin_right=8.0
	rail_panel.add_theme_stylebox_override("panel",style)
	add_child(rail_panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	rail_panel.add_child(column)
	var header:=Label.new()
	header.text="T&T"
	header.name="RailHeader"
	header.custom_minimum_size=Vector2(0,Tokens.RAIL_HEADER_HEIGHT)
	header.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	Tokens.style_label(header,10,Tokens.GOLD,0.14)
	column.add_child(header)
	var header_rule:=ColorRect.new()
	header_rule.color=Tokens.BORDER
	header_rule.custom_minimum_size=Vector2(0,1)
	column.add_child(header_rule)
	for section in SECTIONS:
		var button:=_make_rail_button(section)
		column.add_child(button)
	var spacer:=Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var menu_button:=Button.new()
	menu_button.name="RailMenu"
	menu_button.custom_minimum_size=Vector2(0,Tokens.RAIL_HEADER_HEIGHT)
	menu_button.text="MENU"
	menu_button.tooltip_text="Pause, view controls, restart, or begin a new world."
	menu_button.add_theme_font_size_override("font_size",9)
	menu_button.add_theme_color_override("font_color",Tokens.TEXT_DIM)
	menu_button.add_theme_stylebox_override("normal",Tokens.rail_button_style(false))
	menu_button.add_theme_stylebox_override("hover",Tokens.rail_button_style(false,true))
	menu_button.add_theme_stylebox_override("pressed",Tokens.rail_button_style(true))
	menu_button.pressed.connect(func()->void: menu_requested.emit())
	column.add_child(menu_button)

func _make_rail_button(section:Dictionary)->Button:
	var id:=String(section.id)
	var button:=Button.new()
	button.name="Rail"+id.capitalize().replace(" ","")
	if id=="civ": button.name="RailCivilization"
	button.custom_minimum_size=Vector2(0,Tokens.RAIL_BUTTON_HEIGHT)
	button.tooltip_text=String(section.tooltip)
	button.add_theme_stylebox_override("normal",Tokens.rail_button_style(false))
	button.add_theme_stylebox_override("hover",Tokens.rail_button_style(false,true))
	button.add_theme_stylebox_override("pressed",Tokens.rail_button_style(true))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.pressed.connect(func()->void: toggle_section(id))
	var content:=VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment=BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation",3)
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var glyph:=Label.new()
	glyph.text=String(section.glyph)
	glyph.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	Tokens.style_label(glyph,16,Tokens.TEXT_DIM,0.04)
	content.add_child(glyph)
	var label:=Label.new()
	label.text=String(section.label)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	Tokens.style_label(label,8,Tokens.TEXT_DIM,0.1)
	content.add_child(label)
	var badge:=Label.new()
	badge.visible=false
	badge.custom_minimum_size=Vector2(16,16)
	badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size",9)
	badge.add_theme_color_override("font_color",Tokens.DARK_INK)
	# Rail width is fixed, so a plain top-left offset lands the pill at the
	# button's top-right corner (button content width = rail - 2*8 padding).
	badge.position=Vector2(Tokens.RAIL_WIDTH-16.0-16.0-4.0,4.0)
	button.add_child(badge)
	rail_buttons[id]=button
	rail_badges[id]=badge
	return button

func toggle_section(id:String)->void:
	if active_section==id:
		section_requested.emit("",0)
	else:
		section_requested.emit(id,0)

func set_active_section(id:String)->void:
	active_section=id
	for section_id in rail_buttons:
		var button:Button=rail_buttons[section_id]
		var active:bool=String(section_id)==id
		button.add_theme_stylebox_override("normal",Tokens.rail_button_style(active))
		button.add_theme_stylebox_override("hover",Tokens.rail_button_style(active,true))
		for child in button.get_child(0).get_children():
			if child is Label:
				(child as Label).add_theme_color_override("font_color",Tokens.INK if active else Tokens.TEXT_DIM)
	_position_toolbar()

func _set_badge(id:String,text:String,color:Color)->void:
	var badge:Label=rail_badges.get(id)
	if badge==null: return
	badge.visible=text!=""
	if text=="": return
	badge.text=text
	var pill:=Tokens.flat(color,Color(0,0,0,0),0,8)
	pill.content_margin_left=4.0
	pill.content_margin_right=4.0
	badge.add_theme_stylebox_override("normal",pill)
	# Labels have no stylebox slot; draw the pill via a nested panel setup.
	if badge.get_child_count()==0:
		var backing:=Panel.new()
		backing.name="Backing"
		backing.set_anchors_preset(Control.PRESET_FULL_RECT)
		backing.show_behind_parent=true
		backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
		badge.add_child(backing)
	var backing_panel:Panel=badge.get_node("Backing")
	backing_panel.add_theme_stylebox_override("panel",pill)

# --- Time pill --------------------------------------------------------------

func _build_time_pill()->void:
	time_pill=PanelContainer.new()
	time_pill.name="TimePill"
	var style:=Tokens.pill_style()
	style.content_margin_left=16.0
	style.content_margin_right=8.0
	style.content_margin_top=6.0
	style.content_margin_bottom=6.0
	time_pill.add_theme_stylebox_override("panel",style)
	add_child(time_pill)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	time_pill.add_child(row)
	time_text=RichTextLabel.new()
	time_text.bbcode_enabled=true
	time_text.fit_content=true
	time_text.autowrap_mode=TextServer.AUTOWRAP_OFF
	time_text.scroll_active=false
	time_text.custom_minimum_size=Vector2(300,32)
	time_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	time_text.add_theme_font_size_override("normal_font_size",15)
	time_text.add_theme_font_size_override("bold_font_size",15)
	row.add_child(time_text)
	var speed_row:=HBoxContainer.new()
	speed_row.add_theme_constant_override("separation",4)
	row.add_child(speed_row)
	for speed in 6:
		var speed_button:=Button.new()
		speed_button.text=SPEED_GLYPHS[speed]
		speed_button.tooltip_text=SPEED_TOOLTIPS[speed]
		speed_button.custom_minimum_size=Vector2(30,30)
		speed_button.add_theme_font_size_override("font_size",11)
		speed_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		speed_button.pressed.connect(_on_speed_pressed.bind(speed))
		speed_row.add_child(speed_button)
		speed_buttons.append(speed_button)
	_style_speed_buttons(0)

func _on_speed_pressed(speed:int)->void:
	if terrain and terrain.has_method("_set_game_speed"):
		terrain._set_game_speed(float(speed))

func _style_speed_buttons(selected:int)->void:
	for speed in speed_buttons.size():
		var button:=speed_buttons[speed]
		var active:=speed==selected
		var style:=Tokens.flat(Tokens.GOLD if active else Tokens.SPEED_IDLE_BG,Tokens.BORDER_2 if not active else Color(0,0,0,0),0 if active else 1,15)
		button.add_theme_stylebox_override("normal",style)
		button.add_theme_stylebox_override("hover",style)
		button.add_theme_stylebox_override("pressed",style)
		button.add_theme_color_override("font_color",Tokens.DARK_INK if active else Tokens.TEXT_DIM)
		button.add_theme_color_override("font_hover_color",Tokens.DARK_INK if active else Tokens.INK)

# --- KPI strip --------------------------------------------------------------

const KPI_DEFS:Array[Dictionary]=[
	{"id":"population","label":"POPULATION","accent":Tokens.GREEN,"section":"settlement","sub":0},
	{"id":"food","label":"FOOD","accent":Tokens.AMBER,"section":"economy","sub":0},
	{"id":"water","label":"WATER","accent":Tokens.TEAL,"section":"economy","sub":0},
	{"id":"health","label":"HEALTH","accent":Tokens.TEAL,"section":"health","sub":0},
	{"id":"labor","label":"LABOR","accent":Tokens.BLUE,"section":"settlement","sub":0},
]

func _build_kpi_strip()->void:
	kpi_strip=VBoxContainer.new()
	kpi_strip.name="KpiStrip"
	kpi_strip.add_theme_constant_override("separation",6)
	add_child(kpi_strip)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	kpi_strip.add_child(row)
	for def in KPI_DEFS:
		var chip:=Button.new()
		chip.name="Kpi"+String(def.id).capitalize()
		chip.custom_minimum_size=Vector2(0,Tokens.CHIP_HEIGHT)
		chip.add_theme_stylebox_override("normal",Tokens.chip_style(false))
		chip.add_theme_stylebox_override("hover",Tokens.chip_style(true))
		chip.add_theme_stylebox_override("pressed",Tokens.chip_style(true))
		chip.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		chip.pressed.connect(func()->void: section_requested.emit(String(def.section),int(def.sub)))
		row.add_child(chip)
		var inner:=HBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.add_theme_constant_override("separation",8)
		inner.mouse_filter=Control.MOUSE_FILTER_IGNORE
		chip.add_child(inner)
		var accent:=ColorRect.new()
		accent.color=def.accent
		accent.custom_minimum_size=Vector2(8,28)
		accent.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		accent.mouse_filter=Control.MOUSE_FILTER_IGNORE
		inner.add_child(accent)
		var text_column:=VBoxContainer.new()
		text_column.add_theme_constant_override("separation",0)
		text_column.alignment=BoxContainer.ALIGNMENT_CENTER
		text_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		inner.add_child(text_column)
		var caption:=Tokens.make_label(String(def.label),9,Tokens.MUTED,0.12)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text_column.add_child(caption)
		var value_row:=HBoxContainer.new()
		value_row.add_theme_constant_override("separation",6)
		value_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text_column.add_child(value_row)
		var value:=Tokens.make_label("—",15,Tokens.INK)
		value.mouse_filter=Control.MOUSE_FILTER_IGNORE
		value_row.add_child(value)
		var delta:=Tokens.make_label("",10,Tokens.MUTED)
		delta.mouse_filter=Control.MOUSE_FILTER_IGNORE
		delta.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
		value_row.add_child(delta)
		kpi_chips[String(def.id)]={"chip":chip,"value":value,"delta":delta,"inner":inner}

func _update_kpi(id:String,value_text:String,delta_text:String,delta_color:Color,tooltip:String)->void:
	var parts:Dictionary=kpi_chips.get(id,{})
	if parts.is_empty(): return
	(parts.value as Label).text=value_text
	var delta:Label=parts.delta
	delta.text=delta_text
	delta.add_theme_color_override("font_color",delta_color)
	var chip:Button=parts.chip
	chip.tooltip_text=tooltip
	# Buttons do not size to free-floating children; drive the chip width from
	# the inner content so labels never clip.
	var inner:Control=parts.inner
	chip.custom_minimum_size=Vector2(inner.get_combined_minimum_size().x+26.0,Tokens.CHIP_HEIGHT)

# --- Decision queue ---------------------------------------------------------

func _build_decision_queue()->void:
	queue_root=VBoxContainer.new()
	queue_root.name="DecisionQueue"
	queue_root.custom_minimum_size=Vector2(Tokens.QUEUE_WIDTH,0)
	queue_root.add_theme_constant_override("separation",6)
	add_child(queue_root)

func dismiss_alert(alert_id:String)->void:
	if not dismissed_alert_ids.has(alert_id):
		dismissed_alert_ids.append(alert_id)
	# Deferral is persistent: the item leaves the queue and will not return
	# unless its condition escalates. The record stays in the council ledger.
	AdvisorSystem.defer_council_item(alert_id)
	_queue_signature="__stale__"
	refresh()

func _severity_color(severity:String)->Color:
	match severity.to_lower():
		"danger","critical": return Tokens.RED
		"warning": return Tokens.AMBER
	return Tokens.TEAL

func _rebuild_queue(items:Array)->void:
	for child in queue_root.get_children():
		queue_root.remove_child(child)
		child.queue_free()
	queue_root.visible=not items.is_empty()
	if items.is_empty():
		return
	var shown:=0
	for item_variant in items:
		if shown>=MAX_QUEUE_CARDS: break
		var item:Dictionary=item_variant
		queue_root.add_child(_make_queue_card(item))
		shown+=1
	var merged:int=AdvisorSystem.routine_report_count() if typeof(AdvisorSystem)!=TYPE_NIL else 0
	var footer_row:=HBoxContainer.new()
	footer_row.alignment=BoxContainer.ALIGNMENT_END
	footer_row.add_theme_constant_override("separation",4)
	queue_root.add_child(footer_row)
	var counts:=Tokens.make_label("%d DECISION%s%s · " % [items.size(),"" if items.size()==1 else "S"," · %d MERGED" % merged if merged>0 else ""],10,Tokens.MUTED,0.12)
	footer_row.add_child(counts)
	var council_link:=Button.new()
	council_link.flat=true
	council_link.text="COUNCIL"
	council_link.add_theme_font_size_override("font_size",10)
	council_link.add_theme_color_override("font_color",Tokens.GOLD)
	council_link.add_theme_color_override("font_hover_color",Tokens.GOLD_BRIGHT)
	council_link.tooltip_text="Open the council ledger."
	council_link.pressed.connect(func()->void: section_requested.emit("civ",2))
	footer_row.add_child(council_link)
	queue_root.reset_size()
	_layout()

func _make_queue_card(item:Dictionary)->PanelContainer:
	var card:=PanelContainer.new()
	var style:=Tokens.flat(Tokens.PANEL_BG,Tokens.BORDER_SOFT,1,3)
	style.content_margin_top=8.0
	style.content_margin_bottom=8.0
	style.content_margin_right=10.0
	card.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	card.add_child(row)
	var stripe:=ColorRect.new()
	stripe.color=_severity_color(String(item.get("severity","notice" if String(item.get("topic",""))=="" else "warning")))
	stripe.custom_minimum_size=Vector2(4,0)
	stripe.size_flags_vertical=Control.SIZE_EXPAND_FILL
	row.add_child(stripe)
	var text_column:=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation",2)
	row.add_child(text_column)
	var title:=Tokens.make_label(String(item.get("text","Council item")).split("\n")[0],12,Tokens.INK)
	title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	title.max_lines_visible=1
	text_column.add_child(title)
	var subline:=Tokens.make_label("%s · %s · Day %d" % [String(item.get("office","Council")),String(item.get("advisor","")),int(item.get("day",0))],11,Tokens.MUTED)
	subline.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	subline.max_lines_visible=1
	text_column.add_child(subline)
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	row.add_child(actions)
	var decide:=Button.new()
	decide.text="DECIDE"
	decide.custom_minimum_size=Vector2(0,26)
	decide.add_theme_font_size_override("font_size",10)
	decide.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT)
	decide.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	decide.add_theme_stylebox_override("hover",Tokens.gold_outline_style())
	decide.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	decide.tooltip_text="Open the decision in the council."
	decide.pressed.connect(func()->void: section_requested.emit("civ",2))
	actions.add_child(decide)
	var dismiss:=Button.new()
	dismiss.text="×"
	dismiss.custom_minimum_size=Vector2(26,26)
	dismiss.add_theme_font_size_override("font_size",12)
	dismiss.add_theme_color_override("font_color",Tokens.MUTED)
	dismiss.add_theme_stylebox_override("normal",Tokens.flat(Color(0,0,0,0),Tokens.BORDER_2,1,3))
	dismiss.add_theme_stylebox_override("hover",Tokens.flat(Tokens.CLOSE_HOVER_BG,Tokens.BORDER_2,1,3))
	dismiss.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	dismiss.tooltip_text="Dismiss (stays in council record)"
	dismiss.pressed.connect(dismiss_alert.bind(String(item.get("id",""))))
	actions.add_child(dismiss)
	return card

# --- Map toolbar ------------------------------------------------------------

func _build_toolbar()->void:
	toolbar=PanelContainer.new()
	toolbar.name="MapToolbar"
	var style:=Tokens.flat(Tokens.TOOLBAR_BG,Tokens.BORDER,1,4,6.0)
	toolbar.add_theme_stylebox_override("panel",style)
	add_child(toolbar)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	var column:=VBoxContainer.new()
	toolbar.add_child(column)
	city_selector=OptionButton.new()
	city_selector.name="CitySelector"
	city_selector.custom_minimum_size=Vector2(240,32)
	city_selector.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	city_selector.tooltip_text="Choose a city to view its stores and move the map to it."
	city_selector.item_selected.connect(func(index:int)->void: terrain._select_city(String(city_selector.get_item_metadata(index))))
	column.add_child(city_selector)
	column.add_child(row)
	for action in [["settle","FOUND SETTLEMENT",true],["scouts","SEND SCOUTS",false],["diplomat","SEND DIPLOMAT",false],["convoy","FOCUS CONVOY",false]]:
		var button:=Button.new()
		button.name="Toolbar"+String(action[0]).capitalize()
		button.text=String(action[1])
		button.custom_minimum_size=Vector2(0,34)
		button.add_theme_font_size_override("font_size",11)
		button.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT if bool(action[2]) else Tokens.BODY)
		button.add_theme_color_override("font_disabled_color",Tokens.DISABLED)
		button.add_theme_stylebox_override("normal",Tokens.action_button_style(bool(action[2])))
		button.add_theme_stylebox_override("hover",Tokens.action_button_style(bool(action[2]),true))
		button.add_theme_stylebox_override("disabled",Tokens.action_button_style(false))
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		button.pressed.connect(_on_toolbar_action.bind(String(action[0])))
		row.add_child(button)
		toolbar_action_buttons[String(action[0])]=button
	var actions_divider:=_toolbar_divider()
	actions_divider.name="ToolbarActionsDivider"
	row.add_child(actions_divider)
	for layer in [["resources","RESOURCES","Land resources: green woodland supplies timber; pale exposed ground indicates stone; warm open ground shows productive soil. Click charted ground for details. Hidden deposits stay hidden."],["borders","BORDERS","Settlement claim"],["charted","CHARTED","Fog of observation"]]:
		var toggle:=Button.new()
		toggle.name="Layer"+String(layer[0]).capitalize()
		toggle.custom_minimum_size=Vector2(0,34)
		toggle.tooltip_text=String(layer[2])
		toggle.add_theme_font_size_override("font_size",10)
		toggle.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		toggle.pressed.connect(_on_layer_toggle.bind(String(layer[0])))
		row.add_child(toggle)
		toolbar_layer_buttons[String(layer[0])]={"button":toggle,"label":String(layer[1])}
	row.add_child(_toolbar_divider())
	var scale_box:=VBoxContainer.new()
	scale_box.alignment=BoxContainer.ALIGNMENT_CENTER
	scale_box.add_theme_constant_override("separation",3)
	row.add_child(scale_box)
	scale_line=ColorRect.new()
	scale_line.color=Tokens.LAYER_ON_FG
	scale_line.custom_minimum_size=Vector2(90,2)
	scale_box.add_child(scale_line)
	var scale_row:=HBoxContainer.new()
	scale_row.add_theme_constant_override("separation",8)
	scale_box.add_child(scale_row)
	scale_label=Tokens.make_label("",10,Tokens.MUTED)
	scale_row.add_child(scale_label)
	compass_label=Button.new()
	compass_label.text="NORTH ↑"
	compass_label.add_theme_font_size_override("font_size",12)
	compass_label.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT)
	compass_label.pressed.connect(func()->void: terrain._reset_camera_north())
	compass_label.tooltip_text="Click to reset north-up (N). Rotate with Q/E or Shift + middle-drag; drag vertically to tilt."
	scale_row.add_child(compass_label)
	var aerial_button:=Button.new()
	aerial_button.name="AerialAltitudeButton"
	aerial_button.text="10,000 FT"
	aerial_button.tooltip_text="Descend to 10,000 feet above the land under the camera. F7. Scroll to continue zooming."
	aerial_button.add_theme_font_size_override("font_size",10)
	aerial_button.pressed.connect(func()->void: terrain._inspect_aerial_altitude())
	scale_row.add_child(aerial_button)

	_refresh_layer_toggles()

func _toolbar_divider()->ColorRect:
	var divider:=ColorRect.new()
	divider.color=Tokens.BORDER
	divider.custom_minimum_size=Vector2(1,24)
	divider.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return divider

func _on_toolbar_action(id:String)->void:
	if terrain==null: return
	match id:
		"settle": terrain._on_settlement_action_pressed()
		"scouts": terrain._open_scout_dispatch_panel()
		"diplomat": terrain._open_diplomat_dispatch_panel()
		"convoy":
			var position_value:Variant=GameState.settlement_convoy.get("position",Vector2.ZERO)
			var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
			terrain._set_camera_target(Vector3(position_2d.x,terrain._height_at(position_2d.x,position_2d.y),position_2d.y))

func _on_layer_toggle(id:String)->void:
	layers[id]=not bool(layers.get(id,false))
	if id=="resources" and terrain:
		terrain._set_resource_view_enabled(bool(layers[id]))
	_refresh_layer_toggles()

func _refresh_layer_toggles()->void:
	for id in toolbar_layer_buttons:
		var entry:Dictionary=toolbar_layer_buttons[id]
		var button:Button=entry.button
		var on:=bool(layers.get(id,false))
		button.text=String(entry.label)+(" · ON" if on else "")
		button.add_theme_color_override("font_color",Tokens.LAYER_ON_FG if on else Tokens.MUTED)
		var style:=Tokens.flat(Tokens.BUTTON_BG,Tokens.LAYER_ON_BORDER if on else Tokens.BORDER_2,1,3)
		style.content_margin_left=12.0
		style.content_margin_right=12.0
		button.add_theme_stylebox_override("normal",style)
		button.add_theme_stylebox_override("hover",style)
	toolbar.reset_size()
	_position_toolbar()

var _scale_signature:String=""

func update_scale(pixel_width:float,distance_text:String,band:String,north:String)->void:
	if scale_line==null: return
	var signature:="%d|%s|%s|%s" % [roundi(pixel_width),distance_text,band,north]
	if signature==_scale_signature: return
	_scale_signature=signature
	scale_line.custom_minimum_size=Vector2(clampf(pixel_width,72.0,174.0),2)
	scale_label.text="%s · %s" % [band,distance_text]
	compass_label.text="NORTH %s" % north
	toolbar.reset_size()
	_position_toolbar()

# --- Dock -------------------------------------------------------------------

func _build_dock()->void:
	dock=DockPanelScript.new()
	dock.name="Dock"
	dock.visible=false
	add_child(dock)
	dock.close_requested.connect(func()->void: section_requested.emit("",0))
	dock.tab_changed.connect(func(sub:int)->void:
		_dock_signature=[]
		if dock.provider and dock.provider.has_method("open_expanded_tab") and dock.provider.open_expanded_tab(sub): close_dock())
	detail_dock=DockPanelScript.new()
	detail_dock.name="DetailDock"
	detail_dock.back_mode=true
	detail_dock.visible=false
	add_child(detail_dock)
	detail_dock.close_requested.connect(close_detail)

func register_provider(id:String,provider:Object)->void:
	providers[id]=provider

func has_provider(id:String)->bool:
	return providers.has(id)

func open_dock(section:String,sub:int,expanded:bool=true)->void:
	if not providers.has(section): return
	if expanded and providers[section].has_method("open_expanded_tab") and providers[section].open_expanded_tab(sub):
		close_dock();return
	var was_open:=dock.visible
	detail_history.clear()
	detail_dock.visible=false
	_layout()
	set_active_section(section)
	dock.present(providers[section],sub)
	_dock_signature=(providers[section] as Object).signature()+[sub]
	dock.visible=true
	if not was_open:
		# Slide in from the rail edge over 160 ms.
		var target_x:=Tokens.DOCK_X
		dock.position.x=Tokens.RAIL_WIDTH
		var tween:=create_tween()
		tween.tween_property(dock,"position:x",target_x,0.16).set_ease(Tween.EASE_OUT)

func close_dock()->void:
	dock.visible=false
	detail_dock.visible=false
	detail_history.clear()
	set_active_section("")

func open_detail(provider:Object,sub:int=0)->void:
	# One report at a time; retain the exact parent tab and scroll position.
	var returning:Dictionary={}
	for index in range(detail_history.size()-1,-1,-1):
		if detail_history[index].provider==provider:
			returning=detail_history[index];detail_history.resize(index);break
	if returning.is_empty() and detail_dock.visible and detail_dock.provider!=provider:
		detail_history.append({"provider":detail_dock.provider,"sub":detail_dock.sub,"scroll":detail_dock.body_scroll.scroll_vertical})
	dock.visible=false
	_layout()
	detail_dock.present(provider,sub)
	if not returning.is_empty():detail_dock.body_scroll.set_deferred("scroll_vertical",returning.scroll)
	_detail_signature=(provider as Object).signature()+[sub]
	detail_dock.visible=true

func close_detail()->void:
	if not detail_dock or not detail_dock.visible: return
	if not detail_history.is_empty():
		var previous:Dictionary=detail_history.pop_back()
		detail_dock.present(previous.provider,previous.sub)
		detail_dock.body_scroll.set_deferred("scroll_vertical",previous.scroll)
		_detail_signature=previous.provider.signature()+[previous.sub]
		return
	detail_dock.visible=false
	dock.visible=active_section!="" and dock.provider!=null
	if dock.visible: dock.rebuild_body()

func live_refresh_dock()->void:
	## Called on the terrain's 0.75s live-report tick; rebuilds the dock body
	## only when the active provider's signature changes.
	if dock and dock.visible and dock.provider and not _dock_interaction_active(dock):
		var signature:Array=(dock.provider as Object).signature()+[dock.sub]
		if signature.hash()!=_dock_signature.hash():
			_dock_signature=signature
			dock.rebuild_body()
	if detail_dock and detail_dock.visible and detail_dock.provider and not _dock_interaction_active(detail_dock):
		var detail_signature:Array=(detail_dock.provider as Object).signature()+[detail_dock.sub]
		if detail_signature.hash()!=_detail_signature.hash():
			_detail_signature=detail_signature
			detail_dock.rebuild_body()


func request_immediate_dock_refresh()->void:
	## Player actions are different from background simulation refreshes. The
	## background path waits until the pointer leaves the dock so controls never
	## move underneath a click; an action that has already completed must redraw
	## immediately. Defer one frame so the emitting button/row can finish safely.
	call_deferred("_refresh_active_dock_after_action")


func _refresh_active_dock_after_action()->void:
	if detail_dock and detail_dock.visible and detail_dock.provider:
		_detail_signature=detail_dock.provider.signature()+[detail_dock.sub]
		detail_dock.rebuild_body()
	elif dock and dock.visible and dock.provider:
		_dock_signature=dock.provider.signature()+[dock.sub]
		dock.rebuild_body()

# --- Refresh ----------------------------------------------------------------

func _unhandled_key_input(event:InputEvent)->void:
	var key:=event as InputEventKey
	if key==null or not key.pressed or key.echo: return
	var keys:={KEY_F1:"settlement",KEY_F2:"economy",KEY_F3:"civ",KEY_F4:"inquiry",KEY_F5:"world",KEY_F6:"military"}
	if keys.has(key.keycode):
		toggle_section(String(keys[key.keycode]))
		get_viewport().set_input_as_handled()

func _dock_interaction_active(panel:Control)->bool:
	## Never rebuild while the player is mid-typing in a dock input, and never
	## rebuild under the pointer: destroying the hovered control closes its
	## tooltip instantly and can pull a button out from under a click. The body
	## refreshes on the next tick after the pointer leaves the panel.
	if panel.get_global_rect().has_point(panel.get_global_mouse_position()): return true
	for editor_variant in panel.find_children("*","LineEdit",true,false):
		var editor:=editor_variant as LineEdit
		if editor and (editor.has_focus() or not editor.text.strip_edges().is_empty()): return true
	return false

func handle_escape()->bool:
	if detail_dock and detail_dock.visible:
		close_detail()
		return true
	if dock and dock.visible:
		close_dock()
		return true
	if active_section!="":
		escape_pressed.emit()
		return true
	return false

func _temperature_text()->String:
	# Temperature replaces the season name: it carries the same annual signal the
	# food model actually uses, plus day-scale weather, and it is local truth
	# rather than a calendar label.
	var today:float=terrain.site_temperature_c()
	var yesterday:float=terrain.site_temperature_c(maxf(0.0,GameState.elapsed_days-1.0))
	var trend:="→"
	if today-yesterday>0.3: trend="↑"
	elif today-yesterday<-0.3: trend="↓"
	# The climate model works in °C; the display speaks Fahrenheit.
	return "%d°F %s" % [roundi(today*1.8+32.0),trend]

func refresh()->void:
	if terrain==null: return
	_refresh_city_selector()
	_refresh_time()
	_refresh_kpis()
	_refresh_badges()
	_refresh_queue()
	_refresh_toolbar()

func _refresh_time()->void:
	var absolute_hour:=int(floor(GameState.elapsed_days*24.0))
	var absolute_day:=absolute_hour/24
	var year:=absolute_day/365+1
	var day_of_year:=absolute_day%365+1
	var speed:=int(terrain.game_speed)
	var temperature_text:=_temperature_text()
	var signature:="%d|%d|%d|%s" % [year,day_of_year,speed,temperature_text]
	if signature==_time_signature: return
	_time_signature=signature
	var speed_text:="paused" if speed==0 else SPEED_TOOLTIPS[clampi(speed,0,5)]
	time_text.text="[b][color=#f0e6d1]Year %d · Day %d[/color][/b][color=#8a948f] · %s · %s[/color]" % [year,day_of_year,temperature_text,speed_text]
	time_pill.tooltip_text="Local air temperature at the settlement. The annual warm–cold cycle drives food yields and cold-season rations; the arrow is the day-to-day trend."
	_style_speed_buttons(speed)
	time_pill.reset_size()
	_layout()

func _refresh_kpis()->void:
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void: SettlementModel.with_local_population(_refresh_local_kpis))

func _refresh_local_kpis()->void:
	var metrics:Dictionary=GameState.simulation_metrics
	var water:Dictionary=GameState.water_metrics
	var population:=GameState.population_total
	var health:=roundi(GameState.population_health*100.0)
	var food_days:=float(metrics.get("food_days",0.0))
	var food_balance:=float(metrics.get("food_balance",0.0))
	var vital_balance:Dictionary=GameState.rolling_vital_balance(365)
	var births:=int(vital_balance.get("births",0))
	var deaths:=int(vital_balance.get("deaths",0))
	var vital_net:=int(vital_balance.get("net",births-deaths))
	var efficiency:=roundi(float(metrics.get("labor_efficiency",0.0))*100.0)
	var able:=int(terrain._able_population())
	var assigned:=0
	for role in GameState.population_allocations:
		assigned+=int(GameState.population_allocations[role])
	var idle:=maxi(0,able-assigned)
	var water_days:=float(water.get("days",0.0))
	var water_intake:=roundi(float(water.get("intake_ratio",1.0))*100.0)
	var signature:="%d|%d|%.1f|%.1f|%d|%d|%d|%d|%.1f|%d" % [population,health,food_days,food_balance,births,deaths,efficiency,idle,water_days,water_intake]
	if signature==_kpi_signature: return
	_kpi_signature=signature
	var vital_text:="B %d − D %d = %+d · 12M" % [births,deaths,vital_net]
	var vital_color:=Tokens.GREEN if vital_net>0 else (Tokens.RED if vital_net<0 else Tokens.MUTED)
	_update_kpi("population",str(population),vital_text,vital_color,"Population %d · trailing 12 months: %d births − %d deaths = %+d natural change. Click for people and labor." % [population,births,deaths,vital_net])
	var projected:=float(metrics.get("food_projected_days",food_days))
	if food_balance<0.0:
		_update_kpi("food","%.1f d" % food_days,"▼ shortage %dd" % roundi(projected),Tokens.RED,"Days of adult-equivalent rations in store. Net %.1f/day." % food_balance)
	else:
		_update_kpi("food","%.1f d" % food_days,"▲",Tokens.GREEN,"Days of adult-equivalent rations in store. Net %+.1f/day." % food_balance)
	_update_kpi("water","%.1f d" % water_days,"NEED %d%%" % water_intake,Tokens.GREEN if water_intake>=100 else Tokens.RED,"%.1f reserve days remain after today's use. NEED %d%% is the share of today's drinking requirement that was actually met; it is not storage fullness." % [water_days,water_intake])
	_update_kpi("health","%d%%" % health,"—",Tokens.MUTED,"Physical condition and freedom from preventable harm.")
	_update_kpi("labor","%d · %d%%" % [assigned,efficiency],"%d idle" % idle if idle>0 else "",Tokens.AMBER,"Assigned workers · effective work per assigned person. %d idle." % idle)
	kpi_strip.reset_size()
	_layout()

func _refresh_badges()->void:
	var decisions:=AdvisorSystem.council_decision_items(9,false).size()
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	var visible_foreign:=int(observation.get("visible_count",0))
	var metrics:Dictionary=GameState.simulation_metrics
	var danger:=_economy_danger_active(metrics,GameState.water_metrics)
	var signature:="%d|%d|%s" % [decisions,visible_foreign,danger]
	if signature==_badge_signature: return
	_badge_signature=signature
	_set_badge("civ",str(decisions) if decisions>0 else "",Tokens.RED)
	_set_badge("world",str(visible_foreign) if visible_foreign>0 else "",Tokens.AMBER)
	_set_badge("economy","!" if danger else "",Tokens.RED)


func _economy_danger_active(metrics:Dictionary,water:Dictionary)->bool:
	## A rail badge is an interruption, not a live gauge. Reserve size naturally
	## crosses round-number thresholds during collection and consumption, which
	## made the icon flash at high speed even while everybody ate and drank.
	## Only an actual sustained shortfall, or a critically low reserve still
	## falling, earns the red interruption badge; forecasts remain in the dock.
	var food_intake:=clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var food_days:=maxf(0.0,float(metrics.get("food_days",30.0)))
	var food_net:=float(metrics.get("food_net",0.0))
	var food_danger:=GameState.consecutive_food_shortage_days>=2.0 or food_intake<0.90 or (food_days<7.0 and food_net<0.0)
	var water_required:=maxf(0.0,float(water.get("required_today",0.0)))
	var water_intake:=clampf(float(water.get("intake_ratio",1.0)),0.0,1.0)
	var water_danger:=water_required>0.0 and GameState.consecutive_water_shortage_days>=2.0 and water_intake<0.95
	return food_danger or water_danger

func _refresh_queue()->void:
	# Only unread decisions interrupt at the bottom right; answered history,
	# deferred decisions, and merged routine reports live in the council dock.
	# Deferral is tracked on the ledger item itself, so an escalated condition
	# can legitimately reappear here even after an earlier dismissal.
	var items:Array=AdvisorSystem.council_decision_items(9,false)
	var signature:="sig:"
	for item_variant in items:
		signature+=String((item_variant as Dictionary).get("id",""))+"|"
	if signature==_queue_signature: return
	_queue_signature=signature
	_rebuild_queue(items)

func _refresh_toolbar()->void:
	var settle:Button=toolbar_action_buttons.get("settle")
	var scouts:Button=toolbar_action_buttons.get("scouts")
	var diplomat:Button=toolbar_action_buttons.get("diplomat")
	var convoy:Button=toolbar_action_buttons.get("convoy")
	var convoy_active:=bool(GameState.settlement_convoy.get("active",false))
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var scout_quote:Dictionary=CivilizationSystem.scout_mission_quote(30,"open_world") if not bool(exploration.get("active",false)) else {}
	var scout_presentation:Dictionary=terrain._scout_action_presentation(exploration,scout_quote)
	var diplomatic_status:Dictionary=CivilizationSystem.diplomatic_mission_status()
	var known_destinations:=0
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		if bool((encounter_variant as Dictionary).get("home_location_known",false)): known_destinations+=1
	var diplomat_presentation:Dictionary=terrain._diplomat_action_presentation(diplomatic_status,known_destinations)
	var settle_text:String
	var settle_tooltip:String
	var settle_disabled:=false
	if not GameState.settlement_site_committed:
		settle_text="FOUND SETTLEMENT"
		settle_tooltip="Halt the founding convoy at its exact current location and establish the first settlement."
	elif terrain.settlement_convoy_targeting:
		settle_text="CANCEL SITE SELECTION"
		settle_tooltip="Leave destination-selection mode without paying any cost."
	elif convoy_active:
		settle_text="FOCUS SETTLEMENT CONVOY"
		settle_tooltip="Move the camera to the active settlement convoy."
	elif "Hearth Circle" not in GameState.settlement_completed:
		settle_text="FOUNDING COMMITTED"
		settle_tooltip="The first settlement is already committed here. Complete the Hearth Circle before organizing another founding convoy."
		settle_disabled=true
	else:
		settle_text="FOUND NEW SETTLEMENT"
		settle_tooltip="Enter temporary destination-selection mode. Route and cost are reviewed before anything is committed."
	# An action that can neither be taken nor report anything does not earn a
	# toolbar slot; it appears when it becomes possible. Away-mission states
	# stay visible because their countdown IS the information.
	var settle_visible:=not settle_disabled
	var scouts_visible:=not bool(scout_presentation.disabled) or bool(exploration.get("active",false))
	var diplomat_visible:=not bool(diplomat_presentation.disabled) or bool(diplomatic_status.get("active",false))
	var signature:="%s|%s|%s|%s|%s|%s|%s" % [settle_text,String(scout_presentation.label),String(diplomat_presentation.label),convoy_active,settle_visible,scouts_visible,diplomat_visible]
	if signature==_toolbar_signature: return
	_toolbar_signature=signature
	settle.text=settle_text
	settle.tooltip_text=settle_tooltip
	settle.disabled=settle_disabled
	settle.visible=settle_visible
	# The presentation is the single authority on the label — it carries the
	# soonest return countdown (or OVERDUE) whenever any party is out.
	scouts.text=String(scout_presentation.label)
	scouts.disabled=bool(scout_presentation.disabled)
	scouts.tooltip_text=String(scout_presentation.tooltip)
	scouts.visible=scouts_visible
	diplomat.text="SEND DIPLOMAT" if not bool(diplomatic_status.get("active",false)) else "ENVOYS AWAY · %dD" % int(diplomatic_status.get("days_remaining",0))
	diplomat.disabled=bool(diplomat_presentation.disabled)
	diplomat.tooltip_text=String(diplomat_presentation.tooltip)
	diplomat.visible=diplomat_visible
	convoy.visible=convoy_active
	convoy.tooltip_text="Center the camera on the traveling settlement convoy."
	var actions_divider:=toolbar.find_child("ToolbarActionsDivider",true,false)
	if actions_divider: actions_divider.visible=settle_visible or scouts_visible or diplomat_visible or convoy_active
	toolbar.reset_size()
	_position_toolbar()

func _refresh_city_selector()->void:
	if city_selector==null: return
	var settlements:=GameState.player_settlements
	var signature:=GameState.selected_player_settlement_id+str(GameState.settlement_network_revision)+str(settlements.size())
	if signature==city_selector_signature: return
	city_selector_signature=signature
	city_selector.clear()
	city_selector.visible=not settlements.is_empty()
	for city in settlements:
		city_selector.add_item(String(city.get("name","Settlement")))
		var index:=city_selector.item_count-1
		city_selector.set_item_metadata(index,String(city.id))
		if String(city.id)==GameState.selected_player_settlement_id: city_selector.select(index)
