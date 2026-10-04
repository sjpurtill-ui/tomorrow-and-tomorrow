extends "res://scripts/hud/home_ledger.gd"
## The Materials dock: what is in store, which way each stock is going and
## why, and what (if anything) slows supply: room in the stores or hauling.
##
## The live refresh (update_block) keeps every node while the page's shape
## holds (the same materials, the same opened row, the same leader and
## choices) and writes the day's words and sparks into them; _fill is the one
## place those words are made, for the first drawing and every refresh.
const Materials:=preload("res://scripts/hud/materials_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")

var _shape:Array=[]
var _city:Label
var _manage:Label
var _supply:Label
var _slows:Label
## The searched land: how well, what it gives cutting and digging, the find odds.
var _land:Label
## Per material row: {voice, trend, spark, details:[Label]}.
var _rows:Array=[]
## Per shipment on the road: {voice, when}.
var _incoming:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",6)
	_shape=shape_of(block)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);add_child(head)
	var leader:Dictionary=data.leader
	if not leader.is_empty():head.add_child(Portrait.picture(leader,80,100))
	var manager:=VBoxContainer.new();manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;manager.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(manager)
	var who:=_who(data)
	_city=T.make_label("",13,T.MUTED);manager.add_child(_city)
	_manage=_voice("",18);manager.add_child(_manage)
	_supply=_line(manager,"",13,T.BODY);_supply.name="SupplySentence"
	if not String(Words.supply(float(data.storage),float(data.capacity),data.hauling).slows).is_empty():_slows=_line(manager,"",13,tone_color("warn"));_slows.name="SupplySlows"
	if not String(data.get("land","")).is_empty():_land=_line(manager,"",13,T.MUTED);_land.name="SearchedLand"
	_rule(self)
	for item:Dictionary in data.rows:
		var refs:={"details":[]}
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row)
		row.add_child(Materials.picture(Materials.material(String(item.key)),140,72))
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(text)
		refs.voice=_voice("",18);text.add_child(refs.voice)
		refs.trend=_line(text,"",13,T.MUTED)
		var spark:=Spark.new();spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(spark);refs.spark=spark
		var open:bool=data.selected==item.key
		_button(row,"Hide" if open else "Details",func():data.on_select.call(String(item.key)),"Where it comes from and what limits it").size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if open:
			for detail:String in item.details:(refs.details as Array).append(_line(self,"",13,T.MUTED))
			if item.details.is_empty():_line(self,"No known place to dig or cut it yet. Scouts and surveys find new sources.",13,T.MUTED)
			var actions:=HBoxContainer.new();add_child(actions);_button(actions,"Show on the map",data.on_map,"Mark known sources on the map")
		_rule(self)
		_rows.append(refs)
	if data.rows.is_empty():_line(self,"Nothing is stored or known yet. Surveys find sources of wood, stone and clay.",13,T.MUTED)
	for shipment:Dictionary in data.incoming:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row);row.add_child(Materials.picture(5,140,64))
		# The words take the row's width; without it a wrapping line folds to one letter.
		var summary:=VBoxContainer.new();summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(summary)
		var refs:={"voice":_voice("",18)}
		summary.add_child(refs.voice)
		refs.when=_line(summary,"",13,T.MUTED)
		_incoming.append(refs)
	if bool(data.can_direct):
		var name_word:=who if not who.is_empty() else "the leader"
		var focus:=String(data.get("focus",""))
		_choices(self,"Ask %s for more hands on" % name_word,[
			{"id":"logistics","label":"Carrying and paths","tip":"More people carry loads and keep the paths open. Other work slows.","on_press":func():data.on_focus.call("logistics")},
			{"id":"","label":"Let %s decide" % name_word,"tip":"The leader spreads the work across what the place needs.","on_press":func():data.on_focus.call("")},
		],"" if bool(data.managed) else (focus if focus=="logistics" else "other"))
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",8);add_child(footer)
	_button(footer,"Show sources on the map",data.on_map,"Mark known wood, stone and clay on the map")
	_button(footer,"Deliveries between places",data.on_trade,"Goods on the road between your settlements")
	_fill()

## The live refresh: the same nodes take the day's words while the page keeps
## its shape; a different shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: its leader, the materials in order with the
## opened one and its lines, whether supply is slowed, the shipments and the
## choices offered.
static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):
		var open:bool=block.get("selected","")==item.key
		rows.append([String(item.key),open,(item.get("details",[]) as Array).size() if open else -1])
	var supply:=Words.supply(float(block.get("storage",0.0)),float(block.get("capacity",0.0)),block.get("hauling"))
	var leader:Dictionary=block.get("leader",{})
	return [Portrait.picture_key(leader) if not leader.is_empty() else [],_who(block),bool(block.get("managed",true)),String(block.get("focus","")),String(supply.slows).is_empty(),String(block.get("land","")).is_empty(),rows,(block.get("incoming",[]) as Array).size(),bool(block.get("can_direct",false))]

static func _who(block:Dictionary)->String:
	var leader:Dictionary=block.get("leader",{})
	return String(leader.get("name","")).get_slice(" ",0) if not leader.is_empty() else ""

## Every word and figure on the page that follows the day.
func _fill()->void:
	var who:=_who(data)
	_put(_city,String(data.city))
	_put(_manage,("%s decides who digs, cuts and carries" % who if not who.is_empty() else "The local leader decides who digs, cuts and carries") if bool(data.managed) else "You asked for extra hands on part of the work")
	var supply:=Words.supply(float(data.storage),float(data.capacity),data.hauling)
	_put(_supply,String(supply.sentence))
	if _slows!=null:_put(_slows,String(supply.slows))
	if _land!=null:
		# The first sentence on the page (how much land is searched); the yield
		# factors and the find odds sit in its tooltip.
		var land:=String(data.get("land",""))
		var cut:=land.find(". ")
		_put(_land,land.left(cut+1) if cut>0 else land)
		_land.mouse_filter=Control.MOUSE_FILTER_PASS
		_land.tooltip_text=land
	for index in mini(_rows.size(),(data.rows as Array).size()):
		var item:Dictionary=data.rows[index]
		var refs:Dictionary=_rows[index]
		var blocked:=""
		for detail:String in item.details:
			if bool(item.get("blocked",false)):blocked=detail.get_slice(": ",1);break
		var reading:=Words.material(float(item.stock),float(item.delivered),float(item.loss),item.points,blocked)
		_put(refs.voice,"%s: %s in store" % [String(item.name),Plain.number(float(item.stock))])
		var since:=(" "+String(reading.since)) if not String(reading.since).is_empty() else ""
		_put(refs.trend,"%s%s: %s." % [trend_word(String(reading.trend)),since,String(reading.cause)],tone_color(String(reading.tone)))
		var spark:Control=refs.spark
		if spark.get("points")!=item.points:spark.set("points",item.points);spark.queue_redraw()
		var details:Array=refs.details
		for d in mini(details.size(),(item.details as Array).size()):
			_put(details[d],String(item.details[d]),tone_color("bad") if bool(item.get("blocked",false)) else T.MUTED)
	for index in mini(_incoming.size(),(data.incoming as Array).size()):
		var shipment:Dictionary=data.incoming[index]
		var refs:Dictionary=_incoming[index]
		_put(refs.voice,"%s %s on the way" % [Plain.number(float(shipment.quantity)),String(shipment.resource).to_lower()])
		var days_left:=maxi(0,ceili(float(shipment.arrival_day)-float(data.day)))
		_put(refs.when,"From %s; arrives %s." % [String(shipment.source_name),"today" if days_left<=0 else "in "+Plain.span_text(days_left)])
