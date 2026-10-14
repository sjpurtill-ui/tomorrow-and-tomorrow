extends Control
## Command Rail HUD shell: left rail, time pill, KPI strip, decision queue,
## and map toolbar. The map stays visible and interactive behind everything.
## Design source: design_handoff_command_rail_hud (1920x1080, values final).

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const DockPanelScript:=preload("res://scripts/hud/dock_panel.gd")
const NavIcon:=preload("res://scripts/hud/hud_chrome_icon.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Folio:=preload("res://scripts/hud/reference_folio.gd")
const TopbarInk:=preload("res://scripts/hud/topbar_ink.gd")

signal section_requested(section:String,sub:int)
signal menu_requested
signal escape_pressed

## The original approved nine painted destinations lead the rail. Additional
## existing destinations follow in the same scrollable column.
const SECTIONS:Array[Dictionary]=[
	{"id":"settlement","label":"Overview","tooltip":"This settlement: its people, leader, stores and buildings"},
	{"id":"overview","label":"People","tooltip":"The people: how many, how fed, how long they live · F1"},
	{"id":"economy","label":"Food","sub":0,"tooltip":"Food and water · F2"},
	{"id":"materials","label":"Materials","section":"economy","sub":1,"tooltip":"Material stores and supply"},
	{"id":"wealth","label":"Wealth","section":"economy","sub":2,"tooltip":"Wealth, gifts and exchange"},
	{"id":"construction","label":"Buildings","tooltip":"Construction and infrastructure · F7"},
	{"id":"production","label":"Production","tooltip":"Crafts, tools and weapons in the making · F9"},
	{"id":"civ","label":"Culture","tooltip":"Society and civic dialogue · F4"},
	{"id":"military","label":"Security","tooltip":"War: how many serve, our enemies and our leaders · F8"},
	{"id":"eyes","label":"Eyes","tooltip":"Our eyes among other peoples and the wary watching for theirs: how hard we watch each people and our own, and what came back · F3"},
	{"id":"trade","label":"Trade","section":"economy","sub":3,"tooltip":"Trade with other peoples: what passes, who leans on whom, and pressure"},
	{"id":"inquiry","label":"Research","tooltip":"What the people know and are learning · F5"},
	{"id":"world","label":"World","tooltip":"The world your scouts have walked, and who lives in it · F6"},
	{"id":"chronicle","label":"Chronicle","tooltip":"The story of your people: moments, news and the seasons' tallies · F11"},
	{"id":"standing","label":"Standing","tooltip":"What we are, how every people we know sees us, and what it makes them do"},
]
## ONE SCREEN PER CATEGORY. The rail holds one button for each category; the
## pages of a category are tabs of its one screen (dock_panel.gd lays every
## page's tabs out in a single row). `pages` are section ids, the first the
## page the button opens; `tabs` renames a page's tabs where its own names
## would not say enough beside their neighbours.
const CATEGORIES:Array[Dictionary]=[
	{"id":"home","label":"Home","pages":["settlement","overview","civ"],"tabs":{"settlement":["Overview","History"],"overview":["People"],"civ":["Culture","Council"]},"tooltip":"This settlement, its people and their ways"},
	{"id":"economy","label":"Economy","pages":["economy","production"],"tabs":{"economy":["Food","Materials","Wealth","Trade"],"production":["Workshops","Goods","Arms"]},"tooltip":"Food and water, materials, wealth, trade and what is being made · F2"},
	{"id":"construction","label":"Buildings","pages":["construction"],"tooltip":"Construction and infrastructure · F7"},
	{"id":"inquiry","label":"Research","pages":["inquiry"],"tooltip":"What the people know and are learning · F5"},
	{"id":"military","label":"War","pages":["military"],"tooltip":"War: how many serve, our enemies and our leaders · F8"},
	{"id":"world","label":"World","pages":["world","standing","eyes"],"tabs":{"world":["Peoples","Expeditions","History"],"standing":["Standing"],"eyes":["Spies"]},"tooltip":"The world your scouts have walked, who lives in it, how they see us and what our eyes report · F6"},
	{"id":"chronicle","label":"Chronicle","pages":["chronicle"],"tooltip":"The story of your people: moments, news and the seasons' tallies · F11"},
]
## The category a page belongs to ({} for none).
static func category_of(section:String)->Dictionary:
	for category:Dictionary in CATEGORIES:
		if section in (category.pages as Array):return category
	return {}
## The page of each category last opened, so its button returns there.
var _last_page:Dictionary={}
## Alerts of every page, summed onto its category's button.
var _page_alerts:Dictionary={}
const EraWords:=preload("res://scripts/hud/era_words.gd")
## The WATER tile's one reading of every town's water and the dry year.
const WaterWatch:=preload("res://scripts/hud/water_watch.gd")
## Time controls speak in words: Pause, then five paces from slowest to fastest.
const SPEED_LABELS:Array[String]=["Pause","Slowest","Slow","Normal","Fast","Fastest"]

var city_selector:OptionButton
var city_selector_signature:String=""
var terrain:Node

var active_section:String=""

var rail_panel:PanelContainer
var top_frame:PanelContainer
var brand_row:HBoxContainer
var brand_label:Label
var top_readings:Control
var top_actions:HBoxContainer
var rail_buttons:Dictionary={}
var rail_badges:Dictionary={}
var rail_icons:Dictionary={}
var rail_labels:Dictionary={}
var _words_signature:=""
var time_pill:PanelContainer
var time_text:RichTextLabel
var pause_button:Button
var speed_buttons:Array[Button]=[]
var last_running_speed:=1
var kpi_strip:PanelContainer
var kpi_chips:Dictionary={}
var kpi_separators:Array[ColorRect]=[]
var toolbar:PanelContainer
var toolbar_wrap:Control
var toolbar_action_buttons:Dictionary={}
var scale_line:ColorRect
var scale_label:Label
var compass_label:Button
const MapCompass:=preload("res://scripts/hud/map_compass.gd")
const TOOLBAR_FONT_SIZE:=14
## The one hover card for the whole top bar (hud/hover_card.gd).
var hover_cards:CanvasLayer

var dock:PanelContainer
var detail_dock:PanelContainer
var providers:Dictionary={}
var _dock_signature:Array=[]
var _detail_signature:Array=[]
var detail_history:Array=[]

var _kpi_signature:String=""
var _time_signature:String=""
var _toolbar_signature:String=""
var _information_refresh_elapsed:float=0.0
const INFORMATION_REFRESH_SECONDS:float=0.75

func _process(delta:float)->void:
	_information_refresh_elapsed+=maxf(delta,0.0)
	if _information_refresh_elapsed<INFORMATION_REFRESH_SECONDS:return
	_information_refresh_elapsed=fmod(_information_refresh_elapsed,INFORMATION_REFRESH_SECONDS)
	refresh_information_bar()
	_sync_order_layer()

func refresh_information_bar()->void:
	# The command bar owns its updates, including while a report is open.
	# Legacy interface controls and dock interaction must not gate live totals.
	if not is_instance_valid(terrain):return
	_refresh_words()
	_refresh_time()
	_refresh_kpis()

func _ready()->void:
	name="CommandRailHud"
	theme=Tokens.control_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_build_frame()
	_build_rail()
	_build_time_pill()
	_build_kpi_strip()
	_build_toolbar()
	_build_army_bar()
	_build_dock()
	_build_order_stack()
	dock.visibility_changed.connect(_layout)
	detail_dock.visibility_changed.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	refresh()

func _layout()->void:
	var view:=get_viewport().get_visible_rect().size
	var page_width:=Folio.page_width(view.x)
	for id in rail_buttons:(rail_buttons[id] as Button).custom_minimum_size.y=78.0
	if top_frame:
		top_frame.position=Vector2(Folio.RAIL_WIDTH,0)
		top_frame.size=Vector2(page_width,Folio.TOP_HEIGHT)
	# The olive band behind the top bar spans the map in every map mode.
	var band:=get_node_or_null("MapTopTint") as Control
	if band:
		band.position=Vector2(Folio.RAIL_WIDTH,0);band.size=Vector2(view.x-Folio.RAIL_WIDTH,Folio.TOP_HEIGHT)
	if rail_panel:
		rail_panel.position=Vector2.ZERO
		rail_panel.size=Vector2(Folio.RAIL_WIDTH,view.y)
	if brand_label:brand_label.visible=false
	if brand_row:
		brand_row.add_theme_constant_override("separation",10)
		# The town's name stands on the bar only when there is a choice of towns.
		var city_mark:=brand_row.get_node_or_null("TopCityIcon") as Control
		if city_mark:city_mark.visible=view.x>=1280 and city_selector!=null and city_selector.visible
	if city_selector:city_selector.custom_minimum_size.x=80 if view.x<1280 else 150
	if top_actions:top_actions.position=Vector2(view.x-top_actions.get_combined_minimum_size().x-12,6)
	if time_pill:
		var actions_width:=top_actions.get_combined_minimum_size().x+24 if top_actions else 0.0
		var clock_width:=time_pill.get_combined_minimum_size().x
		time_pill.position=Vector2(maxf(Folio.RAIL_WIDTH+8,view.x-actions_width-clock_width),7)
		if top_frame:
			top_frame.size.x=minf(page_width,maxf(280.0,time_pill.position.x-Folio.RAIL_WIDTH-12.0))
	if kpi_strip:
		# Retain the original formatting and hover sources; the persistent bar
		# presents their readings instead of a second row of boxed chips.
		kpi_strip.visible=false
		# The status strip is a fixed-height top-bar component. At the minimum
		# supported canvas, retain the urgent food, survival and GDP outcomes and
		# hide duplicate context instead of wrapping downward over the map.
		var compact_top:=view.x<1280
		for id in kpi_chips:(kpi_chips[id].chip as Control).visible=true
		for rule in kpi_separators:rule.visible=true
		if compact_top:
			_hide_kpi("population");_hide_kpi("water")
		# Before writing, tools and gear are told in the People view, not the strip.
		if compact_top or EraWords.hearth():_hide_kpi("goods")
		# Before writing, who ate today is told in the PEOPLE chip itself; a
		# separate "bellies filled" count only repeated the head count.
		if EraWords.hearth():_hide_kpi("gdp")
		# Never over the clock and the pace buttons: every reading shows in
		# full, so when the bar left of the clock is too narrow for them all,
		# the least urgent go first (KPI_SHED_ORDER); food, lives and the day's
		# labour always stay.
		if top_readings and top_frame:
			var room:=top_frame.size.x-40.0
			if city_selector!=null and city_selector.visible:room-=city_selector.custom_minimum_size.x+10.0+(36.0 if view.x>=1280 else 0.0)
			for id in KPI_SHED_ORDER:
				if top_readings.needed_width(kpi_readings())<=room:break
				_hide_kpi(String(id))
		kpi_strip.reset_size()
		kpi_strip.position=Vector2(maxf(Folio.RAIL_WIDTH+12.0,view.x-Tokens.EDGE_MARGIN-kpi_strip.size.x),Folio.TOP_HEIGHT+8.0)
	if top_readings:
		top_readings.visible=true
		top_readings.show_readings(kpi_readings())
	_layout_orders()
	if dock:
		dock.position=Vector2(Folio.RAIL_WIDTH,Folio.TOP_HEIGHT)
		# Before the first container sort, autowrap labels report inflated
		# minimum heights and set_size clamps upward; defer so the assignment
		# lands after layout settles.
		dock.set_deferred("size",Vector2(Folio.page_width(view.x),view.y-Folio.TOP_HEIGHT))
	if detail_dock:
		detail_dock.position=Vector2(Folio.RAIL_WIDTH,Folio.TOP_HEIGHT)
		detail_dock.set_deferred("size",Vector2(Folio.page_width(view.x),view.y-Folio.TOP_HEIGHT))
	_position_toolbar()

func _work_queue_width(view_width:float)->float:
	return Folio.page_width(view_width)

func force_dock_layout()->void:
	## Synchronous layout for the capture harness (no idle frames before draw).
	var view:=get_viewport().get_visible_rect().size
	for panel in [dock,detail_dock]:
		if panel==null or not panel.visible: continue
		for sort_pass in 3:
			panel.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)
		panel.size=Vector2(Folio.page_width(view.x),view.y-Folio.TOP_HEIGHT)
		for sort_pass in 3:
			panel.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)
	# Capture only: "--capture-dock-scroll=<px>" shows a long page further down.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dock-scroll=") and dock!=null:
			dock.body_scroll.set_deferred("scroll_vertical",int(argument.trim_prefix("--capture-dock-scroll=")))
			# Again once the page has laid out (a short page clamps an early scroll).
			var later:=int(argument.trim_prefix("--capture-dock-scroll="))
			get_tree().create_timer(0.6).timeout.connect(func()->void: if is_instance_valid(dock): dock.body_scroll.scroll_vertical=later)
			if detail_dock!=null and detail_dock.visible:detail_dock.body_scroll.set_deferred("scroll_vertical",int(argument.trim_prefix("--capture-dock-scroll=")))

func _position_toolbar()->void:
	if toolbar==null: return
	var view:=get_viewport().get_visible_rect().size
	# On a compact enlarged UI, the management dock needs this space. Closing
	# it restores the map toolbar; keyboard map controls remain available.
	toolbar.visible=active_section==""
	var free_left:=Tokens.DOCK_DETAIL_X if active_section!="" else Folio.RAIL_WIDTH
	# Your orders hold the bottom right: the toolbar centres in the room left
	# of them when it fits there (else the cards stand above it).
	var right:=view.x
	if _orders_at_bottom():right=view.x-Tokens.EDGE_MARGIN-OrderStackScript.WIDTH-12.0
	# The War screen's column holds the right edge: the toolbar ends at it,
	# drawn a little smaller when it would not otherwise fit beside it.
	var fit:=1.0
	if war_open():
		right=minf(right,view.x-Tokens.EDGE_MARGIN-_war_layout("COLUMN_WIDTH")-8.0)
		fit=clampf((right-free_left-8.0)/maxf(1.0,toolbar.size.x),0.75,1.0)
	elif toolbar.size.x>right-free_left:right=view.x
	toolbar.scale=Vector2(fit,fit)
	toolbar.position=Vector2(free_left+(right-free_left)*0.5-toolbar.size.x*fit*0.5,view.y-Tokens.EDGE_MARGIN-toolbar.size.y*fit)
	_layout_orders()
	_position_army_bar()

# --- Army bar (hud/army_bar.gd): HOI4's army cards above the map toolbar ------

var army_bar:Control
func _build_army_bar()->void:
	army_bar=preload("res://scripts/hud/army_bar.gd").new()
	army_bar.terrain=terrain
	add_child(army_bar)
	_position_army_bar()

func _position_army_bar()->void:
	if army_bar==null:return
	var view:=get_viewport().get_visible_rect().size
	army_bar.terrain=terrain
	army_bar.set_meta("covered",(dock!=null and dock.visible) or (detail_dock!=null and detail_dock.visible))
	var free_left:=Tokens.DOCK_DETAIL_X if active_section!="" else Folio.RAIL_WIDTH
	var bottom:=toolbar.position.y-8.0 if toolbar!=null and toolbar.visible else view.y-Tokens.EDGE_MARGIN
	var height:float=army_bar.bar_height()
	var left:=free_left+16.0
	var help:Variant=terrain.get("map_help_button") if is_instance_valid(terrain) else null
	if help is Control and (help as Control).is_visible_in_tree() and (help as Control).get_global_rect().end.y>bottom-height:left=maxf(left,(help as Control).get_global_rect().end.x+12.0)
	var right:=view.x-Tokens.EDGE_MARGIN
	if _orders_at_bottom():right-=order_stack.size.x+12.0
	# The War screen's column holds the right edge while it is open.
	if war_open():right=minf(right,view.x-Tokens.EDGE_MARGIN-_war_layout("COLUMN_WIDTH")-12.0)
	army_bar.place(Rect2(left,bottom-height,maxf(0.0,right-left),height))

## Whether the War screen is open (hud/military_roster_screen.gd war_mode):
## its strip and column then hold the top left and the right edge.
func war_open()->bool:
	return preload("res://scripts/hud/army_bar.gd").war_open()

## The War screen's layout numbers (hud/war_board.gd COLUMN_WIDTH), read
## while it is open.
func _war_layout(key:String)->float:
	var board:GDScript=load("res://scripts/hud/war_board.gd") as GDScript
	if board!=null and key=="COLUMN_WIDTH":return float(board.call("column_width",get_viewport().get_visible_rect().size.x))
	return float(board.get_script_constant_map().get(key,0.0)) if board!=null else 0.0

## The top of what stands at the bottom right: your orders, or the map
## toolbar where it reaches under the right edge. The notices and the War
## screen's column stand down to it.
func right_stack_top()->float:
	var view:=get_viewport().get_visible_rect().size
	var top:=orders_top()
	if toolbar!=null and toolbar.visible and toolbar.position.x+toolbar.size.x>view.x-Tokens.EDGE_MARGIN-OrderStackScript.WIDTH:top=minf(top,toolbar.position.y-8.0)
	return top

## The top of what sits along the map's bottom edge (the army bar, else the
## toolbar), for anything that stands just above it.
func map_bottom_top()->float:
	if army_bar!=null and army_bar.visible:return army_bar.position.y+army_bar.size.y-army_bar.bar_height()
	return toolbar.position.y if toolbar!=null and toolbar.visible else get_viewport().get_visible_rect().size.y-Tokens.EDGE_MARGIN

func select_army(army_id:int)->void:
	if army_bar==null:return
	army_bar.refresh()
	for card:Dictionary in army_bar.cards:
		if army_id in (card.get("members",[]) as Array) or (army_id==0 and String(card.kind)=="home"):army_bar.select_card(card);return

# --- Your orders (hud/order_stack.gd): the fail-safe, bottom right ---------

const OrderStackScript:=preload("res://scripts/hud/order_stack.gd")
## Above the court (AudienceHallLayer 85) while it is open, so an order given
## there shows at once in the court's right margin; otherwise just above the
## HUD, under every other screen.
const ORDER_LAYER_COURT:=86
var order_layer:CanvasLayer
var order_stack:Control

func _build_order_stack()->void:
	order_layer=CanvasLayer.new();order_layer.name="OrderLayer"
	add_child(order_layer)
	order_stack=OrderStackScript.new()
	order_layer.add_child(order_stack)
	order_stack.open_requested.connect(_open_order_screen)
	order_stack.resized.connect(_layout_orders)
	order_stack.relayout.connect(_layout_orders)
	order_stack.visibility_changed.connect(_layout)
	_sync_order_layer()

func _court_open()->bool:
	var director:Node=get_tree().get_first_node_in_group("court_director") if is_inside_tree() else null
	return director!=null and director.has_method("court_open") and bool(director.call("court_open"))

func _sync_order_layer()->void:
	if order_layer==null:return
	var base:=get_canvas_layer_node()
	var layer:=ORDER_LAYER_COURT if _court_open() else (base.layer+1 if base!=null else 1)
	if order_layer.layer!=layer:
		order_layer.layer=layer
		_layout_orders()

## The stack's rect at the bottom right would lie under an open dock (or the
## court's card): then it shrinks to its one-line plate at the top right,
## where the status strip stands aside for the dock.
func _orders_covered(view:Vector2)->bool:
	var left:=view.x-Tokens.EDGE_MARGIN-OrderStackScript.WIDTH
	if _court_open():
		var court:=minf(1280.0,view.x-40.0)
		return (view.x+court)*0.5>left
	for panel in [dock,detail_dock]:
		if panel!=null and panel.visible and panel.position.x+panel.size.x>left-4.0:return true
	return false

func _orders_at_bottom()->bool:
	return order_stack!=null and order_stack.visible and not bool(order_stack.compact)

## The top of what stands at the bottom right (your orders).
func orders_top()->float:
	var view:=get_viewport().get_visible_rect().size
	if _orders_at_bottom():return order_stack.position.y-8.0
	return view.y-Tokens.EDGE_MARGIN

func _layout_orders()->void:
	if order_stack==null:return
	var view:=get_viewport().get_visible_rect().size
	var covered:=_orders_covered(view)
	# In the court there is no top bar to stand in: with no room in its
	# margin, the court's own transcript tells the order and the cards wait.
	order_stack.set_suppressed(covered and _court_open())
	order_stack.set_compact(covered and not _court_open())
	order_stack.reset_size()
	var size:Vector2=order_stack.get_combined_minimum_size()
	if bool(order_stack.compact):
		order_stack.position=Vector2(view.x-Tokens.EDGE_MARGIN-size.x,8.0)
	else:
		var bottom:=view.y-Tokens.EDGE_MARGIN
		# The map toolbar too wide to stand beside the cards: they stand above it.
		if toolbar!=null and toolbar.visible and toolbar.position.x+toolbar.size.x>view.x-Tokens.EDGE_MARGIN-size.x-4.0 and not _court_open():bottom=toolbar.position.y-8.0
		order_stack.position=Vector2(view.x-Tokens.EDGE_MARGIN-size.x,bottom-size.y)

## A card was clicked: the screen where that order lives ("military:2" is
## the Military screen's third page, the drill).
func _open_order_screen(screen:String)->void:
	if screen=="":return
	if screen=="court":
		if not _court_open():open_court()
		return
	var section:=screen.get_slice(":",0)
	var sub:=int(screen.get_slice(":",1)) if ":" in screen else 0
	section_requested.emit(section,sub)

# --- Rail -------------------------------------------------------------------

func _build_frame()->void:
	var tint:=ColorRect.new();tint.name="MapTopTint";tint.color=Color(Folio.OLIVE,0.86);tint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_preset(Control.PRESET_TOP_WIDE);tint.offset_left=Folio.RAIL_WIDTH;tint.offset_bottom=Folio.TOP_HEIGHT;add_child(tint)
	top_frame=PanelContainer.new();top_frame.name="TopFrame";top_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# The readings and clock share MapTopTint's uninterrupted background.
	var style:=Tokens.flat(Color.TRANSPARENT)
	top_frame.add_theme_stylebox_override("panel",style);add_child(top_frame)
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",20);margin.add_theme_constant_override("margin_right",20);top_frame.add_child(margin)
	brand_row=HBoxContainer.new();brand_row.add_theme_constant_override("separation",18);margin.add_child(brand_row)
	brand_label=Tokens.make_label("Tomorrow and Tomorrow",24,Tokens.INK);brand_label.add_theme_font_override("font",Tokens.font("voice"));brand_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;brand_row.add_child(brand_label)
	top_readings=preload("res://scripts/hud/folio_readings.gd").new()
	top_readings.visible=true
	top_readings.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	top_readings.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	brand_row.add_child(top_readings)
	top_readings.reading_selected.connect(func(section:String,sub:int)->void:section_requested.emit(section,sub))
	top_readings.reading_created.connect(func(button:Button)->void:_hover_host().attach(button,button.hover_spec))
	top_actions=HBoxContainer.new();top_actions.name="TopActions";top_actions.add_theme_constant_override("separation",6);add_child(top_actions)
	var court:=Button.new();court.name="TopCourt";court.tooltip_text="Open your court · F12";court.pressed.connect(open_court);top_actions.add_child(court)
	var world:=Button.new();world.name="TopWorld";world.tooltip_text="Known world · F6";world.pressed.connect(func()->void:section_requested.emit("world",0));top_actions.add_child(world)
	var menu:=Button.new();menu.name="RailMenu";menu.tooltip_text="Save, load, settings, or a new world (Esc).";menu.pressed.connect(func()->void:menu_requested.emit());top_actions.add_child(menu)
	var help:=Button.new();help.name="TopHelp";help.tooltip_text="Map controls and help";help.pressed.connect(func()->void:
		if is_instance_valid(terrain) and terrain.has_method("_toggle_map_help"):
			close_dock();terrain.call("_toggle_map_help"))
	top_actions.add_child(help)
	var buttons:Array[Button]=[court,world,menu,help]
	var regions:Array[Rect2]=[Rect2(1345,7,34,31),Rect2(1397,8,36,31),Rect2(1447,8,33,29),Rect2(1492,8,30,31)]
	for index in buttons.size():
		var button:=buttons[index]
		button.custom_minimum_size=Vector2(42,32);button.add_theme_font_override("font",Tokens.font("voice"));button.add_theme_font_size_override("font_size",16)
		button.add_theme_color_override("font_color",Folio.RAIL_TEXT);button.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT));button.add_theme_stylebox_override("hover",Folio.rail_style(false,true))
		var icon:=Folio.Approved.symbol(regions[index],28,28);button.add_child(icon);icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);icon.offset_left=7;icon.offset_right=-7;icon.offset_top=2;icon.offset_bottom=-2

func _build_rail()->void:
	rail_panel=PanelContainer.new();rail_panel.name="CommandRail"
	var style:=Tokens.flat(Folio.OLIVE);style.border_color=Color("9e9773");style.border_width_right=1
	rail_panel.add_theme_stylebox_override("panel",style);add_child(rail_panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);rail_panel.add_child(column)
	column.add_child(_make_court_button())
	var scroll:=ScrollContainer.new();scroll.name="RailScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;scroll.follow_focus=true;column.add_child(scroll)
	var entries:=VBoxContainer.new();entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL;entries.add_theme_constant_override("separation",0);scroll.add_child(entries)
	for category in CATEGORIES:entries.add_child(_make_rail_button(category))

func _make_rail_button(section:Dictionary)->Button:
	# Keyed by the category's first page, whose painted icon it wears.
	var id:=String((section.pages as Array)[0])
	var button:=Button.new();button.name="Rail"+id.capitalize().replace(" ","")
	if id=="civ":button.name="RailCivilization"
	button.custom_minimum_size=Vector2(0,78);button.tooltip_text=String(section.tooltip)
	button.add_theme_stylebox_override("normal",_approved_rail_style(false));button.add_theme_stylebox_override("hover",_approved_rail_style(false,true));button.add_theme_stylebox_override("pressed",_approved_rail_style(true));button.add_theme_stylebox_override("focus",_rail_focus_style())
	button.pressed.connect(func()->void:
		# Open on a page of this category: the button closes it. Else it
		# opens the page of the category last seen (its first, to begin with).
		if active_section in (section.pages as Array):section_requested.emit("",0);return
		section_requested.emit(String(_last_page.get(String(section.id),id)),0))
	var content:=VBoxContainer.new();content.set_anchors_preset(Control.PRESET_FULL_RECT);content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",2);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(content)
	var symbol:=Folio.rail_icon(id);symbol.custom_minimum_size=Vector2(40,40);symbol.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;symbol.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(symbol);rail_icons[id]=symbol
	var label:=Tokens.make_label(String(section.label),14,Folio.RAIL_TEXT);label.add_theme_font_override("font",Tokens.font("voice"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(label);rail_labels[id]=label
	var badge:=Label.new();badge.visible=false;badge.custom_minimum_size=Vector2(16,16);badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;badge.add_theme_font_size_override("font_size",12);badge.add_theme_color_override("font_color",Tokens.GLYPH_DARK);badge.position=Vector2(57,3);button.add_child(badge)
	rail_buttons[id]=button;rail_badges[id]=badge
	return button


## Rail labels and top-strip captions follow what the people know.
func _refresh_words()->void:
	var signature:="%s|%s|%s" % [EraWords.stage(),EraWords.has_boats(),EraWords.has_flight()]
	if signature==_words_signature:return
	_words_signature=signature
	for category in CATEGORIES:
		var label:Label=rail_labels.get(String((category.pages as Array)[0]))
		if label:label.text=String(category.label)
	var military:Button=rail_buttons.get("military")
	if military:
		var extra:=""
		if EraWords.has_boats():extra+=" · Shift+F5 the boats"
		if EraWords.has_flight():extra+=" · Shift+F6 the air service"
		military.tooltip_text="War: how many serve, our enemies and our leaders · F8"+extra
	for def in KPI_DEFS:
		var parts:Dictionary=kpi_chips.get(String(def.id),{})
		if parts.has("caption"):(parts.caption as Label).text=EraWords.word("kpi."+String(def.id),String(def.label))
	_kpi_signature=""
	_layout()

func _make_court_button()->Button:
	var button:=Button.new();button.name="RailCourt";button.custom_minimum_size=Vector2(0,58)
	button.tooltip_text="Your court: summon anyone, receive envoys, send word abroad · F12"
	button.add_theme_stylebox_override("normal",_approved_rail_style(false));button.add_theme_stylebox_override("hover",_approved_rail_style(false,true));button.add_theme_stylebox_override("focus",_rail_focus_style());button.pressed.connect(open_court)
	preload("res://scripts/hud/court_prewarm.gd").attach(button)
	var icon:=Folio.rail_icon("court");icon.set_anchors_preset(Control.PRESET_CENTER);icon.position=Vector2(-20,-22);icon.size=Vector2(40,44);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(icon)
	var badge:=Label.new();badge.visible=false;badge.position=Vector2(57,3);badge.add_theme_color_override("font_color",Tokens.GLYPH_DARK);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(badge);rail_badges["court"]=badge
	return button

func open_court()->void:
	var director:Node=get_tree().get_first_node_in_group("court_director") if is_inside_tree() else null
	if director!=null and director.has_method("toggle_court"):director.call("toggle_court")

func toggle_section(id:String)->void:
	if active_section==id:
		section_requested.emit("",0)
	else:
		section_requested.emit(id,0)

func set_active_section(id:String)->void:
	active_section=id
	for section_id in rail_buttons:
		var button:Button=rail_buttons[section_id]
		var active:bool=id!="" and id in (category_of(String(section_id)).get("pages",[]) as Array)
		button.add_theme_stylebox_override("normal",_approved_rail_style(active))
		button.add_theme_stylebox_override("hover",_approved_rail_style(active,true))
		var icon:Control=rail_icons.get(section_id)
		if icon:
			if icon.has_method("set_active"): icon.set_active(active)
			if icon.has_method("set_icon_color"): icon.set_icon_color(Folio.GOLD)
		var label:Label=rail_labels.get(section_id)
		if label:label.add_theme_color_override("font_color",Color.WHITE if active else Folio.RAIL_TEXT)
	_position_toolbar()

## THE RAIL'S BADGES ARE THE NOTICES: how many rows of the notice column
## belong to each rail button (hud/notification_stack.gd needing):
## {category id: count}. Nothing else sets a badge, so the notice header's
## total is always the sum of the rail's badges.
var _notice_counts:Dictionary={}

func set_notice_counts(counts:Dictionary)->void:
	_notice_counts=counts.duplicate()
	for category:Dictionary in CATEGORIES:
		var first:=String((category.pages as Array)[0])
		var alert:Dictionary=_page_alerts.get(first,{})
		_set_badge(first,String(alert.get("text","")),alert.get("color",Tokens.RED))

func _set_badge(id:String,text:String,color:Color)->void:
	# A page's alert stands on its category's button, summed with its
	# neighbours' (red if any of them is).
	var category:=category_of(id)
	if not category.is_empty():
		_page_alerts[id]={"text":text,"color":color}
		var count:=0;var marks:="";var urgent:=false;var tint:=color
		for page:String in category.pages:
			var alert:Dictionary=_page_alerts.get(page,{})
			var words:=String(alert.get("text",""))
			if words=="":continue
			if words.is_valid_int():count+=int(words)
			else:marks=words
			tint=alert.color
			urgent=urgent or alert.color==Tokens.RED
		var needing:=int(_notice_counts.get(String(category.id),0))
		if needing>0:count+=needing;urgent=true
		text=str(count) if count>0 else marks
		color=Tokens.RED if urgent else tint
		id=String((category.pages as Array)[0])
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
	style.content_margin_left=8.0
	style.content_margin_right=8.0
	style.content_margin_top=0.0
	style.content_margin_bottom=0.0
	style.bg_color=Color.TRANSPARENT
	style.border_width_left=0;style.border_width_top=0;style.border_width_right=0;style.border_width_bottom=0
	time_pill.add_theme_stylebox_override("panel",style)
	add_child(time_pill)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	time_pill.add_child(row)
	time_text=RichTextLabel.new()
	time_text.bbcode_enabled=true
	time_text.fit_content=true
	time_text.autowrap_mode=TextServer.AUTOWRAP_OFF
	time_text.scroll_active=false
	time_text.custom_minimum_size=Vector2(175,28)
	time_text.mouse_filter=Control.MOUSE_FILTER_PASS
	time_text.add_theme_font_size_override("normal_font_size",17)
	time_text.add_theme_font_size_override("bold_font_size",17)
	time_text.add_theme_font_override("bold_font",Tokens.font("ui_strong"))
	time_text.add_theme_font_override("normal_font",Tokens.font("voice"))
	time_text.add_theme_color_override("default_color",Folio.RAIL_TEXT)
	TopbarInk.apply(time_text)
	row.add_child(time_text)
	var speed_row:=HBoxContainer.new()
	speed_row.add_theme_constant_override("separation",2)
	row.add_child(speed_row)
	pause_button=Button.new()
	pause_button.name="PauseResume"
	pause_button.custom_minimum_size=Vector2(26,28)
	pause_button.add_theme_font_size_override("font_size",12)
	pause_button.pressed.connect(func()->void:
		_on_speed_pressed(last_running_speed if terrain and int(terrain.game_speed)==0 else 0))
	speed_row.add_child(pause_button)
	speed_buttons=[pause_button]
	for speed:int in range(1,6):
		var button:=Button.new()
		button.name="Speed%d"%speed
		button.text=["", "›", "››", "›››", "»", "»»"][speed]
		button.tooltip_text=SPEED_LABELS[speed]+" (key %d)" % speed
		button.custom_minimum_size=Vector2(22,28)
		button.add_theme_font_size_override("font_size",17)
		button.pressed.connect(_on_speed_pressed.bind(speed))
		speed_row.add_child(button)
		speed_buttons.append(button)
	_style_speed_controls(0)
	var host:=_hover_host()
	host.attach(time_text,_time_card)
	for index:int in speed_buttons.size():host.attach(speed_buttons[index],_speed_card.bind(index))

## The hover card host, made on first use (tests build parts of the bar alone).
func _hover_host()->CanvasLayer:
	if not is_instance_valid(hover_cards):
		hover_cards=preload("res://scripts/hud/hover_card.gd").new()
		add_child(hover_cards)
	return hover_cards

func _time_card()->Dictionary:
	if terrain==null:return {}
	var day:=int(floor(GameState.elapsed_days))
	return {"kicker":"Today","value":EraWords.when(day),
		"headline":"%s at the hearth today. The year's warm and cold decide how much the land yields and how much the people must eat." % _temperature_text().rstrip(" →↑↓"),
		"facts":[{"text":"Warming day by day" if _temperature_text().ends_with("↑") else "Cooling day by day" if _temperature_text().ends_with("↓") else "Much like yesterday","trend":1 if _temperature_text().ends_with("↑") else -1 if _temperature_text().ends_with("↓") else 0,"good":true}],
		"action":"Keys 0–5 stop time or set its pace"}

const SPEED_WORDS:Array[String]=["Time stands still","Half an hour a moment","Two hours a moment","A third of a day a moment","A day a moment","Six days a moment"]

func _speed_card(index:int)->Dictionary:
	var paused:=terrain!=null and int(terrain.game_speed)==0
	if index==0:
		return {"kicker":"Resume" if paused else "Stop time","value":"Paused" if paused else "Stop",
			"headline":"The world waits while you look and think." if not paused else "Time waits for you; press to let it run again at %s." % SPEED_WORDS[last_running_speed].to_lower(),
			"action":"Key 0"}
	return {"kicker":"Pace: %s" % SPEED_LABELS[index].to_lower(),"value":SPEED_WORDS[index],"headline":"How fast the days pass while you watch; slower paces let you follow each day's work.","action":"Key %d" % index}

func _on_speed_pressed(speed:int)->void:
	if terrain and terrain.has_method("_set_game_speed"):
		terrain._set_game_speed(float(speed))

func _style_speed_controls(selected:int)->void:
	selected=clampi(selected,0,5)
	if selected>0:last_running_speed=selected
	var paused:=selected==0
	pause_button.text="▶" if paused else "Ⅱ"
	pause_button.tooltip_text="Let time run again (key 0)" if paused else "Stop time (key 0)"
	for index:int in speed_buttons.size():
		var button:=speed_buttons[index]
		var active:=index==selected
		var normal:=Tokens.flat(Tokens.GOLD_WASH if active else Color.TRANSPARENT)
		if active:normal.border_color=Tokens.GOLD;normal.border_width_bottom=2
		var hover:=Tokens.flat(Tokens.HOVER_BG)
		button.add_theme_stylebox_override("focus",_rail_focus_style())
		for box:StyleBoxFlat in [normal,hover]:box.content_margin_left=3.0;box.content_margin_right=3.0
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",normal)
		button.add_theme_color_override("font_color",Folio.GOLD if active else Folio.RAIL_TEXT)
		button.add_theme_color_override("font_hover_color",Folio.RAIL_TEXT)
		button.add_theme_color_override("font_focus_color",Folio.RAIL_TEXT)
		button.add_theme_color_override("font_pressed_color",Folio.GOLD)
		TopbarInk.apply(button)

# --- KPI strip --------------------------------------------------------------

const KPI_DEFS:Array[Dictionary]=[
	{"id":"population","label":"POPULATION","width":140.0,"accent":Tokens.GREEN,"section":"overview","sub":0},
	{"id":"food","label":"FOOD","width":112.0,"accent":Tokens.AMBER,"section":"economy","sub":0},
	{"id":"water","label":"WATER","width":112.0,"accent":Tokens.TEAL,"section":"economy","sub":0},
	{"id":"goods","label":"GOODS","width":112.0,"accent":Tokens.AMBER,"section":"economy","sub":0},
	{"id":"health","label":"HEALTH","width":152.0,"accent":Tokens.TEAL,"section":"health","sub":0},
	{"id":"science","label":"SCIENCE","width":140.0,"accent":Tokens.GOLD,"section":"inquiry","sub":0},
	{"id":"gdp","label":"REAL GDP / DAY","width":136.0,"accent":Tokens.BLUE,"section":"economy","sub":2},
]

## Which status chips give way first when the top bar is too narrow for them
## all (after the age's own rules in _layout).
const KPI_SHED_ORDER:=["goods","science","water","population"]

## Caption, value and note have separate lines within the 72 px header.
## Insets keep them clear of the fine frame and the semantic bottom rule.
const KPI_HEIGHT:=64.0

func _build_kpi_strip()->void:
	kpi_strip=PanelContainer.new()
	kpi_strip.name="KpiStrip"
	kpi_strip.add_theme_stylebox_override("panel",Tokens.flat(Color.TRANSPARENT))
	add_child(kpi_strip)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",0)
	kpi_strip.add_child(row)
	kpi_separators.clear()
	for index:int in KPI_DEFS.size():
		var def:Dictionary=KPI_DEFS[index]
		if index>0:
			var divider:=ColorRect.new();divider.color=Color.TRANSPARENT;divider.custom_minimum_size=Vector2(4,26);divider.size_flags_vertical=Control.SIZE_SHRINK_CENTER;divider.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(divider);kpi_separators.append(divider)
		var chip:=preload("res://scripts/hud/kpi_detail_chip.gd").new()
		chip.metric_id=String(def.id)
		chip.name="Kpi"+String(def.id).capitalize()
		# Reserve one stable width for every state. In particular, the longer
		# shortage wording must not make the whole strip collide with the clock
		# and jump from the first row to the second while the simulation runs.
		chip.custom_minimum_size=Vector2(_kpi_width(String(def.id),float(def.width)),KPI_HEIGHT)
		chip.clip_contents=true
		chip.add_theme_stylebox_override("normal",Tokens.flat(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL))
		chip.add_theme_stylebox_override("hover",Tokens.flat(Tokens.HOVER_BG,Tokens.RULE_STRONG,1,Tokens.RADIUS_CONTROL))
		chip.add_theme_stylebox_override("pressed",Tokens.flat(Tokens.ACTIVE_BG))
		chip.add_theme_stylebox_override("focus",_rail_focus_style())
		chip.pressed.connect(func()->void: section_requested.emit(String(def.section),int(def.sub)))
		row.add_child(chip)
		_hover_host().attach(chip,chip.hover_spec)
		var inner:=HBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		# A gutter on the right keeps a chip's last word off the next caption.
		inner.offset_left=8.0
		inner.offset_right=-8.0
		inner.offset_top=2.0
		inner.offset_bottom=-4.0
		inner.add_theme_constant_override("separation",0)
		inner.mouse_filter=Control.MOUSE_FILTER_IGNORE
		chip.add_child(inner)
		var accent:=ColorRect.new()
		accent.color=def.accent
		accent.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		accent.offset_left=8;accent.offset_right=-8;accent.offset_top=-2
		accent.mouse_filter=Control.MOUSE_FILTER_IGNORE
		chip.add_child(accent)
		var text_column:=VBoxContainer.new()
		text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		text_column.clip_contents=true
		text_column.add_theme_constant_override("separation",0)
		text_column.alignment=BoxContainer.ALIGNMENT_CENTER
		text_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		inner.add_child(text_column)
		var caption_row:=HBoxContainer.new()
		caption_row.add_theme_constant_override("separation",4)
		caption_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text_column.add_child(caption_row)
		var mark:=NavIcon.new(String(def.id))
		mark.custom_minimum_size=Vector2(14,14)
		mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		mark.set_icon_color(Tokens.text_for(def.accent))
		caption_row.add_child(mark)
		var caption:=Tokens.make_label(EraWords.word("kpi."+String(def.id),String(def.label)),12,Tokens.INK_MUTED)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		caption_row.add_child(caption)
		# The value is the loudest line of the chip: SemiBold ink over a quiet kicker.
		var value:=Tokens.text(Tokens.make_label("—",20,Tokens.INK),"value",Tokens.INK) as Label
		value.add_theme_font_size_override("font_size",22)
		# Widths are sized for the longest real value; the ellipsis is only a
		# last guard against a runaway string pushing the strip over the clock.
		value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		value.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text_column.add_child(value)
		# The note (who went hungry, babes lost, keepers) sits on its own line.
		var delta:=Tokens.make_label("",12,Tokens.INK_MUTED)
		delta.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		delta.mouse_filter=Control.MOUSE_FILTER_IGNORE
		text_column.add_child(delta)
		kpi_chips[String(def.id)]={"chip":chip,"value":value,"delta":delta,"inner":inner,"width":float(def.width),"caption":caption,"accent":accent,"mark":mark,"accent_color":def.accent}

func kpi_readings()->Array[Dictionary]:
	## Project the exact visible strip values; do not recompute inside a city's
	## resource scope. The strip's parent is hidden while a page is open.
	var readings:Array[Dictionary]=[]
	for def:Dictionary in KPI_DEFS:
		var parts:Dictionary=kpi_chips.get(String(def.id),{})
		if parts.is_empty() or not (parts.chip as Control).visible:continue
		readings.append({"id":String(def.id),"caption":(parts.caption as Label).text,
			"value":(parts.value as Label).text,"note":(parts.delta as Label).text,
			"note_color":(parts.delta as Label).get_theme_color("font_color"),
			"section":String(def.section),"sub":int(def.sub)})
	return readings

func _update_kpi(id:String,value_text:String,delta_text:String,delta_color:Color,_tooltip:String)->void:
	var parts:Dictionary=kpi_chips.get(id,{})
	if parts.is_empty(): return
	(parts.value as Label).text=value_text
	var delta:Label=parts.delta
	delta.text=delta_text
	delta.visible=delta_text!=""
	delta.add_theme_color_override("font_color",Tokens.text_for(delta_color))
	# A warning note tints the chip's accent bar too, so it reads at a glance.
	if parts.has("accent"):(parts.accent as ColorRect).color=Tokens.RED if delta_color==Tokens.RED else parts.accent_color
	if parts.has("mark"):parts.mark.set_icon_color(Tokens.RED_TEXT if delta_color==Tokens.RED else Tokens.text_for(parts.accent_color))
	var chip:Button=parts.chip
	# Width is intentionally independent of live text so a deficit cannot move
	# the complete top bar. Hover details read fresh state when opened.
	chip.custom_minimum_size=Vector2(_kpi_width(id,float(parts.width)),KPI_HEIGHT)

## The first of `candidates` (most telling first) that fits the chip's note
## line without an ellipsis; the last one when none does.
func _fitting_note(id:String,candidates:Array)->String:
	if candidates.is_empty():return ""
	var parts:Dictionary=kpi_chips.get(id,{})
	if parts.is_empty():return String(candidates[0])
	var label:Label=parts.delta
	var font:Font=label.get_theme_font("font")
	var size:=label.get_theme_font_size("font_size")
	# The text column has equal eight-pixel left and right insets.
	var room:=_kpi_width(id,float(parts.width))-16.0
	for text in candidates:
		if font==null or font.get_string_size(String(text),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x<=room:return String(text)
	return String(candidates[-1])

## Stable widths per era: the people's words are longer than the acronyms.
## Hides one status chip and the rule beside it: the rule before it, or, for
## the first chip, the rule after it.
func _hide_kpi(id:String)->void:
	var parts:Dictionary=kpi_chips.get(id,{})
	if parts.is_empty():return
	(parts.chip as Control).visible=false
	for index in KPI_DEFS.size():
		if String(KPI_DEFS[index].id)!=id:continue
		var rule:=maxi(0,index-1)
		if rule<kpi_separators.size():kpi_separators[rule].visible=false
		return

func _kpi_width(id:String,base:float)->float:
	if EraWords.reckoned():return base
	# Value and note each have a full line: widths fit "1,240 souls",
	# "2 hearths · all fed", "28 in 100 babes lost" and "115 known".
	return float({"population":132.0,"food":112.0,"water":112.0,"goods":120.0,"health":138.0,"science":112.0,"gdp":116.0}.get(id,base))

# --- Map toolbar ------------------------------------------------------------

func _build_toolbar()->void:
	toolbar=PanelContainer.new()
	toolbar.name="MapToolbar"
	var style:=Tokens.paper_panel_style(false,Tokens.RADIUS_CARD,4.0)
	style.content_margin_left=8.0;style.content_margin_right=8.0
	toolbar.add_theme_stylebox_override("panel",style)
	add_child(toolbar)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	toolbar.add_child(row)
	city_selector=OptionButton.new()
	city_selector.name="CitySelector"
	city_selector.custom_minimum_size=Vector2(150,30)
	city_selector.fit_to_longest_item=false
	city_selector.add_theme_font_override("font",Tokens.font("voice"))
	city_selector.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT))
	city_selector.add_theme_font_size_override("font_size",19)
	TopbarInk.apply(city_selector)
	for color_key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		city_selector.add_theme_color_override(color_key,Folio.RAIL_TEXT)
	city_selector.add_theme_color_override("icon_normal_color",Folio.RAIL_TEXT)
	city_selector.add_theme_color_override("icon_hover_color",Folio.RAIL_TEXT)
	city_selector.add_theme_stylebox_override("hover",Folio.rail_style(false,true))
	city_selector.add_theme_stylebox_override("pressed",Folio.rail_style(false,true))
	city_selector.get_popup().add_theme_font_size_override("font_size",TOOLBAR_FONT_SIZE)
	# The name takes the room left before the clock and is cut short with an
	# ellipsis there; it never runs under the date.
	city_selector.clip_text=true;city_selector.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;city_selector.alignment=HORIZONTAL_ALIGNMENT_LEFT
	city_selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	city_selector.tooltip_text="Choose a city to view its stores and move the map to it."
	city_selector.item_selected.connect(func(index:int)->void: terrain._select_city(String(city_selector.get_item_metadata(index))))
	var divider:=VSeparator.new();divider.custom_minimum_size=Vector2(1,24);divider.size_flags_vertical=Control.SIZE_SHRINK_CENTER;brand_row.add_child(divider)
	var city_mark:=NavIcon.new("settlement");city_mark.set_icon_color(Folio.RAIL_TEXT);city_mark.custom_minimum_size=Vector2(26,24);city_mark.name="TopCityIcon";city_mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;brand_row.add_child(city_mark)
	brand_row.add_child(city_selector)
	# Each action is a word with a drawn mark (resource_icons.gd), never a glyph.
	for action in [["settle","Found a settlement",true],["scouts","Send scouts",false],["diplomat","Send envoys",false],["convoy","Find the settlers",false]]:
		var button:=Button.new()
		button.name="Toolbar"+String(action[0]).capitalize()
		button.text=String(action[1])
		button.icon=_toolbar_icon(String(action[0]))
		button.add_theme_constant_override("icon_max_width",20)
		button.add_theme_constant_override("h_separation",6)
		button.custom_minimum_size=Vector2(0,32)
		button.add_theme_font_size_override("font_size",TOOLBAR_FONT_SIZE)
		button.add_theme_color_override("font_color",Tokens.GOLD_TEXT if bool(action[2]) else Tokens.BODY)
		button.add_theme_color_override("font_disabled_color",Tokens.DISABLED)
		button.add_theme_stylebox_override("normal",Tokens.action_button_style(bool(action[2])))
		button.add_theme_stylebox_override("hover",Tokens.action_button_style(bool(action[2]),true))
		button.add_theme_stylebox_override("disabled",Tokens.action_button_style(false))
		button.add_theme_stylebox_override("focus",_rail_focus_style())
		button.pressed.connect(_on_toolbar_action.bind(String(action[0])))
		row.add_child(button)
		toolbar_action_buttons[String(action[0])]=button
	var actions_divider:=_toolbar_divider()
	actions_divider.name="ToolbarActionsDivider"
	row.add_child(actions_divider)
	var scale_box:=HBoxContainer.new()
	scale_box.alignment=BoxContainer.ALIGNMENT_CENTER
	scale_box.add_theme_constant_override("separation",6)
	row.add_child(scale_box)
	scale_line=ColorRect.new()
	scale_line.color=Tokens.LAYER_ON_FG
	scale_line.custom_minimum_size=Vector2(56,2)
	scale_line.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	scale_box.add_child(scale_line)
	scale_label=Tokens.make_label("",12,Tokens.MUTED)
	scale_box.add_child(scale_label)
	compass_label=MapCompass.new()
	compass_label.pressed.connect(func()->void: terrain._reset_camera_north())
	compass_label.tooltip_text="Click to reset north-up (N). Rotate with Q/E or Shift + middle-drag; drag vertically to tilt."
	scale_box.add_child(compass_label)
	distance_selector=OptionButton.new();distance_selector.name="MapDistanceLevel"
	distance_selector.fit_to_longest_item=false
	distance_selector.custom_minimum_size=Vector2(104,32)
	distance_selector.add_theme_font_size_override("font_size",TOOLBAR_FONT_SIZE)
	distance_selector.add_theme_color_override("font_color",Tokens.INK)
	distance_selector.get_popup().add_theme_font_size_override("font_size",TOOLBAR_FONT_SIZE)
	# Like the rest of the shell, tolerate a HUD built before its terrain is set.
	for index:int in (terrain.CAMERA_DISTANCE_LEVELS.size() if terrain else 0):distance_selector.add_item(String(EraWords.DISTANCE_WORDS[mini(index,EraWords.DISTANCE_WORDS.size()-1)]))
	distance_selector.tooltip_text="How far the map looks: close by, the valley, the region, the far lands. Scroll or pinch changes one step; Shift-scroll makes gentle fine adjustments."
	# The map speaks in the people's distances; a metric scale bar ("SITE ·
	# 20 M") is a surveyor's instrument, so the bar is kept only for tooltips.
	scale_line.visible=false
	scale_label.visible=false
	distance_selector.item_selected.connect(func(index:int)->void:terrain.set_camera_distance_level(index))
	scale_box.add_child(distance_selector)
	# Past the far lands: the whole world, and how much of it our people know
	# (hud/world_globe.gd). Zooming out past the far lands opens it too.
	world_button=Button.new()
	world_button.name="ToolbarWorld"
	world_button.text="World"
	world_button.icon=_toolbar_icon("world")
	world_button.add_theme_constant_override("icon_max_width",20)
	world_button.add_theme_constant_override("h_separation",6)
	world_button.custom_minimum_size=Vector2(0,32)
	world_button.add_theme_font_size_override("font_size",TOOLBAR_FONT_SIZE)
	world_button.add_theme_color_override("font_color",Tokens.BODY)
	world_button.add_theme_stylebox_override("normal",Tokens.action_button_style(false))
	world_button.add_theme_stylebox_override("hover",Tokens.action_button_style(false,true))
	world_button.add_theme_stylebox_override("focus",_rail_focus_style())
	world_button.tooltip_text="See the whole world, and how much of it our people know."
	world_button.pressed.connect(func()->void:
		if terrain and terrain.has_method("open_world_globe"):terrain.open_world_globe())
	scale_box.add_child(world_button)
	# The supply map (hud/supply_map.gd): where our fighters can be fed.
	scale_box.add_child(preload("res://scripts/hud/supply_map.gd").toggle_button(terrain))
	scale_box.add_child(preload("res://scripts/hud/border_map.gd").toggle_button(terrain))
	# The trade map (hud/trade_map.gd): goods between peoples, embargoes broken red.
	scale_box.add_child(preload("res://scripts/hud/trade_map.gd").toggle_button(terrain))
	# Compile the world view's shader while the map loads, so its first opening
	# does not stall: one invisible pixel drawn with it for a moment.
	if is_inside_tree():
		var warm:=ColorRect.new()
		warm.name="WorldViewWarmUp"
		warm.size=Vector2.ONE
		warm.mouse_filter=Control.MOUSE_FILTER_IGNORE
		warm.modulate.a=0.01
		var warm_material:=ShaderMaterial.new()
		warm_material.shader=preload("res://scripts/hud/world_globe.gdshader")
		warm.material=warm_material
		world_button.add_child(warm)
		get_tree().create_timer(3.0).timeout.connect(warm.queue_free)
		# Draw the world view's chart in the background once the world has
		# settled, so its first opening shows what is known at once.
		get_tree().create_timer(8.0).timeout.connect(func()->void:
			if is_instance_valid(terrain):preload("res://scripts/hud/world_globe.gd").prewarm(terrain))

	toolbar.reset_size()
	_position_toolbar()

var world_button:Button

func _toolbar_icon(id:String)->Texture2D:
	var Icons:=preload("res://scripts/resource_icons.gd")
	match id:
		"settle":return Icons.moment_texture("settlement",_rail_ink(),40)
		"scouts":return Icons.moment_texture("scout",_rail_ink(),40)
		"diplomat":return Icons.moment_texture("contact",_rail_ink(),40)
		"world":return Icons.moment_texture("world",_rail_ink(),40)
	return Icons.people_texture("carry",_rail_ink(),40,false)

## The toolbar speaks in one case: sentence case. Labels that arrive shouted
## (all capitals) from older code or data are lowered, keeping the first word.
static func toolbar_case(value:String)->String:
	return Tokens.sentence_case(value)

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

var _scale_signature:String=""

func update_scale(pixel_width:float,distance_text:String,band:String,north:String)->void:
	if scale_line==null: return
	var signature:="%d|%s|%s|%s" % [roundi(pixel_width),distance_text,band,north]
	if signature==_scale_signature: return
	_scale_signature=signature
	scale_line.custom_minimum_size=Vector2(clampf(pixel_width,48.0,110.0),2)
	scale_label.text="%s · %s" % [band,distance_text]
	(compass_label as MapCompass).set_north(north)
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
		set_active_section(active_section)
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

## The pages sharing a category's screen, for the dock's one row of tabs:
## [{section, provider, labels}] (only those that open in the dock).
func _pages_of(category:Dictionary)->Array:
	var out:Array=[]
	for page:String in category.get("pages",[]):
		if not providers.has(page):continue
		var labels:Array=(category.get("tabs",{}) as Dictionary).get(page,[])
		out.append({"section":page,"provider":providers[page],"labels":labels})
	return out

func open_dock(section:String,sub:int,expanded:bool=true)->void:
	if not providers.has(section): return
	if is_instance_valid(MilitaryCampaign.roster_screen):MilitaryCampaign.roster_screen.queue_free()
	if is_instance_valid(MilitaryCampaign.joint_operations.screen):MilitaryCampaign.joint_operations.screen.queue_free()
	if (expanded or section=="military") and providers[section].has_method("open_expanded_tab") and providers[section].open_expanded_tab(sub):
		close_dock();return
	var was_open:=dock.visible
	detail_history.clear()
	detail_dock.visible=false
	_layout()
	set_active_section(section)
	var category:=category_of(section)
	if not category.is_empty():_last_page[String(category.id)]=section
	dock.siblings=_pages_of(category)
	dock.category_title=String(category.get("label",""))
	# Home says which town: its name stands quietly beside the title.
	dock.title_note=String((providers["settlement"] as Object).meta().get("title","")) if String(category.get("id",""))=="home" and providers.has("settlement") else ""
	dock.open_page=func(page:String,page_sub:int)->void:section_requested.emit(page,page_sub)
	dock.present(providers[section],sub)
	set_active_section(section)
	_layout()
	_dock_signature=(providers[section] as Object).signature().duplicate(true)+[sub]
	dock.visible=true
	if not was_open:
		# Slide in from the rail edge and fade up (Motion.BASE, cubic ease-out).
		var target_x:=Folio.RAIL_WIDTH
		dock.position.x=Folio.RAIL_WIDTH;dock.modulate.a=0.0
		var tween:=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(true)
		var slide:=preload("res://scripts/hud/motion.gd").duration(preload("res://scripts/hud/motion.gd").BASE)
		tween.tween_property(dock,"position:x",target_x,slide);tween.tween_property(dock,"modulate:a",1.0,slide)

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
	_detail_signature=(provider as Object).signature().duplicate(true)+[sub]
	detail_dock.visible=true

func close_detail()->void:
	if not detail_dock or not detail_dock.visible: return
	if not detail_history.is_empty():
		var previous:Dictionary=detail_history.pop_back()
		detail_dock.present(previous.provider,previous.sub)
		detail_dock.body_scroll.set_deferred("scroll_vertical",previous.scroll)
		_detail_signature=previous.provider.signature().duplicate(true)+[previous.sub]
		return
	detail_dock.visible=false
	dock.visible=active_section!="" and dock.provider!=null
	if dock.visible: dock.rebuild_body()

func live_refresh_dock()->void:
	## Called on the terrain's 0.75s live-report tick; rebuilds the dock body
	## only when the active provider's signature changes.
	if dock and dock.visible and dock.provider and not _dock_interaction_active(dock):
		var signature:Array=(dock.provider as Object).signature().duplicate(true)+[dock.sub]
		if signature.hash()!=_dock_signature.hash():
			_dock_signature=signature
			dock.rebuild_body()
	if detail_dock and detail_dock.visible and detail_dock.provider and not _dock_interaction_active(detail_dock):
		var detail_signature:Array=(detail_dock.provider as Object).signature().duplicate(true)+[detail_dock.sub]
		if detail_signature.hash()!=_detail_signature.hash():
			_detail_signature=detail_signature
			detail_dock.rebuild_body()


func request_immediate_dock_refresh()->void:
	## Player actions are different from background simulation refreshes. The
	## background path waits during active clicks or text editing; an action
	## that has already completed must redraw
	## immediately. Defer one frame so the emitting button/row can finish safely.
	call_deferred("_refresh_active_dock_after_action")


func _refresh_active_dock_after_action()->void:
	if detail_dock and detail_dock.visible and detail_dock.provider:
		_detail_signature=detail_dock.provider.signature().duplicate(true)+[detail_dock.sub]
		detail_dock.rebuild_body()
	elif dock and dock.visible and dock.provider:
		_dock_signature=dock.provider.signature().duplicate(true)+[dock.sub]
		dock.rebuild_body()

# --- Refresh ----------------------------------------------------------------

func _unhandled_key_input(event:InputEvent)->void:
	var key:=event as InputEventKey
	if key==null or not key.pressed or key.echo: return
	if key.keycode in [KEY_F5,KEY_F6] and key.shift_pressed:
		# No fleet before boats, no air service before flight.
		if (EraWords.has_boats() if key.keycode==KEY_F5 else EraWords.has_flight()):
			MilitaryCampaign.joint_operations.open_service("navy" if key.keycode==KEY_F5 else "air")
		get_viewport().set_input_as_handled();return
	if key.keycode==KEY_F12:
		open_court()
		get_viewport().set_input_as_handled();return
	# One owner per key. The rail owns F1-F9, F11 and F12; F10 stays with the
	# people-and-legacies screen (historical_figures.gd). Every key here is
	# named in its rail tooltip.
	var keys:=HOTKEYS
	if keys.has(key.keycode):
		toggle_section(String(keys[key.keycode]))
		get_viewport().set_input_as_handled()

const HOTKEYS:={KEY_F1:"overview",KEY_F2:"economy",KEY_F3:"eyes",KEY_F4:"civ",KEY_F5:"inquiry",KEY_F6:"world",KEY_F7:"construction",KEY_F8:"military",KEY_F9:"production",KEY_F11:"chronicle"}

func _dock_interaction_active(panel:Control)->bool:
	## Hovering must not freeze progress. Protect an active click or text edit only.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return true
	for editor_variant in panel.find_children("*","LineEdit",true,false):
		var editor:=editor_variant as LineEdit
		if editor and editor.has_focus(): return true
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
	return temperature_words(today,trend,GameState.known_discoveries)

## Sealed thermometers with fixed points give the first number for the air.
const THERMOMETRY:="precision_thermometry"
## Upper bound (°C) of each felt band; above the last it is scorching.
const TEMPERATURE_FEEL:=[[-8.0,"Bitter cold"],[3.0,"Cold"],[10.0,"Cool"],[18.0,"Mild"],[26.0,"Warm"],[34.0,"Hot"]]

static func temperature_words(celsius:float,trend:String,known:Array)->String:
	## Before a thermometer the air is only felt; after it, it is read in
	## degrees (the climate model already works in them).
	if known.has(THERMOMETRY): return "%d°C %s" % [roundi(celsius),trend]
	var feel:="Scorching"
	for band in TEMPERATURE_FEEL:
		if celsius<float(band[0]):
			feel=String(band[1]); break
	return "%s %s" % [feel,trend]

func refresh()->void:
	if terrain==null: return
	_refresh_city_selector()
	_refresh_time()
	_refresh_kpis()
	_refresh_toolbar()

func _refresh_time()->void:
	# Hot script reload can retain an already-built bar from the previous HUD.
	# Rebuild just this small control, preserving the running campaign.
	if not is_instance_valid(pause_button):
		if is_instance_valid(time_pill):time_pill.queue_free()
		_build_time_pill()
		_time_signature=""
	var absolute_hour:=int(floor(GameState.elapsed_days*24.0))
	var absolute_day:=absolute_hour/24
	var date:=EraWords.when(absolute_day)
	var speed:=int(terrain.game_speed)
	var temperature_text:=_temperature_text()
	var signature:="%s|%d|%s" % [date,speed,temperature_text]
	if signature==_time_signature: return
	_time_signature=signature
	time_text.text="[b][color=#%s]%s[/color][/b][color=#%s] · %s[/color]" % [Folio.RAIL_TEXT.to_html(false),date,Folio.RAIL_TEXT.to_html(false),temperature_text]
	_style_speed_controls(speed)
	time_pill.reset_size()
	_layout()

var distance_selector:OptionButton

func _refresh_kpis()->void:
	var t:Dictionary=preload("res://scripts/hud/civilization_kpi_model.gd").snapshot()
	# A dry year can begin, or take its dead, on a day the towns' numbers stand still.
	var signature:=str(hash(t))+str(WaterWatch.drought_now().hash())
	if signature==_kpi_signature:return
	_kpi_signature=signature
	# Every number in the strip is told in the people's own counting
	# (era_words.gd): souls, winters, who went hungry, before GDP and IMR.
	var modern:=EraWords.reckoned()
	# Before writing the strip stays short: a delta is shown only when it says
	# something (a second hearth, a hungry one).
	# PEOPLE carries who ate today: a separate "bellies filled" chip only
	# repeated the head count whenever everyone ate.
	var population:=int(t.population)
	var fed:=EraWords.fed(population,float(t.food_eaten),float(t.food_need))
	var hungry:=population-fed if fed>=0 else 0
	var place_note:=EraWords.places(t.cities.size()) if modern or t.cities.size()>1 else ""
	var people_note:=EraWords.went_without(hungry,"hungry") if hungry>0 else ((place_note+" · " if place_note!="" else "")+"all fed" if fed>=0 else place_note)
	# Births against burials over the last whole year, the people's own count,
	# amber when more are buried than born (the card says why). The note has
	# room for about 19 letters (test_era_words: every value fits at 1280), so
	# where they live and that all are fed go on the card's first lines; a
	# hungry day still takes the note. In the first year: the old note.
	var born:=int(t.get("born",0));var buried:=int(t.get("buried",0))
	var counted:=hungry<=0 and bool(t.get("full_year",false)) and born+buried>0
	if counted:people_note="born %d · buried %d" % [born,buried]
	# Under PEOPLE the count needs no unit; before writing it is told in souls.
	_update_kpi("population",EraWords.people(population) if EraWords.hearth() else EraWords.grouped(population),people_note,Tokens.RED if hungry>0 else (Tokens.AMBER if counted and buried>born else Tokens.MUTED),"")
	for id:String in ["food","water"]:
		var shortage:=int(t[id+"_shortages"])
		var pending:bool=int(t[id+"_reports"])<t.cities.size()
		var days:=float(t[id+"_days"])
		var note:String
		if id=="water" and days>=0.0:
			# WATER reads every town's own ledger and the dry year
			# (water_watch.gd): red with the worst town and its days when
			# anyone went thirsty, amber when a store is nearly gone or a dry
			# year is killing, else the people's days held.
			var watch:Dictionary=WaterWatch.live(t)
			var tone:=String(watch.tone)
			if tone=="calm":
				note=("civ total" if modern else "of drinking water") if not pending else "partial"
				_update_kpi(id,EraWords.days(days),note,Tokens.GREEN,"")
			else:
				_update_kpi(id,EraWords.days(float(watch.days)),_fitting_note(id,watch.notes),Tokens.RED if tone=="short" else Tokens.AMBER,"")
			continue
		if shortage>0:note="%d short" % shortage if modern else ("running short" if t.cities.size()<=1 else "%s short" % EraWords.places(shortage))
		elif pending:note="partial"
		else:note="civ total" if modern else ("of food" if id=="food" else "of drinking water")
		# Food by the one rule for the stores (food_care.gd): bare red, low
		# amber, holding green, so a short number that is safe does not read as a crisis.
		var level:=String(preload("res://scripts/food_care.gd").store_level(days)) if id=="food" else ""
		_update_kpi(id,EraWords.days(days),note,Tokens.RED if shortage>0 or level=="bare" else (Tokens.AMBER if level=="low" else (Tokens.GREEN if level=="holding" else Tokens.MUTED)),"")
	var goods_short:=int(t.goods_shortages)
	_update_kpi("goods",EraWords.goods(float(t.goods_coverage)),("%d short" % goods_short if modern else "%d in want" % goods_short) if goods_short>0 else EraWords.goods_trend(float(t.goods_net)),Tokens.RED if goods_short>0 else Tokens.MUTED,"Civilian Goods held against what households expect")
	_update_kpi("health",EraWords.life(float(t.life)),EraWords.babes_lost_short(float(t.infant)),Tokens.MUTED,"Population-weighted health across all cities")
	if modern:
		_update_kpi("science","%.1f" % t.science,"%.0f%% schooled" % (float(t.education)*100),Tokens.GOLD,"Combined research capacity; population-weighted education")
		_update_kpi("gdp","%.1f" % t.output,"%.2f per person" % (float(t.output)/maxi(1,int(t.population))),Tokens.BLUE,"Total city output and per-city contributions")
	else:
		var keepers:=roundi(float(t.minds))
		# After writing: the scholars, the Research page's own count.
		_update_kpi("science","%d known" % GameState.known_discoveries.size() if EraWords.hearth() else EraWords.grouped(keepers),("%d keeper" if keepers==1 else "%d keepers") % keepers if EraWords.hearth() else "%d known" % GameState.known_discoveries.size(),Tokens.GOLD,"")
		# Before writing the gdp chip is hidden (who ate is in PEOPLE).
		if not EraWords.hearth():
			# AT WORK is a head count: everyone who can work less those serving
			# (war_forces_model.gd at_work, the War screen's own figures).
			var Forces:=preload("res://scripts/hud/war_forces_model.gd")
			_update_kpi("gdp",EraWords.grouped(Forces.at_work(MilitaryCampaign)),"of %s people" % EraWords.grouped(int(t.population)),Tokens.BLUE,"")
	kpi_strip.reset_size()
	_layout()

func _refresh_toolbar()->void:
	if distance_selector: distance_selector.select(terrain.camera_distance_level())
	var settle:Button=toolbar_action_buttons.get("settle")
	var scouts:Button=toolbar_action_buttons.get("scouts")
	var diplomat:Button=toolbar_action_buttons.get("diplomat")
	var convoy:Button=toolbar_action_buttons.get("convoy")
	var convoy_active:=bool(GameState.settlement_convoy.get("active",false))
	var scouting:Dictionary=CivilizationSystem.scouting_staff.toolbar_counts()
	# The toolbar reports standing orders. Route planning belongs to departures,
	# never to a HUD refresh.
	var scout_presentation:Dictionary={"label":EraWords.scouts_out(int(scouting.away)),"disabled":false,"tooltip":"Choose how many of the people walk out as scouts, and where they look."}
	var diplomatic_status:Dictionary=CivilizationSystem.diplomatic_mission_status()
	var known_destinations:=CivilizationSystem.known_home_destination_count()
	var diplomat_presentation:Dictionary=terrain._diplomat_action_presentation(diplomatic_status,known_destinations)
	var returned_reply:=""
	if not bool(diplomatic_status.get("active",false)):
		for thread:Dictionary in WorldSimulation.dialogue.threads.values():
			if bool(thread.get("returned_home",false)) and bool(thread.get("in_transit",false)):
				returned_reply="Envoys home · send again" if bool(thread.get("retryable",false)) else "Envoys home · awaiting word"
				break
	var settle_text:String
	var settle_tooltip:String
	var settle_disabled:=false
	if not GameState.settlement_site_committed:
		settle_text="Review founding site"
		settle_tooltip="Check drinking water and nearby suitable ground on the map before committing to a settlement."
	elif terrain.settlement_convoy_targeting:
		settle_text="Cancel site selection"
		settle_tooltip="Leave destination-selection mode without paying any cost."
	elif convoy_active:
		settle_text="Find the settlers"
		settle_tooltip="Move the camera to the active settlement convoy."
	elif "Hearth Circle" not in GameState.settlement_completed:
		settle_text="Founding committed"
		settle_tooltip="The first settlement is already committed here. Complete the Hearth Circle before organizing another founding convoy."
		settle_disabled=true
	else:
		# One seat for every people (one_seat.gd): it grows outward and sends
		# no settlers away, so there is nothing to found.
		settle_text="Found a new settlement"
		settle_tooltip="Enter temporary destination-selection mode. Route and cost are reviewed before anything is committed."
		settle_disabled=preload("res://scripts/one_seat.gd").has_seat()
	# An action that can neither be taken nor report anything does not earn a
	# toolbar slot; it appears when it becomes possible. Away-mission states
	# stay visible because their countdown IS the information.
	var settle_visible:=not settle_disabled
	var scouts_visible:=GameState.settlement_site_committed or int(scouting.away)>0
	var diplomat_visible:=not bool(diplomat_presentation.disabled) or bool(diplomatic_status.get("active",false))
	var signature:="%s|%s|%s|%s|%s|%s|%s" % [settle_text,String(scout_presentation.label),String(diplomat_presentation.label)+returned_reply,convoy_active,settle_visible,scouts_visible,diplomat_visible]
	if signature==_toolbar_signature: return
	_toolbar_signature=signature
	settle.text=settle_text
	settle.tooltip_text=settle_tooltip
	settle.disabled=settle_disabled
	settle.visible=settle_visible
	# Keep the allocation visible even between departures.
	scouts.text=toolbar_case(String(scout_presentation.label))
	scouts.disabled=bool(scout_presentation.disabled)
	scouts.tooltip_text=String(scout_presentation.tooltip)
	scouts.visible=scouts_visible
	var envoys_out:=bool(diplomatic_status.get("active",false))
	diplomat.text="Send envoys" if not envoys_out else "Envoys away · %s" % EraWords.days(float(diplomatic_status.get("days_remaining",0)))
	diplomat.disabled=bool(diplomat_presentation.disabled)
	# Plain words here, not the removed menu's "result / why / next" text.
	diplomat.tooltip_text=("Our envoys are on the road. You will hear what they bring back in the court." if envoys_out
		else "We know no other people to send envoys to yet. Scouts must find a foreign settlement first." if diplomat.disabled
		else "Open the court and choose which people to send word to.")
	if returned_reply!="":
		diplomat.text=returned_reply
		diplomat.tooltip_text="The envoys are back. Open the court to hear them, or send them again."
	diplomat.visible=diplomat_visible
	# "Find the settlers" already sits on the first button while they travel.
	convoy.visible=convoy_active and settle_text!="Find the settlers"
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
	# One town: nothing to choose, so no name on the bar (Home carries it).
	city_selector.visible=settlements.size()>1
	for city in settlements:
		city_selector.add_item(toolbar_case(String(city.get("name","Settlement"))))
		var index:=city_selector.item_count-1
		city_selector.set_item_metadata(index,String(city.id))
		if String(city.id)==GameState.selected_player_settlement_id: city_selector.select(index)

func show_action_feedback(message:String,category:String="war")->void:
	if message.is_empty():return
	# Notifications (codex/notifications): told in the one stack at the top
	# right (hud/notification_stack.gd), no longer a slip at the lower right.
	preload("res://scripts/hud/notification_model.gd").push({"category":category,"tier":"notable","text":message})

func _approved_rail_style(active:bool,hover:bool=false)->StyleBoxFlat:
	return Folio.rail_style(active,hover)

func _rail_focus_style()->StyleBoxFlat:
	return Tokens.flat(Color.TRANSPARENT,Tokens.GOLD,2,Tokens.RADIUS_CONTROL)

## Rail glyph ink: dark brown ink on light paper, warm gold on night paper.
func _rail_ink()->Color:return Folio.GOLD
