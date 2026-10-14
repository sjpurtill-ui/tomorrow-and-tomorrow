extends VBoxContainer
## Material supply and carrying decisions lead, followed by the land's
## condition, daily flows and individual reserves. A reserve's sources open
## directly beneath it; unavailable materials retain their own source entry.
## Food, water and household goods have their own pages.
##
## The live refresh (update_block) keeps every node while the page's shape
## holds and writes the day's numbers into them.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
## Kept out of the yards' table: each has its own tab.
const ELSEWHERE:=["Freshwater","Civilian Goods","Food"]

var data:Dictionary
var _shape:Array=[]
var _land:Label
var _land_bar:Control
var _land_note:Label
## Per moving material: {key, refs}.
var _rows:Array=[]
var _held_rows:Array=[]
var _grid:GridContainer
var _hero:Label
var _supply:Label
var _readings:Dictionary={}
## Per shipment on the road: {voice, when} (the row's label and note).
var _incoming:Array=[]
var _details:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",24)
	_shape=shape_of(block)
	var who:=_who(block)
	var focus:=_current(block)
	var can_direct:=bool(block.get("can_direct",false))
	var overview:=VBoxContainer.new();overview.add_theme_constant_override("separation",8);add_child(overview)
	_hero=S.voice("",32);_hero.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview.add_child(_hero)
	_supply=S.label("",16,T.INK_MUTED);_supply.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview.add_child(_supply)
	var row_buttons:=HFlowContainer.new();row_buttons.add_theme_constant_override("h_separation",8);row_buttons.add_theme_constant_override("v_separation",8);overview.add_child(row_buttons)
	if can_direct:
		var more:=S.verb("More carriers"+(" (now)" if focus=="logistics" else ""),func():data.on_focus.call("logistics"),"Ask %s to put more people on carrying loads and keeping the paths open. Other work slows." % (who if not who.is_empty() else "the leader"),focus=="logistics")
		more.name="Choice_Logistics";row_buttons.add_child(more)
		if focus!="":row_buttons.add_child(S.verb("Let %s decide" % (who if not who.is_empty() else "the leader"),func():data.on_focus.call(""),"The leader spreads the work across what the place needs."))
	row_buttons.add_child(S.verb("Show on map",data.get("on_map"),"Mark known wood, stone and clay on the map"))
	var readings:=HFlowContainer.new();readings.add_theme_constant_override("h_separation",32);readings.add_theme_constant_override("v_separation",16);add_child(readings)
	for item:Dictionary in kpi_items(block):
		var cell:=VBoxContainer.new();cell.custom_minimum_size.x=136;cell.add_theme_constant_override("separation",4);readings.add_child(cell)
		cell.add_child(S.label(String(KPI_LABELS[item.id]),14,T.INK_MUTED))
		var value:=S.voice("",24);cell.add_child(value)
		var note:=S.label("",14,T.INK_MUTED);cell.add_child(note)
		_readings[item.id]={"cell":cell,"value":value,"note":note}
	# Land condition stays plain; exact yield factors and odds remain in its tooltip.
	if String(block.get("land",""))!="":
		var searched:=VBoxContainer.new();searched.name="Land";searched.add_theme_constant_override("separation",6);add_child(searched)
		var reading:=HBoxContainer.new();reading.add_theme_constant_override("separation",16);searched.add_child(reading)
		_land=S.label("",16,T.INK,true);_land.name="SearchedLand";_land.mouse_filter=Control.MOUSE_FILTER_PASS;reading.add_child(_land)
		_land_bar=S.bar(0.0,T.INK_MUTED,96.0,5.0);_land_bar.name="SearchedBar";reading.add_child(_land_bar)
		_land_note=S.label("",14,T.INK_MUTED);_land_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;searched.add_child(_land_note)
	var moving:Array=[];var still:Array=[];var beyond:Array=[]
	for item:Dictionary in block.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		(beyond if out_of_reach(item) else (still if is_idle(item,"") else moving)).append(item)
	if not moving.is_empty():S.head(self,"Moving through the yards")
	_grid=S.columns(self,"Materials",400.0,2)
	_grid.visible=not moving.is_empty()
	for item:Dictionary in moving:
		var key:=String(item.key)
		var refs:=S.row(_grid,{"id":key,"icon":key,"label":String(item.name),"points":item.get("points",[]),"bar_width":64.0,"value_width":70.0,
			"buttons":[{"text":"Close" if String(block.get("selected",""))==key else "Sources","on_press":func():data.on_select.call(key),"tip":"Where it comes from","chosen":String(block.get("selected",""))==key}]})
		(refs.panel as Control).name="Material_"+key.validate_node_name()
		_rows.append({"key":key,"refs":refs})
	if moving.any(func(item:Dictionary)->bool:return String(item.key)==String(data.get("selected",""))):_opened()
	if not still.is_empty():
		var held:=VBoxContainer.new();held.name="Still";held.add_theme_constant_override("separation",0);add_child(held)
		S.head(held,"Held in reserve","No movement today")
		for item:Dictionary in still:
			var key:=String(item.key)
			var selected:=String(data.get("selected",""))==key
			var refs:=S.row(held,{"id":key,"icon":key,"label":String(item.name),"compact_actions":true,"buttons":[{"text":"Hide sources" if selected else "Sources","on_press":func():data.on_select.call(key),"tip":"Where it comes from","chosen":selected}]})
			_held_rows.append({"key":key,"refs":refs})
			if selected:_opened(held,false)
	if not beyond.is_empty():
		var strip:=HFlowContainer.new();strip.name="NotYetInReach";strip.add_theme_constant_override("h_separation",6);strip.add_theme_constant_override("v_separation",4);add_child(strip)
		var lead:=S.label("Not yet within reach",16,T.INK_MUTED,true);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;strip.add_child(lead)
		for item:Dictionary in beyond:
			var key:=String(item.key)
			var chip:=Button.new();chip.name="Beyond_"+key.validate_node_name();chip.text=String(item.name);chip.icon=Icons.material_texture(key,24);chip.expand_icon=false
			T.apply_button_style(chip);chip.add_theme_constant_override("icon_max_width",20)
			chip.tooltip_text=_reading_words(item)+"\nClick for where it could come from."
			chip.pressed.connect(func()->void:data.on_select.call(key))
			strip.add_child(chip)
		if beyond.any(func(item:Dictionary)->bool:return String(item.key)==String(data.get("selected",""))):_opened()
	var incoming:Array=block.get("incoming",[])
	if not incoming.is_empty():
		S.head(self,"On the road")
		var road:=S.columns(self,"Incoming",400.0,2)
		for shipment:Dictionary in incoming:
			var refs:=S.row(road,{"id":"incoming","icon":String(shipment.get("resource","")),"label":"","value_width":60.0})
			_incoming.append({"voice":refs.label,"when":refs.note,"refs":refs})
		road.add_child(S.verb("All deliveries",data.get("on_trade"),"Goods on the road between your settlements, and what arrived"))
	resized.connect(_arrange)
	_fill()
	_arrange.call_deferred()

## The opened material's sources, beneath the table: one line each.
func _opened(parent:Node=null,close_button:=true)->void:
	var item:Dictionary={}
	for row:Dictionary in data.get("rows",[]):
		if String(row.key)==String(data.get("selected","")):item=row
	if item.is_empty():return
	var box:=VBoxContainer.new();box.name="Sources";box.add_theme_constant_override("separation",12);(parent if parent!=null else self).add_child(box)
	var head:=S.head(box,"%s: where it comes from" % String(item.name))
	if close_button:(head.row as HBoxContainer).add_child(S.verb("Close",func():data.on_select.call(String(item.key)),"Hide its sources"))
	for detail:String in item.get("details",[]):
		var line:=S.label("",16,T.INK_MUTED);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(line);_details.append(line)
	if (item.get("details",[]) as Array).is_empty():
		var empty_sources:=S.label("No known place to dig or cut it yet. Scouts and surveys find new sources.",16,T.INK_MUTED);empty_sources.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(empty_sources)

func _arrange()->void:
	S.flow(_grid,size.x)
	S.compact(self,size.x)
	var road:=get_node_or_null("Incoming") as GridContainer
	if road!=null:S.flow(road,size.x)

## In store with nothing coming in or going out today, and not the one opened.
static func is_idle(item:Dictionary,selected:String)->bool:
	return not out_of_reach(item) and float(item.get("delivered",0.0))<=0.05 and float(item.get("loss",0.0))<=0.05 and String(item.get("key",""))!=selected

## Nothing in store and nothing coming in: not yet within reach.
static func out_of_reach(item:Dictionary)->bool:
	return float(item.get("stock",0.0))<0.5 and float(item.get("delivered",0.0))<=0.05

## Nothing in store although some still comes in: used as fast as it arrives.
static func empty(item:Dictionary)->bool:
	return float(item.get("stock",0.0))<0.5

func update_block(block:Dictionary)->bool:
	if shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: the materials in each part, the opened one and
## its lines, the shipments and the choices offered.
static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):
		var open:bool=block.get("selected","")==item.key
		rows.append([String(item.key),out_of_reach(item),is_idle(item,String(block.get("selected",""))),open,(item.get("details",[]) as Array).size() if open else -1])
	return [_who(block),_current(block),rows,(block.get("incoming",[]) as Array).size(),bool(block.get("can_direct",false))]

static func _current(block:Dictionary)->String:
	var focus:=String(block.get("focus",""))
	return "" if bool(block.get("managed",true)) else (focus if focus=="logistics" else "other")

static func _who(block:Dictionary)->String:
	var leader:Dictionary=block.get("leader",{})
	return String(leader.get("name","")).get_slice(" ",0) if not leader.is_empty() else ""

## A material's reading: which way it goes, since when, and why.
static func reading_of(item:Dictionary)->Dictionary:
	var blocked:=""
	for detail:String in item.get("details",[]):
		if bool(item.get("blocked",false)):blocked=detail.get_slice(": ",1);break
	return Words.material(float(item.stock),float(item.delivered),float(item.loss),item.get("points",[]),blocked)

static func _reading_words(item:Dictionary)->String:
	var reading:=reading_of(item)
	var since:=(" "+String(reading.since)) if not String(reading.since).is_empty() else ""
	return "%s%s: %s." % [trend_word(String(reading.trend)),since,String(reading.cause)]

static func trend_word(trend:String)->String:
	match trend:
		"rising":return "Rising"
		"falling":return "Falling"
	return "Steady"

## The day's flow in and out: "+178 in · −15 lost".
static func flow_words(item:Dictionary)->String:
	var delivered:=float(item.get("delivered",0.0));var loss:=float(item.get("loss",0.0))
	var parts:PackedStringArray=[]
	if delivered>0.05:parts.append("+%s in" % S.n(delivered))
	if loss>0.05:parts.append("−%s lost" % S.n(loss))
	return " · ".join(parts)+" a day" if not parts.is_empty() else "nothing comes in"

## The strip's figures (the dock draws them under the tabs): the yards held
## against their room, what comes in a day, the carrying.
const KPI_LABELS:={"stores":"In the yards","income":"Coming in a day","carry":"Carrying"}
static func kpis(data:Dictionary)->Array:
	return S.dock_kpis(kpi_items(data),KPI_LABELS)

static func kpi_items(data:Dictionary)->Array:
	var out:Array=[]
	var who:=_who(data)
	# The yards: held against their room, one bar, held ÷ room.
	var held:=float(data.get("storage",0.0));var room:=float(data.get("capacity",0.0))
	var full:=held/room if room>0.0 else -1.0
	var counted:=String(data.get("counted",""))
	out.append(S.kpi_item("stores",{"value":S.n(held),"ratio":clampf(full,0.0,1.0) if full>=0.0 else -1.0,"color":T.RED if full>=0.97 else (T.AMBER if full>=0.85 else T.GREEN),"edge":T.RED if full>=1.0 else T.RULE,
		"sub":("of %s room" % S.n(room)+(" · %s× over" % S.n(full) if full>=1.5 else "")) if room>0.0 else "no yards built","sub_color":T.RED_TEXT if full>=1.0 else T.INK_MUTED,
		"tip":"Held: every material in the yards, each counted by the room it takes%s. Food, water and household goods are kept apart and not counted.\nWhat is held beyond the room lies in the open and spoils faster.\n%s" % [(" ("+counted+")") if not counted.is_empty() else "",String(Words.supply(held,room,data.get("hauling")).sentence)]}))
	# What comes in a day, and what is lost.
	var delivered:=0.0;var lost:=0.0;var count:=0
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		delivered+=float(item.get("delivered",0.0));lost+=float(item.get("loss",0.0))
		if float(item.get("delivered",0.0))>0.05:count+=1
	out.append(S.kpi_item("income",{"value":"+"+S.n(delivered) if delivered>=0.5 else "0","ratio":clampf(delivered/maxf(1.0,delivered+lost),0.0,1.0) if delivered+lost>0.05 else -1.0,"color":T.GREEN,
		"sub":"%d materials · −%s lost" % [count,S.n(lost)],"tip":"Loads brought into the yards today, every material together; and what spoiled or was lost in store. The bar: what came in against what came in and was lost."}))
	# The carrying: how much of what is dug and cut the carriers bring in.
	var hauling:Variant=data.get("hauling")
	var supply:=Words.supply(held,room,hauling)
	var flow:=clampf(float(hauling),0.0,1.0) if hauling!=null else -1.0
	out.append(S.kpi_item("carry",{"value":"%d%%" % roundi(flow*100.0) if flow>=0.0 else "—","ratio":flow,"color":T.TEAL if flow>=0.9 else (T.AMBER if flow>=0.6 else T.RED),
		"sub":("hauling slows us" if String(supply.slows).begins_with("Hauling") else "storage slows us") if not String(supply.slows).is_empty() else "of what is dug is carried","sub_color":T.AMBER_TEXT if not String(supply.slows).is_empty() else T.INK_MUTED,
		"tip":"%s\n%s" % [String(supply.sentence),("%s decides who digs, cuts and carries." % who if not who.is_empty() else "The local leader decides who digs, cuts and carries.") if bool(data.get("managed",true)) else "You asked for extra hands on part of the work."]}))
	return out

## Every word and figure on the page that follows the day.
func _fill()->void:
	var supply:=Words.supply(float(data.get("storage",0.0)),float(data.get("capacity",0.0)),data.get("hauling"))
	S.put(_hero,String(supply.store_words))
	var carry:=String(supply.carry_words)
	S.put(_supply,carry.left(1).to_upper()+carry.substr(1)+"." if not carry.is_empty() else "Carrying will be counted after the first day's work.")
	for item:Dictionary in kpi_items(data):
		var refs:Dictionary=_readings[item.id]
		S.put(refs.value,String(item.value),item.get("value_color",T.INK));S.put(refs.note,String(item.sub),item.get("sub_color",T.INK_MUTED));refs.cell.tooltip_text=String(item.get("tip",""))
	var land:=String(data.get("land",""))
	if _land!=null:
		var cover:=float(data.get("cover",ResourceSystem.land_reading().get("cover",0.0)))
		S.put(_land,"Land searched %d%%" % roundi(cover*100.0))
		_land.tooltip_text=land
		var meter:=_land_bar as S.Bar
		meter.ratio=clampf(cover,0.0,1.0);meter.queue_redraw()
		var condition:=String(data.get("land_condition",land.get_slice(". ",0).get_slice(", ",1)))
		S.put(_land_note,condition.left(1).to_upper()+condition.substr(1)+".")
		_land_note.tooltip_text=land
	var by_key:={}
	for item:Dictionary in data.get("rows",[]):by_key[String(item.key)]=item
	for entry:Dictionary in _rows:
		var item:Dictionary=by_key.get(String(entry.key),{})
		if item.is_empty():continue
		var reading:=reading_of(item)
		var dry:=empty(item)
		S.set_row(entry.refs,{"label":String(item.name),"note":flow_words(item),"note_color":T.INK_MUTED,"value":S.n(float(item.stock)),"value_color":T.RED_TEXT if dry else T.INK,"points":item.get("points",[]),
			"tag":"Empty" if dry else ("Blocked" if bool(item.get("blocked",false)) else trend_word(String(reading.trend))),
			"tag_color":T.RED if dry or bool(item.get("blocked",false)) else (T.GREEN if String(reading.trend)=="rising" else (T.AMBER if String(reading.trend)=="falling" else T.MUTED)),
			"tip":"%s: %s in store.\n%s" % [String(item.name),S.n(float(item.stock)),_reading_words(item)]})
	for entry:Dictionary in _held_rows:
		var item:Dictionary=by_key.get(String(entry.key),{})
		if not item.is_empty():S.set_row(entry.refs,{"label":String(item.name),"value":S.n(float(item.stock)),"tip":"%s in store, with nothing coming in or going out today.\n%s" % [S.n(float(item.stock)),_reading_words(item)]})
	var opened:Dictionary=by_key.get(String(data.get("selected","")),{})
	if not opened.is_empty():
		for d in mini(_details.size(),(opened.get("details",[]) as Array).size()):
			S.put(_details[d],String(opened.details[d]),T.RED_TEXT if bool(opened.get("blocked",false)) else T.INK_MUTED)
	var incoming:Array=data.get("incoming",[])
	for index in mini(_incoming.size(),incoming.size()):
		var shipment:Dictionary=incoming[index]
		var days_left:=maxi(0,ceili(float(shipment.arrival_day)-float(data.get("day",0.0))))
		S.set_row((_incoming[index] as Dictionary).refs,{"label":"%s %s on the way" % [S.n(float(shipment.quantity)),String(shipment.resource).to_lower()],
			"note":"From %s; arrives %s." % [String(shipment.source_name),"today" if days_left<=0 else "in "+preload("res://scripts/hud/production_plain.gd").span_text(days_left)],"value":""})
