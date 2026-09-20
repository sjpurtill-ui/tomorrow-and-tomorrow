extends "res://scripts/hud/production_queue.gd"
const Materials:=preload("res://scripts/hud/materials_art.gd")
static var portraits:Texture2D
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;add_theme_constant_override("separation",5)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);add_child(head)
	var leader:Dictionary=data.leader
	if not leader.is_empty():
		if portraits==null:
			var path:="res://assets/portraits/founding_leaders.png"
			portraits=load(path) as Texture2D if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
		var portrait:=TextureRect.new();var atlas:=AtlasTexture.new();atlas.atlas=portraits
		var cell:=Vector2(atlas.atlas.get_width()/5.0,atlas.atlas.get_height());atlas.region=Rect2(Vector2(posmod(int(leader.get("id",0)),5)*cell.x,0),cell)
		portrait.texture=atlas;portrait.custom_minimum_size=Vector2(90,100);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;portrait.tooltip_text="Leader portrait illustration";head.add_child(portrait)
	var manager:=VBoxContainer.new();manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;manager.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(manager)
	manager.add_child(T.make_label(String(data.city),12,T.MUTED));manager.add_child(_serif(String(leader.get("name","Founding camp")),18));manager.add_child(T.make_label("Leader managed" if bool(data.managed) else "Directed priorities",12,T.MUTED))
	_gauge(head,"Storage",float(data.storage)/float(data.capacity) if float(data.capacity)>0 else -1,"%.1f / %.1f bulk" % [float(data.storage),float(data.capacity)])
	_gauge(head,"Hauling",float(data.hauling) if data.hauling!=null else -1,"Share of extracted bulk delivered")
	_rule(self)
	var labels:=HBoxContainer.new();labels.add_theme_constant_override("separation",12);add_child(labels)
	var first:=T.make_label("STORES",10,T.MUTED);first.size_flags_horizontal=Control.SIZE_EXPAND_FILL;labels.add_child(first)
	for spec in [["IN STOCK",75],["DELIVERED / DAY",110],["HISTORY",95],["",28]]:
		var label:=T.make_label(spec[0],10,T.MUTED);label.custom_minimum_size.x=spec[1];labels.add_child(label)
	for item:Dictionary in data.rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row)
		row.add_child(Materials.picture(Materials.material(String(item.key)),160,83))
		var label:=_serif(String(item.name),17);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.tooltip_text=String(item.name);row.add_child(label)
		var stock:=_serif("%.0f" % float(item.stock),21);stock.custom_minimum_size.x=75;row.add_child(stock)
		var rate:=_serif("+%.1f" % float(item.delivered),20);rate.custom_minimum_size.x=110;rate.add_theme_color_override("font_color",T.GREEN if float(item.delivered)>0 else T.MUTED);rate.tooltip_text="Delivered from known extraction sites today; not net stock change";row.add_child(rate)
		var spark:=Spark.new();spark.points=item.points;spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(spark)
		_button(row,"▴" if data.selected==item.key else "›",func():data.on_select.call(String(item.key)),"Sources and supply constraints")
		for child in row.get_children():child.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if data.selected==item.key:
			for detail:String in item.details:
				var note:=T.make_label(detail,12,T.RED if bool(item.get("blocked",false)) else T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)
			if item.details.is_empty():add_child(T.make_label("No known extraction site",12,T.MUTED))
			if float(item.loss)>0:add_child(T.make_label("Storage loss · %.2f / day" % float(item.loss),12,T.RED))
			var actions:=HBoxContainer.new();add_child(actions);_button(actions,"Resource map",data.on_map,"Toggle known resources on the map");_button(actions,"Material details",data.on_atlas,"Open known materials atlas")
			if bool(data.can_direct):_button(actions,"Logistics",func():data.on_focus.call("logistics"),"Ask leader to prioritize local logistics")
		_rule(self)
	if data.rows.is_empty():add_child(T.make_label("No stored or recognized materials yet.",13,T.MUTED))
	for shipment:Dictionary in data.incoming:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row);row.add_child(Materials.picture(5,145,65))
		var summary:=VBoxContainer.new();row.add_child(summary);summary.add_child(T.make_label("Incoming delivery",11,T.MUTED));summary.add_child(_serif("%s · +%.1f" % [String(shipment.resource),float(shipment.quantity)],18));summary.add_child(T.make_label("From %s · %d days" % [String(shipment.source_name),maxi(0,ceili(float(shipment.arrival_day)-float(data.day)))],12,T.MUTED))
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",10);add_child(footer)
	_button(footer,"Resource map",data.on_map,"Toggle recognized deposits");_button(footer,"Leader priorities ▾",data.on_toggle,"Optional direction");_button(footer,"Deliveries",data.on_trade,"Routes and shipments")
	if bool(data.priorities) and bool(data.can_direct):
		var choices:=HBoxContainer.new();add_child(choices);_button(choices,"Logistics",func():data.on_focus.call("logistics"),"Prioritize hauling");_button(choices,"Return to leader",func():data.on_focus.call(""),"Restore automatic management")
func _serif(value:String,font_size:int)->Label:
	var label:=T.make_label(value,font_size,T.INK);var font:=SystemFont.new();font.font_names=PackedStringArray(["Georgia"]);label.add_theme_font_override("font",font);return label
func _gauge(parent:Node,title:String,ratio:float,tip:String)->void:
	var box:=VBoxContainer.new();box.custom_minimum_size.x=125;box.size_flags_vertical=Control.SIZE_SHRINK_CENTER;box.tooltip_text=tip;parent.add_child(box)
	box.add_child(T.make_label(title,12,T.BODY));box.add_child(_serif("%d%%" % roundi(ratio*100) if ratio>=0 else "—",22));_bar(box,clampf(ratio,0,1),T.GREEN)
