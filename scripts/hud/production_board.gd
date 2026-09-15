extends VBoxContainer
## Compact workshop ledger. Progress is work, stocks are present inventory,
## receipts are actual additions; never imply these are the same measurement.
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
var view:Dictionary={}
var mode:=0
func setup(data:Dictionary)->void:
	view=data
	mode=int(view.get("view_state",{}).get("mode",0))
	_rebuild()
func _label(text:String,font_size:int,color:Color)->Label:
	var label:=T.make_label(text,font_size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label
func _rebuild()->void:
	for child:Node in get_children():remove_child(child);child.queue_free()
	add_theme_constant_override("separation",8)
	var tabs:=HBoxContainer.new();add_child(tabs)
	for index:int in 3:
		var button:=Button.new()
		button.text=["IN PRODUCTION","FINISHED","ATTENTION"][index]
		button.add_theme_font_size_override("font_size",11)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.toggle_mode=true;button.button_pressed=mode==index
		button.pressed.connect(func():mode=index;view.get("view_state",{})["mode"]=index;_rebuild())
		tabs.add_child(button)
	if mode==1:
		add_child(_label("ADDED TO STORES · LATEST 30 DAYS",10,T.GOLD))
		var totals:Dictionary={}
		for receipt:Dictionary in view.get("receipts",[]):
			if int(receipt.day)<int(view.get("day",0))-29:continue
			var key:=String(receipt.kind)+":"+String(receipt.resource)
			if not totals.has(key):totals[key]=receipt.duplicate(true);totals[key].quantity=0.0
			totals[key].quantity=float(totals[key].quantity)+float(receipt.quantity)
		for receipt:Dictionary in totals.values():_receipt(receipt)
		if totals.is_empty():add_child(_label("No completed output recorded yet. Existing stock is not counted as new production.",12,T.MUTED))
		add_child(_label("Actual additions, including co-products; repairs are marked separately. Issued or consumed goods remain in this record. Up to 256 daily product entries are retained.",10,T.MUTED))
		return
	var count:=0
	for line:Dictionary in view.get("lines",[]):
		var state:=String(line.get("state","Batch"))
		if mode==2 and state in ["Working","Target met","Batch"]:continue
		_line(line);count+=1
	if count==0:add_child(_label("No blocked lines." if mode==2 else "No production lines assigned. Your workshop manager reviews demand each day.",12,T.MUTED))
func _icon(item:String,kind:String,resource:String="")->Control:
	var icon:=preload("res://scripts/hud/product_glyph.gd").new()
	icon.item=item;icon.resource=resource
	icon.tooltip_text=P.product_name(item)+" · "+kind
	return icon
func _line(line:Dictionary)->void:
	var state:=String(line.get("state","Batch"))
	var accent:Color=T.GREEN if state=="Target met" else T.TEAL if state in ["Working","Batch"] else T.AMBER
	var button:=Button.new();button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	var style:=T.flat(T.ROW_BG,T.BORDER_SOFT,0,0);style.border_width_bottom=1
	button.add_theme_stylebox_override("normal",style)
	button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,accent,1,4))
	add_child(button)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left=8;row.offset_right=-8;row.offset_top=8;row.offset_bottom=-8
	row.add_child(_icon(String(line.item),String(line.get("job_type","production"))))
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)
	var title:=_label(P.product_name(String(line.item)),14,T.INK);body.add_child(title)
	var managed:=bool(line.get("planner_managed",false))
	body.add_child(_label(("STAFF · " if managed else "YOUR ORDER · ")+state,10,accent))
	var progress:=ProgressBar.new();progress.custom_minimum_size.y=5;progress.show_percentage=false
	progress.value=clampf(float(line.get("progress_days",0))/maxf(.001,float(line.get("work_per_item",1)))*100,0,100)
	if state=="Target met":progress.value=100
	progress.add_theme_stylebox_override("background",T.flat(T.TRACK,T.TRACK,0,2))
	progress.add_theme_stylebox_override("fill",T.flat(accent,accent,0,2));body.add_child(progress)
	var forecast:="%.2f/day forecast" % float(line.get("forecast_output_per_day",0))
	if line.has("forecast_inspections_per_day"):forecast="%.2f/day inspected · yield varies" % float(line.forecast_inspections_per_day)
	body.add_child(_label("Stock target filled" if state=="Target met" else "%.0f%% next item · %s" % [progress.value,forecast],10,T.MUTED))
	var stock:=VBoxContainer.new();stock.custom_minimum_size.x=62;row.add_child(stock)
	stock.add_child(_label(str(int(line.get("stock",0))),22,T.INK))
	stock.add_child(_label("IN STORES",9,T.MUTED))
	stock.add_child(_label("goal %d" % int(line.get("target_stock",0)) if int(line.get("target_stock",0))>0 else "continuous" if bool(line.get("persistent",false)) else "%d/%d made" % [int(line.get("completed",0)),int(line.get("ordered",0))],9,T.MUTED))
	button.custom_minimum_size.y=88
	body.minimum_size_changed.connect(func():button.custom_minimum_size.y=maxf(88,body.get_combined_minimum_size().y+16))
	for control:Node in row.find_children("*","Control",true,false):control.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.pressed.connect(func():
		var callback:Callable=view.get("on_open",Callable())
		if callback.is_valid():callback.call(int(line.id)))
	button.tooltip_text=state+" · Select to inspect inputs or override this order."
func _receipt(receipt:Dictionary)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);add_child(row)
	row.add_child(_icon(String(receipt.item),String(receipt.kind),String(receipt.resource) if receipt.kind=="civilian" else ""))
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)
	body.add_child(_label(String(receipt.resource) if receipt.kind=="civilian" else P.product_name(String(receipt.item)),13,T.INK))
	var day:=int(receipt.day)
	body.add_child(_label(("Repaired · " if receipt.kind=="repair" else "Last output · ")+"Year %d, Day %d" % [day/365+1,day%365+1],10,T.MUTED))
	row.add_child(T.make_label("+%.1f" % float(receipt.quantity),20,T.GREEN))
