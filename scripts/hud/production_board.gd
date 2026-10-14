extends VBoxContainer
## Compact workshop ledger. Progress is work, stocks are present inventory,
## receipts are actual additions; never imply these are the same measurement.
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
var view:Dictionary={}
var mode:=0
const HISTORY_PAGE_SIZE:=6
var history_state:={"query":"","page":0,"selected":"","reading":true}
var history_totals:Array=[]
var history_search:LineEdit
var history_choices:VBoxContainer
var history_spread:BoxContainer
var history_index:VBoxContainer
var history_reader:VBoxContainer
var history_detail:VBoxContainer
var history_back:Button
var history_return:Button
var history_counter:Label
var history_previous:Button
var history_next:Button
func setup(data:Dictionary)->void:
	view=data
	mode=int(view.get("view_state",{}).get("mode",1 if view.get("history_only",false) else 0))
	if not resized.is_connected(_history_layout):resized.connect(_history_layout)
	_rebuild()
func _label(text:String,font_size:int,color:Color)->Label:
	var label:=T.make_label(text,font_size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label
func _rebuild()->void:
	for child:Node in get_children():remove_child(child);child.queue_free()
	add_theme_constant_override("separation",8)
	var tabs:=HBoxContainer.new();add_child(tabs);tabs.visible=not bool(view.get("history_only",false))
	for index:int in 3:
		var button:=Button.new()
		button.text=["IN PRODUCTION","FINISHED","ATTENTION"][index]
		button.add_theme_font_size_override("font_size",12)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.toggle_mode=true;button.button_pressed=mode==index
		button.pressed.connect(func():mode=index;view.get("view_state",{})["mode"]=index;_rebuild())
		tabs.add_child(button)
	if mode==1:
		_build_history()
		return
	var count:=0
	for line:Dictionary in view.get("lines",[]):
		var state:=String(line.get("state","Batch"))
		if mode==2 and state in ["Working","Target met","Batch"]:continue
		_line(line);count+=1
	if count==0:add_child(_label("No blocked lines." if mode==2 else "No production lines assigned. Your workshop manager reviews demand each day.",12,T.MUTED))
func _icon(item:String,kind:String,resource:String="")->Control:
	if preload("res://scripts/hud/early_civ_art.gd").active() and item in ["spear","woven_cloth","bow","transport_cart"]:
		var art:=preload("res://scripts/hud/production_art.gd")
		var picture:=art.picture(art.product(item),56,44)
		picture.tooltip_text=P.product_name(item)+" · "+kind
		return picture
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
	body.add_child(_label(String(receipt.resource) if receipt.kind=="civilian" else P.product_name(String(receipt.item)),16,T.INK))
	var day:=int(receipt.day)
	body.add_child(_label(("Repaired · " if receipt.kind=="repair" else "Last output · ")+"Year %d, Day %d" % [day/365+1,day%365+1],14,T.MUTED))
	row.add_child(T.make_label(str(snappedf(float(receipt.quantity),.001)),20,T.GREEN))

## History reads the same cumulative model totals; only one receipt's controls
## exist at a time. Updating the block keeps search, page and selected identity.
func update_block(data:Dictionary)->bool:
	if mode!=1 or not bool(data.get("history_only",false)):return false
	view=data
	_refresh_history()
	return true

func _history_button(caption:String,tip:String,action:Callable)->Button:
	var button:=Button.new();button.text=caption;button.tooltip_text=tip
	T.apply_button_style(button);button.pressed.connect(action)
	return button

func _build_history()->void:
	add_child(_label("Finished in our settlements",22,T.INK))
	add_child(_label("Read what each place has made or repaired since its records began.",14,T.MUTED))
	history_spread=BoxContainer.new();history_spread.add_theme_constant_override("separation",20);add_child(history_spread)
	history_index=VBoxContainer.new();history_index.add_theme_constant_override("separation",6);history_spread.add_child(history_index)
	history_return=_history_button("Back to selected total","Keep this search and page",func():history_state.reading=true;_history_layout());history_index.add_child(history_return)
	history_search=LineEdit.new();history_search.name="HistorySearch";history_search.placeholder_text="Find a place, product or repair";history_search.custom_minimum_size.y=40;history_search.text=String(history_state.query);history_index.add_child(history_search)
	history_search.text_changed.connect(func(words:String):history_state.query=words;history_state.page=0;history_state.selected="";history_state.reading=false;_refresh_history())
	history_choices=VBoxContainer.new();history_choices.name="HistoryChoices";history_choices.add_theme_constant_override("separation",5);history_index.add_child(history_choices)
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",6);history_index.add_child(navigation)
	history_previous=_history_button("‹","Previous six totals",func():history_state.page=int(history_state.page)-1;history_state.selected="";_refresh_history());navigation.add_child(history_previous)
	history_counter=_label("",14,T.MUTED);history_counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;navigation.add_child(history_counter)
	history_next=_history_button("›","Next six totals",func():history_state.page=int(history_state.page)+1;history_state.selected="";_refresh_history());navigation.add_child(history_next)
	history_reader=VBoxContainer.new();history_reader.name="HistoryReader";history_reader.size_flags_horizontal=SIZE_EXPAND_FILL;history_reader.add_theme_constant_override("separation",12);history_spread.add_child(history_reader)
	history_back=_history_button("Choose a place or product","Return to all totals without losing this reading",func():history_state.reading=false;_history_layout());history_reader.add_child(history_back)
	history_detail=VBoxContainer.new();history_detail.name="HistoryDetail";history_detail.add_theme_constant_override("separation",10);history_reader.add_child(history_detail)
	_refresh_history()

func _history_key(receipt:Dictionary)->String:
	return JSON.stringify([receipt.get("settlement_id",""),receipt.kind,receipt.resource])
func _history_city(receipt:Dictionary)->String:
	var city:=String(receipt.get("settlement_name",""))
	return "Settlement not recorded" if city.is_empty() else city
func _history_product(receipt:Dictionary)->String:
	return String(receipt.resource) if receipt.kind in ["civilian","household"] else P.product_name(String(receipt.item))

func _refresh_history()->void:
	if not is_instance_valid(history_choices):return
	history_totals=preload("res://scripts/workshop_steward.gd").history_totals(view.get("receipts",[]),view.get("totals",{}))
	history_totals.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _history_city(a)+String(a.resource)+String(a.kind)<_history_city(b)+String(b.resource)+String(b.kind))
	var query:=String(history_state.query).strip_edges().to_lower()
	var matching:Array=history_totals.filter(func(receipt:Dictionary)->bool:return query.is_empty() or (_history_city(receipt)+" "+_history_product(receipt)+" "+("repaired" if receipt.kind=="repair" else "made")).to_lower().contains(query))
	var page:=clampi(int(history_state.page),0,maxi(0,ceili(float(matching.size())/HISTORY_PAGE_SIZE)-1));history_state.page=page
	var selected:Dictionary={}
	for receipt:Dictionary in matching:
		if _history_key(receipt)==String(history_state.selected):selected=receipt;break
	if selected.is_empty() and not matching.is_empty():selected=matching[page*HISTORY_PAGE_SIZE]
	history_state.selected=_history_key(selected) if not selected.is_empty() else ""
	for child in history_choices.get_children():history_choices.remove_child(child);child.queue_free()
	for receipt:Dictionary in matching.slice(page*HISTORY_PAGE_SIZE,(page+1)*HISTORY_PAGE_SIZE):
		var key:=_history_key(receipt)
		var amount:=str(snappedf(float(receipt.quantity),.001))
		var caption:="%s · %s\n%s %s" % [_history_city(receipt),_history_product(receipt),"Repaired" if receipt.kind=="repair" else "Made",amount]
		var choice:=_history_button(caption,caption,func():history_state.selected=key;history_state.reading=true;_refresh_history())
		choice.name="History_"+key.sha256_text().substr(0,16);choice.custom_minimum_size.y=52;choice.alignment=HORIZONTAL_ALIGNMENT_LEFT;choice.clip_text=true;choice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		choice.toggle_mode=true;choice.set_pressed_no_signal(key==String(history_state.selected));history_choices.add_child(choice)
	if matching.is_empty():history_choices.add_child(_label("No totals match this search." if not query.is_empty() else "The first finished work will be recorded here.",16,T.MUTED))
	history_counter.text="%d–%d of %d" % [page*HISTORY_PAGE_SIZE+1,mini((page+1)*HISTORY_PAGE_SIZE,matching.size()),matching.size()] if not matching.is_empty() else "No matching totals"
	history_previous.disabled=page==0;history_next.disabled=(page+1)*HISTORY_PAGE_SIZE>=matching.size()
	history_previous.get_parent().visible=history_totals.size()>HISTORY_PAGE_SIZE and not matching.is_empty()
	history_search.visible=history_totals.size()>1 or not query.is_empty()
	for child in history_detail.get_children():history_detail.remove_child(child);child.queue_free()
	if not selected.is_empty():
		var title:=HBoxContainer.new();title.add_theme_constant_override("separation",12);history_detail.add_child(title)
		title.add_child(_icon(String(selected.item),String(selected.kind),String(selected.resource)))
		var identity:=VBoxContainer.new();identity.size_flags_horizontal=SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",4);title.add_child(identity)
		identity.add_child(_label(_history_product(selected),22,T.INK))
		identity.add_child(_label(_history_city(selected),16,T.MUTED))
		history_detail.add_child(_label(("Repaired " if selected.kind=="repair" else "Made ")+str(snappedf(float(selected.quantity),.001)),24,T.INK))
		var day:=int(selected.day)
		history_detail.add_child(_label(("Last repair · " if selected.kind=="repair" else "Last output · ")+"Year %d, Day %d" % [day/365+1,day%365+1],14,T.MUTED))
		history_detail.add_child(_label("Repairs are counted separately from newly made equipment." if selected.kind=="repair" else "Includes goods since issued or consumed. This is recorded output, not the amount in stores.",16,T.BODY))
		history_detail.add_child(_label("Totals begin with retained records; earlier unrecorded production cannot be reconstructed.",14,T.MUTED))
	_history_layout()

func _history_layout()->void:
	if not is_instance_valid(history_spread):return
	var narrow:=size.x>0 and size.x<700
	history_spread.vertical=narrow
	history_index.custom_minimum_size.x=0 if narrow else 280
	history_index.size_flags_horizontal=SIZE_EXPAND_FILL if narrow else SIZE_FILL
	var selected:=not String(history_state.selected).is_empty()
	var reading:=bool(history_state.reading) and selected
	history_index.visible=history_totals.size()>1 and (not narrow or not reading) or not selected
	history_reader.visible=selected and (not narrow or reading or history_totals.size()==1)
	history_back.visible=narrow and history_totals.size()>1
	history_return.visible=narrow and selected
