extends VBoxContainer
## Compact line inspector. Values are supplied by the production snapshot;
## controls retain the simulation's existing validation and delegation rules.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Glyph:=preload("res://scripts/hud/product_glyph.gd")
func setup(data:Dictionary)->void:
	name="ProductionLineDetail"
	add_theme_constant_override("separation",12)
	var line:Dictionary=data.line
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",12);add_child(hero)
	var plate:=PanelContainer.new();plate.add_theme_stylebox_override("panel",T.flat(T.TRACK,Color.TRANSPARENT,0,6,10));hero.add_child(plate)
	var glyph:=Glyph.new();glyph.item=String(line.item);plate.add_child(glyph)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.add_child(identity)
	var title:=T.make_label(String(data.title),19,T.INK);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;identity.add_child(title)
	var state:=String(line.get("state","Unknown"))
	var accent:=T.TEAL if state=="Working" else T.GREEN if state=="Target met" else T.AMBER
	identity.add_child(T.make_label(state,12,accent))
	identity.tooltip_text=String(data.get("description",""))
	var managed:=bool(line.get("planner_managed",false))
	var owner:=HBoxContainer.new();owner.add_theme_constant_override("separation",8);add_child(owner)
	var owner_label:=T.make_label("LEADER MANAGED" if managed else "MANUAL OVERRIDE",10,T.TEAL if managed else T.GOLD);owner_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;owner_label.tooltip_text=String(data.get("owner",""));owner.add_child(owner_label)
	if not bool(data.get("staff_enabled",true)):
		owner.add_child(T.make_label("Scheduling off",10,T.AMBER))
	if not managed or not bool(data.get("staff_enabled",true)):_button(owner,"Return to leader",data.get("on_delegate"),"Resume staff scheduling for this line; retain unfinished work.")
	var metrics:=HBoxContainer.new();metrics.add_theme_constant_override("separation",6);add_child(metrics)
	_metric(metrics,str(int(line.get("stock",0))),"IN STORES",T.INK)
	_metric(metrics,"%.2f" % float(line.get("forecast_output_per_day",0)),"FORECAST / DAY",accent)
	_metric(metrics,str(int(line.get("last_output",0))),"LAST DAY",T.TEAL)
	_metric(metrics,"%d%%" % roundi(float(line.get("efficiency",0))*100),"EFFICIENCY",T.GOLD)
	var progress:=clampf(float(line.get("progress_days",0))/maxf(.001,float(line.get("work_per_item",1))),0,1)
	var progress_box:=VBoxContainer.new();progress_box.add_theme_constant_override("separation",4);add_child(progress_box)
	var progress_title:="NEXT ITEM · %d%%" % roundi(progress*100)
	if line.has("exposure_days_required"):progress_title="EXPOSURE · %.1f / %.1f DAYS" % [float(line.get("exposure_days_completed",0)),float(line.exposure_days_required)]
	progress_box.add_child(T.make_label(progress_title,10,T.MUTED))
	_bar(progress_box,progress,accent)
	if line.has("forecast_inspections_per_day"):
		add_child(T.make_label("%.2f inspections/day · yield varies" % float(line.forecast_inspections_per_day),11,T.MUTED))
	var inputs:=VBoxContainer.new();inputs.add_theme_constant_override("separation",6);add_child(inputs)
	inputs.add_child(T.make_label("INPUTS",10,T.GOLD))
	var header:=HBoxContainer.new();inputs.add_child(header)
	_cell(header,"MATERIAL",0,true,T.MUTED);_cell(header,"STOCK",64,false,T.MUTED);_cell(header,"/ ITEM",62,false,T.MUTED);_cell(header,"/ DAY¹",62,false,T.MUTED)
	for input:Dictionary in line.get("materials_status",[]):
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);inputs.add_child(row)
		var shortfall:=maxf(0,float(input.per_item)-float(input.stored))
		var color:=T.RED if shortfall>0 else T.BODY
		row.tooltip_text=("Short %.2f for one item. " % shortfall if shortfall>0 else "Enough stored for one item. ")+"Daily demand is at workshop capacity; competing lines share these stores."
		_cell(row,String(input.name),0,true,color);_cell(row,"%.1f" % float(input.stored),64,false,color);_cell(row,"%.2f" % float(input.per_item),62,false,T.MUTED);_cell(row,"%.2f" % float(input.per_day),62,false,T.MUTED)
	var input_note:=T.make_label("¹ At workshop capacity",9,T.MUTED);inputs.add_child(input_note)
	var controls:=VBoxContainer.new();controls.add_theme_constant_override("separation",8);add_child(controls)
	var target_row:=HBoxContainer.new();target_row.add_theme_constant_override("separation",4);controls.add_child(target_row)
	_cell(target_row,"STOCK TARGET",92,false,T.MUTED)
	for target:int in [0,5,20,100,500]:
		_button(target_row,"∞" if target==0 else str(target),func():data.on_target.call(target),"Continuous output" if target==0 else "Maintain %d in stores" % target,int(line.get("target_stock",0))==target)
	var priority_row:=HBoxContainer.new();priority_row.add_theme_constant_override("separation",4);controls.add_child(priority_row)
	_cell(priority_row,"PRIORITY",92,false,T.MUTED)
	for weight:float in [.5,1.0,2.0,4.0]:
		_button(priority_row,"%.1f×" % weight,func():data.on_priority.call(weight),"Relative share of available workshop work",is_equal_approx(float(line.get("allocation",1)),weight))
	var tip:=T.make_label("Changing a target or priority takes manual control of this line.",10,T.MUTED);tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;controls.add_child(tip)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",6);add_child(footer)
	_button(footer,"Resume" if bool(line.get("paused",false)) else "Pause",data.get("on_pause"),"Toggle production for this line")
	_button(footer,"Retool",data.get("on_retool"),"Change product; review losses before committing")
	_button(footer,"Workforce",data.get("on_labor"),"Review workshop labor allocation")
	_button(footer,"Close line",data.get("on_close"),"Finished stock remains; consumed materials are not refunded.",false,T.RED)
func _button(parent:Node,text:String,callback:Variant,tip:String,selected:bool=false,color:Color=T.BODY)->void:
	var button:=Button.new();button.text=text;button.tooltip_text=tip;button.custom_minimum_size.y=29;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",12);button.add_theme_color_override("font_color",color)
	button.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if selected else T.BUTTON_BG,T.GOLD if selected else T.BORDER_SOFT,1,4,5))
	button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,4,5));parent.add_child(button)
	if callback is Callable and callback.is_valid():button.pressed.connect(callback)
	else:button.disabled=true
func _metric(parent:Node,value:String,caption:String,color:Color)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",T.tile_style());parent.add_child(panel)
	var column:=VBoxContainer.new();panel.add_child(column);column.add_child(T.make_label(value,20,color));column.add_child(T.make_label(caption,8,T.MUTED))
func _cell(parent:Node,text:String,width:float,expand:bool,color:Color)->void:
	var label:=T.make_label(text,11,color);label.custom_minimum_size.x=width
	if expand:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	else:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
func _bar(parent:Node,value:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.custom_minimum_size.y=6;bar.show_percentage=false;bar.value=value*100
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color));parent.add_child(bar)
