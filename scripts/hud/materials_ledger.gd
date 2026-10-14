extends VBoxContainer
## The Materials tab, one page: a strip of four figures (the yards held
## against their room, the land searched, what comes in a day, the carrying),
## the materials that move as a dense table in two columns (icon, name, the
## day's flow in and out, a spark of the monthly counts, the stock, a state
## tag, and a button to their sources), then one compact line for the
## materials only held and one for those not yet within reach. The opened
## material's sources sit under the table. Food, water and household goods
## are kept apart from the yards: they have their own tabs.
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
var _kpis:Dictionary={}
## Per moving material: {key, refs}.
var _rows:Array=[]
var _still:Label
var _grid:GridContainer
## Per shipment on the road: {voice, when} (the row's label and note).
var _incoming:Array=[]
var _details:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",10)
	_shape=shape_of(block)
	var who:=_who(block)
	var focus:=_current(block)
	var can_direct:=bool(block.get("can_direct",false))
	_kpis=S.kpi_strip(self,[
		{"id":"stores","label":"In the yards","icon":"Stone"},
		{"id":"land","label":"Land searched","icon":"find","icon_kind":"chart"},
		{"id":"income","label":"Coming in a day","icon":"Timber"},
		{"id":"carry","label":"Carrying","icon":"carry","icon_kind":"people","action":{"text":"More hands" if focus!="logistics" else "More hands (now)","on_press":func():data.on_focus.call("logistics"),
			"tip":"Ask %s to put more people on carrying loads and keeping the paths open. Other work slows." % (who if not who.is_empty() else "the leader"),"chosen":focus=="logistics"} if can_direct else null},
	])
	var gauge:Dictionary=_kpis.stores
	(gauge.value as Label).name="StoresHeld"
	var land_cell:Dictionary=_kpis.land
	(land_cell.sub as Label).name="SearchedLand";(land_cell.bar as Control).name="SearchedBar"
	if (_kpis.carry as Dictionary).action!=null:((_kpis.carry as Dictionary).action as Button).name="Choice_Logistics"
	var moving:Array=[];var still:Array=[];var beyond:Array=[]
	for item:Dictionary in block.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		(beyond if out_of_reach(item) else (still if is_idle(item,String(block.get("selected",""))) else moving)).append(item)
	var head:=S.head(self,"Moving through the yards")
	var row_buttons:=HBoxContainer.new();row_buttons.add_theme_constant_override("separation",6);(head.row as HBoxContainer).add_child(row_buttons)
	if can_direct and focus!="":
		row_buttons.add_child(S.verb("Let %s decide" % (who if not who.is_empty() else "the leader"),func():data.on_focus.call(""),"The leader spreads the work across what the place needs."))
	row_buttons.add_child(S.verb("Show on map",data.get("on_map"),"Mark known wood, stone and clay on the map"))
	_grid=S.columns(self,"Materials",400.0,2)
	for item:Dictionary in moving:
		var key:=String(item.key)
		var refs:=S.row(_grid,{"id":key,"icon":key,"label":String(item.name),"points":item.get("points",[]),"bar_width":64.0,"value_width":70.0,
			"buttons":[{"text":"Close" if String(block.get("selected",""))==key else "Sources","on_press":func():data.on_select.call(key),"tip":"Where it comes from","chosen":String(block.get("selected",""))==key}]})
		(refs.panel as Control).name="Material_"+key.validate_node_name()
		_rows.append({"key":key,"refs":refs})
	if moving.is_empty():_grid.add_child(S.label("Nothing comes in or goes out of the yards today.",13,T.INK_MUTED))
	_opened()
	if not still.is_empty():
		var line:=HBoxContainer.new();line.name="Still";line.add_theme_constant_override("separation",8);add_child(line)
		var lead:=S.label("Only held:",12,T.GOLD_TEXT,true);lead.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;line.add_child(lead)
		_still=S.label("",13,T.INK);_still.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_still.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_still.tooltip_text="In store, with nothing coming in or going out today.";line.add_child(_still)
	if not beyond.is_empty():
		var strip:=HFlowContainer.new();strip.name="NotYetInReach";strip.add_theme_constant_override("h_separation",6);strip.add_theme_constant_override("v_separation",4);add_child(strip)
		var lead:=S.label("Not yet within reach:",12,T.GOLD_TEXT,true);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;strip.add_child(lead)
		for item:Dictionary in beyond:
			var key:=String(item.key)
			var chip:=Button.new();chip.name="Beyond_"+key.validate_node_name();chip.text=String(item.name);chip.icon=Icons.material_texture(key,24);chip.expand_icon=false
			chip.focus_mode=Control.FOCUS_NONE;chip.flat=true;chip.add_theme_font_size_override("font_size",12);chip.add_theme_constant_override("icon_max_width",14)
			chip.add_theme_color_override("font_color",T.TEXT_SOFT);chip.add_theme_color_override("font_hover_color",T.INK)
			chip.tooltip_text=_reading_words(item)+"\nClick for where it could come from."
			chip.pressed.connect(func()->void:data.on_select.call(key))
			strip.add_child(chip)
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
func _opened()->void:
	var item:Dictionary={}
	for row:Dictionary in data.get("rows",[]):
		if String(row.key)==String(data.get("selected","")):item=row
	if item.is_empty():return
	var box:=VBoxContainer.new();box.name="Sources";box.add_theme_constant_override("separation",0);add_child(box)
	var head:=S.head(box,"%s: where it comes from" % String(item.name))
	(head.row as HBoxContainer).add_child(S.verb("Close",func():data.on_select.call(String(item.key)),"Hide its sources"))
	for detail:String in item.get("details",[]):
		var line:=S.label("",13,T.INK_MUTED);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(line);_details.append(line)
	if (item.get("details",[]) as Array).is_empty():box.add_child(S.label("No known place to dig or cut it yet. Scouts and surveys find new sources.",13,T.INK_MUTED))

func _arrange()->void:
	S.flow(_grid,size.x)
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

## Every word and figure on the page that follows the day.
func _fill()->void:
	var who:=_who(data)
	# The yards: held against their room, one bar, held ÷ room.
	var held:=float(data.get("storage",0.0));var room:=float(data.get("capacity",0.0))
	var full:=held/room if room>0.0 else -1.0
	var counted:=String(data.get("counted",""))
	S.set_kpi(_kpis.stores,{"value":S.n(held),"ratio":clampf(full,0.0,1.0) if full>=0.0 else -1.0,"color":T.RED if full>=0.97 else (T.AMBER if full>=0.85 else T.GREEN),"edge":T.RED if full>=1.0 else T.RULE,
		"sub":("of %s room" % S.n(room)+(" · %s× over" % S.n(full) if full>=1.5 else "")) if room>0.0 else "no yards built","sub_color":T.RED_TEXT if full>=1.0 else T.INK_MUTED,
		"tip":"Held: every material in the yards, each counted by the room it takes%s. Food, water and household goods are kept apart and not counted.\nWhat is held beyond the room lies in the open and spoils faster.\n%s" % [(" ("+counted+")") if not counted.is_empty() else "",String(Words.supply(held,room,data.get("hauling")).sentence)]})
	# The land searched: a share, with its bar; the yields and odds behind it.
	var land:=String(data.get("land",""))
	var cover:=float(data.get("cover",ResourceSystem.land_reading().get("cover",0.0) if land!="" else 0.0))
	S.set_kpi(_kpis.land,{"value":"%d%%" % roundi(cover*100.0) if land!="" else "—","ratio":clampf(cover,0.0,1.0) if land!="" else -1.0,"color":T.GOLD,
		"sub":"Land searched %d%%" % roundi(cover*100.0) if land!="" else "not settled yet","tip":land})
	((_kpis.land as Dictionary).sub as Control).mouse_filter=Control.MOUSE_FILTER_PASS
	((_kpis.land as Dictionary).sub as Control).tooltip_text=land
	# What comes in a day, and what is lost.
	var delivered:=0.0;var lost:=0.0;var count:=0
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		delivered+=float(item.get("delivered",0.0));lost+=float(item.get("loss",0.0))
		if float(item.get("delivered",0.0))>0.05:count+=1
	S.set_kpi(_kpis.income,{"value":"+"+S.n(delivered) if delivered>=0.5 else "0","ratio":clampf(delivered/maxf(1.0,delivered+lost),0.0,1.0) if delivered+lost>0.05 else -1.0,"color":T.GREEN,
		"sub":"%d materials · −%s lost" % [count,S.n(lost)],"tip":"Loads brought into the yards today, every material together; and what spoiled or was lost in store. The bar: what came in against what came in and was lost."})
	# The carrying: how much of what is dug and cut the carriers bring in.
	var hauling:Variant=data.get("hauling")
	var supply:=Words.supply(held,room,hauling)
	var flow:=clampf(float(hauling),0.0,1.0) if hauling!=null else -1.0
	S.set_kpi(_kpis.carry,{"value":"%d%%" % roundi(flow*100.0) if flow>=0.0 else "—","ratio":flow,"color":T.TEAL if flow>=0.9 else (T.AMBER if flow>=0.6 else T.RED),
		"sub":String(supply.slows) if not String(supply.slows).is_empty() else "of what is dug and cut is carried in","sub_color":T.AMBER_TEXT if not String(supply.slows).is_empty() else T.INK_MUTED,
		"tip":"%s\n%s" % [String(supply.sentence),("%s decides who digs, cuts and carries." % who if not who.is_empty() else "The local leader decides who digs, cuts and carries.") if bool(data.get("managed",true)) else "You asked for extra hands on part of the work."]})
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
	if _still!=null:
		var parts:PackedStringArray=[]
		for item:Dictionary in data.get("rows",[]):
			if String(item.get("key","")) in ELSEWHERE:continue
			if is_idle(item,String(data.get("selected",""))):parts.append("%s %s" % [String(item.name),S.n(float(item.stock))])
		S.put(_still,"  ·  ".join(parts))
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
