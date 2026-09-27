extends "res://scripts/hud/home_ledger.gd"
## The Materials dock: what is in store, which way each stock is going and
## why, and what (if anything) slows supply: room in the stores or hauling.
const Materials:=preload("res://scripts/hud/materials_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger";add_theme_constant_override("separation",6)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);add_child(head)
	var leader:Dictionary=data.leader
	if not leader.is_empty():head.add_child(Portrait.picture(leader,80,100))
	var manager:=VBoxContainer.new();manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;manager.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(manager)
	var who:=String(leader.get("name","")).get_slice(" ",0) if not leader.is_empty() else ""
	manager.add_child(T.make_label(String(data.city),13,T.MUTED))
	manager.add_child(_voice(("%s decides who digs, cuts and carries" % who if not who.is_empty() else "The local leader decides who digs, cuts and carries") if bool(data.managed) else "You asked for extra hands on part of the work",18))
	var supply:=Words.supply(float(data.storage),float(data.capacity),data.hauling)
	_line(manager,String(supply.sentence),13,T.BODY).name="SupplySentence"
	if not String(supply.slows).is_empty():_line(manager,String(supply.slows),13,tone_color("warn")).name="SupplySlows"
	_rule(self)
	for item:Dictionary in data.rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row)
		row.add_child(Materials.picture(Materials.material(String(item.key)),140,72))
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(text)
		var blocked:=""
		for detail:String in item.details:
			if bool(item.get("blocked",false)):blocked=detail.get_slice(": ",1);break
		var reading:=Words.material(float(item.stock),float(item.delivered),float(item.loss),item.points,blocked)
		text.add_child(_voice("%s: %s in store" % [String(item.name),Plain.number(float(item.stock))],18))
		var since:=(" "+String(reading.since)) if not String(reading.since).is_empty() else ""
		_line(text,"%s%s: %s." % [trend_word(String(reading.trend)),since,String(reading.cause)],13,tone_color(String(reading.tone)))
		var spark:=Spark.new();spark.points=item.points;spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(spark)
		var open:bool=data.selected==item.key
		_button(row,"Hide" if open else "Details",func():data.on_select.call(String(item.key)),"Where it comes from and what limits it").size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if open:
			for detail:String in item.details:_line(self,detail,13,tone_color("bad") if bool(item.get("blocked",false)) else T.MUTED)
			if item.details.is_empty():_line(self,"No known place to dig or cut it yet. Scouts and surveys find new sources.",13,T.MUTED)
			var actions:=HBoxContainer.new();add_child(actions);_button(actions,"Show on the map",data.on_map,"Mark known sources on the map")
		_rule(self)
	if data.rows.is_empty():_line(self,"Nothing is stored or known yet. Surveys find sources of wood, stone and clay.",13,T.MUTED)
	for shipment:Dictionary in data.incoming:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row);row.add_child(Materials.picture(5,140,64))
		var summary:=VBoxContainer.new();row.add_child(summary)
		summary.add_child(_voice("%s %s on the way" % [Plain.number(float(shipment.quantity)),String(shipment.resource).to_lower()],18))
		var days_left:=maxi(0,ceili(float(shipment.arrival_day)-float(data.day)))
		_line(summary,"From %s; arrives %s." % [String(shipment.source_name),"today" if days_left<=0 else "in "+Plain.span_text(days_left)],13,T.MUTED)
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
