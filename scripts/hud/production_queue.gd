extends VBoxContainer
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Art:=preload("res://scripts/hud/production_art.gd")
const P:=preload("res://scripts/persistent_production.gd")
var data:Dictionary
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="IllustratedProductionQueue";add_theme_constant_override("separation",0)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);add_child(header)
	var management:=T.make_label("LEADER MANAGED" if bool(data.get("managed",true)) else "MANUAL SCHEDULING",12,T.GOLD)
	management.tooltip_text=String(data.get("owner",""));management.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(management)
	_button(header,"Manage",data.get("on_manage"),"Leader scheduling and labor allocation")
	_button(header,"+",data.get("on_add"),"Add a production line")
	var reserves:=HBoxContainer.new();reserves.add_theme_constant_override("separation",12);add_child(reserves)
	for resource:String in data.get("stocks",{}):
		var group:=HBoxContainer.new();group.size_flags_horizontal=Control.SIZE_EXPAND_FILL;group.tooltip_text=resource;reserves.add_child(group)
		group.add_child(Art.picture(Art.resource(resource),30,34));group.add_child(T.make_label("%.0f" % float(data.stocks[resource]),12,T.BODY))
	_rule(self)
	var rank:=0
	for line:Dictionary in data.get("lines",[]):
		rank+=1;_line(line,rank)
	if rank==0:
		var empty:=T.make_label("Your leader schedules work as needs and recipes become available.",12,T.MUTED);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(empty)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",12);add_child(footer)
	var count:=T.make_label("%d / %d lines" % [int(data.get("total_lines",rank)),int(data.get("capacity",rank))],11,T.MUTED);count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(count)
	_button(footer,"Output history",data.get("on_history"),"Actual completed output")
func _line(line:Dictionary,rank:int)->void:
	var id:=int(line.id)
	var selected:=int(data.get("selected",-1))==id
	var shell:=PanelContainer.new();shell.name="Line%d" % id
	var style:=T.flat(Color.TRANSPARENT,T.GOLD if selected else T.BORDER_SOFT,1,0,7)
	style.border_width_left=1 if selected else 0;style.border_width_right=1 if selected else 0;style.border_width_top=1 if selected else 0
	shell.add_theme_stylebox_override("panel",style);add_child(shell)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",7);shell.add_child(column)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",9);column.add_child(row)
	var number:=T.make_label(str(rank),12,T.MUTED);number.custom_minimum_size.x=16;number.tooltip_text="Display position; work is allocated by relative priority.";row.add_child(number)
	var product:=VBoxContainer.new();product.custom_minimum_size.x=164;row.add_child(product)
	var name_label:=T.make_label(P.product_name(String(line.item)),12,T.INK);name_label.custom_minimum_size.x=164;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.tooltip_text=name_label.text;product.add_child(name_label)
	product.add_child(Art.picture(Art.product(String(line.item)),164,76))
	var work:=VBoxContainer.new();work.size_flags_horizontal=Control.SIZE_EXPAND_FILL;work.size_flags_vertical=Control.SIZE_SHRINK_CENTER;work.add_theme_constant_override("separation",5);row.add_child(work)
	var slots:=HBoxContainer.new();slots.add_theme_constant_override("separation",2);work.add_child(slots)
	var share:=clampf(float(line.get("share",0)),0,1)
	slots.tooltip_text="%.1f%% of allocated workshop work. Each marker represents 10%%; not a worker count." % (share*100)
	for i in 10:
		var slot:=ProgressBar.new();slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slot.custom_minimum_size=Vector2(10,18);slot.show_percentage=false;slot.value=clampf(share*10-i,0,1)*100
		slot.add_theme_stylebox_override("background",T.flat(T.TRACK,T.BORDER_SOFT,1));slot.add_theme_stylebox_override("fill",T.flat(T.GREEN));slot.mouse_filter=Control.MOUSE_FILTER_IGNORE;slots.add_child(slot)
	var efficiency:=HBoxContainer.new();work.add_child(efficiency)
	_bar(efficiency,float(line.get("efficiency",0)),T.GREEN)
	efficiency.add_child(T.make_label("%d%%" % roundi(float(line.get("efficiency",0))*100),10,T.MUTED));efficiency.tooltip_text="Production efficiency"
	var state:=String(line.get("state","Batch"))
	var status_color:=T.TEAL if state=="Working" else T.GREEN if state=="Target met" else T.RED
	var status:=T.make_label(state,10,status_color);status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;status.tooltip_text=state;work.add_child(status)
	var output:=VBoxContainer.new();output.custom_minimum_size.x=116;output.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(output)
	var rate:=T.make_label("%.2f / day" % float(line.get("forecast_output_per_day",0)),18,status_color);rate.tooltip_text="Forecast with current inputs, not completed output";output.add_child(rate)
	if line.has("forecast_inspections_per_day"):rate.text="%.2f checks/d" % float(line.forecast_inspections_per_day)
	var stock:=T.make_label("%d / %s" % [int(line.get("stock",0)),str(int(line.get("target_stock",0))) if int(line.get("target_stock",0))>0 else "∞"],11,T.MUTED);stock.tooltip_text="Current stores / stock target";output.add_child(stock)
	var materials:=HBoxContainer.new();materials.add_theme_constant_override("separation",3);output.add_child(materials)
	var inputs:Array=line.get("materials_status",[])
	for index in mini(3,inputs.size()):
		var input:Dictionary=inputs[index]
		var group:=HBoxContainer.new();group.add_theme_constant_override("separation",0);materials.add_child(group)
		group.add_child(Art.picture(Art.resource(String(input.get("resource",input.name))),18,20))
		var missing:=maxf(0,float(input.per_item)-float(input.stored))
		group.add_child(T.make_label("−%.1f" % missing if missing>0 else "%.1f" % float(input.per_item),9,T.RED if missing>0 else T.MUTED));group.tooltip_text=String(input.name)+(" short for one item" if missing>0 else " per item")
	if inputs.size()>3:materials.add_child(T.make_label("+%d" % (inputs.size()-3),9,T.MUTED))
	var controls:=HBoxContainer.new();controls.size_flags_vertical=Control.SIZE_SHRINK_CENTER;controls.add_theme_constant_override("separation",3);row.add_child(controls)
	var owned:=T.make_label("L" if bool(line.get("planner_managed",false)) else "M",10,T.GOLD);owned.tooltip_text="Leader managed" if owned.text=="L" else "Manual override";controls.add_child(owned)
	if bool(line.get("persistent",false)):_button(controls,"▶" if bool(line.get("paused",false)) else "Ⅱ",func():data.on_action.call(id,"pause",0),"Resume" if bool(line.get("paused",false)) else "Pause")
	_button(controls,"▴" if selected else "▾",func():data.on_select.call(id),"Expand line controls")
	if selected:
		_rule(column)
		if bool(line.get("persistent",false)):_expanded(column,line)
		else:_button(column,"Inspect batch",func():data.on_detail.call(id),"Batch progress and cancellation")
func _expanded(parent:Node,line:Dictionary)->void:
	var id:=int(line.id)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);parent.add_child(row)
	row.add_child(T.make_label("Stock target",11,T.MUTED))
	var target:=SpinBox.new();target.min_value=0;target.max_value=1000000000;target.value=int(line.get("target_stock",0));target.custom_minimum_size.x=100;target.tooltip_text="0 = continuous production";row.add_child(target)
	_button(row,"Set",func():data.on_action.call(id,"target",int(target.value)),"Take manual control of this target")
	row.add_child(T.make_label("Priority",11,T.MUTED))
	for weight:float in [.5,1.0,2.0,4.0]:_button(row,"%.1f×" % weight,func():data.on_action.call(id,"priority",weight),"Relative work allocation; takes manual control",is_equal_approx(float(line.get("allocation",1)),weight))
	_button(row,"↶",func():data.on_action.call(id,"delegate",0),"Return this line to leader management")
	_button(row,"…",func():data.on_detail.call(id),"All inputs, retooling, workforce and close line")
	var progress:=HBoxContainer.new();parent.add_child(progress)
	_bar(progress,clampf(float(line.get("progress_days",0))/maxf(.001,float(line.get("work_per_item",1))),0,1),T.TEAL)
	progress.add_child(T.make_label("Next item · last day %d made" % int(line.get("last_output",0)),10,T.MUTED))
func _button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->void:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,28);b.add_theme_font_size_override("font_size",11);b.add_theme_color_override("font_color",T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if active else Color.TRANSPARENT,T.GOLD if active else T.BORDER_SOFT,1,0,5));b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,0,5));parent.add_child(b)
	if callback is Callable and callback.is_valid():b.pressed.connect(callback)
	else:b.disabled=true
func _bar(parent:Node,ratio:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.value=ratio*100;bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color));parent.add_child(bar)
func _rule(parent:Node)->void:
	var rule:=HSeparator.new();rule.add_theme_color_override("color",T.BORDER_SOFT);parent.add_child(rule)
