extends VBoxContainer
## Supply decisions lead. A bounded chooser keeps the inventory compact;
## one selected material explains its stock, daily flow and known places.
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
const PAGE_SIZE:=8

var data:Dictionary
var _shape:Array=[]
var _land:Label
var _land_bar:Control
var _land_note:Label
## Bounded material choices: {key, button}.
var _rows:Array=[]
var _grid:GridContainer
var _composition:BoxContainer
var _inventory:VBoxContainer
var _catalog:VBoxContainer
var _browse_state:Dictionary={}
var _page_label:Label
var _previous:Button
var _next:Button
var _detail_offset:=0
var _selection:Dictionary={}
var _detail_host:VBoxContainer
var _browser:Control
var _hero:Label
var _supply:Label
var _readings:Dictionary={}
## At most three incoming shipment summaries; the link opens all deliveries.
var _incoming:Array=[]
var _details:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",16)
	_shape=shape_of(block)
	var who:=_who(block)
	var focus:=_current(block)
	var can_direct:=bool(block.get("can_direct",false))
	_composition=BoxContainer.new();_composition.vertical=true;_composition.add_theme_constant_override("separation",24);add_child(_composition)
	var overview:=VBoxContainer.new();overview.add_theme_constant_override("separation",8);overview.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.size_flags_stretch_ratio=0.75;_composition.add_child(overview)
	_inventory=VBoxContainer.new();_inventory.add_theme_constant_override("separation",12);_inventory.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_inventory.size_flags_stretch_ratio=1.5;_composition.add_child(_inventory)
	_hero=S.voice("",24);_hero.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview.add_child(_hero)
	_supply=S.label("",14,T.INK_MUTED);_supply.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview.add_child(_supply)
	var row_buttons:=HFlowContainer.new();row_buttons.add_theme_constant_override("h_separation",8);row_buttons.add_theme_constant_override("v_separation",8);overview.add_child(row_buttons)
	if can_direct:
		var more:=S.verb("More carriers"+(" (now)" if focus=="logistics" else ""),func():data.on_focus.call("logistics"),"Ask %s to put more people on carrying loads and keeping the paths open. Other work slows." % (who if not who.is_empty() else "the leader"),focus=="logistics")
		more.name="Choice_Logistics";row_buttons.add_child(more)
		if focus!="":row_buttons.add_child(S.verb("Let %s decide" % (who if not who.is_empty() else "the leader"),func():data.on_focus.call(""),"The leader spreads the work across what the place needs."))
	row_buttons.add_child(S.verb("Show on map",data.get("on_map"),"Mark known wood, stone and clay on the map"))
	var readings:=VBoxContainer.new();readings.add_theme_constant_override("separation",6);overview.add_child(readings)
	for item:Dictionary in kpi_items(block):
		var cell:=HFlowContainer.new();cell.add_theme_constant_override("h_separation",6);cell.add_theme_constant_override("v_separation",2);readings.add_child(cell)
		cell.add_child(S.label(String(KPI_LABELS[item.id]),14,T.INK_MUTED))
		var value:=S.voice("",16);cell.add_child(value)
		var note:=S.label("",14,T.INK_MUTED);cell.add_child(note)
		_readings[item.id]={"cell":cell,"value":value,"note":note}
	# Land condition stays plain; exact yield factors and odds remain in its tooltip.
	if String(block.get("land",""))!="":
		var searched:=VBoxContainer.new();searched.name="Land";searched.add_theme_constant_override("separation",4);add_child(searched)
		var reading:=HBoxContainer.new();reading.add_theme_constant_override("separation",16);searched.add_child(reading)
		_land=S.label("",16,T.INK,true);_land.name="SearchedLand";_land.mouse_filter=Control.MOUSE_FILTER_PASS;reading.add_child(_land)
		_land_bar=S.bar(0.0,T.INK_MUTED,96.0,5.0);_land_bar.name="SearchedBar";reading.add_child(_land_bar)
		_land_note=S.label("",14,T.INK_MUTED);_land_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;searched.add_child(_land_note)
	_build_browser()
	_build_inventory()
	resized.connect(_arrange)
	_inventory.resized.connect(_arrange)
	_fill()
	_arrange.call_deferred()

## Browsing state belongs to the provider, never to a save or simulation.
func _build_browser()->void:
	_browse_state=data.get("browse_state",{})
	_catalog=VBoxContainer.new();_catalog.add_theme_constant_override("separation",12);_inventory.add_child(_catalog)

func _browse_controls()->Control:
	var count:=0
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) not in ELSEWHERE:count+=1
	var pages:=HFlowContainer.new();pages.add_theme_constant_override("h_separation",8);pages.add_theme_constant_override("v_separation",6)
	pages.visible=count>PAGE_SIZE or not String(_browse_state.get("query","")).is_empty()
	var search:=LineEdit.new();search.name="FindMaterial";search.placeholder_text="Find a material";search.text=String(_browse_state.get("query",""));search.custom_minimum_size=Vector2(180,40);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pages.add_child(search)
	search.text_changed.connect(func(words:String)->void:_browse_state.query=words;_browse_state.page=0;_repage())
	_previous=S.verb("‹",func()->void:_browse_state.page=int(_browse_state.get("page",0))-1;_repage(),"Previous materials");_previous.name="PreviousMaterials";_previous.custom_minimum_size.x=40;pages.add_child(_previous)
	_page_label=S.label("",14,T.INK_MUTED);_page_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pages.add_child(_page_label)
	_next=S.verb("›",func()->void:_browse_state.page=int(_browse_state.get("page",0))+1;_repage(),"Next materials");_next.name="NextMaterials";_next.custom_minimum_size.x=40;pages.add_child(_next)
	return pages

func _page_rows()->Array:
	var moving:Array=[];var held:Array=[];var unknown:Array=[]
	var query:=String(_browse_state.get("query","")).strip_edges().to_lower()
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		if not query.is_empty() and not String(item.name).to_lower().contains(query):continue
		(unknown if out_of_reach(item) else (held if is_idle(item,"") else moving)).append(item)
	var matches:=moving+held+unknown
	var last:=maxi(0,ceili(float(matches.size())/PAGE_SIZE)-1)
	var page:=clampi(int(_browse_state.get("page",0)),0,last);_browse_state.page=page
	if _page_label!=null:
		_page_label.text="%d–%d of %d materials" % [page*PAGE_SIZE+1,mini((page+1)*PAGE_SIZE,matches.size()),matches.size()] if not matches.is_empty() else "No matching materials"
		_previous.disabled=page==0;_next.disabled=page>=last
	return matches.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)

func _repage()->void:
	_build_inventory();_fill();_arrange.call_deferred()

func _build_inventory()->void:
	for child:Node in _catalog.get_children():
		if child==_browser:continue
		_catalog.remove_child(child);child.queue_free()
	_rows.clear();_incoming.clear();_details.clear();_selection.clear();_detail_offset=0
	_detail_host=VBoxContainer.new();_detail_host.add_theme_constant_override("separation",6);_catalog.add_child(_detail_host);_catalog.move_child(_detail_host,0)
	_opened(_detail_host)
	var choose:=S.head(_catalog,"Choose a material")
	choose.title.add_theme_font_size_override("font_size",16);_catalog.move_child(choose.box,1)
	if _browser==null:
		_browser=_browse_controls();_catalog.add_child(_browser)
	_catalog.move_child(_browser,2)
	_grid=S.columns(_catalog,"Materials",200.0,3)
	_grid.add_theme_constant_override("h_separation",8)
	for item:Dictionary in _page_rows():
		var key:=String(item.key)
		var button:=S.verb("",func():data.on_select.call(key),"View stock, daily supply and known places for "+String(item.name),key==selected_key(data))
		button.name="Material_"+key.validate_node_name();button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.icon=Icons.material_texture(key,24);button.add_theme_constant_override("icon_max_width",20)
		_grid.add_child(button);_rows.append({"key":key,"button":button})
	var incoming:Array=data.get("incoming",[])
	if not incoming.is_empty():
		var road:=VBoxContainer.new();road.name="Incoming";road.add_theme_constant_override("separation",4);_catalog.add_child(road)
		for shipment:Dictionary in incoming.slice(0,3):
			var line:=S.label("",14,T.INK_MUTED);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;road.add_child(line);_incoming.append({"label":line})
		road.add_child(S.verb("All %d deliveries" % incoming.size(),data.get("on_trade"),"Goods on the road between your settlements, and what arrived"))

## Keep the selected material in place while browsing another inventory page.
static func selected_key(block:Dictionary)->String:
	var rows:Array=block.get("rows",[])
	for row:Dictionary in rows:
		if String(row.key)==String(block.get("selected","")):return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE and empty(row) and float(row.get("delivered",0.0))>0.05:return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE and not is_idle(row,"") and not out_of_reach(row):return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE:return String(row.key)
	return ""

func _opened(parent:Node)->void:
	var item:Dictionary={}
	for row:Dictionary in data.get("rows",[]):
		if String(row.key)==selected_key(data):item=row
	if item.is_empty():
		parent.add_child(S.label("No materials found yet.",16,T.INK_MUTED));return
	var head:=HFlowContainer.new();head.add_theme_constant_override("h_separation",8);parent.add_child(head)
	head.add_child(S.icon(String(item.key),24))
	head.add_child(S.voice(String(item.name),20))
	var stock:=S.voice("",20);head.add_child(stock);_selection.stock=stock
	var spark:=preload("res://scripts/hud/material_stock_spark.gd").new();spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(spark);_selection.spark=spark
	var reading:=S.label("",14,T.INK_MUTED);reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(reading);_selection.reading=reading
	var detail_toggle:=S.verb("Where it comes from",func():_browse_state.sources_open=not bool(_browse_state.get("sources_open",false));_repage(),"Show the known places supplying "+String(item.name))
	detail_toggle.name="WhereItComesFrom";detail_toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;parent.add_child(detail_toggle)
	var details:Array=item.get("details",[])
	var expanded:=bool(_browse_state.get("sources_open",false))
	detail_toggle.text="Hide places" if expanded else "Where it comes from"
	var box:=VBoxContainer.new();box.name="Sources";box.add_theme_constant_override("separation",6);parent.add_child(box)
	if details.is_empty():
		var empty_sources:=S.label("No known place to dig or cut it yet. Scouts and surveys find new places.",14,T.INK_MUTED);empty_sources.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(empty_sources)
		detail_toggle.visible=false
	else:
		var limit:=PAGE_SIZE if expanded else 1
		var last:=maxi(0,ceili(float(details.size())/PAGE_SIZE)-1)
		var page:=clampi(int(_browse_state.get("sources_page",0)),0,last) if expanded else 0
		_detail_offset=page*PAGE_SIZE
		for detail:String in details.slice(_detail_offset,_detail_offset+limit):
			var line:=S.label("",14,T.INK_MUTED);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(line);_details.append(line)
		if details.size()==1:
			detail_toggle.visible=false
			var place_heading:=S.label("Where it comes from",14,T.INK,true);box.add_child(place_heading);box.move_child(place_heading,0)
		elif not expanded:
			box.add_child(S.label("%d other known places" % (details.size()-1),14,T.INK_MUTED))
		elif details.size()>PAGE_SIZE:
			var pages:=HFlowContainer.new();pages.add_theme_constant_override("h_separation",8);box.add_child(pages)
			var previous:=S.verb("Previous places",func():_browse_state.sources_page=page-1;_repage());previous.name="PreviousSources";previous.disabled=page==0;pages.add_child(previous)
			pages.add_child(S.label("%d of %d places" % [mini(_detail_offset+PAGE_SIZE,details.size()),details.size()],14,T.INK_MUTED))
			var next:=S.verb("Next places",func():_browse_state.sources_page=page+1;_repage());next.name="NextSources";next.disabled=page>=last;pages.add_child(next)

func _arrange()->void:
	_composition.vertical=size.x<850.0
	S.flow(_grid,_inventory.size.x)

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
		var open:bool=selected_key(block)==item.key
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
const KPI_LABELS:={"stores":"In the yards","income":"Total coming in a day","carry":"Carrying"}
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
		var suffix:=" · unavailable" if out_of_reach(item) else " · "+S.n(float(item.stock))
		(entry.button as Button).text=String(item.name)+suffix
		(entry.button as Button).tooltip_text="%s in store. %s.\n%s" % [S.n(float(item.stock)),flow_words(item),_reading_words(item)]
	var opened:Dictionary=by_key.get(selected_key(data),{})
	if not opened.is_empty():
		S.put(_selection.stock,S.n(float(opened.stock))+" in store",T.RED_TEXT if empty(opened) else T.INK)
		_selection.spark.points=opened.get("points",[]);_selection.spark.visible=not (_selection.spark.points as Array).is_empty();_selection.spark.queue_redraw()
		var stock_reading:=reading_of(opened)
		var since:=" · "+trend_word(String(stock_reading.trend)).to_lower()+" since latest count" if not (opened.get("points",[]) as Array).is_empty() else ""
		S.put(_selection.reading,flow_words(opened)+since)
		_selection.reading.tooltip_text=_reading_words(opened)
		for d in mini(_details.size(),(opened.get("details",[]) as Array).size()-_detail_offset):
			S.put(_details[d],String(opened.details[d+_detail_offset]),T.RED_TEXT if bool(opened.get("blocked",false)) else T.INK_MUTED)
	var incoming:Array=data.get("incoming",[])
	for index in mini(_incoming.size(),incoming.size()):
		var shipment:Dictionary=incoming[index]
		var days_left:=maxi(0,ceili(float(shipment.arrival_day)-float(data.get("day",0.0))))
		S.put(_incoming[index].label,"%s %s from %s · %s" % [S.n(float(shipment.quantity)),String(shipment.resource).to_lower(),String(shipment.source_name),"arrives today" if days_left<=0 else "in "+preload("res://scripts/hud/production_plain.gd").span_text(days_left)])
