extends "res://scripts/hud/home_ledger.gd"
## The Materials dock, at a glance: a compact header (who decides the work,
## how full the stores are as a gauge, what slows supply), then every material
## in hand as a small tile in a grid (its picture, its count, a spark of the
## monthly counts and which way it is going in a few words), and the ones not
## yet within reach (nothing in store, nothing coming) as a strip of chips.
## Clicking a tile or chip opens its sources beneath the grid. The long
## account of each trend lives in its tile's tooltip.
##
## The live refresh (update_block) keeps every node while the page's shape
## holds (the same materials, the same opened one, the same leader and
## choices) and writes the day's words and sparks into them; _fill is the one
## place those words are made, for the first drawing and every refresh.
const Materials:=preload("res://scripts/hud/materials_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
## A tile is at least this wide; the grid fits as many a row as it can.
const TILE_WIDTH:=232.0
const TILE_GAP:=8

var _shape:Array=[]
var _city:Label
var _manage:Label
var _supply:Label
var _slows:Label
var _gauge:ProgressBar
var _gauge_words:Label
## The searched land: how well, what it gives cutting and digging, the find odds.
var _land:Label
var _grid:GridContainer
## Per material tile: {key, panel, value, trend, spark}.
var _rows:Array=[]
## The opened material's source lines.
var _details:Array=[]
## Per shipment on the road: {voice, when}.
var _incoming:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",10)
	_shape=shape_of(block)
	_header()
	var held:Array=[];var beyond:Array=[]
	for item:Dictionary in data.rows:(beyond if out_of_reach(item) else held).append(item)
	_grid=GridContainer.new();_grid.name="Materials";_grid.add_theme_constant_override("h_separation",TILE_GAP);_grid.add_theme_constant_override("v_separation",TILE_GAP);add_child(_grid)
	for item:Dictionary in held:_tile(_grid,item)
	if data.rows.is_empty():_line(self,"Nothing is stored or known yet. Surveys find sources of wood, stone and clay.",13,T.MUTED)
	if not beyond.is_empty():_beyond(beyond)
	_opened()
	for shipment:Dictionary in data.incoming:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);add_child(row);row.add_child(Materials.picture(5,56,32))
		# The words take the row's width; without it a wrapping line folds to one letter.
		var summary:=VBoxContainer.new();summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.size_flags_vertical=Control.SIZE_SHRINK_CENTER;summary.add_theme_constant_override("separation",0);row.add_child(summary)
		var refs:={"voice":_voice("",15)}
		summary.add_child(refs.voice)
		refs.when=_line(summary,"",12,T.MUTED)
		_incoming.append(refs)
	if bool(data.can_direct):
		var who:=_who(data)
		var name_word:=who if not who.is_empty() else "the leader"
		var focus:=String(data.get("focus",""))
		_choices(self,"Ask %s for more hands on" % name_word,[
			{"id":"logistics","label":"Carrying and paths","tip":"More people carry loads and keep the paths open. Other work slows.","on_press":func():data.on_focus.call("logistics")},
			{"id":"","label":"Let %s decide" % name_word,"tip":"The leader spreads the work across what the place needs.","on_press":func():data.on_focus.call("")},
		],"" if bool(data.managed) else (focus if focus=="logistics" else "other"))
	var links:=HFlowContainer.new();links.name="Links";links.add_theme_constant_override("h_separation",8);add_child(links)
	_button(links,"Show sources on the map",data.on_map,"Mark known wood, stone and clay on the map")
	_button(links,"Deliveries between places",data.on_trade,"Goods on the road between your settlements")
	resized.connect(_arrange);_arrange()
	_fill()

## Nothing in store and nothing coming in: not yet within reach.
static func out_of_reach(item:Dictionary)->bool:
	return float(item.get("stock",0.0))<0.5 and float(item.get("delivered",0.0))<=0.05

# --------------------------------------------------------------------------
# The header
# --------------------------------------------------------------------------

func _header()->void:
	var head:=HBoxContainer.new();head.name="Header";head.add_theme_constant_override("separation",12);add_child(head)
	var leader:Dictionary=data.leader
	if not leader.is_empty():
		var face:=Portrait.picture(leader,48,60);face.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(face)
	var manager:=VBoxContainer.new();manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;manager.size_flags_vertical=Control.SIZE_SHRINK_CENTER;manager.add_theme_constant_override("separation",1);head.add_child(manager)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);manager.add_child(top)
	_manage=_voice("",16);_manage.autowrap_mode=TextServer.AUTOWRAP_OFF;top.add_child(_manage)
	_city=T.make_label("",12,T.MUTED);_city.size_flags_vertical=Control.SIZE_SHRINK_CENTER;top.add_child(_city)
	_supply=_line(manager,"",12,T.BODY);_supply.name="SupplySentence"
	if not String(Words.supply(float(data.storage),float(data.capacity),data.hauling).slows).is_empty():_slows=_line(manager,"",12,tone_color("warn"));_slows.name="SupplySlows"
	if not String(data.get("land","")).is_empty():_land=_line(manager,"",12,T.MUTED);_land.name="SearchedLand"
	# The stores as a gauge: what is held against the room for it.
	var store:=VBoxContainer.new();store.name="Stores";store.custom_minimum_size.x=170;store.size_flags_vertical=Control.SIZE_SHRINK_CENTER;store.add_theme_constant_override("separation",3);head.add_child(store)
	store.add_child(T.make_label("STORES",12,T.GOLD_TEXT,0.06))
	_gauge=ProgressBar.new();_gauge.show_percentage=false;_gauge.custom_minimum_size=Vector2(170,10);_gauge.max_value=1.0;_gauge.step=0.0
	_gauge.add_theme_stylebox_override("background",T.flat(T.TRACK,Color.TRANSPARENT,0,5));store.add_child(_gauge)
	_gauge_words=T.make_label("",12,T.TEXT_SOFT);store.add_child(_gauge_words)
	_rule(self)

# --------------------------------------------------------------------------
# Tiles and chips
# --------------------------------------------------------------------------

## One material: its picture, its name, the count in the voice face beside a
## spark of the monthly counts, and which way it is going in a few words.
func _tile(parent:Node,item:Dictionary)->void:
	var key:=String(item.key)
	var open:bool=data.selected==key
	var panel:=PanelContainer.new();panel.name="Material_"+key.validate_node_name();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
	var rest:=T.flat(T.ACTIVE_BG if open else T.ROW_BG,T.GOLD if open else T.BORDER_SOFT,1,T.RADIUS_CARD,8)
	var lit:=T.flat(T.HOVER_BG,T.GOLD,1,T.RADIUS_CARD,8)
	panel.add_theme_stylebox_override("panel",rest)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);panel.add_child(row)
	row.add_child(_picture(key,48,40))
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",0);row.add_child(text)
	var name_label:=T.make_label(String(item.name),12,T.TEXT_SOFT);_clip(name_label);text.add_child(name_label)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);text.add_child(line)
	var value:=_voice("",22);value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(value)
	var spark:=Spark.new();spark.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(spark)
	spark.ready.connect(func()->void:spark.custom_minimum_size=Vector2(60,26))
	var trend:=T.make_label("",12,T.MUTED);trend.name="Trend";_clip(trend);text.add_child(trend)
	for child:Node in panel.find_children("*","Control",true,false):(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",rest))
	panel.gui_input.connect(func(event:InputEvent)->void:
		var mouse:=event as InputEventMouseButton
		if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:panel.accept_event();data.on_select.call(key))
	_rows.append({"key":key,"panel":panel,"value":value,"trend":trend,"spark":spark})

## The materials not yet within reach, one small chip each; why on hover.
func _beyond(items:Array)->void:
	var strip:=HFlowContainer.new();strip.name="NotYetInReach";strip.add_theme_constant_override("h_separation",6);strip.add_theme_constant_override("v_separation",6);add_child(strip)
	var lead:=T.make_label("Not yet within reach",12,T.MUTED);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;strip.add_child(lead)
	for item:Dictionary in items:
		var key:=String(item.key)
		var open:bool=data.selected==key
		var chip:=Button.new();chip.name="Beyond_"+key.validate_node_name();chip.text=String(item.name);chip.icon=Icons.material_texture(key,24);chip.expand_icon=false
		chip.focus_mode=Control.FOCUS_NONE;chip.custom_minimum_size.y=26;chip.add_theme_font_size_override("font_size",12)
		chip.add_theme_color_override("font_color",T.TEXT_SOFT);chip.add_theme_color_override("font_hover_color",T.INK);chip.add_theme_constant_override("icon_max_width",16)
		chip.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if open else Color.TRANSPARENT,T.GOLD if open else T.BORDER_SOFT,1,13,6))
		chip.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,13,6));chip.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG,T.GOLD,1,13,6))
		chip.tooltip_text=_reading_words(item)+"\nClick for where it could come from."
		chip.pressed.connect(func()->void:data.on_select.call(key))
		strip.add_child(chip)

## The opened material's sources, beneath the grid.
func _opened()->void:
	var item:Dictionary={}
	for row:Dictionary in data.rows:
		if String(row.key)==String(data.selected):item=row
	if item.is_empty():return
	var panel:=PanelContainer.new();panel.name="Sources";add_child(panel)
	var style:=T.flat(T.PANEL_BG_SOLID,T.GOLD,1,T.RADIUS_CARD,10);panel.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",3);panel.add_child(box)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);box.add_child(head)
	head.add_child(_picture(String(item.key),32,26))
	var title:=_voice("%s: where it comes from" % String(item.name),16);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	_button(head,"Show on the map",data.on_map,"Mark known sources on the map")
	_button(head,"Close",func():data.on_select.call(String(item.key)),"Hide its sources")
	for detail:String in item.details:_details.append(_line(box,"",12,T.MUTED))
	if (item.details as Array).is_empty():_line(box,"No known place to dig or cut it yet. Scouts and surveys find new sources.",12,T.MUTED)

## A material's painting from the atlas, or its drawn glyph when it has none.
func _picture(key:String,width:float,height:float)->TextureRect:
	var index:=Materials.material(key)
	var rect:=Materials.picture(index,width,height)
	if index<0:rect.texture=Icons.material_texture(key,64)
	rect.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return rect

func _arrange()->void:
	if _grid==null:return
	var count:=maxi(1,_grid.get_child_count())
	_grid.columns=clampi(floori((size.x+TILE_GAP)/(TILE_WIDTH+TILE_GAP)),1,count)

static func _clip(label:Label)->void:
	label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.custom_minimum_size.x=1

# --------------------------------------------------------------------------
# The live refresh
# --------------------------------------------------------------------------

## The live refresh: the same nodes take the day's words while the page keeps
## its shape; a different shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: its leader, the materials in order with whether
## each is within reach, the opened one and its lines, whether supply is
## slowed, the shipments and the choices offered.
static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):
		var open:bool=block.get("selected","")==item.key
		rows.append([String(item.key),out_of_reach(item),open,(item.get("details",[]) as Array).size() if open else -1])
	var supply:=Words.supply(float(block.get("storage",0.0)),float(block.get("capacity",0.0)),block.get("hauling"))
	var leader:Dictionary=block.get("leader",{})
	return [Portrait.picture_key(leader) if not leader.is_empty() else [],_who(block),bool(block.get("managed",true)),String(block.get("focus","")),String(supply.slows).is_empty(),String(block.get("land","")).is_empty(),rows,(block.get("incoming",[]) as Array).size(),bool(block.get("can_direct",false))]

static func _who(block:Dictionary)->String:
	var leader:Dictionary=block.get("leader",{})
	return String(leader.get("name","")).get_slice(" ",0) if not leader.is_empty() else ""

## A material's reading: which way it goes, since when, and why.
static func reading_of(item:Dictionary)->Dictionary:
	var blocked:=""
	for detail:String in item.get("details",[]):
		if bool(item.get("blocked",false)):blocked=detail.get_slice(": ",1);break
	return Words.material(float(item.stock),float(item.delivered),float(item.loss),item.points,blocked)

static func _reading_words(item:Dictionary)->String:
	var reading:=reading_of(item)
	var since:=(" "+String(reading.since)) if not String(reading.since).is_empty() else ""
	return "%s%s: %s." % [trend_word(String(reading.trend)),since,String(reading.cause)]

## The tile's short line: which way, and the day's flow in and out.
static func _short_words(item:Dictionary)->String:
	var reading:=reading_of(item)
	var delivered:=float(item.delivered);var loss:=float(item.loss)
	var flow:=""
	if delivered>0.05:flow="+%s" % Plain.number(delivered)+(" −%s" % Plain.number(loss) if loss>0.05 else "")+" a day"
	elif loss>0.05:flow="−%s a day" % Plain.number(loss)
	else:flow="nothing coming in"
	return "%s · %s" % [trend_word(String(reading.trend)),flow]

## Every word and figure on the page that follows the day.
func _fill()->void:
	var who:=_who(data)
	_put(_city,String(data.city))
	_put(_manage,("%s decides who digs, cuts and carries" % who if not who.is_empty() else "The local leader decides who digs, cuts and carries") if bool(data.managed) else "You asked for extra hands on part of the work")
	var supply:=Words.supply(float(data.storage),float(data.capacity),data.hauling)
	_put(_supply,String(supply.sentence))
	if _slows!=null:_put(_slows,String(supply.slows))
	var full:=float(supply.full)
	_gauge.value=clampf(full,0.0,1.0)
	_gauge.add_theme_stylebox_override("fill",T.flat(T.RED if full>=0.97 else (T.AMBER if full>=0.85 else T.GREEN),Color.TRANSPARENT,0,5))
	_put(_gauge_words,"No storage built" if float(data.capacity)<=0.0 else "%s held · room for %s" % [Plain.number(float(data.storage)),Plain.number(float(data.capacity))])
	_gauge.tooltip_text=String(supply.sentence)
	if _land!=null:
		# The first sentence on the page (how much land is searched); the yield
		# factors and the find odds sit in its tooltip.
		var land:=String(data.get("land",""))
		var cut:=land.find(". ")
		_put(_land,land.left(cut+1) if cut>0 else land)
		_land.mouse_filter=Control.MOUSE_FILTER_PASS
		_land.tooltip_text=land
	var by_key:={}
	for item:Dictionary in data.rows:by_key[String(item.key)]=item
	for refs:Dictionary in _rows:
		var item:Dictionary=by_key.get(String(refs.key),{})
		if item.is_empty():continue
		var reading:=reading_of(item)
		_put(refs.value,Plain.number(float(item.stock)))
		_put(refs.trend,_short_words(item),tone_color(String(reading.tone)))
		(refs.panel as Control).tooltip_text="%s: %s in store.\n%s\nClick for where it comes from." % [String(item.name),Plain.number(float(item.stock)),_reading_words(item)]
		var spark:Control=refs.spark
		if spark.get("points")!=item.points:spark.set("points",item.points);spark.queue_redraw()
	var opened:Dictionary=by_key.get(String(data.selected),{})
	if not opened.is_empty():
		for d in mini(_details.size(),(opened.details as Array).size()):
			_put(_details[d],String(opened.details[d]),tone_color("bad") if bool(opened.get("blocked",false)) else T.MUTED)
	for index in mini(_incoming.size(),(data.incoming as Array).size()):
		var shipment:Dictionary=data.incoming[index]
		var refs:Dictionary=_incoming[index]
		_put(refs.voice,"%s %s on the way" % [Plain.number(float(shipment.quantity)),String(shipment.resource).to_lower()])
		var days_left:=maxi(0,ceili(float(shipment.arrival_day)-float(data.day)))
		_put(refs.when,"From %s; arrives %s." % [String(shipment.source_name),"today" if days_left<=0 else "in "+Plain.span_text(days_left)])
