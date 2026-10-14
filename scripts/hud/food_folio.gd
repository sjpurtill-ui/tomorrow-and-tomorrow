extends VBoxContainer
## The Food tab, one page: a strip of four figures across the top (food in
## store against the room for it, the 90-day outlook in days, water fetched
## against the day's need, the hands on food), each with its control beside
## it; the day's rations as one bar with the engine's own terms under it;
## then two columns of one-line rows: the stores, the fire and the past
## seasons on the left, where the food and water come from on the right, and
## any deliveries on the road. The top bar already says how many days the
## food and water last, so this page never says it again.
##
## Every number is the engine's (food_system.gd metrics, water_metrics,
## food_care.gd). The live refresh (update_block) keeps every node while the
## page keeps its shape and writes the day's numbers into them.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")

## The day's count in order: [flow key, caption, the bar's ink (null: not a
## part of the bar)]. Every term is the engine's own (food_system.gd): what
## was gathered, what was taken in from towns we hold, what was eaten, what
## spoiled, the weight drying, smoking and canning took out of the food
## (food_preserved.lost), and the change in the stores (food_net). They add
## up: in + taken - eaten - spoiled - keeping = kept.
const FLOW_CELLS := [["Produced", "Brought in", null], ["Taken", "Taken in", null], ["Eaten", "Eaten", Color("8a6118")], ["Spoiled", "Spoiled", Color("a34435")],
	["Keeping", "Lost in drying", Color("4d6389")], ["Net", "Kept", Color("5d6f34")]]
## What each food source is drawn with (resource_icons.gd people glyphs).
const SOURCE_ICONS := {"Wild gathering":"gather", "Hunting":"hunt", "Fishing":"fish", "Cultivation":"tend"}

var data:Dictionary
var daily_values:Dictionary={}
var flow_bar:FlowBar
var _shape:Array=[]
var _refs:Dictionary={}
var _grids:Array[GridContainer]=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="ProvisionsLedger"
	add_theme_constant_override("separation",10)
	_shape=shape_of(block)
	_refs={"kpis":{},"stores":[],"sources":[],"deliveries":[]}
	var who:=_who()
	var current:=_current_focus(block)
	var can_direct:=bool(block.get("can_direct",false))
	# The strip: four figures, each with the control that moves it.
	_refs.kpis=S.kpi_strip(self,[
		{"id":"store","label":"Food in store","icon":"Food"},
		{"id":"ahead","label":"In 90 days","icon":"stores","icon_kind":"people"},
		{"id":"water","label":"Water","icon":"Freshwater","action":{"text":"More" if current!="water" else "More (now)","on_press":func():data.on_focus.call("water"),"tip":"Ask %s to put more people on finding, reaching and carrying water. Other work slows." % who,"chosen":current=="water"} if can_direct else null},
		{"id":"hands","label":"On food","icon":"gather","icon_kind":"people","action":{"text":"More" if current!="provisions" else "More (now)","on_press":func():data.on_focus.call("provisions"),"tip":"Ask %s to put more people on gathering, hunting, fishing and carrying food. Other work slows." % who,"chosen":current=="provisions"} if can_direct else null},
	])
	for key:String in ["water","hands"]:
		var action:Button=(_refs.kpis[key] as Dictionary).action
		if action!=null:action.name="Choice_"+("Water" if key=="water" else "Provisions")
	# The day's rations: one bar and the engine's terms under it.
	var today:=S.head(self,"Today · rations")
	_refs.today_side=today.side
	if can_direct:
		var decide:=S.verb("Let %s decide" % who+(" (now)" if current=="" else ""),func():data.on_focus.call(""),"%s spreads the work across what the place needs." % who.capitalize(),current=="")
		decide.name="Choice_";(today.row as HBoxContainer).add_child(decide)
	flow_bar=FlowBar.new();flow_bar.name="FlowBar";flow_bar.custom_minimum_size=Vector2(0,12);add_child(flow_bar)
	var daily:=GridContainer.new();daily.name="Daily";daily.columns=FLOW_CELLS.size();daily.add_theme_constant_override("h_separation",10);add_child(daily)
	for pair:Array in FLOW_CELLS:
		var cell:=HBoxContainer.new();cell.name="Cell_"+String(pair[0]);cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",5);cell.mouse_filter=Control.MOUSE_FILTER_PASS;daily.add_child(cell)
		if pair[2]!=null:
			var swatch:=ColorRect.new();swatch.color=pair[2];swatch.custom_minimum_size=Vector2(8,8);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(swatch)
		var caption:=S.label(String(pair[1]),12,T.INK_MUTED);caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(caption)
		var value:=S.voice("",20);value.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(value)
		daily_values[pair[0]]=value
	_refs.missions=S.label("",12,T.INK_MUTED);add_child(_refs.missions)
	# Two columns of rows.
	var grid:=S.columns(self,"FoodColumns",400.0,2);_grids.append(grid)
	grid.add_theme_constant_override("v_separation",12)
	var left:=VBoxContainer.new();left.add_theme_constant_override("separation",0);left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(left)
	var right:=VBoxContainer.new();right.add_theme_constant_override("separation",0);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(right)
	var stores_head:=S.head(left,"Stores");_refs.stores_side=stores_head.side
	for item:Dictionary in block.get("rows",[]):
		(_refs.stores as Array).append(S.row(left,{"id":String(item.name),"icon":"Food" if String(item.name)!="Stored food" else "Clay","label":String(item.name),"value_width":96.0}))
	if (block.get("fire",{}) as Dictionary).size()>0:_refs.fire=S.row(left,{"id":"fire","icon":"fetch","icon_kind":"people","label":"Hearth fire","bar_width":60.0})
	# The past seasons: the food days at each monthly count, as one spark.
	var past:=HBoxContainer.new();past.name="PastSeasons";past.add_theme_constant_override("separation",8);past.custom_minimum_size.y=34;left.add_child(past)
	past.add_child(S.icon("Food"))
	var past_label:=S.label("Days of food, past counts",14,T.INK);past_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;past.add_child(past_label)
	var spark:=Spark.new();spark.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;past.add_child(spark)
	spark.ready.connect(func()->void:spark.custom_minimum_size=Vector2(80,28))
	_refs.spark=spark
	_refs.past_range=S.label("",12,T.INK_MUTED);_refs.past_range.size_flags_vertical=Control.SIZE_SHRINK_CENTER;past.add_child(_refs.past_range)
	var sources_head:=S.head(right,"Where it comes from");_refs.sources_side=sources_head.side
	for source:Dictionary in block.get("sources",[]):
		var name_word:=String(source.get("name","Source"))
		(_refs.sources as Array).append(S.row(right,{"id":name_word,"icon":String(SOURCE_ICONS.get(name_word,"gather")),"icon_kind":"people","label":name_word,"bar_width":60.0,"value_width":84.0}))
	var water_access:Dictionary=block.get("water_access",{})
	if not water_access.is_empty():
		_refs.water_row=S.row(right,{"id":"water_source","icon":"Freshwater","label":"Water","value_width":84.0,
			"buttons":[{"text":"Show","on_press":data.get("on_water_map"),"tip":"Show water on the map"}] if data.get("on_water_map") is Callable else []})
	var shipments:Array=block.get("deliveries",[])
	if not shipments.is_empty():
		S.head(right,"On the road")
		for shipment:Dictionary in shipments:(_refs.deliveries as Array).append(S.row(right,{"id":"delivery","icon":String(shipment.get("resource","Food")),"label":"","value_width":84.0}))
	if bool(block.get("has_deliveries",false)):
		var more:=S.verb("Deliveries",data.get("on_trade"),"Every delivery between your settlements, on the road and arrived")
		more.size_flags_horizontal=Control.SIZE_SHRINK_END;right.add_child(more)
	resized.connect(_layout)
	_fill()
	_layout.call_deferred()

func _layout()->void:
	for grid:GridContainer in _grids:S.flow(grid,size.x)

func update_block(block:Dictionary)->bool:
	if _refs.is_empty() or shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: its stores, sources and deliveries, the
## controls offered and which is chosen.
static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):rows.append(String(item.get("name","")))
	var sources:Array=[]
	for source:Dictionary in block.get("sources",[]):sources.append(String(source.get("name","")))
	return [String(block.get("leader_name","")),rows,sources,(block.get("deliveries",[]) as Array).size(),bool(block.get("has_deliveries",false)),
		bool(block.get("can_direct",false)),_current_focus(block),(block.get("fire",{}) as Dictionary).size()>0,
		(block.get("water_access",{}) as Dictionary).is_empty()]

static func _current_focus(block:Dictionary)->String:
	var focus:=String(block.get("focus",""))
	return "" if bool(block.get("managed",true)) else (focus if focus in ["provisions","water"] else "other")

func _who()->String:
	var who:=String(data.get("leader_name",""))
	return who if not who.is_empty() else "the leader"

## Every figure on the page that follows the day.
func _fill()->void:
	var amounts:=flow_amounts(data.get("flow",{}))
	var eaten:=maxf(0.5,float(amounts.Eaten))
	var kpis:Dictionary=_refs.kpis
	# Food in store against the room for it.
	var stock:=0.0
	for item:Dictionary in data.get("rows",[]):stock+=float(item.get("stock",0.0))
	var room:=float(data.get("capacity",0.0))
	var full:=stock/room if room>0.0 else -1.0
	S.set_kpi(kpis.store,{"value":S.n(stock),"ratio":clampf(full,0.0,1.0) if full>=0.0 else -1.0,"color":T.RED if full>=0.98 else (T.AMBER if full>=0.85 else T.GREEN),
		"sub":("of %s room" % S.n(room)) if room>0.0 else "no granary yet",
		"tip":"Rations held in every store here. Food beyond the room the pits, granaries and sealed jars give is thrown out at the end of the day.\n%s" % String(data.get("lean",""))})
	# The outlook in days, the same unit as the top bar's food.
	var forecast:Dictionary=data.get("forecast90",{})
	var shortage:=int(forecast.get("first_shortage_day",-1))
	var ending:=float(forecast.get("ending_days",-1.0))
	var ahead:={"value":"—","sub":"not reckoned yet","ratio":-1.0,"tip":"The 90-day outlook is reckoned each week from the season's yields, spoilage and need."}
	if shortage>0:
		ahead={"value":"Short in %d days" % shortage,"value_color":T.RED_TEXT,"sub":"if the seasons go as expected","ratio":clampf(float(shortage)/90.0,0.0,1.0),"color":T.RED,"edge":T.RED,
			"tip":"At the season's yields, spoilage and need, food runs short in %s." % Plain.duration_text(float(shortage))}
	elif not forecast.is_empty():
		ahead={"value":preload("res://scripts/hud/era_words.gd").days_in_words(maxf(0.0,ending)) if ending>=0.0 else "—","sub":"of food left · no shortage","ratio":clampf(ending/maxf(90.0,ending),0.0,1.0) if ending>=0.0 else -1.0,"color":T.GREEN,
			"tip":"Days of food in store 90 days from now, at the season's yields, spoilage and need. No shortage is expected before then."}
	S.set_kpi(kpis.ahead,ahead)
	# Water fetched against the day's need (the top bar holds the days in store).
	var water:Dictionary=data.get("water",{})
	var wet:=Words.water(water)
	var need:=float(water.get("required_today",0.0))
	if need>0.0:
		var ratio:=clampf(float(water.get("intake_ratio",0.0)),0.0,1.0)
		S.set_kpi(kpis.water,{"value":"%d%%" % roundi(ratio*100.0),"value_color":(T.RED_TEXT if String(wet.tone)=="bad" else T.AMBER_TEXT) if ratio<0.98 else T.INK,"ratio":ratio,"color":T.TEAL if ratio>=0.98 else (T.AMBER if ratio>=0.8 else T.RED),
			"sub":"of %s drinks needed" % S.n(need),
			"tip":"%s.\nYesterday %s drinks were fetched for the %s needed; %s are kept in store. One drink is one person's water for a day." % [String(wet.sentence).trim_suffix("."),S.n(float(water.get("collected_today",0.0))),S.n(need),S.n(float(water.get("stored",0.0)))]})
	else:S.set_kpi(kpis.water,{"value":"—","sub":"counted after the first day","ratio":-1.0})
	# The hands on food, against everyone at work.
	var hands:=float(data.get("food_workers",0.0))
	var share:=float(data.get("food_share",0.0))
	S.set_kpi(kpis.hands,{"value":S.n(hands),"ratio":clampf(share,0.0,1.0),"color":T.GOLD,"sub":"%d in 100 at work" % roundi(share*100.0),
		"tip":(String(data.get("food_plan",""))+"\n" if String(data.get("food_plan",""))!="" else "")+("%s decides the daily food work." % _who().capitalize() if bool(data.get("managed",true)) else "You asked for extra hands on part of the work.")})
	# The day's rations.
	for key:String in daily_values:
		var amount:=float(amounts.get(key,0))
		var words:=S.n(amount) if key!="Net" else S.signed(amount)
		if key in ["Eaten","Spoiled","Keeping"] and amount>=0.5:words="−"+S.n(amount)
		if key in ["Produced","Taken"] and amount>=0.5:words="+"+S.n(amount)
		S.put(daily_values[key],words,(T.RED_TEXT if amount<0 else T.GREEN_TEXT) if key=="Net" else T.INK)
	for key:String in ["Taken","Keeping"]:
		(daily_values[key].get_parent() as Control).visible=absf(float(amounts[key]))>=0.5
	(daily_values.Produced.get_parent() as Control).tooltip_text="Rations gathered, hunted, fished or harvested today."
	(daily_values.Taken.get_parent() as Control).tooltip_text="Food taken in from towns we hold."
	(daily_values.Eaten.get_parent() as Control).tooltip_text="Rations eaten today."
	(daily_values.Spoiled.get_parent() as Control).tooltip_text="Rations that went bad in store today, every store together (the Stores rows give each)."
	(daily_values.Keeping.get_parent() as Control).tooltip_text="Drying, smoking and canning make fresh food keep, and take some of its weight: about an eighth dried, a sixth smoked, a tenth canned."
	(daily_values.Net.get_parent() as Control).tooltip_text="The change in the stores over the day's count: brought in and taken in, less eaten, spoiled and lost in drying."
	var sent:=float(data.get("flow",{}).get("Missions",0))
	_refs.missions.visible=sent>=0.5
	S.put(_refs.missions,"Also today: %s rations went out with parties that left." % S.n(sent))
	S.put(_refs.today_side,"Stores are growing" if float(amounts.Net)>=0.5 else ("Stores are shrinking" if float(amounts.Net)<=-0.5 else "No change to stores today"),T.GREEN_TEXT if float(amounts.Net)>=0.5 else (T.RED_TEXT if float(amounts.Net)<=-0.5 else T.INK_MUTED))
	flow_bar.amounts=amounts;flow_bar.queue_redraw()
	# The stores, each with what spoiled of it today (they sum to Spoiled above).
	var rows:Array=data.get("rows",[])
	for index in mini(rows.size(),(_refs.stores as Array).size()):
		var item:Dictionary=rows[index]
		var amount:=float(item.get("stock",0.0));var lost:=float(item.get("lost",0.0))
		var note:=("%s spoiled today" % S.n(lost)) if lost>=0.5 else "nothing spoiled"
		if amount>=0.5:note+=" · %s alone" % Plain.span_text(amount/eaten)
		S.set_row(_refs.stores[index],{"label":String(item.name),"note":note,"note_color":T.AMBER_TEXT if lost>amount*0.02 and lost>=0.5 else T.INK_MUTED,"value":S.n(amount),
			"tag":"Empty" if amount<0.5 else "","tag_color":T.RED,"tip":String(item.get("detail",""))})
	S.put(_refs.stores_side,"%s spoiled today" % S.n(float(amounts.Spoiled)))
	if _refs.has("fire"):
		var fire:Dictionary=data.fire
		var lit:=bool(fire.get("available",false))
		var embers:=clampf(float(fire.get("embers",0.0)),0.0,1.0)
		var fuel:=float(data.get("fuel",-1.0))
		S.set_row(_refs.fire,{"label":"Hearth fire","note":("lit by "+String(fire.get("source","none")).replace("_"," ") if lit else "no one keeps a fire")+(" · %s wood smoked food today" % S.n(fuel) if fuel>=0.5 else ""),"value":"%d%%" % roundi(embers*100.0),"value_color":T.INK if lit else T.RED_TEXT,
			"ratio":embers,"bar_color":T.AMBER if lit else T.RED,"tag":"Out" if not lit else "","tag_color":T.RED,
			"tip":"%s\nKeeping it alive burned %s wood today; smoking meat and fish so they keep burned %s." % [String(fire.get("status","")),S.n(float(fire.get("maintenance_timber",0.0))),S.n(maxf(0.0,fuel))]})
	var points:Array=data.get("history",[])
	var spark:Control=_refs.spark
	if spark.get("points")!=points:spark.set("points",points);spark.queue_redraw()
	var low:=INF;var high:=-INF
	for point:Dictionary in points:
		if point.get("value")==null:continue
		low=minf(low,float(point.value));high=maxf(high,float(point.value))
	S.put(_refs.past_range,"%s to %s days" % [S.n(low),S.n(high)] if high>=low else "first count to come")
	# Where it comes from.
	var sources:Array=data.get("sources",[])
	var total_in:=0.0
	for source:Dictionary in sources:total_in+=float(source.get("produced",0.0))
	for index in mini(sources.size(),(_refs.sources as Array).size()):
		var source:Dictionary=sources[index]
		var amount:=float(source.get("produced",0.0))
		var ground:=clampf(float(source.get("source_health",1.0)),0.0,1.0)
		var overused:=bool(source.get("overused",false))
		var access:=String(source.get("access",""))
		var reach:=access in ["available","retrievable","retrievable game grounds","ambient wildlife only"]
		var tip:="Rations this source gave today."
		if source.has("renewable"):tip+=" The land nearby grows back about %s rations a day of it; taking more thins the game, fish or plants until they are rested." % S.n(float(source.renewable))
		tip+="\nThe land holds %d in 10 of what it once did." % roundi(ground*10.0)
		S.set_row(_refs.sources[index],{"label":String(source.get("name","")),"note":access if not reach or access=="ambient wildlife only" else ("%d in 100 of the food" % roundi(amount/maxf(1.0,total_in)*100.0) if amount>=0.5 else ""),
			"value":("+"+S.n(amount)) if amount>=0.5 else "none","value_color":T.INK if amount>=0.5 else T.INK_MUTED,
			"ratio":ground if amount>=0.5 or source.has("renewable") else -1.0,"bar_color":T.GREEN if ground>=0.8 else (T.AMBER if ground>=0.5 else T.RED),
			"tag":"Overused" if overused else ("Not known" if access=="practice not discovered" else ""),"tag_color":T.AMBER if overused else T.MUTED,"tip":tip})
	S.put(_refs.sources_side,"bar: how much the land holds")
	if _refs.has("water_row"):
		var w:Dictionary=data.water_access
		var known:=bool(w.get("recognized",false))
		var near:=bool(w.get("accessible",false))
		S.set_row(_refs.water_row,{"label":"Water","note":("%s, %s km away" % [String(w.get("source_kind","source")).capitalize(),S.n(float(w.get("distance_km",0.0)))]) if known else "no stream, spring or lake known",
			"value":S.n(float(water.get("collected_today",0.0))) if need>0.0 else "—","tag":"In reach" if known and near else ("Too far" if known else "Unknown"),"tag_color":T.TEAL if known and near else T.RED,
			"tip":("Close enough to fetch every day; households and carriers bring it in." if near else "Too far to fetch every day. More carriers will not bring it closer.") if known else "More carriers cannot make water appear: scouts or a closer look at the map may find a source."})
	var shipments:Array=data.get("deliveries",[])
	for index in mini(shipments.size(),(_refs.deliveries as Array).size()):
		var shipment:Dictionary=shipments[index]
		S.set_row(_refs.deliveries[index],{"label":"%s from %s" % [String(shipment.get("resource","")).capitalize(),String(shipment.get("source_name",""))],"note":String(shipment.get("when","")),"value":S.n(float(shipment.get("quantity",0.0)))})

## The day's terms as the engine gives them.
static func flow_amounts(flow:Dictionary)->Dictionary:
	var out:={}
	for key:String in ["Produced","Taken","Eaten","Spoiled","Keeping","Net"]:out[key]=float(flow.get(key,0))
	return out

## One bar for the day's food: what was eaten, spoiled, lost in drying and
## kept, each a share of everything that left or stayed.
class FlowBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var amounts:Dictionary={}
	func _draw()->void:
		var parts:Array=[]
		for pair:Array in FLOW_CELLS:
			if pair[2]==null:continue
			var amount:=float(amounts.get(pair[0],0.0))
			# A day the stores shrank has no "kept" share.
			if String(pair[0])=="Net":amount=maxf(0.0,amount)
			if amount>0.0:parts.append([amount,pair[2]])
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.10))
		var total:=0.0
		for part:Array in parts:total+=float(part[0])
		if total<=0.0:return
		var x:=0.0
		for part:Array in parts:
			var width:=size.x*float(part[0])/total
			draw_rect(Rect2(x,0,maxf(1.0,width-1.0),size.y),part[1])
			x+=width
