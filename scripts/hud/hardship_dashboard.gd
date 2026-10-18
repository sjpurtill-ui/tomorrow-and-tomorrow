extends VBoxContainer
## A bounded event browser; the ledger is read-only and the chosen event stays
## selected when a new day or incident arrives.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const PAGE_SIZE:=6
var data:Dictionary={}
var selected_id:=""
var year_filter:=-1
var page:=0
var _metrics:GridContainer
var _values:Array[Label]=[]
var _timeline:HBoxContainer
var _columns:BoxContainer
var _events:VBoxContainer
var _buttons:Array[Button]=[]
var _range:Label
var _newer:Button
var _older:Button
var _title:Label
var _sub:Label
var _losses:GridContainer
var _account:Label
var _action:Button
var _empty:Label
var _key:=""

func setup(block:Dictionary)->void:
	name="HardshipDashboard";theme=T.control_theme();size_flags_horizontal=SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_label(self,"Last ten years",14,T.MUTED)
	_metrics=GridContainer.new();_metrics.columns=5;add_child(_metrics)
	for heading:String in ["EVENTS","DEATHS","FELL ILL","FOOD LOST","SHELTER LOST"]:
		var column:=_column(_metrics)
		_label(column,heading,12,T.MUTED)
		_values.append(_label(column,"0",26,T.INK))
	var heading:=_label(self,"Recent years · deaths by year",16,T.INK)
	heading.tooltip_text=String(block.get("tip",""))
	_timeline=HBoxContainer.new();_timeline.add_theme_constant_override("separation",5);add_child(_timeline)
	_columns=BoxContainer.new();_columns.add_theme_constant_override("separation",24);add_child(_columns)
	var left:=_column(_columns);left.size_flags_stretch_ratio=1.15
	var navigation:=HBoxContainer.new();left.add_child(navigation)
	var all_events:=Button.new();all_events.text="All history";all_events.add_theme_font_size_override("font_size",13);navigation.add_child(all_events)
	all_events.pressed.connect(func():year_filter=-1;page=0;_refresh_timeline();_refresh_events())
	_range=_label(navigation,"",13,T.MUTED)
	_newer=Button.new();_newer.text="‹";_newer.tooltip_text="Newer events";navigation.add_child(_newer)
	_older=Button.new();_older.text="›";_older.tooltip_text="Older events";navigation.add_child(_older)
	_newer.pressed.connect(func():page-=1;_refresh_events())
	_older.pressed.connect(func():page+=1;_refresh_events())
	_events=_column(left);_events.add_theme_constant_override("separation",4)
	for index in PAGE_SIZE:
		var button:=Button.new();button.name="Event%d" % index;button.toggle_mode=true
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size",14);button.custom_minimum_size.y=43
		button.expand_icon=true;button.add_theme_constant_override("icon_max_width",24)
		_events.add_child(button);_buttons.append(button)
		button.pressed.connect(_select_slot.bind(index))
	_empty=_label(left,"",15,T.MUTED)
	var right:=_column(_columns)
	_title=_label(right,"",20,T.INK)
	_sub=_label(right,"",13,T.MUTED)
	_losses=GridContainer.new();_losses.columns=3;right.add_child(_losses)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size.y=190
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.add_child(scroll)
	_account=_label(scroll,"",14,T.BODY)
	_action=Button.new();_action.text="Summon";right.add_child(_action)
	_action.pressed.connect(func():var event:=_selected();var callback:Callable=event.get("on_click",Callable());if callback.is_valid():callback.call())
	resized.connect(_layout);update_block(block);call_deferred("_layout")

func _column(parent:Node)->VBoxContainer:
	var column:=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",6);parent.add_child(column);return column

func _label(parent:Node,text:String,font_size:int,color:Color)->Label:
	var label:=T.make_label(text,font_size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(label);return label

func _layout()->void:
	_columns.vertical=size.x<760
	_metrics.columns=3 if size.x<650 else 5

func update_block(block:Dictionary)->bool:
	data=block
	# Callables can change identity on each provider read; facts determine redraw.
	var facts:Array=[]
	for event:Dictionary in data.get("events",[]):
		var fact:=event.duplicate();fact["can_summon"]=event.get("on_click") is Callable;fact.erase("on_click");facts.append(fact)
	var key:=str([facts,int(data.get("today",0))])
	if key==_key:return true
	_key=key
	if _selected().is_empty():
		var all:Array=data.get("events",[])
		selected_id=String(all[0].id) if not all.is_empty() else ""
	# Retain the inspected event's page across incoming records.
	var filtered:=_filtered()
	for index in filtered.size():
		if String(filtered[index].id)==selected_id:
			page=index/PAGE_SIZE;break
	_refresh_totals();_refresh_timeline();_refresh_events();_layout()
	return true

func _refresh_totals()->void:
	var totals:Array[int]=[0,0,0,0,0]
	var today:=int(data.get("today",0))
	for event:Dictionary in data.get("events",[]):
		if today-int(event.day)>3650:continue
		totals[0]+=1;totals[1]+=int(event.dead);totals[2]+=int(event.sick)
		totals[3]+=int(event.food);totals[4]+=int(event.shelter)
	for index in totals.size():
		_values[index].text=str(totals[index]);_values[index].tooltip_text="Last ten years"+(" · people left without shelter" if index==4 else "")

func _refresh_timeline()->void:
	for child in _timeline.get_children():_timeline.remove_child(child);child.queue_free()
	var current:=int(data.get("today",0))/365
	var first:=maxi(0,current-9)
	var bins:Array=[];var peak:=1
	for year in range(first,current+1):
		var count:=0;var dead:=0
		for event:Dictionary in data.get("events",[]):
			if int(event.day)/365==year:count+=1;dead+=int(event.dead)
		bins.append({"year":year,"count":count,"dead":dead});peak=maxi(peak,dead)
	for bin:Dictionary in bins:
		var column:=_column(_timeline)
		var plot:=Control.new();plot.custom_minimum_size.y=46;column.add_child(plot)
		var bar:=ColorRect.new();bar.color=T.RED if int(bin.dead)>0 else T.MUTED
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;plot.add_child(bar)
		var height:=maxf(2,46.0*float(bin.dead)/peak)
		plot.resized.connect(func():bar.position=Vector2(4,46-height);bar.size=Vector2(maxf(2,plot.size.x-8),height))
		var button:=Button.new();button.text="Y%d\n%d" % [int(bin.year)+1,int(bin.dead)]
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		for style_name:String in ["normal","hover","pressed","hover_pressed","disabled"]:
			var style:=StyleBoxFlat.new();style.bg_color=T.ACTIVE_BG if "pressed" in style_name else T.ROW_BG
			style.content_margin_left=3;style.content_margin_right=3;style.content_margin_top=3;style.content_margin_bottom=3
			button.add_theme_stylebox_override(style_name,style)
		button.add_theme_font_size_override("font_size",12);button.tooltip_text="Events begun in Year %d: %d events, %d deaths. Select to browse." % [int(bin.year)+1,int(bin.count),int(bin.dead)]
		button.toggle_mode=true;button.set_pressed_no_signal(year_filter==int(bin.year));column.add_child(button)
		button.pressed.connect(func():year_filter=int(bin.year);page=0;selected_id="";_refresh_timeline();_refresh_events())

func _filtered()->Array:
	var result:Array=[]
	for event:Dictionary in data.get("events",[]):
		if year_filter<0 or int(event.day)/365==year_filter:result.append(event)
	return result

func _page_events()->Array:
	return _filtered().slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)

func _refresh_events()->void:
	var filtered:=_filtered()
	var pages:=maxi(1,ceili(filtered.size()/float(PAGE_SIZE)))
	page=clampi(page,0,pages-1)
	var events:=_page_events()
	if not events.is_empty() and not events.any(func(event:Dictionary)->bool:return String(event.id)==selected_id):selected_id=String(events[0].id)
	if events.is_empty():selected_id=""
	_range.text="%d events · %d/%d" % [filtered.size(),page+1,pages]
	_newer.disabled=page==0;_older.disabled=page==pages-1
	for index in PAGE_SIZE:
		var button:=_buttons[index];button.visible=index<events.size()
		if index>=events.size():continue
		var event:Dictionary=events[index]
		button.text="%s%s\n%s · %d died" % [String(event.name)," · ongoing" if bool(event.get("ongoing",false)) else "",String(event.date),int(event.dead)]
		button.icon=event.get("icon");button.tooltip_text=String(event.get("kind",""))
		button.set_pressed_no_signal(String(event.id)==selected_id)
	_empty.visible=events.is_empty();_empty.text=String(data.get("empty","Nothing written yet")) if year_filter<0 else "No events this year."
	_show_selected()

func _select_slot(index:int)->void:
	var events:=_page_events()
	if index>=events.size():return
	selected_id=String(events[index].id);_refresh_events()

func _selected()->Dictionary:
	for event:Dictionary in data.get("events",[]):
		if String(event.id)==selected_id:return event
	return {}

func _show_selected()->void:
	var event:=_selected()
	_title.text=String(event.get("name","No event selected"));_sub.text=String(event.get("sub",""))
	_account.text=String(event.get("detail",""))
	for child in _losses.get_children():_losses.remove_child(child);child.queue_free()
	if not event.is_empty():
		for field:String in ["dead","sick","food","shelter","timber"]:
			if field!="dead" and int(event.get(field,0))==0:continue
			var column:=_column(_losses)
			_label(column,str(int(event.get(field,0))),23,T.RED_TEXT if field=="dead" and int(event.get(field,0))>0 else T.INK)
			_label(column,{"dead":"Died","sick":"Fell ill","food":"Food lost","shelter":"Lost shelter","timber":"Timber lost"}[field],12,T.MUTED)
	_action.visible=event.get("on_click") is Callable

func view_state()->Dictionary:
	return {"selected":selected_id,"year":year_filter,"page":page}

func restore_view_state(state:Dictionary)->void:
	selected_id=String(state.get("selected",""));year_filter=int(state.get("year",-1));page=int(state.get("page",0))
	_refresh_timeline();_refresh_events()
