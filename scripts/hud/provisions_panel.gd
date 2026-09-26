extends "res://scripts/hud/production_queue.gd"
const FoodArt:=preload("res://scripts/hud/provisions_art.gd")
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;add_theme_constant_override("separation",4)
	var head:=HBoxContainer.new();add_child(head)
	var owner:=T.make_label("LEADER MANAGED" if bool(data.managed) else "DIRECTED PRIORITIES",12,T.GOLD);owner.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(owner);head.add_child(T.make_label(String(data.city),12,T.BODY))
	var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",12);add_child(summary)
	var water:Dictionary=data.water;var reported:=water.has("required_today")
	var coverage:=clampf(float(water.get("intake_ratio",0)),0,1)
	_summary(summary,0,"%.1f days" % float(data.food_days),"Food reserve",T.INK)
	_summary(summary,4,"%d%%" % roundi(coverage*100) if reported else "—","Water needs met" if reported else "Report pending",T.GREEN if coverage>=.98 else T.MUTED)
	_rule(self)
	var outlook:=HBoxContainer.new();add_child(outlook)
	var forecast:Dictionary=data.forecast90
	var shortage:=int(forecast.get("first_shortage_day",-1))
	var forecast_label:=T.make_label("FORECAST · shortage in %d days" % shortage if shortage>0 else "FORECAST · no shortage in 90 days" if not forecast.is_empty() else "FORECAST · awaiting report",12,T.RED if shortage>0 else T.MUTED);forecast_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;outlook.add_child(forecast_label)
	_button(outlook,"History",data.on_history,"Recorded reserve history")
	for horizon in [30,90]:
		var point:Dictionary=data.get("forecast%d" % horizon,{})
		if point.is_empty():continue
		var row:=HBoxContainer.new();add_child(row);row.add_child(T.make_label("+%d days" % horizon,11,T.MUTED))
		_bar(row,clampf(float(point.get("ending_days",0))/maxf(1,float(data.food_days)),0,1),T.GREEN)
		var label:=T.make_label("%.1f reserve days" % float(point.get("ending_days",0)),11,T.BODY);row.add_child(label)
		row.tooltip_text="Forecast checkpoint, not an observed value. Bar is relative to today's reserve days."
	_rule(self)
	var columns:=HBoxContainer.new();add_child(columns)
	var stores:=T.make_label("STORES",10,T.MUTED);stores.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(stores);var rations:=T.make_label("RATIONS",10,T.MUTED);rations.custom_minimum_size.x=100;columns.add_child(rations)
	var lost:=T.make_label("LOST / DAY",10,T.MUTED);lost.custom_minimum_size.x=95;columns.add_child(lost)
	var spacer:=Control.new();spacer.custom_minimum_size.x=28;columns.add_child(spacer);columns.add_theme_constant_override("separation",12)
	for food:Dictionary in data.rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row)
		row.add_child(FoodArt.picture(FoodArt.food(String(food.name)),200,90))
		var label:=T.make_label(String(food.name),16,T.INK);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
		var stock:=T.make_label("%.0f" % float(food.stock),16,T.BODY);stock.custom_minimum_size.x=100;row.add_child(stock)
		var loss:=T.make_label("−%.1f" % float(food.lost),13,T.RED if float(food.lost)>0 else T.MUTED);loss.custom_minimum_size.x=95;row.add_child(loss)
		_button(row,"▴" if data.selected==food.name else "▾",func():data.on_select.call(String(food.name)),"Inspect food stores")
		(row.get_child(row.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if data.selected==food.name:
			var detail:=HBoxContainer.new();add_child(detail)
			var note:=T.make_label(String(food.detail),11,T.MUTED);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_child(note)
			_button(detail,"Sources & handling",data.on_sources,"Known sources, preparation and preservation")
		_rule(self)
	var flow:=HBoxContainer.new();flow.add_theme_constant_override("separation",14);add_child(flow)
	for kind:String in data.flow:
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;flow.add_child(cell)
		var value:=float(data.flow[kind]);var signed:=0.0 if is_zero_approx(value) else value if kind in ["Net","Produced"] else -value
		cell.add_child(T.make_label("%+.1f" % signed,18,T.GREEN if signed>0 else T.RED if signed<0 else T.MUTED));cell.add_child(T.make_label(kind+" / day",10,T.MUTED))
	var access:=HBoxContainer.new();add_child(access);access.add_child(FoodArt.picture(4,80,40));_bar(access,coverage,T.GREEN)
	_button(access,"Water access",data.on_water,"Source reach, collection and leader direction")
	var footer:=HBoxContainer.new();add_child(footer);_button(footer,"Leader priorities ▾",data.on_toggle,"Optional direction; routine work remains with the leader");_button(footer,"Deliveries",data.on_trade,"Routes and city shipments")
	if bool(data.priorities) and bool(data.can_direct):
		var controls:=HBoxContainer.new();add_child(controls)
		_button(controls,"Food",func():data.on_focus.call("provisions"),"Prioritize food supply")
		_button(controls,"Water",func():data.on_focus.call("water"),"Prioritize water work")
		_button(controls,"Return to leader",func():data.on_focus.call(""),"Restore automatic priorities")

func _summary(parent:Node,index:int,value:String,caption:String,color:Color)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",T.flat(Color.TRANSPARENT,T.BORDER_SOFT,1,0,8));parent.add_child(panel)
	var row:=HBoxContainer.new();panel.add_child(row);row.add_child(FoodArt.picture(index,105,65))
	var stack:=VBoxContainer.new();stack.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(stack)
	var label:=T.make_label(value,28,color);label.add_theme_font_override("font",preload("res://scripts/hud/hud_tokens.gd").voice_font());stack.add_child(label);stack.add_child(T.make_label(caption,12,T.MUTED))
